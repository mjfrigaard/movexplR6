# R6 Classes in Shiny App-Packages

## Why R6 in a Shiny app?

Shiny’s built-in tools for shared mutable state — `reactiveValues()`,
`reactive()`, closures — work well for small apps. As an app grows,
state tends to scatter across the server function and modules, making it
harder to reason about ownership and lifecycle.

An **R6 class** addresses this by bundling related data and the
operations on that data into a single object with explicit public and
private boundaries. For `movexplR6`, the `MovieData` class owns
everything related to the database:

- The connection (`$con`)
- The loaded data (`$all_movies`)
- How data is filtered (`$filter()`)
- How the connection is closed (`$disconnect()`)

The Shiny server just calls methods on the object; it never touches the
connection or SQL directly.

## R6 class anatomy

An R6 class is created with
[`R6::R6Class()`](https://r6.r-lib.org/reference/R6Class.html). The two
most important arguments are `public` and `private`.

``` r

MyClass <- R6::R6Class(
  classname = "MyClass",
  public = list(
    # Fields and methods accessible from outside the object
    value = NULL,
    initialize = function(x) self$value <- x,
    show       = function()  cat(self$value, "\n")
  ),
  private = list(
    # Fields and methods only accessible from within the class
    helper = function() self$value * 2
  )
)
obj <- MyClass$new(10)
obj$show()      # works
obj$value       # works
obj$helper()    # error: private
```

The key rules:

- `public` members are the class’s API — callable and readable from
  outside.
- `private` members are implementation details — only callable via
  `private$` inside other methods.
- `self$` refers to the current object’s public members.
- `private$` refers to the current object’s private members.

## The `MovieData` class in detail

### Fields

``` r

public = list(
  con        = NULL,   # DBI connection — set by initialize()
  all_movies = NULL    # collected data frame — set by initialize()
)
```

Both fields start as `NULL` and are populated during `$initialize()`.
Keeping them public lets the server and tests inspect them without extra
accessor methods.

### `initialize()`

`$initialize()` is the constructor — called automatically by `$new()`.

``` r

initialize = function(db_path) {
  logger::log_info("Connecting to database: {db_path}")
  tryCatch(
    {
      self$con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
      logger::log_info("Database connection established")
    },
    error = function(e) {
      logger::log_error("Failed to connect: {conditionMessage(e)}")
      stop(e)
    }
  )
  tryCatch(
    {
      self$all_movies <- private$load_data()
      logger::log_info("Loaded {nrow(self$all_movies)} movies into memory")
    },
    error = function(e) {
      logger::log_error("Failed to load movie data: {conditionMessage(e)}")
      stop(e)
    }
  )
}
```

Two [`tryCatch()`](https://rdrr.io/r/base/conditions.html) blocks keep
failures distinct: a missing database file is a different problem from a
malformed SQL query. Both re-throw the error so the caller (the Shiny
server) knows initialization failed.

### `private$load_data()`

`load_data()` is private because it is an implementation detail of
`initialize()`. No caller outside the class should call it directly.

``` r

private = list(
  load_data = function() {
    logger::log_debug("Joining omdb and tomatoes tables")
    omdb     <- dplyr::tbl(self$con, "omdb")
    tomatoes <- dplyr::tbl(self$con, "tomatoes")
    result <- dplyr::inner_join(omdb, tomatoes, by = "ID") |>
      dplyr::filter(Reviews >= 10) |>
      dplyr::select(ID, Title, Year, Genre, Director, Cast,
                    Oscars, Reviews, BoxOffice, Meter, Rating,
                    Runtime, ...) |>
      dplyr::collect()
    logger::log_debug("Collected {nrow(result)} rows")
    result
  }
)
```

Collecting into an in-memory data frame
([`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html))
means all subsequent `$filter()` calls work on a plain data frame —
fast, no repeated SQL round-trips.

### `$filter()`

`$filter()` is the class’s main workhorse. It is public because the
server calls it on every input change.

``` r

md <- MovieData$new(db_path)
#> INFO [2026-06-19 15:56:46] Connecting to database: /home/runner/work/_temp/Library/movexplR6/extdata/movies.db
#> INFO [2026-06-19 15:56:46] Database connection established
#> INFO [2026-06-19 15:56:46] Loaded 12569 movies into memory

# Default call — wide-open filters
nrow(md$filter())
#> [1] 4181

# Narrow by multiple criteria
nrow(md$filter(genre = "Drama", year = c(2000, 2014), oscars = 1))
#> [1] 108
```

The defensive pattern inside `$filter()` uses
[`tryCatch()`](https://rdrr.io/r/base/conditions.html) with a re-throw,
so a bad filter (e.g., a corrupted `all_movies` data frame) surfaces as
an error rather than a silent empty result. A `log_warn()` is also
emitted when the result is empty, which is useful during development.

### `$disconnect()` and `private$finalize()`

Lifecycle management is split across two methods:

``` r

# public — called explicitly by the server or tests
disconnect = function() {
  if (!is.null(self$con) && DBI::dbIsValid(self$con)) {
    tryCatch(
      {
        DBI::dbDisconnect(self$con)
        logger::log_info("Database connection closed")
      },
      error = function(e) {
        logger::log_warn("Error closing connection: {conditionMessage(e)}")
      }
    )
  }
}

# private — called by R's garbage collector
private = list(
  finalize = function() self$disconnect()
)
```

**Why split?**

- `finalize()` **must** be private as of R6 2.4.0; making it public
  raises a deprecation warning. It is the GC safety net.
- `$disconnect()` is public so it can be called explicitly —
  `shiny::onStop(function() movie_data$disconnect())` — without relying
  on garbage collection timing.
- `$disconnect()` only warns (never stops) on error: a failure to
  disconnect a closing app should not produce an unhandled exception.

``` r

DBI::dbIsValid(md$con)   # TRUE before disconnect
#> [1] TRUE
md$disconnect()
#> INFO [2026-06-19 15:56:46] Database connection closed
DBI::dbIsValid(md$con)   # FALSE after
#> [1] FALSE
```

## Object lifecycle in the Shiny server

``` r

movies_server <- function(input, output, session) {
  # 1. Created once when the session starts
  movie_data <- MovieData$new(
    system.file("extdata/movies.db", package = "movexplR6")
  )

  # 2. Closed when the session ends (browser tab closed, timeout, etc.)
  shiny::onStop(function() movie_data$disconnect())

  # 3. $filter() is called reactively on every input change
  movies <- shiny::reactive({
    movie_data$filter(
      reviews = input$reviews,
      genre   = input$genre,
      ...
    )
  })
}
```

The object is created once per session, not once per reactive execution.
This is the key advantage over a plain `reactive()` that reconnects each
time: the connection is opened once, data is loaded once, and
`$filter()` operates on the in-memory `$all_movies` data frame for the
lifetime of the session.

## R6 vs. alternative Shiny patterns

| Pattern | State lives in | Lifecycle control | Reusable outside Shiny |
|----|----|----|----|
| `reactiveValues()` | Shiny session | Implicit (GC) | No |
| Module-local closure | Module environment | Implicit (GC) | No |
| **R6 class** | Object fields | Explicit (`$disconnect()`) | **Yes** |

Because `MovieData` is a plain R object, you can use it in unit tests,
scripts, or other packages without starting a Shiny session — the
`test-MovieData.R` test file demonstrates this directly.

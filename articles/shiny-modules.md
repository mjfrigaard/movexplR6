# Shiny Module Architecture

## What is a Shiny module?

A Shiny module is a self-contained unit of UI and server logic
identified by a namespace ID. Modules solve two problems that appear as
apps grow:

1.  **ID collisions** — two inputs named `"genre"` in different parts of
    the app would clash. Modules prefix every ID with their namespace so
    `"filters-genre"` and `"plot-genre"` never conflict.
2.  **Coupling** — without modules, server logic for unrelated features
    shares the same `input`, `output`, and `session` objects. Modules
    give each feature its own scope.

Every module is a pair of functions: a **UI function** that renders
HTML, and a **server function** that contains reactive logic.
`movexplR6` has two modules: `mod_filters` and `mod_plot`.

## Namespace isolation

The `shiny::NS(id)` call inside each UI function returns a namespacing
function. Every input and output ID is wrapped with it:

``` r

mod_filters_ui <- function(id) {
  ns <- shiny::NS(id)          # ns("reviews") becomes "filters-reviews"
  shiny::sliderInput(ns("reviews"), ...)
}
```

When the server function calls `shiny::moduleServer(id, ...)`, Shiny
automatically applies the same namespace to `input`, `output`, and
`session`, so `input$reviews` inside the module body refers to
`"filters-reviews"` in the global session — without the module author or
the caller having to think about it.

## Data flow

The server function in `movies_server.R` acts as the conductor: it owns
the `MovieData` object, calls `$filter()` to derive the `movies`
reactive, and passes both `movies` and `filters` down to
[`mod_plot_server()`](https://mjfrigaard.github.io/movexplR6/reference/mod_plot_server.md).

## `mod_filters`

### UI

`mod_filters_ui(id)` renders two
[`bslib::card`](https://rstudio.github.io/bslib/reference/card.html)
elements: one for filter controls and one for axis variable selectors.

``` r

mod_filters_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    bslib::card(
      bslib::card_header("Filters"),
      shiny::sliderInput(ns("reviews"), "Min reviews", 10, 300, 80, step = 10),
      shiny::sliderInput(ns("year"), "Year released", 1940, 2014,
                         value = c(1970, 2014), sep = ""),
      shiny::selectInput(ns("genre"), "Genre", choices = c("All", ...)),
      shiny::textInput(ns("director"), "Director name contains"),
      shiny::textInput(ns("cast"),     "Cast name contains")
    ),
    bslib::card(
      bslib::card_header("Axes"),
      shiny::selectInput(ns("xvar"), "X-axis variable", choices = axis_vars),
      shiny::selectInput(ns("yvar"), "Y-axis variable", choices = axis_vars)
    )
  )
}
```

### Server

`mod_filters_server(id)` **returns** a reactive list. This is the
module’s output — the value it hands back to whoever called it.

``` r

mod_filters_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::reactive({
      list(
        reviews   = input$reviews,
        oscars    = input$oscars,
        year      = input$year,
        boxoffice = input$boxoffice,
        genre     = input$genre,
        director  = input$director,
        cast      = input$cast,
        xvar      = input$xvar,
        yvar      = input$yvar
      )
    })
  })
}
```

Returning a **single reactive list** rather than nine individual
reactives keeps the interface between modules simple. The caller
receives one object, calls it as `filters()`, and gets all current
values at once.

### Testing `mod_filters_server`

[`shiny::testServer()`](https://rdrr.io/pkg/shiny/man/testServer.html)
lets you set inputs and inspect the returned reactive without running a
browser:

``` r

shiny::testServer(mod_filters_server, {
  session$setInputs(
    reviews = 120, oscars = 1,
    year = c(2000, 2010), boxoffice = c(0, 500),
    genre = "Action", director = "Nolan", cast = "",
    xvar = "Meter", yvar = "Reviews"
  )
  result <- session$returned()
  result$reviews   # 120
  result$genre     # "Action"
})
```

`session$returned()` retrieves whatever the module server returned —
here the reactive list.

## `mod_plot`

### UI

`mod_plot_ui(id)` renders a single
[`bslib::card`](https://rstudio.github.io/bslib/reference/card.html)
containing a `plotly` output and a text output for the movie count.

``` r

mod_plot_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    bslib::card_header("Movie Explorer"),
    plotly::plotlyOutput(ns("scatter"), height = "500px"),
    shiny::textOutput(ns("n_movies"))
  )
}
```

### Server

`mod_plot_server(id, movies, filters)` takes **two reactive arguments**
— the filtered data frame and the filter selections — passed in from the
parent server.

``` r

mod_plot_server <- function(id, movies, filters) {
  shiny::moduleServer(id, function(input, output, session) {
    output$scatter <- plotly::renderPlotly({
      m <- movies()
      f <- filters()
      xvar_name <- names(axis_vars)[axis_vars == f$xvar]
      yvar_name <- names(axis_vars)[axis_vars == f$yvar]
      p <- ggplot2::ggplot(
        m,
        ggplot2::aes(
          x = .data[[f$xvar]], y = .data[[f$yvar]],
          color = has_oscar,
          text  = paste0("<b>", Title, "</b><br>", Year, "<br>$",
                         format(BoxOffice, big.mark = ",", scientific = FALSE))
        )
      ) +
        ggplot2::geom_point(alpha = 0.4, size = 2) +
        ggplot2::scale_color_manual(
          name   = "Won Oscar",
          values = c("Yes" = "orange", "No" = "#aaaaaa")
        ) +
        ggplot2::labs(x = xvar_name, y = yvar_name) +
        ggplot2::theme_minimal()
      plotly::ggplotly(p, tooltip = "text")
    })
    output$n_movies <- shiny::renderText({
      paste("Movies selected:", nrow(movies()))
    })
  })
}
```

`ggplot2::aes(.data[[f$xvar]])` is the tidy-eval idiom for using a
string as a column name inside `aes()`.
[`plotly::ggplotly()`](https://rdrr.io/pkg/plotly/man/ggplotly.html)
converts the `ggplot2` object to an interactive `plotly` widget, with
the `text` aesthetic driving the hover tooltip.

### Passing reactives as arguments

A key design point: `movies` and `filters` are passed as **reactive
objects**, not as their values. The module server calls them
(`movies()`, `filters()`) inside render functions, which means Shiny
knows to re-run the render whenever either reactive invalidates.

``` r

# In movies_server():
filters    <- mod_filters_server("filters")   # reactive list
movies     <- shiny::reactive({
  f <- filters()
  movie_data$filter(reviews = f$reviews, genre = f$genre, ...)
})
mod_plot_server("plot", movies = movies, filters = filters)
#                              ^^^^^^             ^^^^^^^
#                          reactive object    reactive object
#                          (not movies())     (not filters())
```

Passing the reactive itself (not its current value) lets the plot module
subscribe to invalidation events correctly.

### Testing `mod_plot_server`

``` r

md <- MovieData$new(db_path)
on.exit(md$disconnect())

movies_r  <- shiny::reactive(md$filter(genre = "Drama"))
filters_r <- shiny::reactive(list(xvar = "Meter", yvar = "Reviews"))

shiny::testServer(
  mod_plot_server,
  args = list(movies = movies_r, filters = filters_r),
  {
    n <- nrow(md$filter(genre = "Drama"))
    expect_equal(output$n_movies, paste("Movies selected:", n))
  }
)
```

## How the modules connect in `movies_server()`

``` r

movies_server <- function(input, output, session) {
  movie_data <- MovieData$new(
    system.file("extdata/movies.db", package = "movexplR6")
  )
  shiny::onStop(function() movie_data$disconnect())

  # mod_filters_server returns a reactive list
  filters <- mod_filters_server("filters")

  # movies() is derived from the reactive list
  movies <- shiny::reactive({
    f <- filters()
    movie_data$filter(
      reviews   = f$reviews,
      oscars    = f$oscars,
      year      = f$year,
      boxoffice = f$boxoffice,
      genre     = f$genre,
      director  = f$director,
      cast      = f$cast
    )
  })

  # both reactives are handed to the plot module
  mod_plot_server("plot", movies, filters)
}
```

The server function’s only job is wiring: it creates the `MovieData`
object, calls
[`mod_filters_server()`](https://mjfrigaard.github.io/movexplR6/reference/mod_filters_server.md)
to get the `filters` reactive, derives `movies` from it, then passes
both to
[`mod_plot_server()`](https://mjfrigaard.github.io/movexplR6/reference/mod_plot_server.md).
No output rendering happens here — that is fully delegated to the
modules.

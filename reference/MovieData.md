# MovieData R6 class

Manages a SQLite database connection for movie data, loads a joined
dataset from the `omdb` and `tomatoes` tables, and applies filter logic
derived from Shiny input values.

## Details

On initialization the class opens a connection to the SQLite database at
`db_path`, joins the two tables via `inner_join()`, collects the result
into memory, and stores it in `$all_movies`. Call `$filter()` to obtain
a filtered data frame for rendering. Call `$disconnect()` to close the
connection explicitly; the private `finalize()` method also calls it
when the object is garbage collected.

Logging is handled via the `logger` package. Set the threshold with
[`logger::log_threshold()`](https://daroczig.github.io/logger/reference/log_threshold.html)
before initializing the class.

## Public fields

- `con`:

  Active `DBI` database connection.

- `all_movies`:

  Full joined and collected data frame.

## Methods

### Public methods

- [`MovieData$new()`](#method-MovieData-initialize)

- [`MovieData$filter()`](#method-MovieData-filter)

- [`MovieData$disconnect()`](#method-MovieData-disconnect)

- [`MovieData$clone()`](#method-MovieData-clone)

------------------------------------------------------------------------

### `MovieData$new()`

Connect to the SQLite database and load all movie data.

#### Usage

    MovieData$new(db_path)

#### Arguments

- `db_path`:

  Path to the `movies.db` SQLite file.

------------------------------------------------------------------------

### `MovieData$filter()`

Filter the in-memory data frame using input values.

#### Usage

    MovieData$filter(
      reviews = 10,
      oscars = 0,
      year = c(1940, 2014),
      boxoffice = c(0, 800),
      genre = "All",
      director = "",
      cast = ""
    )

#### Arguments

- `reviews`:

  Minimum number of Rotten Tomatoes reviews.

- `oscars`:

  Minimum number of Oscar wins.

- `year`:

  Integer vector of length 2: `c(min_year, max_year)`.

- `boxoffice`:

  Numeric vector of length 2: box-office range in millions.

- `genre`:

  Genre string; `"All"` disables the filter.

- `director`:

  Partial director name; empty string disables the filter.

- `cast`:

  Partial cast name; empty string disables the filter.

#### Returns

A filtered data frame with an added `has_oscar` column.

------------------------------------------------------------------------

### `MovieData$disconnect()`

Explicitly close the database connection. Call this from
[`shiny::onStop()`](https://rdrr.io/pkg/shiny/man/onStop.html) or in
tests via [`on.exit()`](https://rdrr.io/r/base/on.exit.html).

#### Usage

    MovieData$disconnect()

------------------------------------------------------------------------

### `MovieData$clone()`

The objects of this class are cloneable with this method.

#### Usage

    MovieData$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

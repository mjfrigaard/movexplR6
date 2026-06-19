# Introduction to movexplR6

## Overview

`movexplR6` is a Shiny app-package for exploring a movie database that
combines [Rotten Tomatoes](https://www.rottentomatoes.com/) and
[IMDb](https://www.imdb.com/) data. It modernizes the classic
`051-movie-explorer` Shiny example by:

- Replacing `ggvis` with `ggplot2` + `plotly` for interactive scatter
  plots.
- Replacing `wellPanel` layouts with `bslib` (`page_sidebar`, `card`).
- Wrapping all database and filter logic in an **R6 class**
  (`MovieData`).

## The `MovieData` R6 class

`MovieData` owns the database connection and exposes two public methods:
`$filter()` for querying the in-memory data, and `$finalize()` for
cleaning up the connection.

### Connecting and loading data

``` r

md <- MovieData$new(db_path)
#> INFO [2026-06-19 16:04:56] Connecting to database: /home/runner/work/_temp/Library/movexplR6/extdata/movies.db
#> INFO [2026-06-19 16:04:56] Database connection established
#> INFO [2026-06-19 16:04:57] Loaded 12569 movies into memory
```

On initialization the class:

1.  Opens a `DBI` connection to the SQLite file.
2.  Joins the `omdb` and `tomatoes` tables.
3.  Collects the result into `$all_movies` (an in-memory data frame).

``` r

dim(md$all_movies)
#> [1] 12569    26
names(md$all_movies)
#>  [1] "ID"          "imdbID"      "Title"       "Year"        "Rating_m"   
#>  [6] "Runtime"     "Genre"       "Released"    "Director"    "Writer"     
#> [11] "imdbRating"  "imdbVotes"   "Language"    "Country"     "Oscars"     
#> [16] "Rating"      "Meter"       "Reviews"     "Fresh"       "Rotten"     
#> [21] "userMeter"   "userRating"  "userReviews" "BoxOffice"   "Production" 
#> [26] "Cast"
```

### Filtering

`$filter()` accepts the same parameters exposed by the Shiny sidebar and
returns a filtered data frame with an added `has_oscar` column.

``` r

defaults <- md$filter()
nrow(defaults)
#> [1] 4181
```

**Filter by minimum reviews:**

``` r

strict <- md$filter(reviews = 200)
nrow(strict)
#> [1] 306
```

**Filter by genre:**

``` r

drama <- md$filter(genre = "Drama")
nrow(drama)
#> [1] 2195
head(drama[, c("Title", "Year", "Genre", "Oscars", "has_oscar")], 5)
#>                       Title Year                 Genre Oscars has_oscar
#> 1 Diary of a Country Priest 1951                 Drama      0        No
#> 2 The Man in the White Suit 1951 Comedy, Sci-Fi, Drama      0        No
#> 3           Little Fugitive 1953         Drama, Family      0        No
#> 4                 Le amiche 1955        Drama, Romance      0        No
#> 5                Breathless 1960 Crime, Drama, Romance      0        No
```

**Filter by year range:**

``` r

nineties <- md$filter(year = c(1990, 1999))
range(nineties$Year)
#> [1] 1990 1999
```

**Filter by box-office range (millions):**

``` r

blockbusters <- md$filter(boxoffice = c(200, 800))
nrow(blockbusters)
#> [1] 106
```

**Filter by director (partial, case-insensitive):**

``` r

spielberg <- md$filter(director = "Spielberg")
unique(spielberg$Director)
#> [1] "Steven Spielberg"
```

**Combining filters:**

``` r

combined <- md$filter(
  genre    = "Action",
  oscars   = 1,
  year     = c(2000, 2014),
  director = "Nolan"
)
combined[, c("Title", "Year", "Director", "Oscars")]
#>             Title Year          Director Oscars
#> 1 The Dark Knight 2008 Christopher Nolan      2
#> 2       Inception 2010 Christopher Nolan      4
```

### The `has_oscar` column

`$filter()` always appends a `has_oscar` character column (`"Yes"` /
`"No"`) derived from the `Oscars` count. The scatter plot uses this for
color encoding.

``` r

table(defaults$has_oscar)
#> 
#>   No  Yes 
#> 4023  158
```

### Disconnecting

Call `$disconnect()` to explicitly close the database connection. This
is also called automatically via
[`shiny::onStop()`](https://rdrr.io/pkg/shiny/man/onStop.html) inside
[`movies_server()`](https://mjfrigaard.github.io/movexplR6/reference/movies_server.md).
The private `finalize()` method delegates to `$disconnect()` so the
connection is also closed when the object is garbage collected.

``` r

md$disconnect()
#> INFO [2026-06-19 16:04:58] Database connection closed
DBI::dbIsValid(md$con)
#> [1] FALSE
```

## Axis variables

`axis_vars` is a named character vector mapping display labels to column
names. Both
[`mod_filters_ui()`](https://mjfrigaard.github.io/movexplR6/reference/mod_filters_ui.md)
and
[`mod_plot_server()`](https://mjfrigaard.github.io/movexplR6/reference/mod_plot_server.md)
use it to populate the axis selector inputs.

``` r

axis_vars
#>          Tomato Meter        Numeric Rating     Number of reviews 
#>               "Meter"              "Rating"             "Reviews" 
#> Dollars at box office                  Year      Length (minutes) 
#>           "BoxOffice"                "Year"             "Runtime"
```

## Shiny modules

### `mod_filters`

`mod_filters_ui(id)` renders two
[`bslib::card`](https://rstudio.github.io/bslib/reference/card.html)
elements inside the sidebar: one for filter controls and one for axis
selectors. `mod_filters_server(id)` returns a reactive list of the
current selections.

### `mod_plot`

`mod_plot_ui(id)` renders a
[`bslib::card`](https://rstudio.github.io/bslib/reference/card.html)
containing a `plotly` scatter plot and a movie count line.
`mod_plot_server(id, movies, filters)` accepts the filtered data
reactive and the filter selections reactive, and renders the plot. Hover
tooltips show the movie title, year, and box-office gross.

## Running the app

``` r

movexplR6::launch_app()
```

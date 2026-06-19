# Scatter plot display module server

Renders an interactive `plotly` scatter plot from filtered movie data.
Hover tooltips show the movie title, year, and box-office gross.

## Usage

``` r
mod_plot_server(id, movies, filters)
```

## Arguments

- id:

  Module namespace ID.

- movies:

  A reactive data frame of filtered movies (from `MovieData$filter()`).

- filters:

  A reactive list of filter/axis selections (from
  [`mod_filters_server()`](https://mjfrigaard.github.io/movexplR6/reference/mod_filters_server.md)).

## Value

No return value; called for side effects.

# Launch the Movie Explorer application

Entry point for the `movexplR6` package. Calls
[`shiny::shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html) with
the package UI and server functions.

## Usage

``` r
launch_app(...)
```

## Arguments

- ...:

  Additional arguments passed to
  [`shiny::shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

## Value

A Shiny app object (invisibly).

## See also

[`movies_ui()`](https://mjfrigaard.github.io/movexplR6/reference/movies_ui.md),
[`movies_server()`](https://mjfrigaard.github.io/movexplR6/reference/movies_server.md)

Other Application Components:
[`movies_server()`](https://mjfrigaard.github.io/movexplR6/reference/movies_server.md),
[`movies_ui()`](https://mjfrigaard.github.io/movexplR6/reference/movies_ui.md)

## Examples

``` r
if (FALSE) { # \dontrun{
launch_app()
} # }
```

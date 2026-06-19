# Main server logic for the Movie Explorer application

Initializes a
[MovieData](https://mjfrigaard.github.io/movexplR6/reference/MovieData.md)
R6 object, wires the filter module to the data object's `$filter()`
method, and passes reactive results to the plot module.

## Usage

``` r
movies_server(input, output, session)
```

## Arguments

- input, output, session:

  Standard Shiny server arguments.

## Value

No return value; called for side effects.

## See also

[`movies_ui()`](https://mjfrigaard.github.io/movexplR6/reference/movies_ui.md),
[`launch_app()`](https://mjfrigaard.github.io/movexplR6/reference/launch_app.md)

Other Application Components:
[`launch_app()`](https://mjfrigaard.github.io/movexplR6/reference/launch_app.md),
[`movies_ui()`](https://mjfrigaard.github.io/movexplR6/reference/movies_ui.md)

## Examples

``` r
if (FALSE) { # \dontrun{
shiny::shinyApp(ui = movies_ui(), server = movies_server)
} # }
```

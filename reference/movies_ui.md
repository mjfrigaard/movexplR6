# Main UI for the Movie Explorer application

Builds a
[`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html)
layout with filter controls in the sidebar and the scatter plot in the
main panel.

## Usage

``` r
movies_ui()
```

## Value

A `shiny.tag` UI definition.

## See also

[`movies_server()`](https://mjfrigaard.github.io/movexplR6/reference/movies_server.md),
[`launch_app()`](https://mjfrigaard.github.io/movexplR6/reference/launch_app.md)

Other Application Components:
[`launch_app()`](https://mjfrigaard.github.io/movexplR6/reference/launch_app.md),
[`movies_server()`](https://mjfrigaard.github.io/movexplR6/reference/movies_server.md)

## Examples

``` r
if (FALSE) { # \dontrun{
shiny::shinyApp(ui = movies_ui(), server = movies_server)
} # }
```

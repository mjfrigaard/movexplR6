#' Main UI for the Movie Explorer application
#'
#' Builds a `bslib::page_sidebar()` layout with filter controls in the sidebar
#' and the scatter plot in the main panel.
#'
#' @return A `shiny.tag` UI definition.
#'
#' @seealso [movies_server()], [launch_app()]
#' @family Application Components
#'
#' @examples
#' if (interactive()) {
#'   shiny::shinyApp(ui = movies_ui(), server = movies_server)
#' }
#'
#' @export
movies_ui <- function() {
  bslib::page_sidebar(
    title   = "Movie Explorer",
    sidebar = bslib::sidebar(
      mod_filters_ui("filters")
    ),
    mod_plot_ui("plot")
  )
}

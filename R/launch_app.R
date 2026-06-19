#' Launch the Movie Explorer application
#'
#' Entry point for the `movexplR6` package. Calls [shiny::shinyApp()] with the
#' package UI and server functions.
#'
#' @param ... Additional arguments passed to [shiny::shinyApp()].
#'
#' @return A Shiny app object (invisibly).
#'
#' @seealso [movies_ui()], [movies_server()]
#' @family Application Components
#'
#' @examples
#' \dontrun{
#' launch_app()
#' }
#'
#' @export
launch_app <- function(...) {
  shiny::shinyApp(
    ui     = movies_ui(),
    server = movies_server,
    ...
  )
}

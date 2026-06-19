#' Main server logic for the Movie Explorer application
#'
#' Initializes a [MovieData] R6 object, wires the filter module to the data
#' object's `$filter()` method, and passes reactive results to the plot module.
#'
#' @param input,output,session Standard Shiny server arguments.
#'
#' @return No return value; called for side effects.
#'
#' @seealso [movies_ui()], [launch_app()]
#' @family Application Components
#'
#' @examples
#' \dontrun{
#' shiny::shinyApp(ui = movies_ui(), server = movies_server)
#' }
#'
#' @export
movies_server <- function(input, output, session) {
  logger::log_info("Movie Explorer server initializing")
  db_path <- system.file("extdata/movies.db", package = "movexplR6")

  movie_data <- tryCatch(
    MovieData$new(db_path),
    error = function(e) {
      logger::log_error("Could not initialize MovieData: {conditionMessage(e)}")
      stop(e)
    }
  )

  shiny::onStop(function() movie_data$disconnect())

  filters <- mod_filters_server("filters")

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

  mod_plot_server("plot", movies, filters)
}

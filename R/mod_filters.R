#' Filter inputs module UI
#'
#' Renders two `bslib` cards: one for filter controls and one for axis
#' variable selectors. Intended for use inside a `bslib::sidebar()`.
#'
#' @param id Module namespace ID.
#'
#' @return A `tagList` of `bslib::card` elements.
#' @export
mod_filters_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    bslib::card(
      bslib::card_header("Filters"),
      shiny::sliderInput(
        ns("reviews"), "Min reviews on Rotten Tomatoes",
        min = 10, max = 300, value = 80, step = 10
      ),
      shiny::sliderInput(
        ns("year"), "Year released",
        min = 1940, max = 2014, value = c(1970, 2014), sep = ""
      ),
      shiny::sliderInput(
        ns("oscars"), "Min Oscar wins",
        min = 0, max = 4, value = 0, step = 1
      ),
      shiny::sliderInput(
        ns("boxoffice"), "Box office (millions USD)",
        min = 0, max = 800, value = c(0, 800), step = 1
      ),
      shiny::selectInput(
        ns("genre"), "Genre",
        choices = c(
          "All", "Action", "Adventure", "Animation", "Biography", "Comedy",
          "Crime", "Documentary", "Drama", "Family", "Fantasy", "History",
          "Horror", "Music", "Musical", "Mystery", "Romance", "Sci-Fi",
          "Short", "Sport", "Thriller", "War", "Western"
        )
      ),
      shiny::textInput(ns("director"), "Director name contains"),
      shiny::textInput(ns("cast"), "Cast name contains")
    ),
    bslib::card(
      bslib::card_header("Axes"),
      shiny::selectInput(
        ns("xvar"), "X-axis variable",
        choices = axis_vars, selected = "Meter"
      ),
      shiny::selectInput(
        ns("yvar"), "Y-axis variable",
        choices = axis_vars, selected = "Reviews"
      ),
      shiny::tags$small(paste0(
        "The Tomato Meter is the proportion of positive reviews. ",
        "Numeric Rating is a normalized 1-10 score of star-rated reviews."
      ))
    )
  )
}

#' Filter inputs module server
#'
#' Returns a reactive list of all current filter and axis selections.
#'
#' @param id Module namespace ID.
#'
#' @return A reactive list with elements: `reviews`, `oscars`, `year`,
#'   `boxoffice`, `genre`, `director`, `cast`, `xvar`, `yvar`.
#' @export
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

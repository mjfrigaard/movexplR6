#' Scatter plot display module UI
#'
#' Renders a `bslib::card` containing a `plotly` scatter plot and a movie count.
#'
#' @param id Module namespace ID.
#'
#' @return A `bslib::card`.
#' @export
mod_plot_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    bslib::card_header("Movie Explorer"),
    plotly::plotlyOutput(ns("scatter"), height = "500px"),
    shiny::textOutput(ns("n_movies"))
  )
}

#' Scatter plot display module server
#'
#' Renders an interactive `plotly` scatter plot from filtered movie data.
#' Hover tooltips show the movie title, year, and box-office gross.
#'
#' @param id Module namespace ID.
#' @param movies A reactive data frame of filtered movies (from `MovieData$filter()`).
#' @param filters A reactive list of filter/axis selections (from `mod_filters_server()`).
#'
#' @return No return value; called for side effects.
#' @export
mod_plot_server <- function(id, movies, filters) {
  shiny::moduleServer(id, function(input, output, session) {
    output$scatter <- plotly::renderPlotly({
      m <- movies()
      f <- filters()

      xvar_name <- names(axis_vars)[axis_vars == f$xvar]
      yvar_name <- names(axis_vars)[axis_vars == f$yvar]

      p <- ggplot2::ggplot(
        m,
        ggplot2::aes(
          x     = .data[[f$xvar]],
          y     = .data[[f$yvar]],
          color = has_oscar,
          text  = paste0(
            "<b>", Title, "</b><br>",
            Year, "<br>",
            "$", format(BoxOffice, big.mark = ",", scientific = FALSE)
          )
        )
      ) +
        ggplot2::geom_point(alpha = 0.4, size = 2) +
        ggplot2::scale_color_manual(
          name   = "Won Oscar",
          values = c("Yes" = "orange", "No" = "#aaaaaa")
        ) +
        ggplot2::labs(x = xvar_name, y = yvar_name) +
        ggplot2::theme_minimal()

      plotly::ggplotly(p, tooltip = "text")
    })

    output$n_movies <- shiny::renderText({
      paste("Movies selected:", nrow(movies()))
    })
  })
}

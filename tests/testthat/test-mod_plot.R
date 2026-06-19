test_that("mod_plot_ui() returns a bslib card tag", {
  ui <- mod_plot_ui("test")
  expect_s3_class(ui, "bslib_fragment")
})

test_that("mod_plot_ui() output contains namespaced output IDs", {
  ui_html <- as.character(mod_plot_ui("myns"))
  expect_true(grepl("myns-scatter",  ui_html))
  expect_true(grepl("myns-n_movies", ui_html))
})

test_that("mod_plot_server() renders n_movies text output", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$finalize())

  movies_r  <- shiny::reactive(md$filter())
  filters_r <- shiny::reactive(list(xvar = "Meter", yvar = "Reviews"))

  shiny::testServer(
    mod_plot_server,
    args = list(movies = movies_r, filters = filters_r),
    {
      expect_match(output$n_movies, "^Movies selected: [0-9]+$")
    }
  )
})

test_that("mod_plot_server() n_movies count matches the movies reactive row count", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$finalize())

  filtered  <- md$filter(genre = "Drama")
  movies_r  <- shiny::reactive(filtered)
  filters_r <- shiny::reactive(list(xvar = "Meter", yvar = "Reviews"))

  shiny::testServer(
    mod_plot_server,
    args = list(movies = movies_r, filters = filters_r),
    {
      expected <- paste("Movies selected:", nrow(filtered))
      expect_equal(output$n_movies, expected)
    }
  )
})

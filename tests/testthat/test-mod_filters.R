test_that("mod_filters_ui() returns a shiny tagList", {
  ui <- mod_filters_ui("test")
  expect_s3_class(ui, "shiny.tag.list")
})

test_that("mod_filters_ui() output contains namespaced input IDs", {
  ui_html <- as.character(mod_filters_ui("myns"))
  expect_true(grepl("myns-reviews", ui_html))
  expect_true(grepl("myns-year",    ui_html))
  expect_true(grepl("myns-oscars",  ui_html))
  expect_true(grepl("myns-genre",   ui_html))
  expect_true(grepl("myns-xvar",    ui_html))
  expect_true(grepl("myns-yvar",    ui_html))
})

test_that("mod_filters_server() returned reactive has expected names", {
  shiny::testServer(mod_filters_server, {
    session$setInputs(
      reviews   = 50,
      oscars    = 1,
      year      = c(1990, 2010),
      boxoffice = c(0, 500),
      genre     = "Drama",
      director  = "",
      cast      = "",
      xvar      = "Meter",
      yvar      = "Reviews"
    )
    result <- session$returned()
    expect_named(
      result,
      c("reviews", "oscars", "year", "boxoffice",
        "genre", "director", "cast", "xvar", "yvar")
    )
  })
})

test_that("mod_filters_server() reactive reflects current input values", {
  shiny::testServer(mod_filters_server, {
    session$setInputs(
      reviews   = 120,
      oscars    = 2,
      year      = c(2000, 2010),
      boxoffice = c(100, 400),
      genre     = "Action",
      director  = "Nolan",
      cast      = "",
      xvar      = "BoxOffice",
      yvar      = "Year"
    )
    result <- session$returned()
    expect_equal(result$reviews,   120)
    expect_equal(result$oscars,    2)
    expect_equal(result$year,      c(2000, 2010))
    expect_equal(result$boxoffice, c(100, 400))
    expect_equal(result$genre,     "Action")
    expect_equal(result$director,  "Nolan")
    expect_equal(result$xvar,      "BoxOffice")
    expect_equal(result$yvar,      "Year")
  })
})

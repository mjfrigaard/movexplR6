test_that("axis_vars is a named character vector", {
  expect_type(axis_vars, "character")
  expect_true(!is.null(names(axis_vars)))
})

test_that("axis_vars has six elements", {
  expect_length(axis_vars, 6)
})

test_that("axis_vars contains expected column names as values", {
  expect_true(all(
    c("Meter", "Rating", "Reviews", "BoxOffice", "Year", "Runtime") %in%
      axis_vars
  ))
})

test_that("axis_vars contains expected display labels as names", {
  expect_true(all(
    c("Tomato Meter", "Numeric Rating", "Number of reviews",
      "Dollars at box office", "Year", "Length (minutes)") %in%
      names(axis_vars)
  ))
})

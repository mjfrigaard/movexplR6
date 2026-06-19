test_that("MovieData$new() creates an R6 object with a populated all_movies data frame", {
  skip_if(db_path == "", "movies.db not found; run devtools::install() first")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  expect_true(R6::is.R6(md))
  expect_s3_class(md$all_movies, "data.frame")
  expect_gt(nrow(md$all_movies), 0)
})

test_that("all_movies contains expected columns", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  expected_cols <- c(
    "ID", "Title", "Year", "Genre", "Director", "Cast",
    "Oscars", "Reviews", "BoxOffice", "Meter", "Rating", "Runtime"
  )
  expect_true(all(expected_cols %in% names(md$all_movies)))
})

test_that("MovieData$filter() returns a data frame with a has_oscar column", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  result <- md$filter()
  expect_s3_class(result, "data.frame")
  expect_true("has_oscar" %in% names(result))
  expect_true(all(result$has_oscar %in% c("Yes", "No")))
})

test_that("has_oscar reflects Oscars column correctly", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  result <- md$filter()
  expect_true(all(result$has_oscar[result$Oscars == 0] == "No"))
  expect_true(all(result$has_oscar[result$Oscars >= 1] == "Yes"))
})

test_that("reviews filter reduces the number of rows", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  loose  <- md$filter(reviews = 10)
  strict <- md$filter(reviews = 200)
  expect_lt(nrow(strict), nrow(loose))
  expect_true(all(strict$Reviews >= 200))
})

test_that("oscars filter returns only movies meeting the minimum", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  result <- md$filter(oscars = 2)
  expect_true(all(result$Oscars >= 2))
})

test_that("year filter restricts Year to the supplied range", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  result <- md$filter(year = c(2000, 2005))
  expect_true(all(result$Year >= 2000))
  expect_true(all(result$Year <= 2005))
})

test_that("boxoffice filter restricts BoxOffice to the supplied range", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  result <- md$filter(boxoffice = c(100, 300))
  expect_true(all(result$BoxOffice >= 100e6))
  expect_true(all(result$BoxOffice <= 300e6))
})

test_that("genre filter keeps only rows containing that genre string", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  result <- md$filter(genre = "Drama")
  expect_gt(nrow(result), 0)
  expect_true(all(grepl("Drama", result$Genre, fixed = TRUE)))
})

test_that("genre = 'All' does not reduce the unfiltered row count", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  all_genres <- md$filter(genre = "All")
  explicit   <- md$filter()
  expect_equal(nrow(all_genres), nrow(explicit))
})

test_that("director filter is case-insensitive and partial", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  result <- md$filter(director = "spielberg")
  expect_gt(nrow(result), 0)
  expect_true(all(grepl("spielberg", result$Director, ignore.case = TRUE)))
})

test_that("cast filter is case-insensitive and partial", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  result <- md$filter(cast = "hanks")
  expect_gt(nrow(result), 0)
  expect_true(all(grepl("hanks", result$Cast, ignore.case = TRUE)))
})

test_that("empty director and cast strings do not filter any rows", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  on.exit(md$disconnect())
  with_blanks <- md$filter(director = "", cast = "")
  without     <- md$filter()
  expect_equal(nrow(with_blanks), nrow(without))
})

test_that("MovieData$disconnect() closes the connection without error", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  expect_true(DBI::dbIsValid(md$con))
  expect_no_error(md$disconnect())
  expect_false(DBI::dbIsValid(md$con))
})

test_that("calling disconnect() twice does not error", {
  skip_if(db_path == "", "movies.db not found")
  md <- MovieData$new(db_path)
  md$disconnect()
  expect_no_error(md$disconnect())
})

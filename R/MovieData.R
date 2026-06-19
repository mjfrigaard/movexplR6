#' MovieData R6 class
#'
#' @description
#' Manages a SQLite database connection for movie data, loads a joined dataset
#' from the `omdb` and `tomatoes` tables, and applies filter logic derived from
#' Shiny input values.
#'
#' @details
#' On initialization the class opens a connection to the SQLite database at
#' `db_path`, joins the two tables via `inner_join()`, collects the result into
#' memory, and stores it in `$all_movies`. Call `$filter()` to obtain a
#' filtered data frame for rendering. Call `$disconnect()` to close the
#' connection explicitly; the private `finalize()` method also calls it when
#' the object is garbage collected.
#'
#' Logging is handled via the `logger` package. Set the threshold with
#' `logger::log_threshold()` before initializing the class.
#'
#' @export
MovieData <- R6::R6Class(
  classname = "MovieData",
  public = list(
    #' @field con Active `DBI` database connection.
    con = NULL,
    #' @field all_movies Full joined and collected data frame.
    all_movies = NULL,

    #' @description Connect to the SQLite database and load all movie data.
    #' @param db_path Path to the `movies.db` SQLite file.
    initialize = function(db_path) {
      logger::log_info("Connecting to database: {db_path}")
      tryCatch(
        {
          self$con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
          logger::log_info("Database connection established")
        },
        error = function(e) {
          logger::log_error("Failed to connect to database: {conditionMessage(e)}")
          stop(e)
        }
      )
      tryCatch(
        {
          self$all_movies <- private$load_data()
          logger::log_info("Loaded {nrow(self$all_movies)} movies into memory")
        },
        error = function(e) {
          logger::log_error("Failed to load movie data: {conditionMessage(e)}")
          stop(e)
        }
      )
    },

    #' @description Filter the in-memory data frame using input values.
    #' @param reviews Minimum number of Rotten Tomatoes reviews.
    #' @param oscars Minimum number of Oscar wins.
    #' @param year Integer vector of length 2: `c(min_year, max_year)`.
    #' @param boxoffice Numeric vector of length 2: box-office range in millions.
    #' @param genre Genre string; `"All"` disables the filter.
    #' @param director Partial director name; empty string disables the filter.
    #' @param cast Partial cast name; empty string disables the filter.
    #' @return A filtered data frame with an added `has_oscar` column.
    filter = function(
      reviews   = 10,
      oscars    = 0,
      year      = c(1940, 2014),
      boxoffice = c(0, 800),
      genre     = "All",
      director  = "",
      cast      = ""
    ) {
      logger::log_debug(
        "Filter params: reviews={reviews}, oscars={oscars}, ",
        "year={year[1]}-{year[2]}, boxoffice={boxoffice[1]}-{boxoffice[2]}, ",
        "genre={genre}, director='{director}', cast='{cast}'"
      )
      tryCatch(
        {
          min_box <- boxoffice[1] * 1e6
          max_box <- boxoffice[2] * 1e6

          m <- self$all_movies |>
            dplyr::filter(
              Reviews   >= reviews,
              Oscars    >= oscars,
              Year      >= year[1],
              Year      <= year[2],
              BoxOffice >= min_box,
              BoxOffice <= max_box
            )

          if (genre != "All") {
            m <- m |> dplyr::filter(grepl(genre, Genre, fixed = TRUE))
          }
          if (!is.null(director) && nchar(trimws(director)) > 0) {
            m <- m |> dplyr::filter(grepl(director, Director, ignore.case = TRUE))
          }
          if (!is.null(cast) && nchar(trimws(cast)) > 0) {
            m <- m |> dplyr::filter(grepl(cast, Cast, ignore.case = TRUE))
          }

          m$has_oscar <- ifelse(m$Oscars >= 1, "Yes", "No")
          m <- as.data.frame(m)

          if (nrow(m) == 0) {
            logger::log_warn("Filter returned 0 rows; current inputs may be too restrictive")
          } else {
            logger::log_debug("Filter returned {nrow(m)} rows")
          }
          m
        },
        error = function(e) {
          logger::log_error("Filter operation failed: {conditionMessage(e)}")
          stop(e)
        }
      )
    },

    #' @description Explicitly close the database connection.
    #' Call this from `shiny::onStop()` or in tests via `on.exit()`.
    disconnect = function() {
      if (!is.null(self$con) && DBI::dbIsValid(self$con)) {
        tryCatch(
          {
            DBI::dbDisconnect(self$con)
            logger::log_info("Database connection closed")
          },
          error = function(e) {
            logger::log_warn("Error while closing database connection: {conditionMessage(e)}")
          }
        )
      }
    }
  ),

  private = list(
    finalize = function() {
      self$disconnect()
    },

    load_data = function() {
      logger::log_debug("Joining omdb and tomatoes tables")
      omdb     <- dplyr::tbl(self$con, "omdb")
      tomatoes <- dplyr::tbl(self$con, "tomatoes")

      result <- dplyr::inner_join(omdb, tomatoes, by = "ID") |>
        dplyr::filter(Reviews >= 10) |>
        dplyr::select(
          ID, imdbID, Title, Year,
          Rating_m  = Rating.x,
          Runtime, Genre, Released,
          Director, Writer,
          imdbRating, imdbVotes,
          Language, Country, Oscars,
          Rating    = Rating.y,
          Meter, Reviews, Fresh, Rotten,
          userMeter, userRating, userReviews,
          BoxOffice, Production, Cast
        ) |>
        dplyr::collect()

      logger::log_debug("Collected {nrow(result)} rows from joined tables")
      result
    }
  )
)

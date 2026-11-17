# Process one year of raw EPA measurements into one observation per date.
# file_path: CSV path with Date, pollutant concentrations, and their units.
# ozone_units: output ozone units, "ppm" (default) or "ppb".
# Returns: a date-sorted tibble with date, co, pm25, o3, and unit columns.
# Daily means exclude missing readings; all-missing days retain NA.
process_air_quality <- function(file_path, ozone_units = "ppm") {
  ozone_units <- match.arg(ozone_units, c("ppm", "ppb"))

  # 1. Read the file and give the original columns short, consistent names.
  raw <- read.csv(
    file_path,
    check.names = FALSE,
    na.strings = c("", "NA"),
    stringsAsFactors = FALSE
  )
  names(raw) <- trimws(names(raw))

  # Each name on the left is the short name used throughout the project.
  column_names <- c(
    date = "Date",
    co = "Daily Max 8-hour CO Concentration",
    units_co = "units_CO",
    pm25 = "Daily Mean PM2.5 Concentration",
    units_pm25 = "units_PM",
    o3 = "Daily Max 8-hour Ozone Concentration",
    units_o3 = "units_O3"
  )
  if (!all(column_names %in% names(raw))) {
    stop("CSV is missing required columns.")
  }
  if (nrow(raw) == 0L) {
    stop("CSV contains no measurements.")
  }
  raw <- raw[unname(column_names)]
  names(raw) <- names(column_names)

  # 2. Remove complete duplicate records before they receive extra weight.
  raw <- dplyr::distinct(raw)

  # 3. Parse and validate dates. Accept both 1/2/2020 and 01/02/2020.
  dates <- as.Date(raw$date, format = "%m/%d/%Y")
  input_dates <- gsub("(^|/)0", "\\1", raw$date)
  parsed_dates <- gsub("(^|/)0", "\\1", format(dates, "%m/%d/%Y"))
  if (anyNA(dates) || any(input_dates != parsed_dates)) {
    stop("Dates must be valid dates in MM/DD/YYYY format.")
  }
  if (length(unique(format(dates, "%Y"))) != 1L) {
    stop("Supply one year at a time.")
  }

  # 4. Validate units. A missing reading may also have a missing unit.
  expected_units <- c(co = "ppm", pm25 = "ug/m3 LC", o3 = "ppm")
  for (pollutant in names(expected_units)) {
    readings <- raw[[pollutant]]
    units <- raw[[paste0("units_", pollutant)]]
    wrong_unit <- !is.na(units) & units != expected_units[[pollutant]]
    missing_unit <- !is.na(readings) & is.na(units)
    if (any(wrong_unit) || any(missing_unit)) {
      stop("Expected raw units: CO ppm, PM2.5 ug/m3 LC, and ozone ppm.")
    }
  }

  # 5. Correct individual negative readings before calculating daily means.
  # For example, readings -2 and 4 become 0 and 4, giving a daily mean of 2.
  # Averaging first would incorrectly give 1. Missing readings stay missing.
  clean <- dplyr::tibble(date = dates, co = raw$co, pm25 = raw$pm25, o3 = raw$o3)
  for (pollutant in names(expected_units)) {
    readings <- clean[[pollutant]]
    invalid_reading <- !is.finite(readings) & !is.na(readings)
    if (!is.numeric(readings) || any(invalid_reading)) {
      stop("Concentrations must be numeric and finite, or missing.")
    }
    clean[[pollutant]] <- pmax(readings, 0)
  }

  # 6. Average each pollutant within date, retaining NA for all-missing days.
  daily <- clean |>
    dplyr::group_by(date) |>
    dplyr::summarise(
      dplyr::across(
        c(co, pm25, o3),
        ~ if (all(is.na(.x))) NA_real_ else mean(.x, na.rm = TRUE)
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(date)

  # 7. Convert ozone only if requested, and attach the output units.
  if (ozone_units == "ppb") {
    daily$o3 <- daily$o3 * 1000
  }
  dplyr::mutate(
    daily,
    units_co = "ppm",
    units_pm25 = "ug/m3 LC",
    units_o3 = ozone_units
  )
}

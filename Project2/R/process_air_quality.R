# Process one year of raw EPA air quality measurements into daily observations.
# file_path: path to a CSV with Date, three concentration columns, and unit columns.
# ozone_units: output ozone units, either "ppm" (default) or "ppb".
# Returns: a tibble sorted by date, with date, co, pm25, o3, and unit columns;
# concentrations are daily means of non-missing, corrected, deduplicated rows.
process_air_quality <- function(file_path, ozone_units = "ppm") {
  ozone_units <- match.arg(ozone_units, c("ppm", "ppb"))
  raw <- read.csv(file_path, check.names = FALSE, na.strings = c("", "NA"),
                  stringsAsFactors = FALSE)
  names(raw) <- trimws(names(raw))
  required <- c("Date", "Daily Max 8-hour CO Concentration", "units_CO",
                "Daily Mean PM2.5 Concentration", "units_PM",
                "Daily Max 8-hour Ozone Concentration", "units_O3")
  if (!all(required %in% names(raw))) stop("CSV is missing required columns.")
  if (nrow(raw) == 0L) stop("CSV contains no measurements.")
  raw <- raw[required]
  # Remove complete duplicate records before they can receive extra weight.
  raw <- dplyr::distinct(raw)
  dates <- as.Date(raw$Date, format = "%m/%d/%Y")
  if (anyNA(dates) || any(gsub("(^|/)0", "\\1", format(dates, "%m/%d/%Y")) !=
                          gsub("(^|/)0", "\\1", raw$Date))) {
    stop("Dates must be valid dates in MM/DD/YYYY format.")
  }
  if (length(unique(format(dates, "%Y"))) != 1L) stop("Supply one year at a time.")
  if (any(!is.na(raw$units_CO) & raw$units_CO != "ppm") ||
      any(!is.na(raw$units_PM) & raw$units_PM != "ug/m3 LC") ||
      any(!is.na(raw$units_O3) & raw$units_O3 != "ppm") ||
      any(!is.na(raw[[required[2]]]) & is.na(raw$units_CO)) ||
      any(!is.na(raw[[required[4]]]) & is.na(raw$units_PM)) ||
      any(!is.na(raw[[required[6]]]) & is.na(raw$units_O3))) {
    stop("Expected raw units: CO ppm, PM2.5 ug/m3 LC, and ozone ppm.")
  }
  clean <- dplyr::tibble(date = dates, co = raw[[required[2]]],
                          pm25 = raw[[required[4]]], o3 = raw[[required[6]]])
  # Correct individual readings before averaging: mean(max(x,0)) differs
  # from max(mean(x),0). Missing concentrations are preserved.
  for (pollutant in c("co", "pm25", "o3")) {
    if (!is.numeric(clean[[pollutant]]) ||
        any(!is.finite(clean[[pollutant]]) & !is.na(clean[[pollutant]]))) {
      stop("Concentrations must be numeric and finite, or missing.")
    }
    clean[[pollutant]] <- pmax(clean[[pollutant]], 0)
  }
  daily <- clean |>
    dplyr::group_by(date) |>
    dplyr::summarise(dplyr::across(c(co, pm25, o3),
      ~ if (all(is.na(.x))) NA_real_ else mean(.x, na.rm = TRUE)),
      .groups = "drop") |>
    dplyr::arrange(date)
  if (ozone_units == "ppb") daily$o3 <- daily$o3 * 1000
  dplyr::mutate(daily, units_co = "ppm", units_pm25 = "ug/m3 LC",
                units_o3 = ozone_units)
}

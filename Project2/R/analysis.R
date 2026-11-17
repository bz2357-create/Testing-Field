# Run from the Project2 folder; used both directly and by the RMarkdown report.
library(dplyr)
library(tidyr)
library(ggplot2)
source("R/process_air_quality.R")

# 1. Clean each input year and combine the daily observations.
years <- 2018:2020
annual_data <- lapply(years, function(yr) {
  process_air_quality(file.path("data", paste0("AQ_", yr, ".csv")))
})
names(annual_data) <- as.character(years)
daily <- bind_rows(annual_data) |>
  mutate(year = as.integer(format(date, "%Y")),
         month = as.integer(format(date, "%m")))

# 2. Reshape to one row per date and pollutant for grouped summaries.
long <- daily |>
  pivot_longer(c(co, pm25, o3), names_to = "pollutant", values_to = "value")

# 3. Pool daily values by calendar month, rather than averaging yearly means.
# Each day has equal weight. n excludes missing readings for that pollutant.
# The assignment specifies a normal 95% CI: mean +/- 1.96 * SD / sqrt(n).
monthly <- long |>
  group_by(month, pollutant) |>
  summarise(n = sum(!is.na(value)), mean = mean(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE), .groups = "drop") |>
  mutate(se = sd / sqrt(n), lower = mean - 1.96 * se,
         upper = mean + 1.96 * se)

# 4. Find annual ranges from the processed daily averages.
annual_ranges <- long |>
  group_by(year, pollutant) |>
  summarise(n = sum(!is.na(value)), minimum = min(value, na.rm = TRUE),
            maximum = max(value, na.rm = TRUE), .groups = "drop")

# 5. Average daily PM2.5 separately for each month and year.
pm_monthly <- daily |>
  group_by(year, month) |>
  summarise(n = sum(!is.na(pm25)), pm25 = mean(pm25, na.rm = TRUE),
            .groups = "drop")

# 6. Build both figures with a shared, readable theme.
# Use a colorblind-friendly palette, panel labels, and year line types.
plot_theme <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(size = 10),
        legend.position = "bottom", strip.text = element_text(face = "bold"))

# Separate y scales keep ozone visible without a potentially confusing dual axis.
co_o3_plot <- monthly |>
  filter(pollutant %in% c("co", "o3")) |>
  mutate(pollutant = factor(pollutant, levels = c("co", "o3"),
                           labels = c("CO (ppm)", "Ozone (ppm)"))) |>
  ggplot(aes(month, mean, color = pollutant)) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = .17, linewidth = .55) +
  geom_point(size = 2.5) +
  facet_wrap(~pollutant, ncol = 1, scales = "free_y") +
  scale_color_manual(values = c("#0072B2", "#D55E00"), name = "Pollutant") +
  scale_x_continuous(breaks = 1:12, labels = month.abb, limits = c(.6, 12.4)) +
  labs(title = "CO and ozone show different seasonal patterns",
       subtitle = "Pooled daily means with 95% confidence intervals, 2018-2020",
       x = "Month", y = "Daily concentration (ppm)") + plot_theme +
  guides(color = "none")

# Lines stop at the last observed month; no values are added after April 2020.
pm_plot <- ggplot(pm_monthly,
    aes(month, pm25, color = factor(year), linetype = factor(year), group = year)) +
  geom_line(linewidth = .7) + geom_point(size = 2.3) +
  scale_color_manual(values = c("#0072B2", "#D55E00", "#009E73"), name = "Year") +
  scale_linetype_manual(values = c("solid", "dashed", "dotdash"), name = "Year") +
  scale_x_continuous(breaks = 1:12, labels = month.abb, limits = c(.6, 12.4)) +
  labs(title = "Monthly PM2.5 concentrations vary by year",
       subtitle = "Mean of available daily concentrations; 2020 ends in April",
       x = "Month", y = "PM2.5 (ug/m3 LC)") + plot_theme

# 7. Export the daily data, summaries, and figures for independent checking.
dir.create("output", showWarnings = FALSE)
write.csv(daily, "output/daily_air_quality.csv", row.names = FALSE, na = "")
write.csv(annual_ranges, "output/annual_ranges.csv", row.names = FALSE)
write.csv(monthly, "output/monthly_pooled_summary.csv", row.names = FALSE)
write.csv(pm_monthly, "output/pm25_monthly_by_year.csv", row.names = FALSE)
ggsave("output/co_ozone_monthly.png", co_o3_plot, width = 6.8, height = 4.5, dpi = 300)
ggsave("output/pm25_monthly.png", pm_plot, width = 6.8, height = 3.4, dpi = 300)

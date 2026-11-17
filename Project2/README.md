# RDU Airport Air Quality Exploration

This BIOSTAT 721 Project 2 cleans daily pollution measurements and explores pollutant patterns relevant to planning a sickle cell disease study in Durham County, North Carolina. The supplied files contain exposure measurements only; no patient outcomes are analyzed.

Author: Bowen Zhang
Date: November 17, 2026
GitHub: https://github.com/bz2357-create/Testing-Field/tree/main/Project2

## Data source

EPA air pollution monitor at RDU airport, supplied with the assignment in data-7.zip. Original files cover 2018, 2019, and January 1-April 30, 2020 and are preserved in data/. A station identifier and original EPA download URL were not provided, so none is inferred.

## File structure

- Project2.Rproj: RStudio project; Git metadata and the remote are in the parent repository.
- data/: original AQ_2018.csv, AQ_2019.csv, and AQ_2020.csv.
- R/process_air_quality.R: documented single-year cleaning function.
- R/analysis.R: combines years, calculates summaries, and builds both plots.
- Zhang_Bowen_Project2.Rmd: report source with hidden code.
- reference.docx: Word formatting reference.
- render_project.R: report rendering entry point.
- output/Zhang_Bowen_Project2.docx: final Word report.
- output/: processed daily data, annual ranges, pooled monthly statistics, monthly PM2.5 summaries, figure PNGs, and sessionInfo.txt.
- tests/test_cleaning.R: hand-calculated cleaning checks.
- tests/verify_outputs.py: independent numerical audit using Python's standard library.
- docs/superpowers/plans/: implementation decisions and checklist.

## Reproduce

Use R 4.1 or later (tested on R 4.3.2), RStudio or another Pandoc installation, and dplyr, tidyr, ggplot2, knitr, and rmarkdown.

1. Clone this repository, or extract the complete submission ZIP while preserving its .git directory.
2. Open Project2/Project2.Rproj in RStudio. The working directory should be Project2.
3. Install missing packages once:

```r
install.packages(c("dplyr", "tidyr", "ggplot2", "knitr", "rmarkdown"))
```

4. Run `source("render_project.R")` in the R console, or click Knit in the RMarkdown source. From a terminal in Project2, run `Rscript render_project.R`.
5. Open output/Zhang_Bowen_Project2.docx.

RStudio supplies Pandoc. The script also detects the macOS RStudio copy when run from a terminal. On other systems without RStudio, install Pandoc on PATH or set RSTUDIO_PANDOC to its containing directory. output/sessionInfo.txt records the tested R environment. Installed RMarkdown/knitr versions emit xfun and Pandoc deprecation notices; these did not prevent report generation.

Run checks from Project2 after rendering:

```sh
Rscript tests/test_cleaning.R
python3 tests/verify_outputs.py
```

Python 3 is optional and needed only for the independent audit.

## Methods

`process_air_quality(file_path, ozone_units = "ppm")` removes complete duplicate raw records before daily averaging and corrects individual negative readings to zero before averaging. A loop applies this correction to all three pollutants. Missing values are excluded when calculating a daily mean; all-missing days remain NA and absent dates are not imputed. Dates with or without leading zeros are accepted. Non-missing raw measurements must have the expected units.

Ozone defaults to ppm; use `process_air_quality("data/AQ_2018.csv", ozone_units = "ppb")` for ppb. The report uses ppm throughout. The combined data have 847 observed dates: 361 in 2018, 365 in 2019, and 121 in 2020.

Yearly tables summarize processed daily values to three decimal places. Plot 1 pools all non-missing daily values for each calendar month across available years, with mean +/- 1.96 * SD / sqrt(n). Separate CO and ozone panels have independent, labeled ppm scales. January-April include three years and later months two. These descriptive intervals do not adjust for serial correlation. Plot 2 connects monthly means of daily PM2.5 by year, with no continuation beyond April 2020; color and line type distinguish years.

## Submission and AI use

The complete repository ZIP includes Project2, the earlier ICA16 files, and Git metadata to preserve the GitHub connection and development history. After extraction, open Project2/Project2.Rproj. Review the report and code before submitting the ZIP to Canvas. The assignment deadline is November 19, 2026 at 5 pm EST. Canvas submission is a separate step.

OpenAI Codex assisted with code, report drafting, numerical checks, and layout review. The report includes the required AI use statement and distinguishes automated checks from personal review.

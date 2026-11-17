# Run from the Project2 directory: Rscript render_project.R
# RStudio normally supplies Pandoc. This fallback locates its macOS copy.
if (!rmarkdown::pandoc_available()) {
  candidates <- Sys.glob(
    "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/*/pandoc"
  )
  if (length(candidates) > 0L) {
    Sys.setenv(RSTUDIO_PANDOC = dirname(candidates[1]))
  }
}
if (!rmarkdown::pandoc_available()) {
  stop("Pandoc not found. Knit in RStudio or install Pandoc.")
}

# Render the report, then record the R environment used to generate it.
rmarkdown::render(
  "Zhang_Bowen_Project2.Rmd",
  output_dir = "output",
  clean = TRUE
)
writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")

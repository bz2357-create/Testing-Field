# ICA 16: A tiny example of R code for Git practice
# Change the title or the seed to make this example your own.

set.seed(721)
steps <- rnorm(100)
position <- cumsum(steps)

# Print a simple summary to the R console.
cat("Final position:", round(tail(position, 1), 2), "\n")

# Draw a plot using base R (no packages required).
plot(
  position,
  type = "l",
  lwd = 2,
  col = "steelblue",
  main = "A Random Walk in R",
  xlab = "Step",
  ylab = "Position"
)
abline(h = 0, lty = 2, col = "gray60")

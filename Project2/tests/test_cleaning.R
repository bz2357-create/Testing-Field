# These checks catch duplicate weighting, clipping after averaging, lost NA,
# incorrect ozone conversion, and invalid dates/units being accepted.
stopifnot(file.exists("R/process_air_quality.R"))
source("R/process_air_quality.R")
f <- tempfile(fileext = ".csv")
x <- data.frame(Date=c("01/01/2020", "01/01/2020", "01/01/2020", "1/2/2020"),
 co=c(1,1,3,NA), units_CO="ppm", pm25=c(-2,-2,4,NA),
 units_PM="ug/m3 LC", o3=c(.01,.01,.03,NA), units_O3="ppm")
names(x)[c(2,4,6)] <- c("Daily Max 8-hour CO Concentration", "Daily Mean PM2.5 Concentration", "Daily Max 8-hour Ozone Concentration")
x$units_CO[4] <- NA
x$units_PM[4] <- NA
x$units_O3[4] <- NA
write.csv(x,f,row.names=FALSE,na="")
y <- process_air_quality(f)
stopifnot(nrow(y)==2L, inherits(y$date,"Date"), y$co[1]==2,
 y$pm25[1]==2, y$o3[1]==.02, is.na(y$co[2]), is.na(y$pm25[2]),
 is.na(y$o3[2]), y$units_o3[1]=="ppm")
z <- process_air_quality(f,"ppb")
stopifnot(z$o3[1]==20, z$units_o3[1]=="ppb")
stopifnot(inherits(try(process_air_quality(f,"bad"),silent=TRUE),"try-error"))
x$Date[1] <- "02/30/2020"
write.csv(x,f,row.names=FALSE)
stopifnot(inherits(try(process_air_quality(f),silent=TRUE),"try-error"))
unlink(f)
cat("Cleaning fixture checks passed.\n")



# install required packages for all functions in this project directory

packages <- c("raster", 
              "sp", 
              "ggplot2", 
              "rgeos", 
              "rgdal", 
              "plyr", 
              "openxlsx",
              "doSNOW", 
              "foreach", 
              "parallel", 
              "doParallel", 
              "stats", 
              "maptools", 
              "dplyr", 
              "geosphere", 
              "shp2graph", 
              "igraph",
              "stats", 
              "ggmap", 
              "dplyr", 
              "Hmisc", 
              "broom", 
              "colorspace",
              "RColorBrewer", 
              "spatial", 
              "tidyr", 
              "R.utils", 
              "GISTools",
              "kimisc", 
              "knitr",
              "spatialEco")

if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}
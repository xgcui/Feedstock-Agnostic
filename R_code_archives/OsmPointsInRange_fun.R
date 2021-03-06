
#-----------------------------------------------------------------------------#
# PointsInRange_fun.R

# Type: R function script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A function to perform a network analysis to determine which counties are 
# within a specified range (either drive time or drive distance) of a focal 
# point. 

# PARAMETERS:
# hubs.data - object of class SpatialPointsDataFrame with the points to use as
# "hubs," or start points of the network analysis. 
# E.g. biorefineries. 
# points.data - object of class SpatialPointsDataFrame containing the 
# destination points to be used in the network analsysis. 
# E.g. county centroids.
# constraint - a charater (either "time" or "distance") indicating type of 
# constraint to set for determining whether points are in range of hubs. 
# max.dist - numeric inidicating the drive distance (in miles) to use as an 
# upper bound for determining which points are within range of hubs.   
# max.time - numeric inidicating the drive time (in hours) to use as an 
# upper bound for determining which points are within range of hubs. 

# RETURNS:
# list of lists in which first element is RID and second is
# character vector of county names within specified range of refinery

#-----------------------------------------------------------------------------#

# TEMP: set wd for testing function locally in IDE

# a basic function to get the filepath of the current script
csf <- function() {
  # adapted from http://stackoverflow.com/a/32016824/2292993
  cmdArgs = commandArgs(trailingOnly = FALSE)
  needle = "--file="
  match = grep(needle, cmdArgs)
  if (length(match) > 0) {
    # Rscript via command line
    return(normalizePath(sub(needle, "", cmdArgs[match])))
  } else {
    ls_vars = ls(sys.frames()[[1]])
    if ("fileName" %in% ls_vars) {
      # Source'd via RStudio
      return(normalizePath(sys.frames()[[1]]$fileName))
    } else {
      if (!is.null(sys.frames()[[1]]$ofile)) {
        # Source'd via R console
        return(normalizePath(sys.frames()[[1]]$ofile))
      } else {
        # RStudio Run Selection
        # http://stackoverflow.com/a/35842176/2292993
        return(normalizePath(rstudioapi::getActiveDocumentContext()$path))
      }
    }
  }
}

this.dir <- dirname(csf())
setwd(this.dir)
rm(list=ls())

# PointsInRange <- function(hubs.data, points.data, constraint,
#                           max.dist = NULL, max.time = NULL) {
  
  # TEMP: set dummy params for local function testing
  hubs.data <- readRDS("../clean_binary_data/biorefs.sptdf.RDS")
  points.data <- readRDS("../output/ILLINOIS_wtd_cntroids.sptdf.RDS")
  constraint = c("distance")
  max.dist = 50
  
  ###### LOAD LIBRARIES #######
  packages <- c("ggmap", "raster", "sp", "ggplot2", "rgeos",
                "spatialEco")
  if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
    install.packages(setdiff(packages, rownames(installed.packages())))  
  }
  
  library(ggplot2)
  library(ggmap)
  library(raster)
  library(sp)
  library(rgeos)
  library(spatialEco)
  
  ###### SOURCE LOCAL FUNCTIONS ######
  source("OsmRoute_fun.R")
  source("OsmFunctionUtils_fun.R")
  
  ###### SET GLOBAL VARS ######
  wgs84.crs <- crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  
  
  ###### PERFORM NET ANALYSIS #######
  
  # init output list of FIPS vectors
  output.fips.ls <- vector("list", length = nrow(hubs.data))
  
  # iterate over all bioref locations
  #for (RID in seq_along(hubs.data$RID)){
  
  # TEMP: subset for iowa refs
  iowa.refs <- (hubs.data[hubs.data$STATE == "IA", ])$RID
  
  # TEMP: constrain RID sequence
  for (RID in c(9, 10, 21)){
    
    print(paste("Working on refinery with RID: ", RID), echo = T)
    # TEMP: 
    #RID = 22
    
    # subset for particular bioref
    par.bioref <- hubs.data[hubs.data$RID == RID,]
    
    
    # establish search space of counties based on buffer radius
    buff.rad <- 100 # set radius in miles
    buff.rad <- 1609.34*buff.rad # convert to meters
    
    # create buffer around focal refinery
    buff <- gBuffer(par.bioref, byid = F, 
                    width = buff.rad,         
                    quadsegs = 100)
    
    # set buffer CRS
    #refinery_buff.sp <- spTransform(refinery_buff.sp, aea.crs)
    
    # subset county points.data for those in search space
    cand.counties <- crop(points.data, buff)
    
    if (constraint == "time"){
      # set threshold travel time (in hours)
      max.hrs <- max.hrs
    }
    
    if (constraint == "distance"){
      # set threshold travel dist in miles
      max.dist <- max.dist
    }
    
    # init vector for counties in range
    in.range <- c(NULL)
    
    # iterate over candidate counties
    for (fips in cand.counties$FIPS){
      
      # pause to comply with GoogleMaps API query rate limit
      Sys.sleep(1) 
      
      print(paste("Checking county with FIPS code: ", fips), echo = T)
      
      # TEMP:
      #fips = 39001
      
      # get start point coords in WGS 84 CRS
      par.bioref.wgs <- spTransform(par.bioref, wgs84.crs)
      start <- round(as.numeric(par.bioref.wgs@coords[1,]), 5)
      start <- paste(start[2], start[1], sep = ", ")
      
      # get end point
      cand.counties.wgs <- spTransform(cand.counties, wgs84.crs)
      end <- cand.counties.wgs[cand.counties.wgs$FIPS == fips, ]
      end <- round(as.numeric(end@coords[1,]), 5)
      end <- paste(end[2], end[1], sep = ", ")
      
      # calculate route
      rt <- OsmRoute(start, end, overview = "simplified", sp = FALSE)
      
      # calculate total distance of route
      tmiles <- sum(na.omit(rt$miles))
      
      # calculate total travel time of route in hrs
      thrs <- sum(na.omit(rt$hours))
      print(paste("Travel time (hrs): ", thrs))
      print(paste("Drive distance (miles): ", tmiles))
      
      # if travel time is less than thresh, save county FIPS to in.range
      if (constraint == "time"){
        if (thrs <= max.hrs){
          in.range <- c(in.range, fips)
        }
      }
      if (constraint == "distance"){
        if (tmiles <= max.dist){
          in.range <- c(in.range, fips)
          print("County in range")
        } else {
          print("County not in range")
        }
      }
    }
    
    print (paste("FIPs of counties in range: ", in.range))
    
    # create subset of county centroids for counties in range
    in.range.centroids <- cand.counties[cand.counties$FIPS %in% in.range, ]
    
    # if no counties in range assign NA to FIPS_IN_RANGE col
    if (is.null(in.range)){
      output.fips.ls[[RID]] <- NA
    } else {
      
      # add in.range FIPS list to output list
      output.fips.ls[[RID]] <- in.range 
    }
    
  }
  # construct output df
  output.df <- data.frame(FIPS_IN_RANGE = I(output.fips.ls))
  #saveRDS(output.df, "../output/sample_catchment_output.RDS")
  
  return(output.df)
#}

# 
# ls <-list (1:3, 4:6, 4:9)
# v = (1:3)
# output.ls[[RID]][[2]] <- list(v)
# 
# 
# dfl <- data.frame(x = 1:3, y = I(list(1:2, 1:3, 1:4)))
# 
# output <- data.frame(RID = as.numeric(), FIPS_IN_RANGE = I(list()))
# output[2, 2] <- v
# 
# str(output)
# output[6,2] <- 5
# 
# 
# 
# 
# 
# output[RID, FIPS_VECTORS] <- I(list(in.range)) 



# plots for development and testing
# plot(counties.spdf)
# plot(cand.counties, add = T)
# plot(buff, add = F)
# plot(buff, add = T, col = 'red')
# plot(par.bioref, add = T, col = 'blue', pch = 16)
# plot(in.range.centroids, add = T, col = "orange")





#-----------------------------------------------------------------------------#
# CheckIfInRange_fun.R

# Type: R function script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A function to perform a network analysis to determine which counties are 
# within a specified range (either drive time or drive distance) of a focal 
# point using the TIGER/Line US primary and secondary road network.

# PARAMETERS:
# cid - the Centroid ID to check
# par.bioref - the focal biorefinery to check
# cand.counties - a SpatialPolygonsDataFrame of the counties that contain 
  # all CIDs that could potentially fall within the bioshed of par.bioref
# edges.data - road network as a SpatialLinesDataFrame
# to be used in shortest-path routing computation 

# RETURNS:
# list of lists in which first element is RID and second is
# character vector of county names within specified range of refinery

#-----------------------------------------------------------------------------#

# define function to parallelize routing computations
CheckIfInRange <- function(cid, par.bioref, cand.counties, edges.data) {
  
  # set coord ref systems
  wgs84.crs <- crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  aea.crs <- CRS("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23.0
                 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 
                 +units=m +no_defs")
  
  # load shortest path routing function
  source("CalcDriveRoute_fun.R")
  
  # get this refinery's RID
  RID <- par.bioref$RID
  
  cat(sprintf("Checking refinery with RID: %s and centroid with CID: %s", 
              RID, cid), echo = T)
  
  # init in.range vector to store results
  in.range <- c(NULL)
  
  # get start point coords in WGS 84 CRS
  par.bioref.wgs <- spTransform(par.bioref, wgs84.crs)
  start <- par.bioref.wgs@coords[1,]
  
  # get end point
  cand.counties.wgs <- spTransform(cand.counties, wgs84.crs)
  end <- cand.counties.wgs[cand.counties.wgs$cid == cid, ]
  end <- end@coords[1,]
  names(end) <- c("long", "lat")
  
  # calculate route
  rt <- CalcDriveRoute(edges.data, start, end)
  
  # calculate total distance of route in meters
  dist.df <- rt[[1]]
  
  # convert to miles
  tmiles <- dist.df$DIST.MI[1]
  
  # print dist
  cat(paste0("\nDrive distance (miles): ", tmiles))
  
  # if travel time is less than thresh, save county CIDs to in.range
  # if (constraint == "time"){
  #   if (thrs <= max.hrs){
  #     return(cid)
  #   }
  # }
  if (constraint == "distance"){
    if (tmiles <= max.dist) {
      cat("\nCentroid in range")
      return(cid)
    } else {
      cat("\nCentroid not in range")
      return()
    }
  }
}
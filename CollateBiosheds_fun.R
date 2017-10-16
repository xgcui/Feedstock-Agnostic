
#-----------------------------------------------------------------------------#
# CollateBiosheds_fun.R
# Type: R function script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A script to collate the bioshed calculated and saved in separate binary data
# files for each refinery. 

# PARAMS:
# biorefs.data - object of class SpatialPointsDataFrame containing biorefinery
  # locations. 
# crop - primary crop in CDL layer (e.g. "Corn", "Wheat", "Oats") for which to
  # collate refinery bioshed data. 
# range - the maximum drive distance constaint to use for network analysis
  # to determine cluster centroids in range of refinery locations
#

# RETURNS:
# None


# SIDE-EFFECTS:
# outputs a binary data file (.RDS) to the '/output/data_products/' directory
# containing a dataframe with two colums: CIDS_IN_RANGE and RID. Each 
# CIDS_IN_RANGE is a list of the Centroid IDs (CIDs) that fell within the 
# bioshed denoted by the Refinery ID (RID) number in the same row of the df. 



#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

CollateBiosheds <- function(biorefs.data, crop, range) {
  
  ###### LOAD LIBRARIES #######
  
  require(raster)
  require(sp)
  require(rgeos)
  require(maptools)
  require(dplyr)
  
  
  ###### SET PARAMS ######

  # units are either "mi" for miles or "km" for kilometers
  range.units <- "mi"
  
  # init sptdf to store collated RID key
  rid.bioshed.df <- data.frame("RID" = character(), 
                               "BIOSHED_CIDS" = character())
  

  # iterate over RID bioshed files
  for (rid in seq(1, nrow(biorefs))) {
    par.bioshed.file <- (paste0("../output/bin/RID_", 
                                rid, "_", crop, 
                                "_bioshed_", range, range.units, ".RDS"))
    
    # check if file exists:
    check <- file.exists(par.bioshed.file)
    
    if (check) {
      par.bioshed <- readRDS(par.bioshed.file)
      par.bioshed <- as.list(par.bioshed)
      row <- data.frame(rid, I(list(par.bioshed)))
      names(row) <- c("RID", "BIOSHED_CIDS")
      rid.bioshed.df <- rbind(rid.bioshed.df, row)
    }
  }
  
  # re-arrange columns
  output.df <- data.frame(rid.bioshed.df$BIOSHED_CIDS, rid.bioshed.df$RID)
  names(output.df) <- c("CIDS_IN_RANGE", "RID")
  
  # export collated biosheds
  saveRDS(output.df, paste0("../output/data_products/cur.ref.biosheds.", 
                            crop, ".", range, range.units, ".RDS"))
  
}















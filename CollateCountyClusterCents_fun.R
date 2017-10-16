
#-----------------------------------------------------------------------------#
# CollateCountyClusterCents_fun.R
# Type: R function script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A script to collate the county-level kmeans cluster centroids for production
# of a particular crop from separate binary data files (one for each county).

# PARAMS:
# crop - the crop (either a primary crop e.g. "Corn" from which a residue 
  # feedstock is derived, or "EnergyCrops" for potential dedicated biofuel crops
  # e.g. Switchgrass, specifying which centroids should be collated
# fips.codes- list of FIPs codes specifying counties whose k-means cluster
  # centroids should be collated. 

# SIDE-EFFECTS:
# outputs a binary data file (.RDS) to the 'output' directory which contains an
# object of class SpatialPointsData frame containing k-means cluster centroids
# for the specified crop across the continental US. 

#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

CollateCountyClusterCents <- function(crop, fips.codes) {
  
  ###### LOAD LIBRARIES ######
  require(broom)
  require(dplyr)
  require(ggplot2)
  require(colorspace)
  require(sp)
  require(maptools)
  require(raster)
  require(rgdal)
  require(spatial)
  require(foreach)
  require(iterators)
  require(parallel) 
  require(parallel)
  require(snow)
  require(doSNOW)
  require(rgeos)
  
  aea.crs <- CRS("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23.0 
                 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 
                 +units=m +no_defs")
  
  ###### LOAD DATA ######
  
  dir <- sprintf("../output/bin/")
  
  county.files <- list.files(dir)
  county.files <- grep(crop, county.files, value = T)
  county.files <- grep("FIPS", county.files, value = T)
  county.files <- grep("cluster.cents.RDS", county.files, value = T)
  
  # init result df for all US cents
  US.cluster.cents <- NULL
  
  # init pass counter
  pass <- 1
  
  for (file in county.files) {
    
    # load county cluster cents
    filepath <- paste0(dir, file)
    county.cents <- readRDS(filepath)
    
    if (pass == 1) {
      US.cluster.cents <- county.cents
    } else {
      
      US.cluster.cents <- rbind(US.cluster.cents, county.cents)
    }
    pass <- pass + 1
  }
  
  
  # convert cluster centers in spatial points
  US.cluster.cents.coords <- US.cluster.cents[ ,1:2]
  US.cluster.cents.sp <- SpatialPoints(US.cluster.cents.coords,
                                       proj4string = aea.crs)
  cluster.data <- US.cluster.cents[ ,3:(ncol(US.cluster.cents))]
  US.cluster.cents.sp <- sp::SpatialPointsDataFrame(US.cluster.cents.sp,
                                                    cluster.data,
                                                    proj4string = aea.crs)
  
  # export all US cluster cents in binary data file
  crop <- gsub(" ", "_", crop)
  saveRDS(US.cluster.cents.sp,
          paste0("../output/data_products/US.cluster.cents.", crop, ".RDS"))
}




#-----------------------------------------------------------------------------#
# MakeBioshedsDataframe_fun.R

# Type: R function script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A function to organize bioshed data into a dataframe and export it as a 
# .csv file

# PARAMS:
# biomass.data - dataframe of Billion Ton Report data
# biorefs.data - SpatialPointsDataframe of biorefinery point locations
# counties.data - SpatialPolygonsDataframe of US county boundaries
# feeds - list of feedstocks to subset from billion ton data 
# years - years to analyze, must be present in biomass.data 
# scenarios - billion ton scenarios to analyze, must be present in biomass.data
# prices - farmgate price per dry ton of biomass
# ranges - maximum drive distance(s) used to define biosheds


# RETURNS:
# None

# SIDE-EFFECTS:
# exports bioshed output data as a .csv file to the /root/output/data_products/
# directory

#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#


MakeBioshedsDataFrame <- function(biomass.data, biorefs.data, counties.data,
                                  feeds, years, scenarios, prices, ranges) {
                                  
  ###### LOAD LIBRARIES #######
  
  require(ggplot2)
  require(ggmap)
  require(raster)
  require(sp)
  require(rgeos)
  require(rgdal)

  
  ###### LOAD FUNCTIONS ######
  source("BtDataSelect_fun.R")
  source("SumBioshedFeeds_fun.R")
  
  no.cores <- (detectCores() - 1)
  cl <- makeCluster(no.cores, type = "SOCK", outfile="")
  registerDoSNOW(cl)
  
  res <- foreach (feed = feeds, .combine = "rbind", 
                  .export = c("BtDataSelect", "SumBioshedFeeds")) %dopar% {
    
    print(paste0("Feedstock: ", feed))
    if (feed == "Corn stover") {
      crop <- "Corn"
    } else if (feed == "Wheat straw") {
      crop <- "Wheat"
    } else if  (feed %in% c("Biomass sorghum", "Switchgrass", "Miscanthus")) {
      crop <- "EnergyCrops"
    }
    
    # read in kmeans cluster cents for the crop that produces this residue
    centroids.file <- paste0("../output/data_products/",
                             "US.cluster.cents.", crop, ".RDS")
    centroids.data <- readRDS(centroids.file)
    n <- 1
    for (year in years) {
      print(paste0("Year: ", year))
      for (range in ranges) {
        print(paste0("Range: ", range))
        for (scenario in scenarios) {
          print(paste0("Scenario: ", scenario))
          for (price in prices) {
            print(paste0("Price: ", price))
            
            
            # define parameters for BT data to use
            yr <- substr(as.character(year), 3,4)
            
            
            # subset BT data
            biomass.df <- BtDataSelect(biomass.data, year, 
                                       scenario, feed, price)
            
            if (nrow(biomass.df) == 0) {
              res <- biorefs.sptdf
              res$Feedstock <- gsub(" ", "_", feed)
              res$Year <- year
              res$Drive.range <- range
              res$Price <- price
              res$Scenario <- scenario
              res$Dt.biomass <- 0
              
            } else {
              
              # load pre-calculated bioshed data 
              range.units <- "mi"
              rid.bioshed.key <- 
                readRDS(paste0("../output/data_products/cur.ref.biosheds.", 
                               crop, ".", range, "mi.RDS"))
              
              # calculate total biomass available to each bioref,
              res <- SumBioshedFeeds(counties.data, biorefs.data,
                                     catchments.data = rid.bioshed.key,
                                     centroids.data = centroids.data,
                                     biomass.df = biomass.df,
                                     feed_choices = feed)
              
              
              drop.cols <- c("All_Feedstocks")
              res <- res[,!(names(res) %in% drop.cols)]
              
              res$Feedstock <- gsub(" ", "_", feed)
              res$Year <- year
              res$Drive.range <- range
              res$Price <- price
              res$Scenario <- scenario
              
              names(res)[names(res) == (gsub(" ", "_", feed))] <- "Dt.biomass"
            }
            
            if(n == 1) {
              result.df <- res
            } else {
              result.df <- rbind(result.df, res)
            }
            n <- n+1
          }
        }
      }
    }
    result.df
                  }
  
  # export as binary data file
  filepath <- "../output/data_products/output.bioshed.data"
  saveRDS(res, paste0(filepath, ".RDS"))
  
  # export as excel spreasheet
  csv.filepath <- paste0(filepath, ".csv")
  write.csv(res@data, csv.filepath, fileEncoding = "UTF-16LE", row.names = F)

  # cancel parallel backend
  stopCluster(cl)
  
  return(result.df)

}












#-----------------------------------------------------------------------------#
# main_analysis.R
# Type: R analysis script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# The full-pipeline analysis script for calculating biosheds of biorefinery
# locations via a road network analysis using estimates of feedstock 
# production distributions at the sub-county level. 

# SIDE-EFFECTS:
# outputs a .csv file with the feedstock supply data for the parameters given.

#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

###### INSTALL & LOAD REQUIRED LIBRARIES #######
source("install_required_packages.R")

require(raster)
require(sp)
require(rgeos)
require(rgdal)
require(plyr)
require(openxlsx)
require(doSNOW)
require(doParallel)
require(snow)
require(iterators)
require(foreach)
require(parallel)
require(stats)
require(Hmisc)
require(RColorBrewer)
require(colorspace)
require(broom)
require(tidyr)
require(shp2graph)
require(igraph)
require(ggmap)
require(ggplot2)
require(dplyr)


# load helper functions
source("ClipMaskVectorizeNLCD_fun.R")
source("GetCropList_fun.R")
source("ClipMaskVectorizeNLCD_fun.R")
source("CalcClusterCentsNLCD_fun.R")
source("CalcBiosheds_fun.R")
source("CollateCountyClusterCents_fun.R")
source("CollateBiosheds_fun.R")
source("ClipVectorizeCDL_fun.R")
source("CalcClusterCentsCDL_fun.R")
source("MakeBioshedsDataFrame_fun.R")


# load raw data
source("load.R")

# clean raw data
source("clean.R")

# load cleaned binary data into workspace
source("load_cleaned_binary.R")

#-----------------------------------------------------------------------------#
### Set model parameters

# choose feedstocks to include in analysis
# note: these must match exactly as named the in billion ton biomass data
feedstocks <- c("Corn stover", "Wheat straw", "Sorghum", 
                "Switchgrass", "Miscanthus", "Oats straw", "Sorghum stubble")

feedstocks <- c("Corn stover", "Switchgrass")

# set max drive distance constraints (in miles) for calculating biosheds
ranges.to.do <- c(40, 50, 60)

# define years to run analysis for
# note: these must correspond to years in Year column of
# billion ton biomass datafile
years <- c(2018, 2030, 2040)  

# set prices per dt of biomass to include in analysis
# note: these must correspond to price levels in Biomass.price column of
# billion ton biomass datafile 
prices <- c(40, 50, 60) 

# define Billion Ton scenarios to run 
# note: these must match exactly the names in scenario column of billion 
# ton biomass datafile
scenarios <- c("Basecase, all energy crops", 
               "2% yield inc.", "3% yield inc.", "4% yield inc.")

scenarios <- c("Basecase, all energy crops")

#-----------------------------------------------------------------------------#
### Initialize parallel backend
no.cores <- (detectCores() - 1)
cl <- makeCluster(no.cores, type = "SOCK", outfile="")
registerDoSNOW(cl)

#-----------------------------------------------------------------------------#
### Run analysis and generate intermediate data products

# determine crop list from feedstocks selected
crops.to.do <- GetCropList(feedstocks)

# generate list of all US county FIPs (or replace with list of FIPs to analyze)
fips.to.do <- unique(counties$FIPS)

## Dedicated energy crop feedstocks:
# set filepath to NLCD raster data
nlcd.raster.path <- ("../raw_data_files/nlcd/nlcd_2011_30m.img")

# vectorize county level rasters of crop/pasture land from NLCD layer
foreach (fips = fips.to.do) %do% {
  ClipMaskVectorizeNLCD(counties, nlcd.raster.path, fips)
}

# find k-means clusters of crop/pasture land (potential energy crop land)
CalcClusterCentsNLCD(counties, fips.to.do)

# aggregate all US county cluster cents into single file
CollateCountyClusterCents(crop = "EnergyCrops", fips.to.do)


for (range in ranges.to.do) {
  # calculate dedicated energy crop biosheds based on crop/pasture kmeans cents
  CalcBiosheds(biorefs, crop = "EnergyCrops", 
                     edges.data = roads, max.dist = range)
  
  # collate biosheds into single file
  CollateBiosheds(biorefs, crop = "EnergyCrops", range)
}


## Crop residue feedstocks:
# set filepath to CDL raster data
cdl.raster.path <- ("../raw_data_files/cdl/cdl_2016_30m.img")

# vectorize county level rasters for select crops from CDL layer
foreach (fips = fips.to.do) %do% {
  ClipVectorizeCDL(counties, cdl.raster.path, fips)
}

for (crop in crops.to.do) {
  
  # calculate cluster centroids
  CalcClusterCentsCDL(counties, cdl.raster.path, crop, fips.codes)
  
  # collate clusters
  CollateCountyClusterCents(crop, fips.to.do)

}

### calculate residue feedstock biosheds
# iterate over crops
for (crop in crops.to.do) {
  
  # iterate over drive distance ranges
  for (range in ranges.to.do) {
    
    # calculate biosheds
    CalcBiosheds(biorefs, crop, edges.data = roads, max.dist = range)
    
    # collate biosheds into single file
    CollateBiosheds(biorefs, crop, range)
  }
}

#-----------------------------------------------------------------------------#
### Generate final results dataframe

results.df <- MakeBioshedsDataFrame(biomass.data, biorefs, counties, 
                                    feedstocks, years, scenarios, 
                                    prices, ranges.to.do)

# empty the intermediate files bin
system("rm ../output/bin/*")





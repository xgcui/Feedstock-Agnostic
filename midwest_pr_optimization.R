#-----------------------------------------------------------------------------#
# midwest_pr_optimization.R

# Type: R analysis script

# AUTHOR:
# Tyler Huntington, 2017
# XG CUI 2017 October
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A script to perform an optimization analysis of potential refinery (PR) 
# lcoations int the Midwestern region of the US.
# This script is re-written by XG CUI 


#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
 source("GetScriptDir_fun.R")
 this.dir <- dirname(GetScriptDir())
 setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

###### INSTALL & LOAD REQUIRED LIBRARIES #######
#source("install_required_packages.R")

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

source("CalcBiosheds_fun.R")
source("BtDataSelect_fun.R")
source("SumBioshedFeeds_fun.R")


#########################################
cat('Loading road, btbiomass data','\n')
## defined the potential refineries in midwest USA
 curr.biorefs <- readRDS("../clean_binary_data/biorefs.sptdf.RDS")
 
 # load county polygons data
 counties <- readRDS("../clean_binary_data/counties.spdf.RDS")
 
 # load US road network
 road.net <- readRDS("../clean_binary_data/roads.sldf.RDS")
 
 # load billion ton study biomass data
 bt.data <- readRDS("../clean_binary_data/bt_biomass_18_30_40.df.RDS")

################################################
cat('Define the location of potential refineries','\n')
 # create boundary of midwest
 mw.states <- c("IL", "IN", "IA", "KS", "MI", "MN", 
                "MO", "NE", "ND","OH", "SD", "WI")
 
 mw.counties <- counties[counties$STATEABBREV %in% mw.states,]
 
 mw.extent <- extent(mw.counties)
 
 # generate raster layer with extent of midwest boundary
 ras <- raster(mw.extent, ncol = 35, nrow = 35)
 proj4string(ras) <- crs(counties)
 
 # convert raster to pts
 p.refs <- rasterToPoints(ras, spatial = T)
 
 # get points within MW boundary
 p.refs <- raster::intersect(p.refs, mw.counties)
 p.refs <- p.refs[,c("STATENAME", "STATEABBREV", "FIPS")]
 p.refs$RID <- 1:length(p.refs)
 rownames(p.refs@data) <- rownames(p.refs@coords) <- p.refs$RID 
 
 # export potential refinery locations
 saveRDS(p.refs, "../output/data_products/mw.potential.ref.points.RDS")
############################################
####### Compute Bioshed 
cat('compute the bioshed','\n')
 
 # driving distance
 range <- 50
 
 # crop type
 crop <- "EnergyCrops"

 
 # calculate biosheds for chosen crop##FindPointsInRange
 biosheds=CalcBiosheds (p.refs,crop = crop, edges.data=road.net,
                        max.dist = range) 
 
 saveRDS(biosheds, paste0("../output/data_products/",
                          "potential_midwest_ref_biosheds_", 
                          crop,'_', range, "mi.RDS"))

#-----------------------------------------------------------------------------#
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
               "2% yield inc.", "3% yield inc.", "4% yield inc.")[1]

# determine biomass availability based on BT data
feeds <- c("Biomass sorghum", "Switchgrass", "Miscanthus")
#-----------------------------------------------------------------------------#
###############################################################################

# subset BT data for particular year, scenario and price per dt
bt.data <- BtDataSelect(bt.data, years, scenarios, feeds, prices)

# load centroids data for chosen crop type 
#  
centroids <- readRDS(paste0("../output/data_products/US.cluster.cents.", crop, ".RDS"))
###############################################################################
################ compute the biomass, which is available for each refinery
cat('compute the biomass in each bioshed','\n')
p.refs.biomass <- SumBioshedFeeds(counties,
                          p.refs,
                          biosheds,
                          centroids,
                          bt.data,
                          feed_choices = feeds)

# export biosheds as spatial object
saveRDS(p.refs.biomass, paste0("../output/data_products/",
                       "potential_midwest_refs_biomass_", 
                       crop,'_',range, "mi.RDS"))

#########################################plot######################################
states <- readRDS("../clean_binary_data/states.spdf.RDS")

tiff(file = "../figures/potential.refs", res = 400, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")
##mw <- raster::aggregate(mw.states)
plot(mw.counties)
plot(states)
plot(p.refs, pch = 16, col = "springgreen3", cex = .4, add = T)

dev.off()
####################################################################################

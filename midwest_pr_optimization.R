#-----------------------------------------------------------------------------#
# midwest_pr_optimization.R

# Type: R analysis script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A script to perform an optimization analysis of potential refinery (PR) 
# lcoations int the Midwestern region of the US.


#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

###### LOAD LIBRARIES #######
packages <- c("ggmap", "raster", "sp", "ggplot2", "rgeos", "rgdal")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

library(ggplot2)
library(ggmap)
library(raster)
library(sp)
library(rgeos)
library(rgdal)

###### SET GLOBAL VARS ######
years <- c(2018, 2030, 2040)
scenarios <- c("Basecase, all energy crops")
feeds <- c("Corn stover", "Wheat straw", "Miscanthus", 
           "Switchgrass", "Biomass sorghum")
prices <- c(40, 50, 60)


###### LOAD CLEANED DATA ######

# load bioref locations data
curr.biorefs <- readRDS("../clean_binary_data/biorefs.sptdf.RDS")

# load county polygons data
counties <- readRDS("../clean_binary_data/counties.spdf.RDS")

# TODO: load centroids data for all US counties
centroids <- readRDS("../output/data_products/US.cluster.cents.sp.RDS")

# load US road network
road.net <- readRDS("../clean_binary_data/roads.sldf.RDS")

# load billion ton study biomass data
bt.data <- readRDS("../clean_binary_data/bt_biomass_18_30_40.df.RDS")


###### LOAD FUNCTIONS ######
source("FindPointsInRange_fun.R")
source("SumBioshedFeeds_CIDS_fun.R")

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
p.refs <- intersect(p.refs, mw.counties)
p.refs <- p.refs[,c("STATENAME", "STATEABBREV", "FIPS")]

# arrange points layer into similar format as current biorefs point layer
p.refs$RID <- 1:length(p.refs)
rownames(p.refs@data) <- rownames(p.refs@coords) <- p.refs$RID

# export potential refinery locations
saveRDS(p.refs, "../output/data_products/mw.potential.ref.points.RDS")


# determine ag cents in range of p.refs
range <- 50
crop <- "EnergyCrops"
biosheds <- FindPointsInRange(p.refs, crop = crop, 
                              road.net, 
                              constraint = "distance", max.dist = range, 
                              max.time = NULL)

saveRDS(biosheds, paste0("../output/data_products/",
                         "potential_midwest_ref_biosheds_", 
                         crop, range, "mi.RDS"))


# subset BT data for particular year, scenario and price per dt
bt.data <- BtDataSelect(bt.data, years, scenarios, feeds, prices)

# determine biomass availability based on BT data
feeds <- c("Biomass sorghum", "Switchgrass", "Miscanthus")
p.refs <- SumBioshedFeeds(counties,
                          p.refs,
                          biosheds,
                          centroids,
                          bt.data,
                          feed_choices = feeds)

saveRDS(p.refs, paste0("../output/data_products/",
                       "potential_midwest_refs_sp_", 
                       crop, range, "mi.RDS"))


#### plots ####

# plot potential refinery locations on US map

states <- readRDS("../clean_binary_data/states.spdf.RDS")
plot 
mw <- raster::aggregate(mw.states)
plot(mw.counties)


tiff(file = "../figures/potential.refs", res = 400, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")
plot(states)
plot(p.refs, pch = 16, col = "springgreen3", cex = .4, add = T)

dev.off()






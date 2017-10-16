
#-----------------------------------------------------------------------------#
# bioshed_ex_plot.R
# Type: R cleaning script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A plotting script to provide an visual example how biosheds were calculated. 
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

require(ggplot2)
require(ggmap)
require(raster)
require(sp)
require(rgeos)
require(spatialEco)
require(geosphere)
require(igraph)
require(shp2graph)
require(rgdal)

###### SET PARAMS ######
crop <- "Corn"
range <- 50
###### LOAD DATA ######

# load bioref locations data
biorefs <- readRDS("../clean_binary_data/biorefs.sptdf.RDS")

# load centroids data for all US counties
cents <- readRDS(paste0("../output/data_products/US.cluster.cents.", 
                        crop, ".RDS"))

# load counties data
counties <- readRDS("../clean_binary_data/counties.spdf.RDS")

# load roads data
roads.data <- readRDS("../clean_binary_data/roads.sldf.RDS")

aea.crs <- CRS("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23.0
               +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 
               +units=m +no_defs")
wgs84.crs <- crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")


# select bioref to examine
for (rid in (1:20)) {
  
  in.range.cids <- readRDS(paste0("../output/data_products/curr_ref_biosheds_", 
                                  crop, "_", range, "mi.RDS"))
  
  in.range.cids  <- in.range.cids[in.range.cids$RID == rid,]
  in.range.cids <- unlist(in.range.cids$CIDS_IN_RANGE)
  
  # set to projected CRS for geoprocessing
  counties <- spTransform(counties, aea.crs)
  biorefs <- spTransform(biorefs, aea.crs)
  cents <- spTransform(cents, aea.crs)
  
  # subset data
  bioref <- biorefs[biorefs$RID == rid,]
  in.range <- cents[cents$cid %in% in.range.cids,]
  
  # set buffer for search area
  buff <- buffer(bioref, width = 80468, quadsegs = 100)
  
  # determine candidate counties 
  cand.cents <- crop(cents, buff)
  
  # set to consistent CRS for plotting
  counties <- spTransform(counties, wgs84.crs)
  bioref <- spTransform(bioref, wgs84.crs)
  cand.cents <- spTransform(cand.cents, wgs84.crs)
  in.range <- spTransform(in.range, wgs84.crs)
  buff <- spTransform(buff, wgs84.crs)
  roads <- crop(roads.data, buff)
  
  # set up plot
  plot(buff, border = 'orange', main = paste0("RID: ", rid))
  plot(roads, add = T, col = "black")
  plot(cand.cents, add = F, pch = 16, col = 'blue')
  plot(in.range, add = T, col = 'green', pch = 16)
  plot(counties, add = T, border = "grey")
  plot(bioref, add = F, pch = 18, col = 'blue', cex = 1.8)

}


tiff(file = "../figures/bioshed.ex.1.tiff", res = 400, width = 8, 
     height = 7,
     units = "in", compression = "lzw")

# set up plot
plot(bioref, add = F, pch = 18, col = 'springgreen3', cex = 2.2)
raster::plot(roads, add = T, col = 'gray30', lwd = 0.7)

dev.off()


# plot 2
tiff(file = "../figures/bioshed.ex.2.tiff", res = 400, width = 8, 
     height = 7,
     units = "in", compression = "lzw")


# set up plot
plot.new()
plot(cand.cents, pch = 16, col = 'darkgoldenrod1')
raster::plot(roads, add = T, col = 'gray30', lwd = 0.7)
plot(bioref, add = T, pch = 18, col = 'springgreen3', cex = 2.2)
plot(buff, add = T, border = 'blue', main = paste0("RID: ", rid))

dev.off()

# plot 3
tiff(file = "../figures/bioshed.ex.3.tiff", res = 400, width = 8, 
     height = 7,
     units = "in", compression = "lzw")


# set up plot
plot.new()
plot(cand.cents, pch = 16, col = 'darkgoldenrod1')
raster::plot(roads, add = T, col = 'gray30', lwd = 0.7)
plot(bioref, add = T, pch = 18, col = 'springgreen3', cex = 2.2)
plot(in.range, add = T, col = 'red', pch = 16)
plot(buff, add = T, border = 'blue', main = paste0("RID: ", rid))


dev.off()








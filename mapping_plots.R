#-----------------------------------------------------------------------------#
# mapping_plots.R

# Type: R plotting script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A script to generate preliminary mapping plots of bioshed data.  

#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

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
require(cluster)
require(fpc)
require(RColorBrewer)
require(Hmisc)


# load required functions
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


# load bioref locations data
biorefs <- readRDS("../clean_binary_data/biorefs.sptdf.RDS")

# load centroids data for all US counties
crop <- "Corn"
cents <- readRDS(paste0("../output/data_products/US.cluster.cents.", 
                        crop, ".RDS"))

# load counties data
counties <- readRDS("../clean_binary_data/counties.spdf.RDS")
states <- readRDS("../clean_binary_data/states.spdf.RDS")
# load roads data
roads.data <- readRDS("../clean_binary_data/roads.sldf.RDS")

aea.crs <- CRS("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23.0
               +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 
               +units=m +no_defs")
wgs84.crs <- crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")



# plot US biorefineries
tiff(file = "../figures/us.biorefs.tiff", res = 800, width = 9, height = 5,
     units = "in", compression = "lzw")

plot(states, col = "gray95")
plot(biorefs, col = 'seagreen3', pch = 16, add = T, cex = 0.8)

dev.off()

# plot US CDL layer
tiff(file = "../figures/cdl.tiff", res = 800, width = 9, height = 5,
     units = "in", compression = "lzw")
ras <- raster("../raw_data_files/cdl/cdl_2016_30m.img")
plot(ras)

dev.off()


# plot US NLCD layer
tiff(file = "../figures/nlcd.tiff", res = 800, width = 9, height = 5,
     units = "in", compression = "lzw")

ras <- raster("../raw_data_files/nlcd/nlcd_2011_30m.img")
plot(ras)

dev.off()



# plot hist of US biorefs capacity
caps <- as.numeric(biorefs$CAPACITY_MGY)
med <- median(caps)


tiff(file = "../figures/biorefs.caps.hist.tiff", res = 800, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")

biorefs.hist <- hist(caps, 
                     main = NULL,
                     xlab = "Capacity (MG/Year)",
                     ylab = "Frequency",
                     border = "gray",
                     col = "springgreen3",
                     ylim = c(0,50),
                     breaks = 30) 


abline(v = med, col = "red", lwd = 2)
minor.tick(nx=10, ny=5, tick.ratio=0.3)


dev.off()

hist(as.numeric(cap))

# pie chart of bioref types
types <- table(biorefs$TYPE)



tiff(file = "../figures/bioref.types.pie.tiff", res = 800, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")

cols <- c("#238B45", "#74C476", "#BAE4B3", "#EDF8E9")

slices <- c(190, 11, 6, 6)
lbls <- c("Corn", "Corn + Other Starches", "Cellulosic Biomass", "Waste")
lbls <- paste(lbls, slices, sep = " = ") # add percents to labels 
pie(slices, labels = lbls, col=cols,
    main="Feedstock Type")

dev.off()

roads <- readRDS("../clean_binary_data/roads.sldf.RDS")
us <- aggregate(states)

# plot US primary and secondary roads

tiff(file = "../figures/us.roads.tiff", res = 500, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")

raster::plot(us)
raster::plot(roads, add = T, col = 'red')


dev.off()

roads <- 

us <- SpatialPolygonsDataFrame(us, data = NULL)
  

writeOGR(us, dsn = "us.shp", layer = "us", driver = "ESRI Shapefile")


palette(c(brewer.pal(12, "Set3")))


corn.cents <- readRDS("../output/data_products/US.cluster.cents.Corn.RDS")
corn.cents <- corn.cents[us,]

tiff(file = "../figures/us.roads.tiff", res = 500, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")

plot(us)
plot(corn.cents, add = T, pch = 16, col = "darkgoldenrod1", cex = 0.2)

dev.off()



corn.cents <- readRDS("../output/data_products/US.cluster.cents.Corn.RDS")
corn.cents <- corn.cents[us,]

tiff(file = "../figures/corn.cents.tiff", res = 300, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")

plot(us)
plot(corn.cents, add = T, pch = 16, col = "darkgoldenrod1", cex = 0.15)

dev.off()

ec.cents <- readRDS("../output/data_products/US.cluster.cents.EnergyCrops.RDS")
ec.cents <- ec.cents[us,]

tiff(file = "../figures/EnergyCrop.cents.tiff", res = 300, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")

plot(us)
plot(ec.cents, add = T, pch = 16, col = "springgreen3", cex = 0.15)

dev.off()


wheat.cents <- readRDS("../output/data_products/US.cluster.cents.Wheat.RDS")
wheat.cents <- wheat.cents[us,]

tiff(file = "../figures/wheat.cents.tiff", res = 300, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")

plot(us)
plot(wheat.cents, add = T, pch = 16, col = "salmon3", cex = 0.15)

dev.off()


oats.cents <- readRDS("../output/data_products/US.cluster.cents.Oats.RDS")
oats.cents <- oats.cents[us,]

tiff(file = "../figures/oats.cents.tiff", res = 300, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")

plot(us)
plot(oats.cents, add = T, pch = 16, col = "skyblue3", cex = 0.15)

dev.off()



sorg.cents <- readRDS("../output/data_products/US.cluster.cents.Sorghum.RDS")
sorg.cents <- sorg.cents[us,]

tiff(file = "../figures/sorghum.cents.tiff", res = 300, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")

  plot(us)
  plot(sorg.cents, add = T, pch = 16, col = "firebrick2", cex = 0.15)

dev.off()












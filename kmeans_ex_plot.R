#-----------------------------------------------------------------------------#
# kmeans_ex_plot.R
# Type: R plotting script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A plotting script to provide an visual example how kmeans clusters were
# calculated. 
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

# load roads data
roads.data <- readRDS("../clean_binary_data/roads.sldf.RDS")

aea.crs <- CRS("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23.0
               +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 
               +units=m +no_defs")
wgs84.crs <- crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")





feedstocks <- c("Corn stover")
crops.to.do <- GetCropList(feedstocks)
cdl.raster.path <- ("../raw_data_files/cdl/cdl_2016_30m.img")
fips.to.do <- 29197
cents <- readRDS(paste0("../output/bin/FIPS_", fips.to.do,
                        "_", crop, "_cluster.cents.RDS"))
cents <- SpatialPoints(as.matrix(cents[,1:2]), proj4string = aea.crs)

# vectorize county level rasters for select crops from CDL layer
ClipVectorizeCDL(counties, raster.path = cdl.raster.path, fips = fips.to.do)

CalcClusterCentsCDL(counties, cdl.raster.path, crop = crop, fips.to.do)

county <- counties[counties$FIPS == fips.to.do,]
ras.pts <- readRDS(paste0("../output/bin/FIPS_", fips.to.do,
                          "_", crop, "_ras_pts_clustered.RDS"))

ras.pts.sp <- SpatialPoints(as.matrix(ras.pts[,1:2]))
ras.pts.data <- ras.pts[3]
ras.pts.data$.cluster <- as.numeric(ras.pts.data$.cluster)
ras.pts <- SpatialPointsDataFrame(ras.pts.sp@coords, ras.pts.data, 
                                  proj4string = aea.crs)
ras.pts <- ras.pts[county,]



# set plotting params
border.col <- "grey"
pt.size <- 0.2
cent.size <- 2.5
palette(c(brewer.pal(12, "Paired"), brewer.pal(8, "Dark2")))

ras <- raster("../output/bin/cropped_29197_cdl_raster.gri")


# plot raster with county boundary
tiff(file = "../figures/kmeans.ex.1.tiff", res = 800, width = 9, height = 5,
     units = "in", compression = "lzw")
plot.new()
plot(ras)
raster::plot(county, add = T, border = 'black', lwd = 2)

dev.off()

# plot corn points within county boundary
tiff(file = "../figures/kmeans.ex.2.tiff", res = 1000, width = 9, height = 5,
     units = "in", compression = "lzw")
plot.new()
raster::plot(county, col = "gray96")
raster::plot(ras.pts, add = T, col = "gray20", pch = 16, cex = 0.2)

dev.off()

# plot corn points within county boundary
tiff(file = "../figures/kmeans.ex.3.tiff", res = 1000, width = 9, height = 5,
     units = "in", compression = "lzw")
plot.new()
raster::plot(county, col = "gray96")
raster::plot(ras.pts, add = T, col = ras.pts$.cluster, pch = 16, cex = 0.2)
raster::plot(county, add = T)

dev.off()

# plot with cluster centroid
tiff(file = "../figures/kmeans.ex.4.tiff", res = 1000, width = 9, height = 5,
     units = "in", compression = "lzw")
plot.new()
raster::plot(county, col = "gray96")
raster::plot(ras.pts, col = ras.pts$.cluster, pch = 16, cex = 0.4, add = T)
raster::plot(cents, add = T, col = "black", pch = 10, cex = 1.6)
raster::plot(county, add = T)
dev.off()



# first plot raster points only
p1 <- ggplot() + 
  theme_bw() + 
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(), 
          axis.line = element_blank(),
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          legend.position="none") +
          # panel.border = element_rect(colour = border.col, fill=NA, size=0.8)) +
  
  geom_point(data = ras.pts, aes(x = X1, y = X2), 
             color = "gray20", size = pt.size, shape = 15) +
  geom_polygon(data = poly.coords, aes(x = x, y = y, 
                                       fill = NULL, color = "gray20"))




# plot raster point with colors indicating clusters and centroids

p2 <- ggplot() + 
  theme_bw() + 
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line = element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        legend.position="none",
        panel.border = element_rect(colour = border.col, fill=NA, size=0.8)) +
  
  geom_point(data = ras.pts, aes(x = X1, y = X2, color = .cluster), 
             size = pt.size, shape = 15)

p2

# plot raster point with colors indicating clusters
p3 <- ggplot() + 
  theme_bw() + 
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line = element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        legend.position="none",
        panel.border = element_rect(colour = border.col, fill=NA, size=0.8)) +
  
  geom_point(data = ras.pts, aes(x = X1, y = X2, color = .cluster),
             size = pt.size, shape = 15) +
  geom_point(data = cents, aes(x = x1, y = x2), color = "black", 
             size = cent.size)
p3













        







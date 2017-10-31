#------------------------------------------------------------------------------#
# CalcClusterCentsNLCD_fun.R

# AUTHOR:
# Tyler Huntington, 2017

# JBEI Sustainability Team
# Feedstock Agnostic Study
# PI: Corinne Scown PhD

# PURPOSE:
# An analysis script to find the centroids of k-means clusters of crop/pasture
# points extracted from the NLCD raster layer

# PARAMS:
# counties.data - US county boundaries as an object of class 
  # SpatialPolygonsDataFrame
# fips.codes - a list of FIPs codes specifying the counties for whcih to calc
  # kmeans cluster centroids.

# OUTPUTS:
# For each county specified in the fips.codes argument, a binary data (.RDS)
# file containing a dataframe with county-level cluster centroids data.

#------------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

CalcClusterCentsNLCD <- function (counties.data, fips.codes) {

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
    require(doParallel)
    require(snow)
    require(doSNOW)
    require(rgeos)
    
    aea.crs <- CRS("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23.0 
                 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 
                 +units=m +no_defs")
    
    crop <- "EnergyCrops"
    
    
    # non-parallel iteration
    # for (fips in fips.codes) {  
    no.cores <- detectCores() - 1
    no.cores = 30
    cl <- makeCluster(no.cores, type = "SOCK", outfile = "log.nlcd.txt")
    registerDoSNOW(cl)
    
    US.cluster.cents <-
    foreach(fips = fips.codes,
            .combine = "rbind",
            .packages = c("broom", "dplyr", "sp",
                          "raster", "maptools", 
                          "rgeos")) %dopar% {
    
    
    
      cat(sprintf("Working on FIPS: %s", fips))       
      
      # load point representation of ag raster for county
      county.pts <- readRDS(paste0("../output/bin/FIPS_", 
                                   fips, "_EnergyCrops_ras_pts.RDS"))
      
      if (nrow(county.pts) < 20) {
        if (nrow(county.pts) == 0) {
          county.poly <- counties.data[counties.data$FIPS == fips, ]
          cent <- gCentroid(county.poly)
          x1 <- cent@coords[1]
          x2 <- cent@coords[2]
        } else {
          x1 <- mean(county.pts[1])
          x2 <- mean(county.pts[2])
        }
        
        size <- nrow(county.pts)
        withinss <- 0
        cluster <- 1
        cid <- paste0(fips, ".1")
        
        clusters <- data.frame(x1, x2, size, withinss, cluster, fips, cid)
        
        
        # export county cluster centroids
        crop <- gsub(" ", "_", crop)
        saveRDS(clusters, 
                paste0("../output/bin/FIPS_",
                       fips, "_EnergyCrops_cluster.cents.RDS"))
        
        clusters
        
      } else {
        
        # elim layer val column from points matrix
        county.pts <- county.pts[,1:2]
        
        cat("\n Performing k-means cluster analysis...") 
        # perform K-Means cluster analysis
        cluster.info <- kmeans(county.pts, 20)
        #if (cluster.info$ifault==4)
        #{print('change to another algorithm for kmean')
        #gc()
        #cluster.info=kmeans(county.pts, 20, iter.max = 100, algorithm="MacQueen")}
        
        cat("\n cbinding cluster groups to points data")
        # cbind cluster groups to points data
        county.pts <- broom::augment(cluster.info, county.pts)
        
        cat("\n getting cluster summary stats")
        # get cluster summary stats
        clusters <- tidy(cluster.info)
        
        cat("\n cbinding fips and cid columns")
        # cbind fips and cid (unqique cluster id) columns
        clusters$fips <- fips
        clusters$cid <- lapply(clusters$cluster, 
                               function(x) paste0(fips, ".", x))
        
        
        # export county cluster centroids
        crop <- gsub(" ", "_", crop)
        saveRDS(clusters, 
                paste0("../output/bin/FIPS_",
                       fips, "_EnergyCrops_cluster.cents.RDS"))
        
        clusters
        
      }
  }
  # cancel parallel backend
  stopCluster(cl)
}












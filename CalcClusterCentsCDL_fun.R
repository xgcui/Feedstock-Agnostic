#------------------------------------------------------------------------------#
# CalcClusterCentsCDL_fun.R

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
# raster.path - filepath of the the CDL raster layer
# crop - name of the primary crop in the CDL layer for which to calculate
  # cluster centroids.
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


CalcClusterCentsCDL <- function(counties.data, raster.path, crop, fips.codes) {
  
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
  
  # load raster data
  raster.data <- raster(raster.path)
  
  ###### ORG DATA ######
  
  # get df of cell value codes
  ras.vals.df <- raster.data@data@attributes[[1]]
  
  
  # find raster vals for cells with dual production of target crop + other
  all.names <- grep(crop, ras.vals.df$Class_Names, value = T)
  
  # include abbreviations for wheat
  if (crop == "Wheat") {
    all.names <- c(all.names, grep("Wht", ras.vals.df$Class_Names, value = T))
  }
  dbl.names <- grep("Dbl", all.names, value = T)
  dbl.vals <- ras.vals.df[ras.vals.df$Class_Names %in% dbl.names, "ID"]
  
  # determine raster vals corresponding to land dedicated to selected crop 
  ded.names <- all.names[!(all.names %in% dbl.names)]
  ded.vals <- ras.vals.df[ras.vals.df$Class_Names %in% ded.names, "ID"]
  
  
  # non-parallel iteration
  # for (fips in fips.codes[1:length(fips.codes)]) {  
  
  # parallel comp
  # init cluster
  no.cores <- detectCores()
  cl <- makeCluster(no.cores, type = "SOCK", outfile="log.txt")
  registerDoSNOW(cl)
  
  US.cluster.cents <-
    foreach(fips = fips.codes,
            .combine = "rbind",
            .packages = c("broom", "dplyr", "sp",
                          "raster", "maptools", 
                          "rgeos")) %do% {
                            
    cat(sprintf("Working on FIPS: %s", fips))       
    
    # load point representation of ag raster for county
    county.pts <- readRDS(paste0("../output/bin/FIPS_", 
                                 fips, "_ras_pts.RDS"))
    
    
    ## TODO make this a function
    # a function to update raster vals of cdl points layer
    RecodeVals <- function(val, ded.vals, dbl.vals) {
      
      if (val %in% ded.vals) {
        return(2)
      } else if (val %in% dbl.vals) {
        return(1)
      } else {
        return(0)
      }
    }
    
    RecodeVals <- Vectorize(RecodeVals, vectorize.args = c("val"))
    county.pts[,3] <- RecodeVals(county.pts[,3], ded.vals, dbl.vals)
    
    # drop points with val of zero
    county.pts <- county.pts[which(county.pts[,3]!=0),]
    county.pts <- matrix(county.pts, ncol = 3)
    
    # account for weights by duplicating dedicated crop production points
    DuplicateDedPoints <- function(county.pts) {
      ded.rows <- county.pts[which(county.pts[,3] == 2),]
      county.pts <- rbind(county.pts, ded.rows)
      return(county.pts)
    }
    county.pts <- DuplicateDedPoints(county.pts)
    saveRDS(county.pts, paste0("../output/bin/FIPS_", fips,"_", crop, 
                               "_ras_pts.RDS"))
    
    if (nrow(unique(county.pts)) <= 20) {
      if (nrow(county.pts) == 0) {
        county.poly <- counties[counties$FIPS == fips, ]
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
      
    } else {
      
      # elim layer val column from points matrix
      county.pts <- county.pts[,1:2]
      
      cat("\n Performing k-means cluster analysis...") 
      # perform K-Means cluster analysis
      cluster.info <- kmeans(county.pts, 20)
      
      cat("\n cbinding cluster groups to points data")
      # cbind cluster groups to points data
      county.pts <- broom::augment(cluster.info, county.pts)
      
      # export county raster points with cluster assignments
      crop <- gsub(" ", "_", crop)
      saveRDS(county.pts, 
              paste0("../output/bin/FIPS_",
                     fips, "_", crop, "_ras_pts_clustered.RDS"))
      
      cat("\n getting cluster summary stats")
      # get cluster summary stats
      clusters <- tidy(cluster.info)
      
      cat("\n cbinding fips and cid columns")
      # cbind fips and cid (unqique cluster id) columns
      clusters$fips <- fips
      clusters$cluster <- as.character(clusters$cluster)
      clusters$cid <- lapply(clusters$cluster, 
                             function(x) {paste0(fips, ".", x)})
      
    }
    
    # export county cluster centroids
    crop <- gsub(" ", "_", crop)
    saveRDS(clusters, 
            paste0("../output/bin/FIPS_",
                   fips, "_", crop, "_cluster.cents.RDS"))
    
    print(paste0("Exported RDS data file for FIPS: ", fips))
    
    # return cluster df
    clusters
  }
  
  
  # # convert cluster centers in spatial points
  # US.cluster.cents.coords <- US.cluster.cents[ ,1:2]
  # US.cluster.cents.sp <- SpatialPoints(US.cluster.cents.coords, 
  #                                      proj4string = aea.crs)
  # cluster.data <- US.cluster.cents[ ,3:(ncol(US.cluster.cents))]
  # US.cluster.cents.sp <- sp::SpatialPointsDataFrame(US.cluster.cents.sp,  
  #                                                   cluster.data,
  #                                                   proj4string = aea.crs)
  # 
  # # export all US cluster cents in binary data file
  # crop <- gsub(" ", "_", crop)
  # saveRDS(US.cluster.cents.sp, 
  #         paste0("../output/US", crop, 
  #                "cluster.cents.sp.RDS"))
  
  
  # stop parallel cluster
  stopCluster(cl) 
}











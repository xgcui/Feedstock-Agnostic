#-----------------------------------------------------------------------------#
# BtDataSelect_fun.R
# Type: R function

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# calculate total available biomass within defined buffer radius of biorefinery

# PARAMATERS:

# data - dataframe of billion ton study data

# year - an int (2018, 2030 or 2040) specifying the BT scenario year to use

# scenario - a char indicating the billion ton model scenario to use
# choices:
# "Basecase, all energy crops"            
# "Basecase, single energy crops"         
# "Baseline"                             
# "2% yield inc."                         
# "3% yield inc."                         
# "4% yield inc."                         
# "High housing, high energy demands"     
# "High housing, low energy demands"      
# "High housing, medium energy demands"   
# "Medium housing, high energy demands"   
# "Medium housing, low energy demands"    
# "Medium housing, medium energy demands"
# "Wastes and other residues"

# feedstocks - a char or vector of chars indicating feedstocks to include
# may be any combination of "herb", "woody", and "residues"
# or individually specified feedstocks from this list:
# "Barley straw" 
# "Biomass sorghum"
# "CD waste"
# "Citrus residues" 
# "Corn stover"
# "Cotton gin trash" 
# "Cotton residue" 
# "Energy cane" 
# "Eucalyptus"
# "Food waste"
# "Hardwood, lowland, residue"
# "Hardwood, upland, residue"
# "Miscanthus"
# "Mixedwood, residue"
# "Mixedwood, tree"
# "MSW wood"
# "Noncitrus residues"
# "Oats straw"
# "Other forest residue"
# "Other forest thinnings"
# "Poplar"
# "Pine"
# "Primary mill residue"
# "Rice hulls"
# "Rice straw"
# "Secondary mill residue"
# "Softwood, natural, residue"
# "Softwood, planted, residue"
# "Sorghum stubble"
# "Sugarcane bagasse"
# "Sugarcane trash" 
# "Switchgrass"
# "Wheat straw"
# "Willow"
# "Yard trimmings"

# price - an int specifying the price per dry ton of biomass (in US $) to model
# choices:
# 30   
# 40   
# 50   
# 60   
# 70   
# 80   
# 90
# 100

# RETURNS:
# a subsetted version of the input dataframe as specified by other parameter
# values in the function call. 

#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

BtDataSelect <-
  
  function(biomass.data, year, scenario, feedstocks, price) {
    
    ###### LOAD LIBRARIES ######

    require(ggplot2)
    require(ggmap)
    require(raster)
    require(sp)
    require(rgeos)
    require(kimisc)
    require(knitr)
    require(R.utils)
    require(spatial)
    require(GISTools)
    require(gdata)
    require(rgdal)
    require(rgeos)
    require(maptools)
    require(plyr)
    require(dplyr)
    require(raster)

    # define standardized CRS for spatial data
    aea.crs <- CRS("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23.0 
                   +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 
                   +units=m +no_defs")
    
    ###### DEFINE PARAMS OF BT DATA TO ANALYZE ###### 
    # define year of analysis
    year_choice <- as.character(year)
    
    # subset for chosen year
    biomass.data <- subset(biomass.data,
                         (paste(biomass.data$Year) == year_choice))
    
    # define scenario
    scenario_choice <- as.character(scenario)
    
    # subset for chosen scenario
    biomass.data <- subset(biomass.data,
                         (paste(biomass.data$Scenario) == scenario_choice))
    
    # define price point (units: US dollars per dry ton) 
    price_choice <- as.character(price)
    
    # subset for price point
    biomass.data <- subset(biomass.data,
                         (paste(biomass.data$Biomass.Price) == price_choice))
    
    ### Define biomass feedstocks of interest
    
    # group major categories of biomass
    herb <- c("Switchgrass", "Miscanthus", "Energy cane", "Biomass sorghum")
    
    woody <- c("Willow", "Eucalyptus", "Poplar", "Pine")
    
    residues <- c("Wheat straw", "Oat straw", "Corn stover", 
                  "Barley straw", "Sorghum stubble")
    
    # init feed_choices var
    feed_choices <- NULL
    
    # constuct feed_choices string based on feedstocks arg in function call
    if ("herb" %in% feedstocks){
      feed_choices <- herb
    }
    
    if ("woody" %in% feedstocks){
      feed_choices <- c(feed_choices, woody)
    }
    
    if ("residues" %in% feedstocks){
      feed_choices <- c(feed_choices, residues)
    }
    
    if (!("residues" %in% feedstocks) & !("woody" %in% feedstocks) & 
        !("residues" %in% feedstocks)) {
      feed_choices <- feedstocks
    }
    
    
    # make sure there are no duplicates in feed_choices vector
    feed_choices <- unique(feed_choices)
    
    biomass.data <- subset(biomass.data,
                         (paste(biomass.data$Feedstock) %in% feed_choices))
    
    saveRDS(biomass.data, "../output/bt_select_sample.RDS")
    
    return(biomass.data)
  }




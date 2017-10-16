#-----------------------------------------------------------------------------#
# load_cleaned_binary.R
# Type: R loading script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A script to load all the clean binary data for the Feedstock 
# Agnostic analysis.


# SIDE-EFFECTS: loads clean datasets into global environment

#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

# Load libraries
require(raster)


# load current US biorefinery profiles (Source: Renewable Fuels Association)
biorefs <- readRDS("../clean_binary_data/biorefs.sptdf.RDS")

# load US county boundary shapefile (Source: US Census TIGER/Line)
counties <- readRDS("../clean_binary_data/counties.spdf.RDS")

# load US state boundary shapefile (Source: US Census TIGER/Line)
states <- readRDS("../clean_binary_data/states.spdf.RDS")

# load US national road network (primary and secondary) shapefile (Source: USDT)
roads <- readRDS( "../clean_binary_data/roads.sldf.RDS")

# load billion ton study biomass data for all crops for 2018, 2030, and 2040
biomass.data <- readRDS("../clean_binary_data/bt_biomass_18_30_40.df.RDS")




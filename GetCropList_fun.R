
#-----------------------------------------------------------------------------#
# GetCropList_fun.R
# Type: R function script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# PROJECT: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A function to get the primary crops that produce specified residue 
# feedstocks

# PARAMS:
# feedstocks - a list of residue feedstocks for which to get the primary crops
# that produce them as a coproduct. 

# RETURNS:
# list of primary crops that produce the feedstock residues 
# passed by the caller. 

# SIDE-EFFECTS:
# None

#-----------------------------------------------------------------------------#


GetCropList <- function(feedstocks) {
  
   crops <- c(NULL)
   
   ec1 <- "Biomass sorghum" %in% feedstocks
   ec2 <- "Switchgrass" %in% feedstocks
   ec3 <- "Biomass sorghum" %in% feedstocks
   
   if (ec1 | ec2 | ec3) {
     crops <- c("EnergyCrops")
   }
   
   if ("Corn stover" %in% feedstocks) {
     crops <- c(crops, "Corn")
   }
   
   if ("Wheat straw" %in% feedstocks) {
     crops <- c(crops, "Wheat")
   }
   
   if ("Sorghum stubble" %in% feedstocks) {
     crops <- c(crops, "Sorghum")
   }
   
   if ("Oats straw" %in% feedstocks) {
     crops <- c(crops, "Oats")
   }
   
   return(crops)
}

   
   
     
     
   
   
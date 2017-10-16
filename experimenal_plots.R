#-----------------------------------------------------------------------------#
# experimental_plots.R

# Type: R plotting script

# AUTHOR:
# Tyler Huntington, 2017
# JBEI Sustainability Research Group
# Project: Feedstock Agnostic Biorefinery Study

# PURPOSE:
# A script to generate exploratory plots.  

#-----------------------------------------------------------------------------#

###### OPTIONAL: CONFIGURE WORKSPACE ######

# # set working directory to this script's location
# source("GetScriptDir_fun.R")
# this.dir <- dirname(GetScriptDir())
# setwd(this.dir)

# # clear workspace
# rm(list=ls())

#-----------------------------------------------------------------------------#

# plot US primary and secondary roads on US map
roads <- readRDS("../clean_binary_data/roads.sldf.RDS")

states <- readRDS("../clean_binary_data/states.spdf.RDS")
us <- aggregate(states)

roads <- spTransform(roads, aea.crs)
roads <- roads[us,]

tiff(file = "../figures/us.roads.tiff", res = 500, width = 8, 
     height = 5.75,
     units = "in", compression = "lzw")
raster::plot(us)
raster::plot(roads, add = T, col = 'darkred', lwd = 0.7)

dev.off()




###### HISTOGRAMS OF BIOSHED DISTRIBUTIONS ######
SelData <- function(b.data, year, scenario, price, range, feed, trim) {
  
  library(plyr)
  library(shiny)
  library(sp)
  library(raster)
  

  
  query <- b.data$Year == year & 
    b.data$Scenario == scenario & 
    b.data$Price == price & 
    b.data$Drive.range == range & 
    b.data$Feedstock == feed
  
  sel.data <- subset(b.data, query)
  
  if (trim) {
    qs <- quantile(na.omit(sel.data$Dt.biomass))
    qs <- unname(qs)
    q1 <- qs[2]
    q3 <- qs[4]
    
    iqr <- IQR(na.omit(sel.data$Dt.biomass))
    
    lower <- q1 - 1.5*iqr 
    upper <- q3 + 1.5*iqr
    
    mid <- which((sel.data$Dt.biomass >= lower) & 
                   (sel.data$Dt.biomass <= upper))
    
    sel.data <- sel.data[mid,]
  }
  
  return(sel.data)
  
}




ranges <- c(40, 50, 60)
year <- c(2030)
scenario <- "Basecase, all energy crops"
price <- 50
feed <- "Corn_stover"
trim <- T



tiff(file = "../figures/bioshed.Corn.2030.hist.tiff", res = 500, width = 5,
     height = 8,
     units = "in", compression = "lzw")
par(mfrow=c(3,1))

for (range in ranges) {
  sel.data <- SelData(b.data, year, scenario, price, range, feed, trim)


  x <- na.omit(sel.data[, "Dt.biomass"]/1000)
  bins <- 25
  bins <- seq(min(na.omit(x)), max(na.omit(x)), length.out = bins + 1)
  
  # draw the histogram with the specified number of bins
  hist(x, breaks = bins, col = 'darkgoldenrod1', border = 'gray95',
       xlab = NULL,
       ylab = "Frequency",
       xlim = c(0, 5000),
       main = NULL)
}

dev.off()




# summary stats of results

ranges <- c(40, 50, 60)
year <- c(2020)
scenario <- "Basecase, all energy crops"
price <- 50
feed <- "Corn_stover"
trim <- T





###### FEEDSTOCK BLEND ANALYSIS PLOTS ###### 


# set feedstocks to include in blend analysis
#feeds <- c("residues", "herb", "woody") 

feeds <- c("Corn stover", "Wheat straw"
           
           #feeds <- all.feeds
           
           
           # init year
           y <- 2040
           
           # init scenarios
           s <- "Basecase, all energy crops"
           
           
           # init price per dry ton
           price_per_dt <- 80
           
           # collect datasets for running model
           datasets <- list(biomass.df, counties.spdf, biorefs.sptdf)
           
           # calc biosheds
           result <- 
             BasicBiomassCatchmentCalc(data = datasets,
                                       year = y, 
                                       scenario = s, 
                                       feedstocks = feeds,
                                       price = price_per_dt,
                                       radius = 60)
           
           
           # try for year 2018
           
           # define residue categories
           herb <- c("Switchgrass", "Miscanthus", "Energy cane", 
                     "Biomass sorghum")
           
           woody <- c("Willow", "Eucalyptus", "Poplar", "Pine")
           
           residues <- c("Wheat straw", "Oat straw", "Corn stover", 
                         "Barley straw", "Sorghum stubble")
           
           wastes <- c("MSW wood", "Yard trimmings")
           
           
           # create vector of all possible feeds
           #sel.feeds.v <- c(herb, woody, residues)
           
           sel.feeds.v <- feeds
           
           
           
           # replace spaces with underscores
           sel.feeds.v <- gsub(" ", "_", sel.feeds.v)
           
           
           # create blank df to store co-occurence data
           fco.mx <- matrix(0, nrow= length(sel.feeds.v), ncol = length(sel.feeds.v))
           colnames(fco.mx) <- sel.feeds.v
           rownames(fco.mx) <- sel.feeds.v
           
           
           # iterate over refineries
           for (RID in seq_along(result$RID)){
             par.ref <- result[RID,]
             
             # iterate over rows
             for (rowfeed in sel.feeds.v){
               
               for (colfeed in sel.feeds.v){
                 
                 if (par.ref@data[1, colfeed] > 0 & par.ref@data[1, rowfeed] > 0){
                   fco.mx[rowfeed,colfeed] <- fco.mx[rowfeed, colfeed] + 1
                 }
               }
             }
           }
           
           # elim rows of fco.mx with all zeros
           droprows <- c()
           for (rowname in rownames(fco.mx)){
             if (all(fco.mx[rowname,] == 0)) {
               droprows <- c(droprows, rowname)
               print (rowname)
               
             }
           }
           
           
           # subset out zero vector rows
           fco.mx <- fco.mx[!(rownames(fco.mx) %in% droprows),]
           
           
           # elim rows of fco.mx with all zeros
           dropcols <- c()
           for (colname in colnames(fco.mx)){
             if (all(fco.mx[,colname] == 0)) {
               dropcols <- c(dropcols, colname)
               print (colname)
               
             }
           }
           
           # subset out zero vector cols
           fco.mx <- fco.mx[,!(colnames(fco.mx) %in% dropcols)]
           
           # normalize co-occurence vals based on total number of refineries
           fco.mx <- fco.mx/nrow(biorefs.sptdf@data)
           
           
           cormat <- fco.mx
           
           
           ###### PLOT ######
           # adapted from: http://www.sthda.com/
           #english/wiki/
           #ggplot2-quick-correlation-matrix-heatmap-r-software-and-data-visualization
           
           library(reshape2)
           # round vals 
           cormat <- round(cormat, 3)
           
           # replace underscores with spaces 
           rownames(cormat) <- gsub("_", " ", rownames(cormat))
           colnames(cormat) <- gsub("_", " ", colnames(cormat))
           
           
           melted_cormat <- melt(cormat)
           head(melted_cormat)
           melted_cormat$value <- round(melted_cormat$value, 3)
           
           library(ggplot2)
           ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill=value)) + 
             geom_tile()
           
           # Get lower triangle of the correlation matrix
           get_lower_tri<-function(cormat){
             cormat[upper.tri(cormat)] <- NA
             return(cormat)
           }
           # Get upper triangle of the correlation matrix
           get_upper_tri <- function(cormat){
             cormat[lower.tri(cormat)]<- NA
             return(cormat)
           }
           
           upper_tri <- get_upper_tri(cormat)
           lower_tri <-get_lower_tri(cormat)
           
           # Melt the correlation matrix
           library(reshape2)
           melted_cormat <- melt(upper_tri, na.rm = TRUE)
           
           # Heatmap
           library(ggplot2)
           ggplot(data = melted_cormat, aes(Var2, Var1, fill = value))+
             geom_tile(color = "white")+
             scale_fill_gradient2(low = "white", high = "red", mid = "orange", 
                                  midpoint = 0.3, limit = c(0,1), space = "Lab", 
                                  name="Co-Occurrence\nIndex") +
             theme_minimal()+ 
             theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                              size = 12, hjust = 1))+
             coord_fixed()
           
           
           # re - order
           reorder_cormat <- function(cormat){
             # Use correlation between variables as distance
             dd <- as.dist((1-cormat)/2)
             hc <- hclust(dd)
             cormat <-cormat[hc$order, hc$order]
           }
           
           # Reorder the correlation matrix
           cormat <- reorder_cormat(cormat)
           upper_tri <- get_upper_tri(cormat)
           # Melt the correlation matrix
           melted_cormat <- melt(upper_tri, na.rm = TRUE)
           # Create a ggheatmap
           ggheatmap <- ggplot(melted_cormat, aes(Var2, Var1, fill = value))+
             geom_tile(color = "white")+
             scale_fill_gradient2(low = "white", high = "red", mid = "orange", 
                                  midpoint = 0.3, limit = c(0,1), space = "Lab", 
                                  name="Supply\nIndex\n") +
             theme_minimal()+ # minimal theme
             theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                              size = 14, hjust = 1))+
             theme(axis.text.y = element_text(angle = 0, vjust = 1, 
                                              size = 14, hjust = 1))+
             coord_fixed()
           
           
           # Print the heatmap
           print(ggheatmap)
           
           ggheatmap + 
             geom_text(aes(Var2, Var1, label = value), color = "black", size = 2.5) +
             theme(
               axis.title.x = element_blank(),
               axis.title.y = element_blank(),
               panel.grid.major = element_blank(),
               panel.border = element_blank(),
               panel.background = element_blank(),
               axis.ticks = element_blank(),
               legend.position="left") +
             scale_y_discrete(position = "right") +
             guides(fill = guide_colorbar(barwidth = 0.9, barheight = 8,
                                          title.position = "top", title.hjust = 0.5))
           
           
           
           
           
           


# A spatially-explicit framework for assessing U.S. biomass resources
___
#### Principal Investigator: Corinne D. Scown, PhD
#### Joint BioEnergy Institute Sustainability Research Group

<br> 

### Overview
This analysis aims to assess the feasibility of a hypothetical "feedstock agnostic" lignocellulosic biorefinery in the US. Such a biorefinery would be capable of accepting different types of lignocellulosic biomass, thus enabling it to operate at high capacity throughout the year.

<br> 

### Key Questions

* What is the current and future landscape of lignocellulosic biomass availability in the US?

* If existing biorefineries were retrofitted to accept cellulosic feedstocks, how much biomass would feasibly be available to them?

* Given the geographic distributions of biomass availability, what are the most probable feedstock blends in different regions of the US?

* How can we assess current and future biomass resources at high spatial resolution?


<br>

### Methods

<br> 

#### K-means Cluster Analysis of Biomass Production
 
A central goal of our study was to incorporate transportation logistics into spatially-explicit modeling framework for assessing current and future biomass resources across the US.  While the Billion-ton report offers a comprehensive foundation for this type of analysis, one of key limitations of their data is that biomass production and yield values are provided at the county-level. Thus, in order to estimate the spatial distributions biomass productivity at finer spatial scale we integrated data from the Billion-ton report with land-use raster data at the 30x30m.  We utilized both the USDA’s Crop Data Layer (CDL), and the National Land Cover Database (NLCD) provided by the Multi-Resolution Land Characteristics Consortium to identify lands where production of different feedstocks would occur.
 
For coproduct-based feedstocks, such as corn stover and wheat straw, we used the CDL raster data layer, which classifies agricultural lands at the  crop-level, to estimate geographic distributions of feedstock production. Raster cells whose values corresponded to the primary commodity crop (i.e. corn) were clustered using Hartigan and Wong’s (1979)
k-means algorithm, allowing up to 20 clusters to be generated per county. Cluster centroids were then calculated to serve as representative locales of production for a given feedstock within a particular county. These centroids are hereafter referred to as Feedstock Supply Points (FSPs). The total county-level yield of that feedstock based on Billion-ton data was allocated to FSPs, weighted by the proportion of all original production cells in the county constituted a particular cluster. For instance, an FSP representing a cluster 50 production cells would be considered responsible for twice as much production as an FSP calculated from a 25 cell cluster.   
 
 
A similar workflow was implemented to identify potential FSPs of dedicated energy crop production; however, the NCLD raster layer, instead of the CDL layer, was used in the initial steps for determining the land stock from which to calculate k-means clusters. Since the NLCD layer includes classifications for pasture-land and cropland, we treated these cells as candidate sites of energy crop production. This assumption was based on the data reported in Table 4.3 of the Billion-ton report which indicates that the POLYSYS model allocates energy crop production to pasture and cropland in relatively equal proportion over the future years projected by the model.  After masking the NLCD raster layer for only crop and pasture cells, the same k-means clustering approach as described above was used to estimate FSPs and calculate their fractional contribution to total feedstock yields for each county.
 
 
<br> 
 
#### Calculating Biosheds
 
For the purposes of this analysis, we use the term “bioshed” to refer to the available biomass resources within a defined catchment area of a particular location. Our study demonstrates the application of this concept to estimating the projected availability of lignocellulosic feedstocks to existing US bio refineries. While most of these refineries are not currently equipped to accept lignocellulosic biomass, the central premise of our study is to consider the feasibility of a hypothetical “feedstock agnostic” biofuel plant. Moreover, the spatially-explicit methodology we present here for calculating biosheds has broad applicability within the bioenergy space--and potentially beyond--as a research tool and decision-support framework.
 
Using maximum driving distance as the constraint to define the geographic extent of a bioshed, we performed a network analysis to estimate the composition of 213 biosheds surrounding current biorefinery locations. A polyline network of primary and secondary roads obtained from the US Department of Transportation served as the edges in our network while the point locations of biorefineries and feedstock production centroids were treated as nodes. As a first step in determining each refinery’s bioshed, we used a simple buffer of radius equal to the maximum drive distance constraint in order to limit the search space of possible FSPs to only those that could possibly fall within the bioshed. Utilizing the ‘igraph’ package in R and we implemented Dijkstra's shortest path algorithm to calculate the driving distances between refineries and their respective sets of candidate FSPs. Biosheds were defined as the subset of candidate FSPs for which routes were calculated that did exceed the maximum drive distance constraint.

Once the FSPs for a biorefinery were calculated, feedstock yields allocated to each FSP during the k-means clustering procedure were summed to determine the total available biomass within a bioshed.  Since separate FSPs were calculated for each type of feedstock, the feedstock composition of each bioshed can be readily analyzed. A logical next step in this analysis would involve determining the most probable blends of lignocellulosic feedstocks that are projected to be available within biosheds of current refinery locations. 

<br> 

#### Spatial Optimization of Next Generation Biorefineries: Case Study in the US Midwest

Though I did not carry this analysis through to the end, I did begin to explore the bioshed compositions of 842 hypothetical potential biorefinery locations across the US Midwest. There are several scripts and output data products in the project directory that came out of this branch of work, but these are only starting points to what could be a much more interesting and thorough case study. 

<br> 

___


### Guide to the Project Directory

The project files have been organized into a directory structure that is designed to maximize portability and reproducibility. The directory structure is also well suited for easily bundling
project files into an R Package down the line. Here, I will provide a brief orientation to the directory and general underlying workflow.

You are currently in the `Feedstock_Agnostic` root directory, hereafter referred to as `root/`. The file-system nested within this directory is designed to function as self-contained ecosystem. That is, no matter where you store the root directory on you local machine, all* scripts within the subdirectories should run and retrieve the data they need from other subdirectories using relative filepaths. The one exception to this rule is the `load.R` script within the `Feedstock_Agnostic/R_code` subdirectory. This script was developed to initially load the raw data files required for the project (i.e. `.csv`, `.shp`, `.xls`, etc.) and convert them an R-specific
binary data files (`.RDS`) which could be loaded and handled more easily in subsequent processing steps. Currently, the `root/raw_data_files/` subdirectory is compressed into a zipfile due to it's exceedingly large size (~35 GB). In order to run some of the R scripts which source data from `root/raw_data_files/` you will need to temporarily unzip this directory. Once you have finished running a script that requires this data, you may re-zip the directory so that it doesn't take up as much storage space on your disk. 

<br>

The following sections provide a more detailed an overview the other subdirectories within `root/`, and the files they contain: 

#### raw_data_files (zipped)
When unzipped, you will find the data files for this analysis in their original form. Additional information about each dataset and where it was obtained can be found in the `root/documentation/dataset_documentation.txt` file. The `raw_data_files` directory has several subdirectories, each containing a family of associated files for a particular dataset. For example, the `~/raw_data_files/cdl/` and `~/raw_data_files/nlcd/` folders house the raster files for the US Crop Data Layer and National Crop Landcover Database respectively. Since there are dependencies between files within each of these subdirectories it is important that they remain organized in this manner. 

<br>

#### raw_binary_data

This subdirectory contains the raw_binary_data files outputted by the `load.R` script described above.

<br>

#### clean_binary_data

This subdirectory contains the clean_binary_data files outputted by the `clean.R` script described above. These files are treated as read-only in analysis scripts.

<br>

#### R_code

This subdirectory contains all the R source code and scripts for the project. A brief overview of each source code file (or generic file type) is provided below. Further details about a source file can be found in the header comment placed at the top of each script. 

**`install_required_packages.R`** - An R script that installs all libraries required by other scripts in this project directory. Running this script before any others would be advisabel to ensure that all required packages are up to date on your local machine.  

**`main_analysis.R`** - The full-pipeline analysis script for calculating biosheds of biorefinery locations via a road network analysis using estimates of feedstock production distributions at the sub-county level. Outputs a `.csv` file with the feedstock supply data for the parameters specified. The control flow of this script should serve as a guide to understanding the workflow of the entire analysis. All other functions in the `~/R_code/` directory are sourced and called directly by `main_analysis.R`, or by a function within `main_analysis.R`. This file has been run through by CUI on October, 2017 after debugging. This can be seen as a template file on how to compute how to compute cluster, bioshed and mass in eachbioshed.

**`load.R`** - An R script that takes the raw data files required for the project as input and outputs a binary workspace image (`.RData`) to the`root/raw_binary_data` directory. This workspace image is loaded into the `clean.R` script for data cleaning and organization.

**`clean.R`** - An R script that takes the binary data files outputted by `load.R` as input, cleans and organizes datasets as needed for subsequent analyses and outputs individual binary data files (`.rds`) to the `root/clean_binary_data/` directory.

**`<name>_func.R`** - A script containing a function (or functions) that are sourced and called in
analysis scripts. The file name should generally reflect the aspect of the analysis to which the function(s) pertain. The header comment at the top of the script itself will provide a more detailed description of the function's purpose, inputs and outputs.

**`<name>_analysis.R`** - An analysis script that loads cleaned binary data from `\Feedstock_Agnostic\clean_binary_data` and sources `<name>.func.R` files to call functions
designed for the particular analysis being performed. The file name generally reflects the nature of the analysis. The header comment at the top of the script itself will provide a more detailed description of what it does and it's outputs (i.e. figures, files, reformatted data etc.)

**`<name>_plots.R`** - A plotting script that generates and exports figures to the `root/figures/ directory. See script headers for more details. Some plotting scripts may not be entirely functional as input data
that they once visualized upon may have changed. However, they may still provide useful templates for generating graphics of a similar style to ones created previously. 

In addition to the scripts described above, there is also a subdirectory within `root/R_code` named `R_code_arhives`. This a repository of R source files that were generated in the process of developing the current iteration of the modeling framework. Many of these scripts are out-of-date and may not be functional, however, I have archived them in this repository in case there are any useful code snippets that might be salvagable. While there are no gurantees about functionality, all the code is thoroughly commented so it should be fairly obvious what a particular construct was designed to accomplish.  

**`required.packages.R`** - In this R script, it lists all of the pacakges which are required to run these scripts. By run it, it can know which package needs to install

<br>

#### output

The `root/output/` directory acts as a catchment for all all data and files exported by R scripts. There are two subdirectories within `~/output/`: 

<br>

**`~/output/bin/`**  is a temporary cache for intermediate files produced during certain processing steps. Intermediate files are written to disk in this location for memory-intensive steps as a way to minimize strain on RAM.

**`~/output/data_products/`** is the directory where all final data products (that were computationally expensive to produce and have high reusability value) are saved. A number of datasets that have already been generated by running the global model with different input parameters. The structure contents of these existing data products are briefly described below. Note that the <placeholder> notation is used to generalize across files that shares similar structure and filenames but vary by the attributes in the <placeholder> slots. Also note that all `.RDS` files can easily be loaded into an R workspace for viewing and further manipulation using the readRDS(filepath) function call.

**`curr_ref_biosheds_<crop>_<range>mi.RDS`** - object of class dataframe with two columns, "RID" and "CIDS_IN_RANGE", (where RID denotes Refinery ID, and CID stands for Cluster ID). Entries in the "CIDS_IN_RANGE" column are structured as lists of the CIDS that were calulated to fall within the maximum drive distance indicated by the <range> placeholder in the filename. The for residue feedstocks, the <crop> placeholder designates the primary crop from which the feedstock in derived (and thus the cell values inthe CDL raster layer that were used in k-means clustering). Files with "EnergyCrops" in the <crop> slot indicate that crop and pasture cells in the NLCD raster layer were used in k-means clustering to identify sub-county centroids of potential energy crop production.

**`potential_midwest_ref_biosheds_EnergyCrops_50mi.RDS`** - object of the same structure as those described above, except instead of current biorefinery locations, this file contains bioshed data for 842 hyptothetical refinery locations distributed evenly across the US Midwest. Only dedicated energy crop contributions to these potential biorefineries have been calculated so far at a maximum haul distance of 50 miles.

**`potential_midwest_refs_sp_EnergyCrops_50mi.RDS`** - object of class SpatialPointsDataFrame containin the point locations and basic attribute data of the 842 hypothetical biorefinery locations across the US Midwest. 

**`US.cluster.cents.<crop>.RDS`** - object of class SpatialPointsDataFrame containing the point locations and basic attributes of the cluster centroids calculated following k-means clustering of <crop> raster cells in the CDL raster layer or, in the case of the "EnergyCrops" file, crop/pasture cells of the NLCD layer. Note that the file with "Sorghum" in the <crop> slot does not refer to biomass sorghum, but rather, sweet or grain sorghum from which sorghum stubble can be obtained as residue feedstock. 

**`output.bioshed.data.7.23.17.<ext>`** - a tabular dataset in either `.csv` or `.RDS` format that contains all the bioshed data calculated from model runs so far for existing US refineries (i.e. a synthesis of all the other data products in this directory, barring those related to the hyptothetical Midwest refinery locations). 

<br>

#### python_code

This subdirectory follows parallel structure of the the `R_code` directory with the only difference being that scripts are written in Python and thus have the extension `.py` instead of `.R`.  

<br>

#### figures

This subdirectoy is where all figures and graphs will be outputted from analysis scripts. A `README.txt` file also located here for including written documentation of figures if necessary.

<br>

#### documentation

This subdirectory contains additional written documentation related to the analysis and also a PowerPoint presentation with slides that offer nice visual aids for illustrating the project workflow. You can also find a (writable) R Markdown file used to generate the HTML format of this README document.

#### R_shiny

This subdirectory contains the drafted source code for a couple R Shiny web apps designed to help visualize the results of the bioshed analysis. Neither of the apps are currently functional, but I have included the code here in case there is ever interest in reviving them. 


`








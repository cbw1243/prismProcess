# This R script aims to produce growing season precipitation using precipitation data for each year from 1981-2018. 
# Specifically, this R script takes the zipped files (originally downloaded from the PRISM database)
# as inputs, and then extract the data from the zipped files. 

rm(list=ls())

library(raster)
library(data.table)
library(rgdal)
library(parallel)
library(dplyr)
library(tidyr)

#------------------------------------------------------------------------------------------------------#
# Set the parameters prior to running the codes. 
#------------------------------------------------------------------------------------------------------#
## NLCD projection
prjnlcd <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

## Specify the years of data to compile
years <- c(1981: 2019)

## countyfips-gridNumber bridge
gridInfoRaw <- read.table("../gridInfo.csv", header=TRUE, sep=",")

# Set the number of cores to use for parallel computing. 
# detectCores() # check the number of cores
cores <- 8

# Set the working directory to './PRISM_DATA_PROCESS/codes/'!!!!!

# Specify the directory that saves the raw PRISM daily weather data. 
inputDir <- 'C:/Users/bwchen/Box/gramig-lab-bowen/CRPEval/data/prism/daily'

# Specify the directory that saves the unzipped weather data. 
tmpDir <- 'C:/Users/bwchen/Documents/'

# Specify the directory that saves the processed data (output)
outDir <- "C:/Users/bwchen/Box/gramig-lab-bowen/PRISM_DATA_PROCESS/"

# set the temperature interval
Tint <- c(-60:60) # Not have to change
nT <- length(Tint)

# Define the growing season (such as from 0301 to 0831)
grow_season <- c('0820', '0831')

# Read the functions
source('temperature_daily_extract_func.r')

m <- 2018

#------------------------------------------------------------------------------------------------------#
# Now running the codes. 
#------------------------------------------------------------------------------------------------------#
for(m in years){
  cat('Working on data for', m, '\n')
  
  ## years for each bridge
  # (col3) 1992: 1981-1995 [make selcol be 3]
  # (col4) 2001: 1996-2003 [make selcol be 4]
  # (col5) 2006: 2004-2008 [make selcol be 5]
  # (col6) 2011: 2009-2018 (or later) [make selcol be 6]

  if(m <= 1995) selcol <- 3
  if(m >= 1996 & m <= 2003) selcol <- 4  
  if(m >= 2004 & m <= 2008) selcol <- 5  
  if(m >= 2009) selcol <- 6
  
  gridInfo <- gridInfoRaw [,c(1,2,selcol)]  
  
  selTime1 <- paste0(m, grow_season[1]); selTime2 <- paste0(m, grow_season[2]);
  
  # List all the files. 
  yfilenames.max <- list.files(path = paste(inputDir, "/tmax",m,sep = '/'))
  yfilenames.min <- list.files(path = paste(inputDir, "/tmin",m,sep = '/'))
  
  # Number of zipped files contained in one folder. Since one zipped file has data for one day
  # this number is also the number of days in the year, which shall be equal to 365
  ni <- length(yfilenames.max) # Return the number of files in the folder. 
  
  if(ni < 365) {stop; print('Number of days in the year is smalled than 365')}
  
  # Extract all the daily data using parallel computing
  # dailyData <- mclapply(1:ni, dailyDataExtract, mc.cores = 4)
  ## Get the data in the growing season only, rather than extracting all the daily data 
  # Extract the data during the growing season only. 
  cl <- makeCluster(cores)
  clusterExport(cl, c("m", 'yfilenames.max', 'yfilenames.min', 'prjnlcd', 'gridInfo', 'nT', 'days.in.range', 'Tint', 'inputDir', 'tmpDir'))
  clusterEvalQ(cl, library(raster))
  clusterEvalQ(cl, library(rgdal))
  clusterEvalQ(cl, library(dplyr))
  clusterEvalQ(cl, library(data.table))
  
  dailyData <- parLapply(cl, grep(selTime1, yfilenames):grep(selTime2, yfilenames), dailyDataExtract)
  
  # dailyData <- mclapply(grep(selTime1, yfilenames):grep(selTime2, yfilenames),
  #                        dailyDataExtract, mc.cores = 4) # mac version
  stopCluster(cl)
  
  aggData <- dailyData %>% 
    bind_rows() %>% 
    group_by(stco) %>%
    summarise_all(sum) %>%
    mutate(year = m)
 
  countySavePath <- paste0(outDir, selTime1, '_', selTime2, '_', 'gddCounty', m, '.csv')
  write.csv(x = aggData, file = countySavePath, row.names = F)
  
  # Remove the processed data after saving them into the local directory
  # rm(dailyData, countyAggDataWide, cl)
}



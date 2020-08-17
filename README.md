# Process the PRISM weather data 
The R codes process the PRISM weather data and generate county-level growing season variables (i.e., degree days and precipitation). It takes two steps to complete the process. 

We use the R code under the './CRPEval/codes/getData/PRISM_DATA_PROCESS/' folder to obtain and process the weather data. 

contains the codes that download and aggregate the daily weather data from the PRISM database. The weather data that we use consist of precipitation ("ppt"), maximum temperature ("tmax"), and minimum temperature ("tmin").  

## Step 1. Download the weather data from PRISM   

The raw weather data are from the [PRISM Climate Group](http://www.prism.oregonstate.edu/) of the Oregon State University. You can follow the instructions provided at the PRISM webiste [(here)](http://prism.oregonstate.edu/documents/PRISM_downloads_FTP.pdf) and use the FTP service to download the historical daily weather data from PRISM. You need to download data for three variables: precipitation ("ppt"), maximum temperature ("tmax"), and minimum temperature ("tmin").  

Caution: The PRISM updated the precipitation data on June 30, 2015 (see the announcement [here](http://www.prism.oregonstate.edu/whatsnew/) ). The "ppt" folder contains the updated precipitation data, and these are the data that we have downloaded and used for our empirical analyses. You might also see the "ppt_old_method" folder, which contains the out-dated precipitation data. We did **NOT** the out-dated precipitation data. 

Note: You can expected to download the data on your own. No R codes are needed.    

## Step 2. Process the weather data

The original PRISM data are at daily basis and are at 800m resolution (see [here](http://www.prism.oregonstate.edu/documents/PRISM_datasets.pdf)). The downloaded data (from the PRISM database via FTP) should be zipped file, and each zipped file contains data for temperature/precipitation in a day. What the R codes are doing here is to unzip the data (so you do not have to unzip them manually) and then aggregate the grid-cell level data to the county level. The aggregation follow the procedures described in [Seong and Gramig (2019)](https://www.mdpi.com/2306-5729/4/2/66). 

To obtain the aggregated precipitation data, you should run the codes in *precipitation_daily_extract.r* (in the codes folder). To obtain the aggregated degree day data, you should run the codes in *temperature_daily_extract.r* (in the codes folder). These codes will apply parallel computing and perform the aggregation efficiently. 


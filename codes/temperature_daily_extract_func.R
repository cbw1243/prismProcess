# https://help.goodsync.com/hc/en-us/articles/360007773451-Automated-Backup-with-Compression-and-Encryption
## temperature range code
days.in.range <- function(t0,t1,tMin,tMax ){
  n <-  length(tMin)
  t0 <-  rep(t0, n)
  t1 <-  rep(t1, n)
  t0[t0 < tMin] <-  tMin[t0 < tMin]
  t1[t1 > tMax] <-  tMax[t1 > tMax]
  u <- function(z, ind) (z[ind] - tMin[ind])/(tMax[ind] - tMin[ind])  
  outside <-  t0 > tMax | t1 < tMin
  inside <-  !outside
  time.at.range <- rep(0,n)
  time.at.range[inside] <- ( 2/pi )*( asin(u(t1,inside)) - asin(u(t0,inside)) ) 
  return( time.at.range )
}

dailyDataExtract <- function(i){
  
  # Unzip the file and extract the data, then delete the unzipped file
  folderCreate.max <- paste0(tmpDir, '/max_temp_to_be_deleted_', i)
  #cmd.max <- paste0('unzip -q ', inputDir, '/tmax/', m, '/', yfilenames.max[i],' -d', paste0(folderCreate.max))
  cmd.max <- paste0('7z x -o', paste0(folderCreate.max), ' ', inputDir, '/tmax/', m, '/', yfilenames.max[i])
  system(cmd.max)
  
  prism.tmax <- raster(paste(folderCreate.max, sub('\\.zip$', '.bil', yfilenames.max[i]),sep = "/"))
  prism.tmax <- projectRaster(prism.tmax, crs=prjnlcd)
  unlink(folderCreate.max, recursive = T)
  
  folderCreate.min <- paste0(tmpDir, '/min_temp_to_be_deleted_', i)
  #cmd.min <- paste0('unzip -q ', inputDir, '/tmin/', m, '/', yfilenames.min[i],' -d', paste0(folderCreate.min))
  cmd.min <- paste0('7z x -o', paste0(folderCreate.min), ' ', inputDir, '/tmin/', m, '/', yfilenames.min[i])
  system(cmd.min)
  
  prism.tmin <- raster(paste(folderCreate.min, sub('\\.zip$', '.bil', yfilenames.min[i]),sep = "/"))
  prism.tmin <- projectRaster(prism.tmin, crs=prjnlcd)
  unlink(folderCreate.min, recursive = T)
  
  tMax <- getValues(prism.tmax)
  tMin <- getValues(prism.tmin)

  gridNum <- 1:length(tMin)
  tempInfo <- data.frame(gridNum, tMin, tMax)
  merged <- merge(gridInfo, tempInfo, by="gridNum", all.x=TRUE)
  
  # NA control (If there is no data for the specific grid, use the average in the stco (or FIPS))
  # NA control
  midx <- which(is.na(merged),arr.ind = T)[,1]
  if (length(midx) != 0){
    for (mi in 1:length(midx)){
      stcomi <- merged[midx[mi],"stco"]
      merged[midx[mi],"tMin"] <- mean(merged[which(merged[,"stco"]==stcomi),"tMin"],na.rm=T)
      merged[midx[mi],"tMax"] <- mean(merged[which(merged[,"stco"]==stcomi),"tMax"],na.rm=T)
    }
  }
  
  # Calculate GDD by year
  Tvect <- lapply(1:nT, function(k) days.in.range(t0   = Tint[k]-0.5, 
                                                  t1   = Tint[k]+0.5, 
                                                  tMin = merged$tMin, 
                                                  tMax = merged$tMax)) %>%
    bind_cols()
  colnames(Tvect) <- c(paste0('gddm', 60:1), 'gdd0', paste0('gddp', 1:60))
  # Aggregate the GDD below (including) 0C degree and above (including) 40 degree
  #below0 <- rowSums(Tvect[, 1:61])
  #above40 <- rowSums(Tvect[, 101:121])
  #dataOut <- as.data.frame(cbind(merged[,1:3], below0, Tvect[, 62: 100], above40))
  
  dataOut <- as.data.table(cbind(merged[,1:4], Tvect))
  # Take weighted mean before returning the full dataframe.
  colnames(dataOut)[3] <- 'numAg'
  # Aggregate at county level. 
  out <- dataOut[,lapply(.SD, weighted.mean, w = numAg, na.rm = T), 
                 by = list(stco), .SDcols = colnames(Tvect)]

  return(out)
}


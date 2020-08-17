dailyDataExtract <- function(i){
  # import data
  # cat(i, '\b')
  # mon <- as.numeric(substr(yfilenames[i], 28, 29))
  # cat(yfilenames[i], '\r')
  
  # Unzip the file and extract the data, then delete the unzipped file
  folderCreate <- paste0(tmpDir, '/temp_to_be_deleted_', i)
  #cmd <- paste0('unzip -q ', zipDir, '/ppt/', m, '/', yfilenames[i],' -d', paste0(folderCreate))
  cmd <- paste0('7z x -o', paste0(folderCreate), ' ', inputDir, '/ppt/', m, '/', yfilenames[i])
  system(cmd)
  
  prism.ppt <- raster(paste(folderCreate, sub('\\.zip$', '.bil', yfilenames[i]),sep = "/"))
  prism.ppt <- projectRaster(prism.ppt, crs=prjnlcd)
  unlink(folderCreate, recursive = T)
  
  ppt <- getValues(prism.ppt)
  gridNum <- 1:length(ppt)
  pptInfo <- data.frame(gridNum,ppt)
  merged <- merge(gridInfo, pptInfo, by="gridNum", all.x=TRUE)
  
  # NA control (If there is no data for the specific grid, use the average in the stco (or FIPS))
  midx <- which(is.na(merged),arr.ind = T)[,1]
  if (length(midx) != 0){
    for (mi in 1:length(midx)){
      stcomi <- merged[midx[mi],"stco"]
      merged[midx[mi],"ppt"] <- mean(merged[which(merged[,"stco"]==stcomi),"ppt"],na.rm=T)
    }
  }
  
  colnames(merged)[3:4] <- c('numAg', 'ppt') 
  merged <- as.data.table(merged)
  
  out <- merged[,lapply(.SD, weighted.mean, w = numAg, na.rm = T), 
                 by = list(stco), .SDcols = 'ppt']
  
  return(out) 
}



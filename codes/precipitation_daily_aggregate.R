library(dplyr)
library(data.table)
setwd('~')

filenames <- list.files('../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/ppt/gridAgg/')
gridDataList <- lapply(filenames, function(x) fread(paste0('../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/ppt/gridAgg/', x)))
gridData <- bind_rows(gridDataList)

# Aggregate the data to county level. 
countyData <- gridData %>%
  as.data.frame() %>%
  group_by(year, stco) %>%
  dplyr::summarise(ppt = weighted.mean(ppt, w = numAg, na.rm=T))

write.csv(countyData, '../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/ppt/pptCounty19812018.csv', row.names = F)

# Aggregate the data to CRD (also called ASD) level.
countyASDmap <- data.table::fread('../Box/gramig-lab-bowen/CRPEval/data/CRD_shapefile/asds2009.csv') %>%
  dplyr::mutate(STASD = as.numeric(paste0(state, district)),
                fips = case_when(nchar(county) == 1 ~ paste0(state, '00', county),
                                 nchar(county) == 2 ~ paste0(state, '0', county),
                                 nchar(county) == 3 ~ paste0(state, county)),
                fips = as.numeric(fips)) 

ASDData <- gridData %>%
  as.data.frame() %>%
  left_join(., countyASDmap, by = c('stco' = 'fips')) %>% 
  group_by(year, STASD) %>%
  dplyr::summarise(ppt = weighted.mean(ppt, w = numAg, na.rm=T))

write.csv(ASDData, '../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/ppt/pptASD19812018.csv', row.names = F)

# Check with Seong's results. 
# load('/Users/bwchen/Box/gramig-lab-bowen/data/Validation/pptMarAug2015.rda')
# bc2015 <- fread('../Box/gramig-lab-bowen/data/prism_processed/MarchAugust/ppt/countyAgg/pptCounty19812018.csv') %>%
#   filter(year == 2015)
# summary(pptMarAug2015)
# summary(bc2015)
# 
# plot(countyData$ppt, pptMarAug2015$ppt, xlab = 'Seong_result', ylab = 'Bowen_result',
#      xlim = c(0, 1500), ylim = c(0, 1500))
# abline(a = 0, b = 1, col = 'red')
# summary(seong)
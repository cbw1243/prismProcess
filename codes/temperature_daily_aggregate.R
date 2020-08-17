rm(list=ls())
library(dplyr)
library(data.table)
library(rlang)
library(ggplot2)
setwd('~')

# Aggregate the county-level CSV files in different years as a single CSV file. 
filenames <- list.files('../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/gdd/countyAgg/')
countyDataList <- lapply(filenames, function(x) fread(paste0('../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/gdd/countyAgg/', x)))
countyData <- bind_rows(countyDataList)

write.csv(countyData, '../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/gdd/gddCounty19812018.csv', row.names = F)


# Aggregate the ASD-level CSV files in different years as a single CSV file. 
filenames <- list.files('../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/gdd/asdAgg/')
asdDataList <- lapply(filenames, function(x) fread(paste0('../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/gdd/asdAgg/', x)))
asdData <- bind_rows(asdDataList)

write.csv(asdData, '../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/gdd/gddASD19812018.csv', row.names = F)


# Check with Seong's results. 
seong <- fread('/Users/bwchen/Box/gramig-lab-bowen/CRPEval/data/seongCountyData/gddMarAug.csv')
bowen <- fread('../Box/gramig-lab-bowen/CRPEval/data/prism_processed/MarchAugust/gdd/gddCounty19812018.csv')

focusGDD <- paste0('gddp', 29:60, collapse = '+')

yearsel <- 1985
seongEx <- seong %>%
  filter(year == yearsel) %>%
  mutate(gddx29 = !!parse_quo(focusGDD, env = global_env())) %>%
  dplyr::select(year, stco, gddx29)

bowenEx <- bowen %>%
  filter(year == yearsel) %>%
  mutate(gddx29 = !!parse_quo(focusGDD, env = global_env())) %>%
  dplyr::select(year, stco, gddx29)

allEx <- seongEx %>%
  full_join(., bowenEx, by = c('year', 'stco'))

plot(allEx$gddx29.x, allEx$gddx29.y, col = 'blue', cex = 0.5, 
     xlab = 'GDDs >= 29 in 2015 produced by Seong',
     ylab = 'GDDs >= 29 in 2015 produced by Bowen')

summary(allEx)
all.equal(allEx$gddx29.x, allEx$gddx29.y)


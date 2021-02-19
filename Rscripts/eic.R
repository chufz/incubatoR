#!/usr/bin/env Rscript
# Script for extracting EIC with a 3-group color code
# Usage Rscript eic.R [textfile] [pattern1] [pattern2] [pattern3] [mzml_directory] [output_directory] [rt_window] [mz_window] [logical_rtinminutes?] [logical_peakids?] 
args = commandArgs(trailingOnly=TRUE)
############################################
library(xcms)
library(ggplot2)
library(RColorBrewer)
############################################
# read in features
message("[EIC] Read in feature")
result_final <- read.table(file=args[1])

#read in either mz values or peakids
if(as.logical(args[10])==T){
	message("[EIC] Treating as Feature peakIDs (mz@rt)")
	features <- strsplit(as.character(result_final[,1]),"@")
	}
if(as.logical(args[10])==F){
	message("[EIC] Only mz provided")
	features <- result_final[,1]
	}


message("[EIC] Get files")
# Get files
groupfiles <- list.files(path= args[5], pattern = args[2], full.names = T)
comparefiles <- list.files(path= args[5], pattern = args[3], full.names = T)
cleanfiles <- list.files(path= args[5], pattern = args[4], full.names = T)
files <- c(groupfiles, comparefiles, cleanfiles)    
message("[EIC] Read in data: ", files)
# read in data
raw_data <- readMSData(files = files, mode = "onDisk")
##############################################
message("[EIC] Start plotting")
sample_group <- c(rep("Incubated", length(groupfiles)), rep("Compare", length(comparefiles)), rep("Standard", length(cleanfiles)))
group_colors <- c("red", "green", "blue") #paste0(brewer.pal(3, "Set1")[1:3], "60")
names(group_colors) <- c("Incubated","Compare","Standard")

output <- paste0(args[6], "/", args[2])
if(!dir.exists(output)){ dir.create(output)}

# Plot chomatogramms
for(i in 1:length(features)){
    if(as.logical(args[10])==T){
        rt <- as.numeric(features[[i]][2])
        if(as.logical(args[9])==FALSE){
            rt <- rt/60
        }
        mz <- as.numeric(features[[i]][1])
        message("[EIC] m/z: ", mz[1], " at RT(min): ", rt)
        rt_range <- c( (rt - as.numeric(args[7]))*60, (rt + as.numeric(args[7]))*60)
    }
    
    if(as.logical(args[10])==F){
        rt_range <- c(120,1200)
        mz <- as.numeric(features[i])
    }
    
    mz_range <- c( mz - as.numeric(args[8]), mz + as.numeric(args[8]))
    message("[EIC] Build Chromatogram mz= ", mz_range[1], "-", mz_range[2], " rt= ", rt_range[1], "-",rt_range[2], " sec"	)
    bpis <- chromatogram(raw_data, mz=mz_range, rt=rt_range)
    message("[EIC] Plot to ",  paste0(args[6], "/Feature_", mz, ".png"))
    MS1 <- list()
    for(j in 1:length(bpis@.Data)){
        
        MS1[[j]] <- data.frame(RT=(bpis@.Data[[j]]@rtime/60), Intensity=bpis@.Data[[j]]@intensity)
        MS1[[j]] <- MS1[[j]][which(!is.na(MS1[[j]]$Intensity)),]
    }
    if(all(isEmpty(MS1)))(message("No Chromatogramm found, Compound seems to be absent"))else{
        #message(MS1)
        message("[EIC] Datawrangling with dplyr") 
        MS1_data <- dplyr::bind_rows(MS1,  .id="sample")
        
        #message( colnames(MS1_data),   head(MS1_data))
        
        MS1_data$samplegroup <- "" 
        message("[EIC] Sample groups " , sample_group)
        for(j in 1:nrow(MS1_data)){
            # message(j, "->", sample_group[as.numeric(MS1_data$sample[j])])
            MS1_data$samplegroup[j] <- sample_group[as.numeric(MS1_data$sample[j])]
        }
        
        theme_set(theme_classic())
        message("[EIC] Plot to ",  paste0(args[6], "/Feature_", result_final[i,1], ".png"))
        ggplot(data=MS1_data, aes(x=RT, y=Intensity, color=samplegroup, group= sample)) + geom_line()    
        ggsave(paste0(output,"/Feature_", mz, ".png" ))
    }
    
}



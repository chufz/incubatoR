#!/usr/bin/env Rscript
# Script for extracting dd-Scans and generating summary table
# Usage Rscript ddextract.R [featurefile] [path to mzML] [outputdirectory] [mzwindow] [rt_window(sec)] [samplepattern] [puritythreshold]
# Output: List with Filename, scannumber, purityscore ; Folder for each Peakid with dd-Extract 
args = commandArgs(trailingOnly=TRUE)
########################################
if(!requireNamespace("msPurity", quietly = TRUE)) BiocManager::install("msPurity") # will install msPurity in case it is not installed yet
library(xcms)
library(stringr)
library(msPurity)
library(mzR)
########################################
message("[DDextract] Read in data")
peakids <- read.table(file=args[1], header= F)
mz <- as.numeric(unlist(lapply(strsplit(peakids[,1], "@"), function(x){x[1]})))
rt <- as.numeric(sapply(strsplit(peakids[,1], "@"),"[[",2))
message("[DDextract] Get mzML files")
mzMLpths <- list.files(path= args[2], pattern=args[6], full.names = T)
########################################
message("[DDextract] Run MSPurity, please wait...")
pa <- purityA(mzMLpths)
ms_result <- pa@puritydf
########################################
message("[DDextract] Search in result for Peakid- related entries")
res <- list()
for(i in 1:length(mz)){
    mzwindow <- c(mz[i]-as.numeric(args[4]),mz[i]+as.numeric(args[4]))
    rtwindow <- c(rt[i]*60-as.numeric(args[5]),rt[i]*60+as.numeric(args[5]))
    scans <- which(ms_result$precursorMZ > mzwindow[1] & ms_result$precursorMZ < mzwindow[2] & ms_result$precursorRT > rtwindow[1] & ms_result$precursorRT < rtwindow[2])
    res[[i]] <- ms_result[scans,]
}
########################################
message("[DDextract] Create folder for each Peakid where MSMS was found, store a resultfile")
message("[DDextract] Extract MS2 scans and save as txt")
dirnames <- str_replace(peakids[,1], "@", "_")
no_scans <- unlist(lapply(res, nrow))
if(sum(no_scans)> 0){
    for(i in 1:length(res)){
        if(no_scans[i]>0){
            #create directory
            if(!dir.exists(paste0(args[3],"/", dirnames[i]))){dir.create(paste0(args[3],"/", dirnames[i]))}
            #save summary file
            write.csv(res[[i]], paste0(args[3],"/", dirnames[i], "/Result_mspurity.csv"))
            #extract MSMS
            for(j in 1:nrow(res[[i]])){
                if(res[[i]]$aPurity[j]> args[7]){
                    aq_scan <- res[[i]]$acquisitionNum[j]
                    file <- paste0(args[2],res[[i]]$filename[j])
                    file2 <- tools::file_path_sans_ext(basename(file))
                    #open file
                    mzml <- openMSfile(file)
                    pl <- mzR::peaks(mzml, aq_scan)
                    ce <- mzR::header(mzml)$collisionEnergy[aq_scan]
                    write.table(pl, file=paste0(args[3],"/", dirnames[i],"/",file2,"_",aq_scan,"_", ce, ".txt"), row.names=F, col.names=F)
                    rm(mzml)
                }else{message("[DDextract] MSMS purity score is lower than applied threshold")}
            }
        }
    }
}else{message("[DDextract] No MSMS has been found to the associated Peakids")}
########################################



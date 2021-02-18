#!/usr/bin/env/RScript
# Usage Rscript xcms.R [settingsfile] [classfile] [outputdirectory]
args = commandArgs(trailingOnly=TRUE)

library(yaml)
library(xcms)

settings <- read_yaml(args[1])
file <- read.csv(args[2])
message("Class file contains col:",colnames(file))

files_s9 <- as.character(file$path)
message("Files found:", files_s9)
sclass_s9 <- file$class

xset <- xcmsSet(
    files = files_s9,
    sclass =sclass_s9,
    method = settings$xcmsSet$method,
    peakwidth       = c(as.numeric(settings$xcmsSet$peakwidth_min), as.numeric(settings$xcmsSet$peakwidth_max)),
    ppm             = as.numeric(settings$xcmsSet$ppm),
    noise           = as.numeric(settings$xcmsSet$noise),
    snthresh        = as.numeric(settings$xcmsSet$snthresh),
    mzdiff          = as.numeric(settings$xcmsSet$mzdiff),
    prefilter       = c(as.numeric(settings$xcmsSet$prefilter_min), as.numeric(settings$xcmsSet$prefilter_max)),
    mzCenterFun     = settings$xcmsSet$mzCenterFun,
    integrate       = as.numeric(settings$xcmsSet$integrate),
    fitgauss        = settings$xcmsSet$fitgauss,
    verbose.columns = settings$xcmsSet$verbose)

xset <- group(
    xset,
    method  = settings$group$method,
    bw      = as.numeric(settings$group$bw),
    mzwid   = as.numeric(settings$group$mzwid),
    minsamp = as.numeric(settings$group$minsamp),
    max     = as.numeric(settings$group$max))

xset <- retcor( 
    xset,
    method         = settings$retcor$method,
    plottype       = settings$retcor$plottype,
    distFunc       = settings$retcor$distFunc,
    profStep       = as.numeric(settings$retcor$profStep),
    center         = as.numeric(settings$retcor$center),
    response       = as.numeric(settings$retcor$response),
    gapInit        = as.numeric(settings$retcor$gapInit),
    gapExtend      = as.numeric(settings$retcor$gapExtend),
    factorDiag     = as.numeric(settings$retcor$factorDiag),
    factorGap      = as.numeric(settings$retcor$factorGap),
    localAlignment = as.numeric(settings$retcor$localAlignment))

xset <- group( 
    xset,
    method  = settings$group2$method,
    bw      = as.numeric(settings$group2$bw),
    mzwid   = as.numeric(settings$group2$mzwid),
    minsamp = as.numeric(settings$group2$minsamp),
    max     = as.numeric(settings$group2$max))
    
if(settings$fillPeaks){
	xset <- fillPeaks(xset)
	}

saveRDS(xset, file=paste0(args[3],"/xcms.rds"))



#!/usr/bin/env Rscript
# Script to apply CAMERA on xcms Result
# Usage Rscript camera.R [settingsfile] [xcms_output] [mode] [outputdirectory]
args = commandArgs(trailingOnly=TRUE)

library(CAMERA)
library(yaml)

settings <- read_yaml(args[1])
xset <- readRDS(args[2])

an <- xsAnnotate(xset)
anF <- groupFWHM(an, perfwhm=as.numeric(settings$perfwhm))
anI <- findIsotopes(anF, mzabs=as.numeric(settings$mzabs))

# look at EIC (mzmLData needed)
anIC <- groupCorr(anI, cor_eic_th = as.numeric(settings$cor_eic_th))
# define polarity
if(args[3]=="Pos"){pol <- "positive" }else{pol <- "negative"}
anFA <- findAdducts(anIC, polarity=pol)
peaklist <- getPeaklist(anFA)

# split file
groups_no <- length(groups(xset))
file_no <- length(samples(xset))
message("Splitting file for ", groups_no, " groups and ", file_no, " sample files")
peaklist_only <- peaklist[,(16+groups_no):ncol(peaklist)-34
metadata <- cbind(peaklist[1:(15+groups_no)], peaklist[,(ncol(peaklist))-3:ncol(peaklist)])

# save as tsv
write.table(peaklist_only, paste0(args[4],"peaklist.tsv"), col.names=F, quote=F, sep='\t')
write.table(metadata, paste0(args[4],"metadata.tsv"), col.names=F, quote=F, sep='\t')

# save camera file
saveRDS(anFA, file=paste0(args[4],"/camera.rds"))

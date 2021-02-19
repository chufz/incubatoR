#!/usr/bin/env Rscript
# Script to generate Volcano, wilk test and t test from xcmsSet diff report between two samplenames with different pattern.
# Usage Rscript statistics.R [peaklist.tsv] [metadata.tsv] [outputdirectory] [compound_pattern] [compare] [clean_pattern] [reverse_pattern] [settingsfile] 
args = commandArgs(trailingOnly=TRUE)
########################################
library(Rvolcano)
library(yaml)
######################################## 
# Read in settings-file
message("Read settings: ", args[8])
settings <- read_yaml(args[8])
########################################
# Read in data
message("Read in data: ", args[1], " and ", args[2])
data <- read.delim(args[1], sep="\t")
data_info <- read.delim(args[2], sep="\t")
data <- data[, -seq(settings$remove_colums)]
######################################## 
# Blank removal
######################################## 
if(settings$blank_removal){
    if(settings$bigger_than_group){
        message("[Volcano.R] Removal of Blankpattern: ", settings$blankpattern, " Removing all peaks with a higher median than in the group.")
        # calculating median of group
        median_group <- apply(data[,grep(args[4],colnames(data))], 1, median)
        # get median value of Blanks
        blanks <- data[,grep(settings$blankpattern,colnames(data))]
        median_blank <- apply(blanks, 1, median)
        message("[Volcano.R] ", length(which(median_blank > median_group)), " Features will be removed, leaving ", length(which(median_blank < median_group)), " Features" )
        # remove rows from data
        data <- data[-which(median_blank > median_group),]
        # keep data info
        data_info <- data_info[-which(median_blank > median_group),]
    }else{
        message("[Volcano.R] Removal of Blankpattern: ", settings$blankpattern, " Removing all peaks with a higher median than ", settings$blank_threshold)
        blanks <- data[,grep(settings$blankpattern,colnames(data))]
        # get median value
        median_blank <- apply(blanks, 1, median)
        message("[Volcano.R] ", length(which(median_blank > as.numeric(settings$blank_threshold))), " Features will be removed, leaving ", length(which(median_blank < as.numeric(settings$blank_threshold))), " Features" )
        # remove rows from data
        data <- data[-which(median_blank > as.numeric(settings$blank_threshold)),]
        # keep data info
        data_info <- data_info[-which(median_blank > as.numeric(settings$blank_threshold)),]
    }
}else{message("[Volcano.R] No Blank removal performed ")}

######################################## 
# Group and conrols
########################################
message("[Volcano.R] Retrieving class levels ", args[4])
dataG <- data[ , grep(args[4], colnames(data))]
colnames(dataG)
#get controls from aligned object
message("[Volcano.R] Retrieving control levels ", args[5])
dataC <- data[ , grep(args[5], colnames(data))]
#Remove negative control pattern
if(nchar(args[7])>0){
    	message("[Volcano.R] Retrieving reverse control levels ", args[7], " will remove ", length(grep(args[7], colnames(dataC))), " groups.")
        if(length(grep(args[7], colnames(dataC)))>0){
		dataC <- dataC[ , -grep(args[7], colnames(dataC))]
	}
}
message("[Volcano.R] Dataset with ", ncol(dataG), " Group Samples and ", ncol(dataC), " Contol Samples")

######################################## 
# Data cleanup
########################################
message("[Volcano.R] Datawrangling")
# generate transformed dataset
transformed_group <- as.data.frame(t(dataG))
transformed_compare <- as.data.frame(t(dataC))

#remove features that are not present in group
message("[Volcano.R] Remove features that are not in Group")
countzero <- apply(transformed_group,2, function(x){sum(x==0)})
zeroyes <- which(countzero == nrow(transformed_group))
if(length(zeroyes > 0)){
    transformed_group <- transformed_group[,-zeroyes]
    transformed_compare <- transformed_compare[, -zeroyes]
    data_info <- data_info[ -zeroyes,]
}
#replace zeros in compare with half of the min value of min feature
message("[Volcano.R] Produce dummy values for zeros in dataset")
# handle data where only zeros are in compare dataset, produce dummy values
allzero_compare <- which(apply(transformed_compare,2, sum)== 0)
if(length(allzero_compare)> 0){
    set.seed(500)
    transformed_compare[,allzero_compare] <- runif(nrow(transformed_compare), 100, 200)
}
message("[Volcano.R] Replacing zeros in Control Group with random between min and 1/2 of the min found value")
countzero_compare <- apply(transformed_compare,2, function(x){sum(x==0)})
zeroyes_compare <- which(countzero_compare >1)
if(length(zeroyes_compare)>0){
   # for all other zeros, get the half of the lowest value that is not zero
   for(i in 1:length(zeroyes_compare)){
        x <- min(transformed_compare[which(transformed_compare[ , zeroyes_compare[i]] > 0),zeroyes_compare[i]])/2
        thezero <- which(transformed_compare[ , zeroyes_compare[i]]==0)
        set.seed(500)
        dummies <- runif(nrow(transformed_compare), x, 2*x)
        for(j in 1: length(thezero)){
            transformed_compare[ thezero[j] , zeroyes_compare[i]] <- dummies[j]
        }
    }
}
######################################## 
# Calculate statistics
########################################
if(settings$robust_FC){
    message("[Volcano.R] Calculating robust fold change")
    fc_result <- Rvolcano::foldChngCalc(t(rbind(transformed_compare, transformed_group)), nrow(transformed_compare), nrow(transformed_group))
    # calc robust pvalue A kernel weight function has been used behind the test statistic to robustify the t-test.
}else{
    #calculate normal fc
    foldchange <- function(x,y){log2(mean(x))- log2(mean(y))}
    fc_result <- unlist(mapply(foldchange, x= transformed_group, y = transformed_compare, SIMPLIFY = F))
}    
mean_group <-unlist(mapply(mean, x= transformed_group, SIMPLIFY = F))
mean_compare <- unlist(mapply(mean, x= transformed_compare, SIMPLIFY = F))

if(settings$robust_ttest){
    message("[Volcano.R] Calculating robust t-test")
    t.test_results <- mapply(Rvolcano::p.valcalc, x= transformed_group, y = transformed_compare, SIMPLIFY = F)
    p_value <- unlist(t.test_results)
}else{
    #calc normal t.test
    t.test_results <- mapply(t.test, x= transformed_group, y = transformed_compare, SIMPLIFY = F)
    p_value <- unlist(lapply(t.test_results, "[[", "p.value"))
}

######################################## 
# Generate Output
########################################
message("[Volcano.R] Combining Result")
result_combined <- data.frame(mz=data_info$mz, rt=data_info$rt, fc_result, p_value, mean_group, mean_compare, isotopes=data_info$isotopes, adduct=data_info$adduct)
rownames(result_combined) <- colnames(transformed_group)

if(sum(is.na(result_combined$p_value))>0){
    message("[Volcano.R] ", sum(is.na(result_combined$p_value)), " NAs produced during t-test")
}
if(sum(is.infinite(result_combined$fc_result))>0){
    message("[Volcano.R] INF produced during calculation of FC")
}

######################################## 
# Standard control comparison annotation
########################################
if(nchar(args[6])>0){
    message("[Volcano.R] Annotating peaks from Sample with pattern ", args[6])   
    # get colums from data by colname
    clean <- data.frame(data[, grep(args[6], colnames(data))])
    rownames(clean) <- rownames(data)
    result_combined$in_clean <- 20
    for(i in 1:nrow(result_combined)){
        # compare values
        clean_value <- clean[which(rownames(clean)==rownames(result_combined)[i]),1]   
        # store T/F
        if(clean_value > result_combined$mean_group[i]){result_combined$in_clean[i] <- 1}
        }
    if(ncol(clean) > 1){
        message("[Volcano.R] ", ncol(clean)," Samples found. First Sample is taken with samplename: ", colnames(data)[grep(args[6], colnames(data))])     
    }
}else{result_combined$in_clean <- 20 }
########################################
if(!dir.exists(args[3])){ dir.create(args[3])}

message("[Volcano.R] Saving Result")
saveRDS(result_combined, file = paste0(args[3], "/Result_", args[4], ".rds"))



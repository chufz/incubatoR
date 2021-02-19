#!/usr/bin/env Rscript
# Script to filter the features which are suspect to be metabolites
# applying mass defect filtering and cut-off values
# Usage Rscript metabolites.R [Result_compound] [outputdir] [target_mass] [mzparent] [rtparent] [settingsfile] [mode]
args = commandArgs(trailingOnly=TRUE)

library(scales)
library(yaml)

# read in settings
message("Read in settings")
settings <- read_yaml(args[6])

# load volcano result
message("Read in statistic result")
result_combined <- readRDS(args[1]) 
head(result_combined)

message("Read txt files")
target <-read.table(args[3]) 
mz_diff <- settings$mz_diff
mode <- args[7]
mz_parent <- read.table(args[4])
rt_parent <- read.table(args[5] )

# define new color column
result_combined$color <- 'black'

# annotate targets
target$V1 <- as.numeric(target$V1)
target$min <- target$V1 - as.numeric(mz_diff)
target$max <- target$V1 + as.numeric(mz_diff)

# filter peakids by target list
message("Color target metabolites")
for(i in 1:nrow(target)){
    target_rowid <- which(result_combined$mz > target$min[i] & result_combined$mz < target$max[i])
    if(length(target_rowid)>0){
        result_combined$color[target_rowid]   <- "red"
    }
}

# make color scale of adducts and isotopes
if(settings$isotope_color){
	message("Make color scale of adduct and isotopes")
	isotopes1 <- which(nchar(as.character(result_combined$data_info.isotopes)) > 0 ) 
	isotopes2 <- grep("[M]+", as.character(result_combined$data_info.isotopes), fixed = T)
	isotopes <- isotopes1[!isotopes1 %in% isotopes2]
	adducts1 <- which(nchar(as.character(result_combined$data_info.adduct)) > 0)
	if(mode == "Pos"){
    		adducts2 <- grep("[M+H]+", as.character(result_combined$data_info.adduct), fixed = T)
	}else{
    		adducts2 <- grep("[M-H]-", as.character(result_combined$data_info.adduct), fixed = T)
	}
	adducts <- adducts1[!adducts1 %in% adducts2]
	# which isotopes are actual targets?
	FN_i <- which(result_combined$color[isotopes]=="red")
	FN_a <- which(result_combined$color[adducts]=="red")
	# color the others
	result_combined$color[isotopes] <- 'grey'
	result_combined$color[adducts] <- 'grey'

	# color the wrong annotated different
	result_combined$color[isotopes[FN_i]] <- 'red'
	result_combined$color[adducts[FN_a]] <- 'red'
}


# Diff plot
message("Plot diffplot.png")
png(paste0(args[2], "/diffplot.png"), type= "cairo-png")
plot(log2(result_combined$mean_compare)~log2(result_combined$mean_group),
     pch=result_combined$in_clean,
     cex=0.8,
     cex.lab=1.4,
     cex.axis=1.2,
     col=result_combined$color,
     xlim=c(10,35),
     ylim=c(10,35),
     xlab="log2(Mean Intensity replicate)",
     ylab="log2(Mean Intensity control)")
abline(a=-2,b=1, lty=log2(settings$FC_cutoff))
abline(a=0, b=1)
dev.off()

#volcano plot
message("Plot volcano.png")
png(paste0(args[2], "/volcano.png"))
plot(result_combined$fc_result, -log10(result_combined$p_value),
          pch=result_combined$in_clean,
          cex=1.2,
          cex.axis=1.3,
          cex.lab=1.3,
          col=result_combined$color,
          xlab = "log2 FC",
          ylab = "-log10(p value)")
abline(v=settings$FC_cutoff, lty=4)
abline(h=-as.numeric(log(settings$p_cutoff)), lty=4)
dev.off()

message("P-value cutoff:")
r <- result_combined[which(result_combined$p_value < as.numeric(settings$p_cutoff)),]
message("-> leaving ",nrow(r), " features")
message("FC cutoff:")
r <- r[which(r$fc_result > settings$FC_cutoff),]
message("-> leaving ", nrow(r), " features")

message("Calculate MDF shift to parent m/z ", mz_parent)
r$MD_shift <- ((r$mz - round(r$mz,0))-(as.numeric(mz_parent)-round(as.numeric(mz_parent),0)))*1000

message("Plot MDF.png")
png(paste0(args[2], "/MDF.png"))
plot(r$MD_shift~r$mz,
      pch=r$in_clean,
      xlab= "m/z [mu]",
      cex= 1.5,
      cex.lab=1.3,
      cex.axis=1.3,
      ylab= "mass defect shift [mmu]",
      col= r$color)
abline(v=mz_parent+ settings$mz_upper_cutoff, lty=4)
abline(h=settings$mdf_upper_cutoff, lty=4)
abline(h=settings$mdf_lower_cutoff, lty=4)
dev.off()

message("Plot Legend.png")
png(paste0(args[2],"/Legend.png"))
plot.new()
legend("topleft", legend=c("target metabolite", "suspect feature", "isotope/adduct", "standard impurity"), col=c('red', 'black', 'grey', 'black', 'black'), pch=c(20, 20,20,1))
dev.off()

message("MZ cutoff: ")
r <- r[which(r$mz < (as.numeric(mz_parent) + as.numeric(settings$mz_upper_cutoff))),]
message("-> leaving ", nrow(r), " features")
message("MDF-shift filter: ")
r <- r[which(r$MD_shift < settings$mdf_upper_cutoff ),]
r <- r[which(r$MD_shift > -settings$mdf_lower_cutoff),]
message("-> leaving ", nrow(r), " features")
if(settings$isotope_removal){
	message("Removing annotated isotopes and adducts: ")
	r <-r[which(r$color != "grey"),] 
	message("-> leaving ", nrow(r), " features")
}
message("Standard residual filter: ")
r <- r[which(r$in_clean != 1),] 
message("-> leaving ", nrow(r), " features")

message("Plot Feature.png")
png(paste0(args[2],"/Feature.png"))
plot(r$rt~r$mz,
     xlab= "m/z",
     col= r$color,
     cex=1.5+scale(r$mean_group),
     cex.lab=1.3,
     cex.axis=1.3,
     ylab= "RT [min]")
par(xpd=FALSE)
abline(h=rt_parent, lty=4)
abline(v=mz_parent+1.0784, lty=4)
par(xpd=TRUE)
legend("top",bty='n', horiz=T, inset=c(0,-0.15), xjust=0.5, legend=c(paste0(" Int: ", scientific(min(r$mean_group),0)), paste0("  Int: ", scientific(median(r$mean_group),0)), paste0("     Int: ", scientific(max(r$mean_group),0))), pt.cex=c(median(1.5+scale(r$mean_group)),mean(1.5+scale(r$mean_group)),max(1.5+scale(r$mean_group))), col=c('black', 'black','black'), pch=c(1,1,1),y.intersp=1.9, x.intersp=0.9)
dev.off()
########################################
message("[Volcano.R] Saving PeakID list")
metabolites <- paste0(round(r$mz,5), "@", round(r$rt/60, 3))
write.table(metabolites, file=paste0(args[2],"/Metabolites.txt" ), row.names = F, col.names = F)
########################################
message("[Volcano.R] Save decriptive Statistics in csv")
write.csv(r, file=paste0(args[2],"/Statistics.csv"))
########################################

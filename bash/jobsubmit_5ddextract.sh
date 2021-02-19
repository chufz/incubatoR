#!/bin/bash
source globalvar.sh
# [featurefile] [path to mzML] [outputdirectory] [mzwindow] [rt_window(sec)] [samplepattern] [puritythreshold]

for h in $glob_mode
	do
	CLASS=$(cat "$glob_filedir/$h/class.csv" | cut -d "," -f 2 | grep "_clean" | sed 's/_clean//g')

	for i in $CLASS
		do
		mkdir $glob_workdir/$h/$i/MSMS
		echo "
		module load Anaconda3
		source activate $glob_ENV
		Rscript $glob_Rscripts/ddextract.R $glob_workdir/$h/$i/Metabolites.txt $glob_filedir/$h  $glob_workdir/$h/$i/MSMS 0.005 20 $(echo $i)_R 0.4 " # |  qsub -N EIC_$i  -l h_rt=00:40:00 -l h_vmem=10G -binding linear:1 #-o $PROCESSFOLDER/joboutput_preprocessing/$JOB_ID.log -e $PROCESSFOLDER/joboutput_preprocessing/$JOB_ID.log  
		done
done  

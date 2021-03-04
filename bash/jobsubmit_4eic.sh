#!/bin/bash
source globalvar.sh
# [textfile] [pattern1] [pattern2] [pattern3] [mzml_directory] [output_directory] [rt_window] [mz_window] [logical_rtinminutes?] [logical_peakids?]

for h in $glob_mode
	do
	CLASS=$(cat "$glob_filedir/$h/class.csv" | cut -d "," -f 2 | grep "_clean" | sed 's/_clean//g')

	for i in $CLASS
		do
		mkdir $glob_workdir/$h/$i/EIC
		echo "
		module load Anaconda3
		source activate $glob_ENV
		Rscript $glob_Rscripts/eic.R $glob_workdir/$h/$i/Metabolites.txt $(echo $i)_R 'NC' $(echo $i)_clean $glob_filedir/$h $glob_workdir/$h/$i/EIC 4 0.001 T T "  |  qsub -N EIC_$i  -l h_rt=00:40:00 -l h_vmem=10G -binding linear:1 #-o $PROCESSFOLDER/joboutput_preprocessing/$JOB_ID.log -e $PROCESSFOLDER/joboutput_preprocessing/$JOB_ID.log  
		done
done  

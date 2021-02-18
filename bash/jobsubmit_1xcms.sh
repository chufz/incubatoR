#!/bin/bash

source globalvar.sh
mkdir $glob_workdir/
for i in $glob_mode
	do
		mkdir $glob_workdir/$i
		echo "module load Anaconda3
		source activate $glob_ENV
		Rscript $glob_Rscripts/xcms.R $glob_input/$i/settings_xcms.yaml $glob_filedir/$i/class.csv $glob_workdir/$i" | qsub -S /bin/bash -l h_rt=10:00:00 -l h_vmem=10G, -binding linear:1 -cwd -m e -N xcms_$i
	done


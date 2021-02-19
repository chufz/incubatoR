#!/bin/bash

source globalvar.sh

for i in $glob_mode
	do
		echo "module load Anaconda3
		source activate $glob_ENV
		Rscript $glob_Rscripts/camera.R $glob_input/$i/settings_camera.yaml $glob_workdir/$i/xcms.rds $i $glob_workdir/$i/" | qsub -S /bin/bash -l h_rt=10:00:00 -l h_vmem=10G, -binding linear:1 -cwd -m e -N camera_$i
	done

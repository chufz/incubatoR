#!/bin/bash
source globalvar.sh
# [Result_compound] [outputdir] [target_mass] [mzparent] [rtparent] [settingsfile] [mode]

for h in $glob_mode
do
        CLASSFILE=$glob_filedir/$h/class.csv
        CLASS=$(cat $CLASSFILE | cut -d "," -f 2 | grep "_clean" | sed 's/_clean//g')
        for i in $CLASS
        do
                echo "
                module load Anaconda3
                source activate $glob_ENV
                Rscript $glob_Rscripts/metabolites.R $glob_workdir/$h/$i/Result_$(echo $i).rds $glob_workdir/$h/$i $glob_input/$h/$i/target_$(echo $i).txt $glob_input/$h/$i/parent_$(echo $i).txt $glob_input/$h/$i/RT_$(echo $i).txt $glob_input/$h/settings_metabolites.yaml $h" #  |  qsub -N statistic_$h_$i  -l h_rt=00:20:00 -l h_vmem=10G -binding linear:1  -o $glob_workdir/$h/$JOB_ID.log -e $glob_workdir/$h/$JOB_ID.log  

        done
done


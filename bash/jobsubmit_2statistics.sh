source globalvar.sh
# [peaklist.tsv] [metadata.tsv] [outputdirectory] [compound_pattern] [compare] [clean_pattern] [reverse_pattern] [settingsfile] 
for h in $glob_mode
do
	CLASSFILE=$glob_filedir/$h/class.csv
	CLASS=$(cat $CLASSFILE | cut -d "," -f 2 | grep "_clean" | sed 's/_clean//g')
        for i in $CLASS
	do 
		echo "
		module load Anaconda3
		source activate $glob_ENV
		Rscript $glob_Rscripts/statistics.R $glob_workdir/$h/peaklist.tsv $glob_workdir/$h/metadata.tsv $glob_workdir/$h/$i $(echo $i)_R 'NC' $(echo $i)_clean ' ' $glob_input/$h/settings_statistics.yaml  "  # |  qsub -N statistic_$h_$i  -l h_rt=00:20:00 -l h_vmem=10G -binding linear:1 # -o $glob_workdir/$h/$JOB_ID.log -e $glob_workdir/$h/$JOB_ID.log  

	done
done 

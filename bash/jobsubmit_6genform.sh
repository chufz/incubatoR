#!/bin/bash
source globalvar.sh

for h in $glob_mode
	source $glob_input/$h/parameter_genform.sh
	do
        	if [ $h = "Pos" ]; then
		ION="M+H"
        else 
                ION="M-H"
        fi	

	DD=$glob_workdir/$h/MSMS
	for j in $(ls -d $DD/*)
	do
                echo $j
        	for i in $(find $j  -iname "*.txt" | grep -v "MS1.txt")
		do
                FOLDER=$( dirname "${i}" )
		echo "genform  ms=$FOLDER/MS1.txt msms=$i ff=$(cat $glob_input/$h/$i/FF_$(echo $i).txt ) oclean=Clean_$i out=$(echo $i | sed 's/.txt$/.out/') exist analyze loss wi=sqrt ppm=$PPM acc=$ACC rej=$REJ sort=msmsmv oei"  
		done  |  qsub -S /bin/bash -l h_rt=1:00:00 -l h_vmem=6G, -binding linear:1	
	done
	done

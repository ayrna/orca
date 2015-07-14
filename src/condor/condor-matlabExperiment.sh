#!/bin/bash
#Check arguments
if [ $# != 1 ]; then
	echo "Usage:" $0 "name-of-experiment-file"
	exit 127
fi
# Get system time
DATE=`date +%F-%H.%M.%S`;

# Create a directory with date and time, and the name of the configuration file
if [ ! -d "$DATE-$1" ]; then
	mkdir $DATE-$1
fi

# Get the number of experiments and pass it later to the queue of condor-runExperiments
# For this, we iterate over the directories and count train-test pairs with diferent configuration to run
LINES=`cat $1 | grep dir -n`;
RUTAS=(`cat $1 |  grep dir --after-context=1 | grep -v dir | grep -v --regexp "--" | sed -e 's/\ //g'`)
total=0;
jR=0;
for i in $LINES
do
	ii=`echo $i | sed -e 's/:dir//g'`;
	j=`expr $ii + 4`;
	DATASETS=(`sed -n ''$ii','$j'p' $1 | grep datasets --after-context=1 | grep datasets -v | sed -e 's/\,/\n/g'`);
	for iii in `seq 1 ${#DATASETS[@]}`
	do
		iiii=`expr $iii - 1`;
		numFiles=`ls ${RUTAS[$jR]}/${DATASETS[$iiii]}/matlab/train_* -l | wc -l`;
		expresion="expr ( "$total" + "$numFiles" )";
		total=`$expresion`;
	done
	jR=`expr $jR + 1`;
done

# Copy files to keep the configuration used for the experiments
cp *.submit $DATE-$1/
# We modify some of the tags of the .dag file from the DAG template to match the current job
sed -e 's/CURRENT_DATE/'$DATE'/g' -e 's/EXEC_SCRIPT/'$1'/g' -e 's/NUM_RUNS/'$total'/g' condor-matlabFramework.dag > ./$DATE-$1/condor-matlabFramework.dag
# Send the DAG to Condor, so that Condor will manage all the process from now on
condor_submit_dag ./$DATE-$1/condor-matlabFramework.dag

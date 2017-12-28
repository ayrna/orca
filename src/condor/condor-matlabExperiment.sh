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
total=0;
jR=0;
NFILES=$(($(csplit $1 -f $1 '/\[..*\]/' {\*} | wc -l) - 1))
for i in $(seq -f "%02g" $NFILES)
do
	FILE="$1""$i"
	BASEDIR=$(cat $FILE | egrep 'basedir[ ]*=[ ]*' | sed -r -e 's/.*=[ ]*([^ ]*)/\1/g');
	DATASETS=($(cat $FILE | egrep 'datasets[ ]*=[ ]*' | sed -r -e 's/.*=[ ]*([^ ]*)/\1/g' | sed -e 's/\,/\n/g'));
	for i in `seq 1 ${#DATASETS[@]}`
	do
		ii=$(($i - 1))
		numFiles=`ls $BASEDIR/${DATASETS[$ii]}/matlab/train_* -l | wc -l`;
		expresion="expr ( "$total" + "$numFiles" )";
		total=`$expresion`;
	done
done
rm $1?*

# Copy files to keep the configuration used for the experiments
cp *.submit $DATE-$1/
# We modify some of the tags of the .dag file from the DAG template to match the current job
sed -e 's/CURRENT_DATE/'$DATE'/g' -e 's/EXEC_SCRIPT/'$1'/g' -e 's/NUM_RUNS/'$total'/g' condor-matlabFramework.dag > ./$DATE-$1/condor-matlabFramework.dag
# Send the DAG to Condor, so that Condor will manage all the process from now on
condor_submit_dag ./$DATE-$1/condor-matlabFramework.dag

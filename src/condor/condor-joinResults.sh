#!/bin/bash
#Check arguments
if [ $# != 1 ]; then
	echo "Usage:" $0 "name-of-the-directory"
	exit 127
fi

if [ -f "./Experiments/exp-$1/Results/results-$1-complete.tar.gz" ]
then
	rm "./Experiments/exp-$1/Results/results-$1-complete.tar.gz";
fi

if [ -f "./Experiments/exp-$1/Results/mean-results.csv" ]
then
	rm "./Experiments/exp-$1/Results/mean-results.csv";
fi

if [ -f "./Experiments/exp-$1/experiments.tar.gz" ]
then
	rm "./Experiments/exp-$1/experiments.tar.gz";
fi

cmd="/usr/local/matlab/bin/matlab -nodesktop -nojvm -nodisplay -r addpath('../Utils');Utilities.results('Experiments/exp-$1/Results');quit";
$cmd;


cd ./Experiments/exp-$1/Results/
tar zcvf results-$1-complete.tar.gz */
rm -Rf ./*/
cd ../../../

cd ./Experiments/exp-$1/
tar zcvf experiments.tar.gz exp-*
rm -Rf exp-*
cd ../../

cd $1
tar zcvf errorsCreateRun.tar.gz condor-createExperiments.err condor-runExperiments-*.err
rm condor-createExperiments.err condor-runExperiments-*.err
tar zcvf outputsCreateRun.tar.gz condor-createExperiments.out condor-runExperiments-*.out
rm condor-createExperiments.out condor-runExperiments-*.out

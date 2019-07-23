#!/bin/bash
#Check arguments
if [ $# != 2 ]; then
	echo "Usage:" $0 "name-of-the-directory number-of-file-to-run"
	exit 127
fi
hostname

EXPERIMENTS=(`ls Experiments/exp-$1/exp*`);

echo "Launching ${EXPERIMENTS[$2]} configuration file (number $2)!!"

cmd="/usr/local/matlab/bin/matlab -nodesktop -nojvm -nodisplay -r addpath('../Utils');Utilities.runExperimentFold('${EXPERIMENTS[$2]}');quit";
$cmd;

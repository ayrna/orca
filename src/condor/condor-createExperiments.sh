#!/bin/bash
#Check arguments
if [ $# != 2 ]; then
	echo "Usage:" $0 "name-of-experiment-file directory"
	exit 127
fi

cmd="/usr/local/matlab/bin/matlab -nodesktop -nojvm -nodisplay -r addpath('../Utils');Utilities.configureExperiment('$1','$2');quit";
echo $cmd;
$cmd;

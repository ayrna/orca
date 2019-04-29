#!/bin/bash
## runtestssingle.m is already tested in install_octave.m and install_matlab.m
## Test notebooks
cd doc

for i in {1..3}
	jupyter nbconvert --to script orca_tutorial_$i.ipynb
	octave-cli orca_tutorial_$i.m 2> test.err
	status=$?
	if [ $status -eq 0 ]
	then
	  echo "Test notebook $i OK"
	else
	  echo "Test notebook $i ERROR!" 
	  exit $status
	fi

	# Since octave error codes returned to the OS are unstable we also look 
	# for errors in sterr
	n_errors=$( grep error test.err | wc -l )
	echo $n_errors
	if [ $n_errors -eq 0 ]
	then
	  echo "Test notebook $i OK in logs"
	else
	  echo "Test notebook $i ERROR in logs!" 
	  exit $n_errors
	fi
do

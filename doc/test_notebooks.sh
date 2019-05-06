#!/bin/bash
## runtests_single.m is already tested in install_octave.m and install_matlab.m
## Test notebooks

FILES=*.ipynb
let i=1

for file in $FILES
do
	name=`echo "$file" | cut -d'.' -f1`
	jupyter nbconvert --to script $name.ipynb
	octave-cli $name.m 2> test.err
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
	  echo "Contents of stderr"
	  echo "------------------"
	  cat test.err
	  echo "------------------"
	  exit $n_errors
	fi
	
	((i++))
done

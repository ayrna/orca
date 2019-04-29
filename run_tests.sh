#!/bin/bash
## Run singletests
cd src
octave-cli runtestssingle.m 2> test.err
status=$?
if [ $status -eq 0 ]
then
  echo "Test simple OK"
else
  echo "Test simple ERROR!" 
  exit $status
fi

# Since octave error codes returned to the OS are unstable we also look 
# for errors in sterr
n_errors=$( grep error test.err | wc -l )
echo $n_errors
if [ $n_errors -eq 0 ]
then
  echo "Test simple OK in logs"
else
  echo "Test simple ERROR in logs!" 
  exit $status
fi

## Test notebooks
cd ../doc

# Test notebook 1
jupyter nbconvert --to script orca_tutorial_1.ipynb
octave-cli orca_tutorial_1.m 2> test.err
status=$?
if [ $status -eq 0 ]
then
  echo "Test notebook 1 OK"
else
  echo "Test notebook 1 ERROR!" 
  exit $status
fi

n_errors=$( grep error test.err | wc -l )
echo $n_errors
if [ $n_errors -eq 0 ]
then
  echo "Test notebook 1 OK in logs"
else
  echo "Test notebook 1 ERROR in logs!" 
  exit $status
fi

# Test notebook 2
jupyter nbconvert --to script orca_tutorial_2.ipynb
octave-cli orca_tutorial_2.m 2> test.err
status=$?
if [ $status -eq 0 ]
then
  echo "Test notebook 2 OK"
else
  echo "Test notebook 2 ERROR!" 
  exit $status
fi

n_errors=$( grep error test.err | wc -l )
echo $n_errors
if [ $n_errors -eq 0 ]
then
  echo "Test notebook 2 OK in logs"
else
  echo "Test notebook 2 ERROR in logs!" 
  exit $status
fi

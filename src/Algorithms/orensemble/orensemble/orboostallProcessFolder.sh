#!/bin/bash

#Check arguments
if [ $# != 1 ]; then
	echo "Usage:" $0 "/path/to/datasets/"
	exit 127
fi

if [ ! -e "./results/" ]       # Check if the fold exists.
then
	mkdir ./results/
fi

# Get datasets
INPUT=$1
DATASETS=$(ls $INPUT)


for i in $DATASETS; do
	if [ ! -e "./results/$i/" ]       # Check if the fold exists.
	then
		mkdir ./results/$i/
	fi

	echo "Processing $i data set"

	command="cd ./results/$i/"
	$command

	command="cp ../../boostrank-train ./"
	$command

	command="cp ../../boostrank-predict ./"
	$command
	
	FILES=$(ls $INPUT/$i/gpor/train_*.*)
	for j in $FILES; do
		train=${j#"$INPUT/$i/gpor/"}
		test=${train/train/test}
		if [ ! -e "./$train.model" ]       # Check if the fold exists.
		then
			echo "Processing $j train file"
			# Copy train and test files
			command="cp $j ./"
			$command
			jj=${j/train/test}
			command="cp $jj ./"
			$command

			n=`awk '{print NF}' $train | sort -nu | tail -n 1`
			INPUTS=$(($n - 1))
			PATTERNS=`cat $train | wc -l`
			CLASSES=`awk 'BEGIN {max = 0} {if ($'$n'>max) max=$'$n'} END {print max}' $train`
			
			command="./boostrank-train $train $PATTERNS $INPUTS 40 204 $CLASSES 2000 $train.model"
			echo $command
			$command >> res_$i.txt

			PATTERNS=`cat $test | wc -l`
			command="./boostrank-predict $test $PATTERNS $INPUTS $train.model 2000 $test.predict"
			echo $command
			$command >> res_$i.txt

			command="rm $train $test"
			$command
		fi
	done

	command="rm boostrank-train"
	$command

	command="rm boostrank-predict"
	$command
	
	command="cd ../../"
	$command
done


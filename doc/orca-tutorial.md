![ORCA logo](orca_small.png)

# How to use ORCA

ORCA is a framework focused on productivity. The two main objectives of the framework are: 

1. To run many experiments as easily as possible to compare **many algorithms** and **many datasets**.
2. To provide an easy way of including new algorithms into the framework by simply defining the parameters of the algorithms and the training and test methods.

ORCA has been developed and tested in GNU/Linux systems. Although it may run on Windows and other proprietary operating systems, the following instructions are given for GNU/Linux.

## Download and build ORCA

To download ORCA you can simply clone this GitHub repository by using the following commands:
```bash
$ git clone https://github.com/ayrna/orca
```

All the contents of the repository can also be downloaded from the GitHub site by using the "Download ZIP" button.

ORCA is programmed in MATLAB, but many of the classification algorithms are implemented in C/C++. Because of this, these methods have to be compiled and/or packaged into the corresponding `MEX` files. Next, we provide the instructions to compile all the dependencies:

### libsvm-weights-3.12

These instructions are adapted from the corresponding README of `libsvm`. First, you should open MATLAB console and then `cd` to the directory `src/Algorithms/libsvm-weights-3.12/matlab`. After that, try to compile the `MEX` files using `make.m` (from the Matlab console):
```MATLAB
>> cd src/Algorithms/libsvm-weights-3.12/matlab
>> make
```

These commands could fail (especially for Windows) if the compiler is not correctly installed and configured. In those cases, please try `mex -setup` to choose a suitable compiler for `mex`. Make sure your compiler is accessible and workable. Then type `make` to start the installation.

On GNU/Linux systems, if neither `make.m` nor `mex -setup` works, please use `Makefile`, typing `make` in a command window. Please change MATLABDIR in Makefile to point the directory of Matlab (usually `/usr/local/matlab`).

### libsvm-rank-2.81

To compile this dependency, the instructions are similar to those of `libsvm-weights-3.12` (from the Matlab console):
```MATLAB
>> cd src/Algorithms/libsvm-rank-2.81/matlab
>> make
```

### SVOREX and SVORIM

For both algorithms, please use the `make.m` file included in them (from the Matlab console):
```MATLAB
>> cd src/Algorithms/SVOREX
>> make
>> cd ..
>> cd SVORIM
>> make
```

### orensemble

We have not prepared a proper MEX interface for ORBoost, so the binary files of this algorithm should be compiled and are then invoked directly from Matlab. For compiling the ORBoost algorithm, you should uncompress the file `orsemble.tar.gz` and compile the corresponding source code. In GNU/Linux, this can be done by (from the `bash` console):
```bash
$ cd src/Algorithms/orensemble
$ tar zxf orensemble.tar.gz
$ cd orensemble/
$ make
g++ -Ilemga-20060516/lemga -Wall -Wshadow -Wcast-qual -Wpointer-arith -Wconversion -Wredundant-decls -Wwrite-strings -Woverloaded-virtual -D NDEBUG -O3 -funroll-loops -c -o robject.o lemga-20060516/lemga/object.cpp
...
```
Then, you should move the binary files to `..` folder and clean the folder (from the `bash` console):
```bash
$ mv boostrank-predict ../
$ mv boostrank-train ../
$ cd ..
$ rm -Rf orensemble
```
## Experiments configuration

ORCA experiments are specified in configuration files, which run an algorithm (or many algorithms) for a collections of datasets (each dataset with a given number of partitions). The folder [src/config-files](src/config-files) contains example configuration files for running all the algorithms included in ORCA for all the algorithms and datasets of the [review paper](http://www.uco.es/grupos/ayrna/orreview). The following code is an example for running the Proportion Odds Model (POM), a.k.a. Ordinal Logistic Regression:

```
new experiment
name
pom-real
dir
datasets/ordinal/real/30-holdout
datasets
automobile,balance-scale,bondrate,car,contact-lenses,ERA,ESL,eucalyptus,LEV,marketing,newthyroid,pasture,squash-stored,squash-unstored,SWD,tae,thyroid,toy,winequality-red,winequality-white
algorithm
POM
standarize
1
end experiment
```

The above file tells ORCA to run the algorithm `POM` for all the datasets specified in the list `datasets`. Each of these datasets should be found at folder *dir*, in such a way that ORCA expects one subfolder for each dataset, where the name of the subfolder must match the name of the dataset. The *standarize* flag activates the standardization of the data (by using the mean and standard deviation of the train set). Directive *name* is used as and identifier for the experiment set.

## Launch experiments

Assuming you are on the 'src' folder, to launch the bundle of experiments open MATLAB's console and run:

```MATLAB
Utilities.runExperiments('config-files/pom')
```

This should produce and output like this:

```MATLAB
Setting up experiments...
Running experiment exp-pom-real1-ERA-1
Processing Experiments/exp-2015-7-14-9-31-27/exp-pom-real1-ERA-1
Running experiment exp-pom-real1-ERA-10
Processing Experiments/exp-2015-7-14-9-31-27/exp-pom-real1-ERA-10
Running experiment exp-pom-real1-ERA-11
Processing Experiments/exp-2015-7-14-9-31-27/exp-pom-real1-ERA-11
Running experiment exp-pom-real1-ERA-12
Processing Experiments/exp-2015-7-14-9-31-27/exp-pom-real1-ERA-12
...
Calculating results...
```

As can be observed, ORCA analyses all the files included in the folder of the dataset, where the training and test partitions are included (a pair of files `train_dataset.X` and `test_dataset.X` for each dataset, where `X` is the number of partition). For each partition, a model is trained using training data and tested using test data.

After running all the experiments, all the results are generated in the `Experiments` folder, as described in the corresponding section of this tutorial.

## Hyper-parameters optimization

Many machine learning methods depends on hyper-parameters to achieve optimal results. ORCA automates hyper-parameter optimization by using a grid search with an internal nested k-fold cross-validation using only the training partition. Let's see an example for optimization of SVORIM cost parameter ('C') and kernel width parameter ('k', a.k.a *gamma*):

```
new experiment
name
svorim-mae-real
dir
datasets/ordinal/real/30-holdout
datasets
automobile,balance-scale,bondrate,car,contact-lenses,ERA,ESL,eucalyptus,LEV,marketing,newthyroid,pasture,squash-stored,squash-unstored,SWD,tae,thyroid,toy,winequality-red,winequality-white
algorithm
SVORIM
num fold
5
standarize
1
crossval
mae
parameter C
10.^(-3:1:3)
parameter k
10.^(-3:1:3)
kernel
rbf
seed
1
end experiment
```

The meaning of each directive are the following:

 - *num fold*: k value for the k-fold cross validation with the training data.
 - *crossval*: metric to select the best hyper-parameters in the grid search. Metrics available are: AMAE,CCR,GM,MAE,MMAE,MS,MZE,Spearman,Tkendall,Wkappa
 - List of hyper-parameters and set of values for the grid search:
  - *parameter C*: add a new parameter with name 'C' and set of values '10.^(-3:1:3)'.
 - Other parameters of the model depends of the specific method, here the kernel type is set up with *kernel* parameter. These are parameters that are not need to be optimized.

 - *seed*: is the value to initialize MATLAB random number generator. This is helpful to debug algorithms.

# Experimental results and reports

ORCA uses the 'Experiments' folder to store experimental results. Each report is placed in a folder named with the current date and time (for example 'exp-2015-7-14-10-5-57'). After a suscessful experiment, this folder should have the following information:

 - Experiments configuration files for each dataset and partition
 - 'Results' folder with the following information:
  - 'mean-results_train.csv' and 'mean-results_test.csv' that contains mean and standard deviation for each one of the ordinal classificacion performance metrics, and the computational time.
  - Train and test confusion matrices.
  - One folder for each dataset including the models ('Models' folder), threshold models one dimensional mapping values ('Guess' folder), labels predictions ('Predictions' folder), optimal hyper-parameters values ('OptHyperparams') and computational time results ('Times').

# Use ORCA with your own datasets

This section teach you how to use ORCA with your own datasets.

## Data format

ORCA used the common MATLAB's file format, this is one pattern per file:

```
attr1 attr2 ... attrN label
attr1 attr2 ... attrN label
attr1 attr2 ... attrN label
```

Due to some algorithms restrictions, patterns should be sorted by increasing label in the files.

## Data partitions for experiments

ORCA needs pairs of train and test files for each dataset. These pairs of files would be used to train and measure generalization performance of each algorithm. For instance, for 'toy' dataset, we have the following folder and files arrangement to perform an stratified 30-holdout:

```
toy
toy/gpor/
toy/gpor/test_toy.0
toy/gpor/train_toy.0
toy/gpor/test_toy.1
toy/gpor/train_toy.1

toy/gpor/test_toy.29
toy/gpor/train_toy.29
```

In this case ORCA will run all the train and test pairs and performance results will be used for the reports.

![ORCA logo](orca_small.png)

# How to use ORCA

ORCA is a framework focused on productivity. The two main objectives of the framework are:

1. To run many experiments as easily as possible to compare **many algorithms** and **many datasets**.
2. To provide an easy way of including new algorithms into the framework by simply defining the parameters of the algorithms and the training and test methods.

ORCA has been developed and tested in GNU/Linux systems. Although it may run on Windows and other proprietary operating systems, the following instructions are given for GNU/Linux.

## Instalation requirements

In order to use ORCA you need:

* `gcc` and `g++`
* MATLAB/Octave, including `mex`.

## Download and compile ORCA dependencies

To download ORCA you can simply clone this GitHub repository by using the following commands:
```bash
$ git clone https://github.com/ayrna/orca
```

All the contents of the repository can also be downloaded from the GitHub site by using the "Download ZIP" button.

ORCA is programmed in MATLAB, but many of the classification algorithms are implemented in C/C++. Because of this, these methods have to be compiled and/or packaged into the corresponding `MEX` files.

### Build from MATLAB/Octave console

In Windows and GNU/Linux you can build ORCA directly from MATLAB/Octave console. Just enter in `scr` directory and type `make`. Alternatively you can clean the objects files with `make clean`

```MATLAB
>> cd src/
>> make
>> make clean
```

### Build from GNU/Linux terminal

Under GNU/Linux, the simplest way to compile all the algorithms is to use the [Makefile](../src/Makefile) included in ORCA. This will compile all the algorithms and clean intermediate object files. You need to properly setup MATLABDIR variable inside [Makefile](../src/Makefile) to point out to MATLAB installation directory (for instance `MATLABDIR = /usr/local/MATLAB/R2017b`):

```bash
$ cd src/
$ make
```
To build ORCA for Octave the setup MATLABDIR to point out to Octave heather files (for instance `OCTAVEDIR = /usr/include/octave-4.0.0/octave/`) and type:
```bash
$ cd src/
$ make octave
```

### Instalation testing

We provide basic tests to test all the algorithms both using ORCA's API and experiments scripts to run experiments.

To run basic tests (running time is ~12 seconds):

```MATLAB
>> cd src/
>> runtestssingle
...
.........................
Performing test for SVORLin
Accuracy Train 0.262222, Accuracy Test 0.266667
Test accuracy matchs reference accuracy
Processing svrTest.m...
.........................
Performing test for SVR
Accuracy Train 0.995556, Accuracy Test 0.973333
Test accuracy matchs reference accuracy
All tests ended successfully
```

To run script tests (running time is ~123 seconds):

```MATLAB
>> cd src/
>> runtestscv
...
Running experiment exp-svr-real1-toy-1
Processing Experiments/exp-2017-11-16-13-59-1/exp-svr-real1-toy-1
Calculating results...
Experiments/exp-2017-11-16-13-59-1/Results/toy-svr-real1/dataset
Experiments/exp-2017-11-16-13-59-1/Results/toy-svr-real1/dataset
Test passed for svr
All tests ended successfully
```

### Fixing compilation errors

If the command fails, please edit the files `src/Algorithms/libsvm-rank-2.81/matlab/Makefile`, `src/Algorithms/libsvm-weights-3.12/matlab/Makefile`, `src/Algorithms/SVOREX/Makefile` and `src/Algorithms/SVORIM/Makefile`. Make sure that the variable `MATLABDIR` is correctly pointing to the folder of your Matlab installation (by default, `/usr/local/matlab`). You can also make a symbolic link to your current Matlab installation folder:
```bash
$ sudo ln -s /path/to/matlab /usr/local/matlab
```
The following subsections provides individual instructions for compiling each of the dependencies in case the [Makefile](../src/Algorithms/Makefile) still fails or for those which are working in other operating systems.

#### libsvm-weights-3.12

These instructions are adapted from the corresponding README of `libsvm`. First, you should open MATLAB console and then `cd` to the directory `src/Algorithms/libsvm-weights-3.12/matlab`. After that, try to compile the `MEX` files using `make.m` (from the Matlab console):
```MATLAB
>> cd src/Algorithms/libsvm-weights-3.12/matlab
>> make
```

These commands could fail (especially for Windows) if the compiler is not correctly installed and configured. In those cases, please try `mex -setup` to choose a suitable compiler for `mex`. Make sure your compiler is accessible and workable. Then type `make` to start the installation.

On GNU/Linux systems, if neither `make.m` nor `mex -setup` works, please use `Makefile`, typing `make` in a command window. Please change MATLABDIR in Makefile to point the directory of Matlab (usually `/usr/local/matlab`).

#### libsvm-rank-2.81

To compile this dependency, the instructions are similar to those of `libsvm-weights-3.12` (from the Matlab console):
```MATLAB
>> cd src/Algorithms/libsvm-rank-2.81/matlab
>> make
```

#### SVOREX and SVORIM

For both algorithms, please use the `make.m` file included in them (from the Matlab console):
```MATLAB
>> cd src/Algorithms/SVOREX
>> make
>> cd ..
>> cd SVORIM
>> make
```

#### orensemble

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

## Running ORCA algorithms from your own Matlab code

ORCA algorithms can be used from your own Matlab code. All algorithms included in the [Algorithms](../src/Algorithms) have a `runAlgorithm` method, which can be used for running the algorithms with your data. The method receives the matrix of training data, the matrix of test data and a structure with the values of the parameters associated.

For example, the KDLOR method has a total of five parameters. Two of them (the type of kernel, `kernel`, and the optimisation routine considered, `opt`) are received in the constructor of the corresponding class, and the other three parameters (cost, `C`, kernel parameter, `k`, and value to avoid singularities, `u`) are supposed to have to be fine-tuned for each dataset and partition, so they are received in a list passed to the `runAlgorithm` method. This an example of execution of KDLOR from the Matlab console:
```MATLAB
>> cd src/Algorithms/
>> addpath ..
>> kdlorAlgorithm = KDLOR('rbf','quadprog');
>> kdlorAlgorithm

kdlorAlgorithm =

  KDLOR handle

  Properties:
    optimizationMethod: 'quadprog'
       name_parameters: {'C'  'k'  'u'}
            parameters: []
            kernelType: 'rbf'
                  name: 'Kernel Discriminant Learning for Ordinal Regression'

  Methods, Events, Superclasses

>> load ../../exampledata/toy/matlab/train_toy.0
>> load ../../exampledata/toy/matlab/test_toy.0
>> train.patterns = train_toy(:,1:(size(train_toy,2)-1));
>> train.targets = train_toy(:,size(train_toy,2));
>> test.patterns = test_toy(:,1:(size(test_toy,2)-1));
>> test.targets = test_toy(:,size(test_toy,2));
>> param(1) = 10;
>> param(2) = 0.1;
>> param(3) = 0.001;
>> info = kdlorAlgorithm.runAlgorithm(train,test,param);
>> info

info =

         trainTime: 0.2834
    projectedTrain: [225x1 double]
    predictedTrain: [225x1 double]
     projectedTest: [75x1 double]
     predictedTest: [75x1 double]
          testTime: 0.0108
             model: [1x1 struct]

>> fprintf('Accuracy Train %f, Accuracy Test %f\n',sum(train.targets==info.predictedTrain)/size(train.targets,1),sum(test.targets==info.predictedTest)/size(test.targets,1));
Accuracy Train 0.871111, Accuracy Test 0.853333
```
The corresponding script ([exampleKDLOR.m](../src/tests/exampleKDLOR.m)) can found and run in the [tests](../src/tests) folder:
```MATLAB
>> exampleKDLOR
Accuracy Train 0.871111, Accuracy Test 0.853333
```
## Experiment configuration

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

After running all the experiments, all the results are generated in the `Experiments` folder, as described in the [corresponding section](orca-tutorial.md#experimental-results-and-reports) of this tutorial.

## Hyper-parameter optimization

Many machine learning methods depends on hyper-parameters to achieve optimal results. ORCA automates hyper-parameter optimization by using a grid search with an internal nested *k*-fold cross-validation considering only the training partition. Let see an example for the optimisation of the two hyper-parameters of SVORIM: cost ('C') and kernel width parameter ('k', a.k.a *gamma*):
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

The meanings of the directives associated to hyper-parameter optimisation are:

 - *num fold*: *k* value for the nested *k*-fold cross validation over the training data.
 - *crossval*: metric used to select the best hyper-parameters in the grid search. The metrics available are: `AMAE`,`CCR`,`GM`,`MAE`,`MMAE`,`MS`,`MZE`,`Spearman`,`Tkendall` and `Wkappa`.
 - List of hyper-parameters to be optimised and values considered for each parameter during the grid search:
  - *parameter C*: add a new parameter with name `C` and a set of values of `10.^(-3:1:3)` (10<sup>-3</sup>,10<sup>-2</sup>,...,10<sup>3</sup>).
 - Other parameters of the model depends on the specific algorithm (and they should be checked in the documentation of the algorithm). Here the kernel type is set up with *kernel* parameter. These are parameters that will not be optimized.
 - *seed*: is the value to initialize MATLAB random number generator. This can be helpful to debug algorithms.

# Experimental results and reports

ORCA uses the `Experiments` folder to store all the results of the different experiments run. Each report is placed in a subfolder of `Experiments` named with the current date, time and the name of the configuration file (for example 'exp-2015-7-14-10-5-57-pom'). After a successful experiment, this folder should contain the following information:
 - Individual experiment configuration files for each dataset and partition.
 - A `Results` folder with the following information:
  - `mean-results_train.csv` and `mean-results_test.csv` which are reports in CSV format (easily read by Excel or LibreOffice Calc). They contain the mean and standard deviation for each performance measure (`AMAE`,`CCR`,`GM`,`MAE`,`MMAE`,`MS`,`MZE`,`Spearman`,`Tkendall` and `Wkappa`) and the computational time. These averages and standard deviations are obtained for all the partitions of each algorithm and dataset. `mean-results_matrices_sum_train.csv` and `mean-results_matrices_sum_test.csv` present the same metrics results, but these results are calculated with the sum of confusion matrices for train and generalization sets. This is useful for metrics such as `GM`, `MS` and `MMAE`, however these performance results may be considered a `k`-fold experiments setup in which there are `k` generalization sets without patterns repetitions.
 - The `Results` folder contains one subfolder for each dataset with the following data:
  - Train and test confusion matrices (`matrices.txt`).
  - Name of the folder used for the experiments (`dataset`).
  - Individual results for each of the partitions in CSV format (`results.csv`).
  - Models of each partition in `.mat` format (`Models` folder).
  - For threshold models, the one dimensional mapping (before applying the discretisation based on the thresholds) for training and test datasets ('Guess' folder).
  - Labels predicted by the models for each partition ('Predictions' folder).
  - Optimal hyper-parameters values obtained after nested cross-validation ('OptHyperparams').
  - Computational time results ('Times').

# Using ORCA with your own datasets

This section shows how to use ORCA with custom datasets.

## Data format

ORCA uses the default text file format for MATLAB. This is, one pattern per row with the following structure:
```
attr1 attr2 ... attrN label
attr1 attr2 ... attrN label
attr1 attr2 ... attrN label
```
ORCA is intended to be used for ordinal regression problems, so the labels should be integer numbers: `1` for the first class in the ordinal scale, `2` for the second one, ..., `Q` for the last one, where `Q` is the number of classes of the problem.

## Data partitions for the experiments

The datasets should be partitioned before applying the ORCA algorithms, i.e. ORCA needs all the pairs of training and test files for each dataset. These pairs of files would be used to train and measure generalization performance of each algorithm. For instance, for the `toy` dataset, we have the following folder and file arrangement to perform `30` times a stratified holdout validation:
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
ORCA will train a model for all the training/test pairs, and the performance results will be used for the reports. The website of the review paper associated to ORCA includes the [partitions](http://www.uco.es/grupos/ayrna/ucobigfiles/datasets-orreview.zip) for all the datasets considered in the experimental part.

## Warning about highly imbalanced datasets

ORCA is an tool to automate experiments for algorithm comparison. The default experimental setup is a n-hold-out (n=10). However, if your dataset has only less than 10-15 patterns in one or more classes, it is very likely that there will not be enough data to do the corresponding partitions, so there will be folds with varying number of classes. This can cause some errors since the confusion matrices dimensions do not agree.

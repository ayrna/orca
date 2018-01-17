![ORCA logo](orca_small.png)

# How to use ORCA

ORCA is a framework focused on productivity. The two main objectives of the framework are:

1. To run many experiments as easily as possible to compare **many algorithms** and **many datasets**.
2. To provide an easy way of including new algorithms into the framework by simply defining the parameters of the algorithms and the training and test methods.

ORCA has been developed and tested in GNU/Linux systems. Although it may run on Windows and other proprietary operating systems, the following instructions are given for GNU/Linux.

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

ORCA experiments are specified in configuration INI files, which run an algorithm for a collections of datasets (each dataset with a given number of partitions). The folder [src/config-files](src/config-files) contains example configuration files for running all the algorithms included in ORCA for all the algorithms and datasets of the [review paper](http://www.uco.es/grupos/ayrna/orreview). The following code is an example for running the Proportion Odds Model (POM), a.k.a. Ordinal Logistic Regression:
```INI
; Experiment ID
[pom-real]
{general-conf}
seed = 1
; Datasets path
basedir = ../../../datasets/ordinal/real/30-holdout
; Datasets to process (comma separated list or 'all' to process all)
datasets = automobile,balance-scale,bondrate,car,contact-lenses,ERA,ESL,eucalyptus,LEV,marketing,newthyroid,pasture,squash-stored,squash-unstored,SWD,tae,thyroid,toy,winequality-red,winequality-white
; Activate data standardization
standarize = true

; Method: algorithm and parameter
{algorithm-parameters}
algorithm = POM
```

**Subsections** help to organize the file and are mandatory:
 - `{general-conf}`: generic parts of the file.
 - `{algorithm-parameters}`: algorithms and parameters selection.
 - `{algorithm-hyper-parameters-to-cv}`: algorithms' hyper-parameters to optimise (see [Hyper-parameter optimization](orca-tutorial.md#hyper-parameter-optimization)).

The above file tells ORCA to run the algorithm `POM` for all the datasets specified in the list `datasets` (`datasets = all` processes all the datasets in `basedir`). Each of these datasets should be found at folder `basedir`, in such a way that ORCA expects one subfolder for each dataset, where the name of the subfolder must match the name of the dataset. Other directives are:

 - INI section `[pom-real]` sets the experiment identifier.
 - The `standarize` flag activates the standardization of the data (by using the mean and standard deviation of the train set).
 - Other parameters of the model depends on the specific algorithm (and they should be checked in the documentation of the algorithm). For instance, the kernel type is set up with `kernel` parameter.


## Launch experiments

Assuming you are on the 'src' folder, to launch the bundle of experiments open MATLAB's console and run:

```MATLAB
Utilities.runExperiments('config-files/pom.ini')
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
```ini
# Experiment ID
[svorim-mae-real]
{general-conf}
seed = 1
# Datasets path
basedir = datasets/ordinal/real/30-holdout
# Datasets to process (comma separated list)
datasets = all
# Activate data standardization
standarize = true
# Number of folds for the parameters optimization
num_folds = 5
# Crossvalidation metric
cvmetric = mae

# Method: algorithm and parameter
{algorithm-parameters}
algorithm = SVORIM
kernel = rbf

# Method's hyper-parameter values to optimize
{algorithm-hyper-parameters-to-cv}
c = 10.^(-3:1:3)
k = 10.^(-3:1:3)
```

The meanings of the directives associated to hyper-parameter optimisation are:
 - `seed`: is the value to initialize MATLAB random number generator. This can be helpful to debug algorithms.
 - `num_folds`: *k* value for the nested *k*-fold cross validation over the training data.
 - `cvmetric`: metric used to select the best hyper-parameters in the grid search. The metrics available are: `AMAE`,`CCR`,`GM`,`MAE`,`MMAE`,`MS`,`MZE`,`Spearman`,`Tkendall` and `Wkappa`.
 - The list of hyper-parameters to be optimised and values considered for each parameter during the grid search are specified in subsection `{algorithm-hyper-parameters-to-cv}`:
  - `C`: add a new parameter with name `C` and a set of values of `10.^(-3:1:3)` (10<sup>-3</sup>,10<sup>-2</sup>,...,10<sup>3</sup>). The same apples for `k`.


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
toy/matlab/
toy/matlab/test_toy.0
toy/matlab/train_toy.0
toy/matlab/test_toy.1
toy/matlab/train_toy.1

toy/matlab/test_toy.29
toy/matlab/train_toy.29
```
ORCA will train a model for all the training/test pairs, and the performance results will be used for the reports. The website of the review paper associated to ORCA includes the [partitions](http://www.uco.es/grupos/ayrna/ucobigfiles/datasets-orreview.zip) for all the datasets considered in the experimental part.

## Warning about highly imbalanced datasets

ORCA is an tool to automate experiments for algorithm comparison. The default experimental setup is a n-hold-out (n=10). However, if your dataset has only less than 10-15 patterns in one or more classes, it is very likely that there will not be enough data to do the corresponding partitions, so there will be folds with varying number of classes. This can cause some errors since the confusion matrices dimensions do not agree.

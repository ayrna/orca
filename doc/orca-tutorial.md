![ORCA logo](orca_small.png)

# How to use ORCA

ORCA is an experimental framework focused on productivity and experiments reproducibility for machine learning researchers. Initially created to collect ordinal classification methods, it is suitable for other type of classifiers.

First of all, you should install the framework. In order to do so, please visit [ORCA Quick Install Guide](orca-quick-install,md). Note that you should be able to perform the test when the framework is successfully installed.

This tutorial uses four small datasets (`pasture`, `pyrim10`, `tae`, `toy`) contained in folder [example data](../exampledata/30-holdout). The datasets are already partitioned with a 30-holdout experimental design.

The tutorial is prepared for running the experiments in Matlab, although it should be easily adapted to Octave.

Very small datasets like the ones used in this tutorial are given to produce lot of warning messages such as:
```MATLAB
Warning: Matrix is close to singular or badly scaled. Results may be inaccurate. RCOND =
1.747151e-17.
Warning: Maximum likelihood estimation did not converge.  Iteration limit
exceeded.  You may need to merge categories to increase observed counts.
```

You can disable these messages by using the following code:
```MATLAB
warning('off','MATLAB:nearlySingularMatrix')
warning('off','stats:mnrfit:IterOrEvalLimit')
```

## Launch experiments through `ini` files

In this section, we will run several experiments to compare the performance of three methods in a set of datasets: POM (Proportional Odds Model), SVORIM (Support Vector Machines with IMplicit constrains) and SVC1V1 (SVM classifier with 1-vs-1 binary decomposition). POM is a linear ordinal model, with limited performance but with easy interpretation. SVORIM is an ordinal nonlinear model, with one of the best performance values according to several studies. SVC1V1 is the nominal counterpart of SVORIM, so that we can check the benefits of considering ordinality.

From Matlab consoles, assuming you are on the `src` folder, the set of experiments described in INI file `tutorial/pom.ini` can be run by:
```MATLAB
Utilities.runExperiments('../doc/tutorial/config-files/pom.ini')
```

The syntaxis of these files will be explained in the [next subsection](orca-tutorial.md#ini-files-sintaxis). This should produce an output like this:
```MATLAB
>> Utilities.runExperiments('../doc/tutorial/config-files/pom.ini')
Setting up experiments...

...
Running experiment exp-pom-tutorial-toy-8.ini
Running experiment exp-pom-tutorial-toy-9.ini
Calculating results...
Experiments/exp-2018-1-19-20-0-11/Results/pasture-pom-tutorial/dataset
Experiments/exp-2018-1-19-20-0-11/Results/pyrim10-pom-tutorial/dataset
Experiments/exp-2018-1-19-20-0-11/Results/tae-pom-tutorial/dataset
Experiments/exp-2018-1-19-20-0-11/Results/toy-pom-tutorial/dataset
Experiments/exp-2018-1-19-20-0-11/Results/pasture-pom-tutorial/dataset
Experiments/exp-2018-1-19-20-0-11/Results/pyrim10-pom-tutorial/dataset
Experiments/exp-2018-1-19-20-0-11/Results/tae-pom-tutorial/dataset
Experiments/exp-2018-1-19-20-0-11/Results/toy-pom-tutorial/dataset
```

As can be observed, ORCA analyses all the files included in the folder of the dataset, where the training and test partitions are included (a pair of files `train_dataset.X` and `test_dataset.X` for each dataset, where `X` is the number of partition). For each partition, a model is trained using training data and tested using test data.

After this, you can also run the experiments for SVORIM and SVC1V1:
```MATLAB
Utilities.runExperiments('../doc/tutorial/config-files/svorim.ini')
Utilities.runExperiments('../doc/tutorial/config-files/svc1v1.ini')
```

Once the experiments are finished, the corresponding results can be found in a `Experiments` subfolder, as described in the [corresponding section](orca-tutorial.md#experimental-results-and-reports) of this tutorial.

Each experiment has a different folder, and each folder should include two CSV files with results with results similar to the following (some columns are omitted):

POM results ([download CSV](tutorial/reference-results/pom-mean-results_test.csv)):

| Dataset-Experiment | MeanMAE | StdMAE | MeanAMAE | StdAMAE | MeanTrainTime | StdTrainTime |
| --- | --- | --- | --- | --- | --- | --- |
| pasture-pom-tutorial | 0,6 | 0,230866 | 0,6 | 0,230866 | 0,070958 | 0,004822 |
| pyrim10-pom-tutorial | 1,775 | 0,522939 | 1,7825 | 0,55529 | 0,145831 | 0,060944 |
| tae-pom-tutorial | 0,615789 | 0,100766 | 0,616952 | 0,101876 | 0,324884 | 0,087447 |
| toy-pom-tutorial | 0,980889 | 0,038941 | 1,213242 | 0,059357 | 0,038949 | 0,002738 |

SVORIM results ([download CSV](tutorial/reference-results/svorim-mean-results_test.csv)):

| Dataset-Experiment | MeanMAE | StdMAE | MeanAMAE | StdAMAE | MeanTrainTime | StdTrainTime |
| --- | --- | --- | --- | --- | --- | --- |
| pasture-svorim-mae-real | 0,322222 | 0,106614 | 0,322222 | 0,106614 | 0,013843 | 0,002601 |
| pyrim10-svorim-mae-real | 1,377083 | 0,208761 | 1,375 | 0,225138 | 0,031384 | 0,022827 |
| tae-svorim-mae-real | 0,475439 | 0,069086 | 0,473291 | 0,068956 | 0,042999 | 0,023227 |
| toy-svorim-mae-real | 0,017778 | 0,012786 | 0,019631 | 0,015726 | 0,071385 | 0,025767 |

SVC1V1 results ([download CSV](tutorial/reference-results/svc1v1-mean-results_test.csv)):

| Dataset-Experiment | MeanMAE | StdMAE | MeanAMAE | StdAMAE | MeanTrainTime | StdTrainTime |
| --- | --- | --- | --- | --- | --- | --- |
| pasture-svc1v1-mae-tutorial | 0,314815 | 0,127468 | 0,314815 | 0,127468 | 0,014363 | 0,003297 |
| pyrim10-svc1v1-mae-tutorial | 1,870833 | 0,379457 | 1,85 | 0,410961 | 0,015592 | 0,003114 |
| tae-svc1v1-mae-tutorial | 0,534211 | 0,108865 | 0,533832 | 0,110083 | 0,017699 | 0,004122 |
| toy-svc1v1-mae-tutorial | 0,051556 | 0,023419 | 0,044367 | 0,022971 | 0,015869 | 0,003786 |

Finally, you can plot a bar plot to graphically compare the performance of the methods. The following code (to be run from the `src` folder) plots the figure below:
```MATLAB
pomT = readtable('../doc/tutorial/reference-results/pom-mean-results_test.csv');
svorimT = readtable('../doc/tutorial/reference-results/svorim-mean-results_test.csv');
svc1v1T = readtable('../doc/tutorial/reference-results/svc1v1-mean-results_test.csv');

c = categorical({'pasture','pyrim10-','tae','toy'});
bar(c,[pomT.MeanAMAE svorimT.MeanAMAE svc1v1T.MeanAMAE])
legend('POM', 'SVORIM', 'SVC1V1')
title('AMAE performance (smaller is better)')
```

![AMAE performance of several methods](tutorial/images/pom-vs-svorim-vs-svc1v1.png)

## `ini` files syntaxis

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

**Subsections** help to organize the file and are mandatory in the INI file:
 - `{general-conf}`: generic parts of the file.
 - `{algorithm-parameters}`: algorithms and parameters selection.
 - `{algorithm-hyper-parameters-to-cv}`: algorithms' hyper-parameters to optimise (see [Hyper-parameter optimization](orca-tutorial.md#hyper-parameter-optimization)).

The above file tells ORCA to run the algorithm `POM` for all the datasets specified in the list `datasets` (`datasets = all` processes all the datasets in `basedir`). Each of these datasets should be found at folder `basedir`, in such a way that ORCA expects one subfolder for each dataset, where the name of the subfolder must match the name of the dataset. Other directives are:

 - INI section `[pom-real]` sets the experiment identifier.
 - The `standarize` flag activates the standardization of the data (by using the mean and standard deviation of the train set).
 - Other parameters of the model depends on the specific algorithm (and they should be checked in the documentation of the algorithm). For instance, the kernel type is set up with `kernel` parameter.

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


## Experimental results and reports

ORCA uses the `Experiments` folder to store all the results of the different experiments run. Each report is placed in a subfolder of `Experiments` named with the current date, time and the name of the configuration file (for example 'exp-2015-7-14-10-5-57-pom'). After a successful experiment, this folder should contain the following information:
 - Individual experiment configuration files for each dataset and partition.
 - A `Results` folder with the following information:
  - `mean-results_train.csv` and `mean-results_test.csv` which are reports in CSV format (easily read by Excel or LibreOffice Calc). They contain the mean and standard deviation for each performance measure (`AMAE`,`CCR`,`GM`,`MAE`,`MMAE`,`MS`,`MZE`,`Spearman`,`Tkendall` and `Wkappa`) and the computational time. These averages and standard deviations are obtained for all the partitions of each algorithm and dataset.
 - The `Results` folder contains one subfolder for each dataset with the following data:
  - Train and test confusion matrices (`matrices.txt`).
  - Name of the folder used for the experiments (`dataset`).
  - Individual results for each of the partitions in CSV format (`results.csv`).
  - Models of each partition in `.mat` format (`Models` folder).
  - For threshold models, the one dimensional mapping (before applying the discretisation based on the thresholds) for training and test datasets ('Guess' folder).
  - Labels predicted by the models for each partition ('Predictions' folder).
  - Optimal hyper-parameters values obtained after nested cross-validation ('OptHyperparams').
  - Computational time results ('Times').


## Running algorithms with ORCA API

### Run a pair of train-test files with runAlgorithm

ORCA algorithms can be used from your own Matlab code. All algorithms included in the [Algorithms](../src/Algorithms) have a `runAlgorithm` method, which can be used for running the algorithms with your data. The method receives a structure with the matrix of training data and labels, the equivalent for test data and a structure with the values of the parameters associated to the method. With respect to other tools, parameters are a mandatory argument for method to avoid the use of default values.

For example, the [KDLOR](../src/Algorithms/KDLOR.m)  method has a total of five parameters. Two of them (the type of kernel, `kernelType`, and the optimisation routine considered, `optimizationMethod`) are received in the constructor of the corresponding class, and the other three parameters (cost, `C`, kernel parameter, `k`, and value to avoid singularities, `u`) are supposed to have to be fine-tuned for each dataset and partition, so they are received in a structure passed to the `runAlgorithm` method. This an example of execution of KDLOR from the Matlab console:
```MATLAB
>> cd src/
>> addpath Algorithms/
>> kdlorAlgorithm = KDLOR('kernelType','rbf','optimizationMethod','quadprog');
>> kdlorAlgorithm

kdlorAlgorithm =

  KDLOR with properties:

    optimizationMethod: 'quadprog'
            parameters: [1×1 struct]
            kernelType: 'rbf'
                  name: 'Kernel Discriminant Learning for Ordinal Regression'

>> load ../exampledata/1-holdout/toy/matlab/train_toy.0
>> load ../exampledata/1-holdout/toy/matlab/test_toy.0
>> train.patterns = train_toy(:,1:(size(train_toy,2)-1));
>> train.targets = train_toy(:,size(train_toy,2));
>> test.patterns = test_toy(:,1:(size(test_toy,2)-1));
>> test.targets = test_toy(:,size(test_toy,2));
>> param.C = 10;
>> param.k = 0.1;
>> param.u = 0.001;
>> info = kdlorAlgorithm.runAlgorithm(train,test,param);
>> info

info =

  struct with fields:

    projectedTrain: [1×225 double]
    predictedTrain: [225×1 double]
         trainTime: 0.3154
     projectedTest: [1×75 double]
     predictedTest: [75×1 double]
          testTime: 0.0013
             model: [1×1 struct]

>> fprintf('Accuracy Train %f, Accuracy Test %f\n',sum(train.targets==info.predictedTrain)/size(train.targets,1),sum(test.targets==info.predictedTest)/size(test.targets,1));
Accuracy Train 0.871111, Accuracy Test 0.853333
```
The corresponding script ([exampleKDLOR.m](../src/code-examples/exampleKDLOR.m)) can found and run in the [code example](../src/code-examples) folder:
```MATLAB
>> exampleKDLOR
Accuracy Train 0.871111, Accuracy Test 0.853333
```

### Using performance metrics

Ordinal classification problems are evaluated with specific metrics that consider the magnitude of the prediction errors in different ways. ORCA collect a set of these metrics in [Measures](../src/Measures) folder. Given the previous example, we can calculate different performance metrics with the actual and predictel labels:

```MATLAB
>> CCR.calculateMetric(test.targets,info.predictedTest)
ans =
    0.8533
>> MAE.calculateMetric(test.targets,info.predictedTest)
ans =
    0.1467
>> AMAE.calculateMetric(test.targets,info.predictedTest)
ans =
    0.1080
>> Wkappa.calculateMetric(test.targets,info.predictedTest)
ans =
    0.8854
```

The same results can be optained using the confusion matrix:

```MATLAB
>> cm = confusionmat(test.targets,info.predictedTest)
cm =
     9     0     0     0     0
     1    14     7     0     0
     0     0    20     0     0
     0     0     3    14     0
     0     0     0     0     7
>> CCR.calculateMetric(cm)
ans =
    0.8533
>> MAE.calculateMetric(cm)
ans =
    0.1467
>> AMAE.calculateMetric(cm)
ans =
    0.1080
>> Wkappa.calculateMetric(cm)
ans =
    0.8854
```

### Visualizing projections

Many ordinal regression methods belong to the category of threshold methods, which briefly means that models project the patterns into a one-dimensional latent space. We can visualize this projection and thresholds in the following way to observe the effect of the kernel width parameter starting from the previous example:

```MATLAB
figure; hold on;
info1 = kdlorAlgorithm.runAlgorithm(train,test,param);
h1 = histogram(info1.projectedTest,30);
param.k = 10;
info2 = kdlorAlgorithm.runAlgorithm(train,test,param);
h2 = histogram(info2.projectedTest,30);
legend('KDLOR k=0.1','KDLOR k=10', 'Location','NorthWest')
hold off;
```
![Histogram of KDLOR projections](tutorial/images/kdlor-projection-hist.png)

Now, you can compare performance using AMAE:

```MATLAB
>> amae1 = AMAE.calculateMetric(test.targets,info1.predictedTest)
amae1 =
    0.1080
>> amae2 = AMAE.calculateMetric(test.targets,info2.predictedTest)
amae2 =
    0.0817
```

The whole example is available at [exampleProjections.m](../code-examples/exampleProjections.m).

### Visualizing projections and decision thresholds

The `model` structure stores decision thresholds in the field thresholds. Starting from the previous example:

```MATLAB
% Run algorithm
info1 = kdlorAlgorithm.runAlgorithm(train,test,param);
amaeTest1 = AMAE.calculateMetric(test.targets,info1.predictedTest);
% Build legend text
msg{1} = sprintf('KDLOR k=%f. AMAE=%f', param.k, amaeTest1);
msg{2} = 'Thresholds';

figure; hold on;
h1 = histogram(info1.projectedTest,30);
plot(info1.model.thresholds, ...
    zeros(length(info1.model.thresholds),1),...
    'r+', 'MarkerSize', 10)
legend(msg)
legend('Location','NorthWest')
hold off;
```

![Histogram of KDLOR projections](tutorial/images/kdlor-projection-hist-thresholds.png)

The whole example is available at [exampleProjections.m](../code-examples/exampleProjectionsThresholds.m).


## Using ORCA with your own datasets

This section shows how to use ORCA with custom datasets.

### Data format

ORCA uses the default text file format for MATLAB. This is, one pattern per row with the following structure:
```
attr1 attr2 ... attrN label
attr1 attr2 ... attrN label
attr1 attr2 ... attrN label
```
ORCA is intended to be used for ordinal regression problems, so the labels should be integer numbers: `1` for the first class in the ordinal scale, `2` for the second one, ..., `Q` for the last one, where `Q` is the number of classes of the problem.

### Data partitions for the experiments

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

### Warning about highly imbalanced datasets

ORCA is an tool to automate experiments for algorithm comparison. The default experimental setup is a n-hold-out (n=10). However, if your dataset has only less than 10-15 patterns in one or more classes, it is very likely that there will not be enough data to do the corresponding partitions, so there will be folds with varying number of classes. This can cause some errors since the confusion matrices dimensions do not agree.

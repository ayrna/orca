![ORCA logo](orca_small.png)

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:0 orderedList:0 -->

- [How to use ORCA](#how-to-use-orca)
	- [Launch experiments through `ini` files](#launch-experiments-through-ini-files)
		- [Syntax of `ini` files](#syntax-of-ini-files)
		- [Hyper-parameter optimization](#hyper-parameter-optimization)
		- [Experimental results and reports](#experimental-results-and-reports)
	- [Running algorithms with ORCA API](#running-algorithms-with-orca-api)
		- [Run a pair of train-test files with runAlgorithm](#run-a-pair-of-train-test-files-with-runalgorithm)
		- [Using performance metrics](#using-performance-metrics)
		- [Visualizing projections](#visualizing-projections)
		- [Visualizing projections and decision thresholds](#visualizing-projections-and-decision-thresholds)
	- [Using ORCA with your own datasets](#using-orca-with-your-own-datasets)
		- [Data format](#data-format)
		- [Data partitions for the experiments](#data-partitions-for-the-experiments)
		- [Generating your own partitions](#generating-your-own-partitions)
		- [Warning about highly imbalanced datasets](#warning-about-highly-imbalanced-datasets)
<!-- /TOC -->

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

From Matlab console, assuming you are on the `src` folder, the set of experiments described in INI file `../doc/tutorial/config-files/pom.ini` can be run by:
```MATLAB
Utilities.runExperiments('../doc/tutorial/config-files/pom.ini')
```
The syntax of these files will be explained in the [next subsection](orca-tutorial.md#syntax-of-ini-files). This should produce an output like this:
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

---

***Exercise 1***: apparently, POM is the slowest method, but here we are not taking into account the crossvalidation time. Check the detailed CSV results to conclude which is the costliest method (taking crossvalidation, training and test phases into account).

---

Finally, you can plot a bar plot to graphically compare the performance of the methods. Let analyse the `toy` dataset. This is a synthetic dataset proposed by Herbrich et al. in their paper "Support vector learning for ordinal regression" (1997):
![Synthetic toy dataset](tutorial/images/toy.png)

The following code (to be run from the `src` folder) plots the figure below:
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

---

***Exercise 2***: you should repeat this barplots but considering:
- One `global` (i.e. a metric where the class a priori probability is not considered) **nominal** metric.
- One `global` **ordinal** metric.
- One **nominal** metric specifically designed for imbalanced datasets.
- One **ordinal** metric specifically designed for imbalanced datasets.

---

### Syntax of `ini` files

ORCA experiments are specified in configuration `ini` files, which run an algorithm for a collections of datasets (each dataset with a given number of partitions). The folder [src/config-files](src/config-files) contains example configuration files for running all the algorithms included in ORCA for all the algorithms and datasets of the [review paper](http://www.uco.es/grupos/ayrna/orreview). The following code is an example for running the Proportion Odds Model (POM), a.k.a. Ordinal Logistic Regression. Note that the execution of this `ini` file can take several hours:
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

`ini` files include **Subsections** to help organize the configuration. These sections are mandatory:
 - `{general-conf}`: generic parameters of the experiment, including the seed considered for random number generation, the directory containing the datasets, the datasets to be processed... All the parameters included here are the same for all the algorithms.
 - `{algorithm-parameters}`: here you can specify the algorithm to run and those parameters which are going to be fixed (not optimized through cross validation).
 - `{algorithm-hyper-parameters-to-cv}`: algorithms' hyper-parameters to optimise. For more details, see [Hyper-parameter optimization](orca-tutorial.md#hyper-parameter-optimization).

The above file tells ORCA to run the algorithm `POM` for all the datasets specified in the list `datasets`. You can also use `datasets = all` to process all the datasets in `basedir`). Each of these datasets should be found at folder `basedir`, in such a way that ORCA expects one subfolder for each dataset, where the name of the subfolder must match the name of the dataset. Other directives are:
 - INI section `[pom-real]` sets the experiment identifier.
 - The `standarize` flag activates the standardization of the data (by using the mean and standard deviation of the train set).
 - Other parameters of the model depends on the specific algorithm (and they should be checked in the documentation of the algorithm). For instance, the kernel type is set up with `kernel` parameter.

### Hyper-parameter optimization

Many machine learning methods are very sensitive to the value considered for the hyper-parameters (consider, for example, support vector machines and the two associated parameters, cost and kernel width). They depend on hyper-parameters to achieve optimal results. ORCA automates hyper-parameter optimization by using a grid search with an internal nested *k*-fold cross-validation considering only the training partition. Let see an example for the optimisation of the two hyper-parameters of SVORIM: cost (`C`) and kernel width parameter (`k`, a.k.a. *gamma*):
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

The directive for configuring the search process are included in the general section. The directives associated to hyper-parameter optimisation are:
- `seed`: is the value to initialize MATLAB random number generator. This can be helpful to debug algorithms.
- `num_folds`: *k* value for the nested *k*-fold cross validation over the training data.
- `cvmetric`: metric used to select the best hyper-parameters in the grid search. The metrics available are: `AMAE`,`CCR`,`GM`,`MAE`,`MMAE`,`MS`,`MZE`,`Spearman`,`Tkendall` and `Wkappa`.
- The list of hyper-parameters to be optimised and values considered for each parameter during the grid search are specified in subsection `{algorithm-hyper-parameters-to-cv}`;
    - `C`: add a new parameter with name `C` and a set of values of `10.^(-3:1:3)` (10<sup>-3</sup>,10<sup>-2</sup>,...,10<sup>3</sup>). The same apples for `k`.


### Experimental results and reports

ORCA uses the `Experiments` folder to store all the results of the different experiments. Each report is placed in a subfolder of `Experiments` named with the current date, time and the name of the configuration file (for example 'exp-2015-7-14-10-5-57-pom'). After a successful experiment, this folder should contain the following information:
 - Individual experiment configuration files for each dataset and partition.
 - A `Results` folder with the following information:
    - `mean-results_train.csv` and `mean-results_test.csv` which are the reports in CSV format (easily read by Excel or LibreOffice Calc). They contain the mean and standard deviation for each performance measure (`AMAE`,`CCR`,`GM`,`MAE`,`MMAE`,`MS`,`MZE`,`Spearman`,`Tkendall` and `Wkappa`) and the computational time. These averages and standard deviations are obtained for all the partitions of each algorithm and dataset.
    - The `Results` folder contains one subfolder for each dataset with the following data:
        - Train and test confusion matrices (`matrices.txt`).
        - Name of the folder used for the experiments (`dataset`).
        - Individual results for each partition in CSV format (`results.csv`).
        - Models of each partition in `.mat` format (`Models` folder). These models are structures and their fields depend on the specific algorithm.
        - Decision values used to obtain the predicted labels for training and test partitions ('Guess' folder). For threshold models, this is the one dimensional mapping before applying the discretisation based on the thresholds. The rest of models may have multidimensional mappings.
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
>> param

param =

    C: 10
    k: 0.1000
    u: 1.0000e-03
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

As can be checked, the methods return a structure with the main information about the execution of the algorithm. The fields of this structure are:
- `projectedTrain`: decision values for the training set.
- `predictedTrain`: labels predicted for the training set.
- `trainTime`: time in seconds needed for training the model.
- `projectedTest`: decision values for the test set.
- `predictedTest`: labels predicted for the test set.
- `testTime`: time in seconds needed for the test phase.
- `model`: structure containing the model (its coefficients, parameters, etc.). Note that, although most of the fields of this structure depend on the specific algorithm considered, we will always find the `algorithm` and `parameters` fields. These are the fields for KDLOR:
```MATLAB
>> info.model

ans =

    projection: [225x1 double]
    thresholds: [4x1 double]
    parameters: [1x1 struct]
    kernelType: 'rbf'
     algorithm: 'KDLOR'
         train: [2x225 double]
```
i.e., the algorithm used for training (`algorithm`), the weight given to each pattern in the kernel model (`projection`), the set of threshold values (`thresholds`), the parameters used for training (`parameters`), the type of kernel considered (`kernelType`) and the training data (`train`). As can be checked, at least, this structure should contain the information for performing the test phase. In this way, for KDLOR, the prediction phase needs to apply the kernel to each training point and the test point being evaluated (using `kernelType`, `train` and `parameters.K`) and perform the weighted sum of these values (using `projection`). After that, the thresholds are used to obtain the labels.

The corresponding script ([exampleKDLOR.m](../src/code-examples/exampleKDLOR.m)) can be found and run in the [code example](../src/code-examples) folder:
```MATLAB
>> exampleKDLOR
Accuracy Train 0.871111, Accuracy Test 0.853333
```

### Using performance metrics

Ordinal classification problems should be evaluated with specific metrics that consider the magnitude of the prediction errors in different ways. ORCA includes a set of these metrics in [Measures](../src/Measures) folder. Given the previous example, we can calculate different performance metrics with the actual and predicted labels:

```MATLAB
>> addpath ../Measures/
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

The same results can be obtained from the confusion matrix:

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
As can be checked, no pattern is projected in the region of the last class.

![Histogram of KDLOR projections](tutorial/images/kdlor-projection-hist-thresholds.png)

The whole example is available at [exampleProjections.m](../code-examples/exampleProjectionsThresholds.m).


## Using ORCA with your own datasets

This section shows how to use ORCA with custom datasets. First of all, you should take into account the structure of the files and then the way you should include them in the corresponding folder.

### Data format

ORCA uses the default text file format for MATLAB. This is, one pattern per row with the following structure:
```
attr1 attr2 ... attrN label
attr1 attr2 ... attrN label
attr1 attr2 ... attrN label
```
ORCA is intended to be used for ordinal regression problems, so the labels should be integer numbers: `1` for the first class in the ordinal scale, `2` for the second one, ..., `Q` for the last one, where `Q` is the number of classes of the problem. Please, take into account that all the attributes should be numeric, i.e. categorical variables needs to be transformed into several binary dummy variables before using ORCA.

### Data partitions for the experiments

The datasets should be partitioned before applying the ORCA algorithms, i.e. ORCA needs all the pairs of training and test files for each dataset. This is because, in this way, we are sure all the methods will consider the same partitions, which is very important to obtain reliable unbiased estimation of the performance and be able to perform fair comparisons. The partitions would be used to train and measure generalization performance of each algorithm.

For each dataset, ORCA will look for a subfolder called `matlab`, which will contain the training and test partitions. If the name of the dataset is `dataset`, the name of the files will be `train_dataset.X` for training partitions, and `test_dataset.X` for the test ones, where `X` is the number of partitions. This format has to be respected.

For instance, for the `toy` dataset, we have the following folder and file arrangement to perform `30` times a stratified holdout validation:
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

### Generating your own partitions

If you are using your own dataset, you will probably have to generate your own partitions. There are many options for performing the training/test partitions of a dataset, but the two most common ones are:
- `k`-fold cross-validation: in this case, the dataset is randomly divided in `k` subsets or folds. `k` training/test partitions will be considered, where, for each partition, one fold will be used for test and the remaining ones will be used for training.
- Holdout validation: in this case, the dataset is simply divided in two random subsets, one for training and the other one for test. It is quite common to use the following percentages: 75% for training and 25% for test.
- Repeated holdout validation (`h`-holdout): in order to avoid the dependence of the random partition, the holdout process is repeated a total of `h` times. A common value for `h` is 30, given that it is high enough for obtaining reliable estimations of the performance from a statistical point of view.

For classification (ordinal or nominal), both methods (`k`-fold and `h`-holdout) should be applied in a stratified way, i.e. the partitions are generated respecting the initial proportions of patterns in the original dataset. This is especially important for imbalanced datasets.

Now, we are going to generate the partitions for a given dataset. We will use the dataset ERA. This is its description:
> The ERA data set was originally gathered during an academic decision-making
> experiment aiming at determining which are the most important qualities of
> candidates for a certain type of jobs. Unlike the ESL data set (enclosed)
> which was collected from expert recruiters, this data set was collected
> during a MBA academic course.
> The input in the data set are features of a candidates such as past
> experience, verbal skills, etc., and the output is the subjective judgment of
> a decision-maker to which degree he or she tends to accept the applicant to
> the job or to reject him altogether (the lowest score means total tendency to
> reject an applicant and vice versa).

Specifically, 4 input attributes are used for evaluating each individual, and the variable to be predicted is the final judgment of the decision maker. We can load the dataset in MATLAB by using the following code:
```MATLAB
>> ERAData = table2array(readtable('../../exampledata/ERA.csv'));

>> ERAData(1:20,:)

ans =

     3     2     0    14     1
     3     3     5     9     1
     1     3    10     7     1
     0     5     7     2     1
     0    10    12     7     1
     0     5     7     2     1
     2     1     5     1     1
     0     5     7     2     1
     3     2     0    14     1
    10     7     1     6     1
     1     2    12     4     1
     2     1     5     1     1
     1     3    10     7     1
     0     5     7     2     1
     3     2     0    14     1
     1     9     4     1     1
     2     1     5     1     1
     3     2     0    14     1
     2     1     5     1     1
     5     7     3    12     1
>> targets = ERAData(:,end);
>> k=10;
>> CVO = cvpartition(targets,'KFold',k);
>> nameDataset = 'era';
>> rootDir = fullfile('..', '..', 'exampledata', '10-fold', nameDataset);
>> mkdir(rootDir);
>> rootDir = fullfile(rootDir,'matlab');
>> mkdir(rootDir);
>> for ff = 1:CVO.NumTestSets
    trIdx = CVO.training(ff);
    teIdx = CVO.test(ff);
    dlmwrite(fullfile(rootDir,sprintf('train-%s.%d',nameDataset,ff-1)),ERAData(trIdx,:),' ');
    dlmwrite(fullfile(rootDir,sprintf('test-%s.%d',nameDataset,ff-1)),ERAData(teIdx,:),' ');
end
```
This will generate all the partitions for a `10`fold crossvalidation experimental design. The source code of this example is in [exampleERAKFold.m](../src/code-examples/exampleERAKFold.m).

In order to obtain a `30`holdout design, the code will be a bit different. As MATLAB does not included a native way of repeating holdout, we will do it manually:
```Matlab
>> % Load data
ERAData = table2array(readtable('../../exampledata/ERA.csv'));
>> % Check the first 20 rows
ERAData(1:20,:)

ans =

     3     2     0    14     1
     3     3     5     9     1
     1     3    10     7     1
     0     5     7     2     1
     0    10    12     7     1
     0     5     7     2     1
     2     1     5     1     1
     0     5     7     2     1
     3     2     0    14     1
    10     7     1     6     1
     1     2    12     4     1
     2     1     5     1     1
     1     3    10     7     1
     0     5     7     2     1
     3     2     0    14     1
     1     9     4     1     1
     2     1     5     1     1
     3     2     0    14     1
     2     1     5     1     1
     5     7     3    12     1

>> % Extract targets
targets = ERAData(:,end);
>> % Generate h holdout partitions
h=30;
>> % Prepare filesystem
nameDataset = 'era';
rootDir = fullfile('..', '..', 'exampledata', '30-holdout', nameDataset);
mkdir(rootDir);
rootDir = fullfile(rootDir,'matlab');
mkdir(rootDir);
>> % For each partitions
for ff = 1:h
    CVO = cvpartition(targets,'HoldOut',0.25); % 25% of patterns for the test set
    trIdx = CVO.training(1);
    teIdx = CVO.test(1);
    dlmwrite(fullfile(rootDir,sprintf('train-%s.%d',nameDataset,ff-1)),ERAData(trIdx,:),' ');
    dlmwrite(fullfile(rootDir,sprintf('test-%s.%d',nameDataset,ff-1)),ERAData(teIdx,:),' ');
end
```
The source code of this example is in [exampleERAHHoldout.m](../src/code-examples/exampleERAHHoldout.m). As can be checked, the `cvpartition` function performs the partitions, receiving the target vector. The targets are used in order to obtain a stratified partition.

---

***Exercise 3***: you should prepare a `30holdout` set of partitions for the dataset `ESL`, which is included in the folder [exampledata](/exampledata). Try to find the description of this dataset in the Internet and spot the main differences with respect to ERA.

---

***Exercise 4***: train classifiers for both `ERA` and `ESL` datasets, using the same experimental design you used in the [experiment section](orca-tutorial.md#launch-experiments-through-ini-files). Compare the results obtained for both datasets. Generate bar plots for comparing accuracy and AMAE. Which one is better classified? Which one is better ordered?

---

### Warning about highly imbalanced datasets

ORCA is an tool to automate experiments for algorithm comparison. The default experimental setup is a n-hold-out (n=10). However, if your dataset has only less than 10-15 patterns in one or more classes, it is very likely that there will not be enough data to do the corresponding partitions, so there will be folds with varying number of classes. This can cause some errors since the confusion matrices dimensions do not agree.

![ORCA logo](orca_small.png)

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Naive approaches and decomposition methods in orca](#naive-approaches-and-decomposition-methods-in-orca)
	- [Loading the dataset and performing some preliminary experiments](#loading-the-dataset-and-performing-some-preliminary-experiments)
	- [Naive approaches](#naive-approaches)
		- [Regression (SVR)](#regression-svr)
		- [Nominal classification (SVC1V1 and SVC1VA)](#nominal-classification-svc1v1-and-svc1va)
		- [Cost sensitive classification (CSSVC)](#cost-sensitive-classification-cssvc)
		- [Summary of results for naive approaches](#summary-of-results-for-naive-approaches)
	- [Binary decomposition methods](#binary-decomposition-methods)
		- [SVM with ordered partitions (SVMOP)](#svm-with-ordered-partitions-svmop)
		- [Neural network approaches (ELMOP and NNOP)](#neural-network-approaches-elmop-and-nnop)
		- [Summary of results for binary decompositions](#summary-of-results-for-binary-decompositions)
	- [Ternary decomposition](#ternary-decomposition)

<!-- /TOC -->

# Naive approaches and decomposition methods in orca

This tutorial will cover how to apply naive approaches and decomposition methods in the framework ORCA. It is highly recommended to have previously completed the [how to tutorial](orca-tutorial.md).

We are going to test these methods using a melanoma diagnosis dataset based on dermatoscopic images. Melanoma is a type of cancer that develops from the pigment-containing cells known as melanocytes. Usually occurring on the skin, early detection and diagnosis is strongly related to survival rates. The dataset is aimed at predicting the severity of the lesion:
- A total of `100` image descriptors are used as input features, including features related to shape, colour, pigment network and texture.
- The severity is assessed in terms of melanoma thickness, measured by the Breslow index. The problem is tackled as a five-class classification problem, where the first class represents benign lesions, and the remaining four classes represent the different stages of the melanoma (0, I, II and III, where III is the thickest one and the most dangerous).

![Graphical representation of the Breslow index](tutorial/images/diagram-melanoma-stages.png)
*Graphical representation of the Breslow index (source [1])*

The dataset from [1] is included in this repository, in a specific [folder](/exampledata/10-fold/melanoma-5classes-abcd-100/matlab). The corresponding script for this tutorial, ([exampleMelanoma.m](../src/code-examples/exampleMelanoma.m)), can be found and run in the [code example](../src/code-examples).

## Loading the dataset and performing some preliminary experiments

First of all, we are going to load the dataset and examine the label for some of the patterns.
```MATLAB
>> trainMelanoma = load('../exampledata/10-fold/melanoma-5classes-abcd-100/matlab/train_melanoma-5classes-abcd-100.2');
>> testMelanoma = load('../exampledata/10-fold/melanoma-5classes-abcd-100/matlab/test_melanoma-5classes-abcd-100.2');
>> trainMelanoma([1:5 300:305],end)

ans =

     1
     1
     1
     1
     1
     2
     2
     2
     2
     2
     2
```
Although the data is prepared to perform a 10 fold experimental design, we are going to examine the properties of the whole set:
```MATLAB
>> melanoma = [trainMelanoma; testMelanoma];
```

The dataset is quite imbalanced, as you can check with this code:
```MATLAB
>> histcounts(melanoma(:,end),5)

ans =

   313    64   102    54    29
```

---

***Exercise 1***: obtain the average imbalanced ratio for this dataset, where the imbalanced ratio of each class is the sum of the number of patterns of the rest of classes divided by the number of classes times the number of patterns of the class.

---

We can apply a simple method, [POM](../src/Algorithms/POM.m) [2], to check the accuracy obtained for this dataset:
```Matlab
>> train.patterns = trainMelanoma(:,1:(end-1));
>> train.targets = trainMelanoma(:,end);
>> test.patterns = testMelanoma(:,1:(end-1));
>> test.targets = testMelanoma(:,end);
>> addpath Algorithms;
>> algorithmObj = POM();
>> info = algorithmObj.runAlgorithm(train,test);
>> addpath Measures
>> CCR.calculateMetric(info.predictedTest,test.targets)

ans =

    0.625000

>> MAE.calculateMetric(info.predictedTest,test.targets)

ans =

     0.535714
```
In the following code, we try to improve the results by considering standardization:
```Matlab
>> [trainStandarized,testStandarized] = DataSet.standarizeData(train,test)

trainStandarized =

    patterns: [506x100 double]
     targets: [506x1 double]


testStandarized =

    patterns: [56x100 double]
     targets: [56x1 double]

>> train.patterns(1:10,2:5)

ans =

   1.0e+03 *

    0.0014    0.4802    0.0007    0.0012
    0.0013    0.1085    0.0007    0.0012
    0.0014    0.7935    0.0007    0.0012
    0.0013    0.0369    0.0004    0.0011
    0.0015    0.3560    0.0003    0.0010
    0.0014    1.0862    0.0008    0.0012
    0.0014    0.0689    0.0006    0.0011
    0.0016    0.6699    0.0008    0.0014
    0.0013    0.2068    0.0008    0.0013
    0.0013    0.0126    0.0004    0.0011

>> trainStandarized.patterns(1:10,2:5)

ans =

    0.0225   -0.4632    0.2890   -0.0817
   -0.3277   -0.7576    0.0326   -0.3588
   -0.0639   -0.2150    0.4011   -0.1098
   -0.4081   -0.8143   -1.4457   -1.0444
    0.6038   -0.5615   -2.5231   -1.2014
   -0.0875    0.0168    0.6502    0.1826
   -0.0241   -0.7889   -0.2616   -0.5209
    0.9498   -0.3129    1.0035    1.2467
   -0.3708   -0.6797    0.8863    0.4503
   -0.7856   -0.8335   -1.5715   -1.0839

>> info = algorithmObj.runAlgorithm(trainStandarized,testStandarized);
>> CCR.calculateMetric(info.predictedTest,test.targets)

    ans =

             0.625000
>> MAE.calculateMetric(info.predictedTest,test.targets)

         ans =

              0.535714

```
The results have not improved in this specific case. The static method `DataSet.standarizeData(train,test)` transform the training and test datasets and return a copy where all the input variables have zero mean and unit standard deviation. There are other preprocessing methods in the `DataSet` class which delete constant input attributes or non numeric attributes:
```Matlab
>> [train,test] = DataSet.deleteConstantAtributes(train,test);
>> [train,test] = DataSet.standarizeData(train,test);
>> [train,test] = DataSet.deleteNonNumericValues(train,test);
>> info = algorithmObj.runAlgorithm(train,test);
>> CCR.calculateMetric(info.predictedTest,test.targets)

ans =

    0.625000

>> MAE.calculateMetric(info.predictedTest,test.targets)

ans =

     0.535714
```
Again, the results have not changed, as there were no attributes with these characteristics. However, in general, it is a good idea to apply standarisation of the input variables.

---

***Exercise 2***: construct a function (`preprocess.m`) applying these three preprocessing steps (standarisation, removal of constant features and removal of non numeric values) for future uses.

---

## Naive approaches

The first thing we will do is applying standard approaches for this ordinal regression dataset. This includes applying regression, classification and cost-sensitive classification.

### Regression (SVR)

One very simple way of solving an ordinal classification problem is applying regression. This is, we train a regressor to predict the number of the category (where categories are coded with real consecutive values, `1`, `2`, ..., `Q`, which are scaled between 0 and 1, `0/(Q-1)=0`, `1/(Q-1)`, ..., `(Q-1)/(Q-1)`). Then, in order to predict categories, we round the real values predicted by the regressor to the nearest integer.

ORCA includes one algorithm following this approach based on support vector machines: [Support Vector Regression (SVR)](../src/Algorithms/SVR.m). Note that SVR considers the epsilon-SVR model with an RBF kernel, involving three different parameters:
- Parameter `C`, importance given to errors.
- Parameter `k`, inverse of the width of the RBF kernel.
- Parameter `e`, epsilon. It specifies the epsilon-tube within which no penalty is associated in the training loss function with points predicted within a distance epsilon from the actual value.

We can check the performance of this model in the melanoma dataset:
```Matlab
>> algorithmObj = SVR();
info = algorithmObj.runAlgorithm(train,test,struct('C',10,'k',0.001,'e',0.01));
fprintf('\nSupport Vector Regression\n---------------\n');
fprintf('SVR Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVR MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

Support Vector Regression
---------------
SVR Accuracy: 0.678571
SVR MAE: 0.392857
```
The object info also contains the projection values, which, in this case, are the real values without being rounded:
```MATLAB
>> info.projectedTest

ans =

    0.1092
    0.2294
    0.0283
   -0.0479
    0.1216
    0.0513
    0.3135
    0.1257
    0.1051
    0.1062
    0.3625
    0.0604
   -0.1561
   -0.0522
   -0.0229
   -0.0017
   -0.1394
    0.0613
   -0.0394
    0.0612
    0.2356
   -0.0442
   -0.1126
    0.0541
   -0.0653
    0.0451
    0.0289
    0.0392
    0.0565
    0.2734
   -0.0110
    0.0468
    0.1632
    0.2537
    0.1370
    0.2247
    0.2072
    0.5004
    0.5360
    0.7742
    0.0921
    0.3459
    0.5812
    0.3463
    0.2674
    0.2362
    0.3473
    0.6035
    0.5439
    0.2840
    0.8574
    0.0812
    0.7082
    0.6549
    0.8369
    0.9076
```

As you can see, not very good performance is obtained. We can try different parameter values by using a `for` loop:
```MATLAB
>> fprintf('\nSupport Vector Regression parameters\n---------------\n');
bestAccuracy=0;
for C=10.^(-3:1:3)
   for k=10.^(-3:1:3)
       for e=10.^(-3:1:3)
           param = struct('C',C,'k',k,'e',e);
           info = algorithmObj.runAlgorithm(train,test,param);
           accuracy = CCR.calculateMetric(test.targets,info.predictedTest);
           if accuracy > bestAccuracy
               bestAccuracy = accuracy;
               bestParam = param;
           end
           fprintf('SVR C %f, k %f, e %f --> Accuracy: %f, MAE: %f\n' ...
               , C, k, e, accuracy, MAE.calculateMetric(test.targets,info.predictedTest));
       end
   end
end
fprintf('Best Results SVR C %f, k %f, e %f --> Accuracy: %f\n', bestParam.C, bestParam.k, bestParam.e, bestAccuracy);

Support Vector Regression parameters
---------------
SVR C 0.001000, k 0.001000, e 0.001000 --> Accuracy: 0.571429, MAE: 0.892857
SVR C 0.001000, k 0.001000, e 0.010000 --> Accuracy: 0.571429, MAE: 0.892857
SVR C 0.001000, k 0.001000, e 0.100000 --> Accuracy: 0.571429, MAE: 0.892857
SVR C 0.001000, k 0.001000, e 1.000000 --> Accuracy: 0.178571, MAE: 1.428571
SVR C 0.001000, k 0.001000, e 10.000000 --> Accuracy: 0.178571, MAE: 1.428571
SVR C 0.001000, k 0.001000, e 100.000000 --> Accuracy: 0.178571, MAE: 1.428571
SVR C 0.001000, k 0.001000, e 1000.000000 --> Accuracy: 0.178571, MAE: 1.428571
SVR C 0.001000, k 0.010000, e 0.001000 --> Accuracy: 0.571429, MAE: 0.892857
SVR C 0.001000, k 0.010000, e 0.010000 --> Accuracy: 0.571429, MAE: 0.892857
...
SVR C 1000.000000, k 1000.000000, e 100.000000 --> Accuracy: 0.178571, MAE: 1.428571
SVR C 1000.000000, k 1000.000000, e 1000.000000 --> Accuracy: 0.178571, MAE: 1.428571
Best Results SVR C 10.000000, k 0.001000, e 0.010000 --> Accuracy: 0.678571
```
As you can check, the best configuration leads to almost a 70% of accuracy, which is not very bad taking into account that we have 5 classes.

This way of adjusting the parameters is not fair, as we can be overfitting the specific test set. The decision of the optimal parameters should be taken without checking test results. This can be done by using nested crossvalidation.

---

***Exercise 3*** : complete the code of the script ([crossvalide.m](tutorial/scripts/crossvalide.m)) for automatising hyper-parameter selection in this problem. The idea is to have a function like this:
``` MATLAB
>> param = crossvalide(algorithmObj,train,5);
>> param

param =

    C: 0.0100
    k: 0.0100
    e: 0.0100
>> fprintf('\nSupport Vector Regression with cross validated parameters\n---------------\n');
fprintf('SVR Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVR MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

Support Vector Regression with cross validated parameters
---------------
SVR Accuracy: 0.589286
SVR MAE: 0.732143
```
Although the results are worse, we can be sure that here there is no overfitting.

---

Fortunately, this can be easily done in ORCA by using the `ini` files with the correct format. [svrMelanoma.ini](tutorial/config-files/svrMelanoma.ini) is a configuration file with the following contents:
```ini
;SVR experiments for melanoma
;
; Experiment ID
[svr-mae-tutorial-melanoma]
{general-conf}
seed = 1
; Datasets path
basedir = ../exampledata/10-fold
; Datasets to process (comma separated list or all to process all)
datasets = melanoma-5classes-abcd-100
; Activate data standardization
standarize = true
; Number of folds for the parameters optimization
num_folds = 5
; Crossvalidation metric
cvmetric = ccr

; Method: algorithm and parameter
{algorithm-parameters}
algorithm = SVR
;kernelType = rbf

; Method's hyper-parameter values to optimize
{algorithm-hyper-parameters-to-cv}
C = 10.^(-2:1:2)
k = 10.^(-2:1:2)
e = 10.^(-3:1:0)
```
In this way, we will obtain the results for the 10 partitions. This `ini` file can be run by using the following code (to be run from the `src` folder):
```MATLAB
>> Utilities.runExperiments('../doc/tutorial/config-files/svrMelanoma.ini')
Setting up experiments...
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-1.ini
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-10.ini
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-2.ini
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-3.ini
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-4.ini
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-5.ini
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-6.ini
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-7.ini
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-8.ini
Running experiment exp-svr-mae-tutorial-melanoma-melanoma-5classes-abcd-100-9.ini
Calculating results...
Experiments/exp-2018-1-20-17-38-22/Results/melanoma-5classes-abcd-100-svr-mae-tutorial-melanoma/dataset
Experiments/exp-2018-1-20-17-38-22/Results/melanoma-5classes-abcd-100-svr-mae-tutorial-melanoma/dataset

ans =

Experiments/exp-2018-1-20-17-38-22
```

Note that the number of experiments is quite important, so that the execution can take a lot. To accelerate the experiments you can use multiple cores of your CPU (see this [page](orca-parallel.md)).


### Nominal classification (SVC1V1 and SVC1VA)

We can also approach ordinal classification by considering nominal classification, i.e. by ignoring ordering information. It has been shown that this can make the classifier need more data to learn the concept.

ORCA includes two approaches to perform ordinal classification by nominal classification, both based on the Support Vector Classifier:
- [One-Vs-One (SVC1V1)](../src/Algorithms/SVC1V1.m) [3], where all pairs of classes are compared in different binary SVCs. The prediction is based on majority voting.
- [One-Vs-All (SVC1VA)](../src/Algorithms/SVC1VA.m) [3], where each class is compared against the rest. The class predicted is that with the largest decision function value.

Both methods consider an RBF kernel with the following two parameters:
- Parameter `C`, importance given to errors.
- Parameter `k`, inverse of the width of the RBF kernel.

Now, we run the SVC1V1 method:
```MATLAB
>> algorithmObj = SVC1V1();
info = algorithmObj.runAlgorithm(train,test,struct('C',10,'k',0.001));
fprintf('\nSVC1V1\n---------------\n');
fprintf('SVC1V1 Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVC1V1 MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

SVC1V1
---------------
SVC1V1 Accuracy: 0.678571
SVC1V1 MAE: 0.517857
```
In SVC1V1, the decision values has `(Q(Q-1))/2` (the number of combinations of two classes from the set of `Q` possibilities) columns and majority voting is applied.
```MATLAB
>> info.projectedTest(1:10,:)

ans =

    0.9261    0.5367    1.0250    1.8303   -0.6027    0.9841    2.0166    1.1270    2.2486    2.7971
    0.7814    0.4821    0.7651    0.8992   -0.5196    0.1467    1.0538    0.8169    1.3108    1.2065
    1.5287    1.5046    1.5610    1.9358   -0.4651    0.0438    0.9445    0.1504    1.6244    2.4629
    1.6728    2.0872    2.0601    1.7022    0.4386    2.3972    2.7218    1.6865    2.0196    2.2947
    1.4008    1.6203    1.3280    1.6617    0.3078    0.6689    1.7467    0.3941    1.8720    1.8571
    1.5229    1.4526    1.7320    1.7429   -0.8167   -0.3594    0.3977    0.4028    1.2844    0.9317
    1.2554    1.1431    1.0427    1.3174   -1.1444   -0.9344   -0.1922   -0.5129    0.9161    0.9487
    1.1729    1.3795    1.4371    1.3156    0.0133    0.1799    1.1682    0.3116    1.7527    1.2552
    0.6868    0.7459    1.2144    1.1957    0.2937    1.3921    1.0541    1.0434    1.0840    1.1890
    0.5234    0.6924    0.7066    0.7415    0.1852    0.9369    1.5640    0.6698    1.0716    1.0032
```

We can also check SVC1VA:
```MATLAB
>> algorithmObj = SVC1VA();
info = algorithmObj.runAlgorithm(train,test,struct('C',10,'k',0.001));
fprintf('\nSVC1VA\n---------------\n');
fprintf('SVC1VA Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVC1VA MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

SVC1VA
---------------
SVC1VA Accuracy: 0.660714
SVC1VA MAE: 0.535714
```
Five decision values are obtained for each pattern:
```MATLAB
>> info.projectedTest(1:10,:)

ans =

    0.4625   -1.0715   -0.9085   -1.0447   -1.9266
   -0.2265   -1.0583   -1.0804   -1.0532   -1.4971
    1.1639   -1.1286   -1.3049   -1.0684   -1.5018
    1.9740   -1.1976   -1.3387   -1.2114   -1.8832
    0.8887   -1.0291   -1.2843   -0.9885   -1.7727
    1.1675   -1.1209   -1.1077   -1.1153   -1.4466
    0.6181   -1.1607   -1.2486   -0.9805   -1.1492
    0.6817   -0.8617   -1.1509   -1.0171   -1.5208
    0.2028   -0.9899   -0.9379   -1.0777   -1.5955
   -0.0512   -0.9641   -1.1984   -1.0730   -1.3010
```
In this case, SVC1V1 obtains better results.

### Cost sensitive classification (CSSVC)

This is a special case of approaching ordinal classification by nominal classifiers. We can include different misclassification costs in the optimization function, in order to penalyze more those mistakes which involve several categories in the ordinal scale. ORCA implements this methods using again SVC and specifically the SVC1VA alternative. The costs are included as weights in the patterns, in such a way that, when generating the `Q` binary problems, the patterns of the negative class are given a weight according to the absolute difference (in number of categories) between the positive class and the specific negative class.

The method is called [Cost Sensitive SVC (CSSVC)](../src/Algorithms/CSSVC.m) [3] and considers an RBF kernel with the following two parameters:
- Parameter `C`, importance given to errors.
- Parameter `k`, inverse of the width of the RBF kernel.

```MATLAB
>> algorithmObj = CSSVC();
info = algorithmObj.runAlgorithm(train,test,struct('C',10,'k',0.001));
fprintf('\nCSSVC\n---------------\n');
fprintf('CSSVC Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('CSSVC MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

CSSVC
---------------
CSSVC Accuracy: 0.660714
CSSVC MAE: 0.571429
```
And the structure of decision values is the same than for SVC1VA:
```MATLAB
>> info.projectedTest(1:10,:)

ans =

    0.5265   -1.0560   -0.8173   -1.1068   -2.0537
   -0.2460   -1.0671   -1.0919   -1.0690   -1.5709
    1.2720   -1.1276   -1.3638   -1.0968   -1.7707
    2.0127   -1.2108   -1.4486   -1.3483   -2.0445
    0.9971   -1.0379   -1.3398   -1.0044   -1.9323
    1.1885   -1.1183   -1.1658   -1.1901   -1.5868
    0.6074   -1.1525   -1.2662   -0.9842   -1.1079
    0.8171   -0.8598   -1.1562   -1.0893   -1.6638
    0.2353   -0.9671   -0.9448   -1.1252   -1.7739
    0.0180   -0.9739   -1.2185   -1.1168   -1.3740
```

### Summary of results for naive approaches

We can compare all the results obtained by naive methods in the third partition of the melanoma dataset:
- SVR Accuracy: 0.678571
- SVC1V1 Accuracy: 0.678571
- SVC1VA Accuracy: 0.660714
- CSSVC Accuracy: 0.660714
- SVR MAE: 0.392857
- SVC1V1 MAE: 0.517857
- SVC1VA MAE: 0.535714
- CSSVC MAE: 0.571429

In this case, SVR has definitely obtained the best results. As can be checked, SVC1V1 accuracy is quite high, but it masking a not so good MAE value.


## Binary decomposition methods

These methods decompose the original problem in several binary problems (as SVC1V1 and SVC1VA do) but they binary subproblems are organised in such a way that the ordinal structure of the targets is maintained. Specifically, patterns of two non-consecutive categories in the ordinal scale will never be included in the same class against a pattern of an intermediate category. ORCA includes three methods with this structure:
- One based on SVMs. Because of the way SVM is formulated, the binary subproblems are trained with **multiple models**.
- Two based on neural networks. The flexibility of NN training makes possible learn all binary subproblems with one **single model**.
All of them are based on an ordered partition decomposition, where the binary subproblems have the following structure:

| Class | Problem1 | Problem2 | Problem3 | Problem4 |
| --- | --- | --- | --- | --- |
| C1 | 0 | 0 | 0 | 0 |
| C2 | 1 | 0 | 0 | 0 |
| C3 | 1 | 1 | 0 | 0 |
| C4 | 1 | 1 | 1 | 0 |
| C5 | 1 | 1 | 1 | 1 |


### SVM with ordered partitions (SVMOP)

[SVMOP](../src/Algorithms/SVMOP) method is based on applying the ordered partition binary decomposition, together different weights according to the absolute distance between the class of the binary problem and the specific category being examined [4,5]. The models are trained independently and final prediction is based on the first model (in the ordinal scale) predicting a positive class. Again, the parameters of this model are:
- Parameter `C`, importance given to errors.
- Parameter `k`, inverse of the width of the RBF kernel.

The same parameter values are considered for all subproblems, although the results could be improved by considering different `C` and `k` for each subproblem (resulting in a significantly higher computational cost). Here, we can check the performance of SVMOP on the partition of melanoma we have been studying:

```MATLAB
>> algorithmObj = SVMOP();
info = algorithmObj.runAlgorithm(train,test,struct('C',10,'k',0.001));
fprintf('\nSVMOP\n---------------\n');
fprintf('SVMOP Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVMOP MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

SVMOP
---------------
SVMOP Accuracy: 0.678571
SVMOP MAE: 0.517857
```

Of course, decision values include the independent values obtained for all subproblems:
```MATLAB
>> info.projectedTest

ans =

  Columns 1 through 12

    0.3161    0.6788    0.0873    0.0213    0.1411    0.1021    0.2897    0.1883    0.4164    0.5428    0.8796    0.1691
    0.2321    0.3929    0.0826    0.0397    0.1228    0.0916    0.2082    0.1310    0.2140    0.2849    0.7380    0.1135
    0.0256    0.1160    0.0540    0.0186    0.0548    0.0441    0.1156    0.0537    0.0424    0.1020    0.0067    0.0204
    0.0055    0.0212    0.0103    0.0057    0.0074    0.0165    0.0697    0.0141    0.0095    0.0351    0.0034    0.0068
         0         0         0         0         0         0         0         0         0         0         0         0
```

### Neural network approaches (ELMOP and NNOP)

Neural networks allow solving all the binary subproblems using a single model with several output nodes. Two neural network models are considered in ORCA:
- [Extreme learning machines with ordered partitions (ELMOP)](../src/Algorithms/ELMOP.m) [6].
- [Neural network with ordered partitions (NNOP)](../src/Algorithms/NNOP.m) [7].

ELMOP model is based on ELM, which are a quite popular type of neural network. In ELMs, the hidden weights are randomly set and the output weights are analytically set. The implementation in ORCA consider the ordered partition decomposition in the output layer. The prediction phase is tackled using an exponential loss based decoding process, where the class predicted is that with the minimum exponential loss with respect to the decision values.

The algorithm can be configured using different activation functions for the hidden layer ('sig, 'sin', 'hardlim','tribas', 'radbas', 'up','rbf'/'krbf' or 'grbf'). During training, the user has to specify the following parameter in the `param` structure:
- Parameter `hiddenN`: number of hidden nodes of the model. This is a decisive parameter for avoiding overfitting.

Now, we perform a test for training ELMOP (note that ELMOP is not deterministic, this is, the results may vary among different runs of the algorithm):
```MATLAB
>> algorithmObj = ELMOP('activationFunction','sig');
info = algorithmObj.runAlgorithm(train,test,struct('hiddenN',20));
fprintf('\nELMOP\n---------------\n');
fprintf('ELMOP Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('ELMOP MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

ELMOP
---------------
ELMOP Accuracy: 0.607143
ELMOP MAE: 0.642857
```

These are the decision values for ELMOP:
```MATLAB
>> info.projectedTest

ans =

  Columns 1 through 12

    0.9896    1.0486    0.9168    0.9247    1.0403    1.0267    1.0340    1.0738    1.0198    1.0798    1.0952    1.1875
   -0.1175    0.1854   -0.6503   -1.1460    0.0094   -0.2907   -0.6847    0.2618   -0.4546   -0.4248   -0.5869   -0.4123
   -0.4277   -0.1900   -0.8463   -1.1260   -0.5096   -0.5601   -0.8069   -0.2252   -0.7395   -0.6979   -0.6891   -0.6284
   -0.7446   -0.6973   -0.7709   -1.2785   -0.7912   -0.6649   -0.9554   -0.6374   -0.9156   -0.9938   -0.9971   -1.1071
   -0.9630   -0.9493   -0.9312   -0.9969   -1.0528   -0.9400   -1.0753   -0.9589   -0.9230   -0.9160   -0.9969   -1.1435
```

---

***Exercise 4***: compare all different activation functions for ELM trying to find the most appropriate one. Check the source code of [ELMOP](../src/Algorithms/ELMOP.m) to understand the different functions.

---

The other neural network model is NNOP. In this case, a standard neural network is considered, training all its parameters (hidden and output weights). In the output layer, a standard sigmoidal function is used, and the mean squared error with respect to the ordered partition targets is used for gradient descent. The algorithm used for gradient descent is the iRProp+ algorithm.

The prediction rule is based on checking which is the first class whose output value is higher than a predefined threshold (0.5 in this case).

Three parameters have to be specified in this case:
- Parameter `hiddenN`, number of hidden neurons of the model.
- Parameter `iter`, number of iterations for gradient descent.
- Parameter `lambda`, regularization parameter in the error function (L2 regularizer), in order to avoid overfitting.

This is an example of execution of NNOP (note that results may vary among different runs):
```MATLAB
>> algorithmObj = NNOP();
info = algorithmObj.runAlgorithm(train,test,struct('hiddenN',20,'iter',500,'lambda',0.1));
fprintf('\nNNOP\n---------------\n');
fprintf('NNOP Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('NNOP MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

NNOP
---------------
NNOP Accuracy: 0.732143
NNOP MAE: 0.428571
```
and the decision values are:
```MATLAB
>> info.projectedTest

ans =

    0.8846    0.9433    0.9995    0.9998
    0.6481    0.9579    0.9547    0.9772
    0.9765    0.9770    0.9548    0.9961
    0.9942    0.9991    0.9999    0.9997
    0.8824    0.9938    0.9731    0.9982
    0.9668    0.9957    0.9955    0.9973
    0.4480    0.2875    0.7679    0.9627
    0.7560    0.9554    0.9836    0.9978
    0.7151    0.9807    0.9940    0.9727
    0.4807    0.8472    0.9446    0.9206
    0.1589    0.1477    0.9872    0.9998
    0.8633    0.9513    0.9997    0.9995
    ...
```

### Summary of results for binary decompositions

As a summary, the results obtained for the third partition of melanoma dataset are:
- SVMOP Accuracy: 0.678571
- ELMOP Accuracy: 0.607143
- NNOP Accuracy: 0.732143
- SVMOP MAE: 0.517857
- ELMOP MAE: 0.642857
- NNOP MAE: 0.428571

In this case, the best classifier is NNOP, although parameter values can be influencing these results.

## Ternary decomposition

The last method considered in the tutorial is a projection similar to One-Vs-All but generating three class subproblems, instead of binary ones. The subproblems are solved considering independent classifiers, and the prediction phase is performed under a probabilistic approach (which firstly obtain a `Q` class probability distribution for each ternary classifier and then fuse all the distributions).

The base algorithm used can be configured by the user in the constructor, but it is necessary to use a one-dimensional projection method (threshold model). The parameters of OPBE are the same than the base algorithm, all subproblems being solved using the same parameter values.

```MATLAB
>> algorithmObj = OPBE('base_algorithm','SVORIM');
info = algorithmObj.runAlgorithm(train,test,struct('C',10,'k',0.001));
fprintf('\nOPBE\n---------------\n');
fprintf('OPBE Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('OPBE MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

OPBE
---------------
OPBE Accuracy: 0.696429
OPBE MAE: 0.446429
```

In this case, the decision values only include the maximum probability after considering the weights given for each class:
```MATLAB
>> info.projectedTest

ans =

  Columns 1 through 12

    0.0071    0.0013    0.0083    0.0103    0.0081    0.0083    0.0045    0.0072    0.0054    0.0026    0.0004    0.0080

  Columns 13 through 24

    0.0086    0.0099    0.0099    0.0109    0.0084    0.0092    0.0089    0.0081    0.0006    0.0105    0.0109    0.0090
...
```

---

***Exercise 5***: in this tutorial, we have considered a total of 8 classifiers with different parameter values for one of the folds of the melanoma dataset. In this exercise, you should generalise these results over the `10` partitions and interpret the results, trying to search for the best method. Apart from the two metrics considered in the tutorial (CCR and MAE), include metrics more sensitive to minority classes (for example, MS and MMAE). Construct a table with the average of these four metrics over the 10 folds. You can use the parameter values given in this tutorial or try to tune a bit them.

---

***Exercise 6***: now you should consider cross-validation to tune hyper parameters. In order to limit the computational time, do not include too many values for each parameter and only use the three first partitions of the dataset (by deleting or moving the files for the rest of partitions). Check again the conclusions about the methods. **Hyper parameters are decisive for performance!!**

---

# References

1. J. Sánchez-Monedero, M. Pérez-Ortiz, A. Sáez, P.A. Gutiérrez, and C. Hervás-Martínez. "Partial order label decomposition approaches for melanoma diagnosis". Applied Soft Computing. Volume 64, March 2018, Pages 341-355. https://doi.org/10.1016/j.asoc.2017.11.042
1. P. McCullagh, "Regression models for ordinal data",  Journal of the Royal Statistical Society. Series B (Methodological), vol. 42, no. 2, pp. 109–142, 1980.
1. C.-W. Hsu and C.-J. Lin. "A comparison of methods for multi-class support vector machines", IEEE Transaction on Neural Networks,vol. 13, no. 2, pp. 415–425, 2002. https://doi.org/10.1109/72.991427
1. E. Frank and M. Hall, "A simple approach to ordinal classification", in Proceedings of the 12th European Conference on Machine Learning, ser. EMCL'01. London, UK: Springer-Verlag, 2001, pp. 145–156. https://doi.org/10.1007/3-540-44795-4_13
1. W. Waegeman and L. Boullart, "An ensemble of weighted support vector machines for ordinal regression", International Journal of Computer Systems Science and Engineering, vol. 3, no. 1, pp. 47–51, 2009.
1. W.-Y. Deng, Q.-H. Zheng, S. Lian, L. Chen, and X. Wang, "Ordinal extreme learning machine", Neurocomputing, vol. 74, no. 1-3, pp. 447-456, 2010.         http://dx.doi.org/10.1016/j.neucom.2010.08.022
1. J. Cheng, Z. Wang, and G. Pollastri, "A neural network  approach to ordinal regression," in Proc. IEEE Int. Joint Conf. Neural Netw. (IEEE World Congr. Comput. Intell.), 2008, pp. 1279-1284.

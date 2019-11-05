[![Build Status](https://travis-ci.org/ayrna/orca.svg?branch=master)](https://travis-ci.org/ayrna/orca)
[![LICENSE](https://img.shields.io/badge/license-Anti%20996-blue.svg)](https://github.com/996icu/996.ICU/blob/master/LICENSE)

![ORCA logo](doc/orca_small.png)
<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:1 -->

- [ORCA](#orca)
- [Cite ORCA](#cite-orca)
- [Installation, tutorials and documentation](#installation-tutorials-and-documentation)
- [Methods included](#methods-included)
  - [Ordinal regression algorithms](#ordinal-regression-algorithms)
  - [Partial order methods](#partial-order-methods)
  - [Nominal methods](#nominal-methods)
- [Performance metrics](#performance-metrics)
- [Utilities, classes and scripts](#utilities-classes-and-scripts)
- [Datasets](#datasets)
- [Experiments parallelization with HTCondor](#experiments-parallelization-with-htcondor)
- [External software](#external-software)
- [Other contributors](#other-contributors)
- [References](#references)

<!-- /TOC -->

# ORCA
ORCA (Ordinal Regression and Classification Algorithms) is a MATLAB framework that implements and integrates a wide range of ordinal regression methods and performance metrics from the paper ["Ordinal regression methods: survey and experimental study"](http://dx.doi.org/10.1109/TKDE.2015.2457911) published in *IEEE Transactions on Knowledge and Data Engineering*. ORCA also helps to accelerate classifier experimental comparison with automatic fold execution, experiment paralellisation and performance reports. A basic definition of ordinal regression can be found at [Wikipedia](https://en.wikipedia.org/wiki/Ordinal_regression).

As a generic experimental framework, its two main objectives are:

1. To run experiments easily to facilitate the comparison between **algorithms** and **datasets**.
2. To provide an easy way of including new algorithms into the framework by simply defining the training and test methods and the hyperparameters of the algorithms.

To help these purposes, ORCA is mainly used through **[configuration files](doc/orca_tutorial_1.md#launch-experiments-through-ini-files)** that describe experiments, but the methods can also be easily used through a common **[API](doc/orca_tutorial_1.md#running-algorithms-with-orca-api)**.

# Cite ORCA

If you use ORCA and/or associated datasets, please cite the following works: 

```
J. Sánchez-Monedero, P. A. Gutiérrez and M. Pérez-Ortiz, 
"ORCA: A Matlab/Octave Toolbox for Ordinal Regression", 
Journal of Machine Learning Research. Vol. 20. Issue 125. 2019. http://jmlr.org/papers/v20/18-349.html

P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero, F. Fernandez-Navarro and C. Hervás-Martínez.
"Ordinal regression methods: survey and experimental study",
IEEE Transactions on Knowledge and Data Engineering, Vol. 28, January, 2016, pp. 127-146. http://dx.doi.org/10.1109/TKDE.2015.2457911
```

Bibtex entry:

```
@article{JMLR:v20:18-349,
  author  = {Javier S{{\'a}}nchez-Monedero and Pedro A. Guti{{\'e}}rrez and Mar{{\'i}}a P{{\'e}}rez-Ortiz},
  title   = {ORCA: A Matlab/Octave Toolbox for Ordinal Regression},
  journal = {Journal of Machine Learning Research},
  year    = {2019},
  volume  = {20},
  number  = {125},
  pages   = {1-5},
  url     = {http://jmlr.org/papers/v20/18-349.html}
}

@Article{Gutierrez2015,
  Title                    = {Ordinal regression methods: survey and experimental study},
  Author                   = {P.A. Guti\'errez and M. P\'erez-Ortiz and J. S\'anchez-Monedero and  F. Fernandez-Navarro and C. Herv\'as-Mart\'inez},
  Journal                  = {IEEE Transactions on Knowledge and Data Engineering},
  Year                     = {2016},
  Url                      = {http://dx.doi.org/10.1109/TKDE.2015.2457911},
  Volume                   = {28},
  Number                   = {1},
  pages                    = {127-146},
}
```

For more information about the paper and the ordinal datasets used please visit the associated website: [http://www.uco.es/grupos/ayrna/orreview](http://www.uco.es/grupos/ayrna/orreview)

For more information about our research group please visit [Learning and Artificial Neural Networks (AYRNA) website](http://www.uco.es/grupos/ayrna/index.php/en) at [University of Córdoba](http://www.uco.es/) (Spain).

# Installation, tutorials and documentation

The documentation can be found in the [doc](doc) folder and includes:
  - A [quick installation guide of ORCA](doc/orca_quick_install.md) and the associated [build troubleshooting](doc/orca_install.md). Binaries are available for downloading in the [release page](https://github.com/ayrna/orca/releases).
  - Three **tutorials** on ordinal regression and ORCA (prepared for Octave). Note: you will need Jupyter and the Octave kernel to use the notebooks (`pip install --user jupyter && pip install --user octave_kernel`):
	  1. A first *'how to' tutorial* ([Jupyter Notebook](doc/orca_tutorial_1.ipynb), [MD](doc/orca_tutorial_1.md)) to get started with ORCA.
  	1. A specific *tutorial for naive approaches and decomposition methods* ([Jupyter Notebook](doc/orca_tutorial_2.ipynb), [MD](doc/orca_tutorial_2.md)) covering the different considerations needed for these methods.
  	1. A *tutorial for threshold models* ([Jupyter Notebook](doc/orca_tutorial_3.ipynb), [MD](doc/orca_tutorial_3.md)) examining the differences of these models.
  - A guide about how to [parallelize ORCA experiments](doc/orca_parallel.md).
  - Some notes about the [use of ORCA with HTCondor](doc/orca_condor.md).
  - An example about how to [add a new method to ORCA](doc/orca_addmethod.md).
  - An additional branch that includes other methods ready to use in ORCA. Visit [orca-extra-methods branch](https://github.com/ayrna/orca/tree/orca-extra-methods).

# Methods included

The [Algorithms](src/Algorithms) folder includes the MATLAB classes for the algorithms included and the original code (if applicable). The [config-files](src/config-files) folder includes different configuration files for running all the algorithms. In order to use these files, the [datasets](http://www.uco.es/grupos/ayrna/ucobigfiles/datasets-orreview.zip) used in the previously cited review paper are needed. To add your own method see [Adding a new method to ORCA](doc/orca_addmethod.md).

**Running time** of the algorithms was analysed in ["Ordinal regression methods: survey and experimental study"](http://dx.doi.org/10.1109/TKDE.2015.2457911)
(2016). From this analysis, it can be concluded that ELMOP, SVORLin and POM are the best option if computational cost is a priority. The training time of neural network methods (NNPOM and NNOP) and GPOR is in general the highest. This cost can be assumed for GPOR, given that it obtains very good performance for balanced ordinal datasets, while neural network-based methods are generally beaten by the ordinal SVM variants. Concerning scalability, the experimental setup in the review also included some relatively large datasets, so the practitioner could check the time it took to train one of those models with the ORCA framework. In general, linear models such as POM and SVORLin perform very well in these scenarios where there is plenty of data while still having a reasonably low running time (e.g. around 10 seconds for cross-validating, training and testing on a dataset of almost 22.000 patterns). Although very high-dimensional datasets were not considered in the analysis, it is well-known that SVMs can handle high-dimensional data, and given that they are one of the best performing methods in ordinal regression, this might be a good choice in such scenario.

## Ordinal regression algorithms

  - [SVR](src/Algorithms/SVR.m) [2]: Standard Support Vector Regression with normalised targets (considered as a naïve approach for ordinal regression since equal distances between targets are assumed).
  - [CSSVC](src/Algorithms/CSSVC.m) [1]: Nominal SVM with the OneVsAll decomposition, where absolute costs are included as different weights for the negative class of each decomposition (it is considered as a naïve approach for ordinal regression since equal distances between targets are assumed).
  - [SVMOP](src/Algorithms/SVMOP.m) [3,4]: Binary ordinal decomposition methodology with SVM as base method, it imposes explicit weights over the patterns and uses a probabilistic framework for the prediction.
  - [ELMOP](src/Algorithms/ELMOP.m) [5]: Standard Extreme Learning Machine imposing an ordinal structure in the coding scheme representing the target variable.
  - [POM](src/Algorithms/POM.m) [6]: Extension of the linear binary Logistic Regression methodology to Ordinal Classification by means of Cumulative Link Functions.
  - [SVOREX](src/Algorithms/SVOREX.m) [7]: Ordinal formulation of the SVM paradigm, which computes discriminant parallel hyperplanes for the data and a set of thresholds by imposing explicit constraints in the optimization problem.
  - [SVORIM](src/Algorithms/SVORIM.m) [7]: Ordinal formulation of the SVM paradigm, which computes discriminant parallel hyperplanes for the data and a set of thresholds by imposing implicit constraints in the optimization problem.
  - [SVORLin](src/Algorithms/SVORLin.m) [7]: Linear version of the SVORIM method (considering a linear kernel instead of the Gaussian one) to check how the kernel trick affects the final performance.
  - [KDLOR](src/Algorithms/KDLOR.m) [8]: Reformulation of the well-known Kernel Discriminant Analysis for Ordinal Regression by imposing an order constraint in the projected classes.
  - [NNPOM](src/Algorithms/NNPOM.m) [6,9]: Neural Network based on Proportional Odd Model (NNPOM), implementing a neural network model for ordinal regression. The model has one hidden layer and one output layer with only one neuron but as many thresholds as the number of classes minus one. The standard POM model is applied in this neuron to provide probabilistic outputs.
  - [NNOP](src/Algorithms/NNOP.m) [10]: Neural Network with Ordered Partitions (NNOP), this model considers the OrderedPartitions coding scheme for the labels and a rule for decisions based on the first node whose output is higher than a predefined threshold (T=0.5). The model has one hidden layer and one output layer with as many neurons as the number of classes minus one.
  - [REDSVM](src/Algorithms/REDSVM.m) [11]: Augmented Binary Classification framework that solves the Ordinal Regression problem by a single binary model (SVM is applied in this case).
  - [ORBoost](src/Algorithms/ORBoost.m) [12]: This is an ensemble model based on the threshold model structure, where normalised sigmoid functions are used as the base classifier. The *weights* parameter configures whether the All margins versions is used (`weights=true`) or the Left-Right margin is used (`weights=false`).
  - [OPBE](src/Algorithms/OPBE.m) [13]: Ordinal projection-based ensemble (OPBE) based on three-class decompositions, following the ordinal structure. A specific method for fusing the probabilities returned by the different three-class classifiers is implemented (product combiner, logit function and equal distribution of the probabilities). The base classifier is SVORIM but potentially any of the methods in ORCA can be setup as base classifier.

## Partial order methods
  - [HPOLD](src/Algorithms/HPOLD.m) [16]: Hierarchical Partial Order Label Decomposition with linear and non-linear base methods.

## Nominal methods

  - [SVC1V1](src/Algorithms/SVC1V1.m) [1]: Nominal Support Vector Machine using the OneVsOne formulation (considered as a naïve approach for ordinal regression since it ignores the order information).
  - [SVC1VA](src/Algorithms/SVC1VA.m) [1]: Nominal Support Vector Machine with the OneVsAll paradigm (considered as a naïve approach for ordinal regression since it ignores the order information).
  - [LIBLINEAR](src/Algorithms/LIBLINEAR.m): Implementation of logistic regression and linear SVM based on [LIBLINEAR](https://www.csie.ntu.edu.tw/~cjlin/liblinear/).

# Performance metrics

The [measures](src/Measures) folder contains the MATLAB classes for the metrics used for evaluating the classifiers. The measures included in ORCA are the following (more details about the metrics can be found in [14,15]:
  - [MAE](src/Measures/MAE.m): Mean Absolute Error between predicted and expected categories, representing classes as integer numbers (1, 2, ...).
  - [MZE](src/Measures/MZE.m): Mean Zero-one Error or standard classification error (1-accuracy).
  - [AMAE](src/Measures/AMAE.m): Average MAE, considering MAEs individually calculated for each class.
  - [CCR](src/Measures/CCR.m): Correctly Classified Ration or percentage of correctly classified patterns.
  - [GM](src/Measures/GM.m): Geometric Mean of the sensitivities individually calculated for each class.
  - [MMAE](src/Measures/MMAE.m): Maximum MAE, considering MAEs individually calculated for each class.
  - [MS](src/Measures/MS.m): Minimum Sensitivity, representing the ratio of correctly classified patterns for the worst classified class.
  - [Spearman](src/Measures/Spearman.m): Spearman Rho.
  - [Tkendall](src/Measures/Tkendall.m): Tau of Kendall.
  - [Wkappa](src/Measures/Wkappa.m): Weighted Kappa statistic, using ordinal weights.

# Utilities, classes and scripts

- [DataSet.m](src/Utils/DataSet.m): Class for data preprocessing.
- [Experiment.m](src/Utils/Experiment.m): Class that runs the different experiments.
- [Utilities.m](src/Utils/Utilities.m): Class that pre-process the experiment files, run the different algorithms and produces the results.
- [runtests_single.m](src/runtests_single.m): Script to run all the methods using the ORCA API. Reference performance is compared with `toy` dataset in order to check that the installation is correct.
- [runtests_cv.m](src/runtests_cv.m): This script runs full experiment tests using the ORCA configuration files to describe experiments.

# Datasets

The [example-data](exampledata) folder includes partitions of several small ordinal datasets for code testing purposes. We have also collected 44 publicly available ordinal datasets from various sources. These can be downloaded from: [datasets-OR-review](http://www.uco.es/grupos/ayrna/ucobigfiles/datasets-orreview.zip). The link also contains data partitions as used in different papers in the literature to ease experimental comparison. The characteristics of these datasets are the following:

| Dataset	|	\#Pat.	|	\#Attr.	|	\#Classes	|	Class distribution	|
| --- | --- | --- | --- | --- |
| pyrim5 (P5)	|	74	|	27	|	5	|	~15	 per class|
| machine5 (M5)	|	209	|	7	|	5	|	~42	 per class|
| housing5 (H5)	|	506	|	14	|	5	|	~101	 per class|
| stock5 (S5)	|	700	|	9	|	5	|	140	 per class|
| abalone5 (A5)	|	4177	|	11	|	5	|	~836	 per class|
| bank5 (B5)	|	8192	|	8	|	5	|	~1639	 per class|
| bank5' (BB5)	|	8192	|	32	|	5	|	~1639	 per class|
| computer5 (C5)	|	8192	|	12	|	5	|	~1639	 per class|
| computer5' (CC5)	|	8192	|	21	|	5	|	~1639	 per class|
| cal.housing5 (CH5)	|	20640	|	8	|	5	|	4128	 per class|
| census5 (CE5)	|	22784	|	8	|	5	|	~4557	 per class|
| census5' (CEE5)	|	22784	|	16	|	5	|	~4557	 per class|
| pyrim10 (P10)	|	74	|	27	|	10	|	~8	 per class|
| machine10 (M10)	|	209	|	7	|	10	|	~21	 per class|
| housing10 (H10)	|	506	|	14	|	10	|	~51	 per class|
| stock10 (S10)	|	700	|	9	|	10	|	70	 per class|
| abalone10 (A10)	|	4177	|	11	|	10	|	~418	 per class|
| bank10 (B10)	|	8192	|	8	|	10	|	~820	 per class|
| bank10' (BB10)	|	8192	|	32	|	10	|	~820	 per class|
| computer10 (C10)	|	8192	|	12	|	10	|	~820	 per class|
| computer10' (CC10)	|	8192	|	21	|	10	|	~820	 per class|
| cal.housing (CH10)	|	20640	|	8	|	10	|	2064	 per class|
| census10 (CE10)	|	22784	|	8	|	10	|	~2279	 per class|
| census10' (CEE10)	|	22784	|	16	|	10	|	~2279	 per class|

| Dataset	|	\#Pat.	|	\#Attr.	|	\#Classes	|	Class distribution	|
| --- | --- | --- | --- | --- |
| contact-lenses (CL)	|	24	|	6	|	3	|	(15,5,4)	|
| pasture (PA)		|	36	|	25	|	3	|	(12,12,12)	|
| squash-stored (SS)	|	52	|	51	|	3	|	(23,21,8)	|
| squash-unstored (SU)	|	52	|	52	|	3	|	(24,24,4)	|
| tae (TA)		|	151	|	54	|	3	|	(49,50,52)	|
| newthyroid (NT)		|	215	|	5	|	3	|	(30,150,35)	|
| balance-scale (BS)	|	625	|	4	|	3	|	(288,49,288)	|
| SWD (SW)		|	1000	|	10	|	4	|	(32,352,399,217)	|
| car (CA)		|	1728	|	21	|	4	|	(1210,384,69,65)	|
| bondrate (BO)		|	57	|	37	|	5	|	(6,33,12,5,1)	|
| toy (TO)		|	300	|	2	|	5	|	(35,87,79,68,31)	|
| eucalyptus (EU)		|	736	|	91	|	5	|	(180,107,130,214,105)	|
| LEV (LE)		|	1000	|	4	|	5	|	(93,280,403,197,27)	|
| automobile (AU)		|	205	|	71	|	6	|	(3,22,67,54,32,27)	|
| winequality-red (WR)	|	1599	|	11	|	6	|	(10,53,681,638,199,18)	|
| ESL (ES)		|	488	|	4	|	9	|	(2,12,38,100,116,135,62,19,4)	|
| ERA (ER)		|	1000	|	4	|	9	|	(92,142,181,172,158,118,88,31,18)	|
| marketing	|	8993	|	74	|	9	|	(1745,775,667,813,722,1110,969,1308,884)	|
| thyroid	|	7200	|	21	|	3	|	(6666,166,368)	|
|  winequality-white	|	4898	|	11	|	7	|	(20,163,1457,2198,880,175,5)	|

# Experiments parallelization with HTCondor

The [condor](src/condor) folder contains the necessary files and steps for using [HTCondor](https://research.cs.wisc.edu/htcondor/) with our framework.

# External software
ORCA makes use of the following external software implementations. For some of them, a Matlab interface has been developed through the use of MEX files.
- [libsvm-weights-3.12](http://ntucsu.csie.ntu.edu.tw/~cjlin/libsvmtools/#weights_for_data_instances): framework used for Support Vector Machine algorithms. The version considered was 3.12.
- [libsvm-rank-2.81](http://www.work.caltech.edu/~htlin/program/libsvm/): implementation used for the REDSVM method. The version considered was 2.81.
- [orensemble](http://www.work.caltech.edu/~htlin/program/orensemble/): implementation used for the ORBoost method.
- [SVOR](http://www.gatsby.ucl.ac.uk/~chuwei/svor.htm): implementation used for the SVOREX, SVORIM and SVORIMLin methods.

# Other contributors
Apart from the authors of the paper and the authors of the implementations referenced in "External software" section, the following persons also contributed to ORCA framework:
- [Juan Martín Jiménez Alcaide](http://www.ic.uma.es/contenidos/ficha_personal.action?id=1034) developed the Matlab wrappers for the SVORIM and SVOREX algorithms.

# References
- [1] C.-W. Hsu and C.-J. Lin, “A comparison of methods for multi-class support vector machines,” IEEE Transaction on Neural Networks, vol. 13, no. 2, pp. 415–425, 2002.
- [2] A. Smola and B. Schölkopf, “A tutorial on support vector regression,” Statistics and Computing, vol. 14, no. 3, pp. 199–222, 2004.
- [3] E. Frank and M. Hall, “A simple approach to ordinal classification,” in Proceedings of the 12th European Conference on Machine Learning, ser. EMCL ’01. London, UK: Springer-Verlag, 2001, pp. 145–156.
- [4] W. Waegeman and L. Boullart, “An ensemble of weighted support vector machines for ordinal regression,” International Journal of Computer Systems Science and Engineering, vol. 3, no. 1, pp. 47–51, 2009.
- [5] W.-Y. Deng, Q.-H. Zheng, S. Lian, L. Chen, and X. Wang, “Ordinal extreme learning machine,” Neurocomputing, vol. 74, no. 1–3, pp. 447– 456, 2010.
- [6] P. McCullagh, “Regression models for ordinal data,” Journal of the Royal Statistical Society. Series B (Methodological), vol. 42, no. 2, pp. 109–142, 1980.
- [7] W. Chu and S. S. Keerthi, “Support Vector Ordinal Regression,” Neural Computation, vol. 19, no. 3, pp. 792–815, 2007.
- [8] B.-Y. Sun, J. Li, D. D. Wu, X.-M. Zhang, and W.-B. Li, “Kernel discriminant learning for ordinal regression,” IEEE Transactions on Knowledge and Data Engineering, vol. 22, no. 6, pp. 906–910, 2010.
- [9] M. J. Mathieson, Ordinal models for neural networks, in Proc. 3rd Int. Conf. Neural Netw. Capital Markets, 1996, pp. 523-536.
- [10] J. Cheng, Z. Wang, and G. Pollastri, "A neural network approach to ordinal regression," in Proc. IEEE Int. Joint Conf. Neural Netw. (IEEE World Congr. Comput. Intell.), 2008, pp. 1279-1284.
- [11] H.-T. Lin and L. Li, “Reduction from cost-sensitive ordinal ranking to weighted binary classification,” Neural Computation, vol. 24, no. 5, pp. 1329–1367, 2012.
- [12] H.-T. Lin and L. Li, “Large-margin thresholded ensembles for ordinal regression: Theory and practice,” in Proc. of the 17th Algorithmic Learning Theory International Conference, ser. Lecture Notes in Artificial Intelligence (LNAI), J. L. Balcazar, P. M. Long, and F. Stephan, Eds., vol. 4264. Springer-Verlag, October 2006, pp. 319–333.
- [13] M. Pérez-Ortiz, P. A. Gutiérrez y C. Hervás-Martínez. “Projection based ensemble learning for ordinal regression”, IEEE Transactions on Cybernetics, Vol. 44, May, 2014, pp. 681-694.
- [14] M. Cruz-Ramírez, C. Hervás-Martínez, J. Sánchez-Monedero and P. A. Gutiérrez. “Metrics to guide a multi-objective evolutionary algorithm for ordinal classification,” Neurocomputing, Vol. 135, July, 2014, pp. 21-31.
- [15] J. C. Fernandez-Caballero, F. J. Martínez-Estudillo, C. Hervás-Martínez and P. A. Gutiérrez. “Sensitivity Versus Accuracy in Multiclass Problems Using Memetic Pareto Evolutionary Neural Networks,” IEEE Transacctions on Neural Networks, Vol. 21. 2010, pp. 750-770.
- [16] J. Sánchez-Monedero, M. Pérez-Ortiz, A. Sáez, P.A. Gutiérrez and C. Hervás-Martínez. "Partial order label decomposition approaches for melanoma diagnosis". Applied Soft Computing. Vol. 64, March 2018, pp. 341-355.

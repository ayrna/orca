![ORCA logo](doc/orca_small.png)
<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:1 -->

1. [ORCA](#orca)
2. [Cite ORCA](#cite-orca)
3. [Install, tutorials and documentation](#install-tutorials-and-documentation)
4. [Methods](#methods)
	1. [Ordinal regression algorithms](#ordinal-regression-algorithms)
	2. [Partial order methods](#partial-order-methods)
	3. [Nominal methods](#nominal-methods)
5. [Performance metrics](#performance-metrics)
6. [Utilities, classes and scripts](#utilities-classes-and-scripts)
7. [Experiments parallelization with HTCondor](#experiments-parallelization-with-htcondor)
8. [External software](#external-software)
9. [Other contributors](#other-contributors)
10. [References](#references)

<!-- /TOC -->

# ORCA
ORCA (Ordinal Regression and Classification Algorithms) is a MATLAB framework including a wide set of ordinal regression methods associated to the paper ["Ordinal regression methods: survey and experimental study"](http://dx.doi.org/10.1109/TKDE.2015.2457911) published in *IEEE Transactions on Knowledge and Data Engineering*. ORCA provides implementation and integration of ordinal classification algorithms and performance metrics for ordinal regression. In addition, it helps to accelerate classifier experimental comparison with automatic fold execution, experiment paralellisation and performance reports. You can find a basic definition of ordinal regression at [Wikipedia](https://en.wikipedia.org/wiki/Ordinal_regression).

As a general experimental framework, the two main objectives of the framework are:

1. To run many experiments as easily as possible to compare **many algorithms** and **many datasets**.
2. To provide an easy way of including new algorithms into the framework by simply defining the parameters of the algorithms and the training and test methods.

To help these purposes, ORCA is mainly used through **[scripts](doc/orca-tutorial.md#running-algorithms-with-orca-api#experiment-configuration)** that describe experiments, but the methods can be easily used through a common **[API](doc/orca-tutorial.md#running-algorithms-with-orca-api)**.

# Cite ORCA

The initial code of ORCA was released linked to the following work, if you use this framework please cite it:

```
P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero, F. Fernández-Navarro and C. Hervás-Martínez (2016),
"Ordinal regression methods: survey and experimental study",
IEEE Transactions on Knowledge and Data Engineering. Vol. 28. Issue 1
```

Bibtex entry:

```
@Article{Gutierrez2015,
  Title                    = {Ordinal regression methods: survey and experimental study},
  Author                   = {P.A. Guti\'errez and M. P\'erez-Ortiz and J. S\'anchez-Monedero and  F. Fernandez-Navarro and C. Herv\'as-Mart\'inez},
  Journal                  = {IEEE Transactions on Knowledge and Data Engineering},
  Year                     = {2016},
  Url                      = {http://dx.doi.org/10.1109/TKDE.2015.2457911},
  Volume                   = {28},
  Number                   = {1}
}
```

For more information about the paper and the ordinal datasets used please visit the associated website: [http://www.uco.es/grupos/ayrna/orreview](http://www.uco.es/grupos/ayrna/orreview)
For more information about our research group please visit [Learning and Artificial Neural Networks (AYRNA) website](http://www.uco.es/grupos/ayrna/index.php/en) at [University of Córdoba](http://www.uco.es/) (Spain).

# Install, tutorials and documentation

All the documentation is in the [doc](doc) folder:
  - A [quick install guide of ORCA](doc/orca-quick-install.md) and the associated [build troubleshooting](doc/orca-install.md).
  - A first [how to tutorial](doc/orca-tutorial.md) to get started with ORCA.
  - A specific [tutorial for naive approaches and decompositions](doc/orca-tutorial-2.md) covering the different considerations for this kind of methods.
  - A [tutorial for threshold models](doc/orca-tutorial-3.md) centred on examining the differences of these models.
  - [Paralelize ORCA experiments](doc/orca-parallel.md).
  - [Use ORCA with HTCondor](doc/orca-condor.md).
  - [Adding a new method to ORCA](doc/addmethod/addmethod.md).

# Methods

The [Algorithms](src/Algorithms) folder includes the MATLAB classes for the algorithms included and the original code (if applicable). [config-files](src/config-files) includes different configuration files for running all the algorithms. In order to use these files, you will need the [datasets](http://www.uco.es/grupos/ayrna/ucobigfiles/datasets-orreview.zip) of our review paper. To add your own method see [Adding a new method to ORCA](doc/addmethod/addmethod.md).

## Ordinal regression algorithms

  - [SVR](src/Algorithms/SVR.m) [2]: Standard Support Vector Regression with normalised targets (considered as a naïve approach for ordinal regression since the assumption of equal distances between targets is done).
  - [CSSVC](src/Algorithms/CSSVC.m) [1]: This is a nominal SVM with the OneVsAll decomposition, where absolute costs are included as different weights for the negative class of each decomposition (it is considered as a naïve approach for ordinal regression since the assumption of equal distances between classes is done).
  - [SVMOP](src/Algorithms/SVMOP.m) [3,4]: Binary ordinal decomposition methodology with SVM as base method, it imposes explicit weights over the patterns and performs a probabilistic framework for the prediction.
  - [ELMOP](src/Algorithms/ELMOP.m) [5]: Standard Extreme Learning Machine imposing an ordinal structure in the coding scheme representing the target variable.
  - [POM](src/Algorithms/POM.m) [6]: Extension of the linear binary Logistic Regression methodology to Ordinal Classification by means of Cumulative Link Functions.
  - [SVOREX](src/Algorithms/SVOREX.m) [7]: Ordinal formulation of the SVM paradigm, which computes discriminant parallel hyperplanes for the data and a set of thresholds by imposing explicit constraints in the optimization problem.
  - [SVORIM](src/Algorithms/SVORIM.m) [7]: Ordinal formulation of the SVM paradigm, which computes discriminant parallel hyperplanes for the data and a set of thresholds by imposing implicit constraints in the optimization problem.
  - [SVORLin](src/Algorithms/SVORLin.m) [7]: We have also included a linear version of the SVORIM method (considering the linear kernel instead of the Gaussian one) to check how the kernel trick affects the final performance (SVORLin).
  - [KDLOR](src/Algorithms/KDLOR.m) [8]: Reformulation of the well-known Kernel Discriminant Analysis for Ordinal Regression by imposing an order constraint in the projection to compute.
  - [NNPOM](src/Algorithms/NNPOM.m) [6,9]: Neural Network based on Proportional Odd Model (NNPOM), implementing a neural network model for ordinal regression. The model has one hidden layer and one output layer with only one neuron but as many threshold as the number of classes minus one. The standard POM model is applied in this neuron to have probabilistic outputs.
  - [NNOP](src/Algorithms/NNOP.m) [10]: Neural Network with Ordered Partitions (NNOP), this model considers the OrderedPartitions coding scheme for the labels and a rule for decisions based on the first node whose output is higher than a predefined threshold (T=0.5). The model has one hidden layer and one outputlayer with as many neurons as the number of classes minus one.
  - [REDSVM](src/Algorithms/REDSVM.m) [11]: Augmented Binary Classification framework that solves the Ordinal Regression problem by a single binary model (SVM is applied in this case).
  - [ORBoost](src/Algorithms/ORBoost.m) [12]: This is an ensemble model based on the threshold model structure, where normalised sigmoid functions are used as the base classifier. The *weights* parameters configures whether the All margins versions is used (`weights=true`) or the Left-Right margin is used (`weights=false`).
  - [OPBE](src/Algorithms/OPBE.m) [13]: This method implements an ordinal projection based ensemble (OPBE) based on three-class decompositions, following the ordinal structure. A specific method for fusing the probabilities returned by the different three-class classifiers is implemented (product combiner, logit function and equal distribution of the probabilities). The base classifier is SVORIM but potentially any of the methods in ORCA can be setup as base classifier.

## Partial order methods
  - [HPOLD](src/Algorithms/HPOLD.m) [16]: Hierarchical Partial Order Label Decomposition with linear and non-linear base methods.

## Nominal methods

  - [SVC1V1](src/Algorithms/SVC1V1.m) [1]: Nominal Support Vector Machine performing the OneVsOne formulation (considered as a naïve approach for ordinal regression since it ignores the order information).
  - [SVC1VA](src/Algorithms/SVC1VA.m) [1]: Nominal Support Vector Machine with the OneVsAll paradigm (considered as a naïve approach for ordinal regression since it ignores the order information).
  - [LIBLINEAR](src/Algorithms/LIBLINEAR.m) : Provides implementation of logistic regression and linear SVM based on [LIBLINEAR](https://www.csie.ntu.edu.tw/~cjlin/liblinear/).

# Performance metrics

[Measures](src/Measures) folder contains the MATLAB classes for the metrics used for evaluating the classifiers. The measures included in ORCA are the following (more details about the metrics can be found in [14,15]:
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

- [DataSet.m](src/DataSet.m): Class for data preprocessing.
- [Experiment.m](src/Experiment.m): Class that runs the different experiments.
- [Utilities.m](src/Utilities.m): Class that pre-process the experiment files, run the different algorithms and produces the results.
- [runtests.m](src/runtests.m): Script to run all the methods in order to check that the installation is correct.
- [runtestssingle.m](src/runtests.m): Script to run all the methods using the ORCA API. Reference performance is compared with toy dataset in order to check that the installation is correct.
- [runtestscv.m](src/runtests.m): This script runs full experiment tests using the ORCA configuration files to describe experiments.

# Experiments parallelization with HTCondor

[condor](src/condor) folder contains the necessary files and steps for using [HTCondor](https://research.cs.wisc.edu/htcondor/) with our framework.

# External software
The ORCA frameworks makes use of the following external software implementations. For some of them, a Matlab interface has been developed through the use of MEX files.
- [libsvm-weights-3.12](http://ntucsu.csie.ntu.edu.tw/~cjlin/libsvmtools/#weights_for_data_instances): we have used this framework for Support Vector Machine algorithms. The version considered was 3.12.
- [libsvm-rank-2.81](http://www.work.caltech.edu/~htlin/program/libsvm/): this implementation was used for the method REDSVM. The version considered was 2.81.
- [orensemble](http://www.work.caltech.edu/~htlin/program/orensemble/): this implementation was used for the method ORBoost.
- [SVOR](http://www.gatsby.ucl.ac.uk/~chuwei/svor.htm): this implementation was used for the methods SVOREX, SVORIM and SVORIMLin.

# Other contributors
Apart from the authors of the paper and the authors of the implementations referenced in "External software" section, the following persons have also contributed to ORCA framework:
- [Juan Martín Jiménez Alcaide](https://es.linkedin.com/pub/juan-martín-jiménez/89/824/a31) developed the Matlab wrappers for the SVORIM and SVOREX algorithms.

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

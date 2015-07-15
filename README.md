# orca

![ORCA logo](doc/orca_small.png) ORCA (Ordinal Regression and Classification Algorithms) is a MATLAB framework including a wide set of ordinal regression methods associated to the paper "Ordinal regression methods: survey and experimental study" published in IEEE Transactions on Knowledge and Data Engineering. If you use this framework please cite the following work:

```
P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero, F. Fernández-Navarro and C. Hervás-Martínez (2015), "Ordinal regression methods: survey and experimental study", IEEE Transactions on Knowledge and Data Engineering. Vol. Accepted
```

Bibtex entry:

```
@Article{Gutierrez2015,
  Title                    = {Ordinal regression methods: survey and experimental study},
  Author                   = {P.A. Guti\'errez and M. P\'erez-Ortiz and J. S\'anchez-Monedero and  F. Fernandez-Navarro and C. Herv\'as-Mart\'inez},
  Journal                  = {IEEE Transactions on Knowledge and Data Engineering},
  Year                     = {2015},
  Volume                   = {Accepted}
}
```

For more information about the paper and the ordinal datasets used please visit the associated webpage: http://www.uco.es/grupos/ayrna/orreview
For more information about our research group please visit [Learning and Artificial Neural Networks (AYRNA) website](http://www.uco.es/grupos/ayrna/index.php/en) at [University of Córdoba](http://www.uco.es/) (Spain).

The code is mainly composed of the following folders and files:
- [doc](doc): Folder containing the documentation (class diagrams and example of use). There is a [How to tutorial](doc/orca-tutorial.md) to get started. Other tutorials are:
  - [Use ORCA with HTCondor](orca/doc/orca-condor.md)
  - [Paralelize ORCA experiments](orca/doc/orca-condor.md)
- [src](src): Folder containing the matlab code.

The [src](src) folder contains the following folders and files:
- [Algorithms](src/Algorithms): Folder containing the matlab classes for the algorithms included and the original code (if applicable). The algorithms included in ORCA are the followings:
 - [CSSVC](src/Algorithms/CSSVC.m): This is a nominal SVM with the OneVsAll decomposition, where absolute costs are included as different weights for the negative class of each decomposition (it is considered as a naïve approach for ordinal regression since the assumption of equal distances between classes is done).
 - [ELMOP](src/Algorithms/ELMOP.m): Standard Extreme Learning Machine imposing an ordinal structure in the coding scheme representing the target variable.
 - [KDLOR](src/Algorithms/KDLOR.m): Reformulation of the well-known Kernel Discriminant Analysis for Ordinal Regression by imposing an order constraint in the projection to compute.
 - [ORBoost](src/Algorithms/ORBoost.m): This is an ensemble model based on the threshold model structure, where normalised sigmoid functions are used as the base classifier. The *weights* parameters configures whether the All margins versions is used (`weights=true`) or the Left-Right margin is used (`weights=false`).
 - [POM](src/Algorithms/POM.m): Extension of the linear binary Logistic Regression methodology to Ordinal Classification by means of Cumulative Link Functions.
 - [REDSVM](src/Algorithms/REDSVM.m): Augmented Binary Classification framework that solves the Ordinal Regression problem by a single binary model (SVM is applied in this case).
 - [SVC1V1](src/Algorithms/SVC1V1.m): Nominal Support Vector Machine performing the OneVsOne formulation (considered as a naïve approach for ordinal regression since it ignores the order information).
 - [SVC1VA](src/Algorithms/SVC1VA.m): Nominal Support Vector Machine with the OneVsAll paradigm (considered as a naïve approach for ordinal regression since it ignores the order information).
 - [SVMOP](src/Algorithms/SVMOP.m): Binary ordinal decomposition methodology with SVM as base method, it imposes explicit weights over the patterns and performs a probabilistic framework for the prediction.
 - [SVOREX](src/Algorithms/SVOREX.m): Ordinal formulation of the SVM paradigm, which computes discriminant parallel hyperplanes for the data and a set of thresholds by imposing explicit constraints in the optimization problem.
 - [SVORIM](src/Algorithms/SVORIM.m): Ordinal formulation of the SVM paradigm, which computes discriminant parallel hyperplanes for the data and a set of thresholds by imposing implicit constraints in the optimization problem.
 - [SVORLin](src/Algorithms/SVORLin.m): We have also included a linear version of the SVORIM method (considering the linear kernel instead of the Gaussian one) to check how the kernel trick affects the final performance (SVORLin).
 - [SVR](src/Algorithms/SVR.m): Standard Support Vector Regression with normalised targets (considered as a naïve approach for ordinal regression since the assumption of equal distances between targets is done).
- [condor](src/condor): Folder with the necessary files and steps for using condor with our framework.
- [config-files](src/config-files): Folder with different configuration files for running all the algorithms.
- [Measures](src/Measures): Folder with the matlab classes for the metrics used for evaluating the classifiers.
- [Algorithm.m](src/Algorithm.m): File that sets the necessary properties and functions for an algorithm class.
- [DataSet.m](src/DataSet.m): Matlab class for data preprocessing.
- [Experiment.m](src/Experiment.m): Matlab class that runs the different experiments.
- [Metric.m](src/Metric.m): File that sets the necessary properties and functions for a metric class.
- [Utilities.m](src/Utilities.m): Class that preprocess the experiment files, run the different algorithms and produces the results.

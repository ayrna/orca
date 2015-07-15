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
- [Algorithms](src/Algorithms): Folder containing the matlab classes for the algorithms included and the original code (if applicable).
- [condor](src/condor): Folder with the necessary files and steps for using condor with our framework.
- [config-files](src/config-files): Folder with different configuration files for running all the algorithms.
- [Measures](src/Measures): Folder with the matlab classes for the metrics used for evaluating the classifiers.
- [Algorithm.m](src/Algorithm.m): File that sets the necessary properties and functions for an algorithm class.
- [DataSet.m](src/DataSet.m): Matlab class for data preprocessing.
- [Experiment.m](src/Experiment.m): Matlab class that runs the different experiments.
- [Metric.m](src/Metric.m): File that sets the necessary properties and functions for a metric class.
- [Utilities.m](src/Utilities.m): Class that preprocess the experiment files, run the different algorithms and produces the results.

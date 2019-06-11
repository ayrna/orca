# Parallelizing experiments with ORCA

ORCA can take advantage of MATLAB's parallel toolbox. The parallelism is done at dataset partition level. The method `runExperiments` of the class [Utilities](../src/Utilities.m) includes the following optional arguments, apart from the name of the configuration file:
 - `'parallel'`: *false* or *true* to activate CPU parallel processing of databases's folds. Default value is '*false*'.
 - `'numcores'`: default maximum number of cores or desired number. If *true* and numcores is lower than 2, this paramter sets the maximum number of cores.
 - `'closepool`': whether to close or not the pool after the experiments. Default *true*. Disabling it can speed up consecutive calls to `runExperiments` saving the time of opening and closing pools.

The improvement is done in models fitting and prediction. However, the reports have to be generated sequentially. Given that lots of metrics are obtained in these reports, this non-parallelizable operation is very costly.

In Octave, the `parfor` tool is not yet implemented. However, we have adapted the code to use the `parallel` package which provides similar functionality. If you want to parallelize experiments in Octave, you will have to install the corresponding package:
```MATLAB
pkg install -forge parallel
```

These are some examples measuring the performance improvement:
```MATLAB
cd src
addpath('Utils')
% Launch experiments sequentially
tic;Utilities.runExperiments('tests/cvtests-30-holdout/kdlor.ini');toc
...
Elapsed time is 318.869864 seconds.

% Launch parallel experiments with maximum number of cores
tic;Utilities.runExperiments('tests/cvtests-30-holdout/kdlor.ini', 'parallel', true);toc
...
Elapsed time is 190.453860 seconds.

% Runs parallel folds with max workers and do not close the pool
Utilities.runExperiments('tests/cvtests-30-holdout/kdlor.ini', 'parallel', 1, 'closepool', false)
Utilities.runExperiments('tests/cvtests-30-holdout/svorim.ini', 'parallel', 1, 'closepool', false)

```

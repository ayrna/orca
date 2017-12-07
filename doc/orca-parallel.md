# Parallelizing experiments with ORCA

ORCA can take advantage of MATLAB's parallel toolbox. The parallelism is done at dataset partition level. The method `runExperiments` of the class [Utilities](../src/Utilities.m) includes the following optional arguments, apart from the name of the configuration file:
 - `'parallel'`: *false* or *true* to activate CPU parallel processing of databases's folds. Default is 'false'
 - `'numcores'`: default maximum number of cores or desired number. If *true* and numcores <2 it sets the number to maximum number of cores.
 - `'closepool`': whether to close or not the pool after  experiments. Default *true*. Disabling it can speed up consecutive calls to `runExperiments` saving the time of opening and closing pools.

Please note that reports calculation is done sequentially, so that the improvement is done in models fitting and prediction. Since the reports calculate lots of metrics, this is a costly operation.

Examples:

```MATLAB
% Launch experiments sequentially
tic;Utilities.runExperiments('tests/cvtests-30-holdout/kdlor.ini');toc
...
Elapsed time is 318.869864 seconds.

% Utilities.runExperiments('tests/cvtests-30-holdout/kdlor.ini', 'parallel', 1)
tic;Utilities.runExperiments('tests/kdlor', true);toc
...
Elapsed time is 190.453860 seconds.

%  Runs parallel folds with max workers and do not close the pool
Utilities.runExperiments('tests/cvtests-30-holdout/kdlor.ini', 'parallel', 1, 'closepool', false)
Utilities.runExperiments('tests/cvtests-30-holdout/svorim.ini', 'parallel', 1, 'closepool', false)

```

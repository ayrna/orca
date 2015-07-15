# Parallelizing experiments with ORCA

ORCA can take advantage of MATLAB's parallel toolbox. The parallelism is done at dataset partition level. The method `runExperiments` of the class [Utilities](../src/Utilities.m) includes two optional arguments, apart from the name of the configuration file. The first argument, if `true`, makes use of `parfor` to parallelize the execution of the different partitions using the cores available in the computer. The second argument indicates the number of cores to be used (by default, the maximum number of cores is considered).

```MATLAB
% Launch experiments sequentially
Utilities.runExperiments('tests/kdlor')

Elapsed time is 333.078627 seconds.

% Switch on parfor with maximum number of workers
tic;Utilities.runExperiments('tests/kdlor', true);toc

Elapsed time is 108.940259 seconds.

% Switch on parfor with fixed number of workers
tic;Utilities.runExperiments('tests/kdlor', true, 2);toc

```

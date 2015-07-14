# Parallelizing experiments with ORCA

ORCA can take advantage of MATLAB's parallel toolbox. The parallelism is done at dataset partition level.

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

% Note: this code should be run from orca/src/code-examples
clear param;
addpath ../Algorithms/
addpath ../Measures/
addpath ../Utils/

% Load the different partitions of the dataset
load ../../exampledata/1-holdout/toy/matlab/train_toy.0
load ../../exampledata/1-holdout/toy/matlab/test_toy.0

% "patterns" refers to the input variables and targets to the output one
train.patterns = train_toy(:,1:end-1);
train.targets = train_toy(:,end);
test.patterns = test_toy(:,1:end-1);
test.targets = test_toy(:,end);

% Create the algorithm object
algorithmObj = KDLOR();
% Create vectors of values to test
param.C = 10.^(-3:1:3);
param.k = 10.^(-3:1:3);
param.u = [0.01,0.001,0.0001,0.00001];

fprintf('Optimizing parameters for KDLOR with metric MAE (default metric)\n');
optimalp = paramopt(algorithmObj,param,train)

fprintf('Optimizing parameters for KDLOR with metric Tkendall\n');
optimalp = paramopt(algorithmObj,param,train, 'metric', Tkendall)

fprintf('Optimizing parameters for KDLOR with metric GM\n');
optimalp = paramopt(algorithmObj,param,train, 'metric', GM)


algorithmObj = SVC1V1();
clear param;
param.C = 10.^(-3:1:3);
param.k = 10.^(-3:1:3);

fprintf('Optimizing parameters for SVC1V1 with metric CCR\n');
optimalp = paramopt(algorithmObj,param,train, 'metric', CCR)

fprintf('Optimizing parameters for SVC1V1 with metric AMAE\n');
optimalp = paramopt(algorithmObj,param,train, 'metric', AMAE)

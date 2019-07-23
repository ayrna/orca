% Note: this code should be run from orca/src/code-examples
addpath ../Algorithms/
addpath ../Measures/

% Load the different partitions of the dataset
load ../../exampledata/1-holdout/toy/matlab/train_toy.0
load ../../exampledata/1-holdout/toy/matlab/test_toy.0

% patterns refers to the input variables and targets to the output one
train.patterns = train_toy(:,1:end-1);
train.targets = train_toy(:,end);
test.patterns = test_toy(:,1:end-1);
test.targets = test_toy(:,end);

% Create the algorithm object
kdlorAlgorithm = KDLOR('kernelType','rbf','optimizationMethod','quadprog');

% Parameters: C (Cost), k (kernel width), u (to avoid singularities)
param.C = 10;
param.k = 0.1;
param.u = 0.001;


% Run algorithm
info1 = kdlorAlgorithm.fitpredict(train,test,param);
amaeTest1 = AMAE.calculateMetric(test.targets,info1.predictedTest);
% Build legend text
msg{1} = sprintf('KDLOR k=%f. AMAE=%f', param.k, amaeTest1);

% Increase kernel width
param.k = 10;
info2 = kdlorAlgorithm.fitpredict(train,test,param);
amaeTest2 = AMAE.calculateMetric(test.targets,info2.predictedTest);
msg{2} = sprintf('KDLOR k=%f. AMAE=%f', param.k, amaeTest2);

figure; hold on;
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
  plothist(info1.projectedTest,30,[102 170 215]/255);
  plothist(info2.projectedTest,30,[232, 152, 117]/255);
else
  h1 = histogram(info1.projectedTest,30);
  h2 = histogram(info2.projectedTest,30);
end
legend(msg)
legend('Location','NorthWest')
hold off;

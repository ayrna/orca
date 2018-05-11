
clear;
addpath ../Algorithms/
addpath ../Measures/

% Load the different partitions of the dataset
train_toy = load('../../exampledata/1-holdout/toy/matlab/train_toy.0');
test_toy = load('../../exampledata/1-holdout/toy/matlab/test_toy.0');

% "patterns" refers to the input variables and targets to the output one
train.patterns = train_toy(:,1:end-1);
train.targets = train_toy(:,end);
test.patterns = test_toy(:,1:end-1);
test.targets = test_toy(:,end);

[train.patterns, trainMeans, trainStds] = DataSet.standarizeFunction(train.patterns);
[test.patterns] = DataSet.standarizeFunction(test.patterns, trainMeans, trainStds);

% Evolutionary ERNN with nominal model and sig activation function 
% Create the algorithm object
ERNNAlgorithm = ERNN('classifier','nominal','activationFunction','sig');

% Running the algorithm
info = ERNNAlgorithm.runAlgorithm(train,test);

fprintf('Nominal ERNN performance\n');

accTrain = CCR.calculateMetric(train.targets, info.predictedTrain);
accTest = CCR.calculateMetric(test.targets, info.predictedTest);
fprintf('Accuracy Train \t%f, Accuracy Test \t%f\n',accTrain,accTest);

amaeTrain = AMAE.calculateMetric(train.targets, info.predictedTrain);
amaeTest = AMAE.calculateMetric(test.targets, info.predictedTest);
fprintf('AMAE Train \t%f, AMAE Test \t\t%f\n',amaeTrain,amaeTest);


% Evolutionary ERNN with ordinal model and rbf activation function. Set the
% fitness to an ordinal metric and change hidden layer units
% Create the algorithm object
clear ERNNAlgorithm;
ERNNAlgorithm = ERNN('classifier','ordinal','activationFunction','rbf', ...
                     'FitnessFunction', 'wrmse');

param.hiddenN = 20;

% Running the algorithm
info = ERNNAlgorithm.runAlgorithm(train,test,param);

fprintf('Ordinal ERNN performance\n');

accTrain = CCR.calculateMetric(train.targets, info.predictedTrain);
accTest = CCR.calculateMetric(test.targets, info.predictedTest);
fprintf('Accuracy Train \t%f, Accuracy Test \t%f\n',accTrain,accTest);

amaeTrain = AMAE.calculateMetric(train.targets, info.predictedTrain);
amaeTest = AMAE.calculateMetric(test.targets, info.predictedTest);
fprintf('AMAE Train \t%f, AMAE Test \t\t%f\n',amaeTrain,amaeTest);




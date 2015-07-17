cd ../Algorithms/
addpath ..
kdlorAlgorithm = KDLOR('rbf','quadprog');

load ../../exampledata/toy/matlab/train_toy.0
load ../../exampledata/toy/matlab/test_toy.0

train.patterns = train_toy(:,1:(size(train_toy,2)-1));
train.targets = train_toy(:,size(train_toy,2));

test.patterns = test_toy(:,1:(size(test_toy,2)-1));
test.targets = test_toy(:,size(test_toy,2));

param(1) = 10;
param(2) = 0.1;
param(3) = 0.001;

info = kdlorAlgorithm.runAlgorithm(train,test,param);

fprintf('Accuracy Train %f, Accuracy Test %f\n',sum(train.targets==info.predictedTrain)/size(train.targets,1),sum(test.targets==info.predictedTest)/size(test.targets,1));
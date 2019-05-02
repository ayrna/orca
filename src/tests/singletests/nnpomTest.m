% Reference performance
accTestRef = 0.950000;
% Increase the error due to method's variability
allowedError = 0.10; 
method = 'NNPOM';

% Create the algorithm object
algorithmObj = NNPOM();

% Clear parameter struct
clear param;

% Parameter hiddenN (Number of neurons in the hidden layer)
param.hiddenN = 10;

% Parameter iter (Number of iterations)
param.iter = 1000;

% Parameter lambda (Regularization parameter)
param.lambda = 0.01;

% Run the algorithm
info = algorithmObj.fitpredict(train,test,param);

trainCM = confusionmat(info.predictedTrain,train.targets);
testCM = confusionmat(info.predictedTest,test.targets);

accTrain = CCR.calculateMetric(trainCM);
accTest  = CCR.calculateMetric(testCM);

% Report accuracy
fprintf('Performing test for %s\n', method);
fprintf('Accuracy Train %f, Accuracy Test %f\n',accTrain,accTest);

if abs(accTestRef-accTest)<allowedError
    fprintf('Test accuracy matches reference accuracy\n');
else
    warning('Test accuracy does NOT match reference accuracy');
end

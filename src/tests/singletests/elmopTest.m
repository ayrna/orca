% Reference performance
accTestRef = 0.920000;
% Increase the error due to method's variability
allowedError = 0.05; 
method = 'ELMOP';

% Create the algorithm object
algorithmObj = ELMOP();

% Clear parameter struct
clear param;

% Parameter hiddenN (Number of neurons in the hidden layer)
param.hiddenN = 50;

% Running the algorithm
info = algorithmObj.runAlgorithm(train,test,param);

trainCM = confusionmat(info.predictedTrain,train.targets);
testCM = confusionmat(info.predictedTest,test.targets);

accTrain = CCR.calculateMetric(trainCM);
accTest  = CCR.calculateMetric(testCM);

% Reporting accuracy
fprintf('.........................\n');
fprintf('Performing test for %s\n', method);
fprintf('Accuracy Train %f, Accuracy Test %f\n',accTrain,accTest);

if abs(accTestRef-accTest)<allowedError
    fprintf('Test accuracy matchs reference accuracy\n');
else
    error('Test accuracy does NOT match reference accuracy');
end

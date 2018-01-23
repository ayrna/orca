% Reference performance
accTestRef = 0.893333;
allowedError = 0.001;
method = 'SVORIM';

% Create the algorithm object
algorithmObj = SVORIM();

% Clear parameter struct
clear param;

% Parameter C (Cost)
param.C = 10;

% Parameter k (kernel width)
param.k = 1;

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

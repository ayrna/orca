% Reference performance
accTestRef = 0.293333;
allowedError = 0.001;
method = 'LIBLINEAR';

% Create the algorithm object
algorithmObj = LIBLINEAR();

% Clear parameter struct
clear param;

% Parameter C (Cost)
param.C = 0.10;

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

% Note: this code should be run from orca/src/code-examples
% Loading the data
trainMelanoma = load('../../exampledata/10-fold/melanoma-5classes-abcd-100/matlab/train_melanoma-5classes-abcd-100.2');
testMelanoma = load('../../exampledata/10-fold/melanoma-5classes-abcd-100/matlab/test_melanoma-5classes-abcd-100.2');

% Examining some targets
trainMelanoma([1:5 300:305],end)

% Complete set of data
melanoma = [trainMelanoma; testMelanoma];

% Number of patterns per class
n = hist(melanoma(:,end),5)

addpath ../Algorithms

% Form structures for training/test
train.patterns = trainMelanoma(:,1:(end-1));
train.targets = trainMelanoma(:,end);
test.patterns = testMelanoma(:,1:(end-1));
test.targets = testMelanoma(:,end);

%% Use the original dataset
% Create the POM object
algorithmObj = POM();

addpath ../Measures
%% Train POM
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
  fprintf('POM in octave fails with non-standardized data\n---------------\n');
else
  info = algorithmObj.fitpredict(train,test);
  fprintf('Original dataset\n---------------\n');
  fprintf('POM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
  fprintf('POM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));
end

%% Standarize data
addpath ../Utils
[trainStandarized,testStandarized] = DataSet.standarizeData(train,test);

% Check data
train.patterns(1:10,2:5)
trainStandarized.patterns(1:10,2:5)

% Run POM again with standarizeData
info = algorithmObj.fitpredict(trainStandarized,testStandarized);
fprintf('\nStandarized dataset\n---------------\n');
fprintf('POM Accuracy: %f\n', CCR.calculateMetric(info.predictedTest,test.targets));
fprintf('POM MAE: %f\n', MAE.calculateMetric(info.predictedTest,test.targets));

%% Standarize data and delete constant attributes or non numeric values
[train,test] = DataSet.deleteConstantAtributes(train,test);
[train,test] = DataSet.standarizeData(train,test);
[train,test] = DataSet.deleteNonNumericValues(train,test);
info = algorithmObj.fitpredict(train,test);
fprintf('\nStandarized dataset without constant attributes\n---------------\n');
fprintf('POM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('POM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

%% Now we apply SVR
algorithmObj = SVR();
info = algorithmObj.fitpredict(train,test,struct('C',10,'k',0.001,'e',0.01));
fprintf('\nSupport Vector Regression\n---------------\n');
fprintf('SVR Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVR MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));
info.projectedTest

fprintf('\nSupport Vector Regression parameters\n---------------\n');
bestAccuracy=0;
for C=10.^(-3:1:3)
    for k=10.^(-3:1:3)
        for e=10.^(-3:1:3)
            param = struct('C',C,'k',k,'e',e);
            info = algorithmObj.fitpredict(train,test,param);
            accuracy = CCR.calculateMetric(test.targets,info.predictedTest);
            if accuracy > bestAccuracy
                bestAccuracy = accuracy;
                bestParam = param;
            end
            fprintf('SVR C %f, k %f, e %f --> Accuracy: %f, MAE: %f\n' ...
                , C, k, e, accuracy, MAE.calculateMetric(test.targets,info.predictedTest));
        end
    end
end
fprintf('Best Results SVR C %f, k %f, e %f --> Accuracy: %f\n', bestParam.C, bestParam.k, bestParam.e, bestAccuracy);

%% For the exercise of cross validation
%algorithmObj = SVR();
%param = crossvalide(algorithmObj,train,5);
%param
%info = algorithmObj.fitpredict(train,test,param);
%fprintf('\nSupport Vector Regression with cross validated parameters\n---------------\n');
%fprintf('SVR Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
%fprintf('SVR MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

%% Nominal SVCs
algorithmObj = SVC1V1();
info = algorithmObj.fitpredict(train,test,struct('C',10,'k',0.001));
fprintf('\nSVC1V1\n---------------\n');
fprintf('SVC1V1 Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVC1V1 MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));
info.projectedTest

algorithmObj = SVC1VA();
info = algorithmObj.fitpredict(train,test,struct('C',10,'k',0.001));
fprintf('\nSVC1VA\n---------------\n');
fprintf('SVC1VA Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVC1VA MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));
info.projectedTest

%% Cost sensitive SVC
algorithmObj = CSSVC();
info = algorithmObj.fitpredict(train,test,struct('C',10,'k',0.001));
fprintf('\nCSSVC\n---------------\n');
fprintf('CSSVC Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('CSSVC MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));
info.projectedTest

%% SVM with ordered partitions and weights
algorithmObj = SVMOP();
info = algorithmObj.fitpredict(train,test,struct('C',10,'k',0.001));
fprintf('\nSVMOP\n---------------\n');
fprintf('SVMOP Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVMOP MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

%% Extreme learning machine with ordered partitions
algorithmObj = ELMOP('activationFunction','sig');
info = algorithmObj.fitpredict(train,test,struct('hiddenN',20));
fprintf('\nELMOP\n---------------\n');
fprintf('ELMOP Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('ELMOP MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

%% Neural network with ordered partitions
algorithmObj = NNOP();
info = algorithmObj.fitpredict(train,test,struct('hiddenN',20,'iter',500,'lambda',0.1));
fprintf('\nNNOP\n---------------\n');
fprintf('NNOP Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('NNOP MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

%% Ordinal projection based ensemble with SVORIM
algorithmObj = OPBE('base_algorithm','SVORIM');
info = algorithmObj.fitpredict(train,test,struct('C',10,'k',0.001));
fprintf('\nOPBE\n---------------\n');
fprintf('OPBE Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('OPBE MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

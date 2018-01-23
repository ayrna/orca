addpath ../
addpath ../Measures
addpath ../Algorithms

% Disable warnings
warning('off','MATLAB:nearlySingularMatrix')
warning('off','stats:mnrfit:IterOrEvalLimit')

% Loading the data
trainMelanoma = load('../../exampledata/10-fold/melanoma-5classes-abcd-100/matlab/train_melanoma-5classes-abcd-100.5');
testMelanoma = load('../../exampledata/10-fold/melanoma-5classes-abcd-100/matlab/test_melanoma-5classes-abcd-100.5');

% Form structures for training/test
train.patterns = trainMelanoma(:,1:(end-1));
train.targets = trainMelanoma(:,end);
test.patterns = testMelanoma(:,1:(end-1));
test.targets = testMelanoma(:,end);

% Preprocess the data
[train,test] = DataSet.deleteConstantAtributes(train,test);
[train,test] = DataSet.standarizeData(train,test);
[train,test] = DataSet.deleteNonNumericValues(train,test);

%% Apply POM model
% Create the POM object
algorithmObj = POM();

% Train POM
info = algorithmObj.runAlgorithm(train,test);

% Evaluate the model
fprintf('POM method\n---------------\n');
fprintf('POM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('POM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

% Visualize the projection
figure; hold on;
h = histogram(info.projectedTest,30);
y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,1)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);    
end
hold off;

% Check confusion matrix
confusionmat(test.targets,info.predictedTest)

% Visualize the projection with colors
figure; hold on;
Q = size(info.model.thresholds,1)+1;
for i=1:Q
    h = histogram(info.projectedTest(test.targets==i),'BinWidth',0.5);
end
y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,1)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);    
end
%legend('C1','C2','C3','C4','C5');
legend(arrayfun(@(num) sprintf('C%d', num), 1:Q, 'UniformOutput', false))
hold off;

% Visualize the cummulative probabilities
figure; hold on;
numPoints=300;
x = linspace(min(info.model.thresholds-3),max(info.model.thresholds+3),numPoints);
f = repmat(info.model.thresholds',numPoints,1) - repmat(x',1,Q-1);
cumProb = [1./(1+exp(-f)) ones(numPoints,1)]; %logit function
plot(x,cumProb,'-');
y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,1)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);    
end
hold off;

% Visualize the individual probabilities
figure; hold on;
prob = cumProb;
prob(:,2:end) = prob(:,2:end) - prob(:,1:(end-1));
plot(x,prob,'-');
y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,1)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);    
end
hold off;

%% Apply the NNPOM model
% Create the NNPOM object
algorithmObj = NNPOM();

% Train NNPOM
info = algorithmObj.runAlgorithm(train,test,struct('hiddenN',20,'iter',500,'lambda',0.1));

% Evaluate the model
fprintf('NNPOM method\n---------------\n');
fprintf('NNPOM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('NNPOM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

info.projectedTest

%% Apply the SVORIM model
% Create the SVORIM object
algorithmObj = SVORIM();

% Train SVORIM
info = algorithmObj.runAlgorithm(train,test,struct('C',10,'k',0.001));

% Evaluate the model
fprintf('SVORIM method\n---------------\n');
fprintf('SVORIM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVORIM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

% Store projections and thresholds (we will used them later)
svorimProjections = info.projectedTest;
svorimProjectionsTrain = info.projectedTrain;
svorimThresholds = info.model.thresholds;

%% Apply the SVOREX model
% Create the SVOREX object
algorithmObj = SVOREX();

% Train SVOREX
info = algorithmObj.runAlgorithm(train,test,struct('C',10,'k',0.001));

% Evaluate the model
fprintf('SVOREX methodt\n---------------\n');
fprintf('SVOREX Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVOREX MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

% Store projections and thresholds (we will used them later)
svorexProjections = info.projectedTest;
svorexProjectionsTrain = info.projectedTrain;
svorexThresholds = info.model.thresholds;

%% Represent both projections and thresholds
figure; hold on;
subplot(2,1,1)
plot(svorimProjections,test.targets, 'o');
y1=get(gca,'ylim');
for i=1:size(svorimThresholds,2)
    line([svorimThresholds(i) svorimThresholds(i)],y1,'Color',[1 0 0]);    
end
legend('SVORIM');
subplot(2,1,2)
plot(svorexProjections,test.targets, 'o');
y1=get(gca,'ylim');
for i=1:size(svorexThresholds,2)
    line([svorexThresholds(i) svorexThresholds(i)],y1,'Color',[1 0 0]);    
end
legend('SVOREX');
hold off;

%% Apply the SVORIM model improved
% Create the SVORIM object
algorithmObj = SVORIM();

% Train SVORIM
info = algorithmObj.runAlgorithm(train,test,struct('C',500,'k',0.001));

% Evaluate the model
fprintf('SVORIM method improved\n---------------\n');
fprintf('SVORIM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVORIM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

%% Apply the REDSVM model
% Create the REDSVM object
algorithmObj = REDSVM();
 
% Train REDSVM
info = algorithmObj.runAlgorithm(train,test,struct('C',10,'k',0.001));
 
% Evaluate the model
fprintf('REDSVM method\n---------------\n');
fprintf('REDSVM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('REDSVM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

%% REDSVM optimization 
% Note we change the comparison here to minimize and initialize
% bestMZE/bestAMAE to Inf
clear T Ts;

Metrics = {@MZE,@AMAE};
Ts = cell(size(Metrics,2),1);
for m = 1:size(Metrics,2)
    mObj = Metrics{m}();
    fprintf('Grid search to optimize %s for REDSVM\n', mObj.name);
    bestError=Inf;
    T = table();
    for C=10.^(-3:1:3)
        for k=10.^(-3:1:3)
            param = struct('C',C,'k',k);
            info = algorithmObj.runAlgorithm(train,test,param);
            error = mObj.calculateMetric(test.targets,info.predictedTest);

            if error < bestError
                bestError = error;
                bestParam = param;
            end
            param.error = error;
            T = [T; struct2table(param)];
            fprintf('.');
        end
    end
    Ts{m} = T;
    fprintf('\nBest Results REDSVM C %f, k %f --> %s: %f\n', bestParam.C, bestParam.k, mObj.name, bestError);
end

fprintf('Generating heat maps\n');
figure;
subplot(2,1,1)
h = heatmap(Ts{1},'C','k','ColorVariable','error');
title('MZE optimization for REDSVM');

subplot(2,1,2)
h = heatmap(Ts{2},'C','k','ColorVariable','error');
title('AMAE optimization for REDSVM');


%% Apply the KDLOR model 
% Create the KDLOR object
algorithmObj = KDLOR('kernelType','rbf');

% Train KDLOR
info = algorithmObj.runAlgorithm(train,test,struct('C',1,'k',0.001,'u',0.01));

% Evaluate the model
fprintf('KDLOR method\n---------------\n');
fprintf('KDLOR Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('KDLOR MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

MS.calculateMetric(test.targets,info.predictedTest)

confusionmat(test.targets,info.predictedTest)

% Visualize the projection with colors
figure; hold on;
Q = size(info.model.thresholds,1)+1;
for i=1:Q
    h = histogram(info.projectedTest(test.targets==i),30);
end
y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,1)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);    
end
%legend('C1','C2','C3','C4','C5');
legend(arrayfun(@(num) sprintf('C%d', num), 1:Q, 'UniformOutput', false))
hold off;

%% Apply the ORBoost model 
% Create the ORBoost object
algorithmObj = ORBoost('weights',true);

% Train ORBoost
info = algorithmObj.runAlgorithm(train,test);

% Evaluate the model
fprintf('ORBoost method\n---------------\n');
fprintf('ORBoost Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('ORBoost MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

MS.calculateMetric(test.targets,info.predictedTest)

confusionmat(test.targets,info.predictedTest)


%% Make an ensemble with SVORIM and SVOREX. The final decission by POM
% Construct a new dataset with the projections
newTrain.patterns = [svorexProjectionsTrain' svorimProjectionsTrain'];
newTrain.targets = train.targets;
newTest.patterns = [svorexProjections' svorimProjections'];
newTest.targets = train.targets;
% Preprocess the dataset
[newTrain,newTest] = DataSet.deleteConstantAtributes(newTrain,newTest);
[newTrain,newTest] = DataSet.standarizeData(newTrain,newTest);
[newTrain,newTest] = DataSet.deleteNonNumericValues(newTrain,newTest);
% Train the final POM model
algorithmObj = POM();
info = algorithmObj.runAlgorithm(newTrain,newTest);
% Evaluate the ensemble
fprintf('SVORIM+SVOREX+POM method\n---------------\n');
fprintf('SVORIM+SVOREX+POM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVORIM+SVOREX+POM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

scatter(newTrain.patterns(:,1),newTrain.patterns(:,2),7,newTrain.targets);
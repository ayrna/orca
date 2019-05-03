% Note: this code should be run from orca/src/code-examples
clear param;
addpath ../Utils
addpath ../Measures
addpath ../Algorithms

if (exist ('OCTAVE_VERSION', 'builtin') > 0)
  pkg load statistics
  try
    graphics_toolkit ('gnuplot')
  catch
    error('This code uses gnuplot for plotting. Please install gnuplot and restart Octave to run this code.')
  end
end

% Disable MATLAB warnings
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
info = algorithmObj.fitpredict(train,test);

% Evaluate the model
fprintf('POM method\n---------------\n');
fprintf('POM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('POM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

% Visualize the projection
figure; hold on;
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
    hist(info.projectedTest,30)
else
    h = histogram(info.projectedTest,30);
end
y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,2)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);
end
hold off;

% Check confusion matrix
confusionmat(test.targets,info.predictedTest)

% Visualize the projection with colors
figure; hold on;
Q = size(info.model.thresholds,2)+1;
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
  colors = {[102 170 215],[232, 152, 117],[183, 174, 105],[178, 130, 187],[173, 205, 131]};
  for i=1:Q
      plothist(info.projectedTest(test.targets==i),30,colors{i}/255);
  end
else
  for i=1:Q
      h = histogram(info.projectedTest(test.targets==i),'BinWidth',0.5);
  end
end
y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,2)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);
end
%legend('C1','C2','C3','C4','C5');
legend(arrayfun(@(num) sprintf('C%d', num), 1:Q, 'UniformOutput', false))
hold off;

% Visualize the cummulative probabilities
figure; hold on;
numPoints=300;
x = linspace(min(info.model.thresholds-3),max(info.model.thresholds+3),numPoints);
f = repmat(info.model.thresholds,numPoints,1) - repmat(x',1,Q-1);
cumProb = [1./(1+exp(-f)) ones(numPoints,1)]; %logit function
plot(x,cumProb,'-','LineWidth',1);
y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,2)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);
end
hold off;

% Visualize the individual probabilities
figure; hold on;
prob = cumProb;
prob(:,2:end) = prob(:,2:end) - prob(:,1:(end-1));
plot(x,prob,'-','LineWidth',1);
y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,2)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);
end
hold off;

%% Apply the NNPOM model
% Create the NNPOM object
algorithmObj = NNPOM();

% Train NNPOM
info = algorithmObj.fitpredict(train,test,struct('hiddenN',20,'iter',500,'lambda',0.1));

% Evaluate the model
fprintf('NNPOM method\n---------------\n');
fprintf('NNPOM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('NNPOM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

info.projectedTest

%% Apply the SVORIM model
% Create the SVORIM object
algorithmObj = SVORIM();

% Train SVORIM
info = algorithmObj.fitpredict(train,test,struct('C',10,'k',0.001));

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
info = algorithmObj.fitpredict(train,test,struct('C',10,'k',0.001));

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
info = algorithmObj.fitpredict(train,test,struct('C',500,'k',0.001));

% Evaluate the model
fprintf('SVORIM method improved\n---------------\n');
fprintf('SVORIM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVORIM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

%% Apply the REDSVM model
% Create the REDSVM object
algorithmObj = REDSVM();

% Train REDSVM
info = algorithmObj.fitpredict(train,test,struct('C',10,'k',0.001));

% Evaluate the model
fprintf('REDSVM method\n---------------\n');
fprintf('REDSVM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('REDSVM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

%% REDSVM optimization
clear param T Ts;

Metrics = {@MZE,@AMAE};
setC = 10.^(-3:1:3);
setk = 10.^(-3:1:3);
% TODO: fix for Octave since table() is not supported
Ts = cell(size(Metrics,2),1);
nFolds = 3;

if (exist ('OCTAVE_VERSION', 'builtin') > 0)
  pkg load statistics
end

CVO = cvpartition(train.targets,'KFold',nFolds);
for m = 1:size(Metrics,2)
    mObj = Metrics{m}();
    fprintf('Grid search to optimize %s for REDSVM\n', mObj.name);
    bestError=Inf;
    if (~exist ('OCTAVE_VERSION', 'builtin') > 0)
      T = table();
    end
    for C=10.^(-3:1:3)
        for k=10.^(-3:1:3)
            error=0;
            for ff = 1:nFolds
                param = struct('C',C,'k',k);
                info = algorithmObj.fitpredict(train,test,param);
                error = error + mObj.calculateMetric(test.targets,info.predictedTest);

            end
            error = error / nFolds;
            if error < bestError
                bestError = error;
                bestParam = param;
            end
            param.error = error;
            if (~exist ('OCTAVE_VERSION', 'builtin') > 0)
              T = [T; struct2table(param)];
            end
            fprintf('.');
        end
    end
    if (~exist ('OCTAVE_VERSION', 'builtin') > 0)
      Ts{m} = T;
    end
    fprintf('\nBest Results REDSVM C %f, k %f --> %s: %f\n', bestParam.C, bestParam.k, mObj.name, bestError);
end

if (exist ('OCTAVE_VERSION', 'builtin') > 0)
  fprintf('This type of graphic is not supported in Octave\n');
else
if verLessThan('matlab', '9.2')
    % Use contours
    figure;
    hold on;
    for m = 1:size(Metrics,2)
        mObj = Metrics{m}();
        subplot(size(Metrics,2),1,m)
        x = Ts{m}{:,1};
        y = Ts{m}{:,2};
        z = Ts{m}{:,3};
        numPoints=100;
        [xi, yi] = meshgrid(linspace(min(x),max(x),numPoints),linspace(min(y),max(y),numPoints));
        zi = griddata(x,y,z, xi,yi);
        contourf(xi,yi,zi,15);
        set(gca, 'XScale', 'log');
        set(gca, 'YScale', 'log');
        colorbar;
        title([mObj.name ' optimization for REDSVM']);
    end
    hold off;
else
    % Use heatmaps
    fprintf('Generating heat maps\n');
    figure;
    subplot(2,1,1)
    heatmap(Ts{1},'C','k','ColorVariable','error');
    title('MZE optimization for REDSVM');

    subplot(2,1,2)
    heatmap(Ts{2},'C','k','ColorVariable','error');
    title('AMAE optimization for REDSVM');
end
end

%% Apply the KDLOR model
% Create the KDLOR object
algorithmObj = KDLOR('kernelType','rbf');

% Train KDLOR
info = algorithmObj.fitpredict(train,test,struct('C',1,'k',0.001,'u',0.01));

% Evaluate the model
fprintf('KDLOR method\n---------------\n');
fprintf('KDLOR Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('KDLOR MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

MS.calculateMetric(test.targets,info.predictedTest)

confusionmat(test.targets,info.predictedTest)

% Visualize the projection with colors
figure; hold on;
Q = size(info.model.thresholds,2)+1;
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
  colors = {[102 170 215],[232, 152, 117],[183, 174, 105],[178, 130, 187],[173, 205, 131]};
  for i=1:Q
      plothist(info.projectedTest(test.targets==i),30,colors{i}/255);
  end
else
  for i=1:Q
      h = histogram(info.projectedTest(test.targets==i),30);
  end
end

y1=get(gca,'ylim');
for i=1:size(info.model.thresholds,2)
    line([info.model.thresholds(i) info.model.thresholds(i)],y1,'Color',[1 0 0]);
end
%legend('C1','C2','C3','C4','C5');
legend(arrayfun(@(num) sprintf('C%d', num), 1:Q, 'UniformOutput', false))
hold off;

%% Apply the ORBoost model
% Create the ORBoost object
algorithmObj = ORBoost('weights',true);

% Train ORBoost
info = algorithmObj.fitpredict(train,test);

% Evaluate the model
fprintf('ORBoost method\n---------------\n');
fprintf('ORBoost Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('ORBoost MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

MS.calculateMetric(test.targets,info.predictedTest)

confusionmat(test.targets,info.predictedTest)


%% Make an ensemble with SVORIM and SVOREX. The final decission by POM
% Construct a new dataset with the projections
newTrain.patterns = [svorexProjectionsTrain svorimProjectionsTrain];
newTrain.targets = train.targets;
newTest.patterns = [svorexProjections svorimProjections];
newTest.targets = train.targets;
% Preprocess the dataset
[newTrain,newTest] = DataSet.deleteConstantAtributes(newTrain,newTest);
[newTrain,newTest] = DataSet.standarizeData(newTrain,newTest);
[newTrain,newTest] = DataSet.deleteNonNumericValues(newTrain,newTest);
% Train the final POM model
algorithmObj = POM();
info = algorithmObj.fitpredict(newTrain,newTest);
% Evaluate the ensemble
fprintf('SVORIM+SVOREX+POM method\n---------------\n');
fprintf('SVORIM+SVOREX+POM Accuracy: %f\n', CCR.calculateMetric(test.targets,info.predictedTest));
fprintf('SVORIM+SVOREX+POM MAE: %f\n', MAE.calculateMetric(test.targets,info.predictedTest));

scatter(newTrain.patterns(:,1),newTrain.patterns(:,2),7,newTrain.targets);

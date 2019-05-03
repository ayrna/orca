function optimals = paramopt(alg, param, train, varargin)
% PARAMOPT Function to optimize a set of parameters of a method
%   in a specific train set.
%
%   OPTIMALS = PARAMOPT(ALG,PARAM,TRAIN) Divides the data in k-folds
%   (k defined by 'nfolds' with default value 5). Returns structure OPTIMALS
%   with optimal parameter(s) acording to 'metric' (default MAE).
%   OPTIMALS = PARAMOPT(ALG,PARAM,TRAIN,'metric',METRICCLASS, 'nfolds', K, 'seed', S )
%   uses METRICCLASS as parameters selection critera, K for k-fold, and S 
%   as base number seed for random number generation.
            
% Default values for optional parameters
opt.nfolds = 5;
opt.metric = MAE;
opt.seed = 1;
opt = parsevarargs(opt, varargin);

% Check data integrity
if  ~(isfield(train, 'patterns') && isfield(train, 'targets'))
    error('Please, provide a valid train structure.')
else
    if size(train.targets,1)~=size(train.patterns,1)
        error('Number of patterns and labels must match.')
    end
end

% Check name and type of parameters
checkParameters(alg, param);

name_parameters = fieldnames(param);
nParam = numel(name_parameters);
sets = struct2cell(param);

c = cell(1, numel(sets));
[c{:}] = ndgrid( sets{:} );
combinations = cell2mat( cellfun(@(v)v(:), c, 'UniformOutput',false) );
combinations = combinations';

% Avoid problems with very low number of patterns for some
% classes
uniqueTargets = unique(train.targets);
nOfPattPerClass = sum(repmat(train.targets,1,size(uniqueTargets,1))==repmat(uniqueTargets',size(train.targets,1),1));
for i=1:size(uniqueTargets,1)
    if(nOfPattPerClass(i)==1)
        train.patterns = [train.patterns; train.patterns(train.targets==uniqueTargets(i),:)];
        train.targets = [train.targets; train.targets(train.targets==uniqueTargets(i),:)];
        [train.targets,idx] = sort(train.targets);
        train.patterns = train.patterns(idx,:);
    end
end

% Use the seed
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
    rand('seed',opt.seed);
else
    s = RandStream.create('mt19937ar','seed',opt.seed);
    if verLessThan('matlab','8.0')
        RandStream.setDefaultStream(s);
    else
        RandStream.setGlobalStream(s);
    end
end

if (exist ('OCTAVE_VERSION', 'builtin') > 0)
    pkg load statistics;
    CVO = cvpartition(train.targets,'KFold',opt.nfolds);
    numTests = get(CVO,'NumTestSets');
else
    CVO = cvpartition(train.targets,'k',opt.nfolds);
    numTests = CVO.NumTestSets;
end
result = zeros(numTests,size(combinations,2));

% Foreach fold
for ff = 1:numTests
    % Build fold dataset
    if (exist ('OCTAVE_VERSION', 'builtin') > 0)
        trIdx = training(CVO,ff);
        teIdx = test(CVO,ff);
    else
        trIdx = CVO.training(ff);
        teIdx = CVO.test(ff);
    end
    
    auxTrain.targets = train.targets(trIdx,:);
    auxTrain.patterns = train.patterns(trIdx,:);
    auxTest.targets = train.targets(teIdx,:);
    auxTest.patterns = train.patterns(teIdx,:);
    for i=1:size(combinations,2)
        % Extract the combination of parameters
        currentCombination = combinations(:,i);
        
        if nParam~= 0
            currentCombination = reshape(currentCombination,[1,nParam]);
            param = cell2struct(num2cell(currentCombination(1:nParam)),name_parameters,2);
        else
            param = [];
        end
        
        model = alg.fitpredict(auxTrain, auxTest, param);
        
        result(ff,i) = opt.metric.calculateCrossvalMetric(auxTest.targets, model.predictedTest);
    end
    
end
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
    pkg unload statistics;
end

[bestValue,bestIdx] = min(mean(result));
optimalCombination = combinations(:,bestIdx);

if nParam~= 0
    optimalCombination = reshape(optimalCombination,[1,nParam]);
    optimals = cell2struct(num2cell(optimalCombination(1:nParam)),name_parameters,2);
else
    optimals = [];
end

end

function checkParameters(obj, param)
paramNames = fieldnames(param);

for i = 1:length(paramNames)
    inpName = paramNames{i};
    if isfield(obj.parameters,inpName)
        % check type
        if ~strcmp(class(obj.parameters.(inpName)), class(param.(inpName)(1)))
            msg = sprintf('Data type of property ''%s'' (%s) not compatible with data type (%s) of assigned value in configuration file', ...
                    inpName, class(obj.parameters.(inpName)), class(param.(inpName)(1)));
            error(msg);
        end
    else
        error('Error ''%s'' is not a recognized class parameter name',inpName)
    end
end
end


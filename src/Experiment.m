classdef Experiment < handle
    %EXPERIMENT creates an experiment to run an ORCA's experiment which
    %   consist on optimising and running a method in fold (a pair of train-test
    %   dataset partition). Theexperiment is described by a configuration file.
    %   This class is used by Utilities to launch a set of experiments
    %
    %   EXPERIMENT properties:
    %      data               - DataSet object to store the train/test data
    %      method             - Method to learn and classify data
    %      cvCriteria         - Metric to guide the grid search for parameters optimisation
    %      resultsDir         - Directory to store performance reports and learned models
    %      seed               - Seed to be used for random number generation
    %      crossvalide        - Activate corssvalidation
    %
    %   EXPERIMENT methods:
    %      launch             - Launch experiment described in file
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    %
    properties
        data = DataSet;
        method = Algorithm;
        cvCriteria = MAE;
        crossvalide = 0;
        resultsDir = '';
        seed = 1;
        parameters; % parameters to optimize
    end
    
    properties (SetAccess = private)
        
        logsDir
    end
    
    methods
        function obj = launch(obj,expFile)
            % LAUNCH Launch experiment described in file.
            %   EXPOBJ = LAUNCH(EXPFILE) parses EXPFILE and run the experiment
            %   described on it. It performs the following steps:
            %   # Preprocess data cleaning and standardization (option need to be actived in configuration file)
            %   # Optimize parameters by performing a grid search (if selected
            %   in configuration file)
            %   # Run algorithm with optimal parameters (if crossvalidation was
            %   selected)
            %   # Save experiment results for the fold
            obj.process(expFile);
            obj.run();
        end
    end
    
    methods(Access = private)
        
        function obj = run(obj)
            % RUN do experiment steps: data cleaning and standardization, parameters
            %   optimization and save results
            [train,test] = obj.data.preProcessData();
            
            if obj.crossvalide
                c1 = clock;
                Optimals = obj.crossValideParams(train);
                c2 = clock;
                crossvaltime = etime(c2,c1);
                totalResults = obj.method.runAlgorithm(train, test, Optimals);
                totalResults.crossvaltime = crossvaltime;
            else
                totalResults = obj.method.runAlgorithm(train, test);
            end
            
            obj.saveResults(totalResults);
            
        end
        
        function obj = process(obj,fname)
            % PROCESS parses experiment described in FNAME
            cObj = Config(fname);
            expObj = cObj.exps{:};
            % Copy ini values to corresponding object properties
            
            % General experiment properties
            try
                obj.data.directory = expObj.general('directory');
                obj.data.train = expObj.general('train');
                obj.data.test = expObj.general('test');
                obj.resultsDir = expObj.general('results');
                obj.data.nOfFolds = str2num(expObj.general('num_folds'));
                obj.data.standarize = str2num(expObj.general('standarize'));
                met = upper(expObj.general('cvmetric'));
                eval(['obj.cvCriteria = ' met ';']);
                obj.seed = str2num(expObj.general('seed'));
            catch ME
                error('Configuration file %s does not have mininum fields. Exception %s', fname, ME.identifier)
            end
            
            % Algorithm properties are transformed to varargs ('key',value)
            %expObj.algorithm('foo') = 'var'
            %varargs = mapsToString2(expObj.algorithm, expObj.parameters);
            try
                varargs = obj.mapsToCell(expObj.algorithm);
                alg = expObj.algorithm('algorithm');
            catch ME % TODO: refine error unknown algorithm vs bad parameters
                switch ME.identifier
                    case 'MATLAB:Containers:Map:NoKey'
                        error('Algorithm is not defined in configuration file')
                    otherwise
                        error('Unknown error: %s', ME.identifier)
                end
            end
            
            obj.method = feval(alg, varargs);
            try
                obj.method = feval(alg, varargs);
            catch ME
                switch ME.identifier
                    case 'MATLAB:noPublicFieldForClass'
                        rethrow(ME)
                    case 'MATLAB:UndefinedFunction'
                        error('Unknown method ''%s'' in configuration file', alg)
                    case 'ORCA:InconsistentDataType'
                        error('Error: %s. %s', ME.identifier, ME.message)
                    otherwise
                        error('Unknown error. Error: %s. %s', ME.identifier, ME.message)
                end
            end
            
            % Parameters to be optimized
            if ~isempty(expObj.params)
                pkeys = expObj.params.keys;
                for p=1:cast(expObj.params.Count,'int32')
                    %isfield(obj.parameters.' pkeys{p})
                    eval(['obj.parameters.' pkeys{p} ' = [' expObj.params(pkeys{p}) '];']);
                    obj.crossvalide = 1;
                end
            end
        end
        
        function obj = saveResults(obj,TotalResults)
            % SAVERESULTS saves the results of the experiment and
            % the best hyperparameters.
            
            par = obj.method.getParameterNames();
            if ~isempty(par)
                outputFile = [obj.resultsDir filesep 'OptHyperparams' filesep obj.data.dataname ];
                fid = fopen(outputFile,'w');
                
                for i=1:(numel(par))
                    value = getfield(TotalResults.model.parameters,par{i});
                    fprintf(fid,'%s,%f\n', par{i},value);
                end
                
                fclose(fid);
            end
            
            outputFile = [obj.resultsDir filesep 'Times' filesep obj.data.dataname ];
            fid = fopen(outputFile,'w');
            if obj.crossvalide
                fprintf(fid, '%f\n%f\n%f', TotalResults.trainTime, TotalResults.testTime, TotalResults.crossvaltime);
            else
                fprintf(fid, '%f\n%f\n%f', TotalResults.trainTime, TotalResults.testTime, 0);
            end
            fclose(fid);
            
            
            outputFile = [obj.resultsDir filesep 'Predictions' filesep obj.data.train ];
            dlmwrite(outputFile, TotalResults.predictedTrain);
            outputFile = [obj.resultsDir filesep 'Predictions' filesep obj.data.test ];
            dlmwrite(outputFile, TotalResults.predictedTest);
            
            model = TotalResults.model;
            % Write complete model
            outputFile = [obj.resultsDir filesep 'Models' filesep obj.data.dataname '.mat'];
            save(outputFile, 'model');
            
            outputFile = [obj.resultsDir filesep 'Guess' filesep obj.data.train ];
            dlmwrite(outputFile, TotalResults.projectedTrain, 'precision', '%.15f');
            
            outputFile = [obj.resultsDir filesep 'Guess' filesep obj.data.test ];
            dlmwrite(outputFile, TotalResults.projectedTest, 'precision', '%.15f');
            
        end
        
        
        function optimals = crossValideParams(obj,train)
            % CROSSVALIDE Function for performing the crossvalidation in a specific train partition.
            %
            %   OPTIMALS = CROSSVALIDEPARAMS(TRAIN) Divides each the data in k-folds
            %   (k defined by 'num fold' in configuration file). Returns vector OPTIMALS
            %   with optimal parameter(s)
            nOfFolds = obj.data.nOfFolds;
            %parameters = obj.parameters;
            %par = fieldnames(parameters);
            
            sets = struct2cell(obj.parameters);
            name_parameters = fieldnames(obj.parameters);
            nParam = numel(name_parameters);
            
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
                rand('seed',obj.seed);
            else
                s = RandStream.create('mt19937ar','seed',obj.seed);
                if verLessThan('matlab','8.0')
                    RandStream.setDefaultStream(s);
                else
                    RandStream.setGlobalStream(s);
                end
            end
            
            if (exist ('OCTAVE_VERSION', 'builtin') > 0)
                pkg load statistics;
                CVO = cvpartition(train.targets,'KFold',nOfFolds);
                numTests = get(CVO,'NumTestSets');
            else
                CVO = cvpartition(train.targets,'k',nOfFolds);
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
                    
                    model = obj.method.runAlgorithm(auxTrain, auxTest, param);
                    
                    if strcmp(obj.cvCriteria.name,'Area under curve')
                        result(ff,i) = obj.cvCriteria.calculateCrossvalMetric(auxTest.targets, model.projectedTest);
                    else
                        result(ff,i) = obj.cvCriteria.calculateCrossvalMetric(auxTest.targets, model.predictedTest);
                    end
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
        
    end
    
    methods (Static = true)

        function varargs = mapsToCell(aObj)
            %varargs = mapsToCell(mapObj) returns key value pairs in a comma separated
            %   string. Example: "'kernel', 'rbf', 'c', 0.1"
            mapObj = containers.Map(aObj.keys,aObj.values);
            mapObj.remove('algorithm');
            pkeys = mapObj.keys;
            varargs = cell(1,cast(mapObj.Count,'int32')*2);
            for p=1:2:cast(mapObj.Count,'int32')*2
                value = mapObj.values(pkeys(p));
                value = value{:};
                varargs{1,p} = sprintf('%s', pkeys{p});
                % Check numerical values
                valuenum = str2double(value);
                if isnan(valuenum) % we have a string
                    varargs{1,p+1} = sprintf('%s', value);
                else % we have a number
                    varargs{1,p+1} = valuenum;
                end
                %     if isempty(varargs)
                %         varargs{1,p} = sprintf('''%s'',%s', pkeys{p},value);
                %     else
                %         varargs = sprintf('%s,''%s'',%s',varargs, pkeys{p},value);
                %     end
            end
        end
    end
    
    
end

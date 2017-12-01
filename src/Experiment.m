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
        method = KDLOR;
        cvCriteria = MAE;
        crossvalide = 0;
        resultsDir = '';
        seed = 1;
        
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
            try
                [keys,sections,subsections] = inifile(fname,'readall');
            catch ME
                error('Cannot read or parse %s. \nError: %s', confFile, ME.identifier)
            end
            
            % Extract keys for each experiment
            %experiment = keys(strcmp(keys(:, 1), sections{i}), :);
            valueSet = keys(:,4);
            keySet = keys(:,3);
            mapObj = containers.Map(keySet,valueSet);
            
            % Copy ini values to corresponding object properties
            try
                obj.data.directory = mapObj('general-conf@directory');
                obj.data.train = mapObj('general-conf@train');
                obj.data.test = mapObj('general-conf@test');
                obj.resultsDir = mapObj('general-conf@results');
                obj.data.nOfFolds = str2num(mapObj('general-conf@num_fold'));
                obj.data.standarize = str2num(mapObj('general-conf@standarize'));
                met = upper(mapObj('general-conf@crossval'));
                eval(['obj.cvCriteria = ' met ';']);
                obj.seed = str2num(mapObj('general-conf@seed'));
            catch ME
                error('Configuration file %s does not have mininum fields. Exception %s', fname, ME.identifier)
            end
            
            alg = mapObj('algorithm-parameters@algorithm');
            try
                eval(['obj.method = ' alg ';']);
                obj.method.defaultParameters();
            catch
                error('Unknown algorithm')
            end
                
            % TODO: These parameters loading should be moved to Algorithms classes
            % Those classes should check they have necessary parameters
            % description to be created and provide default values
            % otherwise. There, it would be easier to generalize the
            % code
            if mapObj.isKey('algorithm-parameters@weights')
                wei = mapObj('algorithm-parameters@weights');
                eval(['obj.method.weights = ' wei ';']);
            end
            if mapObj.isKey('algorithm-parameters@kernel')
                obj.method.kernelType = mapObj('algorithm-parameters@kernel');
            end
            if mapObj.isKey('algorithm-parameters@activationFunction')
                obj.method.activationFunction = mapObj('algorithm-parameters@activationFunction');
            end
            
            % Parameters to optimize
            % Extract keys of parameters to optimize
            keysc = mapObj.keys;
            keysc(cellfun('isempty', keysc)) = {''};
            logicalArray = ~cellfun('isempty', strfind(keysc, 'algorithm-hyper-parameters-to-cv'));
            keysOpt = keysc(logicalArray);
            for keysc=1:length(keysOpt)
                nameparameter = regexp(keysOpt{keysc}, '\w*@(\w*)', 'tokens');
                nameparameter = nameparameter{:};
                nameparameter = nameparameter{:};
                %TODO: ALL IN LOWERCASE nameparameter = lower(nameparameter{:});
                eval(['obj.method.parameters.' nameparameter ' = [' mapObj(keysOpt{keysc}) '];']);
                obj.crossvalide = 1;
            end
            %
            %                 elseif strncmpi('parameter', new_line, 5)
            %                     %TODO
            %                     nameparameter = sscanf(new_line, 'parameter %s');
            %                     val = fgetl(fid);
            %                     if sum(strcmp(nameparameter,obj.method.name_parameters))
            %                         eval(['obj.method.parameters.' nameparameter ' = [' val '];']);
            %                         obj.crossvalide = 1;
            %                     else
            %                         error('Wrong parameter name - not found');
            %                     end
            %
            %
            %
            %
            %                 end
            
            
            % Fix user bad configuration
            if(obj.crossvalide == 0 && numel(obj.method.name_parameters)~=0 ...
                    && ~strcmpi(obj.method.name_parameters,'dummy'))
                obj.crossvalide = 1;
                obj.method.defaultParameters();
                disp('No parameter info found - setting up default parameters.')
            end
            
        end
        
        function obj = saveResults(obj,TotalResults)
            % SAVERESULTS saves the results of the experiment and
            % the best hyperparameters.
            
            if numel(obj.method.name_parameters)~=0
                outputFile = [obj.resultsDir filesep 'OptHyperparams' filesep obj.data.dataname ];
                fid = fopen(outputFile,'w');
                
                par = fieldnames(TotalResults.model.parameters);
                
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
            parameters = obj.method.parameters;
            par = fieldnames(parameters);
            
            sets = struct2cell(parameters);
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
                    model = obj.method.runAlgorithm(auxTrain, auxTest, currentCombination);
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
            optimals = combinations(:,bestIdx);
            
        end
        
    end
    
    
end

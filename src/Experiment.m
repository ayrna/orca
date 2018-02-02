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
        % calculate metrics with the sum of matrices (only suitable for 
        % k-fold experimental design)
        report_sum = 0; 
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
            if expObj.general.isKey('num_folds')
                obj.data.nOfFolds = str2num(expObj.general('num_folds'));
            end
            if expObj.general.isKey('standarize')
                obj.data.standarize = str2num(expObj.general('standarize'));
            end
            if expObj.general.isKey('cvmetric')
                met = upper(expObj.general('cvmetric'));
                eval(['obj.cvCriteria = ' met ';']);
            end
            if expObj.general.isKey('seed')
                obj.seed = str2num(expObj.general('seed'));
            end
            if expObj.general.isKey('report_sum')
                obj.report_sum = str2num(expObj.general('report_sum'));
            end
            
            try
                obj.data.directory = expObj.general('directory');
                obj.data.train = expObj.general('train');
                obj.data.test = expObj.general('test');
                obj.resultsDir = expObj.general('results');
            catch ME
                error('Configuration file %s does not have mininum fields. Exception %s', fname, ME.identifier)
            end
            
            % Algorithm properties are transformed to varargs ('key',value)
            varargs = obj.mapsToCell(expObj.algorithm);
            alg = expObj.algorithm('algorithm');
            obj.method = feval(alg, varargs);
            
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
            % CROSSVALIDEPARAMS Function for performing the crossvalidation in a specific train partition.
            %
            %   OPTIMALS = CROSSVALIDEPARAMS(TRAIN) Divides the data in k-folds
            %   (k defined by 'num fold' in configuration file). Returns 
            %   structure OPTIMALS with optimal parameter(s)
            optimals = paramopt(obj.method,obj.parameters,train, 'metric', obj.cvCriteria,...
                                'nfolds', obj.data.nOfFolds, 'seed', obj.seed);

        end
        
    end
    
    methods (Static = true)
        
        function varargs = mapsToCell(aObj)
            %varargs = mapsToCell(mapObj) returns key value pairs in a comma separated
            %   string. Example: "'kernel', 'rbf', 'c', 0.1"
            
            % If there are no parameters return empty cell
            if aObj.Count == 1
                varargs = cell(1,1);
                return
            end
            
            mapObj = containers.Map(aObj.keys,aObj.values);
            mapObj.remove('algorithm');
            pkeys = mapObj.keys;
            varargs = cell(1,cast(mapObj.Count,'int32')*2);
            
            for p=1:2:(cast(mapObj.Count,'int32')*2)
                p = cast(p,'int32');
                keyasstr = pkeys(p/2);
                keyasstr = keyasstr{:};
                value = mapObj(keyasstr);
                varargs{1,p} = sprintf('%s', pkeys{p/2});
                % Check numerical values
                valuenum = str2double(value);
                if isnan(valuenum) % we have a string
                    varargs{1,p+1} = sprintf('%s', value);
                else % we have a number
                    varargs{1,p+1} = valuenum;
                end
            end
        end
    end
    
    
end

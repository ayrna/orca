classdef Utilities < handle
    %UTILITIES Static class that contains several methods for configurating
    %   and running the experiments. It allows experiments CPU parallelization.
    %   Examples of integration with HTCondor are provided src/condor folder.
    %
    %   UTILITIES methods:
    %      runExperiments             - setting and running experiments
    %      runExperimentFold          - Launchs a single experiment fold
    %      configureExperiment        - sets configuration of the several experiments
    %      results                    - creates experiments reports
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    
    properties
        
    end
    
    
    methods (Static = true)
        function [logsDir] = runExperiments(expFile, varargin)
            % RUNEXPERIMENTS Function for setting and running the experiments
            %   [LOGSDIR] = RUNEXPERIMENTS(EXPFILE) runs
            %   experiments described in EXPFILE and returns the folder
            %   name LOGSDIR that stores all the results. LOGSDIR is
            %   generated based on the date and time of the system.
            %
            %   [LOGSDIR] = RUNEXPERIMENTS(EXPFILE, options) runs
            %   experiments described in EXPFILE and returns the folder
            %   name LOGSDIR that stores all the results. Options are:
            %       - 'parallel': 'false' or 'true' to activate CPU parallel
            %         processing of databases's folds. Default is 'false'
            %       - 'numcores': default maximum number of cores or desired
            %         number. If parallel = 1 and numcores <2 it sets the number
            %         to maximum number of cores.
            %       - 'closepool': whether to close or not the pool after
            %         experiments. Default 'true'. Disabling it can speed
            %         up consecutive calls to runExperiments.
            %
            %  Examples:
            %
            %  Runs parallel folds with 3 workers:
            %   Utilities.runExperiments('tests/cvtests-30-holdout/kdlor.ini', 'parallel', 1, 'numcores', 3)
            %  Runs parallel folds with max workers:
            %   Utilities.runExperiments('tests/cvtests-30-holdout/kdlor.ini', 'parallel', 1)
            %  Runs parallel folds with max workers and do not close the
            %  pool:
            %   Utilities.runExperiments('tests/cvtests-30-holdout/kdlor.ini', 'parallel', 1, 'closepool', false)
            %   Utilities.runExperiments('tests/cvtests-30-holdout/svorim.ini', 'parallel', 1, 'closepool', false)
            %
            addpath(fullfile(fileparts(which('Utilities.m')),'../Measures'));
            addpath(fullfile(fileparts(which('Utilities.m')),'../Algorithms'));
            
            disp('Setting up experiments...');
            
            % TODO: move ID generation to configureExperiment?
            c = clock;
            dirSuffix = [num2str(c(1)) '-' num2str(c(2)) '-'  num2str(c(3)) '-' num2str(c(4)) '-' num2str(c(5)) '-' num2str(uint8(c(6)))];
            logsDir = Utilities.configureExperiment(expFile,dirSuffix);
            expFiles = dir([logsDir '/' 'exp-*']);
            
            % Parse options.
            op = Utilities.parseParArgs(varargin);
            myExperiment = Experiment;
            
            report_sum = zeros(numel(expFiles),1);
            
            if op.parallel
                Utilities.preparePool(op.numcores)
                if (exist ('OCTAVE_VERSION', 'builtin') > 0)
                    logsCell = cell(numel(expFiles),1);
                    logsCell(:) = logsDir;
                    report_sum = parcellfun(op.numcores,@(varargin) Utilities.octaveParallelAuxFunction(varargin{:}),num2cell(expFiles),logsCell);
                else
                    parfor i=1:numel(expFiles)
                        if ~strcmp(expFiles(i).name(end), '~')
                            report_sum(i) = Utilities.octaveParallelAuxFunction(expFiles(i), logsDir);
                        end
                    end
                end
                
                Utilities.closePool()
            else
                for i=1:numel(expFiles)
                    if ~strcmp(expFiles(i).name(end), '~')
                        %disp(['Running experiment ', expFiles(i).name]);
                        %myExperiment.launch([logsDir '/' expFiles(i).name]);
                        report_sum(i) = Utilities.octaveParallelAuxFunction(expFiles(i), logsDir);
                    end
                end
            end
            
            disp('Calculating results...');
            % If any ini file activates the flag, the results are processed
            % with the 'report_sum = 1' flag. 
            report_sum_flag = any(report_sum);
            % Train results (note last argument)
            Utilities.results([logsDir '/' 'Results'],'report_sum', report_sum_flag, 'train', true);
            % Test results
            Utilities.results([logsDir '/' 'Results'], 'report_sum', report_sum_flag);
            %rmpath('../Measures');
            %rmpath('../Algorithms');
            
        end
        
        function [report_sum] = octaveParallelAuxFunction(experimentToRun,logsDir)
            % OCTAVEPARALLELAUXFUNCTION Function for running one experiment file
            %   It is used in Octave because it Octave does not have parfor
            %   OCTAVEPARALLELAUXFUNCTION(EXPERIMENT,LOGSDIR) run the experiment
            %   named EXPERIMENT and contained in the folder LOGSDIR
            if ~strcmp(experimentToRun.name(end), '~')
                myExperiment = Experiment;
                disp(['Running experiment ', experimentToRun.name]);
                myExperiment.launch([logsDir '/' experimentToRun.name]);
                report_sum = myExperiment.report_sum;
            end
        end
        
        function results(experiment_folder,varargin)
            % RESULTS Function for computing the results
            %   RESULTS(EXPERIMENT_FOLDER) computes results of predictions
            %   stored in EXPERIMENT_FOLDER. It generates CSV files with
            %   several performance metrics of the testing (generalization)
            %   predictions.
            %       * |mean-results_test.csv|: CSV file with datasets in files
            %       and performance metrics in columns. For each metric two columns
            %       are created (mean and standard deviation considering the _k_ folds
            %       of the experiment).
            %       * |mean-results_matrices_sum_test.csv|: CSV file with
            %       performance metrics calculated using the sum of all the
            %       confussion matrices of the _k_ experiments (as Weka does). Each column
            %       presents the performance of this single matrix.
            %
            %   RESULTS(EXPERIMENT_FOLDER,'TRAIN', true) same as
            %   RESULTS(EXPERIMENT_FOLDER) but calculates performance in train
            %   data. It can be usefull to evaluate overfitting.
            %
            %   See also MEASURES/MZE, MEASURES/MAE, MEASURES/AMAE, MEASURES/CCR,
            %   MEASURES/MMAE, MEASURES/GM, MEASURES/MS, MEASURES/Spearman,
            %   MEASURES/Tkendall, MEASURES/Wkappa
            
            addpath(fullfile(fileparts(which('Utilities.m')),'../Measures'));
            addpath(fullfile(fileparts(which('Utilities.m')),'../Algorithms'));
            
            opt.train = false;
            opt.report_sum = false;
            
            opt = parsevarargs(opt, varargin);
            
            experiments = dir(experiment_folder);
            
            for i=1:numel(experiments)
                if ~(any(strcmp(experiments(i).name, {'.', '..'}))) && experiments(i).isdir
                    disp([experiment_folder '/' experiments(i).name '/' 'dataset'])
                    fid = fopen([experiment_folder '/' experiments(i).name '/' 'dataset'],'r');
                    datasetPath = fgetl(fid);
                    fclose(fid);
                    
                    if opt.train
                        predicted_files = dir([experiment_folder '/' experiments(i).name '/' 'Predictions' '/' 'train_*']);
                    else
                        predicted_files = dir([experiment_folder '/' experiments(i).name '/' 'Predictions' '/' 'test_*']);
                    end
                    % Check if we have a missing fold experiment.
                    % -2 is to compensate . and ..
                    predicted_files_train = dir([experiment_folder '/' experiments(i).name '/' 'Predictions' '/' 'train_*']);
                    predicted_files_test = dir([experiment_folder '/' experiments(i).name '/' 'Predictions' '/' 'test_*']);
                    
                    if (numel(predicted_files_train)+numel(predicted_files_test)) ~= numel(dir(datasetPath)) -2
                        warning(sprintf('\n *********** \n The execution of some folds failed. Number of experiments differs from number of train-test files. \n *********** \n'))
                    end
                    time_files = dir([experiment_folder '/' experiments(i).name '/' 'Times' '/' '*.*']);
                    hyp_files = dir([experiment_folder '/' experiments(i).name '/' 'OptHyperparams' '/' '*.*']);
                    
                    if opt.train
                        guess_files = dir([experiment_folder '/' experiments(i).name '/' 'Guess' '/' 'train_*']);
                    else
                        guess_files = dir([experiment_folder '/' experiments(i).name '/' 'Guess' '/' 'test_*']);
                    end
                    
                    % Discard "." and ".."
                    if ~(exist ('OCTAVE_VERSION', 'builtin') > 0)
                        time_files = time_files(3:numel(time_files));
                        hyp_files = hyp_files(3:numel(hyp_files));
                    end
                    
                    if opt.train
                        real_files = dir([datasetPath '/' 'train_*']);
                    else
                        real_files = dir([datasetPath '/' 'test_*']);
                    end
                    
                    act = cell(1, numel(predicted_files));
                    pred = cell(1, numel(predicted_files));
                    proj = cell(1, numel(guess_files));
                    
                    times = zeros(3,numel(predicted_files));
                    param = [];
                    
                    for j=1:numel(predicted_files)
                        pred{j} = importdata([experiment_folder '/' experiments(i).name '/' 'Predictions' '/' predicted_files(j).name]);
                        times(:,j) = importdata([experiment_folder '/' experiments(i).name '/' 'Times' '/' time_files(j).name]);
                        proj{j} = importdata([experiment_folder '/' experiments(i).name '/' 'Guess' '/' guess_files(j).name]);
                        
                        if ~isempty(hyp_files)
                            struct_hyperparams(j) = importdata([experiment_folder '/' experiments(i).name '/' 'OptHyperparams' '/' hyp_files(j).name],',');
                            for z = 1:numel(struct_hyperparams(j).data)
                                param(z,j) = struct_hyperparams(j).data(z);
                            end
                        end
                        actual = importdata([datasetPath '/' real_files(j).name]);
                        act{j} = actual(:,end);
                    end
                    
                    names = {'Dataset', 'Acc', 'GM', 'MS', 'MAE', 'AMAE', 'MMAE','RSpearman', 'Tkendall', 'Wkappa', 'TrainTime', 'TestTime', 'CrossvalTime'};
                    
                    if ~isempty(hyp_files)
                        for j=1:numel(struct_hyperparams(1).textdata)
                            names{numel(names)+1} = struct_hyperparams(1).textdata{j};
                        end
                    end
                    
                    if exist ('OCTAVE_VERSION', 'builtin') > 0
                        accs = cell2mat(cellfun(@(varargin) CCR.calculateMetric(varargin{:}), act, pred, 'UniformOutput', false)) * 100;
                        gms = cell2mat(cellfun(@(varargin) GM.calculateMetric(varargin{:}), act, pred, 'UniformOutput', false)) * 100;
                        mss = cell2mat(cellfun(@(varargin) MS.calculateMetric(varargin{:}), act, pred, 'UniformOutput', false)) * 100;
                        maes = cell2mat(cellfun(@(varargin) MAE.calculateMetric(varargin{:}), act, pred, 'UniformOutput', false));
                        amaes = cell2mat(cellfun(@(varargin) AMAE.calculateMetric(varargin{:}), act, pred, 'UniformOutput', false));
                        maxmaes = cell2mat(cellfun(@(varargin) MMAE.calculateMetric(varargin{:}), act, pred, 'UniformOutput', false));
                        spearmans = cell2mat(cellfun(@(varargin) Spearman.calculateMetric(varargin{:}), act, pred, 'UniformOutput', false));
                        kendalls = cell2mat(cellfun(@(varargin) Tkendall.calculateMetric(varargin{:}), act, pred, 'UniformOutput', false));
                        wkappas = cell2mat(cellfun(@(varargin) Wkappa.calculateMetric(varargin{:}), act, pred, 'UniformOutput', false));
                    else
                        accs = cell2mat(cellfun(@CCR.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                        gms = cell2mat(cellfun(@GM.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                        mss = cell2mat(cellfun(@MS.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                        maes = cell2mat(cellfun(@MAE.calculateMetric, act, pred, 'UniformOutput', false));
                        amaes = cell2mat(cellfun(@AMAE.calculateMetric, act, pred, 'UniformOutput', false));
                        maxmaes = cell2mat(cellfun(@MMAE.calculateMetric, act, pred, 'UniformOutput', false));
                        spearmans = cell2mat(cellfun(@Spearman.calculateMetric, act, pred, 'UniformOutput', false));
                        kendalls = cell2mat(cellfun(@Tkendall.calculateMetric, act, pred, 'UniformOutput', false));
                        wkappas = cell2mat(cellfun(@Wkappa.calculateMetric, act, pred, 'UniformOutput', false));
                    end
                    
                    results_matrix = [accs; gms; mss; maes; amaes; maxmaes; spearmans; kendalls; wkappas; times(1,:); times(2,:); times(3,:)];
                    if ~isempty(hyp_files)
                        for j=1:numel(struct_hyperparams(1).textdata)
                            results_matrix = [results_matrix ; param(j,:) ];
                        end
                    end
                    
                    results_matrix = results_matrix';
                    
                    % Results for the independent dataset
                    if opt.train
                        fid = fopen([experiment_folder '/' experiments(i).name '/' 'results_train.csv'],'w');
                    else
                        fid = fopen([experiment_folder '/' experiments(i).name '/' 'results_test.csv'],'w');
                    end
                    
                    for h = 1:numel(names)
                        fprintf(fid, '%s,', names{h});
                    end
                    fprintf(fid,'\n');
                    
                    for h = 1:size(results_matrix,1)
                        fprintf(fid, '%s,', real_files(h).name);
                        for z = 1:size(results_matrix,2)
                            fprintf(fid, '%f,', results_matrix(h,z));
                        end
                        fprintf(fid,'\n');
                    end
                    fclose(fid);
                    
                    % Confusion matrices and sum of confusion matrices
                    if opt.report_sum
                        if opt.train
                            fid = fopen([experiment_folder '/' experiments(i).name '/' 'matrices_train.txt'],'w');
                        else
                            fid = fopen([experiment_folder '/' experiments(i).name '/' 'matrices_test.txt'],'w');
                        end
                        
                        J = length(unique(act{1}));
                        cm_sum = zeros(J);
                        for h = 1:size(results_matrix,1)
                            fprintf(fid, '%s\n----------\n', real_files(h).name);
                            cm = confusionmat(act{h},pred{h});
                            cm_sum = cm_sum + cm;
                            for ii = 1:size(cm,1)
                                for jj = 1:size(cm,2)
                                    fprintf(fid, '%d ', cm(ii,jj));
                                end
                                fprintf(fid, '\n');
                            end
                        end
                        fclose(fid);
                        
                        % Calculate metrics with the sum of confusion matrices
                        accs_sum = CCR.calculateMetric(cm_sum) * 100;
                        gms_sum = GM.calculateMetric(cm_sum) * 100;
                        mss_sum = MS.calculateMetric(cm_sum) * 100;
                        maes_sum = MAE.calculateMetric(cm_sum);
                        amaes_sum = AMAE.calculateMetric(cm_sum);
                        maxmaes_sum = MMAE.calculateMetric(cm_sum);
                        spearmans_sum = Spearman.calculateMetric(cm_sum);
                        kendalls_sum = Tkendall.calculateMetric(cm_sum);
                        wkappas_sum = Wkappa.calculateMetric(cm_sum);
                        results_matrix_sum = [accs_sum; gms_sum; mss_sum; maes_sum; amaes_sum; maxmaes_sum; spearmans_sum; kendalls_sum; wkappas_sum; sum(times(1,:)); sum(times(2,:)); sum(times(3,:))];
                        
                        results_matrix_sum = results_matrix_sum';
                    end
                    
                    
                    means = mean(results_matrix,1);
                    stdev = std(results_matrix,0,1);
                    
                    if opt.train
                        if ~exist([experiment_folder '/' 'mean-results_train.csv'],'file')
                            add_head = 1;
                        else
                            add_head = 0;
                        end
                        fid = fopen([experiment_folder '/' 'mean-results_train.csv'],'at');
                    else
                        if ~exist([experiment_folder '/' 'mean-results_test.csv'],'file')
                            add_head = 1;
                        else
                            add_head = 0;
                        end
                        fid = fopen([experiment_folder '/' 'mean-results_test.csv'],'at');
                    end
                    
                    
                    if add_head
                        fprintf(fid, 'Dataset-Experiment,');
                        
                        for h = 2:numel(names)
                            fprintf(fid, 'Mean%s,Std%s,', names{h},names{h});
                        end
                        fprintf(fid,'\n');
                    end
                    
                    
                    
                    fprintf(fid, '%s,', experiments(i).name);
                    for h = 1:numel(means)
                        fprintf(fid, '%f,%f,', means(h), stdev(h));
                    end
                    fprintf(fid,'\n');
                    fclose(fid);
                    
                    
                    % Confusion matrices and sum of confusion matrices
                    if opt.report_sum
                        if opt.train
                            fid = fopen([experiment_folder '/' 'mean-results_matrices_sum_train.csv'],'at');
                        else
                            fid = fopen([experiment_folder '/' 'mean-results_matrices_sum_test.csv'],'at');
                        end
                        
                        if add_head
                            fprintf(fid, 'Dataset-Experiment,');
                            
                            for h = 2:numel(names)
                                fprintf(fid, '%s,', names{h});
                            end
                            fprintf(fid,'\n');
                        end
                        
                        fprintf(fid, '%s,', experiments(i).name);
                        for h = 1:numel(results_matrix_sum)
                            fprintf(fid, '%f,', results_matrix_sum(h));
                        end
                        fprintf(fid,'\n');
                        fclose(fid);
                    end
                    
                end
                
            end
            rmpath(fullfile(fileparts(which('Utilities.m')),'../Measures'));
            rmpath(fullfile(fileparts(which('Utilities.m')),'../Algorithms'));
            
            
        end
        
        function logsDir = configureExperiment(expFile,dirSuffix)
            % CONFIGUREEXPERIMENT Function for setting the configuration of the
            % 	different experiments.
            %   LOGSDIR = CONFIGUREEXPERIMENT(EXPFILE,DIRSUFFIX) parses EXPFILE and
            %       generates single experiment files describing individual experiment
            %       of each fold. It also creates folders to store predictions
            %       and models for all the partitions. All the resources are
            %       created int exp-DIRSUFFIX folder.
            if( ~(exist(expFile,'file')))
                error('The file %s does not exist\n',expFile);
            end
            
            logsDir = ['Experiments' '/' 'exp-' dirSuffix];
            resultsDir = [logsDir '/' 'Results'];
            if ~exist('Experiments','dir')
                mkdir('Experiments');
            end
            mkdir(logsDir);
            mkdir(resultsDir);
            
            % Load and parse conf file
            cObj = Config(expFile);
            
            num_experiment = numel(cObj.exps);
            for e = 1:num_experiment
                expObj = cObj.exps{e};
                
                id_experiment = expObj.expId;
                directory = expObj.general('basedir');
                if ~(exist(directory,'dir'))
                    error('Datasets directory "%s" does not exist', directory)
                end
                
                datasets = expObj.general('datasets');
                conf_file = [logsDir '/' 'exp-' id_experiment];
                [matchstart,matchend,tokenindices,matchstring,tokenstring,tokenname,datasetsList] = regexpi(datasets,',');
                % Check that all datasets partitions are accesible
                % The method checkDatasets calls error
                Utilities.checkDatasets(directory, datasets);
                
                [train, test] = Utilities.processDirectory(directory,datasetsList);
                
                % Generate one config file and corresponding directories
                % for each fold.
                for i=1:numel(train)
                    aux_directory = [resultsDir '/' datasetsList{i} '-' id_experiment];
                    mkdir(aux_directory);
                    
                    mkdir([aux_directory '/' 'OptHyperparams']);
                    mkdir([aux_directory '/' 'Times']);
                    mkdir([aux_directory '/' 'Models']);
                    mkdir([aux_directory '/' 'Predictions']);
                    mkdir([aux_directory '/' 'Guess']);
                    
                    file = [resultsDir '/' datasetsList{i} '-' id_experiment '/' 'dataset'];
                    fich = fopen(file,'w');
                    fprintf(fich, [directory '/' datasetsList{i} '/' 'matlab']);
                    fclose(fich);
                    
                    runfolds = numel(train{i});
                    for j=1:runfolds
                        iniFile = [conf_file '-' datasetsList{i} '-' num2str(j) '.ini'];
                        
                        expObj.general('directory') = [directory '/' datasetsList{i} '/' 'matlab'];
                        expObj.general('train') = train{i}(j).name;
                        expObj.general('test') = test{i}(j).name ;
                        expObj.general('results') = [resultsDir '/' datasetsList{i} '-' id_experiment];
                        
                        expObj.writeIni(iniFile);
                    end
                end
            end
        end
        
        function runExperimentFold(confFile)
            % RUNEXPERIMENTFOLD(CONFFILE) launch a single experiment described in
            %   file CONFFILE
            addpath(fullfile(fileparts(which('Utilities.m')),'../Measures'));
            addpath(fullfile(fileparts(which('Utilities.m')),'../Algorithms'));
            
            auxiliar = Experiment;
            auxiliar.launch(confFile);
            
            rmpath(fullfile(fileparts(which('Utilities.m')),'../Measures'));
            rmpath(fullfile(fileparts(which('Utilities.m')),'../Algorithms'));
            
        end
    end
    
    methods(Static = true, Access = private)
        
        function [trainFileNames, testFileNames] = processDirectory(directory, dataSetNames)
            % PROCESSDIRECTORY Function to get all the train and test pair of
            %   files of dataset's folds
            %   [TRAINFILENAMES, TESTFILENAMES] = PROCESSDIRECTORY(DIRECTORY, DATASETNAMES)
            %   process comma separated list of datasets names in DATASETNAMES.
            %   All the dataset's folders need to be stored in DIRECTORY.
            %   Returns all the pairs of train-test files in TRAINFILENAMES and
            %   TESTFILENAMES.
            %   [TRAINFILENAMES, TESTFILENAMES] = PROCESSDIRECTORY(DIRECTORY,
            %   'all') process all datasets in DIRECTORY.
            dbs = dir(directory);
            dbs(2) = [];
            dbs(1) = [];
            validDataSets = 1;
            
            trainFileNames = cell(numel(dataSetNames),1);
            testFileNames = cell(numel(dataSetNames),1);
            for j=1:numel(dataSetNames)
                dsdirectory = [directory '/' dataSetNames{j}];
                if(isdir(dsdirectory))
                    file_expr = [dsdirectory '/' 'matlab' '/' 'train_' dataSetNames{j} '.*'];
                    trainFileNames{validDataSets} = dir(file_expr);
                    file_expr = [dsdirectory '/' 'matlab' '/' 'test_' dataSetNames{j} '.*'];
                    testFileNames{validDataSets} = dir(file_expr);
                    validDataSets = validDataSets + 1;
                end
            end
        end
        
        function checkDatasets(basedir, datasets)
            % CHECKDATASETS Test datasets are accessible and with expected
            % names. Launch error in case a dataset is not found.
            %   CHECKDATASETS(BASEDIR, DATASETS) tests all DATASETS (comma
            %   separated list of datasets) in directory BASEDIR.
            
            if ~exist(basedir,'dir')
                error('Datasets directory "%s" does not exist', basedir)
            end
            
            dsdirsCell = regexp(datasets, '((\w|-|_)+(\w*))','tokens');
            for i=1:length(dsdirsCell) % skip . and ..
                dsName = dsdirsCell{i};
                dsName = dsName{:};
                if ~exist([basedir '/' dsName],'dir')
                    error('Dataset directory "%s" does not exist', [basedir '/' dsName])
                end
                
                dsTrainFiles = dir([basedir '/' dsName '/matlab/train*']);
                
                % Test every train file has a test file
                for f=1:length(dsTrainFiles)
                    
                    trainName = [basedir '/' dsName '/matlab/' dsTrainFiles(f).name];
                    testName = strrep(trainName, 'train', 'test');
                    
                    try
                        trainData = load(trainName);
                        testData = load(testName);
                    catch
                        error('Cannot read train and test files "%s", "%s"', trainName, testName)
                    end
                    
                    if size(trainData,2) ~= size(testData,2)
                        error('Train and test data dimensions do not agree for dataset "%s"', dsName)
                    end
                    
                end
            end
            
        end
        
        function preparePool(numcores)
            %PREPAREPOOL(NUMCORES) creates a pool of workers. Function to
            %abstract code from different matlab versions. Adapt the pool
            %to the desired number of cores. If there is a current pool with
            %desired number of cores do not open again to save time
            if (exist ('OCTAVE_VERSION', 'builtin') > 0)
                maximum_ncores = nproc;
            else
                maximum_ncores = feature('numCores');
            end
            
            % Adjust number of cores
            if numcores > maximum_ncores
                disp(['Number of cores was too high and was set up to the maximum available: ' num2str(feature('numCores')) ])
                numcores = maximum_ncores;
            end
            
            % Check size of the pool
            if (exist ('OCTAVE_VERSION', 'builtin') > 0)
                pkg load parallel;
            else
                if verLessThan('matlab', '8.3')
                    poolsize = matlabpool('size');
                    if poolsize > 0
                        if poolsize ~= numcores
                            matlabpool close;
                            matlabpool(numcores);
                        end
                    else
                        matlabpool(numcores);
                    end
                else
                    poolobj = gcp('nocreate'); % If no pool, do not create new one.
                    if ~isempty(poolobj)
                        if poolobj.NumWorkers ~= numcores
                            numcores = poolobj.NumWorkers;
                            delete(gcp('nocreate'))
                            parpool(numcores);
                        end
                    else
                        parpool(numcores);
                    end
                end
            end
        end
        
        function closePool()
            if (exist ('OCTAVE_VERSION', 'builtin') > 0)
                pkg unload parallel;
            else
                if verLessThan('matlab', '8.3')
                    isOpen = matlabpool('size') > 0;
                    if isOpen
                        matlabpool close;
                    end
                else
                    delete(gcp('nocreate'))
                end
            end
        end
        
        function options = parseParArgs(varargin)
            %OPTIONS = PARSEPARARGS(VARARGIN) parses parallelization
            %options with are:
            % - 'parallel': 'false' or 'true' to activate, default 'false'
            % - 'numcores': default maximum number of cores or desired
            %    number. If parallel = 1 and numcores <2 it sets the number
            %    to maximum number of cores.
            % - 'closepool': whether to close or not the pool after
            %    experiments. Default 'true'
            % Solution adapted from https://stackoverflow.com/questions/2775263/how-to-deal-with-name-value-pairs-of-function-arguments-in-matlab#2776238
            
            if (exist ('OCTAVE_VERSION', 'builtin') > 0)
                maximum_ncores = nproc;
            else
                maximum_ncores = feature('numCores');
            end
            
            options = struct('parallel',false,'numcores',maximum_ncores,'closepool',true);
            
            varargin = varargin{:};
            if ~isempty(varargin)
                options = parsevarargs(options, varargin);
                if options.parallel && options.numcores <2
                    disp('Number of cores to low, setting to default number of cores')
                    options.numcores = maximum_ncores;
                end
            end
        end
        
    end
end



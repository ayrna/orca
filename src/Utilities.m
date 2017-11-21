%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Guti??rrez (pagutierrez at uco dot es)
% Mar??a P??rez Ortiz (i82perom at uco dot es)
% Javier S??nchez Monedero (jsanchezm at uco dot es)
%
% This file contains the class that configures and executes the experiments, presented in the paper Ordinal regression methods: survey and experimental study published in the IEEE Transactions on Knowledge and Data Engineering. 
% 
% The code has been tested with Ubuntu 12.04 x86_64, Debian Wheezy 8, Matlab R2009a and Matlab 2011
% 
% If you use this code, please cite the associated paper
% Code updates and citing information:
% http://www.uco.es/grupos/ayrna/orreview
% https://github.com/ayrna/orca
% 
% AYRNA Research group's website:
% http://www.uco.es/ayrna 
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
% Licence available at: http://www.gnu.org/licenses/gpl-3.0.html
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%???

classdef Utilities < handle
    % Utilities class
    % Class that contains several methods for configurating and running the experiments
    
    properties
         
    end
    
    
    methods (Static = true)

     	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runExperiments (static)
        % Description: Function for setting and running the experiments
        % Type: void
        % Arguments:
        %           -ficheroExperimentos: Name for the current experiment file
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [logsDir] = runExperiments(ficheroExperimentos, varargin)
            
            parallel = 0;
            num_cores = 0;
            maximum_ncores = 0;
            if (exist ('OCTAVE_VERSION', 'builtin') > 0)
              maximum_ncores = nproc;
            else
              maximum_ncores = feature('numCores');
            end
            optargin = size(varargin,2);
            if optargin == 1
                parallel = varargin{1};
                num_cores = maximum_ncores; 
            else
                if optargin == 2
                    parallel = varargin{1};
                    num_cores = varargin{2}; 
                    if num_cores > maximum_ncores
                        disp(['Number of cores was too high and was set up to the maximum available: ' num2str(feature('numCores')) ])
                        num_cores = maximum_ncores;
                    end
                end                    
            end
            
            addpath('Measures');
            addpath('Algorithms');
            
            disp('Setting up experiments...');

            % TODO: move ID generation to configureExperiment?
            c = clock;
            dirSuffix = [num2str(c(1)) '-' num2str(c(2)) '-'  num2str(c(3)) '-' num2str(c(4)) '-' num2str(c(5)) '-' num2str(uint8(c(6)))];            
            logsDir = Utilities.configureExperiment(ficheroExperimentos,dirSuffix);            
            ficheros_experimentos = dir([logsDir '/' 'exp-*']);
            
            if parallel

                % Check if the pool is open, then close and open with the
                % right number of cores
                poolsize = matlabpool('size');
                if poolsize > 0
                    if poolsize ~= num_cores
                        matlabpool close;
                        matlabpool(num_cores);
                    end
                else
                    matlabpool(num_cores)
                end
                
                parfor i=1:numel(ficheros_experimentos),
                    if ~strcmp(ficheros_experimentos(i).name(end), '~')
                        auxiliar = Experiment;

                        disp(['Running experiment ', ficheros_experimentos(i).name]);
                        auxiliar.launch([logsDir '/' ficheros_experimentos(i).name]);
                    end
                end
                
                isOpen = matlabpool('size') > 0;
                if isOpen
                    matlabpool close;
                end

                
            else
                for i=1:numel(ficheros_experimentos),
                    if ~strcmp(ficheros_experimentos(i).name(end), '~')
                        auxiliar = Experiment;

                        disp(['Running experiment ', ficheros_experimentos(i).name]);
                        auxiliar.launch([logsDir '/' ficheros_experimentos(i).name]);
                    end
                end
            end
            
            disp('Calculating results...');
            % Train results (note last argument)
            Utilities.results([logsDir '/' 'Results'],1);
            % Test results 
            Utilities.results([logsDir '/' 'Results']);
            %rmpath('Measures');
            %rmpath('Algorithms');
            
        end
        
     	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: results (static)
        % Description: Function for computing the results
        % Type: void
        % Arguments:
        %           -experiment_folder: folder where the information
	%				about the experiment is contained
	%	    -train: train set structure
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function results(experiment_folder,train)
                   
            addpath('Measures');
            addpath('Algorithms');

            if nargin < 2
                train = 0;
            elseif nargin == 1
                train = train;
            end
            experimentos = dir(experiment_folder);

            %idx=strfind(experiment_folder,'Results');
            %scriptpath = [experiment_folder(1:idx-1)];
   
            for i=1:numel(experimentos)
                if ~(any(strcmp(experimentos(i).name, {'.', '..'}))) && experimentos(i).isdir
                    disp([experiment_folder '/' experimentos(i).name '/' 'dataset'])
                    fid = fopen([experiment_folder '/' experimentos(i).name '/' 'dataset'],'r');
                    ruta_dataset = fgetl(fid);
                    fclose(fid);

                    if train == 1
                        predicted_files = dir([experiment_folder '/' experimentos(i).name '/' 'Predictions' '/' 'train_*']);
                    else
                        predicted_files = dir([experiment_folder '/' experimentos(i).name '/' 'Predictions' '/' 'test_*']);
                    end
                    % Check if we have a missing fold experiment. 
                    % -2 is to compensate . and ..
                    predicted_files_train = dir([experiment_folder '/' experimentos(i).name '/' 'Predictions' '/' 'train_*']);
                    predicted_files_test = dir([experiment_folder '/' experimentos(i).name '/' 'Predictions' '/' 'test_*']);
                    
                    if (numel(predicted_files_train)+numel(predicted_files_test)) ~= numel(dir(ruta_dataset)) -2 
                        warning(sprintf('\n *********** \n The execution of some folds failed. Number of experiments differs from number of train-test files. \n *********** \n'))
                    end
                    time_files = dir([experiment_folder '/' experimentos(i).name '/' 'Times' '/' '*.*']);
                    hyp_files = dir([experiment_folder '/' experimentos(i).name '/' 'OptHyperparams' '/' '*.*']);
                    
                    if train == 1
                        guess_files = dir([experiment_folder '/' experimentos(i).name '/' 'Guess' '/' 'train_*']);
                    else
                        guess_files = dir([experiment_folder '/' experimentos(i).name '/' 'Guess' '/' 'test_*']);
                    end
                    
                    %str=predicted_files(1).name;
                    %[matchstart,matchend] = regexp( str,'_(.+)\.\d+');
                    %dataset=str(matchstart+1:matchend-2);

                    %auxscript =  experimentos(i).name;
                    %[matchstart,matchend]=regexp(auxscript,dataset);
                    %basescript = ['exp-' auxscript(matchend+2:end) '-' dataset '-'];

                    % Discard "." and ".."
                    if ~(exist ('OCTAVE_VERSION', 'builtin') > 0)
                      time_files = time_files(3:numel(time_files));
                      hyp_files = hyp_files(3:numel(hyp_files));
                    end
                    
                    if train == 1
                        real_files = dir([ruta_dataset '/' 'train_*']);
                    else
                        real_files = dir([ruta_dataset '/' 'test_*']);
                    end

                    act = cell(1, numel(predicted_files));
                    pred = cell(1, numel(predicted_files));
                    proj = cell(1, numel(guess_files));

                    times = zeros(3,numel(predicted_files));
                    param = [];
                    
                    for j=1:numel(predicted_files)
                        pred{j} = importdata([experiment_folder '/' experimentos(i).name '/' 'Predictions' '/' predicted_files(j).name]);
                        times(:,j) = importdata([experiment_folder '/' experimentos(i).name '/' 'Times' '/' time_files(j).name]);
                        proj{j} = importdata([experiment_folder '/' experimentos(i).name '/' 'Guess' '/' guess_files(j).name]);
                        
                        if length(hyp_files)~=0
                            struct_hyperparams(j) = importdata([experiment_folder '/' experimentos(i).name '/' 'OptHyperparams' '/' hyp_files(j).name],',');
                            for z = 1:numel(struct_hyperparams(j).data)
                                param(z,j) = struct_hyperparams(j).data(z);
                            end
                        end
                        actual = importdata([ruta_dataset '/' real_files(j).name]);
                        act{j} = actual(:,end);
                    end

                    names = {'Dataset', 'Acc', 'GM', 'MS', 'MAE', 'AMAE', 'MMAE','RSpearman', 'Tkendall', 'Wkappa', 'TrainTime', 'TestTime', 'CrossvalTime'};

                    if length(hyp_files)~=0
                        for j=1:numel(struct_hyperparams(1).textdata),
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
                    if length(hyp_files)~=0
                        for j=1:numel(struct_hyperparams(1).textdata),
                            results_matrix = [results_matrix ; param(j,:) ];
                        end
                    end

                    results_matrix = results_matrix';

                    % Results for the independent dataset
                    if train == 1
                        fid = fopen([experiment_folder '/' experimentos(i).name '/' 'results_train.csv'],'w');
                    else
                        fid = fopen([experiment_folder '/' experimentos(i).name '/' 'results_test.csv'],'w');
                    end
                    
                    for h = 1:numel(names),
                        fprintf(fid, '%s,', names{h});
                    end
                    fprintf(fid,'\n');

                    for h = 1:size(results_matrix,1),
                        fprintf(fid, '%s,', real_files(h).name);
                        for z = 1:size(results_matrix,2),
                            fprintf(fid, '%f,', results_matrix(h,z));
                        end
                        fprintf(fid,'\n');
                    end
                    fclose(fid);

                    % Confusion matrices and sum of confusion matrices
                    if train == 1
                        fid = fopen([experiment_folder '/' experimentos(i).name '/' 'matrices_train.txt'],'w');
                    else
                        fid = fopen([experiment_folder '/' experimentos(i).name '/' 'matrices_test.txt'],'w');
                    end

                    J = length(unique(act{1}));
                    cm_sum = zeros(J);
                    for h = 1:size(results_matrix,1),
                        fprintf(fid, '%s\n----------\n', real_files(h).name);
                        cm = confusionmat(act{h},pred{h});
                        cm_sum = cm_sum + cm;
                        for ii = 1:size(cm,1),
                            for jj = 1:size(cm,2),
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


                    medias = mean(results_matrix,1);
                    stdev = std(results_matrix,0,1);

                    if train == 1
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

                        for h = 2:numel(names),
                            fprintf(fid, 'Mean%s,Std%s,', names{h},names{h});
                        end
                        fprintf(fid,'\n');
                    end

                    

                    fprintf(fid, '%s,', experimentos(i).name);
                    for h = 1:numel(medias),
                        fprintf(fid, '%f,%f,', medias(h), stdev(h));
                    end
                    fprintf(fid,'\n');
                    fclose(fid);
                    
                    
                    if train == 1
                        fid = fopen([experiment_folder '/' 'mean-results_matrices_sum_train.csv'],'at');
                    else
                        fid = fopen([experiment_folder '/' 'mean-results_matrices_sum_test.csv'],'at');
                    end
                    
                    if add_head
                        fprintf(fid, 'Dataset-Experiment,');

                        for h = 2:numel(names),
                            fprintf(fid, '%s,', names{h});
                        end
                        fprintf(fid,'\n');
                    end
                    
                    fprintf(fid, '%s,', experimentos(i).name);
                    for h = 1:numel(results_matrix_sum),
                        fprintf(fid, '%f,', results_matrix_sum(h));
                    end
                    fprintf(fid,'\n');
                    fclose(fid);

                end
                
            end
            rmpath('Measures');
            rmpath('Algorithms');
            
            
        end
                
     	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: configureExperiment (static)
        % Description: Function for setting the configuration of the
	% 	different experiments
        % Output: -logsDir: Folder where the logs are contained 
        % Arguments:
        %           -ficheroExperimentos: Name for the current experiment file
	%	    -dirSuffix: experiment directory identifier
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function logsDir = configureExperiment(ficheroExperimentos,dirSuffix)
            
            if( ~(exist(ficheroExperimentos,'file')))
                fprintf('The file %s does not exist\n',ficheroExperimentos);
                return;
            end
            
            logsDir = ['Experiments' '/' 'exp-' dirSuffix];
            % Prevent to overwrite log dir of parallel or fast experiments
            % with same ID
            %if exist(logsDir, 'dir')
            %    randStr = num2str(rand);
            %    randStr(1:2)=[];
            %    logsDir = [logsDir '-' randStr];
            %end
            
            resultados = [logsDir '/' 'Results'];
            if ~exist('Experiments','dir')
                mkdir('Experiments');
            end
            mkdir(logsDir);
            mkdir(resultados);
            fid = fopen(ficheroExperimentos,'r+');
            num_experiment = 0;
            nOfFolds = 0;
            
            while ~feof(fid),
                nueva_linea = fgetl(fid);
                if strncmpi(nueva_linea,'%',1),
                    %Doing nothing!
                elseif strcmpi('new experiment', nueva_linea),
                    num_experiment = num_experiment + 1;
                    id_experiment = num2str(num_experiment);
                    auxiliar = '';
                elseif strcmpi('name', nueva_linea),
                    id_experiment = [fgetl(fid) num2str(num_experiment)];
                elseif strcmpi('dir', nueva_linea),
                    directory = fgetl(fid);
                    if ~(exist(directory,'dir'))
                        error('Datasets directory "%s" does not exist', directory)
                    end
                elseif strcmpi('datasets', nueva_linea),
                    datasets = fgetl(fid);
                elseif strcmpi('folds', nueva_linea),
                    nOfFolds = str2num(fgetl(fid)); 
                elseif strcmpi('end experiment', nueva_linea),
                    fichero_ini = [logsDir '/' 'exp-' id_experiment];
                    [matchstart,matchend,tokenindices,matchstring,tokenstring,tokenname,splitstring] = regexpi(datasets,',');
                    % Check that all datasets partitions are accesible
                    % The method checkDatasets calls error
                    Utilities.checkDatasets(directory, datasets);
                    [train, test] = Utilities.processDirectory(directory,splitstring);
                    for i=1:numel(train)
                        aux_directory = [resultados '/' splitstring{i} '-' id_experiment];
                        mkdir(aux_directory);
                       
                        mkdir([aux_directory '/' 'OptHyperparams']);
                                                mkdir([aux_directory '/' 'Times']);
                        mkdir([aux_directory '/' 'Models']);
                        mkdir([aux_directory '/' 'Predictions']);
                        mkdir([aux_directory '/' 'Guess']);
                        
                        fichero = [resultados '/' splitstring{i} '-' id_experiment '/' 'dataset'];
                        fich = fopen(fichero,'w');
                        fprintf(fich, [directory '/' splitstring{i} '/' 'matlab']);
                        fclose(fich);

			runfolds = numel(train{i});
                        
                        for j=1:runfolds,
                            fichero = [fichero_ini '-' splitstring{i} '-' num2str(j)];
                            fich = fopen(fichero,'w');
                            fprintf(fich, ['directory\n' directory '/' splitstring{i} '/' 'matlab' '\n']);
                            fprintf(fich, ['train\n' train{i}(j).name '\n']);
                            fprintf(fich, ['test\n' test{i}(j).name '\n']);
                            fprintf(fich, ['results\n' resultados '/' splitstring{i} '-' id_experiment '\n']);
                            fprintf(fich, auxiliar);
                            fclose(fich);
                        end
                    end
                else
                    auxiliar = [auxiliar nueva_linea '\n'];
                end
                
            end
            fclose(fid);
            
        end
        
     	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: processDirectory (static)
        % Description: Function for processing the dataset
        % Output:  -trainFileNames: Files for the different training folds
	%	   -testFileNames: Files for the different test folds
        % Arguments:
        %           -directory: Name for the current experiment file
	%	    -dataSetNames: experiment directory identifier
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [trainFileNames, testFileNames] = processDirectory(directory, dataSetNames)
            dbs = dir(directory);
            dbs(2) = [];
            dbs(1) = [];
            validDataSets = 1;
			            
			% Currently, 'all' is not working
            %if strcmpi(dataSetNames{1}, 'all')
            %    trainFileNames = cell(size(dbs,1),1);
            %    testFileNames = cell(size(dbs,1),1);
            %    for dd=1:size(dbs,1)
            %        % get directory
            %        if dbs(dd).isdir,
            %            ejemplo = [directory '/' dbs(dd).name '/' 'matlab' '/' 'train_' dbs(dd).name '.*'];
            %            trainFileNames{validDataSets} = dir(ejemplo);
            %            ejemplo = [directory '/' dbs(dd).name '/' 'matlab' '/' 'test_' dbs(dd).name '.*'];
            %            testFileNames{validDataSets} = dir(ejemplo);
            %            validDataSets = validDataSets + 1;
            %        end
            %        
            %    end
            %else
                trainFileNames = cell(numel(dataSetNames),1);
                testFileNames = cell(numel(dataSetNames),1);
                for j=1:numel(dataSetNames),
                    isdirectory = [directory '/' dataSetNames{j}];
                    if(isdir(isdirectory)),
                        ejemplo = [isdirectory '/' 'matlab' '/' 'train_' dataSetNames{j} '.*'];
                        trainFileNames{validDataSets} = dir(ejemplo);
                        ejemplo = [isdirectory '/' 'matlab' '/' 'test_' dataSetNames{j} '.*'];
                        testFileNames{validDataSets} = dir(ejemplo);
                        validDataSets = validDataSets + 1;
                    end
                end
            %end
        end
        
     	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runExperiment (static)
        % Description: Simple function for launching the experiments
        % Type: void
        % Arguments:
        %           No arguments
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function runExperiment(fichero)
            addpath('Measures');
            addpath('Algorithms');
            
            auxiliar = Experiment;
            auxiliar.launch(fichero);

            rmpath('Measures');
            rmpath('Algorithms');
            
        end
        
                
     	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: checkDatasets (static)
        % Description: Test datasets are accessible and with expected
        % names. Launch error in case a dataset is not found. 
        % Type: void
        % Arguments: 
        %   - basedir: base directory containing all the datasets
        %   - datasets: colon separaded list of datasets. keyword 'all'
        %   test all datasets in basedir
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function checkDatasets(basedir, datasets)
            if ~exist(basedir,'dir')
                error('Datasets directory "%s" does not exist', basedir)
            end
            
            if strcmpi(datasets, 'all')
                dsdirs = ls(basedir);
                dsdirsCell = regexp(dsdirs, '((\w|-|_)+(\t*)(\w*))','tokens');
            else
                dsdirsCell = regexp(datasets, '((\w|-|_)+(\w*))','tokens');
            end
            for i=1:length(dsdirsCell) % skip . and ..
                dsName = dsdirsCell{i};
                dsName = dsName{:};
                if ~exist([basedir '/' dsName],'dir')
                    error('Dataset directory "%s" does not exist', dsName)
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
    end
end



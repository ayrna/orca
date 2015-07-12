%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%﻿

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
        
        function runExperiments(ficheroExperimentos)
            
            c = clock;
            addpath('Measures');
            addpath('Algorithms');
            dirSuffix = [num2str(c(1)) '-' num2str(c(2)) '-'  num2str(c(3)) '-' num2str(c(4)) '-' num2str(c(5)) '-' num2str(uint8(c(6)))];
            disp('Setting up experiments...');
            logsDir = Utilities.configureExperiment(ficheroExperimentos,dirSuffix);
            
            ficheros_experimentos = dir([logsDir filesep 'exp-*']);
            
            for i=1:numel(ficheros_experimentos),
                if ~strcmp(ficheros_experimentos(i).name(end), '~')
                    auxiliar = Experiment;
                    
                    disp(['Running experiment ', ficheros_experimentos(i).name]);
                    auxiliar.launch([logsDir filesep ficheros_experimentos(i).name]);
                end
            end
            
            disp('Calculating results...');
            % Train results (note last argument)
            Utilities.results([logsDir filesep 'Results'],1);
            % Test results 
            Utilities.results([logsDir filesep 'Results']);
            rmpath('Measures');
            rmpath('Algorithms');
            
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
                        
            experimentos = dir([experiment_folder filesep '*-*']);

            %idx=strfind(experiment_folder,'Results');
            %scriptpath = [experiment_folder(1:idx-1)];
   
            for i=1:numel(experimentos)
                if experimentos(i).isdir
                    disp([experiment_folder filesep experimentos(i).name filesep 'dataset'])
                    fid = fopen([experiment_folder filesep experimentos(i).name filesep 'dataset'],'r');
                    ruta_dataset = fgetl(fid);
                    fclose(fid);

                    if train == 1
                        predicted_files = dir([experiment_folder filesep experimentos(i).name filesep 'Predictions' filesep 'train_*']);
                    else
                        predicted_files = dir([experiment_folder filesep experimentos(i).name filesep 'Predictions' filesep 'test_*']);
                    end
                    time_files = dir([experiment_folder filesep experimentos(i).name filesep 'Times' filesep '*.*']);
                    hyp_files = dir([experiment_folder filesep experimentos(i).name filesep 'OptHyperparams' filesep '*.*']);
                    
                    if train == 1
                        guess_files = dir([experiment_folder filesep experimentos(i).name filesep 'Guess' filesep 'train_*']);
                    else
                        guess_files = dir([experiment_folder filesep experimentos(i).name filesep 'Guess' filesep 'test_*']);
                    end
                    
                    %str=predicted_files(1).name;
                    %[matchstart,matchend] = regexp( str,'_(.+)\.\d+');
                    %dataset=str(matchstart+1:matchend-2);

                    %auxscript =  experimentos(i).name;
                    %[matchstart,matchend]=regexp(auxscript,dataset);
                    %basescript = ['exp-' auxscript(matchend+2:end) '-' dataset '-'];

                    % Discard "." and ".."
                    time_files = time_files(3:numel(time_files));
                    hyp_files = hyp_files(3:numel(hyp_files));
                    
                    if train == 1
                        real_files = dir([ruta_dataset filesep 'train_*']);
                    else
                        real_files = dir([ruta_dataset filesep 'test_*']);
                    end

                    act = cell(1, numel(predicted_files));
                    pred = cell(1, numel(predicted_files));
                    proj = cell(1, numel(guess_files));

                    times = [];
                    param = [];

                    for j=1:numel(predicted_files)
                        pred{j} = importdata([experiment_folder filesep experimentos(i).name filesep 'Predictions' filesep predicted_files(j).name]);
                        times(:,j) = importdata([experiment_folder filesep experimentos(i).name filesep 'Times' filesep time_files(j).name]);
                        proj{j} = importdata([experiment_folder filesep experimentos(i).name filesep 'Guess' filesep guess_files(j).name]);
                        if length(hyp_files)~=0
                            struct_hyperparams(j) = importdata([experiment_folder filesep experimentos(i).name filesep 'OptHyperparams' filesep hyp_files(j).name],',');
                            for z = 1:numel(struct_hyperparams(j).data)
                                param(z,j) = struct_hyperparams(j).data(z);
                            end
                        end
                        actual = importdata([ruta_dataset filesep real_files(j).name]);
                        act{j} = actual(:,end);

                    end

                    names = {'Dataset', 'Acc', 'GM', 'MS', 'MAE', 'AMAE', 'MMAE','RSpearman', 'Tkendall', 'Wkappa', 'TrainTime', 'TestTime', 'CrossvalTime'};

                    if length(hyp_files)~=0
                        for j=1:numel(struct_hyperparams(1).textdata),
                            names{numel(names)+1} = struct_hyperparams(1).textdata{j};
                        end
                    end

                    accs = cell2mat(cellfun(@CCR.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                    gms = cell2mat(cellfun(@GM.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                    mss = cell2mat(cellfun(@MS.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                    maes = cell2mat(cellfun(@MAE.calculateMetric, act, pred, 'UniformOutput', false));
                    amaes = cell2mat(cellfun(@AMAE.calculateMetric, act, pred, 'UniformOutput', false));
                    maxmaes = cell2mat(cellfun(@MMAE.calculateMetric, act, pred, 'UniformOutput', false));
                    spearmans = cell2mat(cellfun(@Spearman.calculateMetric, act, pred, 'UniformOutput', false));
                    kendalls = cell2mat(cellfun(@Tkendall.calculateMetric, act, pred, 'UniformOutput', false));
                    wkappas = cell2mat(cellfun(@Wkappa.calculateMetric, act, pred, 'UniformOutput', false));
                    results_matrix = [accs; gms; mss; maes; amaes; maxmaes; spearmans; kendalls; wkappas; times(1,:); times(2,:); times(3,:)];
                    if length(hyp_files)~=0
                        for j=1:numel(struct_hyperparams(1).textdata),
                            results_matrix = [results_matrix ; param(j,:) ];
                        end
                    end

                    results_matrix = results_matrix';

                    % Results for the independent dataset
                    if train == 1
                        fid = fopen([experiment_folder filesep experimentos(i).name filesep 'results_train.csv'],'w');
                    else
                        fid = fopen([experiment_folder filesep experimentos(i).name filesep 'results_test.csv'],'w');
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

                    % Confusion matrices
                    if train == 1
                        fid = fopen([experiment_folder filesep experimentos(i).name filesep 'matrices_train.txt'],'w');
                    else
                        fid = fopen([experiment_folder filesep experimentos(i).name filesep 'matrices_test.txt'],'w');
                    end

                    for h = 1:size(results_matrix,1),
                        fprintf(fid, '%s\n----------\n', real_files(h).name);
                        cm = confusionmat(act{h},pred{h});
                        for ii = 1:size(cm,1),
                            for jj = 1:size(cm,2),
                                fprintf(fid, '%d ', cm(ii,jj));
                            end
                            fprintf(fid, '\n');                        
                        end
                    end
                    fclose(fid);

                    medias = mean(results_matrix,1);
                    stdev = std(results_matrix,0,1);

                    if train == 1
                        if ~exist([experiment_folder filesep 'mean-results_train.csv'],'file')
                            add_head = 1;
                        else
                            add_head = 0;
                        end
                        fid = fopen([experiment_folder filesep 'mean-results_train.csv'],'at');
                    else
                        if ~exist([experiment_folder filesep 'mean-results_test.csv'],'file')
                            add_head = 1;
                        else
                            add_head = 0;
                        end
                        fid = fopen([experiment_folder filesep 'mean-results_test.csv'],'at');
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
            
            logsDir = ['Experiments' filesep 'exp-' dirSuffix];
            resultados = [logsDir filesep 'Results'];
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
                elseif strcmpi('datasets', nueva_linea),
                    datasets = fgetl(fid);
                elseif strcmpi('folds', nueva_linea),
                    nOfFolds = str2num(fgetl(fid)); 
                elseif strcmpi('end experiment', nueva_linea),
                    fichero_ini = [logsDir filesep 'exp-' id_experiment];
                    [matchstart,matchend,tokenindices,matchstring,tokenstring,tokenname,splitstring] = regexpi(datasets,',');
                    if( ~(exist(directory,'dir')))
                        fprintf('The directory %s does not exist\n',directory);
                        return;
                    end
                    [train, test] = Utilities.processDirectory(directory,splitstring);
                    for i=1:numel(train)
                        aux_directory = [resultados filesep splitstring{i} '-' id_experiment];
                        mkdir(aux_directory);
                       
                        mkdir([aux_directory filesep 'OptHyperparams']);
                                                mkdir([aux_directory filesep 'Times']);
                        mkdir([aux_directory filesep 'Models']);
                        mkdir([aux_directory filesep 'Predictions']);
                        mkdir([aux_directory filesep 'Guess']);
                        
                        fichero = [resultados filesep splitstring{i} '-' id_experiment filesep 'dataset'];
                        fich = fopen(fichero,'w');
                        fprintf(fich, [directory filesep splitstring{i} filesep 'gpor']);
                        fclose(fich);

			runfolds = numel(train{i});
                        
                        for j=1:runfolds,
                            fichero = [fichero_ini '-' splitstring{i} '-' num2str(j)];
                            fich = fopen(fichero,'w');
                            fprintf(fich, ['directory\n' directory filesep splitstring{i} filesep 'gpor' '\n']);
                            fprintf(fich, ['train\n' train{i}(j).name '\n']);
                            fprintf(fich, ['test\n' test{i}(j).name '\n']);
                            fprintf(fich, ['results\n' resultados filesep splitstring{i} '-' id_experiment '\n']);
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
            
            if strcmpi(dataSetNames{1}, 'all')
                for dd=1:size(dbs,1)
                    % get directory
                    if dbs(dd).isdir,
                        ejemplo = [directory filesep dbs(dd).name filesep 'gpor' filesep 'train_' dbs(dd).name '.*'];
                        trainFileNames{validDataSets, :} = dir(ejemplo);
                        ejemplo = [directory filesep dbs(dd).name filesep 'gpor' filesep 'test_' dbs(dd).name '.*'];
                        testFileNames{validDataSets, :} = dir(ejemplo);
                        validDataSets = validDataSets + 1;
                    end
                    
                end
            else
                for j=1:numel(dataSetNames),
                    isdirectory = [directory filesep dataSetNames{j}];
                    if(isdir(isdirectory)),
                        ejemplo = [isdirectory filesep 'gpor' filesep 'train_' dataSetNames{j} '.*'];
                        trainFileNames{validDataSets, :} = dir(ejemplo);
                        ejemplo = [isdirectory filesep 'gpor' filesep 'test_' dataSetNames{j} '.*'];
                        testFileNames{validDataSets, :} = dir(ejemplo);
                        validDataSets = validDataSets + 1;
                    end
                end
            end
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
        
        
    end
    
    
    
end



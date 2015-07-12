classdef Utilities < handle
    % Algorithm Abstract interface class
    % Abstract class which defines Machine Learning algorithms.
    % It describes some common methods and variables for all the
    % algorithMs.
    
    
    properties
         
    end
    
    
    methods (Static = true)
        
        function runExperiments(ficheroExperimentos)
            % Guardamos esto aquí porque la información se guarda en 
            % Data dentro de Experiment y los objetos son destruídos
            % antes de procesar la carpeta de experimentos
            % Hay que declararla como global en cada función que vaya a
            % usarla
            % http://stackoverflow.com/questions/9961697/undefined-function-or-variable-in-matlab
            global reorderlabels; 
            reorderlabels = 0;
            
            c = clock;
            %addpath libsvm-2.81/
            %addpath libsvm-weights-3.12/matlab
            addpath('Measures');
            addpath('Algorithms');
            dirSuffix = [num2str(c(1)) '-' num2str(c(2)) '-'  num2str(c(3)) '-' num2str(c(4)) '-' num2str(c(5)) '-' num2str(uint8(c(6)))];
            disp('Setting up experiments...');
            logsDir = Utilities.configureExperiment(ficheroExperimentos,dirSuffix);
            
            ficheros_experimentos = dir([logsDir filesep 'exp-*']);
            
            
            for i=1:numel(ficheros_experimentos),
                if ~strcmp(ficheros_experimentos(i).name(end), '~')
                    auxiliar = Experiment;
                    reorderlabels = auxiliar.data.reorderlabels;
                    
                    disp(['Running experiment ', ficheros_experimentos(i).name]);
                    auxiliar.launch([logsDir filesep ficheros_experimentos(i).name]);
                end
            end
            
            disp('Calculating results...');
            if auxiliar.topology
                Utilities.resultsMCTOL([logsDir filesep 'Results']);
            else
                Utilities.results([logsDir filesep 'Results'],1);
                Utilities.results([logsDir filesep 'Results']);
            end
            rmpath('Measures');
            rmpath('Algorithms');
            
        end
        
        
        function results(experiment_folder,train)
            global reorderlabels;           
            
            if nargin < 2
                train = 0;
            elseif nargin == 1
                train = train;
            end
                                    
            addpath('Measures');
            addpath('Algorithms');
                        
            experimentos = dir([experiment_folder filesep '*-*']);

            idx=strfind(experiment_folder,'Results');
            scriptpath = [experiment_folder(1:idx-1)];
            %experimentos_scripts = dir([experiment_folder(1:idx-1) 'exp-*']);
            
            % Recorremos las carpetas de experimentos ejecutados para sacar los
            % resultados
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
                    

                    % recomponemos el nombre de los scripts
                    str=predicted_files(1).name;
                    [matchstart,matchend] = regexp( str,'_(.+)\.\d+');
                    dataset=str(matchstart+1:matchend-2);

                    auxscript =  experimentos(i).name;
                    [matchstart,matchend]=regexp(auxscript,dataset);
                    basescript = ['exp-' auxscript(matchend+2:end) '-' dataset '-'];

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
                    % Recorremos cada fichero de test de la carpeta de resultados
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

                        % jsanchez: Si hemos reetiquetado, reequitamos antes de evaluar 
                        % TODO: modificar las funciones de coste de las
                        % métricas ordinales como MAE, AMAE...
                        fid = fopen([scriptpath basescript num2str(j)],'r');
                        tline = fgetl(fid);
                        while ischar(tline)
                            if strcmpi(tline,'reorderlabels')
                                reorderlabels = str2num(fgetl(fid));
                            end
                            tline = fgetl(fid);
                        end
                        fclose(fid);
                        
                        if ~exist('reorderlabels','var') || isempty(reorderlabels)
                            reorderlabels = 0;
                        end

                        switch(reorderlabels)
                            case 1
                                dummyTrain.patterns = zeros(size(act{j}));
                                dummyTrain.targets = act{j};
                                
                                dummyTest.patterns = zeros(size(act{j}));
                                dummyTest.targets = act{j};
                                
                                [dummyTrain,dummyTest] = DataSet.reorderLabels(dummyTrain, dummyTest);
                                act{j} = dummyTest.targets;
                                
                                clear dummyTrain dummyTest;
                            case 2
                                dummyTrain.patterns = zeros(size(act{j}));
                                dummyTrain.targets = act{j};
                                
                                dummyTest.patterns = zeros(size(act{j}));
                                dummyTest.targets = act{j};
                                
                                [dummyTrain,dummyTest] = DataSet.reorderLabelsInverse(dummyTrain, dummyTest);
                                act{j} = dummyTest.targets;
                                
                                clear dummyTrain dummyTest;
                            otherwise
                                % do nothing
                        end
                    end

                    names = {'Dataset', 'Acc', 'MAcc', 'GM', 'MS', 'AUC', 'MAE', 'AMAE', 'MMAE', 'MinMAE','RSpearman', 'Tkendall', 'Wkappa', 'TrainTime', 'TestTime', 'CrossvalTime'};%, 'ClassCCR'};

                    if length(hyp_files)~=0
                        for j=1:numel(struct_hyperparams(1).textdata),
                            names{numel(names)+1} = struct_hyperparams(1).textdata{j};
                        end
                    end

                    accs = cell2mat(cellfun(@CCR.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                    mccrs = cell2mat(cellfun(@MCCR.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                    gms = cell2mat(cellfun(@GM.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                    mss = cell2mat(cellfun(@MS.calculateMetric, act, pred, 'UniformOutput', false)) * 100;
                    aucs = cell2mat(cellfun(@AUC.calculateMetric, act, proj, 'UniformOutput', false));
                    maes = cell2mat(cellfun(@MAE.calculateMetric, act, pred, 'UniformOutput', false));
                    amaes = cell2mat(cellfun(@AMAE.calculateMetric, act, pred, 'UniformOutput', false));
                    maxmaes = cell2mat(cellfun(@MMAE.calculateMetric, act, pred, 'UniformOutput', false));
                    minmaes = cell2mat(cellfun(@MinMAE.calculateMetric, act, pred, 'UniformOutput', false));
                    spearmans = cell2mat(cellfun(@Spearman.calculateMetric, act, pred, 'UniformOutput', false));
                    kendalls = cell2mat(cellfun(@Tkendall.calculateMetric, act, pred, 'UniformOutput', false));
                    wkappas = cell2mat(cellfun(@Wkappa.calculateMetric, act, pred, 'UniformOutput', false));
                    %classccrs = cell2mat(cellfun(@ClassCCR.calculateMetric, act, pred, 'UniformOutput', false));
                    results_matrix = [accs; mccrs; gms; mss; aucs; maes; amaes; maxmaes; minmaes; spearmans; kendalls; wkappas; times(1,:); times(2,:); times(3,:)];%; classccrs];
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
                
%                     if i==1,
%                         fprintf(fid, 'Dataset-Experiment,');
% 
%                         for h = 2:numel(names),
%                             fprintf(fid, 'Mean%s,Std%s,', names{h},names{h});
%                         end
%                         fprintf(fid,'\n');
%                     end

                    % Si no existe previamente el fichero, añadimos la
                    % cabecera                    
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
        
        function resultsMCTOL(experiment_folder,train)
            addpath('Measures');
            addpath('Algorithms');
            
            global reorderlabels;           
            
            if nargin < 2
                train = 0;
            end
                        
            experimentos = dir([experiment_folder filesep '*-*']);

            idx=strfind(experiment_folder,'Results');
            scriptpath = [experiment_folder(1:idx-1)];
            %experimentos_scripts = dir([experiment_folder(1:idx-1) 'exp-*']);
            
            % Recorremos las carpetas de experimentos ejecutados para sacar los
            % resultados
            for i=1:numel(experimentos)
                if experimentos(i).isdir
                    disp([experiment_folder filesep experimentos(i).name filesep 'dataset'])
                    fid = fopen([experiment_folder filesep experimentos(i).name filesep 'dataset'],'r');
                    ruta_dataset = fgetl(fid);
                    fclose(fid);

                    %TODO: Seleccionar qué carpetas se crean o no en
                    %función de los algoritmos
                    topology_files = dir([experiment_folder filesep experimentos(i).name filesep 'Topology' filesep '*stochasticmatrix']);
                    
                    time_files = dir([experiment_folder filesep experimentos(i).name filesep 'Times' filesep '*.*']);
                    hyp_files = dir([experiment_folder filesep experimentos(i).name filesep 'OptHyperparams' filesep '*.*']);
                    
                    % recomponemos el nombre de los scripts
                    str=topology_files(1).name;
                    [matchstart,matchend] = regexp( str,'\.\d+');
                    dataset = str(1:matchstart-1);

                    auxscript =  experimentos(i).name;
                    [matchstart,matchend]=regexp(auxscript,dataset);
                    basescript = ['exp-' auxscript(matchend+2:end) '-' dataset '-'];
                    
                    % TODO: suprimir model_* ??
                    %model_files = dir([experiment_folder filesep experimentos(i).name filesep 'Models' filesep '*.*']);
                    topo_lo_files = dir([experiment_folder filesep experimentos(i).name filesep 'Topology' filesep '*.loss']);
                    topo_od_files = dir([experiment_folder filesep experimentos(i).name filesep 'Topology' filesep '*.ordinalitydegree']);
                    topo_st_files = dir([experiment_folder filesep experimentos(i).name filesep 'Topology' filesep '*.stochasticmatrix']);
                    

                    % Discard "." and ".."
                    time_files = time_files(3:numel(time_files));
                    %model_files = model_files(3:numel(model_files));
                    
                    topo_loss = cell(1,numel(time_files));
                    topo_sthoc = cell(1,numel(time_files));

                    times = [];
                
                    % Recorremos cada fichero de test de la carpeta de resultados
                    for j=1:numel(topology_files)
                        times(:,j) = importdata([experiment_folder filesep experimentos(i).name filesep 'Times' filesep time_files(j).name]);
                        
                        topo_loss{:,j} = importdata([experiment_folder filesep experimentos(i).name filesep 'Topology' filesep topo_lo_files(j).name]);
                        topo_odegree(:,j) = importdata([experiment_folder filesep experimentos(i).name filesep 'Topology' filesep topo_od_files(j).name]);
                        topo_sthoc{:,j} = importdata([experiment_folder filesep experimentos(i).name filesep 'Topology' filesep topo_st_files(j).name]);
                    end
                    
                    names = {'Dataset', 'OrdDegree', 'TrainTime', 'TestTime', 'CrossvalTime'};
                        
                    results_matrix = [topo_odegree; times(1,:); times(2,:); times(3,:)];

    %                 for j=1:numel(struct_hyperparams(1).textdata),
    %                     results_matrix = [results_matrix ; param(j,:) ];
    %                 end


                    results_matrix = results_matrix';

                    fid = fopen([experiment_folder filesep experimentos(i).name filesep 'results.csv'],'w');
                    for h = 1:numel(names),
                        fprintf(fid, '%s,', names{h});
                    end
                    fprintf(fid,'\n');

                    for h = 1:size(results_matrix,1),
                        fprintf(fid, '%s,', time_files(h).name);
                        for z = 1:size(results_matrix,2),
                            fprintf(fid, '%f,', results_matrix(h,z));
                        end
                        fprintf(fid,'\n');
                    end
                    fclose(fid);

                    medias = mean(results_matrix,1);
                    stdev = std(results_matrix,0,1);

                    fid = fopen([experiment_folder filesep 'mean-results.csv'],'at');

                    if i==1,
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

                    % Stochastic Matrices
                    fid = fopen([experiment_folder filesep 'stochastic-matrices.csv'],'at');

                    for h=1:size(topo_sthoc,1)
                        SMtemp = topo_sthoc{h,1};
                        [cm_fi cm_co] = size(SMtemp);

                        fprintf(fid, ['# Stochastic Matrix for ' time_files(h).name ' fold ' num2str(h) '\n']);
                        % For each matrix
                        for mi=1:cm_fi
                            for mj=1:cm_co-1
                                fprintf(fid,'%1.4f\t',SMtemp(mi,mj));
                            end
                            fprintf(fid,'%1.4f\n',SMtemp(mi,cm_co)); 
                        end
                    end

                    fprintf(fid,'\n');
                    fclose(fid);
                
                end
            end
            rmpath('Measures');
            rmpath('Algorithms');
            
        end
                
        
        function logsDir = configureExperiment(ficheroExperimentos,dirSuffix)
            
            if( ~(exist(ficheroExperimentos,'file')))
                fprintf('The file %s does not exist!!!\n',ficheroExperimentos);
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
                %fprintf('configureExperiment: %s\n', nueva_linea)
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
                % jsanchez
%                 elseif strcmpi('algorithm', nueva_linea),
%                      algorithmName = fgetl(fid);
%                      fprintf('\tconfigureExperiment algorithm: %s\n', algorithmName)
                elseif strcmpi('folds', nueva_linea),
                    nOfFolds = str2num(fgetl(fid)); %#ok<ST2NM> % 0 means all
                elseif strcmpi('end experiment', nueva_linea),
                    fichero_ini = [logsDir filesep 'exp-' id_experiment];
                    [matchstart,matchend,tokenindices,matchstring,tokenstring,tokenname,splitstring] = regexpi(datasets,',');
                    if( ~(exist(directory,'dir')))
                        fprintf('The directory %s does not exist!!!\n',directory);
                        return;
                    end
                    [train, test] = Utilities.processDirectory(directory,splitstring);
                    for i=1:numel(train)
                        aux_directory = [resultados filesep splitstring{i} '-' id_experiment];
                        mkdir(aux_directory);
                        
%                         if strcmpi(algorithm,'MCTOL')
%             	            mkdir([aux_directory filesep 'Topology']);
%                         else
%                             mkdir([aux_directory filesep 'OptHyperparams']);
%                         end

                        mkdir([aux_directory filesep 'Topology']);
                        mkdir([aux_directory filesep 'OptHyperparams']);
                        
                        mkdir([aux_directory filesep 'Times']);
                        mkdir([aux_directory filesep 'Models']);
                        mkdir([aux_directory filesep 'Predictions']);
                        mkdir([aux_directory filesep 'Guess']);
                        
                        fichero = [resultados filesep splitstring{i} '-' id_experiment filesep 'dataset'];
                        fich = fopen(fichero,'w');
                        fprintf(fich, [directory filesep splitstring{i} filesep 'gpor']);
                        fclose(fich);
                        % jsanchez: Number of folds
                        if nOfFolds == 0
                            runfolds = numel(train{i});
                        else
                            runfolds = nOfFolds;
                        end
                        
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for executing different experiments in the present framework (data loading, cross-validation and computation of results), presented in the paper Ordinal regression methods: survey and experimental study published in the IEEE Transactions on Knowledge and Data Engineering. 
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Experiment < handle
    % Experiment class
    % This class describes the different methods for running a given experiment in the framework
    
    properties
        
        data = DataSet;
        
        method = KDLOR;
        
        cvCriteria = MAE;
        
        resultsDir = '';
        
        seed = 1;
        
        crossvalide = 0;
        
        kernel_alignment = 0;
                
    end
    
    properties (SetAccess = private)
        
        logsDir
    end
    
    methods
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: launch (Public)
        % Description: This function launches the selected experiment.
        % Type: Void
        % Arguments:
        %          No arguments
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = launch(obj,fichero)
            obj.process(fichero);
            obj.run();
        end
    end
    
    methods(Access = private)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runFolder (private)
        % Description: Function for preprocessing the data, the
        % crossvalidation for each fold and the execution of the method
        % with the optimal parameters.
        % Type: void
        % Arguments:
        %          No arguments
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = run(obj)
            [train,test] = obj.data.preProcessData();
            
            if obj.crossvalide,
                c1 = clock;      
                Optimals = obj.crossValide(train);
                c2 = clock;
                crossvaltime = etime(c2,c1);
                totalResults = obj.method.runAlgorithm(train, test, Optimals);
                totalResults.crossvaltime = crossvaltime;
            else
                totalResults = obj.method.runAlgorithm(train, test);
            end

	    obj.saveResults(totalResults);    
            
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: process (private)
        % Description: Process the information in the experiment file
        % Type: void
        % Arguments:
        %          fichero: file containing the experiment to proccess
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = process(obj,fichero)

            fid = fopen(fichero,'r+');
            
            fprintf('Processing %s\n', fichero)
            
            while ~feof(fid),
                nueva_linea = fgetl(fid);
                nueva_linea = regexprep(nueva_linea, ' ', '');
                
                if strncmpi('directory',nueva_linea,3),
                    obj.data.directory = fgetl(fid);
                elseif strcmpi('train', nueva_linea),
                    obj.data.train = fgetl(fid);
                elseif strcmpi('test', nueva_linea),
                    obj.data.test = fgetl(fid);
                elseif strncmpi('results', nueva_linea, 6),
                    obj.resultsDir = fgetl(fid);
                elseif strncmpi('algorithm',nueva_linea, 3),
                    alg = fgetl(fid);
                    eval(['obj.method = ' alg ';']);
                    obj.method.defaultParameters();
                elseif strncmpi('numfold', nueva_linea, 4),
                    obj.data.nOfFolds = str2num(fgetl(fid));
                elseif strncmpi('standarize', nueva_linea, 5),
                    obj.data.standarize = str2num(fgetl(fid));
                elseif strncmpi('weights', nueva_linea, 7),
                    wei = fgetl(fid);
                    eval(['obj.method.weights = ' wei ';']);
                elseif strncmpi('crossval', nueva_linea, 8),
                    met = upper(fgetl(fid));
                    eval(['obj.cvCriteria = ' met ';']);
                elseif strncmpi('parameter', nueva_linea, 5),
                    nameparameter = sscanf(nueva_linea, 'parameter %s');
                    val = fgetl(fid);
                    if sum(strcmp(nameparameter,obj.method.name_parameters))
                        eval(['obj.method.parameters.' nameparameter ' = [' val '];']);
                        obj.crossvalide = 1;
                    else
                        error('Wrong parameter name - not found');
                    end
                elseif strcmpi('kernel', nueva_linea),
                    obj.method.kernelType = fgetl(fid);
                elseif strcmpi('itermax', nueva_linea),
                    obj.method.itermax = str2num(fgetl(fid));
                elseif strcmpi('activationFunction', nueva_linea),
                    obj.method.activationFunction = fgetl(fid);
                elseif strcmpi('classifier', nueva_linea),
                    val = lower(fgetl(fid));
                    eval(['obj.method.classifier = ' val ';']);
                elseif strcmpi('base_algorithm', nueva_linea),
                    val = fgetl(fid);
                    eval(['obj.method.base_algorithm = ' val ';']);
                elseif strcmpi('seed', nueva_linea),
                    obj.seed = str2num(fgetl(fid));
                elseif strcmpi('modelsdir', nueva_linea),
                    obj.method.modelsdir = fgetl(fid);
                elseif strcmpi('epsilon', nueva_linea),
                    % Numerical value
                    eval(['obj.method.epsilon = ' (fgetl(fid)) ';']);
                else
                    error(['Error reading: ' nueva_linea]);
                end
                
            end
            
            % jsanchez
            if(obj.crossvalide == 0 && numel(obj.method.name_parameters)~=0 ...
                    && ~strcmpi(obj.method.name_parameters,'dummy')),
                obj.crossvalide = 1;
                obj.method.defaultParameters();
                disp('No parameter info found - setting up default parameters.')
            end
            
            fclose(fid);
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: saveResults (private)
        % Description: This file saves the results of the experiment and
        % the best hyperparameters.
        % Type: Void
        % Arguments:
        %           TotalResults--> Results of the experiment
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = saveResults(obj,TotalResults)

            if numel(obj.method.name_parameters)~=0
                outputFile = [obj.resultsDir filesep 'OptHyperparams' filesep obj.data.dataname ];
                fid = fopen(outputFile,'w');
                
                par = fieldnames(TotalResults.model.parameters);
                
                for i=1:(numel(par)),
                    value = getfield(TotalResults.model.parameters,par{i});
                    fprintf(fid,'%s,%f\n', par{i},value);
                end
                
                fclose(fid);
            end
            
            outputFile = [obj.resultsDir filesep 'Times' filesep obj.data.dataname ];
            fid = fopen(outputFile,'w');
            if obj.crossvalide,
                fprintf(fid, '%f\n%f\n%f', TotalResults.trainTime, TotalResults.testTime, TotalResults.crossvaltime);
            else
                fprintf(fid, '%f\n%f\n%f', TotalResults.trainTime, TotalResults.testTime, 0);
            end
            fclose(fid);
            
            
            outputFile = [obj.resultsDir filesep 'Predictions' filesep obj.data.train ];
            dlmwrite(outputFile, TotalResults.predictedTrain);
            outputFile = [obj.resultsDir filesep 'Predictions' filesep obj.data.test ];
            dlmwrite(outputFile, TotalResults.predictedTest);
            
            modelo = TotalResults.model;
            % Write complete model
            outputFile = [obj.resultsDir filesep 'Models' filesep obj.data.dataname '.mat'];
            save(outputFile, 'modelo');
            
            outputFile = [obj.resultsDir filesep 'Guess' filesep obj.data.train ];
            dlmwrite(outputFile, TotalResults.projectedTrain, 'precision', '%.15f');
            
            outputFile = [obj.resultsDir filesep 'Guess' filesep obj.data.test ];
            dlmwrite(outputFile, TotalResults.projectedTest, 'precision', '%.15f');
            
        end
        
             

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: crossValide (private)
        % Description: Function for performing the crossvalidation in a
        %               specific partition. It divides each partition
        %               in k-folds and then adjust the parameters.
        % Type: It returns the optimal parameters.
        % Arguments:
        %           -train--> train patterns
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        function optimals = crossValide(obj,train)
            nOfFolds = obj.data.nOfFolds;
            parameters = obj.method.parameters;
            par = fieldnames(parameters);
            
            combinations = getfield(parameters,par{1});
            
            for i=1:(numel(par)-1),
                if i==1,
                    aux1 = getfield(parameters, par{i});
                else
                    aux1 = combinations;
                end
                aux2 = getfield(parameters, par{i+1});
                combinations = combvec(aux1,aux2);
            end
            
            % Avoid problems with very low number of patterns for some
            % classes
            uniqueTargets = unique(train.targets);
            nOfPattPerClass = sum(repmat(train.targets,1,size(uniqueTargets,1))==repmat(uniqueTargets',size(train.targets,1),1));
            for i=1:size(uniqueTargets,1),
                if(nOfPattPerClass(i)==1)
                    train.patterns = [train.patterns; train.patterns(train.targets==uniqueTargets(i),:)];
                    train.targets = [train.targets; train.targets(train.targets==uniqueTargets(i),:)];
                    [train.targets,idx] = sort(train.targets);
                    train.patterns = train.patterns(idx,:);
                end
            end
            
            % Use the seed
            s = RandStream.create('mt19937ar','seed',obj.seed);
            RandStream.setDefaultStream(s);
            
            CVO = cvpartition(train.targets,'k',nOfFolds);

            result = zeros(CVO.NumTestSets,size(combinations,2));
            % Foreach fold
            for ff = 1:CVO.NumTestSets,
                % Build fold dataset
                trIdx = CVO.training(ff);
                teIdx = CVO.test(ff);
                
                auxTrain.targets = train.targets(trIdx,:);
                auxTrain.patterns = train.patterns(trIdx,:);
                auxTest.targets = train.targets(teIdx,:);
                auxTest.patterns = train.patterns(teIdx,:);
                for i=1:size(combinations,2),
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

            [bestValue,bestIdx] = min(mean(result));
            optimals = combinations(:,bestIdx);
            
        end
        
    end
    
    
end


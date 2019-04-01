classdef SVMOP < Algorithm
    %SVMOP Support vector machines using Frank & Hall method for ordinal
    % regression (by binary decomposition). This class uses libsvm-weights
    % for SVM training (https://www.csie.ntu.edu.tw/~cjlin/libsvm).
    %   SVMOP methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   References:
    %     [1] E. Frank and M. Hall, "A simple approach to ordinal classification"
    %         in Proceedings of the 12th European Conference on Machine Learning,
    %         ser. EMCL'01. London, UK: Springer-Verlag, 2001, pp. 145–156.
    %         https://doi.org/10.1007/3-540-44795-4_13
    %     [2] W. Waegeman and L. Boullart, "An ensemble of weighted support
    %         vector machines for ordinal regression", International Journal
    %         of Computer Systems Science and Engineering, vol. 3, no. 1,
    %         pp. 47–51, 2009.
    %     [3] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
    %         F. Fernández-Navarro and C. Hervás-Martínez
    %         Ordinal regression methods: survey and experimental study
    %         IEEE Transactions on Knowledge and Data Engineering, Vol. 28. Issue 1
    %         2016
    %         http://dx.doi.org/10.1109/TKDE.2015.2457911
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    
    properties
        description = 'Frank Hall Support Vector Machines';
        parameters = struct('C', 0.1, 'k', 0.1);
        weights = true;
    end
    properties (Access = private)
        algorithmMexPath = fullfile(fileparts(which('Algorithm.m')),'libsvm-weights-3.12','matlab');
    end
    
    methods
        
        function obj = SVMOP(varargin)
            %SVMOP SVMOP an object of the class SVMOP and sets its default
            %   characteristics
            %   OBJ = SVMOP(KERNEL) builds SVMOP with RBF as kernel function
            obj.parseArgs(varargin);
        end
        
        function obj = set.weights(obj,w)
            if strcmp(class(obj.weights), class(w))
                obj.weights= w;
            else
                error('weights type is ''%s'' and ''%s'' was provided', class(obj.weights), class(w))
            end
        end
        
        function [projectedTrain, predictedTrain] = privfit( obj, train, param)
            %PRIVFIT trains the model for the SVMOP method with TRAIN data and
            %vector of parameters PARAMETERS. 
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            classes = unique(train.targets);
            nOfClasses = numel(classes);
            patterns = train.patterns(train.targets==1,:);
            labels = train.targets(train.targets == 1);
            
            for i = 2:nOfClasses
                patterns = [patterns ; train.patterns(train.targets==i,:)];
                labels = [labels ; train.targets(train.targets == i)];
            end
            
            trainTargets = labels;
            
            models = cell(1, nOfClasses-1);
            for i = 2:nOfClasses
                
                etiquetas_train = [ ones(size(trainTargets(trainTargets<i))) ;  ones(size(trainTargets(trainTargets>=i)))*2];
                
                % Train
                options = ['-b 1 -t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
                if obj.weights
                    weightsTrain = obj.computeWeights(i-1,trainTargets);
                else
                    weightsTrain = ones(size(trainTargets));
                end
                models{i} = svmtrain(weightsTrain, etiquetas_train, train.patterns, options);
                if(numel(models{i}.SVs)==0)
                    disp('Something went wrong. Please check the training patterns.')
                end
            end
            
            model.models=models;
            model.parameters = param;
            model.weights = obj.weights;
            model.nOfClasses = nOfClasses;
            obj.model = model;
            [projectedTrain, predictedTrain] = obj.predict(train.patterns);

            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
        
        function [projected,predicted] = privpredict(obj,test)
            %PREDICT predicts labels of TEST patterns labels. The object needs to be fitted to the data first.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            projected = zeros(obj.model.nOfClasses, size(test,1));
            for i = 2:obj.model.nOfClasses
                [pr, acc, probTs] = svmpredict(zeros(size(test,1),1),test,obj.model.models{i},'-b 1');
                
                projected(i-1,:) = probTs(:,2)';
            end
            probts(1,:) = ones(size(projected(1,:))) - projected(1,:);
            for i=2:obj.model.nOfClasses
                probts(i,:) =  projected(i-1,:) -  projected(i,:);
            end
            probts(obj.model.nOfClasses,:) =  projected(obj.model.nOfClasses-1,:);
            [aux, predicted] = max(probts);
            predicted = predicted';
            projected = projected';
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
        
        function [weights] = computeWeights(obj, p, targets)
            weights = ones(size(targets));
            weights(targets<=p) = (p+1-targets(targets<=p)) * size(targets(targets<=p),1) / sum(p+1-targets(targets<=p));
            weights(targets>p) = (targets(targets>p)-p) * size(targets(targets>p),1) / sum(targets(targets>p)-p);
        end
        
    end
    
end


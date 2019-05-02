classdef SVC1VA < Algorithm
    %SVC1VA Support Vector Classifier using one-vs-all approach
    %classification by predicting class labels as a regression problem.
    %It uses libSVM-weight SVM implementation.
    %
    %   SVC1VA methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   References:
    %     [1] C.-W. Hsu and C.-J. Lin
    %         A comparison of methods for multi-class support vector machines
    %         IEEE Transaction on Neural Networks,vol. 13, no. 2, pp. 415–425, 2002.
    %         https://doi.org/10.1109/72.991427
    %     [2] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
    %         F. Fernández-Navarro and C. Hervás-Martínez
    %         Ordinal regression methods: survey and experimental study
    %         IEEE Transactions on Knowledge and Data Engineering, Vol. 28. Issue 1
    %         2016
    %         http://dx.doi.org/10.1109/TKDE.2015.2457911
    %     [3] LibSVM website: https://www.csie.ntu.edu.tw/~cjlin/libsvm
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        description = 'Support Vector Machine Classifier with 1vsAll paradigm';
        parameters = struct('C', 0.1, 'k', 0.1);
    end
    properties (Access = private)
        algorithmMexPath = fullfile(fileparts(which('Algorithm.m')),'libsvm-weights-3.12','matlab');
    end
    
    methods
        
        function obj = SVC1VA(varargin)
            %SVC1VA constructs an object of the class SVC1VA and sets its default
            %   characteristics
            %   OBJ = SVC1VA() builds SVC1VA with RBF as kernel function
            obj.parseArgs(varargin);
        end
        
        function [projectedTrain, predictedTrain]= privfit( obj, train, param)
            %PRIVFIT trains the model for the SVC1VA method with TRAIN data and
            %vector of parameters PARAMETERS. 
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            
            options = ['-t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
            
            labelSet = unique(train.targets);
            labelSetSize = length(labelSet);
            models = cell(labelSetSize,1);
            
            for i=1:labelSetSize
                labels = double(train.targets == labelSet(i));
                weights = ones(size(labels));
                models{i} = svmtrain(weights,labels, train.patterns, options);
            end
            
            model = struct('models', {models}, 'labelSet', labelSet);
            model.parameters = param;
            obj.model = model;
            [projectedTrain, predictedTrain] = obj.predict(train.patterns);
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
            
        end
        
        function [projected, predicted]= privpredict(obj, test)
            %PREDICT predicts labels of TEST patterns labels. The object needs to be fitted to the data first.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            labelSet = obj.model.labelSet;
            labelSetSize = length(labelSet);
            models = obj.model.models;
            projected= zeros(size(test, 1), labelSetSize);
            
            for i=1:labelSetSize
                [l,a,d] = svmpredict(zeros(size(test,1),1), test, models{i});
                projected(:, i) = d * (2 * models{i}.Label(1) - 1);
            end
            
            [tmp,predicted] = max(projected, [], 2);
            predicted = labelSet(predicted);
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
            
        end
    end
end

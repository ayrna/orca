classdef CSSVC < Algorithm
    %CSSVC Ordinal Support Vector Classifier using 1VsAll approach with
    %ordinal weights. This class uses |libsvm-weights-3.12| for SVM
    %training available at https://www.csie.ntu.edu.tw/~cjlin/libsvm
    %
    %   CSSVC methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   References:
    %     [1] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
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
        description = 'Support Vector Machine Classifier with 1vsAll paradigm with ordinal weights';
        parameters = struct('C', 0.1, 'k', 0.1);
    end
    properties (Access = private)
        algorithmMexPath = fullfile(fileparts(which('Algorithm.m')),'libsvm-weights-3.12','matlab');
    end
    
    methods
        function obj = CSSVC(varargin)
            %CSSVC constructs an object of the class CSSVC and sets its default
            %   characteristics
            %   OBJ = CSSVC() builds CSSVC with RBF kernel function
            obj.parseArgs(varargin);
        end
        
        function [projectedTrain, predictedTrain] = privfit( obj, train, param)
            %PRIVFIT trains the model for the CSSVC method with TRAIN data and
            %vector of parameters PARAM. 
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            options = ['-t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
            
            labelSet = unique(train.targets);
            labelSetSize = length(labelSet);
            models = cell(labelSetSize,1);
            
            for i=1:labelSetSize
                labels = double(train.targets == labelSet(i));
                weights = CSSVC.ordinalWeights(i, train.targets);
                models{i} = svmtrain(weights,labels, train.patterns, options);
            end
            model = struct('models', {models}, 'labelSet', labelSet);
            model.parameters = param;
            obj.model = model;
            [projectedTrain,predictedTrain] = obj.predict(train.patterns);
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
        
        function [decv, pred]= privpredict(obj, test)
            %PREDICT predicts labels of TEST patterns labels. The object needs to be fitted to the data first.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            labelSet = obj.model.labelSet;
            labelSetSize = length(labelSet);
            models = obj.model.models;
            decv= zeros(size(test, 1), labelSetSize);
            
            for i=1:labelSetSize
                [l,a,d] = svmpredict(zeros(size(test,1),1), test, models{i});
                decv(:, i) = d * (2 * models{i}.Label(1) - 1);
            end
            
            [tmp,pred] = max(decv, [], 2);
            pred = labelSet(pred);
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
    end
    methods (Static = true)
        function [w] = ordinalWeights(p, targets)
            %ORDINALWEIGHTS compute the weights to apply to the set of
            %training patterns.
            %   [W] = ORDINALWEIGHTS(P, TARGETS) compute the weights of P,
            %   scalar corresponding to the indexes of the classes or class
            %   being considered, and TARGETS, training targets.
            w = ones(size(targets));
            w(targets~=p) = (abs(p-targets(targets~=p))+1) * size(targets(targets~=p),1) / sum(abs(p-targets(targets~=p))+1);
            w(targets==p) = 1;
        end
    end
end

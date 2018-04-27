classdef SVR < Algorithm
    %SVR implements Support Vector Regression to perform ordinal
    %classification by predicting class labels as a regression problem.
    %It uses libSVM-weight SVM implementation.
    %
    %   SVR methods:
    %      runAlgorithm               - runs the corresponding algorithm,
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
    %     [2] C.-W. Hsu and C.-J. Lin
    %         A comparison of methods for multi-class support vector machines
    %         IEEE Transaction on Neural Networks,vol. 13, no. 2, pp. 415–425, 2002.
    %         https://doi.org/10.1109/72.991427
    %     [3] LibSVM website: https://www.csie.ntu.edu.tw/~cjlin/libsvm
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        description = 'Support Vector Regression';
        parameters = struct('C', 0.1, 'k', 0.1, 'e', 0.1);
    end
    
    properties (Access = private)
        algorithmMexPath = fullfile(fileparts(which('Algorithm.m')),'libsvm-weights-3.12','matlab');
    end
    
    methods
        
        function obj = SVR(varargin)
            %SVR constructs an object of the class SVR and sets its default
            %   characteristics
            %   OBJ = SVR() builds SVR with RBF as kernel function
        end
        
        function [projectedTrain,predictedTrain] = privfit(obj,train,parameters)
            %PRIVFIT trains the model for the SVR method with TRAIN data and
            %vector of parameters PARAMETERS. 
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            nOfClasses = numel(unique(train.targets));
            % Scale the targets
            auxTrain = train;
            auxTrain.targets = (auxTrain.targets-1)/(nOfClasses-1);
            svrParameters = ...
                ['-s 3 -t 2 -c ' num2str(parameters.C) ' -p ' num2str(parameters.e) ' -g '  num2str(parameters.k) ' -q'];
            
            weights = ones(size(auxTrain.targets));
            model.libsvmModel = svmtrain(weights, auxTrain.targets, auxTrain.patterns, svrParameters);
            model.scaledLabelSet = unique(auxTrain.targets);
            model.parameters = parameters;
            obj.model = model;
            
            [projectedTrain, predictedTrain] = obj.predict(auxTrain.patterns);
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
        
        function [projected, predicted]= privpredict(obj, test)
            %PREDICT predict labels of TEST patterns labels using MODEL.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            [projected err] = svmpredict(ones(size(test,1),1), test, obj.model.libsvmModel);
            
            classMembership = repmat(projected, 1,numel(obj.model.scaledLabelSet));
            classMembership = abs(classMembership -  ones(size(classMembership,1),1)*obj.model.scaledLabelSet');
            
            [m,predicted]=min(classMembership,[],2);
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
        
    end
end


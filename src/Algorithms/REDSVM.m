classdef REDSVM < Algorithm
    %REDSVM Reduction from ordinal regression to binary SVM classifiers [1].
    %The configuration used is the identity coding matrix, the absolute
    %cost matrix and the standard binary soft-margin SVM. This class uses
    %libsvm-rank-2.81 implementation
    %(http://www.work.caltech.edu/~htlin/program/libsvm/)
    %
    %   REDSVM methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   References:
    %     [1] H.-T. Lin and L. Li, "Reduction from cost-sensitive ordinal
    %         ranking to weighted binary classification" Neural Computation,
    %         vol. 24, no. 5, pp. 1329-1367, 2012.
    %         http://10.1162/NECO_a_00265
    %     [2] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
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
    %
    properties
        description = 'Reduction from OR to weighted binary classification (SVM)';
        parameters = struct('C', 0.1, 'k', 0.1);
    end
    properties (Access = private)
        algorithmMexPath = fullfile(fileparts(which('Algorithm.m')),'libsvm-rank-2.81','matlab');
    end
    
    methods
        
        function obj = REDSVM(varargin)
            %REDSVM constructs an object of the class REDSVM and sets its default
            %   characteristics
            %   OBJ = REDSVM() builds REDSVM with RBF kernel function
            obj.parseArgs(varargin);
        end
        
        function [projectedTrain, predictedTrain]= privfit( obj, train , param)
            %PRIVFIT trains the model for the REDSVM method with TRAIN data and
            %vector of parameters PARAMETERS.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            options = ['-s 5 -t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
            model.libsvmModel = svmtrain(train.targets, train.patterns, options);
            model.parameters = param;
            obj.model = model;
            [predictedTrain, acc, projectedTrain] = svmpredict(train.targets,train.patterns,model.libsvmModel, '');
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
        
        function [projected, predicted]= predict(obj,test)
            %PREDICT predict labels of TEST patterns labels using MODEL.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            [predicted, acc, projected] = svmpredict(ones(size(test,1),1),test,obj.model.libsvmModel, '');
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
            
        end
    end
end

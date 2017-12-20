classdef LRLIBLINEAR < Algorithm
    %LRLIBLINEAR liblinear [1] implementation of regularized logistic
    %regression, more information at https://www.csie.ntu.edu.tw/~cjlin/liblinear/.
    %
    %   LRLIBLINEAR methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   LRLIBLINEAR parameters are:
    %   - parameters.c: penalty cost of misclassification
    %   - solver: the type of solver (default 0), options are the liblinear
    %     options for '-s' for multi-class classification:
    %       0 -- L2-regularized logistic regression (primal)
    %       1 -- L2-regularized L2-loss support vector classification (dual)
    %       2 -- L2-regularized L2-loss support vector classification (primal)
    %       3 -- L2-regularized L1-loss support vector classification (dual)
    %       4 -- support vector classification by Crammer and Singer
    %       5 -- L1-regularized L2-loss support vector classification
    %       6 -- L1-regularized logistic regression
    %       7 -- L2-regularized logistic regression (dual)
    %
    %   References:
    %     [1] R.-E. Fan, K.-W. Chang, C.-J. Hsieh, X.-R. Wang, and C.-J. Lin,
    %         LIBLINEAR: A library for large linear classification,
    %         Journal of Machine Learning Research, Vo. 9, 1871-1874, 2008
    %         http://jmlr.csail.mit.edu/papers/v9/fan08a.html
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        solver = 0;
        parameters = struct('c', 0.1);
        algorithmMexPath = fullfile(pwd,'Algorithms','liblinear-2.20','matlab');
        %algorithmMexPath = fullfile(pwd,'Algorithms','liblinear-1.96','matlab');
    end
    
    methods
        
        function obj = LRLIBLINEAR()
            %LRLIBLINEAR constructs an object of the class LRLIBLINEAR.
            %Default solver is '0' (L2-regularized logistic regression
            %(primal)). Parameter c have to be optimized in order to obtain
            %suitable model fitting
            obj.name = 'Logistic Regression with liblinear solver';
        end
        
        function [model, projectedTrain, predictedTrain]= fit( obj, train, param)
            %FIT trains the model for the LRLIBLINEAR method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            
            options = ['-s ' num2str(obj.solver) ' -c ' num2str(param.c) ' -q'];
            model.libsvmModel = svmtrain(train.targets, sparse(train.patterns), options);
            model.algorithm = 'LRLIBLINEAR';
            model.parameters = param;
            [projectedTrain,predictedTrain] = obj.predict(train.patterns,model);
            
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
        
        function [projected, predicted]= predict(obj,test, model)
            %PREDICT predicts labels of TEST patterns labels using MODEL.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            
            [predicted, acc, projected] = svmpredict(ones(size(test,1),1),sparse(test),model.libsvmModel);
            
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
    end
end

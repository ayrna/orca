classdef SVC1V1 < Algorithm
    %SVC1V1 Support Vector Classifier using one-vs-one approach
    %classification by predicting class labels as a regression problem.
    %It uses libSVM-weight SVM implementation.
    %
    %   SVC1V1 methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
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
        name_parameters = {'C','k'};
        parameters;
    end
    
    methods
        
        function obj = SVC1V1(kernel)
            %SVC1V1 constructs an object of the class SVR and sets its default
            %   characteristics
            %   OBJ = SVC1V1(KERNEL) builds SVC1V1 with KERNEL as kernel function
            obj.name = 'Support Vector Machine Classifier with 1vs1 paradigm';
            if(nargin ~= 0)
                obj.kernelType = kernel;
            else
                obj.kernelType = 'rbf';
            end
            
        end
        
        function obj = defaultParameters(obj)
            %DEFAULTPARAMETERS It assigns the parameters of the algorithm
            %   to a default value.
            % cost
            obj.parameters.C = 10.^(-3:1:3);
            % kernel width
            obj.parameters.k = 10.^(-3:1:3);
        end
        
        function [mInf] = runAlgorithm(obj,train, test, parameters)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter
            %   values for the method. Test the generalization performance
            %   with TRAIN and TEST data and returns predictions and model
            %   in mInf structure.
            param.C = parameters(1);
            param.k = parameters(2);
            
            c1 = clock;
            model = obj.train(train,param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            [mInf.projectedTrain,mInf.predictedTrain] = obj.test(train,model);
            [mInf.projectedTest,mInf.predictedTest] = obj.test(test,model);
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            
            model.algorithm = 'SVC1V1';
            model.parameters = param;
            mInf.model = model;
        end
        
        function [model]= train( obj, train , param)
            %TRAIN trains the model for the SVR method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            addpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
            
            weights = ones(size(train.targets));
            options = ['-t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
            model = svmtrain(weights, train.targets, train.patterns, options);
            
            rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
        end
        
        function [projected, testTargets]= test(obj,test, model)
            %TEST predict labels of TEST patterns labels using MODEL.
            addpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
            [testTargets, acc, projected] = svmpredict(test.targets,test.patterns,model, '');
            rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
            
        end
    end
end

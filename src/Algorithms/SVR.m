classdef SVR < Algorithm
    %SVR implements Support Vector Regression to perform ordinal
    %classification by predicting class labels as a regression problem.
    %It uses libSVM-weight SVM implementation. 
    %
    %   SVR methods:
    %      runAlgorithm               - runs the corresponding algorithm, 
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
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
        name_parameters = {'C','k','e'};
        parameters;
    end
    
    methods
        
        function obj = SVR(kernel)
            %SVR constructs an object of the class SVR and sets its default 
            %   characteristics
            %   OBJ = SVR(KERNEL) builds SVR with KERNEL as kernel function
            obj.name = 'Support Vector Regression';
            if(nargin ~= 0)
                obj.kernelType = kernel;
            else
                obj.kernelType = 'rbf';
            end
        end
        
        function obj = defaultParameters(obj)
            %DEFAULTPARAMETERS It assigns the parameters of the algorithm 
            %   to a default value.
            obj.parameters.C = 10.^(3:-1:-3);
            % kernel width
            obj.parameters.k = 10.^(3:-1:-3);
            % epsilon
            obj.parameters.e = 10.^(-3:1:0);
        end
                
        function mInf = runAlgorithm(obj,train, test, parameters)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter 
            %   values for the method. Test the generalization performance 
            %   with TRAIN and TEST data and returns predictions and model
            %   in mInf structure. 
            addpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
            
            param.C = parameters(1);
            param.k = parameters(2);
            param.e = parameters(3);
            
            c1 = clock;
            % Scale the targets
            nOfClasses = numel(unique(train.targets));
            
            auxTrain = train;
            auxTest = test;
            
            auxTrain.targets = (auxTrain.targets-1)/(nOfClasses-1);
            auxTest.targets = (auxTest.targets-1)/(nOfClasses-1);
            
            classes = unique([auxTrain.targets' auxTest.targets']);
            
            model = obj.train( auxTrain, param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            [mInf.projectedTrain, mInf.predictedTrain] = obj.test( auxTrain,model,classes );
            [mInf.projectedTest, mInf.predictedTest] = obj.test( auxTest,model,classes );
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            
            model.algorithm = 'SVR';
            model.parameters = param;
            %mInf.projection = model.SVs' * model.sv_coef;
            mInf.model = model;
            
            rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
        end
        
        function model = train(obj,train, parameters)
            %TRAIN trains the model for the SVR method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model. 
            
            svrParameters = ...
                ['-s 3 -t 2 -c ' num2str(parameters.C) ' -p ' num2str(parameters.e) ' -g '  num2str(parameters.k) ' -q'];
            
            weights = ones(size(train.targets));
            model = svmtrain(weights, train.targets, train.patterns, svrParameters);
            
        end
        
        
        % TODO: remove class parameters. Avoid using test.targets
        function [projected, predicted]= test(obj, test, model,classes)
            %TEST predict labels of TEST patterns labels using MODEL. 
            
            [projected err] = svmpredict(test.targets, test.patterns, model);
            
            classMembership = repmat(projected, 1,numel(classes));
            classMembership = abs(classMembership -  ones(size(classMembership,1),1)*classes);
            
            [m,predicted]=min(classMembership,[],2);
            
        end
        
    end
    
    
end


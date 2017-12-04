
classdef REDSVM < Algorithm
    %REDSVM Reduction from ordinal regression to binary SVM classifiers [1].
    %The configuration used is the identity coding matrix, the absolute
    %cost matrix and the standard binary soft-margin SVM. This class uses
    %libsvm-rank-2.81 implementation
    %(http://www.work.caltech.edu/~htlin/program/libsvm/)
    %
    %   REDSVM methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
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
        
        parameters;
        
        name_parameters = {'C','k'};
        algorithmMexPath = fullfile('Algorithms','libsvm-rank-2.81','matlab');
    end
    
    methods
        
        function obj = REDSVM(kernel)
            %REDSVM constructs an object of the class SVR and sets its default
            %   characteristics
            %   OBJ = REDSVM(KERNEL) builds REDSVM with KERNEL as kernel function
            obj.name = 'Reduction from OR to weighted binary classification (SVM)';
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
            nParam = numel(obj.name_parameters);
            if nParam~= 0
                parameters = reshape(parameters,[1,nParam]);
                param = cell2struct(num2cell(parameters(1:nParam)),obj.name_parameters,2);
            else
                param = [];
            end
            
            c1 = clock;
            [model,mInf.projectedTrain, mInf.predictedTrain] = obj.train(train,param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            [mInf.projectedTest, mInf.predictedTest] = obj.test(test.patterns, model);
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            mInf.model = model;
            
        end
        
        function [model, projectedTrain, predictedTrain]= train( obj, train , param)
            %TRAIN trains the model for the SVR method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            options = ['-s 5 -t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
            model.libsvmModel = svmtrain(train.targets, train.patterns, options);
            model.algorithm = 'REDSVM';
            model.parameters = param;
            [predictedTrain, acc, projectedTrain] = svmpredict(train.targets,train.patterns,model.libsvmModel, '');
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end            
        end
        
        function [projected, predicted]= test(obj,test, model)
            %TEST predict labels of TEST patterns labels using MODEL.
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            [predicted, acc, projected] = svmpredict(ones(size(test,1),1),test,model.libsvmModel, '');
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
            
        end
    end
end

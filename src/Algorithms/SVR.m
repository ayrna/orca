classdef SVR < Algorithm
    %SVR Support Vector Regression
    
    properties
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: parameters (Public)
        % Type: Struct
        % Description: This variable keeps the values for
        %               the C penalty coefficient, the
        %               kernel parameters and epsilon
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        name_parameters = {'C','k','e'}
        parameters
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: SVR (Public Constructor)
        % Description: It constructs an object of the class
        %               SVR and sets its characteristics.
        % Type: Void
        % Arguments:
        %           kernel--> Type of Kernel function
        %           opt--> Type of optimization used in the method.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = SVR(kernel)
            obj.name = 'Support Vector Regression';
            if(nargin ~= 0)
                obj.kernelType = kernel;
            else
                obj.kernelType = 'rbf';
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: defaultParameters (Public)
        % Description: It assigns the parameters of the
        %               algorithm to a default value.
        % Type: Void
        % Arguments:
        %           No arguments for this function.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = defaultParameters(obj)
            obj.parameters.C = 10.^(3:-1:-3);
            obj.parameters.k = 10.^(3:-1:-3);
            obj.parameters.e = 10.^(-3:1:0);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runAlgorithm (Public)
        % Description: This function runs the corresponding
        %               algorithm, fitting the model, and
        %               testing it in a dataset. It also
        %               calculates some statistics as CCR,
        %               Confusion Matrix, and others.
        % Type: It returns a set of statistics (Struct)
        % Arguments:
        %           Train --> Trainning data for fitting the model
        %           Test --> Test data for validation
        %           parameters --> Penalty coefficient C
        %           for the SVRPCDOC method and kernel parameters
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [model_information] = runAlgorithm(obj,train, test, parameters)
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
            model_information.trainTime = etime(c2,c1);            
            
            c1 = clock;
            [model_information.projectedTrain, model_information.predictedTrain] = obj.test( auxTrain,model,classes );
            [model_information.projectedTest, model_information.predictedTest] = obj.test( auxTest,model,classes );
            c2 = clock;
            model_information.testTime = etime(c2,c1);
            
            model.algorithm = 'SVR';
            model.parameters = param;
            %model_information.projection = model.SVs' * model.sv_coef;
            model_information.model = model;
            
            rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
        end
        
        
        function model = train(obj,train, parameters)
            
            svrParameters = ...
                ['-s 3 -t 2 -c ' num2str(parameters.C) ' -p ' num2str(parameters.e) ' -g '  num2str(parameters.k) ' -q'];
            
            weights = ones(size(train.targets));
            model = svmtrain(weights, train.targets, train.patterns, svrParameters);
            
        end
        
        
        function [projected, predicted]= test(obj, test, model,classes)
            
            [projected err] = svmpredict(test.targets, test.patterns, model);
            
            pertenencia_clase = repmat(projected, 1,numel(classes));
            pertenencia_clase = abs(pertenencia_clase -  ones(size(pertenencia_clase,1),1)*classes);
            
            [m,predicted]=min(pertenencia_clase,[],2);
            
        end
        
    end
    
    
end


classdef SVC_1vA < Algorithm
    %SVC_1v1 Support Vector Classifier using 1VsAll approach
    %   This class derives from the Algorithm Class and implements the
    %   SVC_1v1 method. 
    %   Characteristics: 
    %               -Kernel functions: Yes
    %               -Ordinal: Yes
    %               -Parameters: 
    %                       -C: Penalty coefficient
    %                       -Others (depending on the kernel choice)
    
    properties
       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: parameters (Public)
        % Type: Struct
        % Description: This variable keeps the values for 
        %               the C penalty coefficient and the 
        %               kernel parameters
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        name_parameters = {'C','k'}
        parameters
    end
    
    methods
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: SVC_1v1 (Public Constructor)
        % Description: It constructs an object of the class
        %               SVC_1v1 and sets its characteristics.
        % Type: Void
        % Arguments: 
        %           kernel--> Type of Kernel function
        %           opt--> Type of optimization used in the method.
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = SVC_1vA(kernel)
            obj.name = 'Support Vector Machine Classifier with 1vsAll paradigm';
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
            obj.parameters.C = 10.^(-3:1:3);
            obj.parameters.k = 10.^(-3:1:3);
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
        %           for the KDLOR method and kernel parameters
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [model_information] = runAlgorithm(obj,train, test, parameters)
            	addpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
                param.C = parameters(1);
                param.k = parameters(2);
                
                c1 = clock;
                model = obj.train(train, param);
                c2 = clock;
                model_information.trainTime = etime(c2,c1);
                
                c1 = clock;
                [model_information.projectedTrain, model_information.predictedTrain] = obj.test(train,model);
                [model_information.projectedTest,model_information.predictedTest ] = obj.test(test,model);
                c2 = clock;
                model_information.testTime = etime(c2,c1);
                           
                model.algorithm = 'SVC_1vA';
                model.parameters = param;
                model_information.model = model;

            	rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the KDLOR algorithm.
        % Type: [Array, Array]
        % Arguments: 
        %           trainPatterns --> Trainning data for 
        %                              fitting the model
        %           testTargets --> Training targets
        %           parameters --> Penalty coefficient C 
        %           for the KDLOR method and kernel parameters
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [model]= train( obj, train, param)  
            options = ['-t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
            
            labelSet = unique(train.targets);
            labelSetSize = length(labelSet);
            models = cell(labelSetSize,1);

            for i=1:labelSetSize,
                etiquetas = double(train.targets == labelSet(i));
                weights = ones(size(etiquetas));
                models{i} = svmtrain(weights,etiquetas, train.patterns, options);
            end

            model = struct('models', {models}, 'labelSet', labelSet);

        end
        
        function [decv, pred]= test(obj, test, model)
            
            labelSet = model.labelSet;
            labelSetSize = length(labelSet);
            models = model.models;
            decv= zeros(size(test.targets, 1), labelSetSize);

            for i=1:labelSetSize
                etiquetas = double(test.targets == labelSet(i));
                [l,a,d] = svmpredict(etiquetas, test.patterns, models{i});
                decv(:, i) = d * (2 * models{i}.Label(1) - 1);
            end

            [tmp,pred] = max(decv, [], 2);
            pred = labelSet(pred);

        end      
    end
end

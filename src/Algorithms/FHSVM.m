classdef FHSVM < Algorithm
    % FHSVM Support vector machines using Frank & Hall method for ordinal
    % regression (by binary decomposition)
    %   This class derives from the Algorithm Class and implements the
    %   FHSVM method.
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
        weights = true;
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: FHSVM (Public Constructor)
        % Description: It constructs an object of the class
        %               FHSVM and sets its characteristics.
        % Type: Void
        % Arguments:
        %           kernel--> Type of Kernel function
        %           opt--> Type of optimization used in the method.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = FHSVM(kernel)
            obj.name = 'Frank Hall Support Vector Machines';
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
        %           for the SVM method
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [model_information] = runAlgorithm(obj,train, test, parameters)
            addpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
            
            param.C = parameters(1);
            param.k = parameters(2);
            
            
            c1 = clock;
            classes = unique(train.targets);
            nOfClasses = numel(classes);
            [models] = obj.train(train,nOfClasses,param.C,param.k);
            c2 = clock;
            model_information.trainTime = etime(c2,c1);
            
            c1 = clock;
            % Probabilities are included as ProjectedTrain and
            % ProjectedTest
            [model_information.projectedTrain,model_information.predictedTrain] = obj.test(train,models,nOfClasses);
            [model_information.projectedTest,model_information.predictedTest] = obj.test(test,models,nOfClasses);
            c2 = clock;
            model_information.testTime = etime(c2,c1);
            
            model.models=models;
            model.algorithm = 'FHSVM';
            model.parameters = param;
            model.weights = obj.weights;
            model_information.model = model;
            
            rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the FHSVM algorithm.
        % Type: [Array, Array]
        % Arguments:
        %           trainPatterns --> Trainning data for
        %                              fitting the model
        %           testTargets --> Training targets
        %           parameters --> Penalty coefficient C
        %           for the KDLOR method and kernel parameters
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [models]= train( obj,train,nOfClasses,C,k)
            
            patrones = train.patterns(train.targets==1,:);
            etiq = train.targets(train.targets == 1);
            
            for i = 2:nOfClasses,
                patrones = [patrones ; train.patterns(train.targets==i,:)];
                etiq = [etiq ; train.targets(train.targets == i)];
            end
            
            train.targets = etiq;
            train.patterns = patrones';
            
            models = cell(1, nOfClasses-1);
            for i = 2:nOfClasses,
                
                etiquetas_train = [ ones(size(train.targets(train.targets<i))) ;  ones(size(train.targets(train.targets>=i)))*2];
                
                % Train
                options = ['-b 1 -t 2 -c ' num2str(C) ' -g ' num2str(k) ' -q'];
                if obj.weights,
                    weightsTrain = obj.waegemanWeights(i-1,train.targets);
                else
                    weightsTrain = ones(size(train.targets));
                end
                models{i} = svmtrain(weightsTrain, etiquetas_train, train.patterns', options);
                if(numel(models{i}.SVs)==0)
                    etiquetas_train
                end
            end
            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test a model given
        %               a set of test patterns.
        % Type: [Array, Array]
        % Arguments:
        %           testPatterns --> Testing data
        %           projection --> Projection previously
        %                       calculated fitting the model
        %           thresholds --> Thresholds previously
        %                       calculated fitting the model
        %           trainPatterns --> Trainning data (needed
        %                              for the gram matrix)
        %           kernelParam --> kernel parameter for KDLOR
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [probTest,clasetest] = test(obj,test,models,nOfClasses)
            probTest = zeros(nOfClasses, size(test.patterns,1));
            for i = 2:nOfClasses,
                etiquetas_test = [ ones(size(test.targets(test.targets<i))) ;  ones(size(test.targets(test.targets>=i)))*2];
                [pr, acc, probTs] = svmpredict(etiquetas_test,test.patterns,models{i},'-b 1');

                probTest(i-1,:) = probTs(:,2)';
            end
            probts(1,:) = ones(size(probTest(1,:))) - probTest(1,:);
            for i=2:nOfClasses,
                probts(i,:) =  probTest(i-1,:) -  probTest(i,:);
            end
            probts(nOfClasses,:) =  probTest(nOfClasses-1,:);
            [aux, clasetest] = max(probts);
            clasetest = clasetest';
        end
        
        
        
        function [weights] = waegemanWeights(obj, p, targets)
            weights = ones(size(targets));
            weights(targets<=p) = (p+1-targets(targets<=p)) * size(targets(targets<=p),1) / sum(p+1-targets(targets<=p));
            weights(targets>p) = (targets(targets>p)-p) * size(targets(targets>p),1) / sum(targets(targets>p)-p);
        end
        
    end
    
end


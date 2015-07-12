classdef SVORLin < Algorithm
    % SVOR Support Vector for Ordinal Regression (Implicit constraints)
    %   This class derives from the Algorithm Class and implements the
    %   SVORIM method.
    %   Characteristics:
    %               -Kernel functions: Yes
    %               -Ordinal: Yes
    
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
        
        parameters
        name_parameters = {'C'}
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: SVORIM (Public Constructor)
        % Description: It constructs an object of the class
        %               SVORIM and sets its characteristics.
        % Type: Void
        % Arguments:
        %           kernel--> Type of Kernel function
        %           opt--> Type of optimization used in the method.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = SVORLin()
            obj.name = 'Support Vector for Ordinal Regression (Implicit constraints / Linear)';

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
            obj.parameters.C =  10.^(-3:1:3);
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
        %           for the SVORIM method and kernel parameters
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [model_information] = runAlgorithm(obj,train, test, parameters)
            
            param.C = parameters(1);
            
            
            c1 = clock;
            [model,model_information.projectedTest,model_information.projectedTrain, model_information.trainTime, model_information.testTime] = obj.train([train.patterns train.targets],[test.patterns test.targets],param);
            % thresholds = SVORIM.adaptThresholds(train.targets, model_information.projectedTrain);
            c2 = clock;
            model_information.trainTime = etime(c2,c1);


            % Cross validar con una partición de los datos
            %cv = cvpartition(train.targets,'holdout',0.5);
            %[validateProject, alpha, thresholds, trainProject] = svorex([train.patterns(cv.test,:) train.targets(cv.test,:)],[train.patterns(~cv.test,:) train.targets(~cv.test,:)],param.k,param.C);
            %thresholds = obj.adaptThresholds(train.targets(~cv.test,:), validateProject);
            %trainProject = sum(repmat(alpha,size(train.patterns,1),1).*computeKernelMatrix(train.patterns',train.patterns(cv.test,:)',obj.kernelType, param.k),2)';
            %testProject =
            %sum(repmat(alpha,size(test.patterns,1),1).*computeKernelMatrix(test.patterns',train.patterns(cv.test,:)',obj.kernelType, param.k),2)';
            
            c1 = clock; 
            model_information.predictedTrain = obj.test(model_information.projectedTrain, model);
            model_information.predictedTest = obj.test(model_information.projectedTest, model);
            c2 = clock;
            model_information.testTime = etime(c2,c1);
            model_information.model = model;
            
        end
        
        
        function [model, projectedTest, projectedTrain, trainTime, testTime] = train(obj, train,test, parameters)
            
                 [projectedTest, alpha, thresholds, projectedTrain, trainTime, testTime] = svorim(train,test,1,parameters.C,0,0,1);
                  model.projection = alpha;
                  model.thresholds = thresholds; 
                  model.parameters = parameters;
                  model.algorithm = 'SVORLin';
        end
        
        function [targets] = test(obj, project, model)
            
            numClasses = size(model.thresholds,2)+1;
            project2 = repmat(project, numClasses-1,1);
            project2 = project2 - model.thresholds'*ones(1,size(project2,2));
            
            % Asignation of the class
            % f(x) = max {Wx-bk<0} or Wx - b_(K-1) > 0
            wx=project2;
            
            % The procedure for that is the following:
            % We assign the values > 0 to NaN
            wx(wx(:,:)>0)=NaN;
            
            % Then, we choose the bigger one.
            [maximum,targets]=max(wx,[],1);
            
            % If a max is equal to NaN is because Wx-bk for all k is >0, so this
            % pattern below to the last class.
            targets(isnan(maximum(:,:)))=numClasses;
            
            targets = targets';
            
        end
        
       
        
    end
    
    
end


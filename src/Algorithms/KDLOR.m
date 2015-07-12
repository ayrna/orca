classdef KDLOR < Algorithm
    %KDLOR Kernel Discriminant Learning for Ordinal Regression
    %   This class derives from the Algorithm Class and implements the
    %   KLDOR method. 
    %   Characteristics: 
    %               -Kernel functions: Yes
    %               -Ordinal: Yes
    %               -Parameters: 
    %                       -C: Penalty coefficient
    %                       -Others (depending on the kernel choice)
    
    properties
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: optimizationMethod (Public)
        % Type: String
        % Description: It specifies the method used for 
        %              optimizing the discriminant funcion
        %              of the model. It can be quadprog, 
        %               qp, or cvx.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        optimizationMethod = 'quadprog'
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: parameters (Public)
        % Type: Struct
        % Description: This variable keeps the values for 
        %               the C penalty coefficient and the 
        %               kernel parameters
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        name_parameters = {'C','k','u'}
        parameters
    end
    
    methods
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: KDLOR (Public Constructor)
        % Description: It constructs an object of the class
        %               KDLOR and sets its characteristics.
        % Type: Void
        % Arguments: 
        %           kernel--> Type of Kernel function
        %           opt--> Type of optimization used in the method.
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = KDLOR(kernel, opt)
            obj.name = 'Kernel Discriminant Learning for Ordinal Regression';
            if(nargin ~= 0)
                 obj.kernelType = kernel;
            else
                obj.kernelType = 'rbf';
            end
            if(nargin > 1)
                obj.optimizationMethod = opt;
            else
                obj.optimizationMethod = 'quadprog';
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: set.optimizationMethod (Public)
        % Description: It verifies if the value for the 
        %               variable optimizationMethod 
        %                   is correct.
        % Type: Void
        % Arguments: 
        %           value--> Value for the variable optimizationMethod.
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = set.optimizationMethod(obj, value)
            if ~(strcmpi(value,'quadprog') || strcmpi(value,'qp') || strcmpi(value,'cvx'))
                   error('Invalid value for optimizer');
            else
                   obj.optimizationMethod = value;
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
                obj.parameters.C = [0.1,1,10,100];
                obj.parameters.k = 10.^(-3:1:3);
                obj.parameters.u = [0.01,0.001,0.0001,0.00001,0.000001];
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
                
                param.C = parameters(1);
                param.k = parameters(2);
                %param.u = parameters(3);
                
                if strcmp(obj.kernelType, 'sigmoid'),
                    param.k = [parameters(2),parameters(3)];
                    if numel(parameters)>3,
                        param.u = parameters(4);
                    else
                        param.u = 0.01;
                    end
                else
                    if numel(parameters)>2,
                        param.u = parameters(3);
                    else
                        param.u = 0.01;
                    end
               
                end
                
                c1 = clock;
                [model]= obj.train( train.patterns', train.targets', param);
                c2 = clock;
                model_information.trainTime = etime(c2,c1);
                
                c1 = clock;
                [model_information.projectedTrain, model_information.predictedTrain] = obj.test( train.patterns', train.patterns', model);
                [model_information.projectedTest, model_information.predictedTest] = obj.test( test.patterns', train.patterns', model);            
                c2 = clock;
                % time information for testing
                model_information.testTime = etime(c2,c1);
                
                model_information.model = model;
                

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
        
        function [model]= train( obj,trainPatterns, trainTargets , parameters)
                [dim,numTrain] = size(trainPatterns);

                if(nargin < 2)
                    error('Patterns and targets are needed.\n');
                end

                if length(trainTargets) ~= size(trainPatterns,2)
                    error('Number of patterns and targets should be the same.\n');
                end

                    if(nargin < 4)
                            % Default parameters
                            d=10;
                            u=0.001;

                            switch obj.kernelType
                                case 'rbf'
                                    kernelParam = 1;
                                case 'sigmoid'
                                    kernelParam = [1,2];
                                case 'linear'
                                    kernelParam = 1;
                            end
                    else
                            d = parameters.C;
                            u = parameters.u;
                            kernelParam = parameters.k;
                    end



                % Compute the Gram or Kernel matrix
                kernelMatrix = computeKernelMatrix(trainPatterns, trainPatterns,obj.kernelType, kernelParam);

                dim2 = numTrain; 
                numClasses = length(unique(trainTargets));
                meanClasses = zeros(numClasses,dim2);

                Q=zeros(numClasses-1, numClasses-1);
                c=zeros(numClasses-1,1);
                A=ones(numClasses-1,numClasses-1);
                A=-A;
                b=zeros(numClasses-1,1);
                E=ones(1,numClasses-1);

                aux=zeros(1,dim2);
                N=hist(trainTargets,1:numClasses);

                H = sparse(dim2,dim2); 

                % Calculate the mean of the classes and the H matrix
                for currentClass = 1:numClasses,
                  meanClasses(currentClass,:) = mean(kernelMatrix(:,( trainTargets == currentClass )),2);
                  H = H + kernelMatrix(:,( trainTargets == currentClass ))*(eye(N(1,currentClass),N(1,currentClass))-ones(N(1,currentClass),N(1,currentClass))/sum( trainTargets == currentClass ))*kernelMatrix(:,( trainTargets == currentClass ))';
                end

                % Avoid ill-posed matrixes
                H = H +  u*eye(dim2,dim2);
                H_inv = inv(H);
                % Calculate the Q matrix for the optimization problem
                for i = 1:numClasses-1,
                    for j = i:numClasses-1,
                        Q(i,j) = (meanClasses(i+1,:)-meanClasses(i,:))*H_inv*(meanClasses(j+1,:)-meanClasses(j,:))';
                        % Force the matrix to be symmetric
                        Q(j,i)=Q(i,j);
                    end
                end

             vlb = zeros(numClasses-1,1);    % Set the bounds: alphas and betas >= 0
             vub = Inf*ones(numClasses-1,1); %                 alphas and betas <= Inf
             x0 = zeros(numClasses-1,1);     % The starting point is [0 0 0 0]

             [ms,me,t,m] = regexp( version,'R(\d+)\w*');

             if strcmp(m,'R2009a') || strcmp(m,'R2008a')
                 options = optimset('Algorithm','interior-point','LargeScale','off','Display','off');
             else
                 options = optimset('Algorithm','interior-point-convex','LargeScale','off','Display','off');
             end
             
             % Choice the optimization method
                switch upper(obj.optimizationMethod)
                    case 'QUADPROG'
                        [alpha, fval, how] = quadprog(Q,c,A,b,E,d,vlb,vub,x0,options);
                    case 'CVX'
%                         rmpath ../cvx/sets
%                         rmpath ../cvx/keywords
%                         addpath ../cvx
%                         addpath ../cvx/structures
%                         addpath ../cvx/lib
%                         addpath ../cvx/functions
%                         addpath ../cvx/commands
%                         addpath ../cvx/builtins

                        cvx_begin
                        cvx_quiet(true)
                        variables alpha(numClasses-1)
                        minimize( 0.5*alpha'*Q*alpha );
                        subject to
                            (ones(1,numClasses-1)*alpha) == d;
                            alpha >= 0;
                        cvx_end
                    case 'QP'
                        alpha = qp(Q, c, E, d, vlb, vub,x0,1,0);
                    otherwise
                        error('Invalid value for optimizer\n');
                end

                % Calculate Sum_{k=1}^{K-1}(alpha_{k}*(M_{k+1}-M_{k}))
                for currentClass = 1:numClasses-1,
                    aux = aux + alpha(currentClass)*(meanClasses(currentClass+1,:)-meanClasses(currentClass,:));
                end

                % W = 0.5 * H^{-1} * aux
                projection = 0.5*H_inv*aux';
                thresholds = zeros(numClasses-1, 1);

                % Calculate the threshold for each couple of classes
                for currentClass = 1:numClasses-1,
                    thresholds(currentClass) = (projection'*(meanClasses(currentClass+1,:)+meanClasses(currentClass,:))')/2;
                end
                
                
                model.projection = projection;
                model.thresholds = thresholds;
                model.parameters = parameters;
                model.kernelType = obj.kernelType;
                model.algorithm = 'KDLOR';
               
                
%                 projected = projection'*kernelMatrix; 
%             
%                 projected2 = repmat(projected, numClasses-1,1);
%                 projected2 = projected2 - thresholds*ones(1,size(projected2,2));
% 
%                 % Asignation of the class
%                 % f(x) = max {Wx-bk<0} or Wx - b_(K-1) > 0
%                 wx=projected2;
% 
%                 % The procedure for that is the following:
%                 % We assign the values > 0 to NaN
%                 wx(wx(:,:)>0)=NaN;
% 
%                 % Then, we choose the bigger one.
%                 [maximum,testTargets]=max(wx,[],1);
% 
%                 % If a max is equal to NaN is because Wx-bk for all k is >0, so this
%                 % pattern below to the last class.
%                 testTargets(isnan(maximum(:,:)))=numClasses;
%                 %thresholds
%                 %N
%                 for i=1:numClasses-1,
%                     punto1 = max(projected(testTargets==i));
%                     punto2 = min(projected(testTargets==(i+1)));
%                     
%                     thresholds(i) = (1-(N(i)/(N(i)+N(i+1))))*(punto2-punto1) + punto1;
%                 end
%                 %thresholds
%                 %pause
            
            
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
        
        function [projected, testTargets]= test(obj, testPatterns, trainPatterns, model)
            
                numClasses = size(model.thresholds,1)+1;

                kernelMatrix2 = computeKernelMatrix(trainPatterns, testPatterns,model.kernelType, model.parameters.k);
                projected = model.projection'*kernelMatrix2; 

                % We calculate the projected patterns - each thresholds, and then with
                % the following decision rule we can induce the class each pattern
                % belows.
                projected2 = repmat(projected, numClasses-1,1);
                projected2 = projected2 - model.thresholds*ones(1,size(projected2,2));

                % Asignation of the class
                % f(x) = max {Wx-bk<0} or Wx - b_(K-1) > 0
                wx=projected2;

                % The procedure for that is the following:
                % We assign the values > 0 to NaN
                wx(wx(:,:)>0)=NaN;

                % Then, we choose the bigger one.
                [maximum,testTargets]=max(wx,[],1);

                % If a max is equal to NaN is because Wx-bk for all k is >0, so this
                % pattern below to the last class.
                testTargets(isnan(maximum(:,:)))=numClasses;
                %projected
                projected = projected';
                testTargets = testTargets';


        end      
            
    end
    
end


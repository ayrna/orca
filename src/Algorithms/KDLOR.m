classdef KDLOR < Algorithm
    %KDLOR Kernel Discriminant Learning for Ordinal Regression (KDLOR) [1].
    %
    %   KDLOR methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
    %
    %   References:
    %     [1] B.-Y. Sun, J. Li, D. D. Wu, X.-M. Zhang, and W.-B. Li,
    %         Kernel discriminant learning for ordinal regression
    %         IEEE Transactions on Knowledge and Data Engineering, vol. 22,
    %         no. 6, pp. 906-910, 2010.
    %         https://doi.org/10.1109/TKDE.2009.170
    %     [2] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
    %         F. Fernández-Navarro and C. Hervás-Martínez
    %         Ordinal regression methods: survey and experimental study
    %         IEEE Transactions on Knowledge and Data Engineering, Vol. 28.
    %         Issue 1, 2016
    %         http://dx.doi.org/10.1109/TKDE.2009.170
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    
    properties
        optimizationMethod = 'quadprog';
        name_parameters = {'C','k','u'};
        parameters;
    end
    
    methods
        
        function obj = KDLOR(kernel, opt)
            %KDLOR constructs an object of the class SVR. Default kernel is
            %'rbf' and default optimization method is 'quadprog'
            %
            %   OBJ = KDLOR(KERNEL) builds KDLOR with KERNEL as kernel function
            %   OBJ = KDLOR(KERNEL, OPT) builds KDLOR with KERNEL as kernel
            %   function and OPT as optimization method.
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
        
        function obj = set.optimizationMethod(obj, value)
            %SET.OPTIMIZATIONMETHOD verifies if the value for the variable
            %optimizationMethod is correct. Returns value for the variable
            %|optimizationMethod|.
            if ~(strcmpi(value,'quadprog') || strcmpi(value,'qp') || strcmpi(value,'cvx'))
                error('Invalid value for optimizer');
            else
                obj.optimizationMethod = value;
            end
        end
        
        
        function obj = defaultParameters(obj)
            %DEFAULTPARAMETERS It assigns the parameters of the algorithm
            %to a default value.
            
            % cost
            obj.parameters.C = [0.1,1,10,100];
            % kernel width
            obj.parameters.k = 10.^(-3:1:3);
            % parameter for avoiding singular matrix problems
            obj.parameters.u = [0.01,0.001,0.0001,0.00001,0.000001];
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
            
            if strcmp(obj.kernelType, 'sigmoid')
                param.k = [parameters(2),parameters(3)];
                if numel(parameters)>3
                    param.u = parameters(4);
                else
                    param.u = 0.01;
                end
            else
                if numel(parameters)>2
                    param.u = parameters(3);
                else
                    param.u = 0.01;
                end
                
            end
            
            c1 = clock;
            [model]= obj.train( train.patterns', train.targets', param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            [mInf.projectedTrain, mInf.predictedTrain] = obj.test( train.patterns', train.patterns', model);
            [mInf.projectedTest, mInf.predictedTest] = obj.test( test.patterns', train.patterns', model);
            c2 = clock;
            % time information for testing
            mInf.testTime = etime(c2,c1);
            
            mInf.model = model;
            
            
        end
        
        % TODO: Fix to receibe data structure as unique parameter
        function [model]= train( obj,trainPatterns, trainTargets , parameters)
            %TRAIN trains the model for the KDLOR method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
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
            for currentClass = 1:numClasses
                meanClasses(currentClass,:) = mean(kernelMatrix(:,( trainTargets == currentClass )),2);
                H = H + kernelMatrix(:,( trainTargets == currentClass ))*(eye(N(1,currentClass),N(1,currentClass))-ones(N(1,currentClass),N(1,currentClass))/sum( trainTargets == currentClass ))*kernelMatrix(:,( trainTargets == currentClass ))';
            end
            
            % Avoid ill-posed matrixes
            H = H +  u*eye(dim2,dim2);
            H_inv = inv(H);
            % Calculate the Q matrix for the optimization problem
            for i = 1:numClasses-1
                for j = i:numClasses-1
                    Q(i,j) = (meanClasses(i+1,:)-meanClasses(i,:))*H_inv*(meanClasses(j+1,:)-meanClasses(j,:))';
                    % Force the matrix to be symmetric
                    Q(j,i)=Q(i,j);
                end
            end
            
            vlb = zeros(numClasses-1,1);    % Set the bounds: alphas and betas >= 0
            vub = Inf*ones(numClasses-1,1); %                 alphas and betas <= Inf
            x0 = zeros(numClasses-1,1);     % The starting point is [0 0 0 0]
            
            
            % Choice the optimization method
            switch upper(obj.optimizationMethod)
                case 'QUADPROG'
                    [ms,me,t,m] = regexp( version,'R(\d+)\w*');
                    
                    if exist ('OCTAVE_VERSION', 'builtin') > 0
                        options = optimset('Display','off');
                        pkg load optim;
                    elseif strcmp(m,'R2009a') || strcmp(m,'R2008a')
                        options = optimset('Algorithm','interior-point','LargeScale','off','Display','off');
                    else
                        options = optimset('Algorithm','interior-point-convex','LargeScale','off','Display','off');
                    end
                    [alpha, fval, how] = quadprog(Q,c,A,b,E,d,vlb,vub,x0,options);
                    if exist ('OCTAVE_VERSION', 'builtin') > 0
                        pkg unload optim;
                    end
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
                    if exist ('OCTAVE_VERSION', 'builtin') > 0
                        alpha = qp(x0, Q, c, E, d, vlb, vub);
                    else
                        alpha = qp(Q, c, E, d, vlb, vub,x0,1,0);
                    end
                otherwise
                    error('Invalid value for optimizer\n');
            end
            
            % Calculate Sum_{k=1}^{K-1}(alpha_{k}*(M_{k+1}-M_{k}))
            for currentClass = 1:numClasses-1
                aux = aux + alpha(currentClass)*(meanClasses(currentClass+1,:)-meanClasses(currentClass,:));
            end
            
            % W = 0.5 * H^{-1} * aux
            projection = 0.5*H_inv*aux';
            thresholds = zeros(numClasses-1, 1);
            
            % Calculate the threshold for each couple of classes
            for currentClass = 1:numClasses-1
                thresholds(currentClass) = (projection'*(meanClasses(currentClass+1,:)+meanClasses(currentClass,:))')/2;
            end
            
            
            model.projection = projection;
            model.thresholds = thresholds;
            model.parameters = parameters;
            model.kernelType = obj.kernelType;
            model.algorithm = 'KDLOR';
            
            
        end
        
        % TODO: Fix to receibe data structure as unique parameter
        function [projected, testTargets] = test(obj, testPatterns, trainPatterns, model)
            %TEST predict labels of TEST patterns labels using MODEL.
            
            numClasses = size(model.thresholds,1)+1;
            
            kernelMatrix2 = computeKernelMatrix(trainPatterns, testPatterns,model.kernelType, model.parameters.k);
            projected = model.projection'*kernelMatrix2;
            
            % We calculate the projected patterns minus each threshold, and then with
            % the following decision rule we can compute the class to which each pattern
            % belongs to.
            projected2 = repmat(projected, numClasses-1,1);
            projected2 = projected2 - model.thresholds*ones(1,size(projected2,2));
            
            % Asignation of the class
            % f(x) = max {Wx-bk<0} or Wx - b_(K-1) > 0
            wx=projected2;
            
            % The procedure for that is the following:
            % We assign the values > 0 to NaN
            wx(wx(:,:)>0)=NaN;
            
            % Then, we choose the biggest one.
            [maximum,testTargets]=max(wx,[],1);
            
            % If a max is equal to NaN is because Wx-bk for all k is >0, so this
            % pattern belong to the last class.
            testTargets(isnan(maximum(:,:)))=numClasses;
            
            projected = projected';
            testTargets = testTargets';
            
        end
        
    end
    
end


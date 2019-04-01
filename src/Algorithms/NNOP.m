classdef NNOP < Algorithm
    %NNOP Neural Network with Ordered Partitions (NNOP). This model
    % considers the OrderedPartitions coding scheme for the labels and a
    % rule for decisions based on the first node whose output is higher
    % than a predefined threshold (T=0.5, in our experiments). The
    % model has one hidden layer with hiddenN neurons and one outputlayer
    % with as many neurons as the number of classes minus one. The learning
    % is based on iRProp+ algorithm and the implementation provided by
    % Roberto Calandra in his toolbox Rprop Toolbox for {MATLAB}:
    % http://www.ias.informatik.tu-darmstadt.de/Research/RpropToolbox
    % The model is adjusted by minimizing mean squared error. A regularization
    % parameter "lambda" is included based on L2, and the number of
    % iterations is specified by the "iter" parameter.
    %   NNPOM methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it
    %                                   in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   NNPOM properties:
    %      epsilonInit                - Range for initializing the weights.
    %      parameters.hiddenN         - Number of hidden neurons of the
    %                                   model.
    %      parameters.iter            - Number of iterations for iRProp+
    %                                   algorithm.
    %      parameters.lambda          - Regularization parameter.
    %
    %   References:
    %     [1] J. Cheng, Z. Wang, and G. Pollastri, "A neural network
    %         approach to ordinal regression," in Proc. IEEE Int. Joint
    %         Conf. Neural Netw. (IEEE World Congr. Comput. Intell.), 2008,
    %         pp. 1279-1284.
    %     [2] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
    %         F. Fernández-Navarro and C. Hervás-Martínez
    %         Ordinal regression methods: survey and experimental study
    %         IEEE Transactions on Knowledge and Data Engineering, Vol. 28.
    %         Issue 1, 2016
    %         http://dx.doi.org/10.1109/TKDE.2015.2457911
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    
    properties
        description = 'Neural Network with Ordered Partitions';
        % Weights range
        epsilonInit = 0.5;
        parameters = struct('iter', 500,'hiddenN', 50,'lambda', 0.01);
    end
    
    methods
        
        function obj = NNOP(varargin)
            %NNOP constructs an object of the class NNOP and sets its default
            %   characteristics
            %   obj = NNOP('epsilonInit', 0.5) sets initialization of
            %   epsilon to 0.5
            obj.parseArgs(varargin);
        end
        
        function obj = set.epsilonInit(obj,e)
            if strcmp(class(obj.epsilonInit), class(e))
                obj.epsilonInit= e;
            else
                error('epsilonInit type is ''%s'' and ''%s'' was provided', class(obj.epsilonInit), class(e))
            end
        end
        
        function [projectedTrain, predictedTrain] = privfit( obj, train, parameters)
            %PRIVFIT trains the model for the NNOP method with TRAIN data and
            %vector of parameters PARAM. 
            
            % Aux variables
            X = train.patterns;
            y = train.targets;
            input_layer_size  = size(X,2);
            hidden_layer_size = parameters.hiddenN;
            num_labels = numel(unique(y));
            m = size(X,1);
            
            % Recode y to Y using ordered partitions
            Y = repmat(y,1,num_labels) <= repmat((1:num_labels),m,1);
            
            % Hidden layer weigths (with bias)
            initial_Theta1 = obj.randInitializeWeights(input_layer_size+1, hidden_layer_size);
            % Output layer weigths (without bias, the biases will be the
            %                       Thresholds)
            initial_Theta2 = obj.randInitializeWeights(hidden_layer_size+1, num_labels-1);
            
            % Pack parameters
            initial_nn_params = [initial_Theta1(:) ; initial_Theta2(:)];
            
            % Set regularization parameter
            lambda = parameters.lambda;
            
            % Create "short hand" for the cost function to be minimized
            costFunction = @(p) obj.nnOPCostFunction(p, ...
                input_layer_size, ...
                hidden_layer_size, ...
                num_labels, X, Y, lambda);
            
            % RProp options
            p.verbosity = 0;                    % Increase indent
            p.MaxIter   = parameters.iter;     	% Maximum number of iterations
            p.d_Obj     = -1;                   % Objective cost
            p.method    = 'IRprop+';            % Use IRprop- algorithm
            p.display   = 0;
            
            % Running RProp
            [nn_params,cost,exitflag,stats1] = rprop(costFunction,initial_nn_params,p);
            
            %             options = optimoptions('fminunc','Algorithm','quasi-newton','SpecifyObjectiveGradient',true,'Diagnostics','on','Display','iter-detailed','UseParallel',true,'MaxIter', 1000,'CheckGradients',true);
            %             [nn_params, cost, exitflag, output] = fminunc(costFunction, initial_nn_params, options);
            
            % Unpack the parameters
            [Theta1, Theta2] = obj.unpackParameters(nn_params,input_layer_size,hidden_layer_size,num_labels);
            model.Theta1=Theta1;
            model.Theta2=Theta2;
            model.num_labels=num_labels;
            model.m = m;
            model.parameters = parameters;
            obj.model = model;
            [projectedTrain, predictedTrain] = obj.predict(train.patterns);
        end
        
        function [projected, predicted]= predict(obj,test)
            %PREDICT predicts labels of TEST patterns labels. The object needs to be fitted to the data first.
            m = size(test,1);
            a1 = [ones(m, 1) test];
            z2 = [ones(m, 1) a1*obj.model.Theta1'];
            a2 =  1.0 ./ (1.0 + exp(-z2));
            projected=a2*obj.model.Theta2';
            projected=1.0 ./ (1.0 + exp(-projected));
            
            a3 = ([projected ones(m,1)] > 0.5).*repmat(1:obj.model.num_labels,m,1);
            a3(a3==0)=obj.model.num_labels+1;
            
            predicted = min(a3,[],2);
        end
        
    end
    
    methods(Access = private)
        
        function [Theta1, Theta2] = unpackParameters(obj,nn_params,input_layer_size,hidden_layer_size,num_labels)
            % UNPACKPARAMETERS obtains Theta1 and Theta2
            % back from the whole array nn_params
            nTheta1 = hidden_layer_size * (input_layer_size + 1);
            Theta1 = reshape(nn_params(1:nTheta1), ...
                hidden_layer_size, (input_layer_size + 1));
            Theta2 = reshape(nn_params((1+nTheta1):end), ...
                num_labels-1, (hidden_layer_size+1));
        end
        
        function W = randInitializeWeights(obj, L_in, L_out)
            %RANDINITIALIZEWEIGHTS randomly initializes the weights of a layer with L_in
            %incoming connections and L_out outgoing connections
            W = rand(L_out, L_in)*2*obj.epsilonInit - obj.epsilonInit;
        end
        
        function [J,grad] = nnOPCostFunction(obj, nn_params, ...
                input_layer_size, ...
                hidden_layer_size, ...
                num_labels, ...
                X, Y, lambda)
            %NNPOMCOSTFUNCTION implements the cost function and obtains the
            %corresponding derivatives.
            
            % Unroll all the parameters
            [Theta1, Theta2] = unpackParameters(obj,...
                nn_params,input_layer_size,hidden_layer_size,num_labels);
            
            
            % Setup some useful variables
            m = size(X, 1);
            
            % Neural Network model
            a1 = [ones(m, 1) X];
            z2 = a1*Theta1';
            a2 =  [ones(m, 1) (1.0 ./ (1.0 + exp(-z2)))];
            z3=a2*Theta2';
            h =  [1.0 ./ (1.0 + exp(-z3)) ones(m, 1)];
            
            % Final output
            out = h;
            
            % calculte penalty (regularización L2)
            p = sum(sum(Theta1(:, 2:end).^2, 2))+sum(sum(Theta2(:, 2:end).^2, 2));
            
            % MSE
            J = sum(sum((out-Y).^2, 2))/(2*m) + lambda*p/(2*m);
            % Cross entropy
            %J = sum(-log(out(Y==1)), 1)/m + lambda*p/(2*m);
            if nargout > 1
                % Cross entropy
                %out(out<0.00001)=0.00001;
                %errorDer = zeros(size(Y));
                %errorDer(Y~=0) = (-Y(Y~=0)./out(Y~=0));
                
                % MSE
                errorDer=(out-Y);
                
                % Calculate sigmas
                sigma3 = errorDer.*h.*(1-h);
                sigma3 = sigma3(:,1:(end-1));
                sigma2 = (sigma3*Theta2).*a2.*(1-a2);
                sigma2 = sigma2(:, 2:end);
                
                % Accumulate gradients
                delta_1 = (sigma2'*a1);
                delta_2 = (sigma3'*a2);
                
                % calculate regularized gradient
                p1 = (lambda/m)*[zeros(size(Theta1, 1), 1) Theta1(:, 2:end)];
                p2 = (lambda/m)*[zeros(size(Theta2, 1), 1) Theta2(:, 2:end)];
                Theta1_grad = delta_1./m + p1;
                Theta2_grad = delta_2./m + p2;
                
                % Unroll gradients
                grad = [Theta1_grad(:) ; Theta2_grad(:)];
            end
            
        end
    end
end


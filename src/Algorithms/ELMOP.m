classdef ELMOP < Algorithm
    %ELMOP Extreme Learning Machine for Ordinal Regression (ELMOP). This
    %class is an extended version of the source code provided by Guang-Bin
    %Huang (http://www.ntu.edu.sg/home/egbhuang/)
    %
    %   ELMOP methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   ELMOP properties:
    %      activationFunction         - Activation function, default
    %                                   sigmoid. Available options are 'sig,
    %                                   'sin', 'hardlim','tribas', 'radbas',
    %                                   'up','rbf', 'krbf', 'grbf'
    %                                   fitting the model and testing it in a dataset.
    %      parameters.hiddenN         - parameters.hiddenN is a vector of
    %                                   the number of hidden neural networks
    %                                   to validate.
    %
    %   References:
    %     [1] W.-Y. Deng, Q.-H. Zheng, S. Lian, L. Chen, and X. Wang,
    %         Ordinal extreme learning machine, Neurocomputing, vol. 74,
    %         no. 1-3, pp. 447-456, 2010.
    %         http://dx.doi.org/10.1016/j.neucom.2010.08.022
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
        description = 'Extreme Learning Machine for Ordinal Regression';
        activationFunction = 'sig';
        
        % Input Weights range
        wMin = -1;
        wMax = 1;
        
        parameters = struct('hiddenN', 50);
    end
    
    methods
        function obj = ELMOP(varargin)
            %ELMOP constructs an object of the class ELMOP and sets its default
            %   characteristics
            %   OBJ = ELMOP('activationFunction', ) builds ELMOP with
            %       activationFunction ('sig', 'rbf', 'krbf', 'grbf', 'up')
            obj.parseArgs(varargin);
        end
        
        function obj = set.activationFunction(obj,a)
            b = {'sig';'sigmoid';'up';'rbf';'krbf';'grbf'};
            if any(strcmp(a,b))
                obj.activationFunction = a;
            else
                error('activationFunction ''%s'' not allowed', a)
            end
        end
        
        function [projectedTrain, predictedTrain] = privfit( obj, train, parameters)
            %PRIVFIT trains the model for the ELMOP method with TRAIN data and
            %vector of parameters PARAM. 
            %TODO train.uniqueTargets = unique([test.targets ;train.targets]);
            train.uniqueTargets = unique(train.targets);
            train.nOfClasses = max(train.uniqueTargets);
            train.nOfPatterns = length(train.targets);
            train.dim = size(train.patterns,2);
            train = obj.labelToOrelm(train);
            
            if( strcmp(obj.activationFunction,'rbf') && parameters.hiddenN > train.nOfPatterns)
                %disp(['User''s number of hidden neurons ' num2str(parameters.hiddenN) ...
                %   ' was too high and has been adjusted to the number of training patterns']);
                obj.parameters.hiddenN = train.nOfPatterns;
            else
                obj.parameters.hiddenN = parameters.hiddenN;
            end
            
            P = train.patterns';
            T = train.targetsOrelm;
            T = T';
            
            %%%%%%%%%%% Calculate weights & biases
            
            %------Perform log(P) calculation once for UP
            % The calculation is done here for including it into the validation time
            if strcmp(obj.activationFunction, 'up')
                P = log(P);
            end
            
            %%%%%%%%%%% Random generate input weights InputWeight (w_i) and biases BiasofHiddenNeurons (b_i) of hidden neurons
            
            switch lower(obj.activationFunction)
                case {'sig','sigmoid'}
                    InputWeight=rand(obj.parameters.hiddenN,train.dim)*2-1;
                    
                    BiasofHiddenNeurons=rand(obj.parameters.hiddenN,1);
                    tempH=InputWeight*P;
                    ind=ones(1,train.nOfPatterns);
                    BiasMatrix=BiasofHiddenNeurons(:,ind);              %   Extend the bias matrix BiasofHiddenNeurons to match the demention of H
                    tempH=tempH+BiasMatrix;
                case {'up'}
                    InputWeight = obj.wMin + (obj.wMax-obj.wMin).*rand(obj.parameters.hiddenN,train.dim);
                case {'rbf'}
                    P = P';
                    if (train.nOfPatterns>2000)
                        TY=pdist(P(randperm(2000),:));
                    else
                        TY=pdist(P);
                    end
                    a10=prctile(TY,20);
                    a90=prctile(TY,60);
                    MP=randperm(train.nOfPatterns);
                    W1=P(MP(1:obj.parameters.hiddenN),:);
                    W10=rand(1,obj.parameters.hiddenN)*(a90-a10)+a10;
                    W10 = W10';
                    InputWeight = [W1 W10];
                    clear TY;
                case {'krbf'}
                    P = P';
                    opts = statset('MaxIter',200);
                    [IDX, C, SUMD, D] = kmeans(P,obj.parameters.hiddenN,'Options',opts);
                    MC = squareform(pdist(C));
                    MCS = sort(MC);
                    MCS(1,:)=[];
                    radii = sqrt(MCS(1,:).*MCS(2,:));
                    InputWeight = [C radii'];
                    
                    W1 = C;
                    W10 = radii;
                case {'grbf'}
                    MP = randperm(train.nOfPatterns);
                    InputWeight = P(:,MP(1:obj.parameters.hiddenN))';
            end
            
            
            %%%%%%%%%%% Calculate hidden neuron output matrix H
            switch lower(obj.activationFunction)
                case {'sig','sigmoid'}
                    %%%%%%%% Sigmoid
                    H = 1 ./ (1 + exp(-tempH));
                case {'sin','sine'}
                    %%%%%%%% Sine
                    H = sin(tempH);
                case {'hardlim'}
                    %%%%%%%% Hard Limit
                    H = double(hardlim(tempH));
                case {'tribas'}
                    %%%%%%%% Triangular basis function
                    H = tribas(tempH);
                case {'radbas'}
                    %%%%%%%% Radial basis function
                    H = radbas(tempH);
                    %%%%%%%% More activation functions can be added here
                case {'up'}
                    %PU_j(X) = productorio_{i=0}^n (x_i^{w_{ji}})
                    %P = log(P);
                    
                    H = zeros(obj.parameters.hiddenN,train.nOfPatterns);
                    for i = 1 : train.nOfPatterns
                        for j = 1 : obj.parameters.hiddenN
                            temp = zeros(train.dim,1);
                            for n = 1: train.dim
                                temp(n) = InputWeight(j,n)*P(n,i);
                            end
                            H(j,i) =  sum(temp);
                        end
                    end
                    clear temp;
                case {'rbf','krbf'}
                    H = zeros(train.nOfPatterns, obj.parameters.hiddenN);
                    for j=1:obj.parameters.hiddenN
                        H(:,j)=gaussian_func(P,W1(j,:),W10(j,:));
                        %KM.valueinit(:,j)=gaussian_func(x,W1(j,:),W10(1,j));
                    end
                    H = H';
                case {'grbf'}
                    % Compute Pairwise Euclidean distance
                    EuclideanDistanceArray = pdist(InputWeight);
                    EuclideanDistanceMatrix = squareform(EuclideanDistanceArray);
                    EuclideanDistanceSorted = sort(EuclideanDistanceMatrix);
                    % Larges distances and nearest distances
                    dF = EuclideanDistanceSorted(2,:);
                    %dN = (dF*0.05)/0.95;
                    dN = ones(size(dF)) * sqrt((0.001^2) * train.dim);
                    % Determine Tau and radii values
                    %taus = 4.0674 ./ (log(dF./dN));
                    taus = 5.6973 ./ (log(dF./dN));
                    
                    taus = ones(1,obj.parameters.hiddenN)*2;
                    %radii = dF ./(-log(0.95)).^(1 ./taus);
                    radii = dF ./(-log(0.99)).^(1 ./taus);
                    % Obtain denominator
                    denominator = radii .^taus;
                    denominator_extended = repmat(denominator,train.nOfPatterns,1)';
                    % Obtain Numerator
                    EuclideanDistance = pdistalt(InputWeight,P','euclidean');
                    taus_extended = repmat(taus,train.nOfPatterns,1)';
                    numerator = EuclideanDistance.^taus_extended;
                    % Calculate Hidden Node outputs
                    H = exp(-(numerator./denominator_extended));
            end
            %COMENTADO clear P;
            
            clear tempH;%   Release the temnormMinrary array for calculation of hidden neuron output matrix H
            
            
            %%%%%%%%%%% Calculate output weights OutputWeight (beta_i)
            
            OutputWeight=pinv(H') * T';                        % slower implementation
            % OutputWeight=inv(H * H') * H * T';                         % faster implementation
            
            
            model.activationFunction = obj.activationFunction;
            model.hiddenN = obj.parameters.hiddenN;
            model.InputWeight = InputWeight;
            
            if strcmpi(obj.activationFunction, 'sig')
                model.BiasofHiddenNeurons = BiasofHiddenNeurons;
            end
            
            if strcmp(obj.activationFunction, 'rbf') || strcmp(obj.activationFunction, 'krbf')
                model.W1 = W1;
                model.W10 = W10;
            end
            
            model.OutputWeight = OutputWeight;
            model.parameters = parameters;
            model.labelSet = unique(train.targetsOrelm,'rows');
            model.nOfClasses = train.nOfClasses;
            model.dim = train.dim;
            obj.model = model;
            [projectedTrain, predictedTrain] = obj.predict( train.patterns);
            
        end
        
        function [TY, TestPredictedY]= privpredict(obj, test)
            %PREDICT predicts labels of TEST patterns labels. The object needs to be fitted to the data first.
            nOfPatterns = size(test,1);
            
            TV.P = test';
            
            %------Perform log(P) calculation once for UP
            % The calculation is done here for including it into the validation time
            if strcmp(obj.model.activationFunction, 'up')
                TV.P = log(TV.P);
            end
            
            %%%%%%%%%%% Calculate the output of testing input
            
            if strcmpi(obj.model.activationFunction, 'sig')
                tempH_test=obj.model.InputWeight*TV.P;
                %Movido abajo
                %clear TV.P;             %   Release input of testing data
                ind=ones(1,nOfPatterns);
                
                BiasMatrix=obj.model.BiasofHiddenNeurons(:,ind);              %   Extend the bias matrix BiasofHiddenNeurons to match the demention of H
                tempH_test=tempH_test + BiasMatrix;
            end
            
            switch lower(obj.model.activationFunction)
                case {'sig','sigmoid'}
                    %%%%%%%% Sigmoid
                    H_test = 1 ./ (1 + exp(-tempH_test));
                case {'sin','sine'}
                    %%%%%%%% Sine
                    H_test = sin(tempH_test);
                case {'hardlim'}
                    %%%%%%%% Hard Limit
                    H_test = hardlim(tempH_test);
                case {'tribas'}
                    %%%%%%%% Triangular basis function
                    H_test = tribas(tempH_test);
                case {'radbas'}
                    %%%%%%%% Radial basis function
                    H_test = radbas(tempH_test);
                    %%%%%%%% More activation functions can be added here
                case {'up'}
                    
                    %TV.P = log(TV.P);
                    H_test = zeros(obj.model.hiddenN, nOfPatterns);
                    
                    for i = 1 : nOfPatterns
                        for j = 1 : obj.model.hiddenN
                            temp = zeros(obj.model.dim,1);
                            for n = 1: obj.model.dim
                                %temp(n) = TV.P(n,i)^InputWeight(j,n);
                                temp(n) = obj.model.InputWeight(j,n)*TV.P(n,i);
                            end
                            %H_predict(j,i) =  prod(temp);
                            H_predict(j,i) =  sum(temp);
                        end
                    end
                    
                    clear temp;
                case {'rbf','krbf'}
                    H_test = zeros(nOfPatterns,obj.model.hiddenN);
                    TV.P = TV.P';
                    
                    for j=1:obj.model.hiddenN
                        H_predict(:,j)=gaussian_func(TV.P,obj.model.W1(j,:),obj.model.W10(j,:));
                    end
                    H_test = H_test';
                    
                case {'grbf'}
                    % Repmat denominator to Testing data
                    denominator_extended = repmat(denominator,nOfPatterns,1)';
                    % Recalculate Euclidean Distance
                    EuclideanDistanceTest = pdistalt(InputWeight,TV.P','euclidean');
                    taus_extended = repmat(taus,nOfPatterns,1)';
                    numerator = EuclideanDistanceTest.^taus_extended;
                    % Calculate Hidden Node outputs
                    H_test = exp(-(numerator./denominator_extended));
            end
            
            clear TV.P;             %   Release input of testing data
            
            TY=(H_test' * obj.model.OutputWeight);                       %   TY: the actual output of the testing data
            clear H_test;
            
            TestPredictedY = obj.orelmToLabel(TY, obj.model.labelSet);
        end
        
    end
    
    methods(Access = private)
        function [predL,eLosses] = orelmToLabel(obj,predictions,labelSet)
            %ORELMTOLABEL computes the exponential loss and the final prediction
            %   [PREDL,ELOSSES] = ORELMTOLABEL(OBJ,PREDICTIONS,LABELSSET)
            %   return final label prediction PREDL and exponential loss
            %   ELOSSES of PREDICTIONS matrix. PREDICTIONS is the set of
            %   output for each output neuron. LABELSSET is the set of
            %   labels in the classification problem.
            
            % Minimal Exponential Loss
            eLosses=zeros(size(predictions));
            
            for i=1:size(predictions,2)
                eLosses(:,i) = sum(exp(-predictions.*repmat(labelSet(i,:),size(predictions,1),1)),2);
            end
            
            [minVal,predL] = min(eLosses,[],2);
        end
        
        %TODO: This method should work only with a dataset partition.
        function [data] = labelToOrelm(obj,data)
            %LABELTOORELM Compute the labels to the ordinal format. It
            %returns the two pattern structures (train and test)
            data.targetsOrelm = ones(data.nOfPatterns,data.nOfClasses);
            for i=1:data.nOfClasses
                data.targetsOrelm(data.targets<data.uniqueTargets(i),i) = -1;
            end
        end
    end
end


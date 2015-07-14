%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for the ELMOP method.
% 
% The code has been tested with Ubuntu 12.04 x86_64, Debian Wheezy 8, Matlab R2009a and Matlab 2011
% 
% If you use this code, please cite the associated paper
% Code updates and citing information:
% http://www.uco.es/grupos/ayrna/orreview
% https://github.com/ayrna/orca
% 
% AYRNA Research group's website:
% http://www.uco.es/ayrna 
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
% Licence available at: http://www.gnu.org/licenses/gpl-3.0.html
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef ELMOP < Algorithm
    %ELM Extreme Learning Machine for Ordinal Regression
    %   This class derives from the Algorithm Class and implements the
    %   ELMOP method
    
    properties
        
        activationFunction = 'sig';

        % Input Weights range 
        wMin = -1;
        wMax = 1;
       
        parameters

        name_parameters = {'hiddenN'}
    end

    
    methods
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: ELMOP (Public Constructor)
        % Description: It constructs an object of the class
        %               ELM and sets its characteristics.
        % Type: Void
        % Arguments: 
        %           activationFunction
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = ELMOP(activationFunction)
            obj.name = 'Extreme Learning Machine for Ordinal Regression';
            if(nargin ~= 0)
                obj.activationFunction = activationFunction;
            else
                obj.activationFunction = 'sig';
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
            obj.parameters.hiddenN = {5,10,20,30,40,50,60,70,80,90,100};
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runAlgorithm (Public)
        % Description: This function runs the corresponding
        %               algorithm, fitting the model and 
        %               testing it in a dataset.
        % Type: It returns the model (Struct) 
        % Arguments: 
        %           Train --> Training data for fitting the model
        %           Test --> Test data for validation
        %           parameters --> vector with the parameter information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [model_information] = runAlgorithm(obj,train, test, parameters)
            
                train.uniqueTargets = unique([test.targets ;train.targets]);
                test.uniqueTargets = train.uniqueTargets;
                train.nOfClasses = max(train.uniqueTargets);
                test.nOfClasses = train.nOfClasses;                
                train.nOfPatterns = length(train.targets);
                test.nOfPatterns = length(test.targets);
                
                train.dim = size(train.patterns,2);
                test.dim = train.dim;
                
                param.hiddenN = parameters(1);
                
                [train, test] = obj.labelToOrelm(train,test);
                train.uniqueTargetsOrelm = unique([test.targetsOrelm ;train.targetsOrelm],'rows');
                test.uniqueTargetsOrelm = train.uniqueTargetsOrelm;
                
                
                c1 = clock;
                model = obj.train( train, param);
                c2 = clock;
                % time information for testing
                model_information.trainTime = etime(c2,c1);
                
                c1 = clock;
                [model_information.projectedTrain, model_information.predictedTrain] = obj.test( train,model );
                [model_information.projectedTest, model_information.predictedTest] = obj.test( test,model );
                c2 = clock;
                % time information for testing
                model_information.testTime = etime(c2,c1);

                model_information.model = model;

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the ELMOP algorithm.
        % Type: model structure
        % Arguments: 
        %           train --> Train structure
        %           parameters --> parameters for the model
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function model = train( obj,train, parameters)
            
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

            clear tempH;                                        %   Release the temnormMinrary array for calculation of hidden neuron output matrix H


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
            model.algorithm = 'ELMOP';
            model.parameters = parameters;

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test the model in
        %               a set of test patterns.
        % Type: Two arrays (projected patterns and predicted labels)
        % Arguments: 
        %           test --> Test structure
        %           model --> model structure
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [TY, TestPredictedY]= test(obj, test, model)

            
            TV.P = test.patterns';

            %------Perform log(P) calculation once for UP
            % The calculation is done here for including it into the validation time
            if strcmp(model.activationFunction, 'up')
                TV.P = log(TV.P);
            end

            %%%%%%%%%%% Calculate the output of testing input

            if strcmpi(model.activationFunction, 'sig')
                tempH_test=model.InputWeight*TV.P;
                %Movido abajo 
                %clear TV.P;             %   Release input of testing data             
                ind=ones(1,test.nOfPatterns);

                BiasMatrix=model.BiasofHiddenNeurons(:,ind);              %   Extend the bias matrix BiasofHiddenNeurons to match the demention of H
                tempH_test=tempH_test + BiasMatrix;
            end

            switch lower(model.activationFunction)
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
                    H_test = zeros(model.hiddenN, test.nOfPatterns);

                    for i = 1 : test.nOfPatterns
                        for j = 1 : model.hiddenN
                            temp = zeros(test.dim,1);
                            for n = 1: test.dim
                                %temp(n) = TV.P(n,i)^InputWeight(j,n);
                                temp(n) = model.InputWeight(j,n)*TV.P(n,i);
                            end
                            %H_test(j,i) =  prod(temp);
                            H_test(j,i) =  sum(temp);
                        end
                    end

                    clear temp;
                case {'rbf','krbf'}
                    H_test = zeros(test.nOfPatterns,model.hiddenN);
                    TV.P = TV.P';

                    for j=1:model.hiddenN
                        H_test(:,j)=gaussian_func(TV.P,model.W1(j,:),model.W10(j,:));
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


            TY=(H_test' * model.OutputWeight)';                       %   TY: the actual output of the testing data
            
            clear H_test;

            TestPredictedY = obj.orelmToLabel(TY', test.uniqueTargetsOrelm);
                    
            
            TestPredictedY = TestPredictedY';

        end

    end
    
    methods(Access = private)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: orelmToLabel (Private)
        % Description: Compute the exponential loss and the final prediction
        % Type: It returns the final prediction and the losses
        % Arguments: 
        %           predictions--> Array of predictions
        %           uniqueNewTargets--> Array of unique labels
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [finalOutput,expLosses] = orelmToLabel(obj,predictions,uniqueNewTargets)
            
            
            % Minimal Exponential Loss
            expLosses=zeros(size(predictions));
            
            for i=1:size(predictions,2),
                expLosses(:,i) = sum(exp(-predictions.*repmat(uniqueNewTargets(i,:),size(predictions,1),1)),2);
            end
            
            [minVal,finalOutput] = min(expLosses,[],2);
            finalOutput = finalOutput';
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: labelToOrelm (Private)
        % Description: Compute the labels to the ordinal format
        % Type: It returns the two pattern structures (train and test)
        % Arguments: 
        %           trainSet--> train structure
        %           testSet--> test structure
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	function [trainSet, testSet] = labelToOrelm(obj,trainSet,testSet)

            trainSet.targetsOrelm = ones(trainSet.nOfPatterns,trainSet.nOfClasses);
            testSet.targetsOrelm = ones(testSet.nOfPatterns,trainSet.nOfClasses);
            
            for i=1:trainSet.nOfClasses,
                trainSet.targetsOrelm(trainSet.targets<trainSet.uniqueTargets(i),i) = -1;
                testSet.targetsOrelm(testSet.targets<trainSet.uniqueTargets(i),i) = -1;
            end
           
        end
        
        
    end
    
end


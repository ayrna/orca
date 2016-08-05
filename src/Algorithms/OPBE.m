%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) María Pérez Ortiz (i82perom at uco dot es)
%
% This file implements the code for the Ordinal Projection Based Ensemble (OPBE) method.
% 
% The code has been tested with Ubuntu 12.04 x86_64, Debian Wheezy 8, Matlab R2009a and Matlab 2011
% 
% If you use this code, please cite the associated paper
% Code updates and citing information:
% http://www.uco.es/grupos/ayrna/elor2013
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

classdef OPBE < Algorithm
    % Ordinal Projection Based Ensemble (OPBE)
    %   This class derives from the Algorithm Class and implements the
    %   OPBE method with the best configuration found (product combiner, 
    %   SVM base methodology, logit function and equal distribution of
    %   probabilities).
    % Further details in: * María Pérez-Ortiz, Pedro Antonio Gutiérrez 
    %                          and César Hervás-Martínez (2013), 
    %                       "Ordinal regression methods: survey and
    %                       experimental study",  
    %                       IEEE Transactions on Cybernetics. Vol. 44 (5) 
    % Dependencies: this class uses
    % - svorim implementation: http://www.gatsby.ucl.ac.uk/~chuwei/svor.htm
    
    properties
        
        parameters

        name_parameters = {'C', 'k'}
    end
    
    methods
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: OPBE (Public Constructor)
        % Description: It constructs an object of the class
        %               OPBE and sets its characteristics.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = GOE()
            obj.name = 'Product Ensemble Discriminant Analysis';


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
        %               algorithm, fitting the model and 
        %               testing it in a dataset.
        % Type: It returns the model (Struct) 
        % Arguments: 
        %           train --> Training data for fitting the model
        %           test --> Test data for validation
        %           parameters --> vector with the parameter information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [model_information] = runAlgorithm(obj,train, test, parameters)
                 
                 param.C = parameters(1);
                 param.k = parameters(2);
                
                 c1 = clock;
                 [model,model_information.projectedTrain,model_information.predictedTrain] = obj.train(train, test, parameters);
                 c2 = clock;
                 model_information.trainTime = etime(c2,c1);
                
                 c1 = clock;
                 [model_information.projectedTest, model_information.predictedTest] = obj.test( test, train, model);            
                 c2 = clock;
                
                 model_information.testTime = etime(c2,c1);
                 model_information.model.parameters = param;
                 model_information.model.algorithm = 'GOE';
                 model_information.model.ensembleModels = model;

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the OPBE algorithm.
        % Type: It returns the model, the projected test patterns,
        %	the projected train patterns and the time information.
        % Arguments: 
        %           train --> Train struct
        %           test --> Test struct
        %           parameters--> struct with the parameter information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

        
        function [models, projected, trainTargets] = train(obj, train, test, parameters)
            
                  classes = unique(train.targets);
                  nOfClasses = numel(classes);
                  n = zeros(1,nOfClasses);
                  for i=1:nOfClasses,
                     n(i) = sum(train.targets == i);
                  end
                  baseAlgorithm = SVORIM;    
                  
                  % Sort patterns
                  orderedPatterns = train.patterns(train.targets==1,:);
                  orderedTargets = train.targets(train.targets == 1);
                  for i = 2:nOfClasses,
                      orderedPatterns = [orderedPatterns ; train.patterns(train.targets==i,:)];
                      orderedTargets = [orderedTargets; train.targets(train.targets == i)];
                  end
                  
                  train.patterns = orderedPatterns;
                  train.targets = orderedTargets;
                  classBelongingProbTrain = ones(nOfClasses, size(train.patterns,1));
                  weights = zeros(nOfClasses,1);

                  for i = 1:nOfClasses,
                       nLowerRankingClasses = sum(classes<i);
                       nHigherRankingClasses = sum(classes>i);

                       nPreviousClasses = numel(train.targets(train.targets < i));
                       nFollowingClasses = numel(train.targets(train.targets > i));

                       % Assign labels depending on the decomposition
                       if nPreviousClasses == 0, 
                            currentTargets = [train.targets(train.targets==1); ones(size(train.targets(train.targets>1)))*2];
                       elseif nFollowingClasses ==0,
                            currentTargets = [ones(size(train.targets(train.targets<i)));  ones(size(train.targets(train.targets==i)))*2];
                       else
                            currentTargets = [ones(size(train.targets(train.targets<i))); ones(size(train.targets(train.targets==i)))*2; ones(size(train.targets(train.targets>i)))*3];
                       end


                        auxtrain.patterns = train.patterns;
                        auxtrain.targets = currentTargets;

                        % Train each label decomposition 
                       [models(i)] = baseAlgorithm.runAlgorithm(auxtrain, test, parameters); 

                       % Estimate probabilities
                       probTrain = obj.calculateProbabilities(models(i).projectedTrain, models(i).model.thresholds');

                       % Compute weights and fused probabilities
                       for j = 1: nOfClasses,
                            if nHigherRankingClasses~= 0 && nLowerRankingClasses ~=0,
                                if(j<i)
                                    classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .* (probTrain(1,:)/nLowerRankingClasses);
                                    weights(j) = weights(j) + 1/nLowerRankingClasses;
                                elseif (j>i)
                                    classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .* (probTrain(3,:)/nHigherRankingClasses);
                                    weights(j) = weights(j) + 1/nHigherRankingClasses;
                                else
                                    classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .* probTrain(2,:);
                                    weights(j) = weights(j) + 1;
                                end
                            elseif i==j,
                                if nLowerRankingClasses == 0,
                                    classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .*  probTrain(1,:);
                                    weights(j) = weights(j) + 1;
                                else
                                    classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .* probTrain(2,:);
                                    weights(j) = weights(j) + 1;
                                end
                            else
                                if nLowerRankingClasses == 0,
                                    classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .* (probTrain(2,:)/nHigherRankingClasses);
                                    weights(j) = weights(j) + 1/nHigherRankingClasses;
                                else
                                    classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .* (probTrain(1,:)/nLowerRankingClasses);
                                    weights(j) = weights(j) + 1/nLowerRankingClasses;
                                end
                            end

                          end
                 end

                 % Join weights and probabilities into a final
                 % decision label
                 classBelongingProbTrain = classBelongingProbTrain ./ (weights*ones(1,size(classBelongingProbTrain,2)));
                 % There is not a single projection, so projected vector
                 % should not be used (it is however needed in the framework)
                 
                 % Compute final prediction
                 [projected, trainTargets] = max(classBelongingProbTrain);
                 trainTargets = trainTargets';
                    
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test a model given in
        %               a set of test patterns.
        % Outputs: Array of projected and predicted patterns
        % Arguments: 
        %           test --> Test struct
        %           train --> Train struct
        %           models --> struct with the different models
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [projected, testTargets] = test(obj, test, train, models)
                 
                 classes = unique(train.targets);
                 nOfClasses = numel(classes); 
                 weights = zeros(nOfClasses,1);
                 classBelongingProbTest = ones(nOfClasses, size(test.patterns,1));

                 for i = 1:nOfClasses,
                     nLowerRankingClasses = sum(classes<i);
                     nHigherRankingClasses = sum(classes>i);
                     
                     % Estimate probabilities
                     probTest = obj.calculateProbabilities(models(i).projectedTest, models(i).model.thresholds');

                     % Compute weights and fused probabilities

                     for j = 1: nOfClasses,
                        if nHigherRankingClasses~= 0 && nLowerRankingClasses ~=0,
                            if(j<i)
                                classBelongingProbTest(j,:) = classBelongingProbTest(j,:) .* (probTest(1,:)/nLowerRankingClasses);
                                weights(j) = weights(j) + 1/nLowerRankingClasses;
                            elseif (j>i)
                                classBelongingProbTest(j,:) = classBelongingProbTest(j,:) .* (probTest(3,:)/nHigherRankingClasses);
                                weights(j) = weights(j) + 1/nHigherRankingClasses;
                            else
                                classBelongingProbTest(j,:) = classBelongingProbTest(j,:) .* probTest(2,:);
                                weights(j) = weights(j) + 1;
                            end
                        elseif i==j,
                            if nLowerRankingClasses == 0,
                                classBelongingProbTest(j,:) = classBelongingProbTest(j,:) .*  probTest(1,:);
                                weights(j) = weights(j) + 1;
                            else
                                classBelongingProbTest(j,:) = classBelongingProbTest(j,:) .* probTest(2,:);
                                weights(j) = weights(j) + 1;
                            end
                        else
                            if nLowerRankingClasses == 0,
                                classBelongingProbTest(j,:) = classBelongingProbTest(j,:) .* (probTest(2,:)/nHigherRankingClasses);
                                weights(j) = weights(j) + 1/nHigherRankingClasses;
                            else
                                classBelongingProbTest(j,:) = classBelongingProbTest(j,:) .* (probTest(1,:)/nLowerRankingClasses);
                                weights(j) = weights(j) + 1/nLowerRankingClasses;
                            end
                        end
                           
                     end
                 end
                    
                 % Join weights and probabilities into a final
                 % decision label
                 classBelongingProbTest = classBelongingProbTest ./ (weights*ones(1,size(classBelongingProbTest,2)));
                 % There is not a single projection, so projected vector
                 % should not be used (it is however needed in the framework)
                 
                 % Compute final prediction
                 [projected, testTargets] = max(classBelongingProbTest);
                 testTargets = testTargets';


        end    
                        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: cummulativeProb (Public)
        % Description: This function computes the cummulative
        %               probabilities for a set of projected
        %               patterns and thresholds
        % Outputs: Cummulative probabilities
        % Arguments: 
        %           x --> projected patterns
        %           beta --> set of thresholds
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [y] = cummulativeProb(obj, x, beta)
                    y =  1 ./ (1+exp((x-beta))); %Logit
                %    y =  1-exp(-exp(beta-x)); %log log complementario
                %    y = exp(-exp(x-beta)); %log log negativo
                %    y = normcdf(beta-x); %probit
                %    y = atan(beta-x)/pi + 0.5; % cauchit
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: calculateProbabilities (Public)
        % Description: This function computes the
        %               probabilities for a set of projected
        %               patterns and thresholds
        % Outputs: Probabilities
        % Arguments: 
        %           projected --> projected patterns
        %           thresholds --> set of thresholds
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
         function [g] = calculateProbabilities(obj, projected, thresholds)
            
            % Numerical fix
            nOfClasses = numel(thresholds)+1;
            if (numel(thresholds)==2)
                deseada=4.0;
                actual=abs(thresholds(2) - thresholds(1));
                if actual<4,
                    projected = projected*(deseada/actual);
                    thresholds = thresholds*(deseada/actual);
                end
            end

            f = zeros(nOfClasses, numel(projected));
            g = zeros(nOfClasses, numel(projected));
            

            for i=1:(nOfClasses-1)
                    f(i,:) = obj.cummulativeProb(projected',thresholds(i));
            end
            f(nOfClasses,:) = ones(1, size(projected',2));
              
            g(1,:) = f(1,:);
            for i=2:nOfClasses
                    g(i,:)=f(i,:)-f(i-1,:);
            end


         end      
            
    end
    
end


classdef OPBE < Algorithm
    %OPBE Ordinal Projection Based Ensemble (OPBE)[1]. This class derives
    %from the Algorithm Class and implements the OPBE method with the best
    %configuration found (product combiner, SVM base methodology, logit
    %function and equal distribution of probabilities). This class uses
    % SVORIM implementation: http://www.gatsby.ucl.ac.uk/~chuwei/svor.htm
    %
    %   OPBE methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
    %
    %   References:
    %     [1] María Pérez-Ortiz, Pedro Antonio Gutiérrez and César
    %     Hervás-Martínez, Projection based ensemble learning for ordinal
    %     regression, IEEE Transactions on Cybernetics. Vol. 44 (5), 2014
    %     https://doi.org/10.1109/TCYB.2013.2266336
    
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: María Pérez Ortiz
    %   Citation: If you use this code, please cite the associated papers
    %      - http://www.uco.es/grupos/ayrna/elor2013
    %      - http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        parameters;
        name_parameters;
        base_algorithm;
    end
    
    methods
        
        function obj = OPBE()
            %OPBE constructs an object of the class SVR and sets its default
            obj.name = 'Ordinal Projection Based Ensemble';
            obj.base_algorithm = SVORIM;
            obj.name_parameters = obj.base_algorithm.name_parameters;
        end
        
        function obj = defaultParameters(obj)
            %DEFAULTPARAMETERS It assigns the parameters of the algorithm
            %   to a default value.
            % cost
            obj.base_algorithm.defaultParameters();
        end
        
        function [mInf] = runAlgorithm(obj,train, test, parameters)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter
            %   values for the method. Test the generalization performance
            %   with TRAIN and TEST data and returns predictions and model
            %   in mInf structure.
            nParam = numel(obj.name_parameters);
            parameters = reshape(parameters,[1,nParam]);
            param = cell2struct(num2cell(parameters(1:nParam)),obj.name_parameters,2);
            
            c1 = clock;
            [model,mInf.projectedTrain,mInf.predictedTrain] = obj.train(train, param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            [mInf.projectedTest, mInf.predictedTest] = obj.test( test.patterns, model);
            c2 = clock;
            
            mInf.testTime = etime(c2,c1);
            mInf.model = model;
            
        end
        
        function [model, projected, trainTargets] = train(obj, train, param)
            %TRAIN trains the model for the OPBE method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model and
            %the projected TRAIN and TEST patterns
            
            classes = unique(train.targets);
            nOfClasses = numel(classes);
            n = zeros(1,nOfClasses);
            for i=1:nOfClasses
                n(i) = sum(train.targets == i);
            end
            baseAlgorithm = SVORIM;
            
            % Sort patterns
            orderedPatterns = train.patterns(train.targets==1,:);
            orderedTargets = train.targets(train.targets == 1);
            for i = 2:nOfClasses
                orderedPatterns = [orderedPatterns ; train.patterns(train.targets==i,:)];
                orderedTargets = [orderedTargets; train.targets(train.targets == i)];
            end
            
            train.patterns = orderedPatterns;
            train.targets = orderedTargets;
            classBelongingProbTrain = ones(nOfClasses, size(train.patterns,1));
            weights = zeros(nOfClasses,1);
            
            for i = 1:nOfClasses
                nLowerRankingClasses = sum(classes<i);
                nHigherRankingClasses = sum(classes>i);
                
                nPreviousClasses = numel(train.targets(train.targets < i));
                nFollowingClasses = numel(train.targets(train.targets > i));
                
                % Assign labels depending on the decomposition
                if nPreviousClasses == 0
                    currentTargets = [train.targets(train.targets==1); ones(size(train.targets(train.targets>1)))*2];
                elseif nFollowingClasses ==0
                    currentTargets = [ones(size(train.targets(train.targets<i)));  ones(size(train.targets(train.targets==i)))*2];
                else
                    currentTargets = [ones(size(train.targets(train.targets<i))); ones(size(train.targets(train.targets==i)))*2; ones(size(train.targets(train.targets>i)))*3];
                end
                
                
                auxtrain.patterns = train.patterns;
                auxtrain.targets = currentTargets;
                
                % Train each label decomposition
                [model, projectedTrain] = baseAlgorithm.train(auxtrain, param);
                models(i) = model;
                
                % Estimate probabilities
                probTrain = obj.calculateProbabilities(projectedTrain, models(i).thresholds');
                
                % Compute weights and fused probabilities
                for j = 1: nOfClasses
                    if nHigherRankingClasses~= 0 && nLowerRankingClasses ~=0
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
                    elseif i==j
                        if nLowerRankingClasses == 0
                            classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .*  probTrain(1,:);
                            weights(j) = weights(j) + 1;
                        else
                            classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .* probTrain(2,:);
                            weights(j) = weights(j) + 1;
                        end
                    else
                        if nLowerRankingClasses == 0
                            classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .* (probTrain(2,:)/nHigherRankingClasses);
                            weights(j) = weights(j) + 1/nHigherRankingClasses;
                        else
                            classBelongingProbTrain(j,:) = classBelongingProbTrain(j,:) .* (probTrain(1,:)/nLowerRankingClasses);
                            weights(j) = weights(j) + 1/nLowerRankingClasses;
                        end
                    end
                    
                end
            end
            model.ensembleModels = models;
            model.parameters = param;
            
            % Join weights and probabilities into a final
            % decision label
            classBelongingProbTrain = classBelongingProbTrain ./ (weights*ones(1,size(classBelongingProbTrain,2)));
            % There is not a single projection, so projected vector
            % should not be used (it is however needed in the framework)
            
            % Compute final prediction
            [projected, trainTargets] = max(classBelongingProbTrain);
            trainTargets = trainTargets';
            
        end
        
        function [projected, testTargets] = test(obj, test, model)
            %TEST predict labels of TEST patterns labels using model in MODEL.
            models = model.ensembleModels;
            nOfClasses = size(models,2);
            classes = 1:nOfClasses;
            weights = zeros(nOfClasses,1);
            classBelongingProbTest = ones(nOfClasses, size(test,1));
            
            for i = 1:nOfClasses
                nLowerRankingClasses = sum(classes<i);
                nHigherRankingClasses = sum(classes>i);
                
                % Estimate probabilities
                [projectedTest] = obj.base_algorithm.test(test, models(i));
                probTest = obj.calculateProbabilities(projectedTest, models(i).thresholds');
                
                % Compute weights and fused probabilities
                
                for j = 1: nOfClasses
                    if nHigherRankingClasses~= 0 && nLowerRankingClasses ~=0
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
                    elseif i==j
                        if nLowerRankingClasses == 0
                            classBelongingProbTest(j,:) = classBelongingProbTest(j,:) .*  probTest(1,:);
                            weights(j) = weights(j) + 1;
                        else
                            classBelongingProbTest(j,:) = classBelongingProbTest(j,:) .* probTest(2,:);
                            weights(j) = weights(j) + 1;
                        end
                    else
                        if nLowerRankingClasses == 0
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
        
        function [y] = cummulativeProb(obj, x, beta)
            %CUMMULATIVEPROB computes the cummulative probabilities for a
            %set of projected patterns and thresholds
            %
            %   [Y] = CUMMULATIVEPROB(X, BETA) compute cummulative
            %   probabilities Y of projected patterns X with thresholds
            %   BETA
            
            y =  1 ./ (1+exp((x-beta))); %Logit
            %    y =  1-exp(-exp(beta-x)); %complementary log log
            %    y = exp(-exp(x-beta)); %negative log log
            %    y = normcdf(beta-x); %probit
            %    y = atan(beta-x)/pi + 0.5; % cauchit
        end
        
        function [g] = calculateProbabilities(obj, z, theta)
            %CALCULATEPROBABILITIES computes the probabilities for a set of
            %projected patterns and thresholds
            %
            %   [G] = CALCULATEPROBABILITIES(OBJ, Z, THETA)
            %   compute probabilities G of projected patterns PROJECTED
            %   with thresholds THRESHOLDS
            
            % Numerical fix
            nOfClasses = numel(theta)+1;
            if (numel(theta)==2)
                desired=4.0;
                actual=abs(theta(2) - theta(1));
                if actual<4
                    z = z*(desired/actual);
                    theta = theta*(desired/actual);
                end
            end
            
            f = zeros(nOfClasses, numel(z));
            g = zeros(nOfClasses, numel(z));
            
            
            for i=1:(nOfClasses-1)
                f(i,:) = obj.cummulativeProb(z',theta(i));
            end
            f(nOfClasses,:) = ones(1, size(z',2));
            
            g(1,:) = f(1,:);
            for i=2:nOfClasses
                g(i,:)=f(i,:)-f(i-1,:);
            end
            
            
        end
        
    end
    
end
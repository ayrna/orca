classdef OPBE < Algorithm
    %OPBE Ordinal Projection Based Ensemble (OPBE)[1]. This class derives
    %from the Algorithm Class and implements the OPBE method with the best
    %configuration found (product combiner, SVM base methodology, logit
    %function and equal distribution of probabilities). By default, this class uses
    %SVORIM implementation, but potentially any ORCA model can be used.
    %
    %   OPBE methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   References:
    %     [1] María Pérez-Ortiz, Pedro Antonio Gutiérrez and César
    %     Hervás-Martínez, Projection based ensemble learning for ordinal
    %     regression, IEEE Transactions on Cybernetics. Vol. 44 (5), 2014
    %     https://doi.org/10.1109/TCYB.2013.2266336
    
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original author: María Pérez Ortiz
    %   Contributors: Pedro A. Gutiérrez, Javier Sánchez-Monedero
    %   Citation: If you use this code, please cite the associated papers
    %      - http://www.uco.es/grupos/ayrna/elor2013
    %      - http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        description = 'Ordinal Projection Based Ensemble';
        parameters = [];
        baseMethod = SVORIM;
        % Method name as str to allow loading from configuration file. The
        % constructor will instanciate it via feval()
        base_algorithm = 'SVORIM';
    end
    
    methods
        
        % TODO: Update and test parameter description
        function obj = OPBE(varargin)
            %OPBE constructs an object of the class OPBE and sets its
            %default properties.
            %   obj = OPBE('baseMethod', METHOD) sets METHOD as base
            %   algorithm.
            obj.parseArgs(varargin);
            % TODO: Pass varargin parameters to base algorithm?
            obj.baseMethod = feval(obj.base_algorithm);
            %obj.name_parameters = obj.baseMethod.getParameterNames();
            obj.parameters = obj.baseMethod.parameters;
        end
        
        function [projected, trainTargets] = privfit(obj, train, param)
            %PRIVFIT trains the model for the OPBE method with TRAIN data and
            %vector of parameters PARAMETERS. 
            
            classes = unique(train.targets);
            nOfClasses = numel(classes);
            n = zeros(1,nOfClasses);
            for i=1:nOfClasses
                n(i) = sum(train.targets == i);
            end
            
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
                [projectedTrain] = obj.baseMethod.fit(auxtrain, param);
                models(i) = obj.baseMethod.getModel();
                
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
            obj.model = model;
            
            % Join weights and probabilities into a final
            % decision label
            classBelongingProbTrain = classBelongingProbTrain ./ (weights*ones(1,size(classBelongingProbTrain,2)));
            % There is not a single projection, so projected vector
            % should not be used (it is however needed in the framework)
            
            % Compute final prediction
            [projected, trainTargets] = max(classBelongingProbTrain);
            projected = projected';
            trainTargets = trainTargets';
            
        end
        
        function [projected, testTargets] = privpredict(obj, test)
            %PREDICT predicts labels of TEST patterns labels using model in MODEL.
            models = obj.model.ensembleModels;
            nOfClasses = size(models,2);
            classes = 1:nOfClasses;
            weights = zeros(nOfClasses,1);
            classBelongingProbTest = ones(nOfClasses, size(test,1));
            
            for i = 1:nOfClasses
                nLowerRankingClasses = sum(classes<i);
                nHigherRankingClasses = sum(classes>i);
                
                % Estimate probabilities
                obj.baseMethod.setModel(models(i));
                [projectedTest] = obj.baseMethod.predict(test);
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
            projected = projected';
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
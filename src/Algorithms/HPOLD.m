classdef HPOLD < Algorithm
    %HPOLD Hierarchical Partial Order Label Decomposition performs partial
    %order classification with a hierarchical model [1]. Class 1 versus the
    %rest is first classified with a binary model and the remainder labels
    %(2,3,...,Q) with an ordinal model. The available methods are logistic
    %regression and suport vector machine. For additional details see [1].
    %
    %   SVR methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   References:
    %     [1] J. Sánchez-Monedero, M. Pérez-Ortiz, A. Sáez, P.A. Gutiérrez,
    %         and C. Hervás-Martínez. "Partial order label decomposition
    %         approaches for melanoma diagnosis". Applied Soft Computing.
    %         Volume 64, March 2018, Pages 341-355.
    %         https://doi.org/10.1016/j.asoc.2017.11.042
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        description = 'Hierarchical Partial Order Label Decomposition';
        %C penalty coefficient and the kernel parameters (both for the binary
        %and ordinal methods).
        parameters = struct('C', 0.1, 'k', 0.1);
        binaryMethod = 'SVC1V1';
        ordinalMethod = 'SVORIM';
    end
    properties(Access = private)
        objBI;
        objOR;
    end
    
    methods
        
        % TODO: update doc
        function obj = HPOLD(varargin)
            %HPOLD constructs an object of the class HPOLD and sets its default
            %   characteristics
            %   OBJ = HPOLD() builds HPOLD
            obj.parseArgs(varargin);
        end
        
        function [projectedTrain, predictedTrain] = privfit( obj, train, param)
            %PRIVFIT trains the model for the HPOLD method with TRAIN data and
            %vector of parameters PARAM. 
            
            projectedTrain = -1*ones(length(train.targets),1);% dummy value
            predictedTrain = -1*ones(length(train.targets),1);% dummy value
            
            % Create binary dataset
            trainTargetsBi = ones(size(train.targets));
            trainTargetsBi(train.targets~=1)=2;
            
            trainBi.patterns = train.patterns;
            trainBi.targets = trainTargetsBi;
            
            % Create ordinal dataset by removing class obj.binClass patterns
            % and relabelling the rest of the labels
            trainOr.patterns = train.patterns(train.targets~=1,:);
            trainOr.targets = train.targets(train.targets~=1,:) - 1;
            
            % Create and train binary classifier
            switch(lower(obj.binaryMethod))
                case 'svc1v1'
                    parambi.C = param.C;
                    parambi.k = param.k;
                    obj.objBI = SVC1V1();
                    obj.objBI.fit(trainBi, parambi);
                case 'csvc1v1'
                    error('TODO')
                    parambi.C = param.C;
                    parambi.k = param.k;
                    obj.objBI = CSVC();
                    obj.objBI.fit(trainBi, parambi);
                case 'liblinear'
                    parambi.C = param.C;
                    obj.objBI = LIBLINEAR();
                    obj.objBI.fit(trainBi, parambi);
                otherwise
                    error(['Unknown binary classifier method:', obj.binaryMethod])
            end
            
            
            % Create and train ordinal classifier
            switch(lower(obj.ordinalMethod))
                case 'svorim'
                    obj.objOR = SVORIM();
                    paramor.C = param.C;
                    paramor.k = param.k;
                    obj.objOR.fit(trainOr,paramor);
                    %obj.objOR.model = obj.objOR.fit(trainOr,paramor);
                case 'pom'
                    obj.objOR = POM();
                    obj.objOR.fit(trainOr);
                    %obj.objOR.model = obj.objOR.fit(trainOr);
                otherwise
                    error(['Unknown ordinal classifier method:', obj.ordinalMethod])
            end
            
            % Save model and parameters
            model.parameters = param;
            model.modelBI = obj.objBI.getModel();
            model.modelOR = obj.objOR.getModel();
            obj.model = model;
            [projectedTrain, predictedTrain] = obj.predict(train.patterns);
        end
        
        function [projected, predTargets]= privpredict(obj, testPatterns)
            %PREDICT predict labels of TEST patterns labels using MODEL.
            projected = -1*ones(size(testPatterns,1),1);% dummy value
            % Binary prediction: classes 1/2
            [projectedTest_bi,predTargets] = obj.objBI.predict(testPatterns);
            % Ordinal prediction for patterns of class ~= class 1
            [projectedTest_or, predictedTest_or] = obj.objOR.predict(testPatterns(predTargets~=1,:));
            % +1 to correct label numbering
            predictedTest_or = predictedTest_or + 1;
            predTargets(predTargets~=1,:) = predictedTest_or;
        end
        
    end
    
end


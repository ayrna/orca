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
    %         and C. Hervás-Martínez. Partial order label decomposition
    %         approaches for melanoma diagnosis. Applied Soft Computing. In
    %         Press. 2017.
    %         https://doi.org/10.1016/j.asoc.2017.11.042
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        %C penalty coefficient and the kernel parameters (both for the binary
        %and ordinal methods)
        parameters = struct('c', 0.1, 'k', 0.1);
        
        binaryMethod = 'SVC1V1';
        ordinalMethod = 'SVORIM';
        kernelType = 'rbf';
    end
    
    properties(Access = private)
        objBI;
        objOR;
        modelBI;
        modelOR;
    end
    
    methods
        
        % TODO: update doc
        function obj = HPOLD()
            %HPOLD constructs an object of the class HPOLD and sets its default
            %   characteristics
            %   OBJ = HPOLD() builds HPOLD 
            obj.name = 'Hierarchical Partial Order Label Decomposition';
        end
        
        function [model, projectedTrain, predictedTrain] = fit( obj, train, param)
            %FIT trains the model for the HPOLD method with TRAIN data and
            %vector of parameters PARAMETERS. Returns the learned model.
            
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
                    parambi.c = param(1);
                    parambi.k = param(2);
                    obj.objBI = SVC1V1(obj.kernelType);
                    obj.modelBI = obj.objBI.fit(trainBi, parambi);
                case 'csvc1v1'
                    parambi.c = param(1);
                    parambi.k = param(2);
                    obj.objBI = CSVC(obj.kernelType);
                    obj.modelBI = obj.objBI.fit(trainBi, parambi);
                case 'lrliblinear'
                    parambi.c = param(1);
                    obj.objBI = LRLIBLINEAR();
                    obj.modelBI = obj.objBI.fit(trainBi, parambi);
                otherwise
                    error(['Unknown binary classifier method:', obj.binaryMethod])
            end
            
            
            % Create and train ordinal classifier
            switch(lower(obj.ordinalMethod))
                case 'svorim'
                    obj.objOR = SVORIM(obj.kernelType);
                    paramor.c = param(1);
                    paramor.k = param(2);
                    obj.modelOR = obj.objOR.fit(trainOr,paramor);
                    %obj.objOR.model = obj.objOR.fit(trainOr,paramor);
                case 'pom'
                    obj.objOR = POM();
                    obj.modelOR = obj.objOR.fit(trainOr);
                    %obj.objOR.model = obj.objOR.fit(trainOr);
                otherwise
                    error(['Unknown ordinal classifier method:', obj.ordinalMethod])
            end
            
            model.modelBI = obj.objBI.model;
            model.modelOR = obj.objOR.model;
        end
        
        function [projected, predTargets]= predict(obj, test, model)%, model_mc)
            %PREDICT predict labels of TEST patterns labels using MODEL.
            
            projected = -1*ones(size(test.targets));% dummy value
            
            % Binary prediction: classes 1/2
            [projectedTest_bi,predTargets] = obj.objBI.predict(test,model.modelBI);
            
            %%%% DEBUG
            %predTargetsBiOnly = predTargets;
            
            % Ordinal prediction for patterns of class ~= class 1
            testOr.patterns = test.patterns(predTargets~=1,:);
            testOr.targets = test.targets(predTargets~=1,:);
            
            [projectedTest_or, predictedTest_or] = obj.objOR.predict(testOr,model.modelOR);
            
            %             switch(lower(obj.ordinalMethod))
            %                 case 'svorim'
            %                     [projectedTest_or, predictedTest_or] = obj.objOR.predict(testOr,model.modelOR);
            %                 case 'pom'
            %                     [projectedTest_or, predictedTest_or] = obj.objOR.predict(testOr,model.modelOR);
            %                 otherwise
            %                     error(['Unknown ordinal classifier method:', obj.ordinalMethod])
            %             end
            
            predictedTest_or = predictedTest_or + 1;
            predTargets(predTargets~=obj.binClass,:) = predictedTest_or;
            
            %%%%%%%%%%%% DEBUG:
            %  BINARY prediction
            %             if false
            %             J = length(unique(test.targets));
            %             testTargetsBi = ones(size(test.targets));
            %             testTargetsBi(test.targets>=2)=2;
            %
            %             testBi.patterns = test.patterns;
            %             testBi.targets = testTargetsBi;
            %
            %             [projectedTest_bi,predTargetsBi] = obj.objBI.predict(testBi,model_bi);
            
            %             %%%%%%%%%% DEBUG: MULTICLASS prediction
            %             [projectedTest_mc,predTargetsMC] = obj.obj_mc.predict(test,model_mc);
            %
            %             cm = confusionmat(test.targets, predTargets);
            %             cm_bi = confusionmat(testBi.targets, predTargetsBi);
            %             cm_mc = confusionmat(test.targets, predTargetsMC);
            %
            %
            %             fid = fopen('prueba_HPOLD.txt', 'a+');
            %             %fprintf(fid, 'BI only:\tCCR %.3f,\tMAE %.3f,\tAMAE %.3f\n', CCR.calculateMetric(testBi.targets, predTargetsBiOnly), ...
            %             %    MAE.calculateMetric(testBi.targets, predTargetsBiOnly), AMAE.calculateMetric(testBi.targets, predTargetsBiOnly));
            %             fprintf(fid, 'BI+OR:\tCCR %.3f,\tMAE %.3f,\tAMAE %.3f\n', CCR.calculateMetric(test.targets, predTargets), ...
            %                 MAE.calculateMetric(test.targets, predTargets), AMAE.calculateMetric(test.targets, predTargets));
            %             for h = 1:size(cm,1),
            %                 for z = 1:size(cm,2),
            %                     fprintf(fid, '%d\t', cm(h,z));
            %                 end
            %                 fprintf(fid,'\n');
            %             end
            %
            %             fprintf(fid, 'BI:\tCCR %.3f,\tMAE %.3f,\tAMAE %.3f\n', CCR.calculateMetric(testBi.targets, predTargetsBi), ...
            %                 MAE.calculateMetric(testBi.targets, predTargetsBi), AMAE.calculateMetric(testBi.targets, predTargetsBi));
            %             for h = 1:size(cm_bi,1),
            %                 for z = 1:size(cm_bi,2),
            %                     fprintf(fid, '%d\t', cm_bi(h,z));
            %                 end
            %                 fprintf(fid,'\n');
            %             end
            %
            %             fprintf(fid, 'MC:\tCCR %.3f,\tMAE %.3f,\tAMAE %.3f\n', CCR.calculateMetric(test.targets, predTargetsMC), ...
            %                 MAE.calculateMetric(test.targets, predTargetsMC), AMAE.calculateMetric(test.targets, predTargetsMC));
            %
            %             for h = 1:size(cm_mc,1),
            %                 for z = 1:size(cm_mc,2),
            %                     fprintf(fid, '%d\t', cm_mc(h,z));
            %                 end
            %                 fprintf(fid,'\n');
            %             end
            %
            %             fprintf(fid, '-----------\n');
            %             fclose(fid);
            %             end % if false
            
        end
        
    end
    
end


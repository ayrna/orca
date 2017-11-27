classdef ORBoost < Algorithm
    %ORBoost ORBoost Boosting ensemble for Ordinal Regression [1]. This class
    %uses orensemble implementation at http://www.work.caltech.edu/~htlin/program/orensemble/
    %
    %   ORBoost methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
    %
    %   References:
    %
    %     [1] H.-T. Lin and L. Li, Large-margin thresholded ensembles for
    %         ordinal regression: Theory and practice, in Proc. of the 17th
    %         Algorithmic Learning Theory International Conference, ser.
    %         Lecture Notes in Artificial Intelligence (LNAI), J. L. Balcazar,
    %         P. M. Long, and F. Stephan, Eds., vol. 4264. Springer-Verlag,
    %         October 2006, pp. 319-333.
    %     [1] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
    %         F. Fernández-Navarro and C. Hervás-Martínez
    %         Ordinal regression methods: survey and experimental study
    %         IEEE Transactions on Knowledge and Data Engineering, Vol. 28. Issue 1
    %         2016
    %         http://dx.doi.org/10.1109/TKDE.2015.2457911
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        parameters = [];
        name_parameters = {};
        weights = true;
    end
    
    methods
        
        function obj = ORBoost()
            %ORBoost constructs an object of the class ORBoost and sets its default
            %   characteristics
            %   OBJ = ORBoost() builds ORBoost object
            obj.name = 'OR Ensemble with perceptrons';
        end
        
        function obj = defaultParameters(obj)
            %DEFAULTPARAMETERS dummy implementation to satisfy abstract
            %class API requirements
            obj.parameters = [];
        end
        
        function [mInf] = runAlgorithm(obj,train, test)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter
            %   values for the method. Test the generalization performance
            %   with TRAIN and TEST data and returns predictions and model
            %   in mInf structure.
            trainFile = tempname();
            dlmwrite(trainFile,[train.patterns train.targets],'delimiter',' ','precision',10);
            testFile = tempname();
            dlmwrite(testFile,[test.patterns test.targets],'delimiter',' ','precision',10);
            modelFile = tempname();
            
            c1 = clock;
            obj.train( train,trainFile, modelFile);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            c1 = clock;
            [mInf.projectedTrain,mInf.predictedTrain] = obj.test(train,trainFile,modelFile);
            [mInf.projectedTest,mInf.predictedTest] = obj.test(test,testFile,modelFile);
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            
            fid = fopen(modelFile);
            if ~(exist ('OCTAVE_VERSION', 'builtin') > 0) && verLessThan('matlab','8.4')
                s = textscan(fid,'%s','Delimiter','\n','bufsize', 2^18-1);
            else
                s = textscan(fid,'%s','Delimiter','\n');
            end
            
            s = s{1};
            fclose(fid);
            
            model.algorithm = 'OREnsemble';
            model.textInformation = s;
            model.weights = obj.weights;
            mInf.model = model;
            
            delete(trainFile);
            delete(testFile);
            delete(modelFile);
        end
        
        function train( obj,train,trainFile, modelFile )
            %TRAIN trains the model for the SVR method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            if ispc
                bin_train = fullfile('Algorithms','orensemble', 'boostrank-train.exe');
                execute_train = sprintf('%s %s %d %d %d1 204 %d 2000 %s',...
                    bin_train, trainFile,size(train.patterns,1),size(train.patterns,2),(3+obj.weights),max(unique(train.targets)),modelFile);
                system(execute_train);
            else
                execute_train = sprintf('./Algorithms/orensemble/hack.sh ./Algorithms/orensemble/boostrank-train %s %d %d %d1 204 %d 2000 %s',...
                    trainFile,size(train.patterns,1),size(train.patterns,2),(3+obj.weights),max(unique(train.targets)),modelFile);
                system(execute_train);
            end
        end
        
        function [projected, testTargets]= test( obj,test,testFile,modelFile )
            %TEST predict labels of TEST patterns labels using MODEL.
            predictFile = tempname();
            if ispc
                bin_predict = fullfile('Algorithms','orensemble', 'boostrank-predict.exe');
                execute_test = sprintf('%s %s %d %d %s 2000 %s',...
                    bin_predict,testFile,size(test.patterns,1),...
                    size(test.patterns,2),modelFile,predictFile);
            else
                execute_test = ...
                    sprintf('./Algorithms/orensemble/hack.sh ./Algorithms/orensemble/boostrank-predict %s %d %d %s 2000 %s',...
                    testFile,size(test.patterns,1),size(test.patterns,2),modelFile,predictFile);
            end
            
            system(execute_test);
            all = load(predictFile);
            testTargets = all(:,1);
            projected = all(:,2);
            delete(predictFile);
        end
        
    end
end

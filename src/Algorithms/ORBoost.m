classdef ORBoost < Algorithm
    %ORBoost ORBoost Boosting ensemble for Ordinal Regression [1]. This class
    %uses orensemble implementation at http://www.work.caltech.edu/~htlin/program/orensemble/
    %
    %   ORBoost methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
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
        description = 'OR Ensemble with perceptrons';
        parameters = [];
        weights = true;
    end
    
    methods
        
        function obj = ORBoost(varargin)
            %ORBoost constructs an object of the class ORBoost and sets its default
            %   characteristics
            %   OBJ = ORBoost() builds ORBoost object
            obj.parseArgs(varargin);
        end
        
        function [projectedTrain, predictedTrain] = privfit(obj,train,parameters)
            %PRIVFIT trains the model for the ORBoost method with TRAIN data and
            %vector of parameters PARAMETERS. 
            
            % Output model file
            modelFile = tempname();
            % Write train file
            trainFile = tempname();
            dlmwrite(trainFile,[train.patterns train.targets],'delimiter',' ','precision',10);
            
            % Prepare command line
            if ispc
                bin_train = fullfile('Algorithms','orensemble', 'boostrank-train.exe');
                execute_train = sprintf('%s %s %d %d %d1 204 %d 2000 %s',...
                    bin_train, trainFile,size(train.patterns,1),size(train.patterns,2),(3+obj.weights),max(unique(train.targets)),modelFile);
            else
                execute_train = sprintf('%s/orensemble/hack.sh %s/orensemble/boostrank-train %s %d %d %d1 204 %d 2000 %s',...
                    fileparts(which('Algorithm.m')), fileparts(which('Algorithm.m')),...
                    trainFile,size(train.patterns,1),size(train.patterns,2),(3+obj.weights),max(unique(train.targets)),modelFile);
            end
            
            % Execute train
            system(execute_train);
            
            % Extract contents of model file
            fid = fopen(modelFile);
            if ~(exist ('OCTAVE_VERSION', 'builtin') > 0) && verLessThan('matlab','8.4')
                s = textscan(fid,'%s','Delimiter','\n','bufsize', 2^18-1);
            else
                s = textscan(fid,'%s','Delimiter','\n');
            end
            s = s{1};
            fclose(fid);
            
            model.textInformation = s;
            model.weights = obj.weights;
            obj.model = model;
            [projectedTrain,predictedTrain] = obj.predict(train.patterns);
            % Delete temp files
            delete(trainFile);
            delete(modelFile);
        end
        
        function [projected, predicted]= privpredict( obj,test)
            %PREDICT predicts labels of TEST patterns labels. The object needs to be fitted to the data first.
            
            % Write test file
            testFile = tempname();
            dlmwrite(testFile,[test ones(size(test,1),1)],'delimiter',' ','precision',10);
            % Write model file
            modelFile = tempname();
            fid = fopen(modelFile,'w');
            nLines = size(obj.model.textInformation,1);
            for iLine = 1:nLines
                fprintf(fid,'%s\n',obj.model.textInformation{iLine});
            end
            fclose(fid);
            % Name of prediction file
            predictFile = tempname();
            
            % Prepare command line
            if ispc
                bin_predict = fullfile(fileparts(which('Algorithm.m')),'orensemble', 'boostrank-predict.exe');
                execute_test = sprintf('%s %s %d %d %s 2000 %s',...
                    bin_predict,testFile,size(test,1),...
                    size(test,2),modelFile,predictFile);
            else
                execute_test = ...
                    sprintf('%s/orensemble/hack.sh %s/orensemble/boostrank-predict %s %d %d %s 2000 %s',...
                    fileparts(which('Algorithm.m')),fileparts(which('Algorithm.m')),testFile,size(test,1),size(test,2),modelFile,predictFile);
            end
            
            % Execute test
            system(execute_test);
            % Extract predictions (targets and projections)
            all = load(predictFile);
            predicted = all(:,1);
            projected = all(:,2);
            % Delete temp files
            delete(predictFile);
            delete(testFile);
            delete(modelFile);
        end
        
    end
end

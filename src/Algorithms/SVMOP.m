classdef SVMOP < Algorithm
    %SVMOP Support vector machines using Frank & Hall method for ordinal
    % regression (by binary decomposition). This class uses libsvm-weights
    % for SVM training (https://www.csie.ntu.edu.tw/~cjlin/libsvm).
    %   SVMOP methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
    %
    %   References:
    %     [1] E. Frank and M. Hall, "A simple approach to ordinal classification"
    %         in Proceedings of the 12th European Conference on Machine Learning,
    %         ser. EMCL'01. London, UK: Springer-Verlag, 2001, pp. 145–156.
    %         https://doi.org/10.1007/3-540-44795-4_13
    %     [2] W. Waegeman and L. Boullart, "An ensemble of weighted support
    %         vector machines for ordinal regression", International Journal
    %         of Computer Systems Science and Engineering, vol. 3, no. 1,
    %         pp. 47–51, 2009.
    %     [3] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
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
        name_parameters = {'C','k'};
        parameters;
        weights = true;
    end
    
    methods
        
        function obj = SVMOP(kernel)
            %SVR SVMOP an object of the class SVR and sets its default
            %   characteristics
            %   OBJ = SVR(KERNEL) builds SVR with KERNEL as kernel function
            obj.name = 'Frank Hall Support Vector Machines';
            if(nargin ~= 0)
                obj.kernelType = kernel;
            else
                obj.kernelType = 'rbf';
            end
        end
        
        function obj = defaultParameters(obj)
            %DEFAULTPARAMETERS It assigns the parameters of the algorithm
            %   to a default value.
            % cost
            obj.parameters.C = 10.^(-3:1:3);
            % kernel width
            obj.parameters.k = 10.^(-3:1:3);
        end
        
        function [mInf] = runAlgorithm(obj,train, test, parameters)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter
            %   values for the method. Test the generalization performance
            %   with TRAIN and TEST data and returns predictions and model
            %   in mInf structure
            addpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
            
            param.C = parameters(1);
            param.k = parameters(2);
            
            
            c1 = clock;
            classes = unique(train.targets);
            nOfClasses = numel(classes);
            [models] = obj.train(train,nOfClasses,param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            % Probabilities are included as ProjectedTrain and
            % ProjectedTest
            [mInf.projectedTrain,mInf.predictedTrain] = obj.test(train,models,nOfClasses);
            [mInf.projectedTest,mInf.predictedTest] = obj.test(test,models,nOfClasses);
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            
            model.models=models;
            model.algorithm = 'SVMOP';
            model.parameters = param;
            model.weights = obj.weights;
            mInf.model = model;
            
            rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
        end
        
        
        function [models]= train( obj,train,nOfClasses,parameters)
            %TRAIN trains the model for the SVR method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            patterns = train.patterns(train.targets==1,:);
            labels = train.targets(train.targets == 1);
            
            for i = 2:nOfClasses
                patterns = [patterns ; train.patterns(train.targets==i,:)];
                labels = [labels ; train.targets(train.targets == i)];
            end
            
            train.targets = labels;
            train.patterns = patterns';
            
            models = cell(1, nOfClasses-1);
            for i = 2:nOfClasses
                
                etiquetas_train = [ ones(size(train.targets(train.targets<i))) ;  ones(size(train.targets(train.targets>=i)))*2];
                
                % Train
                options = ['-b 1 -t 2 -c ' num2str(parameters.C) ' -g ' num2str(parameters.k) ' -q'];
                if obj.weights
                    weightsTrain = obj.computeWeights(i-1,train.targets);
                else
                    weightsTrain = ones(size(train.targets));
                end
                models{i} = svmtrain(weightsTrain, etiquetas_train, train.patterns', options);
                if(numel(models{i}.SVs)==0)
                    disp('Something went wrong. Please check the training patterns.')
                end
            end
            
            
        end
        
        function [probTest,clasetest] = test(obj,test,models,nOfClasses)
            %TEST predict labels of TEST patterns labels using MODEL.
            probTest = zeros(nOfClasses, size(test.patterns,1));
            for i = 2:nOfClasses
                testLabels = [ ones(size(test.targets(test.targets<i))) ;  ones(size(test.targets(test.targets>=i)))*2];
                [pr, acc, probTs] = svmpredict(testLabels,test.patterns,models{i},'-b 1');
                
                probTest(i-1,:) = probTs(:,2)';
            end
            probts(1,:) = ones(size(probTest(1,:))) - probTest(1,:);
            for i=2:nOfClasses
                probts(i,:) =  probTest(i-1,:) -  probTest(i,:);
            end
            probts(nOfClasses,:) =  probTest(nOfClasses-1,:);
            [aux, clasetest] = max(probts);
            clasetest = clasetest';
        end
        
        function [weights] = computeWeights(obj, p, targets)
            weights = ones(size(targets));
            weights(targets<=p) = (p+1-targets(targets<=p)) * size(targets(targets<=p),1) / sum(p+1-targets(targets<=p));
            weights(targets>p) = (targets(targets>p)-p) * size(targets(targets>p),1) / sum(targets(targets>p)-p);
        end
        
    end
    
end


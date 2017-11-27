classdef CSSVC < Algorithm
    %CSSVC Ordinal Support Vector Classifier using 1VsAll approach with
    %ordinal weights. This class uses |libsvm-weights-3.12| for SVM
    %training available at https://www.csie.ntu.edu.tw/~cjlin/libsvm
    %
    %   CSSVC methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
    %
    %   References:
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
        name_parameters = {'C','k'};
        parameters;
    end
    
    methods
        function obj = CSSVC(kernel)
            %CSSVC constructs an object of the class SVR and sets its default
            %   characteristics
            %   OBJ = CSSVC(KERNEL) builds CSSVC with KERNEL as kernel function
            obj.name = 'Support Vector Machine Classifier with 1vsAll paradigm with ordinal weights';
            if(nargin ~= 0)
                obj.kernelType = kernel;
            else
                obj.kernelType = 'rbf';
            end
            
        end
        
        function obj = defaultParameters(obj)
            %DEFAULTPARAMETERS It assigns the parameters of the algorithm
            %to a default value.
            
            % cost
            obj.parameters.C = 10.^(-3:1:3);
            % kernel width
            obj.parameters.k = 10.^(-3:1:3);
        end
        
        function [model_information] = runAlgorithm(obj,train, test, parameters)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter
            %   values for the method. Test the generalization performance
            %   with TRAIN and TEST data and returns predictions and model
            %   in mInf structure.
            addpath(fullfile(pwd,'Algorithms','libsvm-weights-3.12','matlab'));
            param.C = parameters(1);
            param.k = parameters(2);
            
            c1 = clock;
            model = obj.train(train, param);
            c2 = clock;
            model_information.trainTime = etime(c2,c1);
            
            c1 = clock;
            [model_information.projectedTrain, model_information.predictedTrain] = obj.test(train,model);
            [model_information.projectedTest,model_information.predictedTest ] = obj.test(test,model);
            c2 = clock;
            model_information.testTime = etime(c2,c1);
            
            model.algorithm = 'CSSVC';
            model.parameters = param;
            model_information.model = model;
            
            rmpath(fullfile(pwd,'Algorithms','libsvm-weights-3.12','matlab'));
            
        end
        
        function [model]= train( obj, train, param)
            %TRAIN trains the model for the SVR method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            options = ['-t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
            
            labelSet = unique(train.targets);
            labelSetSize = length(labelSet);
            models = cell(labelSetSize,1);
            
            for i=1:labelSetSize
                labels = double(train.targets == labelSet(i));
                weights = obj.ordinalWeights(i, train.targets);
                models{i} = svmtrain(weights,labels, train.patterns, options);
            end
            
            model = struct('models', {models}, 'labelSet', labelSet);
        end
        
        function [decv, pred]= test(obj, test, model)
            %TEST predict labels of TEST patterns labels using MODEL.
            labelSet = model.labelSet;
            labelSetSize = length(labelSet);
            models = model.models;
            decv= zeros(size(test.targets, 1), labelSetSize);
            
            for i=1:labelSetSize
                labels = double(test.targets == labelSet(i));
                [l,a,d] = svmpredict(labels, test.patterns, models{i});
                decv(:, i) = d * (2 * models{i}.Label(1) - 1);
            end
            
            [tmp,pred] = max(decv, [], 2);
            pred = labelSet(pred);
        end
        
        function [w] = ordinalWeights(obj, p, targets)
            %ORDINALWEIGHTS compute the weights to apply to the set of
            %training patterns.
            %   [W] = ORDINALWEIGHTS(P, TARGETS) compute the weights of P,
            %   scalar corresponding to the indexes of the classes or class
            %   being considered, and TARGETS, training targets.
            w = ones(size(targets));
            w(targets~=p) = (abs(p-targets(targets~=p))+1) * size(targets(targets~=p),1) / sum(abs(p-targets(targets~=p))+1);
            w(targets==p) = 1;
        end
    end
end

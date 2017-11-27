classdef SVORIM < Algorithm
    %SVORIM Support Vector for Ordinal Regression (Implicit constraints)
    %   This class derives from the Algorithm Class and implements the
    %   SVORIM method. This class uses SVORIM implementation by
    %   W. Chu et al (http://www.gatsby.ucl.ac.uk/~chuwei/svor.htm)
    %
    %   SVORIM methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
    %
    %   References:
    %     [1] W. Chu and S. S. Keerthi, Support Vector Ordinal Regression,
    %         Neural Computation, vol. 19, no. 3, pp. 792–815, 2007.
    %         http://10.1162/neco.2007.19.3.792
    %     [2] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
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
        parameters;
        name_parameters = {'C', 'k'};
    end
    
    methods
        function obj = SVORIM(kernel)
            %SVORIM constructs an object of the class SVR and sets its default
            %   characteristics
            %   OBJ = SVORIM(KERNEL) builds SVR with KERNEL as kernel function
            obj.name = 'Support Vector for Ordinal Regression (Implicit constraints)';
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
            obj.parameters.C =  10.^(-3:1:3);
            % kernel width
            obj.parameters.k = 10.^(-3:1:3);
        end
        
        %TODO: Fix train/test API
        function [mInf] = runAlgorithm(obj,train, test, parameters)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter
            %   values for the method. Test the generalization performance
            %   with TRAIN and TEST data and returns predictions and model
            %   in mInf structure.
            addpath(fullfile('Algorithms','SVORIM'));
            
            param.C = parameters(1);
            param.k = parameters(2);
            
            c1 = clock;
            [model,mInf.projectedTest,mInf.projectedTrain, mInf.trainTime, mInf.testTime] = obj.train([train.patterns train.targets],[test.patterns test.targets],param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            mInf.predictedTrain = obj.test(mInf.projectedTrain, model);
            mInf.predictedTest = obj.test(mInf.projectedTest, model);
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            mInf.model = model;
            
            rmpath(fullfile('Algorithms','SVORIM'));
            
        end
        
        function [model, projectedTest, projectedTrain, trainTime, testTime] = train(obj, train,test, parameters)
            %TRAIN trains the model for the SVR method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            [projectedTest, alpha, thresholds, projectedTrain, trainTime, testTime] = svorim(train,test,parameters.k,parameters.C,0,0,0);
            model.projection = alpha;
            model.thresholds = thresholds;
            model.parameters = parameters;
            model.algorithm = 'SVORIM';
        end
        
        
        function [targets] = test(obj, project, model)
            %TEST predict labels of TEST patterns labels using MODEL.
            numClasses = size(model.thresholds,2)+1;
            project2 = repmat(project, numClasses-1,1);
            project2 = project2 - model.thresholds'*ones(1,size(project2,2));
            
            % Asignation of the class
            % f(x) = max {Wx-bk<0} or Wx - b_(K-1) > 0
            wx=project2;
            
            % The procedure for that is the following:
            % We assign the values > 0 to NaN
            wx(wx(:,:)>0)=NaN;
            
            % Then, we choose the biggest one.
            [maximum,targets]=max(wx,[],1);
            
            % If a max is equal to NaN is because Wx-bk for all k is >0, so this
            % pattern belongs to the last class.
            targets(isnan(maximum(:,:)))=numClasses;
            
            targets = targets';
        end
        
        
    end
    
end


classdef SVORIM < Algorithm
    %SVORIM Support Vector for Ordinal Regression (Implicit constraints)
    %   This class derives from the Algorithm Class and implements the
    %   SVORIM method. This class uses SVORIM implementation by
    %   W. Chu et al (http://www.gatsby.ucl.ac.uk/~chuwei/svor.htm)
    %
    %   SVORIM methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
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
        description = 'Support Vector for Ordinal Regression (Implicit constraints)';
        parameters = struct('C', 0.1, 'k', 0.1);
    end
    properties (Access = private)
        algorithmMexPath = fullfile(fileparts(which('Algorithm.m')),'SVORIM');
    end
    
    methods
        function obj = SVORIM(varargin)
            %SVORIM constructs an object of the class SVORIM and sets its default
            %   characteristics
            %   OBJ = SVORIM() builds SVORIM with RBF as kernel function
            obj.parseArgs(varargin);
        end
        
        function [projectedTrain,predictedTrain] = privfit(obj, train, parameters)
            %PRIVFIT trains the model for the SVORIM method with TRAIN data and
            %vector of parameters PARAMETERS. 
            
            if isempty(strfind(path,obj.algorithmMexPath))
                addpath(obj.algorithmMexPath);
            end
            [alpha, thresholds, projectedTrain] = svorim([train.patterns train.targets],parameters.k,parameters.C,0,0,0);
            predictedTrain = obj.assignLabels(projectedTrain, thresholds);
            model.projection = alpha;
            model.thresholds = thresholds;
            model.parameters = parameters;
            model.train = train.patterns;
            obj.model = model;
            projectedTrain = projectedTrain';
            if ~isempty(strfind(path,obj.algorithmMexPath))
                rmpath(obj.algorithmMexPath);
            end
        end
        
        function [projected, predicted] = privpredict(obj, test)
            %PREDICT predicts labels of TEST patterns labels. The object needs to be fitted to the data first.
            kernelMatrix = computeKernelMatrix(obj.model.train',test','rbf',obj.model.parameters.k);
            projected = obj.model.projection*kernelMatrix;
            
            predicted = SVORIM.assignLabels(projected, obj.model.thresholds);
            projected = projected';
        end
    end
    methods (Static = true)
        function predicted = assignLabels(projected, thresholds)
            numClasses = size(thresholds,2)+1;
            %TEST assign the labels from projections and thresholds
            project2 = repmat(projected, numClasses-1,1);
            project2 = project2 - thresholds'*ones(1,size(project2,2));
            
            % Asignation of the class
            % f(x) = max {Wx-bk<0} or Wx - b_(K-1) > 0
            wx=project2;
            
            % The procedure for that is the following:
            % We assign the values > 0 to NaN
            wx(wx(:,:)>0)=NaN;
            
            % Then, we choose the biggest one.
            [maximum,predicted]=max(wx,[],1);
            
            % If a max is equal to NaN is because Wx-bk for all k is >0, so this
            % pattern belongs to the last class.
            predicted(isnan(maximum(:,:)))=numClasses;
            
            predicted = predicted';
        end
        
    end
    
end


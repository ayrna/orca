classdef POM < Algorithm
    %POM Proportional Odd Model for Ordinal Regression
    %
    %   POM methods:
    %      fitpredict               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   POM properties:
    %      linkFunction               - Link function, default set to logit
    %                                   Available options are 'logit',
    %                                   'probit', 'comploglog' or 'loglog'.
    %                                   Octave only supports 'logit'
    %   References:
    %     [1] P. McCullagh, Regression models for ordinal data,  Journal of
    %         the Royal Statistical Society. Series B (Methodological), vol. 42,
    %         no. 2, pp. 109–142, 1980.
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
    % POM Proportional Odd Model for Ordinal Regression
    %   This class derives from the Algorithm Class and implements the
    %   POM method.
    % Further details in: * P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
    %                       F. Fernández-Navarro and C. Hervás-Martínez (2015),
    %                       "Ordinal regression methods: survey and
    %                       experimental study",
    %                       IEEE Transactions on Knowledge and Data
    %                       Engineering. Vol. Accepted
    %                     * P. McCullagh, "Regression models for ordinal
    %                       data," Journal of the Royal Statistical
    %                       Society. Series B (Methodological), vol. 42,
    %                       no. 2, pp. 109–142, 1980.
    
    properties
        linkFunction = 'logit';
        description = 'Linear Proportional Odds Model for Ordinal Regression';
        parameters = [];
    end
    
    methods
        function obj = POM(varargin)
            %POM constructs an object of the class POM. This method does not
            %have any parameters
            obj.parseArgs(varargin);
        end
        
        function obj = set.linkFunction(obj, value)
            %SET.LINKFUNCTION verifies if the value for the variable
            %linkFunction is correct. Returns class object wiht correct 
            %value for the variable |linkFunction|.
            if exist ('OCTAVE_VERSION', 'builtin') > 0 && ...
                    ~strcmpi(value,'logit')
                error('Invalid link function. Octave only supports logit link function');                
            elseif ~(strcmpi(value,'logit') || strcmpi(value,'probit') || ...
                 strcmpi(value,'comploglog') || strcmpi(value,'loglog'))
                error('Invalid link function. Supported MATLAB link functions: logit, probit, comploglog, loglog');
            else
                obj.linkFunction = value;
            end
        end

        function [projectedTrain, predictedTrain]= privfit( obj,train,parameters)
            %PRIVFIT trains the model for the POM method with TRAIN data and
            %vector of parameters PARAMETERS. 
            nOfClasses = numel(unique(train.targets));
            % TODO: Debug size octave
            if exist ('OCTAVE_VERSION', 'builtin') > 0
                pkg load statistics;
                [model.thresholds, model.projection] = logistic_regression(train.targets, train.patterns);
                pkg unload statistics;
            else
                % Obtain coefficients of the ordinal regression model
                betaHatOrd = mnrfit(train.patterns,train.targets,'model',...
                    'ordinal','interactions','off','Link',obj.linkFunction);
                
                model.thresholds = -betaHatOrd(1:nOfClasses-1);
                model.projection = betaHatOrd(nOfClasses:end);
            end
            model.thresholds = model.thresholds';
            obj.model = model;
            [projectedTrain, predictedTrain] = obj.predict(train.patterns);
        end
        
        function [projected, predicted ] = privpredict( obj, testPatterns)
            %PREDICT predict labels of TEST patterns labels using fitted model 
            model = obj.model;
            
            if exist ('OCTAVE_VERSION', 'builtin') > 0
                numClasses = size(model.thresholds,2)+1;
                m = size(testPatterns,1);
                projected = model.projection' * testPatterns';
                z3=repmat(model.thresholds,m,1)-repmat(projected',1,numClasses-1);
                a3T =  1.0 ./ (1.0 + exp(-z3));
                a3 = [a3T ones(m,1)];
                a3(:,2:end) = a3(:,2:end) - a3(:,1:(end-1));
                [M,predicted] = max(a3,[],2);
            else
                prob = mnrval([-model.thresholds'; model.projection],...
                    testPatterns,'model','ordinal','interactions','off',...
                    'Link',obj.linkFunction);
                [aux,predicted] = max(prob,[],2);
                projected = model.projection' * testPatterns';
                projected = projected';
            end
        end
    end
    
end


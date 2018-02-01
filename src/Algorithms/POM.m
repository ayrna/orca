classdef POM < Algorithm
    %POM Proportional Odd Model for Ordinal Regression
    %
    %   POM methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
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
    %                     * P. McCullagh, “Regression models for ordinal
    %                       data,” Journal of the Royal Statistical
    %                       Society. Series B (Methodological), vol. 42,
    %                       no. 2, pp. 109–142, 1980.
    
    properties
        description = 'Linear Proportional Odds Model for Ordinal Regression';
        parameters = [];
    end
    
    methods
        function obj = POM(varargin)
            %POM constructs an object of the class POM. This method does not
            %have any parameters
            obj.parseArgs(varargin);
        end

        function [model, projectedTrain, predictedTrain]= fit( obj,train,parameters)
            %FIT trains the model for the POM method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            nOfClasses = numel(unique(train.targets));
            % TODO: Debug size octave
            if exist ('OCTAVE_VERSION', 'builtin') > 0
                [model.thresholds, model.projection] = logistic_regression(train.targets, train.patterns);    
            else
                % Obtain coefficients of the ordinal regression model
                betaHatOrd = mnrfit(train.patterns,train.targets,'model','ordinal','interactions','off');
                
                model.thresholds = betaHatOrd(1:nOfClasses-1);
                model.projection = -betaHatOrd(nOfClasses:end);
            end
            model.thresholds = model.thresholds';
            [projectedTrain, predictedTrain] = obj.predict(train.patterns, model);
        end
        
        function [ projected, predicted ] = predict( obj, testPatterns, model)
            %PREDICT predict labels of TEST patterns labels using MODEL.
            numClasses = size(model.thresholds,2)+1;
            projected = model.projection' * testPatterns';
            
            % We calculate the projected patterns minus each threshold, and then with
            % the following decision rule we can compute the class to which each pattern
            % belongs to.
            projected2 = repmat(projected, numClasses-1,1);
            projected2 = projected2 - model.thresholds'*ones(1,size(projected2,2));
            
            % Asignation of the class
            % f(x) = max {Wx-bk<0} or Wx - b_(K-1) > 0
            wx=projected2;
            
            % The procedure for that is the following:
            % We assign the values > 0 to NaN
            wx(wx(:,:)>0)=NaN;
            
            % Then, we choose the biggest one.
            [maximum,predicted]=max(wx,[],1);
            
            % If a max is equal to NaN is because Wx-bk for all k is >0, so this
            % pattern belongs to the last class.
            predicted(isnan(maximum(:,:)))=numClasses;
            
            projected = projected';
            predicted = predicted';
            
        end
    end
    
end


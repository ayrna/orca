%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for the POM method.
% 
% The code has been tested with Ubuntu 12.04 x86_64, Debian Wheezy 8, Matlab R2009a and Matlab 2011
% 
% If you use this code, please cite the associated paper
% Code updates and citing information:
% http://www.uco.es/grupos/ayrna/orreview
% https://github.com/ayrna/orca
% 
% AYRNA Research group's website:
% http://www.uco.es/ayrna 
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
% Licence available at: http://www.gnu.org/licenses/gpl-3.0.html
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef POM < Algorithm
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
		
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: parameters (Private)
        % Description: No parameters for this algorithm
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        parameters = [];

        name_parameters = {};
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: POM (Public Constructor)
        % Description: It constructs an object of the class POM and sets its
        %               characteristics.
        % Type: Void
        % Arguments:
        %           No arguments
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
        function obj = POM(opt)
            obj.name = 'Linear Proportional Odds Model for Ordinal Regression';
            % This method don't use kernel functions.
            obj.kernelType = 'no';
        end
		

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: defaultParameters (Public)
        % Description: It assigns the parameters of the algorithm to a default value.
        % Type: Void
        % Arguments: 
        %           No arguments for this function.
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
        function obj = defaultParameters(obj)
            obj.parameters = [];
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runAlgorithm (Public)
        % Description: This function runs the corresponding
        %               algorithm, fitting the model and 
        %               testing it in a dataset.
        % Type: It returns the model (Struct) 
        % Arguments: 
        %           Train --> Training data for fitting the model
        %           Test --> Test data for validation
        %           parameters --> vector with the parameter information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
        function model_information = runAlgorithm(obj,train, test)

                c1 = clock;
                [model]= obj.train( train );
                % Time information for training
                c2 = clock;
                model_information.trainTime = etime(c2,c1);

                c1 = clock;
                [model_information.projectedTrain,model_information.predictedTrain] = obj.test( train.patterns, model);
                [model_information.projectedTest,model_information.predictedTest] = obj.test( test.patterns, model);
                c2 = clock;
                % time information for testing
                model_information.testTime = etime(c2,c1);

                model_information.model = model;
                
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the POM algorithm.
        % Type: It returns the model
        % Arguments: 
        %           trainPatterns --> Train structure
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [model]= train( obj,train)
                    
                    nOfClasses = numel(unique(train.targets));
                    if exist ('OCTAVE_VERSION', 'builtin') > 0
                      [model.thresholds, model.projection] = logistic_regression(train.targets, train.patterns);
                    else
                      % Obtain coefficients of the ordinal regression model
                      betaHatOrd = mnrfit(train.patterns,train.targets,'model','ordinal','interactions','off');
                    
                      model.thresholds = betaHatOrd(1:nOfClasses-1);
                      model.projection = -betaHatOrd(nOfClasses:end);
                    end

                    model.algorithm = 'POM';
                    % Estimated Probabilities
                    %pHatOrd = mnrval(betaHatOrd,trainPatterns,'model','ordinal','interactions','off');
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test a model given in
        %               a set of test patterns.
        % Outputs: Two arrays (projected patterns and predicted targets)
        % Arguments: 
        %           testPatterns --> Test data
        %           model --> struct with the model information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        function [ projected,testTargets ] = test( obj, testPatterns, model)
                numClasses = size(model.thresholds,1)+1;
                projected = model.projection' * testPatterns';
                
                % We calculate the projected patterns minus each threshold, and then with
                % the following decision rule we can compute the class to which each pattern
                % belongs to.
                projected2 = repmat(projected, numClasses-1,1);
                projected2 = projected2 - model.thresholds*ones(1,size(projected2,2));

                % Asignation of the class
                % f(x) = max {Wx-bk<0} or Wx - b_(K-1) > 0
                wx=projected2;

                % The procedure for that is the following:
                % We assign the values > 0 to NaN
                wx(wx(:,:)>0)=NaN;

                % Then, we choose the biggest one.
                [maximum,testTargets]=max(wx,[],1);

                % If a max is equal to NaN is because Wx-bk for all k is >0, so this
                % pattern belongs to the last class.
                testTargets(isnan(maximum(:,:)))=numClasses;

                testTargets = testTargets';

         end
    end
    
end


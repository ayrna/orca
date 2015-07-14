%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for the SVR method.
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

classdef SVR < Algorithm
    %SVR Support Vector Regression
    %   This class derives from the Algorithm Class and implements the
    %   SVR method. 
    
    properties
        
        name_parameters = {'C','k','e'}
        
	parameters
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: SVR (Public Constructor)
        % Description: It constructs an object of the class
        %               SVR and sets its characteristics.
        % Type: Void
        % Arguments:
        %           kernel--> Type of Kernel function
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = SVR(kernel)
            obj.name = 'Support Vector Regression';
            if(nargin ~= 0)
                obj.kernelType = kernel;
            else
                obj.kernelType = 'rbf';
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: defaultParameters (Public)
        % Description: It assigns the parameters of the
        %               algorithm to a default value.
        % Type: Void
        % Arguments:
        %           No arguments for this function.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = defaultParameters(obj)
            obj.parameters.C = 10.^(3:-1:-3);
	    % kernel width
            obj.parameters.k = 10.^(3:-1:-3);
	    % epsilon
            obj.parameters.e = 10.^(-3:1:0);
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
        
        function [model_information] = runAlgorithm(obj,train, test, parameters)
            addpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
            
            param.C = parameters(1);
            param.k = parameters(2);
            param.e = parameters(3);
            
            c1 = clock;
            % Scale the targets
            nOfClasses = numel(unique(train.targets));
            
            auxTrain = train;
            auxTest = test;
            
            auxTrain.targets = (auxTrain.targets-1)/(nOfClasses-1);
            auxTest.targets = (auxTest.targets-1)/(nOfClasses-1);
            
            classes = unique([auxTrain.targets' auxTest.targets']);
            
            model = obj.train( auxTrain, param);
            c2 = clock;
            model_information.trainTime = etime(c2,c1);            
            
            c1 = clock;
            [model_information.projectedTrain, model_information.predictedTrain] = obj.test( auxTrain,model,classes );
            [model_information.projectedTest, model_information.predictedTest] = obj.test( auxTest,model,classes );
            c2 = clock;
            model_information.testTime = etime(c2,c1);
            
            model.algorithm = 'SVR';
            model.parameters = param;
            %model_information.projection = model.SVs' * model.sv_coef;
            model_information.model = model;
            
            rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the SVR algorithm.
        % Type: It returns the model
        % Arguments: 
        %           train --> Train struct
        %           parameters--> struct with the parameter information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function model = train(obj,train, parameters)
            
            svrParameters = ...
                ['-s 3 -t 2 -c ' num2str(parameters.C) ' -p ' num2str(parameters.e) ' -g '  num2str(parameters.k) ' -q'];
            
            weights = ones(size(train.targets));
            model = svmtrain(weights, train.targets, train.patterns, svrParameters);
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test a model given in
        %               a set of test patterns.
        % Outputs: Two arrays (projected patterns and predicted targets)
        % Arguments: 
        %           test --> Test struct data
        %           model --> struct with the model information
	%	    classes --> set of labels
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [projected, predicted]= test(obj, test, model,classes)
            
            [projected err] = svmpredict(test.targets, test.patterns, model);
            
            pertenencia_clase = repmat(projected, 1,numel(classes));
            pertenencia_clase = abs(pertenencia_clase -  ones(size(pertenencia_clase,1),1)*classes);
            
            [m,predicted]=min(pertenencia_clase,[],2);
            
        end
        
    end
    
    
end


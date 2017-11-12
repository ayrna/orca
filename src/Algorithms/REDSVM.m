%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for the REDSVM method.
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

classdef REDSVM < Algorithm
    % REDSVM Reduction from ordinal regression to binary SVM classifiers. 
    %	The configuration used is the identity coding matrix, the absolute
    %    cost matrix and the standard binary soft-margin SVM.
    %   This class derives from the Algorithm Class and implements the
    %   REDSVM method. 
    % Further details in: * P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero, 
    %                       F. Fernández-Navarro and C. Hervás-Martínez (2015), 
    %                       "Ordinal regression methods: survey and
    %                       experimental study",  
    %                       IEEE Transactions on Knowledge and Data
    %                       Engineering. Vol. Accepted 
    %                     * H.-T. Lin and L. Li, “Reduction from
    %                       cost-sensitive ordinal ranking to weighted
    %                       binary classification,” Neural Computation,
    %                       vol. 24, no. 5, pp. 1329–1367, 2012.    
    % Dependencies: this class uses
    % - libsvm-rank-2.81 implementation http://www.work.caltech.edu/~htlin/program/libsvm/
    
    properties

        parameters;

        name_parameters = {'C','k'};
    end
    
    methods
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: REDSVM (Public Constructor)
        % Description: It constructs an object of the class
        %               REDSVM and sets its characteristics.
        % Type: Void
        % Arguments: 
        %           kernel--> Type of Kernel function
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = REDSVM(kernel)
            obj.name = 'Reduction from OR to weighted binary classification (SVM)';
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
            obj.parameters.C = 10.^(-3:1:3);
	    % kernel width
            obj.parameters.k = 10.^(-3:1:3);
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
            	addpath(fullfile('Algorithms','libsvm-rank-2.81','matlab'));
                param.C = parameters(1);
                param.k = parameters(2);
                
                c1 = clock;
                model = obj.train(train,param);
                c2 = clock;
                model_information.trainTime = etime(c2,c1);
                
                c1 = clock;
                [model_information.projectedTrain,model_information.predictedTrain] = obj.test(train,model);
                [model_information.projectedTest,model_information.predictedTest] = obj.test(test,model);
                c2 = clock;
                model_information.testTime = etime(c2,c1);

                model.algorithm = 'REDSVM';
                model.parameters = param;
                model_information.model = model;

            	rmpath(fullfile('Algorithms','libsvm-rank-2.81','matlab'));

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the REDSVM algorithm.
        % Type: It returns the model
        % Arguments: 
        %           train --> train struct data
        %           parameters --> struct with the parameter information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [model]= train( obj, train , param)
            options = ['-s 5 -t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
            model = svmtrain(train.targets, train.patterns, options);

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
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [projected, testTargets]= test(obj,test, model)
                [testTargets, acc, projected] = svmpredict(test.targets,test.patterns,model, '');

        end      
    end
end

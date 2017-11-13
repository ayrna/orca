%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for the SVORIMLin method.
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

classdef SVORLin < Algorithm
    % SVOR Linear Support Vector for Ordinal Regression (Implicit constraints)
    %   This class derives from the Algorithm Class and implements the
    %   linear SVORIM method.
    % Further details in: * P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero, 
    %                       F. Fernández-Navarro and C. Hervás-Martínez (2015), 
    %                       "Ordinal regression methods: survey and
    %                       experimental study",  
    %                       IEEE Transactions on Knowledge and Data
    %                       Engineering. Vol. Accepted 
    %                     * W. Chu and S. S. Keerthi, “Support Vector
    %                       Ordinal Regression,” Neural Computation, vol.
    %                       19, no. 3, pp. 792–815, 2007.   
    % Dependencies: this class uses
    % - svorim implementation: http://www.gatsby.ucl.ac.uk/~chuwei/svor.htm
    
    properties
        
        parameters;

        name_parameters = {'C'};
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: SVORIM (Public Constructor)
        % Description: It constructs an object of the class
        %               SVORIMLin and sets its characteristics.
        % Type: Void
        % Arguments:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = SVORLin()
            obj.name = 'Support Vector for Ordinal Regression (Implicit constraints / Linear)';

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
            obj.parameters.C =  10.^(-3:1:3);
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
            addpath(fullfile('Algorithms','SVORIM'));
            param.C = parameters(1);
            
            c1 = clock;
            [model,model_information.projectedTest,model_information.projectedTrain, model_information.trainTime, model_information.testTime] = obj.train([train.patterns train.targets],[test.patterns test.targets],param);

            c2 = clock;
            model_information.trainTime = etime(c2,c1);

            c1 = clock; 
            model_information.predictedTrain = obj.test(model_information.projectedTrain, model);
            model_information.predictedTest = obj.test(model_information.projectedTest, model);
            c2 = clock;
            model_information.testTime = etime(c2,c1);
            model_information.model = model;
            rmpath(fullfile('Algorithms','SVORIM'));
        end
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the SVORIMLin algorithm.
        % Type: It returns the model, the projected test patterns,
	%	the projected train patterns and the time information.
        % Arguments: 
        %           train --> Train struct
	%	    test --> Test struct
        %           parameters--> struct with the parameter information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [model, projectedTest, projectedTrain, trainTime, testTime] = train(obj, train,test, parameters)
            
                 [projectedTest, alpha, thresholds, projectedTrain, trainTime, testTime] = svorim(train,test,1,parameters.C,0,0,1);
                  model.projection = alpha;
                  model.thresholds = thresholds; 
                  model.parameters = parameters;
                  model.algorithm = 'SVORLin';
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test a model given in
        %               a set of test patterns.
        % Outputs: Array of predicted patterns
        % Arguments: 
        %           project --> projected patterns
        %           model --> struct with the model information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [targets] = test(obj, project, model)
            
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


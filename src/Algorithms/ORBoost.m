%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for the ORBoost method.
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

classdef ORBoost < Algorithm    
    %ORBoost Boosting ensemble for Ordinal Regression
    %   This class derives from the Algorithm Class and implements the
    %   ORBoost method. 
    % Further details in: * P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero, 
    %                       F. Fernández-Navarro and C. Hervás-Martínez (2015), 
    %                       "Ordinal regression methods: survey and
    %                       experimental study",  
    %                       IEEE Transactions on Knowledge and Data
    %                       Engineering. Vol. Accepted 
    %                     * H.-T. Lin and L. Li, “Large-margin thresholded
    %                       ensembles for ordinal regression: Theory and
    %                       practice,” in Proc. of the 17th Algorithmic
    %                       Learning Theory International Conference, ser.
    %                       Lecture Notes in Artificial Intelligence
    %                       (LNAI), J. L. Balcazar, P. M. Long, and F.
    %                       Stephan, Eds., vol. 4264. Springer-Verlag,
    %                       October 2006, pp. 319–333.       
    % Dependencies: this class uses
    % - orensemble implementation http://www.work.caltech.edu/~htlin/program/orensemble/
    
    properties
      
        parameters = [];
        
	name_parameters = {};

        weights = true;
    end
    
    methods
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: ORBoost (Public Constructor)
        % Description: It constructs an object of the class
        %               ORBoost and sets its characteristics.
        % Type: Void
        % Arguments: 
	    %		-No arguments	
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = ORBoost()
            obj.name = 'OR Ensemble with perceptrons';
            
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
            obj.parameters = [];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runAlgorithm (Public)
        % Description: This function runs the corresponding
        %               algorithm, fitting the model, and 
        %               testing it in a dataset. It also 
        %               calculates some statistics as CCR,
        %               Confusion Matrix, and others. 
        % Type: It returns a set of statistics (Struct) 
        % Arguments: 
        %           Train --> Trainning data for fitting the model
        %           Test --> Test data for validation
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [model_information] = runAlgorithm(obj,train, test)
                trainFile = tempname();
                dlmwrite(trainFile,[train.patterns train.targets],'delimiter',' ','precision',10);
                testFile = tempname();
                dlmwrite(testFile,[test.patterns test.targets],'delimiter',' ','precision',10);
                modelFile = tempname();
                
                c1 = clock;
                obj.train( train,trainFile, modelFile);
                c2 = clock;
                model_information.trainTime = etime(c2,c1);
                c1 = clock;
                [model_information.projectedTrain,model_information.predictedTrain] = obj.test(train,trainFile,modelFile);
                [model_information.projectedTest,model_information.predictedTest] = obj.test(test,testFile,modelFile);
                c2 = clock;
                model_information.testTime = etime(c2,c1);
                
                fid = fopen(modelFile);
                if ~(exist ("OCTAVE_VERSION", "builtin") > 0) && verLessThan('matlab','8.4')
                    s = textscan(fid,'%s','Delimiter','\n','bufsize', 2^18-1);
                else
                    s = textscan(fid,'%s','Delimiter','\n');
                end
                
                s = s{1};
                fclose(fid);
                
                model.algorithm = 'OREnsemble';
                model.textInformation = s;
                model.weights = obj.weights;
                model_information.model = model;
                
                system(['rm ' trainFile]);
                system(['rm ' testFile]);
                system(['rm ' modelFile]);
                 

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the ORBoost algorithm.
        % Type: void
        % Arguments: 
        %           train --> Train struct
	%	    trainFile --> Path to the training file
        %           modelFile--> Path to the file where the model is to be saved
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        
        function train( obj,train,trainFile, modelFile )
            execute_train = sprintf('./Algorithms/orensemble/hack.sh ./Algorithms/orensemble/boostrank-train %s %d %d %d1 204 %d 2000 %s',trainFile,size(train.patterns,1),size(train.patterns,2),(3+obj.weights),max(unique(train.targets)),modelFile);
            system(execute_train);
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test a model given in
        %               a set of test patterns.
        % Outputs: Two arrays (projected patterns and predicted targets)
        % Arguments: 
        %           test --> Test struct
	%	    testFile --> Path to the test file
        %           modelFile--> Path to the file where the model is to be saved
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [projected, testTargets]= test( obj,test,testFile,modelFile )
                predictFile = tempname();
                execute_test = sprintf('./Algorithms/orensemble/hack.sh ./Algorithms/orensemble/boostrank-predict %s %d %d %s 2000 %s',testFile,size(test.patterns,1),size(test.patterns,2),modelFile,predictFile);

                system(execute_test);
                all = load(predictFile);
                testTargets = all(:,1);
                projected = all(:,2);
                system(['rm ' predictFile]);
                

        end  
            
    end
end

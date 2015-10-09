%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for the SVMOP method.
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

classdef SVMOP < Algorithm
    % SVMOP Support vector machines using Frank & Hall method for ordinal
    % regression (by binary decomposition)
    %   This class derives from the Algorithm Class and implements the
    %   SVMOP method.
    % Further details in: * P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero, 
    %                       F. Fernández-Navarro and C. Hervás-Martínez (2015), 
    %                       "Ordinal regression methods: survey and
    %                       experimental study",  
    %                       IEEE Transactions on Knowledge and Data
    %                       Engineering. Vol. Accepted 
    %                     * E. Frank and M. Hall, “A simple approach to
    %                       ordinal classification,” in Proceedings of the
    %                       12th European Conference on Machine Learning,
    %                       ser. EMCL ’01. London, UK: Springer-Verlag,
    %                       2001, pp. 145–156.    
    %                     * W. Waegeman and L. Boullart, “An ensemble of
    %                       weighted support vector machines for ordinal
    %                       regression,” International Journal of Computer
    %                       Systems Science and Engineering, vol. 3, no. 1,
    %                       pp. 47–51, 2009.    
    % Dependencies: this class uses
    % - libsvm-weights-3.12 for SVM training: https://www.csie.ntu.edu.tw/~cjlin/libsvm
    
    properties

        name_parameters = {'C','k'}

        parameters

        weights = true;
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: SVMOP (Public Constructor)
        % Description: It constructs an object of the class
        %               SVMOP and sets its characteristics.
        % Type: Void
        % Arguments:
        %           kernel--> Type of Kernel function
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = SVMOP(kernel)
            obj.name = 'Frank Hall Support Vector Machines';
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
            addpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
            
            param.C = parameters(1);
            param.k = parameters(2);
            
            
            c1 = clock;
            classes = unique(train.targets);
            nOfClasses = numel(classes);
            [models] = obj.train(train,nOfClasses,param);
            c2 = clock;
            model_information.trainTime = etime(c2,c1);
            
            c1 = clock;
            % Probabilities are included as ProjectedTrain and
            % ProjectedTest
            [model_information.projectedTrain,model_information.predictedTrain] = obj.test(train,models,nOfClasses);
            [model_information.projectedTest,model_information.predictedTest] = obj.test(test,models,nOfClasses);
            c2 = clock;
            model_information.testTime = etime(c2,c1);
            
            model.models=models;
            model.algorithm = 'SVMOP';
            model.parameters = param;
            model.weights = obj.weights;
            model_information.model = model;
            
            rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
        end
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the SVMOP algorithm.
        % Type: It returns the model (struct)
        % Arguments: 
        %           train --> Train struct
	%	    nOfClasses --> number of classes for the dataset
        %           parameters --> struct with the parameter information
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [models]= train( obj,train,nOfClasses,parameters)
            
            patrones = train.patterns(train.targets==1,:);
            etiq = train.targets(train.targets == 1);
            
            for i = 2:nOfClasses,
                patrones = [patrones ; train.patterns(train.targets==i,:)];
                etiq = [etiq ; train.targets(train.targets == i)];
            end
            
            train.targets = etiq;
            train.patterns = patrones';
            
            models = cell(1, nOfClasses-1);
            for i = 2:nOfClasses,
                
                etiquetas_train = [ ones(size(train.targets(train.targets<i))) ;  ones(size(train.targets(train.targets>=i)))*2];
                
                % Train
                options = ['-b 1 -t 2 -c ' num2str(parameters.C) ' -g ' num2str(parameters.k) ' -q'];
                if obj.weights,
                    weightsTrain = obj.computeWeights(i-1,train.targets);
                else
                    weightsTrain = ones(size(train.targets));
                end
                models{i} = svmtrain(weightsTrain, etiquetas_train, train.patterns', options);
                if(numel(models{i}.SVs)==0)
                    disp('Something went wrong. Please check the training patterns.')
                end
            end
            
            
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test a model given in
        %               a set of test patterns.
        % Outputs: Two arrays (probabilities and predicted targets)
        % Arguments: 
        %           test --> Test struct data
        %           models --> struct with the models
	%	    nOfClasses --> number of classes for the dataset
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [probTest,clasetest] = test(obj,test,models,nOfClasses)
            probTest = zeros(nOfClasses, size(test.patterns,1));
            for i = 2:nOfClasses,
                etiquetas_test = [ ones(size(test.targets(test.targets<i))) ;  ones(size(test.targets(test.targets>=i)))*2];
                [pr, acc, probTs] = svmpredict(etiquetas_test,test.patterns,models{i},'-b 1');

                probTest(i-1,:) = probTs(:,2)';
            end
            probts(1,:) = ones(size(probTest(1,:))) - probTest(1,:);
            for i=2:nOfClasses,
                probts(i,:) =  probTest(i-1,:) -  probTest(i,:);
            end
            probts(nOfClasses,:) =  probTest(nOfClasses-1,:);
            [aux, clasetest] = max(probts);
            clasetest = clasetest';
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: computeWeights (Public)
        % Description: compute the weights to apply to the set of training patterns
        % Outputs: array with the weigths 
        % Arguments: 
        %           p --> scalar corresponding to the indexes 
	%	          of the classes being considered 
	%		(all classes whose index is lower or equal than p)	
	%	    targets --> training targets
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [weights] = computeWeights(obj, p, targets)
            weights = ones(size(targets));
            weights(targets<=p) = (p+1-targets(targets<=p)) * size(targets(targets<=p),1) / sum(p+1-targets(targets<=p));
            weights(targets>p) = (targets(targets>p)-p) * size(targets(targets>p),1) / sum(targets(targets>p)-p);
        end
        
    end
    
end


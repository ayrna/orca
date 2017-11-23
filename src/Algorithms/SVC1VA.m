%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for the SVC (one-versus-all approach) method.
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

classdef SVC1VA < Algorithm
    %SVC1VA Support Vector Classifier using 1VsAll approach
    %   This class derives from the Algorithm Class and implements the
    %   SVC1VA method.
    % Further details in: * P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
    %                       F. Fernández-Navarro and C. Hervás-Martínez (2015),
    %                       "Ordinal regression methods: survey and
    %                       experimental study",
    %                       IEEE Transactions on Knowledge and Data
    %                       Engineering. Vol. Accepted
    %                     * C.-W. Hsu and C.-J. Lin, “A comparison of
    %                       methods for multi-class support vector
    %                       machines,” IEEE Transaction on Neural Networks,
    %                       vol. 13, no. 2, pp. 415–425, 2002.
    % Dependencies: this class uses
    % - libsvm-weights-3.12 for SVM training: https://www.csie.ntu.edu.tw/~cjlin/libsvm
    
    properties
        
        name_parameters = {'C','k'};
        
        parameters;
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: SVC1VA (Public Constructor)
        % Description: It constructs an object of the class
        %               SVC1VA and sets its characteristics.
        % Type: Void
        % Arguments:
        %           kernel--> Type of Kernel function
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = SVC1VA(kernel)
            obj.name = 'Support Vector Machine Classifier with 1vsAll paradigm';
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
            model = obj.train(train, param);
            c2 = clock;
            model_information.trainTime = etime(c2,c1);
            
            c1 = clock;
            [model_information.projectedTrain, model_information.predictedTrain] = obj.test(train,model);
            [model_information.projectedTest,model_information.predictedTest ] = obj.test(test,model);
            c2 = clock;
            model_information.testTime = etime(c2,c1);
            
            model.algorithm = 'SVC1VA';
            model.parameters = param;
            model_information.model = model;
            
            rmpath(fullfile('Algorithms','libsvm-weights-3.12','matlab'));
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the SVC1vA algorithm.
        % Type: It returns the model
        % Arguments:
        %           train --> Train struct
        %           param--> struct with the parameter information
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [model]= train( obj, train, param)
            options = ['-t 2 -c ' num2str(param.C) ' -g ' num2str(param.k) ' -q'];
            
            labelSet = unique(train.targets);
            labelSetSize = length(labelSet);
            models = cell(labelSetSize,1);
            
            for i=1:labelSetSize
                labels = double(train.targets == labelSet(i));
                weights = ones(size(labels));
                models{i} = svmtrain(weights,labels, train.patterns, options);
            end
            
            model = struct('models', {models}, 'labelSet', labelSet);
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test a model given in
        %               a set of test patterns.
        % Outputs: Two arrays (decision values and predicted targets)
        % Arguments:
        %           test --> Test struct data
        %           model --> struct with the model information
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [decv, pred]= test(obj, test, model)
            
            labelSet = model.labelSet;
            labelSetSize = length(labelSet);
            models = model.models;
            decv= zeros(size(test.targets, 1), labelSetSize);
            
            for i=1:labelSetSize
                labels = double(test.targets == labelSet(i));
                [l,a,d] = svmpredict(labels, test.patterns, models{i});
                decv(:, i) = d * (2 * models{i}.Label(1) - 1);
            end
            
            [tmp,pred] = max(decv, [], 2);
            pred = labelSet(pred);
            
        end
    end
end

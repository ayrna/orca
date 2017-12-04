classdef Algorithm < handle
    %ALGORITHM abstract interface class. Abstract class which defines the
    %settings for the algorithms (common methods and variables).
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        kernelType = 'rbf';
        name
    end
    
    methods
        function name = getName(obj)
            %GETNAME returns the name of the implemented algorithm.
            name = obj.name;
        end
        
        function mInf = runAlgorithm(obj,train, test, parameters)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter 
            %   values for the method. Test the generalization performance 
            %   with TRAIN and TEST data and returns predictions and model
            %   in mInf structure. 
            nParam = numel(obj.name_parameters);
            if nParam~= 0
                parameters = reshape(parameters,[1,nParam]);
                param = cell2struct(num2cell(parameters(1:nParam)),obj.name_parameters,2);
            else
                param = [];
            end
            
            c1 = clock;
            [model,mInf.projectedTrain, mInf.predictedTrain] = obj.train(train,param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            [mInf.projectedTest, mInf.predictedTest] = obj.test(test.patterns, model);
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            mInf.model = model; 
        end
    end
    
    %    methods(Abstract)
    %
    %        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        %
    %        % Function: runAlgorithm(Public)
    %        % Description: function to run the algorithm (train and test partitions)
    %        % Type: Void
    %        % Arguments:
    %        %           No arguments
    %        %
    %        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %        runAlgorithm(obj);
    %
    %        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        %
    %        % Function: defaultParameters(Public)
    %        % Description: function for setting the default parameters
    %        % Type: Void
    %        % Arguments:
    %        %           No arguments
    %        %
    %        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %        defaultParameters(obj);
    %
    %        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        %
    %        % Function: train(Public)
    %        % Description: function for training the model
    %        % Type: Void
    %        % Arguments:
    %        %           No arguments
    %        %
    %        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %        train(obj);
    %
    %        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        %
    %        % Function: test(Public)
    %        % Description: function for testing the model
    %        % Type: Void
    %        % Arguments:
    %        %           No arguments
    %        %
    %        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %        test(obj);
    %    end
    
    
end



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
        name
    end
    
    methods
        function name = getName(obj)
            %GETNAME returns the name of the implemented algorithm.
            name = obj.name;
        end
        
        function name_parameters = getParameterNames(obj)
            if ~isempty(obj.parameters)
                name_parameters = sort(fieldnames(obj.parameters));
            else
                name_parameters = [];
            end
        end
        
        function mInf = runAlgorithm(obj,train, test, param)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter
            %   structure of values for the method. It tests the
            %   generalization performance with TRAIN and TEST data and
            %   returns predictions and model in mInf structure.
            c1 = clock;
            [model,mInf.projectedTrain, mInf.predictedTrain] = obj.fit(train,param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            [mInf.projectedTest, mInf.predictedTest] = obj.predict(test.patterns, model);
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            mInf.model = model;
        end
        
        % Abstract methods: they have been implemented in this way to
        % ensure compatibility with Octave. An error is thrown if the method
        % is not implemented in child class.
        
        function [model, projectedTrain, predictedTrain] = fit( obj,train,param)
            %FIT trains the model for the Algorithm method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            error('train method should be implemented in all subclasses');
        end
        
        function [projected, predicted]= predict(obj,test,model)
            %PREDICT predicts labels of TEST patterns labels using MODEL.
            error('test method should be implemented in all subclasses');
        end
        
    end
    
end



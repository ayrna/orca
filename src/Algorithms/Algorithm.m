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
        model = [];
    end
    methods
        
        function name_parameters = getParameterNames(obj)
            if ~isempty(obj.parameters)
                name_parameters = sort(fieldnames(obj.parameters));
            else
                name_parameters = [];
            end
        end
        
        %TODO Document
        function parseArgs(obj,varargin)
            %PARSEARGS(VARARGIN) parses a pair of keys-values in matlab
            %style format. It throws different exceptions if the field does
            %not exits on the class or if the type assignement is not consistent.
            if ~isempty(varargin) && ~isempty(varargin{1})
                while iscell(varargin{1})
                    varargin = varargin{1};
                    if isempty(varargin{1})
                        return
                    end
                end
                
                %# read the acceptable names
                optionNames = fieldnames(obj);
                
                %# count arguments
                nArgs = length(varargin);
                if mod(nArgs,2)
                    error('parseParArgs needs propertyName/propertyValue pairs')
                end
                
                for pair = reshape(varargin,2,[]) % pair is {propName;propValue}
                    inpName = pair{1}; % make case insensitive
                    
                    if any(strcmp(inpName,optionNames))
                        % overwrite properties.
                        % check type
                        if strcmp(class(obj.(inpName)), class(pair{2}))
                            obj.(inpName) = pair{2};
                        else
                            % Check boolean
                            if islogical(obj.(inpName)) && ...
                                    (strcmp(pair{2},'true') || strcmp(pair{2},'false'))
                                obj.(inpName) = eval(pair{2});
                            else
                                msg = sprintf('Data type of property ''%s'' (%s) not compatible with data type (%s) of assigned value in configuration file', ...
                                    inpName, class(obj.(inpName)), class(pair{2}));
                                error(msg);
                            end
                        end
                    else
                        error('Error ''%s'' is not a recognized class property name',inpName)
                    end
                end
            end
        end
        
        function setParam(obj,param)
            %SETPARAM(PARAM) set parameters contained in param and keep default
            %values of class parameters field. It throws different exceptions if
            %the field does not exits on the class or if the type assignement is not consistent.
            %paramNames = fieldnames(obj.parameters);
            paramNames = fieldnames(param);
            
            for i = 1:length(paramNames)
                inpName = paramNames{i};
                if isfield(obj.parameters,inpName)
                    % check type
                    if strcmp(class(obj.parameters.(inpName)), class(param.(inpName)))
                        obj.parameters.(inpName) = param.(inpName);
                    else
                        % Check boolean
                        if islogical(obj.parameters.(inpName)) && ...
                                (strcmp(param.(inpName),'true') || strcmp(param.(inpName),'false'))
                            obj.parameters.(inpName) = eval(pair{2});
                        else
                            msg = sprintf('Data type of property ''%s'' (%s) not compatible with data type (%s) of assigned value in configuration file', ...
                                inpName, class(obj.parameters.(inpName)), class(param.(inpName)));
                            error(msg);
                        end
                    end
                else
                    error('Error ''%s'' is not a recognized class parameter name',inpName)
                end
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
            if nargin == 3
                param = [];
            else
                % Mix parameters with default
                obj.setParam(param)
            end
            param = obj.parameters;
            
            c1 = clock;
            [mInf.projectedTrain, mInf.predictedTrain] = obj.fit(train,param);
            % Save the model type
            obj.model.algorithm = class(obj);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            c1 = clock;
            [mInf.projectedTest, mInf.predictedTest] = obj.predict(test.patterns);
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            mInf.model = obj.model;
        end
        
        function [projectedTrain, predictedTrain] = fit( obj,train,param)
            if nargin < 3
                param = [];
                if nargin < 2
                    error('Please provide training data')
                end
            end
            if ~all(isfield(train, {'patterns','targets'}))
                error('Please provide a structure with train patterns and targets')
            end
            % check that dimensions agree
            if ~size(train.patterns,1) == size(train.targets,1)
                error('Number of train patterns and targets must agree')
            end
            
            [projectedTrain, predictedTrain] = obj.privfit(train, param);
        end

        function [projected, predicted]= predict(obj,test)
            % Check if there is a model
            if isempty(obj.model)
                error('The object does not have a fitted model')
            end
            % Avoid typicall error os passing a structure containing labels
            if ~isa(test,'double')
                error('test parameter has to be a matrix')
            end
            [projected, predicted]= privpredict(obj,test);
        end
        
        %TODO: Update DOC
        % Abstract methods: they have been implemented in this way to
        % ensure compatibility with Octave. An error is thrown if the method
        % is not implemented in child class.
        
        function [projectedTrain, predictedTrain] = privfit( obj,train,param)
            %FIT trains the model for the Algorithm method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            error('train method should be implemented in all subclasses');
        end
        
        function [projected, predicted]= privpredict(obj,test)
            %PREDICT predicts labels of TEST patterns labels using fitted MODEL.
            error('test method should be implemented in all subclasses');
        end
        
    end
    
end

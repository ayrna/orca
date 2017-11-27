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



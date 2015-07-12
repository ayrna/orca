classdef Algorithm < handle
    % Algorithm Abstract interface class
    % Abstract class which defines Machine Learning algorithms.
    % It describes some common methods and variables for all the
    % algorithMs.
    
    properties
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: kernelType (Public)
        % Type: String
        % Description: It specifies the kernel function
        %               used by the algorithm. Possible
        %               values are: 'no', 'rbf',
        %               'sigmoid', 'linear' or 'poly'
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        kernelType = 'rbf'
        name
        
    end
    
    %     properties(Access = protected)
    %
    %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %         %
    %         % Variable: name (Protected)
    %         % Type: String
    %         % Description: This variables contains the name
    %         %              of the implemented algorithm
    %         %
    %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %         name
    %
    %     end
    
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: set.kernelType (Public)
        % Description: It verifies if the value for the
        %               variable kernelType is correct.
        % Type: Void
        % Arguments:
        %           value--> Value for the variable kernelType.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
%         function obj = set.kernelType(obj, value)
%             if ~(strcmpi(value,'no') || strcmpi(value,'rbf') || strcmpi(value,'sigmoid') || strcmpi(value,'poly') || strcmpi(value,'lin'))
%                 error('Invalid value for Kernel type ');
%             else
%                 obj.kernelType = value;
%             end
%         end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: getName (Public)
        % Description: It returns the name of the implemented
        %               algorithm.
        % Type: String
        % Arguments:
        %           No arguments
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function name = getName(obj)
            name = obj.name;
        end
        
    end
    
    
    methods(Abstract)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runAlgorithm(Public)
        % Description: This function is not implemented,
        %                   since it will be designed by
        %                   the derivated class.
        % Type: Void
        % Arguments:
        %           No arguments
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        runAlgorithm(obj);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: defaultParameters(Public)
        % Description: This function is not implemented,
        %                   since it will be designed by
        %                   the derivated class.
        % Type: Void
        % Arguments:
        %           No arguments
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        defaultParameters(obj);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train(Public)
        % Description: This function is not implemented,
        %                   since it will be designed by
        %                   the derivated class.
        % Type: Void
        % Arguments:
        %           No arguments
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        train(obj);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test(Public)
        % Description: This function is not implemented,
        %                   since it will be designed by
        %                   the derivated class.
        % Type: Void
        % Arguments:
        %           No arguments
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        test(obj);
    end
    
    
end



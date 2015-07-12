classdef Metric < handle
    % Metric Abstract interface class
    
    properties
	
	name = ''
        
    end
    
    
    methods(Abstract)
            calculateMetric()
    end
            
    
end



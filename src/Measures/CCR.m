classdef CCR < Metric 

    methods
        function obj = CCR()
                obj.name = 'Correct Classification Rate';
        end
    end
    
    methods(Static = true)
	    
        function ccr = calculateMetric(argum1,argum2)
            if nargin == 2,
                ccr = sum(argum1==argum2)/numel(argum1);
            else
                ccr = sum(diag(argum1)) / sum(sum(argum1));
            end
        end

	function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = 1 - sum(argum1==argum2)/numel(argum1);
            else
                value = 1 - sum(diag(argum1)) / sum(sum(argum1));
            end
        end
        
    end
            
    
end


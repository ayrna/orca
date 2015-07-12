classdef MZE < Metric

    methods
        function obj = MZE()
                obj.name = 'Mean Zero Error';
        end
    end
    
    methods(Static = true)
	    
        function ccr = calculateMetric(argum1,argum2)
            if nargin == 2,
                ccr = 1 - (sum(argum1==argum2)/numel(argum1));
            else
                ccr = 1 - sum(diag(cm)) / sum(sum(cm));
            end
        end

	function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = MZE.calculateMetric(argum1,argum2);
            else
                value = MZE.calculateMetric(argum1);
            end
    end
    end
end
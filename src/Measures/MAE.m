classdef MAE < Metric

    methods
        function obj = MAE()
                obj.name = 'Mean Absolute Error';
        end
        
        
    end
    
    methods(Static = true)
	    
        function mae = calculateMetric(argum1,argum2)
            if nargin == 2,
                    mae = sum(abs(argum1 - argum2))/numel(argum1);
            else
                    n=size(argum1,1);
                    cm = double(argum1);
                    cost = abs(repmat(1:n,n,1) - repmat((1:n)',1,n));
                    mae = sum(sum(cost.*cm)) / sum(sum(cm));
            end
        end
        
        function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = MAE.calculateMetric(argum1,argum2);
            else
                value = MAE.calculateMetric(argum1);
            end
        end

	
        
    end
            
    
end

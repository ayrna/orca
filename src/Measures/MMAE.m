classdef MMAE < Metric

    methods
        function obj = MMAE()
                obj.name = 'Max Mean Absolute Error';
        end
    end
    
    methods(Static = true)
	    
        function maxmae = calculateMetric(argum1,argum2)
            if nargin == 2,
                argum1 = confusionmat(argum1,argum2);
            end
                n=size(argum1,1);
                cm = double(argum1);
                cost = abs(repmat(1:n,n,1) - repmat((1:n)',1,n));
                mae = zeros(n:1);
                cmt = cm';
                for i=0:n-1
                    mae(i+1) = sum(cost(1+(i*n):(i*n)+n).*cmt(1+(i*n):(i*n)+n)) / sum(cmt(1+(i*n):(i*n)+n));
                end
                maxmae = max(mae);
        end

	function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = MMAE.calculateMetric(argum1,argum2);
            else
                value = MMAE.calculateMetric(argum1);
            end
        end
        
    end
            
    
end

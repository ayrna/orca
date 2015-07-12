classdef AMAE < Metric

    methods
        function obj = AMAE()
                obj.name = 'Average Mean Absolute Error';
        end
    end
    
    methods(Static = true)
	    
        function amae = calculateMetric(argum1,argum2)
            if nargin == 2,
                argum1 = confusionmat(argum1,argum2);
            end
            n=size(argum1,1);
            argum1 = double(argum1);
            cost = abs(repmat(1:n,n,1) - repmat((1:n)',1,n));
            mae = zeros(n:1);
            cmt = argum1';
            for i=0:n-1
                mae(i+1) = sum(cost(1+(i*n):(i*n)+n).*cmt(1+(i*n):(i*n)+n)) / sum(cmt(1+(i*n):(i*n)+n));
            end
            amae = nanmean(mae);
        end

	function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = AMAE.calculateMetric(argum1,argum2);
            else
                value = AMAE.calculateMetric(argum1);
            end
        end
        
    end
            
    
end

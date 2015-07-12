classdef MCCR < Metric

    methods
        function obj = MCCR()
                obj.name = 'MeanCCR';
        end
    end
    
    methods(Static = true)
	    
        function meanccr = calculateMetric(argum1,argum2)
            if nargin == 2,
                argum1 = confusionmat(argum1,argum2);
            end
            ccr_class = zeros(size(argum1,1),1);
            n = sum(argum1,2);
            for i=1:size(argum1,1),
                if(n(i)~=0)
                    ccr_class(i) = argum1(i,i)/n(i);
                end
            end
            meanccr = mean(ccr_class,1);

        end


	function value = calculateCrossvalMetric(argum1,argum2)
                value = 1 - MCCR.calculateMetric(argum1,argum2);
        end
        
    end
            
    
end


classdef ClassCCR < Metric

    methods
        function obj = ClassCCR()
                obj.name = 'CCR per Class';
        end
    end
    
    methods(Static = true)
	    
        function ccr_class = calculateMetric(argum1,argum2)
            if nargin == 2,
                argum1 = confusionmat(argum1,argum2);
            end
            ccr_class = zeros(size(argum1,1),1);
            n = sum(argum1,2);
            for i=1:size(argum1,1),
                ccr_class(i) = argum1(i,i)/n(i);
            end
        end
        
    end
            
    
end


classdef MS < Metric

    methods
        function obj = MS()
                obj.name = 'Minimum Sensitivity';
        end
    end
    
    methods(Static = true)
	    
        function [ms,class] = calculateMetric(argum1,argum2)
            if nargin == 2,
                argum1 = confusionmat(argum1,argum2);
            end
            nC = size(argum1,1);
            ms = 1;

            for ii=1:nC
                accuracyC = argum1(ii,ii)/sum(argum1(ii,:));

                if accuracyC < ms
                    ms = accuracyC;
                    class = ii;
                end
            end
        end

	function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = 1 - MS.calculateMetric(argum1,argum2);
            else
                value = 1 - MS.calculateMetric(argum1);
            end
        end
        
    end
            
    
end


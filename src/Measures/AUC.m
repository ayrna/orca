classdef AUC < Metric

    methods
        function obj = AUC()
                obj.name = 'Area under curve';
        end
    end
    
    methods(Static = true)
	    
        function auc = calculateMetric(truelabels,decisionvalues)
	    if any(~isnan(decisionvalues))
		    if min(truelabels) ~= max(truelabels)
		        if numel(truelabels) ~= numel(decisionvalues)
		            if(size(decisionvalues,1) == numel(truelabels)),
		                decisionvalues = decisionvalues(:,1);
		            else
		                decisionvalues = decisionvalues(1,:); 
		            end
		        end

		        if size(truelabels,1) ~= size(decisionvalues,1)
		            [x,y,th,auc] = perfcurve2(truelabels, decisionvalues', min(truelabels));
		        else
		            [x,y,th,auc] = perfcurve2(truelabels, decisionvalues, min(truelabels));
		        end
		    else
		        auc = 0.5;
		    end
	    else
                auc = 0.5;
	    end
        end

	function value = calculateCrossvalMetric(argum1,argum2)
                value = 1 - AUC.calculateMetric(argum1,argum2);
        end
        
    end
            
    
end

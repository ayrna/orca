classdef Spearman < Metric
 
     methods
         function obj = MZE(obj)
                 obj.name = 'Rho Spearman';
         end
     end
    
    methods(Static = true)
	    
        function spearman = calculateMetric(argum1,argum2)
            
            if nargin < 2,
                [argum1, argum2] = calculaEtiquetasViaCM(argum1);
            end
	
            n = size(argum1,1);
		    num = sum((argum1-repmat(mean(argum1),n,1)).*(argum2-repmat(mean(argum2),n,1)));
		    div= sqrt(sum((argum1-repmat(mean(argum1),n,1)).^2)*sum((argum2-repmat(mean(argum2),n,1)).^2));    
		    if(num == 0)
                spearman = 0;
            else
                spearman = num/div;
    		end

        end

	function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = 1 - Spearman.calculateMetric(argum1,argum2);
            else
                value = 1 - Spearman.calculateMetric(argum1);
            end
        end
        
    end
            
    
end

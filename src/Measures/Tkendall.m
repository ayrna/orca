classdef Tkendall < Metric

    methods
        function obj = Tkendall()
                obj.name = 'Tkendall';
        end
    end
    
    methods(Static = true)
	    
        function tkendall = calculateMetric(argum1,argum2)
            if nargin < 2,
                [ argum1, argum2 ] = calculaEtiquetasViaCM( argum1 );
            end

            [tkendall] = corr(argum1, argum2, 'type', 'Kendall');
	        if isnan(tkendall)
                tkendall = 0;
	        end
   
        end

	function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = 1 - Tkendall.calculateMetric(argum1,argum2) ;
            else
                value = 1 - Tkendall.calculateMetric(argum1);
            end
        end
        
    end
            
    
end

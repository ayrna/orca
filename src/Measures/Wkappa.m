classdef Wkappa < Metric

    methods
        function obj = Wkappa()
                obj.name = 'Weighted Kappa';
        end
    end
    
    methods(Static = true)
	    
        function wkappa = calculateMetric(argum1,argum2)
            if nargin == 2,
                 argum1 = confusionmat(argum1, argum2);
            end
            m=size(argum1,1);
            J=repmat((1:1:m),m,1);
            I=flipud(rot90(J));
            f=1-abs(I-J)./(m-1); %linear weight
            x = argum1;

            n=sum(x(:)); %Sum of Matrix elements
            x=x./n; %proportion
            r=sum(x,2); %rows sum
            s=sum(x); %columns sum
            Ex=r*s; %expected proportion for random agree
            po=sum(sum(x.*f));
            pe=sum(sum(Ex.*f));
            wkappa=(po-pe)/(1-pe);
        end


	function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = 1 - Wkappa.calculateMetric(argum1,argum2);
            else
                value = 1 - Wkappa.calculateMetric(argum1);
            end
        end
        
    end
            
    
end


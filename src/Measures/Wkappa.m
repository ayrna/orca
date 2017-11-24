classdef Wkappa < Metric
    %WKAPPA static class to calculate Weighted Kappa statistic using ordinal weights.
    %
    %   WKAPPA methods:
    %      CALCULATEMETRIC            - Computes the evaluation metric
    %      CALCULATECROSSVALMETRIC    - Computes the evaluation metric as an error
    %
    %   References:
    %     [1] J.L. Fleiss, J. Cohen, B.S. Everitt
    %         Large sample standard errors of kappa and weighted kappa
    %         Psychol. Bull., 72 (5) (1969), pp. 323-327
    %         https://doi.org/10.1037/h0028106
    %     [2] M. Cruz-Ramírez, C. Hervás-Martínez, J. Sánchez-Monedero and
    %         P. A. Gutiérrez Metrics to guide a multi-objective evolutionary
    %         algorithm for ordinal classification, Neurocomputing, Vol. 135, July, 2014, pp. 21-31.
    %         https://doi.org/10.1016/j.neucom.2013.05.058
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    methods
        function obj = Wkappa()
            obj.name = 'Weighted Kappa';
        end
    end
    
    methods(Static = true)
        
        function wkappa = calculateMetric(argum1,argum2)
            %CALCULATEMETRIC Computes the evaluation metric
            %   METRIC = CALCULATEMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATEMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2
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
            %CALCULATECROSSVALMETRIC Computes the evaluation metric and returns
            %it as an error.
            %   METRIC = CALCULATECROSSVALMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATECROSSVALMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            
            if nargin == 2
                value = 1 - Wkappa.calculateMetric(argum1,argum2);
            else
                value = 1 - Wkappa.calculateMetric(argum1);
            end
        end
        
    end
    
    
end


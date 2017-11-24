classdef MMAE < Metric
    %MAE static class to calculate the minimum mean absolute error (MAE) per
    %   class. Values range from 0 to J-1, where J is the number of classes.
    %
    %   MAE methods:
    %      CALCULATEMETRIC            - Computes the evaluation metric
    %      CALCULATECROSSVALMETRIC    - Computes the evaluation metric as an error
    %
    %   References:
    %     [1] M. Cruz-Ramírez, C. Hervás-Martínez, J. Sánchez-Monedero and
    %         P. A. Gutiérrez Metrics to guide a multi-objective evolutionary
    %         algorithm for ordinal classification, Neurocomputing, Vol. 135, July, 2014, pp. 21-31.
    %         https://doi.org/10.1016/j.neucom.2013.05.058
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.htmlml
    methods
        function obj = MMAE()
            obj.name = 'Max Mean Absolute Error';
        end
    end
    
    methods(Static = true)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: calculateMetric (static)
        % Description: Computes the evaluation metric
        % Outputs: metric results
        % Arguments:
        %           argum1--> First argument (confusion matrix or predictions)
        %	    argum2--> Second argument (true labels)
        % 	    If there is only one argument, the results are computed
        %	    using the confusion matrix. In other case, with the
        %	    predictions and true labels.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function maxmae = calculateMetric(argum1,argum2)
            %CALCULATEMETRIC Computes the evaluation metric
            %   METRIC = CALCULATEMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATEMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRE
            if nargin == 2
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
            %CALCULATECROSSVALMETRIC Computes the evaluation metric and returns
            %it as an error.
            %   METRIC = CALCULATECROSSVALMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATECROSSVALMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2
                value = MMAE.calculateMetric(argum1,argum2);
            else
                value = MMAE.calculateMetric(argum1);
            end
        end
        
    end
    
    
end

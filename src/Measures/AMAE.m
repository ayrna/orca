classdef AMAE < Metric
    %AMAE static class to calculate average mean absolute error (MAE). The average
    %   MAE is the mean of the MAE classification errors across classes and was proposed
    %   by Baccianella et al. [1] to mitigate the effect of imbalanced
    %   class distributions. Values range from 0 to J-1, where J is the
    %   number of classes.
    %
    %   AMAE methods:
    %      CALCULATEMETRIC            - Computes the evaluation metric
    %      CALCULATECROSSVALMETRIC    - Computes the evaluation metric as an error
    %
    %   References:
    %     [1] S. Baccianella, A. Esuli, F. Sebastiani,
    %         Evaluation measures for ordinal regression
    %         Proceedings of the Ninth International Conference on Intelligent
    %         Systems Design and Applications, ISDA′09, 2009, pp. 283–287.
    %         https://doi.org/10.1109/ISDA.2009.230
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
        function obj = AMAE()
            obj.name = 'Average Mean Absolute Error';
        end
    end
    
    methods(Static = true)
        
        function amae = calculateMetric(argum1,argum2)
            %CALCULATEMETRIC Computes the evaluation metric
            %   METRIC = CALCULATEMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATEMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2
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
            
            if (exist ('OCTAVE_VERSION', 'builtin') > 0)
              n = sum (~isnan(mae));
              n(n == 0) = NaN;
              mae(isnan(mae)) = 0;
              amae = sum (mae) ./ n;
            else
              amae = nanmean(mae);
            end
        end
        
        function value = calculateCrossvalMetric(argum1,argum2)
            %CALCULATECROSSVALMETRIC Computes the evaluation metric as return it 
            %   expressed as an error metric
            %   METRIC = CALCULATECROSSVALMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATECROSSVALMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2
                value = AMAE.calculateMetric(argum1,argum2);
            else
                value = AMAE.calculateMetric(argum1);
            end
        end
        
    end
    
    
end

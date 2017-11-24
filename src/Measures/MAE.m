classdef MAE < Metric
    %MAE static class to calculate the mean absolute error (MAE). Values range
    %   from 0 to J-1, where J is the number of classes.
    %
    %   MAE methods:
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
        function obj = MAE()
            obj.name = 'Mean Absolute Error';
        end
    end
    
    methods(Static = true)
        
        function mae = calculateMetric(argum1,argum2)
            %CALCULATEMETRIC Computes the evaluation metric
            %   METRIC = CALCULATEMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATEMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2
                mae = sum(abs(argum1 - argum2))/numel(argum1);
            else
                n=size(argum1,1);
                cm = double(argum1);
                cost = abs(repmat(1:n,n,1) - repmat((1:n)',1,n));
                mae = sum(sum(cost.*cm)) / sum(sum(cm));
            end
        end
        
        
        function value = calculateCrossvalMetric(argum1,argum2)
            %CALCULATECROSSVALMETRIC Computes the evaluation metric and returns
            %it as an error.
            %   METRIC = CALCULATECROSSVALMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATECROSSVALMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2,
                value = MAE.calculateMetric(argum1,argum2);
            else
                value = MAE.calculateMetric(argum1);
            end
        end
        
        
        
    end
    
    
end

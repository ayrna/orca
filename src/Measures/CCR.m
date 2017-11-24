classdef CCR < Metric
    %CCR static class to calculate the correct classification rate or accuracy,
    % which is the percentage of correctly classified patterns. Values
    % range from 0 to 1.
    %
    %   CCR methods:
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
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    methods
        function obj = CCR()
            obj.name = 'Correct Classification Rate';
        end
    end
    
    methods(Static = true)
        %CALCULATEMETRIC Computes the evaluation metric
        %   METRIC = CALCULATEMETRIC(CM) returns calculated metric from confussion
        %   matrix CM
        %   METRIC = CALCULATEMETRIC(actual, pred) returns calculated metric from
        %   real labels (ACTUAL) labels and predicted labels (PRED)
        
        function ccr = calculateMetric(argum1,argum2)
            if nargin == 2
                ccr = sum(argum1==argum2)/numel(argum1);
            else
                ccr = sum(diag(argum1)) / sum(sum(argum1));
            end
        end
        
        function value = calculateCrossvalMetric(argum1,argum2)
            %CALCULATECROSSVALMETRIC Computes the evaluation metric and returns
            %it as an error.
            %   METRIC = CALCULATECROSSVALMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATECROSSVALMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2
                value = 1 - sum(argum1==argum2)/numel(argum1);
            else
                value = 1 - sum(diag(argum1)) / sum(sum(argum1));
            end
        end
        
    end
    
    
end


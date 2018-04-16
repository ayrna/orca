classdef Metric < handle
    %METRIC abstract interface class for performance evaluation
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    properties
        name = '';
    end
    
    
    % Abstract methods: they have been implemented in this way to
    % ensure compatibility with Octave. An error is thrown if the method
    % is not implemented in child class.
    
    
    
    methods
        function calculateMetric(argum1,argum2)
            %CALCULATEMETRIC Computes the evaluation metric
            %   METRIC = CALCULATEMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATEMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            error('calculateMetric method should be implemented in all subclasses');
        end
        function value = calculateCrossvalMetric(argum1,argum2)
            %CALCULATECROSSVALMETRIC Computes the evaluation metric 
            %   METRIC = CALCULATEMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATEMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            error('calculateCrossvalMetric method should be implemented in all subclasses');
        end
    end
end

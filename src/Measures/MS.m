classdef MS < Metric
    %MS static class to calculate minimum sensitivity metric. Values range from 0 to 1.
    %
    %   MS methods:
    %      CALCULATEMETRIC            - Computes the evaluation metric
    %      CALCULATECROSSVALMETRIC    - Computes the evaluation metric as an error
    %
    %   References:
    %     [1] J.C. Fernández, F. Martínez, C. Hervás, P.A. Gutiérrez
    %         Sensitivity versus accuracy in multi-class problems using memetic Pareto evolutionary neural networks
    %         IEEE Trans. Neural Netw., 21 (5) (2010), pp. 750-770
    %         https://doi.org/10.1109/TNN.2010.2041468
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
        function obj = MS()
            obj.name = 'Minimum Sensitivity';
        end
    end
    
    methods(Static = true)
        
        function [ms,class] = calculateMetric(argum1,argum2)
            %CALCULATEMETRIC Computes the evaluation metric
            %   METRIC = CALCULATEMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATEMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2
                argum1 = confusionmat(argum1,argum2);
            end
            nC = size(argum1,1);
            ms = 1;
            
            for ii=1:nC
                accuracyC = argum1(ii,ii)/sum(argum1(ii,:));
                
                if accuracyC < ms
                    ms = accuracyC;
                    class = ii;
                end
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
                value = 1 - MS.calculateMetric(argum1,argum2);
            else
                value = 1 - MS.calculateMetric(argum1);
            end
        end
        
    end
    
    
end


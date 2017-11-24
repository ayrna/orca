classdef GM < Metric
    %GM static class to calculate the geometric mean of the sensitivity of
    %each class, this is, the geometric mean of the accuracy for each class.
    %Values range from 0 to 1.
    %
    %   GM methods:
    %      CALCULATEMETRIC            - Computes the evaluation metric
    %      CALCULATECROSSVALMETRIC    - Computes the evaluation metric as an error
    %
    %   References:
    %     [1] Wang, S., & Yao, X. 
    %         Multiclass imbalance problems: Analysis and potential solutions. 
    %         IEEE Transactions on Systems, Man, and Cybernetics, Part B (Cybernetics),
    %         42(4), 2012, pp. 1119-1130.
    %         https://doi.org/10.1109/TSMCB.2012.2187280
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    methods
        function obj = GM()
            obj.name = 'Geometric Mean';
        end
    end
    
    methods(Static = true)
        
        function [gm] = calculateMetric(argum1,argum2)
            %CALCULATEMETRIC Computes the evaluation metric
            %   METRIC = CALCULATEMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATEMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2
                argum1 = confusionmat(argum1,argum2);
            end
            nC = size(argum1,1);
            gm = 1;
            
            for ii=1:nC
                if(sum(argum1(ii,:))~=0)
                    gm = gm*argum1(ii,ii)/sum(argum1(ii,:));
                end
            end
            gm = nthroot(gm,nC);
        end
        
        function value = calculateCrossvalMetric(argum1,argum2)
            %CALCULATECROSSVALMETRIC Computes the evaluation metric and returns
            %it as an error.
            %   METRIC = CALCULATECROSSVALMETRIC(CM) returns calculated metric from confussion
            %   matrix CM
            %   METRIC = CALCULATECROSSVALMETRIC(actual, pred) returns calculated metric from
            %   real labels (ACTUAL) labels and predicted labels (PRED)
            if nargin == 2
                value = 1 - GM.calculateMetric(argum1,argum2);
            else
                value = 1 - GM.calculateMetric(argum1);
            end
        end
        
    end
    
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for the Minimum Sensitivity (MS).
% 
% The code has been tested with Ubuntu 12.04 x86_64, Debian Wheezy 8, Matlab R2009a and Matlab 2011
% 
% If you use this code, please cite the associated paper
% Code updates and citing information:
% http://www.uco.es/grupos/ayrna/orreview
% https://github.com/ayrna/orca
% 
% AYRNA Research group's website:
% http://www.uco.es/ayrna 
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
% Licence available at: http://www.gnu.org/licenses/gpl-3.0.html
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef MS < Metric

    methods
        function obj = MS()
                obj.name = 'Minimum Sensitivity';
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
	    
        function [ms,class] = calculateMetric(argum1,argum2)
            if nargin == 2,
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

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: calculateCrossvalMetric (static)
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

	function value = calculateCrossvalMetric(argum1,argum2)
            if nargin == 2,
                value = 1 - MS.calculateMetric(argum1,argum2);
            else
                value = 1 - MS.calculateMetric(argum1);
            end
        end
        
    end
            
    
end


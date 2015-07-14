%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for computing different kernel functions.
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

function kernelMatrix  = computeKernelMatrix(patterns1, patterns2, kernelType, kernelParam)
% Compute the kernel matrix between two sets of patterns
%
% Function inputs:
%   patterns1, patterns2   - Two matrixes of patterns (train and test, or train and train)
%   kernelType             - Kernel function choice. Can be  Gauss, Linear, Quickrbf, Poly, or Sigmoid.
%   kernelMatrix           - The kernel matrix


Nf1             = size(patterns1, 2);
Nf2             = size(patterns2, 2);
kernelMatrix   = zeros(Nf1, Nf2);

switch upper(kernelType),
    case {'GAUSS','GAUSSIAN','RBF'},

            for i = 1:Nf2,
                kernelMatrix(:,i)  = exp(-kernelParam*sum((patterns1-patterns2(:,i)*ones(1,Nf1)).^2)');

            end
   
    case {'QUICKRBF'}
        d = pdistalt(patterns1,patterns2,'euclidean');
        kernelMatrix = exp(-kernelParam*d.^2);
   
    case {'POLYNOMIAL', 'POLY', 'LINEAR'}
        if strcmp(upper(kernelType), 'LINEAR')
            kernelParam = 1;
            bias = 0;
        else
            bias = 1;
        end
        kernelMatrix = (patterns1' * patterns2 + bias).^kernelParam;

    case 'SIGMOID'

        if (length(kernelParam) ~= 2)
            error('This kernel needs two parameters to operate!')
        end

        kernelMatrix   = zeros(Nf1, Nf2);
        for i = 1:Nf2,
            kernelMatrix(:,i)  = tanh(patterns1'*patterns2(:,i)*kernelParam(1)+kernelParam(2));
        end
    
    otherwise
        error('Unknown kernel. Can be Gauss, Linear, Quickrbf, Poly, or Sigmoid.')
        
end

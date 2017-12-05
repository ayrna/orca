function KM = computeKernelMatrix(P1, P2, kType, kParam)
%COMPUTEKERNELMATRIX computes the kernel matrix between two sets of patterns
%
%   KM = computeKernelMatrix(P1, P2, kType, kParam) computes kernel matrix
%   KM between sets of patterns P1 and P2. kType is the type of the kernel
%   function (Gauss, Linear, Quickrbf, Poly, or Sigmoid). KPARAM is the
%   kernel parameter, for instance the width of the Gaussian kernel.
%
% Function inputs:
%   patterns1, patterns2   - Two matrixes of patterns (train and test, or train and train)
%   kernelType             - Kernel function choice. Can be  Gauss, Linear, Quickrbf, Poly, or Sigmoid.
%   kernelMatrix           - The kernel matrix
%
%   This file is part of ORCA: https://github.com/ayrna/orca
%   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
%   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
%   Copyright:
%       This software is released under the The GNU General Public License v3.0 licence
%       available at http://www.gnu.org/licenses/gpl-3.0.html
%
Nf1             = size(P1, 2);
Nf2             = size(P2, 2);
KM   = zeros(Nf1, Nf2);

switch upper(kType)
    case {'GAUSS','GAUSSIAN','RBF'}
        
        for i = 1:Nf2
            KM(:,i)  = exp(-kParam*sum((P1-P2(:,i)*ones(1,Nf1)).^2)');
            
        end
        
    case {'QUICKRBF'}
        d = pdistalt(P1,P2,'euclidean');
        KM = exp(-kParam*d.^2);
        
    case {'POLYNOMIAL', 'POLY', 'LINEAR'}
        if strcmpi(kType, 'LINEAR')
            kParam = 1;
            bias = 0;
        else
            bias = 1;
        end
        KM = ((P1' * P2 + bias)/size(P1,1)).^kParam;
        
    case 'SIGMOID'
        
        if (length(kParam) ~= 2)
            error('This kernel needs two parameters to operate!')
        end
        
        KM   = zeros(Nf1, Nf2);
        for i = 1:Nf2
            KM(:,i)  = tanh(P1'*P2(:,i)*kParam(1)+kParam(2));
        end
        
    otherwise
        error('Unknown kernel. Can be Gauss, Linear, Quickrbf, Poly, or Sigmoid.')
        
end

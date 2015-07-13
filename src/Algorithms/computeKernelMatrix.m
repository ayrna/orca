function kernelMatrix  = computeKernelMatrix(patterns1, patterns2, kernelType, kernelParam)

% Compute the kernel matrix between two sets of patterns, returning a matrix
% of size N1xN2
%
% Inputs:
%   patterns1, patterns2    - Two matrixes of patterns
%   kernelType             - The kernel function. Can be RBF, Poly,
%                             Linear, Sigmoid, or Precomputed 
%                             (In the last case, patterns1 are returned as 
%                             the kernel matrix 
% Outputs:
%   kernelMatrix           - The kernel matrix
%
% Example:
%   load clouds
%   ker = compute_kernelMatrix(patterns(:, 1:500), patterns(:, 1:500), 'RBF', 1);

%Transform the input patterns
Nf1             = size(patterns1, 2);
Nf2             = size(patterns2, 2);
kernelMatrix   = zeros(Nf1, Nf2);

switch upper(kernelType),
    case {'GAUSS','GAUSSIAN','RBF'},
        %for j = 1:Nf1,

            for i = 1:Nf2,
                kernelMatrix(:,i)  = exp(-kernelParam*sum((patterns1-patterns2(:,i)*ones(1,Nf1)).^2)');
                %kernelMatrix(:,i)  = exp(-sum((patterns1-patterns2(:,i)*ones(1,Nf1)).^2)'/(2*kernelParam^2));
                %kernelMatrix(j,i)  = exp(-pdist([ patterns1(:,j)' ; patterns2(:,i)'],'seuclidean')/(2*kernelParam^2));
                %SVOREX:
                %kernelMatrix(:,i)  = exp(-(kernelParam/2.0)*sum((patterns1-patterns2(:,i)*ones(1,Nf1)).^2)');

            end
            %kernelMatrix = kernelMatrix + eye(size(kernelMatrix))*0.001;
        %end
        
%         n1sq = sum(patterns1.^2,1);
%         n1 = size(patterns1,2);
% 
%         if isempty(patterns2);
%             D = (ones(n1,1)*n1sq)' + ones(n1,1)*n1sq -2*(patterns1'*patterns1);
%         else
%             n2sq = sum(patterns2.^2,1);
%             n2 = size(patterns2,2);
%             D = (ones(n2,1)*n1sq)' + (ones(n1,1)*n2sq) -2*(patterns1'*patterns2);
%         end;
%         kernelMatrix = exp(-kernelParam*D);
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

%        kernelMatrix   = zeros(Nf1, Nf2);
%        for i = 1:Nf2,
%            kernelMatrix(:,i)  = (patterns1'*patterns2(:,i) + bias).^kernelParam;
%        end
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
        error('Unknown kernel. Can be Gauss, Linear, Poly, or Sigmoid.')
        
end

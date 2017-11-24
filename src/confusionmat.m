function [ret] = confusionmat(actual, pred)
% CONFUSIONMAT Calculates confusion matrix for classification algorithms.
%    CM = CONFUSIONMAT(actual,pred) returns the confusion matrix CM from class
%    labels ACTUAL and predicted labels PRED
%
%   This file is part of ORCA: https://github.com/ayrna/orca
%   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
%   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
%   Copyright:
%       This software is released under the The GNU General Public License v3.0 licence
%       available at http://www.gnu.org/licenses/gpl-3.0.html
%
    values = union(unique(actual), unique(pred));
    ret = zeros(numel(values), numel(values));
    for i = 1:numel(actual)
        i1 = find(values == actual(i));
        i2 = find(values == pred(i));
        ret(i1, i2) = ret(i1, i2) + 1;
    end
end

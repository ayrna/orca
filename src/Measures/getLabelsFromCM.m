function [actual,pred] = getLabelsFromCM(cm)
%getLabelsFromCM build pair of actual and predicted labels from a
%   confussion matrix
%   [ACTUAL,PRED] = GETLABELSFROMCM(CM) returns real labels in ACTUAL and
%   predicted labels in PRED.
%
%   This file is part of ORCA: https://github.com/ayrna/orca
%   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
%   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
%   Copyright:
%       This software is released under the The GNU General Public License v3.0 licence
%       available at http://www.gnu.org/licenses/gpl-3.0.html
counter1 = 1;
counter2 = 1;
for i=1:size(cm,1)
    %actual(counter1:(sum(cm(i,:))+counter1-1))=i-1;
    actual(counter1:(sum(cm(i,:))+counter1-1))=i;
    counter1 = counter1 + sum(cm(i,:));
    for z=1:size(cm,1)
        %pred(counter2:(cm(i,z)+counter2-1))=z-1;
        pred(counter2:(cm(i,z)+counter2-1))=z;
        counter2 = counter2 + cm(i,z);
        
    end
end
actual = actual';
pred = pred';
end


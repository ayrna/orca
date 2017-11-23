function [ret] = confusionmat(actual, pred)
% CONFUSIONMAT Calculates confusion matrix for classification algorithms.
%    CM = CONFUSIONMAT(actual,pred) returns the confusion matrix CM from class
%    labels ACTUAL and predicted labels PRED

    values = union(unique(actual), unique(pred));
    ret = zeros(numel(values), numel(values));
    for i = 1:numel(actual)
        i1 = find(values == actual(i));
        i2 = find(values == pred(i));
        ret(i1, i2) = ret(i1, i2) + 1;
    end
end

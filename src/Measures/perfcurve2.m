function [X,Y,thre,auc,optrocpt,subY,subYnames] = ...
    perfcurve2(labels,scores,posClass,varargin)
%PERFCURVE Compute Receiver Operating Characteristic (ROC) curve or other
%   performance curve for classifier output.
%  
%   [X,Y] = PERFCURVE(LABELS,SCORES,POSCLASS) computes a ROC curve for a
%   vector of classifier predictions SCORES given true class labels,
%   LABELS. The labels can be a numeric vector, logical vector, character
%   matrix, cell array of strings or categorical vector (see help for
%   groupingvariable). SCORES is a numeric vector of scores returned by a
%   classifier for some data. This vector must have as many elements as
%   LABELS does. POSCLASS is the positive class label (scalar), either
%   numeric (for numeric LABELS) or char. The specified positive class must
%   be in the array of input labels. The returned values X and Y are
%   coordinates for the performance curve and can be visualized  with
%   PLOT(X,Y). By default, X is false positive rate, FPR, (equivalently,
%   fallout, or 1-specificity) and Y is true positive rate, TPR,
%   (equivalently, recall, or sensitivity).
%  
%   [X,Y,THRE] = PERFCURVE(LABELS,SCORES,POSCLASS) returns an array of
%   thresholds on classifier scores for the computed values of X and Y. It
%   has the same number of rows as X and Y. For each threshold, TP is the
%   count of true positive observations with scores greater or equal to
%   this threshold, and FP is the count of false positive observations with
%   scores greater or equal to this threshold. PERFCURVE defines negative
%   counts, TN and FN, in a similar way then sorts the thresholds in the
%   descending order which corresponds to the ascending order of positive
%   counts. For the M distinct thresholds found in the array of scores,
%   PERFCURVE returns the X, Y and THRE arrays with M+1 rows. PERFCURVE
%   sets elements THRE(2:M+1) to the distinct thresholds, and THRE(1)
%   replicates THRE(2). By convention, THRE(1) represents the highest
%   'reject all' threshold and PERFCURVE computes the corresponding values
%   of X and Y for TP=0 and FP=0. THRE(end) is the lowest 'accept all'
%   threshold for which TN=0 and FN=0.
%  
%   [X,Y,THRE,AUC] = PERFCURVE(LABELS,SCORES,POSCLASS) returns the area
%   under curve (AUC) for the computed values of X and Y. If XVALS is set
%   to 'all', PERFCURVE computes AUC using the returned X and Y values. If
%   XVALS is a numeric array, PERFCURVE computes AUC using X and Y values
%   found from all distinct scores in the interval specified by the
%   smallest and largest elements of XVALS. More precisely, PERFCURVE finds
%   X values for all distinct thresholds as if XVALS were set to 'all',
%   then uses a subset of these (with corresponding Y values) between
%   MIN(XVALS) and MAX(XVALS) to compute AUC. The function uses trapezoidal
%   approximation to estimate the area.
%  
%   If the first or last value of X or Y are NaN's, PERFCURVE removes them
%   to allow calculation of AUC. This takes care of criteria that produce
%   NaN's for the special 'reject all' or 'accept all' thresholds, for
%   example, positive predictive value (PPV) or negative predictive value
%   (NPV).
%    
%   [X,Y,THRE,AUC,OPTROCPT] = PERFCURVE(LABELS,SCORES,POSCLASS) returns the
%   optimal operating point of the ROC curve as an array of size 1-by-2
%   with FPR and TPR values for the optimal ROC operating point. OPTROCPT
%   is computed only for the standard ROC curve and set to NaN's otherwise.
%   To obtain the optimal operating point for the ROC curve PERFCURVE first
%   finds  the slope, S, using 
%          S = (cost(P|N)-cost(N|N))/(cost(N|P)-cost(P|P)) * N/P
%   where cost(I|J) is the cost of assigning an instance of class J to
%   class I, and P=TP+FN and N=TN+FP are the total instance counts in the
%   positive and negative class, respectively. PERFCURVE then finds the
%   optimal operating point by moving the straight line with slope S from
%   the upper left corner of the ROC plot (FPR=0,TPR=1) down and to the
%   right until it intersects the ROC curve.
%  
%   [X,Y,THRE,AUC,OPTROCPT,SUBY] = PERFCURVE(LABELS,SCORES,POSCLASS)
%   returns an array of Y values for negative subclasses. If you only
%   specify one negative class, SUBY is identical to Y. Otherwise SUBY is a
%   matrix of size M-by-K where M is the number of returned values for X
%   and Y, and K is the number of negative classes. PERFCURVE computes Y
%   values by summing counts over all negative classes. SUBY gives values
%   of the Y criterion for each negative class separately. For each
%   negative class, PERFCURVE places a new column in SUBY and fills it with
%   Y values for TN and FP counted just for this class.
%  
%   [X,Y,THRE,AUC,OPTROCPT,SUBY,SUBYNAMES] = PERFCURVE(LABELS,SCORES,POSCLASS,'NegClass',NEGCLASS)
%   returns a cell array of negative class names. If you provide an input
%   array, NEGCLASS, of negative class names, PERFCURVE copies it into
%   SUBYNAMES. If you do not provide NEGCLASS, PERFCURVE extracts
%   SUBYNAMES from input labels. The order of SUBYNAMES is the same as the
%   order of columns in SUBY, that is, SUBY(:,1) is for negative class
%   SUBYNAMES{1} etc.
%  
%   [X,Y] = PERFCURVE(LABELS,SCORES,POSCLASS,'PARAM1',val1,'PARAM2',val2,...) 
%   specifies optional parameter name/value pairs:
%  
%     'NegClass' - List of negative classes. Can be either a numeric array
%                  or an array of chars or a cell array of strings. By
%                  default, NegClass is set to 'all' and all classes found
%                  in the input array of labels that are not the positive
%                  class are considered negative. If NegClass is a subset
%                  of the classes found in the input array of labels,
%                  instances with labels that do not belong to either
%                  positive or negative classes are discarded.
%  
%     'XCrit' - Criterion to compute for X. The following criteria are
%               supported: 
%         TP    - number of true positives
%         FN    - number of false negatives
%         FP    - number of false positives
%         TN    - number of true negatives
%         TP+FP - sum of TP and FP
%         RPP   = (TP+FP)/(TP+FN+FP+TN) rate of positive predictions
%         RNP   = (TN+FN)/(TP+FN+FP+TN) rate of negative predictions
%         accu  = (TP+TN)/(TP+FN+FP+TN) accuracy
%         TPR, sens, reca = TP/(TP+FN) true positive rate, sensitivity, recall
%         FNR, miss       = FN/(TP+FN) false negative rate, miss
%         FPR, fall       = FP/(TN+FP) false positive rate, fallout
%         TNR, spec       = TN/(TN+FP) true negative rate, specificity
%         PPV, prec = TP/(TP+FP) positive predictive value, precision
%         NPV       = TN/(TN+FN) negative predictive value
%         ecost=(TP*COST(P|P)+FN*COST(N|P)+FP*COST(P|N)+TN*COST(N|N))/(TP+FN+FP+TN)
%              expected cost
%         In addition, you can define an arbitrary criterion by supplying
%         an anonymous function of 3 arguments, (C,scale,cost), where C is
%         a 2-by-2 confusion matrix, scale is a 2-by-1 array of class
%         scales, and cost is a 2-by-2 misclassification cost matrix.
%         Warning: some of these criteria return NaN values at one of the
%         two special thresholds, 'reject all' and 'accept all'.
%   
%     'YCrit' - Criterion to compute for Y. The same criteria as for X
%               are supported.
%   
%     'XVals' - Values for the X criterion. By default, XVals is set to
%               'all' and PERFCURVE computes X and Y values for all scores.
%               If XVals is not set to 'all', it must be a numeric array.
%               In this case, X and Y are computed only for the specified
%               XVals.
%   
%     'ProcessNaN' - This argument specifies how PERFCURVE processes NaN
%                    scores. By default, it is set to 'ignore' and
%                    instances with NaN scores are removed from the data.
%                    If the parameter is set to 'addtofalse', PERFCURVE
%                    adds instances with NaN scores to false classification
%                    counts in the respective class. That is, instances
%                    from the positive class are always counted as false
%                    negative (FN), and instances from the negative class
%                    are always counted as false positive (FP). 
%   
%     'Prior' - Either string or array with 2 elements. It represents prior
%               probabilities for the positive and negative class,
%               respectively. Default is 'empirical', that is, prior
%               probabilities are derived from class frequencies. If set to
%               'uniform', all prior probabilities are set equal.
%   
%     'Cost'  - A 2-by-2 matrix of misclassification costs 
%                   [C(P|P) C(N|P); C(P|N) C(N|N)] 
%               where C(I|J) is the cost of misclassifying
%               class J as class I. By default set to [0 0.5; 0.5 0].
%
%   Example: Plot ROC curve for classification by logistic regression
%      load fisheriris
%      x = meas(51:end,1:2);        % iris data, 2 classes and 2 features
%      y = (1:100)'>50;             % versicolor=0, virginica=1
%      b = glmfit(x,y,'binomial');  % logistic regression
%      p = glmval(b,x,'logit');     % get fitted probabilities for scores
% 
%      [X,Y] = perfcurve(species(51:end,:),p,'virginica');
%      plot(X,Y)
%      xlabel('False positive rate'); ylabel('True positive rate')
%      title('ROC for classification by logistic regression')
%
%   See also GLMFIT, CLASSIFY, NAIVEBAYES, CLASSREGTREE, GROUPINGVARIABLE.

%   Copyright 2008 The MathWorks, Inc. 
%   $Revision: 1.1.6.2.2.1 $

% Prepare input parser
p = inputParser;
p.addRequired('labels',...
    @(x) ~isempty(x) && (ischar(x) || isnumeric(x) || islogical(x) ...
    || iscell(x) || strcmp(class(x),'nominal') || strcmp(class(x),'ordinal')));
p.addRequired('scores',@(x) ~isempty(x) && isnumeric(x));
p.addRequired('PosClass',@(x) ~isempty(x) && (ischar(x) || isnumeric(x)));
p.addParamValue('NegClass','all', ...
    @(x) ~isempty(x) && (ischar(x) || isnumeric(x) || iscell(x)));    
p.addParamValue('XCrit','FPR',@(x) ischar(x) || isa(x,'function_handle'));
p.addParamValue('YCrit','sens',@(x) ischar(x) || isa(x,'function_handle'));
p.addParamValue('XVals','all', ... 
    @(x) ~isempty(x) && ((ischar(x) && strcmpi(x,'all')) || isnumeric(x)) );
p.addParamValue('ProcessNaN','ignore', ...
    @(x) strcmpi(x,'ignore') || strcmpi(x,'addtofalse'));
p.addParamValue('Prior','empirical', ...
    @(x) (ischar(x) && (strcmpi(x,'empirical') || strcmpi(x,'uniform'))) ...
    || (isnumeric(x) && numel(x)==2) );
p.addParamValue('Cost',[0 0.5; 0.5 0], ...
    @(x) isnumeric(x) && size(x,1)==2 && size(x,2)==2);
p.FunctionName = 'perfcurve';

% Parse inputs
p.parse(labels,scores,posClass,varargin{:});
negClass       = p.Results.NegClass;
xCrit          = p.Results.XCrit;
yCrit          = p.Results.YCrit;
xVals          = p.Results.XVals;
processNaN     = p.Results.ProcessNaN;
prior          = p.Results.Prior;
cost           = p.Results.Cost;

% Check dimensionality of scores and labels
[nsx,nsy] = size(scores);
if nsx~=1 && nsy~=1
    error('stats:perfcurve:InvalidInput',...
        'Array of scores must be a vector.');
end
if nsx==1 && nsy~=1
    scores = scores';
end
[nlx,nly] = size(labels);
if ~ischar(labels) 
    if nlx~=1 && nly~=1
        error('stats:perfcurve:InvalidInput',...
            'Array of labels must be a vector.');
    end
    if nlx==1 && nly~=1
        labels = labels';
    end
end
if nsx~=nlx
    error('stats:perfcurve:InvalidInput',...
        'The size of scores does not match the size of labels.');
end

% Convert class labels to a cat array
labels = nominal(labels);
trueNames = getlabels(labels);
if length(trueNames) < 2
    error('stats:perfcurve:InvalidInput',...
        'Less than two classes are found in the array of true class labels.');
end

% Check costs
if (cost(2,1)-cost(2,2))<=0 || (cost(1,2)-cost(1,1))<=0
    error('stats:perfcurve:InvalidInput',...
        'Cost of correct classification must be less than cost of incorrect classification.');
end

% Sort scores in the descending order
[sScores,sIdx] = sort(scores,1,'descend');
sLabels = labels(sIdx);

% Get class membership for instances:
% C(i,j)==1 if instance i is from class j and ==0 otherwise.
% Also, get negative class names.
% C has the size of NxK 
%   where N is the number of instances and K is the number of classes.
% subYnames is a cell array of length K-1 with names of negative classes.
% Column C(:,j) is for class subYnames{j-1}   (j>1)
[C,subYnames] = membership(sLabels,posClass,negClass,trueNames);

% Make Ccum, a matrix of cumulative counts in each class.
% Adjust Ccum and scores using the specified behavior for NaN scores.
[Ccum,sScores] = makeccum(C,sScores,processNaN);

% Determine criteria to compute
if isa(xCrit,'function_handle')
    fx = xCrit;
else
    fx = makeCrit(xCrit);
end
if isa(yCrit,'function_handle')
    fy = yCrit;
else
    fy = makeCrit(yCrit);
end

% Compute class probabilities
scale = classscale(Ccum,prior);

% Define arrayfuns
afx = @(tp,fn,fp,tn) fx([tp fn; fp tn],scale,cost);
afy = @(tp,fn,fp,tn) fy([tp fn; fp tn],scale,cost);

% Compute the actual values for the specified criterion,
%   (to be plotted on X axis),
%   associated TP and FP counts,
%   and the associated threshold indices
[X,tpX,fpX,divX] = Xvalues(xVals,afx,Ccum);

% Compute criterion values associated with these thresholds 
%   (to be plotted on Y axis)
Y = Yvalues(tpX,fpX,afy,Ccum);

% Get thresholds from indices
if nargout>2
    thre = thresholds(divX,sScores);
end

% Compute area under curve
if nargout>3
    % If not all thresholds have been found, find all and apply range
    if ~strcmpi(xVals,'all')
        [Xnew,tpXnew,fpXnew,divXnew] = Xvalues('all',afx,Ccum);
        Ynew = Yvalues(tpXnew,fpXnew,afy,Ccum);
        [Xnew,Ynew] = applyrange(Xnew,Ynew,[X(1) X(end)]);
    else
        Xnew = X;
        Ynew = Y;
        divXnew = divX;
    end
    
    % If the 1st or last value is NaN, trim the new X and Y
    if isnan(Xnew(1)) || isnan(Ynew(1))
        Xnew = trimfirst(Xnew,divXnew);
        Ynew = trimfirst(Ynew,divXnew);
    end
    if isnan(Xnew(end)) || isnan(Ynew(end))
        Xnew = trimlast(Xnew,divXnew);
        Ynew = trimlast(Ynew,divXnew);
    end
    
    % Get the area
    auc = AUC(Xnew,Ynew);
end

% Find optimal operation point for the standard ROC curve
if nargout>4
    isroc = (strcmpi(xCrit,'FPR') || strcmpi(xCrit,'fall')) && ...
        (strcmpi(yCrit,'TPR') || strcmpi(yCrit,'sens') || strcmpi(yCrit,'reca'));
    if isroc
        optrocpt = findoptroc(X,Y,Ccum,scale,cost);
    else
        optrocpt = NaN(1,2);
    end
end

% Compute criterion values for individual negative classes
if nargout>5
    subY = subYvalues(tpX,fpX,divX,afy,Ccum);
end
end


function [C,negClassNames] = membership(sLabels,posClass,negClass,trueNames)
% Find the positive class. Must have exactly one.
posClass = cellstr(nominal(posClass));
if length(posClass)>1
    error('stats:perfcurve:InvalidInput',...
        'Only one positive class is allowed.');
end
if ~ismember(posClass,trueNames)
    error('stats:perfcurve:InvalidInput',...
        'Positive class is not found in the input data.');
end

% Check negative class labels
if strcmpi(negClass,'all')
    negClass = nominal(trueNames);
    [tf,posClassLoc] = ismember(posClass,cellstr(negClass));
    negClass(posClassLoc) = [];
    negClass = nominal(negClass);
else
    negClass = nominal(negClass);
    tf = ismember(cellstr(negClass),trueNames);
    if any(~tf)
        error('stats:perfcurve:InvalidInput',...
            'One or more negative classes not found in the input data.');
    end
    tf = ismember(posClass,cellstr(negClass));
    if tf
        error('stats:perfcurve:InvalidInput',...
            'Positive and negative classes cannot overlap.');
    end
end
nNeg = length(negClass);

% Names of selected negative classes
negClassNames = getlabels(negClass);

% Check for duplicate entries
if nNeg~=length(negClassNames)
    error('stats:perfcurve:InvalidInput',...
        'The list of negative classes has duplicate entries.');
end

% Fill out the membership matrix
% 1st column is for the positive class.
% Columns 2:end are for negative classes.
negClass = cellstr(negClass);
C = false(length(sLabels),1+nNeg);
C(:,1) = ismember(sLabels,posClass);
for i=1:nNeg
    C(:,i+1) = ismember(sLabels,negClass(i));
end
end


function [Ccum,scores] = makeccum(C,scores,processNaN)
% Discard instances that do not belong to any class
idxNone = ~any(C,2);
C(idxNone,:) = [];
scores(idxNone) = [];

% Get rid of NaN's in scores
Cnanrow = zeros(1,size(C,2));
idxNaN = isnan(scores);
if strcmpi(processNaN,'addtofalse')
    if ~isempty(idxNaN)
        Cnanrow = sum(C(idxNaN,:),1);
    end
end
scores(idxNaN) = [];
C(idxNaN,:) = [];

% Make a matrix of counts with NaN instances included
Cnan = zeros(size(C,1)+2,size(C,2));
Cnan(1,2:end) = Cnanrow(2:end);% FP (always accepted)
Cnan(2:end-1,:) = C;
Cnan(end,1) = Cnanrow(1);% FN (always rejected)

% Compute cumulative counts in each class
Ccum = cumsum(Cnan,1);

% Compact Ccum in case of identical scores
idxEq = find( scores(1:end-1) < scores(2:end) + ...
    max([eps(scores(1:end-1)) eps(scores(2:end))],[],2) );
Ccum(idxEq+1,:) = [];
scores(idxEq) = [];

% Have enough data for analysis?
% if length(scores)<2
%     error('stats:perfcurve:InvalidInput',...
%         'Unable to compute a performance curve for less than 2 distinct scores.');
% end
end


function scale = classscale(Ccum,prior)
scale = zeros(2,1);
Npos = Ccum(end,1);
Nneg = sum(Ccum(end,2:end),2);
if ischar(prior) && strcmpi(prior,'empirical')
    scale = ones(2,1);
end
if ischar(prior) && strcmpi(prior,'uniform')
    prior = ones(2,1);
end
if isnumeric(prior)
    if any(prior<=0)
        error('stats:perfcurve:InvalidInput',...
            'Prior class probabilities must be positive.');
    end
    scale(1) = prior(1)*Nneg;
    scale(2) = prior(2)*Npos;
    scale = scale/sum(scale);
end
end


function f = makeCrit(crit)
switch lower(crit)
    case 'tp'
        f = @(C,scale,cost) scale(1)*C(1,1);
    case 'fn'
        f = @(C,scale,cost) scale(1)*C(1,2);
    case 'fp'
        f = @(C,scale,cost) scale(2)*C(2,1);
    case 'tn'
        f = @(C,scale,cost) scale(2)*C(2,2);
    case 'tp+fp'
        f = @(C,scale,cost) sum(scale.*C(:,1),1);
    case 'rpp'
        f = @(C,scale,cost) sum(scale.*C(:,1),1) / sum(scale.*sum(C,2));
    case 'rnp'
        f = @(C,scale,cost) sum(scale.*C(:,2),1) / sum(scale.*sum(C,2));
    case 'accu'
        f = @(C,scale,cost) ...
            (scale(1)*C(1,1)+scale(2)*C(2,2)) / sum(scale.*sum(C,2));
    case {'tpr','sens','reca'}
        f = @(C,scale,cost) C(1,1) / sum(C(1,:),2);
    case {'fnr','miss'}
        f = @(C,scale,cost) C(1,2) / sum(C(1,:),2);
    case {'fpr','fall'}
        f = @(C,scale,cost) C(2,1) / sum(C(2,:),2);
    case {'tnr','spec'}
        f = @(C,scale,cost) C(2,2) / sum(C(2,:),2);
    case {'ppv','prec'}
        f = @(C,scale,cost) scale(1)*C(1,1) / sum(scale.*C(:,1));
    case 'npv'
        f = @(C,scale,cost) scale(2)*C(2,2) / sum(scale.*C(:,2));
    case 'ecost'
        f = @(C,scale,cost) ...
            sum(scale.*sum(C.*cost,2)) / sum(scale.*sum(C,2));
    otherwise
        error('stats:perfcurve:InvalidInput',...
            'Unknown criterion specified.');
end
end


function X = trimfirst(X,divX)
X(divX==1,:) = [];
end


function X = trimlast(X,divX)
X(divX==divX(end),:) = [];
end


function [X,Y] = applyrange(X,Y,xrange)
if ~isempty(xrange)
    if numel(xrange)~=2
        error('stats:perfcurve:InvalidInput',...
            'Invalid range for X values.');
    end
    xrange = sort(xrange);
    inrange = (X>=xrange(1) & X<=xrange(2));
    if isempty(inrange)
        error('stats:perfcurve:InvalidInput',...
            'No X values in the specified range.');
    end
    X = X(inrange);
    Y = Y(inrange,:);
end
end


function thre = thresholds(divX,scores)
% Init
thre = zeros(length(divX),1);

% First threshold
if divX(1)==1
    thre(1) = scores(1);
else
    thre(1) = scores(divX(1)-1);
end

% Normal thresholds
thre(2:end-1) = scores(divX(2:end-1)-1);
end


function increasing = monotone(vals)
% Allow only monotone criteria.
% By default, assume a criterion that monotonously increases as
%   the predicted score in the positive class decreases. Otherwise, swap.
% 'increasing' is a flag that shows in what order values are sorted.
increasing = 1;
if any(vals(1:end-1)>vals(2:end))
    increasing = -1;
    if any(vals(1:end-1)<vals(2:end))
        error('stats:perfcurve:BadXCritValue',...
            'Chosen X criterion is not a monotone function of the predicted score for the positive class.');
    end
end
end


function [valX,tpX,fpX,divX] = Xvalues(xVals,afx,Ccum)
% Get counts for positive and negative classes
Pcum = Ccum(:,1);
Ncum = sum(Ccum(:,2:end),2);
nP = Pcum(end);
nN = Ncum(end);
Nrow = size(Pcum,1)-1;

% Check total counts in positive and negative classes
if nP==0
    error('stats:perfcurve:BadClassCounts',...
        'No instances of positive class found.');
end
if nN==0
    error('stats:perfcurve:BadClassCounts',...
        'No instances of negative class found.');
end

% Get all possible values of the criterion
allVals = arrayfun(afx,Pcum(1:Nrow),nP-Pcum(1:Nrow),Ncum(1:Nrow),nN-Ncum(1:Nrow));

% Check for NaN's everywhere but first and last row
idxnan = isnan(allVals);
if any(idxnan(2:end-1))
    error('stats:perfcurve:BadXCritValue',...
        'Unable to compute X criterion for supplied class counts.');
end

% Do criterion values increase or decrease vs predicted scores?
increasing = monotone(allVals);

% Return all possible values and divisions if requested.
% If xVals is char, it was set to 'all', the only allowed value.
if ischar(xVals)
    valX = allVals;
    tpX = Pcum(1:Nrow);
    fpX = Ncum(1:Nrow);
    divX = (1:Nrow)';
    return;
end

% Sort input values
xVals = increasing*sort(increasing*xVals);

% Find indices of thresholds.
nVal = length(xVals);
divX = zeros(nVal,1);
for i=1:nVal
    thisdiv = find(increasing*allVals >= increasing*xVals(i),1);
    if isempty(thisdiv)
        divX(i) = Nrow;
        break;
    end
    divX(i) = thisdiv;
end
divX = divX(divX>0);
if divX(1)==1
    divX = [1 2 divX(2:end)']';
end
divX = unique(divX);

% Get TP and FP counts for chosen threshold indices
tpX = Pcum(divX);
fpX = Ncum(divX);

% valX is the corresponding array of criterion values
valX = arrayfun(afx,tpX,nP-tpX,fpX,nN-fpX);
end


function valY = Yvalues(tpX,fpX,afy,Ccum)
% Get number of instances in the positive and negative classes
nP = Ccum(end,1);
nN = sum(Ccum(end,2:end),2);

% Compute Y criterion for the total of all negative classes
valY = arrayfun(afy,tpX,nP-tpX,fpX,nN-fpX);
end


function subY = subYvalues(tpX,fpX,divX,afy,Ccum)
% If only one negative class, it is accounted for by Yvalues
nNegClass = size(Ccum,2)-1;
if nNegClass < 2
    subY = Yvalues(tpX,fpX,afy,Ccum);
    return;
end

% Compute Y criteria for negative classes separately
nP = Ccum(end,1);
subY = zeros(length(tpX),nNegClass);
for i=1:nNegClass
    nN = Ccum(end,i+1);
    if nN==0
        error('stats:perfcurve:BadClassCounts',...
            'No instances of negative class %i found.',i);
    end
    fpX = Ccum(divX,i+1);
    subY(:,i) = arrayfun(afy,tpX,nP-tpX,fpX,nN-fpX);
end
end


function auc = AUC(x,y)
% Have enough data?
if length(x)<2
    auc = 0;
    return;
end

% Get area
auc = 0.5*sum( (x(2:end)-x(1:end-1)).*(y(2:end)+y(1:end-1)) );
auc = abs(auc);
end


function optpt = findoptroc(X,Y,Ccum,scale,cost)
% Get positive and negative counts
nP = scale(1)*Ccum(end,1);
nN = scale(2)*sum(Ccum(end,2:end),2);

% Get the optimal slope
m = (cost(2,1)-cost(2,2))/(cost(1,2)-cost(1,1)) * nN/nP;

% Find lowest intercept for straight lines drawn through (X,Y) 
%   using this slope and X axis
[intercept,idx] = min(X - Y/m);

% Get the optimal point
optpt = [X(idx) Y(idx)];
end

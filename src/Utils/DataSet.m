classdef DataSet < handle
    %DATASET Class to specify the name of the datasets and perform data preprocessing
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    
    properties
        directory = '';
        train = '';
        test = '';
        standarize = true;
        dataname = '';
        nOfFolds = 5;
    end
    
    methods
        function obj = dataSet(direct)
            if(nargin ~= 0)
                obj.directory = direct;
            end
        end
        
        
        function obj = set.directory(obj,direc)
            if isdir(direc)
                obj.directory = direc;
            else
                error('%s --> Not a directory', direc);
            end
        end
                
        function [trainSet, testSet] = preProcessData(obj)
        % PREPROCESSDATA preprocess a data partition, i.e., deletes the constant 
        %   and non numerical atributes and standarize the data. Test set
        %   is standardised using train mean and standard error. 
        %   [TRAINSET, TESTSET] = PREPROCESSDATA() preprocess dataset and
        %   returns the preprocessed patterns in TRAINSET and TESTSET.
            
            if(exist([obj.directory '/' obj.train], 'file') && exist([obj.directory '/' obj.test], 'file'))
                obj.dataname = strrep(obj.train, 'train_', '');
                rawTrain=load([obj.directory '/' obj.train]);
                rawTest=load([obj.directory '/' obj.test]);
                
                trainSet.targets = rawTrain(:,end);
                trainSet.patterns = rawTrain(:,1:end-1);
                
                testSet.targets = rawTest(:,end);
                testSet.patterns = rawTest(:,1:end-1);
                
                if(obj.standarize)
                    [trainSet, testSet] = obj.deleteConstantAtributes(trainSet,testSet);
                    [trainSet, testSet] = obj.standarizeData(trainSet,testSet);
                    %[trainSet, testSet] = obj.scaleData(trainSet,testSet);
                    [trainSet, testSet] = obj.deleteNonNumericValues(trainSet, testSet);
                end
                
                
                datasetname=[obj.directory '/' obj.train];
                [matchstart,matchend] = regexpi(datasetname,'/');
                trainSet.name = datasetname(matchend(end)+1:end);
                
                datasetname=[obj.directory '/' obj.test];
                [matchstart,matchend] = regexpi(datasetname,'/');
                testSet.name = datasetname(matchend(end)+1:end);
            else
                error('Can not find the files');
            end
        end
        
        
    end
    methods (Static = true)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: standarizeData (static)
        % Description: 
        % Type: It returns the standarized patterns (train and test)
        % Arguments:
        %           trainSet--> Array of training patterns
        %           testSet--> Array of testing patterns
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [trainSet, testSet] = standarizeData(trainSet,testSet)
        % STANDARIZEDATA standarizes a set of training and testing patterns.
        %   [TRAINSET, TESTSET] = STANDARIZEDATA(TRAINSET,TESTSET)
        %   standarizes TRAINSET and TESTSET with TRAINSET mean and std. 
            [trainSet.patterns, trainMeans, trainStds] = DataSet.standarizeFunction(trainSet.patterns);
            testSet.patterns = DataSet.standarizeFunction(testSet.patterns,trainMeans,trainStds);
        end
                
        function [XN, XMeans, XStds] = standarizeFunction(X,XMeans,XStds)
        % STANDARIZEFUNCTION standardises data with patterns stored in rows.
        %   [XN, XMeans, XStds] = standarizeFunction(X) standardises X
        %   using X mean and std. Returns normalised data in XN and
        %   calculated mean and std in XMEANS and XSTDS respectively
        %   [XN, XMeans, XStds] = standarizeFunction(X,XMeans,XStds) standardises X
        %   using XMeans as mean and XStds as std. 
            
            if (nargin<3)
                XStds = std(X);
            end
            if (nargin<2)
                XMeans = mean(X);
            end
            XN = zeros(size(X));
            for i=1:size(X,2)
                XN(:,i) = (X(:,i) - XMeans(i)) / XStds(i);
            end
        end
        
        function [trainSet, testSet] = scaleData(trainSet,testSet)
        % SCALEDATA scales a set of training and testing patterns.
        %   [TRAINSET, TESTSET] = SCALEDATA(TRAINSET,TESTSET)
        %   scales TRAINSET and TESTSET. 
            for i = 1:size(trainSet.patterns,1)
                for j = 1:size(trainSet.patterns,2)
                    trainSet.patterns(i,j) = 1/(1+exp(-trainSet.patterns(i,j)));
                end
            end
            for i = 1:size(testSet.patterns,1)
                for j = 1:size(testSet.patterns,2)
                    testSet.patterns(i,j) = 1/(1+exp(-testSet.patterns(i,j)));
                end
            end
        end
                
        function [trainSet, testSet] = deleteNonNumericValues(trainSet,testSet)
        % DELETENONNUMERICVALUES This function deletes non numerical values 
        %   in the data, as NaN or Inf.
        %   [TRAINSET, TESTSET] = DELETENONNUMERICVALUES(TRAINSET,TESTSET)
        %   performs data cleaning on arrays of patterns TRAINSET and TESTSET. Returns
        %   processed matrices. 
            
            [fils,cols]=find(isnan(trainSet.patterns) | isinf(trainSet.patterns));
            cols = unique(cols);
            for a = size(cols):-1:1
                trainSet.patterns(:,cols(a)) = [];
            end
            
            [fils,cols]=find(isnan(trainSet.targets) | isinf(trainSet.targets));
            cols = unique(cols);
            for a = size(cols):-1:1
                trainSet.patterns(:,cols(a)) = [];
            end
            
            [fils,cols]=find(isnan(testSet.patterns) | isinf(testSet.patterns));
            cols = unique(cols);
            for a = size(cols):-1:1
                testSet.patterns(:,cols(a)) = [];
            end
            
            [fils,cols]=find(isnan(testSet.targets) | isinf(testSet.targets));
            cols = unique(cols);
            for a = size(cols):-1:1
                testSet.patterns(:,cols(a)) = [];
            end
            
        end
        
        function [trainSet,testSet] = deleteConstantAtributes(trainSet, testSet)
        % DELETECONSTANTATRIBUTES This function deletes constant variables
        %   [TRAINSET, TESTSET] = DELETECONSTANTATRIBUTES(TRAINSET,TESTSET)
        %   performs data cleaning on arrays of patterns TRAINSET and TESTSET. Returns
        %   processed matrices. 
            
            % This causes problems in some dataset with constant attribute in
            % train but not constant in test. Latar when standarizing a division by 
            % zero will happens. Then we only look for constant att. in
            % train
            % all = [trainSet.patterns ; testSet.patterns];
            
            minvals = min(trainSet.patterns);
            maxvals = max(trainSet.patterns);
            
            r = 0;
            for k=1:size(trainSet.patterns,2)
                if minvals(k) == maxvals(k)
                    r = r + 1;
                    index(r) = k;
                end
            end
            
            if r > 0
                r = 0;
                for k=1:size(index,2)
                    trainSet.patterns(:,index(k)-r) = [];
                    testSet.patterns(:,index(k)-r) = [];
                    r = r + 1;
                end
            end
        end
        

    end
end



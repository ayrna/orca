classdef DataSet < handle
    % DataSet 
    % Class to specify the name of the databases and process them for further
    % use of the data.
    
    properties
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: directory (Public)
        % Type: String
        % Description: It specifies the directory 
        %               containing the set of
        %               databases. For example:
        %               'dataset-real-holdout\30-holdout' 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        directory = ''
        
        train = ''
       
        test = ''
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: standarize (Public)
        % Type: Logical
        % Description: This variable specifies if the data 
        %               will be standarized. By default, 
        %               this variable is assigned
        %               to 1, so, the data is standarized.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        standarize = true
        
        reorderlabels = 0
        
        dataname = ''
        
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         %
%         % Variable: relabel (Public)
%         % Type: String
%         % Description: This variable specifies whether the labels
%         %               must be converted. For instance, most ANNs
%         %               needs a binary representation instead of 
%         %               integer numbersdefault, 
%         %
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         
%         relabel = 'no' % 'no'/'integer', 'binary', 'latent'
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: nOfFolds (Public)
        % Type: Integer
        % Description: Number of partitions of the data 
        %               for doing the
        %               parameters crossvalidation
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        nOfFolds = 5
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: repeatFold (Public)
        % Type: Logical
        % Description: This variable is set to the number 
        %               of repetitions we
        %               want to do with the same fold.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        repeatFold = 1
        


    end
    
    
    methods   
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: DataSet (Public Constructor)
        % Description: It constructs an object of the class
        %               DataSet and fixes the directory 
        %               to the value of the argument.
        % Type: Void
        % Arguments: 
        %           direct--> Value for the variable directory.
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = dataSet(direct)
            if(nargin ~= 0)
                obj.directory = direct;
            end
        end
        
      
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: set.directory (Public)
        % Description: It verifies if the value for the 
        %               variable directory is correct 
        %           and it exists a directory with this name.
        % Type: Void
        % Arguments: 
        %           direc--> directory to be processed.
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = set.directory(obj,direc)
                if isdir(direc)
                    obj.directory = direc;
                else
                    error('%s --> Not a directory', direc);
                end
        end  
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: preProcessData (Public)
        % Description: This funciton preprocess a file 
        %               indicated by the argument 'file'
        %               and the number of the folder 'folder'.
        %               It checks if the file exists and 
        %               in that case it loads the patterns 
        %               and targets for training and testing. 
        %               Besides, it deletes the constant and
        %               non numerical atributes and standarize
        %               the data.
        % Type: It returns the patterns loaded from the file (train and test)
        % Arguments: 
        %           folder--> Number of the folder in which the file is.
        %           file--> Number of the file.
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [trainSet, testSet] = preProcessData(obj)
            
                 if(exist([obj.directory filesep obj.train], 'file') && exist([obj.directory filesep obj.test], 'file')) 
                        obj.dataname = strrep(obj.train, 'train_', '');
                        rawTrain=load([obj.directory filesep obj.train]);
                        rawTest=load([obj.directory filesep obj.test]);

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
                        
                        switch(obj.reorderlabels)
                            case 1
                                [trainSet, testSet] = obj.reorderLabels(trainSet, testSet);
                            case 2
                                [trainSet, testSet] = obj.reorderLabelsInverse(trainSet, testSet);
                            otherwise
                                %do nothing
                        end
                        
%                         % add sone useful information
%                         trainSet.uniqueTargets = unique(trainSet.targets);
%                         testSet.uniqueTargets = unique(testSet.targets);
%                         
%                         trainSet.nOfClasses = length(trainSet.uniqueTargets);
%                         testSet.nOfClasses = trainSet.nOfClasses; % Number of classes that we see on the train set
%                         
%                         [trainSet.nOfPatterns trainSet.dim] = size(trainSet.patterns);
%                         [testSet.nOfPatterns testSet.dim] = size(testSet.patterns);
%                         
%                         trainSet.nOfPattPerClass = sum(repmat(trainSet.targets,1,size(trainSet.uniqueTargets,1))==repmat(trainSet.uniqueTargets',size(trainSet.targets,1),1));
%                         testSet.nOfPattPerClass = sum(repmat(testSet.targets,1,size(testSet.uniqueTargets,1))==repmat(testSet.uniqueTargets',size(testSet.targets,1),1));

                          datasetname=[obj.directory filesep obj.train];
                          [matchstart,matchend] = regexpi(datasetname,filesep);
                          trainSet.name = datasetname(matchend(end)+1:end);
                          
                          datasetname=[obj.directory filesep obj.test];
                          [matchstart,matchend] = regexpi(datasetname,filesep);
                          testSet.name = datasetname(matchend(end)+1:end);
                 else
                     error('Can not find the files');
                 end   
        end 

            
    end
        methods (Static = true)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: standarizeData (Private)
        % Description: It standarize a set of training and testing
        %               patterns.
        % Type: It returns the standarized patterns (train and test)
        % Arguments: 
        %           trainSet--> Array of training patterns
        %           testSet--> Array of testing patterns
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [trainSet, testSet] = standarizeData(trainSet,testSet)
                     [trainSet.patterns, trainMeans, trainStds] = DataSet.standarizeFunction(trainSet.patterns);
                     testSet.patterns = DataSet.standarizeFunction(testSet.patterns,trainMeans,trainStds);
        end
        
        function [trainSet, testSet] = scaleData(trainSet,testSet)
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: deleteNonNumericalValues (Private)
        % Description: This function deletes non numerical
        %               values in the data, as NaN or Inf.
        % Type: It returns the patterns without non numerical
        %               values (train and test)
        % Arguments: 
        %           trainSet--> Array of training patterns
        %           testSet--> Array of testing patterns
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [trainSet, testSet] = deleteNonNumericValues(trainSet,testSet)
                
                [fils,cols]=find(isnan(trainSet.patterns) | isinf(trainSet.patterns));
                cols = unique(cols);
                for a = size(cols):-1:1,
                    trainSet.patterns(:,cols(a)) = [];
                end

                [fils,cols]=find(isnan(trainSet.targets) | isinf(trainSet.targets));
                cols = unique(cols);
                for a = size(cols):-1:1,
                    trainSet.patterns(:,cols(a)) = [];
                end
                
                [fils,cols]=find(isnan(testSet.patterns) | isinf(testSet.patterns));
                cols = unique(cols);
                for a = size(cols):-1:1,
                    testSet.patterns(:,cols(a)) = [];
                end

                [fils,cols]=find(isnan(testSet.targets) | isinf(testSet.targets));
                cols = unique(cols);
                for a = size(cols):-1:1,
                    testSet.patterns(:,cols(a)) = [];
                end

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: deleteConstantAtributes (Private)
        % Description: This function deletes constant 
        %               atributes because they are not 
        %               helpful for the classification.
        % Type: It returns the patterns without this constant atributes
        % Arguments: 
        %           trainSet--> Array of training patterns
        %           testSet--> Array of testing patterns
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [trainSet,testSet] = deleteConstantAtributes(trainSet, testSet)
                
                all = [trainSet.patterns ; testSet.patterns];
                
                minvals = min(all);
                maxvals = max(all);

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
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function:  (Private)
        % Description: This function reorder the target 
        %               labels. 
        % Type: It returns the new dataset with label reordering. 
        % Arguments: 
        %           trainSet--> Array of training patterns
        %           testSet--> Array of testing patterns
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [trainSet,testSet] = reorderLabels(trainSet, testSet)
            labels = unique([trainSet.targets;testSet.targets]);
            J = max(labels);
            
            switch(J)
                case 2 % :P
                    labelsre = [2;1];
                case 3
                    labelsre = [1;3;2];
                case 4
                    labelsre = [1;4;2;3];
                case 5
                    labelsre = [3;1;5;2;4];
                case 6
                    labelsre = [1;5;2;4;6;3];
                case 7
                    labelsre = [3;1;7;5;2;6;4];
                case 8
                    labelsre = [3;8;1;7;5;2;6;4];
                case 9
                    labelsre = [3;8;1;7;5;9;2;6;4];
                case 10
                    labelsre = [3;10;8;1;7;5;9;2;6;4];
                case 19
                    labelsre = [3;19;10;13;8;18;1;16;11;7;5;12;17;9;2;15;6;4;14];
                otherwise
                    error('¡Number of classes is too high!')
            end
            
            trainTargets = zeros(size(trainSet.targets,1),1);
            testTargets = zeros(size(testSet.targets,1),1);
            
            % Esto es para resistir a distinto número de etiquetas por
            % clase en la partición train/test
            labels = unique(trainSet.targets);
            for j=1:length(labels)
                trainTargets(trainSet.targets==labels(j,1)) = labelsre(j,1);
            end
            
            labels = unique(testSet.targets);
            for j=1:length(labels)
                testTargets(testSet.targets==labels(j,1)) = labelsre(j,1);
            end
            
            % Reordenamos el dataset por la etiqueta tal porque esto lo
            % asumen algunos métodos. 
            P = [trainSet.patterns,trainTargets];
            P = sortrows(P,size(P,2));            
            trainSet.patterns = P(:,1:end-1);
            trainSet.targets = P(:,end);
            
            P = [testSet.patterns,testTargets];
            P = sortrows(P,size(P,2));            
            testSet.patterns = P(:,1:end-1);
            testSet.targets = P(:,end);
            
        end
 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: reorderLabelsInverse (Private)
        % Description: This function reorder the target 
        %               labels. 
        % Type: It returns the patterns without this constant atributes
        % Arguments: 
        %           trainSet--> Array of training patterns
        %           testSet--> Array of testing patterns
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [trainSet, testSet] = reorderLabelsInverse(trainSet, testSet)
            labels = unique([trainSet.targets;testSet.targets]);
            
            labelsre=sort(labels,1,'descend');
            
            % Esto es para resistir a distinto número de etiquetas por
            % clase en la partición train/test
            labels = unique(trainSet.targets);
            for j=1:length(labels)
                trainTargets(trainSet.targets==labels(j,1)) = labelsre(j,1);
            end
            
            labels = unique(testSet.targets);
            for j=1:length(labels)
                testTargets(testSet.targets==labels(j,1)) = labelsre(j,1);
            end
            
            %trainSetLabels = trainTargets';
            %testSetLabels = testTargets';
            
            % Reordenamos el dataset por la etiqueta tal porque esto lo
            % asumen algunos métodos. 
            P = [trainSet.patterns,trainTargets'];
            P = sortrows(P,size(P,2));            
            trainSet.patterns = P(:,1:end-1);
            trainSet.targets = P(:,end);
            
            P = [testSet.patterns,testTargets'];
            P = sortrows(P,size(P,2));            
            testSet.patterns = P(:,1:end-1);
            testSet.targets = P(:,end);
        end
        
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         %
%         % Function: labelToBinary (Private)
%         % Description: 
%         % Type: 
%         % Arguments: 
%         %           trainSet--> Array of training patterns
%         %           testSet--> Array of testing patterns
%         % 
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         
%         function [trainSet, testSet] = labelToBinary(trainSet,testSet)
%             % Adapt labels to Matlab's newff / ELM / etc. 
% 
%             % NOTE: This option based on full + ind2vec is not valid since 
%             % it have problems if a datasets do not have patterns of a
%             % given class
%             %DataSet.TrainTT = full(ind2vec(DataSet.TrainT'));
%             %DataSet.TestTT = full(ind2vec(DataSet.TestT'));
% 
%             trainN = size(trainSet.targets,1);
%             TT = zeros(trainN,trainSet.nOfClasses);
%             for ii=1:trainN
%                 TT(ii,trainSet.targets(ii,1)) = 1;
%             end
% 
%             trainSet.targetsBinary = TT;
% 
%             testN = size(testSet.targets,1);
%             TT = zeros(testN,testSet.nOfClasses);
%             for ii=1:testN
%                 TT(ii,testSet.targets(ii,1)) = 1;
%             end
% 
%             testSet.targetsBinary = TT;
% 
%             clear trainN testN TT;
%         end
%         
%         
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         %
%         % Function: labelToOrelm (Private)
%         % Description: 
%         % Type: 
%         % Arguments: 
%         %           trainSet--> Array of training patterns
%         %           testSet--> Array of testing patterns
%         % 
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         
%         function [trainSet, testSet] = labelToOrelm(trainSet,testSet)
% 
%             uniqueTargets = unique(trainSet.targets);
%             newTargets = zeros(trainSet.nOfPatterns,trainSet.nOfClasses);
% 
%             for i=1:trainSet.nOfClasses,
%                 newTargets(trainSet.targets<uniqueTargets(i),i) = -1;
%                 newTargets(trainSet.targets>=uniqueTargets(i),i) = 1;
%             end
%             
%             trainSet.targetsOrelm = newTargets;
%             
%             uniqueTargets = unique(testSet.targets);
%             newTargets = zeros(testSet.nOfPatterns,testSet.nOfClasses);
% 
%             for i=1:testSet.nOfClasses,
%                 newTargets(testSet.targets<uniqueTargets(i),i) = -1;
%                 newTargets(testSet.targets>=uniqueTargets(i),i) = 1;
%             end
%             
%             testSet.targetsOrelm = newTargets;
%             clear newTargets;
%         end


	function [XN, XMeans, XStds] = standarizeFunction(X,XMeans,XStds)

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
   end
end



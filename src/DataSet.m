%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file implements the code for handling the different data partitions (mainly preprocessing steps), presented in the paper Ordinal regression methods: survey and experimental study published in the IEEE Transactions on Knowledge and Data Engineering. 
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

classdef DataSet < handle
    % DataSet 
    % Class to specify the name of the datasets and preprocess them.
    
    properties

        directory = ''
        
        train = ''
       
        test = ''
        
        standarize = true
        
        dataname = ''
        
        nOfFolds = 5

        repeatFold = 1

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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: preProcessData (Public)
        % Description: This funciton preprocess a data partition, 
	%               deletes the constant and non numerical atributes
	% 		and standarize the data.
        % Type: It returns the patterns loaded from the file (trainSet and testSet)
        % Arguments: 
        %           No arguments
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
        % Function: standarizeData (static)
        % Description: standarize a set of training and testing
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
        % Function: deleteNonNumericalValues (static)
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
        % Function: deleteConstantAtributes (static)
        % Description: This function deletes constant 
        %               atributes.
        % Type: It returns the patterns without this constant attributes
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
        % Function: standarizeFunction (static)
        % Description: Function for data standarization.
        % Type: It returns the standardized patterns (XN), 
	%	the mean (Xmeans) and the standard deviation (XStds)
        % Arguments: 
        %           X--> data
        %           XMeans--> Data mean (optional)
	%	    XStds --> Standard deviation for the data (optional)
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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



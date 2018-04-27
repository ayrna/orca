classdef KNN < Algorithm
    %KNN Basic k-nearest neighbors algorithm based on Euclidean distance
    
    properties
        description = 'k-nearest neighbors algorithm';
        % Parameters to optimize and default value
        parameters = struct('k', 5);
    end
    
    methods    
        function obj = KNN(varargin)
            %KNN constructs an object of the class KNN. Default k is 5
            %
            %   OBJ = KNN('k', neighbours)
            %   builds KNN with NEIGHBOURS as number of neighbours to consider
            %   to label new patterns. 
            obj.parseArgs(varargin);
        end
        
        function [projectedTrain, predictedTrain]= privfit( obj, train, param)
            if(nargin == 3)
                obj.parameters.k = param.k;
            end
            
            % save train data in the model structure
            obj.model.train = train;
            obj.model.parameters = obj.parameters;
            % Predict train labels
            [projectedTrain, predictedTrain] = predict(obj, train.patterns);
        end
        
        function [projected, predicted] = privpredict(obj, testPatterns)
            % Variables aliases
            x = obj.model.train.patterns;
            xlabel = obj.model.train.targets;
            k = obj.model.parameters.k;

            dist = pdist2(testPatterns,x);
            % indicies of nearest neighbors
            [~,nearest] = sort(dist,2);
            % k nearest
            nearest = nearest(:,1:k);
            % mode of k nearest
            val = xlabel(nearest);
            predicted = mode(val,2);
            
            % dummy value for projections
            projected = -1.*ones(length(testPatterns),1); 
        end
    end    
end
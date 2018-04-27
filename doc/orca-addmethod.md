# Adding a new method to ORCA

ORCA is designed to ease the process of adding new methods. You only need to add the new algorithm's class file to folder `src/Algorithms`. After that, the method will be available to the framework and configuration files can be used to automate experiments.

## Method template

The code has follow the following template, which basically satisfies the API defined in the `Algorithm` abstract class:

```MATLAB
classdef NEWMETHOD < Algorithm    
    properties
        description = 'my NEWMETHOD method description';
        % Parameters to optimize and default value
        parameters = struct('k', 5);
    end

    methods    
        function obj = NEWMETHOD(varargin)
            % Process key-values pairs of parameters
            obj.parseArgs(varargin);
        end

        function [projectedTrain, predictedTrain]= privfit( obj, train, param)
            % fit the model and return prediction of train set. It is called by
            % super class Algorithm.fit() method.
            ...
            % Save the model
            obj.model = model;
        end

        function [projected, predicted] = privpredict(obj, testPatterns)
            % predict unseen patterns with 'obj.model' and return prediction and
            % projection of patterns (for threshold models)
            % It is called by super class Algorithm.predict() method.
        end
    end    
end
```

Where `train` is a structure with `train.patterns` being a matrix of patterns and `train.targets` being a vector with the corresponding labels. `model` class property stores the model built with the train data.

## Example: adding KNN to ORCA

To illustrate the one-step process of adding a new method, we will add the KNN classifier to ORCA. Just copy the file [KNN.m](KNN.m) to folder `src/Algorithms`:

```MATLAB
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
```

Then, you can define a configuration file such as [knntoy.ini](knntoy.ini) to describe experiments using KNN:

```INI
;Experiment ID
[knn-mae-toy]
{general-conf}
;Datasets path
basedir = ../exampledata/30-holdout
;Datasets to process (comma separated list)
datasets = toy
;Activate data standardization
standarize = true
;Number of folds for the parameters optimization
num_folds = 5
;Crossvalidation metric
cvmetric = mae

;Method: algorithm and parameter
{algorithm-parameters}
algorithm = KNN

;Method's hyper-parameter values to optimize
{algorithm-hyper-parameters-to-cv}
k = 3,5,7
```

To run experiments described in that file, from `src` folder type:

```MATLAB
Utilities.runExperiments('../doc/addmethod/knntoy.ini')
```

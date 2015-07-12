classdef OREnsemblePer < Algorithm
    % -------
    % TODO: Muy mal hecho
    % -------
    
    %KDLOR Kernel Discriminant Learning for Ordinal Regression
    %   This class derives from the Algorithm Class and implements the
    %   KLDOR method. 
    %   Characteristics: 
    %               -Kernel functions: Yes
    %               -Ordinal: Yes
    %               -Parameters: 
    %                       -C: Penalty coefficient
    %                       -Others (depending on the kernel choice)
    
    properties
       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: parameters (Public)
        % Type: Struct
        % Description: This variable keeps the values for 
        %               the C penalty coefficient and the 
        %               kernel parameters
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        parameters = []
        name_parameters = {}
        weights = true;
    end
    
    methods
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: KDLOR (Public Constructor)
        % Description: It constructs an object of the class
        %               KDLOR and sets its characteristics.
        % Type: Void
        % Arguments: 
        %           kernel--> Type of Kernel function
        %           opt--> Type of optimization used in the method.
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = OREnsemblePer()
            obj.name = 'OR Ensemble with perceptron';
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: defaultParameters (Public)
        % Description: It assigns the parameters of the 
        %               algorithm to a default value.
        % Type: Void
        % Arguments: 
        %           No arguments for this function.
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = defaultParameters(obj)
            obj.parameters = [];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runAlgorithm (Public)
        % Description: This function runs the corresponding
        %               algorithm, fitting the model, and 
        %               testing it in a dataset. It also 
        %               calculates some statistics as CCR,
        %               Confusion Matrix, and others. 
        % Type: It returns a set of statistics (Struct) 
        % Arguments: 
        %           Train --> Trainning data for fitting the model
        %           Test --> Test data for validation
        %           parameters --> Penalty coefficient C 
        %           for the KDLOR method and kernel parameters
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [model_information] = runAlgorithm(obj,train, test)
                trainFile = tempname();
                dlmwrite(trainFile,[train.patterns train.targets],'delimiter',' ','precision',10);
                testFile = tempname();
                dlmwrite(testFile,[test.patterns test.targets],'delimiter',' ','precision',10);
                modelFile = tempname();
                
                c1 = clock;
                obj.train( train,trainFile, modelFile);
                c2 = clock;
                model_information.trainTime = etime(c2,c1);
                c1 = clock;
                [model_information.projectedTrain,model_information.predictedTrain] = obj.test(train,trainFile,modelFile);
                [model_information.projectedTest,model_information.predictedTest] = obj.test(test,testFile,modelFile);
                c2 = clock;
                model_information.testTime = etime(c2,c1);
                
                fid = fopen(modelFile);
                s = textscan(fid,'%s','Delimiter','\n','bufsize', 2^18-1);
                s = s{1};
                fclose(fid);
                
                model.algorithm = 'OREnsemble';
                model.textInformation = s;
                model.weights = obj.weights;
                model_information.model = model;
                
                system(['rm ' trainFile]);
                system(['rm ' testFile]);
                system(['rm ' modelFile]);

                
%                 dataSetStatistics.projectedTest = p2;
%                 dataSetStatistics.projectedTrain = p;
                 

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the KDLOR algorithm.
        % Type: [Array, Array]
        % Arguments: 
        %           trainPatterns --> Trainning data for 
        %                              fitting the model
        %           testTargets --> Training targets
        %           parameters --> Penalty coefficient C 
        %           for the KDLOR method and kernel parameters
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function train( obj,train,trainFile, modelFile )
            execute_train = sprintf('./Algorithms/orensemble/hack.sh ./Algorithms/orensemble/boostrank-train %s %d %d %d1 204 %d 2000 %s',trainFile,size(train.patterns,1),size(train.patterns,2),(3+obj.weights),max(unique(train.targets)),modelFile);
            system(execute_train);
        end
        
        function [projected, testTargets]= test( obj,test,testFile,modelFile )
                predictFile = tempname();
                execute_test = sprintf('./Algorithms/orensemble/hack.sh ./Algorithms/orensemble/boostrank-predict %s %d %d %s 2000 %s',testFile,size(test.patterns,1),size(test.patterns,2),modelFile,predictFile);

                system(execute_test);
                all = load(predictFile);
                testTargets = all(:,1);
                projected = all(:,2);
                system(['rm ' predictFile]);
                

        end  
            
    end
end

% NOTE: 
% - This code is based on the code of Qin-Yu Zhu et. al corresponding to the
%   paper "Evolutionary Extreme Learning Machine" [3]. The code of Qin-Yu
%   Zhu is based on the code of Kenneth Price and Rainer Storn available at
%   http://www1.icsi.berkeley.edu/~storn/code.html#matl
% - As a disclaimer, the code is not clean and elegant enought (since the
%   original code is not), however I prefer to publish the code.
% - We use to term Randomized Neural Network (RNN) as equivalent term for Extreme
%   Learning Machine (ELM)
% 

classdef ERNN < Algorithm
    %ERNN Evolutionary Randomized Neural Network (RNN). Also known as Extreme 
    %   Learning Machine.  The class provides several variations of the
    %   differential evolution algorithm proposed by Kenneth Price and
    %   Rainer Storn applied to train neural networks [1][2]. The input weights of
    %   the neural network are optimized through differential evolution
    %   while the output weights are analitically computed with the
    %   Moore-Penrose Pseudoinverse.
    %
    %   ERNN methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      fit                        - Fits a model from training data
    %      predict                    - Performs label prediction
    %
    %   References:
    %     [1] J. Sánchez-Monedero, P.A. Gutiérrez, and C. Hervás-Martínez, 
    %         "Evolutionary ordinal extreme learning machine", 8th International 
    %         Conference on Hybrid Artificial Intelligent Systems, HAIS
    %         2013. Lecture Notes in Computer Science, Volume 8073 LNAI, 2013, 
    %         Pages 500-509
    %         https://doi.org/10.1007/978-3-642-40846-5_50
    %     [2] J. Sánchez-Monedero, P.A. Gutiérrez, F. Fernández-Navarro and 
    %         C. Hervás-Martínez, "Weighting Efficient Accuracy and Minimum 
    %         Sensitivity for Evolving Multi-Class Classifiers", Neural 
    %         Process Lett (2011) 34: 101.
    %         https://doi.org/10.1007/s11063-011-9186-9
    %     [3] Qin-Yu Zhu, A.K.Qin, P.N.Suganthan and Guang-Bin Huang, "Evolutionary 
    %         extreme learning machine", Pattern Recognition, Volume 38, 
    %         Issue 10, October 2005, Pages 1759-1763
    %         https://doi.org/10.1016/j.patcog.2005.03.028
    
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original author: Javier Sánchez-Monedero
    %   Contributors: Pedro A. Gutiérrez, Javier Sánchez-Monedero
    %   Citation: If you use this code, please cite the associated paper
    %   [1]
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    
    properties
        
        activationFunction = 'sig';
        % Input Weights range 
        wMin = -1;
        wMax = 1;
        
        classifier = 'nominal'
        
        FitnessFunction = 'ccrs_r';
        lambda = 0.3;
        
        NP=40;
        itermax=50;
        refresh=100;
        
        CR=0.8;
        strategy = 3;
        F=1;
        tolerance = 0.02;
                
        description = 'Evolutionary Randomized Neural Network';
        parameters = struct('hiddenN', 20);
    end

    
    methods

        function obj = EELM(varargin)
            %SVC1V1 constructs an object of the class SVC1V1 and sets its default
            %   characteristics
            %   OBJ = SVC1V1(KERNEL) builds SVC1V1 with RBF as kernel function
            obj.parseArgs(varargin);
        end

        function [model_information] = runAlgorithm(obj,train, test, parameters)
                % <Mover a una función >
                train.uniqueTargets = unique([test.targets ;train.targets]);
                test.uniqueTargets = train.uniqueTargets;
                train.nOfClasses = max(train.uniqueTargets);
                test.nOfClasses = train.nOfClasses;                
                train.nOfPatterns = length(train.targets);
                test.nOfPatterns = length(test.targets);
                
                train.dim = size(train.patterns,2);
                test.dim = train.dim;
                % </Mover a una función >
                
                param.hiddenN = parameters(1);
                
                switch(obj.classifier)
                    case {'nominal'}
                        [train, test] = obj.labelToBinary(train,test);
                    case {'ordinal'}
                        [train, test] = obj.labelToOrelm(train,test);
                        train.uniqueTargetsOrelm = unique([test.targetsOrelm ;train.targetsOrelm],'rows');
                        test.uniqueTargetsOrelm = train.uniqueTargetsOrelm;
                
                    case {'ordinalRegressScaled'}
                        [train, test] = obj.scaleLabel(train,test, 0, 1);
                end
                
                tic;
                model = obj.train( train, param);
                trainTime = toc;
                
                tic;
                [model_information.projectedTrain, model_information.predictedTrain] = obj.test( train,model );
                [model_information.projectedTest, model_information.predictedTest] = obj.test( test,model );
                testTime = toc;

                % Dummy values
                %model.thresholds = -1;

                model_information.trainTime = trainTime;
                model_information.testTime = testTime;
                model_information.model = model;

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: train (Public)
        % Description: This function train the model for
        %               the SVRPCDOC algorithm.
        % Type: [Structure]
        % Arguments: 
        %           train.patterns --> Trainning data for 
        %                              fitting the model
        %           testTargets --> Training targets
        %           parameters --> 
        % ,  wMin, wMax
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % minimization of a user-supplied function with respect to x(1:D),
        % using the differential evolution (DE) algorithm of Rainer Storn
        % (http://www.icsi.berkeley.edu/~storn/code.html)
        % 
        % Special thanks go to Ken Price (kprice@solano.community.net) and
        % Arnold Neumaier (http://solon.cma.univie.ac.at/~neum/) for their
        % valuable contributions to improve the code.
        % 
        % Strategies with exponential crossover, further input variable
        % tests, and arbitrary function name implemented by Jim Van Zandt 
        % <jrv@vanzandt.mv.com>, 12/97.
        %
        % Output arguments:
        % ----------------
        % bestmem        parameter vector with best solution
        % bestval        best objective function value
        % nfeval         number of function evaluations
        %
        % Input arguments:  
        % ---------------
        %
        % fname          string naming a function f(x,y) to minimize
        % VTR            "Value To Reach". devec3 will stop its minimization
        %                if either the maximum number of iterations "itermax"
        %                is reached or the best parameter vector "bestmem" 
        %                has found a value f(bestmem,y) <= VTR.
        % D              number of parameters of the objective function 
        % XVMin          vector of lower bounds XVMin(1) ... XVMin(D)
        %                of initial population
        %                *** note: these are not bound constraints!! ***
        % XVMax          vector of upper bounds XVMax(1) ... XVMax(D)
        %                of initial population
        % y		        problem data vector (must remain fixed during the
        %                minimization)
        % NP             number of population members
        % itermax        maximum number of iterations (generations)
        % F              DE-stepsize F from interval [0, 2]
        % CR             crossover probability constant from interval [0, 1]
        % strategy       1 --> DE/best/1/exp           6 --> DE/best/1/bin
        %                2 --> DE/rand/1/exp           7 --> DE/rand/1/bin
        %                3 --> DE/rand-to-best/1/exp   8 --> DE/rand-to-best/1/bin
        %                4 --> DE/best/2/exp           9 --> DE/best/2/bin
        %                5 --> DE/rand/2/exp           else  DE/rand/2/bin
        %                Experiments suggest that /bin likes to have a slightly
        %                larger CR than /exp.
        % refresh        intermediate output will be produced after "refresh"
        %                iterations. No intermediate output will be produced
        %                if refresh is < 1
        %
        %       The first four arguments are essential (though they have
        %       default values, too). In particular, the algorithm seems to
        %       work well only if [XVMin,XVMax] covers the region where the
        %       global minimum is expected. DE is also somewhat sensitive to
        %       the choice of the stepsize F. A good initial guess is to
        %       choose F from interval [0.5, 1], e.g. 0.8. CR, the crossover
        %       probability constant from interval [0, 1] helps to maintain
        %       the diversity of the population and is rather uncritical. The
        %       number of population members NP is also not very critical. A
        %       good initial guess is 10*D. Depending on the difficulty of the
        %       problem NP can be lower than 10*D or must be higher than 10*D
        %       to achieve convergence.
        %       If the parameters are correlated, high values of CR work better.
        %       The reverse is true for no correlation.
        %
        % default values in case of missing input arguments:
        % 	VTR = 1.e-6;
        % 	D = 2; 
        % 	XVMin = [-2 -2]; 
        % 	XVMax = [2 2]; 
        %	y=[];
        % 	NP = 10*D; 
        % 	itermax = 200; 
        % 	F = 0.8; 
        % 	CR = 0.5; 
        % 	strategy = 7;
        % 	refresh = 10; 
        %
        % Cost function:  	function result = f(x,y);
        %                      	has to be defined by the user and is minimized
        %			w.r. to  x(1:D).
        %
        % Example to find the minimum of the Rosenbrock saddle:
        % ----------------------------------------------------
        % Define f.m as:
        %                    function result = f(x,y);
        %                    result = 100*(x(2)-x(1)^2)^2+(1-x(1))^2;
        %                    end
        % Then type:
        %
        % 	VTR = 1.e-6;
        % 	D = 2; 
        % 	XVMin = [-2 -2]; 
        % 	XVMax = [2 2]; 
        % 	[bestmem,bestval,nfeval] = devec3("f",VTR,D,XVMin,XVMax);
        %
        % The same example with a more complete argument list is handled in 
        % run1.m
        %
        % About devec3.m
        % --------------
        % Differential Evolution for MATLAB
        % Copyright (C) 1996, 1997 R. Storn
        % International Computer Science Institute (ICSI)
        % 1947 Center Street, Suite 600
        % Berkeley, CA 94704
        % E-mail: storn@icsi.berkeley.edu
        % WWW:    http://http.icsi.berkeley.edu/~storn
        %
        % devec is a vectorized variant of DE which, however, has a
        % propertiy which differs from the original version of DE:
        % 1) The random selection of vectors is performed by shuffling the
        %    population array. Hence a certain vector can't be chosen twice
        %    in the same term of the perturbation expression.
        %
        % Due to the vectorized expressions devec3 executes fairly fast
        % in MATLAB's interpreter environment.
        %
        % This program is free software; you can redistribute it and/or modify
        % it under the terms of the GNU General Public License as published by
        % the Free Software Foundation; either version 1, or (at your option)
        % any later version.
        %
        % This program is distributed in the hope that it will be useful,
        % but WITHOUT ANY WARRANTY; without even the implied warranty of
        % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        % GNU General Public License for more details. A copy of the GNU 
        % General Public License can be obtained from the 
        % Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

        %-----Check input variables---------------------------------------------
        %err=[];

        % if nargin<1, error('devec3 1st argument must be function name'); else 
        %   if exist(fname)<1; err(1,length(err)+1)=1; end; end;
        % if nargin<2, VTR = 1.e-6; else 
        %   if length(VTR)~=1; err(1,length(err)+1)=2; end; end;
        % if nargin<3, D = 2; else
        %   if length(D)~=1; err(1,length(err)+1)=3; end; end; 
        % if nargin<4, XVMin = [-2 -2];else
        %   if length(XVMin)~=D; err(1,length(err)+1)=4; end; end; 
        % if nargin<5, XVMax = [2 2]; else
        %   if length(XVMax)~=D; err(1,length(err)+1)=5; end; end; 
        % if nargin<6, y=[]; end; 
        % if nargin<7, NP = 10*D; else
        %   if length(NP)~=1; err(1,length(err)+1)=7; end; end; 
        % if nargin<8, itermax = 200; else
        %   if length(itermax)~=1; err(1,length(err)+1)=8; end; end; 
        % if nargin<9, F = 0.8; else
        %   if length(F)~=1; err(1,length(err)+1)=9; end; end;
        % if nargin<10, CR = 0.5; else
        %   if length(CR)~=1; err(1,length(err)+1)=10; end; end; 
        % if nargin<11, strategy = 7; else
        %   if length(strategy)~=1; err(1,length(err)+1)=11; end; end;
        % if nargin<12, refresh = 10; else
        %   if length(refresh)~=1; err(1,length(err)+1)=12; end; end; 
        % if length(err)>0
        %   fprintf(stdout,'error in parameter %d\n', err);
        %   usage('devec3 (string,scalar,scalar,vector,vector,any,integer,integer,scalar,scalar,integer,integer)');    	
        % end
        %REGRESSION=0;
        %CLASSIFIER=1;
        %Gain = 1;                                           %  Gain parameter for sigmoid


        % if ~exist('XVMin', 'var') && ~exist('XVMax','var')
        % 	XVMin=-1;
        % 	XVMax=1; 
        % end
        % if ~exist('wMin', 'var') && ~exist('wMax','var')
        % 	wMin=-1;
        % 	wMax=1; 
        % end
        % 
        % if ~exist('CR', 'var')
        %     CR=0.8;
        % end
        % 
        % if ~exist('F', 'var')
        %     F=1;
        % end
        % 
        % if ~exist('NP', 'var')
        %     NP=400;
        % end
        % 
        % if ~exist('itermax', 'var')
        %     itermax=20;
        % end
        % 
        % if ~exist('strategy', 'var')
        %     strategy = 3;
        % end


        
        %[InputWeight,BiasofHiddenNeurons,OutputWeight,Y,TrainingTime]
        function [projectedTrain, predictedTrain] = privfit( obj,train, parameters)
            % TODO [projectedTrain, predictedTrain]
        %function [TrainingTime, ConfusionMatrixTrain, ConfusionMatrixTest, CCRTrain, MSTrain, CCRTest, MSTest...
        %            NumberofInputNeurons,NumberofHiddenNeurons,NumberofOutputNeurons,InputWeight,OutputWeight,itResults] = ...
        %        eelm(train_data, test_data, Elm_Type, NumberofHiddenNeurons, obj.activationFunction, ...
        %        wMin, wMax, CR, F, NP, itermax,refresh, strategy,tolerance,FitnessFunction,lambda)
            
         % TODO: UNHACK A NIVEL DE CROSSVALIDACIÓN
            if( strcmp(obj.activationFunction,'rbf') && parameters.hiddenN > train.nOfPatterns)
                    %disp(['User''s number of hidden neurons ' num2str(parameters.hiddenN) ... 
                    %    ' was too high and has been adjusted to the number of training patterns']);
               obj.parameters.hiddenN = train.nOfPatterns;
            else
               obj.parameters.hiddenN = parameters.hiddenN;
            end
            
            %  Classifier
            Elm_Type = 1;
            
            % Copy parameters (TODO: clean)
            
            NumberofHiddenNeurons = obj.parameters.hiddenN;
            obj.lambda = obj.lambda;
            
            obj.activationFunction = obj.activationFunction;
            %wMin = obj.wMin;
            %wMax = obj.wMax;
            %CR = obj.CR;
            %NP = obj.NP;
            obj.itermax = obj.itermax;
            obj.refresh = obj.refresh;
            obj.strategy = obj.strategy;
            obj.F = obj.F;
            obj.tolerance = obj.tolerance;
           
           
            
            P = train.patterns';

            switch(obj.classifier)
                case {'nominal'}
                    T = train.targetsBinary;
                    T=T*2-1; % Map tags values to -1, 1  
                case {'ordinal'}
                    T = train.targetsOrelm;
                case {'ordinalRegress'}
                    T = train.targets;
                case {'ordinalRegressScaled'}
                    T = train.targetsScaled;
                case {'regression'}
                    T = train.targets;
                case {'regressionLatent'}
                    T = train.targetsLatent;
            end

                                
            T = T';
            
            T_ceros = T;
            T_ceros(T_ceros==-1)=0;
            T_org = train.targets;


%             %%%%%%%%%%% Load testing dataset
%             TV.T=test_data(:,1)';
%             TV.P=test_data(:,2:size(test_data,2))';
%             clear test_data;                                    %   Release raw testing data array

            NumberofTrainingData=size(P,2);
%            NumberofTestingData=size(TV.P,2);
            NumberofInputNeurons=size(P,1);
            %NumberofValidationData = round(NumberofTestingData / 2);
            NumberofOutputNeurons = train.nOfClasses;
            
            
            D=NumberofHiddenNeurons*(NumberofInputNeurons+1);
            
            

% %             if Elm_Type~=0
% %                 %%%%%%%%%%%% Preprocessing the data of classification
% %                 %sorted_target=sort(cat(2,T,TV.T),2);
% %                 sorted_target=sort(cat(2,T),2);
% %                 label=zeros(1,1);                               %   Find and save in 'label' class label from training and testing data sets
% %                 label(1,1)=sorted_target(1,1);
% %                 j=1;
% %                 %for i = 2:(NumberofTrainingData+NumberofTestingData)
% %                 for i = 2:(NumberofTrainingData)
% %                     if sorted_target(1,i) ~= label(1,j)
% %                         j=j+1;
% %                         label(1,j) = sorted_target(1,i);
% %                     end
% %                 end
% %                 number_class=j;
% %                 NumberofOutputNeurons=j;

                %%%%%%%%%% Processing the targets of training
% %                 temp_T=zeros(NumberofOutputNeurons, NumberofTrainingData);
% %                 for i = 1:NumberofTrainingData
% %                     for j = 1:number_class
% %                         if label(1,j) == T(1,i)
% %                             %nOfPatterns(j,1) = nOfPatterns(j,1) + 1;
% %                             break; 
% %                         end
% %                     end
% %                     temp_T(j,i)=1;
% %                 end
% % 
% %                 %pstar_train = min(nOfPatterns) / NumberofTrainingData;
% % 
% %                 % TODO : controlar cuándo se normaliza esto
% %                 T_org = T;
% %                 T=temp_T*2-1; % Map tags values to -1, 1
% % 
% %                 %%%%%%%%%% Processing the targets of testing
% % %                 temp_TV_T=zeros(NumberofOutputNeurons, NumberofTestingData);
% % %                 for i = 1:NumberofTestingData
% % %                     for j = 1:number_class
% % %                         if label(1,j) == TV.T(1,i)
% % %                             break; 
% % %                         end
% % %                     end
% % %                     temp_TV_T(j,i)=1;
% % %                 end
% % % 
% % %                 TV_org = TV.T;
% % %                 TV.T=temp_TV_T*2-1;
% %             end                                                 %   end if of Elm_Type
% % 
% %             T_ceros = T;
% %             T_ceros(T_ceros==-1)=0;
% % 
% % %             TV_ceros = TV.T;
% % %             TV_ceros(TV_ceros==-1)=0;
% % 
% %             clear sorted_target;
% %             clear temp_T;
% %             clear temp_TV_T;


            % VV.P = TV.P(:,1:NumberofValidationData);
            % VV.T = TV.T(:,1:NumberofValidationData);
            % TV.P(:,1:NumberofValidationData)=[];
            % TV.T(:,1:NumberofValidationData)=[];
            % NumberofTestingData = NumberofTestingData - NumberofValidationData;


            %%%%%%%%%%% Calculate weights & biases




            %------Perform log(P) calculation once for UP
            % The calculation is done here for including it into the validation time
            if strcmp(obj.activationFunction, 'up')
                P = log(P);
%                 TV.P = log(TV.P);
                %VV.P = log(VV.P);
            end

            if (obj.NP < 5)
               obj.NP=5;
               fprintf(1,' NP increased to minimal value 5\n');
            end
            if ((obj.CR < 0) || (obj.CR > 1))
               obj.CR=0.5;
               fprintf(1,'CR should be from interval [0,1]; set to default value 0.5\n');
            end
            if (obj.itermax <= 0)
               obj.itermax = 200;
               fprintf(1,'itermax should be > 0; set to default value 200\n');
            end
            obj.refresh = floor(obj.refresh);

            %-----Initialize population and some arrays-------------------------------

            pop = zeros(obj.NP,D); %initialize pop to gain speed

            %----pop is a matrix of size NPxD. It will be initialized-------------
            %----with random values between the min and max values of the---------
            %----parameters-------------------------------------------------------


            if strcmp(obj.activationFunction,'sig') || strcmp(obj.activationFunction,'up')
                for i=1:obj.NP
                    %pop(i,:) = XVMin + rand(1,D).*(XVMax - XVMin);
                    pop(i,:) = obj.wMin + rand(1,D).*(obj.wMax- obj.wMin); %Debería ser esto
                end
            else if strcmp(obj.activationFunction,'rbf')
                    P = P';
                    for i=1:obj.NP
                        if (NumberofTrainingData>2000)
                            TY=pdist(P(randperm(2000),:));
                        else
                            TY=pdist(P);
                        end
                        a10=prctile(TY,20);
                        a90=prctile(TY,60);
                        MP=randperm(NumberofTrainingData);
                        W1=P(MP(1:NumberofHiddenNeurons),:);
                        W10=rand(1,NumberofHiddenNeurons)*(a90-a10)+a10;

                        pop(i,:) = reshape([W1 W10'],D,1);
                    end
                    P = P';
                end
            end

            popold    = zeros(size(pop));     % toggle population
            val       = zeros(1,obj.NP);          % create and reset the "cost array"
            bestmem   = zeros(1,D);           % best population member ever
            bestmemit = zeros(1,D);           % best population member in iteration
            nfeval    = 0;                    % number of function evaluations
            brk    = 0;


            %------Evaluate the best member after initialization----------------------

            ibest   = 1;  % start with first population member

            [val(1),OutputWeight]  = obj.eelm_x(Elm_Type,pop(ibest,:),P,T,T_org,T_ceros,NumberofHiddenNeurons);
            bestval = val(1);                 % best objective function value so far
            nfeval  = nfeval + 1;
            bestweight = OutputWeight;
            for i=2:obj.NP                        % check the remaining members  
              [val(i),OutputWeight] = obj.eelm_x(Elm_Type,pop(i,:),P,T,T_org,T_ceros,NumberofHiddenNeurons);
              nfeval  = nfeval + 1; % Esto se puede mover abajo
              if (val(i) < bestval)           % if member is better
                 ibest   = i;                 % save its location
                 bestval = val(i);
                 bestweight = OutputWeight;
              end   
            end
            bestmemit = pop(ibest,:);         % best member of current iteration
            bestvalit = bestval;              % best value of current iteration
            bestmem = bestmemit;              % best member ever

            %------Iteration results---------------------------------------------
            itResults = cell(floor(obj.itermax/obj.refresh),1);
            refreshIt = 0;


            %------DE-Minimization---------------------------------------------
            %------popold is the population which has to compete. It is--------
            %------static through one iteration. pop is the newly--------------
            %------emerging population.----------------------------------------

            pm1 = zeros(obj.NP,D);              % initialize population matrix 1
            pm2 = zeros(obj.NP,D);              % initialize population matrix 2
            pm3 = zeros(obj.NP,D);              % initialize population matrix 3
            pm4 = zeros(obj.NP,D);              % initialize population matrix 4
            pm5 = zeros(obj.NP,D);              % initialize population matrix 5
            bm  = zeros(obj.NP,D);              % initialize bestmember  matrix
            ui  = zeros(obj.NP,D);              % intermediate population of perturbed vectors
            mui = zeros(obj.NP,D);              % mask for intermediate population
            mpo = zeros(obj.NP,D);              % mask for old population
            rot = (0:1:obj.NP-1);               % rotating index array (size NP)
            rotd= (0:1:D-1);                % rotating index array (size D)
            rt  = zeros(obj.NP);                % another rotating index array
            rtd = zeros(D);                 % rotating index array for exponential crossover
            a1  = zeros(obj.NP);                % index array
            a2  = zeros(obj.NP);                % index array
            a3  = zeros(obj.NP);                % index array
            a4  = zeros(obj.NP);                % index array
            a5  = zeros(obj.NP);                % index array
            ind = zeros(4);

            iter = 1;
            while (~(iter > obj.itermax) )
              popold = pop;                   % save the old population

              ind = randperm(4);              % index pointer array

              a1  = randperm(obj.NP);             % shuffle locations of vectors
              rt = rem(rot+ind(1),obj.NP);        % rotate indices by ind(1) positions
              a2  = a1(rt+1);                 % rotate vector locations
              rt = rem(rot+ind(2),obj.NP);
              a3  = a2(rt+1);                
              rt = rem(rot+ind(3),obj.NP);
              a4  = a3(rt+1);               
              rt = rem(rot+ind(4),obj.NP);
              a5  = a4(rt+1);                

              pm1 = popold(a1,:);             % shuffled population 1
              pm2 = popold(a2,:);             % shuffled population 2
              pm3 = popold(a3,:);             % shuffled population 3
              pm4 = popold(a4,:);             % shuffled population 4
              pm5 = popold(a5,:);             % shuffled population 5

              for i=1:obj.NP                      % population filled with the best member
                bm(i,:) = bestmemit;          % of the last iteration
              end

              mui = rand(obj.NP,D) < obj.CR;          % all random numbers < CR are 1, 0 otherwise

              if (obj.strategy > 5)
                st = obj.strategy-5;		  % binomial crossover
              else
                st = obj.strategy;		  % exponential crossover
                mui=sort(mui');	          % transpose, collect 1's in each column
                for i=1:obj.NP
                  n=floor(rand*D);
                  if n > 0
                     rtd = rem(rotd+n,D);
                     mui(:,i) = mui(rtd+1,i); %rotate column i by n
                  end
                end
                mui = mui';			  % transpose back
              end
              mpo = mui < 0.5;                % inverse mask to mui

              if (st == 1)                      % DE/best/1
                ui = bm + obj.F*(pm1 - pm2);        % differential variation
                ui = popold.*mpo + ui.*mui;     % crossover
              elseif (st == 2)                  % DE/rand/1
                ui = pm3 + obj.F*(pm1 - pm2);       % differential variation
                ui = popold.*mpo + ui.*mui;     % crossover
              elseif (st == 3)                  % DE/rand-to-best/1
                ui = popold + obj.F*(bm-popold) + obj.F*(pm1 - pm2);        
                ui = popold.*mpo + ui.*mui;     % crossover
              elseif (st == 4)                  % DE/best/2
                ui = bm + obj.F*(pm1 - pm2 + pm3 - pm4);  % differential variation
                ui = popold.*mpo + ui.*mui;           % crossover
              elseif (st == 5)                  % DE/rand/2
                ui = pm5 + obj.F*(pm1 - pm2 + pm3 - pm4);  % differential variation
                ui = popold.*mpo + ui.*mui;            % crossover
              end

            %-----Select which vectors are allowed to enter the new population------------
              for i=1:obj.NP
                [tempval,OutputWeight] = obj.eelm_x(Elm_Type,ui(i,:),P,T,T_org,T_ceros,NumberofHiddenNeurons);   % check cost of competitor
                nfeval  = nfeval + 1;
                if (tempval <= val(i))  % if competitor is better than value in "cost array"
                   pop(i,:) = ui(i,:);  % replace old vector with new one (for new iteration)
                   val(i)   = tempval;  % save value in "cost array"

                   %----we update bestval only in case of success to save time-----------
                   if bestval-tempval>obj.tolerance*bestval
                       bestval = tempval;      % new best value
                       bestmem = ui(i,:);      % new best parameter vector ever
                       bestweight = OutputWeight;
                   elseif abs(tempval-bestval)<obj.tolerance*bestval    % if competitor better than the best one ever
                       if norm(OutputWeight,2)<norm(bestweight,2)
                            bestval = tempval;      % new best value
                            bestmem = ui(i,:);      % new best parameter vector ever
                            bestweight = OutputWeight;
                       end
                   end
                end
              end %---end for imember=1:obj.NP

              bestmemit = bestmem;       % freeze the best member of this iteration for the coming 
                                         % iteration. This is needed for some of the strategies.

            %----Output section----------------------------------------------------------

            %  if (refresh > 0)
            %    if (rem(iter,refresh) == 0)
            %       fprintf(1,'Iteration: %d,  Best: %f,  F: %f,  CR: %f,  obj.NP: %d\n',iter,bestval,F,CR,obj.NP);
            %%%        for n=1:D
            %%%          fprintf(1,'best(%d) = %f\n',n,bestmem(n));
            %%%        end
            %    end
            %  end

%                if (rem(iter,obj.refresh) == 0)
%                   refreshIt = refreshIt + 1;
% 
%                   [OutputWeight,CCRTrain, MSTrain,CCRTest, MSTest] = ...
%                     getBestEvaluation(bestmem,P,T,TV,T_org,TV_org,NumberofHiddenNeurons,obj.activationFunction,obj.FitnessFunction,obj.lambda,bestweight);
% 
%                   itResults{refreshIt,1} = [iter obj.itermax mean(CCRTrain) std(CCRTrain) mean(MSTrain) std(MSTrain) ...
%                                     mean(CCRTest) std(CCRTest) mean(MSTest) std(MSTest)];
%                end

              iter = iter + 1;
            end %---end while ((iter < itermax) ...

            %%%%%%%%%%% Calculate output weights OutputWeight (beta_i)

            %OutputWeight=pinv(H') * T';                        % slower implementation
            % OutputWeight=inv(H * H') * H * T';                         % faster implementation


            model.activationFunction = obj.activationFunction;
            model.hiddenN = obj.parameters.hiddenN;
            model.InputWeight = bestmem;
            model.OutputWeight = bestweight;
            model.algorithm = 'EELM';
            model.parameters = parameters;
            
            obj.model = model;
            [projectedTrain, predictedTrain] = obj.predict(test);

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: test (Public)
        % Description: This function test a model given
        %               a set of test patterns.
        % Type: [Array, Array]
        % Arguments: 
        %           test.patterns --> Testing data
        %           projection --> Projection previously 
        %                       calculated fitting the model
        %           thresholds --> Thresholds previously 
        %                       calculated fitting the model
        %           train.patterns --> Trainning data (needed
        %                              for the gram matrix)
        %           kernelParam --> kernel parameter for SVRPCDOC
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [Y, TestPredictedY]= test(obj, test, model)

            if nargin < 3 
                model = obj.model;
            end
            
            % TODO: parametrice
            Elm_Type = 1;
            
            P = test.patterns';

            NumberofInputNeurons=size(P, 1);
            NumberofTrainingData=size(P, 2);
            Gain=1;
            temp_weight_bias=reshape(model.InputWeight, model.hiddenN, NumberofInputNeurons+1);
            InputWeight=temp_weight_bias(:, 1:NumberofInputNeurons);

            switch lower(model.activationFunction)
                case {'sig','sigmoid'}
                    BiasofHiddenNeurons=temp_weight_bias(:,NumberofInputNeurons+1);
                    tempH=InputWeight*P;
                    ind=ones(1,NumberofTrainingData);
                    BiasMatrix=BiasofHiddenNeurons(:,ind);      %   Extend the bias matrix BiasofHiddenNeurons to match the demention of H
                    tempH=tempH+BiasMatrix;
                    clear BiasMatrix
                    H = 1 ./ (1 + exp(-Gain*tempH));
                    clear tempH;

                case {'up'}
                    % Calculate H matrix for UP
                    H = zeros(NumberofHiddenNeurons,NumberofTrainingData);
                    temp = zeros(NumberofInputNeurons,1);
                    for i = 1 : NumberofTrainingData
                        for j = 1 : NumberofHiddenNeurons
                            for n = 1: NumberofInputNeurons
                                temp(n) = InputWeight(j,n)*(P(n,i));
                            end
                            H(j,i) =  sum(temp);
                        end
                    end

                    clear temp;

                case {'rbf'}
                    P = P';
                    W10 = temp_weight_bias(:,NumberofInputNeurons+1)';
                    W1 = InputWeight;
                    % TODO: Un hack
                    H = zeros(NumberofTrainingData,model.hiddenN);
                    for j=1:model.hiddenN
                        H(:,j)=EELM.gaussian_func(P,W1(j,:),W10(1,j));
                        %KM.valueinit(:,j)=gaussian_func(x,W1(j,:),W10(1,j));
                    end
                    H = H';
            end

            Y=(H' * model.OutputWeight)';
            %TY=(H_test' * model.bestweight)';

            if Elm_Type == 0
                TrainingAccuracy=sqrt(mse(T - Y));
                %TestingAccuracy=sqrt(mse(TV.T - TY));            %   Calculate testing accuracy (RMSE) for regression case
            end

            switch (obj.classifier)
                case {'nominal'}
                    [FOO, TestPredictedY] = max(Y);
                    %TY = -1*ones(size(TestPredictedY)); % Dummy value
                case {'ordinal'}
					% Otra alternativa
					% Q = size(model.OutputWeight,2);
                    % uniqueTargets = tril(2*ones(Q)) + -1*ones(Q);
                    % TestPredictedY = obj.orelmToLabel(TY',uniqueTargets);

                    TestPredictedY = obj.orelmToLabel(Y', test.uniqueTargetsOrelm);
                    %TY = -1*ones(size(TestPredictedY)); % Dummy value
                case {'ordinalRegress'}
                    TestPredictedY = obj.regressToLabel(Y', test.uniqueTargets);
                case {'ordinalRegressScaled'}
                    TestPredictedY = obj.regressToLabel(Y',test.uniqueTargets);
                case {'regression','regressionLatent'}
                    TestPredictedY = Y;
            end
            
            TestPredictedY = TestPredictedY';

        end

    end
    
    methods(Access = private)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: orelmToLabel (Private)
        % Description: 
        % Type: 
        % Arguments: 
        %           trainSet--> Array of training patterns
        %           testSet--> Array of testing patterns
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [finalOutput,expLosses] = orelmToLabel(obj,predictions,uniqueNewTargets)
            
            % Distancia Euclidea
            %            finalOutput = zeros(1,size(predictions,1));
            %            distancias = zeros(1,size(predictions,2));
            
            %             for i=1:size(predictions,1),
            %                 for j=1:size(predictions,2),
            %                     distancias(j) = pdist([predictions(i,:);uniqueNewTargets(j,:)]);
            %                 end
            %                 [FOO,finalOutput(i)] = min(distancias);
            %             end
            
            % Minimal Exponential Loss
            expLosses=zeros(size(predictions));
            
            for i=1:size(predictions,2),
                expLosses(:,i) = sum(exp(-predictions.*repmat(uniqueNewTargets(i,:),size(predictions,1),1)),2);
            end
            
            [minVal,finalOutput] = min(expLosses,[],2);
            finalOutput = finalOutput';
        end
        


        function [trainSet, testSet] = labelToOrelm(obj,trainSet,testSet)
            %uniqueTargets = unique([trainSet.targets; testSet.targets]);

            %   newTargets = zeros(trainSet.nOfPatterns,trainSet.nOfClasses);
            trainSet.targetsOrelm = ones(trainSet.nOfPatterns,trainSet.nOfClasses);
            testSet.targetsOrelm = ones(testSet.nOfPatterns,trainSet.nOfClasses);
            
            for i=1:trainSet.nOfClasses,
                trainSet.targetsOrelm(trainSet.targets<trainSet.uniqueTargets(i),i) = -1;
                testSet.targetsOrelm(testSet.targets<trainSet.uniqueTargets(i),i) = -1;
            end
           
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: labelToBinary (Private)
        % Description: 
        % Type: 
        % Arguments: 
        %           trainSet--> Array of training patterns
        %           testSet--> Array of testing patterns
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [trainSet, testSet] = labelToBinary(obj,trainSet,testSet)
            % Adapt labels to Matlab's newff / ELM / etc. 

            % NOTE: This option based on full + ind2vec is not valid since 
            % it have problems if a datasets do not have patterns of a
            % given class
            %DataSet.TrainTT = full(ind2vec(DataSet.TrainT'));
            %DataSet.TestTT = full(ind2vec(DataSet.TestT'));

            trainN = size(trainSet.targets,1);
            TT = zeros(trainN,trainSet.nOfClasses);
            for ii=1:trainN
                TT(ii,trainSet.targets(ii,1)) = 1;
            end

            trainSet.targetsBinary = TT;

            testN = size(testSet.targets,1);
            TT = zeros(testN,testSet.nOfClasses);
            for ii=1:testN
                TT(ii,testSet.targets(ii,1)) = 1;
            end

            testSet.targetsBinary = TT;

            clear trainN testN TT;
        end
        
        function [Fitness,OutputWeight] = eelm_x (obj,Elm_Type, weight_bias, P, T, T_org, T_ceros, NumberofHiddenNeurons)

            NumberofInputNeurons=size(P, 1);
            NumberofTrainingData=size(P, 2);
            NumberofOutputNeurons=size(T, 1);
            %NumberofTestingData=size(TV.P, 2);

            temp_weight_bias=reshape(weight_bias, NumberofHiddenNeurons, NumberofInputNeurons+1);
            InputWeight=temp_weight_bias(:, 1:NumberofInputNeurons);

            switch lower(obj.activationFunction)
                case {'sig','sigmoid'}
                    Gain=1;
                    BiasofHiddenNeurons=temp_weight_bias(:,NumberofInputNeurons+1);
                    tempH=InputWeight*P;
                    ind=ones(1,NumberofTrainingData);
                    BiasMatrix=BiasofHiddenNeurons(:,ind);      %   Extend the bias matrix BiasofHiddenNeurons to match the demention of H
                    tempH=tempH+BiasMatrix;
                    H = 1 ./ (1 + exp(-Gain*tempH));
                    %clear temp_weight_bias Gain BiasofHiddenNeurons ind BiasMatrix tempH;
                case {'up'}
                    % TODO: Esto sólo habría que calcularlo cuando se vaya a escribir el
                    % log
                    %     tempH_test=InputWeight*TV.P;
                    %     ind=ones(1,NumberofTestingData);
                    %     BiasMatrix=BiasofHiddenNeurons(:,ind);      %   Extend the bias matrix BiasofHiddenNeurons to match the demention of H
                    %     tempH_test=tempH_test + BiasMatrix;
                    %     H_test = 1 ./ (1 + exp(-Gain*tempH_test));
                        % </Sig>

                    H = zeros(NumberofHiddenNeurons,NumberofTrainingData);
                    for i = 1 : NumberofTrainingData
                        for j = 1 : NumberofHiddenNeurons
                            temp = zeros(NumberofInputNeurons,1);
                            for n = 1: NumberofInputNeurons
                                temp(n) = InputWeight(j,n)*P(n,i);
                            end
                            H(j,i) =  sum(temp);
                        end
                    end

                    clear temp;

                case {'rbf'}
                    P = P';
                    W10 = temp_weight_bias(:,NumberofInputNeurons+1)';
                    W1 = InputWeight;
                    % TODO: Un hack
                    H = zeros(NumberofTrainingData,NumberofHiddenNeurons);
                    for j=1:NumberofHiddenNeurons
                        H(:,j)=EELM.gaussian_func(P,W1(j,:),W10(1,j));
                        %KM.valueinit(:,j)=EELM.gaussian_func(x,W1(j,:),W10(1,j));
                    end
                    P = P';
                    H = H';
                    %InputWeight = [W1 W10'];
            end

            OutputWeight=pinv(H') * T';
            Y=(H' * OutputWeight)';

            clear H;

            if Elm_Type == 1
                if strcmp(obj.classifier, 'ordinal')
                    uniqueTargetsOrelm = unique(T','rows');                    
                    [LabelTrainPredicted,expLosses] = obj.orelmToLabel(Y', uniqueTargetsOrelm);
                    LabelTrainPredicted = LabelTrainPredicted';
                else
                    if strcmp(obj.FitnessFunction, 'ccr') || strcmp(obj.FitnessFunction, 'ms') ...
                        || strcmp(obj.FitnessFunction, 'ccrs_cs') || strcmp(obj.FitnessFunction, 'mae') ...
                        || strcmp(obj.FitnessFunction, 'amae')
                    
                        [winnerTrain LabelTrainPredicted] = max(Y);

                        LabelTrainPredicted = LabelTrainPredicted';
                        LabelTrainPredicted = LabelTrainPredicted -1;        

                        ConfusionMatrixTrain = obj.confmat(T_org',LabelTrainPredicted);

                    end
                end

                switch lower(obj.FitnessFunction)
                    case {'mae'}
                        Fitness = MAE.calculateMetric(T_org,LabelTrainPredicted);
                    case {'amae'}
                        Fitness = AMAE.calculateMetric(T_org,LabelTrainPredicted);
                    case {'ccr'}
                        CCRTrain = EELM.CCR(ConfusionMatrixTrain);
                        Fitness = 1-CCRTrain;
                    case {'ms'}
                        MSTrain = EELM.Sensitivity(ConfusionMatrixTrain);
                        Fitness = 1-MSTrain;
                    case {'ccrs_cs'}
                        CCRTrain = EELM.CCR(ConfusionMatrixTrain);
                        MSTrain = EELM.Sensitivity(ConfusionMatrixTrain);
                        Fitness = (1-obj.lambda)*CCRTrain + obj.lambda*MSTrain;
                        Fitness = 1-Fitness;
                    case {'ccrs_r'}
                        rmse_class = zeros(NumberofOutputNeurons,1);
                        patterns_class = zeros(NumberofOutputNeurons,1);

                        STrain = obj.softmaxnn(Y');

                        for j = 1:NumberofOutputNeurons
                            ind_class = T_org==(j-1);
                            S_class = STrain(ind_class,:);
                            T_class = T_ceros(:,ind_class)';

                            patterns_class(j) = size(T_class,1);

                            rmse_class(j) = ...
                                sqrt(sum(sum((T_class - S_class).^2))/(patterns_class(j)*NumberofOutputNeurons));
                        end

                        % Get minimum RMSE per class
                        maxrmse = max(rmse_class);

                        % Get total RMSE
                        total_rmse = (sum(patterns_class.*rmse_class)) / (NumberofTrainingData);

                        Fitness = (1-obj.lambda)*(1/(1+total_rmse)) + obj.lambda*(1/(1+maxrmse));
                        Fitness = 1-Fitness;
                    case {'ccrs_e'}
                        entropy_class = zeros(NumberofOutputNeurons,1);
                        patterns_class = zeros(NumberofOutputNeurons,1);

                        STrain = obj.softmaxnn(Y');

                        for j = 1:NumberofOutputNeurons
                            ind_class = T_org==(j-1);
                            S_class = STrain(ind_class,:);
                            T_class = T_ceros(:,ind_class)';

                            patterns_class(j) = size(T_class,1);

                            entropy_class(j) = ...
                                -sum(sum((T_class.*log(S_class))))/(patterns_class(j));

                        end

                        % Get minimum RMSE per class
                        maxentropy = max(entropy_class);

                        % Get total RMSE
                        total_entropy = (sum(patterns_class.*entropy_class)) / (NumberofTrainingData);

                        Fitness = (1-obj.lambda)*(1/(1+total_entropy)) + obj.lambda*(1/(1+maxentropy));
                        Fitness = 1-Fitness;
                    case {'wrmse'}
                        S=obj.softmaxnn(-expLosses);
                        cost = abs(repmat(1:NumberofOutputNeurons,NumberofOutputNeurons,1) - ...
                                repmat((1:NumberofOutputNeurons)',1,NumberofOutputNeurons));
                        cost = cost+1;
                        TestB=full(ind2vec(T_org'))';
                        error=(S-TestB).^2;
                        we = zeros(size(TestB));

                        for pp=1:NumberofTrainingData
                            c = cost(T_org(pp),:);
                            we(pp,:) = c*error(pp,:)';
                        end
                        
                        %sqrt(sum(sum(error)) / (NumberofInputNeurons*NumberofOutputNeurons) )
                        Fitness = sqrt(sum(sum(we)) / (NumberofInputNeurons*NumberofOutputNeurons));
                        
                end

            else % regression
                Fitness=sqrt(mse(T - Y));
            end

            clear NumberofInputNeurons NumberofHiddenNeurons NumberofTrainingData
        end
        
        function c = confmat(obj,x,y)

            minx = min(x);
            maxx = max(x);

            c = zeros(maxx-minx);
            for i = minx:maxx
               index = x == i;
               for j = minx:maxx
                  z = y(index);
                  c(i-minx+1,j-minx+1) = length(find(z == j));
               end
            end
        end
        
        function s = softmaxnn(obj,X)

            t = sum(exp(X'));
            ind=ones(1,size(X,2));
            pt = t(ind,:)';

            % extend matrix
            pc = exp(X);

            s = pc ./ pt;
        end
    end
        
    methods (Static = true)

        function CCR = CCR(C)
            CCR = sum(diag(C))/sum(sum(C)); 
        end
        
        function [MS, class, nOfBadPatterns] = Sensitivity(C)

            MS = 1.0;
            %class = -1.0;
            nOfBadPatterns = 0;
            for i=1:length(C)
                nOfPatterns = 0;
                for j=1: length(C)
                    nOfPatterns = nOfPatterns + C(i,j);
                end;
                sensitivity = C(i,i) / nOfPatterns;

                if(sensitivity < MS)
                    MS = sensitivity;
                    %class = i;
                    %nOfBadPatterns = nOfPatterns;
                end

            end
        end
        
        function result=gaussian_func(x,c,sig)

            result=exp(-mean(abs((x-ones(size(x,1),1)*c)).^2,2)/sig^2);
        end


    end
    
end
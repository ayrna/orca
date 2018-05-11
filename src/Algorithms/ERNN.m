% NOTE:
% - This code is based on the code of Qin-Yu Zhu et. al corresponding to the
%   paper "Evolutionary Extreme Learning Machine" [3]. The code of Qin-Yu
%   Zhu is based on the code of Kenneth Price and Rainer Storn available at
%   http://www1.icsi.berkeley.edu/~storn/code.html#matl
% - We use to term Randomized Neural Network (RNN) as equivalent term for Extreme
%   Learning Machine (ELM). After reading several discussion about the
%   controversy of the term, we think this is the most precise and fair
%   term.
% - As a disclaimer, THE CODE IS NOT CLEAN ENOUGHT (since the
%   original code is not), however I prefer to publish the code.
% - Author Javier Sánchez Monedero (jsanchezm at uco.es)
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
    
    %   Citation: If you use this code, please cite the associated papers
    %   [1,2,3]
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    %
    %   Documentation of DE parameters:
    %   minimization of a user-supplied function with respect to x(1:D),
    %   using the differential evolution (DE) algorithm of Rainer Storn
    %   (http://www.icsi.berkeley.edu/~storn/code.html)
    %
    %   Special thanks go to Ken Price (kprice@solano.community.net) and
    %   Arnold Neumaier (http://solon.cma.univie.ac.at/~neum/) for their
    %   valuable contributions to improve the code.
    %
    %   Strategies with exponential crossover, further input variable
    %   tests, and arbitrary function name implemented by Jim Van Zandt
    %   <jrv@vanzandt.mv.com>, 12/97.
    %
    %   Output arguments:
    %   ----------------
    %   bestmem    parameter vector with best solution
    %   bestval    best objective function value
    %   nfeval     number of function evaluations
    %
    %   Input arguments:
    %   ---------------
    %
    %   fname      string naming a function f(x,y) to minimize
    %   VTR        "Value To Reach". devec3 will stop its minimization
    %          if either the maximum number of iterations "itermax"
    %          is reached or the best parameter vector "bestmem"
    %          has found a value f(bestmem,y) <= VTR.
    %   D          number of parameters of the objective function
    %   XVMin      vector of lower bounds XVMin(1) ... XVMin(D)
    %          of initial population
    %          *** note: these are not bound constraints!! ***
    %   XVMax      vector of upper bounds XVMax(1) ... XVMax(D)
    %          of initial population
    %   y		    problem data vector (must remain fixed during the
    %          minimization)
    %   NP         number of population members
    %   itermax    maximum number of iterations (generations)
    %   F          DE-stepsize F from interval [0, 2]
    %   CR         crossover probability constant from interval [0, 1]
    %   strategy       1 --> DE/best/1/exp       6 --> DE/best/1/bin
    %          2 --> DE/rand/1/exp       7 --> DE/rand/1/bin
    %          3 --> DE/rand-to-best/1/exp   8 --> DE/rand-to-best/1/bin
    %          4 --> DE/best/2/exp       9 --> DE/best/2/bin
    %          5 --> DE/rand/2/exp       else  DE/rand/2/bin
    %          Experiments suggest that /bin likes to have a slightly
    %          larger CR than /exp.
    %   refresh    intermediate output will be produced after "refresh"
    %          iterations. No intermediate output will be produced
    %          if refresh is < 1
    %
    %         The first four arguments are essential (though they have
    %         default values, too). In particular, the algorithm seems to
    %         work well only if [XVMin,XVMax] covers the region where the
    %         global minimum is expected. DE is also somewhat sensitive to
    %         the choice of the stepsize F. A good initial guess is to
    %         choose F from interval [0.5, 1], e.g. 0.8. CR, the crossover
    %         probability constant from interval [0, 1] helps to maintain
    %         the diversity of the population and is rather uncritical. The
    %         number of population members NP is also not very critical. A
    %         good initial guess is 10*D. Depending on the difficulty of the
    %         problem NP can be lower than 10*D or must be higher than 10*D
    %         to achieve convergence.
    %         If the parameters are correlated, high values of CR work better.
    %         The reverse is true for no correlation.
    %
    %   default values in case of missing input arguments:
    %   	VTR = 1.e-6;
    %   	D = 2;
    %   	XVMin = [-2 -2];
    %   	XVMax = [2 2];
    %	y=[];
    %   	NP = 10*D;
    %   	itermax = 200;
    %   	F = 0.8;
    %   	CR = 0.5;
    %   	strategy = 7;
    %   	refresh = 10;
    %
    %   Cost function:  	function result = f(x,y);
    %                	has to be defined by the user and is minimized
    %			w.r. to  x(1:D).
    %
    %   Example to find the minimum of the Rosenbrock saddle:
    %   ----------------------------------------------------
    %   Define f.m as:
    %              function result = f(x,y);
    %              result = 100*(x(2)-x(1)^2)^2+(1-x(1))^2;
    %              end
    %   Then type:
    %
    %   	VTR = 1.e-6;
    %   	D = 2;
    %   	XVMin = [-2 -2];
    %   	XVMax = [2 2];
    %   	[bestmem,bestval,nfeval] = devec3("f",VTR,D,XVMin,XVMax);
    %
    %   The same example with a more complete argument list is handled in
    %   run1.m
    %
    %   About devec3.m
    %   --------------
    %   Differential Evolution for MATLAB
    %   Copyright (C) 1996, 1997 R. Storn
    %   International Computer Science Institute (ICSI)
    %   1947 Center Street, Suite 600
    %   Berkeley, CA 94704
    %   E-mail: storn@icsi.berkeley.edu
    %   WWW:    http://http.icsi.berkeley.edu/~storn
    %
    %   devec is a vectorized variant of DE which, however, has a
    %   propertiy which differs from the original version of DE:
    %   1) The random selection of vectors is performed by shuffling the
    %      population array. Hence a certain vector can't be chosen twice
    %      in the same term of the perturbation expression.
    %
    %   Due to the vectorized expressions devec3 executes fairly fast
    %   in MATLAB's interpreter environment.
    %
    %   This program is free software; you can redistribute it and/or modify
    %   it under the terms of the GNU General Public License as published by
    %   the Free Software Foundation; either version 1, or (at your option)
    %   any later version.
    %
    %   This program is distributed in the hope that it will be useful,
    %   but WITHOUT ANY WARRANTY; without even the implied warranty of
    %   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    %   GNU General Public License for more details. A copy of the GNU
    %   General Public License can be obtained from the
    %   Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
    %
    
    properties
        description = 'Evolutionary Randomized Neural Network';
        
        % ARR parameters
        activationFunction = 'sig';
        % Input Weights range
        wMin = -1;
        wMax = 1;
        
        % type of ARNN model: 'ordinal' / 'nominal'
        classifier = 'nominal'
        
        % fitness function to guide the evolutionary search (see [1] and
        % [2])
        FitnessFunction = 'ccrs_r';
        lambda = 0.3;
        
        % Differential Evolution parameteres
        NP=40;
        itermax=50;
        refresh=100;
        
        CR=0.8;
        strategy = 3;
        F=1;
        tolerance = 0.02;
        
        % hyper-parameters to optimize via grid search or equivalent methods
        parameters = struct('hiddenN', 20);
    end
    
    
    methods
        
        function obj = ERNN(varargin)
            %ERNN constructs an object of the class ERNN and sets its default
            %   characteristics
            obj.parseArgs(varargin);
        end
        
        function obj = set.classifier(obj,value)
            if ~(strcmpi(value,'nominal') || strcmpi(value,'ordinal'))
                error('Invalid value for classifier');
            else
                obj.classifier = value;
            end
        end
        
        function obj = set.activationFunction(obj,value)
            if ~(strcmpi(value,'sig') || strcmpi(value,'rbf'))
                error('Invalid value for activationFunction');
            else
                obj.activationFunction = value;
            end
        end
        
        function [projectedTrain, predictedTrain] = privfit( obj,train, parameters)
            
            obj.model.uniqueTargets = unique(train.targets);
            obj.model.nOfClasses = max(obj.model.uniqueTargets);
            obj.model.nOfTrPatterns = length(train.targets);
            
            switch(obj.classifier)
                case {'nominal'}
                    train.targetsBinary = ERNN.labelToBinary(train.targets, obj.model.nOfClasses);
                case {'ordinal'}
                    train.targetsOrelm = ERNN.labelToOrelm(train.targets, obj.model.nOfClasses);
                    obj.model.uniqueTargetsOrelm = unique(train.targetsOrelm,'rows');
            end
            
            if( strcmp(obj.activationFunction,'rbf') && parameters.hiddenN > obj.model.nOfTrPatterns)
                disp(['User''s number of hidden neurons ' num2str(parameters.hiddenN) ...
                    ' was too high and has been adjusted to the number of training patterns']);
                obj.parameters.hiddenN = obj.model.nOfTrPatterns;
            else
                obj.parameters.hiddenN = parameters.hiddenN;
            end
            
            %  Classifier
            Elm_Type = 1;
            
            % Copy parameters (TODO: clean)
            NumberofHiddenNeurons = obj.parameters.hiddenN;
            obj.lambda = obj.lambda;
            
            obj.activationFunction = obj.activationFunction;
            
            P = train.patterns';
            
            switch(obj.classifier)
                case {'nominal'}
                    T = train.targetsBinary;
                    T=T*2-1; % Map tags values to -1, 1
                case {'ordinal'}
                    T = train.targetsOrelm;
            end
            
            T = T';
            
            T_ceros = T;
            T_ceros(T_ceros==-1)=0;
            T_org = train.targets;
            
            NumberofTrainingData=size(P,2);
            NumberofInputNeurons=size(P,1);
            %NumberofOutputNeurons = obj.model.nOfClasses;
            
            D=NumberofHiddenNeurons*(NumberofInputNeurons+1);
            
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
            elseif strcmp(obj.activationFunction,'rbf')
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
            
            popold    = zeros(size(pop));     % toggle population
            val       = zeros(1,obj.NP);          % create and reset the "cost array"
            bestmem   = zeros(1,D);           % best population member ever
            bestmemit = zeros(1,D);           % best population member in iteration
            nfeval    = 0;                    % number of function evaluations
            brk    = 0;
            
            
            %------Evaluate the best member after initialization----------------------
            
            ibest   = 1;  % start with first population member
            
            [val(1),OutputWeight]  = obj.ERNN_x(Elm_Type,pop(ibest,:),P,T,T_org,T_ceros,NumberofHiddenNeurons);
            bestval = val(1);                 % best objective function value so far
            nfeval  = nfeval + 1;
            bestweight = OutputWeight;
            for i=2:obj.NP                        % check the remaining members
                [val(i),OutputWeight] = obj.ERNN_x(Elm_Type,pop(i,:),P,T,T_org,T_ceros,NumberofHiddenNeurons);
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
                    [tempval,OutputWeight] = obj.ERNN_x(Elm_Type,ui(i,:),P,T,T_org,T_ceros,NumberofHiddenNeurons);   % check cost of competitor
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
                
                iter = iter + 1;
            end %---end while ((iter < itermax) ...
            
            %%%%%%%%%%% Calculate output weights OutputWeight (beta_i)
            obj.model.activationFunction = obj.activationFunction;
            obj.model.hiddenN = obj.parameters.hiddenN;
            obj.model.parameters = parameters;
            
            obj.model.InputWeight = bestmem;
            obj.model.OutputWeight = bestweight;
            
            [projectedTrain, predictedTrain] = obj.predict(train.patterns);
        end
        
        function [Y, TestPredictedY]= privpredict(obj, test)
            
            % TODO: parametrice to allow regression models.
            Elm_Type = 1;
            
            P = test';
            
            NumberofInputNeurons=size(P, 1);
            NumberofTrainingData=size(P, 2);
            Gain=1;
            temp_weight_bias=reshape(obj.model.InputWeight, obj.model.hiddenN, NumberofInputNeurons+1);
            InputWeight=temp_weight_bias(:, 1:NumberofInputNeurons);
            
            switch lower(obj.model.activationFunction)
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
                    W10 = temp_weight_bias(:,NumberofInputNeurons+1)';
                    W1 = InputWeight;
                    H = zeros(NumberofTrainingData,obj.model.hiddenN);
                    for j=1:obj.model.hiddenN
                        H(:,j)=ERNN.gaussian_func(P',W1(j,:),W10(1,j));
                    end
                    H = H';
            end
            
            Y=(H' * obj.model.OutputWeight)';
            
            if Elm_Type == 0
                TrainingAccuracy=sqrt(mse(T - Y));
            end
            
            switch (obj.classifier)
                case {'nominal'}
                    [FOO, TestPredictedY] = max(Y);
                case {'ordinal'}
                    TestPredictedY = ERNN.orelmToLabel(Y', obj.model.uniqueTargetsOrelm);
            end
            
            TestPredictedY = TestPredictedY';
            
        end
        
    end
    
    methods(Access = private)
        
        function [Fitness,OutputWeight] = ERNN_x (obj,Elm_Type, weight_bias, P, T, T_org, T_ceros, NumberofHiddenNeurons)
            
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
                case {'rbf'}
                    W10 = temp_weight_bias(:,NumberofInputNeurons+1)';
                    W1 = InputWeight;
                    H = zeros(NumberofTrainingData,NumberofHiddenNeurons);
                    for j=1:NumberofHiddenNeurons
                        H(:,j)=ERNN.gaussian_func(P',W1(j,:),W10(1,j));
                    end
                    H = H';
            end
            
            OutputWeight=pinv(H') * T';
            Y=(H' * OutputWeight)';
            
            clear H;
            
            if Elm_Type == 1
                if strcmp(obj.classifier, 'ordinal')
                    [LabelTrainPredicted,expLosses] = ERNN.orelmToLabel(Y', obj.model.uniqueTargetsOrelm);
                    LabelTrainPredicted = LabelTrainPredicted';
                else
                    if strcmp(obj.FitnessFunction, 'ccr') || strcmp(obj.FitnessFunction, 'ms') ...
                            || strcmp(obj.FitnessFunction, 'ccrs_cs') || strcmp(obj.FitnessFunction, 'mae') ...
                            || strcmp(obj.FitnessFunction, 'amae')
                        
                        [winnerTrain LabelTrainPredicted] = max(Y);
                        
                        LabelTrainPredicted = LabelTrainPredicted';
                        LabelTrainPredicted = LabelTrainPredicted -1;
                        
                        ConfusionMatrixTrain = ERNN.confmat(T_org',LabelTrainPredicted);
                        
                    end
                end
                
                switch lower(obj.FitnessFunction)
                    case {'mae'}
                        Fitness = MAE.calculateMetric(T_org,LabelTrainPredicted);
                    case {'amae'}
                        Fitness = AMAE.calculateMetric(T_org,LabelTrainPredicted);
                    case {'ccr'}
                        CCRTrain = CCR.calculateMetric(T_org,LabelTrainPredicted);
                        Fitness = 1-CCRTrain;
                    case {'ms'}
                        MSTrain = MS.calculateMetric(T_org,LabelTrainPredicted);
                        Fitness = 1-MSTrain;
                    case {'ccrs_cs'}
                        CCRTrain = CCR.calculateMetric(ConfusionMatrixTrain);
                        MSTrain = MS.calculateMetric(ConfusionMatrixTrain);
                        Fitness = (1-obj.lambda)*CCRTrain + obj.lambda*MSTrain;
                        Fitness = 1-Fitness;
                    case {'ccrs_r'}
                        rmse_class = zeros(NumberofOutputNeurons,1);
                        patterns_class = zeros(NumberofOutputNeurons,1);
                        
                        STrain = ERNN.softmaxnn(Y');
                        
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
                        
                        STrain = ERNN.softmaxnn(Y');
                        
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
                        S=ERNN.softmaxnn(-expLosses);
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
                        
                        Fitness = sqrt(sum(sum(we)) / (NumberofInputNeurons*NumberofOutputNeurons));
                end
                
            else % regression
                Fitness=sqrt(mse(T - Y));
            end
            
            clear NumberofInputNeurons NumberofHiddenNeurons NumberofTrainingData
        end
    end
    
    methods (Static = true)
        
        function [finalOutput,expLosses] = orelmToLabel(predictions,uniqueNewTargets)
            
            % Minimal Exponential Loss
            expLosses=zeros(size(predictions));
            
            for i=1:size(predictions,2)
                expLosses(:,i) = sum(exp(-predictions.*repmat(uniqueNewTargets(i,:),size(predictions,1),1)),2);
            end
            
            [minVal,finalOutput] = min(expLosses,[],2);
            finalOutput = finalOutput';
        end
        
        function [targetsOrelm] = labelToOrelm(labels,nOfClasses)
            uniqueTargets = unique(labels);
            %   newTargets = zeros(trainSet.nOfPatterns,trainSet.nOfClasses);
            trainN = size(labels,1);
            targetsOrelm = ones(trainN,nOfClasses);
            for i=1:nOfClasses
                targetsOrelm(labels<uniqueTargets(i),i) = -1;
            end
            
        end
        
        
        function [targetsBinary] = labelToBinary(labels,nOfClasses)
            % Adapts labels to Matlab's newff / ELM / etc.
            
            % NOTE: The code could be simplier with:
            % full(ind2vec(dataset.targets'));
            % However it fails in extreme imbalanced problems if a dataset
            % does not have patterns of a class
            
            trainN = size(labels,1);
            targetsBinary = zeros(trainN,nOfClasses);
            for ii=1:trainN
                targetsBinary(ii,labels(ii,1)) = 1;
            end
        end
        
        function c = confmat(x,y)
            
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
        
        function s = softmaxnn(X)
            
            t = sum(exp(X'));
            ind=ones(1,size(X,2));
            pt = t(ind,:)';
            
            % extend matrix
            pc = exp(X);
            
            s = pc ./ pt;
        end
        
        function CCR = CCR(C)
            CCR = sum(diag(C))/sum(sum(C));
        end
        
        function [MS, class, nOfBadPatterns] = Sensitivity(C)
            
            MS = 1.0;
            class = -1.0;
            nOfBadPatterns = 0;
            for i=1:length(C)
                nOfPatterns = 0;
                for j=1: length(C)
                    nOfPatterns = nOfPatterns + C(i,j);
                end
                sensitivity = C(i,i) / nOfPatterns;
                
                if(sensitivity < MS)
                    MS = sensitivity;
                    class = i;
                    %nOfBadPatterns = nOfPatterns;
                end
                
            end
        end
        
        function result=gaussian_func(x,c,sig)
            result=exp(-mean(abs((x-ones(size(x,1),1)*c)).^2,2)/sig^2);
        end
    end
end
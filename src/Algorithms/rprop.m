% RPROP Unconstrained local minimization using Rprop
%   [X,E,EXITFLAG,STATS] = RPROP(FUNCGRAD,X0,PARAMETERS,VARARGIN) Minimize a
%   function FUNCGRAD starting from the parameters X0. Optionally a
%   structure PARAMETERS can be used to override the default parameters.
%   Each additional parameter VARARGIN will be passed to function FUNCGRAD.
%   The function returns the optimized parameters X, the final objective
%   value E, a flag EXITFLAG that encodes the condition that triggered the
%   end of the optimization process and at last a structure STATS that
%   contain various information about the optimization process itself.
%
%   FUNCGRAD:       Function or handle to function. Must take the form
%                   [F,G] = FUNCGRAD(X) where
%                   X:      Parameters
%                   F:      [1 x 1] Objective value
%                   G:      [size(X)] Gradient
%
%   X0:             Can be either a matrix or a cell of matrices
%
%  	PARAMETERS:
%    	method:     Rprop method used, accepts {'Rprop+','Rprop-',
%                   'IRprop+','IRprop-'}.
%                   [Default = 'IRprop-']
%     	MaxIter:    Stop criterion 0: Maximum number of iterations, accepts
%                   numeric values.
%                   [Default = 100]
%     	d_Obj:      Stop criterion 1: Minimum Objective value, accepts
%                   numeric values.
%                   [Default = 10e-12]
%       d_time:     Stop criterion 2: Maximum time, accepts numeric values
%                   or {inf}.
%                   [Default = inf]
%     	Tolfun:     Stop criterion 3: Minimum Delta of value, accepts
%                   numeric values (p.Tolfun is valid only if the
%                   difference is negative, i.e. if the objective value get
%                   better really slowly, but not if it get worst).
%                   [Default = 0]
%     	TolX:       Stop criterion 3: Minimum Delta of value, accepts
%                   numeric values (p.Tolfun is valid only if the
%                   difference is negative, i.e. if the objective value get
%                   better really slowly, but not if it get worst).
%                   [Default = 0]
%      	mu_neg:     Rprop's decrease factor.
%                   [Default = 0.5]
%      	mu_pos:     Rprop's increase factor.
%                   [Default = 1.2]
%      	delta0:     Rprop's initial update-value.
%                   [Default = 0.0123]
%     	delta_min:  Rprop's lower bound for step size.
%                   [Default = 0]
%      	delta_max:  Rprop's upper bound for step size.
%                   [Default = 50]
%      	verbosity:  Determine the amount of information to print during the
%                   optimization process, accepts numeric values [0-3].
%                   [Default = 0]
%      	display:    Plot the Objective value during the optimization
%                   process. NOTE: SLOW DOWN THE OPTIMIZATION CONSIDERABLY!
%                   It's preferable to plot stats.error once optimized.
%                   [Default = false]
%      	indent:     Base indentation level for printing.
%                   [Default = 0]
%     	useGPU:     If true potentially enable GPU acceleration (it will be
%                   checked whenever MATLAB is GPU-ready). NOTE: FOR SMALL
%                   OPTIMIZATION PROBLEMS MIGHT SLOW DOWN THE COMPUTATION!
%                   [Default = false]
%      	funcgradgpu: If true the function FUNCGRAD will be fed with
%                   GPUArray data (Speed up the computation when using GPU
%                   acceleration, but require a compatible FUNCGRAD).
%                   [Default = false]
%      	outputgpu:  If true X will be returned as GPUArray (whenever it
%                   has been computed as GPUArray).
%                   [Default = false]
%      	full_hist:  If true STATS.full_hist will include all the parameters
%                   throughout the optimization process.
%                   NOTE: IT MIGHT GET REALLY BIG! ([p.MaxIter x size(X)])
%                   [Default = false]
%
%   VARARGIN:       Will be passed as argument to FUNCGRAD.
%
%  	EXITFLAG:
%    	0 = Maximum number of iterations PARAMETERS.MaxIter reached.
%       1 = Minimum variation of Obj value PARAMETERS.Tolfun reached.
%       2 = Minimum variation of the gradient of parameters PARAMETERS.TolX
%           reached.
%     	3 = Minimum Objective value PARAMETERS.d_Obj reached.
%       4 = Maximum computational time PARAMETERS.d_time reached.
%
%
%   STATS:
%       error:      [N_ITER x 1] Objectives value during the optimization
%                   process.
%       time:       [N_ITER x 1] Time spent since the beginning of the
%                   optimization process.
%       full_hist:  {N_ITER x 1} If PARAMETERS.full_hist is 'true', each
%                   cell contain X for that particular iteration.
%       FunEvals:   Number of function evaluations (always N_ITER+1).
%
%
%   References:
%       [1] C. Igel and M. Hüsken. Improving the Rprop Learning Algorithm.
%           Neural Computation, pp. 115-121, 2000.
%       [2] C. Igel and M. Hüsken. Empirical Evaluation of the Improved
%           Rprop Learning Algorithm. Neurocomputing 50, pp. 105-123, 2003.
%       [3] M. Riedmiller and H. Braun. A direct adaptive method for faster
%           backpropagation learning: the RPROP algorithm. International
%           Conference on Neural Networks, pp. 586-591, IEEE Press, 1993.
%       [4] M. Riedmiller. Advanced supervised learning in multilayer
%           perceptrons-from backpropagation to adaptive learning
%           techniques. International Journal of Computer Standards and
%           Interfaces 16(3), pp. 265-278, 1994.
%
%
%   Toolbox website:
%       http://www.ias.informatik.tu-darmstadt.de/Research/RpropToolbox
%
%
%   If used for scientific publications please cite explicitly:
%   -----------------------------------------------------------------------
%   @MISC{rproptoolbox,
%       author = {Calandra, Roberto},
%       title = {Rprop Toolbox for {MATLAB}},
%       year = {2011},
%       howpublished = {\url{http://www.ias.informatik.tu-darmstadt.de/Research/RpropToolbox}}
%   }
%   -----------------------------------------------------------------------
%

%   Copyright (c) 2011 Roberto Calandra
%   $Revision: 0.96 $

%   TODO: what happen when x0 is a gpuArray
%   TODO: change d_Obj to 0(-inf), defualt


function [x,E,exitflag,stats] = rprop(funcgrad,x0,parameters,varargin)
%% Input validation

assert(isa(funcgrad,'function_handle'),'Invalid format of FUNCGRAD')

if exist('parameters','var')
    assert(isstruct(parameters),'PARAMETERS is not a structure')
end

% Start the timer
rpropclock = tic;


%% Parameters

% Default Parameters
p.method            = 'Rprop+';    % Rprop method used
p.MaxIter           = 100;          % Stop 0: Maximum number of iterations
p.Tolfun            = 10e-9;        % Stop 1: Minimum Delta of value
p.TolX              = 10e-9;        % Stop 2: Minimum Delta of parameters
p.d_Obj             = 10e-12;       % Stop 3: Minimum value
p.d_time            = inf;          % Stop 4: Maximum time
p.mu_neg            = 0.5;          % Decrease factor
p.mu_pos            = 1.2;          % Increase factor
p.delta0            = 0.0123;       % Initial update-value
p.delta_min         = 0;            % Lower bound for step size
p.delta_max         = 50;           % Upper bound for step size
p.verbosity         = 0;            % [0-3] verbosity mode
p.display           = false;        % Plot optimization process
p.indent            = 0;            % Base for indentation
p.useGPU            = false;        % Use GPU if possible
p.funcgradgpu       = false;        % Enable if funcgrad accept gpuArray
p.outputgpu         = false;        % Enable if you want x to be a gpuArray
p.full_hist         = false;        % Return the full history of parameters

% Override default parameters with eventual passed ones
if exist('parameters','var')
    t_p = fieldnames(parameters);
    for i = 1:size(t_p,1)
        if isfield(p,t_p{i})
            p.(t_p{i}) = parameters.(t_p{i});
        else
            fprintf(2,'%s: unknown parameter passed: %s\n',mfilename,t_p{i})
        end
    end
end

% Validate Parameters
p.MaxIter = round(p.MaxIter);
assert(isfinite(p.MaxIter),'PARAMETERS.MaxIter must be positive')
assert(p.MaxIter>0,'PARAMETERS.MaxIter must be positive')


%% Initialization

x = x0;

% Are we using Rprop+ or IRprop+ ?
plus = sum(strcmp(p.method,{'Rprop+','IRprop+'}));

% Shall we use GPU ?
if p.useGPU
    GPUenable = GPU.GPUsupport();
else
    GPUenable = false;
end

% Shall we pass to funcgrad a gpuArray ?
if GPUenable && ~p.funcgradgpu
    GPUfuncnotGPU = true;
else
    GPUfuncnotGPU = false;
end

% Do we need to convert x from gpuArray to double?
if ~p.outputgpu && GPUenable
    xGPU = true;
else
    xGPU = false;
end

% Initialize some variables
exitflag                        = 0; % Reached maximum amount of iterations
stats.error                     = zeros([p.MaxIter,1]);
stats.time                      = zeros([p.MaxIter,1]);
if p.full_hist
    stats.x = cell([p.MaxIter,1]);
end

% Initialize more variables
if iscell(x0)
    % x0 is made out of cells
    
    ncell                       = numel(x0);
    tb                          = size(x0);
    
    delta                       = cell(tb);
    grad                        = cell(tb);
    old_grad                    = cell(tb);
    deltaW                      = cell(tb);
    if plus
        old_deltaW              = cell(tb);
        if GPUenable
            old_E               = parallel.gpu.GPUArray.inf;
        else
            old_E               = inf;
        end
    end
    
    for i = 1:ncell
        t2 = size(x0{i});
        
        if GPUenable
            delta{i}            = p.delta0.*parallel.gpu.GPUArray.ones(t2);
            grad{i}             = parallel.gpu.GPUArray.zeros(t2);
            old_grad{i}      	= parallel.gpu.GPUArray.zeros(t2);
            deltaW{i}          	= parallel.gpu.GPUArray.zeros(t2);
            if plus
                old_deltaW{i}  	= parallel.gpu.GPUArray.zeros(t2);
            end
        else
            delta{i}          	= repmat(p.delta0,t2);
            grad{i}             = zeros(t2);
            old_grad{i}      	= zeros(t2);
            deltaW{i}         	= zeros(t2);
            if plus
                old_deltaW{i}  	= zeros(t2);
            end
        end
    end
    
else
    % x0 is not a cell
    
    ncell                       = 1;
    tb                          = size(x0);
    
    if GPUenable
        x                       = gpuArray(x);
        delta{1}              	= p.delta0.*parallel.gpu.GPUArray.ones(tb);
        grad{1}               	= parallel.gpu.GPUArray.zeros(tb);
        old_grad{1}          	= parallel.gpu.GPUArray.zeros(tb);
        deltaW{1}           	= parallel.gpu.GPUArray.zeros(tb);
        if plus
            old_deltaW{1}       = parallel.gpu.GPUArray.zeros(tb);
            old_E               = parallel.gpu.GPUArray.inf;
        end
    else
        delta{1}                = repmat(p.delta0,tb);
        grad{1}             	= zeros(tb);
        old_grad{1}           	= zeros(tb);
        deltaW{1}            	= zeros(tb);
        if plus
            old_deltaW{1}     	= zeros(tb);
            old_E               = inf;
        end
    end
end


%% Optimization

% Print method used for optimization
if p.verbosity>0
    Utils.indent(p.indent+0)
    fprintf('Optimizing using %s\n',p.method);
end

if p.verbosity>1
    if GPUenable
        Utils.indent(p.indent+0)
        fprintf('GPU acceleration enabled\n')
    end
end

% Compute initial value function and gradient
if GPUfuncnotGPU
    [E grad_t] = funcgrad(gather(x),varargin{:});
else
    [E grad_t] = funcgrad(x,varargin{:});
end

% Print initial value
if p.verbosity>2
    Utils.indent(p.indent+1)
    fprintf('Initial Value: %e\r',E);
end

% Check stop criterions

% Stop criterion: TolX
if ncell==1
    TolX = max(abs(grad_t));
else
    TolX = max(abs(grad_t{1}));
    for i=2:ncell
        TolX = max(max(abs(grad_t{i})),TolX);
    end
end
if TolX < p.TolX
    if p.verbosity>1
        Utils.indent(p.indent+1)
        fprintf(2,'Stopping criterion reached (TolX < desired TolX)\n')
    end
    exitflag = 2;
    return
end

% Stop criterion: Error
if E < p.d_Obj
    if p.verbosity>1
        Utils.indent(p.indent+1)
        fprintf(2,'Stopping criterion reached (Error < desired Error)\n')
    end
    exitflag = 3;
    return
end

% Stop criterion: Time
t1 = toc(rpropclock);
if t1 > p.d_time
    if p.verbosity>1
        Utils.indent(p.indent+1)
        fprintf(2,'Stopping criterion reached (Time > desired Time)\n')
    end
    exitflag = 4;
    return
end
clear t1

% Init figure
if p.display>0
    stats.fig_h = figure();
end

% Begin the optimization
for Iter = 1:p.MaxIter
    
    % Validate input
    %assert(isequal(size(grad_t),size(x)),...
    %    'The dimension of the gradient do not match the parameters')
    %assert(Utils.msum(isfinite(grad))==numel(x))
    %assert(isfinite(E))
    
    if ncell==1
        grad{1} = grad_t;
    else
        grad = grad_t;
    end
    
    % Optimization !
    for i = 1:ncell
        
        gg          = grad{i}.*old_grad{i};
        delta{i}    = min(delta{i}*p.mu_pos,p.delta_max).*(gg>0) +...
            max(delta{i}*p.mu_neg,p.delta_min).*(gg<0) + delta{i}.*(gg==0);
        
        switch p.method
            case 'Rprop-'
                deltaW{i}           = -sign(grad{i}).*delta{i};
                
            case 'Rprop+'
                deltaW{i}           = -sign(grad{i}).*delta{i}.*(gg>=0) -...
                    old_deltaW{i}.*(gg<0);
                grad{i}             = grad{i}.*(gg>=0);
                old_deltaW{i}       = deltaW{i};
                
            case 'IRprop-'
                grad{i}             = grad{i}.*(gg>=0);
                deltaW{i}           = -sign(grad{i}).*delta{i};
                
            case 'IRprop+'
                deltaW{i}           = -sign(grad{i}).*delta{i}.*(gg>=0) -...
                    old_deltaW{i}.*(gg<0)*(E>old_E);
                grad{i}             = grad{i}.*(gg>=0);
                old_deltaW{i}       = deltaW{i};
                old_E               = E;
                
            otherwise
                error('Unknown method')
                
        end
        
        old_grad{i} 	= grad{i};
        
        % Update parameters
        if ncell==1
            x           = x + deltaW{i};
        else
            x{i}        = x{i} + deltaW{i};
        end
        
    end
    
    
    % Compute value function and gradient
    if GPUfuncnotGPU
        if ncell==1
            [E grad_t] = funcgrad(gather(x),varargin{:});
        else
            x_t = cell(size(x));
            for i=1:numel(x_t)
                x_t{i} = gather(x{i});
            end
            [E grad_t] = funcgrad(x_t,varargin{:});
        end
    else
        [E grad_t] = funcgrad(x,varargin{:});
    end
    
    % Print info about this iteration
    if p.verbosity>1
        Utils.indent(p.indent+1)
        fprintf('Iter %d (of %d)',Iter,p.MaxIter);
        if p.verbosity>2
            fprintf(' - value: %e\r',E);
        else
            fprintf('\r');
        end
    end
    
    % Collect statistics
    if p.full_hist
        stats.x{Iter} = x;
    end
    stats.time(Iter) = toc(rpropclock);
    if p.funcgradgpu
        stats.error(Iter) = gather(E);
    else
        stats.error(Iter) = E;
    end
    
    % Plot optimization process
    if p.display>0
        set(0,'CurrentFigure',stats.fig_h);
        plot(stats.error(1:Iter));
        title('Objective value during optimization')
        ylabel('Objective value')
        xlabel('Number of Iterations')
        drawnow
    end
    
    % Check other stop criterions
    
    % Stop criterion: TolFun
    if Iter>1
        if isfinite(p.Tolfun)
            deltaobj = stats.error(Iter-1) - stats.error(Iter);
            if (deltaobj < p.Tolfun) && (deltaobj > 0)
                if p.verbosity>1
                    Utils.indent(p.indent+1)
                    fprintf(2,'Stopping criterion reached (Delta < desired Delta)\n')
                end
                exitflag = 1;
                break
            end
        end
    end
    
    % Stop criterion: TolX
    if ncell==1
        TolX = max(abs(grad_t));
    else
        TolX = max(abs(grad_t{1}));
        for i=2:ncell
            TolX = max(max(abs(grad_t{i})),TolX);
        end
    end
    if TolX < p.TolX
        if p.verbosity>1
            Utils.indent(p.indent+1)
            fprintf(2,'Stopping criterion reached (TolX < desired TolX)\n')
        end
        exitflag = 2;
        break
    end
    
    % Stop criterion: Error
    if E < p.d_Obj
        if p.verbosity>1
            Utils.indent(p.indent+1)
            fprintf(2,'Stopping criterion reached (Error < desired Error)\n')
        end
        exitflag = 3;
        break
    end
    
    % Stop criterion: Time
    if stats.time(Iter) > p.d_time
        if p.verbosity>1
            Utils.indent(p.indent+1)
            fprintf(2,'Stopping criterion reached (Time > desired Time)\n')
        end
        exitflag = 4;
        break
    end
    
end


%% Output Validation

% Cut outputs in case of early-stop
stats.error             = stats.error(1:Iter);
stats.time              = stats.time(1:Iter);
stats.GPUenabled        = GPUenable;
stats.FunEvals          = Iter+1;
if p.full_hist
    stats.x             = stats.x(1:Iter);
end

% In case the GPU has been used collect the parameters
if xGPU
    if ncell==1
        x = gather(x);
    else
        x_t = cell(size(x));
        for i=1:numel(x)
            x_t{i} = gather(x{i});
        end
        x = x_t;
    end
end


end


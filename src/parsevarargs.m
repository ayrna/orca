function options = parsevarargs(options, varargin)
% PARSEVARARGS parses ('key', value) pairs to fill structure OPTIONS. It
% raises errors if the field does not exits in OPTIONS. OPTIONS should
% provide field with default values.
if ~isempty(varargin{:})
    par = varargin{:};
    
    % read the acceptable names
    optionNames = fieldnames(options);
    
    % count arguments
    nArgs = length(par);
    if mod(nArgs,2)
        error('parseVarArgs needs propertyName/propertyValue pairs')
    end
    
    for pair = reshape(par,2,[]) % pair is {propName;propValue}
        inpName = lower(pair{1}); % make case insensitive
        
        if any(strcmp(inpName,optionNames))
            % overwrite options.
            options.(inpName) = pair{2};
        else
            error('%s is not a recognized parameter name',inpName)
        end
    end
end
end
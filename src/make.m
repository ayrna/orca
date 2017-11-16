% Make function for MATLAB and OCTAVE that processes make() in Algorithms and subfolders 
% with C/C++ code. 
% Options are: 
% - 'make' build all targets
% - 'make clean' clean objects
% - 'make cleanall' clean objects, executables and mex files.
function make(opt)
if nargin < 1
    try
        cd Algorithms/
        make
        cd ..
    catch err
        fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
        disp(err.message);
        fprintf('=> Please check README for detailed instructions.\n');
    end
elseif nargin == 1
    
    switch lower(opt)
        case {'clean', 'cleanall'}
            try
                cd Algorithms/
                make(opt)
                cd ..
            catch err
                fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
                disp(err.message);
                fprintf('=> Please check README for detailed instructions.\n');
            end
        otherwise
            error('make option "%s" not recognized', opt)
    end
end
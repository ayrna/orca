% make function for MATLAB and OCTAVE that processes make() in all the subfolders
% with C/C++ code.
% Options are:
% - 'make' build all targets
% - 'make clean' clean objects
% - 'make cleanall' clean objects, executables and mex files.
function make(opt)
if nargin < 1
    try
        cd 'libsvm-weights-3.12/matlab/'
        make
        cd ../..
        cd 'libsvm-rank-2.81/matlab/'
        make
        cd ../..
        cd SVOREX
        make
        cd ..
        cd SVORIM
        make
        cd ..
        cd orensemble
        make
        cd ..
    catch err
        fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
        disp(err.message);
        fprintf('=> Please check README for detailed instructions.\n');
    end
elseif nargin == 1
    try
        cd 'libsvm-weights-3.12/matlab/'
        make(opt)
        cd ../..
        cd 'libsvm-rank-2.81/matlab/'
        make(opt)
        cd ../..
        cd SVOREX
        make(opt)
        cd ..
        cd SVORIM
        make(opt)
        cd ..
        cd orensemble
        make(opt)
        cd ..
    catch err
        fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
        disp(err.message);
        fprintf('=> Please check README for detailed instructions.\n');
    end
end
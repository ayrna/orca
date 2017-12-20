function make(opt)
%MAKE function for MATLAB and OCTAVE that processes make() in all the subfolders
%with C/C++ code.
% Options are:
% - 'make' build all targets
% - 'make clean' clean objects
% - 'make cleanall' clean objects, executables and mex files.
%
%   This file is part of ORCA: https://github.com/ayrna/orca
%   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
%   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
%   Copyright:
%       This software is released under the The GNU General Public License v3.0 licence
%       available at http://www.gnu.org/licenses/gpl-3.0.html
if nargin < 1
    try
        cd 'libsvm-weights-3.12/matlab/'
        make
        cd ../..
        cd 'libsvm-rank-2.81/matlab/'
        make
        cd ../..
        cd 'liblinear-2.20/matlab/'
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
        cd 'liblinear-2.20/matlab/'
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
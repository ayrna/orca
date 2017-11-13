% Make file for MATLAB and OCTAVE that processes make() in all the subfolders 
% with C/C++ code. 
function make()
try
	% This part is for OCTAVE
	if (exist ('OCTAVE_VERSION', 'builtin'))
		error('TODO')
	% This part is for MATLAB
    else
        cd libsvm-weights-3.12\matlab\
        make
        cd ..\..\
        cd libsvm-rank-2.81\matlab\
        make
		cd ..\..\
        cd SVOREX
        make
		cd ..\
        cd SVORIM
        make
		cd ..\
	end
catch err
	fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
	disp(err.message);
	fprintf('=> Please check README for detailed instructions.\n');
end

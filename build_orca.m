% This script builds ORCA for Octave/MATLAB. The script check dependencies and
% install required Octave packages if needed. In MATLAB, it looks for
% toolboxes.
% The script runs basic tests after installation.%

disp('== Check and install dependencies... ==')
% Build ORCA for Octave and install dependencies
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
	ip = pkg ('list', 'statistics');
	if length(ip) == 0
		pkg install -forge io
		pkg install -forge statistics
	else
		verref = '1.4.1';
		if prod(ip{1,1}.version <= verref) == 0
			pkg install -forge io
			pkg install -forge statistics
		end
	end
	ip = pkg ('list', 'optim');
	if length(ip) == 0
		pkg install -forge struct
		pkg install -forge optim
	end
else % Build ORCA for MATLAB
	if (license('test','statistics_toolbox') == 0)
		error('ORCA needs the Statistics and Machine Learning Toolbox ')
	end
end

disp('== Compile C/C++ source... ==')
cd src/Algorithms
make
make clean
cd ..

disp('== Run basic tests... == ')

runtests_single
cd ..

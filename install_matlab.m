% This script installs ORCA for Octave as well as dependencies.
% The script runs basic tests after installation.%

disp('== Check dependencies... ==')
if (license('test','statistics_toolbox') == 0)
    error('ORCA needs the Statistics and Machine Learning Toolbox ')
end
disp('== Compile C/C++ source... ==')
cd src/Algorithms
make
make clean
cd ..

disp('== Run basic tests... == ')

runtestssingle

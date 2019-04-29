% This script installs ORCA for Octave as well as dependencies.
% The script runs basic tests after installation.%

disp('== Check and install dependencies... ==')
ip = pkg ("list", "statistics");
if length(ip) == 0
    pkg install -forge io
    pkg install -forge statistics
end
ip = pkg ("list", "optim");
if length(ip) == 0
    pkg install -forge struct
    pkg install -forge optim
end

disp('== Compile C/C++ source... ==')
cd src/Algorithms
make
make clean
cd ..

disp('== Run basic tests... == ')

runtestssingle

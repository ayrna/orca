# Windows instalation process

1. Install a [supported compiler](https://es.mathworks.com/support/compilers.html). The easier way is to use the "Add-ons" assistant to download
and install [MinGW](http://es.mathworks.com/help/matlab/matlab_external/install-mingw-support-package.html).
1. Test [basic C example](https://es.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c++-compiler) to ensure `mex` is propertly working.
1. Inside MATLAB's console, run `make` in folder `src\Algorithms`
1. From `src` run `runtestssingle` to check the instalation. 

# Windows instalation process

The following steps provide all the methos but 'ORBoost':

1. Install a [supported compiler](https://es.mathworks.com/support/compilers.html). The easier way is to use the "Add-ons" assistant to download
and install [MinGW](http://es.mathworks.com/help/matlab/matlab_external/install-mingw-support-package.html).
1. Test [basic C example](https://es.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c++-compiler) to ensure `mex` is propertly working.
1. Inside MATLAB's console, run `make` in folder `src\Algorithms`
1. From `src` run `runtestssingle` to check the instalation.

To compile 'ORBoost' you need to install 'w64-mingw32':

1. Open a terminal by presing Windows key and tipping 'cmd.exe'.
1. Set Windows path to your 'w64-mingw32' installation binaries dir, for instance:
```
set PATH=C:\Program Files\mingw-w64\x86_64-7.2.0-posix-seh-rt_v5-rev0\mingw64\bin;"%PATH%"
```
1. Change to directory `orca\src\Algorithms\orensemble\` (Right now only works in `orca\src\Algorithms\orensemble\orensemble\`.).
1. Run `mingw32-make.exe Makefile.win all`.

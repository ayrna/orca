# Windows instalation process

The following steps provide all the methods but 'ORBoost':

1. Install a [supported compiler](https://es.mathworks.com/support/compilers.html). The easier way is to use the "Add-ons" assistant to download
and install [MinGW](http://es.mathworks.com/help/matlab/matlab_external/install-mingw-support-package.html).
1. Test [basic C example](https://es.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c++-compiler) to ensure `mex` is propertly working.
1. Inside MATLAB's console, run `make` in folder `src\Algorithms`
1. From `src` run `runtestssingle` to check the instalation.

We provide binaries and dlls for 'ORBoost' to avoid the *complex* build task in Windows. Make will unpak all the binary files. If you need to compile your own binaries, these are the steeps.

1. Install [w64-mingw32](https://mingw-w64.org).
1. Open a terminal by presing Windows key and type `cmd.exe`.
1. Set Windows path to your `w64-mingw32` installation binaries dir, for instance:
```
set PATH=C:\Program Files\mingw-w64\x86_64-7.2.0-posix-seh-rt_v5-rev0\mingw64\bin;"%PATH%"
```
1. Move to directory `orca\src\Algorithms\orensemble\orensemble`.
1. Run `mingw32-make.exe Makefile.win all`.

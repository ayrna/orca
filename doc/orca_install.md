# ORCA detailed build and troubleshooting

This a detailed install guide. If you have not done it yet, please try the [Quick Install steps](orca_quick_install.md) before continuing. After this, if you are here, that means that there have been some errors when building the `mex` files.

## Building `mex` files in GNU/Linux

`make.m` scripts could fail if the compiler is not correctly installed and configured. In those cases, please try `mex -setup` to choose a suitable compiler for `mex`. Make sure your compiler is accessible. Then type `make` to start the installation.

If neither `make.m` nor `mex -setup` works, the simplest way to compile all the algorithms is to use the [Makefile](../src/Makefile) included in ORCA. This will compile all the algorithms and clean intermediate object files.


### Building `mex` files for Matlab from the GNU/Linux terminal

For building the mex files in MATLAB, you need to properly configure the MATLABDIR variable of [Makefile](../src/Makefile), in order to point out to the MATLAB installation directory (for instance `MATLABDIR = /usr/local/MATLAB/R2017b`). Then, from the `bash` terminal:
```bash
$ cd src/
$ make
```

### Building `mex` files for Octave from the GNU/Linux terminal
For building the `mex` files in Octave, you will need to configure the OCTAVEDIR variable in the [Makefile](../src/Makefile). This variable has to point out to the Octave heather files (for instance, `OCTAVEDIR = /usr/include/octave-4.0.0/octave/`). Then, from the `bash` terminal:
```bash
$ cd src/
$ make octave
```

## Building `mex` files in Windows

In Windows, we recommend compiling `mex` files from Octave/MATLAB console.

### Building `mex` files in Windows for Octave

Default Octave installation provides `mex` command pre-configured with `MinGW`.

1. Inside Octave's console, run `make` in folder `src\Algorithms`
1. From `src` run `runtests_single` to check the installation.

### Building `mex` files in Windows for Matlab

1. Install a [supported compiler](https://es.mathworks.com/support/compilers.html). The easier way is to use the "Add-ons" assistant to download
and install [MinGW](http://es.mathworks.com/help/matlab/matlab_external/install-mingw-support-package.html).
1. Test [basic C example](https://es.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c++-compiler) to ensure `mex` is properly working.
1. From the MATLAB's console, run `make` in `src\Algorithms`.
1. Then run `runtests_single` in `src` to check the instalation.

We provide binaries and *dlls* for 'ORBoost', because building this method in Windows can be very *complex*. Make will unpack all the binary files. If you need to compile your own binaries, these are the steps:

1. Install [w64-mingw32](https://mingw-w64.org).
1. Open a terminal by pressing Windows icon and type `cmd.exe`.
1. Set Windows path to your `w64-mingw32` installation binaries dir, for instance:
```
set PATH=C:\Program Files\mingw-w64\x86_64-7.2.0-posix-seh-rt_v5-rev0\mingw64\bin;"%PATH%"
```
1. Move to directory `orca\src\Algorithms\orensemble\orensemble`.
1. Run `mingw32-make.exe Makefile.win all`.

## Individually compiling the algorithms

If you are not able to compile all the algorithms using the above methods, we recommend individually compiling them. Under GNU/Linux, please, edit the files `src/Algorithms/libsvm-rank-2.81/matlab/Makefile`, `src/Algorithms/libsvm-weights-3.12/matlab/Makefile`, `src/Algorithms/SVOREX/Makefile` and `src/Algorithms/SVORIM/Makefile`. Make sure that the variables `MATLABDIR` or `OCTAVEDIR` are correctly pointing to the folders. For MATLAB, you can also make a symbolic link to your current Matlab installation folder:
```bash
$ sudo ln -s /path/to/matlab /usr/local/matlab
```
The following subsections provides individual instructions for compiling each of the dependencies in case the global [Makefile](../src/Algorithms/Makefile) still fails or for those which are working in other operating systems.

### libsvm-weights-3.12

These instructions are adapted from the corresponding README of `libsvm`. First, you should open MATLAB/Octave console and then `cd` to the directory `src/Algorithms/libsvm-weights-3.12/matlab`. After that, try to compile the `MEX` files using `make.m` (from the MATLAB/Octave console):
```MATLAB
>> cd src/Algorithms/libsvm-weights-3.12/matlab
>> make
```

### libsvm-rank-2.81

To compile this dependency, the instructions are similar to those of `libsvm-weights-3.12` (from the MATLAB/Octave console):
```MATLAB
>> cd src/Algorithms/libsvm-rank-2.81/matlab
>> make
```

### SVOREX and SVORIM

For both algorithms, please use the `make.m` file included in them (from the MATLAB/Octave console):
```MATLAB
>> cd src/Algorithms/SVOREX
>> make
>> cd ..
>> cd SVORIM
>> make
```

### orensemble

We have not prepared a proper MEX interface for ORBoost, so the binary files of this algorithm should be compiled and are then invoked directly from Matlab. For compiling the ORBoost algorithm, you should uncompress the file `orsemble.tar.gz` and compile the corresponding source code. In GNU/Linux, this can be done by (from the `bash` console):
```bash
$ cd src/Algorithms/orensemble
$ tar zxf orensemble.tar.gz
$ cd orensemble/
$ make
g++ -Ilemga-20060516/lemga -Wall -Wshadow -Wcast-qual -Wpointer-arith -Wconversion -Wredundant-decls -Wwrite-strings -Woverloaded-virtual -D NDEBUG -O3 -funroll-loops -c -o robject.o lemga-20060516/lemga/object.cpp
...
```
Then, you should move the binary files to `..` folder and clean the folder (from the `bash` console):
```bash
$ mv boostrank-predict ../
$ mv boostrank-train ../
$ cd ..
$ rm -Rf orensemble
```

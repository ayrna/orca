<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Installing ORCA](#installing-orca)
	- [Installation requirements](#installation-requirements)
	- [Download ORCA](#download-orca)
	- [Binaries](#binaries)
	- [Compilation of `mex` files from the MATLAB/Octave console (RECOMMENDED)](#compilation-of-mex-files-from-the-matlaboctave-console-recommended)
	- [Compilation of `mex` files from system shell](#compilation-of-mex-files-from-system-shell)
	- [Installation testing](#installation-testing)

<!-- /TOC -->

# Installing ORCA

This is a **quick installation** guide. If you experiment any problems, please read the [detailed installation guide](orca_install.md). ORCA has been developed and tested in GNU/Linux systems and ported to Windows. It works in Mac using GNU compilers. It has been tested in MATLAB R2009a-R2017b and Octave >4.0.

## Installation requirements

In order to use ORCA you need:

* GNU `gcc` and `g++`
* MATLAB/Octave (Octave >= 4.0), including `mex`.
  * MATLAB toolboxes: Statistics and Machine Learning
  * Octave packages: statistics,optim,liboctave-dev. These can be easily installed with `pkg install -forge optim` and so on. Depending on your GNU/Linux distribution you may also have to install `liboctave-dev` with your distribution package manager. 

For instance, to install Octave and the required packages in Ubuntu 18.10: 

```bash
$ sudo apt-get install Octave liboctave-dev
```

And then, in the Octave console: 

```MATLAB
> pkg install -forge struct
> pkg install -forge io
> pkg install -forge optim
> pkg install -forge statistics
```
## Download ORCA

To download ORCA you can simply clone this GitHub repository by using the following commands:
```bash
$ git clone https://github.com/ayrna/orca
```
All the contents of the repository can also be downloaded from the GitHub site by using the "Download ZIP" button.

## Binaries

We provide binary files for several platforms (Debian based and CentOS GNU/Linux and Windows). The compressed files include the git files, so git pull should work. Binaries can be downloaded in the [release page](https://github.com/ayrna/orca/releases).

## Compilation of `mex` files from the MATLAB/Octave console (RECOMMENDED)

ORCA is programmed in MATLAB, but many of the classification algorithms are implemented in C/C++. Because of this, these methods have to be compiled and/or packaged into the corresponding `mex` files.

In Windows and GNU/Linux, you can build ORCA directly **from the MATLAB/Octave console**. Just enter in the `scr` directory and type `make`.
```MATLAB
>> cd src/Algorithms
>> make
```
After building, you can clean the objects files with `make clean`:
```MATLAB
>> make clean
```

## Compilation of `mex` files from system shell

If you prefer to build `mex` files from the Linux shell, you can use standard `make` tool at `src/Algorithms` directory:

1. Set up the proper path for `MATLABDIR` or `OCTAVEDIR` variables, see examples at [../src/Algorithms/Makefile](../src/Algorithms/Makefile)
1. Run `make` for MATLAB or `make octave` for GNU Octave.  


## Installation testing

We provide a set of basic tests to for checking that all the algorithms work, both using ORCA's API and experiment scripts (see [tutorial](orca-tutorial-1.md) for more information).

The way to run the tests checking the API (see [single test scripts](../src/tests/singletests/)) is the following (running time is ~12 seconds):

```MATLAB
>> cd src/
>> runtestssingle
...
.........................
Performing test for SVORLin
Accuracy Train 0.262222, Accuracy Test 0.266667
Test accuracy matchs reference accuracy
Processing svrTest.m...
.........................
Performing test for SVR
Accuracy Train 0.995556, Accuracy Test 0.973333
Test accuracy matchs reference accuracy
All tests ended successfully
```

To run the tests checking the experiment scripts (running time is ~123 seconds):

```MATLAB
>> cd src/
>> runtestscv
...
Running experiment exp-svr-real1-toy-1
Processing Experiments/exp-2017-11-16-13-59-1/exp-svr-real1-toy-1
Calculating results...
Experiments/exp-2017-11-16-13-59-1/Results/toy-svr-real1/dataset
Experiments/exp-2017-11-16-13-59-1/Results/toy-svr-real1/dataset
Test passed for svr
All tests ended successfully
```

If any of these tests fail, please read the [detailed installation guide](orca_install.md).

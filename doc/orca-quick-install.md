<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:1 -->

1. [Installing ORCA](#installing-orca)
	1. [Installation requirements](#installation-requirements)
	2. [Download ORCA](#download-orca)
	3. [Compilation of `mex` files](#compilation-of-mex-files)
	4. [Installation testing](#installation-testing)

<!-- /TOC -->
# Installing ORCA

This is a **quick install** guide. If you experiment problems, please read the [detailed install guide](orca-install.md). ORCA has been developed and tested in GNU/Linux systems and ported to Windows. It has been tested in MATLAB R2009a-R2017b and Octave >4.0.

## Installation requirements

In order to use ORCA you need:

* `gcc` and `g++`
* MATLAB/Octave (Octave >= 4.0), including `mex`.
  * MATLAB toolboxes: Statistics and Machine Learning
  * Octave packages: statistics,optim,liboctave-dev. Can be easily installed with `pkg install -forge optim` and so on. Depending on your GNU/Linux distribution you may have to install `liboctave-dev` with your distribution package manager.

## Download ORCA

To download ORCA you can simply clone this GitHub repository by using the following commands:
```bash
$ git clone https://github.com/ayrna/orca
```
All the contents of the repository can also be downloaded from the GitHub site by using the "Download ZIP" button.

## Compilation of `mex` files

ORCA is programmed in MATLAB, but many of the classification algorithms are implemented in C/C++. Because of this, these methods have to be compiled and/or packaged into the corresponding `mex` files.

In Windows and GNU/Linux, you can build ORCA directly from the MATLAB/Octave console. Just enter in the `scr` directory and type `make`.
```MATLAB
>> cd src/Algorithms
>> make
```
After building, you can clean the objects files with `make clean`:
```MATLAB
>> make clean
```

## Installation testing

We provide a set of basic tests to for checking that all the algorithms work, both using ORCA's API and experiment scripts (see [tutorial](orca-tutorial.md) for more information).

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

If any of these tests fail, please read the [detailed install guide](orca-install.md).

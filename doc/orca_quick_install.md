<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Installing ORCA](#installing-orca)
	- [Installation requirements](#installation-requirements)
	- [Download and install ORCA](#download-and-install-orca)
	- [Binaries](#binaries)
	- [Compilation of `mex` files from system shell](#compilation-of-mex-files-from-system-shell)
	- [Installation testing](#installation-testing)
	- [Use ORCA as a toolbox](#use-orca-as-a-toolbox)


# Installing ORCA

This is a **quick installation** guide. If you experiment any problems, please read the [detailed installation guide](orca_install.md). ORCA has been developed and tested in GNU/Linux systems and ported to Windows. It works in Mac using GNU compilers. It has been tested in MATLAB R2009a-R2017b and Octave >= 4.2.

## Installation requirements

In order to use ORCA you need:

* GNU `gcc` and `g++`
* MATLAB/Octave (Octave >= 4.2), including `mex`.
  * MATLAB toolboxes: MATLAB compiler, Optimization, Statistics and Machine Learning. Optional Parallel Computing.
  * Octave packages (ORCA will install them for you): **recent versions from octave forge** of statistics, optim and dependencies io, struct. Depending on your GNU/Linux distribution you may also have to install `liboctave-dev` with your distribution package manager. 

## Download and install ORCA

To download ORCA you can simply clone this GitHub repository by using the following commands:
```bash
$ git clone https://github.com/ayrna/orca
```
All the contents of the repository can also be downloaded from the GitHub site by using the "Download ZIP" button.

To build ORCA, `build_orca.m` will check dependencies, install them for Octave, and run basic tests. From MATLAB/Octave:

```MATLAB
> build_orca.m
```

For instance, to install Octave, download and install ORCA in Ubuntu 18.10:

```bash
$ sudo apt-get install octave liboctave-dev
$ git clone https://github.com/ayrna/orca.git
$ cd orca
$ octave-cli build_orca.m
```

## Binaries

We provide binary files for several platforms (Debian based and CentOS GNU/Linux and Windows). The compressed files include the git files, so git pull should work. Binaries can be downloaded in the [release page](https://github.com/ayrna/orca/releases).

## Compilation of `mex` files from system shell

If you prefer to build `mex` files from the Linux shell, you can use standard `make` tool at `src/Algorithms` directory:

1. Set up the proper path for `MATLABDIR` or `OCTAVEDIR` variables, see examples at [../src/Algorithms/Makefile](../src/Algorithms/Makefile)
1. Run `make` for MATLAB or `make octave` for GNU Octave.  


## Installation testing

We provide a set of basic tests to for checking that all the algorithms work, both using ORCA's API and experiment scripts (see [tutorial](orca_tutorial_1.md) for more information).

The way to run the tests checking the API (see [single test scripts](../src/tests/singletests/)) is the following (running time is ~12 seconds):

```MATLAB
>> cd src/
>> runtests_single
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
>> runtests_cv
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

## Use ORCA as a toolbox

The first of three tutorials covers the basic use of ORCA as a toolbox but also as an experimental framework: *'how to' tutorial* ([Jupyter Notebook](orca_tutorial_1.ipynb), [MD](orca_tutorial_1.md)).

For instance, to use ORCA as a toolbox:

```MATLAB
% Create an Algorithm object
addpath('src/Algorithms/')
kdlorAlgorithm = KDLOR();
% Load dataset
load exampledata/1-holdout/toy/matlab/train_toy.0
load exampledata/1-holdout/toy/matlab/test_toy.0
train.patterns = train_toy(:,1:(size(train_toy,2)-1));
train.targets = train_toy(:,size(train_toy,2));
test.patterns = test_toy(:,1:(size(test_toy,2)-1));
test.targets = test_toy(:,size(test_toy,2));
% Fit the model and predict with test data
info = kdlorAlgorithm.fitpredict(train,test);

% You can evaluate performance with ordinal metrics:
addpath('src/Measures/')
CCR.calculateMetric(info.predictedTest,test.targets)
MAE.calculateMetric(info.predictedTest,test.targets)
```

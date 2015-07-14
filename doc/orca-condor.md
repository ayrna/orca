# Experiments parallelization with HTCondor

ORCA is designed to be *easily* integrated with a [HTCondor](http://research.cs.wisc.edu/htcondor/) High Throughput Computing (HTC) environment so extensive experiments can be speed up. The parallelization is done at dataset partition level.

The [src/condor](src/condor) folder contains a set of scripts that automate the use of ORCA with HTCondor. The script [condor-matlabExperiment.sh](src/condor/condor-matlabExperiment.sh) allows to run an ORCA set of experiments by using any of the configuration files, for instance:

```bash
$ condor-matlabExperiment.sh ../../src/test/pom
```

will create a HTCondor task and will add this task to the HTCondor queue. Each task consist of a train-test execution for each dataset partition, and an extra task to collect all the data an create the reports. Most of the experimental results will be compressed with the exception of the train and test statistical results CSV files. 

To adapt the set of scripts to your HTCondor system please set up environment variables corresponding to MATLAB's path, universe, requirements and so on.

# Experiments parallelization with HTCondor

ORCA can be *easily* integrated with a High Throughput Computing (HTC) environment, such as [HTCondor](http://research.cs.wisc.edu/htcondor/), so extensive experiments can be speed up. The parallelization is done at dataset partition level, i.e. each partitions of each dataset is run in a different slot of the cluster.

The [src/condor](../src/condor) folder contains a set of scripts that automate the use of ORCA with HTCondor. The script [condor-matlabExperiment.sh](../src/condor/condor-matlabExperiment.sh) allows to run an ORCA set of experiments by using any of the configuration files. To use the script, you will need to have the configuration file in the [src/condor](../src/condor) folder. We will combine two different algorithms by concatenating two ini files:
```bash
~/orca/orca$ cd src/condor/
~/orca/orca/src/condor$ cat ../tests/cvtests-30-holdout/svorim.ini > test.ini
~/orca/orca/src/condor$ cat ../tests/cvtests-30-holdout/kdlor.ini >> test.ini
```
Then, you have to edit the test file, so that the path of the experiments is correct with respect to the current path (replace `../example-data` by `../../example-data`). This can be done with a text editor or using the following `sed` command:
```bash
~/orca/orca/src/condor$ sed -i 's/\.\.\//\.\.\/\.\.\//g' test.ini
```
Now the script is ready to be used. The following command:
```bash
~/orca/orca/src/condor$ ./condor-matlabExperiment.sh test.ini
```
will create a HTCondor work and will add this work to the HTCondor queue. Each work consists of a task for dividing the work into different independent configuration files, a train-test task for each dataset partition and an extra task to collect all the data and create the reports. Most of the experimental results will be compressed, with the exception of the CSV files. To adapt the set of scripts to your HTCondor system please set up environment variables corresponding to MATLAB's path, universe, requirements and edit the ``.sh`` file.

Additionally, the [src/condor](../src/condor) folder includes the following files:
- [condor-matlabFramework.dag](../src/condor/condor-matlabFramework.dag): this HTCondor `dag` file will run the `submit` files into the appropriate order, that is, `condor-createExperiments.submit`, `condor-runExperiments.submit` and `condor-joinResults.submit`.
- [condor-createExperiments.sh](../src/condor/condor-createExperiments.sh): this a `bash` script invoking ORCA for separating the configuration file into as many configuration files as the number of datasets by the number of partitions. The script receives two command line arguments, the name of the configuration file and the name of the working directory.
- [condor-createExperiments.submit](../src/condor/condor-createExperiments.submit): this HTCondor `submit` file will run `condor-createExperiments.sh` into the HTCondor cluster.
- [condor-runExperiments.sh](../src/condor/condor-runExperiments.sh): this HTCondor `submit` file will run `condor-joinResults.sh` into the HTCondor cluster. The script receives two command line arguments, the name of the working directory and the number of experiment to be run.
- [condor-runExperiments.submit](../src/condor/condor-runExperiments.submit): this HTCondor `submit` file will run `condor-runExperiments.sh` into the HTCondor cluster.
- [condor-joinResults.sh](../src/condor/condor-joinResults.sh): this a `bash` script invoking ORCA for joining the results of all the experiments run. The script receives a command line argument, the name of the working directory.
- [condor-joinResults.submit](../src/condor/condor-joinResults.submit): this HTCondor `submit` file will run `condor-joinResults.sh` into the HTCondor cluster.

# Experiments parallelization with other cluster environments

The design of ORCA allows easy parallelization with other cluster environments, given that all the intermediate results of the different partitions are saved to disk. In this way, you can use the scripts [condor-createExperiments.sh](../src/condor/condor-createExperiments.sh), [condor-runExperiments.sh](../src/condor/condor-runExperiments.sh) and [condor-joinResults.sh](../src/condor/condor-joinResults.sh) to run the code in your own cluster environment.

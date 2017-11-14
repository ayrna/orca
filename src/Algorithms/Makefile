SUBDIRS = libsvm-rank-2.81/matlab libsvm-weights-3.12/matlab orensemble SVORIM SVOREX
# Matlab instalation dir
#export MATLABDIR = /usr/local/MATLAB/R2017b
export MATLABDIR = /usr/local/MATLAB/R2016a
export OCTAVEDIR = /home/pedroa/anaconda3/include/octave-4.2.1/octave/

# Uncomment for newer versions of Octave
export OCTAVE_CFLAGS = -std=c++11 -Wall -O3 -fPIC -I$(OCTAVEDIR) -I..

SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

SUBOCTAVE = $(addsuffix .octave,$(SUBDIRS))

.PHONY: clean subdirs $(SUBDIRS)
     
all: subdirs clean

subdirs: $(SUBDIRS)

clean: $(SUBCLEAN)

octave: $(SUBOCTAVE) clean
 
$(SUBDIRS):
	$(MAKE) -e -C $@

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* clean

$(SUBOCTAVE): %.octave:
	$(MAKE) -C $* octave


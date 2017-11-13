SUBDIRS = libsvm-rank-2.81/matlab libsvm-weights-3.12/matlab orensemble SVORIM SVOREX
# Matlab instalation dir
#export MATLABDIR = /usr/local/MATLAB/R2017b
export MATLABDIR = /usr/local/MATLAB/R2013a
export OCTAVEDIR = /usr/include/octave-4.0.3/octave

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


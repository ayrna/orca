SUBDIRS = libsvm-rank-2.81/matlab libsvm-weights-3.12/matlab orensemble SVORIM SVOREX

export MATLABDIR = /usr/local/MATLAB/R2016a/

# Use -std=c++11 for newer versions of Octave
export OCTAVE_CFLAGS = -std=gnu99 -Wall -O3 -fPIC -I$(OCTAVEDIR) -I..
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


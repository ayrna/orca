SUBDIRS = Algorithms

# Matlabi/Octave instalation dir
export MATLABDIR = /usr/local/MATLAB/R2017b
export OCTAVEDIR = /usr/include/octave-4.0.0/octave


# Uncomment for newer versions of Octave
export OCTAVE_CFLAGS = -std=c++98 -Wall -O3 -fPIC -I$(OCTAVEDIR) -I..

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


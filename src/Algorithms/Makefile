SUBDIRS = libsvm-rank-2.81/matlab libsvm-weights-3.12/matlab orensemble SVORIM SVOREX
# Matlab instalation dir
#export MATLABDIR = /usr/local/MATLAB/R2017b
export MATLABDIR = /usr/local/MATLAB/R2013a

SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

.PHONY: clean subdirs $(SUBDIRS)
     
all: subdirs clean

subdirs: $(SUBDIRS)

clean: $(SUBCLEAN)
 
$(SUBDIRS):
	$(MAKE) -e -C $@

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* clean


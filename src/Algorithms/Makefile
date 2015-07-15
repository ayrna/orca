SUBDIRS = libsvm-rank-2.81/matlab libsvm-weights-3.12/matlab orensemble SVORIM SVOREX
SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

.PHONY: subdirs $(SUBDIRS)
     
subdirs: $(SUBDIRS)

all: $(SUBDIRS)

clean: $(SUBCLEAN)
 
$(SUBDIRS):
	$(MAKE) -C $@

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* clean


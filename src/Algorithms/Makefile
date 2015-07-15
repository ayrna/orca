SUBDIRS = libsvm-rank-2.81/matlab libsvm-weights-3.12/matlab orensemble SVORIM SVOREX

.PHONY: subdirs $(SUBDIRS)
     
subdirs: $(SUBDIRS)

all: $(SUBDIRS)

clean: $(SUBDIRS)
 
$(SUBDIRS):
	$(MAKE) -C $@
 

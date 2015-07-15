SUBDIRS = libsvm-rank-2.81 libsvm-weights-3.12 orensemble SVORIM SVOREX

.PHONY: subdirs $(SUBDIRS)
     
subdirs: $(SUBDIRS)

all: $(SUBDIRS)

clean: $(SUBDIRS)
 
$(SUBDIRS):
	$(MAKE) -C $@
 

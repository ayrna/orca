SUBDIRS = libsvm-rank-2.81/matlab libsvm-weights-3.12/matlab liblinear-2.20/matlab orensemble SVORIM SVOREX

export MATLABDIR = /usr/local/MATLAB/R2017a/

# Use -std=c++11 for newer versions of Octave
export OCTAVE_CFLAGS = -std=c++11 -std=gnu99 -Wno-unused-result -O3 -fPIC -I$(OCTAVEDIR) -I..
export OCTAVEDIR = /usr/include/octave-4.0.3/octave/

SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

SUBOCTAVE = $(addsuffix .octave,$(SUBDIRS))

.PHONY: clean subdirs $(SUBDIRS)

all: | $(MATLABDIR) message subdirs clean

$(MATLABDIR):
	@echo "Folder $(MATLABDIR) does not exist. Please, set up MATLABDIR propertly"
	false

message:
	@echo "*************************************************************************"
	@echo " Note: some Matlab's versions have problems with libstdc++.so.6, which "
	@echo " can cause compilation warnings. If this happens, we recommend to search "
	@echo " for solutions in Matlab's forums for you specific Matlab ans OS version "
	@echo "*************************************************************************"

subdirs: $(SUBDIRS)

clean: $(SUBCLEAN)

octave: | $(OCTAVEDIR) message_octave $(SUBOCTAVE) clean

$(OCTAVEDIR):
	@echo "Folder $(OCTAVEDIR) does not exist. Please, set up OCTAVEDIR propertly"
	false

message_octave: 


$(SUBDIRS):
	$(MAKE) -e -C $@

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* clean

$(SUBOCTAVE): %.octave:
	$(MAKE) -C $* octave

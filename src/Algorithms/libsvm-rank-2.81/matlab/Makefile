# This Makefile is used under Linux

MATLABDIR ?= /usr/local/matlab
# for Mac
# MATLABDIR ?= /opt/local/matlab

CXX ?= g++
#CXX = gcc-4.1
#CXX = gcc
CFLAGS = -Wno-unused-result -O3 -fPIC -I$(MATLABDIR)/extern/include -I..

MEX = $(MATLABDIR)/bin/mex
MEX_OPTION = CC="$(CXX)" CXX="$(CXX)" CFLAGS="$(CFLAGS)" CXXFLAGS="$(CFLAGS)"
# comment the following line if you use MATLAB on 32-bit computer
MEX_OPTION += -largeArrayDims
MEX_EXT = $(shell $(MATLABDIR)/bin/mexext 2> /dev/null)

OCTAVEDIR ?= /usr/include/octave-4.0.3/octave
OCTAVE_MEX = env CC=$(CXX) mkoctfile
OCTAVE_MEX_OPTION = --mex
OCTAVE_MEX_EXT = mex
OCTAVE_CFLAGS ?= -Wall -O3 -fPIC -I$(OCTAVEDIR) -I..

all:	matlab

matlab:	binary

octave:
	@make MEX="$(OCTAVE_MEX)" MEX_OPTION="$(OCTAVE_MEX_OPTION)" \
	MEX_EXT="$(OCTAVE_MEX_EXT)" CFLAGS="$(OCTAVE_CFLAGS)" \
	binary

binary: svmpredict.$(MEX_EXT) svmtrain.$(MEX_EXT) libsvmread.$(MEX_EXT) libsvmwrite.$(MEX_EXT)

svmpredict.$(MEX_EXT):     svmpredict.cpp ../svm.h ../svm.o svm_model_matlab.o
	$(MEX) $(MEX_OPTION) svmpredict.cpp ../svm.o svm_model_matlab.o

svmtrain.$(MEX_EXT):       svmtrain.cpp ../svm.h ../svm.o svm_model_matlab.o
	$(MEX) $(MEX_OPTION) svmtrain.cpp ../svm.o svm_model_matlab.o

libsvmread.$(MEX_EXT):	libsvmread.c
	$(MEX) $(MEX_OPTION) libsvmread.c

libsvmwrite.$(MEX_EXT):	libsvmwrite.c
	$(MEX) $(MEX_OPTION) libsvmwrite.c

svm_model_matlab.o:     svm_model_matlab.cpp ../svm.h
	$(CXX) $(CFLAGS) -c svm_model_matlab.cpp

../svm.o: ../svm.cpp ../svm.h
	make -C .. svm.o

clean:
	rm -f *~ *.o *.obj ../svm.o

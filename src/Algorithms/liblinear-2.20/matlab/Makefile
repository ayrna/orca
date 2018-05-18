# This Makefile is used under Linux

MATLABDIR ?= /usr/local/matlab
# for Mac
# MATLABDIR ?= /opt/local/matlab

#CXX ?= g++
#CXX = gcc-4.1
CXX = gcc
CFLAGS = -Wall -O3 -fPIC -I$(MATLABDIR)/extern/include -I..
#CFLAGS = -Wall -Wconversion -O3 -fPIC -I$(MATLABDIR)/extern/include -I..

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
	@echo "please type make under Octave"
binary: train.$(MEX_EXT) predict.$(MEX_EXT) libsvmread.$(MEX_EXT) libsvmwrite.$(MEX_EXT)

train.$(MEX_EXT): svmtrain.c ../linear.h ../tron.o ../linear.o linear_model_matlab.o ../blas/blas.a
	$(MEX) $(MEX_OPTION) svmtrain.c ../tron.o ../linear.o linear_model_matlab.o ../blas/blas.a

predict.$(MEX_EXT): svmpredict.c ../linear.h ../tron.o ../linear.o linear_model_matlab.o ../blas/blas.a
	$(MEX) $(MEX_OPTION) svmpredict.c ../tron.o ../linear.o linear_model_matlab.o ../blas/blas.a

libsvmread.$(MEX_EXT):	libsvmread.c
	$(MEX) $(MEX_OPTION) libsvmread.c

libsvmwrite.$(MEX_EXT):	libsvmwrite.c
	$(MEX) $(MEX_OPTION) libsvmwrite.c

linear_model_matlab.o: linear_model_matlab.c ../linear.h
	$(CXX) $(CFLAGS) -c linear_model_matlab.c

../linear.o: ../linear.cpp ../linear.h
	make -C .. linear.o

../tron.o: ../tron.cpp ../tron.h
	make -C .. tron.o

../blas/blas.a: ../blas/*.c ../blas/*.h
	make -C ../blas OPTFLAGS='$(CFLAGS)' CC='$(CC)';

clean:
	make -C ../blas clean
	rm -f *~ *.o *.obj ../linear.o ../tron.o

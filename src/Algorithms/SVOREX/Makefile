# This Makefile is used under Linux

#MATLABDIR ?= /home/administrador/Matlab/
MATLABDIR ?= /usr/local/matlab/
# for Mac
# MATLABDIR ?= /opt/local/matlab

CXX ?= gcc

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

objects = alphas.o cachelist.o datalist.o def_settings.o kcv.o loadfile.o main.o ordinal_takestep.o setandfi.o smo_kernel.o smo_routine.o smo_settings.o smo_timer.o svc_predict.o

matlab: $(objects) mainSvorex.c
	$(MEX) $(MEX_OPTION) mainSvorex.c alphas.o cachelist.o datalist.o def_settings.o kcv.o loadfile.o main.o ordinal_takestep.o setandfi.o smo_kernel.o smo_routine.o smo_settings.o smo_timer.o svc_predict.o -output svorex

octave:
	@make MEX="$(OCTAVE_MEX)" MEX_OPTION="$(OCTAVE_MEX_OPTION)" \
	MEX_EXT="$(OCTAVE_MEX_EXT)" CFLAGS="$(OCTAVE_CFLAGS)" \
	matlab

original: main.c alphas.c cachelist.c datalist.c def_settings.c kcv.c loadfile.c ordinal_takestep.c setandfi.c smo_kernel.c smo_routine.c smo_settings.c smo_timer.c svc_predict.c
	gcc -o svorex main.c alphas.c cachelist.c datalist.c def_settings.c kcv.c loadfile.c ordinal_takestep.c setandfi.c smo_kernel.c smo_routine.c smo_settings.c smo_timer.c svc_predict.c -lm -O2 -Wall
clean:
	rm -f *.o svorex

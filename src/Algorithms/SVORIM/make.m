% This make.m is for MATLAB.

	mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims mainSvorim.c alphas.c cachelist.c datalist.c def_settings.c kcv.c loadfile.c ordinal_takestep.c setandfi.c smo_kernel.c smo_routine.c smo_settings.c smo_timer.c svc_predict.c


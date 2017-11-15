function make()
try
  % This part is for OCTAVE
  if (exist ('OCTAVE_VERSION', 'builtin'))
    setenv('CFLAGS','-std=c99 -O3 -fstack-protector-strong -Wformat -Werror=format-security') 
    mex mainSvorex.c alphas.c cachelist.c datalist.c def_settings.c kcv.c loadfile.c ordinal_takestep.c setandfi.c smo_kernel.c smo_routine.c smo_settings.c smo_timer.c svc_predict.c -output svorex
    delete *.o
  % This part is for MATLAB
  else
    mex COMPFLAGS="\$COMPFLAGS -std=c99 -O3" -largeArrayDims mainSvorex.c alphas.c cachelist.c datalist.c def_settings.c kcv.c loadfile.c ordinal_takestep.c setandfi.c smo_kernel.c smo_routine.c smo_settings.c smo_timer.c svc_predict.c -output svorex
  end
catch err
	fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
	disp(err.message);
	fprintf('=> Please check README for detailed instructions.\n');
end
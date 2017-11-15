% This make.m is for MATLAB and OCTAVE under Windows, Mac, and Unix
function make()
try
	% This part is for OCTAVE
	if (exist ('OCTAVE_VERSION', 'builtin'))
    setenv('CFLAGS','-std=c99 -O3 -fstack-protector-strong -Wformat -Werror=format-security') 
		mex libsvmread.c
		mex libsvmwrite.c
		mex -I.. svmtrain.c ../svm.cpp svm_model_matlab.c
		mex -I.. svmpredict.c ../svm.cpp svm_model_matlab.c
    delete *.o 
	% This part is for MATLAB
	% Add -largeArrayDims on 64-bit machines of MATLAB
	else
		mex COMPFLAGS="\$COMPFLAGS -std=c99 -O3" -largeArrayDims libsvmread.c
		mex COMPFLAGS="\$COMPFLAGS -std=c99 -O3" -largeArrayDims libsvmwrite.c
		mex COMPFLAGS="\$COMPFLAGS -std=c99 -O3" -I.. -largeArrayDims svmtrain.c ../svm.cpp svm_model_matlab.c
		mex COMPFLAGS="\$COMPFLAGS -std=c99 -O3" -I.. -largeArrayDims svmpredict.c ../svm.cpp svm_model_matlab.c
	end
catch err
	fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
	disp(err.message);
	fprintf('=> Please check README for detailed instructions.\n');
end

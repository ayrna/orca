% This make.m is for MATLAB and OCTAVE under Windows, Mac, and Unix
function make(opt)
if nargin < 1
    try
        % This part is for OCTAVE
        if (exist ('OCTAVE_VERSION', 'builtin'))
						if ispc
							setenv('CFLAGS','-std=c99 -O3')
							setenv('CC','gcc')
						else
							setenv('CFLAGS','-std=c99 -O3 -fstack-protector-strong -Wformat -Werror=format-security')
						end
            mex libsvmread.c
            mex libsvmwrite.c
            mex -I.. svmtrain.c ../svm.cpp svm_model_matlab.c
            mex -I.. svmpredict.c ../svm.cpp svm_model_matlab.c
            delete *.o
        % This part is for MATLAB
        % Add -largeArrayDims on 64-bit machines of MATLAB
        else
            if ispc
                mex COMPFLAGS="\$COMPFLAGS -std=c++98 -O3" -largeArrayDims libsvmread.c
                mex COMPFLAGS="\$COMPFLAGS -std=c++98 -O3" -largeArrayDims libsvmwrite.c
                mex COMPFLAGS="\$COMPFLAGS -std=c++98 -O3" -I.. -largeArrayDims svmtrain.c ../svm.cpp svm_model_matlab.c
                mex COMPFLAGS="\$COMPFLAGS -std=c++98 -O3" -I.. -largeArrayDims svmpredict.c ../svm.cpp svm_model_matlab.c
            else
                mex CFLAGS="\$CFLAGS -std=c++98 -O3" -largeArrayDims libsvmread.c
                mex CFLAGS="\$CFLAGS -std=c++98 -O3" -largeArrayDims libsvmwrite.c
                mex CFLAGS="\$CFLAGS -std=c++98 -O3" -I.. -largeArrayDims svmtrain.c ../svm.cpp svm_model_matlab.c
                mex CFLAGS="\$CFLAGS -std=c++98 -O3" -I.. -largeArrayDims svmpredict.c ../svm.cpp svm_model_matlab.c
            end
        end
    catch err
        fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
        disp(err.message);
        fprintf('=> Please check README for detailed instructions.\n');
    end
elseif nargin == 1
    switch lower(opt)
        case 'clean'
            delete *.o
        case 'cleanall'
            delete *.o
            delete *.mexa64
        otherwise
            error('make option "%s" not recognized', opt)
    end
end

% This make.m is for MATLAB and OCTAVE under Windows, Mac, and Unix
function make(opt)
fprintf('=> Building libsvm-weights.\n');
if nargin < 1
    try
        % This part is for OCTAVE
        if (exist ('OCTAVE_VERSION', 'builtin'))
			% Use -std=c++11 for newer versions of Octave
            if ispc
                setenv('CFLAGS','-std=gnu99 -O3 -Wno-unused-result')
                setenv('CC','gcc')
            else
                setenv('CFLAGS','-O3 -Wno-unused-result')
            end
            mex -I.. -std=c++11 -O3 -Wno-unused-result svmtrain.cpp ../svm.cpp svm_model_matlab.cpp
            mex -I.. -std=c++11 -O3 -Wno-unused-result svmpredict.cpp ../svm.cpp svm_model_matlab.cpp
            delete *.o
        % This part is for MATLAB
        % Add -largeArrayDims on 64-bit machines of MATLAB
        else
            if ispc
                mex COMPFLAGS="\$COMPFLAGS -std=c99 -O3 -Wno-unused-result" -I.. -largeArrayDims svmtrain.cpp ../svm.cpp svm_model_matlab.cpp
                mex COMPFLAGS="\$COMPFLAGS -std=c99 -O3 -Wno-unused-result" -I.. -largeArrayDims svmpredict.cpp ../svm.cpp svm_model_matlab.cpp
            else
                mex CFLAGS="\$CFLAGS -O3 -Wno-unused-result" -I.. -largeArrayDims svmtrain.cpp ../svm.cpp svm_model_matlab.cpp
                mex CFLAGS="\$CFLAGS -O3 -Wno-unused-result" -I.. -largeArrayDims svmpredict.cpp ../svm.cpp svm_model_matlab.cpp
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
            delete *.mex
        otherwise
            error('make option "%s" not recognized', opt)
    end
end
    

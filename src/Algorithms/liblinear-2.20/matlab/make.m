% This make.m is for MATLAB and OCTAVE under Windows, Mac, and Unix
function make(opt)
fprintf('=> Building liblinear.\n');
if nargin < 1
    try
        % This part is for OCTAVE
        if(exist('OCTAVE_VERSION', 'builtin'))
            % Use -std=c++11 for newer versions of Octave
            if ispc
                setenv('CFLAGS','-std=gnu99 -O3')
                setenv('CC','gcc')
            else
                setenv('CFLAGS','-O3 -fstack-protector-strong -Wformat -Werror=format-security')
            end
            %mex libsvmread.c
            %mex libsvmwrite.c
            mex -I.. -O3 svmtrain.cpp linear_model_matlab.cpp ../linear.cpp ../tron.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            mex -I.. -O3 svmpredict.cpp linear_model_matlab.cpp ../linear.cpp ../tron.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            delete *.o
            % This part is for MATLAB
            % Add -largeArrayDims on 64-bit machines of MATLAB
        else
            if ispc
                %mex COMPFLAGS="\$COMPFLAGS -std=c99 -O3" -largeArrayDims libsvmread.c
                %mex COMPFLAGS="\$COMPFLAGS -std=c99 -O3" -largeArrayDims libsvmwrite.c
                mex COMPFLAGS="\$COMPFLAGS -O3" -I.. -largeArrayDims svmtrain.cpp linear_model_matlab.cpp ../linear.cpp ../tron.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
                mex COMPFLAGS="\$COMPFLAGS -O3" -I.. -largeArrayDims svmpredict.cpp linear_model_matlab.cpp ../linear.cpp ../tron.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            else
                %mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmread.c
                %mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmwrite.c
                mex CFLAGS="\$CFLAGS" -I.. -largeArrayDims svmtrain.cpp linear_model_matlab.cpp ../linear.cpp ../tron.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
                mex CFLAGS="\$CFLAGS" -I.. -largeArrayDims svmpredict.cpp linear_model_matlab.cpp ../linear.cpp ../tron.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
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

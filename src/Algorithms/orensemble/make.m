% ORBoost does not have a matlab's interface. There we use external
% Makefile
function make(opt)
fprintf('=> Building ORBoost.\n');
if nargin < 1
    try
        if ispc
            warning('Compilation of ORBoost is not supported from MATLAB console in Windows. Unpaking binaries. Please see instalation instructions. ')
            unzip('orensemble-binaries-win.zip')
        else
          if (exist ('OCTAVE_VERSION', 'builtin'))
            setenv('CFLAGS','-O3 -fstack-protector-strong -Wformat -Werror=format-security -Wno-unused-result')
            setenv('CC','g++')
            system('make'); 
            unsetenv('CC')
          else
            system('make'); 
          end
        end
    catch err
        fprintf('Error: %s failed\n', err.stack(1).file);
        disp(err.message);
    end
elseif nargin == 1
    switch lower(opt)
        case 'clean'
            system('make clean');
        case 'cleanall'
            warning('Make clean all not implemented already for ORBoost')
        otherwise
            error('make option "%s" not recognized', opt)
    end
end

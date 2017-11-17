% ORBoost does not have a matlab's interface. There we use external
% Makefile
function make(opt)
if nargin < 1
    try
        if ispc
            warning('Compilation of ORBoost is not supported from MATLAB console in Windows. Unpaking binaries. Please see instalation instructions. ')
            unzip('orensemble-binaries-win.zip')
        else
            system('make'); 
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

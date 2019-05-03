% COPYRIGHT
% This file is part of ORCA: https://github.com/ayrna/orca
% Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
% Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
% Copyright:
%     This software is released under the The GNU General Public License v3.0 licence
%     available at http://www.gnu.org/licenses/gpl-3.0.html
% RUN SINGLE TESTS
% This script runs single tests using the ORCA API. The toy dataset is used
% with a 1 -hold-out experimental. Reference performance is compared. To
% add an script just place it in the test/singletests folder following
% other examples
%
clear;

tests_dir = ['code-examples'];
eval(['cd  ' tests_dir])
files = dir('example*.m');

for i=1:length(files)
    % Clear (almost) all the variables to avoid issues with some mex files in Octave +4.2.2
    if (exist ('OCTAVE_VERSION', 'builtin') > 0)
      clear -x tests_dir files i
    else
      clearvars -except tests_dir files i
    end
    fprintf('==============================================\n');
    cmd = files(i).name;
    fprintf('Processing %s...\n', cmd);
    eval(cmd(1:end-2))
end

% error is called in individual tests, so if code reach this point all the
% tests have been run successfully
fprintf('\nAll tests ended successfully\n')

rmpath Algorithms
rmpath Measures
rmpath Utils
cd ..

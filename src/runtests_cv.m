%% COPYRIGHT
% This file is part of ORCA: https://github.com/ayrna/orca
% Original authors: Pedro Antonio Guti??rrez, Mar??a P??rez Ortiz, Javier S??nchez Monedero
% Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
% Copyright:
%     This software is released under the The GNU General Public License v3.0 licence
%     available at http://www.gnu.org/licenses/gpl-3.0.html
%% RUN ALL TESTS
% This script runs full experiment tests using the ORCA INI files to describe an
% experiment. The toy dataset is used with a 1 or 30-hold-out experimental
% design and method's parameter optimization. At the end of the test there
% should be one new folder for each method in the 'Experiments' directory.
% The following performamnce reports should appear in
% 'Experiments/exp-<id>/Results/'
%
% - mean-results_matrices_sum_test.csv
% - mean-results_matrices_sum_train.csv
% - mean-results_test.csv
% - mean-results_train.csv
%
% RUN INDIVIDUAL TESTS
% To run an individual test just use the right function call
% Utilities.runExperiments('tests/cvtests-1-holdout/<script>')
% Utilities.runExperiments('tests/cvtests-30-holdout/<script>')
%

addpath Utils
% Fast test
tests_dir = 'tests/cvtests-1-holdout';
% Long test
% tests_dir = ['tests' filesep 'cvtests-30-holdout'];
files = dir(tests_dir);

% Delete .. and .
files(1:2) = [];

for i=1:length(files)
    disp(['Running ' tests_dir '/'  files(i).name])
	% Clear (almost) all the variables to avoid issues with some mex files in Octave +4.2.2
	if (exist ('OCTAVE_VERSION', 'builtin') > 0)
		clear -x tests_dir files i
    else
		clearvars -except tests_dir files i
    end
    exp_dir = Utilities.runExperiments([tests_dir '/'  files(i).name], 'parallel', false);
    try
        csv_result = [exp_dir filesep 'Results' filesep 'mean-results_test.csv'];
        results = csvread(csv_result, 1,1);
        
        % Check we have some numerical results.
        if sum(results) > 0
            fprintf('Test passed for %s\n', files(i).name);
        else
            error('Test FAILED for %s. CSV files do not contain valid data. \n', files(i).name)
        end
    catch err
        error('Test FAILED for "%s". Unable to open CSV results file', files(i).name)
    end
    
    % This avoids colisions in logs dir names with fast methods (i.e.
    % elm...)
    pause(1);
end

fprintf('\nAll tests ended successfully\n')

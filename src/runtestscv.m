% This script runs full experiment test using the ORCA scripts to describe and
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
% To run an individual test just use the right function call
%
% Utilities.runExperiments('tests/cvtests-1-holdout/<script>')
% Utilities.runExperiments('tests/cvtests-30-holdout/<script>')

% Fast test
tests_dir = ['tests' filesep 'cvtests-1-holdout'];
% Long test 
% tests_dir = ['tests' filesep 'cvtests-30-holdout'];
files = dir(tests_dir);

% Delete .. and .
files(1:2) = [];

for i=1:length(files)
    exp_dir = Utilities.runExperiments([tests_dir filesep  files(i).name], false);
    try 
        %result_csv = csvread(['Experiments' filesep exp_dir filesep 'Results' filesep 'mean-results_test.csv'], 1,1);
        csv_result = [exp_dir filesep 'Results' filesep 'mean-results_test.csv'];
        %results = csvread(csv_result, 1,0);
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

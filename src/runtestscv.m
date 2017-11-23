%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) Pedro Antonio Gutiérrez (pagutierrez at uco dot es)
% María Pérez Ortiz (i82perom at uco dot es)
% Javier Sánchez Monedero (jsanchezm at uco dot es)
%
% This file contains the abstract class that implements the different metrics for evaluation a classifier, presented in the paper Ordinal regression methods: survey and experimental study published in the IEEE Transactions on Knowledge and Data Engineering.
%
% The code has been tested with Ubuntu 12.04 x86_64, Debian Wheezy 8, Matlab R2009a and Matlab 2011
%
% If you use this code, please cite the associated paper
% Code updates and citing information:
% http://www.uco.es/grupos/ayrna/orreview
% https://github.com/ayrna/orca
%
% AYRNA Research group's website:
% http://www.uco.es/ayrna
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
% Licence available at: http://www.gnu.org/licenses/gpl-3.0.html
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
tests_dir = 'tests/cvtests-1-holdout';
% Long test
% tests_dir = ['tests' filesep 'cvtests-30-holdout'];
files = dir(tests_dir);

% Delete .. and .
files(1:2) = [];

for i=1:length(files)
    exp_dir = Utilities.runExperiments([tests_dir '/'  files(i).name], false);
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

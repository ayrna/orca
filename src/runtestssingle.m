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
% This script runs single tests using the ORCA API. The toy dataset is used
% with a 1 -hold-out experimental. Reference performance is compared. To
% add an script just place it in the test/singletests folder following
% other examples
%
addpath Algorithms
addpath Measures
tests_dir = ['tests' filesep 'singletests'];
eval(['addpath ' tests_dir])

files = dir([tests_dir filesep '*.m']);

% Load the different partitions of the dataset
load ../exampledata/1-holdout/toy/matlab/train_toy.0
load ../exampledata/1-holdout/toy/matlab/test_toy.0

% "patterns" refers to the input variables and targets to the output one
train.patterns = train_toy(:,1:end-1);
train.targets = train_toy(:,end);
test.patterns = test_toy(:,1:end-1);
test.targets = test_toy(:,end);

for i=1:length(files)
    cmd = files(i).name;
    fprintf('Processing %s...\n', cmd);
    eval(cmd(1:end-2))
end

% error is called in individual tests, so if code reach this point all the
% tests have been run successfully
fprintf('\nAll tests ended successfully\n')

rmpath Algorithms
rmpath Measures
eval(['rmpath ' tests_dir])

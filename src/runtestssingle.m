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
    eval(cmd(1:end-2))
end

fprintf('\nAll tests ended successfully\n')

rmpath Algorithms
rmpath Measures
eval(['rmpath ' tests_dir])

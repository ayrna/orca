% Note: this code should be run from orca/src/code-examples
clear param;
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
  pkg load statistics
end

% Load data
ERAData = csvread('../../exampledata/ERA.csv');

% Check the first 20 rows
ERAData(1:20,:)

% Extract targets
targets = ERAData(:,end);

% Generate h holdout partitions
h=30;

% Prepare filesystem
nameDataset = 'era';
rootDir = fullfile('..', '..', 'exampledata', '30-holdout', nameDataset);
mkdir(rootDir);
rootDir = fullfile(rootDir,'matlab');
mkdir(rootDir);

% For each partitions
for ff = 1:h
    CVO = cvpartition(targets,'HoldOut',0.25); % 25% of patterns for the test set
    if (exist ('OCTAVE_VERSION', 'builtin') > 0)
      trIdx = training(CVO,1);
      teIdx = test(CVO,1);
    else
      trIdx = CVO.training(1);
      teIdx = CVO.test(1);
    end
    dlmwrite(fullfile(rootDir,sprintf('train-%s.%d',nameDataset,ff-1)),ERAData(trIdx,:),' ');
    dlmwrite(fullfile(rootDir,sprintf('test-%s.%d',nameDataset,ff-1)),ERAData(teIdx,:),' ');
end

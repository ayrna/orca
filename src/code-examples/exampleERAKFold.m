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

% Generate k fold partitions
k=10;
CVO = cvpartition(targets,'KFold',k);

% Prepare filesystem
nameDataset = 'era';
rootDir = fullfile('..', '..', 'exampledata', '10-fold', nameDataset);
mkdir(rootDir);
rootDir = fullfile(rootDir,'matlab');
mkdir(rootDir);

% For each fold
for ff = 1:k
    if (exist ('OCTAVE_VERSION', 'builtin') > 0)
        trIdx = training(CVO,ff);
        teIdx = test(CVO,ff);
    else
        trIdx = CVO.training(ff);
        teIdx = CVO.test(ff);
    end
    dlmwrite(fullfile(rootDir,sprintf('train-%s.%d',nameDataset,ff-1)),ERAData(trIdx,:),' ');
    dlmwrite(fullfile(rootDir,sprintf('test-%s.%d',nameDataset,ff-1)),ERAData(teIdx,:),' ');
end

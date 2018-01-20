% Load data
ERAData = table2array(readtable('../../exampledata/ERA.csv'));

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
for ff = 1:CVO.NumTestSets
    trIdx = CVO.training(ff);
    teIdx = CVO.test(ff);
    dlmwrite(fullfile(rootDir,sprintf('train-%s.%d',nameDataset,ff-1)),ERAData(trIdx,:),' ');
    dlmwrite(fullfile(rootDir,sprintf('test-%s.%d',nameDataset,ff-1)),ERAData(teIdx,:),' ');
end
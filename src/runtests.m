% To run an individual test just use the right function call
%
% Utilities.runExperiments('tests/cssvc')
% Utilities.runExperiments('tests/elmop')
% Utilities.runExperiments('tests/kdlor')
% Utilities.runExperiments('tests/orboostall')
% Utilities.runExperiments('tests/pom')
% Utilities.runExperiments('tests/redsvm')
% Utilities.runExperiments('tests/svc1v1')
% Utilities.runExperiments('tests/svc1va')
% Utilities.runExperiments('tests/svmop')
% Utilities.runExperiments('tests/svorex')
% Utilities.runExperiments('tests/svorim')
% Utilities.runExperiments('tests/svorimlin')
% Utilities.runExperiments('tests/svr')

d = dir('tests');

% Delete .. and .
d(1)=[];
d(1)=[];

for i=1:length(d)
    Utilities.runExperiments(['tests/' d(1).name], true);
end



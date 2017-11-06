% To run an individual test just use the right function call
%
% Utilities.runExperiments('tests/cvtests/cssvc')
% Utilities.runExperiments('tests/cvtests/elmop')
% Utilities.runExperiments('tests/cvtests/kdlor')
% Utilities.runExperiments('tests/cvtests/orboostall')
% Utilities.runExperiments('tests/cvtests/pom')
% Utilities.runExperiments('tests/cvtests/redsvm')
% Utilities.runExperiments('tests/cvtests/svc1v1')
% Utilities.runExperiments('tests/cvtests/svc1va')
% Utilities.runExperiments('tests/cvtests/svmop')
% Utilities.runExperiments('tests/cvtests/svorex')
% Utilities.runExperiments('tests/cvtests/svorim')
% Utilities.runExperiments('tests/cvtests/svorimlin')
% Utilities.runExperiments('tests/cvtests/svr')

d = dir(['tests' filesep 'cvtests']);

% Delete .. and .
d(1)=[];
d(1)=[];

for i=1:length(d)
    Utilities.runExperiments(['tests' filesep 'cvtests' filesep  d(1).name], true);
end

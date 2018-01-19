pomT = readtable('pom-mean-results_test.csv');
svorimT = readtable('svorim-mean-results_test.csv');
svc1v1T = readtable('svc1v1-mean-results_test.csv');

c = categorical({'pasture','pyrim10-','tae','toy'});
bar(c,[pomT.MeanAMAE svorimT.MeanAMAE svc1v1T.MeanAMAE])
legend('POM', 'SVORIM', 'SVC1V1')
title('AMAE performance (smaller is better)')

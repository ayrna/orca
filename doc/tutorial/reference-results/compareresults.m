pomT = readtable('../doc/tutorial/reference-results/pom-mean-results_test.csv');
svorimT = readtable('../doc/tutorial/reference-results/svorim-mean-results_test.csv');
svc1v1T = readtable('../doc/tutorial/reference-results/svc1v1-mean-results_test.csv');

c = categorical({'pasture','tae','toy'});
bar(c,[pomT.MeanAMAE svorimT.MeanAMAE svc1v1T.MeanAMAE])
legend('POM', 'SVORIM', 'SVC1V1')
title('AMAE performance (smaller is better)')

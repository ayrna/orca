/*******************************************************************************\

	main.c in Sequential Minimal Optimization ver2.0
		
	entry function.
		
	Chu Wei Copyright(C) National Univeristy of Singapore
	Create on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Update on Aug. 23 2001 

\*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#ifndef __MACH__
    #include <malloc.h>
#endif
#include <string.h>
#include <limits.h>
#include <math.h>
#include <time.h>
#include "smo.h"
#define VERSION (0)

int main( int argc, char * argv[])
{
	def_Settings * defsetting = NULL ;
	smo_Settings * smosetting = NULL ;
	kcv_Settings * kcvsetting ;
	//Data_Node * node ;
	char buf[LENGTH] ;
	unsigned int sz = 0;
	unsigned int index = 0 ;
	double parameter = 0 ;
	//double * guess ;
	FILE * log ; 
	printf("\nSupport Vector Ordinal Regression Using K-fold Cross Validation v2.%d \n--- Chu Wei Copyright(C) 2003-2004\n\n", VERSION) ;
	if ( 1 == argc || NULL == (defsetting = Create_def_Settings(argv[--argc])) )
	{
		// display help	
		printf("\nUsage:  svor [-v] [...] [-R r] file \n\n") ;
		printf("  file   specifies the file containing training samples.\n") ;
		printf("  -v     activates the verbose mode to display message.\n") ;
		printf("  -F  k  k-fold is used in cross validation (default 5 folds).\n") ;
		printf("  -Cs s  set searching step of C at s in log10 scale (default 0.5).\n") ;
		printf("  -Cc c  start searching C at c (default 0.1).\n") ;		
		printf("  -Ce e  stop searching C at e (default  100).\n") ;
		printf("  -Ks s  set searching step of K at s in log10 scale (default 0.5).\n") ;
		printf("  -Kc c  start searching K at c (default 0.01).\n") ;		
		printf("  -Ke e  stop searching K at e (default 10).\n") ;	
		//printf("  -L     use imbalanced Linear kernel (default Gaussian kernel).\n") ;
		printf("  -P  p  use Polynomial kernel with order p (default Gaussian kernel).\n") ;
		//printf("  -B     force regularizers Balanced for classification only.\n") ;
		//printf("  -E  e  set Epsilon at e for regression only (default 0.1).\n") ;
		printf("  -Z  z  set the times of Zooming at z (default 2).\n") ;			
		printf("  -i     normalize the training inputs.\n") ;		
		//printf("  -o     normalize the training targets.\n") ;		
		printf("  -a     activates loading weighted kernels.\n") ;
		printf("  -S  s  set the Seed of random number generator at s (default random).\n") ;
		printf("  -R  r  set the Rehearsal times of fold generation at r (default 1).\n") ;
		printf("  -T  t  set Tolerance at t (default 0.001).\n") ;
		printf("new option:\n") ;
		printf("  -Z  0  set the zooming at 0 to skip cross-validation.\n") ;			
		printf("  -Ko o  fix K at o manually (default 1).\n") ;			
		printf("  -Co o  fix C at o manually (default  1).\n") ;			
		printf("\n") ;
		if (NULL !=defsetting)
			Clear_def_Settings( defsetting ) ;
		return 0;
	}
	else
	{
		if (argc>1)
			printf("Options:\n") ;
		do
		{
			strcpy(buf, argv[--argc]) ;
			sz = strlen(buf) ;
			//printf ("%s  %d\n", buf, sz) ;
			if ( '-' == buf[0] )
			{				
				for (index = 1 ; index < sz ; index++)
				{
					switch (buf[index])
					{
					case 'v' :
						printf("  - Verbose mode in display.\n") ;
						defsetting->smo_display = TRUE ;
						break ;	
					case 'a' :
						printf("  - kernels with Ard parameters.\n") ;
						defsetting->ardon = TRUE ;	
						break ;
					case 'o' :
						printf("  - normalize the Outputs in training data.\n") ;
						defsetting->normalized_output = TRUE ;	
						defsetting->pairs.normalized_output = TRUE ;
						break ;
					case 'i' :
						printf("  - normalize the Inputs in training data.\n") ;
						defsetting->normalized_input = TRUE ;	
						defsetting->pairs.normalized_input = TRUE ;
						break ;
					case 'S' :
						if (parameter>0)
						{
							printf("  - specify %.0f as the seed of random number.\n", parameter) ;
							defsetting->seeds = (unsigned int)parameter ;
						}
						break ;
					case 'F' :
						if (parameter>1)
						{
							printf("  - %.0f-fold cross validation.\n", parameter) ;
							defsetting->kfold = (unsigned int)parameter ;
						}
						break ;
					case 'Z' :
						if (parameter>=0)
						{
							printf("  - Zoom in scale %.0f.\n", parameter) ;
							defsetting->loops = (unsigned int)parameter ;
						}
						break ;
					case 'R' :
						if (parameter>=1)
						{
							printf("  - Rehearsal %.0f times.\n", parameter) ;
							defsetting->repeat = (unsigned int)parameter ;
						}
						break ;
					case 'L' :
						printf("  - choose Linear kernel.\n") ;
						defsetting->kernel = LINEAR ;						
						break ;
					case 'B' :
						printf("  - set regularization factors balanced.\n") ;
						defsetting->smo_balance = TRUE ;
						break ;
					case 'T' :
						if (parameter>0)
						{
							printf("  - set Tol as %.6f.\n", parameter) ;
							defsetting->tol = parameter ;
						}
						break ;
					case 'C' :
						if (parameter > 0)
						{ 
							if (index + 1 == sz && parameter != DEF_COARSESTEP )
							{
								printf("  - C is invalid.\n") ;
								parameter = 0;
							}
							else if (index+1==sz-1)
							{
								index+=1;
								switch (buf[index])
								{									
								case 's' :
									defsetting->def_lnC_step = parameter ;
									printf("  - initialize lnC_step at the value %f.\n", parameter) ;
									parameter = 0 ;
									break ;
								case 'c' :
									defsetting->def_lnC_start = log10(parameter) ;
									printf("  - C start at %f.\n", parameter) ;
									parameter = 0 ;
									break ;
								case 'e' :
									defsetting->def_lnC_end = log10(parameter) ;
									printf("  - C end at %f.\n", parameter) ;
									parameter = 0 ;
									break ;
								case 'o' :
									defsetting->vc = (parameter) ;
									printf("  - C at %f.\n", parameter) ;
									parameter = 0 ;
									break ;
								default :
									printf("  - C%c is invalid.\n", buf[index]) ;
									break ;
								}
							}							
						}
						break ;						
					case 'K' :
						if (parameter > 0)
						{ 
							if (index + 1 == sz && parameter != DEF_COARSESTEP )
							{
								printf("  - K is invalid.\n") ;
								parameter = 0;
							}
							else if (index+1==sz-1)
							{
								index+=1;
								switch (buf[index])
								{									
								case 's' :
									defsetting->def_lnK_step = parameter ;
									printf("  - initialize lnK_step at the value %f.\n", parameter) ;
									parameter = 0 ;
									break ;
								case 'c' :
									defsetting->def_lnK_start = log10(parameter) ;
									printf("  - K start at %f.\n", parameter) ;
									parameter = 0 ;
									break ;
								case 'e' :
									defsetting->def_lnK_end = log10(parameter) ;
									printf("  - K end at %f.\n", parameter) ;
									parameter = 0 ;
									break ;
								case 'o' :
									defsetting->kappa = (parameter) ;
									printf("  - K at %f.\n", parameter) ;
									parameter = 0 ;
									break ;
								default :
									printf("  - K%c is invalid.\n", buf[index]) ;
									break ;
								}
							}							
						}
						break ;
					case 'P' :						
						if (parameter >= 1)
						{ 
							defsetting->kernel = POLYNOMIAL ;
							defsetting->p = (unsigned int) parameter ;
							printf("  - choose Polynomial kernel with order %d.\n", defsetting->p) ;
							parameter = 0 ;
							defsetting->def_lnK_start = 0 ;
							defsetting->def_lnK_end = 0 ;
						}					
						break ;	
					default :
						if ('-' != buf[index])
							printf("  -%c is invalid.\n", buf[index]) ;
						break ;
					}
				}
			}
			else
				parameter = atof(buf) ;
		}
		while ( argc > 1 ) ;
		printf("\n") ;
	}

	log = fopen ("validation_implicit.log", "w+t") ;
	if (NULL != log)
		fclose(log) ;	// clear the old file.

	while ( TRUE == Update_def_Settings(defsetting) ) 
	{
/*		sz = defsetting->loops ;
		while (sz > 0)
		{
			// coarse search
			kcvsetting = Create_Kcv ( defsetting ) ;
			while (kcvsetting->index<defsetting->repeat)
			{
				Rehearsal_Kcv ( kcvsetting, defsetting ) ;
				Init_Kcv ( kcvsetting, defsetting ) ;
				kcvsetting->index += 1 ; 
			}			
			// update defsetting 
			defsetting->lnC_start = kcvsetting->best_lnC - defsetting->lnC_step*(1.0-1/defsetting->zoomin) ;		 
			defsetting->lnC_end = kcvsetting->best_lnC + defsetting->lnC_step*(1.0-1/defsetting->zoomin) ;		
			defsetting->lnK_start = kcvsetting->best_lnK - defsetting->lnK_step*(1.0-1/defsetting->zoomin) ;		 
			defsetting->lnK_end = kcvsetting->best_lnK + defsetting->lnK_step*(1.0-1/defsetting->zoomin) ;
			defsetting->lnC_step = defsetting->lnC_step/defsetting->zoomin ;
			defsetting->lnK_step = defsetting->lnK_step/defsetting->zoomin ;
			defsetting->time += kcvsetting->time ;		
			defsetting->best_rate = kcvsetting->best_rate ;
			defsetting->vc = pow(10.0, kcvsetting->best_lnC) ;
			defsetting->kappa = pow(10.0, kcvsetting->best_lnK) ;
			if (1==sz)
			{
                		log = fopen ("validation_implicit.log", "a+t") ;
                		if (NULL != log)
                		{
                        		fprintf(log,"%lu %u %u %f %f %f %.6f\n", defsetting->pairs.dimen, defsetting->kfold, defsetting->loops, log10(defsetting->vc), log10(defsetting->kappa), defsetting->best_rate, defsetting->time) ;
                        		fclose(log) ;
                		}
			}
			Clear_Kcv ( kcvsetting ) ;
			sz -= 1 ;
		}
*/
		// save validation output
		defsetting->lnC_start = log10(defsetting->vc) ;		 
		defsetting->lnC_end = log10(defsetting->vc) ;		
		defsetting->lnK_start = log10(defsetting->kappa) ;		 
		defsetting->lnK_end = log10(defsetting->kappa) ;
		defsetting->lnC_step = defsetting->lnC_step ;
		defsetting->lnK_step = defsetting->lnK_step ;		
/*		
		guess = (double *) calloc(defsetting->pairs.count,sizeof(double)) ;
		kcvsetting = Create_Kcv ( defsetting ) ;
		while (kcvsetting->index<defsetting->repeat)
		{		
			Rehearsal_Kcv ( kcvsetting, defsetting ) ;
			Init_Kcv ( kcvsetting, defsetting ) ;
                	kcvsetting->index += 1 ;
			sz = 0 ;
			node = defsetting->pairs.front ;
                        while(NULL != node)
                        {
				guess[sz] += node->fx ; 
                                node = node->next ;
				sz += 1 ;
                        }
		}		
		sprintf(buf, "%s.validation", defsetting->inputfile) ;
		parameter = 0 ;
		log = fopen (buf, "w+t") ;
		if (NULL != log)
		{
			printf("save validation output in %s.\n", buf) ;
			node = defsetting->pairs.front ;
			sz = 0 ;
			while(NULL != node)
			{
				fprintf(log,"%f ", guess[sz]/(double)defsetting->repeat) ;
                                fprintf(log," %u\n", node->target) ;
				node = node->next ;
				sz += 1 ;
			}
			fclose(log) ;
		}
		free (guess) ;
		Clear_Kcv ( kcvsetting ) ;//
*/
		defsetting->training.count = defsetting->pairs.count ;		
		defsetting->training.front = defsetting->pairs.front ;		
		defsetting->training.rear = defsetting->pairs.rear ;	
		defsetting->training.classes = defsetting->pairs.classes ;	
		defsetting->training.dimen = defsetting->pairs.dimen ;
		defsetting->training.featuretype = defsetting->pairs.featuretype ;
		// create smosettings
		printf ("\n\n TESTING on %s...\n", defsetting->testfile ) ;	
		smosetting = Create_smo_Settings(defsetting) ; 
		smosetting->pairs = &defsetting->pairs ;  		
		defsetting->training.count = 0 ;		
		defsetting->training.front = NULL ;		
		defsetting->training.rear = NULL ;
		defsetting->training.featuretype = NULL ;
		// load test data
		if ( FALSE == smo_Loadfile(&(defsetting->testdata), defsetting->testfile, defsetting->pairs.dimen) )
		{
			printf ("No testing data found in the file %s.\n", defsetting->testfile ) ;
			svm_saveresults (&defsetting->pairs, smosetting) ;		
		}
		// calculate the test output
		else
		{
			smo_routine (smosetting) ;
			svm_predict (&defsetting->testdata, smosetting) ;
			svm_saveresults (&defsetting->testdata, smosetting) ;

			if (ORDINAL == smosetting->pairs->datatype)
				printf ("\r\nTEST ERROR NUMBER %.0f, AAE %.0f and SVs %.0f, at C=%.3f Kappa=%.3f with %.3f seconds.\r\n", 
				smosetting->testerror*defsetting->testdata.count,smosetting->testrate*defsetting->testdata.count, smosetting->svs, smosetting->vc, smosetting->kappa, smosetting->smo_timing) ;

			if (NULL != (log = fopen ("kfoldsvc.log", "a+t")) ) 
			{
				if (REGRESSION == smosetting->pairs->datatype)
					fprintf(log,"%d-fold: TEST ASE %f, AAE %f and SVs %.0f at C=%f and Kappa=%f with %.3f seconds.\r\n", defsetting->kfold, smosetting->testrate, smosetting->testerror, smosetting->svs, smosetting->vc, smosetting->kappa, smosetting->smo_timing) ;
				else
					fprintf(log,"%d-fold: TEST ERROR %f, RATE %f and SVs %.0f at C=%f and Kappa=%f with %.3f seconds.\r\n", defsetting->kfold, smosetting->testerror, smosetting->testrate, smosetting->svs, smosetting->vc, smosetting->kappa, smosetting->smo_timing) ;		
				fclose(log) ;
			}
			// write another log
			if (ORDINAL != smosetting->pairs->datatype)
			{
				if (NULL != (log = fopen ("ordinal.log", "a+t")) )
				{
					fprintf(log,"%.0f %.0f %f %.3f\n", smosetting->testerror*defsetting->testdata.count, smosetting->testrate*defsetting->testdata.count, smosetting->testrate, smosetting->smo_timing) ;
					fclose(log) ;                   
				}
			}
			if (ORDINAL == smosetting->pairs->datatype)
			{
				if (NULL != (log = fopen ("ordinal_implicit.log", "a+t")) )
				{
					fprintf(log,"%.0f %.0f %f %f\n", smosetting->testerror*defsetting->testdata.count, smosetting->testrate*defsetting->testdata.count, smosetting->testrate, smosetting->smo_timing) ;
					fclose(log) ;                   
				}
			}
		}
		Clear_smo_Settings( smosetting ) ;

	}
	// free memory then exit
	Clear_def_Settings( defsetting ) ;	
	return 0;
}
//end of main.c 

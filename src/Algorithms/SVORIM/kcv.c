/* k-fold cross validation */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <limits.h>
#include "smo.h"


kcv_Settings * Create_Kcv ( def_Settings * defsetting )
{
	kcv_Settings * kcvsetting ;
	Data_Node * node ;
	unsigned int * labelnum ; 
	unsigned int index ;

	if ( NULL == defsetting )
		return NULL ;
	if ( TRUE == Is_Data_Empty(&defsetting->pairs) )		
		return NULL ;
	
	kcvsetting = (kcv_Settings *) malloc (sizeof(kcv_Settings)) ;
	if (NULL == kcvsetting)
	{	
		printf("fail to malloc kcv.\r\n") ;
		return NULL ;
	}
	kcvsetting->best_lnC = 0 ;
	kcvsetting->best_lnK = 0 ;
	kcvsetting->index = 0 ;
	kcvsetting->lnC_start = min(defsetting->lnC_start, defsetting->lnC_end) ;
	kcvsetting->lnK_start = min(defsetting->lnK_start, defsetting->lnK_end) ;
	kcvsetting->lnC_end = max(defsetting->lnC_start, defsetting->lnC_end) ;
	kcvsetting->lnK_end = max(defsetting->lnK_start, defsetting->lnK_end) ;
	if (defsetting->kernel == POLYNOMIAL)
	{
		kcvsetting->lnK_start = 0 ;
		kcvsetting->lnK_end = 0 ;
	}
	kcvsetting->lnK_step = defsetting->lnK_step ;
	kcvsetting->lnC_step = defsetting->lnC_step ;
	kcvsetting->C_steps = (unsigned int) floor((kcvsetting->lnC_end - kcvsetting->lnC_start + defsetting->eps)/kcvsetting->lnC_step) + 1 ;
	kcvsetting->K_steps = (unsigned int) floor((kcvsetting->lnK_end - kcvsetting->lnK_start + defsetting->eps)/kcvsetting->lnK_step) + 1 ;
	kcvsetting->lnC = (double *) malloc(sizeof(double)*kcvsetting->C_steps) ;
	kcvsetting->lnK = (double *) malloc(sizeof(double)*kcvsetting->K_steps) ;
	kcvsetting->kfold = defsetting->kfold ;
	kcvsetting->cv_error = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	kcvsetting->cv_mean = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	kcvsetting->cv_variance = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;

	kcvsetting->final_error = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	kcvsetting->final_mean = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	kcvsetting->final_variance = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;	
	kcvsetting->final_var_error = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	kcvsetting->final_var_mean = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	kcvsetting->final_var_variance = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;

	kcvsetting->cv_svs = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	kcvsetting->cv_lnC = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	kcvsetting->cv_lnK = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	kcvsetting->nodelist = (Data_Node **) calloc(defsetting->pairs.count, sizeof(Data_Node *)) ;
	kcvsetting->time = 0 ;
	kcvsetting->best_rate = 0 ;

	for (index = 0; index < kcvsetting->C_steps; index ++)
		kcvsetting->lnC[index] =  kcvsetting->lnC_start + index * kcvsetting->lnC_step ;
	for (index = 0; index < kcvsetting->K_steps; index ++)
		kcvsetting->lnK[index] =  kcvsetting->lnK_start + index * kcvsetting->lnK_step ;

	kcvsetting->pointernode = (Data_Node ***) malloc(defsetting->pairs.classes*sizeof(Data_Node **));
	kcvsetting->cvfold = (unsigned int **) malloc(defsetting->pairs.classes*sizeof(unsigned int *));
	
	labelnum = (unsigned int *) calloc(defsetting->pairs.classes, sizeof(unsigned int));
	
	for (index=0;index<defsetting->pairs.classes;index++)
	{
		kcvsetting->pointernode[index] = (Data_Node **) calloc(defsetting->pairs.labelnum[index], sizeof(Data_Node *)) ;
		kcvsetting->cvfold[index] = (unsigned int *) calloc(defsetting->pairs.labelnum[index], sizeof(unsigned int)) ;
	}
	kcvsetting->ranks = defsetting->pairs.classes ;
	for (index=0;index<kcvsetting->ranks;index++)
	{
		if (defsetting->pairs.labelnum[index]<defsetting->kfold)
			defsetting->kfold = defsetting->pairs.labelnum[index] ;
	}
	if (defsetting->kfold!=kcvsetting->kfold)
	{
		printf("\nThere is a rank having %d samples fewer than %d. So k-fold is reduced to %d-fold.\n", defsetting->kfold, kcvsetting->kfold, defsetting->kfold) ;
		kcvsetting->kfold = defsetting->kfold ;
		if (defsetting->kfold<=1)
		{
			printf("Exit due to 1-fold.\n") ;
			exit(1) ;
		}
	}

	node = defsetting->pairs.front ;
	index = 0 ;
	while ( NULL != node )
	{
		kcvsetting->nodelist[index] = node ;
		kcvsetting->pointernode[node->target-1][labelnum[node->target-1]] = node ;
		labelnum[node->target-1] += 1 ;
		node = node->next ;
		index ++ ;
	}
	
	if (defsetting->seeds>0)
		srand(defsetting->seeds) ;
	else
		srand((unsigned)time( NULL )) ;

	free(labelnum) ;
	return kcvsetting ;	
}
	
	
BOOL Rehearsal_Kcv ( kcv_Settings * kcvsetting, def_Settings * defsetting )
{
	unsigned int label, sz, index, rd ;
	unsigned int * kfold ;
	int size, remain ;

	for (label=0;label<kcvsetting->ranks;label++)
	{
		size = (int)floor((double)defsetting->pairs.labelnum[label]/(double)min(defsetting->kfold,defsetting->pairs.labelnum[label])) ;
		if (size<1)
			printf("Warning, empty folds.\n");
		remain = defsetting->pairs.labelnum[label] - size * defsetting->kfold ;
		kfold = (unsigned int*) malloc((unsigned int)min(defsetting->kfold,defsetting->pairs.labelnum[label])*sizeof(unsigned int)) ;
		for (index = 0 ; index < (unsigned int) min(defsetting->kfold,defsetting->pairs.labelnum[label]) ; index ++)
			kfold[index] = size ;	
		for (size = 0 ; size < remain ; size ++)
			kfold[size] += 1 ;

		for (sz=0;sz<defsetting->pairs.labelnum[label];sz++)
			kcvsetting->cvfold[label][sz] = 0 ;

		for (index = 1; index < (unsigned int)min(defsetting->kfold,defsetting->pairs.labelnum[label]); index ++)
		{
#ifdef _PROSTATE_VIVO
	                if (defsetting->seeds>0)
        	                rdseed = defsetting->seeds ;
                	else
                        	rdseed = (unsigned)time( NULL ) ;
                	srand(rdseed) ;
#endif
			sz=0 ;
			while (sz<kfold[index])
			{
				rd = (unsigned int) floor (rand()*(double)defsetting->pairs.labelnum[label]/RAND_MAX) ;
				if ( 0 == kcvsetting->cvfold[label][rd] )
				{
					kcvsetting->cvfold[label][rd] = index ;
					sz ++ ;
				}
			}
		}
		free(kfold) ;
	}
	printf("\n %d-fold CROSS VALIDATION --- %u.\n\n",defsetting->kfold,kcvsetting->index+1) ;
	if (defsetting->seeds>0)
		defsetting->seeds += 1 ; 
	return TRUE ;
}

BOOL Clear_Kcv ( kcv_Settings * settings)
{
	unsigned int index ;

	if ( NULL == settings )
		return FALSE ;

	if (NULL != settings->lnC)
		free(settings->lnC) ;
	if (NULL != settings->lnK)
		free(settings->lnK) ;
	if (NULL != settings->cv_lnC)
		free(settings->cv_lnC) ;
	if (NULL != settings->cv_lnK)
		free(settings->cv_lnK) ;
	if (NULL != settings->cv_error)
		free(settings->cv_error) ;
	if (NULL != settings->cv_mean)
		free(settings->cv_mean) ;
	if (NULL != settings->cv_variance)
		free(settings->cv_variance) ;
	if (NULL != settings->cv_svs)
		free(settings->cv_svs) ;
	if (NULL != settings->nodelist)
		free(settings->nodelist) ;

	for (index=0;index<settings->ranks;index++)
	{
		if (NULL != settings->pointernode[index])
			free(settings->pointernode[index]) ;
		if (NULL != settings->cvfold[index])
			free(settings->cvfold[index]) ;
	}
	free(settings->pointernode) ;
	free(settings->cvfold) ;

	if (NULL != settings->final_error)
		free(settings->final_error) ;
	if (NULL != settings->final_mean)
		free(settings->final_mean) ;
	if (NULL != settings->final_variance)
		free(settings->final_variance) ;
	if (NULL != settings->final_var_error)
		free(settings->final_var_error) ;
	if (NULL != settings->final_var_mean)
		free(settings->final_var_mean) ;
	if (NULL != settings->final_var_variance)
		free(settings->final_var_variance) ;

	free (settings) ;
	return TRUE ;
}

BOOL Init_Kcv ( kcv_Settings * kcvsetting, def_Settings * defsetting )
{
	smo_Settings * smosetting ;
	unsigned int index, ki, ci, rd, label ;
	int grid ;
	
	if ( NULL == kcvsetting || NULL == defsetting )
		return FALSE ;

	
	defsetting->validation.dimen = defsetting->pairs.dimen ;
	defsetting->training.dimen = defsetting->pairs.dimen ;
	if (NULL!=defsetting->validation.featuretype)
		free(defsetting->validation.featuretype) ;
	if (NULL!=defsetting->training.featuretype)
		free(defsetting->training.featuretype) ;
	defsetting->validation.featuretype = (int *) malloc(defsetting->validation.dimen*sizeof(int)) ;	
	defsetting->training.featuretype = (int *) malloc(defsetting->training.dimen*sizeof(int)) ;
	for (index=0;index<defsetting->pairs.dimen;index++)
	{
		defsetting->validation.featuretype[index] = defsetting->pairs.featuretype[index] ;
		defsetting->training.featuretype[index] = defsetting->pairs.featuretype[index] ;
	}
	
	if (NULL!=defsetting->training.labelnum) 
		free(defsetting->training.labelnum) ;
	if (NULL!=defsetting->validation.labelnum)
		free(defsetting->validation.labelnum) ;
	defsetting->validation.labelnum = (unsigned int *) calloc(defsetting->pairs.classes,sizeof(unsigned int)) ;	
	defsetting->training.labelnum = (unsigned int *) calloc(defsetting->pairs.classes,sizeof(unsigned int)) ;
	
	if (NULL!=defsetting->training.labels) 
		free(defsetting->training.labels) ;
	if (NULL!=defsetting->validation.labels)
		free(defsetting->validation.labels) ;
	defsetting->validation.labels = (unsigned int *) malloc(defsetting->pairs.classes*sizeof(unsigned int)) ;	
	defsetting->training.labels = (unsigned int *) malloc(defsetting->pairs.classes*sizeof(unsigned int)) ;
	for (index=0;index<defsetting->pairs.classes;index++)
	{
		defsetting->validation.labels[index] = defsetting->pairs.labels[index] ;
		defsetting->training.labels[index] = defsetting->pairs.labels[index] ;
	}

	if (NULL != kcvsetting->cv_error)
		free(kcvsetting->cv_error) ;
	kcvsetting->cv_error = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	if (NULL != kcvsetting->cv_mean)
		free(kcvsetting->cv_mean) ;
	kcvsetting->cv_mean = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;
	if (NULL != kcvsetting->cv_variance)
		free(kcvsetting->cv_variance) ;
	kcvsetting->cv_variance = (double *) calloc(kcvsetting->C_steps*kcvsetting->K_steps, sizeof(double)) ;

	for (defsetting->index = 0 ; defsetting->index < defsetting->kfold ; defsetting->index ++)
	{
		printf("Processing the %d-th fold ...\r\n",defsetting->index+1) ;

		defsetting->training.count = 0 ;	
		defsetting->validation.count = 0 ;		
		for (label = 0 ; label < kcvsetting->ranks; label ++ )
		{
			for (index = 0 ; index < (unsigned int)defsetting->pairs.labelnum[label]; index ++)
			{
				kcvsetting->pointernode[label][index]->next = NULL ;

				if ( fabs(kcvsetting->cvfold[label][index] - fmod((double)defsetting->index,(double)min(defsetting->kfold,defsetting->pairs.labelnum[label]))) < 0.001)				

				{
					Add_Data_List ( &(defsetting->validation), kcvsetting->pointernode[label][index] ) ;
					defsetting->validation.labelnum[label] += 1 ;
				}
				else
				{
					Add_Data_List ( &(defsetting->training), kcvsetting->pointernode[label][index] ) ;
					defsetting->training.labelnum[label] += 1 ;
				}
			}
		}
		
		defsetting->validation.datatype = defsetting->pairs.datatype ;
		defsetting->training.datatype = defsetting->pairs.datatype ;
		defsetting->validation.classes = defsetting->pairs.classes ;
		defsetting->training.classes = defsetting->pairs.classes ;
		grid = 0 ;
		for ( ki = 0 ; ki < kcvsetting->K_steps ; ki ++) 		
		{
			defsetting->kappa = pow(10.0, kcvsetting->lnK[ki]) ;
			defsetting->vc = pow(10.0, kcvsetting->lnC[0]) ;
			
			smosetting = Create_smo_Settings(defsetting) ;
			for ( ci = 0 ; ci < kcvsetting->C_steps ; ci ++)
			{									
				smosetting->vc = pow(10.0, kcvsetting->lnC[ci]) ;
		
				smo_routine (smosetting) ;
				 kcvsetting->time += smosetting->smo_timing ;
		
				svm_predict (&defsetting->validation, smosetting) ;

				kcvsetting->cv_lnC[grid] = kcvsetting->lnC[ci] ;
				kcvsetting->cv_lnK[grid] = kcvsetting->lnK[ki] ;
				kcvsetting->cv_error[grid] = (kcvsetting->cv_mean[grid] * (double)(defsetting->index) + smosetting->testrate)/((double)(defsetting->index)+1.0) ;
				kcvsetting->cv_variance[grid] += (smosetting->testrate-kcvsetting->cv_mean[grid])*(smosetting->testrate-kcvsetting->cv_mean[grid])*((double)(defsetting->index))/((double)(defsetting->index+1.0));
				kcvsetting->cv_mean[grid] = kcvsetting->cv_error[grid] ; 
				kcvsetting->cv_svs[grid] += smosetting->svs ;
	
				grid ++ ;
			}

			Clear_smo_Settings(smosetting) ; 
		}
		defsetting->validation.count = 0 ;
		defsetting->validation.front = NULL ;
		defsetting->validation.rear = NULL ;			
		defsetting->training.count = 0 ;
		defsetting->training.front = NULL ;
		defsetting->training.rear = NULL ;
	}


	grid = 0 ;
	for ( ki = 0 ; ki < kcvsetting->K_steps ; ki ++) 		
	{
		for ( ci = 0 ; ci < kcvsetting->C_steps ; ci ++)
		{
			kcvsetting->final_error[grid] = (kcvsetting->final_mean[grid] * (double)(kcvsetting->index) + kcvsetting->cv_mean[grid])/((double)(kcvsetting->index)+1.0) ;
			kcvsetting->final_variance[grid] += (kcvsetting->cv_mean[grid]-kcvsetting->final_mean[grid])*(kcvsetting->cv_mean[grid]-kcvsetting->final_mean[grid])*((double)(kcvsetting->index))/((double)(kcvsetting->index+1.0));
			kcvsetting->final_mean[grid] = kcvsetting->final_error[grid] ; 
			
			kcvsetting->final_var_error[grid] = (kcvsetting->final_var_mean[grid] * (double)(kcvsetting->index) + kcvsetting->cv_variance[grid])/((double)(kcvsetting->index)+1.0) ;
			kcvsetting->final_var_variance[grid] += (kcvsetting->cv_variance[grid]-kcvsetting->final_var_mean[grid])*(kcvsetting->cv_variance[grid]-kcvsetting->final_var_mean[grid])*((double)(kcvsetting->index))/((double)(kcvsetting->index+1.0));
			kcvsetting->final_var_mean[grid] = kcvsetting->final_var_error[grid] ; 

			grid ++ ;
		}
	}


	rd = 0 ;
	for (grid = kcvsetting->C_steps*kcvsetting->K_steps-1 ; grid > 0 ; grid --)
	{
		if (kcvsetting->final_error[grid] < kcvsetting->final_error[rd])
			rd = grid ;
		else if ( kcvsetting->final_error[grid] == kcvsetting->final_error[rd] )
		{
			if (kcvsetting->final_variance[grid] < kcvsetting->final_variance[rd])
				rd = grid ;
			else if (kcvsetting->final_variance[grid] == kcvsetting->final_variance[rd])
			{
				if (kcvsetting->final_var_error[grid] < kcvsetting->final_var_error[rd])
					rd = grid ;
				else if (kcvsetting->final_var_error[grid] == kcvsetting->final_var_error[rd])
				{
					if (kcvsetting->final_var_variance[grid] < kcvsetting->final_var_variance[rd])
						rd = grid ;
					else if (kcvsetting->final_var_variance[grid] == kcvsetting->final_var_variance[rd])
					{
						if (kcvsetting->cv_svs[grid] < kcvsetting->cv_svs[rd])
							rd = grid ;
						else if (kcvsetting->cv_svs[grid] == kcvsetting->cv_svs[rd])
						{
							printf ("Candidate: log(C) = %f, log(K) = %f, Error %f Variance %f and SVs %.0f.\r\n", kcvsetting->cv_lnC[grid],kcvsetting->cv_lnK[grid],kcvsetting->cv_error[grid],kcvsetting->cv_variance[grid],kcvsetting->cv_svs[grid]/(kcvsetting->index+1)/defsetting->kfold) ;					
							if (kcvsetting->cv_lnC[grid]<=kcvsetting->cv_lnC[rd])
								rd = grid ;
						}
					}
				}
			}
		}
	}

	kcvsetting->best_lnC = kcvsetting->cv_lnC[rd] ;
	kcvsetting->best_lnK = kcvsetting->cv_lnK[rd] ;
	kcvsetting->best_rate = kcvsetting->final_error[rd] ;
	printf("Best Settings at log(C)=%f log(Kappa)=%f \r\nwith validation error rate %f and %.0f SVs.\r\n", (kcvsetting->cv_lnC[rd]), (kcvsetting->cv_lnK[rd]), kcvsetting->final_error[rd], kcvsetting->cv_svs[rd]/(kcvsetting->index+1)/defsetting->kfold) ;


	rd = defsetting->pairs.count ;
	defsetting->pairs.count = 0 ;
	defsetting->pairs.front = NULL ;
	defsetting->pairs.rear = NULL ;
	for (index = 0 ; index < rd ; index ++)
	{
		kcvsetting->nodelist[index]->next = NULL ;
		Add_Data_List ( &(defsetting->pairs), kcvsetting->nodelist[index] ) ;
	}
	return TRUE ;
}

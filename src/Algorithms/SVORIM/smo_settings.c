/*******************************************************************************\

	smo_settings.c in Sequential Minimal Optimization ver2.0
	
	creates a smo_Settings from def_Settings.
			
	Chu Wei Copyright(C) National Univeristy of Singapore
	Create on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Update on Aug. 24 2001 

\*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#ifndef __MACH__
    #include <malloc.h>
#endif
#include <string.h>
#include <math.h>
#include <time.h>
#include <sys/types.h> 
#include <sys/timeb.h>
#include "smo.h"


/*******************************************************************************\

	smo_Settings * Create_smo_Settings ( def_Settings * setting ) 
	
	purpose: create and initialize the smo_Settings structure from def_Settings
			call standard SMO to initialize alphas.	
	input:  the pointer to the structure of def_Settings
	output: the pointer to the smo_Settings structure

\*******************************************************************************/

smo_Settings * Create_smo_Settings ( def_Settings * settings ) 
{
	smo_Settings * psetting = NULL ;
	long unsigned int dim = 0 ;
	long unsigned int i, sz ;
	double temp = 0 ;
	char buf[LENGTH] ;
	FILE * fid ;
	
	if (NULL == settings)
		return NULL ;

	if (NULL != (psetting = (smo_Settings *)(malloc(sizeof(smo_Settings))))) 	
	{
		dim = settings->pairs.dimen ;
		psetting->smo_working = FALSE ;
		psetting->smo_display = SMO_DISPLAY ;

		psetting->index = settings->index ;
				
		psetting->eps = EPS ;
		psetting->tol = TOL ;		
		psetting->p = P ;
		psetting->method = METHOD ;
		psetting->kernel = KERNEL ;
		psetting->testerror = 0 ;
		psetting->testrate = 0 ;
		
		if (settings->pairs.dimen>0)
		{
			psetting->ard = (double*) malloc(settings->pairs.dimen*sizeof(double)) ;
			sprintf(buf,"%s.ard",settings->inputfile) ;

			if (TRUE == settings->ardon)
				fid = fopen(buf,"r+t") ;
			else
				fid = NULL ;
			if (NULL != fid)
			{

					printf("Loading ARD weights from %s ...",buf) ;
				sz=0;
				while (!feof(fid) && NULL!=fgets(buf,LENGTH,fid) )
				{
					i=strlen(buf) ;
					if (i>1&&i<LENGTH-1)
					{
						if (sz>=dim)
						{
							printf("Warning : ARD weight file is too long.\n") ;
							sz = dim-1 ;
						}
						psetting->ard[sz] = atof(buf) ;
						sz += 1 ;
					}
					else
						printf("Warning : blank line in ARD weight file.\n") ;
				}
				fclose(fid) ;
				if (sz!=dim)
				{
					printf("Warning : reset ARD weights to 1.0.\n") ;
					for (i=0;i<dim;i++)
						psetting->ard[i]=1.0;					
					printf(" RESET as default.\n") ;
				}
				else
				{
					if (TRUE == SMO_DISPLAY)
						printf(" done.\n") ;
				}
				temp = 0;
				for (i=0;i<dim;i++)
					temp += psetting->ard[i] ;
				if (temp>0)
				{					
					for (i=0;i<dim;i++)
						psetting->ard[i]=psetting->ard[i]/temp ;
				}
				else
				{
					for (i=0;i<dim;i++)
						psetting->ard[i]=1.0/(double)dim;
				}
			}
			else
			{
				for (i=0;i<dim;i++)
					psetting->ard[i]=1.0/(double)dim;
			}
		}
		else
			psetting->ard = NULL ;

		psetting->ij_low = NULL ; 
		psetting->ij_up = NULL ;
		psetting->bj_low = NULL ;
		psetting->bj_up = NULL ;
		psetting->biasj = NULL ;

		if (ORDINAL == settings->pairs.datatype)
		{
			psetting->ij_low = (long unsigned int *) malloc((settings->pairs.classes-1)*sizeof(long unsigned int)) ;
			psetting->ij_up = (long unsigned int *) malloc((settings->pairs.classes-1)*sizeof(long unsigned int)) ;
			psetting->bj_low = (double *) malloc((settings->pairs.classes-1)*sizeof(double)) ;
			psetting->bj_up = (double *) malloc((settings->pairs.classes-1)*sizeof(double)) ;
			psetting->biasj = (double *) malloc((settings->pairs.classes-1)*sizeof(double)) ;
		}
			
		psetting->duration = 0 ;
		psetting->smo_timing = 0 ;
		psetting->abort = FALSE ;

		psetting->alpha = NULL ;
		psetting->inputfile = NULL ;

		Create_Cache_List( &(psetting->io_cache) ) ;
		psetting->pairs = &(settings->training) ;
		psetting->cache_size = psetting->pairs->count ;
		psetting->cacheall = FALSE ;		
		psetting->ardon = settings->ardon ;
		psetting->vc = VC ;
		psetting->smo_balance = settings->smo_balance ;

		psetting->kappa = KAPPA ;
		psetting->testerror = 0 ;
		psetting->testrate = 0 ;
		psetting->svs = 0 ;
		psetting->c1p = 0 ;
		psetting->c1n = 0 ;
		psetting->c2p = 0 ;
		psetting->c2n = 0 ;		

		if ( NULL == (psetting->inputfile = strdup( INPUTFILE )) )
		{
			Clear_smo_Settings( psetting ) ;
			return NULL ;
		}

		if ( NULL == (psetting->alpha = Create_Alphas(psetting) ) )
		{
			printf( "Alphas can not be created.\n" );
			Clear_smo_Settings( psetting ) ;
			return NULL ;
		}
		psetting->cacheall = TRUE ;
		if (TRUE == psetting->smo_display)
			printf("\r\nsmo_Settings is ready.\r\n") ;
	}
	return psetting ; 
}

/*******************************************************************************\

	void * Clear_Smo_Settings ( smo_Settings * psetting ) 
	
	Clear the smo_Settings structure, including its Alphas Structure & Io_CACHE
	input:  the pointer to the smo_Settings structure
	output: none 

\*******************************************************************************/

void Clear_smo_Settings( smo_Settings * settings )
{
	if ( NULL != settings )
	{
		if (NULL != settings->ard)
			free(settings->ard) ;
		if (ORDINAL == settings->pairs->datatype)
		{
			if (NULL != settings->ij_low)
				free(settings->ij_low) ;
			if (NULL != settings->ij_up)
				free(settings->ij_up) ;
			if (NULL != settings->bj_low)
				free(settings->bj_low) ;
			if (NULL != settings->bj_up)
				free(settings->bj_up) ;
			if (NULL != settings->biasj)
				free(settings->biasj) ;
		}
		Clear_Cache_List( &(Io_CACHE) ) ;
		Clear_Alphas( settings ) ;
		if ( NULL != INPUTFILE )
			free( INPUTFILE ) ;
		free ( settings ) ;
		settings = NULL ;
	}
} 


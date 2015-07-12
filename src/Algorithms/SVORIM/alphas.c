/*******************************************************************************\

	alphas.c in Sequential Minimal Optimization ver2.0
		
	implements initialization for alphas matrix.
		
	Chu Wei Copyright(C) University College London
	Create on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Update on May. 30 2004 

\*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <limits.h>
#include "smo.h"


/*******************************************************************************\

	Alphas * Create_Alphas ( smo_Settings * settings )
	
	create and initialize a structure matrix of Alphas from Data_List 
	input:  the pointer to smo_Settings
	output: the pointer to the head of the structure matrix for alphas

\*******************************************************************************/

Alphas * Create_Alphas ( smo_Settings * settings ) 
{
	Data_Node * pair = NULL ; 	
	Alphas * alpha = NULL ;
	Alphas * alphas = NULL ;
	Data_List * pairs = NULL ;
	unsigned int  i = 0, j ;
	
	if ( NULL == settings )
	{
		printf("\nFATAL ERROR : input is NULL in Create_Alphas.\n") ;
		return NULL ;
	}

	if ( NULL == (pairs = settings->pairs) )
	{
		printf("\nFATAL ERROR : data list is NULL in Create_Alphas.\n") ;
		return NULL ;
	}

	if ( TRUE == Is_Data_Empty( pairs ) || pairs->count < MINNUM )
	{ 
		printf( "\nFATAL ERROR : Data_List have not be initialized.\n") ;
		return  NULL ;
	}

	if ( NULL == (alphas = (Alphas *) malloc( pairs->count*sizeof(Alphas) )) )
	{
		printf( "\nFATAL ERROR : fail to malloc Alphas block.\n") ;
		exit(1) ;		
	}

	pair = pairs->front ;
	while ( pair != NULL )
	{		
		alpha = alphas + i ;
		i += 1 ;	
		alpha->f_cache = 0 ;
		alpha->pair = pair ;
		alpha->kernel = NULL ;
		alpha->kernel = (double *) malloc(i*sizeof(double)) ;
		if ( NULL == alpha->kernel )
		{
			printf("Fatal Error : fail to malloc kernel cache.\n") ;
			exit(1) ;
		}
		else
		{
			/* initial the kernel matrix cache*/
			for (j=0 ; j<i ; j++)
				alpha->kernel[j] = Calc_Kernel(alpha, alphas+j, settings) ;	
		}
		alpha->alpha = (double *) calloc(settings->pairs->classes-1,sizeof(double)) ;
		alpha->setname = (Set_Name * ) malloc((settings->pairs->classes-1)*sizeof(Set_Name)) ;	
		if (NULL == alpha->alpha || NULL == alpha->setname)
		{
			printf("\nFatal Error : fail to malloc alpha->setname.\n") ;
			exit(1) ;
		}
		for (j=0;j<settings->pairs->classes-1;j++)
			alpha->setname[j] = Get_Ordinal_Label (alpha, j+1, settings) ;
		alpha->cache = NULL ;
		pair = pair->next ;
	}
	return alphas ;
} /* end of Create_Alphas*/


/*******************************************************************************\

	BOOL Clear_Alphas ( smo_Settings * settings )
	
	clear the structure matrix of Alphas from smo_Settings
	input:  the pointer to smo_Settings
	output: TRUE or FALSE

\*******************************************************************************/

BOOL Clear_Alphas ( smo_Settings * settings )
{
	Alphas * alpha ;
	unsigned int  i = 0 ;
	Data_List * pairs = NULL ;	
	
	if ( NULL == settings )
	{
		printf("\nFATAL ERROR : input is NULL in Create_Alphas.\n") ;
		return FALSE ;
	}

	if ( NULL == (pairs = settings->pairs) )
	{
		printf("\nFATAL ERROR : input is NULL in Create_Alphas.\n") ;
		return FALSE ;
	}

	for (i=0;i<settings->pairs->count;i++)
	{
		alpha = ALPHA + i ;
		if (NULL != alpha->setname)
			free(alpha->setname) ;
		if (NULL != alpha->alpha)
			free(alpha->alpha) ;
		if (NULL != alpha->kernel)
			free(alpha->kernel) ;
	}
	free(ALPHA) ;
	return TRUE ;

} /* end of Clear_Alphas*/

/*******************************************************************************\

	BOOL Clean_Alphas ( Alphas *, smo_Settings * settings )
	
	set all the elements in the matrix to be the default values 
	input:  the pointer to the head of Alphas matrix and the pointer to smo_Settings 
	output: TRUE or FALSE

\*******************************************************************************/

BOOL Clean_Alphas ( Alphas * alphas, smo_Settings * settings )
{
	Alphas * alpha ;
	unsigned int  i = 0, j ;
	Data_Node * node = NULL ;
	Data_List * pairs = NULL ;	
	
	if ( NULL == alphas || NULL == settings )
	{
		printf("\nFATAL ERROR : input is NULL in Create_Alphas.\n") ;
		return FALSE ;
	}

	if ( NULL == (pairs = settings->pairs) )
	{
		printf("\nFATAL ERROR : input is NULL in Create_Alphas.\n") ;
		return FALSE ;
	}
	
	node = pairs->front ;
	while (NULL != node)
	{		
		alpha = alphas + i ;	
		i += 1 ;
		alpha->f_cache = 0 ;
		for (j=0;j<settings->pairs->classes-1;j++)
		{
			alpha->alpha[j] = 0 ;	
			alpha->setname[j] = Get_Ordinal_Label (alpha, j+1, settings) ;
		}
		alpha->cache = NULL ; 
		alpha->pair = node ;			
		node = node->next ;
	}
	return TRUE ;

} /* end of Clean_Alphas*/

/*******************************************************************************\

	BOOL Check_Alphas ( Alphas *, smo_Settings * settings )
	
	check the validation of the Alphas matrix and then itialize the bias terms 
	input:  the pointer to the head of Alphas matrix and the pointer to smo_Settings 
	output: TRUE or FALSE

\*******************************************************************************/

BOOL Check_Alphas ( Alphas * alphas, smo_Settings * settings )
{
	Alphas * alpha ;
	unsigned int loop = 0 ;
	Data_Node * node = NULL ;
	Data_List * pairs = NULL ;
	long int i = 0 ; 
	unsigned int j ;

	if ( NULL == alphas || NULL == settings )
	{
		printf("\nFATAL ERROR : input is NULL in Create_Alphas.\n") ;
		return FALSE ;
	}

	if ( NULL == (pairs = settings->pairs) )
	{
		printf("\nFATAL ERROR : input is NULL in Create_Alphas.\n") ;
		return FALSE ;
	}

	Clear_Cache_List( &(Io_CACHE) ) ;
		
	node = pairs->front ;
	while (NULL != node)
	{		
		alpha = alphas + i ;
		for (j=0;j<pairs->classes-1;j++)
		{			
			if (alpha->alpha[j] > VC)
				alpha->alpha[j] = VC ;
			else if (alpha->alpha[j] < 0)
				alpha->alpha[j] = 0 ;
			alpha->setname[j] = Get_Ordinal_Label (alpha, j+1, settings) ; 
		}
		alpha->f_cache = Calculate_Ordinal_Fi(i+1,settings) ;
		alpha->cache = NULL ; /* clear the reference to Io_Cache here */
		if (alpha->pair != node)
			printf("error in alpha or data list.\n") ;			
		node = node->next ;	
		i += 1 ;
	}
	
	/* initial b_up b_low*/		
	for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
	{
		settings->bj_up[loop-1] = (double)INT_MAX ;
		settings->bj_low[loop-1] = (double)INT_MIN ;
		settings->ij_up[loop-1] = 0 ;
		settings->ij_low[loop-1] = 0 ;
	}
	/* create Io_cache*/ 
	i = 0 ;
	node = pairs->front ;
	while (NULL != node)
	{
		alpha = alphas + i ;
		i += 1 ;
		if (TRUE == Is_Io(alpha,settings))
		{

			Add_Cache_Node(&settings->io_cache, alpha) ;			
		}
		for (loop = 0 ; loop < pairs->classes-1 ; loop ++)
		{
			if (alpha->pair->target > (loop+1.5) )
			{
				/*lower*/
				if (alpha->setname[loop]==Io_b || alpha->setname[loop]==I_One)
				{
					if (alpha->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha->f_cache-1 ;
						settings->ij_up[loop] = alpha - ALPHA + 1 ;
					}
				}
				if (alpha->setname[loop]==Io_b || alpha->setname[loop]==I_Fou)
				{
					if (alpha->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha->f_cache-1 ;
						settings->ij_low[loop] = alpha - ALPHA + 1 ;
					}
				}
			}
			else
			{

				if (alpha->setname[loop]==Io_a || alpha->setname[loop]==I_Thr)
				{
					if (alpha->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha->f_cache+1 ;
						settings->ij_up[loop] = alpha - ALPHA + 1 ;
					}
				}
				if (alpha->setname[loop]==Io_a || alpha->setname[loop]==I_Two)
				{
					if (alpha->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha->f_cache+1 ;
						settings->ij_low[loop] = alpha - ALPHA + 1 ;
					}
				}
			}
		}
		node = node->next ;	
	}
	return TRUE ;
} /* end of Check_Alphas */



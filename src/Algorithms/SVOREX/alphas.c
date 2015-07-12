/*******************************************************************************\

	alphas.c in Sequential Minimal Optimization ver2.0
		
	implements initialization for alphas matrix.
		
	Chu Wei Copyright(C) National Univeristy of Singapore
	Create on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Update on Aug. 23 2001 

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
	input:  the pointer to Data_List
	output: the pointer to the head of the structure matrix

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
		printf("\r\nFATAL ERROR : input is NULL in Create_Alphas.\r\n") ;
		return NULL ;
	}

	if ( NULL == (pairs = settings->pairs) )
	{
		printf("\r\nFATAL ERROR : data list is NULL in Create_Alphas.\r\n") ;
		return NULL ;
	}

	if ( TRUE == Is_Data_Empty( pairs ) || pairs->count < MINNUM )
	{ 
		printf( "\r\nFATAL ERROR : Data_List have not be initialized.\r\n") ;
		return  NULL ;
	}

	if ( NULL == (alphas = (Alphas *) malloc( pairs->count*sizeof(Alphas) )) )
	{
		printf( "\r\nFATAL ERROR : fail to malloc Alphas block.\r\n") ;
		return NULL ;		
	}

	pair = pairs->front ;
	while ( pair != NULL )
	{		
		alpha = alphas + i ;
		i++ ;	
		alpha->f_cache = 0 ;
		alpha->pair = pair ;
		alpha->kernel = NULL ;
		alpha->kernel = (double *) malloc(i*sizeof(double)) ;
		if ( NULL == alpha->kernel )
			printf("Fatal Error : fail to malloc memory.\r\n") ;
		else
		{
			/*/ initial the kernel matrix cache*/
			for (j=0 ; j<i ; j++)
				alpha->kernel[j] = Calc_Kernel(alpha, alphas+j, settings) ;	
		}	
		if (ORDINAL == pairs->datatype)
		{
			alpha->alpha = 0 ;	
			alpha->alpha_up = 0 ;
			alpha->alpha_dw = 0 ;
			/*/alpha->setname = I_o ;*/
			alpha->setname_up = Get_UP_Label (alpha, settings) ;
			alpha->setname_dw = Get_DW_Label (alpha, settings) ;
		}
		else
		{
			printf("Error datatype.\n") ;
			exit(1) ;
		}
		alpha->cache = NULL ;
		pair = pair->next ;
	}
	return alphas ;
} /*/ end of Create_Alphas*/


BOOL Clear_Alphas ( smo_Settings * settings )
{
	Alphas * alpha ;
	unsigned int  i = 0 ;
	Data_List * pairs = NULL ;	
	
	if ( NULL == settings )
	{
		printf("\r\nFATAL ERROR : input is NULL in Create_Alphas.\r\n") ;
		return FALSE ;
	}

	if ( NULL == (pairs = settings->pairs) )
	{
		printf("\r\nFATAL ERROR : input is NULL in Create_Alphas.\r\n") ;
		return FALSE ;
	}

	for (i=0;i<settings->pairs->count;i++)
	{
		alpha = ALPHA + i ;
		if (NULL != alpha->kernel)
			free(alpha->kernel) ;
	}
	free(ALPHA) ;
	return TRUE ;

} /*/ end of Clear_Alphas*/


/*******************************************************************************\

	BOOL Clean_Alphas ( Alphas *, smo_Settings * settings )
	
	set all the elements in the matrix to be the default values 
	input:  the pointer to the head of Alphas matrix and the pointer to Data_List 
	output: TRUE or FALSE

\*******************************************************************************/

BOOL Clean_Alphas ( Alphas * alphas, smo_Settings * settings )
{
	Alphas * alpha ;
	unsigned int  i = 0 ;
	Data_Node * node = NULL ;
	Data_List * pairs = NULL ;	
	
	if ( NULL == alphas || NULL == settings )
	{
		printf("\r\nFATAL ERROR : input is NULL in Create_Alphas.\r\n") ;
		return FALSE ;
	}

	if ( NULL == (pairs = settings->pairs) )
	{
		printf("\r\nFATAL ERROR : input is NULL in Create_Alphas.\r\n") ;
		return FALSE ;
	}

	for (i = 1 ; i < settings->pairs->classes ; i ++)
	{
		settings->mu[i-1] = 0 ;
	}

	i=0 ;
	node = pairs->front ;
	while (NULL != node)
	{		
		alpha = alphas + i ;	
		i++ ;
		alpha->alpha = 0 ;
		alpha->f_cache = 0 ;

		if ( ORDINAL == pairs->datatype )
		{
			/*/alpha->setname = I_o;*/
			alpha->alpha = 0 ;
			alpha->alpha_up = 0 ;
			alpha->alpha_dw = 0 ;
			alpha->setname_up = Get_UP_Label (alpha, settings) ;
			alpha->setname_dw = Get_DW_Label (alpha, settings) ;
		}
		else
		{
			printf("Error datatype.\n") ;
			exit(1) ;
		}
		alpha->cache = NULL ; /*/ clear the reference to Io_Cache here*/
		alpha->pair = node ;			
		node = node->next ;
	}
	return TRUE ;

} /*/ end of Clean_Alphas*/


BOOL Check_Alphas ( Alphas * alphas, smo_Settings * settings )
{
	Alphas * alpha ;
	unsigned int loop = 0 ;
	Data_Node * node = NULL ;
	Data_List * pairs = NULL ;
	long int i = 0 ; 

	if ( NULL == alphas || NULL == settings )
	{
		printf("\r\nFATAL ERROR : input is NULL in Create_Alphas.\r\n") ;
		return FALSE ;
	}

	if ( NULL == (pairs = settings->pairs) )
	{
		printf("\r\nFATAL ERROR : input is NULL in Create_Alphas.\r\n") ;
		return FALSE ;
	}

	Clear_Cache_List( &(Io_CACHE) ) ;
	
	node = pairs->front ;
	while (NULL != node)
	{		
		alpha = alphas + i ;
		if ( ORDINAL == pairs->datatype )
		{
			if (alpha->alpha_up > VC)
				alpha->alpha_up = VC ;
			if (alpha->alpha_dw > VC)
				alpha->alpha_dw = VC ;
			if (alpha->alpha_up < 0)
				alpha->alpha_up = 0 ;
			if (alpha->alpha_dw < 0)
				alpha->alpha_dw = 0 ;		
            alpha->alpha = - alpha->alpha_up + alpha->alpha_dw ;			
			alpha->setname_up = Get_UP_Label (alpha, settings) ;
			alpha->setname_dw = Get_DW_Label (alpha, settings) ;	
		}
		else
		{
			printf("Error datatype.\n") ;
			exit(1) ;
		}
		alpha->f_cache = Calculate_Ordinal_Fi(i+1, settings) ;
		alpha->cache = NULL ; /*/ clear the reference to Io_Cache here*/
		if (alpha->pair != node )
			printf("error in data list.\r\n") ;			
		node = node->next ;	
		i++ ;
	}
	/*/ create Io_cache */
	/*/ initial b_up b_low		*/
	for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
	{
		settings->bj_up[loop-1] = (double)INT_MAX ;
		settings->bj_low[loop-1] = (double)INT_MIN ;
		settings->ij_up[loop-1] = 0 ;
		settings->ij_low[loop-1] = 0 ;
	}
	/*/ create Io_cache*/ 
	i = 0 ;
	node = pairs->front ;
	while (NULL != node)
	{
		alpha = alphas + i ;
		i += 1 ;
		if ( alpha->setname_dw==Io_b || alpha->setname_up==Io_a )
		{

			Add_Cache_Node(&settings->io_cache, alpha) ;			
		}
			if (alpha->pair->target > 1 )
			{
				loop = alpha->pair->target - 2 ;
				/*/lower*/
				if (alpha->setname_dw==Io_b || alpha->setname_dw==I_One)
				{
					if (alpha->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha->f_cache-1 ;
						settings->ij_up[loop] = alpha - ALPHA + 1 ;
					}
				}
				if (alpha->setname_dw==Io_b || alpha->setname_dw==I_Fou)
				{
					if (alpha->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha->f_cache-1 ;
						settings->ij_low[loop] = alpha - ALPHA + 1 ;
					}
				}
			}
			if ( alpha->pair->target < pairs->classes )
			{
				loop = alpha->pair->target - 1 ;
				/*/upper*/
				if (alpha->setname_up==Io_a || alpha->setname_up==I_Thr)
				{
					if (alpha->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha->f_cache+1 ;
						settings->ij_up[loop] = alpha - ALPHA + 1 ;
					}
				}
				if (alpha->setname_up==Io_a || alpha->setname_up==I_Two)
				{
					if (alpha->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha->f_cache+1 ;
						settings->ij_low[loop] = alpha - ALPHA + 1 ;
					}
				}
			}
		node = node->next ;	
	}

#ifdef _ORDINAL_DEBUG
                for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
                {
                        if (0==settings->ij_up[loop-1]||0==settings->ij_low[loop-1])
                        {
								printf("FATAL ERROR>\n");
								for (loop=1;loop<settings->pairs->classes;loop++)
									printf("threshold %lu --- %u: up=%f(%lu), low=%f(%lu), mu=%f\n", loop,settings->pairs->labels[loop-1], settings->bj_up[loop-1],
									settings->ij_up[loop-1],settings->bj_low[loop-1],settings->ij_low[loop-1],settings->mu[loop-1]) ;
								printf("\n") ;
								for ( loop = 1; loop <= settings->pairs->count; loop ++ )
								{
									alpha = ALPHA + loop - 1 ;
									printf("%u-target %u---func %f: alpha = %f , alpha* = %f\n",loop, alpha->pair->target, alpha->f_cache, alpha->alpha_up, alpha->alpha_dw) ;
								}								
                                loop = settings->pairs->classes ;
                        }
                }
#endif
	/*/ check cross updating*/
	return TRUE ;
} /*/ end of Check_Alphas*/

/*/ the end of alphas.c*/

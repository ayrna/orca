#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <sys/types.h> 
#include <sys/timeb.h>
#include "smo.h"


unsigned int active_threshold (smo_Settings * settings) 
{
	unsigned int i, j = 0 ;
	double active = 0 ; 
	double temp = 0 ; 
	
	if (NULL == settings)
	{
		printf("error in the input pointer.\n") ;
		return j ;
	}
	for (i=1;i<settings->pairs->classes;i++)
	{
		temp = settings->bj_low[i-1]-settings->bj_up[i-1] ;
		if (temp>active && temp>TOL)
		{
			active = temp ;			
			j = i ; 
		}
	}
	return j ; 
}

BOOL ordinal_examine_example ( Alphas * alpha, smo_Settings * settings )
{
	double F2 = 0 ;
	unsigned int j = 0 ;
	unsigned int loop ;
	long unsigned int i1 = 0 ;
	long unsigned int i2 = 0 ;
	BOOL optimal = TRUE ; 

	if ( NULL == alpha || NULL == settings )
		return FALSE ;

	if (ORDINAL != settings->pairs->datatype)
		return FALSE ;

	i2 = alpha - ALPHA + 1 ;
#ifdef SMO_DEBUG
	if ( i2 > Pairs.count )
	{
		printf ( "Error input index %d in examineAll\n", i2 ) ;
		return FALSE ;
	}
#endif


	if ( FALSE == Is_Io(alpha,settings) )
	{
		alpha->f_cache = Calculate_Ordinal_Fi(i2, settings) ;

		for (loop = 0 ; loop < settings->pairs->classes-1 ; loop ++)
		{
			if (alpha->pair->target > (loop+1) )
			{

				if (alpha->setname[loop]==Io_b || alpha->setname[loop]==I_One)
				{
					if (alpha->f_cache-1<=settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha->f_cache-1 ;
						settings->ij_up[loop] = alpha - ALPHA + 1 ;
					}
				}
				if (alpha->setname[loop]==Io_b || alpha->setname[loop]==I_Fou)
				{
					if (alpha->f_cache-1>=settings->bj_low[loop])
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
					if (alpha->f_cache+1<=settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha->f_cache+1 ;
						settings->ij_up[loop] = alpha - ALPHA + 1 ;
					}
				}
				if (alpha->setname[loop]==Io_a || alpha->setname[loop]==I_Two)
				{
					if (alpha->f_cache+1>=settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha->f_cache+1 ;
						settings->ij_low[loop] = alpha - ALPHA + 1 ;
					}
				}
			}
		}
	}
	

	for (loop = 0 ; loop < settings->pairs->classes-1 ; loop ++)
	{
		if (alpha->pair->target > (loop+1) )
		{

			if (alpha->setname[loop]==Io_b || alpha->setname[loop]==I_One)
			{
				if ( settings->bj_low[loop] - (alpha->f_cache-1) > TOL )
				{
					optimal = FALSE ;
					if (settings->bj_low[loop]-(alpha->f_cache-1)>F2)
					{
						i1 = settings->ij_low[loop] ;
						F2 = settings->bj_low[loop]-(alpha->f_cache-1) ;
						j = loop+1 ;
					}
				}
			}
			if (alpha->setname[loop]==Io_b || alpha->setname[loop]==I_Fou)
			{
				if ( (alpha->f_cache-1) - settings->bj_up[loop] > TOL )
				{
					optimal = FALSE ;
					if ((alpha->f_cache-1) - settings->bj_up[loop]>F2)
					{
						i1 = settings->ij_up[loop] ;
						F2 = (alpha->f_cache-1) - settings->bj_up[loop] ;
						j = loop+1 ; 
					}
				}
			}
		}
		else
		{

			if (alpha->setname[loop]==Io_a || alpha->setname[loop]==I_Thr)
			{
				if (settings->bj_low[loop]-(alpha->f_cache+1)>TOL)
				{
					optimal = FALSE ;
					if (settings->bj_low[loop]-(alpha->f_cache+1)>F2)
					{
						i1 = settings->ij_low[loop] ;
						F2 = settings->bj_low[loop]-(alpha->f_cache+1) ;
						j = loop+1 ;
					}
				}
			}
			if (alpha->setname[loop]==Io_a || alpha->setname[loop]==I_Two)
			{
				if ((alpha->f_cache+1)-settings->bj_up[loop]>TOL)
				{
					optimal = FALSE ;
					if ((alpha->f_cache+1)-settings->bj_up[loop]>F2)
					{
						i1 = settings->ij_up[loop] ;
						F2 = (alpha->f_cache+1)-settings->bj_up[loop] ;
						j = loop+1 ;
					}
				}
			}
		}
	}

	if (optimal == FALSE)
	{		
		if (TRUE ==  ordinal_takestep( ALPHA + i1 - 1, ALPHA + i2 - 1, j , settings) )
			return TRUE ;
		else 
		{
			if ( TRUE == SMO_DISPLAY )
			{
				printf("%lu and %lu failed in takestep.\n",i1,i2) ;
			}
			return TRUE ;
		}
	}
	return FALSE ;
}

BOOL smo_ordinal (smo_Settings * settings)
{
	BOOL examineAll = TRUE ;
	long unsigned int numChanged = 0 ;
	Alphas * alpha = NULL ;   
	long unsigned int loop = 0 ;
	unsigned int j ;
	
	if (NULL == settings)
		return FALSE ;
	
	if ( VC <= EPS*EPS )
	{
		printf("\nWarning : C is too small.\n") ;
		return FALSE ;
	}
	SMO_WORKING = TRUE ;
	Clean_Alphas (ALPHA, settings) ;	
	Check_Alphas ( ALPHA, settings ) ;

	if ( TRUE == SMO_DISPLAY )
	{
		printf("SMO for Ordinal Expert %d ...  \r\n", INDEX) ;			
		printf("C=%f, Kappa=%f\n", VC, KAPPA) ;
		for (loop=1;loop<settings->pairs->classes;loop++)
			printf("threshold %lu --- %u: up=%f(%lu), low=%f(%lu)\n", loop,settings->pairs->labels[loop-1], settings->bj_up[loop-1], 
			settings->ij_up[loop-1],settings->bj_low[loop-1],settings->ij_low[loop-1]) ;
		printf("\n") ;
	}

	tstart() ; 


	while ( numChanged > 0 || examineAll )
	{
		if ( examineAll )
		{

			numChanged = 0 ;
			for ( loop = 1; loop <= settings->pairs->count; loop ++ )
			{
				numChanged += ordinal_examine_example( ALPHA + loop - 1, settings ) ; 
			}			
			if (TRUE == SMO_DISPLAY)
				for (loop=1;loop<settings->pairs->classes;loop++)
					printf("threshold %lu : up=%f(%lu), low=%f(%lu)\n", loop, settings->bj_up[loop-1], 
						settings->ij_up[loop-1], settings->bj_low[loop-1],settings->ij_low[loop-1]) ;
		}
		else
		{

			j = active_threshold (settings) ;
			while ( numChanged>0&&j>0 )
			{
				numChanged = ordinal_takestep (ALPHA + settings->ij_up[j-1] - 1, 
					ALPHA + settings->ij_low[j-1] - 1, j, settings) ;
				j = active_threshold (settings) ;
			}
			numChanged = 0 ;
			if ( TRUE == settings->abort )
			{
				SMO_WORKING = FALSE ;
				return FALSE ;
			}
		} 

		if ( TRUE == examineAll )
		{
			examineAll = FALSE ;
		}
		else if ( 0 == numChanged )
		{
			examineAll = TRUE ;
		}

	} 

	tend() ;
	settings->smo_timing = tval() ;
	DURATION += settings->smo_timing ;

	if (TRUE == SMO_DISPLAY)
	{
		for ( loop = 1; loop <= settings->pairs->count; loop ++ )
		{	
			alpha = ALPHA + loop - 1 ;
			printf("%lu-target %u---func %f: ",loop, alpha->pair->target, alpha->f_cache) ;
			for (j=0;j<settings->pairs->classes-1;j++)
				printf("a%d %.3f  ",j+1,alpha->alpha[j]) ;
			printf("\n") ;
			if ( fabs(alpha->f_cache - Calculate_Ordinal_Fi ( loop, settings )) > EPS )
				printf("\nindex %d, Fi is different from true value %.4f to %.4f.\r\n",(int)(alpha-ALPHA+1), alpha->f_cache, Calculate_Ordinal_Fi ( loop, settings ) ) ;

		}
	}
	for (loop=1;loop<settings->pairs->classes;loop++)
	{
		settings->biasj[loop-1] = (settings->bj_low[loop-1] + settings->bj_up[loop-1])/2.0 ;
		if (settings->bj_low[loop-1] - settings->bj_up[loop-1]>TOL)
			printf("Warning: KKT conditions are violated on bias--%lu!!! %f with C=%.4f K=%f\r\n", loop,
				settings->bj_low[loop-1] + settings->bj_up[loop-1], VC, KAPPA) ;

#ifdef _ORDINAL_DEBUG
		else
			printf("threshold %u = %f: up=%f(%u), low=%f(%u) \n", loop, settings->biasj[loop-1], settings->bj_up[loop-1], 
				settings->ij_up[loop-1], settings->bj_low[loop-1],settings->ij_low[loop-1]) ;
#endif
		if (loop > 1)
		{
			if (settings->biasj[loop-1]+TOL<settings->biasj[loop-2])
			{
				printf("Warning: thresholds %lu : %f < thresholds %lu : %f.\n",loop, settings->biasj[loop-1], loop-1, settings->biasj[loop-2]) ;
				exit(1) ;
			}
		}
	}
	SMO_WORKING = FALSE ;
	return TRUE ; 
}

BOOL smo_routine (smo_Settings * settings)
{
	if (NULL == settings)
		return FALSE ;

	if (ORDINAL == settings->pairs->datatype)
		return smo_ordinal (settings) ;
	else
	{
		printf("\nThe data type is not ORDINAL REGRESSION.\n") ;
		exit(1) ;
	}
}



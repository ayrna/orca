/*******************************************************************************\

	smo_kernel.c in Sequential Minimal Optimization ver2.0
		
	calculates the Kernel.

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
#include <math.h>
#include <time.h>
#include <sys/types.h> 
#include <sys/timeb.h>
#include "smo.h"


double Calculate_Kernel( double * pi, double * pj, smo_Settings * settings )
{
	long unsigned int dimen = 0 ;
	long unsigned int dimension = 0 ;
	double kernel = 0 ;	

	if ( NULL == pi || NULL == pj || NULL == settings )
		return kernel ;
	
	if (settings->pairs->dimen<1)
	{
		printf("Warning : dimension is less than 1.\n") ;
		return kernel ;
	}
	if (NULL == settings->ard)
	{
		printf("Warning : ard is NULL.\n") ;
		return kernel ;
	}

	dimension = settings->pairs->dimen ;
	if ( POLYNOMIAL == KERNEL )	
	{
		for ( dimen = 0; dimen < dimension; dimen ++ )
		{		
			if ( 0 == settings->pairs->featuretype[dimen] )
			{
				if ( pi[dimen]!=0 && pj[dimen]!=0 )
					kernel = kernel + settings->ard[dimen] * pi[dimen] * pj[dimen] ;
			}
			else
			{
				if ( pi[dimen]!=pj[dimen] )
					kernel = kernel - settings->ard[dimen] ;
				else
					kernel = kernel + settings->ard[dimen] ;
			}
		}
		if ((double) P > 1.0)
			kernel = pow( (kernel + 1.0), (double) P ) ;
	}
	else if ( GAUSSIAN == KERNEL )
	{
		for ( dimen = 0; dimen < dimension; dimen ++ )
		{
			if ( 0 == settings->pairs->featuretype[dimen] )
			{
				if ( pi[dimen]!=pj[dimen] )
					kernel = kernel + KAPPA * settings->ard[dimen] * ( pi[dimen] - pj[dimen] ) * ( pi[dimen] - pj[dimen] ) ;
			}
			else
			{
				if ( pi[dimen]!=pj[dimen] )
					kernel = kernel + KAPPA * settings->ard[dimen] ;
			}
				//printf("%f( %f - %f)^2\n", kernel, pi[dimen], pj[dimen]);
		}
		//printf("%f %d \n", kernel, dimension);
		//kernel = exp ( -  kernel / 2.0 * dimension ) ; 
		kernel = exp ( -  kernel * dimension ) ; 
	}
	else 
	{
		for ( dimen = 0; dimen < dimension; dimen ++ )
		{
			if ( 0 == settings->pairs->featuretype[dimen] )
			{
				if ( pi[dimen]!=0 && pj[dimen]!=0 )
					kernel = kernel + settings->ard[dimen] * pi[dimen] * pj[dimen] ;
			}
			else
			{
				if ( pi[dimen]!=pj[dimen] )
					kernel = kernel - settings->ard[dimen] ;
				else
					kernel = kernel + settings->ard[dimen] ;
			}
		}
	}       
	if (pi==pj){
	//printf("%f\n", kernel+ 0.001);
		return kernel + 0.001 ;
	}else{
	//printf("%f\n", kernel);
        return kernel ; 
	}
}

double Calc_Kernel( struct _Alphas * ai, struct _Alphas * aj, smo_Settings * settings )
{
	long unsigned int dimension = 0 ;
	double kernel = 0 ;
	double * pi ;
	double * pj ;
	int i, j ;

	if ( NULL == ai || NULL == aj || NULL == settings )
		return kernel ;

	if (settings->pairs->dimen<1)
	{
		printf("Warning : dimension is less than 1.\n") ;
		return kernel ;
	}
	if (NULL == settings->ard)
	{
		printf("Warning : ard is NULL.\n") ;
		return kernel ;
	}

	if (TRUE == settings->cacheall)
	{
		/* retrieve kernel values*/
		i = ai - ALPHA ;
		j = aj - ALPHA ;
		if (i >= j)
			return ai->kernel[j] ;
		else if ( i < j )
			return aj->kernel[i] ;
	}

	dimension = settings->pairs->dimen ;
	pi = ai->pair->point ;
	pj = aj->pair->point ;
	return Calculate_Kernel(pi, pj, settings) ;
}
/* the end of smo_kernel.c */

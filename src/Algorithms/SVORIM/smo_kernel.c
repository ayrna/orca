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
//#include "mex.h"


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
		}
		//kernel = exp ( -  kernel / 2.0 / dimension ) ; 
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
	/*for ( dimen = 0; dimen < dimension; dimen ++ )	
			mexPrintf("%f ", pi[dimen]);
	mexPrintf(" /// ");
	for ( dimen = 0; dimen < dimension; dimen ++ )	
			mexPrintf("%f ", pj[dimen]);
	for ( dimen = 0; dimen < dimension; dimen ++ )	
			mexPrintf("%f ",settings->ard[dimen]);
	mexPrintf(" --> %f\n", kernel);*/
	if (pi==pj)
		return kernel + 0.001 ;
	else
	return kernel ;	
}

double Calc_Kernel( struct _Alphas * ai, struct _Alphas * aj, smo_Settings * settings )
{
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

		i = ai - ALPHA ;
		j = aj - ALPHA ;
		if (i >= j)
			return ai->kernel[j] ;
		else if ( i < j )
			return aj->kernel[i] ;
	}

	pi = ai->pair->point ;
	pj = aj->pair->point ;

	return Calculate_Kernel(pi, pj, settings) ;
}


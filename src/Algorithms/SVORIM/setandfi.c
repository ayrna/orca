/*******************************************************************************\

	setandfi.c in Sequential Minimal Optimization ver2.0
		
	calculates Fi and assign Set Name according to alphas. 

	Chu Wei Copyright(C) National Univeristy of Singapore
	Create on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Update on Aug. 23 2001 

\*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#ifndef __MACH__
    #include <malloc.h>
#endif
#include <math.h>
#include "smo.h"


/*******************************************************************************\

	double Calculate_Ordinal_Fi ( long unsigned int i, smo_Settings * settings )
	
	calculate Fi for input index i, which is defined as Fi=f(x_i)
	input:  index i in Data_List Pairs, and the pointer to smo_Settings 
	output: the value of Fi

\*******************************************************************************/

double Calculate_Ordinal_Fi ( long unsigned int i, smo_Settings * settings )
{
	Alphas * ai ;
	Alphas * aj ;
	Data_Node * Pi ;
	Data_Node * Pj ;
	double alpha ;
    double Fi = 0 ;
	long unsigned int j = 0 ;
	long unsigned int k ;

	if ( NULL == settings || i <= 0 )
	{
		printf ("\nFATAL ERROR : input pointer is NULL in Calc_Fi.\n") ;	
		exit(1) ;
	}

	if ( i > settings->pairs->count )
	{
		printf ("\r\nFATAL ERROR : input index exceed the count of Pairs in Calc_Fi.\r\n") ;		
		exit(1) ;
	}

	ai = ALPHA + i - 1 ;
	Pi = ai->pair ;
	Pj = settings->pairs->front ;
	
	while ( Pj != NULL )
	{		
		aj = ALPHA + j ;
		alpha = 0 ;
		for (k=0;k<settings->pairs->classes-1;k++)
		{
			if (aj->pair->target<=k+1)
				alpha -= aj->alpha[k] ;
			else
				alpha += aj->alpha[k] ;
		}
		if ( alpha != 0 )
			Fi = Fi + alpha * Calc_Kernel( aj, ai, settings ) ;
		Pj = Pj->next ;
		j++ ;
	}

#ifdef _ORDINAL_DEBUG
	if ( j != settings->pairs->count ) 
	{
		printf ( "Error in Calculate Fi \n" ) ;
		exit(1) ;
	}
#endif
	return Fi ;

} 

/*******************************************************************************\

	Set_Name Get_Ordinal_Label ( Alphas * alpha, unsigned int j, smo_Settings * settings)
	
	assign a Set_Name associated with j-th threshold for the input alpha 
	input: the pointer to alpha structure, the threshold index and the pointer to smo_Settings 
	output: Set_Name is assigned

\*******************************************************************************/

Set_Name Get_Ordinal_Label ( Alphas * alpha, unsigned int j, smo_Settings * settings)
{
	FILE * fid ;
	if ( NULL == alpha || NULL == settings )
	{
		printf("\r\nFATAL ERROR: input is NULL in Get_Label.\r\n") ;
		exit(1) ;
	}
	if (j>=settings->pairs->classes||j<=0)
	{
		printf("\r\nFATAL ERROR: threshold index is out of region in Get_Label.\r\n") ;
		exit(1) ;
	}

	if (alpha->alpha[j-1]>settings->vc)
	{
		if (alpha->alpha[j-1]>settings->vc+EPS)
		{
		fid = fopen ("error_message.txt","a+t") ;
		if (NULL != fid)
		{
			fprintf(fid,"\nWarning : alpha %f is greater than C.\n", alpha->alpha[j-1]) ;
			fclose(fid) ;
		}
		printf("\nWarning : alpha %f is greater than C.\n", alpha->alpha[j-1]) ;
		}		
		alpha->alpha[j-1]=settings->vc ;
		exit(1) ;
	}
	else if (alpha->alpha[j-1]<0)
	{
		if (alpha->alpha[j-1]<-EPS)
		{
                fid = fopen ("error_message.txt","a+t") ;
                if (NULL != fid)
                {
                        fprintf(fid,"\nWarning : alpha %f is less than 0.\n", alpha->alpha[j-1]) ;
                        fclose(fid) ;
                }
		printf("\nWarning : alpha %f is less than 0.\n", alpha->alpha[j-1]) ;
		}
		alpha->alpha[j-1]=0 ;
		exit(1) ;
	}

	if ( alpha->pair->target > j )
	{

		if ( fabs(settings->vc - alpha->alpha[j-1])<EPS*EPS*EPS )	return I_Fou ;
		else if ( fabs(alpha->alpha[j-1])<EPS*EPS*EPS )				return I_One ;
		else return Io_b ;		
	}
	else
	{

		if ( fabs(settings->vc - alpha->alpha[j-1])<EPS*EPS*EPS )	return I_Thr ;
		else if ( fabs(alpha->alpha[j-1])<EPS*EPS*EPS )				return I_Two ;
		else return Io_a ;
	}
} 

BOOL Is_Io ( Alphas * alpha, smo_Settings * settings ) 
{
	unsigned int i ;
	if (NULL == alpha || NULL == settings)
	{
		printf("\nFATAL ERROR : input pointer is NULL.\n") ;
		exit(1) ;
	}
	for (i=0;i<settings->pairs->classes-1;i++)
	{
		if (Io_a == alpha->setname[i] || Io_b == alpha->setname[i])
			return TRUE ;
	}
	return FALSE ;
} 



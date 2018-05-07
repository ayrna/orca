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
#include <string.h>
#include <math.h>
#include <float.h>
#include <time.h>
#include <sys/types.h> 
#include <sys/timeb.h>
#include "smo.h"


#define PI				(3.141592654)

/*******************************************************************************\

	double Calculate_Fi ( long unsigned int i, smo_Settings * settings )
	
	calculate Fi for input index i, which is defined as Fi=yi-fi
	input:  index i in Data_List Pairs, and the pointer to smo_Settings 
	output: the value of Fi

\*******************************************************************************/

double Calculate_Fi ( long unsigned int i, smo_Settings * settings )/*/ i is index here*/
{
	Alphas * ai ;
	Alphas * aj ;
	Data_Node * Pi ;
	Data_Node * Pj ;
    double Fi = 0 ;
	long unsigned int j = 0 ;	

	
	if ( NULL == settings || i <= 0 )
	{
		printf ("\r\nFATAL ERROR : input pointer is NULL in Calc_Fi.\r\n") ;	
		return 0 ;
	}

	if ( i > settings->pairs->count )
	{
		printf ("\r\nFATAL ERROR : input index exceed the count of Pairs in Calc_Fi.\r\n") ;	
		return 0 ;
	}

	ai = ALPHA + i - 1 ;
	Pi = ai->pair ;
	Pj = settings->pairs->front ;
	
	while ( Pj != NULL )
	{		
		aj = ALPHA + j ;
		if ( aj->alpha != 0 )
			Fi = Fi + (aj->alpha) * Calc_Kernel( aj, ai, settings ) ;
		Pj = Pj->next ;
		j++ ;
	}

	/*/ai->pair->guess = Fi ;*/

#ifdef SMO_DEBUG
	if ( j != settings->pairs->count ) 
		printf ( "Error in Calculate Fi \n" ) ;
#endif

	Fi = Pi->target - Fi ;

	return Fi ;

} /*/ end of Caculate_Fi*/


double Calculate_Ordinal_Fi ( long unsigned int i, smo_Settings * settings )/*/ i is index here*/
{
	Alphas * ai ;
	Alphas * aj ;
	Data_Node * Pi ;
	Data_Node * Pj ;
    double Fi = 0 ;
	long unsigned int j = 0 ;	

	if ( NULL == settings || i <= 0 )
	{
		printf ("\r\nFATAL ERROR : input pointer is NULL in Calc_Fi.\r\n") ;	
		return 0 ;
	}

	if ( i > settings->pairs->count )
	{
		printf ("\r\nFATAL ERROR : input index exceed the count of Pairs in Calc_Fi.\r\n") ;	
		return 0 ;
	}

	ai = ALPHA + i - 1 ;
	Pi = ai->pair ;
	Pj = settings->pairs->front ;
	
	while ( Pj != NULL )
	{		
		aj = ALPHA + j ;
		if ( aj->alpha != 0 )
			Fi = Fi + (-aj->alpha_up+aj->alpha_dw) * Calc_Kernel( aj, ai, settings ) ;
		Pj = Pj->next ;
		j++ ;
	}

#ifdef _ORDINAL_DEBUG
	if ( j != settings->pairs->count ) 
		printf ( "Error in Calculate Fi \n" ) ;
#endif
	return Fi ;

} /*/ end of Caculate_Ordinal_Fi*/

/*******************************************************************************\

	Set_Name Get_Setname( double * a1, double * a1a , smo_Settings * settings)
	
	assign a Set_Name for input a1 and a1a
	input: alpha_up -- *a1, alpha_dw -- *ala, and the pointer to smo_Settings 
	output: Set_Name is assigned

\*******************************************************************************/

Set_Name Get_Setname( double * a1, double * a1a , smo_Settings * settings)
{

	double a , b ;

	a = * a1 ; b = * a1a ;

	if ( (a * b) != 0 )
	{
		printf ( "\r\nFatal Error: alpha or VC in takeStep %f %f \r\n", *a1, *a1a ) ;	   
		* a1 = 0 ; * a1a = 0 ;
	    return I_One ;
	}

	if ( a > VC ) 
	{
		printf ( "\r\nFatal Error: alpha or VC in takeStep %f %f \r\n", *a1, *a1a ) ;
		* a1 = VC ;
		a = VC ;			   
		return I_Thr ;
	}

	if ( b > VC )
	{
		printf ( "\r\nFatal Error: alpha or VC in takeStep %f %f \r\n", *a1, *a1a ) ;
		* a1a = VC ;
		b = VC ;			   
		return I_Two ;
	}

	/*
	if ( VC == a && 0 == b )				return I_Thr ;
	else if (  VC == b && 0 == a  )			return I_Two ;
	else if ( 0 == a && 0 == b )			return I_One ;	*/
	if ( fabs(VC - a)<EPS*EPS && 0 == b )				return I_Thr ;
	else if (  fabs(VC - b)<EPS*EPS && 0 == a  )			return I_Two ;
	else if ( a<EPS*EPS && b<EPS*EPS )	return I_One ;	
	else if ( a > 0 && a < VC  && 0 == b )	return Io_a ;
	else if ( b > 0 && b < VC  && 0 == a )	return Io_b ;
	else
	{
		printf ( "\r\nFATAL ERROR : wrong alpha or VC in GetName. %f %f \r\n", * a1, * a1a ) ;		
		* a1 = 0 ; * a1a = 0 ;
	    return I_One ;		
	}

} /*/ end of Get_Setname*/

/*******************************************************************************\

	Set_Name Get_Label ( Alphas * alpha, smo_Settings * settings)
	
	assign a Set_Name for input alpha and its class label yi
	input: alpha_up -- *a1, alpha_dw -- *ala, and the pointer to smo_Settings 
	output: Set_Name is assigned

\*******************************************************************************/

Set_Name Get_Label ( Alphas * alpha, smo_Settings * settings)
{

	double a ;
	double u ;
	double l ;

	if ( NULL == alpha || NULL == settings )
	{
		printf("\r\nFATAL ERROR: input is NULL in Get_Label.\r\n");
		return I_o ;
	}

	u = alpha->alpha_up ;
	l = alpha->alpha_dw ;


	if ( alpha->alpha > u ) 
	{		
		printf("\r\nWarning: alpha %f is greater than u=%f in Get_Label.\r\n", alpha->alpha,u);
		alpha->alpha = u ;
	}
	if ( alpha->alpha < l )
	{		
		printf("\r\nWarning: alpha %f is less than l=%f in Get_Label.\r\n", alpha->alpha,l);
		alpha->alpha = l ;
	}
	a = alpha->alpha ; 
	
	if ( fabs(a - u)<EPS*EPS )				return I_Two ;
	else if ( fabs(l - a)<EPS*EPS )		return I_Thr ;
	/*if ( u == a )				return I_Two ;
	else if ( l == a )		return I_Thr ;*/
	else if ( a > l && a < u )	return I_One ;
	else
	{
		printf ( "\r\nFATAL ERROR : wrong alpha in Get_Label. %d \r\n", (int)(alpha-ALPHA) ) ;		
	    return I_o ;		
	}

} /*/ end of Get_Setname*/

Set_Name Get_DW_Label ( Alphas * alpha, smo_Settings * settings)
{
	double a ;
	double u ;
	double l ;

	if ( NULL == alpha || NULL == settings )
	{
		printf("\r\nFATAL ERROR: input is NULL in Get_Label.\r\n");
		return I_o ;
	}

	u = alpha->alpha_up ;
	l = alpha->alpha_dw ;

	if ( alpha->alpha_dw > settings->vc ) 
	{		
		if (alpha->alpha_dw > settings->vc+EPS)
			printf("\r\nWarning: alpha %f is greater than u=%f in Get_DW_Label.\r\n", alpha->alpha_dw,settings->vc);
		alpha->alpha_dw = settings->vc ;
	}
	if ( alpha->alpha_dw < 0 )
	{
		if (alpha->alpha_dw < -EPS)		
			printf("\r\nWarning: alpha %f is less than l=%d in Get_DW_Label.\r\n", alpha->alpha_dw,0);
		alpha->alpha_dw = 0 ;
	}

/*       if ( l*u > 0 )
{
if (l<u)
if (u>l)
{alpha->alpha_up=u-l;
alpha->alpha_dw=0;}
else
{alpha->alpha_dw=l-u;
alpha->alpha_up=0;}

//              printf("Warning: alpha_up * alpha_dw  > 0 ---- %d.\n",alpha-ALPHA+1) ;^M
}*/

	a = alpha->alpha_dw ; 

	if (1 == alpha->pair->target)
		return I_One ;
	
	/*if ( fabs(a - u)<EPS*EPS )				return I_Two ;
	else if ( fabs(l - a)<EPS*EPS )		return I_Thr ;*/
	if ( fabs(settings->vc - a)<EPS*EPS )				return I_Fou ;
	else if ( fabs(a)<EPS*EPS )						return I_One ;
	else if ( a > 0 && a < settings->vc )	return Io_b ;
	else
	{
		printf ( "\r\nFATAL ERROR : wrong alpha in Get_Label. %d \r\n", (int)(alpha-ALPHA) ) ;		
	    return I_o ;		
	}

} /*/ end of Get_Setname */


Set_Name Get_UP_Label ( Alphas * alpha, smo_Settings * settings)
{
	double a ;
	double u ;
	double l ;

	if ( NULL == alpha || NULL == settings )
	{
		printf("\r\nFATAL ERROR: input is NULL in Get_Label.\r\n");
		return I_o ;
	}

	u = alpha->alpha_up ;
	l = alpha->alpha_dw ;

/*	if ( l*u > 0 )
{
if (u>l)
{alpha->alpha_up=u-l;
alpha->alpha_dw=0;}
else
{alpha->alpha_dw=l-u;
alpha->alpha_up=0;}

	printf("Warning: alpha_up * alpha_dw  > 0 ---- %d.\n",alpha-ALPHA+1) ;

}*/
	if ( alpha->alpha_up > settings->vc ) 
	{
		if (alpha->alpha_up > settings->vc+EPS)		
			printf("\r\nWarning: alpha %f is greater than u=%f in Get_UP_Label.\r\n", alpha->alpha_up,settings->vc);
		alpha->alpha_up = settings->vc ;
	}
	if ( alpha->alpha_up < 0 )
	{		
		if (alpha->alpha_up < -EPS)
			printf("\r\nWarning: alpha %f is less than l=%d in Get_UP_Label.\r\n", alpha->alpha_up,0);
		alpha->alpha_up = 0 ;
	}
	a = alpha->alpha_up ; 

	if (alpha->pair->target == (int)settings->pairs->classes)
		return I_Two ;	
	
	/*if ( fabs(a - u)<EPS*EPS )				return I_Two ;
	else if ( fabs(l - a)<EPS*EPS )		return I_Thr ;*/
	if ( fabs(settings->vc - a)<EPS*EPS )				return I_Thr ;
	else if ( fabs(a)<EPS*EPS )						return I_Two ;
	else if ( a > 0 && a < settings->vc )	return Io_a ;
	else
	{
		printf ( "\r\nFATAL ERROR : wrong alpha in Get_Label. %u \r\n", (int)(alpha-ALPHA) ) ;		
	    return I_o ;		
	}
} 
/* end of Get_Setname
 end of file setandfi.c */

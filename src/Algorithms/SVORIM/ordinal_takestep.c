/*******************************************************************************\

	smoc_takestep.c in Sequential Minimal Optimization ver2.0
	
	implements the takestep function of SMO for Classification.
			
	Chu Wei Copyright(C) National Univeristy of Singapore
	Create on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Update on Aug. 24 2001 	

\*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <limits.h>
#include "smo.h"


BOOL ordinal_takestep ( Alphas * alpha1, Alphas * alpha2, unsigned int threshold, smo_Settings * settings )
{
	double  n1 = 0, n2 = 0, a1 = 0, a2 = 0;	
	BOOL nset1, nset2, set1, set2 ; 
	double F1 = 0, F2 = 0 ;
	double s1 = 1, s2 = 1 ;
	double K11 = 0, K12 = 0, K22 = 0 ;
	double ueta = 0, gamma = 0, delphi = 0 ;
	double H = 0, L = 0 ;
	double ObjH = 0, ObjL = 0 ;
	Set_Name name1, name2 ;
	Alphas * alpha3 = NULL ;
	Cache_Node * cache = NULL ;
	int * index ; 
#ifdef _ORDINAL_DEBUG
	double temp = 0 ; 
	double temp1, temp2 ;
#endif 
	long unsigned int i1 = 0 ;
	long unsigned int i2 = 0 ; 
	unsigned int t1, t2 ;
	unsigned int loop ;

	if ( NULL == alpha1 || NULL == alpha2 || NULL == settings )
	{
		printf( " Alpha list error. \r\n" ) ;
		return FALSE ;
	}
	if (threshold<=0)
	{
		printf( " Active threshold %u is zero.\n", threshold) ;
		return FALSE ;
	}

	if (threshold >= settings->pairs->classes)
	{
		printf( " Active threshold %u is greater than %u.\n", threshold, settings->pairs->classes-1) ;
		return FALSE ;
	}
    
	i1 = alpha1-ALPHA+1 ;
	i2 = alpha2-ALPHA+1 ;

	if ( i1 == i2 ) 
		return FALSE ;

	t1 = alpha1->pair->target ;
	t2 = alpha2->pair->target ;

	name1 = alpha1->setname[threshold-1] ;
	name2 = alpha2->setname[threshold-1] ;

	set1 = Is_Io(alpha1,settings) ;
	set2 = Is_Io(alpha2,settings) ;

	a1 = n1 = alpha1->alpha[threshold-1] ;		
	a2 = n2 = alpha2->alpha[threshold-1];		
	
	if (t1<=(threshold)&&t2>=(threshold+1))
	{
		s1 = +1 ;
		s2 = -1 ;
	}
	else if (t1>=(threshold+1)&&t2<=(threshold))
	{
		s1 = -1 ;		
		s2 = +1 ;
	}
	else if (t1<=(threshold)&&t2<=(threshold))
	{
		s1 = +1 ;		
		s2 = +1 ;
	}
	else if (t1>=(threshold+1)&&t2>=(threshold+1))
	{
		s1 = -1 ;
		s2 = -1 ;
	}
	else
	{
		printf("\nWarning : fail to specify the case.\n") ;
		exit(1) ;
	}

	F1 = alpha1->f_cache ;	
	F2 = alpha2->f_cache ;		

	K11 = Calc_Kernel( alpha1, alpha1, settings ) ; 
	K12 = Calc_Kernel( alpha1, alpha2, settings ) ;
	K22 = Calc_Kernel( alpha2, alpha2, settings ) ; 

	ueta = K11 + K22 - K12 - K12 ;
	
	if ( 0 >= ueta )
	{ 

		printf("\n Warning: Negative Definite Matrix.\n") ;
		ObjH=0 ;
		ObjL=0 ;
		return FALSE ;
	}
	else 
	{
		
		if (s1*s2<0)
		{
			gamma = a1 - a2 ;
			if (gamma>=0&&gamma<=VC)
			{
				H = VC ;
				L = gamma ;
			}
			else if (gamma<0&&gamma>=-VC)
			{
				H = VC + gamma ;
				L = 0 ;
			}
			else
			{
				printf("beyond corner 1.\n");
				return FALSE ;
			}
		}
		else
		{
			gamma = a1 + a2 ;
			if (gamma>=0&&gamma<=VC)
			{
				H = gamma ;
				L = 0 ;
			}
			else if (gamma>VC&&gamma<=(VC+VC))
			{
				H = VC ;
				L = gamma-VC ;
			}
			else
			{
				printf("beyond corner 3.\n");
				return FALSE ;
			}
		}		
		delphi = - F1 + F2 - s1 + s2 ;		
		n1 = a1 - s1*delphi/ueta ;
		n2 = a2 + s2*delphi/ueta ;
		if (s1*s2<0)
		{
			if (n1>H)
			{
				n1 = H ;
				if (gamma>=0)
					n2 = VC - gamma ;
				else 
					n2 = VC ;
			}
			else if (n1<L)
			{
				n1 = L ;
				if (gamma>=0)
					n2 = 0 ;
				else 
					n2 = - gamma ;
			}
			if (n2<0)
			{
				n2 = 0 ;
				n1 = gamma ;
			}
			else if (n2>VC&&gamma<0)
			{
				n2 = VC ;
				n1 = gamma + VC ;
			}
		}
		else
		{
			if (n1>H)
			{
				n1 = H ;
				if (gamma<=VC)
					n2 = 0 ;
				else 
					n2 = gamma - VC ;
			}
			else if (n1<L)
			{
				n1 = L ;
				if (gamma<=VC)
					n2 = gamma ;
				else 
					n2 = VC ;
			}
			if (n2<0)
			{
				n2 = 0 ;
				n1 = gamma ;
			}
			else if (n2>VC&&gamma>VC)
			{
				n2 = VC ;
				n1 = gamma - VC ;
			}
		}
	}

	
	if ( fabs(n2 - a2) > 0 )
	{

		alpha1->alpha[threshold-1] = n1 ;
		alpha2->alpha[threshold-1] = n2 ;



		alpha1->setname[threshold-1] = Get_Ordinal_Label(alpha1,threshold,settings) ;
		alpha2->setname[threshold-1] = Get_Ordinal_Label(alpha2,threshold,settings) ;

		nset1 = Is_Io(alpha1,settings) ;
		nset2 = Is_Io(alpha2,settings) ;

		if ( nset1 != set1 )
		{			
			if ( TRUE == nset1 && FALSE == set1 )	
				Add_Cache_Node( &Io_CACHE, alpha1 ) ; 
			if ( FALSE == nset1 && TRUE == set1 )
				Del_Cache_Node( &Io_CACHE, alpha1 ) ;
		}		
		if ( nset2 != set2 )
		{						
			if ( TRUE == nset2 && FALSE == set2 )		
				Add_Cache_Node( &Io_CACHE, alpha2 ) ;  						
			if ( FALSE == nset2 && TRUE == set2 )
				Del_Cache_Node( &Io_CACHE, alpha2 ) ;
		}


		index = (int *)calloc(settings->pairs->count,sizeof(int)) ;
		if (NULL == index)
		{
			printf("\n FATAL ERROR : fail to malloc index.\n") ;
			exit(1) ;
		}

		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
			alpha3 = ALPHA + settings->ij_up[loop-1] - 1 ;
			if (alpha3!=alpha1&&alpha3!=alpha2&&FALSE==Is_Io(alpha3,settings)) 
			{
				settings->bj_up[loop-1] += 
					- s1*(n1 - a1)*Calc_Kernel( alpha1, alpha3, settings ) 
					- s2*(n2 - a2)*Calc_Kernel( alpha2, alpha3, settings ) ;
				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=  
						- s1*(n1 - a1)*Calc_Kernel( alpha1, alpha3, settings ) 
						- s2*(n2 - a2)*Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_up[loop-1] = INT_MAX ;
				settings->ij_up[loop-1] = 0 ;
			}
			alpha3 = ALPHA + settings->ij_low[loop-1] - 1 ;
			if (alpha3!=alpha1&&alpha2!=alpha3&&FALSE==Is_Io(alpha3,settings)) 
			{	
				settings->bj_low[loop-1] += 
					- s1*(n1 - a1)*Calc_Kernel( alpha1, alpha3, settings ) 
					- s2*(n2 - a2)*Calc_Kernel( alpha2, alpha3, settings ) ;
				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=  
						- s1*(n1 - a1)*Calc_Kernel( alpha1, alpha3, settings ) 
						- s2*(n2 - a2)*Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_low[loop-1] = INT_MIN ;
				settings->ij_low[loop-1] = 0 ;
			}
		}

		if ( FALSE==Is_Io(alpha1,settings) )
		{
			if (0==index[alpha1-ALPHA])
			{
				alpha1->f_cache = alpha1->f_cache 				
					- s1*(n1 - a1)*K11 - s2*(n2 - a2)*K12 ;
				index[alpha1-ALPHA] = 1 ;
			}
			alpha3 = alpha1 ;
			for (loop = 0 ; loop < settings->pairs->classes-1 ; loop ++)
			{
				if (alpha3->pair->target > (loop+1) )
				{

					if (alpha3->setname[loop]==Io_b || alpha3->setname[loop]==I_One)
					{
						if (alpha3->f_cache-1<settings->bj_up[loop])
						{
							settings->bj_up[loop] = alpha3->f_cache-1 ;
							settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
						}
					}
					if (alpha3->setname[loop]==Io_b || alpha3->setname[loop]==I_Fou)
					{
						if (alpha3->f_cache-1>settings->bj_low[loop])
						{
							settings->bj_low[loop] = alpha3->f_cache-1 ;
							settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
						}
					}
				}
				else
				{

					if (alpha3->setname[loop]==Io_a || alpha3->setname[loop]==I_Thr)
					{
						if (alpha3->f_cache+1<settings->bj_up[loop])
						{
							settings->bj_up[loop] = alpha3->f_cache+1 ;
							settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
						}
					}
					if (alpha3->setname[loop]==Io_a || alpha3->setname[loop]==I_Two)
					{
						if (alpha3->f_cache+1>settings->bj_low[loop])
						{
							settings->bj_low[loop] = alpha3->f_cache+1 ;
							settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
						}
					}
				}
			}		
		}
		if ( FALSE==Is_Io(alpha2,settings) )
		{
			if (0==index[alpha2-ALPHA])
			{
				alpha2->f_cache = alpha2->f_cache 			
					- s1*(n1 - a1)*K12 - s2*(n2 - a2)*K22 ;
				index[alpha2-ALPHA] = 1 ;
			}			
			alpha3 = alpha2 ;
			for (loop = 0 ; loop < settings->pairs->classes-1 ; loop ++)
			{
				if (alpha3->pair->target > (loop+1) )
				{

					if (alpha3->setname[loop]==Io_b || alpha3->setname[loop]==I_One)
					{
						if (alpha3->f_cache-1<settings->bj_up[loop])
						{
							settings->bj_up[loop] = alpha3->f_cache-1 ;
							settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
						}
					}
					if (alpha3->setname[loop]==Io_b || alpha3->setname[loop]==I_Fou)
					{
						if (alpha3->f_cache-1>settings->bj_low[loop])
						{
							settings->bj_low[loop] = alpha3->f_cache-1 ;
							settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
						}
					}
				}
				else
				{

					if (alpha3->setname[loop]==Io_a || alpha3->setname[loop]==I_Thr)
					{
						if (alpha3->f_cache+1<settings->bj_up[loop])
						{
							settings->bj_up[loop] = alpha3->f_cache+1 ;
							settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
						}
					}
					if (alpha3->setname[loop]==Io_a || alpha3->setname[loop]==I_Two)
					{
						if (alpha3->f_cache+1>settings->bj_low[loop])
						{
							settings->bj_low[loop] = alpha3->f_cache+1 ;
							settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
						}
					}
				}
			}		
		}

		cache = Io_CACHE.front ;
		while ( NULL != cache ) 
		{
			alpha3 = cache->alpha ;
			if (0==index[alpha3-ALPHA])
			{
				alpha3->f_cache = alpha3->f_cache 
					- s1*(n1 - a1)*Calc_Kernel( alpha1, alpha3, settings ) 
					- s2*(n2 - a2)*Calc_Kernel( alpha2, alpha3, settings ) ;
				index[alpha3-ALPHA] = 1 ;
			}


			for (loop = 0 ; loop < settings->pairs->classes-1 ; loop ++)
			{
				if (cache->alpha->pair->target > (loop+1) )
				{

					if (cache->alpha->setname[loop]==Io_b || cache->alpha->setname[loop]==I_One)
					{
						if (cache->alpha->f_cache-1<settings->bj_up[loop])
						{
							settings->bj_up[loop] = cache->alpha->f_cache-1 ;
							settings->ij_up[loop] = cache->alpha - ALPHA + 1 ;
						}
					}
					if (cache->alpha->setname[loop]==Io_b || cache->alpha->setname[loop]==I_Fou)
					{
						if (cache->alpha->f_cache-1>settings->bj_low[loop])
						{
							settings->bj_low[loop] = cache->alpha->f_cache-1 ;
							settings->ij_low[loop] = cache->alpha - ALPHA + 1 ;
						}
					}
				}
				else
				{

					if (cache->alpha->setname[loop]==Io_a || cache->alpha->setname[loop]==I_Thr)
					{
						if (cache->alpha->f_cache+1<settings->bj_up[loop])
						{
							settings->bj_up[loop] = cache->alpha->f_cache+1 ;
							settings->ij_up[loop] = cache->alpha - ALPHA + 1 ;
						}
					}
					if (cache->alpha->setname[loop]==Io_a || cache->alpha->setname[loop]==I_Two)
					{
						if (cache->alpha->f_cache+1>settings->bj_low[loop])
						{
							settings->bj_low[loop] = cache->alpha->f_cache+1 ;
							settings->ij_low[loop] = cache->alpha - ALPHA + 1 ;
						}
					}
				}
			}
			cache = cache->next ;
		}

		
		free(index) ;

#ifdef _ORDINAL_DEBUG
		if (TRUE == SMO_DISPLAY)
		{
			for (loop=1;loop<settings->pairs->classes;loop++)
				printf("threshold %u : up=%f(%u), low=%f(%u)\n", loop, settings->bj_up[loop-1], 
				settings->ij_up[loop-1], settings->bj_low[loop-1],settings->ij_low[loop-1]) ;
			for ( loop = 1; loop <= settings->pairs->count; loop ++ )
			{	
				alpha3 = ALPHA + loop - 1 ;
				printf("%u-target %u---func %f: ",loop, alpha3->pair->target, Calculate_Ordinal_Fi(alpha3-ALPHA+1,settings)) ;
				for (t1=0;t1<settings->pairs->classes-1;t1++)
					printf("a%d %.3f  ",t1+1,alpha3->alpha[t1]) ;
				printf("\n") ;
			}
		}
		temp = 0 ;
		for (t1=0;t1<settings->pairs->count;t1++)
		{
			alpha1 = ALPHA+t1 ;
			temp1 = 0 ;
			for (loop=0;loop<settings->pairs->classes-1;loop++)
			{
				if (alpha1->pair->target<=loop+1)
					temp1 -= alpha1->alpha[loop] ;
				else
					temp1 += alpha1->alpha[loop] ;
				temp -= alpha1->alpha[loop] ;
			}
			for (t2=0;t2<t1;t2++)
			{
				alpha2 = ALPHA+t2 ;				
				temp2 = 0 ;
				for (loop=0;loop<settings->pairs->classes-1;loop++)
				{
					if (alpha2->pair->target<=loop+1)
						temp2 -= alpha2->alpha[loop] ;
					else
						temp2 += alpha2->alpha[loop] ;
				}
				temp += temp1*temp2*Calc_Kernel( alpha1, alpha2, settings ) ;
			}
			temp += 0.5*temp1*temp1*Calc_Kernel( alpha1, alpha1, settings ) ;
		}
		printf("objective functional %f\n",temp) ;
#endif
		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
			if (0==settings->ij_up[loop-1]||0==settings->ij_low[loop-1])
				return Check_Alphas ( ALPHA, settings ) ;
		}
		
		return TRUE ;
	}
	else
	{
		return FALSE ;
	}
}



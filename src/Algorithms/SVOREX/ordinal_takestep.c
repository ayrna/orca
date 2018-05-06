/*******************************************************************************\

	smoc_takestep.c in Sequential Minimal Optimization ver2.0
	
	implements the takestep function of SMO for Classification.
			
	Chu Wei Copyright(C) National Univeristy of Singapore
	Create on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Update on Aug. 24 2001 	

\*******************************************************************************/

#include <stdio.h>
#include <stdlib.h> 
#ifndef __MACH__
    #include <malloc.h>
#endif
#include <math.h>
#include <limits.h>
#include "smo.h"


BOOL Decide_Boundary (double gamma, int s1, int s2, smo_Settings * settings, double * H, double * L)
{
	if (NULL == settings)	
	{
		printf("pointer is NULL.\n");
		return FALSE ;
	}
	
	if (s1*s2<0)
	{
		if (gamma>=0&&gamma<=VC)
		{
			*H = VC ;
			*L = gamma ;
		}
		else if (gamma<0&&gamma>=-VC)
		{
			*H = VC + gamma ;
			*L = 0 ;
		}
		else
		{
			printf("beyond corner 1.\n");
			return FALSE ;
		}
	}
	else
	{
		if (gamma>=0&&gamma<=VC)
		{
			*H = gamma ;
			*L = 0 ;
		}
		else if (gamma>VC&&gamma<=(VC+VC))
		{
			*H = VC ;
			*L = gamma-VC ;
		}
		else
		{
			printf("beyond corner 3.\n");
			return FALSE ;
		}
	}
	return TRUE ;
}

BOOL ordinal_cross_identical ( Alphas * alpha1, Alphas * alpha2, unsigned int threshold, smo_Settings * settings )
{
	double a1 = 0, a1a = 0, a2 = 0, a2a = 0 ;	/*/old alpha */
	double n1 = 0, n1a = 0, n2 = 0, n2a = 0 ;	/*/new alpha */
	double F1 = 0, F2 = 0 ;
	BOOL case4 = FALSE ;
	double K11 = 0, K12 = 0, K22 = 0 ;
	double ueta = 0, gamma = 0, delphi = 0 ;
	double H = 0, L = 0 ;
	Set_Name name1_up, name1_dw, name2_up, name2_dw ;
	Alphas * alpha3 = NULL ;
	Cache_Node * cache = NULL ;

	long unsigned int i1 = 0 ;
	long unsigned int i2 = 0 ; 
	unsigned int t1, t2;
	int * index ;
	unsigned int loop ;
	int s1=0, s2=0, mu, mu1=0, mu2=0 ;
	double deltamu = -1 ;

	if ( NULL == alpha1 || NULL == alpha2 || NULL == settings )
	{
		printf( " Alpha list error. \r\n" ) ;
		return FALSE ;
	}

	if (threshold > settings->pairs->classes-1 || threshold < 1)
	{
		printf( " Active threshold %u is greater than %u.\n", threshold, settings->pairs->classes-1) ;
		return FALSE ;
	}
   
	/*/printf("get in cross IDENTICAL update.\n") ; */

	i1 = alpha1-ALPHA+1 ;
	i2 = alpha2-ALPHA+1 ;

	t1 = alpha1->pair->target ;
	t2 = alpha2->pair->target ;

	if ( i1 != i2 )
	{
		printf("fail to update %lu and %lu.\n",i1,i2) ;
		return FALSE ;
	}


	if (!(t1<=threshold&&threshold<=t2))
	{
		threshold = t1 ;
	}

	if (threshold<=1||threshold>=settings->pairs->classes)
	{
		printf("fail to update %lu and %lu.\n",i1,i2) ;
		return FALSE ;
	}

	name1_up = alpha1->setname_up ;
	name1_dw = alpha1->setname_dw ;
	name2_up = alpha2->setname_up ;
	name2_dw = alpha2->setname_dw ;
	
	a1 = n1 = alpha1->alpha_up ;		
	a1a = n1a = alpha1->alpha_dw ;		
	a2 = n2 = alpha2->alpha_up ;
	a2a = n2a = alpha2->alpha_dw ;

	F1 = alpha1->f_cache ;	
	F2 = alpha2->f_cache ;		/*/ must update Io & I_LOW & I_UP every accepted step*/

	K11 = Calc_Kernel( alpha1, alpha1, settings ) ; 
	K12 = Calc_Kernel( alpha1, alpha2, settings ) ;
	K22 = Calc_Kernel( alpha2, alpha2, settings ) ; 

	ueta = K11 + K22 - K12 - K12 ;

	s1 = +1 ;
	mu1 = threshold ;
	s2 = -1 ;
	mu2 = threshold ;
	case4 = TRUE ;

	/*/ normal condition ueta==0 */
	if (TRUE==case4)
	{		
			/*/ a_{k-1}* - a_{k+1} = c. */			
			gamma = a1a + s1*s2*a2 ;

			Decide_Boundary (gamma, s1, s2, settings, &H, &L) ;
			delphi = s1*(H-a1a) ;
			for (mu=mu1;mu<=mu2;mu++)
			{
				if (settings->mu[mu-1]<delphi)
				{
					delphi = settings->mu[mu-1] ;
					deltamu = 0 ;
				}
			}
			n1a=a1a+s1*delphi ;
			n2=a2-s2*delphi ;
			if (n1a>H)
			{
				n1a = H ;
				if (gamma>=0)
					n2 = VC - gamma ;
				else 
					n2 = VC ;
				delphi = s1*(H-a1a) ;
				deltamu = delphi ;
			}
			else if (n1a<L)
			{
				n1a = L ;
				if (gamma>=0)
					n2 = 0 ;
				else 
					n2 = - gamma ;
				delphi = s1*(L-a1a) ;
				deltamu = delphi ;
			}
			n1=n2 ;
			n2a=n1a ;
	}
	else
	{
		printf(" Unknown case.\n") ;
	} /*/end of if ueta */

	/*/ update Alpha List if necessary, then update Io_Cache, and vote B_LOW & B_UP*/
	if ( fabs(delphi) > 0 )
	{
		/*/ store alphas in Alpha List*/
		a1 = alpha1->alpha_up ;	
		a1a = alpha1->alpha_dw ;
		a2 = alpha2->alpha_up ;
		a2a = alpha2->alpha_dw ;
		alpha1->alpha_up = n1 ;	
		alpha1->alpha_dw = n1a ;
		alpha2->alpha_up = n2 ;
		alpha2->alpha_dw = n2a ;
		alpha1->alpha = - alpha1->alpha_up + alpha1->alpha_dw ;		
		alpha2->alpha = - alpha2->alpha_up + alpha2->alpha_dw ;

		/*/ update mu*/
		for (mu=mu1;mu<=mu2;mu++)
			settings->mu[mu-1] -= delphi ;

		/*/ update Set & Cache_List  */
		if ( TRUE == case4 )
		{
			name1_up = Get_UP_Label(alpha1,settings) ;
			name1_dw = Get_DW_Label(alpha1,settings) ;
		}
		else
		{
			printf(" Unknown case.\n") ;
		}
		
		if ( alpha1->setname_up != name1_up || alpha1->setname_dw != name1_dw )
		{			
			if ( (Io_a == name1_up || Io_b == name1_dw) && (alpha1->setname_up != Io_a && alpha1->setname_dw != Io_b) )	
				Add_Cache_Node( &Io_CACHE, alpha1 ) ;  
			if ( (alpha1->setname_up == Io_a || alpha1->setname_dw == Io_b) && name1_up != Io_a && name1_dw != Io_b )
				Del_Cache_Node( &Io_CACHE, alpha1 ) ;
			alpha1->setname_up = name1_up ;
			alpha1->setname_dw = name1_dw ;
		}

		/*/ initialize b_up b_low*/
		index = (int *)calloc(settings->pairs->count,sizeof(int)) ;
		if (NULL == index)
		{
			printf("\n FATAL ERROR : fail to malloc index.\n") ;
			exit(1) ;
		}

		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
			if (settings->ij_up[loop-1]!=0)
			{
			alpha3 = ALPHA + settings->ij_up[loop-1] - 1 ;
			if (alpha3!=alpha1 && alpha3!=alpha2 && Io_a!=alpha3->setname_up && Io_b!=alpha3->setname_dw) 
			{
				settings->bj_up[loop-1] += 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
					* Calc_Kernel( alpha2, alpha3, settings ) ;
				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=
						- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
						* Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_up[loop-1] = INT_MAX ;
				settings->ij_up[loop-1] = 0 ;
			}
			}
			if (settings->ij_low[loop-1]!=0)
			{
			alpha3 = ALPHA + settings->ij_low[loop-1] - 1 ;
			if (alpha3!=alpha1 && alpha2!=alpha3 && Io_a!=alpha3->setname_up && Io_b!=alpha3->setname_dw) 
			{	
				settings->bj_low[loop-1] += 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
					* Calc_Kernel( alpha2, alpha3, settings ) ;
				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=  
						- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
						* Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_low[loop-1] = INT_MIN ;
				settings->ij_low[loop-1] = 0 ;
			}
			}
		}

		/*/ update f-cache of i1 & i2 if not in Io_Cache*/
		if (alpha1->setname_up != Io_a && alpha1->setname_dw != Io_b)
		{
			if (0==index[alpha1-ALPHA])
			{
				alpha1->f_cache = alpha1->f_cache /*/- ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) * K11 */
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) * K12 ;
				index[alpha1-ALPHA] = 1 ;
			}
			alpha3=alpha1 ;
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;
				/*/lower*/
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;
				/*upper*/
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
		}

		/*/ update Fi in Io_Cache and vote B_LOW & B_UP if possible*/
		cache = Io_CACHE.front ;
		while ( NULL != cache )
		{	
			alpha3 = cache->alpha ;	
			if ( 0==index[alpha3-ALPHA])
			{
				alpha3->f_cache = alpha3->f_cache 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
					* Calc_Kernel( alpha2, alpha3, settings ) ;
				index[alpha3-ALPHA] = 1 ;
			}
			
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;
				/*/lower*/
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;
				/*/upper*/
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			cache = cache->next ;				
		} /*/ end of while*/
		
		free(index) ;


		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
			if (0==settings->ij_up[loop-1]||0==settings->ij_low[loop-1])
			{ 
				Check_Alphas ( ALPHA, settings ) ;
				loop = settings->pairs->classes ;
			}
		}

#ifdef _ORDINAL_DEBUG
		for ( t1 = 1; t1 <= settings->pairs->count; t1 ++ )
		{	
			alpha3 = ALPHA + t1 - 1 ;
			printf("%u-target %u---func %f: alpha = %f , alpha* = %f\n",t1, alpha3->pair->target, alpha3->f_cache, alpha3->alpha_up, alpha3->alpha_dw) ;
		}
		for (t1=1;t1<settings->pairs->classes;t1++)
			printf("threshold %u : upper=%f(%u), lower=%f(%u), mu=%f\n", t1, settings->bj_up[t1-1],
				settings->ij_up[t1-1], settings->bj_low[t1-1], settings->ij_low[t1-1], settings->mu[t1-1]) ;
		deltamu = 0 ;
		for (t1=0;t1<settings->pairs->count;t1++)
		{
			alpha1 = ALPHA+t1 ;
			for (t2=0;t2<t1;t2++)
			{
				alpha2 = ALPHA+t2 ;
				deltamu += (-alpha1->alpha_up+alpha1->alpha_dw)
					*(-alpha2->alpha_up+alpha2->alpha_dw)*Calc_Kernel( alpha1, alpha2, settings ) ;
			}
			deltamu += 0.5*(-alpha1->alpha_up+alpha1->alpha_dw)
					*(-alpha1->alpha_up+alpha1->alpha_dw)*Calc_Kernel( alpha1, alpha1, settings ) ;
			deltamu -= (alpha1->alpha_up+alpha1->alpha_dw) ;
		}
		printf("objective functional %f\n",deltamu) ;
#endif

	for (loop = 1; loop < settings->pairs->classes; loop ++)
	{
		settings->bmu_low[loop-1]=settings->bj_low[loop-1] ;
		settings->imu_low[loop-1]=loop ;
		if (loop>1)
		{	

			if (settings->bmu_low[loop-2]>settings->bmu_low[loop-1])
			{
				settings->bmu_low[loop-1]=settings->bmu_low[loop-2] ;
				settings->imu_low[loop-1]=settings->imu_low[loop-2] ;
			}
		}
	}
	for (loop = settings->pairs->classes-1; loop > 0; loop --)
	{
		settings->bmu_up[loop-1]=settings->bj_up[loop-1] ;
		settings->imu_up[loop-1]=loop ;
		if (loop<settings->pairs->classes-1)
		{

			if (settings->bmu_up[loop-1]>settings->bmu_up[loop])
			{
				settings->bmu_up[loop-1]=settings->bmu_up[loop] ;
				settings->imu_up[loop-1]=settings->imu_up[loop] ;
			}			
		}
	}
	for (loop = 2; loop < settings->pairs->classes; loop ++)
	{
		if (settings->mu[loop-1]>EPS*EPS) 
		{
			if (settings->bmu_up[loop-1]>settings->bmu_up[loop-2])
			{
				settings->bmu_up[loop-1]=settings->bmu_up[loop-2] ;
				settings->imu_up[loop-1]=settings->imu_up[loop-2] ;
			}
			if (settings->bmu_low[loop-2]<settings->bmu_low[loop-1])
			{
				settings->bmu_low[loop-2]=settings->bmu_low[loop-1] ;
				settings->imu_low[loop-2]=settings->imu_low[loop-1] ;
			}
		}
	}
#ifdef _ORDINAL_DEBUG
		for (t1=1;t1<settings->pairs->classes;t1++)
			printf("threshold %u : mu_up=%f(%u), mu_low=%f(%u), mu=%f\n", t1, settings->bmu_up[t1-1],
				settings->imu_up[t1-1], settings->bmu_low[t1-1], settings->imu_low[t1-1], settings->mu[t1-1]) ;
#endif
		return TRUE ;
	} /*/ end of update */
	else
	{
		printf("fail to cross identical update pairs %lu and %lu, %f--%f\n",i1,i2,a1,a1a) ;		
		/*/exit(1); */
		return FALSE ;
	}
}

/*
BOOL ordinal_cross_takestep ( Alphas * alpha4, Alphas * alpha5, unsigned int threshold, smo_Settings * settings )
{
	double a1 = 0, a1a = 0, a2 = 0, a2a = 0 ;	//old alpha
	double n1 = 0, n1a = 0, n2 = 0, n2a = 0 ;	//new alpha
	double F1 = 0, F2 = 0 ;
	BOOL case1 = FALSE, case2 = FALSE, case3 = FALSE, 
		case4 = FALSE, case5 = FALSE , fcase1 = FALSE, fcase2 = FALSE, fcase3 = FALSE, 
		fcase4 = FALSE ;
	double K11 = 0, K12 = 0, K22 = 0 ;
	double ueta = 0, gamma = 0, delphi = 0 ;
	double H = 0, L = 0 ;
	double ObjH = 0, ObjL = 0 ;
	Set_Name name1_up, name1_dw, name2_up, name2_dw ;
	Alphas * alpha1 = NULL ;
	Alphas * alpha2 = NULL ;
	Alphas * alpha3 = NULL ;
	Cache_Node * cache = NULL ;

	long unsigned int i1 = 0 ;
	long unsigned int i2 = 0 ; 
	unsigned int t1, t2;
	int * index ;
	unsigned int loop ;
	int s1=0, s2=0, mu, mu1=0, mu2=0 ;
	double deltamu = -1 ;
	int flag = 0 ;


	if ( NULL == alpha4 || NULL == alpha5 || NULL == settings )
	{
		printf( " Alpha list error. \r\n" ) ;
		return FALSE ;
	}

	if (threshold > settings->pairs->classes-1 || threshold < 1)
	{
		printf( " Active threshold %u is greater than %u.\n", threshold, settings->pairs->classes-1) ;
		return FALSE ;
	}
   
	//printf("get in cross update.\n") ;

	// decide case

	i1 = alpha4-ALPHA+1 ;
	i2 = alpha5-ALPHA+1 ;

	t1 = alpha4->pair->target ;
	t2 = alpha5->pair->target ;

	if (t2<t1)
	{
		alpha1 = alpha5 ;
		alpha2 = alpha4 ;
	}
	else
	{
		alpha1 = alpha4 ;
		alpha2 = alpha5 ;
	}
	if (t2==t1)
	{
		if (((double)rand()/(double)RAND_MAX)>0.5)
	{
			alpha1 = alpha5 ;
			alpha2 = alpha4 ;
		}
	}

	i1 = alpha1-ALPHA+1 ;
	i2 = alpha2-ALPHA+1 ;

	t1 = alpha1->pair->target ;
	t2 = alpha2->pair->target ;

    
	if ( i1 == i2 )
	{
		return ordinal_cross_identical (alpha4, alpha5, threshold, settings) ;
	}

	name1_up = alpha1->setname_up ;
	name1_dw = alpha1->setname_dw ;
	name2_up = alpha2->setname_up ;
	name2_dw = alpha2->setname_dw ;
	
	a1 = n1 = alpha1->alpha_up ;		//a
	a1a = n1a = alpha1->alpha_dw ;		//a*
	a2 = n2 = alpha2->alpha_up ;
	a2a = n2a = alpha2->alpha_dw ;

	F1 = alpha1->f_cache ;	
	F2 = alpha2->f_cache ;		// must update Io & I_LOW & I_UP every accepted step

	K11 = Calc_Kernel( alpha1, alpha1, settings ) ; 
	K12 = Calc_Kernel( alpha1, alpha2, settings ) ;
	K22 = Calc_Kernel( alpha2, alpha2, settings ) ; 

	ueta = K11 + K22 - K12 - K12 ;

	if (t2==settings->pairs->classes)
	{
		fcase2=TRUE;
		fcase4=TRUE;
	}
	if (t1==1)
	{
		fcase3=TRUE;
		fcase4=TRUE;
	}
	if (t1+1>t2-1)
		fcase1=TRUE;
	if (t1==t2)
	{
		fcase2=TRUE;
		fcase3=TRUE;
	}

	if ( 0 >= ueta )
	{
		printf(" Negative Definite Matrix cross.\n") ;
		// calculate objective function at H or L, choose the smaller one
		ObjH=0 ;
		ObjL=0 ;
		return FALSE ;
	}
	else // normal condition
	{
		do
		{// check four cases

		if (FALSE==fcase1)
		{	
			fcase1 = TRUE ;		
			s1 = -1 ;
			mu1 = t1 + 1 ;
			s2 = +1 ;
			mu2 = t2 - 1 ;

			// - a_{k} + a_{k+2}* = c.		
			gamma = a1 + s1*s2*a2a ;
			Decide_Boundary (gamma, s1, s2, settings, &H, &L) ;
			if (ueta>0)
				delphi = (- F1 + F2 + s1 - s2)/ueta ;// n1=a1+s1*adlphi ;
			else
				delphi = (- F1 + F2 + s1 - s2) ;
			for (mu=mu1;mu<=mu2;mu++)
			{
				if (settings->mu[mu-1]<delphi)
				{
					delphi = settings->mu[mu-1] ;
					deltamu = 0 ;
				}
			}
			n1=a1+s1*delphi ;				
			n2a=a2a-s2*delphi ;
			if (n1>H)
			{
				n1 = H ;
				if (gamma>=0)
					n2a = VC - gamma ;
				else 
					n2a = VC ;
				delphi = s1*(H-a1) ;
				deltamu = delphi ;
			}
			else if (n1<L)
			{
				n1 = L ;
				if (gamma>=0)
					n2a = 0 ;
				else 
					n2a = - gamma ;
				delphi = s1*(L-a1) ;
				deltamu = delphi ;
			}
			if (fabs(delphi)>EPS)
			{
				case1 = TRUE ;
				case5 = TRUE ;
			}
			else
			{
				a1 = n1 = alpha1->alpha_up ;		//a
				a1a = n1a = alpha1->alpha_dw ;		//a*
				a2 = n2 = alpha2->alpha_up ;
				a2a = n2a = alpha2->alpha_dw ;
			}
		}
		else if (FALSE==fcase2)
		{	
			fcase2 = TRUE ;
			s1 = -1 ;
			mu1 = t1 + 1 ;
			s2 = -1 ;
			mu2 = t2 ;

			// - a_{k-1} - a_{k} = c.		
			gamma = a1 + s1*s2*a2 ;
			Decide_Boundary (gamma, s1, s2, settings, &H, &L) ;
			if (ueta>0)
				delphi = (- F1 + F2 + s1 - s2)/ueta ;// n1=a1+s1*adlphi ;
			else
				delphi = (- F1 + F2 + s1 - s2) ;
			for (mu=mu1;mu<=mu2;mu++)
			{
				if (settings->mu[mu-1]<delphi)
				{
					delphi = settings->mu[mu-1] ;
					deltamu = 0 ;
				}
			}
			n1=a1+s1*delphi ;				
			n2=a2-s2*delphi ;
			if (n1>H)
			{
				n1 = H ;
				if (gamma>0&&gamma<VC)
					n2 = 0 ;
				else 
					n2 = gamma - VC ;
				delphi = s1*(H-a1) ;
				deltamu = delphi ;
			}
			else if (n1<L)
			{
				n1 = L ;
				if (gamma>0&&gamma<VC)
					n2 = gamma ;
				else 
					n2 = VC ;
				delphi = s1*(L-a1) ;
				deltamu = delphi ;
			}
			if (fabs(delphi)>EPS)
			{
				case5 = TRUE ;
				case2 = TRUE ;
			}
			else
			{
				a1 = n1 = alpha1->alpha_up ;		//a
				a1a = n1a = alpha1->alpha_dw ;		//a*
				a2 = n2 = alpha2->alpha_up ;
				a2a = n2a = alpha2->alpha_dw ;
			}
		}
		else if (FALSE==fcase3)
		{
			fcase3 = TRUE ;		
			s1 = +1 ;
			mu1 = t1 ;
			s2 = +1 ;
			mu2 = t2 - 1 ;

			// a_{k+1}* + a_{k+2}* = c.		
			gamma = a1a + s1*s2*a2a ;
			Decide_Boundary (gamma, s1, s2, settings, &H, &L) ;
			if (ueta>0)
				delphi = (- F1 + F2 + s1 - s2)/ueta ;// n1=a1+s1*adlphi ;
			else
				delphi = (- F1 + F2 + s1 - s2) ;
			for (mu=mu1;mu<=mu2;mu++)
			{
				if (settings->mu[mu-1]<delphi)
				{
					delphi = settings->mu[mu-1] ;
					deltamu = 0 ;
				}
			}
			n1a=a1a+s1*delphi ;				
			n2a=a2a-s2*delphi ;
			if (n1a>H)
			{
				n1a = H ;
				if (gamma>0&&gamma<VC)
					n2a = 0 ;
				else 
					n2a = gamma - VC ;
				delphi = s1*(H-a1a) ;
				deltamu = delphi ;
			}
			else if (n1a<L)
			{
				n1a = L ;
				if (gamma>0&&gamma<VC)
					n2a = gamma ;
				else 
					n2a = VC ;
				delphi = s1*(L-a1a) ;
				deltamu = delphi ;
			}
			if (fabs(delphi)>EPS)
			{
				case5 = TRUE ;
				case3 = TRUE ;
			}
			else
			{
				a1 = n1 = alpha1->alpha_up ;		//a
				a1a = n1a = alpha1->alpha_dw ;		//a*
				a2 = n2 = alpha2->alpha_up ;
				a2a = n2a = alpha2->alpha_dw ;
			}
		}
		else if (FALSE==fcase4)
		{
			fcase4 = TRUE ;
			s1 = +1 ;
			mu1 = t1 ;
			s2 = -1 ;
			mu2 = t2 ;
			// a_{k-1}* - a_{k+1} = c.			
			gamma = a1a + s1*s2*a2 ;
			Decide_Boundary (gamma, s1, s2, settings, &H, &L) ;
			if (ueta>0)
				delphi = (- F1 + F2 + s1 - s2)/ueta ;// n1=a1+s1*adlphi ;
			else
				delphi = (- F1 + F2 + s1 - s2) ;
			for (mu=mu1;mu<=mu2;mu++)
			{
				if (settings->mu[mu-1]<delphi)
				{
					delphi = settings->mu[mu-1] ;
					deltamu = 0 ;
				}
			}
			n1a=a1a+s1*delphi ;
			n2=a2-s2*delphi ;
			if (n1a>H)
			{
				n1a = H ;
				if (gamma>=0)
					n2 = VC - gamma ;
				else 
					n2 = VC ;
				delphi = s1*(H-a1a) ;
				deltamu = delphi ;
			}
			else if (n1a<L)
			{
				n1a = L ;
				if (gamma>=0)
					n2 = 0 ;
				else 
					n2 = - gamma ;
				delphi = s1*(L-a1a) ;
				deltamu = delphi ;
			}
			if (fabs(delphi)>EPS)
			{
				case5 = TRUE ;
				case4 = TRUE ;
			}
			else
			{
				a1 = n1 = alpha1->alpha_up ;		//a
				a1a = n1a = alpha1->alpha_dw ;		//a*
				a2 = n2 = alpha2->alpha_up ;
				a2a = n2a = alpha2->alpha_dw ;
				if (t1==t2&&flag<1)
				{
					//swap them 
        alpha3=alpha1 ;
        alpha1=alpha2 ;
        alpha2=alpha3 ;

	flag = 2 ;
        name1_up = alpha1->setname_up ;
        name1_dw = alpha1->setname_dw ;
        name2_up = alpha2->setname_up ;
        name2_dw = alpha2->setname_dw ;
                                a1 = n1 = alpha1->alpha_up ;            //a
                                a1a = n1a = alpha1->alpha_dw ;          //a*
                                a2 = n2 = alpha2->alpha_up ;
                                a2a = n2a = alpha2->alpha_dw ;

        F1 = alpha1->f_cache ;
        F2 = alpha2->f_cache ;          // must update Io & I_LOW & I_UP every accepted step

        K11 = Calc_Kernel( alpha1, alpha1, settings ) ;
        K12 = Calc_Kernel( alpha1, alpha2, settings ) ;
        K22 = Calc_Kernel( alpha2, alpha2, settings ) ;

        ueta = K11 + K22 - K12 - K12 ;
	fcase4 = FALSE ;	}
			}
		}

		}
		while(!(case5==TRUE||(fcase4==TRUE&&fcase3==TRUE&&fcase2==TRUE&&fcase1==TRUE)));
	} //end of if ueta 

	// update Alpha List if necessary, then update Io_Cache, and vote B_LOW & B_UP
	if ( fabs((n2 - n2a) - (alpha2->alpha_up - alpha2->alpha_dw)) > 0 )
	{
	// store alphas in Alpha List
		a1 = alpha1->alpha_up ;	
		a1a = alpha1->alpha_dw ;
		a2 = alpha2->alpha_up ;
		a2a = alpha2->alpha_dw ;
		alpha1->alpha_up = n1 ;	
		alpha1->alpha_dw = n1a ;
		alpha2->alpha_up = n2 ;
		alpha2->alpha_dw = n2a ;
		alpha1->alpha = - alpha1->alpha_up + alpha1->alpha_dw ;		
		alpha2->alpha = - alpha2->alpha_up + alpha2->alpha_dw ;

		// update mu
		for (mu=mu1;mu<=mu2;mu++)
			settings->mu[mu-1] -= delphi ;

		// update Set & Cache_List  
		if ( TRUE == case1 )
		{
			name1_up = Get_UP_Label(alpha1,settings) ;
			name2_dw = Get_DW_Label(alpha2,settings) ;
		}
		else if ( TRUE == case2 )
		{
			name1_up = Get_UP_Label(alpha1,settings) ;
			name2_up = Get_UP_Label(alpha2,settings) ;
		}
		else if ( TRUE == case3 )
		{
			name1_dw = Get_DW_Label(alpha1,settings) ;
			name2_dw = Get_DW_Label(alpha2,settings) ;
		}
		else if ( TRUE == case4 )
		{
			name1_dw = Get_DW_Label(alpha1,settings) ;
			name2_up = Get_UP_Label(alpha2,settings) ;
		}
		
		if ( alpha1->setname_up != name1_up || alpha1->setname_dw != name1_dw )
		{			
			if ( (Io_a == name1_up || Io_b == name1_dw) && (alpha1->setname_up != Io_a && alpha1->setname_dw != Io_b) )	
				Add_Cache_Node( &Io_CACHE, alpha1 ) ; // insert into Io 
			if ( (alpha1->setname_up == Io_a || alpha1->setname_dw == Io_b) && name1_up != Io_a && name1_dw != Io_b )
				Del_Cache_Node( &Io_CACHE, alpha1 ) ;
			if (TRUE == case1||TRUE == case2)
				alpha1->setname_up = name1_up ;
			if (TRUE == case3||TRUE == case4)
				alpha1->setname_dw = name1_dw ;
		}		
		if ( alpha2->setname_up != name2_up || alpha2->setname_dw != name2_dw  )
		{						
			if ( (Io_a == name2_up || Io_b == name2_dw) && (alpha2->setname_up != Io_a && alpha2->setname_dw != Io_b) )		
				Add_Cache_Node( &Io_CACHE, alpha2 ) ; // insert into Io 						
			if ( (Io_a == alpha2->setname_up || Io_b == alpha2->setname_dw) && name2_up != Io_a && name2_dw != Io_b )
				Del_Cache_Node( &Io_CACHE, alpha2 ) ;
			if (TRUE == case2||TRUE == case4)
				alpha2->setname_up = name2_up ;
			if (TRUE == case1||TRUE == case3)
				alpha2->setname_dw = name2_dw ;
		}

		// initialize b_up b_low
		index = (int *)calloc(settings->pairs->count,sizeof(int)) ;
		if (NULL == index)
		{
			printf("\n FATAL ERROR : fail to malloc index.\n") ;

			exit(1) ;
		}

		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
		if (settings->ij_up[loop-1]!=0)
		{
			alpha3 = ALPHA + settings->ij_up[loop-1] - 1 ;
			if (alpha3!=alpha1 && alpha3!=alpha2 && Io_a!=alpha3->setname_up && Io_b!=alpha3->setname_dw) 
			{
				settings->bj_up[loop-1] += 
					- ((alpha1->alpha_up - alpha1->alpha_dw) 
					- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
					* Calc_Kernel( alpha2, alpha3, settings ) ;
				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=
						- ((alpha1->alpha_up - alpha1->alpha_dw) 
						- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
						- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
						* Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_up[loop-1] = INT_MAX ;
				settings->ij_up[loop-1] = 0 ;
			}
			}
			if (settings->ij_low[loop-1]!=0)
			{
			alpha3 = ALPHA + settings->ij_low[loop-1] - 1 ;
			if (alpha3!=alpha1 && alpha2!=alpha3 && Io_a!=alpha3->setname_up && Io_b!=alpha3->setname_dw) 
			{	
				settings->bj_low[loop-1] +=  
					- ((alpha1->alpha_up - alpha1->alpha_dw) 
					- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
					* Calc_Kernel( alpha2, alpha3, settings ) ;
				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=  						
						- ((alpha1->alpha_up - alpha1->alpha_dw) 
						- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
						- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
						* Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_low[loop-1] = INT_MIN ;
				settings->ij_low[loop-1] = 0 ;
			}
			}
		}

		// update f-cache of i1 & i2 if not in Io_Cache
		if (alpha1->setname_up != Io_a && alpha1->setname_dw != Io_b)
		{
			if (0==index[alpha1-ALPHA])
			{
				alpha1->f_cache = alpha1->f_cache - ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) * K11 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) * K12 ;
				index[alpha1-ALPHA] = 1 ;
			}
			alpha3=alpha1 ;
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;
				//lower
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;
				//upper
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
		}
		if (alpha2->setname_up != Io_a && alpha2->setname_dw != Io_b)
		{
			if (0==index[alpha2-ALPHA])
			{
				alpha2->f_cache = alpha2->f_cache - ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) * K12
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) * K22 ;
				index[alpha2-ALPHA] = 1 ;
			}
			alpha3=alpha2 ;			
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;
				//lower
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;
				//upper
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
		}			

		// update Fi in Io_Cache and vote B_LOW & B_UP if possible
		cache = Io_CACHE.front ;
		while ( NULL != cache )
		{	
			alpha3 = cache->alpha ;	
			if ( 0==index[alpha3-ALPHA])
			{
				alpha3->f_cache = alpha3->f_cache - ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) 
				* Calc_Kernel( alpha1, alpha3, settings ) 
				- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
				* Calc_Kernel( alpha2, alpha3, settings ) ;
				index[alpha3-ALPHA] = 1 ;
			}
			
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;
				//lower
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;
				//upper
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			cache = cache->next ;				
		} // end of while
		
		free(index) ;


		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
			if (0==settings->ij_up[loop-1]||0==settings->ij_low[loop-1])
			{ 
				Check_Alphas ( ALPHA, settings ) ;
				loop = settings->pairs->classes ;
			}
		}

#ifdef _ORDINAL_DEBUG

		for ( t1 = 1; t1 <= settings->pairs->count; t1 ++ )
		{	
			alpha3 = ALPHA + t1 - 1 ;
			printf("%u-target %u---func %f: alpha = %f , alpha* = %f\n",t1, alpha3->pair->target, alpha3->f_cache, alpha3->alpha_up, alpha3->alpha_dw) ;
		}
		for (t1=1;t1<settings->pairs->classes;t1++)
			printf("threshold %u : upper=%f(%u), lower=%f(%u), mu=%f\n", t1, settings->bj_up[t1-1],
				settings->ij_up[t1-1], settings->bj_low[t1-1], settings->ij_low[t1-1], settings->mu[t1-1]) ;
		deltamu = 0 ;
		for (t1=0;t1<settings->pairs->count;t1++)
		{
			alpha1 = ALPHA+t1 ;
			for (t2=0;t2<t1;t2++)
			{
				alpha2 = ALPHA+t2 ;
				deltamu += (-alpha1->alpha_up+alpha1->alpha_dw)
					*(-alpha2->alpha_up+alpha2->alpha_dw)*Calc_Kernel( alpha1, alpha2, settings ) ;
			}
			deltamu += 0.5*(-alpha1->alpha_up+alpha1->alpha_dw)
					*(-alpha1->alpha_up+alpha1->alpha_dw)*Calc_Kernel( alpha1, alpha1, settings ) ;
			deltamu -= (alpha1->alpha_up+alpha1->alpha_dw) ;
		}
		printf("objective functional %f\n",deltamu) ;
#endif
	// update mu_bias
	for (loop = 1; loop < settings->pairs->classes; loop ++)
	{
		settings->bmu_low[loop-1]=settings->bj_low[loop-1] ;
		settings->imu_low[loop-1]=settings->ij_low[loop-1] ;
		if (loop>1)
		{	
			// b_low^j=max{b_low^j-1,b_low^j}
			if (settings->bmu_low[loop-2]>settings->bmu_low[loop-1])
			{
				settings->bmu_low[loop-1]=settings->bmu_low[loop-2] ;
				settings->imu_low[loop-1]=settings->imu_low[loop-2] ;
			}
		}
	}
	for (loop = settings->pairs->classes-1; loop > 0; loop --)
	{
		settings->bmu_up[loop-1]=settings->bj_up[loop-1] ;
		settings->imu_up[loop-1]=settings->ij_up[loop-1] ;
		if (loop<settings->pairs->classes-1)
		{
			// b_up^j=min{b_up^j,b_up^j+1}
			if (settings->bmu_up[loop-1]>settings->bmu_up[loop])
			{
				settings->bmu_up[loop-1]=settings->bmu_up[loop] ;
				settings->imu_up[loop-1]=settings->imu_up[loop] ;
			}			
		}
	}
	for (loop = 2; loop < settings->pairs->classes; loop ++)
	{
		if (settings->mu[loop-1]>EPS*EPS) 
		{
			if (settings->bmu_up[loop-1]>settings->bmu_up[loop-2])
			{
				settings->bmu_up[loop-1]=settings->bmu_up[loop-2] ;
				settings->imu_up[loop-1]=settings->imu_up[loop-2] ;
			}
			if (settings->bmu_low[loop-2]<settings->bmu_low[loop-1])
			{
				settings->bmu_low[loop-2]=settings->bmu_low[loop-1] ;
				settings->imu_low[loop-2]=settings->imu_low[loop-1] ;
			}
		}
	}
#ifdef _ORDINAL_DEBUG
		for (t1=1;t1<settings->pairs->classes;t1++)
			printf("threshold %u : mu_up=%f(%u), mu_low=%f(%u), mu=%f\n", t1, settings->bmu_up[t1-1],
				settings->imu_up[t1-1], settings->bmu_low[t1-1], settings->imu_low[t1-1], settings->mu[t1-1]) ;
#endif
		return TRUE ;
	} // end of update 
	else
	{
		//printf("fail to update pairs %lu and %lu\n",i1,i2) ;
		return FALSE ;
	}
}*/

BOOL ordinal_takestep ( Alphas * alpha1, Alphas * alpha2, unsigned int threshold, smo_Settings * settings )
{
	double a1 = 0, a1a = 0, a2 = 0, a2a = 0 ;	/*/old alpha*/
	double n1 = 0, n1a = 0, n2 = 0, n2a = 0 ;	/*/new alpha*/
	double F1 = 0, F2 = 0 ;
	BOOL case1 = FALSE, case2 = FALSE, case3 = FALSE, 
		case4 = FALSE ;
	double K11 = 0, K12 = 0, K22 = 0 ;
	double ueta = 0, gamma = 0, delphi = 0 ;
	double H = 0, L = 0 ;
	double ObjH = 0, ObjL = 0 ;
	Set_Name name1_up, name1_dw, name2_up, name2_dw ;
	Alphas * alpha3 = NULL ;
	Cache_Node * cache = NULL ;

	long unsigned int i1 = 0 ;
	long unsigned int i2 = 0 ; 
	unsigned int t1, t2 ;
	int * index ;
	unsigned int loop ;
#ifdef _ORDINAL_DEBUG
	double temp ;
#endif
	if ( NULL == alpha1 || NULL == alpha2 || NULL == settings )
	{
		printf( " Alpha list error. \r\n" ) ;
		return FALSE ;
	}

	if (threshold > settings->pairs->classes-1 || threshold < 1)
	{
		printf( " Active threshold %u is greater than %u.\n", threshold, settings->pairs->classes-1) ;
		return FALSE ;
	}
    
	i1 = alpha1-ALPHA+1 ;
	i2 = alpha2-ALPHA+1 ;

	if ( i1 == i2 ) 
		return FALSE ;
#ifdef _ORDINAL_DEBUG
	/*/printf("%u and %u in takestep.\n",i1,i2) ;*/
#endif

	t1 = alpha1->pair->target ;
	t2 = alpha2->pair->target ;

	name1_up = alpha1->setname_up ;
	name1_dw = alpha1->setname_dw ;
	name2_up = alpha2->setname_up ;
	name2_dw = alpha2->setname_dw ;

	if (t1==(threshold)&&t2==(threshold+1))
		case1 = TRUE ;
	else if (t1==(threshold+1)&&t2==(threshold))
		case2 = TRUE ;
	else if (t1==(threshold)&&t2==(threshold))
		case3 = TRUE ;
	else if (t1==(threshold+1)&&t2==(threshold+1))
		case4 = TRUE ;
	else
	{
		return FALSE ;
		/*/return ordinal_cross_takestep (alpha1,alpha2,threshold,settings) ;*/
	}
	
	a1 = n1 = alpha1->alpha_up ;		
	a1a = n1a = alpha1->alpha_dw ;		
	a2 = n2 = alpha2->alpha_up ;
	a2a = n2a = alpha2->alpha_dw ;

	F1 = alpha1->f_cache ;	
	F2 = alpha2->f_cache ;		/*/ must update Io & I_LOW & I_UP every accepted step*/

	K11 = Calc_Kernel( alpha1, alpha1, settings ) ; 
	K12 = Calc_Kernel( alpha1, alpha2, settings ) ;
	K22 = Calc_Kernel( alpha2, alpha2, settings ) ; 

	ueta = K11 + K22 - K12 - K12 ;
	
	if ( 0 >= ueta )
	{
		printf(" Negative Definite Matrix.\n") ; 
		/*/ calculate objective function at H or L, choose the smaller one*/
		ObjH=0 ;
		ObjL=0 ;
		return FALSE ;
	}
	else /*/ normal condition*/
	{
		if (TRUE==case1)
		{
			/*/ alpha1_up alpha2_dw*/
			gamma = a1 - a2a ;
			if (gamma>0&&gamma<=VC)
			{
				H = VC ;
				L = gamma ;
			}
			else if (gamma<=0&&gamma>=-VC)
			{
				H = VC + gamma ;
				L = 0 ;
			}
			else
			{
				printf("beyond corner 1.\n");
				return FALSE ;
			}
			ueta = K11 + K22 - K12 - K12 ;
			delphi = - F1 + F2 - 2 ;
			n1 = a1 - delphi/ueta ;
			n2a = a2a - delphi/ueta ;
			if (n1>H)
			{
				n1 = H ;
				if (gamma>=0)
					n2a = VC - gamma ;
				else 
					n2a = VC ;
			}
			else if (n1<L)
			{
				n1 = L ;
				if (gamma>=0)
					n2a = 0 ;
				else 
					n2a = - gamma ;
			}
		}
		else if (TRUE==case2)
		{
			/*/ alpha1_dw alpha2_up*/
			gamma = a1a - a2 ;
			if (gamma>0&&gamma<=VC)
			{
				H = VC ;
				L = gamma ;
			}
			else if (gamma<=0&&gamma>=-VC)
			{
				H = VC + gamma ;
				L = 0 ;
			}
			else
			{
				printf("beyond corner 2.\n");
				return FALSE ;
			}
			ueta = K11 + K22 - K12 - K12 ;
			delphi = F1 - F2 - 2 ;
			n1a = a1a - delphi/ueta ;
			n2 = a2 - delphi/ueta ;
			if (n1a>H)
			{
				n1a = H ;
				if (gamma>=0)
					n2 = VC - gamma ;
				else 
					n2 = VC ;
			}
			else if (n1a<L)
			{
				n1a = L ;
				if (gamma>=0)
					n2 = 0 ;
				else 
					n2 = - gamma ;
			}
		}
		else if (TRUE==case3)
		{
			/*/ alpha1_up alpha2_up*/
			gamma = a1 + a2 ;
			if (gamma>=0&&gamma<VC)
			{
				H = gamma ;
				L = 0 ;
			}
			else if (gamma>=VC&&gamma<=(VC+VC))
			{
				H = VC ;
				L = gamma-VC ;
			}
			else
			{
				printf("beyond corner 3.\n");
				return FALSE ;
			}
			ueta = K11 + K22 - K12 - K12 ;
			delphi = - F1 + F2 ;
			n1 = a1 - delphi/ueta ;
			n2 = a2 + delphi/ueta ;
			if (n1>H)
			{
				n1 = H ;
				if (gamma>0&&gamma<VC)
					n2 = 0 ;
				else 
					n2 = gamma - VC ;
			}
			else if (n1<L)
			{
				n1 = L ;
				if (gamma>0&&gamma<VC)
					n2 = gamma ;
				else 
					n2 = VC ;
			}
		}
		else if (TRUE==case4)
		{
			
			gamma = a1a + a2a ;
			if (gamma>=0&&gamma<VC)
			{
				H = gamma ;
				L = 0 ;
			}
			else if (gamma>=VC&&gamma<=(VC+VC))
			{
				H = VC ;
				L = gamma-VC ;
			}
			else
			{
				printf("beyond corner 4.\n");
				return FALSE ;
			}
			ueta = K11 + K22 - K12 - K12 ;
			delphi = F1 - F2 ;
			n1a = a1a - delphi/ueta ;
			n2a = a2a + delphi/ueta ;
			if (n1a>H)
			{
				n1a = H ;
				if (gamma>0&&gamma<VC)
					n2a = 0 ;
				else 
					n2a = gamma - VC ;
			}
			else if (n1a<L)
			{
				n1a = L ;
				if (gamma>0&&gamma<VC)
					n2a = gamma ;
				else 
					n2a = VC ;
			}
		}
		else
			printf(" Unknown case.\n") ;
	} /*/end of if ueta */

	/*/ update Alpha List if necessary, then update Io_Cache, and vote B_LOW & B_UP*/
	if ( fabs((n2 - n2a) - (alpha2->alpha_up - alpha2->alpha_dw)) > 0 )
	{
		/*/ store alphas in Alpha List*/
		a1 = alpha1->alpha_up ;	
		a1a = alpha1->alpha_dw ;
		a2 = alpha2->alpha_up ;
		a2a = alpha2->alpha_dw ;
		alpha1->alpha_up = n1 ;	
		alpha1->alpha_dw = n1a ;
		alpha2->alpha_up = n2 ;
		alpha2->alpha_dw = n2a ;
		alpha1->alpha = - alpha1->alpha_up + alpha1->alpha_dw ;		
		alpha2->alpha = - alpha2->alpha_up + alpha2->alpha_dw ;

		/*/ update Set & Cache_List  */

		if ( TRUE == case1 )
		{
			name1_up = Get_UP_Label(alpha1,settings) ;
			name2_dw = Get_DW_Label(alpha2,settings) ;
		}
		else if ( TRUE == case2 )
		{
			name1_dw = Get_DW_Label(alpha1,settings) ;
			name2_up = Get_UP_Label(alpha2,settings) ;
		}
		else if ( TRUE == case3 )
		{
			name1_up = Get_UP_Label(alpha1,settings) ;
			name2_up = Get_UP_Label(alpha2,settings) ;
		}
		else if ( TRUE == case4 )
		{
			name1_dw = Get_DW_Label(alpha1,settings) ;
			name2_dw = Get_DW_Label(alpha2,settings) ;
		}
		
		if ( alpha1->setname_up != name1_up || alpha1->setname_dw != name1_dw )
		{			
			if ( (Io_a == name1_up || Io_b == name1_dw) && (alpha1->setname_up != Io_a && alpha1->setname_dw != Io_b) )	
				Add_Cache_Node( &Io_CACHE, alpha1 ) ; 
			if ( (alpha1->setname_up == Io_a || alpha1->setname_dw == Io_b) && name1_up != Io_a && name1_dw != Io_b )
				Del_Cache_Node( &Io_CACHE, alpha1 ) ;
			if (TRUE == case1||TRUE == case3)
				alpha1->setname_up = name1_up ;
			if (TRUE == case2||TRUE == case4)
				alpha1->setname_dw = name1_dw ;
		}		
		if ( alpha2->setname_up != name2_up || alpha2->setname_dw != name2_dw  )
		{						
			if ( (Io_a == name2_up || Io_b == name2_dw) && (alpha2->setname_up != Io_a && alpha2->setname_dw != Io_b) )		
				Add_Cache_Node( &Io_CACHE, alpha2 ) ; 				
			if ( (Io_a == alpha2->setname_up || Io_b == alpha2->setname_dw) && name2_up != Io_a && name2_dw != Io_b )
				Del_Cache_Node( &Io_CACHE, alpha2 ) ;
			if (TRUE == case2||TRUE == case3)
				alpha2->setname_up = name2_up ;
			if (TRUE == case1||TRUE == case4)
				alpha2->setname_dw = name2_dw ;
		}

		/* initialize b_up b_low */
		index = (int *)calloc(settings->pairs->count,sizeof(int)) ;
		if (NULL == index)
		{
			printf("\n FATAL ERROR : fail to malloc index.\n") ;
			exit(1) ;
		}

		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
if (settings->ij_up[loop-1]!=0)
{
			alpha3 = ALPHA + settings->ij_up[loop-1] - 1 ;
			if (alpha3!=alpha1 && alpha3!=alpha2 && Io_a!=alpha3->setname_up && Io_b!=alpha3->setname_dw) 
			{
				settings->bj_up[loop-1] += 
					- ((alpha1->alpha_up - alpha1->alpha_dw) 
					- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
					* Calc_Kernel( alpha2, alpha3, settings ) ;
				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=
						- ((alpha1->alpha_up - alpha1->alpha_dw) 
						- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
						- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
						* Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_up[loop-1] = INT_MAX ;
				settings->ij_up[loop-1] = 0 ;
			}
}
if (settings->ij_low[loop-1]!=0)
{
			alpha3 = ALPHA + settings->ij_low[loop-1] - 1 ;
			if (alpha3!=alpha1 && alpha2!=alpha3 && Io_a!=alpha3->setname_up && Io_b!=alpha3->setname_dw) 
			{	
				settings->bj_low[loop-1] +=  
					- ((alpha1->alpha_up - alpha1->alpha_dw) 
					- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
					* Calc_Kernel( alpha2, alpha3, settings ) ;

				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=  						
						- ((alpha1->alpha_up - alpha1->alpha_dw) 
						- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
						- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
						* Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_low[loop-1] = INT_MIN ;
				settings->ij_low[loop-1] = 0 ;
			}
}
		}

		/* update f-cache of i1 & i2 if not in Io_Cache*/
		if (alpha1->setname_up != Io_a && alpha1->setname_dw != Io_b)
		{
			if (0==index[alpha1-ALPHA])
			{
				alpha1->f_cache = alpha1->f_cache - ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) * K11 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) * K12 ;
				index[alpha1-ALPHA]=1 ;	
			}
			alpha3=alpha1 ;

			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;
				/*/lower*/
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;
				/*/upper*/
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
		}
		if (alpha2->setname_up != Io_a && alpha2->setname_dw != Io_b)
		{
			if (0==index[alpha2-ALPHA])
			{	
				alpha2->f_cache = alpha2->f_cache - ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) * K12
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) * K22 ;
				index[alpha2-ALPHA]=1 ;
			}
			alpha3=alpha2 ;	
		
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;
				/*/lower */
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;
				/*/upper*/
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
		}
				
		/*/ update Fi in Io_Cache and vote B_LOW & B_UP if possible*/
		cache = Io_CACHE.front ;
		while ( NULL != cache )
		{	
			alpha3 = cache->alpha ;

			if ( 0==index[alpha3-ALPHA])
			{
				alpha3->f_cache = alpha3->f_cache - ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) 
				* Calc_Kernel( alpha1, alpha3, settings ) 
				- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
				* Calc_Kernel( alpha2, alpha3, settings ) ;
				index[alpha3-ALPHA]=1 ;
			}			
			
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;
				
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}

			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;

				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			cache = cache->next ;				
		} /*/ end of while*/
		
		free(index) ;

		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
			if (0==settings->ij_up[loop-1]||0==settings->ij_low[loop-1])
			{ 
				/*/return Check_Alphas ( ALPHA, settings ) ; */
				Check_Alphas ( ALPHA, settings ) ;
				loop = settings->pairs->classes ;
			}
		}

	for (loop = 1; loop < settings->pairs->classes; loop ++)
	{
		settings->bmu_low[loop-1]=settings->bj_low[loop-1] ;
		settings->imu_low[loop-1]=loop ;
		if (loop>1)
		{	
			/*/ b_low^j=max{b_low^j-1,b_low^j} */
			if (settings->bmu_low[loop-2]>settings->bmu_low[loop-1])
			{
				settings->bmu_low[loop-1]=settings->bmu_low[loop-2] ;
				settings->imu_low[loop-1]=settings->imu_low[loop-2] ;
			}
		}
	}
	for (loop = settings->pairs->classes-1; loop > 0; loop --)
	{
		settings->bmu_up[loop-1]=settings->bj_up[loop-1] ;
		settings->imu_up[loop-1]=loop ;
		if (loop<settings->pairs->classes-1)
		{
			/*/ b_up^j=min{b_up^j,b_up^j+1} */
			if (settings->bmu_up[loop-1]>settings->bmu_up[loop])
			{
				settings->bmu_up[loop-1]=settings->bmu_up[loop] ;
				settings->imu_up[loop-1]=settings->imu_up[loop] ;
			}			
		}
	}
	for (loop = 2; loop < settings->pairs->classes; loop ++)
	{
		if (settings->mu[loop-1]>EPS*EPS) 
		{
			if (settings->bmu_up[loop-1]>settings->bmu_up[loop-2])
			{
				settings->bmu_up[loop-1]=settings->bmu_up[loop-2] ;
				settings->imu_up[loop-1]=settings->imu_up[loop-2] ;
			}
			if (settings->bmu_low[loop-2]<settings->bmu_low[loop-1])
			{
				settings->bmu_low[loop-2]=settings->bmu_low[loop-1] ;
				settings->imu_low[loop-2]=settings->imu_low[loop-1] ;
			}
		}
	}

#ifdef _ORDINAL_DEBUG
		for (t1=1;t1<settings->pairs->classes;t1++)
			printf("threshold %u : upper=%f(%u), lower=%f(%u), mu=%f\n", t1, settings->bj_up[t1-1],
				settings->ij_up[t1-1], settings->bj_low[t1-1], settings->ij_low[t1-1], settings->mu[t1-1]) ;
		temp = 0 ;
		for (t1=0;t1<settings->pairs->count;t1++)
		{
			alpha1 = ALPHA+t1 ;
			for (t2=0;t2<t1;t2++)
			{
				alpha2 = ALPHA+t2 ;
				temp += (-alpha1->alpha_up+alpha1->alpha_dw)
					*(-alpha2->alpha_up+alpha2->alpha_dw)*Calc_Kernel( alpha1, alpha2, settings ) ;
			}
			temp += 0.5*(-alpha1->alpha_up+alpha1->alpha_dw)
					*(-alpha1->alpha_up+alpha1->alpha_dw)*Calc_Kernel( alpha1, alpha1, settings ) ;
			temp -= (alpha1->alpha_up+alpha1->alpha_dw) ;
		}
		printf("objective functional %f\n",temp) ;
#endif
		return TRUE ;
	} /*/ end of update */
	else
	{
		{
			/*printf("fail to update pairs %u and %u\n",i1,i2) ;*/
			return FALSE ;
		}
	}
}

BOOL ordinal_cross_takestep ( Alphas * Bup, unsigned int b1, Alphas * Blow, unsigned int b2, smo_Settings * settings )
{
	double a1 = 0, a1a = 0, a2 = 0, a2a = 0 ;	
	double n1 = 0, n1a = 0, n2 = 0, n2a = 0 ;	
	double F1 = 0, F2 = 0 ;
	BOOL case1 = FALSE, case2 = FALSE, case3 = FALSE, 
		case4 = FALSE ;  
	double K11 = 0, K12 = 0, K22 = 0 ;
	double ueta = 0, gamma = 0, delphi = 0 ;
	double H = 0, L = 0 ;
	double ObjH = 0, ObjL = 0 ;
	Set_Name name1_up, name1_dw, name2_up, name2_dw ;
	Alphas * alpha1 = NULL ;
	Alphas * alpha2 = NULL ;
	Alphas * alpha3 = NULL ;
	Cache_Node * cache = NULL ;

	long unsigned int i1 = 0 ;
	long unsigned int i2 = 0 ; 
	unsigned int t1, t2 ;
	int * index ;
	unsigned int loop ;
	int s1=0, s2=0, mu, mu1=0, mu2=0 ;
	double deltamu = -1 ;


	if ( NULL == Bup || NULL == Blow || NULL == settings )
	{
		printf( " Alpha list error. \r\n" ) ;
		return FALSE ;
	}

	if (b1 > settings->pairs->classes-1 || b1 < 1 || b2 > settings->pairs->classes-1 || b2 < 1)
	{
		printf( " Active threshold is greater than %u.\n", settings->pairs->classes-1) ;
		return FALSE ;
	}
   
	/*/printf("get in cross update.\n") ;*/

	if ( Bup == Blow )
	{
		return ordinal_cross_identical (Bup, Blow, b1, settings) ;
	}

	/*/b1 = settings->imu_up[threshold-1] ;*/
	/*/b2 = settings->imu_low[threshold-1] ;*/

	if (b1==b2)
	{
		/*/printf("go to standard update.\n") ;*/
		return ordinal_takestep(Bup, Blow, b1, settings) ;
	}

	alpha1 = Bup ;
	alpha2 = Blow ;

	t1 = alpha1->pair->target ;
	t2 = alpha2->pair->target ;

	name1_up = alpha1->setname_up ;
	name1_dw = alpha1->setname_dw ;
	name2_up = alpha2->setname_up ;
	name2_dw = alpha2->setname_dw ;

	/*/ determine s_o & s_u*/

	if (t1==b1)
	{ 
		if (name1_up==Io_a||name1_up==I_Thr)
		{
			s1 = -1 ;
			if (b1<b2)
				mu1 = t1 + 1 ;
			else
				mu1 = t1 ;
		}
		else		
			printf("unknown s_u.\n") ;
	}
	else if (t1==b1+1)
	{ 
		if (name1_dw==Io_b||name1_dw==I_One)
		{
			s1 = +1 ;
			if (b1<b2)
				mu1 = t1 ;
			else
				mu1 = t1 - 1 ;
		}
		else
			printf("unknown s_u.\n") ;
	}
	else
		printf("unknown case t1.\n") ;

	if (t2==b2)
	{ 
		if (name2_up==Io_a||name2_up==I_Two)
		{
			s2 = -1 ;
			if (b1<b2)
				mu2 = t2 ;
			else
				mu2 = t2 + 1 ;
		}
		else
			printf("unknown s_o.\n") ;
	}
	else if (t2==b2+1)
	{ 
		if (name2_dw==Io_b||name2_dw==I_Fou)
		{
			s2 = +1 ;
			if (b1<b2)
				mu2 = t2 - 1 ;
			else
				mu2 = t2 ;
		}
		else
			printf("unknown s_o.\n") ;
	}
	else
		printf("unknown case t2.\n") ;


	if (b1>b2)
	{
		/*/swap*/
		alpha3=alpha1;
		alpha1=alpha2;
		alpha2=alpha3;
		mu=s1;
		s1=s2;
		s2=mu;
	}


	b1=min(mu1,mu2);
	b2=max(mu1,mu2);
	mu1=b1;
	mu2=b2;

	
	i1 = alpha1-ALPHA+1 ;
	i2 = alpha2-ALPHA+1 ;

	t1 = alpha1->pair->target ;
	t2 = alpha2->pair->target ;

	name1_up = alpha1->setname_up ;
	name1_dw = alpha1->setname_dw ;
	name2_up = alpha2->setname_up ;
	name2_dw = alpha2->setname_dw ;
	
	a1 = n1 = alpha1->alpha_up ;		
	a1a = n1a = alpha1->alpha_dw ;		
	a2 = n2 = alpha2->alpha_up ;
	a2a = n2a = alpha2->alpha_dw ;

	F1 = alpha1->f_cache ;	
	F2 = alpha2->f_cache ;		/*/ must update Io & I_LOW & I_UP every accepted step*/

	K11 = Calc_Kernel( alpha1, alpha1, settings ) ; 
	K12 = Calc_Kernel( alpha1, alpha2, settings ) ;
	K22 = Calc_Kernel( alpha2, alpha2, settings ) ; 

	ueta = K11 + K22 - K12 - K12 ;

	/*/ case 1*/
	if ( (s1==-1) && (s2==+1) )
	{
		/*/ - a_{k} + a_{k+2}* = c.*/
		case1 = TRUE ;
	}
	/*/ case 2*/
	else if ( (s1==-1) && (s2==-1) )
	{
		/*/ - a_{k-1} - a_{k} = c.*/
		case2 = TRUE ;
	}
	/*/ case 3*/
	else if ( (s1==+1) && (s2==+1) )
	{
		/*/ a_{k+1}* + a_{k+2}* = c.*/
		case3 = TRUE ;
	}
	/*/ case 4*/
	else if ( (s1==+1) && (s2==-1) )
	{
		/*/ a_{k-1}* - a_{k+1} = c.*/
		case4 = TRUE ;
	}
	else
	{
		printf("\nWarning : fail to specify the case.\n") ;
		return FALSE ;
	}

	if ( 0 >= ueta )
	{
		printf(" Negative Definite Matrix cross.\n") ;
		/*/ calculate objective function at H or L, choose the smaller one*/
		ObjH=0 ;
		ObjL=0 ;
		return FALSE ;
	}
	else /*/ normal condition*/
	{
		if (TRUE==case1)
		{
			/*/ - a_{k} + a_{k+2}* = c.	*/	
			gamma = a1 + s1*s2*a2a ;
			Decide_Boundary (gamma, s1, s2, settings, &H, &L) ;
			if (ueta>0)
				delphi = (- F1 + F2 + s1 - s2)/ueta ;/*/ n1=a1+s1*adlphi ;*/
			else
				delphi = (- F1 + F2 + s1 - s2) ;
			for (mu=mu1;mu<=mu2;mu++)
			{
				if (settings->mu[mu-1]<delphi)
				{
					delphi = settings->mu[mu-1] ;
					deltamu = 0 ;
				}
			}
			n1=a1+s1*delphi ;				
			n2a=a2a-s2*delphi ;
			if (n1>H)
			{
				n1 = H ;
				if (gamma>=0)
					n2a = VC - gamma ;
				else 
					n2a = VC ;
				delphi = s1*(H-a1) ;
				deltamu = delphi ;
			}
			else if (n1<L)
			{
				n1 = L ;
				if (gamma>=0)
					n2a = 0 ;
				else 
					n2a = - gamma ;
				delphi = s1*(L-a1) ;
				deltamu = delphi ;
			}
		}
		else if (TRUE==case2)
		{			
			/*/ - a_{k-1} - a_{k} = c.		*/
			gamma = a1 + s1*s2*a2 ;
			Decide_Boundary (gamma, s1, s2, settings, &H, &L) ;
			if (ueta>0)
				delphi = (- F1 + F2 + s1 - s2)/ueta ;/*/ n1=a1+s1*adlphi ;*/
			else
				delphi = (- F1 + F2 + s1 - s2) ;
			for (mu=mu1;mu<=mu2;mu++)
			{
				if (settings->mu[mu-1]<delphi)
				{
					delphi = settings->mu[mu-1] ;
					deltamu = 0 ;
				}
			}
			n1=a1+s1*delphi ;				
			n2=a2-s2*delphi ;
			if (n1>H)
			{
				n1 = H ;
				if (gamma>0&&gamma<VC)
					n2 = 0 ;
				else 
					n2 = gamma - VC ;
				delphi = s1*(H-a1) ;
				deltamu = delphi ;
			}
			else if (n1<L)
			{
				n1 = L ;
				if (gamma>0&&gamma<VC)
					n2 = gamma ;
				else 
					n2 = VC ;
				delphi = s1*(L-a1) ;
				deltamu = delphi ;
			}
		}
		else if (TRUE==case3)
		{

			gamma = a1a + s1*s2*a2a ;
			Decide_Boundary (gamma, s1, s2, settings, &H, &L) ;
			if (ueta>0)
				delphi = (- F1 + F2 + s1 - s2)/ueta ;
			else
				delphi = (- F1 + F2 + s1 - s2) ;
			for (mu=mu1;mu<=mu2;mu++)
			{
				if (settings->mu[mu-1]<delphi)
				{
					delphi = settings->mu[mu-1] ;
					deltamu = 0 ;
				}
			}
			n1a=a1a+s1*delphi ;				
			n2a=a2a-s2*delphi ;
			if (n1a>H)
			{
				n1a = H ;
				if (gamma>0&&gamma<VC)
					n2a = 0 ;
				else 
					n2a = gamma - VC ;
				delphi = s1*(H-a1a) ;
				deltamu = delphi ;
			}
			else if (n1a<L)
			{
				n1a = L ;
				if (gamma>0&&gamma<VC)
					n2a = gamma ;
				else 
					n2a = VC ;
				delphi = s1*(L-a1a) ;
				deltamu = delphi ;
			}
		}
		else if (TRUE==case4)
		{

			gamma = a1a + s1*s2*a2 ;
			Decide_Boundary (gamma, s1, s2, settings, &H, &L) ;
			if (ueta>0)
				delphi = (- F1 + F2 + s1 - s2)/ueta ;
			else
				delphi = (- F1 + F2 + s1 - s2) ;
			for (mu=mu1;mu<=mu2;mu++)
			{
				if (settings->mu[mu-1]<delphi)
				{
					delphi = settings->mu[mu-1] ;
					deltamu = 0 ;
				}
			}
			n1a=a1a+s1*delphi ;
			n2=a2-s2*delphi ;
			if (n1a>H)
			{
				n1a = H ;
				if (gamma>=0)
					n2 = VC - gamma ;
				else 
					n2 = VC ;
				delphi = s1*(H-a1a) ;
				deltamu = delphi ;
			}
			else if (n1a<L)
			{
				n1a = L ;
				if (gamma>=0)
					n2 = 0 ;
				else 
					n2 = - gamma ;
				delphi = s1*(L-a1a) ;
				deltamu = delphi ;
			}
		}
		else
		{
			printf(" Unknown case.\n") ;
		}
	} /*/end of if ueta */		

	/*/ update Alpha List if necessary, then update Io_Cache, and vote B_LOW & B_UP*/
	if ( fabs((n2 - n2a) - (alpha2->alpha_up - alpha2->alpha_dw)) > 0 )
	{
	/*/ store alphas in Alpha List*/
		a1 = alpha1->alpha_up ;	
		a1a = alpha1->alpha_dw ;
		a2 = alpha2->alpha_up ;
		a2a = alpha2->alpha_dw ;
		alpha1->alpha_up = n1 ;	
		alpha1->alpha_dw = n1a ;
		alpha2->alpha_up = n2 ;
		alpha2->alpha_dw = n2a ;
		alpha1->alpha = - alpha1->alpha_up + alpha1->alpha_dw ;		
		alpha2->alpha = - alpha2->alpha_up + alpha2->alpha_dw ;

		/*/ update mu*/
		for (mu=mu1;mu<=mu2;mu++)
			settings->mu[mu-1] -= delphi ;

		/*/ update Set & Cache_List  */
		if ( TRUE == case1 )
		{
			name1_up = Get_UP_Label(alpha1,settings) ;
			name2_dw = Get_DW_Label(alpha2,settings) ;
		}
		else if ( TRUE == case2 )
		{
			name1_up = Get_UP_Label(alpha1,settings) ;
			name2_up = Get_UP_Label(alpha2,settings) ;
		}
		else if ( TRUE == case3 )
		{
			name1_dw = Get_DW_Label(alpha1,settings) ;
			name2_dw = Get_DW_Label(alpha2,settings) ;
		}
		else if ( TRUE == case4 )
		{
			name1_dw = Get_DW_Label(alpha1,settings) ;
			name2_up = Get_UP_Label(alpha2,settings) ;
		}
		
		if ( alpha1->setname_up != name1_up || alpha1->setname_dw != name1_dw )
		{			
			if ( (Io_a == name1_up || Io_b == name1_dw) && (alpha1->setname_up != Io_a && alpha1->setname_dw != Io_b) )	
				Add_Cache_Node( &Io_CACHE, alpha1 ) ; 
			if ( (alpha1->setname_up == Io_a || alpha1->setname_dw == Io_b) && name1_up != Io_a && name1_dw != Io_b )
				Del_Cache_Node( &Io_CACHE, alpha1 ) ;
			if (TRUE == case1||TRUE == case2)
				alpha1->setname_up = name1_up ;
			if (TRUE == case3||TRUE == case4)
				alpha1->setname_dw = name1_dw ;
		}		
		if ( alpha2->setname_up != name2_up || alpha2->setname_dw != name2_dw  )
		{						
			if ( (Io_a == name2_up || Io_b == name2_dw) && (alpha2->setname_up != Io_a && alpha2->setname_dw != Io_b) )		
				Add_Cache_Node( &Io_CACHE, alpha2 ) ; 						
			if ( (Io_a == alpha2->setname_up || Io_b == alpha2->setname_dw) && name2_up != Io_a && name2_dw != Io_b )
				Del_Cache_Node( &Io_CACHE, alpha2 ) ;
			if (TRUE == case2||TRUE == case4)
				alpha2->setname_up = name2_up ;
			if (TRUE == case1||TRUE == case3)
				alpha2->setname_dw = name2_dw ;
		}

		/*/ initialize b_up b_low*/
		index = (int *)calloc(settings->pairs->count,sizeof(int)) ;
		if (NULL == index)
		{
			printf("\n FATAL ERROR : fail to malloc index.\n") ;
			exit(1) ;
		}

		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
		if (settings->ij_up[loop-1]!=0)
		{
			alpha3 = ALPHA + settings->ij_up[loop-1] - 1 ;
			if (alpha3!=alpha1 && alpha3!=alpha2 && Io_a!=alpha3->setname_up && Io_b!=alpha3->setname_dw) 
			{
				settings->bj_up[loop-1] += 
					- ((alpha1->alpha_up - alpha1->alpha_dw) 
					- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
					* Calc_Kernel( alpha2, alpha3, settings ) ;
				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=
						- ((alpha1->alpha_up - alpha1->alpha_dw) 
						- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
						- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
						* Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_up[loop-1] = INT_MAX ;
				settings->ij_up[loop-1] = 0 ;
			}
			}
			if (settings->ij_low[loop-1]!=0)
			{
			alpha3 = ALPHA + settings->ij_low[loop-1] - 1 ;
			if (alpha3!=alpha1 && alpha2!=alpha3 && Io_a!=alpha3->setname_up && Io_b!=alpha3->setname_dw) 
			{	
				settings->bj_low[loop-1] +=  
					- ((alpha1->alpha_up - alpha1->alpha_dw) 
					- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
					* Calc_Kernel( alpha2, alpha3, settings ) ;
				if (0==index[alpha3-ALPHA])
				{
					alpha3->f_cache +=  						
						- ((alpha1->alpha_up - alpha1->alpha_dw) 
						- (a1 - a1a)) * Calc_Kernel( alpha1, alpha3, settings ) 
						- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
						* Calc_Kernel( alpha2, alpha3, settings ) ;
					index[alpha3-ALPHA] = 1 ;
				}
			}
			else
			{
				settings->bj_low[loop-1] = INT_MIN ;
				settings->ij_low[loop-1] = 0 ;
			}
			}
		}

		/*update f-cache of i1 & i2 if not in Io_Cache*/
		if (alpha1->setname_up != Io_a && alpha1->setname_dw != Io_b)
		{
			if (0==index[alpha1-ALPHA])
			{
				alpha1->f_cache = alpha1->f_cache - ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) * K11 
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) * K12 ;
				index[alpha1-ALPHA] = 1 ;
			}
			alpha3=alpha1 ;
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;

				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;

				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
		}
		if (alpha2->setname_up != Io_a && alpha2->setname_dw != Io_b)
		{
			if (0==index[alpha2-ALPHA])
			{
				alpha2->f_cache = alpha2->f_cache - ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) * K12
					- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) * K22 ;
				index[alpha2-ALPHA] = 1 ;
			}
			alpha3=alpha2 ;			
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;

				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;

				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
		}			

		/*/ update Fi in Io_Cache and vote B_LOW & B_UP if possible*/
		cache = Io_CACHE.front ;
		while ( NULL != cache )
		{	
			alpha3 = cache->alpha ;	
			if ( 0==index[alpha3-ALPHA])
			{
				alpha3->f_cache = alpha3->f_cache - ((alpha1->alpha_up - alpha1->alpha_dw) - (a1 - a1a)) 
				* Calc_Kernel( alpha1, alpha3, settings ) 
				- ((alpha2->alpha_up - alpha2->alpha_dw) - (a2 - a2a)) 
				* Calc_Kernel( alpha2, alpha3, settings ) ;
				index[alpha3-ALPHA] = 1 ;
			}
			
			if (alpha3->pair->target > 1 )
			{
				loop = alpha3->pair->target - 2 ;

				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_One)
				{
					if (alpha3->f_cache-1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache-1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_dw==Io_b || alpha3->setname_dw==I_Fou)
				{
					if (alpha3->f_cache-1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache-1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			if ( alpha3->pair->target < settings->pairs->classes )
			{
				loop = alpha3->pair->target - 1 ;
			
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Thr)
				{
					if (alpha3->f_cache+1<settings->bj_up[loop])
					{
						settings->bj_up[loop] = alpha3->f_cache+1 ;
						settings->ij_up[loop] = alpha3 - ALPHA + 1 ;
					}
				}
				if (alpha3->setname_up==Io_a || alpha3->setname_up==I_Two)
				{
					if (alpha3->f_cache+1>settings->bj_low[loop])
					{
						settings->bj_low[loop] = alpha3->f_cache+1 ;
						settings->ij_low[loop] = alpha3 - ALPHA + 1 ;
					}
				}
			}
			cache = cache->next ;				
		} /*/ end of while*/
		
		free(index) ;


		for (loop = 1 ; loop < settings->pairs->classes ; loop ++)
		{
			if (0==settings->ij_up[loop-1]||0==settings->ij_low[loop-1])
			{ 
				Check_Alphas ( ALPHA, settings ) ;
				loop = settings->pairs->classes ;
			}
		}

#ifdef _ORDINAL_DEBUG

		for ( t1 = 1; t1 <= settings->pairs->count; t1 ++ )
		{	
			alpha3 = ALPHA + t1 - 1 ;
			printf("%u-target %u---func %f: alpha = %f , alpha* = %f\n",t1, alpha3->pair->target, alpha3->f_cache, alpha3->alpha_up, alpha3->alpha_dw) ;
		}
		for (t1=1;t1<settings->pairs->classes;t1++)
			printf("threshold %u : upper=%f(%u), lower=%f(%u), mu=%f\n", t1, settings->bj_up[t1-1],
				settings->ij_up[t1-1], settings->bj_low[t1-1], settings->ij_low[t1-1], settings->mu[t1-1]) ;
		deltamu = 0 ;
		for (t1=0;t1<settings->pairs->count;t1++)
		{
			alpha1 = ALPHA+t1 ;
			for (t2=0;t2<t1;t2++)
			{
				alpha2 = ALPHA+t2 ;
				deltamu += (-alpha1->alpha_up+alpha1->alpha_dw)
					*(-alpha2->alpha_up+alpha2->alpha_dw)*Calc_Kernel( alpha1, alpha2, settings ) ;
			}
			deltamu += 0.5*(-alpha1->alpha_up+alpha1->alpha_dw)
					*(-alpha1->alpha_up+alpha1->alpha_dw)*Calc_Kernel( alpha1, alpha1, settings ) ;
			deltamu -= (alpha1->alpha_up+alpha1->alpha_dw) ;
		}
		printf("objective functional %f\n",deltamu) ;
#endif
	/*/ update mu_bias*/
	for (loop = 1; loop < settings->pairs->classes; loop ++)
	{
		settings->bmu_low[loop-1]=settings->bj_low[loop-1] ;
		settings->imu_low[loop-1]=loop ;
		if (loop>1)
		{	
			/*/ b_low^j=max{b_low^j-1,b_low^j}*/
			if (settings->bmu_low[loop-2]>settings->bmu_low[loop-1])
			{
				settings->bmu_low[loop-1]=settings->bmu_low[loop-2] ;
				settings->imu_low[loop-1]=settings->imu_low[loop-2] ;
			}
		}
	}
	for (loop = settings->pairs->classes-1; loop > 0; loop --)
	{
		settings->bmu_up[loop-1]=settings->bj_up[loop-1] ;
		settings->imu_up[loop-1]=loop ;
		if (loop<settings->pairs->classes-1)
		{
			/*/ b_up^j=min{b_up^j,b_up^j+1}*/
			if (settings->bmu_up[loop-1]>settings->bmu_up[loop])
			{
				settings->bmu_up[loop-1]=settings->bmu_up[loop] ;
				settings->imu_up[loop-1]=settings->imu_up[loop] ;
			}			
		}
	}
	for (loop = 2; loop < settings->pairs->classes; loop ++)
	{
		if (settings->mu[loop-1]>EPS*EPS) 
		{
			if (settings->bmu_up[loop-1]>settings->bmu_up[loop-2])
			{
				settings->bmu_up[loop-1]=settings->bmu_up[loop-2] ;
				settings->imu_up[loop-1]=settings->imu_up[loop-2] ;
			}
			if (settings->bmu_low[loop-2]<settings->bmu_low[loop-1])
			{
				settings->bmu_low[loop-2]=settings->bmu_low[loop-1] ;
				settings->imu_low[loop-2]=settings->imu_low[loop-1] ;
			}
		}
	}
#ifdef _ORDINAL_DEBUG
		for (t1=1;t1<settings->pairs->classes;t1++)
			printf("threshold %u : mu_up=%f(%u), mu_low=%f(%u), mu=%f\n", t1, settings->bmu_up[t1-1],
				settings->imu_up[t1-1], settings->bmu_low[t1-1], settings->imu_low[t1-1], settings->mu[t1-1]) ;
#endif
		return TRUE ;
	} /*/ end of update */
	else
	{
		/*/printf("fail to update pairs %lu and %lu\n",i1,i2) ; */
		return FALSE ;
	}
}

/*/ end of smoc_takestep.cpp*/

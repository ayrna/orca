#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include "smo.h"



BOOL svm_predict ( Data_List * testlist, smo_Settings * settings )
{	
	Data_List * trainlist ;
	Data_Node * trainnode ;
	Data_Node * testnode ;
	double fx, kernel, guess = 0 ;
	double error = 0 ;
	double alpha ;
	unsigned int i, j=0, k ;

	if (testlist == NULL || settings == NULL)
		return FALSE ;
	
	trainlist = settings->pairs ;

	if (TRUE == Is_Data_Empty(testlist))
		return FALSE ;	
	if (trainlist->dimen != testlist->dimen)
		return FALSE ;

	settings->c1p = 0 ;
	settings->c1n = 0 ;
	settings->c2p = 0 ;	
	settings->c2n = 0 ;		
	settings->svs = 0 ;

	i = 0 ;
	testnode = testlist->front ;
	while (testnode!=NULL)
	{ 
		fx = 0 ;

		if (TRUE == trainlist->normalized_input)
		{	
			for (k=0;k<trainlist->dimen;k++)
			{ 
				if ( 0 != trainlist->x_devi[k] )
					testnode->point[k] = (testnode->point[k]-trainlist->x_mean[k])/(trainlist->x_devi[k]) ;
				else
					testnode->point[k] = 0 ;
			}
		}
		trainnode = trainlist->front ;
		j = 0 ;
		while (trainnode!=NULL)
		{		

			alpha = 0 ;
			for (k=0;k<settings->pairs->classes-1;k++)
			{
				if ((ALPHA+j)->pair->target<=k+1)
					alpha -= (ALPHA+j)->alpha[k] ;
				else
					alpha += (ALPHA+j)->alpha[k] ;
			}
			if ( alpha != 0 )
			{
				kernel = Calculate_Kernel (trainnode->point, testnode->point, settings) ;				
				fx = fx + alpha * kernel ;
				if (i==0)
					settings->svs ++ ;
			}
			trainnode = trainnode->next ;
			j++ ;
		}
		testnode -> fx = fx ;
		testnode->guess = fx ;
		
		if ( ORDINAL == trainlist->datatype )
		{

			testnode->guess = 1 ;
			for (k=1;k<settings->pairs->classes;k++)
			{
				if (fx>settings->biasj[k-1])
					testnode->guess = k+1 ;
				else
					k = settings->pairs->classes ;
			}
			error += fabs(testnode->guess-testnode->target) ;
			if (fabs(testnode->guess-testnode->target)>0.5)
				guess += 1.0 ;
		}
		testnode = testnode->next ;
		i++ ;
	}
	if (i==testlist->count&&j==trainlist->count)
	{
		if ( ORDINAL == trainlist->datatype )
		{			
			settings->testrate = error/testlist->count ; 
			settings->testerror = guess/testlist->count ; 
		}
	}
	else
	{
		printf("Error in smo Prediction.\r\n") ;		
		settings->svs = 0 ;
		settings->testrate = 0 ;
		settings->testerror = 0 ;
	}	
	return TRUE ;
}


struct estructura svm_saveresults_Matlab(Data_List * testlist, smo_Settings * settings)
{

	Data_Node * testnode ;
	unsigned int i, result, k ;
	char buf[1000] = "" ;
	char * pstr ;
	double temp ;
	double alpha ;
	FILE * guess_file = NULL ;
	FILE * svmfunc = NULL ;
	FILE * svmalpha = NULL ;
	FILE * svmresu = NULL ;	
	FILE * testfunc = NULL ;
	FILE * svmweight = NULL ;


	struct estructura aux;

	/*if ((aux=(struct estructura*)malloc(nElem*sizeof(struct estructura))) == NULL)
	{
		printf("Error al reservar memoria\n");
		exit(-1);
	}*/
		

	/*for(i=0; i< nElem; i++)
	{*/	


		aux.dim2=testlist->count;
		aux.dim3=settings->pairs->count;
		aux.dim4= settings->pairs->classes - 1;
		aux.dim5=settings->pairs->count;

		if ( (aux.data2=(double *)malloc(testlist->count*sizeof(double))) == NULL)
		{
			printf("Error al reservar memoria\n");
			exit(-1);
		}


		if ( (aux.data3=(double *)malloc(settings->pairs->count*sizeof(double))) == NULL)
		{
			printf("Error al reservar memoria\n");
			exit(-1);
		}

		if ( (aux.data4=(double *)malloc(settings->pairs->classes*sizeof(double))) == NULL)
		{
			printf("Error al reservar memoria\n");
			exit(-1);
		}

		if ( (aux.data5=(double *)malloc(settings->pairs->count*sizeof(double))) == NULL)
		{
			printf("Error al reservar memoria\n");
			exit(-1);
		}

		
	//}


	/*
	if (testlist == NULL || settings == NULL)
		return FALSE ;
	
	if (TRUE == Is_Data_Empty(testlist))
		return FALSE ;	
	if (settings->pairs->dimen != testlist->dimen)
		return FALSE ;*/

//	strcpy (buf, INPUTFILE) ;
//	strcat (buf,".svm.conf") ;
	/*svmfunc = fopen( buf, "w+t" ) ;*/ 	
	/*printf("FUNCTION VALUES for training data have been saved in %s.\n",buf) ;*/
	//printf("FUNCTION VALUES for training data have been saved.\n");	

//	strcpy (buf, INPUTFILE) ;
//	strcat (buf,".svm.alpha") ;
	/*svmalpha = fopen( buf, "w+t" ) ;*/
	/*printf("ALPHAS and BIAS have been saved in %s.\n",buf) ;*/
	//printf("ALPHAS and BIAS have been saved.\n") ;		
	
//	strcpy (buf, INPUTFILE) ;
//	strcat (buf,".svm.resu") ;
	/*svmresu = fopen( buf, "w+t" ) ;*/
	/*printf("FUNCTION VALUES for training data have been saved in %s.\n",buf) ; */


//	if ((POLYNOMIAL==KERNEL && 1==P) || LINEAR==KERNEL )
//	{
//		strcpy (buf, INPUTFILE) ;
//		strcat (buf,".svm.weight") ;
//		svmweight = fopen( buf, "w+t" ) ;
//		printf("LINEAR WEIGHTS have been saved in %s.\n",buf) ;
//	}

	if (testlist != settings->pairs)
	{
	pstr = strstr( INPUTFILE, "train" ) ;
	if (NULL != pstr)
	{
		result = abs( INPUTFILE - pstr ) ;
		strncpy (buf, INPUTFILE, result ) ;
		buf[result] = '\0' ;
		strcat(buf, "cguess") ;
		strcat (buf, pstr+5) ;
	}
	else
	{
		strcpy (buf, INPUTFILE) ;
		strcat (buf,".test.resu") ;
	}
	/*guess_file = fopen( buf, "w+t" ) ;*/	
	/*printf("PREDICTIVE LABELS for test data have been saved in %s.\n",buf) ;*/
	//printf("PREDICTIVE LABELS for test data have been saved.\n");

	strcat(buf, ".svm.conf") ;
	/*testfunc = fopen( buf, "w+t" ) ;*/ 	
	/*printf("FUNCTION VALUES for test data have been saved in %s.\n",buf) ;*/
	//printf("FUNCTION VALUES for test data have been saved.\n");	

	/*save test results now*/
	i = 0 ;
	testnode = testlist->front ;


	while (testnode!=NULL)
	{ 
		/*if (NULL!=testfunc)
		{*/

			/*sprintf(buf,"%f\r", testnode->fx) ;*/
		
			/*printf("%f\r", testnode->fx) ;*/

			aux.data2[i]=testnode->fx;
	
			//printf("data2:%lf\r",aux.data2[i]);

			/*fwrite (buf, sizeof(char), strchr(buf,'\0')-buf, testfunc ) ;*/
			
			
		/*}		
		if (NULL!=guess_file)
		{*/
			/*sprintf(buf,"%.0f\r", testnode->guess) ;*/

			/*printf("%.0f\r", testnode->guess) ;*/

			/*fwrite (buf, sizeof(char), strchr(buf,'\0')-buf, guess_file );*/
			
		/*}*/			
		testnode=testnode->next ;
		i++ ;
	}

 /************************************************************/

	if (i!=testlist->count)
		printf("Error : in the data list for TESTING.\r\n") ;	
	}
				
	/*if ( NULL != svmalpha )	
	{*/
		//printf("\nALPHAS AND BIAS: SVM ALPHA\n");	

		for (i = 0; i < settings->pairs->count; i ++)
		{
			alpha = 0 ;
			for (k=0;k<settings->pairs->classes-1;k++)
			{
				if ((ALPHA+i)->pair->target<=k+1)
					alpha -= (ALPHA+i)->alpha[k] ;
				else
					alpha += (ALPHA+i)->alpha[k] ;
			}
			/*fprintf(svmalpha,"%.12f\r", alpha) ;*/
			aux.data3[i]=alpha;
			//printf("data3:%.12lf\r",aux.data3[i]);

		}

			for (i = 1; i < settings->pairs->classes; i ++){
			/*fprintf(svmalpha,"%.12f\r", settings->biasj[i-1]) ;*/
			/*printf("bias:%.12f\r", settings->biasj[i-1]);*/

			aux.data4[i-1]= settings->biasj[i-1];
			//printf("data4:%.12lf\r",aux.data4[i-1]);

		}
	/*}*/

	/********************************************************/


	/*if ( NULL != svmfunc )	
	{*/
	
	//printf("\nFunction values: TRAIN SVM CONF\n");


	for (i = 0; i < settings->pairs->count; i ++)
		{			
			(settings->alpha + i)->pair->guess = (settings->alpha + i)->f_cache ;	
			/*fprintf(svmfunc,"%.12f\r", fabs((settings->alpha + i)->pair->guess)) ;*/
			/*printf("%.12f\r", fabs((settings->alpha + i)->pair->guess)) ;*/

			aux.data5[i]= (settings->alpha + i)->pair->guess; // He quitado un fabs
			//printf("data5:%.12lf\r",aux.data5[i]);

		}
	/*}*/

	/********************************************************/

	temp = 0 ;
	/*if ( NULL != svmresu )	
	{*/
		for (i = 0; i < settings->pairs->count; i ++)
		{
			if (ORDINAL == settings->pairs->datatype)
			{
				(settings->alpha + i)->pair->guess = 1 ;
				for (k=1;k<settings->pairs->classes;k++)
				{
					if ((settings->alpha + i)->f_cache>settings->biasj[k-1])
						(settings->alpha + i)->pair->guess = k+1 ;
					else
						k = settings->pairs->classes ;
				}
				if ( fabs((settings->alpha + i)->pair->guess-(settings->alpha + i)->pair->target) >= 1.0 )
					temp += 1 ;
			}
			else
				printf("\nFATAL ERROR : the type is not ORDINAL REGRESSION.\n") ;
		}
		//printf("\nTraining Error %.0f\n", temp) ;
	/*}*/
/***********************************************************/

//	if ((POLYNOMIAL==KERNEL && 1==P) || LINEAR==KERNEL )
//	{
//		for (result=0;result<settings->pairs->dimen;result++)
//		{
//			temp=0 ;
//			for (i = 0; i < settings->pairs->count; i ++)
//			{
//				alpha = 0 ;
//				for (k=0;k<settings->pairs->classes-1;k++)
//				{
//					if ((ALPHA+i)->pair->target<=k+1)
//						alpha -= (ALPHA+i)->alpha[k] ;
//					else
//						alpha += (ALPHA+i)->alpha[k] ;
//				}				
//				temp += (settings->ard[result]) * alpha * (settings->alpha + i)->pair->point[result] ;
//			}
			/*fprintf(svmweight,"%.12f\r", temp) ;*/
//		}
//	}

/***********************************************************/
	if (NULL != guess_file)
		fclose(guess_file) ;
	if (NULL != svmresu)
		fclose(svmresu) ;
	if (NULL != svmalpha)
		fclose(svmalpha) ;
	if (NULL != svmfunc)
		fclose(svmfunc) ;
	if (NULL != testfunc)
		fclose(testfunc) ;
	if (NULL != svmweight)
		fclose(svmweight) ;
	
	return aux ;
}

/////////////////////////////////////////////
//////////////////////////////////////////////

BOOL svm_saveresults ( Data_List * testlist, smo_Settings * settings )
{
	Data_Node * testnode ;
	unsigned int i, result, k ;
	char buf[1000] = "" ;
	char * pstr ;
	double temp ;
	double alpha ;
	FILE * guess_file = NULL ;
	FILE * svmfunc = NULL ;
	FILE * svmalpha = NULL ;
	FILE * svmresu = NULL ;	
	FILE * testfunc = NULL ;
	FILE * svmweight = NULL ;
	
	if (testlist == NULL || settings == NULL)
		return FALSE ;
	
	if (TRUE == Is_Data_Empty(testlist))
		return FALSE ;	
	if (settings->pairs->dimen != testlist->dimen)
		return FALSE ;

	strcpy (buf, INPUTFILE) ;
	strcat (buf,".svm.conf") ;
	svmfunc = fopen( buf, "w+t" ) ; 	
	printf("FUNCTION VALUES for training data have been saved in %s.\n",buf) ;
	
	strcpy (buf, INPUTFILE) ;
	strcat (buf,".svm.alpha") ;
	svmalpha = fopen( buf, "w+t" ) ;
	printf("ALPHAS have been saved in %s.\n",buf) ;
	
	strcpy (buf, INPUTFILE) ;
	strcat (buf,".svm.resu") ;
	svmresu = fopen( buf, "w+t" ) ;
	//printf("FUNCTION VALUES for training data have been saved in %s.\n",buf) ;

	if ((POLYNOMIAL==KERNEL && 1==P) || LINEAR==KERNEL )
	{
		strcpy (buf, INPUTFILE) ;
		strcat (buf,".svm.weight") ;
		svmweight = fopen( buf, "w+t" ) ;
		printf("LINEAR WEIGHTS have been saved in %s.\n",buf) ;
	}

	if (testlist != settings->pairs)
	{
	pstr = strstr( INPUTFILE, "train" ) ;
	if (NULL != pstr)
	{
		result = abs( INPUTFILE - pstr ) ;
		strncpy (buf, INPUTFILE, result ) ;
		buf[result] = '\0' ;
		strcat(buf, "cguess") ;
		strcat (buf, pstr+5) ;
	}
	else
	{
		strcpy (buf, INPUTFILE) ;
		strcat (buf,".test.resu") ;
	}
	guess_file = fopen( buf, "w+t" ) ;	
	printf("PREDICTIVE LABELS for test data have been saved in %s.\n",buf) ;	
	strcat(buf, ".svm.conf") ;
	testfunc = fopen( buf, "w+t" ) ; 	
	printf("FUNCTION VALUES for test data have been saved in %s.\n",buf) ;
	
	//save test results now
	i = 0 ;
	testnode = testlist->front ;
	while (testnode!=NULL)
	{ 
		if (NULL!=testfunc)
		{
			sprintf(buf,"%f\r", testnode->fx) ;
			fwrite (buf, sizeof(char), strchr(buf,'\0')-buf, testfunc ) ;
		}		
		if (NULL!=guess_file)
		{
			sprintf(buf,"%.0f\r", testnode->guess) ;
			fwrite (buf, sizeof(char), strchr(buf,'\0')-buf, guess_file ) ;
		}			
		testnode=testnode->next ;
		i++ ;
	}
	if (i!=testlist->count)
		printf("Error : in the data list for TESTING.\r\n") ;	
	}
				
	if ( NULL != svmalpha )	
	{
		for (i = 0; i < settings->pairs->count; i ++)
		{
			alpha = 0 ;
			for (k=0;k<settings->pairs->classes-1;k++)
			{
				if ((ALPHA+i)->pair->target<=k+1)
					alpha -= (ALPHA+i)->alpha[k] ;
				else
					alpha += (ALPHA+i)->alpha[k] ;
			}
			fprintf(svmalpha,"%.12f\r", alpha) ;
		}
		for (i = 1; i < settings->pairs->classes; i ++)
			fprintf(svmalpha,"%.12f\r", settings->biasj[i-1]) ;
	}

	if ( NULL != svmfunc )	
	{
		for (i = 0; i < settings->pairs->count; i ++)
		{			
			(settings->alpha + i)->pair->guess = (settings->alpha + i)->f_cache ;	
			fprintf(svmfunc,"%.12f\r", (settings->alpha + i)->pair->guess) ; // He quitado un fabs
		}
	}

	temp = 0 ;
	if ( NULL != svmresu )	
	{
		for (i = 0; i < settings->pairs->count; i ++)
		{
			if (ORDINAL == settings->pairs->datatype)
			{
				(settings->alpha + i)->pair->guess = 1 ;
				for (k=1;k<settings->pairs->classes;k++)
				{
					if ((settings->alpha + i)->f_cache>settings->biasj[k-1])
						(settings->alpha + i)->pair->guess = k+1 ;
					else
						k = settings->pairs->classes ;
				}
				if ( fabs((settings->alpha + i)->pair->guess-(settings->alpha + i)->pair->target) >= 1.0 )
					temp += 1 ;
			}
			else
				printf("\nFATAL ERROR : the type is not ORDINAL REGRESSION.\n") ;
		}
		printf("\nTraining Error %.0f\n", temp) ;
	}

	if ((POLYNOMIAL==KERNEL && 1==P) || LINEAR==KERNEL )
	{
		for (result=0;result<settings->pairs->dimen;result++)
		{
			temp=0 ;
			for (i = 0; i < settings->pairs->count; i ++)
			{
				alpha = 0 ;
				for (k=0;k<settings->pairs->classes-1;k++)
				{
					if ((ALPHA+i)->pair->target<=k+1)
						alpha -= (ALPHA+i)->alpha[k] ;
					else
						alpha += (ALPHA+i)->alpha[k] ;
				}				
				temp += (settings->ard[result]) * alpha * (settings->alpha + i)->pair->point[result] ;
			}
			fprintf(svmweight,"%.12f\r", temp) ;
		}
	}
	if (NULL != guess_file)
		fclose(guess_file) ;
	if (NULL != svmresu)
		fclose(svmresu) ;
	if (NULL != svmalpha)
		fclose(svmalpha) ;
	if (NULL != svmfunc)
		fclose(svmfunc) ;
	if (NULL != testfunc)
		fclose(testfunc) ;
	if (NULL != svmweight)
		fclose(svmweight) ;
	return TRUE ;
}

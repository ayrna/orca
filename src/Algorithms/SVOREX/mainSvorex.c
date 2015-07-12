#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <limits.h>
#include <math.h>
#include <time.h>
#include "smo.h"

#include "mex.h"

#define VERSION (0)


/* mexFunction es la rutina de enlace con el código C. */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

   clock_t start;
   double trainTime=0;
   double testTime=0;

   if(nrhs != 7)
	{
        mexErrMsgTxt("Error. 7 parámetros requeridos => Train , Test , Ko , Co, Normalizar(1: SI, 0:NO), Salidas MexPrintf(1:SI, 0: NO), Kernel Polinómico(1: SI, 0:NO)");
	}
 
   def_Settings * defsetting = NULL ;
	smo_Settings * smosetting = NULL ;
	/*kcv_Settings * kcvsetting ;*/
	/*Data_Node * node ;*/

	/*char filename[1024] ;*/
	
	FILE * log ; 
	/*double * guess ;*/

   double ** matBien = NULL;
   double ** matTrain = NULL;
   double ** matTest = NULL;
   double * data1 = NULL;
	double * data6 =NULL;
	
	//struct estructura * ptr = NULL;	
	struct estructura e1;

   int aux,aux2;
   int m,n,contador,i,j;
	int nFil=0,nFil2=0,nCol=0,nCol2=0;
   double Ko=0, Co=0, Normalizar=0, salidasMexPrintf=0, kPolinomico=0;

	for (i = 0; i < nrhs; i++) /*nrhs: matrices de la parte derecha*/
	{
        
        if( i< 2)
        {
		
            /* Find the dimensions of the data */
            m = mxGetM(prhs[i]);/*numero filas*/ 
            n = mxGetN(prhs[i]);/*numero columnas*/
        				
            /*Reservo la matriz dinamica MatBien*/  
            matBien=(double **)calloc(m,sizeof(double *));
	
            for(aux=0; aux<m; aux++)
            {
                matBien[aux]=(double *)calloc(n,sizeof(double));
            }
             		
           	/* Retrieve the input data */
    			data1 = mxGetPr(prhs[i]); /*Pointer to the first element of the real data*/

     	   	        
            /*Recolocacion de la matriz*/
            contador=0;
            for(aux=0; aux< n; aux++)
            {
                for(aux2=0; aux2 < m; aux2++)
                {
                    matBien[aux2][aux]=data1[contador];
                    contador++;
                }
         
            }
               
            if(i==0)/*parametro cero: Matriz train*/
            {

				nFil=m;
				nCol=n;


                /*Reservo la matriz dinamica MatTrain*/  
                matTrain=(double **)calloc(m,sizeof(double *));
	
                for(aux=0; aux<m; aux++)
                {
                    matTrain[aux]=(double *)calloc(n,sizeof(double));
                } 
                
            
                /*ASIGNACION TRAIN Y COMPROBACION*/
                
                for(aux=0; aux<m; aux++)
                {
                    for(aux2=0; aux2<n; aux2++)			
                    {
                        matTrain[aux][aux2]=matBien[aux][aux2];
                        /*mexPrintf ("matTrain[%d][%d]=%lf\n",aux,aux2,matTrain[aux][aux2]);*/
                    }
                }
            
            }
            
            if(i==1)/*parametro uno: Matriz test*/
            {

				nFil2=m;
				nCol2=n;
              
                /*Reservo la matriz dinamica MatTest*/  
                matTest=(double **)calloc(m,sizeof(double *));
	
                for(aux=0; aux<m; aux++)
                {
                    matTest[aux]=(double *)calloc(n,sizeof(double));
                } 
                
            
                /*Asignacion test y comprobacion*/
                
                for(aux=0; aux<m; aux++)
                {
                    for(aux2=0; aux2<n; aux2++)			
                    {
                        matTest[aux][aux2]=matBien[aux][aux2];
                        /*mexPrintf ("matTest[%d][%d]=%lf\n",aux,aux2,matTest[aux][aux2]);*/
                    }
                }
            
            }   
              
        }
        
        
        if(i==2)/*parametro dos: K*/
        {
            data1 = mxGetPr(prhs[i]);
            Ko=data1[0];
        }

        if(i==3)/*parametro tres: Cs*/
        {
            data1 = mxGetPr(prhs[i]);
            Co=data1[0];
        }

		  if(i==4) /*Normalizacion*/
		  {
				data1 = mxGetPr(prhs[i]);
            Normalizar=data1[0]; 
		  }	

		  if(i==5) /*Salidas mexPrintf*/
		  {
				data1 = mxGetPr(prhs[i]);
            salidasMexPrintf=data1[0]; 
		  }	
			       
		 if(i==6)
		 {
				data1 = mxGetPr(prhs[i]);
            kPolinomico=data1[0]; 

		 }


	}
	
	/* compruebo que las dos matrices tenga el mismo numero de filas y columnas, sino paro */
//	if(nFil != nFil2 || nCol != nCol2)
	if(nCol != nCol2)
	{
		mexErrMsgTxt("El numero de columnas de las matrices de train y test debe ser el mismo.");
	}     

	if(salidasMexPrintf == 1) //Hemos activados los mexPrintf
	mexPrintf("\nSupport Vector Ordinal Regression Using K-fold Cross Validation v2.%d \n--- Chu Wei Copyright(C) 2003-2004\n\n", VERSION) ;

   defsetting = Create_def_SettingsMatlab(); 

	if(kPolinomico == 1)
	{

		defsetting->kernel = POLYNOMIAL ;

		if( Ko >= 1)
		{		

			defsetting->p = (unsigned int) Ko ;

			if(salidasMexPrintf == 1) //Hemos activados los mexPrintf	
			mexPrintf("  - choose Polynomial kernel with order %d.\n", defsetting->p) ;

			defsetting->def_lnK_start = 0 ;	
			defsetting->def_lnK_end = 0 ;
		}
	}
	else
	{

	   defsetting->kappa = (Ko) ;
		
		if(salidasMexPrintf == 1) //Hemos activados los mexPrintf
		mexPrintf("  - K at %f.\n", Ko) ;
	
		/*defsetting->vc = (Co) ;
	
		if(salidasMexPrintf == 1) //Hemos activados los mexPrintf
		mexPrintf("  - C at %f.\n", Co) ;*/
	}
        
   defsetting->vc = (Co) ;
	
	if(salidasMexPrintf == 1) //Hemos activados los mexPrintf
		mexPrintf("  - C at %f.\n", Co) ;       

	if(Normalizar == 1) //Hemos activado la normalización
	{
		defsetting->normalized_input = TRUE ;	
		defsetting->pairs.normalized_input = TRUE ;
	}   
	 
//	Update_def_Settings_Matlab(defsetting, nFil,nCol,matTrain,matTest); 
	Update_def_Settings_Matlab(defsetting, nFil,nCol,matTrain); 
	

	/* save validation output*/
	defsetting->lnC_start = log10(defsetting->vc) ;		 
	defsetting->lnC_end = log10(defsetting->vc) ;		
	defsetting->lnK_start = log10(defsetting->kappa) ;		 
	defsetting->lnK_end = log10(defsetting->kappa) ;
	defsetting->lnC_step = defsetting->lnC_step ;
	defsetting->lnK_step = defsetting->lnK_step ;		

	defsetting->training.count = defsetting->pairs.count ;		
	defsetting->training.front = defsetting->pairs.front ;		
	defsetting->training.rear = defsetting->pairs.rear ;
	defsetting->training.classes = defsetting->pairs.classes ;	
	defsetting->training.dimen = defsetting->pairs.dimen ;
	defsetting->training.featuretype = defsetting->pairs.featuretype ;
	defsetting->training.datatype = defsetting->pairs.datatype ;
		
	/* create smosettings*/
         	
	smosetting = Create_smo_Settings(defsetting) ; 
	smosetting->pairs = &defsetting->pairs ;  		
	defsetting->training.count = 0 ;		
	defsetting->training.front = NULL ;		
	defsetting->training.rear = NULL ;
	defsetting->training.featuretype = NULL ;
		
	/* load test data*/
//	if ( FALSE == smo_LoadMatrix(&(defsetting->testdata), defsetting->testfile, defsetting->pairs.dimen, nFil,nCol, matTest) )
	if ( FALSE == smo_LoadMatrix(&(defsetting->testdata), defsetting->testfile, defsetting->pairs.dimen, nFil2,nCol2, matTest) )
	{
		mexPrintf ("No testing data found in the file %s.\n", defsetting->testfile ) ;
		/*svm_saveresults (&defsetting->pairs, smosetting) ;*/		
	}
	/* calculate the test output*/
	else
	{
		//Training
   		start=clock();
		smo_routine (smosetting) ;
		trainTime= (clock()-start)/((double)CLOCKS_PER_SEC);
		//Test
   		start=clock();
		svm_predict (&defsetting->testdata, smosetting) ;		
		testTime= (clock()-start)/((double)CLOCKS_PER_SEC);
		e1=svm_saveresults_Matlab (&defsetting->testdata, smosetting) ;

		if(salidasMexPrintf == 1) //Hemos activados los mexPrintf
		{
			if (REGRESSION == smosetting->pairs->datatype)
				mexPrintf("\r\nTEST ASE %f, AAE %f and SVs %.0f at C=%f and Kappa=%f with %.3f seconds.\n", smosetting->testrate, smosetting->testerror, smosetting->svs, smosetting->vc, smosetting->kappa, smosetting->smo_timing) ;
			else if (ORDINAL == smosetting->pairs->datatype)
				mexPrintf ("\r\nTEST ERROR NUMBER %.0f, AAE %.0f and SVs %.0f, at C=%.3f Kappa=%.3f with %.3f seconds.\n", smosetting->testerror*defsetting->testdata.count,smosetting->testrate*defsetting->testdata.count, smosetting->svs, smosetting->vc, smosetting->kappa, smosetting->smo_timing) ;
			else
				mexPrintf ("\r\nTEST ERROR %f and SVs %.0f at C+=%f, C-=%f and Kappa=%f with %.3f seconds.\n", smosetting->testerror, smosetting->svs, smosetting->vc_p, smosetting->vc_n, smosetting->kappa, smosetting->smo_timing) ;
		}
/**************************************************************************************/
			/*if (NULL != (log = fopen ("kfoldsvc.log", "a+t")) ) 
			{
				if (REGRESSION == smosetting->pairs->datatype){
					fprintf(log,"%d-fold: TEST ASE %f, AAE %f and SVs %.0f at C=%f and Kappa=%f with %.3f seconds.\n", defsetting->kfold, smosetting->testrate, smosetting->testerror, smosetting->svs, smosetting->vc, smosetting->kappa, smosetting->smo_timing) ;
					mexPrintf("%d-fold: TEST ASE %f, AAE %f and SVs %.0f at C=%f and Kappa=%f with %.3f seconds.\n", defsetting->kfold, smosetting->testrate, smosetting->testerror, smosetting->svs, smosetting->vc, smosetting->kappa, smosetting->smo_timing) ;
}
				else if (ORDINAL == smosetting->pairs->datatype){
					fprintf (log,"TEST ERROR NUMBER %.0f, AAE %.0f and SVs %.0f, at C=%.3f Kappa=%.3f with %.3f seconds.\n", 
					smosetting->testerror*defsetting->testdata.count,smosetting->testrate*defsetting->testdata.count, smosetting->svs, smosetting->vc, smosetting->kappa, smosetting->smo_timing) ;
					mexPrintf ("TEST ERROR NUMBER %.0f, AAE %.0f and SVs %.0f, at C=%.3f Kappa=%.3f with %.3f seconds.\n", 
					smosetting->testerror*defsetting->testdata.count,smosetting->testrate*defsetting->testdata.count, smosetting->svs, smosetting->vc, smosetting->kappa, smosetting->smo_timing) ;

}
				else{
					fprintf(log,"%d-fold: TEST ERROR %f and SVs %.0f at C=%f, C+=%f, C-=%f and Kappa=%f with %.3f seconds.\n", defsetting->kfold, smosetting->testerror, smosetting->svs, smosetting->vc, smosetting->vc_p, smosetting->vc_n, smosetting->kappa, smosetting->smo_timing) ;		
				fclose(log) ;
					mexPrintf("%d-fold: TEST ERROR %f and SVs %.0f at C=%f, C+=%f, C-=%f and Kappa=%f with %.3f seconds.\n", defsetting->kfold, smosetting->testerror, smosetting->svs, smosetting->vc, smosetting->vc_p, smosetting->vc_n, smosetting->kappa, smosetting->smo_timing) ;		
				
}
			}*/


			/* write another log*/				
			if (REGRESSION == smosetting->pairs->datatype)
			{
				if (NULL != (log = fopen ("esvr.log", "a+t")) )
				{
					fprintf(log,"%f %f %f\n", smosetting->testerror, smosetting->testrate, defsetting->time) ;
					fclose(log) ;			
				}
			}
/*****************************************************************/
			/*else if (ORDINAL == smosetting->pairs->datatype)
			{
				if (NULL != (log = fopen ("ordinal_explicit.log", "a+t")) )
				{
					fprintf(log,"%.0f %.0f %f %f\n", smosetting->testerror*defsetting->testdata.count, smosetting->testrate*defsetting->testdata.count, smosetting->testrate, smosetting->smo_timing) ;
					fclose(log) ;                   
				}
			}*/
/*****************************************************************/
		}
		Clear_smo_Settings( smosetting ) ;
	
	/* free memory then exit */
	Clear_def_Settings( defsetting ) ;

	/*Devolución de valores*/

	for(i=0;i<6;i++)
	{

		if(i==0)
		{
			/* Create an mxArray for the output data */
   		plhs[i] = mxCreateDoubleMatrix(1, e1.dim2, mxREAL);
	
			/* Create a pointer to the output data*/ 
   		data6 = mxGetPr(plhs[i]);

			for(j=0; j< e1.dim2; j++)
			{
				data6[j] = e1.data2[j];	
			}
		}
	
		if(i==1)
		{
			/* Create an mxArray for the output data */
   		plhs[i] = mxCreateDoubleMatrix(1, e1.dim3, mxREAL);
	
			/* Create a pointer to the output data*/ 
   		data6 = mxGetPr(plhs[i]);

			for(j=0; j< e1.dim3; j++)
			{
				data6[j] = e1.data3[j];	
			}
		}
	
		if(i==2)
		{
			/* Create an mxArray for the output data */
   		plhs[i] = mxCreateDoubleMatrix(1, e1.dim4, mxREAL);
	
			/* Create a pointer to the output data*/ 
   		data6 = mxGetPr(plhs[i]);

			for(j=0; j< e1.dim4; j++)
			{
				data6[j] = e1.data4[j];	
			}
		}

		if(i==3)
		{
			/* Create an mxArray for the output data */
   		plhs[i] = mxCreateDoubleMatrix(1, e1.dim5, mxREAL);
	
			/* Create a pointer to the output data*/ 
   		data6 = mxGetPr(plhs[i]);

			for(j=0; j< e1.dim5; j++)
			{
				data6[j] = e1.data5[j];	
			}
		}
		if(i==4)
		{
			plhs[i] = mxCreateDoubleScalar(trainTime);

		}
		if(i==5)
		{
			plhs[i] = mxCreateDoubleScalar(testTime);

		}

}

	/*return 0;*/
}
/*end of mainmex.c*/ 



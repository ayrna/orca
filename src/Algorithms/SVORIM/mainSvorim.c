#include <stdio.h>
#include <stdlib.h>
#ifndef __MACH__
#include <malloc.h>
#endif
#include "smo.h"
#include <limits.h>
#include <math.h>
#include <string.h>
#include <time.h>

#include "mex.h"

#define VERSION (0)
#define DEBUG 0

/* mexFunction es la rutina de enlace con el código C. */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  clock_t start;
  double trainTime = 0;
  /*TEST REMOVED */
  /* double testTime=0; */

  /*TEST REMOVED if(nrhs != 7)
       {
       mexErrMsgTxt("Error. 7 parámetros requeridos => Train , Test , Ko , Co,
     Normalizar(1: SI, 0:NO), Salidas MexPrintf(1:SI, 0: NO), Kernel
     Polinómico(1: SI, 0:NO)");
       }*/

  if (nrhs != 6) {
    mexErrMsgTxt("Error. 6 parameters required => Train , Ko , Co, Normalize "
                 "(1: YES, 0:NO), MexPrintf Outputs (1:YES, 0: NO), Linear "
                 "kernel (1: YES, 0:NO)");
  }

  def_Settings *defsetting = NULL;
  smo_Settings *smosetting = NULL;
  /*kcv_Settings * kcvsetting ;*/
  /*Data_Node * node ;

  char filename[1024] ;
  

  FILE * log ;
  double * guess ;*/

  double **matBien = NULL;
  double **matTrain = NULL;
  double **matTest = NULL;
  double *data1 = NULL;
  double *data6 = NULL;

  // struct estructura * ptr = NULL;
  struct estructura e1;

  int aux, aux2;
  int m = -1, n = -1, contador, i, j;
  int nFil = 0, nFil2 = 0, nCol = 0, nCol2 = 0;
  double Ko = 0, Co = 0, Normalizar = 0, salidasMexPrintf = 0, kPolinomico = 0;

  /*TEST REMOVED
  if( i< 2)*/
  i = 0;

  /* Find the dimensions of the data */
  m = mxGetM(prhs[i]); /*numero filas*/
  n = mxGetN(prhs[i]); /*numero columnas*/

  /*Reservo la matriz dinamica MatBien*/
  matBien = (double **)calloc(m, sizeof(double *));

  for (aux = 0; aux < m; aux++) {
    matBien[aux] = (double *)calloc(n, sizeof(double));
  }

  /* Retrieve the input data */
  data1 = mxGetPr(prhs[i]); /*Pointer to the first element of the real data*/

  /*Recolocacion de la matriz*/
  contador = 0;
  for (aux = 0; aux < n; aux++) {
    for (aux2 = 0; aux2 < m; aux2++) {
      matBien[aux2][aux] = data1[contador];
      contador++;
    }
  }

  nFil = m;
  nCol = n;

  /*Reservo la matriz dinamica MatTrain*/
  matTrain = (double **)calloc(m, sizeof(double *));

  for (aux = 0; aux < m; aux++) {
    matTrain[aux] = (double *)calloc(n, sizeof(double));
  }

  /*ASIGNACION TRAIN Y COMPROBACION*/

  for (aux = 0; aux < m; aux++) {
    for (aux2 = 0; aux2 < n; aux2++) {
      matTrain[aux][aux2] = matBien[aux][aux2];
      /*mexPrintf ("matTrain[%d][%d]=%lf\n",aux,aux2,matTrain[aux][aux2]);*/
    }
  }

  /* TEST REMOVED if(i==2)*parametro dos: K*/
  i = 1;
  data1 = mxGetPr(prhs[i]);
  Ko = data1[0];

  /* TEST REMOVED if(i==3)*parametro tres: Cs*/
  i = 2;
  data1 = mxGetPr(prhs[i]);
  Co = data1[0];

  /* TEST REMOVED if(i==4) *Normalizacion*/
  i = 3;
  data1 = mxGetPr(prhs[i]);
  Normalizar = data1[0];

  /* TEST REMOVED if(i==5) *Salidas mexPrintf*/
  i = 4;
  data1 = mxGetPr(prhs[i]);
  salidasMexPrintf = data1[0];

  /* TEST REMOVED if(i==6)*/
  i = 5;
  data1 = mxGetPr(prhs[i]);
  kPolinomico = data1[0];

  /* TEST REMOVED Hack*/
  /* TODO: Is this for debuging? */
  nFil2 = 2;
  nCol2 = nCol;
  matTest = (double **)calloc(nFil2, sizeof(double *));
  for (aux = 0; aux < nFil2; aux++)
    matTest[aux] = (double *)calloc(nCol2, sizeof(double));
  for (aux = 0; aux < nFil2; aux++)
    for (aux2 = 0; aux2 < nCol2; aux2++)
      matTest[aux][aux2] = matTrain[aux][aux2];
  /* End Hack*/

  /* compruebo que las dos matrices tenga el mismo numero de filas y columnas,
   * sino paro */
  //	if(nFil != nFil2 || nCol != nCol2)
  if (nCol != nCol2) {
    mexErrMsgTxt("Number of columns of training and test must be the same");
  }

  if (salidasMexPrintf == 1) // Hemos activados los mexPrintf
    mexPrintf("\nSupport Vector Ordinal Regression Using K-fold Cross "
              "Validation v2.%d \n--- Chu Wei Copyright(C) 2003-2004\n\n",
              VERSION);

  defsetting = Create_def_Settings_Matlab();

  if (kPolinomico == 1) {

    defsetting->kernel = POLYNOMIAL;

    if (Ko >= 1) {

      defsetting->p = (unsigned int)Ko;

      if (salidasMexPrintf == 1) // Hemos activados los mexPrintf
        mexPrintf("  - choose Polynomial kernel with order %d.\n",
                  defsetting->p);

      defsetting->def_lnK_start = 0;
      defsetting->def_lnK_end = 0;
    }
  } else {

    defsetting->kappa = (Ko);

    if (salidasMexPrintf == 1) // Hemos activados los mexPrintf
      mexPrintf("  - K at %f.\n", Ko);

    /*defsetting->vc = (Co) ;


    if(salidasMexPrintf == 1) //Hemos activados los mexPrintf
    mexPrintf("  - C at %f.\n", Co) ;*/
  }

  defsetting->vc = (Co);

  if (salidasMexPrintf == 1) // Hemos activados los mexPrintf
    mexPrintf("  - C at %f.\n", Co);

  if (Normalizar == 1) // Hemos activado la normalización
  {
    defsetting->normalized_input = TRUE;
    defsetting->pairs.normalized_input = TRUE;
  }

  //	Update_def_Settings_Matlab(defsetting, nFil,nCol,matTrain,matTest);
  Update_def_Settings_Matlab(defsetting, nFil, nCol, matTrain);

  /* save validation output*/
  defsetting->lnC_start = log10(defsetting->vc);
  defsetting->lnC_end = log10(defsetting->vc);
  defsetting->lnK_start = log10(defsetting->kappa);
  defsetting->lnK_end = log10(defsetting->kappa);
  defsetting->lnC_step = defsetting->lnC_step;
  defsetting->lnK_step = defsetting->lnK_step;

  defsetting->training.count = defsetting->pairs.count;
  defsetting->training.front = defsetting->pairs.front;
  defsetting->training.rear = defsetting->pairs.rear;
  defsetting->training.classes = defsetting->pairs.classes;
  defsetting->training.dimen = defsetting->pairs.dimen;
  defsetting->training.featuretype = defsetting->pairs.featuretype;

  /* create smosettings*/
  // mexPrintf ("\n\nTESTING....\n", defsetting->testfile ) ;

  smosetting = Create_smo_Settings(defsetting);
  smosetting->pairs = &defsetting->pairs;
  defsetting->training.count = 0;
  defsetting->training.front = NULL;
  defsetting->training.rear = NULL;
  defsetting->training.featuretype = NULL;

  /* load test data*/
  #if 0
  if (FALSE ==
      smo_Loadfile_Matlab(&(defsetting->testdata), defsetting->testfile,
                          defsetting->pairs.dimen, nFil2, nCol2, matTest)) {
    mexPrintf("No testing data found in the file %s.\n", defsetting->testfile);
    /*svm_saveresults (&defsetting->pairs, smosetting) ;*/
  }
  #endif
  if (FALSE ) {

  }
  /* calculate the test output*/
  else {
    // Training
    start = clock();
    smo_routine(smosetting);
    trainTime = (clock() - start) / ((double)CLOCKS_PER_SEC);
    // Test
    start = clock();
    svm_predict(&defsetting->testdata, smosetting);
    e1 = svm_saveresults_Matlab(&defsetting->testdata, smosetting);
    /*testTime= (clock()-start)/((double)CLOCKS_PER_SEC);*/
    // e1=svm_saveresults_Matlab (&defsetting->testdata, smosetting) ;

    if (salidasMexPrintf == 1) {
      if (ORDINAL == smosetting->pairs->datatype)
        mexPrintf("\r\nTEST ERROR NUMBER %.0f, AAE %.0f and SVs %.0f, at "
                  "C=%.3f Kappa=%.3f with %.3f seconds.\r\n",
                  smosetting->testerror * defsetting->testdata.count,
                  smosetting->testrate * defsetting->testdata.count,
                  smosetting->svs, smosetting->vc, smosetting->kappa,
                  smosetting->smo_timing);
    }
  }
  Clear_smo_Settings(smosetting);

  /* free aux matrices */
  for (aux = 0; aux < m; aux++) {
    free(matBien[aux]);
    free(matTrain[aux]);
  }
  free(matBien);
  free(matTrain);

  for (aux = 0; aux < nFil2; aux++)
    free(matTest[aux]);
  free(matTest);

  /* free memory then exit*/
  Clear_def_Settings(defsetting);

  /*  Output variables */
  for (i=0; i<nlhs; i++) {
	if (i == 0) {
		/* Create an mxArray for the output data */
		plhs[i] = mxCreateDoubleMatrix(1, e1.n_alpha, mxREAL);

		/* Create a pointer to the output data*/
		data6 = mxGetPr(plhs[i]);

		for (j = 0; j < e1.n_alpha; j++) {
			data6[j] = e1.alpha[j];
		}
	}
	if (i == 1) {
		/* Create an mxArray for the output data */
		plhs[i] = mxCreateDoubleMatrix(1, e1.n_threshold, mxREAL);

		/* Create a pointer to the output data*/
		data6 = mxGetPr(plhs[i]);

		for (j = 0; j < e1.n_threshold; j++) {
			data6[j] = e1.biasj[j];
		}
	}

	if (i == 2) {
		/* Create an mxArray for the output data */
		plhs[i] = mxCreateDoubleMatrix(1, e1.n_pairs, mxREAL);
		/* Create a pointer to the output data*/
		data6 = mxGetPr(plhs[i]);

		for (j = 0; j < e1.n_pairs; j++) {
			data6[j] = e1.guess[j];
		}
	}

	if (i== 3) {
		plhs[i] = mxCreateDoubleScalar(trainTime);
	}
  }
}

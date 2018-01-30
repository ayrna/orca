#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <limits.h>
#include "smo.h"

BOOL smo_Loadfile_Matlab ( Data_List * pairs, char * inputfilename, int inputdim, int nFil, int nCol, double ** matrix) 
{ 

	int fila=0,columna=0;
	FILE * smo_stream ;
	FILE * smo_target = NULL ;
	char * pstr = NULL ;
	char buf[LENGTH] ;
	char * temp ;
	int dim = -2 ;
	unsigned long index = 1 ;
	unsigned int result, sz ;
	int var = 0, chg = 0 ;
	double * point = NULL ;
	unsigned int y ;
	int i = 0, j = 0 ;
	double mean = 0 ;
	double ymax = LONG_MIN ;
	double ymin = LONG_MAX ;
	double * xmean = NULL;
	Data_Node * node = NULL ;
	int t0=0, tr=0 ;
	FILE * fid ;

	Data_List label ;

	if ( NULL == pairs || NULL == inputfilename )
		return FALSE ;
	
	Clear_Data_List( pairs ) ;
	Create_Data_List( &label ) ;

	dim = nCol-1;


	if (NULL != pairs->filename) 
		free(pairs->filename) ;

	
	pairs->dimen = dim ;

	/*initialize the x_mean and x_devi in Data_List pairs*/

	if ( NULL == (pairs->x_mean = (double *)(malloc(dim*sizeof(double))) ) 
		|| NULL == (pairs->x_devi = (double *)(malloc(dim*sizeof(double))) ) 
		|| NULL == (xmean = (double *)(malloc(dim*sizeof(double))) ) )
	{		
		if (NULL != pairs->x_mean) 
			free(pairs->x_mean) ;
		if (NULL != pairs->x_devi) 
			free(pairs->x_devi) ;
		if (NULL != xmean)
			free(xmean) ;
		if (NULL != smo_target)
			fclose( smo_target ) ;
		if (NULL != smo_stream)
			fclose( smo_stream );
		return FALSE ;
	}
	for ( j = 0; j < dim; j ++ )
		pairs->x_mean[j] = 0 ;
	for ( j = 0; j < dim; j ++ )
		pairs->x_devi[j] = 0 ;
	for ( j = 0; j < dim; j ++ )
		xmean[j] = 0 ;

	/*/ begin to initialize data_list for digital input only*/
	//printf("\nLOADING.... \n") ;
	pairs->datatype = CLASSIFICATION ; 


	do
	{

#ifdef SMO_DEBUG 
		printf("%d\n", index) ;
		printf("%s\n\n\n", buf) ;
#endif
		point = (double *) malloc( (dim+1) * sizeof(double) ) ; /* Pairs to free them*/
		if ( NULL == point )
		{
			printf("not enough memory.\n") ;
			if (NULL != smo_target)
				fclose( smo_target ) ;
			if (NULL != smo_stream)
				fclose( smo_stream );
			if (NULL != pairs->x_mean) 
				free(pairs->x_mean) ;
			if (NULL != pairs->x_devi) 
				free(pairs->x_devi) ;
			if (NULL != xmean)
				free(xmean) ;
			Clear_Data_List( pairs ) ;
			return FALSE ;
		}

		columna=0;

		while( columna < dim )
		{

			point[columna]= matrix[fila][columna];

			columna++;

		}

		y = matrix[fila][columna];


		fila++;

		point[dim]=0 ;



						
			if ( TRUE == Add_Data_List( pairs, Create_Data_Node(index, point, y) ) )
			{

				pairs->mean = (mean * (((double)(pairs->count)) - 1) + y )/ ((double)(pairs->count))  ;
				pairs->deviation = pairs->deviation + (y-mean)*(y-mean) * ((double)(pairs->count)-1)/((double)(pairs->count));			
				mean = pairs->mean ;	
				for ( j=0; j<dim; j++ )
				{
					pairs->x_mean[j] = (xmean[j] * (((double)(pairs->count)) - 1) + point[j] )/ ((double)(pairs->count))  ;
					pairs->x_devi[j] = pairs->x_devi[j] + (point[j]-xmean[j])*(point[j]-xmean[j]) * ((double)(pairs->count)-1)/((double)(pairs->count));			
					xmean[j] = pairs->x_mean[j] ;
				}
				if (y>ymax)
				{ ymax = y ; pairs->i_ymax = index ;}
				if (y<ymin)
				{ ymin = y ; pairs->i_ymin = index ;}
				

				Add_Label_Data_List( &label, Create_Data_Node(index, point, y) ) ;
				index ++ ;
			}
			else
			{
#ifdef SMO_DEBUG 
				printf("%d\n", index) ;
				printf("duplicate data \n") ;
#endif
			}

	}
	while ( fila < nFil);


	if (label.count>=2||inputdim>0)
		pairs->datatype = ORDINAL ;
	else
	{
		printf("Warning : not a ordinal regression.\n") ;
		exit(1) ;
	}

	if (pairs->count < MINNUM || (pairs->datatype == UNKNOWN && inputdim == 0 ) ) 
	{
		printf("too few input pairs\n") ;
		Clear_Data_List( pairs ) ;
		if (NULL != pairs->x_mean) 
			free(pairs->x_mean) ;
		if (NULL != pairs->x_devi) 
			free(pairs->x_devi) ;
		if (NULL != xmean)
			free(xmean) ;
		if (NULL != smo_target)
			fclose( smo_target ) ;
		if (NULL != smo_stream)
			fclose( smo_stream );
		return FALSE ;
	}


	pairs->featuretype = (int *) malloc(pairs->dimen*sizeof(int)) ;
	if (NULL != pairs->featuretype)
	{

		for (sz=0;sz<pairs->dimen;sz++)
			pairs->featuretype[sz] = 0 ;
		
		if (0==inputdim)
			pstr = strstr( inputfilename, "train") ;	
		else
			pstr = strstr( inputfilename, "test") ;	
		if (NULL != pstr)
		{
			sz = abs( pstr - inputfilename ) ;
			pstr = strrchr( inputfilename, '.') ;	
			strncpy( buf, inputfilename, sz ) ;
			buf[sz]='\0' ;
			strcat( buf, "feature" ) ;			
			strcat( buf, pstr ) ;
			fid = fopen(buf,"r+t") ;
			if (NULL != fid)
			{
				printf("Loading the specifications of feature type in %s ...",buf) ;
				sz = 0 ;
				while (!feof(fid) && NULL!=fgets(buf,LENGTH,fid) )
				{
					i=strlen(buf) ;
					if (i>1)
					{
						if (sz>=pairs->dimen)
						{
							printf("Warning : feature type file is too long.\n") ;
							sz = pairs->dimen-1 ;
						}
						pairs->featuretype[sz] = atoi(buf) ;
						sz += 1 ;
					}
					else
						printf("Warning : blank line in feature type file.\n") ;
				}
				if (sz!=pairs->dimen)
				{

					for (sz=0;sz<pairs->dimen;sz++)
						pairs->featuretype[sz] = 0 ;
					printf(" RESET as default.\n") ;
				}
				else
					printf(" done.\n") ;
				fclose(fid) ;
			}
		}
	}

	pairs->deviation = sqrt( pairs->deviation / ((double)(pairs->count - 1.0)) ) ;
	for ( j=0; j<dim; j++ )
		pairs->x_devi[j] = sqrt( pairs->x_devi[j] / ((double)(pairs->count - 1.0)) ) ;	
	

	if ( UNKNOWN != pairs->datatype && 0 == inputdim )
	{
			pairs->deviation = 1.0 ;
			pairs->mean = 0 ;
			pairs->normalized_output = FALSE ;
	}

	for ( j=0; j<dim; j++ )
	{
		if (pairs->featuretype[j] != 0)
		{
			pairs->x_devi[j] = 1 ;
			pairs->x_mean[j] = 0 ;
		}
	}

	if (inputdim>0) 
	{
		pairs->normalized_output = FALSE ;
		pairs->normalized_input = FALSE ; 
	}


	node = pairs->front ;
	while ( node != NULL )
	{
		if ( TRUE == pairs->normalized_input )
		{
			for ( j=0; j<dim; j++ )
			{				
				if (pairs->x_devi[j]>0)
					node->point[j] = (node->point[j]-pairs->x_mean[j])/(pairs->x_devi[j]) ;
				else
					node->point[j] = 0 ;
			}
		}
		node = node->next ; 
	}
	//printf("Total %d samples with %d dimensions for ", (int)pairs->count, (int)pairs->dimen) ;	

	//if	(inputdim > 0)
		//printf("TESTING.\r\n") ;
	//else 
	if	(inputdim <= 0)	
	{
		if( CLASSIFICATION == pairs->datatype )
			printf("CLASSIFICATION.\r\n") ;
		else if ( ORDINAL == pairs->datatype )
		{
			//printf("ORDINAL %lu REGRESSION.\r\n",label.count) ;
			pairs->classes = label.count ;
			if (NULL != pairs->labels)
				free( pairs->labels ) ;
			i=0;
			pairs->labels = (unsigned int*)malloc(pairs->classes*sizeof(unsigned int)) ;
			pairs->labelnum = (unsigned int*)malloc(pairs->classes*sizeof(unsigned int)) ;
			if (NULL != pairs->labels&&NULL != pairs->labelnum)
			{
				node = label.front ;
				j=0 ;				
				//printf("ordinal varibles : ") ;
				while (NULL!=node)
				{
					if (node->target<1 || node->target>pairs->classes)
					{
						printf("Error : targets should be from 1 to %d.\n",(int)pairs->classes) ;
						exit(1) ;
					}
					pairs->labels[node->target-1] = node->target ;
					if (node->target-1==0)
						t0 = node->target ;
					if (node->target==(int)pairs->classes)
						tr = node->target ;
					pairs->labelnum[node->target-1] = node->fold ;
					i += node->fold ;
					//printf("%d(%d)  ", node->target, node->fold) ;
					node = node->next ;
				}
				//printf("\n") ;
				if (i!=(int)pairs->count||t0!=1||tr!=(int)pairs->classes)
				{
					printf("Error in data list.\n") ;
					exit(1) ;
				}
			}
			else
			{
				printf("fail to malloc for pairs->labels.\n") ;			
				exit(1) ;
			}
		}
		else 
			printf("UNKNOWN.\r\n") ;
	}
	if (1 == pairs->normalized_input)
		printf("Inputs are normalized.\r\n") ;
	
	if (1 == pairs->normalized_output && pairs->deviation > 0)
		printf("Outputs are normalized.\r\n") ;
	//if ( inputdim > 0 && pairs->deviation <= 0 )
	//	printf("Targets are not at hand.\r\n") ;

#ifdef _SOFTMAX_SERVER	
	pairs->classes = 3 ;
	pairs->labels[0] = 2 ;
	pairs->labelnum[0] = 0 ;
	pairs->labels[1] = 0 ;
	pairs->labelnum[1] = 0 ;
	pairs->labels[2] = 1 ;
	pairs->labelnum[2] = 0 ;
#endif

	Clear_Label_Data_List (&label) ;
	if (NULL != smo_target)
		fclose( smo_target ) ;
	if (NULL != smo_stream)
		fclose( smo_stream );
	if ( NULL != xmean )
		free( xmean ) ;
	return TRUE ;
}


/*******************************************************************************\

	BOOL smo_Loadfile ( Pairs * pairs, char * filename, unsigned int inputdim ) 
	
	load data file settings->inputfile, and create the data list Pairs 
	input:  the pointers to pairs and filename
	output: 0 or 1

\*******************************************************************************/

BOOL smo_Loadfile ( Data_List * pairs, char * inputfilename, int inputdim ) 
{ 

	FILE * smo_stream ;
	FILE * smo_target = NULL ;
	char * pstr = NULL ;
	char buf[LENGTH] ;
	char * temp ;
	int dim = -2 ;
	unsigned long index = 1 ;
	unsigned int result, sz ;
	int var = 0, chg = 0 ;
	double * point = NULL ;
	unsigned int y ;
	int i = 0, j = 0 ;
	double mean = 0 ;
	double ymax = LONG_MIN ;
	double ymin = LONG_MAX ;
	double * xmean = NULL;
	Data_Node * node = NULL ;
	int t0=0, tr=0 ;
	FILE * fid ;

	Data_List label ;

	if ( NULL == pairs || NULL == inputfilename )
		return FALSE ;
	
	Clear_Data_List( pairs ) ;
	Create_Data_List( &label ) ;

	if( (smo_stream = fopen( inputfilename, "r+t" )) == NULL )
	{
		//printf( "can not open the file %s.\n", inputfilename );
		return FALSE ;
	}
	
	// save file name 
	var = strlen( inputfilename ) ;
	if (NULL != pairs->filename) 
		free(pairs->filename) ;
	pairs->filename = (char*)malloc((var+1)*sizeof(char)) ;
	if (NULL == pairs->filename)
	{
		printf("fail to malloc for pairs->filename.\n") ;
		exit(0) ;
	}
	strncpy(pairs->filename,inputfilename,var) ;
	pairs->filename[var]='\0' ;

	// check the input dimension here

	if ( NULL == fgets( buf, LENGTH, smo_stream ))
	{
		printf( "fgets error in reading the first line.\n" );
		fclose( smo_stream );
		return FALSE ;
	}
	
	var = strlen( buf ) ;
	
	if (var >= LENGTH-1) 
	{
		printf( "the line is too long in the file %s.\n", inputfilename );
		fclose( smo_stream );
		return FALSE ;
	}
	
	if (0 < var)
	{		
		do 
		{
			dim = dim + 1 ;
			strtod( buf, &temp ) ;
			strcpy( buf, temp ) ;
			chg = var - strlen(buf) ;
			var = var - chg ;
		}
		while ( 0 != chg ) ;
	}
	else
	{ 
		fclose( smo_stream );
		printf("the first line in the file is empty.\n") ;
		return FALSE ;
	}

	if ( 0 > dim || (0 == dim && 0 == inputdim) ) 
	{
		fclose( smo_stream );

#ifdef SMO_DEBUG
		printf( "input dimension is less than one.\n") ;
#endif
		return FALSE ;
	}

	if (inputdim > 0)
	{
		if (inputdim == dim + 1 ) // test file without target
		{
			// try to open "*target*.*" as target
			// create target file name
			pstr = strstr( inputfilename , "test" ) ;
			if (NULL != pstr)
			{
				result = abs( inputfilename - pstr ) ;
				strncpy (buf, inputfilename, result ) ;
				buf[result] = '\0' ;
				strcat(buf, "targets") ;
				strcat (buf, pstr+4) ;
				smo_target = fopen( buf, "r+t" ) ;
			}
			dim = inputdim ;
			pairs->dimen = dim ;
		}
		else if ( inputdim != dim )
		{
			printf("Dimensionality in testdata is inconsistent with traindata.\n") ;
			return FALSE ;
		}
		else
			pairs->dimen = dim ;
	}
	else
		pairs->dimen = dim ;
	
	//initialize the x_mean and x_devi in Data_List pairs

	if ( NULL == (pairs->x_mean = (double *)(malloc(dim*sizeof(double))) ) 
		|| NULL == (pairs->x_devi = (double *)(malloc(dim*sizeof(double))) ) 
		|| NULL == (xmean = (double *)(malloc(dim*sizeof(double))) ) )
	{		
		if (NULL != pairs->x_mean) 
			free(pairs->x_mean) ;
		if (NULL != pairs->x_devi) 
			free(pairs->x_devi) ;
		if (NULL != xmean)
			free(xmean) ;
		if (NULL != smo_target)
			fclose( smo_target ) ;
		if (NULL != smo_stream)
			fclose( smo_stream );
		return FALSE ;
	}
	for ( j = 0; j < dim; j ++ )
		pairs->x_mean[j] = 0 ;
	for ( j = 0; j < dim; j ++ )
		pairs->x_devi[j] = 0 ;
	for ( j = 0; j < dim; j ++ )
		xmean[j] = 0 ;

	// begin to initialize data_list for digital input only
	printf("\nLoading %s ...  \n", inputfilename) ;
	pairs->datatype = CLASSIFICATION ; 

	rewind( smo_stream ) ;
	if (fgets( buf, LENGTH, smo_stream ) == NULL)
    {
        printf("\nError reading %s ...  \n", inputfilename) ;
        exit(1);
    }
	do
	{

#ifdef SMO_DEBUG 
		printf("%d\n", index) ;
		printf("%s\n\n\n", buf) ;
#endif
		point = (double *) malloc( (dim+1) * sizeof(double) ) ; // Pairs to free them
		if ( NULL == point )
		{
			printf("not enough memory.\n") ;
			if (NULL != smo_target)
				fclose( smo_target ) ;
			if (NULL != smo_stream)
				fclose( smo_stream );
			if (NULL != pairs->x_mean) 
				free(pairs->x_mean) ;
			if (NULL != pairs->x_devi) 
				free(pairs->x_devi) ;
			if (NULL != xmean)
				free(xmean) ;
			Clear_Data_List( pairs ) ;
			return FALSE ;
		}
		var = strlen( buf ) ;	
		i = 0 ;
		chg = dim ;

		while ( chg>0 && i<dim)
		{
			point[i] = strtod( buf, &temp ) ;
			i++ ;
			strcpy( buf, temp ) ;
			chg = var - strlen(buf) ;
			var = var - chg ;
		}
		point[dim]=0 ;
		if (i==dim && chg>0 && var>0)
			y = (unsigned int)strtod( buf, &temp ) ;
		else
		{
			free(point) ;
			y = 0 ;
			printf("Warning: the input file %s contains a blank or defective line.\n",inputfilename) ;
 			exit(1) ;
		}
		// load y as target from other file when dim+1
		if (NULL != smo_target)
		{
			if ( NULL != fgets( buf, LENGTH, smo_target ) )
			{
				var = strlen( buf ) ;
				y = (int)strtod( buf, &temp ) ;
				strcpy( buf, temp ) ;
				chg = var - strlen(buf) ;
				if (0==chg)
					printf("Warning: the target file contains a blank line.\n") ;
			}
			else
				printf("Warning: the target file is shorter than the input file.\n") ;
		}

		/*	for ( i = 0; i < dim; i ++ )
			{
				point[i] = strtod( buf, &temp ) ;
				strcpy( buf, temp ) ;
			}
			y = strtod( buf, &temp ) ;

			// load y as target from other file when dim+1
			if (NULL != smo_target)
			{
				fgets( buf, LENGTH, smo_target ) ;
				y = strtod( buf, &temp ) ;
			}*/

		if (chg>0) 
		{	
						
			if ( TRUE == Add_Data_List( pairs, Create_Data_Node(index, point, y) ) )
			{
				// update statistics
				pairs->mean = (mean * (((double)(pairs->count)) - 1) + y )/ ((double)(pairs->count))  ;
				pairs->deviation = pairs->deviation + (y-mean)*(y-mean) * ((double)(pairs->count)-1)/((double)(pairs->count));			
				mean = pairs->mean ;	
				for ( j=0; j<dim; j++ )
				{
					pairs->x_mean[j] = (xmean[j] * (((double)(pairs->count)) - 1) + point[j] )/ ((double)(pairs->count))  ;
					pairs->x_devi[j] = pairs->x_devi[j] + (point[j]-xmean[j])*(point[j]-xmean[j]) * ((double)(pairs->count)-1)/((double)(pairs->count));			
					xmean[j] = pairs->x_mean[j] ;
				}
				if (y>ymax)
				{ ymax = y ; pairs->i_ymax = index ;}
				if (y<ymin)
				{ ymin = y ; pairs->i_ymin = index ;}
				
				// check data type 
				Add_Label_Data_List( &label, Create_Data_Node(index, point, y) ) ;
				index ++ ;
			}
			else
			{
#ifdef SMO_DEBUG 
				printf("%d\n", index) ;
				printf("duplicate data \n") ;
#endif
			}
		}
	}
	while( !feof( smo_stream ) && NULL != fgets( buf, LENGTH, smo_stream ) ) ;

	if (label.count>=2||inputdim>0)
		pairs->datatype = ORDINAL ;
	else
	{
		printf("Warning : not a ordinal regression.\n") ;
		exit(1) ;
	}

	if (pairs->count < MINNUM || (pairs->datatype == UNKNOWN && inputdim == 0 ) ) 
	{
		printf("too few input pairs\n") ;
		Clear_Data_List( pairs ) ;
		if (NULL != pairs->x_mean) 
			free(pairs->x_mean) ;
		if (NULL != pairs->x_devi) 
			free(pairs->x_devi) ;
		if (NULL != xmean)
			free(xmean) ;
		if (NULL != smo_target)
			fclose( smo_target ) ;
		if (NULL != smo_stream)
			fclose( smo_stream );
		return FALSE ;
	}
	// load index file for feature types strstr

	pairs->featuretype = (int *) malloc(pairs->dimen*sizeof(int)) ;
	if (NULL != pairs->featuretype)
	{
		//default 0
		for (sz=0;sz<pairs->dimen;sz++)
			pairs->featuretype[sz] = 0 ;
		
		if (0==inputdim)
			pstr = strstr( inputfilename, "train") ;	// 46
		else
			pstr = strstr( inputfilename, "test") ;	// 46
		if (NULL != pstr)
		{
			sz = abs( pstr - inputfilename ) ;
			pstr = strrchr( inputfilename, '.') ;	// 46
			strncpy( buf, inputfilename, sz ) ;
			buf[sz]='\0' ;
			strcat( buf, "feature" ) ;			
			strcat( buf, pstr ) ;
			fid = fopen(buf,"r+t") ;
			if (NULL != fid)
			{
				printf("Loading the specifications of feature type in %s ...",buf) ;
				sz = 0 ;
				while (!feof(fid) && NULL!=fgets(buf,LENGTH,fid) )
				{
					i=strlen(buf) ;
					if (i>1)
					{
						if (sz>=pairs->dimen)
						{
							printf("Warning : feature type file is too long.\n") ;
							sz = pairs->dimen-1 ;
						}
						pairs->featuretype[sz] = atoi(buf) ;
						sz += 1 ;
					}
					else
						printf("Warning : blank line in feature type file.\n") ;
				}
				if (sz!=pairs->dimen)
				{
					//default 0
					for (sz=0;sz<pairs->dimen;sz++)
						pairs->featuretype[sz] = 0 ;
					printf(" RESET as default.\n") ;
				}
				else
					printf(" done.\n") ;
				fclose(fid) ;
			}
		}
	}

	pairs->deviation = sqrt( pairs->deviation / ((double)(pairs->count - 1.0)) ) ;
	for ( j=0; j<dim; j++ )
		pairs->x_devi[j] = sqrt( pairs->x_devi[j] / ((double)(pairs->count - 1.0)) ) ;	
	
	// set target value as +1 or -1, if data type is CLASSIFICATION
	if ( UNKNOWN != pairs->datatype && 0 == inputdim )
	{
			pairs->deviation = 1.0 ;
			pairs->mean = 0 ;
			pairs->normalized_output = FALSE ;
	}

	for ( j=0; j<dim; j++ )
	{
		if (pairs->featuretype[j] != 0)
		{
			pairs->x_devi[j] = 1 ;
			pairs->x_mean[j] = 0 ;
		}
	}

	if (inputdim>0) // do not normailize data for TESTING
	{
		pairs->normalized_output = FALSE ;
		pairs->normalized_input = FALSE ; 
	}

	// normalize the target if needed 
	node = pairs->front ;
	while ( node != NULL )
	{
		if ( TRUE == pairs->normalized_input )
		{
			for ( j=0; j<dim; j++ )
			{				
				if (pairs->x_devi[j]>0)
					node->point[j] = (node->point[j]-pairs->x_mean[j])/(pairs->x_devi[j]) ;
				else
					node->point[j] = 0 ;
			}
		}
		node = node->next ; 
	}
	printf("Total %d samples with %d dimensions for ", (int)pairs->count, (int)pairs->dimen) ;	

	if	(inputdim > 0)
		printf("TESTING.\r\n") ;
	else 
	{
		if( CLASSIFICATION == pairs->datatype )
			printf("CLASSIFICATION.\r\n") ;
		else if ( ORDINAL == pairs->datatype )
		{
			printf("ORDINAL %lu REGRESSION.\r\n",label.count) ;
			pairs->classes = label.count ;
			if (NULL != pairs->labels)
				free( pairs->labels ) ;
			i=0;
			pairs->labels = (unsigned int*)malloc(pairs->classes*sizeof(unsigned int)) ;
			pairs->labelnum = (unsigned int*)malloc(pairs->classes*sizeof(unsigned int)) ;
			if (NULL != pairs->labels&&NULL != pairs->labelnum)
			{
				node = label.front ;
				j=0 ;				
				printf("ordinal varibles : ") ;
				while (NULL!=node)
				{
					if (node->target<1 || node->target>pairs->classes)
					{
						printf("Error : targets should be from 1 to %d.\n",(int)pairs->classes) ;
						exit(1) ;
					}
					pairs->labels[node->target-1] = node->target ;
					if (node->target-1==0)
						t0 = node->target ;
					if (node->target==(int)pairs->classes)
						tr = node->target ;
					pairs->labelnum[node->target-1] = node->fold ;
					i += node->fold ;
					printf("%d(%d)  ", node->target, node->fold) ;
					node = node->next ;
				}
				printf("\n") ;
				if (i!=(int)pairs->count||t0!=1||tr!=(int)pairs->classes)
				{
					printf("Error in data list.\n") ;
					exit(1) ;
				}
			}
			else
			{
				printf("fail to malloc for pairs->labels.\n") ;			
				exit(1) ;
			}
		}
		else 
			printf("UNKNOWN.\r\n") ;
	}
	if (1 == pairs->normalized_input)
		printf("Inputs are normalized.\r\n") ;
	
	if (1 == pairs->normalized_output && pairs->deviation > 0)
		printf("Outputs are normalized.\r\n") ;
	if ( inputdim > 0 && pairs->deviation <= 0 )
		printf("Targets are not at hand.\r\n") ;

#ifdef _SOFTMAX_SERVER	
	pairs->classes = 3 ;
	pairs->labels[0] = 2 ;
	pairs->labelnum[0] = 0 ;
	pairs->labels[1] = 0 ;
	pairs->labelnum[1] = 0 ;
	pairs->labels[2] = 1 ;
	pairs->labelnum[2] = 0 ;
#endif

	Clear_Label_Data_List (&label) ;
	if (NULL != smo_target)
		fclose( smo_target ) ;
	if (NULL != smo_stream)
		fclose( smo_stream );
	if ( NULL != xmean )
		free( xmean ) ;
	return TRUE ;
}

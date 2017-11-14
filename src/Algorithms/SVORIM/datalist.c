/*******************************************************************************\

	datalist.cpp in Sequential Minimal Optimization ver2.0
		
	implements manipulation functions for data list.
		
	Chu Wei Copyright(C) National Univeristy of Singapore
	Create on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Update on Aug. 23 2001 

\*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "smo.h"


/*******************************************************************************\

	BOOL Create_Data_List ( Data_List * list ) 
	
	set all the elements in the list head to be the default values 
	input:  the pointer to the head of Data_List 
	output: TRUE or FALSE

\*******************************************************************************/

BOOL Create_Data_List ( Data_List * list ) 
{   
	if (NULL == list)
	{
		printf("\r\nFATAL ERROR : input pointer is NULL.\r\n") ;
		return FALSE ;
	}
	list->normalized_input = DEF_NORMALIZEINPUT ;
	list->normalized_output = DEF_NORMALIZETARGET ;

	list->datatype = CLASSIFICATION ;
	list->i_ymax = 0 ;
	list->i_ymin = 0 ;
	list -> count = 0 ;
	list -> dimen = 0 ;
	list -> mean = 0 ;
	list -> deviation = 0 ;
	list -> featuretype = NULL ;
	list -> x_devi = NULL ;
	list -> x_mean = NULL ;
	list -> front = NULL ;
	list -> rear = NULL ;
	list -> classes = 0 ;
	list -> filename = NULL ;
	list -> labelnum = NULL ;
	list -> labels = NULL ;
	
	return TRUE ;
}


Data_Node * Create_Data_Node ( long unsigned int index, double * point, unsigned int y )
{
	Data_Node * node = NULL ;

	if (NULL == point)
		return NULL ;
	
	node = (Data_Node *) malloc (sizeof(Data_Node)) ;
	
	if (NULL == node)
		printf ("fail to allocate memory!") ;
	else
	{

		index = 0 ;
		node -> count = 1 ;
		node -> guess = 0 ;
		node -> point = point ;
		node -> target = y ;
		node -> fx = 0 ; 
		node -> fold = 1 ;
		node -> next = NULL ;
	}
	return node ;
}


BOOL Is_Data_Empty ( Data_List * list )
{
	if (NULL == list) 
	{
		printf ("FATAL ERROR : Data_List has been abused.\n") ;
		return FALSE ;
	}
	if ((list -> front == NULL) && (list -> rear == NULL))
		return  TRUE ;
	else 
		return  FALSE;
}



int Is_Label_Node_Different ( Data_List * Pairs, Data_Node * node, Data_Node * temp )
{
	
	unsigned long int dimen = 0 ;
	
	if ( NULL == node || NULL == temp || NULL == Pairs )
		return 1 ;

	dimen = Pairs->dimen ;

	if ( node -> target != temp -> target )
		return 0 ;
	return 1 ;
}


int Add_Label_Data_List ( Data_List * list, Data_Node * node )
{
	
	Data_Node * temp = NULL ;

	if ( NULL == node )
	{
		return 1 ;
	}	

	if ( NULL == list )
	{
		free (node) ;
		return 1 ;
	}	
	else if (TRUE == Is_Data_Empty(list))
		list -> front = list -> rear = node ;	
	else
	{
		temp = list -> front ;

		while ( NULL != temp )
		{

			if ( 1 == Is_Label_Node_Different(list ,node, temp) )
			{
				temp->fold +=1 ;
				free (node) ;
				return 1 ;
			}
			temp = temp -> next ;
		}

		list -> rear -> next = node ;
		list -> rear = node ;
	}
	list -> count += 1 ;
	node->point = NULL ;
	return 0 ;
}


BOOL Is_Node_Different ( Data_List * Pairs, Data_Node * node, Data_Node * temp )
{
	
	unsigned long int dimen = 0 ;
	unsigned long int i = 0 ;
	
	if ( NULL == node || NULL == temp || NULL == Pairs )
		return FALSE ;

	dimen = Pairs->dimen ;

	if ( node -> target != temp -> target )
		return TRUE ;
	else
	{
		for ( i=0; i<dimen; i++ )
		{			
			if ( node->point[i] != temp->point[i] )
				return TRUE ;
		}
	}
	return FALSE ;
}


/*******************************************************************************\

	BOOL Add_Data_List ( Data_List * list, Data_Node * node ) 
	
	add Data_Node node into the list rear. 
	free * node if node exists already in the list.
	input:  the pointer to the head of Data_List, and a pointer of Data_Node 
	output: TRUE or FALSE

\*******************************************************************************/

BOOL Add_Data_List ( Data_List * list, Data_Node * node )
{
	


	if ( NULL == node )
	{
		printf("Error : input NULL pointer.\n") ;
		return FALSE ;
	}	

	if ( NULL == list )
	{
		printf("Error : input NULL pointer.\n") ;
		free (node) ;
		return FALSE ;
	}	
	else if (Is_Data_Empty(list))
	{	
		list -> front = list -> rear = node ;
	}
	else
	{

		list -> rear -> next = node ;
		list -> rear = node ;
	}
	list -> count += 1 ;
	return TRUE ;
}


BOOL Clear_Data_List ( Data_List * list )
{

	Data_Node * temp = NULL ;

	if (NULL == list)
		return FALSE ;

	while (!Is_Data_Empty(list))	
	{
		temp = list->front ;
	
		if (list -> rear == list -> front)
			list -> rear = list -> front = NULL ;
		else
			list -> front = list -> front -> next ;

		if (NULL != temp)
		{

#ifdef SMO_DEBUG
			printf ("delete %d\n", temp->index) ;
			printf ("%f\n", * temp->point) ;
			printf ("%f\n\n", temp->target) ;
#endif
			list->count -- ;
			free (temp->point) ;
			free (temp) ;
		}
		else 
		{
			printf ("Data list error\n") ;
			return FALSE ;
		}		
	}

#ifdef SMO_DEBUG

	if (0 != list->count)
	{
		printf ("Error happened in Data_List\n") ;
		list->count = 0 ;
		return FALSE ;
	}
	else

#endif
	{
		list -> dimen = 0 ;
		list->datatype = CLASSIFICATION ;
		list->i_ymax = 0 ;
		list->i_ymin = 0 ;
		list -> count = 0 ;
		list -> mean = 0 ;
		list -> deviation = 0 ;		
		list -> front = NULL ;
		list -> rear = NULL ;
		if ( NULL != list->x_mean )
		{
			free ( list->x_mean ) ;
			list->x_mean = NULL ;
		}
		if ( NULL != list->x_devi )
		{
			free ( list->x_devi ) ;
			list->x_devi = NULL ;
		}
		if ( NULL != list->featuretype)
		{
			free ( list->featuretype ) ;
			list->featuretype = NULL ;
		}
		if ( NULL != list->labels)
		{
			free ( list->labels ) ;
			list->labels = NULL ;
		}
		if ( NULL != list->labelnum)
		{
			free ( list->labelnum ) ;
			list->labelnum = NULL ;
		}
		if ( NULL != list->filename)
		{
			free ( list->filename ) ;
			list->filename = NULL ;
		}
	}
	return TRUE ;
}


BOOL Clear_Label_Data_List ( Data_List * list )
{

	Data_Node * temp = NULL ;

	if (NULL == list)
		return FALSE ;

	while (!Is_Data_Empty(list))	
	{
		temp = list->front ;
	
		if (list -> rear == list -> front)
			list -> rear = list -> front = NULL ;
		else
			list -> front = list -> front -> next ;

		if (NULL != temp)
		{

#ifdef SMO_DEBUG
			printf ("delete %d\n", temp->index) ;
			printf ("%f\n", * temp->point) ;
			printf ("%f\n\n", temp->target) ;
#endif
			list->count -- ;

			free (temp) ;
		}
		else 
		{
			printf ("Data list error\n") ;
			return FALSE ;
		}		
	}

#ifdef SMO_DEBUG

	if (0 != list->count)
	{
		printf ("Error happened in Data_List\n") ;
		list->count = 0 ;
		return FALSE ;
	}
	else

#endif
	{
		list -> dimen = 0 ;
		list->datatype = CLASSIFICATION ;
		list->i_ymax = 0 ;
		list->i_ymin = 0 ;
		list -> count = 0 ;
		list -> mean = 0 ;
		list -> deviation = 0 ;		
		list -> front = NULL ;
		list -> rear = NULL ;
		if ( NULL != list->x_mean )
		{
			free ( list->x_mean ) ;
			list->x_mean = NULL ;
		}
		if ( NULL != list->x_devi )
		{
			free ( list->x_devi ) ;
			list->x_devi = NULL ;
		}
		if ( NULL != list->featuretype)
		{
			free ( list->featuretype ) ;
			list->featuretype = NULL ;
		}
		if ( NULL != list->labels)
		{
			free ( list->labels ) ;
			list->labels = NULL ;
		}
		if ( NULL != list->labelnum)
		{
			free ( list->labelnum ) ;
			list->labelnum = NULL ;
		}
		if ( NULL != list->filename)
		{
			free ( list->filename ) ;
			list->filename = NULL ;
		}
	}
	return TRUE ;
}



/*******************************************************************************\

	cachelist.c in Sequential Minimal Optimization ver2.0
		
	implements manipulations for cache list.
		
	Chu Wei Copyright(C) National Univeristy of Singapore
	Create on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Update on Aug. 23 2001 

\*******************************************************************************/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "smo.h"

BOOL Create_Cache_List ( Cache_List * list ) 
{  
	if (NULL == list)
		return FALSE ;
	list -> count = 0 ;
	list -> front = NULL ;
	list -> rear = NULL ;
	return TRUE ;
}


BOOL Is_Cache_Empty ( Cache_List * list )
{
	if (NULL == list) 
	{
		printf ("Cache_List has been abused \n") ;
		return FALSE ;
	}
	if (list -> front == NULL)
		return  TRUE ;
	else 
		return  FALSE ;
}


BOOL Add_Cache_Node ( Cache_List * list, Alphas * alpha )
{
	Cache_Node * node = NULL ;

	if (NULL != alpha->cache)
	{
		printf ("alpha->cache is not NULL\n") ;
		return FALSE ;
	}

	node = (Cache_Node *) malloc (sizeof(Cache_Node)) ;
	if (NULL == node)
	{
		printf ("Fail to create Cache_Node, or alpha is wrong \n") ;
		return FALSE ;
	}

	node -> alpha = alpha ;
 	node -> previous = NULL ;
	node -> next = NULL ;

	if (NULL == list->front)
	{
		list -> front = node ;
		list -> rear = node ;
	}
	else
	{
		node -> next = list -> front ;
		list -> front -> previous = node ;
		list -> front = node ;
		node -> previous = NULL ;
	}
	
	list -> count ++ ;

	alpha -> cache = node ;

#ifdef SMO_DEBUG
	/*/printf ("Add index %d into Cache List\n", alpha->pair->index) ;*/
#endif

	return TRUE ;
}


/*******************************************************************************\

	BOOL Sort_Cache_Node ( Cache_List * list, Alphas * alpha )
	
	add alpha into cache list, the position is determined by alpha->Fi
	we guarantee the node is sorted by deceasing Fi.
	input:  the pointer to the head of Data_List 
	output: TRUE or FALSE

\*******************************************************************************/

BOOL Sort_Cache_Node ( Cache_List * list, Alphas * alpha )
{
	Cache_Node * node = NULL ;
	Cache_Node * cur = NULL ;
	/*/Cache_Node * temp = NULL ;*/
	double Fi = 0 ;
 
	if ( NULL == list || NULL ==alpha )
		return FALSE ;

	if (NULL != alpha->cache)
	{
		printf ("alpha->cache is not NULL\n") ;
		return FALSE ;
	}

	node = (Cache_Node *) malloc (sizeof(Cache_Node)) ;
	if (NULL == node)
	{
		printf ("Fail to create Cache_Node, or alpha is wrong \n") ;
		return FALSE ;
	}

	node -> alpha = alpha ;
 	node -> previous = NULL ;
	node -> next = NULL ;

	if ( NULL == list -> front )
	{
#ifdef SMO_DEBUG
		if ( NULL != list -> rear )
		{
			printf("\r\nfatal error in Cache_List.\r\n") ;
			return FALSE ;
		}
#endif
		list -> front = node ;
		list -> rear = node ;
	}
	else
	{	
		/*/ sorting the list by alpha->Fi*/
		cur = list->front ;
		Fi= cur->alpha->f_cache ;
		
		while ( NULL != cur &&  fabs(Fi) > fabs(alpha->f_cache) )
		{
			cur = cur->next ;
			if (NULL != cur)
				Fi = cur->alpha->f_cache ;
		}

		if ( NULL == cur )
		{
			/*/insert at tail*/
			list -> rear -> next = node ;
			node -> previous = list -> rear ;
			list -> rear = node ; 
		}
		else if ( NULL == cur -> previous )
		{
			/*/insert at head*/
#ifdef SMO_DEBUG
			if ( cur != list -> front )
			{
				printf("fatal error in Cache_List.") ;
				return FALSE ;
			}
#endif
			node -> next = cur ;
			list-> front ->previous = node ;
			list -> front = node ;
		}
		else
		{
			node -> next = cur ;
			node -> previous = cur->previous ;
			cur->previous->next = node ;
			cur->previous = node ;
		}
	}
	
	list -> count ++ ;
	/*/ add pointer into alpha list*/
	alpha -> cache = node ;

#ifdef SMO_DEBUG
	/*/printf ("\r\nAdd index %d into Cache List\r\n", alpha->pair->index) ;*/
#endif

	return TRUE ;
}



BOOL Del_Cache_Node ( Cache_List * list, Alphas * alpha )
{
	Cache_Node * node = NULL ;

	if (NULL == alpha->cache)
	{
		printf ("\r\nalpha->cache is NULL.\r\n") ;
		return FALSE ;
	}
	else 
		node = alpha->cache ;

	if (TRUE == Is_Cache_Empty (list) )
	{
		printf ("\r\nFatal Error in Del_Cache_Node: Cache_List is empty!\r\n") ;
		return FALSE ; 
	}

	if ( NULL != node->previous )  
	{
		node->previous->next = node->next ;
		if ( NULL != node->next ) 
			node->next->previous = node->previous ;
		else					
		{
			node->previous->next = NULL ;
			list->rear = node->previous ;
		}
	}
	else if ( NULL != node->next ) 
	{
		list->front = node->next ;
		node->next->previous = NULL ;
	}		
	else   
	{          
		list->front = NULL ;
		list->rear = NULL ;
	}

	list->count -- ;
	alpha->cache = NULL ;
	free (node) ;

#ifdef SMO_DEBUG
	/*printf("\r\nDelete index %d from Cache List\r\n", alpha->pair->index) ;*/
#endif

	return TRUE ;	
}


BOOL Clear_Cache_List ( Cache_List * list ) 
{

	Cache_Node * temp = NULL ;

#ifdef SMO_DEBUG
	if (NULL == list)
	{
		printf ("\r\nError : Cache_List is abused!\r\n") ;
		return FALSE ; 
	}
#endif
	
	while (NULL != list->front)	
	{
		temp = list->front ;
		list->front = temp->next ;
		list->count -- ;
		temp->alpha->cache = NULL ;
		
#ifdef SMO_DEBUG
		/*/printf ("\r\nDelete index %d in Cache_List\r\n", temp->alpha->pair->index) ;*/
#endif
	
		free(temp) ;
	}

	if ( 0 != list->count )
	{
		printf( "\r\nError happened in Clear_Cache_List!" ) ;
		list->count = 0 ;
		return FALSE ;
	}
	else
	{
		list->front = NULL ;
		list->rear = NULL ;
	}

	return TRUE ;
}

/*/ the end of cachelist.c*/

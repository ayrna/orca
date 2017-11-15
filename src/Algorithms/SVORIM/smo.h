/*******************************************************************************\

	smo.h in Sequential Minimal Optimization ver2.0 

	defines all MACROs and data structures for SMO algorithm.

	Chu Wei Copyright(C) National Univeristy of Singapore
	Created on Jan. 16 2000 at Control Lab of Mechanical Engineering 
	Updated on Aug. 23 2001 
	Updated on Jan. 22 2003 
	Updated on Oct. 06 2003 for imbalanced data 

\*******************************************************************************/

#ifdef  __cplusplus
extern "C" {
#endif

#ifndef _SMO_H
#define _SMO_H

/*#pragma pack(8) 

//#define _WIN_SIMU

//#define _ORDINAL_DEBUG*/

#ifdef _WIN_SIMU
#include <windows.h>
#else
typedef enum _BOOL 
{
	FALSE = 0 ,
	TRUE = 1 ,
} BOOL ;
#define min(a,b)        ((a) < (b) ? (a) : (b))
#define max(a,b)        ((a) > (b) ? (a) : (b))
#endif

#define MINNUM          (2)			
#define LENGTH          (307200)		 

struct estructura
{

	int dim2,dim3,dim4,dim5;
	double * data2;
	double * data3;
	double * data4;
	double * data5;

};

typedef enum _Set_Name
{
	Io_a=5 ,
	Io_b=6 ,
	I_One=1 ,
	I_Two=2 ,
	I_Fou=4 ,
	I_Thr=3 ,
	I_o=0 ,	

} Set_Name ;  

typedef enum _Data_Type
{
	REGRESSION = 2 ,
	CLASSIFICATION = 1 ,
	ORDINAL = 3 ,
	UNKNOWN = 0 ,

} Data_Type ;

typedef enum _Method_Name
{
	SMO_SKONE ,
	SMO_SKTWO ,

} Method_Name ;

typedef enum _Kernel_Name
{
	GAUSSIAN = 0 ,	
	POLYNOMIAL = 1 ,
	LINEAR = 2 ,

} Kernel_Name ;

typedef enum _Training_Method
{
	BAYESIAN = 1 ,
	SMOMERELY = 2 ,
	CROSSVALIDATION = 3 ,

} Training_Method ;

typedef struct _Data_Node 
{
	unsigned int count ;             
	int fold ;
	double * point ;                
	unsigned int target ;                 
	double guess ;					
	double fx ;
	struct _Data_Node * next ;      

} Data_Node ;

typedef struct _Data_List 
{
	Data_Type datatype ;            
	BOOL normalized_input ;			 
	BOOL normalized_output ;		
	unsigned long int count ;       
	unsigned long int dimen ;            	
	unsigned int i_ymax ;
	unsigned int i_ymin ;
	unsigned int classes ;
	char * filename ;
	unsigned int * labels ;
	unsigned int * labelnum ;

	double mean ;                   
	double deviation ;              	
	int * featuretype ;					
	double * x_mean ;				
	double * x_devi ;				
	Data_Node * front ;          
	Data_Node * rear ;             

} Data_List ;

typedef struct _Cache_Node
{
	double new_Fi ;
	struct _Alphas * alpha ;
	struct _Cache_Node * previous ;
	struct _Cache_Node * next ;

} Cache_Node ;

typedef struct _Cache_List 
{
	long unsigned int count ;
	Cache_Node * front ;
	Cache_Node * rear ;
	
} Cache_List ;

typedef struct _Alphas
{
	double * alpha ;
	double f_cache ;					 
	double * kernel ;					

	Data_Node * pair ;					
	Cache_Node * cache ;				
	Set_Name * setname ;				

} Alphas ;


typedef struct _smo_Settings
{
	double vc ;                     
	double tol ;                   
	double eps ;					
	double duration ;               
	double * ard ;

	Kernel_Name kernel ;            
	unsigned int p ;               
	double kappa ;					

	struct _Alphas * alpha ;		
	struct _Cache_List io_cache ;	
	struct _Data_List * pairs ;		
	
	Method_Name method ;        

	long unsigned int * ij_low ;      
	long unsigned int * ij_up ;      
	double * bj_low ;               
	double * bj_up ;                 
	double * biasj ;
	
	BOOL smo_display ;			
	BOOL smo_working ;			
	double smo_timing ;			
	char * inputfile ;			
	char * dumpingfile ;		

	unsigned long int cache_size ;  
	BOOL cacheall ;
	BOOL ardon ;
	

	double testerror ;
	double testrate ;
	double c1p ;
	double c2p ;
	double c1n ;
	double c2n ;
	double svs ;

	int index ;			
	BOOL abort ;		
	BOOL smo_balance ;	

} smo_Settings ;


typedef struct _def_Settings
{
	double vc ;                    
	double tol ;                    
	double eps ;                   
	
	Kernel_Name kernel ;            
	double kappa ;                  
	unsigned int p ;                

	Method_Name method ;            
	BOOL smo_display ;
	BOOL smo_balance ;
	BOOL ardon ;

	unsigned int index ;
	unsigned int loops ;
	unsigned int seeds ;
	unsigned int kfold ;       
	unsigned int repeat ;      
	unsigned long int cache_size ;  

	double lnC_start ;
	double lnC_end ;
	double lnC_step ;
	double lnK_start ;
	double lnK_end ;
	double lnK_step ;	
	double best_rate ;

	double def_lnC_start ;
	double def_lnC_end ;
	double def_lnC_step ;
	double def_lnK_start ;
	double def_lnK_end ;
	double def_lnK_step ;
	double zoomin ;
	double time ;
	
	char * inputfile ;              
	char * testfile ;               
	struct _Data_List pairs ;		
	struct _Data_List training ;
	struct _Data_List validation ;
	struct _Data_List testdata ;		
	
	BOOL normalized_input ;			
	BOOL normalized_output ;		

	Training_Method trainmethod ;	

} def_Settings ;


typedef struct _kcv_Settings
{
	double lnC_start ;
	double lnC_end ;
	double lnC_step ;
	double lnK_start ;
	double lnK_end ;
	double lnK_step ;

	unsigned int C_steps ;
	unsigned int K_steps ;

	double * lnC ;                
	double * lnK ;               

	unsigned int kfold ;         
	unsigned int ranks ;
	
	Data_Node ** nodelist ;
	Data_Node *** pointernode ;
	unsigned int ** cvfold ;
	
	double * cv_error ;           
	double * cv_mean ;            
	double * cv_variance ;        
	double * cv_svs ;             
	double * cv_lnC ;            
	double * cv_lnK ;             

	double * final_error ;          
	double * final_mean ;            
	double * final_variance ;       
	
	double * final_var_error ;          
	double * final_var_mean ;          
	double * final_var_variance ;        

	double best_lnC ;
	double best_lnK ;	
	double best_rate ;

	double time ;                 
	unsigned int index ;

} kcv_Settings ;

#define SMO_WORKING    (settings->smo_working) 
#define SMO_DISPLAY    (settings->smo_display) 
#define EPS            (settings->eps) 
#define TOL            (settings->tol) 
#define EPSILON        (settings->epsilon) 
#define BETA           (settings->beta) 
#define VC             (settings->vc) 
#define VCP            (settings->vc_p)
#define VCN            (settings->vc_n)
#define KAPPA          (settings->kappa) 
#define P              (settings->p) 
#define METHOD         (settings->method) 
#define KERNEL         (settings->kernel) 
#define I_LOW          (settings->i_low) 
#define I_UP           (settings->i_up) 
#define B_LOW          (settings->b_low) 
#define B_UP           (settings->b_up) 
#define BIAS		   (settings->bias)
#define INDEX          (settings->index)
#define DURATION       (settings->duration) 
#define Io_CACHE       (settings->io_cache) 
#define ALPHA          (settings->alpha)
#define INPUTFILE      (settings->inputfile) 
#define TESTFILE       (settings->testfile) 
#define DUMPINGFILE    (settings->dumpingfile)
#define TRAINMETHOD    (settings->trainmethod)
#define KFOLD          (settings->kfold) 
#define ARDON          (settings->ardon) 

/* default settings*/
#define DEF_EPS          (0.000001)
#define DEF_TOL          (0.001) 
#define DEF_EPSILON      (0.1)
#define DEF_BETA         (0) 
#define DEF_VC           (1.0)
#define DEF_KAPPA        (1.0) 
#define DEF_P            (1) 
#define DEF_KERNEL       (GAUSSIAN)
#define DEF_METHOD       (SMO_SKTWO) 
#define DEF_DISPLAY      (FALSE)
#define DEF_ARDON		 (FALSE)
#define DEF_NORMALIZEINPUT    (FALSE)
#define DEF_NORMALIZETARGET   (FALSE)
#define DEF_SUPERLNC		  (2)	
#define DEF_INFERLNC		  (-1) 
#define DEF_SUPERLNK     (1)
#define DEF_INFERLNK     (-2)
#define DEF_TRAINING	 (CROSSVALIDATION)
#define DEF_KFOLD	     (5)
#define DEF_COARSESTEP   (0.5)
#define DEF_REFINESTEP   (0.1)
#define DEF_CACHE        (5000)
#define DEF_ZOOMIN       (5)
#define DEF_REPEAT       (1) 
#define DEF_LOOP         (2)
#define DEF_BALANCE      (FALSE)


def_Settings * Create_def_Settings ( char * filename );
def_Settings * Create_def_Settings_Matlab ( void );
void Clear_def_Settings( def_Settings * settings ) ;
//BOOL Update_def_Settings_Matlab( def_Settings * defsetting, int nFil, int nCol, double ** train,double ** test );
BOOL Update_def_Settings_Matlab( def_Settings * defsetting, int nFil, int nCol, double ** train);
BOOL Update_def_Settings( def_Settings * defsetting );



BOOL Create_Data_List ( Data_List * list ) ;
BOOL Is_Data_Empty ( Data_List * list ) ;
BOOL Clear_Data_List ( Data_List * list ) ;
BOOL Add_Data_List ( Data_List * list, Data_Node * node ) ;
Data_Node * Create_Data_Node ( long unsigned int index, double * point, unsigned int y ) ;
BOOL Clear_Label_Data_List ( Data_List * list ) ;

/*	load data file settings->inputfile, and create the data list Pairs 
//BOOL smo_Loadfile ( Data_List * , char * , int ) ;*/
BOOL smo_Loadfile_Matlab ( Data_List * pairs, char * inputfilename, int inputdim, int nFil, int nCol, double ** matrix);
BOOL smo_Loadfile ( Data_List * pairs, char * inputfilename, int inputdim );  


/*create and initialize the smo_Settings structure from def_Settings*/
smo_Settings * Create_smo_Settings ( def_Settings * settings ) ;
void Clear_smo_Settings( smo_Settings * settings ) ;

/* cache, a doubly linked list*/
BOOL Create_Cache_List( Cache_List * ) ;
BOOL Clear_Cache_List( Cache_List * ) ;
BOOL Is_Cache_Empty( Cache_List * ) ;
BOOL Add_Cache_Node( Cache_List *, Alphas * ) ;
BOOL Sort_Cache_Node( Cache_List *, Alphas * ) ;
BOOL Del_Cache_Node( Cache_List *, Alphas * ) ; 

/* create Alpha Matrix*/
Alphas * Create_Alphas( smo_Settings * ) ;
BOOL Clean_Alphas ( Alphas *, smo_Settings * ) ;
BOOL Check_Alphas ( Alphas *, smo_Settings * ) ;
BOOL Clear_Alphas ( smo_Settings * ) ;

/* calculate kerenl*/
double Calc_Kernel( Alphas * , Alphas * , smo_Settings * ) ;
double Calculate_Kernel( double * , double * , smo_Settings * ) ;
double Calculate_Ordinal_Fi ( long unsigned int i, smo_Settings * settings ) ;

/* get label*/
Set_Name Get_Ordinal_Label ( Alphas * , unsigned int, smo_Settings * settings) ;
int Add_Label_Data_List ( Data_List * list, Data_Node * node ) ;

/* compute Fi*/
double Calculate_Ordinal_Fi( long unsigned int, smo_Settings * ) ;

/* check the data in the cache*/
BOOL Is_Io ( Alphas * alpha, smo_Settings * settings ) ;
BOOL smo_routine ( smo_Settings * settings ) ;
BOOL svm_predict ( Data_List * test, smo_Settings * settings ) ;

kcv_Settings * Create_Kcv ( def_Settings * settings ) ;
BOOL Init_Kcv ( kcv_Settings * settings, def_Settings * defsetting ) ;
BOOL Clear_Kcv ( kcv_Settings * settings) ;
/*BOOL svm_saveresults ( Data_List * testlist, smo_Settings * settings ) ;*/
BOOL svm_saveresults ( Data_List * testlist, smo_Settings * settings );

struct estructura svm_saveresults_Matlab(Data_List * testlist, smo_Settings * settings);

BOOL Rehearsal_Kcv ( kcv_Settings * kcvsetting, def_Settings * defsetting ) ;

BOOL ordinal_takestep ( Alphas * alpha1, Alphas * alpha2, unsigned int threshold, smo_Settings * settings ) ;
Set_Name Get_Ordinal_Label ( Alphas * alpha, unsigned int j, smo_Settings * settings) ;

/*timing routines*/
void tstart(void) ;
void tend(void) ;
double tval() ;

#endif

#ifdef  __cplusplus
}
#endif


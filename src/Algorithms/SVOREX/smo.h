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

/*#pragma pack(8)*/ 

/*#define _ORDINAL_DEBUG*/

#ifdef _WIN32_SIMU
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

#define MINNUM          (2)			/* at least two*/
#define LENGTH          (307200)		/* maximum value of line length in data file */

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
	long unsigned int index ;       /* line number in data file loaded*/	
	unsigned int count ;            /*/ counter for the sample  */
	int fold ;
	double * point ;                /*/ point to one input point*/
	unsigned int target ;                 /*/ output*/
	double guess ;					/*/ our guess in training or prediction*/
	double fx ;
	struct _Data_Node * next ;      /*/ point to next node in the list*/

} Data_Node ;

typedef struct _Data_List 
{
	Data_Type datatype ;            /*/ regression problem or classification*/
	BOOL normalized_input ;			/*/ point data_node normalized or not */
	BOOL normalized_output ;		/*/ target data_node normalized or not */
	unsigned long int count ;       /*/ total number of samples */
	unsigned int dimen ;            /*/ dimension of input vector	*/
	unsigned int i_ymax ;
	unsigned int i_ymin ;
	unsigned int classes ;
	char * filename ;
	unsigned int * labels ;
	unsigned int * labelnum ;

	double mean ;                   /*/ mean of output*/
	double deviation ;              /*/ deviation of output*/	
	int * featuretype ;				/*/ mean of input	*/
	double * x_mean ;				/*/ mean of input*/
	double * x_devi ;				/*/ standard deviation of input*/
	Data_Node * front ;             /*/ point to first node in the list*/
	Data_Node * rear ;              /*/ point to last node in the list*/

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
	double alpha ;
	double alpha_up ;               /*/ ai for input point */
	double alpha_dw ;               /*/ ai' for input point */
	double f_cache ;                /*/ save Fi here if the pair is in Set Io */
	double * kernel ;               /*/ diagonal entry */
	/*/BOOL kernel_cache ;             // in kernel cache or not*/
	/*/unsigned int cache_offset ;     // the offset in kernel cache matrix*/
	/*/unsigned long int update_count ;// the count for entering the takestep*/
	Data_Node * pair ;              /*/ point to the corresponding pair */
	Cache_Node * cache ;            /*/ point to the Node in Cache List */
	/*/Set_Name setname ;				// Set Name */
	Set_Name setname_up ;           /*/ Set Name for ORDINAL*/ 
	Set_Name setname_dw ;              

} Alphas ;


typedef struct _smo_Settings
{
	double vc ;                     /*/ Regularization Parameter*/
	
	/*/ introduce for imbalanced datasets*/
	double vc_p ;                   /*/ C for positive labelled samples*/
	double vc_n ;                   /*/ C for negative labelled samples*/

	double epsilon ;                /*/ Epsilon insensitive Loss Function*/
	double beta ;					/*/ Soft Insensitive Loss Function	*/
	double tol ;                    /*/ Tolerance Parameter in Loose KKT */
	double eps ;					/*/ Error Precision Setting*/
	double duration ;               /*/ clock time passed*/
	double * ard ;

	Kernel_Name kernel ;            /*/ Kernel Type*/
	unsigned int p ;                /*/ Polynomial Power*/
	double kappa ;					/*/ Sigma square is Gaussian kernel	*/

	struct _Alphas * alpha ;		/*/ Pointers to Alphas matrix */
	struct _Cache_List io_cache ;	/*/ Head of Cache List*/
	struct _Data_List * pairs ;		/*/ this is a reference from def_Settings*/
	
	Method_Name method ;            /*/ Heuristic Methods */

	long unsigned int * ij_low ;       /*/ index of Bias_low*/
	long unsigned int * ij_up ;        /*/ index of Bias_up*/
	double * bj_low ;                  /*/ inf of bias*/
	double * bj_up ;                   /*/ sup of bias 	*/
	double * biasj ;
	double * mu ;
	double * bmu_low ;                  /*/ inf of bias*/
	double * bmu_up ;                   /*/ sup of bias 	*/
	long unsigned int * imu_low ;                  /*/ inf of bias*/
	long unsigned int * imu_up ;                   /*/ sup of bias 	*/
	
	long unsigned int i_low ;       /*/ index of Bias_low*/
	long unsigned int i_up ;        /*/ index of Bias_up*/
	double b_low ;                  /*/ inf of bias*/
	double b_up ;                   /*/ sup of bias 	*/
	double bias ;
	
	BOOL smo_display ;				/*/ display message on screen if TRUE*/
	BOOL smo_working ;				/*/ flag of active*/
	double smo_timing ;				/*/ CPU time consumed by the routine*/
	char * inputfile ;				/*/ the name of input data file */
	char * dumpingfile ;			/*/ the name of dumping file */

	unsigned long int cache_size ;  /*/ the size of kernel cache*/ 
	BOOL cacheall ;
	BOOL ardon ;
	/*/double ** kernel_cache ;*/
	/*/unsigned long int cur_cache ;*/
	double testerror ;
	double testrate ;
	double c1p ;
	double c2p ;
	double c1n ;
	double c2n ;
	double svs ;

	int index ;			/*/ expert index in expert committee*/	
	BOOL abort ;		/*/ flag of exit*/
	BOOL smo_balance ;	/*/ lock the ratio between C+ and C- if FALSE, other set them equal*/

} smo_Settings ;


typedef struct _def_Settings
{
	double vc ;                     /*/ Regularization Parameter */
	double vc_p ;                   /*/ Regularization Parameter*/
	double vc_n ;                   /*/ Regularization Parameter*/
	double epsilon ;                /*/ Epsilon insensitive Loss Function*/
	double beta ;					/*/ Soft Insensitive Loss Function*/		
	double tol ;                    /*/ Tolerance Parameter in Loose KKT */
	double eps ;                    /*/ Error Precision Setting*/
	
	Kernel_Name kernel ;            /*/ Kernel Type*/
	double kappa ;                  /*/ 1/Variance in Gaussian kernel*/ 
	unsigned int p ;                /*/ Polynomial Power	*/

	Method_Name method ;            /*/ Heuristic Methods*/
	BOOL smo_display ;
	BOOL smo_balance ;
	BOOL ardon ;

	unsigned int index ;
	unsigned int loops ;
	unsigned int seeds ;
	unsigned int kfold ;       /*/ k-fold cross validation*/
	unsigned int repeat ;      /*/ repeating times  */
	unsigned long int cache_size ;  /*/ the size of kernel cache*/ 

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
	
	char * inputfile ;              /*/ the name of input data file*/
	char * testfile ;               /*/ the name of test data file*/
	struct _Data_List pairs ;		/*/ data_list saving all training data*/
	struct _Data_List training ;
	struct _Data_List validation ;
	struct _Data_List testdata ;		/*/ data_list saving test data*/
	
	BOOL normalized_input ;			/*/ normalize the input of training data if TRUE*/
	BOOL normalized_output ;		/*/ normalize the output of training data if TRUE*/

	Training_Method trainmethod ;	/*/ Training Methods*/

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

	double * lnC ;                /*/ size C_steps*1 */
	double * lnK ;                /*/ size K_steps*1*/

	unsigned int kfold ;          /*/ k-fold cross validation*/
	unsigned int ranks ;
	
	Data_Node ** nodelist ;
	Data_Node *** pointernode ;
	unsigned int ** cvfold ;
	
	double * cv_error ;           /*/ validation error with size C_steps*K_steps	*/
	double * cv_mean ;            /*/ validation error mean with size C_steps*K_steps*/
	double * cv_variance ;        /*/ validation error variance with size C_steps*K_steps*/
	double * cv_svs ;             /*/ size C_steps*K_steps*/
	double * cv_lnC ;             /*/ size C_steps*K_steps*/
	double * cv_lnK ;             /*/ size C_steps*K_steps*/

	double * final_error ;           /*/ validation error with size C_steps*K_steps	*/
	double * final_mean ;            /*/ validation error mean with size C_steps*K_steps*/
	double * final_variance ;        /*/ validation error variance with size C_steps*K_steps*/
	
	double * final_var_error ;           /*/ validation error with size C_steps*K_steps	*/
	double * final_var_mean ;            /*/ validation error mean with size C_steps*K_steps*/
	double * final_var_variance ;        /*/ validation error variance with size C_steps*K_steps*/

	double best_lnC ;
	double best_lnK ;	
	double best_rate ;

	double time ;                 /* time used in seconds*/
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

/*/ default settings*/
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
def_Settings * Create_def_SettingsMatlab ( void );

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

/*	load data file settings->inputfile, and create the data list Pairs */
BOOL smo_Loadfile ( Data_List * pairs, char * inputfilename, int inputdim );  
BOOL smo_LoadMatrix ( Data_List * pairs, char * inputfilename, int inputdim, int nFil, int nCol, double ** matrix);


/*create and initialize the smo_Settings structure from def_Settings*/
smo_Settings * Create_smo_Settings ( def_Settings * settings ) ;
void Clear_smo_Settings( smo_Settings * settings ) ;

/*/ cache, a doubly linked list*/
BOOL Create_Cache_List( Cache_List * ) ;
BOOL Clear_Cache_List( Cache_List * ) ;
BOOL Is_Cache_Empty( Cache_List * ) ;
BOOL Add_Cache_Node( Cache_List *, Alphas * ) ;
BOOL Sort_Cache_Node( Cache_List *, Alphas * ) ;
BOOL Del_Cache_Node( Cache_List *, Alphas * ) ; 

/*/ create Alpha Matrix*/
Alphas * Create_Alphas( smo_Settings * ) ;
BOOL Clean_Alphas ( Alphas *, smo_Settings * ) ;
BOOL Check_Alphas ( Alphas *, smo_Settings * ) ;
BOOL Clear_Alphas ( smo_Settings * ) ;

/*/ calculate kerenl*/
double Calc_Kernel( Alphas * , Alphas * , smo_Settings * ) ;
double Calculate_Kernel( double * , double * , smo_Settings * ) ;
double Calculate_Ordinal_Fi ( long unsigned int i, smo_Settings * settings ) ;/*/ i is index here*/

/*/ get label*/
Set_Name Get_Label ( Alphas * , smo_Settings * settings) ;
Set_Name Get_UP_Label ( Alphas * alpha, smo_Settings * settings) ;
Set_Name Get_DW_Label ( Alphas * alpha, smo_Settings * settings) ;
Set_Name Get_Setname( double * , double * , smo_Settings * ) ;
int Add_Label_Data_List ( Data_List * list, Data_Node * node ) ;

/*/ compute Fi*/
double Calculate_Fi( long unsigned int, smo_Settings * ) ;

BOOL smo_routine ( smo_Settings * settings ) ;
BOOL svm_predict ( Data_List * test, smo_Settings * settings ) ;

kcv_Settings * Create_Kcv ( def_Settings * settings ) ;
BOOL Init_Kcv ( kcv_Settings * settings, def_Settings * defsetting ) ;
BOOL Clear_Kcv ( kcv_Settings * settings) ;

BOOL svm_saveresults ( Data_List * testlist, smo_Settings * settings );
//struct estructura* svm_saveresults_Matlab(Data_List * testlist, smo_Settings * settings,int nElem);
struct estructura svm_saveresults_Matlab(Data_List * testlist, smo_Settings * settings);

BOOL Rehearsal_Kcv ( kcv_Settings * kcvsetting, def_Settings * defsetting ) ;

BOOL ordinal_takestep ( Alphas * alpha1, Alphas * alpha2, unsigned int threshold, smo_Settings * settings ) ;
BOOL ordinal_cross_takestep ( Alphas * alpha4, unsigned int, Alphas * alpha5, unsigned int, smo_Settings * settings ) ;
BOOL ordinal_cross_identical ( Alphas * alpha1, Alphas * alpha2, unsigned int threshold, smo_Settings * settings ) ;

/*/timing routines*/
void tstart(void) ;
void tend(void) ;
double tval() ;

#endif

#ifdef  __cplusplus
}
#endif
/*/ the end of smo.h*/

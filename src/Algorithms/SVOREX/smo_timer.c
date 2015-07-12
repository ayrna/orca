#include <stdio.h>
#include <string.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>


#ifdef _WIN32
#include <windows.h>
__int64 FileTimeToQuadWord (PFILETIME pft) {
   return(Int64ShllMod32(Int64ShllMod32(pft->dwHighDateTime, 16),16) | pft->dwLowDateTime);
}
static double _tstart, _tend;

/* Subroutine */ 
void bmr_timer(double *ttime)
{
	FILETIME ftKernelTimePresent ;
	FILETIME ftUserTimePresent ;
	FILETIME ftDummy;
	__int64 qwKernelTimeElapsed = 0, qwUserTimeElapsed = 0, qwTotalTimeElapsed = 0;

	GetThreadTimes(GetCurrentThread(), &ftDummy, &ftDummy, \
      &ftKernelTimePresent, &ftUserTimePresent);

	/* Get the elapsed kernel and user times by converting the start 
	 and end times from FILETIMEs to quad words, and then subtract 
	 the start times from the end times.*/

	qwKernelTimeElapsed = FileTimeToQuadWord(&ftKernelTimePresent) ;
	qwUserTimeElapsed = FileTimeToQuadWord(&ftUserTimePresent) ;
	/* Get total time duration by adding the kernel and user times.*/
	qwTotalTimeElapsed = qwKernelTimeElapsed + qwUserTimeElapsed ;
	*ttime = (double)qwTotalTimeElapsed*(1.0E-7) ; /*pow(10.0, 9.0) ;*/
}


void tstart(void)
{
bmr_timer(&_tstart) ;
}
void tend(void)
{
bmr_timer(&_tend) ;
}

double tval()
{
	return (_tend - _tstart) ;
}
#else
#include <sys/resource.h>
#include <sys/time.h>
#include <unistd.h>
static struct rusage _tstart, _tend;

void tstart(void)
{
	/*gettimeofday(&_tstart, &tz);*/
	getrusage(RUSAGE_SELF,&_tstart) ;
}
void tend(void)
{
	/*gettimeofday(&_tend,&tz);*/
	getrusage(RUSAGE_SELF,&_tend) ;
}

double tval()
{
	double t1, t2;

	t1 =  (double)_tstart.ru_utime.tv_sec + (double)_tstart.ru_utime.tv_usec/(1000*1000);
	t1 +=  (double)_tstart.ru_stime.tv_sec + (double)_tstart.ru_stime.tv_usec/(1000*1000);
	t2 =  (double)_tend.ru_utime.tv_sec + (double)_tend.ru_utime.tv_usec/(1000*1000);
	t2 +=  (double)_tend.ru_stime.tv_sec + (double)_tend.ru_stime.tv_usec/(1000*1000);
	return t2-t1;
}
#endif
#ifdef _WIN32
#include <windows.h>
#define SLASHC		'\\'
#define SLASHSTR	"\\"
#else
#include <sys/utsname.h>
#define SLASHC		'/'
#define SLASHSTR	"/"
#endif
/* end of smo_timer.c */


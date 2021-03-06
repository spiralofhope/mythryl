// error.c
//
// Run-time system error messages.


#include "../mythryl-config.h"

#include <stdio.h>
#include <stdarg.h>
#include "runtime-base.h"
#include "runtime-pthread.h"

extern FILE	*DebugF;


void   say   (char *fmt, ...)   {
    // ===
    //
    // Print a message to the standard output.

    va_list	ap;

    va_start (ap, fmt);
    vfprintf (stdout, fmt, ap);
    va_end(ap);
    fflush (stdout);
}


void   debug_say   (char *format, ...)   {
    // =========
    //
    // Print a message to the debug output stream.

    va_list	ap;

    va_start (ap, format);
    vfprintf (DebugF, format, ap);
    va_end(ap);
    fflush (DebugF);
}


void   say_error   (char *fmt, ...)   {
    // =========
    //
    // Print an error message.

    va_list	ap;

    va_start (ap, fmt);
    fprintf (stderr, "%s: Nonfatal error:  ", mythryl_program_name__global);
    vfprintf (stderr, fmt, ap);
    va_end(ap);
}


void   die   (char *fmt, ...)   {
    // ===
    //
    // Print an error message and then exit.

    va_list	ap;

    va_start (ap, fmt);
    fprintf (stderr, "%s: Fatal error:  ", mythryl_program_name__global);
    vfprintf (stderr, fmt, ap);
    fprintf (stderr, "\n");
    va_end(ap);

    #if NEED_PTHREAD_SUPPORT
	// Release any platform-specific multicore-support
	// resources such as kernel locks or mmapped segments:
	//
	pth__shut_down ();				// pth__shut_down		defined in   src/c/pthread/pthread-on-posix-threads.c
							// pth__shut_down		defined in   src/c/pthread/pthread-on-sgi.c
    #endif						// pth__shut_down		defined in   src/c/pthread/pthread-on-solaris.c

    print_stats_and_exit( 1 );
}


#ifdef ASSERT_ON
    //
void   assert_fail   (const char* a,  const char* file,  int line)    {		// Used (optionally) in ASSERT macro in   src/c/h/runtime-base.h
	//
	//
	// Print an assertion failure message.

	fprintf (stderr, "%s: Fatal error:  Assertion failure (%s) at \"%s:%d\"\n", mythryl_program_name__global, a, file, line);

	#if NEED_PTHREAD_SUPPORT
	    pth__shut_down ();
	#endif

	print_stats_and_exit( 2 );
    }
#endif


// COPYRIGHT (c) 1994 by AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.



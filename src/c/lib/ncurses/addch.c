// addch.c

#include "../../mythryl-config.h"

#if HAVE_CURSES_H
#include <curses.h>
#endif

#include "runtime-base.h"
#include "runtime-values.h"
#include "make-strings-and-vectors-etc.h"
#include "cfun-proto-list.h"
#include "../lib7-c.h"



Val   _lib7_Ncurses_addch   (Task* task,  Val arg)   {	//  : Void -> Bool
    //===================
    //
    #if HAVE_CURSES_H && HAVE_LIBNCURSES
	int ch     = INT1_LIB7toC(arg);    
	int result = addch( ch );
	if (result == ERR)     return RAISE_ERROR(task, "addch");
	return HEAP_VOID;
    #else
	extern char* no_ncurses_support_in_runtime;
	return RAISE_ERROR(task, no_ncurses_support_in_runtime);
    #endif
}



// Code by Jeff Prothero: Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


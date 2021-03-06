// sleep.c


#include "../../mythryl-config.h"

#include "runtime-base.h"
#include "runtime-values.h"
#include "make-strings-and-vectors-etc.h"
#include "lib7-c.h"
#include "cfun-proto-list.h"

#if HAVE_UNISTD_H
    #include <unistd.h>
#endif



// One of the library bindings exported via
//     src/c/lib/posix-process/cfun-list.h
// and thence
//     src/c/lib/posix-process/libmythryl-posix-process.c



Val   _lib7_P_Process_sleep   (Task* task,  Val arg)   {
    //=====================
    //
    // _lib7_P_Process_sleep:   Int -> Int
    //
    // Suspend execution for interval in seconds.
    //
    // This fn gets bound as   sleep'   in:
    //
    //     src/lib/std/src/posix-1003.1b/posix-process.pkg

    return TAGGED_INT_FROM_C_INT( sleep(TAGGED_INT_TO_C_INT(arg)) );
}


// COPYRIGHT (c) 1995 by AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


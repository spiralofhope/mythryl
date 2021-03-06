// setsid.c



#include "../../mythryl-config.h"

#include "system-dependent-unix-stuff.h"
#include "runtime-base.h"
#include "runtime-values.h"
#include "lib7-c.h"
#include "cfun-proto-list.h"



// One of the library bindings exported via
//     src/c/lib/posix-process-environment/cfun-list.h
// and thence
//     src/c/lib/posix-process-environment/libmythryl-posix-process-environment.c



Val   _lib7_P_ProcEnv_setsid   (Task* task,  Val arg)   {
    //======================
    //
    // Mythryl type:   Void -> Int
    //
    // Set session id
    //
    // This fn gets bound as   set_session_id   in:
    //
    //     src/lib/std/src/posix-1003.1b/posix-id.pkg

    pid_t pid =  setsid ();
    //
    CHECK_RETURN(task, pid)
}



// COPYRIGHT (c) 1995 by AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


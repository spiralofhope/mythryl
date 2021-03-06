// chmod.c


#include "../../mythryl-config.h"

#include "system-dependent-unix-stuff.h"
#include "make-strings-and-vectors-etc.h"
#include "lib7-c.h"
#include "cfun-proto-list.h"

#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif

#if HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif



// One of the library bindings exported via
//     src/c/lib/posix-file-system/cfun-list.h
// and thence
//     src/c/lib/posix-file-system/libmythryl-posix-file-system.c



Val   _lib7_P_FileSys_chmod   (Task* task,  Val arg)   {
    //=====================
    //
    // Mythryl type:  (String, Unt) -> Void
    //                 name    mode
    //
    // Change mode of file.
    //
    // This fn gets bound as   chmod'   in:
    //
    //     src/lib/std/src/posix-1003.1b/posix-file.pkg
    //     src/lib/std/src/posix-1003.1b/posix-file-system-64.pkg

    Val	    path = GET_TUPLE_SLOT_AS_VAL(     arg, 0);
    mode_t  mode = TUPLE_GETWORD( arg, 1);
    //
    int status = chmod (HEAP_STRING_AS_C_STRING(path), mode);
    //
    CHECK_RETURN_UNIT(task, status)
}


// COPYRIGHT (c) 1995 by AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


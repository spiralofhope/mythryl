// umask.c


#include "../../mythryl-config.h"

#include "system-dependent-unix-stuff.h"

#if HAVE_SYS_TYPES_H
    #include <sys/types.h>
#endif

#if HAVE_SYS_STAT_H
    #include <sys/stat.h>
#endif

#include "make-strings-and-vectors-etc.h"
#include "lib7-c.h"
#include "cfun-proto-list.h"



// One of the library bindings exported via
//     src/c/lib/posix-file-system/cfun-list.h
// and thence
//     src/c/lib/posix-file-system/libmythryl-posix-file-system.c



Val   _lib7_P_FileSys_umask   (Task* task,  Val arg)   {
    //=====================
    //
    // Mythryl type : Unt -> Unt
    //
    // Set and get file creation mask
    // Assumes umask never fails.
    //
    // This fn gets bound as   umask'   in:
    //
    //     src/lib/std/src/posix-1003.1b/posix-file.pkg
    //     src/lib/std/src/posix-1003.1b/posix-file-system-64.pkg

    mode_t omask = umask(WORD_LIB7toC(arg));

    Val               result;
    WORD_ALLOC (task, result, (Val_Sized_Unt)omask);
    return            result;
}


// COPYRIGHT (c) 1995 by AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


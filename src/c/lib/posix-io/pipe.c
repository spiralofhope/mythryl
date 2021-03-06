// pipe.c


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
//     src/c/lib/posix-io/cfun-list.h
// and thence
//     src/c/lib/posix-io/libmythryl-posix-io.c



Val   _lib7_P_IO_pipe   (Task* task,  Val arg)   {
    //===============
    //
    // Mythryl type:   Void -> (Int, Int)
    //
    // Create a pipe and return its input and output descriptors.
    //
    // This fn gets bound as   pipe'   in:
    //
    //     src/lib/std/src/posix-1003.1b/posix-io.pkg
    //     src/lib/std/src/posix-1003.1b/posix-io-64.pkg

    int         fds[2];

    if (pipe(fds) == -1) {

        return RAISE_SYSERR(task, -1);

    } else {

        Val        chunk;
        REC_ALLOC2 (task, chunk, TAGGED_INT_FROM_C_INT(fds[0]), TAGGED_INT_FROM_C_INT(fds[1]));
        return chunk;
    }
}


// COPYRIGHT (c) 1995 by AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


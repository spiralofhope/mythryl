// close.c


#include "../../mythryl-config.h"

#include <errno.h>

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



Val   _lib7_P_IO_close   (Task* task,  Val arg)   {
    //================
    //
    // Mythryl type:   Int -> Void
    //
    // Duplicate an open file descriptor
    //
    // This fn gets bound as   close'   in:
    //
    //     src/lib/std/src/posix-1003.1b/posix-io.pkg
    //     src/lib/std/src/posix-1003.1b/posix-io-64.pkg

    int  fd = TAGGED_INT_TO_C_INT(arg);
    int  status;

/*  do { */						// Backed out 2010-02-26 CrT: See discussion at bottom of src/c/lib/socket/connect.c

        status = close(fd);

/*  } while (status < 0 && errno == EINTR);	*/	// Restart if interrupted by a SIGALRM or SIGCHLD or whatever.

    CHECK_RETURN_UNIT(task, status)
}


// COPYRIGHT (c) 1995 by AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


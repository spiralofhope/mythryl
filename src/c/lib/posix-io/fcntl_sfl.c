// fcntl_sfl.c


#include "../../mythryl-config.h"

#include <errno.h>

#include "system-dependent-unix-stuff.h"

#if HAVE_FCNTL_H
    #include <fcntl.h>
#endif

#include "runtime-base.h"
#include "runtime-values.h"
#include "make-strings-and-vectors-etc.h"
#include "lib7-c.h"
#include "cfun-proto-list.h"



// One of the library bindings exported via
//     src/c/lib/posix-io/cfun-list.h
// and thence
//     src/c/lib/posix-io/libmythryl-posix-io.c



Val   _lib7_P_IO_fcntl_sfl   (Task* task,  Val arg)   {
    //====================
    //
    // Mythryl type:  (Int, Unt) -> Void
    //
    // Set file status flags
    //
    // This fn gets bound as   fcntl_sfl   in:
    //
    //     src/lib/std/src/posix-1003.1b/posix-io.pkg
    //     src/lib/std/src/posix-1003.1b/posix-io-64.pkg

    int             status;
    int             fd0 = GET_TUPLE_SLOT_AS_INT(arg, 0);
    Val_Sized_Unt          flag = TUPLE_GETWORD(arg, 1);

/*  do { */						// Backed out 2010-02-26 CrT: See discussion at bottom of src/c/lib/socket/connect.c

        status = fcntl(fd0, F_SETFL, flag);

/*  } while (status < 0 && errno == EINTR);	*/	// Restart if interrupted by a SIGALRM or SIGCHLD or whatever.

    CHECK_RETURN_UNIT(task,status)
}


// COPYRIGHT (c) 1995 by AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


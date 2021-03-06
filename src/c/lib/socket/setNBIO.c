// setNBIO.c	-- "NBIO" == "non-blocking I/O"
//
// Set/clear nonblocking status on given socket.


#include "../../mythryl-config.h"

#include <errno.h>

#include "sockets-osdep.h"
#include INCLUDE_SOCKET_H
#include "runtime-base.h"
#include "runtime-values.h"
#include "make-strings-and-vectors-etc.h"
#include "lib7-c.h"
#include "cfun-proto-list.h"
#include "socket-util.h"



/*
###                 "This is the biggest fool thing we've ever
###                  done -- the bomb will never go off -- and
###                  I speak as an expert on explosives."
###
###                        -- Admiral William Leahy, 1945,
###                           speaking to President Truman about the atom bomb
*/



// One of the library bindings exported via
//     src/c/lib/socket/cfun-list.h
// and thence
//     src/c/lib/socket/libmythryl-socket.c



Val   _lib7_Sock_setNBIO   (Task  *task,   Val  arg)   {
    //==================
    //
    // Mythryl type:  (Socket_Fd, Bool) -> Void
    //
    // This fn gets bound to   set_nbio'   in:
    //
    //     src/lib/std/src/socket/socket-guts.pkg

    int	socket = GET_TUPLE_SLOT_AS_INT(arg, 0);
    int status;

    #ifdef USE_FCNTL_FOR_NBIO
	//
	int n = fcntl(F_GETFL, socket);

	if (n < 0)   return RAISE_SYSERR (task, n);

	if (GET_TUPLE_SLOT_AS_VAL(arg, 1) == HEAP_TRUE)	n |=  O_NONBLOCK;
	else				n &= ~O_NONBLOCK;

    /*  do { */						// Backed out 2010-02-26 CrT: See discussion at bottom of src/c/lib/socket/connect.c

	    status = fcntl(F_SETFL, socket, n);

    /*  } while (status < 0 && errno == EINTR);	*/	// Restart if interrupted by a SIGALRM or SIGCHLD or whatever.

    #else
	int n = (GET_TUPLE_SLOT_AS_VAL(arg, 1) == HEAP_TRUE);

    /*  do { */						// Backed out 2010-02-26 CrT: See discussion at bottom of src/c/lib/socket/connect.c

	    status = ioctl (socket, FIONBIO, (char *)&n);

    /*  } while (status < 0 && errno == EINTR);	*/	// Restart if interrupted by a SIGALRM or SIGCHLD or whatever.
    #endif

    CHECK_RETURN_UNIT(task, status);
}


// COPYRIGHT (c) 1995 AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


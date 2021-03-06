// list-socket-types.c


#include "../../mythryl-config.h"

#include "runtime-base.h"
#include "make-strings-and-vectors-etc.h"
#include "socket-util.h"
#include "cfun-proto-list.h"
#include "lib7-c.h"



// One of the library bindings exported via
//     src/c/lib/socket/cfun-list.h
// and thence
//     src/c/lib/socket/libmythryl-socket.c



Val   _lib7_Sock_listsocktypes   (Task* task,  Val arg)   {
    //========================
    // 
    // Mythryl type:   Void -> List( System_Constant )
    //
    // Return a list of the known socket types.
    // (This may contain unsupported families.)
    //
    // This fn gets bound as   list_socket_types   in:
    //
    //     src/lib/std/src/socket/socket-guts.pkg

    return dump_table_as_system_constants_list( task, &_Sock_Type );
}



// COPYRIGHT (c) 1995 AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


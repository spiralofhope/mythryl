// fcntl_l_64.c
//
//   Using 64-bit position values represented as 32-bit pairs.


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



Val   _lib7_P_IO_fcntl_l_64   (Task* task,  Val arg)   {	// Handle record locking.
    //=====================
    //
    // Mythryl type is
    //
    //     (Sy_Int, Sy_Int, Flock_Rep) -> Flock_Rep
    // where
    //     Flock_Rep = (Int, Int, Offsethi, Offsetlo, Offsethi, Offsetlo, Int)
    //
    // This fn gets bound as   fcntl_l   in:
    //
    //     src/lib/std/src/posix-1003.1b/posix-io-64.pkg
    
    int        fd =  GET_TUPLE_SLOT_AS_INT( arg, 0 );
    int       cmd =  GET_TUPLE_SLOT_AS_INT( arg, 1 );
    Val flock_rep =  GET_TUPLE_SLOT_AS_VAL( arg, 2 );

    Val starthi, startlo;
    Val   lenhi,   lenlo;

    struct flock     flock;
    int  status;
    
    flock.l_type   = GET_TUPLE_SLOT_AS_INT(flock_rep, 0);
    flock.l_whence = GET_TUPLE_SLOT_AS_INT(flock_rep, 1);

    #if (SIZEOF_STRUCT_FLOCK_L_START > 4)				// i.e. sizeof(flock.l_start) > 4 -- see src/c/config/generate-sizes-of-some-c-types-h.c
	//
	flock.l_start
	    =
	    (((off_t)WORD_LIB7toC(GET_TUPLE_SLOT_AS_VAL(flock_rep, 2))) << 32)
            |
	    ((off_t)(WORD_LIB7toC(GET_TUPLE_SLOT_AS_VAL(flock_rep, 3))));
    #else
	flock.l_start =	  (off_t) (WORD_LIB7toC(GET_TUPLE_SLOT_AS_VAL(flock_rep, 3)));
    #endif

    #if (SIZEOF_STRUCT_FLOCK_L_LEN > 4)					// i.e. sizeof (flock.l_len) > 4)  -- see src/c/config/generate-sizes-of-some-c-types-h.c
	//
	flock.l_len
	    =
	    (((off_t)WORD_LIB7toC(GET_TUPLE_SLOT_AS_VAL(flock_rep, 4))) << 32)
	    |
	    ((off_t)(WORD_LIB7toC(GET_TUPLE_SLOT_AS_VAL(flock_rep, 5))));
    #else
	flock.l_len
	    =
	    (off_t)(WORD_LIB7toC(GET_TUPLE_SLOT_AS_VAL(flock_rep, 5)));
    #endif
   

/*  do { */								// Backed out 2010-02-26 CrT: See discussion at bottom of src/c/lib/socket/connect.c

        status = fcntl(fd, cmd, &flock);

/*  } while (status < 0 && errno == EINTR);	*/			// Restart if interrupted by a SIGALRM or SIGCHLD or whatever.


    if (status < 0)   return RAISE_SYSERR(task, status);


    #if (SIZEOF_STRUCT_FLOCK_L_START > 4)				// As above.
	//
        WORD_ALLOC (task, starthi, (Unt1) (flock.l_start >> 32));
    #else
        WORD_ALLOC (task, starthi, (Unt1) 0);
    #endif
    WORD_ALLOC (task, startlo, (Unt1) flock.l_start);


    #if (SIZEOF_STRUCT_FLOCK_L_LEN > 4)					// As above.
	//
        WORD_ALLOC (task, lenhi, (Unt1) (flock.l_len >> 32));
    #else
        WORD_ALLOC (task, lenhi, (Unt1) 0);
    #endif

    WORD_ALLOC (task, lenlo, (Unt1) flock.l_len);


    LIB7_AllocWrite   (task, 0, MAKE_TAGWORD (PAIRS_AND_RECORDS_BTAG, 7));
    LIB7_AllocWrite   (task, 1, TAGGED_INT_FROM_C_INT(flock.l_type));
    LIB7_AllocWrite   (task, 2, TAGGED_INT_FROM_C_INT(flock.l_whence));
    LIB7_AllocWrite   (task, 3, starthi);
    LIB7_AllocWrite   (task, 4, startlo);
    LIB7_AllocWrite   (task, 5, lenhi);
    LIB7_AllocWrite   (task, 6, lenlo);
    LIB7_AllocWrite   (task, 7, TAGGED_INT_FROM_C_INT(flock.l_pid));
    return LIB7_Alloc (task, 7);
}									// fun _lib7_P_IO_fcntl_l_64


// Copyright (c) 2004 by The Fellowship of SML/NJ
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


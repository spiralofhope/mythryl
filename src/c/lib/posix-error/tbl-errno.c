// table-errno.c
//
// The table of system constants representing the Posix error codes.


#include "../../mythryl-config.h"

#include "system-dependent-unix-stuff.h"
#include "runtime-base.h"
#include <errno.h>

// This gets bound as   errors   in:
//
//    src/lib/std/src/posix-1003.1b/posix-error.pkg

static System_Constant table[] = {
	{EACCES,	"acces"},
	{EAGAIN,	"again"},
#if (defined(EWOULDBLOCK) && (EWOULDBLOCK != EAGAIN))
	{EWOULDBLOCK,	"wouldblock"},
#endif
	{EBADF,		"badf"},
#ifdef EBADMSG
	{EBADMSG,	"badmsg"},
#else
	{0,		"badmsg"},
#endif
	{EBUSY,		"busy"},
#ifdef ECANCELED
	{ECANCELED,	"canceled"},
#else
	{0,		"canceled"},
#endif
	{ECHILD,	"child"},
	{EDEADLK,	"deadlk"},
	{EDOM,		"dom"},
	{EEXIST,	"exist"},
	{EFAULT,	"fault"},
	{EFBIG,		"fbig"},
	{EINPROGRESS,	"inprogress"},
	{EINTR,		"intr"},
	{EINVAL,	"inval"},
	{EIO,		"io"},
	{EISDIR,	"isdir"},
	{ELOOP,		"loop"},
	{EMFILE,	"mfile"},
	{EMLINK,	"mlink"},
	{EMSGSIZE,	"msgsize"},
	{ENAMETOOLONG,	"nametoolong"},
	{ENFILE,	"nfile"},
	{ENODEV,	"nodev"},
	{ENOENT,	"noent"},
	{ENOEXEC,	"noexec"},
	{ENOLCK,	"nolck"},
	{ENOMEM,	"nomem"},
	{ENOSPC,	"nospc"},
	{ENOSYS,	"nosys"},
	{ENOTDIR,	"notdir"},
	{ENOTEMPTY,	"notempty"},
#ifdef ENOTSUP
	{ENOTSUP,	"notsup"},
#else
	{0,		"notsup"},
#endif
	{ENOTTY,	"notty"},
	{ENXIO,		"nxio"},
	{EPERM,		"perm"},
	{EPIPE,		"pipe"},
	{ERANGE,	"range"},
	{EROFS,		"rofs"},
	{ESPIPE,	"spipe"},
	{ESRCH,		"srch"},
	{E2BIG,		"toobig"},
	{EXDEV,		"xdev"},
    };

System_Constants_Table	errno_table__global = {
	sizeof(table) / sizeof(System_Constant),
	table
    };


// COPYRIGHT (c) 1996 AT&T Research.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


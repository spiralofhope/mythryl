// prim.pwrpc32.asm
//
// This file contains asmcoded functions callable directly
// from Mythryl via the runtime::asm API defined in
//
//     src/lib/core/init/runtime.api
//
// These assembly code functions may then request services from
// the C level by passing one of the request codes defined in
//
//     src/c/h/asm-to-c-request-codes.h
//
// to
//
//     src/c/main/run-mythryl-code-and-runtime-eventloop.c
//
// which then dispatches on them to various fns throughout the C runtime.

#ifndef _ASM_
#define _ASM_
#endif

#include "runtime-base.h"
#include "asm-base.h"
#include "runtime-values.h"
#include "heap-tags.h"
#include "asm-to-c-request-codes.h"
#include "runtime-configuration.h"
#include "task-and-pthread-struct-field-offsets--autogenerated.h"	// This file is generated.

// Factor out variations in assembler synatax:
//
#if defined(OPSYS_DARWIN)
   // Sse the macOS X names by default
#  define HI(name) ha16(name)
#  define LO(name) lo16(name)


#else 
#  define HI(name) name@ha
#  define LO(name) name@l

#  define cr0 0
#  define cr1 1
#  define r0  0
#  define r1  1
#  define r2  2
#  define r3  3
#  define r4  4
#  define r5  5
#  define r6  6
#  define r7  7
#  define r8  8
#  define r9  9
#  define r10  10
#  define r11  11
#  define r12  12
#  define r13  13
#  define r14  14
#  define r15  15
#  define r16  16
#  define r17  17
#  define r18  18
#  define r19  19
#  define r20  20
#  define r21  21
#  define r22  22
#  define r23  23
#  define r24  24
#  define r25  25
#  define r26  26
#  define r27  27
#  define r28  28
#  define r29  29
#  define r30  30
#  define r31  31

#  define f0  0
#  define f1  1
#  define f2  2
#  define f3  3
#  define f4  4
#  define f5  5
#  define f6  6
#  define f7  7
#  define f8  8
#  define f9  9
#  define f10  10
#  define f11  11
#  define f12  12
#  define f13  13
#  define f14  14
#  define f15  15
#  define f16  16
#  define f17  17
#  define f18  18
#  define f19  19
#  define f20  20
#  define f21  21
#  define f22  22
#  define f23  23
#  define f24  24
#  define f25  25
#  define f26  26
#  define f27  27
#  define f28  28
#  define f29  29
#  define f30  30
#  define f31  31

#endif


	
// Register usage
#define		sp			r1
#define 	stackptr		sp

#define		heap_allocation_pointer	r14
#define 	heap_allocation_limit	r15
#define 	heap_changelog_ptr	r16
#define		stdlink			r17
#define 	stdclos			r18
#define 	stdarg			r19
#define 	stdfate			r20
#define 	exnfate			r21
#define 	current_thread_ptr	r22
#define		miscreg0		r24
#define		miscreg1		r25
#define 	miscreg2		r26
#define		program_counter	        r28


#define       	atmp1 r29
#define       	atmp2 r30
#define       	atmp3 r31
#define 	atmp4 r13

// old stackframe layout -- NO LONGER VALID:
// Note: 1. cvti2d stuff is used in back/low/main/pwrpc32/pwrpc32PseudoInstr.sml.
//          (Orig: The offset of cvti2d tmp is used in rs6000.pkg.)
//
//       2. Question: Where is the load/store offset used, if at all?
//          (Orig: float load/store offset is hardwired in rs6000instr.sml.)
//
// 	             +-------------------+
//   sp--> 0(sp)     | task addr         |
//	             +-------------------+
//	   4(sp)     | _startgc addr	 |
//	             +-------------------+
//	   8(sp)     | cvti2d const	 |
//	             +-------------------+
//	  16(sp)     | cvti2d tmp2	 |
//	      	     +-------------------+
//	  24(sp)     | float load/store  |
//		     +-------------------+
//	  32(sp)     | floor tmp	 |
//		     +-------------------+
//	  40(sp)     | unused		 |
//		     +-------------------+
//	  44(sp)     | unused		 |
//		     +-------------------+
//  argblock(sp)     | C calleesave regs |
//	             .		         .
//		     .		         .
//		     +-------------------+
//  argblock+92(sp)  |		    	 |
//

// NEW stackframe layout -- with support for ccalls (nlffi):
//
// Note: cvti2d stuff is used in back/low/main/pwrpc32/pwrpc32PseudoInstr.sml.
//
//   sp--> 0(sp)     +-------------------+
//                   |                   |
//                   |   linkage area    |
//                   |                   |
// 	  24(sp)     +-------------------+
//                   |  4072 (=4096-24)  |
//                   |  bytes for ccall |
//                   |  arguments        |
//	             .		         .
//		     .		         .
// 	             +-------------------+
//      4096(sp)     | task addr (4)     |
//	             +-------------------+
//	4100(sp)     | _startgc addr (4) |
//	             +-------------------+
//	4104(sp)     | cvti2d const  (8) |
//                   |                   |
//	             +-------------------+
//	4112(sp)     | cvti2d tmp2   (8) |
//                   |                   |
//		     +-------------------+
//	4120(sp)     | floor tmp     (8) |
//		     +-------------------+
//  argblock(sp)     | C calleesave regs |   (argblock = 4128, mult. of 16)
//	             .		         .
//		     .		         .
//		     +-------------------+
//  argblock+92(sp)  |		    	 |



// Task offsets
//
#define argblock 		4128
#define savearea		(23*4+4)	// lr,cr,1,2,13-31,padding
#define framesize		8192
#define TASK_OFFSET	 	4096
#define RUN_HEAPCLEANER__OFFSET	4100		// Offset relative to framepointer of pointer to function which starts a heapcleaning ("garbage collection").
#define CVTI2D_OFFSET		4104
#define FLOOR_OFFSET		4120

// Offsets in condition register CR.0

#define CR0_LT 0
#define CR0_GT 1
#define CR0_EQ 2
#define CR0_SO 3
	
#define CR0	cr0


// C parameter passing conventions
#define CARG1 		r3
#define CRESULT1 	r3


#define CONTINUE									\
	    cmpl	CR0,heap_allocation_pointer,heap_allocation_limit __SC__	\
	    mtlr	stdfate __SC__							\
	    blr

#define CHECKLIMIT(label)	 				\
	    bt		CR0_LT, label __SC__			\
	    addi	program_counter, stdlink,0 __SC__	\
	    b		CSYM(call_heapcleaner_asm) __SC__		\
    label:

#if defined (USE_TOC)
// Create table of contents entries for things we need the address of.
	.extern		CSYM(software_generated_periodic_event_interval_refcell__global)
	.extern 	CSYM(software_generated_periodic_events_switch_refcell__global)
	.extern		CSYM(call_heapcleaner_asm)

	.toc
T.software_generated_periodic_event_interval_refcell__global:
	.tc	H.software_generated_periodic_event_interval_refcell__global[TC],CSYM(software_generated_periodic_event_interval_refcell__global)
T.software_generated_periodic_events_switch_refcell__global:
	.tc	H.software_generated_periodic_events_switch_refcell__global[TC],CSYM(software_generated_periodic_events_switch_refcell__global)
T.call_heapcleaner_asm:	
	.tc	H.call_heapcleaner_asm[TC],CSYM(call_heapcleaner_asm)
T.cvti2d_CONST:
	.tc	H.cvti2d_CONST[TC],cvti2d_CONST
#endif
	RO_DATA
	ALIGN8
cvti2d_CONST:	
	DOUBLE(4503601774854144.0)

	TEXT
// sig_return : (Fate(X), X) -> Y
//
LIB7_CODE_HDR( return_from_signal_handler_asm )
	li 	atmp4,REQUEST_RETURN_FROM_SIGNAL_HANDLER
	li	stdlink,         HEAP_VOID
	li	stdclos,         HEAP_VOID
	li	program_counter, HEAP_VOID
	b	set_request

// Here we pick up execution from where we were
// before we went off to handle a POSIX signal:
//
ENTRY( resume_after_handling_signal )
	li	atmp4, REQUEST_RESUME_SIGNAL_HANDLER
	b	set_request

// return_from_software_generated_periodic_event_handler_a:
// The return fate for the Mythryl software
// generated periodic event handler.
//
LIB7_CODE_HDR( return_from_software_generated_periodic_event_handler_asm )
	li	atmp4,REQUEST_RETURN_FROM_SOFTWARE_GENERATED_PERIODIC_EVENT_HANDLER
	li	stdlink,         HEAP_VOID
	li	stdclos,         HEAP_VOID
	li	program_counter, HEAP_VOID
	b	set_request

// Here we pick up execution from where we were
// before we went off to handle a software generated
// periodic event:
//
ENTRY(resume_after_handling_software_generated_periodic_event)
	li	atmp4,REQUEST_RESUME_SOFTWARE_GENERATED_PERIODIC_EVENT_HANDLER
	b	set_request

// Exception handler for Mythryl functions called from C.
// We delegate uncaught-exception handling to
//     handle_uncaught_exception  in  src/c/main/runtime-exception-stuff.c
// We get invoked courtesy of being stuffed into
//     task->exception_fate
// in  src/c/main/run-mythryl-code-and-runtime-eventloop.c
// and src/c/heapcleaner/import-heap.c
//
LIB7_CODE_HDR(handle_uncaught_exception_closure_asm)
	li	atmp4,REQUEST_HANDLE_UNCAUGHT_EXCEPTION
	addi	program_counter, stdlink, 0
	b	set_request



// Here to return to                                     run_mythryl_task_and_runtime_eventloop  in   src/c/main/run-mythryl-code-and-runtime-eventloop.c
// and thence to whoever called it.  If the caller was   load_and_run_heap_image                 in   src/c/main/load-and-run-heap-image.c
// this will return us to                                main                                    in   src/c/main/runtime-main.c
// which will print stats
// and exit(), but                   if the caller was   no_args_entry or some_args_entry        in   src/c/lib/ccalls/ccalls-fns.c
// then we may have some scenario
// where C calls Mythryl which calls C which ...
// and we may just be unwinding on level.
//    The latter can only happen with the
// help of the src/lib/c-glue-old/ stuff,
// which is currently non-operational.
//
// run_mythryl_task_and_runtime_eventloop is also called by
//     src/c/pthread/pthread-on-posix-threads.c
//     src/c/pthread/pthread-on-sgi.c
//     src/c/pthread/pthread-on-solaris.c
// but that stuff is also non-operational (I think) and
// we're not supposed to return to caller in those cases.
// 
// We get slotted into task->fate by   save_c_state           in   src/c/main/runtime-state.c 
// and by                              run_mythryl_function   in   src/c/main/run-mythryl-code-and-runtime-eventloop.c
//
LIB7_CODE_HDR(return_to_c_level_asm)
	li	atmp4,REQUEST_RETURN_TO_C_LEVEL
	li	stdlink,         HEAP_VOID
	li	stdclos,         HEAP_VOID
	li	program_counter, HEAP_VOID
	b	set_request


ENTRY(request_fault)
	li	atmp4,REQUEST_FAULT
	addi	program_counter, stdlink, 0
	b	set_request


// find_cfun : (String, String) -> Cfunction			// (library-name, function-name) -> Cfunction -- see comments in   src/c/heapcleaner/mythryl-callable-cfun-hashtable.c
//
// We get called (only) from:
//
//     src/lib/std/src/unsafe/mythryl-callable-c-library-interface.pkg	
//
LIB7_CODE_HDR(find_cfun_asm)
	CHECKLIMIT(find_cfun_v_limit) 
	li	atmp4,REQUEST_FIND_CFUN
	b	set_request

LIB7_CODE_HDR(make_package_literals_via_bytecode_interpreter_asm)
	CHECKLIMIT(make_package_literals_via_bytecode_interpreter_v_limit) 
	li	atmp4,REQUEST_MAKE_PACKAGE_LITERALS_VIA_BYTECODE_INTERPRETER
	b	set_request



// Invoke a C-level function (obtained from find_cfun above) from the Mythryl level.
// We get called (only) from
//
//     src/lib/std/src/unsafe/mythryl-callable-c-library-interface.pkg
//
LIB7_CODE_HDR(call_cfun_asm)
	CHECKLIMIT(call_cfun_v_limit) 
	li	atmp4,REQUEST_CALL_CFUN
	b	set_request


// This is the entry point called from Mythryl to start a heapcleaning.
//						Allen 6/5/1998
ENTRY(call_heapcleaner_asm)
	li	atmp4, REQUEST_CLEANING
	mflr	program_counter

	// FALL THROUGH

set_request:
	lwz	atmp3,TASK_OFFSET(sp)			// Save the minimal Mythryl state.
	lwz	atmp2,pthread_byte_offset_in_task_struct(atmp3)	// atmp2 := Pthread
	li	r0,0
	stw	r0,executing_mythryl_code_byte_offset_in_pthread_struct(atmp2)		// Note that we have left Mythryl.
	stw	heap_allocation_pointer,heap_allocation_pointer_byte_offset_in_task_struct(atmp3)
	stw	heap_allocation_limit,heap_allocation_limit_byte_offset_in_task_struct(atmp3)
	stw	heap_changelog_ptr,heap_changelog_byte_offset_in_task_struct(atmp3)
	stw	stdlink,link_register_byte_offset_in_task_struct(atmp3)
	stw	program_counter,program_counter_byte_offset_in_task_struct(atmp3)
	stw	stdarg,argument_byte_offset_in_task_struct(atmp3)
	stw	stdfate,fate_byte_offset_in_task_struct(atmp3)
	stw	stdclos,current_closure_byte_offset_in_task_struct(atmp3)
	stw	current_thread_ptr,current_thread_byte_offset_in_task_struct(atmp3)
	stw	exnfate,exception_fate_byte_offset_in_task_struct(atmp3)
	stw	miscreg0,callee_saved_register_0_byte_offset_in_task_struct(atmp3)
	stw	miscreg1,callee_saved_register_1_byte_offset_in_task_struct(atmp3)
	stw	miscreg2,callee_saved_register_2_byte_offset_in_task_struct(atmp3)

	addi	r3,atmp4,0			// Request as argument.

restore_c_regs:
 	lwz	r2, (argblock+4)(sp) 
	lwz	r13, (argblock+8)(sp)
	lwz	r14, (argblock+12)(sp)
	lwz	r15, (argblock+16)(sp)
	lwz	r16, (argblock+20)(sp)
	lwz	r17, (argblock+24)(sp)
	lwz	r18, (argblock+28)(sp)
	lwz	r19, (argblock+32)(sp)
	lwz	r20, (argblock+36)(sp)
	lwz	r21, (argblock+40)(sp)
	lwz	r22, (argblock+44)(sp)
	lwz	r23, (argblock+48)(sp)
	lwz	r24, (argblock+52)(sp)
	lwz	r25, (argblock+56)(sp)
	lwz	r26, (argblock+60)(sp)
	lwz	r27, (argblock+64)(sp)
	lwz	r28, (argblock+68)(sp)
	lwz	r29, (argblock+72)(sp)
	lwz	r30, (argblock+76)(sp)
	lwz	r31, (argblock+80)(sp)
	lwz	r0, (argblock+84)(sp)
	mtlr    r0
	lwz	r0, (argblock+88)(sp)
	mtcrf	0x80, r0
	addi	sp,sp,framesize 
	blr



CENTRY(asm_run_mythryl_task)
	stwu	sp,-framesize(sp)
#if defined(USE_TOC)
	lwz	r0,T.call_heapcleaner_asm(2)
#else
#ifdef BROKEN_CODE
	lis	r28, HI(CSYM(call_heapcleaner_asm))	// GPR0 <- addrof(call_heapcleaner_asm)
	addi	r28, r28, LO(CSYM(call_heapcleaner_asm))
        li      r0, 0
        add     r0, r28, r0
#else
	lis	r11, HI(CSYM(call_heapcleaner_asm))	// GPR0 <- addrof(call_heapcleaner_asm)
	addi	r11, r11, LO(CSYM(call_heapcleaner_asm))
        li      r0, 0
        add     r0, r11, r0
#endif
#endif
	stw	r3, TASK_OFFSET(sp)
	stw	r0, RUN_HEAPCLEANER__OFFSET(sp)
#if defined(USE_TOC)
	lwz	r4, T.cvti2d_CONST(r2)		// GPR2 is RTOC
	lfd	f0, 0(r4)
#else
	lis	r4, HI(cvti2d_CONST)
	lfd	f0, LO(cvti2d_CONST)(r4)
#endif
	stfd	f0, CVTI2D_OFFSET(sp)

	stw	r2, argblock+4(sp)
	stw	r13, argblock+8(sp)
	stw	r14, argblock+12(sp)
	stw	r15, argblock+16(sp)
	stw	r16, argblock+20(sp)
	stw	r17, argblock+24(sp)
	stw	r18, argblock+28(sp)
	stw	r19, argblock+32(sp)
	stw	r20, argblock+36(sp)
	stw	r21, argblock+40(sp)
	stw	r22, argblock+44(sp)
	stw	r23, argblock+48(sp)
	stw	r24, argblock+52(sp)
	stw	r25, argblock+56(sp)
	stw	r26, argblock+60(sp)
	stw	r27, argblock+64(sp)
	stw	r28, argblock+68(sp)
	stw	r29, argblock+72(sp)
	stw	r30, argblock+76(sp)
	stw	r31, argblock+80(sp)
	mflr    r0
	stw	r0,  argblock+84(sp)
	mfcr	r0
	stw	r0,  argblock+88(sp)
	
	and	atmp1,r3,r3								// atmp1 := Task pointer

	lwz	heap_allocation_pointer,heap_allocation_pointer_byte_offset_in_task_struct(atmp1)
	lwz	heap_allocation_limit,heap_allocation_limit_byte_offset_in_task_struct(atmp1)
	lwz	heap_changelog_ptr,heap_changelog_byte_offset_in_task_struct(atmp1)
	lwz	atmp2,pthread_byte_offset_in_task_struct(atmp1)				// atmp2 := Pthread
	li	atmp3,1
	stw	atmp3,executing_mythryl_code_byte_offset_in_pthread_struct(atmp2)         // We are entering Mythryl code.
	lwz	stdarg,argument_byte_offset_in_task_struct(atmp1)
	lwz	stdfate,fate_byte_offset_in_task_struct(atmp1)
	lwz	stdclos,current_closure_byte_offset_in_task_struct(atmp1)
	lwz	exnfate,exception_fate_byte_offset_in_task_struct(atmp1)
	lwz	miscreg0,callee_saved_register_0_byte_offset_in_task_struct(atmp1)
	lwz	miscreg1,callee_saved_register_1_byte_offset_in_task_struct(atmp1)
	lwz	miscreg2,callee_saved_register_2_byte_offset_in_task_struct(atmp1)
	lwz	stdlink,link_register_byte_offset_in_task_struct(atmp1)
	lwz	current_thread_ptr,current_thread_byte_offset_in_task_struct(atmp1)
	lwz	atmp3,program_counter_byte_offset_in_task_struct(atmp1)
	mtlr	atmp3

	// Check for pending signals:
	//
	lwz	atmp1,all_posix_signals_seen_count_byte_offset_in_pthread_struct(atmp2)	  // Number of signals received.
	lwz	atmp3,all_posix_signals_done_count_byte_offset_in_pthread_struct(atmp2)	  // Number of signals handled.
	cmp	CR0,atmp1,atmp3
	bne	pending_sigs								  // If not equal, then pending signals.


ENTRY(ml_go) 
	cmpl	CR0,heap_allocation_pointer,heap_allocation_limit
	mtfsfi  3,0			// Ensure that no exceptions are set.
	mtfsfi  2,0
	mtfsfi  1,0
	mtfsfi  0,0
	li	r0,0
	mtxer   r0
	blr				// Jump to Mythryl code.

pending_sigs:				// There are pending signals.
					// Check if currently handling a signal.
	lwz	atmp1,mythryl_handler_for_posix_signal_is_running_byte_offset_in_pthread_struct(atmp2)
	cmpi	CR0,atmp1,0
	bf	CR0_EQ,CSYM(ml_go)

	li	r0,1
	stw	r0,posix_signal_pending_byte_offset_in_pthread_struct(atmp2)
	addi	heap_allocation_limit,heap_allocation_pointer,0
	b	CSYM(ml_go)

// make_typeagnostic_rw_vector : (Int, X) -> Rw_Vector(X)
// Allocate and initialize a new array.	 This can trigger cleaning.
//
LIB7_CODE_HDR(make_typeagnostic_rw_vector_asm)
	CHECKLIMIT(make_typeagnostic_rw_vector_a_limit)

	lwz	atmp1,0(stdarg)					// atmp1 := length in words
	srawi	atmp2, atmp1, 1					// atmp2 := length (untagged)
	cmpi	CR0,atmp2,MAX_AGEGROUP0_ALLOCATION_SIZE_IN_WORDS	// Is this a small chunk (i.e., one allowed in the arena)?
	bf	CR0_LT, make_typeagnostic_rw_vector_a_large

	lwz	stdarg,4(stdarg)				// Initial value.
	slwi	atmp3,atmp2,TAG_SHIFTW				// Build tagword in tmp3.
	ori	atmp3,atmp3,MAKE_TAG(DTAG_rw_vec_data)
	stw	atmp3,0(heap_allocation_pointer)				// Store tagword.
	addi	heap_allocation_pointer,heap_allocation_pointer,4				// Points to new chunk.
	addi	atmp3,heap_allocation_pointer,0				// vector data ptr in atmp3

make_typeagnostic_rw_vector_a_1:
	stw	stdarg,0(heap_allocation_pointer)				// Initialize vector
	addi	atmp2,atmp2,-1
	addi	heap_allocation_pointer,heap_allocation_pointer,4
	cmpi 	CR0,atmp2,0
	bf	CR0_EQ,make_typeagnostic_rw_vector_a_1

	// Allocate vector header:
	//
	li	atmp2,TYPEAGNOSTIC_RW_VECTOR_TAGWORD	// Tagword in tmp2.
	stw	atmp2,0(heap_allocation_pointer)	// Store tagword.
	addi	heap_allocation_pointer, heap_allocation_pointer, 4	// heap_allocation_pointer++
	addi	stdarg, heap_allocation_pointer, 0	// result = header addr
	stw	atmp3,0(heap_allocation_pointer)	// Store pointer to data
	stw 	atmp1,4(heap_allocation_pointer)
	addi	heap_allocation_pointer,heap_allocation_pointer,8
	CONTINUE
make_typeagnostic_rw_vector_a_large:				// Offline allocation
	li	atmp4,REQ_ALLOC_ARRAY
	addi	program_counter, stdlink,0
	b	set_request

// make_unt8_rw_vector : Int -> Unt8_Rw_Vector
// Create a bytearray of the given length.
//
LIB7_CODE_HDR(make_unt8_rw_vector_asm)
	CHECKLIMIT(make_unt8_rw_vector_a_limit)

	srawi	atmp2,stdarg,1		// atmp2 = length (untagged int)
	addi	atmp2,atmp2,3		// atmp2 = length in words
	srawi	atmp2,atmp2,2		
	cmpi    CR0,atmp2,MAX_AGEGROUP0_ALLOCATION_SIZE_IN_WORDS // Is this a "small chunk"?
	bf     CR0_LT,make_unt8_rw_vector_a_large

	// Allocate the data chunk:
	//
	slwi	atmp1,atmp2,TAG_SHIFTW		// Build tagword in atmp1
	ori	atmp1,atmp1,MAKE_TAG(DTAG_raw32)
	stw	atmp1,0(heap_allocation_pointer) 		// Store the data tagword.
	addi	heap_allocation_pointer,heap_allocation_pointer,4		// heap_allocation_pointer++
	addi	atmp3, heap_allocation_pointer, 0		// atmp3 = data chunk
	slwi	atmp2, atmp2, 2			// atmp2 = length in bytes
	add	heap_allocation_pointer,heap_allocation_pointer,atmp2		// heap_allocation_pointer += total length

	// Allocate the header chunk:
	//
	li	atmp1, UNT8_RW_VECTOR_TAGWORD		// Header tagword.
	stw	atmp1,0(heap_allocation_pointer)	
	addi	heap_allocation_pointer, heap_allocation_pointer, 4		// heap_allocation_pointer++
	stw	atmp3,0(heap_allocation_pointer)		// Header data field
	stw	stdarg,4(heap_allocation_pointer)		// Header length field.
	addi	stdarg, heap_allocation_pointer, 0		// stdarg = header chunk
	addi	heap_allocation_pointer,heap_allocation_pointer,8		// heap_allocation_pointer += 2
	CONTINUE

make_unt8_rw_vector_a_large:				// Offline allocation.
	li 	atmp4,REQUEST_ALLOCATE_BYTE_VECTOR
	addi	program_counter, stdlink,0
	b	set_request


// make_string_asm: Int -> String
//
LIB7_CODE_HDR(make_string_asm)
	CHECKLIMIT(make_string_a_limit)

	srawi	atmp2,stdarg,1		// atmp2 = length(untagged int)
	addi	atmp2,atmp2,4
	srawi	atmp2,atmp2,2		// Length-in-words (including tagword).
	cmpi	CR0,atmp2,MAX_AGEGROUP0_ALLOCATION_SIZE_IN_WORDS	// Is this a "small chunk"?
	bf	CR0_LT,make_string_a_large
	
	slwi	atmp1,atmp2,TAG_SHIFTW	// Build tagword in atmp3
	ori	atmp1,atmp1,MAKE_TAG(DTAG_raw32)
	stw	atmp1,0(heap_allocation_pointer)	// Store tagword.
	addi	heap_allocation_pointer,heap_allocation_pointer,4	// heap_allocation_pointer++
	addi	atmp3,heap_allocation_pointer,0	// atmp3 = data chunk
	slwi	atmp2,atmp2,2		// atmp2 = length in bytes
	add	heap_allocation_pointer,atmp2,heap_allocation_pointer // heap_allocation_pointer += total length
	stw	r0,-4(heap_allocation_pointer)		// Store zero in last word.

	// Allocate the header chunk:	
	//
	li	atmp1, STRING_TAGWORD	// Header tagword.
	stw	atmp1, 0(heap_allocation_pointer)
	addi	heap_allocation_pointer,heap_allocation_pointer,4	// heap_allocation_pointer++
	stw	atmp3,0(heap_allocation_pointer)	// Header data field.
	stw	stdarg,4(heap_allocation_pointer)	// Header length field.
	addi	stdarg,heap_allocation_pointer,0	// stdarg = header chunk
	addi	heap_allocation_pointer,heap_allocation_pointer,8	// heap_allocation_pointer += 2
	CONTINUE

make_string_a_large:			// Offline allocation.
	li	atmp4,REQUEST_ALLOCATE_STRING
	addi	program_counter, stdlink,0
	b	set_request



LIB7_CODE_HDR(make_float64_rw_vector_asm)
	CHECKLIMIT(make_float64_rw_vector_a_limit)

	srawi	atmp2,stdarg,1		// atmp2 = length (untagged int)
	slwi	atmp2,atmp2,1		// Length in words.
	cmpi	CR0,atmp2,MAX_AGEGROUP0_ALLOCATION_SIZE_IN_WORDS	// Is this a "small chunk"?		
	bf	CR0_LT,make_float64_rw_vector_a_large
	
	// Allocate the data chunk:
	//	
	slwi	atmp1, atmp2, TAG_SHIFTW // Tagword in atmp1.
	ori	atmp1, atmp1, MAKE_TAG(DTAG_raw64)
#ifdef ALIGN_FLOAT64S
	ori	heap_allocation_pointer,heap_allocation_pointer,4
#endif	
	stw	atmp1,0(heap_allocation_pointer)	// Store the tagword.
	addi	heap_allocation_pointer, heap_allocation_pointer, 4	// heap_allocation_pointer++
	addi	atmp3, heap_allocation_pointer, 0	// atmp3 = data chunk
	slwi	atmp2, atmp2, 2		// tmp2 = length in bytes
	add	heap_allocation_pointer,heap_allocation_pointer,atmp2 // heap_allocation_pointer += length

	// Allocate the header chunk:
	//
	li	atmp1, FLOAT64_RW_VECTOR_TAGWORD
	stw	atmp1, 0(heap_allocation_pointer)	// Header tagword.
	addi	heap_allocation_pointer,heap_allocation_pointer,4	// heap_allocation_pointer++
	stw	atmp3,0(heap_allocation_pointer)	// Header data field.
	stw	stdarg,4(heap_allocation_pointer)	// Header length field.
	addi	stdarg,heap_allocation_pointer,0	// stdarg = header chunk
	addi	heap_allocation_pointer,heap_allocation_pointer,8	// heap_allocation_pointer += 2
	CONTINUE
make_float64_rw_vector_a_large:			// Offline allocation.
	li	atmp4,REQUEST_ALLOCATE_VECTOR_OF_EIGHT_BYTE_FLOATS
	addi	program_counter, stdlink,0
	b	set_request


// make_vector_asm:  (Int, List(X)) -> Vector(X)			// (length_in_slots, initializer_list) -> result_vector
//
//	Create a vector and initialize from given list.
//
//	Caller guarantees that length_in_slots is
//      positive and also the length of the list.
//	For a sample client call see
//          fun vector
//	in
//	    src/lib/core/init/pervasive.pkg
//
LIB7_CODE_HDR(make_vector_asm)
	CHECKLIMIT(make_vector_a_limit)
	
	lwz	atmp1,0(stdarg)		// atmp1 = tagged length
	srawi	atmp2,atmp1,1		// atmp2 = untagged length
	cmpi	CR0,atmp2,MAX_AGEGROUP0_ALLOCATION_SIZE_IN_WORDS // Is this a "small chunk"?
	bf	CR0_LT,make_vector_a_large

	slwi	atmp2,atmp2,TAG_SHIFTW	// Build tagword in atmp2
	ori	atmp2,atmp2,MAKE_TAG(DTAG_ro_vec_data)
	stw	atmp2,0(heap_allocation_pointer)	// Store tagword.
	addi	heap_allocation_pointer,heap_allocation_pointer,4	// heap_allocation_pointer++
	lwz	atmp2,4(stdarg)		// atmp2 := list
	addi	stdarg,heap_allocation_pointer,0	// stdarg := vector

make_vector_a_1:
	lwz	atmp3,0(atmp2)		// atmp3:=hd(atmp2)
	lwz	atmp2,4(atmp2)		// atmp2:=tl(atmp2)
	stw	atmp3,0(heap_allocation_pointer)	// Store word.
	addi	heap_allocation_pointer,heap_allocation_pointer,4	// heap_allocation_pointer++ 
	cmpi	CR0,atmp2,HEAP_NIL
	bf	CR0_EQ,create_v_a_1

	// Allocate header chunk:
	//
	li	atmp3, DESC_polyvec	// Tagword in tmp3
	stw	atmp3,0(heap_allocation_pointer)	// Store tagword.
	addi	heap_allocation_pointer,heap_allocation_pointer,4	// heap_allocation_pointer++
	stw	stdarg,0(heap_allocation_pointer)	// Header data field.
	stw 	atmp1,4(heap_allocation_pointer)	// Header length.
	addi	stdarg, heap_allocation_pointer, 0	// result = header chunk
	addi	heap_allocation_pointer,heap_allocation_pointer,8	// heap_allocation_pointer += 2
	CONTINUE

make_vector_a_large:
	li	atmp4,REQ_ALLOC_VECTOR
	addi	program_counter, stdlink,0
	b	set_request


#if defined(USE_TOC)
	.toc
T.floor_CONST:
	.tc	H.floor_CONST[TC],floor_CONST
#endif
	RO_DATA
	ALIGN8
floor_CONST:
	DOUBLE(4512395720392704.0)

	TEXT
	//
	// floor_a : real -> int
	//	Do not test for overflow -- it is the caller's
	//	responsibility to be in range.
	//
	//	This code essentially loads 1.0*2^52 into 
	//	register f3. A floating add will internally 
	//	perform an exponent alignment, which will 
	//	bring the required bits into the mantissa.
	//
LIB7_CODE_HDR(floor_asm)
	lfd	f1, 0(stdarg)		
	/*
	** Neat thing here is that this code works for
	** both +ve and -ve floating point numbers.
	*/
	mffs	f0
	stfd	f0,0(heap_allocation_pointer)	/* steal the heap_allocation_pointer for a second */
	lwz	r0, 4(heap_allocation_pointer)
	mtfsb1	30
	mtfsb1 	31
#ifdef USE_TOC
	lwz	atmp1, T.floor_CONST(r2)
	lfd	f3, 0(atmp1)
#else
	lis	atmp1, HI(floor_CONST)
	lfd	f3, LO(floor_CONST)(atmp1)
#endif
	fadd	f6,f1,f3
	stfd	f6,FLOOR_OFFSET(sp)
	lwz	stdarg,FLOOR_OFFSET+4(sp)
	add	stdarg,stdarg,stdarg
	addi	stdarg,stdarg,1
	
	andi.	r0,r0, 0xf
	mtfsf	0xff,f0
	CONTINUE


LIB7_CODE_HDR(logb_asm)
	lwz	stdarg,0(stdarg)  	// Most significant part.
	srawi 	stdarg,stdarg,20	// Throw out 20 low bits.
	andi.	stdarg,stdarg,0x07ff	// Clear all but 11 low bits.
	addi	stdarg,stdarg,-1023	// Subtract 1023.
	slwi	stdarg,stdarg,1		// Make room for tag bit.
	addi	stdarg,stdarg,1		// Add the tag bit.
	CONTINUE


// scalb : real * int -> real
//	scalb(x,y) = x * 2^y
//
LIB7_CODE_HDR(scalb_asm)
	CHECKLIMIT(scalb_v_limit)
	lwz	atmp1,4(stdarg)		// atmp1 := y
	srawi	atmp1,atmp1,1		// atmp1 := machine int y
	lwz	stdarg,0(stdarg)	// stdarg := x
	lwz	atmp2,0(stdarg)		// atmp2 := MSW(x)
	lis	r0,0x7ff0		// r0 := 0x7ff0,0000
	and.	atmp3,atmp2,r0		// atmp3 := atmp2 & 0x7ff00000
	bt	CR0_EQ,scalb_all_done
	
	srawi	atmp3,atmp3,20		// atmp3 := ieee(exp)
	add.	atmp1,atmp1,atmp3	// Scale exponent 
	bt	CR0_LT,scalb_underflow

	cmpi	CR0,atmp1,2047		// Max. ieee(exp)
	bf	CR0_LT,scalb_overflow

	not	r0,r0			// r0 := not(r0)
	and	atmp2,atmp2,r0		//* atmp2 := high mantessa bits + sign
	slwi	atmp1,atmp1,20		// atmp1 := new exponent
	or	atmp1,atmp1,atmp2	// atmp1 := new MSB(x)
	lwz	atmp2, 4(stdarg)	

scalb_write_out:
	stw	atmp1, 4(heap_allocation_pointer)
	stw	atmp2, 8(heap_allocation_pointer)
	li	atmp3, DESC_reald
	stw	atmp3, 0(heap_allocation_pointer)
	addi	stdarg,heap_allocation_pointer,4
	addi	heap_allocation_pointer,heap_allocation_pointer,12

scalb_all_done:
	CONTINUE

scalb_underflow:
	li	atmp1,0
	li	atmp2,0
	b	scalb_write_out

LABEL(scalb_overflow)
	mtfsb1 	3



LIB7_CODE_HDR(try_lock_asm)
	lwz	atmp1,0(stdarg)
	li	atmp2,1			// HEAP_FALSE
	stw	atmp2,0(stdarg)
	addi	stdarg,atmp1,0
	CONTINUE


LIB7_CODE_HDR(unlock_asm)
	li	atmp1,3			// HEAP_TRUE
	stw	atmp1,0(stdarg)
	li	stdarg,1		// Just return unit
	CONTINUE



CENTRY(set_fsr)
	mtfsb0	24		// Disable invalid exception
	mtfsb0	25		// Disable overflow exception
	mtfsb0	26		// Disable underflow exception
	mtfsb0	28		// Disable inexact exception
	mtfsb0	30		// Round to nearest
	mtfsb0	31		
	blr			// return
	
// saveFPRegs and restoreFPRegs are called from C only.
#define ctmp1 12
#define ctmp2 11
#define ctmp3 10


CENTRY(SaveFPRegs)
	stfd	f14, 4(r3)
	stfd	f15, 12(r3)
	stfd	f16, 20(r3)
	stfd	f17, 28(r3)
	stfd	f18, 36(r3)
	stfd	f19, 44(r3)
	stfd	f20, 52(r3)
	stfd	f21, 60(r3)
	stfd	f22, 68(r3)
	stfd	f23, 76(r3)
	stfd	f24, 84(r3)
	stfd	f25, 92(r3)
	stfd	f26, 100(r3)
	stfd	f27, 108(r3)
	stfd	f28, 116(r3)
	stfd	f29, 124(r3)
	stfd	f30, 132(r3)
	stfd	f31, 140(r3)

	blr

CENTRY(RestoreFPRegs)
	lfd	f14, 0(r3)
	lfd	f15, 8(r3)
	lfd	f16, 16(r3)
	lfd	f17, 24(r3)
	lfd	f18, 32(r3)
	lfd	f19, 40(r3)
	lfd	f20, 48(r3)
	lfd	f21, 56(r3)
	lfd	f22, 64(r3)
	lfd	f23, 72(r3)
	lfd	f24, 80(r3)
	lfd	f25, 88(r3)
	lfd	f26, 96(r3)
	lfd	f27, 104(r3)
	lfd	f28, 112(r3)
	lfd	f29, 120(r3)
	lfd	f30, 128(r3)
	lfd	f31, 136(r3)
	blr

#if (defined(TARGET_PWRPC32) && (defined(OPSYS_LINUX) || defined(OPSYS_DARWIN) ))

#define CACHE_LINE_BYTESIZE		32
#define CACHE_LINE_MASK		(CACHE_LINE_BYTESIZE-1)
#define CACHE_LINE_BITS		26

// FlushICache:
//
//   void FlushICache ( Punt  addr,
//	                Punt  nbytes
//	              )
///
CENTRY(FlushICache)
	add	r4,r3,r4			// stop := addr+nbytes
	addic	r4,r4,CACHE_LINE_MASK		// stop := stop + CACHE_LINE_MASK
	rlwinm	r4,r4,0,0,CACHE_LINE_BITS	// stop := stop & ~CACHE_LINE_MASK
L_FlushICache_1:
	cmplw	cr1,r3,r4			// while (addr < stop)
	bc	4,4,L_FlushICache_2
	dcbf	0,r3				//   flush addr
	icbi	0,r3				//   invalidate addr
	addi	r3,r3,CACHE_LINE_BYTESIZE		//   addr := addr + CACHE_LINE_BYTESIZE
	b	L_FlushICache_1			// end while
L_FlushICache_2:
	blr

#endif



// COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


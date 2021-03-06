// heapcleaner-stuff.c
//
// Garbage collection utility routines.

#include "../mythryl-config.h"

#include <stdarg.h>
#include <string.h>
#include "runtime-base.h"
#include "runtime-configuration.h"
#include "runtime-values.h"
#include "get-multipage-ram-region-from-os.h"
#include "coarse-inter-agegroup-pointers-map.h"
#include "heap.h"


Status   allocate_and_partition_an_agegroup   (Agegroup* ag) {
    //   ==================================
    // 
    // Allocate and partition the space for an agegroup.

    Multipage_Ram_Region*	heapchunk;

    Sib*  ap;

    // Compute the total size:
    //
    Punt  tot_size =  0;
    //
    for (int i = 0;  i < MAX_PLAIN_ILKS;  i++) {
	//
	if (sib_is_active( ag->sib[ i ] )) {							// sib_is_active	def in    src/c/h/heap.h
	    //
	    tot_size +=  ag->sib[ i ]->tospace_bytesize;
	}
    }

    if (ag->saved_fromspace_ram_region != NULL
    && BYTESIZE_OF_MULTIPAGE_RAM_REGION( ag->saved_fromspace_ram_region ) >= tot_size
    ){
	heapchunk =  ag->saved_fromspace_ram_region;

	ag->saved_fromspace_ram_region =  NULL;

    } else if ((heapchunk = obtain_multipage_ram_region_from_os( tot_size )) == NULL) {
	//
	// Eventually we should try to allocate the agegroup
	//as separate chunks instead of failing.			XXX BUGGO FIXME
	//
	return FAILURE;
    }

    // Initialize the chunks:
    //
    ag->tospace_ram_region = heapchunk;
    //
    #ifdef VERBOSE
        debug_say ("allocate_and_partition_an_agegroup[%d]: tot_size = %d, [%#x, %#x)\n",
            ag->age,
            tot_size,
            BASE_ADDRESS_OF_MULTIPAGE_RAM_REGION( heapchunk ),
            BASE_ADDRESS_OF_MULTIPAGE_RAM_REGION( heapchunk ) + BYTESIZE_OF_MULTIPAGE_RAM_REGION( heapchunk )
        );
    #endif
    //
    Val* p =  (Val*) BASE_ADDRESS_OF_MULTIPAGE_RAM_REGION( heapchunk );
    //
    for (int i = 0;  i < MAX_PLAIN_ILKS;  i++) {
        //
	ap = ag->sib[ i ];
        //
	if (!sib_is_active(ap)) {							// sib_is_active	def in    src/c/h/heap.h
            //
	    ap->tospace	= NULL;
	    ap->next_tospace_word_to_allocate		= NULL;
	    ap->next_word_to_sweep_in_tospace	= NULL;
	    ap->tospace_limit		= NULL;
            //
	} else {
            //
	    ap->tospace	= p;
	    ap->next_tospace_word_to_allocate		= p;
	    ap->next_word_to_sweep_in_tospace	= p;
            //
	    p = (Val*)((Punt)p + ap->tospace_bytesize);
	    ap->tospace_limit	= p;
	    set_book2sibid_entries_for_range( book_to_sibid__global, ap->tospace, ap->tospace_bytesize, ap->id );

	    #ifdef VERBOSE
	        debug_say ("  %#x:  [%#x, %#x)\n", ap->id, ap->next_tospace_word_to_allocate, p);
	    #endif
	}
    }

    ap = ag->sib[ PAIR_ILK ];

    if (sib_is_active(ap)) {
        //
        // The first slot of pair-space must not be used,
        // else poly-equal might fault:
        //
	*(ap->next_tospace_word_to_allocate++) = HEAP_VOID;
	*(ap->next_tospace_word_to_allocate++) = HEAP_VOID;
	ap->tospace = ap->next_tospace_word_to_allocate;
	ap->tospace_bytesize -= (2*WORD_BYTESIZE);
	ap->next_word_to_sweep_in_tospace = ap->next_tospace_word_to_allocate;
    }   

    return SUCCESS;
}								// fun allocate_and_partition_an_agegroup



void   free_agegroup   (Heap* heap,  int g) {
    // ====================
    //
    Agegroup*  ag = heap->agegroup[ g ];

    if (ag->fromspace_ram_region == NULL)   return;

    #ifdef VERBOSE
	debug_say ("free_agegroup [%d]: [%#x, %#x)\n",
            g+1,
            BASE_ADDRESS_OF_MULTIPAGE_RAM_REGION( ag->fromspace_ram_region ),
            BASE_ADDRESS_OF_MULTIPAGE_RAM_REGION( ag->fromspace_ram_region ) + BYTESIZE_OF_MULTIPAGE_RAM_REGION( ag->fromspace_ram_region )
        );
    #endif


    if (g >= heap->oldest_agegroup_keeping_idle_fromspace_buffers) {
        //
	return_multipage_ram_region_to_os( ag->fromspace_ram_region );
	//
    } else {
        //
	if (ag->saved_fromspace_ram_region == NULL) {
	    ag->saved_fromspace_ram_region =  ag->fromspace_ram_region;
	} else {

	    if (BYTESIZE_OF_MULTIPAGE_RAM_REGION( ag->saved_fromspace_ram_region )
              > BYTESIZE_OF_MULTIPAGE_RAM_REGION( ag->fromspace_ram_region       )
            ){
	        //
		return_multipage_ram_region_to_os( ag->fromspace_ram_region );
	    } else {
		return_multipage_ram_region_to_os( ag->saved_fromspace_ram_region );
		ag->saved_fromspace_ram_region = ag->fromspace_ram_region;
	    }
	}
    }

    // NOTE: Since the sib buffers are contiguous,
    // we could do this in one call:
    //
    ag->fromspace_ram_region = NULL;
    //	
    for (int i = 0;  i < MAX_PLAIN_ILKS;  i++) {
	//
	Sib* ap =  ag->sib[ i ];

	if (ap->fromspace != NULL) {
	    //
	    set_book2sibid_entries_for_range (book_to_sibid__global, ap->fromspace, ap->fromspace_bytesize, UNMAPPED_BOOK_SIBID);

	    ap->fromspace = NULL;
	    ap->fromspace_bytesize = 0;
	    ap->fromspace_used_end = NULL;
	}
    }
}								// fun free_agegroup


void   make_new_coarse_inter_agegroup_pointers_map_for_agegroup   (Agegroup* ag) {
    // ========================================================
    // 
    // Bind in a new coarse_inter_agegroup_pointers_map
    // vector for the given agegroup VECTOR_ILK,
    // reclaiming the old map.

    Sib* ap =  ag->sib[ VECTOR_ILK ];												// We only need these maps for the VECTOR_ILK sibs.

    int  map_size_in_slots
	=
	ap->tospace_bytesize / CARD_BYTESIZE;

    int  agegroup0_buffer_bytesize = CARDMAP_BYTESIZE( map_size_in_slots );

    if (ag->coarse_inter_agegroup_pointers_map != NULL) {
        //
	FREE( ag->coarse_inter_agegroup_pointers_map );
    }
    ag->coarse_inter_agegroup_pointers_map =   (Coarse_Inter_Agegroup_Pointers_Map*)   MALLOC( agegroup0_buffer_bytesize );

    ag->coarse_inter_agegroup_pointers_map->map_bytesize =   agegroup0_buffer_bytesize;

    if (ag->coarse_inter_agegroup_pointers_map == NULL) 	die ("unable to malloc coarse_inter_agegroup_pointers_map vector");

    ag->coarse_inter_agegroup_pointers_map->base_address =  ap->tospace;
    ag->coarse_inter_agegroup_pointers_map->card_count   =  map_size_in_slots;

    memset(
        ag->coarse_inter_agegroup_pointers_map->min_age,
        CLEAN_CARD,
        agegroup0_buffer_bytesize -  (sizeof( Coarse_Inter_Agegroup_Pointers_Map ) - WORD_BYTESIZE)
    );
}


void   set_book2sibid_entries_for_range   (Sibid* book2sibid,  Val* base_address,  Val_Sized_Unt bytesize,  Sibid sibid) {
    // =================================
    //
    // Mark the book_to_sibid__global entries corresponding to the range [ base_address, base_address+bytesize )
    // with sibid.

    #ifdef TWO_LEVEL_MAP
        #error two level map not supported
    #else
	int start =  GET_BOOK_CONTAINING_POINTEE( base_address );
	int end   =  GET_BOOK_CONTAINING_POINTEE( ((Punt)base_address) + bytesize );

	#ifdef VERBOSE
	    // debug_say("set_book2sibid_entries_for_range [%#x..%#x) as %#x\n", base_address, ((Punt)base_address)+bytesize, sibid);
	#endif

	while (start < end) {
	    //
	    book2sibid[ start++ ] =  sibid;
	}
    #endif
}


void   null_out_newly_dead_weak_pointers   (Heap* heap) {
    // ===========================
    // 
    // Weak pointers are not followed by the cleaner (garbage collector).
    // The point of this is to allow us to (for example) maintain an index
    // of all existing items of some kind while still allowing them to be
    // garbage collected when no longer needed.  The index will see the weak
    // pointers to recycled values turn Void at that point.  Implementing
    // that is our job here.
    // 
    // Scan the list of weak pointers,
    // nullifying those that refer to
    // dead (i.e., from-space) chunks.

    // This list gets constructed in the functions
    // 
    //     forward_special_chunk()
    // in
    //     src/c/heapcleaner/heapclean-agegroup0.c
    //     src/c/heapcleaner/heapclean-n-agegroups.c

    if (heap->weak_pointers_forwarded_during_cleaning == NULL)   return;			// No work to do.

    Sibid*	   b2s    =  book_to_sibid__global;						// Cache global locally for speed.   book_to_sibid__global	def in    src/c/heapcleaner/heapcleaner-initialization.c

    Val* next;

												// debug_say ("scan_weak_pointers:\n");

    for (Val* p = heap->weak_pointers_forwarded_during_cleaning;
         p != NULL;
         p = next
    ){
	next       = PTR_CAST( Val*, UNMARK_POINTER( p[0] ));
	Val* chunk = (Val*) (Punt)   UNMARK_POINTER( p[1] );

												// debug_say ("  %#x --> %#x ", p+1, chunk);

	//
	switch (GET_KIND_FROM_SIBID( SIBID_FOR_POINTER(b2s, chunk ))) {
	    //
	case NEW_KIND:
	case RECORD_KIND:
	case STRING_KIND:
	case VECTOR_KIND:
	    {
		Val tagword = chunk[-1];

		if (tagword == FORWARDED_CHUNK_TAGWORD) {
		    //
		    p[0] = WEAK_POINTER_TAGWORD;
		    p[1] = PTR_CAST( Val, FOLLOW_FWDCHUNK(chunk));
		    // debug_say ("forwarded to %#x\n", FOLLOW_FWDCHUNK(chunk));

		} else {

		    p[0] = NULLED_WEAK_POINTER_TAGWORD;
		    p[1] = HEAP_VOID;

		    // debug_say ("nullified\n");
		}
	    }
	    break;

	case PAIR_KIND:
	    //
	    // Pairs are special because they don't have a tagword.
	    // (To save space.)
	    // Since they don't we mark forwarded pairs not by
	    // changing a tagword to FORWARDED_CHUNK_TAGWORD as usual,
	    // but rather by setting the TAGWORD_ATAG bit (0x2) on the
	    // first word in the Pair:
	    //
	    {   Val tagword;

		if (IS_TAGWORD( tagword = chunk[0] )) {
		    //
		    p[0] = WEAK_POINTER_TAGWORD;
		    p[1] = PTR_CAST( Val,  FOLLOW_PAIRSPACE_FORWARDING_POINTER( tagword, chunk ) );

		    // debug_say ("(pair) forwarded to %#x\n", FOLLOW_PAIRSPACE_FORWARDING_POINTER( tagword, chunk ));

		} else {

		    p[0] = NULLED_WEAK_POINTER_TAGWORD;
		    p[1] = HEAP_VOID;

		    // debug_say ("(pair) nullified\n");
		}
	    }
	    break;

	case CODE_KIND:
	    die ("weak big chunk");
	    break;
	}
    }

    heap->weak_pointers_forwarded_during_cleaning
	=
	NULL;
}



// COPYRIGHT (c) 1993 by AT&T Bell Laboratories.
// Subsequent changes by Jeff Prothero Copyright (c) 2010-2011,
// released under Gnu Public Licence version 3.


#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>

/*
 * Lab2 optional challenge: a simplified, single-CPU SLUB-style allocator.
 * It obtains 4 KiB physical pages from the active pmm_manager and divides
 * those pages into fixed-size objects. Requests larger than the largest size
 * class are backed by one or more consecutive physical pages.
 *
 * Call slub_init() once, after pmm_init() has initialized physical memory.
 * slub_alloc(0) returns NULL; slub_free(NULL) does nothing.
 * All returned addresses are aligned to 16 bytes.
 */
void slub_init(void);
void *slub_alloc(size_t size);
void slub_free(void *ptr);

/* Lab2 optional challenge: independently written correctness tests. */
void slub_check(void);

#endif /* !__KERN_MM_SLUB_H__ */

#include <slub.h>
#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>

/*
 * Lab2 Challenge: simplified SLUB. Level 1 is alloc_pages()/free_pages();
 * level 2 is a group of 16-byte-aligned object caches on top of those pages.
 *
 * This educational implementation assumes a single CPU, no interrupts
 * racing with allocation, and the kernel's existing direct physical map.
 * It deliberately leaves all framework PMM structs, tests and build rules
 * unchanged. This is not Linux's production, per-CPU SLUB implementation.
 */

#define SLUB_ALIGN           16UL
#define SLUB_MIN_OBJECT      16UL
#define SLUB_CACHE_COUNT     8
#define SLUB_BITMAP_WORDS    ((PGSIZE / SLUB_MIN_OBJECT + 63) / 64)
#define SLUB_SLAB_MAGIC      0x534c5542534c4142ULL  /* "SLUBSLAB" */
#define SLUB_LARGE_MAGIC     0x534c55424c415247ULL  /* "SLUBLARG" */

#define SLUB_ALIGNED_BYTES(n) (((n) + SLUB_ALIGN - 1) & ~(SLUB_ALIGN - 1))

struct slub_cache {
    size_t object_size;
    list_entry_t partial; /* pages with at least one free slot */
    list_entry_t full;    /* pages whose slots are all in use */
};

/* Stored inside the page allocated by the existing PMM, not in a new heap. */
struct slub_slab {
    uint64_t magic;
    list_entry_t link;
    void *free_head;  /* free slots chained through their first pointer word */
    unsigned int cache_index;
    unsigned int capacity;
    unsigned int inuse;
    uint64_t allocated[SLUB_BITMAP_WORDS]; /* detect invalid/double free */
};

/* Every large object starts with a header at the beginning of its first page. */
struct slub_large {
    uint64_t magic;
    size_t requested_bytes;
    size_t page_count;
};

#define SLUB_OBJECT_START SLUB_ALIGNED_BYTES(sizeof(struct slub_slab))
#define SLUB_LARGE_START  SLUB_ALIGNED_BYTES(sizeof(struct slub_large))

static const size_t slub_sizes[SLUB_CACHE_COUNT] = {
    16, 32, 64, 128, 256, 512, 1024, 2048
};
static struct slub_cache slub_caches[SLUB_CACHE_COUNT];
static bool slub_initialized;

/* The existing kernel directly maps DRAM at PA + va_pa_offset. */
static uintptr_t slub_page_address(struct Page *page) {
    return page2pa(page) + va_pa_offset;
}

/* Convert a page-aligned direct-map address to its PMM Page descriptor. */
static struct Page *slub_page_descriptor(uintptr_t page_addr) {
    uintptr_t pa = page_addr - va_pa_offset;
    assert(pa >= (uintptr_t)nbase * PGSIZE);
    assert(PPN(pa) < npage);
    struct Page *page = pa2page(pa);
    assert(slub_page_address(page) == page_addr);
    return page;
}

static bool slub_bitmap_is_set(struct slub_slab *slab, size_t index) {
    return (slab->allocated[index / 64] & (1ULL << (index % 64))) != 0;
}

static void slub_bitmap_set(struct slub_slab *slab, size_t index) {
    slab->allocated[index / 64] |= (1ULL << (index % 64));
}

static void slub_bitmap_clear(struct slub_slab *slab, size_t index) {
    slab->allocated[index / 64] &= ~(1ULL << (index % 64));
}

void slub_init(void) {
    /* Re-initializing with live allocations would silently leak whole pages. */
    assert(!slub_initialized);
    assert(SLUB_OBJECT_START + SLUB_MIN_OBJECT <= PGSIZE);
    assert(SLUB_LARGE_START < PGSIZE);
    for (size_t i = 0; i < SLUB_CACHE_COUNT; ++i) {
        slub_caches[i].object_size = slub_sizes[i];
        list_init(&slub_caches[i].partial);
        list_init(&slub_caches[i].full);
    }
    slub_initialized = 1;
}

static struct slub_slab *slub_new_slab(unsigned int index) {
    struct Page *page = alloc_page();
    if (page == NULL) {
        return NULL;
    }
    struct slub_slab *slab = (struct slub_slab *)slub_page_address(page);
    memset(slab, 0, sizeof(*slab));
    slab->magic = SLUB_SLAB_MAGIC;
    slab->cache_index = index;
    slab->capacity = (PGSIZE - SLUB_OBJECT_START) /
                     slub_caches[index].object_size;
    assert(slab->capacity > 0 && slab->capacity <= PGSIZE / SLUB_MIN_OBJECT);
    list_init(&slab->link);

    unsigned char *first = (unsigned char *)slab + SLUB_OBJECT_START;
    size_t slot_size = slub_caches[index].object_size;
    for (unsigned int i = 0; i < slab->capacity; ++i) {
        unsigned char *slot = first + (size_t)i * slot_size;
        void *next = (i + 1 < slab->capacity)
                         ? (void *)(slot + slot_size) : NULL;
        *(void **)slot = next;
    }
    slab->free_head = first;
    list_add(&slub_caches[index].partial, &slab->link);
    return slab;
}

static void *slub_alloc_small(unsigned int index) {
    struct slub_cache *cache = &slub_caches[index];
    if (list_empty(&cache->partial) && slub_new_slab(index) == NULL) {
        return NULL;
    }
    struct slub_slab *slab = to_struct(list_next(&cache->partial),
                                       struct slub_slab, link);
    assert(slab->magic == SLUB_SLAB_MAGIC);
    assert(slab->cache_index == index && slab->inuse < slab->capacity);
    void *object = slab->free_head;
    assert(object != NULL);
    uintptr_t offset = (uintptr_t)object -
                       ((uintptr_t)slab + SLUB_OBJECT_START);
    assert(offset % cache->object_size == 0);
    size_t slot_index = offset / cache->object_size;
    assert(slot_index < slab->capacity);
    assert(!slub_bitmap_is_set(slab, slot_index));

    slab->free_head = *(void **)object;
    slub_bitmap_set(slab, slot_index);
    ++slab->inuse;
    if (slab->inuse == slab->capacity) {
        assert(slab->free_head == NULL);
        list_del(&slab->link);
        list_add(&cache->full, &slab->link);
    }
    return object;
}

static void *slub_alloc_large(size_t size) {
    /* Guard both header addition and page-rounding against size_t overflow. */
    if (size > (size_t)-1 - SLUB_LARGE_START - (PGSIZE - 1)) {
        return NULL;
    }
    size_t count = (size + SLUB_LARGE_START + PGSIZE - 1) / PGSIZE;
    assert(count >= 1);
    struct Page *page = alloc_pages(count);
    if (page == NULL) {
        return NULL;
    }
    struct slub_large *block = (struct slub_large *)slub_page_address(page);
    block->magic = SLUB_LARGE_MAGIC;
    block->requested_bytes = size;
    block->page_count = count;
    return (unsigned char *)block + SLUB_LARGE_START;
}

void *slub_alloc(size_t size) {
    assert(slub_initialized);
    if (size == 0) {
        return NULL;
    }
    for (unsigned int i = 0; i < SLUB_CACHE_COUNT; ++i) {
        if (size <= slub_sizes[i]) {
            return slub_alloc_small(i);
        }
    }
    return slub_alloc_large(size);
}

void slub_free(void *object) {
    if (object == NULL) {
        return;
    }
    assert(slub_initialized);
    uintptr_t page_addr = ROUNDDOWN((uintptr_t)object, PGSIZE);
    struct Page *page = slub_page_descriptor(page_addr);
    uint64_t magic = *(uint64_t *)page_addr;

    if (magic == SLUB_LARGE_MAGIC) {
        struct slub_large *large = (struct slub_large *)page_addr;
        assert((uintptr_t)object == page_addr + SLUB_LARGE_START);
        assert(large->requested_bytes > slub_sizes[SLUB_CACHE_COUNT - 1]);
        assert(large->page_count > 0);
        assert(large->page_count <= npage - page2ppn(page));
        size_t page_count = large->page_count;
        large->magic = 0;
        free_pages(page, page_count);
        return;
    }

    assert(magic == SLUB_SLAB_MAGIC);
    struct slub_slab *slab = (struct slub_slab *)page_addr;
    unsigned int index = slab->cache_index;
    assert(index < SLUB_CACHE_COUNT);
    struct slub_cache *cache = &slub_caches[index];
    uintptr_t begin = page_addr + SLUB_OBJECT_START;
    uintptr_t address = (uintptr_t)object;
    assert(address >= begin);
    size_t offset = address - begin;
    assert(offset < (size_t)slab->capacity * cache->object_size);
    assert(offset % cache->object_size == 0);
    size_t slot_index = offset / cache->object_size;
    assert(slub_bitmap_is_set(slab, slot_index)); /* never free twice */
    assert(slab->inuse > 0);

    bool was_full = (slab->inuse == slab->capacity);
    slub_bitmap_clear(slab, slot_index);
    *(void **)object = slab->free_head;
    slab->free_head = object;
    --slab->inuse;

    if (was_full) {
        list_del(&slab->link);
        list_add(&cache->partial, &slab->link);
    }
    if (slab->inuse == 0) {
        for (size_t i = 0; i < SLUB_BITMAP_WORDS; ++i) {
            assert(slab->allocated[i] == 0);
        }
        list_del(&slab->link);
        slab->magic = 0;
        free_page(page); /* return an entirely empty slab to the page layer */
    }
}

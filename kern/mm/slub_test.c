#include <slub.h>
#include <pmm.h>
#include <stdio.h>

/*
 * Lab2 Challenge: object-allocation tests independent of the SLUB internals.
 * All test buffers live in .bss to avoid overflowing the 8 KiB kernel stack.
 */

static void *tiny_objects[400];
static void *mixed_objects[144];
static size_t mixed_sizes[144];

static void fill_pattern(void *ptr, size_t n, unsigned char pattern) {
    unsigned char *bytes = (unsigned char *)ptr;
    for (size_t i = 0; i < n; ++i) {
        bytes[i] = (unsigned char)(pattern + i * 13U);
    }
}

static void check_pattern(const void *ptr, size_t n, unsigned char pattern) {
    const unsigned char *bytes = (const unsigned char *)ptr;
    for (size_t i = 0; i < n; ++i) {
        assert(bytes[i] == (unsigned char)(pattern + i * 13U));
    }
}

static void check_alignment(const void *ptr) {
    assert(ptr != NULL && ((uintptr_t)ptr & 15) == 0);
}

static void test_size_boundaries(void) {
    const size_t sizes[] = {
        1, 8, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128,
        129, 255, 256, 257, 511, 512, 513, 1023, 1024, 1025,
        2047, 2048, 2049, 4080, 4081, 4096, 4097, 8192, 12289
    };
    enum { COUNT = sizeof(sizes) / sizeof(sizes[0]) };
    void *objects[COUNT];
    size_t initial = nr_free_pages();
    for (size_t i = 0; i < COUNT; ++i) {
        objects[i] = slub_alloc(sizes[i]);
        check_alignment(objects[i]);
        fill_pattern(objects[i], sizes[i], (unsigned char)(i + 1));
    }
    for (size_t i = COUNT; i > 0; --i) {
        size_t index = i - 1;
        check_pattern(objects[index], sizes[index], (unsigned char)(index + 1));
        slub_free(objects[index]);
    }
    assert(nr_free_pages() == initial);
    cprintf("[SLUB 02] object-size class and boundary requests: PASS\n");
    cprintf("[SLUB 03] 16-byte alignment and object isolation: PASS\n");
    cprintf("[SLUB 04] large objects across physical pages: PASS\n");
}

static void test_many_small(void) {
    size_t initial = nr_free_pages();
    for (size_t i = 0; i < 400; ++i) {
        tiny_objects[i] = slub_alloc(16);
        check_alignment(tiny_objects[i]);
        fill_pattern(tiny_objects[i], 16, (unsigned char)i);
    }
    assert(initial >= nr_free_pages() + 2); /* spans at least two slab pages */
    for (size_t i = 0; i < 400; i += 2) {
        slub_free(tiny_objects[i]);
        tiny_objects[i] = NULL;
    }
    size_t held_pages = nr_free_pages();
    for (size_t i = 1; i < 400; i += 2) {
        check_pattern(tiny_objects[i], 16, (unsigned char)i);
    }
    for (size_t i = 0; i < 400; i += 2) {
        tiny_objects[i] = slub_alloc(16);
        assert(tiny_objects[i] != NULL);
        fill_pattern(tiny_objects[i], 16, (unsigned char)(i ^ 0x5a));
    }
    assert(nr_free_pages() == held_pages); /* reused existing partial slabs */
    for (size_t i = 400; i > 0; --i) {
        size_t index = i - 1;
        check_pattern(tiny_objects[index], 16,
                      (unsigned char)((index & 1) ? index : (index ^ 0x5a)));
        slub_free(tiny_objects[index]);
        tiny_objects[index] = NULL;
    }
    assert(nr_free_pages() == initial);
    cprintf("[SLUB 05] multi-slab full/partial transitions: PASS\n");
    cprintf("[SLUB 06] fragmented object-slot reuse: PASS\n");
}

static void test_mixed_sizes(void) {
    const size_t sizes[] = {
        1, 24, 63, 96, 191, 447, 999, 2048, 2049, 4075, 9000
    };
    size_t initial = nr_free_pages();
    for (size_t i = 0; i < 144; ++i) {
        mixed_sizes[i] = sizes[(i * 7) % (sizeof(sizes) / sizeof(sizes[0]))];
        mixed_objects[i] = slub_alloc(mixed_sizes[i]);
        check_alignment(mixed_objects[i]);
        fill_pattern(mixed_objects[i], mixed_sizes[i], (unsigned char)(i + 7));
    }
    for (size_t i = 0; i < 144; i += 3) {
        check_pattern(mixed_objects[i], mixed_sizes[i], (unsigned char)(i + 7));
        slub_free(mixed_objects[i]);
        mixed_objects[i] = NULL;
    }
    for (size_t i = 0; i < 144; ++i) {
        if (mixed_objects[i] != NULL) {
            check_pattern(mixed_objects[i], mixed_sizes[i], (unsigned char)(i + 7));
            slub_free(mixed_objects[i]);
            mixed_objects[i] = NULL;
        }
    }
    assert(nr_free_pages() == initial);
    cprintf("[SLUB 07] mixed-size interleaving and data integrity: PASS\n");
}

void slub_check(void) {
    size_t initial = nr_free_pages();
    assert(slub_alloc(0) == NULL);
    slub_free(NULL);
    assert(slub_alloc((size_t)-1) == NULL);
    assert(nr_free_pages() == initial);
    cprintf("[SLUB 01] zero-size, NULL free and overflow: PASS\n");

    test_size_boundaries();
    test_many_small();
    test_mixed_sizes();
    assert(nr_free_pages() == initial);
    cprintf("[SLUB 08] all underlying pages recovered: PASS (%lu pages)\n",
            (unsigned long)initial);
    cprintf("SLUB Challenge: 8/8 tests passed\n");
}

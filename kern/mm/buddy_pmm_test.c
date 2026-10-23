#include <buddy_pmm.h>
#include <stdio.h>
#include <string.h>

#define TEST_PAGES 256
static struct Page *test_arena;
static size_t region_begin, region_count;
static unsigned char occupied[TEST_PAGES];
static size_t requested[TEST_PAGES];
static size_t expected_free;
static void (*verify_lists)(void);

static size_t rounded(size_t n) {
    size_t span = 1;
    while (span < n) {
        span *= 2;
    }
    return span;
}

static void check_state(void) {
    assert(buddy_pmm_manager.nr_free_pages() == expected_free);
    verify_lists();
    for (size_t i = 0; i < TEST_PAGES; i++) {
        if (i < region_begin || i >= region_begin + region_count) {
            assert(PageReserved(test_arena + i));
        } else if (occupied[i]) {
            assert(!PageReserved(test_arena + i) && !PageProperty(test_arena + i));
        }
    }
}

static void reset_region(size_t offset, size_t n) {
    for (size_t i = 0; i < TEST_PAGES; i++) {
        assert(requested[i] == 0 && occupied[i] == 0);
    }
    assert(offset + n <= TEST_PAGES && n > 0);
    buddy_pmm_manager.init();
    for (size_t i = 0; i < TEST_PAGES; i++) {
        test_arena[i].flags = 0;
        test_arena[i].property = 0;
        set_page_ref(test_arena + i, 0);
        SetPageReserved(test_arena + i);
        list_init(&test_arena[i].page_link);
    }
    region_begin = offset;
    region_count = n;
    expected_free = n;
    buddy_pmm_manager.init_memmap(test_arena + offset, n);
    check_state();
}

static struct Page *take(size_t n) {
    size_t span = rounded(n);
    struct Page *p = buddy_pmm_manager.alloc_pages(n);
    assert(p != NULL);
    assert(p >= test_arena + region_begin && p < test_arena + region_begin + region_count);
    size_t index = p - test_arena;
    assert(span <= region_begin + region_count - index);
    assert((page2ppn(p) & (span - 1)) == 0);
    assert(p->property == n && requested[index] == 0);
    for (size_t i = 0; i < span; i++) {
        assert(occupied[index + i] == 0);
        occupied[index + i] = 1;
        assert(page_ref(p + i) == 0);
    }
    requested[index] = n;
    assert(expected_free >= span);
    expected_free -= span;
    check_state();
    return p;
}

static void give(struct Page *p) {
    size_t index = p - test_arena;
    assert(index < TEST_PAGES && requested[index] > 0);
    size_t n = requested[index];
    size_t span = rounded(n);
    buddy_pmm_manager.free_pages(p, n);
    for (size_t i = 0; i < span; i++) {
        assert(occupied[index + i]);
        occupied[index + i] = 0;
    }
    requested[index] = 0;
    expected_free += span;
    check_state();
}

static void test_sizes(void) {
    reset_region(0, TEST_PAGES);
    cprintf("[Buddy 01] initialization count: PASS\n");
    const size_t sizes[] = {1, 2, 4, 8, 16, 3, 5, 7};
    struct Page *blocks[8];
    for (size_t i = 0; i < 8; i++) {
        blocks[i] = take(sizes[i]);
    }
    assert(expected_free == TEST_PAGES - (1 + 2 + 4 + 8 + 16 + 4 + 8 + 8));
    cprintf("[Buddy 02] allocate 1 page: PASS\n");
    cprintf("[Buddy 03] allocate 2/4/8/16 pages: PASS\n");
    cprintf("[Buddy 04] allocate 3/5/7 as 4/8/8 pages: PASS\n");
    cprintf("[Buddy 14] rounded occupancy accounting: PASS\n");
    for (size_t i = 8; i > 0; i--) {
        give(blocks[i - 1]);
    }
    assert(expected_free == TEST_PAGES);
}

static void test_split_merge(void) {
    reset_region(0, 16);
    struct Page *blocks[16];
    for (size_t i = 0; i < 16; i++) {
        blocks[i] = take(1);
        assert(blocks[i] == test_arena + i);
    }
    assert(expected_free == 0);
    cprintf("[Buddy 05] split 16-page block to single pages: PASS\n");
    give(blocks[0]);
    give(blocks[1]);
    assert(PageProperty(test_arena) && test_arena->property == 2);
    cprintf("[Buddy 06] identify and merge free buddy: PASS\n");
    for (size_t i = 2; i < 16; i++) {
        give(blocks[i]);
        if (i == 3 || i == 7 || i == 15) {
            assert(PageProperty(test_arena) && test_arena->property == i + 1);
        }
    }
    struct Page *whole = take(16);
    assert(whole == test_arena);
    give(whole);
    cprintf("[Buddy 07] multilevel merge back to 16 pages: PASS\n");
}

static void test_cycles(void) {
    reset_region(0, TEST_PAGES);
    for (size_t round = 0; round < 64; round++) {
        struct Page *a = take(3);
        struct Page *b = take(5);
        struct Page *c = take(1);
        give(b);
        struct Page *d = take(7);
        give(a);
        give(c);
        give(d);
        assert(expected_free == TEST_PAGES);
    }
    cprintf("[Buddy 08] 64 repeated allocation/free cycles: PASS\n");
    cprintf("[Buddy 09] interleaved allocation/free: PASS\n");
}

static void test_exhaustion(void) {
    reset_region(0, TEST_PAGES);
    struct Page *blocks[TEST_PAGES];
    for (size_t i = 0; i < TEST_PAGES; i++) {
        blocks[i] = take(1);
    }
    assert(expected_free == 0);
    assert(buddy_pmm_manager.alloc_pages(1) == NULL);
    assert(buddy_pmm_manager.alloc_pages(3) == NULL);
    check_state();
    for (size_t i = 0; i < TEST_PAGES; i += 2) {
        give(blocks[i]);
    }
    assert(buddy_pmm_manager.alloc_pages(2) == NULL);
    check_state();
    for (size_t i = 1; i < TEST_PAGES; i += 2) {
        give(blocks[i]);
    }
    cprintf("[Buddy 10] exhausted/fragmented requests fail safely: PASS\n");
    cprintf("[Buddy 13] 256 live allocations never overlap: PASS\n");
}

static void test_edges(void) {
    const size_t offsets[] = {1, 0, 5};
    const size_t lengths[] = {16, 19, 27};
    for (size_t scenario = 0; scenario < 3; scenario++) {
        reset_region(offsets[scenario], lengths[scenario]);
        struct Page *blocks[27];
        for (size_t i = 0; i < lengths[scenario]; i++) {
            blocks[i] = take(1);
        }
        assert(buddy_pmm_manager.alloc_pages(1) == NULL);
        for (size_t i = lengths[scenario]; i > 0; i--) {
            give(blocks[i - 1]);
        }
        assert(expected_free == lengths[scenario]);
    }
    reset_region(0, 8);
    region_count = 16;
    expected_free += 8;
    buddy_pmm_manager.init_memmap(test_arena + 8, 8);
    check_state();
    struct Page *joined = take(16);
    give(joined);
    cprintf("[Buddy 11] unaligned initial regions: PASS\n");
    cprintf("[Buddy 12] non-power-of-two regions and adjacent registration: PASS\n");
}

void buddy_run_tests(struct Page *arena, void (*verify)(void)) {
    test_arena = arena;
    verify_lists = verify;
    memset(occupied, 0, sizeof(occupied));
    memset(requested, 0, sizeof(requested));
    test_sizes();
    test_split_merge();
    test_cycles();
    test_exhaustion();
    test_edges();
    for (size_t i = 0; i < TEST_PAGES; i++) {
        assert(requested[i] == 0 && occupied[i] == 0);
    }
    assert(expected_free == region_count);
}

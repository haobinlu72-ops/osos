#include <buddy_pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>

#define BUDDY_MAX_ORDER 18
#define BUDDY_ALLOC (1UL << 2)
#define BUDDY_HEAD (1UL << 3)
static list_entry_t buddy_lists[BUDDY_MAX_ORDER + 1];
static size_t buddy_free_count;

static int request_order(size_t n) {
    if (n == 0 || n > ((size_t)1 << BUDDY_MAX_ORDER)) {
        return -1;
    }
    int order = 0;
    while (((size_t)1 << order) < n) {
        order++;
    }
    return order;
}

static void insert_block(struct Page *base, int order) {
    base->property = (size_t)1 << order;
    SetPageProperty(base);
    list_add(&buddy_lists[order], &base->page_link);
}

static void release_block(struct Page *base, int order) {
    size_t ppn = page2ppn(base);
    while (order < BUDDY_MAX_ORDER) {
        size_t span = (size_t)1 << order;
        size_t other_ppn = ppn ^ span;
        if (other_ppn < nbase || other_ppn >= npage || span > npage - other_ppn) {
            break;
        }
        struct Page *other = pages + (other_ppn - nbase);
        if (!PageProperty(other) || PageReserved(other) || other->property != span) {
            break;
        }
        list_del(&other->page_link);
        ClearPageProperty(other);
        other->property = 0;
        if (other_ppn < ppn) {
            base = other;
            ppn = other_ppn;
        }
        order++;
    }
    insert_block(base, order);
}

static void buddy_init(void) {
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        list_init(&buddy_lists[order]);
    }
    buddy_free_count = 0;
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0 && base >= pages && base < pages + (npage - nbase));
    size_t index = base - pages;
    assert(n <= npage - nbase - index);
    for (size_t i = 0; i < n; i++) {
        assert(PageReserved(base + i));
    }
    for (size_t i = 0; i < n; i++) {
        base[i].flags = 0;
        base[i].property = 0;
        set_page_ref(base + i, 0);
        list_init(&base[i].page_link);
    }
    buddy_free_count += n;
    while (n > 0) {
        int order = 0;
        size_t ppn = page2ppn(base);
        while (order < BUDDY_MAX_ORDER) {
            size_t bigger = (size_t)1 << (order + 1);
            if (bigger > n || (ppn & (bigger - 1)) != 0) {
                break;
            }
            order++;
        }
        size_t span = (size_t)1 << order;
        release_block(base, order);
        base += span;
        n -= span;
    }
}

static struct Page *buddy_alloc_pages(size_t n) {
    int wanted = request_order(n);
    if (wanted < 0) {
        return NULL;
    }
    size_t span = (size_t)1 << wanted;
    if (span > buddy_free_count) {
        return NULL;
    }
    int order = wanted;
    while (order <= BUDDY_MAX_ORDER && list_empty(&buddy_lists[order])) {
        order++;
    }
    if (order > BUDDY_MAX_ORDER) {
        return NULL;
    }
    struct Page *base = le2page(list_next(&buddy_lists[order]), page_link);
    list_del(&base->page_link);
    ClearPageProperty(base);
    while (order > wanted) {
        order--;
        insert_block(base + ((size_t)1 << order), order);
    }
    for (size_t i = 0; i < span; i++) {
        base[i].flags = BUDDY_ALLOC;
        base[i].property = 0;
        set_page_ref(base + i, 0);
    }
    base->flags |= BUDDY_HEAD;
    base->property = n;
    buddy_free_count -= span;
    return base;
}

static void buddy_free_pages(struct Page *base, size_t n) {
    int order = request_order(n);
    assert(order >= 0 && base >= pages && base < pages + (npage - nbase));
    size_t span = (size_t)1 << order;
    assert(span <= npage - nbase - (size_t)(base - pages));
    assert((page2ppn(base) & (span - 1)) == 0);
    assert((base->flags & BUDDY_HEAD) && base->property == n);
    for (size_t i = 0; i < span; i++) {
        assert((base[i].flags & BUDDY_ALLOC) && !PageReserved(base + i));
        assert(!PageProperty(base + i) && page_ref(base + i) == 0);
    }
    for (size_t i = 0; i < span; i++) {
        base[i].flags = 0;
        base[i].property = 0;
    }
    buddy_free_count += span;
    release_block(base, order);
}

static size_t buddy_nr_free_pages(void) {
    return buddy_free_count;
}

static void buddy_validate(void) {
    static unsigned char seen[(PHYSICAL_MEMORY_END - DRAM_BASE) / PGSIZE];
    assert(npage >= nbase && npage - nbase <= sizeof(seen));
    memset(seen, 0, sizeof(seen));
    size_t total = 0;
    size_t nodes = 0;
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        list_entry_t *head = &buddy_lists[order];
        assert(head->next->prev == head && head->prev->next == head);
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            assert(++nodes <= npage - nbase);
            assert(le->next->prev == le && le->prev->next == le);
            struct Page *p = le2page(le, page_link);
            assert(p >= pages && p < pages + (npage - nbase));
            size_t span = (size_t)1 << order;
            assert(PageProperty(p) && !PageReserved(p) && p->property == span);
            assert((page2ppn(p) & (span - 1)) == 0);
            assert(span <= npage - page2ppn(p));
            for (size_t i = 0; i < span; i++) {
                size_t index = (p - pages) + i;
                assert(!seen[index]);
                seen[index] = 1;
                assert(!PageReserved(p + i) && !(p[i].flags & (BUDDY_ALLOC | BUDDY_HEAD)));
                assert(page_ref(p + i) == 0);
                assert(i == 0 || !PageProperty(p + i));
            }
            size_t other_ppn = page2ppn(p) ^ span;
            if (order < BUDDY_MAX_ORDER && other_ppn >= nbase && other_ppn < npage) {
                struct Page *other = pages + (other_ppn - nbase);
                assert(!PageProperty(other) || other->property != span);
            }
            total += span;
        }
    }
    assert(total == buddy_free_count);
}

static void buddy_check(void) {
    buddy_validate();
    size_t initial = buddy_free_count;
    uintptr_t free_begin = ROUNDUP(PADDR(pages + (npage - nbase)), PGSIZE);
    assert(initial == (npage * PGSIZE - free_begin) / PGSIZE);
    struct Page *arena = buddy_alloc_pages(512);
    assert(arena != NULL);
    static struct Page descriptors[512];
    memcpy(descriptors, arena, sizeof(descriptors));
    list_entry_t saved_lists[BUDDY_MAX_ORDER + 1];
    memcpy(saved_lists, buddy_lists, sizeof(saved_lists));
    size_t saved_count = buddy_free_count;
    buddy_run_tests(arena, buddy_validate);
    memcpy(arena, descriptors, sizeof(descriptors));
    memcpy(buddy_lists, saved_lists, sizeof(saved_lists));
    buddy_free_count = saved_count;
    buddy_free_pages(arena, 512);
    assert(buddy_free_count == initial);
    buddy_validate();
    cprintf("[Buddy 15] full capacity restored: PASS (%lu pages)\n", initial);
    cprintf("Buddy System: 15/15 tests passed\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

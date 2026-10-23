#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <buddy_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &best_fit_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

//lab2 function1 2412950

static void page_init(void) {
    uint64_t base = get_memory_base();
    uint64_t size = get_memory_size();
    if (base != DRAM_BASE || size == 0 || size > ~(uint64_t)0 - base) {
        panic("invalid DTB memory range");
    }
    uint64_t ram_end = base + size;
    va_pa_offset = KERNBASE - KERNEL_BEGIN_PADDR;
    uintptr_t limit = ram_end < PHYSICAL_MEMORY_END ? ram_end : PHYSICAL_MEMORY_END;
    limit = ROUNDDOWN(limit, PGSIZE);
    if (limit <= KERNEL_BEGIN_PADDR) {
        panic("RAM does not cover kernel");
    }
    npage = PPN(limit);
    size_t count = npage - nbase;
    extern char end[];
    uintptr_t kernel_end = PADDR(end);
    if (kernel_end < KERNEL_BEGIN_PADDR || kernel_end > limit) {
        panic("kernel outside managed RAM");
    }
    uintptr_t desc_pa = ROUNDUP(kernel_end, PGSIZE);
    if (desc_pa > limit || count > (limit - desc_pa) / sizeof(struct Page)) {
        panic("not enough RAM for Page descriptors");
    }
    pages = (struct Page *)(desc_pa + va_pa_offset);
    for (size_t i = 0; i < count; i++) {
        pages[i].flags = 0;
        pages[i].property = 0;
        set_page_ref(&pages[i], 0);
        SetPageReserved(&pages[i]);
        list_init(&pages[i].page_link);
    }
    uintptr_t free_begin = ROUNDUP(desc_pa + count * sizeof(struct Page), PGSIZE);
    cprintf("physical memory: [0x%016lx, 0x%016lx)\n", base, ram_end);
    cprintf("managed memory ends at 0x%016lx; free begins at 0x%016lx\n", limit, free_begin);
    if (free_begin < limit) {
        init_memmap(pa2page(free_begin), (limit - free_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}

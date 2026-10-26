// 伙伴系统实现与其他分配器共享接口，但不共享空闲链表。
#ifndef __KERN_MM_BUDDY_PMM_H__
#define __KERN_MM_BUDDY_PMM_H__
#include <pmm.h> // 引入管理器函数表定义
extern const struct pmm_manager buddy_pmm_manager; // 供 pmm.c 在构建时选择
// 内部自检入口：arena 是已从真实内存取出的 256 页测试区，verify 核对各阶链表不变量。
void buddy_run_tests(struct Page *arena, void (*verify)(void)); // 仅由 Buddy 的 check 调用，不修改其他管理器
#endif

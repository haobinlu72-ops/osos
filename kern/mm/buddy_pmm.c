#include <buddy_pmm.h> // 通用分配器接口及页描述符
#include <list.h> // 使用每个 Page 内嵌的双向链表节点
#include <string.h> // 自检快照与重叠检测使用项目自己的内存操作函数
#include <stdio.h> // 输出真实完成的测试结果

/* 0 阶为 1 页，18 阶为 1GiB，足以覆盖本项目直接映射窗口。
 * free Page 的 property 记录块页数；allocated 块头的 property 记录原请求页数。
 * 例如申请 3 页：取 4 页块，内部碎片为 1 页；必须 free_pages(base, 3)。
 * 只支持整笔释放，不支持 First/Best-Fit 那样拆开释放一笔申请。
 * 页号使用绝对物理页号：ppn XOR (1<<order)，不能假设可用区从第 0 页开始。
 */
#define BUDDY_MAX_ORDER 18 // 最大块的页数为 2^18，移位不超出 size_t
#define BUDDY_ALLOC (1UL << 2) // 每个已分配页的私有状态位，用于拒绝重复释放
#define BUDDY_HEAD (1UL << 3) // 仅分配块头设置，拒绝释放内部页
static list_entry_t buddy_lists[BUDDY_MAX_ORDER + 1]; // 每阶单独一个哨兵，绝不复用其他管理器的 free_list
static size_t buddy_free_count; // 统计可分配页数，申请 3 页按 4 页扣除

/* request_order：输入正页数 n，返回向上取整的阶数；超出支持大小返回 -1。
 * alloc/free 共用此函数，保证计算出的实际块大小一致；无状态副作用。
 */
static int request_order(size_t n) {
    if (n == 0 || n > ((size_t)1 << BUDDY_MAX_ORDER)) { // 先限制范围，防止移位或取整溢出
        return -1; // 不可表示的请求交给调用者处理
    }
    int order = 0; // 从单页块开始寻找
    while (((size_t)1 << order) < n) { // 直到块能覆盖请求的所有页
        order++; // 每升一阶，块大小翻倍
    }
    return order; // 例如 n=3 返回 2，即 4 页
}

/* insert_block：将已经清理的块挂到指定阶，维护空闲块头标记。
 * 参数 base 为块头，order 为阶数；无返回值，不调整总页数，避免拆分/合并重复计数。
 */
static void insert_block(struct Page *base, int order) {
    base->property = (size_t)1 << order; // 空闲块头记录连续页数，不记录阶数
    SetPageProperty(base); // 使伙伴查找能识别空闲块头
    list_add(&buddy_lists[order], &base->page_link); // 同阶内无需按地址排序
}

/* release_block：回收一个 2^order 页块，递归式向上合并；无返回值。
 * 不变量：同阶伙伴必须空闲、块长相等且落在描述符范围内。
 * 例如释放物理页号 8 的 4 页块，伙伴为 8 XOR 4=12，合并后变成 8 页块。
 * 调用者先清除分配标志；本函数只维护块形状，不改变总空闲计数。
 */
static void release_block(struct Page *base, int order) {
    size_t ppn = page2ppn(base); // 使用物理页号，而非相对可用区起点的偏移
    while (order < BUDDY_MAX_ORDER) { // 顶阶不能再扩大
        size_t span = (size_t)1 << order; // 当前块包含的页数
        size_t other_ppn = ppn ^ span; // 翻转此阶对应位得到唯一伙伴
        if (other_ppn < nbase || other_ppn >= npage || span > npage - other_ppn) { // 短路判断保护下界和末尾
            break; // 伙伴超出管理范围时保留当前块
        }
        struct Page *other = pages + (other_ppn - nbase); // 边界确认后才构造描述符指针
        if (!PageProperty(other) || PageReserved(other) || other->property != span) { // 空闲但不同阶也不能合并
            break; // 伙伴正被使用、未注册或已被更大块包含
        }
        list_del(&other->page_link); // 先摘除伙伴旧节点，防止一块内存存在于两个阶中
        ClearPageProperty(other); // 原伙伴头现在可能变为合并块的内部页
        other->property = 0; // 清除过期长度，辅助排查状态错误
        if (other_ppn < ppn) { // 合并块必须从两个伙伴中较低的地址开始
            base = other; // 更新描述符块头
            ppn = other_ppn; // 同步更新下一轮 XOR 使用的页号
        }
        order++; // 两个同阶块合成一个高阶块
    }
    insert_block(base, order); // 不能继续合并时，只有最终块头进入链表
}

/* buddy_init：无参数/返回值；pmm_init 在注册任何 RAM 前调用。
 * 清空每阶哨兵和统计；不能在存在活动分配时重新调用。
 */
static void buddy_init(void) {
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) { // 初始化全部阶，包括最大阶
        list_init(&buddy_lists[order]); // 每个哨兵形成独立的空环
    }
    buddy_free_count = 0; // 尚无注册页面
}

/* buddy_init_memmap：注册 base 开始的 n 个保留页，无返回值，由 page_init 调用。
 * 先核对整个区间，再解除保留；贪心选取地址对齐且不越界的最大幂次块。
 * 非对齐页号 5、长度 7 可分为 [5,6)、[6,8)、[8,12)，无需丢弃边缘页面。
 * 重复注册、越界和零长度属于调用错误，由 assert 拒绝。
 */
static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0 && base >= pages && base < pages + (npage - nbase)); // 先保证起点合法
    size_t index = base - pages; // 将指针变成受管理数组内下标
    assert(n <= npage - nbase - index); // 用减法核对长度，防止 base+n 越界
    for (size_t i = 0; i < n; i++) { // 先完整验证，避免失败时只注册一半
        assert(PageReserved(base + i)); // 只有初始保留区允许首次注册
    }
    for (size_t i = 0; i < n; i++) { // 验证通过后统一清理描述符
        base[i].flags = 0; // 解除保留且清掉私有分配位
        base[i].property = 0; // 内部页无独立块长度
        set_page_ref(base + i, 0); // 空闲页没有引用
        list_init(&base[i].page_link); // 清除初始节点状态
    }
    buddy_free_count += n; // 每个注册页只计数一次
    while (n > 0) { // 将非幂次区间分解为若干合法伙伴块
        int order = 0; // 单页总能对齐
        size_t ppn = page2ppn(base); // 对齐由物理页号决定
        while (order < BUDDY_MAX_ORDER) { // 逐级尝试更大的块
            size_t bigger = (size_t)1 << (order + 1); // 候选块页数为下一阶
            if (bigger > n || (ppn & (bigger - 1)) != 0) { // 块必须既放得下又按块长对齐
                break; // 否则当前阶就是从此起点可取的最大块
            }
            order++; // 满足条件时继续扩大候选
        }
        size_t span = (size_t)1 << order; // 记录本轮注册的原块长度
        release_block(base, order); // 可与先前独立注册的相邻伙伴合并
        base += span; // 下轮从尚未处理的第一页开始
        n -= span; // 只扣除本轮范围，不扣合并前已注册的页
    }
}

/* buddy_alloc_pages：申请 n 页，实际占用向上取整的幂次块；返回块头或 NULL。
 * 从所需阶往上寻找，摘下一个大块后反复平分，只将右半块放回空闲表。
 * 例：申请 3 页，若仅有 16 页块，拆为 8+8，再拆为 4+4，交付左侧 4 页。
 */
static struct Page *buddy_alloc_pages(size_t n) {
    int wanted = request_order(n); // 将原请求转换为目标阶
    if (wanted < 0) { // 零长度或超大请求都不能分配
        return NULL; // 保持所有空闲状态不变
    }
    size_t span = (size_t)1 << wanted; // 实际占用页数，含内部碎片
    if (span > buddy_free_count) { // 总量不足时提前失败
        return NULL; // 不修改链表
    }
    int order = wanted; // 从最小合适阶开始
    while (order <= BUDDY_MAX_ORDER && list_empty(&buddy_lists[order])) { // 短路判断避免数组越界
        order++; // 没有此阶块则寻找可拆分的更大块
    }
    if (order > BUDDY_MAX_ORDER) { // 总量足够也可能没有连续的对齐大块
        return NULL; // 这是分配失败，不代表空闲计数错误
    }
    struct Page *base = le2page(list_next(&buddy_lists[order]), page_link); // 取得该阶任意一个块头
    list_del(&base->page_link); // 原大块即将被分配或拆分
    ClearPageProperty(base); // 分配路径中的块不能继续被识别为空闲头
    while (order > wanted) { // 逐级拆到最小合适阶
        order--; // 两个子块的阶均比父块低一阶
        insert_block(base + ((size_t)1 << order), order); // 右半块入空闲表，左半块继续拆
    }
    for (size_t i = 0; i < span; i++) { // 包括内部碎片在内全部标记为已占用
        base[i].flags = BUDDY_ALLOC; // 覆盖残留空闲块头位
        base[i].property = 0; // 内部页不得被当成独立分配块头
        set_page_ref(base + i, 0); // 分配器不替使用者增加引用
    }
    base->flags |= BUDDY_HEAD; // 只有此地址允许执行整笔释放
    base->property = n; // 记住原请求，拒绝错误的释放长度
    buddy_free_count -= span; // 按真实占用扣除，不能只扣 n 页
    return base; // 调用者可使用前 n 页
}

/* buddy_free_pages：释放原申请 base,n，无返回值；错误调用触发 assert。
 * 整笔检查通过后清除分配位，按原阶回收并查找伙伴，统计仅加实际占用一次。
 */
static void buddy_free_pages(struct Page *base, size_t n) {
    int order = request_order(n); // 与分配时采用相同的取整规则
    assert(order >= 0 && base >= pages && base < pages + (npage - nbase)); // 拒绝非法阶和起点
    size_t span = (size_t)1 << order; // 实际需要释放的幂次页数
    assert(span <= npage - nbase - (size_t)(base - pages)); // 保证后续扫描不越界
    assert((page2ppn(base) & (span - 1)) == 0); // 合法分配块必须按自己的大小对齐
    assert((base->flags & BUDDY_HEAD) && base->property == n); // 只能使用原始块头及原请求长度释放
    for (size_t i = 0; i < span; i++) { // 修改前先验证每一页
        assert((base[i].flags & BUDDY_ALLOC) && !PageReserved(base + i)); // 拒绝重复释放或误释放保留页
        assert(!PageProperty(base + i) && page_ref(base + i) == 0); // 调用者应先解除引用
    }
    for (size_t i = 0; i < span; i++) { // 已完成验证，可以统一清理状态
        base[i].flags = 0; // 清除占用位和分配块头位
        base[i].property = 0; // 旧请求长度不再有效
    }
    buddy_free_count += span; // 归还包含内部碎片的完整块
    release_block(base, order); // 尽可能合并同阶空闲伙伴
}

/* buddy_nr_free_pages：无参数，返回真实空闲页数，复杂度 O(1)。 */
static size_t buddy_nr_free_pages(void) {
    return buddy_free_count; // 已分配块中的内部碎片不计为空闲
}

/* buddy_validate：无参数/返回值，供启动检查和每次测试操作后调用。
 * 不仅加总页数，还核对链表双向关系、块范围、描述符状态、块间不重叠及伙伴已充分合并。
 * 用静态数组避免占用仅 8KiB 的内核栈；遍历步数受物理页数限制，损坏的环不会无限运行。
 */
static void buddy_validate(void) {
    static unsigned char seen[(PHYSICAL_MEMORY_END - DRAM_BASE) / PGSIZE]; // 每个受管理页一个标记，独立检测重复覆盖
    assert(npage >= nbase && npage - nbase <= sizeof(seen)); // 管理范围必须能被检查数组完整覆盖
    memset(seen, 0, sizeof(seen)); // 每次检查重新统计，不能沿用上次空闲布局
    size_t total = 0; // 累加各阶块包含的页数
    size_t nodes = 0; // 记录节点数，限制损坏链表的遍历时间
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) { // 检查全部阶
        list_entry_t *head = &buddy_lists[order]; // 此阶的哨兵
        assert(head->next->prev == head && head->prev->next == head); // 空表与非空表的哨兵都要保持双向闭环
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) { // 遍历此阶所有空闲块
            assert(++nodes <= npage - nbase); // 一个块至少一页，节点数不可能超过描述符数
            assert(le->next->prev == le && le->prev->next == le); // 摘链或插链错误会破坏邻居的反向指针
            struct Page *p = le2page(le, page_link); // 找回块头描述符
            assert(p >= pages && p < pages + (npage - nbase)); // 只有管理数组中的描述符才可作为空闲块头
            size_t span = (size_t)1 << order; // 此阶预期长度
            assert(PageProperty(p) && !PageReserved(p) && p->property == span); // 标志和块长必须匹配
            assert((page2ppn(p) & (span - 1)) == 0); // 所有块都以物理页号对齐
            assert(span <= npage - page2ppn(p)); // 块尾不能越过管理范围
            for (size_t i = 0; i < span; i++) { // 检查整块而不只检查头页
                size_t index = (p - pages) + i; // 将物理页对应到检查数组
                assert(!seen[index]); // 两个空闲块绝不能覆盖同一页
                seen[index] = 1; // 标记这一页已由某个空闲块描述
                assert(!PageReserved(p + i) && !(p[i].flags & (BUDDY_ALLOC | BUDDY_HEAD))); // 空闲页不能同时处于保留或已分配状态
                assert(page_ref(p + i) == 0); // 空闲页必须没有使用者引用
                assert(i == 0 || !PageProperty(p + i)); // 内部页不能伪装成另一个空闲块头
            }
            size_t other_ppn = page2ppn(p) ^ span; // 检查是否遗留本应合并的同阶伙伴
            if (order < BUDDY_MAX_ORDER && other_ppn >= nbase && other_ppn < npage) { // 顶阶不再合并，且必须先确认伙伴边界
                struct Page *other = pages + (other_ppn - nbase); // 先算合法数组下标，再做指针加法，避免产生越界的中间指针
                assert(!PageProperty(other) || other->property != span); // 两个同阶空闲伙伴不应同时留在表中
            }
            total += span; // 每块只计算一次
        }
    }
    assert(total == buddy_free_count); // 链表总量必须等于维护的计数
}

/* buddy_check：无参数/返回值，由 pmm_init 经管理器函数表调用。
 * 目的：在真实 RAM 上执行独立 15 项测试，结束后恢复原空闲容量和规范块布局。
 * 先正常申请 512 页，再保存外部链表及该分配的描述符；测试只重新注册其中的前 256 页。
 * 后半 256 页保持已分配，阻止沙箱顶阶块与被快照隔离的外部空闲伙伴合并。
 * 快照恢复只在全部断言通过后发生，不会吞掉失败、跳过释放验证或伪造测试结果。
 */
static void buddy_check(void) {
    buddy_validate(); // 首先确认启动注册的真实空闲表没有损坏
    size_t initial = buddy_free_count; // 记住从真实启动内存得到的可用容量
    uintptr_t free_begin = ROUNDUP(PADDR(pages + (npage - nbase)), PGSIZE); // 独立从描述符末尾推导 page_init 注册的真实起点
    assert(initial == (npage * PGSIZE - free_begin) / PGSIZE); // 启动总量必须与实际可用物理范围相符
    struct Page *arena = buddy_alloc_pages(512); // 正常申请两个 256 页半块，后半块作为不参与测试的已分配伙伴
    assert(arena != NULL); // 默认 128MiB 实验环境必须能够提供此测试区
    static struct Page descriptors[512]; // 放在 BSS，避免 512 张描述符挤爆内核栈
    memcpy(descriptors, arena, sizeof(descriptors)); // 保存外层真实分配的状态，供隔离测试结束后恢复
    list_entry_t saved_lists[BUDDY_MAX_ORDER + 1]; // 各阶哨兵副本仅保存链接，不复制任何外部页
    memcpy(saved_lists, buddy_lists, sizeof(saved_lists)); // 节点仍指向原哨兵地址，恢复时需原位复制回来
    size_t saved_count = buddy_free_count; // 隔离期间外部空闲页不参与测试计数
    buddy_run_tests(arena, buddy_validate); // 测试文件通过真实管理器接口运行全部场景
    memcpy(arena, descriptors, sizeof(descriptors)); // 所有隔离分配已释放，恢复外层 512 页分配描述符
    memcpy(buddy_lists, saved_lists, sizeof(saved_lists)); // 原位恢复哨兵，外部节点地址关系重新生效
    buddy_free_count = saved_count; // 恢复外层尚未归还 arena 时的空闲数量
    buddy_free_pages(arena, 512); // 正常释放外层分配，检查它能与真实 RAM 中的伙伴继续合并
    assert(buddy_free_count == initial); // 测试结束后必须恢复真实初始容量
    buddy_validate(); // 再检查完整真实空闲表，验证恢复没有造成链表、状态或合并错误
    cprintf("[Buddy 15] full capacity restored: PASS (%lu pages)\n", initial); // 仅在真实容量和结构都恢复后报告最后一项
    cprintf("Buddy System: 15/15 tests passed\n"); // 每项断言实际执行完毕后才输出总结果
}

const struct pmm_manager buddy_pmm_manager = { // 注册独立伙伴系统函数表
    .name = "buddy_pmm_manager", // 用于启动时识别所选算法
    .init = buddy_init, // 初始化各阶链表
    .init_memmap = buddy_init_memmap, // 分解并注册非对齐可用区间
    .alloc_pages = buddy_alloc_pages, // 幂次取整并逐阶拆分
    .free_pages = buddy_free_pages, // 检查整笔释放并合并伙伴
    .nr_free_pages = buddy_nr_free_pages, // 查询真实剩余页数
    .check = buddy_check, // 执行隔离行为测试并验证真实空闲状态完整恢复
};

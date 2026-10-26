#include <buddy_pmm.h> // 测试始终调用真实 Buddy 函数表，不复制分配算法
#include <stdio.h> // 将每项已完成测试打印到 QEMU 串口
#include <string.h> // 清零独立的预期占用记录

#define TEST_PAGES 256 // 外层 buddy_check 保证这 256 页已被独占申请
static struct Page *test_arena; // 当前测试沙箱的真实描述符起点
static size_t region_begin, region_count; // 本轮注册的子区间，用于核对边界和保护页
static unsigned char occupied[TEST_PAGES]; // 独立逐页位图，核对实际取整块是否重叠
static size_t requested[TEST_PAGES]; // 每个成功块头记录原申请长度，不能用取整后的长度释放
static size_t expected_free; // 测试侧独立计算应剩余多少页
static void (*verify_lists)(void); // 由实现提供结构核对，不参与分配或释放决策

/* rounded：测试侧通过翻倍独立计算占用页数，而不读取实现的 request_order。
 * 参数 n 为正申请页数，返回最小的覆盖 n 的 2 的幂；用于发现只扣 n 页的统计错误。
 */
static size_t rounded(size_t n) {
    size_t span = 1; // 最小物理分配块是一页
    while (span < n) { // 例如 3 页需要继续翻倍直到 4
        span *= 2; // 测试请求都很小，不会触及整数溢出
    }
    return span; // 返回真实应被占用的完整块长度
}

/* check_state：每次测试操作后核对计数、空闲链表和沙箱保护页。
 * 目的：发现操作表面成功但破坏全局状态的问题；正常时全部断言通过，无返回值。
 */
static void check_state(void) {
    assert(buddy_pmm_manager.nr_free_pages() == expected_free); // 计数必须符合测试侧独立维护的语义
    verify_lists(); // 检查各阶链表、空闲块重叠和未合并伙伴
    for (size_t i = 0; i < TEST_PAGES; i++) { // 核对沙箱中每一页的已分配状态
        if (i < region_begin || i >= region_begin + region_count) { // 未注册区域充当边界保护页
            assert(PageReserved(test_arena + i)); // 注册、拆分和合并都不应越过边界
        } else if (occupied[i]) { // 测试侧认为正在使用的页不能被实现标为空闲或保留
            assert(!PageReserved(test_arena + i) && !PageProperty(test_arena + i)); // 覆盖非幂次请求的填充页
        }
    }
}

/* reset_region：构造可重复的小空闲区，测试初始化及边缘区间处理。
 * 参数 offset,n 表示 arena 内的子区间；正常时只注册 n 页、周围仍保留。
 * 仅允许在上轮所有成功申请都已释放后调用，不能靠重置掩盖丢页。
 */
static void reset_region(size_t offset, size_t n) {
    for (size_t i = 0; i < TEST_PAGES; i++) { // 先核对上一轮已无活动分配
        assert(requested[i] == 0 && occupied[i] == 0); // 任何漏释放都在重置之前失败
    }
    assert(offset + n <= TEST_PAGES && n > 0); // 所有子区间必须位于独占测试区内部
    buddy_pmm_manager.init(); // 此时旧沙箱空闲表可安全清空，外层真实空闲表另有快照
    for (size_t i = 0; i < TEST_PAGES; i++) { // 模拟 page_init 把初始页面设为保留
        test_arena[i].flags = 0; // 清除上一轮沙箱中的状态位
        test_arena[i].property = 0; // 防止上一轮块长干扰本轮注册
        set_page_ref(test_arena + i, 0); // 新注册的页没有引用
        SetPageReserved(test_arena + i); // 未注册的边缘页必须始终不可分配
        list_init(&test_arena[i].page_link); // 每次从合法的独立链表节点开始
    }
    region_begin = offset; // 记住期望可用起点
    region_count = n; // 记住本轮完整可用页数
    expected_free = n; // 注册成功后空闲页数应正好为 n
    buddy_pmm_manager.init_memmap(test_arena + offset, n); // 使用真实初始化算法处理对齐和长度
    check_state(); // 立即核对初始计数与边界保护
}

/* take：申请 n 页，逐页标记向上取整的完整块并检查边界和重复覆盖。
 * 正常应返回合法块头，空闲计数减少 rounded(n)；失败申请由专门失败测试直接调用接口。
 */
static struct Page *take(size_t n) {
    size_t span = rounded(n); // 独立算出实际应占用页数
    struct Page *p = buddy_pmm_manager.alloc_pages(n); // 运行真实的选阶和拆分路径
    assert(p != NULL); // 此辅助函数用于预期一定成功的申请
    assert(p >= test_arena + region_begin && p < test_arena + region_begin + region_count); // 不能分配保护页或外部页
    size_t index = p - test_arena; // 转为测试位图下标
    assert(span <= region_begin + region_count - index); // 检查包含内部碎片的块尾，而非只检查 n 页
    assert((page2ppn(p) & (span - 1)) == 0); // Buddy 块必须以真实物理页号对齐
    assert(p->property == n && requested[index] == 0); // 分配块头应保存原申请长度
    for (size_t i = 0; i < span; i++) { // 每一页都检查不与先前成功分配重叠
        assert(occupied[index + i] == 0); // 即使重叠发生在填充页中也必须失败
        occupied[index + i] = 1; // 记录完整块正在使用
        assert(page_ref(p + i) == 0); // 新分配页引用计数应为零
    }
    requested[index] = n; // 保存释放所需的原请求长度
    assert(expected_free >= span); // 防止测试侧统计下溢掩盖错误
    expected_free -= span; // 申请 3 页扣 4 页，申请 5 或 7 页扣 8 页
    check_state(); // 每次申请后都验证结构和统计
    return p; // 交给场景函数保存并按原请求释放
}

/* give：按 take 记录的原请求释放，核对真实释放和合并后容量。
 * 参数 p 必须是活动块头；正常应清除位图并加回完整取整块，不能漏掉内部碎片。
 */
static void give(struct Page *p) {
    size_t index = p - test_arena; // 块头对应独立请求记录
    assert(index < TEST_PAGES && requested[index] > 0); // 测试自身也拒绝重复释放
    size_t n = requested[index]; // 使用原请求页数，而不是 property 或取整页数作为释放参数
    size_t span = rounded(n); // 用于核对完整回收的容量
    buddy_pmm_manager.free_pages(p, n); // 运行真实伙伴寻找与多级合并
    for (size_t i = 0; i < span; i++) { // 清除这个申请覆盖的全部页
        assert(occupied[index + i]); // 此前必须确实被此申请占用
        occupied[index + i] = 0; // 之后的申请可以重新使用此页
    }
    requested[index] = 0; // 标记该笔申请已完成释放
    expected_free += span; // 内部碎片也应同时归还
    check_state(); // 合并后的链表和总量必须马上自洽
}

/* test_sizes：验证单页、2/4/8/16 页和 3/5/7 页的实际分配语义。
 * 这些请求同时存活可检查互不重叠；全部释放后应恢复 256 页，覆盖第 1 至 4、14 项。
 */
static void test_sizes(void) {
    reset_region(0, TEST_PAGES); // 从已知容量开始，防止拿错初始化基准
    cprintf("[Buddy 01] initialization count: PASS\n"); // 注册后已经由 check_state 验证精确页数
    const size_t sizes[] = {1, 2, 4, 8, 16, 3, 5, 7}; // 同时覆盖各阶和三种非幂次请求
    struct Page *blocks[8]; // 保存所有活动申请，使其互相构成重叠检查对照
    for (size_t i = 0; i < 8; i++) { // 在同一空闲区连续申请各类大小
        blocks[i] = take(sizes[i]); // 每次都核对对齐、完整块边界、统计和不重叠
    }
    assert(expected_free == TEST_PAGES - (1 + 2 + 4 + 8 + 16 + 4 + 8 + 8)); // 独立列出总占用 51 页
    cprintf("[Buddy 02] allocate 1 page: PASS\n"); // 单页已实际分配
    cprintf("[Buddy 03] allocate 2/4/8/16 pages: PASS\n"); // 各阶申请均已实际成功
    cprintf("[Buddy 04] allocate 3/5/7 as 4/8/8 pages: PASS\n"); // 非幂次占用由逐次和总量断言共同确认
    cprintf("[Buddy 14] rounded occupancy accounting: PASS\n"); // 不是把原申请页数直接相加
    for (size_t i = 8; i > 0; i--) { // 按逆序回收，促使拆出的伙伴重新相遇
        give(blocks[i - 1]); // 以原申请页数正常归还
    }
    assert(expected_free == TEST_PAGES); // 所有成功申请必须恢复本轮容量
}

/* test_split_merge：一个 16 页块拆为 16 个单页，逐对释放并检查 2、4、8、16 页块可重新申请。
 * 只有容量相等还不能证明合并，因此逐级检查块头标记/长度，并最终再次申请完整 16 页。
 * 正常逐级恢复原块，验证第 5、6、7 项；每个活动单页也参与不重叠检查。
 */
static void test_split_merge(void) {
    reset_region(0, 16); // 物理起点来自 256 页对齐 arena，故也是 16 页对齐
    struct Page *blocks[16]; // 同时保持十六笔单页申请
    for (size_t i = 0; i < 16; i++) { // 迫使同一个 16 页大块反复拆分直到单页
        blocks[i] = take(1); // 从唯一大块派生，不可能靠其他区域满足
        assert(blocks[i] == test_arena + i); // 当前确定性左半块拆分应依次覆盖这十六页
    }
    assert(expected_free == 0); // 整个大块已被拆完并占满
    cprintf("[Buddy 05] split 16-page block to single pages: PASS\n"); // 拆分路径已实际走完
    give(blocks[0]); // 先释放页号最低的单页
    give(blocks[1]); // 再释放 XOR 1 的伙伴，应形成 2 页块
    assert(PageProperty(test_arena) && test_arena->property == 2); // 不仅核对计数，还验证真实合并块长
    cprintf("[Buddy 06] identify and merge free buddy: PASS\n"); // 相邻单页已按伙伴关系合并
    for (size_t i = 2; i < 16; i++) { // 继续释放，触发多轮向上合并
        give(blocks[i]); // 每次都核对不留下同阶空闲伙伴
        if (i == 3 || i == 7 || i == 15) { // 完成 4、8、16 页前缀时应形成更高阶块
            assert(PageProperty(test_arena) && test_arena->property == i + 1); // 验证真实多级合并而非只加计数
        }
    }
    struct Page *whole = take(16); // 只有完整恢复大块才可满足此申请
    assert(whole == test_arena); // 完整块必须从原起点返回
    give(whole); // 该笔验证申请也必须释放
    cprintf("[Buddy 07] multilevel merge back to 16 pages: PASS\n"); // 大块已重新申请并归还
}

/* test_cycles：重复分配/释放以及交错释放，验证第 8、9 项。
 * 反复轮转可暴露旧节点残留、重复入链和统计漂移；每轮最终应恢复原容量。
 */
static void test_cycles(void) {
    reset_region(0, TEST_PAGES); // 使用完整测试区减少正常申请失败的干扰
    for (size_t round = 0; round < 64; round++) { // 多轮重复，验证状态不会逐渐漂移
        struct Page *a = take(3); // 同时保留不同阶申请制造可合并与不可合并的边界
        struct Page *b = take(5); // 实际占 8 页，与 a 的阶不同
        struct Page *c = take(1); // 单页插入其间
        give(b); // 先归还中间分配，制造空洞
        struct Page *d = take(7); // 再从现有空闲表申请 8 页实际块
        give(a); // 不按申请顺序释放，避免测试只覆盖栈式回收
        give(c); // 归还单页，可能触发多级合并
        give(d); // 最后归还复用块
        assert(expected_free == TEST_PAGES); // 每一轮结束就检查恢复，不能只在最后检查
    }
    cprintf("[Buddy 08] 64 repeated allocation/free cycles: PASS\n"); // 全部轮次已完成
    cprintf("[Buddy 09] interleaved allocation/free: PASS\n"); // 每轮均包含制造空洞后再申请
}

/* test_exhaustion：耗尽区域后申请必须失败，且失败不能修改状态，验证第 10、13 项。
 * 全部 256 页同时作为单页存活，位图检查任意两笔是否重叠；奇偶交错回收后应恢复容量。
 */
static void test_exhaustion(void) {
    reset_region(0, TEST_PAGES); // 从精确已知的总页数开始耗尽
    struct Page *blocks[TEST_PAGES]; // 保存所有成功申请，以保证每一笔都能被释放
    for (size_t i = 0; i < TEST_PAGES; i++) { // 每次只申请一页，最终应恰好成功 256 次
        blocks[i] = take(1); // 位图对所有活动页做独立重叠检查
    }
    assert(expected_free == 0); // 真实总量必须已耗尽
    assert(buddy_pmm_manager.alloc_pages(1) == NULL); // 即使申请最小块也必须失败
    assert(buddy_pmm_manager.alloc_pages(3) == NULL); // 非幂次请求同样不能越过空闲总量
    check_state(); // 失败不得改变链表或统计
    for (size_t i = 0; i < TEST_PAGES; i += 2) { // 先只释放偶数页，伙伴仍在使用
        give(blocks[i]); // 检查不能错误地与已分配伙伴合并
    }
    assert(buddy_pmm_manager.alloc_pages(2) == NULL); // 总量有 128 页，但没有一个空闲 2 页伙伴块
    check_state(); // 连续块不足的失败路径也不能破坏状态
    for (size_t i = 1; i < TEST_PAGES; i += 2) { // 再释放其余伙伴，重新合成大块
        give(blocks[i]); // 核对每一步回收和合并
    }
    cprintf("[Buddy 10] exhausted/fragmented requests fail safely: PASS\n"); // 同时覆盖总量不足和没有合适连续块
    cprintf("[Buddy 13] 256 live allocations never overlap: PASS\n"); // 256 笔同时存活期间均通过逐页位图检查
}

/* test_edges：分别注册非对齐起点和非幂次长度区间，验证第 11、12 项。
 * 单页耗尽可证明没有丢弃边缘页；保护页与占用位图可发现向区间外扩展或重叠。
 * 再分两段注册一个完整伙伴块，正常应跨注册边界合并，不能被人为起点偏移干扰。
 */
static void test_edges(void) {
    const size_t offsets[] = {1, 0, 5}; // 第一种只改变起点，第二种只改变长度，第三种同时改变
    const size_t lengths[] = {16, 19, 27}; // 全部区域都落在 256 页独占沙箱内
    for (size_t scenario = 0; scenario < 3; scenario++) { // 独立验证三种边缘情形
        reset_region(offsets[scenario], lengths[scenario]); // 用真实 init_memmap 分解不规则区间
        struct Page *blocks[27]; // 最大场景仅有 27 页
        for (size_t i = 0; i < lengths[scenario]; i++) { // 逐页耗尽，确认边缘页没有被丢掉
            blocks[i] = take(1); // 每笔申请都必须严格落在注册范围内
        }
        assert(buddy_pmm_manager.alloc_pages(1) == NULL); // 成功次数应精确等于注册页数
        for (size_t i = lengths[scenario]; i > 0; i--) { // 逆序释放，覆盖不同伙伴相遇顺序
            give(blocks[i - 1]); // 所有成功申请都按原长度归还
        }
        assert(expected_free == lengths[scenario]); // 不规则区域的容量也必须完整恢复
    }
    reset_region(0, 8); // 先只注册一个 16 页父块的左半部分
    region_count = 16; // 将即将注册的右半块加入测试侧边界范围
    expected_free += 8; // 新注册的 8 页应直接计入总量
    buddy_pmm_manager.init_memmap(test_arena + 8, 8); // 连续第二次注册，伙伴应与首段合并
    check_state(); // 验证第二次注册后的链表及计数
    struct Page *joined = take(16); // 跨两个注册调用形成的大块应确实可分配
    give(joined); // 保证此额外测试申请也被回收
    cprintf("[Buddy 11] unaligned initial regions: PASS\n"); // 起点偏移及区间保护断言均通过
    cprintf("[Buddy 12] non-power-of-two regions and adjacent registration: PASS\n"); // 长度处理与跨段伙伴合并均已验证
}

/* buddy_run_tests：由真实 Buddy 自检调用，参数为独占测试区及结构检查回调。
 * 依次执行全部场景；正常结束时不存在活动申请，最后由外层验证完整真实容量恢复。
 */
void buddy_run_tests(struct Page *arena, void (*verify)(void)) {
    test_arena = arena; // 测试不假定可用 RAM 从第零页开始
    verify_lists = verify; // 每次测试操作后都调用实现侧结构检查
    memset(occupied, 0, sizeof(occupied)); // 建立测试侧独立的初始空占用状态
    memset(requested, 0, sizeof(requested)); // 初始没有成功申请记录
    test_sizes(); // 验证初始化、常见幂次和非幂次申请
    test_split_merge(); // 验证大块拆分和逐阶伙伴合并
    test_cycles(); // 验证重复及交错操作不会累积错误
    test_exhaustion(); // 验证耗尽、碎片失败和大量同时申请不重叠
    test_edges(); // 验证不规则起点、长度和多段注册
    for (size_t i = 0; i < TEST_PAGES; i++) { // 返回外层前核对每笔成功申请都已释放
        assert(requested[i] == 0 && occupied[i] == 0); // 不能通过快照恢复掩盖测试中的泄漏
    }
    assert(expected_free == region_count); // 最后一个沙箱也必须完全恢复容量
}

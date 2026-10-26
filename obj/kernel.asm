
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	65c50513          	addi	a0,a0,1628 # ffffffffc02016a8 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	66650513          	addi	a0,a0,1638 # ffffffffc02016c8 <etext+0x24>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	63658593          	addi	a1,a1,1590 # ffffffffc02016a4 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	67250513          	addi	a0,a0,1650 # ffffffffc02016e8 <etext+0x44>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	67e50513          	addi	a0,a0,1662 # ffffffffc0201708 <etext+0x64>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0206078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	68a50513          	addi	a0,a0,1674 # ffffffffc0201728 <etext+0x84>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	3cd58593          	addi	a1,a1,973 # ffffffffc0206477 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	67c50513          	addi	a0,a0,1660 # ffffffffc0201748 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <free_area>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	f9860613          	addi	a2,a2,-104 # ffffffffc0206078 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	5a2010ef          	jal	ra,ffffffffc0201692 <memset>
    dtb_init(); //初始化设备树，后面用它读取RAM配置
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console，初始话控制台，使内核能够输出信息
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	67c50513          	addi	a0,a0,1660 # ffffffffc0201778 <etext+0xd4>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management，初始化物理内存管理系统
ffffffffc020010c:	695000ef          	jal	ra,ffffffffc0200fa0 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	13c010ef          	jal	ra,ffffffffc020127c <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	106010ef          	jal	ra,ffffffffc020127c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	e6e30313          	addi	t1,t1,-402 # ffffffffc0206030 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	5a650513          	addi	a0,a0,1446 # ffffffffc0201798 <etext+0xf4>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	56850513          	addi	a0,a0,1384 # ffffffffc0201770 <etext+0xcc>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	3e20106f          	j	ffffffffc02015fe <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	59650513          	addi	a0,a0,1430 # ffffffffc02017b8 <etext+0x114>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	57850513          	addi	a0,a0,1400 # ffffffffc02017c8 <etext+0x124>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	57250513          	addi	a0,a0,1394 # ffffffffc02017d8 <etext+0x134>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	57a50513          	addi	a0,a0,1402 # ffffffffc02017f0 <etext+0x14c>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9e75>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	51090913          	addi	s2,s2,1296 # ffffffffc0201840 <etext+0x19c>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	4fa48493          	addi	s1,s1,1274 # ffffffffc0201838 <etext+0x194>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	52650513          	addi	a0,a0,1318 # ffffffffc02018b8 <etext+0x214>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	55250513          	addi	a0,a0,1362 # ffffffffc02018f0 <etext+0x24c>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	43250513          	addi	a0,a0,1074 # ffffffffc0201810 <etext+0x16c>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	22c010ef          	jal	ra,ffffffffc0201618 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	272010ef          	jal	ra,ffffffffc020166c <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	1be010ef          	jal	ra,ffffffffc020164e <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	3a450513          	addi	a0,a0,932 # ffffffffc0201848 <etext+0x1a4>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	2f650513          	addi	a0,a0,758 # ffffffffc0201868 <etext+0x1c4>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	2fc50513          	addi	a0,a0,764 # ffffffffc0201880 <etext+0x1dc>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	30a50513          	addi	a0,a0,778 # ffffffffc02018a0 <etext+0x1fc>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	34e50513          	addi	a0,a0,846 # ffffffffc02018f0 <etext+0x24c>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	a887b723          	sd	s0,-1394(a5) # ffffffffc0206038 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	a967b723          	sd	s6,-1394(a5) # ffffffffc0206040 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	a7c53503          	ld	a0,-1412(a0) # ffffffffc0206038 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	a7a53503          	ld	a0,-1414(a0) # ffffffffc0206040 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d0:	00006797          	auipc	a5,0x6
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0206018 <free_area>
ffffffffc02005d8:	e79c                	sd	a5,8(a5)
ffffffffc02005da:	e39c                	sd	a5,0(a5)
/* The two framework check functions below are kept unchanged. */
static void best_fit_check(void);

static void best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005dc:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005e0:	8082                	ret

ffffffffc02005e2 <best_fit_nr_free_pages>:
    }
}

static size_t best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005e2:	00006517          	auipc	a0,0x6
ffffffffc02005e6:	a4656503          	lwu	a0,-1466(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005ec:	c145                	beqz	a0,ffffffffc020068c <best_fit_alloc_pages+0xa0>
    if (n > nr_free) {
ffffffffc02005ee:	00006597          	auipc	a1,0x6
ffffffffc02005f2:	a2a58593          	addi	a1,a1,-1494 # ffffffffc0206018 <free_area>
ffffffffc02005f6:	0105a883          	lw	a7,16(a1)
ffffffffc02005fa:	86aa                	mv	a3,a0
ffffffffc02005fc:	02089793          	slli	a5,a7,0x20
ffffffffc0200600:	9381                	srli	a5,a5,0x20
ffffffffc0200602:	08a7e363          	bltu	a5,a0,ffffffffc0200688 <best_fit_alloc_pages+0x9c>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200606:	659c                	ld	a5,8(a1)
    struct Page *best = NULL;
ffffffffc0200608:	4501                	li	a0,0
    for (list_entry_t *le = list_next(&free_list);
ffffffffc020060a:	06b78e63          	beq	a5,a1,ffffffffc0200686 <best_fit_alloc_pages+0x9a>
        if (p->property >= n &&
ffffffffc020060e:	ff87a703          	lw	a4,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0200612:	fe878813          	addi	a6,a5,-24
        if (p->property >= n &&
ffffffffc0200616:	02071613          	slli	a2,a4,0x20
ffffffffc020061a:	9201                	srli	a2,a2,0x20
ffffffffc020061c:	00d66763          	bltu	a2,a3,ffffffffc020062a <best_fit_alloc_pages+0x3e>
ffffffffc0200620:	c501                	beqz	a0,ffffffffc0200628 <best_fit_alloc_pages+0x3c>
            (best == NULL || p->property < best->property)) {
ffffffffc0200622:	4910                	lw	a2,16(a0)
ffffffffc0200624:	00c77363          	bgeu	a4,a2,ffffffffc020062a <best_fit_alloc_pages+0x3e>
            best = p;
ffffffffc0200628:	8542                	mv	a0,a6
ffffffffc020062a:	679c                	ld	a5,8(a5)
    for (list_entry_t *le = list_next(&free_list);
ffffffffc020062c:	feb791e3          	bne	a5,a1,ffffffffc020060e <best_fit_alloc_pages+0x22>
    if (best == NULL) {
ffffffffc0200630:	c939                	beqz	a0,ffffffffc0200686 <best_fit_alloc_pages+0x9a>
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200632:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200634:	7110                	ld	a2,32(a0)
    ClearPageProperty(best);
ffffffffc0200636:	651c                	ld	a5,8(a0)
    size_t total = best->property;
ffffffffc0200638:	01052803          	lw	a6,16(a0)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020063c:	e710                	sd	a2,8(a4)
    next->prev = prev;
ffffffffc020063e:	e218                	sd	a4,0(a2)
    ClearPageProperty(best);
ffffffffc0200640:	9bf5                	andi	a5,a5,-3
ffffffffc0200642:	e51c                	sd	a5,8(a0)
    size_t total = best->property;
ffffffffc0200644:	02081793          	slli	a5,a6,0x20
    best->property = 0;
ffffffffc0200648:	00052823          	sw	zero,16(a0)
    size_t total = best->property;
ffffffffc020064c:	9381                	srli	a5,a5,0x20
        remainder->property = total - n;
ffffffffc020064e:	0006831b          	sext.w	t1,a3
    if (total > n) {
ffffffffc0200652:	02f6f563          	bgeu	a3,a5,ffffffffc020067c <best_fit_alloc_pages+0x90>
        struct Page *remainder = best + n;
ffffffffc0200656:	00269793          	slli	a5,a3,0x2
ffffffffc020065a:	97b6                	add	a5,a5,a3
ffffffffc020065c:	078e                	slli	a5,a5,0x3
ffffffffc020065e:	97aa                	add	a5,a5,a0
        SetPageProperty(remainder);
ffffffffc0200660:	6794                	ld	a3,8(a5)
        remainder->property = total - n;
ffffffffc0200662:	4068083b          	subw	a6,a6,t1
ffffffffc0200666:	0107a823          	sw	a6,16(a5)
        SetPageProperty(remainder);
ffffffffc020066a:	0026e693          	ori	a3,a3,2
ffffffffc020066e:	e794                	sd	a3,8(a5)
        list_add(prev, &remainder->page_link);
ffffffffc0200670:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200674:	e214                	sd	a3,0(a2)
ffffffffc0200676:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200678:	f390                	sd	a2,32(a5)
    elm->prev = prev;
ffffffffc020067a:	ef98                	sd	a4,24(a5)
    nr_free -= n;
ffffffffc020067c:	406888bb          	subw	a7,a7,t1
ffffffffc0200680:	0115a823          	sw	a7,16(a1)
    return best;
ffffffffc0200684:	8082                	ret
}
ffffffffc0200686:	8082                	ret
        return NULL;
ffffffffc0200688:	4501                	li	a0,0
ffffffffc020068a:	8082                	ret
static struct Page *best_fit_alloc_pages(size_t n) {
ffffffffc020068c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020068e:	00001697          	auipc	a3,0x1
ffffffffc0200692:	27a68693          	addi	a3,a3,634 # ffffffffc0201908 <etext+0x264>
ffffffffc0200696:	00001617          	auipc	a2,0x1
ffffffffc020069a:	27a60613          	addi	a2,a2,634 # ffffffffc0201910 <etext+0x26c>
ffffffffc020069e:	02c00593          	li	a1,44
ffffffffc02006a2:	00001517          	auipc	a0,0x1
ffffffffc02006a6:	28650513          	addi	a0,a0,646 # ffffffffc0201928 <etext+0x284>
static struct Page *best_fit_alloc_pages(size_t n) {
ffffffffc02006aa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02006ac:	b17ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02006b0 <best_fit_check>:
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
ffffffffc02006b0:	715d                	addi	sp,sp,-80
ffffffffc02006b2:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02006b4:	00006417          	auipc	s0,0x6
ffffffffc02006b8:	96440413          	addi	s0,s0,-1692 # ffffffffc0206018 <free_area>
ffffffffc02006bc:	641c                	ld	a5,8(s0)
ffffffffc02006be:	e486                	sd	ra,72(sp)
ffffffffc02006c0:	fc26                	sd	s1,56(sp)
ffffffffc02006c2:	f84a                	sd	s2,48(sp)
ffffffffc02006c4:	f44e                	sd	s3,40(sp)
ffffffffc02006c6:	f052                	sd	s4,32(sp)
ffffffffc02006c8:	ec56                	sd	s5,24(sp)
ffffffffc02006ca:	e85a                	sd	s6,16(sp)
ffffffffc02006cc:	e45e                	sd	s7,8(sp)
ffffffffc02006ce:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006d0:	26878963          	beq	a5,s0,ffffffffc0200942 <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc02006d4:	4481                	li	s1,0
ffffffffc02006d6:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02006d8:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006dc:	8b09                	andi	a4,a4,2
ffffffffc02006de:	26070663          	beqz	a4,ffffffffc020094a <best_fit_check+0x29a>
        count++, total += p->property;
ffffffffc02006e2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006e6:	679c                	ld	a5,8(a5)
ffffffffc02006e8:	2905                	addiw	s2,s2,1
ffffffffc02006ea:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ec:	fe8796e3          	bne	a5,s0,ffffffffc02006d8 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02006f0:	89a6                	mv	s3,s1
ffffffffc02006f2:	0a3000ef          	jal	ra,ffffffffc0200f94 <nr_free_pages>
ffffffffc02006f6:	33351a63          	bne	a0,s3,ffffffffc0200a2a <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006fa:	4505                	li	a0,1
ffffffffc02006fc:	081000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc0200700:	8a2a                	mv	s4,a0
ffffffffc0200702:	36050463          	beqz	a0,ffffffffc0200a6a <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200706:	4505                	li	a0,1
ffffffffc0200708:	075000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc020070c:	89aa                	mv	s3,a0
ffffffffc020070e:	32050e63          	beqz	a0,ffffffffc0200a4a <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200712:	4505                	li	a0,1
ffffffffc0200714:	069000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc0200718:	8aaa                	mv	s5,a0
ffffffffc020071a:	2c050863          	beqz	a0,ffffffffc02009ea <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020071e:	253a0663          	beq	s4,s3,ffffffffc020096a <best_fit_check+0x2ba>
ffffffffc0200722:	24aa0463          	beq	s4,a0,ffffffffc020096a <best_fit_check+0x2ba>
ffffffffc0200726:	24a98263          	beq	s3,a0,ffffffffc020096a <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020072a:	000a2783          	lw	a5,0(s4)
ffffffffc020072e:	24079e63          	bnez	a5,ffffffffc020098a <best_fit_check+0x2da>
ffffffffc0200732:	0009a783          	lw	a5,0(s3)
ffffffffc0200736:	24079a63          	bnez	a5,ffffffffc020098a <best_fit_check+0x2da>
ffffffffc020073a:	411c                	lw	a5,0(a0)
ffffffffc020073c:	24079763          	bnez	a5,ffffffffc020098a <best_fit_check+0x2da>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200740:	00006797          	auipc	a5,0x6
ffffffffc0200744:	9107b783          	ld	a5,-1776(a5) # ffffffffc0206050 <pages>
ffffffffc0200748:	40fa0733          	sub	a4,s4,a5
ffffffffc020074c:	870d                	srai	a4,a4,0x3
ffffffffc020074e:	00002597          	auipc	a1,0x2
ffffffffc0200752:	9125b583          	ld	a1,-1774(a1) # ffffffffc0202060 <error_string+0x38>
ffffffffc0200756:	02b70733          	mul	a4,a4,a1
ffffffffc020075a:	00002617          	auipc	a2,0x2
ffffffffc020075e:	91663603          	ld	a2,-1770(a2) # ffffffffc0202070 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200762:	00006697          	auipc	a3,0x6
ffffffffc0200766:	8e66b683          	ld	a3,-1818(a3) # ffffffffc0206048 <npage>
ffffffffc020076a:	06b2                	slli	a3,a3,0xc
ffffffffc020076c:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc020076e:	0732                	slli	a4,a4,0xc
ffffffffc0200770:	22d77d63          	bgeu	a4,a3,ffffffffc02009aa <best_fit_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200774:	40f98733          	sub	a4,s3,a5
ffffffffc0200778:	870d                	srai	a4,a4,0x3
ffffffffc020077a:	02b70733          	mul	a4,a4,a1
ffffffffc020077e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200780:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200782:	3ed77463          	bgeu	a4,a3,ffffffffc0200b6a <best_fit_check+0x4ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200786:	40f507b3          	sub	a5,a0,a5
ffffffffc020078a:	878d                	srai	a5,a5,0x3
ffffffffc020078c:	02b787b3          	mul	a5,a5,a1
ffffffffc0200790:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200792:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200794:	3ad7fb63          	bgeu	a5,a3,ffffffffc0200b4a <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200798:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020079a:	00043c03          	ld	s8,0(s0)
ffffffffc020079e:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02007a2:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02007a6:	e400                	sd	s0,8(s0)
ffffffffc02007a8:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02007aa:	00006797          	auipc	a5,0x6
ffffffffc02007ae:	8607af23          	sw	zero,-1922(a5) # ffffffffc0206028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02007b2:	7ca000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc02007b6:	36051a63          	bnez	a0,ffffffffc0200b2a <best_fit_check+0x47a>
    free_page(p0);
ffffffffc02007ba:	4585                	li	a1,1
ffffffffc02007bc:	8552                	mv	a0,s4
ffffffffc02007be:	7ca000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    free_page(p1);
ffffffffc02007c2:	4585                	li	a1,1
ffffffffc02007c4:	854e                	mv	a0,s3
ffffffffc02007c6:	7c2000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    free_page(p2);
ffffffffc02007ca:	4585                	li	a1,1
ffffffffc02007cc:	8556                	mv	a0,s5
ffffffffc02007ce:	7ba000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    assert(nr_free == 3);
ffffffffc02007d2:	4818                	lw	a4,16(s0)
ffffffffc02007d4:	478d                	li	a5,3
ffffffffc02007d6:	32f71a63          	bne	a4,a5,ffffffffc0200b0a <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007da:	4505                	li	a0,1
ffffffffc02007dc:	7a0000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc02007e0:	89aa                	mv	s3,a0
ffffffffc02007e2:	30050463          	beqz	a0,ffffffffc0200aea <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007e6:	4505                	li	a0,1
ffffffffc02007e8:	794000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc02007ec:	8aaa                	mv	s5,a0
ffffffffc02007ee:	2c050e63          	beqz	a0,ffffffffc0200aca <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007f2:	4505                	li	a0,1
ffffffffc02007f4:	788000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc02007f8:	8a2a                	mv	s4,a0
ffffffffc02007fa:	2a050863          	beqz	a0,ffffffffc0200aaa <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc02007fe:	4505                	li	a0,1
ffffffffc0200800:	77c000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc0200804:	28051363          	bnez	a0,ffffffffc0200a8a <best_fit_check+0x3da>
    free_page(p0);
ffffffffc0200808:	4585                	li	a1,1
ffffffffc020080a:	854e                	mv	a0,s3
ffffffffc020080c:	77c000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200810:	641c                	ld	a5,8(s0)
ffffffffc0200812:	1a878c63          	beq	a5,s0,ffffffffc02009ca <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc0200816:	4505                	li	a0,1
ffffffffc0200818:	764000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc020081c:	52a99763          	bne	s3,a0,ffffffffc0200d4a <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0200820:	4505                	li	a0,1
ffffffffc0200822:	75a000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc0200826:	50051263          	bnez	a0,ffffffffc0200d2a <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc020082a:	481c                	lw	a5,16(s0)
ffffffffc020082c:	4c079f63          	bnez	a5,ffffffffc0200d0a <best_fit_check+0x65a>
    free_page(p);
ffffffffc0200830:	854e                	mv	a0,s3
ffffffffc0200832:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200834:	01843023          	sd	s8,0(s0)
ffffffffc0200838:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020083c:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200840:	748000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    free_page(p1);
ffffffffc0200844:	4585                	li	a1,1
ffffffffc0200846:	8556                	mv	a0,s5
ffffffffc0200848:	740000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    free_page(p2);
ffffffffc020084c:	4585                	li	a1,1
ffffffffc020084e:	8552                	mv	a0,s4
ffffffffc0200850:	738000ef          	jal	ra,ffffffffc0200f88 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200854:	4515                	li	a0,5
ffffffffc0200856:	726000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc020085a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020085c:	48050763          	beqz	a0,ffffffffc0200cea <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc0200860:	651c                	ld	a5,8(a0)
ffffffffc0200862:	8b89                	andi	a5,a5,2
ffffffffc0200864:	46079363          	bnez	a5,ffffffffc0200cca <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200868:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020086a:	00043b03          	ld	s6,0(s0)
ffffffffc020086e:	00843a83          	ld	s5,8(s0)
ffffffffc0200872:	e000                	sd	s0,0(s0)
ffffffffc0200874:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200876:	706000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc020087a:	42051863          	bnez	a0,ffffffffc0200caa <best_fit_check+0x5fa>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc020087e:	4589                	li	a1,2
ffffffffc0200880:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200884:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200888:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc020088c:	00005797          	auipc	a5,0x5
ffffffffc0200890:	7807ae23          	sw	zero,1948(a5) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200894:	6f4000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200898:	8562                	mv	a0,s8
ffffffffc020089a:	4585                	li	a1,1
ffffffffc020089c:	6ec000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02008a0:	4511                	li	a0,4
ffffffffc02008a2:	6da000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc02008a6:	3e051263          	bnez	a0,ffffffffc0200c8a <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02008aa:	0309b783          	ld	a5,48(s3)
ffffffffc02008ae:	8b89                	andi	a5,a5,2
ffffffffc02008b0:	3a078d63          	beqz	a5,ffffffffc0200c6a <best_fit_check+0x5ba>
ffffffffc02008b4:	0389a703          	lw	a4,56(s3)
ffffffffc02008b8:	4789                	li	a5,2
ffffffffc02008ba:	3af71863          	bne	a4,a5,ffffffffc0200c6a <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008be:	4505                	li	a0,1
ffffffffc02008c0:	6bc000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc02008c4:	8a2a                	mv	s4,a0
ffffffffc02008c6:	38050263          	beqz	a0,ffffffffc0200c4a <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);
ffffffffc02008ca:	4509                	li	a0,2
ffffffffc02008cc:	6b0000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc02008d0:	34050d63          	beqz	a0,ffffffffc0200c2a <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc02008d4:	334c1b63          	bne	s8,s4,ffffffffc0200c0a <best_fit_check+0x55a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008d8:	854e                	mv	a0,s3
ffffffffc02008da:	4595                	li	a1,5
ffffffffc02008dc:	6ac000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008e0:	4515                	li	a0,5
ffffffffc02008e2:	69a000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc02008e6:	89aa                	mv	s3,a0
ffffffffc02008e8:	30050163          	beqz	a0,ffffffffc0200bea <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc02008ec:	4505                	li	a0,1
ffffffffc02008ee:	68e000ef          	jal	ra,ffffffffc0200f7c <alloc_pages>
ffffffffc02008f2:	2c051c63          	bnez	a0,ffffffffc0200bca <best_fit_check+0x51a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008f6:	481c                	lw	a5,16(s0)
ffffffffc02008f8:	2a079963          	bnez	a5,ffffffffc0200baa <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008fc:	4595                	li	a1,5
ffffffffc02008fe:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200900:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200904:	01643023          	sd	s6,0(s0)
ffffffffc0200908:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020090c:	67c000ef          	jal	ra,ffffffffc0200f88 <free_pages>
    return listelm->next;
ffffffffc0200910:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200912:	00878963          	beq	a5,s0,ffffffffc0200924 <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200916:	ff87a703          	lw	a4,-8(a5)
ffffffffc020091a:	679c                	ld	a5,8(a5)
ffffffffc020091c:	397d                	addiw	s2,s2,-1
ffffffffc020091e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200920:	fe879be3          	bne	a5,s0,ffffffffc0200916 <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc0200924:	26091363          	bnez	s2,ffffffffc0200b8a <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc0200928:	e0ed                	bnez	s1,ffffffffc0200a0a <best_fit_check+0x35a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
ffffffffc020092a:	60a6                	ld	ra,72(sp)
ffffffffc020092c:	6406                	ld	s0,64(sp)
ffffffffc020092e:	74e2                	ld	s1,56(sp)
ffffffffc0200930:	7942                	ld	s2,48(sp)
ffffffffc0200932:	79a2                	ld	s3,40(sp)
ffffffffc0200934:	7a02                	ld	s4,32(sp)
ffffffffc0200936:	6ae2                	ld	s5,24(sp)
ffffffffc0200938:	6b42                	ld	s6,16(sp)
ffffffffc020093a:	6ba2                	ld	s7,8(sp)
ffffffffc020093c:	6c02                	ld	s8,0(sp)
ffffffffc020093e:	6161                	addi	sp,sp,80
ffffffffc0200940:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200942:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200944:	4481                	li	s1,0
ffffffffc0200946:	4901                	li	s2,0
ffffffffc0200948:	b36d                	j	ffffffffc02006f2 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc020094a:	00001697          	auipc	a3,0x1
ffffffffc020094e:	ff668693          	addi	a3,a3,-10 # ffffffffc0201940 <etext+0x29c>
ffffffffc0200952:	00001617          	auipc	a2,0x1
ffffffffc0200956:	fbe60613          	addi	a2,a2,-66 # ffffffffc0201910 <etext+0x26c>
ffffffffc020095a:	0bb00593          	li	a1,187
ffffffffc020095e:	00001517          	auipc	a0,0x1
ffffffffc0200962:	fca50513          	addi	a0,a0,-54 # ffffffffc0201928 <etext+0x284>
ffffffffc0200966:	85dff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020096a:	00001697          	auipc	a3,0x1
ffffffffc020096e:	06668693          	addi	a3,a3,102 # ffffffffc02019d0 <etext+0x32c>
ffffffffc0200972:	00001617          	auipc	a2,0x1
ffffffffc0200976:	f9e60613          	addi	a2,a2,-98 # ffffffffc0201910 <etext+0x26c>
ffffffffc020097a:	08900593          	li	a1,137
ffffffffc020097e:	00001517          	auipc	a0,0x1
ffffffffc0200982:	faa50513          	addi	a0,a0,-86 # ffffffffc0201928 <etext+0x284>
ffffffffc0200986:	83dff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020098a:	00001697          	auipc	a3,0x1
ffffffffc020098e:	06e68693          	addi	a3,a3,110 # ffffffffc02019f8 <etext+0x354>
ffffffffc0200992:	00001617          	auipc	a2,0x1
ffffffffc0200996:	f7e60613          	addi	a2,a2,-130 # ffffffffc0201910 <etext+0x26c>
ffffffffc020099a:	08a00593          	li	a1,138
ffffffffc020099e:	00001517          	auipc	a0,0x1
ffffffffc02009a2:	f8a50513          	addi	a0,a0,-118 # ffffffffc0201928 <etext+0x284>
ffffffffc02009a6:	81dff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009aa:	00001697          	auipc	a3,0x1
ffffffffc02009ae:	08e68693          	addi	a3,a3,142 # ffffffffc0201a38 <etext+0x394>
ffffffffc02009b2:	00001617          	auipc	a2,0x1
ffffffffc02009b6:	f5e60613          	addi	a2,a2,-162 # ffffffffc0201910 <etext+0x26c>
ffffffffc02009ba:	08c00593          	li	a1,140
ffffffffc02009be:	00001517          	auipc	a0,0x1
ffffffffc02009c2:	f6a50513          	addi	a0,a0,-150 # ffffffffc0201928 <etext+0x284>
ffffffffc02009c6:	ffcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009ca:	00001697          	auipc	a3,0x1
ffffffffc02009ce:	0f668693          	addi	a3,a3,246 # ffffffffc0201ac0 <etext+0x41c>
ffffffffc02009d2:	00001617          	auipc	a2,0x1
ffffffffc02009d6:	f3e60613          	addi	a2,a2,-194 # ffffffffc0201910 <etext+0x26c>
ffffffffc02009da:	0a500593          	li	a1,165
ffffffffc02009de:	00001517          	auipc	a0,0x1
ffffffffc02009e2:	f4a50513          	addi	a0,a0,-182 # ffffffffc0201928 <etext+0x284>
ffffffffc02009e6:	fdcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009ea:	00001697          	auipc	a3,0x1
ffffffffc02009ee:	fc668693          	addi	a3,a3,-58 # ffffffffc02019b0 <etext+0x30c>
ffffffffc02009f2:	00001617          	auipc	a2,0x1
ffffffffc02009f6:	f1e60613          	addi	a2,a2,-226 # ffffffffc0201910 <etext+0x26c>
ffffffffc02009fa:	08700593          	li	a1,135
ffffffffc02009fe:	00001517          	auipc	a0,0x1
ffffffffc0200a02:	f2a50513          	addi	a0,a0,-214 # ffffffffc0201928 <etext+0x284>
ffffffffc0200a06:	fbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == 0);
ffffffffc0200a0a:	00001697          	auipc	a3,0x1
ffffffffc0200a0e:	1e668693          	addi	a3,a3,486 # ffffffffc0201bf0 <etext+0x54c>
ffffffffc0200a12:	00001617          	auipc	a2,0x1
ffffffffc0200a16:	efe60613          	addi	a2,a2,-258 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200a1a:	0fd00593          	li	a1,253
ffffffffc0200a1e:	00001517          	auipc	a0,0x1
ffffffffc0200a22:	f0a50513          	addi	a0,a0,-246 # ffffffffc0201928 <etext+0x284>
ffffffffc0200a26:	f9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a2a:	00001697          	auipc	a3,0x1
ffffffffc0200a2e:	f2668693          	addi	a3,a3,-218 # ffffffffc0201950 <etext+0x2ac>
ffffffffc0200a32:	00001617          	auipc	a2,0x1
ffffffffc0200a36:	ede60613          	addi	a2,a2,-290 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200a3a:	0be00593          	li	a1,190
ffffffffc0200a3e:	00001517          	auipc	a0,0x1
ffffffffc0200a42:	eea50513          	addi	a0,a0,-278 # ffffffffc0201928 <etext+0x284>
ffffffffc0200a46:	f7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a4a:	00001697          	auipc	a3,0x1
ffffffffc0200a4e:	f4668693          	addi	a3,a3,-186 # ffffffffc0201990 <etext+0x2ec>
ffffffffc0200a52:	00001617          	auipc	a2,0x1
ffffffffc0200a56:	ebe60613          	addi	a2,a2,-322 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200a5a:	08600593          	li	a1,134
ffffffffc0200a5e:	00001517          	auipc	a0,0x1
ffffffffc0200a62:	eca50513          	addi	a0,a0,-310 # ffffffffc0201928 <etext+0x284>
ffffffffc0200a66:	f5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a6a:	00001697          	auipc	a3,0x1
ffffffffc0200a6e:	f0668693          	addi	a3,a3,-250 # ffffffffc0201970 <etext+0x2cc>
ffffffffc0200a72:	00001617          	auipc	a2,0x1
ffffffffc0200a76:	e9e60613          	addi	a2,a2,-354 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200a7a:	08500593          	li	a1,133
ffffffffc0200a7e:	00001517          	auipc	a0,0x1
ffffffffc0200a82:	eaa50513          	addi	a0,a0,-342 # ffffffffc0201928 <etext+0x284>
ffffffffc0200a86:	f3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a8a:	00001697          	auipc	a3,0x1
ffffffffc0200a8e:	00e68693          	addi	a3,a3,14 # ffffffffc0201a98 <etext+0x3f4>
ffffffffc0200a92:	00001617          	auipc	a2,0x1
ffffffffc0200a96:	e7e60613          	addi	a2,a2,-386 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200a9a:	0a200593          	li	a1,162
ffffffffc0200a9e:	00001517          	auipc	a0,0x1
ffffffffc0200aa2:	e8a50513          	addi	a0,a0,-374 # ffffffffc0201928 <etext+0x284>
ffffffffc0200aa6:	f1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aaa:	00001697          	auipc	a3,0x1
ffffffffc0200aae:	f0668693          	addi	a3,a3,-250 # ffffffffc02019b0 <etext+0x30c>
ffffffffc0200ab2:	00001617          	auipc	a2,0x1
ffffffffc0200ab6:	e5e60613          	addi	a2,a2,-418 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200aba:	0a000593          	li	a1,160
ffffffffc0200abe:	00001517          	auipc	a0,0x1
ffffffffc0200ac2:	e6a50513          	addi	a0,a0,-406 # ffffffffc0201928 <etext+0x284>
ffffffffc0200ac6:	efcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200aca:	00001697          	auipc	a3,0x1
ffffffffc0200ace:	ec668693          	addi	a3,a3,-314 # ffffffffc0201990 <etext+0x2ec>
ffffffffc0200ad2:	00001617          	auipc	a2,0x1
ffffffffc0200ad6:	e3e60613          	addi	a2,a2,-450 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200ada:	09f00593          	li	a1,159
ffffffffc0200ade:	00001517          	auipc	a0,0x1
ffffffffc0200ae2:	e4a50513          	addi	a0,a0,-438 # ffffffffc0201928 <etext+0x284>
ffffffffc0200ae6:	edcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200aea:	00001697          	auipc	a3,0x1
ffffffffc0200aee:	e8668693          	addi	a3,a3,-378 # ffffffffc0201970 <etext+0x2cc>
ffffffffc0200af2:	00001617          	auipc	a2,0x1
ffffffffc0200af6:	e1e60613          	addi	a2,a2,-482 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200afa:	09e00593          	li	a1,158
ffffffffc0200afe:	00001517          	auipc	a0,0x1
ffffffffc0200b02:	e2a50513          	addi	a0,a0,-470 # ffffffffc0201928 <etext+0x284>
ffffffffc0200b06:	ebcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 3);
ffffffffc0200b0a:	00001697          	auipc	a3,0x1
ffffffffc0200b0e:	fa668693          	addi	a3,a3,-90 # ffffffffc0201ab0 <etext+0x40c>
ffffffffc0200b12:	00001617          	auipc	a2,0x1
ffffffffc0200b16:	dfe60613          	addi	a2,a2,-514 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200b1a:	09c00593          	li	a1,156
ffffffffc0200b1e:	00001517          	auipc	a0,0x1
ffffffffc0200b22:	e0a50513          	addi	a0,a0,-502 # ffffffffc0201928 <etext+0x284>
ffffffffc0200b26:	e9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b2a:	00001697          	auipc	a3,0x1
ffffffffc0200b2e:	f6e68693          	addi	a3,a3,-146 # ffffffffc0201a98 <etext+0x3f4>
ffffffffc0200b32:	00001617          	auipc	a2,0x1
ffffffffc0200b36:	dde60613          	addi	a2,a2,-546 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200b3a:	09700593          	li	a1,151
ffffffffc0200b3e:	00001517          	auipc	a0,0x1
ffffffffc0200b42:	dea50513          	addi	a0,a0,-534 # ffffffffc0201928 <etext+0x284>
ffffffffc0200b46:	e7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b4a:	00001697          	auipc	a3,0x1
ffffffffc0200b4e:	f2e68693          	addi	a3,a3,-210 # ffffffffc0201a78 <etext+0x3d4>
ffffffffc0200b52:	00001617          	auipc	a2,0x1
ffffffffc0200b56:	dbe60613          	addi	a2,a2,-578 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200b5a:	08e00593          	li	a1,142
ffffffffc0200b5e:	00001517          	auipc	a0,0x1
ffffffffc0200b62:	dca50513          	addi	a0,a0,-566 # ffffffffc0201928 <etext+0x284>
ffffffffc0200b66:	e5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b6a:	00001697          	auipc	a3,0x1
ffffffffc0200b6e:	eee68693          	addi	a3,a3,-274 # ffffffffc0201a58 <etext+0x3b4>
ffffffffc0200b72:	00001617          	auipc	a2,0x1
ffffffffc0200b76:	d9e60613          	addi	a2,a2,-610 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200b7a:	08d00593          	li	a1,141
ffffffffc0200b7e:	00001517          	auipc	a0,0x1
ffffffffc0200b82:	daa50513          	addi	a0,a0,-598 # ffffffffc0201928 <etext+0x284>
ffffffffc0200b86:	e3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(count == 0);
ffffffffc0200b8a:	00001697          	auipc	a3,0x1
ffffffffc0200b8e:	05668693          	addi	a3,a3,86 # ffffffffc0201be0 <etext+0x53c>
ffffffffc0200b92:	00001617          	auipc	a2,0x1
ffffffffc0200b96:	d7e60613          	addi	a2,a2,-642 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200b9a:	0fc00593          	li	a1,252
ffffffffc0200b9e:	00001517          	auipc	a0,0x1
ffffffffc0200ba2:	d8a50513          	addi	a0,a0,-630 # ffffffffc0201928 <etext+0x284>
ffffffffc0200ba6:	e1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200baa:	00001697          	auipc	a3,0x1
ffffffffc0200bae:	f4e68693          	addi	a3,a3,-178 # ffffffffc0201af8 <etext+0x454>
ffffffffc0200bb2:	00001617          	auipc	a2,0x1
ffffffffc0200bb6:	d5e60613          	addi	a2,a2,-674 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200bba:	0f100593          	li	a1,241
ffffffffc0200bbe:	00001517          	auipc	a0,0x1
ffffffffc0200bc2:	d6a50513          	addi	a0,a0,-662 # ffffffffc0201928 <etext+0x284>
ffffffffc0200bc6:	dfcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bca:	00001697          	auipc	a3,0x1
ffffffffc0200bce:	ece68693          	addi	a3,a3,-306 # ffffffffc0201a98 <etext+0x3f4>
ffffffffc0200bd2:	00001617          	auipc	a2,0x1
ffffffffc0200bd6:	d3e60613          	addi	a2,a2,-706 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200bda:	0eb00593          	li	a1,235
ffffffffc0200bde:	00001517          	auipc	a0,0x1
ffffffffc0200be2:	d4a50513          	addi	a0,a0,-694 # ffffffffc0201928 <etext+0x284>
ffffffffc0200be6:	ddcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bea:	00001697          	auipc	a3,0x1
ffffffffc0200bee:	fd668693          	addi	a3,a3,-42 # ffffffffc0201bc0 <etext+0x51c>
ffffffffc0200bf2:	00001617          	auipc	a2,0x1
ffffffffc0200bf6:	d1e60613          	addi	a2,a2,-738 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200bfa:	0ea00593          	li	a1,234
ffffffffc0200bfe:	00001517          	auipc	a0,0x1
ffffffffc0200c02:	d2a50513          	addi	a0,a0,-726 # ffffffffc0201928 <etext+0x284>
ffffffffc0200c06:	dbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c0a:	00001697          	auipc	a3,0x1
ffffffffc0200c0e:	fa668693          	addi	a3,a3,-90 # ffffffffc0201bb0 <etext+0x50c>
ffffffffc0200c12:	00001617          	auipc	a2,0x1
ffffffffc0200c16:	cfe60613          	addi	a2,a2,-770 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200c1a:	0e200593          	li	a1,226
ffffffffc0200c1e:	00001517          	auipc	a0,0x1
ffffffffc0200c22:	d0a50513          	addi	a0,a0,-758 # ffffffffc0201928 <etext+0x284>
ffffffffc0200c26:	d9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(2) != NULL);
ffffffffc0200c2a:	00001697          	auipc	a3,0x1
ffffffffc0200c2e:	f6e68693          	addi	a3,a3,-146 # ffffffffc0201b98 <etext+0x4f4>
ffffffffc0200c32:	00001617          	auipc	a2,0x1
ffffffffc0200c36:	cde60613          	addi	a2,a2,-802 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200c3a:	0e100593          	li	a1,225
ffffffffc0200c3e:	00001517          	auipc	a0,0x1
ffffffffc0200c42:	cea50513          	addi	a0,a0,-790 # ffffffffc0201928 <etext+0x284>
ffffffffc0200c46:	d7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c4a:	00001697          	auipc	a3,0x1
ffffffffc0200c4e:	f2e68693          	addi	a3,a3,-210 # ffffffffc0201b78 <etext+0x4d4>
ffffffffc0200c52:	00001617          	auipc	a2,0x1
ffffffffc0200c56:	cbe60613          	addi	a2,a2,-834 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200c5a:	0e000593          	li	a1,224
ffffffffc0200c5e:	00001517          	auipc	a0,0x1
ffffffffc0200c62:	cca50513          	addi	a0,a0,-822 # ffffffffc0201928 <etext+0x284>
ffffffffc0200c66:	d5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c6a:	00001697          	auipc	a3,0x1
ffffffffc0200c6e:	ede68693          	addi	a3,a3,-290 # ffffffffc0201b48 <etext+0x4a4>
ffffffffc0200c72:	00001617          	auipc	a2,0x1
ffffffffc0200c76:	c9e60613          	addi	a2,a2,-866 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200c7a:	0de00593          	li	a1,222
ffffffffc0200c7e:	00001517          	auipc	a0,0x1
ffffffffc0200c82:	caa50513          	addi	a0,a0,-854 # ffffffffc0201928 <etext+0x284>
ffffffffc0200c86:	d3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c8a:	00001697          	auipc	a3,0x1
ffffffffc0200c8e:	ea668693          	addi	a3,a3,-346 # ffffffffc0201b30 <etext+0x48c>
ffffffffc0200c92:	00001617          	auipc	a2,0x1
ffffffffc0200c96:	c7e60613          	addi	a2,a2,-898 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200c9a:	0dd00593          	li	a1,221
ffffffffc0200c9e:	00001517          	auipc	a0,0x1
ffffffffc0200ca2:	c8a50513          	addi	a0,a0,-886 # ffffffffc0201928 <etext+0x284>
ffffffffc0200ca6:	d1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200caa:	00001697          	auipc	a3,0x1
ffffffffc0200cae:	dee68693          	addi	a3,a3,-530 # ffffffffc0201a98 <etext+0x3f4>
ffffffffc0200cb2:	00001617          	auipc	a2,0x1
ffffffffc0200cb6:	c5e60613          	addi	a2,a2,-930 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200cba:	0d100593          	li	a1,209
ffffffffc0200cbe:	00001517          	auipc	a0,0x1
ffffffffc0200cc2:	c6a50513          	addi	a0,a0,-918 # ffffffffc0201928 <etext+0x284>
ffffffffc0200cc6:	cfcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cca:	00001697          	auipc	a3,0x1
ffffffffc0200cce:	e4e68693          	addi	a3,a3,-434 # ffffffffc0201b18 <etext+0x474>
ffffffffc0200cd2:	00001617          	auipc	a2,0x1
ffffffffc0200cd6:	c3e60613          	addi	a2,a2,-962 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200cda:	0c800593          	li	a1,200
ffffffffc0200cde:	00001517          	auipc	a0,0x1
ffffffffc0200ce2:	c4a50513          	addi	a0,a0,-950 # ffffffffc0201928 <etext+0x284>
ffffffffc0200ce6:	cdcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200cea:	00001697          	auipc	a3,0x1
ffffffffc0200cee:	e1e68693          	addi	a3,a3,-482 # ffffffffc0201b08 <etext+0x464>
ffffffffc0200cf2:	00001617          	auipc	a2,0x1
ffffffffc0200cf6:	c1e60613          	addi	a2,a2,-994 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200cfa:	0c700593          	li	a1,199
ffffffffc0200cfe:	00001517          	auipc	a0,0x1
ffffffffc0200d02:	c2a50513          	addi	a0,a0,-982 # ffffffffc0201928 <etext+0x284>
ffffffffc0200d06:	cbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200d0a:	00001697          	auipc	a3,0x1
ffffffffc0200d0e:	dee68693          	addi	a3,a3,-530 # ffffffffc0201af8 <etext+0x454>
ffffffffc0200d12:	00001617          	auipc	a2,0x1
ffffffffc0200d16:	bfe60613          	addi	a2,a2,-1026 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200d1a:	0ab00593          	li	a1,171
ffffffffc0200d1e:	00001517          	auipc	a0,0x1
ffffffffc0200d22:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0201928 <etext+0x284>
ffffffffc0200d26:	c9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d2a:	00001697          	auipc	a3,0x1
ffffffffc0200d2e:	d6e68693          	addi	a3,a3,-658 # ffffffffc0201a98 <etext+0x3f4>
ffffffffc0200d32:	00001617          	auipc	a2,0x1
ffffffffc0200d36:	bde60613          	addi	a2,a2,-1058 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200d3a:	0a900593          	li	a1,169
ffffffffc0200d3e:	00001517          	auipc	a0,0x1
ffffffffc0200d42:	bea50513          	addi	a0,a0,-1046 # ffffffffc0201928 <etext+0x284>
ffffffffc0200d46:	c7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d4a:	00001697          	auipc	a3,0x1
ffffffffc0200d4e:	d8e68693          	addi	a3,a3,-626 # ffffffffc0201ad8 <etext+0x434>
ffffffffc0200d52:	00001617          	auipc	a2,0x1
ffffffffc0200d56:	bbe60613          	addi	a2,a2,-1090 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200d5a:	0a800593          	li	a1,168
ffffffffc0200d5e:	00001517          	auipc	a0,0x1
ffffffffc0200d62:	bca50513          	addi	a0,a0,-1078 # ffffffffc0201928 <etext+0x284>
ffffffffc0200d66:	c5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d6a <best_fit_free_pages>:
static void best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d6a:	1141                	addi	sp,sp,-16
ffffffffc0200d6c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d6e:	12058e63          	beqz	a1,ffffffffc0200eaa <best_fit_free_pages+0x140>
    for (struct Page *p = base; p < base + n; ++p) {
ffffffffc0200d72:	00259693          	slli	a3,a1,0x2
ffffffffc0200d76:	96ae                	add	a3,a3,a1
ffffffffc0200d78:	068e                	slli	a3,a3,0x3
ffffffffc0200d7a:	96aa                	add	a3,a3,a0
ffffffffc0200d7c:	87aa                	mv	a5,a0
ffffffffc0200d7e:	02d57063          	bgeu	a0,a3,ffffffffc0200d9e <best_fit_free_pages+0x34>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d82:	6798                	ld	a4,8(a5)
ffffffffc0200d84:	8b0d                	andi	a4,a4,3
ffffffffc0200d86:	10071263          	bnez	a4,ffffffffc0200e8a <best_fit_free_pages+0x120>
        p->flags = 0;
ffffffffc0200d8a:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0200d8e:	0007a823          	sw	zero,16(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d92:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p < base + n; ++p) {
ffffffffc0200d96:	02878793          	addi	a5,a5,40
ffffffffc0200d9a:	fed7e4e3          	bltu	a5,a3,ffffffffc0200d82 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200d9e:	00853803          	ld	a6,8(a0)
    nr_free += n;
ffffffffc0200da2:	00005697          	auipc	a3,0x5
ffffffffc0200da6:	27668693          	addi	a3,a3,630 # ffffffffc0206018 <free_area>
ffffffffc0200daa:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200dac:	2581                	sext.w	a1,a1
ffffffffc0200dae:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200db0:	00286613          	ori	a2,a6,2
    base->property = n;
ffffffffc0200db4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200db6:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200db8:	9f2d                	addw	a4,a4,a1
ffffffffc0200dba:	ca98                	sw	a4,16(a3)
    while (le != &free_list && le2page(le, page_link) < base) {
ffffffffc0200dbc:	00d79663          	bne	a5,a3,ffffffffc0200dc8 <best_fit_free_pages+0x5e>
ffffffffc0200dc0:	a0a5                	j	ffffffffc0200e28 <best_fit_free_pages+0xbe>
ffffffffc0200dc2:	679c                	ld	a5,8(a5)
ffffffffc0200dc4:	06d78263          	beq	a5,a3,ffffffffc0200e28 <best_fit_free_pages+0xbe>
ffffffffc0200dc8:	fe878713          	addi	a4,a5,-24
ffffffffc0200dcc:	fea76be3          	bltu	a4,a0,ffffffffc0200dc2 <best_fit_free_pages+0x58>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200dd0:	6390                	ld	a2,0(a5)
    list_add_before(le, &base->page_link);
ffffffffc0200dd2:	01850893          	addi	a7,a0,24
    prev->next = next->prev = elm;
ffffffffc0200dd6:	0117b023          	sd	a7,0(a5)
ffffffffc0200dda:	01163423          	sd	a7,8(a2)
    elm->next = next;
ffffffffc0200dde:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200de0:	ed10                	sd	a2,24(a0)
    if (prev != &free_list) {
ffffffffc0200de2:	02d60563          	beq	a2,a3,ffffffffc0200e0c <best_fit_free_pages+0xa2>
        if (before + before->property == base) {
ffffffffc0200de6:	ff862e03          	lw	t3,-8(a2)
        struct Page *before = le2page(prev, page_link);
ffffffffc0200dea:	fe860313          	addi	t1,a2,-24
        if (before + before->property == base) {
ffffffffc0200dee:	020e1893          	slli	a7,t3,0x20
ffffffffc0200df2:	0208d893          	srli	a7,a7,0x20
ffffffffc0200df6:	00289713          	slli	a4,a7,0x2
ffffffffc0200dfa:	9746                	add	a4,a4,a7
ffffffffc0200dfc:	070e                	slli	a4,a4,0x3
ffffffffc0200dfe:	971a                	add	a4,a4,t1
ffffffffc0200e00:	06e50763          	beq	a0,a4,ffffffffc0200e6e <best_fit_free_pages+0x104>
    if (next != &free_list) {
ffffffffc0200e04:	00d78f63          	beq	a5,a3,ffffffffc0200e22 <best_fit_free_pages+0xb8>
ffffffffc0200e08:	fe878713          	addi	a4,a5,-24
        if (base + base->property == after) {
ffffffffc0200e0c:	490c                	lw	a1,16(a0)
ffffffffc0200e0e:	02059613          	slli	a2,a1,0x20
ffffffffc0200e12:	9201                	srli	a2,a2,0x20
ffffffffc0200e14:	00261693          	slli	a3,a2,0x2
ffffffffc0200e18:	96b2                	add	a3,a3,a2
ffffffffc0200e1a:	068e                	slli	a3,a3,0x3
ffffffffc0200e1c:	96aa                	add	a3,a3,a0
ffffffffc0200e1e:	02d70363          	beq	a4,a3,ffffffffc0200e44 <best_fit_free_pages+0xda>
}
ffffffffc0200e22:	60a2                	ld	ra,8(sp)
ffffffffc0200e24:	0141                	addi	sp,sp,16
ffffffffc0200e26:	8082                	ret
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200e28:	6290                	ld	a2,0(a3)
    list_add_before(le, &base->page_link);
ffffffffc0200e2a:	01850793          	addi	a5,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e2e:	e29c                	sd	a5,0(a3)
ffffffffc0200e30:	e61c                	sd	a5,8(a2)
    elm->next = next;
ffffffffc0200e32:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0200e34:	ed10                	sd	a2,24(a0)
    if (prev != &free_list) {
ffffffffc0200e36:	00005797          	auipc	a5,0x5
ffffffffc0200e3a:	1e278793          	addi	a5,a5,482 # ffffffffc0206018 <free_area>
ffffffffc0200e3e:	fad614e3          	bne	a2,a3,ffffffffc0200de6 <best_fit_free_pages+0x7c>
ffffffffc0200e42:	b7c5                	j	ffffffffc0200e22 <best_fit_free_pages+0xb8>
            base->property += after->property;
ffffffffc0200e44:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(after);
ffffffffc0200e48:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e4c:	0007b803          	ld	a6,0(a5)
ffffffffc0200e50:	6790                	ld	a2,8(a5)
            base->property += after->property;
ffffffffc0200e52:	9db5                	addw	a1,a1,a3
ffffffffc0200e54:	c90c                	sw	a1,16(a0)
            ClearPageProperty(after);
ffffffffc0200e56:	9b75                	andi	a4,a4,-3
ffffffffc0200e58:	fee7b823          	sd	a4,-16(a5)
            after->property = 0;
ffffffffc0200e5c:	fe07ac23          	sw	zero,-8(a5)
}
ffffffffc0200e60:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200e62:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200e66:	01063023          	sd	a6,0(a2)
ffffffffc0200e6a:	0141                	addi	sp,sp,16
ffffffffc0200e6c:	8082                	ret
            before->property += base->property;
ffffffffc0200e6e:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e72:	feb62c23          	sw	a1,-8(a2)
            ClearPageProperty(base);
ffffffffc0200e76:	ffd87813          	andi	a6,a6,-3
ffffffffc0200e7a:	01053423          	sd	a6,8(a0)
            base->property = 0;
ffffffffc0200e7e:	00052823          	sw	zero,16(a0)
    prev->next = next;
ffffffffc0200e82:	e61c                	sd	a5,8(a2)
    next->prev = prev;
ffffffffc0200e84:	e390                	sd	a2,0(a5)
            base = before;
ffffffffc0200e86:	851a                	mv	a0,t1
ffffffffc0200e88:	bfb5                	j	ffffffffc0200e04 <best_fit_free_pages+0x9a>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200e8a:	00001697          	auipc	a3,0x1
ffffffffc0200e8e:	d7668693          	addi	a3,a3,-650 # ffffffffc0201c00 <etext+0x55c>
ffffffffc0200e92:	00001617          	auipc	a2,0x1
ffffffffc0200e96:	a7e60613          	addi	a2,a2,-1410 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200e9a:	05000593          	li	a1,80
ffffffffc0200e9e:	00001517          	auipc	a0,0x1
ffffffffc0200ea2:	a8a50513          	addi	a0,a0,-1398 # ffffffffc0201928 <etext+0x284>
ffffffffc0200ea6:	b1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200eaa:	00001697          	auipc	a3,0x1
ffffffffc0200eae:	a5e68693          	addi	a3,a3,-1442 # ffffffffc0201908 <etext+0x264>
ffffffffc0200eb2:	00001617          	auipc	a2,0x1
ffffffffc0200eb6:	a5e60613          	addi	a2,a2,-1442 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200eba:	04e00593          	li	a1,78
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0201928 <etext+0x284>
ffffffffc0200ec6:	afcff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200eca <best_fit_init_memmap>:
static void best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200eca:	1141                	addi	sp,sp,-16
ffffffffc0200ecc:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ece:	c9c1                	beqz	a1,ffffffffc0200f5e <best_fit_init_memmap+0x94>
    for (struct Page *p = base; p < base + n; ++p) {
ffffffffc0200ed0:	00259693          	slli	a3,a1,0x2
ffffffffc0200ed4:	96ae                	add	a3,a3,a1
ffffffffc0200ed6:	068e                	slli	a3,a3,0x3
ffffffffc0200ed8:	96aa                	add	a3,a3,a0
ffffffffc0200eda:	87aa                	mv	a5,a0
ffffffffc0200edc:	00d57f63          	bgeu	a0,a3,ffffffffc0200efa <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200ee0:	6798                	ld	a4,8(a5)
ffffffffc0200ee2:	8b05                	andi	a4,a4,1
ffffffffc0200ee4:	cf29                	beqz	a4,ffffffffc0200f3e <best_fit_init_memmap+0x74>
        p->flags = 0;
ffffffffc0200ee6:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0200eea:	0007a823          	sw	zero,16(a5)
ffffffffc0200eee:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p < base + n; ++p) {
ffffffffc0200ef2:	02878793          	addi	a5,a5,40
ffffffffc0200ef6:	fed7e5e3          	bltu	a5,a3,ffffffffc0200ee0 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200efa:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200efc:	00005697          	auipc	a3,0x5
ffffffffc0200f00:	11c68693          	addi	a3,a3,284 # ffffffffc0206018 <free_area>
ffffffffc0200f04:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200f06:	2581                	sext.w	a1,a1
    return listelm->next;
ffffffffc0200f08:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200f0a:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200f0e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f10:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f12:	9db9                	addw	a1,a1,a4
ffffffffc0200f14:	ca8c                	sw	a1,16(a3)
    while (le != &free_list && le2page(le, page_link) < base) {
ffffffffc0200f16:	00d79663          	bne	a5,a3,ffffffffc0200f22 <best_fit_init_memmap+0x58>
ffffffffc0200f1a:	a801                	j	ffffffffc0200f2a <best_fit_init_memmap+0x60>
ffffffffc0200f1c:	679c                	ld	a5,8(a5)
ffffffffc0200f1e:	00d78663          	beq	a5,a3,ffffffffc0200f2a <best_fit_init_memmap+0x60>
ffffffffc0200f22:	fe878713          	addi	a4,a5,-24
ffffffffc0200f26:	fea76be3          	bltu	a4,a0,ffffffffc0200f1c <best_fit_init_memmap+0x52>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f2a:	6398                	ld	a4,0(a5)
    list_add_before(le, &base->page_link);
ffffffffc0200f2c:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f30:	e394                	sd	a3,0(a5)
}
ffffffffc0200f32:	60a2                	ld	ra,8(sp)
ffffffffc0200f34:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200f36:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f38:	ed18                	sd	a4,24(a0)
ffffffffc0200f3a:	0141                	addi	sp,sp,16
ffffffffc0200f3c:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f3e:	00001697          	auipc	a3,0x1
ffffffffc0200f42:	cea68693          	addi	a3,a3,-790 # ffffffffc0201c28 <etext+0x584>
ffffffffc0200f46:	00001617          	auipc	a2,0x1
ffffffffc0200f4a:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200f4e:	02000593          	li	a1,32
ffffffffc0200f52:	00001517          	auipc	a0,0x1
ffffffffc0200f56:	9d650513          	addi	a0,a0,-1578 # ffffffffc0201928 <etext+0x284>
ffffffffc0200f5a:	a68ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200f5e:	00001697          	auipc	a3,0x1
ffffffffc0200f62:	9aa68693          	addi	a3,a3,-1622 # ffffffffc0201908 <etext+0x264>
ffffffffc0200f66:	00001617          	auipc	a2,0x1
ffffffffc0200f6a:	9aa60613          	addi	a2,a2,-1622 # ffffffffc0201910 <etext+0x26c>
ffffffffc0200f6e:	45f9                	li	a1,30
ffffffffc0200f70:	00001517          	auipc	a0,0x1
ffffffffc0200f74:	9b850513          	addi	a0,a0,-1608 # ffffffffc0201928 <etext+0x284>
ffffffffc0200f78:	a4aff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200f7c <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200f7c:	00005797          	auipc	a5,0x5
ffffffffc0200f80:	0dc7b783          	ld	a5,220(a5) # ffffffffc0206058 <pmm_manager>
ffffffffc0200f84:	6f9c                	ld	a5,24(a5)
ffffffffc0200f86:	8782                	jr	a5

ffffffffc0200f88 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200f88:	00005797          	auipc	a5,0x5
ffffffffc0200f8c:	0d07b783          	ld	a5,208(a5) # ffffffffc0206058 <pmm_manager>
ffffffffc0200f90:	739c                	ld	a5,32(a5)
ffffffffc0200f92:	8782                	jr	a5

ffffffffc0200f94 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200f94:	00005797          	auipc	a5,0x5
ffffffffc0200f98:	0c47b783          	ld	a5,196(a5) # ffffffffc0206058 <pmm_manager>
ffffffffc0200f9c:	779c                	ld	a5,40(a5)
ffffffffc0200f9e:	8782                	jr	a5

ffffffffc0200fa0 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200fa0:	00001797          	auipc	a5,0x1
ffffffffc0200fa4:	cb078793          	addi	a5,a5,-848 # ffffffffc0201c50 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fa8:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(free_begin), (end_pa - free_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200faa:	7139                	addi	sp,sp,-64
ffffffffc0200fac:	f426                	sd	s1,40(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fae:	00001517          	auipc	a0,0x1
ffffffffc0200fb2:	cda50513          	addi	a0,a0,-806 # ffffffffc0201c88 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200fb6:	00005497          	auipc	s1,0x5
ffffffffc0200fba:	0a248493          	addi	s1,s1,162 # ffffffffc0206058 <pmm_manager>
void pmm_init(void) {
ffffffffc0200fbe:	fc06                	sd	ra,56(sp)
ffffffffc0200fc0:	f822                	sd	s0,48(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200fc2:	e09c                	sd	a5,0(s1)
void pmm_init(void) {
ffffffffc0200fc4:	f04a                	sd	s2,32(sp)
ffffffffc0200fc6:	ec4e                	sd	s3,24(sp)
ffffffffc0200fc8:	e852                	sd	s4,16(sp)
ffffffffc0200fca:	e456                	sd	s5,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fcc:	980ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200fd0:	609c                	ld	a5,0(s1)
ffffffffc0200fd2:	679c                	ld	a5,8(a5)
ffffffffc0200fd4:	9782                	jalr	a5
    uint64_t base = get_memory_base();
ffffffffc0200fd6:	de6ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0200fda:	842a                	mv	s0,a0
    uint64_t size = get_memory_size();
ffffffffc0200fdc:	deaff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (base != DRAM_BASE || size == 0 || size > ~(uint64_t)0 - base) {
ffffffffc0200fe0:	4785                	li	a5,1
ffffffffc0200fe2:	07fe                	slli	a5,a5,0x1f
ffffffffc0200fe4:	18f41063          	bne	s0,a5,ffffffffc0201164 <pmm_init+0x1c4>
ffffffffc0200fe8:	800007b7          	lui	a5,0x80000
ffffffffc0200fec:	fff50713          	addi	a4,a0,-1
ffffffffc0200ff0:	17f9                	addi	a5,a5,-2
ffffffffc0200ff2:	16e7e963          	bltu	a5,a4,ffffffffc0201164 <pmm_init+0x1c4>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200ff6:	57f5                	li	a5,-3
ffffffffc0200ff8:	07fa                	slli	a5,a5,0x1e
ffffffffc0200ffa:	00005917          	auipc	s2,0x5
ffffffffc0200ffe:	07690913          	addi	s2,s2,118 # ffffffffc0206070 <va_pa_offset>
ffffffffc0201002:	00f93023          	sd	a5,0(s2)
    uintptr_t end_pa = memory_end < PHYSICAL_MEMORY_END
ffffffffc0201006:	47c5                	li	a5,17
    uint64_t memory_end = base + size;
ffffffffc0201008:	00850633          	add	a2,a0,s0
    uintptr_t end_pa = memory_end < PHYSICAL_MEMORY_END
ffffffffc020100c:	07ee                	slli	a5,a5,0x1b
ffffffffc020100e:	85b2                	mv	a1,a2
ffffffffc0201010:	12c7e163          	bltu	a5,a2,ffffffffc0201132 <pmm_init+0x192>
    end_pa = ROUNDDOWN(end_pa, PGSIZE);
ffffffffc0201014:	757d                	lui	a0,0xfffff
    if (end_pa <= KERNEL_BEGIN_PADDR) {
ffffffffc0201016:	40100793          	li	a5,1025
    end_pa = ROUNDDOWN(end_pa, PGSIZE);
ffffffffc020101a:	00a5f9b3          	and	s3,a1,a0
    if (end_pa <= KERNEL_BEGIN_PADDR) {
ffffffffc020101e:	07d6                	slli	a5,a5,0x15
ffffffffc0201020:	1d37f063          	bgeu	a5,s3,ffffffffc02011e0 <pmm_init+0x240>
    npage = PPN(end_pa);
ffffffffc0201024:	00c9d593          	srli	a1,s3,0xc
ffffffffc0201028:	00005a17          	auipc	s4,0x5
ffffffffc020102c:	020a0a13          	addi	s4,s4,32 # ffffffffc0206048 <npage>
ffffffffc0201030:	00ba3023          	sd	a1,0(s4)
    uintptr_t kernel_end_pa = PADDR(end);
ffffffffc0201034:	00005717          	auipc	a4,0x5
ffffffffc0201038:	04470713          	addi	a4,a4,68 # ffffffffc0206078 <end>
ffffffffc020103c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201040:	18f76363          	bltu	a4,a5,ffffffffc02011c6 <pmm_init+0x226>
ffffffffc0201044:	478d                	li	a5,3
ffffffffc0201046:	07fa                	slli	a5,a5,0x1e
ffffffffc0201048:	00f706b3          	add	a3,a4,a5
    if (kernel_end_pa < KERNEL_BEGIN_PADDR || kernel_end_pa > end_pa) {
ffffffffc020104c:	16d9e163          	bltu	s3,a3,ffffffffc02011ae <pmm_init+0x20e>
    uintptr_t descriptor_pa = ROUNDUP(kernel_end_pa, PGSIZE);
ffffffffc0201050:	00001697          	auipc	a3,0x1
ffffffffc0201054:	0186b683          	ld	a3,24(a3) # ffffffffc0202068 <error_string+0x40>
ffffffffc0201058:	9736                	add	a4,a4,a3
    size_t descriptor_count = npage - nbase;
ffffffffc020105a:	fff80437          	lui	s0,0xfff80
ffffffffc020105e:	8d79                	and	a0,a0,a4
ffffffffc0201060:	00858833          	add	a6,a1,s0
    if (descriptor_pa > end_pa ||
ffffffffc0201064:	10a9ec63          	bltu	s3,a0,ffffffffc020117c <pmm_init+0x1dc>
        descriptor_count > (end_pa - descriptor_pa) / sizeof(struct Page)) {
ffffffffc0201068:	40a98733          	sub	a4,s3,a0
ffffffffc020106c:	02800693          	li	a3,40
ffffffffc0201070:	02d75733          	divu	a4,a4,a3
    if (descriptor_pa > end_pa ||
ffffffffc0201074:	11076463          	bltu	a4,a6,ffffffffc020117c <pmm_init+0x1dc>
    pages = (struct Page *)(descriptor_pa + va_pa_offset);
ffffffffc0201078:	00259693          	slli	a3,a1,0x2
ffffffffc020107c:	cfb00713          	li	a4,-773
ffffffffc0201080:	96ae                	add	a3,a3,a1
ffffffffc0201082:	075a                	slli	a4,a4,0x16
ffffffffc0201084:	40f507b3          	sub	a5,a0,a5
ffffffffc0201088:	00005a97          	auipc	s5,0x5
ffffffffc020108c:	fc8a8a93          	addi	s5,s5,-56 # ffffffffc0206050 <pages>
ffffffffc0201090:	068e                	slli	a3,a3,0x3
ffffffffc0201092:	972a                	add	a4,a4,a0
ffffffffc0201094:	00fab023          	sd	a5,0(s5)
    for (size_t i = 0; i < descriptor_count; ++i) {
ffffffffc0201098:	96ba                	add	a3,a3,a4
        SetPageReserved(&pages[i]);
ffffffffc020109a:	4585                	li	a1,1
        pages[i].property = 0;
ffffffffc020109c:	01878713          	addi	a4,a5,24 # ffffffffc0200018 <kern_entry+0x18>
ffffffffc02010a0:	0007a823          	sw	zero,16(a5)
ffffffffc02010a4:	0007a023          	sw	zero,0(a5)
        SetPageReserved(&pages[i]);
ffffffffc02010a8:	e78c                	sd	a1,8(a5)
    elm->prev = elm->next = elm;
ffffffffc02010aa:	f398                	sd	a4,32(a5)
ffffffffc02010ac:	ef98                	sd	a4,24(a5)
    for (size_t i = 0; i < descriptor_count; ++i) {
ffffffffc02010ae:	02878793          	addi	a5,a5,40
ffffffffc02010b2:	fef695e3          	bne	a3,a5,ffffffffc020109c <pmm_init+0xfc>
    uintptr_t free_begin = ROUNDUP(
ffffffffc02010b6:	00281413          	slli	s0,a6,0x2
ffffffffc02010ba:	6785                	lui	a5,0x1
ffffffffc02010bc:	9442                	add	s0,s0,a6
ffffffffc02010be:	17fd                	addi	a5,a5,-1
ffffffffc02010c0:	953e                	add	a0,a0,a5
ffffffffc02010c2:	040e                	slli	s0,s0,0x3
ffffffffc02010c4:	942a                	add	s0,s0,a0
ffffffffc02010c6:	757d                	lui	a0,0xfffff
ffffffffc02010c8:	8c69                	and	s0,s0,a0
    cprintf("physical memory: [0x%016lx, 0x%016lx)\n", base, memory_end);
ffffffffc02010ca:	05fe                	slli	a1,a1,0x1f
ffffffffc02010cc:	00001517          	auipc	a0,0x1
ffffffffc02010d0:	c9450513          	addi	a0,a0,-876 # ffffffffc0201d60 <best_fit_pmm_manager+0x110>
ffffffffc02010d4:	878ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (free_begin < end_pa) {
ffffffffc02010d8:	05346f63          	bltu	s0,s3,ffffffffc0201136 <pmm_init+0x196>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010dc:	609c                	ld	a5,0(s1)
ffffffffc02010de:	7b9c                	ld	a5,48(a5)
ffffffffc02010e0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010e2:	00001517          	auipc	a0,0x1
ffffffffc02010e6:	cd650513          	addi	a0,a0,-810 # ffffffffc0201db8 <best_fit_pmm_manager+0x168>
ffffffffc02010ea:	862ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02010ee:	00004597          	auipc	a1,0x4
ffffffffc02010f2:	f1258593          	addi	a1,a1,-238 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02010f6:	00005797          	auipc	a5,0x5
ffffffffc02010fa:	f6b7b923          	sd	a1,-142(a5) # ffffffffc0206068 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010fe:	c02007b7          	lui	a5,0xc0200
ffffffffc0201102:	08f5e963          	bltu	a1,a5,ffffffffc0201194 <pmm_init+0x1f4>
ffffffffc0201106:	00093603          	ld	a2,0(s2)
}
ffffffffc020110a:	7442                	ld	s0,48(sp)
ffffffffc020110c:	70e2                	ld	ra,56(sp)
ffffffffc020110e:	74a2                	ld	s1,40(sp)
ffffffffc0201110:	7902                	ld	s2,32(sp)
ffffffffc0201112:	69e2                	ld	s3,24(sp)
ffffffffc0201114:	6a42                	ld	s4,16(sp)
ffffffffc0201116:	6aa2                	ld	s5,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201118:	40c58633          	sub	a2,a1,a2
ffffffffc020111c:	00005797          	auipc	a5,0x5
ffffffffc0201120:	f4c7b223          	sd	a2,-188(a5) # ffffffffc0206060 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201124:	00001517          	auipc	a0,0x1
ffffffffc0201128:	cb450513          	addi	a0,a0,-844 # ffffffffc0201dd8 <best_fit_pmm_manager+0x188>
}
ffffffffc020112c:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020112e:	81eff06f          	j	ffffffffc020014c <cprintf>
    uintptr_t end_pa = memory_end < PHYSICAL_MEMORY_END
ffffffffc0201132:	85be                	mv	a1,a5
ffffffffc0201134:	b5c5                	j	ffffffffc0201014 <pmm_init+0x74>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201136:	000a3703          	ld	a4,0(s4)
ffffffffc020113a:	00c45793          	srli	a5,s0,0xc
ffffffffc020113e:	0ae7fd63          	bgeu	a5,a4,ffffffffc02011f8 <pmm_init+0x258>
    pmm_manager->init_memmap(base, n);
ffffffffc0201142:	6094                	ld	a3,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201144:	fff80737          	lui	a4,0xfff80
ffffffffc0201148:	973e                	add	a4,a4,a5
ffffffffc020114a:	000ab503          	ld	a0,0(s5)
ffffffffc020114e:	00271793          	slli	a5,a4,0x2
ffffffffc0201152:	97ba                	add	a5,a5,a4
ffffffffc0201154:	6a98                	ld	a4,16(a3)
        init_memmap(pa2page(free_begin), (end_pa - free_begin) / PGSIZE);
ffffffffc0201156:	408985b3          	sub	a1,s3,s0
ffffffffc020115a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020115c:	81b1                	srli	a1,a1,0xc
ffffffffc020115e:	953e                	add	a0,a0,a5
ffffffffc0201160:	9702                	jalr	a4
}
ffffffffc0201162:	bfad                	j	ffffffffc02010dc <pmm_init+0x13c>
        panic("invalid DTB memory range");
ffffffffc0201164:	00001617          	auipc	a2,0x1
ffffffffc0201168:	b3c60613          	addi	a2,a2,-1220 # ffffffffc0201ca0 <best_fit_pmm_manager+0x50>
ffffffffc020116c:	04d00593          	li	a1,77
ffffffffc0201170:	00001517          	auipc	a0,0x1
ffffffffc0201174:	b5050513          	addi	a0,a0,-1200 # ffffffffc0201cc0 <best_fit_pmm_manager+0x70>
ffffffffc0201178:	84aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("insufficient RAM for page descriptors");
ffffffffc020117c:	00001617          	auipc	a2,0x1
ffffffffc0201180:	bbc60613          	addi	a2,a2,-1092 # ffffffffc0201d38 <best_fit_pmm_manager+0xe8>
ffffffffc0201184:	06400593          	li	a1,100
ffffffffc0201188:	00001517          	auipc	a0,0x1
ffffffffc020118c:	b3850513          	addi	a0,a0,-1224 # ffffffffc0201cc0 <best_fit_pmm_manager+0x70>
ffffffffc0201190:	832ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201194:	86ae                	mv	a3,a1
ffffffffc0201196:	00001617          	auipc	a2,0x1
ffffffffc020119a:	b5a60613          	addi	a2,a2,-1190 # ffffffffc0201cf0 <best_fit_pmm_manager+0xa0>
ffffffffc020119e:	09000593          	li	a1,144
ffffffffc02011a2:	00001517          	auipc	a0,0x1
ffffffffc02011a6:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0201cc0 <best_fit_pmm_manager+0x70>
ffffffffc02011aa:	818ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("kernel is outside managed RAM");
ffffffffc02011ae:	00001617          	auipc	a2,0x1
ffffffffc02011b2:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0201d18 <best_fit_pmm_manager+0xc8>
ffffffffc02011b6:	05d00593          	li	a1,93
ffffffffc02011ba:	00001517          	auipc	a0,0x1
ffffffffc02011be:	b0650513          	addi	a0,a0,-1274 # ffffffffc0201cc0 <best_fit_pmm_manager+0x70>
ffffffffc02011c2:	800ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t kernel_end_pa = PADDR(end);
ffffffffc02011c6:	86ba                	mv	a3,a4
ffffffffc02011c8:	00001617          	auipc	a2,0x1
ffffffffc02011cc:	b2860613          	addi	a2,a2,-1240 # ffffffffc0201cf0 <best_fit_pmm_manager+0xa0>
ffffffffc02011d0:	05b00593          	li	a1,91
ffffffffc02011d4:	00001517          	auipc	a0,0x1
ffffffffc02011d8:	aec50513          	addi	a0,a0,-1300 # ffffffffc0201cc0 <best_fit_pmm_manager+0x70>
ffffffffc02011dc:	fe7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("RAM does not cover the kernel");
ffffffffc02011e0:	00001617          	auipc	a2,0x1
ffffffffc02011e4:	af060613          	addi	a2,a2,-1296 # ffffffffc0201cd0 <best_fit_pmm_manager+0x80>
ffffffffc02011e8:	05600593          	li	a1,86
ffffffffc02011ec:	00001517          	auipc	a0,0x1
ffffffffc02011f0:	ad450513          	addi	a0,a0,-1324 # ffffffffc0201cc0 <best_fit_pmm_manager+0x70>
ffffffffc02011f4:	fcffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02011f8:	00001617          	auipc	a2,0x1
ffffffffc02011fc:	b9060613          	addi	a2,a2,-1136 # ffffffffc0201d88 <best_fit_pmm_manager+0x138>
ffffffffc0201200:	06a00593          	li	a1,106
ffffffffc0201204:	00001517          	auipc	a0,0x1
ffffffffc0201208:	ba450513          	addi	a0,a0,-1116 # ffffffffc0201da8 <best_fit_pmm_manager+0x158>
ffffffffc020120c:	fb7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201210 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201210:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201214:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201216:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020121a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020121c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201220:	f022                	sd	s0,32(sp)
ffffffffc0201222:	ec26                	sd	s1,24(sp)
ffffffffc0201224:	e84a                	sd	s2,16(sp)
ffffffffc0201226:	f406                	sd	ra,40(sp)
ffffffffc0201228:	e44e                	sd	s3,8(sp)
ffffffffc020122a:	84aa                	mv	s1,a0
ffffffffc020122c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020122e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201232:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201234:	03067e63          	bgeu	a2,a6,ffffffffc0201270 <printnum+0x60>
ffffffffc0201238:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020123a:	00805763          	blez	s0,ffffffffc0201248 <printnum+0x38>
ffffffffc020123e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201240:	85ca                	mv	a1,s2
ffffffffc0201242:	854e                	mv	a0,s3
ffffffffc0201244:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201246:	fc65                	bnez	s0,ffffffffc020123e <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201248:	1a02                	slli	s4,s4,0x20
ffffffffc020124a:	00001797          	auipc	a5,0x1
ffffffffc020124e:	bce78793          	addi	a5,a5,-1074 # ffffffffc0201e18 <best_fit_pmm_manager+0x1c8>
ffffffffc0201252:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201256:	9a3e                	add	s4,s4,a5
}
ffffffffc0201258:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020125a:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020125e:	70a2                	ld	ra,40(sp)
ffffffffc0201260:	69a2                	ld	s3,8(sp)
ffffffffc0201262:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201264:	85ca                	mv	a1,s2
ffffffffc0201266:	87a6                	mv	a5,s1
}
ffffffffc0201268:	6942                	ld	s2,16(sp)
ffffffffc020126a:	64e2                	ld	s1,24(sp)
ffffffffc020126c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020126e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201270:	03065633          	divu	a2,a2,a6
ffffffffc0201274:	8722                	mv	a4,s0
ffffffffc0201276:	f9bff0ef          	jal	ra,ffffffffc0201210 <printnum>
ffffffffc020127a:	b7f9                	j	ffffffffc0201248 <printnum+0x38>

ffffffffc020127c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020127c:	7119                	addi	sp,sp,-128
ffffffffc020127e:	f4a6                	sd	s1,104(sp)
ffffffffc0201280:	f0ca                	sd	s2,96(sp)
ffffffffc0201282:	ecce                	sd	s3,88(sp)
ffffffffc0201284:	e8d2                	sd	s4,80(sp)
ffffffffc0201286:	e4d6                	sd	s5,72(sp)
ffffffffc0201288:	e0da                	sd	s6,64(sp)
ffffffffc020128a:	fc5e                	sd	s7,56(sp)
ffffffffc020128c:	f06a                	sd	s10,32(sp)
ffffffffc020128e:	fc86                	sd	ra,120(sp)
ffffffffc0201290:	f8a2                	sd	s0,112(sp)
ffffffffc0201292:	f862                	sd	s8,48(sp)
ffffffffc0201294:	f466                	sd	s9,40(sp)
ffffffffc0201296:	ec6e                	sd	s11,24(sp)
ffffffffc0201298:	892a                	mv	s2,a0
ffffffffc020129a:	84ae                	mv	s1,a1
ffffffffc020129c:	8d32                	mv	s10,a2
ffffffffc020129e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012a0:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02012a4:	5b7d                	li	s6,-1
ffffffffc02012a6:	00001a97          	auipc	s5,0x1
ffffffffc02012aa:	ba6a8a93          	addi	s5,s5,-1114 # ffffffffc0201e4c <best_fit_pmm_manager+0x1fc>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02012ae:	00001b97          	auipc	s7,0x1
ffffffffc02012b2:	d7ab8b93          	addi	s7,s7,-646 # ffffffffc0202028 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012b6:	000d4503          	lbu	a0,0(s10)
ffffffffc02012ba:	001d0413          	addi	s0,s10,1
ffffffffc02012be:	01350a63          	beq	a0,s3,ffffffffc02012d2 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02012c2:	c121                	beqz	a0,ffffffffc0201302 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02012c4:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012c6:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02012c8:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012ca:	fff44503          	lbu	a0,-1(s0) # fffffffffff7ffff <end+0x3fd79f87>
ffffffffc02012ce:	ff351ae3          	bne	a0,s3,ffffffffc02012c2 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012d2:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02012d6:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02012da:	4c81                	li	s9,0
ffffffffc02012dc:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02012de:	5c7d                	li	s8,-1
ffffffffc02012e0:	5dfd                	li	s11,-1
ffffffffc02012e2:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02012e6:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02012ec:	0ff5f593          	zext.b	a1,a1
ffffffffc02012f0:	00140d13          	addi	s10,s0,1
ffffffffc02012f4:	04b56263          	bltu	a0,a1,ffffffffc0201338 <vprintfmt+0xbc>
ffffffffc02012f8:	058a                	slli	a1,a1,0x2
ffffffffc02012fa:	95d6                	add	a1,a1,s5
ffffffffc02012fc:	4194                	lw	a3,0(a1)
ffffffffc02012fe:	96d6                	add	a3,a3,s5
ffffffffc0201300:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201302:	70e6                	ld	ra,120(sp)
ffffffffc0201304:	7446                	ld	s0,112(sp)
ffffffffc0201306:	74a6                	ld	s1,104(sp)
ffffffffc0201308:	7906                	ld	s2,96(sp)
ffffffffc020130a:	69e6                	ld	s3,88(sp)
ffffffffc020130c:	6a46                	ld	s4,80(sp)
ffffffffc020130e:	6aa6                	ld	s5,72(sp)
ffffffffc0201310:	6b06                	ld	s6,64(sp)
ffffffffc0201312:	7be2                	ld	s7,56(sp)
ffffffffc0201314:	7c42                	ld	s8,48(sp)
ffffffffc0201316:	7ca2                	ld	s9,40(sp)
ffffffffc0201318:	7d02                	ld	s10,32(sp)
ffffffffc020131a:	6de2                	ld	s11,24(sp)
ffffffffc020131c:	6109                	addi	sp,sp,128
ffffffffc020131e:	8082                	ret
            padc = '0';
ffffffffc0201320:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201322:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201326:	846a                	mv	s0,s10
ffffffffc0201328:	00140d13          	addi	s10,s0,1
ffffffffc020132c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201330:	0ff5f593          	zext.b	a1,a1
ffffffffc0201334:	fcb572e3          	bgeu	a0,a1,ffffffffc02012f8 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201338:	85a6                	mv	a1,s1
ffffffffc020133a:	02500513          	li	a0,37
ffffffffc020133e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201340:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201344:	8d22                	mv	s10,s0
ffffffffc0201346:	f73788e3          	beq	a5,s3,ffffffffc02012b6 <vprintfmt+0x3a>
ffffffffc020134a:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020134e:	1d7d                	addi	s10,s10,-1
ffffffffc0201350:	ff379de3          	bne	a5,s3,ffffffffc020134a <vprintfmt+0xce>
ffffffffc0201354:	b78d                	j	ffffffffc02012b6 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201356:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020135a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020135e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201360:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201364:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201368:	02d86463          	bltu	a6,a3,ffffffffc0201390 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020136c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201370:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201374:	0186873b          	addw	a4,a3,s8
ffffffffc0201378:	0017171b          	slliw	a4,a4,0x1
ffffffffc020137c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020137e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201382:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201384:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201388:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020138c:	fed870e3          	bgeu	a6,a3,ffffffffc020136c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201390:	f40ddce3          	bgez	s11,ffffffffc02012e8 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201394:	8de2                	mv	s11,s8
ffffffffc0201396:	5c7d                	li	s8,-1
ffffffffc0201398:	bf81                	j	ffffffffc02012e8 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020139a:	fffdc693          	not	a3,s11
ffffffffc020139e:	96fd                	srai	a3,a3,0x3f
ffffffffc02013a0:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013a4:	00144603          	lbu	a2,1(s0)
ffffffffc02013a8:	2d81                	sext.w	s11,s11
ffffffffc02013aa:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013ac:	bf35                	j	ffffffffc02012e8 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02013ae:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013b2:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02013b6:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013b8:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02013ba:	bfd9                	j	ffffffffc0201390 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02013bc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013be:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013c2:	01174463          	blt	a4,a7,ffffffffc02013ca <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02013c6:	1a088e63          	beqz	a7,ffffffffc0201582 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02013ca:	000a3603          	ld	a2,0(s4)
ffffffffc02013ce:	46c1                	li	a3,16
ffffffffc02013d0:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02013d2:	2781                	sext.w	a5,a5
ffffffffc02013d4:	876e                	mv	a4,s11
ffffffffc02013d6:	85a6                	mv	a1,s1
ffffffffc02013d8:	854a                	mv	a0,s2
ffffffffc02013da:	e37ff0ef          	jal	ra,ffffffffc0201210 <printnum>
            break;
ffffffffc02013de:	bde1                	j	ffffffffc02012b6 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02013e0:	000a2503          	lw	a0,0(s4)
ffffffffc02013e4:	85a6                	mv	a1,s1
ffffffffc02013e6:	0a21                	addi	s4,s4,8
ffffffffc02013e8:	9902                	jalr	s2
            break;
ffffffffc02013ea:	b5f1                	j	ffffffffc02012b6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013ec:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013ee:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013f2:	01174463          	blt	a4,a7,ffffffffc02013fa <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02013f6:	18088163          	beqz	a7,ffffffffc0201578 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02013fa:	000a3603          	ld	a2,0(s4)
ffffffffc02013fe:	46a9                	li	a3,10
ffffffffc0201400:	8a2e                	mv	s4,a1
ffffffffc0201402:	bfc1                	j	ffffffffc02013d2 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201404:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201408:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020140a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020140c:	bdf1                	j	ffffffffc02012e8 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020140e:	85a6                	mv	a1,s1
ffffffffc0201410:	02500513          	li	a0,37
ffffffffc0201414:	9902                	jalr	s2
            break;
ffffffffc0201416:	b545                	j	ffffffffc02012b6 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201418:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020141c:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020141e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201420:	b5e1                	j	ffffffffc02012e8 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201422:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201424:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201428:	01174463          	blt	a4,a7,ffffffffc0201430 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020142c:	14088163          	beqz	a7,ffffffffc020156e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201430:	000a3603          	ld	a2,0(s4)
ffffffffc0201434:	46a1                	li	a3,8
ffffffffc0201436:	8a2e                	mv	s4,a1
ffffffffc0201438:	bf69                	j	ffffffffc02013d2 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020143a:	03000513          	li	a0,48
ffffffffc020143e:	85a6                	mv	a1,s1
ffffffffc0201440:	e03e                	sd	a5,0(sp)
ffffffffc0201442:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201444:	85a6                	mv	a1,s1
ffffffffc0201446:	07800513          	li	a0,120
ffffffffc020144a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020144c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020144e:	6782                	ld	a5,0(sp)
ffffffffc0201450:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201452:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201456:	bfb5                	j	ffffffffc02013d2 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201458:	000a3403          	ld	s0,0(s4)
ffffffffc020145c:	008a0713          	addi	a4,s4,8
ffffffffc0201460:	e03a                	sd	a4,0(sp)
ffffffffc0201462:	14040263          	beqz	s0,ffffffffc02015a6 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201466:	0fb05763          	blez	s11,ffffffffc0201554 <vprintfmt+0x2d8>
ffffffffc020146a:	02d00693          	li	a3,45
ffffffffc020146e:	0cd79163          	bne	a5,a3,ffffffffc0201530 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201472:	00044783          	lbu	a5,0(s0)
ffffffffc0201476:	0007851b          	sext.w	a0,a5
ffffffffc020147a:	cf85                	beqz	a5,ffffffffc02014b2 <vprintfmt+0x236>
ffffffffc020147c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201480:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201484:	000c4563          	bltz	s8,ffffffffc020148e <vprintfmt+0x212>
ffffffffc0201488:	3c7d                	addiw	s8,s8,-1
ffffffffc020148a:	036c0263          	beq	s8,s6,ffffffffc02014ae <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020148e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201490:	0e0c8e63          	beqz	s9,ffffffffc020158c <vprintfmt+0x310>
ffffffffc0201494:	3781                	addiw	a5,a5,-32
ffffffffc0201496:	0ef47b63          	bgeu	s0,a5,ffffffffc020158c <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020149a:	03f00513          	li	a0,63
ffffffffc020149e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014a0:	000a4783          	lbu	a5,0(s4)
ffffffffc02014a4:	3dfd                	addiw	s11,s11,-1
ffffffffc02014a6:	0a05                	addi	s4,s4,1
ffffffffc02014a8:	0007851b          	sext.w	a0,a5
ffffffffc02014ac:	ffe1                	bnez	a5,ffffffffc0201484 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02014ae:	01b05963          	blez	s11,ffffffffc02014c0 <vprintfmt+0x244>
ffffffffc02014b2:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02014b4:	85a6                	mv	a1,s1
ffffffffc02014b6:	02000513          	li	a0,32
ffffffffc02014ba:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02014bc:	fe0d9be3          	bnez	s11,ffffffffc02014b2 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014c0:	6a02                	ld	s4,0(sp)
ffffffffc02014c2:	bbd5                	j	ffffffffc02012b6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02014c4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02014c6:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02014ca:	01174463          	blt	a4,a7,ffffffffc02014d2 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02014ce:	08088d63          	beqz	a7,ffffffffc0201568 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02014d2:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02014d6:	0a044d63          	bltz	s0,ffffffffc0201590 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02014da:	8622                	mv	a2,s0
ffffffffc02014dc:	8a66                	mv	s4,s9
ffffffffc02014de:	46a9                	li	a3,10
ffffffffc02014e0:	bdcd                	j	ffffffffc02013d2 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02014e2:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014e6:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02014e8:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02014ea:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02014ee:	8fb5                	xor	a5,a5,a3
ffffffffc02014f0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014f4:	02d74163          	blt	a4,a3,ffffffffc0201516 <vprintfmt+0x29a>
ffffffffc02014f8:	00369793          	slli	a5,a3,0x3
ffffffffc02014fc:	97de                	add	a5,a5,s7
ffffffffc02014fe:	639c                	ld	a5,0(a5)
ffffffffc0201500:	cb99                	beqz	a5,ffffffffc0201516 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201502:	86be                	mv	a3,a5
ffffffffc0201504:	00001617          	auipc	a2,0x1
ffffffffc0201508:	94460613          	addi	a2,a2,-1724 # ffffffffc0201e48 <best_fit_pmm_manager+0x1f8>
ffffffffc020150c:	85a6                	mv	a1,s1
ffffffffc020150e:	854a                	mv	a0,s2
ffffffffc0201510:	0ce000ef          	jal	ra,ffffffffc02015de <printfmt>
ffffffffc0201514:	b34d                	j	ffffffffc02012b6 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201516:	00001617          	auipc	a2,0x1
ffffffffc020151a:	92260613          	addi	a2,a2,-1758 # ffffffffc0201e38 <best_fit_pmm_manager+0x1e8>
ffffffffc020151e:	85a6                	mv	a1,s1
ffffffffc0201520:	854a                	mv	a0,s2
ffffffffc0201522:	0bc000ef          	jal	ra,ffffffffc02015de <printfmt>
ffffffffc0201526:	bb41                	j	ffffffffc02012b6 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201528:	00001417          	auipc	s0,0x1
ffffffffc020152c:	90840413          	addi	s0,s0,-1784 # ffffffffc0201e30 <best_fit_pmm_manager+0x1e0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201530:	85e2                	mv	a1,s8
ffffffffc0201532:	8522                	mv	a0,s0
ffffffffc0201534:	e43e                	sd	a5,8(sp)
ffffffffc0201536:	0fc000ef          	jal	ra,ffffffffc0201632 <strnlen>
ffffffffc020153a:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020153e:	01b05b63          	blez	s11,ffffffffc0201554 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201542:	67a2                	ld	a5,8(sp)
ffffffffc0201544:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201548:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020154a:	85a6                	mv	a1,s1
ffffffffc020154c:	8552                	mv	a0,s4
ffffffffc020154e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201550:	fe0d9ce3          	bnez	s11,ffffffffc0201548 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201554:	00044783          	lbu	a5,0(s0)
ffffffffc0201558:	00140a13          	addi	s4,s0,1
ffffffffc020155c:	0007851b          	sext.w	a0,a5
ffffffffc0201560:	d3a5                	beqz	a5,ffffffffc02014c0 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201562:	05e00413          	li	s0,94
ffffffffc0201566:	bf39                	j	ffffffffc0201484 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201568:	000a2403          	lw	s0,0(s4)
ffffffffc020156c:	b7ad                	j	ffffffffc02014d6 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020156e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201572:	46a1                	li	a3,8
ffffffffc0201574:	8a2e                	mv	s4,a1
ffffffffc0201576:	bdb1                	j	ffffffffc02013d2 <vprintfmt+0x156>
ffffffffc0201578:	000a6603          	lwu	a2,0(s4)
ffffffffc020157c:	46a9                	li	a3,10
ffffffffc020157e:	8a2e                	mv	s4,a1
ffffffffc0201580:	bd89                	j	ffffffffc02013d2 <vprintfmt+0x156>
ffffffffc0201582:	000a6603          	lwu	a2,0(s4)
ffffffffc0201586:	46c1                	li	a3,16
ffffffffc0201588:	8a2e                	mv	s4,a1
ffffffffc020158a:	b5a1                	j	ffffffffc02013d2 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020158c:	9902                	jalr	s2
ffffffffc020158e:	bf09                	j	ffffffffc02014a0 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201590:	85a6                	mv	a1,s1
ffffffffc0201592:	02d00513          	li	a0,45
ffffffffc0201596:	e03e                	sd	a5,0(sp)
ffffffffc0201598:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020159a:	6782                	ld	a5,0(sp)
ffffffffc020159c:	8a66                	mv	s4,s9
ffffffffc020159e:	40800633          	neg	a2,s0
ffffffffc02015a2:	46a9                	li	a3,10
ffffffffc02015a4:	b53d                	j	ffffffffc02013d2 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02015a6:	03b05163          	blez	s11,ffffffffc02015c8 <vprintfmt+0x34c>
ffffffffc02015aa:	02d00693          	li	a3,45
ffffffffc02015ae:	f6d79de3          	bne	a5,a3,ffffffffc0201528 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02015b2:	00001417          	auipc	s0,0x1
ffffffffc02015b6:	87e40413          	addi	s0,s0,-1922 # ffffffffc0201e30 <best_fit_pmm_manager+0x1e0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015ba:	02800793          	li	a5,40
ffffffffc02015be:	02800513          	li	a0,40
ffffffffc02015c2:	00140a13          	addi	s4,s0,1
ffffffffc02015c6:	bd6d                	j	ffffffffc0201480 <vprintfmt+0x204>
ffffffffc02015c8:	00001a17          	auipc	s4,0x1
ffffffffc02015cc:	869a0a13          	addi	s4,s4,-1943 # ffffffffc0201e31 <best_fit_pmm_manager+0x1e1>
ffffffffc02015d0:	02800513          	li	a0,40
ffffffffc02015d4:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02015d8:	05e00413          	li	s0,94
ffffffffc02015dc:	b565                	j	ffffffffc0201484 <vprintfmt+0x208>

ffffffffc02015de <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015de:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02015e0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015e4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02015e6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015e8:	ec06                	sd	ra,24(sp)
ffffffffc02015ea:	f83a                	sd	a4,48(sp)
ffffffffc02015ec:	fc3e                	sd	a5,56(sp)
ffffffffc02015ee:	e0c2                	sd	a6,64(sp)
ffffffffc02015f0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02015f2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02015f4:	c89ff0ef          	jal	ra,ffffffffc020127c <vprintfmt>
}
ffffffffc02015f8:	60e2                	ld	ra,24(sp)
ffffffffc02015fa:	6161                	addi	sp,sp,80
ffffffffc02015fc:	8082                	ret

ffffffffc02015fe <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02015fe:	4781                	li	a5,0
ffffffffc0201600:	00005717          	auipc	a4,0x5
ffffffffc0201604:	a1073703          	ld	a4,-1520(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201608:	88ba                	mv	a7,a4
ffffffffc020160a:	852a                	mv	a0,a0
ffffffffc020160c:	85be                	mv	a1,a5
ffffffffc020160e:	863e                	mv	a2,a5
ffffffffc0201610:	00000073          	ecall
ffffffffc0201614:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201616:	8082                	ret

ffffffffc0201618 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201618:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020161c:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020161e:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201620:	cb81                	beqz	a5,ffffffffc0201630 <strlen+0x18>
        cnt ++;
ffffffffc0201622:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201624:	00a707b3          	add	a5,a4,a0
ffffffffc0201628:	0007c783          	lbu	a5,0(a5)
ffffffffc020162c:	fbfd                	bnez	a5,ffffffffc0201622 <strlen+0xa>
ffffffffc020162e:	8082                	ret
    }
    return cnt;
}
ffffffffc0201630:	8082                	ret

ffffffffc0201632 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201632:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201634:	e589                	bnez	a1,ffffffffc020163e <strnlen+0xc>
ffffffffc0201636:	a811                	j	ffffffffc020164a <strnlen+0x18>
        cnt ++;
ffffffffc0201638:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020163a:	00f58863          	beq	a1,a5,ffffffffc020164a <strnlen+0x18>
ffffffffc020163e:	00f50733          	add	a4,a0,a5
ffffffffc0201642:	00074703          	lbu	a4,0(a4)
ffffffffc0201646:	fb6d                	bnez	a4,ffffffffc0201638 <strnlen+0x6>
ffffffffc0201648:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020164a:	852e                	mv	a0,a1
ffffffffc020164c:	8082                	ret

ffffffffc020164e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020164e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201652:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201656:	cb89                	beqz	a5,ffffffffc0201668 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201658:	0505                	addi	a0,a0,1
ffffffffc020165a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020165c:	fee789e3          	beq	a5,a4,ffffffffc020164e <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201660:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201664:	9d19                	subw	a0,a0,a4
ffffffffc0201666:	8082                	ret
ffffffffc0201668:	4501                	li	a0,0
ffffffffc020166a:	bfed                	j	ffffffffc0201664 <strcmp+0x16>

ffffffffc020166c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020166c:	c20d                	beqz	a2,ffffffffc020168e <strncmp+0x22>
ffffffffc020166e:	962e                	add	a2,a2,a1
ffffffffc0201670:	a031                	j	ffffffffc020167c <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201672:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201674:	00e79a63          	bne	a5,a4,ffffffffc0201688 <strncmp+0x1c>
ffffffffc0201678:	00b60b63          	beq	a2,a1,ffffffffc020168e <strncmp+0x22>
ffffffffc020167c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201680:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201682:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201686:	f7f5                	bnez	a5,ffffffffc0201672 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201688:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020168c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020168e:	4501                	li	a0,0
ffffffffc0201690:	8082                	ret

ffffffffc0201692 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201692:	ca01                	beqz	a2,ffffffffc02016a2 <memset+0x10>
ffffffffc0201694:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201696:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201698:	0785                	addi	a5,a5,1
ffffffffc020169a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020169e:	fec79de3          	bne	a5,a2,ffffffffc0201698 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02016a2:	8082                	ret

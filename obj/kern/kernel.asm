
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in mem_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 f0 11 f0       	mov    $0xf011f000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 f0 00 00 00       	call   f010012e <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	83 ec 10             	sub    $0x10,%esp
f0100048:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010004b:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 80 ae 22 f0    	mov    %esi,0xf022ae80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 d8 63 00 00       	call   f010643c <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 a0 6b 10 f0 	movl   $0xf0106ba0,(%esp)
f010007d:	e8 74 3c 00 00       	call   f0103cf6 <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 35 3c 00 00       	call   f0103cc3 <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 58 78 10 f0 	movl   $0xf0107858,(%esp)
f0100095:	e8 5c 3c 00 00       	call   f0103cf6 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 8c 09 00 00       	call   f0100a32 <monitor>
f01000a6:	eb f2                	jmp    f010009a <_panic+0x5a>

f01000a8 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01000a8:	55                   	push   %ebp
f01000a9:	89 e5                	mov    %esp,%ebp
f01000ab:	83 ec 18             	sub    $0x18,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01000ae:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01000b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01000b8:	77 20                	ja     f01000da <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01000ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01000be:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f01000c5:	f0 
f01000c6:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
f01000cd:	00 
f01000ce:	c7 04 24 0b 6c 10 f0 	movl   $0xf0106c0b,(%esp)
f01000d5:	e8 66 ff ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01000da:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01000df:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01000e2:	e8 55 63 00 00       	call   f010643c <cpunum>
f01000e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000eb:	c7 04 24 17 6c 10 f0 	movl   $0xf0106c17,(%esp)
f01000f2:	e8 ff 3b 00 00       	call   f0103cf6 <cprintf>

	lapic_init();
f01000f7:	e8 5b 63 00 00       	call   f0106457 <lapic_init>
	env_init_percpu();
f01000fc:	e8 8d 33 00 00       	call   f010348e <env_init_percpu>
	trap_init_percpu();
f0100101:	e8 0a 3c 00 00       	call   f0103d10 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100106:	e8 31 63 00 00       	call   f010643c <cpunum>
f010010b:	6b d0 74             	imul   $0x74,%eax,%edx
f010010e:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100114:	b8 01 00 00 00       	mov    $0x1,%eax
f0100119:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f010011d:	c7 04 24 a0 13 12 f0 	movl   $0xf01213a0,(%esp)
f0100124:	e8 ac 65 00 00       	call   f01066d5 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100129:	e8 ca 47 00 00       	call   f01048f8 <sched_yield>

f010012e <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010012e:	55                   	push   %ebp
f010012f:	89 e5                	mov    %esp,%ebp
f0100131:	53                   	push   %ebx
f0100132:	83 ec 14             	sub    $0x14,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100135:	b8 04 c0 26 f0       	mov    $0xf026c004,%eax
f010013a:	2d 62 98 22 f0       	sub    $0xf0229862,%eax
f010013f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100143:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010014a:	00 
f010014b:	c7 04 24 62 98 22 f0 	movl   $0xf0229862,(%esp)
f0100152:	e8 3e 5c 00 00       	call   f0105d95 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100157:	e8 6b 05 00 00       	call   f01006c7 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010015c:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100163:	00 
f0100164:	c7 04 24 2d 6c 10 f0 	movl   $0xf0106c2d,(%esp)
f010016b:	e8 86 3b 00 00       	call   f0103cf6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100170:	e8 9c 13 00 00       	call   f0101511 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100175:	e8 3e 33 00 00       	call   f01034b8 <env_init>
	trap_init();
f010017a:	e8 82 3c 00 00       	call   f0103e01 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f010017f:	90                   	nop
f0100180:	e8 cf 5f 00 00       	call   f0106154 <mp_init>
	lapic_init();
f0100185:	e8 cd 62 00 00       	call   f0106457 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f010018a:	e8 94 3a 00 00       	call   f0103c23 <pic_init>
f010018f:	c7 04 24 a0 13 12 f0 	movl   $0xf01213a0,(%esp)
f0100196:	e8 3a 65 00 00       	call   f01066d5 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010019b:	83 3d 88 ae 22 f0 07 	cmpl   $0x7,0xf022ae88
f01001a2:	77 24                	ja     f01001c8 <i386_init+0x9a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01001a4:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f01001ab:	00 
f01001ac:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01001b3:	f0 
f01001b4:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
f01001bb:	00 
f01001bc:	c7 04 24 0b 6c 10 f0 	movl   $0xf0106c0b,(%esp)
f01001c3:	e8 78 fe ff ff       	call   f0100040 <_panic>
	void *code;
	struct Cpu *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f01001c8:	b8 6a 60 10 f0       	mov    $0xf010606a,%eax
f01001cd:	2d f0 5f 10 f0       	sub    $0xf0105ff0,%eax
f01001d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01001d6:	c7 44 24 04 f0 5f 10 	movl   $0xf0105ff0,0x4(%esp)
f01001dd:	f0 
f01001de:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f01001e5:	e8 09 5c 00 00       	call   f0105df3 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01001ea:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f01001f1:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01001f6:	3d 20 b0 22 f0       	cmp    $0xf022b020,%eax
f01001fb:	0f 86 a6 00 00 00    	jbe    f01002a7 <i386_init+0x179>
f0100201:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
		if (c == cpus + cpunum())  // We've started already.
f0100206:	e8 31 62 00 00       	call   f010643c <cpunum>
f010020b:	6b c0 74             	imul   $0x74,%eax,%eax
f010020e:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0100213:	39 c3                	cmp    %eax,%ebx
f0100215:	74 39                	je     f0100250 <i386_init+0x122>

static void boot_aps(void);


void
i386_init(void)
f0100217:	89 d8                	mov    %ebx,%eax
f0100219:	2d 20 b0 22 f0       	sub    $0xf022b020,%eax
	for (c = cpus; c < cpus + ncpu; c++) {
		if (c == cpus + cpunum())  // We've started already.
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f010021e:	c1 f8 02             	sar    $0x2,%eax
f0100221:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100227:	c1 e0 0f             	shl    $0xf,%eax
f010022a:	8d 80 00 40 23 f0    	lea    -0xfdcc000(%eax),%eax
f0100230:	a3 84 ae 22 f0       	mov    %eax,0xf022ae84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100235:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f010023c:	00 
f010023d:	0f b6 03             	movzbl (%ebx),%eax
f0100240:	89 04 24             	mov    %eax,(%esp)
f0100243:	e8 47 63 00 00       	call   f010658f <lapic_startap>
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100248:	8b 43 04             	mov    0x4(%ebx),%eax
f010024b:	83 f8 01             	cmp    $0x1,%eax
f010024e:	75 f8                	jne    f0100248 <i386_init+0x11a>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100250:	83 c3 74             	add    $0x74,%ebx
f0100253:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f010025a:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010025f:	39 c3                	cmp    %eax,%ebx
f0100261:	72 a3                	jb     f0100206 <i386_init+0xd8>
f0100263:	eb 42                	jmp    f01002a7 <i386_init+0x179>
	boot_aps();

	// Should always have idle processes at first.
	int i;
	for (i = 0; i < NCPU; i++)
		ENV_CREATE(user_idle, ENV_TYPE_IDLE);
f0100265:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010026c:	00 
f010026d:	c7 44 24 04 5e 89 00 	movl   $0x895e,0x4(%esp)
f0100274:	00 
f0100275:	c7 04 24 2c 0e 19 f0 	movl   $0xf0190e2c,(%esp)
f010027c:	e8 56 34 00 00       	call   f01036d7 <env_create>
	// Starting non-boot CPUs
	boot_aps();

	// Should always have idle processes at first.
	int i;
	for (i = 0; i < NCPU; i++)
f0100281:	83 eb 01             	sub    $0x1,%ebx
f0100284:	75 df                	jne    f0100265 <i386_init+0x137>
		ENV_CREATE(user_idle, ENV_TYPE_IDLE);

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100286:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010028d:	00 
f010028e:	c7 44 24 04 b5 9a 00 	movl   $0x9ab5,0x4(%esp)
f0100295:	00 
f0100296:	c7 04 24 f5 62 21 f0 	movl   $0xf02162f5,(%esp)
f010029d:	e8 35 34 00 00       	call   f01036d7 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01002a2:	e8 51 46 00 00       	call   f01048f8 <sched_yield>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01002a7:	bb 08 00 00 00       	mov    $0x8,%ebx
f01002ac:	eb b7                	jmp    f0100265 <i386_init+0x137>

f01002ae <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01002ae:	55                   	push   %ebp
f01002af:	89 e5                	mov    %esp,%ebp
f01002b1:	53                   	push   %ebx
f01002b2:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01002b5:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01002b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01002bb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01002bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01002c2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01002c6:	c7 04 24 48 6c 10 f0 	movl   $0xf0106c48,(%esp)
f01002cd:	e8 24 3a 00 00       	call   f0103cf6 <cprintf>
	vcprintf(fmt, ap);
f01002d2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01002d6:	8b 45 10             	mov    0x10(%ebp),%eax
f01002d9:	89 04 24             	mov    %eax,(%esp)
f01002dc:	e8 e2 39 00 00       	call   f0103cc3 <vcprintf>
	cprintf("\n");
f01002e1:	c7 04 24 58 78 10 f0 	movl   $0xf0107858,(%esp)
f01002e8:	e8 09 3a 00 00       	call   f0103cf6 <cprintf>
	va_end(ap);
}
f01002ed:	83 c4 14             	add    $0x14,%esp
f01002f0:	5b                   	pop    %ebx
f01002f1:	5d                   	pop    %ebp
f01002f2:	c3                   	ret    
f01002f3:	66 90                	xchg   %ax,%ax
f01002f5:	66 90                	xchg   %ax,%ax
f01002f7:	66 90                	xchg   %ax,%ax
f01002f9:	66 90                	xchg   %ax,%ax
f01002fb:	66 90                	xchg   %ax,%ax
f01002fd:	66 90                	xchg   %ax,%ax
f01002ff:	90                   	nop

f0100300 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100300:	55                   	push   %ebp
f0100301:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100303:	ba 84 00 00 00       	mov    $0x84,%edx
f0100308:	ec                   	in     (%dx),%al
f0100309:	ec                   	in     (%dx),%al
f010030a:	ec                   	in     (%dx),%al
f010030b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010030c:	5d                   	pop    %ebp
f010030d:	c3                   	ret    

f010030e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010030e:	55                   	push   %ebp
f010030f:	89 e5                	mov    %esp,%ebp
f0100311:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100316:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100317:	a8 01                	test   $0x1,%al
f0100319:	74 08                	je     f0100323 <serial_proc_data+0x15>
f010031b:	b2 f8                	mov    $0xf8,%dl
f010031d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010031e:	0f b6 c0             	movzbl %al,%eax
f0100321:	eb 05                	jmp    f0100328 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100323:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100328:	5d                   	pop    %ebp
f0100329:	c3                   	ret    

f010032a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010032a:	55                   	push   %ebp
f010032b:	89 e5                	mov    %esp,%ebp
f010032d:	53                   	push   %ebx
f010032e:	83 ec 04             	sub    $0x4,%esp
f0100331:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100333:	eb 26                	jmp    f010035b <cons_intr+0x31>
		if (c == 0)
f0100335:	85 d2                	test   %edx,%edx
f0100337:	74 22                	je     f010035b <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f0100339:	a1 24 a2 22 f0       	mov    0xf022a224,%eax
f010033e:	88 90 20 a0 22 f0    	mov    %dl,-0xfdd5fe0(%eax)
f0100344:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f0100347:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f010034d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100352:	0f 44 d0             	cmove  %eax,%edx
f0100355:	89 15 24 a2 22 f0    	mov    %edx,0xf022a224
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010035b:	ff d3                	call   *%ebx
f010035d:	89 c2                	mov    %eax,%edx
f010035f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100362:	75 d1                	jne    f0100335 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100364:	83 c4 04             	add    $0x4,%esp
f0100367:	5b                   	pop    %ebx
f0100368:	5d                   	pop    %ebp
f0100369:	c3                   	ret    

f010036a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010036a:	55                   	push   %ebp
f010036b:	89 e5                	mov    %esp,%ebp
f010036d:	57                   	push   %edi
f010036e:	56                   	push   %esi
f010036f:	53                   	push   %ebx
f0100370:	83 ec 2c             	sub    $0x2c,%esp
f0100373:	89 c7                	mov    %eax,%edi
f0100375:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010037a:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010037b:	a8 20                	test   $0x20,%al
f010037d:	75 1b                	jne    f010039a <cons_putc+0x30>
f010037f:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100384:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100389:	e8 72 ff ff ff       	call   f0100300 <delay>
f010038e:	89 f2                	mov    %esi,%edx
f0100390:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f0100391:	a8 20                	test   $0x20,%al
f0100393:	75 05                	jne    f010039a <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100395:	83 eb 01             	sub    $0x1,%ebx
f0100398:	75 ef                	jne    f0100389 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f010039a:	89 f8                	mov    %edi,%eax
f010039c:	25 ff 00 00 00       	and    $0xff,%eax
f01003a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003a4:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003a9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003aa:	b2 79                	mov    $0x79,%dl
f01003ac:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003ad:	84 c0                	test   %al,%al
f01003af:	78 1b                	js     f01003cc <cons_putc+0x62>
f01003b1:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01003b6:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01003bb:	e8 40 ff ff ff       	call   f0100300 <delay>
f01003c0:	89 f2                	mov    %esi,%edx
f01003c2:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003c3:	84 c0                	test   %al,%al
f01003c5:	78 05                	js     f01003cc <cons_putc+0x62>
f01003c7:	83 eb 01             	sub    $0x1,%ebx
f01003ca:	75 ef                	jne    f01003bb <cons_putc+0x51>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003cc:	ba 78 03 00 00       	mov    $0x378,%edx
f01003d1:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f01003d5:	ee                   	out    %al,(%dx)
f01003d6:	b2 7a                	mov    $0x7a,%dl
f01003d8:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003dd:	ee                   	out    %al,(%dx)
f01003de:	b8 08 00 00 00       	mov    $0x8,%eax
f01003e3:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01003e4:	89 fa                	mov    %edi,%edx
f01003e6:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003ec:	89 f8                	mov    %edi,%eax
f01003ee:	80 cc 07             	or     $0x7,%ah
f01003f1:	85 d2                	test   %edx,%edx
f01003f3:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003f6:	89 f8                	mov    %edi,%eax
f01003f8:	25 ff 00 00 00       	and    $0xff,%eax
f01003fd:	83 f8 09             	cmp    $0x9,%eax
f0100400:	74 77                	je     f0100479 <cons_putc+0x10f>
f0100402:	83 f8 09             	cmp    $0x9,%eax
f0100405:	7f 0b                	jg     f0100412 <cons_putc+0xa8>
f0100407:	83 f8 08             	cmp    $0x8,%eax
f010040a:	0f 85 9d 00 00 00    	jne    f01004ad <cons_putc+0x143>
f0100410:	eb 10                	jmp    f0100422 <cons_putc+0xb8>
f0100412:	83 f8 0a             	cmp    $0xa,%eax
f0100415:	74 3c                	je     f0100453 <cons_putc+0xe9>
f0100417:	83 f8 0d             	cmp    $0xd,%eax
f010041a:	0f 85 8d 00 00 00    	jne    f01004ad <cons_putc+0x143>
f0100420:	eb 39                	jmp    f010045b <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f0100422:	0f b7 05 34 a2 22 f0 	movzwl 0xf022a234,%eax
f0100429:	66 85 c0             	test   %ax,%ax
f010042c:	0f 84 e5 00 00 00    	je     f0100517 <cons_putc+0x1ad>
			crt_pos--;
f0100432:	83 e8 01             	sub    $0x1,%eax
f0100435:	66 a3 34 a2 22 f0    	mov    %ax,0xf022a234
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010043b:	0f b7 c0             	movzwl %ax,%eax
f010043e:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f0100444:	83 cf 20             	or     $0x20,%edi
f0100447:	8b 15 30 a2 22 f0    	mov    0xf022a230,%edx
f010044d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100451:	eb 77                	jmp    f01004ca <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100453:	66 83 05 34 a2 22 f0 	addw   $0x50,0xf022a234
f010045a:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010045b:	0f b7 05 34 a2 22 f0 	movzwl 0xf022a234,%eax
f0100462:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100468:	c1 e8 16             	shr    $0x16,%eax
f010046b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010046e:	c1 e0 04             	shl    $0x4,%eax
f0100471:	66 a3 34 a2 22 f0    	mov    %ax,0xf022a234
f0100477:	eb 51                	jmp    f01004ca <cons_putc+0x160>
		break;
	case '\t':
		cons_putc(' ');
f0100479:	b8 20 00 00 00       	mov    $0x20,%eax
f010047e:	e8 e7 fe ff ff       	call   f010036a <cons_putc>
		cons_putc(' ');
f0100483:	b8 20 00 00 00       	mov    $0x20,%eax
f0100488:	e8 dd fe ff ff       	call   f010036a <cons_putc>
		cons_putc(' ');
f010048d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100492:	e8 d3 fe ff ff       	call   f010036a <cons_putc>
		cons_putc(' ');
f0100497:	b8 20 00 00 00       	mov    $0x20,%eax
f010049c:	e8 c9 fe ff ff       	call   f010036a <cons_putc>
		cons_putc(' ');
f01004a1:	b8 20 00 00 00       	mov    $0x20,%eax
f01004a6:	e8 bf fe ff ff       	call   f010036a <cons_putc>
f01004ab:	eb 1d                	jmp    f01004ca <cons_putc+0x160>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01004ad:	0f b7 05 34 a2 22 f0 	movzwl 0xf022a234,%eax
f01004b4:	0f b7 c8             	movzwl %ax,%ecx
f01004b7:	8b 15 30 a2 22 f0    	mov    0xf022a230,%edx
f01004bd:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f01004c1:	83 c0 01             	add    $0x1,%eax
f01004c4:	66 a3 34 a2 22 f0    	mov    %ax,0xf022a234
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01004ca:	66 81 3d 34 a2 22 f0 	cmpw   $0x7cf,0xf022a234
f01004d1:	cf 07 
f01004d3:	76 42                	jbe    f0100517 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004d5:	a1 30 a2 22 f0       	mov    0xf022a230,%eax
f01004da:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01004e1:	00 
f01004e2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004e8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01004ec:	89 04 24             	mov    %eax,(%esp)
f01004ef:	e8 ff 58 00 00       	call   f0105df3 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004f4:	8b 15 30 a2 22 f0    	mov    0xf022a230,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004fa:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004ff:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100505:	83 c0 01             	add    $0x1,%eax
f0100508:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010050d:	75 f0                	jne    f01004ff <cons_putc+0x195>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010050f:	66 83 2d 34 a2 22 f0 	subw   $0x50,0xf022a234
f0100516:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100517:	8b 0d 2c a2 22 f0    	mov    0xf022a22c,%ecx
f010051d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100522:	89 ca                	mov    %ecx,%edx
f0100524:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100525:	0f b7 1d 34 a2 22 f0 	movzwl 0xf022a234,%ebx
f010052c:	8d 71 01             	lea    0x1(%ecx),%esi
f010052f:	89 d8                	mov    %ebx,%eax
f0100531:	66 c1 e8 08          	shr    $0x8,%ax
f0100535:	89 f2                	mov    %esi,%edx
f0100537:	ee                   	out    %al,(%dx)
f0100538:	b8 0f 00 00 00       	mov    $0xf,%eax
f010053d:	89 ca                	mov    %ecx,%edx
f010053f:	ee                   	out    %al,(%dx)
f0100540:	89 d8                	mov    %ebx,%eax
f0100542:	89 f2                	mov    %esi,%edx
f0100544:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100545:	83 c4 2c             	add    $0x2c,%esp
f0100548:	5b                   	pop    %ebx
f0100549:	5e                   	pop    %esi
f010054a:	5f                   	pop    %edi
f010054b:	5d                   	pop    %ebp
f010054c:	c3                   	ret    

f010054d <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010054d:	55                   	push   %ebp
f010054e:	89 e5                	mov    %esp,%ebp
f0100550:	53                   	push   %ebx
f0100551:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100554:	ba 64 00 00 00       	mov    $0x64,%edx
f0100559:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010055a:	a8 01                	test   $0x1,%al
f010055c:	0f 84 e5 00 00 00    	je     f0100647 <kbd_proc_data+0xfa>
f0100562:	b2 60                	mov    $0x60,%dl
f0100564:	ec                   	in     (%dx),%al
f0100565:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100567:	3c e0                	cmp    $0xe0,%al
f0100569:	75 11                	jne    f010057c <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f010056b:	83 0d 28 a2 22 f0 40 	orl    $0x40,0xf022a228
		return 0;
f0100572:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100577:	e9 d0 00 00 00       	jmp    f010064c <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f010057c:	84 c0                	test   %al,%al
f010057e:	79 37                	jns    f01005b7 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100580:	8b 0d 28 a2 22 f0    	mov    0xf022a228,%ecx
f0100586:	89 cb                	mov    %ecx,%ebx
f0100588:	83 e3 40             	and    $0x40,%ebx
f010058b:	83 e0 7f             	and    $0x7f,%eax
f010058e:	85 db                	test   %ebx,%ebx
f0100590:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100593:	0f b6 d2             	movzbl %dl,%edx
f0100596:	0f b6 82 a0 6c 10 f0 	movzbl -0xfef9360(%edx),%eax
f010059d:	83 c8 40             	or     $0x40,%eax
f01005a0:	0f b6 c0             	movzbl %al,%eax
f01005a3:	f7 d0                	not    %eax
f01005a5:	21 c1                	and    %eax,%ecx
f01005a7:	89 0d 28 a2 22 f0    	mov    %ecx,0xf022a228
		return 0;
f01005ad:	bb 00 00 00 00       	mov    $0x0,%ebx
f01005b2:	e9 95 00 00 00       	jmp    f010064c <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f01005b7:	8b 0d 28 a2 22 f0    	mov    0xf022a228,%ecx
f01005bd:	f6 c1 40             	test   $0x40,%cl
f01005c0:	74 0e                	je     f01005d0 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01005c2:	89 c2                	mov    %eax,%edx
f01005c4:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01005c7:	83 e1 bf             	and    $0xffffffbf,%ecx
f01005ca:	89 0d 28 a2 22 f0    	mov    %ecx,0xf022a228
	}

	shift |= shiftcode[data];
f01005d0:	0f b6 d2             	movzbl %dl,%edx
f01005d3:	0f b6 82 a0 6c 10 f0 	movzbl -0xfef9360(%edx),%eax
f01005da:	0b 05 28 a2 22 f0    	or     0xf022a228,%eax
	shift ^= togglecode[data];
f01005e0:	0f b6 8a a0 6d 10 f0 	movzbl -0xfef9260(%edx),%ecx
f01005e7:	31 c8                	xor    %ecx,%eax
f01005e9:	a3 28 a2 22 f0       	mov    %eax,0xf022a228

	c = charcode[shift & (CTL | SHIFT)][data];
f01005ee:	89 c1                	mov    %eax,%ecx
f01005f0:	83 e1 03             	and    $0x3,%ecx
f01005f3:	8b 0c 8d a0 6e 10 f0 	mov    -0xfef9160(,%ecx,4),%ecx
f01005fa:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01005fe:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100601:	a8 08                	test   $0x8,%al
f0100603:	74 1b                	je     f0100620 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100605:	89 da                	mov    %ebx,%edx
f0100607:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010060a:	83 f9 19             	cmp    $0x19,%ecx
f010060d:	77 05                	ja     f0100614 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010060f:	83 eb 20             	sub    $0x20,%ebx
f0100612:	eb 0c                	jmp    f0100620 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100614:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100617:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010061a:	83 fa 19             	cmp    $0x19,%edx
f010061d:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100620:	f7 d0                	not    %eax
f0100622:	a8 06                	test   $0x6,%al
f0100624:	75 26                	jne    f010064c <kbd_proc_data+0xff>
f0100626:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010062c:	75 1e                	jne    f010064c <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f010062e:	c7 04 24 62 6c 10 f0 	movl   $0xf0106c62,(%esp)
f0100635:	e8 bc 36 00 00       	call   f0103cf6 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010063a:	ba 92 00 00 00       	mov    $0x92,%edx
f010063f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100644:	ee                   	out    %al,(%dx)
f0100645:	eb 05                	jmp    f010064c <kbd_proc_data+0xff>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100647:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010064c:	89 d8                	mov    %ebx,%eax
f010064e:	83 c4 14             	add    $0x14,%esp
f0100651:	5b                   	pop    %ebx
f0100652:	5d                   	pop    %ebp
f0100653:	c3                   	ret    

f0100654 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100654:	83 3d 00 a0 22 f0 00 	cmpl   $0x0,0xf022a000
f010065b:	74 11                	je     f010066e <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100663:	b8 0e 03 10 f0       	mov    $0xf010030e,%eax
f0100668:	e8 bd fc ff ff       	call   f010032a <cons_intr>
}
f010066d:	c9                   	leave  
f010066e:	f3 c3                	repz ret 

f0100670 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100670:	55                   	push   %ebp
f0100671:	89 e5                	mov    %esp,%ebp
f0100673:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100676:	b8 4d 05 10 f0       	mov    $0xf010054d,%eax
f010067b:	e8 aa fc ff ff       	call   f010032a <cons_intr>
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
f0100685:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100688:	e8 c7 ff ff ff       	call   f0100654 <serial_intr>
	kbd_intr();
f010068d:	e8 de ff ff ff       	call   f0100670 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100692:	8b 15 20 a2 22 f0    	mov    0xf022a220,%edx
f0100698:	3b 15 24 a2 22 f0    	cmp    0xf022a224,%edx
f010069e:	74 20                	je     f01006c0 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01006a0:	0f b6 82 20 a0 22 f0 	movzbl -0xfdd5fe0(%edx),%eax
f01006a7:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f01006aa:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f01006b0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01006b5:	0f 44 d1             	cmove  %ecx,%edx
f01006b8:	89 15 20 a2 22 f0    	mov    %edx,0xf022a220
f01006be:	eb 05                	jmp    f01006c5 <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01006c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01006c5:	c9                   	leave  
f01006c6:	c3                   	ret    

f01006c7 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01006c7:	55                   	push   %ebp
f01006c8:	89 e5                	mov    %esp,%ebp
f01006ca:	57                   	push   %edi
f01006cb:	56                   	push   %esi
f01006cc:	53                   	push   %ebx
f01006cd:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01006d0:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01006d7:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01006de:	5a a5 
	if (*cp != 0xA55A) {
f01006e0:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01006e7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01006eb:	74 11                	je     f01006fe <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01006ed:	c7 05 2c a2 22 f0 b4 	movl   $0x3b4,0xf022a22c
f01006f4:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006f7:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01006fc:	eb 16                	jmp    f0100714 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01006fe:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100705:	c7 05 2c a2 22 f0 d4 	movl   $0x3d4,0xf022a22c
f010070c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010070f:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100714:	8b 0d 2c a2 22 f0    	mov    0xf022a22c,%ecx
f010071a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010071f:	89 ca                	mov    %ecx,%edx
f0100721:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100722:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100725:	89 da                	mov    %ebx,%edx
f0100727:	ec                   	in     (%dx),%al
f0100728:	0f b6 f0             	movzbl %al,%esi
f010072b:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010072e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100733:	89 ca                	mov    %ecx,%edx
f0100735:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100736:	89 da                	mov    %ebx,%edx
f0100738:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100739:	89 3d 30 a2 22 f0    	mov    %edi,0xf022a230
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010073f:	0f b6 d8             	movzbl %al,%ebx
f0100742:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100744:	66 89 35 34 a2 22 f0 	mov    %si,0xf022a234

static void
kbd_init(void)
{
	// Drain the kbd buffer so that Bochs generates interrupts.
	kbd_intr();
f010074b:	e8 20 ff ff ff       	call   f0100670 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f0100750:	0f b7 05 88 13 12 f0 	movzwl 0xf0121388,%eax
f0100757:	25 fd ff 00 00       	and    $0xfffd,%eax
f010075c:	89 04 24             	mov    %eax,(%esp)
f010075f:	e8 50 34 00 00       	call   f0103bb4 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100764:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100769:	b8 00 00 00 00       	mov    $0x0,%eax
f010076e:	89 f2                	mov    %esi,%edx
f0100770:	ee                   	out    %al,(%dx)
f0100771:	b2 fb                	mov    $0xfb,%dl
f0100773:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100778:	ee                   	out    %al,(%dx)
f0100779:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010077e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100783:	89 da                	mov    %ebx,%edx
f0100785:	ee                   	out    %al,(%dx)
f0100786:	b2 f9                	mov    $0xf9,%dl
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	ee                   	out    %al,(%dx)
f010078e:	b2 fb                	mov    $0xfb,%dl
f0100790:	b8 03 00 00 00       	mov    $0x3,%eax
f0100795:	ee                   	out    %al,(%dx)
f0100796:	b2 fc                	mov    $0xfc,%dl
f0100798:	b8 00 00 00 00       	mov    $0x0,%eax
f010079d:	ee                   	out    %al,(%dx)
f010079e:	b2 f9                	mov    $0xf9,%dl
f01007a0:	b8 01 00 00 00       	mov    $0x1,%eax
f01007a5:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01007a6:	b2 fd                	mov    $0xfd,%dl
f01007a8:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01007a9:	3c ff                	cmp    $0xff,%al
f01007ab:	0f 95 c1             	setne  %cl
f01007ae:	0f b6 c9             	movzbl %cl,%ecx
f01007b1:	89 0d 00 a0 22 f0    	mov    %ecx,0xf022a000
f01007b7:	89 f2                	mov    %esi,%edx
f01007b9:	ec                   	in     (%dx),%al
f01007ba:	89 da                	mov    %ebx,%edx
f01007bc:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01007bd:	85 c9                	test   %ecx,%ecx
f01007bf:	75 0c                	jne    f01007cd <cons_init+0x106>
		cprintf("Serial port does not exist!\n");
f01007c1:	c7 04 24 6e 6c 10 f0 	movl   $0xf0106c6e,(%esp)
f01007c8:	e8 29 35 00 00       	call   f0103cf6 <cprintf>
}
f01007cd:	83 c4 1c             	add    $0x1c,%esp
f01007d0:	5b                   	pop    %ebx
f01007d1:	5e                   	pop    %esi
f01007d2:	5f                   	pop    %edi
f01007d3:	5d                   	pop    %ebp
f01007d4:	c3                   	ret    

f01007d5 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01007d5:	55                   	push   %ebp
f01007d6:	89 e5                	mov    %esp,%ebp
f01007d8:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01007db:	8b 45 08             	mov    0x8(%ebp),%eax
f01007de:	e8 87 fb ff ff       	call   f010036a <cons_putc>
}
f01007e3:	c9                   	leave  
f01007e4:	c3                   	ret    

f01007e5 <getchar>:

int
getchar(void)
{
f01007e5:	55                   	push   %ebp
f01007e6:	89 e5                	mov    %esp,%ebp
f01007e8:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007eb:	e8 92 fe ff ff       	call   f0100682 <cons_getc>
f01007f0:	85 c0                	test   %eax,%eax
f01007f2:	74 f7                	je     f01007eb <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007f4:	c9                   	leave  
f01007f5:	c3                   	ret    

f01007f6 <iscons>:

int
iscons(int fdnum)
{
f01007f6:	55                   	push   %ebp
f01007f7:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007f9:	b8 01 00 00 00       	mov    $0x1,%eax
f01007fe:	5d                   	pop    %ebp
f01007ff:	c3                   	ret    

f0100800 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100800:	55                   	push   %ebp
f0100801:	89 e5                	mov    %esp,%ebp
f0100803:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100806:	c7 04 24 b0 6e 10 f0 	movl   $0xf0106eb0,(%esp)
f010080d:	e8 e4 34 00 00       	call   f0103cf6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100812:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100819:	00 
f010081a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100821:	f0 
f0100822:	c7 04 24 c8 6f 10 f0 	movl   $0xf0106fc8,(%esp)
f0100829:	e8 c8 34 00 00       	call   f0103cf6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010082e:	c7 44 24 08 9f 6b 10 	movl   $0x106b9f,0x8(%esp)
f0100835:	00 
f0100836:	c7 44 24 04 9f 6b 10 	movl   $0xf0106b9f,0x4(%esp)
f010083d:	f0 
f010083e:	c7 04 24 ec 6f 10 f0 	movl   $0xf0106fec,(%esp)
f0100845:	e8 ac 34 00 00       	call   f0103cf6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010084a:	c7 44 24 08 62 98 22 	movl   $0x229862,0x8(%esp)
f0100851:	00 
f0100852:	c7 44 24 04 62 98 22 	movl   $0xf0229862,0x4(%esp)
f0100859:	f0 
f010085a:	c7 04 24 10 70 10 f0 	movl   $0xf0107010,(%esp)
f0100861:	e8 90 34 00 00       	call   f0103cf6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100866:	c7 44 24 08 04 c0 26 	movl   $0x26c004,0x8(%esp)
f010086d:	00 
f010086e:	c7 44 24 04 04 c0 26 	movl   $0xf026c004,0x4(%esp)
f0100875:	f0 
f0100876:	c7 04 24 34 70 10 f0 	movl   $0xf0107034,(%esp)
f010087d:	e8 74 34 00 00       	call   f0103cf6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100882:	b8 03 c4 26 f0       	mov    $0xf026c403,%eax
f0100887:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010088c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100892:	85 c0                	test   %eax,%eax
f0100894:	0f 48 c2             	cmovs  %edx,%eax
f0100897:	c1 f8 0a             	sar    $0xa,%eax
f010089a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089e:	c7 04 24 58 70 10 f0 	movl   $0xf0107058,(%esp)
f01008a5:	e8 4c 34 00 00       	call   f0103cf6 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01008aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01008af:	c9                   	leave  
f01008b0:	c3                   	ret    

f01008b1 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01008b1:	55                   	push   %ebp
f01008b2:	89 e5                	mov    %esp,%ebp
f01008b4:	56                   	push   %esi
f01008b5:	53                   	push   %ebx
f01008b6:	83 ec 10             	sub    $0x10,%esp
f01008b9:	bb 04 71 10 f0       	mov    $0xf0107104,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f01008be:	be 40 71 10 f0       	mov    $0xf0107140,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01008c3:	8b 03                	mov    (%ebx),%eax
f01008c5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008c9:	8b 43 fc             	mov    -0x4(%ebx),%eax
f01008cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d0:	c7 04 24 c9 6e 10 f0 	movl   $0xf0106ec9,(%esp)
f01008d7:	e8 1a 34 00 00       	call   f0103cf6 <cprintf>
f01008dc:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01008df:	39 f3                	cmp    %esi,%ebx
f01008e1:	75 e0                	jne    f01008c3 <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f01008e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e8:	83 c4 10             	add    $0x10,%esp
f01008eb:	5b                   	pop    %ebx
f01008ec:	5e                   	pop    %esi
f01008ed:	5d                   	pop    %ebp
f01008ee:	c3                   	ret    

f01008ef <mon_debug>:
	}
	return -1;
}

int
mon_debug(int argc, char **argv, struct Trapframe *tf){
f01008ef:	55                   	push   %ebp
f01008f0:	89 e5                	mov    %esp,%ebp
f01008f2:	83 ec 18             	sub    $0x18,%esp
f01008f5:	8b 45 10             	mov    0x10(%ebp),%eax
	if(tf -> tf_trapno == T_BRKPT || tf -> tf_trapno == T_DEBUG){
f01008f8:	8b 50 28             	mov    0x28(%eax),%edx
f01008fb:	83 e2 fd             	and    $0xfffffffd,%edx
f01008fe:	83 fa 01             	cmp    $0x1,%edx
f0100901:	75 1d                	jne    f0100920 <mon_debug+0x31>
		tf -> tf_eflags |= FL_TF;
f0100903:	81 48 38 00 01 00 00 	orl    $0x100,0x38(%eax)
		env_run(curenv);
f010090a:	e8 2d 5b 00 00       	call   f010643c <cpunum>
f010090f:	6b c0 74             	imul   $0x74,%eax,%eax
f0100912:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0100918:	89 04 24             	mov    %eax,(%esp)
f010091b:	e8 99 31 00 00       	call   f0103ab9 <env_run>
	}
	return -1;
}
f0100920:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100925:	c9                   	leave  
f0100926:	c3                   	ret    

f0100927 <mon_continue>:
	}while(ebp);
	return 0;
}

int
mon_continue(int argc, char **argv, struct Trapframe *tf){
f0100927:	55                   	push   %ebp
f0100928:	89 e5                	mov    %esp,%ebp
f010092a:	83 ec 18             	sub    $0x18,%esp
f010092d:	8b 45 10             	mov    0x10(%ebp),%eax
	if(tf -> tf_trapno == T_BRKPT || tf -> tf_trapno == T_DEBUG){
f0100930:	8b 50 28             	mov    0x28(%eax),%edx
f0100933:	83 e2 fd             	and    $0xfffffffd,%edx
f0100936:	83 fa 01             	cmp    $0x1,%edx
f0100939:	75 1d                	jne    f0100958 <mon_continue+0x31>
	//	panic("##%x##\n",tf -> tf_eflags);
		tf -> tf_eflags &= ~FL_TF;
f010093b:	81 60 38 ff fe ff ff 	andl   $0xfffffeff,0x38(%eax)
		env_run(curenv);
f0100942:	e8 f5 5a 00 00       	call   f010643c <cpunum>
f0100947:	6b c0 74             	imul   $0x74,%eax,%eax
f010094a:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0100950:	89 04 24             	mov    %eax,(%esp)
f0100953:	e8 61 31 00 00       	call   f0103ab9 <env_run>
	}
	return -1;
}
f0100958:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010095d:	c9                   	leave  
f010095e:	c3                   	ret    

f010095f <mon_backtrace>:
 * 2. *ebp is the new ebp(actually old)
 * 3. get the end(ebp = 0 -> see kern/entry.S, stack movl $0, %ebp)
 */
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010095f:	55                   	push   %ebp
f0100960:	89 e5                	mov    %esp,%ebp
f0100962:	57                   	push   %edi
f0100963:	56                   	push   %esi
f0100964:	53                   	push   %ebx
f0100965:	83 ec 3c             	sub    $0x3c,%esp
	// Your code here.
	uint32_t ebp,eip;
	int i;	
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100968:	c7 04 24 d2 6e 10 f0 	movl   $0xf0106ed2,(%esp)
f010096f:	e8 82 33 00 00       	call   f0103cf6 <cprintf>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100974:	89 ee                	mov    %ebp,%esi
	ebp = read_ebp();
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
f0100976:	89 74 24 04          	mov    %esi,0x4(%esp)
f010097a:	c7 04 24 e4 6e 10 f0 	movl   $0xf0106ee4,(%esp)
f0100981:	e8 70 33 00 00       	call   f0103cf6 <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f0100986:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f0100989:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010098d:	c7 04 24 ef 6e 10 f0 	movl   $0xf0106eef,(%esp)
f0100994:	e8 5d 33 00 00       	call   f0103cf6 <cprintf>
		for(i=2; i < 7; i++)
f0100999:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f010099e:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01009a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009a5:	c7 04 24 e9 6e 10 f0 	movl   $0xf0106ee9,(%esp)
f01009ac:	e8 45 33 00 00       	call   f0103cf6 <cprintf>
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
		eip = *(uint32_t *)(ebp + 4);
		cprintf("  eip %08x  args",eip);
		for(i=2; i < 7; i++)
f01009b1:	83 c3 01             	add    $0x1,%ebx
f01009b4:	83 fb 07             	cmp    $0x7,%ebx
f01009b7:	75 e5                	jne    f010099e <mon_backtrace+0x3f>
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
		cprintf("\n");
f01009b9:	c7 04 24 58 78 10 f0 	movl   $0xf0107858,(%esp)
f01009c0:	e8 31 33 00 00       	call   f0103cf6 <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f01009c5:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01009c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cc:	89 3c 24             	mov    %edi,(%esp)
f01009cf:	e8 b2 47 00 00       	call   f0105186 <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f01009d4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01009d7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009db:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01009de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009e2:	c7 04 24 00 6f 10 f0 	movl   $0xf0106f00,(%esp)
f01009e9:	e8 08 33 00 00       	call   f0103cf6 <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f01009ee:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009f1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009f5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01009f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009fc:	c7 04 24 09 6f 10 f0 	movl   $0xf0106f09,(%esp)
f0100a03:	e8 ee 32 00 00       	call   f0103cf6 <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f0100a08:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a0b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a0f:	c7 04 24 0e 6f 10 f0 	movl   $0xf0106f0e,(%esp)
f0100a16:	e8 db 32 00 00       	call   f0103cf6 <cprintf>
		ebp = *(uint32_t *)ebp;
f0100a1b:	8b 36                	mov    (%esi),%esi
	}while(ebp);
f0100a1d:	85 f6                	test   %esi,%esi
f0100a1f:	0f 85 51 ff ff ff    	jne    f0100976 <mon_backtrace+0x17>
	return 0;
}
f0100a25:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a2a:	83 c4 3c             	add    $0x3c,%esp
f0100a2d:	5b                   	pop    %ebx
f0100a2e:	5e                   	pop    %esi
f0100a2f:	5f                   	pop    %edi
f0100a30:	5d                   	pop    %ebp
f0100a31:	c3                   	ret    

f0100a32 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100a32:	55                   	push   %ebp
f0100a33:	89 e5                	mov    %esp,%ebp
f0100a35:	57                   	push   %edi
f0100a36:	56                   	push   %esi
f0100a37:	53                   	push   %ebx
f0100a38:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100a3b:	c7 04 24 84 70 10 f0 	movl   $0xf0107084,(%esp)
f0100a42:	e8 af 32 00 00       	call   f0103cf6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a47:	c7 04 24 a8 70 10 f0 	movl   $0xf01070a8,(%esp)
f0100a4e:	e8 a3 32 00 00       	call   f0103cf6 <cprintf>

	if (tf != NULL)
f0100a53:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100a57:	74 0b                	je     f0100a64 <monitor+0x32>
		print_trapframe(tf);
f0100a59:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a5c:	89 04 24             	mov    %eax,(%esp)
f0100a5f:	e8 84 38 00 00       	call   f01042e8 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100a64:	c7 04 24 13 6f 10 f0 	movl   $0xf0106f13,(%esp)
f0100a6b:	e8 50 50 00 00       	call   f0105ac0 <readline>
f0100a70:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100a72:	85 c0                	test   %eax,%eax
f0100a74:	74 ee                	je     f0100a64 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100a76:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100a7d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a82:	eb 06                	jmp    f0100a8a <monitor+0x58>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100a84:	c6 06 00             	movb   $0x0,(%esi)
f0100a87:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100a8a:	0f b6 06             	movzbl (%esi),%eax
f0100a8d:	84 c0                	test   %al,%al
f0100a8f:	74 6a                	je     f0100afb <monitor+0xc9>
f0100a91:	0f be c0             	movsbl %al,%eax
f0100a94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a98:	c7 04 24 17 6f 10 f0 	movl   $0xf0106f17,(%esp)
f0100a9f:	e8 91 52 00 00       	call   f0105d35 <strchr>
f0100aa4:	85 c0                	test   %eax,%eax
f0100aa6:	75 dc                	jne    f0100a84 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100aa8:	80 3e 00             	cmpb   $0x0,(%esi)
f0100aab:	74 4e                	je     f0100afb <monitor+0xc9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100aad:	83 fb 0f             	cmp    $0xf,%ebx
f0100ab0:	75 16                	jne    f0100ac8 <monitor+0x96>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100ab2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100ab9:	00 
f0100aba:	c7 04 24 1c 6f 10 f0 	movl   $0xf0106f1c,(%esp)
f0100ac1:	e8 30 32 00 00       	call   f0103cf6 <cprintf>
f0100ac6:	eb 9c                	jmp    f0100a64 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100ac8:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f0100acc:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100acf:	0f b6 06             	movzbl (%esi),%eax
f0100ad2:	84 c0                	test   %al,%al
f0100ad4:	75 0c                	jne    f0100ae2 <monitor+0xb0>
f0100ad6:	eb b2                	jmp    f0100a8a <monitor+0x58>
			buf++;
f0100ad8:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100adb:	0f b6 06             	movzbl (%esi),%eax
f0100ade:	84 c0                	test   %al,%al
f0100ae0:	74 a8                	je     f0100a8a <monitor+0x58>
f0100ae2:	0f be c0             	movsbl %al,%eax
f0100ae5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ae9:	c7 04 24 17 6f 10 f0 	movl   $0xf0106f17,(%esp)
f0100af0:	e8 40 52 00 00       	call   f0105d35 <strchr>
f0100af5:	85 c0                	test   %eax,%eax
f0100af7:	74 df                	je     f0100ad8 <monitor+0xa6>
f0100af9:	eb 8f                	jmp    f0100a8a <monitor+0x58>
			buf++;
	}
	argv[argc] = 0;
f0100afb:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100b02:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100b03:	85 db                	test   %ebx,%ebx
f0100b05:	0f 84 59 ff ff ff    	je     f0100a64 <monitor+0x32>
f0100b0b:	bf 00 71 10 f0       	mov    $0xf0107100,%edi
f0100b10:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b15:	8b 07                	mov    (%edi),%eax
f0100b17:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b1b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b1e:	89 04 24             	mov    %eax,(%esp)
f0100b21:	e8 8b 51 00 00       	call   f0105cb1 <strcmp>
f0100b26:	85 c0                	test   %eax,%eax
f0100b28:	75 24                	jne    f0100b4e <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100b2a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100b2d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b30:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100b34:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100b37:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100b3b:	89 1c 24             	mov    %ebx,(%esp)
f0100b3e:	ff 14 85 08 71 10 f0 	call   *-0xfef8ef8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100b45:	85 c0                	test   %eax,%eax
f0100b47:	78 28                	js     f0100b71 <monitor+0x13f>
f0100b49:	e9 16 ff ff ff       	jmp    f0100a64 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100b4e:	83 c6 01             	add    $0x1,%esi
f0100b51:	83 c7 0c             	add    $0xc,%edi
f0100b54:	83 fe 05             	cmp    $0x5,%esi
f0100b57:	75 bc                	jne    f0100b15 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100b59:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b60:	c7 04 24 39 6f 10 f0 	movl   $0xf0106f39,(%esp)
f0100b67:	e8 8a 31 00 00       	call   f0103cf6 <cprintf>
f0100b6c:	e9 f3 fe ff ff       	jmp    f0100a64 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100b71:	83 c4 5c             	add    $0x5c,%esp
f0100b74:	5b                   	pop    %ebx
f0100b75:	5e                   	pop    %esi
f0100b76:	5f                   	pop    %edi
f0100b77:	5d                   	pop    %ebp
f0100b78:	c3                   	ret    

f0100b79 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100b79:	55                   	push   %ebp
f0100b7a:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100b7c:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100b7f:	5d                   	pop    %ebp
f0100b80:	c3                   	ret    
f0100b81:	66 90                	xchg   %ax,%ax
f0100b83:	66 90                	xchg   %ax,%ax
f0100b85:	66 90                	xchg   %ax,%ax
f0100b87:	66 90                	xchg   %ax,%ax
f0100b89:	66 90                	xchg   %ax,%ax
f0100b8b:	66 90                	xchg   %ax,%ax
f0100b8d:	66 90                	xchg   %ax,%ax
f0100b8f:	90                   	nop

f0100b90 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b90:	89 d1                	mov    %edx,%ecx
f0100b92:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100b95:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100b98:	a8 01                	test   $0x1,%al
f0100b9a:	74 5d                	je     f0100bf9 <check_va2pa+0x69>
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b9c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ba1:	89 c1                	mov    %eax,%ecx
f0100ba3:	c1 e9 0c             	shr    $0xc,%ecx
f0100ba6:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0100bac:	72 26                	jb     f0100bd4 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100bae:	55                   	push   %ebp
f0100baf:	89 e5                	mov    %esp,%ebp
f0100bb1:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bb4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bb8:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0100bbf:	f0 
f0100bc0:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0100bc7:	00 
f0100bc8:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100bcf:	e8 6c f4 ff ff       	call   f0100040 <_panic>
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100bd4:	c1 ea 0c             	shr    $0xc,%edx
f0100bd7:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100bdd:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100be4:	89 c2                	mov    %eax,%edx
f0100be6:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100be9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bee:	85 d2                	test   %edx,%edx
f0100bf0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100bf5:	0f 44 c2             	cmove  %edx,%eax
f0100bf8:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100bf9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100bfe:	c3                   	ret    

f0100bff <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100bff:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100c01:	83 3d 3c a2 22 f0 00 	cmpl   $0x0,0xf022a23c
f0100c08:	75 0f                	jne    f0100c19 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100c0a:	b8 03 d0 26 f0       	mov    $0xf026d003,%eax
f0100c0f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c14:	a3 3c a2 22 f0       	mov    %eax,0xf022a23c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f0100c19:	85 d2                	test   %edx,%edx
f0100c1b:	75 06                	jne    f0100c23 <boot_alloc+0x24>
		return nextfree;
f0100c1d:	a1 3c a2 22 f0       	mov    0xf022a23c,%eax
f0100c22:	c3                   	ret    
	result = nextfree;
f0100c23:	a1 3c a2 22 f0       	mov    0xf022a23c,%eax
	nextfree += (n/PGSIZE + 1)*PGSIZE;
f0100c28:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100c2e:	8d 94 10 00 10 00 00 	lea    0x1000(%eax,%edx,1),%edx
f0100c35:	89 15 3c a2 22 f0    	mov    %edx,0xf022a23c
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
f0100c3b:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0100c41:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f0100c47:	c1 e1 0c             	shl    $0xc,%ecx
f0100c4a:	39 ca                	cmp    %ecx,%edx
f0100c4c:	72 22                	jb     f0100c70 <boot_alloc+0x71>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100c4e:	55                   	push   %ebp
f0100c4f:	89 e5                	mov    %esp,%ebp
f0100c51:	83 ec 18             	sub    $0x18,%esp
	if(n == 0)
		return nextfree;
	result = nextfree;
	nextfree += (n/PGSIZE + 1)*PGSIZE;
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
		panic("Run out of memory!!\n");
f0100c54:	c7 44 24 08 45 78 10 	movl   $0xf0107845,0x8(%esp)
f0100c5b:	f0 
f0100c5c:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
f0100c63:	00 
f0100c64:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100c6b:	e8 d0 f3 ff ff       	call   f0100040 <_panic>
	return result;
}
f0100c70:	f3 c3                	repz ret 

f0100c72 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100c72:	55                   	push   %ebp
f0100c73:	89 e5                	mov    %esp,%ebp
f0100c75:	83 ec 18             	sub    $0x18,%esp
f0100c78:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100c7b:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100c7e:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100c80:	89 04 24             	mov    %eax,(%esp)
f0100c83:	e8 00 2f 00 00       	call   f0103b88 <mc146818_read>
f0100c88:	89 c6                	mov    %eax,%esi
f0100c8a:	83 c3 01             	add    $0x1,%ebx
f0100c8d:	89 1c 24             	mov    %ebx,(%esp)
f0100c90:	e8 f3 2e 00 00       	call   f0103b88 <mc146818_read>
f0100c95:	c1 e0 08             	shl    $0x8,%eax
f0100c98:	09 f0                	or     %esi,%eax
}
f0100c9a:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100c9d:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100ca0:	89 ec                	mov    %ebp,%esp
f0100ca2:	5d                   	pop    %ebp
f0100ca3:	c3                   	ret    

f0100ca4 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100ca4:	55                   	push   %ebp
f0100ca5:	89 e5                	mov    %esp,%ebp
f0100ca7:	57                   	push   %edi
f0100ca8:	56                   	push   %esi
f0100ca9:	53                   	push   %ebx
f0100caa:	83 ec 4c             	sub    $0x4c,%esp
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cad:	85 c0                	test   %eax,%eax
f0100caf:	0f 85 71 03 00 00    	jne    f0101026 <check_page_free_list+0x382>
f0100cb5:	e9 7e 03 00 00       	jmp    f0101038 <check_page_free_list+0x394>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100cba:	c7 44 24 08 3c 71 10 	movl   $0xf010713c,0x8(%esp)
f0100cc1:	f0 
f0100cc2:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0100cc9:	00 
f0100cca:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100cd1:	e8 6a f3 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100cd6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100cd9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100cdc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100cdf:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ce2:	89 c2                	mov    %eax,%edx
f0100ce4:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100cea:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100cf0:	0f 95 c2             	setne  %dl
f0100cf3:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100cf6:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100cfa:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100cfc:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d00:	8b 00                	mov    (%eax),%eax
f0100d02:	85 c0                	test   %eax,%eax
f0100d04:	75 dc                	jne    f0100ce2 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100d06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d09:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100d0f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d12:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d15:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100d17:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d1a:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d1f:	89 c3                	mov    %eax,%ebx
f0100d21:	85 c0                	test   %eax,%eax
f0100d23:	74 6c                	je     f0100d91 <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d25:	be 01 00 00 00       	mov    $0x1,%esi
f0100d2a:	89 d8                	mov    %ebx,%eax
f0100d2c:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100d32:	c1 f8 03             	sar    $0x3,%eax
f0100d35:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d38:	89 c2                	mov    %eax,%edx
f0100d3a:	c1 ea 16             	shr    $0x16,%edx
f0100d3d:	39 f2                	cmp    %esi,%edx
f0100d3f:	73 4a                	jae    f0100d8b <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d41:	89 c2                	mov    %eax,%edx
f0100d43:	c1 ea 0c             	shr    $0xc,%edx
f0100d46:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100d4c:	72 20                	jb     f0100d6e <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d4e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d52:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0100d59:	f0 
f0100d5a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d61:	00 
f0100d62:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f0100d69:	e8 d2 f2 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100d6e:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100d75:	00 
f0100d76:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d7d:	00 
	return (void *)(pa + KERNBASE);
f0100d7e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d83:	89 04 24             	mov    %eax,(%esp)
f0100d86:	e8 0a 50 00 00       	call   f0105d95 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d8b:	8b 1b                	mov    (%ebx),%ebx
f0100d8d:	85 db                	test   %ebx,%ebx
f0100d8f:	75 99                	jne    f0100d2a <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100d91:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d96:	e8 64 fe ff ff       	call   f0100bff <boot_alloc>
f0100d9b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d9e:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100da4:	85 d2                	test   %edx,%edx
f0100da6:	0f 84 2e 02 00 00    	je     f0100fda <check_page_free_list+0x336>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100dac:	8b 3d 90 ae 22 f0    	mov    0xf022ae90,%edi
f0100db2:	39 fa                	cmp    %edi,%edx
f0100db4:	72 51                	jb     f0100e07 <check_page_free_list+0x163>
		assert(pp < pages + npages);
f0100db6:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0100dbb:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100dbe:	8d 04 c7             	lea    (%edi,%eax,8),%eax
f0100dc1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100dc4:	39 c2                	cmp    %eax,%edx
f0100dc6:	73 68                	jae    f0100e30 <check_page_free_list+0x18c>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dc8:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0100dcb:	89 d0                	mov    %edx,%eax
f0100dcd:	29 f8                	sub    %edi,%eax
f0100dcf:	a8 07                	test   $0x7,%al
f0100dd1:	0f 85 86 00 00 00    	jne    f0100e5d <check_page_free_list+0x1b9>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dd7:	c1 f8 03             	sar    $0x3,%eax
f0100dda:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ddd:	85 c0                	test   %eax,%eax
f0100ddf:	0f 84 a6 00 00 00    	je     f0100e8b <check_page_free_list+0x1e7>
		assert(page2pa(pp) != IOPHYSMEM);
f0100de5:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100dea:	0f 84 c6 00 00 00    	je     f0100eb6 <check_page_free_list+0x212>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100df0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100df5:	be 00 00 00 00       	mov    $0x0,%esi
f0100dfa:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100dfd:	e9 d8 00 00 00       	jmp    f0100eda <check_page_free_list+0x236>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100e02:	3b 55 c0             	cmp    -0x40(%ebp),%edx
f0100e05:	73 24                	jae    f0100e2b <check_page_free_list+0x187>
f0100e07:	c7 44 24 0c 68 78 10 	movl   $0xf0107868,0xc(%esp)
f0100e0e:	f0 
f0100e0f:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100e16:	f0 
f0100e17:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f0100e1e:	00 
f0100e1f:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100e26:	e8 15 f2 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100e2b:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100e2e:	72 24                	jb     f0100e54 <check_page_free_list+0x1b0>
f0100e30:	c7 44 24 0c 89 78 10 	movl   $0xf0107889,0xc(%esp)
f0100e37:	f0 
f0100e38:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100e3f:	f0 
f0100e40:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f0100e47:	00 
f0100e48:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100e4f:	e8 ec f1 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e54:	89 d0                	mov    %edx,%eax
f0100e56:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100e59:	a8 07                	test   $0x7,%al
f0100e5b:	74 24                	je     f0100e81 <check_page_free_list+0x1dd>
f0100e5d:	c7 44 24 0c 60 71 10 	movl   $0xf0107160,0xc(%esp)
f0100e64:	f0 
f0100e65:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100e6c:	f0 
f0100e6d:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f0100e74:	00 
f0100e75:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100e7c:	e8 bf f1 ff ff       	call   f0100040 <_panic>
f0100e81:	c1 f8 03             	sar    $0x3,%eax
f0100e84:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100e87:	85 c0                	test   %eax,%eax
f0100e89:	75 24                	jne    f0100eaf <check_page_free_list+0x20b>
f0100e8b:	c7 44 24 0c 9d 78 10 	movl   $0xf010789d,0xc(%esp)
f0100e92:	f0 
f0100e93:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100e9a:	f0 
f0100e9b:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f0100ea2:	00 
f0100ea3:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100eaa:	e8 91 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100eaf:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100eb4:	75 24                	jne    f0100eda <check_page_free_list+0x236>
f0100eb6:	c7 44 24 0c ae 78 10 	movl   $0xf01078ae,0xc(%esp)
f0100ebd:	f0 
f0100ebe:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100ec5:	f0 
f0100ec6:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f0100ecd:	00 
f0100ece:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100ed5:	e8 66 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100eda:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100edf:	75 24                	jne    f0100f05 <check_page_free_list+0x261>
f0100ee1:	c7 44 24 0c 94 71 10 	movl   $0xf0107194,0xc(%esp)
f0100ee8:	f0 
f0100ee9:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100ef0:	f0 
f0100ef1:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0100ef8:	00 
f0100ef9:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100f00:	e8 3b f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f05:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100f0a:	75 24                	jne    f0100f30 <check_page_free_list+0x28c>
f0100f0c:	c7 44 24 0c c7 78 10 	movl   $0xf01078c7,0xc(%esp)
f0100f13:	f0 
f0100f14:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100f1b:	f0 
f0100f1c:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0100f23:	00 
f0100f24:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100f2b:	e8 10 f1 ff ff       	call   f0100040 <_panic>
f0100f30:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f32:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f37:	0f 86 09 01 00 00    	jbe    f0101046 <check_page_free_list+0x3a2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f3d:	89 c7                	mov    %eax,%edi
f0100f3f:	c1 ef 0c             	shr    $0xc,%edi
f0100f42:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0100f45:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0100f48:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100f4b:	72 20                	jb     f0100f6d <check_page_free_list+0x2c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f4d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f51:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0100f58:	f0 
f0100f59:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f60:	00 
f0100f61:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f0100f68:	e8 d3 f0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100f6d:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100f73:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100f76:	0f 86 da 00 00 00    	jbe    f0101056 <check_page_free_list+0x3b2>
f0100f7c:	c7 44 24 0c b8 71 10 	movl   $0xf01071b8,0xc(%esp)
f0100f83:	f0 
f0100f84:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100f8b:	f0 
f0100f8c:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0100f93:	00 
f0100f94:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100f9b:	e8 a0 f0 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100fa0:	c7 44 24 0c e1 78 10 	movl   $0xf01078e1,0xc(%esp)
f0100fa7:	f0 
f0100fa8:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100faf:	f0 
f0100fb0:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f0100fb7:	00 
f0100fb8:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100fbf:	e8 7c f0 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100fc4:	83 c6 01             	add    $0x1,%esi
f0100fc7:	eb 03                	jmp    f0100fcc <check_page_free_list+0x328>
		else
			++nfree_extmem;
f0100fc9:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fcc:	8b 12                	mov    (%edx),%edx
f0100fce:	85 d2                	test   %edx,%edx
f0100fd0:	0f 85 2c fe ff ff    	jne    f0100e02 <check_page_free_list+0x15e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100fd6:	85 f6                	test   %esi,%esi
f0100fd8:	7f 24                	jg     f0100ffe <check_page_free_list+0x35a>
f0100fda:	c7 44 24 0c fe 78 10 	movl   $0xf01078fe,0xc(%esp)
f0100fe1:	f0 
f0100fe2:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0100fe9:	f0 
f0100fea:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0100ff1:	00 
f0100ff2:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0100ff9:	e8 42 f0 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100ffe:	85 db                	test   %ebx,%ebx
f0101000:	7f 74                	jg     f0101076 <check_page_free_list+0x3d2>
f0101002:	c7 44 24 0c 10 79 10 	movl   $0xf0107910,0xc(%esp)
f0101009:	f0 
f010100a:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101011:	f0 
f0101012:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f0101019:	00 
f010101a:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101021:	e8 1a f0 ff ff       	call   f0100040 <_panic>
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101026:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010102b:	85 c0                	test   %eax,%eax
f010102d:	0f 85 a3 fc ff ff    	jne    f0100cd6 <check_page_free_list+0x32>
f0101033:	e9 82 fc ff ff       	jmp    f0100cba <check_page_free_list+0x16>
f0101038:	83 3d 40 a2 22 f0 00 	cmpl   $0x0,0xf022a240
f010103f:	75 25                	jne    f0101066 <check_page_free_list+0x3c2>
f0101041:	e9 74 fc ff ff       	jmp    f0100cba <check_page_free_list+0x16>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0101046:	3d 00 70 00 00       	cmp    $0x7000,%eax
f010104b:	0f 85 73 ff ff ff    	jne    f0100fc4 <check_page_free_list+0x320>
f0101051:	e9 4a ff ff ff       	jmp    f0100fa0 <check_page_free_list+0x2fc>
f0101056:	3d 00 70 00 00       	cmp    $0x7000,%eax
f010105b:	0f 85 68 ff ff ff    	jne    f0100fc9 <check_page_free_list+0x325>
f0101061:	e9 3a ff ff ff       	jmp    f0100fa0 <check_page_free_list+0x2fc>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101066:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010106c:	be 00 04 00 00       	mov    $0x400,%esi
f0101071:	e9 b4 fc ff ff       	jmp    f0100d2a <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0101076:	83 c4 4c             	add    $0x4c,%esp
f0101079:	5b                   	pop    %ebx
f010107a:	5e                   	pop    %esi
f010107b:	5f                   	pop    %edi
f010107c:	5d                   	pop    %ebp
f010107d:	c3                   	ret    

f010107e <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010107e:	55                   	push   %ebp
f010107f:	89 e5                	mov    %esp,%ebp
f0101081:	56                   	push   %esi
f0101082:	53                   	push   %ebx
f0101083:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
f0101086:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f010108b:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0101091:	8b 35 38 a2 22 f0    	mov    0xf022a238,%esi
f0101097:	83 fe 01             	cmp    $0x1,%esi
f010109a:	76 37                	jbe    f01010d3 <page_init+0x55>
f010109c:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f01010a2:	b8 01 00 00 00       	mov    $0x1,%eax
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
f01010a7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
		pages[i].pp_ref = 0;
f01010ae:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
f01010b4:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f01010bb:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f01010be:	8b 1d 90 ae 22 f0    	mov    0xf022ae90,%ebx
f01010c4:	01 d3                	add    %edx,%ebx
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f01010c6:	83 c0 01             	add    $0x1,%eax
f01010c9:	39 f0                	cmp    %esi,%eax
f01010cb:	72 da                	jb     f01010a7 <page_init+0x29>
f01010cd:	89 1d 40 a2 22 f0    	mov    %ebx,0xf022a240
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	size_t page_num = PADDR(boot_alloc(0)) / PGSIZE;
f01010d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01010d8:	e8 22 fb ff ff       	call   f0100bff <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010dd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010e2:	77 20                	ja     f0101104 <page_init+0x86>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010e4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010e8:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f01010ef:	f0 
f01010f0:	c7 44 24 04 5a 01 00 	movl   $0x15a,0x4(%esp)
f01010f7:	00 
f01010f8:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01010ff:	e8 3c ef ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101104:	05 00 00 00 10       	add    $0x10000000,%eax
f0101109:	c1 e8 0c             	shr    $0xc,%eax
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f010110c:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0101112:	73 39                	jae    f010114d <page_init+0xcf>
f0101114:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f010111a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0101121:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
f0101127:	01 d1                	add    %edx,%ecx
f0101129:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f010112f:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0101131:	8b 1d 90 ae 22 f0    	mov    0xf022ae90,%ebx
f0101137:	01 d3                	add    %edx,%ebx
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0101139:	83 c0 01             	add    $0x1,%eax
f010113c:	83 c2 08             	add    $0x8,%edx
f010113f:	39 05 88 ae 22 f0    	cmp    %eax,0xf022ae88
f0101145:	77 da                	ja     f0101121 <page_init+0xa3>
f0101147:	89 1d 40 a2 22 f0    	mov    %ebx,0xf022a240
	}

	page_num = MPENTRY_PADDR / PGSIZE;
	//cprintf("MPENTRY_PADDR: %x\n MPENTRY.link: %x\n ref:%x",
	//	&pages[page_num],pages[page_num].pp_link,pages[page_num+1].pp_link);
	pages[page_num+1].pp_link = pages[page_num].pp_link;
f010114d:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0101152:	8b 50 38             	mov    0x38(%eax),%edx
f0101155:	89 50 40             	mov    %edx,0x40(%eax)
//	panic("here");
	
}
f0101158:	83 c4 10             	add    $0x10,%esp
f010115b:	5b                   	pop    %ebx
f010115c:	5e                   	pop    %esi
f010115d:	5d                   	pop    %ebp
f010115e:	c3                   	ret    

f010115f <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f010115f:	55                   	push   %ebp
f0101160:	89 e5                	mov    %esp,%ebp
f0101162:	53                   	push   %ebx
f0101163:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(!page_free_list)
f0101166:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f010116c:	85 db                	test   %ebx,%ebx
f010116e:	74 6b                	je     f01011db <page_alloc+0x7c>
		return NULL;
	struct Page *alloc_page = page_free_list;
	page_free_list = page_free_list->pp_link;
f0101170:	8b 03                	mov    (%ebx),%eax
f0101172:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	alloc_page -> pp_link = NULL;
f0101177:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f010117d:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101181:	74 58                	je     f01011db <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101183:	89 d8                	mov    %ebx,%eax
f0101185:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010118b:	c1 f8 03             	sar    $0x3,%eax
f010118e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101191:	89 c2                	mov    %eax,%edx
f0101193:	c1 ea 0c             	shr    $0xc,%edx
f0101196:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f010119c:	72 20                	jb     f01011be <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010119e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011a2:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01011a9:	f0 
f01011aa:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01011b1:	00 
f01011b2:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f01011b9:	e8 82 ee ff ff       	call   f0100040 <_panic>
		memset(page2kva(alloc_page), 0, PGSIZE);
f01011be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01011c5:	00 
f01011c6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01011cd:	00 
	return (void *)(pa + KERNBASE);
f01011ce:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01011d3:	89 04 24             	mov    %eax,(%esp)
f01011d6:	e8 ba 4b 00 00       	call   f0105d95 <memset>
	
	return alloc_page;
}
f01011db:	89 d8                	mov    %ebx,%eax
f01011dd:	83 c4 14             	add    $0x14,%esp
f01011e0:	5b                   	pop    %ebx
f01011e1:	5d                   	pop    %ebp
f01011e2:	c3                   	ret    

f01011e3 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f01011e3:	55                   	push   %ebp
f01011e4:	89 e5                	mov    %esp,%ebp
f01011e6:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if(pp -> pp_ref)	// If the ref is not 0, return
f01011e9:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01011ee:	75 0d                	jne    f01011fd <page_free+0x1a>
		return;
	pp->pp_link = page_free_list;
f01011f0:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f01011f6:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01011f8:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
}
f01011fd:	5d                   	pop    %ebp
f01011fe:	c3                   	ret    

f01011ff <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f01011ff:	55                   	push   %ebp
f0101200:	89 e5                	mov    %esp,%ebp
f0101202:	83 ec 04             	sub    $0x4,%esp
f0101205:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101208:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f010120c:	83 ea 01             	sub    $0x1,%edx
f010120f:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101213:	66 85 d2             	test   %dx,%dx
f0101216:	75 08                	jne    f0101220 <page_decref+0x21>
		page_free(pp);
f0101218:	89 04 24             	mov    %eax,(%esp)
f010121b:	e8 c3 ff ff ff       	call   f01011e3 <page_free>
}
f0101220:	c9                   	leave  
f0101221:	c3                   	ret    

f0101222 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{/* see the check_va2pa() */
f0101222:	55                   	push   %ebp
f0101223:	89 e5                	mov    %esp,%ebp
f0101225:	56                   	push   %esi
f0101226:	53                   	push   %ebx
f0101227:	83 ec 10             	sub    $0x10,%esp
f010122a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/* va is a linear address */
	pde_t *ptdir = pgdir + PDX(va);
f010122d:	89 de                	mov    %ebx,%esi
f010122f:	c1 ee 16             	shr    $0x16,%esi
f0101232:	c1 e6 02             	shl    $0x2,%esi
f0101235:	03 75 08             	add    0x8(%ebp),%esi
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
f0101238:	8b 06                	mov    (%esi),%eax
f010123a:	a8 01                	test   $0x1,%al
f010123c:	74 44                	je     f0101282 <pgdir_walk+0x60>
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f010123e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101243:	89 c2                	mov    %eax,%edx
f0101245:	c1 ea 0c             	shr    $0xc,%edx
f0101248:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f010124e:	72 20                	jb     f0101270 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101250:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101254:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f010125b:	f0 
f010125c:	c7 44 24 04 bc 01 00 	movl   $0x1bc,0x4(%esp)
f0101263:	00 
f0101264:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010126b:	e8 d0 ed ff ff       	call   f0100040 <_panic>
f0101270:	c1 eb 0a             	shr    $0xa,%ebx
f0101273:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101279:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0101280:	eb 7c                	jmp    f01012fe <pgdir_walk+0xdc>
	if(!create)
f0101282:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101286:	74 6a                	je     f01012f2 <pgdir_walk+0xd0>
		return NULL;
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
f0101288:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010128f:	e8 cb fe ff ff       	call   f010115f <page_alloc>
	if(!page_create)
f0101294:	85 c0                	test   %eax,%eax
f0101296:	74 61                	je     f01012f9 <pgdir_walk+0xd7>
		return NULL; /* allocation fails */
	page_create -> pp_ref++; /* reference count increase */
f0101298:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010129d:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01012a3:	c1 f8 03             	sar    $0x3,%eax
f01012a6:	c1 e0 0c             	shl    $0xc,%eax
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
f01012a9:	83 c8 07             	or     $0x7,%eax
f01012ac:	89 06                	mov    %eax,(%esi)
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f01012ae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012b3:	89 c2                	mov    %eax,%edx
f01012b5:	c1 ea 0c             	shr    $0xc,%edx
f01012b8:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01012be:	72 20                	jb     f01012e0 <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012c0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012c4:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01012cb:	f0 
f01012cc:	c7 44 24 04 c4 01 00 	movl   $0x1c4,0x4(%esp)
f01012d3:	00 
f01012d4:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01012db:	e8 60 ed ff ff       	call   f0100040 <_panic>
f01012e0:	c1 eb 0a             	shr    $0xa,%ebx
f01012e3:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f01012e9:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f01012f0:	eb 0c                	jmp    f01012fe <pgdir_walk+0xdc>
	pde_t *ptdir = pgdir + PDX(va);
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
	if(!create)
		return NULL;
f01012f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01012f7:	eb 05                	jmp    f01012fe <pgdir_walk+0xdc>
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
	if(!page_create)
		return NULL; /* allocation fails */
f01012f9:	b8 00 00 00 00       	mov    $0x0,%eax
	page_create -> pp_ref++; /* reference count increase */
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
}
f01012fe:	83 c4 10             	add    $0x10,%esp
f0101301:	5b                   	pop    %ebx
f0101302:	5e                   	pop    %esi
f0101303:	5d                   	pop    %ebp
f0101304:	c3                   	ret    

f0101305 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101305:	55                   	push   %ebp
f0101306:	89 e5                	mov    %esp,%ebp
f0101308:	57                   	push   %edi
f0101309:	56                   	push   %esi
f010130a:	53                   	push   %ebx
f010130b:	83 ec 2c             	sub    $0x2c,%esp
f010130e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f0101311:	85 c9                	test   %ecx,%ecx
f0101313:	74 4c                	je     f0101361 <boot_map_region+0x5c>
f0101315:	89 c6                	mov    %eax,%esi
f0101317:	89 d3                	mov    %edx,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101319:	8b 45 08             	mov    0x8(%ebp),%eax
f010131c:	29 d0                	sub    %edx,%eax
f010131e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
		pte_t *pte = pgdir_walk(pgdir, (const void *)va, 1);
		if(!pte)
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm|PTE_P;
f0101321:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101324:	83 c8 01             	or     $0x1,%eax
f0101327:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010132a:	89 55 d8             	mov    %edx,-0x28(%ebp)
f010132d:	89 f7                	mov    %esi,%edi
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f010132f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101332:	01 de                	add    %ebx,%esi
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
		pte_t *pte = pgdir_walk(pgdir, (const void *)va, 1);
f0101334:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010133b:	00 
f010133c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101340:	89 3c 24             	mov    %edi,(%esp)
f0101343:	e8 da fe ff ff       	call   f0101222 <pgdir_walk>
		if(!pte)
f0101348:	85 c0                	test   %eax,%eax
f010134a:	74 15                	je     f0101361 <boot_map_region+0x5c>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm|PTE_P;
f010134c:	0b 75 e0             	or     -0x20(%ebp),%esi
f010134f:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f0101351:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101357:	89 d8                	mov    %ebx,%eax
f0101359:	2b 45 d8             	sub    -0x28(%ebp),%eax
f010135c:	3b 45 dc             	cmp    -0x24(%ebp),%eax
f010135f:	72 ce                	jb     f010132f <boot_map_region+0x2a>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm|PTE_P;
	}
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~\n");
}
f0101361:	83 c4 2c             	add    $0x2c,%esp
f0101364:	5b                   	pop    %ebx
f0101365:	5e                   	pop    %esi
f0101366:	5f                   	pop    %edi
f0101367:	5d                   	pop    %ebp
f0101368:	c3                   	ret    

f0101369 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101369:	55                   	push   %ebp
f010136a:	89 e5                	mov    %esp,%ebp
f010136c:	53                   	push   %ebx
f010136d:	83 ec 14             	sub    $0x14,%esp
f0101370:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101373:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010137a:	00 
f010137b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010137e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101382:	8b 45 08             	mov    0x8(%ebp),%eax
f0101385:	89 04 24             	mov    %eax,(%esp)
f0101388:	e8 95 fe ff ff       	call   f0101222 <pgdir_walk>
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
f010138d:	85 c0                	test   %eax,%eax
f010138f:	74 3f                	je     f01013d0 <page_lookup+0x67>
f0101391:	f6 00 01             	testb  $0x1,(%eax)
f0101394:	74 41                	je     f01013d7 <page_lookup+0x6e>
		return NULL;
	if(pte_store)
f0101396:	85 db                	test   %ebx,%ebx
f0101398:	74 02                	je     f010139c <page_lookup+0x33>
		*pte_store = pte;
f010139a:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f010139c:	8b 00                	mov    (%eax),%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010139e:	c1 e8 0c             	shr    $0xc,%eax
f01013a1:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01013a7:	72 1c                	jb     f01013c5 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f01013a9:	c7 44 24 08 00 72 10 	movl   $0xf0107200,0x8(%esp)
f01013b0:	f0 
f01013b1:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01013b8:	00 
f01013b9:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f01013c0:	e8 7b ec ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01013c5:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f01013cb:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01013ce:	eb 0c                	jmp    f01013dc <page_lookup+0x73>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
		return NULL;
f01013d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01013d5:	eb 05                	jmp    f01013dc <page_lookup+0x73>
f01013d7:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f01013dc:	83 c4 14             	add    $0x14,%esp
f01013df:	5b                   	pop    %ebx
f01013e0:	5d                   	pop    %ebp
f01013e1:	c3                   	ret    

f01013e2 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01013e2:	55                   	push   %ebp
f01013e3:	89 e5                	mov    %esp,%ebp
f01013e5:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01013e8:	e8 4f 50 00 00       	call   f010643c <cpunum>
f01013ed:	6b c0 74             	imul   $0x74,%eax,%eax
f01013f0:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01013f7:	74 16                	je     f010140f <tlb_invalidate+0x2d>
f01013f9:	e8 3e 50 00 00       	call   f010643c <cpunum>
f01013fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0101401:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0101407:	8b 55 08             	mov    0x8(%ebp),%edx
f010140a:	39 50 60             	cmp    %edx,0x60(%eax)
f010140d:	75 06                	jne    f0101415 <tlb_invalidate+0x33>
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010140f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101412:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101415:	c9                   	leave  
f0101416:	c3                   	ret    

f0101417 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101417:	55                   	push   %ebp
f0101418:	89 e5                	mov    %esp,%ebp
f010141a:	83 ec 28             	sub    $0x28,%esp
f010141d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101420:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101423:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101426:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct Page *pp = page_lookup(pgdir, va, &pte);
f0101429:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010142c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101430:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101434:	89 1c 24             	mov    %ebx,(%esp)
f0101437:	e8 2d ff ff ff       	call   f0101369 <page_lookup>
	if(!pp)
f010143c:	85 c0                	test   %eax,%eax
f010143e:	74 1d                	je     f010145d <page_remove+0x46>
		return;
	page_decref(pp);
f0101440:	89 04 24             	mov    %eax,(%esp)
f0101443:	e8 b7 fd ff ff       	call   f01011ff <page_decref>
	*pte = 0;
f0101448:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010144b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f0101451:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101455:	89 1c 24             	mov    %ebx,(%esp)
f0101458:	e8 85 ff ff ff       	call   f01013e2 <tlb_invalidate>
	
}
f010145d:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101460:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101463:	89 ec                	mov    %ebp,%esp
f0101465:	5d                   	pop    %ebp
f0101466:	c3                   	ret    

f0101467 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101467:	55                   	push   %ebp
f0101468:	89 e5                	mov    %esp,%ebp
f010146a:	83 ec 28             	sub    $0x28,%esp
f010146d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101470:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101473:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101476:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101479:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f010147c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101483:	00 
f0101484:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101488:	8b 45 08             	mov    0x8(%ebp),%eax
f010148b:	89 04 24             	mov    %eax,(%esp)
f010148e:	e8 8f fd ff ff       	call   f0101222 <pgdir_walk>
f0101493:	89 c6                	mov    %eax,%esi
	if(!pte)
f0101495:	85 c0                	test   %eax,%eax
f0101497:	74 66                	je     f01014ff <page_insert+0x98>
		return -E_NO_MEM;
	if(*pte & PTE_P) { /* already a page */
f0101499:	8b 00                	mov    (%eax),%eax
f010149b:	a8 01                	test   $0x1,%al
f010149d:	74 3c                	je     f01014db <page_insert+0x74>
		if(PTE_ADDR(*pte) == page2pa(pp)){	/* the same one */
f010149f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01014a4:	89 da                	mov    %ebx,%edx
f01014a6:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f01014ac:	c1 fa 03             	sar    $0x3,%edx
f01014af:	c1 e2 0c             	shl    $0xc,%edx
f01014b2:	39 d0                	cmp    %edx,%eax
f01014b4:	75 16                	jne    f01014cc <page_insert+0x65>
			tlb_invalidate(pgdir, va);
f01014b6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01014bd:	89 04 24             	mov    %eax,(%esp)
f01014c0:	e8 1d ff ff ff       	call   f01013e2 <tlb_invalidate>
			pp -> pp_ref--;
f01014c5:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f01014ca:	eb 0f                	jmp    f01014db <page_insert+0x74>
		}else
			page_remove(pgdir, va);
f01014cc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d3:	89 04 24             	mov    %eax,(%esp)
f01014d6:	e8 3c ff ff ff       	call   f0101417 <page_remove>
	}
	*pte = page2pa(pp)|perm|PTE_P;
f01014db:	8b 55 14             	mov    0x14(%ebp),%edx
f01014de:	83 ca 01             	or     $0x1,%edx
f01014e1:	89 d8                	mov    %ebx,%eax
f01014e3:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01014e9:	c1 f8 03             	sar    $0x3,%eax
f01014ec:	c1 e0 0c             	shl    $0xc,%eax
f01014ef:	09 d0                	or     %edx,%eax
f01014f1:	89 06                	mov    %eax,(%esi)
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
f01014f3:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f01014f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01014fd:	eb 05                	jmp    f0101504 <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
	if(!pte)
		return -E_NO_MEM;
f01014ff:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*pte = page2pa(pp)|perm|PTE_P;
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
	return 0;
}
f0101504:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101507:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010150a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010150d:	89 ec                	mov    %ebp,%esp
f010150f:	5d                   	pop    %ebp
f0101510:	c3                   	ret    

f0101511 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101511:	55                   	push   %ebp
f0101512:	89 e5                	mov    %esp,%ebp
f0101514:	57                   	push   %edi
f0101515:	56                   	push   %esi
f0101516:	53                   	push   %ebx
f0101517:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010151a:	b8 15 00 00 00       	mov    $0x15,%eax
f010151f:	e8 4e f7 ff ff       	call   f0100c72 <nvram_read>
f0101524:	c1 e0 0a             	shl    $0xa,%eax
f0101527:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010152d:	85 c0                	test   %eax,%eax
f010152f:	0f 48 c2             	cmovs  %edx,%eax
f0101532:	c1 f8 0c             	sar    $0xc,%eax
f0101535:	a3 38 a2 22 f0       	mov    %eax,0xf022a238
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010153a:	b8 17 00 00 00       	mov    $0x17,%eax
f010153f:	e8 2e f7 ff ff       	call   f0100c72 <nvram_read>
f0101544:	c1 e0 0a             	shl    $0xa,%eax
f0101547:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010154d:	85 c0                	test   %eax,%eax
f010154f:	0f 48 c2             	cmovs  %edx,%eax
f0101552:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101555:	85 c0                	test   %eax,%eax
f0101557:	74 0e                	je     f0101567 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101559:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010155f:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88
f0101565:	eb 0c                	jmp    f0101573 <mem_init+0x62>
	else
		npages = npages_basemem;
f0101567:	8b 15 38 a2 22 f0    	mov    0xf022a238,%edx
f010156d:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101573:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101576:	c1 e8 0a             	shr    $0xa,%eax
f0101579:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010157d:	a1 38 a2 22 f0       	mov    0xf022a238,%eax
f0101582:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101585:	c1 e8 0a             	shr    $0xa,%eax
f0101588:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010158c:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0101591:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101594:	c1 e8 0a             	shr    $0xa,%eax
f0101597:	89 44 24 04          	mov    %eax,0x4(%esp)
f010159b:	c7 04 24 20 72 10 f0 	movl   $0xf0107220,(%esp)
f01015a2:	e8 4f 27 00 00       	call   f0103cf6 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01015a7:	b8 00 10 00 00       	mov    $0x1000,%eax
f01015ac:	e8 4e f6 ff ff       	call   f0100bff <boot_alloc>
f01015b1:	a3 8c ae 22 f0       	mov    %eax,0xf022ae8c
	memset(kern_pgdir, 0, PGSIZE);
f01015b6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01015bd:	00 
f01015be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01015c5:	00 
f01015c6:	89 04 24             	mov    %eax,(%esp)
f01015c9:	e8 c7 47 00 00       	call   f0105d95 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01015ce:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01015d3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01015d8:	77 20                	ja     f01015fa <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01015da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01015de:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f01015e5:	f0 
f01015e6:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
f01015ed:	00 
f01015ee:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01015f5:	e8 46 ea ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01015fa:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101600:	83 ca 05             	or     $0x5,%edx
f0101603:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page *)boot_alloc(npages * sizeof(struct Page));
f0101609:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f010160e:	c1 e0 03             	shl    $0x3,%eax
f0101611:	e8 e9 f5 ff ff       	call   f0100bff <boot_alloc>
f0101616:	a3 90 ae 22 f0       	mov    %eax,0xf022ae90
		
//panic("PDX(0)");
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f010161b:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101620:	e8 da f5 ff ff       	call   f0100bff <boot_alloc>
f0101625:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010162a:	e8 4f fa ff ff       	call   f010107e <page_init>

	check_page_free_list(1);
f010162f:	b8 01 00 00 00       	mov    $0x1,%eax
f0101634:	e8 6b f6 ff ff       	call   f0100ca4 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101639:	83 3d 90 ae 22 f0 00 	cmpl   $0x0,0xf022ae90
f0101640:	75 1c                	jne    f010165e <mem_init+0x14d>
		panic("'pages' is a null pointer!");
f0101642:	c7 44 24 08 21 79 10 	movl   $0xf0107921,0x8(%esp)
f0101649:	f0 
f010164a:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f0101651:	00 
f0101652:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101659:	e8 e2 e9 ff ff       	call   f0100040 <_panic>
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010165e:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101663:	85 c0                	test   %eax,%eax
f0101665:	74 10                	je     f0101677 <mem_init+0x166>
f0101667:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f010166c:	83 c3 01             	add    $0x1,%ebx
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010166f:	8b 00                	mov    (%eax),%eax
f0101671:	85 c0                	test   %eax,%eax
f0101673:	75 f7                	jne    f010166c <mem_init+0x15b>
f0101675:	eb 05                	jmp    f010167c <mem_init+0x16b>
f0101677:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010167c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101683:	e8 d7 fa ff ff       	call   f010115f <page_alloc>
f0101688:	89 c7                	mov    %eax,%edi
f010168a:	85 c0                	test   %eax,%eax
f010168c:	75 24                	jne    f01016b2 <mem_init+0x1a1>
f010168e:	c7 44 24 0c 3c 79 10 	movl   $0xf010793c,0xc(%esp)
f0101695:	f0 
f0101696:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010169d:	f0 
f010169e:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f01016a5:	00 
f01016a6:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01016ad:	e8 8e e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01016b2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016b9:	e8 a1 fa ff ff       	call   f010115f <page_alloc>
f01016be:	89 c6                	mov    %eax,%esi
f01016c0:	85 c0                	test   %eax,%eax
f01016c2:	75 24                	jne    f01016e8 <mem_init+0x1d7>
f01016c4:	c7 44 24 0c 52 79 10 	movl   $0xf0107952,0xc(%esp)
f01016cb:	f0 
f01016cc:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01016d3:	f0 
f01016d4:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f01016db:	00 
f01016dc:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01016e3:	e8 58 e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01016e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016ef:	e8 6b fa ff ff       	call   f010115f <page_alloc>
f01016f4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016f7:	85 c0                	test   %eax,%eax
f01016f9:	75 24                	jne    f010171f <mem_init+0x20e>
f01016fb:	c7 44 24 0c 68 79 10 	movl   $0xf0107968,0xc(%esp)
f0101702:	f0 
f0101703:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010170a:	f0 
f010170b:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f0101712:	00 
f0101713:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010171a:	e8 21 e9 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010171f:	39 f7                	cmp    %esi,%edi
f0101721:	75 24                	jne    f0101747 <mem_init+0x236>
f0101723:	c7 44 24 0c 7e 79 10 	movl   $0xf010797e,0xc(%esp)
f010172a:	f0 
f010172b:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101732:	f0 
f0101733:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f010173a:	00 
f010173b:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101742:	e8 f9 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101747:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010174a:	74 05                	je     f0101751 <mem_init+0x240>
f010174c:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010174f:	75 24                	jne    f0101775 <mem_init+0x264>
f0101751:	c7 44 24 0c 5c 72 10 	movl   $0xf010725c,0xc(%esp)
f0101758:	f0 
f0101759:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101760:	f0 
f0101761:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
f0101768:	00 
f0101769:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101770:	e8 cb e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101775:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010177b:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0101780:	c1 e0 0c             	shl    $0xc,%eax
f0101783:	89 f9                	mov    %edi,%ecx
f0101785:	29 d1                	sub    %edx,%ecx
f0101787:	c1 f9 03             	sar    $0x3,%ecx
f010178a:	c1 e1 0c             	shl    $0xc,%ecx
f010178d:	39 c1                	cmp    %eax,%ecx
f010178f:	72 24                	jb     f01017b5 <mem_init+0x2a4>
f0101791:	c7 44 24 0c 90 79 10 	movl   $0xf0107990,0xc(%esp)
f0101798:	f0 
f0101799:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01017a0:	f0 
f01017a1:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f01017a8:	00 
f01017a9:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01017b0:	e8 8b e8 ff ff       	call   f0100040 <_panic>
f01017b5:	89 f1                	mov    %esi,%ecx
f01017b7:	29 d1                	sub    %edx,%ecx
f01017b9:	c1 f9 03             	sar    $0x3,%ecx
f01017bc:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01017bf:	39 c8                	cmp    %ecx,%eax
f01017c1:	77 24                	ja     f01017e7 <mem_init+0x2d6>
f01017c3:	c7 44 24 0c ad 79 10 	movl   $0xf01079ad,0xc(%esp)
f01017ca:	f0 
f01017cb:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01017d2:	f0 
f01017d3:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
f01017da:	00 
f01017db:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01017e2:	e8 59 e8 ff ff       	call   f0100040 <_panic>
f01017e7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01017ea:	29 d1                	sub    %edx,%ecx
f01017ec:	89 ca                	mov    %ecx,%edx
f01017ee:	c1 fa 03             	sar    $0x3,%edx
f01017f1:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01017f4:	39 d0                	cmp    %edx,%eax
f01017f6:	77 24                	ja     f010181c <mem_init+0x30b>
f01017f8:	c7 44 24 0c ca 79 10 	movl   $0xf01079ca,0xc(%esp)
f01017ff:	f0 
f0101800:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101807:	f0 
f0101808:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f010180f:	00 
f0101810:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101817:	e8 24 e8 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010181c:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101821:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101824:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f010182b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010182e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101835:	e8 25 f9 ff ff       	call   f010115f <page_alloc>
f010183a:	85 c0                	test   %eax,%eax
f010183c:	74 24                	je     f0101862 <mem_init+0x351>
f010183e:	c7 44 24 0c e7 79 10 	movl   $0xf01079e7,0xc(%esp)
f0101845:	f0 
f0101846:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010184d:	f0 
f010184e:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0101855:	00 
f0101856:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010185d:	e8 de e7 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101862:	89 3c 24             	mov    %edi,(%esp)
f0101865:	e8 79 f9 ff ff       	call   f01011e3 <page_free>
	page_free(pp1);
f010186a:	89 34 24             	mov    %esi,(%esp)
f010186d:	e8 71 f9 ff ff       	call   f01011e3 <page_free>
	page_free(pp2);
f0101872:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101875:	89 04 24             	mov    %eax,(%esp)
f0101878:	e8 66 f9 ff ff       	call   f01011e3 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010187d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101884:	e8 d6 f8 ff ff       	call   f010115f <page_alloc>
f0101889:	89 c6                	mov    %eax,%esi
f010188b:	85 c0                	test   %eax,%eax
f010188d:	75 24                	jne    f01018b3 <mem_init+0x3a2>
f010188f:	c7 44 24 0c 3c 79 10 	movl   $0xf010793c,0xc(%esp)
f0101896:	f0 
f0101897:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010189e:	f0 
f010189f:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f01018a6:	00 
f01018a7:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01018ae:	e8 8d e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01018b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018ba:	e8 a0 f8 ff ff       	call   f010115f <page_alloc>
f01018bf:	89 c7                	mov    %eax,%edi
f01018c1:	85 c0                	test   %eax,%eax
f01018c3:	75 24                	jne    f01018e9 <mem_init+0x3d8>
f01018c5:	c7 44 24 0c 52 79 10 	movl   $0xf0107952,0xc(%esp)
f01018cc:	f0 
f01018cd:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01018d4:	f0 
f01018d5:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f01018dc:	00 
f01018dd:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01018e4:	e8 57 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01018e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018f0:	e8 6a f8 ff ff       	call   f010115f <page_alloc>
f01018f5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018f8:	85 c0                	test   %eax,%eax
f01018fa:	75 24                	jne    f0101920 <mem_init+0x40f>
f01018fc:	c7 44 24 0c 68 79 10 	movl   $0xf0107968,0xc(%esp)
f0101903:	f0 
f0101904:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010190b:	f0 
f010190c:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f0101913:	00 
f0101914:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010191b:	e8 20 e7 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101920:	39 fe                	cmp    %edi,%esi
f0101922:	75 24                	jne    f0101948 <mem_init+0x437>
f0101924:	c7 44 24 0c 7e 79 10 	movl   $0xf010797e,0xc(%esp)
f010192b:	f0 
f010192c:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101933:	f0 
f0101934:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f010193b:	00 
f010193c:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101943:	e8 f8 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101948:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010194b:	74 05                	je     f0101952 <mem_init+0x441>
f010194d:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101950:	75 24                	jne    f0101976 <mem_init+0x465>
f0101952:	c7 44 24 0c 5c 72 10 	movl   $0xf010725c,0xc(%esp)
f0101959:	f0 
f010195a:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101961:	f0 
f0101962:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0101969:	00 
f010196a:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101971:	e8 ca e6 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101976:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010197d:	e8 dd f7 ff ff       	call   f010115f <page_alloc>
f0101982:	85 c0                	test   %eax,%eax
f0101984:	74 24                	je     f01019aa <mem_init+0x499>
f0101986:	c7 44 24 0c e7 79 10 	movl   $0xf01079e7,0xc(%esp)
f010198d:	f0 
f010198e:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101995:	f0 
f0101996:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f010199d:	00 
f010199e:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01019a5:	e8 96 e6 ff ff       	call   f0100040 <_panic>
f01019aa:	89 f0                	mov    %esi,%eax
f01019ac:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01019b2:	c1 f8 03             	sar    $0x3,%eax
f01019b5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019b8:	89 c2                	mov    %eax,%edx
f01019ba:	c1 ea 0c             	shr    $0xc,%edx
f01019bd:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01019c3:	72 20                	jb     f01019e5 <mem_init+0x4d4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01019c9:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01019d0:	f0 
f01019d1:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01019d8:	00 
f01019d9:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f01019e0:	e8 5b e6 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01019e5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01019ec:	00 
f01019ed:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01019f4:	00 
	return (void *)(pa + KERNBASE);
f01019f5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019fa:	89 04 24             	mov    %eax,(%esp)
f01019fd:	e8 93 43 00 00       	call   f0105d95 <memset>
	page_free(pp0);
f0101a02:	89 34 24             	mov    %esi,(%esp)
f0101a05:	e8 d9 f7 ff ff       	call   f01011e3 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a0a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101a11:	e8 49 f7 ff ff       	call   f010115f <page_alloc>
f0101a16:	85 c0                	test   %eax,%eax
f0101a18:	75 24                	jne    f0101a3e <mem_init+0x52d>
f0101a1a:	c7 44 24 0c f6 79 10 	movl   $0xf01079f6,0xc(%esp)
f0101a21:	f0 
f0101a22:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101a29:	f0 
f0101a2a:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0101a31:	00 
f0101a32:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101a39:	e8 02 e6 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101a3e:	39 c6                	cmp    %eax,%esi
f0101a40:	74 24                	je     f0101a66 <mem_init+0x555>
f0101a42:	c7 44 24 0c 14 7a 10 	movl   $0xf0107a14,0xc(%esp)
f0101a49:	f0 
f0101a4a:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101a51:	f0 
f0101a52:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f0101a59:	00 
f0101a5a:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101a61:	e8 da e5 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a66:	89 f2                	mov    %esi,%edx
f0101a68:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101a6e:	c1 fa 03             	sar    $0x3,%edx
f0101a71:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a74:	89 d0                	mov    %edx,%eax
f0101a76:	c1 e8 0c             	shr    $0xc,%eax
f0101a79:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0101a7f:	72 20                	jb     f0101aa1 <mem_init+0x590>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a81:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101a85:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0101a8c:	f0 
f0101a8d:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101a94:	00 
f0101a95:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f0101a9c:	e8 9f e5 ff ff       	call   f0100040 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101aa1:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101aa8:	75 11                	jne    f0101abb <mem_init+0x5aa>
f0101aaa:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101ab0:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101ab6:	80 38 00             	cmpb   $0x0,(%eax)
f0101ab9:	74 24                	je     f0101adf <mem_init+0x5ce>
f0101abb:	c7 44 24 0c 24 7a 10 	movl   $0xf0107a24,0xc(%esp)
f0101ac2:	f0 
f0101ac3:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101aca:	f0 
f0101acb:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101ad2:	00 
f0101ad3:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101ada:	e8 61 e5 ff ff       	call   f0100040 <_panic>
f0101adf:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101ae2:	39 d0                	cmp    %edx,%eax
f0101ae4:	75 d0                	jne    f0101ab6 <mem_init+0x5a5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101ae6:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101ae9:	89 15 40 a2 22 f0    	mov    %edx,0xf022a240

	// free the pages we took
	page_free(pp0);
f0101aef:	89 34 24             	mov    %esi,(%esp)
f0101af2:	e8 ec f6 ff ff       	call   f01011e3 <page_free>
	page_free(pp1);
f0101af7:	89 3c 24             	mov    %edi,(%esp)
f0101afa:	e8 e4 f6 ff ff       	call   f01011e3 <page_free>
	page_free(pp2);
f0101aff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b02:	89 04 24             	mov    %eax,(%esp)
f0101b05:	e8 d9 f6 ff ff       	call   f01011e3 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b0a:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101b0f:	85 c0                	test   %eax,%eax
f0101b11:	74 09                	je     f0101b1c <mem_init+0x60b>
		--nfree;
f0101b13:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b16:	8b 00                	mov    (%eax),%eax
f0101b18:	85 c0                	test   %eax,%eax
f0101b1a:	75 f7                	jne    f0101b13 <mem_init+0x602>
		--nfree;
	assert(nfree == 0);
f0101b1c:	85 db                	test   %ebx,%ebx
f0101b1e:	74 24                	je     f0101b44 <mem_init+0x633>
f0101b20:	c7 44 24 0c 2e 7a 10 	movl   $0xf0107a2e,0xc(%esp)
f0101b27:	f0 
f0101b28:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101b2f:	f0 
f0101b30:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101b37:	00 
f0101b38:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101b3f:	e8 fc e4 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101b44:	c7 04 24 7c 72 10 f0 	movl   $0xf010727c,(%esp)
f0101b4b:	e8 a6 21 00 00       	call   f0103cf6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b50:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b57:	e8 03 f6 ff ff       	call   f010115f <page_alloc>
f0101b5c:	89 c3                	mov    %eax,%ebx
f0101b5e:	85 c0                	test   %eax,%eax
f0101b60:	75 24                	jne    f0101b86 <mem_init+0x675>
f0101b62:	c7 44 24 0c 3c 79 10 	movl   $0xf010793c,0xc(%esp)
f0101b69:	f0 
f0101b6a:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101b71:	f0 
f0101b72:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0101b79:	00 
f0101b7a:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101b81:	e8 ba e4 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b86:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b8d:	e8 cd f5 ff ff       	call   f010115f <page_alloc>
f0101b92:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b95:	85 c0                	test   %eax,%eax
f0101b97:	75 24                	jne    f0101bbd <mem_init+0x6ac>
f0101b99:	c7 44 24 0c 52 79 10 	movl   $0xf0107952,0xc(%esp)
f0101ba0:	f0 
f0101ba1:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101ba8:	f0 
f0101ba9:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0101bb0:	00 
f0101bb1:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101bb8:	e8 83 e4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101bbd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bc4:	e8 96 f5 ff ff       	call   f010115f <page_alloc>
f0101bc9:	89 c6                	mov    %eax,%esi
f0101bcb:	85 c0                	test   %eax,%eax
f0101bcd:	75 24                	jne    f0101bf3 <mem_init+0x6e2>
f0101bcf:	c7 44 24 0c 68 79 10 	movl   $0xf0107968,0xc(%esp)
f0101bd6:	f0 
f0101bd7:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101bde:	f0 
f0101bdf:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f0101be6:	00 
f0101be7:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101bee:	e8 4d e4 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101bf3:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101bf6:	75 24                	jne    f0101c1c <mem_init+0x70b>
f0101bf8:	c7 44 24 0c 7e 79 10 	movl   $0xf010797e,0xc(%esp)
f0101bff:	f0 
f0101c00:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101c07:	f0 
f0101c08:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101c0f:	00 
f0101c10:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101c17:	e8 24 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c1c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101c1f:	74 04                	je     f0101c25 <mem_init+0x714>
f0101c21:	39 c3                	cmp    %eax,%ebx
f0101c23:	75 24                	jne    f0101c49 <mem_init+0x738>
f0101c25:	c7 44 24 0c 5c 72 10 	movl   $0xf010725c,0xc(%esp)
f0101c2c:	f0 
f0101c2d:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101c34:	f0 
f0101c35:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0101c3c:	00 
f0101c3d:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101c44:	e8 f7 e3 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c49:	8b 3d 40 a2 22 f0    	mov    0xf022a240,%edi
f0101c4f:	89 7d c8             	mov    %edi,-0x38(%ebp)
	page_free_list = 0;
f0101c52:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f0101c59:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c5c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c63:	e8 f7 f4 ff ff       	call   f010115f <page_alloc>
f0101c68:	85 c0                	test   %eax,%eax
f0101c6a:	74 24                	je     f0101c90 <mem_init+0x77f>
f0101c6c:	c7 44 24 0c e7 79 10 	movl   $0xf01079e7,0xc(%esp)
f0101c73:	f0 
f0101c74:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101c7b:	f0 
f0101c7c:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0101c83:	00 
f0101c84:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101c8b:	e8 b0 e3 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101c90:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101c93:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c97:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101c9e:	00 
f0101c9f:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101ca4:	89 04 24             	mov    %eax,(%esp)
f0101ca7:	e8 bd f6 ff ff       	call   f0101369 <page_lookup>
f0101cac:	85 c0                	test   %eax,%eax
f0101cae:	74 24                	je     f0101cd4 <mem_init+0x7c3>
f0101cb0:	c7 44 24 0c 9c 72 10 	movl   $0xf010729c,0xc(%esp)
f0101cb7:	f0 
f0101cb8:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101cbf:	f0 
f0101cc0:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0101cc7:	00 
f0101cc8:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101ccf:	e8 6c e3 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101cd4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cdb:	00 
f0101cdc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ce3:	00 
f0101ce4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ce7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ceb:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101cf0:	89 04 24             	mov    %eax,(%esp)
f0101cf3:	e8 6f f7 ff ff       	call   f0101467 <page_insert>
f0101cf8:	85 c0                	test   %eax,%eax
f0101cfa:	78 24                	js     f0101d20 <mem_init+0x80f>
f0101cfc:	c7 44 24 0c d4 72 10 	movl   $0xf01072d4,0xc(%esp)
f0101d03:	f0 
f0101d04:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101d0b:	f0 
f0101d0c:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0101d13:	00 
f0101d14:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101d1b:	e8 20 e3 ff ff       	call   f0100040 <_panic>
//panic("\n");
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101d20:	89 1c 24             	mov    %ebx,(%esp)
f0101d23:	e8 bb f4 ff ff       	call   f01011e3 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101d28:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d2f:	00 
f0101d30:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d37:	00 
f0101d38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101d3f:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101d44:	89 04 24             	mov    %eax,(%esp)
f0101d47:	e8 1b f7 ff ff       	call   f0101467 <page_insert>
f0101d4c:	85 c0                	test   %eax,%eax
f0101d4e:	74 24                	je     f0101d74 <mem_init+0x863>
f0101d50:	c7 44 24 0c 04 73 10 	movl   $0xf0107304,0xc(%esp)
f0101d57:	f0 
f0101d58:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101d5f:	f0 
f0101d60:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0101d67:	00 
f0101d68:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101d6f:	e8 cc e2 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d74:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101d7a:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f0101d80:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101d83:	8b 17                	mov    (%edi),%edx
f0101d85:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d8b:	89 d8                	mov    %ebx,%eax
f0101d8d:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101d90:	c1 f8 03             	sar    $0x3,%eax
f0101d93:	c1 e0 0c             	shl    $0xc,%eax
f0101d96:	39 c2                	cmp    %eax,%edx
f0101d98:	74 24                	je     f0101dbe <mem_init+0x8ad>
f0101d9a:	c7 44 24 0c 34 73 10 	movl   $0xf0107334,0xc(%esp)
f0101da1:	f0 
f0101da2:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101da9:	f0 
f0101daa:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0101db1:	00 
f0101db2:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101db9:	e8 82 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101dbe:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dc3:	89 f8                	mov    %edi,%eax
f0101dc5:	e8 c6 ed ff ff       	call   f0100b90 <check_va2pa>
f0101dca:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101dcd:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101dd0:	c1 fa 03             	sar    $0x3,%edx
f0101dd3:	c1 e2 0c             	shl    $0xc,%edx
f0101dd6:	39 d0                	cmp    %edx,%eax
f0101dd8:	74 24                	je     f0101dfe <mem_init+0x8ed>
f0101dda:	c7 44 24 0c 5c 73 10 	movl   $0xf010735c,0xc(%esp)
f0101de1:	f0 
f0101de2:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101de9:	f0 
f0101dea:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0101df1:	00 
f0101df2:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101df9:	e8 42 e2 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101dfe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e01:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e06:	74 24                	je     f0101e2c <mem_init+0x91b>
f0101e08:	c7 44 24 0c 39 7a 10 	movl   $0xf0107a39,0xc(%esp)
f0101e0f:	f0 
f0101e10:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101e17:	f0 
f0101e18:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0101e1f:	00 
f0101e20:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101e27:	e8 14 e2 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101e2c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e31:	74 24                	je     f0101e57 <mem_init+0x946>
f0101e33:	c7 44 24 0c 4a 7a 10 	movl   $0xf0107a4a,0xc(%esp)
f0101e3a:	f0 
f0101e3b:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101e42:	f0 
f0101e43:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0101e4a:	00 
f0101e4b:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101e52:	e8 e9 e1 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e57:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e5e:	00 
f0101e5f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e66:	00 
f0101e67:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e6b:	89 3c 24             	mov    %edi,(%esp)
f0101e6e:	e8 f4 f5 ff ff       	call   f0101467 <page_insert>
f0101e73:	85 c0                	test   %eax,%eax
f0101e75:	74 24                	je     f0101e9b <mem_init+0x98a>
f0101e77:	c7 44 24 0c 8c 73 10 	movl   $0xf010738c,0xc(%esp)
f0101e7e:	f0 
f0101e7f:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101e86:	f0 
f0101e87:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0101e8e:	00 
f0101e8f:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101e96:	e8 a5 e1 ff ff       	call   f0100040 <_panic>
	//panic("va2pa: %x,page %x", check_va2pa(kern_pgdir, PGSIZE), page2pa(pp2));
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e9b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ea0:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101ea5:	e8 e6 ec ff ff       	call   f0100b90 <check_va2pa>
f0101eaa:	89 f2                	mov    %esi,%edx
f0101eac:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101eb2:	c1 fa 03             	sar    $0x3,%edx
f0101eb5:	c1 e2 0c             	shl    $0xc,%edx
f0101eb8:	39 d0                	cmp    %edx,%eax
f0101eba:	74 24                	je     f0101ee0 <mem_init+0x9cf>
f0101ebc:	c7 44 24 0c c8 73 10 	movl   $0xf01073c8,0xc(%esp)
f0101ec3:	f0 
f0101ec4:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101ecb:	f0 
f0101ecc:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0101ed3:	00 
f0101ed4:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101edb:	e8 60 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ee0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ee5:	74 24                	je     f0101f0b <mem_init+0x9fa>
f0101ee7:	c7 44 24 0c 5b 7a 10 	movl   $0xf0107a5b,0xc(%esp)
f0101eee:	f0 
f0101eef:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101ef6:	f0 
f0101ef7:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0101efe:	00 
f0101eff:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101f06:	e8 35 e1 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f0b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f12:	e8 48 f2 ff ff       	call   f010115f <page_alloc>
f0101f17:	85 c0                	test   %eax,%eax
f0101f19:	74 24                	je     f0101f3f <mem_init+0xa2e>
f0101f1b:	c7 44 24 0c e7 79 10 	movl   $0xf01079e7,0xc(%esp)
f0101f22:	f0 
f0101f23:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101f2a:	f0 
f0101f2b:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0101f32:	00 
f0101f33:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101f3a:	e8 01 e1 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f3f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f46:	00 
f0101f47:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f4e:	00 
f0101f4f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f53:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101f58:	89 04 24             	mov    %eax,(%esp)
f0101f5b:	e8 07 f5 ff ff       	call   f0101467 <page_insert>
f0101f60:	85 c0                	test   %eax,%eax
f0101f62:	74 24                	je     f0101f88 <mem_init+0xa77>
f0101f64:	c7 44 24 0c 8c 73 10 	movl   $0xf010738c,0xc(%esp)
f0101f6b:	f0 
f0101f6c:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101f73:	f0 
f0101f74:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0101f7b:	00 
f0101f7c:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101f83:	e8 b8 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f88:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f8d:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101f92:	e8 f9 eb ff ff       	call   f0100b90 <check_va2pa>
f0101f97:	89 f2                	mov    %esi,%edx
f0101f99:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101f9f:	c1 fa 03             	sar    $0x3,%edx
f0101fa2:	c1 e2 0c             	shl    $0xc,%edx
f0101fa5:	39 d0                	cmp    %edx,%eax
f0101fa7:	74 24                	je     f0101fcd <mem_init+0xabc>
f0101fa9:	c7 44 24 0c c8 73 10 	movl   $0xf01073c8,0xc(%esp)
f0101fb0:	f0 
f0101fb1:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101fb8:	f0 
f0101fb9:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f0101fc0:	00 
f0101fc1:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101fc8:	e8 73 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101fcd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fd2:	74 24                	je     f0101ff8 <mem_init+0xae7>
f0101fd4:	c7 44 24 0c 5b 7a 10 	movl   $0xf0107a5b,0xc(%esp)
f0101fdb:	f0 
f0101fdc:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0101fe3:	f0 
f0101fe4:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0101feb:	00 
f0101fec:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0101ff3:	e8 48 e0 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ff8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fff:	e8 5b f1 ff ff       	call   f010115f <page_alloc>
f0102004:	85 c0                	test   %eax,%eax
f0102006:	74 24                	je     f010202c <mem_init+0xb1b>
f0102008:	c7 44 24 0c e7 79 10 	movl   $0xf01079e7,0xc(%esp)
f010200f:	f0 
f0102010:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102017:	f0 
f0102018:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f010201f:	00 
f0102020:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102027:	e8 14 e0 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010202c:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0102032:	8b 02                	mov    (%edx),%eax
f0102034:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102039:	89 c1                	mov    %eax,%ecx
f010203b:	c1 e9 0c             	shr    $0xc,%ecx
f010203e:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0102044:	72 20                	jb     f0102066 <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102046:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010204a:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0102051:	f0 
f0102052:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f0102059:	00 
f010205a:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102061:	e8 da df ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102066:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010206b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010206e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102075:	00 
f0102076:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010207d:	00 
f010207e:	89 14 24             	mov    %edx,(%esp)
f0102081:	e8 9c f1 ff ff       	call   f0101222 <pgdir_walk>
f0102086:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102089:	83 c2 04             	add    $0x4,%edx
f010208c:	39 d0                	cmp    %edx,%eax
f010208e:	74 24                	je     f01020b4 <mem_init+0xba3>
f0102090:	c7 44 24 0c f8 73 10 	movl   $0xf01073f8,0xc(%esp)
f0102097:	f0 
f0102098:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010209f:	f0 
f01020a0:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f01020a7:	00 
f01020a8:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01020af:	e8 8c df ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01020b4:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01020bb:	00 
f01020bc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020c3:	00 
f01020c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01020c8:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01020cd:	89 04 24             	mov    %eax,(%esp)
f01020d0:	e8 92 f3 ff ff       	call   f0101467 <page_insert>
f01020d5:	85 c0                	test   %eax,%eax
f01020d7:	74 24                	je     f01020fd <mem_init+0xbec>
f01020d9:	c7 44 24 0c 38 74 10 	movl   $0xf0107438,0xc(%esp)
f01020e0:	f0 
f01020e1:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01020e8:	f0 
f01020e9:	c7 44 24 04 b0 03 00 	movl   $0x3b0,0x4(%esp)
f01020f0:	00 
f01020f1:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01020f8:	e8 43 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020fd:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0102103:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102108:	89 f8                	mov    %edi,%eax
f010210a:	e8 81 ea ff ff       	call   f0100b90 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010210f:	89 f2                	mov    %esi,%edx
f0102111:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0102117:	c1 fa 03             	sar    $0x3,%edx
f010211a:	c1 e2 0c             	shl    $0xc,%edx
f010211d:	39 d0                	cmp    %edx,%eax
f010211f:	74 24                	je     f0102145 <mem_init+0xc34>
f0102121:	c7 44 24 0c c8 73 10 	movl   $0xf01073c8,0xc(%esp)
f0102128:	f0 
f0102129:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102130:	f0 
f0102131:	c7 44 24 04 b1 03 00 	movl   $0x3b1,0x4(%esp)
f0102138:	00 
f0102139:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102140:	e8 fb de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102145:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010214a:	74 24                	je     f0102170 <mem_init+0xc5f>
f010214c:	c7 44 24 0c 5b 7a 10 	movl   $0xf0107a5b,0xc(%esp)
f0102153:	f0 
f0102154:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010215b:	f0 
f010215c:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0102163:	00 
f0102164:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010216b:	e8 d0 de ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102170:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102177:	00 
f0102178:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010217f:	00 
f0102180:	89 3c 24             	mov    %edi,(%esp)
f0102183:	e8 9a f0 ff ff       	call   f0101222 <pgdir_walk>
f0102188:	f6 00 04             	testb  $0x4,(%eax)
f010218b:	75 24                	jne    f01021b1 <mem_init+0xca0>
f010218d:	c7 44 24 0c 78 74 10 	movl   $0xf0107478,0xc(%esp)
f0102194:	f0 
f0102195:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010219c:	f0 
f010219d:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f01021a4:	00 
f01021a5:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01021ac:	e8 8f de ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01021b1:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01021b6:	f6 00 04             	testb  $0x4,(%eax)
f01021b9:	75 24                	jne    f01021df <mem_init+0xcce>
f01021bb:	c7 44 24 0c 6c 7a 10 	movl   $0xf0107a6c,0xc(%esp)
f01021c2:	f0 
f01021c3:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01021ca:	f0 
f01021cb:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f01021d2:	00 
f01021d3:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01021da:	e8 61 de ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01021df:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021e6:	00 
f01021e7:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01021ee:	00 
f01021ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01021f3:	89 04 24             	mov    %eax,(%esp)
f01021f6:	e8 6c f2 ff ff       	call   f0101467 <page_insert>
f01021fb:	85 c0                	test   %eax,%eax
f01021fd:	78 24                	js     f0102223 <mem_init+0xd12>
f01021ff:	c7 44 24 0c ac 74 10 	movl   $0xf01074ac,0xc(%esp)
f0102206:	f0 
f0102207:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010220e:	f0 
f010220f:	c7 44 24 04 b7 03 00 	movl   $0x3b7,0x4(%esp)
f0102216:	00 
f0102217:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010221e:	e8 1d de ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102223:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010222a:	00 
f010222b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102232:	00 
f0102233:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102236:	89 44 24 04          	mov    %eax,0x4(%esp)
f010223a:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010223f:	89 04 24             	mov    %eax,(%esp)
f0102242:	e8 20 f2 ff ff       	call   f0101467 <page_insert>
f0102247:	85 c0                	test   %eax,%eax
f0102249:	74 24                	je     f010226f <mem_init+0xd5e>
f010224b:	c7 44 24 0c e4 74 10 	movl   $0xf01074e4,0xc(%esp)
f0102252:	f0 
f0102253:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010225a:	f0 
f010225b:	c7 44 24 04 ba 03 00 	movl   $0x3ba,0x4(%esp)
f0102262:	00 
f0102263:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010226a:	e8 d1 dd ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010226f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102276:	00 
f0102277:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010227e:	00 
f010227f:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102284:	89 04 24             	mov    %eax,(%esp)
f0102287:	e8 96 ef ff ff       	call   f0101222 <pgdir_walk>
f010228c:	f6 00 04             	testb  $0x4,(%eax)
f010228f:	74 24                	je     f01022b5 <mem_init+0xda4>
f0102291:	c7 44 24 0c 20 75 10 	movl   $0xf0107520,0xc(%esp)
f0102298:	f0 
f0102299:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01022a0:	f0 
f01022a1:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f01022a8:	00 
f01022a9:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01022b0:	e8 8b dd ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01022b5:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f01022bb:	ba 00 00 00 00       	mov    $0x0,%edx
f01022c0:	89 f8                	mov    %edi,%eax
f01022c2:	e8 c9 e8 ff ff       	call   f0100b90 <check_va2pa>
f01022c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01022ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022cd:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01022d3:	c1 f8 03             	sar    $0x3,%eax
f01022d6:	c1 e0 0c             	shl    $0xc,%eax
f01022d9:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01022dc:	74 24                	je     f0102302 <mem_init+0xdf1>
f01022de:	c7 44 24 0c 58 75 10 	movl   $0xf0107558,0xc(%esp)
f01022e5:	f0 
f01022e6:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01022ed:	f0 
f01022ee:	c7 44 24 04 be 03 00 	movl   $0x3be,0x4(%esp)
f01022f5:	00 
f01022f6:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01022fd:	e8 3e dd ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102302:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102307:	89 f8                	mov    %edi,%eax
f0102309:	e8 82 e8 ff ff       	call   f0100b90 <check_va2pa>
f010230e:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102311:	74 24                	je     f0102337 <mem_init+0xe26>
f0102313:	c7 44 24 0c 84 75 10 	movl   $0xf0107584,0xc(%esp)
f010231a:	f0 
f010231b:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102322:	f0 
f0102323:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f010232a:	00 
f010232b:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102332:	e8 09 dd ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102337:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010233a:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f010233f:	74 24                	je     f0102365 <mem_init+0xe54>
f0102341:	c7 44 24 0c 82 7a 10 	movl   $0xf0107a82,0xc(%esp)
f0102348:	f0 
f0102349:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102350:	f0 
f0102351:	c7 44 24 04 c1 03 00 	movl   $0x3c1,0x4(%esp)
f0102358:	00 
f0102359:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102360:	e8 db dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102365:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010236a:	74 24                	je     f0102390 <mem_init+0xe7f>
f010236c:	c7 44 24 0c 93 7a 10 	movl   $0xf0107a93,0xc(%esp)
f0102373:	f0 
f0102374:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010237b:	f0 
f010237c:	c7 44 24 04 c2 03 00 	movl   $0x3c2,0x4(%esp)
f0102383:	00 
f0102384:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010238b:	e8 b0 dc ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102390:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102397:	e8 c3 ed ff ff       	call   f010115f <page_alloc>
f010239c:	85 c0                	test   %eax,%eax
f010239e:	74 04                	je     f01023a4 <mem_init+0xe93>
f01023a0:	39 c6                	cmp    %eax,%esi
f01023a2:	74 24                	je     f01023c8 <mem_init+0xeb7>
f01023a4:	c7 44 24 0c b4 75 10 	movl   $0xf01075b4,0xc(%esp)
f01023ab:	f0 
f01023ac:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01023b3:	f0 
f01023b4:	c7 44 24 04 c5 03 00 	movl   $0x3c5,0x4(%esp)
f01023bb:	00 
f01023bc:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01023c3:	e8 78 dc ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01023c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01023cf:	00 
f01023d0:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01023d5:	89 04 24             	mov    %eax,(%esp)
f01023d8:	e8 3a f0 ff ff       	call   f0101417 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01023dd:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f01023e3:	ba 00 00 00 00       	mov    $0x0,%edx
f01023e8:	89 f8                	mov    %edi,%eax
f01023ea:	e8 a1 e7 ff ff       	call   f0100b90 <check_va2pa>
f01023ef:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023f2:	74 24                	je     f0102418 <mem_init+0xf07>
f01023f4:	c7 44 24 0c d8 75 10 	movl   $0xf01075d8,0xc(%esp)
f01023fb:	f0 
f01023fc:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102403:	f0 
f0102404:	c7 44 24 04 c9 03 00 	movl   $0x3c9,0x4(%esp)
f010240b:	00 
f010240c:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102413:	e8 28 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102418:	ba 00 10 00 00       	mov    $0x1000,%edx
f010241d:	89 f8                	mov    %edi,%eax
f010241f:	e8 6c e7 ff ff       	call   f0100b90 <check_va2pa>
f0102424:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102427:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f010242d:	c1 fa 03             	sar    $0x3,%edx
f0102430:	c1 e2 0c             	shl    $0xc,%edx
f0102433:	39 d0                	cmp    %edx,%eax
f0102435:	74 24                	je     f010245b <mem_init+0xf4a>
f0102437:	c7 44 24 0c 84 75 10 	movl   $0xf0107584,0xc(%esp)
f010243e:	f0 
f010243f:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102446:	f0 
f0102447:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f010244e:	00 
f010244f:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102456:	e8 e5 db ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010245b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010245e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102463:	74 24                	je     f0102489 <mem_init+0xf78>
f0102465:	c7 44 24 0c 39 7a 10 	movl   $0xf0107a39,0xc(%esp)
f010246c:	f0 
f010246d:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102474:	f0 
f0102475:	c7 44 24 04 cb 03 00 	movl   $0x3cb,0x4(%esp)
f010247c:	00 
f010247d:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102484:	e8 b7 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102489:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010248e:	74 24                	je     f01024b4 <mem_init+0xfa3>
f0102490:	c7 44 24 0c 93 7a 10 	movl   $0xf0107a93,0xc(%esp)
f0102497:	f0 
f0102498:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010249f:	f0 
f01024a0:	c7 44 24 04 cc 03 00 	movl   $0x3cc,0x4(%esp)
f01024a7:	00 
f01024a8:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01024af:	e8 8c db ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01024b4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01024bb:	00 
f01024bc:	89 3c 24             	mov    %edi,(%esp)
f01024bf:	e8 53 ef ff ff       	call   f0101417 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024c4:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f01024ca:	ba 00 00 00 00       	mov    $0x0,%edx
f01024cf:	89 f8                	mov    %edi,%eax
f01024d1:	e8 ba e6 ff ff       	call   f0100b90 <check_va2pa>
f01024d6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024d9:	74 24                	je     f01024ff <mem_init+0xfee>
f01024db:	c7 44 24 0c d8 75 10 	movl   $0xf01075d8,0xc(%esp)
f01024e2:	f0 
f01024e3:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01024ea:	f0 
f01024eb:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f01024f2:	00 
f01024f3:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01024fa:	e8 41 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01024ff:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102504:	89 f8                	mov    %edi,%eax
f0102506:	e8 85 e6 ff ff       	call   f0100b90 <check_va2pa>
f010250b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010250e:	74 24                	je     f0102534 <mem_init+0x1023>
f0102510:	c7 44 24 0c fc 75 10 	movl   $0xf01075fc,0xc(%esp)
f0102517:	f0 
f0102518:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010251f:	f0 
f0102520:	c7 44 24 04 d1 03 00 	movl   $0x3d1,0x4(%esp)
f0102527:	00 
f0102528:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010252f:	e8 0c db ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102534:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102537:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010253c:	74 24                	je     f0102562 <mem_init+0x1051>
f010253e:	c7 44 24 0c a4 7a 10 	movl   $0xf0107aa4,0xc(%esp)
f0102545:	f0 
f0102546:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010254d:	f0 
f010254e:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102555:	00 
f0102556:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010255d:	e8 de da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102562:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102567:	74 24                	je     f010258d <mem_init+0x107c>
f0102569:	c7 44 24 0c 93 7a 10 	movl   $0xf0107a93,0xc(%esp)
f0102570:	f0 
f0102571:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102578:	f0 
f0102579:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f0102580:	00 
f0102581:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102588:	e8 b3 da ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010258d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102594:	e8 c6 eb ff ff       	call   f010115f <page_alloc>
f0102599:	85 c0                	test   %eax,%eax
f010259b:	74 05                	je     f01025a2 <mem_init+0x1091>
f010259d:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01025a0:	74 24                	je     f01025c6 <mem_init+0x10b5>
f01025a2:	c7 44 24 0c 24 76 10 	movl   $0xf0107624,0xc(%esp)
f01025a9:	f0 
f01025aa:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01025b1:	f0 
f01025b2:	c7 44 24 04 d6 03 00 	movl   $0x3d6,0x4(%esp)
f01025b9:	00 
f01025ba:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01025c1:	e8 7a da ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01025c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025cd:	e8 8d eb ff ff       	call   f010115f <page_alloc>
f01025d2:	85 c0                	test   %eax,%eax
f01025d4:	74 24                	je     f01025fa <mem_init+0x10e9>
f01025d6:	c7 44 24 0c e7 79 10 	movl   $0xf01079e7,0xc(%esp)
f01025dd:	f0 
f01025de:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01025e5:	f0 
f01025e6:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f01025ed:	00 
f01025ee:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01025f5:	e8 46 da ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025fa:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025ff:	8b 08                	mov    (%eax),%ecx
f0102601:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102607:	89 da                	mov    %ebx,%edx
f0102609:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f010260f:	c1 fa 03             	sar    $0x3,%edx
f0102612:	c1 e2 0c             	shl    $0xc,%edx
f0102615:	39 d1                	cmp    %edx,%ecx
f0102617:	74 24                	je     f010263d <mem_init+0x112c>
f0102619:	c7 44 24 0c 34 73 10 	movl   $0xf0107334,0xc(%esp)
f0102620:	f0 
f0102621:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102628:	f0 
f0102629:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0102630:	00 
f0102631:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102638:	e8 03 da ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010263d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102643:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102648:	74 24                	je     f010266e <mem_init+0x115d>
f010264a:	c7 44 24 0c 4a 7a 10 	movl   $0xf0107a4a,0xc(%esp)
f0102651:	f0 
f0102652:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102659:	f0 
f010265a:	c7 44 24 04 de 03 00 	movl   $0x3de,0x4(%esp)
f0102661:	00 
f0102662:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102669:	e8 d2 d9 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010266e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102674:	89 1c 24             	mov    %ebx,(%esp)
f0102677:	e8 67 eb ff ff       	call   f01011e3 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010267c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102683:	00 
f0102684:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010268b:	00 
f010268c:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102691:	89 04 24             	mov    %eax,(%esp)
f0102694:	e8 89 eb ff ff       	call   f0101222 <pgdir_walk>
f0102699:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010269c:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f01026a2:	8b 4a 04             	mov    0x4(%edx),%ecx
f01026a5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01026ab:	89 4d cc             	mov    %ecx,-0x34(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026ae:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f01026b4:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01026b7:	c1 ef 0c             	shr    $0xc,%edi
f01026ba:	39 cf                	cmp    %ecx,%edi
f01026bc:	72 23                	jb     f01026e1 <mem_init+0x11d0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026be:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01026c1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026c5:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01026cc:	f0 
f01026cd:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f01026d4:	00 
f01026d5:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01026dc:	e8 5f d9 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01026e1:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01026e4:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01026ea:	39 f8                	cmp    %edi,%eax
f01026ec:	74 24                	je     f0102712 <mem_init+0x1201>
f01026ee:	c7 44 24 0c b5 7a 10 	movl   $0xf0107ab5,0xc(%esp)
f01026f5:	f0 
f01026f6:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01026fd:	f0 
f01026fe:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f0102705:	00 
f0102706:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010270d:	e8 2e d9 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102712:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102719:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010271f:	89 d8                	mov    %ebx,%eax
f0102721:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102727:	c1 f8 03             	sar    $0x3,%eax
f010272a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010272d:	89 c2                	mov    %eax,%edx
f010272f:	c1 ea 0c             	shr    $0xc,%edx
f0102732:	39 d1                	cmp    %edx,%ecx
f0102734:	77 20                	ja     f0102756 <mem_init+0x1245>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102736:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010273a:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0102741:	f0 
f0102742:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102749:	00 
f010274a:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f0102751:	e8 ea d8 ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102756:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010275d:	00 
f010275e:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102765:	00 
	return (void *)(pa + KERNBASE);
f0102766:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010276b:	89 04 24             	mov    %eax,(%esp)
f010276e:	e8 22 36 00 00       	call   f0105d95 <memset>
	page_free(pp0);
f0102773:	89 1c 24             	mov    %ebx,(%esp)
f0102776:	e8 68 ea ff ff       	call   f01011e3 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010277b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102782:	00 
f0102783:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010278a:	00 
f010278b:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102790:	89 04 24             	mov    %eax,(%esp)
f0102793:	e8 8a ea ff ff       	call   f0101222 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102798:	89 da                	mov    %ebx,%edx
f010279a:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f01027a0:	c1 fa 03             	sar    $0x3,%edx
f01027a3:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027a6:	89 d0                	mov    %edx,%eax
f01027a8:	c1 e8 0c             	shr    $0xc,%eax
f01027ab:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01027b1:	72 20                	jb     f01027d3 <mem_init+0x12c2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027b3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01027b7:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01027be:	f0 
f01027bf:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01027c6:	00 
f01027c7:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f01027ce:	e8 6d d8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01027d3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01027d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01027dc:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f01027e3:	75 11                	jne    f01027f6 <mem_init+0x12e5>
f01027e5:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027eb:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01027f1:	f6 00 01             	testb  $0x1,(%eax)
f01027f4:	74 24                	je     f010281a <mem_init+0x1309>
f01027f6:	c7 44 24 0c cd 7a 10 	movl   $0xf0107acd,0xc(%esp)
f01027fd:	f0 
f01027fe:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102805:	f0 
f0102806:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f010280d:	00 
f010280e:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102815:	e8 26 d8 ff ff       	call   f0100040 <_panic>
f010281a:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010281d:	39 d0                	cmp    %edx,%eax
f010281f:	75 d0                	jne    f01027f1 <mem_init+0x12e0>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102821:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102826:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010282c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102832:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102835:	89 3d 40 a2 22 f0    	mov    %edi,0xf022a240

	// free the pages we took
	page_free(pp0);
f010283b:	89 1c 24             	mov    %ebx,(%esp)
f010283e:	e8 a0 e9 ff ff       	call   f01011e3 <page_free>
	page_free(pp1);
f0102843:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102846:	89 04 24             	mov    %eax,(%esp)
f0102849:	e8 95 e9 ff ff       	call   f01011e3 <page_free>
	page_free(pp2);
f010284e:	89 34 24             	mov    %esi,(%esp)
f0102851:	e8 8d e9 ff ff       	call   f01011e3 <page_free>

	cprintf("check_page() succeeded!\n");
f0102856:	c7 04 24 e4 7a 10 f0 	movl   $0xf0107ae4,(%esp)
f010285d:	e8 94 14 00 00       	call   f0103cf6 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
//pte_t *p = (pte_t *)0xf03fd000;
	boot_map_region(kern_pgdir,UPAGES, npages * sizeof(struct Page), PADDR(pages), PTE_U|PTE_P);
f0102862:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102867:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010286c:	77 20                	ja     f010288e <mem_init+0x137d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010286e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102872:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f0102879:	f0 
f010287a:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f0102881:	00 
f0102882:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102889:	e8 b2 d7 ff ff       	call   f0100040 <_panic>
f010288e:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0102894:	c1 e1 03             	shl    $0x3,%ecx
f0102897:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f010289e:	00 
	return (physaddr_t)kva - KERNBASE;
f010289f:	05 00 00 00 10       	add    $0x10000000,%eax
f01028a4:	89 04 24             	mov    %eax,(%esp)
f01028a7:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01028ac:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01028b1:	e8 4f ea ff ff       	call   f0101305 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS, NENV * sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f01028b6:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028bb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028c0:	77 20                	ja     f01028e2 <mem_init+0x13d1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028c6:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f01028cd:	f0 
f01028ce:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
f01028d5:	00 
f01028d6:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01028dd:	e8 5e d7 ff ff       	call   f0100040 <_panic>
f01028e2:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01028e9:	00 
	return (physaddr_t)kva - KERNBASE;
f01028ea:	05 00 00 00 10       	add    $0x10000000,%eax
f01028ef:	89 04 24             	mov    %eax,(%esp)
f01028f2:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f01028f7:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01028fc:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102901:	e8 ff e9 ff ff       	call   f0101305 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102906:	b8 00 70 11 f0       	mov    $0xf0117000,%eax
f010290b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102910:	77 20                	ja     f0102932 <mem_init+0x1421>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102912:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102916:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f010291d:	f0 
f010291e:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
f0102925:	00 
f0102926:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010292d:	e8 0e d7 ff ff       	call   f0100040 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
//	cprintf("\n%x\n", KSTACKTOP - KSTKSIZE);
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_P|PTE_W);
f0102932:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102939:	00 
f010293a:	c7 04 24 00 70 11 00 	movl   $0x117000,(%esp)
f0102941:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102946:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f010294b:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102950:	e8 b0 e9 ff ff       	call   f0101305 <boot_map_region>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ~0x0 - KERNBASE + 1;
	//cprintf("the size is %x", size);
	boot_map_region(kern_pgdir, KERNBASE, size, (physaddr_t)0,PTE_P|PTE_W);
f0102955:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010295c:	00 
f010295d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102964:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102969:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010296e:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102973:	e8 8d e9 ff ff       	call   f0101305 <boot_map_region>
mem_init_mp(void)
{
	// Create a direct mapping at the top of virtual address space starting
	// at IOMEMBASE for accessing the LAPIC unit using memory-mapped I/O.
	//cprintf("mem_init_mp: %x %x\n", IOMEMBASE, IOMEM_PADDR);
	boot_map_region(kern_pgdir, IOMEMBASE, -IOMEMBASE, IOMEM_PADDR, PTE_W);
f0102978:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010297f:	00 
f0102980:	c7 04 24 00 00 00 fe 	movl   $0xfe000000,(%esp)
f0102987:	b9 00 00 00 02       	mov    $0x2000000,%ecx
f010298c:	ba 00 00 00 fe       	mov    $0xfe000000,%edx
f0102991:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102996:	e8 6a e9 ff ff       	call   f0101305 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010299b:	b8 00 c0 22 f0       	mov    $0xf022c000,%eax
f01029a0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029a5:	0f 87 1e 08 00 00    	ja     f01031c9 <mem_init+0x1cb8>
f01029ab:	eb 20                	jmp    f01029cd <mem_init+0x14bc>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01029ad:	89 da                	mov    %ebx,%edx
f01029af:	f7 da                	neg    %edx
f01029b1:	c1 e2 10             	shl    $0x10,%edx
f01029b4:	81 ea 00 80 40 10    	sub    $0x10408000,%edx
	uint32_t kstacktop_i;
	for(; i < NCPU; i++){
		kstacktop_i = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (i + 1) + KSTKGAP;
		// panic("%x",percpu_kstacks[i]);
		// cprintf("%x\n",kstacktop_i);
		boot_map_region(kern_pgdir, kstacktop_i, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W|PTE_P);
f01029ba:	89 d8                	mov    %ebx,%eax
f01029bc:	c1 e0 0f             	shl    $0xf,%eax
f01029bf:	05 00 c0 22 f0       	add    $0xf022c000,%eax
f01029c4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029c9:	77 27                	ja     f01029f2 <mem_init+0x14e1>
f01029cb:	eb 05                	jmp    f01029d2 <mem_init+0x14c1>
f01029cd:	b8 00 c0 22 f0       	mov    $0xf022c000,%eax
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029d2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029d6:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f01029dd:	f0 
f01029de:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
f01029e5:	00 
f01029e6:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01029ed:	e8 4e d6 ff ff       	call   f0100040 <_panic>
f01029f2:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01029f9:	00 
	return (physaddr_t)kva - KERNBASE;
f01029fa:	05 00 00 00 10       	add    $0x10000000,%eax
f01029ff:	89 04 24             	mov    %eax,(%esp)
f0102a02:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102a07:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102a0c:	e8 f4 e8 ff ff       	call   f0101305 <boot_map_region>
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	size_t i = 0;
	uint32_t kstacktop_i;
	for(; i < NCPU; i++){
f0102a11:	83 c3 01             	add    $0x1,%ebx
f0102a14:	83 fb 08             	cmp    $0x8,%ebx
f0102a17:	75 94                	jne    f01029ad <mem_init+0x149c>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102a19:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f0102a1f:	8b 15 88 ae 22 f0    	mov    0xf022ae88,%edx
f0102a25:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102a28:	8d 04 d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f0102a2f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102a34:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a37:	75 30                	jne    f0102a69 <mem_init+0x1558>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a39:	8b 1d 48 a2 22 f0    	mov    0xf022a248,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a3f:	89 de                	mov    %ebx,%esi
f0102a41:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102a46:	89 f8                	mov    %edi,%eax
f0102a48:	e8 43 e1 ff ff       	call   f0100b90 <check_va2pa>
f0102a4d:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102a53:	0f 86 94 00 00 00    	jbe    f0102aed <mem_init+0x15dc>
f0102a59:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102a5e:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0102a64:	e9 a4 00 00 00       	jmp    f0102b0d <mem_init+0x15fc>
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a69:	8b 1d 90 ae 22 f0    	mov    0xf022ae90,%ebx
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102a6f:	8d b3 00 00 00 10    	lea    0x10000000(%ebx),%esi
f0102a75:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102a7a:	89 f8                	mov    %edi,%eax
f0102a7c:	e8 0f e1 ff ff       	call   f0100b90 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a81:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102a87:	77 20                	ja     f0102aa9 <mem_init+0x1598>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a89:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102a8d:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f0102a94:	f0 
f0102a95:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0102a9c:	00 
f0102a9d:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102aa4:	e8 97 d5 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102aa9:	ba 00 00 00 00       	mov    $0x0,%edx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102aae:	8d 0c 32             	lea    (%edx,%esi,1),%ecx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102ab1:	39 c1                	cmp    %eax,%ecx
f0102ab3:	74 24                	je     f0102ad9 <mem_init+0x15c8>
f0102ab5:	c7 44 24 0c 48 76 10 	movl   $0xf0107648,0xc(%esp)
f0102abc:	f0 
f0102abd:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102ac4:	f0 
f0102ac5:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0102acc:	00 
f0102acd:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102ad4:	e8 67 d5 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102ad9:	8d 9a 00 10 00 00    	lea    0x1000(%edx),%ebx
f0102adf:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102ae2:	0f 87 1c 07 00 00    	ja     f0103204 <mem_init+0x1cf3>
f0102ae8:	e9 4c ff ff ff       	jmp    f0102a39 <mem_init+0x1528>
f0102aed:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102af1:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f0102af8:	f0 
f0102af9:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102b00:	00 
f0102b01:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102b08:	e8 33 d5 ff ff       	call   f0100040 <_panic>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102b0d:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102b10:	39 d0                	cmp    %edx,%eax
f0102b12:	74 24                	je     f0102b38 <mem_init+0x1627>
f0102b14:	c7 44 24 0c 7c 76 10 	movl   $0xf010767c,0xc(%esp)
f0102b1b:	f0 
f0102b1c:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102b23:	f0 
f0102b24:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102b2b:	00 
f0102b2c:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102b33:	e8 08 d5 ff ff       	call   f0100040 <_panic>
f0102b38:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102b3e:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102b44:	0f 85 ac 06 00 00    	jne    f01031f6 <mem_init+0x1ce5>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b4a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102b4d:	c1 e6 0c             	shl    $0xc,%esi
f0102b50:	85 f6                	test   %esi,%esi
f0102b52:	74 4b                	je     f0102b9f <mem_init+0x168e>
f0102b54:	bb 00 00 00 00       	mov    $0x0,%ebx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102b59:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102b5f:	89 f8                	mov    %edi,%eax
f0102b61:	e8 2a e0 ff ff       	call   f0100b90 <check_va2pa>
f0102b66:	39 c3                	cmp    %eax,%ebx
f0102b68:	74 24                	je     f0102b8e <mem_init+0x167d>
f0102b6a:	c7 44 24 0c b0 76 10 	movl   $0xf01076b0,0xc(%esp)
f0102b71:	f0 
f0102b72:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102b79:	f0 
f0102b7a:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0102b81:	00 
f0102b82:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102b89:	e8 b2 d4 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b8e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102b94:	39 f3                	cmp    %esi,%ebx
f0102b96:	72 c1                	jb     f0102b59 <mem_init+0x1648>
f0102b98:	bb 00 00 00 fe       	mov    $0xfe000000,%ebx
f0102b9d:	eb 05                	jmp    f0102ba4 <mem_init+0x1693>
f0102b9f:	bb 00 00 00 fe       	mov    $0xfe000000,%ebx
	// check IO mem (new in lab 4)
	//cprintf("check_kern_pgdir: %x", IOMEMBASE);
	for (i = IOMEMBASE; i < -PGSIZE; i += PGSIZE){
		//cprintf("i is %x\n", i);
		//cprintf("check_va2pa: %x\n",check_va2pa(pgdir, i));
		assert(check_va2pa(pgdir, i) == i);
f0102ba4:	89 da                	mov    %ebx,%edx
f0102ba6:	89 f8                	mov    %edi,%eax
f0102ba8:	e8 e3 df ff ff       	call   f0100b90 <check_va2pa>
f0102bad:	39 c3                	cmp    %eax,%ebx
f0102baf:	74 24                	je     f0102bd5 <mem_init+0x16c4>
f0102bb1:	c7 44 24 0c fd 7a 10 	movl   $0xf0107afd,0xc(%esp)
f0102bb8:	f0 
f0102bb9:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102bc0:	f0 
f0102bc1:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0102bc8:	00 
f0102bc9:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102bd0:	e8 6b d4 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check IO mem (new in lab 4)
	//cprintf("check_kern_pgdir: %x", IOMEMBASE);
	for (i = IOMEMBASE; i < -PGSIZE; i += PGSIZE){
f0102bd5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102bdb:	81 fb 00 f0 ff ff    	cmp    $0xfffff000,%ebx
f0102be1:	75 c1                	jne    f0102ba4 <mem_init+0x1693>
f0102be3:	be 00 00 bf ef       	mov    $0xefbf0000,%esi
f0102be8:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0102bef:	89 7d d4             	mov    %edi,-0x2c(%ebp)
}
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
f0102bf2:	bb 00 00 00 00       	mov    $0x0,%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102bf7:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102bfa:	c1 e7 0f             	shl    $0xf,%edi
f0102bfd:	81 c7 00 c0 22 f0    	add    $0xf022c000,%edi
	return (physaddr_t)kva - KERNBASE;
f0102c03:	8d 8f 00 00 00 10    	lea    0x10000000(%edi),%ecx
f0102c09:	89 4d d0             	mov    %ecx,-0x30(%ebp)
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102c0c:	8d 94 1e 00 80 00 00 	lea    0x8000(%esi,%ebx,1),%edx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102c13:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c16:	e8 75 df ff ff       	call   f0100b90 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c1b:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0102c21:	77 20                	ja     f0102c43 <mem_init+0x1732>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c23:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102c27:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f0102c2e:	f0 
f0102c2f:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102c36:	00 
f0102c37:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102c3e:	e8 fd d3 ff ff       	call   f0100040 <_panic>
f0102c43:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102c46:	01 da                	add    %ebx,%edx
f0102c48:	39 d0                	cmp    %edx,%eax
f0102c4a:	74 24                	je     f0102c70 <mem_init+0x175f>
f0102c4c:	c7 44 24 0c d8 76 10 	movl   $0xf01076d8,0xc(%esp)
f0102c53:	f0 
f0102c54:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102c5b:	f0 
f0102c5c:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102c63:	00 
f0102c64:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102c6b:	e8 d0 d3 ff ff       	call   f0100040 <_panic>
}
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
f0102c70:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102c76:	81 fb 00 80 00 00    	cmp    $0x8000,%ebx
f0102c7c:	75 8e                	jne    f0102c0c <mem_init+0x16fb>
f0102c7e:	66 bb 00 00          	mov    $0x0,%bx
f0102c82:	8b 7d d4             	mov    -0x2c(%ebp),%edi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102c85:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);}
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102c88:	89 f8                	mov    %edi,%eax
f0102c8a:	e8 01 df ff ff       	call   f0100b90 <check_va2pa>
f0102c8f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c92:	74 24                	je     f0102cb8 <mem_init+0x17a7>
f0102c94:	c7 44 24 0c 20 77 10 	movl   $0xf0107720,0xc(%esp)
f0102c9b:	f0 
f0102c9c:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102ca3:	f0 
f0102ca4:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102cab:	00 
f0102cac:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102cb3:	e8 88 d3 ff ff       	call   f0100040 <_panic>
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);}
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102cb8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102cbe:	81 fb 00 80 00 00    	cmp    $0x8000,%ebx
f0102cc4:	75 bf                	jne    f0102c85 <mem_init+0x1774>
		//cprintf("check_va2pa: %x\n",check_va2pa(pgdir, i));
		assert(check_va2pa(pgdir, i) == i);
}
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102cc6:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0102cca:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f0102cd0:	83 7d cc 08          	cmpl   $0x8,-0x34(%ebp)
f0102cd4:	0f 85 18 ff ff ff    	jne    f0102bf2 <mem_init+0x16e1>
f0102cda:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102cdd:	b8 00 00 00 00       	mov    $0x0,%eax
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102ce2:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102ce8:	83 fa 03             	cmp    $0x3,%edx
f0102ceb:	77 2e                	ja     f0102d1b <mem_init+0x180a>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102ced:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102cf1:	0f 85 aa 00 00 00    	jne    f0102da1 <mem_init+0x1890>
f0102cf7:	c7 44 24 0c 18 7b 10 	movl   $0xf0107b18,0xc(%esp)
f0102cfe:	f0 
f0102cff:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102d06:	f0 
f0102d07:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102d0e:	00 
f0102d0f:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102d16:	e8 25 d3 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102d1b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102d20:	76 55                	jbe    f0102d77 <mem_init+0x1866>
				assert(pgdir[i] & PTE_P);
f0102d22:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102d25:	f6 c2 01             	test   $0x1,%dl
f0102d28:	75 24                	jne    f0102d4e <mem_init+0x183d>
f0102d2a:	c7 44 24 0c 18 7b 10 	movl   $0xf0107b18,0xc(%esp)
f0102d31:	f0 
f0102d32:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102d39:	f0 
f0102d3a:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0102d41:	00 
f0102d42:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102d49:	e8 f2 d2 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102d4e:	f6 c2 02             	test   $0x2,%dl
f0102d51:	75 4e                	jne    f0102da1 <mem_init+0x1890>
f0102d53:	c7 44 24 0c 29 7b 10 	movl   $0xf0107b29,0xc(%esp)
f0102d5a:	f0 
f0102d5b:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102d62:	f0 
f0102d63:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0102d6a:	00 
f0102d6b:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102d72:	e8 c9 d2 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102d77:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102d7b:	74 24                	je     f0102da1 <mem_init+0x1890>
f0102d7d:	c7 44 24 0c 3a 7b 10 	movl   $0xf0107b3a,0xc(%esp)
f0102d84:	f0 
f0102d85:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102d8c:	f0 
f0102d8d:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0102d94:	00 
f0102d95:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102d9c:	e8 9f d2 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102da1:	83 c0 01             	add    $0x1,%eax
f0102da4:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102da9:	0f 85 33 ff ff ff    	jne    f0102ce2 <mem_init+0x17d1>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102daf:	c7 04 24 44 77 10 f0 	movl   $0xf0107744,(%esp)
f0102db6:	e8 3b 0f 00 00       	call   f0103cf6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102dbb:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dc0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dc5:	77 20                	ja     f0102de7 <mem_init+0x18d6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dc7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dcb:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f0102dd2:	f0 
f0102dd3:	c7 44 24 04 f1 00 00 	movl   $0xf1,0x4(%esp)
f0102dda:	00 
f0102ddb:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102de2:	e8 59 d2 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102de7:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102dec:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102def:	b8 00 00 00 00       	mov    $0x0,%eax
f0102df4:	e8 ab de ff ff       	call   f0100ca4 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102df9:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102dfc:	83 e0 f3             	and    $0xfffffff3,%eax
f0102dff:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102e04:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102e07:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e0e:	e8 4c e3 ff ff       	call   f010115f <page_alloc>
f0102e13:	89 c3                	mov    %eax,%ebx
f0102e15:	85 c0                	test   %eax,%eax
f0102e17:	75 24                	jne    f0102e3d <mem_init+0x192c>
f0102e19:	c7 44 24 0c 3c 79 10 	movl   $0xf010793c,0xc(%esp)
f0102e20:	f0 
f0102e21:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102e28:	f0 
f0102e29:	c7 44 24 04 0b 04 00 	movl   $0x40b,0x4(%esp)
f0102e30:	00 
f0102e31:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102e38:	e8 03 d2 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e3d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e44:	e8 16 e3 ff ff       	call   f010115f <page_alloc>
f0102e49:	89 c7                	mov    %eax,%edi
f0102e4b:	85 c0                	test   %eax,%eax
f0102e4d:	75 24                	jne    f0102e73 <mem_init+0x1962>
f0102e4f:	c7 44 24 0c 52 79 10 	movl   $0xf0107952,0xc(%esp)
f0102e56:	f0 
f0102e57:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102e5e:	f0 
f0102e5f:	c7 44 24 04 0c 04 00 	movl   $0x40c,0x4(%esp)
f0102e66:	00 
f0102e67:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102e6e:	e8 cd d1 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102e73:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e7a:	e8 e0 e2 ff ff       	call   f010115f <page_alloc>
f0102e7f:	89 c6                	mov    %eax,%esi
f0102e81:	85 c0                	test   %eax,%eax
f0102e83:	75 24                	jne    f0102ea9 <mem_init+0x1998>
f0102e85:	c7 44 24 0c 68 79 10 	movl   $0xf0107968,0xc(%esp)
f0102e8c:	f0 
f0102e8d:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102e94:	f0 
f0102e95:	c7 44 24 04 0d 04 00 	movl   $0x40d,0x4(%esp)
f0102e9c:	00 
f0102e9d:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102ea4:	e8 97 d1 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102ea9:	89 1c 24             	mov    %ebx,(%esp)
f0102eac:	e8 32 e3 ff ff       	call   f01011e3 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102eb1:	89 f8                	mov    %edi,%eax
f0102eb3:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102eb9:	c1 f8 03             	sar    $0x3,%eax
f0102ebc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ebf:	89 c2                	mov    %eax,%edx
f0102ec1:	c1 ea 0c             	shr    $0xc,%edx
f0102ec4:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102eca:	72 20                	jb     f0102eec <mem_init+0x19db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ecc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ed0:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0102ed7:	f0 
f0102ed8:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102edf:	00 
f0102ee0:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f0102ee7:	e8 54 d1 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102eec:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ef3:	00 
f0102ef4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102efb:	00 
	return (void *)(pa + KERNBASE);
f0102efc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102f01:	89 04 24             	mov    %eax,(%esp)
f0102f04:	e8 8c 2e 00 00       	call   f0105d95 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f09:	89 f0                	mov    %esi,%eax
f0102f0b:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102f11:	c1 f8 03             	sar    $0x3,%eax
f0102f14:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f17:	89 c2                	mov    %eax,%edx
f0102f19:	c1 ea 0c             	shr    $0xc,%edx
f0102f1c:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102f22:	72 20                	jb     f0102f44 <mem_init+0x1a33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f24:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f28:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0102f2f:	f0 
f0102f30:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102f37:	00 
f0102f38:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f0102f3f:	e8 fc d0 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102f44:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102f4b:	00 
f0102f4c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102f53:	00 
	return (void *)(pa + KERNBASE);
f0102f54:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102f59:	89 04 24             	mov    %eax,(%esp)
f0102f5c:	e8 34 2e 00 00       	call   f0105d95 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102f61:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102f68:	00 
f0102f69:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102f70:	00 
f0102f71:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102f75:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102f7a:	89 04 24             	mov    %eax,(%esp)
f0102f7d:	e8 e5 e4 ff ff       	call   f0101467 <page_insert>
	assert(pp1->pp_ref == 1);
f0102f82:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102f87:	74 24                	je     f0102fad <mem_init+0x1a9c>
f0102f89:	c7 44 24 0c 39 7a 10 	movl   $0xf0107a39,0xc(%esp)
f0102f90:	f0 
f0102f91:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102f98:	f0 
f0102f99:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f0102fa0:	00 
f0102fa1:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102fa8:	e8 93 d0 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102fad:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102fb4:	01 01 01 
f0102fb7:	74 24                	je     f0102fdd <mem_init+0x1acc>
f0102fb9:	c7 44 24 0c 64 77 10 	movl   $0xf0107764,0xc(%esp)
f0102fc0:	f0 
f0102fc1:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0102fc8:	f0 
f0102fc9:	c7 44 24 04 13 04 00 	movl   $0x413,0x4(%esp)
f0102fd0:	00 
f0102fd1:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0102fd8:	e8 63 d0 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102fdd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102fe4:	00 
f0102fe5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102fec:	00 
f0102fed:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ff1:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102ff6:	89 04 24             	mov    %eax,(%esp)
f0102ff9:	e8 69 e4 ff ff       	call   f0101467 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ffe:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103005:	02 02 02 
f0103008:	74 24                	je     f010302e <mem_init+0x1b1d>
f010300a:	c7 44 24 0c 88 77 10 	movl   $0xf0107788,0xc(%esp)
f0103011:	f0 
f0103012:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0103019:	f0 
f010301a:	c7 44 24 04 15 04 00 	movl   $0x415,0x4(%esp)
f0103021:	00 
f0103022:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0103029:	e8 12 d0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010302e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103033:	74 24                	je     f0103059 <mem_init+0x1b48>
f0103035:	c7 44 24 0c 5b 7a 10 	movl   $0xf0107a5b,0xc(%esp)
f010303c:	f0 
f010303d:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0103044:	f0 
f0103045:	c7 44 24 04 16 04 00 	movl   $0x416,0x4(%esp)
f010304c:	00 
f010304d:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0103054:	e8 e7 cf ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0103059:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010305e:	74 24                	je     f0103084 <mem_init+0x1b73>
f0103060:	c7 44 24 0c a4 7a 10 	movl   $0xf0107aa4,0xc(%esp)
f0103067:	f0 
f0103068:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010306f:	f0 
f0103070:	c7 44 24 04 17 04 00 	movl   $0x417,0x4(%esp)
f0103077:	00 
f0103078:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f010307f:	e8 bc cf ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103084:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010308b:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010308e:	89 f0                	mov    %esi,%eax
f0103090:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0103096:	c1 f8 03             	sar    $0x3,%eax
f0103099:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010309c:	89 c2                	mov    %eax,%edx
f010309e:	c1 ea 0c             	shr    $0xc,%edx
f01030a1:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01030a7:	72 20                	jb     f01030c9 <mem_init+0x1bb8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01030a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030ad:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01030b4:	f0 
f01030b5:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01030bc:	00 
f01030bd:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f01030c4:	e8 77 cf ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01030c9:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01030d0:	03 03 03 
f01030d3:	74 24                	je     f01030f9 <mem_init+0x1be8>
f01030d5:	c7 44 24 0c ac 77 10 	movl   $0xf01077ac,0xc(%esp)
f01030dc:	f0 
f01030dd:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01030e4:	f0 
f01030e5:	c7 44 24 04 19 04 00 	movl   $0x419,0x4(%esp)
f01030ec:	00 
f01030ed:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01030f4:	e8 47 cf ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01030f9:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103100:	00 
f0103101:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0103106:	89 04 24             	mov    %eax,(%esp)
f0103109:	e8 09 e3 ff ff       	call   f0101417 <page_remove>
	assert(pp2->pp_ref == 0);
f010310e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0103113:	74 24                	je     f0103139 <mem_init+0x1c28>
f0103115:	c7 44 24 0c 93 7a 10 	movl   $0xf0107a93,0xc(%esp)
f010311c:	f0 
f010311d:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0103124:	f0 
f0103125:	c7 44 24 04 1b 04 00 	movl   $0x41b,0x4(%esp)
f010312c:	00 
f010312d:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0103134:	e8 07 cf ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103139:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010313e:	8b 08                	mov    (%eax),%ecx
f0103140:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0103146:	89 da                	mov    %ebx,%edx
f0103148:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f010314e:	c1 fa 03             	sar    $0x3,%edx
f0103151:	c1 e2 0c             	shl    $0xc,%edx
f0103154:	39 d1                	cmp    %edx,%ecx
f0103156:	74 24                	je     f010317c <mem_init+0x1c6b>
f0103158:	c7 44 24 0c 34 73 10 	movl   $0xf0107334,0xc(%esp)
f010315f:	f0 
f0103160:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0103167:	f0 
f0103168:	c7 44 24 04 1e 04 00 	movl   $0x41e,0x4(%esp)
f010316f:	00 
f0103170:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f0103177:	e8 c4 ce ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010317c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0103182:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103187:	74 24                	je     f01031ad <mem_init+0x1c9c>
f0103189:	c7 44 24 0c 4a 7a 10 	movl   $0xf0107a4a,0xc(%esp)
f0103190:	f0 
f0103191:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f0103198:	f0 
f0103199:	c7 44 24 04 20 04 00 	movl   $0x420,0x4(%esp)
f01031a0:	00 
f01031a1:	c7 04 24 39 78 10 f0 	movl   $0xf0107839,(%esp)
f01031a8:	e8 93 ce ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01031ad:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01031b3:	89 1c 24             	mov    %ebx,(%esp)
f01031b6:	e8 28 e0 ff ff       	call   f01011e3 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01031bb:	c7 04 24 d8 77 10 f0 	movl   $0xf01077d8,(%esp)
f01031c2:	e8 2f 0b 00 00       	call   f0103cf6 <cprintf>
f01031c7:	eb 4f                	jmp    f0103218 <mem_init+0x1d07>
	uint32_t kstacktop_i;
	for(; i < NCPU; i++){
		kstacktop_i = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (i + 1) + KSTKGAP;
		// panic("%x",percpu_kstacks[i]);
		// cprintf("%x\n",kstacktop_i);
		boot_map_region(kern_pgdir, kstacktop_i, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W|PTE_P);
f01031c9:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01031d0:	00 
f01031d1:	c7 04 24 00 c0 22 00 	movl   $0x22c000,(%esp)
f01031d8:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01031dd:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01031e2:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01031e7:	e8 19 e1 ff ff       	call   f0101305 <boot_map_region>
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	size_t i = 0;
	uint32_t kstacktop_i;
	for(; i < NCPU; i++){
f01031ec:	bb 01 00 00 00       	mov    $0x1,%ebx
f01031f1:	e9 b7 f7 ff ff       	jmp    f01029ad <mem_init+0x149c>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01031f6:	89 da                	mov    %ebx,%edx
f01031f8:	89 f8                	mov    %edi,%eax
f01031fa:	e8 91 d9 ff ff       	call   f0100b90 <check_va2pa>
f01031ff:	e9 09 f9 ff ff       	jmp    f0102b0d <mem_init+0x15fc>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0103204:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010320a:	89 f8                	mov    %edi,%eax
f010320c:	e8 7f d9 ff ff       	call   f0100b90 <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0103211:	89 da                	mov    %ebx,%edx
f0103213:	e9 96 f8 ff ff       	jmp    f0102aae <mem_init+0x159d>
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();

}
f0103218:	83 c4 3c             	add    $0x3c,%esp
f010321b:	5b                   	pop    %ebx
f010321c:	5e                   	pop    %esi
f010321d:	5f                   	pop    %edi
f010321e:	5d                   	pop    %ebp
f010321f:	c3                   	ret    

f0103220 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0103220:	55                   	push   %ebp
f0103221:	89 e5                	mov    %esp,%ebp
f0103223:	57                   	push   %edi
f0103224:	56                   	push   %esi
f0103225:	53                   	push   %ebx
f0103226:	83 ec 2c             	sub    $0x2c,%esp
f0103229:	8b 75 08             	mov    0x8(%ebp),%esi
f010322c:	8b 45 0c             	mov    0xc(%ebp),%eax
	// LAB 3: Your code here.
	pte_t *pte;
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);
f010322f:	89 c2                	mov    %eax,%edx
f0103231:	03 55 10             	add    0x10(%ebp),%edx
f0103234:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f010323a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0103240:	89 55 e4             	mov    %edx,-0x1c(%ebp)

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
f0103243:	39 d0                	cmp    %edx,%eax
f0103245:	73 5d                	jae    f01032a4 <user_mem_check+0x84>
		user_mem_check_addr = (uintptr_t)va; /* record the va */
f0103247:	89 c3                	mov    %eax,%ebx
f0103249:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
		if(user_mem_check_addr > ULIM) /* below the ULIM */
			return -E_FAULT;
		if((pte = pgdir_walk(env->env_pgdir,va,0)) == NULL) /* No creation, and the pte is null */
			return -E_FAULT;
		if(!(*pte & (perm|PTE_P))) /* No permission */
f010324e:	8b 7d 14             	mov    0x14(%ebp),%edi
f0103251:	83 cf 01             	or     $0x1,%edi
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
		user_mem_check_addr = (uintptr_t)va; /* record the va */
		if(user_mem_check_addr > ULIM) /* below the ULIM */
f0103254:	3d 00 00 80 ef       	cmp    $0xef800000,%eax
f0103259:	76 12                	jbe    f010326d <user_mem_check+0x4d>
f010325b:	eb 4e                	jmp    f01032ab <user_mem_check+0x8b>
	pte_t *pte;
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
		user_mem_check_addr = (uintptr_t)va; /* record the va */
f010325d:	89 c3                	mov    %eax,%ebx
f010325f:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
		if(user_mem_check_addr > ULIM) /* below the ULIM */
f0103264:	3d 00 00 80 ef       	cmp    $0xef800000,%eax
f0103269:	76 02                	jbe    f010326d <user_mem_check+0x4d>
f010326b:	eb 45                	jmp    f01032b2 <user_mem_check+0x92>
			return -E_FAULT;
		if((pte = pgdir_walk(env->env_pgdir,va,0)) == NULL) /* No creation, and the pte is null */
f010326d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0103274:	00 
f0103275:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103279:	8b 46 60             	mov    0x60(%esi),%eax
f010327c:	89 04 24             	mov    %eax,(%esp)
f010327f:	e8 9e df ff ff       	call   f0101222 <pgdir_walk>
f0103284:	85 c0                	test   %eax,%eax
f0103286:	74 31                	je     f01032b9 <user_mem_check+0x99>
			return -E_FAULT;
		if(!(*pte & (perm|PTE_P))) /* No permission */
f0103288:	85 38                	test   %edi,(%eax)
f010328a:	74 34                	je     f01032c0 <user_mem_check+0xa0>
			return -E_FAULT;
		va = ROUNDDOWN(va, PGSIZE);
f010328c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	// LAB 3: Your code here.
	pte_t *pte;
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
f0103292:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0103298:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010329b:	77 c0                	ja     f010325d <user_mem_check+0x3d>
			return -E_FAULT;
		if(!(*pte & (perm|PTE_P))) /* No permission */
			return -E_FAULT;
		va = ROUNDDOWN(va, PGSIZE);
	}
	return 0;
f010329d:	b8 00 00 00 00       	mov    $0x0,%eax
f01032a2:	eb 21                	jmp    f01032c5 <user_mem_check+0xa5>
f01032a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01032a9:	eb 1a                	jmp    f01032c5 <user_mem_check+0xa5>

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
		user_mem_check_addr = (uintptr_t)va; /* record the va */
		if(user_mem_check_addr > ULIM) /* below the ULIM */
			return -E_FAULT;
f01032ab:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01032b0:	eb 13                	jmp    f01032c5 <user_mem_check+0xa5>
f01032b2:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01032b7:	eb 0c                	jmp    f01032c5 <user_mem_check+0xa5>
		if((pte = pgdir_walk(env->env_pgdir,va,0)) == NULL) /* No creation, and the pte is null */
			return -E_FAULT;
f01032b9:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01032be:	eb 05                	jmp    f01032c5 <user_mem_check+0xa5>
		if(!(*pte & (perm|PTE_P))) /* No permission */
			return -E_FAULT;
f01032c0:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
		va = ROUNDDOWN(va, PGSIZE);
	}
	return 0;
}
f01032c5:	83 c4 2c             	add    $0x2c,%esp
f01032c8:	5b                   	pop    %ebx
f01032c9:	5e                   	pop    %esi
f01032ca:	5f                   	pop    %edi
f01032cb:	5d                   	pop    %ebp
f01032cc:	c3                   	ret    

f01032cd <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01032cd:	55                   	push   %ebp
f01032ce:	89 e5                	mov    %esp,%ebp
f01032d0:	53                   	push   %ebx
f01032d1:	83 ec 14             	sub    $0x14,%esp
f01032d4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01032d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01032da:	83 c8 04             	or     $0x4,%eax
f01032dd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032e1:	8b 45 10             	mov    0x10(%ebp),%eax
f01032e4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01032e8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032ef:	89 1c 24             	mov    %ebx,(%esp)
f01032f2:	e8 29 ff ff ff       	call   f0103220 <user_mem_check>
f01032f7:	85 c0                	test   %eax,%eax
f01032f9:	79 24                	jns    f010331f <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f01032fb:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f0103300:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103304:	8b 43 48             	mov    0x48(%ebx),%eax
f0103307:	89 44 24 04          	mov    %eax,0x4(%esp)
f010330b:	c7 04 24 04 78 10 f0 	movl   $0xf0107804,(%esp)
f0103312:	e8 df 09 00 00       	call   f0103cf6 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0103317:	89 1c 24             	mov    %ebx,(%esp)
f010331a:	e8 f9 06 00 00       	call   f0103a18 <env_destroy>
	}
}
f010331f:	83 c4 14             	add    $0x14,%esp
f0103322:	5b                   	pop    %ebx
f0103323:	5d                   	pop    %ebp
f0103324:	c3                   	ret    
f0103325:	66 90                	xchg   %ax,%ax
f0103327:	90                   	nop

f0103328 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103328:	55                   	push   %ebp
f0103329:	89 e5                	mov    %esp,%ebp
f010332b:	57                   	push   %edi
f010332c:	56                   	push   %esi
f010332d:	53                   	push   %ebx
f010332e:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	if(!len) /* If the len is zero panic immedatelly? or just return? */
f0103331:	85 c9                	test   %ecx,%ecx
f0103333:	75 1c                	jne    f0103351 <region_alloc+0x29>
		panic("Allocation failed!\n");
f0103335:	c7 44 24 08 48 7b 10 	movl   $0xf0107b48,0x8(%esp)
f010333c:	f0 
f010333d:	c7 44 24 04 2a 01 00 	movl   $0x12a,0x4(%esp)
f0103344:	00 
f0103345:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f010334c:	e8 ef cc ff ff       	call   f0100040 <_panic>
f0103351:	89 c7                	mov    %eax,%edi
	void* up_lim = ROUNDUP(va + len, PGSIZE);
f0103353:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010335a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	va = ROUNDDOWN(va, PGSIZE);
f0103360:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0103366:	89 d3                	mov    %edx,%ebx
	
	struct Page *p;
	for(;va < up_lim; va += PGSIZE){
f0103368:	39 d6                	cmp    %edx,%esi
f010336a:	76 71                	jbe    f01033dd <region_alloc+0xb5>
		if((p  = page_alloc(ALLOC_ZERO)) == NULL)
f010336c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103373:	e8 e7 dd ff ff       	call   f010115f <page_alloc>
f0103378:	85 c0                	test   %eax,%eax
f010337a:	75 1c                	jne    f0103398 <region_alloc+0x70>
			panic("Allocation failed!\n");
f010337c:	c7 44 24 08 48 7b 10 	movl   $0xf0107b48,0x8(%esp)
f0103383:	f0 
f0103384:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
f010338b:	00 
f010338c:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f0103393:	e8 a8 cc ff ff       	call   f0100040 <_panic>
		if(page_insert(e->env_pgdir, p, va, PTE_U|PTE_W) < 0)
f0103398:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010339f:	00 
f01033a0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01033a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033a8:	8b 47 60             	mov    0x60(%edi),%eax
f01033ab:	89 04 24             	mov    %eax,(%esp)
f01033ae:	e8 b4 e0 ff ff       	call   f0101467 <page_insert>
f01033b3:	85 c0                	test   %eax,%eax
f01033b5:	79 1c                	jns    f01033d3 <region_alloc+0xab>
			panic("Allocation failed!\n");
f01033b7:	c7 44 24 08 48 7b 10 	movl   $0xf0107b48,0x8(%esp)
f01033be:	f0 
f01033bf:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
f01033c6:	00 
f01033c7:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f01033ce:	e8 6d cc ff ff       	call   f0100040 <_panic>
		panic("Allocation failed!\n");
	void* up_lim = ROUNDUP(va + len, PGSIZE);
	va = ROUNDDOWN(va, PGSIZE);
	
	struct Page *p;
	for(;va < up_lim; va += PGSIZE){
f01033d3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01033d9:	39 de                	cmp    %ebx,%esi
f01033db:	77 8f                	ja     f010336c <region_alloc+0x44>
			panic("Allocation failed!\n");
		if(page_insert(e->env_pgdir, p, va, PTE_U|PTE_W) < 0)
			panic("Allocation failed!\n");
	}

}
f01033dd:	83 c4 1c             	add    $0x1c,%esp
f01033e0:	5b                   	pop    %ebx
f01033e1:	5e                   	pop    %esi
f01033e2:	5f                   	pop    %edi
f01033e3:	5d                   	pop    %ebp
f01033e4:	c3                   	ret    

f01033e5 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01033e5:	55                   	push   %ebp
f01033e6:	89 e5                	mov    %esp,%ebp
f01033e8:	83 ec 08             	sub    $0x8,%esp
f01033eb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01033ee:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01033f1:	8b 45 08             	mov    0x8(%ebp),%eax
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01033f4:	85 c0                	test   %eax,%eax
f01033f6:	75 1a                	jne    f0103412 <envid2env+0x2d>
		*env_store = curenv;
f01033f8:	e8 3f 30 00 00       	call   f010643c <cpunum>
f01033fd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103400:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103406:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103409:	89 02                	mov    %eax,(%edx)
		return 0;
f010340b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103410:	eb 72                	jmp    f0103484 <envid2env+0x9f>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103412:	89 c3                	mov    %eax,%ebx
f0103414:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010341a:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f010341d:	03 1d 48 a2 22 f0    	add    0xf022a248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103423:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103427:	74 05                	je     f010342e <envid2env+0x49>
f0103429:	39 43 48             	cmp    %eax,0x48(%ebx)
f010342c:	74 10                	je     f010343e <envid2env+0x59>
		*env_store = 0;
f010342e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103431:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103437:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010343c:	eb 46                	jmp    f0103484 <envid2env+0x9f>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010343e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103442:	74 36                	je     f010347a <envid2env+0x95>
f0103444:	e8 f3 2f 00 00       	call   f010643c <cpunum>
f0103449:	6b c0 74             	imul   $0x74,%eax,%eax
f010344c:	39 98 28 b0 22 f0    	cmp    %ebx,-0xfdd4fd8(%eax)
f0103452:	74 26                	je     f010347a <envid2env+0x95>
f0103454:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103457:	e8 e0 2f 00 00       	call   f010643c <cpunum>
f010345c:	6b c0 74             	imul   $0x74,%eax,%eax
f010345f:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103465:	3b 70 48             	cmp    0x48(%eax),%esi
f0103468:	74 10                	je     f010347a <envid2env+0x95>
		*env_store = 0;
f010346a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010346d:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
		return -E_BAD_ENV;
f0103473:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103478:	eb 0a                	jmp    f0103484 <envid2env+0x9f>
	}

	*env_store = e;
f010347a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010347d:	89 18                	mov    %ebx,(%eax)
	return 0;
f010347f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103484:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0103487:	8b 75 fc             	mov    -0x4(%ebp),%esi
f010348a:	89 ec                	mov    %ebp,%esp
f010348c:	5d                   	pop    %ebp
f010348d:	c3                   	ret    

f010348e <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010348e:	55                   	push   %ebp
f010348f:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103491:	b8 00 13 12 f0       	mov    $0xf0121300,%eax
f0103496:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103499:	b8 23 00 00 00       	mov    $0x23,%eax
f010349e:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01034a0:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01034a2:	b0 10                	mov    $0x10,%al
f01034a4:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01034a6:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01034a8:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01034aa:	ea b1 34 10 f0 08 00 	ljmp   $0x8,$0xf01034b1
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01034b1:	b0 00                	mov    $0x0,%al
f01034b3:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01034b6:	5d                   	pop    %ebp
f01034b7:	c3                   	ret    

f01034b8 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01034b8:	55                   	push   %ebp
f01034b9:	89 e5                	mov    %esp,%ebp
f01034bb:	56                   	push   %esi
f01034bc:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV-1; i >=0 ; i--){
		envs[i].env_link = env_free_list;
f01034bd:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
f01034c3:	8b 0d 4c a2 22 f0    	mov    0xf022a24c,%ecx
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
f01034c9:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f01034cf:	ba 00 04 00 00       	mov    $0x400,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV-1; i >=0 ; i--){
		envs[i].env_link = env_free_list;
f01034d4:	89 c3                	mov    %eax,%ebx
f01034d6:	89 48 44             	mov    %ecx,0x44(%eax)
		envs[i].env_id = 0;	
f01034d9:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f01034e0:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f01034e7:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f01034ea:	89 d9                	mov    %ebx,%ecx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV-1; i >=0 ; i--){
f01034ec:	83 ea 01             	sub    $0x1,%edx
f01034ef:	75 e3                	jne    f01034d4 <env_init+0x1c>
f01034f1:	89 35 4c a2 22 f0    	mov    %esi,0xf022a24c
		env_free_list = &envs[i];
		
	}
//	panic("");
	// Per-CPU part of the initialization
	env_init_percpu();
f01034f7:	e8 92 ff ff ff       	call   f010348e <env_init_percpu>
}
f01034fc:	5b                   	pop    %ebx
f01034fd:	5e                   	pop    %esi
f01034fe:	5d                   	pop    %ebp
f01034ff:	c3                   	ret    

f0103500 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103500:	55                   	push   %ebp
f0103501:	89 e5                	mov    %esp,%ebp
f0103503:	56                   	push   %esi
f0103504:	53                   	push   %ebx
f0103505:	83 ec 10             	sub    $0x10,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103508:	8b 1d 4c a2 22 f0    	mov    0xf022a24c,%ebx
f010350e:	85 db                	test   %ebx,%ebx
f0103510:	0f 84 ae 01 00 00    	je     f01036c4 <env_alloc+0x1c4>
{
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103516:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010351d:	e8 3d dc ff ff       	call   f010115f <page_alloc>
f0103522:	89 c6                	mov    %eax,%esi
f0103524:	85 c0                	test   %eax,%eax
f0103526:	0f 84 9f 01 00 00    	je     f01036cb <env_alloc+0x1cb>
f010352c:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0103532:	c1 f8 03             	sar    $0x3,%eax
f0103535:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103538:	89 c2                	mov    %eax,%edx
f010353a:	c1 ea 0c             	shr    $0xc,%edx
f010353d:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0103543:	72 20                	jb     f0103565 <env_alloc+0x65>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103545:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103549:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0103550:	f0 
f0103551:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103558:	00 
f0103559:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f0103560:	e8 db ca ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103565:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	/* e->env_pgdir is a pte_t* */
	e -> env_pgdir = page2kva(p);
f010356a:	89 43 60             	mov    %eax,0x60(%ebx)

	memmove(e -> env_pgdir , kern_pgdir, PGSIZE);
f010356d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103574:	00 
f0103575:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f010357b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010357f:	89 04 24             	mov    %eax,(%esp)
f0103582:	e8 6c 28 00 00       	call   f0105df3 <memmove>
	memset(e -> env_pgdir, 0 , PDX(UTOP)*sizeof(pde_t));
f0103587:	c7 44 24 08 ec 0e 00 	movl   $0xeec,0x8(%esp)
f010358e:	00 
f010358f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103596:	00 
f0103597:	8b 43 60             	mov    0x60(%ebx),%eax
f010359a:	89 04 24             	mov    %eax,(%esp)
f010359d:	e8 f3 27 00 00       	call   f0105d95 <memset>

	p -> pp_ref++;
f01035a2:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01035a7:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01035aa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01035af:	77 20                	ja     f01035d1 <env_alloc+0xd1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035b5:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f01035bc:	f0 
f01035bd:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
f01035c4:	00 
f01035c5:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f01035cc:	e8 6f ca ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01035d1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01035d7:	83 ca 05             	or     $0x5,%edx
f01035da:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01035e0:	8b 43 48             	mov    0x48(%ebx),%eax
f01035e3:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01035e8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01035ed:	ba 00 10 00 00       	mov    $0x1000,%edx
f01035f2:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01035f5:	89 da                	mov    %ebx,%edx
f01035f7:	2b 15 48 a2 22 f0    	sub    0xf022a248,%edx
f01035fd:	c1 fa 02             	sar    $0x2,%edx
f0103600:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103606:	09 d0                	or     %edx,%eax
f0103608:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f010360b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010360e:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103611:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103618:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010361f:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103626:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f010362d:	00 
f010362e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103635:	00 
f0103636:	89 1c 24             	mov    %ebx,(%esp)
f0103639:	e8 57 27 00 00       	call   f0105d95 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010363e:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103644:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010364a:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103650:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103657:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;
f010365d:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103664:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f010366b:	c7 43 68 00 00 00 00 	movl   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103672:	8b 43 44             	mov    0x44(%ebx),%eax
f0103675:	a3 4c a2 22 f0       	mov    %eax,0xf022a24c
	*newenv_store = e;
f010367a:	8b 45 08             	mov    0x8(%ebp),%eax
f010367d:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010367f:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103682:	e8 b5 2d 00 00       	call   f010643c <cpunum>
f0103687:	6b c0 74             	imul   $0x74,%eax,%eax
f010368a:	ba 00 00 00 00       	mov    $0x0,%edx
f010368f:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103696:	74 11                	je     f01036a9 <env_alloc+0x1a9>
f0103698:	e8 9f 2d 00 00       	call   f010643c <cpunum>
f010369d:	6b c0 74             	imul   $0x74,%eax,%eax
f01036a0:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01036a6:	8b 50 48             	mov    0x48(%eax),%edx
f01036a9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036ad:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036b1:	c7 04 24 67 7b 10 f0 	movl   $0xf0107b67,(%esp)
f01036b8:	e8 39 06 00 00       	call   f0103cf6 <cprintf>
	return 0;
f01036bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01036c2:	eb 0c                	jmp    f01036d0 <env_alloc+0x1d0>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01036c4:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01036c9:	eb 05                	jmp    f01036d0 <env_alloc+0x1d0>
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01036cb:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01036d0:	83 c4 10             	add    $0x10,%esp
f01036d3:	5b                   	pop    %ebx
f01036d4:	5e                   	pop    %esi
f01036d5:	5d                   	pop    %ebp
f01036d6:	c3                   	ret    

f01036d7 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size, enum EnvType type)
{
f01036d7:	55                   	push   %ebp
f01036d8:	89 e5                	mov    %esp,%ebp
f01036da:	57                   	push   %edi
f01036db:	56                   	push   %esi
f01036dc:	53                   	push   %ebx
f01036dd:	83 ec 3c             	sub    $0x3c,%esp
f01036e0:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;

	if((r = env_alloc(&e, 0)) < 0)
f01036e3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01036ea:	00 
f01036eb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01036ee:	89 04 24             	mov    %eax,(%esp)
f01036f1:	e8 0a fe ff ff       	call   f0103500 <env_alloc>
f01036f6:	85 c0                	test   %eax,%eax
f01036f8:	79 20                	jns    f010371a <env_create+0x43>
		panic("env alloc failed! %e\n",r);
f01036fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036fe:	c7 44 24 08 7c 7b 10 	movl   $0xf0107b7c,0x8(%esp)
f0103705:	f0 
f0103706:	c7 44 24 04 a3 01 00 	movl   $0x1a3,0x4(%esp)
f010370d:	00 
f010370e:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f0103715:	e8 26 c9 ff ff       	call   f0100040 <_panic>
	/* load_icode(struct Env *e, uint8_t *binary, size_t size) */
	load_icode(e, binary, size);
f010371a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010371d:	89 45 d4             	mov    %eax,-0x2c(%ebp)

static __inline uint32_t
rcr3(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr3,%0" : "=r" (val));
f0103720:	0f 20 da             	mov    %cr3,%edx
f0103723:	89 55 d0             	mov    %edx,-0x30(%ebp)
	struct Proghdr *ph, *eph; /* see inc/elf.h */
	struct Elf *ELFHDR = (struct Elf *)binary;
	uint32_t cr3 = rcr3();

	/* just copy from boot/main.c */
	if (ELFHDR->e_magic != ELF_MAGIC)
f0103726:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010372c:	74 1c                	je     f010374a <env_create+0x73>
		panic("Invalid ELF!\n");
f010372e:	c7 44 24 08 92 7b 10 	movl   $0xf0107b92,0x8(%esp)
f0103735:	f0 
f0103736:	c7 44 24 04 74 01 00 	movl   $0x174,0x4(%esp)
f010373d:	00 
f010373e:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f0103745:	e8 f6 c8 ff ff       	call   f0100040 <_panic>
	lcr3(PADDR(e -> env_pgdir));
f010374a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010374d:	8b 42 60             	mov    0x60(%edx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103750:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103755:	77 20                	ja     f0103777 <env_create+0xa0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103757:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010375b:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f0103762:	f0 
f0103763:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
f010376a:	00 
f010376b:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f0103772:	e8 c9 c8 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103777:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010377c:	0f 22 d8             	mov    %eax,%cr3
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f010377f:	89 fb                	mov    %edi,%ebx
f0103781:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0103784:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103788:	c1 e6 05             	shl    $0x5,%esi
f010378b:	01 de                	add    %ebx,%esi

	for (; ph < eph; ph++){
f010378d:	39 f3                	cmp    %esi,%ebx
f010378f:	73 4f                	jae    f01037e0 <env_create+0x109>
		// p_pa is the load address of this segment (as well
		// as the physical address)
		if( ph->p_type == ELF_PROG_LOAD ){
f0103791:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103794:	75 43                	jne    f01037d9 <env_create+0x102>
			/* alloc p_memsz physical memory for e*/
			region_alloc(e, (void *)ph -> p_va, ph -> p_memsz); 
f0103796:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103799:	8b 53 08             	mov    0x8(%ebx),%edx
f010379c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010379f:	e8 84 fb ff ff       	call   f0103328 <region_alloc>
			/* set zero filled */
			//panic("%x", ph);
			memset((void *)ph->p_va, 0x0 , ph->p_memsz);
f01037a4:	8b 43 14             	mov    0x14(%ebx),%eax
f01037a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01037ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01037b2:	00 
f01037b3:	8b 43 08             	mov    0x8(%ebx),%eax
f01037b6:	89 04 24             	mov    %eax,(%esp)
f01037b9:	e8 d7 25 00 00       	call   f0105d95 <memset>
			/* inc/string.h : void * memmove(void *dst, const void *src, size_t len); */
			memmove((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f01037be:	8b 43 10             	mov    0x10(%ebx),%eax
f01037c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01037c5:	89 f8                	mov    %edi,%eax
f01037c7:	03 43 04             	add    0x4(%ebx),%eax
f01037ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037ce:	8b 43 08             	mov    0x8(%ebx),%eax
f01037d1:	89 04 24             	mov    %eax,(%esp)
f01037d4:	e8 1a 26 00 00       	call   f0105df3 <memmove>
		panic("Invalid ELF!\n");
	lcr3(PADDR(e -> env_pgdir));
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;

	for (; ph < eph; ph++){
f01037d9:	83 c3 20             	add    $0x20,%ebx
f01037dc:	39 de                	cmp    %ebx,%esi
f01037de:	77 b1                	ja     f0103791 <env_create+0xba>
		}

	}
	//((void (*)(void)) (ELFHDR->e_entry))();

	e -> env_tf.tf_eip = ELFHDR -> e_entry;
f01037e0:	8b 47 18             	mov    0x18(%edi),%eax
f01037e3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01037e6:	89 42 30             	mov    %eax,0x30(%edx)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
f01037e9:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01037ee:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01037f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01037f6:	e8 2d fb ff ff       	call   f0103328 <region_alloc>
f01037fb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01037fe:	0f 22 d8             	mov    %eax,%cr3

	if((r = env_alloc(&e, 0)) < 0)
		panic("env alloc failed! %e\n",r);
	/* load_icode(struct Env *e, uint8_t *binary, size_t size) */
	load_icode(e, binary, size);
	e -> env_type = type;
f0103801:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103804:	8b 55 10             	mov    0x10(%ebp),%edx
f0103807:	89 50 50             	mov    %edx,0x50(%eax)
}
f010380a:	83 c4 3c             	add    $0x3c,%esp
f010380d:	5b                   	pop    %ebx
f010380e:	5e                   	pop    %esi
f010380f:	5f                   	pop    %edi
f0103810:	5d                   	pop    %ebp
f0103811:	c3                   	ret    

f0103812 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103812:	55                   	push   %ebp
f0103813:	89 e5                	mov    %esp,%ebp
f0103815:	57                   	push   %edi
f0103816:	56                   	push   %esi
f0103817:	53                   	push   %ebx
f0103818:	83 ec 2c             	sub    $0x2c,%esp
f010381b:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010381e:	e8 19 2c 00 00       	call   f010643c <cpunum>
f0103823:	6b c0 74             	imul   $0x74,%eax,%eax
f0103826:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f010382c:	75 34                	jne    f0103862 <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f010382e:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103833:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103838:	77 20                	ja     f010385a <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010383a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010383e:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f0103845:	f0 
f0103846:	c7 44 24 04 b7 01 00 	movl   $0x1b7,0x4(%esp)
f010384d:	00 
f010384e:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f0103855:	e8 e6 c7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010385a:	05 00 00 00 10       	add    $0x10000000,%eax
f010385f:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103862:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103865:	e8 d2 2b 00 00       	call   f010643c <cpunum>
f010386a:	6b d0 74             	imul   $0x74,%eax,%edx
f010386d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103872:	83 ba 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%edx)
f0103879:	74 11                	je     f010388c <env_free+0x7a>
f010387b:	e8 bc 2b 00 00       	call   f010643c <cpunum>
f0103880:	6b c0 74             	imul   $0x74,%eax,%eax
f0103883:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103889:	8b 40 48             	mov    0x48(%eax),%eax
f010388c:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103890:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103894:	c7 04 24 a0 7b 10 f0 	movl   $0xf0107ba0,(%esp)
f010389b:	e8 56 04 00 00       	call   f0103cf6 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01038a0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
f01038a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01038aa:	c1 e0 02             	shl    $0x2,%eax
f01038ad:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01038b0:	8b 47 60             	mov    0x60(%edi),%eax
f01038b3:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01038b6:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01038b9:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01038bf:	0f 84 b7 00 00 00    	je     f010397c <env_free+0x16a>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01038c5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01038cb:	89 f0                	mov    %esi,%eax
f01038cd:	c1 e8 0c             	shr    $0xc,%eax
f01038d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01038d3:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01038d9:	72 20                	jb     f01038fb <env_free+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01038db:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01038df:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01038e6:	f0 
f01038e7:	c7 44 24 04 c6 01 00 	movl   $0x1c6,0x4(%esp)
f01038ee:	00 
f01038ef:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f01038f6:	e8 45 c7 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01038fb:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01038fe:	c1 e2 16             	shl    $0x16,%edx
f0103901:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103904:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103909:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103910:	01 
f0103911:	74 17                	je     f010392a <env_free+0x118>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103913:	89 d8                	mov    %ebx,%eax
f0103915:	c1 e0 0c             	shl    $0xc,%eax
f0103918:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010391b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010391f:	8b 47 60             	mov    0x60(%edi),%eax
f0103922:	89 04 24             	mov    %eax,(%esp)
f0103925:	e8 ed da ff ff       	call   f0101417 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010392a:	83 c3 01             	add    $0x1,%ebx
f010392d:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103933:	75 d4                	jne    f0103909 <env_free+0xf7>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103935:	8b 47 60             	mov    0x60(%edi),%eax
f0103938:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010393b:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103942:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103945:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010394b:	72 1c                	jb     f0103969 <env_free+0x157>
		panic("pa2page called with invalid pa");
f010394d:	c7 44 24 08 00 72 10 	movl   $0xf0107200,0x8(%esp)
f0103954:	f0 
f0103955:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010395c:	00 
f010395d:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f0103964:	e8 d7 c6 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103969:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f010396e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103971:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103974:	89 04 24             	mov    %eax,(%esp)
f0103977:	e8 83 d8 ff ff       	call   f01011ff <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010397c:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103980:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103987:	0f 85 1a ff ff ff    	jne    f01038a7 <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010398d:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103990:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103995:	77 20                	ja     f01039b7 <env_free+0x1a5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103997:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010399b:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f01039a2:	f0 
f01039a3:	c7 44 24 04 d4 01 00 	movl   $0x1d4,0x4(%esp)
f01039aa:	00 
f01039ab:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f01039b2:	e8 89 c6 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f01039b7:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f01039be:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01039c3:	c1 e8 0c             	shr    $0xc,%eax
f01039c6:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01039cc:	72 1c                	jb     f01039ea <env_free+0x1d8>
		panic("pa2page called with invalid pa");
f01039ce:	c7 44 24 08 00 72 10 	movl   $0xf0107200,0x8(%esp)
f01039d5:	f0 
f01039d6:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01039dd:	00 
f01039de:	c7 04 24 5a 78 10 f0 	movl   $0xf010785a,(%esp)
f01039e5:	e8 56 c6 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01039ea:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f01039f0:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f01039f3:	89 04 24             	mov    %eax,(%esp)
f01039f6:	e8 04 d8 ff ff       	call   f01011ff <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01039fb:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103a02:	a1 4c a2 22 f0       	mov    0xf022a24c,%eax
f0103a07:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103a0a:	89 3d 4c a2 22 f0    	mov    %edi,0xf022a24c
}
f0103a10:	83 c4 2c             	add    $0x2c,%esp
f0103a13:	5b                   	pop    %ebx
f0103a14:	5e                   	pop    %esi
f0103a15:	5f                   	pop    %edi
f0103a16:	5d                   	pop    %ebp
f0103a17:	c3                   	ret    

f0103a18 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103a18:	55                   	push   %ebp
f0103a19:	89 e5                	mov    %esp,%ebp
f0103a1b:	53                   	push   %ebx
f0103a1c:	83 ec 14             	sub    $0x14,%esp
f0103a1f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103a22:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103a26:	75 19                	jne    f0103a41 <env_destroy+0x29>
f0103a28:	e8 0f 2a 00 00       	call   f010643c <cpunum>
f0103a2d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a30:	39 98 28 b0 22 f0    	cmp    %ebx,-0xfdd4fd8(%eax)
f0103a36:	74 09                	je     f0103a41 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103a38:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103a3f:	eb 2f                	jmp    f0103a70 <env_destroy+0x58>
	}

	env_free(e);
f0103a41:	89 1c 24             	mov    %ebx,(%esp)
f0103a44:	e8 c9 fd ff ff       	call   f0103812 <env_free>

	if (curenv == e) {
f0103a49:	e8 ee 29 00 00       	call   f010643c <cpunum>
f0103a4e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a51:	39 98 28 b0 22 f0    	cmp    %ebx,-0xfdd4fd8(%eax)
f0103a57:	75 17                	jne    f0103a70 <env_destroy+0x58>
		curenv = NULL;
f0103a59:	e8 de 29 00 00       	call   f010643c <cpunum>
f0103a5e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a61:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103a68:	00 00 00 
		sched_yield();
f0103a6b:	e8 88 0e 00 00       	call   f01048f8 <sched_yield>
	}
}
f0103a70:	83 c4 14             	add    $0x14,%esp
f0103a73:	5b                   	pop    %ebx
f0103a74:	5d                   	pop    %ebp
f0103a75:	c3                   	ret    

f0103a76 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103a76:	55                   	push   %ebp
f0103a77:	89 e5                	mov    %esp,%ebp
f0103a79:	53                   	push   %ebx
f0103a7a:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103a7d:	e8 ba 29 00 00       	call   f010643c <cpunum>
f0103a82:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a85:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f0103a8b:	e8 ac 29 00 00       	call   f010643c <cpunum>
f0103a90:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103a93:	8b 65 08             	mov    0x8(%ebp),%esp
f0103a96:	61                   	popa   
f0103a97:	07                   	pop    %es
f0103a98:	1f                   	pop    %ds
f0103a99:	83 c4 08             	add    $0x8,%esp
f0103a9c:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103a9d:	c7 44 24 08 b6 7b 10 	movl   $0xf0107bb6,0x8(%esp)
f0103aa4:	f0 
f0103aa5:	c7 44 24 04 0a 02 00 	movl   $0x20a,0x4(%esp)
f0103aac:	00 
f0103aad:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f0103ab4:	e8 87 c5 ff ff       	call   f0100040 <_panic>

f0103ab9 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103ab9:	55                   	push   %ebp
f0103aba:	89 e5                	mov    %esp,%ebp
f0103abc:	53                   	push   %ebx
f0103abd:	83 ec 14             	sub    $0x14,%esp
f0103ac0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL  && curenv->env_status == ENV_RUNNING)
f0103ac3:	e8 74 29 00 00       	call   f010643c <cpunum>
f0103ac8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103acb:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103ad2:	74 29                	je     f0103afd <env_run+0x44>
f0103ad4:	e8 63 29 00 00       	call   f010643c <cpunum>
f0103ad9:	6b c0 74             	imul   $0x74,%eax,%eax
f0103adc:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103ae2:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103ae6:	75 15                	jne    f0103afd <env_run+0x44>
		curenv -> env_status = ENV_RUNNABLE;
f0103ae8:	e8 4f 29 00 00       	call   f010643c <cpunum>
f0103aed:	6b c0 74             	imul   $0x74,%eax,%eax
f0103af0:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103af6:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)

	curenv = e;
f0103afd:	e8 3a 29 00 00       	call   f010643c <cpunum>
f0103b02:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b05:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	curenv -> env_status = ENV_RUNNING;
f0103b0b:	e8 2c 29 00 00       	call   f010643c <cpunum>
f0103b10:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b13:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103b19:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv -> env_runs++;
f0103b20:	e8 17 29 00 00       	call   f010643c <cpunum>
f0103b25:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b28:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103b2e:	83 40 58 01          	addl   $0x1,0x58(%eax)
	//cprintf("cpu %d curenv.pgdir: %x\n", cpunum(), curenv -> env_pgdir);
	lcr3(PADDR(curenv -> env_pgdir));
f0103b32:	e8 05 29 00 00       	call   f010643c <cpunum>
f0103b37:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b3a:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103b40:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103b43:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b48:	77 20                	ja     f0103b6a <env_run+0xb1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b4a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b4e:	c7 44 24 08 c4 6b 10 	movl   $0xf0106bc4,0x8(%esp)
f0103b55:	f0 
f0103b56:	c7 44 24 04 2f 02 00 	movl   $0x22f,0x4(%esp)
f0103b5d:	00 
f0103b5e:	c7 04 24 5c 7b 10 f0 	movl   $0xf0107b5c,(%esp)
f0103b65:	e8 d6 c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103b6a:	05 00 00 00 10       	add    $0x10000000,%eax
f0103b6f:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103b72:	c7 04 24 a0 13 12 f0 	movl   $0xf01213a0,(%esp)
f0103b79:	e8 27 2c 00 00       	call   f01067a5 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103b7e:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&(e -> env_tf));
f0103b80:	89 1c 24             	mov    %ebx,(%esp)
f0103b83:	e8 ee fe ff ff       	call   f0103a76 <env_pop_tf>

f0103b88 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103b88:	55                   	push   %ebp
f0103b89:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103b8b:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103b8f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103b94:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103b95:	b2 71                	mov    $0x71,%dl
f0103b97:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103b98:	0f b6 c0             	movzbl %al,%eax
}
f0103b9b:	5d                   	pop    %ebp
f0103b9c:	c3                   	ret    

f0103b9d <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103b9d:	55                   	push   %ebp
f0103b9e:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103ba0:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103ba4:	ba 70 00 00 00       	mov    $0x70,%edx
f0103ba9:	ee                   	out    %al,(%dx)
f0103baa:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0103bae:	b2 71                	mov    $0x71,%dl
f0103bb0:	ee                   	out    %al,(%dx)
f0103bb1:	5d                   	pop    %ebp
f0103bb2:	c3                   	ret    
f0103bb3:	90                   	nop

f0103bb4 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103bb4:	55                   	push   %ebp
f0103bb5:	89 e5                	mov    %esp,%ebp
f0103bb7:	56                   	push   %esi
f0103bb8:	53                   	push   %ebx
f0103bb9:	83 ec 10             	sub    $0x10,%esp
f0103bbc:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103bbf:	66 a3 88 13 12 f0    	mov    %ax,0xf0121388
	if (!didinit)
f0103bc5:	83 3d 50 a2 22 f0 00 	cmpl   $0x0,0xf022a250
f0103bcc:	74 4e                	je     f0103c1c <irq_setmask_8259A+0x68>
f0103bce:	89 c6                	mov    %eax,%esi
f0103bd0:	ba 21 00 00 00       	mov    $0x21,%edx
f0103bd5:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103bd6:	66 c1 e8 08          	shr    $0x8,%ax
f0103bda:	b2 a1                	mov    $0xa1,%dl
f0103bdc:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103bdd:	c7 04 24 c2 7b 10 f0 	movl   $0xf0107bc2,(%esp)
f0103be4:	e8 0d 01 00 00       	call   f0103cf6 <cprintf>
	for (i = 0; i < 16; i++)
f0103be9:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103bee:	0f b7 f6             	movzwl %si,%esi
f0103bf1:	f7 d6                	not    %esi
f0103bf3:	0f a3 de             	bt     %ebx,%esi
f0103bf6:	73 10                	jae    f0103c08 <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0103bf8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103bfc:	c7 04 24 cb 80 10 f0 	movl   $0xf01080cb,(%esp)
f0103c03:	e8 ee 00 00 00       	call   f0103cf6 <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103c08:	83 c3 01             	add    $0x1,%ebx
f0103c0b:	83 fb 10             	cmp    $0x10,%ebx
f0103c0e:	75 e3                	jne    f0103bf3 <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103c10:	c7 04 24 58 78 10 f0 	movl   $0xf0107858,(%esp)
f0103c17:	e8 da 00 00 00       	call   f0103cf6 <cprintf>
}
f0103c1c:	83 c4 10             	add    $0x10,%esp
f0103c1f:	5b                   	pop    %ebx
f0103c20:	5e                   	pop    %esi
f0103c21:	5d                   	pop    %ebp
f0103c22:	c3                   	ret    

f0103c23 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103c23:	c7 05 50 a2 22 f0 01 	movl   $0x1,0xf022a250
f0103c2a:	00 00 00 
f0103c2d:	ba 21 00 00 00       	mov    $0x21,%edx
f0103c32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c37:	ee                   	out    %al,(%dx)
f0103c38:	b2 a1                	mov    $0xa1,%dl
f0103c3a:	ee                   	out    %al,(%dx)
f0103c3b:	b2 20                	mov    $0x20,%dl
f0103c3d:	b8 11 00 00 00       	mov    $0x11,%eax
f0103c42:	ee                   	out    %al,(%dx)
f0103c43:	b2 21                	mov    $0x21,%dl
f0103c45:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c4a:	ee                   	out    %al,(%dx)
f0103c4b:	b8 04 00 00 00       	mov    $0x4,%eax
f0103c50:	ee                   	out    %al,(%dx)
f0103c51:	b8 03 00 00 00       	mov    $0x3,%eax
f0103c56:	ee                   	out    %al,(%dx)
f0103c57:	b2 a0                	mov    $0xa0,%dl
f0103c59:	b8 11 00 00 00       	mov    $0x11,%eax
f0103c5e:	ee                   	out    %al,(%dx)
f0103c5f:	b2 a1                	mov    $0xa1,%dl
f0103c61:	b8 28 00 00 00       	mov    $0x28,%eax
f0103c66:	ee                   	out    %al,(%dx)
f0103c67:	b8 02 00 00 00       	mov    $0x2,%eax
f0103c6c:	ee                   	out    %al,(%dx)
f0103c6d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c72:	ee                   	out    %al,(%dx)
f0103c73:	b2 20                	mov    $0x20,%dl
f0103c75:	b8 68 00 00 00       	mov    $0x68,%eax
f0103c7a:	ee                   	out    %al,(%dx)
f0103c7b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c80:	ee                   	out    %al,(%dx)
f0103c81:	b2 a0                	mov    $0xa0,%dl
f0103c83:	b8 68 00 00 00       	mov    $0x68,%eax
f0103c88:	ee                   	out    %al,(%dx)
f0103c89:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c8e:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103c8f:	0f b7 05 88 13 12 f0 	movzwl 0xf0121388,%eax
f0103c96:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103c9a:	74 12                	je     f0103cae <pic_init+0x8b>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103c9c:	55                   	push   %ebp
f0103c9d:	89 e5                	mov    %esp,%ebp
f0103c9f:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103ca2:	0f b7 c0             	movzwl %ax,%eax
f0103ca5:	89 04 24             	mov    %eax,(%esp)
f0103ca8:	e8 07 ff ff ff       	call   f0103bb4 <irq_setmask_8259A>
}
f0103cad:	c9                   	leave  
f0103cae:	f3 c3                	repz ret 

f0103cb0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103cb0:	55                   	push   %ebp
f0103cb1:	89 e5                	mov    %esp,%ebp
f0103cb3:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103cb6:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cb9:	89 04 24             	mov    %eax,(%esp)
f0103cbc:	e8 14 cb ff ff       	call   f01007d5 <cputchar>
	*cnt++;
}
f0103cc1:	c9                   	leave  
f0103cc2:	c3                   	ret    

f0103cc3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103cc3:	55                   	push   %ebp
f0103cc4:	89 e5                	mov    %esp,%ebp
f0103cc6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103cc9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103cd0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103cd3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103cd7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cda:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103cde:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103ce1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ce5:	c7 04 24 b0 3c 10 f0 	movl   $0xf0103cb0,(%esp)
f0103cec:	e8 41 19 00 00       	call   f0105632 <vprintfmt>
	return cnt;
}
f0103cf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103cf4:	c9                   	leave  
f0103cf5:	c3                   	ret    

f0103cf6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103cf6:	55                   	push   %ebp
f0103cf7:	89 e5                	mov    %esp,%ebp
f0103cf9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103cfc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103cff:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d03:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d06:	89 04 24             	mov    %eax,(%esp)
f0103d09:	e8 b5 ff ff ff       	call   f0103cc3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103d0e:	c9                   	leave  
f0103d0f:	c3                   	ret    

f0103d10 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103d10:	55                   	push   %ebp
f0103d11:	89 e5                	mov    %esp,%ebp
f0103d13:	57                   	push   %edi
f0103d14:	56                   	push   %esi
f0103d15:	53                   	push   %ebx
f0103d16:	83 ec 1c             	sub    $0x1c,%esp

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint8_t cpuid;
	//for(; i < NCPU; i++){
	cpuid = thiscpu -> cpu_id;
f0103d19:	e8 1e 27 00 00       	call   f010643c <cpunum>
f0103d1e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d21:	0f b6 98 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%ebx
	thiscpu -> cpu_ts = thiscpu -> cpu_ts;
f0103d28:	e8 0f 27 00 00       	call   f010643c <cpunum>
f0103d2d:	89 c7                	mov    %eax,%edi
f0103d2f:	e8 08 27 00 00       	call   f010643c <cpunum>
f0103d34:	6b ff 74             	imul   $0x74,%edi,%edi
f0103d37:	6b f0 74             	imul   $0x74,%eax,%esi
f0103d3a:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f0103d40:	81 c6 2c b0 22 f0    	add    $0xf022b02c,%esi
f0103d46:	b9 1a 00 00 00       	mov    $0x1a,%ecx
f0103d4b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	thiscpu -> cpu_ts.ts_esp0 = KSTACKTOP - cpuid * (KSTKSIZE + KSTKGAP);
f0103d4d:	e8 ea 26 00 00       	call   f010643c <cpunum>
f0103d52:	0f b6 f3             	movzbl %bl,%esi
f0103d55:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d58:	89 f2                	mov    %esi,%edx
f0103d5a:	f7 da                	neg    %edx
f0103d5c:	c1 e2 10             	shl    $0x10,%edx
f0103d5f:	81 ea 00 00 40 10    	sub    $0x10400000,%edx
f0103d65:	89 90 30 b0 22 f0    	mov    %edx,-0xfdd4fd0(%eax)
	thiscpu -> cpu_ts.ts_ss0 = GD_KD;
f0103d6b:	e8 cc 26 00 00       	call   f010643c <cpunum>
f0103d70:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d73:	66 c7 80 34 b0 22 f0 	movw   $0x10,-0xfdd4fcc(%eax)
f0103d7a:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + cpuid] = SEG16(STS_T32A, (uint32_t) (&(thiscpu -> cpu_ts)),
f0103d7c:	83 c6 05             	add    $0x5,%esi
f0103d7f:	e8 b8 26 00 00       	call   f010643c <cpunum>
f0103d84:	89 c7                	mov    %eax,%edi
f0103d86:	e8 b1 26 00 00       	call   f010643c <cpunum>
f0103d8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103d8e:	e8 a9 26 00 00       	call   f010643c <cpunum>
f0103d93:	66 c7 04 f5 20 13 12 	movw   $0x68,-0xfedece0(,%esi,8)
f0103d9a:	f0 68 00 
f0103d9d:	6b ff 74             	imul   $0x74,%edi,%edi
f0103da0:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f0103da6:	66 89 3c f5 22 13 12 	mov    %di,-0xfedecde(,%esi,8)
f0103dad:	f0 
f0103dae:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103db2:	81 c2 2c b0 22 f0    	add    $0xf022b02c,%edx
f0103db8:	c1 ea 10             	shr    $0x10,%edx
f0103dbb:	88 14 f5 24 13 12 f0 	mov    %dl,-0xfedecdc(,%esi,8)
f0103dc2:	c6 04 f5 26 13 12 f0 	movb   $0x40,-0xfedecda(,%esi,8)
f0103dc9:	40 
f0103dca:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dcd:	05 2c b0 22 f0       	add    $0xf022b02c,%eax
f0103dd2:	c1 e8 18             	shr    $0x18,%eax
f0103dd5:	88 04 f5 27 13 12 f0 	mov    %al,-0xfedecd9(,%esi,8)
					sizeof(struct Taskstate), 0);
	gdt[(GD_TSS0 >> 3) + cpuid].sd_s = 0;
f0103ddc:	c6 04 f5 25 13 12 f0 	movb   $0x89,-0xfedecdb(,%esi,8)
f0103de3:	89 



	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (cpuid << 3));
f0103de4:	0f b6 db             	movzbl %bl,%ebx
f0103de7:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103dee:	0f 00 db             	ltr    %bx
}  

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103df1:	b8 8c 13 12 f0       	mov    $0xf012138c,%eax
f0103df6:	0f 01 18             	lidtl  (%eax)
// cprintf("thiscpu %d\n", thiscpu->cpu_id);
	// Load the IDT
	lidt(&idt_pd);
	// panic("");
	//}
}
f0103df9:	83 c4 1c             	add    $0x1c,%esp
f0103dfc:	5b                   	pop    %ebx
f0103dfd:	5e                   	pop    %esi
f0103dfe:	5f                   	pop    %edi
f0103dff:	5d                   	pop    %ebp
f0103e00:	c3                   	ret    

f0103e01 <trap_init>:
}


void
trap_init(void)
{
f0103e01:	55                   	push   %ebp
f0103e02:	89 e5                	mov    %esp,%ebp
f0103e04:	83 ec 08             	sub    $0x8,%esp
	extern void IRQ_spurious();
	extern void IRQ_ide();
	extern void IRQ_error();

	/* SETGATE(Gatedesc, istrap[1/0], sel, off, dpl) -- inc/mmu.h*/
	SETGATE(idt[T_DIVIDE] ,0, GD_KT, Divide_error, 0);
f0103e07:	b8 50 48 10 f0       	mov    $0xf0104850,%eax
f0103e0c:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f0103e12:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f0103e19:	08 00 
f0103e1b:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f0103e22:	c6 05 65 a2 22 f0 8e 	movb   $0x8e,0xf022a265
f0103e29:	c1 e8 10             	shr    $0x10,%eax
f0103e2c:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	SETGATE(idt[T_DEBUG] ,0, GD_KT, Debug, 0);
f0103e32:	b8 5a 48 10 f0       	mov    $0xf010485a,%eax
f0103e37:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f0103e3d:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f0103e44:	08 00 
f0103e46:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f0103e4d:	c6 05 6d a2 22 f0 8e 	movb   $0x8e,0xf022a26d
f0103e54:	c1 e8 10             	shr    $0x10,%eax
f0103e57:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	SETGATE(idt[T_NMI] ,0, GD_KT, Non_Maskable_Interrupt, 0);
f0103e5d:	b8 60 48 10 f0       	mov    $0xf0104860,%eax
f0103e62:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f0103e68:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f0103e6f:	08 00 
f0103e71:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f0103e78:	c6 05 75 a2 22 f0 8e 	movb   $0x8e,0xf022a275
f0103e7f:	c1 e8 10             	shr    $0x10,%eax
f0103e82:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	SETGATE(idt[T_BRKPT] ,0, GD_KT, Breakpoint, 3);
f0103e88:	b8 66 48 10 f0       	mov    $0xf0104866,%eax
f0103e8d:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f0103e93:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f0103e9a:	08 00 
f0103e9c:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f0103ea3:	c6 05 7d a2 22 f0 ee 	movb   $0xee,0xf022a27d
f0103eaa:	c1 e8 10             	shr    $0x10,%eax
f0103ead:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	SETGATE(idt[T_OFLOW] ,0, GD_KT, Overflow, 0);
f0103eb3:	b8 6c 48 10 f0       	mov    $0xf010486c,%eax
f0103eb8:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f0103ebe:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f0103ec5:	08 00 
f0103ec7:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f0103ece:	c6 05 85 a2 22 f0 8e 	movb   $0x8e,0xf022a285
f0103ed5:	c1 e8 10             	shr    $0x10,%eax
f0103ed8:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	SETGATE(idt[T_BOUND] ,0, GD_KT, BOUND_Range_Exceeded, 0);
f0103ede:	b8 72 48 10 f0       	mov    $0xf0104872,%eax
f0103ee3:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f0103ee9:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f0103ef0:	08 00 
f0103ef2:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f0103ef9:	c6 05 8d a2 22 f0 8e 	movb   $0x8e,0xf022a28d
f0103f00:	c1 e8 10             	shr    $0x10,%eax
f0103f03:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	SETGATE(idt[T_ILLOP] ,0, GD_KT, Invalid_Opcode, 0);
f0103f09:	b8 78 48 10 f0       	mov    $0xf0104878,%eax
f0103f0e:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f0103f14:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f0103f1b:	08 00 
f0103f1d:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f0103f24:	c6 05 95 a2 22 f0 8e 	movb   $0x8e,0xf022a295
f0103f2b:	c1 e8 10             	shr    $0x10,%eax
f0103f2e:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	SETGATE(idt[T_DEVICE] ,0, GD_KT, Device_Not_Available, 0);
f0103f34:	b8 7e 48 10 f0       	mov    $0xf010487e,%eax
f0103f39:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f0103f3f:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f0103f46:	08 00 
f0103f48:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f0103f4f:	c6 05 9d a2 22 f0 8e 	movb   $0x8e,0xf022a29d
f0103f56:	c1 e8 10             	shr    $0x10,%eax
f0103f59:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	SETGATE(idt[T_DBLFLT] ,0, GD_KT, Double_Fault, 0);
f0103f5f:	b8 84 48 10 f0       	mov    $0xf0104884,%eax
f0103f64:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f0103f6a:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f0103f71:	08 00 
f0103f73:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f0103f7a:	c6 05 a5 a2 22 f0 8e 	movb   $0x8e,0xf022a2a5
f0103f81:	c1 e8 10             	shr    $0x10,%eax
f0103f84:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6
	SETGATE(idt[T_TSS] ,0, GD_KT, Invalid_TSS, 0);
f0103f8a:	b8 88 48 10 f0       	mov    $0xf0104888,%eax
f0103f8f:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f0103f95:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f0103f9c:	08 00 
f0103f9e:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f0103fa5:	c6 05 b5 a2 22 f0 8e 	movb   $0x8e,0xf022a2b5
f0103fac:	c1 e8 10             	shr    $0x10,%eax
f0103faf:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	SETGATE(idt[T_SEGNP] ,0, GD_KT, Segment_Not_Present, 0);
f0103fb5:	b8 8c 48 10 f0       	mov    $0xf010488c,%eax
f0103fba:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f0103fc0:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f0103fc7:	08 00 
f0103fc9:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f0103fd0:	c6 05 bd a2 22 f0 8e 	movb   $0x8e,0xf022a2bd
f0103fd7:	c1 e8 10             	shr    $0x10,%eax
f0103fda:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
	SETGATE(idt[T_STACK] ,0, GD_KT, Stack_Fault, 0);
f0103fe0:	b8 90 48 10 f0       	mov    $0xf0104890,%eax
f0103fe5:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f0103feb:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f0103ff2:	08 00 
f0103ff4:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f0103ffb:	c6 05 c5 a2 22 f0 8e 	movb   $0x8e,0xf022a2c5
f0104002:	c1 e8 10             	shr    $0x10,%eax
f0104005:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	SETGATE(idt[T_GPFLT] ,0, GD_KT, General_Protection, 0);
f010400b:	b8 94 48 10 f0       	mov    $0xf0104894,%eax
f0104010:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f0104016:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f010401d:	08 00 
f010401f:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f0104026:	c6 05 cd a2 22 f0 8e 	movb   $0x8e,0xf022a2cd
f010402d:	c1 e8 10             	shr    $0x10,%eax
f0104030:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	SETGATE(idt[T_PGFLT] ,0, GD_KT, Page_Fault, 0);
f0104036:	b8 98 48 10 f0       	mov    $0xf0104898,%eax
f010403b:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f0104041:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f0104048:	08 00 
f010404a:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f0104051:	c6 05 d5 a2 22 f0 8e 	movb   $0x8e,0xf022a2d5
f0104058:	c1 e8 10             	shr    $0x10,%eax
f010405b:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6
	SETGATE(idt[T_FPERR] ,0, GD_KT, x87_FPU_Floating_Point_Error, 0);
f0104061:	b8 9c 48 10 f0       	mov    $0xf010489c,%eax
f0104066:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f010406c:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f0104073:	08 00 
f0104075:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f010407c:	c6 05 e5 a2 22 f0 8e 	movb   $0x8e,0xf022a2e5
f0104083:	c1 e8 10             	shr    $0x10,%eax
f0104086:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6
	SETGATE(idt[T_ALIGN] ,0, GD_KT, Alignment_Check, 0);
f010408c:	b8 a2 48 10 f0       	mov    $0xf01048a2,%eax
f0104091:	66 a3 e8 a2 22 f0    	mov    %ax,0xf022a2e8
f0104097:	66 c7 05 ea a2 22 f0 	movw   $0x8,0xf022a2ea
f010409e:	08 00 
f01040a0:	c6 05 ec a2 22 f0 00 	movb   $0x0,0xf022a2ec
f01040a7:	c6 05 ed a2 22 f0 8e 	movb   $0x8e,0xf022a2ed
f01040ae:	c1 e8 10             	shr    $0x10,%eax
f01040b1:	66 a3 ee a2 22 f0    	mov    %ax,0xf022a2ee
	SETGATE(idt[T_MCHK] ,0, GD_KT, Machine_Check, 0);
f01040b7:	b8 a8 48 10 f0       	mov    $0xf01048a8,%eax
f01040bc:	66 a3 f0 a2 22 f0    	mov    %ax,0xf022a2f0
f01040c2:	66 c7 05 f2 a2 22 f0 	movw   $0x8,0xf022a2f2
f01040c9:	08 00 
f01040cb:	c6 05 f4 a2 22 f0 00 	movb   $0x0,0xf022a2f4
f01040d2:	c6 05 f5 a2 22 f0 8e 	movb   $0x8e,0xf022a2f5
f01040d9:	c1 e8 10             	shr    $0x10,%eax
f01040dc:	66 a3 f6 a2 22 f0    	mov    %ax,0xf022a2f6
	SETGATE(idt[T_SIMDERR] ,0, GD_KT, SIMD_Floating_Point_Exception, 0);
f01040e2:	b8 ae 48 10 f0       	mov    $0xf01048ae,%eax
f01040e7:	66 a3 f8 a2 22 f0    	mov    %ax,0xf022a2f8
f01040ed:	66 c7 05 fa a2 22 f0 	movw   $0x8,0xf022a2fa
f01040f4:	08 00 
f01040f6:	c6 05 fc a2 22 f0 00 	movb   $0x0,0xf022a2fc
f01040fd:	c6 05 fd a2 22 f0 8e 	movb   $0x8e,0xf022a2fd
f0104104:	c1 e8 10             	shr    $0x10,%eax
f0104107:	66 a3 fe a2 22 f0    	mov    %ax,0xf022a2fe

	SETGATE(idt[T_SYSCALL], 0 , GD_KT, System_call, 3);
f010410d:	b8 b4 48 10 f0       	mov    $0xf01048b4,%eax
f0104112:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f0104118:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f010411f:	08 00 
f0104121:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0104128:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f010412f:	c1 e8 10             	shr    $0x10,%eax
f0104132:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6
// TRAPHANDLER_NOEC(IRQ_serial,IRQ_OFFSET+IRQ_SERIAL);
// TRAPHANDLER_NOEC(IRQ_spurious,IRQ_OFFSET+IRQ_SPURIOUS);
// TRAPHANDLER_NOEC(IRQ_ide,IRQ_OFFSET+IRQ_IDE);
// TRAPHANDLER_NOEC(IRQ_error,IRQ_OFFSET+IRQ_ERROR);

	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, IRQ_timer, 0);
f0104138:	b8 ba 48 10 f0       	mov    $0xf01048ba,%eax
f010413d:	66 a3 60 a3 22 f0    	mov    %ax,0xf022a360
f0104143:	66 c7 05 62 a3 22 f0 	movw   $0x8,0xf022a362
f010414a:	08 00 
f010414c:	c6 05 64 a3 22 f0 00 	movb   $0x0,0xf022a364
f0104153:	c6 05 65 a3 22 f0 8e 	movb   $0x8e,0xf022a365
f010415a:	c1 e8 10             	shr    $0x10,%eax
f010415d:	66 a3 66 a3 22 f0    	mov    %ax,0xf022a366
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, IRQ_kbd, 0);
f0104163:	b8 c0 48 10 f0       	mov    $0xf01048c0,%eax
f0104168:	66 a3 68 a3 22 f0    	mov    %ax,0xf022a368
f010416e:	66 c7 05 6a a3 22 f0 	movw   $0x8,0xf022a36a
f0104175:	08 00 
f0104177:	c6 05 6c a3 22 f0 00 	movb   $0x0,0xf022a36c
f010417e:	c6 05 6d a3 22 f0 8e 	movb   $0x8e,0xf022a36d
f0104185:	c1 e8 10             	shr    $0x10,%eax
f0104188:	66 a3 6e a3 22 f0    	mov    %ax,0xf022a36e
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, IRQ_serial, 0);
f010418e:	b8 c6 48 10 f0       	mov    $0xf01048c6,%eax
f0104193:	66 a3 80 a3 22 f0    	mov    %ax,0xf022a380
f0104199:	66 c7 05 82 a3 22 f0 	movw   $0x8,0xf022a382
f01041a0:	08 00 
f01041a2:	c6 05 84 a3 22 f0 00 	movb   $0x0,0xf022a384
f01041a9:	c6 05 85 a3 22 f0 8e 	movb   $0x8e,0xf022a385
f01041b0:	c1 e8 10             	shr    $0x10,%eax
f01041b3:	66 a3 86 a3 22 f0    	mov    %ax,0xf022a386
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, IRQ_spurious, 0);
f01041b9:	b8 cc 48 10 f0       	mov    $0xf01048cc,%eax
f01041be:	66 a3 98 a3 22 f0    	mov    %ax,0xf022a398
f01041c4:	66 c7 05 9a a3 22 f0 	movw   $0x8,0xf022a39a
f01041cb:	08 00 
f01041cd:	c6 05 9c a3 22 f0 00 	movb   $0x0,0xf022a39c
f01041d4:	c6 05 9d a3 22 f0 8e 	movb   $0x8e,0xf022a39d
f01041db:	c1 e8 10             	shr    $0x10,%eax
f01041de:	66 a3 9e a3 22 f0    	mov    %ax,0xf022a39e
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, IRQ_ide, 0);
f01041e4:	b8 d2 48 10 f0       	mov    $0xf01048d2,%eax
f01041e9:	66 a3 d0 a3 22 f0    	mov    %ax,0xf022a3d0
f01041ef:	66 c7 05 d2 a3 22 f0 	movw   $0x8,0xf022a3d2
f01041f6:	08 00 
f01041f8:	c6 05 d4 a3 22 f0 00 	movb   $0x0,0xf022a3d4
f01041ff:	c6 05 d5 a3 22 f0 8e 	movb   $0x8e,0xf022a3d5
f0104206:	c1 e8 10             	shr    $0x10,%eax
f0104209:	66 a3 d6 a3 22 f0    	mov    %ax,0xf022a3d6
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 0, GD_KT, IRQ_error, 0);
f010420f:	b8 d8 48 10 f0       	mov    $0xf01048d8,%eax
f0104214:	66 a3 f8 a3 22 f0    	mov    %ax,0xf022a3f8
f010421a:	66 c7 05 fa a3 22 f0 	movw   $0x8,0xf022a3fa
f0104221:	08 00 
f0104223:	c6 05 fc a3 22 f0 00 	movb   $0x0,0xf022a3fc
f010422a:	c6 05 fd a3 22 f0 8e 	movb   $0x8e,0xf022a3fd
f0104231:	c1 e8 10             	shr    $0x10,%eax
f0104234:	66 a3 fe a3 22 f0    	mov    %ax,0xf022a3fe
	// Per-CPU setup 
	trap_init_percpu();
f010423a:	e8 d1 fa ff ff       	call   f0103d10 <trap_init_percpu>
}
f010423f:	c9                   	leave  
f0104240:	c3                   	ret    

f0104241 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0104241:	55                   	push   %ebp
f0104242:	89 e5                	mov    %esp,%ebp
f0104244:	53                   	push   %ebx
f0104245:	83 ec 14             	sub    $0x14,%esp
f0104248:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010424b:	8b 03                	mov    (%ebx),%eax
f010424d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104251:	c7 04 24 d6 7b 10 f0 	movl   $0xf0107bd6,(%esp)
f0104258:	e8 99 fa ff ff       	call   f0103cf6 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010425d:	8b 43 04             	mov    0x4(%ebx),%eax
f0104260:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104264:	c7 04 24 e5 7b 10 f0 	movl   $0xf0107be5,(%esp)
f010426b:	e8 86 fa ff ff       	call   f0103cf6 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104270:	8b 43 08             	mov    0x8(%ebx),%eax
f0104273:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104277:	c7 04 24 f4 7b 10 f0 	movl   $0xf0107bf4,(%esp)
f010427e:	e8 73 fa ff ff       	call   f0103cf6 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104283:	8b 43 0c             	mov    0xc(%ebx),%eax
f0104286:	89 44 24 04          	mov    %eax,0x4(%esp)
f010428a:	c7 04 24 03 7c 10 f0 	movl   $0xf0107c03,(%esp)
f0104291:	e8 60 fa ff ff       	call   f0103cf6 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104296:	8b 43 10             	mov    0x10(%ebx),%eax
f0104299:	89 44 24 04          	mov    %eax,0x4(%esp)
f010429d:	c7 04 24 12 7c 10 f0 	movl   $0xf0107c12,(%esp)
f01042a4:	e8 4d fa ff ff       	call   f0103cf6 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01042a9:	8b 43 14             	mov    0x14(%ebx),%eax
f01042ac:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042b0:	c7 04 24 21 7c 10 f0 	movl   $0xf0107c21,(%esp)
f01042b7:	e8 3a fa ff ff       	call   f0103cf6 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01042bc:	8b 43 18             	mov    0x18(%ebx),%eax
f01042bf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042c3:	c7 04 24 30 7c 10 f0 	movl   $0xf0107c30,(%esp)
f01042ca:	e8 27 fa ff ff       	call   f0103cf6 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01042cf:	8b 43 1c             	mov    0x1c(%ebx),%eax
f01042d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042d6:	c7 04 24 3f 7c 10 f0 	movl   $0xf0107c3f,(%esp)
f01042dd:	e8 14 fa ff ff       	call   f0103cf6 <cprintf>
}
f01042e2:	83 c4 14             	add    $0x14,%esp
f01042e5:	5b                   	pop    %ebx
f01042e6:	5d                   	pop    %ebp
f01042e7:	c3                   	ret    

f01042e8 <print_trapframe>:
	//}
}

void
print_trapframe(struct Trapframe *tf)
{
f01042e8:	55                   	push   %ebp
f01042e9:	89 e5                	mov    %esp,%ebp
f01042eb:	56                   	push   %esi
f01042ec:	53                   	push   %ebx
f01042ed:	83 ec 10             	sub    $0x10,%esp
f01042f0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f01042f3:	e8 44 21 00 00       	call   f010643c <cpunum>
f01042f8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01042fc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104300:	c7 04 24 a3 7c 10 f0 	movl   $0xf0107ca3,(%esp)
f0104307:	e8 ea f9 ff ff       	call   f0103cf6 <cprintf>
	print_regs(&tf->tf_regs);
f010430c:	89 1c 24             	mov    %ebx,(%esp)
f010430f:	e8 2d ff ff ff       	call   f0104241 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0104314:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0104318:	89 44 24 04          	mov    %eax,0x4(%esp)
f010431c:	c7 04 24 c1 7c 10 f0 	movl   $0xf0107cc1,(%esp)
f0104323:	e8 ce f9 ff ff       	call   f0103cf6 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0104328:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010432c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104330:	c7 04 24 d4 7c 10 f0 	movl   $0xf0107cd4,(%esp)
f0104337:	e8 ba f9 ff ff       	call   f0103cf6 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010433c:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f010433f:	83 f8 13             	cmp    $0x13,%eax
f0104342:	77 09                	ja     f010434d <print_trapframe+0x65>
		return excnames[trapno];
f0104344:	8b 14 85 a0 7f 10 f0 	mov    -0xfef8060(,%eax,4),%edx
f010434b:	eb 1f                	jmp    f010436c <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f010434d:	83 f8 30             	cmp    $0x30,%eax
f0104350:	74 15                	je     f0104367 <print_trapframe+0x7f>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0104352:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f0104355:	83 fa 0f             	cmp    $0xf,%edx
f0104358:	ba 5a 7c 10 f0       	mov    $0xf0107c5a,%edx
f010435d:	b9 6d 7c 10 f0       	mov    $0xf0107c6d,%ecx
f0104362:	0f 47 d1             	cmova  %ecx,%edx
f0104365:	eb 05                	jmp    f010436c <print_trapframe+0x84>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0104367:	ba 4e 7c 10 f0       	mov    $0xf0107c4e,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010436c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104370:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104374:	c7 04 24 e7 7c 10 f0 	movl   $0xf0107ce7,(%esp)
f010437b:	e8 76 f9 ff ff       	call   f0103cf6 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104380:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0104386:	75 19                	jne    f01043a1 <print_trapframe+0xb9>
f0104388:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010438c:	75 13                	jne    f01043a1 <print_trapframe+0xb9>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f010438e:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104391:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104395:	c7 04 24 f9 7c 10 f0 	movl   $0xf0107cf9,(%esp)
f010439c:	e8 55 f9 ff ff       	call   f0103cf6 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f01043a1:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01043a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043a8:	c7 04 24 08 7d 10 f0 	movl   $0xf0107d08,(%esp)
f01043af:	e8 42 f9 ff ff       	call   f0103cf6 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01043b4:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01043b8:	75 51                	jne    f010440b <print_trapframe+0x123>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01043ba:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01043bd:	89 c2                	mov    %eax,%edx
f01043bf:	83 e2 01             	and    $0x1,%edx
f01043c2:	ba 7c 7c 10 f0       	mov    $0xf0107c7c,%edx
f01043c7:	b9 87 7c 10 f0       	mov    $0xf0107c87,%ecx
f01043cc:	0f 45 ca             	cmovne %edx,%ecx
f01043cf:	89 c2                	mov    %eax,%edx
f01043d1:	83 e2 02             	and    $0x2,%edx
f01043d4:	ba 93 7c 10 f0       	mov    $0xf0107c93,%edx
f01043d9:	be 99 7c 10 f0       	mov    $0xf0107c99,%esi
f01043de:	0f 44 d6             	cmove  %esi,%edx
f01043e1:	83 e0 04             	and    $0x4,%eax
f01043e4:	b8 9e 7c 10 f0       	mov    $0xf0107c9e,%eax
f01043e9:	be d3 7d 10 f0       	mov    $0xf0107dd3,%esi
f01043ee:	0f 44 c6             	cmove  %esi,%eax
f01043f1:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01043f5:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043fd:	c7 04 24 16 7d 10 f0 	movl   $0xf0107d16,(%esp)
f0104404:	e8 ed f8 ff ff       	call   f0103cf6 <cprintf>
f0104409:	eb 0c                	jmp    f0104417 <print_trapframe+0x12f>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010440b:	c7 04 24 58 78 10 f0 	movl   $0xf0107858,(%esp)
f0104412:	e8 df f8 ff ff       	call   f0103cf6 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0104417:	8b 43 30             	mov    0x30(%ebx),%eax
f010441a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010441e:	c7 04 24 25 7d 10 f0 	movl   $0xf0107d25,(%esp)
f0104425:	e8 cc f8 ff ff       	call   f0103cf6 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010442a:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010442e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104432:	c7 04 24 34 7d 10 f0 	movl   $0xf0107d34,(%esp)
f0104439:	e8 b8 f8 ff ff       	call   f0103cf6 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010443e:	8b 43 38             	mov    0x38(%ebx),%eax
f0104441:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104445:	c7 04 24 47 7d 10 f0 	movl   $0xf0107d47,(%esp)
f010444c:	e8 a5 f8 ff ff       	call   f0103cf6 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0104451:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104455:	74 27                	je     f010447e <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104457:	8b 43 3c             	mov    0x3c(%ebx),%eax
f010445a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010445e:	c7 04 24 56 7d 10 f0 	movl   $0xf0107d56,(%esp)
f0104465:	e8 8c f8 ff ff       	call   f0103cf6 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010446a:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010446e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104472:	c7 04 24 65 7d 10 f0 	movl   $0xf0107d65,(%esp)
f0104479:	e8 78 f8 ff ff       	call   f0103cf6 <cprintf>
	}
}
f010447e:	83 c4 10             	add    $0x10,%esp
f0104481:	5b                   	pop    %ebx
f0104482:	5e                   	pop    %esi
f0104483:	5d                   	pop    %ebp
f0104484:	c3                   	ret    

f0104485 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104485:	55                   	push   %ebp
f0104486:	89 e5                	mov    %esp,%ebp
f0104488:	83 ec 38             	sub    $0x38,%esp
f010448b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010448e:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104491:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104494:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104497:	0f 20 d6             	mov    %cr2,%esi
	// All the handlers should check whether it is in kernel mode, 
	// if so, it should check the parameter whether it is valid
	// 
	// If I do not do the following operation, the grade script 
	// will run correctly though. 
	if((tf->tf_cs & 0x3) == 0)// CPL  -  the low 2-bit in the cs register 
f010449a:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010449e:	75 20                	jne    f01044c0 <page_fault_handler+0x3b>
		panic("kernel fault: invalid parameter %x for the page fault handler!\n", fault_va);
f01044a0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01044a4:	c7 44 24 08 20 7f 10 	movl   $0xf0107f20,0x8(%esp)
f01044ab:	f0 
f01044ac:	c7 44 24 04 76 01 00 	movl   $0x176,0x4(%esp)
f01044b3:	00 
f01044b4:	c7 04 24 78 7d 10 f0 	movl   $0xf0107d78,(%esp)
f01044bb:	e8 80 bb ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	// panic("%x", curenv->env_pgfault_upcall);
	if(curenv -> env_pgfault_upcall){
f01044c0:	e8 77 1f 00 00       	call   f010643c <cpunum>
f01044c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01044c8:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01044ce:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f01044d2:	0f 84 04 01 00 00    	je     f01045dc <page_fault_handler+0x157>
		esp = tf -> tf_esp;
f01044d8:	8b 43 3c             	mov    0x3c(%ebx),%eax
		if(esp < UXSTACKTOP && esp > UXSTACKTOP - PGSIZE)
f01044db:	8d 90 ff 0f 40 11    	lea    0x11400fff(%eax),%edx
			esp -= 4;
f01044e1:	83 e8 04             	sub    $0x4,%eax
f01044e4:	81 fa fe 0f 00 00    	cmp    $0xffe,%edx
f01044ea:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01044ef:	89 d7                	mov    %edx,%edi
f01044f1:	0f 46 f8             	cmovbe %eax,%edi
		else
			esp = UXSTACKTOP;
		utrap = (struct UTrapframe *)(esp - sizeof(struct UTrapframe));
f01044f4:	8d 47 cc             	lea    -0x34(%edi),%eax
f01044f7:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		user_mem_assert (curenv, (void*) utrap, sizeof (struct UTrapframe), PTE_U|PTE_W);
f01044fa:	e8 3d 1f 00 00       	call   f010643c <cpunum>
f01044ff:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0104506:	00 
f0104507:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
f010450e:	00 
f010450f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104512:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104516:	6b c0 74             	imul   $0x74,%eax,%eax
f0104519:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010451f:	89 04 24             	mov    %eax,(%esp)
f0104522:	e8 a6 ed ff ff       	call   f01032cd <user_mem_assert>

		utrap->utf_fault_va = fault_va;
f0104527:	89 77 cc             	mov    %esi,-0x34(%edi)
		utrap->utf_err = tf->tf_err;
f010452a:	8b 43 2c             	mov    0x2c(%ebx),%eax
f010452d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104530:	89 42 04             	mov    %eax,0x4(%edx)
		utrap->utf_regs = tf->tf_regs;
f0104533:	83 ef 2c             	sub    $0x2c,%edi
f0104536:	89 de                	mov    %ebx,%esi
f0104538:	b8 20 00 00 00       	mov    $0x20,%eax
f010453d:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0104543:	74 03                	je     f0104548 <page_fault_handler+0xc3>
f0104545:	a4                   	movsb  %ds:(%esi),%es:(%edi)
f0104546:	b0 1f                	mov    $0x1f,%al
f0104548:	f7 c7 02 00 00 00    	test   $0x2,%edi
f010454e:	74 05                	je     f0104555 <page_fault_handler+0xd0>
f0104550:	66 a5                	movsw  %ds:(%esi),%es:(%edi)
f0104552:	83 e8 02             	sub    $0x2,%eax
f0104555:	89 c1                	mov    %eax,%ecx
f0104557:	c1 e9 02             	shr    $0x2,%ecx
f010455a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010455c:	ba 00 00 00 00       	mov    $0x0,%edx
f0104561:	a8 02                	test   $0x2,%al
f0104563:	74 0b                	je     f0104570 <page_fault_handler+0xeb>
f0104565:	0f b7 16             	movzwl (%esi),%edx
f0104568:	66 89 17             	mov    %dx,(%edi)
f010456b:	ba 02 00 00 00       	mov    $0x2,%edx
f0104570:	a8 01                	test   $0x1,%al
f0104572:	74 07                	je     f010457b <page_fault_handler+0xf6>
f0104574:	0f b6 04 16          	movzbl (%esi,%edx,1),%eax
f0104578:	88 04 17             	mov    %al,(%edi,%edx,1)
		utrap->utf_eip = tf->tf_eip;
f010457b:	8b 43 30             	mov    0x30(%ebx),%eax
f010457e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104581:	89 42 28             	mov    %eax,0x28(%edx)
		utrap->utf_eflags = tf->tf_eflags;
f0104584:	8b 43 38             	mov    0x38(%ebx),%eax
f0104587:	89 42 2c             	mov    %eax,0x2c(%edx)
		utrap->utf_esp = tf->tf_esp;
f010458a:	8b 43 3c             	mov    0x3c(%ebx),%eax
f010458d:	89 42 30             	mov    %eax,0x30(%edx)


		curenv->env_tf.tf_eip = (uint32_t) curenv->env_pgfault_upcall;
f0104590:	e8 a7 1e 00 00       	call   f010643c <cpunum>
f0104595:	6b c0 74             	imul   $0x74,%eax,%eax
f0104598:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f010459e:	e8 99 1e 00 00       	call   f010643c <cpunum>
f01045a3:	6b c0 74             	imul   $0x74,%eax,%eax
f01045a6:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01045ac:	8b 40 64             	mov    0x64(%eax),%eax
f01045af:	89 43 30             	mov    %eax,0x30(%ebx)
		curenv->env_tf.tf_esp = (uint32_t) utrap;
f01045b2:	e8 85 1e 00 00       	call   f010643c <cpunum>
f01045b7:	6b c0 74             	imul   $0x74,%eax,%eax
f01045ba:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01045c0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01045c3:	89 50 3c             	mov    %edx,0x3c(%eax)
		env_run (curenv);
f01045c6:	e8 71 1e 00 00       	call   f010643c <cpunum>
f01045cb:	6b c0 74             	imul   $0x74,%eax,%eax
f01045ce:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01045d4:	89 04 24             	mov    %eax,(%esp)
f01045d7:	e8 dd f4 ff ff       	call   f0103ab9 <env_run>
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01045dc:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f01045df:	e8 58 1e 00 00       	call   f010643c <cpunum>
		curenv->env_tf.tf_esp = (uint32_t) utrap;
		env_run (curenv);
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01045e4:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01045e8:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f01045ec:	6b c0 74             	imul   $0x74,%eax,%eax
f01045ef:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
		curenv->env_tf.tf_esp = (uint32_t) utrap;
		env_run (curenv);
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01045f5:	8b 40 48             	mov    0x48(%eax),%eax
f01045f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045fc:	c7 04 24 60 7f 10 f0 	movl   $0xf0107f60,(%esp)
f0104603:	e8 ee f6 ff ff       	call   f0103cf6 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0104608:	89 1c 24             	mov    %ebx,(%esp)
f010460b:	e8 d8 fc ff ff       	call   f01042e8 <print_trapframe>
	env_destroy(curenv);
f0104610:	e8 27 1e 00 00       	call   f010643c <cpunum>
f0104615:	6b c0 74             	imul   $0x74,%eax,%eax
f0104618:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010461e:	89 04 24             	mov    %eax,(%esp)
f0104621:	e8 f2 f3 ff ff       	call   f0103a18 <env_destroy>
}
f0104626:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104629:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010462c:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010462f:	89 ec                	mov    %ebp,%esp
f0104631:	5d                   	pop    %ebp
f0104632:	c3                   	ret    

f0104633 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0104633:	55                   	push   %ebp
f0104634:	89 e5                	mov    %esp,%ebp
f0104636:	57                   	push   %edi
f0104637:	56                   	push   %esi
f0104638:	83 ec 20             	sub    $0x20,%esp
f010463b:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010463e:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f010463f:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0104646:	74 01                	je     f0104649 <trap+0x16>
		asm volatile("hlt");
f0104648:	f4                   	hlt    

static __inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0104649:	9c                   	pushf  
f010464a:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010464b:	f6 c4 02             	test   $0x2,%ah
f010464e:	74 24                	je     f0104674 <trap+0x41>
f0104650:	c7 44 24 0c 84 7d 10 	movl   $0xf0107d84,0xc(%esp)
f0104657:	f0 
f0104658:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f010465f:	f0 
f0104660:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f0104667:	00 
f0104668:	c7 04 24 78 7d 10 f0 	movl   $0xf0107d78,(%esp)
f010466f:	e8 cc b9 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0104674:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104678:	83 e0 03             	and    $0x3,%eax
f010467b:	66 83 f8 03          	cmp    $0x3,%ax
f010467f:	0f 85 a7 00 00 00    	jne    f010472c <trap+0xf9>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0104685:	c7 04 24 a0 13 12 f0 	movl   $0xf01213a0,(%esp)
f010468c:	e8 44 20 00 00       	call   f01066d5 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0104691:	e8 a6 1d 00 00       	call   f010643c <cpunum>
f0104696:	6b c0 74             	imul   $0x74,%eax,%eax
f0104699:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01046a0:	75 24                	jne    f01046c6 <trap+0x93>
f01046a2:	c7 44 24 0c 9d 7d 10 	movl   $0xf0107d9d,0xc(%esp)
f01046a9:	f0 
f01046aa:	c7 44 24 08 74 78 10 	movl   $0xf0107874,0x8(%esp)
f01046b1:	f0 
f01046b2:	c7 44 24 04 3e 01 00 	movl   $0x13e,0x4(%esp)
f01046b9:	00 
f01046ba:	c7 04 24 78 7d 10 f0 	movl   $0xf0107d78,(%esp)
f01046c1:	e8 7a b9 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f01046c6:	e8 71 1d 00 00       	call   f010643c <cpunum>
f01046cb:	6b c0 74             	imul   $0x74,%eax,%eax
f01046ce:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01046d4:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01046d8:	75 2d                	jne    f0104707 <trap+0xd4>
			env_free(curenv);
f01046da:	e8 5d 1d 00 00       	call   f010643c <cpunum>
f01046df:	6b c0 74             	imul   $0x74,%eax,%eax
f01046e2:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01046e8:	89 04 24             	mov    %eax,(%esp)
f01046eb:	e8 22 f1 ff ff       	call   f0103812 <env_free>
			curenv = NULL;
f01046f0:	e8 47 1d 00 00       	call   f010643c <cpunum>
f01046f5:	6b c0 74             	imul   $0x74,%eax,%eax
f01046f8:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f01046ff:	00 00 00 
			sched_yield();
f0104702:	e8 f1 01 00 00       	call   f01048f8 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0104707:	e8 30 1d 00 00       	call   f010643c <cpunum>
f010470c:	6b c0 74             	imul   $0x74,%eax,%eax
f010470f:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104715:	b9 11 00 00 00       	mov    $0x11,%ecx
f010471a:	89 c7                	mov    %eax,%edi
f010471c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010471e:	e8 19 1d 00 00       	call   f010643c <cpunum>
f0104723:	6b c0 74             	imul   $0x74,%eax,%eax
f0104726:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010472c:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf -> tf_trapno){
f0104732:	8b 46 28             	mov    0x28(%esi),%eax
f0104735:	83 f8 03             	cmp    $0x3,%eax
f0104738:	74 1a                	je     f0104754 <trap+0x121>
f010473a:	83 f8 03             	cmp    $0x3,%eax
f010473d:	77 07                	ja     f0104746 <trap+0x113>
f010473f:	83 f8 01             	cmp    $0x1,%eax
f0104742:	75 36                	jne    f010477a <trap+0x147>
f0104744:	eb 0e                	jmp    f0104754 <trap+0x121>
f0104746:	83 f8 0e             	cmp    $0xe,%eax
f0104749:	74 17                	je     f0104762 <trap+0x12f>
f010474b:	83 f8 20             	cmp    $0x20,%eax
f010474e:	66 90                	xchg   %ax,%ax
f0104750:	75 28                	jne    f010477a <trap+0x147>
f0104752:	eb 18                	jmp    f010476c <trap+0x139>
		case T_BRKPT:
		case T_DEBUG:
			monitor(tf);
f0104754:	89 34 24             	mov    %esi,(%esp)
f0104757:	e8 d6 c2 ff ff       	call   f0100a32 <monitor>
f010475c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104760:	eb 18                	jmp    f010477a <trap+0x147>
			break;
		case T_PGFLT:
			page_fault_handler(tf);
f0104762:	89 34 24             	mov    %esi,(%esp)
f0104765:	e8 1b fd ff ff       	call   f0104485 <page_fault_handler>
f010476a:	eb 0e                	jmp    f010477a <trap+0x147>
			break;
		case IRQ_OFFSET + IRQ_TIMER:
			lapic_eoi();
f010476c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104770:	e8 fc 1d 00 00       	call   f0106571 <lapic_eoi>
			sched_yield();
f0104775:	e8 7e 01 00 00       	call   f01048f8 <sched_yield>
			return;
	}

	if (tf->tf_trapno == T_SYSCALL){
f010477a:	8b 46 28             	mov    0x28(%esi),%eax
f010477d:	83 f8 30             	cmp    $0x30,%eax
f0104780:	75 32                	jne    f01047b4 <trap+0x181>
		struct PushRegs *regs = &(tf -> tf_regs);
		/*  DX, CX, BX, DI, SI */
		int32_t num = syscall(regs->reg_eax, regs->reg_edx, regs->reg_ecx, 
f0104782:	8b 46 04             	mov    0x4(%esi),%eax
f0104785:	89 44 24 14          	mov    %eax,0x14(%esp)
f0104789:	8b 06                	mov    (%esi),%eax
f010478b:	89 44 24 10          	mov    %eax,0x10(%esp)
f010478f:	8b 46 10             	mov    0x10(%esi),%eax
f0104792:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104796:	8b 46 18             	mov    0x18(%esi),%eax
f0104799:	89 44 24 08          	mov    %eax,0x8(%esp)
f010479d:	8b 46 14             	mov    0x14(%esi),%eax
f01047a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01047a4:	8b 46 1c             	mov    0x1c(%esi),%eax
f01047a7:	89 04 24             	mov    %eax,(%esp)
f01047aa:	e8 92 02 00 00       	call   f0104a41 <syscall>
			regs->reg_ebx,regs->reg_edi, regs->reg_esi);

		// if(num < 0)
		// 	panic("unhandled fault!\n");
		regs -> reg_eax = num;
f01047af:	89 46 1c             	mov    %eax,0x1c(%esi)
f01047b2:	eb 5c                	jmp    f0104810 <trap+0x1dd>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01047b4:	83 f8 27             	cmp    $0x27,%eax
f01047b7:	75 16                	jne    f01047cf <trap+0x19c>
		cprintf("Spurious interrupt on irq 7\n");
f01047b9:	c7 04 24 a4 7d 10 f0 	movl   $0xf0107da4,(%esp)
f01047c0:	e8 31 f5 ff ff       	call   f0103cf6 <cprintf>
		print_trapframe(tf);
f01047c5:	89 34 24             	mov    %esi,(%esp)
f01047c8:	e8 1b fb ff ff       	call   f01042e8 <print_trapframe>
f01047cd:	eb 41                	jmp    f0104810 <trap+0x1dd>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01047cf:	89 34 24             	mov    %esi,(%esp)
f01047d2:	e8 11 fb ff ff       	call   f01042e8 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01047d7:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01047dc:	75 1c                	jne    f01047fa <trap+0x1c7>
		panic("unhandled trap in kernel");
f01047de:	c7 44 24 08 c1 7d 10 	movl   $0xf0107dc1,0x8(%esp)
f01047e5:	f0 
f01047e6:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
f01047ed:	00 
f01047ee:	c7 04 24 78 7d 10 f0 	movl   $0xf0107d78,(%esp)
f01047f5:	e8 46 b8 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f01047fa:	e8 3d 1c 00 00       	call   f010643c <cpunum>
f01047ff:	6b c0 74             	imul   $0x74,%eax,%eax
f0104802:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104808:	89 04 24             	mov    %eax,(%esp)
f010480b:	e8 08 f2 ff ff       	call   f0103a18 <env_destroy>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104810:	e8 27 1c 00 00       	call   f010643c <cpunum>
f0104815:	6b c0 74             	imul   $0x74,%eax,%eax
f0104818:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010481f:	74 2a                	je     f010484b <trap+0x218>
f0104821:	e8 16 1c 00 00       	call   f010643c <cpunum>
f0104826:	6b c0 74             	imul   $0x74,%eax,%eax
f0104829:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010482f:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104833:	75 16                	jne    f010484b <trap+0x218>
		env_run(curenv);
f0104835:	e8 02 1c 00 00       	call   f010643c <cpunum>
f010483a:	6b c0 74             	imul   $0x74,%eax,%eax
f010483d:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104843:	89 04 24             	mov    %eax,(%esp)
f0104846:	e8 6e f2 ff ff       	call   f0103ab9 <env_run>
	else
		sched_yield();
f010484b:	e8 a8 00 00 00       	call   f01048f8 <sched_yield>

f0104850 <Divide_error>:
  * TRAPHANDLER_NOEC - No return
  * TRAPHANDLER - return
  *
  * http://pdos.csail.mit.edu/6.828/2011/readings/i386/s09_10.htm
  */
TRAPHANDLER_NOEC(Divide_error, T_DIVIDE);
f0104850:	6a 00                	push   $0x0
f0104852:	6a 00                	push   $0x0
f0104854:	e9 85 00 00 00       	jmp    f01048de <_alltraps>
f0104859:	90                   	nop

f010485a <Debug>:
TRAPHANDLER_NOEC(Debug, T_DEBUG);
f010485a:	6a 00                	push   $0x0
f010485c:	6a 01                	push   $0x1
f010485e:	eb 7e                	jmp    f01048de <_alltraps>

f0104860 <Non_Maskable_Interrupt>:
TRAPHANDLER_NOEC(Non_Maskable_Interrupt, T_NMI);
f0104860:	6a 00                	push   $0x0
f0104862:	6a 02                	push   $0x2
f0104864:	eb 78                	jmp    f01048de <_alltraps>

f0104866 <Breakpoint>:
TRAPHANDLER_NOEC(Breakpoint, T_BRKPT);
f0104866:	6a 00                	push   $0x0
f0104868:	6a 03                	push   $0x3
f010486a:	eb 72                	jmp    f01048de <_alltraps>

f010486c <Overflow>:
TRAPHANDLER_NOEC(Overflow, T_OFLOW);
f010486c:	6a 00                	push   $0x0
f010486e:	6a 04                	push   $0x4
f0104870:	eb 6c                	jmp    f01048de <_alltraps>

f0104872 <BOUND_Range_Exceeded>:
TRAPHANDLER_NOEC(BOUND_Range_Exceeded, T_BOUND);
f0104872:	6a 00                	push   $0x0
f0104874:	6a 05                	push   $0x5
f0104876:	eb 66                	jmp    f01048de <_alltraps>

f0104878 <Invalid_Opcode>:
TRAPHANDLER_NOEC(Invalid_Opcode, T_ILLOP);
f0104878:	6a 00                	push   $0x0
f010487a:	6a 06                	push   $0x6
f010487c:	eb 60                	jmp    f01048de <_alltraps>

f010487e <Device_Not_Available>:
TRAPHANDLER_NOEC(Device_Not_Available, T_DEVICE);
f010487e:	6a 00                	push   $0x0
f0104880:	6a 07                	push   $0x7
f0104882:	eb 5a                	jmp    f01048de <_alltraps>

f0104884 <Double_Fault>:
TRAPHANDLER(Double_Fault, T_DBLFLT);
f0104884:	6a 08                	push   $0x8
f0104886:	eb 56                	jmp    f01048de <_alltraps>

f0104888 <Invalid_TSS>:
TRAPHANDLER(Invalid_TSS, T_TSS);
f0104888:	6a 0a                	push   $0xa
f010488a:	eb 52                	jmp    f01048de <_alltraps>

f010488c <Segment_Not_Present>:
TRAPHANDLER(Segment_Not_Present, T_SEGNP);
f010488c:	6a 0b                	push   $0xb
f010488e:	eb 4e                	jmp    f01048de <_alltraps>

f0104890 <Stack_Fault>:
TRAPHANDLER(Stack_Fault, T_STACK);
f0104890:	6a 0c                	push   $0xc
f0104892:	eb 4a                	jmp    f01048de <_alltraps>

f0104894 <General_Protection>:
TRAPHANDLER(General_Protection, T_GPFLT);
f0104894:	6a 0d                	push   $0xd
f0104896:	eb 46                	jmp    f01048de <_alltraps>

f0104898 <Page_Fault>:
TRAPHANDLER(Page_Fault, T_PGFLT);
f0104898:	6a 0e                	push   $0xe
f010489a:	eb 42                	jmp    f01048de <_alltraps>

f010489c <x87_FPU_Floating_Point_Error>:
TRAPHANDLER_NOEC(x87_FPU_Floating_Point_Error, T_FPERR);
f010489c:	6a 00                	push   $0x0
f010489e:	6a 10                	push   $0x10
f01048a0:	eb 3c                	jmp    f01048de <_alltraps>

f01048a2 <Alignment_Check>:
TRAPHANDLER_NOEC(Alignment_Check, T_ALIGN);
f01048a2:	6a 00                	push   $0x0
f01048a4:	6a 11                	push   $0x11
f01048a6:	eb 36                	jmp    f01048de <_alltraps>

f01048a8 <Machine_Check>:
TRAPHANDLER_NOEC(Machine_Check, T_MCHK);
f01048a8:	6a 00                	push   $0x0
f01048aa:	6a 12                	push   $0x12
f01048ac:	eb 30                	jmp    f01048de <_alltraps>

f01048ae <SIMD_Floating_Point_Exception>:
TRAPHANDLER_NOEC(SIMD_Floating_Point_Exception, T_SIMDERR);
f01048ae:	6a 00                	push   $0x0
f01048b0:	6a 13                	push   $0x13
f01048b2:	eb 2a                	jmp    f01048de <_alltraps>

f01048b4 <System_call>:

TRAPHANDLER_NOEC(System_call,T_SYSCALL);
f01048b4:	6a 00                	push   $0x0
f01048b6:	6a 30                	push   $0x30
f01048b8:	eb 24                	jmp    f01048de <_alltraps>

f01048ba <IRQ_timer>:

TRAPHANDLER_NOEC(IRQ_timer,IRQ_OFFSET+IRQ_TIMER);
f01048ba:	6a 00                	push   $0x0
f01048bc:	6a 20                	push   $0x20
f01048be:	eb 1e                	jmp    f01048de <_alltraps>

f01048c0 <IRQ_kbd>:
TRAPHANDLER_NOEC(IRQ_kbd,IRQ_OFFSET+IRQ_KBD);
f01048c0:	6a 00                	push   $0x0
f01048c2:	6a 21                	push   $0x21
f01048c4:	eb 18                	jmp    f01048de <_alltraps>

f01048c6 <IRQ_serial>:
TRAPHANDLER_NOEC(IRQ_serial,IRQ_OFFSET+IRQ_SERIAL);
f01048c6:	6a 00                	push   $0x0
f01048c8:	6a 24                	push   $0x24
f01048ca:	eb 12                	jmp    f01048de <_alltraps>

f01048cc <IRQ_spurious>:
TRAPHANDLER_NOEC(IRQ_spurious,IRQ_OFFSET+IRQ_SPURIOUS);
f01048cc:	6a 00                	push   $0x0
f01048ce:	6a 27                	push   $0x27
f01048d0:	eb 0c                	jmp    f01048de <_alltraps>

f01048d2 <IRQ_ide>:
TRAPHANDLER_NOEC(IRQ_ide,IRQ_OFFSET+IRQ_IDE);
f01048d2:	6a 00                	push   $0x0
f01048d4:	6a 2e                	push   $0x2e
f01048d6:	eb 06                	jmp    f01048de <_alltraps>

f01048d8 <IRQ_error>:
TRAPHANDLER_NOEC(IRQ_error,IRQ_OFFSET+IRQ_ERROR);
f01048d8:	6a 00                	push   $0x0
f01048da:	6a 33                	push   $0x33
f01048dc:	eb 00                	jmp    f01048de <_alltraps>

f01048de <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
 _alltraps:
 	pushw   $0x0
f01048de:	66 6a 00             	pushw  $0x0
	pushw	%ds
f01048e1:	66 1e                	pushw  %ds
	pushw	$0x0
f01048e3:	66 6a 00             	pushw  $0x0
	pushw	%es	
f01048e6:	66 06                	pushw  %es
	pushal
f01048e8:	60                   	pusha  
	movl	$GD_KD, %eax /* GD_KD is kern data -- 0x10 */
f01048e9:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax, %ds
f01048ee:	8e d8                	mov    %eax,%ds
	movw	%ax, %es
f01048f0:	8e c0                	mov    %eax,%es
	pushl %esp
f01048f2:	54                   	push   %esp
	call trap
f01048f3:	e8 3b fd ff ff       	call   f0104633 <trap>

f01048f8 <sched_yield>:


// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01048f8:	55                   	push   %ebp
f01048f9:	89 e5                	mov    %esp,%ebp
f01048fb:	53                   	push   %ebx
f01048fc:	83 ec 24             	sub    $0x24,%esp
	// idle environment (env_type == ENV_TYPE_IDLE).  If there are
	// no runnable environments, simply drop through to the code
	// below to switch to this CPU's idle environment.
	
	// LAB 4: Your code here.
	e = curenv;
f01048ff:	e8 38 1b 00 00       	call   f010643c <cpunum>
f0104904:	6b c0 74             	imul   $0x74,%eax,%eax
    if(e == NULL)
f0104907:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
        e = envs;
f010490d:	85 c0                	test   %eax,%eax
f010490f:	0f 44 05 48 a2 22 f0 	cmove  0xf022a248,%eax

    for(i = 0; i < NENV ; i++, e++){
        if(e >= envs + NENV)
f0104916:	8b 1d 48 a2 22 f0    	mov    0xf022a248,%ebx
f010491c:	8d 8b 00 f0 01 00    	lea    0x1f000(%ebx),%ecx
f0104922:	ba 00 04 00 00       	mov    $0x400,%edx
            e = envs;
f0104927:	39 c1                	cmp    %eax,%ecx
f0104929:	0f 46 c3             	cmovbe %ebx,%eax
        if(e->env_status == ENV_RUNNABLE && e->env_type != ENV_TYPE_IDLE)
f010492c:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0104930:	75 0e                	jne    f0104940 <sched_yield+0x48>
f0104932:	83 78 50 01          	cmpl   $0x1,0x50(%eax)
f0104936:	74 08                	je     f0104940 <sched_yield+0x48>
            env_run(e);
f0104938:	89 04 24             	mov    %eax,(%esp)
f010493b:	e8 79 f1 ff ff       	call   f0103ab9 <env_run>
	// LAB 4: Your code here.
	e = curenv;
    if(e == NULL)
        e = envs;

    for(i = 0; i < NENV ; i++, e++){
f0104940:	83 c0 7c             	add    $0x7c,%eax
f0104943:	83 ea 01             	sub    $0x1,%edx
f0104946:	75 df                	jne    f0104927 <sched_yield+0x2f>
#include <kern/monitor.h>


// Choose a user environment to run and run it.
void
sched_yield(void)
f0104948:	8d 43 50             	lea    0x50(%ebx),%eax
f010494b:	ba 00 00 00 00       	mov    $0x0,%edx

	// For debugging and testing purposes, if there are no
	// runnable environments other than the idle environments,
	// drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if (envs[i].env_type != ENV_TYPE_IDLE &&
f0104950:	83 38 01             	cmpl   $0x1,(%eax)
f0104953:	74 0b                	je     f0104960 <sched_yield+0x68>
		    (envs[i].env_status == ENV_RUNNABLE ||
f0104955:	8b 48 04             	mov    0x4(%eax),%ecx
f0104958:	83 e9 02             	sub    $0x2,%ecx

	// For debugging and testing purposes, if there are no
	// runnable environments other than the idle environments,
	// drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if (envs[i].env_type != ENV_TYPE_IDLE &&
f010495b:	83 f9 01             	cmp    $0x1,%ecx
f010495e:	76 10                	jbe    f0104970 <sched_yield+0x78>


	// For debugging and testing purposes, if there are no
	// runnable environments other than the idle environments,
	// drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104960:	83 c2 01             	add    $0x1,%edx
f0104963:	83 c0 7c             	add    $0x7c,%eax
f0104966:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f010496c:	75 e2                	jne    f0104950 <sched_yield+0x58>
f010496e:	eb 08                	jmp    f0104978 <sched_yield+0x80>
		if (envs[i].env_type != ENV_TYPE_IDLE &&
		    (envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING))
			break;
	}
	if (i == NENV) {
f0104970:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f0104976:	75 1a                	jne    f0104992 <sched_yield+0x9a>
		cprintf("No more runnable environments!\n");
f0104978:	c7 04 24 f0 7f 10 f0 	movl   $0xf0107ff0,(%esp)
f010497f:	e8 72 f3 ff ff       	call   f0103cf6 <cprintf>
		while (1)
			monitor(NULL);
f0104984:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010498b:	e8 a2 c0 ff ff       	call   f0100a32 <monitor>
f0104990:	eb f2                	jmp    f0104984 <sched_yield+0x8c>
	}

	// Run this CPU's idle environment when nothing else is runnable.
	idle = &envs[cpunum()];
f0104992:	e8 a5 1a 00 00       	call   f010643c <cpunum>
f0104997:	6b c0 7c             	imul   $0x7c,%eax,%eax
f010499a:	01 d8                	add    %ebx,%eax
	if (!(idle->env_status == ENV_RUNNABLE || idle->env_status == ENV_RUNNING))
f010499c:	8b 58 54             	mov    0x54(%eax),%ebx
f010499f:	8d 53 fe             	lea    -0x2(%ebx),%edx
f01049a2:	83 fa 01             	cmp    $0x1,%edx
f01049a5:	76 29                	jbe    f01049d0 <sched_yield+0xd8>
		panic("CPU %d: No idle environment! %d", cpunum(), idle->env_status);
f01049a7:	e8 90 1a 00 00       	call   f010643c <cpunum>
f01049ac:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f01049b0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01049b4:	c7 44 24 08 10 80 10 	movl   $0xf0108010,0x8(%esp)
f01049bb:	f0 
f01049bc:	c7 44 24 04 3e 00 00 	movl   $0x3e,0x4(%esp)
f01049c3:	00 
f01049c4:	c7 04 24 30 80 10 f0 	movl   $0xf0108030,(%esp)
f01049cb:	e8 70 b6 ff ff       	call   f0100040 <_panic>
	env_run(idle);
f01049d0:	89 04 24             	mov    %eax,(%esp)
f01049d3:	e8 e1 f0 ff ff       	call   f0103ab9 <env_run>
f01049d8:	66 90                	xchg   %ax,%ax
f01049da:	66 90                	xchg   %ax,%ax
f01049dc:	66 90                	xchg   %ax,%ax
f01049de:	66 90                	xchg   %ax,%ax

f01049e0 <sys_page_unmap>:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
static int
sys_page_unmap(envid_t envid, void *va)
{
f01049e0:	55                   	push   %ebp
f01049e1:	89 e5                	mov    %esp,%ebp
f01049e3:	53                   	push   %ebx
f01049e4:	83 ec 24             	sub    $0x24,%esp
f01049e7:	89 d3                	mov    %edx,%ebx
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env *e;
	void *va_align = ROUNDDOWN(va, PGSIZE);
f01049e9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx

	if((size_t)va >= UTOP || va != va_align)
f01049ef:	39 d3                	cmp    %edx,%ebx
f01049f1:	75 3c                	jne    f0104a2f <sys_page_unmap+0x4f>
f01049f3:	81 fb ff ff bf ee    	cmp    $0xeebfffff,%ebx
f01049f9:	77 34                	ja     f0104a2f <sys_page_unmap+0x4f>
		return -E_INVAL;
	if(envid2env(envid, &e, 1))
f01049fb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104a02:	00 
f0104a03:	8d 55 f4             	lea    -0xc(%ebp),%edx
f0104a06:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104a0a:	89 04 24             	mov    %eax,(%esp)
f0104a0d:	e8 d3 e9 ff ff       	call   f01033e5 <envid2env>
f0104a12:	85 c0                	test   %eax,%eax
f0104a14:	75 20                	jne    f0104a36 <sys_page_unmap+0x56>
		return -E_BAD_ENV;
	page_remove(e->env_pgdir, va);
f0104a16:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104a1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a1d:	8b 40 60             	mov    0x60(%eax),%eax
f0104a20:	89 04 24             	mov    %eax,(%esp)
f0104a23:	e8 ef c9 ff ff       	call   f0101417 <page_remove>
	return 0;
f0104a28:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a2d:	eb 0c                	jmp    f0104a3b <sys_page_unmap+0x5b>
	// LAB 4: Your code here.
	struct Env *e;
	void *va_align = ROUNDDOWN(va, PGSIZE);

	if((size_t)va >= UTOP || va != va_align)
		return -E_INVAL;
f0104a2f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104a34:	eb 05                	jmp    f0104a3b <sys_page_unmap+0x5b>
	if(envid2env(envid, &e, 1))
		return -E_BAD_ENV;
f0104a36:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
	page_remove(e->env_pgdir, va);
	return 0;
	//panic("sys_page_unmap not implemented");
}
f0104a3b:	83 c4 24             	add    $0x24,%esp
f0104a3e:	5b                   	pop    %ebx
f0104a3f:	5d                   	pop    %ebp
f0104a40:	c3                   	ret    

f0104a41 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104a41:	55                   	push   %ebp
f0104a42:	89 e5                	mov    %esp,%ebp
f0104a44:	53                   	push   %ebx
f0104a45:	83 ec 24             	sub    $0x24,%esp
f0104a48:	8b 45 08             	mov    0x8(%ebp),%eax
	// SYS_ipc_try_send,
	// SYS_ipc_recv,
	// NSYSCALLS
	// };

	switch(syscallno){
f0104a4b:	83 f8 0c             	cmp    $0xc,%eax
f0104a4e:	0f 87 e9 05 00 00    	ja     f010503d <syscall+0x5fc>
f0104a54:	ff 24 85 70 80 10 f0 	jmp    *-0xfef7f90(,%eax,4)
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	/*user_mem_assert(struct Env *env, const void *va, size_t len, int perm)*/
	user_mem_assert(curenv, (const void *)s, len, PTE_U);
f0104a5b:	e8 dc 19 00 00       	call   f010643c <cpunum>
f0104a60:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104a67:	00 
f0104a68:	8b 55 10             	mov    0x10(%ebp),%edx
f0104a6b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104a6f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104a72:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104a76:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a79:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104a7f:	89 04 24             	mov    %eax,(%esp)
f0104a82:	e8 46 e8 ff ff       	call   f01032cd <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104a87:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a8a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104a8e:	8b 55 10             	mov    0x10(%ebp),%edx
f0104a91:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104a95:	c7 04 24 09 6f 10 f0 	movl   $0xf0106f09,(%esp)
f0104a9c:	e8 55 f2 ff ff       	call   f0103cf6 <cprintf>
	// SYS_ipc_recv,
	// NSYSCALLS
	// };

	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
f0104aa1:	b8 00 00 00 00       	mov    $0x0,%eax
f0104aa6:	e9 9e 05 00 00       	jmp    f0105049 <syscall+0x608>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104aab:	e8 d2 bb ff ff       	call   f0100682 <cons_getc>
	// NSYSCALLS
	// };

	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
		case SYS_cgetc: return sys_cgetc();
f0104ab0:	e9 94 05 00 00       	jmp    f0105049 <syscall+0x608>
    
// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104ab5:	e8 82 19 00 00       	call   f010643c <cpunum>
f0104aba:	6b c0 74             	imul   $0x74,%eax,%eax
f0104abd:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104ac3:	8b 40 48             	mov    0x48(%eax),%eax
	// };

	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
		case SYS_cgetc: return sys_cgetc();
		case SYS_getenvid: return sys_getenvid();
f0104ac6:	e9 7e 05 00 00       	jmp    f0105049 <syscall+0x608>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104acb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104ad2:	00 
f0104ad3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104ad6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ada:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104add:	89 0c 24             	mov    %ecx,(%esp)
f0104ae0:	e8 00 e9 ff ff       	call   f01033e5 <envid2env>
f0104ae5:	85 c0                	test   %eax,%eax
f0104ae7:	0f 88 5c 05 00 00    	js     f0105049 <syscall+0x608>
		return r;
	if (e == curenv)
f0104aed:	e8 4a 19 00 00       	call   f010643c <cpunum>
f0104af2:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104af5:	6b c0 74             	imul   $0x74,%eax,%eax
f0104af8:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f0104afe:	75 23                	jne    f0104b23 <syscall+0xe2>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104b00:	e8 37 19 00 00       	call   f010643c <cpunum>
f0104b05:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b08:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104b0e:	8b 40 48             	mov    0x48(%eax),%eax
f0104b11:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b15:	c7 04 24 3d 80 10 f0 	movl   $0xf010803d,(%esp)
f0104b1c:	e8 d5 f1 ff ff       	call   f0103cf6 <cprintf>
f0104b21:	eb 28                	jmp    f0104b4b <syscall+0x10a>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104b23:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104b26:	e8 11 19 00 00       	call   f010643c <cpunum>
f0104b2b:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104b2f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b32:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104b38:	8b 40 48             	mov    0x48(%eax),%eax
f0104b3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b3f:	c7 04 24 58 80 10 f0 	movl   $0xf0108058,(%esp)
f0104b46:	e8 ab f1 ff ff       	call   f0103cf6 <cprintf>
	env_destroy(e);
f0104b4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104b4e:	89 04 24             	mov    %eax,(%esp)
f0104b51:	e8 c2 ee ff ff       	call   f0103a18 <env_destroy>
	return 0;
f0104b56:	b8 00 00 00 00       	mov    $0x0,%eax

	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
		case SYS_cgetc: return sys_cgetc();
		case SYS_getenvid: return sys_getenvid();
		case SYS_env_destroy: return sys_env_destroy((envid_t)a1);
f0104b5b:	e9 e9 04 00 00       	jmp    f0105049 <syscall+0x608>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104b60:	e8 93 fd ff ff       	call   f01048f8 <sched_yield>
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *new_env;
	int r;
	if((r = env_alloc(&new_env, curenv->env_id)))
f0104b65:	e8 d2 18 00 00       	call   f010643c <cpunum>
f0104b6a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b6d:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104b73:	8b 40 48             	mov    0x48(%eax),%eax
f0104b76:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b7a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104b7d:	89 04 24             	mov    %eax,(%esp)
f0104b80:	e8 7b e9 ff ff       	call   f0103500 <env_alloc>
f0104b85:	85 c0                	test   %eax,%eax
f0104b87:	0f 85 bc 04 00 00    	jne    f0105049 <syscall+0x608>
		return r;

	/* set status */
	new_env -> env_status = ENV_NOT_RUNNABLE;
f0104b8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104b90:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	/* copy the register */
	memmove(&(new_env->env_tf), &(curenv -> env_tf), sizeof(struct Trapframe));
f0104b97:	e8 a0 18 00 00       	call   f010643c <cpunum>
f0104b9c:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0104ba3:	00 
f0104ba4:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ba7:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104bad:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104bb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104bb4:	89 04 24             	mov    %eax,(%esp)
f0104bb7:	e8 37 12 00 00       	call   f0105df3 <memmove>
	/* set the return value */
	new_env -> env_tf.tf_regs.reg_eax = 0;
f0104bbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104bbf:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return new_env -> env_id;
f0104bc6:	8b 40 48             	mov    0x48(%eax),%eax
		case SYS_getenvid: return sys_getenvid();
		case SYS_env_destroy: return sys_env_destroy((envid_t)a1);
		//case NSYSCALLS: NSYSCALLS();break;
		case SYS_yield: sys_yield();return 0;
		// fork functions in Lab4
		case SYS_exofork: return sys_exofork();
f0104bc9:	e9 7b 04 00 00       	jmp    f0105049 <syscall+0x608>
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	struct Env *e;
	if(! (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE))
f0104bce:	83 7d 10 04          	cmpl   $0x4,0x10(%ebp)
f0104bd2:	74 06                	je     f0104bda <syscall+0x199>
f0104bd4:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
f0104bd8:	75 31                	jne    f0104c0b <syscall+0x1ca>
		return -E_INVAL;
	if(envid2env(envid, &e, 1))
f0104bda:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104be1:	00 
f0104be2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104be5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104be9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104bec:	89 04 24             	mov    %eax,(%esp)
f0104bef:	e8 f1 e7 ff ff       	call   f01033e5 <envid2env>
f0104bf4:	85 c0                	test   %eax,%eax
f0104bf6:	75 1d                	jne    f0104c15 <syscall+0x1d4>
		return -E_BAD_ENV;
	e -> env_status = status;
f0104bf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104bfb:	8b 55 10             	mov    0x10(%ebp),%edx
f0104bfe:	89 50 54             	mov    %edx,0x54(%eax)
	return 0;
f0104c01:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c06:	e9 3e 04 00 00       	jmp    f0105049 <syscall+0x608>
	// envid's status.

	// LAB 4: Your code here.
	struct Env *e;
	if(! (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE))
		return -E_INVAL;
f0104c0b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104c10:	e9 34 04 00 00       	jmp    f0105049 <syscall+0x608>
	if(envid2env(envid, &e, 1))
		return -E_BAD_ENV;
f0104c15:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
		case SYS_env_destroy: return sys_env_destroy((envid_t)a1);
		//case NSYSCALLS: NSYSCALLS();break;
		case SYS_yield: sys_yield();return 0;
		// fork functions in Lab4
		case SYS_exofork: return sys_exofork();
		case SYS_env_set_status: return sys_env_set_status((envid_t)a1, (int)a2);
f0104c1a:	e9 2a 04 00 00       	jmp    f0105049 <syscall+0x608>
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	struct Env *e;
	void *va_align = ROUNDDOWN(va, PGSIZE);
f0104c1f:	8b 55 10             	mov    0x10(%ebp),%edx
f0104c22:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	struct Page *p;

	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104c28:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c2b:	83 e0 05             	and    $0x5,%eax
f0104c2e:	83 f8 05             	cmp    $0x5,%eax
f0104c31:	74 0f                	je     f0104c42 <syscall+0x201>
		(perm|PTE_AVAIL|PTE_W)!=(PTE_U|PTE_P|PTE_AVAIL|PTE_W))
f0104c33:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c36:	0d 02 0e 00 00       	or     $0xe02,%eax
	// LAB 4: Your code here.
	struct Env *e;
	void *va_align = ROUNDDOWN(va, PGSIZE);
	struct Page *p;

	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104c3b:	3d 07 0e 00 00       	cmp    $0xe07,%eax
f0104c40:	75 74                	jne    f0104cb6 <syscall+0x275>
		(perm|PTE_AVAIL|PTE_W)!=(PTE_U|PTE_P|PTE_AVAIL|PTE_W))
		return -E_INVAL;
	if((size_t)va >= UTOP || va != va_align)
f0104c42:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104c45:	75 79                	jne    f0104cc0 <syscall+0x27f>
f0104c47:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104c4e:	77 70                	ja     f0104cc0 <syscall+0x27f>
		return -E_INVAL;
	if(envid2env(envid, &e, 1))
f0104c50:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104c57:	00 
f0104c58:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104c5b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c5f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c62:	89 0c 24             	mov    %ecx,(%esp)
f0104c65:	e8 7b e7 ff ff       	call   f01033e5 <envid2env>
f0104c6a:	85 c0                	test   %eax,%eax
f0104c6c:	75 5c                	jne    f0104cca <syscall+0x289>
		return -E_BAD_ENV;
	if((p = page_alloc(ALLOC_ZERO)) == NULL) /* alloc a page */
f0104c6e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0104c75:	e8 e5 c4 ff ff       	call   f010115f <page_alloc>
f0104c7a:	89 c3                	mov    %eax,%ebx
f0104c7c:	85 c0                	test   %eax,%eax
f0104c7e:	74 54                	je     f0104cd4 <syscall+0x293>
		return -E_NO_MEM;
	if(page_insert(e->env_pgdir, p, va, perm)){
f0104c80:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c83:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104c87:	8b 55 10             	mov    0x10(%ebp),%edx
f0104c8a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104c8e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104c92:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104c95:	8b 40 60             	mov    0x60(%eax),%eax
f0104c98:	89 04 24             	mov    %eax,(%esp)
f0104c9b:	e8 c7 c7 ff ff       	call   f0101467 <page_insert>
f0104ca0:	85 c0                	test   %eax,%eax
f0104ca2:	74 3a                	je     f0104cde <syscall+0x29d>
		page_free(p);
f0104ca4:	89 1c 24             	mov    %ebx,(%esp)
f0104ca7:	e8 37 c5 ff ff       	call   f01011e3 <page_free>
		return -E_NO_MEM;
f0104cac:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104cb1:	e9 93 03 00 00       	jmp    f0105049 <syscall+0x608>
	void *va_align = ROUNDDOWN(va, PGSIZE);
	struct Page *p;

	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
		(perm|PTE_AVAIL|PTE_W)!=(PTE_U|PTE_P|PTE_AVAIL|PTE_W))
		return -E_INVAL;
f0104cb6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104cbb:	e9 89 03 00 00       	jmp    f0105049 <syscall+0x608>
	if((size_t)va >= UTOP || va != va_align)
		return -E_INVAL;
f0104cc0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104cc5:	e9 7f 03 00 00       	jmp    f0105049 <syscall+0x608>
	if(envid2env(envid, &e, 1))
		return -E_BAD_ENV;
f0104cca:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104ccf:	e9 75 03 00 00       	jmp    f0105049 <syscall+0x608>
	if((p = page_alloc(ALLOC_ZERO)) == NULL) /* alloc a page */
		return -E_NO_MEM;
f0104cd4:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104cd9:	e9 6b 03 00 00       	jmp    f0105049 <syscall+0x608>
	}
	// if(sys_page_unmap(envid, va))
	// 	return -E_NO_MEM;
	// if(sys_page_map(envid, page2kva(p),envid,va,perm))
	// 	return -E_NO_MEM;
	return 0;
f0104cde:	b8 00 00 00 00       	mov    $0x0,%eax
		//case NSYSCALLS: NSYSCALLS();break;
		case SYS_yield: sys_yield();return 0;
		// fork functions in Lab4
		case SYS_exofork: return sys_exofork();
		case SYS_env_set_status: return sys_env_set_status((envid_t)a1, (int)a2);
		case SYS_page_alloc: return sys_page_alloc((envid_t)a1, (void *)a2, (int)a3);
f0104ce3:	e9 61 03 00 00       	jmp    f0105049 <syscall+0x608>
	struct Env *src_e, *dst_e;
	struct Page *p;
	pte_t *pte;

	/* check perm */
	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104ce8:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104ceb:	83 e0 05             	and    $0x5,%eax
f0104cee:	83 f8 05             	cmp    $0x5,%eax
f0104cf1:	74 11                	je     f0104d04 <syscall+0x2c3>
		(perm|PTE_AVAIL)!=(PTE_U|PTE_P|PTE_AVAIL))
f0104cf3:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104cf6:	80 cc 0e             	or     $0xe,%ah
	struct Env *src_e, *dst_e;
	struct Page *p;
	pte_t *pte;

	/* check perm */
	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104cf9:	3d 05 0e 00 00       	cmp    $0xe05,%eax
f0104cfe:	0f 85 c5 00 00 00    	jne    f0104dc9 <syscall+0x388>
		(perm|PTE_AVAIL)!=(PTE_U|PTE_P|PTE_AVAIL))
		return -E_INVAL;

	/* check vas */
	va_align = ROUNDDOWN(srcva, PGSIZE);
f0104d04:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d07:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if((size_t)srcva >= UTOP || srcva != va_align)
f0104d0c:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104d0f:	0f 85 be 00 00 00    	jne    f0104dd3 <syscall+0x392>
f0104d15:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104d1c:	0f 87 b1 00 00 00    	ja     f0104dd3 <syscall+0x392>
		return -E_INVAL;
	va_align = ROUNDDOWN(dstva, PGSIZE);
f0104d22:	8b 45 18             	mov    0x18(%ebp),%eax
f0104d25:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if((size_t)dstva >= UTOP || dstva != va_align)
f0104d2a:	39 45 18             	cmp    %eax,0x18(%ebp)
f0104d2d:	0f 85 aa 00 00 00    	jne    f0104ddd <syscall+0x39c>
f0104d33:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104d3a:	0f 87 9d 00 00 00    	ja     f0104ddd <syscall+0x39c>
		return -E_INVAL;

	if(envid2env(srcenvid, &src_e, 1)|envid2env(dstenvid, &dst_e, 1))
f0104d40:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104d47:	00 
f0104d48:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104d4b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d4f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104d52:	89 0c 24             	mov    %ecx,(%esp)
f0104d55:	e8 8b e6 ff ff       	call   f01033e5 <envid2env>
f0104d5a:	89 c3                	mov    %eax,%ebx
f0104d5c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104d63:	00 
f0104d64:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0104d67:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d6e:	89 04 24             	mov    %eax,(%esp)
f0104d71:	e8 6f e6 ff ff       	call   f01033e5 <envid2env>
f0104d76:	09 d8                	or     %ebx,%eax
f0104d78:	75 6d                	jne    f0104de7 <syscall+0x3a6>
		return -E_BAD_ENV;

	if((p = page_lookup(src_e->env_pgdir, srcva, &pte)) == NULL)
f0104d7a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104d7d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104d81:	8b 55 10             	mov    0x10(%ebp),%edx
f0104d84:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104d88:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104d8b:	8b 40 60             	mov    0x60(%eax),%eax
f0104d8e:	89 04 24             	mov    %eax,(%esp)
f0104d91:	e8 d3 c5 ff ff       	call   f0101369 <page_lookup>
f0104d96:	85 c0                	test   %eax,%eax
f0104d98:	74 57                	je     f0104df1 <syscall+0x3b0>
		return -E_INVAL;
	if(page_insert(dst_e->env_pgdir, p,dstva, perm))
f0104d9a:	8b 4d 1c             	mov    0x1c(%ebp),%ecx
f0104d9d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104da1:	8b 55 18             	mov    0x18(%ebp),%edx
f0104da4:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104da8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104dac:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104daf:	8b 40 60             	mov    0x60(%eax),%eax
f0104db2:	89 04 24             	mov    %eax,(%esp)
f0104db5:	e8 ad c6 ff ff       	call   f0101467 <page_insert>
		return -E_NO_MEM;
f0104dba:	83 f8 01             	cmp    $0x1,%eax
f0104dbd:	19 c0                	sbb    %eax,%eax
f0104dbf:	f7 d0                	not    %eax
f0104dc1:	83 e0 fc             	and    $0xfffffffc,%eax
f0104dc4:	e9 80 02 00 00       	jmp    f0105049 <syscall+0x608>
	pte_t *pte;

	/* check perm */
	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
		(perm|PTE_AVAIL)!=(PTE_U|PTE_P|PTE_AVAIL))
		return -E_INVAL;
f0104dc9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104dce:	e9 76 02 00 00       	jmp    f0105049 <syscall+0x608>

	/* check vas */
	va_align = ROUNDDOWN(srcva, PGSIZE);
	if((size_t)srcva >= UTOP || srcva != va_align)
		return -E_INVAL;
f0104dd3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104dd8:	e9 6c 02 00 00       	jmp    f0105049 <syscall+0x608>
	va_align = ROUNDDOWN(dstva, PGSIZE);
	if((size_t)dstva >= UTOP || dstva != va_align)
		return -E_INVAL;
f0104ddd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104de2:	e9 62 02 00 00       	jmp    f0105049 <syscall+0x608>

	if(envid2env(srcenvid, &src_e, 1)|envid2env(dstenvid, &dst_e, 1))
		return -E_BAD_ENV;
f0104de7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104dec:	e9 58 02 00 00       	jmp    f0105049 <syscall+0x608>

	if((p = page_lookup(src_e->env_pgdir, srcva, &pte)) == NULL)
		return -E_INVAL;
f0104df1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104df6:	e9 4e 02 00 00       	jmp    f0105049 <syscall+0x608>
		case SYS_exofork: return sys_exofork();
		case SYS_env_set_status: return sys_env_set_status((envid_t)a1, (int)a2);
		case SYS_page_alloc: return sys_page_alloc((envid_t)a1, (void *)a2, (int)a3);
		case SYS_page_map: return sys_page_map((envid_t)a1, (void *)a2,
	     (envid_t)a3, (void *)a4, (int)a5);
		case SYS_page_unmap: return sys_page_unmap((envid_t)a1, (void *)a2);
f0104dfb:	8b 55 10             	mov    0x10(%ebp),%edx
f0104dfe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104e01:	e8 da fb ff ff       	call   f01049e0 <sys_page_unmap>
f0104e06:	e9 3e 02 00 00       	jmp    f0105049 <syscall+0x608>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *e;
	if(envid2env(envid, &e, 1))
f0104e0b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104e12:	00 
f0104e13:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104e16:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e1a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104e1d:	89 0c 24             	mov    %ecx,(%esp)
f0104e20:	e8 c0 e5 ff ff       	call   f01033e5 <envid2env>
f0104e25:	85 c0                	test   %eax,%eax
f0104e27:	75 13                	jne    f0104e3c <syscall+0x3fb>
		return -E_BAD_ENV;
	e->env_pgfault_upcall = func;
f0104e29:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104e2c:	8b 55 10             	mov    0x10(%ebp),%edx
f0104e2f:	89 50 64             	mov    %edx,0x64(%eax)
	return 0;
f0104e32:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e37:	e9 0d 02 00 00       	jmp    f0105049 <syscall+0x608>
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *e;
	if(envid2env(envid, &e, 1))
		return -E_BAD_ENV;
f0104e3c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
		case SYS_env_set_status: return sys_env_set_status((envid_t)a1, (int)a2);
		case SYS_page_alloc: return sys_page_alloc((envid_t)a1, (void *)a2, (int)a3);
		case SYS_page_map: return sys_page_map((envid_t)a1, (void *)a2,
	     (envid_t)a3, (void *)a4, (int)a5);
		case SYS_page_unmap: return sys_page_unmap((envid_t)a1, (void *)a2);
		case SYS_env_set_pgfault_upcall: return sys_env_set_pgfault_upcall((envid_t)a1, (void *)a2);
f0104e41:	e9 03 02 00 00       	jmp    f0105049 <syscall+0x608>
	// LAB 4: Your code here.
	struct Page *p;
	pte_t *pte;
	struct Env *e;

	if(envid2env(envid, &e, 0))
f0104e46:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0104e4d:	00 
f0104e4e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104e51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e55:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104e58:	89 0c 24             	mov    %ecx,(%esp)
f0104e5b:	e8 85 e5 ff ff       	call   f01033e5 <envid2env>
f0104e60:	85 c0                	test   %eax,%eax
f0104e62:	0f 85 fe 00 00 00    	jne    f0104f66 <syscall+0x525>
		return -E_BAD_ENV;
	if((!e -> env_ipc_recving) || e->env_ipc_from > 0)
f0104e68:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104e6b:	83 78 68 00          	cmpl   $0x0,0x68(%eax)
f0104e6f:	0f 84 fb 00 00 00    	je     f0104f70 <syscall+0x52f>
f0104e75:	83 78 74 00          	cmpl   $0x0,0x74(%eax)
f0104e79:	0f 8f fb 00 00 00    	jg     f0104f7a <syscall+0x539>
		return -E_IPC_NOT_RECV;
	if(srcva < (void *)UTOP){
f0104e7f:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104e86:	0f 87 9b 00 00 00    	ja     f0104f27 <syscall+0x4e6>
		if(ROUNDDOWN(srcva, PGSIZE) != srcva)
f0104e8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e8f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104e94:	39 45 14             	cmp    %eax,0x14(%ebp)
f0104e97:	0f 85 e7 00 00 00    	jne    f0104f84 <syscall+0x543>
			return -E_INVAL;
		if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104e9d:	8b 45 18             	mov    0x18(%ebp),%eax
f0104ea0:	83 e0 05             	and    $0x5,%eax
f0104ea3:	83 f8 05             	cmp    $0x5,%eax
f0104ea6:	74 13                	je     f0104ebb <syscall+0x47a>
			(perm|PTE_AVAIL|PTE_W)!=(PTE_U|PTE_P|PTE_AVAIL|PTE_W))
f0104ea8:	8b 45 18             	mov    0x18(%ebp),%eax
f0104eab:	0d 02 0e 00 00       	or     $0xe02,%eax
	if((!e -> env_ipc_recving) || e->env_ipc_from > 0)
		return -E_IPC_NOT_RECV;
	if(srcva < (void *)UTOP){
		if(ROUNDDOWN(srcva, PGSIZE) != srcva)
			return -E_INVAL;
		if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104eb0:	3d 07 0e 00 00       	cmp    $0xe07,%eax
f0104eb5:	0f 85 d3 00 00 00    	jne    f0104f8e <syscall+0x54d>
			(perm|PTE_AVAIL|PTE_W)!=(PTE_U|PTE_P|PTE_AVAIL|PTE_W))
			return -E_INVAL;
		if((p = page_lookup(curenv->env_pgdir, srcva, &pte)) == NULL)
f0104ebb:	e8 7c 15 00 00       	call   f010643c <cpunum>
f0104ec0:	8d 55 f0             	lea    -0x10(%ebp),%edx
f0104ec3:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104ec7:	8b 55 14             	mov    0x14(%ebp),%edx
f0104eca:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104ece:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ed1:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104ed7:	8b 40 60             	mov    0x60(%eax),%eax
f0104eda:	89 04 24             	mov    %eax,(%esp)
f0104edd:	e8 87 c4 ff ff       	call   f0101369 <page_lookup>
f0104ee2:	85 c0                	test   %eax,%eax
f0104ee4:	0f 84 ae 00 00 00    	je     f0104f98 <syscall+0x557>
			return -E_INVAL;
		if(!(*pte & PTE_W))
f0104eea:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0104eed:	f6 02 02             	testb  $0x2,(%edx)
f0104ef0:	0f 84 ac 00 00 00    	je     f0104fa2 <syscall+0x561>
			return -E_INVAL;
		// if(sys_page_map(curenv->env_id, srcva, envid, e->env_ipc_dstva, perm))
		if(page_insert(e->env_pgdir, p, e -> env_ipc_dstva, perm) < 0)
f0104ef6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104ef9:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104efc:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104f00:	8b 4a 6c             	mov    0x6c(%edx),%ecx
f0104f03:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104f07:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f0b:	8b 42 60             	mov    0x60(%edx),%eax
f0104f0e:	89 04 24             	mov    %eax,(%esp)
f0104f11:	e8 51 c5 ff ff       	call   f0101467 <page_insert>
f0104f16:	85 c0                	test   %eax,%eax
f0104f18:	0f 88 8e 00 00 00    	js     f0104fac <syscall+0x56b>
			return -E_NO_MEM;
		e -> env_ipc_perm = perm;
f0104f1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104f21:	8b 55 18             	mov    0x18(%ebp),%edx
f0104f24:	89 50 78             	mov    %edx,0x78(%eax)
	}
	e -> env_ipc_recving = 0;
f0104f27:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104f2a:	c7 43 68 00 00 00 00 	movl   $0x0,0x68(%ebx)
    e -> env_ipc_from = curenv -> env_id;
f0104f31:	e8 06 15 00 00       	call   f010643c <cpunum>
f0104f36:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f39:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104f3f:	8b 40 48             	mov    0x48(%eax),%eax
f0104f42:	89 43 74             	mov    %eax,0x74(%ebx)
    e -> env_ipc_value = value;
f0104f45:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104f48:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104f4b:	89 48 70             	mov    %ecx,0x70(%eax)
    e -> env_status = ENV_RUNNABLE;
f0104f4e:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
    e -> env_tf.tf_regs.reg_eax = 0;
f0104f55:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	//panic("sys_ipc_try_send not implemented");
	return 0;
f0104f5c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f61:	e9 e3 00 00 00       	jmp    f0105049 <syscall+0x608>
	struct Page *p;
	pte_t *pte;
	struct Env *e;

	if(envid2env(envid, &e, 0))
		return -E_BAD_ENV;
f0104f66:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104f6b:	e9 d9 00 00 00       	jmp    f0105049 <syscall+0x608>
	if((!e -> env_ipc_recving) || e->env_ipc_from > 0)
		return -E_IPC_NOT_RECV;
f0104f70:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
f0104f75:	e9 cf 00 00 00       	jmp    f0105049 <syscall+0x608>
f0104f7a:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
f0104f7f:	e9 c5 00 00 00       	jmp    f0105049 <syscall+0x608>
	if(srcva < (void *)UTOP){
		if(ROUNDDOWN(srcva, PGSIZE) != srcva)
			return -E_INVAL;
f0104f84:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104f89:	e9 bb 00 00 00       	jmp    f0105049 <syscall+0x608>
		if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
			(perm|PTE_AVAIL|PTE_W)!=(PTE_U|PTE_P|PTE_AVAIL|PTE_W))
			return -E_INVAL;
f0104f8e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104f93:	e9 b1 00 00 00       	jmp    f0105049 <syscall+0x608>
		if((p = page_lookup(curenv->env_pgdir, srcva, &pte)) == NULL)
			return -E_INVAL;
f0104f98:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104f9d:	e9 a7 00 00 00       	jmp    f0105049 <syscall+0x608>
		if(!(*pte & PTE_W))
			return -E_INVAL;
f0104fa2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104fa7:	e9 9d 00 00 00       	jmp    f0105049 <syscall+0x608>
		// if(sys_page_map(curenv->env_id, srcva, envid, e->env_ipc_dstva, perm))
		if(page_insert(e->env_pgdir, p, e -> env_ipc_dstva, perm) < 0)
			return -E_NO_MEM;
f0104fac:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		case SYS_page_alloc: return sys_page_alloc((envid_t)a1, (void *)a2, (int)a3);
		case SYS_page_map: return sys_page_map((envid_t)a1, (void *)a2,
	     (envid_t)a3, (void *)a4, (int)a5);
		case SYS_page_unmap: return sys_page_unmap((envid_t)a1, (void *)a2);
		case SYS_env_set_pgfault_upcall: return sys_env_set_pgfault_upcall((envid_t)a1, (void *)a2);
		case SYS_ipc_try_send: return sys_ipc_try_send((envid_t)a1, a2, (void *)a3, (unsigned)a4);
f0104fb1:	e9 93 00 00 00       	jmp    f0105049 <syscall+0x608>
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
	if(dstva < (void *)UTOP && (ROUNDDOWN(dstva, PGSIZE) != dstva))
f0104fb6:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0104fbd:	77 0d                	ja     f0104fcc <syscall+0x58b>
f0104fbf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104fc2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104fc7:	39 45 0c             	cmp    %eax,0xc(%ebp)
f0104fca:	75 78                	jne    f0105044 <syscall+0x603>
		return -E_INVAL;

	/* unmap the previous page */
	sys_page_unmap(curenv -> env_id, dstva);
f0104fcc:	e8 6b 14 00 00       	call   f010643c <cpunum>
f0104fd1:	6b c0 74             	imul   $0x74,%eax,%eax
f0104fd4:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104fda:	8b 40 48             	mov    0x48(%eax),%eax
f0104fdd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104fe0:	e8 fb f9 ff ff       	call   f01049e0 <sys_page_unmap>

	curenv -> env_status = ENV_NOT_RUNNABLE;
f0104fe5:	e8 52 14 00 00       	call   f010643c <cpunum>
f0104fea:	6b c0 74             	imul   $0x74,%eax,%eax
f0104fed:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104ff3:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	curenv -> env_ipc_recving = 1;
f0104ffa:	e8 3d 14 00 00       	call   f010643c <cpunum>
f0104fff:	6b c0 74             	imul   $0x74,%eax,%eax
f0105002:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0105008:	c7 40 68 01 00 00 00 	movl   $0x1,0x68(%eax)
	curenv -> env_ipc_from = 0;
f010500f:	e8 28 14 00 00       	call   f010643c <cpunum>
f0105014:	6b c0 74             	imul   $0x74,%eax,%eax
f0105017:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010501d:	c7 40 74 00 00 00 00 	movl   $0x0,0x74(%eax)
	curenv -> env_ipc_dstva = dstva;
f0105024:	e8 13 14 00 00       	call   f010643c <cpunum>
f0105029:	6b c0 74             	imul   $0x74,%eax,%eax
f010502c:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0105032:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105035:	89 50 6c             	mov    %edx,0x6c(%eax)
	sched_yield();
f0105038:	e8 bb f8 ff ff       	call   f01048f8 <sched_yield>
	     (envid_t)a3, (void *)a4, (int)a5);
		case SYS_page_unmap: return sys_page_unmap((envid_t)a1, (void *)a2);
		case SYS_env_set_pgfault_upcall: return sys_env_set_pgfault_upcall((envid_t)a1, (void *)a2);
		case SYS_ipc_try_send: return sys_ipc_try_send((envid_t)a1, a2, (void *)a3, (unsigned)a4);
		case SYS_ipc_recv:return sys_ipc_recv((void *)a1);
		default: return -E_INVAL;
f010503d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105042:	eb 05                	jmp    f0105049 <syscall+0x608>
		case SYS_page_map: return sys_page_map((envid_t)a1, (void *)a2,
	     (envid_t)a3, (void *)a4, (int)a5);
		case SYS_page_unmap: return sys_page_unmap((envid_t)a1, (void *)a2);
		case SYS_env_set_pgfault_upcall: return sys_env_set_pgfault_upcall((envid_t)a1, (void *)a2);
		case SYS_ipc_try_send: return sys_ipc_try_send((envid_t)a1, a2, (void *)a3, (unsigned)a4);
		case SYS_ipc_recv:return sys_ipc_recv((void *)a1);
f0105044:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		default: return -E_INVAL;
	}
	//panic("current %d", syscallno);

	//panic("syscall not implemented");
}
f0105049:	83 c4 24             	add    $0x24,%esp
f010504c:	5b                   	pop    %ebx
f010504d:	5d                   	pop    %ebp
f010504e:	c3                   	ret    
f010504f:	90                   	nop

f0105050 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0105050:	55                   	push   %ebp
f0105051:	89 e5                	mov    %esp,%ebp
f0105053:	57                   	push   %edi
f0105054:	56                   	push   %esi
f0105055:	53                   	push   %ebx
f0105056:	83 ec 14             	sub    $0x14,%esp
f0105059:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010505c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010505f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0105062:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0105065:	8b 1a                	mov    (%edx),%ebx
f0105067:	8b 01                	mov    (%ecx),%eax
f0105069:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f010506c:	39 c3                	cmp    %eax,%ebx
f010506e:	0f 8f 9f 00 00 00    	jg     f0105113 <stab_binsearch+0xc3>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0105074:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f010507b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010507e:	01 d8                	add    %ebx,%eax
f0105080:	89 c7                	mov    %eax,%edi
f0105082:	c1 ef 1f             	shr    $0x1f,%edi
f0105085:	01 c7                	add    %eax,%edi
f0105087:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0105089:	39 df                	cmp    %ebx,%edi
f010508b:	0f 8c ce 00 00 00    	jl     f010515f <stab_binsearch+0x10f>
f0105091:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0105094:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0105097:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f010509c:	39 f0                	cmp    %esi,%eax
f010509e:	0f 84 c0 00 00 00    	je     f0105164 <stab_binsearch+0x114>
f01050a4:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01050a8:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f01050ac:	89 f8                	mov    %edi,%eax
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01050ae:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01050b1:	39 d8                	cmp    %ebx,%eax
f01050b3:	0f 8c a6 00 00 00    	jl     f010515f <stab_binsearch+0x10f>
f01050b9:	0f b6 0a             	movzbl (%edx),%ecx
f01050bc:	83 ea 0c             	sub    $0xc,%edx
f01050bf:	39 f1                	cmp    %esi,%ecx
f01050c1:	75 eb                	jne    f01050ae <stab_binsearch+0x5e>
f01050c3:	e9 9e 00 00 00       	jmp    f0105166 <stab_binsearch+0x116>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01050c8:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01050cb:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f01050cd:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01050d0:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01050d7:	eb 2b                	jmp    f0105104 <stab_binsearch+0xb4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01050d9:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01050dc:	76 14                	jbe    f01050f2 <stab_binsearch+0xa2>
			*region_right = m - 1;
f01050de:	83 e8 01             	sub    $0x1,%eax
f01050e1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01050e4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01050e7:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01050e9:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01050f0:	eb 12                	jmp    f0105104 <stab_binsearch+0xb4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01050f2:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01050f5:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f01050f7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01050fb:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01050fd:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0105104:	3b 5d ec             	cmp    -0x14(%ebp),%ebx
f0105107:	0f 8e 6e ff ff ff    	jle    f010507b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010510d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105111:	75 0f                	jne    f0105122 <stab_binsearch+0xd2>
		*region_right = *region_left - 1;
f0105113:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0105116:	8b 02                	mov    (%edx),%eax
f0105118:	83 e8 01             	sub    $0x1,%eax
f010511b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010511e:	89 01                	mov    %eax,(%ecx)
f0105120:	eb 5c                	jmp    f010517e <stab_binsearch+0x12e>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0105122:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0105125:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0105127:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010512a:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010512c:	39 c8                	cmp    %ecx,%eax
f010512e:	7e 28                	jle    f0105158 <stab_binsearch+0x108>
		     l > *region_left && stabs[l].n_type != type;
f0105130:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105133:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0105136:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f010513b:	39 f2                	cmp    %esi,%edx
f010513d:	74 19                	je     f0105158 <stab_binsearch+0x108>
f010513f:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0105143:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0105147:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010514a:	39 c8                	cmp    %ecx,%eax
f010514c:	7e 0a                	jle    f0105158 <stab_binsearch+0x108>
		     l > *region_left && stabs[l].n_type != type;
f010514e:	0f b6 1a             	movzbl (%edx),%ebx
f0105151:	83 ea 0c             	sub    $0xc,%edx
f0105154:	39 f3                	cmp    %esi,%ebx
f0105156:	75 ef                	jne    f0105147 <stab_binsearch+0xf7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0105158:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010515b:	89 02                	mov    %eax,(%edx)
f010515d:	eb 1f                	jmp    f010517e <stab_binsearch+0x12e>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010515f:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0105162:	eb a0                	jmp    f0105104 <stab_binsearch+0xb4>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0105164:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0105166:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105169:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f010516c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0105170:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0105173:	0f 82 4f ff ff ff    	jb     f01050c8 <stab_binsearch+0x78>
f0105179:	e9 5b ff ff ff       	jmp    f01050d9 <stab_binsearch+0x89>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f010517e:	83 c4 14             	add    $0x14,%esp
f0105181:	5b                   	pop    %ebx
f0105182:	5e                   	pop    %esi
f0105183:	5f                   	pop    %edi
f0105184:	5d                   	pop    %ebp
f0105185:	c3                   	ret    

f0105186 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0105186:	55                   	push   %ebp
f0105187:	89 e5                	mov    %esp,%ebp
f0105189:	57                   	push   %edi
f010518a:	56                   	push   %esi
f010518b:	53                   	push   %ebx
f010518c:	83 ec 5c             	sub    $0x5c,%esp
f010518f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105192:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0105195:	c7 03 a4 80 10 f0    	movl   $0xf01080a4,(%ebx)
	info->eip_line = 0;
f010519b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01051a2:	c7 43 08 a4 80 10 f0 	movl   $0xf01080a4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01051a9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01051b0:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01051b3:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01051ba:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01051c0:	0f 87 c9 00 00 00    	ja     f010528f <debuginfo_eip+0x109>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		/* user_mem_check(struct Env *env, const void *va, size_t len, int perm) */
		if(user_mem_check(curenv, (void *)usd, sizeof(*usd), PTE_U))
f01051c6:	e8 71 12 00 00       	call   f010643c <cpunum>
f01051cb:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01051d2:	00 
f01051d3:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01051da:	00 
f01051db:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f01051e2:	00 
f01051e3:	6b c0 74             	imul   $0x74,%eax,%eax
f01051e6:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01051ec:	89 04 24             	mov    %eax,(%esp)
f01051ef:	e8 2c e0 ff ff       	call   f0103220 <user_mem_check>
f01051f4:	85 c0                	test   %eax,%eax
f01051f6:	0f 85 7b 02 00 00    	jne    f0105477 <debuginfo_eip+0x2f1>
			return -1;

		stabs = usd->stabs;
f01051fc:	a1 00 00 20 00       	mov    0x200000,%eax
f0105201:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0105204:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f010520a:	8b 15 08 00 20 00    	mov    0x200008,%edx
f0105210:	89 55 bc             	mov    %edx,-0x44(%ebp)
		stabstr_end = usd->stabstr_end;
f0105213:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f0105219:	89 4d c0             	mov    %ecx,-0x40(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) |
f010521c:	e8 1b 12 00 00       	call   f010643c <cpunum>
f0105221:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0105228:	00 
f0105229:	89 f2                	mov    %esi,%edx
f010522b:	2b 55 c4             	sub    -0x3c(%ebp),%edx
f010522e:	c1 fa 02             	sar    $0x2,%edx
f0105231:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0105237:	89 54 24 08          	mov    %edx,0x8(%esp)
f010523b:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f010523e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105242:	6b c0 74             	imul   $0x74,%eax,%eax
f0105245:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010524b:	89 04 24             	mov    %eax,(%esp)
f010524e:	e8 cd df ff ff       	call   f0103220 <user_mem_check>
f0105253:	89 45 b8             	mov    %eax,-0x48(%ebp)
		user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U))
f0105256:	e8 e1 11 00 00       	call   f010643c <cpunum>
f010525b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0105262:	00 
f0105263:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0105266:	2b 55 bc             	sub    -0x44(%ebp),%edx
f0105269:	89 54 24 08          	mov    %edx,0x8(%esp)
f010526d:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0105270:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105274:	6b c0 74             	imul   $0x74,%eax,%eax
f0105277:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010527d:	89 04 24             	mov    %eax,(%esp)
f0105280:	e8 9b df ff ff       	call   f0103220 <user_mem_check>
		stabstr = usd->stabstr;
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) |
f0105285:	0b 45 b8             	or     -0x48(%ebp),%eax
f0105288:	74 1f                	je     f01052a9 <debuginfo_eip+0x123>
f010528a:	e9 ef 01 00 00       	jmp    f010547e <debuginfo_eip+0x2f8>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010528f:	c7 45 c0 34 65 11 f0 	movl   $0xf0116534,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0105296:	c7 45 bc 75 2f 11 f0 	movl   $0xf0112f75,-0x44(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010529d:	be 74 2f 11 f0       	mov    $0xf0112f74,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01052a2:	c7 45 c4 94 85 10 f0 	movl   $0xf0108594,-0x3c(%ebp)
			return -1;

	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01052a9:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01052ac:	39 45 bc             	cmp    %eax,-0x44(%ebp)
f01052af:	0f 83 d0 01 00 00    	jae    f0105485 <debuginfo_eip+0x2ff>
f01052b5:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01052b9:	0f 85 cd 01 00 00    	jne    f010548c <debuginfo_eip+0x306>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01052bf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01052c6:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f01052c9:	c1 fe 02             	sar    $0x2,%esi
f01052cc:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f01052d2:	83 e8 01             	sub    $0x1,%eax
f01052d5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01052d8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01052dc:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01052e3:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01052e6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01052e9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01052ec:	e8 5f fd ff ff       	call   f0105050 <stab_binsearch>
	if (lfile == 0)
f01052f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01052f4:	85 c0                	test   %eax,%eax
f01052f6:	0f 84 97 01 00 00    	je     f0105493 <debuginfo_eip+0x30d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01052fc:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01052ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105302:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0105305:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105309:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0105310:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0105313:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0105316:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0105319:	e8 32 fd ff ff       	call   f0105050 <stab_binsearch>

	if (lfun <= rfun) {
f010531e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105321:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0105324:	39 f0                	cmp    %esi,%eax
f0105326:	7f 32                	jg     f010535a <debuginfo_eip+0x1d4>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0105328:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010532b:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010532e:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f0105331:	8b 0a                	mov    (%edx),%ecx
f0105333:	89 4d b4             	mov    %ecx,-0x4c(%ebp)
f0105336:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0105339:	2b 4d bc             	sub    -0x44(%ebp),%ecx
f010533c:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f010533f:	73 09                	jae    f010534a <debuginfo_eip+0x1c4>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0105341:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f0105344:	03 4d bc             	add    -0x44(%ebp),%ecx
f0105347:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010534a:	8b 52 08             	mov    0x8(%edx),%edx
f010534d:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0105350:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0105352:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0105355:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0105358:	eb 0f                	jmp    f0105369 <debuginfo_eip+0x1e3>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010535a:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f010535d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105360:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0105363:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105366:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0105369:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0105370:	00 
f0105371:	8b 43 08             	mov    0x8(%ebx),%eax
f0105374:	89 04 24             	mov    %eax,(%esp)
f0105377:	e8 ef 09 00 00       	call   f0105d6b <strfind>
f010537c:	2b 43 08             	sub    0x8(%ebx),%eax
f010537f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f0105382:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105386:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010538d:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0105390:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105393:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0105396:	e8 b5 fc ff ff       	call   f0105050 <stab_binsearch>
	if(lline > rline)
f010539b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010539e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01053a1:	0f 8f f3 00 00 00    	jg     f010549a <debuginfo_eip+0x314>
		return -1;
		//cprintf("lline %d, rline %d",lline, rline);
	info -> eip_line = stabs[lline].n_desc;
f01053a7:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01053aa:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01053ad:	0f b7 44 82 06       	movzwl 0x6(%edx,%eax,4),%eax
f01053b2:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01053b5:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01053b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01053bb:	39 fa                	cmp    %edi,%edx
f01053bd:	7c 6b                	jl     f010542a <debuginfo_eip+0x2a4>
	       && stabs[lline].n_type != N_SOL
f01053bf:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01053c2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01053c5:	8d 34 81             	lea    (%ecx,%eax,4),%esi
f01053c8:	0f b6 46 04          	movzbl 0x4(%esi),%eax
f01053cc:	88 45 b4             	mov    %al,-0x4c(%ebp)
f01053cf:	3c 84                	cmp    $0x84,%al
f01053d1:	74 3f                	je     f0105412 <debuginfo_eip+0x28c>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01053d3:	8d 4c 52 fd          	lea    -0x3(%edx,%edx,2),%ecx
f01053d7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01053da:	8d 04 88             	lea    (%eax,%ecx,4),%eax
f01053dd:	89 45 b8             	mov    %eax,-0x48(%ebp)
f01053e0:	0f b6 4d b4          	movzbl -0x4c(%ebp),%ecx
f01053e4:	eb 1a                	jmp    f0105400 <debuginfo_eip+0x27a>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01053e6:	83 ea 01             	sub    $0x1,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01053e9:	39 fa                	cmp    %edi,%edx
f01053eb:	7c 3d                	jl     f010542a <debuginfo_eip+0x2a4>
	       && stabs[lline].n_type != N_SOL
f01053ed:	89 c6                	mov    %eax,%esi
f01053ef:	83 e8 0c             	sub    $0xc,%eax
f01053f2:	0f b6 48 10          	movzbl 0x10(%eax),%ecx
f01053f6:	80 f9 84             	cmp    $0x84,%cl
f01053f9:	75 05                	jne    f0105400 <debuginfo_eip+0x27a>
f01053fb:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01053fe:	eb 12                	jmp    f0105412 <debuginfo_eip+0x28c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0105400:	80 f9 64             	cmp    $0x64,%cl
f0105403:	75 e1                	jne    f01053e6 <debuginfo_eip+0x260>
f0105405:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0105409:	74 db                	je     f01053e6 <debuginfo_eip+0x260>
f010540b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010540e:	39 d7                	cmp    %edx,%edi
f0105410:	7f 18                	jg     f010542a <debuginfo_eip+0x2a4>
f0105412:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0105415:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0105418:	8b 04 82             	mov    (%edx,%eax,4),%eax
f010541b:	8b 55 c0             	mov    -0x40(%ebp),%edx
f010541e:	2b 55 bc             	sub    -0x44(%ebp),%edx
f0105421:	39 d0                	cmp    %edx,%eax
f0105423:	73 05                	jae    f010542a <debuginfo_eip+0x2a4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0105425:	03 45 bc             	add    -0x44(%ebp),%eax
f0105428:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010542a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010542d:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0105430:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105435:	39 f2                	cmp    %esi,%edx
f0105437:	7d 7b                	jge    f01054b4 <debuginfo_eip+0x32e>
		for (lline = lfun + 1;
f0105439:	8d 42 01             	lea    0x1(%edx),%eax
f010543c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010543f:	39 c6                	cmp    %eax,%esi
f0105441:	7e 5e                	jle    f01054a1 <debuginfo_eip+0x31b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105443:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105446:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0105449:	80 7c 81 04 a0       	cmpb   $0xa0,0x4(%ecx,%eax,4)
f010544e:	75 58                	jne    f01054a8 <debuginfo_eip+0x322>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0105450:	8d 42 02             	lea    0x2(%edx),%eax

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105453:	8d 14 52             	lea    (%edx,%edx,2),%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0105456:	8d 54 91 1c          	lea    0x1c(%ecx,%edx,4),%edx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010545a:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010545e:	39 f0                	cmp    %esi,%eax
f0105460:	74 4d                	je     f01054af <debuginfo_eip+0x329>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105462:	0f b6 0a             	movzbl (%edx),%ecx
f0105465:	83 c0 01             	add    $0x1,%eax
f0105468:	83 c2 0c             	add    $0xc,%edx
f010546b:	80 f9 a0             	cmp    $0xa0,%cl
f010546e:	74 ea                	je     f010545a <debuginfo_eip+0x2d4>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0105470:	b8 00 00 00 00       	mov    $0x0,%eax
f0105475:	eb 3d                	jmp    f01054b4 <debuginfo_eip+0x32e>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		/* user_mem_check(struct Env *env, const void *va, size_t len, int perm) */
		if(user_mem_check(curenv, (void *)usd, sizeof(*usd), PTE_U))
			return -1;
f0105477:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010547c:	eb 36                	jmp    f01054b4 <debuginfo_eip+0x32e>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) |
		user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
f010547e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105483:	eb 2f                	jmp    f01054b4 <debuginfo_eip+0x32e>

	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0105485:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010548a:	eb 28                	jmp    f01054b4 <debuginfo_eip+0x32e>
f010548c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105491:	eb 21                	jmp    f01054b4 <debuginfo_eip+0x32e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0105493:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105498:	eb 1a                	jmp    f01054b4 <debuginfo_eip+0x32e>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
	if(lline > rline)
		return -1;
f010549a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010549f:	eb 13                	jmp    f01054b4 <debuginfo_eip+0x32e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f01054a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01054a6:	eb 0c                	jmp    f01054b4 <debuginfo_eip+0x32e>
f01054a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01054ad:	eb 05                	jmp    f01054b4 <debuginfo_eip+0x32e>
f01054af:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01054b4:	83 c4 5c             	add    $0x5c,%esp
f01054b7:	5b                   	pop    %ebx
f01054b8:	5e                   	pop    %esi
f01054b9:	5f                   	pop    %edi
f01054ba:	5d                   	pop    %ebp
f01054bb:	c3                   	ret    
f01054bc:	66 90                	xchg   %ax,%ax
f01054be:	66 90                	xchg   %ax,%ax

f01054c0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01054c0:	55                   	push   %ebp
f01054c1:	89 e5                	mov    %esp,%ebp
f01054c3:	57                   	push   %edi
f01054c4:	56                   	push   %esi
f01054c5:	53                   	push   %ebx
f01054c6:	83 ec 4c             	sub    $0x4c,%esp
f01054c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01054cc:	89 d7                	mov    %edx,%edi
f01054ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01054d1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01054d4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01054d7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01054da:	b8 00 00 00 00       	mov    $0x0,%eax
f01054df:	39 d8                	cmp    %ebx,%eax
f01054e1:	72 17                	jb     f01054fa <printnum+0x3a>
f01054e3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01054e6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f01054e9:	76 0f                	jbe    f01054fa <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01054eb:	8b 75 14             	mov    0x14(%ebp),%esi
f01054ee:	83 ee 01             	sub    $0x1,%esi
f01054f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01054f4:	85 f6                	test   %esi,%esi
f01054f6:	7f 63                	jg     f010555b <printnum+0x9b>
f01054f8:	eb 75                	jmp    f010556f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01054fa:	8b 5d 18             	mov    0x18(%ebp),%ebx
f01054fd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0105501:	8b 45 14             	mov    0x14(%ebp),%eax
f0105504:	83 e8 01             	sub    $0x1,%eax
f0105507:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010550b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010550e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105512:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105516:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010551a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010551d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105520:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0105527:	00 
f0105528:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010552b:	89 1c 24             	mov    %ebx,(%esp)
f010552e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0105531:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105535:	e8 86 13 00 00       	call   f01068c0 <__udivdi3>
f010553a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010553d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0105540:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105544:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0105548:	89 04 24             	mov    %eax,(%esp)
f010554b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010554f:	89 fa                	mov    %edi,%edx
f0105551:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105554:	e8 67 ff ff ff       	call   f01054c0 <printnum>
f0105559:	eb 14                	jmp    f010556f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010555b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010555f:	8b 45 18             	mov    0x18(%ebp),%eax
f0105562:	89 04 24             	mov    %eax,(%esp)
f0105565:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0105567:	83 ee 01             	sub    $0x1,%esi
f010556a:	75 ef                	jne    f010555b <printnum+0x9b>
f010556c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010556f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105573:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105577:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010557a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010557e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0105585:	00 
f0105586:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0105589:	89 1c 24             	mov    %ebx,(%esp)
f010558c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010558f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105593:	e8 78 14 00 00       	call   f0106a10 <__umoddi3>
f0105598:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010559c:	0f be 80 ae 80 10 f0 	movsbl -0xfef7f52(%eax),%eax
f01055a3:	89 04 24             	mov    %eax,(%esp)
f01055a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01055a9:	ff d0                	call   *%eax
}
f01055ab:	83 c4 4c             	add    $0x4c,%esp
f01055ae:	5b                   	pop    %ebx
f01055af:	5e                   	pop    %esi
f01055b0:	5f                   	pop    %edi
f01055b1:	5d                   	pop    %ebp
f01055b2:	c3                   	ret    

f01055b3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01055b3:	55                   	push   %ebp
f01055b4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01055b6:	83 fa 01             	cmp    $0x1,%edx
f01055b9:	7e 0e                	jle    f01055c9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01055bb:	8b 10                	mov    (%eax),%edx
f01055bd:	8d 4a 08             	lea    0x8(%edx),%ecx
f01055c0:	89 08                	mov    %ecx,(%eax)
f01055c2:	8b 02                	mov    (%edx),%eax
f01055c4:	8b 52 04             	mov    0x4(%edx),%edx
f01055c7:	eb 22                	jmp    f01055eb <getuint+0x38>
	else if (lflag)
f01055c9:	85 d2                	test   %edx,%edx
f01055cb:	74 10                	je     f01055dd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01055cd:	8b 10                	mov    (%eax),%edx
f01055cf:	8d 4a 04             	lea    0x4(%edx),%ecx
f01055d2:	89 08                	mov    %ecx,(%eax)
f01055d4:	8b 02                	mov    (%edx),%eax
f01055d6:	ba 00 00 00 00       	mov    $0x0,%edx
f01055db:	eb 0e                	jmp    f01055eb <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01055dd:	8b 10                	mov    (%eax),%edx
f01055df:	8d 4a 04             	lea    0x4(%edx),%ecx
f01055e2:	89 08                	mov    %ecx,(%eax)
f01055e4:	8b 02                	mov    (%edx),%eax
f01055e6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01055eb:	5d                   	pop    %ebp
f01055ec:	c3                   	ret    

f01055ed <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01055ed:	55                   	push   %ebp
f01055ee:	89 e5                	mov    %esp,%ebp
f01055f0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01055f3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01055f7:	8b 10                	mov    (%eax),%edx
f01055f9:	3b 50 04             	cmp    0x4(%eax),%edx
f01055fc:	73 0a                	jae    f0105608 <sprintputch+0x1b>
		*b->buf++ = ch;
f01055fe:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105601:	88 0a                	mov    %cl,(%edx)
f0105603:	83 c2 01             	add    $0x1,%edx
f0105606:	89 10                	mov    %edx,(%eax)
}
f0105608:	5d                   	pop    %ebp
f0105609:	c3                   	ret    

f010560a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010560a:	55                   	push   %ebp
f010560b:	89 e5                	mov    %esp,%ebp
f010560d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0105610:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0105613:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105617:	8b 45 10             	mov    0x10(%ebp),%eax
f010561a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010561e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105621:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105625:	8b 45 08             	mov    0x8(%ebp),%eax
f0105628:	89 04 24             	mov    %eax,(%esp)
f010562b:	e8 02 00 00 00       	call   f0105632 <vprintfmt>
	va_end(ap);
}
f0105630:	c9                   	leave  
f0105631:	c3                   	ret    

f0105632 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0105632:	55                   	push   %ebp
f0105633:	89 e5                	mov    %esp,%ebp
f0105635:	57                   	push   %edi
f0105636:	56                   	push   %esi
f0105637:	53                   	push   %ebx
f0105638:	83 ec 4c             	sub    $0x4c,%esp
f010563b:	8b 75 08             	mov    0x8(%ebp),%esi
f010563e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105641:	8b 7d 10             	mov    0x10(%ebp),%edi
f0105644:	eb 11                	jmp    f0105657 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0105646:	85 c0                	test   %eax,%eax
f0105648:	0f 84 db 03 00 00    	je     f0105a29 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f010564e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105652:	89 04 24             	mov    %eax,(%esp)
f0105655:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105657:	0f b6 07             	movzbl (%edi),%eax
f010565a:	83 c7 01             	add    $0x1,%edi
f010565d:	83 f8 25             	cmp    $0x25,%eax
f0105660:	75 e4                	jne    f0105646 <vprintfmt+0x14>
f0105662:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0105666:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f010566d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105674:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010567b:	ba 00 00 00 00       	mov    $0x0,%edx
f0105680:	eb 2b                	jmp    f01056ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105682:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0105685:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0105689:	eb 22                	jmp    f01056ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010568b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010568e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0105692:	eb 19                	jmp    f01056ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105694:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0105697:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010569e:	eb 0d                	jmp    f01056ad <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01056a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01056a3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01056a6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01056ad:	0f b6 0f             	movzbl (%edi),%ecx
f01056b0:	8d 47 01             	lea    0x1(%edi),%eax
f01056b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01056b6:	0f b6 07             	movzbl (%edi),%eax
f01056b9:	83 e8 23             	sub    $0x23,%eax
f01056bc:	3c 55                	cmp    $0x55,%al
f01056be:	0f 87 40 03 00 00    	ja     f0105a04 <vprintfmt+0x3d2>
f01056c4:	0f b6 c0             	movzbl %al,%eax
f01056c7:	ff 24 85 80 81 10 f0 	jmp    *-0xfef7e80(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01056ce:	83 e9 30             	sub    $0x30,%ecx
f01056d1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f01056d4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f01056d8:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01056db:	83 f9 09             	cmp    $0x9,%ecx
f01056de:	77 57                	ja     f0105737 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01056e0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01056e3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01056e6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01056e9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01056ec:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01056ef:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f01056f3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f01056f6:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01056f9:	83 f9 09             	cmp    $0x9,%ecx
f01056fc:	76 eb                	jbe    f01056e9 <vprintfmt+0xb7>
f01056fe:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105701:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0105704:	eb 34                	jmp    f010573a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105706:	8b 45 14             	mov    0x14(%ebp),%eax
f0105709:	8d 48 04             	lea    0x4(%eax),%ecx
f010570c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010570f:	8b 00                	mov    (%eax),%eax
f0105711:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105714:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0105717:	eb 21                	jmp    f010573a <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0105719:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010571d:	0f 88 71 ff ff ff    	js     f0105694 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105723:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0105726:	eb 85                	jmp    f01056ad <vprintfmt+0x7b>
f0105728:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010572b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0105732:	e9 76 ff ff ff       	jmp    f01056ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105737:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010573a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010573e:	0f 89 69 ff ff ff    	jns    f01056ad <vprintfmt+0x7b>
f0105744:	e9 57 ff ff ff       	jmp    f01056a0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0105749:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010574c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010574f:	e9 59 ff ff ff       	jmp    f01056ad <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0105754:	8b 45 14             	mov    0x14(%ebp),%eax
f0105757:	8d 50 04             	lea    0x4(%eax),%edx
f010575a:	89 55 14             	mov    %edx,0x14(%ebp)
f010575d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105761:	8b 00                	mov    (%eax),%eax
f0105763:	89 04 24             	mov    %eax,(%esp)
f0105766:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105768:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010576b:	e9 e7 fe ff ff       	jmp    f0105657 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0105770:	8b 45 14             	mov    0x14(%ebp),%eax
f0105773:	8d 50 04             	lea    0x4(%eax),%edx
f0105776:	89 55 14             	mov    %edx,0x14(%ebp)
f0105779:	8b 00                	mov    (%eax),%eax
f010577b:	89 c2                	mov    %eax,%edx
f010577d:	c1 fa 1f             	sar    $0x1f,%edx
f0105780:	31 d0                	xor    %edx,%eax
f0105782:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0105784:	83 f8 08             	cmp    $0x8,%eax
f0105787:	7f 0b                	jg     f0105794 <vprintfmt+0x162>
f0105789:	8b 14 85 e0 82 10 f0 	mov    -0xfef7d20(,%eax,4),%edx
f0105790:	85 d2                	test   %edx,%edx
f0105792:	75 20                	jne    f01057b4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0105794:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105798:	c7 44 24 08 c6 80 10 	movl   $0xf01080c6,0x8(%esp)
f010579f:	f0 
f01057a0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01057a4:	89 34 24             	mov    %esi,(%esp)
f01057a7:	e8 5e fe ff ff       	call   f010560a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01057ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01057af:	e9 a3 fe ff ff       	jmp    f0105657 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01057b4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01057b8:	c7 44 24 08 86 78 10 	movl   $0xf0107886,0x8(%esp)
f01057bf:	f0 
f01057c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01057c4:	89 34 24             	mov    %esi,(%esp)
f01057c7:	e8 3e fe ff ff       	call   f010560a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01057cc:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01057cf:	e9 83 fe ff ff       	jmp    f0105657 <vprintfmt+0x25>
f01057d4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01057d7:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01057da:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01057dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01057e0:	8d 50 04             	lea    0x4(%eax),%edx
f01057e3:	89 55 14             	mov    %edx,0x14(%ebp)
f01057e6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01057e8:	85 ff                	test   %edi,%edi
f01057ea:	b8 bf 80 10 f0       	mov    $0xf01080bf,%eax
f01057ef:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01057f2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f01057f6:	74 06                	je     f01057fe <vprintfmt+0x1cc>
f01057f8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01057fc:	7f 16                	jg     f0105814 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01057fe:	0f b6 17             	movzbl (%edi),%edx
f0105801:	0f be c2             	movsbl %dl,%eax
f0105804:	83 c7 01             	add    $0x1,%edi
f0105807:	85 c0                	test   %eax,%eax
f0105809:	0f 85 9f 00 00 00    	jne    f01058ae <vprintfmt+0x27c>
f010580f:	e9 8b 00 00 00       	jmp    f010589f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105814:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105818:	89 3c 24             	mov    %edi,(%esp)
f010581b:	e8 92 03 00 00       	call   f0105bb2 <strnlen>
f0105820:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0105823:	29 c2                	sub    %eax,%edx
f0105825:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0105828:	85 d2                	test   %edx,%edx
f010582a:	7e d2                	jle    f01057fe <vprintfmt+0x1cc>
					putch(padc, putdat);
f010582c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0105830:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0105833:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0105836:	89 d7                	mov    %edx,%edi
f0105838:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010583c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010583f:	89 04 24             	mov    %eax,(%esp)
f0105842:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105844:	83 ef 01             	sub    $0x1,%edi
f0105847:	75 ef                	jne    f0105838 <vprintfmt+0x206>
f0105849:	89 7d d8             	mov    %edi,-0x28(%ebp)
f010584c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010584f:	eb ad                	jmp    f01057fe <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0105851:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0105855:	74 20                	je     f0105877 <vprintfmt+0x245>
f0105857:	0f be d2             	movsbl %dl,%edx
f010585a:	83 ea 20             	sub    $0x20,%edx
f010585d:	83 fa 5e             	cmp    $0x5e,%edx
f0105860:	76 15                	jbe    f0105877 <vprintfmt+0x245>
					putch('?', putdat);
f0105862:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105865:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105869:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0105870:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0105873:	ff d1                	call   *%ecx
f0105875:	eb 0f                	jmp    f0105886 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0105877:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010587a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010587e:	89 04 24             	mov    %eax,(%esp)
f0105881:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0105884:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105886:	83 eb 01             	sub    $0x1,%ebx
f0105889:	0f b6 17             	movzbl (%edi),%edx
f010588c:	0f be c2             	movsbl %dl,%eax
f010588f:	83 c7 01             	add    $0x1,%edi
f0105892:	85 c0                	test   %eax,%eax
f0105894:	75 24                	jne    f01058ba <vprintfmt+0x288>
f0105896:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0105899:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010589c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010589f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01058a2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01058a6:	0f 8e ab fd ff ff    	jle    f0105657 <vprintfmt+0x25>
f01058ac:	eb 20                	jmp    f01058ce <vprintfmt+0x29c>
f01058ae:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01058b1:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01058b4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01058b7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01058ba:	85 f6                	test   %esi,%esi
f01058bc:	78 93                	js     f0105851 <vprintfmt+0x21f>
f01058be:	83 ee 01             	sub    $0x1,%esi
f01058c1:	79 8e                	jns    f0105851 <vprintfmt+0x21f>
f01058c3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01058c6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01058c9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01058cc:	eb d1                	jmp    f010589f <vprintfmt+0x26d>
f01058ce:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01058d1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01058d5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01058dc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01058de:	83 ef 01             	sub    $0x1,%edi
f01058e1:	75 ee                	jne    f01058d1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01058e3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01058e6:	e9 6c fd ff ff       	jmp    f0105657 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01058eb:	83 fa 01             	cmp    $0x1,%edx
f01058ee:	66 90                	xchg   %ax,%ax
f01058f0:	7e 16                	jle    f0105908 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f01058f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01058f5:	8d 50 08             	lea    0x8(%eax),%edx
f01058f8:	89 55 14             	mov    %edx,0x14(%ebp)
f01058fb:	8b 10                	mov    (%eax),%edx
f01058fd:	8b 48 04             	mov    0x4(%eax),%ecx
f0105900:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0105903:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0105906:	eb 32                	jmp    f010593a <vprintfmt+0x308>
	else if (lflag)
f0105908:	85 d2                	test   %edx,%edx
f010590a:	74 18                	je     f0105924 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f010590c:	8b 45 14             	mov    0x14(%ebp),%eax
f010590f:	8d 50 04             	lea    0x4(%eax),%edx
f0105912:	89 55 14             	mov    %edx,0x14(%ebp)
f0105915:	8b 00                	mov    (%eax),%eax
f0105917:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010591a:	89 c1                	mov    %eax,%ecx
f010591c:	c1 f9 1f             	sar    $0x1f,%ecx
f010591f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0105922:	eb 16                	jmp    f010593a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f0105924:	8b 45 14             	mov    0x14(%ebp),%eax
f0105927:	8d 50 04             	lea    0x4(%eax),%edx
f010592a:	89 55 14             	mov    %edx,0x14(%ebp)
f010592d:	8b 00                	mov    (%eax),%eax
f010592f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0105932:	89 c7                	mov    %eax,%edi
f0105934:	c1 ff 1f             	sar    $0x1f,%edi
f0105937:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010593a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010593d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0105940:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105945:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0105949:	79 7d                	jns    f01059c8 <vprintfmt+0x396>
				putch('-', putdat);
f010594b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010594f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0105956:	ff d6                	call   *%esi
				num = -(long long) num;
f0105958:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010595b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010595e:	f7 d8                	neg    %eax
f0105960:	83 d2 00             	adc    $0x0,%edx
f0105963:	f7 da                	neg    %edx
			}
			base = 10;
f0105965:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010596a:	eb 5c                	jmp    f01059c8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010596c:	8d 45 14             	lea    0x14(%ebp),%eax
f010596f:	e8 3f fc ff ff       	call   f01055b3 <getuint>
			base = 10;
f0105974:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105979:	eb 4d                	jmp    f01059c8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010597b:	8d 45 14             	lea    0x14(%ebp),%eax
f010597e:	e8 30 fc ff ff       	call   f01055b3 <getuint>
			base = 8;
f0105983:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105988:	eb 3e                	jmp    f01059c8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
f010598a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010598e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0105995:	ff d6                	call   *%esi
			putch('x', putdat);
f0105997:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010599b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01059a2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01059a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01059a7:	8d 50 04             	lea    0x4(%eax),%edx
f01059aa:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01059ad:	8b 00                	mov    (%eax),%eax
f01059af:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01059b4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01059b9:	eb 0d                	jmp    f01059c8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01059bb:	8d 45 14             	lea    0x14(%ebp),%eax
f01059be:	e8 f0 fb ff ff       	call   f01055b3 <getuint>
			base = 16;
f01059c3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01059c8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f01059cc:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01059d0:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01059d3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01059d7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01059db:	89 04 24             	mov    %eax,(%esp)
f01059de:	89 54 24 04          	mov    %edx,0x4(%esp)
f01059e2:	89 da                	mov    %ebx,%edx
f01059e4:	89 f0                	mov    %esi,%eax
f01059e6:	e8 d5 fa ff ff       	call   f01054c0 <printnum>
			break;
f01059eb:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01059ee:	e9 64 fc ff ff       	jmp    f0105657 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01059f3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01059f7:	89 0c 24             	mov    %ecx,(%esp)
f01059fa:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01059fc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01059ff:	e9 53 fc ff ff       	jmp    f0105657 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105a04:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105a08:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105a0f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105a11:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0105a15:	0f 84 3c fc ff ff    	je     f0105657 <vprintfmt+0x25>
f0105a1b:	83 ef 01             	sub    $0x1,%edi
f0105a1e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0105a22:	75 f7                	jne    f0105a1b <vprintfmt+0x3e9>
f0105a24:	e9 2e fc ff ff       	jmp    f0105657 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0105a29:	83 c4 4c             	add    $0x4c,%esp
f0105a2c:	5b                   	pop    %ebx
f0105a2d:	5e                   	pop    %esi
f0105a2e:	5f                   	pop    %edi
f0105a2f:	5d                   	pop    %ebp
f0105a30:	c3                   	ret    

f0105a31 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105a31:	55                   	push   %ebp
f0105a32:	89 e5                	mov    %esp,%ebp
f0105a34:	83 ec 28             	sub    $0x28,%esp
f0105a37:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a3a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105a3d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105a40:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105a44:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105a47:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105a4e:	85 d2                	test   %edx,%edx
f0105a50:	7e 30                	jle    f0105a82 <vsnprintf+0x51>
f0105a52:	85 c0                	test   %eax,%eax
f0105a54:	74 2c                	je     f0105a82 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105a56:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a59:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105a5d:	8b 45 10             	mov    0x10(%ebp),%eax
f0105a60:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105a64:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105a67:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105a6b:	c7 04 24 ed 55 10 f0 	movl   $0xf01055ed,(%esp)
f0105a72:	e8 bb fb ff ff       	call   f0105632 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105a77:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105a7a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105a80:	eb 05                	jmp    f0105a87 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105a82:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105a87:	c9                   	leave  
f0105a88:	c3                   	ret    

f0105a89 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105a89:	55                   	push   %ebp
f0105a8a:	89 e5                	mov    %esp,%ebp
f0105a8c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105a8f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105a92:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105a96:	8b 45 10             	mov    0x10(%ebp),%eax
f0105a99:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105a9d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105aa0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105aa4:	8b 45 08             	mov    0x8(%ebp),%eax
f0105aa7:	89 04 24             	mov    %eax,(%esp)
f0105aaa:	e8 82 ff ff ff       	call   f0105a31 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105aaf:	c9                   	leave  
f0105ab0:	c3                   	ret    
f0105ab1:	66 90                	xchg   %ax,%ax
f0105ab3:	66 90                	xchg   %ax,%ax
f0105ab5:	66 90                	xchg   %ax,%ax
f0105ab7:	66 90                	xchg   %ax,%ax
f0105ab9:	66 90                	xchg   %ax,%ax
f0105abb:	66 90                	xchg   %ax,%ax
f0105abd:	66 90                	xchg   %ax,%ax
f0105abf:	90                   	nop

f0105ac0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105ac0:	55                   	push   %ebp
f0105ac1:	89 e5                	mov    %esp,%ebp
f0105ac3:	57                   	push   %edi
f0105ac4:	56                   	push   %esi
f0105ac5:	53                   	push   %ebx
f0105ac6:	83 ec 1c             	sub    $0x1c,%esp
f0105ac9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0105acc:	85 c0                	test   %eax,%eax
f0105ace:	74 10                	je     f0105ae0 <readline+0x20>
		cprintf("%s", prompt);
f0105ad0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105ad4:	c7 04 24 86 78 10 f0 	movl   $0xf0107886,(%esp)
f0105adb:	e8 16 e2 ff ff       	call   f0103cf6 <cprintf>

	i = 0;
	echoing = iscons(0);
f0105ae0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0105ae7:	e8 0a ad ff ff       	call   f01007f6 <iscons>
f0105aec:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0105aee:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105af3:	e8 ed ac ff ff       	call   f01007e5 <getchar>
f0105af8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105afa:	85 c0                	test   %eax,%eax
f0105afc:	79 17                	jns    f0105b15 <readline+0x55>
			cprintf("read error: %e\n", c);
f0105afe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105b02:	c7 04 24 04 83 10 f0 	movl   $0xf0108304,(%esp)
f0105b09:	e8 e8 e1 ff ff       	call   f0103cf6 <cprintf>
			return NULL;
f0105b0e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105b13:	eb 6d                	jmp    f0105b82 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105b15:	83 f8 7f             	cmp    $0x7f,%eax
f0105b18:	74 05                	je     f0105b1f <readline+0x5f>
f0105b1a:	83 f8 08             	cmp    $0x8,%eax
f0105b1d:	75 19                	jne    f0105b38 <readline+0x78>
f0105b1f:	85 f6                	test   %esi,%esi
f0105b21:	7e 15                	jle    f0105b38 <readline+0x78>
			if (echoing)
f0105b23:	85 ff                	test   %edi,%edi
f0105b25:	74 0c                	je     f0105b33 <readline+0x73>
				cputchar('\b');
f0105b27:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0105b2e:	e8 a2 ac ff ff       	call   f01007d5 <cputchar>
			i--;
f0105b33:	83 ee 01             	sub    $0x1,%esi
f0105b36:	eb bb                	jmp    f0105af3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105b38:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0105b3e:	7f 1c                	jg     f0105b5c <readline+0x9c>
f0105b40:	83 fb 1f             	cmp    $0x1f,%ebx
f0105b43:	7e 17                	jle    f0105b5c <readline+0x9c>
			if (echoing)
f0105b45:	85 ff                	test   %edi,%edi
f0105b47:	74 08                	je     f0105b51 <readline+0x91>
				cputchar(c);
f0105b49:	89 1c 24             	mov    %ebx,(%esp)
f0105b4c:	e8 84 ac ff ff       	call   f01007d5 <cputchar>
			buf[i++] = c;
f0105b51:	88 9e 80 aa 22 f0    	mov    %bl,-0xfdd5580(%esi)
f0105b57:	83 c6 01             	add    $0x1,%esi
f0105b5a:	eb 97                	jmp    f0105af3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0105b5c:	83 fb 0d             	cmp    $0xd,%ebx
f0105b5f:	74 05                	je     f0105b66 <readline+0xa6>
f0105b61:	83 fb 0a             	cmp    $0xa,%ebx
f0105b64:	75 8d                	jne    f0105af3 <readline+0x33>
			if (echoing)
f0105b66:	85 ff                	test   %edi,%edi
f0105b68:	74 0c                	je     f0105b76 <readline+0xb6>
				cputchar('\n');
f0105b6a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0105b71:	e8 5f ac ff ff       	call   f01007d5 <cputchar>
			buf[i] = 0;
f0105b76:	c6 86 80 aa 22 f0 00 	movb   $0x0,-0xfdd5580(%esi)
			return buf;
f0105b7d:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
		}
	}
}
f0105b82:	83 c4 1c             	add    $0x1c,%esp
f0105b85:	5b                   	pop    %ebx
f0105b86:	5e                   	pop    %esi
f0105b87:	5f                   	pop    %edi
f0105b88:	5d                   	pop    %ebp
f0105b89:	c3                   	ret    
f0105b8a:	66 90                	xchg   %ax,%ax
f0105b8c:	66 90                	xchg   %ax,%ax
f0105b8e:	66 90                	xchg   %ax,%ax

f0105b90 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105b90:	55                   	push   %ebp
f0105b91:	89 e5                	mov    %esp,%ebp
f0105b93:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105b96:	80 3a 00             	cmpb   $0x0,(%edx)
f0105b99:	74 10                	je     f0105bab <strlen+0x1b>
f0105b9b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0105ba0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105ba3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105ba7:	75 f7                	jne    f0105ba0 <strlen+0x10>
f0105ba9:	eb 05                	jmp    f0105bb0 <strlen+0x20>
f0105bab:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0105bb0:	5d                   	pop    %ebp
f0105bb1:	c3                   	ret    

f0105bb2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105bb2:	55                   	push   %ebp
f0105bb3:	89 e5                	mov    %esp,%ebp
f0105bb5:	53                   	push   %ebx
f0105bb6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0105bb9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105bbc:	85 c9                	test   %ecx,%ecx
f0105bbe:	74 1c                	je     f0105bdc <strnlen+0x2a>
f0105bc0:	80 3b 00             	cmpb   $0x0,(%ebx)
f0105bc3:	74 1e                	je     f0105be3 <strnlen+0x31>
f0105bc5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0105bca:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105bcc:	39 ca                	cmp    %ecx,%edx
f0105bce:	74 18                	je     f0105be8 <strnlen+0x36>
f0105bd0:	83 c2 01             	add    $0x1,%edx
f0105bd3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0105bd8:	75 f0                	jne    f0105bca <strnlen+0x18>
f0105bda:	eb 0c                	jmp    f0105be8 <strnlen+0x36>
f0105bdc:	b8 00 00 00 00       	mov    $0x0,%eax
f0105be1:	eb 05                	jmp    f0105be8 <strnlen+0x36>
f0105be3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0105be8:	5b                   	pop    %ebx
f0105be9:	5d                   	pop    %ebp
f0105bea:	c3                   	ret    

f0105beb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105beb:	55                   	push   %ebp
f0105bec:	89 e5                	mov    %esp,%ebp
f0105bee:	53                   	push   %ebx
f0105bef:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bf2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105bf5:	89 c2                	mov    %eax,%edx
f0105bf7:	0f b6 19             	movzbl (%ecx),%ebx
f0105bfa:	88 1a                	mov    %bl,(%edx)
f0105bfc:	83 c2 01             	add    $0x1,%edx
f0105bff:	83 c1 01             	add    $0x1,%ecx
f0105c02:	84 db                	test   %bl,%bl
f0105c04:	75 f1                	jne    f0105bf7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105c06:	5b                   	pop    %ebx
f0105c07:	5d                   	pop    %ebp
f0105c08:	c3                   	ret    

f0105c09 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105c09:	55                   	push   %ebp
f0105c0a:	89 e5                	mov    %esp,%ebp
f0105c0c:	53                   	push   %ebx
f0105c0d:	83 ec 08             	sub    $0x8,%esp
f0105c10:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105c13:	89 1c 24             	mov    %ebx,(%esp)
f0105c16:	e8 75 ff ff ff       	call   f0105b90 <strlen>
	strcpy(dst + len, src);
f0105c1b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c1e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105c22:	01 d8                	add    %ebx,%eax
f0105c24:	89 04 24             	mov    %eax,(%esp)
f0105c27:	e8 bf ff ff ff       	call   f0105beb <strcpy>
	return dst;
}
f0105c2c:	89 d8                	mov    %ebx,%eax
f0105c2e:	83 c4 08             	add    $0x8,%esp
f0105c31:	5b                   	pop    %ebx
f0105c32:	5d                   	pop    %ebp
f0105c33:	c3                   	ret    

f0105c34 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105c34:	55                   	push   %ebp
f0105c35:	89 e5                	mov    %esp,%ebp
f0105c37:	56                   	push   %esi
f0105c38:	53                   	push   %ebx
f0105c39:	8b 75 08             	mov    0x8(%ebp),%esi
f0105c3c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c3f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105c42:	85 db                	test   %ebx,%ebx
f0105c44:	74 16                	je     f0105c5c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f0105c46:	01 f3                	add    %esi,%ebx
f0105c48:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f0105c4a:	0f b6 02             	movzbl (%edx),%eax
f0105c4d:	88 01                	mov    %al,(%ecx)
f0105c4f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105c52:	80 3a 01             	cmpb   $0x1,(%edx)
f0105c55:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105c58:	39 d9                	cmp    %ebx,%ecx
f0105c5a:	75 ee                	jne    f0105c4a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105c5c:	89 f0                	mov    %esi,%eax
f0105c5e:	5b                   	pop    %ebx
f0105c5f:	5e                   	pop    %esi
f0105c60:	5d                   	pop    %ebp
f0105c61:	c3                   	ret    

f0105c62 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105c62:	55                   	push   %ebp
f0105c63:	89 e5                	mov    %esp,%ebp
f0105c65:	57                   	push   %edi
f0105c66:	56                   	push   %esi
f0105c67:	53                   	push   %ebx
f0105c68:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105c6b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105c6e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105c71:	89 f8                	mov    %edi,%eax
f0105c73:	85 f6                	test   %esi,%esi
f0105c75:	74 33                	je     f0105caa <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f0105c77:	83 fe 01             	cmp    $0x1,%esi
f0105c7a:	74 25                	je     f0105ca1 <strlcpy+0x3f>
f0105c7c:	0f b6 0b             	movzbl (%ebx),%ecx
f0105c7f:	84 c9                	test   %cl,%cl
f0105c81:	74 22                	je     f0105ca5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0105c83:	83 ee 02             	sub    $0x2,%esi
f0105c86:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105c8b:	88 08                	mov    %cl,(%eax)
f0105c8d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105c90:	39 f2                	cmp    %esi,%edx
f0105c92:	74 13                	je     f0105ca7 <strlcpy+0x45>
f0105c94:	83 c2 01             	add    $0x1,%edx
f0105c97:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0105c9b:	84 c9                	test   %cl,%cl
f0105c9d:	75 ec                	jne    f0105c8b <strlcpy+0x29>
f0105c9f:	eb 06                	jmp    f0105ca7 <strlcpy+0x45>
f0105ca1:	89 f8                	mov    %edi,%eax
f0105ca3:	eb 02                	jmp    f0105ca7 <strlcpy+0x45>
f0105ca5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105ca7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105caa:	29 f8                	sub    %edi,%eax
}
f0105cac:	5b                   	pop    %ebx
f0105cad:	5e                   	pop    %esi
f0105cae:	5f                   	pop    %edi
f0105caf:	5d                   	pop    %ebp
f0105cb0:	c3                   	ret    

f0105cb1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105cb1:	55                   	push   %ebp
f0105cb2:	89 e5                	mov    %esp,%ebp
f0105cb4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105cb7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105cba:	0f b6 01             	movzbl (%ecx),%eax
f0105cbd:	84 c0                	test   %al,%al
f0105cbf:	74 15                	je     f0105cd6 <strcmp+0x25>
f0105cc1:	3a 02                	cmp    (%edx),%al
f0105cc3:	75 11                	jne    f0105cd6 <strcmp+0x25>
		p++, q++;
f0105cc5:	83 c1 01             	add    $0x1,%ecx
f0105cc8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105ccb:	0f b6 01             	movzbl (%ecx),%eax
f0105cce:	84 c0                	test   %al,%al
f0105cd0:	74 04                	je     f0105cd6 <strcmp+0x25>
f0105cd2:	3a 02                	cmp    (%edx),%al
f0105cd4:	74 ef                	je     f0105cc5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105cd6:	0f b6 c0             	movzbl %al,%eax
f0105cd9:	0f b6 12             	movzbl (%edx),%edx
f0105cdc:	29 d0                	sub    %edx,%eax
}
f0105cde:	5d                   	pop    %ebp
f0105cdf:	c3                   	ret    

f0105ce0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105ce0:	55                   	push   %ebp
f0105ce1:	89 e5                	mov    %esp,%ebp
f0105ce3:	56                   	push   %esi
f0105ce4:	53                   	push   %ebx
f0105ce5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0105ce8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105ceb:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0105cee:	85 f6                	test   %esi,%esi
f0105cf0:	74 29                	je     f0105d1b <strncmp+0x3b>
f0105cf2:	0f b6 03             	movzbl (%ebx),%eax
f0105cf5:	84 c0                	test   %al,%al
f0105cf7:	74 30                	je     f0105d29 <strncmp+0x49>
f0105cf9:	3a 02                	cmp    (%edx),%al
f0105cfb:	75 2c                	jne    f0105d29 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0105cfd:	8d 43 01             	lea    0x1(%ebx),%eax
f0105d00:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0105d02:	89 c3                	mov    %eax,%ebx
f0105d04:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105d07:	39 f0                	cmp    %esi,%eax
f0105d09:	74 17                	je     f0105d22 <strncmp+0x42>
f0105d0b:	0f b6 08             	movzbl (%eax),%ecx
f0105d0e:	84 c9                	test   %cl,%cl
f0105d10:	74 17                	je     f0105d29 <strncmp+0x49>
f0105d12:	83 c0 01             	add    $0x1,%eax
f0105d15:	3a 0a                	cmp    (%edx),%cl
f0105d17:	74 e9                	je     f0105d02 <strncmp+0x22>
f0105d19:	eb 0e                	jmp    f0105d29 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105d1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d20:	eb 0f                	jmp    f0105d31 <strncmp+0x51>
f0105d22:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d27:	eb 08                	jmp    f0105d31 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105d29:	0f b6 03             	movzbl (%ebx),%eax
f0105d2c:	0f b6 12             	movzbl (%edx),%edx
f0105d2f:	29 d0                	sub    %edx,%eax
}
f0105d31:	5b                   	pop    %ebx
f0105d32:	5e                   	pop    %esi
f0105d33:	5d                   	pop    %ebp
f0105d34:	c3                   	ret    

f0105d35 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105d35:	55                   	push   %ebp
f0105d36:	89 e5                	mov    %esp,%ebp
f0105d38:	53                   	push   %ebx
f0105d39:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d3c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0105d3f:	0f b6 18             	movzbl (%eax),%ebx
f0105d42:	84 db                	test   %bl,%bl
f0105d44:	74 1d                	je     f0105d63 <strchr+0x2e>
f0105d46:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0105d48:	38 d3                	cmp    %dl,%bl
f0105d4a:	75 06                	jne    f0105d52 <strchr+0x1d>
f0105d4c:	eb 1a                	jmp    f0105d68 <strchr+0x33>
f0105d4e:	38 ca                	cmp    %cl,%dl
f0105d50:	74 16                	je     f0105d68 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105d52:	83 c0 01             	add    $0x1,%eax
f0105d55:	0f b6 10             	movzbl (%eax),%edx
f0105d58:	84 d2                	test   %dl,%dl
f0105d5a:	75 f2                	jne    f0105d4e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0105d5c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d61:	eb 05                	jmp    f0105d68 <strchr+0x33>
f0105d63:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105d68:	5b                   	pop    %ebx
f0105d69:	5d                   	pop    %ebp
f0105d6a:	c3                   	ret    

f0105d6b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105d6b:	55                   	push   %ebp
f0105d6c:	89 e5                	mov    %esp,%ebp
f0105d6e:	53                   	push   %ebx
f0105d6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d72:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0105d75:	0f b6 18             	movzbl (%eax),%ebx
f0105d78:	84 db                	test   %bl,%bl
f0105d7a:	74 16                	je     f0105d92 <strfind+0x27>
f0105d7c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0105d7e:	38 d3                	cmp    %dl,%bl
f0105d80:	75 06                	jne    f0105d88 <strfind+0x1d>
f0105d82:	eb 0e                	jmp    f0105d92 <strfind+0x27>
f0105d84:	38 ca                	cmp    %cl,%dl
f0105d86:	74 0a                	je     f0105d92 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0105d88:	83 c0 01             	add    $0x1,%eax
f0105d8b:	0f b6 10             	movzbl (%eax),%edx
f0105d8e:	84 d2                	test   %dl,%dl
f0105d90:	75 f2                	jne    f0105d84 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f0105d92:	5b                   	pop    %ebx
f0105d93:	5d                   	pop    %ebp
f0105d94:	c3                   	ret    

f0105d95 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105d95:	55                   	push   %ebp
f0105d96:	89 e5                	mov    %esp,%ebp
f0105d98:	83 ec 0c             	sub    $0xc,%esp
f0105d9b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0105d9e:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0105da1:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0105da4:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105da7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105daa:	85 c9                	test   %ecx,%ecx
f0105dac:	74 36                	je     f0105de4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105dae:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105db4:	75 28                	jne    f0105dde <memset+0x49>
f0105db6:	f6 c1 03             	test   $0x3,%cl
f0105db9:	75 23                	jne    f0105dde <memset+0x49>
		c &= 0xFF;
f0105dbb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105dbf:	89 d3                	mov    %edx,%ebx
f0105dc1:	c1 e3 08             	shl    $0x8,%ebx
f0105dc4:	89 d6                	mov    %edx,%esi
f0105dc6:	c1 e6 18             	shl    $0x18,%esi
f0105dc9:	89 d0                	mov    %edx,%eax
f0105dcb:	c1 e0 10             	shl    $0x10,%eax
f0105dce:	09 f0                	or     %esi,%eax
f0105dd0:	09 c2                	or     %eax,%edx
f0105dd2:	89 d0                	mov    %edx,%eax
f0105dd4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105dd6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0105dd9:	fc                   	cld    
f0105dda:	f3 ab                	rep stos %eax,%es:(%edi)
f0105ddc:	eb 06                	jmp    f0105de4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105dde:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105de1:	fc                   	cld    
f0105de2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105de4:	89 f8                	mov    %edi,%eax
f0105de6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0105de9:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0105dec:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0105def:	89 ec                	mov    %ebp,%esp
f0105df1:	5d                   	pop    %ebp
f0105df2:	c3                   	ret    

f0105df3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105df3:	55                   	push   %ebp
f0105df4:	89 e5                	mov    %esp,%ebp
f0105df6:	83 ec 08             	sub    $0x8,%esp
f0105df9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0105dfc:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0105dff:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e02:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105e05:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105e08:	39 c6                	cmp    %eax,%esi
f0105e0a:	73 36                	jae    f0105e42 <memmove+0x4f>
f0105e0c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105e0f:	39 d0                	cmp    %edx,%eax
f0105e11:	73 2f                	jae    f0105e42 <memmove+0x4f>
		s += n;
		d += n;
f0105e13:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105e16:	f6 c2 03             	test   $0x3,%dl
f0105e19:	75 1b                	jne    f0105e36 <memmove+0x43>
f0105e1b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105e21:	75 13                	jne    f0105e36 <memmove+0x43>
f0105e23:	f6 c1 03             	test   $0x3,%cl
f0105e26:	75 0e                	jne    f0105e36 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105e28:	83 ef 04             	sub    $0x4,%edi
f0105e2b:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105e2e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0105e31:	fd                   	std    
f0105e32:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105e34:	eb 09                	jmp    f0105e3f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105e36:	83 ef 01             	sub    $0x1,%edi
f0105e39:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105e3c:	fd                   	std    
f0105e3d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105e3f:	fc                   	cld    
f0105e40:	eb 20                	jmp    f0105e62 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105e42:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105e48:	75 13                	jne    f0105e5d <memmove+0x6a>
f0105e4a:	a8 03                	test   $0x3,%al
f0105e4c:	75 0f                	jne    f0105e5d <memmove+0x6a>
f0105e4e:	f6 c1 03             	test   $0x3,%cl
f0105e51:	75 0a                	jne    f0105e5d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105e53:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0105e56:	89 c7                	mov    %eax,%edi
f0105e58:	fc                   	cld    
f0105e59:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105e5b:	eb 05                	jmp    f0105e62 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105e5d:	89 c7                	mov    %eax,%edi
f0105e5f:	fc                   	cld    
f0105e60:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105e62:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0105e65:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0105e68:	89 ec                	mov    %ebp,%esp
f0105e6a:	5d                   	pop    %ebp
f0105e6b:	c3                   	ret    

f0105e6c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0105e6c:	55                   	push   %ebp
f0105e6d:	89 e5                	mov    %esp,%ebp
f0105e6f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105e72:	8b 45 10             	mov    0x10(%ebp),%eax
f0105e75:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105e79:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105e7c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105e80:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e83:	89 04 24             	mov    %eax,(%esp)
f0105e86:	e8 68 ff ff ff       	call   f0105df3 <memmove>
}
f0105e8b:	c9                   	leave  
f0105e8c:	c3                   	ret    

f0105e8d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105e8d:	55                   	push   %ebp
f0105e8e:	89 e5                	mov    %esp,%ebp
f0105e90:	57                   	push   %edi
f0105e91:	56                   	push   %esi
f0105e92:	53                   	push   %ebx
f0105e93:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0105e96:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105e99:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105e9c:	8d 78 ff             	lea    -0x1(%eax),%edi
f0105e9f:	85 c0                	test   %eax,%eax
f0105ea1:	74 36                	je     f0105ed9 <memcmp+0x4c>
		if (*s1 != *s2)
f0105ea3:	0f b6 03             	movzbl (%ebx),%eax
f0105ea6:	0f b6 0e             	movzbl (%esi),%ecx
f0105ea9:	38 c8                	cmp    %cl,%al
f0105eab:	75 17                	jne    f0105ec4 <memcmp+0x37>
f0105ead:	ba 00 00 00 00       	mov    $0x0,%edx
f0105eb2:	eb 1a                	jmp    f0105ece <memcmp+0x41>
f0105eb4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0105eb9:	83 c2 01             	add    $0x1,%edx
f0105ebc:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0105ec0:	38 c8                	cmp    %cl,%al
f0105ec2:	74 0a                	je     f0105ece <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0105ec4:	0f b6 c0             	movzbl %al,%eax
f0105ec7:	0f b6 c9             	movzbl %cl,%ecx
f0105eca:	29 c8                	sub    %ecx,%eax
f0105ecc:	eb 10                	jmp    f0105ede <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105ece:	39 fa                	cmp    %edi,%edx
f0105ed0:	75 e2                	jne    f0105eb4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105ed2:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ed7:	eb 05                	jmp    f0105ede <memcmp+0x51>
f0105ed9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105ede:	5b                   	pop    %ebx
f0105edf:	5e                   	pop    %esi
f0105ee0:	5f                   	pop    %edi
f0105ee1:	5d                   	pop    %ebp
f0105ee2:	c3                   	ret    

f0105ee3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105ee3:	55                   	push   %ebp
f0105ee4:	89 e5                	mov    %esp,%ebp
f0105ee6:	53                   	push   %ebx
f0105ee7:	8b 45 08             	mov    0x8(%ebp),%eax
f0105eea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0105eed:	89 c2                	mov    %eax,%edx
f0105eef:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105ef2:	39 d0                	cmp    %edx,%eax
f0105ef4:	73 13                	jae    f0105f09 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105ef6:	89 d9                	mov    %ebx,%ecx
f0105ef8:	38 18                	cmp    %bl,(%eax)
f0105efa:	75 06                	jne    f0105f02 <memfind+0x1f>
f0105efc:	eb 0b                	jmp    f0105f09 <memfind+0x26>
f0105efe:	38 08                	cmp    %cl,(%eax)
f0105f00:	74 07                	je     f0105f09 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105f02:	83 c0 01             	add    $0x1,%eax
f0105f05:	39 d0                	cmp    %edx,%eax
f0105f07:	75 f5                	jne    f0105efe <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105f09:	5b                   	pop    %ebx
f0105f0a:	5d                   	pop    %ebp
f0105f0b:	c3                   	ret    

f0105f0c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105f0c:	55                   	push   %ebp
f0105f0d:	89 e5                	mov    %esp,%ebp
f0105f0f:	57                   	push   %edi
f0105f10:	56                   	push   %esi
f0105f11:	53                   	push   %ebx
f0105f12:	83 ec 04             	sub    $0x4,%esp
f0105f15:	8b 55 08             	mov    0x8(%ebp),%edx
f0105f18:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105f1b:	0f b6 02             	movzbl (%edx),%eax
f0105f1e:	3c 09                	cmp    $0x9,%al
f0105f20:	74 04                	je     f0105f26 <strtol+0x1a>
f0105f22:	3c 20                	cmp    $0x20,%al
f0105f24:	75 0e                	jne    f0105f34 <strtol+0x28>
		s++;
f0105f26:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105f29:	0f b6 02             	movzbl (%edx),%eax
f0105f2c:	3c 09                	cmp    $0x9,%al
f0105f2e:	74 f6                	je     f0105f26 <strtol+0x1a>
f0105f30:	3c 20                	cmp    $0x20,%al
f0105f32:	74 f2                	je     f0105f26 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105f34:	3c 2b                	cmp    $0x2b,%al
f0105f36:	75 0a                	jne    f0105f42 <strtol+0x36>
		s++;
f0105f38:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105f3b:	bf 00 00 00 00       	mov    $0x0,%edi
f0105f40:	eb 10                	jmp    f0105f52 <strtol+0x46>
f0105f42:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105f47:	3c 2d                	cmp    $0x2d,%al
f0105f49:	75 07                	jne    f0105f52 <strtol+0x46>
		s++, neg = 1;
f0105f4b:	83 c2 01             	add    $0x1,%edx
f0105f4e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105f52:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105f58:	75 15                	jne    f0105f6f <strtol+0x63>
f0105f5a:	80 3a 30             	cmpb   $0x30,(%edx)
f0105f5d:	75 10                	jne    f0105f6f <strtol+0x63>
f0105f5f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105f63:	75 0a                	jne    f0105f6f <strtol+0x63>
		s += 2, base = 16;
f0105f65:	83 c2 02             	add    $0x2,%edx
f0105f68:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105f6d:	eb 10                	jmp    f0105f7f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0105f6f:	85 db                	test   %ebx,%ebx
f0105f71:	75 0c                	jne    f0105f7f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105f73:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105f75:	80 3a 30             	cmpb   $0x30,(%edx)
f0105f78:	75 05                	jne    f0105f7f <strtol+0x73>
		s++, base = 8;
f0105f7a:	83 c2 01             	add    $0x1,%edx
f0105f7d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0105f7f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105f84:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105f87:	0f b6 0a             	movzbl (%edx),%ecx
f0105f8a:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0105f8d:	89 f3                	mov    %esi,%ebx
f0105f8f:	80 fb 09             	cmp    $0x9,%bl
f0105f92:	77 08                	ja     f0105f9c <strtol+0x90>
			dig = *s - '0';
f0105f94:	0f be c9             	movsbl %cl,%ecx
f0105f97:	83 e9 30             	sub    $0x30,%ecx
f0105f9a:	eb 22                	jmp    f0105fbe <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0105f9c:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0105f9f:	89 f3                	mov    %esi,%ebx
f0105fa1:	80 fb 19             	cmp    $0x19,%bl
f0105fa4:	77 08                	ja     f0105fae <strtol+0xa2>
			dig = *s - 'a' + 10;
f0105fa6:	0f be c9             	movsbl %cl,%ecx
f0105fa9:	83 e9 57             	sub    $0x57,%ecx
f0105fac:	eb 10                	jmp    f0105fbe <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0105fae:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0105fb1:	89 f3                	mov    %esi,%ebx
f0105fb3:	80 fb 19             	cmp    $0x19,%bl
f0105fb6:	77 16                	ja     f0105fce <strtol+0xc2>
			dig = *s - 'A' + 10;
f0105fb8:	0f be c9             	movsbl %cl,%ecx
f0105fbb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105fbe:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0105fc1:	7d 0f                	jge    f0105fd2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0105fc3:	83 c2 01             	add    $0x1,%edx
f0105fc6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0105fca:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0105fcc:	eb b9                	jmp    f0105f87 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0105fce:	89 c1                	mov    %eax,%ecx
f0105fd0:	eb 02                	jmp    f0105fd4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0105fd2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0105fd4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105fd8:	74 05                	je     f0105fdf <strtol+0xd3>
		*endptr = (char *) s;
f0105fda:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105fdd:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0105fdf:	89 ca                	mov    %ecx,%edx
f0105fe1:	f7 da                	neg    %edx
f0105fe3:	85 ff                	test   %edi,%edi
f0105fe5:	0f 45 c2             	cmovne %edx,%eax
}
f0105fe8:	83 c4 04             	add    $0x4,%esp
f0105feb:	5b                   	pop    %ebx
f0105fec:	5e                   	pop    %esi
f0105fed:	5f                   	pop    %edi
f0105fee:	5d                   	pop    %ebp
f0105fef:	c3                   	ret    

f0105ff0 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105ff0:	fa                   	cli    

	xorw    %ax, %ax
f0105ff1:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105ff3:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105ff5:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105ff7:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105ff9:	0f 01 16             	lgdtl  (%esi)
f0105ffc:	74 70                	je     f010606e <mpentry_end+0x4>
	movl    %cr0, %eax
f0105ffe:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0106001:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0106005:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0106008:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010600e:	08 00                	or     %al,(%eax)

f0106010 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0106010:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0106014:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0106016:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0106018:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f010601a:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010601e:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0106020:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0106022:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl    %eax, %cr3
f0106027:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f010602a:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f010602d:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0106032:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in mem_init()
	movl    mpentry_kstack, %esp
f0106035:	8b 25 84 ae 22 f0    	mov    0xf022ae84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f010603b:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0106040:	b8 a8 00 10 f0       	mov    $0xf01000a8,%eax
	call    *%eax
f0106045:	ff d0                	call   *%eax

f0106047 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0106047:	eb fe                	jmp    f0106047 <spin>
f0106049:	8d 76 00             	lea    0x0(%esi),%esi

f010604c <gdt>:
	...
f0106054:	ff                   	(bad)  
f0106055:	ff 00                	incl   (%eax)
f0106057:	00 00                	add    %al,(%eax)
f0106059:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0106060:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0106064 <gdtdesc>:
f0106064:	17                   	pop    %ss
f0106065:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f010606a <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f010606a:	90                   	nop
f010606b:	66 90                	xchg   %ax,%ax
f010606d:	66 90                	xchg   %ax,%ax
f010606f:	90                   	nop

f0106070 <sum>:
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0106070:	85 d2                	test   %edx,%edx
f0106072:	7e 1c                	jle    f0106090 <sum+0x20>
#define MPIOINTR  0x03  // One per bus interrupt source
#define MPLINTR   0x04  // One per system interrupt source

static uint8_t
sum(void *addr, int len)
{
f0106074:	55                   	push   %ebp
f0106075:	89 e5                	mov    %esp,%ebp
f0106077:	53                   	push   %ebx
f0106078:	89 c1                	mov    %eax,%ecx
#define MPIOAPIC  0x02  // One per I/O APIC
#define MPIOINTR  0x03  // One per bus interrupt source
#define MPLINTR   0x04  // One per system interrupt source

static uint8_t
sum(void *addr, int len)
f010607a:	8d 1c 10             	lea    (%eax,%edx,1),%ebx
{
	int i, sum;

	sum = 0;
f010607d:	b8 00 00 00 00       	mov    $0x0,%eax
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0106082:	0f b6 11             	movzbl (%ecx),%edx
f0106085:	01 d0                	add    %edx,%eax
f0106087:	83 c1 01             	add    $0x1,%ecx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010608a:	39 d9                	cmp    %ebx,%ecx
f010608c:	75 f4                	jne    f0106082 <sum+0x12>
f010608e:	eb 06                	jmp    f0106096 <sum+0x26>
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0106090:	b8 00 00 00 00       	mov    $0x0,%eax
f0106095:	c3                   	ret    
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
	return sum;
}
f0106096:	5b                   	pop    %ebx
f0106097:	5d                   	pop    %ebp
f0106098:	c3                   	ret    

f0106099 <mpsearch1>:

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0106099:	55                   	push   %ebp
f010609a:	89 e5                	mov    %esp,%ebp
f010609c:	56                   	push   %esi
f010609d:	53                   	push   %ebx
f010609e:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01060a1:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f01060a7:	89 c3                	mov    %eax,%ebx
f01060a9:	c1 eb 0c             	shr    $0xc,%ebx
f01060ac:	39 cb                	cmp    %ecx,%ebx
f01060ae:	72 20                	jb     f01060d0 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01060b0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01060b4:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01060bb:	f0 
f01060bc:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f01060c3:	00 
f01060c4:	c7 04 24 a1 84 10 f0 	movl   $0xf01084a1,(%esp)
f01060cb:	e8 70 9f ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01060d0:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01060d6:	8d 34 02             	lea    (%edx,%eax,1),%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01060d9:	89 f0                	mov    %esi,%eax
f01060db:	c1 e8 0c             	shr    $0xc,%eax
f01060de:	39 c1                	cmp    %eax,%ecx
f01060e0:	77 20                	ja     f0106102 <mpsearch1+0x69>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01060e2:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01060e6:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01060ed:	f0 
f01060ee:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f01060f5:	00 
f01060f6:	c7 04 24 a1 84 10 f0 	movl   $0xf01084a1,(%esp)
f01060fd:	e8 3e 9f ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0106102:	81 ee 00 00 00 10    	sub    $0x10000000,%esi

	for (; mp < end; mp++)
f0106108:	39 f3                	cmp    %esi,%ebx
f010610a:	73 3a                	jae    f0106146 <mpsearch1+0xad>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010610c:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0106113:	00 
f0106114:	c7 44 24 04 b1 84 10 	movl   $0xf01084b1,0x4(%esp)
f010611b:	f0 
f010611c:	89 1c 24             	mov    %ebx,(%esp)
f010611f:	e8 69 fd ff ff       	call   f0105e8d <memcmp>
f0106124:	85 c0                	test   %eax,%eax
f0106126:	75 10                	jne    f0106138 <mpsearch1+0x9f>
		    sum(mp, sizeof(*mp)) == 0)
f0106128:	ba 10 00 00 00       	mov    $0x10,%edx
f010612d:	89 d8                	mov    %ebx,%eax
f010612f:	e8 3c ff ff ff       	call   f0106070 <sum>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0106134:	84 c0                	test   %al,%al
f0106136:	74 13                	je     f010614b <mpsearch1+0xb2>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0106138:	83 c3 10             	add    $0x10,%ebx
f010613b:	39 f3                	cmp    %esi,%ebx
f010613d:	72 cd                	jb     f010610c <mpsearch1+0x73>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010613f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0106144:	eb 05                	jmp    f010614b <mpsearch1+0xb2>
f0106146:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010614b:	89 d8                	mov    %ebx,%eax
f010614d:	83 c4 10             	add    $0x10,%esp
f0106150:	5b                   	pop    %ebx
f0106151:	5e                   	pop    %esi
f0106152:	5d                   	pop    %ebp
f0106153:	c3                   	ret    

f0106154 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0106154:	55                   	push   %ebp
f0106155:	89 e5                	mov    %esp,%ebp
f0106157:	57                   	push   %edi
f0106158:	56                   	push   %esi
f0106159:	53                   	push   %ebx
f010615a:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f010615d:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f0106164:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106167:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f010616e:	75 24                	jne    f0106194 <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106170:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f0106177:	00 
f0106178:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f010617f:	f0 
f0106180:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0106187:	00 
f0106188:	c7 04 24 a1 84 10 f0 	movl   $0xf01084a1,(%esp)
f010618f:	e8 ac 9e ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0106194:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f010619b:	85 c0                	test   %eax,%eax
f010619d:	74 16                	je     f01061b5 <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f010619f:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f01061a2:	ba 00 04 00 00       	mov    $0x400,%edx
f01061a7:	e8 ed fe ff ff       	call   f0106099 <mpsearch1>
f01061ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01061af:	85 c0                	test   %eax,%eax
f01061b1:	75 3c                	jne    f01061ef <mp_init+0x9b>
f01061b3:	eb 20                	jmp    f01061d5 <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f01061b5:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f01061bc:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f01061bf:	2d 00 04 00 00       	sub    $0x400,%eax
f01061c4:	ba 00 04 00 00       	mov    $0x400,%edx
f01061c9:	e8 cb fe ff ff       	call   f0106099 <mpsearch1>
f01061ce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01061d1:	85 c0                	test   %eax,%eax
f01061d3:	75 1a                	jne    f01061ef <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01061d5:	ba 00 00 01 00       	mov    $0x10000,%edx
f01061da:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01061df:	e8 b5 fe ff ff       	call   f0106099 <mpsearch1>
f01061e4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01061e7:	85 c0                	test   %eax,%eax
f01061e9:	0f 84 2a 02 00 00    	je     f0106419 <mp_init+0x2c5>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01061ef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01061f2:	8b 78 04             	mov    0x4(%eax),%edi
f01061f5:	85 ff                	test   %edi,%edi
f01061f7:	74 06                	je     f01061ff <mp_init+0xab>
f01061f9:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01061fd:	74 11                	je     f0106210 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f01061ff:	c7 04 24 14 83 10 f0 	movl   $0xf0108314,(%esp)
f0106206:	e8 eb da ff ff       	call   f0103cf6 <cprintf>
f010620b:	e9 09 02 00 00       	jmp    f0106419 <mp_init+0x2c5>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106210:	89 f8                	mov    %edi,%eax
f0106212:	c1 e8 0c             	shr    $0xc,%eax
f0106215:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010621b:	72 20                	jb     f010623d <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010621d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106221:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f0106228:	f0 
f0106229:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0106230:	00 
f0106231:	c7 04 24 a1 84 10 f0 	movl   $0xf01084a1,(%esp)
f0106238:	e8 03 9e ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010623d:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0106243:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f010624a:	00 
f010624b:	c7 44 24 04 b6 84 10 	movl   $0xf01084b6,0x4(%esp)
f0106252:	f0 
f0106253:	89 3c 24             	mov    %edi,(%esp)
f0106256:	e8 32 fc ff ff       	call   f0105e8d <memcmp>
f010625b:	85 c0                	test   %eax,%eax
f010625d:	74 11                	je     f0106270 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f010625f:	c7 04 24 44 83 10 f0 	movl   $0xf0108344,(%esp)
f0106266:	e8 8b da ff ff       	call   f0103cf6 <cprintf>
f010626b:	e9 a9 01 00 00       	jmp    f0106419 <mp_init+0x2c5>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0106270:	0f b7 5f 04          	movzwl 0x4(%edi),%ebx
f0106274:	0f b7 d3             	movzwl %bx,%edx
f0106277:	89 f8                	mov    %edi,%eax
f0106279:	e8 f2 fd ff ff       	call   f0106070 <sum>
f010627e:	84 c0                	test   %al,%al
f0106280:	74 11                	je     f0106293 <mp_init+0x13f>
		cprintf("SMP: Bad MP configuration checksum\n");
f0106282:	c7 04 24 78 83 10 f0 	movl   $0xf0108378,(%esp)
f0106289:	e8 68 da ff ff       	call   f0103cf6 <cprintf>
f010628e:	e9 86 01 00 00       	jmp    f0106419 <mp_init+0x2c5>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0106293:	0f b6 47 06          	movzbl 0x6(%edi),%eax
f0106297:	3c 04                	cmp    $0x4,%al
f0106299:	74 1f                	je     f01062ba <mp_init+0x166>
f010629b:	3c 01                	cmp    $0x1,%al
f010629d:	8d 76 00             	lea    0x0(%esi),%esi
f01062a0:	74 18                	je     f01062ba <mp_init+0x166>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01062a2:	0f b6 c0             	movzbl %al,%eax
f01062a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01062a9:	c7 04 24 9c 83 10 f0 	movl   $0xf010839c,(%esp)
f01062b0:	e8 41 da ff ff       	call   f0103cf6 <cprintf>
f01062b5:	e9 5f 01 00 00       	jmp    f0106419 <mp_init+0x2c5>
		return NULL;
	}
	if (sum((uint8_t *)conf + conf->length, conf->xlength) != conf->xchecksum) {
f01062ba:	0f b7 57 28          	movzwl 0x28(%edi),%edx
f01062be:	0f b7 db             	movzwl %bx,%ebx
f01062c1:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f01062c4:	e8 a7 fd ff ff       	call   f0106070 <sum>
f01062c9:	3a 47 2a             	cmp    0x2a(%edi),%al
f01062cc:	74 11                	je     f01062df <mp_init+0x18b>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01062ce:	c7 04 24 bc 83 10 f0 	movl   $0xf01083bc,(%esp)
f01062d5:	e8 1c da ff ff       	call   f0103cf6 <cprintf>
f01062da:	e9 3a 01 00 00       	jmp    f0106419 <mp_init+0x2c5>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01062df:	85 ff                	test   %edi,%edi
f01062e1:	0f 84 32 01 00 00    	je     f0106419 <mp_init+0x2c5>
		return;
	ismp = 1;
f01062e7:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f01062ee:	00 00 00 
	lapic = (uint32_t *)conf->lapicaddr;
f01062f1:	8b 47 24             	mov    0x24(%edi),%eax
f01062f4:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01062f9:	8d 77 2c             	lea    0x2c(%edi),%esi
f01062fc:	66 83 7f 22 00       	cmpw   $0x0,0x22(%edi)
f0106301:	0f 84 97 00 00 00    	je     f010639e <mp_init+0x24a>
f0106307:	bb 00 00 00 00       	mov    $0x0,%ebx
		switch (*p) {
f010630c:	0f b6 06             	movzbl (%esi),%eax
f010630f:	84 c0                	test   %al,%al
f0106311:	74 06                	je     f0106319 <mp_init+0x1c5>
f0106313:	3c 04                	cmp    $0x4,%al
f0106315:	77 57                	ja     f010636e <mp_init+0x21a>
f0106317:	eb 50                	jmp    f0106369 <mp_init+0x215>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0106319:	f6 46 03 02          	testb  $0x2,0x3(%esi)
f010631d:	8d 76 00             	lea    0x0(%esi),%esi
f0106320:	74 11                	je     f0106333 <mp_init+0x1df>
				bootcpu = &cpus[ncpu];
f0106322:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f0106329:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010632e:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f0106333:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f0106338:	83 f8 07             	cmp    $0x7,%eax
f010633b:	7f 13                	jg     f0106350 <mp_init+0x1fc>
				cpus[ncpu].cpu_id = ncpu;
f010633d:	6b d0 74             	imul   $0x74,%eax,%edx
f0106340:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f0106346:	83 c0 01             	add    $0x1,%eax
f0106349:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f010634e:	eb 14                	jmp    f0106364 <mp_init+0x210>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0106350:	0f b6 46 01          	movzbl 0x1(%esi),%eax
f0106354:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106358:	c7 04 24 ec 83 10 f0 	movl   $0xf01083ec,(%esp)
f010635f:	e8 92 d9 ff ff       	call   f0103cf6 <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0106364:	83 c6 14             	add    $0x14,%esi
			continue;
f0106367:	eb 26                	jmp    f010638f <mp_init+0x23b>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0106369:	83 c6 08             	add    $0x8,%esi
			continue;
f010636c:	eb 21                	jmp    f010638f <mp_init+0x23b>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010636e:	0f b6 c0             	movzbl %al,%eax
f0106371:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106375:	c7 04 24 14 84 10 f0 	movl   $0xf0108414,(%esp)
f010637c:	e8 75 d9 ff ff       	call   f0103cf6 <cprintf>
			ismp = 0;
f0106381:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f0106388:	00 00 00 
			i = conf->entry;
f010638b:	0f b7 5f 22          	movzwl 0x22(%edi),%ebx
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapic = (uint32_t *)conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010638f:	83 c3 01             	add    $0x1,%ebx
f0106392:	0f b7 47 22          	movzwl 0x22(%edi),%eax
f0106396:	39 d8                	cmp    %ebx,%eax
f0106398:	0f 87 6e ff ff ff    	ja     f010630c <mp_init+0x1b8>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010639e:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f01063a3:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01063aa:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f01063b1:	75 22                	jne    f01063d5 <mp_init+0x281>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01063b3:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f01063ba:	00 00 00 
		lapic = NULL;
f01063bd:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f01063c4:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01063c7:	c7 04 24 34 84 10 f0 	movl   $0xf0108434,(%esp)
f01063ce:	e8 23 d9 ff ff       	call   f0103cf6 <cprintf>
f01063d3:	eb 44                	jmp    f0106419 <mp_init+0x2c5>
		return;
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01063d5:	8b 15 c4 b3 22 f0    	mov    0xf022b3c4,%edx
f01063db:	89 54 24 08          	mov    %edx,0x8(%esp)
f01063df:	0f b6 00             	movzbl (%eax),%eax
f01063e2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01063e6:	c7 04 24 bb 84 10 f0 	movl   $0xf01084bb,(%esp)
f01063ed:	e8 04 d9 ff ff       	call   f0103cf6 <cprintf>

	if (mp->imcrp) {
f01063f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01063f5:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01063f9:	74 1e                	je     f0106419 <mp_init+0x2c5>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01063fb:	c7 04 24 60 84 10 f0 	movl   $0xf0108460,(%esp)
f0106402:	e8 ef d8 ff ff       	call   f0103cf6 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106407:	ba 22 00 00 00       	mov    $0x22,%edx
f010640c:	b8 70 00 00 00       	mov    $0x70,%eax
f0106411:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0106412:	b2 23                	mov    $0x23,%dl
f0106414:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0106415:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106418:	ee                   	out    %al,(%dx)
	}
}
f0106419:	83 c4 2c             	add    $0x2c,%esp
f010641c:	5b                   	pop    %ebx
f010641d:	5e                   	pop    %esi
f010641e:	5f                   	pop    %edi
f010641f:	5d                   	pop    %ebp
f0106420:	c3                   	ret    
f0106421:	66 90                	xchg   %ax,%ax
f0106423:	90                   	nop

f0106424 <lapicw>:

volatile uint32_t *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
f0106424:	55                   	push   %ebp
f0106425:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0106427:	8b 0d 00 c0 26 f0    	mov    0xf026c000,%ecx
f010642d:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0106430:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0106432:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f0106437:	8b 40 20             	mov    0x20(%eax),%eax
}
f010643a:	5d                   	pop    %ebp
f010643b:	c3                   	ret    

f010643c <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010643c:	55                   	push   %ebp
f010643d:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010643f:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f0106444:	85 c0                	test   %eax,%eax
f0106446:	74 08                	je     f0106450 <cpunum+0x14>
		return lapic[ID] >> 24;
f0106448:	8b 40 20             	mov    0x20(%eax),%eax
f010644b:	c1 e8 18             	shr    $0x18,%eax
f010644e:	eb 05                	jmp    f0106455 <cpunum+0x19>
	return 0;
f0106450:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106455:	5d                   	pop    %ebp
f0106456:	c3                   	ret    

f0106457 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapic) 
f0106457:	83 3d 00 c0 26 f0 00 	cmpl   $0x0,0xf026c000
f010645e:	0f 84 0b 01 00 00    	je     f010656f <lapic_init+0x118>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0106464:	55                   	push   %ebp
f0106465:	89 e5                	mov    %esp,%ebp
	if (!lapic) 
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0106467:	ba 27 01 00 00       	mov    $0x127,%edx
f010646c:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106471:	e8 ae ff ff ff       	call   f0106424 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0106476:	ba 0b 00 00 00       	mov    $0xb,%edx
f010647b:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0106480:	e8 9f ff ff ff       	call   f0106424 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0106485:	ba 20 00 02 00       	mov    $0x20020,%edx
f010648a:	b8 c8 00 00 00       	mov    $0xc8,%eax
f010648f:	e8 90 ff ff ff       	call   f0106424 <lapicw>
	lapicw(TICR, 10000000); 
f0106494:	ba 80 96 98 00       	mov    $0x989680,%edx
f0106499:	b8 e0 00 00 00       	mov    $0xe0,%eax
f010649e:	e8 81 ff ff ff       	call   f0106424 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f01064a3:	e8 94 ff ff ff       	call   f010643c <cpunum>
f01064a8:	6b c0 74             	imul   $0x74,%eax,%eax
f01064ab:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01064b0:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f01064b6:	74 0f                	je     f01064c7 <lapic_init+0x70>
		lapicw(LINT0, MASKED);
f01064b8:	ba 00 00 01 00       	mov    $0x10000,%edx
f01064bd:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01064c2:	e8 5d ff ff ff       	call   f0106424 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01064c7:	ba 00 00 01 00       	mov    $0x10000,%edx
f01064cc:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01064d1:	e8 4e ff ff ff       	call   f0106424 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01064d6:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f01064db:	8b 40 30             	mov    0x30(%eax),%eax
f01064de:	c1 e8 10             	shr    $0x10,%eax
f01064e1:	3c 03                	cmp    $0x3,%al
f01064e3:	76 0f                	jbe    f01064f4 <lapic_init+0x9d>
		lapicw(PCINT, MASKED);
f01064e5:	ba 00 00 01 00       	mov    $0x10000,%edx
f01064ea:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01064ef:	e8 30 ff ff ff       	call   f0106424 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01064f4:	ba 33 00 00 00       	mov    $0x33,%edx
f01064f9:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01064fe:	e8 21 ff ff ff       	call   f0106424 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0106503:	ba 00 00 00 00       	mov    $0x0,%edx
f0106508:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010650d:	e8 12 ff ff ff       	call   f0106424 <lapicw>
	lapicw(ESR, 0);
f0106512:	ba 00 00 00 00       	mov    $0x0,%edx
f0106517:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010651c:	e8 03 ff ff ff       	call   f0106424 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0106521:	ba 00 00 00 00       	mov    $0x0,%edx
f0106526:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010652b:	e8 f4 fe ff ff       	call   f0106424 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0106530:	ba 00 00 00 00       	mov    $0x0,%edx
f0106535:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010653a:	e8 e5 fe ff ff       	call   f0106424 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f010653f:	ba 00 85 08 00       	mov    $0x88500,%edx
f0106544:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106549:	e8 d6 fe ff ff       	call   f0106424 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f010654e:	8b 15 00 c0 26 f0    	mov    0xf026c000,%edx
f0106554:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010655a:	f6 c4 10             	test   $0x10,%ah
f010655d:	75 f5                	jne    f0106554 <lapic_init+0xfd>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f010655f:	ba 00 00 00 00       	mov    $0x0,%edx
f0106564:	b8 20 00 00 00       	mov    $0x20,%eax
f0106569:	e8 b6 fe ff ff       	call   f0106424 <lapicw>
}
f010656e:	5d                   	pop    %ebp
f010656f:	f3 c3                	repz ret 

f0106571 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0106571:	83 3d 00 c0 26 f0 00 	cmpl   $0x0,0xf026c000
f0106578:	74 13                	je     f010658d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010657a:	55                   	push   %ebp
f010657b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f010657d:	ba 00 00 00 00       	mov    $0x0,%edx
f0106582:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106587:	e8 98 fe ff ff       	call   f0106424 <lapicw>
}
f010658c:	5d                   	pop    %ebp
f010658d:	f3 c3                	repz ret 

f010658f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f010658f:	55                   	push   %ebp
f0106590:	89 e5                	mov    %esp,%ebp
f0106592:	56                   	push   %esi
f0106593:	53                   	push   %ebx
f0106594:	83 ec 10             	sub    $0x10,%esp
f0106597:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010659a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010659d:	ba 70 00 00 00       	mov    $0x70,%edx
f01065a2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01065a7:	ee                   	out    %al,(%dx)
f01065a8:	b2 71                	mov    $0x71,%dl
f01065aa:	b8 0a 00 00 00       	mov    $0xa,%eax
f01065af:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01065b0:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f01065b7:	75 24                	jne    f01065dd <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01065b9:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f01065c0:	00 
f01065c1:	c7 44 24 08 e8 6b 10 	movl   $0xf0106be8,0x8(%esp)
f01065c8:	f0 
f01065c9:	c7 44 24 04 93 00 00 	movl   $0x93,0x4(%esp)
f01065d0:	00 
f01065d1:	c7 04 24 d8 84 10 f0 	movl   $0xf01084d8,(%esp)
f01065d8:	e8 63 9a ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01065dd:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01065e4:	00 00 
	wrv[1] = addr >> 4;
f01065e6:	89 f0                	mov    %esi,%eax
f01065e8:	c1 e8 04             	shr    $0x4,%eax
f01065eb:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01065f1:	c1 e3 18             	shl    $0x18,%ebx
f01065f4:	89 da                	mov    %ebx,%edx
f01065f6:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01065fb:	e8 24 fe ff ff       	call   f0106424 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0106600:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0106605:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010660a:	e8 15 fe ff ff       	call   f0106424 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f010660f:	ba 00 85 00 00       	mov    $0x8500,%edx
f0106614:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106619:	e8 06 fe ff ff       	call   f0106424 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010661e:	c1 ee 0c             	shr    $0xc,%esi
f0106621:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0106627:	89 da                	mov    %ebx,%edx
f0106629:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010662e:	e8 f1 fd ff ff       	call   f0106424 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106633:	89 f2                	mov    %esi,%edx
f0106635:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010663a:	e8 e5 fd ff ff       	call   f0106424 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010663f:	89 da                	mov    %ebx,%edx
f0106641:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106646:	e8 d9 fd ff ff       	call   f0106424 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010664b:	89 f2                	mov    %esi,%edx
f010664d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106652:	e8 cd fd ff ff       	call   f0106424 <lapicw>
		microdelay(200);
	}
}
f0106657:	83 c4 10             	add    $0x10,%esp
f010665a:	5b                   	pop    %ebx
f010665b:	5e                   	pop    %esi
f010665c:	5d                   	pop    %ebp
f010665d:	c3                   	ret    

f010665e <lapic_ipi>:

void
lapic_ipi(int vector)
{
f010665e:	55                   	push   %ebp
f010665f:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106661:	8b 55 08             	mov    0x8(%ebp),%edx
f0106664:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010666a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010666f:	e8 b0 fd ff ff       	call   f0106424 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106674:	8b 15 00 c0 26 f0    	mov    0xf026c000,%edx
f010667a:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106680:	f6 c4 10             	test   $0x10,%ah
f0106683:	75 f5                	jne    f010667a <lapic_ipi+0x1c>
		;
}
f0106685:	5d                   	pop    %ebp
f0106686:	c3                   	ret    
f0106687:	90                   	nop

f0106688 <holding>:

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0106688:	83 38 00             	cmpl   $0x0,(%eax)
f010668b:	74 21                	je     f01066ae <holding+0x26>
}

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
f010668d:	55                   	push   %ebp
f010668e:	89 e5                	mov    %esp,%ebp
f0106690:	53                   	push   %ebx
f0106691:	83 ec 04             	sub    $0x4,%esp
	return lock->locked && lock->cpu == thiscpu;
f0106694:	8b 58 08             	mov    0x8(%eax),%ebx
f0106697:	e8 a0 fd ff ff       	call   f010643c <cpunum>
f010669c:	6b c0 74             	imul   $0x74,%eax,%eax
f010669f:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01066a4:	39 c3                	cmp    %eax,%ebx
f01066a6:	0f 94 c0             	sete   %al
f01066a9:	0f b6 c0             	movzbl %al,%eax
f01066ac:	eb 06                	jmp    f01066b4 <holding+0x2c>
f01066ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01066b3:	c3                   	ret    
}
f01066b4:	83 c4 04             	add    $0x4,%esp
f01066b7:	5b                   	pop    %ebx
f01066b8:	5d                   	pop    %ebp
f01066b9:	c3                   	ret    

f01066ba <__spin_initlock>:
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01066ba:	55                   	push   %ebp
f01066bb:	89 e5                	mov    %esp,%ebp
f01066bd:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01066c0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01066c6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01066c9:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01066cc:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01066d3:	5d                   	pop    %ebp
f01066d4:	c3                   	ret    

f01066d5 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01066d5:	55                   	push   %ebp
f01066d6:	89 e5                	mov    %esp,%ebp
f01066d8:	53                   	push   %ebx
f01066d9:	83 ec 24             	sub    $0x24,%esp
f01066dc:	8b 5d 08             	mov    0x8(%ebp),%ebx
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01066df:	89 d8                	mov    %ebx,%eax
f01066e1:	e8 a2 ff ff ff       	call   f0106688 <holding>
f01066e6:	85 c0                	test   %eax,%eax
f01066e8:	75 12                	jne    f01066fc <spin_lock+0x27>
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01066ea:	89 da                	mov    %ebx,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01066ec:	b0 01                	mov    $0x1,%al
f01066ee:	f0 87 03             	lock xchg %eax,(%ebx)
f01066f1:	b9 01 00 00 00       	mov    $0x1,%ecx
f01066f6:	85 c0                	test   %eax,%eax
f01066f8:	75 2e                	jne    f0106728 <spin_lock+0x53>
f01066fa:	eb 37                	jmp    f0106733 <spin_lock+0x5e>
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01066fc:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01066ff:	e8 38 fd ff ff       	call   f010643c <cpunum>
f0106704:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0106708:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010670c:	c7 44 24 08 e8 84 10 	movl   $0xf01084e8,0x8(%esp)
f0106713:	f0 
f0106714:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
f010671b:	00 
f010671c:	c7 04 24 4c 85 10 f0 	movl   $0xf010854c,(%esp)
f0106723:	e8 18 99 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0106728:	f3 90                	pause  
f010672a:	89 c8                	mov    %ecx,%eax
f010672c:	f0 87 02             	lock xchg %eax,(%edx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f010672f:	85 c0                	test   %eax,%eax
f0106731:	75 f5                	jne    f0106728 <spin_lock+0x53>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0106733:	e8 04 fd ff ff       	call   f010643c <cpunum>
f0106738:	6b c0 74             	imul   $0x74,%eax,%eax
f010673b:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0106740:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0106743:	8d 4b 0c             	lea    0xc(%ebx),%ecx

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0106746:	89 e8                	mov    %ebp,%eax
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
		if (ebp == 0 || ebp < (uint32_t *)ULIM
		    || ebp >= (uint32_t *)IOMEMBASE)
f0106748:	8d 90 00 00 80 10    	lea    0x10800000(%eax),%edx
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
		if (ebp == 0 || ebp < (uint32_t *)ULIM
f010674e:	81 fa ff ff 7f 0e    	cmp    $0xe7fffff,%edx
f0106754:	76 3a                	jbe    f0106790 <spin_lock+0xbb>
f0106756:	eb 31                	jmp    f0106789 <spin_lock+0xb4>
		    || ebp >= (uint32_t *)IOMEMBASE)
f0106758:	8d 9a 00 00 80 10    	lea    0x10800000(%edx),%ebx
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
		if (ebp == 0 || ebp < (uint32_t *)ULIM
f010675e:	81 fb ff ff 7f 0e    	cmp    $0xe7fffff,%ebx
f0106764:	77 12                	ja     f0106778 <spin_lock+0xa3>
		    || ebp >= (uint32_t *)IOMEMBASE)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0106766:	8b 5a 04             	mov    0x4(%edx),%ebx
f0106769:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f010676c:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f010676e:	83 c0 01             	add    $0x1,%eax
f0106771:	83 f8 0a             	cmp    $0xa,%eax
f0106774:	75 e2                	jne    f0106758 <spin_lock+0x83>
f0106776:	eb 27                	jmp    f010679f <spin_lock+0xca>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0106778:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
		    || ebp >= (uint32_t *)IOMEMBASE)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f010677f:	83 c0 01             	add    $0x1,%eax
f0106782:	83 f8 09             	cmp    $0x9,%eax
f0106785:	7e f1                	jle    f0106778 <spin_lock+0xa3>
f0106787:	eb 16                	jmp    f010679f <spin_lock+0xca>
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0106789:	b8 00 00 00 00       	mov    $0x0,%eax
f010678e:	eb e8                	jmp    f0106778 <spin_lock+0xa3>
		if (ebp == 0 || ebp < (uint32_t *)ULIM
		    || ebp >= (uint32_t *)IOMEMBASE)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0106790:	8b 50 04             	mov    0x4(%eax),%edx
f0106793:	89 53 0c             	mov    %edx,0xc(%ebx)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106796:	8b 10                	mov    (%eax),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0106798:	b8 01 00 00 00       	mov    $0x1,%eax
f010679d:	eb b9                	jmp    f0106758 <spin_lock+0x83>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010679f:	83 c4 24             	add    $0x24,%esp
f01067a2:	5b                   	pop    %ebx
f01067a3:	5d                   	pop    %ebp
f01067a4:	c3                   	ret    

f01067a5 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f01067a5:	55                   	push   %ebp
f01067a6:	89 e5                	mov    %esp,%ebp
f01067a8:	83 ec 78             	sub    $0x78,%esp
f01067ab:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01067ae:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01067b1:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01067b4:	8b 5d 08             	mov    0x8(%ebp),%ebx
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f01067b7:	89 d8                	mov    %ebx,%eax
f01067b9:	e8 ca fe ff ff       	call   f0106688 <holding>
f01067be:	85 c0                	test   %eax,%eax
f01067c0:	0f 85 d4 00 00 00    	jne    f010689a <spin_unlock+0xf5>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f01067c6:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f01067cd:	00 
f01067ce:	8d 43 0c             	lea    0xc(%ebx),%eax
f01067d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01067d5:	8d 45 c0             	lea    -0x40(%ebp),%eax
f01067d8:	89 04 24             	mov    %eax,(%esp)
f01067db:	e8 13 f6 ff ff       	call   f0105df3 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f01067e0:	8b 43 08             	mov    0x8(%ebx),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f01067e3:	0f b6 30             	movzbl (%eax),%esi
f01067e6:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01067e9:	e8 4e fc ff ff       	call   f010643c <cpunum>
f01067ee:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01067f2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01067f6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01067fa:	c7 04 24 14 85 10 f0 	movl   $0xf0108514,(%esp)
f0106801:	e8 f0 d4 ff ff       	call   f0103cf6 <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106806:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0106809:	85 c0                	test   %eax,%eax
f010680b:	74 71                	je     f010687e <spin_unlock+0xd9>
f010680d:	8d 5d c0             	lea    -0x40(%ebp),%ebx
#endif
}

// Release the lock.
void
spin_unlock(struct spinlock *lk)
f0106810:	8d 7d e4             	lea    -0x1c(%ebp),%edi
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0106813:	8d 75 a8             	lea    -0x58(%ebp),%esi
f0106816:	89 74 24 04          	mov    %esi,0x4(%esp)
f010681a:	89 04 24             	mov    %eax,(%esp)
f010681d:	e8 64 e9 ff ff       	call   f0105186 <debuginfo_eip>
f0106822:	85 c0                	test   %eax,%eax
f0106824:	78 39                	js     f010685f <spin_unlock+0xba>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0106826:	8b 03                	mov    (%ebx),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106828:	89 c2                	mov    %eax,%edx
f010682a:	2b 55 b8             	sub    -0x48(%ebp),%edx
f010682d:	89 54 24 18          	mov    %edx,0x18(%esp)
f0106831:	8b 55 b0             	mov    -0x50(%ebp),%edx
f0106834:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106838:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f010683b:	89 54 24 10          	mov    %edx,0x10(%esp)
f010683f:	8b 55 ac             	mov    -0x54(%ebp),%edx
f0106842:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0106846:	8b 55 a8             	mov    -0x58(%ebp),%edx
f0106849:	89 54 24 08          	mov    %edx,0x8(%esp)
f010684d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106851:	c7 04 24 5c 85 10 f0 	movl   $0xf010855c,(%esp)
f0106858:	e8 99 d4 ff ff       	call   f0103cf6 <cprintf>
f010685d:	eb 12                	jmp    f0106871 <spin_unlock+0xcc>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f010685f:	8b 03                	mov    (%ebx),%eax
f0106861:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106865:	c7 04 24 73 85 10 f0 	movl   $0xf0108573,(%esp)
f010686c:	e8 85 d4 ff ff       	call   f0103cf6 <cprintf>
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106871:	39 fb                	cmp    %edi,%ebx
f0106873:	74 09                	je     f010687e <spin_unlock+0xd9>
f0106875:	83 c3 04             	add    $0x4,%ebx
f0106878:	8b 03                	mov    (%ebx),%eax
f010687a:	85 c0                	test   %eax,%eax
f010687c:	75 98                	jne    f0106816 <spin_unlock+0x71>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f010687e:	c7 44 24 08 7b 85 10 	movl   $0xf010857b,0x8(%esp)
f0106885:	f0 
f0106886:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
f010688d:	00 
f010688e:	c7 04 24 4c 85 10 f0 	movl   $0xf010854c,(%esp)
f0106895:	e8 a6 97 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f010689a:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
	lk->cpu = 0;
f01068a1:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01068a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01068ad:	f0 87 03             	lock xchg %eax,(%ebx)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f01068b0:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01068b3:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01068b6:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01068b9:	89 ec                	mov    %ebp,%esp
f01068bb:	5d                   	pop    %ebp
f01068bc:	c3                   	ret    
f01068bd:	66 90                	xchg   %ax,%ax
f01068bf:	90                   	nop

f01068c0 <__udivdi3>:
f01068c0:	83 ec 1c             	sub    $0x1c,%esp
f01068c3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f01068c7:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01068cb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01068cf:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01068d3:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01068d7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f01068db:	85 c0                	test   %eax,%eax
f01068dd:	89 74 24 10          	mov    %esi,0x10(%esp)
f01068e1:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01068e5:	89 ea                	mov    %ebp,%edx
f01068e7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01068eb:	75 33                	jne    f0106920 <__udivdi3+0x60>
f01068ed:	39 e9                	cmp    %ebp,%ecx
f01068ef:	77 6f                	ja     f0106960 <__udivdi3+0xa0>
f01068f1:	85 c9                	test   %ecx,%ecx
f01068f3:	89 ce                	mov    %ecx,%esi
f01068f5:	75 0b                	jne    f0106902 <__udivdi3+0x42>
f01068f7:	b8 01 00 00 00       	mov    $0x1,%eax
f01068fc:	31 d2                	xor    %edx,%edx
f01068fe:	f7 f1                	div    %ecx
f0106900:	89 c6                	mov    %eax,%esi
f0106902:	31 d2                	xor    %edx,%edx
f0106904:	89 e8                	mov    %ebp,%eax
f0106906:	f7 f6                	div    %esi
f0106908:	89 c5                	mov    %eax,%ebp
f010690a:	89 f8                	mov    %edi,%eax
f010690c:	f7 f6                	div    %esi
f010690e:	89 ea                	mov    %ebp,%edx
f0106910:	8b 74 24 10          	mov    0x10(%esp),%esi
f0106914:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0106918:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010691c:	83 c4 1c             	add    $0x1c,%esp
f010691f:	c3                   	ret    
f0106920:	39 e8                	cmp    %ebp,%eax
f0106922:	77 24                	ja     f0106948 <__udivdi3+0x88>
f0106924:	0f bd c8             	bsr    %eax,%ecx
f0106927:	83 f1 1f             	xor    $0x1f,%ecx
f010692a:	89 0c 24             	mov    %ecx,(%esp)
f010692d:	75 49                	jne    f0106978 <__udivdi3+0xb8>
f010692f:	8b 74 24 08          	mov    0x8(%esp),%esi
f0106933:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0106937:	0f 86 ab 00 00 00    	jbe    f01069e8 <__udivdi3+0x128>
f010693d:	39 e8                	cmp    %ebp,%eax
f010693f:	0f 82 a3 00 00 00    	jb     f01069e8 <__udivdi3+0x128>
f0106945:	8d 76 00             	lea    0x0(%esi),%esi
f0106948:	31 d2                	xor    %edx,%edx
f010694a:	31 c0                	xor    %eax,%eax
f010694c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0106950:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0106954:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0106958:	83 c4 1c             	add    $0x1c,%esp
f010695b:	c3                   	ret    
f010695c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106960:	89 f8                	mov    %edi,%eax
f0106962:	f7 f1                	div    %ecx
f0106964:	31 d2                	xor    %edx,%edx
f0106966:	8b 74 24 10          	mov    0x10(%esp),%esi
f010696a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010696e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0106972:	83 c4 1c             	add    $0x1c,%esp
f0106975:	c3                   	ret    
f0106976:	66 90                	xchg   %ax,%ax
f0106978:	0f b6 0c 24          	movzbl (%esp),%ecx
f010697c:	89 c6                	mov    %eax,%esi
f010697e:	b8 20 00 00 00       	mov    $0x20,%eax
f0106983:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0106987:	2b 04 24             	sub    (%esp),%eax
f010698a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010698e:	d3 e6                	shl    %cl,%esi
f0106990:	89 c1                	mov    %eax,%ecx
f0106992:	d3 ed                	shr    %cl,%ebp
f0106994:	0f b6 0c 24          	movzbl (%esp),%ecx
f0106998:	09 f5                	or     %esi,%ebp
f010699a:	8b 74 24 04          	mov    0x4(%esp),%esi
f010699e:	d3 e6                	shl    %cl,%esi
f01069a0:	89 c1                	mov    %eax,%ecx
f01069a2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01069a6:	89 d6                	mov    %edx,%esi
f01069a8:	d3 ee                	shr    %cl,%esi
f01069aa:	0f b6 0c 24          	movzbl (%esp),%ecx
f01069ae:	d3 e2                	shl    %cl,%edx
f01069b0:	89 c1                	mov    %eax,%ecx
f01069b2:	d3 ef                	shr    %cl,%edi
f01069b4:	09 d7                	or     %edx,%edi
f01069b6:	89 f2                	mov    %esi,%edx
f01069b8:	89 f8                	mov    %edi,%eax
f01069ba:	f7 f5                	div    %ebp
f01069bc:	89 d6                	mov    %edx,%esi
f01069be:	89 c7                	mov    %eax,%edi
f01069c0:	f7 64 24 04          	mull   0x4(%esp)
f01069c4:	39 d6                	cmp    %edx,%esi
f01069c6:	72 30                	jb     f01069f8 <__udivdi3+0x138>
f01069c8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01069cc:	0f b6 0c 24          	movzbl (%esp),%ecx
f01069d0:	d3 e5                	shl    %cl,%ebp
f01069d2:	39 c5                	cmp    %eax,%ebp
f01069d4:	73 04                	jae    f01069da <__udivdi3+0x11a>
f01069d6:	39 d6                	cmp    %edx,%esi
f01069d8:	74 1e                	je     f01069f8 <__udivdi3+0x138>
f01069da:	89 f8                	mov    %edi,%eax
f01069dc:	31 d2                	xor    %edx,%edx
f01069de:	e9 69 ff ff ff       	jmp    f010694c <__udivdi3+0x8c>
f01069e3:	90                   	nop
f01069e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01069e8:	31 d2                	xor    %edx,%edx
f01069ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01069ef:	e9 58 ff ff ff       	jmp    f010694c <__udivdi3+0x8c>
f01069f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01069f8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01069fb:	31 d2                	xor    %edx,%edx
f01069fd:	8b 74 24 10          	mov    0x10(%esp),%esi
f0106a01:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0106a05:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0106a09:	83 c4 1c             	add    $0x1c,%esp
f0106a0c:	c3                   	ret    
f0106a0d:	66 90                	xchg   %ax,%ax
f0106a0f:	90                   	nop

f0106a10 <__umoddi3>:
f0106a10:	83 ec 2c             	sub    $0x2c,%esp
f0106a13:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0106a17:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0106a1b:	89 74 24 20          	mov    %esi,0x20(%esp)
f0106a1f:	8b 74 24 38          	mov    0x38(%esp),%esi
f0106a23:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0106a27:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0106a2b:	85 c0                	test   %eax,%eax
f0106a2d:	89 c2                	mov    %eax,%edx
f0106a2f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0106a33:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0106a37:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106a3b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0106a3f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0106a43:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0106a47:	75 1f                	jne    f0106a68 <__umoddi3+0x58>
f0106a49:	39 fe                	cmp    %edi,%esi
f0106a4b:	76 63                	jbe    f0106ab0 <__umoddi3+0xa0>
f0106a4d:	89 c8                	mov    %ecx,%eax
f0106a4f:	89 fa                	mov    %edi,%edx
f0106a51:	f7 f6                	div    %esi
f0106a53:	89 d0                	mov    %edx,%eax
f0106a55:	31 d2                	xor    %edx,%edx
f0106a57:	8b 74 24 20          	mov    0x20(%esp),%esi
f0106a5b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0106a5f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0106a63:	83 c4 2c             	add    $0x2c,%esp
f0106a66:	c3                   	ret    
f0106a67:	90                   	nop
f0106a68:	39 f8                	cmp    %edi,%eax
f0106a6a:	77 64                	ja     f0106ad0 <__umoddi3+0xc0>
f0106a6c:	0f bd e8             	bsr    %eax,%ebp
f0106a6f:	83 f5 1f             	xor    $0x1f,%ebp
f0106a72:	75 74                	jne    f0106ae8 <__umoddi3+0xd8>
f0106a74:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0106a78:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f0106a7c:	0f 87 0e 01 00 00    	ja     f0106b90 <__umoddi3+0x180>
f0106a82:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0106a86:	29 f1                	sub    %esi,%ecx
f0106a88:	19 c7                	sbb    %eax,%edi
f0106a8a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0106a8e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0106a92:	8b 44 24 14          	mov    0x14(%esp),%eax
f0106a96:	8b 54 24 18          	mov    0x18(%esp),%edx
f0106a9a:	8b 74 24 20          	mov    0x20(%esp),%esi
f0106a9e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0106aa2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0106aa6:	83 c4 2c             	add    $0x2c,%esp
f0106aa9:	c3                   	ret    
f0106aaa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106ab0:	85 f6                	test   %esi,%esi
f0106ab2:	89 f5                	mov    %esi,%ebp
f0106ab4:	75 0b                	jne    f0106ac1 <__umoddi3+0xb1>
f0106ab6:	b8 01 00 00 00       	mov    $0x1,%eax
f0106abb:	31 d2                	xor    %edx,%edx
f0106abd:	f7 f6                	div    %esi
f0106abf:	89 c5                	mov    %eax,%ebp
f0106ac1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106ac5:	31 d2                	xor    %edx,%edx
f0106ac7:	f7 f5                	div    %ebp
f0106ac9:	89 c8                	mov    %ecx,%eax
f0106acb:	f7 f5                	div    %ebp
f0106acd:	eb 84                	jmp    f0106a53 <__umoddi3+0x43>
f0106acf:	90                   	nop
f0106ad0:	89 c8                	mov    %ecx,%eax
f0106ad2:	89 fa                	mov    %edi,%edx
f0106ad4:	8b 74 24 20          	mov    0x20(%esp),%esi
f0106ad8:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0106adc:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0106ae0:	83 c4 2c             	add    $0x2c,%esp
f0106ae3:	c3                   	ret    
f0106ae4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106ae8:	8b 44 24 10          	mov    0x10(%esp),%eax
f0106aec:	be 20 00 00 00       	mov    $0x20,%esi
f0106af1:	89 e9                	mov    %ebp,%ecx
f0106af3:	29 ee                	sub    %ebp,%esi
f0106af5:	d3 e2                	shl    %cl,%edx
f0106af7:	89 f1                	mov    %esi,%ecx
f0106af9:	d3 e8                	shr    %cl,%eax
f0106afb:	89 e9                	mov    %ebp,%ecx
f0106afd:	09 d0                	or     %edx,%eax
f0106aff:	89 fa                	mov    %edi,%edx
f0106b01:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106b05:	8b 44 24 10          	mov    0x10(%esp),%eax
f0106b09:	d3 e0                	shl    %cl,%eax
f0106b0b:	89 f1                	mov    %esi,%ecx
f0106b0d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0106b11:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0106b15:	d3 ea                	shr    %cl,%edx
f0106b17:	89 e9                	mov    %ebp,%ecx
f0106b19:	d3 e7                	shl    %cl,%edi
f0106b1b:	89 f1                	mov    %esi,%ecx
f0106b1d:	d3 e8                	shr    %cl,%eax
f0106b1f:	89 e9                	mov    %ebp,%ecx
f0106b21:	09 f8                	or     %edi,%eax
f0106b23:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0106b27:	f7 74 24 0c          	divl   0xc(%esp)
f0106b2b:	d3 e7                	shl    %cl,%edi
f0106b2d:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0106b31:	89 d7                	mov    %edx,%edi
f0106b33:	f7 64 24 10          	mull   0x10(%esp)
f0106b37:	39 d7                	cmp    %edx,%edi
f0106b39:	89 c1                	mov    %eax,%ecx
f0106b3b:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106b3f:	72 3b                	jb     f0106b7c <__umoddi3+0x16c>
f0106b41:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0106b45:	72 31                	jb     f0106b78 <__umoddi3+0x168>
f0106b47:	8b 44 24 18          	mov    0x18(%esp),%eax
f0106b4b:	29 c8                	sub    %ecx,%eax
f0106b4d:	19 d7                	sbb    %edx,%edi
f0106b4f:	89 e9                	mov    %ebp,%ecx
f0106b51:	89 fa                	mov    %edi,%edx
f0106b53:	d3 e8                	shr    %cl,%eax
f0106b55:	89 f1                	mov    %esi,%ecx
f0106b57:	d3 e2                	shl    %cl,%edx
f0106b59:	89 e9                	mov    %ebp,%ecx
f0106b5b:	09 d0                	or     %edx,%eax
f0106b5d:	89 fa                	mov    %edi,%edx
f0106b5f:	d3 ea                	shr    %cl,%edx
f0106b61:	8b 74 24 20          	mov    0x20(%esp),%esi
f0106b65:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0106b69:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0106b6d:	83 c4 2c             	add    $0x2c,%esp
f0106b70:	c3                   	ret    
f0106b71:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106b78:	39 d7                	cmp    %edx,%edi
f0106b7a:	75 cb                	jne    f0106b47 <__umoddi3+0x137>
f0106b7c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0106b80:	89 c1                	mov    %eax,%ecx
f0106b82:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0106b86:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0106b8a:	eb bb                	jmp    f0106b47 <__umoddi3+0x137>
f0106b8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106b90:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0106b94:	0f 82 e8 fe ff ff    	jb     f0106a82 <__umoddi3+0x72>
f0106b9a:	e9 f3 fe ff ff       	jmp    f0106a92 <__umoddi3+0x82>

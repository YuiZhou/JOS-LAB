
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
f010004b:	83 3d 80 7e 22 f0 00 	cmpl   $0x0,0xf0227e80
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 80 7e 22 f0    	mov    %esi,0xf0227e80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 68 61 00 00       	call   f01061cc <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 40 69 10 f0 	movl   $0xf0106940,(%esp)
f010007d:	e8 3c 3d 00 00       	call   f0103dbe <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 fd 3c 00 00       	call   f0103d8b <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 f8 75 10 f0 	movl   $0xf01075f8,(%esp)
f0100095:	e8 24 3d 00 00       	call   f0103dbe <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 6c 0a 00 00       	call   f0100b12 <monitor>
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
f01000ae:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01000b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01000b8:	77 20                	ja     f01000da <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01000ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01000be:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f01000c5:	f0 
f01000c6:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
f01000cd:	00 
f01000ce:	c7 04 24 ab 69 10 f0 	movl   $0xf01069ab,(%esp)
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
f01000e2:	e8 e5 60 00 00       	call   f01061cc <cpunum>
f01000e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000eb:	c7 04 24 b7 69 10 f0 	movl   $0xf01069b7,(%esp)
f01000f2:	e8 c7 3c 00 00       	call   f0103dbe <cprintf>

	lapic_init();
f01000f7:	e8 eb 60 00 00       	call   f01061e7 <lapic_init>
	env_init_percpu();
f01000fc:	e8 6d 34 00 00       	call   f010356e <env_init_percpu>
	trap_init_percpu();
f0100101:	e8 da 3c 00 00       	call   f0103de0 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100106:	e8 c1 60 00 00       	call   f01061cc <cpunum>
f010010b:	6b d0 74             	imul   $0x74,%eax,%edx
f010010e:	81 c2 20 80 22 f0    	add    $0xf0228020,%edx
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
f0100124:	e8 3c 63 00 00       	call   f0106465 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100129:	e8 6e 47 00 00       	call   f010489c <sched_yield>

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
f0100135:	b8 04 90 26 f0       	mov    $0xf0269004,%eax
f010013a:	2d 62 68 22 f0       	sub    $0xf0226862,%eax
f010013f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100143:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010014a:	00 
f010014b:	c7 04 24 62 68 22 f0 	movl   $0xf0226862,(%esp)
f0100152:	e8 ce 59 00 00       	call   f0105b25 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100157:	e8 4b 06 00 00       	call   f01007a7 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010015c:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100163:	00 
f0100164:	c7 04 24 cd 69 10 f0 	movl   $0xf01069cd,(%esp)
f010016b:	e8 4e 3c 00 00       	call   f0103dbe <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100170:	e8 7c 14 00 00       	call   f01015f1 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100175:	e8 1e 34 00 00       	call   f0103598 <env_init>
	trap_init();
f010017a:	e8 52 3d 00 00       	call   f0103ed1 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f010017f:	90                   	nop
f0100180:	e8 5f 5d 00 00       	call   f0105ee4 <mp_init>
	lapic_init();
f0100185:	e8 5d 60 00 00       	call   f01061e7 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f010018a:	e8 5c 3b 00 00       	call   f0103ceb <pic_init>
f010018f:	c7 04 24 a0 13 12 f0 	movl   $0xf01213a0,(%esp)
f0100196:	e8 ca 62 00 00       	call   f0106465 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010019b:	83 3d 88 7e 22 f0 07 	cmpl   $0x7,0xf0227e88
f01001a2:	77 24                	ja     f01001c8 <i386_init+0x9a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01001a4:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f01001ab:	00 
f01001ac:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f01001b3:	f0 
f01001b4:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
f01001bb:	00 
f01001bc:	c7 04 24 ab 69 10 f0 	movl   $0xf01069ab,(%esp)
f01001c3:	e8 78 fe ff ff       	call   f0100040 <_panic>
	void *code;
	struct Cpu *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f01001c8:	b8 fa 5d 10 f0       	mov    $0xf0105dfa,%eax
f01001cd:	2d 80 5d 10 f0       	sub    $0xf0105d80,%eax
f01001d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01001d6:	c7 44 24 04 80 5d 10 	movl   $0xf0105d80,0x4(%esp)
f01001dd:	f0 
f01001de:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f01001e5:	e8 99 59 00 00       	call   f0105b83 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01001ea:	6b 05 c4 83 22 f0 74 	imul   $0x74,0xf02283c4,%eax
f01001f1:	05 20 80 22 f0       	add    $0xf0228020,%eax
f01001f6:	3d 20 80 22 f0       	cmp    $0xf0228020,%eax
f01001fb:	0f 86 89 01 00 00    	jbe    f010038a <i386_init+0x25c>
f0100201:	bb 20 80 22 f0       	mov    $0xf0228020,%ebx
		if (c == cpus + cpunum())  // We've started already.
f0100206:	e8 c1 5f 00 00       	call   f01061cc <cpunum>
f010020b:	6b c0 74             	imul   $0x74,%eax,%eax
f010020e:	05 20 80 22 f0       	add    $0xf0228020,%eax
f0100213:	39 c3                	cmp    %eax,%ebx
f0100215:	74 39                	je     f0100250 <i386_init+0x122>

static void boot_aps(void);


void
i386_init(void)
f0100217:	89 d8                	mov    %ebx,%eax
f0100219:	2d 20 80 22 f0       	sub    $0xf0228020,%eax
	for (c = cpus; c < cpus + ncpu; c++) {
		if (c == cpus + cpunum())  // We've started already.
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f010021e:	c1 f8 02             	sar    $0x2,%eax
f0100221:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100227:	c1 e0 0f             	shl    $0xf,%eax
f010022a:	8d 80 00 10 23 f0    	lea    -0xfdcf000(%eax),%eax
f0100230:	a3 84 7e 22 f0       	mov    %eax,0xf0227e84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100235:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f010023c:	00 
f010023d:	0f b6 03             	movzbl (%ebx),%eax
f0100240:	89 04 24             	mov    %eax,(%esp)
f0100243:	e8 d7 60 00 00       	call   f010631f <lapic_startap>
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
f0100253:	6b 05 c4 83 22 f0 74 	imul   $0x74,0xf02283c4,%eax
f010025a:	05 20 80 22 f0       	add    $0xf0228020,%eax
f010025f:	39 c3                	cmp    %eax,%ebx
f0100261:	72 a3                	jb     f0100206 <i386_init+0xd8>
f0100263:	e9 22 01 00 00       	jmp    f010038a <i386_init+0x25c>
	boot_aps();

	// Should always have idle processes at first.
	int i;
	for (i = 0; i < NCPU; i++)
		ENV_CREATE(user_idle, ENV_TYPE_IDLE);
f0100268:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010026f:	00 
f0100270:	c7 44 24 04 5e 89 00 	movl   $0x895e,0x4(%esp)
f0100277:	00 
f0100278:	c7 04 24 2c 0e 19 f0 	movl   $0xf0190e2c,(%esp)
f010027f:	e8 2c 35 00 00       	call   f01037b0 <env_create>
	// Starting non-boot CPUs
	boot_aps();

	// Should always have idle processes at first.
	int i;
	for (i = 0; i < NCPU; i++)
f0100284:	83 eb 01             	sub    $0x1,%ebx
f0100287:	75 df                	jne    f0100268 <i386_init+0x13a>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_dumbfork, ENV_TYPE_USER);
f0100289:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100290:	00 
f0100291:	c7 44 24 04 a7 89 00 	movl   $0x89a7,0x4(%esp)
f0100298:	00 
f0100299:	c7 04 24 e9 20 1a f0 	movl   $0xf01a20e9,(%esp)
f01002a0:	e8 0b 35 00 00       	call   f01037b0 <env_create>
	ENV_CREATE(user_faultread, ENV_TYPE_USER);
f01002a5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01002ac:	00 
f01002ad:	c7 44 24 04 63 89 00 	movl   $0x8963,0x4(%esp)
f01002b4:	00 
f01002b5:	c7 04 24 92 e8 16 f0 	movl   $0xf016e892,(%esp)
f01002bc:	e8 ef 34 00 00       	call   f01037b0 <env_create>
	ENV_CREATE(user_faultdie, ENV_TYPE_USER);
f01002c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01002c8:	00 
f01002c9:	c7 44 24 04 f9 89 00 	movl   $0x89f9,0x4(%esp)
f01002d0:	00 
f01002d1:	c7 04 24 e6 34 1b f0 	movl   $0xf01b34e6,(%esp)
f01002d8:	e8 d3 34 00 00       	call   f01037b0 <env_create>
	ENV_CREATE(user_faultalloc, ENV_TYPE_USER);
f01002dd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01002e4:	00 
f01002e5:	c7 44 24 04 fb 89 00 	movl   $0x89fb,0x4(%esp)
f01002ec:	00 
f01002ed:	c7 04 24 38 49 1c f0 	movl   $0xf01c4938,(%esp)
f01002f4:	e8 b7 34 00 00       	call   f01037b0 <env_create>
	ENV_CREATE(user_faultallocbad, ENV_TYPE_USER);
f01002f9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100300:	00 
f0100301:	c7 44 24 04 fe 89 00 	movl   $0x89fe,0x4(%esp)
f0100308:	00 
f0100309:	c7 04 24 33 d3 1c f0 	movl   $0xf01cd333,(%esp)
f0100310:	e8 9b 34 00 00       	call   f01037b0 <env_create>
	ENV_CREATE(user_primes, ENV_TYPE_USER);
f0100315:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010031c:	00 
f010031d:	c7 44 24 04 b8 9a 00 	movl   $0x9ab8,0x4(%esp)
f0100324:	00 
f0100325:	c7 04 24 aa cd 21 f0 	movl   $0xf021cdaa,(%esp)
f010032c:	e8 7f 34 00 00       	call   f01037b0 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f0100331:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100338:	00 
f0100339:	c7 44 24 04 5f 89 00 	movl   $0x895f,0x4(%esp)
f0100340:	00 
f0100341:	c7 04 24 8a 97 19 f0 	movl   $0xf019978a,(%esp)
f0100348:	e8 63 34 00 00       	call   f01037b0 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f010034d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100354:	00 
f0100355:	c7 44 24 04 5f 89 00 	movl   $0x895f,0x4(%esp)
f010035c:	00 
f010035d:	c7 04 24 8a 97 19 f0 	movl   $0xf019978a,(%esp)
f0100364:	e8 47 34 00 00       	call   f01037b0 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f0100369:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100370:	00 
f0100371:	c7 44 24 04 5f 89 00 	movl   $0x895f,0x4(%esp)
f0100378:	00 
f0100379:	c7 04 24 8a 97 19 f0 	movl   $0xf019978a,(%esp)
f0100380:	e8 2b 34 00 00       	call   f01037b0 <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f0100385:	e8 12 45 00 00       	call   f010489c <sched_yield>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010038a:	bb 08 00 00 00       	mov    $0x8,%ebx
f010038f:	e9 d4 fe ff ff       	jmp    f0100268 <i386_init+0x13a>

f0100394 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100394:	55                   	push   %ebp
f0100395:	89 e5                	mov    %esp,%ebp
f0100397:	53                   	push   %ebx
f0100398:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010039b:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010039e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01003a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01003a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01003a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01003ac:	c7 04 24 e8 69 10 f0 	movl   $0xf01069e8,(%esp)
f01003b3:	e8 06 3a 00 00       	call   f0103dbe <cprintf>
	vcprintf(fmt, ap);
f01003b8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01003bc:	8b 45 10             	mov    0x10(%ebp),%eax
f01003bf:	89 04 24             	mov    %eax,(%esp)
f01003c2:	e8 c4 39 00 00       	call   f0103d8b <vcprintf>
	cprintf("\n");
f01003c7:	c7 04 24 f8 75 10 f0 	movl   $0xf01075f8,(%esp)
f01003ce:	e8 eb 39 00 00       	call   f0103dbe <cprintf>
	va_end(ap);
}
f01003d3:	83 c4 14             	add    $0x14,%esp
f01003d6:	5b                   	pop    %ebx
f01003d7:	5d                   	pop    %ebp
f01003d8:	c3                   	ret    
f01003d9:	66 90                	xchg   %ax,%ax
f01003db:	66 90                	xchg   %ax,%ax
f01003dd:	66 90                	xchg   %ax,%ax
f01003df:	90                   	nop

f01003e0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01003e0:	55                   	push   %ebp
f01003e1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e3:	ba 84 00 00 00       	mov    $0x84,%edx
f01003e8:	ec                   	in     (%dx),%al
f01003e9:	ec                   	in     (%dx),%al
f01003ea:	ec                   	in     (%dx),%al
f01003eb:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01003ec:	5d                   	pop    %ebp
f01003ed:	c3                   	ret    

f01003ee <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01003ee:	55                   	push   %ebp
f01003ef:	89 e5                	mov    %esp,%ebp
f01003f1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01003f6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01003f7:	a8 01                	test   $0x1,%al
f01003f9:	74 08                	je     f0100403 <serial_proc_data+0x15>
f01003fb:	b2 f8                	mov    $0xf8,%dl
f01003fd:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01003fe:	0f b6 c0             	movzbl %al,%eax
f0100401:	eb 05                	jmp    f0100408 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100403:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100408:	5d                   	pop    %ebp
f0100409:	c3                   	ret    

f010040a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010040a:	55                   	push   %ebp
f010040b:	89 e5                	mov    %esp,%ebp
f010040d:	53                   	push   %ebx
f010040e:	83 ec 04             	sub    $0x4,%esp
f0100411:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100413:	eb 26                	jmp    f010043b <cons_intr+0x31>
		if (c == 0)
f0100415:	85 d2                	test   %edx,%edx
f0100417:	74 22                	je     f010043b <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f0100419:	a1 24 72 22 f0       	mov    0xf0227224,%eax
f010041e:	88 90 20 70 22 f0    	mov    %dl,-0xfdd8fe0(%eax)
f0100424:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f0100427:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f010042d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100432:	0f 44 d0             	cmove  %eax,%edx
f0100435:	89 15 24 72 22 f0    	mov    %edx,0xf0227224
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010043b:	ff d3                	call   *%ebx
f010043d:	89 c2                	mov    %eax,%edx
f010043f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100442:	75 d1                	jne    f0100415 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100444:	83 c4 04             	add    $0x4,%esp
f0100447:	5b                   	pop    %ebx
f0100448:	5d                   	pop    %ebp
f0100449:	c3                   	ret    

f010044a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010044a:	55                   	push   %ebp
f010044b:	89 e5                	mov    %esp,%ebp
f010044d:	57                   	push   %edi
f010044e:	56                   	push   %esi
f010044f:	53                   	push   %ebx
f0100450:	83 ec 2c             	sub    $0x2c,%esp
f0100453:	89 c7                	mov    %eax,%edi
f0100455:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010045a:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010045b:	a8 20                	test   $0x20,%al
f010045d:	75 1b                	jne    f010047a <cons_putc+0x30>
f010045f:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100464:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100469:	e8 72 ff ff ff       	call   f01003e0 <delay>
f010046e:	89 f2                	mov    %esi,%edx
f0100470:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f0100471:	a8 20                	test   $0x20,%al
f0100473:	75 05                	jne    f010047a <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100475:	83 eb 01             	sub    $0x1,%ebx
f0100478:	75 ef                	jne    f0100469 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f010047a:	89 f8                	mov    %edi,%eax
f010047c:	25 ff 00 00 00       	and    $0xff,%eax
f0100481:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100484:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100489:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010048a:	b2 79                	mov    $0x79,%dl
f010048c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010048d:	84 c0                	test   %al,%al
f010048f:	78 1b                	js     f01004ac <cons_putc+0x62>
f0100491:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100496:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f010049b:	e8 40 ff ff ff       	call   f01003e0 <delay>
f01004a0:	89 f2                	mov    %esi,%edx
f01004a2:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01004a3:	84 c0                	test   %al,%al
f01004a5:	78 05                	js     f01004ac <cons_putc+0x62>
f01004a7:	83 eb 01             	sub    $0x1,%ebx
f01004aa:	75 ef                	jne    f010049b <cons_putc+0x51>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004ac:	ba 78 03 00 00       	mov    $0x378,%edx
f01004b1:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f01004b5:	ee                   	out    %al,(%dx)
f01004b6:	b2 7a                	mov    $0x7a,%dl
f01004b8:	b8 0d 00 00 00       	mov    $0xd,%eax
f01004bd:	ee                   	out    %al,(%dx)
f01004be:	b8 08 00 00 00       	mov    $0x8,%eax
f01004c3:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004c4:	89 fa                	mov    %edi,%edx
f01004c6:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01004cc:	89 f8                	mov    %edi,%eax
f01004ce:	80 cc 07             	or     $0x7,%ah
f01004d1:	85 d2                	test   %edx,%edx
f01004d3:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01004d6:	89 f8                	mov    %edi,%eax
f01004d8:	25 ff 00 00 00       	and    $0xff,%eax
f01004dd:	83 f8 09             	cmp    $0x9,%eax
f01004e0:	74 77                	je     f0100559 <cons_putc+0x10f>
f01004e2:	83 f8 09             	cmp    $0x9,%eax
f01004e5:	7f 0b                	jg     f01004f2 <cons_putc+0xa8>
f01004e7:	83 f8 08             	cmp    $0x8,%eax
f01004ea:	0f 85 9d 00 00 00    	jne    f010058d <cons_putc+0x143>
f01004f0:	eb 10                	jmp    f0100502 <cons_putc+0xb8>
f01004f2:	83 f8 0a             	cmp    $0xa,%eax
f01004f5:	74 3c                	je     f0100533 <cons_putc+0xe9>
f01004f7:	83 f8 0d             	cmp    $0xd,%eax
f01004fa:	0f 85 8d 00 00 00    	jne    f010058d <cons_putc+0x143>
f0100500:	eb 39                	jmp    f010053b <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f0100502:	0f b7 05 34 72 22 f0 	movzwl 0xf0227234,%eax
f0100509:	66 85 c0             	test   %ax,%ax
f010050c:	0f 84 e5 00 00 00    	je     f01005f7 <cons_putc+0x1ad>
			crt_pos--;
f0100512:	83 e8 01             	sub    $0x1,%eax
f0100515:	66 a3 34 72 22 f0    	mov    %ax,0xf0227234
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010051b:	0f b7 c0             	movzwl %ax,%eax
f010051e:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f0100524:	83 cf 20             	or     $0x20,%edi
f0100527:	8b 15 30 72 22 f0    	mov    0xf0227230,%edx
f010052d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100531:	eb 77                	jmp    f01005aa <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100533:	66 83 05 34 72 22 f0 	addw   $0x50,0xf0227234
f010053a:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010053b:	0f b7 05 34 72 22 f0 	movzwl 0xf0227234,%eax
f0100542:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100548:	c1 e8 16             	shr    $0x16,%eax
f010054b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010054e:	c1 e0 04             	shl    $0x4,%eax
f0100551:	66 a3 34 72 22 f0    	mov    %ax,0xf0227234
f0100557:	eb 51                	jmp    f01005aa <cons_putc+0x160>
		break;
	case '\t':
		cons_putc(' ');
f0100559:	b8 20 00 00 00       	mov    $0x20,%eax
f010055e:	e8 e7 fe ff ff       	call   f010044a <cons_putc>
		cons_putc(' ');
f0100563:	b8 20 00 00 00       	mov    $0x20,%eax
f0100568:	e8 dd fe ff ff       	call   f010044a <cons_putc>
		cons_putc(' ');
f010056d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100572:	e8 d3 fe ff ff       	call   f010044a <cons_putc>
		cons_putc(' ');
f0100577:	b8 20 00 00 00       	mov    $0x20,%eax
f010057c:	e8 c9 fe ff ff       	call   f010044a <cons_putc>
		cons_putc(' ');
f0100581:	b8 20 00 00 00       	mov    $0x20,%eax
f0100586:	e8 bf fe ff ff       	call   f010044a <cons_putc>
f010058b:	eb 1d                	jmp    f01005aa <cons_putc+0x160>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010058d:	0f b7 05 34 72 22 f0 	movzwl 0xf0227234,%eax
f0100594:	0f b7 c8             	movzwl %ax,%ecx
f0100597:	8b 15 30 72 22 f0    	mov    0xf0227230,%edx
f010059d:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f01005a1:	83 c0 01             	add    $0x1,%eax
f01005a4:	66 a3 34 72 22 f0    	mov    %ax,0xf0227234
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005aa:	66 81 3d 34 72 22 f0 	cmpw   $0x7cf,0xf0227234
f01005b1:	cf 07 
f01005b3:	76 42                	jbe    f01005f7 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005b5:	a1 30 72 22 f0       	mov    0xf0227230,%eax
f01005ba:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005c1:	00 
f01005c2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005c8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005cc:	89 04 24             	mov    %eax,(%esp)
f01005cf:	e8 af 55 00 00       	call   f0105b83 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005d4:	8b 15 30 72 22 f0    	mov    0xf0227230,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005da:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005df:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005e5:	83 c0 01             	add    $0x1,%eax
f01005e8:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005ed:	75 f0                	jne    f01005df <cons_putc+0x195>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005ef:	66 83 2d 34 72 22 f0 	subw   $0x50,0xf0227234
f01005f6:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005f7:	8b 0d 2c 72 22 f0    	mov    0xf022722c,%ecx
f01005fd:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100602:	89 ca                	mov    %ecx,%edx
f0100604:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100605:	0f b7 1d 34 72 22 f0 	movzwl 0xf0227234,%ebx
f010060c:	8d 71 01             	lea    0x1(%ecx),%esi
f010060f:	89 d8                	mov    %ebx,%eax
f0100611:	66 c1 e8 08          	shr    $0x8,%ax
f0100615:	89 f2                	mov    %esi,%edx
f0100617:	ee                   	out    %al,(%dx)
f0100618:	b8 0f 00 00 00       	mov    $0xf,%eax
f010061d:	89 ca                	mov    %ecx,%edx
f010061f:	ee                   	out    %al,(%dx)
f0100620:	89 d8                	mov    %ebx,%eax
f0100622:	89 f2                	mov    %esi,%edx
f0100624:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100625:	83 c4 2c             	add    $0x2c,%esp
f0100628:	5b                   	pop    %ebx
f0100629:	5e                   	pop    %esi
f010062a:	5f                   	pop    %edi
f010062b:	5d                   	pop    %ebp
f010062c:	c3                   	ret    

f010062d <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010062d:	55                   	push   %ebp
f010062e:	89 e5                	mov    %esp,%ebp
f0100630:	53                   	push   %ebx
f0100631:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100634:	ba 64 00 00 00       	mov    $0x64,%edx
f0100639:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010063a:	a8 01                	test   $0x1,%al
f010063c:	0f 84 e5 00 00 00    	je     f0100727 <kbd_proc_data+0xfa>
f0100642:	b2 60                	mov    $0x60,%dl
f0100644:	ec                   	in     (%dx),%al
f0100645:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100647:	3c e0                	cmp    $0xe0,%al
f0100649:	75 11                	jne    f010065c <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f010064b:	83 0d 28 72 22 f0 40 	orl    $0x40,0xf0227228
		return 0;
f0100652:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100657:	e9 d0 00 00 00       	jmp    f010072c <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f010065c:	84 c0                	test   %al,%al
f010065e:	79 37                	jns    f0100697 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100660:	8b 0d 28 72 22 f0    	mov    0xf0227228,%ecx
f0100666:	89 cb                	mov    %ecx,%ebx
f0100668:	83 e3 40             	and    $0x40,%ebx
f010066b:	83 e0 7f             	and    $0x7f,%eax
f010066e:	85 db                	test   %ebx,%ebx
f0100670:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100673:	0f b6 d2             	movzbl %dl,%edx
f0100676:	0f b6 82 40 6a 10 f0 	movzbl -0xfef95c0(%edx),%eax
f010067d:	83 c8 40             	or     $0x40,%eax
f0100680:	0f b6 c0             	movzbl %al,%eax
f0100683:	f7 d0                	not    %eax
f0100685:	21 c1                	and    %eax,%ecx
f0100687:	89 0d 28 72 22 f0    	mov    %ecx,0xf0227228
		return 0;
f010068d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100692:	e9 95 00 00 00       	jmp    f010072c <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f0100697:	8b 0d 28 72 22 f0    	mov    0xf0227228,%ecx
f010069d:	f6 c1 40             	test   $0x40,%cl
f01006a0:	74 0e                	je     f01006b0 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01006a2:	89 c2                	mov    %eax,%edx
f01006a4:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01006a7:	83 e1 bf             	and    $0xffffffbf,%ecx
f01006aa:	89 0d 28 72 22 f0    	mov    %ecx,0xf0227228
	}

	shift |= shiftcode[data];
f01006b0:	0f b6 d2             	movzbl %dl,%edx
f01006b3:	0f b6 82 40 6a 10 f0 	movzbl -0xfef95c0(%edx),%eax
f01006ba:	0b 05 28 72 22 f0    	or     0xf0227228,%eax
	shift ^= togglecode[data];
f01006c0:	0f b6 8a 40 6b 10 f0 	movzbl -0xfef94c0(%edx),%ecx
f01006c7:	31 c8                	xor    %ecx,%eax
f01006c9:	a3 28 72 22 f0       	mov    %eax,0xf0227228

	c = charcode[shift & (CTL | SHIFT)][data];
f01006ce:	89 c1                	mov    %eax,%ecx
f01006d0:	83 e1 03             	and    $0x3,%ecx
f01006d3:	8b 0c 8d 40 6c 10 f0 	mov    -0xfef93c0(,%ecx,4),%ecx
f01006da:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01006de:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01006e1:	a8 08                	test   $0x8,%al
f01006e3:	74 1b                	je     f0100700 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01006e5:	89 da                	mov    %ebx,%edx
f01006e7:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01006ea:	83 f9 19             	cmp    $0x19,%ecx
f01006ed:	77 05                	ja     f01006f4 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01006ef:	83 eb 20             	sub    $0x20,%ebx
f01006f2:	eb 0c                	jmp    f0100700 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01006f4:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01006f7:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01006fa:	83 fa 19             	cmp    $0x19,%edx
f01006fd:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100700:	f7 d0                	not    %eax
f0100702:	a8 06                	test   $0x6,%al
f0100704:	75 26                	jne    f010072c <kbd_proc_data+0xff>
f0100706:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010070c:	75 1e                	jne    f010072c <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f010070e:	c7 04 24 02 6a 10 f0 	movl   $0xf0106a02,(%esp)
f0100715:	e8 a4 36 00 00       	call   f0103dbe <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010071a:	ba 92 00 00 00       	mov    $0x92,%edx
f010071f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100724:	ee                   	out    %al,(%dx)
f0100725:	eb 05                	jmp    f010072c <kbd_proc_data+0xff>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100727:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010072c:	89 d8                	mov    %ebx,%eax
f010072e:	83 c4 14             	add    $0x14,%esp
f0100731:	5b                   	pop    %ebx
f0100732:	5d                   	pop    %ebp
f0100733:	c3                   	ret    

f0100734 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100734:	83 3d 00 70 22 f0 00 	cmpl   $0x0,0xf0227000
f010073b:	74 11                	je     f010074e <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010073d:	55                   	push   %ebp
f010073e:	89 e5                	mov    %esp,%ebp
f0100740:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100743:	b8 ee 03 10 f0       	mov    $0xf01003ee,%eax
f0100748:	e8 bd fc ff ff       	call   f010040a <cons_intr>
}
f010074d:	c9                   	leave  
f010074e:	f3 c3                	repz ret 

f0100750 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100750:	55                   	push   %ebp
f0100751:	89 e5                	mov    %esp,%ebp
f0100753:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100756:	b8 2d 06 10 f0       	mov    $0xf010062d,%eax
f010075b:	e8 aa fc ff ff       	call   f010040a <cons_intr>
}
f0100760:	c9                   	leave  
f0100761:	c3                   	ret    

f0100762 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100762:	55                   	push   %ebp
f0100763:	89 e5                	mov    %esp,%ebp
f0100765:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100768:	e8 c7 ff ff ff       	call   f0100734 <serial_intr>
	kbd_intr();
f010076d:	e8 de ff ff ff       	call   f0100750 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100772:	8b 15 20 72 22 f0    	mov    0xf0227220,%edx
f0100778:	3b 15 24 72 22 f0    	cmp    0xf0227224,%edx
f010077e:	74 20                	je     f01007a0 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f0100780:	0f b6 82 20 70 22 f0 	movzbl -0xfdd8fe0(%edx),%eax
f0100787:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010078a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f0100790:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100795:	0f 44 d1             	cmove  %ecx,%edx
f0100798:	89 15 20 72 22 f0    	mov    %edx,0xf0227220
f010079e:	eb 05                	jmp    f01007a5 <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01007a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01007a5:	c9                   	leave  
f01007a6:	c3                   	ret    

f01007a7 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01007a7:	55                   	push   %ebp
f01007a8:	89 e5                	mov    %esp,%ebp
f01007aa:	57                   	push   %edi
f01007ab:	56                   	push   %esi
f01007ac:	53                   	push   %ebx
f01007ad:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01007b0:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01007b7:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01007be:	5a a5 
	if (*cp != 0xA55A) {
f01007c0:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01007c7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01007cb:	74 11                	je     f01007de <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01007cd:	c7 05 2c 72 22 f0 b4 	movl   $0x3b4,0xf022722c
f01007d4:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01007d7:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01007dc:	eb 16                	jmp    f01007f4 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01007de:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01007e5:	c7 05 2c 72 22 f0 d4 	movl   $0x3d4,0xf022722c
f01007ec:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01007ef:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01007f4:	8b 0d 2c 72 22 f0    	mov    0xf022722c,%ecx
f01007fa:	b8 0e 00 00 00       	mov    $0xe,%eax
f01007ff:	89 ca                	mov    %ecx,%edx
f0100801:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100802:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100805:	89 da                	mov    %ebx,%edx
f0100807:	ec                   	in     (%dx),%al
f0100808:	0f b6 f0             	movzbl %al,%esi
f010080b:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010080e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100813:	89 ca                	mov    %ecx,%edx
f0100815:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100816:	89 da                	mov    %ebx,%edx
f0100818:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100819:	89 3d 30 72 22 f0    	mov    %edi,0xf0227230
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010081f:	0f b6 d8             	movzbl %al,%ebx
f0100822:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100824:	66 89 35 34 72 22 f0 	mov    %si,0xf0227234

static void
kbd_init(void)
{
	// Drain the kbd buffer so that Bochs generates interrupts.
	kbd_intr();
f010082b:	e8 20 ff ff ff       	call   f0100750 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f0100830:	0f b7 05 88 13 12 f0 	movzwl 0xf0121388,%eax
f0100837:	25 fd ff 00 00       	and    $0xfffd,%eax
f010083c:	89 04 24             	mov    %eax,(%esp)
f010083f:	e8 38 34 00 00       	call   f0103c7c <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100844:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100849:	b8 00 00 00 00       	mov    $0x0,%eax
f010084e:	89 f2                	mov    %esi,%edx
f0100850:	ee                   	out    %al,(%dx)
f0100851:	b2 fb                	mov    $0xfb,%dl
f0100853:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100858:	ee                   	out    %al,(%dx)
f0100859:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010085e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100863:	89 da                	mov    %ebx,%edx
f0100865:	ee                   	out    %al,(%dx)
f0100866:	b2 f9                	mov    $0xf9,%dl
f0100868:	b8 00 00 00 00       	mov    $0x0,%eax
f010086d:	ee                   	out    %al,(%dx)
f010086e:	b2 fb                	mov    $0xfb,%dl
f0100870:	b8 03 00 00 00       	mov    $0x3,%eax
f0100875:	ee                   	out    %al,(%dx)
f0100876:	b2 fc                	mov    $0xfc,%dl
f0100878:	b8 00 00 00 00       	mov    $0x0,%eax
f010087d:	ee                   	out    %al,(%dx)
f010087e:	b2 f9                	mov    $0xf9,%dl
f0100880:	b8 01 00 00 00       	mov    $0x1,%eax
f0100885:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100886:	b2 fd                	mov    $0xfd,%dl
f0100888:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100889:	3c ff                	cmp    $0xff,%al
f010088b:	0f 95 c1             	setne  %cl
f010088e:	0f b6 c9             	movzbl %cl,%ecx
f0100891:	89 0d 00 70 22 f0    	mov    %ecx,0xf0227000
f0100897:	89 f2                	mov    %esi,%edx
f0100899:	ec                   	in     (%dx),%al
f010089a:	89 da                	mov    %ebx,%edx
f010089c:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010089d:	85 c9                	test   %ecx,%ecx
f010089f:	75 0c                	jne    f01008ad <cons_init+0x106>
		cprintf("Serial port does not exist!\n");
f01008a1:	c7 04 24 0e 6a 10 f0 	movl   $0xf0106a0e,(%esp)
f01008a8:	e8 11 35 00 00       	call   f0103dbe <cprintf>
}
f01008ad:	83 c4 1c             	add    $0x1c,%esp
f01008b0:	5b                   	pop    %ebx
f01008b1:	5e                   	pop    %esi
f01008b2:	5f                   	pop    %edi
f01008b3:	5d                   	pop    %ebp
f01008b4:	c3                   	ret    

f01008b5 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01008b5:	55                   	push   %ebp
f01008b6:	89 e5                	mov    %esp,%ebp
f01008b8:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01008bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01008be:	e8 87 fb ff ff       	call   f010044a <cons_putc>
}
f01008c3:	c9                   	leave  
f01008c4:	c3                   	ret    

f01008c5 <getchar>:

int
getchar(void)
{
f01008c5:	55                   	push   %ebp
f01008c6:	89 e5                	mov    %esp,%ebp
f01008c8:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01008cb:	e8 92 fe ff ff       	call   f0100762 <cons_getc>
f01008d0:	85 c0                	test   %eax,%eax
f01008d2:	74 f7                	je     f01008cb <getchar+0x6>
		/* do nothing */;
	return c;
}
f01008d4:	c9                   	leave  
f01008d5:	c3                   	ret    

f01008d6 <iscons>:

int
iscons(int fdnum)
{
f01008d6:	55                   	push   %ebp
f01008d7:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01008d9:	b8 01 00 00 00       	mov    $0x1,%eax
f01008de:	5d                   	pop    %ebp
f01008df:	c3                   	ret    

f01008e0 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01008e0:	55                   	push   %ebp
f01008e1:	89 e5                	mov    %esp,%ebp
f01008e3:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01008e6:	c7 04 24 50 6c 10 f0 	movl   $0xf0106c50,(%esp)
f01008ed:	e8 cc 34 00 00       	call   f0103dbe <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01008f2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01008f9:	00 
f01008fa:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100901:	f0 
f0100902:	c7 04 24 68 6d 10 f0 	movl   $0xf0106d68,(%esp)
f0100909:	e8 b0 34 00 00       	call   f0103dbe <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010090e:	c7 44 24 08 2f 69 10 	movl   $0x10692f,0x8(%esp)
f0100915:	00 
f0100916:	c7 44 24 04 2f 69 10 	movl   $0xf010692f,0x4(%esp)
f010091d:	f0 
f010091e:	c7 04 24 8c 6d 10 f0 	movl   $0xf0106d8c,(%esp)
f0100925:	e8 94 34 00 00       	call   f0103dbe <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010092a:	c7 44 24 08 62 68 22 	movl   $0x226862,0x8(%esp)
f0100931:	00 
f0100932:	c7 44 24 04 62 68 22 	movl   $0xf0226862,0x4(%esp)
f0100939:	f0 
f010093a:	c7 04 24 b0 6d 10 f0 	movl   $0xf0106db0,(%esp)
f0100941:	e8 78 34 00 00       	call   f0103dbe <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100946:	c7 44 24 08 04 90 26 	movl   $0x269004,0x8(%esp)
f010094d:	00 
f010094e:	c7 44 24 04 04 90 26 	movl   $0xf0269004,0x4(%esp)
f0100955:	f0 
f0100956:	c7 04 24 d4 6d 10 f0 	movl   $0xf0106dd4,(%esp)
f010095d:	e8 5c 34 00 00       	call   f0103dbe <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100962:	b8 03 94 26 f0       	mov    $0xf0269403,%eax
f0100967:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010096c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100972:	85 c0                	test   %eax,%eax
f0100974:	0f 48 c2             	cmovs  %edx,%eax
f0100977:	c1 f8 0a             	sar    $0xa,%eax
f010097a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097e:	c7 04 24 f8 6d 10 f0 	movl   $0xf0106df8,(%esp)
f0100985:	e8 34 34 00 00       	call   f0103dbe <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010098a:	b8 00 00 00 00       	mov    $0x0,%eax
f010098f:	c9                   	leave  
f0100990:	c3                   	ret    

f0100991 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100991:	55                   	push   %ebp
f0100992:	89 e5                	mov    %esp,%ebp
f0100994:	56                   	push   %esi
f0100995:	53                   	push   %ebx
f0100996:	83 ec 10             	sub    $0x10,%esp
f0100999:	bb a4 6e 10 f0       	mov    $0xf0106ea4,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f010099e:	be e0 6e 10 f0       	mov    $0xf0106ee0,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01009a3:	8b 03                	mov    (%ebx),%eax
f01009a5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009a9:	8b 43 fc             	mov    -0x4(%ebx),%eax
f01009ac:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b0:	c7 04 24 69 6c 10 f0 	movl   $0xf0106c69,(%esp)
f01009b7:	e8 02 34 00 00       	call   f0103dbe <cprintf>
f01009bc:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01009bf:	39 f3                	cmp    %esi,%ebx
f01009c1:	75 e0                	jne    f01009a3 <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f01009c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01009c8:	83 c4 10             	add    $0x10,%esp
f01009cb:	5b                   	pop    %ebx
f01009cc:	5e                   	pop    %esi
f01009cd:	5d                   	pop    %ebp
f01009ce:	c3                   	ret    

f01009cf <mon_debug>:
	}
	return -1;
}

int
mon_debug(int argc, char **argv, struct Trapframe *tf){
f01009cf:	55                   	push   %ebp
f01009d0:	89 e5                	mov    %esp,%ebp
f01009d2:	83 ec 18             	sub    $0x18,%esp
f01009d5:	8b 45 10             	mov    0x10(%ebp),%eax
	if(tf -> tf_trapno == T_BRKPT || tf -> tf_trapno == T_DEBUG){
f01009d8:	8b 50 28             	mov    0x28(%eax),%edx
f01009db:	83 e2 fd             	and    $0xfffffffd,%edx
f01009de:	83 fa 01             	cmp    $0x1,%edx
f01009e1:	75 1d                	jne    f0100a00 <mon_debug+0x31>
		tf -> tf_eflags |= FL_TF;
f01009e3:	81 48 38 00 01 00 00 	orl    $0x100,0x38(%eax)
		env_run(curenv);
f01009ea:	e8 dd 57 00 00       	call   f01061cc <cpunum>
f01009ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01009f2:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01009f8:	89 04 24             	mov    %eax,(%esp)
f01009fb:	e8 92 31 00 00       	call   f0103b92 <env_run>
	}
	return -1;
}
f0100a00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100a05:	c9                   	leave  
f0100a06:	c3                   	ret    

f0100a07 <mon_continue>:
	}while(ebp);
	return 0;
}

int
mon_continue(int argc, char **argv, struct Trapframe *tf){
f0100a07:	55                   	push   %ebp
f0100a08:	89 e5                	mov    %esp,%ebp
f0100a0a:	83 ec 18             	sub    $0x18,%esp
f0100a0d:	8b 45 10             	mov    0x10(%ebp),%eax
	if(tf -> tf_trapno == T_BRKPT || tf -> tf_trapno == T_DEBUG){
f0100a10:	8b 50 28             	mov    0x28(%eax),%edx
f0100a13:	83 e2 fd             	and    $0xfffffffd,%edx
f0100a16:	83 fa 01             	cmp    $0x1,%edx
f0100a19:	75 1d                	jne    f0100a38 <mon_continue+0x31>
	//	panic("##%x##\n",tf -> tf_eflags);
		tf -> tf_eflags &= ~FL_TF;
f0100a1b:	81 60 38 ff fe ff ff 	andl   $0xfffffeff,0x38(%eax)
		env_run(curenv);
f0100a22:	e8 a5 57 00 00       	call   f01061cc <cpunum>
f0100a27:	6b c0 74             	imul   $0x74,%eax,%eax
f0100a2a:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0100a30:	89 04 24             	mov    %eax,(%esp)
f0100a33:	e8 5a 31 00 00       	call   f0103b92 <env_run>
	}
	return -1;
}
f0100a38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100a3d:	c9                   	leave  
f0100a3e:	c3                   	ret    

f0100a3f <mon_backtrace>:
 * 2. *ebp is the new ebp(actually old)
 * 3. get the end(ebp = 0 -> see kern/entry.S, stack movl $0, %ebp)
 */
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100a3f:	55                   	push   %ebp
f0100a40:	89 e5                	mov    %esp,%ebp
f0100a42:	57                   	push   %edi
f0100a43:	56                   	push   %esi
f0100a44:	53                   	push   %ebx
f0100a45:	83 ec 3c             	sub    $0x3c,%esp
	// Your code here.
	uint32_t ebp,eip;
	int i;	
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100a48:	c7 04 24 72 6c 10 f0 	movl   $0xf0106c72,(%esp)
f0100a4f:	e8 6a 33 00 00       	call   f0103dbe <cprintf>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100a54:	89 ee                	mov    %ebp,%esi
	ebp = read_ebp();
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
f0100a56:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a5a:	c7 04 24 84 6c 10 f0 	movl   $0xf0106c84,(%esp)
f0100a61:	e8 58 33 00 00       	call   f0103dbe <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f0100a66:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f0100a69:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100a6d:	c7 04 24 8f 6c 10 f0 	movl   $0xf0106c8f,(%esp)
f0100a74:	e8 45 33 00 00       	call   f0103dbe <cprintf>
		for(i=2; i < 7; i++)
f0100a79:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f0100a7e:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100a81:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a85:	c7 04 24 89 6c 10 f0 	movl   $0xf0106c89,(%esp)
f0100a8c:	e8 2d 33 00 00       	call   f0103dbe <cprintf>
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
		eip = *(uint32_t *)(ebp + 4);
		cprintf("  eip %08x  args",eip);
		for(i=2; i < 7; i++)
f0100a91:	83 c3 01             	add    $0x1,%ebx
f0100a94:	83 fb 07             	cmp    $0x7,%ebx
f0100a97:	75 e5                	jne    f0100a7e <mon_backtrace+0x3f>
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
		cprintf("\n");
f0100a99:	c7 04 24 f8 75 10 f0 	movl   $0xf01075f8,(%esp)
f0100aa0:	e8 19 33 00 00       	call   f0103dbe <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f0100aa5:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100aa8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100aac:	89 3c 24             	mov    %edi,(%esp)
f0100aaf:	e8 62 44 00 00       	call   f0104f16 <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f0100ab4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ab7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100abb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100abe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ac2:	c7 04 24 a0 6c 10 f0 	movl   $0xf0106ca0,(%esp)
f0100ac9:	e8 f0 32 00 00       	call   f0103dbe <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f0100ace:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ad1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ad5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ad8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100adc:	c7 04 24 a9 6c 10 f0 	movl   $0xf0106ca9,(%esp)
f0100ae3:	e8 d6 32 00 00       	call   f0103dbe <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f0100ae8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aeb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100aef:	c7 04 24 ae 6c 10 f0 	movl   $0xf0106cae,(%esp)
f0100af6:	e8 c3 32 00 00       	call   f0103dbe <cprintf>
		ebp = *(uint32_t *)ebp;
f0100afb:	8b 36                	mov    (%esi),%esi
	}while(ebp);
f0100afd:	85 f6                	test   %esi,%esi
f0100aff:	0f 85 51 ff ff ff    	jne    f0100a56 <mon_backtrace+0x17>
	return 0;
}
f0100b05:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b0a:	83 c4 3c             	add    $0x3c,%esp
f0100b0d:	5b                   	pop    %ebx
f0100b0e:	5e                   	pop    %esi
f0100b0f:	5f                   	pop    %edi
f0100b10:	5d                   	pop    %ebp
f0100b11:	c3                   	ret    

f0100b12 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100b12:	55                   	push   %ebp
f0100b13:	89 e5                	mov    %esp,%ebp
f0100b15:	57                   	push   %edi
f0100b16:	56                   	push   %esi
f0100b17:	53                   	push   %ebx
f0100b18:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100b1b:	c7 04 24 24 6e 10 f0 	movl   $0xf0106e24,(%esp)
f0100b22:	e8 97 32 00 00       	call   f0103dbe <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100b27:	c7 04 24 48 6e 10 f0 	movl   $0xf0106e48,(%esp)
f0100b2e:	e8 8b 32 00 00       	call   f0103dbe <cprintf>

	if (tf != NULL)
f0100b33:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100b37:	74 0b                	je     f0100b44 <monitor+0x32>
		print_trapframe(tf);
f0100b39:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b3c:	89 04 24             	mov    %eax,(%esp)
f0100b3f:	e8 72 37 00 00       	call   f01042b6 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100b44:	c7 04 24 b3 6c 10 f0 	movl   $0xf0106cb3,(%esp)
f0100b4b:	e8 00 4d 00 00       	call   f0105850 <readline>
f0100b50:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100b52:	85 c0                	test   %eax,%eax
f0100b54:	74 ee                	je     f0100b44 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100b56:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100b5d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100b62:	eb 06                	jmp    f0100b6a <monitor+0x58>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100b64:	c6 06 00             	movb   $0x0,(%esi)
f0100b67:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b6a:	0f b6 06             	movzbl (%esi),%eax
f0100b6d:	84 c0                	test   %al,%al
f0100b6f:	74 6a                	je     f0100bdb <monitor+0xc9>
f0100b71:	0f be c0             	movsbl %al,%eax
f0100b74:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b78:	c7 04 24 b7 6c 10 f0 	movl   $0xf0106cb7,(%esp)
f0100b7f:	e8 41 4f 00 00       	call   f0105ac5 <strchr>
f0100b84:	85 c0                	test   %eax,%eax
f0100b86:	75 dc                	jne    f0100b64 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100b88:	80 3e 00             	cmpb   $0x0,(%esi)
f0100b8b:	74 4e                	je     f0100bdb <monitor+0xc9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100b8d:	83 fb 0f             	cmp    $0xf,%ebx
f0100b90:	75 16                	jne    f0100ba8 <monitor+0x96>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100b92:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100b99:	00 
f0100b9a:	c7 04 24 bc 6c 10 f0 	movl   $0xf0106cbc,(%esp)
f0100ba1:	e8 18 32 00 00       	call   f0103dbe <cprintf>
f0100ba6:	eb 9c                	jmp    f0100b44 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100ba8:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f0100bac:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100baf:	0f b6 06             	movzbl (%esi),%eax
f0100bb2:	84 c0                	test   %al,%al
f0100bb4:	75 0c                	jne    f0100bc2 <monitor+0xb0>
f0100bb6:	eb b2                	jmp    f0100b6a <monitor+0x58>
			buf++;
f0100bb8:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100bbb:	0f b6 06             	movzbl (%esi),%eax
f0100bbe:	84 c0                	test   %al,%al
f0100bc0:	74 a8                	je     f0100b6a <monitor+0x58>
f0100bc2:	0f be c0             	movsbl %al,%eax
f0100bc5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bc9:	c7 04 24 b7 6c 10 f0 	movl   $0xf0106cb7,(%esp)
f0100bd0:	e8 f0 4e 00 00       	call   f0105ac5 <strchr>
f0100bd5:	85 c0                	test   %eax,%eax
f0100bd7:	74 df                	je     f0100bb8 <monitor+0xa6>
f0100bd9:	eb 8f                	jmp    f0100b6a <monitor+0x58>
			buf++;
	}
	argv[argc] = 0;
f0100bdb:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100be2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100be3:	85 db                	test   %ebx,%ebx
f0100be5:	0f 84 59 ff ff ff    	je     f0100b44 <monitor+0x32>
f0100beb:	bf a0 6e 10 f0       	mov    $0xf0106ea0,%edi
f0100bf0:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100bf5:	8b 07                	mov    (%edi),%eax
f0100bf7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bfb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100bfe:	89 04 24             	mov    %eax,(%esp)
f0100c01:	e8 3b 4e 00 00       	call   f0105a41 <strcmp>
f0100c06:	85 c0                	test   %eax,%eax
f0100c08:	75 24                	jne    f0100c2e <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100c0a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c0d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100c10:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c14:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100c17:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c1b:	89 1c 24             	mov    %ebx,(%esp)
f0100c1e:	ff 14 85 a8 6e 10 f0 	call   *-0xfef9158(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100c25:	85 c0                	test   %eax,%eax
f0100c27:	78 28                	js     f0100c51 <monitor+0x13f>
f0100c29:	e9 16 ff ff ff       	jmp    f0100b44 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100c2e:	83 c6 01             	add    $0x1,%esi
f0100c31:	83 c7 0c             	add    $0xc,%edi
f0100c34:	83 fe 05             	cmp    $0x5,%esi
f0100c37:	75 bc                	jne    f0100bf5 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100c39:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100c3c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c40:	c7 04 24 d9 6c 10 f0 	movl   $0xf0106cd9,(%esp)
f0100c47:	e8 72 31 00 00       	call   f0103dbe <cprintf>
f0100c4c:	e9 f3 fe ff ff       	jmp    f0100b44 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100c51:	83 c4 5c             	add    $0x5c,%esp
f0100c54:	5b                   	pop    %ebx
f0100c55:	5e                   	pop    %esi
f0100c56:	5f                   	pop    %edi
f0100c57:	5d                   	pop    %ebp
f0100c58:	c3                   	ret    

f0100c59 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100c59:	55                   	push   %ebp
f0100c5a:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100c5c:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100c5f:	5d                   	pop    %ebp
f0100c60:	c3                   	ret    
f0100c61:	66 90                	xchg   %ax,%ax
f0100c63:	66 90                	xchg   %ax,%ax
f0100c65:	66 90                	xchg   %ax,%ax
f0100c67:	66 90                	xchg   %ax,%ax
f0100c69:	66 90                	xchg   %ax,%ax
f0100c6b:	66 90                	xchg   %ax,%ax
f0100c6d:	66 90                	xchg   %ax,%ax
f0100c6f:	90                   	nop

f0100c70 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100c70:	89 d1                	mov    %edx,%ecx
f0100c72:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100c75:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100c78:	a8 01                	test   $0x1,%al
f0100c7a:	74 5d                	je     f0100cd9 <check_va2pa+0x69>
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100c7c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c81:	89 c1                	mov    %eax,%ecx
f0100c83:	c1 e9 0c             	shr    $0xc,%ecx
f0100c86:	3b 0d 88 7e 22 f0    	cmp    0xf0227e88,%ecx
f0100c8c:	72 26                	jb     f0100cb4 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100c8e:	55                   	push   %ebp
f0100c8f:	89 e5                	mov    %esp,%ebp
f0100c91:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c94:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c98:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0100c9f:	f0 
f0100ca0:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0100ca7:	00 
f0100ca8:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0100caf:	e8 8c f3 ff ff       	call   f0100040 <_panic>
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100cb4:	c1 ea 0c             	shr    $0xc,%edx
f0100cb7:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100cbd:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100cc4:	89 c2                	mov    %eax,%edx
f0100cc6:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100cc9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cce:	85 d2                	test   %edx,%edx
f0100cd0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100cd5:	0f 44 c2             	cmove  %edx,%eax
f0100cd8:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100cd9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100cde:	c3                   	ret    

f0100cdf <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100cdf:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ce1:	83 3d 3c 72 22 f0 00 	cmpl   $0x0,0xf022723c
f0100ce8:	75 0f                	jne    f0100cf9 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100cea:	b8 03 a0 26 f0       	mov    $0xf026a003,%eax
f0100cef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cf4:	a3 3c 72 22 f0       	mov    %eax,0xf022723c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f0100cf9:	85 d2                	test   %edx,%edx
f0100cfb:	75 06                	jne    f0100d03 <boot_alloc+0x24>
		return nextfree;
f0100cfd:	a1 3c 72 22 f0       	mov    0xf022723c,%eax
f0100d02:	c3                   	ret    
	result = nextfree;
f0100d03:	a1 3c 72 22 f0       	mov    0xf022723c,%eax
	nextfree += (n/PGSIZE + 1)*PGSIZE;
f0100d08:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100d0e:	8d 94 10 00 10 00 00 	lea    0x1000(%eax,%edx,1),%edx
f0100d15:	89 15 3c 72 22 f0    	mov    %edx,0xf022723c
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
f0100d1b:	8b 0d 88 7e 22 f0    	mov    0xf0227e88,%ecx
f0100d21:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f0100d27:	c1 e1 0c             	shl    $0xc,%ecx
f0100d2a:	39 ca                	cmp    %ecx,%edx
f0100d2c:	72 22                	jb     f0100d50 <boot_alloc+0x71>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100d2e:	55                   	push   %ebp
f0100d2f:	89 e5                	mov    %esp,%ebp
f0100d31:	83 ec 18             	sub    $0x18,%esp
	if(n == 0)
		return nextfree;
	result = nextfree;
	nextfree += (n/PGSIZE + 1)*PGSIZE;
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
		panic("Run out of memory!!\n");
f0100d34:	c7 44 24 08 e5 75 10 	movl   $0xf01075e5,0x8(%esp)
f0100d3b:	f0 
f0100d3c:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
f0100d43:	00 
f0100d44:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0100d4b:	e8 f0 f2 ff ff       	call   f0100040 <_panic>
	return result;
}
f0100d50:	f3 c3                	repz ret 

f0100d52 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100d52:	55                   	push   %ebp
f0100d53:	89 e5                	mov    %esp,%ebp
f0100d55:	83 ec 18             	sub    $0x18,%esp
f0100d58:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100d5b:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100d5e:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100d60:	89 04 24             	mov    %eax,(%esp)
f0100d63:	e8 e8 2e 00 00       	call   f0103c50 <mc146818_read>
f0100d68:	89 c6                	mov    %eax,%esi
f0100d6a:	83 c3 01             	add    $0x1,%ebx
f0100d6d:	89 1c 24             	mov    %ebx,(%esp)
f0100d70:	e8 db 2e 00 00       	call   f0103c50 <mc146818_read>
f0100d75:	c1 e0 08             	shl    $0x8,%eax
f0100d78:	09 f0                	or     %esi,%eax
}
f0100d7a:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100d7d:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100d80:	89 ec                	mov    %ebp,%esp
f0100d82:	5d                   	pop    %ebp
f0100d83:	c3                   	ret    

f0100d84 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100d84:	55                   	push   %ebp
f0100d85:	89 e5                	mov    %esp,%ebp
f0100d87:	57                   	push   %edi
f0100d88:	56                   	push   %esi
f0100d89:	53                   	push   %ebx
f0100d8a:	83 ec 4c             	sub    $0x4c,%esp
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d8d:	85 c0                	test   %eax,%eax
f0100d8f:	0f 85 71 03 00 00    	jne    f0101106 <check_page_free_list+0x382>
f0100d95:	e9 7e 03 00 00       	jmp    f0101118 <check_page_free_list+0x394>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100d9a:	c7 44 24 08 dc 6e 10 	movl   $0xf0106edc,0x8(%esp)
f0100da1:	f0 
f0100da2:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0100da9:	00 
f0100daa:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0100db1:	e8 8a f2 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100db6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100db9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100dbc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100dbf:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dc2:	89 c2                	mov    %eax,%edx
f0100dc4:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100dca:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100dd0:	0f 95 c2             	setne  %dl
f0100dd3:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100dd6:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100dda:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ddc:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100de0:	8b 00                	mov    (%eax),%eax
f0100de2:	85 c0                	test   %eax,%eax
f0100de4:	75 dc                	jne    f0100dc2 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100de6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100de9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100def:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100df2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100df5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100df7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100dfa:	a3 40 72 22 f0       	mov    %eax,0xf0227240
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dff:	89 c3                	mov    %eax,%ebx
f0100e01:	85 c0                	test   %eax,%eax
f0100e03:	74 6c                	je     f0100e71 <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e05:	be 01 00 00 00       	mov    $0x1,%esi
f0100e0a:	89 d8                	mov    %ebx,%eax
f0100e0c:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f0100e12:	c1 f8 03             	sar    $0x3,%eax
f0100e15:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100e18:	89 c2                	mov    %eax,%edx
f0100e1a:	c1 ea 16             	shr    $0x16,%edx
f0100e1d:	39 f2                	cmp    %esi,%edx
f0100e1f:	73 4a                	jae    f0100e6b <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e21:	89 c2                	mov    %eax,%edx
f0100e23:	c1 ea 0c             	shr    $0xc,%edx
f0100e26:	3b 15 88 7e 22 f0    	cmp    0xf0227e88,%edx
f0100e2c:	72 20                	jb     f0100e4e <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e2e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e32:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0100e39:	f0 
f0100e3a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100e41:	00 
f0100e42:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0100e49:	e8 f2 f1 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100e4e:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100e55:	00 
f0100e56:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100e5d:	00 
	return (void *)(pa + KERNBASE);
f0100e5e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e63:	89 04 24             	mov    %eax,(%esp)
f0100e66:	e8 ba 4c 00 00       	call   f0105b25 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e6b:	8b 1b                	mov    (%ebx),%ebx
f0100e6d:	85 db                	test   %ebx,%ebx
f0100e6f:	75 99                	jne    f0100e0a <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100e71:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e76:	e8 64 fe ff ff       	call   f0100cdf <boot_alloc>
f0100e7b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e7e:	8b 15 40 72 22 f0    	mov    0xf0227240,%edx
f0100e84:	85 d2                	test   %edx,%edx
f0100e86:	0f 84 2e 02 00 00    	je     f01010ba <check_page_free_list+0x336>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100e8c:	8b 3d 90 7e 22 f0    	mov    0xf0227e90,%edi
f0100e92:	39 fa                	cmp    %edi,%edx
f0100e94:	72 51                	jb     f0100ee7 <check_page_free_list+0x163>
		assert(pp < pages + npages);
f0100e96:	a1 88 7e 22 f0       	mov    0xf0227e88,%eax
f0100e9b:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100e9e:	8d 04 c7             	lea    (%edi,%eax,8),%eax
f0100ea1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100ea4:	39 c2                	cmp    %eax,%edx
f0100ea6:	73 68                	jae    f0100f10 <check_page_free_list+0x18c>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ea8:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0100eab:	89 d0                	mov    %edx,%eax
f0100ead:	29 f8                	sub    %edi,%eax
f0100eaf:	a8 07                	test   $0x7,%al
f0100eb1:	0f 85 86 00 00 00    	jne    f0100f3d <check_page_free_list+0x1b9>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100eb7:	c1 f8 03             	sar    $0x3,%eax
f0100eba:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ebd:	85 c0                	test   %eax,%eax
f0100ebf:	0f 84 a6 00 00 00    	je     f0100f6b <check_page_free_list+0x1e7>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ec5:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100eca:	0f 84 c6 00 00 00    	je     f0100f96 <check_page_free_list+0x212>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ed0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ed5:	be 00 00 00 00       	mov    $0x0,%esi
f0100eda:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100edd:	e9 d8 00 00 00       	jmp    f0100fba <check_page_free_list+0x236>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ee2:	3b 55 c0             	cmp    -0x40(%ebp),%edx
f0100ee5:	73 24                	jae    f0100f0b <check_page_free_list+0x187>
f0100ee7:	c7 44 24 0c 08 76 10 	movl   $0xf0107608,0xc(%esp)
f0100eee:	f0 
f0100eef:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0100ef6:	f0 
f0100ef7:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f0100efe:	00 
f0100eff:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0100f06:	e8 35 f1 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100f0b:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100f0e:	72 24                	jb     f0100f34 <check_page_free_list+0x1b0>
f0100f10:	c7 44 24 0c 29 76 10 	movl   $0xf0107629,0xc(%esp)
f0100f17:	f0 
f0100f18:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0100f1f:	f0 
f0100f20:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f0100f27:	00 
f0100f28:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0100f2f:	e8 0c f1 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f34:	89 d0                	mov    %edx,%eax
f0100f36:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100f39:	a8 07                	test   $0x7,%al
f0100f3b:	74 24                	je     f0100f61 <check_page_free_list+0x1dd>
f0100f3d:	c7 44 24 0c 00 6f 10 	movl   $0xf0106f00,0xc(%esp)
f0100f44:	f0 
f0100f45:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0100f4c:	f0 
f0100f4d:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f0100f54:	00 
f0100f55:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0100f5c:	e8 df f0 ff ff       	call   f0100040 <_panic>
f0100f61:	c1 f8 03             	sar    $0x3,%eax
f0100f64:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100f67:	85 c0                	test   %eax,%eax
f0100f69:	75 24                	jne    f0100f8f <check_page_free_list+0x20b>
f0100f6b:	c7 44 24 0c 3d 76 10 	movl   $0xf010763d,0xc(%esp)
f0100f72:	f0 
f0100f73:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0100f7a:	f0 
f0100f7b:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f0100f82:	00 
f0100f83:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0100f8a:	e8 b1 f0 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f8f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f94:	75 24                	jne    f0100fba <check_page_free_list+0x236>
f0100f96:	c7 44 24 0c 4e 76 10 	movl   $0xf010764e,0xc(%esp)
f0100f9d:	f0 
f0100f9e:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0100fa5:	f0 
f0100fa6:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f0100fad:	00 
f0100fae:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0100fb5:	e8 86 f0 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100fba:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100fbf:	75 24                	jne    f0100fe5 <check_page_free_list+0x261>
f0100fc1:	c7 44 24 0c 34 6f 10 	movl   $0xf0106f34,0xc(%esp)
f0100fc8:	f0 
f0100fc9:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0100fd0:	f0 
f0100fd1:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0100fd8:	00 
f0100fd9:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0100fe0:	e8 5b f0 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100fe5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100fea:	75 24                	jne    f0101010 <check_page_free_list+0x28c>
f0100fec:	c7 44 24 0c 67 76 10 	movl   $0xf0107667,0xc(%esp)
f0100ff3:	f0 
f0100ff4:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0100ffb:	f0 
f0100ffc:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0101003:	00 
f0101004:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010100b:	e8 30 f0 ff ff       	call   f0100040 <_panic>
f0101010:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101012:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101017:	0f 86 09 01 00 00    	jbe    f0101126 <check_page_free_list+0x3a2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010101d:	89 c7                	mov    %eax,%edi
f010101f:	c1 ef 0c             	shr    $0xc,%edi
f0101022:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0101025:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0101028:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f010102b:	72 20                	jb     f010104d <check_page_free_list+0x2c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010102d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101031:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0101038:	f0 
f0101039:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101040:	00 
f0101041:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0101048:	e8 f3 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010104d:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0101053:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0101056:	0f 86 da 00 00 00    	jbe    f0101136 <check_page_free_list+0x3b2>
f010105c:	c7 44 24 0c 58 6f 10 	movl   $0xf0106f58,0xc(%esp)
f0101063:	f0 
f0101064:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010106b:	f0 
f010106c:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0101073:	00 
f0101074:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010107b:	e8 c0 ef ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0101080:	c7 44 24 0c 81 76 10 	movl   $0xf0107681,0xc(%esp)
f0101087:	f0 
f0101088:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010108f:	f0 
f0101090:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f0101097:	00 
f0101098:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010109f:	e8 9c ef ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f01010a4:	83 c6 01             	add    $0x1,%esi
f01010a7:	eb 03                	jmp    f01010ac <check_page_free_list+0x328>
		else
			++nfree_extmem;
f01010a9:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010ac:	8b 12                	mov    (%edx),%edx
f01010ae:	85 d2                	test   %edx,%edx
f01010b0:	0f 85 2c fe ff ff    	jne    f0100ee2 <check_page_free_list+0x15e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01010b6:	85 f6                	test   %esi,%esi
f01010b8:	7f 24                	jg     f01010de <check_page_free_list+0x35a>
f01010ba:	c7 44 24 0c 9e 76 10 	movl   $0xf010769e,0xc(%esp)
f01010c1:	f0 
f01010c2:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01010c9:	f0 
f01010ca:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f01010d1:	00 
f01010d2:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01010d9:	e8 62 ef ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f01010de:	85 db                	test   %ebx,%ebx
f01010e0:	7f 74                	jg     f0101156 <check_page_free_list+0x3d2>
f01010e2:	c7 44 24 0c b0 76 10 	movl   $0xf01076b0,0xc(%esp)
f01010e9:	f0 
f01010ea:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01010f1:	f0 
f01010f2:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f01010f9:	00 
f01010fa:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101101:	e8 3a ef ff ff       	call   f0100040 <_panic>
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101106:	a1 40 72 22 f0       	mov    0xf0227240,%eax
f010110b:	85 c0                	test   %eax,%eax
f010110d:	0f 85 a3 fc ff ff    	jne    f0100db6 <check_page_free_list+0x32>
f0101113:	e9 82 fc ff ff       	jmp    f0100d9a <check_page_free_list+0x16>
f0101118:	83 3d 40 72 22 f0 00 	cmpl   $0x0,0xf0227240
f010111f:	75 25                	jne    f0101146 <check_page_free_list+0x3c2>
f0101121:	e9 74 fc ff ff       	jmp    f0100d9a <check_page_free_list+0x16>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0101126:	3d 00 70 00 00       	cmp    $0x7000,%eax
f010112b:	0f 85 73 ff ff ff    	jne    f01010a4 <check_page_free_list+0x320>
f0101131:	e9 4a ff ff ff       	jmp    f0101080 <check_page_free_list+0x2fc>
f0101136:	3d 00 70 00 00       	cmp    $0x7000,%eax
f010113b:	0f 85 68 ff ff ff    	jne    f01010a9 <check_page_free_list+0x325>
f0101141:	e9 3a ff ff ff       	jmp    f0101080 <check_page_free_list+0x2fc>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101146:	8b 1d 40 72 22 f0    	mov    0xf0227240,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010114c:	be 00 04 00 00       	mov    $0x400,%esi
f0101151:	e9 b4 fc ff ff       	jmp    f0100e0a <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0101156:	83 c4 4c             	add    $0x4c,%esp
f0101159:	5b                   	pop    %ebx
f010115a:	5e                   	pop    %esi
f010115b:	5f                   	pop    %edi
f010115c:	5d                   	pop    %ebp
f010115d:	c3                   	ret    

f010115e <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010115e:	55                   	push   %ebp
f010115f:	89 e5                	mov    %esp,%ebp
f0101161:	56                   	push   %esi
f0101162:	53                   	push   %ebx
f0101163:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
f0101166:	a1 90 7e 22 f0       	mov    0xf0227e90,%eax
f010116b:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0101171:	8b 35 38 72 22 f0    	mov    0xf0227238,%esi
f0101177:	83 fe 01             	cmp    $0x1,%esi
f010117a:	76 37                	jbe    f01011b3 <page_init+0x55>
f010117c:	8b 1d 40 72 22 f0    	mov    0xf0227240,%ebx
f0101182:	b8 01 00 00 00       	mov    $0x1,%eax
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
f0101187:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
		pages[i].pp_ref = 0;
f010118e:	8b 0d 90 7e 22 f0    	mov    0xf0227e90,%ecx
f0101194:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f010119b:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f010119e:	8b 1d 90 7e 22 f0    	mov    0xf0227e90,%ebx
f01011a4:	01 d3                	add    %edx,%ebx
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f01011a6:	83 c0 01             	add    $0x1,%eax
f01011a9:	39 f0                	cmp    %esi,%eax
f01011ab:	72 da                	jb     f0101187 <page_init+0x29>
f01011ad:	89 1d 40 72 22 f0    	mov    %ebx,0xf0227240
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	size_t page_num = PADDR(boot_alloc(0)) / PGSIZE;
f01011b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b8:	e8 22 fb ff ff       	call   f0100cdf <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01011bd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01011c2:	77 20                	ja     f01011e4 <page_init+0x86>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01011c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011c8:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f01011cf:	f0 
f01011d0:	c7 44 24 04 5a 01 00 	movl   $0x15a,0x4(%esp)
f01011d7:	00 
f01011d8:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01011df:	e8 5c ee ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01011e4:	05 00 00 00 10       	add    $0x10000000,%eax
f01011e9:	c1 e8 0c             	shr    $0xc,%eax
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f01011ec:	3b 05 88 7e 22 f0    	cmp    0xf0227e88,%eax
f01011f2:	73 39                	jae    f010122d <page_init+0xcf>
f01011f4:	8b 1d 40 72 22 f0    	mov    0xf0227240,%ebx
f01011fa:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0101201:	8b 0d 90 7e 22 f0    	mov    0xf0227e90,%ecx
f0101207:	01 d1                	add    %edx,%ecx
f0101209:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f010120f:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0101211:	8b 1d 90 7e 22 f0    	mov    0xf0227e90,%ebx
f0101217:	01 d3                	add    %edx,%ebx
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0101219:	83 c0 01             	add    $0x1,%eax
f010121c:	83 c2 08             	add    $0x8,%edx
f010121f:	39 05 88 7e 22 f0    	cmp    %eax,0xf0227e88
f0101225:	77 da                	ja     f0101201 <page_init+0xa3>
f0101227:	89 1d 40 72 22 f0    	mov    %ebx,0xf0227240
	}

	page_num = MPENTRY_PADDR / PGSIZE;
	//cprintf("MPENTRY_PADDR: %x\n MPENTRY.link: %x\n ref:%x",
	//	&pages[page_num],pages[page_num].pp_link,pages[page_num+1].pp_link);
	pages[page_num+1].pp_link = pages[page_num].pp_link;
f010122d:	a1 90 7e 22 f0       	mov    0xf0227e90,%eax
f0101232:	8b 50 38             	mov    0x38(%eax),%edx
f0101235:	89 50 40             	mov    %edx,0x40(%eax)
//	panic("here");
	
}
f0101238:	83 c4 10             	add    $0x10,%esp
f010123b:	5b                   	pop    %ebx
f010123c:	5e                   	pop    %esi
f010123d:	5d                   	pop    %ebp
f010123e:	c3                   	ret    

f010123f <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f010123f:	55                   	push   %ebp
f0101240:	89 e5                	mov    %esp,%ebp
f0101242:	53                   	push   %ebx
f0101243:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(!page_free_list)
f0101246:	8b 1d 40 72 22 f0    	mov    0xf0227240,%ebx
f010124c:	85 db                	test   %ebx,%ebx
f010124e:	74 6b                	je     f01012bb <page_alloc+0x7c>
		return NULL;
	struct Page *alloc_page = page_free_list;
	page_free_list = page_free_list->pp_link;
f0101250:	8b 03                	mov    (%ebx),%eax
f0101252:	a3 40 72 22 f0       	mov    %eax,0xf0227240
	alloc_page -> pp_link = NULL;
f0101257:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f010125d:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101261:	74 58                	je     f01012bb <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101263:	89 d8                	mov    %ebx,%eax
f0101265:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f010126b:	c1 f8 03             	sar    $0x3,%eax
f010126e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101271:	89 c2                	mov    %eax,%edx
f0101273:	c1 ea 0c             	shr    $0xc,%edx
f0101276:	3b 15 88 7e 22 f0    	cmp    0xf0227e88,%edx
f010127c:	72 20                	jb     f010129e <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010127e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101282:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0101289:	f0 
f010128a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101291:	00 
f0101292:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0101299:	e8 a2 ed ff ff       	call   f0100040 <_panic>
		memset(page2kva(alloc_page), 0, PGSIZE);
f010129e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012a5:	00 
f01012a6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012ad:	00 
	return (void *)(pa + KERNBASE);
f01012ae:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012b3:	89 04 24             	mov    %eax,(%esp)
f01012b6:	e8 6a 48 00 00       	call   f0105b25 <memset>
	
	return alloc_page;
}
f01012bb:	89 d8                	mov    %ebx,%eax
f01012bd:	83 c4 14             	add    $0x14,%esp
f01012c0:	5b                   	pop    %ebx
f01012c1:	5d                   	pop    %ebp
f01012c2:	c3                   	ret    

f01012c3 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f01012c3:	55                   	push   %ebp
f01012c4:	89 e5                	mov    %esp,%ebp
f01012c6:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if(pp -> pp_ref)	// If the ref is not 0, return
f01012c9:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01012ce:	75 0d                	jne    f01012dd <page_free+0x1a>
		return;
	pp->pp_link = page_free_list;
f01012d0:	8b 15 40 72 22 f0    	mov    0xf0227240,%edx
f01012d6:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01012d8:	a3 40 72 22 f0       	mov    %eax,0xf0227240
}
f01012dd:	5d                   	pop    %ebp
f01012de:	c3                   	ret    

f01012df <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f01012df:	55                   	push   %ebp
f01012e0:	89 e5                	mov    %esp,%ebp
f01012e2:	83 ec 04             	sub    $0x4,%esp
f01012e5:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01012e8:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f01012ec:	83 ea 01             	sub    $0x1,%edx
f01012ef:	66 89 50 04          	mov    %dx,0x4(%eax)
f01012f3:	66 85 d2             	test   %dx,%dx
f01012f6:	75 08                	jne    f0101300 <page_decref+0x21>
		page_free(pp);
f01012f8:	89 04 24             	mov    %eax,(%esp)
f01012fb:	e8 c3 ff ff ff       	call   f01012c3 <page_free>
}
f0101300:	c9                   	leave  
f0101301:	c3                   	ret    

f0101302 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{/* see the check_va2pa() */
f0101302:	55                   	push   %ebp
f0101303:	89 e5                	mov    %esp,%ebp
f0101305:	56                   	push   %esi
f0101306:	53                   	push   %ebx
f0101307:	83 ec 10             	sub    $0x10,%esp
f010130a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/* va is a linear address */
	pde_t *ptdir = pgdir + PDX(va);
f010130d:	89 de                	mov    %ebx,%esi
f010130f:	c1 ee 16             	shr    $0x16,%esi
f0101312:	c1 e6 02             	shl    $0x2,%esi
f0101315:	03 75 08             	add    0x8(%ebp),%esi
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
f0101318:	8b 06                	mov    (%esi),%eax
f010131a:	a8 01                	test   $0x1,%al
f010131c:	74 44                	je     f0101362 <pgdir_walk+0x60>
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f010131e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101323:	89 c2                	mov    %eax,%edx
f0101325:	c1 ea 0c             	shr    $0xc,%edx
f0101328:	3b 15 88 7e 22 f0    	cmp    0xf0227e88,%edx
f010132e:	72 20                	jb     f0101350 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101330:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101334:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f010133b:	f0 
f010133c:	c7 44 24 04 bc 01 00 	movl   $0x1bc,0x4(%esp)
f0101343:	00 
f0101344:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010134b:	e8 f0 ec ff ff       	call   f0100040 <_panic>
f0101350:	c1 eb 0a             	shr    $0xa,%ebx
f0101353:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101359:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0101360:	eb 7c                	jmp    f01013de <pgdir_walk+0xdc>
	if(!create)
f0101362:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101366:	74 6a                	je     f01013d2 <pgdir_walk+0xd0>
		return NULL;
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
f0101368:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010136f:	e8 cb fe ff ff       	call   f010123f <page_alloc>
	if(!page_create)
f0101374:	85 c0                	test   %eax,%eax
f0101376:	74 61                	je     f01013d9 <pgdir_walk+0xd7>
		return NULL; /* allocation fails */
	page_create -> pp_ref++; /* reference count increase */
f0101378:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010137d:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f0101383:	c1 f8 03             	sar    $0x3,%eax
f0101386:	c1 e0 0c             	shl    $0xc,%eax
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
f0101389:	83 c8 07             	or     $0x7,%eax
f010138c:	89 06                	mov    %eax,(%esi)
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f010138e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101393:	89 c2                	mov    %eax,%edx
f0101395:	c1 ea 0c             	shr    $0xc,%edx
f0101398:	3b 15 88 7e 22 f0    	cmp    0xf0227e88,%edx
f010139e:	72 20                	jb     f01013c0 <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013a0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013a4:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f01013ab:	f0 
f01013ac:	c7 44 24 04 c4 01 00 	movl   $0x1c4,0x4(%esp)
f01013b3:	00 
f01013b4:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01013bb:	e8 80 ec ff ff       	call   f0100040 <_panic>
f01013c0:	c1 eb 0a             	shr    $0xa,%ebx
f01013c3:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f01013c9:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f01013d0:	eb 0c                	jmp    f01013de <pgdir_walk+0xdc>
	pde_t *ptdir = pgdir + PDX(va);
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
	if(!create)
		return NULL;
f01013d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01013d7:	eb 05                	jmp    f01013de <pgdir_walk+0xdc>
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
	if(!page_create)
		return NULL; /* allocation fails */
f01013d9:	b8 00 00 00 00       	mov    $0x0,%eax
	page_create -> pp_ref++; /* reference count increase */
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
}
f01013de:	83 c4 10             	add    $0x10,%esp
f01013e1:	5b                   	pop    %ebx
f01013e2:	5e                   	pop    %esi
f01013e3:	5d                   	pop    %ebp
f01013e4:	c3                   	ret    

f01013e5 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01013e5:	55                   	push   %ebp
f01013e6:	89 e5                	mov    %esp,%ebp
f01013e8:	57                   	push   %edi
f01013e9:	56                   	push   %esi
f01013ea:	53                   	push   %ebx
f01013eb:	83 ec 2c             	sub    $0x2c,%esp
f01013ee:	89 4d dc             	mov    %ecx,-0x24(%ebp)
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f01013f1:	85 c9                	test   %ecx,%ecx
f01013f3:	74 4c                	je     f0101441 <boot_map_region+0x5c>
f01013f5:	89 c6                	mov    %eax,%esi
f01013f7:	89 d3                	mov    %edx,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01013f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01013fc:	29 d0                	sub    %edx,%eax
f01013fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
		pte_t *pte = pgdir_walk(pgdir, (const void *)va, 1);
		if(!pte)
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm|PTE_P;
f0101401:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101404:	83 c8 01             	or     $0x1,%eax
f0101407:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010140a:	89 55 d8             	mov    %edx,-0x28(%ebp)
f010140d:	89 f7                	mov    %esi,%edi
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f010140f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101412:	01 de                	add    %ebx,%esi
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
		pte_t *pte = pgdir_walk(pgdir, (const void *)va, 1);
f0101414:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010141b:	00 
f010141c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101420:	89 3c 24             	mov    %edi,(%esp)
f0101423:	e8 da fe ff ff       	call   f0101302 <pgdir_walk>
		if(!pte)
f0101428:	85 c0                	test   %eax,%eax
f010142a:	74 15                	je     f0101441 <boot_map_region+0x5c>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm|PTE_P;
f010142c:	0b 75 e0             	or     -0x20(%ebp),%esi
f010142f:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f0101431:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101437:	89 d8                	mov    %ebx,%eax
f0101439:	2b 45 d8             	sub    -0x28(%ebp),%eax
f010143c:	3b 45 dc             	cmp    -0x24(%ebp),%eax
f010143f:	72 ce                	jb     f010140f <boot_map_region+0x2a>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm|PTE_P;
	}
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~\n");
}
f0101441:	83 c4 2c             	add    $0x2c,%esp
f0101444:	5b                   	pop    %ebx
f0101445:	5e                   	pop    %esi
f0101446:	5f                   	pop    %edi
f0101447:	5d                   	pop    %ebp
f0101448:	c3                   	ret    

f0101449 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101449:	55                   	push   %ebp
f010144a:	89 e5                	mov    %esp,%ebp
f010144c:	53                   	push   %ebx
f010144d:	83 ec 14             	sub    $0x14,%esp
f0101450:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101453:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010145a:	00 
f010145b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010145e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101462:	8b 45 08             	mov    0x8(%ebp),%eax
f0101465:	89 04 24             	mov    %eax,(%esp)
f0101468:	e8 95 fe ff ff       	call   f0101302 <pgdir_walk>
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
f010146d:	85 c0                	test   %eax,%eax
f010146f:	74 3f                	je     f01014b0 <page_lookup+0x67>
f0101471:	f6 00 01             	testb  $0x1,(%eax)
f0101474:	74 41                	je     f01014b7 <page_lookup+0x6e>
		return NULL;
	if(pte_store)
f0101476:	85 db                	test   %ebx,%ebx
f0101478:	74 02                	je     f010147c <page_lookup+0x33>
		*pte_store = pte;
f010147a:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f010147c:	8b 00                	mov    (%eax),%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010147e:	c1 e8 0c             	shr    $0xc,%eax
f0101481:	3b 05 88 7e 22 f0    	cmp    0xf0227e88,%eax
f0101487:	72 1c                	jb     f01014a5 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f0101489:	c7 44 24 08 a0 6f 10 	movl   $0xf0106fa0,0x8(%esp)
f0101490:	f0 
f0101491:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0101498:	00 
f0101499:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f01014a0:	e8 9b eb ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01014a5:	8b 15 90 7e 22 f0    	mov    0xf0227e90,%edx
f01014ab:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01014ae:	eb 0c                	jmp    f01014bc <page_lookup+0x73>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
		return NULL;
f01014b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01014b5:	eb 05                	jmp    f01014bc <page_lookup+0x73>
f01014b7:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f01014bc:	83 c4 14             	add    $0x14,%esp
f01014bf:	5b                   	pop    %ebx
f01014c0:	5d                   	pop    %ebp
f01014c1:	c3                   	ret    

f01014c2 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01014c2:	55                   	push   %ebp
f01014c3:	89 e5                	mov    %esp,%ebp
f01014c5:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01014c8:	e8 ff 4c 00 00       	call   f01061cc <cpunum>
f01014cd:	6b c0 74             	imul   $0x74,%eax,%eax
f01014d0:	83 b8 28 80 22 f0 00 	cmpl   $0x0,-0xfdd7fd8(%eax)
f01014d7:	74 16                	je     f01014ef <tlb_invalidate+0x2d>
f01014d9:	e8 ee 4c 00 00       	call   f01061cc <cpunum>
f01014de:	6b c0 74             	imul   $0x74,%eax,%eax
f01014e1:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01014e7:	8b 55 08             	mov    0x8(%ebp),%edx
f01014ea:	39 50 60             	cmp    %edx,0x60(%eax)
f01014ed:	75 06                	jne    f01014f5 <tlb_invalidate+0x33>
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01014ef:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014f2:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01014f5:	c9                   	leave  
f01014f6:	c3                   	ret    

f01014f7 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01014f7:	55                   	push   %ebp
f01014f8:	89 e5                	mov    %esp,%ebp
f01014fa:	83 ec 28             	sub    $0x28,%esp
f01014fd:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101500:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101503:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101506:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct Page *pp = page_lookup(pgdir, va, &pte);
f0101509:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010150c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101510:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101514:	89 1c 24             	mov    %ebx,(%esp)
f0101517:	e8 2d ff ff ff       	call   f0101449 <page_lookup>
	if(!pp)
f010151c:	85 c0                	test   %eax,%eax
f010151e:	74 1d                	je     f010153d <page_remove+0x46>
		return;
	page_decref(pp);
f0101520:	89 04 24             	mov    %eax,(%esp)
f0101523:	e8 b7 fd ff ff       	call   f01012df <page_decref>
	*pte = 0;
f0101528:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010152b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f0101531:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101535:	89 1c 24             	mov    %ebx,(%esp)
f0101538:	e8 85 ff ff ff       	call   f01014c2 <tlb_invalidate>
	
}
f010153d:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101540:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101543:	89 ec                	mov    %ebp,%esp
f0101545:	5d                   	pop    %ebp
f0101546:	c3                   	ret    

f0101547 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101547:	55                   	push   %ebp
f0101548:	89 e5                	mov    %esp,%ebp
f010154a:	83 ec 28             	sub    $0x28,%esp
f010154d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101550:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101553:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101556:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101559:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f010155c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101563:	00 
f0101564:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101568:	8b 45 08             	mov    0x8(%ebp),%eax
f010156b:	89 04 24             	mov    %eax,(%esp)
f010156e:	e8 8f fd ff ff       	call   f0101302 <pgdir_walk>
f0101573:	89 c6                	mov    %eax,%esi
	if(!pte)
f0101575:	85 c0                	test   %eax,%eax
f0101577:	74 66                	je     f01015df <page_insert+0x98>
		return -E_NO_MEM;
	if(*pte & PTE_P) { /* already a page */
f0101579:	8b 00                	mov    (%eax),%eax
f010157b:	a8 01                	test   $0x1,%al
f010157d:	74 3c                	je     f01015bb <page_insert+0x74>
		if(PTE_ADDR(*pte) == page2pa(pp)){	/* the same one */
f010157f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101584:	89 da                	mov    %ebx,%edx
f0101586:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
f010158c:	c1 fa 03             	sar    $0x3,%edx
f010158f:	c1 e2 0c             	shl    $0xc,%edx
f0101592:	39 d0                	cmp    %edx,%eax
f0101594:	75 16                	jne    f01015ac <page_insert+0x65>
			tlb_invalidate(pgdir, va);
f0101596:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010159a:	8b 45 08             	mov    0x8(%ebp),%eax
f010159d:	89 04 24             	mov    %eax,(%esp)
f01015a0:	e8 1d ff ff ff       	call   f01014c2 <tlb_invalidate>
			pp -> pp_ref--;
f01015a5:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f01015aa:	eb 0f                	jmp    f01015bb <page_insert+0x74>
		}else
			page_remove(pgdir, va);
f01015ac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01015b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015b3:	89 04 24             	mov    %eax,(%esp)
f01015b6:	e8 3c ff ff ff       	call   f01014f7 <page_remove>
	}
	*pte = page2pa(pp)|perm|PTE_P;
f01015bb:	8b 55 14             	mov    0x14(%ebp),%edx
f01015be:	83 ca 01             	or     $0x1,%edx
f01015c1:	89 d8                	mov    %ebx,%eax
f01015c3:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f01015c9:	c1 f8 03             	sar    $0x3,%eax
f01015cc:	c1 e0 0c             	shl    $0xc,%eax
f01015cf:	09 d0                	or     %edx,%eax
f01015d1:	89 06                	mov    %eax,(%esi)
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
f01015d3:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f01015d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01015dd:	eb 05                	jmp    f01015e4 <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
	if(!pte)
		return -E_NO_MEM;
f01015df:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*pte = page2pa(pp)|perm|PTE_P;
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
	return 0;
}
f01015e4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01015e7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01015ea:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01015ed:	89 ec                	mov    %ebp,%esp
f01015ef:	5d                   	pop    %ebp
f01015f0:	c3                   	ret    

f01015f1 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01015f1:	55                   	push   %ebp
f01015f2:	89 e5                	mov    %esp,%ebp
f01015f4:	57                   	push   %edi
f01015f5:	56                   	push   %esi
f01015f6:	53                   	push   %ebx
f01015f7:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01015fa:	b8 15 00 00 00       	mov    $0x15,%eax
f01015ff:	e8 4e f7 ff ff       	call   f0100d52 <nvram_read>
f0101604:	c1 e0 0a             	shl    $0xa,%eax
f0101607:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010160d:	85 c0                	test   %eax,%eax
f010160f:	0f 48 c2             	cmovs  %edx,%eax
f0101612:	c1 f8 0c             	sar    $0xc,%eax
f0101615:	a3 38 72 22 f0       	mov    %eax,0xf0227238
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010161a:	b8 17 00 00 00       	mov    $0x17,%eax
f010161f:	e8 2e f7 ff ff       	call   f0100d52 <nvram_read>
f0101624:	c1 e0 0a             	shl    $0xa,%eax
f0101627:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010162d:	85 c0                	test   %eax,%eax
f010162f:	0f 48 c2             	cmovs  %edx,%eax
f0101632:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101635:	85 c0                	test   %eax,%eax
f0101637:	74 0e                	je     f0101647 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101639:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010163f:	89 15 88 7e 22 f0    	mov    %edx,0xf0227e88
f0101645:	eb 0c                	jmp    f0101653 <mem_init+0x62>
	else
		npages = npages_basemem;
f0101647:	8b 15 38 72 22 f0    	mov    0xf0227238,%edx
f010164d:	89 15 88 7e 22 f0    	mov    %edx,0xf0227e88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101653:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101656:	c1 e8 0a             	shr    $0xa,%eax
f0101659:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010165d:	a1 38 72 22 f0       	mov    0xf0227238,%eax
f0101662:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101665:	c1 e8 0a             	shr    $0xa,%eax
f0101668:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010166c:	a1 88 7e 22 f0       	mov    0xf0227e88,%eax
f0101671:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101674:	c1 e8 0a             	shr    $0xa,%eax
f0101677:	89 44 24 04          	mov    %eax,0x4(%esp)
f010167b:	c7 04 24 c0 6f 10 f0 	movl   $0xf0106fc0,(%esp)
f0101682:	e8 37 27 00 00       	call   f0103dbe <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101687:	b8 00 10 00 00       	mov    $0x1000,%eax
f010168c:	e8 4e f6 ff ff       	call   f0100cdf <boot_alloc>
f0101691:	a3 8c 7e 22 f0       	mov    %eax,0xf0227e8c
	memset(kern_pgdir, 0, PGSIZE);
f0101696:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010169d:	00 
f010169e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01016a5:	00 
f01016a6:	89 04 24             	mov    %eax,(%esp)
f01016a9:	e8 77 44 00 00       	call   f0105b25 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01016ae:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01016b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01016b8:	77 20                	ja     f01016da <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01016ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016be:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f01016c5:	f0 
f01016c6:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
f01016cd:	00 
f01016ce:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01016d5:	e8 66 e9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01016da:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01016e0:	83 ca 05             	or     $0x5,%edx
f01016e3:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page *)boot_alloc(npages * sizeof(struct Page));
f01016e9:	a1 88 7e 22 f0       	mov    0xf0227e88,%eax
f01016ee:	c1 e0 03             	shl    $0x3,%eax
f01016f1:	e8 e9 f5 ff ff       	call   f0100cdf <boot_alloc>
f01016f6:	a3 90 7e 22 f0       	mov    %eax,0xf0227e90
		
//panic("PDX(0)");
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f01016fb:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101700:	e8 da f5 ff ff       	call   f0100cdf <boot_alloc>
f0101705:	a3 48 72 22 f0       	mov    %eax,0xf0227248
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010170a:	e8 4f fa ff ff       	call   f010115e <page_init>

	check_page_free_list(1);
f010170f:	b8 01 00 00 00       	mov    $0x1,%eax
f0101714:	e8 6b f6 ff ff       	call   f0100d84 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101719:	83 3d 90 7e 22 f0 00 	cmpl   $0x0,0xf0227e90
f0101720:	75 1c                	jne    f010173e <mem_init+0x14d>
		panic("'pages' is a null pointer!");
f0101722:	c7 44 24 08 c1 76 10 	movl   $0xf01076c1,0x8(%esp)
f0101729:	f0 
f010172a:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f0101731:	00 
f0101732:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101739:	e8 02 e9 ff ff       	call   f0100040 <_panic>
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010173e:	a1 40 72 22 f0       	mov    0xf0227240,%eax
f0101743:	85 c0                	test   %eax,%eax
f0101745:	74 10                	je     f0101757 <mem_init+0x166>
f0101747:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f010174c:	83 c3 01             	add    $0x1,%ebx
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010174f:	8b 00                	mov    (%eax),%eax
f0101751:	85 c0                	test   %eax,%eax
f0101753:	75 f7                	jne    f010174c <mem_init+0x15b>
f0101755:	eb 05                	jmp    f010175c <mem_init+0x16b>
f0101757:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010175c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101763:	e8 d7 fa ff ff       	call   f010123f <page_alloc>
f0101768:	89 c7                	mov    %eax,%edi
f010176a:	85 c0                	test   %eax,%eax
f010176c:	75 24                	jne    f0101792 <mem_init+0x1a1>
f010176e:	c7 44 24 0c dc 76 10 	movl   $0xf01076dc,0xc(%esp)
f0101775:	f0 
f0101776:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010177d:	f0 
f010177e:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0101785:	00 
f0101786:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010178d:	e8 ae e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101792:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101799:	e8 a1 fa ff ff       	call   f010123f <page_alloc>
f010179e:	89 c6                	mov    %eax,%esi
f01017a0:	85 c0                	test   %eax,%eax
f01017a2:	75 24                	jne    f01017c8 <mem_init+0x1d7>
f01017a4:	c7 44 24 0c f2 76 10 	movl   $0xf01076f2,0xc(%esp)
f01017ab:	f0 
f01017ac:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01017b3:	f0 
f01017b4:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f01017bb:	00 
f01017bc:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01017c3:	e8 78 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017cf:	e8 6b fa ff ff       	call   f010123f <page_alloc>
f01017d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017d7:	85 c0                	test   %eax,%eax
f01017d9:	75 24                	jne    f01017ff <mem_init+0x20e>
f01017db:	c7 44 24 0c 08 77 10 	movl   $0xf0107708,0xc(%esp)
f01017e2:	f0 
f01017e3:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01017ea:	f0 
f01017eb:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f01017f2:	00 
f01017f3:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01017fa:	e8 41 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017ff:	39 f7                	cmp    %esi,%edi
f0101801:	75 24                	jne    f0101827 <mem_init+0x236>
f0101803:	c7 44 24 0c 1e 77 10 	movl   $0xf010771e,0xc(%esp)
f010180a:	f0 
f010180b:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101812:	f0 
f0101813:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f010181a:	00 
f010181b:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101822:	e8 19 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101827:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010182a:	74 05                	je     f0101831 <mem_init+0x240>
f010182c:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010182f:	75 24                	jne    f0101855 <mem_init+0x264>
f0101831:	c7 44 24 0c fc 6f 10 	movl   $0xf0106ffc,0xc(%esp)
f0101838:	f0 
f0101839:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101840:	f0 
f0101841:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
f0101848:	00 
f0101849:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101850:	e8 eb e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101855:	8b 15 90 7e 22 f0    	mov    0xf0227e90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010185b:	a1 88 7e 22 f0       	mov    0xf0227e88,%eax
f0101860:	c1 e0 0c             	shl    $0xc,%eax
f0101863:	89 f9                	mov    %edi,%ecx
f0101865:	29 d1                	sub    %edx,%ecx
f0101867:	c1 f9 03             	sar    $0x3,%ecx
f010186a:	c1 e1 0c             	shl    $0xc,%ecx
f010186d:	39 c1                	cmp    %eax,%ecx
f010186f:	72 24                	jb     f0101895 <mem_init+0x2a4>
f0101871:	c7 44 24 0c 30 77 10 	movl   $0xf0107730,0xc(%esp)
f0101878:	f0 
f0101879:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101880:	f0 
f0101881:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f0101888:	00 
f0101889:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101890:	e8 ab e7 ff ff       	call   f0100040 <_panic>
f0101895:	89 f1                	mov    %esi,%ecx
f0101897:	29 d1                	sub    %edx,%ecx
f0101899:	c1 f9 03             	sar    $0x3,%ecx
f010189c:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010189f:	39 c8                	cmp    %ecx,%eax
f01018a1:	77 24                	ja     f01018c7 <mem_init+0x2d6>
f01018a3:	c7 44 24 0c 4d 77 10 	movl   $0xf010774d,0xc(%esp)
f01018aa:	f0 
f01018ab:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01018b2:	f0 
f01018b3:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
f01018ba:	00 
f01018bb:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01018c2:	e8 79 e7 ff ff       	call   f0100040 <_panic>
f01018c7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01018ca:	29 d1                	sub    %edx,%ecx
f01018cc:	89 ca                	mov    %ecx,%edx
f01018ce:	c1 fa 03             	sar    $0x3,%edx
f01018d1:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01018d4:	39 d0                	cmp    %edx,%eax
f01018d6:	77 24                	ja     f01018fc <mem_init+0x30b>
f01018d8:	c7 44 24 0c 6a 77 10 	movl   $0xf010776a,0xc(%esp)
f01018df:	f0 
f01018e0:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01018e7:	f0 
f01018e8:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f01018ef:	00 
f01018f0:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01018f7:	e8 44 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018fc:	a1 40 72 22 f0       	mov    0xf0227240,%eax
f0101901:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101904:	c7 05 40 72 22 f0 00 	movl   $0x0,0xf0227240
f010190b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010190e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101915:	e8 25 f9 ff ff       	call   f010123f <page_alloc>
f010191a:	85 c0                	test   %eax,%eax
f010191c:	74 24                	je     f0101942 <mem_init+0x351>
f010191e:	c7 44 24 0c 87 77 10 	movl   $0xf0107787,0xc(%esp)
f0101925:	f0 
f0101926:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010192d:	f0 
f010192e:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0101935:	00 
f0101936:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010193d:	e8 fe e6 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101942:	89 3c 24             	mov    %edi,(%esp)
f0101945:	e8 79 f9 ff ff       	call   f01012c3 <page_free>
	page_free(pp1);
f010194a:	89 34 24             	mov    %esi,(%esp)
f010194d:	e8 71 f9 ff ff       	call   f01012c3 <page_free>
	page_free(pp2);
f0101952:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101955:	89 04 24             	mov    %eax,(%esp)
f0101958:	e8 66 f9 ff ff       	call   f01012c3 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010195d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101964:	e8 d6 f8 ff ff       	call   f010123f <page_alloc>
f0101969:	89 c6                	mov    %eax,%esi
f010196b:	85 c0                	test   %eax,%eax
f010196d:	75 24                	jne    f0101993 <mem_init+0x3a2>
f010196f:	c7 44 24 0c dc 76 10 	movl   $0xf01076dc,0xc(%esp)
f0101976:	f0 
f0101977:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010197e:	f0 
f010197f:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0101986:	00 
f0101987:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010198e:	e8 ad e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101993:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010199a:	e8 a0 f8 ff ff       	call   f010123f <page_alloc>
f010199f:	89 c7                	mov    %eax,%edi
f01019a1:	85 c0                	test   %eax,%eax
f01019a3:	75 24                	jne    f01019c9 <mem_init+0x3d8>
f01019a5:	c7 44 24 0c f2 76 10 	movl   $0xf01076f2,0xc(%esp)
f01019ac:	f0 
f01019ad:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01019b4:	f0 
f01019b5:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f01019bc:	00 
f01019bd:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01019c4:	e8 77 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01019c9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019d0:	e8 6a f8 ff ff       	call   f010123f <page_alloc>
f01019d5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019d8:	85 c0                	test   %eax,%eax
f01019da:	75 24                	jne    f0101a00 <mem_init+0x40f>
f01019dc:	c7 44 24 0c 08 77 10 	movl   $0xf0107708,0xc(%esp)
f01019e3:	f0 
f01019e4:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01019eb:	f0 
f01019ec:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f01019f3:	00 
f01019f4:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01019fb:	e8 40 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a00:	39 fe                	cmp    %edi,%esi
f0101a02:	75 24                	jne    f0101a28 <mem_init+0x437>
f0101a04:	c7 44 24 0c 1e 77 10 	movl   $0xf010771e,0xc(%esp)
f0101a0b:	f0 
f0101a0c:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101a13:	f0 
f0101a14:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0101a1b:	00 
f0101a1c:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101a23:	e8 18 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a28:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101a2b:	74 05                	je     f0101a32 <mem_init+0x441>
f0101a2d:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101a30:	75 24                	jne    f0101a56 <mem_init+0x465>
f0101a32:	c7 44 24 0c fc 6f 10 	movl   $0xf0106ffc,0xc(%esp)
f0101a39:	f0 
f0101a3a:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101a41:	f0 
f0101a42:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0101a49:	00 
f0101a4a:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101a51:	e8 ea e5 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101a56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a5d:	e8 dd f7 ff ff       	call   f010123f <page_alloc>
f0101a62:	85 c0                	test   %eax,%eax
f0101a64:	74 24                	je     f0101a8a <mem_init+0x499>
f0101a66:	c7 44 24 0c 87 77 10 	movl   $0xf0107787,0xc(%esp)
f0101a6d:	f0 
f0101a6e:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101a75:	f0 
f0101a76:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f0101a7d:	00 
f0101a7e:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101a85:	e8 b6 e5 ff ff       	call   f0100040 <_panic>
f0101a8a:	89 f0                	mov    %esi,%eax
f0101a8c:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f0101a92:	c1 f8 03             	sar    $0x3,%eax
f0101a95:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a98:	89 c2                	mov    %eax,%edx
f0101a9a:	c1 ea 0c             	shr    $0xc,%edx
f0101a9d:	3b 15 88 7e 22 f0    	cmp    0xf0227e88,%edx
f0101aa3:	72 20                	jb     f0101ac5 <mem_init+0x4d4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101aa5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101aa9:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0101ab0:	f0 
f0101ab1:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101ab8:	00 
f0101ab9:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0101ac0:	e8 7b e5 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101ac5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101acc:	00 
f0101acd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101ad4:	00 
	return (void *)(pa + KERNBASE);
f0101ad5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ada:	89 04 24             	mov    %eax,(%esp)
f0101add:	e8 43 40 00 00       	call   f0105b25 <memset>
	page_free(pp0);
f0101ae2:	89 34 24             	mov    %esi,(%esp)
f0101ae5:	e8 d9 f7 ff ff       	call   f01012c3 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101aea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101af1:	e8 49 f7 ff ff       	call   f010123f <page_alloc>
f0101af6:	85 c0                	test   %eax,%eax
f0101af8:	75 24                	jne    f0101b1e <mem_init+0x52d>
f0101afa:	c7 44 24 0c 96 77 10 	movl   $0xf0107796,0xc(%esp)
f0101b01:	f0 
f0101b02:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101b09:	f0 
f0101b0a:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0101b11:	00 
f0101b12:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101b19:	e8 22 e5 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101b1e:	39 c6                	cmp    %eax,%esi
f0101b20:	74 24                	je     f0101b46 <mem_init+0x555>
f0101b22:	c7 44 24 0c b4 77 10 	movl   $0xf01077b4,0xc(%esp)
f0101b29:	f0 
f0101b2a:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101b31:	f0 
f0101b32:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f0101b39:	00 
f0101b3a:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101b41:	e8 fa e4 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b46:	89 f2                	mov    %esi,%edx
f0101b48:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
f0101b4e:	c1 fa 03             	sar    $0x3,%edx
f0101b51:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b54:	89 d0                	mov    %edx,%eax
f0101b56:	c1 e8 0c             	shr    $0xc,%eax
f0101b59:	3b 05 88 7e 22 f0    	cmp    0xf0227e88,%eax
f0101b5f:	72 20                	jb     f0101b81 <mem_init+0x590>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b61:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b65:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0101b6c:	f0 
f0101b6d:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101b74:	00 
f0101b75:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0101b7c:	e8 bf e4 ff ff       	call   f0100040 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101b81:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101b88:	75 11                	jne    f0101b9b <mem_init+0x5aa>
f0101b8a:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101b90:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101b96:	80 38 00             	cmpb   $0x0,(%eax)
f0101b99:	74 24                	je     f0101bbf <mem_init+0x5ce>
f0101b9b:	c7 44 24 0c c4 77 10 	movl   $0xf01077c4,0xc(%esp)
f0101ba2:	f0 
f0101ba3:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101baa:	f0 
f0101bab:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101bb2:	00 
f0101bb3:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101bba:	e8 81 e4 ff ff       	call   f0100040 <_panic>
f0101bbf:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101bc2:	39 d0                	cmp    %edx,%eax
f0101bc4:	75 d0                	jne    f0101b96 <mem_init+0x5a5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101bc6:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101bc9:	89 15 40 72 22 f0    	mov    %edx,0xf0227240

	// free the pages we took
	page_free(pp0);
f0101bcf:	89 34 24             	mov    %esi,(%esp)
f0101bd2:	e8 ec f6 ff ff       	call   f01012c3 <page_free>
	page_free(pp1);
f0101bd7:	89 3c 24             	mov    %edi,(%esp)
f0101bda:	e8 e4 f6 ff ff       	call   f01012c3 <page_free>
	page_free(pp2);
f0101bdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101be2:	89 04 24             	mov    %eax,(%esp)
f0101be5:	e8 d9 f6 ff ff       	call   f01012c3 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101bea:	a1 40 72 22 f0       	mov    0xf0227240,%eax
f0101bef:	85 c0                	test   %eax,%eax
f0101bf1:	74 09                	je     f0101bfc <mem_init+0x60b>
		--nfree;
f0101bf3:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101bf6:	8b 00                	mov    (%eax),%eax
f0101bf8:	85 c0                	test   %eax,%eax
f0101bfa:	75 f7                	jne    f0101bf3 <mem_init+0x602>
		--nfree;
	assert(nfree == 0);
f0101bfc:	85 db                	test   %ebx,%ebx
f0101bfe:	74 24                	je     f0101c24 <mem_init+0x633>
f0101c00:	c7 44 24 0c ce 77 10 	movl   $0xf01077ce,0xc(%esp)
f0101c07:	f0 
f0101c08:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101c0f:	f0 
f0101c10:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101c17:	00 
f0101c18:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101c1f:	e8 1c e4 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101c24:	c7 04 24 1c 70 10 f0 	movl   $0xf010701c,(%esp)
f0101c2b:	e8 8e 21 00 00       	call   f0103dbe <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101c30:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c37:	e8 03 f6 ff ff       	call   f010123f <page_alloc>
f0101c3c:	89 c3                	mov    %eax,%ebx
f0101c3e:	85 c0                	test   %eax,%eax
f0101c40:	75 24                	jne    f0101c66 <mem_init+0x675>
f0101c42:	c7 44 24 0c dc 76 10 	movl   $0xf01076dc,0xc(%esp)
f0101c49:	f0 
f0101c4a:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101c51:	f0 
f0101c52:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0101c59:	00 
f0101c5a:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101c61:	e8 da e3 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c66:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c6d:	e8 cd f5 ff ff       	call   f010123f <page_alloc>
f0101c72:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c75:	85 c0                	test   %eax,%eax
f0101c77:	75 24                	jne    f0101c9d <mem_init+0x6ac>
f0101c79:	c7 44 24 0c f2 76 10 	movl   $0xf01076f2,0xc(%esp)
f0101c80:	f0 
f0101c81:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101c88:	f0 
f0101c89:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0101c90:	00 
f0101c91:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101c98:	e8 a3 e3 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c9d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ca4:	e8 96 f5 ff ff       	call   f010123f <page_alloc>
f0101ca9:	89 c6                	mov    %eax,%esi
f0101cab:	85 c0                	test   %eax,%eax
f0101cad:	75 24                	jne    f0101cd3 <mem_init+0x6e2>
f0101caf:	c7 44 24 0c 08 77 10 	movl   $0xf0107708,0xc(%esp)
f0101cb6:	f0 
f0101cb7:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101cbe:	f0 
f0101cbf:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f0101cc6:	00 
f0101cc7:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101cce:	e8 6d e3 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101cd3:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101cd6:	75 24                	jne    f0101cfc <mem_init+0x70b>
f0101cd8:	c7 44 24 0c 1e 77 10 	movl   $0xf010771e,0xc(%esp)
f0101cdf:	f0 
f0101ce0:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101ce7:	f0 
f0101ce8:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101cef:	00 
f0101cf0:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101cf7:	e8 44 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101cfc:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101cff:	74 04                	je     f0101d05 <mem_init+0x714>
f0101d01:	39 c3                	cmp    %eax,%ebx
f0101d03:	75 24                	jne    f0101d29 <mem_init+0x738>
f0101d05:	c7 44 24 0c fc 6f 10 	movl   $0xf0106ffc,0xc(%esp)
f0101d0c:	f0 
f0101d0d:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101d14:	f0 
f0101d15:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0101d1c:	00 
f0101d1d:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101d24:	e8 17 e3 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101d29:	8b 3d 40 72 22 f0    	mov    0xf0227240,%edi
f0101d2f:	89 7d c8             	mov    %edi,-0x38(%ebp)
	page_free_list = 0;
f0101d32:	c7 05 40 72 22 f0 00 	movl   $0x0,0xf0227240
f0101d39:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101d3c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d43:	e8 f7 f4 ff ff       	call   f010123f <page_alloc>
f0101d48:	85 c0                	test   %eax,%eax
f0101d4a:	74 24                	je     f0101d70 <mem_init+0x77f>
f0101d4c:	c7 44 24 0c 87 77 10 	movl   $0xf0107787,0xc(%esp)
f0101d53:	f0 
f0101d54:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101d5b:	f0 
f0101d5c:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0101d63:	00 
f0101d64:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101d6b:	e8 d0 e2 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101d70:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101d73:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d77:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101d7e:	00 
f0101d7f:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0101d84:	89 04 24             	mov    %eax,(%esp)
f0101d87:	e8 bd f6 ff ff       	call   f0101449 <page_lookup>
f0101d8c:	85 c0                	test   %eax,%eax
f0101d8e:	74 24                	je     f0101db4 <mem_init+0x7c3>
f0101d90:	c7 44 24 0c 3c 70 10 	movl   $0xf010703c,0xc(%esp)
f0101d97:	f0 
f0101d98:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101d9f:	f0 
f0101da0:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0101da7:	00 
f0101da8:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101daf:	e8 8c e2 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101db4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101dbb:	00 
f0101dbc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dc3:	00 
f0101dc4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dc7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101dcb:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0101dd0:	89 04 24             	mov    %eax,(%esp)
f0101dd3:	e8 6f f7 ff ff       	call   f0101547 <page_insert>
f0101dd8:	85 c0                	test   %eax,%eax
f0101dda:	78 24                	js     f0101e00 <mem_init+0x80f>
f0101ddc:	c7 44 24 0c 74 70 10 	movl   $0xf0107074,0xc(%esp)
f0101de3:	f0 
f0101de4:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101deb:	f0 
f0101dec:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0101df3:	00 
f0101df4:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101dfb:	e8 40 e2 ff ff       	call   f0100040 <_panic>
//panic("\n");
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101e00:	89 1c 24             	mov    %ebx,(%esp)
f0101e03:	e8 bb f4 ff ff       	call   f01012c3 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101e08:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e0f:	00 
f0101e10:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e17:	00 
f0101e18:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e1b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e1f:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0101e24:	89 04 24             	mov    %eax,(%esp)
f0101e27:	e8 1b f7 ff ff       	call   f0101547 <page_insert>
f0101e2c:	85 c0                	test   %eax,%eax
f0101e2e:	74 24                	je     f0101e54 <mem_init+0x863>
f0101e30:	c7 44 24 0c a4 70 10 	movl   $0xf01070a4,0xc(%esp)
f0101e37:	f0 
f0101e38:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101e3f:	f0 
f0101e40:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0101e47:	00 
f0101e48:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101e4f:	e8 ec e1 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e54:	8b 3d 8c 7e 22 f0    	mov    0xf0227e8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e5a:	8b 15 90 7e 22 f0    	mov    0xf0227e90,%edx
f0101e60:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101e63:	8b 17                	mov    (%edi),%edx
f0101e65:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e6b:	89 d8                	mov    %ebx,%eax
f0101e6d:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101e70:	c1 f8 03             	sar    $0x3,%eax
f0101e73:	c1 e0 0c             	shl    $0xc,%eax
f0101e76:	39 c2                	cmp    %eax,%edx
f0101e78:	74 24                	je     f0101e9e <mem_init+0x8ad>
f0101e7a:	c7 44 24 0c d4 70 10 	movl   $0xf01070d4,0xc(%esp)
f0101e81:	f0 
f0101e82:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101e89:	f0 
f0101e8a:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0101e91:	00 
f0101e92:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101e99:	e8 a2 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101e9e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ea3:	89 f8                	mov    %edi,%eax
f0101ea5:	e8 c6 ed ff ff       	call   f0100c70 <check_va2pa>
f0101eaa:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101ead:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101eb0:	c1 fa 03             	sar    $0x3,%edx
f0101eb3:	c1 e2 0c             	shl    $0xc,%edx
f0101eb6:	39 d0                	cmp    %edx,%eax
f0101eb8:	74 24                	je     f0101ede <mem_init+0x8ed>
f0101eba:	c7 44 24 0c fc 70 10 	movl   $0xf01070fc,0xc(%esp)
f0101ec1:	f0 
f0101ec2:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101ec9:	f0 
f0101eca:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0101ed1:	00 
f0101ed2:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101ed9:	e8 62 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ede:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ee6:	74 24                	je     f0101f0c <mem_init+0x91b>
f0101ee8:	c7 44 24 0c d9 77 10 	movl   $0xf01077d9,0xc(%esp)
f0101eef:	f0 
f0101ef0:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101ef7:	f0 
f0101ef8:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0101eff:	00 
f0101f00:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101f07:	e8 34 e1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101f0c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f11:	74 24                	je     f0101f37 <mem_init+0x946>
f0101f13:	c7 44 24 0c ea 77 10 	movl   $0xf01077ea,0xc(%esp)
f0101f1a:	f0 
f0101f1b:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101f22:	f0 
f0101f23:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0101f2a:	00 
f0101f2b:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101f32:	e8 09 e1 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f37:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f3e:	00 
f0101f3f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f46:	00 
f0101f47:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f4b:	89 3c 24             	mov    %edi,(%esp)
f0101f4e:	e8 f4 f5 ff ff       	call   f0101547 <page_insert>
f0101f53:	85 c0                	test   %eax,%eax
f0101f55:	74 24                	je     f0101f7b <mem_init+0x98a>
f0101f57:	c7 44 24 0c 2c 71 10 	movl   $0xf010712c,0xc(%esp)
f0101f5e:	f0 
f0101f5f:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101f66:	f0 
f0101f67:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0101f6e:	00 
f0101f6f:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101f76:	e8 c5 e0 ff ff       	call   f0100040 <_panic>
	//panic("va2pa: %x,page %x", check_va2pa(kern_pgdir, PGSIZE), page2pa(pp2));
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f7b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f80:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0101f85:	e8 e6 ec ff ff       	call   f0100c70 <check_va2pa>
f0101f8a:	89 f2                	mov    %esi,%edx
f0101f8c:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
f0101f92:	c1 fa 03             	sar    $0x3,%edx
f0101f95:	c1 e2 0c             	shl    $0xc,%edx
f0101f98:	39 d0                	cmp    %edx,%eax
f0101f9a:	74 24                	je     f0101fc0 <mem_init+0x9cf>
f0101f9c:	c7 44 24 0c 68 71 10 	movl   $0xf0107168,0xc(%esp)
f0101fa3:	f0 
f0101fa4:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101fab:	f0 
f0101fac:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0101fb3:	00 
f0101fb4:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101fbb:	e8 80 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101fc0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fc5:	74 24                	je     f0101feb <mem_init+0x9fa>
f0101fc7:	c7 44 24 0c fb 77 10 	movl   $0xf01077fb,0xc(%esp)
f0101fce:	f0 
f0101fcf:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0101fd6:	f0 
f0101fd7:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0101fde:	00 
f0101fdf:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0101fe6:	e8 55 e0 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101feb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ff2:	e8 48 f2 ff ff       	call   f010123f <page_alloc>
f0101ff7:	85 c0                	test   %eax,%eax
f0101ff9:	74 24                	je     f010201f <mem_init+0xa2e>
f0101ffb:	c7 44 24 0c 87 77 10 	movl   $0xf0107787,0xc(%esp)
f0102002:	f0 
f0102003:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010200a:	f0 
f010200b:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102012:	00 
f0102013:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010201a:	e8 21 e0 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010201f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102026:	00 
f0102027:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010202e:	00 
f010202f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102033:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102038:	89 04 24             	mov    %eax,(%esp)
f010203b:	e8 07 f5 ff ff       	call   f0101547 <page_insert>
f0102040:	85 c0                	test   %eax,%eax
f0102042:	74 24                	je     f0102068 <mem_init+0xa77>
f0102044:	c7 44 24 0c 2c 71 10 	movl   $0xf010712c,0xc(%esp)
f010204b:	f0 
f010204c:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102053:	f0 
f0102054:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f010205b:	00 
f010205c:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102063:	e8 d8 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102068:	ba 00 10 00 00       	mov    $0x1000,%edx
f010206d:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102072:	e8 f9 eb ff ff       	call   f0100c70 <check_va2pa>
f0102077:	89 f2                	mov    %esi,%edx
f0102079:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
f010207f:	c1 fa 03             	sar    $0x3,%edx
f0102082:	c1 e2 0c             	shl    $0xc,%edx
f0102085:	39 d0                	cmp    %edx,%eax
f0102087:	74 24                	je     f01020ad <mem_init+0xabc>
f0102089:	c7 44 24 0c 68 71 10 	movl   $0xf0107168,0xc(%esp)
f0102090:	f0 
f0102091:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102098:	f0 
f0102099:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01020a0:	00 
f01020a1:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01020a8:	e8 93 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01020ad:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020b2:	74 24                	je     f01020d8 <mem_init+0xae7>
f01020b4:	c7 44 24 0c fb 77 10 	movl   $0xf01077fb,0xc(%esp)
f01020bb:	f0 
f01020bc:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01020c3:	f0 
f01020c4:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f01020cb:	00 
f01020cc:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01020d3:	e8 68 df ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01020d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020df:	e8 5b f1 ff ff       	call   f010123f <page_alloc>
f01020e4:	85 c0                	test   %eax,%eax
f01020e6:	74 24                	je     f010210c <mem_init+0xb1b>
f01020e8:	c7 44 24 0c 87 77 10 	movl   $0xf0107787,0xc(%esp)
f01020ef:	f0 
f01020f0:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01020f7:	f0 
f01020f8:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f01020ff:	00 
f0102100:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102107:	e8 34 df ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010210c:	8b 15 8c 7e 22 f0    	mov    0xf0227e8c,%edx
f0102112:	8b 02                	mov    (%edx),%eax
f0102114:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102119:	89 c1                	mov    %eax,%ecx
f010211b:	c1 e9 0c             	shr    $0xc,%ecx
f010211e:	3b 0d 88 7e 22 f0    	cmp    0xf0227e88,%ecx
f0102124:	72 20                	jb     f0102146 <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102126:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010212a:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0102131:	f0 
f0102132:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f0102139:	00 
f010213a:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102141:	e8 fa de ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102146:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010214b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010214e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102155:	00 
f0102156:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010215d:	00 
f010215e:	89 14 24             	mov    %edx,(%esp)
f0102161:	e8 9c f1 ff ff       	call   f0101302 <pgdir_walk>
f0102166:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102169:	83 c2 04             	add    $0x4,%edx
f010216c:	39 d0                	cmp    %edx,%eax
f010216e:	74 24                	je     f0102194 <mem_init+0xba3>
f0102170:	c7 44 24 0c 98 71 10 	movl   $0xf0107198,0xc(%esp)
f0102177:	f0 
f0102178:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010217f:	f0 
f0102180:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f0102187:	00 
f0102188:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010218f:	e8 ac de ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102194:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010219b:	00 
f010219c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021a3:	00 
f01021a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021a8:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f01021ad:	89 04 24             	mov    %eax,(%esp)
f01021b0:	e8 92 f3 ff ff       	call   f0101547 <page_insert>
f01021b5:	85 c0                	test   %eax,%eax
f01021b7:	74 24                	je     f01021dd <mem_init+0xbec>
f01021b9:	c7 44 24 0c d8 71 10 	movl   $0xf01071d8,0xc(%esp)
f01021c0:	f0 
f01021c1:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01021c8:	f0 
f01021c9:	c7 44 24 04 b0 03 00 	movl   $0x3b0,0x4(%esp)
f01021d0:	00 
f01021d1:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01021d8:	e8 63 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01021dd:	8b 3d 8c 7e 22 f0    	mov    0xf0227e8c,%edi
f01021e3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021e8:	89 f8                	mov    %edi,%eax
f01021ea:	e8 81 ea ff ff       	call   f0100c70 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01021ef:	89 f2                	mov    %esi,%edx
f01021f1:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
f01021f7:	c1 fa 03             	sar    $0x3,%edx
f01021fa:	c1 e2 0c             	shl    $0xc,%edx
f01021fd:	39 d0                	cmp    %edx,%eax
f01021ff:	74 24                	je     f0102225 <mem_init+0xc34>
f0102201:	c7 44 24 0c 68 71 10 	movl   $0xf0107168,0xc(%esp)
f0102208:	f0 
f0102209:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102210:	f0 
f0102211:	c7 44 24 04 b1 03 00 	movl   $0x3b1,0x4(%esp)
f0102218:	00 
f0102219:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102220:	e8 1b de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102225:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010222a:	74 24                	je     f0102250 <mem_init+0xc5f>
f010222c:	c7 44 24 0c fb 77 10 	movl   $0xf01077fb,0xc(%esp)
f0102233:	f0 
f0102234:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010223b:	f0 
f010223c:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0102243:	00 
f0102244:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010224b:	e8 f0 dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102250:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102257:	00 
f0102258:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010225f:	00 
f0102260:	89 3c 24             	mov    %edi,(%esp)
f0102263:	e8 9a f0 ff ff       	call   f0101302 <pgdir_walk>
f0102268:	f6 00 04             	testb  $0x4,(%eax)
f010226b:	75 24                	jne    f0102291 <mem_init+0xca0>
f010226d:	c7 44 24 0c 18 72 10 	movl   $0xf0107218,0xc(%esp)
f0102274:	f0 
f0102275:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010227c:	f0 
f010227d:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0102284:	00 
f0102285:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010228c:	e8 af dd ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102291:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102296:	f6 00 04             	testb  $0x4,(%eax)
f0102299:	75 24                	jne    f01022bf <mem_init+0xcce>
f010229b:	c7 44 24 0c 0c 78 10 	movl   $0xf010780c,0xc(%esp)
f01022a2:	f0 
f01022a3:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01022aa:	f0 
f01022ab:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f01022b2:	00 
f01022b3:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01022ba:	e8 81 dd ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01022bf:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022c6:	00 
f01022c7:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01022ce:	00 
f01022cf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022d3:	89 04 24             	mov    %eax,(%esp)
f01022d6:	e8 6c f2 ff ff       	call   f0101547 <page_insert>
f01022db:	85 c0                	test   %eax,%eax
f01022dd:	78 24                	js     f0102303 <mem_init+0xd12>
f01022df:	c7 44 24 0c 4c 72 10 	movl   $0xf010724c,0xc(%esp)
f01022e6:	f0 
f01022e7:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01022ee:	f0 
f01022ef:	c7 44 24 04 b7 03 00 	movl   $0x3b7,0x4(%esp)
f01022f6:	00 
f01022f7:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01022fe:	e8 3d dd ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102303:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010230a:	00 
f010230b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102312:	00 
f0102313:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102316:	89 44 24 04          	mov    %eax,0x4(%esp)
f010231a:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f010231f:	89 04 24             	mov    %eax,(%esp)
f0102322:	e8 20 f2 ff ff       	call   f0101547 <page_insert>
f0102327:	85 c0                	test   %eax,%eax
f0102329:	74 24                	je     f010234f <mem_init+0xd5e>
f010232b:	c7 44 24 0c 84 72 10 	movl   $0xf0107284,0xc(%esp)
f0102332:	f0 
f0102333:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010233a:	f0 
f010233b:	c7 44 24 04 ba 03 00 	movl   $0x3ba,0x4(%esp)
f0102342:	00 
f0102343:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010234a:	e8 f1 dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010234f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102356:	00 
f0102357:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010235e:	00 
f010235f:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102364:	89 04 24             	mov    %eax,(%esp)
f0102367:	e8 96 ef ff ff       	call   f0101302 <pgdir_walk>
f010236c:	f6 00 04             	testb  $0x4,(%eax)
f010236f:	74 24                	je     f0102395 <mem_init+0xda4>
f0102371:	c7 44 24 0c c0 72 10 	movl   $0xf01072c0,0xc(%esp)
f0102378:	f0 
f0102379:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102380:	f0 
f0102381:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f0102388:	00 
f0102389:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102390:	e8 ab dc ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102395:	8b 3d 8c 7e 22 f0    	mov    0xf0227e8c,%edi
f010239b:	ba 00 00 00 00       	mov    $0x0,%edx
f01023a0:	89 f8                	mov    %edi,%eax
f01023a2:	e8 c9 e8 ff ff       	call   f0100c70 <check_va2pa>
f01023a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01023aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023ad:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f01023b3:	c1 f8 03             	sar    $0x3,%eax
f01023b6:	c1 e0 0c             	shl    $0xc,%eax
f01023b9:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01023bc:	74 24                	je     f01023e2 <mem_init+0xdf1>
f01023be:	c7 44 24 0c f8 72 10 	movl   $0xf01072f8,0xc(%esp)
f01023c5:	f0 
f01023c6:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01023cd:	f0 
f01023ce:	c7 44 24 04 be 03 00 	movl   $0x3be,0x4(%esp)
f01023d5:	00 
f01023d6:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01023dd:	e8 5e dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01023e2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023e7:	89 f8                	mov    %edi,%eax
f01023e9:	e8 82 e8 ff ff       	call   f0100c70 <check_va2pa>
f01023ee:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01023f1:	74 24                	je     f0102417 <mem_init+0xe26>
f01023f3:	c7 44 24 0c 24 73 10 	movl   $0xf0107324,0xc(%esp)
f01023fa:	f0 
f01023fb:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102402:	f0 
f0102403:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f010240a:	00 
f010240b:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102412:	e8 29 dc ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102417:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010241a:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f010241f:	74 24                	je     f0102445 <mem_init+0xe54>
f0102421:	c7 44 24 0c 22 78 10 	movl   $0xf0107822,0xc(%esp)
f0102428:	f0 
f0102429:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102430:	f0 
f0102431:	c7 44 24 04 c1 03 00 	movl   $0x3c1,0x4(%esp)
f0102438:	00 
f0102439:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102440:	e8 fb db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102445:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010244a:	74 24                	je     f0102470 <mem_init+0xe7f>
f010244c:	c7 44 24 0c 33 78 10 	movl   $0xf0107833,0xc(%esp)
f0102453:	f0 
f0102454:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010245b:	f0 
f010245c:	c7 44 24 04 c2 03 00 	movl   $0x3c2,0x4(%esp)
f0102463:	00 
f0102464:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010246b:	e8 d0 db ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102470:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102477:	e8 c3 ed ff ff       	call   f010123f <page_alloc>
f010247c:	85 c0                	test   %eax,%eax
f010247e:	74 04                	je     f0102484 <mem_init+0xe93>
f0102480:	39 c6                	cmp    %eax,%esi
f0102482:	74 24                	je     f01024a8 <mem_init+0xeb7>
f0102484:	c7 44 24 0c 54 73 10 	movl   $0xf0107354,0xc(%esp)
f010248b:	f0 
f010248c:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102493:	f0 
f0102494:	c7 44 24 04 c5 03 00 	movl   $0x3c5,0x4(%esp)
f010249b:	00 
f010249c:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01024a3:	e8 98 db ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01024a8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024af:	00 
f01024b0:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f01024b5:	89 04 24             	mov    %eax,(%esp)
f01024b8:	e8 3a f0 ff ff       	call   f01014f7 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024bd:	8b 3d 8c 7e 22 f0    	mov    0xf0227e8c,%edi
f01024c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01024c8:	89 f8                	mov    %edi,%eax
f01024ca:	e8 a1 e7 ff ff       	call   f0100c70 <check_va2pa>
f01024cf:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024d2:	74 24                	je     f01024f8 <mem_init+0xf07>
f01024d4:	c7 44 24 0c 78 73 10 	movl   $0xf0107378,0xc(%esp)
f01024db:	f0 
f01024dc:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01024e3:	f0 
f01024e4:	c7 44 24 04 c9 03 00 	movl   $0x3c9,0x4(%esp)
f01024eb:	00 
f01024ec:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01024f3:	e8 48 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01024f8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024fd:	89 f8                	mov    %edi,%eax
f01024ff:	e8 6c e7 ff ff       	call   f0100c70 <check_va2pa>
f0102504:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102507:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
f010250d:	c1 fa 03             	sar    $0x3,%edx
f0102510:	c1 e2 0c             	shl    $0xc,%edx
f0102513:	39 d0                	cmp    %edx,%eax
f0102515:	74 24                	je     f010253b <mem_init+0xf4a>
f0102517:	c7 44 24 0c 24 73 10 	movl   $0xf0107324,0xc(%esp)
f010251e:	f0 
f010251f:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102526:	f0 
f0102527:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f010252e:	00 
f010252f:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102536:	e8 05 db ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010253b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010253e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102543:	74 24                	je     f0102569 <mem_init+0xf78>
f0102545:	c7 44 24 0c d9 77 10 	movl   $0xf01077d9,0xc(%esp)
f010254c:	f0 
f010254d:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102554:	f0 
f0102555:	c7 44 24 04 cb 03 00 	movl   $0x3cb,0x4(%esp)
f010255c:	00 
f010255d:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102564:	e8 d7 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102569:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010256e:	74 24                	je     f0102594 <mem_init+0xfa3>
f0102570:	c7 44 24 0c 33 78 10 	movl   $0xf0107833,0xc(%esp)
f0102577:	f0 
f0102578:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010257f:	f0 
f0102580:	c7 44 24 04 cc 03 00 	movl   $0x3cc,0x4(%esp)
f0102587:	00 
f0102588:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010258f:	e8 ac da ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102594:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010259b:	00 
f010259c:	89 3c 24             	mov    %edi,(%esp)
f010259f:	e8 53 ef ff ff       	call   f01014f7 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025a4:	8b 3d 8c 7e 22 f0    	mov    0xf0227e8c,%edi
f01025aa:	ba 00 00 00 00       	mov    $0x0,%edx
f01025af:	89 f8                	mov    %edi,%eax
f01025b1:	e8 ba e6 ff ff       	call   f0100c70 <check_va2pa>
f01025b6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025b9:	74 24                	je     f01025df <mem_init+0xfee>
f01025bb:	c7 44 24 0c 78 73 10 	movl   $0xf0107378,0xc(%esp)
f01025c2:	f0 
f01025c3:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01025ca:	f0 
f01025cb:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f01025d2:	00 
f01025d3:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01025da:	e8 61 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01025df:	ba 00 10 00 00       	mov    $0x1000,%edx
f01025e4:	89 f8                	mov    %edi,%eax
f01025e6:	e8 85 e6 ff ff       	call   f0100c70 <check_va2pa>
f01025eb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025ee:	74 24                	je     f0102614 <mem_init+0x1023>
f01025f0:	c7 44 24 0c 9c 73 10 	movl   $0xf010739c,0xc(%esp)
f01025f7:	f0 
f01025f8:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01025ff:	f0 
f0102600:	c7 44 24 04 d1 03 00 	movl   $0x3d1,0x4(%esp)
f0102607:	00 
f0102608:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010260f:	e8 2c da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102614:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102617:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010261c:	74 24                	je     f0102642 <mem_init+0x1051>
f010261e:	c7 44 24 0c 44 78 10 	movl   $0xf0107844,0xc(%esp)
f0102625:	f0 
f0102626:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010262d:	f0 
f010262e:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102635:	00 
f0102636:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010263d:	e8 fe d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102642:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102647:	74 24                	je     f010266d <mem_init+0x107c>
f0102649:	c7 44 24 0c 33 78 10 	movl   $0xf0107833,0xc(%esp)
f0102650:	f0 
f0102651:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102658:	f0 
f0102659:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f0102660:	00 
f0102661:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102668:	e8 d3 d9 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010266d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102674:	e8 c6 eb ff ff       	call   f010123f <page_alloc>
f0102679:	85 c0                	test   %eax,%eax
f010267b:	74 05                	je     f0102682 <mem_init+0x1091>
f010267d:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0102680:	74 24                	je     f01026a6 <mem_init+0x10b5>
f0102682:	c7 44 24 0c c4 73 10 	movl   $0xf01073c4,0xc(%esp)
f0102689:	f0 
f010268a:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102691:	f0 
f0102692:	c7 44 24 04 d6 03 00 	movl   $0x3d6,0x4(%esp)
f0102699:	00 
f010269a:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01026a1:	e8 9a d9 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01026a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026ad:	e8 8d eb ff ff       	call   f010123f <page_alloc>
f01026b2:	85 c0                	test   %eax,%eax
f01026b4:	74 24                	je     f01026da <mem_init+0x10e9>
f01026b6:	c7 44 24 0c 87 77 10 	movl   $0xf0107787,0xc(%esp)
f01026bd:	f0 
f01026be:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01026c5:	f0 
f01026c6:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f01026cd:	00 
f01026ce:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01026d5:	e8 66 d9 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026da:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f01026df:	8b 08                	mov    (%eax),%ecx
f01026e1:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01026e7:	89 da                	mov    %ebx,%edx
f01026e9:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
f01026ef:	c1 fa 03             	sar    $0x3,%edx
f01026f2:	c1 e2 0c             	shl    $0xc,%edx
f01026f5:	39 d1                	cmp    %edx,%ecx
f01026f7:	74 24                	je     f010271d <mem_init+0x112c>
f01026f9:	c7 44 24 0c d4 70 10 	movl   $0xf01070d4,0xc(%esp)
f0102700:	f0 
f0102701:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102708:	f0 
f0102709:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0102710:	00 
f0102711:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102718:	e8 23 d9 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010271d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102723:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102728:	74 24                	je     f010274e <mem_init+0x115d>
f010272a:	c7 44 24 0c ea 77 10 	movl   $0xf01077ea,0xc(%esp)
f0102731:	f0 
f0102732:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102739:	f0 
f010273a:	c7 44 24 04 de 03 00 	movl   $0x3de,0x4(%esp)
f0102741:	00 
f0102742:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102749:	e8 f2 d8 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010274e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102754:	89 1c 24             	mov    %ebx,(%esp)
f0102757:	e8 67 eb ff ff       	call   f01012c3 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010275c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102763:	00 
f0102764:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010276b:	00 
f010276c:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102771:	89 04 24             	mov    %eax,(%esp)
f0102774:	e8 89 eb ff ff       	call   f0101302 <pgdir_walk>
f0102779:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010277c:	8b 15 8c 7e 22 f0    	mov    0xf0227e8c,%edx
f0102782:	8b 4a 04             	mov    0x4(%edx),%ecx
f0102785:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010278b:	89 4d cc             	mov    %ecx,-0x34(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010278e:	8b 0d 88 7e 22 f0    	mov    0xf0227e88,%ecx
f0102794:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102797:	c1 ef 0c             	shr    $0xc,%edi
f010279a:	39 cf                	cmp    %ecx,%edi
f010279c:	72 23                	jb     f01027c1 <mem_init+0x11d0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010279e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01027a5:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f01027ac:	f0 
f01027ad:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f01027b4:	00 
f01027b5:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01027bc:	e8 7f d8 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01027c1:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01027c4:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01027ca:	39 f8                	cmp    %edi,%eax
f01027cc:	74 24                	je     f01027f2 <mem_init+0x1201>
f01027ce:	c7 44 24 0c 55 78 10 	movl   $0xf0107855,0xc(%esp)
f01027d5:	f0 
f01027d6:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01027dd:	f0 
f01027de:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f01027e5:	00 
f01027e6:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01027ed:	e8 4e d8 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01027f2:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01027f9:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01027ff:	89 d8                	mov    %ebx,%eax
f0102801:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f0102807:	c1 f8 03             	sar    $0x3,%eax
f010280a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010280d:	89 c2                	mov    %eax,%edx
f010280f:	c1 ea 0c             	shr    $0xc,%edx
f0102812:	39 d1                	cmp    %edx,%ecx
f0102814:	77 20                	ja     f0102836 <mem_init+0x1245>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102816:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010281a:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0102821:	f0 
f0102822:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102829:	00 
f010282a:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0102831:	e8 0a d8 ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102836:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010283d:	00 
f010283e:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102845:	00 
	return (void *)(pa + KERNBASE);
f0102846:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010284b:	89 04 24             	mov    %eax,(%esp)
f010284e:	e8 d2 32 00 00       	call   f0105b25 <memset>
	page_free(pp0);
f0102853:	89 1c 24             	mov    %ebx,(%esp)
f0102856:	e8 68 ea ff ff       	call   f01012c3 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010285b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102862:	00 
f0102863:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010286a:	00 
f010286b:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102870:	89 04 24             	mov    %eax,(%esp)
f0102873:	e8 8a ea ff ff       	call   f0101302 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102878:	89 da                	mov    %ebx,%edx
f010287a:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
f0102880:	c1 fa 03             	sar    $0x3,%edx
f0102883:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102886:	89 d0                	mov    %edx,%eax
f0102888:	c1 e8 0c             	shr    $0xc,%eax
f010288b:	3b 05 88 7e 22 f0    	cmp    0xf0227e88,%eax
f0102891:	72 20                	jb     f01028b3 <mem_init+0x12c2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102893:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102897:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f010289e:	f0 
f010289f:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01028a6:	00 
f01028a7:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f01028ae:	e8 8d d7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01028b3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01028b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01028bc:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f01028c3:	75 11                	jne    f01028d6 <mem_init+0x12e5>
f01028c5:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01028cb:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01028d1:	f6 00 01             	testb  $0x1,(%eax)
f01028d4:	74 24                	je     f01028fa <mem_init+0x1309>
f01028d6:	c7 44 24 0c 6d 78 10 	movl   $0xf010786d,0xc(%esp)
f01028dd:	f0 
f01028de:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01028e5:	f0 
f01028e6:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f01028ed:	00 
f01028ee:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01028f5:	e8 46 d7 ff ff       	call   f0100040 <_panic>
f01028fa:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01028fd:	39 d0                	cmp    %edx,%eax
f01028ff:	75 d0                	jne    f01028d1 <mem_init+0x12e0>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102901:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102906:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010290c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102912:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102915:	89 3d 40 72 22 f0    	mov    %edi,0xf0227240

	// free the pages we took
	page_free(pp0);
f010291b:	89 1c 24             	mov    %ebx,(%esp)
f010291e:	e8 a0 e9 ff ff       	call   f01012c3 <page_free>
	page_free(pp1);
f0102923:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102926:	89 04 24             	mov    %eax,(%esp)
f0102929:	e8 95 e9 ff ff       	call   f01012c3 <page_free>
	page_free(pp2);
f010292e:	89 34 24             	mov    %esi,(%esp)
f0102931:	e8 8d e9 ff ff       	call   f01012c3 <page_free>

	cprintf("check_page() succeeded!\n");
f0102936:	c7 04 24 84 78 10 f0 	movl   $0xf0107884,(%esp)
f010293d:	e8 7c 14 00 00       	call   f0103dbe <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
//pte_t *p = (pte_t *)0xf03fd000;
	boot_map_region(kern_pgdir,UPAGES, npages * sizeof(struct Page), PADDR(pages), PTE_U|PTE_P);
f0102942:	a1 90 7e 22 f0       	mov    0xf0227e90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102947:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010294c:	77 20                	ja     f010296e <mem_init+0x137d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010294e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102952:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f0102959:	f0 
f010295a:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f0102961:	00 
f0102962:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102969:	e8 d2 d6 ff ff       	call   f0100040 <_panic>
f010296e:	8b 0d 88 7e 22 f0    	mov    0xf0227e88,%ecx
f0102974:	c1 e1 03             	shl    $0x3,%ecx
f0102977:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f010297e:	00 
	return (physaddr_t)kva - KERNBASE;
f010297f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102984:	89 04 24             	mov    %eax,(%esp)
f0102987:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010298c:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102991:	e8 4f ea ff ff       	call   f01013e5 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS, NENV * sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f0102996:	a1 48 72 22 f0       	mov    0xf0227248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010299b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029a0:	77 20                	ja     f01029c2 <mem_init+0x13d1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029a2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029a6:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f01029ad:	f0 
f01029ae:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
f01029b5:	00 
f01029b6:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01029bd:	e8 7e d6 ff ff       	call   f0100040 <_panic>
f01029c2:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01029c9:	00 
	return (physaddr_t)kva - KERNBASE;
f01029ca:	05 00 00 00 10       	add    $0x10000000,%eax
f01029cf:	89 04 24             	mov    %eax,(%esp)
f01029d2:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f01029d7:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01029dc:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f01029e1:	e8 ff e9 ff ff       	call   f01013e5 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029e6:	b8 00 70 11 f0       	mov    $0xf0117000,%eax
f01029eb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029f0:	77 20                	ja     f0102a12 <mem_init+0x1421>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029f6:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f01029fd:	f0 
f01029fe:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
f0102a05:	00 
f0102a06:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102a0d:	e8 2e d6 ff ff       	call   f0100040 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
//	cprintf("\n%x\n", KSTACKTOP - KSTKSIZE);
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_P|PTE_W);
f0102a12:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102a19:	00 
f0102a1a:	c7 04 24 00 70 11 00 	movl   $0x117000,(%esp)
f0102a21:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102a26:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102a2b:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102a30:	e8 b0 e9 ff ff       	call   f01013e5 <boot_map_region>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ~0x0 - KERNBASE + 1;
	//cprintf("the size is %x", size);
	boot_map_region(kern_pgdir, KERNBASE, size, (physaddr_t)0,PTE_P|PTE_W);
f0102a35:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102a3c:	00 
f0102a3d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a44:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102a49:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102a4e:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102a53:	e8 8d e9 ff ff       	call   f01013e5 <boot_map_region>
mem_init_mp(void)
{
	// Create a direct mapping at the top of virtual address space starting
	// at IOMEMBASE for accessing the LAPIC unit using memory-mapped I/O.
	//cprintf("mem_init_mp: %x %x\n", IOMEMBASE, IOMEM_PADDR);
	boot_map_region(kern_pgdir, IOMEMBASE, -IOMEMBASE, IOMEM_PADDR, PTE_W);
f0102a58:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a5f:	00 
f0102a60:	c7 04 24 00 00 00 fe 	movl   $0xfe000000,(%esp)
f0102a67:	b9 00 00 00 02       	mov    $0x2000000,%ecx
f0102a6c:	ba 00 00 00 fe       	mov    $0xfe000000,%edx
f0102a71:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102a76:	e8 6a e9 ff ff       	call   f01013e5 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a7b:	b8 00 90 22 f0       	mov    $0xf0229000,%eax
f0102a80:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a85:	0f 87 1e 08 00 00    	ja     f01032a9 <mem_init+0x1cb8>
f0102a8b:	eb 20                	jmp    f0102aad <mem_init+0x14bc>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102a8d:	89 da                	mov    %ebx,%edx
f0102a8f:	f7 da                	neg    %edx
f0102a91:	c1 e2 10             	shl    $0x10,%edx
f0102a94:	81 ea 00 80 40 10    	sub    $0x10408000,%edx
	uint32_t kstacktop_i;
	for(; i < NCPU; i++){
		kstacktop_i = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (i + 1) + KSTKGAP;
		// panic("%x",percpu_kstacks[i]);
		// cprintf("%x\n",kstacktop_i);
		boot_map_region(kern_pgdir, kstacktop_i, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W|PTE_P);
f0102a9a:	89 d8                	mov    %ebx,%eax
f0102a9c:	c1 e0 0f             	shl    $0xf,%eax
f0102a9f:	05 00 90 22 f0       	add    $0xf0229000,%eax
f0102aa4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102aa9:	77 27                	ja     f0102ad2 <mem_init+0x14e1>
f0102aab:	eb 05                	jmp    f0102ab2 <mem_init+0x14c1>
f0102aad:	b8 00 90 22 f0       	mov    $0xf0229000,%eax
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ab2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ab6:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f0102abd:	f0 
f0102abe:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
f0102ac5:	00 
f0102ac6:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102acd:	e8 6e d5 ff ff       	call   f0100040 <_panic>
f0102ad2:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102ad9:	00 
	return (physaddr_t)kva - KERNBASE;
f0102ada:	05 00 00 00 10       	add    $0x10000000,%eax
f0102adf:	89 04 24             	mov    %eax,(%esp)
f0102ae2:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102ae7:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f0102aec:	e8 f4 e8 ff ff       	call   f01013e5 <boot_map_region>
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	size_t i = 0;
	uint32_t kstacktop_i;
	for(; i < NCPU; i++){
f0102af1:	83 c3 01             	add    $0x1,%ebx
f0102af4:	83 fb 08             	cmp    $0x8,%ebx
f0102af7:	75 94                	jne    f0102a8d <mem_init+0x149c>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102af9:	8b 3d 8c 7e 22 f0    	mov    0xf0227e8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f0102aff:	8b 15 88 7e 22 f0    	mov    0xf0227e88,%edx
f0102b05:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102b08:	8d 04 d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f0102b0f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102b14:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102b17:	75 30                	jne    f0102b49 <mem_init+0x1558>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102b19:	8b 1d 48 72 22 f0    	mov    0xf0227248,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b1f:	89 de                	mov    %ebx,%esi
f0102b21:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102b26:	89 f8                	mov    %edi,%eax
f0102b28:	e8 43 e1 ff ff       	call   f0100c70 <check_va2pa>
f0102b2d:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102b33:	0f 86 94 00 00 00    	jbe    f0102bcd <mem_init+0x15dc>
f0102b39:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102b3e:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0102b44:	e9 a4 00 00 00       	jmp    f0102bed <mem_init+0x15fc>
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102b49:	8b 1d 90 7e 22 f0    	mov    0xf0227e90,%ebx
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102b4f:	8d b3 00 00 00 10    	lea    0x10000000(%ebx),%esi
f0102b55:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102b5a:	89 f8                	mov    %edi,%eax
f0102b5c:	e8 0f e1 ff ff       	call   f0100c70 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b61:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102b67:	77 20                	ja     f0102b89 <mem_init+0x1598>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b69:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102b6d:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f0102b74:	f0 
f0102b75:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0102b7c:	00 
f0102b7d:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102b84:	e8 b7 d4 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102b89:	ba 00 00 00 00       	mov    $0x0,%edx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102b8e:	8d 0c 32             	lea    (%edx,%esi,1),%ecx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102b91:	39 c1                	cmp    %eax,%ecx
f0102b93:	74 24                	je     f0102bb9 <mem_init+0x15c8>
f0102b95:	c7 44 24 0c e8 73 10 	movl   $0xf01073e8,0xc(%esp)
f0102b9c:	f0 
f0102b9d:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102ba4:	f0 
f0102ba5:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0102bac:	00 
f0102bad:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102bb4:	e8 87 d4 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102bb9:	8d 9a 00 10 00 00    	lea    0x1000(%edx),%ebx
f0102bbf:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102bc2:	0f 87 1c 07 00 00    	ja     f01032e4 <mem_init+0x1cf3>
f0102bc8:	e9 4c ff ff ff       	jmp    f0102b19 <mem_init+0x1528>
f0102bcd:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102bd1:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f0102bd8:	f0 
f0102bd9:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102be0:	00 
f0102be1:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102be8:	e8 53 d4 ff ff       	call   f0100040 <_panic>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102bed:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102bf0:	39 d0                	cmp    %edx,%eax
f0102bf2:	74 24                	je     f0102c18 <mem_init+0x1627>
f0102bf4:	c7 44 24 0c 1c 74 10 	movl   $0xf010741c,0xc(%esp)
f0102bfb:	f0 
f0102bfc:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102c03:	f0 
f0102c04:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102c0b:	00 
f0102c0c:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102c13:	e8 28 d4 ff ff       	call   f0100040 <_panic>
f0102c18:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102c1e:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102c24:	0f 85 ac 06 00 00    	jne    f01032d6 <mem_init+0x1ce5>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102c2a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c2d:	c1 e6 0c             	shl    $0xc,%esi
f0102c30:	85 f6                	test   %esi,%esi
f0102c32:	74 4b                	je     f0102c7f <mem_init+0x168e>
f0102c34:	bb 00 00 00 00       	mov    $0x0,%ebx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102c39:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102c3f:	89 f8                	mov    %edi,%eax
f0102c41:	e8 2a e0 ff ff       	call   f0100c70 <check_va2pa>
f0102c46:	39 c3                	cmp    %eax,%ebx
f0102c48:	74 24                	je     f0102c6e <mem_init+0x167d>
f0102c4a:	c7 44 24 0c 50 74 10 	movl   $0xf0107450,0xc(%esp)
f0102c51:	f0 
f0102c52:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102c59:	f0 
f0102c5a:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0102c61:	00 
f0102c62:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102c69:	e8 d2 d3 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102c6e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102c74:	39 f3                	cmp    %esi,%ebx
f0102c76:	72 c1                	jb     f0102c39 <mem_init+0x1648>
f0102c78:	bb 00 00 00 fe       	mov    $0xfe000000,%ebx
f0102c7d:	eb 05                	jmp    f0102c84 <mem_init+0x1693>
f0102c7f:	bb 00 00 00 fe       	mov    $0xfe000000,%ebx
	// check IO mem (new in lab 4)
	//cprintf("check_kern_pgdir: %x", IOMEMBASE);
	for (i = IOMEMBASE; i < -PGSIZE; i += PGSIZE){
		//cprintf("i is %x\n", i);
		//cprintf("check_va2pa: %x\n",check_va2pa(pgdir, i));
		assert(check_va2pa(pgdir, i) == i);
f0102c84:	89 da                	mov    %ebx,%edx
f0102c86:	89 f8                	mov    %edi,%eax
f0102c88:	e8 e3 df ff ff       	call   f0100c70 <check_va2pa>
f0102c8d:	39 c3                	cmp    %eax,%ebx
f0102c8f:	74 24                	je     f0102cb5 <mem_init+0x16c4>
f0102c91:	c7 44 24 0c 9d 78 10 	movl   $0xf010789d,0xc(%esp)
f0102c98:	f0 
f0102c99:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102ca0:	f0 
f0102ca1:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0102ca8:	00 
f0102ca9:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102cb0:	e8 8b d3 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check IO mem (new in lab 4)
	//cprintf("check_kern_pgdir: %x", IOMEMBASE);
	for (i = IOMEMBASE; i < -PGSIZE; i += PGSIZE){
f0102cb5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102cbb:	81 fb 00 f0 ff ff    	cmp    $0xfffff000,%ebx
f0102cc1:	75 c1                	jne    f0102c84 <mem_init+0x1693>
f0102cc3:	be 00 00 bf ef       	mov    $0xefbf0000,%esi
f0102cc8:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0102ccf:	89 7d d4             	mov    %edi,-0x2c(%ebp)
}
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
f0102cd2:	bb 00 00 00 00       	mov    $0x0,%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102cd7:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102cda:	c1 e7 0f             	shl    $0xf,%edi
f0102cdd:	81 c7 00 90 22 f0    	add    $0xf0229000,%edi
	return (physaddr_t)kva - KERNBASE;
f0102ce3:	8d 8f 00 00 00 10    	lea    0x10000000(%edi),%ecx
f0102ce9:	89 4d d0             	mov    %ecx,-0x30(%ebp)
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102cec:	8d 94 1e 00 80 00 00 	lea    0x8000(%esi,%ebx,1),%edx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102cf3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cf6:	e8 75 df ff ff       	call   f0100c70 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cfb:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0102d01:	77 20                	ja     f0102d23 <mem_init+0x1732>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d03:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102d07:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f0102d0e:	f0 
f0102d0f:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102d16:	00 
f0102d17:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102d1e:	e8 1d d3 ff ff       	call   f0100040 <_panic>
f0102d23:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102d26:	01 da                	add    %ebx,%edx
f0102d28:	39 d0                	cmp    %edx,%eax
f0102d2a:	74 24                	je     f0102d50 <mem_init+0x175f>
f0102d2c:	c7 44 24 0c 78 74 10 	movl   $0xf0107478,0xc(%esp)
f0102d33:	f0 
f0102d34:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102d3b:	f0 
f0102d3c:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102d43:	00 
f0102d44:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102d4b:	e8 f0 d2 ff ff       	call   f0100040 <_panic>
}
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
f0102d50:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d56:	81 fb 00 80 00 00    	cmp    $0x8000,%ebx
f0102d5c:	75 8e                	jne    f0102cec <mem_init+0x16fb>
f0102d5e:	66 bb 00 00          	mov    $0x0,%bx
f0102d62:	8b 7d d4             	mov    -0x2c(%ebp),%edi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102d65:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);}
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102d68:	89 f8                	mov    %edi,%eax
f0102d6a:	e8 01 df ff ff       	call   f0100c70 <check_va2pa>
f0102d6f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102d72:	74 24                	je     f0102d98 <mem_init+0x17a7>
f0102d74:	c7 44 24 0c c0 74 10 	movl   $0xf01074c0,0xc(%esp)
f0102d7b:	f0 
f0102d7c:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102d83:	f0 
f0102d84:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102d8b:	00 
f0102d8c:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102d93:	e8 a8 d2 ff ff       	call   f0100040 <_panic>
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE){
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);}
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102d98:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d9e:	81 fb 00 80 00 00    	cmp    $0x8000,%ebx
f0102da4:	75 bf                	jne    f0102d65 <mem_init+0x1774>
		//cprintf("check_va2pa: %x\n",check_va2pa(pgdir, i));
		assert(check_va2pa(pgdir, i) == i);
}
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102da6:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0102daa:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f0102db0:	83 7d cc 08          	cmpl   $0x8,-0x34(%ebp)
f0102db4:	0f 85 18 ff ff ff    	jne    f0102cd2 <mem_init+0x16e1>
f0102dba:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102dbd:	b8 00 00 00 00       	mov    $0x0,%eax
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102dc2:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102dc8:	83 fa 03             	cmp    $0x3,%edx
f0102dcb:	77 2e                	ja     f0102dfb <mem_init+0x180a>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102dcd:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102dd1:	0f 85 aa 00 00 00    	jne    f0102e81 <mem_init+0x1890>
f0102dd7:	c7 44 24 0c b8 78 10 	movl   $0xf01078b8,0xc(%esp)
f0102dde:	f0 
f0102ddf:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102de6:	f0 
f0102de7:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102dee:	00 
f0102def:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102df6:	e8 45 d2 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102dfb:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102e00:	76 55                	jbe    f0102e57 <mem_init+0x1866>
				assert(pgdir[i] & PTE_P);
f0102e02:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102e05:	f6 c2 01             	test   $0x1,%dl
f0102e08:	75 24                	jne    f0102e2e <mem_init+0x183d>
f0102e0a:	c7 44 24 0c b8 78 10 	movl   $0xf01078b8,0xc(%esp)
f0102e11:	f0 
f0102e12:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102e19:	f0 
f0102e1a:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0102e21:	00 
f0102e22:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102e29:	e8 12 d2 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102e2e:	f6 c2 02             	test   $0x2,%dl
f0102e31:	75 4e                	jne    f0102e81 <mem_init+0x1890>
f0102e33:	c7 44 24 0c c9 78 10 	movl   $0xf01078c9,0xc(%esp)
f0102e3a:	f0 
f0102e3b:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102e42:	f0 
f0102e43:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0102e4a:	00 
f0102e4b:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102e52:	e8 e9 d1 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102e57:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102e5b:	74 24                	je     f0102e81 <mem_init+0x1890>
f0102e5d:	c7 44 24 0c da 78 10 	movl   $0xf01078da,0xc(%esp)
f0102e64:	f0 
f0102e65:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102e6c:	f0 
f0102e6d:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0102e74:	00 
f0102e75:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102e7c:	e8 bf d1 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102e81:	83 c0 01             	add    $0x1,%eax
f0102e84:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102e89:	0f 85 33 ff ff ff    	jne    f0102dc2 <mem_init+0x17d1>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102e8f:	c7 04 24 e4 74 10 f0 	movl   $0xf01074e4,(%esp)
f0102e96:	e8 23 0f 00 00       	call   f0103dbe <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102e9b:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ea0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ea5:	77 20                	ja     f0102ec7 <mem_init+0x18d6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ea7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102eab:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f0102eb2:	f0 
f0102eb3:	c7 44 24 04 f1 00 00 	movl   $0xf1,0x4(%esp)
f0102eba:	00 
f0102ebb:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102ec2:	e8 79 d1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102ec7:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102ecc:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102ecf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ed4:	e8 ab de ff ff       	call   f0100d84 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102ed9:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102edc:	83 e0 f3             	and    $0xfffffff3,%eax
f0102edf:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102ee4:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102ee7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102eee:	e8 4c e3 ff ff       	call   f010123f <page_alloc>
f0102ef3:	89 c3                	mov    %eax,%ebx
f0102ef5:	85 c0                	test   %eax,%eax
f0102ef7:	75 24                	jne    f0102f1d <mem_init+0x192c>
f0102ef9:	c7 44 24 0c dc 76 10 	movl   $0xf01076dc,0xc(%esp)
f0102f00:	f0 
f0102f01:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102f08:	f0 
f0102f09:	c7 44 24 04 0b 04 00 	movl   $0x40b,0x4(%esp)
f0102f10:	00 
f0102f11:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102f18:	e8 23 d1 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102f1d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f24:	e8 16 e3 ff ff       	call   f010123f <page_alloc>
f0102f29:	89 c7                	mov    %eax,%edi
f0102f2b:	85 c0                	test   %eax,%eax
f0102f2d:	75 24                	jne    f0102f53 <mem_init+0x1962>
f0102f2f:	c7 44 24 0c f2 76 10 	movl   $0xf01076f2,0xc(%esp)
f0102f36:	f0 
f0102f37:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102f3e:	f0 
f0102f3f:	c7 44 24 04 0c 04 00 	movl   $0x40c,0x4(%esp)
f0102f46:	00 
f0102f47:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102f4e:	e8 ed d0 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102f53:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f5a:	e8 e0 e2 ff ff       	call   f010123f <page_alloc>
f0102f5f:	89 c6                	mov    %eax,%esi
f0102f61:	85 c0                	test   %eax,%eax
f0102f63:	75 24                	jne    f0102f89 <mem_init+0x1998>
f0102f65:	c7 44 24 0c 08 77 10 	movl   $0xf0107708,0xc(%esp)
f0102f6c:	f0 
f0102f6d:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0102f74:	f0 
f0102f75:	c7 44 24 04 0d 04 00 	movl   $0x40d,0x4(%esp)
f0102f7c:	00 
f0102f7d:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0102f84:	e8 b7 d0 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102f89:	89 1c 24             	mov    %ebx,(%esp)
f0102f8c:	e8 32 e3 ff ff       	call   f01012c3 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f91:	89 f8                	mov    %edi,%eax
f0102f93:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f0102f99:	c1 f8 03             	sar    $0x3,%eax
f0102f9c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f9f:	89 c2                	mov    %eax,%edx
f0102fa1:	c1 ea 0c             	shr    $0xc,%edx
f0102fa4:	3b 15 88 7e 22 f0    	cmp    0xf0227e88,%edx
f0102faa:	72 20                	jb     f0102fcc <mem_init+0x19db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fac:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102fb0:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0102fb7:	f0 
f0102fb8:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102fbf:	00 
f0102fc0:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0102fc7:	e8 74 d0 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102fcc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102fd3:	00 
f0102fd4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102fdb:	00 
	return (void *)(pa + KERNBASE);
f0102fdc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102fe1:	89 04 24             	mov    %eax,(%esp)
f0102fe4:	e8 3c 2b 00 00       	call   f0105b25 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102fe9:	89 f0                	mov    %esi,%eax
f0102feb:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f0102ff1:	c1 f8 03             	sar    $0x3,%eax
f0102ff4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ff7:	89 c2                	mov    %eax,%edx
f0102ff9:	c1 ea 0c             	shr    $0xc,%edx
f0102ffc:	3b 15 88 7e 22 f0    	cmp    0xf0227e88,%edx
f0103002:	72 20                	jb     f0103024 <mem_init+0x1a33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103004:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103008:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f010300f:	f0 
f0103010:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103017:	00 
f0103018:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f010301f:	e8 1c d0 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0103024:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010302b:	00 
f010302c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103033:	00 
	return (void *)(pa + KERNBASE);
f0103034:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103039:	89 04 24             	mov    %eax,(%esp)
f010303c:	e8 e4 2a 00 00       	call   f0105b25 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103041:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103048:	00 
f0103049:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103050:	00 
f0103051:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103055:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f010305a:	89 04 24             	mov    %eax,(%esp)
f010305d:	e8 e5 e4 ff ff       	call   f0101547 <page_insert>
	assert(pp1->pp_ref == 1);
f0103062:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103067:	74 24                	je     f010308d <mem_init+0x1a9c>
f0103069:	c7 44 24 0c d9 77 10 	movl   $0xf01077d9,0xc(%esp)
f0103070:	f0 
f0103071:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0103078:	f0 
f0103079:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f0103080:	00 
f0103081:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0103088:	e8 b3 cf ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010308d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103094:	01 01 01 
f0103097:	74 24                	je     f01030bd <mem_init+0x1acc>
f0103099:	c7 44 24 0c 04 75 10 	movl   $0xf0107504,0xc(%esp)
f01030a0:	f0 
f01030a1:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01030a8:	f0 
f01030a9:	c7 44 24 04 13 04 00 	movl   $0x413,0x4(%esp)
f01030b0:	00 
f01030b1:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01030b8:	e8 83 cf ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01030bd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01030c4:	00 
f01030c5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01030cc:	00 
f01030cd:	89 74 24 04          	mov    %esi,0x4(%esp)
f01030d1:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f01030d6:	89 04 24             	mov    %eax,(%esp)
f01030d9:	e8 69 e4 ff ff       	call   f0101547 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01030de:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01030e5:	02 02 02 
f01030e8:	74 24                	je     f010310e <mem_init+0x1b1d>
f01030ea:	c7 44 24 0c 28 75 10 	movl   $0xf0107528,0xc(%esp)
f01030f1:	f0 
f01030f2:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01030f9:	f0 
f01030fa:	c7 44 24 04 15 04 00 	movl   $0x415,0x4(%esp)
f0103101:	00 
f0103102:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0103109:	e8 32 cf ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010310e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103113:	74 24                	je     f0103139 <mem_init+0x1b48>
f0103115:	c7 44 24 0c fb 77 10 	movl   $0xf01077fb,0xc(%esp)
f010311c:	f0 
f010311d:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0103124:	f0 
f0103125:	c7 44 24 04 16 04 00 	movl   $0x416,0x4(%esp)
f010312c:	00 
f010312d:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0103134:	e8 07 cf ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0103139:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010313e:	74 24                	je     f0103164 <mem_init+0x1b73>
f0103140:	c7 44 24 0c 44 78 10 	movl   $0xf0107844,0xc(%esp)
f0103147:	f0 
f0103148:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010314f:	f0 
f0103150:	c7 44 24 04 17 04 00 	movl   $0x417,0x4(%esp)
f0103157:	00 
f0103158:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f010315f:	e8 dc ce ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103164:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010316b:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010316e:	89 f0                	mov    %esi,%eax
f0103170:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f0103176:	c1 f8 03             	sar    $0x3,%eax
f0103179:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010317c:	89 c2                	mov    %eax,%edx
f010317e:	c1 ea 0c             	shr    $0xc,%edx
f0103181:	3b 15 88 7e 22 f0    	cmp    0xf0227e88,%edx
f0103187:	72 20                	jb     f01031a9 <mem_init+0x1bb8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103189:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010318d:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0103194:	f0 
f0103195:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010319c:	00 
f010319d:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f01031a4:	e8 97 ce ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01031a9:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01031b0:	03 03 03 
f01031b3:	74 24                	je     f01031d9 <mem_init+0x1be8>
f01031b5:	c7 44 24 0c 4c 75 10 	movl   $0xf010754c,0xc(%esp)
f01031bc:	f0 
f01031bd:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f01031c4:	f0 
f01031c5:	c7 44 24 04 19 04 00 	movl   $0x419,0x4(%esp)
f01031cc:	00 
f01031cd:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f01031d4:	e8 67 ce ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01031d9:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01031e0:	00 
f01031e1:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f01031e6:	89 04 24             	mov    %eax,(%esp)
f01031e9:	e8 09 e3 ff ff       	call   f01014f7 <page_remove>
	assert(pp2->pp_ref == 0);
f01031ee:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01031f3:	74 24                	je     f0103219 <mem_init+0x1c28>
f01031f5:	c7 44 24 0c 33 78 10 	movl   $0xf0107833,0xc(%esp)
f01031fc:	f0 
f01031fd:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0103204:	f0 
f0103205:	c7 44 24 04 1b 04 00 	movl   $0x41b,0x4(%esp)
f010320c:	00 
f010320d:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0103214:	e8 27 ce ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103219:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f010321e:	8b 08                	mov    (%eax),%ecx
f0103220:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0103226:	89 da                	mov    %ebx,%edx
f0103228:	2b 15 90 7e 22 f0    	sub    0xf0227e90,%edx
f010322e:	c1 fa 03             	sar    $0x3,%edx
f0103231:	c1 e2 0c             	shl    $0xc,%edx
f0103234:	39 d1                	cmp    %edx,%ecx
f0103236:	74 24                	je     f010325c <mem_init+0x1c6b>
f0103238:	c7 44 24 0c d4 70 10 	movl   $0xf01070d4,0xc(%esp)
f010323f:	f0 
f0103240:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0103247:	f0 
f0103248:	c7 44 24 04 1e 04 00 	movl   $0x41e,0x4(%esp)
f010324f:	00 
f0103250:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0103257:	e8 e4 cd ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010325c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0103262:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103267:	74 24                	je     f010328d <mem_init+0x1c9c>
f0103269:	c7 44 24 0c ea 77 10 	movl   $0xf01077ea,0xc(%esp)
f0103270:	f0 
f0103271:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f0103278:	f0 
f0103279:	c7 44 24 04 20 04 00 	movl   $0x420,0x4(%esp)
f0103280:	00 
f0103281:	c7 04 24 d9 75 10 f0 	movl   $0xf01075d9,(%esp)
f0103288:	e8 b3 cd ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010328d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0103293:	89 1c 24             	mov    %ebx,(%esp)
f0103296:	e8 28 e0 ff ff       	call   f01012c3 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010329b:	c7 04 24 78 75 10 f0 	movl   $0xf0107578,(%esp)
f01032a2:	e8 17 0b 00 00       	call   f0103dbe <cprintf>
f01032a7:	eb 4f                	jmp    f01032f8 <mem_init+0x1d07>
	uint32_t kstacktop_i;
	for(; i < NCPU; i++){
		kstacktop_i = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (i + 1) + KSTKGAP;
		// panic("%x",percpu_kstacks[i]);
		// cprintf("%x\n",kstacktop_i);
		boot_map_region(kern_pgdir, kstacktop_i, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W|PTE_P);
f01032a9:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01032b0:	00 
f01032b1:	c7 04 24 00 90 22 00 	movl   $0x229000,(%esp)
f01032b8:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01032bd:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01032c2:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
f01032c7:	e8 19 e1 ff ff       	call   f01013e5 <boot_map_region>
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	size_t i = 0;
	uint32_t kstacktop_i;
	for(; i < NCPU; i++){
f01032cc:	bb 01 00 00 00       	mov    $0x1,%ebx
f01032d1:	e9 b7 f7 ff ff       	jmp    f0102a8d <mem_init+0x149c>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01032d6:	89 da                	mov    %ebx,%edx
f01032d8:	89 f8                	mov    %edi,%eax
f01032da:	e8 91 d9 ff ff       	call   f0100c70 <check_va2pa>
f01032df:	e9 09 f9 ff ff       	jmp    f0102bed <mem_init+0x15fc>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01032e4:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01032ea:	89 f8                	mov    %edi,%eax
f01032ec:	e8 7f d9 ff ff       	call   f0100c70 <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01032f1:	89 da                	mov    %ebx,%edx
f01032f3:	e9 96 f8 ff ff       	jmp    f0102b8e <mem_init+0x159d>
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();

}
f01032f8:	83 c4 3c             	add    $0x3c,%esp
f01032fb:	5b                   	pop    %ebx
f01032fc:	5e                   	pop    %esi
f01032fd:	5f                   	pop    %edi
f01032fe:	5d                   	pop    %ebp
f01032ff:	c3                   	ret    

f0103300 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0103300:	55                   	push   %ebp
f0103301:	89 e5                	mov    %esp,%ebp
f0103303:	57                   	push   %edi
f0103304:	56                   	push   %esi
f0103305:	53                   	push   %ebx
f0103306:	83 ec 2c             	sub    $0x2c,%esp
f0103309:	8b 75 08             	mov    0x8(%ebp),%esi
f010330c:	8b 45 0c             	mov    0xc(%ebp),%eax
	// LAB 3: Your code here.
	pte_t *pte;
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);
f010330f:	89 c2                	mov    %eax,%edx
f0103311:	03 55 10             	add    0x10(%ebp),%edx
f0103314:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f010331a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0103320:	89 55 e4             	mov    %edx,-0x1c(%ebp)

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
f0103323:	39 d0                	cmp    %edx,%eax
f0103325:	73 5d                	jae    f0103384 <user_mem_check+0x84>
		user_mem_check_addr = (uintptr_t)va; /* record the va */
f0103327:	89 c3                	mov    %eax,%ebx
f0103329:	a3 44 72 22 f0       	mov    %eax,0xf0227244
		if(user_mem_check_addr > ULIM) /* below the ULIM */
			return -E_FAULT;
		if((pte = pgdir_walk(env->env_pgdir,va,0)) == NULL) /* No creation, and the pte is null */
			return -E_FAULT;
		if(!(*pte & (perm|PTE_P))) /* No permission */
f010332e:	8b 7d 14             	mov    0x14(%ebp),%edi
f0103331:	83 cf 01             	or     $0x1,%edi
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
		user_mem_check_addr = (uintptr_t)va; /* record the va */
		if(user_mem_check_addr > ULIM) /* below the ULIM */
f0103334:	3d 00 00 80 ef       	cmp    $0xef800000,%eax
f0103339:	76 12                	jbe    f010334d <user_mem_check+0x4d>
f010333b:	eb 4e                	jmp    f010338b <user_mem_check+0x8b>
	pte_t *pte;
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
		user_mem_check_addr = (uintptr_t)va; /* record the va */
f010333d:	89 c3                	mov    %eax,%ebx
f010333f:	a3 44 72 22 f0       	mov    %eax,0xf0227244
		if(user_mem_check_addr > ULIM) /* below the ULIM */
f0103344:	3d 00 00 80 ef       	cmp    $0xef800000,%eax
f0103349:	76 02                	jbe    f010334d <user_mem_check+0x4d>
f010334b:	eb 45                	jmp    f0103392 <user_mem_check+0x92>
			return -E_FAULT;
		if((pte = pgdir_walk(env->env_pgdir,va,0)) == NULL) /* No creation, and the pte is null */
f010334d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0103354:	00 
f0103355:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103359:	8b 46 60             	mov    0x60(%esi),%eax
f010335c:	89 04 24             	mov    %eax,(%esp)
f010335f:	e8 9e df ff ff       	call   f0101302 <pgdir_walk>
f0103364:	85 c0                	test   %eax,%eax
f0103366:	74 31                	je     f0103399 <user_mem_check+0x99>
			return -E_FAULT;
		if(!(*pte & (perm|PTE_P))) /* No permission */
f0103368:	85 38                	test   %edi,(%eax)
f010336a:	74 34                	je     f01033a0 <user_mem_check+0xa0>
			return -E_FAULT;
		va = ROUNDDOWN(va, PGSIZE);
f010336c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	// LAB 3: Your code here.
	pte_t *pte;
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
f0103372:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0103378:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010337b:	77 c0                	ja     f010333d <user_mem_check+0x3d>
			return -E_FAULT;
		if(!(*pte & (perm|PTE_P))) /* No permission */
			return -E_FAULT;
		va = ROUNDDOWN(va, PGSIZE);
	}
	return 0;
f010337d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103382:	eb 21                	jmp    f01033a5 <user_mem_check+0xa5>
f0103384:	b8 00 00 00 00       	mov    $0x0,%eax
f0103389:	eb 1a                	jmp    f01033a5 <user_mem_check+0xa5>

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
		user_mem_check_addr = (uintptr_t)va; /* record the va */
		if(user_mem_check_addr > ULIM) /* below the ULIM */
			return -E_FAULT;
f010338b:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103390:	eb 13                	jmp    f01033a5 <user_mem_check+0xa5>
f0103392:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103397:	eb 0c                	jmp    f01033a5 <user_mem_check+0xa5>
		if((pte = pgdir_walk(env->env_pgdir,va,0)) == NULL) /* No creation, and the pte is null */
			return -E_FAULT;
f0103399:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010339e:	eb 05                	jmp    f01033a5 <user_mem_check+0xa5>
		if(!(*pte & (perm|PTE_P))) /* No permission */
			return -E_FAULT;
f01033a0:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
		va = ROUNDDOWN(va, PGSIZE);
	}
	return 0;
}
f01033a5:	83 c4 2c             	add    $0x2c,%esp
f01033a8:	5b                   	pop    %ebx
f01033a9:	5e                   	pop    %esi
f01033aa:	5f                   	pop    %edi
f01033ab:	5d                   	pop    %ebp
f01033ac:	c3                   	ret    

f01033ad <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01033ad:	55                   	push   %ebp
f01033ae:	89 e5                	mov    %esp,%ebp
f01033b0:	53                   	push   %ebx
f01033b1:	83 ec 14             	sub    $0x14,%esp
f01033b4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01033b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01033ba:	83 c8 04             	or     $0x4,%eax
f01033bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033c1:	8b 45 10             	mov    0x10(%ebp),%eax
f01033c4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033cf:	89 1c 24             	mov    %ebx,(%esp)
f01033d2:	e8 29 ff ff ff       	call   f0103300 <user_mem_check>
f01033d7:	85 c0                	test   %eax,%eax
f01033d9:	79 24                	jns    f01033ff <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f01033db:	a1 44 72 22 f0       	mov    0xf0227244,%eax
f01033e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033e4:	8b 43 48             	mov    0x48(%ebx),%eax
f01033e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033eb:	c7 04 24 a4 75 10 f0 	movl   $0xf01075a4,(%esp)
f01033f2:	e8 c7 09 00 00       	call   f0103dbe <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01033f7:	89 1c 24             	mov    %ebx,(%esp)
f01033fa:	e8 f2 06 00 00       	call   f0103af1 <env_destroy>
	}
}
f01033ff:	83 c4 14             	add    $0x14,%esp
f0103402:	5b                   	pop    %ebx
f0103403:	5d                   	pop    %ebp
f0103404:	c3                   	ret    
f0103405:	66 90                	xchg   %ax,%ax
f0103407:	90                   	nop

f0103408 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103408:	55                   	push   %ebp
f0103409:	89 e5                	mov    %esp,%ebp
f010340b:	57                   	push   %edi
f010340c:	56                   	push   %esi
f010340d:	53                   	push   %ebx
f010340e:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	if(!len) /* If the len is zero panic immedatelly? or just return? */
f0103411:	85 c9                	test   %ecx,%ecx
f0103413:	75 1c                	jne    f0103431 <region_alloc+0x29>
		panic("Allocation failed!\n");
f0103415:	c7 44 24 08 e8 78 10 	movl   $0xf01078e8,0x8(%esp)
f010341c:	f0 
f010341d:	c7 44 24 04 2a 01 00 	movl   $0x12a,0x4(%esp)
f0103424:	00 
f0103425:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f010342c:	e8 0f cc ff ff       	call   f0100040 <_panic>
f0103431:	89 c7                	mov    %eax,%edi
	void* up_lim = ROUNDUP(va + len, PGSIZE);
f0103433:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010343a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	va = ROUNDDOWN(va, PGSIZE);
f0103440:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0103446:	89 d3                	mov    %edx,%ebx
	
	struct Page *p;
	for(;va < up_lim; va += PGSIZE){
f0103448:	39 d6                	cmp    %edx,%esi
f010344a:	76 71                	jbe    f01034bd <region_alloc+0xb5>
		if((p  = page_alloc(ALLOC_ZERO)) == NULL)
f010344c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103453:	e8 e7 dd ff ff       	call   f010123f <page_alloc>
f0103458:	85 c0                	test   %eax,%eax
f010345a:	75 1c                	jne    f0103478 <region_alloc+0x70>
			panic("Allocation failed!\n");
f010345c:	c7 44 24 08 e8 78 10 	movl   $0xf01078e8,0x8(%esp)
f0103463:	f0 
f0103464:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
f010346b:	00 
f010346c:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f0103473:	e8 c8 cb ff ff       	call   f0100040 <_panic>
		if(page_insert(e->env_pgdir, p, va, PTE_U|PTE_W) < 0)
f0103478:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010347f:	00 
f0103480:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103484:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103488:	8b 47 60             	mov    0x60(%edi),%eax
f010348b:	89 04 24             	mov    %eax,(%esp)
f010348e:	e8 b4 e0 ff ff       	call   f0101547 <page_insert>
f0103493:	85 c0                	test   %eax,%eax
f0103495:	79 1c                	jns    f01034b3 <region_alloc+0xab>
			panic("Allocation failed!\n");
f0103497:	c7 44 24 08 e8 78 10 	movl   $0xf01078e8,0x8(%esp)
f010349e:	f0 
f010349f:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
f01034a6:	00 
f01034a7:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f01034ae:	e8 8d cb ff ff       	call   f0100040 <_panic>
		panic("Allocation failed!\n");
	void* up_lim = ROUNDUP(va + len, PGSIZE);
	va = ROUNDDOWN(va, PGSIZE);
	
	struct Page *p;
	for(;va < up_lim; va += PGSIZE){
f01034b3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01034b9:	39 de                	cmp    %ebx,%esi
f01034bb:	77 8f                	ja     f010344c <region_alloc+0x44>
			panic("Allocation failed!\n");
		if(page_insert(e->env_pgdir, p, va, PTE_U|PTE_W) < 0)
			panic("Allocation failed!\n");
	}

}
f01034bd:	83 c4 1c             	add    $0x1c,%esp
f01034c0:	5b                   	pop    %ebx
f01034c1:	5e                   	pop    %esi
f01034c2:	5f                   	pop    %edi
f01034c3:	5d                   	pop    %ebp
f01034c4:	c3                   	ret    

f01034c5 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01034c5:	55                   	push   %ebp
f01034c6:	89 e5                	mov    %esp,%ebp
f01034c8:	83 ec 08             	sub    $0x8,%esp
f01034cb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01034ce:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01034d1:	8b 45 08             	mov    0x8(%ebp),%eax
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01034d4:	85 c0                	test   %eax,%eax
f01034d6:	75 1a                	jne    f01034f2 <envid2env+0x2d>
		*env_store = curenv;
f01034d8:	e8 ef 2c 00 00       	call   f01061cc <cpunum>
f01034dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01034e0:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01034e6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034e9:	89 02                	mov    %eax,(%edx)
		return 0;
f01034eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01034f0:	eb 72                	jmp    f0103564 <envid2env+0x9f>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01034f2:	89 c3                	mov    %eax,%ebx
f01034f4:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f01034fa:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f01034fd:	03 1d 48 72 22 f0    	add    0xf0227248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103503:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103507:	74 05                	je     f010350e <envid2env+0x49>
f0103509:	39 43 48             	cmp    %eax,0x48(%ebx)
f010350c:	74 10                	je     f010351e <envid2env+0x59>
		*env_store = 0;
f010350e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103511:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103517:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010351c:	eb 46                	jmp    f0103564 <envid2env+0x9f>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010351e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103522:	74 36                	je     f010355a <envid2env+0x95>
f0103524:	e8 a3 2c 00 00       	call   f01061cc <cpunum>
f0103529:	6b c0 74             	imul   $0x74,%eax,%eax
f010352c:	39 98 28 80 22 f0    	cmp    %ebx,-0xfdd7fd8(%eax)
f0103532:	74 26                	je     f010355a <envid2env+0x95>
f0103534:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103537:	e8 90 2c 00 00       	call   f01061cc <cpunum>
f010353c:	6b c0 74             	imul   $0x74,%eax,%eax
f010353f:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0103545:	3b 70 48             	cmp    0x48(%eax),%esi
f0103548:	74 10                	je     f010355a <envid2env+0x95>
		*env_store = 0;
f010354a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010354d:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
		return -E_BAD_ENV;
f0103553:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103558:	eb 0a                	jmp    f0103564 <envid2env+0x9f>
	}

	*env_store = e;
f010355a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010355d:	89 18                	mov    %ebx,(%eax)
	return 0;
f010355f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103564:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0103567:	8b 75 fc             	mov    -0x4(%ebp),%esi
f010356a:	89 ec                	mov    %ebp,%esp
f010356c:	5d                   	pop    %ebp
f010356d:	c3                   	ret    

f010356e <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010356e:	55                   	push   %ebp
f010356f:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103571:	b8 00 13 12 f0       	mov    $0xf0121300,%eax
f0103576:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103579:	b8 23 00 00 00       	mov    $0x23,%eax
f010357e:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0103580:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0103582:	b0 10                	mov    $0x10,%al
f0103584:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103586:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0103588:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010358a:	ea 91 35 10 f0 08 00 	ljmp   $0x8,$0xf0103591
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0103591:	b0 00                	mov    $0x0,%al
f0103593:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103596:	5d                   	pop    %ebp
f0103597:	c3                   	ret    

f0103598 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103598:	55                   	push   %ebp
f0103599:	89 e5                	mov    %esp,%ebp
f010359b:	56                   	push   %esi
f010359c:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV-1; i >=0 ; i--){
		envs[i].env_link = env_free_list;
f010359d:	8b 35 48 72 22 f0    	mov    0xf0227248,%esi
f01035a3:	8b 0d 4c 72 22 f0    	mov    0xf022724c,%ecx
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
f01035a9:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f01035af:	ba 00 04 00 00       	mov    $0x400,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV-1; i >=0 ; i--){
		envs[i].env_link = env_free_list;
f01035b4:	89 c3                	mov    %eax,%ebx
f01035b6:	89 48 44             	mov    %ecx,0x44(%eax)
		envs[i].env_id = 0;	
f01035b9:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f01035c0:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f01035c7:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f01035ca:	89 d9                	mov    %ebx,%ecx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV-1; i >=0 ; i--){
f01035cc:	83 ea 01             	sub    $0x1,%edx
f01035cf:	75 e3                	jne    f01035b4 <env_init+0x1c>
f01035d1:	89 35 4c 72 22 f0    	mov    %esi,0xf022724c
		env_free_list = &envs[i];
		
	}
//	panic("");
	// Per-CPU part of the initialization
	env_init_percpu();
f01035d7:	e8 92 ff ff ff       	call   f010356e <env_init_percpu>
}
f01035dc:	5b                   	pop    %ebx
f01035dd:	5e                   	pop    %esi
f01035de:	5d                   	pop    %ebp
f01035df:	c3                   	ret    

f01035e0 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01035e0:	55                   	push   %ebp
f01035e1:	89 e5                	mov    %esp,%ebp
f01035e3:	56                   	push   %esi
f01035e4:	53                   	push   %ebx
f01035e5:	83 ec 10             	sub    $0x10,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01035e8:	8b 1d 4c 72 22 f0    	mov    0xf022724c,%ebx
f01035ee:	85 db                	test   %ebx,%ebx
f01035f0:	0f 84 a7 01 00 00    	je     f010379d <env_alloc+0x1bd>
{
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01035f6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01035fd:	e8 3d dc ff ff       	call   f010123f <page_alloc>
f0103602:	89 c6                	mov    %eax,%esi
f0103604:	85 c0                	test   %eax,%eax
f0103606:	0f 84 98 01 00 00    	je     f01037a4 <env_alloc+0x1c4>
f010360c:	2b 05 90 7e 22 f0    	sub    0xf0227e90,%eax
f0103612:	c1 f8 03             	sar    $0x3,%eax
f0103615:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103618:	89 c2                	mov    %eax,%edx
f010361a:	c1 ea 0c             	shr    $0xc,%edx
f010361d:	3b 15 88 7e 22 f0    	cmp    0xf0227e88,%edx
f0103623:	72 20                	jb     f0103645 <env_alloc+0x65>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103625:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103629:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0103630:	f0 
f0103631:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103638:	00 
f0103639:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0103640:	e8 fb c9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103645:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	/* e->env_pgdir is a pte_t* */
	e -> env_pgdir = page2kva(p);
f010364a:	89 43 60             	mov    %eax,0x60(%ebx)

	memmove(e -> env_pgdir , kern_pgdir, PGSIZE);
f010364d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103654:	00 
f0103655:	8b 15 8c 7e 22 f0    	mov    0xf0227e8c,%edx
f010365b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010365f:	89 04 24             	mov    %eax,(%esp)
f0103662:	e8 1c 25 00 00       	call   f0105b83 <memmove>
	memset(e -> env_pgdir, 0 , PDX(UTOP)*sizeof(pde_t));
f0103667:	c7 44 24 08 ec 0e 00 	movl   $0xeec,0x8(%esp)
f010366e:	00 
f010366f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103676:	00 
f0103677:	8b 43 60             	mov    0x60(%ebx),%eax
f010367a:	89 04 24             	mov    %eax,(%esp)
f010367d:	e8 a3 24 00 00       	call   f0105b25 <memset>

	p -> pp_ref++;
f0103682:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103687:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010368a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010368f:	77 20                	ja     f01036b1 <env_alloc+0xd1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103691:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103695:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f010369c:	f0 
f010369d:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
f01036a4:	00 
f01036a5:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f01036ac:	e8 8f c9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036b1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01036b7:	83 ca 05             	or     $0x5,%edx
f01036ba:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01036c0:	8b 43 48             	mov    0x48(%ebx),%eax
f01036c3:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01036c8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01036cd:	ba 00 10 00 00       	mov    $0x1000,%edx
f01036d2:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01036d5:	89 da                	mov    %ebx,%edx
f01036d7:	2b 15 48 72 22 f0    	sub    0xf0227248,%edx
f01036dd:	c1 fa 02             	sar    $0x2,%edx
f01036e0:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01036e6:	09 d0                	or     %edx,%eax
f01036e8:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01036eb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036ee:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01036f1:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01036f8:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01036ff:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103706:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f010370d:	00 
f010370e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103715:	00 
f0103716:	89 1c 24             	mov    %ebx,(%esp)
f0103719:	e8 07 24 00 00       	call   f0105b25 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010371e:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103724:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010372a:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103730:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103737:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f010373d:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103744:	c7 43 68 00 00 00 00 	movl   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f010374b:	8b 43 44             	mov    0x44(%ebx),%eax
f010374e:	a3 4c 72 22 f0       	mov    %eax,0xf022724c
	*newenv_store = e;
f0103753:	8b 45 08             	mov    0x8(%ebp),%eax
f0103756:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103758:	8b 5b 48             	mov    0x48(%ebx),%ebx
f010375b:	e8 6c 2a 00 00       	call   f01061cc <cpunum>
f0103760:	6b c0 74             	imul   $0x74,%eax,%eax
f0103763:	ba 00 00 00 00       	mov    $0x0,%edx
f0103768:	83 b8 28 80 22 f0 00 	cmpl   $0x0,-0xfdd7fd8(%eax)
f010376f:	74 11                	je     f0103782 <env_alloc+0x1a2>
f0103771:	e8 56 2a 00 00       	call   f01061cc <cpunum>
f0103776:	6b c0 74             	imul   $0x74,%eax,%eax
f0103779:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f010377f:	8b 50 48             	mov    0x48(%eax),%edx
f0103782:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103786:	89 54 24 04          	mov    %edx,0x4(%esp)
f010378a:	c7 04 24 07 79 10 f0 	movl   $0xf0107907,(%esp)
f0103791:	e8 28 06 00 00       	call   f0103dbe <cprintf>
	return 0;
f0103796:	b8 00 00 00 00       	mov    $0x0,%eax
f010379b:	eb 0c                	jmp    f01037a9 <env_alloc+0x1c9>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010379d:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01037a2:	eb 05                	jmp    f01037a9 <env_alloc+0x1c9>
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01037a4:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01037a9:	83 c4 10             	add    $0x10,%esp
f01037ac:	5b                   	pop    %ebx
f01037ad:	5e                   	pop    %esi
f01037ae:	5d                   	pop    %ebp
f01037af:	c3                   	ret    

f01037b0 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size, enum EnvType type)
{
f01037b0:	55                   	push   %ebp
f01037b1:	89 e5                	mov    %esp,%ebp
f01037b3:	57                   	push   %edi
f01037b4:	56                   	push   %esi
f01037b5:	53                   	push   %ebx
f01037b6:	83 ec 3c             	sub    $0x3c,%esp
f01037b9:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;

	if((r = env_alloc(&e, 0)) < 0)
f01037bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01037c3:	00 
f01037c4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01037c7:	89 04 24             	mov    %eax,(%esp)
f01037ca:	e8 11 fe ff ff       	call   f01035e0 <env_alloc>
f01037cf:	85 c0                	test   %eax,%eax
f01037d1:	79 20                	jns    f01037f3 <env_create+0x43>
		panic("env alloc failed! %e\n",r);
f01037d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01037d7:	c7 44 24 08 1c 79 10 	movl   $0xf010791c,0x8(%esp)
f01037de:	f0 
f01037df:	c7 44 24 04 a3 01 00 	movl   $0x1a3,0x4(%esp)
f01037e6:	00 
f01037e7:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f01037ee:	e8 4d c8 ff ff       	call   f0100040 <_panic>
	/* load_icode(struct Env *e, uint8_t *binary, size_t size) */
	load_icode(e, binary, size);
f01037f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037f6:	89 45 d4             	mov    %eax,-0x2c(%ebp)

static __inline uint32_t
rcr3(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr3,%0" : "=r" (val));
f01037f9:	0f 20 da             	mov    %cr3,%edx
f01037fc:	89 55 d0             	mov    %edx,-0x30(%ebp)
	struct Proghdr *ph, *eph; /* see inc/elf.h */
	struct Elf *ELFHDR = (struct Elf *)binary;
	uint32_t cr3 = rcr3();

	/* just copy from boot/main.c */
	if (ELFHDR->e_magic != ELF_MAGIC)
f01037ff:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103805:	74 1c                	je     f0103823 <env_create+0x73>
		panic("Invalid ELF!\n");
f0103807:	c7 44 24 08 32 79 10 	movl   $0xf0107932,0x8(%esp)
f010380e:	f0 
f010380f:	c7 44 24 04 74 01 00 	movl   $0x174,0x4(%esp)
f0103816:	00 
f0103817:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f010381e:	e8 1d c8 ff ff       	call   f0100040 <_panic>
	lcr3(PADDR(e -> env_pgdir));
f0103823:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103826:	8b 42 60             	mov    0x60(%edx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103829:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010382e:	77 20                	ja     f0103850 <env_create+0xa0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103830:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103834:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f010383b:	f0 
f010383c:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
f0103843:	00 
f0103844:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f010384b:	e8 f0 c7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103850:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103855:	0f 22 d8             	mov    %eax,%cr3
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0103858:	89 fb                	mov    %edi,%ebx
f010385a:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f010385d:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103861:	c1 e6 05             	shl    $0x5,%esi
f0103864:	01 de                	add    %ebx,%esi

	for (; ph < eph; ph++){
f0103866:	39 f3                	cmp    %esi,%ebx
f0103868:	73 4f                	jae    f01038b9 <env_create+0x109>
		// p_pa is the load address of this segment (as well
		// as the physical address)
		if( ph->p_type == ELF_PROG_LOAD ){
f010386a:	83 3b 01             	cmpl   $0x1,(%ebx)
f010386d:	75 43                	jne    f01038b2 <env_create+0x102>
			/* alloc p_memsz physical memory for e*/
			region_alloc(e, (void *)ph -> p_va, ph -> p_memsz); 
f010386f:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103872:	8b 53 08             	mov    0x8(%ebx),%edx
f0103875:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103878:	e8 8b fb ff ff       	call   f0103408 <region_alloc>
			/* set zero filled */
			//panic("%x", ph);
			memset((void *)ph->p_va, 0x0 , ph->p_memsz);
f010387d:	8b 43 14             	mov    0x14(%ebx),%eax
f0103880:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103884:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010388b:	00 
f010388c:	8b 43 08             	mov    0x8(%ebx),%eax
f010388f:	89 04 24             	mov    %eax,(%esp)
f0103892:	e8 8e 22 00 00       	call   f0105b25 <memset>
			/* inc/string.h : void * memmove(void *dst, const void *src, size_t len); */
			memmove((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0103897:	8b 43 10             	mov    0x10(%ebx),%eax
f010389a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010389e:	89 f8                	mov    %edi,%eax
f01038a0:	03 43 04             	add    0x4(%ebx),%eax
f01038a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038a7:	8b 43 08             	mov    0x8(%ebx),%eax
f01038aa:	89 04 24             	mov    %eax,(%esp)
f01038ad:	e8 d1 22 00 00       	call   f0105b83 <memmove>
		panic("Invalid ELF!\n");
	lcr3(PADDR(e -> env_pgdir));
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;

	for (; ph < eph; ph++){
f01038b2:	83 c3 20             	add    $0x20,%ebx
f01038b5:	39 de                	cmp    %ebx,%esi
f01038b7:	77 b1                	ja     f010386a <env_create+0xba>
		}

	}
	//((void (*)(void)) (ELFHDR->e_entry))();

	e -> env_tf.tf_eip = ELFHDR -> e_entry;
f01038b9:	8b 47 18             	mov    0x18(%edi),%eax
f01038bc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01038bf:	89 42 30             	mov    %eax,0x30(%edx)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
f01038c2:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01038c7:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01038cc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01038cf:	e8 34 fb ff ff       	call   f0103408 <region_alloc>
f01038d4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01038d7:	0f 22 d8             	mov    %eax,%cr3

	if((r = env_alloc(&e, 0)) < 0)
		panic("env alloc failed! %e\n",r);
	/* load_icode(struct Env *e, uint8_t *binary, size_t size) */
	load_icode(e, binary, size);
	e -> env_type = type;
f01038da:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038dd:	8b 55 10             	mov    0x10(%ebp),%edx
f01038e0:	89 50 50             	mov    %edx,0x50(%eax)
}
f01038e3:	83 c4 3c             	add    $0x3c,%esp
f01038e6:	5b                   	pop    %ebx
f01038e7:	5e                   	pop    %esi
f01038e8:	5f                   	pop    %edi
f01038e9:	5d                   	pop    %ebp
f01038ea:	c3                   	ret    

f01038eb <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01038eb:	55                   	push   %ebp
f01038ec:	89 e5                	mov    %esp,%ebp
f01038ee:	57                   	push   %edi
f01038ef:	56                   	push   %esi
f01038f0:	53                   	push   %ebx
f01038f1:	83 ec 2c             	sub    $0x2c,%esp
f01038f4:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01038f7:	e8 d0 28 00 00       	call   f01061cc <cpunum>
f01038fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01038ff:	39 b8 28 80 22 f0    	cmp    %edi,-0xfdd7fd8(%eax)
f0103905:	75 34                	jne    f010393b <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103907:	a1 8c 7e 22 f0       	mov    0xf0227e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010390c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103911:	77 20                	ja     f0103933 <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103913:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103917:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f010391e:	f0 
f010391f:	c7 44 24 04 b7 01 00 	movl   $0x1b7,0x4(%esp)
f0103926:	00 
f0103927:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f010392e:	e8 0d c7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103933:	05 00 00 00 10       	add    $0x10000000,%eax
f0103938:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010393b:	8b 5f 48             	mov    0x48(%edi),%ebx
f010393e:	e8 89 28 00 00       	call   f01061cc <cpunum>
f0103943:	6b d0 74             	imul   $0x74,%eax,%edx
f0103946:	b8 00 00 00 00       	mov    $0x0,%eax
f010394b:	83 ba 28 80 22 f0 00 	cmpl   $0x0,-0xfdd7fd8(%edx)
f0103952:	74 11                	je     f0103965 <env_free+0x7a>
f0103954:	e8 73 28 00 00       	call   f01061cc <cpunum>
f0103959:	6b c0 74             	imul   $0x74,%eax,%eax
f010395c:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0103962:	8b 40 48             	mov    0x48(%eax),%eax
f0103965:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103969:	89 44 24 04          	mov    %eax,0x4(%esp)
f010396d:	c7 04 24 40 79 10 f0 	movl   $0xf0107940,(%esp)
f0103974:	e8 45 04 00 00       	call   f0103dbe <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103979:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
f0103980:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103983:	c1 e0 02             	shl    $0x2,%eax
f0103986:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103989:	8b 47 60             	mov    0x60(%edi),%eax
f010398c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010398f:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103992:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103998:	0f 84 b7 00 00 00    	je     f0103a55 <env_free+0x16a>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010399e:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01039a4:	89 f0                	mov    %esi,%eax
f01039a6:	c1 e8 0c             	shr    $0xc,%eax
f01039a9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01039ac:	3b 05 88 7e 22 f0    	cmp    0xf0227e88,%eax
f01039b2:	72 20                	jb     f01039d4 <env_free+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01039b4:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01039b8:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f01039bf:	f0 
f01039c0:	c7 44 24 04 c6 01 00 	movl   $0x1c6,0x4(%esp)
f01039c7:	00 
f01039c8:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f01039cf:	e8 6c c6 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01039d4:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01039d7:	c1 e2 16             	shl    $0x16,%edx
f01039da:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01039dd:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01039e2:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01039e9:	01 
f01039ea:	74 17                	je     f0103a03 <env_free+0x118>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01039ec:	89 d8                	mov    %ebx,%eax
f01039ee:	c1 e0 0c             	shl    $0xc,%eax
f01039f1:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01039f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039f8:	8b 47 60             	mov    0x60(%edi),%eax
f01039fb:	89 04 24             	mov    %eax,(%esp)
f01039fe:	e8 f4 da ff ff       	call   f01014f7 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103a03:	83 c3 01             	add    $0x1,%ebx
f0103a06:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103a0c:	75 d4                	jne    f01039e2 <env_free+0xf7>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103a0e:	8b 47 60             	mov    0x60(%edi),%eax
f0103a11:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103a14:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103a1b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103a1e:	3b 05 88 7e 22 f0    	cmp    0xf0227e88,%eax
f0103a24:	72 1c                	jb     f0103a42 <env_free+0x157>
		panic("pa2page called with invalid pa");
f0103a26:	c7 44 24 08 a0 6f 10 	movl   $0xf0106fa0,0x8(%esp)
f0103a2d:	f0 
f0103a2e:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103a35:	00 
f0103a36:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0103a3d:	e8 fe c5 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103a42:	a1 90 7e 22 f0       	mov    0xf0227e90,%eax
f0103a47:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103a4a:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103a4d:	89 04 24             	mov    %eax,(%esp)
f0103a50:	e8 8a d8 ff ff       	call   f01012df <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103a55:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103a59:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103a60:	0f 85 1a ff ff ff    	jne    f0103980 <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103a66:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103a69:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103a6e:	77 20                	ja     f0103a90 <env_free+0x1a5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a70:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a74:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f0103a7b:	f0 
f0103a7c:	c7 44 24 04 d4 01 00 	movl   $0x1d4,0x4(%esp)
f0103a83:	00 
f0103a84:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f0103a8b:	e8 b0 c5 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103a90:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103a97:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103a9c:	c1 e8 0c             	shr    $0xc,%eax
f0103a9f:	3b 05 88 7e 22 f0    	cmp    0xf0227e88,%eax
f0103aa5:	72 1c                	jb     f0103ac3 <env_free+0x1d8>
		panic("pa2page called with invalid pa");
f0103aa7:	c7 44 24 08 a0 6f 10 	movl   $0xf0106fa0,0x8(%esp)
f0103aae:	f0 
f0103aaf:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103ab6:	00 
f0103ab7:	c7 04 24 fa 75 10 f0 	movl   $0xf01075fa,(%esp)
f0103abe:	e8 7d c5 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103ac3:	8b 15 90 7e 22 f0    	mov    0xf0227e90,%edx
f0103ac9:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103acc:	89 04 24             	mov    %eax,(%esp)
f0103acf:	e8 0b d8 ff ff       	call   f01012df <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103ad4:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103adb:	a1 4c 72 22 f0       	mov    0xf022724c,%eax
f0103ae0:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103ae3:	89 3d 4c 72 22 f0    	mov    %edi,0xf022724c
}
f0103ae9:	83 c4 2c             	add    $0x2c,%esp
f0103aec:	5b                   	pop    %ebx
f0103aed:	5e                   	pop    %esi
f0103aee:	5f                   	pop    %edi
f0103aef:	5d                   	pop    %ebp
f0103af0:	c3                   	ret    

f0103af1 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103af1:	55                   	push   %ebp
f0103af2:	89 e5                	mov    %esp,%ebp
f0103af4:	53                   	push   %ebx
f0103af5:	83 ec 14             	sub    $0x14,%esp
f0103af8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103afb:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103aff:	75 19                	jne    f0103b1a <env_destroy+0x29>
f0103b01:	e8 c6 26 00 00       	call   f01061cc <cpunum>
f0103b06:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b09:	39 98 28 80 22 f0    	cmp    %ebx,-0xfdd7fd8(%eax)
f0103b0f:	74 09                	je     f0103b1a <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103b11:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103b18:	eb 2f                	jmp    f0103b49 <env_destroy+0x58>
	}

	env_free(e);
f0103b1a:	89 1c 24             	mov    %ebx,(%esp)
f0103b1d:	e8 c9 fd ff ff       	call   f01038eb <env_free>

	if (curenv == e) {
f0103b22:	e8 a5 26 00 00       	call   f01061cc <cpunum>
f0103b27:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b2a:	39 98 28 80 22 f0    	cmp    %ebx,-0xfdd7fd8(%eax)
f0103b30:	75 17                	jne    f0103b49 <env_destroy+0x58>
		curenv = NULL;
f0103b32:	e8 95 26 00 00       	call   f01061cc <cpunum>
f0103b37:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b3a:	c7 80 28 80 22 f0 00 	movl   $0x0,-0xfdd7fd8(%eax)
f0103b41:	00 00 00 
		sched_yield();
f0103b44:	e8 53 0d 00 00       	call   f010489c <sched_yield>
	}
}
f0103b49:	83 c4 14             	add    $0x14,%esp
f0103b4c:	5b                   	pop    %ebx
f0103b4d:	5d                   	pop    %ebp
f0103b4e:	c3                   	ret    

f0103b4f <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103b4f:	55                   	push   %ebp
f0103b50:	89 e5                	mov    %esp,%ebp
f0103b52:	53                   	push   %ebx
f0103b53:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103b56:	e8 71 26 00 00       	call   f01061cc <cpunum>
f0103b5b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b5e:	8b 98 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%ebx
f0103b64:	e8 63 26 00 00       	call   f01061cc <cpunum>
f0103b69:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103b6c:	8b 65 08             	mov    0x8(%ebp),%esp
f0103b6f:	61                   	popa   
f0103b70:	07                   	pop    %es
f0103b71:	1f                   	pop    %ds
f0103b72:	83 c4 08             	add    $0x8,%esp
f0103b75:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103b76:	c7 44 24 08 56 79 10 	movl   $0xf0107956,0x8(%esp)
f0103b7d:	f0 
f0103b7e:	c7 44 24 04 0a 02 00 	movl   $0x20a,0x4(%esp)
f0103b85:	00 
f0103b86:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f0103b8d:	e8 ae c4 ff ff       	call   f0100040 <_panic>

f0103b92 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103b92:	55                   	push   %ebp
f0103b93:	89 e5                	mov    %esp,%ebp
f0103b95:	53                   	push   %ebx
f0103b96:	83 ec 14             	sub    $0x14,%esp
f0103b99:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL)
f0103b9c:	e8 2b 26 00 00       	call   f01061cc <cpunum>
f0103ba1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ba4:	83 b8 28 80 22 f0 00 	cmpl   $0x0,-0xfdd7fd8(%eax)
f0103bab:	74 15                	je     f0103bc2 <env_run+0x30>
		curenv -> env_status = ENV_RUNNABLE;
f0103bad:	e8 1a 26 00 00       	call   f01061cc <cpunum>
f0103bb2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bb5:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0103bbb:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)

	curenv = e;
f0103bc2:	e8 05 26 00 00       	call   f01061cc <cpunum>
f0103bc7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bca:	89 98 28 80 22 f0    	mov    %ebx,-0xfdd7fd8(%eax)
	curenv -> env_status = ENV_RUNNING;
f0103bd0:	e8 f7 25 00 00       	call   f01061cc <cpunum>
f0103bd5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bd8:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0103bde:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv -> env_runs++;
f0103be5:	e8 e2 25 00 00       	call   f01061cc <cpunum>
f0103bea:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bed:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0103bf3:	83 40 58 01          	addl   $0x1,0x58(%eax)
	//cprintf("cpu %d curenv.pgdir: %x\n", cpunum(), curenv -> env_pgdir);
	lcr3(PADDR(curenv -> env_pgdir));
f0103bf7:	e8 d0 25 00 00       	call   f01061cc <cpunum>
f0103bfc:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bff:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0103c05:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103c08:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103c0d:	77 20                	ja     f0103c2f <env_run+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103c0f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c13:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f0103c1a:	f0 
f0103c1b:	c7 44 24 04 2f 02 00 	movl   $0x22f,0x4(%esp)
f0103c22:	00 
f0103c23:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f0103c2a:	e8 11 c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103c2f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103c34:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103c37:	c7 04 24 a0 13 12 f0 	movl   $0xf01213a0,(%esp)
f0103c3e:	e8 f2 28 00 00       	call   f0106535 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103c43:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&(e -> env_tf));
f0103c45:	89 1c 24             	mov    %ebx,(%esp)
f0103c48:	e8 02 ff ff ff       	call   f0103b4f <env_pop_tf>
f0103c4d:	66 90                	xchg   %ax,%ax
f0103c4f:	90                   	nop

f0103c50 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103c50:	55                   	push   %ebp
f0103c51:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103c53:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103c57:	ba 70 00 00 00       	mov    $0x70,%edx
f0103c5c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103c5d:	b2 71                	mov    $0x71,%dl
f0103c5f:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103c60:	0f b6 c0             	movzbl %al,%eax
}
f0103c63:	5d                   	pop    %ebp
f0103c64:	c3                   	ret    

f0103c65 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103c65:	55                   	push   %ebp
f0103c66:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103c68:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103c6c:	ba 70 00 00 00       	mov    $0x70,%edx
f0103c71:	ee                   	out    %al,(%dx)
f0103c72:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0103c76:	b2 71                	mov    $0x71,%dl
f0103c78:	ee                   	out    %al,(%dx)
f0103c79:	5d                   	pop    %ebp
f0103c7a:	c3                   	ret    
f0103c7b:	90                   	nop

f0103c7c <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103c7c:	55                   	push   %ebp
f0103c7d:	89 e5                	mov    %esp,%ebp
f0103c7f:	56                   	push   %esi
f0103c80:	53                   	push   %ebx
f0103c81:	83 ec 10             	sub    $0x10,%esp
f0103c84:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103c87:	66 a3 88 13 12 f0    	mov    %ax,0xf0121388
	if (!didinit)
f0103c8d:	83 3d 50 72 22 f0 00 	cmpl   $0x0,0xf0227250
f0103c94:	74 4e                	je     f0103ce4 <irq_setmask_8259A+0x68>
f0103c96:	89 c6                	mov    %eax,%esi
f0103c98:	ba 21 00 00 00       	mov    $0x21,%edx
f0103c9d:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103c9e:	66 c1 e8 08          	shr    $0x8,%ax
f0103ca2:	b2 a1                	mov    $0xa1,%dl
f0103ca4:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103ca5:	c7 04 24 62 79 10 f0 	movl   $0xf0107962,(%esp)
f0103cac:	e8 0d 01 00 00       	call   f0103dbe <cprintf>
	for (i = 0; i < 16; i++)
f0103cb1:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103cb6:	0f b7 f6             	movzwl %si,%esi
f0103cb9:	f7 d6                	not    %esi
f0103cbb:	0f a3 de             	bt     %ebx,%esi
f0103cbe:	73 10                	jae    f0103cd0 <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0103cc0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103cc4:	c7 04 24 63 7e 10 f0 	movl   $0xf0107e63,(%esp)
f0103ccb:	e8 ee 00 00 00       	call   f0103dbe <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103cd0:	83 c3 01             	add    $0x1,%ebx
f0103cd3:	83 fb 10             	cmp    $0x10,%ebx
f0103cd6:	75 e3                	jne    f0103cbb <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103cd8:	c7 04 24 f8 75 10 f0 	movl   $0xf01075f8,(%esp)
f0103cdf:	e8 da 00 00 00       	call   f0103dbe <cprintf>
}
f0103ce4:	83 c4 10             	add    $0x10,%esp
f0103ce7:	5b                   	pop    %ebx
f0103ce8:	5e                   	pop    %esi
f0103ce9:	5d                   	pop    %ebp
f0103cea:	c3                   	ret    

f0103ceb <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103ceb:	c7 05 50 72 22 f0 01 	movl   $0x1,0xf0227250
f0103cf2:	00 00 00 
f0103cf5:	ba 21 00 00 00       	mov    $0x21,%edx
f0103cfa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103cff:	ee                   	out    %al,(%dx)
f0103d00:	b2 a1                	mov    $0xa1,%dl
f0103d02:	ee                   	out    %al,(%dx)
f0103d03:	b2 20                	mov    $0x20,%dl
f0103d05:	b8 11 00 00 00       	mov    $0x11,%eax
f0103d0a:	ee                   	out    %al,(%dx)
f0103d0b:	b2 21                	mov    $0x21,%dl
f0103d0d:	b8 20 00 00 00       	mov    $0x20,%eax
f0103d12:	ee                   	out    %al,(%dx)
f0103d13:	b8 04 00 00 00       	mov    $0x4,%eax
f0103d18:	ee                   	out    %al,(%dx)
f0103d19:	b8 03 00 00 00       	mov    $0x3,%eax
f0103d1e:	ee                   	out    %al,(%dx)
f0103d1f:	b2 a0                	mov    $0xa0,%dl
f0103d21:	b8 11 00 00 00       	mov    $0x11,%eax
f0103d26:	ee                   	out    %al,(%dx)
f0103d27:	b2 a1                	mov    $0xa1,%dl
f0103d29:	b8 28 00 00 00       	mov    $0x28,%eax
f0103d2e:	ee                   	out    %al,(%dx)
f0103d2f:	b8 02 00 00 00       	mov    $0x2,%eax
f0103d34:	ee                   	out    %al,(%dx)
f0103d35:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d3a:	ee                   	out    %al,(%dx)
f0103d3b:	b2 20                	mov    $0x20,%dl
f0103d3d:	b8 68 00 00 00       	mov    $0x68,%eax
f0103d42:	ee                   	out    %al,(%dx)
f0103d43:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d48:	ee                   	out    %al,(%dx)
f0103d49:	b2 a0                	mov    $0xa0,%dl
f0103d4b:	b8 68 00 00 00       	mov    $0x68,%eax
f0103d50:	ee                   	out    %al,(%dx)
f0103d51:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d56:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103d57:	0f b7 05 88 13 12 f0 	movzwl 0xf0121388,%eax
f0103d5e:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103d62:	74 12                	je     f0103d76 <pic_init+0x8b>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103d64:	55                   	push   %ebp
f0103d65:	89 e5                	mov    %esp,%ebp
f0103d67:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103d6a:	0f b7 c0             	movzwl %ax,%eax
f0103d6d:	89 04 24             	mov    %eax,(%esp)
f0103d70:	e8 07 ff ff ff       	call   f0103c7c <irq_setmask_8259A>
}
f0103d75:	c9                   	leave  
f0103d76:	f3 c3                	repz ret 

f0103d78 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103d78:	55                   	push   %ebp
f0103d79:	89 e5                	mov    %esp,%ebp
f0103d7b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103d7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d81:	89 04 24             	mov    %eax,(%esp)
f0103d84:	e8 2c cb ff ff       	call   f01008b5 <cputchar>
	*cnt++;
}
f0103d89:	c9                   	leave  
f0103d8a:	c3                   	ret    

f0103d8b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103d8b:	55                   	push   %ebp
f0103d8c:	89 e5                	mov    %esp,%ebp
f0103d8e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103d91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103d98:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d9b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103da2:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103da6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103da9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dad:	c7 04 24 78 3d 10 f0 	movl   $0xf0103d78,(%esp)
f0103db4:	e8 09 16 00 00       	call   f01053c2 <vprintfmt>
	return cnt;
}
f0103db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103dbc:	c9                   	leave  
f0103dbd:	c3                   	ret    

f0103dbe <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103dbe:	55                   	push   %ebp
f0103dbf:	89 e5                	mov    %esp,%ebp
f0103dc1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103dc4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103dc7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dcb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dce:	89 04 24             	mov    %eax,(%esp)
f0103dd1:	e8 b5 ff ff ff       	call   f0103d8b <vcprintf>
	va_end(ap);

	return cnt;
}
f0103dd6:	c9                   	leave  
f0103dd7:	c3                   	ret    
f0103dd8:	66 90                	xchg   %ax,%ax
f0103dda:	66 90                	xchg   %ax,%ax
f0103ddc:	66 90                	xchg   %ax,%ax
f0103dde:	66 90                	xchg   %ax,%ax

f0103de0 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103de0:	55                   	push   %ebp
f0103de1:	89 e5                	mov    %esp,%ebp
f0103de3:	57                   	push   %edi
f0103de4:	56                   	push   %esi
f0103de5:	53                   	push   %ebx
f0103de6:	83 ec 1c             	sub    $0x1c,%esp

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint8_t cpuid;
	//for(; i < NCPU; i++){
	cpuid = thiscpu -> cpu_id;
f0103de9:	e8 de 23 00 00       	call   f01061cc <cpunum>
f0103dee:	6b c0 74             	imul   $0x74,%eax,%eax
f0103df1:	0f b6 98 20 80 22 f0 	movzbl -0xfdd7fe0(%eax),%ebx
	thiscpu -> cpu_ts = thiscpu -> cpu_ts;
f0103df8:	e8 cf 23 00 00       	call   f01061cc <cpunum>
f0103dfd:	89 c7                	mov    %eax,%edi
f0103dff:	e8 c8 23 00 00       	call   f01061cc <cpunum>
f0103e04:	6b ff 74             	imul   $0x74,%edi,%edi
f0103e07:	6b f0 74             	imul   $0x74,%eax,%esi
f0103e0a:	81 c7 2c 80 22 f0    	add    $0xf022802c,%edi
f0103e10:	81 c6 2c 80 22 f0    	add    $0xf022802c,%esi
f0103e16:	b9 1a 00 00 00       	mov    $0x1a,%ecx
f0103e1b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	thiscpu -> cpu_ts.ts_esp0 = KSTACKTOP - cpuid * (KSTKSIZE + KSTKGAP);
f0103e1d:	e8 aa 23 00 00       	call   f01061cc <cpunum>
f0103e22:	0f b6 f3             	movzbl %bl,%esi
f0103e25:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e28:	89 f2                	mov    %esi,%edx
f0103e2a:	f7 da                	neg    %edx
f0103e2c:	c1 e2 10             	shl    $0x10,%edx
f0103e2f:	81 ea 00 00 40 10    	sub    $0x10400000,%edx
f0103e35:	89 90 30 80 22 f0    	mov    %edx,-0xfdd7fd0(%eax)
	thiscpu -> cpu_ts.ts_ss0 = GD_KD;
f0103e3b:	e8 8c 23 00 00       	call   f01061cc <cpunum>
f0103e40:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e43:	66 c7 80 34 80 22 f0 	movw   $0x10,-0xfdd7fcc(%eax)
f0103e4a:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + cpuid] = SEG16(STS_T32A, (uint32_t) (&(thiscpu -> cpu_ts)),
f0103e4c:	83 c6 05             	add    $0x5,%esi
f0103e4f:	e8 78 23 00 00       	call   f01061cc <cpunum>
f0103e54:	89 c7                	mov    %eax,%edi
f0103e56:	e8 71 23 00 00       	call   f01061cc <cpunum>
f0103e5b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103e5e:	e8 69 23 00 00       	call   f01061cc <cpunum>
f0103e63:	66 c7 04 f5 20 13 12 	movw   $0x68,-0xfedece0(,%esi,8)
f0103e6a:	f0 68 00 
f0103e6d:	6b ff 74             	imul   $0x74,%edi,%edi
f0103e70:	81 c7 2c 80 22 f0    	add    $0xf022802c,%edi
f0103e76:	66 89 3c f5 22 13 12 	mov    %di,-0xfedecde(,%esi,8)
f0103e7d:	f0 
f0103e7e:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103e82:	81 c2 2c 80 22 f0    	add    $0xf022802c,%edx
f0103e88:	c1 ea 10             	shr    $0x10,%edx
f0103e8b:	88 14 f5 24 13 12 f0 	mov    %dl,-0xfedecdc(,%esi,8)
f0103e92:	c6 04 f5 26 13 12 f0 	movb   $0x40,-0xfedecda(,%esi,8)
f0103e99:	40 
f0103e9a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e9d:	05 2c 80 22 f0       	add    $0xf022802c,%eax
f0103ea2:	c1 e8 18             	shr    $0x18,%eax
f0103ea5:	88 04 f5 27 13 12 f0 	mov    %al,-0xfedecd9(,%esi,8)
					sizeof(struct Taskstate), 0);
	gdt[(GD_TSS0 >> 3) + cpuid].sd_s = 0;
f0103eac:	c6 04 f5 25 13 12 f0 	movb   $0x89,-0xfedecdb(,%esi,8)
f0103eb3:	89 



	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (cpuid << 3));
f0103eb4:	0f b6 db             	movzbl %bl,%ebx
f0103eb7:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103ebe:	0f 00 db             	ltr    %bx
}  

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103ec1:	b8 8c 13 12 f0       	mov    $0xf012138c,%eax
f0103ec6:	0f 01 18             	lidtl  (%eax)
// cprintf("thiscpu %d\n", thiscpu->cpu_id);
	// Load the IDT
	lidt(&idt_pd);
	// panic("");
	//}
}
f0103ec9:	83 c4 1c             	add    $0x1c,%esp
f0103ecc:	5b                   	pop    %ebx
f0103ecd:	5e                   	pop    %esi
f0103ece:	5f                   	pop    %edi
f0103ecf:	5d                   	pop    %ebp
f0103ed0:	c3                   	ret    

f0103ed1 <trap_init>:
}


void
trap_init(void)
{
f0103ed1:	55                   	push   %ebp
f0103ed2:	89 e5                	mov    %esp,%ebp
f0103ed4:	83 ec 08             	sub    $0x8,%esp
	extern void Machine_Check();
	extern void SIMD_Floating_Point_Exception();
	extern void System_call();

	/* SETGATE(Gatedesc, istrap[1/0], sel, off, dpl) -- inc/mmu.h*/
	SETGATE(idt[T_DIVIDE] ,0, GD_KT, Divide_error, 0);
f0103ed7:	b8 1c 48 10 f0       	mov    $0xf010481c,%eax
f0103edc:	66 a3 60 72 22 f0    	mov    %ax,0xf0227260
f0103ee2:	66 c7 05 62 72 22 f0 	movw   $0x8,0xf0227262
f0103ee9:	08 00 
f0103eeb:	c6 05 64 72 22 f0 00 	movb   $0x0,0xf0227264
f0103ef2:	c6 05 65 72 22 f0 8e 	movb   $0x8e,0xf0227265
f0103ef9:	c1 e8 10             	shr    $0x10,%eax
f0103efc:	66 a3 66 72 22 f0    	mov    %ax,0xf0227266
	SETGATE(idt[T_DEBUG] ,0, GD_KT, Debug, 0);
f0103f02:	b8 22 48 10 f0       	mov    $0xf0104822,%eax
f0103f07:	66 a3 68 72 22 f0    	mov    %ax,0xf0227268
f0103f0d:	66 c7 05 6a 72 22 f0 	movw   $0x8,0xf022726a
f0103f14:	08 00 
f0103f16:	c6 05 6c 72 22 f0 00 	movb   $0x0,0xf022726c
f0103f1d:	c6 05 6d 72 22 f0 8e 	movb   $0x8e,0xf022726d
f0103f24:	c1 e8 10             	shr    $0x10,%eax
f0103f27:	66 a3 6e 72 22 f0    	mov    %ax,0xf022726e
	SETGATE(idt[T_NMI] ,0, GD_KT, Non_Maskable_Interrupt, 0);
f0103f2d:	b8 28 48 10 f0       	mov    $0xf0104828,%eax
f0103f32:	66 a3 70 72 22 f0    	mov    %ax,0xf0227270
f0103f38:	66 c7 05 72 72 22 f0 	movw   $0x8,0xf0227272
f0103f3f:	08 00 
f0103f41:	c6 05 74 72 22 f0 00 	movb   $0x0,0xf0227274
f0103f48:	c6 05 75 72 22 f0 8e 	movb   $0x8e,0xf0227275
f0103f4f:	c1 e8 10             	shr    $0x10,%eax
f0103f52:	66 a3 76 72 22 f0    	mov    %ax,0xf0227276
	SETGATE(idt[T_BRKPT] ,0, GD_KT, Breakpoint, 3);
f0103f58:	b8 2e 48 10 f0       	mov    $0xf010482e,%eax
f0103f5d:	66 a3 78 72 22 f0    	mov    %ax,0xf0227278
f0103f63:	66 c7 05 7a 72 22 f0 	movw   $0x8,0xf022727a
f0103f6a:	08 00 
f0103f6c:	c6 05 7c 72 22 f0 00 	movb   $0x0,0xf022727c
f0103f73:	c6 05 7d 72 22 f0 ee 	movb   $0xee,0xf022727d
f0103f7a:	c1 e8 10             	shr    $0x10,%eax
f0103f7d:	66 a3 7e 72 22 f0    	mov    %ax,0xf022727e
	SETGATE(idt[T_OFLOW] ,0, GD_KT, Overflow, 0);
f0103f83:	b8 34 48 10 f0       	mov    $0xf0104834,%eax
f0103f88:	66 a3 80 72 22 f0    	mov    %ax,0xf0227280
f0103f8e:	66 c7 05 82 72 22 f0 	movw   $0x8,0xf0227282
f0103f95:	08 00 
f0103f97:	c6 05 84 72 22 f0 00 	movb   $0x0,0xf0227284
f0103f9e:	c6 05 85 72 22 f0 8e 	movb   $0x8e,0xf0227285
f0103fa5:	c1 e8 10             	shr    $0x10,%eax
f0103fa8:	66 a3 86 72 22 f0    	mov    %ax,0xf0227286
	SETGATE(idt[T_BOUND] ,0, GD_KT, BOUND_Range_Exceeded, 0);
f0103fae:	b8 3a 48 10 f0       	mov    $0xf010483a,%eax
f0103fb3:	66 a3 88 72 22 f0    	mov    %ax,0xf0227288
f0103fb9:	66 c7 05 8a 72 22 f0 	movw   $0x8,0xf022728a
f0103fc0:	08 00 
f0103fc2:	c6 05 8c 72 22 f0 00 	movb   $0x0,0xf022728c
f0103fc9:	c6 05 8d 72 22 f0 8e 	movb   $0x8e,0xf022728d
f0103fd0:	c1 e8 10             	shr    $0x10,%eax
f0103fd3:	66 a3 8e 72 22 f0    	mov    %ax,0xf022728e
	SETGATE(idt[T_ILLOP] ,0, GD_KT, Invalid_Opcode, 0);
f0103fd9:	b8 40 48 10 f0       	mov    $0xf0104840,%eax
f0103fde:	66 a3 90 72 22 f0    	mov    %ax,0xf0227290
f0103fe4:	66 c7 05 92 72 22 f0 	movw   $0x8,0xf0227292
f0103feb:	08 00 
f0103fed:	c6 05 94 72 22 f0 00 	movb   $0x0,0xf0227294
f0103ff4:	c6 05 95 72 22 f0 8e 	movb   $0x8e,0xf0227295
f0103ffb:	c1 e8 10             	shr    $0x10,%eax
f0103ffe:	66 a3 96 72 22 f0    	mov    %ax,0xf0227296
	SETGATE(idt[T_DEVICE] ,0, GD_KT, Device_Not_Available, 0);
f0104004:	b8 46 48 10 f0       	mov    $0xf0104846,%eax
f0104009:	66 a3 98 72 22 f0    	mov    %ax,0xf0227298
f010400f:	66 c7 05 9a 72 22 f0 	movw   $0x8,0xf022729a
f0104016:	08 00 
f0104018:	c6 05 9c 72 22 f0 00 	movb   $0x0,0xf022729c
f010401f:	c6 05 9d 72 22 f0 8e 	movb   $0x8e,0xf022729d
f0104026:	c1 e8 10             	shr    $0x10,%eax
f0104029:	66 a3 9e 72 22 f0    	mov    %ax,0xf022729e
	SETGATE(idt[T_DBLFLT] ,0, GD_KT, Double_Fault, 0);
f010402f:	b8 4c 48 10 f0       	mov    $0xf010484c,%eax
f0104034:	66 a3 a0 72 22 f0    	mov    %ax,0xf02272a0
f010403a:	66 c7 05 a2 72 22 f0 	movw   $0x8,0xf02272a2
f0104041:	08 00 
f0104043:	c6 05 a4 72 22 f0 00 	movb   $0x0,0xf02272a4
f010404a:	c6 05 a5 72 22 f0 8e 	movb   $0x8e,0xf02272a5
f0104051:	c1 e8 10             	shr    $0x10,%eax
f0104054:	66 a3 a6 72 22 f0    	mov    %ax,0xf02272a6
	SETGATE(idt[T_TSS] ,0, GD_KT, Invalid_TSS, 0);
f010405a:	b8 50 48 10 f0       	mov    $0xf0104850,%eax
f010405f:	66 a3 b0 72 22 f0    	mov    %ax,0xf02272b0
f0104065:	66 c7 05 b2 72 22 f0 	movw   $0x8,0xf02272b2
f010406c:	08 00 
f010406e:	c6 05 b4 72 22 f0 00 	movb   $0x0,0xf02272b4
f0104075:	c6 05 b5 72 22 f0 8e 	movb   $0x8e,0xf02272b5
f010407c:	c1 e8 10             	shr    $0x10,%eax
f010407f:	66 a3 b6 72 22 f0    	mov    %ax,0xf02272b6
	SETGATE(idt[T_SEGNP] ,0, GD_KT, Segment_Not_Present, 0);
f0104085:	b8 54 48 10 f0       	mov    $0xf0104854,%eax
f010408a:	66 a3 b8 72 22 f0    	mov    %ax,0xf02272b8
f0104090:	66 c7 05 ba 72 22 f0 	movw   $0x8,0xf02272ba
f0104097:	08 00 
f0104099:	c6 05 bc 72 22 f0 00 	movb   $0x0,0xf02272bc
f01040a0:	c6 05 bd 72 22 f0 8e 	movb   $0x8e,0xf02272bd
f01040a7:	c1 e8 10             	shr    $0x10,%eax
f01040aa:	66 a3 be 72 22 f0    	mov    %ax,0xf02272be
	SETGATE(idt[T_STACK] ,0, GD_KT, Stack_Fault, 0);
f01040b0:	b8 58 48 10 f0       	mov    $0xf0104858,%eax
f01040b5:	66 a3 c0 72 22 f0    	mov    %ax,0xf02272c0
f01040bb:	66 c7 05 c2 72 22 f0 	movw   $0x8,0xf02272c2
f01040c2:	08 00 
f01040c4:	c6 05 c4 72 22 f0 00 	movb   $0x0,0xf02272c4
f01040cb:	c6 05 c5 72 22 f0 8e 	movb   $0x8e,0xf02272c5
f01040d2:	c1 e8 10             	shr    $0x10,%eax
f01040d5:	66 a3 c6 72 22 f0    	mov    %ax,0xf02272c6
	SETGATE(idt[T_GPFLT] ,0, GD_KT, General_Protection, 0);
f01040db:	b8 5c 48 10 f0       	mov    $0xf010485c,%eax
f01040e0:	66 a3 c8 72 22 f0    	mov    %ax,0xf02272c8
f01040e6:	66 c7 05 ca 72 22 f0 	movw   $0x8,0xf02272ca
f01040ed:	08 00 
f01040ef:	c6 05 cc 72 22 f0 00 	movb   $0x0,0xf02272cc
f01040f6:	c6 05 cd 72 22 f0 8e 	movb   $0x8e,0xf02272cd
f01040fd:	c1 e8 10             	shr    $0x10,%eax
f0104100:	66 a3 ce 72 22 f0    	mov    %ax,0xf02272ce
	SETGATE(idt[T_PGFLT] ,0, GD_KT, Page_Fault, 0);
f0104106:	b8 60 48 10 f0       	mov    $0xf0104860,%eax
f010410b:	66 a3 d0 72 22 f0    	mov    %ax,0xf02272d0
f0104111:	66 c7 05 d2 72 22 f0 	movw   $0x8,0xf02272d2
f0104118:	08 00 
f010411a:	c6 05 d4 72 22 f0 00 	movb   $0x0,0xf02272d4
f0104121:	c6 05 d5 72 22 f0 8e 	movb   $0x8e,0xf02272d5
f0104128:	c1 e8 10             	shr    $0x10,%eax
f010412b:	66 a3 d6 72 22 f0    	mov    %ax,0xf02272d6
	SETGATE(idt[T_FPERR] ,0, GD_KT, x87_FPU_Floating_Point_Error, 0);
f0104131:	b8 64 48 10 f0       	mov    $0xf0104864,%eax
f0104136:	66 a3 e0 72 22 f0    	mov    %ax,0xf02272e0
f010413c:	66 c7 05 e2 72 22 f0 	movw   $0x8,0xf02272e2
f0104143:	08 00 
f0104145:	c6 05 e4 72 22 f0 00 	movb   $0x0,0xf02272e4
f010414c:	c6 05 e5 72 22 f0 8e 	movb   $0x8e,0xf02272e5
f0104153:	c1 e8 10             	shr    $0x10,%eax
f0104156:	66 a3 e6 72 22 f0    	mov    %ax,0xf02272e6
	SETGATE(idt[T_ALIGN] ,0, GD_KT, Alignment_Check, 0);
f010415c:	b8 6a 48 10 f0       	mov    $0xf010486a,%eax
f0104161:	66 a3 e8 72 22 f0    	mov    %ax,0xf02272e8
f0104167:	66 c7 05 ea 72 22 f0 	movw   $0x8,0xf02272ea
f010416e:	08 00 
f0104170:	c6 05 ec 72 22 f0 00 	movb   $0x0,0xf02272ec
f0104177:	c6 05 ed 72 22 f0 8e 	movb   $0x8e,0xf02272ed
f010417e:	c1 e8 10             	shr    $0x10,%eax
f0104181:	66 a3 ee 72 22 f0    	mov    %ax,0xf02272ee
	SETGATE(idt[T_MCHK] ,0, GD_KT, Machine_Check, 0);
f0104187:	b8 70 48 10 f0       	mov    $0xf0104870,%eax
f010418c:	66 a3 f0 72 22 f0    	mov    %ax,0xf02272f0
f0104192:	66 c7 05 f2 72 22 f0 	movw   $0x8,0xf02272f2
f0104199:	08 00 
f010419b:	c6 05 f4 72 22 f0 00 	movb   $0x0,0xf02272f4
f01041a2:	c6 05 f5 72 22 f0 8e 	movb   $0x8e,0xf02272f5
f01041a9:	c1 e8 10             	shr    $0x10,%eax
f01041ac:	66 a3 f6 72 22 f0    	mov    %ax,0xf02272f6
	SETGATE(idt[T_SIMDERR] ,0, GD_KT, SIMD_Floating_Point_Exception, 0);
f01041b2:	b8 76 48 10 f0       	mov    $0xf0104876,%eax
f01041b7:	66 a3 f8 72 22 f0    	mov    %ax,0xf02272f8
f01041bd:	66 c7 05 fa 72 22 f0 	movw   $0x8,0xf02272fa
f01041c4:	08 00 
f01041c6:	c6 05 fc 72 22 f0 00 	movb   $0x0,0xf02272fc
f01041cd:	c6 05 fd 72 22 f0 8e 	movb   $0x8e,0xf02272fd
f01041d4:	c1 e8 10             	shr    $0x10,%eax
f01041d7:	66 a3 fe 72 22 f0    	mov    %ax,0xf02272fe

	SETGATE(idt[T_SYSCALL], 0 , GD_KT, System_call, 3)
f01041dd:	b8 7c 48 10 f0       	mov    $0xf010487c,%eax
f01041e2:	66 a3 e0 73 22 f0    	mov    %ax,0xf02273e0
f01041e8:	66 c7 05 e2 73 22 f0 	movw   $0x8,0xf02273e2
f01041ef:	08 00 
f01041f1:	c6 05 e4 73 22 f0 00 	movb   $0x0,0xf02273e4
f01041f8:	c6 05 e5 73 22 f0 ee 	movb   $0xee,0xf02273e5
f01041ff:	c1 e8 10             	shr    $0x10,%eax
f0104202:	66 a3 e6 73 22 f0    	mov    %ax,0xf02273e6
	// Per-CPU setup 
	trap_init_percpu();
f0104208:	e8 d3 fb ff ff       	call   f0103de0 <trap_init_percpu>
}
f010420d:	c9                   	leave  
f010420e:	c3                   	ret    

f010420f <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010420f:	55                   	push   %ebp
f0104210:	89 e5                	mov    %esp,%ebp
f0104212:	53                   	push   %ebx
f0104213:	83 ec 14             	sub    $0x14,%esp
f0104216:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0104219:	8b 03                	mov    (%ebx),%eax
f010421b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010421f:	c7 04 24 76 79 10 f0 	movl   $0xf0107976,(%esp)
f0104226:	e8 93 fb ff ff       	call   f0103dbe <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010422b:	8b 43 04             	mov    0x4(%ebx),%eax
f010422e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104232:	c7 04 24 85 79 10 f0 	movl   $0xf0107985,(%esp)
f0104239:	e8 80 fb ff ff       	call   f0103dbe <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010423e:	8b 43 08             	mov    0x8(%ebx),%eax
f0104241:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104245:	c7 04 24 94 79 10 f0 	movl   $0xf0107994,(%esp)
f010424c:	e8 6d fb ff ff       	call   f0103dbe <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104251:	8b 43 0c             	mov    0xc(%ebx),%eax
f0104254:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104258:	c7 04 24 a3 79 10 f0 	movl   $0xf01079a3,(%esp)
f010425f:	e8 5a fb ff ff       	call   f0103dbe <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104264:	8b 43 10             	mov    0x10(%ebx),%eax
f0104267:	89 44 24 04          	mov    %eax,0x4(%esp)
f010426b:	c7 04 24 b2 79 10 f0 	movl   $0xf01079b2,(%esp)
f0104272:	e8 47 fb ff ff       	call   f0103dbe <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104277:	8b 43 14             	mov    0x14(%ebx),%eax
f010427a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010427e:	c7 04 24 c1 79 10 f0 	movl   $0xf01079c1,(%esp)
f0104285:	e8 34 fb ff ff       	call   f0103dbe <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010428a:	8b 43 18             	mov    0x18(%ebx),%eax
f010428d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104291:	c7 04 24 d0 79 10 f0 	movl   $0xf01079d0,(%esp)
f0104298:	e8 21 fb ff ff       	call   f0103dbe <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010429d:	8b 43 1c             	mov    0x1c(%ebx),%eax
f01042a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042a4:	c7 04 24 df 79 10 f0 	movl   $0xf01079df,(%esp)
f01042ab:	e8 0e fb ff ff       	call   f0103dbe <cprintf>
}
f01042b0:	83 c4 14             	add    $0x14,%esp
f01042b3:	5b                   	pop    %ebx
f01042b4:	5d                   	pop    %ebp
f01042b5:	c3                   	ret    

f01042b6 <print_trapframe>:
	//}
}

void
print_trapframe(struct Trapframe *tf)
{
f01042b6:	55                   	push   %ebp
f01042b7:	89 e5                	mov    %esp,%ebp
f01042b9:	56                   	push   %esi
f01042ba:	53                   	push   %ebx
f01042bb:	83 ec 10             	sub    $0x10,%esp
f01042be:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f01042c1:	e8 06 1f 00 00       	call   f01061cc <cpunum>
f01042c6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01042ca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01042ce:	c7 04 24 43 7a 10 f0 	movl   $0xf0107a43,(%esp)
f01042d5:	e8 e4 fa ff ff       	call   f0103dbe <cprintf>
	print_regs(&tf->tf_regs);
f01042da:	89 1c 24             	mov    %ebx,(%esp)
f01042dd:	e8 2d ff ff ff       	call   f010420f <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01042e2:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01042e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042ea:	c7 04 24 61 7a 10 f0 	movl   $0xf0107a61,(%esp)
f01042f1:	e8 c8 fa ff ff       	call   f0103dbe <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01042f6:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01042fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042fe:	c7 04 24 74 7a 10 f0 	movl   $0xf0107a74,(%esp)
f0104305:	e8 b4 fa ff ff       	call   f0103dbe <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010430a:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f010430d:	83 f8 13             	cmp    $0x13,%eax
f0104310:	77 09                	ja     f010431b <print_trapframe+0x65>
		return excnames[trapno];
f0104312:	8b 14 85 40 7d 10 f0 	mov    -0xfef82c0(,%eax,4),%edx
f0104319:	eb 1f                	jmp    f010433a <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f010431b:	83 f8 30             	cmp    $0x30,%eax
f010431e:	74 15                	je     f0104335 <print_trapframe+0x7f>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0104320:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f0104323:	83 fa 0f             	cmp    $0xf,%edx
f0104326:	ba fa 79 10 f0       	mov    $0xf01079fa,%edx
f010432b:	b9 0d 7a 10 f0       	mov    $0xf0107a0d,%ecx
f0104330:	0f 47 d1             	cmova  %ecx,%edx
f0104333:	eb 05                	jmp    f010433a <print_trapframe+0x84>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0104335:	ba ee 79 10 f0       	mov    $0xf01079ee,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010433a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010433e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104342:	c7 04 24 87 7a 10 f0 	movl   $0xf0107a87,(%esp)
f0104349:	e8 70 fa ff ff       	call   f0103dbe <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010434e:	3b 1d 60 7a 22 f0    	cmp    0xf0227a60,%ebx
f0104354:	75 19                	jne    f010436f <print_trapframe+0xb9>
f0104356:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010435a:	75 13                	jne    f010436f <print_trapframe+0xb9>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f010435c:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010435f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104363:	c7 04 24 99 7a 10 f0 	movl   $0xf0107a99,(%esp)
f010436a:	e8 4f fa ff ff       	call   f0103dbe <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f010436f:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0104372:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104376:	c7 04 24 a8 7a 10 f0 	movl   $0xf0107aa8,(%esp)
f010437d:	e8 3c fa ff ff       	call   f0103dbe <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0104382:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104386:	75 51                	jne    f01043d9 <print_trapframe+0x123>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0104388:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010438b:	89 c2                	mov    %eax,%edx
f010438d:	83 e2 01             	and    $0x1,%edx
f0104390:	ba 1c 7a 10 f0       	mov    $0xf0107a1c,%edx
f0104395:	b9 27 7a 10 f0       	mov    $0xf0107a27,%ecx
f010439a:	0f 45 ca             	cmovne %edx,%ecx
f010439d:	89 c2                	mov    %eax,%edx
f010439f:	83 e2 02             	and    $0x2,%edx
f01043a2:	ba 33 7a 10 f0       	mov    $0xf0107a33,%edx
f01043a7:	be 39 7a 10 f0       	mov    $0xf0107a39,%esi
f01043ac:	0f 44 d6             	cmove  %esi,%edx
f01043af:	83 e0 04             	and    $0x4,%eax
f01043b2:	b8 3e 7a 10 f0       	mov    $0xf0107a3e,%eax
f01043b7:	be 85 7b 10 f0       	mov    $0xf0107b85,%esi
f01043bc:	0f 44 c6             	cmove  %esi,%eax
f01043bf:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01043c3:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043cb:	c7 04 24 b6 7a 10 f0 	movl   $0xf0107ab6,(%esp)
f01043d2:	e8 e7 f9 ff ff       	call   f0103dbe <cprintf>
f01043d7:	eb 0c                	jmp    f01043e5 <print_trapframe+0x12f>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01043d9:	c7 04 24 f8 75 10 f0 	movl   $0xf01075f8,(%esp)
f01043e0:	e8 d9 f9 ff ff       	call   f0103dbe <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01043e5:	8b 43 30             	mov    0x30(%ebx),%eax
f01043e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043ec:	c7 04 24 c5 7a 10 f0 	movl   $0xf0107ac5,(%esp)
f01043f3:	e8 c6 f9 ff ff       	call   f0103dbe <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01043f8:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01043fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104400:	c7 04 24 d4 7a 10 f0 	movl   $0xf0107ad4,(%esp)
f0104407:	e8 b2 f9 ff ff       	call   f0103dbe <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010440c:	8b 43 38             	mov    0x38(%ebx),%eax
f010440f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104413:	c7 04 24 e7 7a 10 f0 	movl   $0xf0107ae7,(%esp)
f010441a:	e8 9f f9 ff ff       	call   f0103dbe <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010441f:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104423:	74 27                	je     f010444c <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104425:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104428:	89 44 24 04          	mov    %eax,0x4(%esp)
f010442c:	c7 04 24 f6 7a 10 f0 	movl   $0xf0107af6,(%esp)
f0104433:	e8 86 f9 ff ff       	call   f0103dbe <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104438:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010443c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104440:	c7 04 24 05 7b 10 f0 	movl   $0xf0107b05,(%esp)
f0104447:	e8 72 f9 ff ff       	call   f0103dbe <cprintf>
	}
}
f010444c:	83 c4 10             	add    $0x10,%esp
f010444f:	5b                   	pop    %ebx
f0104450:	5e                   	pop    %esi
f0104451:	5d                   	pop    %ebp
f0104452:	c3                   	ret    

f0104453 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104453:	55                   	push   %ebp
f0104454:	89 e5                	mov    %esp,%ebp
f0104456:	83 ec 38             	sub    $0x38,%esp
f0104459:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010445c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010445f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104462:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104465:	0f 20 d6             	mov    %cr2,%esi
	// All the handlers should check whether it is in kernel mode, 
	// if so, it should check the parameter whether it is valid
	// 
	// If I do not do the following operation, the grade script 
	// will run correctly though. 
	if((tf->tf_cs & 0x3) == 0)// CPL  -  the low 2-bit in the cs register 
f0104468:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010446c:	75 20                	jne    f010448e <page_fault_handler+0x3b>
		panic("kernel fault: invalid parameter %x for the page fault handler!\n", fault_va);
f010446e:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104472:	c7 44 24 08 d0 7c 10 	movl   $0xf0107cd0,0x8(%esp)
f0104479:	f0 
f010447a:	c7 44 24 04 5d 01 00 	movl   $0x15d,0x4(%esp)
f0104481:	00 
f0104482:	c7 04 24 18 7b 10 f0 	movl   $0xf0107b18,(%esp)
f0104489:	e8 b2 bb ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	// panic("%x", curenv->env_pgfault_upcall);
	if(curenv -> env_pgfault_upcall){
f010448e:	e8 39 1d 00 00       	call   f01061cc <cpunum>
f0104493:	6b c0 74             	imul   $0x74,%eax,%eax
f0104496:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f010449c:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f01044a0:	0f 84 04 01 00 00    	je     f01045aa <page_fault_handler+0x157>
		esp = tf -> tf_esp;
f01044a6:	8b 43 3c             	mov    0x3c(%ebx),%eax
		if(esp < UXSTACKTOP && esp > UXSTACKTOP - PGSIZE)
f01044a9:	8d 90 ff 0f 40 11    	lea    0x11400fff(%eax),%edx
			esp -= 4;
f01044af:	83 e8 04             	sub    $0x4,%eax
f01044b2:	81 fa fe 0f 00 00    	cmp    $0xffe,%edx
f01044b8:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01044bd:	89 d7                	mov    %edx,%edi
f01044bf:	0f 46 f8             	cmovbe %eax,%edi
		else
			esp = UXSTACKTOP;
		utrap = (struct UTrapframe *)(esp - sizeof(struct UTrapframe));
f01044c2:	8d 47 cc             	lea    -0x34(%edi),%eax
f01044c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		user_mem_assert (curenv, (void*) utrap, sizeof (struct UTrapframe), PTE_U|PTE_W);
f01044c8:	e8 ff 1c 00 00       	call   f01061cc <cpunum>
f01044cd:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01044d4:	00 
f01044d5:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
f01044dc:	00 
f01044dd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01044e0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01044e4:	6b c0 74             	imul   $0x74,%eax,%eax
f01044e7:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01044ed:	89 04 24             	mov    %eax,(%esp)
f01044f0:	e8 b8 ee ff ff       	call   f01033ad <user_mem_assert>

		utrap->utf_fault_va = fault_va;
f01044f5:	89 77 cc             	mov    %esi,-0x34(%edi)
		utrap->utf_err = tf->tf_err;
f01044f8:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01044fb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01044fe:	89 42 04             	mov    %eax,0x4(%edx)
		utrap->utf_regs = tf->tf_regs;
f0104501:	83 ef 2c             	sub    $0x2c,%edi
f0104504:	89 de                	mov    %ebx,%esi
f0104506:	b8 20 00 00 00       	mov    $0x20,%eax
f010450b:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0104511:	74 03                	je     f0104516 <page_fault_handler+0xc3>
f0104513:	a4                   	movsb  %ds:(%esi),%es:(%edi)
f0104514:	b0 1f                	mov    $0x1f,%al
f0104516:	f7 c7 02 00 00 00    	test   $0x2,%edi
f010451c:	74 05                	je     f0104523 <page_fault_handler+0xd0>
f010451e:	66 a5                	movsw  %ds:(%esi),%es:(%edi)
f0104520:	83 e8 02             	sub    $0x2,%eax
f0104523:	89 c1                	mov    %eax,%ecx
f0104525:	c1 e9 02             	shr    $0x2,%ecx
f0104528:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010452a:	ba 00 00 00 00       	mov    $0x0,%edx
f010452f:	a8 02                	test   $0x2,%al
f0104531:	74 0b                	je     f010453e <page_fault_handler+0xeb>
f0104533:	0f b7 16             	movzwl (%esi),%edx
f0104536:	66 89 17             	mov    %dx,(%edi)
f0104539:	ba 02 00 00 00       	mov    $0x2,%edx
f010453e:	a8 01                	test   $0x1,%al
f0104540:	74 07                	je     f0104549 <page_fault_handler+0xf6>
f0104542:	0f b6 04 16          	movzbl (%esi,%edx,1),%eax
f0104546:	88 04 17             	mov    %al,(%edi,%edx,1)
		utrap->utf_eip = tf->tf_eip;
f0104549:	8b 43 30             	mov    0x30(%ebx),%eax
f010454c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010454f:	89 42 28             	mov    %eax,0x28(%edx)
		utrap->utf_eflags = tf->tf_eflags;
f0104552:	8b 43 38             	mov    0x38(%ebx),%eax
f0104555:	89 42 2c             	mov    %eax,0x2c(%edx)
		utrap->utf_esp = tf->tf_esp;
f0104558:	8b 43 3c             	mov    0x3c(%ebx),%eax
f010455b:	89 42 30             	mov    %eax,0x30(%edx)


		curenv->env_tf.tf_eip = (uint32_t) curenv->env_pgfault_upcall;
f010455e:	e8 69 1c 00 00       	call   f01061cc <cpunum>
f0104563:	6b c0 74             	imul   $0x74,%eax,%eax
f0104566:	8b 98 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%ebx
f010456c:	e8 5b 1c 00 00       	call   f01061cc <cpunum>
f0104571:	6b c0 74             	imul   $0x74,%eax,%eax
f0104574:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f010457a:	8b 40 64             	mov    0x64(%eax),%eax
f010457d:	89 43 30             	mov    %eax,0x30(%ebx)
		curenv->env_tf.tf_esp = (uint32_t) utrap;
f0104580:	e8 47 1c 00 00       	call   f01061cc <cpunum>
f0104585:	6b c0 74             	imul   $0x74,%eax,%eax
f0104588:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f010458e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104591:	89 50 3c             	mov    %edx,0x3c(%eax)
		env_run (curenv);
f0104594:	e8 33 1c 00 00       	call   f01061cc <cpunum>
f0104599:	6b c0 74             	imul   $0x74,%eax,%eax
f010459c:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01045a2:	89 04 24             	mov    %eax,(%esp)
f01045a5:	e8 e8 f5 ff ff       	call   f0103b92 <env_run>
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01045aa:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f01045ad:	e8 1a 1c 00 00       	call   f01061cc <cpunum>
		curenv->env_tf.tf_esp = (uint32_t) utrap;
		env_run (curenv);
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01045b2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01045b6:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f01045ba:	6b c0 74             	imul   $0x74,%eax,%eax
f01045bd:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
		curenv->env_tf.tf_esp = (uint32_t) utrap;
		env_run (curenv);
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01045c3:	8b 40 48             	mov    0x48(%eax),%eax
f01045c6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045ca:	c7 04 24 10 7d 10 f0 	movl   $0xf0107d10,(%esp)
f01045d1:	e8 e8 f7 ff ff       	call   f0103dbe <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01045d6:	89 1c 24             	mov    %ebx,(%esp)
f01045d9:	e8 d8 fc ff ff       	call   f01042b6 <print_trapframe>
	env_destroy(curenv);
f01045de:	e8 e9 1b 00 00       	call   f01061cc <cpunum>
f01045e3:	6b c0 74             	imul   $0x74,%eax,%eax
f01045e6:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01045ec:	89 04 24             	mov    %eax,(%esp)
f01045ef:	e8 fd f4 ff ff       	call   f0103af1 <env_destroy>
}
f01045f4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01045f7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01045fa:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01045fd:	89 ec                	mov    %ebp,%esp
f01045ff:	5d                   	pop    %ebp
f0104600:	c3                   	ret    

f0104601 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0104601:	55                   	push   %ebp
f0104602:	89 e5                	mov    %esp,%ebp
f0104604:	57                   	push   %edi
f0104605:	56                   	push   %esi
f0104606:	83 ec 20             	sub    $0x20,%esp
f0104609:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010460c:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f010460d:	83 3d 80 7e 22 f0 00 	cmpl   $0x0,0xf0227e80
f0104614:	74 01                	je     f0104617 <trap+0x16>
		asm volatile("hlt");
f0104616:	f4                   	hlt    

static __inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0104617:	9c                   	pushf  
f0104618:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0104619:	f6 c4 02             	test   $0x2,%ah
f010461c:	74 24                	je     f0104642 <trap+0x41>
f010461e:	c7 44 24 0c 24 7b 10 	movl   $0xf0107b24,0xc(%esp)
f0104625:	f0 
f0104626:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010462d:	f0 
f010462e:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
f0104635:	00 
f0104636:	c7 04 24 18 7b 10 f0 	movl   $0xf0107b18,(%esp)
f010463d:	e8 fe b9 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0104642:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104646:	83 e0 03             	and    $0x3,%eax
f0104649:	66 83 f8 03          	cmp    $0x3,%ax
f010464d:	0f 85 a7 00 00 00    	jne    f01046fa <trap+0xf9>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0104653:	c7 04 24 a0 13 12 f0 	movl   $0xf01213a0,(%esp)
f010465a:	e8 06 1e 00 00       	call   f0106465 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f010465f:	e8 68 1b 00 00       	call   f01061cc <cpunum>
f0104664:	6b c0 74             	imul   $0x74,%eax,%eax
f0104667:	83 b8 28 80 22 f0 00 	cmpl   $0x0,-0xfdd7fd8(%eax)
f010466e:	75 24                	jne    f0104694 <trap+0x93>
f0104670:	c7 44 24 0c 3d 7b 10 	movl   $0xf0107b3d,0xc(%esp)
f0104677:	f0 
f0104678:	c7 44 24 08 14 76 10 	movl   $0xf0107614,0x8(%esp)
f010467f:	f0 
f0104680:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
f0104687:	00 
f0104688:	c7 04 24 18 7b 10 f0 	movl   $0xf0107b18,(%esp)
f010468f:	e8 ac b9 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0104694:	e8 33 1b 00 00       	call   f01061cc <cpunum>
f0104699:	6b c0 74             	imul   $0x74,%eax,%eax
f010469c:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01046a2:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01046a6:	75 2d                	jne    f01046d5 <trap+0xd4>
			env_free(curenv);
f01046a8:	e8 1f 1b 00 00       	call   f01061cc <cpunum>
f01046ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01046b0:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01046b6:	89 04 24             	mov    %eax,(%esp)
f01046b9:	e8 2d f2 ff ff       	call   f01038eb <env_free>
			curenv = NULL;
f01046be:	e8 09 1b 00 00       	call   f01061cc <cpunum>
f01046c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01046c6:	c7 80 28 80 22 f0 00 	movl   $0x0,-0xfdd7fd8(%eax)
f01046cd:	00 00 00 
			sched_yield();
f01046d0:	e8 c7 01 00 00       	call   f010489c <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01046d5:	e8 f2 1a 00 00       	call   f01061cc <cpunum>
f01046da:	6b c0 74             	imul   $0x74,%eax,%eax
f01046dd:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01046e3:	b9 11 00 00 00       	mov    $0x11,%ecx
f01046e8:	89 c7                	mov    %eax,%edi
f01046ea:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01046ec:	e8 db 1a 00 00       	call   f01061cc <cpunum>
f01046f1:	6b c0 74             	imul   $0x74,%eax,%eax
f01046f4:	8b b0 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01046fa:	89 35 60 7a 22 f0    	mov    %esi,0xf0227a60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf -> tf_trapno){
f0104700:	8b 46 28             	mov    0x28(%esi),%eax
f0104703:	83 f8 03             	cmp    $0x3,%eax
f0104706:	74 0a                	je     f0104712 <trap+0x111>
f0104708:	83 f8 0e             	cmp    $0xe,%eax
f010470b:	74 0f                	je     f010471c <trap+0x11b>
f010470d:	83 f8 01             	cmp    $0x1,%eax
f0104710:	75 12                	jne    f0104724 <trap+0x123>
		case T_BRKPT:
		case T_DEBUG:
			monitor(tf);
f0104712:	89 34 24             	mov    %esi,(%esp)
f0104715:	e8 f8 c3 ff ff       	call   f0100b12 <monitor>
f010471a:	eb 08                	jmp    f0104724 <trap+0x123>
			break;
		case T_PGFLT:
			page_fault_handler(tf);
f010471c:	89 34 24             	mov    %esi,(%esp)
f010471f:	e8 2f fd ff ff       	call   f0104453 <page_fault_handler>
			break;
	}

	if (tf->tf_trapno == T_SYSCALL){
f0104724:	8b 46 28             	mov    0x28(%esi),%eax
f0104727:	83 f8 30             	cmp    $0x30,%eax
f010472a:	75 52                	jne    f010477e <trap+0x17d>
		struct PushRegs *regs = &(tf -> tf_regs);
		/*  DX, CX, BX, DI, SI */
		int32_t num = syscall(regs->reg_eax, regs->reg_edx, regs->reg_ecx, 
f010472c:	8b 46 04             	mov    0x4(%esi),%eax
f010472f:	89 44 24 14          	mov    %eax,0x14(%esp)
f0104733:	8b 06                	mov    (%esi),%eax
f0104735:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104739:	8b 46 10             	mov    0x10(%esi),%eax
f010473c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104740:	8b 46 18             	mov    0x18(%esi),%eax
f0104743:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104747:	8b 46 14             	mov    0x14(%esi),%eax
f010474a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010474e:	8b 46 1c             	mov    0x1c(%esi),%eax
f0104751:	89 04 24             	mov    %eax,(%esp)
f0104754:	e8 47 02 00 00       	call   f01049a0 <syscall>
			regs->reg_ebx,regs->reg_edi, regs->reg_esi);

		if(num < 0)
f0104759:	85 c0                	test   %eax,%eax
f010475b:	79 1c                	jns    f0104779 <trap+0x178>
			panic("unhandled fault!\n");
f010475d:	c7 44 24 08 44 7b 10 	movl   $0xf0107b44,0x8(%esp)
f0104764:	f0 
f0104765:	c7 44 24 04 f1 00 00 	movl   $0xf1,0x4(%esp)
f010476c:	00 
f010476d:	c7 04 24 18 7b 10 f0 	movl   $0xf0107b18,(%esp)
f0104774:	e8 c7 b8 ff ff       	call   f0100040 <_panic>
		regs -> reg_eax = num;
f0104779:	89 46 1c             	mov    %eax,0x1c(%esi)
f010477c:	eb 5c                	jmp    f01047da <trap+0x1d9>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f010477e:	83 f8 27             	cmp    $0x27,%eax
f0104781:	75 16                	jne    f0104799 <trap+0x198>
		cprintf("Spurious interrupt on irq 7\n");
f0104783:	c7 04 24 56 7b 10 f0 	movl   $0xf0107b56,(%esp)
f010478a:	e8 2f f6 ff ff       	call   f0103dbe <cprintf>
		print_trapframe(tf);
f010478f:	89 34 24             	mov    %esi,(%esp)
f0104792:	e8 1f fb ff ff       	call   f01042b6 <print_trapframe>
f0104797:	eb 41                	jmp    f01047da <trap+0x1d9>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0104799:	89 34 24             	mov    %esi,(%esp)
f010479c:	e8 15 fb ff ff       	call   f01042b6 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01047a1:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01047a6:	75 1c                	jne    f01047c4 <trap+0x1c3>
		panic("unhandled trap in kernel");
f01047a8:	c7 44 24 08 73 7b 10 	movl   $0xf0107b73,0x8(%esp)
f01047af:	f0 
f01047b0:	c7 44 24 04 07 01 00 	movl   $0x107,0x4(%esp)
f01047b7:	00 
f01047b8:	c7 04 24 18 7b 10 f0 	movl   $0xf0107b18,(%esp)
f01047bf:	e8 7c b8 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f01047c4:	e8 03 1a 00 00       	call   f01061cc <cpunum>
f01047c9:	6b c0 74             	imul   $0x74,%eax,%eax
f01047cc:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01047d2:	89 04 24             	mov    %eax,(%esp)
f01047d5:	e8 17 f3 ff ff       	call   f0103af1 <env_destroy>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f01047da:	e8 ed 19 00 00       	call   f01061cc <cpunum>
f01047df:	6b c0 74             	imul   $0x74,%eax,%eax
f01047e2:	83 b8 28 80 22 f0 00 	cmpl   $0x0,-0xfdd7fd8(%eax)
f01047e9:	74 2a                	je     f0104815 <trap+0x214>
f01047eb:	e8 dc 19 00 00       	call   f01061cc <cpunum>
f01047f0:	6b c0 74             	imul   $0x74,%eax,%eax
f01047f3:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01047f9:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01047fd:	75 16                	jne    f0104815 <trap+0x214>
		env_run(curenv);
f01047ff:	e8 c8 19 00 00       	call   f01061cc <cpunum>
f0104804:	6b c0 74             	imul   $0x74,%eax,%eax
f0104807:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f010480d:	89 04 24             	mov    %eax,(%esp)
f0104810:	e8 7d f3 ff ff       	call   f0103b92 <env_run>
	else
		sched_yield();
f0104815:	e8 82 00 00 00       	call   f010489c <sched_yield>
f010481a:	66 90                	xchg   %ax,%ax

f010481c <Divide_error>:
  * TRAPHANDLER_NOEC - No return
  * TRAPHANDLER - return
  *
  * http://pdos.csail.mit.edu/6.828/2011/readings/i386/s09_10.htm
  */
TRAPHANDLER_NOEC(Divide_error, T_DIVIDE);
f010481c:	6a 00                	push   $0x0
f010481e:	6a 00                	push   $0x0
f0104820:	eb 60                	jmp    f0104882 <_alltraps>

f0104822 <Debug>:
TRAPHANDLER_NOEC(Debug, T_DEBUG);
f0104822:	6a 00                	push   $0x0
f0104824:	6a 01                	push   $0x1
f0104826:	eb 5a                	jmp    f0104882 <_alltraps>

f0104828 <Non_Maskable_Interrupt>:
TRAPHANDLER_NOEC(Non_Maskable_Interrupt, T_NMI);
f0104828:	6a 00                	push   $0x0
f010482a:	6a 02                	push   $0x2
f010482c:	eb 54                	jmp    f0104882 <_alltraps>

f010482e <Breakpoint>:
TRAPHANDLER_NOEC(Breakpoint, T_BRKPT);
f010482e:	6a 00                	push   $0x0
f0104830:	6a 03                	push   $0x3
f0104832:	eb 4e                	jmp    f0104882 <_alltraps>

f0104834 <Overflow>:
TRAPHANDLER_NOEC(Overflow, T_OFLOW);
f0104834:	6a 00                	push   $0x0
f0104836:	6a 04                	push   $0x4
f0104838:	eb 48                	jmp    f0104882 <_alltraps>

f010483a <BOUND_Range_Exceeded>:
TRAPHANDLER_NOEC(BOUND_Range_Exceeded, T_BOUND);
f010483a:	6a 00                	push   $0x0
f010483c:	6a 05                	push   $0x5
f010483e:	eb 42                	jmp    f0104882 <_alltraps>

f0104840 <Invalid_Opcode>:
TRAPHANDLER_NOEC(Invalid_Opcode, T_ILLOP);
f0104840:	6a 00                	push   $0x0
f0104842:	6a 06                	push   $0x6
f0104844:	eb 3c                	jmp    f0104882 <_alltraps>

f0104846 <Device_Not_Available>:
TRAPHANDLER_NOEC(Device_Not_Available, T_DEVICE);
f0104846:	6a 00                	push   $0x0
f0104848:	6a 07                	push   $0x7
f010484a:	eb 36                	jmp    f0104882 <_alltraps>

f010484c <Double_Fault>:
TRAPHANDLER(Double_Fault, T_DBLFLT);
f010484c:	6a 08                	push   $0x8
f010484e:	eb 32                	jmp    f0104882 <_alltraps>

f0104850 <Invalid_TSS>:
TRAPHANDLER(Invalid_TSS, T_TSS);
f0104850:	6a 0a                	push   $0xa
f0104852:	eb 2e                	jmp    f0104882 <_alltraps>

f0104854 <Segment_Not_Present>:
TRAPHANDLER(Segment_Not_Present, T_SEGNP);
f0104854:	6a 0b                	push   $0xb
f0104856:	eb 2a                	jmp    f0104882 <_alltraps>

f0104858 <Stack_Fault>:
TRAPHANDLER(Stack_Fault, T_STACK);
f0104858:	6a 0c                	push   $0xc
f010485a:	eb 26                	jmp    f0104882 <_alltraps>

f010485c <General_Protection>:
TRAPHANDLER(General_Protection, T_GPFLT);
f010485c:	6a 0d                	push   $0xd
f010485e:	eb 22                	jmp    f0104882 <_alltraps>

f0104860 <Page_Fault>:
TRAPHANDLER(Page_Fault, T_PGFLT);
f0104860:	6a 0e                	push   $0xe
f0104862:	eb 1e                	jmp    f0104882 <_alltraps>

f0104864 <x87_FPU_Floating_Point_Error>:
TRAPHANDLER_NOEC(x87_FPU_Floating_Point_Error, T_FPERR);
f0104864:	6a 00                	push   $0x0
f0104866:	6a 10                	push   $0x10
f0104868:	eb 18                	jmp    f0104882 <_alltraps>

f010486a <Alignment_Check>:
TRAPHANDLER_NOEC(Alignment_Check, T_ALIGN);
f010486a:	6a 00                	push   $0x0
f010486c:	6a 11                	push   $0x11
f010486e:	eb 12                	jmp    f0104882 <_alltraps>

f0104870 <Machine_Check>:
TRAPHANDLER_NOEC(Machine_Check, T_MCHK);
f0104870:	6a 00                	push   $0x0
f0104872:	6a 12                	push   $0x12
f0104874:	eb 0c                	jmp    f0104882 <_alltraps>

f0104876 <SIMD_Floating_Point_Exception>:
TRAPHANDLER_NOEC(SIMD_Floating_Point_Exception, T_SIMDERR);
f0104876:	6a 00                	push   $0x0
f0104878:	6a 13                	push   $0x13
f010487a:	eb 06                	jmp    f0104882 <_alltraps>

f010487c <System_call>:

TRAPHANDLER_NOEC(System_call,T_SYSCALL);
f010487c:	6a 00                	push   $0x0
f010487e:	6a 30                	push   $0x30
f0104880:	eb 00                	jmp    f0104882 <_alltraps>

f0104882 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
 _alltraps:
 	pushw   $0x0
f0104882:	66 6a 00             	pushw  $0x0
	pushw	%ds
f0104885:	66 1e                	pushw  %ds
	pushw	$0x0
f0104887:	66 6a 00             	pushw  $0x0
	pushw	%es	
f010488a:	66 06                	pushw  %es
	pushal
f010488c:	60                   	pusha  
	movl	$GD_KD, %eax /* GD_KD is kern data -- 0x10 */
f010488d:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax, %ds
f0104892:	8e d8                	mov    %eax,%ds
	movw	%ax, %es
f0104894:	8e c0                	mov    %eax,%es
	pushl %esp
f0104896:	54                   	push   %esp
	call trap
f0104897:	e8 65 fd ff ff       	call   f0104601 <trap>

f010489c <sched_yield>:


// Choose a user environment to run and run it.
void
sched_yield(void)
{
f010489c:	55                   	push   %ebp
f010489d:	89 e5                	mov    %esp,%ebp
f010489f:	56                   	push   %esi
f01048a0:	53                   	push   %ebx
f01048a1:	83 ec 20             	sub    $0x20,%esp
	// idle environment (env_type == ENV_TYPE_IDLE).  If there are
	// no runnable environments, simply drop through to the code
	// below to switch to this CPU's idle environment.

	// LAB 4: Your code here.
	if(curenv != NULL)
f01048a4:	e8 23 19 00 00       	call   f01061cc <cpunum>
f01048a9:	6b d0 74             	imul   $0x74,%eax,%edx
		cur_id = curenv->env_id;
	else
		cur_id = 0;
f01048ac:	b8 00 00 00 00       	mov    $0x0,%eax
	// idle environment (env_type == ENV_TYPE_IDLE).  If there are
	// no runnable environments, simply drop through to the code
	// below to switch to this CPU's idle environment.

	// LAB 4: Your code here.
	if(curenv != NULL)
f01048b1:	83 ba 28 80 22 f0 00 	cmpl   $0x0,-0xfdd7fd8(%edx)
f01048b8:	74 11                	je     f01048cb <sched_yield+0x2f>
		cur_id = curenv->env_id;
f01048ba:	e8 0d 19 00 00       	call   f01061cc <cpunum>
f01048bf:	6b c0 74             	imul   $0x74,%eax,%eax
f01048c2:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01048c8:	8b 40 48             	mov    0x48(%eax),%eax
	else
		cur_id = 0;
	for(i = 0; i < NENV; i++){
		if((++cur_id) >= NENV) /* The cur_id could be 409*, and the NENV is 1024 */
			cur_id = 0;
		if(envs[cur_id].env_type != ENV_TYPE_IDLE &&
f01048cb:	8b 1d 48 72 22 f0    	mov    0xf0227248,%ebx
f01048d1:	ba 00 04 00 00       	mov    $0x400,%edx
		cur_id = curenv->env_id;
	else
		cur_id = 0;
	for(i = 0; i < NENV; i++){
		if((++cur_id) >= NENV) /* The cur_id could be 409*, and the NENV is 1024 */
			cur_id = 0;
f01048d6:	be 00 00 00 00       	mov    $0x0,%esi
	if(curenv != NULL)
		cur_id = curenv->env_id;
	else
		cur_id = 0;
	for(i = 0; i < NENV; i++){
		if((++cur_id) >= NENV) /* The cur_id could be 409*, and the NENV is 1024 */
f01048db:	83 c0 01             	add    $0x1,%eax
			cur_id = 0;
f01048de:	3d 00 04 00 00       	cmp    $0x400,%eax
f01048e3:	0f 4d c6             	cmovge %esi,%eax
		if(envs[cur_id].env_type != ENV_TYPE_IDLE &&
f01048e6:	6b c8 7c             	imul   $0x7c,%eax,%ecx
f01048e9:	01 d9                	add    %ebx,%ecx
f01048eb:	83 79 50 01          	cmpl   $0x1,0x50(%ecx)
f01048ef:	74 0e                	je     f01048ff <sched_yield+0x63>
f01048f1:	83 79 54 02          	cmpl   $0x2,0x54(%ecx)
f01048f5:	75 08                	jne    f01048ff <sched_yield+0x63>
			envs[cur_id].env_status == ENV_RUNNABLE)
			env_run(&envs[cur_id]);
f01048f7:	89 0c 24             	mov    %ecx,(%esp)
f01048fa:	e8 93 f2 ff ff       	call   f0103b92 <env_run>
	// LAB 4: Your code here.
	if(curenv != NULL)
		cur_id = curenv->env_id;
	else
		cur_id = 0;
	for(i = 0; i < NENV; i++){
f01048ff:	83 ea 01             	sub    $0x1,%edx
f0104902:	75 d7                	jne    f01048db <sched_yield+0x3f>
#include <kern/monitor.h>


// Choose a user environment to run and run it.
void
sched_yield(void)
f0104904:	8d 43 50             	lea    0x50(%ebx),%eax
f0104907:	ba 00 00 00 00       	mov    $0x0,%edx

	// For debugging and testing purposes, if there are no
	// runnable environments other than the idle environments,
	// drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if (envs[i].env_type != ENV_TYPE_IDLE &&
f010490c:	83 38 01             	cmpl   $0x1,(%eax)
f010490f:	74 0b                	je     f010491c <sched_yield+0x80>
		    (envs[i].env_status == ENV_RUNNABLE ||
f0104911:	8b 48 04             	mov    0x4(%eax),%ecx
f0104914:	83 e9 02             	sub    $0x2,%ecx

	// For debugging and testing purposes, if there are no
	// runnable environments other than the idle environments,
	// drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if (envs[i].env_type != ENV_TYPE_IDLE &&
f0104917:	83 f9 01             	cmp    $0x1,%ecx
f010491a:	76 10                	jbe    f010492c <sched_yield+0x90>
	}

	// For debugging and testing purposes, if there are no
	// runnable environments other than the idle environments,
	// drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010491c:	83 c2 01             	add    $0x1,%edx
f010491f:	83 c0 7c             	add    $0x7c,%eax
f0104922:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f0104928:	75 e2                	jne    f010490c <sched_yield+0x70>
f010492a:	eb 08                	jmp    f0104934 <sched_yield+0x98>
		if (envs[i].env_type != ENV_TYPE_IDLE &&
		    (envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING))
			break;
	}
	if (i == NENV) {
f010492c:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f0104932:	75 1a                	jne    f010494e <sched_yield+0xb2>
		cprintf("No more runnable environments!\n");
f0104934:	c7 04 24 90 7d 10 f0 	movl   $0xf0107d90,(%esp)
f010493b:	e8 7e f4 ff ff       	call   f0103dbe <cprintf>
		while (1)
			monitor(NULL);
f0104940:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104947:	e8 c6 c1 ff ff       	call   f0100b12 <monitor>
f010494c:	eb f2                	jmp    f0104940 <sched_yield+0xa4>
	}

	// Run this CPU's idle environment when nothing else is runnable.
	idle = &envs[cpunum()];
f010494e:	e8 79 18 00 00       	call   f01061cc <cpunum>
f0104953:	6b c0 7c             	imul   $0x7c,%eax,%eax
f0104956:	01 c3                	add    %eax,%ebx
	if (!(idle->env_status == ENV_RUNNABLE || idle->env_status == ENV_RUNNING))
f0104958:	8b 73 54             	mov    0x54(%ebx),%esi
f010495b:	8d 46 fe             	lea    -0x2(%esi),%eax
f010495e:	83 f8 01             	cmp    $0x1,%eax
f0104961:	76 29                	jbe    f010498c <sched_yield+0xf0>
		panic("CPU %d: No idle environment! %d", cpunum(), idle->env_status);
f0104963:	e8 64 18 00 00       	call   f01061cc <cpunum>
f0104968:	89 74 24 10          	mov    %esi,0x10(%esp)
f010496c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104970:	c7 44 24 08 b0 7d 10 	movl   $0xf0107db0,0x8(%esp)
f0104977:	f0 
f0104978:	c7 44 24 04 3e 00 00 	movl   $0x3e,0x4(%esp)
f010497f:	00 
f0104980:	c7 04 24 d0 7d 10 f0 	movl   $0xf0107dd0,(%esp)
f0104987:	e8 b4 b6 ff ff       	call   f0100040 <_panic>
	env_run(idle);
f010498c:	89 1c 24             	mov    %ebx,(%esp)
f010498f:	e8 fe f1 ff ff       	call   f0103b92 <env_run>
f0104994:	66 90                	xchg   %ax,%ax
f0104996:	66 90                	xchg   %ax,%ax
f0104998:	66 90                	xchg   %ax,%ax
f010499a:	66 90                	xchg   %ax,%ax
f010499c:	66 90                	xchg   %ax,%ax
f010499e:	66 90                	xchg   %ax,%ax

f01049a0 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01049a0:	55                   	push   %ebp
f01049a1:	89 e5                	mov    %esp,%ebp
f01049a3:	56                   	push   %esi
f01049a4:	53                   	push   %ebx
f01049a5:	83 ec 20             	sub    $0x20,%esp
f01049a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01049ab:	8b 5d 10             	mov    0x10(%ebp),%ebx
	SYS_ipc_try_send,
	SYS_ipc_recv,
	NSYSCALLS
};
*/
	switch(syscallno){
f01049ae:	83 f8 0a             	cmp    $0xa,%eax
f01049b1:	0f 87 1d 04 00 00    	ja     f0104dd4 <syscall+0x434>
f01049b7:	ff 24 85 10 7e 10 f0 	jmp    *-0xfef81f0(,%eax,4)
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	/*user_mem_assert(struct Env *env, const void *va, size_t len, int perm)*/
	user_mem_assert(curenv, (const void *)s, len, PTE_U);
f01049be:	e8 09 18 00 00       	call   f01061cc <cpunum>
f01049c3:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01049ca:	00 
f01049cb:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01049cf:	8b 55 0c             	mov    0xc(%ebp),%edx
f01049d2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01049d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d9:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f01049df:	89 04 24             	mov    %eax,(%esp)
f01049e2:	e8 c6 e9 ff ff       	call   f01033ad <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01049e7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01049ea:	89 44 24 08          	mov    %eax,0x8(%esp)
f01049ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01049f2:	c7 04 24 a9 6c 10 f0 	movl   $0xf0106ca9,(%esp)
f01049f9:	e8 c0 f3 ff ff       	call   f0103dbe <cprintf>
	SYS_ipc_recv,
	NSYSCALLS
};
*/
	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
f01049fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a03:	e9 d1 03 00 00       	jmp    f0104dd9 <syscall+0x439>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104a08:	e8 55 bd ff ff       	call   f0100762 <cons_getc>
	NSYSCALLS
};
*/
	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
		case SYS_cgetc: return sys_cgetc();
f0104a0d:	8d 76 00             	lea    0x0(%esi),%esi
f0104a10:	e9 c4 03 00 00       	jmp    f0104dd9 <syscall+0x439>
    
// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104a15:	e8 b2 17 00 00       	call   f01061cc <cpunum>
f0104a1a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a1d:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0104a23:	8b 40 48             	mov    0x48(%eax),%eax
};
*/
	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
		case SYS_cgetc: return sys_cgetc();
		case SYS_getenvid: return sys_getenvid();
f0104a26:	e9 ae 03 00 00       	jmp    f0104dd9 <syscall+0x439>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104a2b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104a32:	00 
f0104a33:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104a36:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a3a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104a3d:	89 14 24             	mov    %edx,(%esp)
f0104a40:	e8 80 ea ff ff       	call   f01034c5 <envid2env>
f0104a45:	85 c0                	test   %eax,%eax
f0104a47:	0f 88 8c 03 00 00    	js     f0104dd9 <syscall+0x439>
		return r;
	if (e == curenv)
f0104a4d:	e8 7a 17 00 00       	call   f01061cc <cpunum>
f0104a52:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104a55:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a58:	39 90 28 80 22 f0    	cmp    %edx,-0xfdd7fd8(%eax)
f0104a5e:	75 23                	jne    f0104a83 <syscall+0xe3>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104a60:	e8 67 17 00 00       	call   f01061cc <cpunum>
f0104a65:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a68:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0104a6e:	8b 40 48             	mov    0x48(%eax),%eax
f0104a71:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a75:	c7 04 24 dd 7d 10 f0 	movl   $0xf0107ddd,(%esp)
f0104a7c:	e8 3d f3 ff ff       	call   f0103dbe <cprintf>
f0104a81:	eb 28                	jmp    f0104aab <syscall+0x10b>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104a83:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104a86:	e8 41 17 00 00       	call   f01061cc <cpunum>
f0104a8b:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104a8f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a92:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0104a98:	8b 40 48             	mov    0x48(%eax),%eax
f0104a9b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a9f:	c7 04 24 f8 7d 10 f0 	movl   $0xf0107df8,(%esp)
f0104aa6:	e8 13 f3 ff ff       	call   f0103dbe <cprintf>
	env_destroy(e);
f0104aab:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104aae:	89 04 24             	mov    %eax,(%esp)
f0104ab1:	e8 3b f0 ff ff       	call   f0103af1 <env_destroy>
	return 0;
f0104ab6:	b8 00 00 00 00       	mov    $0x0,%eax
*/
	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
		case SYS_cgetc: return sys_cgetc();
		case SYS_getenvid: return sys_getenvid();
		case SYS_env_destroy: return sys_env_destroy((envid_t)a1);
f0104abb:	e9 19 03 00 00       	jmp    f0104dd9 <syscall+0x439>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104ac0:	e8 d7 fd ff ff       	call   f010489c <sched_yield>
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *new_env;
	int r;
	if((r = env_alloc(&new_env, curenv->env_id)))
f0104ac5:	e8 02 17 00 00       	call   f01061cc <cpunum>
f0104aca:	6b c0 74             	imul   $0x74,%eax,%eax
f0104acd:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0104ad3:	8b 40 48             	mov    0x48(%eax),%eax
f0104ad6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ada:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104add:	89 04 24             	mov    %eax,(%esp)
f0104ae0:	e8 fb ea ff ff       	call   f01035e0 <env_alloc>
f0104ae5:	85 c0                	test   %eax,%eax
f0104ae7:	0f 85 ec 02 00 00    	jne    f0104dd9 <syscall+0x439>
		return r;

	/* set status */
	new_env -> env_status = ENV_NOT_RUNNABLE;
f0104aed:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104af0:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	/* copy the register */
	memmove(&(new_env->env_tf), &(curenv -> env_tf), sizeof(struct Trapframe));
f0104af7:	e8 d0 16 00 00       	call   f01061cc <cpunum>
f0104afc:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0104b03:	00 
f0104b04:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b07:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0104b0d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b11:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104b14:	89 04 24             	mov    %eax,(%esp)
f0104b17:	e8 67 10 00 00       	call   f0105b83 <memmove>
	/* set the return value */
	new_env -> env_tf.tf_regs.reg_eax = 0;
f0104b1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104b1f:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return new_env -> env_id;
f0104b26:	8b 40 48             	mov    0x48(%eax),%eax
		case SYS_getenvid: return sys_getenvid();
		case SYS_env_destroy: return sys_env_destroy((envid_t)a1);
		//case NSYSCALLS: NSYSCALLS();break;
		case SYS_yield: sys_yield();return 0;
		// fork functions in Lab4
		case SYS_exofork: return sys_exofork();
f0104b29:	e9 ab 02 00 00       	jmp    f0104dd9 <syscall+0x439>
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	struct Env *e;
	if(! (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE))
f0104b2e:	83 fb 04             	cmp    $0x4,%ebx
f0104b31:	74 05                	je     f0104b38 <syscall+0x198>
f0104b33:	83 fb 02             	cmp    $0x2,%ebx
f0104b36:	75 2e                	jne    f0104b66 <syscall+0x1c6>
		return -E_INVAL;
	if(envid2env(envid, &e, 1))
f0104b38:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104b3f:	00 
f0104b40:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104b43:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b4a:	89 04 24             	mov    %eax,(%esp)
f0104b4d:	e8 73 e9 ff ff       	call   f01034c5 <envid2env>
f0104b52:	85 c0                	test   %eax,%eax
f0104b54:	75 1a                	jne    f0104b70 <syscall+0x1d0>
		return -E_BAD_ENV;
	e -> env_status = status;
f0104b56:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104b59:	89 58 54             	mov    %ebx,0x54(%eax)
	return 0;
f0104b5c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b61:	e9 73 02 00 00       	jmp    f0104dd9 <syscall+0x439>
	// envid's status.

	// LAB 4: Your code here.
	struct Env *e;
	if(! (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE))
		return -E_INVAL;
f0104b66:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104b6b:	e9 69 02 00 00       	jmp    f0104dd9 <syscall+0x439>
	if(envid2env(envid, &e, 1))
		return -E_BAD_ENV;
f0104b70:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
		case SYS_env_destroy: return sys_env_destroy((envid_t)a1);
		//case NSYSCALLS: NSYSCALLS();break;
		case SYS_yield: sys_yield();return 0;
		// fork functions in Lab4
		case SYS_exofork: return sys_exofork();
		case SYS_env_set_status: return sys_env_set_status((envid_t)a1, (int)a2);
f0104b75:	e9 5f 02 00 00       	jmp    f0104dd9 <syscall+0x439>
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	struct Env *e;
	void *va_align = ROUNDDOWN(va, PGSIZE);
f0104b7a:	89 da                	mov    %ebx,%edx
f0104b7c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	struct Page *p;

	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104b82:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b85:	83 e0 05             	and    $0x5,%eax
f0104b88:	83 f8 05             	cmp    $0x5,%eax
f0104b8b:	74 0f                	je     f0104b9c <syscall+0x1fc>
		(perm|PTE_AVAIL|PTE_W)!=(PTE_U|PTE_P|PTE_AVAIL|PTE_W))
f0104b8d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b90:	0d 02 0e 00 00       	or     $0xe02,%eax
	// LAB 4: Your code here.
	struct Env *e;
	void *va_align = ROUNDDOWN(va, PGSIZE);
	struct Page *p;

	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104b95:	3d 07 0e 00 00       	cmp    $0xe07,%eax
f0104b9a:	75 6f                	jne    f0104c0b <syscall+0x26b>
		(perm|PTE_AVAIL|PTE_W)!=(PTE_U|PTE_P|PTE_AVAIL|PTE_W))
		return -E_INVAL;
	if((size_t)va >= UTOP || va != va_align)
f0104b9c:	39 da                	cmp    %ebx,%edx
f0104b9e:	75 75                	jne    f0104c15 <syscall+0x275>
f0104ba0:	81 fb ff ff bf ee    	cmp    $0xeebfffff,%ebx
f0104ba6:	77 6d                	ja     f0104c15 <syscall+0x275>
		return -E_INVAL;
	if(envid2env(envid, &e, 1))
f0104ba8:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104baf:	00 
f0104bb0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104bb3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104bb7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104bba:	89 14 24             	mov    %edx,(%esp)
f0104bbd:	e8 03 e9 ff ff       	call   f01034c5 <envid2env>
f0104bc2:	85 c0                	test   %eax,%eax
f0104bc4:	75 59                	jne    f0104c1f <syscall+0x27f>
		return -E_BAD_ENV;
	if((p = page_alloc(ALLOC_ZERO)) == NULL) /* alloc a page */
f0104bc6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0104bcd:	e8 6d c6 ff ff       	call   f010123f <page_alloc>
f0104bd2:	89 c6                	mov    %eax,%esi
f0104bd4:	85 c0                	test   %eax,%eax
f0104bd6:	74 51                	je     f0104c29 <syscall+0x289>
		return -E_NO_MEM;
	if(page_insert(e->env_pgdir, p, va, perm)){
f0104bd8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bdb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104bdf:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104be3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104be7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104bea:	8b 40 60             	mov    0x60(%eax),%eax
f0104bed:	89 04 24             	mov    %eax,(%esp)
f0104bf0:	e8 52 c9 ff ff       	call   f0101547 <page_insert>
f0104bf5:	85 c0                	test   %eax,%eax
f0104bf7:	74 3a                	je     f0104c33 <syscall+0x293>
		page_free(p);
f0104bf9:	89 34 24             	mov    %esi,(%esp)
f0104bfc:	e8 c2 c6 ff ff       	call   f01012c3 <page_free>
		return -E_NO_MEM;
f0104c01:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104c06:	e9 ce 01 00 00       	jmp    f0104dd9 <syscall+0x439>
	void *va_align = ROUNDDOWN(va, PGSIZE);
	struct Page *p;

	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
		(perm|PTE_AVAIL|PTE_W)!=(PTE_U|PTE_P|PTE_AVAIL|PTE_W))
		return -E_INVAL;
f0104c0b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104c10:	e9 c4 01 00 00       	jmp    f0104dd9 <syscall+0x439>
	if((size_t)va >= UTOP || va != va_align)
		return -E_INVAL;
f0104c15:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104c1a:	e9 ba 01 00 00       	jmp    f0104dd9 <syscall+0x439>
	if(envid2env(envid, &e, 1))
		return -E_BAD_ENV;
f0104c1f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104c24:	e9 b0 01 00 00       	jmp    f0104dd9 <syscall+0x439>
	if((p = page_alloc(ALLOC_ZERO)) == NULL) /* alloc a page */
		return -E_NO_MEM;
f0104c29:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104c2e:	e9 a6 01 00 00       	jmp    f0104dd9 <syscall+0x439>
	}
	// if(sys_page_unmap(envid, va))
	// 	return -E_NO_MEM;
	// if(sys_page_map(envid, page2kva(p),envid,va,perm))
	// 	return -E_NO_MEM;
	return 0;
f0104c33:	b8 00 00 00 00       	mov    $0x0,%eax
		//case NSYSCALLS: NSYSCALLS();break;
		case SYS_yield: sys_yield();return 0;
		// fork functions in Lab4
		case SYS_exofork: return sys_exofork();
		case SYS_env_set_status: return sys_env_set_status((envid_t)a1, (int)a2);
		case SYS_page_alloc: return sys_page_alloc((envid_t)a1, (void *)a2, (int)a3);
f0104c38:	e9 9c 01 00 00       	jmp    f0104dd9 <syscall+0x439>
	struct Env *src_e, *dst_e;
	struct Page *p;
	pte_t *pte;

	/* check perm */
	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104c3d:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104c40:	83 e0 05             	and    $0x5,%eax
f0104c43:	83 f8 05             	cmp    $0x5,%eax
f0104c46:	74 11                	je     f0104c59 <syscall+0x2b9>
		(perm|PTE_AVAIL)!=(PTE_U|PTE_P|PTE_AVAIL))
f0104c48:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104c4b:	80 cc 0e             	or     $0xe,%ah
	struct Env *src_e, *dst_e;
	struct Page *p;
	pte_t *pte;

	/* check perm */
	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
f0104c4e:	3d 05 0e 00 00       	cmp    $0xe05,%eax
f0104c53:	0f 85 bf 00 00 00    	jne    f0104d18 <syscall+0x378>
		(perm|PTE_AVAIL)!=(PTE_U|PTE_P|PTE_AVAIL))
		return -E_INVAL;

	/* check vas */
	va_align = ROUNDDOWN(srcva, PGSIZE);
f0104c59:	89 d8                	mov    %ebx,%eax
f0104c5b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if((size_t)srcva >= UTOP || srcva != va_align)
f0104c60:	39 c3                	cmp    %eax,%ebx
f0104c62:	0f 85 ba 00 00 00    	jne    f0104d22 <syscall+0x382>
f0104c68:	81 fb ff ff bf ee    	cmp    $0xeebfffff,%ebx
f0104c6e:	0f 87 ae 00 00 00    	ja     f0104d22 <syscall+0x382>
		return -E_INVAL;
	va_align = ROUNDDOWN(dstva, PGSIZE);
f0104c74:	8b 45 18             	mov    0x18(%ebp),%eax
f0104c77:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if((size_t)dstva >= UTOP || dstva != va_align)
f0104c7c:	39 45 18             	cmp    %eax,0x18(%ebp)
f0104c7f:	0f 85 a7 00 00 00    	jne    f0104d2c <syscall+0x38c>
f0104c85:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104c8c:	0f 87 9a 00 00 00    	ja     f0104d2c <syscall+0x38c>
		return -E_INVAL;

	if(envid2env(srcenvid, &src_e, 1)|envid2env(dstenvid, &dst_e, 1))
f0104c92:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104c99:	00 
f0104c9a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104c9d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ca1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104ca4:	89 14 24             	mov    %edx,(%esp)
f0104ca7:	e8 19 e8 ff ff       	call   f01034c5 <envid2env>
f0104cac:	89 c6                	mov    %eax,%esi
f0104cae:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104cb5:	00 
f0104cb6:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0104cb9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104cbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cc0:	89 04 24             	mov    %eax,(%esp)
f0104cc3:	e8 fd e7 ff ff       	call   f01034c5 <envid2env>
f0104cc8:	09 f0                	or     %esi,%eax
f0104cca:	75 6a                	jne    f0104d36 <syscall+0x396>
		return -E_BAD_ENV;

	if((p = page_lookup(src_e->env_pgdir, srcva, &pte)) == NULL)
f0104ccc:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104ccf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104cd3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104cd7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104cda:	8b 40 60             	mov    0x60(%eax),%eax
f0104cdd:	89 04 24             	mov    %eax,(%esp)
f0104ce0:	e8 64 c7 ff ff       	call   f0101449 <page_lookup>
f0104ce5:	85 c0                	test   %eax,%eax
f0104ce7:	74 57                	je     f0104d40 <syscall+0x3a0>
		return -E_INVAL;
	if(page_insert(dst_e->env_pgdir, p,dstva, perm))
f0104ce9:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104cec:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104cf0:	8b 55 18             	mov    0x18(%ebp),%edx
f0104cf3:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104cf7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104cfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104cfe:	8b 40 60             	mov    0x60(%eax),%eax
f0104d01:	89 04 24             	mov    %eax,(%esp)
f0104d04:	e8 3e c8 ff ff       	call   f0101547 <page_insert>
		return -E_NO_MEM;
f0104d09:	83 f8 01             	cmp    $0x1,%eax
f0104d0c:	19 c0                	sbb    %eax,%eax
f0104d0e:	f7 d0                	not    %eax
f0104d10:	83 e0 fc             	and    $0xfffffffc,%eax
f0104d13:	e9 c1 00 00 00       	jmp    f0104dd9 <syscall+0x439>
	pte_t *pte;

	/* check perm */
	if(((perm & (PTE_U|PTE_P))!=(PTE_P|PTE_U))&&
		(perm|PTE_AVAIL)!=(PTE_U|PTE_P|PTE_AVAIL))
		return -E_INVAL;
f0104d18:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d1d:	e9 b7 00 00 00       	jmp    f0104dd9 <syscall+0x439>

	/* check vas */
	va_align = ROUNDDOWN(srcva, PGSIZE);
	if((size_t)srcva >= UTOP || srcva != va_align)
		return -E_INVAL;
f0104d22:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d27:	e9 ad 00 00 00       	jmp    f0104dd9 <syscall+0x439>
	va_align = ROUNDDOWN(dstva, PGSIZE);
	if((size_t)dstva >= UTOP || dstva != va_align)
		return -E_INVAL;
f0104d2c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d31:	e9 a3 00 00 00       	jmp    f0104dd9 <syscall+0x439>

	if(envid2env(srcenvid, &src_e, 1)|envid2env(dstenvid, &dst_e, 1))
		return -E_BAD_ENV;
f0104d36:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104d3b:	e9 99 00 00 00       	jmp    f0104dd9 <syscall+0x439>

	if((p = page_lookup(src_e->env_pgdir, srcva, &pte)) == NULL)
		return -E_INVAL;
f0104d40:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d45:	e9 8f 00 00 00       	jmp    f0104dd9 <syscall+0x439>
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env *e;
	void *va_align = ROUNDDOWN(va, PGSIZE);
f0104d4a:	89 d8                	mov    %ebx,%eax
f0104d4c:	25 00 f0 ff ff       	and    $0xfffff000,%eax

	if((size_t)va >= UTOP || va != va_align)
f0104d51:	39 c3                	cmp    %eax,%ebx
f0104d53:	75 3f                	jne    f0104d94 <syscall+0x3f4>
f0104d55:	81 fb ff ff bf ee    	cmp    $0xeebfffff,%ebx
f0104d5b:	77 37                	ja     f0104d94 <syscall+0x3f4>
		return -E_INVAL;
	if(envid2env(envid, &e, 1))
f0104d5d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104d64:	00 
f0104d65:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104d68:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d6c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d6f:	89 04 24             	mov    %eax,(%esp)
f0104d72:	e8 4e e7 ff ff       	call   f01034c5 <envid2env>
f0104d77:	85 c0                	test   %eax,%eax
f0104d79:	75 20                	jne    f0104d9b <syscall+0x3fb>
		return -E_BAD_ENV;
	page_remove(e->env_pgdir, va);
f0104d7b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104d7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104d82:	8b 40 60             	mov    0x60(%eax),%eax
f0104d85:	89 04 24             	mov    %eax,(%esp)
f0104d88:	e8 6a c7 ff ff       	call   f01014f7 <page_remove>
	return 0;
f0104d8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d92:	eb 45                	jmp    f0104dd9 <syscall+0x439>
	// LAB 4: Your code here.
	struct Env *e;
	void *va_align = ROUNDDOWN(va, PGSIZE);

	if((size_t)va >= UTOP || va != va_align)
		return -E_INVAL;
f0104d94:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d99:	eb 3e                	jmp    f0104dd9 <syscall+0x439>
	if(envid2env(envid, &e, 1))
		return -E_BAD_ENV;
f0104d9b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
		case SYS_exofork: return sys_exofork();
		case SYS_env_set_status: return sys_env_set_status((envid_t)a1, (int)a2);
		case SYS_page_alloc: return sys_page_alloc((envid_t)a1, (void *)a2, (int)a3);
		case SYS_page_map: return sys_page_map((envid_t)a1, (void *)a2,
	     (envid_t)a3, (void *)a4, (int)a5);
		case SYS_page_unmap: return sys_page_unmap((envid_t)a1, (void *)a2);
f0104da0:	eb 37                	jmp    f0104dd9 <syscall+0x439>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *e;
	if(envid2env(envid, &e, 1))
f0104da2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104da9:	00 
f0104daa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104dad:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104db1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104db4:	89 14 24             	mov    %edx,(%esp)
f0104db7:	e8 09 e7 ff ff       	call   f01034c5 <envid2env>
f0104dbc:	85 c0                	test   %eax,%eax
f0104dbe:	75 0d                	jne    f0104dcd <syscall+0x42d>
		return -E_BAD_ENV;
	e->env_pgfault_upcall = func;
f0104dc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104dc3:	89 58 64             	mov    %ebx,0x64(%eax)
	return 0;
f0104dc6:	b8 00 00 00 00       	mov    $0x0,%eax
f0104dcb:	eb 0c                	jmp    f0104dd9 <syscall+0x439>
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *e;
	if(envid2env(envid, &e, 1))
		return -E_BAD_ENV;
f0104dcd:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
		case SYS_env_set_status: return sys_env_set_status((envid_t)a1, (int)a2);
		case SYS_page_alloc: return sys_page_alloc((envid_t)a1, (void *)a2, (int)a3);
		case SYS_page_map: return sys_page_map((envid_t)a1, (void *)a2,
	     (envid_t)a3, (void *)a4, (int)a5);
		case SYS_page_unmap: return sys_page_unmap((envid_t)a1, (void *)a2);
		case SYS_env_set_pgfault_upcall: return sys_env_set_pgfault_upcall((envid_t)a1, (void *)a2);
f0104dd2:	eb 05                	jmp    f0104dd9 <syscall+0x439>
		default: return -E_INVAL;
f0104dd4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	//panic("current %d", syscallno);

	//panic("syscall not implemented");
}
f0104dd9:	83 c4 20             	add    $0x20,%esp
f0104ddc:	5b                   	pop    %ebx
f0104ddd:	5e                   	pop    %esi
f0104dde:	5d                   	pop    %ebp
f0104ddf:	c3                   	ret    

f0104de0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104de0:	55                   	push   %ebp
f0104de1:	89 e5                	mov    %esp,%ebp
f0104de3:	57                   	push   %edi
f0104de4:	56                   	push   %esi
f0104de5:	53                   	push   %ebx
f0104de6:	83 ec 14             	sub    $0x14,%esp
f0104de9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104dec:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0104def:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104df2:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104df5:	8b 1a                	mov    (%edx),%ebx
f0104df7:	8b 01                	mov    (%ecx),%eax
f0104df9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0104dfc:	39 c3                	cmp    %eax,%ebx
f0104dfe:	0f 8f 9f 00 00 00    	jg     f0104ea3 <stab_binsearch+0xc3>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0104e04:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0104e0b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104e0e:	01 d8                	add    %ebx,%eax
f0104e10:	89 c7                	mov    %eax,%edi
f0104e12:	c1 ef 1f             	shr    $0x1f,%edi
f0104e15:	01 c7                	add    %eax,%edi
f0104e17:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104e19:	39 df                	cmp    %ebx,%edi
f0104e1b:	0f 8c ce 00 00 00    	jl     f0104eef <stab_binsearch+0x10f>
f0104e21:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104e24:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0104e27:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0104e2c:	39 f0                	cmp    %esi,%eax
f0104e2e:	0f 84 c0 00 00 00    	je     f0104ef4 <stab_binsearch+0x114>
f0104e34:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0104e38:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0104e3c:	89 f8                	mov    %edi,%eax
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0104e3e:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104e41:	39 d8                	cmp    %ebx,%eax
f0104e43:	0f 8c a6 00 00 00    	jl     f0104eef <stab_binsearch+0x10f>
f0104e49:	0f b6 0a             	movzbl (%edx),%ecx
f0104e4c:	83 ea 0c             	sub    $0xc,%edx
f0104e4f:	39 f1                	cmp    %esi,%ecx
f0104e51:	75 eb                	jne    f0104e3e <stab_binsearch+0x5e>
f0104e53:	e9 9e 00 00 00       	jmp    f0104ef6 <stab_binsearch+0x116>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0104e58:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104e5b:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f0104e5d:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104e60:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0104e67:	eb 2b                	jmp    f0104e94 <stab_binsearch+0xb4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104e69:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104e6c:	76 14                	jbe    f0104e82 <stab_binsearch+0xa2>
			*region_right = m - 1;
f0104e6e:	83 e8 01             	sub    $0x1,%eax
f0104e71:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104e74:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104e77:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104e79:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0104e80:	eb 12                	jmp    f0104e94 <stab_binsearch+0xb4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104e82:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104e85:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0104e87:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104e8b:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104e8d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0104e94:	3b 5d ec             	cmp    -0x14(%ebp),%ebx
f0104e97:	0f 8e 6e ff ff ff    	jle    f0104e0b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104e9d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104ea1:	75 0f                	jne    f0104eb2 <stab_binsearch+0xd2>
		*region_right = *region_left - 1;
f0104ea3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104ea6:	8b 02                	mov    (%edx),%eax
f0104ea8:	83 e8 01             	sub    $0x1,%eax
f0104eab:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104eae:	89 01                	mov    %eax,(%ecx)
f0104eb0:	eb 5c                	jmp    f0104f0e <stab_binsearch+0x12e>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104eb2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104eb5:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104eb7:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104eba:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104ebc:	39 c8                	cmp    %ecx,%eax
f0104ebe:	7e 28                	jle    f0104ee8 <stab_binsearch+0x108>
		     l > *region_left && stabs[l].n_type != type;
f0104ec0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104ec3:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0104ec6:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0104ecb:	39 f2                	cmp    %esi,%edx
f0104ecd:	74 19                	je     f0104ee8 <stab_binsearch+0x108>
f0104ecf:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0104ed3:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104ed7:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104eda:	39 c8                	cmp    %ecx,%eax
f0104edc:	7e 0a                	jle    f0104ee8 <stab_binsearch+0x108>
		     l > *region_left && stabs[l].n_type != type;
f0104ede:	0f b6 1a             	movzbl (%edx),%ebx
f0104ee1:	83 ea 0c             	sub    $0xc,%edx
f0104ee4:	39 f3                	cmp    %esi,%ebx
f0104ee6:	75 ef                	jne    f0104ed7 <stab_binsearch+0xf7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104ee8:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104eeb:	89 02                	mov    %eax,(%edx)
f0104eed:	eb 1f                	jmp    f0104f0e <stab_binsearch+0x12e>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104eef:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104ef2:	eb a0                	jmp    f0104e94 <stab_binsearch+0xb4>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0104ef4:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104ef6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104ef9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0104efc:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104f00:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104f03:	0f 82 4f ff ff ff    	jb     f0104e58 <stab_binsearch+0x78>
f0104f09:	e9 5b ff ff ff       	jmp    f0104e69 <stab_binsearch+0x89>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0104f0e:	83 c4 14             	add    $0x14,%esp
f0104f11:	5b                   	pop    %ebx
f0104f12:	5e                   	pop    %esi
f0104f13:	5f                   	pop    %edi
f0104f14:	5d                   	pop    %ebp
f0104f15:	c3                   	ret    

f0104f16 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104f16:	55                   	push   %ebp
f0104f17:	89 e5                	mov    %esp,%ebp
f0104f19:	57                   	push   %edi
f0104f1a:	56                   	push   %esi
f0104f1b:	53                   	push   %ebx
f0104f1c:	83 ec 5c             	sub    $0x5c,%esp
f0104f1f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104f22:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104f25:	c7 03 3c 7e 10 f0    	movl   $0xf0107e3c,(%ebx)
	info->eip_line = 0;
f0104f2b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104f32:	c7 43 08 3c 7e 10 f0 	movl   $0xf0107e3c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104f39:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104f40:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104f43:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104f4a:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104f50:	0f 87 c9 00 00 00    	ja     f010501f <debuginfo_eip+0x109>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		/* user_mem_check(struct Env *env, const void *va, size_t len, int perm) */
		if(user_mem_check(curenv, (void *)usd, sizeof(*usd), PTE_U))
f0104f56:	e8 71 12 00 00       	call   f01061cc <cpunum>
f0104f5b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104f62:	00 
f0104f63:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0104f6a:	00 
f0104f6b:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0104f72:	00 
f0104f73:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f76:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0104f7c:	89 04 24             	mov    %eax,(%esp)
f0104f7f:	e8 7c e3 ff ff       	call   f0103300 <user_mem_check>
f0104f84:	85 c0                	test   %eax,%eax
f0104f86:	0f 85 7b 02 00 00    	jne    f0105207 <debuginfo_eip+0x2f1>
			return -1;

		stabs = usd->stabs;
f0104f8c:	a1 00 00 20 00       	mov    0x200000,%eax
f0104f91:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0104f94:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104f9a:	8b 15 08 00 20 00    	mov    0x200008,%edx
f0104fa0:	89 55 bc             	mov    %edx,-0x44(%ebp)
		stabstr_end = usd->stabstr_end;
f0104fa3:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f0104fa9:	89 4d c0             	mov    %ecx,-0x40(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) |
f0104fac:	e8 1b 12 00 00       	call   f01061cc <cpunum>
f0104fb1:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104fb8:	00 
f0104fb9:	89 f2                	mov    %esi,%edx
f0104fbb:	2b 55 c4             	sub    -0x3c(%ebp),%edx
f0104fbe:	c1 fa 02             	sar    $0x2,%edx
f0104fc1:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0104fc7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104fcb:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0104fce:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104fd2:	6b c0 74             	imul   $0x74,%eax,%eax
f0104fd5:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f0104fdb:	89 04 24             	mov    %eax,(%esp)
f0104fde:	e8 1d e3 ff ff       	call   f0103300 <user_mem_check>
f0104fe3:	89 45 b8             	mov    %eax,-0x48(%ebp)
		user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U))
f0104fe6:	e8 e1 11 00 00       	call   f01061cc <cpunum>
f0104feb:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104ff2:	00 
f0104ff3:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0104ff6:	2b 55 bc             	sub    -0x44(%ebp),%edx
f0104ff9:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104ffd:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0105000:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105004:	6b c0 74             	imul   $0x74,%eax,%eax
f0105007:	8b 80 28 80 22 f0    	mov    -0xfdd7fd8(%eax),%eax
f010500d:	89 04 24             	mov    %eax,(%esp)
f0105010:	e8 eb e2 ff ff       	call   f0103300 <user_mem_check>
		stabstr = usd->stabstr;
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) |
f0105015:	0b 45 b8             	or     -0x48(%ebp),%eax
f0105018:	74 1f                	je     f0105039 <debuginfo_eip+0x123>
f010501a:	e9 ef 01 00 00       	jmp    f010520e <debuginfo_eip+0x2f8>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010501f:	c7 45 c0 84 60 11 f0 	movl   $0xf0116084,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0105026:	c7 45 bc e5 2a 11 f0 	movl   $0xf0112ae5,-0x44(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010502d:	be e4 2a 11 f0       	mov    $0xf0112ae4,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0105032:	c7 45 c4 14 83 10 f0 	movl   $0xf0108314,-0x3c(%ebp)
			return -1;

	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105039:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010503c:	39 45 bc             	cmp    %eax,-0x44(%ebp)
f010503f:	0f 83 d0 01 00 00    	jae    f0105215 <debuginfo_eip+0x2ff>
f0105045:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0105049:	0f 85 cd 01 00 00    	jne    f010521c <debuginfo_eip+0x306>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010504f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0105056:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f0105059:	c1 fe 02             	sar    $0x2,%esi
f010505c:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0105062:	83 e8 01             	sub    $0x1,%eax
f0105065:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0105068:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010506c:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0105073:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0105076:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0105079:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010507c:	e8 5f fd ff ff       	call   f0104de0 <stab_binsearch>
	if (lfile == 0)
f0105081:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105084:	85 c0                	test   %eax,%eax
f0105086:	0f 84 97 01 00 00    	je     f0105223 <debuginfo_eip+0x30d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010508c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010508f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105092:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0105095:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105099:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01050a0:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01050a3:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01050a6:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01050a9:	e8 32 fd ff ff       	call   f0104de0 <stab_binsearch>

	if (lfun <= rfun) {
f01050ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01050b1:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01050b4:	39 f0                	cmp    %esi,%eax
f01050b6:	7f 32                	jg     f01050ea <debuginfo_eip+0x1d4>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01050b8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01050bb:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01050be:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f01050c1:	8b 0a                	mov    (%edx),%ecx
f01050c3:	89 4d b4             	mov    %ecx,-0x4c(%ebp)
f01050c6:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f01050c9:	2b 4d bc             	sub    -0x44(%ebp),%ecx
f01050cc:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f01050cf:	73 09                	jae    f01050da <debuginfo_eip+0x1c4>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01050d1:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f01050d4:	03 4d bc             	add    -0x44(%ebp),%ecx
f01050d7:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01050da:	8b 52 08             	mov    0x8(%edx),%edx
f01050dd:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01050e0:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01050e2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01050e5:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01050e8:	eb 0f                	jmp    f01050f9 <debuginfo_eip+0x1e3>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01050ea:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f01050ed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01050f0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01050f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01050f6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01050f9:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0105100:	00 
f0105101:	8b 43 08             	mov    0x8(%ebx),%eax
f0105104:	89 04 24             	mov    %eax,(%esp)
f0105107:	e8 ef 09 00 00       	call   f0105afb <strfind>
f010510c:	2b 43 08             	sub    0x8(%ebx),%eax
f010510f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f0105112:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105116:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010511d:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0105120:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105123:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0105126:	e8 b5 fc ff ff       	call   f0104de0 <stab_binsearch>
	if(lline > rline)
f010512b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010512e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0105131:	0f 8f f3 00 00 00    	jg     f010522a <debuginfo_eip+0x314>
		return -1;
		//cprintf("lline %d, rline %d",lline, rline);
	info -> eip_line = stabs[lline].n_desc;
f0105137:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010513a:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f010513d:	0f b7 44 82 06       	movzwl 0x6(%edx,%eax,4),%eax
f0105142:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0105145:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0105148:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010514b:	39 fa                	cmp    %edi,%edx
f010514d:	7c 6b                	jl     f01051ba <debuginfo_eip+0x2a4>
	       && stabs[lline].n_type != N_SOL
f010514f:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0105152:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0105155:	8d 34 81             	lea    (%ecx,%eax,4),%esi
f0105158:	0f b6 46 04          	movzbl 0x4(%esi),%eax
f010515c:	88 45 b4             	mov    %al,-0x4c(%ebp)
f010515f:	3c 84                	cmp    $0x84,%al
f0105161:	74 3f                	je     f01051a2 <debuginfo_eip+0x28c>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0105163:	8d 4c 52 fd          	lea    -0x3(%edx,%edx,2),%ecx
f0105167:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010516a:	8d 04 88             	lea    (%eax,%ecx,4),%eax
f010516d:	89 45 b8             	mov    %eax,-0x48(%ebp)
f0105170:	0f b6 4d b4          	movzbl -0x4c(%ebp),%ecx
f0105174:	eb 1a                	jmp    f0105190 <debuginfo_eip+0x27a>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0105176:	83 ea 01             	sub    $0x1,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0105179:	39 fa                	cmp    %edi,%edx
f010517b:	7c 3d                	jl     f01051ba <debuginfo_eip+0x2a4>
	       && stabs[lline].n_type != N_SOL
f010517d:	89 c6                	mov    %eax,%esi
f010517f:	83 e8 0c             	sub    $0xc,%eax
f0105182:	0f b6 48 10          	movzbl 0x10(%eax),%ecx
f0105186:	80 f9 84             	cmp    $0x84,%cl
f0105189:	75 05                	jne    f0105190 <debuginfo_eip+0x27a>
f010518b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010518e:	eb 12                	jmp    f01051a2 <debuginfo_eip+0x28c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0105190:	80 f9 64             	cmp    $0x64,%cl
f0105193:	75 e1                	jne    f0105176 <debuginfo_eip+0x260>
f0105195:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0105199:	74 db                	je     f0105176 <debuginfo_eip+0x260>
f010519b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010519e:	39 d7                	cmp    %edx,%edi
f01051a0:	7f 18                	jg     f01051ba <debuginfo_eip+0x2a4>
f01051a2:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01051a5:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01051a8:	8b 04 82             	mov    (%edx,%eax,4),%eax
f01051ab:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01051ae:	2b 55 bc             	sub    -0x44(%ebp),%edx
f01051b1:	39 d0                	cmp    %edx,%eax
f01051b3:	73 05                	jae    f01051ba <debuginfo_eip+0x2a4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01051b5:	03 45 bc             	add    -0x44(%ebp),%eax
f01051b8:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01051ba:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01051bd:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f01051c0:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01051c5:	39 f2                	cmp    %esi,%edx
f01051c7:	7d 7b                	jge    f0105244 <debuginfo_eip+0x32e>
		for (lline = lfun + 1;
f01051c9:	8d 42 01             	lea    0x1(%edx),%eax
f01051cc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01051cf:	39 c6                	cmp    %eax,%esi
f01051d1:	7e 5e                	jle    f0105231 <debuginfo_eip+0x31b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01051d3:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01051d6:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01051d9:	80 7c 81 04 a0       	cmpb   $0xa0,0x4(%ecx,%eax,4)
f01051de:	75 58                	jne    f0105238 <debuginfo_eip+0x322>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01051e0:	8d 42 02             	lea    0x2(%edx),%eax

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01051e3:	8d 14 52             	lea    (%edx,%edx,2),%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01051e6:	8d 54 91 1c          	lea    0x1c(%ecx,%edx,4),%edx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01051ea:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01051ee:	39 f0                	cmp    %esi,%eax
f01051f0:	74 4d                	je     f010523f <debuginfo_eip+0x329>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01051f2:	0f b6 0a             	movzbl (%edx),%ecx
f01051f5:	83 c0 01             	add    $0x1,%eax
f01051f8:	83 c2 0c             	add    $0xc,%edx
f01051fb:	80 f9 a0             	cmp    $0xa0,%cl
f01051fe:	74 ea                	je     f01051ea <debuginfo_eip+0x2d4>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0105200:	b8 00 00 00 00       	mov    $0x0,%eax
f0105205:	eb 3d                	jmp    f0105244 <debuginfo_eip+0x32e>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		/* user_mem_check(struct Env *env, const void *va, size_t len, int perm) */
		if(user_mem_check(curenv, (void *)usd, sizeof(*usd), PTE_U))
			return -1;
f0105207:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010520c:	eb 36                	jmp    f0105244 <debuginfo_eip+0x32e>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) |
		user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
f010520e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105213:	eb 2f                	jmp    f0105244 <debuginfo_eip+0x32e>

	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0105215:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010521a:	eb 28                	jmp    f0105244 <debuginfo_eip+0x32e>
f010521c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105221:	eb 21                	jmp    f0105244 <debuginfo_eip+0x32e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0105223:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105228:	eb 1a                	jmp    f0105244 <debuginfo_eip+0x32e>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
	if(lline > rline)
		return -1;
f010522a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010522f:	eb 13                	jmp    f0105244 <debuginfo_eip+0x32e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0105231:	b8 00 00 00 00       	mov    $0x0,%eax
f0105236:	eb 0c                	jmp    f0105244 <debuginfo_eip+0x32e>
f0105238:	b8 00 00 00 00       	mov    $0x0,%eax
f010523d:	eb 05                	jmp    f0105244 <debuginfo_eip+0x32e>
f010523f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105244:	83 c4 5c             	add    $0x5c,%esp
f0105247:	5b                   	pop    %ebx
f0105248:	5e                   	pop    %esi
f0105249:	5f                   	pop    %edi
f010524a:	5d                   	pop    %ebp
f010524b:	c3                   	ret    
f010524c:	66 90                	xchg   %ax,%ax
f010524e:	66 90                	xchg   %ax,%ax

f0105250 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0105250:	55                   	push   %ebp
f0105251:	89 e5                	mov    %esp,%ebp
f0105253:	57                   	push   %edi
f0105254:	56                   	push   %esi
f0105255:	53                   	push   %ebx
f0105256:	83 ec 4c             	sub    $0x4c,%esp
f0105259:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010525c:	89 d7                	mov    %edx,%edi
f010525e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0105261:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0105264:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105267:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010526a:	b8 00 00 00 00       	mov    $0x0,%eax
f010526f:	39 d8                	cmp    %ebx,%eax
f0105271:	72 17                	jb     f010528a <printnum+0x3a>
f0105273:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0105276:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0105279:	76 0f                	jbe    f010528a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010527b:	8b 75 14             	mov    0x14(%ebp),%esi
f010527e:	83 ee 01             	sub    $0x1,%esi
f0105281:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105284:	85 f6                	test   %esi,%esi
f0105286:	7f 63                	jg     f01052eb <printnum+0x9b>
f0105288:	eb 75                	jmp    f01052ff <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010528a:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010528d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0105291:	8b 45 14             	mov    0x14(%ebp),%eax
f0105294:	83 e8 01             	sub    $0x1,%eax
f0105297:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010529b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010529e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01052a2:	8b 44 24 08          	mov    0x8(%esp),%eax
f01052a6:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01052aa:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01052ad:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01052b0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01052b7:	00 
f01052b8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01052bb:	89 1c 24             	mov    %ebx,(%esp)
f01052be:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01052c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01052c5:	e8 86 13 00 00       	call   f0106650 <__udivdi3>
f01052ca:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01052cd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01052d0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01052d4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01052d8:	89 04 24             	mov    %eax,(%esp)
f01052db:	89 54 24 04          	mov    %edx,0x4(%esp)
f01052df:	89 fa                	mov    %edi,%edx
f01052e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01052e4:	e8 67 ff ff ff       	call   f0105250 <printnum>
f01052e9:	eb 14                	jmp    f01052ff <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01052eb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01052ef:	8b 45 18             	mov    0x18(%ebp),%eax
f01052f2:	89 04 24             	mov    %eax,(%esp)
f01052f5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01052f7:	83 ee 01             	sub    $0x1,%esi
f01052fa:	75 ef                	jne    f01052eb <printnum+0x9b>
f01052fc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01052ff:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105303:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105307:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010530a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010530e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0105315:	00 
f0105316:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0105319:	89 1c 24             	mov    %ebx,(%esp)
f010531c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010531f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105323:	e8 78 14 00 00       	call   f01067a0 <__umoddi3>
f0105328:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010532c:	0f be 80 46 7e 10 f0 	movsbl -0xfef81ba(%eax),%eax
f0105333:	89 04 24             	mov    %eax,(%esp)
f0105336:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105339:	ff d0                	call   *%eax
}
f010533b:	83 c4 4c             	add    $0x4c,%esp
f010533e:	5b                   	pop    %ebx
f010533f:	5e                   	pop    %esi
f0105340:	5f                   	pop    %edi
f0105341:	5d                   	pop    %ebp
f0105342:	c3                   	ret    

f0105343 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0105343:	55                   	push   %ebp
f0105344:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0105346:	83 fa 01             	cmp    $0x1,%edx
f0105349:	7e 0e                	jle    f0105359 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010534b:	8b 10                	mov    (%eax),%edx
f010534d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0105350:	89 08                	mov    %ecx,(%eax)
f0105352:	8b 02                	mov    (%edx),%eax
f0105354:	8b 52 04             	mov    0x4(%edx),%edx
f0105357:	eb 22                	jmp    f010537b <getuint+0x38>
	else if (lflag)
f0105359:	85 d2                	test   %edx,%edx
f010535b:	74 10                	je     f010536d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010535d:	8b 10                	mov    (%eax),%edx
f010535f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0105362:	89 08                	mov    %ecx,(%eax)
f0105364:	8b 02                	mov    (%edx),%eax
f0105366:	ba 00 00 00 00       	mov    $0x0,%edx
f010536b:	eb 0e                	jmp    f010537b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010536d:	8b 10                	mov    (%eax),%edx
f010536f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0105372:	89 08                	mov    %ecx,(%eax)
f0105374:	8b 02                	mov    (%edx),%eax
f0105376:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010537b:	5d                   	pop    %ebp
f010537c:	c3                   	ret    

f010537d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010537d:	55                   	push   %ebp
f010537e:	89 e5                	mov    %esp,%ebp
f0105380:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0105383:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105387:	8b 10                	mov    (%eax),%edx
f0105389:	3b 50 04             	cmp    0x4(%eax),%edx
f010538c:	73 0a                	jae    f0105398 <sprintputch+0x1b>
		*b->buf++ = ch;
f010538e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105391:	88 0a                	mov    %cl,(%edx)
f0105393:	83 c2 01             	add    $0x1,%edx
f0105396:	89 10                	mov    %edx,(%eax)
}
f0105398:	5d                   	pop    %ebp
f0105399:	c3                   	ret    

f010539a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010539a:	55                   	push   %ebp
f010539b:	89 e5                	mov    %esp,%ebp
f010539d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01053a0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01053a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01053a7:	8b 45 10             	mov    0x10(%ebp),%eax
f01053aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01053ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01053b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01053b8:	89 04 24             	mov    %eax,(%esp)
f01053bb:	e8 02 00 00 00       	call   f01053c2 <vprintfmt>
	va_end(ap);
}
f01053c0:	c9                   	leave  
f01053c1:	c3                   	ret    

f01053c2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01053c2:	55                   	push   %ebp
f01053c3:	89 e5                	mov    %esp,%ebp
f01053c5:	57                   	push   %edi
f01053c6:	56                   	push   %esi
f01053c7:	53                   	push   %ebx
f01053c8:	83 ec 4c             	sub    $0x4c,%esp
f01053cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01053ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01053d1:	8b 7d 10             	mov    0x10(%ebp),%edi
f01053d4:	eb 11                	jmp    f01053e7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01053d6:	85 c0                	test   %eax,%eax
f01053d8:	0f 84 db 03 00 00    	je     f01057b9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f01053de:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01053e2:	89 04 24             	mov    %eax,(%esp)
f01053e5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01053e7:	0f b6 07             	movzbl (%edi),%eax
f01053ea:	83 c7 01             	add    $0x1,%edi
f01053ed:	83 f8 25             	cmp    $0x25,%eax
f01053f0:	75 e4                	jne    f01053d6 <vprintfmt+0x14>
f01053f2:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f01053f6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f01053fd:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105404:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010540b:	ba 00 00 00 00       	mov    $0x0,%edx
f0105410:	eb 2b                	jmp    f010543d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105412:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0105415:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0105419:	eb 22                	jmp    f010543d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010541b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010541e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0105422:	eb 19                	jmp    f010543d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105424:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0105427:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010542e:	eb 0d                	jmp    f010543d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0105430:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105433:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105436:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010543d:	0f b6 0f             	movzbl (%edi),%ecx
f0105440:	8d 47 01             	lea    0x1(%edi),%eax
f0105443:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105446:	0f b6 07             	movzbl (%edi),%eax
f0105449:	83 e8 23             	sub    $0x23,%eax
f010544c:	3c 55                	cmp    $0x55,%al
f010544e:	0f 87 40 03 00 00    	ja     f0105794 <vprintfmt+0x3d2>
f0105454:	0f b6 c0             	movzbl %al,%eax
f0105457:	ff 24 85 00 7f 10 f0 	jmp    *-0xfef8100(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010545e:	83 e9 30             	sub    $0x30,%ecx
f0105461:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f0105464:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0105468:	8d 48 d0             	lea    -0x30(%eax),%ecx
f010546b:	83 f9 09             	cmp    $0x9,%ecx
f010546e:	77 57                	ja     f01054c7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105470:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0105473:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0105476:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105479:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010547c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f010547f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0105483:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0105486:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0105489:	83 f9 09             	cmp    $0x9,%ecx
f010548c:	76 eb                	jbe    f0105479 <vprintfmt+0xb7>
f010548e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105491:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0105494:	eb 34                	jmp    f01054ca <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105496:	8b 45 14             	mov    0x14(%ebp),%eax
f0105499:	8d 48 04             	lea    0x4(%eax),%ecx
f010549c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010549f:	8b 00                	mov    (%eax),%eax
f01054a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01054a4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01054a7:	eb 21                	jmp    f01054ca <vprintfmt+0x108>

		case '.':
			if (width < 0)
f01054a9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01054ad:	0f 88 71 ff ff ff    	js     f0105424 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01054b3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01054b6:	eb 85                	jmp    f010543d <vprintfmt+0x7b>
f01054b8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01054bb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01054c2:	e9 76 ff ff ff       	jmp    f010543d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01054c7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01054ca:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01054ce:	0f 89 69 ff ff ff    	jns    f010543d <vprintfmt+0x7b>
f01054d4:	e9 57 ff ff ff       	jmp    f0105430 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01054d9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01054dc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01054df:	e9 59 ff ff ff       	jmp    f010543d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01054e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01054e7:	8d 50 04             	lea    0x4(%eax),%edx
f01054ea:	89 55 14             	mov    %edx,0x14(%ebp)
f01054ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01054f1:	8b 00                	mov    (%eax),%eax
f01054f3:	89 04 24             	mov    %eax,(%esp)
f01054f6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01054f8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01054fb:	e9 e7 fe ff ff       	jmp    f01053e7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0105500:	8b 45 14             	mov    0x14(%ebp),%eax
f0105503:	8d 50 04             	lea    0x4(%eax),%edx
f0105506:	89 55 14             	mov    %edx,0x14(%ebp)
f0105509:	8b 00                	mov    (%eax),%eax
f010550b:	89 c2                	mov    %eax,%edx
f010550d:	c1 fa 1f             	sar    $0x1f,%edx
f0105510:	31 d0                	xor    %edx,%eax
f0105512:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0105514:	83 f8 08             	cmp    $0x8,%eax
f0105517:	7f 0b                	jg     f0105524 <vprintfmt+0x162>
f0105519:	8b 14 85 60 80 10 f0 	mov    -0xfef7fa0(,%eax,4),%edx
f0105520:	85 d2                	test   %edx,%edx
f0105522:	75 20                	jne    f0105544 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0105524:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105528:	c7 44 24 08 5e 7e 10 	movl   $0xf0107e5e,0x8(%esp)
f010552f:	f0 
f0105530:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105534:	89 34 24             	mov    %esi,(%esp)
f0105537:	e8 5e fe ff ff       	call   f010539a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010553c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010553f:	e9 a3 fe ff ff       	jmp    f01053e7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0105544:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105548:	c7 44 24 08 26 76 10 	movl   $0xf0107626,0x8(%esp)
f010554f:	f0 
f0105550:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105554:	89 34 24             	mov    %esi,(%esp)
f0105557:	e8 3e fe ff ff       	call   f010539a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010555c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010555f:	e9 83 fe ff ff       	jmp    f01053e7 <vprintfmt+0x25>
f0105564:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105567:	8b 7d d8             	mov    -0x28(%ebp),%edi
f010556a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010556d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105570:	8d 50 04             	lea    0x4(%eax),%edx
f0105573:	89 55 14             	mov    %edx,0x14(%ebp)
f0105576:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0105578:	85 ff                	test   %edi,%edi
f010557a:	b8 57 7e 10 f0       	mov    $0xf0107e57,%eax
f010557f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0105582:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0105586:	74 06                	je     f010558e <vprintfmt+0x1cc>
f0105588:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010558c:	7f 16                	jg     f01055a4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010558e:	0f b6 17             	movzbl (%edi),%edx
f0105591:	0f be c2             	movsbl %dl,%eax
f0105594:	83 c7 01             	add    $0x1,%edi
f0105597:	85 c0                	test   %eax,%eax
f0105599:	0f 85 9f 00 00 00    	jne    f010563e <vprintfmt+0x27c>
f010559f:	e9 8b 00 00 00       	jmp    f010562f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01055a4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01055a8:	89 3c 24             	mov    %edi,(%esp)
f01055ab:	e8 92 03 00 00       	call   f0105942 <strnlen>
f01055b0:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01055b3:	29 c2                	sub    %eax,%edx
f01055b5:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01055b8:	85 d2                	test   %edx,%edx
f01055ba:	7e d2                	jle    f010558e <vprintfmt+0x1cc>
					putch(padc, putdat);
f01055bc:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f01055c0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01055c3:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01055c6:	89 d7                	mov    %edx,%edi
f01055c8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01055cc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01055cf:	89 04 24             	mov    %eax,(%esp)
f01055d2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01055d4:	83 ef 01             	sub    $0x1,%edi
f01055d7:	75 ef                	jne    f01055c8 <vprintfmt+0x206>
f01055d9:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01055dc:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01055df:	eb ad                	jmp    f010558e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01055e1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01055e5:	74 20                	je     f0105607 <vprintfmt+0x245>
f01055e7:	0f be d2             	movsbl %dl,%edx
f01055ea:	83 ea 20             	sub    $0x20,%edx
f01055ed:	83 fa 5e             	cmp    $0x5e,%edx
f01055f0:	76 15                	jbe    f0105607 <vprintfmt+0x245>
					putch('?', putdat);
f01055f2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01055f5:	89 54 24 04          	mov    %edx,0x4(%esp)
f01055f9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0105600:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0105603:	ff d1                	call   *%ecx
f0105605:	eb 0f                	jmp    f0105616 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0105607:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010560a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010560e:	89 04 24             	mov    %eax,(%esp)
f0105611:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0105614:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105616:	83 eb 01             	sub    $0x1,%ebx
f0105619:	0f b6 17             	movzbl (%edi),%edx
f010561c:	0f be c2             	movsbl %dl,%eax
f010561f:	83 c7 01             	add    $0x1,%edi
f0105622:	85 c0                	test   %eax,%eax
f0105624:	75 24                	jne    f010564a <vprintfmt+0x288>
f0105626:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0105629:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010562c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010562f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105632:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0105636:	0f 8e ab fd ff ff    	jle    f01053e7 <vprintfmt+0x25>
f010563c:	eb 20                	jmp    f010565e <vprintfmt+0x29c>
f010563e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0105641:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0105644:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0105647:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010564a:	85 f6                	test   %esi,%esi
f010564c:	78 93                	js     f01055e1 <vprintfmt+0x21f>
f010564e:	83 ee 01             	sub    $0x1,%esi
f0105651:	79 8e                	jns    f01055e1 <vprintfmt+0x21f>
f0105653:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0105656:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0105659:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010565c:	eb d1                	jmp    f010562f <vprintfmt+0x26d>
f010565e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0105661:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105665:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010566c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010566e:	83 ef 01             	sub    $0x1,%edi
f0105671:	75 ee                	jne    f0105661 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105673:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0105676:	e9 6c fd ff ff       	jmp    f01053e7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010567b:	83 fa 01             	cmp    $0x1,%edx
f010567e:	66 90                	xchg   %ax,%ax
f0105680:	7e 16                	jle    f0105698 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f0105682:	8b 45 14             	mov    0x14(%ebp),%eax
f0105685:	8d 50 08             	lea    0x8(%eax),%edx
f0105688:	89 55 14             	mov    %edx,0x14(%ebp)
f010568b:	8b 10                	mov    (%eax),%edx
f010568d:	8b 48 04             	mov    0x4(%eax),%ecx
f0105690:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0105693:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0105696:	eb 32                	jmp    f01056ca <vprintfmt+0x308>
	else if (lflag)
f0105698:	85 d2                	test   %edx,%edx
f010569a:	74 18                	je     f01056b4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f010569c:	8b 45 14             	mov    0x14(%ebp),%eax
f010569f:	8d 50 04             	lea    0x4(%eax),%edx
f01056a2:	89 55 14             	mov    %edx,0x14(%ebp)
f01056a5:	8b 00                	mov    (%eax),%eax
f01056a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01056aa:	89 c1                	mov    %eax,%ecx
f01056ac:	c1 f9 1f             	sar    $0x1f,%ecx
f01056af:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01056b2:	eb 16                	jmp    f01056ca <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f01056b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01056b7:	8d 50 04             	lea    0x4(%eax),%edx
f01056ba:	89 55 14             	mov    %edx,0x14(%ebp)
f01056bd:	8b 00                	mov    (%eax),%eax
f01056bf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01056c2:	89 c7                	mov    %eax,%edi
f01056c4:	c1 ff 1f             	sar    $0x1f,%edi
f01056c7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01056ca:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01056cd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01056d0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01056d5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01056d9:	79 7d                	jns    f0105758 <vprintfmt+0x396>
				putch('-', putdat);
f01056db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01056df:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01056e6:	ff d6                	call   *%esi
				num = -(long long) num;
f01056e8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01056eb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01056ee:	f7 d8                	neg    %eax
f01056f0:	83 d2 00             	adc    $0x0,%edx
f01056f3:	f7 da                	neg    %edx
			}
			base = 10;
f01056f5:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01056fa:	eb 5c                	jmp    f0105758 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01056fc:	8d 45 14             	lea    0x14(%ebp),%eax
f01056ff:	e8 3f fc ff ff       	call   f0105343 <getuint>
			base = 10;
f0105704:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105709:	eb 4d                	jmp    f0105758 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010570b:	8d 45 14             	lea    0x14(%ebp),%eax
f010570e:	e8 30 fc ff ff       	call   f0105343 <getuint>
			base = 8;
f0105713:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105718:	eb 3e                	jmp    f0105758 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
f010571a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010571e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0105725:	ff d6                	call   *%esi
			putch('x', putdat);
f0105727:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010572b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0105732:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0105734:	8b 45 14             	mov    0x14(%ebp),%eax
f0105737:	8d 50 04             	lea    0x4(%eax),%edx
f010573a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010573d:	8b 00                	mov    (%eax),%eax
f010573f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0105744:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105749:	eb 0d                	jmp    f0105758 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010574b:	8d 45 14             	lea    0x14(%ebp),%eax
f010574e:	e8 f0 fb ff ff       	call   f0105343 <getuint>
			base = 16;
f0105753:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105758:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010575c:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0105760:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0105763:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105767:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010576b:	89 04 24             	mov    %eax,(%esp)
f010576e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105772:	89 da                	mov    %ebx,%edx
f0105774:	89 f0                	mov    %esi,%eax
f0105776:	e8 d5 fa ff ff       	call   f0105250 <printnum>
			break;
f010577b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010577e:	e9 64 fc ff ff       	jmp    f01053e7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105783:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105787:	89 0c 24             	mov    %ecx,(%esp)
f010578a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010578c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010578f:	e9 53 fc ff ff       	jmp    f01053e7 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105794:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105798:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010579f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01057a1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01057a5:	0f 84 3c fc ff ff    	je     f01053e7 <vprintfmt+0x25>
f01057ab:	83 ef 01             	sub    $0x1,%edi
f01057ae:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01057b2:	75 f7                	jne    f01057ab <vprintfmt+0x3e9>
f01057b4:	e9 2e fc ff ff       	jmp    f01053e7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01057b9:	83 c4 4c             	add    $0x4c,%esp
f01057bc:	5b                   	pop    %ebx
f01057bd:	5e                   	pop    %esi
f01057be:	5f                   	pop    %edi
f01057bf:	5d                   	pop    %ebp
f01057c0:	c3                   	ret    

f01057c1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01057c1:	55                   	push   %ebp
f01057c2:	89 e5                	mov    %esp,%ebp
f01057c4:	83 ec 28             	sub    $0x28,%esp
f01057c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01057ca:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01057cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01057d0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01057d4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01057d7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01057de:	85 d2                	test   %edx,%edx
f01057e0:	7e 30                	jle    f0105812 <vsnprintf+0x51>
f01057e2:	85 c0                	test   %eax,%eax
f01057e4:	74 2c                	je     f0105812 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01057e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01057e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01057ed:	8b 45 10             	mov    0x10(%ebp),%eax
f01057f0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01057f4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01057f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01057fb:	c7 04 24 7d 53 10 f0 	movl   $0xf010537d,(%esp)
f0105802:	e8 bb fb ff ff       	call   f01053c2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105807:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010580a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010580d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105810:	eb 05                	jmp    f0105817 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105812:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105817:	c9                   	leave  
f0105818:	c3                   	ret    

f0105819 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105819:	55                   	push   %ebp
f010581a:	89 e5                	mov    %esp,%ebp
f010581c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010581f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105822:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105826:	8b 45 10             	mov    0x10(%ebp),%eax
f0105829:	89 44 24 08          	mov    %eax,0x8(%esp)
f010582d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105830:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105834:	8b 45 08             	mov    0x8(%ebp),%eax
f0105837:	89 04 24             	mov    %eax,(%esp)
f010583a:	e8 82 ff ff ff       	call   f01057c1 <vsnprintf>
	va_end(ap);

	return rc;
}
f010583f:	c9                   	leave  
f0105840:	c3                   	ret    
f0105841:	66 90                	xchg   %ax,%ax
f0105843:	66 90                	xchg   %ax,%ax
f0105845:	66 90                	xchg   %ax,%ax
f0105847:	66 90                	xchg   %ax,%ax
f0105849:	66 90                	xchg   %ax,%ax
f010584b:	66 90                	xchg   %ax,%ax
f010584d:	66 90                	xchg   %ax,%ax
f010584f:	90                   	nop

f0105850 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105850:	55                   	push   %ebp
f0105851:	89 e5                	mov    %esp,%ebp
f0105853:	57                   	push   %edi
f0105854:	56                   	push   %esi
f0105855:	53                   	push   %ebx
f0105856:	83 ec 1c             	sub    $0x1c,%esp
f0105859:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010585c:	85 c0                	test   %eax,%eax
f010585e:	74 10                	je     f0105870 <readline+0x20>
		cprintf("%s", prompt);
f0105860:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105864:	c7 04 24 26 76 10 f0 	movl   $0xf0107626,(%esp)
f010586b:	e8 4e e5 ff ff       	call   f0103dbe <cprintf>

	i = 0;
	echoing = iscons(0);
f0105870:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0105877:	e8 5a b0 ff ff       	call   f01008d6 <iscons>
f010587c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010587e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105883:	e8 3d b0 ff ff       	call   f01008c5 <getchar>
f0105888:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010588a:	85 c0                	test   %eax,%eax
f010588c:	79 17                	jns    f01058a5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010588e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105892:	c7 04 24 84 80 10 f0 	movl   $0xf0108084,(%esp)
f0105899:	e8 20 e5 ff ff       	call   f0103dbe <cprintf>
			return NULL;
f010589e:	b8 00 00 00 00       	mov    $0x0,%eax
f01058a3:	eb 6d                	jmp    f0105912 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01058a5:	83 f8 7f             	cmp    $0x7f,%eax
f01058a8:	74 05                	je     f01058af <readline+0x5f>
f01058aa:	83 f8 08             	cmp    $0x8,%eax
f01058ad:	75 19                	jne    f01058c8 <readline+0x78>
f01058af:	85 f6                	test   %esi,%esi
f01058b1:	7e 15                	jle    f01058c8 <readline+0x78>
			if (echoing)
f01058b3:	85 ff                	test   %edi,%edi
f01058b5:	74 0c                	je     f01058c3 <readline+0x73>
				cputchar('\b');
f01058b7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01058be:	e8 f2 af ff ff       	call   f01008b5 <cputchar>
			i--;
f01058c3:	83 ee 01             	sub    $0x1,%esi
f01058c6:	eb bb                	jmp    f0105883 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01058c8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01058ce:	7f 1c                	jg     f01058ec <readline+0x9c>
f01058d0:	83 fb 1f             	cmp    $0x1f,%ebx
f01058d3:	7e 17                	jle    f01058ec <readline+0x9c>
			if (echoing)
f01058d5:	85 ff                	test   %edi,%edi
f01058d7:	74 08                	je     f01058e1 <readline+0x91>
				cputchar(c);
f01058d9:	89 1c 24             	mov    %ebx,(%esp)
f01058dc:	e8 d4 af ff ff       	call   f01008b5 <cputchar>
			buf[i++] = c;
f01058e1:	88 9e 80 7a 22 f0    	mov    %bl,-0xfdd8580(%esi)
f01058e7:	83 c6 01             	add    $0x1,%esi
f01058ea:	eb 97                	jmp    f0105883 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01058ec:	83 fb 0d             	cmp    $0xd,%ebx
f01058ef:	74 05                	je     f01058f6 <readline+0xa6>
f01058f1:	83 fb 0a             	cmp    $0xa,%ebx
f01058f4:	75 8d                	jne    f0105883 <readline+0x33>
			if (echoing)
f01058f6:	85 ff                	test   %edi,%edi
f01058f8:	74 0c                	je     f0105906 <readline+0xb6>
				cputchar('\n');
f01058fa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0105901:	e8 af af ff ff       	call   f01008b5 <cputchar>
			buf[i] = 0;
f0105906:	c6 86 80 7a 22 f0 00 	movb   $0x0,-0xfdd8580(%esi)
			return buf;
f010590d:	b8 80 7a 22 f0       	mov    $0xf0227a80,%eax
		}
	}
}
f0105912:	83 c4 1c             	add    $0x1c,%esp
f0105915:	5b                   	pop    %ebx
f0105916:	5e                   	pop    %esi
f0105917:	5f                   	pop    %edi
f0105918:	5d                   	pop    %ebp
f0105919:	c3                   	ret    
f010591a:	66 90                	xchg   %ax,%ax
f010591c:	66 90                	xchg   %ax,%ax
f010591e:	66 90                	xchg   %ax,%ax

f0105920 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105920:	55                   	push   %ebp
f0105921:	89 e5                	mov    %esp,%ebp
f0105923:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105926:	80 3a 00             	cmpb   $0x0,(%edx)
f0105929:	74 10                	je     f010593b <strlen+0x1b>
f010592b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0105930:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105933:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105937:	75 f7                	jne    f0105930 <strlen+0x10>
f0105939:	eb 05                	jmp    f0105940 <strlen+0x20>
f010593b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0105940:	5d                   	pop    %ebp
f0105941:	c3                   	ret    

f0105942 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105942:	55                   	push   %ebp
f0105943:	89 e5                	mov    %esp,%ebp
f0105945:	53                   	push   %ebx
f0105946:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0105949:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010594c:	85 c9                	test   %ecx,%ecx
f010594e:	74 1c                	je     f010596c <strnlen+0x2a>
f0105950:	80 3b 00             	cmpb   $0x0,(%ebx)
f0105953:	74 1e                	je     f0105973 <strnlen+0x31>
f0105955:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010595a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010595c:	39 ca                	cmp    %ecx,%edx
f010595e:	74 18                	je     f0105978 <strnlen+0x36>
f0105960:	83 c2 01             	add    $0x1,%edx
f0105963:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0105968:	75 f0                	jne    f010595a <strnlen+0x18>
f010596a:	eb 0c                	jmp    f0105978 <strnlen+0x36>
f010596c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105971:	eb 05                	jmp    f0105978 <strnlen+0x36>
f0105973:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0105978:	5b                   	pop    %ebx
f0105979:	5d                   	pop    %ebp
f010597a:	c3                   	ret    

f010597b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010597b:	55                   	push   %ebp
f010597c:	89 e5                	mov    %esp,%ebp
f010597e:	53                   	push   %ebx
f010597f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105982:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105985:	89 c2                	mov    %eax,%edx
f0105987:	0f b6 19             	movzbl (%ecx),%ebx
f010598a:	88 1a                	mov    %bl,(%edx)
f010598c:	83 c2 01             	add    $0x1,%edx
f010598f:	83 c1 01             	add    $0x1,%ecx
f0105992:	84 db                	test   %bl,%bl
f0105994:	75 f1                	jne    f0105987 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105996:	5b                   	pop    %ebx
f0105997:	5d                   	pop    %ebp
f0105998:	c3                   	ret    

f0105999 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105999:	55                   	push   %ebp
f010599a:	89 e5                	mov    %esp,%ebp
f010599c:	53                   	push   %ebx
f010599d:	83 ec 08             	sub    $0x8,%esp
f01059a0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01059a3:	89 1c 24             	mov    %ebx,(%esp)
f01059a6:	e8 75 ff ff ff       	call   f0105920 <strlen>
	strcpy(dst + len, src);
f01059ab:	8b 55 0c             	mov    0xc(%ebp),%edx
f01059ae:	89 54 24 04          	mov    %edx,0x4(%esp)
f01059b2:	01 d8                	add    %ebx,%eax
f01059b4:	89 04 24             	mov    %eax,(%esp)
f01059b7:	e8 bf ff ff ff       	call   f010597b <strcpy>
	return dst;
}
f01059bc:	89 d8                	mov    %ebx,%eax
f01059be:	83 c4 08             	add    $0x8,%esp
f01059c1:	5b                   	pop    %ebx
f01059c2:	5d                   	pop    %ebp
f01059c3:	c3                   	ret    

f01059c4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01059c4:	55                   	push   %ebp
f01059c5:	89 e5                	mov    %esp,%ebp
f01059c7:	56                   	push   %esi
f01059c8:	53                   	push   %ebx
f01059c9:	8b 75 08             	mov    0x8(%ebp),%esi
f01059cc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01059cf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01059d2:	85 db                	test   %ebx,%ebx
f01059d4:	74 16                	je     f01059ec <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f01059d6:	01 f3                	add    %esi,%ebx
f01059d8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f01059da:	0f b6 02             	movzbl (%edx),%eax
f01059dd:	88 01                	mov    %al,(%ecx)
f01059df:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01059e2:	80 3a 01             	cmpb   $0x1,(%edx)
f01059e5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01059e8:	39 d9                	cmp    %ebx,%ecx
f01059ea:	75 ee                	jne    f01059da <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01059ec:	89 f0                	mov    %esi,%eax
f01059ee:	5b                   	pop    %ebx
f01059ef:	5e                   	pop    %esi
f01059f0:	5d                   	pop    %ebp
f01059f1:	c3                   	ret    

f01059f2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01059f2:	55                   	push   %ebp
f01059f3:	89 e5                	mov    %esp,%ebp
f01059f5:	57                   	push   %edi
f01059f6:	56                   	push   %esi
f01059f7:	53                   	push   %ebx
f01059f8:	8b 7d 08             	mov    0x8(%ebp),%edi
f01059fb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01059fe:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105a01:	89 f8                	mov    %edi,%eax
f0105a03:	85 f6                	test   %esi,%esi
f0105a05:	74 33                	je     f0105a3a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f0105a07:	83 fe 01             	cmp    $0x1,%esi
f0105a0a:	74 25                	je     f0105a31 <strlcpy+0x3f>
f0105a0c:	0f b6 0b             	movzbl (%ebx),%ecx
f0105a0f:	84 c9                	test   %cl,%cl
f0105a11:	74 22                	je     f0105a35 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0105a13:	83 ee 02             	sub    $0x2,%esi
f0105a16:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105a1b:	88 08                	mov    %cl,(%eax)
f0105a1d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105a20:	39 f2                	cmp    %esi,%edx
f0105a22:	74 13                	je     f0105a37 <strlcpy+0x45>
f0105a24:	83 c2 01             	add    $0x1,%edx
f0105a27:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0105a2b:	84 c9                	test   %cl,%cl
f0105a2d:	75 ec                	jne    f0105a1b <strlcpy+0x29>
f0105a2f:	eb 06                	jmp    f0105a37 <strlcpy+0x45>
f0105a31:	89 f8                	mov    %edi,%eax
f0105a33:	eb 02                	jmp    f0105a37 <strlcpy+0x45>
f0105a35:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105a37:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105a3a:	29 f8                	sub    %edi,%eax
}
f0105a3c:	5b                   	pop    %ebx
f0105a3d:	5e                   	pop    %esi
f0105a3e:	5f                   	pop    %edi
f0105a3f:	5d                   	pop    %ebp
f0105a40:	c3                   	ret    

f0105a41 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105a41:	55                   	push   %ebp
f0105a42:	89 e5                	mov    %esp,%ebp
f0105a44:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105a47:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105a4a:	0f b6 01             	movzbl (%ecx),%eax
f0105a4d:	84 c0                	test   %al,%al
f0105a4f:	74 15                	je     f0105a66 <strcmp+0x25>
f0105a51:	3a 02                	cmp    (%edx),%al
f0105a53:	75 11                	jne    f0105a66 <strcmp+0x25>
		p++, q++;
f0105a55:	83 c1 01             	add    $0x1,%ecx
f0105a58:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105a5b:	0f b6 01             	movzbl (%ecx),%eax
f0105a5e:	84 c0                	test   %al,%al
f0105a60:	74 04                	je     f0105a66 <strcmp+0x25>
f0105a62:	3a 02                	cmp    (%edx),%al
f0105a64:	74 ef                	je     f0105a55 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105a66:	0f b6 c0             	movzbl %al,%eax
f0105a69:	0f b6 12             	movzbl (%edx),%edx
f0105a6c:	29 d0                	sub    %edx,%eax
}
f0105a6e:	5d                   	pop    %ebp
f0105a6f:	c3                   	ret    

f0105a70 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105a70:	55                   	push   %ebp
f0105a71:	89 e5                	mov    %esp,%ebp
f0105a73:	56                   	push   %esi
f0105a74:	53                   	push   %ebx
f0105a75:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0105a78:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a7b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0105a7e:	85 f6                	test   %esi,%esi
f0105a80:	74 29                	je     f0105aab <strncmp+0x3b>
f0105a82:	0f b6 03             	movzbl (%ebx),%eax
f0105a85:	84 c0                	test   %al,%al
f0105a87:	74 30                	je     f0105ab9 <strncmp+0x49>
f0105a89:	3a 02                	cmp    (%edx),%al
f0105a8b:	75 2c                	jne    f0105ab9 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0105a8d:	8d 43 01             	lea    0x1(%ebx),%eax
f0105a90:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0105a92:	89 c3                	mov    %eax,%ebx
f0105a94:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105a97:	39 f0                	cmp    %esi,%eax
f0105a99:	74 17                	je     f0105ab2 <strncmp+0x42>
f0105a9b:	0f b6 08             	movzbl (%eax),%ecx
f0105a9e:	84 c9                	test   %cl,%cl
f0105aa0:	74 17                	je     f0105ab9 <strncmp+0x49>
f0105aa2:	83 c0 01             	add    $0x1,%eax
f0105aa5:	3a 0a                	cmp    (%edx),%cl
f0105aa7:	74 e9                	je     f0105a92 <strncmp+0x22>
f0105aa9:	eb 0e                	jmp    f0105ab9 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105aab:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ab0:	eb 0f                	jmp    f0105ac1 <strncmp+0x51>
f0105ab2:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ab7:	eb 08                	jmp    f0105ac1 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105ab9:	0f b6 03             	movzbl (%ebx),%eax
f0105abc:	0f b6 12             	movzbl (%edx),%edx
f0105abf:	29 d0                	sub    %edx,%eax
}
f0105ac1:	5b                   	pop    %ebx
f0105ac2:	5e                   	pop    %esi
f0105ac3:	5d                   	pop    %ebp
f0105ac4:	c3                   	ret    

f0105ac5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105ac5:	55                   	push   %ebp
f0105ac6:	89 e5                	mov    %esp,%ebp
f0105ac8:	53                   	push   %ebx
f0105ac9:	8b 45 08             	mov    0x8(%ebp),%eax
f0105acc:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0105acf:	0f b6 18             	movzbl (%eax),%ebx
f0105ad2:	84 db                	test   %bl,%bl
f0105ad4:	74 1d                	je     f0105af3 <strchr+0x2e>
f0105ad6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0105ad8:	38 d3                	cmp    %dl,%bl
f0105ada:	75 06                	jne    f0105ae2 <strchr+0x1d>
f0105adc:	eb 1a                	jmp    f0105af8 <strchr+0x33>
f0105ade:	38 ca                	cmp    %cl,%dl
f0105ae0:	74 16                	je     f0105af8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105ae2:	83 c0 01             	add    $0x1,%eax
f0105ae5:	0f b6 10             	movzbl (%eax),%edx
f0105ae8:	84 d2                	test   %dl,%dl
f0105aea:	75 f2                	jne    f0105ade <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0105aec:	b8 00 00 00 00       	mov    $0x0,%eax
f0105af1:	eb 05                	jmp    f0105af8 <strchr+0x33>
f0105af3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105af8:	5b                   	pop    %ebx
f0105af9:	5d                   	pop    %ebp
f0105afa:	c3                   	ret    

f0105afb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105afb:	55                   	push   %ebp
f0105afc:	89 e5                	mov    %esp,%ebp
f0105afe:	53                   	push   %ebx
f0105aff:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b02:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0105b05:	0f b6 18             	movzbl (%eax),%ebx
f0105b08:	84 db                	test   %bl,%bl
f0105b0a:	74 16                	je     f0105b22 <strfind+0x27>
f0105b0c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0105b0e:	38 d3                	cmp    %dl,%bl
f0105b10:	75 06                	jne    f0105b18 <strfind+0x1d>
f0105b12:	eb 0e                	jmp    f0105b22 <strfind+0x27>
f0105b14:	38 ca                	cmp    %cl,%dl
f0105b16:	74 0a                	je     f0105b22 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0105b18:	83 c0 01             	add    $0x1,%eax
f0105b1b:	0f b6 10             	movzbl (%eax),%edx
f0105b1e:	84 d2                	test   %dl,%dl
f0105b20:	75 f2                	jne    f0105b14 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f0105b22:	5b                   	pop    %ebx
f0105b23:	5d                   	pop    %ebp
f0105b24:	c3                   	ret    

f0105b25 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105b25:	55                   	push   %ebp
f0105b26:	89 e5                	mov    %esp,%ebp
f0105b28:	83 ec 0c             	sub    $0xc,%esp
f0105b2b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0105b2e:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0105b31:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0105b34:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105b37:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105b3a:	85 c9                	test   %ecx,%ecx
f0105b3c:	74 36                	je     f0105b74 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105b3e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105b44:	75 28                	jne    f0105b6e <memset+0x49>
f0105b46:	f6 c1 03             	test   $0x3,%cl
f0105b49:	75 23                	jne    f0105b6e <memset+0x49>
		c &= 0xFF;
f0105b4b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105b4f:	89 d3                	mov    %edx,%ebx
f0105b51:	c1 e3 08             	shl    $0x8,%ebx
f0105b54:	89 d6                	mov    %edx,%esi
f0105b56:	c1 e6 18             	shl    $0x18,%esi
f0105b59:	89 d0                	mov    %edx,%eax
f0105b5b:	c1 e0 10             	shl    $0x10,%eax
f0105b5e:	09 f0                	or     %esi,%eax
f0105b60:	09 c2                	or     %eax,%edx
f0105b62:	89 d0                	mov    %edx,%eax
f0105b64:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105b66:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0105b69:	fc                   	cld    
f0105b6a:	f3 ab                	rep stos %eax,%es:(%edi)
f0105b6c:	eb 06                	jmp    f0105b74 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105b6e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105b71:	fc                   	cld    
f0105b72:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105b74:	89 f8                	mov    %edi,%eax
f0105b76:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0105b79:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0105b7c:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0105b7f:	89 ec                	mov    %ebp,%esp
f0105b81:	5d                   	pop    %ebp
f0105b82:	c3                   	ret    

f0105b83 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105b83:	55                   	push   %ebp
f0105b84:	89 e5                	mov    %esp,%ebp
f0105b86:	83 ec 08             	sub    $0x8,%esp
f0105b89:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0105b8c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0105b8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b92:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105b95:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105b98:	39 c6                	cmp    %eax,%esi
f0105b9a:	73 36                	jae    f0105bd2 <memmove+0x4f>
f0105b9c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105b9f:	39 d0                	cmp    %edx,%eax
f0105ba1:	73 2f                	jae    f0105bd2 <memmove+0x4f>
		s += n;
		d += n;
f0105ba3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105ba6:	f6 c2 03             	test   $0x3,%dl
f0105ba9:	75 1b                	jne    f0105bc6 <memmove+0x43>
f0105bab:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105bb1:	75 13                	jne    f0105bc6 <memmove+0x43>
f0105bb3:	f6 c1 03             	test   $0x3,%cl
f0105bb6:	75 0e                	jne    f0105bc6 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105bb8:	83 ef 04             	sub    $0x4,%edi
f0105bbb:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105bbe:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0105bc1:	fd                   	std    
f0105bc2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105bc4:	eb 09                	jmp    f0105bcf <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105bc6:	83 ef 01             	sub    $0x1,%edi
f0105bc9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105bcc:	fd                   	std    
f0105bcd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105bcf:	fc                   	cld    
f0105bd0:	eb 20                	jmp    f0105bf2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105bd2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105bd8:	75 13                	jne    f0105bed <memmove+0x6a>
f0105bda:	a8 03                	test   $0x3,%al
f0105bdc:	75 0f                	jne    f0105bed <memmove+0x6a>
f0105bde:	f6 c1 03             	test   $0x3,%cl
f0105be1:	75 0a                	jne    f0105bed <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105be3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0105be6:	89 c7                	mov    %eax,%edi
f0105be8:	fc                   	cld    
f0105be9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105beb:	eb 05                	jmp    f0105bf2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105bed:	89 c7                	mov    %eax,%edi
f0105bef:	fc                   	cld    
f0105bf0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105bf2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0105bf5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0105bf8:	89 ec                	mov    %ebp,%esp
f0105bfa:	5d                   	pop    %ebp
f0105bfb:	c3                   	ret    

f0105bfc <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0105bfc:	55                   	push   %ebp
f0105bfd:	89 e5                	mov    %esp,%ebp
f0105bff:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105c02:	8b 45 10             	mov    0x10(%ebp),%eax
f0105c05:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105c09:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105c0c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105c10:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c13:	89 04 24             	mov    %eax,(%esp)
f0105c16:	e8 68 ff ff ff       	call   f0105b83 <memmove>
}
f0105c1b:	c9                   	leave  
f0105c1c:	c3                   	ret    

f0105c1d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105c1d:	55                   	push   %ebp
f0105c1e:	89 e5                	mov    %esp,%ebp
f0105c20:	57                   	push   %edi
f0105c21:	56                   	push   %esi
f0105c22:	53                   	push   %ebx
f0105c23:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0105c26:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105c29:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105c2c:	8d 78 ff             	lea    -0x1(%eax),%edi
f0105c2f:	85 c0                	test   %eax,%eax
f0105c31:	74 36                	je     f0105c69 <memcmp+0x4c>
		if (*s1 != *s2)
f0105c33:	0f b6 03             	movzbl (%ebx),%eax
f0105c36:	0f b6 0e             	movzbl (%esi),%ecx
f0105c39:	38 c8                	cmp    %cl,%al
f0105c3b:	75 17                	jne    f0105c54 <memcmp+0x37>
f0105c3d:	ba 00 00 00 00       	mov    $0x0,%edx
f0105c42:	eb 1a                	jmp    f0105c5e <memcmp+0x41>
f0105c44:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0105c49:	83 c2 01             	add    $0x1,%edx
f0105c4c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0105c50:	38 c8                	cmp    %cl,%al
f0105c52:	74 0a                	je     f0105c5e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0105c54:	0f b6 c0             	movzbl %al,%eax
f0105c57:	0f b6 c9             	movzbl %cl,%ecx
f0105c5a:	29 c8                	sub    %ecx,%eax
f0105c5c:	eb 10                	jmp    f0105c6e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105c5e:	39 fa                	cmp    %edi,%edx
f0105c60:	75 e2                	jne    f0105c44 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105c62:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c67:	eb 05                	jmp    f0105c6e <memcmp+0x51>
f0105c69:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c6e:	5b                   	pop    %ebx
f0105c6f:	5e                   	pop    %esi
f0105c70:	5f                   	pop    %edi
f0105c71:	5d                   	pop    %ebp
f0105c72:	c3                   	ret    

f0105c73 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105c73:	55                   	push   %ebp
f0105c74:	89 e5                	mov    %esp,%ebp
f0105c76:	53                   	push   %ebx
f0105c77:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c7a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0105c7d:	89 c2                	mov    %eax,%edx
f0105c7f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105c82:	39 d0                	cmp    %edx,%eax
f0105c84:	73 13                	jae    f0105c99 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105c86:	89 d9                	mov    %ebx,%ecx
f0105c88:	38 18                	cmp    %bl,(%eax)
f0105c8a:	75 06                	jne    f0105c92 <memfind+0x1f>
f0105c8c:	eb 0b                	jmp    f0105c99 <memfind+0x26>
f0105c8e:	38 08                	cmp    %cl,(%eax)
f0105c90:	74 07                	je     f0105c99 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105c92:	83 c0 01             	add    $0x1,%eax
f0105c95:	39 d0                	cmp    %edx,%eax
f0105c97:	75 f5                	jne    f0105c8e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105c99:	5b                   	pop    %ebx
f0105c9a:	5d                   	pop    %ebp
f0105c9b:	c3                   	ret    

f0105c9c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105c9c:	55                   	push   %ebp
f0105c9d:	89 e5                	mov    %esp,%ebp
f0105c9f:	57                   	push   %edi
f0105ca0:	56                   	push   %esi
f0105ca1:	53                   	push   %ebx
f0105ca2:	83 ec 04             	sub    $0x4,%esp
f0105ca5:	8b 55 08             	mov    0x8(%ebp),%edx
f0105ca8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105cab:	0f b6 02             	movzbl (%edx),%eax
f0105cae:	3c 09                	cmp    $0x9,%al
f0105cb0:	74 04                	je     f0105cb6 <strtol+0x1a>
f0105cb2:	3c 20                	cmp    $0x20,%al
f0105cb4:	75 0e                	jne    f0105cc4 <strtol+0x28>
		s++;
f0105cb6:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105cb9:	0f b6 02             	movzbl (%edx),%eax
f0105cbc:	3c 09                	cmp    $0x9,%al
f0105cbe:	74 f6                	je     f0105cb6 <strtol+0x1a>
f0105cc0:	3c 20                	cmp    $0x20,%al
f0105cc2:	74 f2                	je     f0105cb6 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105cc4:	3c 2b                	cmp    $0x2b,%al
f0105cc6:	75 0a                	jne    f0105cd2 <strtol+0x36>
		s++;
f0105cc8:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105ccb:	bf 00 00 00 00       	mov    $0x0,%edi
f0105cd0:	eb 10                	jmp    f0105ce2 <strtol+0x46>
f0105cd2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105cd7:	3c 2d                	cmp    $0x2d,%al
f0105cd9:	75 07                	jne    f0105ce2 <strtol+0x46>
		s++, neg = 1;
f0105cdb:	83 c2 01             	add    $0x1,%edx
f0105cde:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105ce2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105ce8:	75 15                	jne    f0105cff <strtol+0x63>
f0105cea:	80 3a 30             	cmpb   $0x30,(%edx)
f0105ced:	75 10                	jne    f0105cff <strtol+0x63>
f0105cef:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105cf3:	75 0a                	jne    f0105cff <strtol+0x63>
		s += 2, base = 16;
f0105cf5:	83 c2 02             	add    $0x2,%edx
f0105cf8:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105cfd:	eb 10                	jmp    f0105d0f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0105cff:	85 db                	test   %ebx,%ebx
f0105d01:	75 0c                	jne    f0105d0f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105d03:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105d05:	80 3a 30             	cmpb   $0x30,(%edx)
f0105d08:	75 05                	jne    f0105d0f <strtol+0x73>
		s++, base = 8;
f0105d0a:	83 c2 01             	add    $0x1,%edx
f0105d0d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0105d0f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d14:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105d17:	0f b6 0a             	movzbl (%edx),%ecx
f0105d1a:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0105d1d:	89 f3                	mov    %esi,%ebx
f0105d1f:	80 fb 09             	cmp    $0x9,%bl
f0105d22:	77 08                	ja     f0105d2c <strtol+0x90>
			dig = *s - '0';
f0105d24:	0f be c9             	movsbl %cl,%ecx
f0105d27:	83 e9 30             	sub    $0x30,%ecx
f0105d2a:	eb 22                	jmp    f0105d4e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0105d2c:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0105d2f:	89 f3                	mov    %esi,%ebx
f0105d31:	80 fb 19             	cmp    $0x19,%bl
f0105d34:	77 08                	ja     f0105d3e <strtol+0xa2>
			dig = *s - 'a' + 10;
f0105d36:	0f be c9             	movsbl %cl,%ecx
f0105d39:	83 e9 57             	sub    $0x57,%ecx
f0105d3c:	eb 10                	jmp    f0105d4e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0105d3e:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0105d41:	89 f3                	mov    %esi,%ebx
f0105d43:	80 fb 19             	cmp    $0x19,%bl
f0105d46:	77 16                	ja     f0105d5e <strtol+0xc2>
			dig = *s - 'A' + 10;
f0105d48:	0f be c9             	movsbl %cl,%ecx
f0105d4b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105d4e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0105d51:	7d 0f                	jge    f0105d62 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0105d53:	83 c2 01             	add    $0x1,%edx
f0105d56:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0105d5a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0105d5c:	eb b9                	jmp    f0105d17 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0105d5e:	89 c1                	mov    %eax,%ecx
f0105d60:	eb 02                	jmp    f0105d64 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0105d62:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0105d64:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105d68:	74 05                	je     f0105d6f <strtol+0xd3>
		*endptr = (char *) s;
f0105d6a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105d6d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0105d6f:	89 ca                	mov    %ecx,%edx
f0105d71:	f7 da                	neg    %edx
f0105d73:	85 ff                	test   %edi,%edi
f0105d75:	0f 45 c2             	cmovne %edx,%eax
}
f0105d78:	83 c4 04             	add    $0x4,%esp
f0105d7b:	5b                   	pop    %ebx
f0105d7c:	5e                   	pop    %esi
f0105d7d:	5f                   	pop    %edi
f0105d7e:	5d                   	pop    %ebp
f0105d7f:	c3                   	ret    

f0105d80 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105d80:	fa                   	cli    

	xorw    %ax, %ax
f0105d81:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105d83:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d85:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d87:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105d89:	0f 01 16             	lgdtl  (%esi)
f0105d8c:	74 70                	je     f0105dfe <mpentry_end+0x4>
	movl    %cr0, %eax
f0105d8e:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105d91:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105d95:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105d98:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105d9e:	08 00                	or     %al,(%eax)

f0105da0 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105da0:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105da4:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105da6:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105da8:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105daa:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105dae:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105db0:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105db2:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl    %eax, %cr3
f0105db7:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105dba:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105dbd:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105dc2:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in mem_init()
	movl    mpentry_kstack, %esp
f0105dc5:	8b 25 84 7e 22 f0    	mov    0xf0227e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105dcb:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105dd0:	b8 a8 00 10 f0       	mov    $0xf01000a8,%eax
	call    *%eax
f0105dd5:	ff d0                	call   *%eax

f0105dd7 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105dd7:	eb fe                	jmp    f0105dd7 <spin>
f0105dd9:	8d 76 00             	lea    0x0(%esi),%esi

f0105ddc <gdt>:
	...
f0105de4:	ff                   	(bad)  
f0105de5:	ff 00                	incl   (%eax)
f0105de7:	00 00                	add    %al,(%eax)
f0105de9:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105df0:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0105df4 <gdtdesc>:
f0105df4:	17                   	pop    %ss
f0105df5:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105dfa <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105dfa:	90                   	nop
f0105dfb:	66 90                	xchg   %ax,%ax
f0105dfd:	66 90                	xchg   %ax,%ax
f0105dff:	90                   	nop

f0105e00 <sum>:
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105e00:	85 d2                	test   %edx,%edx
f0105e02:	7e 1c                	jle    f0105e20 <sum+0x20>
#define MPIOINTR  0x03  // One per bus interrupt source
#define MPLINTR   0x04  // One per system interrupt source

static uint8_t
sum(void *addr, int len)
{
f0105e04:	55                   	push   %ebp
f0105e05:	89 e5                	mov    %esp,%ebp
f0105e07:	53                   	push   %ebx
f0105e08:	89 c1                	mov    %eax,%ecx
#define MPIOAPIC  0x02  // One per I/O APIC
#define MPIOINTR  0x03  // One per bus interrupt source
#define MPLINTR   0x04  // One per system interrupt source

static uint8_t
sum(void *addr, int len)
f0105e0a:	8d 1c 10             	lea    (%eax,%edx,1),%ebx
{
	int i, sum;

	sum = 0;
f0105e0d:	b8 00 00 00 00       	mov    $0x0,%eax
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105e12:	0f b6 11             	movzbl (%ecx),%edx
f0105e15:	01 d0                	add    %edx,%eax
f0105e17:	83 c1 01             	add    $0x1,%ecx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105e1a:	39 d9                	cmp    %ebx,%ecx
f0105e1c:	75 f4                	jne    f0105e12 <sum+0x12>
f0105e1e:	eb 06                	jmp    f0105e26 <sum+0x26>
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105e20:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e25:	c3                   	ret    
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
	return sum;
}
f0105e26:	5b                   	pop    %ebx
f0105e27:	5d                   	pop    %ebp
f0105e28:	c3                   	ret    

f0105e29 <mpsearch1>:

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105e29:	55                   	push   %ebp
f0105e2a:	89 e5                	mov    %esp,%ebp
f0105e2c:	56                   	push   %esi
f0105e2d:	53                   	push   %ebx
f0105e2e:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105e31:	8b 0d 88 7e 22 f0    	mov    0xf0227e88,%ecx
f0105e37:	89 c3                	mov    %eax,%ebx
f0105e39:	c1 eb 0c             	shr    $0xc,%ebx
f0105e3c:	39 cb                	cmp    %ecx,%ebx
f0105e3e:	72 20                	jb     f0105e60 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105e40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105e44:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0105e4b:	f0 
f0105e4c:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105e53:	00 
f0105e54:	c7 04 24 21 82 10 f0 	movl   $0xf0108221,(%esp)
f0105e5b:	e8 e0 a1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105e60:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105e66:	8d 34 02             	lea    (%edx,%eax,1),%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105e69:	89 f0                	mov    %esi,%eax
f0105e6b:	c1 e8 0c             	shr    $0xc,%eax
f0105e6e:	39 c1                	cmp    %eax,%ecx
f0105e70:	77 20                	ja     f0105e92 <mpsearch1+0x69>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105e72:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105e76:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0105e7d:	f0 
f0105e7e:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105e85:	00 
f0105e86:	c7 04 24 21 82 10 f0 	movl   $0xf0108221,(%esp)
f0105e8d:	e8 ae a1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105e92:	81 ee 00 00 00 10    	sub    $0x10000000,%esi

	for (; mp < end; mp++)
f0105e98:	39 f3                	cmp    %esi,%ebx
f0105e9a:	73 3a                	jae    f0105ed6 <mpsearch1+0xad>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e9c:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105ea3:	00 
f0105ea4:	c7 44 24 04 31 82 10 	movl   $0xf0108231,0x4(%esp)
f0105eab:	f0 
f0105eac:	89 1c 24             	mov    %ebx,(%esp)
f0105eaf:	e8 69 fd ff ff       	call   f0105c1d <memcmp>
f0105eb4:	85 c0                	test   %eax,%eax
f0105eb6:	75 10                	jne    f0105ec8 <mpsearch1+0x9f>
		    sum(mp, sizeof(*mp)) == 0)
f0105eb8:	ba 10 00 00 00       	mov    $0x10,%edx
f0105ebd:	89 d8                	mov    %ebx,%eax
f0105ebf:	e8 3c ff ff ff       	call   f0105e00 <sum>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105ec4:	84 c0                	test   %al,%al
f0105ec6:	74 13                	je     f0105edb <mpsearch1+0xb2>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105ec8:	83 c3 10             	add    $0x10,%ebx
f0105ecb:	39 f3                	cmp    %esi,%ebx
f0105ecd:	72 cd                	jb     f0105e9c <mpsearch1+0x73>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105ecf:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105ed4:	eb 05                	jmp    f0105edb <mpsearch1+0xb2>
f0105ed6:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0105edb:	89 d8                	mov    %ebx,%eax
f0105edd:	83 c4 10             	add    $0x10,%esp
f0105ee0:	5b                   	pop    %ebx
f0105ee1:	5e                   	pop    %esi
f0105ee2:	5d                   	pop    %ebp
f0105ee3:	c3                   	ret    

f0105ee4 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105ee4:	55                   	push   %ebp
f0105ee5:	89 e5                	mov    %esp,%ebp
f0105ee7:	57                   	push   %edi
f0105ee8:	56                   	push   %esi
f0105ee9:	53                   	push   %ebx
f0105eea:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105eed:	c7 05 c0 83 22 f0 20 	movl   $0xf0228020,0xf02283c0
f0105ef4:	80 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105ef7:	83 3d 88 7e 22 f0 00 	cmpl   $0x0,0xf0227e88
f0105efe:	75 24                	jne    f0105f24 <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105f00:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f0105f07:	00 
f0105f08:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0105f0f:	f0 
f0105f10:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0105f17:	00 
f0105f18:	c7 04 24 21 82 10 f0 	movl   $0xf0108221,(%esp)
f0105f1f:	e8 1c a1 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105f24:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105f2b:	85 c0                	test   %eax,%eax
f0105f2d:	74 16                	je     f0105f45 <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0105f2f:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105f32:	ba 00 04 00 00       	mov    $0x400,%edx
f0105f37:	e8 ed fe ff ff       	call   f0105e29 <mpsearch1>
f0105f3c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105f3f:	85 c0                	test   %eax,%eax
f0105f41:	75 3c                	jne    f0105f7f <mp_init+0x9b>
f0105f43:	eb 20                	jmp    f0105f65 <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105f45:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105f4c:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105f4f:	2d 00 04 00 00       	sub    $0x400,%eax
f0105f54:	ba 00 04 00 00       	mov    $0x400,%edx
f0105f59:	e8 cb fe ff ff       	call   f0105e29 <mpsearch1>
f0105f5e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105f61:	85 c0                	test   %eax,%eax
f0105f63:	75 1a                	jne    f0105f7f <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105f65:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105f6a:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105f6f:	e8 b5 fe ff ff       	call   f0105e29 <mpsearch1>
f0105f74:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105f77:	85 c0                	test   %eax,%eax
f0105f79:	0f 84 2a 02 00 00    	je     f01061a9 <mp_init+0x2c5>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105f7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105f82:	8b 78 04             	mov    0x4(%eax),%edi
f0105f85:	85 ff                	test   %edi,%edi
f0105f87:	74 06                	je     f0105f8f <mp_init+0xab>
f0105f89:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105f8d:	74 11                	je     f0105fa0 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0105f8f:	c7 04 24 94 80 10 f0 	movl   $0xf0108094,(%esp)
f0105f96:	e8 23 de ff ff       	call   f0103dbe <cprintf>
f0105f9b:	e9 09 02 00 00       	jmp    f01061a9 <mp_init+0x2c5>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105fa0:	89 f8                	mov    %edi,%eax
f0105fa2:	c1 e8 0c             	shr    $0xc,%eax
f0105fa5:	3b 05 88 7e 22 f0    	cmp    0xf0227e88,%eax
f0105fab:	72 20                	jb     f0105fcd <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105fad:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105fb1:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0105fb8:	f0 
f0105fb9:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0105fc0:	00 
f0105fc1:	c7 04 24 21 82 10 f0 	movl   $0xf0108221,(%esp)
f0105fc8:	e8 73 a0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105fcd:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105fd3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105fda:	00 
f0105fdb:	c7 44 24 04 36 82 10 	movl   $0xf0108236,0x4(%esp)
f0105fe2:	f0 
f0105fe3:	89 3c 24             	mov    %edi,(%esp)
f0105fe6:	e8 32 fc ff ff       	call   f0105c1d <memcmp>
f0105feb:	85 c0                	test   %eax,%eax
f0105fed:	74 11                	je     f0106000 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105fef:	c7 04 24 c4 80 10 f0 	movl   $0xf01080c4,(%esp)
f0105ff6:	e8 c3 dd ff ff       	call   f0103dbe <cprintf>
f0105ffb:	e9 a9 01 00 00       	jmp    f01061a9 <mp_init+0x2c5>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0106000:	0f b7 5f 04          	movzwl 0x4(%edi),%ebx
f0106004:	0f b7 d3             	movzwl %bx,%edx
f0106007:	89 f8                	mov    %edi,%eax
f0106009:	e8 f2 fd ff ff       	call   f0105e00 <sum>
f010600e:	84 c0                	test   %al,%al
f0106010:	74 11                	je     f0106023 <mp_init+0x13f>
		cprintf("SMP: Bad MP configuration checksum\n");
f0106012:	c7 04 24 f8 80 10 f0 	movl   $0xf01080f8,(%esp)
f0106019:	e8 a0 dd ff ff       	call   f0103dbe <cprintf>
f010601e:	e9 86 01 00 00       	jmp    f01061a9 <mp_init+0x2c5>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0106023:	0f b6 47 06          	movzbl 0x6(%edi),%eax
f0106027:	3c 04                	cmp    $0x4,%al
f0106029:	74 1f                	je     f010604a <mp_init+0x166>
f010602b:	3c 01                	cmp    $0x1,%al
f010602d:	8d 76 00             	lea    0x0(%esi),%esi
f0106030:	74 18                	je     f010604a <mp_init+0x166>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0106032:	0f b6 c0             	movzbl %al,%eax
f0106035:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106039:	c7 04 24 1c 81 10 f0 	movl   $0xf010811c,(%esp)
f0106040:	e8 79 dd ff ff       	call   f0103dbe <cprintf>
f0106045:	e9 5f 01 00 00       	jmp    f01061a9 <mp_init+0x2c5>
		return NULL;
	}
	if (sum((uint8_t *)conf + conf->length, conf->xlength) != conf->xchecksum) {
f010604a:	0f b7 57 28          	movzwl 0x28(%edi),%edx
f010604e:	0f b7 db             	movzwl %bx,%ebx
f0106051:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0106054:	e8 a7 fd ff ff       	call   f0105e00 <sum>
f0106059:	3a 47 2a             	cmp    0x2a(%edi),%al
f010605c:	74 11                	je     f010606f <mp_init+0x18b>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010605e:	c7 04 24 3c 81 10 f0 	movl   $0xf010813c,(%esp)
f0106065:	e8 54 dd ff ff       	call   f0103dbe <cprintf>
f010606a:	e9 3a 01 00 00       	jmp    f01061a9 <mp_init+0x2c5>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010606f:	85 ff                	test   %edi,%edi
f0106071:	0f 84 32 01 00 00    	je     f01061a9 <mp_init+0x2c5>
		return;
	ismp = 1;
f0106077:	c7 05 00 80 22 f0 01 	movl   $0x1,0xf0228000
f010607e:	00 00 00 
	lapic = (uint32_t *)conf->lapicaddr;
f0106081:	8b 47 24             	mov    0x24(%edi),%eax
f0106084:	a3 00 90 26 f0       	mov    %eax,0xf0269000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0106089:	8d 77 2c             	lea    0x2c(%edi),%esi
f010608c:	66 83 7f 22 00       	cmpw   $0x0,0x22(%edi)
f0106091:	0f 84 97 00 00 00    	je     f010612e <mp_init+0x24a>
f0106097:	bb 00 00 00 00       	mov    $0x0,%ebx
		switch (*p) {
f010609c:	0f b6 06             	movzbl (%esi),%eax
f010609f:	84 c0                	test   %al,%al
f01060a1:	74 06                	je     f01060a9 <mp_init+0x1c5>
f01060a3:	3c 04                	cmp    $0x4,%al
f01060a5:	77 57                	ja     f01060fe <mp_init+0x21a>
f01060a7:	eb 50                	jmp    f01060f9 <mp_init+0x215>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01060a9:	f6 46 03 02          	testb  $0x2,0x3(%esi)
f01060ad:	8d 76 00             	lea    0x0(%esi),%esi
f01060b0:	74 11                	je     f01060c3 <mp_init+0x1df>
				bootcpu = &cpus[ncpu];
f01060b2:	6b 05 c4 83 22 f0 74 	imul   $0x74,0xf02283c4,%eax
f01060b9:	05 20 80 22 f0       	add    $0xf0228020,%eax
f01060be:	a3 c0 83 22 f0       	mov    %eax,0xf02283c0
			if (ncpu < NCPU) {
f01060c3:	a1 c4 83 22 f0       	mov    0xf02283c4,%eax
f01060c8:	83 f8 07             	cmp    $0x7,%eax
f01060cb:	7f 13                	jg     f01060e0 <mp_init+0x1fc>
				cpus[ncpu].cpu_id = ncpu;
f01060cd:	6b d0 74             	imul   $0x74,%eax,%edx
f01060d0:	88 82 20 80 22 f0    	mov    %al,-0xfdd7fe0(%edx)
				ncpu++;
f01060d6:	83 c0 01             	add    $0x1,%eax
f01060d9:	a3 c4 83 22 f0       	mov    %eax,0xf02283c4
f01060de:	eb 14                	jmp    f01060f4 <mp_init+0x210>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01060e0:	0f b6 46 01          	movzbl 0x1(%esi),%eax
f01060e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01060e8:	c7 04 24 6c 81 10 f0 	movl   $0xf010816c,(%esp)
f01060ef:	e8 ca dc ff ff       	call   f0103dbe <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01060f4:	83 c6 14             	add    $0x14,%esi
			continue;
f01060f7:	eb 26                	jmp    f010611f <mp_init+0x23b>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01060f9:	83 c6 08             	add    $0x8,%esi
			continue;
f01060fc:	eb 21                	jmp    f010611f <mp_init+0x23b>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01060fe:	0f b6 c0             	movzbl %al,%eax
f0106101:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106105:	c7 04 24 94 81 10 f0 	movl   $0xf0108194,(%esp)
f010610c:	e8 ad dc ff ff       	call   f0103dbe <cprintf>
			ismp = 0;
f0106111:	c7 05 00 80 22 f0 00 	movl   $0x0,0xf0228000
f0106118:	00 00 00 
			i = conf->entry;
f010611b:	0f b7 5f 22          	movzwl 0x22(%edi),%ebx
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapic = (uint32_t *)conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010611f:	83 c3 01             	add    $0x1,%ebx
f0106122:	0f b7 47 22          	movzwl 0x22(%edi),%eax
f0106126:	39 d8                	cmp    %ebx,%eax
f0106128:	0f 87 6e ff ff ff    	ja     f010609c <mp_init+0x1b8>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010612e:	a1 c0 83 22 f0       	mov    0xf02283c0,%eax
f0106133:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010613a:	83 3d 00 80 22 f0 00 	cmpl   $0x0,0xf0228000
f0106141:	75 22                	jne    f0106165 <mp_init+0x281>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0106143:	c7 05 c4 83 22 f0 01 	movl   $0x1,0xf02283c4
f010614a:	00 00 00 
		lapic = NULL;
f010614d:	c7 05 00 90 26 f0 00 	movl   $0x0,0xf0269000
f0106154:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0106157:	c7 04 24 b4 81 10 f0 	movl   $0xf01081b4,(%esp)
f010615e:	e8 5b dc ff ff       	call   f0103dbe <cprintf>
f0106163:	eb 44                	jmp    f01061a9 <mp_init+0x2c5>
		return;
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0106165:	8b 15 c4 83 22 f0    	mov    0xf02283c4,%edx
f010616b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010616f:	0f b6 00             	movzbl (%eax),%eax
f0106172:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106176:	c7 04 24 3b 82 10 f0 	movl   $0xf010823b,(%esp)
f010617d:	e8 3c dc ff ff       	call   f0103dbe <cprintf>

	if (mp->imcrp) {
f0106182:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106185:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0106189:	74 1e                	je     f01061a9 <mp_init+0x2c5>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f010618b:	c7 04 24 e0 81 10 f0 	movl   $0xf01081e0,(%esp)
f0106192:	e8 27 dc ff ff       	call   f0103dbe <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106197:	ba 22 00 00 00       	mov    $0x22,%edx
f010619c:	b8 70 00 00 00       	mov    $0x70,%eax
f01061a1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01061a2:	b2 23                	mov    $0x23,%dl
f01061a4:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f01061a5:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01061a8:	ee                   	out    %al,(%dx)
	}
}
f01061a9:	83 c4 2c             	add    $0x2c,%esp
f01061ac:	5b                   	pop    %ebx
f01061ad:	5e                   	pop    %esi
f01061ae:	5f                   	pop    %edi
f01061af:	5d                   	pop    %ebp
f01061b0:	c3                   	ret    
f01061b1:	66 90                	xchg   %ax,%ax
f01061b3:	90                   	nop

f01061b4 <lapicw>:

volatile uint32_t *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
f01061b4:	55                   	push   %ebp
f01061b5:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01061b7:	8b 0d 00 90 26 f0    	mov    0xf0269000,%ecx
f01061bd:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01061c0:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01061c2:	a1 00 90 26 f0       	mov    0xf0269000,%eax
f01061c7:	8b 40 20             	mov    0x20(%eax),%eax
}
f01061ca:	5d                   	pop    %ebp
f01061cb:	c3                   	ret    

f01061cc <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01061cc:	55                   	push   %ebp
f01061cd:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01061cf:	a1 00 90 26 f0       	mov    0xf0269000,%eax
f01061d4:	85 c0                	test   %eax,%eax
f01061d6:	74 08                	je     f01061e0 <cpunum+0x14>
		return lapic[ID] >> 24;
f01061d8:	8b 40 20             	mov    0x20(%eax),%eax
f01061db:	c1 e8 18             	shr    $0x18,%eax
f01061de:	eb 05                	jmp    f01061e5 <cpunum+0x19>
	return 0;
f01061e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01061e5:	5d                   	pop    %ebp
f01061e6:	c3                   	ret    

f01061e7 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapic) 
f01061e7:	83 3d 00 90 26 f0 00 	cmpl   $0x0,0xf0269000
f01061ee:	0f 84 0b 01 00 00    	je     f01062ff <lapic_init+0x118>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f01061f4:	55                   	push   %ebp
f01061f5:	89 e5                	mov    %esp,%ebp
	if (!lapic) 
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f01061f7:	ba 27 01 00 00       	mov    $0x127,%edx
f01061fc:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106201:	e8 ae ff ff ff       	call   f01061b4 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0106206:	ba 0b 00 00 00       	mov    $0xb,%edx
f010620b:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0106210:	e8 9f ff ff ff       	call   f01061b4 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0106215:	ba 20 00 02 00       	mov    $0x20020,%edx
f010621a:	b8 c8 00 00 00       	mov    $0xc8,%eax
f010621f:	e8 90 ff ff ff       	call   f01061b4 <lapicw>
	lapicw(TICR, 10000000); 
f0106224:	ba 80 96 98 00       	mov    $0x989680,%edx
f0106229:	b8 e0 00 00 00       	mov    $0xe0,%eax
f010622e:	e8 81 ff ff ff       	call   f01061b4 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0106233:	e8 94 ff ff ff       	call   f01061cc <cpunum>
f0106238:	6b c0 74             	imul   $0x74,%eax,%eax
f010623b:	05 20 80 22 f0       	add    $0xf0228020,%eax
f0106240:	39 05 c0 83 22 f0    	cmp    %eax,0xf02283c0
f0106246:	74 0f                	je     f0106257 <lapic_init+0x70>
		lapicw(LINT0, MASKED);
f0106248:	ba 00 00 01 00       	mov    $0x10000,%edx
f010624d:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0106252:	e8 5d ff ff ff       	call   f01061b4 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0106257:	ba 00 00 01 00       	mov    $0x10000,%edx
f010625c:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0106261:	e8 4e ff ff ff       	call   f01061b4 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0106266:	a1 00 90 26 f0       	mov    0xf0269000,%eax
f010626b:	8b 40 30             	mov    0x30(%eax),%eax
f010626e:	c1 e8 10             	shr    $0x10,%eax
f0106271:	3c 03                	cmp    $0x3,%al
f0106273:	76 0f                	jbe    f0106284 <lapic_init+0x9d>
		lapicw(PCINT, MASKED);
f0106275:	ba 00 00 01 00       	mov    $0x10000,%edx
f010627a:	b8 d0 00 00 00       	mov    $0xd0,%eax
f010627f:	e8 30 ff ff ff       	call   f01061b4 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0106284:	ba 33 00 00 00       	mov    $0x33,%edx
f0106289:	b8 dc 00 00 00       	mov    $0xdc,%eax
f010628e:	e8 21 ff ff ff       	call   f01061b4 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0106293:	ba 00 00 00 00       	mov    $0x0,%edx
f0106298:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010629d:	e8 12 ff ff ff       	call   f01061b4 <lapicw>
	lapicw(ESR, 0);
f01062a2:	ba 00 00 00 00       	mov    $0x0,%edx
f01062a7:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01062ac:	e8 03 ff ff ff       	call   f01061b4 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01062b1:	ba 00 00 00 00       	mov    $0x0,%edx
f01062b6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01062bb:	e8 f4 fe ff ff       	call   f01061b4 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01062c0:	ba 00 00 00 00       	mov    $0x0,%edx
f01062c5:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01062ca:	e8 e5 fe ff ff       	call   f01061b4 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01062cf:	ba 00 85 08 00       	mov    $0x88500,%edx
f01062d4:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01062d9:	e8 d6 fe ff ff       	call   f01061b4 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f01062de:	8b 15 00 90 26 f0    	mov    0xf0269000,%edx
f01062e4:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01062ea:	f6 c4 10             	test   $0x10,%ah
f01062ed:	75 f5                	jne    f01062e4 <lapic_init+0xfd>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f01062ef:	ba 00 00 00 00       	mov    $0x0,%edx
f01062f4:	b8 20 00 00 00       	mov    $0x20,%eax
f01062f9:	e8 b6 fe ff ff       	call   f01061b4 <lapicw>
}
f01062fe:	5d                   	pop    %ebp
f01062ff:	f3 c3                	repz ret 

f0106301 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0106301:	83 3d 00 90 26 f0 00 	cmpl   $0x0,0xf0269000
f0106308:	74 13                	je     f010631d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010630a:	55                   	push   %ebp
f010630b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f010630d:	ba 00 00 00 00       	mov    $0x0,%edx
f0106312:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106317:	e8 98 fe ff ff       	call   f01061b4 <lapicw>
}
f010631c:	5d                   	pop    %ebp
f010631d:	f3 c3                	repz ret 

f010631f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f010631f:	55                   	push   %ebp
f0106320:	89 e5                	mov    %esp,%ebp
f0106322:	56                   	push   %esi
f0106323:	53                   	push   %ebx
f0106324:	83 ec 10             	sub    $0x10,%esp
f0106327:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010632a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010632d:	ba 70 00 00 00       	mov    $0x70,%edx
f0106332:	b8 0f 00 00 00       	mov    $0xf,%eax
f0106337:	ee                   	out    %al,(%dx)
f0106338:	b2 71                	mov    $0x71,%dl
f010633a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010633f:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106340:	83 3d 88 7e 22 f0 00 	cmpl   $0x0,0xf0227e88
f0106347:	75 24                	jne    f010636d <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106349:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f0106350:	00 
f0106351:	c7 44 24 08 88 69 10 	movl   $0xf0106988,0x8(%esp)
f0106358:	f0 
f0106359:	c7 44 24 04 93 00 00 	movl   $0x93,0x4(%esp)
f0106360:	00 
f0106361:	c7 04 24 58 82 10 f0 	movl   $0xf0108258,(%esp)
f0106368:	e8 d3 9c ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f010636d:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0106374:	00 00 
	wrv[1] = addr >> 4;
f0106376:	89 f0                	mov    %esi,%eax
f0106378:	c1 e8 04             	shr    $0x4,%eax
f010637b:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0106381:	c1 e3 18             	shl    $0x18,%ebx
f0106384:	89 da                	mov    %ebx,%edx
f0106386:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010638b:	e8 24 fe ff ff       	call   f01061b4 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0106390:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0106395:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010639a:	e8 15 fe ff ff       	call   f01061b4 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f010639f:	ba 00 85 00 00       	mov    $0x8500,%edx
f01063a4:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01063a9:	e8 06 fe ff ff       	call   f01061b4 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01063ae:	c1 ee 0c             	shr    $0xc,%esi
f01063b1:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01063b7:	89 da                	mov    %ebx,%edx
f01063b9:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01063be:	e8 f1 fd ff ff       	call   f01061b4 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01063c3:	89 f2                	mov    %esi,%edx
f01063c5:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01063ca:	e8 e5 fd ff ff       	call   f01061b4 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01063cf:	89 da                	mov    %ebx,%edx
f01063d1:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01063d6:	e8 d9 fd ff ff       	call   f01061b4 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01063db:	89 f2                	mov    %esi,%edx
f01063dd:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01063e2:	e8 cd fd ff ff       	call   f01061b4 <lapicw>
		microdelay(200);
	}
}
f01063e7:	83 c4 10             	add    $0x10,%esp
f01063ea:	5b                   	pop    %ebx
f01063eb:	5e                   	pop    %esi
f01063ec:	5d                   	pop    %ebp
f01063ed:	c3                   	ret    

f01063ee <lapic_ipi>:

void
lapic_ipi(int vector)
{
f01063ee:	55                   	push   %ebp
f01063ef:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f01063f1:	8b 55 08             	mov    0x8(%ebp),%edx
f01063f4:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f01063fa:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01063ff:	e8 b0 fd ff ff       	call   f01061b4 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106404:	8b 15 00 90 26 f0    	mov    0xf0269000,%edx
f010640a:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106410:	f6 c4 10             	test   $0x10,%ah
f0106413:	75 f5                	jne    f010640a <lapic_ipi+0x1c>
		;
}
f0106415:	5d                   	pop    %ebp
f0106416:	c3                   	ret    
f0106417:	90                   	nop

f0106418 <holding>:

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0106418:	83 38 00             	cmpl   $0x0,(%eax)
f010641b:	74 21                	je     f010643e <holding+0x26>
}

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
f010641d:	55                   	push   %ebp
f010641e:	89 e5                	mov    %esp,%ebp
f0106420:	53                   	push   %ebx
f0106421:	83 ec 04             	sub    $0x4,%esp
	return lock->locked && lock->cpu == thiscpu;
f0106424:	8b 58 08             	mov    0x8(%eax),%ebx
f0106427:	e8 a0 fd ff ff       	call   f01061cc <cpunum>
f010642c:	6b c0 74             	imul   $0x74,%eax,%eax
f010642f:	05 20 80 22 f0       	add    $0xf0228020,%eax
f0106434:	39 c3                	cmp    %eax,%ebx
f0106436:	0f 94 c0             	sete   %al
f0106439:	0f b6 c0             	movzbl %al,%eax
f010643c:	eb 06                	jmp    f0106444 <holding+0x2c>
f010643e:	b8 00 00 00 00       	mov    $0x0,%eax
f0106443:	c3                   	ret    
}
f0106444:	83 c4 04             	add    $0x4,%esp
f0106447:	5b                   	pop    %ebx
f0106448:	5d                   	pop    %ebp
f0106449:	c3                   	ret    

f010644a <__spin_initlock>:
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010644a:	55                   	push   %ebp
f010644b:	89 e5                	mov    %esp,%ebp
f010644d:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0106450:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0106456:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106459:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010645c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0106463:	5d                   	pop    %ebp
f0106464:	c3                   	ret    

f0106465 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0106465:	55                   	push   %ebp
f0106466:	89 e5                	mov    %esp,%ebp
f0106468:	53                   	push   %ebx
f0106469:	83 ec 24             	sub    $0x24,%esp
f010646c:	8b 5d 08             	mov    0x8(%ebp),%ebx
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f010646f:	89 d8                	mov    %ebx,%eax
f0106471:	e8 a2 ff ff ff       	call   f0106418 <holding>
f0106476:	85 c0                	test   %eax,%eax
f0106478:	75 12                	jne    f010648c <spin_lock+0x27>
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f010647a:	89 da                	mov    %ebx,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010647c:	b0 01                	mov    $0x1,%al
f010647e:	f0 87 03             	lock xchg %eax,(%ebx)
f0106481:	b9 01 00 00 00       	mov    $0x1,%ecx
f0106486:	85 c0                	test   %eax,%eax
f0106488:	75 2e                	jne    f01064b8 <spin_lock+0x53>
f010648a:	eb 37                	jmp    f01064c3 <spin_lock+0x5e>
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f010648c:	8b 5b 04             	mov    0x4(%ebx),%ebx
f010648f:	e8 38 fd ff ff       	call   f01061cc <cpunum>
f0106494:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0106498:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010649c:	c7 44 24 08 68 82 10 	movl   $0xf0108268,0x8(%esp)
f01064a3:	f0 
f01064a4:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
f01064ab:	00 
f01064ac:	c7 04 24 cc 82 10 f0 	movl   $0xf01082cc,(%esp)
f01064b3:	e8 88 9b ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01064b8:	f3 90                	pause  
f01064ba:	89 c8                	mov    %ecx,%eax
f01064bc:	f0 87 02             	lock xchg %eax,(%edx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01064bf:	85 c0                	test   %eax,%eax
f01064c1:	75 f5                	jne    f01064b8 <spin_lock+0x53>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01064c3:	e8 04 fd ff ff       	call   f01061cc <cpunum>
f01064c8:	6b c0 74             	imul   $0x74,%eax,%eax
f01064cb:	05 20 80 22 f0       	add    $0xf0228020,%eax
f01064d0:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01064d3:	8d 4b 0c             	lea    0xc(%ebx),%ecx

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01064d6:	89 e8                	mov    %ebp,%eax
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
		if (ebp == 0 || ebp < (uint32_t *)ULIM
		    || ebp >= (uint32_t *)IOMEMBASE)
f01064d8:	8d 90 00 00 80 10    	lea    0x10800000(%eax),%edx
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
		if (ebp == 0 || ebp < (uint32_t *)ULIM
f01064de:	81 fa ff ff 7f 0e    	cmp    $0xe7fffff,%edx
f01064e4:	76 3a                	jbe    f0106520 <spin_lock+0xbb>
f01064e6:	eb 31                	jmp    f0106519 <spin_lock+0xb4>
		    || ebp >= (uint32_t *)IOMEMBASE)
f01064e8:	8d 9a 00 00 80 10    	lea    0x10800000(%edx),%ebx
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
		if (ebp == 0 || ebp < (uint32_t *)ULIM
f01064ee:	81 fb ff ff 7f 0e    	cmp    $0xe7fffff,%ebx
f01064f4:	77 12                	ja     f0106508 <spin_lock+0xa3>
		    || ebp >= (uint32_t *)IOMEMBASE)
			break;
		pcs[i] = ebp[1];          // saved %eip
f01064f6:	8b 5a 04             	mov    0x4(%edx),%ebx
f01064f9:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01064fc:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01064fe:	83 c0 01             	add    $0x1,%eax
f0106501:	83 f8 0a             	cmp    $0xa,%eax
f0106504:	75 e2                	jne    f01064e8 <spin_lock+0x83>
f0106506:	eb 27                	jmp    f010652f <spin_lock+0xca>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0106508:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
		    || ebp >= (uint32_t *)IOMEMBASE)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f010650f:	83 c0 01             	add    $0x1,%eax
f0106512:	83 f8 09             	cmp    $0x9,%eax
f0106515:	7e f1                	jle    f0106508 <spin_lock+0xa3>
f0106517:	eb 16                	jmp    f010652f <spin_lock+0xca>
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0106519:	b8 00 00 00 00       	mov    $0x0,%eax
f010651e:	eb e8                	jmp    f0106508 <spin_lock+0xa3>
		if (ebp == 0 || ebp < (uint32_t *)ULIM
		    || ebp >= (uint32_t *)IOMEMBASE)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0106520:	8b 50 04             	mov    0x4(%eax),%edx
f0106523:	89 53 0c             	mov    %edx,0xc(%ebx)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106526:	8b 10                	mov    (%eax),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0106528:	b8 01 00 00 00       	mov    $0x1,%eax
f010652d:	eb b9                	jmp    f01064e8 <spin_lock+0x83>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010652f:	83 c4 24             	add    $0x24,%esp
f0106532:	5b                   	pop    %ebx
f0106533:	5d                   	pop    %ebp
f0106534:	c3                   	ret    

f0106535 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106535:	55                   	push   %ebp
f0106536:	89 e5                	mov    %esp,%ebp
f0106538:	83 ec 78             	sub    $0x78,%esp
f010653b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010653e:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0106541:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0106544:	8b 5d 08             	mov    0x8(%ebp),%ebx
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0106547:	89 d8                	mov    %ebx,%eax
f0106549:	e8 ca fe ff ff       	call   f0106418 <holding>
f010654e:	85 c0                	test   %eax,%eax
f0106550:	0f 85 d4 00 00 00    	jne    f010662a <spin_unlock+0xf5>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0106556:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f010655d:	00 
f010655e:	8d 43 0c             	lea    0xc(%ebx),%eax
f0106561:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106565:	8d 45 c0             	lea    -0x40(%ebp),%eax
f0106568:	89 04 24             	mov    %eax,(%esp)
f010656b:	e8 13 f6 ff ff       	call   f0105b83 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0106570:	8b 43 08             	mov    0x8(%ebx),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0106573:	0f b6 30             	movzbl (%eax),%esi
f0106576:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0106579:	e8 4e fc ff ff       	call   f01061cc <cpunum>
f010657e:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0106582:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0106586:	89 44 24 04          	mov    %eax,0x4(%esp)
f010658a:	c7 04 24 94 82 10 f0 	movl   $0xf0108294,(%esp)
f0106591:	e8 28 d8 ff ff       	call   f0103dbe <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106596:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0106599:	85 c0                	test   %eax,%eax
f010659b:	74 71                	je     f010660e <spin_unlock+0xd9>
f010659d:	8d 5d c0             	lea    -0x40(%ebp),%ebx
#endif
}

// Release the lock.
void
spin_unlock(struct spinlock *lk)
f01065a0:	8d 7d e4             	lea    -0x1c(%ebp),%edi
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01065a3:	8d 75 a8             	lea    -0x58(%ebp),%esi
f01065a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01065aa:	89 04 24             	mov    %eax,(%esp)
f01065ad:	e8 64 e9 ff ff       	call   f0104f16 <debuginfo_eip>
f01065b2:	85 c0                	test   %eax,%eax
f01065b4:	78 39                	js     f01065ef <spin_unlock+0xba>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f01065b6:	8b 03                	mov    (%ebx),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f01065b8:	89 c2                	mov    %eax,%edx
f01065ba:	2b 55 b8             	sub    -0x48(%ebp),%edx
f01065bd:	89 54 24 18          	mov    %edx,0x18(%esp)
f01065c1:	8b 55 b0             	mov    -0x50(%ebp),%edx
f01065c4:	89 54 24 14          	mov    %edx,0x14(%esp)
f01065c8:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f01065cb:	89 54 24 10          	mov    %edx,0x10(%esp)
f01065cf:	8b 55 ac             	mov    -0x54(%ebp),%edx
f01065d2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01065d6:	8b 55 a8             	mov    -0x58(%ebp),%edx
f01065d9:	89 54 24 08          	mov    %edx,0x8(%esp)
f01065dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01065e1:	c7 04 24 dc 82 10 f0 	movl   $0xf01082dc,(%esp)
f01065e8:	e8 d1 d7 ff ff       	call   f0103dbe <cprintf>
f01065ed:	eb 12                	jmp    f0106601 <spin_unlock+0xcc>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01065ef:	8b 03                	mov    (%ebx),%eax
f01065f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01065f5:	c7 04 24 f3 82 10 f0 	movl   $0xf01082f3,(%esp)
f01065fc:	e8 bd d7 ff ff       	call   f0103dbe <cprintf>
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106601:	39 fb                	cmp    %edi,%ebx
f0106603:	74 09                	je     f010660e <spin_unlock+0xd9>
f0106605:	83 c3 04             	add    $0x4,%ebx
f0106608:	8b 03                	mov    (%ebx),%eax
f010660a:	85 c0                	test   %eax,%eax
f010660c:	75 98                	jne    f01065a6 <spin_unlock+0x71>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f010660e:	c7 44 24 08 fb 82 10 	movl   $0xf01082fb,0x8(%esp)
f0106615:	f0 
f0106616:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
f010661d:	00 
f010661e:	c7 04 24 cc 82 10 f0 	movl   $0xf01082cc,(%esp)
f0106625:	e8 16 9a ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f010662a:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
	lk->cpu = 0;
f0106631:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0106638:	b8 00 00 00 00       	mov    $0x0,%eax
f010663d:	f0 87 03             	lock xchg %eax,(%ebx)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0106640:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0106643:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0106646:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0106649:	89 ec                	mov    %ebp,%esp
f010664b:	5d                   	pop    %ebp
f010664c:	c3                   	ret    
f010664d:	66 90                	xchg   %ax,%ax
f010664f:	90                   	nop

f0106650 <__udivdi3>:
f0106650:	83 ec 1c             	sub    $0x1c,%esp
f0106653:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0106657:	89 7c 24 14          	mov    %edi,0x14(%esp)
f010665b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010665f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0106663:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0106667:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f010666b:	85 c0                	test   %eax,%eax
f010666d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0106671:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0106675:	89 ea                	mov    %ebp,%edx
f0106677:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010667b:	75 33                	jne    f01066b0 <__udivdi3+0x60>
f010667d:	39 e9                	cmp    %ebp,%ecx
f010667f:	77 6f                	ja     f01066f0 <__udivdi3+0xa0>
f0106681:	85 c9                	test   %ecx,%ecx
f0106683:	89 ce                	mov    %ecx,%esi
f0106685:	75 0b                	jne    f0106692 <__udivdi3+0x42>
f0106687:	b8 01 00 00 00       	mov    $0x1,%eax
f010668c:	31 d2                	xor    %edx,%edx
f010668e:	f7 f1                	div    %ecx
f0106690:	89 c6                	mov    %eax,%esi
f0106692:	31 d2                	xor    %edx,%edx
f0106694:	89 e8                	mov    %ebp,%eax
f0106696:	f7 f6                	div    %esi
f0106698:	89 c5                	mov    %eax,%ebp
f010669a:	89 f8                	mov    %edi,%eax
f010669c:	f7 f6                	div    %esi
f010669e:	89 ea                	mov    %ebp,%edx
f01066a0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01066a4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01066a8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01066ac:	83 c4 1c             	add    $0x1c,%esp
f01066af:	c3                   	ret    
f01066b0:	39 e8                	cmp    %ebp,%eax
f01066b2:	77 24                	ja     f01066d8 <__udivdi3+0x88>
f01066b4:	0f bd c8             	bsr    %eax,%ecx
f01066b7:	83 f1 1f             	xor    $0x1f,%ecx
f01066ba:	89 0c 24             	mov    %ecx,(%esp)
f01066bd:	75 49                	jne    f0106708 <__udivdi3+0xb8>
f01066bf:	8b 74 24 08          	mov    0x8(%esp),%esi
f01066c3:	39 74 24 04          	cmp    %esi,0x4(%esp)
f01066c7:	0f 86 ab 00 00 00    	jbe    f0106778 <__udivdi3+0x128>
f01066cd:	39 e8                	cmp    %ebp,%eax
f01066cf:	0f 82 a3 00 00 00    	jb     f0106778 <__udivdi3+0x128>
f01066d5:	8d 76 00             	lea    0x0(%esi),%esi
f01066d8:	31 d2                	xor    %edx,%edx
f01066da:	31 c0                	xor    %eax,%eax
f01066dc:	8b 74 24 10          	mov    0x10(%esp),%esi
f01066e0:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01066e4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01066e8:	83 c4 1c             	add    $0x1c,%esp
f01066eb:	c3                   	ret    
f01066ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01066f0:	89 f8                	mov    %edi,%eax
f01066f2:	f7 f1                	div    %ecx
f01066f4:	31 d2                	xor    %edx,%edx
f01066f6:	8b 74 24 10          	mov    0x10(%esp),%esi
f01066fa:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01066fe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0106702:	83 c4 1c             	add    $0x1c,%esp
f0106705:	c3                   	ret    
f0106706:	66 90                	xchg   %ax,%ax
f0106708:	0f b6 0c 24          	movzbl (%esp),%ecx
f010670c:	89 c6                	mov    %eax,%esi
f010670e:	b8 20 00 00 00       	mov    $0x20,%eax
f0106713:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0106717:	2b 04 24             	sub    (%esp),%eax
f010671a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010671e:	d3 e6                	shl    %cl,%esi
f0106720:	89 c1                	mov    %eax,%ecx
f0106722:	d3 ed                	shr    %cl,%ebp
f0106724:	0f b6 0c 24          	movzbl (%esp),%ecx
f0106728:	09 f5                	or     %esi,%ebp
f010672a:	8b 74 24 04          	mov    0x4(%esp),%esi
f010672e:	d3 e6                	shl    %cl,%esi
f0106730:	89 c1                	mov    %eax,%ecx
f0106732:	89 74 24 04          	mov    %esi,0x4(%esp)
f0106736:	89 d6                	mov    %edx,%esi
f0106738:	d3 ee                	shr    %cl,%esi
f010673a:	0f b6 0c 24          	movzbl (%esp),%ecx
f010673e:	d3 e2                	shl    %cl,%edx
f0106740:	89 c1                	mov    %eax,%ecx
f0106742:	d3 ef                	shr    %cl,%edi
f0106744:	09 d7                	or     %edx,%edi
f0106746:	89 f2                	mov    %esi,%edx
f0106748:	89 f8                	mov    %edi,%eax
f010674a:	f7 f5                	div    %ebp
f010674c:	89 d6                	mov    %edx,%esi
f010674e:	89 c7                	mov    %eax,%edi
f0106750:	f7 64 24 04          	mull   0x4(%esp)
f0106754:	39 d6                	cmp    %edx,%esi
f0106756:	72 30                	jb     f0106788 <__udivdi3+0x138>
f0106758:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f010675c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0106760:	d3 e5                	shl    %cl,%ebp
f0106762:	39 c5                	cmp    %eax,%ebp
f0106764:	73 04                	jae    f010676a <__udivdi3+0x11a>
f0106766:	39 d6                	cmp    %edx,%esi
f0106768:	74 1e                	je     f0106788 <__udivdi3+0x138>
f010676a:	89 f8                	mov    %edi,%eax
f010676c:	31 d2                	xor    %edx,%edx
f010676e:	e9 69 ff ff ff       	jmp    f01066dc <__udivdi3+0x8c>
f0106773:	90                   	nop
f0106774:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106778:	31 d2                	xor    %edx,%edx
f010677a:	b8 01 00 00 00       	mov    $0x1,%eax
f010677f:	e9 58 ff ff ff       	jmp    f01066dc <__udivdi3+0x8c>
f0106784:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106788:	8d 47 ff             	lea    -0x1(%edi),%eax
f010678b:	31 d2                	xor    %edx,%edx
f010678d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0106791:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0106795:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0106799:	83 c4 1c             	add    $0x1c,%esp
f010679c:	c3                   	ret    
f010679d:	66 90                	xchg   %ax,%ax
f010679f:	90                   	nop

f01067a0 <__umoddi3>:
f01067a0:	83 ec 2c             	sub    $0x2c,%esp
f01067a3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01067a7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01067ab:	89 74 24 20          	mov    %esi,0x20(%esp)
f01067af:	8b 74 24 38          	mov    0x38(%esp),%esi
f01067b3:	89 7c 24 24          	mov    %edi,0x24(%esp)
f01067b7:	8b 7c 24 34          	mov    0x34(%esp),%edi
f01067bb:	85 c0                	test   %eax,%eax
f01067bd:	89 c2                	mov    %eax,%edx
f01067bf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f01067c3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f01067c7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01067cb:	89 74 24 10          	mov    %esi,0x10(%esp)
f01067cf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01067d3:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01067d7:	75 1f                	jne    f01067f8 <__umoddi3+0x58>
f01067d9:	39 fe                	cmp    %edi,%esi
f01067db:	76 63                	jbe    f0106840 <__umoddi3+0xa0>
f01067dd:	89 c8                	mov    %ecx,%eax
f01067df:	89 fa                	mov    %edi,%edx
f01067e1:	f7 f6                	div    %esi
f01067e3:	89 d0                	mov    %edx,%eax
f01067e5:	31 d2                	xor    %edx,%edx
f01067e7:	8b 74 24 20          	mov    0x20(%esp),%esi
f01067eb:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01067ef:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01067f3:	83 c4 2c             	add    $0x2c,%esp
f01067f6:	c3                   	ret    
f01067f7:	90                   	nop
f01067f8:	39 f8                	cmp    %edi,%eax
f01067fa:	77 64                	ja     f0106860 <__umoddi3+0xc0>
f01067fc:	0f bd e8             	bsr    %eax,%ebp
f01067ff:	83 f5 1f             	xor    $0x1f,%ebp
f0106802:	75 74                	jne    f0106878 <__umoddi3+0xd8>
f0106804:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0106808:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f010680c:	0f 87 0e 01 00 00    	ja     f0106920 <__umoddi3+0x180>
f0106812:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0106816:	29 f1                	sub    %esi,%ecx
f0106818:	19 c7                	sbb    %eax,%edi
f010681a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010681e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0106822:	8b 44 24 14          	mov    0x14(%esp),%eax
f0106826:	8b 54 24 18          	mov    0x18(%esp),%edx
f010682a:	8b 74 24 20          	mov    0x20(%esp),%esi
f010682e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0106832:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0106836:	83 c4 2c             	add    $0x2c,%esp
f0106839:	c3                   	ret    
f010683a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106840:	85 f6                	test   %esi,%esi
f0106842:	89 f5                	mov    %esi,%ebp
f0106844:	75 0b                	jne    f0106851 <__umoddi3+0xb1>
f0106846:	b8 01 00 00 00       	mov    $0x1,%eax
f010684b:	31 d2                	xor    %edx,%edx
f010684d:	f7 f6                	div    %esi
f010684f:	89 c5                	mov    %eax,%ebp
f0106851:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106855:	31 d2                	xor    %edx,%edx
f0106857:	f7 f5                	div    %ebp
f0106859:	89 c8                	mov    %ecx,%eax
f010685b:	f7 f5                	div    %ebp
f010685d:	eb 84                	jmp    f01067e3 <__umoddi3+0x43>
f010685f:	90                   	nop
f0106860:	89 c8                	mov    %ecx,%eax
f0106862:	89 fa                	mov    %edi,%edx
f0106864:	8b 74 24 20          	mov    0x20(%esp),%esi
f0106868:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010686c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0106870:	83 c4 2c             	add    $0x2c,%esp
f0106873:	c3                   	ret    
f0106874:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106878:	8b 44 24 10          	mov    0x10(%esp),%eax
f010687c:	be 20 00 00 00       	mov    $0x20,%esi
f0106881:	89 e9                	mov    %ebp,%ecx
f0106883:	29 ee                	sub    %ebp,%esi
f0106885:	d3 e2                	shl    %cl,%edx
f0106887:	89 f1                	mov    %esi,%ecx
f0106889:	d3 e8                	shr    %cl,%eax
f010688b:	89 e9                	mov    %ebp,%ecx
f010688d:	09 d0                	or     %edx,%eax
f010688f:	89 fa                	mov    %edi,%edx
f0106891:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106895:	8b 44 24 10          	mov    0x10(%esp),%eax
f0106899:	d3 e0                	shl    %cl,%eax
f010689b:	89 f1                	mov    %esi,%ecx
f010689d:	89 44 24 10          	mov    %eax,0x10(%esp)
f01068a1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01068a5:	d3 ea                	shr    %cl,%edx
f01068a7:	89 e9                	mov    %ebp,%ecx
f01068a9:	d3 e7                	shl    %cl,%edi
f01068ab:	89 f1                	mov    %esi,%ecx
f01068ad:	d3 e8                	shr    %cl,%eax
f01068af:	89 e9                	mov    %ebp,%ecx
f01068b1:	09 f8                	or     %edi,%eax
f01068b3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01068b7:	f7 74 24 0c          	divl   0xc(%esp)
f01068bb:	d3 e7                	shl    %cl,%edi
f01068bd:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01068c1:	89 d7                	mov    %edx,%edi
f01068c3:	f7 64 24 10          	mull   0x10(%esp)
f01068c7:	39 d7                	cmp    %edx,%edi
f01068c9:	89 c1                	mov    %eax,%ecx
f01068cb:	89 54 24 14          	mov    %edx,0x14(%esp)
f01068cf:	72 3b                	jb     f010690c <__umoddi3+0x16c>
f01068d1:	39 44 24 18          	cmp    %eax,0x18(%esp)
f01068d5:	72 31                	jb     f0106908 <__umoddi3+0x168>
f01068d7:	8b 44 24 18          	mov    0x18(%esp),%eax
f01068db:	29 c8                	sub    %ecx,%eax
f01068dd:	19 d7                	sbb    %edx,%edi
f01068df:	89 e9                	mov    %ebp,%ecx
f01068e1:	89 fa                	mov    %edi,%edx
f01068e3:	d3 e8                	shr    %cl,%eax
f01068e5:	89 f1                	mov    %esi,%ecx
f01068e7:	d3 e2                	shl    %cl,%edx
f01068e9:	89 e9                	mov    %ebp,%ecx
f01068eb:	09 d0                	or     %edx,%eax
f01068ed:	89 fa                	mov    %edi,%edx
f01068ef:	d3 ea                	shr    %cl,%edx
f01068f1:	8b 74 24 20          	mov    0x20(%esp),%esi
f01068f5:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01068f9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01068fd:	83 c4 2c             	add    $0x2c,%esp
f0106900:	c3                   	ret    
f0106901:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106908:	39 d7                	cmp    %edx,%edi
f010690a:	75 cb                	jne    f01068d7 <__umoddi3+0x137>
f010690c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0106910:	89 c1                	mov    %eax,%ecx
f0106912:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0106916:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010691a:	eb bb                	jmp    f01068d7 <__umoddi3+0x137>
f010691c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106920:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0106924:	0f 82 e8 fe ff ff    	jb     f0106812 <__umoddi3+0x72>
f010692a:	e9 f3 fe ff ff       	jmp    f0106822 <__umoddi3+0x82>

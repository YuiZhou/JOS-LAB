
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
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
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
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 b0 ef 17 f0       	mov    $0xf017efb0,%eax
f010004b:	2d a3 e0 17 f0       	sub    $0xf017e0a3,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 a3 e0 17 f0 	movl   $0xf017e0a3,(%esp)
f0100063:	e8 3d 4d 00 00       	call   f0104da5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 ca 04 00 00       	call   f0100537 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 e0 52 10 f0 	movl   $0xf01052e0,(%esp)
f010007c:	e8 9d 36 00 00       	call   f010371e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 44 12 00 00       	call   f01012ca <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 5d 30 00 00       	call   f01030e8 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 08 37 00 00       	call   f010379d <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010009c:	00 
f010009d:	c7 44 24 04 62 78 00 	movl   $0x7862,0x4(%esp)
f01000a4:	00 
f01000a5:	c7 04 24 97 2c 13 f0 	movl   $0xf0132c97,(%esp)
f01000ac:	e8 19 32 00 00       	call   f01032ca <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000b1:	a1 0c e3 17 f0       	mov    0xf017e30c,%eax
f01000b6:	89 04 24             	mov    %eax,(%esp)
f01000b9:	e8 87 35 00 00       	call   f0103645 <env_run>

f01000be <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000be:	55                   	push   %ebp
f01000bf:	89 e5                	mov    %esp,%ebp
f01000c1:	56                   	push   %esi
f01000c2:	53                   	push   %ebx
f01000c3:	83 ec 10             	sub    $0x10,%esp
f01000c6:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c9:	83 3d a0 ef 17 f0 00 	cmpl   $0x0,0xf017efa0
f01000d0:	75 3d                	jne    f010010f <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000d2:	89 35 a0 ef 17 f0    	mov    %esi,0xf017efa0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d8:	fa                   	cli    
f01000d9:	fc                   	cld    

	va_start(ap, fmt);
f01000da:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01000e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000eb:	c7 04 24 fb 52 10 f0 	movl   $0xf01052fb,(%esp)
f01000f2:	e8 27 36 00 00       	call   f010371e <cprintf>
	vcprintf(fmt, ap);
f01000f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000fb:	89 34 24             	mov    %esi,(%esp)
f01000fe:	e8 e8 35 00 00       	call   f01036eb <vcprintf>
	cprintf("\n");
f0100103:	c7 04 24 6c 5f 10 f0 	movl   $0xf0105f6c,(%esp)
f010010a:	e8 0f 36 00 00       	call   f010371e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010010f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100116:	e8 65 07 00 00       	call   f0100880 <monitor>
f010011b:	eb f2                	jmp    f010010f <_panic+0x51>

f010011d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011d:	55                   	push   %ebp
f010011e:	89 e5                	mov    %esp,%ebp
f0100120:	53                   	push   %ebx
f0100121:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100124:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100127:	8b 45 0c             	mov    0xc(%ebp),%eax
f010012a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010012e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100131:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100135:	c7 04 24 13 53 10 f0 	movl   $0xf0105313,(%esp)
f010013c:	e8 dd 35 00 00       	call   f010371e <cprintf>
	vcprintf(fmt, ap);
f0100141:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100145:	8b 45 10             	mov    0x10(%ebp),%eax
f0100148:	89 04 24             	mov    %eax,(%esp)
f010014b:	e8 9b 35 00 00       	call   f01036eb <vcprintf>
	cprintf("\n");
f0100150:	c7 04 24 6c 5f 10 f0 	movl   $0xf0105f6c,(%esp)
f0100157:	e8 c2 35 00 00       	call   f010371e <cprintf>
	va_end(ap);
}
f010015c:	83 c4 14             	add    $0x14,%esp
f010015f:	5b                   	pop    %ebx
f0100160:	5d                   	pop    %ebp
f0100161:	c3                   	ret    
f0100162:	66 90                	xchg   %ax,%ax
f0100164:	66 90                	xchg   %ax,%ax
f0100166:	66 90                	xchg   %ax,%ax
f0100168:	66 90                	xchg   %ax,%ax
f010016a:	66 90                	xchg   %ax,%ax
f010016c:	66 90                	xchg   %ax,%ax
f010016e:	66 90                	xchg   %ax,%ax

f0100170 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100170:	55                   	push   %ebp
f0100171:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100173:	ba 84 00 00 00       	mov    $0x84,%edx
f0100178:	ec                   	in     (%dx),%al
f0100179:	ec                   	in     (%dx),%al
f010017a:	ec                   	in     (%dx),%al
f010017b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010017e:	55                   	push   %ebp
f010017f:	89 e5                	mov    %esp,%ebp
f0100181:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100186:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100187:	a8 01                	test   $0x1,%al
f0100189:	74 08                	je     f0100193 <serial_proc_data+0x15>
f010018b:	b2 f8                	mov    $0xf8,%dl
f010018d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018e:	0f b6 c0             	movzbl %al,%eax
f0100191:	eb 05                	jmp    f0100198 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100193:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100198:	5d                   	pop    %ebp
f0100199:	c3                   	ret    

f010019a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010019a:	55                   	push   %ebp
f010019b:	89 e5                	mov    %esp,%ebp
f010019d:	53                   	push   %ebx
f010019e:	83 ec 04             	sub    $0x4,%esp
f01001a1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001a3:	eb 26                	jmp    f01001cb <cons_intr+0x31>
		if (c == 0)
f01001a5:	85 d2                	test   %edx,%edx
f01001a7:	74 22                	je     f01001cb <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a9:	a1 e4 e2 17 f0       	mov    0xf017e2e4,%eax
f01001ae:	88 90 e0 e0 17 f0    	mov    %dl,-0xfe81f20(%eax)
f01001b4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001b7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c2:	0f 44 d0             	cmove  %eax,%edx
f01001c5:	89 15 e4 e2 17 f0    	mov    %edx,0xf017e2e4
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cb:	ff d3                	call   *%ebx
f01001cd:	89 c2                	mov    %eax,%edx
f01001cf:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d2:	75 d1                	jne    f01001a5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d4:	83 c4 04             	add    $0x4,%esp
f01001d7:	5b                   	pop    %ebx
f01001d8:	5d                   	pop    %ebp
f01001d9:	c3                   	ret    

f01001da <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001da:	55                   	push   %ebp
f01001db:	89 e5                	mov    %esp,%ebp
f01001dd:	57                   	push   %edi
f01001de:	56                   	push   %esi
f01001df:	53                   	push   %ebx
f01001e0:	83 ec 2c             	sub    $0x2c,%esp
f01001e3:	89 c7                	mov    %eax,%edi
f01001e5:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001ea:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001eb:	a8 20                	test   $0x20,%al
f01001ed:	75 1b                	jne    f010020a <cons_putc+0x30>
f01001ef:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f4:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001f9:	e8 72 ff ff ff       	call   f0100170 <delay>
f01001fe:	89 f2                	mov    %esi,%edx
f0100200:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f0100201:	a8 20                	test   $0x20,%al
f0100203:	75 05                	jne    f010020a <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100205:	83 eb 01             	sub    $0x1,%ebx
f0100208:	75 ef                	jne    f01001f9 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f010020a:	89 f8                	mov    %edi,%eax
f010020c:	25 ff 00 00 00       	and    $0xff,%eax
f0100211:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100214:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100219:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010021a:	b2 79                	mov    $0x79,%dl
f010021c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010021d:	84 c0                	test   %al,%al
f010021f:	78 1b                	js     f010023c <cons_putc+0x62>
f0100221:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100226:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f010022b:	e8 40 ff ff ff       	call   f0100170 <delay>
f0100230:	89 f2                	mov    %esi,%edx
f0100232:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100233:	84 c0                	test   %al,%al
f0100235:	78 05                	js     f010023c <cons_putc+0x62>
f0100237:	83 eb 01             	sub    $0x1,%ebx
f010023a:	75 ef                	jne    f010022b <cons_putc+0x51>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100241:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100245:	ee                   	out    %al,(%dx)
f0100246:	b2 7a                	mov    $0x7a,%dl
f0100248:	b8 0d 00 00 00       	mov    $0xd,%eax
f010024d:	ee                   	out    %al,(%dx)
f010024e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100253:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100254:	89 fa                	mov    %edi,%edx
f0100256:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010025c:	89 f8                	mov    %edi,%eax
f010025e:	80 cc 07             	or     $0x7,%ah
f0100261:	85 d2                	test   %edx,%edx
f0100263:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100266:	89 f8                	mov    %edi,%eax
f0100268:	25 ff 00 00 00       	and    $0xff,%eax
f010026d:	83 f8 09             	cmp    $0x9,%eax
f0100270:	74 77                	je     f01002e9 <cons_putc+0x10f>
f0100272:	83 f8 09             	cmp    $0x9,%eax
f0100275:	7f 0b                	jg     f0100282 <cons_putc+0xa8>
f0100277:	83 f8 08             	cmp    $0x8,%eax
f010027a:	0f 85 9d 00 00 00    	jne    f010031d <cons_putc+0x143>
f0100280:	eb 10                	jmp    f0100292 <cons_putc+0xb8>
f0100282:	83 f8 0a             	cmp    $0xa,%eax
f0100285:	74 3c                	je     f01002c3 <cons_putc+0xe9>
f0100287:	83 f8 0d             	cmp    $0xd,%eax
f010028a:	0f 85 8d 00 00 00    	jne    f010031d <cons_putc+0x143>
f0100290:	eb 39                	jmp    f01002cb <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f0100292:	0f b7 05 f4 e2 17 f0 	movzwl 0xf017e2f4,%eax
f0100299:	66 85 c0             	test   %ax,%ax
f010029c:	0f 84 e5 00 00 00    	je     f0100387 <cons_putc+0x1ad>
			crt_pos--;
f01002a2:	83 e8 01             	sub    $0x1,%eax
f01002a5:	66 a3 f4 e2 17 f0    	mov    %ax,0xf017e2f4
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002ab:	0f b7 c0             	movzwl %ax,%eax
f01002ae:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002b4:	83 cf 20             	or     $0x20,%edi
f01002b7:	8b 15 f0 e2 17 f0    	mov    0xf017e2f0,%edx
f01002bd:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002c1:	eb 77                	jmp    f010033a <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002c3:	66 83 05 f4 e2 17 f0 	addw   $0x50,0xf017e2f4
f01002ca:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002cb:	0f b7 05 f4 e2 17 f0 	movzwl 0xf017e2f4,%eax
f01002d2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002d8:	c1 e8 16             	shr    $0x16,%eax
f01002db:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002de:	c1 e0 04             	shl    $0x4,%eax
f01002e1:	66 a3 f4 e2 17 f0    	mov    %ax,0xf017e2f4
f01002e7:	eb 51                	jmp    f010033a <cons_putc+0x160>
		break;
	case '\t':
		cons_putc(' ');
f01002e9:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ee:	e8 e7 fe ff ff       	call   f01001da <cons_putc>
		cons_putc(' ');
f01002f3:	b8 20 00 00 00       	mov    $0x20,%eax
f01002f8:	e8 dd fe ff ff       	call   f01001da <cons_putc>
		cons_putc(' ');
f01002fd:	b8 20 00 00 00       	mov    $0x20,%eax
f0100302:	e8 d3 fe ff ff       	call   f01001da <cons_putc>
		cons_putc(' ');
f0100307:	b8 20 00 00 00       	mov    $0x20,%eax
f010030c:	e8 c9 fe ff ff       	call   f01001da <cons_putc>
		cons_putc(' ');
f0100311:	b8 20 00 00 00       	mov    $0x20,%eax
f0100316:	e8 bf fe ff ff       	call   f01001da <cons_putc>
f010031b:	eb 1d                	jmp    f010033a <cons_putc+0x160>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010031d:	0f b7 05 f4 e2 17 f0 	movzwl 0xf017e2f4,%eax
f0100324:	0f b7 c8             	movzwl %ax,%ecx
f0100327:	8b 15 f0 e2 17 f0    	mov    0xf017e2f0,%edx
f010032d:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100331:	83 c0 01             	add    $0x1,%eax
f0100334:	66 a3 f4 e2 17 f0    	mov    %ax,0xf017e2f4
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010033a:	66 81 3d f4 e2 17 f0 	cmpw   $0x7cf,0xf017e2f4
f0100341:	cf 07 
f0100343:	76 42                	jbe    f0100387 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100345:	a1 f0 e2 17 f0       	mov    0xf017e2f0,%eax
f010034a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100351:	00 
f0100352:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100358:	89 54 24 04          	mov    %edx,0x4(%esp)
f010035c:	89 04 24             	mov    %eax,(%esp)
f010035f:	e8 9f 4a 00 00       	call   f0104e03 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100364:	8b 15 f0 e2 17 f0    	mov    0xf017e2f0,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010036a:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010036f:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100375:	83 c0 01             	add    $0x1,%eax
f0100378:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010037d:	75 f0                	jne    f010036f <cons_putc+0x195>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010037f:	66 83 2d f4 e2 17 f0 	subw   $0x50,0xf017e2f4
f0100386:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100387:	8b 0d ec e2 17 f0    	mov    0xf017e2ec,%ecx
f010038d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100392:	89 ca                	mov    %ecx,%edx
f0100394:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100395:	0f b7 1d f4 e2 17 f0 	movzwl 0xf017e2f4,%ebx
f010039c:	8d 71 01             	lea    0x1(%ecx),%esi
f010039f:	89 d8                	mov    %ebx,%eax
f01003a1:	66 c1 e8 08          	shr    $0x8,%ax
f01003a5:	89 f2                	mov    %esi,%edx
f01003a7:	ee                   	out    %al,(%dx)
f01003a8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003ad:	89 ca                	mov    %ecx,%edx
f01003af:	ee                   	out    %al,(%dx)
f01003b0:	89 d8                	mov    %ebx,%eax
f01003b2:	89 f2                	mov    %esi,%edx
f01003b4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003b5:	83 c4 2c             	add    $0x2c,%esp
f01003b8:	5b                   	pop    %ebx
f01003b9:	5e                   	pop    %esi
f01003ba:	5f                   	pop    %edi
f01003bb:	5d                   	pop    %ebp
f01003bc:	c3                   	ret    

f01003bd <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003bd:	55                   	push   %ebp
f01003be:	89 e5                	mov    %esp,%ebp
f01003c0:	53                   	push   %ebx
f01003c1:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003c4:	ba 64 00 00 00       	mov    $0x64,%edx
f01003c9:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003ca:	a8 01                	test   $0x1,%al
f01003cc:	0f 84 e5 00 00 00    	je     f01004b7 <kbd_proc_data+0xfa>
f01003d2:	b2 60                	mov    $0x60,%dl
f01003d4:	ec                   	in     (%dx),%al
f01003d5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003d7:	3c e0                	cmp    $0xe0,%al
f01003d9:	75 11                	jne    f01003ec <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01003db:	83 0d e8 e2 17 f0 40 	orl    $0x40,0xf017e2e8
		return 0;
f01003e2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003e7:	e9 d0 00 00 00       	jmp    f01004bc <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003ec:	84 c0                	test   %al,%al
f01003ee:	79 37                	jns    f0100427 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003f0:	8b 0d e8 e2 17 f0    	mov    0xf017e2e8,%ecx
f01003f6:	89 cb                	mov    %ecx,%ebx
f01003f8:	83 e3 40             	and    $0x40,%ebx
f01003fb:	83 e0 7f             	and    $0x7f,%eax
f01003fe:	85 db                	test   %ebx,%ebx
f0100400:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100403:	0f b6 d2             	movzbl %dl,%edx
f0100406:	0f b6 82 60 53 10 f0 	movzbl -0xfefaca0(%edx),%eax
f010040d:	83 c8 40             	or     $0x40,%eax
f0100410:	0f b6 c0             	movzbl %al,%eax
f0100413:	f7 d0                	not    %eax
f0100415:	21 c1                	and    %eax,%ecx
f0100417:	89 0d e8 e2 17 f0    	mov    %ecx,0xf017e2e8
		return 0;
f010041d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100422:	e9 95 00 00 00       	jmp    f01004bc <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f0100427:	8b 0d e8 e2 17 f0    	mov    0xf017e2e8,%ecx
f010042d:	f6 c1 40             	test   $0x40,%cl
f0100430:	74 0e                	je     f0100440 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100432:	89 c2                	mov    %eax,%edx
f0100434:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100437:	83 e1 bf             	and    $0xffffffbf,%ecx
f010043a:	89 0d e8 e2 17 f0    	mov    %ecx,0xf017e2e8
	}

	shift |= shiftcode[data];
f0100440:	0f b6 d2             	movzbl %dl,%edx
f0100443:	0f b6 82 60 53 10 f0 	movzbl -0xfefaca0(%edx),%eax
f010044a:	0b 05 e8 e2 17 f0    	or     0xf017e2e8,%eax
	shift ^= togglecode[data];
f0100450:	0f b6 8a 60 54 10 f0 	movzbl -0xfefaba0(%edx),%ecx
f0100457:	31 c8                	xor    %ecx,%eax
f0100459:	a3 e8 e2 17 f0       	mov    %eax,0xf017e2e8

	c = charcode[shift & (CTL | SHIFT)][data];
f010045e:	89 c1                	mov    %eax,%ecx
f0100460:	83 e1 03             	and    $0x3,%ecx
f0100463:	8b 0c 8d 60 55 10 f0 	mov    -0xfefaaa0(,%ecx,4),%ecx
f010046a:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010046e:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100471:	a8 08                	test   $0x8,%al
f0100473:	74 1b                	je     f0100490 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100475:	89 da                	mov    %ebx,%edx
f0100477:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010047a:	83 f9 19             	cmp    $0x19,%ecx
f010047d:	77 05                	ja     f0100484 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010047f:	83 eb 20             	sub    $0x20,%ebx
f0100482:	eb 0c                	jmp    f0100490 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100484:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100487:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010048a:	83 fa 19             	cmp    $0x19,%edx
f010048d:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100490:	f7 d0                	not    %eax
f0100492:	a8 06                	test   $0x6,%al
f0100494:	75 26                	jne    f01004bc <kbd_proc_data+0xff>
f0100496:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010049c:	75 1e                	jne    f01004bc <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f010049e:	c7 04 24 2d 53 10 f0 	movl   $0xf010532d,(%esp)
f01004a5:	e8 74 32 00 00       	call   f010371e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004aa:	ba 92 00 00 00       	mov    $0x92,%edx
f01004af:	b8 03 00 00 00       	mov    $0x3,%eax
f01004b4:	ee                   	out    %al,(%dx)
f01004b5:	eb 05                	jmp    f01004bc <kbd_proc_data+0xff>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01004b7:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004bc:	89 d8                	mov    %ebx,%eax
f01004be:	83 c4 14             	add    $0x14,%esp
f01004c1:	5b                   	pop    %ebx
f01004c2:	5d                   	pop    %ebp
f01004c3:	c3                   	ret    

f01004c4 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004c4:	83 3d c0 e0 17 f0 00 	cmpl   $0x0,0xf017e0c0
f01004cb:	74 11                	je     f01004de <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004cd:	55                   	push   %ebp
f01004ce:	89 e5                	mov    %esp,%ebp
f01004d0:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004d3:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004d8:	e8 bd fc ff ff       	call   f010019a <cons_intr>
}
f01004dd:	c9                   	leave  
f01004de:	f3 c3                	repz ret 

f01004e0 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e0:	55                   	push   %ebp
f01004e1:	89 e5                	mov    %esp,%ebp
f01004e3:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004e6:	b8 bd 03 10 f0       	mov    $0xf01003bd,%eax
f01004eb:	e8 aa fc ff ff       	call   f010019a <cons_intr>
}
f01004f0:	c9                   	leave  
f01004f1:	c3                   	ret    

f01004f2 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004f2:	55                   	push   %ebp
f01004f3:	89 e5                	mov    %esp,%ebp
f01004f5:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004f8:	e8 c7 ff ff ff       	call   f01004c4 <serial_intr>
	kbd_intr();
f01004fd:	e8 de ff ff ff       	call   f01004e0 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100502:	8b 15 e0 e2 17 f0    	mov    0xf017e2e0,%edx
f0100508:	3b 15 e4 e2 17 f0    	cmp    0xf017e2e4,%edx
f010050e:	74 20                	je     f0100530 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f0100510:	0f b6 82 e0 e0 17 f0 	movzbl -0xfe81f20(%edx),%eax
f0100517:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010051a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f0100520:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100525:	0f 44 d1             	cmove  %ecx,%edx
f0100528:	89 15 e0 e2 17 f0    	mov    %edx,0xf017e2e0
f010052e:	eb 05                	jmp    f0100535 <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100530:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100535:	c9                   	leave  
f0100536:	c3                   	ret    

f0100537 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100537:	55                   	push   %ebp
f0100538:	89 e5                	mov    %esp,%ebp
f010053a:	57                   	push   %edi
f010053b:	56                   	push   %esi
f010053c:	53                   	push   %ebx
f010053d:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100540:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100547:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010054e:	5a a5 
	if (*cp != 0xA55A) {
f0100550:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100557:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010055b:	74 11                	je     f010056e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010055d:	c7 05 ec e2 17 f0 b4 	movl   $0x3b4,0xf017e2ec
f0100564:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100567:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010056c:	eb 16                	jmp    f0100584 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010056e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100575:	c7 05 ec e2 17 f0 d4 	movl   $0x3d4,0xf017e2ec
f010057c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010057f:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100584:	8b 0d ec e2 17 f0    	mov    0xf017e2ec,%ecx
f010058a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010058f:	89 ca                	mov    %ecx,%edx
f0100591:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100592:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100595:	89 da                	mov    %ebx,%edx
f0100597:	ec                   	in     (%dx),%al
f0100598:	0f b6 f0             	movzbl %al,%esi
f010059b:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010059e:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005a3:	89 ca                	mov    %ecx,%edx
f01005a5:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a6:	89 da                	mov    %ebx,%edx
f01005a8:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005a9:	89 3d f0 e2 17 f0    	mov    %edi,0xf017e2f0
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005af:	0f b6 d8             	movzbl %al,%ebx
f01005b2:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005b4:	66 89 35 f4 e2 17 f0 	mov    %si,0xf017e2f4
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005bb:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c5:	89 f2                	mov    %esi,%edx
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	b2 fb                	mov    $0xfb,%dl
f01005ca:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005cf:	ee                   	out    %al,(%dx)
f01005d0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005d5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005da:	89 da                	mov    %ebx,%edx
f01005dc:	ee                   	out    %al,(%dx)
f01005dd:	b2 f9                	mov    $0xf9,%dl
f01005df:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e4:	ee                   	out    %al,(%dx)
f01005e5:	b2 fb                	mov    $0xfb,%dl
f01005e7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	b2 fc                	mov    $0xfc,%dl
f01005ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f4:	ee                   	out    %al,(%dx)
f01005f5:	b2 f9                	mov    $0xf9,%dl
f01005f7:	b8 01 00 00 00       	mov    $0x1,%eax
f01005fc:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fd:	b2 fd                	mov    $0xfd,%dl
f01005ff:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100600:	3c ff                	cmp    $0xff,%al
f0100602:	0f 95 c1             	setne  %cl
f0100605:	0f b6 c9             	movzbl %cl,%ecx
f0100608:	89 0d c0 e0 17 f0    	mov    %ecx,0xf017e0c0
f010060e:	89 f2                	mov    %esi,%edx
f0100610:	ec                   	in     (%dx),%al
f0100611:	89 da                	mov    %ebx,%edx
f0100613:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100614:	85 c9                	test   %ecx,%ecx
f0100616:	75 0c                	jne    f0100624 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100618:	c7 04 24 39 53 10 f0 	movl   $0xf0105339,(%esp)
f010061f:	e8 fa 30 00 00       	call   f010371e <cprintf>
}
f0100624:	83 c4 1c             	add    $0x1c,%esp
f0100627:	5b                   	pop    %ebx
f0100628:	5e                   	pop    %esi
f0100629:	5f                   	pop    %edi
f010062a:	5d                   	pop    %ebp
f010062b:	c3                   	ret    

f010062c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010062c:	55                   	push   %ebp
f010062d:	89 e5                	mov    %esp,%ebp
f010062f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100632:	8b 45 08             	mov    0x8(%ebp),%eax
f0100635:	e8 a0 fb ff ff       	call   f01001da <cons_putc>
}
f010063a:	c9                   	leave  
f010063b:	c3                   	ret    

f010063c <getchar>:

int
getchar(void)
{
f010063c:	55                   	push   %ebp
f010063d:	89 e5                	mov    %esp,%ebp
f010063f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100642:	e8 ab fe ff ff       	call   f01004f2 <cons_getc>
f0100647:	85 c0                	test   %eax,%eax
f0100649:	74 f7                	je     f0100642 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010064b:	c9                   	leave  
f010064c:	c3                   	ret    

f010064d <iscons>:

int
iscons(int fdnum)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100650:	b8 01 00 00 00       	mov    $0x1,%eax
f0100655:	5d                   	pop    %ebp
f0100656:	c3                   	ret    
f0100657:	66 90                	xchg   %ax,%ax
f0100659:	66 90                	xchg   %ax,%ax
f010065b:	66 90                	xchg   %ax,%ax
f010065d:	66 90                	xchg   %ax,%ax
f010065f:	90                   	nop

f0100660 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100660:	55                   	push   %ebp
f0100661:	89 e5                	mov    %esp,%ebp
f0100663:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100666:	c7 04 24 70 55 10 f0 	movl   $0xf0105570,(%esp)
f010066d:	e8 ac 30 00 00       	call   f010371e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100672:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 88 56 10 f0 	movl   $0xf0105688,(%esp)
f0100689:	e8 90 30 00 00       	call   f010371e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068e:	c7 44 24 08 df 52 10 	movl   $0x1052df,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 df 52 10 	movl   $0xf01052df,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 ac 56 10 f0 	movl   $0xf01056ac,(%esp)
f01006a5:	e8 74 30 00 00       	call   f010371e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006aa:	c7 44 24 08 a3 e0 17 	movl   $0x17e0a3,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 a3 e0 17 	movl   $0xf017e0a3,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 d0 56 10 f0 	movl   $0xf01056d0,(%esp)
f01006c1:	e8 58 30 00 00       	call   f010371e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006c6:	c7 44 24 08 b0 ef 17 	movl   $0x17efb0,0x8(%esp)
f01006cd:	00 
f01006ce:	c7 44 24 04 b0 ef 17 	movl   $0xf017efb0,0x4(%esp)
f01006d5:	f0 
f01006d6:	c7 04 24 f4 56 10 f0 	movl   $0xf01056f4,(%esp)
f01006dd:	e8 3c 30 00 00       	call   f010371e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006e2:	b8 af f3 17 f0       	mov    $0xf017f3af,%eax
f01006e7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ec:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f2:	85 c0                	test   %eax,%eax
f01006f4:	0f 48 c2             	cmovs  %edx,%eax
f01006f7:	c1 f8 0a             	sar    $0xa,%eax
f01006fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006fe:	c7 04 24 18 57 10 f0 	movl   $0xf0105718,(%esp)
f0100705:	e8 14 30 00 00       	call   f010371e <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010070a:	b8 00 00 00 00       	mov    $0x0,%eax
f010070f:	c9                   	leave  
f0100710:	c3                   	ret    

f0100711 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100711:	55                   	push   %ebp
f0100712:	89 e5                	mov    %esp,%ebp
f0100714:	56                   	push   %esi
f0100715:	53                   	push   %ebx
f0100716:	83 ec 10             	sub    $0x10,%esp
f0100719:	bb c4 57 10 f0       	mov    $0xf01057c4,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f010071e:	be 00 58 10 f0       	mov    $0xf0105800,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100723:	8b 03                	mov    (%ebx),%eax
f0100725:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100729:	8b 43 fc             	mov    -0x4(%ebx),%eax
f010072c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100730:	c7 04 24 89 55 10 f0 	movl   $0xf0105589,(%esp)
f0100737:	e8 e2 2f 00 00       	call   f010371e <cprintf>
f010073c:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f010073f:	39 f3                	cmp    %esi,%ebx
f0100741:	75 e0                	jne    f0100723 <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100743:	b8 00 00 00 00       	mov    $0x0,%eax
f0100748:	83 c4 10             	add    $0x10,%esp
f010074b:	5b                   	pop    %ebx
f010074c:	5e                   	pop    %esi
f010074d:	5d                   	pop    %ebp
f010074e:	c3                   	ret    

f010074f <mon_debug>:
	}
	return -1;
}

int
mon_debug(int argc, char **argv, struct Trapframe *tf){
f010074f:	55                   	push   %ebp
f0100750:	89 e5                	mov    %esp,%ebp
f0100752:	83 ec 18             	sub    $0x18,%esp
f0100755:	8b 45 10             	mov    0x10(%ebp),%eax
	if(tf -> tf_trapno == T_BRKPT || tf -> tf_trapno == T_DEBUG){
f0100758:	8b 50 28             	mov    0x28(%eax),%edx
f010075b:	83 e2 fd             	and    $0xfffffffd,%edx
f010075e:	83 fa 01             	cmp    $0x1,%edx
f0100761:	75 14                	jne    f0100777 <mon_debug+0x28>
		tf -> tf_eflags |= FL_TF;
f0100763:	81 48 38 00 01 00 00 	orl    $0x100,0x38(%eax)
		env_run(curenv);
f010076a:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f010076f:	89 04 24             	mov    %eax,(%esp)
f0100772:	e8 ce 2e 00 00       	call   f0103645 <env_run>
	}
	return -1;
}
f0100777:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010077c:	c9                   	leave  
f010077d:	c3                   	ret    

f010077e <mon_continue>:
	}while(ebp);
	return 0;
}

int
mon_continue(int argc, char **argv, struct Trapframe *tf){
f010077e:	55                   	push   %ebp
f010077f:	89 e5                	mov    %esp,%ebp
f0100781:	83 ec 18             	sub    $0x18,%esp
f0100784:	8b 45 10             	mov    0x10(%ebp),%eax
	if(tf -> tf_trapno == T_BRKPT || tf -> tf_trapno == T_DEBUG){
f0100787:	8b 50 28             	mov    0x28(%eax),%edx
f010078a:	83 e2 fd             	and    $0xfffffffd,%edx
f010078d:	83 fa 01             	cmp    $0x1,%edx
f0100790:	75 14                	jne    f01007a6 <mon_continue+0x28>
	//	panic("##%x##\n",tf -> tf_eflags);
		tf -> tf_eflags &= ~FL_TF;
f0100792:	81 60 38 ff fe ff ff 	andl   $0xfffffeff,0x38(%eax)
		env_run(curenv);
f0100799:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f010079e:	89 04 24             	mov    %eax,(%esp)
f01007a1:	e8 9f 2e 00 00       	call   f0103645 <env_run>
	}
	return -1;
}
f01007a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01007ab:	c9                   	leave  
f01007ac:	c3                   	ret    

f01007ad <mon_backtrace>:
 * 2. *ebp is the new ebp(actually old)
 * 3. get the end(ebp = 0 -> see kern/entry.S, stack movl $0, %ebp)
 */
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007ad:	55                   	push   %ebp
f01007ae:	89 e5                	mov    %esp,%ebp
f01007b0:	57                   	push   %edi
f01007b1:	56                   	push   %esi
f01007b2:	53                   	push   %ebx
f01007b3:	83 ec 3c             	sub    $0x3c,%esp
	// Your code here.
	uint32_t ebp,eip;
	int i;	
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f01007b6:	c7 04 24 92 55 10 f0 	movl   $0xf0105592,(%esp)
f01007bd:	e8 5c 2f 00 00       	call   f010371e <cprintf>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007c2:	89 ee                	mov    %ebp,%esi
	ebp = read_ebp();
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
f01007c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007c8:	c7 04 24 a4 55 10 f0 	movl   $0xf01055a4,(%esp)
f01007cf:	e8 4a 2f 00 00       	call   f010371e <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f01007d4:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f01007d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007db:	c7 04 24 af 55 10 f0 	movl   $0xf01055af,(%esp)
f01007e2:	e8 37 2f 00 00       	call   f010371e <cprintf>
		for(i=2; i < 7; i++)
f01007e7:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f01007ec:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007ef:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f3:	c7 04 24 a9 55 10 f0 	movl   $0xf01055a9,(%esp)
f01007fa:	e8 1f 2f 00 00       	call   f010371e <cprintf>
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
		eip = *(uint32_t *)(ebp + 4);
		cprintf("  eip %08x  args",eip);
		for(i=2; i < 7; i++)
f01007ff:	83 c3 01             	add    $0x1,%ebx
f0100802:	83 fb 07             	cmp    $0x7,%ebx
f0100805:	75 e5                	jne    f01007ec <mon_backtrace+0x3f>
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
		cprintf("\n");
f0100807:	c7 04 24 6c 5f 10 f0 	movl   $0xf0105f6c,(%esp)
f010080e:	e8 0b 2f 00 00       	call   f010371e <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f0100813:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100816:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081a:	89 3c 24             	mov    %edi,(%esp)
f010081d:	e8 84 39 00 00       	call   f01041a6 <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f0100822:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100825:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100829:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010082c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100830:	c7 04 24 c0 55 10 f0 	movl   $0xf01055c0,(%esp)
f0100837:	e8 e2 2e 00 00       	call   f010371e <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f010083c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010083f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100843:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100846:	89 44 24 04          	mov    %eax,0x4(%esp)
f010084a:	c7 04 24 c9 55 10 f0 	movl   $0xf01055c9,(%esp)
f0100851:	e8 c8 2e 00 00       	call   f010371e <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f0100856:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100859:	89 44 24 04          	mov    %eax,0x4(%esp)
f010085d:	c7 04 24 ce 55 10 f0 	movl   $0xf01055ce,(%esp)
f0100864:	e8 b5 2e 00 00       	call   f010371e <cprintf>
		ebp = *(uint32_t *)ebp;
f0100869:	8b 36                	mov    (%esi),%esi
	}while(ebp);
f010086b:	85 f6                	test   %esi,%esi
f010086d:	0f 85 51 ff ff ff    	jne    f01007c4 <mon_backtrace+0x17>
	return 0;
}
f0100873:	b8 00 00 00 00       	mov    $0x0,%eax
f0100878:	83 c4 3c             	add    $0x3c,%esp
f010087b:	5b                   	pop    %ebx
f010087c:	5e                   	pop    %esi
f010087d:	5f                   	pop    %edi
f010087e:	5d                   	pop    %ebp
f010087f:	c3                   	ret    

f0100880 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100880:	55                   	push   %ebp
f0100881:	89 e5                	mov    %esp,%ebp
f0100883:	57                   	push   %edi
f0100884:	56                   	push   %esi
f0100885:	53                   	push   %ebx
f0100886:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100889:	c7 04 24 44 57 10 f0 	movl   $0xf0105744,(%esp)
f0100890:	e8 89 2e 00 00       	call   f010371e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100895:	c7 04 24 68 57 10 f0 	movl   $0xf0105768,(%esp)
f010089c:	e8 7d 2e 00 00       	call   f010371e <cprintf>

	if (tf != NULL)
f01008a1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01008a5:	74 0b                	je     f01008b2 <monitor+0x32>
		print_trapframe(tf);
f01008a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01008aa:	89 04 24             	mov    %eax,(%esp)
f01008ad:	e8 cd 32 00 00       	call   f0103b7f <print_trapframe>

	while (1) {
		buf = readline("K> ");
f01008b2:	c7 04 24 d3 55 10 f0 	movl   $0xf01055d3,(%esp)
f01008b9:	e8 12 42 00 00       	call   f0104ad0 <readline>
f01008be:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01008c0:	85 c0                	test   %eax,%eax
f01008c2:	74 ee                	je     f01008b2 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008c4:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008cb:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008d0:	eb 06                	jmp    f01008d8 <monitor+0x58>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008d2:	c6 06 00             	movb   $0x0,(%esi)
f01008d5:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008d8:	0f b6 06             	movzbl (%esi),%eax
f01008db:	84 c0                	test   %al,%al
f01008dd:	74 6c                	je     f010094b <monitor+0xcb>
f01008df:	0f be c0             	movsbl %al,%eax
f01008e2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e6:	c7 04 24 d7 55 10 f0 	movl   $0xf01055d7,(%esp)
f01008ed:	e8 53 44 00 00       	call   f0104d45 <strchr>
f01008f2:	85 c0                	test   %eax,%eax
f01008f4:	75 dc                	jne    f01008d2 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f01008f6:	80 3e 00             	cmpb   $0x0,(%esi)
f01008f9:	74 50                	je     f010094b <monitor+0xcb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008fb:	83 fb 0f             	cmp    $0xf,%ebx
f01008fe:	66 90                	xchg   %ax,%ax
f0100900:	75 16                	jne    f0100918 <monitor+0x98>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100902:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100909:	00 
f010090a:	c7 04 24 dc 55 10 f0 	movl   $0xf01055dc,(%esp)
f0100911:	e8 08 2e 00 00       	call   f010371e <cprintf>
f0100916:	eb 9a                	jmp    f01008b2 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100918:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f010091c:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f010091f:	0f b6 06             	movzbl (%esi),%eax
f0100922:	84 c0                	test   %al,%al
f0100924:	75 0c                	jne    f0100932 <monitor+0xb2>
f0100926:	eb b0                	jmp    f01008d8 <monitor+0x58>
			buf++;
f0100928:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010092b:	0f b6 06             	movzbl (%esi),%eax
f010092e:	84 c0                	test   %al,%al
f0100930:	74 a6                	je     f01008d8 <monitor+0x58>
f0100932:	0f be c0             	movsbl %al,%eax
f0100935:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100939:	c7 04 24 d7 55 10 f0 	movl   $0xf01055d7,(%esp)
f0100940:	e8 00 44 00 00       	call   f0104d45 <strchr>
f0100945:	85 c0                	test   %eax,%eax
f0100947:	74 df                	je     f0100928 <monitor+0xa8>
f0100949:	eb 8d                	jmp    f01008d8 <monitor+0x58>
			buf++;
	}
	argv[argc] = 0;
f010094b:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100952:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100953:	85 db                	test   %ebx,%ebx
f0100955:	0f 84 57 ff ff ff    	je     f01008b2 <monitor+0x32>
f010095b:	bf c0 57 10 f0       	mov    $0xf01057c0,%edi
f0100960:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100965:	8b 07                	mov    (%edi),%eax
f0100967:	89 44 24 04          	mov    %eax,0x4(%esp)
f010096b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010096e:	89 04 24             	mov    %eax,(%esp)
f0100971:	e8 4b 43 00 00       	call   f0104cc1 <strcmp>
f0100976:	85 c0                	test   %eax,%eax
f0100978:	75 24                	jne    f010099e <monitor+0x11e>
			return commands[i].func(argc, argv, tf);
f010097a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010097d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100980:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100984:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100987:	89 54 24 04          	mov    %edx,0x4(%esp)
f010098b:	89 1c 24             	mov    %ebx,(%esp)
f010098e:	ff 14 85 c8 57 10 f0 	call   *-0xfefa838(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100995:	85 c0                	test   %eax,%eax
f0100997:	78 28                	js     f01009c1 <monitor+0x141>
f0100999:	e9 14 ff ff ff       	jmp    f01008b2 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010099e:	83 c6 01             	add    $0x1,%esi
f01009a1:	83 c7 0c             	add    $0xc,%edi
f01009a4:	83 fe 05             	cmp    $0x5,%esi
f01009a7:	75 bc                	jne    f0100965 <monitor+0xe5>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009a9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009ac:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b0:	c7 04 24 f9 55 10 f0 	movl   $0xf01055f9,(%esp)
f01009b7:	e8 62 2d 00 00       	call   f010371e <cprintf>
f01009bc:	e9 f1 fe ff ff       	jmp    f01008b2 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009c1:	83 c4 5c             	add    $0x5c,%esp
f01009c4:	5b                   	pop    %ebx
f01009c5:	5e                   	pop    %esi
f01009c6:	5f                   	pop    %edi
f01009c7:	5d                   	pop    %ebp
f01009c8:	c3                   	ret    

f01009c9 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01009c9:	55                   	push   %ebp
f01009ca:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01009cc:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01009cf:	5d                   	pop    %ebp
f01009d0:	c3                   	ret    
f01009d1:	66 90                	xchg   %ax,%ax
f01009d3:	66 90                	xchg   %ax,%ax
f01009d5:	66 90                	xchg   %ax,%ax
f01009d7:	66 90                	xchg   %ax,%ax
f01009d9:	66 90                	xchg   %ax,%ax
f01009db:	66 90                	xchg   %ax,%ax
f01009dd:	66 90                	xchg   %ax,%ax
f01009df:	90                   	nop

f01009e0 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009e0:	89 d1                	mov    %edx,%ecx
f01009e2:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009e5:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009e8:	a8 01                	test   $0x1,%al
f01009ea:	74 5d                	je     f0100a49 <check_va2pa+0x69>
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009ec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009f1:	89 c1                	mov    %eax,%ecx
f01009f3:	c1 e9 0c             	shr    $0xc,%ecx
f01009f6:	3b 0d a4 ef 17 f0    	cmp    0xf017efa4,%ecx
f01009fc:	72 26                	jb     f0100a24 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009fe:	55                   	push   %ebp
f01009ff:	89 e5                	mov    %esp,%ebp
f0100a01:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a04:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a08:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0100a0f:	f0 
f0100a10:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0100a17:	00 
f0100a18:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100a1f:	e8 9a f6 ff ff       	call   f01000be <_panic>
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a24:	c1 ea 0c             	shr    $0xc,%edx
f0100a27:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a2d:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a34:	89 c2                	mov    %eax,%edx
f0100a36:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a39:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a3e:	85 d2                	test   %edx,%edx
f0100a40:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a45:	0f 44 c2             	cmove  %edx,%eax
f0100a48:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a49:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a4e:	c3                   	ret    

f0100a4f <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a4f:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a51:	83 3d fc e2 17 f0 00 	cmpl   $0x0,0xf017e2fc
f0100a58:	75 0f                	jne    f0100a69 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a5a:	b8 af ff 17 f0       	mov    $0xf017ffaf,%eax
f0100a5f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a64:	a3 fc e2 17 f0       	mov    %eax,0xf017e2fc
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f0100a69:	85 d2                	test   %edx,%edx
f0100a6b:	75 06                	jne    f0100a73 <boot_alloc+0x24>
		return nextfree;
f0100a6d:	a1 fc e2 17 f0       	mov    0xf017e2fc,%eax
f0100a72:	c3                   	ret    
	result = nextfree;
f0100a73:	a1 fc e2 17 f0       	mov    0xf017e2fc,%eax
	nextfree += (n/PGSIZE + 1)*PGSIZE;
f0100a78:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a7e:	8d 94 10 00 10 00 00 	lea    0x1000(%eax,%edx,1),%edx
f0100a85:	89 15 fc e2 17 f0    	mov    %edx,0xf017e2fc
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
f0100a8b:	8b 0d a4 ef 17 f0    	mov    0xf017efa4,%ecx
f0100a91:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f0100a97:	c1 e1 0c             	shl    $0xc,%ecx
f0100a9a:	39 ca                	cmp    %ecx,%edx
f0100a9c:	72 22                	jb     f0100ac0 <boot_alloc+0x71>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a9e:	55                   	push   %ebp
f0100a9f:	89 e5                	mov    %esp,%ebp
f0100aa1:	83 ec 18             	sub    $0x18,%esp
	if(n == 0)
		return nextfree;
	result = nextfree;
	nextfree += (n/PGSIZE + 1)*PGSIZE;
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
		panic("Run out of memory!!\n");
f0100aa4:	c7 44 24 08 59 5f 10 	movl   $0xf0105f59,0x8(%esp)
f0100aab:	f0 
f0100aac:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
f0100ab3:	00 
f0100ab4:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100abb:	e8 fe f5 ff ff       	call   f01000be <_panic>
	return result;
}
f0100ac0:	f3 c3                	repz ret 

f0100ac2 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ac2:	55                   	push   %ebp
f0100ac3:	89 e5                	mov    %esp,%ebp
f0100ac5:	83 ec 18             	sub    $0x18,%esp
f0100ac8:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100acb:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100ace:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ad0:	89 04 24             	mov    %eax,(%esp)
f0100ad3:	e8 d4 2b 00 00       	call   f01036ac <mc146818_read>
f0100ad8:	89 c6                	mov    %eax,%esi
f0100ada:	83 c3 01             	add    $0x1,%ebx
f0100add:	89 1c 24             	mov    %ebx,(%esp)
f0100ae0:	e8 c7 2b 00 00       	call   f01036ac <mc146818_read>
f0100ae5:	c1 e0 08             	shl    $0x8,%eax
f0100ae8:	09 f0                	or     %esi,%eax
}
f0100aea:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100aed:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100af0:	89 ec                	mov    %ebp,%esp
f0100af2:	5d                   	pop    %ebp
f0100af3:	c3                   	ret    

f0100af4 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100af4:	55                   	push   %ebp
f0100af5:	89 e5                	mov    %esp,%ebp
f0100af7:	57                   	push   %edi
f0100af8:	56                   	push   %esi
f0100af9:	53                   	push   %ebx
f0100afa:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100afd:	85 c0                	test   %eax,%eax
f0100aff:	0f 85 39 03 00 00    	jne    f0100e3e <check_page_free_list+0x34a>
f0100b05:	e9 46 03 00 00       	jmp    f0100e50 <check_page_free_list+0x35c>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b0a:	c7 44 24 08 20 58 10 	movl   $0xf0105820,0x8(%esp)
f0100b11:	f0 
f0100b12:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0100b19:	00 
f0100b1a:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100b21:	e8 98 f5 ff ff       	call   f01000be <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100b26:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b29:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b2c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b2f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b32:	89 c2                	mov    %eax,%edx
f0100b34:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b3a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b40:	0f 95 c2             	setne  %dl
f0100b43:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b46:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b4a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b4c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b50:	8b 00                	mov    (%eax),%eax
f0100b52:	85 c0                	test   %eax,%eax
f0100b54:	75 dc                	jne    f0100b32 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b59:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b5f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b62:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b65:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b67:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b6a:	a3 00 e3 17 f0       	mov    %eax,0xf017e300
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b6f:	89 c3                	mov    %eax,%ebx
f0100b71:	85 c0                	test   %eax,%eax
f0100b73:	74 6c                	je     f0100be1 <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b75:	be 01 00 00 00       	mov    $0x1,%esi
f0100b7a:	89 d8                	mov    %ebx,%eax
f0100b7c:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f0100b82:	c1 f8 03             	sar    $0x3,%eax
f0100b85:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b88:	89 c2                	mov    %eax,%edx
f0100b8a:	c1 ea 16             	shr    $0x16,%edx
f0100b8d:	39 f2                	cmp    %esi,%edx
f0100b8f:	73 4a                	jae    f0100bdb <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b91:	89 c2                	mov    %eax,%edx
f0100b93:	c1 ea 0c             	shr    $0xc,%edx
f0100b96:	3b 15 a4 ef 17 f0    	cmp    0xf017efa4,%edx
f0100b9c:	72 20                	jb     f0100bbe <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b9e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ba2:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0100ba9:	f0 
f0100baa:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100bb1:	00 
f0100bb2:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f0100bb9:	e8 00 f5 ff ff       	call   f01000be <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bbe:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100bc5:	00 
f0100bc6:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100bcd:	00 
	return (void *)(pa + KERNBASE);
f0100bce:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bd3:	89 04 24             	mov    %eax,(%esp)
f0100bd6:	e8 ca 41 00 00       	call   f0104da5 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bdb:	8b 1b                	mov    (%ebx),%ebx
f0100bdd:	85 db                	test   %ebx,%ebx
f0100bdf:	75 99                	jne    f0100b7a <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100be1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be6:	e8 64 fe ff ff       	call   f0100a4f <boot_alloc>
f0100beb:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bee:	8b 15 00 e3 17 f0    	mov    0xf017e300,%edx
f0100bf4:	85 d2                	test   %edx,%edx
f0100bf6:	0f 84 f6 01 00 00    	je     f0100df2 <check_page_free_list+0x2fe>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bfc:	8b 1d ac ef 17 f0    	mov    0xf017efac,%ebx
f0100c02:	39 da                	cmp    %ebx,%edx
f0100c04:	72 4d                	jb     f0100c53 <check_page_free_list+0x15f>
		assert(pp < pages + npages);
f0100c06:	a1 a4 ef 17 f0       	mov    0xf017efa4,%eax
f0100c0b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c0e:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100c11:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c14:	39 c2                	cmp    %eax,%edx
f0100c16:	73 64                	jae    f0100c7c <check_page_free_list+0x188>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c18:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100c1b:	89 d0                	mov    %edx,%eax
f0100c1d:	29 d8                	sub    %ebx,%eax
f0100c1f:	a8 07                	test   $0x7,%al
f0100c21:	0f 85 82 00 00 00    	jne    f0100ca9 <check_page_free_list+0x1b5>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c27:	c1 f8 03             	sar    $0x3,%eax
f0100c2a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c2d:	85 c0                	test   %eax,%eax
f0100c2f:	0f 84 a2 00 00 00    	je     f0100cd7 <check_page_free_list+0x1e3>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c35:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c3a:	0f 84 c2 00 00 00    	je     f0100d02 <check_page_free_list+0x20e>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c40:	be 00 00 00 00       	mov    $0x0,%esi
f0100c45:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c4a:	e9 d7 00 00 00       	jmp    f0100d26 <check_page_free_list+0x232>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c4f:	39 da                	cmp    %ebx,%edx
f0100c51:	73 24                	jae    f0100c77 <check_page_free_list+0x183>
f0100c53:	c7 44 24 0c 7c 5f 10 	movl   $0xf0105f7c,0xc(%esp)
f0100c5a:	f0 
f0100c5b:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100c62:	f0 
f0100c63:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f0100c6a:	00 
f0100c6b:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100c72:	e8 47 f4 ff ff       	call   f01000be <_panic>
		assert(pp < pages + npages);
f0100c77:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c7a:	72 24                	jb     f0100ca0 <check_page_free_list+0x1ac>
f0100c7c:	c7 44 24 0c 9d 5f 10 	movl   $0xf0105f9d,0xc(%esp)
f0100c83:	f0 
f0100c84:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100c8b:	f0 
f0100c8c:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0100c93:	00 
f0100c94:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100c9b:	e8 1e f4 ff ff       	call   f01000be <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ca0:	89 d0                	mov    %edx,%eax
f0100ca2:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100ca5:	a8 07                	test   $0x7,%al
f0100ca7:	74 24                	je     f0100ccd <check_page_free_list+0x1d9>
f0100ca9:	c7 44 24 0c 44 58 10 	movl   $0xf0105844,0xc(%esp)
f0100cb0:	f0 
f0100cb1:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100cb8:	f0 
f0100cb9:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0100cc0:	00 
f0100cc1:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100cc8:	e8 f1 f3 ff ff       	call   f01000be <_panic>
f0100ccd:	c1 f8 03             	sar    $0x3,%eax
f0100cd0:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100cd3:	85 c0                	test   %eax,%eax
f0100cd5:	75 24                	jne    f0100cfb <check_page_free_list+0x207>
f0100cd7:	c7 44 24 0c b1 5f 10 	movl   $0xf0105fb1,0xc(%esp)
f0100cde:	f0 
f0100cdf:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100ce6:	f0 
f0100ce7:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f0100cee:	00 
f0100cef:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100cf6:	e8 c3 f3 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cfb:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d00:	75 24                	jne    f0100d26 <check_page_free_list+0x232>
f0100d02:	c7 44 24 0c c2 5f 10 	movl   $0xf0105fc2,0xc(%esp)
f0100d09:	f0 
f0100d0a:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100d11:	f0 
f0100d12:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0100d19:	00 
f0100d1a:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100d21:	e8 98 f3 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d26:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d2b:	75 24                	jne    f0100d51 <check_page_free_list+0x25d>
f0100d2d:	c7 44 24 0c 78 58 10 	movl   $0xf0105878,0xc(%esp)
f0100d34:	f0 
f0100d35:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100d3c:	f0 
f0100d3d:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f0100d44:	00 
f0100d45:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100d4c:	e8 6d f3 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d51:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d56:	75 24                	jne    f0100d7c <check_page_free_list+0x288>
f0100d58:	c7 44 24 0c db 5f 10 	movl   $0xf0105fdb,0xc(%esp)
f0100d5f:	f0 
f0100d60:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100d67:	f0 
f0100d68:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0100d6f:	00 
f0100d70:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100d77:	e8 42 f3 ff ff       	call   f01000be <_panic>
f0100d7c:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d7e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d83:	76 57                	jbe    f0100ddc <check_page_free_list+0x2e8>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d85:	c1 e8 0c             	shr    $0xc,%eax
f0100d88:	3b 45 cc             	cmp    -0x34(%ebp),%eax
f0100d8b:	72 20                	jb     f0100dad <check_page_free_list+0x2b9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d8d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d91:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0100d98:	f0 
f0100d99:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100da0:	00 
f0100da1:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f0100da8:	e8 11 f3 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0100dad:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100db3:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100db6:	76 29                	jbe    f0100de1 <check_page_free_list+0x2ed>
f0100db8:	c7 44 24 0c 9c 58 10 	movl   $0xf010589c,0xc(%esp)
f0100dbf:	f0 
f0100dc0:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100dc7:	f0 
f0100dc8:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f0100dcf:	00 
f0100dd0:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100dd7:	e8 e2 f2 ff ff       	call   f01000be <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100ddc:	83 c7 01             	add    $0x1,%edi
f0100ddf:	eb 03                	jmp    f0100de4 <check_page_free_list+0x2f0>
		else
			++nfree_extmem;
f0100de1:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100de4:	8b 12                	mov    (%edx),%edx
f0100de6:	85 d2                	test   %edx,%edx
f0100de8:	0f 85 61 fe ff ff    	jne    f0100c4f <check_page_free_list+0x15b>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100dee:	85 ff                	test   %edi,%edi
f0100df0:	7f 24                	jg     f0100e16 <check_page_free_list+0x322>
f0100df2:	c7 44 24 0c f5 5f 10 	movl   $0xf0105ff5,0xc(%esp)
f0100df9:	f0 
f0100dfa:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100e01:	f0 
f0100e02:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f0100e09:	00 
f0100e0a:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100e11:	e8 a8 f2 ff ff       	call   f01000be <_panic>
	assert(nfree_extmem > 0);
f0100e16:	85 f6                	test   %esi,%esi
f0100e18:	7f 53                	jg     f0100e6d <check_page_free_list+0x379>
f0100e1a:	c7 44 24 0c 07 60 10 	movl   $0xf0106007,0xc(%esp)
f0100e21:	f0 
f0100e22:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0100e29:	f0 
f0100e2a:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f0100e31:	00 
f0100e32:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100e39:	e8 80 f2 ff ff       	call   f01000be <_panic>
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e3e:	a1 00 e3 17 f0       	mov    0xf017e300,%eax
f0100e43:	85 c0                	test   %eax,%eax
f0100e45:	0f 85 db fc ff ff    	jne    f0100b26 <check_page_free_list+0x32>
f0100e4b:	e9 ba fc ff ff       	jmp    f0100b0a <check_page_free_list+0x16>
f0100e50:	83 3d 00 e3 17 f0 00 	cmpl   $0x0,0xf017e300
f0100e57:	0f 84 ad fc ff ff    	je     f0100b0a <check_page_free_list+0x16>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e5d:	8b 1d 00 e3 17 f0    	mov    0xf017e300,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e63:	be 00 04 00 00       	mov    $0x400,%esi
f0100e68:	e9 0d fd ff ff       	jmp    f0100b7a <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100e6d:	83 c4 3c             	add    $0x3c,%esp
f0100e70:	5b                   	pop    %ebx
f0100e71:	5e                   	pop    %esi
f0100e72:	5f                   	pop    %edi
f0100e73:	5d                   	pop    %ebp
f0100e74:	c3                   	ret    

f0100e75 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e75:	55                   	push   %ebp
f0100e76:	89 e5                	mov    %esp,%ebp
f0100e78:	56                   	push   %esi
f0100e79:	53                   	push   %ebx
f0100e7a:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
f0100e7d:	a1 ac ef 17 f0       	mov    0xf017efac,%eax
f0100e82:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100e88:	8b 35 f8 e2 17 f0    	mov    0xf017e2f8,%esi
f0100e8e:	83 fe 01             	cmp    $0x1,%esi
f0100e91:	76 37                	jbe    f0100eca <page_init+0x55>
f0100e93:	8b 1d 00 e3 17 f0    	mov    0xf017e300,%ebx
f0100e99:	b8 01 00 00 00       	mov    $0x1,%eax
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
f0100e9e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
		pages[i].pp_ref = 0;
f0100ea5:	8b 0d ac ef 17 f0    	mov    0xf017efac,%ecx
f0100eab:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100eb2:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0100eb5:	8b 1d ac ef 17 f0    	mov    0xf017efac,%ebx
f0100ebb:	01 d3                	add    %edx,%ebx
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100ebd:	83 c0 01             	add    $0x1,%eax
f0100ec0:	39 f0                	cmp    %esi,%eax
f0100ec2:	72 da                	jb     f0100e9e <page_init+0x29>
f0100ec4:	89 1d 00 e3 17 f0    	mov    %ebx,0xf017e300
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	size_t page_num = PADDR(boot_alloc(0)) / PGSIZE;
f0100eca:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ecf:	e8 7b fb ff ff       	call   f0100a4f <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ed4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ed9:	77 20                	ja     f0100efb <page_init+0x86>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100edb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100edf:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f0100ee6:	f0 
f0100ee7:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
f0100eee:	00 
f0100eef:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0100ef6:	e8 c3 f1 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100efb:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f00:	c1 e8 0c             	shr    $0xc,%eax
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100f03:	3b 05 a4 ef 17 f0    	cmp    0xf017efa4,%eax
f0100f09:	73 39                	jae    f0100f44 <page_init+0xcf>
f0100f0b:	8b 1d 00 e3 17 f0    	mov    0xf017e300,%ebx
f0100f11:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100f18:	8b 0d ac ef 17 f0    	mov    0xf017efac,%ecx
f0100f1e:	01 d1                	add    %edx,%ecx
f0100f20:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100f26:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100f28:	8b 1d ac ef 17 f0    	mov    0xf017efac,%ebx
f0100f2e:	01 d3                	add    %edx,%ebx
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100f30:	83 c0 01             	add    $0x1,%eax
f0100f33:	83 c2 08             	add    $0x8,%edx
f0100f36:	39 05 a4 ef 17 f0    	cmp    %eax,0xf017efa4
f0100f3c:	77 da                	ja     f0100f18 <page_init+0xa3>
f0100f3e:	89 1d 00 e3 17 f0    	mov    %ebx,0xf017e300
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
//	panic("here");
	
}
f0100f44:	83 c4 10             	add    $0x10,%esp
f0100f47:	5b                   	pop    %ebx
f0100f48:	5e                   	pop    %esi
f0100f49:	5d                   	pop    %ebp
f0100f4a:	c3                   	ret    

f0100f4b <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100f4b:	55                   	push   %ebp
f0100f4c:	89 e5                	mov    %esp,%ebp
f0100f4e:	53                   	push   %ebx
f0100f4f:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(!page_free_list)
f0100f52:	8b 1d 00 e3 17 f0    	mov    0xf017e300,%ebx
f0100f58:	85 db                	test   %ebx,%ebx
f0100f5a:	74 6b                	je     f0100fc7 <page_alloc+0x7c>
		return NULL;
	struct Page *alloc_page = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100f5c:	8b 03                	mov    (%ebx),%eax
f0100f5e:	a3 00 e3 17 f0       	mov    %eax,0xf017e300
	alloc_page -> pp_link = NULL;
f0100f63:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100f69:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f6d:	74 58                	je     f0100fc7 <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f6f:	89 d8                	mov    %ebx,%eax
f0100f71:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f0100f77:	c1 f8 03             	sar    $0x3,%eax
f0100f7a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f7d:	89 c2                	mov    %eax,%edx
f0100f7f:	c1 ea 0c             	shr    $0xc,%edx
f0100f82:	3b 15 a4 ef 17 f0    	cmp    0xf017efa4,%edx
f0100f88:	72 20                	jb     f0100faa <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f8a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f8e:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0100f95:	f0 
f0100f96:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f9d:	00 
f0100f9e:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f0100fa5:	e8 14 f1 ff ff       	call   f01000be <_panic>
		memset(page2kva(alloc_page), 0, PGSIZE);
f0100faa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100fb1:	00 
f0100fb2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100fb9:	00 
	return (void *)(pa + KERNBASE);
f0100fba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fbf:	89 04 24             	mov    %eax,(%esp)
f0100fc2:	e8 de 3d 00 00       	call   f0104da5 <memset>
	
	return alloc_page;
}
f0100fc7:	89 d8                	mov    %ebx,%eax
f0100fc9:	83 c4 14             	add    $0x14,%esp
f0100fcc:	5b                   	pop    %ebx
f0100fcd:	5d                   	pop    %ebp
f0100fce:	c3                   	ret    

f0100fcf <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100fcf:	55                   	push   %ebp
f0100fd0:	89 e5                	mov    %esp,%ebp
f0100fd2:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if(pp -> pp_ref)	// If the ref is not 0, return
f0100fd5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100fda:	75 0d                	jne    f0100fe9 <page_free+0x1a>
		return;
	pp->pp_link = page_free_list;
f0100fdc:	8b 15 00 e3 17 f0    	mov    0xf017e300,%edx
f0100fe2:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100fe4:	a3 00 e3 17 f0       	mov    %eax,0xf017e300
}
f0100fe9:	5d                   	pop    %ebp
f0100fea:	c3                   	ret    

f0100feb <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100feb:	55                   	push   %ebp
f0100fec:	89 e5                	mov    %esp,%ebp
f0100fee:	83 ec 04             	sub    $0x4,%esp
f0100ff1:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100ff4:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100ff8:	83 ea 01             	sub    $0x1,%edx
f0100ffb:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100fff:	66 85 d2             	test   %dx,%dx
f0101002:	75 08                	jne    f010100c <page_decref+0x21>
		page_free(pp);
f0101004:	89 04 24             	mov    %eax,(%esp)
f0101007:	e8 c3 ff ff ff       	call   f0100fcf <page_free>
}
f010100c:	c9                   	leave  
f010100d:	c3                   	ret    

f010100e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{/* see the check_va2pa() */
f010100e:	55                   	push   %ebp
f010100f:	89 e5                	mov    %esp,%ebp
f0101011:	56                   	push   %esi
f0101012:	53                   	push   %ebx
f0101013:	83 ec 10             	sub    $0x10,%esp
f0101016:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/* va is a linear address */
	pde_t *ptdir = pgdir + PDX(va);
f0101019:	89 de                	mov    %ebx,%esi
f010101b:	c1 ee 16             	shr    $0x16,%esi
f010101e:	c1 e6 02             	shl    $0x2,%esi
f0101021:	03 75 08             	add    0x8(%ebp),%esi
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
f0101024:	8b 06                	mov    (%esi),%eax
f0101026:	a8 01                	test   $0x1,%al
f0101028:	74 44                	je     f010106e <pgdir_walk+0x60>
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f010102a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010102f:	89 c2                	mov    %eax,%edx
f0101031:	c1 ea 0c             	shr    $0xc,%edx
f0101034:	3b 15 a4 ef 17 f0    	cmp    0xf017efa4,%edx
f010103a:	72 20                	jb     f010105c <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010103c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101040:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0101047:	f0 
f0101048:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
f010104f:	00 
f0101050:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101057:	e8 62 f0 ff ff       	call   f01000be <_panic>
f010105c:	c1 eb 0a             	shr    $0xa,%ebx
f010105f:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101065:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f010106c:	eb 7c                	jmp    f01010ea <pgdir_walk+0xdc>
	if(!create)
f010106e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101072:	74 6a                	je     f01010de <pgdir_walk+0xd0>
		return NULL;
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
f0101074:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010107b:	e8 cb fe ff ff       	call   f0100f4b <page_alloc>
	if(!page_create)
f0101080:	85 c0                	test   %eax,%eax
f0101082:	74 61                	je     f01010e5 <pgdir_walk+0xd7>
		return NULL; /* allocation fails */
	page_create -> pp_ref++; /* reference count increase */
f0101084:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101089:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f010108f:	c1 f8 03             	sar    $0x3,%eax
f0101092:	c1 e0 0c             	shl    $0xc,%eax
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
f0101095:	83 c8 07             	or     $0x7,%eax
f0101098:	89 06                	mov    %eax,(%esi)
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f010109a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010109f:	89 c2                	mov    %eax,%edx
f01010a1:	c1 ea 0c             	shr    $0xc,%edx
f01010a4:	3b 15 a4 ef 17 f0    	cmp    0xf017efa4,%edx
f01010aa:	72 20                	jb     f01010cc <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010b0:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f01010b7:	f0 
f01010b8:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f01010bf:	00 
f01010c0:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01010c7:	e8 f2 ef ff ff       	call   f01000be <_panic>
f01010cc:	c1 eb 0a             	shr    $0xa,%ebx
f01010cf:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f01010d5:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f01010dc:	eb 0c                	jmp    f01010ea <pgdir_walk+0xdc>
	pde_t *ptdir = pgdir + PDX(va);
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
	if(!create)
		return NULL;
f01010de:	b8 00 00 00 00       	mov    $0x0,%eax
f01010e3:	eb 05                	jmp    f01010ea <pgdir_walk+0xdc>
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
	if(!page_create)
		return NULL; /* allocation fails */
f01010e5:	b8 00 00 00 00       	mov    $0x0,%eax
	page_create -> pp_ref++; /* reference count increase */
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
}
f01010ea:	83 c4 10             	add    $0x10,%esp
f01010ed:	5b                   	pop    %ebx
f01010ee:	5e                   	pop    %esi
f01010ef:	5d                   	pop    %ebp
f01010f0:	c3                   	ret    

f01010f1 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010f1:	55                   	push   %ebp
f01010f2:	89 e5                	mov    %esp,%ebp
f01010f4:	57                   	push   %edi
f01010f5:	56                   	push   %esi
f01010f6:	53                   	push   %ebx
f01010f7:	83 ec 2c             	sub    $0x2c,%esp
f01010fa:	89 4d e0             	mov    %ecx,-0x20(%ebp)
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f01010fd:	85 c9                	test   %ecx,%ecx
f01010ff:	74 43                	je     f0101144 <boot_map_region+0x53>
f0101101:	89 c6                	mov    %eax,%esi
f0101103:	89 d3                	mov    %edx,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101105:	8b 45 08             	mov    0x8(%ebp),%eax
f0101108:	29 d0                	sub    %edx,%eax
f010110a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010110d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101110:	89 f7                	mov    %esi,%edi
f0101112:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101115:	01 de                	add    %ebx,%esi
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
		pte_t *pte = pgdir_walk(pgdir, (const void *)va, 1);
f0101117:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010111e:	00 
f010111f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101123:	89 3c 24             	mov    %edi,(%esp)
f0101126:	e8 e3 fe ff ff       	call   f010100e <pgdir_walk>
		if(!pte)
f010112b:	85 c0                	test   %eax,%eax
f010112d:	74 15                	je     f0101144 <boot_map_region+0x53>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm;
f010112f:	0b 75 0c             	or     0xc(%ebp),%esi
f0101132:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f0101134:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010113a:	89 d8                	mov    %ebx,%eax
f010113c:	2b 45 dc             	sub    -0x24(%ebp),%eax
f010113f:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0101142:	72 ce                	jb     f0101112 <boot_map_region+0x21>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm;
	}
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~\n");
}
f0101144:	83 c4 2c             	add    $0x2c,%esp
f0101147:	5b                   	pop    %ebx
f0101148:	5e                   	pop    %esi
f0101149:	5f                   	pop    %edi
f010114a:	5d                   	pop    %ebp
f010114b:	c3                   	ret    

f010114c <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010114c:	55                   	push   %ebp
f010114d:	89 e5                	mov    %esp,%ebp
f010114f:	53                   	push   %ebx
f0101150:	83 ec 14             	sub    $0x14,%esp
f0101153:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101156:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010115d:	00 
f010115e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101161:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101165:	8b 45 08             	mov    0x8(%ebp),%eax
f0101168:	89 04 24             	mov    %eax,(%esp)
f010116b:	e8 9e fe ff ff       	call   f010100e <pgdir_walk>
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
f0101170:	85 c0                	test   %eax,%eax
f0101172:	74 3f                	je     f01011b3 <page_lookup+0x67>
f0101174:	f6 00 01             	testb  $0x1,(%eax)
f0101177:	74 41                	je     f01011ba <page_lookup+0x6e>
		return NULL;
	if(pte_store)
f0101179:	85 db                	test   %ebx,%ebx
f010117b:	74 02                	je     f010117f <page_lookup+0x33>
		*pte_store = pte;
f010117d:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f010117f:	8b 00                	mov    (%eax),%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101181:	c1 e8 0c             	shr    $0xc,%eax
f0101184:	3b 05 a4 ef 17 f0    	cmp    0xf017efa4,%eax
f010118a:	72 1c                	jb     f01011a8 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f010118c:	c7 44 24 08 08 59 10 	movl   $0xf0105908,0x8(%esp)
f0101193:	f0 
f0101194:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010119b:	00 
f010119c:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f01011a3:	e8 16 ef ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f01011a8:	8b 15 ac ef 17 f0    	mov    0xf017efac,%edx
f01011ae:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01011b1:	eb 0c                	jmp    f01011bf <page_lookup+0x73>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
		return NULL;
f01011b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b8:	eb 05                	jmp    f01011bf <page_lookup+0x73>
f01011ba:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f01011bf:	83 c4 14             	add    $0x14,%esp
f01011c2:	5b                   	pop    %ebx
f01011c3:	5d                   	pop    %ebp
f01011c4:	c3                   	ret    

f01011c5 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01011c5:	55                   	push   %ebp
f01011c6:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011cb:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01011ce:	5d                   	pop    %ebp
f01011cf:	c3                   	ret    

f01011d0 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01011d0:	55                   	push   %ebp
f01011d1:	89 e5                	mov    %esp,%ebp
f01011d3:	83 ec 28             	sub    $0x28,%esp
f01011d6:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01011d9:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01011dc:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01011df:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct Page *pp = page_lookup(pgdir, va, &pte);
f01011e2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011e9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011ed:	89 1c 24             	mov    %ebx,(%esp)
f01011f0:	e8 57 ff ff ff       	call   f010114c <page_lookup>
	if(!pp)
f01011f5:	85 c0                	test   %eax,%eax
f01011f7:	74 1d                	je     f0101216 <page_remove+0x46>
		return;
	page_decref(pp);
f01011f9:	89 04 24             	mov    %eax,(%esp)
f01011fc:	e8 ea fd ff ff       	call   f0100feb <page_decref>
	*pte = 0;
f0101201:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101204:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f010120a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010120e:	89 1c 24             	mov    %ebx,(%esp)
f0101211:	e8 af ff ff ff       	call   f01011c5 <tlb_invalidate>
	
}
f0101216:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101219:	8b 75 fc             	mov    -0x4(%ebp),%esi
f010121c:	89 ec                	mov    %ebp,%esp
f010121e:	5d                   	pop    %ebp
f010121f:	c3                   	ret    

f0101220 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101220:	55                   	push   %ebp
f0101221:	89 e5                	mov    %esp,%ebp
f0101223:	83 ec 28             	sub    $0x28,%esp
f0101226:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101229:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010122c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010122f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101232:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101235:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010123c:	00 
f010123d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101241:	8b 45 08             	mov    0x8(%ebp),%eax
f0101244:	89 04 24             	mov    %eax,(%esp)
f0101247:	e8 c2 fd ff ff       	call   f010100e <pgdir_walk>
f010124c:	89 c6                	mov    %eax,%esi
	if(!pte)
f010124e:	85 c0                	test   %eax,%eax
f0101250:	74 66                	je     f01012b8 <page_insert+0x98>
		return -E_NO_MEM;
	if(*pte & PTE_P) { /* already a page */
f0101252:	8b 00                	mov    (%eax),%eax
f0101254:	a8 01                	test   $0x1,%al
f0101256:	74 3c                	je     f0101294 <page_insert+0x74>
		if(PTE_ADDR(*pte) == page2pa(pp)){	/* the same one */
f0101258:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010125d:	89 da                	mov    %ebx,%edx
f010125f:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
f0101265:	c1 fa 03             	sar    $0x3,%edx
f0101268:	c1 e2 0c             	shl    $0xc,%edx
f010126b:	39 d0                	cmp    %edx,%eax
f010126d:	75 16                	jne    f0101285 <page_insert+0x65>
			tlb_invalidate(pgdir, va);
f010126f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101273:	8b 45 08             	mov    0x8(%ebp),%eax
f0101276:	89 04 24             	mov    %eax,(%esp)
f0101279:	e8 47 ff ff ff       	call   f01011c5 <tlb_invalidate>
			pp -> pp_ref--;
f010127e:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f0101283:	eb 0f                	jmp    f0101294 <page_insert+0x74>
		}else
			page_remove(pgdir, va);
f0101285:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101289:	8b 45 08             	mov    0x8(%ebp),%eax
f010128c:	89 04 24             	mov    %eax,(%esp)
f010128f:	e8 3c ff ff ff       	call   f01011d0 <page_remove>
	}
	*pte = page2pa(pp)|perm|PTE_P;
f0101294:	8b 55 14             	mov    0x14(%ebp),%edx
f0101297:	83 ca 01             	or     $0x1,%edx
f010129a:	89 d8                	mov    %ebx,%eax
f010129c:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f01012a2:	c1 f8 03             	sar    $0x3,%eax
f01012a5:	c1 e0 0c             	shl    $0xc,%eax
f01012a8:	09 d0                	or     %edx,%eax
f01012aa:	89 06                	mov    %eax,(%esi)
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
f01012ac:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f01012b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01012b6:	eb 05                	jmp    f01012bd <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
	if(!pte)
		return -E_NO_MEM;
f01012b8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*pte = page2pa(pp)|perm|PTE_P;
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
	return 0;
}
f01012bd:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01012c0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01012c3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01012c6:	89 ec                	mov    %ebp,%esp
f01012c8:	5d                   	pop    %ebp
f01012c9:	c3                   	ret    

f01012ca <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01012ca:	55                   	push   %ebp
f01012cb:	89 e5                	mov    %esp,%ebp
f01012cd:	57                   	push   %edi
f01012ce:	56                   	push   %esi
f01012cf:	53                   	push   %ebx
f01012d0:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01012d3:	b8 15 00 00 00       	mov    $0x15,%eax
f01012d8:	e8 e5 f7 ff ff       	call   f0100ac2 <nvram_read>
f01012dd:	c1 e0 0a             	shl    $0xa,%eax
f01012e0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012e6:	85 c0                	test   %eax,%eax
f01012e8:	0f 48 c2             	cmovs  %edx,%eax
f01012eb:	c1 f8 0c             	sar    $0xc,%eax
f01012ee:	a3 f8 e2 17 f0       	mov    %eax,0xf017e2f8
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012f3:	b8 17 00 00 00       	mov    $0x17,%eax
f01012f8:	e8 c5 f7 ff ff       	call   f0100ac2 <nvram_read>
f01012fd:	c1 e0 0a             	shl    $0xa,%eax
f0101300:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101306:	85 c0                	test   %eax,%eax
f0101308:	0f 48 c2             	cmovs  %edx,%eax
f010130b:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010130e:	85 c0                	test   %eax,%eax
f0101310:	74 0e                	je     f0101320 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101312:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101318:	89 15 a4 ef 17 f0    	mov    %edx,0xf017efa4
f010131e:	eb 0c                	jmp    f010132c <mem_init+0x62>
	else
		npages = npages_basemem;
f0101320:	8b 15 f8 e2 17 f0    	mov    0xf017e2f8,%edx
f0101326:	89 15 a4 ef 17 f0    	mov    %edx,0xf017efa4

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010132c:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010132f:	c1 e8 0a             	shr    $0xa,%eax
f0101332:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101336:	a1 f8 e2 17 f0       	mov    0xf017e2f8,%eax
f010133b:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010133e:	c1 e8 0a             	shr    $0xa,%eax
f0101341:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101345:	a1 a4 ef 17 f0       	mov    0xf017efa4,%eax
f010134a:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010134d:	c1 e8 0a             	shr    $0xa,%eax
f0101350:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101354:	c7 04 24 28 59 10 f0 	movl   $0xf0105928,(%esp)
f010135b:	e8 be 23 00 00       	call   f010371e <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101360:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101365:	e8 e5 f6 ff ff       	call   f0100a4f <boot_alloc>
f010136a:	a3 a8 ef 17 f0       	mov    %eax,0xf017efa8
	memset(kern_pgdir, 0, PGSIZE);
f010136f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101376:	00 
f0101377:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010137e:	00 
f010137f:	89 04 24             	mov    %eax,(%esp)
f0101382:	e8 1e 3a 00 00       	call   f0104da5 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101387:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010138c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101391:	77 20                	ja     f01013b3 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101393:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101397:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f010139e:	f0 
f010139f:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
f01013a6:	00 
f01013a7:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01013ae:	e8 0b ed ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01013b3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013b9:	83 ca 05             	or     $0x5,%edx
f01013bc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page *)boot_alloc(npages * sizeof(struct Page));
f01013c2:	a1 a4 ef 17 f0       	mov    0xf017efa4,%eax
f01013c7:	c1 e0 03             	shl    $0x3,%eax
f01013ca:	e8 80 f6 ff ff       	call   f0100a4f <boot_alloc>
f01013cf:	a3 ac ef 17 f0       	mov    %eax,0xf017efac
		
//panic("PDX(0)");
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f01013d4:	b8 00 80 01 00       	mov    $0x18000,%eax
f01013d9:	e8 71 f6 ff ff       	call   f0100a4f <boot_alloc>
f01013de:	a3 0c e3 17 f0       	mov    %eax,0xf017e30c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01013e3:	e8 8d fa ff ff       	call   f0100e75 <page_init>

	check_page_free_list(1);
f01013e8:	b8 01 00 00 00       	mov    $0x1,%eax
f01013ed:	e8 02 f7 ff ff       	call   f0100af4 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01013f2:	83 3d ac ef 17 f0 00 	cmpl   $0x0,0xf017efac
f01013f9:	75 1c                	jne    f0101417 <mem_init+0x14d>
		panic("'pages' is a null pointer!");
f01013fb:	c7 44 24 08 18 60 10 	movl   $0xf0106018,0x8(%esp)
f0101402:	f0 
f0101403:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f010140a:	00 
f010140b:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101412:	e8 a7 ec ff ff       	call   f01000be <_panic>
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101417:	a1 00 e3 17 f0       	mov    0xf017e300,%eax
f010141c:	85 c0                	test   %eax,%eax
f010141e:	74 10                	je     f0101430 <mem_init+0x166>
f0101420:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f0101425:	83 c3 01             	add    $0x1,%ebx
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101428:	8b 00                	mov    (%eax),%eax
f010142a:	85 c0                	test   %eax,%eax
f010142c:	75 f7                	jne    f0101425 <mem_init+0x15b>
f010142e:	eb 05                	jmp    f0101435 <mem_init+0x16b>
f0101430:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101435:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010143c:	e8 0a fb ff ff       	call   f0100f4b <page_alloc>
f0101441:	89 c7                	mov    %eax,%edi
f0101443:	85 c0                	test   %eax,%eax
f0101445:	75 24                	jne    f010146b <mem_init+0x1a1>
f0101447:	c7 44 24 0c 33 60 10 	movl   $0xf0106033,0xc(%esp)
f010144e:	f0 
f010144f:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101456:	f0 
f0101457:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f010145e:	00 
f010145f:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101466:	e8 53 ec ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f010146b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101472:	e8 d4 fa ff ff       	call   f0100f4b <page_alloc>
f0101477:	89 c6                	mov    %eax,%esi
f0101479:	85 c0                	test   %eax,%eax
f010147b:	75 24                	jne    f01014a1 <mem_init+0x1d7>
f010147d:	c7 44 24 0c 49 60 10 	movl   $0xf0106049,0xc(%esp)
f0101484:	f0 
f0101485:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010148c:	f0 
f010148d:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f0101494:	00 
f0101495:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010149c:	e8 1d ec ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f01014a1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014a8:	e8 9e fa ff ff       	call   f0100f4b <page_alloc>
f01014ad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014b0:	85 c0                	test   %eax,%eax
f01014b2:	75 24                	jne    f01014d8 <mem_init+0x20e>
f01014b4:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f01014bb:	f0 
f01014bc:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01014c3:	f0 
f01014c4:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
f01014cb:	00 
f01014cc:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01014d3:	e8 e6 eb ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014d8:	39 f7                	cmp    %esi,%edi
f01014da:	75 24                	jne    f0101500 <mem_init+0x236>
f01014dc:	c7 44 24 0c 75 60 10 	movl   $0xf0106075,0xc(%esp)
f01014e3:	f0 
f01014e4:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01014eb:	f0 
f01014ec:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f01014f3:	00 
f01014f4:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01014fb:	e8 be eb ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101500:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101503:	74 05                	je     f010150a <mem_init+0x240>
f0101505:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101508:	75 24                	jne    f010152e <mem_init+0x264>
f010150a:	c7 44 24 0c 64 59 10 	movl   $0xf0105964,0xc(%esp)
f0101511:	f0 
f0101512:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101519:	f0 
f010151a:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
f0101521:	00 
f0101522:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101529:	e8 90 eb ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010152e:	8b 15 ac ef 17 f0    	mov    0xf017efac,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101534:	a1 a4 ef 17 f0       	mov    0xf017efa4,%eax
f0101539:	c1 e0 0c             	shl    $0xc,%eax
f010153c:	89 f9                	mov    %edi,%ecx
f010153e:	29 d1                	sub    %edx,%ecx
f0101540:	c1 f9 03             	sar    $0x3,%ecx
f0101543:	c1 e1 0c             	shl    $0xc,%ecx
f0101546:	39 c1                	cmp    %eax,%ecx
f0101548:	72 24                	jb     f010156e <mem_init+0x2a4>
f010154a:	c7 44 24 0c 87 60 10 	movl   $0xf0106087,0xc(%esp)
f0101551:	f0 
f0101552:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101559:	f0 
f010155a:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f0101561:	00 
f0101562:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101569:	e8 50 eb ff ff       	call   f01000be <_panic>
f010156e:	89 f1                	mov    %esi,%ecx
f0101570:	29 d1                	sub    %edx,%ecx
f0101572:	c1 f9 03             	sar    $0x3,%ecx
f0101575:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101578:	39 c8                	cmp    %ecx,%eax
f010157a:	77 24                	ja     f01015a0 <mem_init+0x2d6>
f010157c:	c7 44 24 0c a4 60 10 	movl   $0xf01060a4,0xc(%esp)
f0101583:	f0 
f0101584:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010158b:	f0 
f010158c:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f0101593:	00 
f0101594:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010159b:	e8 1e eb ff ff       	call   f01000be <_panic>
f01015a0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01015a3:	29 d1                	sub    %edx,%ecx
f01015a5:	89 ca                	mov    %ecx,%edx
f01015a7:	c1 fa 03             	sar    $0x3,%edx
f01015aa:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01015ad:	39 d0                	cmp    %edx,%eax
f01015af:	77 24                	ja     f01015d5 <mem_init+0x30b>
f01015b1:	c7 44 24 0c c1 60 10 	movl   $0xf01060c1,0xc(%esp)
f01015b8:	f0 
f01015b9:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01015c0:	f0 
f01015c1:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f01015c8:	00 
f01015c9:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01015d0:	e8 e9 ea ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015d5:	a1 00 e3 17 f0       	mov    0xf017e300,%eax
f01015da:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015dd:	c7 05 00 e3 17 f0 00 	movl   $0x0,0xf017e300
f01015e4:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ee:	e8 58 f9 ff ff       	call   f0100f4b <page_alloc>
f01015f3:	85 c0                	test   %eax,%eax
f01015f5:	74 24                	je     f010161b <mem_init+0x351>
f01015f7:	c7 44 24 0c de 60 10 	movl   $0xf01060de,0xc(%esp)
f01015fe:	f0 
f01015ff:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101606:	f0 
f0101607:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f010160e:	00 
f010160f:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101616:	e8 a3 ea ff ff       	call   f01000be <_panic>

	// free and re-allocate?
	page_free(pp0);
f010161b:	89 3c 24             	mov    %edi,(%esp)
f010161e:	e8 ac f9 ff ff       	call   f0100fcf <page_free>
	page_free(pp1);
f0101623:	89 34 24             	mov    %esi,(%esp)
f0101626:	e8 a4 f9 ff ff       	call   f0100fcf <page_free>
	page_free(pp2);
f010162b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010162e:	89 04 24             	mov    %eax,(%esp)
f0101631:	e8 99 f9 ff ff       	call   f0100fcf <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101636:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010163d:	e8 09 f9 ff ff       	call   f0100f4b <page_alloc>
f0101642:	89 c6                	mov    %eax,%esi
f0101644:	85 c0                	test   %eax,%eax
f0101646:	75 24                	jne    f010166c <mem_init+0x3a2>
f0101648:	c7 44 24 0c 33 60 10 	movl   $0xf0106033,0xc(%esp)
f010164f:	f0 
f0101650:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101657:	f0 
f0101658:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f010165f:	00 
f0101660:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101667:	e8 52 ea ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f010166c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101673:	e8 d3 f8 ff ff       	call   f0100f4b <page_alloc>
f0101678:	89 c7                	mov    %eax,%edi
f010167a:	85 c0                	test   %eax,%eax
f010167c:	75 24                	jne    f01016a2 <mem_init+0x3d8>
f010167e:	c7 44 24 0c 49 60 10 	movl   $0xf0106049,0xc(%esp)
f0101685:	f0 
f0101686:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010168d:	f0 
f010168e:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0101695:	00 
f0101696:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010169d:	e8 1c ea ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f01016a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016a9:	e8 9d f8 ff ff       	call   f0100f4b <page_alloc>
f01016ae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016b1:	85 c0                	test   %eax,%eax
f01016b3:	75 24                	jne    f01016d9 <mem_init+0x40f>
f01016b5:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f01016bc:	f0 
f01016bd:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01016c4:	f0 
f01016c5:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f01016cc:	00 
f01016cd:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01016d4:	e8 e5 e9 ff ff       	call   f01000be <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016d9:	39 fe                	cmp    %edi,%esi
f01016db:	75 24                	jne    f0101701 <mem_init+0x437>
f01016dd:	c7 44 24 0c 75 60 10 	movl   $0xf0106075,0xc(%esp)
f01016e4:	f0 
f01016e5:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01016ec:	f0 
f01016ed:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f01016f4:	00 
f01016f5:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01016fc:	e8 bd e9 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101701:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101704:	74 05                	je     f010170b <mem_init+0x441>
f0101706:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101709:	75 24                	jne    f010172f <mem_init+0x465>
f010170b:	c7 44 24 0c 64 59 10 	movl   $0xf0105964,0xc(%esp)
f0101712:	f0 
f0101713:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010171a:	f0 
f010171b:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f0101722:	00 
f0101723:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010172a:	e8 8f e9 ff ff       	call   f01000be <_panic>
	assert(!page_alloc(0));
f010172f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101736:	e8 10 f8 ff ff       	call   f0100f4b <page_alloc>
f010173b:	85 c0                	test   %eax,%eax
f010173d:	74 24                	je     f0101763 <mem_init+0x499>
f010173f:	c7 44 24 0c de 60 10 	movl   $0xf01060de,0xc(%esp)
f0101746:	f0 
f0101747:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010174e:	f0 
f010174f:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0101756:	00 
f0101757:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010175e:	e8 5b e9 ff ff       	call   f01000be <_panic>
f0101763:	89 f0                	mov    %esi,%eax
f0101765:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f010176b:	c1 f8 03             	sar    $0x3,%eax
f010176e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101771:	89 c2                	mov    %eax,%edx
f0101773:	c1 ea 0c             	shr    $0xc,%edx
f0101776:	3b 15 a4 ef 17 f0    	cmp    0xf017efa4,%edx
f010177c:	72 20                	jb     f010179e <mem_init+0x4d4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010177e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101782:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0101789:	f0 
f010178a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101791:	00 
f0101792:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f0101799:	e8 20 e9 ff ff       	call   f01000be <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010179e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01017a5:	00 
f01017a6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01017ad:	00 
	return (void *)(pa + KERNBASE);
f01017ae:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01017b3:	89 04 24             	mov    %eax,(%esp)
f01017b6:	e8 ea 35 00 00       	call   f0104da5 <memset>
	page_free(pp0);
f01017bb:	89 34 24             	mov    %esi,(%esp)
f01017be:	e8 0c f8 ff ff       	call   f0100fcf <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017c3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017ca:	e8 7c f7 ff ff       	call   f0100f4b <page_alloc>
f01017cf:	85 c0                	test   %eax,%eax
f01017d1:	75 24                	jne    f01017f7 <mem_init+0x52d>
f01017d3:	c7 44 24 0c ed 60 10 	movl   $0xf01060ed,0xc(%esp)
f01017da:	f0 
f01017db:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01017e2:	f0 
f01017e3:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f01017ea:	00 
f01017eb:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01017f2:	e8 c7 e8 ff ff       	call   f01000be <_panic>
	assert(pp && pp0 == pp);
f01017f7:	39 c6                	cmp    %eax,%esi
f01017f9:	74 24                	je     f010181f <mem_init+0x555>
f01017fb:	c7 44 24 0c 0b 61 10 	movl   $0xf010610b,0xc(%esp)
f0101802:	f0 
f0101803:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010180a:	f0 
f010180b:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f0101812:	00 
f0101813:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010181a:	e8 9f e8 ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010181f:	89 f2                	mov    %esi,%edx
f0101821:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
f0101827:	c1 fa 03             	sar    $0x3,%edx
f010182a:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010182d:	89 d0                	mov    %edx,%eax
f010182f:	c1 e8 0c             	shr    $0xc,%eax
f0101832:	3b 05 a4 ef 17 f0    	cmp    0xf017efa4,%eax
f0101838:	72 20                	jb     f010185a <mem_init+0x590>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010183a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010183e:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0101845:	f0 
f0101846:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010184d:	00 
f010184e:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f0101855:	e8 64 e8 ff ff       	call   f01000be <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010185a:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101861:	75 11                	jne    f0101874 <mem_init+0x5aa>
f0101863:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101869:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010186f:	80 38 00             	cmpb   $0x0,(%eax)
f0101872:	74 24                	je     f0101898 <mem_init+0x5ce>
f0101874:	c7 44 24 0c 1b 61 10 	movl   $0xf010611b,0xc(%esp)
f010187b:	f0 
f010187c:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101883:	f0 
f0101884:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f010188b:	00 
f010188c:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101893:	e8 26 e8 ff ff       	call   f01000be <_panic>
f0101898:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010189b:	39 d0                	cmp    %edx,%eax
f010189d:	75 d0                	jne    f010186f <mem_init+0x5a5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010189f:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01018a2:	89 15 00 e3 17 f0    	mov    %edx,0xf017e300

	// free the pages we took
	page_free(pp0);
f01018a8:	89 34 24             	mov    %esi,(%esp)
f01018ab:	e8 1f f7 ff ff       	call   f0100fcf <page_free>
	page_free(pp1);
f01018b0:	89 3c 24             	mov    %edi,(%esp)
f01018b3:	e8 17 f7 ff ff       	call   f0100fcf <page_free>
	page_free(pp2);
f01018b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018bb:	89 04 24             	mov    %eax,(%esp)
f01018be:	e8 0c f7 ff ff       	call   f0100fcf <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018c3:	a1 00 e3 17 f0       	mov    0xf017e300,%eax
f01018c8:	85 c0                	test   %eax,%eax
f01018ca:	74 09                	je     f01018d5 <mem_init+0x60b>
		--nfree;
f01018cc:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018cf:	8b 00                	mov    (%eax),%eax
f01018d1:	85 c0                	test   %eax,%eax
f01018d3:	75 f7                	jne    f01018cc <mem_init+0x602>
		--nfree;
	assert(nfree == 0);
f01018d5:	85 db                	test   %ebx,%ebx
f01018d7:	74 24                	je     f01018fd <mem_init+0x633>
f01018d9:	c7 44 24 0c 25 61 10 	movl   $0xf0106125,0xc(%esp)
f01018e0:	f0 
f01018e1:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01018e8:	f0 
f01018e9:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f01018f0:	00 
f01018f1:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01018f8:	e8 c1 e7 ff ff       	call   f01000be <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01018fd:	c7 04 24 84 59 10 f0 	movl   $0xf0105984,(%esp)
f0101904:	e8 15 1e 00 00       	call   f010371e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101909:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101910:	e8 36 f6 ff ff       	call   f0100f4b <page_alloc>
f0101915:	89 c3                	mov    %eax,%ebx
f0101917:	85 c0                	test   %eax,%eax
f0101919:	75 24                	jne    f010193f <mem_init+0x675>
f010191b:	c7 44 24 0c 33 60 10 	movl   $0xf0106033,0xc(%esp)
f0101922:	f0 
f0101923:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010192a:	f0 
f010192b:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101932:	00 
f0101933:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010193a:	e8 7f e7 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f010193f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101946:	e8 00 f6 ff ff       	call   f0100f4b <page_alloc>
f010194b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010194e:	85 c0                	test   %eax,%eax
f0101950:	75 24                	jne    f0101976 <mem_init+0x6ac>
f0101952:	c7 44 24 0c 49 60 10 	movl   $0xf0106049,0xc(%esp)
f0101959:	f0 
f010195a:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101961:	f0 
f0101962:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101969:	00 
f010196a:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101971:	e8 48 e7 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101976:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010197d:	e8 c9 f5 ff ff       	call   f0100f4b <page_alloc>
f0101982:	89 c6                	mov    %eax,%esi
f0101984:	85 c0                	test   %eax,%eax
f0101986:	75 24                	jne    f01019ac <mem_init+0x6e2>
f0101988:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f010198f:	f0 
f0101990:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101997:	f0 
f0101998:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f010199f:	00 
f01019a0:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01019a7:	e8 12 e7 ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019ac:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01019af:	75 24                	jne    f01019d5 <mem_init+0x70b>
f01019b1:	c7 44 24 0c 75 60 10 	movl   $0xf0106075,0xc(%esp)
f01019b8:	f0 
f01019b9:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01019c0:	f0 
f01019c1:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f01019c8:	00 
f01019c9:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01019d0:	e8 e9 e6 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019d5:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019d8:	74 04                	je     f01019de <mem_init+0x714>
f01019da:	39 c3                	cmp    %eax,%ebx
f01019dc:	75 24                	jne    f0101a02 <mem_init+0x738>
f01019de:	c7 44 24 0c 64 59 10 	movl   $0xf0105964,0xc(%esp)
f01019e5:	f0 
f01019e6:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01019ed:	f0 
f01019ee:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01019f5:	00 
f01019f6:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01019fd:	e8 bc e6 ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a02:	8b 3d 00 e3 17 f0    	mov    0xf017e300,%edi
f0101a08:	89 7d c8             	mov    %edi,-0x38(%ebp)
	page_free_list = 0;
f0101a0b:	c7 05 00 e3 17 f0 00 	movl   $0x0,0xf017e300
f0101a12:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a15:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a1c:	e8 2a f5 ff ff       	call   f0100f4b <page_alloc>
f0101a21:	85 c0                	test   %eax,%eax
f0101a23:	74 24                	je     f0101a49 <mem_init+0x77f>
f0101a25:	c7 44 24 0c de 60 10 	movl   $0xf01060de,0xc(%esp)
f0101a2c:	f0 
f0101a2d:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101a34:	f0 
f0101a35:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101a3c:	00 
f0101a3d:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101a44:	e8 75 e6 ff ff       	call   f01000be <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a49:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a4c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a50:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a57:	00 
f0101a58:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0101a5d:	89 04 24             	mov    %eax,(%esp)
f0101a60:	e8 e7 f6 ff ff       	call   f010114c <page_lookup>
f0101a65:	85 c0                	test   %eax,%eax
f0101a67:	74 24                	je     f0101a8d <mem_init+0x7c3>
f0101a69:	c7 44 24 0c a4 59 10 	movl   $0xf01059a4,0xc(%esp)
f0101a70:	f0 
f0101a71:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101a78:	f0 
f0101a79:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101a80:	00 
f0101a81:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101a88:	e8 31 e6 ff ff       	call   f01000be <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a8d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a94:	00 
f0101a95:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a9c:	00 
f0101a9d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aa0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101aa4:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0101aa9:	89 04 24             	mov    %eax,(%esp)
f0101aac:	e8 6f f7 ff ff       	call   f0101220 <page_insert>
f0101ab1:	85 c0                	test   %eax,%eax
f0101ab3:	78 24                	js     f0101ad9 <mem_init+0x80f>
f0101ab5:	c7 44 24 0c dc 59 10 	movl   $0xf01059dc,0xc(%esp)
f0101abc:	f0 
f0101abd:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101ac4:	f0 
f0101ac5:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101acc:	00 
f0101acd:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101ad4:	e8 e5 e5 ff ff       	call   f01000be <_panic>
//panic("\n");
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101ad9:	89 1c 24             	mov    %ebx,(%esp)
f0101adc:	e8 ee f4 ff ff       	call   f0100fcf <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101ae1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ae8:	00 
f0101ae9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101af0:	00 
f0101af1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101af4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101af8:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0101afd:	89 04 24             	mov    %eax,(%esp)
f0101b00:	e8 1b f7 ff ff       	call   f0101220 <page_insert>
f0101b05:	85 c0                	test   %eax,%eax
f0101b07:	74 24                	je     f0101b2d <mem_init+0x863>
f0101b09:	c7 44 24 0c 0c 5a 10 	movl   $0xf0105a0c,0xc(%esp)
f0101b10:	f0 
f0101b11:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101b18:	f0 
f0101b19:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101b20:	00 
f0101b21:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101b28:	e8 91 e5 ff ff       	call   f01000be <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b2d:	8b 3d a8 ef 17 f0    	mov    0xf017efa8,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b33:	8b 15 ac ef 17 f0    	mov    0xf017efac,%edx
f0101b39:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101b3c:	8b 17                	mov    (%edi),%edx
f0101b3e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b44:	89 d8                	mov    %ebx,%eax
f0101b46:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101b49:	c1 f8 03             	sar    $0x3,%eax
f0101b4c:	c1 e0 0c             	shl    $0xc,%eax
f0101b4f:	39 c2                	cmp    %eax,%edx
f0101b51:	74 24                	je     f0101b77 <mem_init+0x8ad>
f0101b53:	c7 44 24 0c 3c 5a 10 	movl   $0xf0105a3c,0xc(%esp)
f0101b5a:	f0 
f0101b5b:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101b62:	f0 
f0101b63:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0101b6a:	00 
f0101b6b:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101b72:	e8 47 e5 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b77:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b7c:	89 f8                	mov    %edi,%eax
f0101b7e:	e8 5d ee ff ff       	call   f01009e0 <check_va2pa>
f0101b83:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b86:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101b89:	c1 fa 03             	sar    $0x3,%edx
f0101b8c:	c1 e2 0c             	shl    $0xc,%edx
f0101b8f:	39 d0                	cmp    %edx,%eax
f0101b91:	74 24                	je     f0101bb7 <mem_init+0x8ed>
f0101b93:	c7 44 24 0c 64 5a 10 	movl   $0xf0105a64,0xc(%esp)
f0101b9a:	f0 
f0101b9b:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101ba2:	f0 
f0101ba3:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101baa:	00 
f0101bab:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101bb2:	e8 07 e5 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f0101bb7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bba:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bbf:	74 24                	je     f0101be5 <mem_init+0x91b>
f0101bc1:	c7 44 24 0c 30 61 10 	movl   $0xf0106130,0xc(%esp)
f0101bc8:	f0 
f0101bc9:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101bd0:	f0 
f0101bd1:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101bd8:	00 
f0101bd9:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101be0:	e8 d9 e4 ff ff       	call   f01000be <_panic>
	assert(pp0->pp_ref == 1);
f0101be5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101bea:	74 24                	je     f0101c10 <mem_init+0x946>
f0101bec:	c7 44 24 0c 41 61 10 	movl   $0xf0106141,0xc(%esp)
f0101bf3:	f0 
f0101bf4:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101bfb:	f0 
f0101bfc:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101c03:	00 
f0101c04:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101c0b:	e8 ae e4 ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c10:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c17:	00 
f0101c18:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c1f:	00 
f0101c20:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c24:	89 3c 24             	mov    %edi,(%esp)
f0101c27:	e8 f4 f5 ff ff       	call   f0101220 <page_insert>
f0101c2c:	85 c0                	test   %eax,%eax
f0101c2e:	74 24                	je     f0101c54 <mem_init+0x98a>
f0101c30:	c7 44 24 0c 94 5a 10 	movl   $0xf0105a94,0xc(%esp)
f0101c37:	f0 
f0101c38:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101c3f:	f0 
f0101c40:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101c47:	00 
f0101c48:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101c4f:	e8 6a e4 ff ff       	call   f01000be <_panic>
	//panic("va2pa: %x,page %x", check_va2pa(kern_pgdir, PGSIZE), page2pa(pp2));
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c54:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c59:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0101c5e:	e8 7d ed ff ff       	call   f01009e0 <check_va2pa>
f0101c63:	89 f2                	mov    %esi,%edx
f0101c65:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
f0101c6b:	c1 fa 03             	sar    $0x3,%edx
f0101c6e:	c1 e2 0c             	shl    $0xc,%edx
f0101c71:	39 d0                	cmp    %edx,%eax
f0101c73:	74 24                	je     f0101c99 <mem_init+0x9cf>
f0101c75:	c7 44 24 0c d0 5a 10 	movl   $0xf0105ad0,0xc(%esp)
f0101c7c:	f0 
f0101c7d:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101c84:	f0 
f0101c85:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0101c8c:	00 
f0101c8d:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101c94:	e8 25 e4 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101c99:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c9e:	74 24                	je     f0101cc4 <mem_init+0x9fa>
f0101ca0:	c7 44 24 0c 52 61 10 	movl   $0xf0106152,0xc(%esp)
f0101ca7:	f0 
f0101ca8:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101caf:	f0 
f0101cb0:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0101cb7:	00 
f0101cb8:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101cbf:	e8 fa e3 ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101cc4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ccb:	e8 7b f2 ff ff       	call   f0100f4b <page_alloc>
f0101cd0:	85 c0                	test   %eax,%eax
f0101cd2:	74 24                	je     f0101cf8 <mem_init+0xa2e>
f0101cd4:	c7 44 24 0c de 60 10 	movl   $0xf01060de,0xc(%esp)
f0101cdb:	f0 
f0101cdc:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101ce3:	f0 
f0101ce4:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0101ceb:	00 
f0101cec:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101cf3:	e8 c6 e3 ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cf8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cff:	00 
f0101d00:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d07:	00 
f0101d08:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d0c:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0101d11:	89 04 24             	mov    %eax,(%esp)
f0101d14:	e8 07 f5 ff ff       	call   f0101220 <page_insert>
f0101d19:	85 c0                	test   %eax,%eax
f0101d1b:	74 24                	je     f0101d41 <mem_init+0xa77>
f0101d1d:	c7 44 24 0c 94 5a 10 	movl   $0xf0105a94,0xc(%esp)
f0101d24:	f0 
f0101d25:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101d2c:	f0 
f0101d2d:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101d34:	00 
f0101d35:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101d3c:	e8 7d e3 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d41:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d46:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0101d4b:	e8 90 ec ff ff       	call   f01009e0 <check_va2pa>
f0101d50:	89 f2                	mov    %esi,%edx
f0101d52:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
f0101d58:	c1 fa 03             	sar    $0x3,%edx
f0101d5b:	c1 e2 0c             	shl    $0xc,%edx
f0101d5e:	39 d0                	cmp    %edx,%eax
f0101d60:	74 24                	je     f0101d86 <mem_init+0xabc>
f0101d62:	c7 44 24 0c d0 5a 10 	movl   $0xf0105ad0,0xc(%esp)
f0101d69:	f0 
f0101d6a:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101d71:	f0 
f0101d72:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0101d79:	00 
f0101d7a:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101d81:	e8 38 e3 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101d86:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d8b:	74 24                	je     f0101db1 <mem_init+0xae7>
f0101d8d:	c7 44 24 0c 52 61 10 	movl   $0xf0106152,0xc(%esp)
f0101d94:	f0 
f0101d95:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101d9c:	f0 
f0101d9d:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101da4:	00 
f0101da5:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101dac:	e8 0d e3 ff ff       	call   f01000be <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101db1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101db8:	e8 8e f1 ff ff       	call   f0100f4b <page_alloc>
f0101dbd:	85 c0                	test   %eax,%eax
f0101dbf:	74 24                	je     f0101de5 <mem_init+0xb1b>
f0101dc1:	c7 44 24 0c de 60 10 	movl   $0xf01060de,0xc(%esp)
f0101dc8:	f0 
f0101dc9:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101dd0:	f0 
f0101dd1:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0101dd8:	00 
f0101dd9:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101de0:	e8 d9 e2 ff ff       	call   f01000be <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101de5:	8b 15 a8 ef 17 f0    	mov    0xf017efa8,%edx
f0101deb:	8b 02                	mov    (%edx),%eax
f0101ded:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101df2:	89 c1                	mov    %eax,%ecx
f0101df4:	c1 e9 0c             	shr    $0xc,%ecx
f0101df7:	3b 0d a4 ef 17 f0    	cmp    0xf017efa4,%ecx
f0101dfd:	72 20                	jb     f0101e1f <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101dff:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e03:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0101e0a:	f0 
f0101e0b:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0101e12:	00 
f0101e13:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101e1a:	e8 9f e2 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0101e1f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e24:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101e27:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e2e:	00 
f0101e2f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e36:	00 
f0101e37:	89 14 24             	mov    %edx,(%esp)
f0101e3a:	e8 cf f1 ff ff       	call   f010100e <pgdir_walk>
f0101e3f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101e42:	83 c2 04             	add    $0x4,%edx
f0101e45:	39 d0                	cmp    %edx,%eax
f0101e47:	74 24                	je     f0101e6d <mem_init+0xba3>
f0101e49:	c7 44 24 0c 00 5b 10 	movl   $0xf0105b00,0xc(%esp)
f0101e50:	f0 
f0101e51:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101e58:	f0 
f0101e59:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101e60:	00 
f0101e61:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101e68:	e8 51 e2 ff ff       	call   f01000be <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e6d:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e74:	00 
f0101e75:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e7c:	00 
f0101e7d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e81:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0101e86:	89 04 24             	mov    %eax,(%esp)
f0101e89:	e8 92 f3 ff ff       	call   f0101220 <page_insert>
f0101e8e:	85 c0                	test   %eax,%eax
f0101e90:	74 24                	je     f0101eb6 <mem_init+0xbec>
f0101e92:	c7 44 24 0c 40 5b 10 	movl   $0xf0105b40,0xc(%esp)
f0101e99:	f0 
f0101e9a:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101ea1:	f0 
f0101ea2:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101ea9:	00 
f0101eaa:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101eb1:	e8 08 e2 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101eb6:	8b 3d a8 ef 17 f0    	mov    0xf017efa8,%edi
f0101ebc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ec1:	89 f8                	mov    %edi,%eax
f0101ec3:	e8 18 eb ff ff       	call   f01009e0 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ec8:	89 f2                	mov    %esi,%edx
f0101eca:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
f0101ed0:	c1 fa 03             	sar    $0x3,%edx
f0101ed3:	c1 e2 0c             	shl    $0xc,%edx
f0101ed6:	39 d0                	cmp    %edx,%eax
f0101ed8:	74 24                	je     f0101efe <mem_init+0xc34>
f0101eda:	c7 44 24 0c d0 5a 10 	movl   $0xf0105ad0,0xc(%esp)
f0101ee1:	f0 
f0101ee2:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101ee9:	f0 
f0101eea:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0101ef1:	00 
f0101ef2:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101ef9:	e8 c0 e1 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101efe:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f03:	74 24                	je     f0101f29 <mem_init+0xc5f>
f0101f05:	c7 44 24 0c 52 61 10 	movl   $0xf0106152,0xc(%esp)
f0101f0c:	f0 
f0101f0d:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101f14:	f0 
f0101f15:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0101f1c:	00 
f0101f1d:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101f24:	e8 95 e1 ff ff       	call   f01000be <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101f29:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f30:	00 
f0101f31:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f38:	00 
f0101f39:	89 3c 24             	mov    %edi,(%esp)
f0101f3c:	e8 cd f0 ff ff       	call   f010100e <pgdir_walk>
f0101f41:	f6 00 04             	testb  $0x4,(%eax)
f0101f44:	75 24                	jne    f0101f6a <mem_init+0xca0>
f0101f46:	c7 44 24 0c 80 5b 10 	movl   $0xf0105b80,0xc(%esp)
f0101f4d:	f0 
f0101f4e:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101f55:	f0 
f0101f56:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f0101f5d:	00 
f0101f5e:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101f65:	e8 54 e1 ff ff       	call   f01000be <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f6a:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0101f6f:	f6 00 04             	testb  $0x4,(%eax)
f0101f72:	75 24                	jne    f0101f98 <mem_init+0xcce>
f0101f74:	c7 44 24 0c 63 61 10 	movl   $0xf0106163,0xc(%esp)
f0101f7b:	f0 
f0101f7c:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101f83:	f0 
f0101f84:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0101f8b:	00 
f0101f8c:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101f93:	e8 26 e1 ff ff       	call   f01000be <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f98:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f9f:	00 
f0101fa0:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101fa7:	00 
f0101fa8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fac:	89 04 24             	mov    %eax,(%esp)
f0101faf:	e8 6c f2 ff ff       	call   f0101220 <page_insert>
f0101fb4:	85 c0                	test   %eax,%eax
f0101fb6:	78 24                	js     f0101fdc <mem_init+0xd12>
f0101fb8:	c7 44 24 0c b4 5b 10 	movl   $0xf0105bb4,0xc(%esp)
f0101fbf:	f0 
f0101fc0:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101fc7:	f0 
f0101fc8:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0101fcf:	00 
f0101fd0:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0101fd7:	e8 e2 e0 ff ff       	call   f01000be <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101fdc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fe3:	00 
f0101fe4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101feb:	00 
f0101fec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fef:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ff3:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0101ff8:	89 04 24             	mov    %eax,(%esp)
f0101ffb:	e8 20 f2 ff ff       	call   f0101220 <page_insert>
f0102000:	85 c0                	test   %eax,%eax
f0102002:	74 24                	je     f0102028 <mem_init+0xd5e>
f0102004:	c7 44 24 0c ec 5b 10 	movl   $0xf0105bec,0xc(%esp)
f010200b:	f0 
f010200c:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102013:	f0 
f0102014:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f010201b:	00 
f010201c:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102023:	e8 96 e0 ff ff       	call   f01000be <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102028:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010202f:	00 
f0102030:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102037:	00 
f0102038:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f010203d:	89 04 24             	mov    %eax,(%esp)
f0102040:	e8 c9 ef ff ff       	call   f010100e <pgdir_walk>
f0102045:	f6 00 04             	testb  $0x4,(%eax)
f0102048:	74 24                	je     f010206e <mem_init+0xda4>
f010204a:	c7 44 24 0c 28 5c 10 	movl   $0xf0105c28,0xc(%esp)
f0102051:	f0 
f0102052:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102059:	f0 
f010205a:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0102061:	00 
f0102062:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102069:	e8 50 e0 ff ff       	call   f01000be <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010206e:	8b 3d a8 ef 17 f0    	mov    0xf017efa8,%edi
f0102074:	ba 00 00 00 00       	mov    $0x0,%edx
f0102079:	89 f8                	mov    %edi,%eax
f010207b:	e8 60 e9 ff ff       	call   f01009e0 <check_va2pa>
f0102080:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102083:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102086:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f010208c:	c1 f8 03             	sar    $0x3,%eax
f010208f:	c1 e0 0c             	shl    $0xc,%eax
f0102092:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102095:	74 24                	je     f01020bb <mem_init+0xdf1>
f0102097:	c7 44 24 0c 60 5c 10 	movl   $0xf0105c60,0xc(%esp)
f010209e:	f0 
f010209f:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01020a6:	f0 
f01020a7:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f01020ae:	00 
f01020af:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01020b6:	e8 03 e0 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020bb:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020c0:	89 f8                	mov    %edi,%eax
f01020c2:	e8 19 e9 ff ff       	call   f01009e0 <check_va2pa>
f01020c7:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01020ca:	74 24                	je     f01020f0 <mem_init+0xe26>
f01020cc:	c7 44 24 0c 8c 5c 10 	movl   $0xf0105c8c,0xc(%esp)
f01020d3:	f0 
f01020d4:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01020db:	f0 
f01020dc:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f01020e3:	00 
f01020e4:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01020eb:	e8 ce df ff ff       	call   f01000be <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020f3:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f01020f8:	74 24                	je     f010211e <mem_init+0xe54>
f01020fa:	c7 44 24 0c 79 61 10 	movl   $0xf0106179,0xc(%esp)
f0102101:	f0 
f0102102:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102109:	f0 
f010210a:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f0102111:	00 
f0102112:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102119:	e8 a0 df ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f010211e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102123:	74 24                	je     f0102149 <mem_init+0xe7f>
f0102125:	c7 44 24 0c 8a 61 10 	movl   $0xf010618a,0xc(%esp)
f010212c:	f0 
f010212d:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102134:	f0 
f0102135:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f010213c:	00 
f010213d:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102144:	e8 75 df ff ff       	call   f01000be <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102150:	e8 f6 ed ff ff       	call   f0100f4b <page_alloc>
f0102155:	85 c0                	test   %eax,%eax
f0102157:	74 04                	je     f010215d <mem_init+0xe93>
f0102159:	39 c6                	cmp    %eax,%esi
f010215b:	74 24                	je     f0102181 <mem_init+0xeb7>
f010215d:	c7 44 24 0c bc 5c 10 	movl   $0xf0105cbc,0xc(%esp)
f0102164:	f0 
f0102165:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010216c:	f0 
f010216d:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0102174:	00 
f0102175:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010217c:	e8 3d df ff ff       	call   f01000be <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102181:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102188:	00 
f0102189:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f010218e:	89 04 24             	mov    %eax,(%esp)
f0102191:	e8 3a f0 ff ff       	call   f01011d0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102196:	8b 3d a8 ef 17 f0    	mov    0xf017efa8,%edi
f010219c:	ba 00 00 00 00       	mov    $0x0,%edx
f01021a1:	89 f8                	mov    %edi,%eax
f01021a3:	e8 38 e8 ff ff       	call   f01009e0 <check_va2pa>
f01021a8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021ab:	74 24                	je     f01021d1 <mem_init+0xf07>
f01021ad:	c7 44 24 0c e0 5c 10 	movl   $0xf0105ce0,0xc(%esp)
f01021b4:	f0 
f01021b5:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01021bc:	f0 
f01021bd:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01021c4:	00 
f01021c5:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01021cc:	e8 ed de ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021d1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021d6:	89 f8                	mov    %edi,%eax
f01021d8:	e8 03 e8 ff ff       	call   f01009e0 <check_va2pa>
f01021dd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01021e0:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
f01021e6:	c1 fa 03             	sar    $0x3,%edx
f01021e9:	c1 e2 0c             	shl    $0xc,%edx
f01021ec:	39 d0                	cmp    %edx,%eax
f01021ee:	74 24                	je     f0102214 <mem_init+0xf4a>
f01021f0:	c7 44 24 0c 8c 5c 10 	movl   $0xf0105c8c,0xc(%esp)
f01021f7:	f0 
f01021f8:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01021ff:	f0 
f0102200:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0102207:	00 
f0102208:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010220f:	e8 aa de ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f0102214:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102217:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010221c:	74 24                	je     f0102242 <mem_init+0xf78>
f010221e:	c7 44 24 0c 30 61 10 	movl   $0xf0106130,0xc(%esp)
f0102225:	f0 
f0102226:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010222d:	f0 
f010222e:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0102235:	00 
f0102236:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010223d:	e8 7c de ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f0102242:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102247:	74 24                	je     f010226d <mem_init+0xfa3>
f0102249:	c7 44 24 0c 8a 61 10 	movl   $0xf010618a,0xc(%esp)
f0102250:	f0 
f0102251:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102258:	f0 
f0102259:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0102260:	00 
f0102261:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102268:	e8 51 de ff ff       	call   f01000be <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010226d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102274:	00 
f0102275:	89 3c 24             	mov    %edi,(%esp)
f0102278:	e8 53 ef ff ff       	call   f01011d0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010227d:	8b 3d a8 ef 17 f0    	mov    0xf017efa8,%edi
f0102283:	ba 00 00 00 00       	mov    $0x0,%edx
f0102288:	89 f8                	mov    %edi,%eax
f010228a:	e8 51 e7 ff ff       	call   f01009e0 <check_va2pa>
f010228f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102292:	74 24                	je     f01022b8 <mem_init+0xfee>
f0102294:	c7 44 24 0c e0 5c 10 	movl   $0xf0105ce0,0xc(%esp)
f010229b:	f0 
f010229c:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01022a3:	f0 
f01022a4:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01022ab:	00 
f01022ac:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01022b3:	e8 06 de ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01022b8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022bd:	89 f8                	mov    %edi,%eax
f01022bf:	e8 1c e7 ff ff       	call   f01009e0 <check_va2pa>
f01022c4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022c7:	74 24                	je     f01022ed <mem_init+0x1023>
f01022c9:	c7 44 24 0c 04 5d 10 	movl   $0xf0105d04,0xc(%esp)
f01022d0:	f0 
f01022d1:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01022d8:	f0 
f01022d9:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f01022e0:	00 
f01022e1:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01022e8:	e8 d1 dd ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f01022ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f0:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01022f5:	74 24                	je     f010231b <mem_init+0x1051>
f01022f7:	c7 44 24 0c 9b 61 10 	movl   $0xf010619b,0xc(%esp)
f01022fe:	f0 
f01022ff:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102306:	f0 
f0102307:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f010230e:	00 
f010230f:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102316:	e8 a3 dd ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f010231b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102320:	74 24                	je     f0102346 <mem_init+0x107c>
f0102322:	c7 44 24 0c 8a 61 10 	movl   $0xf010618a,0xc(%esp)
f0102329:	f0 
f010232a:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102331:	f0 
f0102332:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0102339:	00 
f010233a:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102341:	e8 78 dd ff ff       	call   f01000be <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102346:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010234d:	e8 f9 eb ff ff       	call   f0100f4b <page_alloc>
f0102352:	85 c0                	test   %eax,%eax
f0102354:	74 05                	je     f010235b <mem_init+0x1091>
f0102356:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0102359:	74 24                	je     f010237f <mem_init+0x10b5>
f010235b:	c7 44 24 0c 2c 5d 10 	movl   $0xf0105d2c,0xc(%esp)
f0102362:	f0 
f0102363:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010236a:	f0 
f010236b:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0102372:	00 
f0102373:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010237a:	e8 3f dd ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010237f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102386:	e8 c0 eb ff ff       	call   f0100f4b <page_alloc>
f010238b:	85 c0                	test   %eax,%eax
f010238d:	74 24                	je     f01023b3 <mem_init+0x10e9>
f010238f:	c7 44 24 0c de 60 10 	movl   $0xf01060de,0xc(%esp)
f0102396:	f0 
f0102397:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010239e:	f0 
f010239f:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f01023a6:	00 
f01023a7:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01023ae:	e8 0b dd ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023b3:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f01023b8:	8b 08                	mov    (%eax),%ecx
f01023ba:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01023c0:	89 da                	mov    %ebx,%edx
f01023c2:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
f01023c8:	c1 fa 03             	sar    $0x3,%edx
f01023cb:	c1 e2 0c             	shl    $0xc,%edx
f01023ce:	39 d1                	cmp    %edx,%ecx
f01023d0:	74 24                	je     f01023f6 <mem_init+0x112c>
f01023d2:	c7 44 24 0c 3c 5a 10 	movl   $0xf0105a3c,0xc(%esp)
f01023d9:	f0 
f01023da:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01023e1:	f0 
f01023e2:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f01023e9:	00 
f01023ea:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01023f1:	e8 c8 dc ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f01023f6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01023fc:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102401:	74 24                	je     f0102427 <mem_init+0x115d>
f0102403:	c7 44 24 0c 41 61 10 	movl   $0xf0106141,0xc(%esp)
f010240a:	f0 
f010240b:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102412:	f0 
f0102413:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f010241a:	00 
f010241b:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102422:	e8 97 dc ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f0102427:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010242d:	89 1c 24             	mov    %ebx,(%esp)
f0102430:	e8 9a eb ff ff       	call   f0100fcf <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102435:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010243c:	00 
f010243d:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102444:	00 
f0102445:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f010244a:	89 04 24             	mov    %eax,(%esp)
f010244d:	e8 bc eb ff ff       	call   f010100e <pgdir_walk>
f0102452:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102455:	8b 15 a8 ef 17 f0    	mov    0xf017efa8,%edx
f010245b:	8b 4a 04             	mov    0x4(%edx),%ecx
f010245e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102464:	89 4d cc             	mov    %ecx,-0x34(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102467:	8b 0d a4 ef 17 f0    	mov    0xf017efa4,%ecx
f010246d:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102470:	c1 ef 0c             	shr    $0xc,%edi
f0102473:	39 cf                	cmp    %ecx,%edi
f0102475:	72 23                	jb     f010249a <mem_init+0x11d0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102477:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010247a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010247e:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0102485:	f0 
f0102486:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f010248d:	00 
f010248e:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102495:	e8 24 dc ff ff       	call   f01000be <_panic>
	assert(ptep == ptep1 + PTX(va));
f010249a:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010249d:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01024a3:	39 f8                	cmp    %edi,%eax
f01024a5:	74 24                	je     f01024cb <mem_init+0x1201>
f01024a7:	c7 44 24 0c ac 61 10 	movl   $0xf01061ac,0xc(%esp)
f01024ae:	f0 
f01024af:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01024b6:	f0 
f01024b7:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f01024be:	00 
f01024bf:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01024c6:	e8 f3 db ff ff       	call   f01000be <_panic>
	kern_pgdir[PDX(va)] = 0;
f01024cb:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01024d2:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024d8:	89 d8                	mov    %ebx,%eax
f01024da:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f01024e0:	c1 f8 03             	sar    $0x3,%eax
f01024e3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024e6:	89 c2                	mov    %eax,%edx
f01024e8:	c1 ea 0c             	shr    $0xc,%edx
f01024eb:	39 d1                	cmp    %edx,%ecx
f01024ed:	77 20                	ja     f010250f <mem_init+0x1245>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01024f3:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f01024fa:	f0 
f01024fb:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102502:	00 
f0102503:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f010250a:	e8 af db ff ff       	call   f01000be <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010250f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102516:	00 
f0102517:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010251e:	00 
	return (void *)(pa + KERNBASE);
f010251f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102524:	89 04 24             	mov    %eax,(%esp)
f0102527:	e8 79 28 00 00       	call   f0104da5 <memset>
	page_free(pp0);
f010252c:	89 1c 24             	mov    %ebx,(%esp)
f010252f:	e8 9b ea ff ff       	call   f0100fcf <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102534:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010253b:	00 
f010253c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102543:	00 
f0102544:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0102549:	89 04 24             	mov    %eax,(%esp)
f010254c:	e8 bd ea ff ff       	call   f010100e <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102551:	89 da                	mov    %ebx,%edx
f0102553:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
f0102559:	c1 fa 03             	sar    $0x3,%edx
f010255c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010255f:	89 d0                	mov    %edx,%eax
f0102561:	c1 e8 0c             	shr    $0xc,%eax
f0102564:	3b 05 a4 ef 17 f0    	cmp    0xf017efa4,%eax
f010256a:	72 20                	jb     f010258c <mem_init+0x12c2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010256c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102570:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0102577:	f0 
f0102578:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010257f:	00 
f0102580:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f0102587:	e8 32 db ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f010258c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102592:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102595:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f010259c:	75 11                	jne    f01025af <mem_init+0x12e5>
f010259e:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01025a4:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01025aa:	f6 00 01             	testb  $0x1,(%eax)
f01025ad:	74 24                	je     f01025d3 <mem_init+0x1309>
f01025af:	c7 44 24 0c c4 61 10 	movl   $0xf01061c4,0xc(%esp)
f01025b6:	f0 
f01025b7:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01025be:	f0 
f01025bf:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f01025c6:	00 
f01025c7:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01025ce:	e8 eb da ff ff       	call   f01000be <_panic>
f01025d3:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01025d6:	39 d0                	cmp    %edx,%eax
f01025d8:	75 d0                	jne    f01025aa <mem_init+0x12e0>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01025da:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f01025df:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01025e5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f01025eb:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01025ee:	89 3d 00 e3 17 f0    	mov    %edi,0xf017e300

	// free the pages we took
	page_free(pp0);
f01025f4:	89 1c 24             	mov    %ebx,(%esp)
f01025f7:	e8 d3 e9 ff ff       	call   f0100fcf <page_free>
	page_free(pp1);
f01025fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025ff:	89 04 24             	mov    %eax,(%esp)
f0102602:	e8 c8 e9 ff ff       	call   f0100fcf <page_free>
	page_free(pp2);
f0102607:	89 34 24             	mov    %esi,(%esp)
f010260a:	e8 c0 e9 ff ff       	call   f0100fcf <page_free>

	cprintf("check_page() succeeded!\n");
f010260f:	c7 04 24 db 61 10 f0 	movl   $0xf01061db,(%esp)
f0102616:	e8 03 11 00 00       	call   f010371e <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
//pte_t *p = (pte_t *)0xf03fd000;
	boot_map_region(kern_pgdir,UPAGES, npages * sizeof(struct Page), PADDR(pages), PTE_U|PTE_P);
f010261b:	a1 ac ef 17 f0       	mov    0xf017efac,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102620:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102625:	77 20                	ja     f0102647 <mem_init+0x137d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102627:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010262b:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f0102632:	f0 
f0102633:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
f010263a:	00 
f010263b:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102642:	e8 77 da ff ff       	call   f01000be <_panic>
f0102647:	8b 0d a4 ef 17 f0    	mov    0xf017efa4,%ecx
f010264d:	c1 e1 03             	shl    $0x3,%ecx
f0102650:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102657:	00 
	return (physaddr_t)kva - KERNBASE;
f0102658:	05 00 00 00 10       	add    $0x10000000,%eax
f010265d:	89 04 24             	mov    %eax,(%esp)
f0102660:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102665:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f010266a:	e8 82 ea ff ff       	call   f01010f1 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS, NENV * sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f010266f:	a1 0c e3 17 f0       	mov    0xf017e30c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102674:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102679:	77 20                	ja     f010269b <mem_init+0x13d1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010267b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010267f:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f0102686:	f0 
f0102687:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f010268e:	00 
f010268f:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102696:	e8 23 da ff ff       	call   f01000be <_panic>
f010269b:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01026a2:	00 
	return (physaddr_t)kva - KERNBASE;
f01026a3:	05 00 00 00 10       	add    $0x10000000,%eax
f01026a8:	89 04 24             	mov    %eax,(%esp)
f01026ab:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01026b0:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01026b5:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f01026ba:	e8 32 ea ff ff       	call   f01010f1 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026bf:	ba 00 20 11 f0       	mov    $0xf0112000,%edx
f01026c4:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01026ca:	77 20                	ja     f01026ec <mem_init+0x1422>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026cc:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01026d0:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f01026d7:	f0 
f01026d8:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
f01026df:	00 
f01026e0:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01026e7:	e8 d2 d9 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01026ec:	c7 45 cc 00 20 11 00 	movl   $0x112000,-0x34(%ebp)
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
//	cprintf("\n%x\n", KSTACKTOP - KSTKSIZE);
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_P|PTE_W);
f01026f3:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01026fa:	00 
f01026fb:	c7 04 24 00 20 11 00 	movl   $0x112000,(%esp)
f0102702:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102707:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f010270c:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0102711:	e8 db e9 ff ff       	call   f01010f1 <boot_map_region>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ~0x0 - KERNBASE + 1;
	//cprintf("the size is %x", size);
	boot_map_region(kern_pgdir, KERNBASE, size, (physaddr_t)0,PTE_P|PTE_W);
f0102716:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010271d:	00 
f010271e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102725:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010272a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010272f:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0102734:	e8 b8 e9 ff ff       	call   f01010f1 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102739:	8b 1d a8 ef 17 f0    	mov    0xf017efa8,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f010273f:	8b 3d a4 ef 17 f0    	mov    0xf017efa4,%edi
f0102745:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102748:	8d 04 fd ff 0f 00 00 	lea    0xfff(,%edi,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f010274f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102754:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102757:	75 30                	jne    f0102789 <mem_init+0x14bf>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102759:	8b 35 0c e3 17 f0    	mov    0xf017e30c,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010275f:	89 f7                	mov    %esi,%edi
f0102761:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102766:	89 d8                	mov    %ebx,%eax
f0102768:	e8 73 e2 ff ff       	call   f01009e0 <check_va2pa>
f010276d:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102773:	0f 86 94 00 00 00    	jbe    f010280d <mem_init+0x1543>
f0102779:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010277e:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f0102784:	e9 a4 00 00 00       	jmp    f010282d <mem_init+0x1563>
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102789:	8b 35 ac ef 17 f0    	mov    0xf017efac,%esi
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f010278f:	8d be 00 00 00 10    	lea    0x10000000(%esi),%edi
f0102795:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010279a:	89 d8                	mov    %ebx,%eax
f010279c:	e8 3f e2 ff ff       	call   f01009e0 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027a1:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01027a7:	77 20                	ja     f01027c9 <mem_init+0x14ff>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027a9:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01027ad:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f01027b4:	f0 
f01027b5:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f01027bc:	00 
f01027bd:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01027c4:	e8 f5 d8 ff ff       	call   f01000be <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027c9:	ba 00 00 00 00       	mov    $0x0,%edx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027ce:	8d 0c 17             	lea    (%edi,%edx,1),%ecx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027d1:	39 c1                	cmp    %eax,%ecx
f01027d3:	74 24                	je     f01027f9 <mem_init+0x152f>
f01027d5:	c7 44 24 0c 50 5d 10 	movl   $0xf0105d50,0xc(%esp)
f01027dc:	f0 
f01027dd:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01027e4:	f0 
f01027e5:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f01027ec:	00 
f01027ed:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01027f4:	e8 c5 d8 ff ff       	call   f01000be <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027f9:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f01027ff:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102802:	0f 87 58 06 00 00    	ja     f0102e60 <mem_init+0x1b96>
f0102808:	e9 4c ff ff ff       	jmp    f0102759 <mem_init+0x148f>
f010280d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102811:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f0102818:	f0 
f0102819:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0102820:	00 
f0102821:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102828:	e8 91 d8 ff ff       	call   f01000be <_panic>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010282d:	8d 14 37             	lea    (%edi,%esi,1),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102830:	39 c2                	cmp    %eax,%edx
f0102832:	74 24                	je     f0102858 <mem_init+0x158e>
f0102834:	c7 44 24 0c 84 5d 10 	movl   $0xf0105d84,0xc(%esp)
f010283b:	f0 
f010283c:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102843:	f0 
f0102844:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f010284b:	00 
f010284c:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102853:	e8 66 d8 ff ff       	call   f01000be <_panic>
f0102858:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010285e:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102864:	0f 85 e8 05 00 00    	jne    f0102e52 <mem_init+0x1b88>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010286a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010286d:	c1 e7 0c             	shl    $0xc,%edi
f0102870:	85 ff                	test   %edi,%edi
f0102872:	0f 84 b3 05 00 00    	je     f0102e2b <mem_init+0x1b61>
f0102878:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010287d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102883:	89 d8                	mov    %ebx,%eax
f0102885:	e8 56 e1 ff ff       	call   f01009e0 <check_va2pa>
f010288a:	39 c6                	cmp    %eax,%esi
f010288c:	74 24                	je     f01028b2 <mem_init+0x15e8>
f010288e:	c7 44 24 0c b8 5d 10 	movl   $0xf0105db8,0xc(%esp)
f0102895:	f0 
f0102896:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010289d:	f0 
f010289e:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f01028a5:	00 
f01028a6:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01028ad:	e8 0c d8 ff ff       	call   f01000be <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028b2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028b8:	39 fe                	cmp    %edi,%esi
f01028ba:	72 c1                	jb     f010287d <mem_init+0x15b3>
f01028bc:	e9 6a 05 00 00       	jmp    f0102e2b <mem_init+0x1b61>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028c1:	39 c3                	cmp    %eax,%ebx
f01028c3:	74 24                	je     f01028e9 <mem_init+0x161f>
f01028c5:	c7 44 24 0c e0 5d 10 	movl   $0xf0105de0,0xc(%esp)
f01028cc:	f0 
f01028cd:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01028d4:	f0 
f01028d5:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f01028dc:	00 
f01028dd:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01028e4:	e8 d5 d7 ff ff       	call   f01000be <_panic>
f01028e9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028ef:	39 f3                	cmp    %esi,%ebx
f01028f1:	0f 85 24 05 00 00    	jne    f0102e1b <mem_init+0x1b51>
f01028f7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01028fa:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f01028ff:	89 d8                	mov    %ebx,%eax
f0102901:	e8 da e0 ff ff       	call   f01009e0 <check_va2pa>
f0102906:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102909:	74 24                	je     f010292f <mem_init+0x1665>
f010290b:	c7 44 24 0c 28 5e 10 	movl   $0xf0105e28,0xc(%esp)
f0102912:	f0 
f0102913:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010291a:	f0 
f010291b:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f0102922:	00 
f0102923:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010292a:	e8 8f d7 ff ff       	call   f01000be <_panic>
f010292f:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102934:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f010293a:	83 fa 03             	cmp    $0x3,%edx
f010293d:	77 2e                	ja     f010296d <mem_init+0x16a3>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010293f:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102943:	0f 85 aa 00 00 00    	jne    f01029f3 <mem_init+0x1729>
f0102949:	c7 44 24 0c f4 61 10 	movl   $0xf01061f4,0xc(%esp)
f0102950:	f0 
f0102951:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102958:	f0 
f0102959:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0102960:	00 
f0102961:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102968:	e8 51 d7 ff ff       	call   f01000be <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010296d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102972:	76 55                	jbe    f01029c9 <mem_init+0x16ff>
				assert(pgdir[i] & PTE_P);
f0102974:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102977:	f6 c2 01             	test   $0x1,%dl
f010297a:	75 24                	jne    f01029a0 <mem_init+0x16d6>
f010297c:	c7 44 24 0c f4 61 10 	movl   $0xf01061f4,0xc(%esp)
f0102983:	f0 
f0102984:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f010298b:	f0 
f010298c:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0102993:	00 
f0102994:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f010299b:	e8 1e d7 ff ff       	call   f01000be <_panic>
				assert(pgdir[i] & PTE_W);
f01029a0:	f6 c2 02             	test   $0x2,%dl
f01029a3:	75 4e                	jne    f01029f3 <mem_init+0x1729>
f01029a5:	c7 44 24 0c 05 62 10 	movl   $0xf0106205,0xc(%esp)
f01029ac:	f0 
f01029ad:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01029b4:	f0 
f01029b5:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f01029bc:	00 
f01029bd:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01029c4:	e8 f5 d6 ff ff       	call   f01000be <_panic>
			} else
				assert(pgdir[i] == 0);
f01029c9:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01029cd:	74 24                	je     f01029f3 <mem_init+0x1729>
f01029cf:	c7 44 24 0c 16 62 10 	movl   $0xf0106216,0xc(%esp)
f01029d6:	f0 
f01029d7:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f01029de:	f0 
f01029df:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f01029e6:	00 
f01029e7:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f01029ee:	e8 cb d6 ff ff       	call   f01000be <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01029f3:	83 c0 01             	add    $0x1,%eax
f01029f6:	3d 00 04 00 00       	cmp    $0x400,%eax
f01029fb:	0f 85 33 ff ff ff    	jne    f0102934 <mem_init+0x166a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a01:	c7 04 24 58 5e 10 f0 	movl   $0xf0105e58,(%esp)
f0102a08:	e8 11 0d 00 00       	call   f010371e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a0d:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a12:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a17:	77 20                	ja     f0102a39 <mem_init+0x176f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a19:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a1d:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f0102a24:	f0 
f0102a25:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
f0102a2c:	00 
f0102a2d:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102a34:	e8 85 d6 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102a39:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102a3e:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a41:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a46:	e8 a9 e0 ff ff       	call   f0100af4 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102a4b:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a4e:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a51:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102a56:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a59:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a60:	e8 e6 e4 ff ff       	call   f0100f4b <page_alloc>
f0102a65:	89 c3                	mov    %eax,%ebx
f0102a67:	85 c0                	test   %eax,%eax
f0102a69:	75 24                	jne    f0102a8f <mem_init+0x17c5>
f0102a6b:	c7 44 24 0c 33 60 10 	movl   $0xf0106033,0xc(%esp)
f0102a72:	f0 
f0102a73:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102a7a:	f0 
f0102a7b:	c7 44 24 04 c2 03 00 	movl   $0x3c2,0x4(%esp)
f0102a82:	00 
f0102a83:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102a8a:	e8 2f d6 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0102a8f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a96:	e8 b0 e4 ff ff       	call   f0100f4b <page_alloc>
f0102a9b:	89 c7                	mov    %eax,%edi
f0102a9d:	85 c0                	test   %eax,%eax
f0102a9f:	75 24                	jne    f0102ac5 <mem_init+0x17fb>
f0102aa1:	c7 44 24 0c 49 60 10 	movl   $0xf0106049,0xc(%esp)
f0102aa8:	f0 
f0102aa9:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102ab0:	f0 
f0102ab1:	c7 44 24 04 c3 03 00 	movl   $0x3c3,0x4(%esp)
f0102ab8:	00 
f0102ab9:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102ac0:	e8 f9 d5 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0102ac5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102acc:	e8 7a e4 ff ff       	call   f0100f4b <page_alloc>
f0102ad1:	89 c6                	mov    %eax,%esi
f0102ad3:	85 c0                	test   %eax,%eax
f0102ad5:	75 24                	jne    f0102afb <mem_init+0x1831>
f0102ad7:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f0102ade:	f0 
f0102adf:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102ae6:	f0 
f0102ae7:	c7 44 24 04 c4 03 00 	movl   $0x3c4,0x4(%esp)
f0102aee:	00 
f0102aef:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102af6:	e8 c3 d5 ff ff       	call   f01000be <_panic>
	page_free(pp0);
f0102afb:	89 1c 24             	mov    %ebx,(%esp)
f0102afe:	e8 cc e4 ff ff       	call   f0100fcf <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b03:	89 f8                	mov    %edi,%eax
f0102b05:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f0102b0b:	c1 f8 03             	sar    $0x3,%eax
f0102b0e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b11:	89 c2                	mov    %eax,%edx
f0102b13:	c1 ea 0c             	shr    $0xc,%edx
f0102b16:	3b 15 a4 ef 17 f0    	cmp    0xf017efa4,%edx
f0102b1c:	72 20                	jb     f0102b3e <mem_init+0x1874>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b1e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b22:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0102b29:	f0 
f0102b2a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102b31:	00 
f0102b32:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f0102b39:	e8 80 d5 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b3e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b45:	00 
f0102b46:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102b4d:	00 
	return (void *)(pa + KERNBASE);
f0102b4e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b53:	89 04 24             	mov    %eax,(%esp)
f0102b56:	e8 4a 22 00 00       	call   f0104da5 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b5b:	89 f0                	mov    %esi,%eax
f0102b5d:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f0102b63:	c1 f8 03             	sar    $0x3,%eax
f0102b66:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b69:	89 c2                	mov    %eax,%edx
f0102b6b:	c1 ea 0c             	shr    $0xc,%edx
f0102b6e:	3b 15 a4 ef 17 f0    	cmp    0xf017efa4,%edx
f0102b74:	72 20                	jb     f0102b96 <mem_init+0x18cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b76:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b7a:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0102b81:	f0 
f0102b82:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102b89:	00 
f0102b8a:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f0102b91:	e8 28 d5 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b96:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b9d:	00 
f0102b9e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102ba5:	00 
	return (void *)(pa + KERNBASE);
f0102ba6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bab:	89 04 24             	mov    %eax,(%esp)
f0102bae:	e8 f2 21 00 00       	call   f0104da5 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102bb3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102bba:	00 
f0102bbb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bc2:	00 
f0102bc3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102bc7:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0102bcc:	89 04 24             	mov    %eax,(%esp)
f0102bcf:	e8 4c e6 ff ff       	call   f0101220 <page_insert>
	assert(pp1->pp_ref == 1);
f0102bd4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102bd9:	74 24                	je     f0102bff <mem_init+0x1935>
f0102bdb:	c7 44 24 0c 30 61 10 	movl   $0xf0106130,0xc(%esp)
f0102be2:	f0 
f0102be3:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102bea:	f0 
f0102beb:	c7 44 24 04 c9 03 00 	movl   $0x3c9,0x4(%esp)
f0102bf2:	00 
f0102bf3:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102bfa:	e8 bf d4 ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102bff:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c06:	01 01 01 
f0102c09:	74 24                	je     f0102c2f <mem_init+0x1965>
f0102c0b:	c7 44 24 0c 78 5e 10 	movl   $0xf0105e78,0xc(%esp)
f0102c12:	f0 
f0102c13:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102c1a:	f0 
f0102c1b:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f0102c22:	00 
f0102c23:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102c2a:	e8 8f d4 ff ff       	call   f01000be <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c2f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c36:	00 
f0102c37:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c3e:	00 
f0102c3f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102c43:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0102c48:	89 04 24             	mov    %eax,(%esp)
f0102c4b:	e8 d0 e5 ff ff       	call   f0101220 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c50:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c57:	02 02 02 
f0102c5a:	74 24                	je     f0102c80 <mem_init+0x19b6>
f0102c5c:	c7 44 24 0c 9c 5e 10 	movl   $0xf0105e9c,0xc(%esp)
f0102c63:	f0 
f0102c64:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102c6b:	f0 
f0102c6c:	c7 44 24 04 cc 03 00 	movl   $0x3cc,0x4(%esp)
f0102c73:	00 
f0102c74:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102c7b:	e8 3e d4 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0102c80:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c85:	74 24                	je     f0102cab <mem_init+0x19e1>
f0102c87:	c7 44 24 0c 52 61 10 	movl   $0xf0106152,0xc(%esp)
f0102c8e:	f0 
f0102c8f:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102c96:	f0 
f0102c97:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0102c9e:	00 
f0102c9f:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102ca6:	e8 13 d4 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f0102cab:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cb0:	74 24                	je     f0102cd6 <mem_init+0x1a0c>
f0102cb2:	c7 44 24 0c 9b 61 10 	movl   $0xf010619b,0xc(%esp)
f0102cb9:	f0 
f0102cba:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102cc1:	f0 
f0102cc2:	c7 44 24 04 ce 03 00 	movl   $0x3ce,0x4(%esp)
f0102cc9:	00 
f0102cca:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102cd1:	e8 e8 d3 ff ff       	call   f01000be <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102cd6:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102cdd:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ce0:	89 f0                	mov    %esi,%eax
f0102ce2:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f0102ce8:	c1 f8 03             	sar    $0x3,%eax
f0102ceb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cee:	89 c2                	mov    %eax,%edx
f0102cf0:	c1 ea 0c             	shr    $0xc,%edx
f0102cf3:	3b 15 a4 ef 17 f0    	cmp    0xf017efa4,%edx
f0102cf9:	72 20                	jb     f0102d1b <mem_init+0x1a51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102cfb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102cff:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f0102d06:	f0 
f0102d07:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102d0e:	00 
f0102d0f:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f0102d16:	e8 a3 d3 ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d1b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d22:	03 03 03 
f0102d25:	74 24                	je     f0102d4b <mem_init+0x1a81>
f0102d27:	c7 44 24 0c c0 5e 10 	movl   $0xf0105ec0,0xc(%esp)
f0102d2e:	f0 
f0102d2f:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102d36:	f0 
f0102d37:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f0102d3e:	00 
f0102d3f:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102d46:	e8 73 d3 ff ff       	call   f01000be <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d4b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102d52:	00 
f0102d53:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0102d58:	89 04 24             	mov    %eax,(%esp)
f0102d5b:	e8 70 e4 ff ff       	call   f01011d0 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d60:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d65:	74 24                	je     f0102d8b <mem_init+0x1ac1>
f0102d67:	c7 44 24 0c 8a 61 10 	movl   $0xf010618a,0xc(%esp)
f0102d6e:	f0 
f0102d6f:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102d76:	f0 
f0102d77:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102d7e:	00 
f0102d7f:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102d86:	e8 33 d3 ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d8b:	a1 a8 ef 17 f0       	mov    0xf017efa8,%eax
f0102d90:	8b 08                	mov    (%eax),%ecx
f0102d92:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d98:	89 da                	mov    %ebx,%edx
f0102d9a:	2b 15 ac ef 17 f0    	sub    0xf017efac,%edx
f0102da0:	c1 fa 03             	sar    $0x3,%edx
f0102da3:	c1 e2 0c             	shl    $0xc,%edx
f0102da6:	39 d1                	cmp    %edx,%ecx
f0102da8:	74 24                	je     f0102dce <mem_init+0x1b04>
f0102daa:	c7 44 24 0c 3c 5a 10 	movl   $0xf0105a3c,0xc(%esp)
f0102db1:	f0 
f0102db2:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102db9:	f0 
f0102dba:	c7 44 24 04 d5 03 00 	movl   $0x3d5,0x4(%esp)
f0102dc1:	00 
f0102dc2:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102dc9:	e8 f0 d2 ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f0102dce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102dd4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102dd9:	74 24                	je     f0102dff <mem_init+0x1b35>
f0102ddb:	c7 44 24 0c 41 61 10 	movl   $0xf0106141,0xc(%esp)
f0102de2:	f0 
f0102de3:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0102dea:	f0 
f0102deb:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102df2:	00 
f0102df3:	c7 04 24 4d 5f 10 f0 	movl   $0xf0105f4d,(%esp)
f0102dfa:	e8 bf d2 ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f0102dff:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e05:	89 1c 24             	mov    %ebx,(%esp)
f0102e08:	e8 c2 e1 ff ff       	call   f0100fcf <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e0d:	c7 04 24 ec 5e 10 f0 	movl   $0xf0105eec,(%esp)
f0102e14:	e8 05 09 00 00       	call   f010371e <cprintf>
f0102e19:	eb 59                	jmp    f0102e74 <mem_init+0x1baa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102e1b:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102e1e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e21:	e8 ba db ff ff       	call   f01009e0 <check_va2pa>
f0102e26:	e9 96 fa ff ff       	jmp    f01028c1 <mem_init+0x15f7>
f0102e2b:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102e30:	89 d8                	mov    %ebx,%eax
f0102e32:	e8 a9 db ff ff       	call   f01009e0 <check_va2pa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102e37:	be 00 a0 11 00       	mov    $0x11a000,%esi
f0102e3c:	bf 00 80 bf df       	mov    $0xdfbf8000,%edi
f0102e41:	81 ef 00 20 11 f0    	sub    $0xf0112000,%edi
f0102e47:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0102e4a:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0102e4d:	e9 6f fa ff ff       	jmp    f01028c1 <mem_init+0x15f7>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102e52:	89 f2                	mov    %esi,%edx
f0102e54:	89 d8                	mov    %ebx,%eax
f0102e56:	e8 85 db ff ff       	call   f01009e0 <check_va2pa>
f0102e5b:	e9 cd f9 ff ff       	jmp    f010282d <mem_init+0x1563>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102e60:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e66:	89 d8                	mov    %ebx,%eax
f0102e68:	e8 73 db ff ff       	call   f01009e0 <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102e6d:	89 f2                	mov    %esi,%edx
f0102e6f:	e9 5a f9 ff ff       	jmp    f01027ce <mem_init+0x1504>
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();

}
f0102e74:	83 c4 3c             	add    $0x3c,%esp
f0102e77:	5b                   	pop    %ebx
f0102e78:	5e                   	pop    %esi
f0102e79:	5f                   	pop    %edi
f0102e7a:	5d                   	pop    %ebp
f0102e7b:	c3                   	ret    

f0102e7c <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e7c:	55                   	push   %ebp
f0102e7d:	89 e5                	mov    %esp,%ebp
f0102e7f:	57                   	push   %edi
f0102e80:	56                   	push   %esi
f0102e81:	53                   	push   %ebx
f0102e82:	83 ec 2c             	sub    $0x2c,%esp
f0102e85:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e88:	8b 45 0c             	mov    0xc(%ebp),%eax
	// LAB 3: Your code here.
	pte_t *pte;
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);
f0102e8b:	89 c2                	mov    %eax,%edx
f0102e8d:	03 55 10             	add    0x10(%ebp),%edx
f0102e90:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0102e96:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102e9c:	89 55 e4             	mov    %edx,-0x1c(%ebp)

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
f0102e9f:	39 d0                	cmp    %edx,%eax
f0102ea1:	73 5d                	jae    f0102f00 <user_mem_check+0x84>
		user_mem_check_addr = (uintptr_t)va; /* record the va */
f0102ea3:	89 c3                	mov    %eax,%ebx
f0102ea5:	a3 04 e3 17 f0       	mov    %eax,0xf017e304
		if(user_mem_check_addr > ULIM) /* below the ULIM */
			return -E_FAULT;
		if((pte = pgdir_walk(env->env_pgdir,va,0)) == NULL) /* No creation, and the pte is null */
			return -E_FAULT;
		if(!(*pte & (perm|PTE_P))) /* No permission */
f0102eaa:	8b 7d 14             	mov    0x14(%ebp),%edi
f0102ead:	83 cf 01             	or     $0x1,%edi
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
		user_mem_check_addr = (uintptr_t)va; /* record the va */
		if(user_mem_check_addr > ULIM) /* below the ULIM */
f0102eb0:	3d 00 00 80 ef       	cmp    $0xef800000,%eax
f0102eb5:	76 12                	jbe    f0102ec9 <user_mem_check+0x4d>
f0102eb7:	eb 4e                	jmp    f0102f07 <user_mem_check+0x8b>
	pte_t *pte;
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
		user_mem_check_addr = (uintptr_t)va; /* record the va */
f0102eb9:	89 c3                	mov    %eax,%ebx
f0102ebb:	a3 04 e3 17 f0       	mov    %eax,0xf017e304
		if(user_mem_check_addr > ULIM) /* below the ULIM */
f0102ec0:	3d 00 00 80 ef       	cmp    $0xef800000,%eax
f0102ec5:	76 02                	jbe    f0102ec9 <user_mem_check+0x4d>
f0102ec7:	eb 45                	jmp    f0102f0e <user_mem_check+0x92>
			return -E_FAULT;
		if((pte = pgdir_walk(env->env_pgdir,va,0)) == NULL) /* No creation, and the pte is null */
f0102ec9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102ed0:	00 
f0102ed1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ed5:	8b 46 5c             	mov    0x5c(%esi),%eax
f0102ed8:	89 04 24             	mov    %eax,(%esp)
f0102edb:	e8 2e e1 ff ff       	call   f010100e <pgdir_walk>
f0102ee0:	85 c0                	test   %eax,%eax
f0102ee2:	74 31                	je     f0102f15 <user_mem_check+0x99>
			return -E_FAULT;
		if(!(*pte & (perm|PTE_P))) /* No permission */
f0102ee4:	85 38                	test   %edi,(%eax)
f0102ee6:	74 34                	je     f0102f1c <user_mem_check+0xa0>
			return -E_FAULT;
		va = ROUNDDOWN(va, PGSIZE);
f0102ee8:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	// LAB 3: Your code here.
	pte_t *pte;
	void* uplim = (void *)ROUNDUP(va + len, PGSIZE);

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
f0102eee:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102ef4:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0102ef7:	77 c0                	ja     f0102eb9 <user_mem_check+0x3d>
			return -E_FAULT;
		if(!(*pte & (perm|PTE_P))) /* No permission */
			return -E_FAULT;
		va = ROUNDDOWN(va, PGSIZE);
	}
	return 0;
f0102ef9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102efe:	eb 21                	jmp    f0102f21 <user_mem_check+0xa5>
f0102f00:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f05:	eb 1a                	jmp    f0102f21 <user_mem_check+0xa5>

	/*pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)*/
	for(;va < uplim; va += PGSIZE){
		user_mem_check_addr = (uintptr_t)va; /* record the va */
		if(user_mem_check_addr > ULIM) /* below the ULIM */
			return -E_FAULT;
f0102f07:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102f0c:	eb 13                	jmp    f0102f21 <user_mem_check+0xa5>
f0102f0e:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102f13:	eb 0c                	jmp    f0102f21 <user_mem_check+0xa5>
		if((pte = pgdir_walk(env->env_pgdir,va,0)) == NULL) /* No creation, and the pte is null */
			return -E_FAULT;
f0102f15:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102f1a:	eb 05                	jmp    f0102f21 <user_mem_check+0xa5>
		if(!(*pte & (perm|PTE_P))) /* No permission */
			return -E_FAULT;
f0102f1c:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
		va = ROUNDDOWN(va, PGSIZE);
	}
	return 0;
}
f0102f21:	83 c4 2c             	add    $0x2c,%esp
f0102f24:	5b                   	pop    %ebx
f0102f25:	5e                   	pop    %esi
f0102f26:	5f                   	pop    %edi
f0102f27:	5d                   	pop    %ebp
f0102f28:	c3                   	ret    

f0102f29 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102f29:	55                   	push   %ebp
f0102f2a:	89 e5                	mov    %esp,%ebp
f0102f2c:	53                   	push   %ebx
f0102f2d:	83 ec 14             	sub    $0x14,%esp
f0102f30:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102f33:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f36:	83 c8 04             	or     $0x4,%eax
f0102f39:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f3d:	8b 45 10             	mov    0x10(%ebp),%eax
f0102f40:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f44:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f47:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f4b:	89 1c 24             	mov    %ebx,(%esp)
f0102f4e:	e8 29 ff ff ff       	call   f0102e7c <user_mem_check>
f0102f53:	85 c0                	test   %eax,%eax
f0102f55:	79 24                	jns    f0102f7b <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f57:	a1 04 e3 17 f0       	mov    0xf017e304,%eax
f0102f5c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f60:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f67:	c7 04 24 18 5f 10 f0 	movl   $0xf0105f18,(%esp)
f0102f6e:	e8 ab 07 00 00       	call   f010371e <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f73:	89 1c 24             	mov    %ebx,(%esp)
f0102f76:	e8 73 06 00 00       	call   f01035ee <env_destroy>
	}
}
f0102f7b:	83 c4 14             	add    $0x14,%esp
f0102f7e:	5b                   	pop    %ebx
f0102f7f:	5d                   	pop    %ebp
f0102f80:	c3                   	ret    
f0102f81:	66 90                	xchg   %ax,%ax
f0102f83:	90                   	nop

f0102f84 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f84:	55                   	push   %ebp
f0102f85:	89 e5                	mov    %esp,%ebp
f0102f87:	57                   	push   %edi
f0102f88:	56                   	push   %esi
f0102f89:	53                   	push   %ebx
f0102f8a:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	if(!len) /* If the len is zero panic immedatelly? or just return? */
f0102f8d:	85 c9                	test   %ecx,%ecx
f0102f8f:	75 1c                	jne    f0102fad <region_alloc+0x29>
		panic("Allocation failed!\n");
f0102f91:	c7 44 24 08 24 62 10 	movl   $0xf0106224,0x8(%esp)
f0102f98:	f0 
f0102f99:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
f0102fa0:	00 
f0102fa1:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0102fa8:	e8 11 d1 ff ff       	call   f01000be <_panic>
f0102fad:	89 c7                	mov    %eax,%edi
	void* up_lim = ROUNDUP(va + len, PGSIZE);
f0102faf:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102fb6:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	va = ROUNDDOWN(va, PGSIZE);
f0102fbc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102fc2:	89 d3                	mov    %edx,%ebx
	
	struct Page *p;
	for(;va < up_lim; va += PGSIZE){
f0102fc4:	39 d6                	cmp    %edx,%esi
f0102fc6:	76 71                	jbe    f0103039 <region_alloc+0xb5>
		if((p  = page_alloc(ALLOC_ZERO)) == NULL)
f0102fc8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0102fcf:	e8 77 df ff ff       	call   f0100f4b <page_alloc>
f0102fd4:	85 c0                	test   %eax,%eax
f0102fd6:	75 1c                	jne    f0102ff4 <region_alloc+0x70>
			panic("Allocation failed!\n");
f0102fd8:	c7 44 24 08 24 62 10 	movl   $0xf0106224,0x8(%esp)
f0102fdf:	f0 
f0102fe0:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f0102fe7:	00 
f0102fe8:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0102fef:	e8 ca d0 ff ff       	call   f01000be <_panic>
		if(page_insert(e->env_pgdir, p, va, PTE_U|PTE_W) < 0)
f0102ff4:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102ffb:	00 
f0102ffc:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103000:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103004:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103007:	89 04 24             	mov    %eax,(%esp)
f010300a:	e8 11 e2 ff ff       	call   f0101220 <page_insert>
f010300f:	85 c0                	test   %eax,%eax
f0103011:	79 1c                	jns    f010302f <region_alloc+0xab>
			panic("Allocation failed!\n");
f0103013:	c7 44 24 08 24 62 10 	movl   $0xf0106224,0x8(%esp)
f010301a:	f0 
f010301b:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
f0103022:	00 
f0103023:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f010302a:	e8 8f d0 ff ff       	call   f01000be <_panic>
		panic("Allocation failed!\n");
	void* up_lim = ROUNDUP(va + len, PGSIZE);
	va = ROUNDDOWN(va, PGSIZE);
	
	struct Page *p;
	for(;va < up_lim; va += PGSIZE){
f010302f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103035:	39 de                	cmp    %ebx,%esi
f0103037:	77 8f                	ja     f0102fc8 <region_alloc+0x44>
			panic("Allocation failed!\n");
		if(page_insert(e->env_pgdir, p, va, PTE_U|PTE_W) < 0)
			panic("Allocation failed!\n");
	}

}
f0103039:	83 c4 1c             	add    $0x1c,%esp
f010303c:	5b                   	pop    %ebx
f010303d:	5e                   	pop    %esi
f010303e:	5f                   	pop    %edi
f010303f:	5d                   	pop    %ebp
f0103040:	c3                   	ret    

f0103041 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103041:	55                   	push   %ebp
f0103042:	89 e5                	mov    %esp,%ebp
f0103044:	8b 45 08             	mov    0x8(%ebp),%eax
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103047:	85 c0                	test   %eax,%eax
f0103049:	75 11                	jne    f010305c <envid2env+0x1b>
		*env_store = curenv;
f010304b:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0103050:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103053:	89 02                	mov    %eax,(%edx)
		return 0;
f0103055:	b8 00 00 00 00       	mov    $0x0,%eax
f010305a:	eb 60                	jmp    f01030bc <envid2env+0x7b>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010305c:	89 c2                	mov    %eax,%edx
f010305e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103064:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103067:	c1 e2 05             	shl    $0x5,%edx
f010306a:	03 15 0c e3 17 f0    	add    0xf017e30c,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103070:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103074:	74 05                	je     f010307b <envid2env+0x3a>
f0103076:	39 42 48             	cmp    %eax,0x48(%edx)
f0103079:	74 10                	je     f010308b <envid2env+0x4a>
		*env_store = 0;
f010307b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010307e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0103084:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103089:	eb 31                	jmp    f01030bc <envid2env+0x7b>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010308b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010308f:	74 21                	je     f01030b2 <envid2env+0x71>
f0103091:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0103096:	39 c2                	cmp    %eax,%edx
f0103098:	74 18                	je     f01030b2 <envid2env+0x71>
f010309a:	8b 48 48             	mov    0x48(%eax),%ecx
f010309d:	39 4a 4c             	cmp    %ecx,0x4c(%edx)
f01030a0:	74 10                	je     f01030b2 <envid2env+0x71>
		*env_store = 0;
f01030a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030a5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01030ab:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01030b0:	eb 0a                	jmp    f01030bc <envid2env+0x7b>
	}

	*env_store = e;
f01030b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030b5:	89 11                	mov    %edx,(%ecx)
	return 0;
f01030b7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030bc:	5d                   	pop    %ebp
f01030bd:	c3                   	ret    

f01030be <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01030be:	55                   	push   %ebp
f01030bf:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01030c1:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f01030c6:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01030c9:	b8 23 00 00 00       	mov    $0x23,%eax
f01030ce:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01030d0:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01030d2:	b0 10                	mov    $0x10,%al
f01030d4:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01030d6:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01030d8:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01030da:	ea e1 30 10 f0 08 00 	ljmp   $0x8,$0xf01030e1
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01030e1:	b0 00                	mov    $0x0,%al
f01030e3:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01030e6:	5d                   	pop    %ebp
f01030e7:	c3                   	ret    

f01030e8 <env_init>:
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	size_t i;
	struct Env *cur_env = envs+ NENV - 1, *ptr;
f01030e8:	8b 0d 0c e3 17 f0    	mov    0xf017e30c,%ecx
f01030ee:	8d 81 a0 7f 01 00    	lea    0x17fa0(%ecx),%eax
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
f01030f4:	8d 51 a0             	lea    -0x60(%ecx),%edx
	// Set up envs array
	// LAB 3: Your code here.
	size_t i;
	struct Env *cur_env = envs+ NENV - 1, *ptr;
	for(i = 0; i < NENV; i++){
		cur_env -> env_status = ENV_FREE;
f01030f7:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		cur_env -> env_id = 0;
f01030fe:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		ptr = cur_env;
		ptr++;
		cur_env--;
f0103105:	83 e8 60             	sub    $0x60,%eax
{
	// Set up envs array
	// LAB 3: Your code here.
	size_t i;
	struct Env *cur_env = envs+ NENV - 1, *ptr;
	for(i = 0; i < NENV; i++){
f0103108:	39 d0                	cmp    %edx,%eax
f010310a:	75 eb                	jne    f01030f7 <env_init+0xf>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010310c:	55                   	push   %ebp
f010310d:	89 e5                	mov    %esp,%ebp
		cur_env -> env_id = 0;
		ptr = cur_env;
		ptr++;
		cur_env--;
	}
	env_free_list = ptr - 1;
f010310f:	89 0d 10 e3 17 f0    	mov    %ecx,0xf017e310
	// Per-CPU part of the initialization
	env_init_percpu();
f0103115:	e8 a4 ff ff ff       	call   f01030be <env_init_percpu>
}
f010311a:	5d                   	pop    %ebp
f010311b:	c3                   	ret    

f010311c <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010311c:	55                   	push   %ebp
f010311d:	89 e5                	mov    %esp,%ebp
f010311f:	56                   	push   %esi
f0103120:	53                   	push   %ebx
f0103121:	83 ec 10             	sub    $0x10,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103124:	8b 1d 10 e3 17 f0    	mov    0xf017e310,%ebx
f010312a:	85 db                	test   %ebx,%ebx
f010312c:	0f 84 85 01 00 00    	je     f01032b7 <env_alloc+0x19b>
{
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103132:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103139:	e8 0d de ff ff       	call   f0100f4b <page_alloc>
f010313e:	89 c6                	mov    %eax,%esi
f0103140:	85 c0                	test   %eax,%eax
f0103142:	0f 84 76 01 00 00    	je     f01032be <env_alloc+0x1a2>
f0103148:	2b 05 ac ef 17 f0    	sub    0xf017efac,%eax
f010314e:	c1 f8 03             	sar    $0x3,%eax
f0103151:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103154:	89 c2                	mov    %eax,%edx
f0103156:	c1 ea 0c             	shr    $0xc,%edx
f0103159:	3b 15 a4 ef 17 f0    	cmp    0xf017efa4,%edx
f010315f:	72 20                	jb     f0103181 <env_alloc+0x65>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103161:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103165:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f010316c:	f0 
f010316d:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103174:	00 
f0103175:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f010317c:	e8 3d cf ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0103181:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	/* e->env_pgdir is a pte_t* */
	e -> env_pgdir = (pte_t *)page2kva(p);
f0103186:	89 43 5c             	mov    %eax,0x5c(%ebx)

	memmove(e -> env_pgdir , kern_pgdir, PGSIZE);
f0103189:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103190:	00 
f0103191:	8b 15 a8 ef 17 f0    	mov    0xf017efa8,%edx
f0103197:	89 54 24 04          	mov    %edx,0x4(%esp)
f010319b:	89 04 24             	mov    %eax,(%esp)
f010319e:	e8 60 1c 00 00       	call   f0104e03 <memmove>
	memset(e -> env_pgdir, 0 , PDX(UTOP)*sizeof(pde_t));
f01031a3:	c7 44 24 08 ec 0e 00 	movl   $0xeec,0x8(%esp)
f01031aa:	00 
f01031ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01031b2:	00 
f01031b3:	8b 43 5c             	mov    0x5c(%ebx),%eax
f01031b6:	89 04 24             	mov    %eax,(%esp)
f01031b9:	e8 e7 1b 00 00       	call   f0104da5 <memset>

	p -> pp_ref++;
f01031be:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01031c3:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031c6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031cb:	77 20                	ja     f01031ed <env_alloc+0xd1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031d1:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f01031d8:	f0 
f01031d9:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
f01031e0:	00 
f01031e1:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f01031e8:	e8 d1 ce ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01031ed:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01031f3:	83 ca 05             	or     $0x5,%edx
f01031f6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01031fc:	8b 43 48             	mov    0x48(%ebx),%eax
f01031ff:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103204:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103209:	ba 00 10 00 00       	mov    $0x1000,%edx
f010320e:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103211:	89 da                	mov    %ebx,%edx
f0103213:	2b 15 0c e3 17 f0    	sub    0xf017e30c,%edx
f0103219:	c1 fa 05             	sar    $0x5,%edx
f010321c:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103222:	09 d0                	or     %edx,%eax
f0103224:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103227:	8b 45 0c             	mov    0xc(%ebp),%eax
f010322a:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010322d:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103234:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f010323b:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103242:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103249:	00 
f010324a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103251:	00 
f0103252:	89 1c 24             	mov    %ebx,(%esp)
f0103255:	e8 4b 1b 00 00       	call   f0104da5 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010325a:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103260:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103266:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010326c:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103273:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103279:	8b 43 44             	mov    0x44(%ebx),%eax
f010327c:	a3 10 e3 17 f0       	mov    %eax,0xf017e310
	*newenv_store = e;
f0103281:	8b 45 08             	mov    0x8(%ebp),%eax
f0103284:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103286:	8b 53 48             	mov    0x48(%ebx),%edx
f0103289:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f010328e:	85 c0                	test   %eax,%eax
f0103290:	74 05                	je     f0103297 <env_alloc+0x17b>
f0103292:	8b 40 48             	mov    0x48(%eax),%eax
f0103295:	eb 05                	jmp    f010329c <env_alloc+0x180>
f0103297:	b8 00 00 00 00       	mov    $0x0,%eax
f010329c:	89 54 24 08          	mov    %edx,0x8(%esp)
f01032a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032a4:	c7 04 24 43 62 10 f0 	movl   $0xf0106243,(%esp)
f01032ab:	e8 6e 04 00 00       	call   f010371e <cprintf>
	return 0;
f01032b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01032b5:	eb 0c                	jmp    f01032c3 <env_alloc+0x1a7>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01032b7:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01032bc:	eb 05                	jmp    f01032c3 <env_alloc+0x1a7>
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01032be:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01032c3:	83 c4 10             	add    $0x10,%esp
f01032c6:	5b                   	pop    %ebx
f01032c7:	5e                   	pop    %esi
f01032c8:	5d                   	pop    %ebp
f01032c9:	c3                   	ret    

f01032ca <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size, enum EnvType type)
{
f01032ca:	55                   	push   %ebp
f01032cb:	89 e5                	mov    %esp,%ebp
f01032cd:	57                   	push   %edi
f01032ce:	56                   	push   %esi
f01032cf:	53                   	push   %ebx
f01032d0:	83 ec 3c             	sub    $0x3c,%esp
f01032d3:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;

	if((r = env_alloc(&e, 0)) < 0)
f01032d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01032dd:	00 
f01032de:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01032e1:	89 04 24             	mov    %eax,(%esp)
f01032e4:	e8 33 fe ff ff       	call   f010311c <env_alloc>
f01032e9:	85 c0                	test   %eax,%eax
f01032eb:	79 20                	jns    f010330d <env_create+0x43>
		panic("env alloc failed! %e\n",r);
f01032ed:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032f1:	c7 44 24 08 58 62 10 	movl   $0xf0106258,0x8(%esp)
f01032f8:	f0 
f01032f9:	c7 44 24 04 98 01 00 	movl   $0x198,0x4(%esp)
f0103300:	00 
f0103301:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0103308:	e8 b1 cd ff ff       	call   f01000be <_panic>
	/* load_icode(struct Env *e, uint8_t *binary, size_t size) */
	load_icode(e, binary, size);
f010330d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103310:	89 45 d4             	mov    %eax,-0x2c(%ebp)

static __inline uint32_t
rcr3(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr3,%0" : "=r" (val));
f0103313:	0f 20 da             	mov    %cr3,%edx
f0103316:	89 55 d0             	mov    %edx,-0x30(%ebp)
	struct Proghdr *ph, *eph; /* see inc/elf.h */
	struct Elf *ELFHDR = (struct Elf *)binary;
	uint32_t cr3 = rcr3();

	/* just copy from boot/main.c */
	if (ELFHDR->e_magic != ELF_MAGIC)
f0103319:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010331f:	74 1c                	je     f010333d <env_create+0x73>
		panic("Invalid ELF!\n");
f0103321:	c7 44 24 08 6e 62 10 	movl   $0xf010626e,0x8(%esp)
f0103328:	f0 
f0103329:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f0103330:	00 
f0103331:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0103338:	e8 81 cd ff ff       	call   f01000be <_panic>
	lcr3(PADDR(e -> env_pgdir));
f010333d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103340:	8b 42 5c             	mov    0x5c(%edx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103343:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103348:	77 20                	ja     f010336a <env_create+0xa0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010334a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010334e:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f0103355:	f0 
f0103356:	c7 44 24 04 6a 01 00 	movl   $0x16a,0x4(%esp)
f010335d:	00 
f010335e:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0103365:	e8 54 cd ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f010336a:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010336f:	0f 22 d8             	mov    %eax,%cr3
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0103372:	89 fb                	mov    %edi,%ebx
f0103374:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0103377:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f010337b:	c1 e6 05             	shl    $0x5,%esi
f010337e:	01 de                	add    %ebx,%esi

	for (; ph < eph; ph++){
f0103380:	39 f3                	cmp    %esi,%ebx
f0103382:	73 4f                	jae    f01033d3 <env_create+0x109>
		// p_pa is the load address of this segment (as well
		// as the physical address)
		if( ph->p_type == ELF_PROG_LOAD ){
f0103384:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103387:	75 43                	jne    f01033cc <env_create+0x102>
			/* alloc p_memsz physical memory for e*/
			region_alloc(e, (void *)ph -> p_va, ph -> p_memsz); 
f0103389:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010338c:	8b 53 08             	mov    0x8(%ebx),%edx
f010338f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103392:	e8 ed fb ff ff       	call   f0102f84 <region_alloc>
			/* set zero filled */
			//panic("%x", ph);
			memset((void *)ph->p_va, 0x0 , ph->p_memsz);
f0103397:	8b 43 14             	mov    0x14(%ebx),%eax
f010339a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010339e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01033a5:	00 
f01033a6:	8b 43 08             	mov    0x8(%ebx),%eax
f01033a9:	89 04 24             	mov    %eax,(%esp)
f01033ac:	e8 f4 19 00 00       	call   f0104da5 <memset>
			/* inc/string.h : void * memmove(void *dst, const void *src, size_t len); */
			memmove((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f01033b1:	8b 43 10             	mov    0x10(%ebx),%eax
f01033b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033b8:	89 f8                	mov    %edi,%eax
f01033ba:	03 43 04             	add    0x4(%ebx),%eax
f01033bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033c1:	8b 43 08             	mov    0x8(%ebx),%eax
f01033c4:	89 04 24             	mov    %eax,(%esp)
f01033c7:	e8 37 1a 00 00       	call   f0104e03 <memmove>
		panic("Invalid ELF!\n");
	lcr3(PADDR(e -> env_pgdir));
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;

	for (; ph < eph; ph++){
f01033cc:	83 c3 20             	add    $0x20,%ebx
f01033cf:	39 de                	cmp    %ebx,%esi
f01033d1:	77 b1                	ja     f0103384 <env_create+0xba>
		}

	}
	//((void (*)(void)) (ELFHDR->e_entry))();

	e -> env_tf.tf_eip = ELFHDR -> e_entry;
f01033d3:	8b 47 18             	mov    0x18(%edi),%eax
f01033d6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01033d9:	89 42 30             	mov    %eax,0x30(%edx)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
f01033dc:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01033e1:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01033e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033e9:	e8 96 fb ff ff       	call   f0102f84 <region_alloc>
f01033ee:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01033f1:	0f 22 d8             	mov    %eax,%cr3

	if((r = env_alloc(&e, 0)) < 0)
		panic("env alloc failed! %e\n",r);
	/* load_icode(struct Env *e, uint8_t *binary, size_t size) */
	load_icode(e, binary, size);
	e -> env_type = type;
f01033f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033f7:	8b 55 10             	mov    0x10(%ebp),%edx
f01033fa:	89 50 50             	mov    %edx,0x50(%eax)
}
f01033fd:	83 c4 3c             	add    $0x3c,%esp
f0103400:	5b                   	pop    %ebx
f0103401:	5e                   	pop    %esi
f0103402:	5f                   	pop    %edi
f0103403:	5d                   	pop    %ebp
f0103404:	c3                   	ret    

f0103405 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103405:	55                   	push   %ebp
f0103406:	89 e5                	mov    %esp,%ebp
f0103408:	57                   	push   %edi
f0103409:	56                   	push   %esi
f010340a:	53                   	push   %ebx
f010340b:	83 ec 2c             	sub    $0x2c,%esp
f010340e:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103411:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0103416:	39 c7                	cmp    %eax,%edi
f0103418:	75 37                	jne    f0103451 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f010341a:	8b 15 a8 ef 17 f0    	mov    0xf017efa8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103420:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103426:	77 20                	ja     f0103448 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103428:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010342c:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f0103433:	f0 
f0103434:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
f010343b:	00 
f010343c:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0103443:	e8 76 cc ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103448:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010344e:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103451:	8b 57 48             	mov    0x48(%edi),%edx
f0103454:	85 c0                	test   %eax,%eax
f0103456:	74 05                	je     f010345d <env_free+0x58>
f0103458:	8b 40 48             	mov    0x48(%eax),%eax
f010345b:	eb 05                	jmp    f0103462 <env_free+0x5d>
f010345d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103462:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103466:	89 44 24 04          	mov    %eax,0x4(%esp)
f010346a:	c7 04 24 7c 62 10 f0 	movl   $0xf010627c,(%esp)
f0103471:	e8 a8 02 00 00       	call   f010371e <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103476:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
f010347d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103480:	c1 e0 02             	shl    $0x2,%eax
f0103483:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103486:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103489:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010348c:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010348f:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103495:	0f 84 b7 00 00 00    	je     f0103552 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010349b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034a1:	89 f0                	mov    %esi,%eax
f01034a3:	c1 e8 0c             	shr    $0xc,%eax
f01034a6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01034a9:	3b 05 a4 ef 17 f0    	cmp    0xf017efa4,%eax
f01034af:	72 20                	jb     f01034d1 <env_free+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01034b1:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01034b5:	c7 44 24 08 fc 57 10 	movl   $0xf01057fc,0x8(%esp)
f01034bc:	f0 
f01034bd:	c7 44 24 04 bb 01 00 	movl   $0x1bb,0x4(%esp)
f01034c4:	00 
f01034c5:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f01034cc:	e8 ed cb ff ff       	call   f01000be <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034d1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01034d4:	c1 e2 16             	shl    $0x16,%edx
f01034d7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034da:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01034df:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01034e6:	01 
f01034e7:	74 17                	je     f0103500 <env_free+0xfb>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034e9:	89 d8                	mov    %ebx,%eax
f01034eb:	c1 e0 0c             	shl    $0xc,%eax
f01034ee:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01034f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034f5:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034f8:	89 04 24             	mov    %eax,(%esp)
f01034fb:	e8 d0 dc ff ff       	call   f01011d0 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103500:	83 c3 01             	add    $0x1,%ebx
f0103503:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103509:	75 d4                	jne    f01034df <env_free+0xda>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010350b:	8b 47 5c             	mov    0x5c(%edi),%eax
f010350e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103511:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103518:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010351b:	3b 05 a4 ef 17 f0    	cmp    0xf017efa4,%eax
f0103521:	72 1c                	jb     f010353f <env_free+0x13a>
		panic("pa2page called with invalid pa");
f0103523:	c7 44 24 08 08 59 10 	movl   $0xf0105908,0x8(%esp)
f010352a:	f0 
f010352b:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103532:	00 
f0103533:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f010353a:	e8 7f cb ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f010353f:	a1 ac ef 17 f0       	mov    0xf017efac,%eax
f0103544:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103547:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f010354a:	89 04 24             	mov    %eax,(%esp)
f010354d:	e8 99 da ff ff       	call   f0100feb <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103552:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103556:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f010355d:	0f 85 1a ff ff ff    	jne    f010347d <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103563:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103566:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010356b:	77 20                	ja     f010358d <env_free+0x188>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010356d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103571:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f0103578:	f0 
f0103579:	c7 44 24 04 c9 01 00 	movl   $0x1c9,0x4(%esp)
f0103580:	00 
f0103581:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0103588:	e8 31 cb ff ff       	call   f01000be <_panic>
	e->env_pgdir = 0;
f010358d:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103594:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103599:	c1 e8 0c             	shr    $0xc,%eax
f010359c:	3b 05 a4 ef 17 f0    	cmp    0xf017efa4,%eax
f01035a2:	72 1c                	jb     f01035c0 <env_free+0x1bb>
		panic("pa2page called with invalid pa");
f01035a4:	c7 44 24 08 08 59 10 	movl   $0xf0105908,0x8(%esp)
f01035ab:	f0 
f01035ac:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01035b3:	00 
f01035b4:	c7 04 24 6e 5f 10 f0 	movl   $0xf0105f6e,(%esp)
f01035bb:	e8 fe ca ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f01035c0:	8b 15 ac ef 17 f0    	mov    0xf017efac,%edx
f01035c6:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f01035c9:	89 04 24             	mov    %eax,(%esp)
f01035cc:	e8 1a da ff ff       	call   f0100feb <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01035d1:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01035d8:	a1 10 e3 17 f0       	mov    0xf017e310,%eax
f01035dd:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01035e0:	89 3d 10 e3 17 f0    	mov    %edi,0xf017e310
}
f01035e6:	83 c4 2c             	add    $0x2c,%esp
f01035e9:	5b                   	pop    %ebx
f01035ea:	5e                   	pop    %esi
f01035eb:	5f                   	pop    %edi
f01035ec:	5d                   	pop    %ebp
f01035ed:	c3                   	ret    

f01035ee <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01035ee:	55                   	push   %ebp
f01035ef:	89 e5                	mov    %esp,%ebp
f01035f1:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f01035f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01035f7:	89 04 24             	mov    %eax,(%esp)
f01035fa:	e8 06 fe ff ff       	call   f0103405 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01035ff:	c7 04 24 a0 62 10 f0 	movl   $0xf01062a0,(%esp)
f0103606:	e8 13 01 00 00       	call   f010371e <cprintf>
	while (1)
		monitor(NULL);
f010360b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103612:	e8 69 d2 ff ff       	call   f0100880 <monitor>
f0103617:	eb f2                	jmp    f010360b <env_destroy+0x1d>

f0103619 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103619:	55                   	push   %ebp
f010361a:	89 e5                	mov    %esp,%ebp
f010361c:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f010361f:	8b 65 08             	mov    0x8(%ebp),%esp
f0103622:	61                   	popa   
f0103623:	07                   	pop    %es
f0103624:	1f                   	pop    %ds
f0103625:	83 c4 08             	add    $0x8,%esp
f0103628:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103629:	c7 44 24 08 92 62 10 	movl   $0xf0106292,0x8(%esp)
f0103630:	f0 
f0103631:	c7 44 24 04 f1 01 00 	movl   $0x1f1,0x4(%esp)
f0103638:	00 
f0103639:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0103640:	e8 79 ca ff ff       	call   f01000be <_panic>

f0103645 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103645:	55                   	push   %ebp
f0103646:	89 e5                	mov    %esp,%ebp
f0103648:	83 ec 18             	sub    $0x18,%esp
f010364b:	8b 45 08             	mov    0x8(%ebp),%eax
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	if(curenv != NULL)
f010364e:	8b 15 08 e3 17 f0    	mov    0xf017e308,%edx
f0103654:	85 d2                	test   %edx,%edx
f0103656:	74 07                	je     f010365f <env_run+0x1a>
		curenv -> env_status = ENV_RUNNABLE;
f0103658:	c7 42 54 01 00 00 00 	movl   $0x1,0x54(%edx)

	curenv = e;
f010365f:	a3 08 e3 17 f0       	mov    %eax,0xf017e308
	curenv -> env_status = ENV_RUNNING;
f0103664:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv -> env_runs++;
f010366b:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv -> env_pgdir));
f010366f:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103672:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103678:	77 20                	ja     f010369a <env_run+0x55>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010367a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010367e:	c7 44 24 08 e4 58 10 	movl   $0xf01058e4,0x8(%esp)
f0103685:	f0 
f0103686:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
f010368d:	00 
f010368e:	c7 04 24 38 62 10 f0 	movl   $0xf0106238,(%esp)
f0103695:	e8 24 ca ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f010369a:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01036a0:	0f 22 da             	mov    %edx,%cr3

	env_pop_tf(&(e -> env_tf));
f01036a3:	89 04 24             	mov    %eax,(%esp)
f01036a6:	e8 6e ff ff ff       	call   f0103619 <env_pop_tf>
f01036ab:	90                   	nop

f01036ac <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036ac:	55                   	push   %ebp
f01036ad:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01036af:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036b3:	ba 70 00 00 00       	mov    $0x70,%edx
f01036b8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01036b9:	b2 71                	mov    $0x71,%dl
f01036bb:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01036bc:	0f b6 c0             	movzbl %al,%eax
}
f01036bf:	5d                   	pop    %ebp
f01036c0:	c3                   	ret    

f01036c1 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01036c1:	55                   	push   %ebp
f01036c2:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01036c4:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036c8:	ba 70 00 00 00       	mov    $0x70,%edx
f01036cd:	ee                   	out    %al,(%dx)
f01036ce:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f01036d2:	b2 71                	mov    $0x71,%dl
f01036d4:	ee                   	out    %al,(%dx)
f01036d5:	5d                   	pop    %ebp
f01036d6:	c3                   	ret    
f01036d7:	90                   	nop

f01036d8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01036d8:	55                   	push   %ebp
f01036d9:	89 e5                	mov    %esp,%ebp
f01036db:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01036de:	8b 45 08             	mov    0x8(%ebp),%eax
f01036e1:	89 04 24             	mov    %eax,(%esp)
f01036e4:	e8 43 cf ff ff       	call   f010062c <cputchar>
	*cnt++;
}
f01036e9:	c9                   	leave  
f01036ea:	c3                   	ret    

f01036eb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01036eb:	55                   	push   %ebp
f01036ec:	89 e5                	mov    %esp,%ebp
f01036ee:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01036f1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01036f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103702:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103706:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103709:	89 44 24 04          	mov    %eax,0x4(%esp)
f010370d:	c7 04 24 d8 36 10 f0 	movl   $0xf01036d8,(%esp)
f0103714:	e8 29 0f 00 00       	call   f0104642 <vprintfmt>
	return cnt;
}
f0103719:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010371c:	c9                   	leave  
f010371d:	c3                   	ret    

f010371e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010371e:	55                   	push   %ebp
f010371f:	89 e5                	mov    %esp,%ebp
f0103721:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103724:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103727:	89 44 24 04          	mov    %eax,0x4(%esp)
f010372b:	8b 45 08             	mov    0x8(%ebp),%eax
f010372e:	89 04 24             	mov    %eax,(%esp)
f0103731:	e8 b5 ff ff ff       	call   f01036eb <vcprintf>
	va_end(ap);

	return cnt;
}
f0103736:	c9                   	leave  
f0103737:	c3                   	ret    
f0103738:	66 90                	xchg   %ax,%ax
f010373a:	66 90                	xchg   %ax,%ax
f010373c:	66 90                	xchg   %ax,%ax
f010373e:	66 90                	xchg   %ax,%ax

f0103740 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103740:	55                   	push   %ebp
f0103741:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103743:	c7 05 24 eb 17 f0 00 	movl   $0xefc00000,0xf017eb24
f010374a:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f010374d:	66 c7 05 28 eb 17 f0 	movw   $0x10,0xf017eb28
f0103754:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103756:	66 c7 05 48 c3 11 f0 	movw   $0x68,0xf011c348
f010375d:	68 00 
f010375f:	b8 20 eb 17 f0       	mov    $0xf017eb20,%eax
f0103764:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f010376a:	89 c2                	mov    %eax,%edx
f010376c:	c1 ea 10             	shr    $0x10,%edx
f010376f:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f0103775:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f010377c:	c1 e8 18             	shr    $0x18,%eax
f010377f:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103784:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010378b:	b8 28 00 00 00       	mov    $0x28,%eax
f0103790:	0f 00 d8             	ltr    %ax
}  

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103793:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f0103798:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010379b:	5d                   	pop    %ebp
f010379c:	c3                   	ret    

f010379d <trap_init>:
}


void
trap_init(void)
{
f010379d:	55                   	push   %ebp
f010379e:	89 e5                	mov    %esp,%ebp
	extern void Machine_Check();
	extern void SIMD_Floating_Point_Exception();
	extern void System_call();

	/* SETGATE(Gatedesc, istrap[1/0], sel, off, dpl) -- inc/mmu.h*/
	SETGATE(idt[T_DIVIDE] ,0, GD_KT, Divide_error, 0);
f01037a0:	b8 00 3f 10 f0       	mov    $0xf0103f00,%eax
f01037a5:	66 a3 20 e3 17 f0    	mov    %ax,0xf017e320
f01037ab:	66 c7 05 22 e3 17 f0 	movw   $0x8,0xf017e322
f01037b2:	08 00 
f01037b4:	c6 05 24 e3 17 f0 00 	movb   $0x0,0xf017e324
f01037bb:	c6 05 25 e3 17 f0 8e 	movb   $0x8e,0xf017e325
f01037c2:	c1 e8 10             	shr    $0x10,%eax
f01037c5:	66 a3 26 e3 17 f0    	mov    %ax,0xf017e326
	SETGATE(idt[T_DEBUG] ,0, GD_KT, Debug, 0);
f01037cb:	b8 06 3f 10 f0       	mov    $0xf0103f06,%eax
f01037d0:	66 a3 28 e3 17 f0    	mov    %ax,0xf017e328
f01037d6:	66 c7 05 2a e3 17 f0 	movw   $0x8,0xf017e32a
f01037dd:	08 00 
f01037df:	c6 05 2c e3 17 f0 00 	movb   $0x0,0xf017e32c
f01037e6:	c6 05 2d e3 17 f0 8e 	movb   $0x8e,0xf017e32d
f01037ed:	c1 e8 10             	shr    $0x10,%eax
f01037f0:	66 a3 2e e3 17 f0    	mov    %ax,0xf017e32e
	SETGATE(idt[T_NMI] ,0, GD_KT, Non_Maskable_Interrupt, 0);
f01037f6:	b8 0c 3f 10 f0       	mov    $0xf0103f0c,%eax
f01037fb:	66 a3 30 e3 17 f0    	mov    %ax,0xf017e330
f0103801:	66 c7 05 32 e3 17 f0 	movw   $0x8,0xf017e332
f0103808:	08 00 
f010380a:	c6 05 34 e3 17 f0 00 	movb   $0x0,0xf017e334
f0103811:	c6 05 35 e3 17 f0 8e 	movb   $0x8e,0xf017e335
f0103818:	c1 e8 10             	shr    $0x10,%eax
f010381b:	66 a3 36 e3 17 f0    	mov    %ax,0xf017e336
	SETGATE(idt[T_BRKPT] ,0, GD_KT, Breakpoint, 3);
f0103821:	b8 12 3f 10 f0       	mov    $0xf0103f12,%eax
f0103826:	66 a3 38 e3 17 f0    	mov    %ax,0xf017e338
f010382c:	66 c7 05 3a e3 17 f0 	movw   $0x8,0xf017e33a
f0103833:	08 00 
f0103835:	c6 05 3c e3 17 f0 00 	movb   $0x0,0xf017e33c
f010383c:	c6 05 3d e3 17 f0 ee 	movb   $0xee,0xf017e33d
f0103843:	c1 e8 10             	shr    $0x10,%eax
f0103846:	66 a3 3e e3 17 f0    	mov    %ax,0xf017e33e
	SETGATE(idt[T_OFLOW] ,0, GD_KT, Overflow, 0);
f010384c:	b8 18 3f 10 f0       	mov    $0xf0103f18,%eax
f0103851:	66 a3 40 e3 17 f0    	mov    %ax,0xf017e340
f0103857:	66 c7 05 42 e3 17 f0 	movw   $0x8,0xf017e342
f010385e:	08 00 
f0103860:	c6 05 44 e3 17 f0 00 	movb   $0x0,0xf017e344
f0103867:	c6 05 45 e3 17 f0 8e 	movb   $0x8e,0xf017e345
f010386e:	c1 e8 10             	shr    $0x10,%eax
f0103871:	66 a3 46 e3 17 f0    	mov    %ax,0xf017e346
	SETGATE(idt[T_BOUND] ,0, GD_KT, BOUND_Range_Exceeded, 0);
f0103877:	b8 1e 3f 10 f0       	mov    $0xf0103f1e,%eax
f010387c:	66 a3 48 e3 17 f0    	mov    %ax,0xf017e348
f0103882:	66 c7 05 4a e3 17 f0 	movw   $0x8,0xf017e34a
f0103889:	08 00 
f010388b:	c6 05 4c e3 17 f0 00 	movb   $0x0,0xf017e34c
f0103892:	c6 05 4d e3 17 f0 8e 	movb   $0x8e,0xf017e34d
f0103899:	c1 e8 10             	shr    $0x10,%eax
f010389c:	66 a3 4e e3 17 f0    	mov    %ax,0xf017e34e
	SETGATE(idt[T_ILLOP] ,0, GD_KT, Invalid_Opcode, 0);
f01038a2:	b8 24 3f 10 f0       	mov    $0xf0103f24,%eax
f01038a7:	66 a3 50 e3 17 f0    	mov    %ax,0xf017e350
f01038ad:	66 c7 05 52 e3 17 f0 	movw   $0x8,0xf017e352
f01038b4:	08 00 
f01038b6:	c6 05 54 e3 17 f0 00 	movb   $0x0,0xf017e354
f01038bd:	c6 05 55 e3 17 f0 8e 	movb   $0x8e,0xf017e355
f01038c4:	c1 e8 10             	shr    $0x10,%eax
f01038c7:	66 a3 56 e3 17 f0    	mov    %ax,0xf017e356
	SETGATE(idt[T_DEVICE] ,0, GD_KT, Device_Not_Available, 0);
f01038cd:	b8 2a 3f 10 f0       	mov    $0xf0103f2a,%eax
f01038d2:	66 a3 58 e3 17 f0    	mov    %ax,0xf017e358
f01038d8:	66 c7 05 5a e3 17 f0 	movw   $0x8,0xf017e35a
f01038df:	08 00 
f01038e1:	c6 05 5c e3 17 f0 00 	movb   $0x0,0xf017e35c
f01038e8:	c6 05 5d e3 17 f0 8e 	movb   $0x8e,0xf017e35d
f01038ef:	c1 e8 10             	shr    $0x10,%eax
f01038f2:	66 a3 5e e3 17 f0    	mov    %ax,0xf017e35e
	SETGATE(idt[T_DBLFLT] ,0, GD_KT, Double_Fault, 0);
f01038f8:	b8 30 3f 10 f0       	mov    $0xf0103f30,%eax
f01038fd:	66 a3 60 e3 17 f0    	mov    %ax,0xf017e360
f0103903:	66 c7 05 62 e3 17 f0 	movw   $0x8,0xf017e362
f010390a:	08 00 
f010390c:	c6 05 64 e3 17 f0 00 	movb   $0x0,0xf017e364
f0103913:	c6 05 65 e3 17 f0 8e 	movb   $0x8e,0xf017e365
f010391a:	c1 e8 10             	shr    $0x10,%eax
f010391d:	66 a3 66 e3 17 f0    	mov    %ax,0xf017e366
	SETGATE(idt[T_TSS] ,0, GD_KT, Invalid_TSS, 0);
f0103923:	b8 34 3f 10 f0       	mov    $0xf0103f34,%eax
f0103928:	66 a3 70 e3 17 f0    	mov    %ax,0xf017e370
f010392e:	66 c7 05 72 e3 17 f0 	movw   $0x8,0xf017e372
f0103935:	08 00 
f0103937:	c6 05 74 e3 17 f0 00 	movb   $0x0,0xf017e374
f010393e:	c6 05 75 e3 17 f0 8e 	movb   $0x8e,0xf017e375
f0103945:	c1 e8 10             	shr    $0x10,%eax
f0103948:	66 a3 76 e3 17 f0    	mov    %ax,0xf017e376
	SETGATE(idt[T_SEGNP] ,0, GD_KT, Segment_Not_Present, 0);
f010394e:	b8 38 3f 10 f0       	mov    $0xf0103f38,%eax
f0103953:	66 a3 78 e3 17 f0    	mov    %ax,0xf017e378
f0103959:	66 c7 05 7a e3 17 f0 	movw   $0x8,0xf017e37a
f0103960:	08 00 
f0103962:	c6 05 7c e3 17 f0 00 	movb   $0x0,0xf017e37c
f0103969:	c6 05 7d e3 17 f0 8e 	movb   $0x8e,0xf017e37d
f0103970:	c1 e8 10             	shr    $0x10,%eax
f0103973:	66 a3 7e e3 17 f0    	mov    %ax,0xf017e37e
	SETGATE(idt[T_STACK] ,0, GD_KT, Stack_Fault, 0);
f0103979:	b8 3c 3f 10 f0       	mov    $0xf0103f3c,%eax
f010397e:	66 a3 80 e3 17 f0    	mov    %ax,0xf017e380
f0103984:	66 c7 05 82 e3 17 f0 	movw   $0x8,0xf017e382
f010398b:	08 00 
f010398d:	c6 05 84 e3 17 f0 00 	movb   $0x0,0xf017e384
f0103994:	c6 05 85 e3 17 f0 8e 	movb   $0x8e,0xf017e385
f010399b:	c1 e8 10             	shr    $0x10,%eax
f010399e:	66 a3 86 e3 17 f0    	mov    %ax,0xf017e386
	SETGATE(idt[T_GPFLT] ,0, GD_KT, General_Protection, 0);
f01039a4:	b8 40 3f 10 f0       	mov    $0xf0103f40,%eax
f01039a9:	66 a3 88 e3 17 f0    	mov    %ax,0xf017e388
f01039af:	66 c7 05 8a e3 17 f0 	movw   $0x8,0xf017e38a
f01039b6:	08 00 
f01039b8:	c6 05 8c e3 17 f0 00 	movb   $0x0,0xf017e38c
f01039bf:	c6 05 8d e3 17 f0 8e 	movb   $0x8e,0xf017e38d
f01039c6:	c1 e8 10             	shr    $0x10,%eax
f01039c9:	66 a3 8e e3 17 f0    	mov    %ax,0xf017e38e
	SETGATE(idt[T_PGFLT] ,0, GD_KT, Page_Fault, 0);
f01039cf:	b8 44 3f 10 f0       	mov    $0xf0103f44,%eax
f01039d4:	66 a3 90 e3 17 f0    	mov    %ax,0xf017e390
f01039da:	66 c7 05 92 e3 17 f0 	movw   $0x8,0xf017e392
f01039e1:	08 00 
f01039e3:	c6 05 94 e3 17 f0 00 	movb   $0x0,0xf017e394
f01039ea:	c6 05 95 e3 17 f0 8e 	movb   $0x8e,0xf017e395
f01039f1:	c1 e8 10             	shr    $0x10,%eax
f01039f4:	66 a3 96 e3 17 f0    	mov    %ax,0xf017e396
	SETGATE(idt[T_FPERR] ,0, GD_KT, x87_FPU_Floating_Point_Error, 0);
f01039fa:	b8 48 3f 10 f0       	mov    $0xf0103f48,%eax
f01039ff:	66 a3 a0 e3 17 f0    	mov    %ax,0xf017e3a0
f0103a05:	66 c7 05 a2 e3 17 f0 	movw   $0x8,0xf017e3a2
f0103a0c:	08 00 
f0103a0e:	c6 05 a4 e3 17 f0 00 	movb   $0x0,0xf017e3a4
f0103a15:	c6 05 a5 e3 17 f0 8e 	movb   $0x8e,0xf017e3a5
f0103a1c:	c1 e8 10             	shr    $0x10,%eax
f0103a1f:	66 a3 a6 e3 17 f0    	mov    %ax,0xf017e3a6
	SETGATE(idt[T_ALIGN] ,0, GD_KT, Alignment_Check, 0);
f0103a25:	b8 4e 3f 10 f0       	mov    $0xf0103f4e,%eax
f0103a2a:	66 a3 a8 e3 17 f0    	mov    %ax,0xf017e3a8
f0103a30:	66 c7 05 aa e3 17 f0 	movw   $0x8,0xf017e3aa
f0103a37:	08 00 
f0103a39:	c6 05 ac e3 17 f0 00 	movb   $0x0,0xf017e3ac
f0103a40:	c6 05 ad e3 17 f0 8e 	movb   $0x8e,0xf017e3ad
f0103a47:	c1 e8 10             	shr    $0x10,%eax
f0103a4a:	66 a3 ae e3 17 f0    	mov    %ax,0xf017e3ae
	SETGATE(idt[T_MCHK] ,0, GD_KT, Machine_Check, 0);
f0103a50:	b8 54 3f 10 f0       	mov    $0xf0103f54,%eax
f0103a55:	66 a3 b0 e3 17 f0    	mov    %ax,0xf017e3b0
f0103a5b:	66 c7 05 b2 e3 17 f0 	movw   $0x8,0xf017e3b2
f0103a62:	08 00 
f0103a64:	c6 05 b4 e3 17 f0 00 	movb   $0x0,0xf017e3b4
f0103a6b:	c6 05 b5 e3 17 f0 8e 	movb   $0x8e,0xf017e3b5
f0103a72:	c1 e8 10             	shr    $0x10,%eax
f0103a75:	66 a3 b6 e3 17 f0    	mov    %ax,0xf017e3b6
	SETGATE(idt[T_SIMDERR] ,0, GD_KT, SIMD_Floating_Point_Exception, 0);
f0103a7b:	b8 5a 3f 10 f0       	mov    $0xf0103f5a,%eax
f0103a80:	66 a3 b8 e3 17 f0    	mov    %ax,0xf017e3b8
f0103a86:	66 c7 05 ba e3 17 f0 	movw   $0x8,0xf017e3ba
f0103a8d:	08 00 
f0103a8f:	c6 05 bc e3 17 f0 00 	movb   $0x0,0xf017e3bc
f0103a96:	c6 05 bd e3 17 f0 8e 	movb   $0x8e,0xf017e3bd
f0103a9d:	c1 e8 10             	shr    $0x10,%eax
f0103aa0:	66 a3 be e3 17 f0    	mov    %ax,0xf017e3be

	SETGATE(idt[T_SYSCALL], 0 , GD_KT, System_call, 3)
f0103aa6:	b8 60 3f 10 f0       	mov    $0xf0103f60,%eax
f0103aab:	66 a3 a0 e4 17 f0    	mov    %ax,0xf017e4a0
f0103ab1:	66 c7 05 a2 e4 17 f0 	movw   $0x8,0xf017e4a2
f0103ab8:	08 00 
f0103aba:	c6 05 a4 e4 17 f0 00 	movb   $0x0,0xf017e4a4
f0103ac1:	c6 05 a5 e4 17 f0 ee 	movb   $0xee,0xf017e4a5
f0103ac8:	c1 e8 10             	shr    $0x10,%eax
f0103acb:	66 a3 a6 e4 17 f0    	mov    %ax,0xf017e4a6
	// Per-CPU setup 
	trap_init_percpu();
f0103ad1:	e8 6a fc ff ff       	call   f0103740 <trap_init_percpu>
}
f0103ad6:	5d                   	pop    %ebp
f0103ad7:	c3                   	ret    

f0103ad8 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103ad8:	55                   	push   %ebp
f0103ad9:	89 e5                	mov    %esp,%ebp
f0103adb:	53                   	push   %ebx
f0103adc:	83 ec 14             	sub    $0x14,%esp
f0103adf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103ae2:	8b 03                	mov    (%ebx),%eax
f0103ae4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ae8:	c7 04 24 d6 62 10 f0 	movl   $0xf01062d6,(%esp)
f0103aef:	e8 2a fc ff ff       	call   f010371e <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103af4:	8b 43 04             	mov    0x4(%ebx),%eax
f0103af7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103afb:	c7 04 24 e5 62 10 f0 	movl   $0xf01062e5,(%esp)
f0103b02:	e8 17 fc ff ff       	call   f010371e <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103b07:	8b 43 08             	mov    0x8(%ebx),%eax
f0103b0a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b0e:	c7 04 24 f4 62 10 f0 	movl   $0xf01062f4,(%esp)
f0103b15:	e8 04 fc ff ff       	call   f010371e <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103b1a:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103b1d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b21:	c7 04 24 03 63 10 f0 	movl   $0xf0106303,(%esp)
f0103b28:	e8 f1 fb ff ff       	call   f010371e <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103b2d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b30:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b34:	c7 04 24 12 63 10 f0 	movl   $0xf0106312,(%esp)
f0103b3b:	e8 de fb ff ff       	call   f010371e <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b40:	8b 43 14             	mov    0x14(%ebx),%eax
f0103b43:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b47:	c7 04 24 21 63 10 f0 	movl   $0xf0106321,(%esp)
f0103b4e:	e8 cb fb ff ff       	call   f010371e <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b53:	8b 43 18             	mov    0x18(%ebx),%eax
f0103b56:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b5a:	c7 04 24 30 63 10 f0 	movl   $0xf0106330,(%esp)
f0103b61:	e8 b8 fb ff ff       	call   f010371e <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b66:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103b69:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b6d:	c7 04 24 3f 63 10 f0 	movl   $0xf010633f,(%esp)
f0103b74:	e8 a5 fb ff ff       	call   f010371e <cprintf>
}
f0103b79:	83 c4 14             	add    $0x14,%esp
f0103b7c:	5b                   	pop    %ebx
f0103b7d:	5d                   	pop    %ebp
f0103b7e:	c3                   	ret    

f0103b7f <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b7f:	55                   	push   %ebp
f0103b80:	89 e5                	mov    %esp,%ebp
f0103b82:	56                   	push   %esi
f0103b83:	53                   	push   %ebx
f0103b84:	83 ec 10             	sub    $0x10,%esp
f0103b87:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103b8a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b8e:	c7 04 24 75 64 10 f0 	movl   $0xf0106475,(%esp)
f0103b95:	e8 84 fb ff ff       	call   f010371e <cprintf>
	print_regs(&tf->tf_regs);
f0103b9a:	89 1c 24             	mov    %ebx,(%esp)
f0103b9d:	e8 36 ff ff ff       	call   f0103ad8 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103ba2:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103ba6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103baa:	c7 04 24 90 63 10 f0 	movl   $0xf0106390,(%esp)
f0103bb1:	e8 68 fb ff ff       	call   f010371e <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103bb6:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103bba:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bbe:	c7 04 24 a3 63 10 f0 	movl   $0xf01063a3,(%esp)
f0103bc5:	e8 54 fb ff ff       	call   f010371e <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bca:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103bcd:	83 f8 13             	cmp    $0x13,%eax
f0103bd0:	77 09                	ja     f0103bdb <print_trapframe+0x5c>
		return excnames[trapno];
f0103bd2:	8b 14 85 a0 66 10 f0 	mov    -0xfef9960(,%eax,4),%edx
f0103bd9:	eb 10                	jmp    f0103beb <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103bdb:	83 f8 30             	cmp    $0x30,%eax
f0103bde:	ba 4e 63 10 f0       	mov    $0xf010634e,%edx
f0103be3:	b9 5a 63 10 f0       	mov    $0xf010635a,%ecx
f0103be8:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103beb:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103bef:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bf3:	c7 04 24 b6 63 10 f0 	movl   $0xf01063b6,(%esp)
f0103bfa:	e8 1f fb ff ff       	call   f010371e <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103bff:	3b 1d 88 eb 17 f0    	cmp    0xf017eb88,%ebx
f0103c05:	75 19                	jne    f0103c20 <print_trapframe+0xa1>
f0103c07:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c0b:	75 13                	jne    f0103c20 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103c0d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103c10:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c14:	c7 04 24 c8 63 10 f0 	movl   $0xf01063c8,(%esp)
f0103c1b:	e8 fe fa ff ff       	call   f010371e <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103c20:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103c23:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c27:	c7 04 24 d7 63 10 f0 	movl   $0xf01063d7,(%esp)
f0103c2e:	e8 eb fa ff ff       	call   f010371e <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103c33:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c37:	75 51                	jne    f0103c8a <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103c39:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103c3c:	89 c2                	mov    %eax,%edx
f0103c3e:	83 e2 01             	and    $0x1,%edx
f0103c41:	ba 69 63 10 f0       	mov    $0xf0106369,%edx
f0103c46:	b9 74 63 10 f0       	mov    $0xf0106374,%ecx
f0103c4b:	0f 45 ca             	cmovne %edx,%ecx
f0103c4e:	89 c2                	mov    %eax,%edx
f0103c50:	83 e2 02             	and    $0x2,%edx
f0103c53:	ba 80 63 10 f0       	mov    $0xf0106380,%edx
f0103c58:	be 86 63 10 f0       	mov    $0xf0106386,%esi
f0103c5d:	0f 44 d6             	cmove  %esi,%edx
f0103c60:	83 e0 04             	and    $0x4,%eax
f0103c63:	b8 8b 63 10 f0       	mov    $0xf010638b,%eax
f0103c68:	be b2 64 10 f0       	mov    $0xf01064b2,%esi
f0103c6d:	0f 44 c6             	cmove  %esi,%eax
f0103c70:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103c74:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103c78:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c7c:	c7 04 24 e5 63 10 f0 	movl   $0xf01063e5,(%esp)
f0103c83:	e8 96 fa ff ff       	call   f010371e <cprintf>
f0103c88:	eb 0c                	jmp    f0103c96 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c8a:	c7 04 24 6c 5f 10 f0 	movl   $0xf0105f6c,(%esp)
f0103c91:	e8 88 fa ff ff       	call   f010371e <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c96:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c99:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c9d:	c7 04 24 f4 63 10 f0 	movl   $0xf01063f4,(%esp)
f0103ca4:	e8 75 fa ff ff       	call   f010371e <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103ca9:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103cad:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cb1:	c7 04 24 03 64 10 f0 	movl   $0xf0106403,(%esp)
f0103cb8:	e8 61 fa ff ff       	call   f010371e <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103cbd:	8b 43 38             	mov    0x38(%ebx),%eax
f0103cc0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cc4:	c7 04 24 16 64 10 f0 	movl   $0xf0106416,(%esp)
f0103ccb:	e8 4e fa ff ff       	call   f010371e <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103cd0:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103cd4:	74 27                	je     f0103cfd <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103cd6:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103cd9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cdd:	c7 04 24 25 64 10 f0 	movl   $0xf0106425,(%esp)
f0103ce4:	e8 35 fa ff ff       	call   f010371e <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103ce9:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103ced:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cf1:	c7 04 24 34 64 10 f0 	movl   $0xf0106434,(%esp)
f0103cf8:	e8 21 fa ff ff       	call   f010371e <cprintf>
	}
}
f0103cfd:	83 c4 10             	add    $0x10,%esp
f0103d00:	5b                   	pop    %ebx
f0103d01:	5e                   	pop    %esi
f0103d02:	5d                   	pop    %ebp
f0103d03:	c3                   	ret    

f0103d04 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103d04:	55                   	push   %ebp
f0103d05:	89 e5                	mov    %esp,%ebp
f0103d07:	53                   	push   %ebx
f0103d08:	83 ec 14             	sub    $0x14,%esp
f0103d0b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103d0e:	0f 20 d2             	mov    %cr2,%edx
	// All the handlers should check whether it is in kernel mode, 
	// if so, it should check the parameter whether it is valid
	// 
	// If I do not do the following operation, the grade script 
	// will run correctly though. 
	if((tf->tf_cs & 0x3) == 0)/* CPL  -  the low 2-bit in the cs register */
f0103d11:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103d15:	a8 03                	test   $0x3,%al
f0103d17:	75 23                	jne    f0103d3c <page_fault_handler+0x38>
		panic("kernel fault: invalid parameter for the page fault handler! With CPL = %d\n", tf->tf_cs);
f0103d19:	0f b7 c0             	movzwl %ax,%eax
f0103d1c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d20:	c7 44 24 08 fc 65 10 	movl   $0xf01065fc,0x8(%esp)
f0103d27:	f0 
f0103d28:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
f0103d2f:	00 
f0103d30:	c7 04 24 47 64 10 f0 	movl   $0xf0106447,(%esp)
f0103d37:	e8 82 c3 ff ff       	call   f01000be <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d3c:	8b 43 30             	mov    0x30(%ebx),%eax
f0103d3f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d43:	89 54 24 08          	mov    %edx,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0103d47:	a1 08 e3 17 f0       	mov    0xf017e308,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d4c:	8b 40 48             	mov    0x48(%eax),%eax
f0103d4f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d53:	c7 04 24 48 66 10 f0 	movl   $0xf0106648,(%esp)
f0103d5a:	e8 bf f9 ff ff       	call   f010371e <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103d5f:	89 1c 24             	mov    %ebx,(%esp)
f0103d62:	e8 18 fe ff ff       	call   f0103b7f <print_trapframe>
	env_destroy(curenv);
f0103d67:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0103d6c:	89 04 24             	mov    %eax,(%esp)
f0103d6f:	e8 7a f8 ff ff       	call   f01035ee <env_destroy>
}
f0103d74:	83 c4 14             	add    $0x14,%esp
f0103d77:	5b                   	pop    %ebx
f0103d78:	5d                   	pop    %ebp
f0103d79:	c3                   	ret    

f0103d7a <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103d7a:	55                   	push   %ebp
f0103d7b:	89 e5                	mov    %esp,%ebp
f0103d7d:	57                   	push   %edi
f0103d7e:	56                   	push   %esi
f0103d7f:	83 ec 20             	sub    $0x20,%esp
f0103d82:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d85:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d86:	9c                   	pushf  
f0103d87:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d88:	f6 c4 02             	test   $0x2,%ah
f0103d8b:	74 24                	je     f0103db1 <trap+0x37>
f0103d8d:	c7 44 24 0c 53 64 10 	movl   $0xf0106453,0xc(%esp)
f0103d94:	f0 
f0103d95:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0103d9c:	f0 
f0103d9d:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
f0103da4:	00 
f0103da5:	c7 04 24 47 64 10 f0 	movl   $0xf0106447,(%esp)
f0103dac:	e8 0d c3 ff ff       	call   f01000be <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103db1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103db5:	c7 04 24 6c 64 10 f0 	movl   $0xf010646c,(%esp)
f0103dbc:	e8 5d f9 ff ff       	call   f010371e <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103dc1:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103dc5:	83 e0 03             	and    $0x3,%eax
f0103dc8:	66 83 f8 03          	cmp    $0x3,%ax
f0103dcc:	75 3c                	jne    f0103e0a <trap+0x90>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0103dce:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0103dd3:	85 c0                	test   %eax,%eax
f0103dd5:	75 24                	jne    f0103dfb <trap+0x81>
f0103dd7:	c7 44 24 0c 87 64 10 	movl   $0xf0106487,0xc(%esp)
f0103dde:	f0 
f0103ddf:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0103de6:	f0 
f0103de7:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
f0103dee:	00 
f0103def:	c7 04 24 47 64 10 f0 	movl   $0xf0106447,(%esp)
f0103df6:	e8 c3 c2 ff ff       	call   f01000be <_panic>
		curenv->env_tf = *tf;
f0103dfb:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e00:	89 c7                	mov    %eax,%edi
f0103e02:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103e04:	8b 35 08 e3 17 f0    	mov    0xf017e308,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e0a:	89 35 88 eb 17 f0    	mov    %esi,0xf017eb88
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf -> tf_trapno){
f0103e10:	8b 46 28             	mov    0x28(%esi),%eax
f0103e13:	83 f8 03             	cmp    $0x3,%eax
f0103e16:	74 0a                	je     f0103e22 <trap+0xa8>
f0103e18:	83 f8 0e             	cmp    $0xe,%eax
f0103e1b:	74 0f                	je     f0103e2c <trap+0xb2>
f0103e1d:	83 f8 01             	cmp    $0x1,%eax
f0103e20:	75 12                	jne    f0103e34 <trap+0xba>
		case T_BRKPT:
		case T_DEBUG:
			monitor(tf);
f0103e22:	89 34 24             	mov    %esi,(%esp)
f0103e25:	e8 56 ca ff ff       	call   f0100880 <monitor>
f0103e2a:	eb 08                	jmp    f0103e34 <trap+0xba>
			break;
		case T_PGFLT:
			page_fault_handler(tf);
f0103e2c:	89 34 24             	mov    %esi,(%esp)
f0103e2f:	e8 d0 fe ff ff       	call   f0103d04 <page_fault_handler>
			break;
	}

	if (tf->tf_trapno == T_SYSCALL){
f0103e34:	83 7e 28 30          	cmpl   $0x30,0x28(%esi)
f0103e38:	75 52                	jne    f0103e8c <trap+0x112>
		struct PushRegs *regs = &(tf -> tf_regs);
		/*  DX, CX, BX, DI, SI */
		int32_t num = syscall(regs->reg_eax, regs->reg_edx, regs->reg_ecx, 
f0103e3a:	8b 46 04             	mov    0x4(%esi),%eax
f0103e3d:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103e41:	8b 06                	mov    (%esi),%eax
f0103e43:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103e47:	8b 46 10             	mov    0x10(%esi),%eax
f0103e4a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e4e:	8b 46 18             	mov    0x18(%esi),%eax
f0103e51:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e55:	8b 46 14             	mov    0x14(%esi),%eax
f0103e58:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e5c:	8b 46 1c             	mov    0x1c(%esi),%eax
f0103e5f:	89 04 24             	mov    %eax,(%esp)
f0103e62:	e8 19 01 00 00       	call   f0103f80 <syscall>
			regs->reg_ebx,regs->reg_edi, regs->reg_esi);

		if(num < 0)
f0103e67:	85 c0                	test   %eax,%eax
f0103e69:	79 1c                	jns    f0103e87 <trap+0x10d>
			panic("unhandled fault!\n");
f0103e6b:	c7 44 24 08 8e 64 10 	movl   $0xf010648e,0x8(%esp)
f0103e72:	f0 
f0103e73:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
f0103e7a:	00 
f0103e7b:	c7 04 24 47 64 10 f0 	movl   $0xf0106447,(%esp)
f0103e82:	e8 37 c2 ff ff       	call   f01000be <_panic>
		regs -> reg_eax = num;
f0103e87:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e8a:	eb 38                	jmp    f0103ec4 <trap+0x14a>
		return;

	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103e8c:	89 34 24             	mov    %esi,(%esp)
f0103e8f:	e8 eb fc ff ff       	call   f0103b7f <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103e94:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e99:	75 1c                	jne    f0103eb7 <trap+0x13d>
		panic("unhandled trap in kernel");
f0103e9b:	c7 44 24 08 a0 64 10 	movl   $0xf01064a0,0x8(%esp)
f0103ea2:	f0 
f0103ea3:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f0103eaa:	00 
f0103eab:	c7 04 24 47 64 10 f0 	movl   $0xf0106447,(%esp)
f0103eb2:	e8 07 c2 ff ff       	call   f01000be <_panic>
	else {
		env_destroy(curenv);
f0103eb7:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0103ebc:	89 04 24             	mov    %eax,(%esp)
f0103ebf:	e8 2a f7 ff ff       	call   f01035ee <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103ec4:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0103ec9:	85 c0                	test   %eax,%eax
f0103ecb:	74 06                	je     f0103ed3 <trap+0x159>
f0103ecd:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0103ed1:	74 24                	je     f0103ef7 <trap+0x17d>
f0103ed3:	c7 44 24 0c 6c 66 10 	movl   $0xf010666c,0xc(%esp)
f0103eda:	f0 
f0103edb:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0103ee2:	f0 
f0103ee3:	c7 44 24 04 fc 00 00 	movl   $0xfc,0x4(%esp)
f0103eea:	00 
f0103eeb:	c7 04 24 47 64 10 f0 	movl   $0xf0106447,(%esp)
f0103ef2:	e8 c7 c1 ff ff       	call   f01000be <_panic>
	env_run(curenv);
f0103ef7:	89 04 24             	mov    %eax,(%esp)
f0103efa:	e8 46 f7 ff ff       	call   f0103645 <env_run>
f0103eff:	90                   	nop

f0103f00 <Divide_error>:
  * TRAPHANDLER_NOEC - No return
  * TRAPHANDLER - return
  *
  * http://pdos.csail.mit.edu/6.828/2011/readings/i386/s09_10.htm
  */
TRAPHANDLER_NOEC(Divide_error, T_DIVIDE);
f0103f00:	6a 00                	push   $0x0
f0103f02:	6a 00                	push   $0x0
f0103f04:	eb 60                	jmp    f0103f66 <_alltraps>

f0103f06 <Debug>:
TRAPHANDLER_NOEC(Debug, T_DEBUG);
f0103f06:	6a 00                	push   $0x0
f0103f08:	6a 01                	push   $0x1
f0103f0a:	eb 5a                	jmp    f0103f66 <_alltraps>

f0103f0c <Non_Maskable_Interrupt>:
TRAPHANDLER_NOEC(Non_Maskable_Interrupt, T_NMI);
f0103f0c:	6a 00                	push   $0x0
f0103f0e:	6a 02                	push   $0x2
f0103f10:	eb 54                	jmp    f0103f66 <_alltraps>

f0103f12 <Breakpoint>:
TRAPHANDLER_NOEC(Breakpoint, T_BRKPT);
f0103f12:	6a 00                	push   $0x0
f0103f14:	6a 03                	push   $0x3
f0103f16:	eb 4e                	jmp    f0103f66 <_alltraps>

f0103f18 <Overflow>:
TRAPHANDLER_NOEC(Overflow, T_OFLOW);
f0103f18:	6a 00                	push   $0x0
f0103f1a:	6a 04                	push   $0x4
f0103f1c:	eb 48                	jmp    f0103f66 <_alltraps>

f0103f1e <BOUND_Range_Exceeded>:
TRAPHANDLER_NOEC(BOUND_Range_Exceeded, T_BOUND);
f0103f1e:	6a 00                	push   $0x0
f0103f20:	6a 05                	push   $0x5
f0103f22:	eb 42                	jmp    f0103f66 <_alltraps>

f0103f24 <Invalid_Opcode>:
TRAPHANDLER_NOEC(Invalid_Opcode, T_ILLOP);
f0103f24:	6a 00                	push   $0x0
f0103f26:	6a 06                	push   $0x6
f0103f28:	eb 3c                	jmp    f0103f66 <_alltraps>

f0103f2a <Device_Not_Available>:
TRAPHANDLER_NOEC(Device_Not_Available, T_DEVICE);
f0103f2a:	6a 00                	push   $0x0
f0103f2c:	6a 07                	push   $0x7
f0103f2e:	eb 36                	jmp    f0103f66 <_alltraps>

f0103f30 <Double_Fault>:
TRAPHANDLER(Double_Fault, T_DBLFLT);
f0103f30:	6a 08                	push   $0x8
f0103f32:	eb 32                	jmp    f0103f66 <_alltraps>

f0103f34 <Invalid_TSS>:
TRAPHANDLER(Invalid_TSS, T_TSS);
f0103f34:	6a 0a                	push   $0xa
f0103f36:	eb 2e                	jmp    f0103f66 <_alltraps>

f0103f38 <Segment_Not_Present>:
TRAPHANDLER(Segment_Not_Present, T_SEGNP);
f0103f38:	6a 0b                	push   $0xb
f0103f3a:	eb 2a                	jmp    f0103f66 <_alltraps>

f0103f3c <Stack_Fault>:
TRAPHANDLER(Stack_Fault, T_STACK);
f0103f3c:	6a 0c                	push   $0xc
f0103f3e:	eb 26                	jmp    f0103f66 <_alltraps>

f0103f40 <General_Protection>:
TRAPHANDLER(General_Protection, T_GPFLT);
f0103f40:	6a 0d                	push   $0xd
f0103f42:	eb 22                	jmp    f0103f66 <_alltraps>

f0103f44 <Page_Fault>:
TRAPHANDLER(Page_Fault, T_PGFLT);
f0103f44:	6a 0e                	push   $0xe
f0103f46:	eb 1e                	jmp    f0103f66 <_alltraps>

f0103f48 <x87_FPU_Floating_Point_Error>:
TRAPHANDLER_NOEC(x87_FPU_Floating_Point_Error, T_FPERR);
f0103f48:	6a 00                	push   $0x0
f0103f4a:	6a 10                	push   $0x10
f0103f4c:	eb 18                	jmp    f0103f66 <_alltraps>

f0103f4e <Alignment_Check>:
TRAPHANDLER_NOEC(Alignment_Check, T_ALIGN);
f0103f4e:	6a 00                	push   $0x0
f0103f50:	6a 11                	push   $0x11
f0103f52:	eb 12                	jmp    f0103f66 <_alltraps>

f0103f54 <Machine_Check>:
TRAPHANDLER_NOEC(Machine_Check, T_MCHK);
f0103f54:	6a 00                	push   $0x0
f0103f56:	6a 12                	push   $0x12
f0103f58:	eb 0c                	jmp    f0103f66 <_alltraps>

f0103f5a <SIMD_Floating_Point_Exception>:
TRAPHANDLER_NOEC(SIMD_Floating_Point_Exception, T_SIMDERR);
f0103f5a:	6a 00                	push   $0x0
f0103f5c:	6a 13                	push   $0x13
f0103f5e:	eb 06                	jmp    f0103f66 <_alltraps>

f0103f60 <System_call>:

TRAPHANDLER_NOEC(System_call,T_SYSCALL);
f0103f60:	6a 00                	push   $0x0
f0103f62:	6a 30                	push   $0x30
f0103f64:	eb 00                	jmp    f0103f66 <_alltraps>

f0103f66 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
 _alltraps:
 	pushw   $0x0
f0103f66:	66 6a 00             	pushw  $0x0
	pushw	%ds
f0103f69:	66 1e                	pushw  %ds
	pushw	$0x0
f0103f6b:	66 6a 00             	pushw  $0x0
	pushw	%es	
f0103f6e:	66 06                	pushw  %es
	pushal
f0103f70:	60                   	pusha  
	movl	$GD_KD, %eax /* GD_KD is kern data -- 0x10 */
f0103f71:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax, %ds
f0103f76:	8e d8                	mov    %eax,%ds
	movw	%ax, %es
f0103f78:	8e c0                	mov    %eax,%es
	pushl %esp
f0103f7a:	54                   	push   %esp
	call trap
f0103f7b:	e8 fa fd ff ff       	call   f0103d7a <trap>

f0103f80 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103f80:	55                   	push   %ebp
f0103f81:	89 e5                	mov    %esp,%ebp
f0103f83:	83 ec 28             	sub    $0x28,%esp
f0103f86:	8b 45 08             	mov    0x8(%ebp),%eax
	SYS_cgetc,
	SYS_getenvid,
	SYS_env_destroy,
	NSYSCALLS
	};*/
	switch(syscallno){
f0103f89:	83 f8 01             	cmp    $0x1,%eax
f0103f8c:	74 5c                	je     f0103fea <syscall+0x6a>
f0103f8e:	83 f8 01             	cmp    $0x1,%eax
f0103f91:	72 10                	jb     f0103fa3 <syscall+0x23>
f0103f93:	83 f8 02             	cmp    $0x2,%eax
f0103f96:	74 5a                	je     f0103ff2 <syscall+0x72>
f0103f98:	83 f8 03             	cmp    $0x3,%eax
f0103f9b:	0f 85 c7 00 00 00    	jne    f0104068 <syscall+0xe8>
f0103fa1:	eb 59                	jmp    f0103ffc <syscall+0x7c>
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	/*user_mem_assert(struct Env *env, const void *va, size_t len, int perm)*/
	user_mem_assert(curenv, (const void *)s, len, PTE_U);
f0103fa3:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0103faa:	00 
f0103fab:	8b 45 10             	mov    0x10(%ebp),%eax
f0103fae:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fb2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103fb5:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103fb9:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0103fbe:	89 04 24             	mov    %eax,(%esp)
f0103fc1:	e8 63 ef ff ff       	call   f0102f29 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103fc6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fc9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fcd:	8b 55 10             	mov    0x10(%ebp),%edx
f0103fd0:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103fd4:	c7 04 24 c9 55 10 f0 	movl   $0xf01055c9,(%esp)
f0103fdb:	e8 3e f7 ff ff       	call   f010371e <cprintf>
	SYS_getenvid,
	SYS_env_destroy,
	NSYSCALLS
	};*/
	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
f0103fe0:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fe5:	e9 83 00 00 00       	jmp    f010406d <syscall+0xed>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103fea:	e8 03 c5 ff ff       	call   f01004f2 <cons_getc>
	SYS_env_destroy,
	NSYSCALLS
	};*/
	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
		case SYS_cgetc: return sys_cgetc();
f0103fef:	90                   	nop
f0103ff0:	eb 7b                	jmp    f010406d <syscall+0xed>
    
// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103ff2:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0103ff7:	8b 40 48             	mov    0x48(%eax),%eax
	NSYSCALLS
	};*/
	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
		case SYS_cgetc: return sys_cgetc();
		case SYS_getenvid: return sys_getenvid();
f0103ffa:	eb 71                	jmp    f010406d <syscall+0xed>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103ffc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104003:	00 
f0104004:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104007:	89 44 24 04          	mov    %eax,0x4(%esp)
f010400b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010400e:	89 04 24             	mov    %eax,(%esp)
f0104011:	e8 2b f0 ff ff       	call   f0103041 <envid2env>
f0104016:	85 c0                	test   %eax,%eax
f0104018:	78 53                	js     f010406d <syscall+0xed>
		return r;
	if (e == curenv)
f010401a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010401d:	8b 15 08 e3 17 f0    	mov    0xf017e308,%edx
f0104023:	39 d0                	cmp    %edx,%eax
f0104025:	75 15                	jne    f010403c <syscall+0xbc>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104027:	8b 40 48             	mov    0x48(%eax),%eax
f010402a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010402e:	c7 04 24 f0 66 10 f0 	movl   $0xf01066f0,(%esp)
f0104035:	e8 e4 f6 ff ff       	call   f010371e <cprintf>
f010403a:	eb 1a                	jmp    f0104056 <syscall+0xd6>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010403c:	8b 40 48             	mov    0x48(%eax),%eax
f010403f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104043:	8b 42 48             	mov    0x48(%edx),%eax
f0104046:	89 44 24 04          	mov    %eax,0x4(%esp)
f010404a:	c7 04 24 0b 67 10 f0 	movl   $0xf010670b,(%esp)
f0104051:	e8 c8 f6 ff ff       	call   f010371e <cprintf>
	env_destroy(e);
f0104056:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104059:	89 04 24             	mov    %eax,(%esp)
f010405c:	e8 8d f5 ff ff       	call   f01035ee <env_destroy>
	return 0;
f0104061:	b8 00 00 00 00       	mov    $0x0,%eax
	};*/
	switch(syscallno){
		case SYS_cputs: sys_cputs((char *)a1, (size_t)a2);return 0;
		case SYS_cgetc: return sys_cgetc();
		case SYS_getenvid: return sys_getenvid();
		case SYS_env_destroy: return sys_env_destroy((envid_t)a1);
f0104066:	eb 05                	jmp    f010406d <syscall+0xed>
		//case NSYSCALLS: NSYSCALLS();break;
		default: return -E_INVAL;
f0104068:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	//panic("current %d", syscallno);

	//panic("syscall not implemented");
}
f010406d:	c9                   	leave  
f010406e:	c3                   	ret    
f010406f:	90                   	nop

f0104070 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104070:	55                   	push   %ebp
f0104071:	89 e5                	mov    %esp,%ebp
f0104073:	57                   	push   %edi
f0104074:	56                   	push   %esi
f0104075:	53                   	push   %ebx
f0104076:	83 ec 14             	sub    $0x14,%esp
f0104079:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010407c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010407f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104082:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104085:	8b 1a                	mov    (%edx),%ebx
f0104087:	8b 01                	mov    (%ecx),%eax
f0104089:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f010408c:	39 c3                	cmp    %eax,%ebx
f010408e:	0f 8f 9f 00 00 00    	jg     f0104133 <stab_binsearch+0xc3>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0104094:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f010409b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010409e:	01 d8                	add    %ebx,%eax
f01040a0:	89 c7                	mov    %eax,%edi
f01040a2:	c1 ef 1f             	shr    $0x1f,%edi
f01040a5:	01 c7                	add    %eax,%edi
f01040a7:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040a9:	39 df                	cmp    %ebx,%edi
f01040ab:	0f 8c ce 00 00 00    	jl     f010417f <stab_binsearch+0x10f>
f01040b1:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01040b4:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01040b7:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f01040bc:	39 f0                	cmp    %esi,%eax
f01040be:	0f 84 c0 00 00 00    	je     f0104184 <stab_binsearch+0x114>
f01040c4:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01040c8:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f01040cc:	89 f8                	mov    %edi,%eax
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01040ce:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040d1:	39 d8                	cmp    %ebx,%eax
f01040d3:	0f 8c a6 00 00 00    	jl     f010417f <stab_binsearch+0x10f>
f01040d9:	0f b6 0a             	movzbl (%edx),%ecx
f01040dc:	83 ea 0c             	sub    $0xc,%edx
f01040df:	39 f1                	cmp    %esi,%ecx
f01040e1:	75 eb                	jne    f01040ce <stab_binsearch+0x5e>
f01040e3:	e9 9e 00 00 00       	jmp    f0104186 <stab_binsearch+0x116>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01040e8:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01040eb:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f01040ed:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040f0:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01040f7:	eb 2b                	jmp    f0104124 <stab_binsearch+0xb4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01040f9:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01040fc:	76 14                	jbe    f0104112 <stab_binsearch+0xa2>
			*region_right = m - 1;
f01040fe:	83 e8 01             	sub    $0x1,%eax
f0104101:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104104:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104107:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104109:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0104110:	eb 12                	jmp    f0104124 <stab_binsearch+0xb4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104112:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104115:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0104117:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010411b:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010411d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0104124:	3b 5d ec             	cmp    -0x14(%ebp),%ebx
f0104127:	0f 8e 6e ff ff ff    	jle    f010409b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010412d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104131:	75 0f                	jne    f0104142 <stab_binsearch+0xd2>
		*region_right = *region_left - 1;
f0104133:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104136:	8b 02                	mov    (%edx),%eax
f0104138:	83 e8 01             	sub    $0x1,%eax
f010413b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010413e:	89 01                	mov    %eax,(%ecx)
f0104140:	eb 5c                	jmp    f010419e <stab_binsearch+0x12e>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104142:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104145:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104147:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010414a:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010414c:	39 c8                	cmp    %ecx,%eax
f010414e:	7e 28                	jle    f0104178 <stab_binsearch+0x108>
		     l > *region_left && stabs[l].n_type != type;
f0104150:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104153:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0104156:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f010415b:	39 f2                	cmp    %esi,%edx
f010415d:	74 19                	je     f0104178 <stab_binsearch+0x108>
f010415f:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0104163:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104167:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010416a:	39 c8                	cmp    %ecx,%eax
f010416c:	7e 0a                	jle    f0104178 <stab_binsearch+0x108>
		     l > *region_left && stabs[l].n_type != type;
f010416e:	0f b6 1a             	movzbl (%edx),%ebx
f0104171:	83 ea 0c             	sub    $0xc,%edx
f0104174:	39 f3                	cmp    %esi,%ebx
f0104176:	75 ef                	jne    f0104167 <stab_binsearch+0xf7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104178:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010417b:	89 02                	mov    %eax,(%edx)
f010417d:	eb 1f                	jmp    f010419e <stab_binsearch+0x12e>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010417f:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104182:	eb a0                	jmp    f0104124 <stab_binsearch+0xb4>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0104184:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104186:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104189:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f010418c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104190:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104193:	0f 82 4f ff ff ff    	jb     f01040e8 <stab_binsearch+0x78>
f0104199:	e9 5b ff ff ff       	jmp    f01040f9 <stab_binsearch+0x89>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f010419e:	83 c4 14             	add    $0x14,%esp
f01041a1:	5b                   	pop    %ebx
f01041a2:	5e                   	pop    %esi
f01041a3:	5f                   	pop    %edi
f01041a4:	5d                   	pop    %ebp
f01041a5:	c3                   	ret    

f01041a6 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01041a6:	55                   	push   %ebp
f01041a7:	89 e5                	mov    %esp,%ebp
f01041a9:	57                   	push   %edi
f01041aa:	56                   	push   %esi
f01041ab:	53                   	push   %ebx
f01041ac:	83 ec 5c             	sub    $0x5c,%esp
f01041af:	8b 7d 08             	mov    0x8(%ebp),%edi
f01041b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01041b5:	c7 03 23 67 10 f0    	movl   $0xf0106723,(%ebx)
	info->eip_line = 0;
f01041bb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01041c2:	c7 43 08 23 67 10 f0 	movl   $0xf0106723,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01041c9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01041d0:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01041d3:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01041da:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01041e0:	0f 87 ae 00 00 00    	ja     f0104294 <debuginfo_eip+0xee>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		/* user_mem_check(struct Env *env, const void *va, size_t len, int perm) */
		if(user_mem_check(curenv, (void *)usd, sizeof(*usd), PTE_U))
f01041e6:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01041ed:	00 
f01041ee:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01041f5:	00 
f01041f6:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f01041fd:	00 
f01041fe:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0104203:	89 04 24             	mov    %eax,(%esp)
f0104206:	e8 71 ec ff ff       	call   f0102e7c <user_mem_check>
f010420b:	85 c0                	test   %eax,%eax
f010420d:	0f 85 69 02 00 00    	jne    f010447c <debuginfo_eip+0x2d6>
			return -1;

		stabs = usd->stabs;
f0104213:	a1 00 00 20 00       	mov    0x200000,%eax
f0104218:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f010421b:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104221:	8b 15 08 00 20 00    	mov    0x200008,%edx
f0104227:	89 55 bc             	mov    %edx,-0x44(%ebp)
		stabstr_end = usd->stabstr_end;
f010422a:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f0104230:	89 4d c0             	mov    %ecx,-0x40(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) |
f0104233:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010423a:	00 
f010423b:	89 f0                	mov    %esi,%eax
f010423d:	2b 45 c4             	sub    -0x3c(%ebp),%eax
f0104240:	c1 f8 02             	sar    $0x2,%eax
f0104243:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104249:	89 44 24 08          	mov    %eax,0x8(%esp)
f010424d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0104250:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104254:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0104259:	89 04 24             	mov    %eax,(%esp)
f010425c:	e8 1b ec ff ff       	call   f0102e7c <user_mem_check>
f0104261:	89 45 b8             	mov    %eax,-0x48(%ebp)
		user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U))
f0104264:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010426b:	00 
f010426c:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010426f:	2b 45 bc             	sub    -0x44(%ebp),%eax
f0104272:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104276:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104279:	89 54 24 04          	mov    %edx,0x4(%esp)
f010427d:	a1 08 e3 17 f0       	mov    0xf017e308,%eax
f0104282:	89 04 24             	mov    %eax,(%esp)
f0104285:	e8 f2 eb ff ff       	call   f0102e7c <user_mem_check>
		stabstr = usd->stabstr;
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) |
f010428a:	0b 45 b8             	or     -0x48(%ebp),%eax
f010428d:	74 1f                	je     f01042ae <debuginfo_eip+0x108>
f010428f:	e9 ef 01 00 00       	jmp    f0104483 <debuginfo_eip+0x2dd>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104294:	c7 45 c0 75 17 11 f0 	movl   $0xf0111775,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010429b:	c7 45 bc b9 ec 10 f0 	movl   $0xf010ecb9,-0x44(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01042a2:	be b8 ec 10 f0       	mov    $0xf010ecb8,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01042a7:	c7 45 c4 3c 69 10 f0 	movl   $0xf010693c,-0x3c(%ebp)
			return -1;

	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01042ae:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f01042b1:	39 4d bc             	cmp    %ecx,-0x44(%ebp)
f01042b4:	0f 83 d0 01 00 00    	jae    f010448a <debuginfo_eip+0x2e4>
f01042ba:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f01042be:	0f 85 cd 01 00 00    	jne    f0104491 <debuginfo_eip+0x2eb>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01042c4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01042cb:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f01042ce:	c1 fe 02             	sar    $0x2,%esi
f01042d1:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f01042d7:	83 e8 01             	sub    $0x1,%eax
f01042da:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01042dd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01042e1:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01042e8:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01042eb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01042ee:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01042f1:	e8 7a fd ff ff       	call   f0104070 <stab_binsearch>
	if (lfile == 0)
f01042f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042f9:	85 c0                	test   %eax,%eax
f01042fb:	0f 84 97 01 00 00    	je     f0104498 <debuginfo_eip+0x2f2>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104301:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104304:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104307:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010430a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010430e:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104315:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104318:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010431b:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010431e:	e8 4d fd ff ff       	call   f0104070 <stab_binsearch>

	if (lfun <= rfun) {
f0104323:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104326:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0104329:	39 f0                	cmp    %esi,%eax
f010432b:	7f 32                	jg     f010435f <debuginfo_eip+0x1b9>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010432d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104330:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104333:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f0104336:	8b 0a                	mov    (%edx),%ecx
f0104338:	89 4d b4             	mov    %ecx,-0x4c(%ebp)
f010433b:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f010433e:	2b 4d bc             	sub    -0x44(%ebp),%ecx
f0104341:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f0104344:	73 09                	jae    f010434f <debuginfo_eip+0x1a9>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104346:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f0104349:	03 4d bc             	add    -0x44(%ebp),%ecx
f010434c:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010434f:	8b 52 08             	mov    0x8(%edx),%edx
f0104352:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104355:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104357:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010435a:	89 75 d0             	mov    %esi,-0x30(%ebp)
f010435d:	eb 0f                	jmp    f010436e <debuginfo_eip+0x1c8>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010435f:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104362:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104365:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104368:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010436b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010436e:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104375:	00 
f0104376:	8b 43 08             	mov    0x8(%ebx),%eax
f0104379:	89 04 24             	mov    %eax,(%esp)
f010437c:	e8 fa 09 00 00       	call   f0104d7b <strfind>
f0104381:	2b 43 08             	sub    0x8(%ebx),%eax
f0104384:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f0104387:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010438b:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0104392:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104395:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104398:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010439b:	e8 d0 fc ff ff       	call   f0104070 <stab_binsearch>
	if(lline > rline)
f01043a0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01043a3:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01043a6:	0f 8f f3 00 00 00    	jg     f010449f <debuginfo_eip+0x2f9>
		return -1;
		//cprintf("lline %d, rline %d",lline, rline);
	info -> eip_line = stabs[lline].n_desc;
f01043ac:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01043af:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01043b2:	0f b7 44 82 06       	movzwl 0x6(%edx,%eax,4),%eax
f01043b7:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01043ba:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01043bd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01043c0:	39 fa                	cmp    %edi,%edx
f01043c2:	7c 6b                	jl     f010442f <debuginfo_eip+0x289>
	       && stabs[lline].n_type != N_SOL
f01043c4:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01043c7:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01043ca:	8d 34 81             	lea    (%ecx,%eax,4),%esi
f01043cd:	0f b6 46 04          	movzbl 0x4(%esi),%eax
f01043d1:	88 45 b4             	mov    %al,-0x4c(%ebp)
f01043d4:	3c 84                	cmp    $0x84,%al
f01043d6:	74 3f                	je     f0104417 <debuginfo_eip+0x271>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01043d8:	8d 4c 52 fd          	lea    -0x3(%edx,%edx,2),%ecx
f01043dc:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01043df:	8d 04 88             	lea    (%eax,%ecx,4),%eax
f01043e2:	89 45 b8             	mov    %eax,-0x48(%ebp)
f01043e5:	0f b6 4d b4          	movzbl -0x4c(%ebp),%ecx
f01043e9:	eb 1a                	jmp    f0104405 <debuginfo_eip+0x25f>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01043eb:	83 ea 01             	sub    $0x1,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01043ee:	39 fa                	cmp    %edi,%edx
f01043f0:	7c 3d                	jl     f010442f <debuginfo_eip+0x289>
	       && stabs[lline].n_type != N_SOL
f01043f2:	89 c6                	mov    %eax,%esi
f01043f4:	83 e8 0c             	sub    $0xc,%eax
f01043f7:	0f b6 48 10          	movzbl 0x10(%eax),%ecx
f01043fb:	80 f9 84             	cmp    $0x84,%cl
f01043fe:	75 05                	jne    f0104405 <debuginfo_eip+0x25f>
f0104400:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104403:	eb 12                	jmp    f0104417 <debuginfo_eip+0x271>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104405:	80 f9 64             	cmp    $0x64,%cl
f0104408:	75 e1                	jne    f01043eb <debuginfo_eip+0x245>
f010440a:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f010440e:	74 db                	je     f01043eb <debuginfo_eip+0x245>
f0104410:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104413:	39 d7                	cmp    %edx,%edi
f0104415:	7f 18                	jg     f010442f <debuginfo_eip+0x289>
f0104417:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010441a:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f010441d:	8b 04 82             	mov    (%edx,%eax,4),%eax
f0104420:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0104423:	2b 55 bc             	sub    -0x44(%ebp),%edx
f0104426:	39 d0                	cmp    %edx,%eax
f0104428:	73 05                	jae    f010442f <debuginfo_eip+0x289>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010442a:	03 45 bc             	add    -0x44(%ebp),%eax
f010442d:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010442f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104432:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0104435:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010443a:	39 f2                	cmp    %esi,%edx
f010443c:	7d 7b                	jge    f01044b9 <debuginfo_eip+0x313>
		for (lline = lfun + 1;
f010443e:	8d 42 01             	lea    0x1(%edx),%eax
f0104441:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104444:	39 c6                	cmp    %eax,%esi
f0104446:	7e 5e                	jle    f01044a6 <debuginfo_eip+0x300>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104448:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010444b:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010444e:	80 7c 81 04 a0       	cmpb   $0xa0,0x4(%ecx,%eax,4)
f0104453:	75 58                	jne    f01044ad <debuginfo_eip+0x307>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0104455:	8d 42 02             	lea    0x2(%edx),%eax

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104458:	8d 14 52             	lea    (%edx,%edx,2),%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f010445b:	8d 54 91 1c          	lea    0x1c(%ecx,%edx,4),%edx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010445f:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104463:	39 f0                	cmp    %esi,%eax
f0104465:	74 4d                	je     f01044b4 <debuginfo_eip+0x30e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104467:	0f b6 0a             	movzbl (%edx),%ecx
f010446a:	83 c0 01             	add    $0x1,%eax
f010446d:	83 c2 0c             	add    $0xc,%edx
f0104470:	80 f9 a0             	cmp    $0xa0,%cl
f0104473:	74 ea                	je     f010445f <debuginfo_eip+0x2b9>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0104475:	b8 00 00 00 00       	mov    $0x0,%eax
f010447a:	eb 3d                	jmp    f01044b9 <debuginfo_eip+0x313>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		/* user_mem_check(struct Env *env, const void *va, size_t len, int perm) */
		if(user_mem_check(curenv, (void *)usd, sizeof(*usd), PTE_U))
			return -1;
f010447c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104481:	eb 36                	jmp    f01044b9 <debuginfo_eip+0x313>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) |
		user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
f0104483:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104488:	eb 2f                	jmp    f01044b9 <debuginfo_eip+0x313>

	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010448a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010448f:	eb 28                	jmp    f01044b9 <debuginfo_eip+0x313>
f0104491:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104496:	eb 21                	jmp    f01044b9 <debuginfo_eip+0x313>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104498:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010449d:	eb 1a                	jmp    f01044b9 <debuginfo_eip+0x313>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
	if(lline > rline)
		return -1;
f010449f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044a4:	eb 13                	jmp    f01044b9 <debuginfo_eip+0x313>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f01044a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01044ab:	eb 0c                	jmp    f01044b9 <debuginfo_eip+0x313>
f01044ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01044b2:	eb 05                	jmp    f01044b9 <debuginfo_eip+0x313>
f01044b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01044b9:	83 c4 5c             	add    $0x5c,%esp
f01044bc:	5b                   	pop    %ebx
f01044bd:	5e                   	pop    %esi
f01044be:	5f                   	pop    %edi
f01044bf:	5d                   	pop    %ebp
f01044c0:	c3                   	ret    
f01044c1:	66 90                	xchg   %ax,%ax
f01044c3:	66 90                	xchg   %ax,%ax
f01044c5:	66 90                	xchg   %ax,%ax
f01044c7:	66 90                	xchg   %ax,%ax
f01044c9:	66 90                	xchg   %ax,%ax
f01044cb:	66 90                	xchg   %ax,%ax
f01044cd:	66 90                	xchg   %ax,%ax
f01044cf:	90                   	nop

f01044d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01044d0:	55                   	push   %ebp
f01044d1:	89 e5                	mov    %esp,%ebp
f01044d3:	57                   	push   %edi
f01044d4:	56                   	push   %esi
f01044d5:	53                   	push   %ebx
f01044d6:	83 ec 4c             	sub    $0x4c,%esp
f01044d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01044dc:	89 d7                	mov    %edx,%edi
f01044de:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01044e1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01044e4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01044e7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01044ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01044ef:	39 d8                	cmp    %ebx,%eax
f01044f1:	72 17                	jb     f010450a <printnum+0x3a>
f01044f3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01044f6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f01044f9:	76 0f                	jbe    f010450a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01044fb:	8b 75 14             	mov    0x14(%ebp),%esi
f01044fe:	83 ee 01             	sub    $0x1,%esi
f0104501:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104504:	85 f6                	test   %esi,%esi
f0104506:	7f 63                	jg     f010456b <printnum+0x9b>
f0104508:	eb 75                	jmp    f010457f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010450a:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010450d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0104511:	8b 45 14             	mov    0x14(%ebp),%eax
f0104514:	83 e8 01             	sub    $0x1,%eax
f0104517:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010451b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010451e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104522:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104526:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010452a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010452d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104530:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0104537:	00 
f0104538:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010453b:	89 1c 24             	mov    %ebx,(%esp)
f010453e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104541:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104545:	e8 b6 0a 00 00       	call   f0105000 <__udivdi3>
f010454a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010454d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104550:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104554:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0104558:	89 04 24             	mov    %eax,(%esp)
f010455b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010455f:	89 fa                	mov    %edi,%edx
f0104561:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104564:	e8 67 ff ff ff       	call   f01044d0 <printnum>
f0104569:	eb 14                	jmp    f010457f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010456b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010456f:	8b 45 18             	mov    0x18(%ebp),%eax
f0104572:	89 04 24             	mov    %eax,(%esp)
f0104575:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104577:	83 ee 01             	sub    $0x1,%esi
f010457a:	75 ef                	jne    f010456b <printnum+0x9b>
f010457c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010457f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104583:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104587:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010458a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010458e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0104595:	00 
f0104596:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104599:	89 1c 24             	mov    %ebx,(%esp)
f010459c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010459f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01045a3:	e8 a8 0b 00 00       	call   f0105150 <__umoddi3>
f01045a8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01045ac:	0f be 80 2d 67 10 f0 	movsbl -0xfef98d3(%eax),%eax
f01045b3:	89 04 24             	mov    %eax,(%esp)
f01045b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01045b9:	ff d0                	call   *%eax
}
f01045bb:	83 c4 4c             	add    $0x4c,%esp
f01045be:	5b                   	pop    %ebx
f01045bf:	5e                   	pop    %esi
f01045c0:	5f                   	pop    %edi
f01045c1:	5d                   	pop    %ebp
f01045c2:	c3                   	ret    

f01045c3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01045c3:	55                   	push   %ebp
f01045c4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01045c6:	83 fa 01             	cmp    $0x1,%edx
f01045c9:	7e 0e                	jle    f01045d9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01045cb:	8b 10                	mov    (%eax),%edx
f01045cd:	8d 4a 08             	lea    0x8(%edx),%ecx
f01045d0:	89 08                	mov    %ecx,(%eax)
f01045d2:	8b 02                	mov    (%edx),%eax
f01045d4:	8b 52 04             	mov    0x4(%edx),%edx
f01045d7:	eb 22                	jmp    f01045fb <getuint+0x38>
	else if (lflag)
f01045d9:	85 d2                	test   %edx,%edx
f01045db:	74 10                	je     f01045ed <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01045dd:	8b 10                	mov    (%eax),%edx
f01045df:	8d 4a 04             	lea    0x4(%edx),%ecx
f01045e2:	89 08                	mov    %ecx,(%eax)
f01045e4:	8b 02                	mov    (%edx),%eax
f01045e6:	ba 00 00 00 00       	mov    $0x0,%edx
f01045eb:	eb 0e                	jmp    f01045fb <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01045ed:	8b 10                	mov    (%eax),%edx
f01045ef:	8d 4a 04             	lea    0x4(%edx),%ecx
f01045f2:	89 08                	mov    %ecx,(%eax)
f01045f4:	8b 02                	mov    (%edx),%eax
f01045f6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01045fb:	5d                   	pop    %ebp
f01045fc:	c3                   	ret    

f01045fd <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01045fd:	55                   	push   %ebp
f01045fe:	89 e5                	mov    %esp,%ebp
f0104600:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104603:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104607:	8b 10                	mov    (%eax),%edx
f0104609:	3b 50 04             	cmp    0x4(%eax),%edx
f010460c:	73 0a                	jae    f0104618 <sprintputch+0x1b>
		*b->buf++ = ch;
f010460e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104611:	88 0a                	mov    %cl,(%edx)
f0104613:	83 c2 01             	add    $0x1,%edx
f0104616:	89 10                	mov    %edx,(%eax)
}
f0104618:	5d                   	pop    %ebp
f0104619:	c3                   	ret    

f010461a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010461a:	55                   	push   %ebp
f010461b:	89 e5                	mov    %esp,%ebp
f010461d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0104620:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104623:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104627:	8b 45 10             	mov    0x10(%ebp),%eax
f010462a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010462e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104631:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104635:	8b 45 08             	mov    0x8(%ebp),%eax
f0104638:	89 04 24             	mov    %eax,(%esp)
f010463b:	e8 02 00 00 00       	call   f0104642 <vprintfmt>
	va_end(ap);
}
f0104640:	c9                   	leave  
f0104641:	c3                   	ret    

f0104642 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104642:	55                   	push   %ebp
f0104643:	89 e5                	mov    %esp,%ebp
f0104645:	57                   	push   %edi
f0104646:	56                   	push   %esi
f0104647:	53                   	push   %ebx
f0104648:	83 ec 4c             	sub    $0x4c,%esp
f010464b:	8b 75 08             	mov    0x8(%ebp),%esi
f010464e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104651:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104654:	eb 11                	jmp    f0104667 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104656:	85 c0                	test   %eax,%eax
f0104658:	0f 84 db 03 00 00    	je     f0104a39 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f010465e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104662:	89 04 24             	mov    %eax,(%esp)
f0104665:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104667:	0f b6 07             	movzbl (%edi),%eax
f010466a:	83 c7 01             	add    $0x1,%edi
f010466d:	83 f8 25             	cmp    $0x25,%eax
f0104670:	75 e4                	jne    f0104656 <vprintfmt+0x14>
f0104672:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0104676:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f010467d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104684:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010468b:	ba 00 00 00 00       	mov    $0x0,%edx
f0104690:	eb 2b                	jmp    f01046bd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104692:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104695:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0104699:	eb 22                	jmp    f01046bd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010469b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010469e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f01046a2:	eb 19                	jmp    f01046bd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046a4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01046a7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01046ae:	eb 0d                	jmp    f01046bd <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01046b0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01046b3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01046b6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046bd:	0f b6 0f             	movzbl (%edi),%ecx
f01046c0:	8d 47 01             	lea    0x1(%edi),%eax
f01046c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01046c6:	0f b6 07             	movzbl (%edi),%eax
f01046c9:	83 e8 23             	sub    $0x23,%eax
f01046cc:	3c 55                	cmp    $0x55,%al
f01046ce:	0f 87 40 03 00 00    	ja     f0104a14 <vprintfmt+0x3d2>
f01046d4:	0f b6 c0             	movzbl %al,%eax
f01046d7:	ff 24 85 b8 67 10 f0 	jmp    *-0xfef9848(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01046de:	83 e9 30             	sub    $0x30,%ecx
f01046e1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f01046e4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f01046e8:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01046eb:	83 f9 09             	cmp    $0x9,%ecx
f01046ee:	77 57                	ja     f0104747 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046f0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01046f3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01046f6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01046f9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01046fc:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01046ff:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0104703:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0104706:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0104709:	83 f9 09             	cmp    $0x9,%ecx
f010470c:	76 eb                	jbe    f01046f9 <vprintfmt+0xb7>
f010470e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104711:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104714:	eb 34                	jmp    f010474a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104716:	8b 45 14             	mov    0x14(%ebp),%eax
f0104719:	8d 48 04             	lea    0x4(%eax),%ecx
f010471c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010471f:	8b 00                	mov    (%eax),%eax
f0104721:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104724:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104727:	eb 21                	jmp    f010474a <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0104729:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010472d:	0f 88 71 ff ff ff    	js     f01046a4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104733:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104736:	eb 85                	jmp    f01046bd <vprintfmt+0x7b>
f0104738:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010473b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0104742:	e9 76 ff ff ff       	jmp    f01046bd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104747:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010474a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010474e:	0f 89 69 ff ff ff    	jns    f01046bd <vprintfmt+0x7b>
f0104754:	e9 57 ff ff ff       	jmp    f01046b0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104759:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010475c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010475f:	e9 59 ff ff ff       	jmp    f01046bd <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104764:	8b 45 14             	mov    0x14(%ebp),%eax
f0104767:	8d 50 04             	lea    0x4(%eax),%edx
f010476a:	89 55 14             	mov    %edx,0x14(%ebp)
f010476d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104771:	8b 00                	mov    (%eax),%eax
f0104773:	89 04 24             	mov    %eax,(%esp)
f0104776:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104778:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010477b:	e9 e7 fe ff ff       	jmp    f0104667 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104780:	8b 45 14             	mov    0x14(%ebp),%eax
f0104783:	8d 50 04             	lea    0x4(%eax),%edx
f0104786:	89 55 14             	mov    %edx,0x14(%ebp)
f0104789:	8b 00                	mov    (%eax),%eax
f010478b:	89 c2                	mov    %eax,%edx
f010478d:	c1 fa 1f             	sar    $0x1f,%edx
f0104790:	31 d0                	xor    %edx,%eax
f0104792:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104794:	83 f8 06             	cmp    $0x6,%eax
f0104797:	7f 0b                	jg     f01047a4 <vprintfmt+0x162>
f0104799:	8b 14 85 10 69 10 f0 	mov    -0xfef96f0(,%eax,4),%edx
f01047a0:	85 d2                	test   %edx,%edx
f01047a2:	75 20                	jne    f01047c4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f01047a4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01047a8:	c7 44 24 08 45 67 10 	movl   $0xf0106745,0x8(%esp)
f01047af:	f0 
f01047b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01047b4:	89 34 24             	mov    %esi,(%esp)
f01047b7:	e8 5e fe ff ff       	call   f010461a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047bc:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01047bf:	e9 a3 fe ff ff       	jmp    f0104667 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01047c4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01047c8:	c7 44 24 08 9a 5f 10 	movl   $0xf0105f9a,0x8(%esp)
f01047cf:	f0 
f01047d0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01047d4:	89 34 24             	mov    %esi,(%esp)
f01047d7:	e8 3e fe ff ff       	call   f010461a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047dc:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01047df:	e9 83 fe ff ff       	jmp    f0104667 <vprintfmt+0x25>
f01047e4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01047e7:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01047ea:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01047ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01047f0:	8d 50 04             	lea    0x4(%eax),%edx
f01047f3:	89 55 14             	mov    %edx,0x14(%ebp)
f01047f6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01047f8:	85 ff                	test   %edi,%edi
f01047fa:	b8 3e 67 10 f0       	mov    $0xf010673e,%eax
f01047ff:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104802:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0104806:	74 06                	je     f010480e <vprintfmt+0x1cc>
f0104808:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010480c:	7f 16                	jg     f0104824 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010480e:	0f b6 17             	movzbl (%edi),%edx
f0104811:	0f be c2             	movsbl %dl,%eax
f0104814:	83 c7 01             	add    $0x1,%edi
f0104817:	85 c0                	test   %eax,%eax
f0104819:	0f 85 9f 00 00 00    	jne    f01048be <vprintfmt+0x27c>
f010481f:	e9 8b 00 00 00       	jmp    f01048af <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104824:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104828:	89 3c 24             	mov    %edi,(%esp)
f010482b:	e8 92 03 00 00       	call   f0104bc2 <strnlen>
f0104830:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0104833:	29 c2                	sub    %eax,%edx
f0104835:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0104838:	85 d2                	test   %edx,%edx
f010483a:	7e d2                	jle    f010480e <vprintfmt+0x1cc>
					putch(padc, putdat);
f010483c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0104840:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0104843:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0104846:	89 d7                	mov    %edx,%edi
f0104848:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010484c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010484f:	89 04 24             	mov    %eax,(%esp)
f0104852:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104854:	83 ef 01             	sub    $0x1,%edi
f0104857:	75 ef                	jne    f0104848 <vprintfmt+0x206>
f0104859:	89 7d d8             	mov    %edi,-0x28(%ebp)
f010485c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010485f:	eb ad                	jmp    f010480e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104861:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104865:	74 20                	je     f0104887 <vprintfmt+0x245>
f0104867:	0f be d2             	movsbl %dl,%edx
f010486a:	83 ea 20             	sub    $0x20,%edx
f010486d:	83 fa 5e             	cmp    $0x5e,%edx
f0104870:	76 15                	jbe    f0104887 <vprintfmt+0x245>
					putch('?', putdat);
f0104872:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104875:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104879:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104880:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104883:	ff d1                	call   *%ecx
f0104885:	eb 0f                	jmp    f0104896 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0104887:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010488a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010488e:	89 04 24             	mov    %eax,(%esp)
f0104891:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104894:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104896:	83 eb 01             	sub    $0x1,%ebx
f0104899:	0f b6 17             	movzbl (%edi),%edx
f010489c:	0f be c2             	movsbl %dl,%eax
f010489f:	83 c7 01             	add    $0x1,%edi
f01048a2:	85 c0                	test   %eax,%eax
f01048a4:	75 24                	jne    f01048ca <vprintfmt+0x288>
f01048a6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01048a9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048ac:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01048af:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01048b2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01048b6:	0f 8e ab fd ff ff    	jle    f0104667 <vprintfmt+0x25>
f01048bc:	eb 20                	jmp    f01048de <vprintfmt+0x29c>
f01048be:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01048c1:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01048c4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01048c7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01048ca:	85 f6                	test   %esi,%esi
f01048cc:	78 93                	js     f0104861 <vprintfmt+0x21f>
f01048ce:	83 ee 01             	sub    $0x1,%esi
f01048d1:	79 8e                	jns    f0104861 <vprintfmt+0x21f>
f01048d3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01048d6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048d9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01048dc:	eb d1                	jmp    f01048af <vprintfmt+0x26d>
f01048de:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01048e1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01048e5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01048ec:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01048ee:	83 ef 01             	sub    $0x1,%edi
f01048f1:	75 ee                	jne    f01048e1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01048f3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01048f6:	e9 6c fd ff ff       	jmp    f0104667 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01048fb:	83 fa 01             	cmp    $0x1,%edx
f01048fe:	66 90                	xchg   %ax,%ax
f0104900:	7e 16                	jle    f0104918 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f0104902:	8b 45 14             	mov    0x14(%ebp),%eax
f0104905:	8d 50 08             	lea    0x8(%eax),%edx
f0104908:	89 55 14             	mov    %edx,0x14(%ebp)
f010490b:	8b 10                	mov    (%eax),%edx
f010490d:	8b 48 04             	mov    0x4(%eax),%ecx
f0104910:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0104913:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0104916:	eb 32                	jmp    f010494a <vprintfmt+0x308>
	else if (lflag)
f0104918:	85 d2                	test   %edx,%edx
f010491a:	74 18                	je     f0104934 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f010491c:	8b 45 14             	mov    0x14(%ebp),%eax
f010491f:	8d 50 04             	lea    0x4(%eax),%edx
f0104922:	89 55 14             	mov    %edx,0x14(%ebp)
f0104925:	8b 00                	mov    (%eax),%eax
f0104927:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010492a:	89 c1                	mov    %eax,%ecx
f010492c:	c1 f9 1f             	sar    $0x1f,%ecx
f010492f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0104932:	eb 16                	jmp    f010494a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f0104934:	8b 45 14             	mov    0x14(%ebp),%eax
f0104937:	8d 50 04             	lea    0x4(%eax),%edx
f010493a:	89 55 14             	mov    %edx,0x14(%ebp)
f010493d:	8b 00                	mov    (%eax),%eax
f010493f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104942:	89 c7                	mov    %eax,%edi
f0104944:	c1 ff 1f             	sar    $0x1f,%edi
f0104947:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010494a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010494d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104950:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104955:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0104959:	79 7d                	jns    f01049d8 <vprintfmt+0x396>
				putch('-', putdat);
f010495b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010495f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104966:	ff d6                	call   *%esi
				num = -(long long) num;
f0104968:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010496b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010496e:	f7 d8                	neg    %eax
f0104970:	83 d2 00             	adc    $0x0,%edx
f0104973:	f7 da                	neg    %edx
			}
			base = 10;
f0104975:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010497a:	eb 5c                	jmp    f01049d8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010497c:	8d 45 14             	lea    0x14(%ebp),%eax
f010497f:	e8 3f fc ff ff       	call   f01045c3 <getuint>
			base = 10;
f0104984:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104989:	eb 4d                	jmp    f01049d8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010498b:	8d 45 14             	lea    0x14(%ebp),%eax
f010498e:	e8 30 fc ff ff       	call   f01045c3 <getuint>
			base = 8;
f0104993:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104998:	eb 3e                	jmp    f01049d8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
f010499a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010499e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01049a5:	ff d6                	call   *%esi
			putch('x', putdat);
f01049a7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01049ab:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01049b2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01049b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01049b7:	8d 50 04             	lea    0x4(%eax),%edx
f01049ba:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01049bd:	8b 00                	mov    (%eax),%eax
f01049bf:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01049c4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01049c9:	eb 0d                	jmp    f01049d8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01049cb:	8d 45 14             	lea    0x14(%ebp),%eax
f01049ce:	e8 f0 fb ff ff       	call   f01045c3 <getuint>
			base = 16;
f01049d3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01049d8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f01049dc:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01049e0:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01049e3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01049e7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01049eb:	89 04 24             	mov    %eax,(%esp)
f01049ee:	89 54 24 04          	mov    %edx,0x4(%esp)
f01049f2:	89 da                	mov    %ebx,%edx
f01049f4:	89 f0                	mov    %esi,%eax
f01049f6:	e8 d5 fa ff ff       	call   f01044d0 <printnum>
			break;
f01049fb:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01049fe:	e9 64 fc ff ff       	jmp    f0104667 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104a03:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104a07:	89 0c 24             	mov    %ecx,(%esp)
f0104a0a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a0c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104a0f:	e9 53 fc ff ff       	jmp    f0104667 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104a14:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104a18:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104a1f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104a21:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104a25:	0f 84 3c fc ff ff    	je     f0104667 <vprintfmt+0x25>
f0104a2b:	83 ef 01             	sub    $0x1,%edi
f0104a2e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104a32:	75 f7                	jne    f0104a2b <vprintfmt+0x3e9>
f0104a34:	e9 2e fc ff ff       	jmp    f0104667 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0104a39:	83 c4 4c             	add    $0x4c,%esp
f0104a3c:	5b                   	pop    %ebx
f0104a3d:	5e                   	pop    %esi
f0104a3e:	5f                   	pop    %edi
f0104a3f:	5d                   	pop    %ebp
f0104a40:	c3                   	ret    

f0104a41 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104a41:	55                   	push   %ebp
f0104a42:	89 e5                	mov    %esp,%ebp
f0104a44:	83 ec 28             	sub    $0x28,%esp
f0104a47:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a4a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104a4d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a50:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104a54:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104a57:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104a5e:	85 d2                	test   %edx,%edx
f0104a60:	7e 30                	jle    f0104a92 <vsnprintf+0x51>
f0104a62:	85 c0                	test   %eax,%eax
f0104a64:	74 2c                	je     f0104a92 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104a66:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a69:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104a6d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a70:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104a74:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104a77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a7b:	c7 04 24 fd 45 10 f0 	movl   $0xf01045fd,(%esp)
f0104a82:	e8 bb fb ff ff       	call   f0104642 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104a87:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104a8a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104a8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a90:	eb 05                	jmp    f0104a97 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104a92:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104a97:	c9                   	leave  
f0104a98:	c3                   	ret    

f0104a99 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104a99:	55                   	push   %ebp
f0104a9a:	89 e5                	mov    %esp,%ebp
f0104a9c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104a9f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104aa2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104aa6:	8b 45 10             	mov    0x10(%ebp),%eax
f0104aa9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104aad:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104ab0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ab4:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ab7:	89 04 24             	mov    %eax,(%esp)
f0104aba:	e8 82 ff ff ff       	call   f0104a41 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104abf:	c9                   	leave  
f0104ac0:	c3                   	ret    
f0104ac1:	66 90                	xchg   %ax,%ax
f0104ac3:	66 90                	xchg   %ax,%ax
f0104ac5:	66 90                	xchg   %ax,%ax
f0104ac7:	66 90                	xchg   %ax,%ax
f0104ac9:	66 90                	xchg   %ax,%ax
f0104acb:	66 90                	xchg   %ax,%ax
f0104acd:	66 90                	xchg   %ax,%ax
f0104acf:	90                   	nop

f0104ad0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104ad0:	55                   	push   %ebp
f0104ad1:	89 e5                	mov    %esp,%ebp
f0104ad3:	57                   	push   %edi
f0104ad4:	56                   	push   %esi
f0104ad5:	53                   	push   %ebx
f0104ad6:	83 ec 1c             	sub    $0x1c,%esp
f0104ad9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104adc:	85 c0                	test   %eax,%eax
f0104ade:	74 10                	je     f0104af0 <readline+0x20>
		cprintf("%s", prompt);
f0104ae0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ae4:	c7 04 24 9a 5f 10 f0 	movl   $0xf0105f9a,(%esp)
f0104aeb:	e8 2e ec ff ff       	call   f010371e <cprintf>

	i = 0;
	echoing = iscons(0);
f0104af0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104af7:	e8 51 bb ff ff       	call   f010064d <iscons>
f0104afc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104afe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104b03:	e8 34 bb ff ff       	call   f010063c <getchar>
f0104b08:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104b0a:	85 c0                	test   %eax,%eax
f0104b0c:	79 17                	jns    f0104b25 <readline+0x55>
			cprintf("read error: %e\n", c);
f0104b0e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b12:	c7 04 24 2c 69 10 f0 	movl   $0xf010692c,(%esp)
f0104b19:	e8 00 ec ff ff       	call   f010371e <cprintf>
			return NULL;
f0104b1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b23:	eb 6d                	jmp    f0104b92 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104b25:	83 f8 7f             	cmp    $0x7f,%eax
f0104b28:	74 05                	je     f0104b2f <readline+0x5f>
f0104b2a:	83 f8 08             	cmp    $0x8,%eax
f0104b2d:	75 19                	jne    f0104b48 <readline+0x78>
f0104b2f:	85 f6                	test   %esi,%esi
f0104b31:	7e 15                	jle    f0104b48 <readline+0x78>
			if (echoing)
f0104b33:	85 ff                	test   %edi,%edi
f0104b35:	74 0c                	je     f0104b43 <readline+0x73>
				cputchar('\b');
f0104b37:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0104b3e:	e8 e9 ba ff ff       	call   f010062c <cputchar>
			i--;
f0104b43:	83 ee 01             	sub    $0x1,%esi
f0104b46:	eb bb                	jmp    f0104b03 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104b48:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104b4e:	7f 1c                	jg     f0104b6c <readline+0x9c>
f0104b50:	83 fb 1f             	cmp    $0x1f,%ebx
f0104b53:	7e 17                	jle    f0104b6c <readline+0x9c>
			if (echoing)
f0104b55:	85 ff                	test   %edi,%edi
f0104b57:	74 08                	je     f0104b61 <readline+0x91>
				cputchar(c);
f0104b59:	89 1c 24             	mov    %ebx,(%esp)
f0104b5c:	e8 cb ba ff ff       	call   f010062c <cputchar>
			buf[i++] = c;
f0104b61:	88 9e a0 eb 17 f0    	mov    %bl,-0xfe81460(%esi)
f0104b67:	83 c6 01             	add    $0x1,%esi
f0104b6a:	eb 97                	jmp    f0104b03 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104b6c:	83 fb 0d             	cmp    $0xd,%ebx
f0104b6f:	74 05                	je     f0104b76 <readline+0xa6>
f0104b71:	83 fb 0a             	cmp    $0xa,%ebx
f0104b74:	75 8d                	jne    f0104b03 <readline+0x33>
			if (echoing)
f0104b76:	85 ff                	test   %edi,%edi
f0104b78:	74 0c                	je     f0104b86 <readline+0xb6>
				cputchar('\n');
f0104b7a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104b81:	e8 a6 ba ff ff       	call   f010062c <cputchar>
			buf[i] = 0;
f0104b86:	c6 86 a0 eb 17 f0 00 	movb   $0x0,-0xfe81460(%esi)
			return buf;
f0104b8d:	b8 a0 eb 17 f0       	mov    $0xf017eba0,%eax
		}
	}
}
f0104b92:	83 c4 1c             	add    $0x1c,%esp
f0104b95:	5b                   	pop    %ebx
f0104b96:	5e                   	pop    %esi
f0104b97:	5f                   	pop    %edi
f0104b98:	5d                   	pop    %ebp
f0104b99:	c3                   	ret    
f0104b9a:	66 90                	xchg   %ax,%ax
f0104b9c:	66 90                	xchg   %ax,%ax
f0104b9e:	66 90                	xchg   %ax,%ax

f0104ba0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104ba0:	55                   	push   %ebp
f0104ba1:	89 e5                	mov    %esp,%ebp
f0104ba3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104ba6:	80 3a 00             	cmpb   $0x0,(%edx)
f0104ba9:	74 10                	je     f0104bbb <strlen+0x1b>
f0104bab:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0104bb0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104bb3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104bb7:	75 f7                	jne    f0104bb0 <strlen+0x10>
f0104bb9:	eb 05                	jmp    f0104bc0 <strlen+0x20>
f0104bbb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0104bc0:	5d                   	pop    %ebp
f0104bc1:	c3                   	ret    

f0104bc2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104bc2:	55                   	push   %ebp
f0104bc3:	89 e5                	mov    %esp,%ebp
f0104bc5:	53                   	push   %ebx
f0104bc6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104bc9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104bcc:	85 c9                	test   %ecx,%ecx
f0104bce:	74 1c                	je     f0104bec <strnlen+0x2a>
f0104bd0:	80 3b 00             	cmpb   $0x0,(%ebx)
f0104bd3:	74 1e                	je     f0104bf3 <strnlen+0x31>
f0104bd5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0104bda:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104bdc:	39 ca                	cmp    %ecx,%edx
f0104bde:	74 18                	je     f0104bf8 <strnlen+0x36>
f0104be0:	83 c2 01             	add    $0x1,%edx
f0104be3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0104be8:	75 f0                	jne    f0104bda <strnlen+0x18>
f0104bea:	eb 0c                	jmp    f0104bf8 <strnlen+0x36>
f0104bec:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bf1:	eb 05                	jmp    f0104bf8 <strnlen+0x36>
f0104bf3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0104bf8:	5b                   	pop    %ebx
f0104bf9:	5d                   	pop    %ebp
f0104bfa:	c3                   	ret    

f0104bfb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104bfb:	55                   	push   %ebp
f0104bfc:	89 e5                	mov    %esp,%ebp
f0104bfe:	53                   	push   %ebx
f0104bff:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c02:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104c05:	89 c2                	mov    %eax,%edx
f0104c07:	0f b6 19             	movzbl (%ecx),%ebx
f0104c0a:	88 1a                	mov    %bl,(%edx)
f0104c0c:	83 c2 01             	add    $0x1,%edx
f0104c0f:	83 c1 01             	add    $0x1,%ecx
f0104c12:	84 db                	test   %bl,%bl
f0104c14:	75 f1                	jne    f0104c07 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104c16:	5b                   	pop    %ebx
f0104c17:	5d                   	pop    %ebp
f0104c18:	c3                   	ret    

f0104c19 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104c19:	55                   	push   %ebp
f0104c1a:	89 e5                	mov    %esp,%ebp
f0104c1c:	53                   	push   %ebx
f0104c1d:	83 ec 08             	sub    $0x8,%esp
f0104c20:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104c23:	89 1c 24             	mov    %ebx,(%esp)
f0104c26:	e8 75 ff ff ff       	call   f0104ba0 <strlen>
	strcpy(dst + len, src);
f0104c2b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c2e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104c32:	01 d8                	add    %ebx,%eax
f0104c34:	89 04 24             	mov    %eax,(%esp)
f0104c37:	e8 bf ff ff ff       	call   f0104bfb <strcpy>
	return dst;
}
f0104c3c:	89 d8                	mov    %ebx,%eax
f0104c3e:	83 c4 08             	add    $0x8,%esp
f0104c41:	5b                   	pop    %ebx
f0104c42:	5d                   	pop    %ebp
f0104c43:	c3                   	ret    

f0104c44 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104c44:	55                   	push   %ebp
f0104c45:	89 e5                	mov    %esp,%ebp
f0104c47:	56                   	push   %esi
f0104c48:	53                   	push   %ebx
f0104c49:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c4c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c4f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c52:	85 db                	test   %ebx,%ebx
f0104c54:	74 16                	je     f0104c6c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f0104c56:	01 f3                	add    %esi,%ebx
f0104c58:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f0104c5a:	0f b6 02             	movzbl (%edx),%eax
f0104c5d:	88 01                	mov    %al,(%ecx)
f0104c5f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104c62:	80 3a 01             	cmpb   $0x1,(%edx)
f0104c65:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c68:	39 d9                	cmp    %ebx,%ecx
f0104c6a:	75 ee                	jne    f0104c5a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104c6c:	89 f0                	mov    %esi,%eax
f0104c6e:	5b                   	pop    %ebx
f0104c6f:	5e                   	pop    %esi
f0104c70:	5d                   	pop    %ebp
f0104c71:	c3                   	ret    

f0104c72 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104c72:	55                   	push   %ebp
f0104c73:	89 e5                	mov    %esp,%ebp
f0104c75:	57                   	push   %edi
f0104c76:	56                   	push   %esi
f0104c77:	53                   	push   %ebx
f0104c78:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104c7b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104c7e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104c81:	89 f8                	mov    %edi,%eax
f0104c83:	85 f6                	test   %esi,%esi
f0104c85:	74 33                	je     f0104cba <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f0104c87:	83 fe 01             	cmp    $0x1,%esi
f0104c8a:	74 25                	je     f0104cb1 <strlcpy+0x3f>
f0104c8c:	0f b6 0b             	movzbl (%ebx),%ecx
f0104c8f:	84 c9                	test   %cl,%cl
f0104c91:	74 22                	je     f0104cb5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0104c93:	83 ee 02             	sub    $0x2,%esi
f0104c96:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104c9b:	88 08                	mov    %cl,(%eax)
f0104c9d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104ca0:	39 f2                	cmp    %esi,%edx
f0104ca2:	74 13                	je     f0104cb7 <strlcpy+0x45>
f0104ca4:	83 c2 01             	add    $0x1,%edx
f0104ca7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0104cab:	84 c9                	test   %cl,%cl
f0104cad:	75 ec                	jne    f0104c9b <strlcpy+0x29>
f0104caf:	eb 06                	jmp    f0104cb7 <strlcpy+0x45>
f0104cb1:	89 f8                	mov    %edi,%eax
f0104cb3:	eb 02                	jmp    f0104cb7 <strlcpy+0x45>
f0104cb5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104cb7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104cba:	29 f8                	sub    %edi,%eax
}
f0104cbc:	5b                   	pop    %ebx
f0104cbd:	5e                   	pop    %esi
f0104cbe:	5f                   	pop    %edi
f0104cbf:	5d                   	pop    %ebp
f0104cc0:	c3                   	ret    

f0104cc1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104cc1:	55                   	push   %ebp
f0104cc2:	89 e5                	mov    %esp,%ebp
f0104cc4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104cc7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104cca:	0f b6 01             	movzbl (%ecx),%eax
f0104ccd:	84 c0                	test   %al,%al
f0104ccf:	74 15                	je     f0104ce6 <strcmp+0x25>
f0104cd1:	3a 02                	cmp    (%edx),%al
f0104cd3:	75 11                	jne    f0104ce6 <strcmp+0x25>
		p++, q++;
f0104cd5:	83 c1 01             	add    $0x1,%ecx
f0104cd8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104cdb:	0f b6 01             	movzbl (%ecx),%eax
f0104cde:	84 c0                	test   %al,%al
f0104ce0:	74 04                	je     f0104ce6 <strcmp+0x25>
f0104ce2:	3a 02                	cmp    (%edx),%al
f0104ce4:	74 ef                	je     f0104cd5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104ce6:	0f b6 c0             	movzbl %al,%eax
f0104ce9:	0f b6 12             	movzbl (%edx),%edx
f0104cec:	29 d0                	sub    %edx,%eax
}
f0104cee:	5d                   	pop    %ebp
f0104cef:	c3                   	ret    

f0104cf0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104cf0:	55                   	push   %ebp
f0104cf1:	89 e5                	mov    %esp,%ebp
f0104cf3:	56                   	push   %esi
f0104cf4:	53                   	push   %ebx
f0104cf5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104cf8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104cfb:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0104cfe:	85 f6                	test   %esi,%esi
f0104d00:	74 29                	je     f0104d2b <strncmp+0x3b>
f0104d02:	0f b6 03             	movzbl (%ebx),%eax
f0104d05:	84 c0                	test   %al,%al
f0104d07:	74 30                	je     f0104d39 <strncmp+0x49>
f0104d09:	3a 02                	cmp    (%edx),%al
f0104d0b:	75 2c                	jne    f0104d39 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0104d0d:	8d 43 01             	lea    0x1(%ebx),%eax
f0104d10:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0104d12:	89 c3                	mov    %eax,%ebx
f0104d14:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104d17:	39 f0                	cmp    %esi,%eax
f0104d19:	74 17                	je     f0104d32 <strncmp+0x42>
f0104d1b:	0f b6 08             	movzbl (%eax),%ecx
f0104d1e:	84 c9                	test   %cl,%cl
f0104d20:	74 17                	je     f0104d39 <strncmp+0x49>
f0104d22:	83 c0 01             	add    $0x1,%eax
f0104d25:	3a 0a                	cmp    (%edx),%cl
f0104d27:	74 e9                	je     f0104d12 <strncmp+0x22>
f0104d29:	eb 0e                	jmp    f0104d39 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104d2b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d30:	eb 0f                	jmp    f0104d41 <strncmp+0x51>
f0104d32:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d37:	eb 08                	jmp    f0104d41 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104d39:	0f b6 03             	movzbl (%ebx),%eax
f0104d3c:	0f b6 12             	movzbl (%edx),%edx
f0104d3f:	29 d0                	sub    %edx,%eax
}
f0104d41:	5b                   	pop    %ebx
f0104d42:	5e                   	pop    %esi
f0104d43:	5d                   	pop    %ebp
f0104d44:	c3                   	ret    

f0104d45 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104d45:	55                   	push   %ebp
f0104d46:	89 e5                	mov    %esp,%ebp
f0104d48:	53                   	push   %ebx
f0104d49:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d4c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0104d4f:	0f b6 18             	movzbl (%eax),%ebx
f0104d52:	84 db                	test   %bl,%bl
f0104d54:	74 1d                	je     f0104d73 <strchr+0x2e>
f0104d56:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0104d58:	38 d3                	cmp    %dl,%bl
f0104d5a:	75 06                	jne    f0104d62 <strchr+0x1d>
f0104d5c:	eb 1a                	jmp    f0104d78 <strchr+0x33>
f0104d5e:	38 ca                	cmp    %cl,%dl
f0104d60:	74 16                	je     f0104d78 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104d62:	83 c0 01             	add    $0x1,%eax
f0104d65:	0f b6 10             	movzbl (%eax),%edx
f0104d68:	84 d2                	test   %dl,%dl
f0104d6a:	75 f2                	jne    f0104d5e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0104d6c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d71:	eb 05                	jmp    f0104d78 <strchr+0x33>
f0104d73:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d78:	5b                   	pop    %ebx
f0104d79:	5d                   	pop    %ebp
f0104d7a:	c3                   	ret    

f0104d7b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104d7b:	55                   	push   %ebp
f0104d7c:	89 e5                	mov    %esp,%ebp
f0104d7e:	53                   	push   %ebx
f0104d7f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d82:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0104d85:	0f b6 18             	movzbl (%eax),%ebx
f0104d88:	84 db                	test   %bl,%bl
f0104d8a:	74 16                	je     f0104da2 <strfind+0x27>
f0104d8c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0104d8e:	38 d3                	cmp    %dl,%bl
f0104d90:	75 06                	jne    f0104d98 <strfind+0x1d>
f0104d92:	eb 0e                	jmp    f0104da2 <strfind+0x27>
f0104d94:	38 ca                	cmp    %cl,%dl
f0104d96:	74 0a                	je     f0104da2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104d98:	83 c0 01             	add    $0x1,%eax
f0104d9b:	0f b6 10             	movzbl (%eax),%edx
f0104d9e:	84 d2                	test   %dl,%dl
f0104da0:	75 f2                	jne    f0104d94 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f0104da2:	5b                   	pop    %ebx
f0104da3:	5d                   	pop    %ebp
f0104da4:	c3                   	ret    

f0104da5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104da5:	55                   	push   %ebp
f0104da6:	89 e5                	mov    %esp,%ebp
f0104da8:	83 ec 0c             	sub    $0xc,%esp
f0104dab:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0104dae:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104db1:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104db4:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104db7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104dba:	85 c9                	test   %ecx,%ecx
f0104dbc:	74 36                	je     f0104df4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104dbe:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104dc4:	75 28                	jne    f0104dee <memset+0x49>
f0104dc6:	f6 c1 03             	test   $0x3,%cl
f0104dc9:	75 23                	jne    f0104dee <memset+0x49>
		c &= 0xFF;
f0104dcb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104dcf:	89 d3                	mov    %edx,%ebx
f0104dd1:	c1 e3 08             	shl    $0x8,%ebx
f0104dd4:	89 d6                	mov    %edx,%esi
f0104dd6:	c1 e6 18             	shl    $0x18,%esi
f0104dd9:	89 d0                	mov    %edx,%eax
f0104ddb:	c1 e0 10             	shl    $0x10,%eax
f0104dde:	09 f0                	or     %esi,%eax
f0104de0:	09 c2                	or     %eax,%edx
f0104de2:	89 d0                	mov    %edx,%eax
f0104de4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104de6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104de9:	fc                   	cld    
f0104dea:	f3 ab                	rep stos %eax,%es:(%edi)
f0104dec:	eb 06                	jmp    f0104df4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104dee:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104df1:	fc                   	cld    
f0104df2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104df4:	89 f8                	mov    %edi,%eax
f0104df6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104df9:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104dfc:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104dff:	89 ec                	mov    %ebp,%esp
f0104e01:	5d                   	pop    %ebp
f0104e02:	c3                   	ret    

f0104e03 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104e03:	55                   	push   %ebp
f0104e04:	89 e5                	mov    %esp,%ebp
f0104e06:	83 ec 08             	sub    $0x8,%esp
f0104e09:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104e0c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104e0f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e12:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e15:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104e18:	39 c6                	cmp    %eax,%esi
f0104e1a:	73 36                	jae    f0104e52 <memmove+0x4f>
f0104e1c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104e1f:	39 d0                	cmp    %edx,%eax
f0104e21:	73 2f                	jae    f0104e52 <memmove+0x4f>
		s += n;
		d += n;
f0104e23:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104e26:	f6 c2 03             	test   $0x3,%dl
f0104e29:	75 1b                	jne    f0104e46 <memmove+0x43>
f0104e2b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104e31:	75 13                	jne    f0104e46 <memmove+0x43>
f0104e33:	f6 c1 03             	test   $0x3,%cl
f0104e36:	75 0e                	jne    f0104e46 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104e38:	83 ef 04             	sub    $0x4,%edi
f0104e3b:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104e3e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104e41:	fd                   	std    
f0104e42:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104e44:	eb 09                	jmp    f0104e4f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104e46:	83 ef 01             	sub    $0x1,%edi
f0104e49:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104e4c:	fd                   	std    
f0104e4d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104e4f:	fc                   	cld    
f0104e50:	eb 20                	jmp    f0104e72 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104e52:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104e58:	75 13                	jne    f0104e6d <memmove+0x6a>
f0104e5a:	a8 03                	test   $0x3,%al
f0104e5c:	75 0f                	jne    f0104e6d <memmove+0x6a>
f0104e5e:	f6 c1 03             	test   $0x3,%cl
f0104e61:	75 0a                	jne    f0104e6d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104e63:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104e66:	89 c7                	mov    %eax,%edi
f0104e68:	fc                   	cld    
f0104e69:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104e6b:	eb 05                	jmp    f0104e72 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104e6d:	89 c7                	mov    %eax,%edi
f0104e6f:	fc                   	cld    
f0104e70:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104e72:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104e75:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104e78:	89 ec                	mov    %ebp,%esp
f0104e7a:	5d                   	pop    %ebp
f0104e7b:	c3                   	ret    

f0104e7c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0104e7c:	55                   	push   %ebp
f0104e7d:	89 e5                	mov    %esp,%ebp
f0104e7f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104e82:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e85:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104e89:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104e8c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e90:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e93:	89 04 24             	mov    %eax,(%esp)
f0104e96:	e8 68 ff ff ff       	call   f0104e03 <memmove>
}
f0104e9b:	c9                   	leave  
f0104e9c:	c3                   	ret    

f0104e9d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104e9d:	55                   	push   %ebp
f0104e9e:	89 e5                	mov    %esp,%ebp
f0104ea0:	57                   	push   %edi
f0104ea1:	56                   	push   %esi
f0104ea2:	53                   	push   %ebx
f0104ea3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104ea6:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104ea9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104eac:	8d 78 ff             	lea    -0x1(%eax),%edi
f0104eaf:	85 c0                	test   %eax,%eax
f0104eb1:	74 36                	je     f0104ee9 <memcmp+0x4c>
		if (*s1 != *s2)
f0104eb3:	0f b6 03             	movzbl (%ebx),%eax
f0104eb6:	0f b6 0e             	movzbl (%esi),%ecx
f0104eb9:	38 c8                	cmp    %cl,%al
f0104ebb:	75 17                	jne    f0104ed4 <memcmp+0x37>
f0104ebd:	ba 00 00 00 00       	mov    $0x0,%edx
f0104ec2:	eb 1a                	jmp    f0104ede <memcmp+0x41>
f0104ec4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0104ec9:	83 c2 01             	add    $0x1,%edx
f0104ecc:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0104ed0:	38 c8                	cmp    %cl,%al
f0104ed2:	74 0a                	je     f0104ede <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0104ed4:	0f b6 c0             	movzbl %al,%eax
f0104ed7:	0f b6 c9             	movzbl %cl,%ecx
f0104eda:	29 c8                	sub    %ecx,%eax
f0104edc:	eb 10                	jmp    f0104eee <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104ede:	39 fa                	cmp    %edi,%edx
f0104ee0:	75 e2                	jne    f0104ec4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104ee2:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ee7:	eb 05                	jmp    f0104eee <memcmp+0x51>
f0104ee9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104eee:	5b                   	pop    %ebx
f0104eef:	5e                   	pop    %esi
f0104ef0:	5f                   	pop    %edi
f0104ef1:	5d                   	pop    %ebp
f0104ef2:	c3                   	ret    

f0104ef3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104ef3:	55                   	push   %ebp
f0104ef4:	89 e5                	mov    %esp,%ebp
f0104ef6:	53                   	push   %ebx
f0104ef7:	8b 45 08             	mov    0x8(%ebp),%eax
f0104efa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0104efd:	89 c2                	mov    %eax,%edx
f0104eff:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104f02:	39 d0                	cmp    %edx,%eax
f0104f04:	73 13                	jae    f0104f19 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104f06:	89 d9                	mov    %ebx,%ecx
f0104f08:	38 18                	cmp    %bl,(%eax)
f0104f0a:	75 06                	jne    f0104f12 <memfind+0x1f>
f0104f0c:	eb 0b                	jmp    f0104f19 <memfind+0x26>
f0104f0e:	38 08                	cmp    %cl,(%eax)
f0104f10:	74 07                	je     f0104f19 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104f12:	83 c0 01             	add    $0x1,%eax
f0104f15:	39 d0                	cmp    %edx,%eax
f0104f17:	75 f5                	jne    f0104f0e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104f19:	5b                   	pop    %ebx
f0104f1a:	5d                   	pop    %ebp
f0104f1b:	c3                   	ret    

f0104f1c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104f1c:	55                   	push   %ebp
f0104f1d:	89 e5                	mov    %esp,%ebp
f0104f1f:	57                   	push   %edi
f0104f20:	56                   	push   %esi
f0104f21:	53                   	push   %ebx
f0104f22:	83 ec 04             	sub    $0x4,%esp
f0104f25:	8b 55 08             	mov    0x8(%ebp),%edx
f0104f28:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104f2b:	0f b6 02             	movzbl (%edx),%eax
f0104f2e:	3c 09                	cmp    $0x9,%al
f0104f30:	74 04                	je     f0104f36 <strtol+0x1a>
f0104f32:	3c 20                	cmp    $0x20,%al
f0104f34:	75 0e                	jne    f0104f44 <strtol+0x28>
		s++;
f0104f36:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104f39:	0f b6 02             	movzbl (%edx),%eax
f0104f3c:	3c 09                	cmp    $0x9,%al
f0104f3e:	74 f6                	je     f0104f36 <strtol+0x1a>
f0104f40:	3c 20                	cmp    $0x20,%al
f0104f42:	74 f2                	je     f0104f36 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104f44:	3c 2b                	cmp    $0x2b,%al
f0104f46:	75 0a                	jne    f0104f52 <strtol+0x36>
		s++;
f0104f48:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104f4b:	bf 00 00 00 00       	mov    $0x0,%edi
f0104f50:	eb 10                	jmp    f0104f62 <strtol+0x46>
f0104f52:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104f57:	3c 2d                	cmp    $0x2d,%al
f0104f59:	75 07                	jne    f0104f62 <strtol+0x46>
		s++, neg = 1;
f0104f5b:	83 c2 01             	add    $0x1,%edx
f0104f5e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104f62:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104f68:	75 15                	jne    f0104f7f <strtol+0x63>
f0104f6a:	80 3a 30             	cmpb   $0x30,(%edx)
f0104f6d:	75 10                	jne    f0104f7f <strtol+0x63>
f0104f6f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104f73:	75 0a                	jne    f0104f7f <strtol+0x63>
		s += 2, base = 16;
f0104f75:	83 c2 02             	add    $0x2,%edx
f0104f78:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104f7d:	eb 10                	jmp    f0104f8f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0104f7f:	85 db                	test   %ebx,%ebx
f0104f81:	75 0c                	jne    f0104f8f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104f83:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104f85:	80 3a 30             	cmpb   $0x30,(%edx)
f0104f88:	75 05                	jne    f0104f8f <strtol+0x73>
		s++, base = 8;
f0104f8a:	83 c2 01             	add    $0x1,%edx
f0104f8d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0104f8f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f94:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104f97:	0f b6 0a             	movzbl (%edx),%ecx
f0104f9a:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104f9d:	89 f3                	mov    %esi,%ebx
f0104f9f:	80 fb 09             	cmp    $0x9,%bl
f0104fa2:	77 08                	ja     f0104fac <strtol+0x90>
			dig = *s - '0';
f0104fa4:	0f be c9             	movsbl %cl,%ecx
f0104fa7:	83 e9 30             	sub    $0x30,%ecx
f0104faa:	eb 22                	jmp    f0104fce <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0104fac:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104faf:	89 f3                	mov    %esi,%ebx
f0104fb1:	80 fb 19             	cmp    $0x19,%bl
f0104fb4:	77 08                	ja     f0104fbe <strtol+0xa2>
			dig = *s - 'a' + 10;
f0104fb6:	0f be c9             	movsbl %cl,%ecx
f0104fb9:	83 e9 57             	sub    $0x57,%ecx
f0104fbc:	eb 10                	jmp    f0104fce <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0104fbe:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104fc1:	89 f3                	mov    %esi,%ebx
f0104fc3:	80 fb 19             	cmp    $0x19,%bl
f0104fc6:	77 16                	ja     f0104fde <strtol+0xc2>
			dig = *s - 'A' + 10;
f0104fc8:	0f be c9             	movsbl %cl,%ecx
f0104fcb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104fce:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0104fd1:	7d 0f                	jge    f0104fe2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0104fd3:	83 c2 01             	add    $0x1,%edx
f0104fd6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0104fda:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0104fdc:	eb b9                	jmp    f0104f97 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104fde:	89 c1                	mov    %eax,%ecx
f0104fe0:	eb 02                	jmp    f0104fe4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104fe2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104fe4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104fe8:	74 05                	je     f0104fef <strtol+0xd3>
		*endptr = (char *) s;
f0104fea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104fed:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104fef:	89 ca                	mov    %ecx,%edx
f0104ff1:	f7 da                	neg    %edx
f0104ff3:	85 ff                	test   %edi,%edi
f0104ff5:	0f 45 c2             	cmovne %edx,%eax
}
f0104ff8:	83 c4 04             	add    $0x4,%esp
f0104ffb:	5b                   	pop    %ebx
f0104ffc:	5e                   	pop    %esi
f0104ffd:	5f                   	pop    %edi
f0104ffe:	5d                   	pop    %ebp
f0104fff:	c3                   	ret    

f0105000 <__udivdi3>:
f0105000:	83 ec 1c             	sub    $0x1c,%esp
f0105003:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0105007:	89 7c 24 14          	mov    %edi,0x14(%esp)
f010500b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010500f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0105013:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0105017:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f010501b:	85 c0                	test   %eax,%eax
f010501d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0105021:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0105025:	89 ea                	mov    %ebp,%edx
f0105027:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010502b:	75 33                	jne    f0105060 <__udivdi3+0x60>
f010502d:	39 e9                	cmp    %ebp,%ecx
f010502f:	77 6f                	ja     f01050a0 <__udivdi3+0xa0>
f0105031:	85 c9                	test   %ecx,%ecx
f0105033:	89 ce                	mov    %ecx,%esi
f0105035:	75 0b                	jne    f0105042 <__udivdi3+0x42>
f0105037:	b8 01 00 00 00       	mov    $0x1,%eax
f010503c:	31 d2                	xor    %edx,%edx
f010503e:	f7 f1                	div    %ecx
f0105040:	89 c6                	mov    %eax,%esi
f0105042:	31 d2                	xor    %edx,%edx
f0105044:	89 e8                	mov    %ebp,%eax
f0105046:	f7 f6                	div    %esi
f0105048:	89 c5                	mov    %eax,%ebp
f010504a:	89 f8                	mov    %edi,%eax
f010504c:	f7 f6                	div    %esi
f010504e:	89 ea                	mov    %ebp,%edx
f0105050:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105054:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0105058:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010505c:	83 c4 1c             	add    $0x1c,%esp
f010505f:	c3                   	ret    
f0105060:	39 e8                	cmp    %ebp,%eax
f0105062:	77 24                	ja     f0105088 <__udivdi3+0x88>
f0105064:	0f bd c8             	bsr    %eax,%ecx
f0105067:	83 f1 1f             	xor    $0x1f,%ecx
f010506a:	89 0c 24             	mov    %ecx,(%esp)
f010506d:	75 49                	jne    f01050b8 <__udivdi3+0xb8>
f010506f:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105073:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0105077:	0f 86 ab 00 00 00    	jbe    f0105128 <__udivdi3+0x128>
f010507d:	39 e8                	cmp    %ebp,%eax
f010507f:	0f 82 a3 00 00 00    	jb     f0105128 <__udivdi3+0x128>
f0105085:	8d 76 00             	lea    0x0(%esi),%esi
f0105088:	31 d2                	xor    %edx,%edx
f010508a:	31 c0                	xor    %eax,%eax
f010508c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105090:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0105094:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0105098:	83 c4 1c             	add    $0x1c,%esp
f010509b:	c3                   	ret    
f010509c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01050a0:	89 f8                	mov    %edi,%eax
f01050a2:	f7 f1                	div    %ecx
f01050a4:	31 d2                	xor    %edx,%edx
f01050a6:	8b 74 24 10          	mov    0x10(%esp),%esi
f01050aa:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01050ae:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01050b2:	83 c4 1c             	add    $0x1c,%esp
f01050b5:	c3                   	ret    
f01050b6:	66 90                	xchg   %ax,%ax
f01050b8:	0f b6 0c 24          	movzbl (%esp),%ecx
f01050bc:	89 c6                	mov    %eax,%esi
f01050be:	b8 20 00 00 00       	mov    $0x20,%eax
f01050c3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f01050c7:	2b 04 24             	sub    (%esp),%eax
f01050ca:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01050ce:	d3 e6                	shl    %cl,%esi
f01050d0:	89 c1                	mov    %eax,%ecx
f01050d2:	d3 ed                	shr    %cl,%ebp
f01050d4:	0f b6 0c 24          	movzbl (%esp),%ecx
f01050d8:	09 f5                	or     %esi,%ebp
f01050da:	8b 74 24 04          	mov    0x4(%esp),%esi
f01050de:	d3 e6                	shl    %cl,%esi
f01050e0:	89 c1                	mov    %eax,%ecx
f01050e2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01050e6:	89 d6                	mov    %edx,%esi
f01050e8:	d3 ee                	shr    %cl,%esi
f01050ea:	0f b6 0c 24          	movzbl (%esp),%ecx
f01050ee:	d3 e2                	shl    %cl,%edx
f01050f0:	89 c1                	mov    %eax,%ecx
f01050f2:	d3 ef                	shr    %cl,%edi
f01050f4:	09 d7                	or     %edx,%edi
f01050f6:	89 f2                	mov    %esi,%edx
f01050f8:	89 f8                	mov    %edi,%eax
f01050fa:	f7 f5                	div    %ebp
f01050fc:	89 d6                	mov    %edx,%esi
f01050fe:	89 c7                	mov    %eax,%edi
f0105100:	f7 64 24 04          	mull   0x4(%esp)
f0105104:	39 d6                	cmp    %edx,%esi
f0105106:	72 30                	jb     f0105138 <__udivdi3+0x138>
f0105108:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f010510c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0105110:	d3 e5                	shl    %cl,%ebp
f0105112:	39 c5                	cmp    %eax,%ebp
f0105114:	73 04                	jae    f010511a <__udivdi3+0x11a>
f0105116:	39 d6                	cmp    %edx,%esi
f0105118:	74 1e                	je     f0105138 <__udivdi3+0x138>
f010511a:	89 f8                	mov    %edi,%eax
f010511c:	31 d2                	xor    %edx,%edx
f010511e:	e9 69 ff ff ff       	jmp    f010508c <__udivdi3+0x8c>
f0105123:	90                   	nop
f0105124:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105128:	31 d2                	xor    %edx,%edx
f010512a:	b8 01 00 00 00       	mov    $0x1,%eax
f010512f:	e9 58 ff ff ff       	jmp    f010508c <__udivdi3+0x8c>
f0105134:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105138:	8d 47 ff             	lea    -0x1(%edi),%eax
f010513b:	31 d2                	xor    %edx,%edx
f010513d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105141:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0105145:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0105149:	83 c4 1c             	add    $0x1c,%esp
f010514c:	c3                   	ret    
f010514d:	66 90                	xchg   %ax,%ax
f010514f:	90                   	nop

f0105150 <__umoddi3>:
f0105150:	83 ec 2c             	sub    $0x2c,%esp
f0105153:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0105157:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010515b:	89 74 24 20          	mov    %esi,0x20(%esp)
f010515f:	8b 74 24 38          	mov    0x38(%esp),%esi
f0105163:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0105167:	8b 7c 24 34          	mov    0x34(%esp),%edi
f010516b:	85 c0                	test   %eax,%eax
f010516d:	89 c2                	mov    %eax,%edx
f010516f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0105173:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0105177:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010517b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010517f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0105183:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0105187:	75 1f                	jne    f01051a8 <__umoddi3+0x58>
f0105189:	39 fe                	cmp    %edi,%esi
f010518b:	76 63                	jbe    f01051f0 <__umoddi3+0xa0>
f010518d:	89 c8                	mov    %ecx,%eax
f010518f:	89 fa                	mov    %edi,%edx
f0105191:	f7 f6                	div    %esi
f0105193:	89 d0                	mov    %edx,%eax
f0105195:	31 d2                	xor    %edx,%edx
f0105197:	8b 74 24 20          	mov    0x20(%esp),%esi
f010519b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010519f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01051a3:	83 c4 2c             	add    $0x2c,%esp
f01051a6:	c3                   	ret    
f01051a7:	90                   	nop
f01051a8:	39 f8                	cmp    %edi,%eax
f01051aa:	77 64                	ja     f0105210 <__umoddi3+0xc0>
f01051ac:	0f bd e8             	bsr    %eax,%ebp
f01051af:	83 f5 1f             	xor    $0x1f,%ebp
f01051b2:	75 74                	jne    f0105228 <__umoddi3+0xd8>
f01051b4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01051b8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f01051bc:	0f 87 0e 01 00 00    	ja     f01052d0 <__umoddi3+0x180>
f01051c2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f01051c6:	29 f1                	sub    %esi,%ecx
f01051c8:	19 c7                	sbb    %eax,%edi
f01051ca:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01051ce:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01051d2:	8b 44 24 14          	mov    0x14(%esp),%eax
f01051d6:	8b 54 24 18          	mov    0x18(%esp),%edx
f01051da:	8b 74 24 20          	mov    0x20(%esp),%esi
f01051de:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01051e2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01051e6:	83 c4 2c             	add    $0x2c,%esp
f01051e9:	c3                   	ret    
f01051ea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01051f0:	85 f6                	test   %esi,%esi
f01051f2:	89 f5                	mov    %esi,%ebp
f01051f4:	75 0b                	jne    f0105201 <__umoddi3+0xb1>
f01051f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01051fb:	31 d2                	xor    %edx,%edx
f01051fd:	f7 f6                	div    %esi
f01051ff:	89 c5                	mov    %eax,%ebp
f0105201:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105205:	31 d2                	xor    %edx,%edx
f0105207:	f7 f5                	div    %ebp
f0105209:	89 c8                	mov    %ecx,%eax
f010520b:	f7 f5                	div    %ebp
f010520d:	eb 84                	jmp    f0105193 <__umoddi3+0x43>
f010520f:	90                   	nop
f0105210:	89 c8                	mov    %ecx,%eax
f0105212:	89 fa                	mov    %edi,%edx
f0105214:	8b 74 24 20          	mov    0x20(%esp),%esi
f0105218:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010521c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0105220:	83 c4 2c             	add    $0x2c,%esp
f0105223:	c3                   	ret    
f0105224:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105228:	8b 44 24 10          	mov    0x10(%esp),%eax
f010522c:	be 20 00 00 00       	mov    $0x20,%esi
f0105231:	89 e9                	mov    %ebp,%ecx
f0105233:	29 ee                	sub    %ebp,%esi
f0105235:	d3 e2                	shl    %cl,%edx
f0105237:	89 f1                	mov    %esi,%ecx
f0105239:	d3 e8                	shr    %cl,%eax
f010523b:	89 e9                	mov    %ebp,%ecx
f010523d:	09 d0                	or     %edx,%eax
f010523f:	89 fa                	mov    %edi,%edx
f0105241:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105245:	8b 44 24 10          	mov    0x10(%esp),%eax
f0105249:	d3 e0                	shl    %cl,%eax
f010524b:	89 f1                	mov    %esi,%ecx
f010524d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0105251:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0105255:	d3 ea                	shr    %cl,%edx
f0105257:	89 e9                	mov    %ebp,%ecx
f0105259:	d3 e7                	shl    %cl,%edi
f010525b:	89 f1                	mov    %esi,%ecx
f010525d:	d3 e8                	shr    %cl,%eax
f010525f:	89 e9                	mov    %ebp,%ecx
f0105261:	09 f8                	or     %edi,%eax
f0105263:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0105267:	f7 74 24 0c          	divl   0xc(%esp)
f010526b:	d3 e7                	shl    %cl,%edi
f010526d:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0105271:	89 d7                	mov    %edx,%edi
f0105273:	f7 64 24 10          	mull   0x10(%esp)
f0105277:	39 d7                	cmp    %edx,%edi
f0105279:	89 c1                	mov    %eax,%ecx
f010527b:	89 54 24 14          	mov    %edx,0x14(%esp)
f010527f:	72 3b                	jb     f01052bc <__umoddi3+0x16c>
f0105281:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0105285:	72 31                	jb     f01052b8 <__umoddi3+0x168>
f0105287:	8b 44 24 18          	mov    0x18(%esp),%eax
f010528b:	29 c8                	sub    %ecx,%eax
f010528d:	19 d7                	sbb    %edx,%edi
f010528f:	89 e9                	mov    %ebp,%ecx
f0105291:	89 fa                	mov    %edi,%edx
f0105293:	d3 e8                	shr    %cl,%eax
f0105295:	89 f1                	mov    %esi,%ecx
f0105297:	d3 e2                	shl    %cl,%edx
f0105299:	89 e9                	mov    %ebp,%ecx
f010529b:	09 d0                	or     %edx,%eax
f010529d:	89 fa                	mov    %edi,%edx
f010529f:	d3 ea                	shr    %cl,%edx
f01052a1:	8b 74 24 20          	mov    0x20(%esp),%esi
f01052a5:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01052a9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01052ad:	83 c4 2c             	add    $0x2c,%esp
f01052b0:	c3                   	ret    
f01052b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01052b8:	39 d7                	cmp    %edx,%edi
f01052ba:	75 cb                	jne    f0105287 <__umoddi3+0x137>
f01052bc:	8b 54 24 14          	mov    0x14(%esp),%edx
f01052c0:	89 c1                	mov    %eax,%ecx
f01052c2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f01052c6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f01052ca:	eb bb                	jmp    f0105287 <__umoddi3+0x137>
f01052cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01052d0:	3b 44 24 18          	cmp    0x18(%esp),%eax
f01052d4:	0f 82 e8 fe ff ff    	jb     f01051c2 <__umoddi3+0x72>
f01052da:	e9 f3 fe ff ff       	jmp    f01051d2 <__umoddi3+0x82>

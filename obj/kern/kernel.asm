
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

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
f0100046:	b8 b0 df 17 f0       	mov    $0xf017dfb0,%eax
f010004b:	2d a3 d0 17 f0       	sub    $0xf017d0a3,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 a3 d0 17 f0 	movl   $0xf017d0a3,(%esp)
f0100063:	e8 8d 49 00 00       	call   f01049f5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 ca 04 00 00       	call   f0100537 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 4f 10 f0 	movl   $0xf0104f40,(%esp)
f010007c:	e8 99 35 00 00       	call   f010361a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 e4 11 00 00       	call   f010126a <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 59 2f 00 00       	call   f0102fe4 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 fc 35 00 00       	call   f0103691 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010009c:	00 
f010009d:	c7 44 24 04 63 78 00 	movl   $0x7863,0x4(%esp)
f01000a4:	00 
f01000a5:	c7 04 24 d7 df 16 f0 	movl   $0xf016dfd7,(%esp)
f01000ac:	e8 15 31 00 00       	call   f01031c6 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000b1:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f01000b6:	89 04 24             	mov    %eax,(%esp)
f01000b9:	e8 83 34 00 00       	call   f0103541 <env_run>

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
f01000c9:	83 3d a0 df 17 f0 00 	cmpl   $0x0,0xf017dfa0
f01000d0:	75 3d                	jne    f010010f <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000d2:	89 35 a0 df 17 f0    	mov    %esi,0xf017dfa0

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
f01000eb:	c7 04 24 5b 4f 10 f0 	movl   $0xf0104f5b,(%esp)
f01000f2:	e8 23 35 00 00       	call   f010361a <cprintf>
	vcprintf(fmt, ap);
f01000f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000fb:	89 34 24             	mov    %esi,(%esp)
f01000fe:	e8 e4 34 00 00       	call   f01035e7 <vcprintf>
	cprintf("\n");
f0100103:	c7 04 24 94 5b 10 f0 	movl   $0xf0105b94,(%esp)
f010010a:	e8 0b 35 00 00       	call   f010361a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010010f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100116:	e8 07 07 00 00       	call   f0100822 <monitor>
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
f0100135:	c7 04 24 73 4f 10 f0 	movl   $0xf0104f73,(%esp)
f010013c:	e8 d9 34 00 00       	call   f010361a <cprintf>
	vcprintf(fmt, ap);
f0100141:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100145:	8b 45 10             	mov    0x10(%ebp),%eax
f0100148:	89 04 24             	mov    %eax,(%esp)
f010014b:	e8 97 34 00 00       	call   f01035e7 <vcprintf>
	cprintf("\n");
f0100150:	c7 04 24 94 5b 10 f0 	movl   $0xf0105b94,(%esp)
f0100157:	e8 be 34 00 00       	call   f010361a <cprintf>
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
f01001a9:	a1 e4 d2 17 f0       	mov    0xf017d2e4,%eax
f01001ae:	88 90 e0 d0 17 f0    	mov    %dl,-0xfe82f20(%eax)
f01001b4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001b7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c2:	0f 44 d0             	cmove  %eax,%edx
f01001c5:	89 15 e4 d2 17 f0    	mov    %edx,0xf017d2e4
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
f0100292:	0f b7 05 f4 d2 17 f0 	movzwl 0xf017d2f4,%eax
f0100299:	66 85 c0             	test   %ax,%ax
f010029c:	0f 84 e5 00 00 00    	je     f0100387 <cons_putc+0x1ad>
			crt_pos--;
f01002a2:	83 e8 01             	sub    $0x1,%eax
f01002a5:	66 a3 f4 d2 17 f0    	mov    %ax,0xf017d2f4
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002ab:	0f b7 c0             	movzwl %ax,%eax
f01002ae:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002b4:	83 cf 20             	or     $0x20,%edi
f01002b7:	8b 15 f0 d2 17 f0    	mov    0xf017d2f0,%edx
f01002bd:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002c1:	eb 77                	jmp    f010033a <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002c3:	66 83 05 f4 d2 17 f0 	addw   $0x50,0xf017d2f4
f01002ca:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002cb:	0f b7 05 f4 d2 17 f0 	movzwl 0xf017d2f4,%eax
f01002d2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002d8:	c1 e8 16             	shr    $0x16,%eax
f01002db:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002de:	c1 e0 04             	shl    $0x4,%eax
f01002e1:	66 a3 f4 d2 17 f0    	mov    %ax,0xf017d2f4
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
f010031d:	0f b7 05 f4 d2 17 f0 	movzwl 0xf017d2f4,%eax
f0100324:	0f b7 c8             	movzwl %ax,%ecx
f0100327:	8b 15 f0 d2 17 f0    	mov    0xf017d2f0,%edx
f010032d:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100331:	83 c0 01             	add    $0x1,%eax
f0100334:	66 a3 f4 d2 17 f0    	mov    %ax,0xf017d2f4
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010033a:	66 81 3d f4 d2 17 f0 	cmpw   $0x7cf,0xf017d2f4
f0100341:	cf 07 
f0100343:	76 42                	jbe    f0100387 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100345:	a1 f0 d2 17 f0       	mov    0xf017d2f0,%eax
f010034a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100351:	00 
f0100352:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100358:	89 54 24 04          	mov    %edx,0x4(%esp)
f010035c:	89 04 24             	mov    %eax,(%esp)
f010035f:	e8 ef 46 00 00       	call   f0104a53 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100364:	8b 15 f0 d2 17 f0    	mov    0xf017d2f0,%edx
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
f010037f:	66 83 2d f4 d2 17 f0 	subw   $0x50,0xf017d2f4
f0100386:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100387:	8b 0d ec d2 17 f0    	mov    0xf017d2ec,%ecx
f010038d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100392:	89 ca                	mov    %ecx,%edx
f0100394:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100395:	0f b7 1d f4 d2 17 f0 	movzwl 0xf017d2f4,%ebx
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
f01003db:	83 0d e8 d2 17 f0 40 	orl    $0x40,0xf017d2e8
		return 0;
f01003e2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003e7:	e9 d0 00 00 00       	jmp    f01004bc <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003ec:	84 c0                	test   %al,%al
f01003ee:	79 37                	jns    f0100427 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003f0:	8b 0d e8 d2 17 f0    	mov    0xf017d2e8,%ecx
f01003f6:	89 cb                	mov    %ecx,%ebx
f01003f8:	83 e3 40             	and    $0x40,%ebx
f01003fb:	83 e0 7f             	and    $0x7f,%eax
f01003fe:	85 db                	test   %ebx,%ebx
f0100400:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100403:	0f b6 d2             	movzbl %dl,%edx
f0100406:	0f b6 82 c0 4f 10 f0 	movzbl -0xfefb040(%edx),%eax
f010040d:	83 c8 40             	or     $0x40,%eax
f0100410:	0f b6 c0             	movzbl %al,%eax
f0100413:	f7 d0                	not    %eax
f0100415:	21 c1                	and    %eax,%ecx
f0100417:	89 0d e8 d2 17 f0    	mov    %ecx,0xf017d2e8
		return 0;
f010041d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100422:	e9 95 00 00 00       	jmp    f01004bc <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f0100427:	8b 0d e8 d2 17 f0    	mov    0xf017d2e8,%ecx
f010042d:	f6 c1 40             	test   $0x40,%cl
f0100430:	74 0e                	je     f0100440 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100432:	89 c2                	mov    %eax,%edx
f0100434:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100437:	83 e1 bf             	and    $0xffffffbf,%ecx
f010043a:	89 0d e8 d2 17 f0    	mov    %ecx,0xf017d2e8
	}

	shift |= shiftcode[data];
f0100440:	0f b6 d2             	movzbl %dl,%edx
f0100443:	0f b6 82 c0 4f 10 f0 	movzbl -0xfefb040(%edx),%eax
f010044a:	0b 05 e8 d2 17 f0    	or     0xf017d2e8,%eax
	shift ^= togglecode[data];
f0100450:	0f b6 8a c0 50 10 f0 	movzbl -0xfefaf40(%edx),%ecx
f0100457:	31 c8                	xor    %ecx,%eax
f0100459:	a3 e8 d2 17 f0       	mov    %eax,0xf017d2e8

	c = charcode[shift & (CTL | SHIFT)][data];
f010045e:	89 c1                	mov    %eax,%ecx
f0100460:	83 e1 03             	and    $0x3,%ecx
f0100463:	8b 0c 8d c0 51 10 f0 	mov    -0xfefae40(,%ecx,4),%ecx
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
f010049e:	c7 04 24 8d 4f 10 f0 	movl   $0xf0104f8d,(%esp)
f01004a5:	e8 70 31 00 00       	call   f010361a <cprintf>
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
f01004c4:	83 3d c0 d0 17 f0 00 	cmpl   $0x0,0xf017d0c0
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
f0100502:	8b 15 e0 d2 17 f0    	mov    0xf017d2e0,%edx
f0100508:	3b 15 e4 d2 17 f0    	cmp    0xf017d2e4,%edx
f010050e:	74 20                	je     f0100530 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f0100510:	0f b6 82 e0 d0 17 f0 	movzbl -0xfe82f20(%edx),%eax
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
f0100528:	89 15 e0 d2 17 f0    	mov    %edx,0xf017d2e0
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
f010055d:	c7 05 ec d2 17 f0 b4 	movl   $0x3b4,0xf017d2ec
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
f0100575:	c7 05 ec d2 17 f0 d4 	movl   $0x3d4,0xf017d2ec
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
f0100584:	8b 0d ec d2 17 f0    	mov    0xf017d2ec,%ecx
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
f01005a9:	89 3d f0 d2 17 f0    	mov    %edi,0xf017d2f0
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005af:	0f b6 d8             	movzbl %al,%ebx
f01005b2:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005b4:	66 89 35 f4 d2 17 f0 	mov    %si,0xf017d2f4
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
f0100608:	89 0d c0 d0 17 f0    	mov    %ecx,0xf017d0c0
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
f0100618:	c7 04 24 99 4f 10 f0 	movl   $0xf0104f99,(%esp)
f010061f:	e8 f6 2f 00 00       	call   f010361a <cprintf>
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
f0100666:	c7 04 24 d0 51 10 f0 	movl   $0xf01051d0,(%esp)
f010066d:	e8 a8 2f 00 00       	call   f010361a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100672:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 b8 52 10 f0 	movl   $0xf01052b8,(%esp)
f0100689:	e8 8c 2f 00 00       	call   f010361a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068e:	c7 44 24 08 2f 4f 10 	movl   $0x104f2f,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 2f 4f 10 	movl   $0xf0104f2f,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 dc 52 10 f0 	movl   $0xf01052dc,(%esp)
f01006a5:	e8 70 2f 00 00       	call   f010361a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006aa:	c7 44 24 08 a3 d0 17 	movl   $0x17d0a3,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 a3 d0 17 	movl   $0xf017d0a3,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 00 53 10 f0 	movl   $0xf0105300,(%esp)
f01006c1:	e8 54 2f 00 00       	call   f010361a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006c6:	c7 44 24 08 b0 df 17 	movl   $0x17dfb0,0x8(%esp)
f01006cd:	00 
f01006ce:	c7 44 24 04 b0 df 17 	movl   $0xf017dfb0,0x4(%esp)
f01006d5:	f0 
f01006d6:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f01006dd:	e8 38 2f 00 00       	call   f010361a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006e2:	b8 af e3 17 f0       	mov    $0xf017e3af,%eax
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
f01006fe:	c7 04 24 48 53 10 f0 	movl   $0xf0105348,(%esp)
f0100705:	e8 10 2f 00 00       	call   f010361a <cprintf>
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
f0100719:	bb 04 54 10 f0       	mov    $0xf0105404,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f010071e:	be 28 54 10 f0       	mov    $0xf0105428,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100723:	8b 03                	mov    (%ebx),%eax
f0100725:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100729:	8b 43 fc             	mov    -0x4(%ebx),%eax
f010072c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100730:	c7 04 24 e9 51 10 f0 	movl   $0xf01051e9,(%esp)
f0100737:	e8 de 2e 00 00       	call   f010361a <cprintf>
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

f010074f <mon_backtrace>:
 * 2. *ebp is the new ebp(actually old)
 * 3. get the end(ebp = 0 -> see kern/entry.S, stack movl $0, %ebp)
 */
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010074f:	55                   	push   %ebp
f0100750:	89 e5                	mov    %esp,%ebp
f0100752:	57                   	push   %edi
f0100753:	56                   	push   %esi
f0100754:	53                   	push   %ebx
f0100755:	83 ec 3c             	sub    $0x3c,%esp
	// Your code here.
	uint32_t ebp,eip;
	int i;	
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100758:	c7 04 24 f2 51 10 f0 	movl   $0xf01051f2,(%esp)
f010075f:	e8 b6 2e 00 00       	call   f010361a <cprintf>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100764:	89 ee                	mov    %ebp,%esi
	ebp = read_ebp();
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
f0100766:	89 74 24 04          	mov    %esi,0x4(%esp)
f010076a:	c7 04 24 04 52 10 f0 	movl   $0xf0105204,(%esp)
f0100771:	e8 a4 2e 00 00       	call   f010361a <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f0100776:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f0100779:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010077d:	c7 04 24 0f 52 10 f0 	movl   $0xf010520f,(%esp)
f0100784:	e8 91 2e 00 00       	call   f010361a <cprintf>
		for(i=2; i < 7; i++)
f0100789:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f010078e:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100791:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100795:	c7 04 24 09 52 10 f0 	movl   $0xf0105209,(%esp)
f010079c:	e8 79 2e 00 00       	call   f010361a <cprintf>
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
		eip = *(uint32_t *)(ebp + 4);
		cprintf("  eip %08x  args",eip);
		for(i=2; i < 7; i++)
f01007a1:	83 c3 01             	add    $0x1,%ebx
f01007a4:	83 fb 07             	cmp    $0x7,%ebx
f01007a7:	75 e5                	jne    f010078e <mon_backtrace+0x3f>
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
		cprintf("\n");
f01007a9:	c7 04 24 94 5b 10 f0 	movl   $0xf0105b94,(%esp)
f01007b0:	e8 65 2e 00 00       	call   f010361a <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f01007b5:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007bc:	89 3c 24             	mov    %edi,(%esp)
f01007bf:	e8 42 37 00 00       	call   f0103f06 <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f01007c4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007c7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007cb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d2:	c7 04 24 20 52 10 f0 	movl   $0xf0105220,(%esp)
f01007d9:	e8 3c 2e 00 00       	call   f010361a <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f01007de:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007e5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ec:	c7 04 24 29 52 10 f0 	movl   $0xf0105229,(%esp)
f01007f3:	e8 22 2e 00 00       	call   f010361a <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f01007f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ff:	c7 04 24 2e 52 10 f0 	movl   $0xf010522e,(%esp)
f0100806:	e8 0f 2e 00 00       	call   f010361a <cprintf>
		ebp = *(uint32_t *)ebp;
f010080b:	8b 36                	mov    (%esi),%esi
	}while(ebp);
f010080d:	85 f6                	test   %esi,%esi
f010080f:	0f 85 51 ff ff ff    	jne    f0100766 <mon_backtrace+0x17>
	return 0;
}
f0100815:	b8 00 00 00 00       	mov    $0x0,%eax
f010081a:	83 c4 3c             	add    $0x3c,%esp
f010081d:	5b                   	pop    %ebx
f010081e:	5e                   	pop    %esi
f010081f:	5f                   	pop    %edi
f0100820:	5d                   	pop    %ebp
f0100821:	c3                   	ret    

f0100822 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100822:	55                   	push   %ebp
f0100823:	89 e5                	mov    %esp,%ebp
f0100825:	57                   	push   %edi
f0100826:	56                   	push   %esi
f0100827:	53                   	push   %ebx
f0100828:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010082b:	c7 04 24 74 53 10 f0 	movl   $0xf0105374,(%esp)
f0100832:	e8 e3 2d 00 00       	call   f010361a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100837:	c7 04 24 98 53 10 f0 	movl   $0xf0105398,(%esp)
f010083e:	e8 d7 2d 00 00       	call   f010361a <cprintf>

	if (tf != NULL)
f0100843:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100847:	74 0b                	je     f0100854 <monitor+0x32>
		print_trapframe(tf);
f0100849:	8b 45 08             	mov    0x8(%ebp),%eax
f010084c:	89 04 24             	mov    %eax,(%esp)
f010084f:	e8 f4 31 00 00       	call   f0103a48 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100854:	c7 04 24 33 52 10 f0 	movl   $0xf0105233,(%esp)
f010085b:	e8 c0 3e 00 00       	call   f0104720 <readline>
f0100860:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100862:	85 c0                	test   %eax,%eax
f0100864:	74 ee                	je     f0100854 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100866:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010086d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100872:	eb 06                	jmp    f010087a <monitor+0x58>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100874:	c6 06 00             	movb   $0x0,(%esi)
f0100877:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010087a:	0f b6 06             	movzbl (%esi),%eax
f010087d:	84 c0                	test   %al,%al
f010087f:	74 6a                	je     f01008eb <monitor+0xc9>
f0100881:	0f be c0             	movsbl %al,%eax
f0100884:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100888:	c7 04 24 37 52 10 f0 	movl   $0xf0105237,(%esp)
f010088f:	e8 01 41 00 00       	call   f0104995 <strchr>
f0100894:	85 c0                	test   %eax,%eax
f0100896:	75 dc                	jne    f0100874 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100898:	80 3e 00             	cmpb   $0x0,(%esi)
f010089b:	74 4e                	je     f01008eb <monitor+0xc9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010089d:	83 fb 0f             	cmp    $0xf,%ebx
f01008a0:	75 16                	jne    f01008b8 <monitor+0x96>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008a9:	00 
f01008aa:	c7 04 24 3c 52 10 f0 	movl   $0xf010523c,(%esp)
f01008b1:	e8 64 2d 00 00       	call   f010361a <cprintf>
f01008b6:	eb 9c                	jmp    f0100854 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f01008b8:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f01008bc:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f01008bf:	0f b6 06             	movzbl (%esi),%eax
f01008c2:	84 c0                	test   %al,%al
f01008c4:	75 0c                	jne    f01008d2 <monitor+0xb0>
f01008c6:	eb b2                	jmp    f010087a <monitor+0x58>
			buf++;
f01008c8:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008cb:	0f b6 06             	movzbl (%esi),%eax
f01008ce:	84 c0                	test   %al,%al
f01008d0:	74 a8                	je     f010087a <monitor+0x58>
f01008d2:	0f be c0             	movsbl %al,%eax
f01008d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d9:	c7 04 24 37 52 10 f0 	movl   $0xf0105237,(%esp)
f01008e0:	e8 b0 40 00 00       	call   f0104995 <strchr>
f01008e5:	85 c0                	test   %eax,%eax
f01008e7:	74 df                	je     f01008c8 <monitor+0xa6>
f01008e9:	eb 8f                	jmp    f010087a <monitor+0x58>
			buf++;
	}
	argv[argc] = 0;
f01008eb:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f01008f2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f3:	85 db                	test   %ebx,%ebx
f01008f5:	0f 84 59 ff ff ff    	je     f0100854 <monitor+0x32>
f01008fb:	bf 00 54 10 f0       	mov    $0xf0105400,%edi
f0100900:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100905:	8b 07                	mov    (%edi),%eax
f0100907:	89 44 24 04          	mov    %eax,0x4(%esp)
f010090b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010090e:	89 04 24             	mov    %eax,(%esp)
f0100911:	e8 fb 3f 00 00       	call   f0104911 <strcmp>
f0100916:	85 c0                	test   %eax,%eax
f0100918:	75 24                	jne    f010093e <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f010091a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010091d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100920:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100924:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100927:	89 54 24 04          	mov    %edx,0x4(%esp)
f010092b:	89 1c 24             	mov    %ebx,(%esp)
f010092e:	ff 14 85 08 54 10 f0 	call   *-0xfefabf8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100935:	85 c0                	test   %eax,%eax
f0100937:	78 28                	js     f0100961 <monitor+0x13f>
f0100939:	e9 16 ff ff ff       	jmp    f0100854 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010093e:	83 c6 01             	add    $0x1,%esi
f0100941:	83 c7 0c             	add    $0xc,%edi
f0100944:	83 fe 03             	cmp    $0x3,%esi
f0100947:	75 bc                	jne    f0100905 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100949:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010094c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100950:	c7 04 24 59 52 10 f0 	movl   $0xf0105259,(%esp)
f0100957:	e8 be 2c 00 00       	call   f010361a <cprintf>
f010095c:	e9 f3 fe ff ff       	jmp    f0100854 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100961:	83 c4 5c             	add    $0x5c,%esp
f0100964:	5b                   	pop    %ebx
f0100965:	5e                   	pop    %esi
f0100966:	5f                   	pop    %edi
f0100967:	5d                   	pop    %ebp
f0100968:	c3                   	ret    

f0100969 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100969:	55                   	push   %ebp
f010096a:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010096c:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f010096f:	5d                   	pop    %ebp
f0100970:	c3                   	ret    
f0100971:	66 90                	xchg   %ax,%ax
f0100973:	66 90                	xchg   %ax,%ax
f0100975:	66 90                	xchg   %ax,%ax
f0100977:	66 90                	xchg   %ax,%ax
f0100979:	66 90                	xchg   %ax,%ax
f010097b:	66 90                	xchg   %ax,%ax
f010097d:	66 90                	xchg   %ax,%ax
f010097f:	90                   	nop

f0100980 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100980:	89 d1                	mov    %edx,%ecx
f0100982:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100985:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100988:	a8 01                	test   $0x1,%al
f010098a:	74 5d                	je     f01009e9 <check_va2pa+0x69>
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010098c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100991:	89 c1                	mov    %eax,%ecx
f0100993:	c1 e9 0c             	shr    $0xc,%ecx
f0100996:	3b 0d a4 df 17 f0    	cmp    0xf017dfa4,%ecx
f010099c:	72 26                	jb     f01009c4 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010099e:	55                   	push   %ebp
f010099f:	89 e5                	mov    %esp,%ebp
f01009a1:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009a4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009a8:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f01009af:	f0 
f01009b0:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f01009b7:	00 
f01009b8:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01009bf:	e8 fa f6 ff ff       	call   f01000be <_panic>
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009c4:	c1 ea 0c             	shr    $0xc,%edx
f01009c7:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009cd:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009d4:	89 c2                	mov    %eax,%edx
f01009d6:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009d9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009de:	85 d2                	test   %edx,%edx
f01009e0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009e5:	0f 44 c2             	cmove  %edx,%eax
f01009e8:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009ee:	c3                   	ret    

f01009ef <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009ef:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009f1:	83 3d fc d2 17 f0 00 	cmpl   $0x0,0xf017d2fc
f01009f8:	75 0f                	jne    f0100a09 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009fa:	b8 af ef 17 f0       	mov    $0xf017efaf,%eax
f01009ff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a04:	a3 fc d2 17 f0       	mov    %eax,0xf017d2fc
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f0100a09:	85 d2                	test   %edx,%edx
f0100a0b:	75 06                	jne    f0100a13 <boot_alloc+0x24>
		return nextfree;
f0100a0d:	a1 fc d2 17 f0       	mov    0xf017d2fc,%eax
f0100a12:	c3                   	ret    
	result = nextfree;
f0100a13:	a1 fc d2 17 f0       	mov    0xf017d2fc,%eax
	nextfree += (n/PGSIZE + 1)*PGSIZE;
f0100a18:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a1e:	8d 94 10 00 10 00 00 	lea    0x1000(%eax,%edx,1),%edx
f0100a25:	89 15 fc d2 17 f0    	mov    %edx,0xf017d2fc
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
f0100a2b:	8b 0d a4 df 17 f0    	mov    0xf017dfa4,%ecx
f0100a31:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f0100a37:	c1 e1 0c             	shl    $0xc,%ecx
f0100a3a:	39 ca                	cmp    %ecx,%edx
f0100a3c:	72 22                	jb     f0100a60 <boot_alloc+0x71>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a3e:	55                   	push   %ebp
f0100a3f:	89 e5                	mov    %esp,%ebp
f0100a41:	83 ec 18             	sub    $0x18,%esp
	if(n == 0)
		return nextfree;
	result = nextfree;
	nextfree += (n/PGSIZE + 1)*PGSIZE;
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
		panic("Run out of memory!!\n");
f0100a44:	c7 44 24 08 81 5b 10 	movl   $0xf0105b81,0x8(%esp)
f0100a4b:	f0 
f0100a4c:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
f0100a53:	00 
f0100a54:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100a5b:	e8 5e f6 ff ff       	call   f01000be <_panic>
	return result;
}
f0100a60:	f3 c3                	repz ret 

f0100a62 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a62:	55                   	push   %ebp
f0100a63:	89 e5                	mov    %esp,%ebp
f0100a65:	83 ec 18             	sub    $0x18,%esp
f0100a68:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a6b:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a6e:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a70:	89 04 24             	mov    %eax,(%esp)
f0100a73:	e8 30 2b 00 00       	call   f01035a8 <mc146818_read>
f0100a78:	89 c6                	mov    %eax,%esi
f0100a7a:	83 c3 01             	add    $0x1,%ebx
f0100a7d:	89 1c 24             	mov    %ebx,(%esp)
f0100a80:	e8 23 2b 00 00       	call   f01035a8 <mc146818_read>
f0100a85:	c1 e0 08             	shl    $0x8,%eax
f0100a88:	09 f0                	or     %esi,%eax
}
f0100a8a:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a8d:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a90:	89 ec                	mov    %ebp,%esp
f0100a92:	5d                   	pop    %ebp
f0100a93:	c3                   	ret    

f0100a94 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a94:	55                   	push   %ebp
f0100a95:	89 e5                	mov    %esp,%ebp
f0100a97:	57                   	push   %edi
f0100a98:	56                   	push   %esi
f0100a99:	53                   	push   %ebx
f0100a9a:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a9d:	85 c0                	test   %eax,%eax
f0100a9f:	0f 85 39 03 00 00    	jne    f0100dde <check_page_free_list+0x34a>
f0100aa5:	e9 46 03 00 00       	jmp    f0100df0 <check_page_free_list+0x35c>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100aaa:	c7 44 24 08 48 54 10 	movl   $0xf0105448,0x8(%esp)
f0100ab1:	f0 
f0100ab2:	c7 44 24 04 51 02 00 	movl   $0x251,0x4(%esp)
f0100ab9:	00 
f0100aba:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100ac1:	e8 f8 f5 ff ff       	call   f01000be <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100ac6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ac9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100acc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100acf:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ad2:	89 c2                	mov    %eax,%edx
f0100ad4:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ada:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ae0:	0f 95 c2             	setne  %dl
f0100ae3:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ae6:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100aea:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100aec:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100af0:	8b 00                	mov    (%eax),%eax
f0100af2:	85 c0                	test   %eax,%eax
f0100af4:	75 dc                	jne    f0100ad2 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100af6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100af9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b02:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b05:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b07:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b0a:	a3 00 d3 17 f0       	mov    %eax,0xf017d300
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b0f:	89 c3                	mov    %eax,%ebx
f0100b11:	85 c0                	test   %eax,%eax
f0100b13:	74 6c                	je     f0100b81 <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b15:	be 01 00 00 00       	mov    $0x1,%esi
f0100b1a:	89 d8                	mov    %ebx,%eax
f0100b1c:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f0100b22:	c1 f8 03             	sar    $0x3,%eax
f0100b25:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b28:	89 c2                	mov    %eax,%edx
f0100b2a:	c1 ea 16             	shr    $0x16,%edx
f0100b2d:	39 f2                	cmp    %esi,%edx
f0100b2f:	73 4a                	jae    f0100b7b <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b31:	89 c2                	mov    %eax,%edx
f0100b33:	c1 ea 0c             	shr    $0xc,%edx
f0100b36:	3b 15 a4 df 17 f0    	cmp    0xf017dfa4,%edx
f0100b3c:	72 20                	jb     f0100b5e <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b3e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b42:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0100b49:	f0 
f0100b4a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b51:	00 
f0100b52:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0100b59:	e8 60 f5 ff ff       	call   f01000be <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b5e:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b65:	00 
f0100b66:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b6d:	00 
	return (void *)(pa + KERNBASE);
f0100b6e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b73:	89 04 24             	mov    %eax,(%esp)
f0100b76:	e8 7a 3e 00 00       	call   f01049f5 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b7b:	8b 1b                	mov    (%ebx),%ebx
f0100b7d:	85 db                	test   %ebx,%ebx
f0100b7f:	75 99                	jne    f0100b1a <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b81:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b86:	e8 64 fe ff ff       	call   f01009ef <boot_alloc>
f0100b8b:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b8e:	8b 15 00 d3 17 f0    	mov    0xf017d300,%edx
f0100b94:	85 d2                	test   %edx,%edx
f0100b96:	0f 84 f6 01 00 00    	je     f0100d92 <check_page_free_list+0x2fe>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b9c:	8b 1d ac df 17 f0    	mov    0xf017dfac,%ebx
f0100ba2:	39 da                	cmp    %ebx,%edx
f0100ba4:	72 4d                	jb     f0100bf3 <check_page_free_list+0x15f>
		assert(pp < pages + npages);
f0100ba6:	a1 a4 df 17 f0       	mov    0xf017dfa4,%eax
f0100bab:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100bae:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100bb1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100bb4:	39 c2                	cmp    %eax,%edx
f0100bb6:	73 64                	jae    f0100c1c <check_page_free_list+0x188>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bb8:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100bbb:	89 d0                	mov    %edx,%eax
f0100bbd:	29 d8                	sub    %ebx,%eax
f0100bbf:	a8 07                	test   $0x7,%al
f0100bc1:	0f 85 82 00 00 00    	jne    f0100c49 <check_page_free_list+0x1b5>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bc7:	c1 f8 03             	sar    $0x3,%eax
f0100bca:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bcd:	85 c0                	test   %eax,%eax
f0100bcf:	0f 84 a2 00 00 00    	je     f0100c77 <check_page_free_list+0x1e3>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bd5:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bda:	0f 84 c2 00 00 00    	je     f0100ca2 <check_page_free_list+0x20e>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100be0:	be 00 00 00 00       	mov    $0x0,%esi
f0100be5:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bea:	e9 d7 00 00 00       	jmp    f0100cc6 <check_page_free_list+0x232>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bef:	39 da                	cmp    %ebx,%edx
f0100bf1:	73 24                	jae    f0100c17 <check_page_free_list+0x183>
f0100bf3:	c7 44 24 0c a4 5b 10 	movl   $0xf0105ba4,0xc(%esp)
f0100bfa:	f0 
f0100bfb:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100c02:	f0 
f0100c03:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f0100c0a:	00 
f0100c0b:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100c12:	e8 a7 f4 ff ff       	call   f01000be <_panic>
		assert(pp < pages + npages);
f0100c17:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c1a:	72 24                	jb     f0100c40 <check_page_free_list+0x1ac>
f0100c1c:	c7 44 24 0c c5 5b 10 	movl   $0xf0105bc5,0xc(%esp)
f0100c23:	f0 
f0100c24:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100c2b:	f0 
f0100c2c:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f0100c33:	00 
f0100c34:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100c3b:	e8 7e f4 ff ff       	call   f01000be <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c40:	89 d0                	mov    %edx,%eax
f0100c42:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c45:	a8 07                	test   $0x7,%al
f0100c47:	74 24                	je     f0100c6d <check_page_free_list+0x1d9>
f0100c49:	c7 44 24 0c 6c 54 10 	movl   $0xf010546c,0xc(%esp)
f0100c50:	f0 
f0100c51:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100c58:	f0 
f0100c59:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f0100c60:	00 
f0100c61:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100c68:	e8 51 f4 ff ff       	call   f01000be <_panic>
f0100c6d:	c1 f8 03             	sar    $0x3,%eax
f0100c70:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c73:	85 c0                	test   %eax,%eax
f0100c75:	75 24                	jne    f0100c9b <check_page_free_list+0x207>
f0100c77:	c7 44 24 0c d9 5b 10 	movl   $0xf0105bd9,0xc(%esp)
f0100c7e:	f0 
f0100c7f:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100c86:	f0 
f0100c87:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f0100c8e:	00 
f0100c8f:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100c96:	e8 23 f4 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c9b:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ca0:	75 24                	jne    f0100cc6 <check_page_free_list+0x232>
f0100ca2:	c7 44 24 0c ea 5b 10 	movl   $0xf0105bea,0xc(%esp)
f0100ca9:	f0 
f0100caa:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100cb1:	f0 
f0100cb2:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
f0100cb9:	00 
f0100cba:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100cc1:	e8 f8 f3 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cc6:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ccb:	75 24                	jne    f0100cf1 <check_page_free_list+0x25d>
f0100ccd:	c7 44 24 0c a0 54 10 	movl   $0xf01054a0,0xc(%esp)
f0100cd4:	f0 
f0100cd5:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100cdc:	f0 
f0100cdd:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f0100ce4:	00 
f0100ce5:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100cec:	e8 cd f3 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cf1:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cf6:	75 24                	jne    f0100d1c <check_page_free_list+0x288>
f0100cf8:	c7 44 24 0c 03 5c 10 	movl   $0xf0105c03,0xc(%esp)
f0100cff:	f0 
f0100d00:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100d07:	f0 
f0100d08:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f0100d0f:	00 
f0100d10:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100d17:	e8 a2 f3 ff ff       	call   f01000be <_panic>
f0100d1c:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d1e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d23:	76 57                	jbe    f0100d7c <check_page_free_list+0x2e8>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d25:	c1 e8 0c             	shr    $0xc,%eax
f0100d28:	3b 45 cc             	cmp    -0x34(%ebp),%eax
f0100d2b:	72 20                	jb     f0100d4d <check_page_free_list+0x2b9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d2d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d31:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0100d38:	f0 
f0100d39:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d40:	00 
f0100d41:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0100d48:	e8 71 f3 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0100d4d:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d53:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100d56:	76 29                	jbe    f0100d81 <check_page_free_list+0x2ed>
f0100d58:	c7 44 24 0c c4 54 10 	movl   $0xf01054c4,0xc(%esp)
f0100d5f:	f0 
f0100d60:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100d67:	f0 
f0100d68:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f0100d6f:	00 
f0100d70:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100d77:	e8 42 f3 ff ff       	call   f01000be <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d7c:	83 c7 01             	add    $0x1,%edi
f0100d7f:	eb 03                	jmp    f0100d84 <check_page_free_list+0x2f0>
		else
			++nfree_extmem;
f0100d81:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d84:	8b 12                	mov    (%edx),%edx
f0100d86:	85 d2                	test   %edx,%edx
f0100d88:	0f 85 61 fe ff ff    	jne    f0100bef <check_page_free_list+0x15b>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d8e:	85 ff                	test   %edi,%edi
f0100d90:	7f 24                	jg     f0100db6 <check_page_free_list+0x322>
f0100d92:	c7 44 24 0c 1d 5c 10 	movl   $0xf0105c1d,0xc(%esp)
f0100d99:	f0 
f0100d9a:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100da1:	f0 
f0100da2:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f0100da9:	00 
f0100daa:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100db1:	e8 08 f3 ff ff       	call   f01000be <_panic>
	assert(nfree_extmem > 0);
f0100db6:	85 f6                	test   %esi,%esi
f0100db8:	7f 53                	jg     f0100e0d <check_page_free_list+0x379>
f0100dba:	c7 44 24 0c 2f 5c 10 	movl   $0xf0105c2f,0xc(%esp)
f0100dc1:	f0 
f0100dc2:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0100dc9:	f0 
f0100dca:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f0100dd1:	00 
f0100dd2:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100dd9:	e8 e0 f2 ff ff       	call   f01000be <_panic>
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dde:	a1 00 d3 17 f0       	mov    0xf017d300,%eax
f0100de3:	85 c0                	test   %eax,%eax
f0100de5:	0f 85 db fc ff ff    	jne    f0100ac6 <check_page_free_list+0x32>
f0100deb:	e9 ba fc ff ff       	jmp    f0100aaa <check_page_free_list+0x16>
f0100df0:	83 3d 00 d3 17 f0 00 	cmpl   $0x0,0xf017d300
f0100df7:	0f 84 ad fc ff ff    	je     f0100aaa <check_page_free_list+0x16>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dfd:	8b 1d 00 d3 17 f0    	mov    0xf017d300,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e03:	be 00 04 00 00       	mov    $0x400,%esi
f0100e08:	e9 0d fd ff ff       	jmp    f0100b1a <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100e0d:	83 c4 3c             	add    $0x3c,%esp
f0100e10:	5b                   	pop    %ebx
f0100e11:	5e                   	pop    %esi
f0100e12:	5f                   	pop    %edi
f0100e13:	5d                   	pop    %ebp
f0100e14:	c3                   	ret    

f0100e15 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e15:	55                   	push   %ebp
f0100e16:	89 e5                	mov    %esp,%ebp
f0100e18:	56                   	push   %esi
f0100e19:	53                   	push   %ebx
f0100e1a:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
f0100e1d:	a1 ac df 17 f0       	mov    0xf017dfac,%eax
f0100e22:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100e28:	8b 35 f8 d2 17 f0    	mov    0xf017d2f8,%esi
f0100e2e:	83 fe 01             	cmp    $0x1,%esi
f0100e31:	76 37                	jbe    f0100e6a <page_init+0x55>
f0100e33:	8b 1d 00 d3 17 f0    	mov    0xf017d300,%ebx
f0100e39:	b8 01 00 00 00       	mov    $0x1,%eax
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
f0100e3e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
		pages[i].pp_ref = 0;
f0100e45:	8b 0d ac df 17 f0    	mov    0xf017dfac,%ecx
f0100e4b:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100e52:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0100e55:	8b 1d ac df 17 f0    	mov    0xf017dfac,%ebx
f0100e5b:	01 d3                	add    %edx,%ebx
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100e5d:	83 c0 01             	add    $0x1,%eax
f0100e60:	39 f0                	cmp    %esi,%eax
f0100e62:	72 da                	jb     f0100e3e <page_init+0x29>
f0100e64:	89 1d 00 d3 17 f0    	mov    %ebx,0xf017d300
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	size_t page_num = PADDR(boot_alloc(0)) / PGSIZE;
f0100e6a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e6f:	e8 7b fb ff ff       	call   f01009ef <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e74:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e79:	77 20                	ja     f0100e9b <page_init+0x86>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e7b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e7f:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f0100e86:	f0 
f0100e87:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
f0100e8e:	00 
f0100e8f:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100e96:	e8 23 f2 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e9b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ea0:	c1 e8 0c             	shr    $0xc,%eax
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100ea3:	3b 05 a4 df 17 f0    	cmp    0xf017dfa4,%eax
f0100ea9:	73 39                	jae    f0100ee4 <page_init+0xcf>
f0100eab:	8b 1d 00 d3 17 f0    	mov    0xf017d300,%ebx
f0100eb1:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100eb8:	8b 0d ac df 17 f0    	mov    0xf017dfac,%ecx
f0100ebe:	01 d1                	add    %edx,%ecx
f0100ec0:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ec6:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100ec8:	8b 1d ac df 17 f0    	mov    0xf017dfac,%ebx
f0100ece:	01 d3                	add    %edx,%ebx
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100ed0:	83 c0 01             	add    $0x1,%eax
f0100ed3:	83 c2 08             	add    $0x8,%edx
f0100ed6:	39 05 a4 df 17 f0    	cmp    %eax,0xf017dfa4
f0100edc:	77 da                	ja     f0100eb8 <page_init+0xa3>
f0100ede:	89 1d 00 d3 17 f0    	mov    %ebx,0xf017d300
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
//	panic("here");
	
}
f0100ee4:	83 c4 10             	add    $0x10,%esp
f0100ee7:	5b                   	pop    %ebx
f0100ee8:	5e                   	pop    %esi
f0100ee9:	5d                   	pop    %ebp
f0100eea:	c3                   	ret    

f0100eeb <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100eeb:	55                   	push   %ebp
f0100eec:	89 e5                	mov    %esp,%ebp
f0100eee:	53                   	push   %ebx
f0100eef:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(!page_free_list)
f0100ef2:	8b 1d 00 d3 17 f0    	mov    0xf017d300,%ebx
f0100ef8:	85 db                	test   %ebx,%ebx
f0100efa:	74 6b                	je     f0100f67 <page_alloc+0x7c>
		return NULL;
	struct Page *alloc_page = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100efc:	8b 03                	mov    (%ebx),%eax
f0100efe:	a3 00 d3 17 f0       	mov    %eax,0xf017d300
	alloc_page -> pp_link = NULL;
f0100f03:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100f09:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f0d:	74 58                	je     f0100f67 <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f0f:	89 d8                	mov    %ebx,%eax
f0100f11:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f0100f17:	c1 f8 03             	sar    $0x3,%eax
f0100f1a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f1d:	89 c2                	mov    %eax,%edx
f0100f1f:	c1 ea 0c             	shr    $0xc,%edx
f0100f22:	3b 15 a4 df 17 f0    	cmp    0xf017dfa4,%edx
f0100f28:	72 20                	jb     f0100f4a <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f2a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f2e:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0100f35:	f0 
f0100f36:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f3d:	00 
f0100f3e:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0100f45:	e8 74 f1 ff ff       	call   f01000be <_panic>
		memset(page2kva(alloc_page), 0, PGSIZE);
f0100f4a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f51:	00 
f0100f52:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f59:	00 
	return (void *)(pa + KERNBASE);
f0100f5a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f5f:	89 04 24             	mov    %eax,(%esp)
f0100f62:	e8 8e 3a 00 00       	call   f01049f5 <memset>
	
	return alloc_page;
}
f0100f67:	89 d8                	mov    %ebx,%eax
f0100f69:	83 c4 14             	add    $0x14,%esp
f0100f6c:	5b                   	pop    %ebx
f0100f6d:	5d                   	pop    %ebp
f0100f6e:	c3                   	ret    

f0100f6f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f6f:	55                   	push   %ebp
f0100f70:	89 e5                	mov    %esp,%ebp
f0100f72:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if(pp -> pp_ref)	// If the ref is not 0, return
f0100f75:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f7a:	75 0d                	jne    f0100f89 <page_free+0x1a>
		return;
	pp->pp_link = page_free_list;
f0100f7c:	8b 15 00 d3 17 f0    	mov    0xf017d300,%edx
f0100f82:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f84:	a3 00 d3 17 f0       	mov    %eax,0xf017d300
}
f0100f89:	5d                   	pop    %ebp
f0100f8a:	c3                   	ret    

f0100f8b <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f8b:	55                   	push   %ebp
f0100f8c:	89 e5                	mov    %esp,%ebp
f0100f8e:	83 ec 04             	sub    $0x4,%esp
f0100f91:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f94:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f98:	83 ea 01             	sub    $0x1,%edx
f0100f9b:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f9f:	66 85 d2             	test   %dx,%dx
f0100fa2:	75 08                	jne    f0100fac <page_decref+0x21>
		page_free(pp);
f0100fa4:	89 04 24             	mov    %eax,(%esp)
f0100fa7:	e8 c3 ff ff ff       	call   f0100f6f <page_free>
}
f0100fac:	c9                   	leave  
f0100fad:	c3                   	ret    

f0100fae <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{/* see the check_va2pa() */
f0100fae:	55                   	push   %ebp
f0100faf:	89 e5                	mov    %esp,%ebp
f0100fb1:	56                   	push   %esi
f0100fb2:	53                   	push   %ebx
f0100fb3:	83 ec 10             	sub    $0x10,%esp
f0100fb6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/* va is a linear address */
	pde_t *ptdir = pgdir + PDX(va);
f0100fb9:	89 de                	mov    %ebx,%esi
f0100fbb:	c1 ee 16             	shr    $0x16,%esi
f0100fbe:	c1 e6 02             	shl    $0x2,%esi
f0100fc1:	03 75 08             	add    0x8(%ebp),%esi
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
f0100fc4:	8b 06                	mov    (%esi),%eax
f0100fc6:	a8 01                	test   $0x1,%al
f0100fc8:	74 44                	je     f010100e <pgdir_walk+0x60>
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f0100fca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fcf:	89 c2                	mov    %eax,%edx
f0100fd1:	c1 ea 0c             	shr    $0xc,%edx
f0100fd4:	3b 15 a4 df 17 f0    	cmp    0xf017dfa4,%edx
f0100fda:	72 20                	jb     f0100ffc <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fdc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fe0:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0100fe7:	f0 
f0100fe8:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
f0100fef:	00 
f0100ff0:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0100ff7:	e8 c2 f0 ff ff       	call   f01000be <_panic>
f0100ffc:	c1 eb 0a             	shr    $0xa,%ebx
f0100fff:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101005:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f010100c:	eb 7c                	jmp    f010108a <pgdir_walk+0xdc>
	if(!create)
f010100e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101012:	74 6a                	je     f010107e <pgdir_walk+0xd0>
		return NULL;
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
f0101014:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010101b:	e8 cb fe ff ff       	call   f0100eeb <page_alloc>
	if(!page_create)
f0101020:	85 c0                	test   %eax,%eax
f0101022:	74 61                	je     f0101085 <pgdir_walk+0xd7>
		return NULL; /* allocation fails */
	page_create -> pp_ref++; /* reference count increase */
f0101024:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101029:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f010102f:	c1 f8 03             	sar    $0x3,%eax
f0101032:	c1 e0 0c             	shl    $0xc,%eax
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
f0101035:	83 c8 07             	or     $0x7,%eax
f0101038:	89 06                	mov    %eax,(%esi)
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f010103a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010103f:	89 c2                	mov    %eax,%edx
f0101041:	c1 ea 0c             	shr    $0xc,%edx
f0101044:	3b 15 a4 df 17 f0    	cmp    0xf017dfa4,%edx
f010104a:	72 20                	jb     f010106c <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010104c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101050:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0101057:	f0 
f0101058:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f010105f:	00 
f0101060:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101067:	e8 52 f0 ff ff       	call   f01000be <_panic>
f010106c:	c1 eb 0a             	shr    $0xa,%ebx
f010106f:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101075:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f010107c:	eb 0c                	jmp    f010108a <pgdir_walk+0xdc>
	pde_t *ptdir = pgdir + PDX(va);
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
	if(!create)
		return NULL;
f010107e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101083:	eb 05                	jmp    f010108a <pgdir_walk+0xdc>
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
	if(!page_create)
		return NULL; /* allocation fails */
f0101085:	b8 00 00 00 00       	mov    $0x0,%eax
	page_create -> pp_ref++; /* reference count increase */
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
}
f010108a:	83 c4 10             	add    $0x10,%esp
f010108d:	5b                   	pop    %ebx
f010108e:	5e                   	pop    %esi
f010108f:	5d                   	pop    %ebp
f0101090:	c3                   	ret    

f0101091 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101091:	55                   	push   %ebp
f0101092:	89 e5                	mov    %esp,%ebp
f0101094:	57                   	push   %edi
f0101095:	56                   	push   %esi
f0101096:	53                   	push   %ebx
f0101097:	83 ec 2c             	sub    $0x2c,%esp
f010109a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f010109d:	85 c9                	test   %ecx,%ecx
f010109f:	74 43                	je     f01010e4 <boot_map_region+0x53>
f01010a1:	89 c6                	mov    %eax,%esi
f01010a3:	89 d3                	mov    %edx,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01010a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01010a8:	29 d0                	sub    %edx,%eax
f01010aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010ad:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010b0:	89 f7                	mov    %esi,%edi
f01010b2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01010b5:	01 de                	add    %ebx,%esi
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
		pte_t *pte = pgdir_walk(pgdir, (const void *)va, 1);
f01010b7:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010be:	00 
f01010bf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c3:	89 3c 24             	mov    %edi,(%esp)
f01010c6:	e8 e3 fe ff ff       	call   f0100fae <pgdir_walk>
		if(!pte)
f01010cb:	85 c0                	test   %eax,%eax
f01010cd:	74 15                	je     f01010e4 <boot_map_region+0x53>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm;
f01010cf:	0b 75 0c             	or     0xc(%ebp),%esi
f01010d2:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f01010d4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01010da:	89 d8                	mov    %ebx,%eax
f01010dc:	2b 45 dc             	sub    -0x24(%ebp),%eax
f01010df:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01010e2:	72 ce                	jb     f01010b2 <boot_map_region+0x21>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm;
	}
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~\n");
}
f01010e4:	83 c4 2c             	add    $0x2c,%esp
f01010e7:	5b                   	pop    %ebx
f01010e8:	5e                   	pop    %esi
f01010e9:	5f                   	pop    %edi
f01010ea:	5d                   	pop    %ebp
f01010eb:	c3                   	ret    

f01010ec <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010ec:	55                   	push   %ebp
f01010ed:	89 e5                	mov    %esp,%ebp
f01010ef:	53                   	push   %ebx
f01010f0:	83 ec 14             	sub    $0x14,%esp
f01010f3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f01010f6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010fd:	00 
f01010fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101101:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101105:	8b 45 08             	mov    0x8(%ebp),%eax
f0101108:	89 04 24             	mov    %eax,(%esp)
f010110b:	e8 9e fe ff ff       	call   f0100fae <pgdir_walk>
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
f0101110:	85 c0                	test   %eax,%eax
f0101112:	74 3f                	je     f0101153 <page_lookup+0x67>
f0101114:	f6 00 01             	testb  $0x1,(%eax)
f0101117:	74 41                	je     f010115a <page_lookup+0x6e>
		return NULL;
	if(pte_store)
f0101119:	85 db                	test   %ebx,%ebx
f010111b:	74 02                	je     f010111f <page_lookup+0x33>
		*pte_store = pte;
f010111d:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f010111f:	8b 00                	mov    (%eax),%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101121:	c1 e8 0c             	shr    $0xc,%eax
f0101124:	3b 05 a4 df 17 f0    	cmp    0xf017dfa4,%eax
f010112a:	72 1c                	jb     f0101148 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f010112c:	c7 44 24 08 30 55 10 	movl   $0xf0105530,0x8(%esp)
f0101133:	f0 
f0101134:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010113b:	00 
f010113c:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0101143:	e8 76 ef ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f0101148:	8b 15 ac df 17 f0    	mov    0xf017dfac,%edx
f010114e:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0101151:	eb 0c                	jmp    f010115f <page_lookup+0x73>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
		return NULL;
f0101153:	b8 00 00 00 00       	mov    $0x0,%eax
f0101158:	eb 05                	jmp    f010115f <page_lookup+0x73>
f010115a:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f010115f:	83 c4 14             	add    $0x14,%esp
f0101162:	5b                   	pop    %ebx
f0101163:	5d                   	pop    %ebp
f0101164:	c3                   	ret    

f0101165 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101165:	55                   	push   %ebp
f0101166:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101168:	8b 45 0c             	mov    0xc(%ebp),%eax
f010116b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010116e:	5d                   	pop    %ebp
f010116f:	c3                   	ret    

f0101170 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101170:	55                   	push   %ebp
f0101171:	89 e5                	mov    %esp,%ebp
f0101173:	83 ec 28             	sub    $0x28,%esp
f0101176:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101179:	89 75 fc             	mov    %esi,-0x4(%ebp)
f010117c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010117f:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct Page *pp = page_lookup(pgdir, va, &pte);
f0101182:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101185:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101189:	89 74 24 04          	mov    %esi,0x4(%esp)
f010118d:	89 1c 24             	mov    %ebx,(%esp)
f0101190:	e8 57 ff ff ff       	call   f01010ec <page_lookup>
	if(!pp)
f0101195:	85 c0                	test   %eax,%eax
f0101197:	74 1d                	je     f01011b6 <page_remove+0x46>
		return;
	page_decref(pp);
f0101199:	89 04 24             	mov    %eax,(%esp)
f010119c:	e8 ea fd ff ff       	call   f0100f8b <page_decref>
	*pte = 0;
f01011a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011a4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01011aa:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011ae:	89 1c 24             	mov    %ebx,(%esp)
f01011b1:	e8 af ff ff ff       	call   f0101165 <tlb_invalidate>
	
}
f01011b6:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01011b9:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01011bc:	89 ec                	mov    %ebp,%esp
f01011be:	5d                   	pop    %ebp
f01011bf:	c3                   	ret    

f01011c0 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01011c0:	55                   	push   %ebp
f01011c1:	89 e5                	mov    %esp,%ebp
f01011c3:	83 ec 28             	sub    $0x28,%esp
f01011c6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01011c9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01011cc:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01011cf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01011d2:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f01011d5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01011dc:	00 
f01011dd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e4:	89 04 24             	mov    %eax,(%esp)
f01011e7:	e8 c2 fd ff ff       	call   f0100fae <pgdir_walk>
f01011ec:	89 c6                	mov    %eax,%esi
	if(!pte)
f01011ee:	85 c0                	test   %eax,%eax
f01011f0:	74 66                	je     f0101258 <page_insert+0x98>
		return -E_NO_MEM;
	if(*pte & PTE_P) { /* already a page */
f01011f2:	8b 00                	mov    (%eax),%eax
f01011f4:	a8 01                	test   $0x1,%al
f01011f6:	74 3c                	je     f0101234 <page_insert+0x74>
		if(PTE_ADDR(*pte) == page2pa(pp)){	/* the same one */
f01011f8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01011fd:	89 da                	mov    %ebx,%edx
f01011ff:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
f0101205:	c1 fa 03             	sar    $0x3,%edx
f0101208:	c1 e2 0c             	shl    $0xc,%edx
f010120b:	39 d0                	cmp    %edx,%eax
f010120d:	75 16                	jne    f0101225 <page_insert+0x65>
			tlb_invalidate(pgdir, va);
f010120f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101213:	8b 45 08             	mov    0x8(%ebp),%eax
f0101216:	89 04 24             	mov    %eax,(%esp)
f0101219:	e8 47 ff ff ff       	call   f0101165 <tlb_invalidate>
			pp -> pp_ref--;
f010121e:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f0101223:	eb 0f                	jmp    f0101234 <page_insert+0x74>
		}else
			page_remove(pgdir, va);
f0101225:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101229:	8b 45 08             	mov    0x8(%ebp),%eax
f010122c:	89 04 24             	mov    %eax,(%esp)
f010122f:	e8 3c ff ff ff       	call   f0101170 <page_remove>
	}
	*pte = page2pa(pp)|perm|PTE_P;
f0101234:	8b 55 14             	mov    0x14(%ebp),%edx
f0101237:	83 ca 01             	or     $0x1,%edx
f010123a:	89 d8                	mov    %ebx,%eax
f010123c:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f0101242:	c1 f8 03             	sar    $0x3,%eax
f0101245:	c1 e0 0c             	shl    $0xc,%eax
f0101248:	09 d0                	or     %edx,%eax
f010124a:	89 06                	mov    %eax,(%esi)
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
f010124c:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f0101251:	b8 00 00 00 00       	mov    $0x0,%eax
f0101256:	eb 05                	jmp    f010125d <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
	if(!pte)
		return -E_NO_MEM;
f0101258:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*pte = page2pa(pp)|perm|PTE_P;
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
	return 0;
}
f010125d:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101260:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101263:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101266:	89 ec                	mov    %ebp,%esp
f0101268:	5d                   	pop    %ebp
f0101269:	c3                   	ret    

f010126a <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010126a:	55                   	push   %ebp
f010126b:	89 e5                	mov    %esp,%ebp
f010126d:	57                   	push   %edi
f010126e:	56                   	push   %esi
f010126f:	53                   	push   %ebx
f0101270:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101273:	b8 15 00 00 00       	mov    $0x15,%eax
f0101278:	e8 e5 f7 ff ff       	call   f0100a62 <nvram_read>
f010127d:	c1 e0 0a             	shl    $0xa,%eax
f0101280:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101286:	85 c0                	test   %eax,%eax
f0101288:	0f 48 c2             	cmovs  %edx,%eax
f010128b:	c1 f8 0c             	sar    $0xc,%eax
f010128e:	a3 f8 d2 17 f0       	mov    %eax,0xf017d2f8
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101293:	b8 17 00 00 00       	mov    $0x17,%eax
f0101298:	e8 c5 f7 ff ff       	call   f0100a62 <nvram_read>
f010129d:	c1 e0 0a             	shl    $0xa,%eax
f01012a0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012a6:	85 c0                	test   %eax,%eax
f01012a8:	0f 48 c2             	cmovs  %edx,%eax
f01012ab:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012ae:	85 c0                	test   %eax,%eax
f01012b0:	74 0e                	je     f01012c0 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012b2:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012b8:	89 15 a4 df 17 f0    	mov    %edx,0xf017dfa4
f01012be:	eb 0c                	jmp    f01012cc <mem_init+0x62>
	else
		npages = npages_basemem;
f01012c0:	8b 15 f8 d2 17 f0    	mov    0xf017d2f8,%edx
f01012c6:	89 15 a4 df 17 f0    	mov    %edx,0xf017dfa4

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01012cc:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012cf:	c1 e8 0a             	shr    $0xa,%eax
f01012d2:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012d6:	a1 f8 d2 17 f0       	mov    0xf017d2f8,%eax
f01012db:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012de:	c1 e8 0a             	shr    $0xa,%eax
f01012e1:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012e5:	a1 a4 df 17 f0       	mov    0xf017dfa4,%eax
f01012ea:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012ed:	c1 e8 0a             	shr    $0xa,%eax
f01012f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f4:	c7 04 24 50 55 10 f0 	movl   $0xf0105550,(%esp)
f01012fb:	e8 1a 23 00 00       	call   f010361a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101300:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101305:	e8 e5 f6 ff ff       	call   f01009ef <boot_alloc>
f010130a:	a3 a8 df 17 f0       	mov    %eax,0xf017dfa8
	memset(kern_pgdir, 0, PGSIZE);
f010130f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101316:	00 
f0101317:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010131e:	00 
f010131f:	89 04 24             	mov    %eax,(%esp)
f0101322:	e8 ce 36 00 00       	call   f01049f5 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101327:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010132c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101331:	77 20                	ja     f0101353 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101333:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101337:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f010133e:	f0 
f010133f:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
f0101346:	00 
f0101347:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010134e:	e8 6b ed ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101353:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101359:	83 ca 05             	or     $0x5,%edx
f010135c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page *)boot_alloc(npages * sizeof(struct Page));
f0101362:	a1 a4 df 17 f0       	mov    0xf017dfa4,%eax
f0101367:	c1 e0 03             	shl    $0x3,%eax
f010136a:	e8 80 f6 ff ff       	call   f01009ef <boot_alloc>
f010136f:	a3 ac df 17 f0       	mov    %eax,0xf017dfac
		
//panic("PDX(0)");
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f0101374:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101379:	e8 71 f6 ff ff       	call   f01009ef <boot_alloc>
f010137e:	a3 08 d3 17 f0       	mov    %eax,0xf017d308
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101383:	e8 8d fa ff ff       	call   f0100e15 <page_init>

	check_page_free_list(1);
f0101388:	b8 01 00 00 00       	mov    $0x1,%eax
f010138d:	e8 02 f7 ff ff       	call   f0100a94 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101392:	83 3d ac df 17 f0 00 	cmpl   $0x0,0xf017dfac
f0101399:	75 1c                	jne    f01013b7 <mem_init+0x14d>
		panic("'pages' is a null pointer!");
f010139b:	c7 44 24 08 40 5c 10 	movl   $0xf0105c40,0x8(%esp)
f01013a2:	f0 
f01013a3:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f01013aa:	00 
f01013ab:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01013b2:	e8 07 ed ff ff       	call   f01000be <_panic>
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013b7:	a1 00 d3 17 f0       	mov    0xf017d300,%eax
f01013bc:	85 c0                	test   %eax,%eax
f01013be:	74 10                	je     f01013d0 <mem_init+0x166>
f01013c0:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f01013c5:	83 c3 01             	add    $0x1,%ebx
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013c8:	8b 00                	mov    (%eax),%eax
f01013ca:	85 c0                	test   %eax,%eax
f01013cc:	75 f7                	jne    f01013c5 <mem_init+0x15b>
f01013ce:	eb 05                	jmp    f01013d5 <mem_init+0x16b>
f01013d0:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013d5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013dc:	e8 0a fb ff ff       	call   f0100eeb <page_alloc>
f01013e1:	89 c7                	mov    %eax,%edi
f01013e3:	85 c0                	test   %eax,%eax
f01013e5:	75 24                	jne    f010140b <mem_init+0x1a1>
f01013e7:	c7 44 24 0c 5b 5c 10 	movl   $0xf0105c5b,0xc(%esp)
f01013ee:	f0 
f01013ef:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01013f6:	f0 
f01013f7:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f01013fe:	00 
f01013ff:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101406:	e8 b3 ec ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f010140b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101412:	e8 d4 fa ff ff       	call   f0100eeb <page_alloc>
f0101417:	89 c6                	mov    %eax,%esi
f0101419:	85 c0                	test   %eax,%eax
f010141b:	75 24                	jne    f0101441 <mem_init+0x1d7>
f010141d:	c7 44 24 0c 71 5c 10 	movl   $0xf0105c71,0xc(%esp)
f0101424:	f0 
f0101425:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010142c:	f0 
f010142d:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f0101434:	00 
f0101435:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010143c:	e8 7d ec ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101441:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101448:	e8 9e fa ff ff       	call   f0100eeb <page_alloc>
f010144d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101450:	85 c0                	test   %eax,%eax
f0101452:	75 24                	jne    f0101478 <mem_init+0x20e>
f0101454:	c7 44 24 0c 87 5c 10 	movl   $0xf0105c87,0xc(%esp)
f010145b:	f0 
f010145c:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101463:	f0 
f0101464:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f010146b:	00 
f010146c:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101473:	e8 46 ec ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101478:	39 f7                	cmp    %esi,%edi
f010147a:	75 24                	jne    f01014a0 <mem_init+0x236>
f010147c:	c7 44 24 0c 9d 5c 10 	movl   $0xf0105c9d,0xc(%esp)
f0101483:	f0 
f0101484:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010148b:	f0 
f010148c:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0101493:	00 
f0101494:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010149b:	e8 1e ec ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014a0:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01014a3:	74 05                	je     f01014aa <mem_init+0x240>
f01014a5:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01014a8:	75 24                	jne    f01014ce <mem_init+0x264>
f01014aa:	c7 44 24 0c 8c 55 10 	movl   $0xf010558c,0xc(%esp)
f01014b1:	f0 
f01014b2:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01014b9:	f0 
f01014ba:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f01014c1:	00 
f01014c2:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01014c9:	e8 f0 eb ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01014ce:	8b 15 ac df 17 f0    	mov    0xf017dfac,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014d4:	a1 a4 df 17 f0       	mov    0xf017dfa4,%eax
f01014d9:	c1 e0 0c             	shl    $0xc,%eax
f01014dc:	89 f9                	mov    %edi,%ecx
f01014de:	29 d1                	sub    %edx,%ecx
f01014e0:	c1 f9 03             	sar    $0x3,%ecx
f01014e3:	c1 e1 0c             	shl    $0xc,%ecx
f01014e6:	39 c1                	cmp    %eax,%ecx
f01014e8:	72 24                	jb     f010150e <mem_init+0x2a4>
f01014ea:	c7 44 24 0c af 5c 10 	movl   $0xf0105caf,0xc(%esp)
f01014f1:	f0 
f01014f2:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01014f9:	f0 
f01014fa:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0101501:	00 
f0101502:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101509:	e8 b0 eb ff ff       	call   f01000be <_panic>
f010150e:	89 f1                	mov    %esi,%ecx
f0101510:	29 d1                	sub    %edx,%ecx
f0101512:	c1 f9 03             	sar    $0x3,%ecx
f0101515:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101518:	39 c8                	cmp    %ecx,%eax
f010151a:	77 24                	ja     f0101540 <mem_init+0x2d6>
f010151c:	c7 44 24 0c cc 5c 10 	movl   $0xf0105ccc,0xc(%esp)
f0101523:	f0 
f0101524:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010152b:	f0 
f010152c:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
f0101533:	00 
f0101534:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010153b:	e8 7e eb ff ff       	call   f01000be <_panic>
f0101540:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101543:	29 d1                	sub    %edx,%ecx
f0101545:	89 ca                	mov    %ecx,%edx
f0101547:	c1 fa 03             	sar    $0x3,%edx
f010154a:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010154d:	39 d0                	cmp    %edx,%eax
f010154f:	77 24                	ja     f0101575 <mem_init+0x30b>
f0101551:	c7 44 24 0c e9 5c 10 	movl   $0xf0105ce9,0xc(%esp)
f0101558:	f0 
f0101559:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101560:	f0 
f0101561:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f0101568:	00 
f0101569:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101570:	e8 49 eb ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101575:	a1 00 d3 17 f0       	mov    0xf017d300,%eax
f010157a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010157d:	c7 05 00 d3 17 f0 00 	movl   $0x0,0xf017d300
f0101584:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101587:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010158e:	e8 58 f9 ff ff       	call   f0100eeb <page_alloc>
f0101593:	85 c0                	test   %eax,%eax
f0101595:	74 24                	je     f01015bb <mem_init+0x351>
f0101597:	c7 44 24 0c 06 5d 10 	movl   $0xf0105d06,0xc(%esp)
f010159e:	f0 
f010159f:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01015a6:	f0 
f01015a7:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f01015ae:	00 
f01015af:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01015b6:	e8 03 eb ff ff       	call   f01000be <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015bb:	89 3c 24             	mov    %edi,(%esp)
f01015be:	e8 ac f9 ff ff       	call   f0100f6f <page_free>
	page_free(pp1);
f01015c3:	89 34 24             	mov    %esi,(%esp)
f01015c6:	e8 a4 f9 ff ff       	call   f0100f6f <page_free>
	page_free(pp2);
f01015cb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015ce:	89 04 24             	mov    %eax,(%esp)
f01015d1:	e8 99 f9 ff ff       	call   f0100f6f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015dd:	e8 09 f9 ff ff       	call   f0100eeb <page_alloc>
f01015e2:	89 c6                	mov    %eax,%esi
f01015e4:	85 c0                	test   %eax,%eax
f01015e6:	75 24                	jne    f010160c <mem_init+0x3a2>
f01015e8:	c7 44 24 0c 5b 5c 10 	movl   $0xf0105c5b,0xc(%esp)
f01015ef:	f0 
f01015f0:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01015f7:	f0 
f01015f8:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f01015ff:	00 
f0101600:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101607:	e8 b2 ea ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f010160c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101613:	e8 d3 f8 ff ff       	call   f0100eeb <page_alloc>
f0101618:	89 c7                	mov    %eax,%edi
f010161a:	85 c0                	test   %eax,%eax
f010161c:	75 24                	jne    f0101642 <mem_init+0x3d8>
f010161e:	c7 44 24 0c 71 5c 10 	movl   $0xf0105c71,0xc(%esp)
f0101625:	f0 
f0101626:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010162d:	f0 
f010162e:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
f0101635:	00 
f0101636:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010163d:	e8 7c ea ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101642:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101649:	e8 9d f8 ff ff       	call   f0100eeb <page_alloc>
f010164e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101651:	85 c0                	test   %eax,%eax
f0101653:	75 24                	jne    f0101679 <mem_init+0x40f>
f0101655:	c7 44 24 0c 87 5c 10 	movl   $0xf0105c87,0xc(%esp)
f010165c:	f0 
f010165d:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101664:	f0 
f0101665:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f010166c:	00 
f010166d:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101674:	e8 45 ea ff ff       	call   f01000be <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101679:	39 fe                	cmp    %edi,%esi
f010167b:	75 24                	jne    f01016a1 <mem_init+0x437>
f010167d:	c7 44 24 0c 9d 5c 10 	movl   $0xf0105c9d,0xc(%esp)
f0101684:	f0 
f0101685:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010168c:	f0 
f010168d:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0101694:	00 
f0101695:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010169c:	e8 1d ea ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016a1:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01016a4:	74 05                	je     f01016ab <mem_init+0x441>
f01016a6:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01016a9:	75 24                	jne    f01016cf <mem_init+0x465>
f01016ab:	c7 44 24 0c 8c 55 10 	movl   $0xf010558c,0xc(%esp)
f01016b2:	f0 
f01016b3:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01016ba:	f0 
f01016bb:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f01016c2:	00 
f01016c3:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01016ca:	e8 ef e9 ff ff       	call   f01000be <_panic>
	assert(!page_alloc(0));
f01016cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016d6:	e8 10 f8 ff ff       	call   f0100eeb <page_alloc>
f01016db:	85 c0                	test   %eax,%eax
f01016dd:	74 24                	je     f0101703 <mem_init+0x499>
f01016df:	c7 44 24 0c 06 5d 10 	movl   $0xf0105d06,0xc(%esp)
f01016e6:	f0 
f01016e7:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01016ee:	f0 
f01016ef:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f01016f6:	00 
f01016f7:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01016fe:	e8 bb e9 ff ff       	call   f01000be <_panic>
f0101703:	89 f0                	mov    %esi,%eax
f0101705:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f010170b:	c1 f8 03             	sar    $0x3,%eax
f010170e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101711:	89 c2                	mov    %eax,%edx
f0101713:	c1 ea 0c             	shr    $0xc,%edx
f0101716:	3b 15 a4 df 17 f0    	cmp    0xf017dfa4,%edx
f010171c:	72 20                	jb     f010173e <mem_init+0x4d4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010171e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101722:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0101729:	f0 
f010172a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101731:	00 
f0101732:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0101739:	e8 80 e9 ff ff       	call   f01000be <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010173e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101745:	00 
f0101746:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010174d:	00 
	return (void *)(pa + KERNBASE);
f010174e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101753:	89 04 24             	mov    %eax,(%esp)
f0101756:	e8 9a 32 00 00       	call   f01049f5 <memset>
	page_free(pp0);
f010175b:	89 34 24             	mov    %esi,(%esp)
f010175e:	e8 0c f8 ff ff       	call   f0100f6f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101763:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010176a:	e8 7c f7 ff ff       	call   f0100eeb <page_alloc>
f010176f:	85 c0                	test   %eax,%eax
f0101771:	75 24                	jne    f0101797 <mem_init+0x52d>
f0101773:	c7 44 24 0c 15 5d 10 	movl   $0xf0105d15,0xc(%esp)
f010177a:	f0 
f010177b:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101782:	f0 
f0101783:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f010178a:	00 
f010178b:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101792:	e8 27 e9 ff ff       	call   f01000be <_panic>
	assert(pp && pp0 == pp);
f0101797:	39 c6                	cmp    %eax,%esi
f0101799:	74 24                	je     f01017bf <mem_init+0x555>
f010179b:	c7 44 24 0c 33 5d 10 	movl   $0xf0105d33,0xc(%esp)
f01017a2:	f0 
f01017a3:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01017aa:	f0 
f01017ab:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f01017b2:	00 
f01017b3:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01017ba:	e8 ff e8 ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01017bf:	89 f2                	mov    %esi,%edx
f01017c1:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
f01017c7:	c1 fa 03             	sar    $0x3,%edx
f01017ca:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017cd:	89 d0                	mov    %edx,%eax
f01017cf:	c1 e8 0c             	shr    $0xc,%eax
f01017d2:	3b 05 a4 df 17 f0    	cmp    0xf017dfa4,%eax
f01017d8:	72 20                	jb     f01017fa <mem_init+0x590>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017da:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017de:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f01017e5:	f0 
f01017e6:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01017ed:	00 
f01017ee:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f01017f5:	e8 c4 e8 ff ff       	call   f01000be <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017fa:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101801:	75 11                	jne    f0101814 <mem_init+0x5aa>
f0101803:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101809:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010180f:	80 38 00             	cmpb   $0x0,(%eax)
f0101812:	74 24                	je     f0101838 <mem_init+0x5ce>
f0101814:	c7 44 24 0c 43 5d 10 	movl   $0xf0105d43,0xc(%esp)
f010181b:	f0 
f010181c:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101823:	f0 
f0101824:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f010182b:	00 
f010182c:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101833:	e8 86 e8 ff ff       	call   f01000be <_panic>
f0101838:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010183b:	39 d0                	cmp    %edx,%eax
f010183d:	75 d0                	jne    f010180f <mem_init+0x5a5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010183f:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101842:	89 15 00 d3 17 f0    	mov    %edx,0xf017d300

	// free the pages we took
	page_free(pp0);
f0101848:	89 34 24             	mov    %esi,(%esp)
f010184b:	e8 1f f7 ff ff       	call   f0100f6f <page_free>
	page_free(pp1);
f0101850:	89 3c 24             	mov    %edi,(%esp)
f0101853:	e8 17 f7 ff ff       	call   f0100f6f <page_free>
	page_free(pp2);
f0101858:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010185b:	89 04 24             	mov    %eax,(%esp)
f010185e:	e8 0c f7 ff ff       	call   f0100f6f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101863:	a1 00 d3 17 f0       	mov    0xf017d300,%eax
f0101868:	85 c0                	test   %eax,%eax
f010186a:	74 09                	je     f0101875 <mem_init+0x60b>
		--nfree;
f010186c:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010186f:	8b 00                	mov    (%eax),%eax
f0101871:	85 c0                	test   %eax,%eax
f0101873:	75 f7                	jne    f010186c <mem_init+0x602>
		--nfree;
	assert(nfree == 0);
f0101875:	85 db                	test   %ebx,%ebx
f0101877:	74 24                	je     f010189d <mem_init+0x633>
f0101879:	c7 44 24 0c 4d 5d 10 	movl   $0xf0105d4d,0xc(%esp)
f0101880:	f0 
f0101881:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101888:	f0 
f0101889:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f0101890:	00 
f0101891:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101898:	e8 21 e8 ff ff       	call   f01000be <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010189d:	c7 04 24 ac 55 10 f0 	movl   $0xf01055ac,(%esp)
f01018a4:	e8 71 1d 00 00       	call   f010361a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018a9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018b0:	e8 36 f6 ff ff       	call   f0100eeb <page_alloc>
f01018b5:	89 c3                	mov    %eax,%ebx
f01018b7:	85 c0                	test   %eax,%eax
f01018b9:	75 24                	jne    f01018df <mem_init+0x675>
f01018bb:	c7 44 24 0c 5b 5c 10 	movl   $0xf0105c5b,0xc(%esp)
f01018c2:	f0 
f01018c3:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01018ca:	f0 
f01018cb:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f01018d2:	00 
f01018d3:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01018da:	e8 df e7 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f01018df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018e6:	e8 00 f6 ff ff       	call   f0100eeb <page_alloc>
f01018eb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018ee:	85 c0                	test   %eax,%eax
f01018f0:	75 24                	jne    f0101916 <mem_init+0x6ac>
f01018f2:	c7 44 24 0c 71 5c 10 	movl   $0xf0105c71,0xc(%esp)
f01018f9:	f0 
f01018fa:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101901:	f0 
f0101902:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101909:	00 
f010190a:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101911:	e8 a8 e7 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101916:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010191d:	e8 c9 f5 ff ff       	call   f0100eeb <page_alloc>
f0101922:	89 c6                	mov    %eax,%esi
f0101924:	85 c0                	test   %eax,%eax
f0101926:	75 24                	jne    f010194c <mem_init+0x6e2>
f0101928:	c7 44 24 0c 87 5c 10 	movl   $0xf0105c87,0xc(%esp)
f010192f:	f0 
f0101930:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101937:	f0 
f0101938:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f010193f:	00 
f0101940:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101947:	e8 72 e7 ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010194c:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f010194f:	75 24                	jne    f0101975 <mem_init+0x70b>
f0101951:	c7 44 24 0c 9d 5c 10 	movl   $0xf0105c9d,0xc(%esp)
f0101958:	f0 
f0101959:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101960:	f0 
f0101961:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101968:	00 
f0101969:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101970:	e8 49 e7 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101975:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101978:	74 04                	je     f010197e <mem_init+0x714>
f010197a:	39 c3                	cmp    %eax,%ebx
f010197c:	75 24                	jne    f01019a2 <mem_init+0x738>
f010197e:	c7 44 24 0c 8c 55 10 	movl   $0xf010558c,0xc(%esp)
f0101985:	f0 
f0101986:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010198d:	f0 
f010198e:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101995:	00 
f0101996:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010199d:	e8 1c e7 ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019a2:	8b 3d 00 d3 17 f0    	mov    0xf017d300,%edi
f01019a8:	89 7d c8             	mov    %edi,-0x38(%ebp)
	page_free_list = 0;
f01019ab:	c7 05 00 d3 17 f0 00 	movl   $0x0,0xf017d300
f01019b2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019b5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019bc:	e8 2a f5 ff ff       	call   f0100eeb <page_alloc>
f01019c1:	85 c0                	test   %eax,%eax
f01019c3:	74 24                	je     f01019e9 <mem_init+0x77f>
f01019c5:	c7 44 24 0c 06 5d 10 	movl   $0xf0105d06,0xc(%esp)
f01019cc:	f0 
f01019cd:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01019d4:	f0 
f01019d5:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f01019dc:	00 
f01019dd:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01019e4:	e8 d5 e6 ff ff       	call   f01000be <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019e9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019ec:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019f0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019f7:	00 
f01019f8:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f01019fd:	89 04 24             	mov    %eax,(%esp)
f0101a00:	e8 e7 f6 ff ff       	call   f01010ec <page_lookup>
f0101a05:	85 c0                	test   %eax,%eax
f0101a07:	74 24                	je     f0101a2d <mem_init+0x7c3>
f0101a09:	c7 44 24 0c cc 55 10 	movl   $0xf01055cc,0xc(%esp)
f0101a10:	f0 
f0101a11:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101a18:	f0 
f0101a19:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0101a20:	00 
f0101a21:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101a28:	e8 91 e6 ff ff       	call   f01000be <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a2d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a34:	00 
f0101a35:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a3c:	00 
f0101a3d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a40:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a44:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0101a49:	89 04 24             	mov    %eax,(%esp)
f0101a4c:	e8 6f f7 ff ff       	call   f01011c0 <page_insert>
f0101a51:	85 c0                	test   %eax,%eax
f0101a53:	78 24                	js     f0101a79 <mem_init+0x80f>
f0101a55:	c7 44 24 0c 04 56 10 	movl   $0xf0105604,0xc(%esp)
f0101a5c:	f0 
f0101a5d:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101a64:	f0 
f0101a65:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101a6c:	00 
f0101a6d:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101a74:	e8 45 e6 ff ff       	call   f01000be <_panic>
//panic("\n");
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a79:	89 1c 24             	mov    %ebx,(%esp)
f0101a7c:	e8 ee f4 ff ff       	call   f0100f6f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a81:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a88:	00 
f0101a89:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a90:	00 
f0101a91:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a98:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0101a9d:	89 04 24             	mov    %eax,(%esp)
f0101aa0:	e8 1b f7 ff ff       	call   f01011c0 <page_insert>
f0101aa5:	85 c0                	test   %eax,%eax
f0101aa7:	74 24                	je     f0101acd <mem_init+0x863>
f0101aa9:	c7 44 24 0c 34 56 10 	movl   $0xf0105634,0xc(%esp)
f0101ab0:	f0 
f0101ab1:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101ab8:	f0 
f0101ab9:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0101ac0:	00 
f0101ac1:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101ac8:	e8 f1 e5 ff ff       	call   f01000be <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101acd:	8b 3d a8 df 17 f0    	mov    0xf017dfa8,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ad3:	8b 15 ac df 17 f0    	mov    0xf017dfac,%edx
f0101ad9:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101adc:	8b 17                	mov    (%edi),%edx
f0101ade:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ae4:	89 d8                	mov    %ebx,%eax
f0101ae6:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101ae9:	c1 f8 03             	sar    $0x3,%eax
f0101aec:	c1 e0 0c             	shl    $0xc,%eax
f0101aef:	39 c2                	cmp    %eax,%edx
f0101af1:	74 24                	je     f0101b17 <mem_init+0x8ad>
f0101af3:	c7 44 24 0c 64 56 10 	movl   $0xf0105664,0xc(%esp)
f0101afa:	f0 
f0101afb:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101b02:	f0 
f0101b03:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101b0a:	00 
f0101b0b:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101b12:	e8 a7 e5 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b17:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b1c:	89 f8                	mov    %edi,%eax
f0101b1e:	e8 5d ee ff ff       	call   f0100980 <check_va2pa>
f0101b23:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b26:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101b29:	c1 fa 03             	sar    $0x3,%edx
f0101b2c:	c1 e2 0c             	shl    $0xc,%edx
f0101b2f:	39 d0                	cmp    %edx,%eax
f0101b31:	74 24                	je     f0101b57 <mem_init+0x8ed>
f0101b33:	c7 44 24 0c 8c 56 10 	movl   $0xf010568c,0xc(%esp)
f0101b3a:	f0 
f0101b3b:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101b42:	f0 
f0101b43:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101b4a:	00 
f0101b4b:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101b52:	e8 67 e5 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f0101b57:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b5a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b5f:	74 24                	je     f0101b85 <mem_init+0x91b>
f0101b61:	c7 44 24 0c 58 5d 10 	movl   $0xf0105d58,0xc(%esp)
f0101b68:	f0 
f0101b69:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101b70:	f0 
f0101b71:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101b78:	00 
f0101b79:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101b80:	e8 39 e5 ff ff       	call   f01000be <_panic>
	assert(pp0->pp_ref == 1);
f0101b85:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b8a:	74 24                	je     f0101bb0 <mem_init+0x946>
f0101b8c:	c7 44 24 0c 69 5d 10 	movl   $0xf0105d69,0xc(%esp)
f0101b93:	f0 
f0101b94:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101b9b:	f0 
f0101b9c:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101ba3:	00 
f0101ba4:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101bab:	e8 0e e5 ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bb0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bb7:	00 
f0101bb8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bbf:	00 
f0101bc0:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101bc4:	89 3c 24             	mov    %edi,(%esp)
f0101bc7:	e8 f4 f5 ff ff       	call   f01011c0 <page_insert>
f0101bcc:	85 c0                	test   %eax,%eax
f0101bce:	74 24                	je     f0101bf4 <mem_init+0x98a>
f0101bd0:	c7 44 24 0c bc 56 10 	movl   $0xf01056bc,0xc(%esp)
f0101bd7:	f0 
f0101bd8:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101bdf:	f0 
f0101be0:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0101be7:	00 
f0101be8:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101bef:	e8 ca e4 ff ff       	call   f01000be <_panic>
	//panic("va2pa: %x,page %x", check_va2pa(kern_pgdir, PGSIZE), page2pa(pp2));
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bf4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bf9:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0101bfe:	e8 7d ed ff ff       	call   f0100980 <check_va2pa>
f0101c03:	89 f2                	mov    %esi,%edx
f0101c05:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
f0101c0b:	c1 fa 03             	sar    $0x3,%edx
f0101c0e:	c1 e2 0c             	shl    $0xc,%edx
f0101c11:	39 d0                	cmp    %edx,%eax
f0101c13:	74 24                	je     f0101c39 <mem_init+0x9cf>
f0101c15:	c7 44 24 0c f8 56 10 	movl   $0xf01056f8,0xc(%esp)
f0101c1c:	f0 
f0101c1d:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101c24:	f0 
f0101c25:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101c2c:	00 
f0101c2d:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101c34:	e8 85 e4 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101c39:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c3e:	74 24                	je     f0101c64 <mem_init+0x9fa>
f0101c40:	c7 44 24 0c 7a 5d 10 	movl   $0xf0105d7a,0xc(%esp)
f0101c47:	f0 
f0101c48:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101c4f:	f0 
f0101c50:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101c57:	00 
f0101c58:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101c5f:	e8 5a e4 ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c64:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c6b:	e8 7b f2 ff ff       	call   f0100eeb <page_alloc>
f0101c70:	85 c0                	test   %eax,%eax
f0101c72:	74 24                	je     f0101c98 <mem_init+0xa2e>
f0101c74:	c7 44 24 0c 06 5d 10 	movl   $0xf0105d06,0xc(%esp)
f0101c7b:	f0 
f0101c7c:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101c83:	f0 
f0101c84:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101c8b:	00 
f0101c8c:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101c93:	e8 26 e4 ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c98:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c9f:	00 
f0101ca0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ca7:	00 
f0101ca8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101cac:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0101cb1:	89 04 24             	mov    %eax,(%esp)
f0101cb4:	e8 07 f5 ff ff       	call   f01011c0 <page_insert>
f0101cb9:	85 c0                	test   %eax,%eax
f0101cbb:	74 24                	je     f0101ce1 <mem_init+0xa77>
f0101cbd:	c7 44 24 0c bc 56 10 	movl   $0xf01056bc,0xc(%esp)
f0101cc4:	f0 
f0101cc5:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101ccc:	f0 
f0101ccd:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101cd4:	00 
f0101cd5:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101cdc:	e8 dd e3 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ce1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ce6:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0101ceb:	e8 90 ec ff ff       	call   f0100980 <check_va2pa>
f0101cf0:	89 f2                	mov    %esi,%edx
f0101cf2:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
f0101cf8:	c1 fa 03             	sar    $0x3,%edx
f0101cfb:	c1 e2 0c             	shl    $0xc,%edx
f0101cfe:	39 d0                	cmp    %edx,%eax
f0101d00:	74 24                	je     f0101d26 <mem_init+0xabc>
f0101d02:	c7 44 24 0c f8 56 10 	movl   $0xf01056f8,0xc(%esp)
f0101d09:	f0 
f0101d0a:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101d11:	f0 
f0101d12:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101d19:	00 
f0101d1a:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101d21:	e8 98 e3 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101d26:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d2b:	74 24                	je     f0101d51 <mem_init+0xae7>
f0101d2d:	c7 44 24 0c 7a 5d 10 	movl   $0xf0105d7a,0xc(%esp)
f0101d34:	f0 
f0101d35:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101d3c:	f0 
f0101d3d:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0101d44:	00 
f0101d45:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101d4c:	e8 6d e3 ff ff       	call   f01000be <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d51:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d58:	e8 8e f1 ff ff       	call   f0100eeb <page_alloc>
f0101d5d:	85 c0                	test   %eax,%eax
f0101d5f:	74 24                	je     f0101d85 <mem_init+0xb1b>
f0101d61:	c7 44 24 0c 06 5d 10 	movl   $0xf0105d06,0xc(%esp)
f0101d68:	f0 
f0101d69:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101d70:	f0 
f0101d71:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0101d78:	00 
f0101d79:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101d80:	e8 39 e3 ff ff       	call   f01000be <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d85:	8b 15 a8 df 17 f0    	mov    0xf017dfa8,%edx
f0101d8b:	8b 02                	mov    (%edx),%eax
f0101d8d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d92:	89 c1                	mov    %eax,%ecx
f0101d94:	c1 e9 0c             	shr    $0xc,%ecx
f0101d97:	3b 0d a4 df 17 f0    	cmp    0xf017dfa4,%ecx
f0101d9d:	72 20                	jb     f0101dbf <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d9f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101da3:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0101daa:	f0 
f0101dab:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101db2:	00 
f0101db3:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101dba:	e8 ff e2 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0101dbf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101dc4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101dc7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dce:	00 
f0101dcf:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101dd6:	00 
f0101dd7:	89 14 24             	mov    %edx,(%esp)
f0101dda:	e8 cf f1 ff ff       	call   f0100fae <pgdir_walk>
f0101ddf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101de2:	83 c2 04             	add    $0x4,%edx
f0101de5:	39 d0                	cmp    %edx,%eax
f0101de7:	74 24                	je     f0101e0d <mem_init+0xba3>
f0101de9:	c7 44 24 0c 28 57 10 	movl   $0xf0105728,0xc(%esp)
f0101df0:	f0 
f0101df1:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101df8:	f0 
f0101df9:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0101e00:	00 
f0101e01:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101e08:	e8 b1 e2 ff ff       	call   f01000be <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e0d:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e14:	00 
f0101e15:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e1c:	00 
f0101e1d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e21:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0101e26:	89 04 24             	mov    %eax,(%esp)
f0101e29:	e8 92 f3 ff ff       	call   f01011c0 <page_insert>
f0101e2e:	85 c0                	test   %eax,%eax
f0101e30:	74 24                	je     f0101e56 <mem_init+0xbec>
f0101e32:	c7 44 24 0c 68 57 10 	movl   $0xf0105768,0xc(%esp)
f0101e39:	f0 
f0101e3a:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101e41:	f0 
f0101e42:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101e49:	00 
f0101e4a:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101e51:	e8 68 e2 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e56:	8b 3d a8 df 17 f0    	mov    0xf017dfa8,%edi
f0101e5c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e61:	89 f8                	mov    %edi,%eax
f0101e63:	e8 18 eb ff ff       	call   f0100980 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e68:	89 f2                	mov    %esi,%edx
f0101e6a:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
f0101e70:	c1 fa 03             	sar    $0x3,%edx
f0101e73:	c1 e2 0c             	shl    $0xc,%edx
f0101e76:	39 d0                	cmp    %edx,%eax
f0101e78:	74 24                	je     f0101e9e <mem_init+0xc34>
f0101e7a:	c7 44 24 0c f8 56 10 	movl   $0xf01056f8,0xc(%esp)
f0101e81:	f0 
f0101e82:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101e89:	f0 
f0101e8a:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0101e91:	00 
f0101e92:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101e99:	e8 20 e2 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101e9e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ea3:	74 24                	je     f0101ec9 <mem_init+0xc5f>
f0101ea5:	c7 44 24 0c 7a 5d 10 	movl   $0xf0105d7a,0xc(%esp)
f0101eac:	f0 
f0101ead:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101eb4:	f0 
f0101eb5:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101ebc:	00 
f0101ebd:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101ec4:	e8 f5 e1 ff ff       	call   f01000be <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ec9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ed0:	00 
f0101ed1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ed8:	00 
f0101ed9:	89 3c 24             	mov    %edi,(%esp)
f0101edc:	e8 cd f0 ff ff       	call   f0100fae <pgdir_walk>
f0101ee1:	f6 00 04             	testb  $0x4,(%eax)
f0101ee4:	75 24                	jne    f0101f0a <mem_init+0xca0>
f0101ee6:	c7 44 24 0c a8 57 10 	movl   $0xf01057a8,0xc(%esp)
f0101eed:	f0 
f0101eee:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101ef5:	f0 
f0101ef6:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0101efd:	00 
f0101efe:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101f05:	e8 b4 e1 ff ff       	call   f01000be <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f0a:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0101f0f:	f6 00 04             	testb  $0x4,(%eax)
f0101f12:	75 24                	jne    f0101f38 <mem_init+0xcce>
f0101f14:	c7 44 24 0c 8b 5d 10 	movl   $0xf0105d8b,0xc(%esp)
f0101f1b:	f0 
f0101f1c:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101f23:	f0 
f0101f24:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0101f2b:	00 
f0101f2c:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101f33:	e8 86 e1 ff ff       	call   f01000be <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f38:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f3f:	00 
f0101f40:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f47:	00 
f0101f48:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f4c:	89 04 24             	mov    %eax,(%esp)
f0101f4f:	e8 6c f2 ff ff       	call   f01011c0 <page_insert>
f0101f54:	85 c0                	test   %eax,%eax
f0101f56:	78 24                	js     f0101f7c <mem_init+0xd12>
f0101f58:	c7 44 24 0c dc 57 10 	movl   $0xf01057dc,0xc(%esp)
f0101f5f:	f0 
f0101f60:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101f67:	f0 
f0101f68:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f0101f6f:	00 
f0101f70:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101f77:	e8 42 e1 ff ff       	call   f01000be <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f7c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f83:	00 
f0101f84:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f8b:	00 
f0101f8c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f8f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f93:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0101f98:	89 04 24             	mov    %eax,(%esp)
f0101f9b:	e8 20 f2 ff ff       	call   f01011c0 <page_insert>
f0101fa0:	85 c0                	test   %eax,%eax
f0101fa2:	74 24                	je     f0101fc8 <mem_init+0xd5e>
f0101fa4:	c7 44 24 0c 14 58 10 	movl   $0xf0105814,0xc(%esp)
f0101fab:	f0 
f0101fac:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101fb3:	f0 
f0101fb4:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101fbb:	00 
f0101fbc:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0101fc3:	e8 f6 e0 ff ff       	call   f01000be <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fc8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fcf:	00 
f0101fd0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fd7:	00 
f0101fd8:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0101fdd:	89 04 24             	mov    %eax,(%esp)
f0101fe0:	e8 c9 ef ff ff       	call   f0100fae <pgdir_walk>
f0101fe5:	f6 00 04             	testb  $0x4,(%eax)
f0101fe8:	74 24                	je     f010200e <mem_init+0xda4>
f0101fea:	c7 44 24 0c 50 58 10 	movl   $0xf0105850,0xc(%esp)
f0101ff1:	f0 
f0101ff2:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0101ff9:	f0 
f0101ffa:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0102001:	00 
f0102002:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102009:	e8 b0 e0 ff ff       	call   f01000be <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010200e:	8b 3d a8 df 17 f0    	mov    0xf017dfa8,%edi
f0102014:	ba 00 00 00 00       	mov    $0x0,%edx
f0102019:	89 f8                	mov    %edi,%eax
f010201b:	e8 60 e9 ff ff       	call   f0100980 <check_va2pa>
f0102020:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102023:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102026:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f010202c:	c1 f8 03             	sar    $0x3,%eax
f010202f:	c1 e0 0c             	shl    $0xc,%eax
f0102032:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102035:	74 24                	je     f010205b <mem_init+0xdf1>
f0102037:	c7 44 24 0c 88 58 10 	movl   $0xf0105888,0xc(%esp)
f010203e:	f0 
f010203f:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102046:	f0 
f0102047:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f010204e:	00 
f010204f:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102056:	e8 63 e0 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010205b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102060:	89 f8                	mov    %edi,%eax
f0102062:	e8 19 e9 ff ff       	call   f0100980 <check_va2pa>
f0102067:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010206a:	74 24                	je     f0102090 <mem_init+0xe26>
f010206c:	c7 44 24 0c b4 58 10 	movl   $0xf01058b4,0xc(%esp)
f0102073:	f0 
f0102074:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010207b:	f0 
f010207c:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102083:	00 
f0102084:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010208b:	e8 2e e0 ff ff       	call   f01000be <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102090:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102093:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0102098:	74 24                	je     f01020be <mem_init+0xe54>
f010209a:	c7 44 24 0c a1 5d 10 	movl   $0xf0105da1,0xc(%esp)
f01020a1:	f0 
f01020a2:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01020a9:	f0 
f01020aa:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f01020b1:	00 
f01020b2:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01020b9:	e8 00 e0 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01020be:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020c3:	74 24                	je     f01020e9 <mem_init+0xe7f>
f01020c5:	c7 44 24 0c b2 5d 10 	movl   $0xf0105db2,0xc(%esp)
f01020cc:	f0 
f01020cd:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01020d4:	f0 
f01020d5:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f01020dc:	00 
f01020dd:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01020e4:	e8 d5 df ff ff       	call   f01000be <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01020e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020f0:	e8 f6 ed ff ff       	call   f0100eeb <page_alloc>
f01020f5:	85 c0                	test   %eax,%eax
f01020f7:	74 04                	je     f01020fd <mem_init+0xe93>
f01020f9:	39 c6                	cmp    %eax,%esi
f01020fb:	74 24                	je     f0102121 <mem_init+0xeb7>
f01020fd:	c7 44 24 0c e4 58 10 	movl   $0xf01058e4,0xc(%esp)
f0102104:	f0 
f0102105:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010210c:	f0 
f010210d:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0102114:	00 
f0102115:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010211c:	e8 9d df ff ff       	call   f01000be <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102121:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102128:	00 
f0102129:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f010212e:	89 04 24             	mov    %eax,(%esp)
f0102131:	e8 3a f0 ff ff       	call   f0101170 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102136:	8b 3d a8 df 17 f0    	mov    0xf017dfa8,%edi
f010213c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102141:	89 f8                	mov    %edi,%eax
f0102143:	e8 38 e8 ff ff       	call   f0100980 <check_va2pa>
f0102148:	83 f8 ff             	cmp    $0xffffffff,%eax
f010214b:	74 24                	je     f0102171 <mem_init+0xf07>
f010214d:	c7 44 24 0c 08 59 10 	movl   $0xf0105908,0xc(%esp)
f0102154:	f0 
f0102155:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010215c:	f0 
f010215d:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0102164:	00 
f0102165:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010216c:	e8 4d df ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102171:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102176:	89 f8                	mov    %edi,%eax
f0102178:	e8 03 e8 ff ff       	call   f0100980 <check_va2pa>
f010217d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102180:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
f0102186:	c1 fa 03             	sar    $0x3,%edx
f0102189:	c1 e2 0c             	shl    $0xc,%edx
f010218c:	39 d0                	cmp    %edx,%eax
f010218e:	74 24                	je     f01021b4 <mem_init+0xf4a>
f0102190:	c7 44 24 0c b4 58 10 	movl   $0xf01058b4,0xc(%esp)
f0102197:	f0 
f0102198:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010219f:	f0 
f01021a0:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f01021a7:	00 
f01021a8:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01021af:	e8 0a df ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f01021b4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021b7:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021bc:	74 24                	je     f01021e2 <mem_init+0xf78>
f01021be:	c7 44 24 0c 58 5d 10 	movl   $0xf0105d58,0xc(%esp)
f01021c5:	f0 
f01021c6:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01021cd:	f0 
f01021ce:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f01021d5:	00 
f01021d6:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01021dd:	e8 dc de ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01021e2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021e7:	74 24                	je     f010220d <mem_init+0xfa3>
f01021e9:	c7 44 24 0c b2 5d 10 	movl   $0xf0105db2,0xc(%esp)
f01021f0:	f0 
f01021f1:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01021f8:	f0 
f01021f9:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f0102200:	00 
f0102201:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102208:	e8 b1 de ff ff       	call   f01000be <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010220d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102214:	00 
f0102215:	89 3c 24             	mov    %edi,(%esp)
f0102218:	e8 53 ef ff ff       	call   f0101170 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010221d:	8b 3d a8 df 17 f0    	mov    0xf017dfa8,%edi
f0102223:	ba 00 00 00 00       	mov    $0x0,%edx
f0102228:	89 f8                	mov    %edi,%eax
f010222a:	e8 51 e7 ff ff       	call   f0100980 <check_va2pa>
f010222f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102232:	74 24                	je     f0102258 <mem_init+0xfee>
f0102234:	c7 44 24 0c 08 59 10 	movl   $0xf0105908,0xc(%esp)
f010223b:	f0 
f010223c:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102243:	f0 
f0102244:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f010224b:	00 
f010224c:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102253:	e8 66 de ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102258:	ba 00 10 00 00       	mov    $0x1000,%edx
f010225d:	89 f8                	mov    %edi,%eax
f010225f:	e8 1c e7 ff ff       	call   f0100980 <check_va2pa>
f0102264:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102267:	74 24                	je     f010228d <mem_init+0x1023>
f0102269:	c7 44 24 0c 2c 59 10 	movl   $0xf010592c,0xc(%esp)
f0102270:	f0 
f0102271:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102278:	f0 
f0102279:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102280:	00 
f0102281:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102288:	e8 31 de ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f010228d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102290:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102295:	74 24                	je     f01022bb <mem_init+0x1051>
f0102297:	c7 44 24 0c c3 5d 10 	movl   $0xf0105dc3,0xc(%esp)
f010229e:	f0 
f010229f:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01022a6:	f0 
f01022a7:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f01022ae:	00 
f01022af:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01022b6:	e8 03 de ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01022bb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01022c0:	74 24                	je     f01022e6 <mem_init+0x107c>
f01022c2:	c7 44 24 0c b2 5d 10 	movl   $0xf0105db2,0xc(%esp)
f01022c9:	f0 
f01022ca:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01022d1:	f0 
f01022d2:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f01022d9:	00 
f01022da:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01022e1:	e8 d8 dd ff ff       	call   f01000be <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01022e6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022ed:	e8 f9 eb ff ff       	call   f0100eeb <page_alloc>
f01022f2:	85 c0                	test   %eax,%eax
f01022f4:	74 05                	je     f01022fb <mem_init+0x1091>
f01022f6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01022f9:	74 24                	je     f010231f <mem_init+0x10b5>
f01022fb:	c7 44 24 0c 54 59 10 	movl   $0xf0105954,0xc(%esp)
f0102302:	f0 
f0102303:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010230a:	f0 
f010230b:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0102312:	00 
f0102313:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010231a:	e8 9f dd ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010231f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102326:	e8 c0 eb ff ff       	call   f0100eeb <page_alloc>
f010232b:	85 c0                	test   %eax,%eax
f010232d:	74 24                	je     f0102353 <mem_init+0x10e9>
f010232f:	c7 44 24 0c 06 5d 10 	movl   $0xf0105d06,0xc(%esp)
f0102336:	f0 
f0102337:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010233e:	f0 
f010233f:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0102346:	00 
f0102347:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010234e:	e8 6b dd ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102353:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0102358:	8b 08                	mov    (%eax),%ecx
f010235a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102360:	89 da                	mov    %ebx,%edx
f0102362:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
f0102368:	c1 fa 03             	sar    $0x3,%edx
f010236b:	c1 e2 0c             	shl    $0xc,%edx
f010236e:	39 d1                	cmp    %edx,%ecx
f0102370:	74 24                	je     f0102396 <mem_init+0x112c>
f0102372:	c7 44 24 0c 64 56 10 	movl   $0xf0105664,0xc(%esp)
f0102379:	f0 
f010237a:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102381:	f0 
f0102382:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0102389:	00 
f010238a:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102391:	e8 28 dd ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f0102396:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010239c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01023a1:	74 24                	je     f01023c7 <mem_init+0x115d>
f01023a3:	c7 44 24 0c 69 5d 10 	movl   $0xf0105d69,0xc(%esp)
f01023aa:	f0 
f01023ab:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01023b2:	f0 
f01023b3:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f01023ba:	00 
f01023bb:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01023c2:	e8 f7 dc ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f01023c7:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01023cd:	89 1c 24             	mov    %ebx,(%esp)
f01023d0:	e8 9a eb ff ff       	call   f0100f6f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01023d5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01023dc:	00 
f01023dd:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01023e4:	00 
f01023e5:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f01023ea:	89 04 24             	mov    %eax,(%esp)
f01023ed:	e8 bc eb ff ff       	call   f0100fae <pgdir_walk>
f01023f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01023f5:	8b 15 a8 df 17 f0    	mov    0xf017dfa8,%edx
f01023fb:	8b 4a 04             	mov    0x4(%edx),%ecx
f01023fe:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102404:	89 4d cc             	mov    %ecx,-0x34(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102407:	8b 0d a4 df 17 f0    	mov    0xf017dfa4,%ecx
f010240d:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102410:	c1 ef 0c             	shr    $0xc,%edi
f0102413:	39 cf                	cmp    %ecx,%edi
f0102415:	72 23                	jb     f010243a <mem_init+0x11d0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102417:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010241a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010241e:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0102425:	f0 
f0102426:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f010242d:	00 
f010242e:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102435:	e8 84 dc ff ff       	call   f01000be <_panic>
	assert(ptep == ptep1 + PTX(va));
f010243a:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010243d:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102443:	39 f8                	cmp    %edi,%eax
f0102445:	74 24                	je     f010246b <mem_init+0x1201>
f0102447:	c7 44 24 0c d4 5d 10 	movl   $0xf0105dd4,0xc(%esp)
f010244e:	f0 
f010244f:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102456:	f0 
f0102457:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f010245e:	00 
f010245f:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102466:	e8 53 dc ff ff       	call   f01000be <_panic>
	kern_pgdir[PDX(va)] = 0;
f010246b:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102472:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102478:	89 d8                	mov    %ebx,%eax
f010247a:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f0102480:	c1 f8 03             	sar    $0x3,%eax
f0102483:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102486:	89 c2                	mov    %eax,%edx
f0102488:	c1 ea 0c             	shr    $0xc,%edx
f010248b:	39 d1                	cmp    %edx,%ecx
f010248d:	77 20                	ja     f01024af <mem_init+0x1245>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010248f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102493:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f010249a:	f0 
f010249b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01024a2:	00 
f01024a3:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f01024aa:	e8 0f dc ff ff       	call   f01000be <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01024af:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024b6:	00 
f01024b7:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01024be:	00 
	return (void *)(pa + KERNBASE);
f01024bf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024c4:	89 04 24             	mov    %eax,(%esp)
f01024c7:	e8 29 25 00 00       	call   f01049f5 <memset>
	page_free(pp0);
f01024cc:	89 1c 24             	mov    %ebx,(%esp)
f01024cf:	e8 9b ea ff ff       	call   f0100f6f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01024d4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024db:	00 
f01024dc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024e3:	00 
f01024e4:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f01024e9:	89 04 24             	mov    %eax,(%esp)
f01024ec:	e8 bd ea ff ff       	call   f0100fae <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024f1:	89 da                	mov    %ebx,%edx
f01024f3:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
f01024f9:	c1 fa 03             	sar    $0x3,%edx
f01024fc:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024ff:	89 d0                	mov    %edx,%eax
f0102501:	c1 e8 0c             	shr    $0xc,%eax
f0102504:	3b 05 a4 df 17 f0    	cmp    0xf017dfa4,%eax
f010250a:	72 20                	jb     f010252c <mem_init+0x12c2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010250c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102510:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0102517:	f0 
f0102518:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010251f:	00 
f0102520:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0102527:	e8 92 db ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f010252c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102532:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102535:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f010253c:	75 11                	jne    f010254f <mem_init+0x12e5>
f010253e:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102544:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010254a:	f6 00 01             	testb  $0x1,(%eax)
f010254d:	74 24                	je     f0102573 <mem_init+0x1309>
f010254f:	c7 44 24 0c ec 5d 10 	movl   $0xf0105dec,0xc(%esp)
f0102556:	f0 
f0102557:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010255e:	f0 
f010255f:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102566:	00 
f0102567:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010256e:	e8 4b db ff ff       	call   f01000be <_panic>
f0102573:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102576:	39 d0                	cmp    %edx,%eax
f0102578:	75 d0                	jne    f010254a <mem_init+0x12e0>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010257a:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f010257f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102585:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f010258b:	8b 7d c8             	mov    -0x38(%ebp),%edi
f010258e:	89 3d 00 d3 17 f0    	mov    %edi,0xf017d300

	// free the pages we took
	page_free(pp0);
f0102594:	89 1c 24             	mov    %ebx,(%esp)
f0102597:	e8 d3 e9 ff ff       	call   f0100f6f <page_free>
	page_free(pp1);
f010259c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010259f:	89 04 24             	mov    %eax,(%esp)
f01025a2:	e8 c8 e9 ff ff       	call   f0100f6f <page_free>
	page_free(pp2);
f01025a7:	89 34 24             	mov    %esi,(%esp)
f01025aa:	e8 c0 e9 ff ff       	call   f0100f6f <page_free>

	cprintf("check_page() succeeded!\n");
f01025af:	c7 04 24 03 5e 10 f0 	movl   $0xf0105e03,(%esp)
f01025b6:	e8 5f 10 00 00       	call   f010361a <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
//pte_t *p = (pte_t *)0xf03fd000;
	boot_map_region(kern_pgdir,UPAGES, npages * sizeof(struct Page), PADDR(pages), PTE_U|PTE_P);
f01025bb:	a1 ac df 17 f0       	mov    0xf017dfac,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025c0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025c5:	77 20                	ja     f01025e7 <mem_init+0x137d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025c7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025cb:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f01025d2:	f0 
f01025d3:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
f01025da:	00 
f01025db:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01025e2:	e8 d7 da ff ff       	call   f01000be <_panic>
f01025e7:	8b 0d a4 df 17 f0    	mov    0xf017dfa4,%ecx
f01025ed:	c1 e1 03             	shl    $0x3,%ecx
f01025f0:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01025f7:	00 
	return (physaddr_t)kva - KERNBASE;
f01025f8:	05 00 00 00 10       	add    $0x10000000,%eax
f01025fd:	89 04 24             	mov    %eax,(%esp)
f0102600:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102605:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f010260a:	e8 82 ea ff ff       	call   f0101091 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS, NENV * sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f010260f:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102614:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102619:	77 20                	ja     f010263b <mem_init+0x13d1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010261b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010261f:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f0102626:	f0 
f0102627:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f010262e:	00 
f010262f:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102636:	e8 83 da ff ff       	call   f01000be <_panic>
f010263b:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102642:	00 
	return (physaddr_t)kva - KERNBASE;
f0102643:	05 00 00 00 10       	add    $0x10000000,%eax
f0102648:	89 04 24             	mov    %eax,(%esp)
f010264b:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102650:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102655:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f010265a:	e8 32 ea ff ff       	call   f0101091 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010265f:	ba 00 10 11 f0       	mov    $0xf0111000,%edx
f0102664:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010266a:	77 20                	ja     f010268c <mem_init+0x1422>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010266c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102670:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f0102677:	f0 
f0102678:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
f010267f:	00 
f0102680:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102687:	e8 32 da ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f010268c:	c7 45 cc 00 10 11 00 	movl   $0x111000,-0x34(%ebp)
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
//	cprintf("\n%x\n", KSTACKTOP - KSTKSIZE);
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_P|PTE_W);
f0102693:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010269a:	00 
f010269b:	c7 04 24 00 10 11 00 	movl   $0x111000,(%esp)
f01026a2:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026a7:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01026ac:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f01026b1:	e8 db e9 ff ff       	call   f0101091 <boot_map_region>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ~0x0 - KERNBASE + 1;
	//cprintf("the size is %x", size);
	boot_map_region(kern_pgdir, KERNBASE, size, (physaddr_t)0,PTE_P|PTE_W);
f01026b6:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01026bd:	00 
f01026be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026c5:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01026ca:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01026cf:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f01026d4:	e8 b8 e9 ff ff       	call   f0101091 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01026d9:	8b 1d a8 df 17 f0    	mov    0xf017dfa8,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f01026df:	8b 3d a4 df 17 f0    	mov    0xf017dfa4,%edi
f01026e5:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01026e8:	8d 04 fd ff 0f 00 00 	lea    0xfff(,%edi,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f01026ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026f4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01026f7:	75 30                	jne    f0102729 <mem_init+0x14bf>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01026f9:	8b 35 08 d3 17 f0    	mov    0xf017d308,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026ff:	89 f7                	mov    %esi,%edi
f0102701:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102706:	89 d8                	mov    %ebx,%eax
f0102708:	e8 73 e2 ff ff       	call   f0100980 <check_va2pa>
f010270d:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102713:	0f 86 94 00 00 00    	jbe    f01027ad <mem_init+0x1543>
f0102719:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010271e:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f0102724:	e9 a4 00 00 00       	jmp    f01027cd <mem_init+0x1563>
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102729:	8b 35 ac df 17 f0    	mov    0xf017dfac,%esi
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f010272f:	8d be 00 00 00 10    	lea    0x10000000(%esi),%edi
f0102735:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010273a:	89 d8                	mov    %ebx,%eax
f010273c:	e8 3f e2 ff ff       	call   f0100980 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102741:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102747:	77 20                	ja     f0102769 <mem_init+0x14ff>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102749:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010274d:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f0102754:	f0 
f0102755:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f010275c:	00 
f010275d:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102764:	e8 55 d9 ff ff       	call   f01000be <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102769:	ba 00 00 00 00       	mov    $0x0,%edx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010276e:	8d 0c 17             	lea    (%edi,%edx,1),%ecx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102771:	39 c1                	cmp    %eax,%ecx
f0102773:	74 24                	je     f0102799 <mem_init+0x152f>
f0102775:	c7 44 24 0c 78 59 10 	movl   $0xf0105978,0xc(%esp)
f010277c:	f0 
f010277d:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102784:	f0 
f0102785:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f010278c:	00 
f010278d:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102794:	e8 25 d9 ff ff       	call   f01000be <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102799:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f010279f:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01027a2:	0f 87 58 06 00 00    	ja     f0102e00 <mem_init+0x1b96>
f01027a8:	e9 4c ff ff ff       	jmp    f01026f9 <mem_init+0x148f>
f01027ad:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01027b1:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f01027b8:	f0 
f01027b9:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f01027c0:	00 
f01027c1:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01027c8:	e8 f1 d8 ff ff       	call   f01000be <_panic>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027cd:	8d 14 37             	lea    (%edi,%esi,1),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01027d0:	39 c2                	cmp    %eax,%edx
f01027d2:	74 24                	je     f01027f8 <mem_init+0x158e>
f01027d4:	c7 44 24 0c ac 59 10 	movl   $0xf01059ac,0xc(%esp)
f01027db:	f0 
f01027dc:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01027e3:	f0 
f01027e4:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f01027eb:	00 
f01027ec:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01027f3:	e8 c6 d8 ff ff       	call   f01000be <_panic>
f01027f8:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027fe:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102804:	0f 85 e8 05 00 00    	jne    f0102df2 <mem_init+0x1b88>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010280a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010280d:	c1 e7 0c             	shl    $0xc,%edi
f0102810:	85 ff                	test   %edi,%edi
f0102812:	0f 84 b3 05 00 00    	je     f0102dcb <mem_init+0x1b61>
f0102818:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010281d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102823:	89 d8                	mov    %ebx,%eax
f0102825:	e8 56 e1 ff ff       	call   f0100980 <check_va2pa>
f010282a:	39 c6                	cmp    %eax,%esi
f010282c:	74 24                	je     f0102852 <mem_init+0x15e8>
f010282e:	c7 44 24 0c e0 59 10 	movl   $0xf01059e0,0xc(%esp)
f0102835:	f0 
f0102836:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010283d:	f0 
f010283e:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
f0102845:	00 
f0102846:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010284d:	e8 6c d8 ff ff       	call   f01000be <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102852:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102858:	39 fe                	cmp    %edi,%esi
f010285a:	72 c1                	jb     f010281d <mem_init+0x15b3>
f010285c:	e9 6a 05 00 00       	jmp    f0102dcb <mem_init+0x1b61>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102861:	39 c3                	cmp    %eax,%ebx
f0102863:	74 24                	je     f0102889 <mem_init+0x161f>
f0102865:	c7 44 24 0c 08 5a 10 	movl   $0xf0105a08,0xc(%esp)
f010286c:	f0 
f010286d:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102874:	f0 
f0102875:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f010287c:	00 
f010287d:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102884:	e8 35 d8 ff ff       	call   f01000be <_panic>
f0102889:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010288f:	39 f3                	cmp    %esi,%ebx
f0102891:	0f 85 24 05 00 00    	jne    f0102dbb <mem_init+0x1b51>
f0102897:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010289a:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f010289f:	89 d8                	mov    %ebx,%eax
f01028a1:	e8 da e0 ff ff       	call   f0100980 <check_va2pa>
f01028a6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028a9:	74 24                	je     f01028cf <mem_init+0x1665>
f01028ab:	c7 44 24 0c 50 5a 10 	movl   $0xf0105a50,0xc(%esp)
f01028b2:	f0 
f01028b3:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01028ba:	f0 
f01028bb:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f01028c2:	00 
f01028c3:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01028ca:	e8 ef d7 ff ff       	call   f01000be <_panic>
f01028cf:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01028d4:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f01028da:	83 fa 03             	cmp    $0x3,%edx
f01028dd:	77 2e                	ja     f010290d <mem_init+0x16a3>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01028df:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01028e3:	0f 85 aa 00 00 00    	jne    f0102993 <mem_init+0x1729>
f01028e9:	c7 44 24 0c 1c 5e 10 	movl   $0xf0105e1c,0xc(%esp)
f01028f0:	f0 
f01028f1:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f01028f8:	f0 
f01028f9:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f0102900:	00 
f0102901:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102908:	e8 b1 d7 ff ff       	call   f01000be <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010290d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102912:	76 55                	jbe    f0102969 <mem_init+0x16ff>
				assert(pgdir[i] & PTE_P);
f0102914:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102917:	f6 c2 01             	test   $0x1,%dl
f010291a:	75 24                	jne    f0102940 <mem_init+0x16d6>
f010291c:	c7 44 24 0c 1c 5e 10 	movl   $0xf0105e1c,0xc(%esp)
f0102923:	f0 
f0102924:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010292b:	f0 
f010292c:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f0102933:	00 
f0102934:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010293b:	e8 7e d7 ff ff       	call   f01000be <_panic>
				assert(pgdir[i] & PTE_W);
f0102940:	f6 c2 02             	test   $0x2,%dl
f0102943:	75 4e                	jne    f0102993 <mem_init+0x1729>
f0102945:	c7 44 24 0c 2d 5e 10 	movl   $0xf0105e2d,0xc(%esp)
f010294c:	f0 
f010294d:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102954:	f0 
f0102955:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f010295c:	00 
f010295d:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102964:	e8 55 d7 ff ff       	call   f01000be <_panic>
			} else
				assert(pgdir[i] == 0);
f0102969:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010296d:	74 24                	je     f0102993 <mem_init+0x1729>
f010296f:	c7 44 24 0c 3e 5e 10 	movl   $0xf0105e3e,0xc(%esp)
f0102976:	f0 
f0102977:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f010297e:	f0 
f010297f:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0102986:	00 
f0102987:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f010298e:	e8 2b d7 ff ff       	call   f01000be <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102993:	83 c0 01             	add    $0x1,%eax
f0102996:	3d 00 04 00 00       	cmp    $0x400,%eax
f010299b:	0f 85 33 ff ff ff    	jne    f01028d4 <mem_init+0x166a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01029a1:	c7 04 24 80 5a 10 f0 	movl   $0xf0105a80,(%esp)
f01029a8:	e8 6d 0c 00 00       	call   f010361a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01029ad:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029b2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029b7:	77 20                	ja     f01029d9 <mem_init+0x176f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029bd:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f01029c4:	f0 
f01029c5:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
f01029cc:	00 
f01029cd:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f01029d4:	e8 e5 d6 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01029d9:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01029de:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01029e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01029e6:	e8 a9 e0 ff ff       	call   f0100a94 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01029eb:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01029ee:	83 e0 f3             	and    $0xfffffff3,%eax
f01029f1:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01029f6:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01029f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a00:	e8 e6 e4 ff ff       	call   f0100eeb <page_alloc>
f0102a05:	89 c3                	mov    %eax,%ebx
f0102a07:	85 c0                	test   %eax,%eax
f0102a09:	75 24                	jne    f0102a2f <mem_init+0x17c5>
f0102a0b:	c7 44 24 0c 5b 5c 10 	movl   $0xf0105c5b,0xc(%esp)
f0102a12:	f0 
f0102a13:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102a1a:	f0 
f0102a1b:	c7 44 24 04 b5 03 00 	movl   $0x3b5,0x4(%esp)
f0102a22:	00 
f0102a23:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102a2a:	e8 8f d6 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0102a2f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a36:	e8 b0 e4 ff ff       	call   f0100eeb <page_alloc>
f0102a3b:	89 c7                	mov    %eax,%edi
f0102a3d:	85 c0                	test   %eax,%eax
f0102a3f:	75 24                	jne    f0102a65 <mem_init+0x17fb>
f0102a41:	c7 44 24 0c 71 5c 10 	movl   $0xf0105c71,0xc(%esp)
f0102a48:	f0 
f0102a49:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102a50:	f0 
f0102a51:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0102a58:	00 
f0102a59:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102a60:	e8 59 d6 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0102a65:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a6c:	e8 7a e4 ff ff       	call   f0100eeb <page_alloc>
f0102a71:	89 c6                	mov    %eax,%esi
f0102a73:	85 c0                	test   %eax,%eax
f0102a75:	75 24                	jne    f0102a9b <mem_init+0x1831>
f0102a77:	c7 44 24 0c 87 5c 10 	movl   $0xf0105c87,0xc(%esp)
f0102a7e:	f0 
f0102a7f:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102a86:	f0 
f0102a87:	c7 44 24 04 b7 03 00 	movl   $0x3b7,0x4(%esp)
f0102a8e:	00 
f0102a8f:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102a96:	e8 23 d6 ff ff       	call   f01000be <_panic>
	page_free(pp0);
f0102a9b:	89 1c 24             	mov    %ebx,(%esp)
f0102a9e:	e8 cc e4 ff ff       	call   f0100f6f <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102aa3:	89 f8                	mov    %edi,%eax
f0102aa5:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f0102aab:	c1 f8 03             	sar    $0x3,%eax
f0102aae:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ab1:	89 c2                	mov    %eax,%edx
f0102ab3:	c1 ea 0c             	shr    $0xc,%edx
f0102ab6:	3b 15 a4 df 17 f0    	cmp    0xf017dfa4,%edx
f0102abc:	72 20                	jb     f0102ade <mem_init+0x1874>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102abe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ac2:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0102ac9:	f0 
f0102aca:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102ad1:	00 
f0102ad2:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0102ad9:	e8 e0 d5 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ade:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ae5:	00 
f0102ae6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102aed:	00 
	return (void *)(pa + KERNBASE);
f0102aee:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102af3:	89 04 24             	mov    %eax,(%esp)
f0102af6:	e8 fa 1e 00 00       	call   f01049f5 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102afb:	89 f0                	mov    %esi,%eax
f0102afd:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f0102b03:	c1 f8 03             	sar    $0x3,%eax
f0102b06:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b09:	89 c2                	mov    %eax,%edx
f0102b0b:	c1 ea 0c             	shr    $0xc,%edx
f0102b0e:	3b 15 a4 df 17 f0    	cmp    0xf017dfa4,%edx
f0102b14:	72 20                	jb     f0102b36 <mem_init+0x18cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b16:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b1a:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0102b21:	f0 
f0102b22:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102b29:	00 
f0102b2a:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0102b31:	e8 88 d5 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b36:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b3d:	00 
f0102b3e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102b45:	00 
	return (void *)(pa + KERNBASE);
f0102b46:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b4b:	89 04 24             	mov    %eax,(%esp)
f0102b4e:	e8 a2 1e 00 00       	call   f01049f5 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b53:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b5a:	00 
f0102b5b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b62:	00 
f0102b63:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102b67:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0102b6c:	89 04 24             	mov    %eax,(%esp)
f0102b6f:	e8 4c e6 ff ff       	call   f01011c0 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b74:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b79:	74 24                	je     f0102b9f <mem_init+0x1935>
f0102b7b:	c7 44 24 0c 58 5d 10 	movl   $0xf0105d58,0xc(%esp)
f0102b82:	f0 
f0102b83:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102b8a:	f0 
f0102b8b:	c7 44 24 04 bc 03 00 	movl   $0x3bc,0x4(%esp)
f0102b92:	00 
f0102b93:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102b9a:	e8 1f d5 ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b9f:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ba6:	01 01 01 
f0102ba9:	74 24                	je     f0102bcf <mem_init+0x1965>
f0102bab:	c7 44 24 0c a0 5a 10 	movl   $0xf0105aa0,0xc(%esp)
f0102bb2:	f0 
f0102bb3:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102bba:	f0 
f0102bbb:	c7 44 24 04 bd 03 00 	movl   $0x3bd,0x4(%esp)
f0102bc2:	00 
f0102bc3:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102bca:	e8 ef d4 ff ff       	call   f01000be <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bcf:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102bd6:	00 
f0102bd7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bde:	00 
f0102bdf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102be3:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0102be8:	89 04 24             	mov    %eax,(%esp)
f0102beb:	e8 d0 e5 ff ff       	call   f01011c0 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102bf0:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bf7:	02 02 02 
f0102bfa:	74 24                	je     f0102c20 <mem_init+0x19b6>
f0102bfc:	c7 44 24 0c c4 5a 10 	movl   $0xf0105ac4,0xc(%esp)
f0102c03:	f0 
f0102c04:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102c0b:	f0 
f0102c0c:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0102c13:	00 
f0102c14:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102c1b:	e8 9e d4 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0102c20:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c25:	74 24                	je     f0102c4b <mem_init+0x19e1>
f0102c27:	c7 44 24 0c 7a 5d 10 	movl   $0xf0105d7a,0xc(%esp)
f0102c2e:	f0 
f0102c2f:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102c36:	f0 
f0102c37:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f0102c3e:	00 
f0102c3f:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102c46:	e8 73 d4 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f0102c4b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102c50:	74 24                	je     f0102c76 <mem_init+0x1a0c>
f0102c52:	c7 44 24 0c c3 5d 10 	movl   $0xf0105dc3,0xc(%esp)
f0102c59:	f0 
f0102c5a:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102c61:	f0 
f0102c62:	c7 44 24 04 c1 03 00 	movl   $0x3c1,0x4(%esp)
f0102c69:	00 
f0102c6a:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102c71:	e8 48 d4 ff ff       	call   f01000be <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c76:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c7d:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c80:	89 f0                	mov    %esi,%eax
f0102c82:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f0102c88:	c1 f8 03             	sar    $0x3,%eax
f0102c8b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c8e:	89 c2                	mov    %eax,%edx
f0102c90:	c1 ea 0c             	shr    $0xc,%edx
f0102c93:	3b 15 a4 df 17 f0    	cmp    0xf017dfa4,%edx
f0102c99:	72 20                	jb     f0102cbb <mem_init+0x1a51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c9b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c9f:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0102ca6:	f0 
f0102ca7:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102cae:	00 
f0102caf:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0102cb6:	e8 03 d4 ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102cbb:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102cc2:	03 03 03 
f0102cc5:	74 24                	je     f0102ceb <mem_init+0x1a81>
f0102cc7:	c7 44 24 0c e8 5a 10 	movl   $0xf0105ae8,0xc(%esp)
f0102cce:	f0 
f0102ccf:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102cd6:	f0 
f0102cd7:	c7 44 24 04 c3 03 00 	movl   $0x3c3,0x4(%esp)
f0102cde:	00 
f0102cdf:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102ce6:	e8 d3 d3 ff ff       	call   f01000be <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102ceb:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102cf2:	00 
f0102cf3:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0102cf8:	89 04 24             	mov    %eax,(%esp)
f0102cfb:	e8 70 e4 ff ff       	call   f0101170 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d00:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d05:	74 24                	je     f0102d2b <mem_init+0x1ac1>
f0102d07:	c7 44 24 0c b2 5d 10 	movl   $0xf0105db2,0xc(%esp)
f0102d0e:	f0 
f0102d0f:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102d16:	f0 
f0102d17:	c7 44 24 04 c5 03 00 	movl   $0x3c5,0x4(%esp)
f0102d1e:	00 
f0102d1f:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102d26:	e8 93 d3 ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d2b:	a1 a8 df 17 f0       	mov    0xf017dfa8,%eax
f0102d30:	8b 08                	mov    (%eax),%ecx
f0102d32:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d38:	89 da                	mov    %ebx,%edx
f0102d3a:	2b 15 ac df 17 f0    	sub    0xf017dfac,%edx
f0102d40:	c1 fa 03             	sar    $0x3,%edx
f0102d43:	c1 e2 0c             	shl    $0xc,%edx
f0102d46:	39 d1                	cmp    %edx,%ecx
f0102d48:	74 24                	je     f0102d6e <mem_init+0x1b04>
f0102d4a:	c7 44 24 0c 64 56 10 	movl   $0xf0105664,0xc(%esp)
f0102d51:	f0 
f0102d52:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102d59:	f0 
f0102d5a:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0102d61:	00 
f0102d62:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102d69:	e8 50 d3 ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f0102d6e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102d74:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d79:	74 24                	je     f0102d9f <mem_init+0x1b35>
f0102d7b:	c7 44 24 0c 69 5d 10 	movl   $0xf0105d69,0xc(%esp)
f0102d82:	f0 
f0102d83:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0102d8a:	f0 
f0102d8b:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f0102d92:	00 
f0102d93:	c7 04 24 75 5b 10 f0 	movl   $0xf0105b75,(%esp)
f0102d9a:	e8 1f d3 ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f0102d9f:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102da5:	89 1c 24             	mov    %ebx,(%esp)
f0102da8:	e8 c2 e1 ff ff       	call   f0100f6f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102dad:	c7 04 24 14 5b 10 f0 	movl   $0xf0105b14,(%esp)
f0102db4:	e8 61 08 00 00       	call   f010361a <cprintf>
f0102db9:	eb 59                	jmp    f0102e14 <mem_init+0x1baa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102dbb:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102dbe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102dc1:	e8 ba db ff ff       	call   f0100980 <check_va2pa>
f0102dc6:	e9 96 fa ff ff       	jmp    f0102861 <mem_init+0x15f7>
f0102dcb:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102dd0:	89 d8                	mov    %ebx,%eax
f0102dd2:	e8 a9 db ff ff       	call   f0100980 <check_va2pa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102dd7:	be 00 90 11 00       	mov    $0x119000,%esi
f0102ddc:	bf 00 80 bf df       	mov    $0xdfbf8000,%edi
f0102de1:	81 ef 00 10 11 f0    	sub    $0xf0111000,%edi
f0102de7:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0102dea:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0102ded:	e9 6f fa ff ff       	jmp    f0102861 <mem_init+0x15f7>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102df2:	89 f2                	mov    %esi,%edx
f0102df4:	89 d8                	mov    %ebx,%eax
f0102df6:	e8 85 db ff ff       	call   f0100980 <check_va2pa>
f0102dfb:	e9 cd f9 ff ff       	jmp    f01027cd <mem_init+0x1563>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102e00:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e06:	89 d8                	mov    %ebx,%eax
f0102e08:	e8 73 db ff ff       	call   f0100980 <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102e0d:	89 f2                	mov    %esi,%edx
f0102e0f:	e9 5a f9 ff ff       	jmp    f010276e <mem_init+0x1504>
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();

}
f0102e14:	83 c4 3c             	add    $0x3c,%esp
f0102e17:	5b                   	pop    %ebx
f0102e18:	5e                   	pop    %esi
f0102e19:	5f                   	pop    %edi
f0102e1a:	5d                   	pop    %ebp
f0102e1b:	c3                   	ret    

f0102e1c <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e1c:	55                   	push   %ebp
f0102e1d:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102e1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e24:	5d                   	pop    %ebp
f0102e25:	c3                   	ret    

f0102e26 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102e26:	55                   	push   %ebp
f0102e27:	89 e5                	mov    %esp,%ebp
f0102e29:	53                   	push   %ebx
f0102e2a:	83 ec 14             	sub    $0x14,%esp
f0102e2d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102e30:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e33:	83 c8 04             	or     $0x4,%eax
f0102e36:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e3a:	8b 45 10             	mov    0x10(%ebp),%eax
f0102e3d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102e41:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e44:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e48:	89 1c 24             	mov    %ebx,(%esp)
f0102e4b:	e8 cc ff ff ff       	call   f0102e1c <user_mem_check>
f0102e50:	85 c0                	test   %eax,%eax
f0102e52:	79 23                	jns    f0102e77 <user_mem_assert+0x51>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102e54:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102e5b:	00 
f0102e5c:	8b 43 48             	mov    0x48(%ebx),%eax
f0102e5f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e63:	c7 04 24 40 5b 10 f0 	movl   $0xf0105b40,(%esp)
f0102e6a:	e8 ab 07 00 00       	call   f010361a <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102e6f:	89 1c 24             	mov    %ebx,(%esp)
f0102e72:	e8 73 06 00 00       	call   f01034ea <env_destroy>
	}
}
f0102e77:	83 c4 14             	add    $0x14,%esp
f0102e7a:	5b                   	pop    %ebx
f0102e7b:	5d                   	pop    %ebp
f0102e7c:	c3                   	ret    
f0102e7d:	66 90                	xchg   %ax,%ax
f0102e7f:	90                   	nop

f0102e80 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102e80:	55                   	push   %ebp
f0102e81:	89 e5                	mov    %esp,%ebp
f0102e83:	57                   	push   %edi
f0102e84:	56                   	push   %esi
f0102e85:	53                   	push   %ebx
f0102e86:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	if(!len) /* If the len is zero panic immedatelly? or just return? */
f0102e89:	85 c9                	test   %ecx,%ecx
f0102e8b:	75 1c                	jne    f0102ea9 <region_alloc+0x29>
		panic("Allocation failed!\n");
f0102e8d:	c7 44 24 08 4c 5e 10 	movl   $0xf0105e4c,0x8(%esp)
f0102e94:	f0 
f0102e95:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
f0102e9c:	00 
f0102e9d:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f0102ea4:	e8 15 d2 ff ff       	call   f01000be <_panic>
f0102ea9:	89 c7                	mov    %eax,%edi
	void* up_lim = ROUNDUP(va + len, PGSIZE);
f0102eab:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102eb2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	va = ROUNDDOWN(va, PGSIZE);
f0102eb8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102ebe:	89 d3                	mov    %edx,%ebx
	
	struct Page *p;
	for(;va < up_lim; va += PGSIZE){
f0102ec0:	39 d6                	cmp    %edx,%esi
f0102ec2:	76 71                	jbe    f0102f35 <region_alloc+0xb5>
		if((p  = page_alloc(ALLOC_ZERO)) == NULL)
f0102ec4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0102ecb:	e8 1b e0 ff ff       	call   f0100eeb <page_alloc>
f0102ed0:	85 c0                	test   %eax,%eax
f0102ed2:	75 1c                	jne    f0102ef0 <region_alloc+0x70>
			panic("Allocation failed!\n");
f0102ed4:	c7 44 24 08 4c 5e 10 	movl   $0xf0105e4c,0x8(%esp)
f0102edb:	f0 
f0102edc:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f0102ee3:	00 
f0102ee4:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f0102eeb:	e8 ce d1 ff ff       	call   f01000be <_panic>
		if(page_insert(e->env_pgdir, p, va, PTE_U|PTE_W) < 0)
f0102ef0:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102ef7:	00 
f0102ef8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102efc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f00:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102f03:	89 04 24             	mov    %eax,(%esp)
f0102f06:	e8 b5 e2 ff ff       	call   f01011c0 <page_insert>
f0102f0b:	85 c0                	test   %eax,%eax
f0102f0d:	79 1c                	jns    f0102f2b <region_alloc+0xab>
			panic("Allocation failed!\n");
f0102f0f:	c7 44 24 08 4c 5e 10 	movl   $0xf0105e4c,0x8(%esp)
f0102f16:	f0 
f0102f17:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
f0102f1e:	00 
f0102f1f:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f0102f26:	e8 93 d1 ff ff       	call   f01000be <_panic>
		panic("Allocation failed!\n");
	void* up_lim = ROUNDUP(va + len, PGSIZE);
	va = ROUNDDOWN(va, PGSIZE);
	
	struct Page *p;
	for(;va < up_lim; va += PGSIZE){
f0102f2b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f31:	39 de                	cmp    %ebx,%esi
f0102f33:	77 8f                	ja     f0102ec4 <region_alloc+0x44>
			panic("Allocation failed!\n");
		if(page_insert(e->env_pgdir, p, va, PTE_U|PTE_W) < 0)
			panic("Allocation failed!\n");
	}

}
f0102f35:	83 c4 1c             	add    $0x1c,%esp
f0102f38:	5b                   	pop    %ebx
f0102f39:	5e                   	pop    %esi
f0102f3a:	5f                   	pop    %edi
f0102f3b:	5d                   	pop    %ebp
f0102f3c:	c3                   	ret    

f0102f3d <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102f3d:	55                   	push   %ebp
f0102f3e:	89 e5                	mov    %esp,%ebp
f0102f40:	8b 45 08             	mov    0x8(%ebp),%eax
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102f43:	85 c0                	test   %eax,%eax
f0102f45:	75 11                	jne    f0102f58 <envid2env+0x1b>
		*env_store = curenv;
f0102f47:	a1 04 d3 17 f0       	mov    0xf017d304,%eax
f0102f4c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102f4f:	89 02                	mov    %eax,(%edx)
		return 0;
f0102f51:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f56:	eb 60                	jmp    f0102fb8 <envid2env+0x7b>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102f58:	89 c2                	mov    %eax,%edx
f0102f5a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102f60:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102f63:	c1 e2 05             	shl    $0x5,%edx
f0102f66:	03 15 08 d3 17 f0    	add    0xf017d308,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102f6c:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0102f70:	74 05                	je     f0102f77 <envid2env+0x3a>
f0102f72:	39 42 48             	cmp    %eax,0x48(%edx)
f0102f75:	74 10                	je     f0102f87 <envid2env+0x4a>
		*env_store = 0;
f0102f77:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102f7a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0102f80:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102f85:	eb 31                	jmp    f0102fb8 <envid2env+0x7b>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102f87:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0102f8b:	74 21                	je     f0102fae <envid2env+0x71>
f0102f8d:	a1 04 d3 17 f0       	mov    0xf017d304,%eax
f0102f92:	39 c2                	cmp    %eax,%edx
f0102f94:	74 18                	je     f0102fae <envid2env+0x71>
f0102f96:	8b 48 48             	mov    0x48(%eax),%ecx
f0102f99:	39 4a 4c             	cmp    %ecx,0x4c(%edx)
f0102f9c:	74 10                	je     f0102fae <envid2env+0x71>
		*env_store = 0;
f0102f9e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fa1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102fa7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102fac:	eb 0a                	jmp    f0102fb8 <envid2env+0x7b>
	}

	*env_store = e;
f0102fae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102fb1:	89 11                	mov    %edx,(%ecx)
	return 0;
f0102fb3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102fb8:	5d                   	pop    %ebp
f0102fb9:	c3                   	ret    

f0102fba <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102fba:	55                   	push   %ebp
f0102fbb:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102fbd:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102fc2:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102fc5:	b8 23 00 00 00       	mov    $0x23,%eax
f0102fca:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102fcc:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102fce:	b0 10                	mov    $0x10,%al
f0102fd0:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102fd2:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102fd4:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102fd6:	ea dd 2f 10 f0 08 00 	ljmp   $0x8,$0xf0102fdd
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102fdd:	b0 00                	mov    $0x0,%al
f0102fdf:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102fe2:	5d                   	pop    %ebp
f0102fe3:	c3                   	ret    

f0102fe4 <env_init>:
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	size_t i;
	struct Env *cur_env = envs+ NENV - 1, *ptr;
f0102fe4:	8b 0d 08 d3 17 f0    	mov    0xf017d308,%ecx
f0102fea:	8d 81 a0 7f 01 00    	lea    0x17fa0(%ecx),%eax
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
f0102ff0:	8d 51 a0             	lea    -0x60(%ecx),%edx
	// Set up envs array
	// LAB 3: Your code here.
	size_t i;
	struct Env *cur_env = envs+ NENV - 1, *ptr;
	for(i = 0; i < NENV; i++){
		cur_env -> env_status = ENV_FREE;
f0102ff3:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		cur_env -> env_id = 0;
f0102ffa:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		ptr = cur_env;
		ptr++;
		cur_env--;
f0103001:	83 e8 60             	sub    $0x60,%eax
{
	// Set up envs array
	// LAB 3: Your code here.
	size_t i;
	struct Env *cur_env = envs+ NENV - 1, *ptr;
	for(i = 0; i < NENV; i++){
f0103004:	39 d0                	cmp    %edx,%eax
f0103006:	75 eb                	jne    f0102ff3 <env_init+0xf>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103008:	55                   	push   %ebp
f0103009:	89 e5                	mov    %esp,%ebp
		cur_env -> env_id = 0;
		ptr = cur_env;
		ptr++;
		cur_env--;
	}
	env_free_list = ptr - 1;
f010300b:	89 0d 0c d3 17 f0    	mov    %ecx,0xf017d30c
	// Per-CPU part of the initialization
	env_init_percpu();
f0103011:	e8 a4 ff ff ff       	call   f0102fba <env_init_percpu>
}
f0103016:	5d                   	pop    %ebp
f0103017:	c3                   	ret    

f0103018 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103018:	55                   	push   %ebp
f0103019:	89 e5                	mov    %esp,%ebp
f010301b:	56                   	push   %esi
f010301c:	53                   	push   %ebx
f010301d:	83 ec 10             	sub    $0x10,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103020:	8b 1d 0c d3 17 f0    	mov    0xf017d30c,%ebx
f0103026:	85 db                	test   %ebx,%ebx
f0103028:	0f 84 85 01 00 00    	je     f01031b3 <env_alloc+0x19b>
{
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010302e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103035:	e8 b1 de ff ff       	call   f0100eeb <page_alloc>
f010303a:	89 c6                	mov    %eax,%esi
f010303c:	85 c0                	test   %eax,%eax
f010303e:	0f 84 76 01 00 00    	je     f01031ba <env_alloc+0x1a2>
f0103044:	2b 05 ac df 17 f0    	sub    0xf017dfac,%eax
f010304a:	c1 f8 03             	sar    $0x3,%eax
f010304d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103050:	89 c2                	mov    %eax,%edx
f0103052:	c1 ea 0c             	shr    $0xc,%edx
f0103055:	3b 15 a4 df 17 f0    	cmp    0xf017dfa4,%edx
f010305b:	72 20                	jb     f010307d <env_alloc+0x65>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010305d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103061:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f0103068:	f0 
f0103069:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103070:	00 
f0103071:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0103078:	e8 41 d0 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f010307d:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	/* e->env_pgdir is a pte_t* */
	e -> env_pgdir = (pte_t *)page2kva(p);
f0103082:	89 43 5c             	mov    %eax,0x5c(%ebx)

	memmove(e -> env_pgdir , kern_pgdir, PGSIZE);
f0103085:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010308c:	00 
f010308d:	8b 15 a8 df 17 f0    	mov    0xf017dfa8,%edx
f0103093:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103097:	89 04 24             	mov    %eax,(%esp)
f010309a:	e8 b4 19 00 00       	call   f0104a53 <memmove>
	memset(e -> env_pgdir, 0 , PDX(UTOP)*sizeof(pde_t));
f010309f:	c7 44 24 08 ec 0e 00 	movl   $0xeec,0x8(%esp)
f01030a6:	00 
f01030a7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01030ae:	00 
f01030af:	8b 43 5c             	mov    0x5c(%ebx),%eax
f01030b2:	89 04 24             	mov    %eax,(%esp)
f01030b5:	e8 3b 19 00 00       	call   f01049f5 <memset>

	p -> pp_ref++;
f01030ba:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01030bf:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030c2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030c7:	77 20                	ja     f01030e9 <env_alloc+0xd1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030cd:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f01030d4:	f0 
f01030d5:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
f01030dc:	00 
f01030dd:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f01030e4:	e8 d5 cf ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01030e9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01030ef:	83 ca 05             	or     $0x5,%edx
f01030f2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01030f8:	8b 43 48             	mov    0x48(%ebx),%eax
f01030fb:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103100:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103105:	ba 00 10 00 00       	mov    $0x1000,%edx
f010310a:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010310d:	89 da                	mov    %ebx,%edx
f010310f:	2b 15 08 d3 17 f0    	sub    0xf017d308,%edx
f0103115:	c1 fa 05             	sar    $0x5,%edx
f0103118:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010311e:	09 d0                	or     %edx,%eax
f0103120:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103123:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103126:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103129:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103130:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f0103137:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010313e:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103145:	00 
f0103146:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010314d:	00 
f010314e:	89 1c 24             	mov    %ebx,(%esp)
f0103151:	e8 9f 18 00 00       	call   f01049f5 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103156:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010315c:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103162:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103168:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010316f:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103175:	8b 43 44             	mov    0x44(%ebx),%eax
f0103178:	a3 0c d3 17 f0       	mov    %eax,0xf017d30c
	*newenv_store = e;
f010317d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103180:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103182:	8b 53 48             	mov    0x48(%ebx),%edx
f0103185:	a1 04 d3 17 f0       	mov    0xf017d304,%eax
f010318a:	85 c0                	test   %eax,%eax
f010318c:	74 05                	je     f0103193 <env_alloc+0x17b>
f010318e:	8b 40 48             	mov    0x48(%eax),%eax
f0103191:	eb 05                	jmp    f0103198 <env_alloc+0x180>
f0103193:	b8 00 00 00 00       	mov    $0x0,%eax
f0103198:	89 54 24 08          	mov    %edx,0x8(%esp)
f010319c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031a0:	c7 04 24 6b 5e 10 f0 	movl   $0xf0105e6b,(%esp)
f01031a7:	e8 6e 04 00 00       	call   f010361a <cprintf>
	return 0;
f01031ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01031b1:	eb 0c                	jmp    f01031bf <env_alloc+0x1a7>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01031b3:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01031b8:	eb 05                	jmp    f01031bf <env_alloc+0x1a7>
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01031ba:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01031bf:	83 c4 10             	add    $0x10,%esp
f01031c2:	5b                   	pop    %ebx
f01031c3:	5e                   	pop    %esi
f01031c4:	5d                   	pop    %ebp
f01031c5:	c3                   	ret    

f01031c6 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size, enum EnvType type)
{
f01031c6:	55                   	push   %ebp
f01031c7:	89 e5                	mov    %esp,%ebp
f01031c9:	57                   	push   %edi
f01031ca:	56                   	push   %esi
f01031cb:	53                   	push   %ebx
f01031cc:	83 ec 3c             	sub    $0x3c,%esp
f01031cf:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;

	if((r = env_alloc(&e, 0)) < 0)
f01031d2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01031d9:	00 
f01031da:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01031dd:	89 04 24             	mov    %eax,(%esp)
f01031e0:	e8 33 fe ff ff       	call   f0103018 <env_alloc>
f01031e5:	85 c0                	test   %eax,%eax
f01031e7:	79 20                	jns    f0103209 <env_create+0x43>
		panic("env alloc failed! %e\n",r);
f01031e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031ed:	c7 44 24 08 80 5e 10 	movl   $0xf0105e80,0x8(%esp)
f01031f4:	f0 
f01031f5:	c7 44 24 04 98 01 00 	movl   $0x198,0x4(%esp)
f01031fc:	00 
f01031fd:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f0103204:	e8 b5 ce ff ff       	call   f01000be <_panic>
	/* load_icode(struct Env *e, uint8_t *binary, size_t size) */
	load_icode(e, binary, size);
f0103209:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010320c:	89 45 d4             	mov    %eax,-0x2c(%ebp)

static __inline uint32_t
rcr3(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr3,%0" : "=r" (val));
f010320f:	0f 20 da             	mov    %cr3,%edx
f0103212:	89 55 d0             	mov    %edx,-0x30(%ebp)
	struct Proghdr *ph, *eph; /* see inc/elf.h */
	struct Elf *ELFHDR = (struct Elf *)binary;
	uint32_t cr3 = rcr3();

	/* just copy from boot/main.c */
	if (ELFHDR->e_magic != ELF_MAGIC)
f0103215:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010321b:	74 1c                	je     f0103239 <env_create+0x73>
		panic("Invalid ELF!\n");
f010321d:	c7 44 24 08 96 5e 10 	movl   $0xf0105e96,0x8(%esp)
f0103224:	f0 
f0103225:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f010322c:	00 
f010322d:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f0103234:	e8 85 ce ff ff       	call   f01000be <_panic>
	lcr3(PADDR(e -> env_pgdir));
f0103239:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010323c:	8b 42 5c             	mov    0x5c(%edx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010323f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103244:	77 20                	ja     f0103266 <env_create+0xa0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103246:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010324a:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f0103251:	f0 
f0103252:	c7 44 24 04 6a 01 00 	movl   $0x16a,0x4(%esp)
f0103259:	00 
f010325a:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f0103261:	e8 58 ce ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103266:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010326b:	0f 22 d8             	mov    %eax,%cr3
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f010326e:	89 fb                	mov    %edi,%ebx
f0103270:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0103273:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103277:	c1 e6 05             	shl    $0x5,%esi
f010327a:	01 de                	add    %ebx,%esi

	for (; ph < eph; ph++){
f010327c:	39 f3                	cmp    %esi,%ebx
f010327e:	73 4f                	jae    f01032cf <env_create+0x109>
		// p_pa is the load address of this segment (as well
		// as the physical address)
		if( ph->p_type == ELF_PROG_LOAD ){
f0103280:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103283:	75 43                	jne    f01032c8 <env_create+0x102>
			/* alloc p_memsz physical memory for e*/
			region_alloc(e, (void *)ph -> p_va, ph -> p_memsz); 
f0103285:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103288:	8b 53 08             	mov    0x8(%ebx),%edx
f010328b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010328e:	e8 ed fb ff ff       	call   f0102e80 <region_alloc>
			/* set zero filled */
			//panic("%x", ph);
			memset((void *)ph->p_va, 0x0 , ph->p_memsz);
f0103293:	8b 43 14             	mov    0x14(%ebx),%eax
f0103296:	89 44 24 08          	mov    %eax,0x8(%esp)
f010329a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01032a1:	00 
f01032a2:	8b 43 08             	mov    0x8(%ebx),%eax
f01032a5:	89 04 24             	mov    %eax,(%esp)
f01032a8:	e8 48 17 00 00       	call   f01049f5 <memset>
			/* inc/string.h : void * memmove(void *dst, const void *src, size_t len); */
			memmove((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f01032ad:	8b 43 10             	mov    0x10(%ebx),%eax
f01032b0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01032b4:	89 f8                	mov    %edi,%eax
f01032b6:	03 43 04             	add    0x4(%ebx),%eax
f01032b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032bd:	8b 43 08             	mov    0x8(%ebx),%eax
f01032c0:	89 04 24             	mov    %eax,(%esp)
f01032c3:	e8 8b 17 00 00       	call   f0104a53 <memmove>
		panic("Invalid ELF!\n");
	lcr3(PADDR(e -> env_pgdir));
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;

	for (; ph < eph; ph++){
f01032c8:	83 c3 20             	add    $0x20,%ebx
f01032cb:	39 de                	cmp    %ebx,%esi
f01032cd:	77 b1                	ja     f0103280 <env_create+0xba>
		}

	}
	//((void (*)(void)) (ELFHDR->e_entry))();

	e -> env_tf.tf_eip = ELFHDR -> e_entry;
f01032cf:	8b 47 18             	mov    0x18(%edi),%eax
f01032d2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01032d5:	89 42 30             	mov    %eax,0x30(%edx)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
f01032d8:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01032dd:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01032e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032e5:	e8 96 fb ff ff       	call   f0102e80 <region_alloc>
f01032ea:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01032ed:	0f 22 d8             	mov    %eax,%cr3

	if((r = env_alloc(&e, 0)) < 0)
		panic("env alloc failed! %e\n",r);
	/* load_icode(struct Env *e, uint8_t *binary, size_t size) */
	load_icode(e, binary, size);
	e -> env_type = type;
f01032f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032f3:	8b 55 10             	mov    0x10(%ebp),%edx
f01032f6:	89 50 50             	mov    %edx,0x50(%eax)
}
f01032f9:	83 c4 3c             	add    $0x3c,%esp
f01032fc:	5b                   	pop    %ebx
f01032fd:	5e                   	pop    %esi
f01032fe:	5f                   	pop    %edi
f01032ff:	5d                   	pop    %ebp
f0103300:	c3                   	ret    

f0103301 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103301:	55                   	push   %ebp
f0103302:	89 e5                	mov    %esp,%ebp
f0103304:	57                   	push   %edi
f0103305:	56                   	push   %esi
f0103306:	53                   	push   %ebx
f0103307:	83 ec 2c             	sub    $0x2c,%esp
f010330a:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010330d:	a1 04 d3 17 f0       	mov    0xf017d304,%eax
f0103312:	39 c7                	cmp    %eax,%edi
f0103314:	75 37                	jne    f010334d <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f0103316:	8b 15 a8 df 17 f0    	mov    0xf017dfa8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010331c:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103322:	77 20                	ja     f0103344 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103324:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103328:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f010332f:	f0 
f0103330:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
f0103337:	00 
f0103338:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f010333f:	e8 7a cd ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103344:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010334a:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010334d:	8b 57 48             	mov    0x48(%edi),%edx
f0103350:	85 c0                	test   %eax,%eax
f0103352:	74 05                	je     f0103359 <env_free+0x58>
f0103354:	8b 40 48             	mov    0x48(%eax),%eax
f0103357:	eb 05                	jmp    f010335e <env_free+0x5d>
f0103359:	b8 00 00 00 00       	mov    $0x0,%eax
f010335e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103362:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103366:	c7 04 24 a4 5e 10 f0 	movl   $0xf0105ea4,(%esp)
f010336d:	e8 a8 02 00 00       	call   f010361a <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103372:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
f0103379:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010337c:	c1 e0 02             	shl    $0x2,%eax
f010337f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103382:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103385:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103388:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010338b:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103391:	0f 84 b7 00 00 00    	je     f010344e <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103397:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010339d:	89 f0                	mov    %esi,%eax
f010339f:	c1 e8 0c             	shr    $0xc,%eax
f01033a2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01033a5:	3b 05 a4 df 17 f0    	cmp    0xf017dfa4,%eax
f01033ab:	72 20                	jb     f01033cd <env_free+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01033ad:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01033b1:	c7 44 24 08 24 54 10 	movl   $0xf0105424,0x8(%esp)
f01033b8:	f0 
f01033b9:	c7 44 24 04 bb 01 00 	movl   $0x1bb,0x4(%esp)
f01033c0:	00 
f01033c1:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f01033c8:	e8 f1 cc ff ff       	call   f01000be <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01033cd:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01033d0:	c1 e2 16             	shl    $0x16,%edx
f01033d3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01033d6:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01033db:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01033e2:	01 
f01033e3:	74 17                	je     f01033fc <env_free+0xfb>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01033e5:	89 d8                	mov    %ebx,%eax
f01033e7:	c1 e0 0c             	shl    $0xc,%eax
f01033ea:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01033ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033f1:	8b 47 5c             	mov    0x5c(%edi),%eax
f01033f4:	89 04 24             	mov    %eax,(%esp)
f01033f7:	e8 74 dd ff ff       	call   f0101170 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01033fc:	83 c3 01             	add    $0x1,%ebx
f01033ff:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103405:	75 d4                	jne    f01033db <env_free+0xda>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103407:	8b 47 5c             	mov    0x5c(%edi),%eax
f010340a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010340d:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103414:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103417:	3b 05 a4 df 17 f0    	cmp    0xf017dfa4,%eax
f010341d:	72 1c                	jb     f010343b <env_free+0x13a>
		panic("pa2page called with invalid pa");
f010341f:	c7 44 24 08 30 55 10 	movl   $0xf0105530,0x8(%esp)
f0103426:	f0 
f0103427:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010342e:	00 
f010342f:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f0103436:	e8 83 cc ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f010343b:	a1 ac df 17 f0       	mov    0xf017dfac,%eax
f0103440:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103443:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103446:	89 04 24             	mov    %eax,(%esp)
f0103449:	e8 3d db ff ff       	call   f0100f8b <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010344e:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103452:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103459:	0f 85 1a ff ff ff    	jne    f0103379 <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010345f:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103462:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103467:	77 20                	ja     f0103489 <env_free+0x188>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103469:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010346d:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f0103474:	f0 
f0103475:	c7 44 24 04 c9 01 00 	movl   $0x1c9,0x4(%esp)
f010347c:	00 
f010347d:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f0103484:	e8 35 cc ff ff       	call   f01000be <_panic>
	e->env_pgdir = 0;
f0103489:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103490:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103495:	c1 e8 0c             	shr    $0xc,%eax
f0103498:	3b 05 a4 df 17 f0    	cmp    0xf017dfa4,%eax
f010349e:	72 1c                	jb     f01034bc <env_free+0x1bb>
		panic("pa2page called with invalid pa");
f01034a0:	c7 44 24 08 30 55 10 	movl   $0xf0105530,0x8(%esp)
f01034a7:	f0 
f01034a8:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01034af:	00 
f01034b0:	c7 04 24 96 5b 10 f0 	movl   $0xf0105b96,(%esp)
f01034b7:	e8 02 cc ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f01034bc:	8b 15 ac df 17 f0    	mov    0xf017dfac,%edx
f01034c2:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f01034c5:	89 04 24             	mov    %eax,(%esp)
f01034c8:	e8 be da ff ff       	call   f0100f8b <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01034cd:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01034d4:	a1 0c d3 17 f0       	mov    0xf017d30c,%eax
f01034d9:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01034dc:	89 3d 0c d3 17 f0    	mov    %edi,0xf017d30c
}
f01034e2:	83 c4 2c             	add    $0x2c,%esp
f01034e5:	5b                   	pop    %ebx
f01034e6:	5e                   	pop    %esi
f01034e7:	5f                   	pop    %edi
f01034e8:	5d                   	pop    %ebp
f01034e9:	c3                   	ret    

f01034ea <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01034ea:	55                   	push   %ebp
f01034eb:	89 e5                	mov    %esp,%ebp
f01034ed:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f01034f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01034f3:	89 04 24             	mov    %eax,(%esp)
f01034f6:	e8 06 fe ff ff       	call   f0103301 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01034fb:	c7 04 24 c8 5e 10 f0 	movl   $0xf0105ec8,(%esp)
f0103502:	e8 13 01 00 00       	call   f010361a <cprintf>
	while (1)
		monitor(NULL);
f0103507:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010350e:	e8 0f d3 ff ff       	call   f0100822 <monitor>
f0103513:	eb f2                	jmp    f0103507 <env_destroy+0x1d>

f0103515 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103515:	55                   	push   %ebp
f0103516:	89 e5                	mov    %esp,%ebp
f0103518:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f010351b:	8b 65 08             	mov    0x8(%ebp),%esp
f010351e:	61                   	popa   
f010351f:	07                   	pop    %es
f0103520:	1f                   	pop    %ds
f0103521:	83 c4 08             	add    $0x8,%esp
f0103524:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103525:	c7 44 24 08 ba 5e 10 	movl   $0xf0105eba,0x8(%esp)
f010352c:	f0 
f010352d:	c7 44 24 04 f1 01 00 	movl   $0x1f1,0x4(%esp)
f0103534:	00 
f0103535:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f010353c:	e8 7d cb ff ff       	call   f01000be <_panic>

f0103541 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103541:	55                   	push   %ebp
f0103542:	89 e5                	mov    %esp,%ebp
f0103544:	83 ec 18             	sub    $0x18,%esp
f0103547:	8b 45 08             	mov    0x8(%ebp),%eax
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	if(curenv != NULL)
f010354a:	8b 15 04 d3 17 f0    	mov    0xf017d304,%edx
f0103550:	85 d2                	test   %edx,%edx
f0103552:	74 07                	je     f010355b <env_run+0x1a>
		curenv -> env_status = ENV_RUNNABLE;
f0103554:	c7 42 54 01 00 00 00 	movl   $0x1,0x54(%edx)

	curenv = e;
f010355b:	a3 04 d3 17 f0       	mov    %eax,0xf017d304
	curenv -> env_status = ENV_RUNNING;
f0103560:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv -> env_runs++;
f0103567:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv -> env_pgdir));
f010356b:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010356e:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103574:	77 20                	ja     f0103596 <env_run+0x55>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103576:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010357a:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f0103581:	f0 
f0103582:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
f0103589:	00 
f010358a:	c7 04 24 60 5e 10 f0 	movl   $0xf0105e60,(%esp)
f0103591:	e8 28 cb ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103596:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010359c:	0f 22 da             	mov    %edx,%cr3

	env_pop_tf(&(e -> env_tf));
f010359f:	89 04 24             	mov    %eax,(%esp)
f01035a2:	e8 6e ff ff ff       	call   f0103515 <env_pop_tf>
f01035a7:	90                   	nop

f01035a8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01035a8:	55                   	push   %ebp
f01035a9:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01035ab:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035af:	ba 70 00 00 00       	mov    $0x70,%edx
f01035b4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01035b5:	b2 71                	mov    $0x71,%dl
f01035b7:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01035b8:	0f b6 c0             	movzbl %al,%eax
}
f01035bb:	5d                   	pop    %ebp
f01035bc:	c3                   	ret    

f01035bd <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01035bd:	55                   	push   %ebp
f01035be:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01035c0:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035c4:	ba 70 00 00 00       	mov    $0x70,%edx
f01035c9:	ee                   	out    %al,(%dx)
f01035ca:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f01035ce:	b2 71                	mov    $0x71,%dl
f01035d0:	ee                   	out    %al,(%dx)
f01035d1:	5d                   	pop    %ebp
f01035d2:	c3                   	ret    
f01035d3:	90                   	nop

f01035d4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01035d4:	55                   	push   %ebp
f01035d5:	89 e5                	mov    %esp,%ebp
f01035d7:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01035da:	8b 45 08             	mov    0x8(%ebp),%eax
f01035dd:	89 04 24             	mov    %eax,(%esp)
f01035e0:	e8 47 d0 ff ff       	call   f010062c <cputchar>
	*cnt++;
}
f01035e5:	c9                   	leave  
f01035e6:	c3                   	ret    

f01035e7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01035e7:	55                   	push   %ebp
f01035e8:	89 e5                	mov    %esp,%ebp
f01035ea:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01035ed:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01035f4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035f7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01035fe:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103602:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103605:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103609:	c7 04 24 d4 35 10 f0 	movl   $0xf01035d4,(%esp)
f0103610:	e8 7d 0c 00 00       	call   f0104292 <vprintfmt>
	return cnt;
}
f0103615:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103618:	c9                   	leave  
f0103619:	c3                   	ret    

f010361a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010361a:	55                   	push   %ebp
f010361b:	89 e5                	mov    %esp,%ebp
f010361d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103620:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103623:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103627:	8b 45 08             	mov    0x8(%ebp),%eax
f010362a:	89 04 24             	mov    %eax,(%esp)
f010362d:	e8 b5 ff ff ff       	call   f01035e7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103632:	c9                   	leave  
f0103633:	c3                   	ret    

f0103634 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103634:	55                   	push   %ebp
f0103635:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103637:	c7 05 24 db 17 f0 00 	movl   $0xefc00000,0xf017db24
f010363e:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f0103641:	66 c7 05 28 db 17 f0 	movw   $0x10,0xf017db28
f0103648:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f010364a:	66 c7 05 48 b3 11 f0 	movw   $0x68,0xf011b348
f0103651:	68 00 
f0103653:	b8 20 db 17 f0       	mov    $0xf017db20,%eax
f0103658:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f010365e:	89 c2                	mov    %eax,%edx
f0103660:	c1 ea 10             	shr    $0x10,%edx
f0103663:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0103669:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0103670:	c1 e8 18             	shr    $0x18,%eax
f0103673:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103678:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010367f:	b8 28 00 00 00       	mov    $0x28,%eax
f0103684:	0f 00 d8             	ltr    %ax
}  

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103687:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f010368c:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010368f:	5d                   	pop    %ebp
f0103690:	c3                   	ret    

f0103691 <trap_init>:
}


void
trap_init(void)
{
f0103691:	55                   	push   %ebp
f0103692:	89 e5                	mov    %esp,%ebp
	extern void Alignment_Check();
	extern void Machine_Check();
	extern void SIMD_Floating_Point_Exception();

	/* SETGATE(Gatedesc, istrap[1/0], sel, off, dpl) -- inc/mmu.h*/
	SETGATE(idt[T_DIVIDE] ,0, GD_KT, Divide_error, 0);
f0103694:	b8 24 3d 10 f0       	mov    $0xf0103d24,%eax
f0103699:	66 a3 20 d3 17 f0    	mov    %ax,0xf017d320
f010369f:	66 c7 05 22 d3 17 f0 	movw   $0x8,0xf017d322
f01036a6:	08 00 
f01036a8:	c6 05 24 d3 17 f0 00 	movb   $0x0,0xf017d324
f01036af:	c6 05 25 d3 17 f0 8e 	movb   $0x8e,0xf017d325
f01036b6:	c1 e8 10             	shr    $0x10,%eax
f01036b9:	66 a3 26 d3 17 f0    	mov    %ax,0xf017d326
	SETGATE(idt[T_DEBUG] ,0, GD_KT, Debug, 0);
f01036bf:	b8 2a 3d 10 f0       	mov    $0xf0103d2a,%eax
f01036c4:	66 a3 28 d3 17 f0    	mov    %ax,0xf017d328
f01036ca:	66 c7 05 2a d3 17 f0 	movw   $0x8,0xf017d32a
f01036d1:	08 00 
f01036d3:	c6 05 2c d3 17 f0 00 	movb   $0x0,0xf017d32c
f01036da:	c6 05 2d d3 17 f0 8e 	movb   $0x8e,0xf017d32d
f01036e1:	c1 e8 10             	shr    $0x10,%eax
f01036e4:	66 a3 2e d3 17 f0    	mov    %ax,0xf017d32e
	SETGATE(idt[T_NMI] ,0, GD_KT, Non_Maskable_Interrupt, 0);
f01036ea:	b8 30 3d 10 f0       	mov    $0xf0103d30,%eax
f01036ef:	66 a3 30 d3 17 f0    	mov    %ax,0xf017d330
f01036f5:	66 c7 05 32 d3 17 f0 	movw   $0x8,0xf017d332
f01036fc:	08 00 
f01036fe:	c6 05 34 d3 17 f0 00 	movb   $0x0,0xf017d334
f0103705:	c6 05 35 d3 17 f0 8e 	movb   $0x8e,0xf017d335
f010370c:	c1 e8 10             	shr    $0x10,%eax
f010370f:	66 a3 36 d3 17 f0    	mov    %ax,0xf017d336
	SETGATE(idt[T_BRKPT] ,0, GD_KT, Breakpoint, 0);
f0103715:	b8 36 3d 10 f0       	mov    $0xf0103d36,%eax
f010371a:	66 a3 38 d3 17 f0    	mov    %ax,0xf017d338
f0103720:	66 c7 05 3a d3 17 f0 	movw   $0x8,0xf017d33a
f0103727:	08 00 
f0103729:	c6 05 3c d3 17 f0 00 	movb   $0x0,0xf017d33c
f0103730:	c6 05 3d d3 17 f0 8e 	movb   $0x8e,0xf017d33d
f0103737:	c1 e8 10             	shr    $0x10,%eax
f010373a:	66 a3 3e d3 17 f0    	mov    %ax,0xf017d33e
	SETGATE(idt[T_OFLOW] ,0, GD_KT, Overflow, 0);
f0103740:	b8 3c 3d 10 f0       	mov    $0xf0103d3c,%eax
f0103745:	66 a3 40 d3 17 f0    	mov    %ax,0xf017d340
f010374b:	66 c7 05 42 d3 17 f0 	movw   $0x8,0xf017d342
f0103752:	08 00 
f0103754:	c6 05 44 d3 17 f0 00 	movb   $0x0,0xf017d344
f010375b:	c6 05 45 d3 17 f0 8e 	movb   $0x8e,0xf017d345
f0103762:	c1 e8 10             	shr    $0x10,%eax
f0103765:	66 a3 46 d3 17 f0    	mov    %ax,0xf017d346
	SETGATE(idt[T_BOUND] ,0, GD_KT, BOUND_Range_Exceeded, 0);
f010376b:	b8 42 3d 10 f0       	mov    $0xf0103d42,%eax
f0103770:	66 a3 48 d3 17 f0    	mov    %ax,0xf017d348
f0103776:	66 c7 05 4a d3 17 f0 	movw   $0x8,0xf017d34a
f010377d:	08 00 
f010377f:	c6 05 4c d3 17 f0 00 	movb   $0x0,0xf017d34c
f0103786:	c6 05 4d d3 17 f0 8e 	movb   $0x8e,0xf017d34d
f010378d:	c1 e8 10             	shr    $0x10,%eax
f0103790:	66 a3 4e d3 17 f0    	mov    %ax,0xf017d34e
	SETGATE(idt[T_ILLOP] ,0, GD_KT, Invalid_Opcode, 0);
f0103796:	b8 48 3d 10 f0       	mov    $0xf0103d48,%eax
f010379b:	66 a3 50 d3 17 f0    	mov    %ax,0xf017d350
f01037a1:	66 c7 05 52 d3 17 f0 	movw   $0x8,0xf017d352
f01037a8:	08 00 
f01037aa:	c6 05 54 d3 17 f0 00 	movb   $0x0,0xf017d354
f01037b1:	c6 05 55 d3 17 f0 8e 	movb   $0x8e,0xf017d355
f01037b8:	c1 e8 10             	shr    $0x10,%eax
f01037bb:	66 a3 56 d3 17 f0    	mov    %ax,0xf017d356
	SETGATE(idt[T_DEVICE] ,0, GD_KT, Device_Not_Available, 0);
f01037c1:	b8 4e 3d 10 f0       	mov    $0xf0103d4e,%eax
f01037c6:	66 a3 58 d3 17 f0    	mov    %ax,0xf017d358
f01037cc:	66 c7 05 5a d3 17 f0 	movw   $0x8,0xf017d35a
f01037d3:	08 00 
f01037d5:	c6 05 5c d3 17 f0 00 	movb   $0x0,0xf017d35c
f01037dc:	c6 05 5d d3 17 f0 8e 	movb   $0x8e,0xf017d35d
f01037e3:	c1 e8 10             	shr    $0x10,%eax
f01037e6:	66 a3 5e d3 17 f0    	mov    %ax,0xf017d35e
	SETGATE(idt[T_DBLFLT] ,0, GD_KT, Double_Fault, 0);
f01037ec:	b8 54 3d 10 f0       	mov    $0xf0103d54,%eax
f01037f1:	66 a3 60 d3 17 f0    	mov    %ax,0xf017d360
f01037f7:	66 c7 05 62 d3 17 f0 	movw   $0x8,0xf017d362
f01037fe:	08 00 
f0103800:	c6 05 64 d3 17 f0 00 	movb   $0x0,0xf017d364
f0103807:	c6 05 65 d3 17 f0 8e 	movb   $0x8e,0xf017d365
f010380e:	c1 e8 10             	shr    $0x10,%eax
f0103811:	66 a3 66 d3 17 f0    	mov    %ax,0xf017d366
	SETGATE(idt[T_TSS] ,0, GD_KT, Invalid_TSS, 0);
f0103817:	b8 58 3d 10 f0       	mov    $0xf0103d58,%eax
f010381c:	66 a3 70 d3 17 f0    	mov    %ax,0xf017d370
f0103822:	66 c7 05 72 d3 17 f0 	movw   $0x8,0xf017d372
f0103829:	08 00 
f010382b:	c6 05 74 d3 17 f0 00 	movb   $0x0,0xf017d374
f0103832:	c6 05 75 d3 17 f0 8e 	movb   $0x8e,0xf017d375
f0103839:	c1 e8 10             	shr    $0x10,%eax
f010383c:	66 a3 76 d3 17 f0    	mov    %ax,0xf017d376
	SETGATE(idt[T_SEGNP] ,0, GD_KT, Segment_Not_Present, 0);
f0103842:	b8 5c 3d 10 f0       	mov    $0xf0103d5c,%eax
f0103847:	66 a3 78 d3 17 f0    	mov    %ax,0xf017d378
f010384d:	66 c7 05 7a d3 17 f0 	movw   $0x8,0xf017d37a
f0103854:	08 00 
f0103856:	c6 05 7c d3 17 f0 00 	movb   $0x0,0xf017d37c
f010385d:	c6 05 7d d3 17 f0 8e 	movb   $0x8e,0xf017d37d
f0103864:	c1 e8 10             	shr    $0x10,%eax
f0103867:	66 a3 7e d3 17 f0    	mov    %ax,0xf017d37e
	SETGATE(idt[T_STACK] ,0, GD_KT, Stack_Fault, 0);
f010386d:	b8 60 3d 10 f0       	mov    $0xf0103d60,%eax
f0103872:	66 a3 80 d3 17 f0    	mov    %ax,0xf017d380
f0103878:	66 c7 05 82 d3 17 f0 	movw   $0x8,0xf017d382
f010387f:	08 00 
f0103881:	c6 05 84 d3 17 f0 00 	movb   $0x0,0xf017d384
f0103888:	c6 05 85 d3 17 f0 8e 	movb   $0x8e,0xf017d385
f010388f:	c1 e8 10             	shr    $0x10,%eax
f0103892:	66 a3 86 d3 17 f0    	mov    %ax,0xf017d386
	SETGATE(idt[T_GPFLT] ,0, GD_KT, General_Protection, 0);
f0103898:	b8 64 3d 10 f0       	mov    $0xf0103d64,%eax
f010389d:	66 a3 88 d3 17 f0    	mov    %ax,0xf017d388
f01038a3:	66 c7 05 8a d3 17 f0 	movw   $0x8,0xf017d38a
f01038aa:	08 00 
f01038ac:	c6 05 8c d3 17 f0 00 	movb   $0x0,0xf017d38c
f01038b3:	c6 05 8d d3 17 f0 8e 	movb   $0x8e,0xf017d38d
f01038ba:	c1 e8 10             	shr    $0x10,%eax
f01038bd:	66 a3 8e d3 17 f0    	mov    %ax,0xf017d38e
	SETGATE(idt[T_PGFLT] ,0, GD_KT, Page_Fault, 0);
f01038c3:	b8 68 3d 10 f0       	mov    $0xf0103d68,%eax
f01038c8:	66 a3 90 d3 17 f0    	mov    %ax,0xf017d390
f01038ce:	66 c7 05 92 d3 17 f0 	movw   $0x8,0xf017d392
f01038d5:	08 00 
f01038d7:	c6 05 94 d3 17 f0 00 	movb   $0x0,0xf017d394
f01038de:	c6 05 95 d3 17 f0 8e 	movb   $0x8e,0xf017d395
f01038e5:	c1 e8 10             	shr    $0x10,%eax
f01038e8:	66 a3 96 d3 17 f0    	mov    %ax,0xf017d396
	SETGATE(idt[T_FPERR] ,0, GD_KT, x87_FPU_Floating_Point_Error, 0);
f01038ee:	b8 6c 3d 10 f0       	mov    $0xf0103d6c,%eax
f01038f3:	66 a3 a0 d3 17 f0    	mov    %ax,0xf017d3a0
f01038f9:	66 c7 05 a2 d3 17 f0 	movw   $0x8,0xf017d3a2
f0103900:	08 00 
f0103902:	c6 05 a4 d3 17 f0 00 	movb   $0x0,0xf017d3a4
f0103909:	c6 05 a5 d3 17 f0 8e 	movb   $0x8e,0xf017d3a5
f0103910:	c1 e8 10             	shr    $0x10,%eax
f0103913:	66 a3 a6 d3 17 f0    	mov    %ax,0xf017d3a6
	SETGATE(idt[T_ALIGN] ,0, GD_KT, Alignment_Check, 0);
f0103919:	b8 72 3d 10 f0       	mov    $0xf0103d72,%eax
f010391e:	66 a3 a8 d3 17 f0    	mov    %ax,0xf017d3a8
f0103924:	66 c7 05 aa d3 17 f0 	movw   $0x8,0xf017d3aa
f010392b:	08 00 
f010392d:	c6 05 ac d3 17 f0 00 	movb   $0x0,0xf017d3ac
f0103934:	c6 05 ad d3 17 f0 8e 	movb   $0x8e,0xf017d3ad
f010393b:	c1 e8 10             	shr    $0x10,%eax
f010393e:	66 a3 ae d3 17 f0    	mov    %ax,0xf017d3ae
	SETGATE(idt[T_MCHK] ,0, GD_KT, Machine_Check, 0);
f0103944:	b8 78 3d 10 f0       	mov    $0xf0103d78,%eax
f0103949:	66 a3 b0 d3 17 f0    	mov    %ax,0xf017d3b0
f010394f:	66 c7 05 b2 d3 17 f0 	movw   $0x8,0xf017d3b2
f0103956:	08 00 
f0103958:	c6 05 b4 d3 17 f0 00 	movb   $0x0,0xf017d3b4
f010395f:	c6 05 b5 d3 17 f0 8e 	movb   $0x8e,0xf017d3b5
f0103966:	c1 e8 10             	shr    $0x10,%eax
f0103969:	66 a3 b6 d3 17 f0    	mov    %ax,0xf017d3b6
	SETGATE(idt[T_SIMDERR] ,0, GD_KT, SIMD_Floating_Point_Exception, 0);
f010396f:	b8 7e 3d 10 f0       	mov    $0xf0103d7e,%eax
f0103974:	66 a3 b8 d3 17 f0    	mov    %ax,0xf017d3b8
f010397a:	66 c7 05 ba d3 17 f0 	movw   $0x8,0xf017d3ba
f0103981:	08 00 
f0103983:	c6 05 bc d3 17 f0 00 	movb   $0x0,0xf017d3bc
f010398a:	c6 05 bd d3 17 f0 8e 	movb   $0x8e,0xf017d3bd
f0103991:	c1 e8 10             	shr    $0x10,%eax
f0103994:	66 a3 be d3 17 f0    	mov    %ax,0xf017d3be


	// Per-CPU setup 
	trap_init_percpu();
f010399a:	e8 95 fc ff ff       	call   f0103634 <trap_init_percpu>
}
f010399f:	5d                   	pop    %ebp
f01039a0:	c3                   	ret    

f01039a1 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01039a1:	55                   	push   %ebp
f01039a2:	89 e5                	mov    %esp,%ebp
f01039a4:	53                   	push   %ebx
f01039a5:	83 ec 14             	sub    $0x14,%esp
f01039a8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039ab:	8b 03                	mov    (%ebx),%eax
f01039ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039b1:	c7 04 24 fe 5e 10 f0 	movl   $0xf0105efe,(%esp)
f01039b8:	e8 5d fc ff ff       	call   f010361a <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039bd:	8b 43 04             	mov    0x4(%ebx),%eax
f01039c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039c4:	c7 04 24 0d 5f 10 f0 	movl   $0xf0105f0d,(%esp)
f01039cb:	e8 4a fc ff ff       	call   f010361a <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01039d0:	8b 43 08             	mov    0x8(%ebx),%eax
f01039d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039d7:	c7 04 24 1c 5f 10 f0 	movl   $0xf0105f1c,(%esp)
f01039de:	e8 37 fc ff ff       	call   f010361a <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01039e3:	8b 43 0c             	mov    0xc(%ebx),%eax
f01039e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039ea:	c7 04 24 2b 5f 10 f0 	movl   $0xf0105f2b,(%esp)
f01039f1:	e8 24 fc ff ff       	call   f010361a <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01039f6:	8b 43 10             	mov    0x10(%ebx),%eax
f01039f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039fd:	c7 04 24 3a 5f 10 f0 	movl   $0xf0105f3a,(%esp)
f0103a04:	e8 11 fc ff ff       	call   f010361a <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a09:	8b 43 14             	mov    0x14(%ebx),%eax
f0103a0c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a10:	c7 04 24 49 5f 10 f0 	movl   $0xf0105f49,(%esp)
f0103a17:	e8 fe fb ff ff       	call   f010361a <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a1c:	8b 43 18             	mov    0x18(%ebx),%eax
f0103a1f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a23:	c7 04 24 58 5f 10 f0 	movl   $0xf0105f58,(%esp)
f0103a2a:	e8 eb fb ff ff       	call   f010361a <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a2f:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103a32:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a36:	c7 04 24 67 5f 10 f0 	movl   $0xf0105f67,(%esp)
f0103a3d:	e8 d8 fb ff ff       	call   f010361a <cprintf>
}
f0103a42:	83 c4 14             	add    $0x14,%esp
f0103a45:	5b                   	pop    %ebx
f0103a46:	5d                   	pop    %ebp
f0103a47:	c3                   	ret    

f0103a48 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103a48:	55                   	push   %ebp
f0103a49:	89 e5                	mov    %esp,%ebp
f0103a4b:	56                   	push   %esi
f0103a4c:	53                   	push   %ebx
f0103a4d:	83 ec 10             	sub    $0x10,%esp
f0103a50:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103a53:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103a57:	c7 04 24 9d 60 10 f0 	movl   $0xf010609d,(%esp)
f0103a5e:	e8 b7 fb ff ff       	call   f010361a <cprintf>
	print_regs(&tf->tf_regs);
f0103a63:	89 1c 24             	mov    %ebx,(%esp)
f0103a66:	e8 36 ff ff ff       	call   f01039a1 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a6b:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103a6f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a73:	c7 04 24 b8 5f 10 f0 	movl   $0xf0105fb8,(%esp)
f0103a7a:	e8 9b fb ff ff       	call   f010361a <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103a7f:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103a83:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a87:	c7 04 24 cb 5f 10 f0 	movl   $0xf0105fcb,(%esp)
f0103a8e:	e8 87 fb ff ff       	call   f010361a <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103a93:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103a96:	83 f8 13             	cmp    $0x13,%eax
f0103a99:	77 09                	ja     f0103aa4 <print_trapframe+0x5c>
		return excnames[trapno];
f0103a9b:	8b 14 85 80 62 10 f0 	mov    -0xfef9d80(,%eax,4),%edx
f0103aa2:	eb 10                	jmp    f0103ab4 <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103aa4:	83 f8 30             	cmp    $0x30,%eax
f0103aa7:	ba 76 5f 10 f0       	mov    $0xf0105f76,%edx
f0103aac:	b9 82 5f 10 f0       	mov    $0xf0105f82,%ecx
f0103ab1:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ab4:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103ab8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103abc:	c7 04 24 de 5f 10 f0 	movl   $0xf0105fde,(%esp)
f0103ac3:	e8 52 fb ff ff       	call   f010361a <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103ac8:	3b 1d 88 db 17 f0    	cmp    0xf017db88,%ebx
f0103ace:	75 19                	jne    f0103ae9 <print_trapframe+0xa1>
f0103ad0:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ad4:	75 13                	jne    f0103ae9 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103ad6:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103ad9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103add:	c7 04 24 f0 5f 10 f0 	movl   $0xf0105ff0,(%esp)
f0103ae4:	e8 31 fb ff ff       	call   f010361a <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103ae9:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103aec:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103af0:	c7 04 24 ff 5f 10 f0 	movl   $0xf0105fff,(%esp)
f0103af7:	e8 1e fb ff ff       	call   f010361a <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103afc:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b00:	75 51                	jne    f0103b53 <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b02:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b05:	89 c2                	mov    %eax,%edx
f0103b07:	83 e2 01             	and    $0x1,%edx
f0103b0a:	ba 91 5f 10 f0       	mov    $0xf0105f91,%edx
f0103b0f:	b9 9c 5f 10 f0       	mov    $0xf0105f9c,%ecx
f0103b14:	0f 45 ca             	cmovne %edx,%ecx
f0103b17:	89 c2                	mov    %eax,%edx
f0103b19:	83 e2 02             	and    $0x2,%edx
f0103b1c:	ba a8 5f 10 f0       	mov    $0xf0105fa8,%edx
f0103b21:	be ae 5f 10 f0       	mov    $0xf0105fae,%esi
f0103b26:	0f 44 d6             	cmove  %esi,%edx
f0103b29:	83 e0 04             	and    $0x4,%eax
f0103b2c:	b8 b3 5f 10 f0       	mov    $0xf0105fb3,%eax
f0103b31:	be c8 60 10 f0       	mov    $0xf01060c8,%esi
f0103b36:	0f 44 c6             	cmove  %esi,%eax
f0103b39:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103b3d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103b41:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b45:	c7 04 24 0d 60 10 f0 	movl   $0xf010600d,(%esp)
f0103b4c:	e8 c9 fa ff ff       	call   f010361a <cprintf>
f0103b51:	eb 0c                	jmp    f0103b5f <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b53:	c7 04 24 94 5b 10 f0 	movl   $0xf0105b94,(%esp)
f0103b5a:	e8 bb fa ff ff       	call   f010361a <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b5f:	8b 43 30             	mov    0x30(%ebx),%eax
f0103b62:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b66:	c7 04 24 1c 60 10 f0 	movl   $0xf010601c,(%esp)
f0103b6d:	e8 a8 fa ff ff       	call   f010361a <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103b72:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103b76:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b7a:	c7 04 24 2b 60 10 f0 	movl   $0xf010602b,(%esp)
f0103b81:	e8 94 fa ff ff       	call   f010361a <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103b86:	8b 43 38             	mov    0x38(%ebx),%eax
f0103b89:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b8d:	c7 04 24 3e 60 10 f0 	movl   $0xf010603e,(%esp)
f0103b94:	e8 81 fa ff ff       	call   f010361a <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103b99:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103b9d:	74 27                	je     f0103bc6 <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103b9f:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103ba2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ba6:	c7 04 24 4d 60 10 f0 	movl   $0xf010604d,(%esp)
f0103bad:	e8 68 fa ff ff       	call   f010361a <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103bb2:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103bb6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bba:	c7 04 24 5c 60 10 f0 	movl   $0xf010605c,(%esp)
f0103bc1:	e8 54 fa ff ff       	call   f010361a <cprintf>
	}
}
f0103bc6:	83 c4 10             	add    $0x10,%esp
f0103bc9:	5b                   	pop    %ebx
f0103bca:	5e                   	pop    %esi
f0103bcb:	5d                   	pop    %ebp
f0103bcc:	c3                   	ret    

f0103bcd <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103bcd:	55                   	push   %ebp
f0103bce:	89 e5                	mov    %esp,%ebp
f0103bd0:	57                   	push   %edi
f0103bd1:	56                   	push   %esi
f0103bd2:	83 ec 10             	sub    $0x10,%esp
f0103bd5:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103bd8:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103bd9:	9c                   	pushf  
f0103bda:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103bdb:	f6 c4 02             	test   $0x2,%ah
f0103bde:	74 24                	je     f0103c04 <trap+0x37>
f0103be0:	c7 44 24 0c 6f 60 10 	movl   $0xf010606f,0xc(%esp)
f0103be7:	f0 
f0103be8:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0103bef:	f0 
f0103bf0:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
f0103bf7:	00 
f0103bf8:	c7 04 24 88 60 10 f0 	movl   $0xf0106088,(%esp)
f0103bff:	e8 ba c4 ff ff       	call   f01000be <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103c04:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103c08:	c7 04 24 94 60 10 f0 	movl   $0xf0106094,(%esp)
f0103c0f:	e8 06 fa ff ff       	call   f010361a <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103c14:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103c18:	83 e0 03             	and    $0x3,%eax
f0103c1b:	66 83 f8 03          	cmp    $0x3,%ax
f0103c1f:	75 3c                	jne    f0103c5d <trap+0x90>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0103c21:	a1 04 d3 17 f0       	mov    0xf017d304,%eax
f0103c26:	85 c0                	test   %eax,%eax
f0103c28:	75 24                	jne    f0103c4e <trap+0x81>
f0103c2a:	c7 44 24 0c af 60 10 	movl   $0xf01060af,0xc(%esp)
f0103c31:	f0 
f0103c32:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0103c39:	f0 
f0103c3a:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
f0103c41:	00 
f0103c42:	c7 04 24 88 60 10 f0 	movl   $0xf0106088,(%esp)
f0103c49:	e8 70 c4 ff ff       	call   f01000be <_panic>
		curenv->env_tf = *tf;
f0103c4e:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103c53:	89 c7                	mov    %eax,%edi
f0103c55:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103c57:	8b 35 04 d3 17 f0    	mov    0xf017d304,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103c5d:	89 35 88 db 17 f0    	mov    %esi,0xf017db88
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103c63:	89 34 24             	mov    %esi,(%esp)
f0103c66:	e8 dd fd ff ff       	call   f0103a48 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103c6b:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103c70:	75 1c                	jne    f0103c8e <trap+0xc1>
		panic("unhandled trap in kernel");
f0103c72:	c7 44 24 08 b6 60 10 	movl   $0xf01060b6,0x8(%esp)
f0103c79:	f0 
f0103c7a:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
f0103c81:	00 
f0103c82:	c7 04 24 88 60 10 f0 	movl   $0xf0106088,(%esp)
f0103c89:	e8 30 c4 ff ff       	call   f01000be <_panic>
	else {
		env_destroy(curenv);
f0103c8e:	a1 04 d3 17 f0       	mov    0xf017d304,%eax
f0103c93:	89 04 24             	mov    %eax,(%esp)
f0103c96:	e8 4f f8 ff ff       	call   f01034ea <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103c9b:	a1 04 d3 17 f0       	mov    0xf017d304,%eax
f0103ca0:	85 c0                	test   %eax,%eax
f0103ca2:	74 06                	je     f0103caa <trap+0xdd>
f0103ca4:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0103ca8:	74 24                	je     f0103cce <trap+0x101>
f0103caa:	c7 44 24 0c 14 62 10 	movl   $0xf0106214,0xc(%esp)
f0103cb1:	f0 
f0103cb2:	c7 44 24 08 b0 5b 10 	movl   $0xf0105bb0,0x8(%esp)
f0103cb9:	f0 
f0103cba:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
f0103cc1:	00 
f0103cc2:	c7 04 24 88 60 10 f0 	movl   $0xf0106088,(%esp)
f0103cc9:	e8 f0 c3 ff ff       	call   f01000be <_panic>
	env_run(curenv);
f0103cce:	89 04 24             	mov    %eax,(%esp)
f0103cd1:	e8 6b f8 ff ff       	call   f0103541 <env_run>

f0103cd6 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103cd6:	55                   	push   %ebp
f0103cd7:	89 e5                	mov    %esp,%ebp
f0103cd9:	53                   	push   %ebx
f0103cda:	83 ec 14             	sub    $0x14,%esp
f0103cdd:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103ce0:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ce3:	8b 53 30             	mov    0x30(%ebx),%edx
f0103ce6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103cea:	89 44 24 08          	mov    %eax,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0103cee:	a1 04 d3 17 f0       	mov    0xf017d304,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cf3:	8b 40 48             	mov    0x48(%eax),%eax
f0103cf6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cfa:	c7 04 24 40 62 10 f0 	movl   $0xf0106240,(%esp)
f0103d01:	e8 14 f9 ff ff       	call   f010361a <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103d06:	89 1c 24             	mov    %ebx,(%esp)
f0103d09:	e8 3a fd ff ff       	call   f0103a48 <print_trapframe>
	env_destroy(curenv);
f0103d0e:	a1 04 d3 17 f0       	mov    0xf017d304,%eax
f0103d13:	89 04 24             	mov    %eax,(%esp)
f0103d16:	e8 cf f7 ff ff       	call   f01034ea <env_destroy>
}
f0103d1b:	83 c4 14             	add    $0x14,%esp
f0103d1e:	5b                   	pop    %ebx
f0103d1f:	5d                   	pop    %ebp
f0103d20:	c3                   	ret    
f0103d21:	66 90                	xchg   %ax,%ax
f0103d23:	90                   	nop

f0103d24 <Divide_error>:
  * TRAPHANDLER_NOEC - No return
  * TRAPHANDLER - return
  *
  * http://pdos.csail.mit.edu/6.828/2011/readings/i386/s09_10.htm
  */
TRAPHANDLER_NOEC(Divide_error, T_DIVIDE);
f0103d24:	6a 00                	push   $0x0
f0103d26:	6a 00                	push   $0x0
f0103d28:	eb 5a                	jmp    f0103d84 <_alltraps>

f0103d2a <Debug>:
TRAPHANDLER_NOEC(Debug, T_DEBUG);
f0103d2a:	6a 00                	push   $0x0
f0103d2c:	6a 01                	push   $0x1
f0103d2e:	eb 54                	jmp    f0103d84 <_alltraps>

f0103d30 <Non_Maskable_Interrupt>:
TRAPHANDLER_NOEC(Non_Maskable_Interrupt, T_NMI);
f0103d30:	6a 00                	push   $0x0
f0103d32:	6a 02                	push   $0x2
f0103d34:	eb 4e                	jmp    f0103d84 <_alltraps>

f0103d36 <Breakpoint>:
TRAPHANDLER_NOEC(Breakpoint, T_BRKPT);
f0103d36:	6a 00                	push   $0x0
f0103d38:	6a 03                	push   $0x3
f0103d3a:	eb 48                	jmp    f0103d84 <_alltraps>

f0103d3c <Overflow>:
TRAPHANDLER_NOEC(Overflow, T_OFLOW);
f0103d3c:	6a 00                	push   $0x0
f0103d3e:	6a 04                	push   $0x4
f0103d40:	eb 42                	jmp    f0103d84 <_alltraps>

f0103d42 <BOUND_Range_Exceeded>:
TRAPHANDLER_NOEC(BOUND_Range_Exceeded, T_BOUND);
f0103d42:	6a 00                	push   $0x0
f0103d44:	6a 05                	push   $0x5
f0103d46:	eb 3c                	jmp    f0103d84 <_alltraps>

f0103d48 <Invalid_Opcode>:
TRAPHANDLER_NOEC(Invalid_Opcode, T_ILLOP);
f0103d48:	6a 00                	push   $0x0
f0103d4a:	6a 06                	push   $0x6
f0103d4c:	eb 36                	jmp    f0103d84 <_alltraps>

f0103d4e <Device_Not_Available>:
TRAPHANDLER_NOEC(Device_Not_Available, T_DEVICE);
f0103d4e:	6a 00                	push   $0x0
f0103d50:	6a 07                	push   $0x7
f0103d52:	eb 30                	jmp    f0103d84 <_alltraps>

f0103d54 <Double_Fault>:
TRAPHANDLER(Double_Fault, T_DBLFLT);
f0103d54:	6a 08                	push   $0x8
f0103d56:	eb 2c                	jmp    f0103d84 <_alltraps>

f0103d58 <Invalid_TSS>:
TRAPHANDLER(Invalid_TSS, T_TSS);
f0103d58:	6a 0a                	push   $0xa
f0103d5a:	eb 28                	jmp    f0103d84 <_alltraps>

f0103d5c <Segment_Not_Present>:
TRAPHANDLER(Segment_Not_Present, T_SEGNP);
f0103d5c:	6a 0b                	push   $0xb
f0103d5e:	eb 24                	jmp    f0103d84 <_alltraps>

f0103d60 <Stack_Fault>:
TRAPHANDLER(Stack_Fault, T_STACK);
f0103d60:	6a 0c                	push   $0xc
f0103d62:	eb 20                	jmp    f0103d84 <_alltraps>

f0103d64 <General_Protection>:
TRAPHANDLER(General_Protection, T_GPFLT);
f0103d64:	6a 0d                	push   $0xd
f0103d66:	eb 1c                	jmp    f0103d84 <_alltraps>

f0103d68 <Page_Fault>:
TRAPHANDLER(Page_Fault, T_PGFLT);
f0103d68:	6a 0e                	push   $0xe
f0103d6a:	eb 18                	jmp    f0103d84 <_alltraps>

f0103d6c <x87_FPU_Floating_Point_Error>:
TRAPHANDLER_NOEC(x87_FPU_Floating_Point_Error, T_FPERR);
f0103d6c:	6a 00                	push   $0x0
f0103d6e:	6a 10                	push   $0x10
f0103d70:	eb 12                	jmp    f0103d84 <_alltraps>

f0103d72 <Alignment_Check>:
TRAPHANDLER_NOEC(Alignment_Check, T_ALIGN);
f0103d72:	6a 00                	push   $0x0
f0103d74:	6a 11                	push   $0x11
f0103d76:	eb 0c                	jmp    f0103d84 <_alltraps>

f0103d78 <Machine_Check>:
TRAPHANDLER_NOEC(Machine_Check, T_MCHK);
f0103d78:	6a 00                	push   $0x0
f0103d7a:	6a 12                	push   $0x12
f0103d7c:	eb 06                	jmp    f0103d84 <_alltraps>

f0103d7e <SIMD_Floating_Point_Exception>:
TRAPHANDLER_NOEC(SIMD_Floating_Point_Exception, T_SIMDERR);
f0103d7e:	6a 00                	push   $0x0
f0103d80:	6a 13                	push   $0x13
f0103d82:	eb 00                	jmp    f0103d84 <_alltraps>

f0103d84 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
 _alltraps:
 	pushw   $0x0
f0103d84:	66 6a 00             	pushw  $0x0
	pushw	%ds
f0103d87:	66 1e                	pushw  %ds
	pushw	$0x0
f0103d89:	66 6a 00             	pushw  $0x0
	pushw	%es	
f0103d8c:	66 06                	pushw  %es
	pushal
f0103d8e:	60                   	pusha  
	movl	$GD_KD, %eax /* GD_KD is kern data -- 0x10 */
f0103d8f:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax, %ds
f0103d94:	8e d8                	mov    %eax,%ds
	movw	%ax, %es
f0103d96:	8e c0                	mov    %eax,%es
	pushl %esp
f0103d98:	54                   	push   %esp
	call trap
f0103d99:	e8 2f fe ff ff       	call   f0103bcd <trap>
f0103d9e:	66 90                	xchg   %ax,%ax

f0103da0 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103da0:	55                   	push   %ebp
f0103da1:	89 e5                	mov    %esp,%ebp
f0103da3:	83 ec 18             	sub    $0x18,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");
f0103da6:	c7 44 24 08 d0 62 10 	movl   $0xf01062d0,0x8(%esp)
f0103dad:	f0 
f0103dae:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f0103db5:	00 
f0103db6:	c7 04 24 e8 62 10 f0 	movl   $0xf01062e8,(%esp)
f0103dbd:	e8 fc c2 ff ff       	call   f01000be <_panic>
f0103dc2:	66 90                	xchg   %ax,%ax
f0103dc4:	66 90                	xchg   %ax,%ax
f0103dc6:	66 90                	xchg   %ax,%ax
f0103dc8:	66 90                	xchg   %ax,%ax
f0103dca:	66 90                	xchg   %ax,%ax
f0103dcc:	66 90                	xchg   %ax,%ax
f0103dce:	66 90                	xchg   %ax,%ax

f0103dd0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103dd0:	55                   	push   %ebp
f0103dd1:	89 e5                	mov    %esp,%ebp
f0103dd3:	57                   	push   %edi
f0103dd4:	56                   	push   %esi
f0103dd5:	53                   	push   %ebx
f0103dd6:	83 ec 14             	sub    $0x14,%esp
f0103dd9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103ddc:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0103ddf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103de2:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103de5:	8b 1a                	mov    (%edx),%ebx
f0103de7:	8b 01                	mov    (%ecx),%eax
f0103de9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0103dec:	39 c3                	cmp    %eax,%ebx
f0103dee:	0f 8f 9f 00 00 00    	jg     f0103e93 <stab_binsearch+0xc3>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0103df4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103dfb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103dfe:	01 d8                	add    %ebx,%eax
f0103e00:	89 c7                	mov    %eax,%edi
f0103e02:	c1 ef 1f             	shr    $0x1f,%edi
f0103e05:	01 c7                	add    %eax,%edi
f0103e07:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103e09:	39 df                	cmp    %ebx,%edi
f0103e0b:	0f 8c ce 00 00 00    	jl     f0103edf <stab_binsearch+0x10f>
f0103e11:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103e14:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103e17:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0103e1c:	39 f0                	cmp    %esi,%eax
f0103e1e:	0f 84 c0 00 00 00    	je     f0103ee4 <stab_binsearch+0x114>
f0103e24:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103e28:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103e2c:	89 f8                	mov    %edi,%eax
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103e2e:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103e31:	39 d8                	cmp    %ebx,%eax
f0103e33:	0f 8c a6 00 00 00    	jl     f0103edf <stab_binsearch+0x10f>
f0103e39:	0f b6 0a             	movzbl (%edx),%ecx
f0103e3c:	83 ea 0c             	sub    $0xc,%edx
f0103e3f:	39 f1                	cmp    %esi,%ecx
f0103e41:	75 eb                	jne    f0103e2e <stab_binsearch+0x5e>
f0103e43:	e9 9e 00 00 00       	jmp    f0103ee6 <stab_binsearch+0x116>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103e48:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103e4b:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f0103e4d:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103e50:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0103e57:	eb 2b                	jmp    f0103e84 <stab_binsearch+0xb4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103e59:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103e5c:	76 14                	jbe    f0103e72 <stab_binsearch+0xa2>
			*region_right = m - 1;
f0103e5e:	83 e8 01             	sub    $0x1,%eax
f0103e61:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103e64:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103e67:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103e69:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0103e70:	eb 12                	jmp    f0103e84 <stab_binsearch+0xb4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103e72:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103e75:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0103e77:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103e7b:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103e7d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0103e84:	3b 5d ec             	cmp    -0x14(%ebp),%ebx
f0103e87:	0f 8e 6e ff ff ff    	jle    f0103dfb <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103e8d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103e91:	75 0f                	jne    f0103ea2 <stab_binsearch+0xd2>
		*region_right = *region_left - 1;
f0103e93:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103e96:	8b 02                	mov    (%edx),%eax
f0103e98:	83 e8 01             	sub    $0x1,%eax
f0103e9b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103e9e:	89 01                	mov    %eax,(%ecx)
f0103ea0:	eb 5c                	jmp    f0103efe <stab_binsearch+0x12e>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103ea2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103ea5:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103ea7:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103eaa:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103eac:	39 c8                	cmp    %ecx,%eax
f0103eae:	7e 28                	jle    f0103ed8 <stab_binsearch+0x108>
		     l > *region_left && stabs[l].n_type != type;
f0103eb0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103eb3:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0103eb6:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0103ebb:	39 f2                	cmp    %esi,%edx
f0103ebd:	74 19                	je     f0103ed8 <stab_binsearch+0x108>
f0103ebf:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103ec3:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103ec7:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103eca:	39 c8                	cmp    %ecx,%eax
f0103ecc:	7e 0a                	jle    f0103ed8 <stab_binsearch+0x108>
		     l > *region_left && stabs[l].n_type != type;
f0103ece:	0f b6 1a             	movzbl (%edx),%ebx
f0103ed1:	83 ea 0c             	sub    $0xc,%edx
f0103ed4:	39 f3                	cmp    %esi,%ebx
f0103ed6:	75 ef                	jne    f0103ec7 <stab_binsearch+0xf7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103ed8:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103edb:	89 02                	mov    %eax,(%edx)
f0103edd:	eb 1f                	jmp    f0103efe <stab_binsearch+0x12e>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103edf:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103ee2:	eb a0                	jmp    f0103e84 <stab_binsearch+0xb4>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103ee4:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103ee6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103ee9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0103eec:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103ef0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103ef3:	0f 82 4f ff ff ff    	jb     f0103e48 <stab_binsearch+0x78>
f0103ef9:	e9 5b ff ff ff       	jmp    f0103e59 <stab_binsearch+0x89>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0103efe:	83 c4 14             	add    $0x14,%esp
f0103f01:	5b                   	pop    %ebx
f0103f02:	5e                   	pop    %esi
f0103f03:	5f                   	pop    %edi
f0103f04:	5d                   	pop    %ebp
f0103f05:	c3                   	ret    

f0103f06 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103f06:	55                   	push   %ebp
f0103f07:	89 e5                	mov    %esp,%ebp
f0103f09:	57                   	push   %edi
f0103f0a:	56                   	push   %esi
f0103f0b:	53                   	push   %ebx
f0103f0c:	83 ec 4c             	sub    $0x4c,%esp
f0103f0f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103f12:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103f15:	c7 06 f7 62 10 f0    	movl   $0xf01062f7,(%esi)
	info->eip_line = 0;
f0103f1b:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103f22:	c7 46 08 f7 62 10 f0 	movl   $0xf01062f7,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103f29:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103f30:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103f33:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103f3a:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103f40:	77 22                	ja     f0103f64 <debuginfo_eip+0x5e>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103f42:	8b 1d 00 00 20 00    	mov    0x200000,%ebx
f0103f48:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0103f4b:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103f50:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f0103f56:	89 5d cc             	mov    %ebx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0103f59:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f0103f5f:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0103f62:	eb 1a                	jmp    f0103f7e <debuginfo_eip+0x78>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103f64:	c7 45 d0 04 0e 11 f0 	movl   $0xf0110e04,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103f6b:	c7 45 cc dd e3 10 f0 	movl   $0xf010e3dd,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103f72:	b8 dc e3 10 f0       	mov    $0xf010e3dc,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103f77:	c7 45 d4 10 65 10 f0 	movl   $0xf0106510,-0x2c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103f7e:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103f81:	39 5d cc             	cmp    %ebx,-0x34(%ebp)
f0103f84:	0f 83 62 01 00 00    	jae    f01040ec <debuginfo_eip+0x1e6>
f0103f8a:	80 7b ff 00          	cmpb   $0x0,-0x1(%ebx)
f0103f8e:	0f 85 5f 01 00 00    	jne    f01040f3 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103f94:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103f9b:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0103f9e:	c1 f8 02             	sar    $0x2,%eax
f0103fa1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103fa7:	83 e8 01             	sub    $0x1,%eax
f0103faa:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103fad:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103fb1:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103fb8:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103fbb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103fbe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103fc1:	e8 0a fe ff ff       	call   f0103dd0 <stab_binsearch>
	if (lfile == 0)
f0103fc6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103fc9:	85 c0                	test   %eax,%eax
f0103fcb:	0f 84 29 01 00 00    	je     f01040fa <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103fd1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103fd4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103fd7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103fda:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103fde:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103fe5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103fe8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103feb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103fee:	e8 dd fd ff ff       	call   f0103dd0 <stab_binsearch>

	if (lfun <= rfun) {
f0103ff3:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103ff6:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0103ff9:	7f 23                	jg     f010401e <debuginfo_eip+0x118>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103ffb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103ffe:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104001:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0104004:	8b 10                	mov    (%eax),%edx
f0104006:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104009:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f010400c:	39 ca                	cmp    %ecx,%edx
f010400e:	73 06                	jae    f0104016 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104010:	03 55 cc             	add    -0x34(%ebp),%edx
f0104013:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104016:	8b 40 08             	mov    0x8(%eax),%eax
f0104019:	89 46 10             	mov    %eax,0x10(%esi)
f010401c:	eb 06                	jmp    f0104024 <debuginfo_eip+0x11e>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010401e:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104021:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104024:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010402b:	00 
f010402c:	8b 46 08             	mov    0x8(%esi),%eax
f010402f:	89 04 24             	mov    %eax,(%esp)
f0104032:	e8 94 09 00 00       	call   f01049cb <strfind>
f0104037:	2b 46 08             	sub    0x8(%esi),%eax
f010403a:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010403d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104040:	39 fb                	cmp    %edi,%ebx
f0104042:	7c 63                	jl     f01040a7 <debuginfo_eip+0x1a1>
	       && stabs[lline].n_type != N_SOL
f0104044:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104047:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010404a:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f010404d:	0f b6 41 04          	movzbl 0x4(%ecx),%eax
f0104051:	88 45 c7             	mov    %al,-0x39(%ebp)
f0104054:	3c 84                	cmp    $0x84,%al
f0104056:	74 37                	je     f010408f <debuginfo_eip+0x189>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0104058:	8d 54 5b fd          	lea    -0x3(%ebx,%ebx,2),%edx
f010405c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010405f:	8d 04 90             	lea    (%eax,%edx,4),%eax
f0104062:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0104065:	0f b6 55 c7          	movzbl -0x39(%ebp),%edx
f0104069:	eb 15                	jmp    f0104080 <debuginfo_eip+0x17a>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010406b:	83 eb 01             	sub    $0x1,%ebx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010406e:	39 fb                	cmp    %edi,%ebx
f0104070:	7c 35                	jl     f01040a7 <debuginfo_eip+0x1a1>
	       && stabs[lline].n_type != N_SOL
f0104072:	89 c1                	mov    %eax,%ecx
f0104074:	83 e8 0c             	sub    $0xc,%eax
f0104077:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f010407b:	80 fa 84             	cmp    $0x84,%dl
f010407e:	74 0f                	je     f010408f <debuginfo_eip+0x189>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104080:	80 fa 64             	cmp    $0x64,%dl
f0104083:	75 e6                	jne    f010406b <debuginfo_eip+0x165>
f0104085:	83 79 08 00          	cmpl   $0x0,0x8(%ecx)
f0104089:	74 e0                	je     f010406b <debuginfo_eip+0x165>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010408b:	39 df                	cmp    %ebx,%edi
f010408d:	7f 18                	jg     f01040a7 <debuginfo_eip+0x1a1>
f010408f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104092:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104095:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0104098:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010409b:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010409e:	39 d0                	cmp    %edx,%eax
f01040a0:	73 05                	jae    f01040a7 <debuginfo_eip+0x1a1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01040a2:	03 45 cc             	add    -0x34(%ebp),%eax
f01040a5:	89 06                	mov    %eax,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01040a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01040aa:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f01040ad:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01040b2:	39 ca                	cmp    %ecx,%edx
f01040b4:	7d 5e                	jge    f0104114 <debuginfo_eip+0x20e>
		for (lline = lfun + 1;
f01040b6:	8d 42 01             	lea    0x1(%edx),%eax
f01040b9:	39 c1                	cmp    %eax,%ecx
f01040bb:	7e 44                	jle    f0104101 <debuginfo_eip+0x1fb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01040bd:	8d 1c 40             	lea    (%eax,%eax,2),%ebx
f01040c0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01040c3:	80 7c 9f 04 a0       	cmpb   $0xa0,0x4(%edi,%ebx,4)
f01040c8:	75 3e                	jne    f0104108 <debuginfo_eip+0x202>
f01040ca:	8d 14 52             	lea    (%edx,%edx,2),%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01040cd:	8d 54 97 1c          	lea    0x1c(%edi,%edx,4),%edx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01040d1:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01040d5:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01040d8:	39 c1                	cmp    %eax,%ecx
f01040da:	7e 33                	jle    f010410f <debuginfo_eip+0x209>
f01040dc:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01040df:	80 7a f4 a0          	cmpb   $0xa0,-0xc(%edx)
f01040e3:	74 ec                	je     f01040d1 <debuginfo_eip+0x1cb>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f01040e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01040ea:	eb 28                	jmp    f0104114 <debuginfo_eip+0x20e>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01040ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01040f1:	eb 21                	jmp    f0104114 <debuginfo_eip+0x20e>
f01040f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01040f8:	eb 1a                	jmp    f0104114 <debuginfo_eip+0x20e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01040fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01040ff:	eb 13                	jmp    f0104114 <debuginfo_eip+0x20e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0104101:	b8 00 00 00 00       	mov    $0x0,%eax
f0104106:	eb 0c                	jmp    f0104114 <debuginfo_eip+0x20e>
f0104108:	b8 00 00 00 00       	mov    $0x0,%eax
f010410d:	eb 05                	jmp    f0104114 <debuginfo_eip+0x20e>
f010410f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104114:	83 c4 4c             	add    $0x4c,%esp
f0104117:	5b                   	pop    %ebx
f0104118:	5e                   	pop    %esi
f0104119:	5f                   	pop    %edi
f010411a:	5d                   	pop    %ebp
f010411b:	c3                   	ret    
f010411c:	66 90                	xchg   %ax,%ax
f010411e:	66 90                	xchg   %ax,%ax

f0104120 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104120:	55                   	push   %ebp
f0104121:	89 e5                	mov    %esp,%ebp
f0104123:	57                   	push   %edi
f0104124:	56                   	push   %esi
f0104125:	53                   	push   %ebx
f0104126:	83 ec 4c             	sub    $0x4c,%esp
f0104129:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010412c:	89 d7                	mov    %edx,%edi
f010412e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104131:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0104134:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104137:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010413a:	b8 00 00 00 00       	mov    $0x0,%eax
f010413f:	39 d8                	cmp    %ebx,%eax
f0104141:	72 17                	jb     f010415a <printnum+0x3a>
f0104143:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104146:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0104149:	76 0f                	jbe    f010415a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010414b:	8b 75 14             	mov    0x14(%ebp),%esi
f010414e:	83 ee 01             	sub    $0x1,%esi
f0104151:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104154:	85 f6                	test   %esi,%esi
f0104156:	7f 63                	jg     f01041bb <printnum+0x9b>
f0104158:	eb 75                	jmp    f01041cf <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010415a:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010415d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0104161:	8b 45 14             	mov    0x14(%ebp),%eax
f0104164:	83 e8 01             	sub    $0x1,%eax
f0104167:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010416b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010416e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104172:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104176:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010417a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010417d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104180:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0104187:	00 
f0104188:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010418b:	89 1c 24             	mov    %ebx,(%esp)
f010418e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104191:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104195:	e8 b6 0a 00 00       	call   f0104c50 <__udivdi3>
f010419a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010419d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01041a0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01041a4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01041a8:	89 04 24             	mov    %eax,(%esp)
f01041ab:	89 54 24 04          	mov    %edx,0x4(%esp)
f01041af:	89 fa                	mov    %edi,%edx
f01041b1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01041b4:	e8 67 ff ff ff       	call   f0104120 <printnum>
f01041b9:	eb 14                	jmp    f01041cf <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01041bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01041bf:	8b 45 18             	mov    0x18(%ebp),%eax
f01041c2:	89 04 24             	mov    %eax,(%esp)
f01041c5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01041c7:	83 ee 01             	sub    $0x1,%esi
f01041ca:	75 ef                	jne    f01041bb <printnum+0x9b>
f01041cc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01041cf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01041d3:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01041d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01041da:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01041de:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01041e5:	00 
f01041e6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01041e9:	89 1c 24             	mov    %ebx,(%esp)
f01041ec:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01041ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01041f3:	e8 a8 0b 00 00       	call   f0104da0 <__umoddi3>
f01041f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01041fc:	0f be 80 01 63 10 f0 	movsbl -0xfef9cff(%eax),%eax
f0104203:	89 04 24             	mov    %eax,(%esp)
f0104206:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104209:	ff d0                	call   *%eax
}
f010420b:	83 c4 4c             	add    $0x4c,%esp
f010420e:	5b                   	pop    %ebx
f010420f:	5e                   	pop    %esi
f0104210:	5f                   	pop    %edi
f0104211:	5d                   	pop    %ebp
f0104212:	c3                   	ret    

f0104213 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104213:	55                   	push   %ebp
f0104214:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104216:	83 fa 01             	cmp    $0x1,%edx
f0104219:	7e 0e                	jle    f0104229 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010421b:	8b 10                	mov    (%eax),%edx
f010421d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104220:	89 08                	mov    %ecx,(%eax)
f0104222:	8b 02                	mov    (%edx),%eax
f0104224:	8b 52 04             	mov    0x4(%edx),%edx
f0104227:	eb 22                	jmp    f010424b <getuint+0x38>
	else if (lflag)
f0104229:	85 d2                	test   %edx,%edx
f010422b:	74 10                	je     f010423d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010422d:	8b 10                	mov    (%eax),%edx
f010422f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104232:	89 08                	mov    %ecx,(%eax)
f0104234:	8b 02                	mov    (%edx),%eax
f0104236:	ba 00 00 00 00       	mov    $0x0,%edx
f010423b:	eb 0e                	jmp    f010424b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010423d:	8b 10                	mov    (%eax),%edx
f010423f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104242:	89 08                	mov    %ecx,(%eax)
f0104244:	8b 02                	mov    (%edx),%eax
f0104246:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010424b:	5d                   	pop    %ebp
f010424c:	c3                   	ret    

f010424d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010424d:	55                   	push   %ebp
f010424e:	89 e5                	mov    %esp,%ebp
f0104250:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104253:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104257:	8b 10                	mov    (%eax),%edx
f0104259:	3b 50 04             	cmp    0x4(%eax),%edx
f010425c:	73 0a                	jae    f0104268 <sprintputch+0x1b>
		*b->buf++ = ch;
f010425e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104261:	88 0a                	mov    %cl,(%edx)
f0104263:	83 c2 01             	add    $0x1,%edx
f0104266:	89 10                	mov    %edx,(%eax)
}
f0104268:	5d                   	pop    %ebp
f0104269:	c3                   	ret    

f010426a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010426a:	55                   	push   %ebp
f010426b:	89 e5                	mov    %esp,%ebp
f010426d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0104270:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104273:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104277:	8b 45 10             	mov    0x10(%ebp),%eax
f010427a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010427e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104281:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104285:	8b 45 08             	mov    0x8(%ebp),%eax
f0104288:	89 04 24             	mov    %eax,(%esp)
f010428b:	e8 02 00 00 00       	call   f0104292 <vprintfmt>
	va_end(ap);
}
f0104290:	c9                   	leave  
f0104291:	c3                   	ret    

f0104292 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104292:	55                   	push   %ebp
f0104293:	89 e5                	mov    %esp,%ebp
f0104295:	57                   	push   %edi
f0104296:	56                   	push   %esi
f0104297:	53                   	push   %ebx
f0104298:	83 ec 4c             	sub    $0x4c,%esp
f010429b:	8b 75 08             	mov    0x8(%ebp),%esi
f010429e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01042a1:	8b 7d 10             	mov    0x10(%ebp),%edi
f01042a4:	eb 11                	jmp    f01042b7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01042a6:	85 c0                	test   %eax,%eax
f01042a8:	0f 84 db 03 00 00    	je     f0104689 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f01042ae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01042b2:	89 04 24             	mov    %eax,(%esp)
f01042b5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01042b7:	0f b6 07             	movzbl (%edi),%eax
f01042ba:	83 c7 01             	add    $0x1,%edi
f01042bd:	83 f8 25             	cmp    $0x25,%eax
f01042c0:	75 e4                	jne    f01042a6 <vprintfmt+0x14>
f01042c2:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f01042c6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f01042cd:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01042d4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f01042db:	ba 00 00 00 00       	mov    $0x0,%edx
f01042e0:	eb 2b                	jmp    f010430d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042e2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01042e5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f01042e9:	eb 22                	jmp    f010430d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042eb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01042ee:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f01042f2:	eb 19                	jmp    f010430d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042f4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01042f7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01042fe:	eb 0d                	jmp    f010430d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0104300:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104303:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104306:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010430d:	0f b6 0f             	movzbl (%edi),%ecx
f0104310:	8d 47 01             	lea    0x1(%edi),%eax
f0104313:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104316:	0f b6 07             	movzbl (%edi),%eax
f0104319:	83 e8 23             	sub    $0x23,%eax
f010431c:	3c 55                	cmp    $0x55,%al
f010431e:	0f 87 40 03 00 00    	ja     f0104664 <vprintfmt+0x3d2>
f0104324:	0f b6 c0             	movzbl %al,%eax
f0104327:	ff 24 85 8c 63 10 f0 	jmp    *-0xfef9c74(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010432e:	83 e9 30             	sub    $0x30,%ecx
f0104331:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f0104334:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0104338:	8d 48 d0             	lea    -0x30(%eax),%ecx
f010433b:	83 f9 09             	cmp    $0x9,%ecx
f010433e:	77 57                	ja     f0104397 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104340:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104343:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0104346:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104349:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010434c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f010434f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0104353:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0104356:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0104359:	83 f9 09             	cmp    $0x9,%ecx
f010435c:	76 eb                	jbe    f0104349 <vprintfmt+0xb7>
f010435e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104361:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104364:	eb 34                	jmp    f010439a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104366:	8b 45 14             	mov    0x14(%ebp),%eax
f0104369:	8d 48 04             	lea    0x4(%eax),%ecx
f010436c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010436f:	8b 00                	mov    (%eax),%eax
f0104371:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104374:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104377:	eb 21                	jmp    f010439a <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0104379:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010437d:	0f 88 71 ff ff ff    	js     f01042f4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104383:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104386:	eb 85                	jmp    f010430d <vprintfmt+0x7b>
f0104388:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010438b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0104392:	e9 76 ff ff ff       	jmp    f010430d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104397:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010439a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010439e:	0f 89 69 ff ff ff    	jns    f010430d <vprintfmt+0x7b>
f01043a4:	e9 57 ff ff ff       	jmp    f0104300 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01043a9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01043ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01043af:	e9 59 ff ff ff       	jmp    f010430d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01043b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01043b7:	8d 50 04             	lea    0x4(%eax),%edx
f01043ba:	89 55 14             	mov    %edx,0x14(%ebp)
f01043bd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01043c1:	8b 00                	mov    (%eax),%eax
f01043c3:	89 04 24             	mov    %eax,(%esp)
f01043c6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01043c8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01043cb:	e9 e7 fe ff ff       	jmp    f01042b7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01043d0:	8b 45 14             	mov    0x14(%ebp),%eax
f01043d3:	8d 50 04             	lea    0x4(%eax),%edx
f01043d6:	89 55 14             	mov    %edx,0x14(%ebp)
f01043d9:	8b 00                	mov    (%eax),%eax
f01043db:	89 c2                	mov    %eax,%edx
f01043dd:	c1 fa 1f             	sar    $0x1f,%edx
f01043e0:	31 d0                	xor    %edx,%eax
f01043e2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01043e4:	83 f8 06             	cmp    $0x6,%eax
f01043e7:	7f 0b                	jg     f01043f4 <vprintfmt+0x162>
f01043e9:	8b 14 85 e4 64 10 f0 	mov    -0xfef9b1c(,%eax,4),%edx
f01043f0:	85 d2                	test   %edx,%edx
f01043f2:	75 20                	jne    f0104414 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f01043f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01043f8:	c7 44 24 08 19 63 10 	movl   $0xf0106319,0x8(%esp)
f01043ff:	f0 
f0104400:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104404:	89 34 24             	mov    %esi,(%esp)
f0104407:	e8 5e fe ff ff       	call   f010426a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010440c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010440f:	e9 a3 fe ff ff       	jmp    f01042b7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0104414:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104418:	c7 44 24 08 c2 5b 10 	movl   $0xf0105bc2,0x8(%esp)
f010441f:	f0 
f0104420:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104424:	89 34 24             	mov    %esi,(%esp)
f0104427:	e8 3e fe ff ff       	call   f010426a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010442c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010442f:	e9 83 fe ff ff       	jmp    f01042b7 <vprintfmt+0x25>
f0104434:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104437:	8b 7d d8             	mov    -0x28(%ebp),%edi
f010443a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010443d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104440:	8d 50 04             	lea    0x4(%eax),%edx
f0104443:	89 55 14             	mov    %edx,0x14(%ebp)
f0104446:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104448:	85 ff                	test   %edi,%edi
f010444a:	b8 12 63 10 f0       	mov    $0xf0106312,%eax
f010444f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104452:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0104456:	74 06                	je     f010445e <vprintfmt+0x1cc>
f0104458:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010445c:	7f 16                	jg     f0104474 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010445e:	0f b6 17             	movzbl (%edi),%edx
f0104461:	0f be c2             	movsbl %dl,%eax
f0104464:	83 c7 01             	add    $0x1,%edi
f0104467:	85 c0                	test   %eax,%eax
f0104469:	0f 85 9f 00 00 00    	jne    f010450e <vprintfmt+0x27c>
f010446f:	e9 8b 00 00 00       	jmp    f01044ff <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104474:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104478:	89 3c 24             	mov    %edi,(%esp)
f010447b:	e8 92 03 00 00       	call   f0104812 <strnlen>
f0104480:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0104483:	29 c2                	sub    %eax,%edx
f0104485:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0104488:	85 d2                	test   %edx,%edx
f010448a:	7e d2                	jle    f010445e <vprintfmt+0x1cc>
					putch(padc, putdat);
f010448c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0104490:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0104493:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0104496:	89 d7                	mov    %edx,%edi
f0104498:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010449c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010449f:	89 04 24             	mov    %eax,(%esp)
f01044a2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01044a4:	83 ef 01             	sub    $0x1,%edi
f01044a7:	75 ef                	jne    f0104498 <vprintfmt+0x206>
f01044a9:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01044ac:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01044af:	eb ad                	jmp    f010445e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01044b1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01044b5:	74 20                	je     f01044d7 <vprintfmt+0x245>
f01044b7:	0f be d2             	movsbl %dl,%edx
f01044ba:	83 ea 20             	sub    $0x20,%edx
f01044bd:	83 fa 5e             	cmp    $0x5e,%edx
f01044c0:	76 15                	jbe    f01044d7 <vprintfmt+0x245>
					putch('?', putdat);
f01044c2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01044c5:	89 54 24 04          	mov    %edx,0x4(%esp)
f01044c9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01044d0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01044d3:	ff d1                	call   *%ecx
f01044d5:	eb 0f                	jmp    f01044e6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f01044d7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01044da:	89 54 24 04          	mov    %edx,0x4(%esp)
f01044de:	89 04 24             	mov    %eax,(%esp)
f01044e1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01044e4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01044e6:	83 eb 01             	sub    $0x1,%ebx
f01044e9:	0f b6 17             	movzbl (%edi),%edx
f01044ec:	0f be c2             	movsbl %dl,%eax
f01044ef:	83 c7 01             	add    $0x1,%edi
f01044f2:	85 c0                	test   %eax,%eax
f01044f4:	75 24                	jne    f010451a <vprintfmt+0x288>
f01044f6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01044f9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01044fc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01044ff:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104502:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104506:	0f 8e ab fd ff ff    	jle    f01042b7 <vprintfmt+0x25>
f010450c:	eb 20                	jmp    f010452e <vprintfmt+0x29c>
f010450e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0104511:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104514:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0104517:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010451a:	85 f6                	test   %esi,%esi
f010451c:	78 93                	js     f01044b1 <vprintfmt+0x21f>
f010451e:	83 ee 01             	sub    $0x1,%esi
f0104521:	79 8e                	jns    f01044b1 <vprintfmt+0x21f>
f0104523:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0104526:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104529:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010452c:	eb d1                	jmp    f01044ff <vprintfmt+0x26d>
f010452e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104531:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104535:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010453c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010453e:	83 ef 01             	sub    $0x1,%edi
f0104541:	75 ee                	jne    f0104531 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104543:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104546:	e9 6c fd ff ff       	jmp    f01042b7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010454b:	83 fa 01             	cmp    $0x1,%edx
f010454e:	66 90                	xchg   %ax,%ax
f0104550:	7e 16                	jle    f0104568 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f0104552:	8b 45 14             	mov    0x14(%ebp),%eax
f0104555:	8d 50 08             	lea    0x8(%eax),%edx
f0104558:	89 55 14             	mov    %edx,0x14(%ebp)
f010455b:	8b 10                	mov    (%eax),%edx
f010455d:	8b 48 04             	mov    0x4(%eax),%ecx
f0104560:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0104563:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0104566:	eb 32                	jmp    f010459a <vprintfmt+0x308>
	else if (lflag)
f0104568:	85 d2                	test   %edx,%edx
f010456a:	74 18                	je     f0104584 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f010456c:	8b 45 14             	mov    0x14(%ebp),%eax
f010456f:	8d 50 04             	lea    0x4(%eax),%edx
f0104572:	89 55 14             	mov    %edx,0x14(%ebp)
f0104575:	8b 00                	mov    (%eax),%eax
f0104577:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010457a:	89 c1                	mov    %eax,%ecx
f010457c:	c1 f9 1f             	sar    $0x1f,%ecx
f010457f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0104582:	eb 16                	jmp    f010459a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f0104584:	8b 45 14             	mov    0x14(%ebp),%eax
f0104587:	8d 50 04             	lea    0x4(%eax),%edx
f010458a:	89 55 14             	mov    %edx,0x14(%ebp)
f010458d:	8b 00                	mov    (%eax),%eax
f010458f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104592:	89 c7                	mov    %eax,%edi
f0104594:	c1 ff 1f             	sar    $0x1f,%edi
f0104597:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010459a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010459d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01045a0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01045a5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01045a9:	79 7d                	jns    f0104628 <vprintfmt+0x396>
				putch('-', putdat);
f01045ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01045af:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01045b6:	ff d6                	call   *%esi
				num = -(long long) num;
f01045b8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01045bb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01045be:	f7 d8                	neg    %eax
f01045c0:	83 d2 00             	adc    $0x0,%edx
f01045c3:	f7 da                	neg    %edx
			}
			base = 10;
f01045c5:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01045ca:	eb 5c                	jmp    f0104628 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01045cc:	8d 45 14             	lea    0x14(%ebp),%eax
f01045cf:	e8 3f fc ff ff       	call   f0104213 <getuint>
			base = 10;
f01045d4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01045d9:	eb 4d                	jmp    f0104628 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01045db:	8d 45 14             	lea    0x14(%ebp),%eax
f01045de:	e8 30 fc ff ff       	call   f0104213 <getuint>
			base = 8;
f01045e3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01045e8:	eb 3e                	jmp    f0104628 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
f01045ea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01045ee:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01045f5:	ff d6                	call   *%esi
			putch('x', putdat);
f01045f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01045fb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0104602:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104604:	8b 45 14             	mov    0x14(%ebp),%eax
f0104607:	8d 50 04             	lea    0x4(%eax),%edx
f010460a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010460d:	8b 00                	mov    (%eax),%eax
f010460f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104614:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104619:	eb 0d                	jmp    f0104628 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010461b:	8d 45 14             	lea    0x14(%ebp),%eax
f010461e:	e8 f0 fb ff ff       	call   f0104213 <getuint>
			base = 16;
f0104623:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104628:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010462c:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0104630:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0104633:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104637:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010463b:	89 04 24             	mov    %eax,(%esp)
f010463e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104642:	89 da                	mov    %ebx,%edx
f0104644:	89 f0                	mov    %esi,%eax
f0104646:	e8 d5 fa ff ff       	call   f0104120 <printnum>
			break;
f010464b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010464e:	e9 64 fc ff ff       	jmp    f01042b7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104653:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104657:	89 0c 24             	mov    %ecx,(%esp)
f010465a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010465c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010465f:	e9 53 fc ff ff       	jmp    f01042b7 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104664:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104668:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010466f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104671:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104675:	0f 84 3c fc ff ff    	je     f01042b7 <vprintfmt+0x25>
f010467b:	83 ef 01             	sub    $0x1,%edi
f010467e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104682:	75 f7                	jne    f010467b <vprintfmt+0x3e9>
f0104684:	e9 2e fc ff ff       	jmp    f01042b7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0104689:	83 c4 4c             	add    $0x4c,%esp
f010468c:	5b                   	pop    %ebx
f010468d:	5e                   	pop    %esi
f010468e:	5f                   	pop    %edi
f010468f:	5d                   	pop    %ebp
f0104690:	c3                   	ret    

f0104691 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104691:	55                   	push   %ebp
f0104692:	89 e5                	mov    %esp,%ebp
f0104694:	83 ec 28             	sub    $0x28,%esp
f0104697:	8b 45 08             	mov    0x8(%ebp),%eax
f010469a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010469d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01046a0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01046a4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01046a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01046ae:	85 d2                	test   %edx,%edx
f01046b0:	7e 30                	jle    f01046e2 <vsnprintf+0x51>
f01046b2:	85 c0                	test   %eax,%eax
f01046b4:	74 2c                	je     f01046e2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01046b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01046b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01046bd:	8b 45 10             	mov    0x10(%ebp),%eax
f01046c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01046c4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01046c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046cb:	c7 04 24 4d 42 10 f0 	movl   $0xf010424d,(%esp)
f01046d2:	e8 bb fb ff ff       	call   f0104292 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01046d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01046da:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01046dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01046e0:	eb 05                	jmp    f01046e7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01046e2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01046e7:	c9                   	leave  
f01046e8:	c3                   	ret    

f01046e9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01046e9:	55                   	push   %ebp
f01046ea:	89 e5                	mov    %esp,%ebp
f01046ec:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01046ef:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01046f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01046f6:	8b 45 10             	mov    0x10(%ebp),%eax
f01046f9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01046fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104700:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104704:	8b 45 08             	mov    0x8(%ebp),%eax
f0104707:	89 04 24             	mov    %eax,(%esp)
f010470a:	e8 82 ff ff ff       	call   f0104691 <vsnprintf>
	va_end(ap);

	return rc;
}
f010470f:	c9                   	leave  
f0104710:	c3                   	ret    
f0104711:	66 90                	xchg   %ax,%ax
f0104713:	66 90                	xchg   %ax,%ax
f0104715:	66 90                	xchg   %ax,%ax
f0104717:	66 90                	xchg   %ax,%ax
f0104719:	66 90                	xchg   %ax,%ax
f010471b:	66 90                	xchg   %ax,%ax
f010471d:	66 90                	xchg   %ax,%ax
f010471f:	90                   	nop

f0104720 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104720:	55                   	push   %ebp
f0104721:	89 e5                	mov    %esp,%ebp
f0104723:	57                   	push   %edi
f0104724:	56                   	push   %esi
f0104725:	53                   	push   %ebx
f0104726:	83 ec 1c             	sub    $0x1c,%esp
f0104729:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010472c:	85 c0                	test   %eax,%eax
f010472e:	74 10                	je     f0104740 <readline+0x20>
		cprintf("%s", prompt);
f0104730:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104734:	c7 04 24 c2 5b 10 f0 	movl   $0xf0105bc2,(%esp)
f010473b:	e8 da ee ff ff       	call   f010361a <cprintf>

	i = 0;
	echoing = iscons(0);
f0104740:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104747:	e8 01 bf ff ff       	call   f010064d <iscons>
f010474c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010474e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104753:	e8 e4 be ff ff       	call   f010063c <getchar>
f0104758:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010475a:	85 c0                	test   %eax,%eax
f010475c:	79 17                	jns    f0104775 <readline+0x55>
			cprintf("read error: %e\n", c);
f010475e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104762:	c7 04 24 00 65 10 f0 	movl   $0xf0106500,(%esp)
f0104769:	e8 ac ee ff ff       	call   f010361a <cprintf>
			return NULL;
f010476e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104773:	eb 6d                	jmp    f01047e2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104775:	83 f8 7f             	cmp    $0x7f,%eax
f0104778:	74 05                	je     f010477f <readline+0x5f>
f010477a:	83 f8 08             	cmp    $0x8,%eax
f010477d:	75 19                	jne    f0104798 <readline+0x78>
f010477f:	85 f6                	test   %esi,%esi
f0104781:	7e 15                	jle    f0104798 <readline+0x78>
			if (echoing)
f0104783:	85 ff                	test   %edi,%edi
f0104785:	74 0c                	je     f0104793 <readline+0x73>
				cputchar('\b');
f0104787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010478e:	e8 99 be ff ff       	call   f010062c <cputchar>
			i--;
f0104793:	83 ee 01             	sub    $0x1,%esi
f0104796:	eb bb                	jmp    f0104753 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104798:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010479e:	7f 1c                	jg     f01047bc <readline+0x9c>
f01047a0:	83 fb 1f             	cmp    $0x1f,%ebx
f01047a3:	7e 17                	jle    f01047bc <readline+0x9c>
			if (echoing)
f01047a5:	85 ff                	test   %edi,%edi
f01047a7:	74 08                	je     f01047b1 <readline+0x91>
				cputchar(c);
f01047a9:	89 1c 24             	mov    %ebx,(%esp)
f01047ac:	e8 7b be ff ff       	call   f010062c <cputchar>
			buf[i++] = c;
f01047b1:	88 9e a0 db 17 f0    	mov    %bl,-0xfe82460(%esi)
f01047b7:	83 c6 01             	add    $0x1,%esi
f01047ba:	eb 97                	jmp    f0104753 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01047bc:	83 fb 0d             	cmp    $0xd,%ebx
f01047bf:	74 05                	je     f01047c6 <readline+0xa6>
f01047c1:	83 fb 0a             	cmp    $0xa,%ebx
f01047c4:	75 8d                	jne    f0104753 <readline+0x33>
			if (echoing)
f01047c6:	85 ff                	test   %edi,%edi
f01047c8:	74 0c                	je     f01047d6 <readline+0xb6>
				cputchar('\n');
f01047ca:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01047d1:	e8 56 be ff ff       	call   f010062c <cputchar>
			buf[i] = 0;
f01047d6:	c6 86 a0 db 17 f0 00 	movb   $0x0,-0xfe82460(%esi)
			return buf;
f01047dd:	b8 a0 db 17 f0       	mov    $0xf017dba0,%eax
		}
	}
}
f01047e2:	83 c4 1c             	add    $0x1c,%esp
f01047e5:	5b                   	pop    %ebx
f01047e6:	5e                   	pop    %esi
f01047e7:	5f                   	pop    %edi
f01047e8:	5d                   	pop    %ebp
f01047e9:	c3                   	ret    
f01047ea:	66 90                	xchg   %ax,%ax
f01047ec:	66 90                	xchg   %ax,%ax
f01047ee:	66 90                	xchg   %ax,%ax

f01047f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01047f0:	55                   	push   %ebp
f01047f1:	89 e5                	mov    %esp,%ebp
f01047f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01047f6:	80 3a 00             	cmpb   $0x0,(%edx)
f01047f9:	74 10                	je     f010480b <strlen+0x1b>
f01047fb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0104800:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104803:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104807:	75 f7                	jne    f0104800 <strlen+0x10>
f0104809:	eb 05                	jmp    f0104810 <strlen+0x20>
f010480b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0104810:	5d                   	pop    %ebp
f0104811:	c3                   	ret    

f0104812 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104812:	55                   	push   %ebp
f0104813:	89 e5                	mov    %esp,%ebp
f0104815:	53                   	push   %ebx
f0104816:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104819:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010481c:	85 c9                	test   %ecx,%ecx
f010481e:	74 1c                	je     f010483c <strnlen+0x2a>
f0104820:	80 3b 00             	cmpb   $0x0,(%ebx)
f0104823:	74 1e                	je     f0104843 <strnlen+0x31>
f0104825:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010482a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010482c:	39 ca                	cmp    %ecx,%edx
f010482e:	74 18                	je     f0104848 <strnlen+0x36>
f0104830:	83 c2 01             	add    $0x1,%edx
f0104833:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0104838:	75 f0                	jne    f010482a <strnlen+0x18>
f010483a:	eb 0c                	jmp    f0104848 <strnlen+0x36>
f010483c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104841:	eb 05                	jmp    f0104848 <strnlen+0x36>
f0104843:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0104848:	5b                   	pop    %ebx
f0104849:	5d                   	pop    %ebp
f010484a:	c3                   	ret    

f010484b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010484b:	55                   	push   %ebp
f010484c:	89 e5                	mov    %esp,%ebp
f010484e:	53                   	push   %ebx
f010484f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104852:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104855:	89 c2                	mov    %eax,%edx
f0104857:	0f b6 19             	movzbl (%ecx),%ebx
f010485a:	88 1a                	mov    %bl,(%edx)
f010485c:	83 c2 01             	add    $0x1,%edx
f010485f:	83 c1 01             	add    $0x1,%ecx
f0104862:	84 db                	test   %bl,%bl
f0104864:	75 f1                	jne    f0104857 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104866:	5b                   	pop    %ebx
f0104867:	5d                   	pop    %ebp
f0104868:	c3                   	ret    

f0104869 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104869:	55                   	push   %ebp
f010486a:	89 e5                	mov    %esp,%ebp
f010486c:	53                   	push   %ebx
f010486d:	83 ec 08             	sub    $0x8,%esp
f0104870:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104873:	89 1c 24             	mov    %ebx,(%esp)
f0104876:	e8 75 ff ff ff       	call   f01047f0 <strlen>
	strcpy(dst + len, src);
f010487b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010487e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104882:	01 d8                	add    %ebx,%eax
f0104884:	89 04 24             	mov    %eax,(%esp)
f0104887:	e8 bf ff ff ff       	call   f010484b <strcpy>
	return dst;
}
f010488c:	89 d8                	mov    %ebx,%eax
f010488e:	83 c4 08             	add    $0x8,%esp
f0104891:	5b                   	pop    %ebx
f0104892:	5d                   	pop    %ebp
f0104893:	c3                   	ret    

f0104894 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104894:	55                   	push   %ebp
f0104895:	89 e5                	mov    %esp,%ebp
f0104897:	56                   	push   %esi
f0104898:	53                   	push   %ebx
f0104899:	8b 75 08             	mov    0x8(%ebp),%esi
f010489c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010489f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01048a2:	85 db                	test   %ebx,%ebx
f01048a4:	74 16                	je     f01048bc <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f01048a6:	01 f3                	add    %esi,%ebx
f01048a8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f01048aa:	0f b6 02             	movzbl (%edx),%eax
f01048ad:	88 01                	mov    %al,(%ecx)
f01048af:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01048b2:	80 3a 01             	cmpb   $0x1,(%edx)
f01048b5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01048b8:	39 d9                	cmp    %ebx,%ecx
f01048ba:	75 ee                	jne    f01048aa <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01048bc:	89 f0                	mov    %esi,%eax
f01048be:	5b                   	pop    %ebx
f01048bf:	5e                   	pop    %esi
f01048c0:	5d                   	pop    %ebp
f01048c1:	c3                   	ret    

f01048c2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01048c2:	55                   	push   %ebp
f01048c3:	89 e5                	mov    %esp,%ebp
f01048c5:	57                   	push   %edi
f01048c6:	56                   	push   %esi
f01048c7:	53                   	push   %ebx
f01048c8:	8b 7d 08             	mov    0x8(%ebp),%edi
f01048cb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048ce:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01048d1:	89 f8                	mov    %edi,%eax
f01048d3:	85 f6                	test   %esi,%esi
f01048d5:	74 33                	je     f010490a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f01048d7:	83 fe 01             	cmp    $0x1,%esi
f01048da:	74 25                	je     f0104901 <strlcpy+0x3f>
f01048dc:	0f b6 0b             	movzbl (%ebx),%ecx
f01048df:	84 c9                	test   %cl,%cl
f01048e1:	74 22                	je     f0104905 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01048e3:	83 ee 02             	sub    $0x2,%esi
f01048e6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01048eb:	88 08                	mov    %cl,(%eax)
f01048ed:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01048f0:	39 f2                	cmp    %esi,%edx
f01048f2:	74 13                	je     f0104907 <strlcpy+0x45>
f01048f4:	83 c2 01             	add    $0x1,%edx
f01048f7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01048fb:	84 c9                	test   %cl,%cl
f01048fd:	75 ec                	jne    f01048eb <strlcpy+0x29>
f01048ff:	eb 06                	jmp    f0104907 <strlcpy+0x45>
f0104901:	89 f8                	mov    %edi,%eax
f0104903:	eb 02                	jmp    f0104907 <strlcpy+0x45>
f0104905:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104907:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010490a:	29 f8                	sub    %edi,%eax
}
f010490c:	5b                   	pop    %ebx
f010490d:	5e                   	pop    %esi
f010490e:	5f                   	pop    %edi
f010490f:	5d                   	pop    %ebp
f0104910:	c3                   	ret    

f0104911 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104911:	55                   	push   %ebp
f0104912:	89 e5                	mov    %esp,%ebp
f0104914:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104917:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010491a:	0f b6 01             	movzbl (%ecx),%eax
f010491d:	84 c0                	test   %al,%al
f010491f:	74 15                	je     f0104936 <strcmp+0x25>
f0104921:	3a 02                	cmp    (%edx),%al
f0104923:	75 11                	jne    f0104936 <strcmp+0x25>
		p++, q++;
f0104925:	83 c1 01             	add    $0x1,%ecx
f0104928:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010492b:	0f b6 01             	movzbl (%ecx),%eax
f010492e:	84 c0                	test   %al,%al
f0104930:	74 04                	je     f0104936 <strcmp+0x25>
f0104932:	3a 02                	cmp    (%edx),%al
f0104934:	74 ef                	je     f0104925 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104936:	0f b6 c0             	movzbl %al,%eax
f0104939:	0f b6 12             	movzbl (%edx),%edx
f010493c:	29 d0                	sub    %edx,%eax
}
f010493e:	5d                   	pop    %ebp
f010493f:	c3                   	ret    

f0104940 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104940:	55                   	push   %ebp
f0104941:	89 e5                	mov    %esp,%ebp
f0104943:	56                   	push   %esi
f0104944:	53                   	push   %ebx
f0104945:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104948:	8b 55 0c             	mov    0xc(%ebp),%edx
f010494b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f010494e:	85 f6                	test   %esi,%esi
f0104950:	74 29                	je     f010497b <strncmp+0x3b>
f0104952:	0f b6 03             	movzbl (%ebx),%eax
f0104955:	84 c0                	test   %al,%al
f0104957:	74 30                	je     f0104989 <strncmp+0x49>
f0104959:	3a 02                	cmp    (%edx),%al
f010495b:	75 2c                	jne    f0104989 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f010495d:	8d 43 01             	lea    0x1(%ebx),%eax
f0104960:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0104962:	89 c3                	mov    %eax,%ebx
f0104964:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104967:	39 f0                	cmp    %esi,%eax
f0104969:	74 17                	je     f0104982 <strncmp+0x42>
f010496b:	0f b6 08             	movzbl (%eax),%ecx
f010496e:	84 c9                	test   %cl,%cl
f0104970:	74 17                	je     f0104989 <strncmp+0x49>
f0104972:	83 c0 01             	add    $0x1,%eax
f0104975:	3a 0a                	cmp    (%edx),%cl
f0104977:	74 e9                	je     f0104962 <strncmp+0x22>
f0104979:	eb 0e                	jmp    f0104989 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010497b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104980:	eb 0f                	jmp    f0104991 <strncmp+0x51>
f0104982:	b8 00 00 00 00       	mov    $0x0,%eax
f0104987:	eb 08                	jmp    f0104991 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104989:	0f b6 03             	movzbl (%ebx),%eax
f010498c:	0f b6 12             	movzbl (%edx),%edx
f010498f:	29 d0                	sub    %edx,%eax
}
f0104991:	5b                   	pop    %ebx
f0104992:	5e                   	pop    %esi
f0104993:	5d                   	pop    %ebp
f0104994:	c3                   	ret    

f0104995 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104995:	55                   	push   %ebp
f0104996:	89 e5                	mov    %esp,%ebp
f0104998:	53                   	push   %ebx
f0104999:	8b 45 08             	mov    0x8(%ebp),%eax
f010499c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010499f:	0f b6 18             	movzbl (%eax),%ebx
f01049a2:	84 db                	test   %bl,%bl
f01049a4:	74 1d                	je     f01049c3 <strchr+0x2e>
f01049a6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01049a8:	38 d3                	cmp    %dl,%bl
f01049aa:	75 06                	jne    f01049b2 <strchr+0x1d>
f01049ac:	eb 1a                	jmp    f01049c8 <strchr+0x33>
f01049ae:	38 ca                	cmp    %cl,%dl
f01049b0:	74 16                	je     f01049c8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01049b2:	83 c0 01             	add    $0x1,%eax
f01049b5:	0f b6 10             	movzbl (%eax),%edx
f01049b8:	84 d2                	test   %dl,%dl
f01049ba:	75 f2                	jne    f01049ae <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f01049bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01049c1:	eb 05                	jmp    f01049c8 <strchr+0x33>
f01049c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01049c8:	5b                   	pop    %ebx
f01049c9:	5d                   	pop    %ebp
f01049ca:	c3                   	ret    

f01049cb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01049cb:	55                   	push   %ebp
f01049cc:	89 e5                	mov    %esp,%ebp
f01049ce:	53                   	push   %ebx
f01049cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01049d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01049d5:	0f b6 18             	movzbl (%eax),%ebx
f01049d8:	84 db                	test   %bl,%bl
f01049da:	74 16                	je     f01049f2 <strfind+0x27>
f01049dc:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01049de:	38 d3                	cmp    %dl,%bl
f01049e0:	75 06                	jne    f01049e8 <strfind+0x1d>
f01049e2:	eb 0e                	jmp    f01049f2 <strfind+0x27>
f01049e4:	38 ca                	cmp    %cl,%dl
f01049e6:	74 0a                	je     f01049f2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01049e8:	83 c0 01             	add    $0x1,%eax
f01049eb:	0f b6 10             	movzbl (%eax),%edx
f01049ee:	84 d2                	test   %dl,%dl
f01049f0:	75 f2                	jne    f01049e4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f01049f2:	5b                   	pop    %ebx
f01049f3:	5d                   	pop    %ebp
f01049f4:	c3                   	ret    

f01049f5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01049f5:	55                   	push   %ebp
f01049f6:	89 e5                	mov    %esp,%ebp
f01049f8:	83 ec 0c             	sub    $0xc,%esp
f01049fb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01049fe:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104a01:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104a04:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104a07:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104a0a:	85 c9                	test   %ecx,%ecx
f0104a0c:	74 36                	je     f0104a44 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104a0e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104a14:	75 28                	jne    f0104a3e <memset+0x49>
f0104a16:	f6 c1 03             	test   $0x3,%cl
f0104a19:	75 23                	jne    f0104a3e <memset+0x49>
		c &= 0xFF;
f0104a1b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104a1f:	89 d3                	mov    %edx,%ebx
f0104a21:	c1 e3 08             	shl    $0x8,%ebx
f0104a24:	89 d6                	mov    %edx,%esi
f0104a26:	c1 e6 18             	shl    $0x18,%esi
f0104a29:	89 d0                	mov    %edx,%eax
f0104a2b:	c1 e0 10             	shl    $0x10,%eax
f0104a2e:	09 f0                	or     %esi,%eax
f0104a30:	09 c2                	or     %eax,%edx
f0104a32:	89 d0                	mov    %edx,%eax
f0104a34:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104a36:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104a39:	fc                   	cld    
f0104a3a:	f3 ab                	rep stos %eax,%es:(%edi)
f0104a3c:	eb 06                	jmp    f0104a44 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104a3e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a41:	fc                   	cld    
f0104a42:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104a44:	89 f8                	mov    %edi,%eax
f0104a46:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104a49:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104a4c:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104a4f:	89 ec                	mov    %ebp,%esp
f0104a51:	5d                   	pop    %ebp
f0104a52:	c3                   	ret    

f0104a53 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104a53:	55                   	push   %ebp
f0104a54:	89 e5                	mov    %esp,%ebp
f0104a56:	83 ec 08             	sub    $0x8,%esp
f0104a59:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104a5c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104a5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a62:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104a65:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104a68:	39 c6                	cmp    %eax,%esi
f0104a6a:	73 36                	jae    f0104aa2 <memmove+0x4f>
f0104a6c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104a6f:	39 d0                	cmp    %edx,%eax
f0104a71:	73 2f                	jae    f0104aa2 <memmove+0x4f>
		s += n;
		d += n;
f0104a73:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104a76:	f6 c2 03             	test   $0x3,%dl
f0104a79:	75 1b                	jne    f0104a96 <memmove+0x43>
f0104a7b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104a81:	75 13                	jne    f0104a96 <memmove+0x43>
f0104a83:	f6 c1 03             	test   $0x3,%cl
f0104a86:	75 0e                	jne    f0104a96 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104a88:	83 ef 04             	sub    $0x4,%edi
f0104a8b:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104a8e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104a91:	fd                   	std    
f0104a92:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104a94:	eb 09                	jmp    f0104a9f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104a96:	83 ef 01             	sub    $0x1,%edi
f0104a99:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104a9c:	fd                   	std    
f0104a9d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104a9f:	fc                   	cld    
f0104aa0:	eb 20                	jmp    f0104ac2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104aa2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104aa8:	75 13                	jne    f0104abd <memmove+0x6a>
f0104aaa:	a8 03                	test   $0x3,%al
f0104aac:	75 0f                	jne    f0104abd <memmove+0x6a>
f0104aae:	f6 c1 03             	test   $0x3,%cl
f0104ab1:	75 0a                	jne    f0104abd <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104ab3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104ab6:	89 c7                	mov    %eax,%edi
f0104ab8:	fc                   	cld    
f0104ab9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104abb:	eb 05                	jmp    f0104ac2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104abd:	89 c7                	mov    %eax,%edi
f0104abf:	fc                   	cld    
f0104ac0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104ac2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104ac5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104ac8:	89 ec                	mov    %ebp,%esp
f0104aca:	5d                   	pop    %ebp
f0104acb:	c3                   	ret    

f0104acc <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0104acc:	55                   	push   %ebp
f0104acd:	89 e5                	mov    %esp,%ebp
f0104acf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104ad2:	8b 45 10             	mov    0x10(%ebp),%eax
f0104ad5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104ad9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104adc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ae0:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ae3:	89 04 24             	mov    %eax,(%esp)
f0104ae6:	e8 68 ff ff ff       	call   f0104a53 <memmove>
}
f0104aeb:	c9                   	leave  
f0104aec:	c3                   	ret    

f0104aed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104aed:	55                   	push   %ebp
f0104aee:	89 e5                	mov    %esp,%ebp
f0104af0:	57                   	push   %edi
f0104af1:	56                   	push   %esi
f0104af2:	53                   	push   %ebx
f0104af3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104af6:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104af9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104afc:	8d 78 ff             	lea    -0x1(%eax),%edi
f0104aff:	85 c0                	test   %eax,%eax
f0104b01:	74 36                	je     f0104b39 <memcmp+0x4c>
		if (*s1 != *s2)
f0104b03:	0f b6 03             	movzbl (%ebx),%eax
f0104b06:	0f b6 0e             	movzbl (%esi),%ecx
f0104b09:	38 c8                	cmp    %cl,%al
f0104b0b:	75 17                	jne    f0104b24 <memcmp+0x37>
f0104b0d:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b12:	eb 1a                	jmp    f0104b2e <memcmp+0x41>
f0104b14:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0104b19:	83 c2 01             	add    $0x1,%edx
f0104b1c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0104b20:	38 c8                	cmp    %cl,%al
f0104b22:	74 0a                	je     f0104b2e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0104b24:	0f b6 c0             	movzbl %al,%eax
f0104b27:	0f b6 c9             	movzbl %cl,%ecx
f0104b2a:	29 c8                	sub    %ecx,%eax
f0104b2c:	eb 10                	jmp    f0104b3e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104b2e:	39 fa                	cmp    %edi,%edx
f0104b30:	75 e2                	jne    f0104b14 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104b32:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b37:	eb 05                	jmp    f0104b3e <memcmp+0x51>
f0104b39:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104b3e:	5b                   	pop    %ebx
f0104b3f:	5e                   	pop    %esi
f0104b40:	5f                   	pop    %edi
f0104b41:	5d                   	pop    %ebp
f0104b42:	c3                   	ret    

f0104b43 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104b43:	55                   	push   %ebp
f0104b44:	89 e5                	mov    %esp,%ebp
f0104b46:	53                   	push   %ebx
f0104b47:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b4a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0104b4d:	89 c2                	mov    %eax,%edx
f0104b4f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104b52:	39 d0                	cmp    %edx,%eax
f0104b54:	73 13                	jae    f0104b69 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104b56:	89 d9                	mov    %ebx,%ecx
f0104b58:	38 18                	cmp    %bl,(%eax)
f0104b5a:	75 06                	jne    f0104b62 <memfind+0x1f>
f0104b5c:	eb 0b                	jmp    f0104b69 <memfind+0x26>
f0104b5e:	38 08                	cmp    %cl,(%eax)
f0104b60:	74 07                	je     f0104b69 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104b62:	83 c0 01             	add    $0x1,%eax
f0104b65:	39 d0                	cmp    %edx,%eax
f0104b67:	75 f5                	jne    f0104b5e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104b69:	5b                   	pop    %ebx
f0104b6a:	5d                   	pop    %ebp
f0104b6b:	c3                   	ret    

f0104b6c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104b6c:	55                   	push   %ebp
f0104b6d:	89 e5                	mov    %esp,%ebp
f0104b6f:	57                   	push   %edi
f0104b70:	56                   	push   %esi
f0104b71:	53                   	push   %ebx
f0104b72:	83 ec 04             	sub    $0x4,%esp
f0104b75:	8b 55 08             	mov    0x8(%ebp),%edx
f0104b78:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104b7b:	0f b6 02             	movzbl (%edx),%eax
f0104b7e:	3c 09                	cmp    $0x9,%al
f0104b80:	74 04                	je     f0104b86 <strtol+0x1a>
f0104b82:	3c 20                	cmp    $0x20,%al
f0104b84:	75 0e                	jne    f0104b94 <strtol+0x28>
		s++;
f0104b86:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104b89:	0f b6 02             	movzbl (%edx),%eax
f0104b8c:	3c 09                	cmp    $0x9,%al
f0104b8e:	74 f6                	je     f0104b86 <strtol+0x1a>
f0104b90:	3c 20                	cmp    $0x20,%al
f0104b92:	74 f2                	je     f0104b86 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104b94:	3c 2b                	cmp    $0x2b,%al
f0104b96:	75 0a                	jne    f0104ba2 <strtol+0x36>
		s++;
f0104b98:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104b9b:	bf 00 00 00 00       	mov    $0x0,%edi
f0104ba0:	eb 10                	jmp    f0104bb2 <strtol+0x46>
f0104ba2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104ba7:	3c 2d                	cmp    $0x2d,%al
f0104ba9:	75 07                	jne    f0104bb2 <strtol+0x46>
		s++, neg = 1;
f0104bab:	83 c2 01             	add    $0x1,%edx
f0104bae:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104bb2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104bb8:	75 15                	jne    f0104bcf <strtol+0x63>
f0104bba:	80 3a 30             	cmpb   $0x30,(%edx)
f0104bbd:	75 10                	jne    f0104bcf <strtol+0x63>
f0104bbf:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104bc3:	75 0a                	jne    f0104bcf <strtol+0x63>
		s += 2, base = 16;
f0104bc5:	83 c2 02             	add    $0x2,%edx
f0104bc8:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104bcd:	eb 10                	jmp    f0104bdf <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0104bcf:	85 db                	test   %ebx,%ebx
f0104bd1:	75 0c                	jne    f0104bdf <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104bd3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104bd5:	80 3a 30             	cmpb   $0x30,(%edx)
f0104bd8:	75 05                	jne    f0104bdf <strtol+0x73>
		s++, base = 8;
f0104bda:	83 c2 01             	add    $0x1,%edx
f0104bdd:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0104bdf:	b8 00 00 00 00       	mov    $0x0,%eax
f0104be4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104be7:	0f b6 0a             	movzbl (%edx),%ecx
f0104bea:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104bed:	89 f3                	mov    %esi,%ebx
f0104bef:	80 fb 09             	cmp    $0x9,%bl
f0104bf2:	77 08                	ja     f0104bfc <strtol+0x90>
			dig = *s - '0';
f0104bf4:	0f be c9             	movsbl %cl,%ecx
f0104bf7:	83 e9 30             	sub    $0x30,%ecx
f0104bfa:	eb 22                	jmp    f0104c1e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0104bfc:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104bff:	89 f3                	mov    %esi,%ebx
f0104c01:	80 fb 19             	cmp    $0x19,%bl
f0104c04:	77 08                	ja     f0104c0e <strtol+0xa2>
			dig = *s - 'a' + 10;
f0104c06:	0f be c9             	movsbl %cl,%ecx
f0104c09:	83 e9 57             	sub    $0x57,%ecx
f0104c0c:	eb 10                	jmp    f0104c1e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0104c0e:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104c11:	89 f3                	mov    %esi,%ebx
f0104c13:	80 fb 19             	cmp    $0x19,%bl
f0104c16:	77 16                	ja     f0104c2e <strtol+0xc2>
			dig = *s - 'A' + 10;
f0104c18:	0f be c9             	movsbl %cl,%ecx
f0104c1b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104c1e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0104c21:	7d 0f                	jge    f0104c32 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0104c23:	83 c2 01             	add    $0x1,%edx
f0104c26:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0104c2a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0104c2c:	eb b9                	jmp    f0104be7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104c2e:	89 c1                	mov    %eax,%ecx
f0104c30:	eb 02                	jmp    f0104c34 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104c32:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104c34:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104c38:	74 05                	je     f0104c3f <strtol+0xd3>
		*endptr = (char *) s;
f0104c3a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104c3d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104c3f:	89 ca                	mov    %ecx,%edx
f0104c41:	f7 da                	neg    %edx
f0104c43:	85 ff                	test   %edi,%edi
f0104c45:	0f 45 c2             	cmovne %edx,%eax
}
f0104c48:	83 c4 04             	add    $0x4,%esp
f0104c4b:	5b                   	pop    %ebx
f0104c4c:	5e                   	pop    %esi
f0104c4d:	5f                   	pop    %edi
f0104c4e:	5d                   	pop    %ebp
f0104c4f:	c3                   	ret    

f0104c50 <__udivdi3>:
f0104c50:	83 ec 1c             	sub    $0x1c,%esp
f0104c53:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0104c57:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104c5b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104c5f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104c63:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0104c67:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f0104c6b:	85 c0                	test   %eax,%eax
f0104c6d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104c71:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104c75:	89 ea                	mov    %ebp,%edx
f0104c77:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104c7b:	75 33                	jne    f0104cb0 <__udivdi3+0x60>
f0104c7d:	39 e9                	cmp    %ebp,%ecx
f0104c7f:	77 6f                	ja     f0104cf0 <__udivdi3+0xa0>
f0104c81:	85 c9                	test   %ecx,%ecx
f0104c83:	89 ce                	mov    %ecx,%esi
f0104c85:	75 0b                	jne    f0104c92 <__udivdi3+0x42>
f0104c87:	b8 01 00 00 00       	mov    $0x1,%eax
f0104c8c:	31 d2                	xor    %edx,%edx
f0104c8e:	f7 f1                	div    %ecx
f0104c90:	89 c6                	mov    %eax,%esi
f0104c92:	31 d2                	xor    %edx,%edx
f0104c94:	89 e8                	mov    %ebp,%eax
f0104c96:	f7 f6                	div    %esi
f0104c98:	89 c5                	mov    %eax,%ebp
f0104c9a:	89 f8                	mov    %edi,%eax
f0104c9c:	f7 f6                	div    %esi
f0104c9e:	89 ea                	mov    %ebp,%edx
f0104ca0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104ca4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104ca8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104cac:	83 c4 1c             	add    $0x1c,%esp
f0104caf:	c3                   	ret    
f0104cb0:	39 e8                	cmp    %ebp,%eax
f0104cb2:	77 24                	ja     f0104cd8 <__udivdi3+0x88>
f0104cb4:	0f bd c8             	bsr    %eax,%ecx
f0104cb7:	83 f1 1f             	xor    $0x1f,%ecx
f0104cba:	89 0c 24             	mov    %ecx,(%esp)
f0104cbd:	75 49                	jne    f0104d08 <__udivdi3+0xb8>
f0104cbf:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104cc3:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0104cc7:	0f 86 ab 00 00 00    	jbe    f0104d78 <__udivdi3+0x128>
f0104ccd:	39 e8                	cmp    %ebp,%eax
f0104ccf:	0f 82 a3 00 00 00    	jb     f0104d78 <__udivdi3+0x128>
f0104cd5:	8d 76 00             	lea    0x0(%esi),%esi
f0104cd8:	31 d2                	xor    %edx,%edx
f0104cda:	31 c0                	xor    %eax,%eax
f0104cdc:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104ce0:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104ce4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104ce8:	83 c4 1c             	add    $0x1c,%esp
f0104ceb:	c3                   	ret    
f0104cec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104cf0:	89 f8                	mov    %edi,%eax
f0104cf2:	f7 f1                	div    %ecx
f0104cf4:	31 d2                	xor    %edx,%edx
f0104cf6:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104cfa:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104cfe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104d02:	83 c4 1c             	add    $0x1c,%esp
f0104d05:	c3                   	ret    
f0104d06:	66 90                	xchg   %ax,%ax
f0104d08:	0f b6 0c 24          	movzbl (%esp),%ecx
f0104d0c:	89 c6                	mov    %eax,%esi
f0104d0e:	b8 20 00 00 00       	mov    $0x20,%eax
f0104d13:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0104d17:	2b 04 24             	sub    (%esp),%eax
f0104d1a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104d1e:	d3 e6                	shl    %cl,%esi
f0104d20:	89 c1                	mov    %eax,%ecx
f0104d22:	d3 ed                	shr    %cl,%ebp
f0104d24:	0f b6 0c 24          	movzbl (%esp),%ecx
f0104d28:	09 f5                	or     %esi,%ebp
f0104d2a:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104d2e:	d3 e6                	shl    %cl,%esi
f0104d30:	89 c1                	mov    %eax,%ecx
f0104d32:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104d36:	89 d6                	mov    %edx,%esi
f0104d38:	d3 ee                	shr    %cl,%esi
f0104d3a:	0f b6 0c 24          	movzbl (%esp),%ecx
f0104d3e:	d3 e2                	shl    %cl,%edx
f0104d40:	89 c1                	mov    %eax,%ecx
f0104d42:	d3 ef                	shr    %cl,%edi
f0104d44:	09 d7                	or     %edx,%edi
f0104d46:	89 f2                	mov    %esi,%edx
f0104d48:	89 f8                	mov    %edi,%eax
f0104d4a:	f7 f5                	div    %ebp
f0104d4c:	89 d6                	mov    %edx,%esi
f0104d4e:	89 c7                	mov    %eax,%edi
f0104d50:	f7 64 24 04          	mull   0x4(%esp)
f0104d54:	39 d6                	cmp    %edx,%esi
f0104d56:	72 30                	jb     f0104d88 <__udivdi3+0x138>
f0104d58:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104d5c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0104d60:	d3 e5                	shl    %cl,%ebp
f0104d62:	39 c5                	cmp    %eax,%ebp
f0104d64:	73 04                	jae    f0104d6a <__udivdi3+0x11a>
f0104d66:	39 d6                	cmp    %edx,%esi
f0104d68:	74 1e                	je     f0104d88 <__udivdi3+0x138>
f0104d6a:	89 f8                	mov    %edi,%eax
f0104d6c:	31 d2                	xor    %edx,%edx
f0104d6e:	e9 69 ff ff ff       	jmp    f0104cdc <__udivdi3+0x8c>
f0104d73:	90                   	nop
f0104d74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104d78:	31 d2                	xor    %edx,%edx
f0104d7a:	b8 01 00 00 00       	mov    $0x1,%eax
f0104d7f:	e9 58 ff ff ff       	jmp    f0104cdc <__udivdi3+0x8c>
f0104d84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104d88:	8d 47 ff             	lea    -0x1(%edi),%eax
f0104d8b:	31 d2                	xor    %edx,%edx
f0104d8d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104d91:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104d95:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104d99:	83 c4 1c             	add    $0x1c,%esp
f0104d9c:	c3                   	ret    
f0104d9d:	66 90                	xchg   %ax,%ax
f0104d9f:	90                   	nop

f0104da0 <__umoddi3>:
f0104da0:	83 ec 2c             	sub    $0x2c,%esp
f0104da3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0104da7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0104dab:	89 74 24 20          	mov    %esi,0x20(%esp)
f0104daf:	8b 74 24 38          	mov    0x38(%esp),%esi
f0104db3:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0104db7:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0104dbb:	85 c0                	test   %eax,%eax
f0104dbd:	89 c2                	mov    %eax,%edx
f0104dbf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0104dc3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0104dc7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104dcb:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104dcf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0104dd3:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0104dd7:	75 1f                	jne    f0104df8 <__umoddi3+0x58>
f0104dd9:	39 fe                	cmp    %edi,%esi
f0104ddb:	76 63                	jbe    f0104e40 <__umoddi3+0xa0>
f0104ddd:	89 c8                	mov    %ecx,%eax
f0104ddf:	89 fa                	mov    %edi,%edx
f0104de1:	f7 f6                	div    %esi
f0104de3:	89 d0                	mov    %edx,%eax
f0104de5:	31 d2                	xor    %edx,%edx
f0104de7:	8b 74 24 20          	mov    0x20(%esp),%esi
f0104deb:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0104def:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0104df3:	83 c4 2c             	add    $0x2c,%esp
f0104df6:	c3                   	ret    
f0104df7:	90                   	nop
f0104df8:	39 f8                	cmp    %edi,%eax
f0104dfa:	77 64                	ja     f0104e60 <__umoddi3+0xc0>
f0104dfc:	0f bd e8             	bsr    %eax,%ebp
f0104dff:	83 f5 1f             	xor    $0x1f,%ebp
f0104e02:	75 74                	jne    f0104e78 <__umoddi3+0xd8>
f0104e04:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104e08:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f0104e0c:	0f 87 0e 01 00 00    	ja     f0104f20 <__umoddi3+0x180>
f0104e12:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0104e16:	29 f1                	sub    %esi,%ecx
f0104e18:	19 c7                	sbb    %eax,%edi
f0104e1a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0104e1e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0104e22:	8b 44 24 14          	mov    0x14(%esp),%eax
f0104e26:	8b 54 24 18          	mov    0x18(%esp),%edx
f0104e2a:	8b 74 24 20          	mov    0x20(%esp),%esi
f0104e2e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0104e32:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0104e36:	83 c4 2c             	add    $0x2c,%esp
f0104e39:	c3                   	ret    
f0104e3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104e40:	85 f6                	test   %esi,%esi
f0104e42:	89 f5                	mov    %esi,%ebp
f0104e44:	75 0b                	jne    f0104e51 <__umoddi3+0xb1>
f0104e46:	b8 01 00 00 00       	mov    $0x1,%eax
f0104e4b:	31 d2                	xor    %edx,%edx
f0104e4d:	f7 f6                	div    %esi
f0104e4f:	89 c5                	mov    %eax,%ebp
f0104e51:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104e55:	31 d2                	xor    %edx,%edx
f0104e57:	f7 f5                	div    %ebp
f0104e59:	89 c8                	mov    %ecx,%eax
f0104e5b:	f7 f5                	div    %ebp
f0104e5d:	eb 84                	jmp    f0104de3 <__umoddi3+0x43>
f0104e5f:	90                   	nop
f0104e60:	89 c8                	mov    %ecx,%eax
f0104e62:	89 fa                	mov    %edi,%edx
f0104e64:	8b 74 24 20          	mov    0x20(%esp),%esi
f0104e68:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0104e6c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0104e70:	83 c4 2c             	add    $0x2c,%esp
f0104e73:	c3                   	ret    
f0104e74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104e78:	8b 44 24 10          	mov    0x10(%esp),%eax
f0104e7c:	be 20 00 00 00       	mov    $0x20,%esi
f0104e81:	89 e9                	mov    %ebp,%ecx
f0104e83:	29 ee                	sub    %ebp,%esi
f0104e85:	d3 e2                	shl    %cl,%edx
f0104e87:	89 f1                	mov    %esi,%ecx
f0104e89:	d3 e8                	shr    %cl,%eax
f0104e8b:	89 e9                	mov    %ebp,%ecx
f0104e8d:	09 d0                	or     %edx,%eax
f0104e8f:	89 fa                	mov    %edi,%edx
f0104e91:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104e95:	8b 44 24 10          	mov    0x10(%esp),%eax
f0104e99:	d3 e0                	shl    %cl,%eax
f0104e9b:	89 f1                	mov    %esi,%ecx
f0104e9d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104ea1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0104ea5:	d3 ea                	shr    %cl,%edx
f0104ea7:	89 e9                	mov    %ebp,%ecx
f0104ea9:	d3 e7                	shl    %cl,%edi
f0104eab:	89 f1                	mov    %esi,%ecx
f0104ead:	d3 e8                	shr    %cl,%eax
f0104eaf:	89 e9                	mov    %ebp,%ecx
f0104eb1:	09 f8                	or     %edi,%eax
f0104eb3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104eb7:	f7 74 24 0c          	divl   0xc(%esp)
f0104ebb:	d3 e7                	shl    %cl,%edi
f0104ebd:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0104ec1:	89 d7                	mov    %edx,%edi
f0104ec3:	f7 64 24 10          	mull   0x10(%esp)
f0104ec7:	39 d7                	cmp    %edx,%edi
f0104ec9:	89 c1                	mov    %eax,%ecx
f0104ecb:	89 54 24 14          	mov    %edx,0x14(%esp)
f0104ecf:	72 3b                	jb     f0104f0c <__umoddi3+0x16c>
f0104ed1:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0104ed5:	72 31                	jb     f0104f08 <__umoddi3+0x168>
f0104ed7:	8b 44 24 18          	mov    0x18(%esp),%eax
f0104edb:	29 c8                	sub    %ecx,%eax
f0104edd:	19 d7                	sbb    %edx,%edi
f0104edf:	89 e9                	mov    %ebp,%ecx
f0104ee1:	89 fa                	mov    %edi,%edx
f0104ee3:	d3 e8                	shr    %cl,%eax
f0104ee5:	89 f1                	mov    %esi,%ecx
f0104ee7:	d3 e2                	shl    %cl,%edx
f0104ee9:	89 e9                	mov    %ebp,%ecx
f0104eeb:	09 d0                	or     %edx,%eax
f0104eed:	89 fa                	mov    %edi,%edx
f0104eef:	d3 ea                	shr    %cl,%edx
f0104ef1:	8b 74 24 20          	mov    0x20(%esp),%esi
f0104ef5:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0104ef9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0104efd:	83 c4 2c             	add    $0x2c,%esp
f0104f00:	c3                   	ret    
f0104f01:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104f08:	39 d7                	cmp    %edx,%edi
f0104f0a:	75 cb                	jne    f0104ed7 <__umoddi3+0x137>
f0104f0c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0104f10:	89 c1                	mov    %eax,%ecx
f0104f12:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0104f16:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0104f1a:	eb bb                	jmp    f0104ed7 <__umoddi3+0x137>
f0104f1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104f20:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0104f24:	0f 82 e8 fe ff ff    	jb     f0104e12 <__umoddi3+0x72>
f0104f2a:	e9 f3 fe ff ff       	jmp    f0104e22 <__umoddi3+0x82>

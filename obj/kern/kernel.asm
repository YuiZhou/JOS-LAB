
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
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 80 1b 10 f0 	movl   $0xf0101b80,(%esp)
f0100055:	e8 90 09 00 00       	call   f01009ea <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 11 07 00 00       	call   f0100798 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 1b 10 f0 	movl   $0xf0101b9c,(%esp)
f0100092:	e8 53 09 00 00       	call   f01009ea <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 80 15 00 00       	call   f0101645 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 9d 04 00 00       	call   f0100567 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 1b 10 f0 	movl   $0xf0101bb7,(%esp)
f01000d9:	e8 0c 09 00 00       	call   f01009ea <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 75 07 00 00       	call   f010086b <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 d2 1b 10 f0 	movl   $0xf0101bd2,(%esp)
f010012c:	e8 b9 08 00 00       	call   f01009ea <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 7a 08 00 00       	call   f01009b7 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 0e 1c 10 f0 	movl   $0xf0101c0e,(%esp)
f0100144:	e8 a1 08 00 00       	call   f01009ea <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 16 07 00 00       	call   f010086b <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ea 1b 10 f0 	movl   $0xf0101bea,(%esp)
f0100176:	e8 6f 08 00 00       	call   f01009ea <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 2d 08 00 00       	call   f01009b7 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 0e 1c 10 f0 	movl   $0xf0101c0e,(%esp)
f0100191:	e8 54 08 00 00       	call   f01009ea <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b7:	a8 01                	test   $0x1,%al
f01001b9:	74 08                	je     f01001c3 <serial_proc_data+0x15>
f01001bb:	b2 f8                	mov    $0xf8,%dl
f01001bd:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001be:	0f b6 c0             	movzbl %al,%eax
f01001c1:	eb 05                	jmp    f01001c8 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 26                	jmp    f01001fb <cons_intr+0x31>
		if (c == 0)
f01001d5:	85 d2                	test   %edx,%edx
f01001d7:	74 22                	je     f01001fb <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001de:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
f01001e4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001e7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f2:	0f 44 d0             	cmove  %eax,%edx
f01001f5:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fb:	ff d3                	call   *%ebx
f01001fd:	89 c2                	mov    %eax,%edx
f01001ff:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100202:	75 d1                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100204:	83 c4 04             	add    $0x4,%esp
f0100207:	5b                   	pop    %ebx
f0100208:	5d                   	pop    %ebp
f0100209:	c3                   	ret    

f010020a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010020a:	55                   	push   %ebp
f010020b:	89 e5                	mov    %esp,%ebp
f010020d:	57                   	push   %edi
f010020e:	56                   	push   %esi
f010020f:	53                   	push   %ebx
f0100210:	83 ec 2c             	sub    $0x2c,%esp
f0100213:	89 c7                	mov    %eax,%edi
f0100215:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010021a:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010021b:	a8 20                	test   $0x20,%al
f010021d:	75 1b                	jne    f010023a <cons_putc+0x30>
f010021f:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100224:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100229:	e8 72 ff ff ff       	call   f01001a0 <delay>
f010022e:	89 f2                	mov    %esi,%edx
f0100230:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100231:	a8 20                	test   $0x20,%al
f0100233:	75 05                	jne    f010023a <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100235:	83 eb 01             	sub    $0x1,%ebx
f0100238:	75 ef                	jne    f0100229 <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010023a:	89 f8                	mov    %edi,%eax
f010023c:	25 ff 00 00 00       	and    $0xff,%eax
f0100241:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100244:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100249:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010024a:	b2 79                	mov    $0x79,%dl
f010024c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010024d:	84 c0                	test   %al,%al
f010024f:	78 1b                	js     f010026c <cons_putc+0x62>
f0100251:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100256:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f010025b:	e8 40 ff ff ff       	call   f01001a0 <delay>
f0100260:	89 f2                	mov    %esi,%edx
f0100262:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100263:	84 c0                	test   %al,%al
f0100265:	78 05                	js     f010026c <cons_putc+0x62>
f0100267:	83 eb 01             	sub    $0x1,%ebx
f010026a:	75 ef                	jne    f010025b <cons_putc+0x51>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100271:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100275:	ee                   	out    %al,(%dx)
f0100276:	b2 7a                	mov    $0x7a,%dl
f0100278:	b8 0d 00 00 00       	mov    $0xd,%eax
f010027d:	ee                   	out    %al,(%dx)
f010027e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100283:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100284:	89 fa                	mov    %edi,%edx
f0100286:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010028c:	89 f8                	mov    %edi,%eax
f010028e:	80 cc 07             	or     $0x7,%ah
f0100291:	85 d2                	test   %edx,%edx
f0100293:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100296:	89 f8                	mov    %edi,%eax
f0100298:	25 ff 00 00 00       	and    $0xff,%eax
f010029d:	83 f8 09             	cmp    $0x9,%eax
f01002a0:	74 77                	je     f0100319 <cons_putc+0x10f>
f01002a2:	83 f8 09             	cmp    $0x9,%eax
f01002a5:	7f 0b                	jg     f01002b2 <cons_putc+0xa8>
f01002a7:	83 f8 08             	cmp    $0x8,%eax
f01002aa:	0f 85 9d 00 00 00    	jne    f010034d <cons_putc+0x143>
f01002b0:	eb 10                	jmp    f01002c2 <cons_putc+0xb8>
f01002b2:	83 f8 0a             	cmp    $0xa,%eax
f01002b5:	74 3c                	je     f01002f3 <cons_putc+0xe9>
f01002b7:	83 f8 0d             	cmp    $0xd,%eax
f01002ba:	0f 85 8d 00 00 00    	jne    f010034d <cons_putc+0x143>
f01002c0:	eb 39                	jmp    f01002fb <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f01002c2:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002c9:	66 85 c0             	test   %ax,%ax
f01002cc:	0f 84 e5 00 00 00    	je     f01003b7 <cons_putc+0x1ad>
			crt_pos--;
f01002d2:	83 e8 01             	sub    $0x1,%eax
f01002d5:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002db:	0f b7 c0             	movzwl %ax,%eax
f01002de:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002e4:	83 cf 20             	or     $0x20,%edi
f01002e7:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002ed:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f1:	eb 77                	jmp    f010036a <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002f3:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002fa:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002fb:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100302:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100308:	c1 e8 16             	shr    $0x16,%eax
f010030b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010030e:	c1 e0 04             	shl    $0x4,%eax
f0100311:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f0100317:	eb 51                	jmp    f010036a <cons_putc+0x160>
		break;
	case '\t':
		cons_putc(' ');
f0100319:	b8 20 00 00 00       	mov    $0x20,%eax
f010031e:	e8 e7 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100323:	b8 20 00 00 00       	mov    $0x20,%eax
f0100328:	e8 dd fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f010032d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100332:	e8 d3 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100337:	b8 20 00 00 00       	mov    $0x20,%eax
f010033c:	e8 c9 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100341:	b8 20 00 00 00       	mov    $0x20,%eax
f0100346:	e8 bf fe ff ff       	call   f010020a <cons_putc>
f010034b:	eb 1d                	jmp    f010036a <cons_putc+0x160>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010034d:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100354:	0f b7 c8             	movzwl %ax,%ecx
f0100357:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f010035d:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100361:	83 c0 01             	add    $0x1,%eax
f0100364:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010036a:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100371:	cf 07 
f0100373:	76 42                	jbe    f01003b7 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100375:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f010037a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100381:	00 
f0100382:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100388:	89 54 24 04          	mov    %edx,0x4(%esp)
f010038c:	89 04 24             	mov    %eax,(%esp)
f010038f:	e8 0f 13 00 00       	call   f01016a3 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100394:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010039a:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010039f:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a5:	83 c0 01             	add    $0x1,%eax
f01003a8:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003ad:	75 f0                	jne    f010039f <cons_putc+0x195>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003af:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003b6:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003b7:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003bd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003c2:	89 ca                	mov    %ecx,%edx
f01003c4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003c5:	0f b7 1d 34 25 11 f0 	movzwl 0xf0112534,%ebx
f01003cc:	8d 71 01             	lea    0x1(%ecx),%esi
f01003cf:	89 d8                	mov    %ebx,%eax
f01003d1:	66 c1 e8 08          	shr    $0x8,%ax
f01003d5:	89 f2                	mov    %esi,%edx
f01003d7:	ee                   	out    %al,(%dx)
f01003d8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003dd:	89 ca                	mov    %ecx,%edx
f01003df:	ee                   	out    %al,(%dx)
f01003e0:	89 d8                	mov    %ebx,%eax
f01003e2:	89 f2                	mov    %esi,%edx
f01003e4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003e5:	83 c4 2c             	add    $0x2c,%esp
f01003e8:	5b                   	pop    %ebx
f01003e9:	5e                   	pop    %esi
f01003ea:	5f                   	pop    %edi
f01003eb:	5d                   	pop    %ebp
f01003ec:	c3                   	ret    

f01003ed <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003ed:	55                   	push   %ebp
f01003ee:	89 e5                	mov    %esp,%ebp
f01003f0:	53                   	push   %ebx
f01003f1:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f4:	ba 64 00 00 00       	mov    $0x64,%edx
f01003f9:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003fa:	a8 01                	test   $0x1,%al
f01003fc:	0f 84 e5 00 00 00    	je     f01004e7 <kbd_proc_data+0xfa>
f0100402:	b2 60                	mov    $0x60,%dl
f0100404:	ec                   	in     (%dx),%al
f0100405:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100407:	3c e0                	cmp    $0xe0,%al
f0100409:	75 11                	jne    f010041c <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f010040b:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f0100412:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100417:	e9 d0 00 00 00       	jmp    f01004ec <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f010041c:	84 c0                	test   %al,%al
f010041e:	79 37                	jns    f0100457 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100420:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100426:	89 cb                	mov    %ecx,%ebx
f0100428:	83 e3 40             	and    $0x40,%ebx
f010042b:	83 e0 7f             	and    $0x7f,%eax
f010042e:	85 db                	test   %ebx,%ebx
f0100430:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100433:	0f b6 d2             	movzbl %dl,%edx
f0100436:	0f b6 82 40 1c 10 f0 	movzbl -0xfefe3c0(%edx),%eax
f010043d:	83 c8 40             	or     $0x40,%eax
f0100440:	0f b6 c0             	movzbl %al,%eax
f0100443:	f7 d0                	not    %eax
f0100445:	21 c1                	and    %eax,%ecx
f0100447:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f010044d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100452:	e9 95 00 00 00       	jmp    f01004ec <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f0100457:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010045d:	f6 c1 40             	test   $0x40,%cl
f0100460:	74 0e                	je     f0100470 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100462:	89 c2                	mov    %eax,%edx
f0100464:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100467:	83 e1 bf             	and    $0xffffffbf,%ecx
f010046a:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	}

	shift |= shiftcode[data];
f0100470:	0f b6 d2             	movzbl %dl,%edx
f0100473:	0f b6 82 40 1c 10 f0 	movzbl -0xfefe3c0(%edx),%eax
f010047a:	0b 05 28 25 11 f0    	or     0xf0112528,%eax
	shift ^= togglecode[data];
f0100480:	0f b6 8a 40 1d 10 f0 	movzbl -0xfefe2c0(%edx),%ecx
f0100487:	31 c8                	xor    %ecx,%eax
f0100489:	a3 28 25 11 f0       	mov    %eax,0xf0112528

	c = charcode[shift & (CTL | SHIFT)][data];
f010048e:	89 c1                	mov    %eax,%ecx
f0100490:	83 e1 03             	and    $0x3,%ecx
f0100493:	8b 0c 8d 40 1e 10 f0 	mov    -0xfefe1c0(,%ecx,4),%ecx
f010049a:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010049e:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01004a1:	a8 08                	test   $0x8,%al
f01004a3:	74 1b                	je     f01004c0 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004a5:	89 da                	mov    %ebx,%edx
f01004a7:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004aa:	83 f9 19             	cmp    $0x19,%ecx
f01004ad:	77 05                	ja     f01004b4 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004af:	83 eb 20             	sub    $0x20,%ebx
f01004b2:	eb 0c                	jmp    f01004c0 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004b4:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01004b7:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004ba:	83 fa 19             	cmp    $0x19,%edx
f01004bd:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004c0:	f7 d0                	not    %eax
f01004c2:	a8 06                	test   $0x6,%al
f01004c4:	75 26                	jne    f01004ec <kbd_proc_data+0xff>
f01004c6:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004cc:	75 1e                	jne    f01004ec <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f01004ce:	c7 04 24 04 1c 10 f0 	movl   $0xf0101c04,(%esp)
f01004d5:	e8 10 05 00 00       	call   f01009ea <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004da:	ba 92 00 00 00       	mov    $0x92,%edx
f01004df:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e4:	ee                   	out    %al,(%dx)
f01004e5:	eb 05                	jmp    f01004ec <kbd_proc_data+0xff>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01004e7:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004ec:	89 d8                	mov    %ebx,%eax
f01004ee:	83 c4 14             	add    $0x14,%esp
f01004f1:	5b                   	pop    %ebx
f01004f2:	5d                   	pop    %ebp
f01004f3:	c3                   	ret    

f01004f4 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f4:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f01004fb:	74 11                	je     f010050e <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004fd:	55                   	push   %ebp
f01004fe:	89 e5                	mov    %esp,%ebp
f0100500:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100503:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100508:	e8 bd fc ff ff       	call   f01001ca <cons_intr>
}
f010050d:	c9                   	leave  
f010050e:	f3 c3                	repz ret 

f0100510 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100510:	55                   	push   %ebp
f0100511:	89 e5                	mov    %esp,%ebp
f0100513:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100516:	b8 ed 03 10 f0       	mov    $0xf01003ed,%eax
f010051b:	e8 aa fc ff ff       	call   f01001ca <cons_intr>
}
f0100520:	c9                   	leave  
f0100521:	c3                   	ret    

f0100522 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100522:	55                   	push   %ebp
f0100523:	89 e5                	mov    %esp,%ebp
f0100525:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100528:	e8 c7 ff ff ff       	call   f01004f4 <serial_intr>
	kbd_intr();
f010052d:	e8 de ff ff ff       	call   f0100510 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100532:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
f0100538:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f010053e:	74 20                	je     f0100560 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f0100540:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f0100547:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010054a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f0100550:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100555:	0f 44 d1             	cmove  %ecx,%edx
f0100558:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010055e:	eb 05                	jmp    f0100565 <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100560:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100565:	c9                   	leave  
f0100566:	c3                   	ret    

f0100567 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100567:	55                   	push   %ebp
f0100568:	89 e5                	mov    %esp,%ebp
f010056a:	57                   	push   %edi
f010056b:	56                   	push   %esi
f010056c:	53                   	push   %ebx
f010056d:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100570:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100577:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010057e:	5a a5 
	if (*cp != 0xA55A) {
f0100580:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100587:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010058b:	74 11                	je     f010059e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010058d:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f0100594:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100597:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010059c:	eb 16                	jmp    f01005b4 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010059e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a5:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f01005ac:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005af:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b4:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005ba:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005bf:	89 ca                	mov    %ecx,%edx
f01005c1:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c2:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c5:	89 da                	mov    %ebx,%edx
f01005c7:	ec                   	in     (%dx),%al
f01005c8:	0f b6 f0             	movzbl %al,%esi
f01005cb:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ce:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d3:	89 ca                	mov    %ecx,%edx
f01005d5:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d6:	89 da                	mov    %ebx,%edx
f01005d8:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d9:	89 3d 30 25 11 f0    	mov    %edi,0xf0112530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005df:	0f b6 d8             	movzbl %al,%ebx
f01005e2:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e4:	66 89 35 34 25 11 f0 	mov    %si,0xf0112534
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005eb:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f5:	89 f2                	mov    %esi,%edx
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	b2 fb                	mov    $0xfb,%dl
f01005fa:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100605:	b8 0c 00 00 00       	mov    $0xc,%eax
f010060a:	89 da                	mov    %ebx,%edx
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 f9                	mov    $0xf9,%dl
f010060f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fb                	mov    $0xfb,%dl
f0100617:	b8 03 00 00 00       	mov    $0x3,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fc                	mov    $0xfc,%dl
f010061f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 f9                	mov    $0xf9,%dl
f0100627:	b8 01 00 00 00       	mov    $0x1,%eax
f010062c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010062d:	b2 fd                	mov    $0xfd,%dl
f010062f:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100630:	3c ff                	cmp    $0xff,%al
f0100632:	0f 95 c1             	setne  %cl
f0100635:	88 0d 00 23 11 f0    	mov    %cl,0xf0112300
f010063b:	89 f2                	mov    %esi,%edx
f010063d:	ec                   	in     (%dx),%al
f010063e:	89 da                	mov    %ebx,%edx
f0100640:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100641:	84 c9                	test   %cl,%cl
f0100643:	75 0c                	jne    f0100651 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f0100645:	c7 04 24 10 1c 10 f0 	movl   $0xf0101c10,(%esp)
f010064c:	e8 99 03 00 00       	call   f01009ea <cprintf>
}
f0100651:	83 c4 1c             	add    $0x1c,%esp
f0100654:	5b                   	pop    %ebx
f0100655:	5e                   	pop    %esi
f0100656:	5f                   	pop    %edi
f0100657:	5d                   	pop    %ebp
f0100658:	c3                   	ret    

f0100659 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100659:	55                   	push   %ebp
f010065a:	89 e5                	mov    %esp,%ebp
f010065c:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010065f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100662:	e8 a3 fb ff ff       	call   f010020a <cons_putc>
}
f0100667:	c9                   	leave  
f0100668:	c3                   	ret    

f0100669 <getchar>:

int
getchar(void)
{
f0100669:	55                   	push   %ebp
f010066a:	89 e5                	mov    %esp,%ebp
f010066c:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010066f:	e8 ae fe ff ff       	call   f0100522 <cons_getc>
f0100674:	85 c0                	test   %eax,%eax
f0100676:	74 f7                	je     f010066f <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <iscons>:

int
iscons(int fdnum)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100682:	5d                   	pop    %ebp
f0100683:	c3                   	ret    
f0100684:	66 90                	xchg   %ax,%ax
f0100686:	66 90                	xchg   %ax,%ax
f0100688:	66 90                	xchg   %ax,%ax
f010068a:	66 90                	xchg   %ax,%ax
f010068c:	66 90                	xchg   %ax,%ax
f010068e:	66 90                	xchg   %ax,%ax

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 50 1e 10 f0 	movl   $0xf0101e50,(%esp)
f010069d:	e8 48 03 00 00       	call   f01009ea <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a2:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006a9:	00 
f01006aa:	c7 04 24 38 1f 10 f0 	movl   $0xf0101f38,(%esp)
f01006b1:	e8 34 03 00 00       	call   f01009ea <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 60 1f 10 f0 	movl   $0xf0101f60,(%esp)
f01006cd:	e8 18 03 00 00       	call   f01009ea <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d2:	c7 44 24 08 7f 1b 10 	movl   $0x101b7f,0x8(%esp)
f01006d9:	00 
f01006da:	c7 44 24 04 7f 1b 10 	movl   $0xf0101b7f,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 84 1f 10 f0 	movl   $0xf0101f84,(%esp)
f01006e9:	e8 fc 02 00 00       	call   f01009ea <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006f5:	00 
f01006f6:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 a8 1f 10 f0 	movl   $0xf0101fa8,(%esp)
f0100705:	e8 e0 02 00 00       	call   f01009ea <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070a:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 cc 1f 10 f0 	movl   $0xf0101fcc,(%esp)
f0100721:	e8 c4 02 00 00       	call   f01009ea <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010072b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100730:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100735:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073b:	85 c0                	test   %eax,%eax
f010073d:	0f 48 c2             	cmovs  %edx,%eax
f0100740:	c1 f8 0a             	sar    $0xa,%eax
f0100743:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100747:	c7 04 24 f0 1f 10 f0 	movl   $0xf0101ff0,(%esp)
f010074e:	e8 97 02 00 00       	call   f01009ea <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100753:	b8 00 00 00 00       	mov    $0x0,%eax
f0100758:	c9                   	leave  
f0100759:	c3                   	ret    

f010075a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010075a:	55                   	push   %ebp
f010075b:	89 e5                	mov    %esp,%ebp
f010075d:	56                   	push   %esi
f010075e:	53                   	push   %ebx
f010075f:	83 ec 10             	sub    $0x10,%esp
f0100762:	bb a4 20 10 f0       	mov    $0xf01020a4,%ebx
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f0100767:	be c8 20 10 f0       	mov    $0xf01020c8,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010076c:	8b 03                	mov    (%ebx),%eax
f010076e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100772:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100775:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100779:	c7 04 24 69 1e 10 f0 	movl   $0xf0101e69,(%esp)
f0100780:	e8 65 02 00 00       	call   f01009ea <cprintf>
f0100785:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100788:	39 f3                	cmp    %esi,%ebx
f010078a:	75 e0                	jne    f010076c <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010078c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100791:	83 c4 10             	add    $0x10,%esp
f0100794:	5b                   	pop    %ebx
f0100795:	5e                   	pop    %esi
f0100796:	5d                   	pop    %ebp
f0100797:	c3                   	ret    

f0100798 <mon_backtrace>:
 * 2. *ebp is the new ebp(actually old)
 * 3. get the end(ebp = 0 -> see kern/entry.S, stack movl $0, %ebp)
 */
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100798:	55                   	push   %ebp
f0100799:	89 e5                	mov    %esp,%ebp
f010079b:	57                   	push   %edi
f010079c:	56                   	push   %esi
f010079d:	53                   	push   %ebx
f010079e:	83 ec 3c             	sub    $0x3c,%esp
	// Your code here.
	uint32_t ebp,eip;
	int i;	
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f01007a1:	c7 04 24 72 1e 10 f0 	movl   $0xf0101e72,(%esp)
f01007a8:	e8 3d 02 00 00       	call   f01009ea <cprintf>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007ad:	89 ee                	mov    %ebp,%esi
	ebp = read_ebp();
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
f01007af:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007b3:	c7 04 24 84 1e 10 f0 	movl   $0xf0101e84,(%esp)
f01007ba:	e8 2b 02 00 00       	call   f01009ea <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f01007bf:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f01007c2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007c6:	c7 04 24 8f 1e 10 f0 	movl   $0xf0101e8f,(%esp)
f01007cd:	e8 18 02 00 00       	call   f01009ea <cprintf>
		for(i=2; i < 7; i++)
f01007d2:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f01007d7:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007de:	c7 04 24 89 1e 10 f0 	movl   $0xf0101e89,(%esp)
f01007e5:	e8 00 02 00 00       	call   f01009ea <cprintf>
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
		eip = *(uint32_t *)(ebp + 4);
		cprintf("  eip %08x  args",eip);
		for(i=2; i < 7; i++)
f01007ea:	83 c3 01             	add    $0x1,%ebx
f01007ed:	83 fb 07             	cmp    $0x7,%ebx
f01007f0:	75 e5                	jne    f01007d7 <mon_backtrace+0x3f>
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
		cprintf("\n");
f01007f2:	c7 04 24 0e 1c 10 f0 	movl   $0xf0101c0e,(%esp)
f01007f9:	e8 ec 01 00 00       	call   f01009ea <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f01007fe:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100801:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100805:	89 3c 24             	mov    %edi,(%esp)
f0100808:	e8 e0 02 00 00       	call   f0100aed <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f010080d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100810:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100814:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100817:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081b:	c7 04 24 a0 1e 10 f0 	movl   $0xf0101ea0,(%esp)
f0100822:	e8 c3 01 00 00       	call   f01009ea <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f0100827:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010082a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010082e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100831:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100835:	c7 04 24 a9 1e 10 f0 	movl   $0xf0101ea9,(%esp)
f010083c:	e8 a9 01 00 00       	call   f01009ea <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f0100841:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100844:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100848:	c7 04 24 ae 1e 10 f0 	movl   $0xf0101eae,(%esp)
f010084f:	e8 96 01 00 00       	call   f01009ea <cprintf>
		ebp = *(uint32_t *)ebp;
f0100854:	8b 36                	mov    (%esi),%esi
	}while(ebp);
f0100856:	85 f6                	test   %esi,%esi
f0100858:	0f 85 51 ff ff ff    	jne    f01007af <mon_backtrace+0x17>
	return 0;
}
f010085e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100863:	83 c4 3c             	add    $0x3c,%esp
f0100866:	5b                   	pop    %ebx
f0100867:	5e                   	pop    %esi
f0100868:	5f                   	pop    %edi
f0100869:	5d                   	pop    %ebp
f010086a:	c3                   	ret    

f010086b <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010086b:	55                   	push   %ebp
f010086c:	89 e5                	mov    %esp,%ebp
f010086e:	57                   	push   %edi
f010086f:	56                   	push   %esi
f0100870:	53                   	push   %ebx
f0100871:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100874:	c7 04 24 1c 20 10 f0 	movl   $0xf010201c,(%esp)
f010087b:	e8 6a 01 00 00       	call   f01009ea <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100880:	c7 04 24 40 20 10 f0 	movl   $0xf0102040,(%esp)
f0100887:	e8 5e 01 00 00       	call   f01009ea <cprintf>


	while (1) {
		buf = readline("K> ");
f010088c:	c7 04 24 b3 1e 10 f0 	movl   $0xf0101eb3,(%esp)
f0100893:	e8 d8 0a 00 00       	call   f0101370 <readline>
f0100898:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f010089a:	85 c0                	test   %eax,%eax
f010089c:	74 ee                	je     f010088c <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010089e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008a5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008aa:	eb 06                	jmp    f01008b2 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008ac:	c6 06 00             	movb   $0x0,(%esi)
f01008af:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008b2:	0f b6 06             	movzbl (%esi),%eax
f01008b5:	84 c0                	test   %al,%al
f01008b7:	74 6a                	je     f0100923 <monitor+0xb8>
f01008b9:	0f be c0             	movsbl %al,%eax
f01008bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c0:	c7 04 24 b7 1e 10 f0 	movl   $0xf0101eb7,(%esp)
f01008c7:	e8 19 0d 00 00       	call   f01015e5 <strchr>
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	75 dc                	jne    f01008ac <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008d0:	80 3e 00             	cmpb   $0x0,(%esi)
f01008d3:	74 4e                	je     f0100923 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008d5:	83 fb 0f             	cmp    $0xf,%ebx
f01008d8:	75 16                	jne    f01008f0 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008da:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008e1:	00 
f01008e2:	c7 04 24 bc 1e 10 f0 	movl   $0xf0101ebc,(%esp)
f01008e9:	e8 fc 00 00 00       	call   f01009ea <cprintf>
f01008ee:	eb 9c                	jmp    f010088c <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008f0:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f01008f4:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f01008f7:	0f b6 06             	movzbl (%esi),%eax
f01008fa:	84 c0                	test   %al,%al
f01008fc:	75 0c                	jne    f010090a <monitor+0x9f>
f01008fe:	eb b2                	jmp    f01008b2 <monitor+0x47>
			buf++;
f0100900:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100903:	0f b6 06             	movzbl (%esi),%eax
f0100906:	84 c0                	test   %al,%al
f0100908:	74 a8                	je     f01008b2 <monitor+0x47>
f010090a:	0f be c0             	movsbl %al,%eax
f010090d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100911:	c7 04 24 b7 1e 10 f0 	movl   $0xf0101eb7,(%esp)
f0100918:	e8 c8 0c 00 00       	call   f01015e5 <strchr>
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 df                	je     f0100900 <monitor+0x95>
f0100921:	eb 8f                	jmp    f01008b2 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100923:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f010092a:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010092b:	85 db                	test   %ebx,%ebx
f010092d:	0f 84 59 ff ff ff    	je     f010088c <monitor+0x21>
f0100933:	bf a0 20 10 f0       	mov    $0xf01020a0,%edi
f0100938:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010093d:	8b 07                	mov    (%edi),%eax
f010093f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100943:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100946:	89 04 24             	mov    %eax,(%esp)
f0100949:	e8 13 0c 00 00       	call   f0101561 <strcmp>
f010094e:	85 c0                	test   %eax,%eax
f0100950:	75 24                	jne    f0100976 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100952:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100955:	8b 55 08             	mov    0x8(%ebp),%edx
f0100958:	89 54 24 08          	mov    %edx,0x8(%esp)
f010095c:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010095f:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100963:	89 1c 24             	mov    %ebx,(%esp)
f0100966:	ff 14 85 a8 20 10 f0 	call   *-0xfefdf58(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010096d:	85 c0                	test   %eax,%eax
f010096f:	78 28                	js     f0100999 <monitor+0x12e>
f0100971:	e9 16 ff ff ff       	jmp    f010088c <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100976:	83 c6 01             	add    $0x1,%esi
f0100979:	83 c7 0c             	add    $0xc,%edi
f010097c:	83 fe 03             	cmp    $0x3,%esi
f010097f:	75 bc                	jne    f010093d <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100981:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100984:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100988:	c7 04 24 d9 1e 10 f0 	movl   $0xf0101ed9,(%esp)
f010098f:	e8 56 00 00 00       	call   f01009ea <cprintf>
f0100994:	e9 f3 fe ff ff       	jmp    f010088c <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100999:	83 c4 5c             	add    $0x5c,%esp
f010099c:	5b                   	pop    %ebx
f010099d:	5e                   	pop    %esi
f010099e:	5f                   	pop    %edi
f010099f:	5d                   	pop    %ebp
f01009a0:	c3                   	ret    
f01009a1:	66 90                	xchg   %ax,%ax
f01009a3:	90                   	nop

f01009a4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009a4:	55                   	push   %ebp
f01009a5:	89 e5                	mov    %esp,%ebp
f01009a7:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ad:	89 04 24             	mov    %eax,(%esp)
f01009b0:	e8 a4 fc ff ff       	call   f0100659 <cputchar>
	*cnt++;
}
f01009b5:	c9                   	leave  
f01009b6:	c3                   	ret    

f01009b7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009b7:	55                   	push   %ebp
f01009b8:	89 e5                	mov    %esp,%ebp
f01009ba:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009bd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009c7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ce:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009d2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d9:	c7 04 24 a4 09 10 f0 	movl   $0xf01009a4,(%esp)
f01009e0:	e8 fd 04 00 00       	call   f0100ee2 <vprintfmt>
	return cnt;
}
f01009e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009e8:	c9                   	leave  
f01009e9:	c3                   	ret    

f01009ea <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009ea:	55                   	push   %ebp
f01009eb:	89 e5                	mov    %esp,%ebp
f01009ed:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009f0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01009fa:	89 04 24             	mov    %eax,(%esp)
f01009fd:	e8 b5 ff ff ff       	call   f01009b7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a02:	c9                   	leave  
f0100a03:	c3                   	ret    
f0100a04:	66 90                	xchg   %ax,%ax
f0100a06:	66 90                	xchg   %ax,%ax
f0100a08:	66 90                	xchg   %ax,%ax
f0100a0a:	66 90                	xchg   %ax,%ax
f0100a0c:	66 90                	xchg   %ax,%ax
f0100a0e:	66 90                	xchg   %ax,%ax

f0100a10 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a10:	55                   	push   %ebp
f0100a11:	89 e5                	mov    %esp,%ebp
f0100a13:	57                   	push   %edi
f0100a14:	56                   	push   %esi
f0100a15:	53                   	push   %ebx
f0100a16:	83 ec 10             	sub    $0x10,%esp
f0100a19:	89 c6                	mov    %eax,%esi
f0100a1b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a1e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a21:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a24:	8b 1a                	mov    (%edx),%ebx
f0100a26:	8b 09                	mov    (%ecx),%ecx
f0100a28:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100a2b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a32:	eb 77                	jmp    f0100aab <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a34:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a37:	01 d8                	add    %ebx,%eax
f0100a39:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a3e:	99                   	cltd   
f0100a3f:	f7 f9                	idiv   %ecx
f0100a41:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a43:	eb 01                	jmp    f0100a46 <stab_binsearch+0x36>
			m--;
f0100a45:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a46:	39 d9                	cmp    %ebx,%ecx
f0100a48:	7c 1d                	jl     f0100a67 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a4a:	6b d1 0c             	imul   $0xc,%ecx,%edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a4d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a52:	39 fa                	cmp    %edi,%edx
f0100a54:	75 ef                	jne    f0100a45 <stab_binsearch+0x35>
f0100a56:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a59:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a5c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a60:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a63:	73 18                	jae    f0100a7d <stab_binsearch+0x6d>
f0100a65:	eb 05                	jmp    f0100a6c <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a67:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a6a:	eb 3f                	jmp    f0100aab <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a6c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a6f:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100a71:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a74:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a7b:	eb 2e                	jmp    f0100aab <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a7d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a80:	73 15                	jae    f0100a97 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a82:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a85:	49                   	dec    %ecx
f0100a86:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100a89:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a8c:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a8e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a95:	eb 14                	jmp    f0100aab <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a97:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a9a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a9d:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0100a9f:	ff 45 0c             	incl   0xc(%ebp)
f0100aa2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aa4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100aab:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100aae:	7e 84                	jle    f0100a34 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ab0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ab4:	75 0d                	jne    f0100ac3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ab6:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100ab9:	8b 02                	mov    (%edx),%eax
f0100abb:	48                   	dec    %eax
f0100abc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100abf:	89 01                	mov    %eax,(%ecx)
f0100ac1:	eb 22                	jmp    f0100ae5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ac3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100ac6:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ac8:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100acb:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100acd:	eb 01                	jmp    f0100ad0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100acf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad0:	39 c1                	cmp    %eax,%ecx
f0100ad2:	7d 0c                	jge    f0100ae0 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100ad4:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100ad7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100adc:	39 fa                	cmp    %edi,%edx
f0100ade:	75 ef                	jne    f0100acf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ae0:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100ae3:	89 02                	mov    %eax,(%edx)
	}
}
f0100ae5:	83 c4 10             	add    $0x10,%esp
f0100ae8:	5b                   	pop    %ebx
f0100ae9:	5e                   	pop    %esi
f0100aea:	5f                   	pop    %edi
f0100aeb:	5d                   	pop    %ebp
f0100aec:	c3                   	ret    

f0100aed <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aed:	55                   	push   %ebp
f0100aee:	89 e5                	mov    %esp,%ebp
f0100af0:	83 ec 58             	sub    $0x58,%esp
f0100af3:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100af6:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100af9:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100afc:	8b 75 08             	mov    0x8(%ebp),%esi
f0100aff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b02:	c7 03 c4 20 10 f0    	movl   $0xf01020c4,(%ebx)
	info->eip_line = 0;
f0100b08:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b0f:	c7 43 08 c4 20 10 f0 	movl   $0xf01020c4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b16:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b1d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b20:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b27:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b2d:	76 12                	jbe    f0100b41 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b2f:	b8 a1 78 10 f0       	mov    $0xf01078a1,%eax
f0100b34:	3d 75 5f 10 f0       	cmp    $0xf0105f75,%eax
f0100b39:	0f 86 f5 01 00 00    	jbe    f0100d34 <debuginfo_eip+0x247>
f0100b3f:	eb 1c                	jmp    f0100b5d <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b41:	c7 44 24 08 ce 20 10 	movl   $0xf01020ce,0x8(%esp)
f0100b48:	f0 
f0100b49:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b50:	00 
f0100b51:	c7 04 24 db 20 10 f0 	movl   $0xf01020db,(%esp)
f0100b58:	e8 9b f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b5d:	80 3d a0 78 10 f0 00 	cmpb   $0x0,0xf01078a0
f0100b64:	0f 85 d1 01 00 00    	jne    f0100d3b <debuginfo_eip+0x24e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b6a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b71:	b8 74 5f 10 f0       	mov    $0xf0105f74,%eax
f0100b76:	2d fc 22 10 f0       	sub    $0xf01022fc,%eax
f0100b7b:	c1 f8 02             	sar    $0x2,%eax
f0100b7e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b84:	83 e8 01             	sub    $0x1,%eax
f0100b87:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b8a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b8e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b95:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b98:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b9b:	b8 fc 22 10 f0       	mov    $0xf01022fc,%eax
f0100ba0:	e8 6b fe ff ff       	call   f0100a10 <stab_binsearch>
	if (lfile == 0)
f0100ba5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ba8:	85 c0                	test   %eax,%eax
f0100baa:	0f 84 92 01 00 00    	je     f0100d42 <debuginfo_eip+0x255>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bb0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bb6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bb9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bbd:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bc4:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bc7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bca:	b8 fc 22 10 f0       	mov    $0xf01022fc,%eax
f0100bcf:	e8 3c fe ff ff       	call   f0100a10 <stab_binsearch>

	if (lfun <= rfun) {
f0100bd4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bd7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bda:	39 d0                	cmp    %edx,%eax
f0100bdc:	7f 3d                	jg     f0100c1b <debuginfo_eip+0x12e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bde:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100be1:	8d b9 fc 22 10 f0    	lea    -0xfefdd04(%ecx),%edi
f0100be7:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100bea:	8b 89 fc 22 10 f0    	mov    -0xfefdd04(%ecx),%ecx
f0100bf0:	bf a1 78 10 f0       	mov    $0xf01078a1,%edi
f0100bf5:	81 ef 75 5f 10 f0    	sub    $0xf0105f75,%edi
f0100bfb:	39 f9                	cmp    %edi,%ecx
f0100bfd:	73 09                	jae    f0100c08 <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bff:	81 c1 75 5f 10 f0    	add    $0xf0105f75,%ecx
f0100c05:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c08:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100c0b:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c0e:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c11:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c13:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c16:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c19:	eb 0f                	jmp    f0100c2a <debuginfo_eip+0x13d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c1b:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c1e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c21:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c24:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c27:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c2a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c31:	00 
f0100c32:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c35:	89 04 24             	mov    %eax,(%esp)
f0100c38:	e8 de 09 00 00       	call   f010161b <strfind>
f0100c3d:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c40:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f0100c43:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c47:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c4e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c51:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c54:	b8 fc 22 10 f0       	mov    $0xf01022fc,%eax
f0100c59:	e8 b2 fd ff ff       	call   f0100a10 <stab_binsearch>
	if(lline > rline)
f0100c5e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c61:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c64:	0f 8f df 00 00 00    	jg     f0100d49 <debuginfo_eip+0x25c>
		return -1;
		//cprintf("lline %d, rline %d",lline, rline);
	info -> eip_line = stabs[lline].n_desc;
f0100c6a:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c6d:	0f b7 80 02 23 10 f0 	movzwl -0xfefdcfe(%eax),%eax
f0100c74:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c77:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c7a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c7d:	39 f0                	cmp    %esi,%eax
f0100c7f:	7c 63                	jl     f0100ce4 <debuginfo_eip+0x1f7>
	       && stabs[lline].n_type != N_SOL
f0100c81:	6b f8 0c             	imul   $0xc,%eax,%edi
f0100c84:	81 c7 fc 22 10 f0    	add    $0xf01022fc,%edi
f0100c8a:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
f0100c8e:	80 f9 84             	cmp    $0x84,%cl
f0100c91:	74 32                	je     f0100cc5 <debuginfo_eip+0x1d8>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100c93:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100c96:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100c99:	81 c2 fc 22 10 f0    	add    $0xf01022fc,%edx
f0100c9f:	eb 15                	jmp    f0100cb6 <debuginfo_eip+0x1c9>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ca1:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ca4:	39 f0                	cmp    %esi,%eax
f0100ca6:	7c 3c                	jl     f0100ce4 <debuginfo_eip+0x1f7>
	       && stabs[lline].n_type != N_SOL
f0100ca8:	89 d7                	mov    %edx,%edi
f0100caa:	83 ea 0c             	sub    $0xc,%edx
f0100cad:	0f b6 4a 10          	movzbl 0x10(%edx),%ecx
f0100cb1:	80 f9 84             	cmp    $0x84,%cl
f0100cb4:	74 0f                	je     f0100cc5 <debuginfo_eip+0x1d8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cb6:	80 f9 64             	cmp    $0x64,%cl
f0100cb9:	75 e6                	jne    f0100ca1 <debuginfo_eip+0x1b4>
f0100cbb:	83 7f 08 00          	cmpl   $0x0,0x8(%edi)
f0100cbf:	74 e0                	je     f0100ca1 <debuginfo_eip+0x1b4>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cc1:	39 c6                	cmp    %eax,%esi
f0100cc3:	7f 1f                	jg     f0100ce4 <debuginfo_eip+0x1f7>
f0100cc5:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cc8:	8b 80 fc 22 10 f0    	mov    -0xfefdd04(%eax),%eax
f0100cce:	ba a1 78 10 f0       	mov    $0xf01078a1,%edx
f0100cd3:	81 ea 75 5f 10 f0    	sub    $0xf0105f75,%edx
f0100cd9:	39 d0                	cmp    %edx,%eax
f0100cdb:	73 07                	jae    f0100ce4 <debuginfo_eip+0x1f7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cdd:	05 75 5f 10 f0       	add    $0xf0105f75,%eax
f0100ce2:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ce4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ce7:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		     lline++)
			info->eip_fn_narg++;

	//cprintf("\neip_file %s\neip_line %d\neip_fn_name %s\neip_fn_namelen %d\neip_fn_addr %08x\neip_fn_narg\n",info->eip_file,info->eip_line,info->eip_fn_name,info->eip_fn_namelen,info->eip_fn_addr,info->eip_fn_narg);

	return 0;
f0100cea:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cef:	39 ca                	cmp    %ecx,%edx
f0100cf1:	7d 70                	jge    f0100d63 <debuginfo_eip+0x276>
		for (lline = lfun + 1;
f0100cf3:	8d 42 01             	lea    0x1(%edx),%eax
f0100cf6:	39 c1                	cmp    %eax,%ecx
f0100cf8:	7e 56                	jle    f0100d50 <debuginfo_eip+0x263>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cfa:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cfd:	80 b8 00 23 10 f0 a0 	cmpb   $0xa0,-0xfefdd00(%eax)
f0100d04:	75 51                	jne    f0100d57 <debuginfo_eip+0x26a>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100d06:	8d 42 02             	lea    0x2(%edx),%eax
f0100d09:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100d0c:	81 c2 fc 22 10 f0    	add    $0xf01022fc,%edx
f0100d12:	89 cf                	mov    %ecx,%edi
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d14:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d18:	39 f8                	cmp    %edi,%eax
f0100d1a:	74 42                	je     f0100d5e <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d1c:	0f b6 72 1c          	movzbl 0x1c(%edx),%esi
f0100d20:	83 c0 01             	add    $0x1,%eax
f0100d23:	83 c2 0c             	add    $0xc,%edx
f0100d26:	89 f1                	mov    %esi,%ecx
f0100d28:	80 f9 a0             	cmp    $0xa0,%cl
f0100d2b:	74 e7                	je     f0100d14 <debuginfo_eip+0x227>
		     lline++)
			info->eip_fn_narg++;

	//cprintf("\neip_file %s\neip_line %d\neip_fn_name %s\neip_fn_namelen %d\neip_fn_addr %08x\neip_fn_narg\n",info->eip_file,info->eip_line,info->eip_fn_name,info->eip_fn_namelen,info->eip_fn_addr,info->eip_fn_narg);

	return 0;
f0100d2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d32:	eb 2f                	jmp    f0100d63 <debuginfo_eip+0x276>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d39:	eb 28                	jmp    f0100d63 <debuginfo_eip+0x276>
f0100d3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d40:	eb 21                	jmp    f0100d63 <debuginfo_eip+0x276>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d47:	eb 1a                	jmp    f0100d63 <debuginfo_eip+0x276>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
	if(lline > rline)
		return -1;
f0100d49:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d4e:	eb 13                	jmp    f0100d63 <debuginfo_eip+0x276>
		     lline++)
			info->eip_fn_narg++;

	//cprintf("\neip_file %s\neip_line %d\neip_fn_name %s\neip_fn_namelen %d\neip_fn_addr %08x\neip_fn_narg\n",info->eip_file,info->eip_line,info->eip_fn_name,info->eip_fn_namelen,info->eip_fn_addr,info->eip_fn_narg);

	return 0;
f0100d50:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d55:	eb 0c                	jmp    f0100d63 <debuginfo_eip+0x276>
f0100d57:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d5c:	eb 05                	jmp    f0100d63 <debuginfo_eip+0x276>
f0100d5e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d63:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d66:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d69:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d6c:	89 ec                	mov    %ebp,%esp
f0100d6e:	5d                   	pop    %ebp
f0100d6f:	c3                   	ret    

f0100d70 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d70:	55                   	push   %ebp
f0100d71:	89 e5                	mov    %esp,%ebp
f0100d73:	57                   	push   %edi
f0100d74:	56                   	push   %esi
f0100d75:	53                   	push   %ebx
f0100d76:	83 ec 4c             	sub    $0x4c,%esp
f0100d79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d7c:	89 d7                	mov    %edx,%edi
f0100d7e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100d81:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100d84:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d87:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d8a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d8f:	39 d8                	cmp    %ebx,%eax
f0100d91:	72 17                	jb     f0100daa <printnum+0x3a>
f0100d93:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100d96:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100d99:	76 0f                	jbe    f0100daa <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d9b:	8b 75 14             	mov    0x14(%ebp),%esi
f0100d9e:	83 ee 01             	sub    $0x1,%esi
f0100da1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100da4:	85 f6                	test   %esi,%esi
f0100da6:	7f 63                	jg     f0100e0b <printnum+0x9b>
f0100da8:	eb 75                	jmp    f0100e1f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100daa:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100dad:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100db1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100db4:	83 e8 01             	sub    $0x1,%eax
f0100db7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dbb:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100dbe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100dc2:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100dc6:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100dca:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100dcd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100dd0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100dd7:	00 
f0100dd8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100ddb:	89 1c 24             	mov    %ebx,(%esp)
f0100dde:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100de1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100de5:	e8 b6 0a 00 00       	call   f01018a0 <__udivdi3>
f0100dea:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100ded:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100df0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100df4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100df8:	89 04 24             	mov    %eax,(%esp)
f0100dfb:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100dff:	89 fa                	mov    %edi,%edx
f0100e01:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e04:	e8 67 ff ff ff       	call   f0100d70 <printnum>
f0100e09:	eb 14                	jmp    f0100e1f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e0b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e0f:	8b 45 18             	mov    0x18(%ebp),%eax
f0100e12:	89 04 24             	mov    %eax,(%esp)
f0100e15:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e17:	83 ee 01             	sub    $0x1,%esi
f0100e1a:	75 ef                	jne    f0100e0b <printnum+0x9b>
f0100e1c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e1f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e23:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e27:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e2a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100e2e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e35:	00 
f0100e36:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100e39:	89 1c 24             	mov    %ebx,(%esp)
f0100e3c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100e3f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e43:	e8 a8 0b 00 00       	call   f01019f0 <__umoddi3>
f0100e48:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e4c:	0f be 80 e9 20 10 f0 	movsbl -0xfefdf17(%eax),%eax
f0100e53:	89 04 24             	mov    %eax,(%esp)
f0100e56:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e59:	ff d0                	call   *%eax
}
f0100e5b:	83 c4 4c             	add    $0x4c,%esp
f0100e5e:	5b                   	pop    %ebx
f0100e5f:	5e                   	pop    %esi
f0100e60:	5f                   	pop    %edi
f0100e61:	5d                   	pop    %ebp
f0100e62:	c3                   	ret    

f0100e63 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e63:	55                   	push   %ebp
f0100e64:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e66:	83 fa 01             	cmp    $0x1,%edx
f0100e69:	7e 0e                	jle    f0100e79 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e6b:	8b 10                	mov    (%eax),%edx
f0100e6d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e70:	89 08                	mov    %ecx,(%eax)
f0100e72:	8b 02                	mov    (%edx),%eax
f0100e74:	8b 52 04             	mov    0x4(%edx),%edx
f0100e77:	eb 22                	jmp    f0100e9b <getuint+0x38>
	else if (lflag)
f0100e79:	85 d2                	test   %edx,%edx
f0100e7b:	74 10                	je     f0100e8d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e7d:	8b 10                	mov    (%eax),%edx
f0100e7f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e82:	89 08                	mov    %ecx,(%eax)
f0100e84:	8b 02                	mov    (%edx),%eax
f0100e86:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e8b:	eb 0e                	jmp    f0100e9b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e8d:	8b 10                	mov    (%eax),%edx
f0100e8f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e92:	89 08                	mov    %ecx,(%eax)
f0100e94:	8b 02                	mov    (%edx),%eax
f0100e96:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e9b:	5d                   	pop    %ebp
f0100e9c:	c3                   	ret    

f0100e9d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e9d:	55                   	push   %ebp
f0100e9e:	89 e5                	mov    %esp,%ebp
f0100ea0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ea3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ea7:	8b 10                	mov    (%eax),%edx
f0100ea9:	3b 50 04             	cmp    0x4(%eax),%edx
f0100eac:	73 0a                	jae    f0100eb8 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100eae:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100eb1:	88 0a                	mov    %cl,(%edx)
f0100eb3:	83 c2 01             	add    $0x1,%edx
f0100eb6:	89 10                	mov    %edx,(%eax)
}
f0100eb8:	5d                   	pop    %ebp
f0100eb9:	c3                   	ret    

f0100eba <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100eba:	55                   	push   %ebp
f0100ebb:	89 e5                	mov    %esp,%ebp
f0100ebd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ec0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ec3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ec7:	8b 45 10             	mov    0x10(%ebp),%eax
f0100eca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ece:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ed1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ed5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ed8:	89 04 24             	mov    %eax,(%esp)
f0100edb:	e8 02 00 00 00       	call   f0100ee2 <vprintfmt>
	va_end(ap);
}
f0100ee0:	c9                   	leave  
f0100ee1:	c3                   	ret    

f0100ee2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ee2:	55                   	push   %ebp
f0100ee3:	89 e5                	mov    %esp,%ebp
f0100ee5:	57                   	push   %edi
f0100ee6:	56                   	push   %esi
f0100ee7:	53                   	push   %ebx
f0100ee8:	83 ec 4c             	sub    $0x4c,%esp
f0100eeb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100eee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ef1:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100ef4:	eb 11                	jmp    f0100f07 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ef6:	85 c0                	test   %eax,%eax
f0100ef8:	0f 84 db 03 00 00    	je     f01012d9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f0100efe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f02:	89 04 24             	mov    %eax,(%esp)
f0100f05:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f07:	0f b6 07             	movzbl (%edi),%eax
f0100f0a:	83 c7 01             	add    $0x1,%edi
f0100f0d:	83 f8 25             	cmp    $0x25,%eax
f0100f10:	75 e4                	jne    f0100ef6 <vprintfmt+0x14>
f0100f12:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0100f16:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100f1d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100f24:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100f2b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f30:	eb 2b                	jmp    f0100f5d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f32:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f35:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0100f39:	eb 22                	jmp    f0100f5d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f3e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0100f42:	eb 19                	jmp    f0100f5d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f44:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100f47:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f4e:	eb 0d                	jmp    f0100f5d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f50:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f53:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f56:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5d:	0f b6 0f             	movzbl (%edi),%ecx
f0100f60:	8d 47 01             	lea    0x1(%edi),%eax
f0100f63:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f66:	0f b6 07             	movzbl (%edi),%eax
f0100f69:	83 e8 23             	sub    $0x23,%eax
f0100f6c:	3c 55                	cmp    $0x55,%al
f0100f6e:	0f 87 40 03 00 00    	ja     f01012b4 <vprintfmt+0x3d2>
f0100f74:	0f b6 c0             	movzbl %al,%eax
f0100f77:	ff 24 85 78 21 10 f0 	jmp    *-0xfefde88(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f7e:	83 e9 30             	sub    $0x30,%ecx
f0100f81:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f0100f84:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0100f88:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f8b:	83 f9 09             	cmp    $0x9,%ecx
f0100f8e:	77 57                	ja     f0100fe7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f90:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100f93:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f96:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f99:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100f9c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100f9f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100fa3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100fa6:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100fa9:	83 f9 09             	cmp    $0x9,%ecx
f0100fac:	76 eb                	jbe    f0100f99 <vprintfmt+0xb7>
f0100fae:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100fb1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100fb4:	eb 34                	jmp    f0100fea <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100fb6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb9:	8d 48 04             	lea    0x4(%eax),%ecx
f0100fbc:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100fbf:	8b 00                	mov    (%eax),%eax
f0100fc1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100fc7:	eb 21                	jmp    f0100fea <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0100fc9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fcd:	0f 88 71 ff ff ff    	js     f0100f44 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100fd6:	eb 85                	jmp    f0100f5d <vprintfmt+0x7b>
f0100fd8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fdb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0100fe2:	e9 76 ff ff ff       	jmp    f0100f5d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fe7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100fea:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fee:	0f 89 69 ff ff ff    	jns    f0100f5d <vprintfmt+0x7b>
f0100ff4:	e9 57 ff ff ff       	jmp    f0100f50 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ff9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fff:	e9 59 ff ff ff       	jmp    f0100f5d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101004:	8b 45 14             	mov    0x14(%ebp),%eax
f0101007:	8d 50 04             	lea    0x4(%eax),%edx
f010100a:	89 55 14             	mov    %edx,0x14(%ebp)
f010100d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101011:	8b 00                	mov    (%eax),%eax
f0101013:	89 04 24             	mov    %eax,(%esp)
f0101016:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101018:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010101b:	e9 e7 fe ff ff       	jmp    f0100f07 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101020:	8b 45 14             	mov    0x14(%ebp),%eax
f0101023:	8d 50 04             	lea    0x4(%eax),%edx
f0101026:	89 55 14             	mov    %edx,0x14(%ebp)
f0101029:	8b 00                	mov    (%eax),%eax
f010102b:	89 c2                	mov    %eax,%edx
f010102d:	c1 fa 1f             	sar    $0x1f,%edx
f0101030:	31 d0                	xor    %edx,%eax
f0101032:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101034:	83 f8 06             	cmp    $0x6,%eax
f0101037:	7f 0b                	jg     f0101044 <vprintfmt+0x162>
f0101039:	8b 14 85 d0 22 10 f0 	mov    -0xfefdd30(,%eax,4),%edx
f0101040:	85 d2                	test   %edx,%edx
f0101042:	75 20                	jne    f0101064 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0101044:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101048:	c7 44 24 08 01 21 10 	movl   $0xf0102101,0x8(%esp)
f010104f:	f0 
f0101050:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101054:	89 34 24             	mov    %esi,(%esp)
f0101057:	e8 5e fe ff ff       	call   f0100eba <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010105c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010105f:	e9 a3 fe ff ff       	jmp    f0100f07 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0101064:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101068:	c7 44 24 08 0a 21 10 	movl   $0xf010210a,0x8(%esp)
f010106f:	f0 
f0101070:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101074:	89 34 24             	mov    %esi,(%esp)
f0101077:	e8 3e fe ff ff       	call   f0100eba <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010107c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010107f:	e9 83 fe ff ff       	jmp    f0100f07 <vprintfmt+0x25>
f0101084:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101087:	8b 7d d8             	mov    -0x28(%ebp),%edi
f010108a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010108d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101090:	8d 50 04             	lea    0x4(%eax),%edx
f0101093:	89 55 14             	mov    %edx,0x14(%ebp)
f0101096:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101098:	85 ff                	test   %edi,%edi
f010109a:	b8 fa 20 10 f0       	mov    $0xf01020fa,%eax
f010109f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01010a2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f01010a6:	74 06                	je     f01010ae <vprintfmt+0x1cc>
f01010a8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01010ac:	7f 16                	jg     f01010c4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010ae:	0f b6 17             	movzbl (%edi),%edx
f01010b1:	0f be c2             	movsbl %dl,%eax
f01010b4:	83 c7 01             	add    $0x1,%edi
f01010b7:	85 c0                	test   %eax,%eax
f01010b9:	0f 85 9f 00 00 00    	jne    f010115e <vprintfmt+0x27c>
f01010bf:	e9 8b 00 00 00       	jmp    f010114f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010c4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010c8:	89 3c 24             	mov    %edi,(%esp)
f01010cb:	e8 92 03 00 00       	call   f0101462 <strnlen>
f01010d0:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01010d3:	29 c2                	sub    %eax,%edx
f01010d5:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01010d8:	85 d2                	test   %edx,%edx
f01010da:	7e d2                	jle    f01010ae <vprintfmt+0x1cc>
					putch(padc, putdat);
f01010dc:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f01010e0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01010e3:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01010e6:	89 d7                	mov    %edx,%edi
f01010e8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010ef:	89 04 24             	mov    %eax,(%esp)
f01010f2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010f4:	83 ef 01             	sub    $0x1,%edi
f01010f7:	75 ef                	jne    f01010e8 <vprintfmt+0x206>
f01010f9:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01010fc:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01010ff:	eb ad                	jmp    f01010ae <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101101:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101105:	74 20                	je     f0101127 <vprintfmt+0x245>
f0101107:	0f be d2             	movsbl %dl,%edx
f010110a:	83 ea 20             	sub    $0x20,%edx
f010110d:	83 fa 5e             	cmp    $0x5e,%edx
f0101110:	76 15                	jbe    f0101127 <vprintfmt+0x245>
					putch('?', putdat);
f0101112:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101115:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101119:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101120:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101123:	ff d1                	call   *%ecx
f0101125:	eb 0f                	jmp    f0101136 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0101127:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010112a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010112e:	89 04 24             	mov    %eax,(%esp)
f0101131:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101134:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101136:	83 eb 01             	sub    $0x1,%ebx
f0101139:	0f b6 17             	movzbl (%edi),%edx
f010113c:	0f be c2             	movsbl %dl,%eax
f010113f:	83 c7 01             	add    $0x1,%edi
f0101142:	85 c0                	test   %eax,%eax
f0101144:	75 24                	jne    f010116a <vprintfmt+0x288>
f0101146:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101149:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010114c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010114f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101152:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101156:	0f 8e ab fd ff ff    	jle    f0100f07 <vprintfmt+0x25>
f010115c:	eb 20                	jmp    f010117e <vprintfmt+0x29c>
f010115e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101161:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101164:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101167:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010116a:	85 f6                	test   %esi,%esi
f010116c:	78 93                	js     f0101101 <vprintfmt+0x21f>
f010116e:	83 ee 01             	sub    $0x1,%esi
f0101171:	79 8e                	jns    f0101101 <vprintfmt+0x21f>
f0101173:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101176:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101179:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010117c:	eb d1                	jmp    f010114f <vprintfmt+0x26d>
f010117e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101181:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101185:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010118c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010118e:	83 ef 01             	sub    $0x1,%edi
f0101191:	75 ee                	jne    f0101181 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101193:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101196:	e9 6c fd ff ff       	jmp    f0100f07 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010119b:	83 fa 01             	cmp    $0x1,%edx
f010119e:	66 90                	xchg   %ax,%ax
f01011a0:	7e 16                	jle    f01011b8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f01011a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a5:	8d 50 08             	lea    0x8(%eax),%edx
f01011a8:	89 55 14             	mov    %edx,0x14(%ebp)
f01011ab:	8b 10                	mov    (%eax),%edx
f01011ad:	8b 48 04             	mov    0x4(%eax),%ecx
f01011b0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01011b3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01011b6:	eb 32                	jmp    f01011ea <vprintfmt+0x308>
	else if (lflag)
f01011b8:	85 d2                	test   %edx,%edx
f01011ba:	74 18                	je     f01011d4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f01011bc:	8b 45 14             	mov    0x14(%ebp),%eax
f01011bf:	8d 50 04             	lea    0x4(%eax),%edx
f01011c2:	89 55 14             	mov    %edx,0x14(%ebp)
f01011c5:	8b 00                	mov    (%eax),%eax
f01011c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01011ca:	89 c1                	mov    %eax,%ecx
f01011cc:	c1 f9 1f             	sar    $0x1f,%ecx
f01011cf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01011d2:	eb 16                	jmp    f01011ea <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f01011d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d7:	8d 50 04             	lea    0x4(%eax),%edx
f01011da:	89 55 14             	mov    %edx,0x14(%ebp)
f01011dd:	8b 00                	mov    (%eax),%eax
f01011df:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01011e2:	89 c7                	mov    %eax,%edi
f01011e4:	c1 ff 1f             	sar    $0x1f,%edi
f01011e7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011ea:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01011ed:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011f0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011f5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01011f9:	79 7d                	jns    f0101278 <vprintfmt+0x396>
				putch('-', putdat);
f01011fb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ff:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101206:	ff d6                	call   *%esi
				num = -(long long) num;
f0101208:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010120b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010120e:	f7 d8                	neg    %eax
f0101210:	83 d2 00             	adc    $0x0,%edx
f0101213:	f7 da                	neg    %edx
			}
			base = 10;
f0101215:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010121a:	eb 5c                	jmp    f0101278 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010121c:	8d 45 14             	lea    0x14(%ebp),%eax
f010121f:	e8 3f fc ff ff       	call   f0100e63 <getuint>
			base = 10;
f0101224:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101229:	eb 4d                	jmp    f0101278 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010122b:	8d 45 14             	lea    0x14(%ebp),%eax
f010122e:	e8 30 fc ff ff       	call   f0100e63 <getuint>
			base = 8;
f0101233:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101238:	eb 3e                	jmp    f0101278 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
f010123a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010123e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101245:	ff d6                	call   *%esi
			putch('x', putdat);
f0101247:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010124b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101252:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101254:	8b 45 14             	mov    0x14(%ebp),%eax
f0101257:	8d 50 04             	lea    0x4(%eax),%edx
f010125a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010125d:	8b 00                	mov    (%eax),%eax
f010125f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101264:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101269:	eb 0d                	jmp    f0101278 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010126b:	8d 45 14             	lea    0x14(%ebp),%eax
f010126e:	e8 f0 fb ff ff       	call   f0100e63 <getuint>
			base = 16;
f0101273:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101278:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010127c:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0101280:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101283:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101287:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010128b:	89 04 24             	mov    %eax,(%esp)
f010128e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101292:	89 da                	mov    %ebx,%edx
f0101294:	89 f0                	mov    %esi,%eax
f0101296:	e8 d5 fa ff ff       	call   f0100d70 <printnum>
			break;
f010129b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010129e:	e9 64 fc ff ff       	jmp    f0100f07 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012a3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012a7:	89 0c 24             	mov    %ecx,(%esp)
f01012aa:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01012af:	e9 53 fc ff ff       	jmp    f0100f07 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012b4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012b8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01012bf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012c1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01012c5:	0f 84 3c fc ff ff    	je     f0100f07 <vprintfmt+0x25>
f01012cb:	83 ef 01             	sub    $0x1,%edi
f01012ce:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01012d2:	75 f7                	jne    f01012cb <vprintfmt+0x3e9>
f01012d4:	e9 2e fc ff ff       	jmp    f0100f07 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01012d9:	83 c4 4c             	add    $0x4c,%esp
f01012dc:	5b                   	pop    %ebx
f01012dd:	5e                   	pop    %esi
f01012de:	5f                   	pop    %edi
f01012df:	5d                   	pop    %ebp
f01012e0:	c3                   	ret    

f01012e1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012e1:	55                   	push   %ebp
f01012e2:	89 e5                	mov    %esp,%ebp
f01012e4:	83 ec 28             	sub    $0x28,%esp
f01012e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ea:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012f0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012f4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012f7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012fe:	85 d2                	test   %edx,%edx
f0101300:	7e 30                	jle    f0101332 <vsnprintf+0x51>
f0101302:	85 c0                	test   %eax,%eax
f0101304:	74 2c                	je     f0101332 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101306:	8b 45 14             	mov    0x14(%ebp),%eax
f0101309:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010130d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101310:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101314:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101317:	89 44 24 04          	mov    %eax,0x4(%esp)
f010131b:	c7 04 24 9d 0e 10 f0 	movl   $0xf0100e9d,(%esp)
f0101322:	e8 bb fb ff ff       	call   f0100ee2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101327:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010132a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010132d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101330:	eb 05                	jmp    f0101337 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101332:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101337:	c9                   	leave  
f0101338:	c3                   	ret    

f0101339 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101339:	55                   	push   %ebp
f010133a:	89 e5                	mov    %esp,%ebp
f010133c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010133f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101342:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101346:	8b 45 10             	mov    0x10(%ebp),%eax
f0101349:	89 44 24 08          	mov    %eax,0x8(%esp)
f010134d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101350:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101354:	8b 45 08             	mov    0x8(%ebp),%eax
f0101357:	89 04 24             	mov    %eax,(%esp)
f010135a:	e8 82 ff ff ff       	call   f01012e1 <vsnprintf>
	va_end(ap);

	return rc;
}
f010135f:	c9                   	leave  
f0101360:	c3                   	ret    
f0101361:	66 90                	xchg   %ax,%ax
f0101363:	66 90                	xchg   %ax,%ax
f0101365:	66 90                	xchg   %ax,%ax
f0101367:	66 90                	xchg   %ax,%ax
f0101369:	66 90                	xchg   %ax,%ax
f010136b:	66 90                	xchg   %ax,%ax
f010136d:	66 90                	xchg   %ax,%ax
f010136f:	90                   	nop

f0101370 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101370:	55                   	push   %ebp
f0101371:	89 e5                	mov    %esp,%ebp
f0101373:	57                   	push   %edi
f0101374:	56                   	push   %esi
f0101375:	53                   	push   %ebx
f0101376:	83 ec 1c             	sub    $0x1c,%esp
f0101379:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010137c:	85 c0                	test   %eax,%eax
f010137e:	74 10                	je     f0101390 <readline+0x20>
		cprintf("%s", prompt);
f0101380:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101384:	c7 04 24 0a 21 10 f0 	movl   $0xf010210a,(%esp)
f010138b:	e8 5a f6 ff ff       	call   f01009ea <cprintf>

	i = 0;
	echoing = iscons(0);
f0101390:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101397:	e8 de f2 ff ff       	call   f010067a <iscons>
f010139c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010139e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013a3:	e8 c1 f2 ff ff       	call   f0100669 <getchar>
f01013a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013aa:	85 c0                	test   %eax,%eax
f01013ac:	79 17                	jns    f01013c5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01013ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013b2:	c7 04 24 ec 22 10 f0 	movl   $0xf01022ec,(%esp)
f01013b9:	e8 2c f6 ff ff       	call   f01009ea <cprintf>
			return NULL;
f01013be:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c3:	eb 6d                	jmp    f0101432 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013c5:	83 f8 7f             	cmp    $0x7f,%eax
f01013c8:	74 05                	je     f01013cf <readline+0x5f>
f01013ca:	83 f8 08             	cmp    $0x8,%eax
f01013cd:	75 19                	jne    f01013e8 <readline+0x78>
f01013cf:	85 f6                	test   %esi,%esi
f01013d1:	7e 15                	jle    f01013e8 <readline+0x78>
			if (echoing)
f01013d3:	85 ff                	test   %edi,%edi
f01013d5:	74 0c                	je     f01013e3 <readline+0x73>
				cputchar('\b');
f01013d7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01013de:	e8 76 f2 ff ff       	call   f0100659 <cputchar>
			i--;
f01013e3:	83 ee 01             	sub    $0x1,%esi
f01013e6:	eb bb                	jmp    f01013a3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013e8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013ee:	7f 1c                	jg     f010140c <readline+0x9c>
f01013f0:	83 fb 1f             	cmp    $0x1f,%ebx
f01013f3:	7e 17                	jle    f010140c <readline+0x9c>
			if (echoing)
f01013f5:	85 ff                	test   %edi,%edi
f01013f7:	74 08                	je     f0101401 <readline+0x91>
				cputchar(c);
f01013f9:	89 1c 24             	mov    %ebx,(%esp)
f01013fc:	e8 58 f2 ff ff       	call   f0100659 <cputchar>
			buf[i++] = c;
f0101401:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101407:	83 c6 01             	add    $0x1,%esi
f010140a:	eb 97                	jmp    f01013a3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010140c:	83 fb 0d             	cmp    $0xd,%ebx
f010140f:	74 05                	je     f0101416 <readline+0xa6>
f0101411:	83 fb 0a             	cmp    $0xa,%ebx
f0101414:	75 8d                	jne    f01013a3 <readline+0x33>
			if (echoing)
f0101416:	85 ff                	test   %edi,%edi
f0101418:	74 0c                	je     f0101426 <readline+0xb6>
				cputchar('\n');
f010141a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101421:	e8 33 f2 ff ff       	call   f0100659 <cputchar>
			buf[i] = 0;
f0101426:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010142d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101432:	83 c4 1c             	add    $0x1c,%esp
f0101435:	5b                   	pop    %ebx
f0101436:	5e                   	pop    %esi
f0101437:	5f                   	pop    %edi
f0101438:	5d                   	pop    %ebp
f0101439:	c3                   	ret    
f010143a:	66 90                	xchg   %ax,%ax
f010143c:	66 90                	xchg   %ax,%ax
f010143e:	66 90                	xchg   %ax,%ax

f0101440 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101440:	55                   	push   %ebp
f0101441:	89 e5                	mov    %esp,%ebp
f0101443:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101446:	80 3a 00             	cmpb   $0x0,(%edx)
f0101449:	74 10                	je     f010145b <strlen+0x1b>
f010144b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101450:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101453:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101457:	75 f7                	jne    f0101450 <strlen+0x10>
f0101459:	eb 05                	jmp    f0101460 <strlen+0x20>
f010145b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101460:	5d                   	pop    %ebp
f0101461:	c3                   	ret    

f0101462 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101462:	55                   	push   %ebp
f0101463:	89 e5                	mov    %esp,%ebp
f0101465:	53                   	push   %ebx
f0101466:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101469:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010146c:	85 c9                	test   %ecx,%ecx
f010146e:	74 1c                	je     f010148c <strnlen+0x2a>
f0101470:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101473:	74 1e                	je     f0101493 <strnlen+0x31>
f0101475:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010147a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010147c:	39 ca                	cmp    %ecx,%edx
f010147e:	74 18                	je     f0101498 <strnlen+0x36>
f0101480:	83 c2 01             	add    $0x1,%edx
f0101483:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101488:	75 f0                	jne    f010147a <strnlen+0x18>
f010148a:	eb 0c                	jmp    f0101498 <strnlen+0x36>
f010148c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101491:	eb 05                	jmp    f0101498 <strnlen+0x36>
f0101493:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101498:	5b                   	pop    %ebx
f0101499:	5d                   	pop    %ebp
f010149a:	c3                   	ret    

f010149b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010149b:	55                   	push   %ebp
f010149c:	89 e5                	mov    %esp,%ebp
f010149e:	53                   	push   %ebx
f010149f:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014a5:	89 c2                	mov    %eax,%edx
f01014a7:	0f b6 19             	movzbl (%ecx),%ebx
f01014aa:	88 1a                	mov    %bl,(%edx)
f01014ac:	83 c2 01             	add    $0x1,%edx
f01014af:	83 c1 01             	add    $0x1,%ecx
f01014b2:	84 db                	test   %bl,%bl
f01014b4:	75 f1                	jne    f01014a7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014b6:	5b                   	pop    %ebx
f01014b7:	5d                   	pop    %ebp
f01014b8:	c3                   	ret    

f01014b9 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014b9:	55                   	push   %ebp
f01014ba:	89 e5                	mov    %esp,%ebp
f01014bc:	53                   	push   %ebx
f01014bd:	83 ec 08             	sub    $0x8,%esp
f01014c0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014c3:	89 1c 24             	mov    %ebx,(%esp)
f01014c6:	e8 75 ff ff ff       	call   f0101440 <strlen>
	strcpy(dst + len, src);
f01014cb:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ce:	89 54 24 04          	mov    %edx,0x4(%esp)
f01014d2:	01 d8                	add    %ebx,%eax
f01014d4:	89 04 24             	mov    %eax,(%esp)
f01014d7:	e8 bf ff ff ff       	call   f010149b <strcpy>
	return dst;
}
f01014dc:	89 d8                	mov    %ebx,%eax
f01014de:	83 c4 08             	add    $0x8,%esp
f01014e1:	5b                   	pop    %ebx
f01014e2:	5d                   	pop    %ebp
f01014e3:	c3                   	ret    

f01014e4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014e4:	55                   	push   %ebp
f01014e5:	89 e5                	mov    %esp,%ebp
f01014e7:	56                   	push   %esi
f01014e8:	53                   	push   %ebx
f01014e9:	8b 75 08             	mov    0x8(%ebp),%esi
f01014ec:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ef:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014f2:	85 db                	test   %ebx,%ebx
f01014f4:	74 16                	je     f010150c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f01014f6:	01 f3                	add    %esi,%ebx
f01014f8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f01014fa:	0f b6 02             	movzbl (%edx),%eax
f01014fd:	88 01                	mov    %al,(%ecx)
f01014ff:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101502:	80 3a 01             	cmpb   $0x1,(%edx)
f0101505:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101508:	39 d9                	cmp    %ebx,%ecx
f010150a:	75 ee                	jne    f01014fa <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010150c:	89 f0                	mov    %esi,%eax
f010150e:	5b                   	pop    %ebx
f010150f:	5e                   	pop    %esi
f0101510:	5d                   	pop    %ebp
f0101511:	c3                   	ret    

f0101512 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101512:	55                   	push   %ebp
f0101513:	89 e5                	mov    %esp,%ebp
f0101515:	57                   	push   %edi
f0101516:	56                   	push   %esi
f0101517:	53                   	push   %ebx
f0101518:	8b 7d 08             	mov    0x8(%ebp),%edi
f010151b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010151e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101521:	89 f8                	mov    %edi,%eax
f0101523:	85 f6                	test   %esi,%esi
f0101525:	74 33                	je     f010155a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f0101527:	83 fe 01             	cmp    $0x1,%esi
f010152a:	74 25                	je     f0101551 <strlcpy+0x3f>
f010152c:	0f b6 0b             	movzbl (%ebx),%ecx
f010152f:	84 c9                	test   %cl,%cl
f0101531:	74 22                	je     f0101555 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101533:	83 ee 02             	sub    $0x2,%esi
f0101536:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010153b:	88 08                	mov    %cl,(%eax)
f010153d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101540:	39 f2                	cmp    %esi,%edx
f0101542:	74 13                	je     f0101557 <strlcpy+0x45>
f0101544:	83 c2 01             	add    $0x1,%edx
f0101547:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010154b:	84 c9                	test   %cl,%cl
f010154d:	75 ec                	jne    f010153b <strlcpy+0x29>
f010154f:	eb 06                	jmp    f0101557 <strlcpy+0x45>
f0101551:	89 f8                	mov    %edi,%eax
f0101553:	eb 02                	jmp    f0101557 <strlcpy+0x45>
f0101555:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101557:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010155a:	29 f8                	sub    %edi,%eax
}
f010155c:	5b                   	pop    %ebx
f010155d:	5e                   	pop    %esi
f010155e:	5f                   	pop    %edi
f010155f:	5d                   	pop    %ebp
f0101560:	c3                   	ret    

f0101561 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101561:	55                   	push   %ebp
f0101562:	89 e5                	mov    %esp,%ebp
f0101564:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101567:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010156a:	0f b6 01             	movzbl (%ecx),%eax
f010156d:	84 c0                	test   %al,%al
f010156f:	74 15                	je     f0101586 <strcmp+0x25>
f0101571:	3a 02                	cmp    (%edx),%al
f0101573:	75 11                	jne    f0101586 <strcmp+0x25>
		p++, q++;
f0101575:	83 c1 01             	add    $0x1,%ecx
f0101578:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010157b:	0f b6 01             	movzbl (%ecx),%eax
f010157e:	84 c0                	test   %al,%al
f0101580:	74 04                	je     f0101586 <strcmp+0x25>
f0101582:	3a 02                	cmp    (%edx),%al
f0101584:	74 ef                	je     f0101575 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101586:	0f b6 c0             	movzbl %al,%eax
f0101589:	0f b6 12             	movzbl (%edx),%edx
f010158c:	29 d0                	sub    %edx,%eax
}
f010158e:	5d                   	pop    %ebp
f010158f:	c3                   	ret    

f0101590 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101590:	55                   	push   %ebp
f0101591:	89 e5                	mov    %esp,%ebp
f0101593:	56                   	push   %esi
f0101594:	53                   	push   %ebx
f0101595:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101598:	8b 55 0c             	mov    0xc(%ebp),%edx
f010159b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f010159e:	85 f6                	test   %esi,%esi
f01015a0:	74 29                	je     f01015cb <strncmp+0x3b>
f01015a2:	0f b6 03             	movzbl (%ebx),%eax
f01015a5:	84 c0                	test   %al,%al
f01015a7:	74 30                	je     f01015d9 <strncmp+0x49>
f01015a9:	3a 02                	cmp    (%edx),%al
f01015ab:	75 2c                	jne    f01015d9 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f01015ad:	8d 43 01             	lea    0x1(%ebx),%eax
f01015b0:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f01015b2:	89 c3                	mov    %eax,%ebx
f01015b4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015b7:	39 f0                	cmp    %esi,%eax
f01015b9:	74 17                	je     f01015d2 <strncmp+0x42>
f01015bb:	0f b6 08             	movzbl (%eax),%ecx
f01015be:	84 c9                	test   %cl,%cl
f01015c0:	74 17                	je     f01015d9 <strncmp+0x49>
f01015c2:	83 c0 01             	add    $0x1,%eax
f01015c5:	3a 0a                	cmp    (%edx),%cl
f01015c7:	74 e9                	je     f01015b2 <strncmp+0x22>
f01015c9:	eb 0e                	jmp    f01015d9 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01015d0:	eb 0f                	jmp    f01015e1 <strncmp+0x51>
f01015d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01015d7:	eb 08                	jmp    f01015e1 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015d9:	0f b6 03             	movzbl (%ebx),%eax
f01015dc:	0f b6 12             	movzbl (%edx),%edx
f01015df:	29 d0                	sub    %edx,%eax
}
f01015e1:	5b                   	pop    %ebx
f01015e2:	5e                   	pop    %esi
f01015e3:	5d                   	pop    %ebp
f01015e4:	c3                   	ret    

f01015e5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015e5:	55                   	push   %ebp
f01015e6:	89 e5                	mov    %esp,%ebp
f01015e8:	53                   	push   %ebx
f01015e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ec:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01015ef:	0f b6 18             	movzbl (%eax),%ebx
f01015f2:	84 db                	test   %bl,%bl
f01015f4:	74 1d                	je     f0101613 <strchr+0x2e>
f01015f6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01015f8:	38 d3                	cmp    %dl,%bl
f01015fa:	75 06                	jne    f0101602 <strchr+0x1d>
f01015fc:	eb 1a                	jmp    f0101618 <strchr+0x33>
f01015fe:	38 ca                	cmp    %cl,%dl
f0101600:	74 16                	je     f0101618 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101602:	83 c0 01             	add    $0x1,%eax
f0101605:	0f b6 10             	movzbl (%eax),%edx
f0101608:	84 d2                	test   %dl,%dl
f010160a:	75 f2                	jne    f01015fe <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f010160c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101611:	eb 05                	jmp    f0101618 <strchr+0x33>
f0101613:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101618:	5b                   	pop    %ebx
f0101619:	5d                   	pop    %ebp
f010161a:	c3                   	ret    

f010161b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010161b:	55                   	push   %ebp
f010161c:	89 e5                	mov    %esp,%ebp
f010161e:	53                   	push   %ebx
f010161f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101622:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101625:	0f b6 18             	movzbl (%eax),%ebx
f0101628:	84 db                	test   %bl,%bl
f010162a:	74 16                	je     f0101642 <strfind+0x27>
f010162c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f010162e:	38 d3                	cmp    %dl,%bl
f0101630:	75 06                	jne    f0101638 <strfind+0x1d>
f0101632:	eb 0e                	jmp    f0101642 <strfind+0x27>
f0101634:	38 ca                	cmp    %cl,%dl
f0101636:	74 0a                	je     f0101642 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101638:	83 c0 01             	add    $0x1,%eax
f010163b:	0f b6 10             	movzbl (%eax),%edx
f010163e:	84 d2                	test   %dl,%dl
f0101640:	75 f2                	jne    f0101634 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f0101642:	5b                   	pop    %ebx
f0101643:	5d                   	pop    %ebp
f0101644:	c3                   	ret    

f0101645 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101645:	55                   	push   %ebp
f0101646:	89 e5                	mov    %esp,%ebp
f0101648:	83 ec 0c             	sub    $0xc,%esp
f010164b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010164e:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101651:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101654:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101657:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010165a:	85 c9                	test   %ecx,%ecx
f010165c:	74 36                	je     f0101694 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010165e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101664:	75 28                	jne    f010168e <memset+0x49>
f0101666:	f6 c1 03             	test   $0x3,%cl
f0101669:	75 23                	jne    f010168e <memset+0x49>
		c &= 0xFF;
f010166b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010166f:	89 d3                	mov    %edx,%ebx
f0101671:	c1 e3 08             	shl    $0x8,%ebx
f0101674:	89 d6                	mov    %edx,%esi
f0101676:	c1 e6 18             	shl    $0x18,%esi
f0101679:	89 d0                	mov    %edx,%eax
f010167b:	c1 e0 10             	shl    $0x10,%eax
f010167e:	09 f0                	or     %esi,%eax
f0101680:	09 c2                	or     %eax,%edx
f0101682:	89 d0                	mov    %edx,%eax
f0101684:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101686:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101689:	fc                   	cld    
f010168a:	f3 ab                	rep stos %eax,%es:(%edi)
f010168c:	eb 06                	jmp    f0101694 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010168e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101691:	fc                   	cld    
f0101692:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101694:	89 f8                	mov    %edi,%eax
f0101696:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101699:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010169c:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010169f:	89 ec                	mov    %ebp,%esp
f01016a1:	5d                   	pop    %ebp
f01016a2:	c3                   	ret    

f01016a3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016a3:	55                   	push   %ebp
f01016a4:	89 e5                	mov    %esp,%ebp
f01016a6:	83 ec 08             	sub    $0x8,%esp
f01016a9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01016ac:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01016af:	8b 45 08             	mov    0x8(%ebp),%eax
f01016b2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016b5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01016b8:	39 c6                	cmp    %eax,%esi
f01016ba:	73 36                	jae    f01016f2 <memmove+0x4f>
f01016bc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016bf:	39 d0                	cmp    %edx,%eax
f01016c1:	73 2f                	jae    f01016f2 <memmove+0x4f>
		s += n;
		d += n;
f01016c3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016c6:	f6 c2 03             	test   $0x3,%dl
f01016c9:	75 1b                	jne    f01016e6 <memmove+0x43>
f01016cb:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016d1:	75 13                	jne    f01016e6 <memmove+0x43>
f01016d3:	f6 c1 03             	test   $0x3,%cl
f01016d6:	75 0e                	jne    f01016e6 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01016d8:	83 ef 04             	sub    $0x4,%edi
f01016db:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016de:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01016e1:	fd                   	std    
f01016e2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016e4:	eb 09                	jmp    f01016ef <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01016e6:	83 ef 01             	sub    $0x1,%edi
f01016e9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016ec:	fd                   	std    
f01016ed:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016ef:	fc                   	cld    
f01016f0:	eb 20                	jmp    f0101712 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016f2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01016f8:	75 13                	jne    f010170d <memmove+0x6a>
f01016fa:	a8 03                	test   $0x3,%al
f01016fc:	75 0f                	jne    f010170d <memmove+0x6a>
f01016fe:	f6 c1 03             	test   $0x3,%cl
f0101701:	75 0a                	jne    f010170d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101703:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101706:	89 c7                	mov    %eax,%edi
f0101708:	fc                   	cld    
f0101709:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010170b:	eb 05                	jmp    f0101712 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010170d:	89 c7                	mov    %eax,%edi
f010170f:	fc                   	cld    
f0101710:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101712:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101715:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101718:	89 ec                	mov    %ebp,%esp
f010171a:	5d                   	pop    %ebp
f010171b:	c3                   	ret    

f010171c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010171c:	55                   	push   %ebp
f010171d:	89 e5                	mov    %esp,%ebp
f010171f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101722:	8b 45 10             	mov    0x10(%ebp),%eax
f0101725:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101729:	8b 45 0c             	mov    0xc(%ebp),%eax
f010172c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101730:	8b 45 08             	mov    0x8(%ebp),%eax
f0101733:	89 04 24             	mov    %eax,(%esp)
f0101736:	e8 68 ff ff ff       	call   f01016a3 <memmove>
}
f010173b:	c9                   	leave  
f010173c:	c3                   	ret    

f010173d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010173d:	55                   	push   %ebp
f010173e:	89 e5                	mov    %esp,%ebp
f0101740:	57                   	push   %edi
f0101741:	56                   	push   %esi
f0101742:	53                   	push   %ebx
f0101743:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101746:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101749:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010174c:	8d 78 ff             	lea    -0x1(%eax),%edi
f010174f:	85 c0                	test   %eax,%eax
f0101751:	74 36                	je     f0101789 <memcmp+0x4c>
		if (*s1 != *s2)
f0101753:	0f b6 03             	movzbl (%ebx),%eax
f0101756:	0f b6 0e             	movzbl (%esi),%ecx
f0101759:	38 c8                	cmp    %cl,%al
f010175b:	75 17                	jne    f0101774 <memcmp+0x37>
f010175d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101762:	eb 1a                	jmp    f010177e <memcmp+0x41>
f0101764:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101769:	83 c2 01             	add    $0x1,%edx
f010176c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101770:	38 c8                	cmp    %cl,%al
f0101772:	74 0a                	je     f010177e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0101774:	0f b6 c0             	movzbl %al,%eax
f0101777:	0f b6 c9             	movzbl %cl,%ecx
f010177a:	29 c8                	sub    %ecx,%eax
f010177c:	eb 10                	jmp    f010178e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010177e:	39 fa                	cmp    %edi,%edx
f0101780:	75 e2                	jne    f0101764 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101782:	b8 00 00 00 00       	mov    $0x0,%eax
f0101787:	eb 05                	jmp    f010178e <memcmp+0x51>
f0101789:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010178e:	5b                   	pop    %ebx
f010178f:	5e                   	pop    %esi
f0101790:	5f                   	pop    %edi
f0101791:	5d                   	pop    %ebp
f0101792:	c3                   	ret    

f0101793 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101793:	55                   	push   %ebp
f0101794:	89 e5                	mov    %esp,%ebp
f0101796:	53                   	push   %ebx
f0101797:	8b 45 08             	mov    0x8(%ebp),%eax
f010179a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f010179d:	89 c2                	mov    %eax,%edx
f010179f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017a2:	39 d0                	cmp    %edx,%eax
f01017a4:	73 13                	jae    f01017b9 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017a6:	89 d9                	mov    %ebx,%ecx
f01017a8:	38 18                	cmp    %bl,(%eax)
f01017aa:	75 06                	jne    f01017b2 <memfind+0x1f>
f01017ac:	eb 0b                	jmp    f01017b9 <memfind+0x26>
f01017ae:	38 08                	cmp    %cl,(%eax)
f01017b0:	74 07                	je     f01017b9 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01017b2:	83 c0 01             	add    $0x1,%eax
f01017b5:	39 d0                	cmp    %edx,%eax
f01017b7:	75 f5                	jne    f01017ae <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01017b9:	5b                   	pop    %ebx
f01017ba:	5d                   	pop    %ebp
f01017bb:	c3                   	ret    

f01017bc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017bc:	55                   	push   %ebp
f01017bd:	89 e5                	mov    %esp,%ebp
f01017bf:	57                   	push   %edi
f01017c0:	56                   	push   %esi
f01017c1:	53                   	push   %ebx
f01017c2:	83 ec 04             	sub    $0x4,%esp
f01017c5:	8b 55 08             	mov    0x8(%ebp),%edx
f01017c8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017cb:	0f b6 02             	movzbl (%edx),%eax
f01017ce:	3c 09                	cmp    $0x9,%al
f01017d0:	74 04                	je     f01017d6 <strtol+0x1a>
f01017d2:	3c 20                	cmp    $0x20,%al
f01017d4:	75 0e                	jne    f01017e4 <strtol+0x28>
		s++;
f01017d6:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017d9:	0f b6 02             	movzbl (%edx),%eax
f01017dc:	3c 09                	cmp    $0x9,%al
f01017de:	74 f6                	je     f01017d6 <strtol+0x1a>
f01017e0:	3c 20                	cmp    $0x20,%al
f01017e2:	74 f2                	je     f01017d6 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01017e4:	3c 2b                	cmp    $0x2b,%al
f01017e6:	75 0a                	jne    f01017f2 <strtol+0x36>
		s++;
f01017e8:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01017eb:	bf 00 00 00 00       	mov    $0x0,%edi
f01017f0:	eb 10                	jmp    f0101802 <strtol+0x46>
f01017f2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01017f7:	3c 2d                	cmp    $0x2d,%al
f01017f9:	75 07                	jne    f0101802 <strtol+0x46>
		s++, neg = 1;
f01017fb:	83 c2 01             	add    $0x1,%edx
f01017fe:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101802:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101808:	75 15                	jne    f010181f <strtol+0x63>
f010180a:	80 3a 30             	cmpb   $0x30,(%edx)
f010180d:	75 10                	jne    f010181f <strtol+0x63>
f010180f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101813:	75 0a                	jne    f010181f <strtol+0x63>
		s += 2, base = 16;
f0101815:	83 c2 02             	add    $0x2,%edx
f0101818:	bb 10 00 00 00       	mov    $0x10,%ebx
f010181d:	eb 10                	jmp    f010182f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f010181f:	85 db                	test   %ebx,%ebx
f0101821:	75 0c                	jne    f010182f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101823:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101825:	80 3a 30             	cmpb   $0x30,(%edx)
f0101828:	75 05                	jne    f010182f <strtol+0x73>
		s++, base = 8;
f010182a:	83 c2 01             	add    $0x1,%edx
f010182d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010182f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101834:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101837:	0f b6 0a             	movzbl (%edx),%ecx
f010183a:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010183d:	89 f3                	mov    %esi,%ebx
f010183f:	80 fb 09             	cmp    $0x9,%bl
f0101842:	77 08                	ja     f010184c <strtol+0x90>
			dig = *s - '0';
f0101844:	0f be c9             	movsbl %cl,%ecx
f0101847:	83 e9 30             	sub    $0x30,%ecx
f010184a:	eb 22                	jmp    f010186e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f010184c:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010184f:	89 f3                	mov    %esi,%ebx
f0101851:	80 fb 19             	cmp    $0x19,%bl
f0101854:	77 08                	ja     f010185e <strtol+0xa2>
			dig = *s - 'a' + 10;
f0101856:	0f be c9             	movsbl %cl,%ecx
f0101859:	83 e9 57             	sub    $0x57,%ecx
f010185c:	eb 10                	jmp    f010186e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f010185e:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0101861:	89 f3                	mov    %esi,%ebx
f0101863:	80 fb 19             	cmp    $0x19,%bl
f0101866:	77 16                	ja     f010187e <strtol+0xc2>
			dig = *s - 'A' + 10;
f0101868:	0f be c9             	movsbl %cl,%ecx
f010186b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010186e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0101871:	7d 0f                	jge    f0101882 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0101873:	83 c2 01             	add    $0x1,%edx
f0101876:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f010187a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010187c:	eb b9                	jmp    f0101837 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f010187e:	89 c1                	mov    %eax,%ecx
f0101880:	eb 02                	jmp    f0101884 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101882:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101884:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101888:	74 05                	je     f010188f <strtol+0xd3>
		*endptr = (char *) s;
f010188a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010188d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f010188f:	89 ca                	mov    %ecx,%edx
f0101891:	f7 da                	neg    %edx
f0101893:	85 ff                	test   %edi,%edi
f0101895:	0f 45 c2             	cmovne %edx,%eax
}
f0101898:	83 c4 04             	add    $0x4,%esp
f010189b:	5b                   	pop    %ebx
f010189c:	5e                   	pop    %esi
f010189d:	5f                   	pop    %edi
f010189e:	5d                   	pop    %ebp
f010189f:	c3                   	ret    

f01018a0 <__udivdi3>:
f01018a0:	83 ec 1c             	sub    $0x1c,%esp
f01018a3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f01018a7:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01018ab:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01018af:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01018b3:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01018b7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f01018bb:	85 c0                	test   %eax,%eax
f01018bd:	89 74 24 10          	mov    %esi,0x10(%esp)
f01018c1:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01018c5:	89 ea                	mov    %ebp,%edx
f01018c7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01018cb:	75 33                	jne    f0101900 <__udivdi3+0x60>
f01018cd:	39 e9                	cmp    %ebp,%ecx
f01018cf:	77 6f                	ja     f0101940 <__udivdi3+0xa0>
f01018d1:	85 c9                	test   %ecx,%ecx
f01018d3:	89 ce                	mov    %ecx,%esi
f01018d5:	75 0b                	jne    f01018e2 <__udivdi3+0x42>
f01018d7:	b8 01 00 00 00       	mov    $0x1,%eax
f01018dc:	31 d2                	xor    %edx,%edx
f01018de:	f7 f1                	div    %ecx
f01018e0:	89 c6                	mov    %eax,%esi
f01018e2:	31 d2                	xor    %edx,%edx
f01018e4:	89 e8                	mov    %ebp,%eax
f01018e6:	f7 f6                	div    %esi
f01018e8:	89 c5                	mov    %eax,%ebp
f01018ea:	89 f8                	mov    %edi,%eax
f01018ec:	f7 f6                	div    %esi
f01018ee:	89 ea                	mov    %ebp,%edx
f01018f0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018f4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018f8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018fc:	83 c4 1c             	add    $0x1c,%esp
f01018ff:	c3                   	ret    
f0101900:	39 e8                	cmp    %ebp,%eax
f0101902:	77 24                	ja     f0101928 <__udivdi3+0x88>
f0101904:	0f bd c8             	bsr    %eax,%ecx
f0101907:	83 f1 1f             	xor    $0x1f,%ecx
f010190a:	89 0c 24             	mov    %ecx,(%esp)
f010190d:	75 49                	jne    f0101958 <__udivdi3+0xb8>
f010190f:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101913:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0101917:	0f 86 ab 00 00 00    	jbe    f01019c8 <__udivdi3+0x128>
f010191d:	39 e8                	cmp    %ebp,%eax
f010191f:	0f 82 a3 00 00 00    	jb     f01019c8 <__udivdi3+0x128>
f0101925:	8d 76 00             	lea    0x0(%esi),%esi
f0101928:	31 d2                	xor    %edx,%edx
f010192a:	31 c0                	xor    %eax,%eax
f010192c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101930:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101934:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101938:	83 c4 1c             	add    $0x1c,%esp
f010193b:	c3                   	ret    
f010193c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101940:	89 f8                	mov    %edi,%eax
f0101942:	f7 f1                	div    %ecx
f0101944:	31 d2                	xor    %edx,%edx
f0101946:	8b 74 24 10          	mov    0x10(%esp),%esi
f010194a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010194e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101952:	83 c4 1c             	add    $0x1c,%esp
f0101955:	c3                   	ret    
f0101956:	66 90                	xchg   %ax,%ax
f0101958:	0f b6 0c 24          	movzbl (%esp),%ecx
f010195c:	89 c6                	mov    %eax,%esi
f010195e:	b8 20 00 00 00       	mov    $0x20,%eax
f0101963:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0101967:	2b 04 24             	sub    (%esp),%eax
f010196a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010196e:	d3 e6                	shl    %cl,%esi
f0101970:	89 c1                	mov    %eax,%ecx
f0101972:	d3 ed                	shr    %cl,%ebp
f0101974:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101978:	09 f5                	or     %esi,%ebp
f010197a:	8b 74 24 04          	mov    0x4(%esp),%esi
f010197e:	d3 e6                	shl    %cl,%esi
f0101980:	89 c1                	mov    %eax,%ecx
f0101982:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101986:	89 d6                	mov    %edx,%esi
f0101988:	d3 ee                	shr    %cl,%esi
f010198a:	0f b6 0c 24          	movzbl (%esp),%ecx
f010198e:	d3 e2                	shl    %cl,%edx
f0101990:	89 c1                	mov    %eax,%ecx
f0101992:	d3 ef                	shr    %cl,%edi
f0101994:	09 d7                	or     %edx,%edi
f0101996:	89 f2                	mov    %esi,%edx
f0101998:	89 f8                	mov    %edi,%eax
f010199a:	f7 f5                	div    %ebp
f010199c:	89 d6                	mov    %edx,%esi
f010199e:	89 c7                	mov    %eax,%edi
f01019a0:	f7 64 24 04          	mull   0x4(%esp)
f01019a4:	39 d6                	cmp    %edx,%esi
f01019a6:	72 30                	jb     f01019d8 <__udivdi3+0x138>
f01019a8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01019ac:	0f b6 0c 24          	movzbl (%esp),%ecx
f01019b0:	d3 e5                	shl    %cl,%ebp
f01019b2:	39 c5                	cmp    %eax,%ebp
f01019b4:	73 04                	jae    f01019ba <__udivdi3+0x11a>
f01019b6:	39 d6                	cmp    %edx,%esi
f01019b8:	74 1e                	je     f01019d8 <__udivdi3+0x138>
f01019ba:	89 f8                	mov    %edi,%eax
f01019bc:	31 d2                	xor    %edx,%edx
f01019be:	e9 69 ff ff ff       	jmp    f010192c <__udivdi3+0x8c>
f01019c3:	90                   	nop
f01019c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019c8:	31 d2                	xor    %edx,%edx
f01019ca:	b8 01 00 00 00       	mov    $0x1,%eax
f01019cf:	e9 58 ff ff ff       	jmp    f010192c <__udivdi3+0x8c>
f01019d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019d8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01019db:	31 d2                	xor    %edx,%edx
f01019dd:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019e1:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019e5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019e9:	83 c4 1c             	add    $0x1c,%esp
f01019ec:	c3                   	ret    
f01019ed:	66 90                	xchg   %ax,%ax
f01019ef:	90                   	nop

f01019f0 <__umoddi3>:
f01019f0:	83 ec 2c             	sub    $0x2c,%esp
f01019f3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01019f7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01019fb:	89 74 24 20          	mov    %esi,0x20(%esp)
f01019ff:	8b 74 24 38          	mov    0x38(%esp),%esi
f0101a03:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0101a07:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0101a0b:	85 c0                	test   %eax,%eax
f0101a0d:	89 c2                	mov    %eax,%edx
f0101a0f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0101a13:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101a17:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a1b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101a1f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101a23:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101a27:	75 1f                	jne    f0101a48 <__umoddi3+0x58>
f0101a29:	39 fe                	cmp    %edi,%esi
f0101a2b:	76 63                	jbe    f0101a90 <__umoddi3+0xa0>
f0101a2d:	89 c8                	mov    %ecx,%eax
f0101a2f:	89 fa                	mov    %edi,%edx
f0101a31:	f7 f6                	div    %esi
f0101a33:	89 d0                	mov    %edx,%eax
f0101a35:	31 d2                	xor    %edx,%edx
f0101a37:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101a3b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101a3f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101a43:	83 c4 2c             	add    $0x2c,%esp
f0101a46:	c3                   	ret    
f0101a47:	90                   	nop
f0101a48:	39 f8                	cmp    %edi,%eax
f0101a4a:	77 64                	ja     f0101ab0 <__umoddi3+0xc0>
f0101a4c:	0f bd e8             	bsr    %eax,%ebp
f0101a4f:	83 f5 1f             	xor    $0x1f,%ebp
f0101a52:	75 74                	jne    f0101ac8 <__umoddi3+0xd8>
f0101a54:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a58:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f0101a5c:	0f 87 0e 01 00 00    	ja     f0101b70 <__umoddi3+0x180>
f0101a62:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0101a66:	29 f1                	sub    %esi,%ecx
f0101a68:	19 c7                	sbb    %eax,%edi
f0101a6a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101a6e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101a72:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101a76:	8b 54 24 18          	mov    0x18(%esp),%edx
f0101a7a:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101a7e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101a82:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101a86:	83 c4 2c             	add    $0x2c,%esp
f0101a89:	c3                   	ret    
f0101a8a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a90:	85 f6                	test   %esi,%esi
f0101a92:	89 f5                	mov    %esi,%ebp
f0101a94:	75 0b                	jne    f0101aa1 <__umoddi3+0xb1>
f0101a96:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a9b:	31 d2                	xor    %edx,%edx
f0101a9d:	f7 f6                	div    %esi
f0101a9f:	89 c5                	mov    %eax,%ebp
f0101aa1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101aa5:	31 d2                	xor    %edx,%edx
f0101aa7:	f7 f5                	div    %ebp
f0101aa9:	89 c8                	mov    %ecx,%eax
f0101aab:	f7 f5                	div    %ebp
f0101aad:	eb 84                	jmp    f0101a33 <__umoddi3+0x43>
f0101aaf:	90                   	nop
f0101ab0:	89 c8                	mov    %ecx,%eax
f0101ab2:	89 fa                	mov    %edi,%edx
f0101ab4:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101ab8:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101abc:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101ac0:	83 c4 2c             	add    $0x2c,%esp
f0101ac3:	c3                   	ret    
f0101ac4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ac8:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101acc:	be 20 00 00 00       	mov    $0x20,%esi
f0101ad1:	89 e9                	mov    %ebp,%ecx
f0101ad3:	29 ee                	sub    %ebp,%esi
f0101ad5:	d3 e2                	shl    %cl,%edx
f0101ad7:	89 f1                	mov    %esi,%ecx
f0101ad9:	d3 e8                	shr    %cl,%eax
f0101adb:	89 e9                	mov    %ebp,%ecx
f0101add:	09 d0                	or     %edx,%eax
f0101adf:	89 fa                	mov    %edi,%edx
f0101ae1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ae5:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101ae9:	d3 e0                	shl    %cl,%eax
f0101aeb:	89 f1                	mov    %esi,%ecx
f0101aed:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101af1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0101af5:	d3 ea                	shr    %cl,%edx
f0101af7:	89 e9                	mov    %ebp,%ecx
f0101af9:	d3 e7                	shl    %cl,%edi
f0101afb:	89 f1                	mov    %esi,%ecx
f0101afd:	d3 e8                	shr    %cl,%eax
f0101aff:	89 e9                	mov    %ebp,%ecx
f0101b01:	09 f8                	or     %edi,%eax
f0101b03:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0101b07:	f7 74 24 0c          	divl   0xc(%esp)
f0101b0b:	d3 e7                	shl    %cl,%edi
f0101b0d:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101b11:	89 d7                	mov    %edx,%edi
f0101b13:	f7 64 24 10          	mull   0x10(%esp)
f0101b17:	39 d7                	cmp    %edx,%edi
f0101b19:	89 c1                	mov    %eax,%ecx
f0101b1b:	89 54 24 14          	mov    %edx,0x14(%esp)
f0101b1f:	72 3b                	jb     f0101b5c <__umoddi3+0x16c>
f0101b21:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0101b25:	72 31                	jb     f0101b58 <__umoddi3+0x168>
f0101b27:	8b 44 24 18          	mov    0x18(%esp),%eax
f0101b2b:	29 c8                	sub    %ecx,%eax
f0101b2d:	19 d7                	sbb    %edx,%edi
f0101b2f:	89 e9                	mov    %ebp,%ecx
f0101b31:	89 fa                	mov    %edi,%edx
f0101b33:	d3 e8                	shr    %cl,%eax
f0101b35:	89 f1                	mov    %esi,%ecx
f0101b37:	d3 e2                	shl    %cl,%edx
f0101b39:	89 e9                	mov    %ebp,%ecx
f0101b3b:	09 d0                	or     %edx,%eax
f0101b3d:	89 fa                	mov    %edi,%edx
f0101b3f:	d3 ea                	shr    %cl,%edx
f0101b41:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101b45:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101b49:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101b4d:	83 c4 2c             	add    $0x2c,%esp
f0101b50:	c3                   	ret    
f0101b51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b58:	39 d7                	cmp    %edx,%edi
f0101b5a:	75 cb                	jne    f0101b27 <__umoddi3+0x137>
f0101b5c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0101b60:	89 c1                	mov    %eax,%ecx
f0101b62:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0101b66:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0101b6a:	eb bb                	jmp    f0101b27 <__umoddi3+0x137>
f0101b6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b70:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101b74:	0f 82 e8 fe ff ff    	jb     f0101a62 <__umoddi3+0x72>
f0101b7a:	e9 f3 fe ff ff       	jmp    f0101a72 <__umoddi3+0x82>

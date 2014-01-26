
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 8c 79 11 f0       	mov    $0xf011798c,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 c7 38 00 00       	call   f010392f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 9a 04 00 00       	call   f0100507 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 80 3e 10 f0 	movl   $0xf0103e80,(%esp)
f010007c:	e8 e5 2c 00 00       	call   f0102d66 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 a4 11 00 00       	call   f010122a <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 60 07 00 00       	call   f01007f2 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 00 73 11 f0 00 	cmpl   $0x0,0xf0117300
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 00 73 11 f0    	mov    %esi,0xf0117300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 9b 3e 10 f0 	movl   $0xf0103e9b,(%esp)
f01000c8:	e8 99 2c 00 00       	call   f0102d66 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 5a 2c 00 00       	call   f0102d33 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 6b 4a 10 f0 	movl   $0xf0104a6b,(%esp)
f01000e0:	e8 81 2c 00 00       	call   f0102d66 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 01 07 00 00       	call   f01007f2 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 b3 3e 10 f0 	movl   $0xf0103eb3,(%esp)
f0100112:	e8 4f 2c 00 00       	call   f0102d66 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 0d 2c 00 00       	call   f0102d33 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 6b 4a 10 f0 	movl   $0xf0104a6b,(%esp)
f010012d:	e8 34 2c 00 00       	call   f0102d66 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100157:	a8 01                	test   $0x1,%al
f0100159:	74 08                	je     f0100163 <serial_proc_data+0x15>
f010015b:	b2 f8                	mov    $0xf8,%dl
f010015d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010015e:	0f b6 c0             	movzbl %al,%eax
f0100161:	eb 05                	jmp    f0100168 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100163:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 26                	jmp    f010019b <cons_intr+0x31>
		if (c == 0)
f0100175:	85 d2                	test   %edx,%edx
f0100177:	74 22                	je     f010019b <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	a1 44 75 11 f0       	mov    0xf0117544,%eax
f010017e:	88 90 40 73 11 f0    	mov    %dl,-0xfee8cc0(%eax)
f0100184:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f0100187:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f010018d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100192:	0f 44 d0             	cmove  %eax,%edx
f0100195:	89 15 44 75 11 f0    	mov    %edx,0xf0117544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019b:	ff d3                	call   *%ebx
f010019d:	89 c2                	mov    %eax,%edx
f010019f:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a2:	75 d1                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a4:	83 c4 04             	add    $0x4,%esp
f01001a7:	5b                   	pop    %ebx
f01001a8:	5d                   	pop    %ebp
f01001a9:	c3                   	ret    

f01001aa <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001aa:	55                   	push   %ebp
f01001ab:	89 e5                	mov    %esp,%ebp
f01001ad:	57                   	push   %edi
f01001ae:	56                   	push   %esi
f01001af:	53                   	push   %ebx
f01001b0:	83 ec 2c             	sub    $0x2c,%esp
f01001b3:	89 c7                	mov    %eax,%edi
f01001b5:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001ba:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001bb:	a8 20                	test   $0x20,%al
f01001bd:	75 1b                	jne    f01001da <cons_putc+0x30>
f01001bf:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c4:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c9:	e8 72 ff ff ff       	call   f0100140 <delay>
f01001ce:	89 f2                	mov    %esi,%edx
f01001d0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001d1:	a8 20                	test   $0x20,%al
f01001d3:	75 05                	jne    f01001da <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d5:	83 eb 01             	sub    $0x1,%ebx
f01001d8:	75 ef                	jne    f01001c9 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01001da:	89 f8                	mov    %edi,%eax
f01001dc:	25 ff 00 00 00       	and    $0xff,%eax
f01001e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001e4:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001ea:	b2 79                	mov    $0x79,%dl
f01001ec:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001ed:	84 c0                	test   %al,%al
f01001ef:	78 1b                	js     f010020c <cons_putc+0x62>
f01001f1:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f6:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01001fb:	e8 40 ff ff ff       	call   f0100140 <delay>
f0100200:	89 f2                	mov    %esi,%edx
f0100202:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100203:	84 c0                	test   %al,%al
f0100205:	78 05                	js     f010020c <cons_putc+0x62>
f0100207:	83 eb 01             	sub    $0x1,%ebx
f010020a:	75 ef                	jne    f01001fb <cons_putc+0x51>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010020c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100211:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100215:	ee                   	out    %al,(%dx)
f0100216:	b2 7a                	mov    $0x7a,%dl
f0100218:	b8 0d 00 00 00       	mov    $0xd,%eax
f010021d:	ee                   	out    %al,(%dx)
f010021e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100223:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100224:	89 fa                	mov    %edi,%edx
f0100226:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010022c:	89 f8                	mov    %edi,%eax
f010022e:	80 cc 07             	or     $0x7,%ah
f0100231:	85 d2                	test   %edx,%edx
f0100233:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100236:	89 f8                	mov    %edi,%eax
f0100238:	25 ff 00 00 00       	and    $0xff,%eax
f010023d:	83 f8 09             	cmp    $0x9,%eax
f0100240:	74 77                	je     f01002b9 <cons_putc+0x10f>
f0100242:	83 f8 09             	cmp    $0x9,%eax
f0100245:	7f 0b                	jg     f0100252 <cons_putc+0xa8>
f0100247:	83 f8 08             	cmp    $0x8,%eax
f010024a:	0f 85 9d 00 00 00    	jne    f01002ed <cons_putc+0x143>
f0100250:	eb 10                	jmp    f0100262 <cons_putc+0xb8>
f0100252:	83 f8 0a             	cmp    $0xa,%eax
f0100255:	74 3c                	je     f0100293 <cons_putc+0xe9>
f0100257:	83 f8 0d             	cmp    $0xd,%eax
f010025a:	0f 85 8d 00 00 00    	jne    f01002ed <cons_putc+0x143>
f0100260:	eb 39                	jmp    f010029b <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f0100262:	0f b7 05 54 75 11 f0 	movzwl 0xf0117554,%eax
f0100269:	66 85 c0             	test   %ax,%ax
f010026c:	0f 84 e5 00 00 00    	je     f0100357 <cons_putc+0x1ad>
			crt_pos--;
f0100272:	83 e8 01             	sub    $0x1,%eax
f0100275:	66 a3 54 75 11 f0    	mov    %ax,0xf0117554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027b:	0f b7 c0             	movzwl %ax,%eax
f010027e:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f0100284:	83 cf 20             	or     $0x20,%edi
f0100287:	8b 15 50 75 11 f0    	mov    0xf0117550,%edx
f010028d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100291:	eb 77                	jmp    f010030a <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100293:	66 83 05 54 75 11 f0 	addw   $0x50,0xf0117554
f010029a:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010029b:	0f b7 05 54 75 11 f0 	movzwl 0xf0117554,%eax
f01002a2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a8:	c1 e8 16             	shr    $0x16,%eax
f01002ab:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ae:	c1 e0 04             	shl    $0x4,%eax
f01002b1:	66 a3 54 75 11 f0    	mov    %ax,0xf0117554
f01002b7:	eb 51                	jmp    f010030a <cons_putc+0x160>
		break;
	case '\t':
		cons_putc(' ');
f01002b9:	b8 20 00 00 00       	mov    $0x20,%eax
f01002be:	e8 e7 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002c3:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c8:	e8 dd fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002cd:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d2:	e8 d3 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002d7:	b8 20 00 00 00       	mov    $0x20,%eax
f01002dc:	e8 c9 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002e1:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e6:	e8 bf fe ff ff       	call   f01001aa <cons_putc>
f01002eb:	eb 1d                	jmp    f010030a <cons_putc+0x160>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002ed:	0f b7 05 54 75 11 f0 	movzwl 0xf0117554,%eax
f01002f4:	0f b7 c8             	movzwl %ax,%ecx
f01002f7:	8b 15 50 75 11 f0    	mov    0xf0117550,%edx
f01002fd:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100301:	83 c0 01             	add    $0x1,%eax
f0100304:	66 a3 54 75 11 f0    	mov    %ax,0xf0117554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010030a:	66 81 3d 54 75 11 f0 	cmpw   $0x7cf,0xf0117554
f0100311:	cf 07 
f0100313:	76 42                	jbe    f0100357 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100315:	a1 50 75 11 f0       	mov    0xf0117550,%eax
f010031a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100321:	00 
f0100322:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100328:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032c:	89 04 24             	mov    %eax,(%esp)
f010032f:	e8 59 36 00 00       	call   f010398d <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100334:	8b 15 50 75 11 f0    	mov    0xf0117550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010033a:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010033f:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100345:	83 c0 01             	add    $0x1,%eax
f0100348:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010034d:	75 f0                	jne    f010033f <cons_putc+0x195>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010034f:	66 83 2d 54 75 11 f0 	subw   $0x50,0xf0117554
f0100356:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100357:	8b 0d 4c 75 11 f0    	mov    0xf011754c,%ecx
f010035d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100362:	89 ca                	mov    %ecx,%edx
f0100364:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100365:	0f b7 1d 54 75 11 f0 	movzwl 0xf0117554,%ebx
f010036c:	8d 71 01             	lea    0x1(%ecx),%esi
f010036f:	89 d8                	mov    %ebx,%eax
f0100371:	66 c1 e8 08          	shr    $0x8,%ax
f0100375:	89 f2                	mov    %esi,%edx
f0100377:	ee                   	out    %al,(%dx)
f0100378:	b8 0f 00 00 00       	mov    $0xf,%eax
f010037d:	89 ca                	mov    %ecx,%edx
f010037f:	ee                   	out    %al,(%dx)
f0100380:	89 d8                	mov    %ebx,%eax
f0100382:	89 f2                	mov    %esi,%edx
f0100384:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100385:	83 c4 2c             	add    $0x2c,%esp
f0100388:	5b                   	pop    %ebx
f0100389:	5e                   	pop    %esi
f010038a:	5f                   	pop    %edi
f010038b:	5d                   	pop    %ebp
f010038c:	c3                   	ret    

f010038d <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010038d:	55                   	push   %ebp
f010038e:	89 e5                	mov    %esp,%ebp
f0100390:	53                   	push   %ebx
f0100391:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100394:	ba 64 00 00 00       	mov    $0x64,%edx
f0100399:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010039a:	a8 01                	test   $0x1,%al
f010039c:	0f 84 e5 00 00 00    	je     f0100487 <kbd_proc_data+0xfa>
f01003a2:	b2 60                	mov    $0x60,%dl
f01003a4:	ec                   	in     (%dx),%al
f01003a5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003a7:	3c e0                	cmp    $0xe0,%al
f01003a9:	75 11                	jne    f01003bc <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01003ab:	83 0d 48 75 11 f0 40 	orl    $0x40,0xf0117548
		return 0;
f01003b2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003b7:	e9 d0 00 00 00       	jmp    f010048c <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003bc:	84 c0                	test   %al,%al
f01003be:	79 37                	jns    f01003f7 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c0:	8b 0d 48 75 11 f0    	mov    0xf0117548,%ecx
f01003c6:	89 cb                	mov    %ecx,%ebx
f01003c8:	83 e3 40             	and    $0x40,%ebx
f01003cb:	83 e0 7f             	and    $0x7f,%eax
f01003ce:	85 db                	test   %ebx,%ebx
f01003d0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d3:	0f b6 d2             	movzbl %dl,%edx
f01003d6:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f01003dd:	83 c8 40             	or     $0x40,%eax
f01003e0:	0f b6 c0             	movzbl %al,%eax
f01003e3:	f7 d0                	not    %eax
f01003e5:	21 c1                	and    %eax,%ecx
f01003e7:	89 0d 48 75 11 f0    	mov    %ecx,0xf0117548
		return 0;
f01003ed:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f2:	e9 95 00 00 00       	jmp    f010048c <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f01003f7:	8b 0d 48 75 11 f0    	mov    0xf0117548,%ecx
f01003fd:	f6 c1 40             	test   $0x40,%cl
f0100400:	74 0e                	je     f0100410 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100402:	89 c2                	mov    %eax,%edx
f0100404:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100407:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040a:	89 0d 48 75 11 f0    	mov    %ecx,0xf0117548
	}

	shift |= shiftcode[data];
f0100410:	0f b6 d2             	movzbl %dl,%edx
f0100413:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f010041a:	0b 05 48 75 11 f0    	or     0xf0117548,%eax
	shift ^= togglecode[data];
f0100420:	0f b6 8a 00 40 10 f0 	movzbl -0xfefc000(%edx),%ecx
f0100427:	31 c8                	xor    %ecx,%eax
f0100429:	a3 48 75 11 f0       	mov    %eax,0xf0117548

	c = charcode[shift & (CTL | SHIFT)][data];
f010042e:	89 c1                	mov    %eax,%ecx
f0100430:	83 e1 03             	and    $0x3,%ecx
f0100433:	8b 0c 8d 00 41 10 f0 	mov    -0xfefbf00(,%ecx,4),%ecx
f010043a:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010043e:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100441:	a8 08                	test   $0x8,%al
f0100443:	74 1b                	je     f0100460 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100445:	89 da                	mov    %ebx,%edx
f0100447:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010044a:	83 f9 19             	cmp    $0x19,%ecx
f010044d:	77 05                	ja     f0100454 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010044f:	83 eb 20             	sub    $0x20,%ebx
f0100452:	eb 0c                	jmp    f0100460 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100454:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100457:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010045a:	83 fa 19             	cmp    $0x19,%edx
f010045d:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100460:	f7 d0                	not    %eax
f0100462:	a8 06                	test   $0x6,%al
f0100464:	75 26                	jne    f010048c <kbd_proc_data+0xff>
f0100466:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010046c:	75 1e                	jne    f010048c <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f010046e:	c7 04 24 cd 3e 10 f0 	movl   $0xf0103ecd,(%esp)
f0100475:	e8 ec 28 00 00       	call   f0102d66 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010047a:	ba 92 00 00 00       	mov    $0x92,%edx
f010047f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100484:	ee                   	out    %al,(%dx)
f0100485:	eb 05                	jmp    f010048c <kbd_proc_data+0xff>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100487:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010048c:	89 d8                	mov    %ebx,%eax
f010048e:	83 c4 14             	add    $0x14,%esp
f0100491:	5b                   	pop    %ebx
f0100492:	5d                   	pop    %ebp
f0100493:	c3                   	ret    

f0100494 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100494:	83 3d 20 73 11 f0 00 	cmpl   $0x0,0xf0117320
f010049b:	74 11                	je     f01004ae <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049d:	55                   	push   %ebp
f010049e:	89 e5                	mov    %esp,%ebp
f01004a0:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a3:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f01004a8:	e8 bd fc ff ff       	call   f010016a <cons_intr>
}
f01004ad:	c9                   	leave  
f01004ae:	f3 c3                	repz ret 

f01004b0 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b0:	55                   	push   %ebp
f01004b1:	89 e5                	mov    %esp,%ebp
f01004b3:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b6:	b8 8d 03 10 f0       	mov    $0xf010038d,%eax
f01004bb:	e8 aa fc ff ff       	call   f010016a <cons_intr>
}
f01004c0:	c9                   	leave  
f01004c1:	c3                   	ret    

f01004c2 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c2:	55                   	push   %ebp
f01004c3:	89 e5                	mov    %esp,%ebp
f01004c5:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c8:	e8 c7 ff ff ff       	call   f0100494 <serial_intr>
	kbd_intr();
f01004cd:	e8 de ff ff ff       	call   f01004b0 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d2:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f01004d8:	3b 15 44 75 11 f0    	cmp    0xf0117544,%edx
f01004de:	74 20                	je     f0100500 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01004e0:	0f b6 82 40 73 11 f0 	movzbl -0xfee8cc0(%edx),%eax
f01004e7:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f01004ea:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f01004f0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f5:	0f 44 d1             	cmove  %ecx,%edx
f01004f8:	89 15 40 75 11 f0    	mov    %edx,0xf0117540
f01004fe:	eb 05                	jmp    f0100505 <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100500:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100505:	c9                   	leave  
f0100506:	c3                   	ret    

f0100507 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100507:	55                   	push   %ebp
f0100508:	89 e5                	mov    %esp,%ebp
f010050a:	57                   	push   %edi
f010050b:	56                   	push   %esi
f010050c:	53                   	push   %ebx
f010050d:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100510:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100517:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010051e:	5a a5 
	if (*cp != 0xA55A) {
f0100520:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100527:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010052b:	74 11                	je     f010053e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010052d:	c7 05 4c 75 11 f0 b4 	movl   $0x3b4,0xf011754c
f0100534:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100537:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010053c:	eb 16                	jmp    f0100554 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010053e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100545:	c7 05 4c 75 11 f0 d4 	movl   $0x3d4,0xf011754c
f010054c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010054f:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100554:	8b 0d 4c 75 11 f0    	mov    0xf011754c,%ecx
f010055a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010055f:	89 ca                	mov    %ecx,%edx
f0100561:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100562:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100565:	89 da                	mov    %ebx,%edx
f0100567:	ec                   	in     (%dx),%al
f0100568:	0f b6 f0             	movzbl %al,%esi
f010056b:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100573:	89 ca                	mov    %ecx,%edx
f0100575:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100576:	89 da                	mov    %ebx,%edx
f0100578:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100579:	89 3d 50 75 11 f0    	mov    %edi,0xf0117550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010057f:	0f b6 d8             	movzbl %al,%ebx
f0100582:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100584:	66 89 35 54 75 11 f0 	mov    %si,0xf0117554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010058b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100590:	b8 00 00 00 00       	mov    $0x0,%eax
f0100595:	89 f2                	mov    %esi,%edx
f0100597:	ee                   	out    %al,(%dx)
f0100598:	b2 fb                	mov    $0xfb,%dl
f010059a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005a5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005aa:	89 da                	mov    %ebx,%edx
f01005ac:	ee                   	out    %al,(%dx)
f01005ad:	b2 f9                	mov    $0xf9,%dl
f01005af:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 fb                	mov    $0xfb,%dl
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fc                	mov    $0xfc,%dl
f01005bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 f9                	mov    $0xf9,%dl
f01005c7:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cc:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	b2 fd                	mov    $0xfd,%dl
f01005cf:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d0:	3c ff                	cmp    $0xff,%al
f01005d2:	0f 95 c1             	setne  %cl
f01005d5:	0f b6 c9             	movzbl %cl,%ecx
f01005d8:	89 0d 20 73 11 f0    	mov    %ecx,0xf0117320
f01005de:	89 f2                	mov    %esi,%edx
f01005e0:	ec                   	in     (%dx),%al
f01005e1:	89 da                	mov    %ebx,%edx
f01005e3:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e4:	85 c9                	test   %ecx,%ecx
f01005e6:	75 0c                	jne    f01005f4 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f01005e8:	c7 04 24 d9 3e 10 f0 	movl   $0xf0103ed9,(%esp)
f01005ef:	e8 72 27 00 00       	call   f0102d66 <cprintf>
}
f01005f4:	83 c4 1c             	add    $0x1c,%esp
f01005f7:	5b                   	pop    %ebx
f01005f8:	5e                   	pop    %esi
f01005f9:	5f                   	pop    %edi
f01005fa:	5d                   	pop    %ebp
f01005fb:	c3                   	ret    

f01005fc <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005fc:	55                   	push   %ebp
f01005fd:	89 e5                	mov    %esp,%ebp
f01005ff:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100602:	8b 45 08             	mov    0x8(%ebp),%eax
f0100605:	e8 a0 fb ff ff       	call   f01001aa <cons_putc>
}
f010060a:	c9                   	leave  
f010060b:	c3                   	ret    

f010060c <getchar>:

int
getchar(void)
{
f010060c:	55                   	push   %ebp
f010060d:	89 e5                	mov    %esp,%ebp
f010060f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100612:	e8 ab fe ff ff       	call   f01004c2 <cons_getc>
f0100617:	85 c0                	test   %eax,%eax
f0100619:	74 f7                	je     f0100612 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061b:	c9                   	leave  
f010061c:	c3                   	ret    

f010061d <iscons>:

int
iscons(int fdnum)
{
f010061d:	55                   	push   %ebp
f010061e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100620:	b8 01 00 00 00       	mov    $0x1,%eax
f0100625:	5d                   	pop    %ebp
f0100626:	c3                   	ret    
f0100627:	66 90                	xchg   %ax,%ax
f0100629:	66 90                	xchg   %ax,%ax
f010062b:	66 90                	xchg   %ax,%ax
f010062d:	66 90                	xchg   %ax,%ax
f010062f:	90                   	nop

f0100630 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100636:	c7 04 24 10 41 10 f0 	movl   $0xf0104110,(%esp)
f010063d:	e8 24 27 00 00       	call   f0102d66 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100642:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100649:	00 
f010064a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 f8 41 10 f0 	movl   $0xf01041f8,(%esp)
f0100659:	e8 08 27 00 00       	call   f0102d66 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010065e:	c7 44 24 08 6f 3e 10 	movl   $0x103e6f,0x8(%esp)
f0100665:	00 
f0100666:	c7 44 24 04 6f 3e 10 	movl   $0xf0103e6f,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 1c 42 10 f0 	movl   $0xf010421c,(%esp)
f0100675:	e8 ec 26 00 00       	call   f0102d66 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010067a:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f0100681:	00 
f0100682:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f0100689:	f0 
f010068a:	c7 04 24 40 42 10 f0 	movl   $0xf0104240,(%esp)
f0100691:	e8 d0 26 00 00       	call   f0102d66 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100696:	c7 44 24 08 8c 79 11 	movl   $0x11798c,0x8(%esp)
f010069d:	00 
f010069e:	c7 44 24 04 8c 79 11 	movl   $0xf011798c,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 64 42 10 f0 	movl   $0xf0104264,(%esp)
f01006ad:	e8 b4 26 00 00       	call   f0102d66 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006b2:	b8 8b 7d 11 f0       	mov    $0xf0117d8b,%eax
f01006b7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006bc:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006c2:	85 c0                	test   %eax,%eax
f01006c4:	0f 48 c2             	cmovs  %edx,%eax
f01006c7:	c1 f8 0a             	sar    $0xa,%eax
f01006ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006ce:	c7 04 24 88 42 10 f0 	movl   $0xf0104288,(%esp)
f01006d5:	e8 8c 26 00 00       	call   f0102d66 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01006da:	b8 00 00 00 00       	mov    $0x0,%eax
f01006df:	c9                   	leave  
f01006e0:	c3                   	ret    

f01006e1 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006e1:	55                   	push   %ebp
f01006e2:	89 e5                	mov    %esp,%ebp
f01006e4:	56                   	push   %esi
f01006e5:	53                   	push   %ebx
f01006e6:	83 ec 10             	sub    $0x10,%esp
f01006e9:	bb 44 43 10 f0       	mov    $0xf0104344,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f01006ee:	be 68 43 10 f0       	mov    $0xf0104368,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006f3:	8b 03                	mov    (%ebx),%eax
f01006f5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006f9:	8b 43 fc             	mov    -0x4(%ebx),%eax
f01006fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100700:	c7 04 24 29 41 10 f0 	movl   $0xf0104129,(%esp)
f0100707:	e8 5a 26 00 00       	call   f0102d66 <cprintf>
f010070c:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f010070f:	39 f3                	cmp    %esi,%ebx
f0100711:	75 e0                	jne    f01006f3 <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100713:	b8 00 00 00 00       	mov    $0x0,%eax
f0100718:	83 c4 10             	add    $0x10,%esp
f010071b:	5b                   	pop    %ebx
f010071c:	5e                   	pop    %esi
f010071d:	5d                   	pop    %ebp
f010071e:	c3                   	ret    

f010071f <mon_backtrace>:
 * 2. *ebp is the new ebp(actually old)
 * 3. get the end(ebp = 0 -> see kern/entry.S, stack movl $0, %ebp)
 */
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010071f:	55                   	push   %ebp
f0100720:	89 e5                	mov    %esp,%ebp
f0100722:	57                   	push   %edi
f0100723:	56                   	push   %esi
f0100724:	53                   	push   %ebx
f0100725:	83 ec 3c             	sub    $0x3c,%esp
	// Your code here.
	uint32_t ebp,eip;
	int i;	
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100728:	c7 04 24 32 41 10 f0 	movl   $0xf0104132,(%esp)
f010072f:	e8 32 26 00 00       	call   f0102d66 <cprintf>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100734:	89 ee                	mov    %ebp,%esi
	ebp = read_ebp();
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
f0100736:	89 74 24 04          	mov    %esi,0x4(%esp)
f010073a:	c7 04 24 44 41 10 f0 	movl   $0xf0104144,(%esp)
f0100741:	e8 20 26 00 00       	call   f0102d66 <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f0100746:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f0100749:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010074d:	c7 04 24 4f 41 10 f0 	movl   $0xf010414f,(%esp)
f0100754:	e8 0d 26 00 00       	call   f0102d66 <cprintf>
		for(i=2; i < 7; i++)
f0100759:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f010075e:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100761:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100765:	c7 04 24 49 41 10 f0 	movl   $0xf0104149,(%esp)
f010076c:	e8 f5 25 00 00       	call   f0102d66 <cprintf>
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
		eip = *(uint32_t *)(ebp + 4);
		cprintf("  eip %08x  args",eip);
		for(i=2; i < 7; i++)
f0100771:	83 c3 01             	add    $0x1,%ebx
f0100774:	83 fb 07             	cmp    $0x7,%ebx
f0100777:	75 e5                	jne    f010075e <mon_backtrace+0x3f>
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
		cprintf("\n");
f0100779:	c7 04 24 6b 4a 10 f0 	movl   $0xf0104a6b,(%esp)
f0100780:	e8 e1 25 00 00       	call   f0102d66 <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f0100785:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100788:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078c:	89 3c 24             	mov    %edi,(%esp)
f010078f:	e8 c9 26 00 00       	call   f0102e5d <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f0100794:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100797:	89 44 24 08          	mov    %eax,0x8(%esp)
f010079b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010079e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a2:	c7 04 24 60 41 10 f0 	movl   $0xf0104160,(%esp)
f01007a9:	e8 b8 25 00 00       	call   f0102d66 <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f01007ae:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007b1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007b5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007bc:	c7 04 24 69 41 10 f0 	movl   $0xf0104169,(%esp)
f01007c3:	e8 9e 25 00 00       	call   f0102d66 <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f01007c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007cf:	c7 04 24 6e 41 10 f0 	movl   $0xf010416e,(%esp)
f01007d6:	e8 8b 25 00 00       	call   f0102d66 <cprintf>
		ebp = *(uint32_t *)ebp;
f01007db:	8b 36                	mov    (%esi),%esi
	}while(ebp);
f01007dd:	85 f6                	test   %esi,%esi
f01007df:	0f 85 51 ff ff ff    	jne    f0100736 <mon_backtrace+0x17>
	return 0;
}
f01007e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ea:	83 c4 3c             	add    $0x3c,%esp
f01007ed:	5b                   	pop    %ebx
f01007ee:	5e                   	pop    %esi
f01007ef:	5f                   	pop    %edi
f01007f0:	5d                   	pop    %ebp
f01007f1:	c3                   	ret    

f01007f2 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007f2:	55                   	push   %ebp
f01007f3:	89 e5                	mov    %esp,%ebp
f01007f5:	57                   	push   %edi
f01007f6:	56                   	push   %esi
f01007f7:	53                   	push   %ebx
f01007f8:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007fb:	c7 04 24 b4 42 10 f0 	movl   $0xf01042b4,(%esp)
f0100802:	e8 5f 25 00 00       	call   f0102d66 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100807:	c7 04 24 d8 42 10 f0 	movl   $0xf01042d8,(%esp)
f010080e:	e8 53 25 00 00       	call   f0102d66 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100813:	c7 04 24 73 41 10 f0 	movl   $0xf0104173,(%esp)
f010081a:	e8 61 2e 00 00       	call   f0103680 <readline>
f010081f:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100821:	85 c0                	test   %eax,%eax
f0100823:	74 ee                	je     f0100813 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100825:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010082c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100831:	eb 06                	jmp    f0100839 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100833:	c6 06 00             	movb   $0x0,(%esi)
f0100836:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100839:	0f b6 06             	movzbl (%esi),%eax
f010083c:	84 c0                	test   %al,%al
f010083e:	74 6b                	je     f01008ab <monitor+0xb9>
f0100840:	0f be c0             	movsbl %al,%eax
f0100843:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100847:	c7 04 24 77 41 10 f0 	movl   $0xf0104177,(%esp)
f010084e:	e8 77 30 00 00       	call   f01038ca <strchr>
f0100853:	85 c0                	test   %eax,%eax
f0100855:	75 dc                	jne    f0100833 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100857:	80 3e 00             	cmpb   $0x0,(%esi)
f010085a:	74 4f                	je     f01008ab <monitor+0xb9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010085c:	83 fb 0f             	cmp    $0xf,%ebx
f010085f:	90                   	nop
f0100860:	75 16                	jne    f0100878 <monitor+0x86>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100862:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100869:	00 
f010086a:	c7 04 24 7c 41 10 f0 	movl   $0xf010417c,(%esp)
f0100871:	e8 f0 24 00 00       	call   f0102d66 <cprintf>
f0100876:	eb 9b                	jmp    f0100813 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100878:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f010087c:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f010087f:	0f b6 06             	movzbl (%esi),%eax
f0100882:	84 c0                	test   %al,%al
f0100884:	75 0c                	jne    f0100892 <monitor+0xa0>
f0100886:	eb b1                	jmp    f0100839 <monitor+0x47>
			buf++;
f0100888:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010088b:	0f b6 06             	movzbl (%esi),%eax
f010088e:	84 c0                	test   %al,%al
f0100890:	74 a7                	je     f0100839 <monitor+0x47>
f0100892:	0f be c0             	movsbl %al,%eax
f0100895:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100899:	c7 04 24 77 41 10 f0 	movl   $0xf0104177,(%esp)
f01008a0:	e8 25 30 00 00       	call   f01038ca <strchr>
f01008a5:	85 c0                	test   %eax,%eax
f01008a7:	74 df                	je     f0100888 <monitor+0x96>
f01008a9:	eb 8e                	jmp    f0100839 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f01008ab:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f01008b2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b3:	85 db                	test   %ebx,%ebx
f01008b5:	0f 84 58 ff ff ff    	je     f0100813 <monitor+0x21>
f01008bb:	bf 40 43 10 f0       	mov    $0xf0104340,%edi
f01008c0:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c5:	8b 07                	mov    (%edi),%eax
f01008c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ce:	89 04 24             	mov    %eax,(%esp)
f01008d1:	e8 70 2f 00 00       	call   f0103846 <strcmp>
f01008d6:	85 c0                	test   %eax,%eax
f01008d8:	75 24                	jne    f01008fe <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008da:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01008dd:	8b 55 08             	mov    0x8(%ebp),%edx
f01008e0:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008e4:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008e7:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008eb:	89 1c 24             	mov    %ebx,(%esp)
f01008ee:	ff 14 85 48 43 10 f0 	call   *-0xfefbcb8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008f5:	85 c0                	test   %eax,%eax
f01008f7:	78 28                	js     f0100921 <monitor+0x12f>
f01008f9:	e9 15 ff ff ff       	jmp    f0100813 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008fe:	83 c6 01             	add    $0x1,%esi
f0100901:	83 c7 0c             	add    $0xc,%edi
f0100904:	83 fe 03             	cmp    $0x3,%esi
f0100907:	75 bc                	jne    f01008c5 <monitor+0xd3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100909:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010090c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100910:	c7 04 24 99 41 10 f0 	movl   $0xf0104199,(%esp)
f0100917:	e8 4a 24 00 00       	call   f0102d66 <cprintf>
f010091c:	e9 f2 fe ff ff       	jmp    f0100813 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100921:	83 c4 5c             	add    $0x5c,%esp
f0100924:	5b                   	pop    %ebx
f0100925:	5e                   	pop    %esi
f0100926:	5f                   	pop    %edi
f0100927:	5d                   	pop    %ebp
f0100928:	c3                   	ret    

f0100929 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100929:	55                   	push   %ebp
f010092a:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010092c:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f010092f:	5d                   	pop    %ebp
f0100930:	c3                   	ret    
f0100931:	66 90                	xchg   %ax,%ax
f0100933:	66 90                	xchg   %ax,%ax
f0100935:	66 90                	xchg   %ax,%ax
f0100937:	66 90                	xchg   %ax,%ax
f0100939:	66 90                	xchg   %ax,%ax
f010093b:	66 90                	xchg   %ax,%ax
f010093d:	66 90                	xchg   %ax,%ax
f010093f:	90                   	nop

f0100940 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100940:	89 d1                	mov    %edx,%ecx
f0100942:	c1 e9 16             	shr    $0x16,%ecx
//cprintf("#pgdir is %x #",KADDR(PTE_ADDR(*pgdir)));
	if (!(*pgdir & PTE_P))
f0100945:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100948:	a8 01                	test   $0x1,%al
f010094a:	74 5d                	je     f01009a9 <check_va2pa+0x69>
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010094c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100951:	89 c1                	mov    %eax,%ecx
f0100953:	c1 e9 0c             	shr    $0xc,%ecx
f0100956:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f010095c:	72 26                	jb     f0100984 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010095e:	55                   	push   %ebp
f010095f:	89 e5                	mov    %esp,%ebp
f0100961:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100964:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100968:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f010096f:	f0 
f0100970:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f0100977:	00 
f0100978:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010097f:	e8 10 f7 ff ff       	call   f0100094 <_panic>
	if (!(*pgdir & PTE_P))
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
//cprintf("#%d the p+PTX(va) is %x #\n",PTX(va), p + PTX(va));
	if (!(p[PTX(va)] & PTE_P))
f0100984:	c1 ea 0c             	shr    $0xc,%edx
f0100987:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010098d:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100994:	89 c2                	mov    %eax,%edx
f0100996:	83 e2 01             	and    $0x1,%edx
		return ~0;
//	cprintf("%x\n", PTE_ADDR(p[PTX(va)]));
	return PTE_ADDR(p[PTX(va)]);
f0100999:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010099e:	85 d2                	test   %edx,%edx
f01009a0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009a5:	0f 44 c2             	cmove  %edx,%eax
f01009a8:	c3                   	ret    
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
//cprintf("#pgdir is %x #",KADDR(PTE_ADDR(*pgdir)));
	if (!(*pgdir & PTE_P))
		return ~0;
f01009a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
//cprintf("#%d the p+PTX(va) is %x #\n",PTX(va), p + PTX(va));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
//	cprintf("%x\n", PTE_ADDR(p[PTX(va)]));
	return PTE_ADDR(p[PTX(va)]);
}
f01009ae:	c3                   	ret    

f01009af <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009af:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009b1:	83 3d 5c 75 11 f0 00 	cmpl   $0x0,0xf011755c
f01009b8:	75 0f                	jne    f01009c9 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009ba:	b8 8b 89 11 f0       	mov    $0xf011898b,%eax
f01009bf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009c4:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f01009c9:	85 d2                	test   %edx,%edx
f01009cb:	75 06                	jne    f01009d3 <boot_alloc+0x24>
		return nextfree;
f01009cd:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f01009d2:	c3                   	ret    
	result = nextfree;
f01009d3:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
	nextfree += (n/PGSIZE + 1)*PGSIZE;
f01009d8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009de:	8d 94 10 00 10 00 00 	lea    0x1000(%eax,%edx,1),%edx
f01009e5:	89 15 5c 75 11 f0    	mov    %edx,0xf011755c
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
f01009eb:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f01009f1:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f01009f7:	c1 e1 0c             	shl    $0xc,%ecx
f01009fa:	39 ca                	cmp    %ecx,%edx
f01009fc:	72 22                	jb     f0100a20 <boot_alloc+0x71>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009fe:	55                   	push   %ebp
f01009ff:	89 e5                	mov    %esp,%ebp
f0100a01:	83 ec 18             	sub    $0x18,%esp
	if(n == 0)
		return nextfree;
	result = nextfree;
	nextfree += (n/PGSIZE + 1)*PGSIZE;
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
		panic("Run out of memory!!\n");
f0100a04:	c7 44 24 08 58 4a 10 	movl   $0xf0104a58,0x8(%esp)
f0100a0b:	f0 
f0100a0c:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
f0100a13:	00 
f0100a14:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100a1b:	e8 74 f6 ff ff       	call   f0100094 <_panic>
	return result;
}
f0100a20:	f3 c3                	repz ret 

f0100a22 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a22:	55                   	push   %ebp
f0100a23:	89 e5                	mov    %esp,%ebp
f0100a25:	83 ec 18             	sub    $0x18,%esp
f0100a28:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a2b:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a2e:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a30:	89 04 24             	mov    %eax,(%esp)
f0100a33:	e8 bc 22 00 00       	call   f0102cf4 <mc146818_read>
f0100a38:	89 c6                	mov    %eax,%esi
f0100a3a:	83 c3 01             	add    $0x1,%ebx
f0100a3d:	89 1c 24             	mov    %ebx,(%esp)
f0100a40:	e8 af 22 00 00       	call   f0102cf4 <mc146818_read>
f0100a45:	c1 e0 08             	shl    $0x8,%eax
f0100a48:	09 f0                	or     %esi,%eax
}
f0100a4a:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a4d:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a50:	89 ec                	mov    %ebp,%esp
f0100a52:	5d                   	pop    %ebp
f0100a53:	c3                   	ret    

f0100a54 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a54:	55                   	push   %ebp
f0100a55:	89 e5                	mov    %esp,%ebp
f0100a57:	57                   	push   %edi
f0100a58:	56                   	push   %esi
f0100a59:	53                   	push   %ebx
f0100a5a:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a5d:	85 c0                	test   %eax,%eax
f0100a5f:	0f 85 39 03 00 00    	jne    f0100d9e <check_page_free_list+0x34a>
f0100a65:	e9 46 03 00 00       	jmp    f0100db0 <check_page_free_list+0x35c>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a6a:	c7 44 24 08 88 43 10 	movl   $0xf0104388,0x8(%esp)
f0100a71:	f0 
f0100a72:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
f0100a79:	00 
f0100a7a:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100a81:	e8 0e f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100a86:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a89:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a8c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a8f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a92:	89 c2                	mov    %eax,%edx
f0100a94:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a9a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100aa0:	0f 95 c2             	setne  %dl
f0100aa3:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100aa6:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100aaa:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100aac:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab0:	8b 00                	mov    (%eax),%eax
f0100ab2:	85 c0                	test   %eax,%eax
f0100ab4:	75 dc                	jne    f0100a92 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ab6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ab9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100abf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ac2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ac5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ac7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100aca:	a3 60 75 11 f0       	mov    %eax,0xf0117560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100acf:	89 c3                	mov    %eax,%ebx
f0100ad1:	85 c0                	test   %eax,%eax
f0100ad3:	74 6c                	je     f0100b41 <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ad5:	be 01 00 00 00       	mov    $0x1,%esi
f0100ada:	89 d8                	mov    %ebx,%eax
f0100adc:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100ae2:	c1 f8 03             	sar    $0x3,%eax
f0100ae5:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ae8:	89 c2                	mov    %eax,%edx
f0100aea:	c1 ea 16             	shr    $0x16,%edx
f0100aed:	39 f2                	cmp    %esi,%edx
f0100aef:	73 4a                	jae    f0100b3b <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100af1:	89 c2                	mov    %eax,%edx
f0100af3:	c1 ea 0c             	shr    $0xc,%edx
f0100af6:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100afc:	72 20                	jb     f0100b1e <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100afe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b02:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0100b09:	f0 
f0100b0a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b11:	00 
f0100b12:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f0100b19:	e8 76 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b1e:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b25:	00 
f0100b26:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b2d:	00 
	return (void *)(pa + KERNBASE);
f0100b2e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b33:	89 04 24             	mov    %eax,(%esp)
f0100b36:	e8 f4 2d 00 00       	call   f010392f <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b3b:	8b 1b                	mov    (%ebx),%ebx
f0100b3d:	85 db                	test   %ebx,%ebx
f0100b3f:	75 99                	jne    f0100ada <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b41:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b46:	e8 64 fe ff ff       	call   f01009af <boot_alloc>
f0100b4b:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b4e:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f0100b54:	85 d2                	test   %edx,%edx
f0100b56:	0f 84 f6 01 00 00    	je     f0100d52 <check_page_free_list+0x2fe>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b5c:	8b 1d 88 79 11 f0    	mov    0xf0117988,%ebx
f0100b62:	39 da                	cmp    %ebx,%edx
f0100b64:	72 4d                	jb     f0100bb3 <check_page_free_list+0x15f>
		assert(pp < pages + npages);
f0100b66:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0100b6b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b6e:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b71:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b74:	39 c2                	cmp    %eax,%edx
f0100b76:	73 64                	jae    f0100bdc <check_page_free_list+0x188>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b78:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b7b:	89 d0                	mov    %edx,%eax
f0100b7d:	29 d8                	sub    %ebx,%eax
f0100b7f:	a8 07                	test   $0x7,%al
f0100b81:	0f 85 82 00 00 00    	jne    f0100c09 <check_page_free_list+0x1b5>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b87:	c1 f8 03             	sar    $0x3,%eax
f0100b8a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b8d:	85 c0                	test   %eax,%eax
f0100b8f:	0f 84 a2 00 00 00    	je     f0100c37 <check_page_free_list+0x1e3>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b95:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b9a:	0f 84 c2 00 00 00    	je     f0100c62 <check_page_free_list+0x20e>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ba0:	be 00 00 00 00       	mov    $0x0,%esi
f0100ba5:	bf 00 00 00 00       	mov    $0x0,%edi
f0100baa:	e9 d7 00 00 00       	jmp    f0100c86 <check_page_free_list+0x232>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100baf:	39 da                	cmp    %ebx,%edx
f0100bb1:	73 24                	jae    f0100bd7 <check_page_free_list+0x183>
f0100bb3:	c7 44 24 0c 7b 4a 10 	movl   $0xf0104a7b,0xc(%esp)
f0100bba:	f0 
f0100bbb:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100bc2:	f0 
f0100bc3:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
f0100bca:	00 
f0100bcb:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100bd2:	e8 bd f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bd7:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bda:	72 24                	jb     f0100c00 <check_page_free_list+0x1ac>
f0100bdc:	c7 44 24 0c 9c 4a 10 	movl   $0xf0104a9c,0xc(%esp)
f0100be3:	f0 
f0100be4:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100beb:	f0 
f0100bec:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0100bf3:	00 
f0100bf4:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100bfb:	e8 94 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c00:	89 d0                	mov    %edx,%eax
f0100c02:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c05:	a8 07                	test   $0x7,%al
f0100c07:	74 24                	je     f0100c2d <check_page_free_list+0x1d9>
f0100c09:	c7 44 24 0c ac 43 10 	movl   $0xf01043ac,0xc(%esp)
f0100c10:	f0 
f0100c11:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100c18:	f0 
f0100c19:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
f0100c20:	00 
f0100c21:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100c28:	e8 67 f4 ff ff       	call   f0100094 <_panic>
f0100c2d:	c1 f8 03             	sar    $0x3,%eax
f0100c30:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c33:	85 c0                	test   %eax,%eax
f0100c35:	75 24                	jne    f0100c5b <check_page_free_list+0x207>
f0100c37:	c7 44 24 0c b0 4a 10 	movl   $0xf0104ab0,0xc(%esp)
f0100c3e:	f0 
f0100c3f:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100c46:	f0 
f0100c47:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f0100c4e:	00 
f0100c4f:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100c56:	e8 39 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c5b:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c60:	75 24                	jne    f0100c86 <check_page_free_list+0x232>
f0100c62:	c7 44 24 0c c1 4a 10 	movl   $0xf0104ac1,0xc(%esp)
f0100c69:	f0 
f0100c6a:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100c71:	f0 
f0100c72:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100c79:	00 
f0100c7a:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100c81:	e8 0e f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c86:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c8b:	75 24                	jne    f0100cb1 <check_page_free_list+0x25d>
f0100c8d:	c7 44 24 0c e0 43 10 	movl   $0xf01043e0,0xc(%esp)
f0100c94:	f0 
f0100c95:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100c9c:	f0 
f0100c9d:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0100ca4:	00 
f0100ca5:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100cac:	e8 e3 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cb1:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cb6:	75 24                	jne    f0100cdc <check_page_free_list+0x288>
f0100cb8:	c7 44 24 0c da 4a 10 	movl   $0xf0104ada,0xc(%esp)
f0100cbf:	f0 
f0100cc0:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100cc7:	f0 
f0100cc8:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f0100ccf:	00 
f0100cd0:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100cd7:	e8 b8 f3 ff ff       	call   f0100094 <_panic>
f0100cdc:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cde:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100ce3:	76 57                	jbe    f0100d3c <check_page_free_list+0x2e8>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ce5:	c1 e8 0c             	shr    $0xc,%eax
f0100ce8:	3b 45 cc             	cmp    -0x34(%ebp),%eax
f0100ceb:	72 20                	jb     f0100d0d <check_page_free_list+0x2b9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ced:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100cf1:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0100cf8:	f0 
f0100cf9:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d00:	00 
f0100d01:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f0100d08:	e8 87 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d0d:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d13:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100d16:	76 29                	jbe    f0100d41 <check_page_free_list+0x2ed>
f0100d18:	c7 44 24 0c 04 44 10 	movl   $0xf0104404,0xc(%esp)
f0100d1f:	f0 
f0100d20:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100d27:	f0 
f0100d28:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0100d2f:	00 
f0100d30:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100d37:	e8 58 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d3c:	83 c7 01             	add    $0x1,%edi
f0100d3f:	eb 03                	jmp    f0100d44 <check_page_free_list+0x2f0>
		else
			++nfree_extmem;
f0100d41:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d44:	8b 12                	mov    (%edx),%edx
f0100d46:	85 d2                	test   %edx,%edx
f0100d48:	0f 85 61 fe ff ff    	jne    f0100baf <check_page_free_list+0x15b>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d4e:	85 ff                	test   %edi,%edi
f0100d50:	7f 24                	jg     f0100d76 <check_page_free_list+0x322>
f0100d52:	c7 44 24 0c f4 4a 10 	movl   $0xf0104af4,0xc(%esp)
f0100d59:	f0 
f0100d5a:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100d61:	f0 
f0100d62:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f0100d69:	00 
f0100d6a:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100d71:	e8 1e f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d76:	85 f6                	test   %esi,%esi
f0100d78:	7f 53                	jg     f0100dcd <check_page_free_list+0x379>
f0100d7a:	c7 44 24 0c 06 4b 10 	movl   $0xf0104b06,0xc(%esp)
f0100d81:	f0 
f0100d82:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0100d89:	f0 
f0100d8a:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f0100d91:	00 
f0100d92:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100d99:	e8 f6 f2 ff ff       	call   f0100094 <_panic>
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d9e:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f0100da3:	85 c0                	test   %eax,%eax
f0100da5:	0f 85 db fc ff ff    	jne    f0100a86 <check_page_free_list+0x32>
f0100dab:	e9 ba fc ff ff       	jmp    f0100a6a <check_page_free_list+0x16>
f0100db0:	83 3d 60 75 11 f0 00 	cmpl   $0x0,0xf0117560
f0100db7:	0f 84 ad fc ff ff    	je     f0100a6a <check_page_free_list+0x16>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dbd:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dc3:	be 00 04 00 00       	mov    $0x400,%esi
f0100dc8:	e9 0d fd ff ff       	jmp    f0100ada <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100dcd:	83 c4 3c             	add    $0x3c,%esp
f0100dd0:	5b                   	pop    %ebx
f0100dd1:	5e                   	pop    %esi
f0100dd2:	5f                   	pop    %edi
f0100dd3:	5d                   	pop    %ebp
f0100dd4:	c3                   	ret    

f0100dd5 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dd5:	55                   	push   %ebp
f0100dd6:	89 e5                	mov    %esp,%ebp
f0100dd8:	56                   	push   %esi
f0100dd9:	53                   	push   %ebx
f0100dda:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
f0100ddd:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0100de2:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100de8:	8b 35 58 75 11 f0    	mov    0xf0117558,%esi
f0100dee:	83 fe 01             	cmp    $0x1,%esi
f0100df1:	76 37                	jbe    f0100e2a <page_init+0x55>
f0100df3:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100df9:	b8 01 00 00 00       	mov    $0x1,%eax
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
f0100dfe:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
		pages[i].pp_ref = 0;
f0100e05:	8b 0d 88 79 11 f0    	mov    0xf0117988,%ecx
f0100e0b:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100e12:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0100e15:	8b 1d 88 79 11 f0    	mov    0xf0117988,%ebx
f0100e1b:	01 d3                	add    %edx,%ebx
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100e1d:	83 c0 01             	add    $0x1,%eax
f0100e20:	39 f0                	cmp    %esi,%eax
f0100e22:	72 da                	jb     f0100dfe <page_init+0x29>
f0100e24:	89 1d 60 75 11 f0    	mov    %ebx,0xf0117560
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	size_t page_num = PADDR(boot_alloc(0)) / PGSIZE;
f0100e2a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e2f:	e8 7b fb ff ff       	call   f01009af <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e34:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e39:	77 20                	ja     f0100e5b <page_init+0x86>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e3b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e3f:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f0100e46:	f0 
f0100e47:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
f0100e4e:	00 
f0100e4f:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100e56:	e8 39 f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e5b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e60:	c1 e8 0c             	shr    $0xc,%eax
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100e63:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0100e69:	73 39                	jae    f0100ea4 <page_init+0xcf>
f0100e6b:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100e71:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100e78:	8b 0d 88 79 11 f0    	mov    0xf0117988,%ecx
f0100e7e:	01 d1                	add    %edx,%ecx
f0100e80:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100e86:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100e88:	8b 1d 88 79 11 f0    	mov    0xf0117988,%ebx
f0100e8e:	01 d3                	add    %edx,%ebx
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100e90:	83 c0 01             	add    $0x1,%eax
f0100e93:	83 c2 08             	add    $0x8,%edx
f0100e96:	39 05 80 79 11 f0    	cmp    %eax,0xf0117980
f0100e9c:	77 da                	ja     f0100e78 <page_init+0xa3>
f0100e9e:	89 1d 60 75 11 f0    	mov    %ebx,0xf0117560
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
//	panic("here");
	
}
f0100ea4:	83 c4 10             	add    $0x10,%esp
f0100ea7:	5b                   	pop    %ebx
f0100ea8:	5e                   	pop    %esi
f0100ea9:	5d                   	pop    %ebp
f0100eaa:	c3                   	ret    

f0100eab <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100eab:	55                   	push   %ebp
f0100eac:	89 e5                	mov    %esp,%ebp
f0100eae:	53                   	push   %ebx
f0100eaf:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(!page_free_list)
f0100eb2:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100eb8:	85 db                	test   %ebx,%ebx
f0100eba:	74 6b                	je     f0100f27 <page_alloc+0x7c>
		return NULL;
	struct Page *alloc_page = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100ebc:	8b 03                	mov    (%ebx),%eax
f0100ebe:	a3 60 75 11 f0       	mov    %eax,0xf0117560
	alloc_page -> pp_link = NULL;
f0100ec3:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100ec9:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ecd:	74 58                	je     f0100f27 <page_alloc+0x7c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ecf:	89 d8                	mov    %ebx,%eax
f0100ed1:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100ed7:	c1 f8 03             	sar    $0x3,%eax
f0100eda:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100edd:	89 c2                	mov    %eax,%edx
f0100edf:	c1 ea 0c             	shr    $0xc,%edx
f0100ee2:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100ee8:	72 20                	jb     f0100f0a <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eea:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eee:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0100ef5:	f0 
f0100ef6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100efd:	00 
f0100efe:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f0100f05:	e8 8a f1 ff ff       	call   f0100094 <_panic>
		memset(page2kva(alloc_page), 0, PGSIZE);
f0100f0a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f11:	00 
f0100f12:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f19:	00 
	return (void *)(pa + KERNBASE);
f0100f1a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f1f:	89 04 24             	mov    %eax,(%esp)
f0100f22:	e8 08 2a 00 00       	call   f010392f <memset>
	
	return alloc_page;
}
f0100f27:	89 d8                	mov    %ebx,%eax
f0100f29:	83 c4 14             	add    $0x14,%esp
f0100f2c:	5b                   	pop    %ebx
f0100f2d:	5d                   	pop    %ebp
f0100f2e:	c3                   	ret    

f0100f2f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f2f:	55                   	push   %ebp
f0100f30:	89 e5                	mov    %esp,%ebp
f0100f32:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if(pp -> pp_ref)	// If the ref is not 0, return
f0100f35:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f3a:	75 0d                	jne    f0100f49 <page_free+0x1a>
		return;
	pp->pp_link = page_free_list;
f0100f3c:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f0100f42:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f44:	a3 60 75 11 f0       	mov    %eax,0xf0117560
}
f0100f49:	5d                   	pop    %ebp
f0100f4a:	c3                   	ret    

f0100f4b <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f4b:	55                   	push   %ebp
f0100f4c:	89 e5                	mov    %esp,%ebp
f0100f4e:	83 ec 04             	sub    $0x4,%esp
f0100f51:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f54:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f58:	83 ea 01             	sub    $0x1,%edx
f0100f5b:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f5f:	66 85 d2             	test   %dx,%dx
f0100f62:	75 08                	jne    f0100f6c <page_decref+0x21>
		page_free(pp);
f0100f64:	89 04 24             	mov    %eax,(%esp)
f0100f67:	e8 c3 ff ff ff       	call   f0100f2f <page_free>
}
f0100f6c:	c9                   	leave  
f0100f6d:	c3                   	ret    

f0100f6e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{/* see the check_va2pa() */
f0100f6e:	55                   	push   %ebp
f0100f6f:	89 e5                	mov    %esp,%ebp
f0100f71:	56                   	push   %esi
f0100f72:	53                   	push   %ebx
f0100f73:	83 ec 10             	sub    $0x10,%esp
f0100f76:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/* va is a linear address */
	pde_t *ptdir = pgdir + PDX(va);
f0100f79:	89 de                	mov    %ebx,%esi
f0100f7b:	c1 ee 16             	shr    $0x16,%esi
f0100f7e:	c1 e6 02             	shl    $0x2,%esi
f0100f81:	03 75 08             	add    0x8(%ebp),%esi
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
f0100f84:	8b 06                	mov    (%esi),%eax
f0100f86:	a8 01                	test   $0x1,%al
f0100f88:	74 44                	je     f0100fce <pgdir_walk+0x60>
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f0100f8a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f8f:	89 c2                	mov    %eax,%edx
f0100f91:	c1 ea 0c             	shr    $0xc,%edx
f0100f94:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100f9a:	72 20                	jb     f0100fbc <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f9c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fa0:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0100fa7:	f0 
f0100fa8:	c7 44 24 04 76 01 00 	movl   $0x176,0x4(%esp)
f0100faf:	00 
f0100fb0:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0100fb7:	e8 d8 f0 ff ff       	call   f0100094 <_panic>
f0100fbc:	c1 eb 0a             	shr    $0xa,%ebx
f0100fbf:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100fc5:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100fcc:	eb 7c                	jmp    f010104a <pgdir_walk+0xdc>
	if(!create)
f0100fce:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fd2:	74 6a                	je     f010103e <pgdir_walk+0xd0>
		return NULL;
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
f0100fd4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fdb:	e8 cb fe ff ff       	call   f0100eab <page_alloc>
	if(!page_create)
f0100fe0:	85 c0                	test   %eax,%eax
f0100fe2:	74 61                	je     f0101045 <pgdir_walk+0xd7>
		return NULL; /* allocation fails */
	page_create -> pp_ref++; /* reference count increase */
f0100fe4:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fe9:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100fef:	c1 f8 03             	sar    $0x3,%eax
f0100ff2:	c1 e0 0c             	shl    $0xc,%eax
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
f0100ff5:	83 c8 07             	or     $0x7,%eax
f0100ff8:	89 06                	mov    %eax,(%esi)
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f0100ffa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fff:	89 c2                	mov    %eax,%edx
f0101001:	c1 ea 0c             	shr    $0xc,%edx
f0101004:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f010100a:	72 20                	jb     f010102c <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010100c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101010:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0101017:	f0 
f0101018:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f010101f:	00 
f0101020:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101027:	e8 68 f0 ff ff       	call   f0100094 <_panic>
f010102c:	c1 eb 0a             	shr    $0xa,%ebx
f010102f:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101035:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f010103c:	eb 0c                	jmp    f010104a <pgdir_walk+0xdc>
	pde_t *ptdir = pgdir + PDX(va);
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
	if(!create)
		return NULL;
f010103e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101043:	eb 05                	jmp    f010104a <pgdir_walk+0xdc>
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
	if(!page_create)
		return NULL; /* allocation fails */
f0101045:	b8 00 00 00 00       	mov    $0x0,%eax
	page_create -> pp_ref++; /* reference count increase */
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
}
f010104a:	83 c4 10             	add    $0x10,%esp
f010104d:	5b                   	pop    %ebx
f010104e:	5e                   	pop    %esi
f010104f:	5d                   	pop    %ebp
f0101050:	c3                   	ret    

f0101051 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101051:	55                   	push   %ebp
f0101052:	89 e5                	mov    %esp,%ebp
f0101054:	57                   	push   %edi
f0101055:	56                   	push   %esi
f0101056:	53                   	push   %ebx
f0101057:	83 ec 2c             	sub    $0x2c,%esp
f010105a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f010105d:	85 c9                	test   %ecx,%ecx
f010105f:	74 43                	je     f01010a4 <boot_map_region+0x53>
f0101061:	89 c6                	mov    %eax,%esi
f0101063:	89 d3                	mov    %edx,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101065:	8b 45 08             	mov    0x8(%ebp),%eax
f0101068:	29 d0                	sub    %edx,%eax
f010106a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010106d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101070:	89 f7                	mov    %esi,%edi
f0101072:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101075:	01 de                	add    %ebx,%esi
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
		pte_t *pte = pgdir_walk(pgdir, (const void *)va, 1);
f0101077:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010107e:	00 
f010107f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101083:	89 3c 24             	mov    %edi,(%esp)
f0101086:	e8 e3 fe ff ff       	call   f0100f6e <pgdir_walk>
		if(!pte)
f010108b:	85 c0                	test   %eax,%eax
f010108d:	74 15                	je     f01010a4 <boot_map_region+0x53>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm;
f010108f:	0b 75 0c             	or     0xc(%ebp),%esi
f0101092:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f0101094:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010109a:	89 d8                	mov    %ebx,%eax
f010109c:	2b 45 dc             	sub    -0x24(%ebp),%eax
f010109f:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01010a2:	72 ce                	jb     f0101072 <boot_map_region+0x21>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm;
	}
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~\n");
}
f01010a4:	83 c4 2c             	add    $0x2c,%esp
f01010a7:	5b                   	pop    %ebx
f01010a8:	5e                   	pop    %esi
f01010a9:	5f                   	pop    %edi
f01010aa:	5d                   	pop    %ebp
f01010ab:	c3                   	ret    

f01010ac <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010ac:	55                   	push   %ebp
f01010ad:	89 e5                	mov    %esp,%ebp
f01010af:	53                   	push   %ebx
f01010b0:	83 ec 14             	sub    $0x14,%esp
f01010b3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f01010b6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010bd:	00 
f01010be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01010c8:	89 04 24             	mov    %eax,(%esp)
f01010cb:	e8 9e fe ff ff       	call   f0100f6e <pgdir_walk>
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
f01010d0:	85 c0                	test   %eax,%eax
f01010d2:	74 3f                	je     f0101113 <page_lookup+0x67>
f01010d4:	f6 00 01             	testb  $0x1,(%eax)
f01010d7:	74 41                	je     f010111a <page_lookup+0x6e>
		return NULL;
	if(pte_store)
f01010d9:	85 db                	test   %ebx,%ebx
f01010db:	74 02                	je     f01010df <page_lookup+0x33>
		*pte_store = pte;
f01010dd:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f01010df:	8b 00                	mov    (%eax),%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010e1:	c1 e8 0c             	shr    $0xc,%eax
f01010e4:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f01010ea:	72 1c                	jb     f0101108 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f01010ec:	c7 44 24 08 70 44 10 	movl   $0xf0104470,0x8(%esp)
f01010f3:	f0 
f01010f4:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f01010fb:	00 
f01010fc:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f0101103:	e8 8c ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101108:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
f010110e:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0101111:	eb 0c                	jmp    f010111f <page_lookup+0x73>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
		return NULL;
f0101113:	b8 00 00 00 00       	mov    $0x0,%eax
f0101118:	eb 05                	jmp    f010111f <page_lookup+0x73>
f010111a:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f010111f:	83 c4 14             	add    $0x14,%esp
f0101122:	5b                   	pop    %ebx
f0101123:	5d                   	pop    %ebp
f0101124:	c3                   	ret    

f0101125 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101125:	55                   	push   %ebp
f0101126:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101128:	8b 45 0c             	mov    0xc(%ebp),%eax
f010112b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010112e:	5d                   	pop    %ebp
f010112f:	c3                   	ret    

f0101130 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101130:	55                   	push   %ebp
f0101131:	89 e5                	mov    %esp,%ebp
f0101133:	83 ec 28             	sub    $0x28,%esp
f0101136:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101139:	89 75 fc             	mov    %esi,-0x4(%ebp)
f010113c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010113f:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct Page *pp = page_lookup(pgdir, va, &pte);
f0101142:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101145:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101149:	89 74 24 04          	mov    %esi,0x4(%esp)
f010114d:	89 1c 24             	mov    %ebx,(%esp)
f0101150:	e8 57 ff ff ff       	call   f01010ac <page_lookup>
	if(!pp)
f0101155:	85 c0                	test   %eax,%eax
f0101157:	74 1d                	je     f0101176 <page_remove+0x46>
		return;
	page_decref(pp);
f0101159:	89 04 24             	mov    %eax,(%esp)
f010115c:	e8 ea fd ff ff       	call   f0100f4b <page_decref>
	*pte = 0;
f0101161:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101164:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f010116a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010116e:	89 1c 24             	mov    %ebx,(%esp)
f0101171:	e8 af ff ff ff       	call   f0101125 <tlb_invalidate>
	
}
f0101176:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101179:	8b 75 fc             	mov    -0x4(%ebp),%esi
f010117c:	89 ec                	mov    %ebp,%esp
f010117e:	5d                   	pop    %ebp
f010117f:	c3                   	ret    

f0101180 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101180:	55                   	push   %ebp
f0101181:	89 e5                	mov    %esp,%ebp
f0101183:	83 ec 28             	sub    $0x28,%esp
f0101186:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101189:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010118c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010118f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101192:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101195:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010119c:	00 
f010119d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01011a4:	89 04 24             	mov    %eax,(%esp)
f01011a7:	e8 c2 fd ff ff       	call   f0100f6e <pgdir_walk>
f01011ac:	89 c6                	mov    %eax,%esi
	if(!pte)
f01011ae:	85 c0                	test   %eax,%eax
f01011b0:	74 66                	je     f0101218 <page_insert+0x98>
		return -E_NO_MEM;
	if(*pte & PTE_P) { /* already a page */
f01011b2:	8b 00                	mov    (%eax),%eax
f01011b4:	a8 01                	test   $0x1,%al
f01011b6:	74 3c                	je     f01011f4 <page_insert+0x74>
		if(PTE_ADDR(*pte) == page2pa(pp)){	/* the same one */
f01011b8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01011bd:	89 da                	mov    %ebx,%edx
f01011bf:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01011c5:	c1 fa 03             	sar    $0x3,%edx
f01011c8:	c1 e2 0c             	shl    $0xc,%edx
f01011cb:	39 d0                	cmp    %edx,%eax
f01011cd:	75 16                	jne    f01011e5 <page_insert+0x65>
			tlb_invalidate(pgdir, va);
f01011cf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d6:	89 04 24             	mov    %eax,(%esp)
f01011d9:	e8 47 ff ff ff       	call   f0101125 <tlb_invalidate>
			pp -> pp_ref--;
f01011de:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f01011e3:	eb 0f                	jmp    f01011f4 <page_insert+0x74>
		}else
			page_remove(pgdir, va);
f01011e5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ec:	89 04 24             	mov    %eax,(%esp)
f01011ef:	e8 3c ff ff ff       	call   f0101130 <page_remove>
	}
	*pte = page2pa(pp)|perm|PTE_P;
f01011f4:	8b 55 14             	mov    0x14(%ebp),%edx
f01011f7:	83 ca 01             	or     $0x1,%edx
f01011fa:	89 d8                	mov    %ebx,%eax
f01011fc:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0101202:	c1 f8 03             	sar    $0x3,%eax
f0101205:	c1 e0 0c             	shl    $0xc,%eax
f0101208:	09 d0                	or     %edx,%eax
f010120a:	89 06                	mov    %eax,(%esi)
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
f010120c:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f0101211:	b8 00 00 00 00       	mov    $0x0,%eax
f0101216:	eb 05                	jmp    f010121d <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
	if(!pte)
		return -E_NO_MEM;
f0101218:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*pte = page2pa(pp)|perm|PTE_P;
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
	return 0;
}
f010121d:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101220:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101223:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101226:	89 ec                	mov    %ebp,%esp
f0101228:	5d                   	pop    %ebp
f0101229:	c3                   	ret    

f010122a <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010122a:	55                   	push   %ebp
f010122b:	89 e5                	mov    %esp,%ebp
f010122d:	57                   	push   %edi
f010122e:	56                   	push   %esi
f010122f:	53                   	push   %ebx
f0101230:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101233:	b8 15 00 00 00       	mov    $0x15,%eax
f0101238:	e8 e5 f7 ff ff       	call   f0100a22 <nvram_read>
f010123d:	c1 e0 0a             	shl    $0xa,%eax
f0101240:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101246:	85 c0                	test   %eax,%eax
f0101248:	0f 48 c2             	cmovs  %edx,%eax
f010124b:	c1 f8 0c             	sar    $0xc,%eax
f010124e:	a3 58 75 11 f0       	mov    %eax,0xf0117558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101253:	b8 17 00 00 00       	mov    $0x17,%eax
f0101258:	e8 c5 f7 ff ff       	call   f0100a22 <nvram_read>
f010125d:	c1 e0 0a             	shl    $0xa,%eax
f0101260:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101266:	85 c0                	test   %eax,%eax
f0101268:	0f 48 c2             	cmovs  %edx,%eax
f010126b:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010126e:	85 c0                	test   %eax,%eax
f0101270:	74 0e                	je     f0101280 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101272:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101278:	89 15 80 79 11 f0    	mov    %edx,0xf0117980
f010127e:	eb 0c                	jmp    f010128c <mem_init+0x62>
	else
		npages = npages_basemem;
f0101280:	8b 15 58 75 11 f0    	mov    0xf0117558,%edx
f0101286:	89 15 80 79 11 f0    	mov    %edx,0xf0117980

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010128c:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010128f:	c1 e8 0a             	shr    $0xa,%eax
f0101292:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101296:	a1 58 75 11 f0       	mov    0xf0117558,%eax
f010129b:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010129e:	c1 e8 0a             	shr    $0xa,%eax
f01012a1:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012a5:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f01012aa:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012ad:	c1 e8 0a             	shr    $0xa,%eax
f01012b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012b4:	c7 04 24 90 44 10 f0 	movl   $0xf0104490,(%esp)
f01012bb:	e8 a6 1a 00 00       	call   f0102d66 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012c0:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012c5:	e8 e5 f6 ff ff       	call   f01009af <boot_alloc>
f01012ca:	a3 84 79 11 f0       	mov    %eax,0xf0117984
	memset(kern_pgdir, 0, PGSIZE);
f01012cf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012d6:	00 
f01012d7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012de:	00 
f01012df:	89 04 24             	mov    %eax,(%esp)
f01012e2:	e8 48 26 00 00       	call   f010392f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012e7:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012ec:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012f1:	77 20                	ja     f0101313 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012f7:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f01012fe:	f0 
f01012ff:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
f0101306:	00 
f0101307:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010130e:	e8 81 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101313:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101319:	83 ca 05             	or     $0x5,%edx
f010131c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page *)boot_alloc(npages * sizeof(struct Page));
f0101322:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0101327:	c1 e0 03             	shl    $0x3,%eax
f010132a:	e8 80 f6 ff ff       	call   f01009af <boot_alloc>
f010132f:	a3 88 79 11 f0       	mov    %eax,0xf0117988
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101334:	e8 9c fa ff ff       	call   f0100dd5 <page_init>

	check_page_free_list(1);
f0101339:	b8 01 00 00 00       	mov    $0x1,%eax
f010133e:	e8 11 f7 ff ff       	call   f0100a54 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101343:	83 3d 88 79 11 f0 00 	cmpl   $0x0,0xf0117988
f010134a:	75 1c                	jne    f0101368 <mem_init+0x13e>
		panic("'pages' is a null pointer!");
f010134c:	c7 44 24 08 17 4b 10 	movl   $0xf0104b17,0x8(%esp)
f0101353:	f0 
f0101354:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f010135b:	00 
f010135c:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101363:	e8 2c ed ff ff       	call   f0100094 <_panic>
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101368:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f010136d:	85 c0                	test   %eax,%eax
f010136f:	74 10                	je     f0101381 <mem_init+0x157>
f0101371:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f0101376:	83 c3 01             	add    $0x1,%ebx
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101379:	8b 00                	mov    (%eax),%eax
f010137b:	85 c0                	test   %eax,%eax
f010137d:	75 f7                	jne    f0101376 <mem_init+0x14c>
f010137f:	eb 05                	jmp    f0101386 <mem_init+0x15c>
f0101381:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101386:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010138d:	e8 19 fb ff ff       	call   f0100eab <page_alloc>
f0101392:	89 c7                	mov    %eax,%edi
f0101394:	85 c0                	test   %eax,%eax
f0101396:	75 24                	jne    f01013bc <mem_init+0x192>
f0101398:	c7 44 24 0c 32 4b 10 	movl   $0xf0104b32,0xc(%esp)
f010139f:	f0 
f01013a0:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01013a7:	f0 
f01013a8:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f01013af:	00 
f01013b0:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01013b7:	e8 d8 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013c3:	e8 e3 fa ff ff       	call   f0100eab <page_alloc>
f01013c8:	89 c6                	mov    %eax,%esi
f01013ca:	85 c0                	test   %eax,%eax
f01013cc:	75 24                	jne    f01013f2 <mem_init+0x1c8>
f01013ce:	c7 44 24 0c 48 4b 10 	movl   $0xf0104b48,0xc(%esp)
f01013d5:	f0 
f01013d6:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01013dd:	f0 
f01013de:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
f01013e5:	00 
f01013e6:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01013ed:	e8 a2 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01013f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013f9:	e8 ad fa ff ff       	call   f0100eab <page_alloc>
f01013fe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101401:	85 c0                	test   %eax,%eax
f0101403:	75 24                	jne    f0101429 <mem_init+0x1ff>
f0101405:	c7 44 24 0c 5e 4b 10 	movl   $0xf0104b5e,0xc(%esp)
f010140c:	f0 
f010140d:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101414:	f0 
f0101415:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f010141c:	00 
f010141d:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101424:	e8 6b ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101429:	39 f7                	cmp    %esi,%edi
f010142b:	75 24                	jne    f0101451 <mem_init+0x227>
f010142d:	c7 44 24 0c 74 4b 10 	movl   $0xf0104b74,0xc(%esp)
f0101434:	f0 
f0101435:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010143c:	f0 
f010143d:	c7 44 24 04 60 02 00 	movl   $0x260,0x4(%esp)
f0101444:	00 
f0101445:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010144c:	e8 43 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101451:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101454:	74 05                	je     f010145b <mem_init+0x231>
f0101456:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101459:	75 24                	jne    f010147f <mem_init+0x255>
f010145b:	c7 44 24 0c cc 44 10 	movl   $0xf01044cc,0xc(%esp)
f0101462:	f0 
f0101463:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010146a:	f0 
f010146b:	c7 44 24 04 61 02 00 	movl   $0x261,0x4(%esp)
f0101472:	00 
f0101473:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010147a:	e8 15 ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010147f:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101485:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f010148a:	c1 e0 0c             	shl    $0xc,%eax
f010148d:	89 f9                	mov    %edi,%ecx
f010148f:	29 d1                	sub    %edx,%ecx
f0101491:	c1 f9 03             	sar    $0x3,%ecx
f0101494:	c1 e1 0c             	shl    $0xc,%ecx
f0101497:	39 c1                	cmp    %eax,%ecx
f0101499:	72 24                	jb     f01014bf <mem_init+0x295>
f010149b:	c7 44 24 0c 86 4b 10 	movl   $0xf0104b86,0xc(%esp)
f01014a2:	f0 
f01014a3:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01014aa:	f0 
f01014ab:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f01014b2:	00 
f01014b3:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01014ba:	e8 d5 eb ff ff       	call   f0100094 <_panic>
f01014bf:	89 f1                	mov    %esi,%ecx
f01014c1:	29 d1                	sub    %edx,%ecx
f01014c3:	c1 f9 03             	sar    $0x3,%ecx
f01014c6:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014c9:	39 c8                	cmp    %ecx,%eax
f01014cb:	77 24                	ja     f01014f1 <mem_init+0x2c7>
f01014cd:	c7 44 24 0c a3 4b 10 	movl   $0xf0104ba3,0xc(%esp)
f01014d4:	f0 
f01014d5:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01014dc:	f0 
f01014dd:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f01014e4:	00 
f01014e5:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01014ec:	e8 a3 eb ff ff       	call   f0100094 <_panic>
f01014f1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01014f4:	29 d1                	sub    %edx,%ecx
f01014f6:	89 ca                	mov    %ecx,%edx
f01014f8:	c1 fa 03             	sar    $0x3,%edx
f01014fb:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014fe:	39 d0                	cmp    %edx,%eax
f0101500:	77 24                	ja     f0101526 <mem_init+0x2fc>
f0101502:	c7 44 24 0c c0 4b 10 	movl   $0xf0104bc0,0xc(%esp)
f0101509:	f0 
f010150a:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101511:	f0 
f0101512:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0101519:	00 
f010151a:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101521:	e8 6e eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101526:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f010152b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010152e:	c7 05 60 75 11 f0 00 	movl   $0x0,0xf0117560
f0101535:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101538:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010153f:	e8 67 f9 ff ff       	call   f0100eab <page_alloc>
f0101544:	85 c0                	test   %eax,%eax
f0101546:	74 24                	je     f010156c <mem_init+0x342>
f0101548:	c7 44 24 0c dd 4b 10 	movl   $0xf0104bdd,0xc(%esp)
f010154f:	f0 
f0101550:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101557:	f0 
f0101558:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f010155f:	00 
f0101560:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101567:	e8 28 eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010156c:	89 3c 24             	mov    %edi,(%esp)
f010156f:	e8 bb f9 ff ff       	call   f0100f2f <page_free>
	page_free(pp1);
f0101574:	89 34 24             	mov    %esi,(%esp)
f0101577:	e8 b3 f9 ff ff       	call   f0100f2f <page_free>
	page_free(pp2);
f010157c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010157f:	89 04 24             	mov    %eax,(%esp)
f0101582:	e8 a8 f9 ff ff       	call   f0100f2f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101587:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010158e:	e8 18 f9 ff ff       	call   f0100eab <page_alloc>
f0101593:	89 c6                	mov    %eax,%esi
f0101595:	85 c0                	test   %eax,%eax
f0101597:	75 24                	jne    f01015bd <mem_init+0x393>
f0101599:	c7 44 24 0c 32 4b 10 	movl   $0xf0104b32,0xc(%esp)
f01015a0:	f0 
f01015a1:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01015a8:	f0 
f01015a9:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f01015b0:	00 
f01015b1:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01015b8:	e8 d7 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c4:	e8 e2 f8 ff ff       	call   f0100eab <page_alloc>
f01015c9:	89 c7                	mov    %eax,%edi
f01015cb:	85 c0                	test   %eax,%eax
f01015cd:	75 24                	jne    f01015f3 <mem_init+0x3c9>
f01015cf:	c7 44 24 0c 48 4b 10 	movl   $0xf0104b48,0xc(%esp)
f01015d6:	f0 
f01015d7:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01015de:	f0 
f01015df:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f01015e6:	00 
f01015e7:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01015ee:	e8 a1 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01015f3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015fa:	e8 ac f8 ff ff       	call   f0100eab <page_alloc>
f01015ff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101602:	85 c0                	test   %eax,%eax
f0101604:	75 24                	jne    f010162a <mem_init+0x400>
f0101606:	c7 44 24 0c 5e 4b 10 	movl   $0xf0104b5e,0xc(%esp)
f010160d:	f0 
f010160e:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101615:	f0 
f0101616:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f010161d:	00 
f010161e:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101625:	e8 6a ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010162a:	39 fe                	cmp    %edi,%esi
f010162c:	75 24                	jne    f0101652 <mem_init+0x428>
f010162e:	c7 44 24 0c 74 4b 10 	movl   $0xf0104b74,0xc(%esp)
f0101635:	f0 
f0101636:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010163d:	f0 
f010163e:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f0101645:	00 
f0101646:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010164d:	e8 42 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101652:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101655:	74 05                	je     f010165c <mem_init+0x432>
f0101657:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010165a:	75 24                	jne    f0101680 <mem_init+0x456>
f010165c:	c7 44 24 0c cc 44 10 	movl   $0xf01044cc,0xc(%esp)
f0101663:	f0 
f0101664:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010166b:	f0 
f010166c:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f0101673:	00 
f0101674:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010167b:	e8 14 ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101680:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101687:	e8 1f f8 ff ff       	call   f0100eab <page_alloc>
f010168c:	85 c0                	test   %eax,%eax
f010168e:	74 24                	je     f01016b4 <mem_init+0x48a>
f0101690:	c7 44 24 0c dd 4b 10 	movl   $0xf0104bdd,0xc(%esp)
f0101697:	f0 
f0101698:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010169f:	f0 
f01016a0:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f01016a7:	00 
f01016a8:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01016af:	e8 e0 e9 ff ff       	call   f0100094 <_panic>
f01016b4:	89 f0                	mov    %esi,%eax
f01016b6:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f01016bc:	c1 f8 03             	sar    $0x3,%eax
f01016bf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016c2:	89 c2                	mov    %eax,%edx
f01016c4:	c1 ea 0c             	shr    $0xc,%edx
f01016c7:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f01016cd:	72 20                	jb     f01016ef <mem_init+0x4c5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016d3:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01016da:	f0 
f01016db:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01016e2:	00 
f01016e3:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f01016ea:	e8 a5 e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016ef:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016f6:	00 
f01016f7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016fe:	00 
	return (void *)(pa + KERNBASE);
f01016ff:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101704:	89 04 24             	mov    %eax,(%esp)
f0101707:	e8 23 22 00 00       	call   f010392f <memset>
	page_free(pp0);
f010170c:	89 34 24             	mov    %esi,(%esp)
f010170f:	e8 1b f8 ff ff       	call   f0100f2f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101714:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010171b:	e8 8b f7 ff ff       	call   f0100eab <page_alloc>
f0101720:	85 c0                	test   %eax,%eax
f0101722:	75 24                	jne    f0101748 <mem_init+0x51e>
f0101724:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f010172b:	f0 
f010172c:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101733:	f0 
f0101734:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f010173b:	00 
f010173c:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101743:	e8 4c e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101748:	39 c6                	cmp    %eax,%esi
f010174a:	74 24                	je     f0101770 <mem_init+0x546>
f010174c:	c7 44 24 0c 0a 4c 10 	movl   $0xf0104c0a,0xc(%esp)
f0101753:	f0 
f0101754:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010175b:	f0 
f010175c:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0101763:	00 
f0101764:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010176b:	e8 24 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101770:	89 f2                	mov    %esi,%edx
f0101772:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101778:	c1 fa 03             	sar    $0x3,%edx
f010177b:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010177e:	89 d0                	mov    %edx,%eax
f0101780:	c1 e8 0c             	shr    $0xc,%eax
f0101783:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0101789:	72 20                	jb     f01017ab <mem_init+0x581>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010178b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010178f:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0101796:	f0 
f0101797:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010179e:	00 
f010179f:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f01017a6:	e8 e9 e8 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017ab:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01017b2:	75 11                	jne    f01017c5 <mem_init+0x59b>
f01017b4:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01017ba:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017c0:	80 38 00             	cmpb   $0x0,(%eax)
f01017c3:	74 24                	je     f01017e9 <mem_init+0x5bf>
f01017c5:	c7 44 24 0c 1a 4c 10 	movl   $0xf0104c1a,0xc(%esp)
f01017cc:	f0 
f01017cd:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01017d4:	f0 
f01017d5:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f01017dc:	00 
f01017dd:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01017e4:	e8 ab e8 ff ff       	call   f0100094 <_panic>
f01017e9:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017ec:	39 d0                	cmp    %edx,%eax
f01017ee:	75 d0                	jne    f01017c0 <mem_init+0x596>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017f0:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01017f3:	89 15 60 75 11 f0    	mov    %edx,0xf0117560

	// free the pages we took
	page_free(pp0);
f01017f9:	89 34 24             	mov    %esi,(%esp)
f01017fc:	e8 2e f7 ff ff       	call   f0100f2f <page_free>
	page_free(pp1);
f0101801:	89 3c 24             	mov    %edi,(%esp)
f0101804:	e8 26 f7 ff ff       	call   f0100f2f <page_free>
	page_free(pp2);
f0101809:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010180c:	89 04 24             	mov    %eax,(%esp)
f010180f:	e8 1b f7 ff ff       	call   f0100f2f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101814:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f0101819:	85 c0                	test   %eax,%eax
f010181b:	74 09                	je     f0101826 <mem_init+0x5fc>
		--nfree;
f010181d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101820:	8b 00                	mov    (%eax),%eax
f0101822:	85 c0                	test   %eax,%eax
f0101824:	75 f7                	jne    f010181d <mem_init+0x5f3>
		--nfree;
	assert(nfree == 0);
f0101826:	85 db                	test   %ebx,%ebx
f0101828:	74 24                	je     f010184e <mem_init+0x624>
f010182a:	c7 44 24 0c 24 4c 10 	movl   $0xf0104c24,0xc(%esp)
f0101831:	f0 
f0101832:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101839:	f0 
f010183a:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0101841:	00 
f0101842:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101849:	e8 46 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010184e:	c7 04 24 ec 44 10 f0 	movl   $0xf01044ec,(%esp)
f0101855:	e8 0c 15 00 00       	call   f0102d66 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010185a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101861:	e8 45 f6 ff ff       	call   f0100eab <page_alloc>
f0101866:	89 c3                	mov    %eax,%ebx
f0101868:	85 c0                	test   %eax,%eax
f010186a:	75 24                	jne    f0101890 <mem_init+0x666>
f010186c:	c7 44 24 0c 32 4b 10 	movl   $0xf0104b32,0xc(%esp)
f0101873:	f0 
f0101874:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010187b:	f0 
f010187c:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0101883:	00 
f0101884:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010188b:	e8 04 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101890:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101897:	e8 0f f6 ff ff       	call   f0100eab <page_alloc>
f010189c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010189f:	85 c0                	test   %eax,%eax
f01018a1:	75 24                	jne    f01018c7 <mem_init+0x69d>
f01018a3:	c7 44 24 0c 48 4b 10 	movl   $0xf0104b48,0xc(%esp)
f01018aa:	f0 
f01018ab:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01018b2:	f0 
f01018b3:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f01018ba:	00 
f01018bb:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01018c2:	e8 cd e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018ce:	e8 d8 f5 ff ff       	call   f0100eab <page_alloc>
f01018d3:	89 c6                	mov    %eax,%esi
f01018d5:	85 c0                	test   %eax,%eax
f01018d7:	75 24                	jne    f01018fd <mem_init+0x6d3>
f01018d9:	c7 44 24 0c 5e 4b 10 	movl   $0xf0104b5e,0xc(%esp)
f01018e0:	f0 
f01018e1:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01018e8:	f0 
f01018e9:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f01018f0:	00 
f01018f1:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01018f8:	e8 97 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018fd:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101900:	75 24                	jne    f0101926 <mem_init+0x6fc>
f0101902:	c7 44 24 0c 74 4b 10 	movl   $0xf0104b74,0xc(%esp)
f0101909:	f0 
f010190a:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101911:	f0 
f0101912:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f0101919:	00 
f010191a:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101921:	e8 6e e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101926:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101929:	74 04                	je     f010192f <mem_init+0x705>
f010192b:	39 c3                	cmp    %eax,%ebx
f010192d:	75 24                	jne    f0101953 <mem_init+0x729>
f010192f:	c7 44 24 0c cc 44 10 	movl   $0xf01044cc,0xc(%esp)
f0101936:	f0 
f0101937:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010193e:	f0 
f010193f:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101946:	00 
f0101947:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010194e:	e8 41 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101953:	8b 3d 60 75 11 f0    	mov    0xf0117560,%edi
f0101959:	89 7d c8             	mov    %edi,-0x38(%ebp)
	page_free_list = 0;
f010195c:	c7 05 60 75 11 f0 00 	movl   $0x0,0xf0117560
f0101963:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101966:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010196d:	e8 39 f5 ff ff       	call   f0100eab <page_alloc>
f0101972:	85 c0                	test   %eax,%eax
f0101974:	74 24                	je     f010199a <mem_init+0x770>
f0101976:	c7 44 24 0c dd 4b 10 	movl   $0xf0104bdd,0xc(%esp)
f010197d:	f0 
f010197e:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101985:	f0 
f0101986:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f010198d:	00 
f010198e:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101995:	e8 fa e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010199a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010199d:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019a1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019a8:	00 
f01019a9:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01019ae:	89 04 24             	mov    %eax,(%esp)
f01019b1:	e8 f6 f6 ff ff       	call   f01010ac <page_lookup>
f01019b6:	85 c0                	test   %eax,%eax
f01019b8:	74 24                	je     f01019de <mem_init+0x7b4>
f01019ba:	c7 44 24 0c 0c 45 10 	movl   $0xf010450c,0xc(%esp)
f01019c1:	f0 
f01019c2:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01019c9:	f0 
f01019ca:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f01019d1:	00 
f01019d2:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01019d9:	e8 b6 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019de:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019e5:	00 
f01019e6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019ed:	00 
f01019ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019f5:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01019fa:	89 04 24             	mov    %eax,(%esp)
f01019fd:	e8 7e f7 ff ff       	call   f0101180 <page_insert>
f0101a02:	85 c0                	test   %eax,%eax
f0101a04:	78 24                	js     f0101a2a <mem_init+0x800>
f0101a06:	c7 44 24 0c 44 45 10 	movl   $0xf0104544,0xc(%esp)
f0101a0d:	f0 
f0101a0e:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101a15:	f0 
f0101a16:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0101a1d:	00 
f0101a1e:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101a25:	e8 6a e6 ff ff       	call   f0100094 <_panic>
//panic("\n");
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a2a:	89 1c 24             	mov    %ebx,(%esp)
f0101a2d:	e8 fd f4 ff ff       	call   f0100f2f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a32:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a39:	00 
f0101a3a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a41:	00 
f0101a42:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a45:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a49:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101a4e:	89 04 24             	mov    %eax,(%esp)
f0101a51:	e8 2a f7 ff ff       	call   f0101180 <page_insert>
f0101a56:	85 c0                	test   %eax,%eax
f0101a58:	74 24                	je     f0101a7e <mem_init+0x854>
f0101a5a:	c7 44 24 0c 74 45 10 	movl   $0xf0104574,0xc(%esp)
f0101a61:	f0 
f0101a62:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101a69:	f0 
f0101a6a:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f0101a71:	00 
f0101a72:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101a79:	e8 16 e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a7e:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a84:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
f0101a8a:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101a8d:	8b 17                	mov    (%edi),%edx
f0101a8f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a95:	89 d8                	mov    %ebx,%eax
f0101a97:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101a9a:	c1 f8 03             	sar    $0x3,%eax
f0101a9d:	c1 e0 0c             	shl    $0xc,%eax
f0101aa0:	39 c2                	cmp    %eax,%edx
f0101aa2:	74 24                	je     f0101ac8 <mem_init+0x89e>
f0101aa4:	c7 44 24 0c a4 45 10 	movl   $0xf01045a4,0xc(%esp)
f0101aab:	f0 
f0101aac:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101ab3:	f0 
f0101ab4:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101abb:	00 
f0101abc:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101ac3:	e8 cc e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101ac8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101acd:	89 f8                	mov    %edi,%eax
f0101acf:	e8 6c ee ff ff       	call   f0100940 <check_va2pa>
f0101ad4:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101ad7:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101ada:	c1 fa 03             	sar    $0x3,%edx
f0101add:	c1 e2 0c             	shl    $0xc,%edx
f0101ae0:	39 d0                	cmp    %edx,%eax
f0101ae2:	74 24                	je     f0101b08 <mem_init+0x8de>
f0101ae4:	c7 44 24 0c cc 45 10 	movl   $0xf01045cc,0xc(%esp)
f0101aeb:	f0 
f0101aec:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101af3:	f0 
f0101af4:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101afb:	00 
f0101afc:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101b03:	e8 8c e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b0b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b10:	74 24                	je     f0101b36 <mem_init+0x90c>
f0101b12:	c7 44 24 0c 2f 4c 10 	movl   $0xf0104c2f,0xc(%esp)
f0101b19:	f0 
f0101b1a:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101b21:	f0 
f0101b22:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101b29:	00 
f0101b2a:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101b31:	e8 5e e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b36:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b3b:	74 24                	je     f0101b61 <mem_init+0x937>
f0101b3d:	c7 44 24 0c 40 4c 10 	movl   $0xf0104c40,0xc(%esp)
f0101b44:	f0 
f0101b45:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101b4c:	f0 
f0101b4d:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101b54:	00 
f0101b55:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101b5c:	e8 33 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b61:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b68:	00 
f0101b69:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b70:	00 
f0101b71:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b75:	89 3c 24             	mov    %edi,(%esp)
f0101b78:	e8 03 f6 ff ff       	call   f0101180 <page_insert>
f0101b7d:	85 c0                	test   %eax,%eax
f0101b7f:	74 24                	je     f0101ba5 <mem_init+0x97b>
f0101b81:	c7 44 24 0c fc 45 10 	movl   $0xf01045fc,0xc(%esp)
f0101b88:	f0 
f0101b89:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101b90:	f0 
f0101b91:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101b98:	00 
f0101b99:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101ba0:	e8 ef e4 ff ff       	call   f0100094 <_panic>
	//panic("va2pa: %x,page %x", check_va2pa(kern_pgdir, PGSIZE), page2pa(pp2));
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ba5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101baa:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101baf:	e8 8c ed ff ff       	call   f0100940 <check_va2pa>
f0101bb4:	89 f2                	mov    %esi,%edx
f0101bb6:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101bbc:	c1 fa 03             	sar    $0x3,%edx
f0101bbf:	c1 e2 0c             	shl    $0xc,%edx
f0101bc2:	39 d0                	cmp    %edx,%eax
f0101bc4:	74 24                	je     f0101bea <mem_init+0x9c0>
f0101bc6:	c7 44 24 0c 38 46 10 	movl   $0xf0104638,0xc(%esp)
f0101bcd:	f0 
f0101bce:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101bd5:	f0 
f0101bd6:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101bdd:	00 
f0101bde:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101be5:	e8 aa e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101bea:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bef:	74 24                	je     f0101c15 <mem_init+0x9eb>
f0101bf1:	c7 44 24 0c 51 4c 10 	movl   $0xf0104c51,0xc(%esp)
f0101bf8:	f0 
f0101bf9:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101c00:	f0 
f0101c01:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101c08:	00 
f0101c09:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101c10:	e8 7f e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c15:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c1c:	e8 8a f2 ff ff       	call   f0100eab <page_alloc>
f0101c21:	85 c0                	test   %eax,%eax
f0101c23:	74 24                	je     f0101c49 <mem_init+0xa1f>
f0101c25:	c7 44 24 0c dd 4b 10 	movl   $0xf0104bdd,0xc(%esp)
f0101c2c:	f0 
f0101c2d:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101c34:	f0 
f0101c35:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101c3c:	00 
f0101c3d:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101c44:	e8 4b e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c49:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c50:	00 
f0101c51:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c58:	00 
f0101c59:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c5d:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101c62:	89 04 24             	mov    %eax,(%esp)
f0101c65:	e8 16 f5 ff ff       	call   f0101180 <page_insert>
f0101c6a:	85 c0                	test   %eax,%eax
f0101c6c:	74 24                	je     f0101c92 <mem_init+0xa68>
f0101c6e:	c7 44 24 0c fc 45 10 	movl   $0xf01045fc,0xc(%esp)
f0101c75:	f0 
f0101c76:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101c7d:	f0 
f0101c7e:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101c85:	00 
f0101c86:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101c8d:	e8 02 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c92:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c97:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101c9c:	e8 9f ec ff ff       	call   f0100940 <check_va2pa>
f0101ca1:	89 f2                	mov    %esi,%edx
f0101ca3:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101ca9:	c1 fa 03             	sar    $0x3,%edx
f0101cac:	c1 e2 0c             	shl    $0xc,%edx
f0101caf:	39 d0                	cmp    %edx,%eax
f0101cb1:	74 24                	je     f0101cd7 <mem_init+0xaad>
f0101cb3:	c7 44 24 0c 38 46 10 	movl   $0xf0104638,0xc(%esp)
f0101cba:	f0 
f0101cbb:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101cc2:	f0 
f0101cc3:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101cca:	00 
f0101ccb:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101cd2:	e8 bd e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101cd7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cdc:	74 24                	je     f0101d02 <mem_init+0xad8>
f0101cde:	c7 44 24 0c 51 4c 10 	movl   $0xf0104c51,0xc(%esp)
f0101ce5:	f0 
f0101ce6:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101ced:	f0 
f0101cee:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101cf5:	00 
f0101cf6:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101cfd:	e8 92 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d02:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d09:	e8 9d f1 ff ff       	call   f0100eab <page_alloc>
f0101d0e:	85 c0                	test   %eax,%eax
f0101d10:	74 24                	je     f0101d36 <mem_init+0xb0c>
f0101d12:	c7 44 24 0c dd 4b 10 	movl   $0xf0104bdd,0xc(%esp)
f0101d19:	f0 
f0101d1a:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101d21:	f0 
f0101d22:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101d29:	00 
f0101d2a:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101d31:	e8 5e e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d36:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f0101d3c:	8b 02                	mov    (%edx),%eax
f0101d3e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d43:	89 c1                	mov    %eax,%ecx
f0101d45:	c1 e9 0c             	shr    $0xc,%ecx
f0101d48:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f0101d4e:	72 20                	jb     f0101d70 <mem_init+0xb46>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d50:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d54:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0101d5b:	f0 
f0101d5c:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101d63:	00 
f0101d64:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101d6b:	e8 24 e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d70:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d75:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d78:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d7f:	00 
f0101d80:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d87:	00 
f0101d88:	89 14 24             	mov    %edx,(%esp)
f0101d8b:	e8 de f1 ff ff       	call   f0100f6e <pgdir_walk>
f0101d90:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101d93:	83 c2 04             	add    $0x4,%edx
f0101d96:	39 d0                	cmp    %edx,%eax
f0101d98:	74 24                	je     f0101dbe <mem_init+0xb94>
f0101d9a:	c7 44 24 0c 68 46 10 	movl   $0xf0104668,0xc(%esp)
f0101da1:	f0 
f0101da2:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101da9:	f0 
f0101daa:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101db1:	00 
f0101db2:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101db9:	e8 d6 e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101dbe:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101dc5:	00 
f0101dc6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dcd:	00 
f0101dce:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101dd2:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101dd7:	89 04 24             	mov    %eax,(%esp)
f0101dda:	e8 a1 f3 ff ff       	call   f0101180 <page_insert>
f0101ddf:	85 c0                	test   %eax,%eax
f0101de1:	74 24                	je     f0101e07 <mem_init+0xbdd>
f0101de3:	c7 44 24 0c a8 46 10 	movl   $0xf01046a8,0xc(%esp)
f0101dea:	f0 
f0101deb:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101df2:	f0 
f0101df3:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101dfa:	00 
f0101dfb:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101e02:	e8 8d e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e07:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0101e0d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e12:	89 f8                	mov    %edi,%eax
f0101e14:	e8 27 eb ff ff       	call   f0100940 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e19:	89 f2                	mov    %esi,%edx
f0101e1b:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101e21:	c1 fa 03             	sar    $0x3,%edx
f0101e24:	c1 e2 0c             	shl    $0xc,%edx
f0101e27:	39 d0                	cmp    %edx,%eax
f0101e29:	74 24                	je     f0101e4f <mem_init+0xc25>
f0101e2b:	c7 44 24 0c 38 46 10 	movl   $0xf0104638,0xc(%esp)
f0101e32:	f0 
f0101e33:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101e3a:	f0 
f0101e3b:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101e42:	00 
f0101e43:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101e4a:	e8 45 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e4f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e54:	74 24                	je     f0101e7a <mem_init+0xc50>
f0101e56:	c7 44 24 0c 51 4c 10 	movl   $0xf0104c51,0xc(%esp)
f0101e5d:	f0 
f0101e5e:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101e65:	f0 
f0101e66:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101e6d:	00 
f0101e6e:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101e75:	e8 1a e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e7a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e81:	00 
f0101e82:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e89:	00 
f0101e8a:	89 3c 24             	mov    %edi,(%esp)
f0101e8d:	e8 dc f0 ff ff       	call   f0100f6e <pgdir_walk>
f0101e92:	f6 00 04             	testb  $0x4,(%eax)
f0101e95:	75 24                	jne    f0101ebb <mem_init+0xc91>
f0101e97:	c7 44 24 0c e8 46 10 	movl   $0xf01046e8,0xc(%esp)
f0101e9e:	f0 
f0101e9f:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101ea6:	f0 
f0101ea7:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101eae:	00 
f0101eaf:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101eb6:	e8 d9 e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ebb:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101ec0:	f6 00 04             	testb  $0x4,(%eax)
f0101ec3:	75 24                	jne    f0101ee9 <mem_init+0xcbf>
f0101ec5:	c7 44 24 0c 62 4c 10 	movl   $0xf0104c62,0xc(%esp)
f0101ecc:	f0 
f0101ecd:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101ed4:	f0 
f0101ed5:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101edc:	00 
f0101edd:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101ee4:	e8 ab e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ee9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ef0:	00 
f0101ef1:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101ef8:	00 
f0101ef9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101efd:	89 04 24             	mov    %eax,(%esp)
f0101f00:	e8 7b f2 ff ff       	call   f0101180 <page_insert>
f0101f05:	85 c0                	test   %eax,%eax
f0101f07:	78 24                	js     f0101f2d <mem_init+0xd03>
f0101f09:	c7 44 24 0c 1c 47 10 	movl   $0xf010471c,0xc(%esp)
f0101f10:	f0 
f0101f11:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101f18:	f0 
f0101f19:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101f20:	00 
f0101f21:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101f28:	e8 67 e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f2d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f34:	00 
f0101f35:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f3c:	00 
f0101f3d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f40:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f44:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101f49:	89 04 24             	mov    %eax,(%esp)
f0101f4c:	e8 2f f2 ff ff       	call   f0101180 <page_insert>
f0101f51:	85 c0                	test   %eax,%eax
f0101f53:	74 24                	je     f0101f79 <mem_init+0xd4f>
f0101f55:	c7 44 24 0c 54 47 10 	movl   $0xf0104754,0xc(%esp)
f0101f5c:	f0 
f0101f5d:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101f64:	f0 
f0101f65:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0101f6c:	00 
f0101f6d:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101f74:	e8 1b e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f79:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f80:	00 
f0101f81:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f88:	00 
f0101f89:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101f8e:	89 04 24             	mov    %eax,(%esp)
f0101f91:	e8 d8 ef ff ff       	call   f0100f6e <pgdir_walk>
f0101f96:	f6 00 04             	testb  $0x4,(%eax)
f0101f99:	74 24                	je     f0101fbf <mem_init+0xd95>
f0101f9b:	c7 44 24 0c 90 47 10 	movl   $0xf0104790,0xc(%esp)
f0101fa2:	f0 
f0101fa3:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101faa:	f0 
f0101fab:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101fb2:	00 
f0101fb3:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0101fba:	e8 d5 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fbf:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0101fc5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fca:	89 f8                	mov    %edi,%eax
f0101fcc:	e8 6f e9 ff ff       	call   f0100940 <check_va2pa>
f0101fd1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101fd4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fd7:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0101fdd:	c1 f8 03             	sar    $0x3,%eax
f0101fe0:	c1 e0 0c             	shl    $0xc,%eax
f0101fe3:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101fe6:	74 24                	je     f010200c <mem_init+0xde2>
f0101fe8:	c7 44 24 0c c8 47 10 	movl   $0xf01047c8,0xc(%esp)
f0101fef:	f0 
f0101ff0:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0101ff7:	f0 
f0101ff8:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101fff:	00 
f0102000:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102007:	e8 88 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010200c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102011:	89 f8                	mov    %edi,%eax
f0102013:	e8 28 e9 ff ff       	call   f0100940 <check_va2pa>
f0102018:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010201b:	74 24                	je     f0102041 <mem_init+0xe17>
f010201d:	c7 44 24 0c f4 47 10 	movl   $0xf01047f4,0xc(%esp)
f0102024:	f0 
f0102025:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010202c:	f0 
f010202d:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102034:	00 
f0102035:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010203c:	e8 53 e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102041:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102044:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0102049:	74 24                	je     f010206f <mem_init+0xe45>
f010204b:	c7 44 24 0c 78 4c 10 	movl   $0xf0104c78,0xc(%esp)
f0102052:	f0 
f0102053:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010205a:	f0 
f010205b:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0102062:	00 
f0102063:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010206a:	e8 25 e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010206f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102074:	74 24                	je     f010209a <mem_init+0xe70>
f0102076:	c7 44 24 0c 89 4c 10 	movl   $0xf0104c89,0xc(%esp)
f010207d:	f0 
f010207e:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102085:	f0 
f0102086:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f010208d:	00 
f010208e:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102095:	e8 fa df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010209a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020a1:	e8 05 ee ff ff       	call   f0100eab <page_alloc>
f01020a6:	85 c0                	test   %eax,%eax
f01020a8:	74 04                	je     f01020ae <mem_init+0xe84>
f01020aa:	39 c6                	cmp    %eax,%esi
f01020ac:	74 24                	je     f01020d2 <mem_init+0xea8>
f01020ae:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f01020b5:	f0 
f01020b6:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01020bd:	f0 
f01020be:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f01020c5:	00 
f01020c6:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01020cd:	e8 c2 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01020d2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01020d9:	00 
f01020da:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01020df:	89 04 24             	mov    %eax,(%esp)
f01020e2:	e8 49 f0 ff ff       	call   f0101130 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020e7:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f01020ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01020f2:	89 f8                	mov    %edi,%eax
f01020f4:	e8 47 e8 ff ff       	call   f0100940 <check_va2pa>
f01020f9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020fc:	74 24                	je     f0102122 <mem_init+0xef8>
f01020fe:	c7 44 24 0c 48 48 10 	movl   $0xf0104848,0xc(%esp)
f0102105:	f0 
f0102106:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010210d:	f0 
f010210e:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0102115:	00 
f0102116:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010211d:	e8 72 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102122:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102127:	89 f8                	mov    %edi,%eax
f0102129:	e8 12 e8 ff ff       	call   f0100940 <check_va2pa>
f010212e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102131:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102137:	c1 fa 03             	sar    $0x3,%edx
f010213a:	c1 e2 0c             	shl    $0xc,%edx
f010213d:	39 d0                	cmp    %edx,%eax
f010213f:	74 24                	je     f0102165 <mem_init+0xf3b>
f0102141:	c7 44 24 0c f4 47 10 	movl   $0xf01047f4,0xc(%esp)
f0102148:	f0 
f0102149:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102150:	f0 
f0102151:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0102158:	00 
f0102159:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102160:	e8 2f df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102165:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102168:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010216d:	74 24                	je     f0102193 <mem_init+0xf69>
f010216f:	c7 44 24 0c 2f 4c 10 	movl   $0xf0104c2f,0xc(%esp)
f0102176:	f0 
f0102177:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010217e:	f0 
f010217f:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0102186:	00 
f0102187:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010218e:	e8 01 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102193:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102198:	74 24                	je     f01021be <mem_init+0xf94>
f010219a:	c7 44 24 0c 89 4c 10 	movl   $0xf0104c89,0xc(%esp)
f01021a1:	f0 
f01021a2:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01021a9:	f0 
f01021aa:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f01021b1:	00 
f01021b2:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01021b9:	e8 d6 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021be:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021c5:	00 
f01021c6:	89 3c 24             	mov    %edi,(%esp)
f01021c9:	e8 62 ef ff ff       	call   f0101130 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021ce:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f01021d4:	ba 00 00 00 00       	mov    $0x0,%edx
f01021d9:	89 f8                	mov    %edi,%eax
f01021db:	e8 60 e7 ff ff       	call   f0100940 <check_va2pa>
f01021e0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021e3:	74 24                	je     f0102209 <mem_init+0xfdf>
f01021e5:	c7 44 24 0c 48 48 10 	movl   $0xf0104848,0xc(%esp)
f01021ec:	f0 
f01021ed:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01021f4:	f0 
f01021f5:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f01021fc:	00 
f01021fd:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102204:	e8 8b de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102209:	ba 00 10 00 00       	mov    $0x1000,%edx
f010220e:	89 f8                	mov    %edi,%eax
f0102210:	e8 2b e7 ff ff       	call   f0100940 <check_va2pa>
f0102215:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102218:	74 24                	je     f010223e <mem_init+0x1014>
f010221a:	c7 44 24 0c 6c 48 10 	movl   $0xf010486c,0xc(%esp)
f0102221:	f0 
f0102222:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102229:	f0 
f010222a:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0102231:	00 
f0102232:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102239:	e8 56 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010223e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102241:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102246:	74 24                	je     f010226c <mem_init+0x1042>
f0102248:	c7 44 24 0c 9a 4c 10 	movl   $0xf0104c9a,0xc(%esp)
f010224f:	f0 
f0102250:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102257:	f0 
f0102258:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f010225f:	00 
f0102260:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102267:	e8 28 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010226c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102271:	74 24                	je     f0102297 <mem_init+0x106d>
f0102273:	c7 44 24 0c 89 4c 10 	movl   $0xf0104c89,0xc(%esp)
f010227a:	f0 
f010227b:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102282:	f0 
f0102283:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f010228a:	00 
f010228b:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102292:	e8 fd dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102297:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010229e:	e8 08 ec ff ff       	call   f0100eab <page_alloc>
f01022a3:	85 c0                	test   %eax,%eax
f01022a5:	74 05                	je     f01022ac <mem_init+0x1082>
f01022a7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01022aa:	74 24                	je     f01022d0 <mem_init+0x10a6>
f01022ac:	c7 44 24 0c 94 48 10 	movl   $0xf0104894,0xc(%esp)
f01022b3:	f0 
f01022b4:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01022bb:	f0 
f01022bc:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f01022c3:	00 
f01022c4:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01022cb:	e8 c4 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01022d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022d7:	e8 cf eb ff ff       	call   f0100eab <page_alloc>
f01022dc:	85 c0                	test   %eax,%eax
f01022de:	74 24                	je     f0102304 <mem_init+0x10da>
f01022e0:	c7 44 24 0c dd 4b 10 	movl   $0xf0104bdd,0xc(%esp)
f01022e7:	f0 
f01022e8:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01022ef:	f0 
f01022f0:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f01022f7:	00 
f01022f8:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01022ff:	e8 90 dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102304:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102309:	8b 08                	mov    (%eax),%ecx
f010230b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102311:	89 da                	mov    %ebx,%edx
f0102313:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102319:	c1 fa 03             	sar    $0x3,%edx
f010231c:	c1 e2 0c             	shl    $0xc,%edx
f010231f:	39 d1                	cmp    %edx,%ecx
f0102321:	74 24                	je     f0102347 <mem_init+0x111d>
f0102323:	c7 44 24 0c a4 45 10 	movl   $0xf01045a4,0xc(%esp)
f010232a:	f0 
f010232b:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102332:	f0 
f0102333:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f010233a:	00 
f010233b:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102342:	e8 4d dd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102347:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010234d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102352:	74 24                	je     f0102378 <mem_init+0x114e>
f0102354:	c7 44 24 0c 40 4c 10 	movl   $0xf0104c40,0xc(%esp)
f010235b:	f0 
f010235c:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102363:	f0 
f0102364:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f010236b:	00 
f010236c:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102373:	e8 1c dd ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102378:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010237e:	89 1c 24             	mov    %ebx,(%esp)
f0102381:	e8 a9 eb ff ff       	call   f0100f2f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102386:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010238d:	00 
f010238e:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102395:	00 
f0102396:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010239b:	89 04 24             	mov    %eax,(%esp)
f010239e:	e8 cb eb ff ff       	call   f0100f6e <pgdir_walk>
f01023a3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01023a6:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f01023ac:	8b 4a 04             	mov    0x4(%edx),%ecx
f01023af:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01023b5:	89 4d cc             	mov    %ecx,-0x34(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023b8:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f01023be:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01023c1:	c1 ef 0c             	shr    $0xc,%edi
f01023c4:	39 cf                	cmp    %ecx,%edi
f01023c6:	72 23                	jb     f01023eb <mem_init+0x11c1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023c8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01023cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01023cf:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01023d6:	f0 
f01023d7:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f01023de:	00 
f01023df:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01023e6:	e8 a9 dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01023eb:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01023ee:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01023f4:	39 f8                	cmp    %edi,%eax
f01023f6:	74 24                	je     f010241c <mem_init+0x11f2>
f01023f8:	c7 44 24 0c ab 4c 10 	movl   $0xf0104cab,0xc(%esp)
f01023ff:	f0 
f0102400:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102407:	f0 
f0102408:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f010240f:	00 
f0102410:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102417:	e8 78 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010241c:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102423:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102429:	89 d8                	mov    %ebx,%eax
f010242b:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0102431:	c1 f8 03             	sar    $0x3,%eax
f0102434:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102437:	89 c2                	mov    %eax,%edx
f0102439:	c1 ea 0c             	shr    $0xc,%edx
f010243c:	39 d1                	cmp    %edx,%ecx
f010243e:	77 20                	ja     f0102460 <mem_init+0x1236>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102440:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102444:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f010244b:	f0 
f010244c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102453:	00 
f0102454:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f010245b:	e8 34 dc ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102460:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102467:	00 
f0102468:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010246f:	00 
	return (void *)(pa + KERNBASE);
f0102470:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102475:	89 04 24             	mov    %eax,(%esp)
f0102478:	e8 b2 14 00 00       	call   f010392f <memset>
	page_free(pp0);
f010247d:	89 1c 24             	mov    %ebx,(%esp)
f0102480:	e8 aa ea ff ff       	call   f0100f2f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102485:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010248c:	00 
f010248d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102494:	00 
f0102495:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010249a:	89 04 24             	mov    %eax,(%esp)
f010249d:	e8 cc ea ff ff       	call   f0100f6e <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024a2:	89 da                	mov    %ebx,%edx
f01024a4:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01024aa:	c1 fa 03             	sar    $0x3,%edx
f01024ad:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024b0:	89 d0                	mov    %edx,%eax
f01024b2:	c1 e8 0c             	shr    $0xc,%eax
f01024b5:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f01024bb:	72 20                	jb     f01024dd <mem_init+0x12b3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024bd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01024c1:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01024c8:	f0 
f01024c9:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01024d0:	00 
f01024d1:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f01024d8:	e8 b7 db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01024dd:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01024e3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01024e6:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f01024ed:	75 11                	jne    f0102500 <mem_init+0x12d6>
f01024ef:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01024f5:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01024fb:	f6 00 01             	testb  $0x1,(%eax)
f01024fe:	74 24                	je     f0102524 <mem_init+0x12fa>
f0102500:	c7 44 24 0c c3 4c 10 	movl   $0xf0104cc3,0xc(%esp)
f0102507:	f0 
f0102508:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010250f:	f0 
f0102510:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102517:	00 
f0102518:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010251f:	e8 70 db ff ff       	call   f0100094 <_panic>
f0102524:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102527:	39 d0                	cmp    %edx,%eax
f0102529:	75 d0                	jne    f01024fb <mem_init+0x12d1>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010252b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102530:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102536:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f010253c:	8b 7d c8             	mov    -0x38(%ebp),%edi
f010253f:	89 3d 60 75 11 f0    	mov    %edi,0xf0117560

	// free the pages we took
	page_free(pp0);
f0102545:	89 1c 24             	mov    %ebx,(%esp)
f0102548:	e8 e2 e9 ff ff       	call   f0100f2f <page_free>
	page_free(pp1);
f010254d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102550:	89 04 24             	mov    %eax,(%esp)
f0102553:	e8 d7 e9 ff ff       	call   f0100f2f <page_free>
	page_free(pp2);
f0102558:	89 34 24             	mov    %esi,(%esp)
f010255b:	e8 cf e9 ff ff       	call   f0100f2f <page_free>

	cprintf("check_page() succeeded!\n");
f0102560:	c7 04 24 da 4c 10 f0 	movl   $0xf0104cda,(%esp)
f0102567:	e8 fa 07 00 00       	call   f0102d66 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
//pte_t *p = (pte_t *)0xf03fd000;
	boot_map_region(kern_pgdir,UPAGES, npages * sizeof(struct Page), PADDR(pages), PTE_U|PTE_P);
f010256c:	a1 88 79 11 f0       	mov    0xf0117988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102571:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102576:	77 20                	ja     f0102598 <mem_init+0x136e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102578:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010257c:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f0102583:	f0 
f0102584:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
f010258b:	00 
f010258c:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102593:	e8 fc da ff ff       	call   f0100094 <_panic>
f0102598:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f010259e:	c1 e1 03             	shl    $0x3,%ecx
f01025a1:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01025a8:	00 
	return (physaddr_t)kva - KERNBASE;
f01025a9:	05 00 00 00 10       	add    $0x10000000,%eax
f01025ae:	89 04 24             	mov    %eax,(%esp)
f01025b1:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025b6:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01025bb:	e8 91 ea ff ff       	call   f0101051 <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	cprintf("\n%x\n", KSTACKTOP - KSTKSIZE);
f01025c0:	c7 44 24 04 00 80 bf 	movl   $0xefbf8000,0x4(%esp)
f01025c7:	ef 
f01025c8:	c7 04 24 f3 4c 10 f0 	movl   $0xf0104cf3,(%esp)
f01025cf:	e8 92 07 00 00       	call   f0102d66 <cprintf>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025d4:	ba 00 d0 10 f0       	mov    $0xf010d000,%edx
f01025d9:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01025df:	77 20                	ja     f0102601 <mem_init+0x13d7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025e1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01025e5:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f01025ec:	f0 
f01025ed:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
f01025f4:	00 
f01025f5:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01025fc:	e8 93 da ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102601:	c7 45 cc 00 d0 10 00 	movl   $0x10d000,-0x34(%ebp)
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_P|PTE_W);
f0102608:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010260f:	00 
f0102610:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102617:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010261c:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102621:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102626:	e8 26 ea ff ff       	call   f0101051 <boot_map_region>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ~0x0 - KERNBASE + 1;
	//cprintf("the size is %x", size);
	boot_map_region(kern_pgdir, KERNBASE, size, (physaddr_t)0,PTE_P|PTE_W);
f010262b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102632:	00 
f0102633:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010263a:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010263f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102644:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102649:	e8 03 ea ff ff       	call   f0101051 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010264e:	8b 1d 84 79 11 f0    	mov    0xf0117984,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f0102654:	8b 3d 80 79 11 f0    	mov    0xf0117980,%edi
f010265a:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010265d:	8d 04 fd ff 0f 00 00 	lea    0xfff(,%edi,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f0102664:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102669:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010266c:	74 7f                	je     f01026ed <mem_init+0x14c3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010266e:	8b 35 88 79 11 f0    	mov    0xf0117988,%esi
f0102674:	8d be 00 00 00 10    	lea    0x10000000(%esi),%edi
f010267a:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010267f:	89 d8                	mov    %ebx,%eax
f0102681:	e8 ba e2 ff ff       	call   f0100940 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102686:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010268c:	77 20                	ja     f01026ae <mem_init+0x1484>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010268e:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102692:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f0102699:	f0 
f010269a:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f01026a1:	00 
f01026a2:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01026a9:	e8 e6 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026ae:	ba 00 00 00 00       	mov    $0x0,%edx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01026b3:	8d 0c 17             	lea    (%edi,%edx,1),%ecx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026b6:	39 c1                	cmp    %eax,%ecx
f01026b8:	74 24                	je     f01026de <mem_init+0x14b4>
f01026ba:	c7 44 24 0c b8 48 10 	movl   $0xf01048b8,0xc(%esp)
f01026c1:	f0 
f01026c2:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01026c9:	f0 
f01026ca:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f01026d1:	00 
f01026d2:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01026d9:	e8 b6 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026de:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f01026e4:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01026e7:	0f 87 e8 05 00 00    	ja     f0102cd5 <mem_init+0x1aab>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01026ed:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01026f0:	c1 e7 0c             	shl    $0xc,%edi
f01026f3:	85 ff                	test   %edi,%edi
f01026f5:	0f 84 b3 05 00 00    	je     f0102cae <mem_init+0x1a84>
f01026fb:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102700:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102706:	89 d8                	mov    %ebx,%eax
f0102708:	e8 33 e2 ff ff       	call   f0100940 <check_va2pa>
f010270d:	39 c6                	cmp    %eax,%esi
f010270f:	74 24                	je     f0102735 <mem_init+0x150b>
f0102711:	c7 44 24 0c ec 48 10 	movl   $0xf01048ec,0xc(%esp)
f0102718:	f0 
f0102719:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102720:	f0 
f0102721:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0102728:	00 
f0102729:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102730:	e8 5f d9 ff ff       	call   f0100094 <_panic>
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102735:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010273b:	39 fe                	cmp    %edi,%esi
f010273d:	72 c1                	jb     f0102700 <mem_init+0x14d6>
f010273f:	e9 6a 05 00 00       	jmp    f0102cae <mem_init+0x1a84>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102744:	39 c3                	cmp    %eax,%ebx
f0102746:	74 24                	je     f010276c <mem_init+0x1542>
f0102748:	c7 44 24 0c 14 49 10 	movl   $0xf0104914,0xc(%esp)
f010274f:	f0 
f0102750:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102757:	f0 
f0102758:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f010275f:	00 
f0102760:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102767:	e8 28 d9 ff ff       	call   f0100094 <_panic>
f010276c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102772:	39 f3                	cmp    %esi,%ebx
f0102774:	0f 85 24 05 00 00    	jne    f0102c9e <mem_init+0x1a74>
f010277a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010277d:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102782:	89 d8                	mov    %ebx,%eax
f0102784:	e8 b7 e1 ff ff       	call   f0100940 <check_va2pa>
f0102789:	83 f8 ff             	cmp    $0xffffffff,%eax
f010278c:	74 24                	je     f01027b2 <mem_init+0x1588>
f010278e:	c7 44 24 0c 5c 49 10 	movl   $0xf010495c,0xc(%esp)
f0102795:	f0 
f0102796:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010279d:	f0 
f010279e:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f01027a5:	00 
f01027a6:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01027ad:	e8 e2 d8 ff ff       	call   f0100094 <_panic>
f01027b2:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01027b7:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01027bd:	83 fa 02             	cmp    $0x2,%edx
f01027c0:	77 2e                	ja     f01027f0 <mem_init+0x15c6>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01027c2:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01027c6:	0f 85 aa 00 00 00    	jne    f0102876 <mem_init+0x164c>
f01027cc:	c7 44 24 0c f8 4c 10 	movl   $0xf0104cf8,0xc(%esp)
f01027d3:	f0 
f01027d4:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01027db:	f0 
f01027dc:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f01027e3:	00 
f01027e4:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01027eb:	e8 a4 d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01027f0:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01027f5:	76 55                	jbe    f010284c <mem_init+0x1622>
				assert(pgdir[i] & PTE_P);
f01027f7:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01027fa:	f6 c2 01             	test   $0x1,%dl
f01027fd:	75 24                	jne    f0102823 <mem_init+0x15f9>
f01027ff:	c7 44 24 0c f8 4c 10 	movl   $0xf0104cf8,0xc(%esp)
f0102806:	f0 
f0102807:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f010280e:	f0 
f010280f:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0102816:	00 
f0102817:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010281e:	e8 71 d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102823:	f6 c2 02             	test   $0x2,%dl
f0102826:	75 4e                	jne    f0102876 <mem_init+0x164c>
f0102828:	c7 44 24 0c 09 4d 10 	movl   $0xf0104d09,0xc(%esp)
f010282f:	f0 
f0102830:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102837:	f0 
f0102838:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f010283f:	00 
f0102840:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102847:	e8 48 d8 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f010284c:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102850:	74 24                	je     f0102876 <mem_init+0x164c>
f0102852:	c7 44 24 0c 1a 4d 10 	movl   $0xf0104d1a,0xc(%esp)
f0102859:	f0 
f010285a:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102861:	f0 
f0102862:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0102869:	00 
f010286a:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102871:	e8 1e d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102876:	83 c0 01             	add    $0x1,%eax
f0102879:	3d 00 04 00 00       	cmp    $0x400,%eax
f010287e:	0f 85 33 ff ff ff    	jne    f01027b7 <mem_init+0x158d>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102884:	c7 04 24 8c 49 10 f0 	movl   $0xf010498c,(%esp)
f010288b:	e8 d6 04 00 00       	call   f0102d66 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102890:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102895:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010289a:	77 20                	ja     f01028bc <mem_init+0x1692>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010289c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028a0:	c7 44 24 08 4c 44 10 	movl   $0xf010444c,0x8(%esp)
f01028a7:	f0 
f01028a8:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
f01028af:	00 
f01028b0:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f01028b7:	e8 d8 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01028bc:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01028c1:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01028c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01028c9:	e8 86 e1 ff ff       	call   f0100a54 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01028ce:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01028d1:	83 e0 f3             	and    $0xfffffff3,%eax
f01028d4:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01028d9:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01028dc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028e3:	e8 c3 e5 ff ff       	call   f0100eab <page_alloc>
f01028e8:	89 c3                	mov    %eax,%ebx
f01028ea:	85 c0                	test   %eax,%eax
f01028ec:	75 24                	jne    f0102912 <mem_init+0x16e8>
f01028ee:	c7 44 24 0c 32 4b 10 	movl   $0xf0104b32,0xc(%esp)
f01028f5:	f0 
f01028f6:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f01028fd:	f0 
f01028fe:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0102905:	00 
f0102906:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f010290d:	e8 82 d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102912:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102919:	e8 8d e5 ff ff       	call   f0100eab <page_alloc>
f010291e:	89 c7                	mov    %eax,%edi
f0102920:	85 c0                	test   %eax,%eax
f0102922:	75 24                	jne    f0102948 <mem_init+0x171e>
f0102924:	c7 44 24 0c 48 4b 10 	movl   $0xf0104b48,0xc(%esp)
f010292b:	f0 
f010292c:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102933:	f0 
f0102934:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f010293b:	00 
f010293c:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102943:	e8 4c d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102948:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010294f:	e8 57 e5 ff ff       	call   f0100eab <page_alloc>
f0102954:	89 c6                	mov    %eax,%esi
f0102956:	85 c0                	test   %eax,%eax
f0102958:	75 24                	jne    f010297e <mem_init+0x1754>
f010295a:	c7 44 24 0c 5e 4b 10 	movl   $0xf0104b5e,0xc(%esp)
f0102961:	f0 
f0102962:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102969:	f0 
f010296a:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102971:	00 
f0102972:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102979:	e8 16 d7 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f010297e:	89 1c 24             	mov    %ebx,(%esp)
f0102981:	e8 a9 e5 ff ff       	call   f0100f2f <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102986:	89 f8                	mov    %edi,%eax
f0102988:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f010298e:	c1 f8 03             	sar    $0x3,%eax
f0102991:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102994:	89 c2                	mov    %eax,%edx
f0102996:	c1 ea 0c             	shr    $0xc,%edx
f0102999:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f010299f:	72 20                	jb     f01029c1 <mem_init+0x1797>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029a5:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01029ac:	f0 
f01029ad:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01029b4:	00 
f01029b5:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f01029bc:	e8 d3 d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029c1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029c8:	00 
f01029c9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01029d0:	00 
	return (void *)(pa + KERNBASE);
f01029d1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029d6:	89 04 24             	mov    %eax,(%esp)
f01029d9:	e8 51 0f 00 00       	call   f010392f <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01029de:	89 f0                	mov    %esi,%eax
f01029e0:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f01029e6:	c1 f8 03             	sar    $0x3,%eax
f01029e9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029ec:	89 c2                	mov    %eax,%edx
f01029ee:	c1 ea 0c             	shr    $0xc,%edx
f01029f1:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f01029f7:	72 20                	jb     f0102a19 <mem_init+0x17ef>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029fd:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0102a04:	f0 
f0102a05:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a0c:	00 
f0102a0d:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f0102a14:	e8 7b d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a19:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a20:	00 
f0102a21:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a28:	00 
	return (void *)(pa + KERNBASE);
f0102a29:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a2e:	89 04 24             	mov    %eax,(%esp)
f0102a31:	e8 f9 0e 00 00       	call   f010392f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a36:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a3d:	00 
f0102a3e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a45:	00 
f0102a46:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102a4a:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102a4f:	89 04 24             	mov    %eax,(%esp)
f0102a52:	e8 29 e7 ff ff       	call   f0101180 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a57:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a5c:	74 24                	je     f0102a82 <mem_init+0x1858>
f0102a5e:	c7 44 24 0c 2f 4c 10 	movl   $0xf0104c2f,0xc(%esp)
f0102a65:	f0 
f0102a66:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102a6d:	f0 
f0102a6e:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0102a75:	00 
f0102a76:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102a7d:	e8 12 d6 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a82:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a89:	01 01 01 
f0102a8c:	74 24                	je     f0102ab2 <mem_init+0x1888>
f0102a8e:	c7 44 24 0c ac 49 10 	movl   $0xf01049ac,0xc(%esp)
f0102a95:	f0 
f0102a96:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102a9d:	f0 
f0102a9e:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0102aa5:	00 
f0102aa6:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102aad:	e8 e2 d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ab2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102ab9:	00 
f0102aba:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ac1:	00 
f0102ac2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ac6:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102acb:	89 04 24             	mov    %eax,(%esp)
f0102ace:	e8 ad e6 ff ff       	call   f0101180 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ad3:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ada:	02 02 02 
f0102add:	74 24                	je     f0102b03 <mem_init+0x18d9>
f0102adf:	c7 44 24 0c d0 49 10 	movl   $0xf01049d0,0xc(%esp)
f0102ae6:	f0 
f0102ae7:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102aee:	f0 
f0102aef:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0102af6:	00 
f0102af7:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102afe:	e8 91 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102b03:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b08:	74 24                	je     f0102b2e <mem_init+0x1904>
f0102b0a:	c7 44 24 0c 51 4c 10 	movl   $0xf0104c51,0xc(%esp)
f0102b11:	f0 
f0102b12:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102b19:	f0 
f0102b1a:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102b21:	00 
f0102b22:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102b29:	e8 66 d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102b2e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b33:	74 24                	je     f0102b59 <mem_init+0x192f>
f0102b35:	c7 44 24 0c 9a 4c 10 	movl   $0xf0104c9a,0xc(%esp)
f0102b3c:	f0 
f0102b3d:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102b44:	f0 
f0102b45:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0102b4c:	00 
f0102b4d:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102b54:	e8 3b d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b59:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b60:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b63:	89 f0                	mov    %esi,%eax
f0102b65:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0102b6b:	c1 f8 03             	sar    $0x3,%eax
f0102b6e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b71:	89 c2                	mov    %eax,%edx
f0102b73:	c1 ea 0c             	shr    $0xc,%edx
f0102b76:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0102b7c:	72 20                	jb     f0102b9e <mem_init+0x1974>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b7e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b82:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f0102b89:	f0 
f0102b8a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b91:	00 
f0102b92:	c7 04 24 6d 4a 10 f0 	movl   $0xf0104a6d,(%esp)
f0102b99:	e8 f6 d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b9e:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102ba5:	03 03 03 
f0102ba8:	74 24                	je     f0102bce <mem_init+0x19a4>
f0102baa:	c7 44 24 0c f4 49 10 	movl   $0xf01049f4,0xc(%esp)
f0102bb1:	f0 
f0102bb2:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102bb9:	f0 
f0102bba:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f0102bc1:	00 
f0102bc2:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102bc9:	e8 c6 d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102bce:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102bd5:	00 
f0102bd6:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102bdb:	89 04 24             	mov    %eax,(%esp)
f0102bde:	e8 4d e5 ff ff       	call   f0101130 <page_remove>
	assert(pp2->pp_ref == 0);
f0102be3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102be8:	74 24                	je     f0102c0e <mem_init+0x19e4>
f0102bea:	c7 44 24 0c 89 4c 10 	movl   $0xf0104c89,0xc(%esp)
f0102bf1:	f0 
f0102bf2:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102bf9:	f0 
f0102bfa:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102c01:	00 
f0102c02:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102c09:	e8 86 d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c0e:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102c13:	8b 08                	mov    (%eax),%ecx
f0102c15:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c1b:	89 da                	mov    %ebx,%edx
f0102c1d:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102c23:	c1 fa 03             	sar    $0x3,%edx
f0102c26:	c1 e2 0c             	shl    $0xc,%edx
f0102c29:	39 d1                	cmp    %edx,%ecx
f0102c2b:	74 24                	je     f0102c51 <mem_init+0x1a27>
f0102c2d:	c7 44 24 0c a4 45 10 	movl   $0xf01045a4,0xc(%esp)
f0102c34:	f0 
f0102c35:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102c3c:	f0 
f0102c3d:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102c44:	00 
f0102c45:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102c4c:	e8 43 d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102c51:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102c57:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c5c:	74 24                	je     f0102c82 <mem_init+0x1a58>
f0102c5e:	c7 44 24 0c 40 4c 10 	movl   $0xf0104c40,0xc(%esp)
f0102c65:	f0 
f0102c66:	c7 44 24 08 87 4a 10 	movl   $0xf0104a87,0x8(%esp)
f0102c6d:	f0 
f0102c6e:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0102c75:	00 
f0102c76:	c7 04 24 4c 4a 10 f0 	movl   $0xf0104a4c,(%esp)
f0102c7d:	e8 12 d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102c82:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c88:	89 1c 24             	mov    %ebx,(%esp)
f0102c8b:	e8 9f e2 ff ff       	call   f0100f2f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c90:	c7 04 24 20 4a 10 f0 	movl   $0xf0104a20,(%esp)
f0102c97:	e8 ca 00 00 00       	call   f0102d66 <cprintf>
f0102c9c:	eb 4b                	jmp    f0102ce9 <mem_init+0x1abf>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102c9e:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102ca1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ca4:	e8 97 dc ff ff       	call   f0100940 <check_va2pa>
f0102ca9:	e9 96 fa ff ff       	jmp    f0102744 <mem_init+0x151a>
f0102cae:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102cb3:	89 d8                	mov    %ebx,%eax
f0102cb5:	e8 86 dc ff ff       	call   f0100940 <check_va2pa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102cba:	be 00 50 11 00       	mov    $0x115000,%esi
f0102cbf:	bf 00 80 bf df       	mov    $0xdfbf8000,%edi
f0102cc4:	81 ef 00 d0 10 f0    	sub    $0xf010d000,%edi
f0102cca:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0102ccd:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0102cd0:	e9 6f fa ff ff       	jmp    f0102744 <mem_init+0x151a>
f0102cd5:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102cdb:	89 d8                	mov    %ebx,%eax
f0102cdd:	e8 5e dc ff ff       	call   f0100940 <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102ce2:	89 f2                	mov    %esi,%edx
f0102ce4:	e9 ca f9 ff ff       	jmp    f01026b3 <mem_init+0x1489>
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();

}
f0102ce9:	83 c4 3c             	add    $0x3c,%esp
f0102cec:	5b                   	pop    %ebx
f0102ced:	5e                   	pop    %esi
f0102cee:	5f                   	pop    %edi
f0102cef:	5d                   	pop    %ebp
f0102cf0:	c3                   	ret    
f0102cf1:	66 90                	xchg   %ax,%ax
f0102cf3:	90                   	nop

f0102cf4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102cf4:	55                   	push   %ebp
f0102cf5:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102cf7:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cfb:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d00:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d01:	b2 71                	mov    $0x71,%dl
f0102d03:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d04:	0f b6 c0             	movzbl %al,%eax
}
f0102d07:	5d                   	pop    %ebp
f0102d08:	c3                   	ret    

f0102d09 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102d09:	55                   	push   %ebp
f0102d0a:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d0c:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d10:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d15:	ee                   	out    %al,(%dx)
f0102d16:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0102d1a:	b2 71                	mov    $0x71,%dl
f0102d1c:	ee                   	out    %al,(%dx)
f0102d1d:	5d                   	pop    %ebp
f0102d1e:	c3                   	ret    
f0102d1f:	90                   	nop

f0102d20 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d20:	55                   	push   %ebp
f0102d21:	89 e5                	mov    %esp,%ebp
f0102d23:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d26:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d29:	89 04 24             	mov    %eax,(%esp)
f0102d2c:	e8 cb d8 ff ff       	call   f01005fc <cputchar>
	*cnt++;
}
f0102d31:	c9                   	leave  
f0102d32:	c3                   	ret    

f0102d33 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d33:	55                   	push   %ebp
f0102d34:	89 e5                	mov    %esp,%ebp
f0102d36:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d39:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d40:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d43:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d47:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d4a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d4e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d55:	c7 04 24 20 2d 10 f0 	movl   $0xf0102d20,(%esp)
f0102d5c:	e8 91 04 00 00       	call   f01031f2 <vprintfmt>
	return cnt;
}
f0102d61:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d64:	c9                   	leave  
f0102d65:	c3                   	ret    

f0102d66 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d66:	55                   	push   %ebp
f0102d67:	89 e5                	mov    %esp,%ebp
f0102d69:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d6c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d6f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d73:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d76:	89 04 24             	mov    %eax,(%esp)
f0102d79:	e8 b5 ff ff ff       	call   f0102d33 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d7e:	c9                   	leave  
f0102d7f:	c3                   	ret    

f0102d80 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d80:	55                   	push   %ebp
f0102d81:	89 e5                	mov    %esp,%ebp
f0102d83:	57                   	push   %edi
f0102d84:	56                   	push   %esi
f0102d85:	53                   	push   %ebx
f0102d86:	83 ec 10             	sub    $0x10,%esp
f0102d89:	89 c6                	mov    %eax,%esi
f0102d8b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d8e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d91:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d94:	8b 1a                	mov    (%edx),%ebx
f0102d96:	8b 09                	mov    (%ecx),%ecx
f0102d98:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102d9b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102da2:	eb 77                	jmp    f0102e1b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102da4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102da7:	01 d8                	add    %ebx,%eax
f0102da9:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102dae:	99                   	cltd   
f0102daf:	f7 f9                	idiv   %ecx
f0102db1:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102db3:	eb 01                	jmp    f0102db6 <stab_binsearch+0x36>
			m--;
f0102db5:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102db6:	39 d9                	cmp    %ebx,%ecx
f0102db8:	7c 1d                	jl     f0102dd7 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102dba:	6b d1 0c             	imul   $0xc,%ecx,%edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102dbd:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102dc2:	39 fa                	cmp    %edi,%edx
f0102dc4:	75 ef                	jne    f0102db5 <stab_binsearch+0x35>
f0102dc6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102dc9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102dcc:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102dd0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102dd3:	73 18                	jae    f0102ded <stab_binsearch+0x6d>
f0102dd5:	eb 05                	jmp    f0102ddc <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102dd7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102dda:	eb 3f                	jmp    f0102e1b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102ddc:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102ddf:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0102de1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102de4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102deb:	eb 2e                	jmp    f0102e1b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102ded:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102df0:	73 15                	jae    f0102e07 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102df2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102df5:	49                   	dec    %ecx
f0102df6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102df9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102dfc:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dfe:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e05:	eb 14                	jmp    f0102e1b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102e07:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e0a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e0d:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0102e0f:	ff 45 0c             	incl   0xc(%ebp)
f0102e12:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e14:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102e1b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102e1e:	7e 84                	jle    f0102da4 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102e20:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102e24:	75 0d                	jne    f0102e33 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102e26:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e29:	8b 02                	mov    (%edx),%eax
f0102e2b:	48                   	dec    %eax
f0102e2c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e2f:	89 01                	mov    %eax,(%ecx)
f0102e31:	eb 22                	jmp    f0102e55 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e33:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e36:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e38:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e3b:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e3d:	eb 01                	jmp    f0102e40 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102e3f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e40:	39 c1                	cmp    %eax,%ecx
f0102e42:	7d 0c                	jge    f0102e50 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e44:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102e47:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102e4c:	39 fa                	cmp    %edi,%edx
f0102e4e:	75 ef                	jne    f0102e3f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102e50:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e53:	89 02                	mov    %eax,(%edx)
	}
}
f0102e55:	83 c4 10             	add    $0x10,%esp
f0102e58:	5b                   	pop    %ebx
f0102e59:	5e                   	pop    %esi
f0102e5a:	5f                   	pop    %edi
f0102e5b:	5d                   	pop    %ebp
f0102e5c:	c3                   	ret    

f0102e5d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102e5d:	55                   	push   %ebp
f0102e5e:	89 e5                	mov    %esp,%ebp
f0102e60:	83 ec 38             	sub    $0x38,%esp
f0102e63:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102e66:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102e69:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102e6c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e6f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102e72:	c7 03 28 4d 10 f0    	movl   $0xf0104d28,(%ebx)
	info->eip_line = 0;
f0102e78:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e7f:	c7 43 08 28 4d 10 f0 	movl   $0xf0104d28,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e86:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e8d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e90:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e97:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e9d:	76 12                	jbe    f0102eb1 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e9f:	b8 2a cd 10 f0       	mov    $0xf010cd2a,%eax
f0102ea4:	3d 99 af 10 f0       	cmp    $0xf010af99,%eax
f0102ea9:	0f 86 99 01 00 00    	jbe    f0103048 <debuginfo_eip+0x1eb>
f0102eaf:	eb 1c                	jmp    f0102ecd <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102eb1:	c7 44 24 08 32 4d 10 	movl   $0xf0104d32,0x8(%esp)
f0102eb8:	f0 
f0102eb9:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102ec0:	00 
f0102ec1:	c7 04 24 3f 4d 10 f0 	movl   $0xf0104d3f,(%esp)
f0102ec8:	e8 c7 d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102ecd:	80 3d 29 cd 10 f0 00 	cmpb   $0x0,0xf010cd29
f0102ed4:	0f 85 75 01 00 00    	jne    f010304f <debuginfo_eip+0x1f2>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102eda:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102ee1:	b8 98 af 10 f0       	mov    $0xf010af98,%eax
f0102ee6:	2d 5c 4f 10 f0       	sub    $0xf0104f5c,%eax
f0102eeb:	c1 f8 02             	sar    $0x2,%eax
f0102eee:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102ef4:	83 e8 01             	sub    $0x1,%eax
f0102ef7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102efa:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102efe:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102f05:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102f08:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102f0b:	b8 5c 4f 10 f0       	mov    $0xf0104f5c,%eax
f0102f10:	e8 6b fe ff ff       	call   f0102d80 <stab_binsearch>
	if (lfile == 0)
f0102f15:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f18:	85 c0                	test   %eax,%eax
f0102f1a:	0f 84 36 01 00 00    	je     f0103056 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102f20:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102f23:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f26:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f29:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f2d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f34:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f37:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f3a:	b8 5c 4f 10 f0       	mov    $0xf0104f5c,%eax
f0102f3f:	e8 3c fe ff ff       	call   f0102d80 <stab_binsearch>

	if (lfun <= rfun) {
f0102f44:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102f47:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102f4a:	7f 2e                	jg     f0102f7a <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f4c:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102f4f:	8d 90 5c 4f 10 f0    	lea    -0xfefb0a4(%eax),%edx
f0102f55:	8b 80 5c 4f 10 f0    	mov    -0xfefb0a4(%eax),%eax
f0102f5b:	b9 2a cd 10 f0       	mov    $0xf010cd2a,%ecx
f0102f60:	81 e9 99 af 10 f0    	sub    $0xf010af99,%ecx
f0102f66:	39 c8                	cmp    %ecx,%eax
f0102f68:	73 08                	jae    f0102f72 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102f6a:	05 99 af 10 f0       	add    $0xf010af99,%eax
f0102f6f:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102f72:	8b 42 08             	mov    0x8(%edx),%eax
f0102f75:	89 43 10             	mov    %eax,0x10(%ebx)
f0102f78:	eb 06                	jmp    f0102f80 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f7a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f80:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f87:	00 
f0102f88:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f8b:	89 04 24             	mov    %eax,(%esp)
f0102f8e:	e8 6d 09 00 00       	call   f0103900 <strfind>
f0102f93:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f96:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f99:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102f9c:	39 cf                	cmp    %ecx,%edi
f0102f9e:	7c 62                	jl     f0103002 <debuginfo_eip+0x1a5>
	       && stabs[lline].n_type != N_SOL
f0102fa0:	6b f7 0c             	imul   $0xc,%edi,%esi
f0102fa3:	81 c6 5c 4f 10 f0    	add    $0xf0104f5c,%esi
f0102fa9:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0102fad:	80 fa 84             	cmp    $0x84,%dl
f0102fb0:	74 31                	je     f0102fe3 <debuginfo_eip+0x186>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0102fb2:	8d 47 ff             	lea    -0x1(%edi),%eax
f0102fb5:	6b c0 0c             	imul   $0xc,%eax,%eax
f0102fb8:	05 5c 4f 10 f0       	add    $0xf0104f5c,%eax
f0102fbd:	eb 15                	jmp    f0102fd4 <debuginfo_eip+0x177>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102fbf:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102fc2:	39 cf                	cmp    %ecx,%edi
f0102fc4:	7c 3c                	jl     f0103002 <debuginfo_eip+0x1a5>
	       && stabs[lline].n_type != N_SOL
f0102fc6:	89 c6                	mov    %eax,%esi
f0102fc8:	83 e8 0c             	sub    $0xc,%eax
f0102fcb:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0102fcf:	80 fa 84             	cmp    $0x84,%dl
f0102fd2:	74 0f                	je     f0102fe3 <debuginfo_eip+0x186>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102fd4:	80 fa 64             	cmp    $0x64,%dl
f0102fd7:	75 e6                	jne    f0102fbf <debuginfo_eip+0x162>
f0102fd9:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0102fdd:	74 e0                	je     f0102fbf <debuginfo_eip+0x162>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102fdf:	39 f9                	cmp    %edi,%ecx
f0102fe1:	7f 1f                	jg     f0103002 <debuginfo_eip+0x1a5>
f0102fe3:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102fe6:	8b 87 5c 4f 10 f0    	mov    -0xfefb0a4(%edi),%eax
f0102fec:	ba 2a cd 10 f0       	mov    $0xf010cd2a,%edx
f0102ff1:	81 ea 99 af 10 f0    	sub    $0xf010af99,%edx
f0102ff7:	39 d0                	cmp    %edx,%eax
f0102ff9:	73 07                	jae    f0103002 <debuginfo_eip+0x1a5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102ffb:	05 99 af 10 f0       	add    $0xf010af99,%eax
f0103000:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103002:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103005:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103008:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010300d:	39 ca                	cmp    %ecx,%edx
f010300f:	7d 5f                	jge    f0103070 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f0103011:	8d 42 01             	lea    0x1(%edx),%eax
f0103014:	39 c1                	cmp    %eax,%ecx
f0103016:	7e 45                	jle    f010305d <debuginfo_eip+0x200>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103018:	6b f0 0c             	imul   $0xc,%eax,%esi
f010301b:	80 be 60 4f 10 f0 a0 	cmpb   $0xa0,-0xfefb0a0(%esi)
f0103022:	75 40                	jne    f0103064 <debuginfo_eip+0x207>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103024:	6b d2 0c             	imul   $0xc,%edx,%edx
f0103027:	81 c2 5c 4f 10 f0    	add    $0xf0104f5c,%edx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010302d:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103031:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103034:	39 c1                	cmp    %eax,%ecx
f0103036:	7e 33                	jle    f010306b <debuginfo_eip+0x20e>
f0103038:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010303b:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f010303f:	74 ec                	je     f010302d <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103041:	b8 00 00 00 00       	mov    $0x0,%eax
f0103046:	eb 28                	jmp    f0103070 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103048:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010304d:	eb 21                	jmp    f0103070 <debuginfo_eip+0x213>
f010304f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103054:	eb 1a                	jmp    f0103070 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103056:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010305b:	eb 13                	jmp    f0103070 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010305d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103062:	eb 0c                	jmp    f0103070 <debuginfo_eip+0x213>
f0103064:	b8 00 00 00 00       	mov    $0x0,%eax
f0103069:	eb 05                	jmp    f0103070 <debuginfo_eip+0x213>
f010306b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103070:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103073:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103076:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103079:	89 ec                	mov    %ebp,%esp
f010307b:	5d                   	pop    %ebp
f010307c:	c3                   	ret    
f010307d:	66 90                	xchg   %ax,%ax
f010307f:	90                   	nop

f0103080 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103080:	55                   	push   %ebp
f0103081:	89 e5                	mov    %esp,%ebp
f0103083:	57                   	push   %edi
f0103084:	56                   	push   %esi
f0103085:	53                   	push   %ebx
f0103086:	83 ec 4c             	sub    $0x4c,%esp
f0103089:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010308c:	89 d7                	mov    %edx,%edi
f010308e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103091:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0103094:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103097:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010309a:	b8 00 00 00 00       	mov    $0x0,%eax
f010309f:	39 d8                	cmp    %ebx,%eax
f01030a1:	72 17                	jb     f01030ba <printnum+0x3a>
f01030a3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01030a6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f01030a9:	76 0f                	jbe    f01030ba <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01030ab:	8b 75 14             	mov    0x14(%ebp),%esi
f01030ae:	83 ee 01             	sub    $0x1,%esi
f01030b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030b4:	85 f6                	test   %esi,%esi
f01030b6:	7f 63                	jg     f010311b <printnum+0x9b>
f01030b8:	eb 75                	jmp    f010312f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01030ba:	8b 5d 18             	mov    0x18(%ebp),%ebx
f01030bd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f01030c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01030c4:	83 e8 01             	sub    $0x1,%eax
f01030c7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030cb:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01030ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01030d2:	8b 44 24 08          	mov    0x8(%esp),%eax
f01030d6:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01030da:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01030dd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01030e0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01030e7:	00 
f01030e8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01030eb:	89 1c 24             	mov    %ebx,(%esp)
f01030ee:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01030f1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01030f5:	e8 96 0a 00 00       	call   f0103b90 <__udivdi3>
f01030fa:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01030fd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103100:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103104:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103108:	89 04 24             	mov    %eax,(%esp)
f010310b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010310f:	89 fa                	mov    %edi,%edx
f0103111:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103114:	e8 67 ff ff ff       	call   f0103080 <printnum>
f0103119:	eb 14                	jmp    f010312f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010311b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010311f:	8b 45 18             	mov    0x18(%ebp),%eax
f0103122:	89 04 24             	mov    %eax,(%esp)
f0103125:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103127:	83 ee 01             	sub    $0x1,%esi
f010312a:	75 ef                	jne    f010311b <printnum+0x9b>
f010312c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010312f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103133:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103137:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010313a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010313e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103145:	00 
f0103146:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0103149:	89 1c 24             	mov    %ebx,(%esp)
f010314c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010314f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103153:	e8 88 0b 00 00       	call   f0103ce0 <__umoddi3>
f0103158:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010315c:	0f be 80 4d 4d 10 f0 	movsbl -0xfefb2b3(%eax),%eax
f0103163:	89 04 24             	mov    %eax,(%esp)
f0103166:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103169:	ff d0                	call   *%eax
}
f010316b:	83 c4 4c             	add    $0x4c,%esp
f010316e:	5b                   	pop    %ebx
f010316f:	5e                   	pop    %esi
f0103170:	5f                   	pop    %edi
f0103171:	5d                   	pop    %ebp
f0103172:	c3                   	ret    

f0103173 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103173:	55                   	push   %ebp
f0103174:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103176:	83 fa 01             	cmp    $0x1,%edx
f0103179:	7e 0e                	jle    f0103189 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010317b:	8b 10                	mov    (%eax),%edx
f010317d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103180:	89 08                	mov    %ecx,(%eax)
f0103182:	8b 02                	mov    (%edx),%eax
f0103184:	8b 52 04             	mov    0x4(%edx),%edx
f0103187:	eb 22                	jmp    f01031ab <getuint+0x38>
	else if (lflag)
f0103189:	85 d2                	test   %edx,%edx
f010318b:	74 10                	je     f010319d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010318d:	8b 10                	mov    (%eax),%edx
f010318f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103192:	89 08                	mov    %ecx,(%eax)
f0103194:	8b 02                	mov    (%edx),%eax
f0103196:	ba 00 00 00 00       	mov    $0x0,%edx
f010319b:	eb 0e                	jmp    f01031ab <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010319d:	8b 10                	mov    (%eax),%edx
f010319f:	8d 4a 04             	lea    0x4(%edx),%ecx
f01031a2:	89 08                	mov    %ecx,(%eax)
f01031a4:	8b 02                	mov    (%edx),%eax
f01031a6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01031ab:	5d                   	pop    %ebp
f01031ac:	c3                   	ret    

f01031ad <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01031ad:	55                   	push   %ebp
f01031ae:	89 e5                	mov    %esp,%ebp
f01031b0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01031b3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01031b7:	8b 10                	mov    (%eax),%edx
f01031b9:	3b 50 04             	cmp    0x4(%eax),%edx
f01031bc:	73 0a                	jae    f01031c8 <sprintputch+0x1b>
		*b->buf++ = ch;
f01031be:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031c1:	88 0a                	mov    %cl,(%edx)
f01031c3:	83 c2 01             	add    $0x1,%edx
f01031c6:	89 10                	mov    %edx,(%eax)
}
f01031c8:	5d                   	pop    %ebp
f01031c9:	c3                   	ret    

f01031ca <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01031ca:	55                   	push   %ebp
f01031cb:	89 e5                	mov    %esp,%ebp
f01031cd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01031d0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01031d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031d7:	8b 45 10             	mov    0x10(%ebp),%eax
f01031da:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01031e8:	89 04 24             	mov    %eax,(%esp)
f01031eb:	e8 02 00 00 00       	call   f01031f2 <vprintfmt>
	va_end(ap);
}
f01031f0:	c9                   	leave  
f01031f1:	c3                   	ret    

f01031f2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01031f2:	55                   	push   %ebp
f01031f3:	89 e5                	mov    %esp,%ebp
f01031f5:	57                   	push   %edi
f01031f6:	56                   	push   %esi
f01031f7:	53                   	push   %ebx
f01031f8:	83 ec 4c             	sub    $0x4c,%esp
f01031fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01031fe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103201:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103204:	eb 11                	jmp    f0103217 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103206:	85 c0                	test   %eax,%eax
f0103208:	0f 84 db 03 00 00    	je     f01035e9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f010320e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103212:	89 04 24             	mov    %eax,(%esp)
f0103215:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103217:	0f b6 07             	movzbl (%edi),%eax
f010321a:	83 c7 01             	add    $0x1,%edi
f010321d:	83 f8 25             	cmp    $0x25,%eax
f0103220:	75 e4                	jne    f0103206 <vprintfmt+0x14>
f0103222:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0103226:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f010322d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103234:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010323b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103240:	eb 2b                	jmp    f010326d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103242:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103245:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0103249:	eb 22                	jmp    f010326d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010324b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010324e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0103252:	eb 19                	jmp    f010326d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103254:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103257:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010325e:	eb 0d                	jmp    f010326d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103260:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103263:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103266:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010326d:	0f b6 0f             	movzbl (%edi),%ecx
f0103270:	8d 47 01             	lea    0x1(%edi),%eax
f0103273:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103276:	0f b6 07             	movzbl (%edi),%eax
f0103279:	83 e8 23             	sub    $0x23,%eax
f010327c:	3c 55                	cmp    $0x55,%al
f010327e:	0f 87 40 03 00 00    	ja     f01035c4 <vprintfmt+0x3d2>
f0103284:	0f b6 c0             	movzbl %al,%eax
f0103287:	ff 24 85 d8 4d 10 f0 	jmp    *-0xfefb228(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010328e:	83 e9 30             	sub    $0x30,%ecx
f0103291:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f0103294:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0103298:	8d 48 d0             	lea    -0x30(%eax),%ecx
f010329b:	83 f9 09             	cmp    $0x9,%ecx
f010329e:	77 57                	ja     f01032f7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032a0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01032a3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01032a6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01032a9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01032ac:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01032af:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f01032b3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f01032b6:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01032b9:	83 f9 09             	cmp    $0x9,%ecx
f01032bc:	76 eb                	jbe    f01032a9 <vprintfmt+0xb7>
f01032be:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01032c1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01032c4:	eb 34                	jmp    f01032fa <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01032c6:	8b 45 14             	mov    0x14(%ebp),%eax
f01032c9:	8d 48 04             	lea    0x4(%eax),%ecx
f01032cc:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01032cf:	8b 00                	mov    (%eax),%eax
f01032d1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032d4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01032d7:	eb 21                	jmp    f01032fa <vprintfmt+0x108>

		case '.':
			if (width < 0)
f01032d9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01032dd:	0f 88 71 ff ff ff    	js     f0103254 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032e3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01032e6:	eb 85                	jmp    f010326d <vprintfmt+0x7b>
f01032e8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01032eb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01032f2:	e9 76 ff ff ff       	jmp    f010326d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032f7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01032fa:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01032fe:	0f 89 69 ff ff ff    	jns    f010326d <vprintfmt+0x7b>
f0103304:	e9 57 ff ff ff       	jmp    f0103260 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103309:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010330c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010330f:	e9 59 ff ff ff       	jmp    f010326d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103314:	8b 45 14             	mov    0x14(%ebp),%eax
f0103317:	8d 50 04             	lea    0x4(%eax),%edx
f010331a:	89 55 14             	mov    %edx,0x14(%ebp)
f010331d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103321:	8b 00                	mov    (%eax),%eax
f0103323:	89 04 24             	mov    %eax,(%esp)
f0103326:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103328:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010332b:	e9 e7 fe ff ff       	jmp    f0103217 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103330:	8b 45 14             	mov    0x14(%ebp),%eax
f0103333:	8d 50 04             	lea    0x4(%eax),%edx
f0103336:	89 55 14             	mov    %edx,0x14(%ebp)
f0103339:	8b 00                	mov    (%eax),%eax
f010333b:	89 c2                	mov    %eax,%edx
f010333d:	c1 fa 1f             	sar    $0x1f,%edx
f0103340:	31 d0                	xor    %edx,%eax
f0103342:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103344:	83 f8 06             	cmp    $0x6,%eax
f0103347:	7f 0b                	jg     f0103354 <vprintfmt+0x162>
f0103349:	8b 14 85 30 4f 10 f0 	mov    -0xfefb0d0(,%eax,4),%edx
f0103350:	85 d2                	test   %edx,%edx
f0103352:	75 20                	jne    f0103374 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0103354:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103358:	c7 44 24 08 65 4d 10 	movl   $0xf0104d65,0x8(%esp)
f010335f:	f0 
f0103360:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103364:	89 34 24             	mov    %esi,(%esp)
f0103367:	e8 5e fe ff ff       	call   f01031ca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010336c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010336f:	e9 a3 fe ff ff       	jmp    f0103217 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0103374:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103378:	c7 44 24 08 99 4a 10 	movl   $0xf0104a99,0x8(%esp)
f010337f:	f0 
f0103380:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103384:	89 34 24             	mov    %esi,(%esp)
f0103387:	e8 3e fe ff ff       	call   f01031ca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010338c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010338f:	e9 83 fe ff ff       	jmp    f0103217 <vprintfmt+0x25>
f0103394:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103397:	8b 7d d8             	mov    -0x28(%ebp),%edi
f010339a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010339d:	8b 45 14             	mov    0x14(%ebp),%eax
f01033a0:	8d 50 04             	lea    0x4(%eax),%edx
f01033a3:	89 55 14             	mov    %edx,0x14(%ebp)
f01033a6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01033a8:	85 ff                	test   %edi,%edi
f01033aa:	b8 5e 4d 10 f0       	mov    $0xf0104d5e,%eax
f01033af:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01033b2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f01033b6:	74 06                	je     f01033be <vprintfmt+0x1cc>
f01033b8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01033bc:	7f 16                	jg     f01033d4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01033be:	0f b6 17             	movzbl (%edi),%edx
f01033c1:	0f be c2             	movsbl %dl,%eax
f01033c4:	83 c7 01             	add    $0x1,%edi
f01033c7:	85 c0                	test   %eax,%eax
f01033c9:	0f 85 9f 00 00 00    	jne    f010346e <vprintfmt+0x27c>
f01033cf:	e9 8b 00 00 00       	jmp    f010345f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01033d4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01033d8:	89 3c 24             	mov    %edi,(%esp)
f01033db:	e8 92 03 00 00       	call   f0103772 <strnlen>
f01033e0:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01033e3:	29 c2                	sub    %eax,%edx
f01033e5:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01033e8:	85 d2                	test   %edx,%edx
f01033ea:	7e d2                	jle    f01033be <vprintfmt+0x1cc>
					putch(padc, putdat);
f01033ec:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f01033f0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01033f3:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01033f6:	89 d7                	mov    %edx,%edi
f01033f8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033ff:	89 04 24             	mov    %eax,(%esp)
f0103402:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103404:	83 ef 01             	sub    $0x1,%edi
f0103407:	75 ef                	jne    f01033f8 <vprintfmt+0x206>
f0103409:	89 7d d8             	mov    %edi,-0x28(%ebp)
f010340c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010340f:	eb ad                	jmp    f01033be <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103411:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103415:	74 20                	je     f0103437 <vprintfmt+0x245>
f0103417:	0f be d2             	movsbl %dl,%edx
f010341a:	83 ea 20             	sub    $0x20,%edx
f010341d:	83 fa 5e             	cmp    $0x5e,%edx
f0103420:	76 15                	jbe    f0103437 <vprintfmt+0x245>
					putch('?', putdat);
f0103422:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103425:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103429:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103430:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103433:	ff d1                	call   *%ecx
f0103435:	eb 0f                	jmp    f0103446 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0103437:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010343a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010343e:	89 04 24             	mov    %eax,(%esp)
f0103441:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103444:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103446:	83 eb 01             	sub    $0x1,%ebx
f0103449:	0f b6 17             	movzbl (%edi),%edx
f010344c:	0f be c2             	movsbl %dl,%eax
f010344f:	83 c7 01             	add    $0x1,%edi
f0103452:	85 c0                	test   %eax,%eax
f0103454:	75 24                	jne    f010347a <vprintfmt+0x288>
f0103456:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0103459:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010345c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010345f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103462:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103466:	0f 8e ab fd ff ff    	jle    f0103217 <vprintfmt+0x25>
f010346c:	eb 20                	jmp    f010348e <vprintfmt+0x29c>
f010346e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103471:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103474:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0103477:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010347a:	85 f6                	test   %esi,%esi
f010347c:	78 93                	js     f0103411 <vprintfmt+0x21f>
f010347e:	83 ee 01             	sub    $0x1,%esi
f0103481:	79 8e                	jns    f0103411 <vprintfmt+0x21f>
f0103483:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0103486:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103489:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010348c:	eb d1                	jmp    f010345f <vprintfmt+0x26d>
f010348e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103491:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103495:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010349c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010349e:	83 ef 01             	sub    $0x1,%edi
f01034a1:	75 ee                	jne    f0103491 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034a3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01034a6:	e9 6c fd ff ff       	jmp    f0103217 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01034ab:	83 fa 01             	cmp    $0x1,%edx
f01034ae:	66 90                	xchg   %ax,%ax
f01034b0:	7e 16                	jle    f01034c8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f01034b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01034b5:	8d 50 08             	lea    0x8(%eax),%edx
f01034b8:	89 55 14             	mov    %edx,0x14(%ebp)
f01034bb:	8b 10                	mov    (%eax),%edx
f01034bd:	8b 48 04             	mov    0x4(%eax),%ecx
f01034c0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01034c3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01034c6:	eb 32                	jmp    f01034fa <vprintfmt+0x308>
	else if (lflag)
f01034c8:	85 d2                	test   %edx,%edx
f01034ca:	74 18                	je     f01034e4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f01034cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01034cf:	8d 50 04             	lea    0x4(%eax),%edx
f01034d2:	89 55 14             	mov    %edx,0x14(%ebp)
f01034d5:	8b 00                	mov    (%eax),%eax
f01034d7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01034da:	89 c1                	mov    %eax,%ecx
f01034dc:	c1 f9 1f             	sar    $0x1f,%ecx
f01034df:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01034e2:	eb 16                	jmp    f01034fa <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f01034e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01034e7:	8d 50 04             	lea    0x4(%eax),%edx
f01034ea:	89 55 14             	mov    %edx,0x14(%ebp)
f01034ed:	8b 00                	mov    (%eax),%eax
f01034ef:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01034f2:	89 c7                	mov    %eax,%edi
f01034f4:	c1 ff 1f             	sar    $0x1f,%edi
f01034f7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01034fa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01034fd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103500:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103505:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103509:	79 7d                	jns    f0103588 <vprintfmt+0x396>
				putch('-', putdat);
f010350b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010350f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103516:	ff d6                	call   *%esi
				num = -(long long) num;
f0103518:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010351b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010351e:	f7 d8                	neg    %eax
f0103520:	83 d2 00             	adc    $0x0,%edx
f0103523:	f7 da                	neg    %edx
			}
			base = 10;
f0103525:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010352a:	eb 5c                	jmp    f0103588 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010352c:	8d 45 14             	lea    0x14(%ebp),%eax
f010352f:	e8 3f fc ff ff       	call   f0103173 <getuint>
			base = 10;
f0103534:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103539:	eb 4d                	jmp    f0103588 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010353b:	8d 45 14             	lea    0x14(%ebp),%eax
f010353e:	e8 30 fc ff ff       	call   f0103173 <getuint>
			base = 8;
f0103543:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103548:	eb 3e                	jmp    f0103588 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
f010354a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010354e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103555:	ff d6                	call   *%esi
			putch('x', putdat);
f0103557:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010355b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103562:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103564:	8b 45 14             	mov    0x14(%ebp),%eax
f0103567:	8d 50 04             	lea    0x4(%eax),%edx
f010356a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010356d:	8b 00                	mov    (%eax),%eax
f010356f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103574:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103579:	eb 0d                	jmp    f0103588 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010357b:	8d 45 14             	lea    0x14(%ebp),%eax
f010357e:	e8 f0 fb ff ff       	call   f0103173 <getuint>
			base = 16;
f0103583:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103588:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010358c:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0103590:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0103593:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103597:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010359b:	89 04 24             	mov    %eax,(%esp)
f010359e:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035a2:	89 da                	mov    %ebx,%edx
f01035a4:	89 f0                	mov    %esi,%eax
f01035a6:	e8 d5 fa ff ff       	call   f0103080 <printnum>
			break;
f01035ab:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01035ae:	e9 64 fc ff ff       	jmp    f0103217 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01035b3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035b7:	89 0c 24             	mov    %ecx,(%esp)
f01035ba:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035bc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01035bf:	e9 53 fc ff ff       	jmp    f0103217 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01035c4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035c8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01035cf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01035d1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01035d5:	0f 84 3c fc ff ff    	je     f0103217 <vprintfmt+0x25>
f01035db:	83 ef 01             	sub    $0x1,%edi
f01035de:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01035e2:	75 f7                	jne    f01035db <vprintfmt+0x3e9>
f01035e4:	e9 2e fc ff ff       	jmp    f0103217 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01035e9:	83 c4 4c             	add    $0x4c,%esp
f01035ec:	5b                   	pop    %ebx
f01035ed:	5e                   	pop    %esi
f01035ee:	5f                   	pop    %edi
f01035ef:	5d                   	pop    %ebp
f01035f0:	c3                   	ret    

f01035f1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01035f1:	55                   	push   %ebp
f01035f2:	89 e5                	mov    %esp,%ebp
f01035f4:	83 ec 28             	sub    $0x28,%esp
f01035f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01035fa:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01035fd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103600:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103604:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103607:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010360e:	85 d2                	test   %edx,%edx
f0103610:	7e 30                	jle    f0103642 <vsnprintf+0x51>
f0103612:	85 c0                	test   %eax,%eax
f0103614:	74 2c                	je     f0103642 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103616:	8b 45 14             	mov    0x14(%ebp),%eax
f0103619:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010361d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103620:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103624:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103627:	89 44 24 04          	mov    %eax,0x4(%esp)
f010362b:	c7 04 24 ad 31 10 f0 	movl   $0xf01031ad,(%esp)
f0103632:	e8 bb fb ff ff       	call   f01031f2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103637:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010363a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010363d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103640:	eb 05                	jmp    f0103647 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103642:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103647:	c9                   	leave  
f0103648:	c3                   	ret    

f0103649 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103649:	55                   	push   %ebp
f010364a:	89 e5                	mov    %esp,%ebp
f010364c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010364f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103652:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103656:	8b 45 10             	mov    0x10(%ebp),%eax
f0103659:	89 44 24 08          	mov    %eax,0x8(%esp)
f010365d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103660:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103664:	8b 45 08             	mov    0x8(%ebp),%eax
f0103667:	89 04 24             	mov    %eax,(%esp)
f010366a:	e8 82 ff ff ff       	call   f01035f1 <vsnprintf>
	va_end(ap);

	return rc;
}
f010366f:	c9                   	leave  
f0103670:	c3                   	ret    
f0103671:	66 90                	xchg   %ax,%ax
f0103673:	66 90                	xchg   %ax,%ax
f0103675:	66 90                	xchg   %ax,%ax
f0103677:	66 90                	xchg   %ax,%ax
f0103679:	66 90                	xchg   %ax,%ax
f010367b:	66 90                	xchg   %ax,%ax
f010367d:	66 90                	xchg   %ax,%ax
f010367f:	90                   	nop

f0103680 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103680:	55                   	push   %ebp
f0103681:	89 e5                	mov    %esp,%ebp
f0103683:	57                   	push   %edi
f0103684:	56                   	push   %esi
f0103685:	53                   	push   %ebx
f0103686:	83 ec 1c             	sub    $0x1c,%esp
f0103689:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010368c:	85 c0                	test   %eax,%eax
f010368e:	74 10                	je     f01036a0 <readline+0x20>
		cprintf("%s", prompt);
f0103690:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103694:	c7 04 24 99 4a 10 f0 	movl   $0xf0104a99,(%esp)
f010369b:	e8 c6 f6 ff ff       	call   f0102d66 <cprintf>

	i = 0;
	echoing = iscons(0);
f01036a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036a7:	e8 71 cf ff ff       	call   f010061d <iscons>
f01036ac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01036ae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01036b3:	e8 54 cf ff ff       	call   f010060c <getchar>
f01036b8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01036ba:	85 c0                	test   %eax,%eax
f01036bc:	79 17                	jns    f01036d5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01036be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036c2:	c7 04 24 4c 4f 10 f0 	movl   $0xf0104f4c,(%esp)
f01036c9:	e8 98 f6 ff ff       	call   f0102d66 <cprintf>
			return NULL;
f01036ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01036d3:	eb 6d                	jmp    f0103742 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01036d5:	83 f8 7f             	cmp    $0x7f,%eax
f01036d8:	74 05                	je     f01036df <readline+0x5f>
f01036da:	83 f8 08             	cmp    $0x8,%eax
f01036dd:	75 19                	jne    f01036f8 <readline+0x78>
f01036df:	85 f6                	test   %esi,%esi
f01036e1:	7e 15                	jle    f01036f8 <readline+0x78>
			if (echoing)
f01036e3:	85 ff                	test   %edi,%edi
f01036e5:	74 0c                	je     f01036f3 <readline+0x73>
				cputchar('\b');
f01036e7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01036ee:	e8 09 cf ff ff       	call   f01005fc <cputchar>
			i--;
f01036f3:	83 ee 01             	sub    $0x1,%esi
f01036f6:	eb bb                	jmp    f01036b3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01036f8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01036fe:	7f 1c                	jg     f010371c <readline+0x9c>
f0103700:	83 fb 1f             	cmp    $0x1f,%ebx
f0103703:	7e 17                	jle    f010371c <readline+0x9c>
			if (echoing)
f0103705:	85 ff                	test   %edi,%edi
f0103707:	74 08                	je     f0103711 <readline+0x91>
				cputchar(c);
f0103709:	89 1c 24             	mov    %ebx,(%esp)
f010370c:	e8 eb ce ff ff       	call   f01005fc <cputchar>
			buf[i++] = c;
f0103711:	88 9e 80 75 11 f0    	mov    %bl,-0xfee8a80(%esi)
f0103717:	83 c6 01             	add    $0x1,%esi
f010371a:	eb 97                	jmp    f01036b3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010371c:	83 fb 0d             	cmp    $0xd,%ebx
f010371f:	74 05                	je     f0103726 <readline+0xa6>
f0103721:	83 fb 0a             	cmp    $0xa,%ebx
f0103724:	75 8d                	jne    f01036b3 <readline+0x33>
			if (echoing)
f0103726:	85 ff                	test   %edi,%edi
f0103728:	74 0c                	je     f0103736 <readline+0xb6>
				cputchar('\n');
f010372a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103731:	e8 c6 ce ff ff       	call   f01005fc <cputchar>
			buf[i] = 0;
f0103736:	c6 86 80 75 11 f0 00 	movb   $0x0,-0xfee8a80(%esi)
			return buf;
f010373d:	b8 80 75 11 f0       	mov    $0xf0117580,%eax
		}
	}
}
f0103742:	83 c4 1c             	add    $0x1c,%esp
f0103745:	5b                   	pop    %ebx
f0103746:	5e                   	pop    %esi
f0103747:	5f                   	pop    %edi
f0103748:	5d                   	pop    %ebp
f0103749:	c3                   	ret    
f010374a:	66 90                	xchg   %ax,%ax
f010374c:	66 90                	xchg   %ax,%ax
f010374e:	66 90                	xchg   %ax,%ax

f0103750 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103750:	55                   	push   %ebp
f0103751:	89 e5                	mov    %esp,%ebp
f0103753:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103756:	80 3a 00             	cmpb   $0x0,(%edx)
f0103759:	74 10                	je     f010376b <strlen+0x1b>
f010375b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0103760:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103763:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103767:	75 f7                	jne    f0103760 <strlen+0x10>
f0103769:	eb 05                	jmp    f0103770 <strlen+0x20>
f010376b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103770:	5d                   	pop    %ebp
f0103771:	c3                   	ret    

f0103772 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103772:	55                   	push   %ebp
f0103773:	89 e5                	mov    %esp,%ebp
f0103775:	53                   	push   %ebx
f0103776:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103779:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010377c:	85 c9                	test   %ecx,%ecx
f010377e:	74 1c                	je     f010379c <strnlen+0x2a>
f0103780:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103783:	74 1e                	je     f01037a3 <strnlen+0x31>
f0103785:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010378a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010378c:	39 ca                	cmp    %ecx,%edx
f010378e:	74 18                	je     f01037a8 <strnlen+0x36>
f0103790:	83 c2 01             	add    $0x1,%edx
f0103793:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103798:	75 f0                	jne    f010378a <strnlen+0x18>
f010379a:	eb 0c                	jmp    f01037a8 <strnlen+0x36>
f010379c:	b8 00 00 00 00       	mov    $0x0,%eax
f01037a1:	eb 05                	jmp    f01037a8 <strnlen+0x36>
f01037a3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01037a8:	5b                   	pop    %ebx
f01037a9:	5d                   	pop    %ebp
f01037aa:	c3                   	ret    

f01037ab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01037ab:	55                   	push   %ebp
f01037ac:	89 e5                	mov    %esp,%ebp
f01037ae:	53                   	push   %ebx
f01037af:	8b 45 08             	mov    0x8(%ebp),%eax
f01037b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01037b5:	89 c2                	mov    %eax,%edx
f01037b7:	0f b6 19             	movzbl (%ecx),%ebx
f01037ba:	88 1a                	mov    %bl,(%edx)
f01037bc:	83 c2 01             	add    $0x1,%edx
f01037bf:	83 c1 01             	add    $0x1,%ecx
f01037c2:	84 db                	test   %bl,%bl
f01037c4:	75 f1                	jne    f01037b7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01037c6:	5b                   	pop    %ebx
f01037c7:	5d                   	pop    %ebp
f01037c8:	c3                   	ret    

f01037c9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01037c9:	55                   	push   %ebp
f01037ca:	89 e5                	mov    %esp,%ebp
f01037cc:	56                   	push   %esi
f01037cd:	53                   	push   %ebx
f01037ce:	8b 75 08             	mov    0x8(%ebp),%esi
f01037d1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037d4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01037d7:	85 db                	test   %ebx,%ebx
f01037d9:	74 16                	je     f01037f1 <strncpy+0x28>
		/* do nothing */;
	return ret;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f01037db:	01 f3                	add    %esi,%ebx
f01037dd:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f01037df:	0f b6 02             	movzbl (%edx),%eax
f01037e2:	88 01                	mov    %al,(%ecx)
f01037e4:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01037e7:	80 3a 01             	cmpb   $0x1,(%edx)
f01037ea:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01037ed:	39 d9                	cmp    %ebx,%ecx
f01037ef:	75 ee                	jne    f01037df <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01037f1:	89 f0                	mov    %esi,%eax
f01037f3:	5b                   	pop    %ebx
f01037f4:	5e                   	pop    %esi
f01037f5:	5d                   	pop    %ebp
f01037f6:	c3                   	ret    

f01037f7 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01037f7:	55                   	push   %ebp
f01037f8:	89 e5                	mov    %esp,%ebp
f01037fa:	57                   	push   %edi
f01037fb:	56                   	push   %esi
f01037fc:	53                   	push   %ebx
f01037fd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103800:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103803:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103806:	89 f8                	mov    %edi,%eax
f0103808:	85 f6                	test   %esi,%esi
f010380a:	74 33                	je     f010383f <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f010380c:	83 fe 01             	cmp    $0x1,%esi
f010380f:	74 25                	je     f0103836 <strlcpy+0x3f>
f0103811:	0f b6 0b             	movzbl (%ebx),%ecx
f0103814:	84 c9                	test   %cl,%cl
f0103816:	74 22                	je     f010383a <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0103818:	83 ee 02             	sub    $0x2,%esi
f010381b:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103820:	88 08                	mov    %cl,(%eax)
f0103822:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103825:	39 f2                	cmp    %esi,%edx
f0103827:	74 13                	je     f010383c <strlcpy+0x45>
f0103829:	83 c2 01             	add    $0x1,%edx
f010382c:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103830:	84 c9                	test   %cl,%cl
f0103832:	75 ec                	jne    f0103820 <strlcpy+0x29>
f0103834:	eb 06                	jmp    f010383c <strlcpy+0x45>
f0103836:	89 f8                	mov    %edi,%eax
f0103838:	eb 02                	jmp    f010383c <strlcpy+0x45>
f010383a:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f010383c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010383f:	29 f8                	sub    %edi,%eax
}
f0103841:	5b                   	pop    %ebx
f0103842:	5e                   	pop    %esi
f0103843:	5f                   	pop    %edi
f0103844:	5d                   	pop    %ebp
f0103845:	c3                   	ret    

f0103846 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103846:	55                   	push   %ebp
f0103847:	89 e5                	mov    %esp,%ebp
f0103849:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010384c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010384f:	0f b6 01             	movzbl (%ecx),%eax
f0103852:	84 c0                	test   %al,%al
f0103854:	74 15                	je     f010386b <strcmp+0x25>
f0103856:	3a 02                	cmp    (%edx),%al
f0103858:	75 11                	jne    f010386b <strcmp+0x25>
		p++, q++;
f010385a:	83 c1 01             	add    $0x1,%ecx
f010385d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103860:	0f b6 01             	movzbl (%ecx),%eax
f0103863:	84 c0                	test   %al,%al
f0103865:	74 04                	je     f010386b <strcmp+0x25>
f0103867:	3a 02                	cmp    (%edx),%al
f0103869:	74 ef                	je     f010385a <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010386b:	0f b6 c0             	movzbl %al,%eax
f010386e:	0f b6 12             	movzbl (%edx),%edx
f0103871:	29 d0                	sub    %edx,%eax
}
f0103873:	5d                   	pop    %ebp
f0103874:	c3                   	ret    

f0103875 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103875:	55                   	push   %ebp
f0103876:	89 e5                	mov    %esp,%ebp
f0103878:	56                   	push   %esi
f0103879:	53                   	push   %ebx
f010387a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010387d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103880:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0103883:	85 f6                	test   %esi,%esi
f0103885:	74 29                	je     f01038b0 <strncmp+0x3b>
f0103887:	0f b6 03             	movzbl (%ebx),%eax
f010388a:	84 c0                	test   %al,%al
f010388c:	74 30                	je     f01038be <strncmp+0x49>
f010388e:	3a 02                	cmp    (%edx),%al
f0103890:	75 2c                	jne    f01038be <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0103892:	8d 43 01             	lea    0x1(%ebx),%eax
f0103895:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0103897:	89 c3                	mov    %eax,%ebx
f0103899:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010389c:	39 f0                	cmp    %esi,%eax
f010389e:	74 17                	je     f01038b7 <strncmp+0x42>
f01038a0:	0f b6 08             	movzbl (%eax),%ecx
f01038a3:	84 c9                	test   %cl,%cl
f01038a5:	74 17                	je     f01038be <strncmp+0x49>
f01038a7:	83 c0 01             	add    $0x1,%eax
f01038aa:	3a 0a                	cmp    (%edx),%cl
f01038ac:	74 e9                	je     f0103897 <strncmp+0x22>
f01038ae:	eb 0e                	jmp    f01038be <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01038b5:	eb 0f                	jmp    f01038c6 <strncmp+0x51>
f01038b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01038bc:	eb 08                	jmp    f01038c6 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01038be:	0f b6 03             	movzbl (%ebx),%eax
f01038c1:	0f b6 12             	movzbl (%edx),%edx
f01038c4:	29 d0                	sub    %edx,%eax
}
f01038c6:	5b                   	pop    %ebx
f01038c7:	5e                   	pop    %esi
f01038c8:	5d                   	pop    %ebp
f01038c9:	c3                   	ret    

f01038ca <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01038ca:	55                   	push   %ebp
f01038cb:	89 e5                	mov    %esp,%ebp
f01038cd:	53                   	push   %ebx
f01038ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01038d1:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01038d4:	0f b6 18             	movzbl (%eax),%ebx
f01038d7:	84 db                	test   %bl,%bl
f01038d9:	74 1d                	je     f01038f8 <strchr+0x2e>
f01038db:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01038dd:	38 d3                	cmp    %dl,%bl
f01038df:	75 06                	jne    f01038e7 <strchr+0x1d>
f01038e1:	eb 1a                	jmp    f01038fd <strchr+0x33>
f01038e3:	38 ca                	cmp    %cl,%dl
f01038e5:	74 16                	je     f01038fd <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01038e7:	83 c0 01             	add    $0x1,%eax
f01038ea:	0f b6 10             	movzbl (%eax),%edx
f01038ed:	84 d2                	test   %dl,%dl
f01038ef:	75 f2                	jne    f01038e3 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f01038f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01038f6:	eb 05                	jmp    f01038fd <strchr+0x33>
f01038f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038fd:	5b                   	pop    %ebx
f01038fe:	5d                   	pop    %ebp
f01038ff:	c3                   	ret    

f0103900 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103900:	55                   	push   %ebp
f0103901:	89 e5                	mov    %esp,%ebp
f0103903:	53                   	push   %ebx
f0103904:	8b 45 08             	mov    0x8(%ebp),%eax
f0103907:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010390a:	0f b6 18             	movzbl (%eax),%ebx
f010390d:	84 db                	test   %bl,%bl
f010390f:	74 1b                	je     f010392c <strfind+0x2c>
f0103911:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0103913:	38 d3                	cmp    %dl,%bl
f0103915:	75 0b                	jne    f0103922 <strfind+0x22>
f0103917:	eb 13                	jmp    f010392c <strfind+0x2c>
f0103919:	38 ca                	cmp    %cl,%dl
f010391b:	90                   	nop
f010391c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103920:	74 0a                	je     f010392c <strfind+0x2c>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103922:	83 c0 01             	add    $0x1,%eax
f0103925:	0f b6 10             	movzbl (%eax),%edx
f0103928:	84 d2                	test   %dl,%dl
f010392a:	75 ed                	jne    f0103919 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010392c:	5b                   	pop    %ebx
f010392d:	5d                   	pop    %ebp
f010392e:	c3                   	ret    

f010392f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010392f:	55                   	push   %ebp
f0103930:	89 e5                	mov    %esp,%ebp
f0103932:	83 ec 0c             	sub    $0xc,%esp
f0103935:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103938:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010393b:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010393e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103941:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103944:	85 c9                	test   %ecx,%ecx
f0103946:	74 36                	je     f010397e <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103948:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010394e:	75 28                	jne    f0103978 <memset+0x49>
f0103950:	f6 c1 03             	test   $0x3,%cl
f0103953:	75 23                	jne    f0103978 <memset+0x49>
		c &= 0xFF;
f0103955:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103959:	89 d3                	mov    %edx,%ebx
f010395b:	c1 e3 08             	shl    $0x8,%ebx
f010395e:	89 d6                	mov    %edx,%esi
f0103960:	c1 e6 18             	shl    $0x18,%esi
f0103963:	89 d0                	mov    %edx,%eax
f0103965:	c1 e0 10             	shl    $0x10,%eax
f0103968:	09 f0                	or     %esi,%eax
f010396a:	09 c2                	or     %eax,%edx
f010396c:	89 d0                	mov    %edx,%eax
f010396e:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103970:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103973:	fc                   	cld    
f0103974:	f3 ab                	rep stos %eax,%es:(%edi)
f0103976:	eb 06                	jmp    f010397e <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103978:	8b 45 0c             	mov    0xc(%ebp),%eax
f010397b:	fc                   	cld    
f010397c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010397e:	89 f8                	mov    %edi,%eax
f0103980:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103983:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103986:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103989:	89 ec                	mov    %ebp,%esp
f010398b:	5d                   	pop    %ebp
f010398c:	c3                   	ret    

f010398d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010398d:	55                   	push   %ebp
f010398e:	89 e5                	mov    %esp,%ebp
f0103990:	83 ec 08             	sub    $0x8,%esp
f0103993:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103996:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103999:	8b 45 08             	mov    0x8(%ebp),%eax
f010399c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010399f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01039a2:	39 c6                	cmp    %eax,%esi
f01039a4:	73 36                	jae    f01039dc <memmove+0x4f>
f01039a6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01039a9:	39 d0                	cmp    %edx,%eax
f01039ab:	73 2f                	jae    f01039dc <memmove+0x4f>
		s += n;
		d += n;
f01039ad:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039b0:	f6 c2 03             	test   $0x3,%dl
f01039b3:	75 1b                	jne    f01039d0 <memmove+0x43>
f01039b5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01039bb:	75 13                	jne    f01039d0 <memmove+0x43>
f01039bd:	f6 c1 03             	test   $0x3,%cl
f01039c0:	75 0e                	jne    f01039d0 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01039c2:	83 ef 04             	sub    $0x4,%edi
f01039c5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01039c8:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01039cb:	fd                   	std    
f01039cc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039ce:	eb 09                	jmp    f01039d9 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01039d0:	83 ef 01             	sub    $0x1,%edi
f01039d3:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01039d6:	fd                   	std    
f01039d7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01039d9:	fc                   	cld    
f01039da:	eb 20                	jmp    f01039fc <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039dc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01039e2:	75 13                	jne    f01039f7 <memmove+0x6a>
f01039e4:	a8 03                	test   $0x3,%al
f01039e6:	75 0f                	jne    f01039f7 <memmove+0x6a>
f01039e8:	f6 c1 03             	test   $0x3,%cl
f01039eb:	75 0a                	jne    f01039f7 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01039ed:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01039f0:	89 c7                	mov    %eax,%edi
f01039f2:	fc                   	cld    
f01039f3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039f5:	eb 05                	jmp    f01039fc <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01039f7:	89 c7                	mov    %eax,%edi
f01039f9:	fc                   	cld    
f01039fa:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01039fc:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01039ff:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103a02:	89 ec                	mov    %ebp,%esp
f0103a04:	5d                   	pop    %ebp
f0103a05:	c3                   	ret    

f0103a06 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103a06:	55                   	push   %ebp
f0103a07:	89 e5                	mov    %esp,%ebp
f0103a09:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103a0c:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a0f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a13:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a16:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a1d:	89 04 24             	mov    %eax,(%esp)
f0103a20:	e8 68 ff ff ff       	call   f010398d <memmove>
}
f0103a25:	c9                   	leave  
f0103a26:	c3                   	ret    

f0103a27 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a27:	55                   	push   %ebp
f0103a28:	89 e5                	mov    %esp,%ebp
f0103a2a:	57                   	push   %edi
f0103a2b:	56                   	push   %esi
f0103a2c:	53                   	push   %ebx
f0103a2d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103a30:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a33:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a36:	8d 78 ff             	lea    -0x1(%eax),%edi
f0103a39:	85 c0                	test   %eax,%eax
f0103a3b:	74 36                	je     f0103a73 <memcmp+0x4c>
		if (*s1 != *s2)
f0103a3d:	0f b6 03             	movzbl (%ebx),%eax
f0103a40:	0f b6 0e             	movzbl (%esi),%ecx
f0103a43:	38 c8                	cmp    %cl,%al
f0103a45:	75 17                	jne    f0103a5e <memcmp+0x37>
f0103a47:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a4c:	eb 1a                	jmp    f0103a68 <memcmp+0x41>
f0103a4e:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103a53:	83 c2 01             	add    $0x1,%edx
f0103a56:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103a5a:	38 c8                	cmp    %cl,%al
f0103a5c:	74 0a                	je     f0103a68 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0103a5e:	0f b6 c0             	movzbl %al,%eax
f0103a61:	0f b6 c9             	movzbl %cl,%ecx
f0103a64:	29 c8                	sub    %ecx,%eax
f0103a66:	eb 10                	jmp    f0103a78 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a68:	39 fa                	cmp    %edi,%edx
f0103a6a:	75 e2                	jne    f0103a4e <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a6c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a71:	eb 05                	jmp    f0103a78 <memcmp+0x51>
f0103a73:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a78:	5b                   	pop    %ebx
f0103a79:	5e                   	pop    %esi
f0103a7a:	5f                   	pop    %edi
f0103a7b:	5d                   	pop    %ebp
f0103a7c:	c3                   	ret    

f0103a7d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a7d:	55                   	push   %ebp
f0103a7e:	89 e5                	mov    %esp,%ebp
f0103a80:	53                   	push   %ebx
f0103a81:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a84:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0103a87:	89 c2                	mov    %eax,%edx
f0103a89:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a8c:	39 d0                	cmp    %edx,%eax
f0103a8e:	73 13                	jae    f0103aa3 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a90:	89 d9                	mov    %ebx,%ecx
f0103a92:	38 18                	cmp    %bl,(%eax)
f0103a94:	75 06                	jne    f0103a9c <memfind+0x1f>
f0103a96:	eb 0b                	jmp    f0103aa3 <memfind+0x26>
f0103a98:	38 08                	cmp    %cl,(%eax)
f0103a9a:	74 07                	je     f0103aa3 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103a9c:	83 c0 01             	add    $0x1,%eax
f0103a9f:	39 d0                	cmp    %edx,%eax
f0103aa1:	75 f5                	jne    f0103a98 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103aa3:	5b                   	pop    %ebx
f0103aa4:	5d                   	pop    %ebp
f0103aa5:	c3                   	ret    

f0103aa6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103aa6:	55                   	push   %ebp
f0103aa7:	89 e5                	mov    %esp,%ebp
f0103aa9:	57                   	push   %edi
f0103aaa:	56                   	push   %esi
f0103aab:	53                   	push   %ebx
f0103aac:	83 ec 04             	sub    $0x4,%esp
f0103aaf:	8b 55 08             	mov    0x8(%ebp),%edx
f0103ab2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103ab5:	0f b6 02             	movzbl (%edx),%eax
f0103ab8:	3c 09                	cmp    $0x9,%al
f0103aba:	74 04                	je     f0103ac0 <strtol+0x1a>
f0103abc:	3c 20                	cmp    $0x20,%al
f0103abe:	75 0e                	jne    f0103ace <strtol+0x28>
		s++;
f0103ac0:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103ac3:	0f b6 02             	movzbl (%edx),%eax
f0103ac6:	3c 09                	cmp    $0x9,%al
f0103ac8:	74 f6                	je     f0103ac0 <strtol+0x1a>
f0103aca:	3c 20                	cmp    $0x20,%al
f0103acc:	74 f2                	je     f0103ac0 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103ace:	3c 2b                	cmp    $0x2b,%al
f0103ad0:	75 0a                	jne    f0103adc <strtol+0x36>
		s++;
f0103ad2:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103ad5:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ada:	eb 10                	jmp    f0103aec <strtol+0x46>
f0103adc:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103ae1:	3c 2d                	cmp    $0x2d,%al
f0103ae3:	75 07                	jne    f0103aec <strtol+0x46>
		s++, neg = 1;
f0103ae5:	83 c2 01             	add    $0x1,%edx
f0103ae8:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103aec:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103af2:	75 15                	jne    f0103b09 <strtol+0x63>
f0103af4:	80 3a 30             	cmpb   $0x30,(%edx)
f0103af7:	75 10                	jne    f0103b09 <strtol+0x63>
f0103af9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103afd:	75 0a                	jne    f0103b09 <strtol+0x63>
		s += 2, base = 16;
f0103aff:	83 c2 02             	add    $0x2,%edx
f0103b02:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103b07:	eb 10                	jmp    f0103b19 <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0103b09:	85 db                	test   %ebx,%ebx
f0103b0b:	75 0c                	jne    f0103b19 <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103b0d:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103b0f:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b12:	75 05                	jne    f0103b19 <strtol+0x73>
		s++, base = 8;
f0103b14:	83 c2 01             	add    $0x1,%edx
f0103b17:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103b19:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b1e:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103b21:	0f b6 0a             	movzbl (%edx),%ecx
f0103b24:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103b27:	89 f3                	mov    %esi,%ebx
f0103b29:	80 fb 09             	cmp    $0x9,%bl
f0103b2c:	77 08                	ja     f0103b36 <strtol+0x90>
			dig = *s - '0';
f0103b2e:	0f be c9             	movsbl %cl,%ecx
f0103b31:	83 e9 30             	sub    $0x30,%ecx
f0103b34:	eb 22                	jmp    f0103b58 <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0103b36:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103b39:	89 f3                	mov    %esi,%ebx
f0103b3b:	80 fb 19             	cmp    $0x19,%bl
f0103b3e:	77 08                	ja     f0103b48 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0103b40:	0f be c9             	movsbl %cl,%ecx
f0103b43:	83 e9 57             	sub    $0x57,%ecx
f0103b46:	eb 10                	jmp    f0103b58 <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0103b48:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103b4b:	89 f3                	mov    %esi,%ebx
f0103b4d:	80 fb 19             	cmp    $0x19,%bl
f0103b50:	77 16                	ja     f0103b68 <strtol+0xc2>
			dig = *s - 'A' + 10;
f0103b52:	0f be c9             	movsbl %cl,%ecx
f0103b55:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103b58:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103b5b:	7d 0f                	jge    f0103b6c <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0103b5d:	83 c2 01             	add    $0x1,%edx
f0103b60:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0103b64:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103b66:	eb b9                	jmp    f0103b21 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103b68:	89 c1                	mov    %eax,%ecx
f0103b6a:	eb 02                	jmp    f0103b6e <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103b6c:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103b6e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b72:	74 05                	je     f0103b79 <strtol+0xd3>
		*endptr = (char *) s;
f0103b74:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b77:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103b79:	89 ca                	mov    %ecx,%edx
f0103b7b:	f7 da                	neg    %edx
f0103b7d:	85 ff                	test   %edi,%edi
f0103b7f:	0f 45 c2             	cmovne %edx,%eax
}
f0103b82:	83 c4 04             	add    $0x4,%esp
f0103b85:	5b                   	pop    %ebx
f0103b86:	5e                   	pop    %esi
f0103b87:	5f                   	pop    %edi
f0103b88:	5d                   	pop    %ebp
f0103b89:	c3                   	ret    
f0103b8a:	66 90                	xchg   %ax,%ax
f0103b8c:	66 90                	xchg   %ax,%ax
f0103b8e:	66 90                	xchg   %ax,%ax

f0103b90 <__udivdi3>:
f0103b90:	83 ec 1c             	sub    $0x1c,%esp
f0103b93:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0103b97:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103b9b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103b9f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103ba3:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0103ba7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f0103bab:	85 c0                	test   %eax,%eax
f0103bad:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103bb1:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103bb5:	89 ea                	mov    %ebp,%edx
f0103bb7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103bbb:	75 33                	jne    f0103bf0 <__udivdi3+0x60>
f0103bbd:	39 e9                	cmp    %ebp,%ecx
f0103bbf:	77 6f                	ja     f0103c30 <__udivdi3+0xa0>
f0103bc1:	85 c9                	test   %ecx,%ecx
f0103bc3:	89 ce                	mov    %ecx,%esi
f0103bc5:	75 0b                	jne    f0103bd2 <__udivdi3+0x42>
f0103bc7:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bcc:	31 d2                	xor    %edx,%edx
f0103bce:	f7 f1                	div    %ecx
f0103bd0:	89 c6                	mov    %eax,%esi
f0103bd2:	31 d2                	xor    %edx,%edx
f0103bd4:	89 e8                	mov    %ebp,%eax
f0103bd6:	f7 f6                	div    %esi
f0103bd8:	89 c5                	mov    %eax,%ebp
f0103bda:	89 f8                	mov    %edi,%eax
f0103bdc:	f7 f6                	div    %esi
f0103bde:	89 ea                	mov    %ebp,%edx
f0103be0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103be4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103be8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103bec:	83 c4 1c             	add    $0x1c,%esp
f0103bef:	c3                   	ret    
f0103bf0:	39 e8                	cmp    %ebp,%eax
f0103bf2:	77 24                	ja     f0103c18 <__udivdi3+0x88>
f0103bf4:	0f bd c8             	bsr    %eax,%ecx
f0103bf7:	83 f1 1f             	xor    $0x1f,%ecx
f0103bfa:	89 0c 24             	mov    %ecx,(%esp)
f0103bfd:	75 49                	jne    f0103c48 <__udivdi3+0xb8>
f0103bff:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103c03:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0103c07:	0f 86 ab 00 00 00    	jbe    f0103cb8 <__udivdi3+0x128>
f0103c0d:	39 e8                	cmp    %ebp,%eax
f0103c0f:	0f 82 a3 00 00 00    	jb     f0103cb8 <__udivdi3+0x128>
f0103c15:	8d 76 00             	lea    0x0(%esi),%esi
f0103c18:	31 d2                	xor    %edx,%edx
f0103c1a:	31 c0                	xor    %eax,%eax
f0103c1c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c20:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c24:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c28:	83 c4 1c             	add    $0x1c,%esp
f0103c2b:	c3                   	ret    
f0103c2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c30:	89 f8                	mov    %edi,%eax
f0103c32:	f7 f1                	div    %ecx
f0103c34:	31 d2                	xor    %edx,%edx
f0103c36:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c3a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c3e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c42:	83 c4 1c             	add    $0x1c,%esp
f0103c45:	c3                   	ret    
f0103c46:	66 90                	xchg   %ax,%ax
f0103c48:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103c4c:	89 c6                	mov    %eax,%esi
f0103c4e:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c53:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0103c57:	2b 04 24             	sub    (%esp),%eax
f0103c5a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103c5e:	d3 e6                	shl    %cl,%esi
f0103c60:	89 c1                	mov    %eax,%ecx
f0103c62:	d3 ed                	shr    %cl,%ebp
f0103c64:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103c68:	09 f5                	or     %esi,%ebp
f0103c6a:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103c6e:	d3 e6                	shl    %cl,%esi
f0103c70:	89 c1                	mov    %eax,%ecx
f0103c72:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103c76:	89 d6                	mov    %edx,%esi
f0103c78:	d3 ee                	shr    %cl,%esi
f0103c7a:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103c7e:	d3 e2                	shl    %cl,%edx
f0103c80:	89 c1                	mov    %eax,%ecx
f0103c82:	d3 ef                	shr    %cl,%edi
f0103c84:	09 d7                	or     %edx,%edi
f0103c86:	89 f2                	mov    %esi,%edx
f0103c88:	89 f8                	mov    %edi,%eax
f0103c8a:	f7 f5                	div    %ebp
f0103c8c:	89 d6                	mov    %edx,%esi
f0103c8e:	89 c7                	mov    %eax,%edi
f0103c90:	f7 64 24 04          	mull   0x4(%esp)
f0103c94:	39 d6                	cmp    %edx,%esi
f0103c96:	72 30                	jb     f0103cc8 <__udivdi3+0x138>
f0103c98:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103c9c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103ca0:	d3 e5                	shl    %cl,%ebp
f0103ca2:	39 c5                	cmp    %eax,%ebp
f0103ca4:	73 04                	jae    f0103caa <__udivdi3+0x11a>
f0103ca6:	39 d6                	cmp    %edx,%esi
f0103ca8:	74 1e                	je     f0103cc8 <__udivdi3+0x138>
f0103caa:	89 f8                	mov    %edi,%eax
f0103cac:	31 d2                	xor    %edx,%edx
f0103cae:	e9 69 ff ff ff       	jmp    f0103c1c <__udivdi3+0x8c>
f0103cb3:	90                   	nop
f0103cb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cb8:	31 d2                	xor    %edx,%edx
f0103cba:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cbf:	e9 58 ff ff ff       	jmp    f0103c1c <__udivdi3+0x8c>
f0103cc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cc8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103ccb:	31 d2                	xor    %edx,%edx
f0103ccd:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cd1:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103cd5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103cd9:	83 c4 1c             	add    $0x1c,%esp
f0103cdc:	c3                   	ret    
f0103cdd:	66 90                	xchg   %ax,%ax
f0103cdf:	90                   	nop

f0103ce0 <__umoddi3>:
f0103ce0:	83 ec 2c             	sub    $0x2c,%esp
f0103ce3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0103ce7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103ceb:	89 74 24 20          	mov    %esi,0x20(%esp)
f0103cef:	8b 74 24 38          	mov    0x38(%esp),%esi
f0103cf3:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0103cf7:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0103cfb:	85 c0                	test   %eax,%eax
f0103cfd:	89 c2                	mov    %eax,%edx
f0103cff:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0103d03:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0103d07:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d0b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103d0f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0103d13:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103d17:	75 1f                	jne    f0103d38 <__umoddi3+0x58>
f0103d19:	39 fe                	cmp    %edi,%esi
f0103d1b:	76 63                	jbe    f0103d80 <__umoddi3+0xa0>
f0103d1d:	89 c8                	mov    %ecx,%eax
f0103d1f:	89 fa                	mov    %edi,%edx
f0103d21:	f7 f6                	div    %esi
f0103d23:	89 d0                	mov    %edx,%eax
f0103d25:	31 d2                	xor    %edx,%edx
f0103d27:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103d2b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103d2f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103d33:	83 c4 2c             	add    $0x2c,%esp
f0103d36:	c3                   	ret    
f0103d37:	90                   	nop
f0103d38:	39 f8                	cmp    %edi,%eax
f0103d3a:	77 64                	ja     f0103da0 <__umoddi3+0xc0>
f0103d3c:	0f bd e8             	bsr    %eax,%ebp
f0103d3f:	83 f5 1f             	xor    $0x1f,%ebp
f0103d42:	75 74                	jne    f0103db8 <__umoddi3+0xd8>
f0103d44:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d48:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f0103d4c:	0f 87 0e 01 00 00    	ja     f0103e60 <__umoddi3+0x180>
f0103d52:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0103d56:	29 f1                	sub    %esi,%ecx
f0103d58:	19 c7                	sbb    %eax,%edi
f0103d5a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0103d5e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103d62:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103d66:	8b 54 24 18          	mov    0x18(%esp),%edx
f0103d6a:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103d6e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103d72:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103d76:	83 c4 2c             	add    $0x2c,%esp
f0103d79:	c3                   	ret    
f0103d7a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103d80:	85 f6                	test   %esi,%esi
f0103d82:	89 f5                	mov    %esi,%ebp
f0103d84:	75 0b                	jne    f0103d91 <__umoddi3+0xb1>
f0103d86:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d8b:	31 d2                	xor    %edx,%edx
f0103d8d:	f7 f6                	div    %esi
f0103d8f:	89 c5                	mov    %eax,%ebp
f0103d91:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103d95:	31 d2                	xor    %edx,%edx
f0103d97:	f7 f5                	div    %ebp
f0103d99:	89 c8                	mov    %ecx,%eax
f0103d9b:	f7 f5                	div    %ebp
f0103d9d:	eb 84                	jmp    f0103d23 <__umoddi3+0x43>
f0103d9f:	90                   	nop
f0103da0:	89 c8                	mov    %ecx,%eax
f0103da2:	89 fa                	mov    %edi,%edx
f0103da4:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103da8:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103dac:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103db0:	83 c4 2c             	add    $0x2c,%esp
f0103db3:	c3                   	ret    
f0103db4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103db8:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103dbc:	be 20 00 00 00       	mov    $0x20,%esi
f0103dc1:	89 e9                	mov    %ebp,%ecx
f0103dc3:	29 ee                	sub    %ebp,%esi
f0103dc5:	d3 e2                	shl    %cl,%edx
f0103dc7:	89 f1                	mov    %esi,%ecx
f0103dc9:	d3 e8                	shr    %cl,%eax
f0103dcb:	89 e9                	mov    %ebp,%ecx
f0103dcd:	09 d0                	or     %edx,%eax
f0103dcf:	89 fa                	mov    %edi,%edx
f0103dd1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103dd5:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103dd9:	d3 e0                	shl    %cl,%eax
f0103ddb:	89 f1                	mov    %esi,%ecx
f0103ddd:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103de1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0103de5:	d3 ea                	shr    %cl,%edx
f0103de7:	89 e9                	mov    %ebp,%ecx
f0103de9:	d3 e7                	shl    %cl,%edi
f0103deb:	89 f1                	mov    %esi,%ecx
f0103ded:	d3 e8                	shr    %cl,%eax
f0103def:	89 e9                	mov    %ebp,%ecx
f0103df1:	09 f8                	or     %edi,%eax
f0103df3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103df7:	f7 74 24 0c          	divl   0xc(%esp)
f0103dfb:	d3 e7                	shl    %cl,%edi
f0103dfd:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103e01:	89 d7                	mov    %edx,%edi
f0103e03:	f7 64 24 10          	mull   0x10(%esp)
f0103e07:	39 d7                	cmp    %edx,%edi
f0103e09:	89 c1                	mov    %eax,%ecx
f0103e0b:	89 54 24 14          	mov    %edx,0x14(%esp)
f0103e0f:	72 3b                	jb     f0103e4c <__umoddi3+0x16c>
f0103e11:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0103e15:	72 31                	jb     f0103e48 <__umoddi3+0x168>
f0103e17:	8b 44 24 18          	mov    0x18(%esp),%eax
f0103e1b:	29 c8                	sub    %ecx,%eax
f0103e1d:	19 d7                	sbb    %edx,%edi
f0103e1f:	89 e9                	mov    %ebp,%ecx
f0103e21:	89 fa                	mov    %edi,%edx
f0103e23:	d3 e8                	shr    %cl,%eax
f0103e25:	89 f1                	mov    %esi,%ecx
f0103e27:	d3 e2                	shl    %cl,%edx
f0103e29:	89 e9                	mov    %ebp,%ecx
f0103e2b:	09 d0                	or     %edx,%eax
f0103e2d:	89 fa                	mov    %edi,%edx
f0103e2f:	d3 ea                	shr    %cl,%edx
f0103e31:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103e35:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103e39:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103e3d:	83 c4 2c             	add    $0x2c,%esp
f0103e40:	c3                   	ret    
f0103e41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e48:	39 d7                	cmp    %edx,%edi
f0103e4a:	75 cb                	jne    f0103e17 <__umoddi3+0x137>
f0103e4c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0103e50:	89 c1                	mov    %eax,%ecx
f0103e52:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0103e56:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0103e5a:	eb bb                	jmp    f0103e17 <__umoddi3+0x137>
f0103e5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e60:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0103e64:	0f 82 e8 fe ff ff    	jb     f0103d52 <__umoddi3+0x72>
f0103e6a:	e9 f3 fe ff ff       	jmp    f0103d62 <__umoddi3+0x82>

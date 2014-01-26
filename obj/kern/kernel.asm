
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

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
f0100046:	b8 8c 49 11 f0       	mov    $0xf011498c,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 43 11 f0 	movl   $0xf0114300,(%esp)
f0100063:	e8 b7 20 00 00       	call   f010211f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 9a 04 00 00       	call   f0100507 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 60 26 10 f0 	movl   $0xf0102660,(%esp)
f010007c:	e8 c9 14 00 00       	call   f010154a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 01 0b 00 00       	call   f0100b87 <mem_init>

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
f010009f:	83 3d 00 43 11 f0 00 	cmpl   $0x0,0xf0114300
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 00 43 11 f0    	mov    %esi,0xf0114300

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
f01000c1:	c7 04 24 7b 26 10 f0 	movl   $0xf010267b,(%esp)
f01000c8:	e8 7d 14 00 00       	call   f010154a <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 3e 14 00 00       	call   f0101517 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 57 2b 10 f0 	movl   $0xf0102b57,(%esp)
f01000e0:	e8 65 14 00 00       	call   f010154a <cprintf>
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
f010010b:	c7 04 24 93 26 10 f0 	movl   $0xf0102693,(%esp)
f0100112:	e8 33 14 00 00       	call   f010154a <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 f1 13 00 00       	call   f0101517 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 57 2b 10 f0 	movl   $0xf0102b57,(%esp)
f010012d:	e8 18 14 00 00       	call   f010154a <cprintf>
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
f0100179:	a1 44 45 11 f0       	mov    0xf0114544,%eax
f010017e:	88 90 40 43 11 f0    	mov    %dl,-0xfeebcc0(%eax)
f0100184:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f0100187:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f010018d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100192:	0f 44 d0             	cmove  %eax,%edx
f0100195:	89 15 44 45 11 f0    	mov    %edx,0xf0114544
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
f0100262:	0f b7 05 54 45 11 f0 	movzwl 0xf0114554,%eax
f0100269:	66 85 c0             	test   %ax,%ax
f010026c:	0f 84 e5 00 00 00    	je     f0100357 <cons_putc+0x1ad>
			crt_pos--;
f0100272:	83 e8 01             	sub    $0x1,%eax
f0100275:	66 a3 54 45 11 f0    	mov    %ax,0xf0114554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027b:	0f b7 c0             	movzwl %ax,%eax
f010027e:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f0100284:	83 cf 20             	or     $0x20,%edi
f0100287:	8b 15 50 45 11 f0    	mov    0xf0114550,%edx
f010028d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100291:	eb 77                	jmp    f010030a <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100293:	66 83 05 54 45 11 f0 	addw   $0x50,0xf0114554
f010029a:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010029b:	0f b7 05 54 45 11 f0 	movzwl 0xf0114554,%eax
f01002a2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a8:	c1 e8 16             	shr    $0x16,%eax
f01002ab:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ae:	c1 e0 04             	shl    $0x4,%eax
f01002b1:	66 a3 54 45 11 f0    	mov    %ax,0xf0114554
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
f01002ed:	0f b7 05 54 45 11 f0 	movzwl 0xf0114554,%eax
f01002f4:	0f b7 c8             	movzwl %ax,%ecx
f01002f7:	8b 15 50 45 11 f0    	mov    0xf0114550,%edx
f01002fd:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100301:	83 c0 01             	add    $0x1,%eax
f0100304:	66 a3 54 45 11 f0    	mov    %ax,0xf0114554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010030a:	66 81 3d 54 45 11 f0 	cmpw   $0x7cf,0xf0114554
f0100311:	cf 07 
f0100313:	76 42                	jbe    f0100357 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100315:	a1 50 45 11 f0       	mov    0xf0114550,%eax
f010031a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100321:	00 
f0100322:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100328:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032c:	89 04 24             	mov    %eax,(%esp)
f010032f:	e8 49 1e 00 00       	call   f010217d <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100334:	8b 15 50 45 11 f0    	mov    0xf0114550,%edx
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
f010034f:	66 83 2d 54 45 11 f0 	subw   $0x50,0xf0114554
f0100356:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100357:	8b 0d 4c 45 11 f0    	mov    0xf011454c,%ecx
f010035d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100362:	89 ca                	mov    %ecx,%edx
f0100364:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100365:	0f b7 1d 54 45 11 f0 	movzwl 0xf0114554,%ebx
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
f01003ab:	83 0d 48 45 11 f0 40 	orl    $0x40,0xf0114548
		return 0;
f01003b2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003b7:	e9 d0 00 00 00       	jmp    f010048c <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003bc:	84 c0                	test   %al,%al
f01003be:	79 37                	jns    f01003f7 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c0:	8b 0d 48 45 11 f0    	mov    0xf0114548,%ecx
f01003c6:	89 cb                	mov    %ecx,%ebx
f01003c8:	83 e3 40             	and    $0x40,%ebx
f01003cb:	83 e0 7f             	and    $0x7f,%eax
f01003ce:	85 db                	test   %ebx,%ebx
f01003d0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d3:	0f b6 d2             	movzbl %dl,%edx
f01003d6:	0f b6 82 e0 26 10 f0 	movzbl -0xfefd920(%edx),%eax
f01003dd:	83 c8 40             	or     $0x40,%eax
f01003e0:	0f b6 c0             	movzbl %al,%eax
f01003e3:	f7 d0                	not    %eax
f01003e5:	21 c1                	and    %eax,%ecx
f01003e7:	89 0d 48 45 11 f0    	mov    %ecx,0xf0114548
		return 0;
f01003ed:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f2:	e9 95 00 00 00       	jmp    f010048c <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f01003f7:	8b 0d 48 45 11 f0    	mov    0xf0114548,%ecx
f01003fd:	f6 c1 40             	test   $0x40,%cl
f0100400:	74 0e                	je     f0100410 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100402:	89 c2                	mov    %eax,%edx
f0100404:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100407:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040a:	89 0d 48 45 11 f0    	mov    %ecx,0xf0114548
	}

	shift |= shiftcode[data];
f0100410:	0f b6 d2             	movzbl %dl,%edx
f0100413:	0f b6 82 e0 26 10 f0 	movzbl -0xfefd920(%edx),%eax
f010041a:	0b 05 48 45 11 f0    	or     0xf0114548,%eax
	shift ^= togglecode[data];
f0100420:	0f b6 8a e0 27 10 f0 	movzbl -0xfefd820(%edx),%ecx
f0100427:	31 c8                	xor    %ecx,%eax
f0100429:	a3 48 45 11 f0       	mov    %eax,0xf0114548

	c = charcode[shift & (CTL | SHIFT)][data];
f010042e:	89 c1                	mov    %eax,%ecx
f0100430:	83 e1 03             	and    $0x3,%ecx
f0100433:	8b 0c 8d e0 28 10 f0 	mov    -0xfefd720(,%ecx,4),%ecx
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
f010046e:	c7 04 24 ad 26 10 f0 	movl   $0xf01026ad,(%esp)
f0100475:	e8 d0 10 00 00       	call   f010154a <cprintf>
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
f0100494:	83 3d 20 43 11 f0 00 	cmpl   $0x0,0xf0114320
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
f01004d2:	8b 15 40 45 11 f0    	mov    0xf0114540,%edx
f01004d8:	3b 15 44 45 11 f0    	cmp    0xf0114544,%edx
f01004de:	74 20                	je     f0100500 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01004e0:	0f b6 82 40 43 11 f0 	movzbl -0xfeebcc0(%edx),%eax
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
f01004f8:	89 15 40 45 11 f0    	mov    %edx,0xf0114540
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
f010052d:	c7 05 4c 45 11 f0 b4 	movl   $0x3b4,0xf011454c
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
f0100545:	c7 05 4c 45 11 f0 d4 	movl   $0x3d4,0xf011454c
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
f0100554:	8b 0d 4c 45 11 f0    	mov    0xf011454c,%ecx
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
f0100579:	89 3d 50 45 11 f0    	mov    %edi,0xf0114550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010057f:	0f b6 d8             	movzbl %al,%ebx
f0100582:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100584:	66 89 35 54 45 11 f0 	mov    %si,0xf0114554
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
f01005d8:	89 0d 20 43 11 f0    	mov    %ecx,0xf0114320
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
f01005e8:	c7 04 24 b9 26 10 f0 	movl   $0xf01026b9,(%esp)
f01005ef:	e8 56 0f 00 00       	call   f010154a <cprintf>
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
f0100636:	c7 04 24 f0 28 10 f0 	movl   $0xf01028f0,(%esp)
f010063d:	e8 08 0f 00 00       	call   f010154a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100642:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100649:	00 
f010064a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 d8 29 10 f0 	movl   $0xf01029d8,(%esp)
f0100659:	e8 ec 0e 00 00       	call   f010154a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010065e:	c7 44 24 08 5f 26 10 	movl   $0x10265f,0x8(%esp)
f0100665:	00 
f0100666:	c7 44 24 04 5f 26 10 	movl   $0xf010265f,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 fc 29 10 f0 	movl   $0xf01029fc,(%esp)
f0100675:	e8 d0 0e 00 00       	call   f010154a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010067a:	c7 44 24 08 00 43 11 	movl   $0x114300,0x8(%esp)
f0100681:	00 
f0100682:	c7 44 24 04 00 43 11 	movl   $0xf0114300,0x4(%esp)
f0100689:	f0 
f010068a:	c7 04 24 20 2a 10 f0 	movl   $0xf0102a20,(%esp)
f0100691:	e8 b4 0e 00 00       	call   f010154a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100696:	c7 44 24 08 8c 49 11 	movl   $0x11498c,0x8(%esp)
f010069d:	00 
f010069e:	c7 44 24 04 8c 49 11 	movl   $0xf011498c,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 44 2a 10 f0 	movl   $0xf0102a44,(%esp)
f01006ad:	e8 98 0e 00 00       	call   f010154a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006b2:	b8 8b 4d 11 f0       	mov    $0xf0114d8b,%eax
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
f01006ce:	c7 04 24 68 2a 10 f0 	movl   $0xf0102a68,(%esp)
f01006d5:	e8 70 0e 00 00       	call   f010154a <cprintf>
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
f01006e9:	bb 24 2b 10 f0       	mov    $0xf0102b24,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f01006ee:	be 48 2b 10 f0       	mov    $0xf0102b48,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006f3:	8b 03                	mov    (%ebx),%eax
f01006f5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006f9:	8b 43 fc             	mov    -0x4(%ebx),%eax
f01006fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100700:	c7 04 24 09 29 10 f0 	movl   $0xf0102909,(%esp)
f0100707:	e8 3e 0e 00 00       	call   f010154a <cprintf>
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
f0100728:	c7 04 24 12 29 10 f0 	movl   $0xf0102912,(%esp)
f010072f:	e8 16 0e 00 00       	call   f010154a <cprintf>

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
f010073a:	c7 04 24 24 29 10 f0 	movl   $0xf0102924,(%esp)
f0100741:	e8 04 0e 00 00       	call   f010154a <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f0100746:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f0100749:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010074d:	c7 04 24 2f 29 10 f0 	movl   $0xf010292f,(%esp)
f0100754:	e8 f1 0d 00 00       	call   f010154a <cprintf>
		for(i=2; i < 7; i++)
f0100759:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f010075e:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100761:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100765:	c7 04 24 29 29 10 f0 	movl   $0xf0102929,(%esp)
f010076c:	e8 d9 0d 00 00       	call   f010154a <cprintf>
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
f0100779:	c7 04 24 57 2b 10 f0 	movl   $0xf0102b57,(%esp)
f0100780:	e8 c5 0d 00 00       	call   f010154a <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f0100785:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100788:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078c:	89 3c 24             	mov    %edi,(%esp)
f010078f:	e8 b9 0e 00 00       	call   f010164d <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f0100794:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100797:	89 44 24 08          	mov    %eax,0x8(%esp)
f010079b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010079e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a2:	c7 04 24 40 29 10 f0 	movl   $0xf0102940,(%esp)
f01007a9:	e8 9c 0d 00 00       	call   f010154a <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f01007ae:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007b1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007b5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007bc:	c7 04 24 49 29 10 f0 	movl   $0xf0102949,(%esp)
f01007c3:	e8 82 0d 00 00       	call   f010154a <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f01007c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007cf:	c7 04 24 4e 29 10 f0 	movl   $0xf010294e,(%esp)
f01007d6:	e8 6f 0d 00 00       	call   f010154a <cprintf>
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
f01007fb:	c7 04 24 94 2a 10 f0 	movl   $0xf0102a94,(%esp)
f0100802:	e8 43 0d 00 00       	call   f010154a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100807:	c7 04 24 b8 2a 10 f0 	movl   $0xf0102ab8,(%esp)
f010080e:	e8 37 0d 00 00       	call   f010154a <cprintf>


	while (1) {
		buf = readline("K> ");
f0100813:	c7 04 24 53 29 10 f0 	movl   $0xf0102953,(%esp)
f010081a:	e8 51 16 00 00       	call   f0101e70 <readline>
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
f0100847:	c7 04 24 57 29 10 f0 	movl   $0xf0102957,(%esp)
f010084e:	e8 67 18 00 00       	call   f01020ba <strchr>
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
f010086a:	c7 04 24 5c 29 10 f0 	movl   $0xf010295c,(%esp)
f0100871:	e8 d4 0c 00 00       	call   f010154a <cprintf>
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
f0100899:	c7 04 24 57 29 10 f0 	movl   $0xf0102957,(%esp)
f01008a0:	e8 15 18 00 00       	call   f01020ba <strchr>
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
f01008bb:	bf 20 2b 10 f0       	mov    $0xf0102b20,%edi
f01008c0:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c5:	8b 07                	mov    (%edi),%eax
f01008c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ce:	89 04 24             	mov    %eax,(%esp)
f01008d1:	e8 60 17 00 00       	call   f0102036 <strcmp>
f01008d6:	85 c0                	test   %eax,%eax
f01008d8:	75 24                	jne    f01008fe <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008da:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01008dd:	8b 55 08             	mov    0x8(%ebp),%edx
f01008e0:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008e4:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008e7:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008eb:	89 1c 24             	mov    %ebx,(%esp)
f01008ee:	ff 14 85 28 2b 10 f0 	call   *-0xfefd4d8(,%eax,4)


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
f0100910:	c7 04 24 79 29 10 f0 	movl   $0xf0102979,(%esp)
f0100917:	e8 2e 0c 00 00       	call   f010154a <cprintf>
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
f0100933:	90                   	nop

f0100934 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100934:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100936:	83 3d 5c 45 11 f0 00 	cmpl   $0x0,0xf011455c
f010093d:	75 0f                	jne    f010094e <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010093f:	b8 8b 59 11 f0       	mov    $0xf011598b,%eax
f0100944:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100949:	a3 5c 45 11 f0       	mov    %eax,0xf011455c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f010094e:	85 d2                	test   %edx,%edx
f0100950:	75 06                	jne    f0100958 <boot_alloc+0x24>
		return nextfree;
f0100952:	a1 5c 45 11 f0       	mov    0xf011455c,%eax
f0100957:	c3                   	ret    
	result = nextfree;
f0100958:	a1 5c 45 11 f0       	mov    0xf011455c,%eax
	nextfree += (n/PGSIZE + 1)*PGSIZE;
f010095d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100963:	8d 94 10 00 10 00 00 	lea    0x1000(%eax,%edx,1),%edx
f010096a:	89 15 5c 45 11 f0    	mov    %edx,0xf011455c
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
f0100970:	8b 0d 80 49 11 f0    	mov    0xf0114980,%ecx
f0100976:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f010097c:	c1 e1 0c             	shl    $0xc,%ecx
f010097f:	39 ca                	cmp    %ecx,%edx
f0100981:	72 22                	jb     f01009a5 <boot_alloc+0x71>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	83 ec 18             	sub    $0x18,%esp
	if(n == 0)
		return nextfree;
	result = nextfree;
	nextfree += (n/PGSIZE + 1)*PGSIZE;
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
		panic("Run out of memory!!\n");
f0100989:	c7 44 24 08 44 2b 10 	movl   $0xf0102b44,0x8(%esp)
f0100990:	f0 
f0100991:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
f0100998:	00 
f0100999:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01009a0:	e8 ef f6 ff ff       	call   f0100094 <_panic>
	return result;
}
f01009a5:	f3 c3                	repz ret 

f01009a7 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01009a7:	55                   	push   %ebp
f01009a8:	89 e5                	mov    %esp,%ebp
f01009aa:	56                   	push   %esi
f01009ab:	53                   	push   %ebx
f01009ac:	83 ec 10             	sub    $0x10,%esp
f01009af:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009b1:	89 04 24             	mov    %eax,(%esp)
f01009b4:	e8 1f 0b 00 00       	call   f01014d8 <mc146818_read>
f01009b9:	89 c6                	mov    %eax,%esi
f01009bb:	83 c3 01             	add    $0x1,%ebx
f01009be:	89 1c 24             	mov    %ebx,(%esp)
f01009c1:	e8 12 0b 00 00       	call   f01014d8 <mc146818_read>
f01009c6:	c1 e0 08             	shl    $0x8,%eax
f01009c9:	09 f0                	or     %esi,%eax
}
f01009cb:	83 c4 10             	add    $0x10,%esp
f01009ce:	5b                   	pop    %ebx
f01009cf:	5e                   	pop    %esi
f01009d0:	5d                   	pop    %ebp
f01009d1:	c3                   	ret    

f01009d2 <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01009d2:	2b 05 88 49 11 f0    	sub    0xf0114988,%eax
f01009d8:	c1 f8 03             	sar    $0x3,%eax
f01009db:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009de:	89 c2                	mov    %eax,%edx
f01009e0:	c1 ea 0c             	shr    $0xc,%edx
f01009e3:	3b 15 80 49 11 f0    	cmp    0xf0114980,%edx
f01009e9:	72 26                	jb     f0100a11 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct Page *pp)
{
f01009eb:	55                   	push   %ebp
f01009ec:	89 e5                	mov    %esp,%ebp
f01009ee:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009f1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009f5:	c7 44 24 08 40 2d 10 	movl   $0xf0102d40,0x8(%esp)
f01009fc:	f0 
f01009fd:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100a04:	00 
f0100a05:	c7 04 24 65 2b 10 f0 	movl   $0xf0102b65,(%esp)
f0100a0c:	e8 83 f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100a11:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
}
f0100a16:	c3                   	ret    

f0100a17 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100a17:	55                   	push   %ebp
f0100a18:	89 e5                	mov    %esp,%ebp
f0100a1a:	56                   	push   %esi
f0100a1b:	53                   	push   %ebx
f0100a1c:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
f0100a1f:	a1 88 49 11 f0       	mov    0xf0114988,%eax
f0100a24:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100a2a:	8b 35 58 45 11 f0    	mov    0xf0114558,%esi
f0100a30:	83 fe 01             	cmp    $0x1,%esi
f0100a33:	76 37                	jbe    f0100a6c <page_init+0x55>
f0100a35:	8b 1d 60 45 11 f0    	mov    0xf0114560,%ebx
f0100a3b:	b8 01 00 00 00       	mov    $0x1,%eax
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
f0100a40:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
		pages[i].pp_ref = 0;
f0100a47:	8b 0d 88 49 11 f0    	mov    0xf0114988,%ecx
f0100a4d:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100a54:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0100a57:	8b 1d 88 49 11 f0    	mov    0xf0114988,%ebx
f0100a5d:	01 d3                	add    %edx,%ebx
	pages[0].pp_ref = 1;
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100a5f:	83 c0 01             	add    $0x1,%eax
f0100a62:	39 f0                	cmp    %esi,%eax
f0100a64:	72 da                	jb     f0100a40 <page_init+0x29>
f0100a66:	89 1d 60 45 11 f0    	mov    %ebx,0xf0114560
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	size_t page_num = PADDR(boot_alloc(0)) / PGSIZE;
f0100a6c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a71:	e8 be fe ff ff       	call   f0100934 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100a76:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100a7b:	77 20                	ja     f0100a9d <page_init+0x86>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100a7d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a81:	c7 44 24 08 64 2d 10 	movl   $0xf0102d64,0x8(%esp)
f0100a88:	f0 
f0100a89:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
f0100a90:	00 
f0100a91:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100a98:	e8 f7 f5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100a9d:	05 00 00 00 10       	add    $0x10000000,%eax
f0100aa2:	c1 e8 0c             	shr    $0xc,%eax
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100aa5:	3b 05 80 49 11 f0    	cmp    0xf0114980,%eax
f0100aab:	73 39                	jae    f0100ae6 <page_init+0xcf>
f0100aad:	8b 1d 60 45 11 f0    	mov    0xf0114560,%ebx
f0100ab3:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100aba:	8b 0d 88 49 11 f0    	mov    0xf0114988,%ecx
f0100ac0:	01 d1                	add    %edx,%ecx
f0100ac2:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ac8:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100aca:	8b 1d 88 49 11 f0    	mov    0xf0114988,%ebx
f0100ad0:	01 d3                	add    %edx,%ebx
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100ad2:	83 c0 01             	add    $0x1,%eax
f0100ad5:	83 c2 08             	add    $0x8,%edx
f0100ad8:	39 05 80 49 11 f0    	cmp    %eax,0xf0114980
f0100ade:	77 da                	ja     f0100aba <page_init+0xa3>
f0100ae0:	89 1d 60 45 11 f0    	mov    %ebx,0xf0114560
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
//	panic("here");
	
}
f0100ae6:	83 c4 10             	add    $0x10,%esp
f0100ae9:	5b                   	pop    %ebx
f0100aea:	5e                   	pop    %esi
f0100aeb:	5d                   	pop    %ebp
f0100aec:	c3                   	ret    

f0100aed <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100aed:	55                   	push   %ebp
f0100aee:	89 e5                	mov    %esp,%ebp
f0100af0:	53                   	push   %ebx
f0100af1:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(!page_free_list)
f0100af4:	8b 1d 60 45 11 f0    	mov    0xf0114560,%ebx
f0100afa:	85 db                	test   %ebx,%ebx
f0100afc:	74 65                	je     f0100b63 <page_alloc+0x76>
		return NULL;
	struct Page *alloc_page = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100afe:	8b 03                	mov    (%ebx),%eax
f0100b00:	a3 60 45 11 f0       	mov    %eax,0xf0114560
	if(alloc_flags & ALLOC_ZERO)
f0100b05:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100b09:	74 58                	je     f0100b63 <page_alloc+0x76>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b0b:	89 d8                	mov    %ebx,%eax
f0100b0d:	2b 05 88 49 11 f0    	sub    0xf0114988,%eax
f0100b13:	c1 f8 03             	sar    $0x3,%eax
f0100b16:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b19:	89 c2                	mov    %eax,%edx
f0100b1b:	c1 ea 0c             	shr    $0xc,%edx
f0100b1e:	3b 15 80 49 11 f0    	cmp    0xf0114980,%edx
f0100b24:	72 20                	jb     f0100b46 <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b26:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b2a:	c7 44 24 08 40 2d 10 	movl   $0xf0102d40,0x8(%esp)
f0100b31:	f0 
f0100b32:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b39:	00 
f0100b3a:	c7 04 24 65 2b 10 f0 	movl   $0xf0102b65,(%esp)
f0100b41:	e8 4e f5 ff ff       	call   f0100094 <_panic>
		memset(page2kva(alloc_page), 0, PGSIZE);
f0100b46:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100b4d:	00 
f0100b4e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100b55:	00 
	return (void *)(pa + KERNBASE);
f0100b56:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b5b:	89 04 24             	mov    %eax,(%esp)
f0100b5e:	e8 bc 15 00 00       	call   f010211f <memset>
	
	return alloc_page;
}
f0100b63:	89 d8                	mov    %ebx,%eax
f0100b65:	83 c4 14             	add    $0x14,%esp
f0100b68:	5b                   	pop    %ebx
f0100b69:	5d                   	pop    %ebp
f0100b6a:	c3                   	ret    

f0100b6b <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100b6b:	55                   	push   %ebp
f0100b6c:	89 e5                	mov    %esp,%ebp
f0100b6e:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if(pp -> pp_ref)	// If the ref is not 0, return
f0100b71:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100b76:	75 0d                	jne    f0100b85 <page_free+0x1a>
		return;
	pp->pp_link = page_free_list;
f0100b78:	8b 15 60 45 11 f0    	mov    0xf0114560,%edx
f0100b7e:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100b80:	a3 60 45 11 f0       	mov    %eax,0xf0114560
}
f0100b85:	5d                   	pop    %ebp
f0100b86:	c3                   	ret    

f0100b87 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100b87:	55                   	push   %ebp
f0100b88:	89 e5                	mov    %esp,%ebp
f0100b8a:	57                   	push   %edi
f0100b8b:	56                   	push   %esi
f0100b8c:	53                   	push   %ebx
f0100b8d:	83 ec 4c             	sub    $0x4c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100b90:	b8 15 00 00 00       	mov    $0x15,%eax
f0100b95:	e8 0d fe ff ff       	call   f01009a7 <nvram_read>
f0100b9a:	c1 e0 0a             	shl    $0xa,%eax
f0100b9d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100ba3:	85 c0                	test   %eax,%eax
f0100ba5:	0f 48 c2             	cmovs  %edx,%eax
f0100ba8:	c1 f8 0c             	sar    $0xc,%eax
f0100bab:	a3 58 45 11 f0       	mov    %eax,0xf0114558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100bb0:	b8 17 00 00 00       	mov    $0x17,%eax
f0100bb5:	e8 ed fd ff ff       	call   f01009a7 <nvram_read>
f0100bba:	c1 e0 0a             	shl    $0xa,%eax
f0100bbd:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100bc3:	85 c0                	test   %eax,%eax
f0100bc5:	0f 48 c2             	cmovs  %edx,%eax
f0100bc8:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100bcb:	85 c0                	test   %eax,%eax
f0100bcd:	74 0e                	je     f0100bdd <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100bcf:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100bd5:	89 15 80 49 11 f0    	mov    %edx,0xf0114980
f0100bdb:	eb 0c                	jmp    f0100be9 <mem_init+0x62>
	else
		npages = npages_basemem;
f0100bdd:	8b 15 58 45 11 f0    	mov    0xf0114558,%edx
f0100be3:	89 15 80 49 11 f0    	mov    %edx,0xf0114980

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0100be9:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100bec:	c1 e8 0a             	shr    $0xa,%eax
f0100bef:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100bf3:	a1 58 45 11 f0       	mov    0xf0114558,%eax
f0100bf8:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100bfb:	c1 e8 0a             	shr    $0xa,%eax
f0100bfe:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0100c02:	a1 80 49 11 f0       	mov    0xf0114980,%eax
f0100c07:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100c0a:	c1 e8 0a             	shr    $0xa,%eax
f0100c0d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c11:	c7 04 24 88 2d 10 f0 	movl   $0xf0102d88,(%esp)
f0100c18:	e8 2d 09 00 00       	call   f010154a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100c1d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100c22:	e8 0d fd ff ff       	call   f0100934 <boot_alloc>
f0100c27:	a3 84 49 11 f0       	mov    %eax,0xf0114984
	memset(kern_pgdir, 0, PGSIZE);
f0100c2c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100c33:	00 
f0100c34:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100c3b:	00 
f0100c3c:	89 04 24             	mov    %eax,(%esp)
f0100c3f:	e8 db 14 00 00       	call   f010211f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100c44:	a1 84 49 11 f0       	mov    0xf0114984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c49:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100c4e:	77 20                	ja     f0100c70 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c50:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c54:	c7 44 24 08 64 2d 10 	movl   $0xf0102d64,0x8(%esp)
f0100c5b:	f0 
f0100c5c:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
f0100c63:	00 
f0100c64:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100c6b:	e8 24 f4 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100c70:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100c76:	83 ca 05             	or     $0x5,%edx
f0100c79:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page *)boot_alloc(npages * sizeof(struct Page));
f0100c7f:	a1 80 49 11 f0       	mov    0xf0114980,%eax
f0100c84:	c1 e0 03             	shl    $0x3,%eax
f0100c87:	e8 a8 fc ff ff       	call   f0100934 <boot_alloc>
f0100c8c:	a3 88 49 11 f0       	mov    %eax,0xf0114988
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100c91:	e8 81 fd ff ff       	call   f0100a17 <page_init>
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c96:	a1 60 45 11 f0       	mov    0xf0114560,%eax
f0100c9b:	85 c0                	test   %eax,%eax
f0100c9d:	75 1c                	jne    f0100cbb <mem_init+0x134>
		panic("'page_free_list' is a null pointer!");
f0100c9f:	c7 44 24 08 c4 2d 10 	movl   $0xf0102dc4,0x8(%esp)
f0100ca6:	f0 
f0100ca7:	c7 44 24 04 de 01 00 	movl   $0x1de,0x4(%esp)
f0100cae:	00 
f0100caf:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100cb6:	e8 d9 f3 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100cbb:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100cbe:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100cc1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100cc4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100cc7:	89 c2                	mov    %eax,%edx
f0100cc9:	2b 15 88 49 11 f0    	sub    0xf0114988,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ccf:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100cd5:	0f 95 c2             	setne  %dl
f0100cd8:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100cdb:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100cdf:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ce1:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ce5:	8b 00                	mov    (%eax),%eax
f0100ce7:	85 c0                	test   %eax,%eax
f0100ce9:	75 dc                	jne    f0100cc7 <mem_init+0x140>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ceb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100cf4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cf7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cfa:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100cfc:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100cff:	89 1d 60 45 11 f0    	mov    %ebx,0xf0114560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d05:	85 db                	test   %ebx,%ebx
f0100d07:	74 68                	je     f0100d71 <mem_init+0x1ea>
f0100d09:	89 d8                	mov    %ebx,%eax
f0100d0b:	2b 05 88 49 11 f0    	sub    0xf0114988,%eax
f0100d11:	c1 f8 03             	sar    $0x3,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d14:	89 c2                	mov    %eax,%edx
f0100d16:	c1 e2 0c             	shl    $0xc,%edx
f0100d19:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0100d1e:	75 4b                	jne    f0100d6b <mem_init+0x1e4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d20:	89 d0                	mov    %edx,%eax
f0100d22:	c1 e8 0c             	shr    $0xc,%eax
f0100d25:	3b 05 80 49 11 f0    	cmp    0xf0114980,%eax
f0100d2b:	72 20                	jb     f0100d4d <mem_init+0x1c6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d2d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d31:	c7 44 24 08 40 2d 10 	movl   $0xf0102d40,0x8(%esp)
f0100d38:	f0 
f0100d39:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d40:	00 
f0100d41:	c7 04 24 65 2b 10 f0 	movl   $0xf0102b65,(%esp)
f0100d48:	e8 47 f3 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100d4d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100d54:	00 
f0100d55:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d5c:	00 
	return (void *)(pa + KERNBASE);
f0100d5d:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100d63:	89 14 24             	mov    %edx,(%esp)
f0100d66:	e8 b4 13 00 00       	call   f010211f <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d6b:	8b 1b                	mov    (%ebx),%ebx
f0100d6d:	85 db                	test   %ebx,%ebx
f0100d6f:	75 98                	jne    f0100d09 <mem_init+0x182>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100d71:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d76:	e8 b9 fb ff ff       	call   f0100934 <boot_alloc>
f0100d7b:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d7e:	a1 60 45 11 f0       	mov    0xf0114560,%eax
f0100d83:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100d86:	85 c0                	test   %eax,%eax
f0100d88:	0f 84 fc 01 00 00    	je     f0100f8a <mem_init+0x403>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d8e:	8b 1d 88 49 11 f0    	mov    0xf0114988,%ebx
f0100d94:	39 d8                	cmp    %ebx,%eax
f0100d96:	72 53                	jb     f0100deb <mem_init+0x264>
		assert(pp < pages + npages);
f0100d98:	8b 0d 80 49 11 f0    	mov    0xf0114980,%ecx
f0100d9e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100da1:	8d 04 cb             	lea    (%ebx,%ecx,8),%eax
f0100da4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100da7:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100daa:	73 68                	jae    f0100e14 <mem_init+0x28d>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dac:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100daf:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100db2:	29 d8                	sub    %ebx,%eax
f0100db4:	a8 07                	test   $0x7,%al
f0100db6:	0f 85 85 00 00 00    	jne    f0100e41 <mem_init+0x2ba>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dbc:	c1 f8 03             	sar    $0x3,%eax
f0100dbf:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100dc2:	85 c0                	test   %eax,%eax
f0100dc4:	0f 84 a5 00 00 00    	je     f0100e6f <mem_init+0x2e8>
		assert(page2pa(pp) != IOPHYSMEM);
f0100dca:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100dcf:	0f 84 c5 00 00 00    	je     f0100e9a <mem_init+0x313>
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dd5:	8b 55 c4             	mov    -0x3c(%ebp),%edx
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100dd8:	be 00 00 00 00       	mov    $0x0,%esi
f0100ddd:	bf 00 00 00 00       	mov    $0x0,%edi
f0100de2:	e9 d7 00 00 00       	jmp    f0100ebe <mem_init+0x337>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100de7:	39 da                	cmp    %ebx,%edx
f0100de9:	73 24                	jae    f0100e0f <mem_init+0x288>
f0100deb:	c7 44 24 0c 73 2b 10 	movl   $0xf0102b73,0xc(%esp)
f0100df2:	f0 
f0100df3:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100dfa:	f0 
f0100dfb:	c7 44 24 04 f8 01 00 	movl   $0x1f8,0x4(%esp)
f0100e02:	00 
f0100e03:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100e0a:	e8 85 f2 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100e0f:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100e12:	72 24                	jb     f0100e38 <mem_init+0x2b1>
f0100e14:	c7 44 24 0c 94 2b 10 	movl   $0xf0102b94,0xc(%esp)
f0100e1b:	f0 
f0100e1c:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100e23:	f0 
f0100e24:	c7 44 24 04 f9 01 00 	movl   $0x1f9,0x4(%esp)
f0100e2b:	00 
f0100e2c:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100e33:	e8 5c f2 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e38:	89 d0                	mov    %edx,%eax
f0100e3a:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100e3d:	a8 07                	test   $0x7,%al
f0100e3f:	74 24                	je     f0100e65 <mem_init+0x2de>
f0100e41:	c7 44 24 0c e8 2d 10 	movl   $0xf0102de8,0xc(%esp)
f0100e48:	f0 
f0100e49:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100e50:	f0 
f0100e51:	c7 44 24 04 fa 01 00 	movl   $0x1fa,0x4(%esp)
f0100e58:	00 
f0100e59:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100e60:	e8 2f f2 ff ff       	call   f0100094 <_panic>
f0100e65:	c1 f8 03             	sar    $0x3,%eax
f0100e68:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100e6b:	85 c0                	test   %eax,%eax
f0100e6d:	75 24                	jne    f0100e93 <mem_init+0x30c>
f0100e6f:	c7 44 24 0c a8 2b 10 	movl   $0xf0102ba8,0xc(%esp)
f0100e76:	f0 
f0100e77:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100e7e:	f0 
f0100e7f:	c7 44 24 04 fd 01 00 	movl   $0x1fd,0x4(%esp)
f0100e86:	00 
f0100e87:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100e8e:	e8 01 f2 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e93:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e98:	75 24                	jne    f0100ebe <mem_init+0x337>
f0100e9a:	c7 44 24 0c b9 2b 10 	movl   $0xf0102bb9,0xc(%esp)
f0100ea1:	f0 
f0100ea2:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100ea9:	f0 
f0100eaa:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
f0100eb1:	00 
f0100eb2:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100eb9:	e8 d6 f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ebe:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ec3:	75 24                	jne    f0100ee9 <mem_init+0x362>
f0100ec5:	c7 44 24 0c 1c 2e 10 	movl   $0xf0102e1c,0xc(%esp)
f0100ecc:	f0 
f0100ecd:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100ed4:	f0 
f0100ed5:	c7 44 24 04 ff 01 00 	movl   $0x1ff,0x4(%esp)
f0100edc:	00 
f0100edd:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100ee4:	e8 ab f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ee9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100eee:	75 24                	jne    f0100f14 <mem_init+0x38d>
f0100ef0:	c7 44 24 0c d2 2b 10 	movl   $0xf0102bd2,0xc(%esp)
f0100ef7:	f0 
f0100ef8:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100eff:	f0 
f0100f00:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
f0100f07:	00 
f0100f08:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100f0f:	e8 80 f1 ff ff       	call   f0100094 <_panic>
f0100f14:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f16:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f1b:	76 57                	jbe    f0100f74 <mem_init+0x3ed>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f1d:	c1 e8 0c             	shr    $0xc,%eax
f0100f20:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100f23:	77 20                	ja     f0100f45 <mem_init+0x3be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f25:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100f29:	c7 44 24 08 40 2d 10 	movl   $0xf0102d40,0x8(%esp)
f0100f30:	f0 
f0100f31:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f38:	00 
f0100f39:	c7 04 24 65 2b 10 f0 	movl   $0xf0102b65,(%esp)
f0100f40:	e8 4f f1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100f45:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100f4b:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100f4e:	76 29                	jbe    f0100f79 <mem_init+0x3f2>
f0100f50:	c7 44 24 0c 40 2e 10 	movl   $0xf0102e40,0xc(%esp)
f0100f57:	f0 
f0100f58:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100f5f:	f0 
f0100f60:	c7 44 24 04 01 02 00 	movl   $0x201,0x4(%esp)
f0100f67:	00 
f0100f68:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100f6f:	e8 20 f1 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100f74:	83 c7 01             	add    $0x1,%edi
f0100f77:	eb 03                	jmp    f0100f7c <mem_init+0x3f5>
		else
			++nfree_extmem;
f0100f79:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f7c:	8b 12                	mov    (%edx),%edx
f0100f7e:	85 d2                	test   %edx,%edx
f0100f80:	0f 85 61 fe ff ff    	jne    f0100de7 <mem_init+0x260>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100f86:	85 ff                	test   %edi,%edi
f0100f88:	7f 24                	jg     f0100fae <mem_init+0x427>
f0100f8a:	c7 44 24 0c ec 2b 10 	movl   $0xf0102bec,0xc(%esp)
f0100f91:	f0 
f0100f92:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100f99:	f0 
f0100f9a:	c7 44 24 04 09 02 00 	movl   $0x209,0x4(%esp)
f0100fa1:	00 
f0100fa2:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100fa9:	e8 e6 f0 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100fae:	85 f6                	test   %esi,%esi
f0100fb0:	7f 24                	jg     f0100fd6 <mem_init+0x44f>
f0100fb2:	c7 44 24 0c fe 2b 10 	movl   $0xf0102bfe,0xc(%esp)
f0100fb9:	f0 
f0100fba:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0100fc1:	f0 
f0100fc2:	c7 44 24 04 0a 02 00 	movl   $0x20a,0x4(%esp)
f0100fc9:	00 
f0100fca:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100fd1:	e8 be f0 ff ff       	call   f0100094 <_panic>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0100fd6:	85 db                	test   %ebx,%ebx
f0100fd8:	75 1c                	jne    f0100ff6 <mem_init+0x46f>
		panic("'pages' is a null pointer!");
f0100fda:	c7 44 24 08 0f 2c 10 	movl   $0xf0102c0f,0x8(%esp)
f0100fe1:	f0 
f0100fe2:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
f0100fe9:	00 
f0100fea:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0100ff1:	e8 9e f0 ff ff       	call   f0100094 <_panic>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0100ff6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ffb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
		++nfree;
f0100ffe:	83 c3 01             	add    $0x1,%ebx
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101001:	8b 00                	mov    (%eax),%eax
f0101003:	85 c0                	test   %eax,%eax
f0101005:	75 f7                	jne    f0100ffe <mem_init+0x477>
		++nfree;
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101007:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010100e:	e8 da fa ff ff       	call   f0100aed <page_alloc>
f0101013:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101016:	85 c0                	test   %eax,%eax
f0101018:	75 24                	jne    f010103e <mem_init+0x4b7>
f010101a:	c7 44 24 0c 2a 2c 10 	movl   $0xf0102c2a,0xc(%esp)
f0101021:	f0 
f0101022:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0101029:	f0 
f010102a:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
f0101031:	00 
f0101032:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0101039:	e8 56 f0 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010103e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101045:	e8 a3 fa ff ff       	call   f0100aed <page_alloc>
f010104a:	89 c7                	mov    %eax,%edi
f010104c:	85 c0                	test   %eax,%eax
f010104e:	75 24                	jne    f0101074 <mem_init+0x4ed>
f0101050:	c7 44 24 0c 40 2c 10 	movl   $0xf0102c40,0xc(%esp)
f0101057:	f0 
f0101058:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f010105f:	f0 
f0101060:	c7 44 24 04 22 02 00 	movl   $0x222,0x4(%esp)
f0101067:	00 
f0101068:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f010106f:	e8 20 f0 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101074:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010107b:	e8 6d fa ff ff       	call   f0100aed <page_alloc>
f0101080:	89 c6                	mov    %eax,%esi
f0101082:	85 c0                	test   %eax,%eax
f0101084:	75 24                	jne    f01010aa <mem_init+0x523>
f0101086:	c7 44 24 0c 56 2c 10 	movl   $0xf0102c56,0xc(%esp)
f010108d:	f0 
f010108e:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0101095:	f0 
f0101096:	c7 44 24 04 23 02 00 	movl   $0x223,0x4(%esp)
f010109d:	00 
f010109e:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01010a5:	e8 ea ef ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01010aa:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f01010ad:	75 24                	jne    f01010d3 <mem_init+0x54c>
f01010af:	c7 44 24 0c 6c 2c 10 	movl   $0xf0102c6c,0xc(%esp)
f01010b6:	f0 
f01010b7:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f01010be:	f0 
f01010bf:	c7 44 24 04 26 02 00 	movl   $0x226,0x4(%esp)
f01010c6:	00 
f01010c7:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01010ce:	e8 c1 ef ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01010d3:	39 c7                	cmp    %eax,%edi
f01010d5:	74 05                	je     f01010dc <mem_init+0x555>
f01010d7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01010da:	75 24                	jne    f0101100 <mem_init+0x579>
f01010dc:	c7 44 24 0c 88 2e 10 	movl   $0xf0102e88,0xc(%esp)
f01010e3:	f0 
f01010e4:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f01010eb:	f0 
f01010ec:	c7 44 24 04 27 02 00 	movl   $0x227,0x4(%esp)
f01010f3:	00 
f01010f4:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01010fb:	e8 94 ef ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101100:	8b 15 88 49 11 f0    	mov    0xf0114988,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101106:	a1 80 49 11 f0       	mov    0xf0114980,%eax
f010110b:	c1 e0 0c             	shl    $0xc,%eax
f010110e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101111:	29 d1                	sub    %edx,%ecx
f0101113:	c1 f9 03             	sar    $0x3,%ecx
f0101116:	c1 e1 0c             	shl    $0xc,%ecx
f0101119:	39 c1                	cmp    %eax,%ecx
f010111b:	72 24                	jb     f0101141 <mem_init+0x5ba>
f010111d:	c7 44 24 0c 7e 2c 10 	movl   $0xf0102c7e,0xc(%esp)
f0101124:	f0 
f0101125:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f010112c:	f0 
f010112d:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
f0101134:	00 
f0101135:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f010113c:	e8 53 ef ff ff       	call   f0100094 <_panic>
f0101141:	89 f9                	mov    %edi,%ecx
f0101143:	29 d1                	sub    %edx,%ecx
f0101145:	c1 f9 03             	sar    $0x3,%ecx
f0101148:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010114b:	39 c8                	cmp    %ecx,%eax
f010114d:	77 24                	ja     f0101173 <mem_init+0x5ec>
f010114f:	c7 44 24 0c 9b 2c 10 	movl   $0xf0102c9b,0xc(%esp)
f0101156:	f0 
f0101157:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f010115e:	f0 
f010115f:	c7 44 24 04 29 02 00 	movl   $0x229,0x4(%esp)
f0101166:	00 
f0101167:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f010116e:	e8 21 ef ff ff       	call   f0100094 <_panic>
f0101173:	89 f1                	mov    %esi,%ecx
f0101175:	29 d1                	sub    %edx,%ecx
f0101177:	89 ca                	mov    %ecx,%edx
f0101179:	c1 fa 03             	sar    $0x3,%edx
f010117c:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010117f:	39 d0                	cmp    %edx,%eax
f0101181:	77 24                	ja     f01011a7 <mem_init+0x620>
f0101183:	c7 44 24 0c b8 2c 10 	movl   $0xf0102cb8,0xc(%esp)
f010118a:	f0 
f010118b:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0101192:	f0 
f0101193:	c7 44 24 04 2a 02 00 	movl   $0x22a,0x4(%esp)
f010119a:	00 
f010119b:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01011a2:	e8 ed ee ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01011a7:	a1 60 45 11 f0       	mov    0xf0114560,%eax
f01011ac:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01011af:	c7 05 60 45 11 f0 00 	movl   $0x0,0xf0114560
f01011b6:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01011b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01011c0:	e8 28 f9 ff ff       	call   f0100aed <page_alloc>
f01011c5:	85 c0                	test   %eax,%eax
f01011c7:	74 24                	je     f01011ed <mem_init+0x666>
f01011c9:	c7 44 24 0c d5 2c 10 	movl   $0xf0102cd5,0xc(%esp)
f01011d0:	f0 
f01011d1:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f01011d8:	f0 
f01011d9:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
f01011e0:	00 
f01011e1:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01011e8:	e8 a7 ee ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01011ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011f0:	89 04 24             	mov    %eax,(%esp)
f01011f3:	e8 73 f9 ff ff       	call   f0100b6b <page_free>
	page_free(pp1);
f01011f8:	89 3c 24             	mov    %edi,(%esp)
f01011fb:	e8 6b f9 ff ff       	call   f0100b6b <page_free>
	page_free(pp2);
f0101200:	89 34 24             	mov    %esi,(%esp)
f0101203:	e8 63 f9 ff ff       	call   f0100b6b <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101208:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010120f:	e8 d9 f8 ff ff       	call   f0100aed <page_alloc>
f0101214:	89 c6                	mov    %eax,%esi
f0101216:	85 c0                	test   %eax,%eax
f0101218:	75 24                	jne    f010123e <mem_init+0x6b7>
f010121a:	c7 44 24 0c 2a 2c 10 	movl   $0xf0102c2a,0xc(%esp)
f0101221:	f0 
f0101222:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0101229:	f0 
f010122a:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0101231:	00 
f0101232:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0101239:	e8 56 ee ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010123e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101245:	e8 a3 f8 ff ff       	call   f0100aed <page_alloc>
f010124a:	89 c7                	mov    %eax,%edi
f010124c:	85 c0                	test   %eax,%eax
f010124e:	75 24                	jne    f0101274 <mem_init+0x6ed>
f0101250:	c7 44 24 0c 40 2c 10 	movl   $0xf0102c40,0xc(%esp)
f0101257:	f0 
f0101258:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f010125f:	f0 
f0101260:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0101267:	00 
f0101268:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f010126f:	e8 20 ee ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101274:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010127b:	e8 6d f8 ff ff       	call   f0100aed <page_alloc>
f0101280:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101283:	85 c0                	test   %eax,%eax
f0101285:	75 24                	jne    f01012ab <mem_init+0x724>
f0101287:	c7 44 24 0c 56 2c 10 	movl   $0xf0102c56,0xc(%esp)
f010128e:	f0 
f010128f:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0101296:	f0 
f0101297:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f010129e:	00 
f010129f:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01012a6:	e8 e9 ed ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012ab:	39 fe                	cmp    %edi,%esi
f01012ad:	75 24                	jne    f01012d3 <mem_init+0x74c>
f01012af:	c7 44 24 0c 6c 2c 10 	movl   $0xf0102c6c,0xc(%esp)
f01012b6:	f0 
f01012b7:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f01012be:	f0 
f01012bf:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
f01012c6:	00 
f01012c7:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01012ce:	e8 c1 ed ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012d3:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01012d6:	74 05                	je     f01012dd <mem_init+0x756>
f01012d8:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01012db:	75 24                	jne    f0101301 <mem_init+0x77a>
f01012dd:	c7 44 24 0c 88 2e 10 	movl   $0xf0102e88,0xc(%esp)
f01012e4:	f0 
f01012e5:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f01012ec:	f0 
f01012ed:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
f01012f4:	00 
f01012f5:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01012fc:	e8 93 ed ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101301:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101308:	e8 e0 f7 ff ff       	call   f0100aed <page_alloc>
f010130d:	85 c0                	test   %eax,%eax
f010130f:	74 24                	je     f0101335 <mem_init+0x7ae>
f0101311:	c7 44 24 0c d5 2c 10 	movl   $0xf0102cd5,0xc(%esp)
f0101318:	f0 
f0101319:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0101320:	f0 
f0101321:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
f0101328:	00 
f0101329:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0101330:	e8 5f ed ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101335:	89 f0                	mov    %esi,%eax
f0101337:	e8 96 f6 ff ff       	call   f01009d2 <page2kva>
f010133c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101343:	00 
f0101344:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010134b:	00 
f010134c:	89 04 24             	mov    %eax,(%esp)
f010134f:	e8 cb 0d 00 00       	call   f010211f <memset>
	page_free(pp0);
f0101354:	89 34 24             	mov    %esi,(%esp)
f0101357:	e8 0f f8 ff ff       	call   f0100b6b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010135c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101363:	e8 85 f7 ff ff       	call   f0100aed <page_alloc>
f0101368:	85 c0                	test   %eax,%eax
f010136a:	75 24                	jne    f0101390 <mem_init+0x809>
f010136c:	c7 44 24 0c e4 2c 10 	movl   $0xf0102ce4,0xc(%esp)
f0101373:	f0 
f0101374:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f010137b:	f0 
f010137c:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f0101383:	00 
f0101384:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f010138b:	e8 04 ed ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101390:	39 c6                	cmp    %eax,%esi
f0101392:	74 24                	je     f01013b8 <mem_init+0x831>
f0101394:	c7 44 24 0c 02 2d 10 	movl   $0xf0102d02,0xc(%esp)
f010139b:	f0 
f010139c:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f01013a3:	f0 
f01013a4:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f01013ab:	00 
f01013ac:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01013b3:	e8 dc ec ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
f01013b8:	89 f0                	mov    %esi,%eax
f01013ba:	e8 13 f6 ff ff       	call   f01009d2 <page2kva>
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01013bf:	80 38 00             	cmpb   $0x0,(%eax)
f01013c2:	75 0b                	jne    f01013cf <mem_init+0x848>
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01013c4:	ba 01 00 00 00       	mov    $0x1,%edx
		assert(c[i] == 0);
f01013c9:	80 3c 10 00          	cmpb   $0x0,(%eax,%edx,1)
f01013cd:	74 24                	je     f01013f3 <mem_init+0x86c>
f01013cf:	c7 44 24 0c 12 2d 10 	movl   $0xf0102d12,0xc(%esp)
f01013d6:	f0 
f01013d7:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f01013de:	f0 
f01013df:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
f01013e6:	00 
f01013e7:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f01013ee:	e8 a1 ec ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01013f3:	83 c2 01             	add    $0x1,%edx
f01013f6:	81 fa 00 10 00 00    	cmp    $0x1000,%edx
f01013fc:	75 cb                	jne    f01013c9 <mem_init+0x842>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01013fe:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101401:	89 0d 60 45 11 f0    	mov    %ecx,0xf0114560

	// free the pages we took
	page_free(pp0);
f0101407:	89 34 24             	mov    %esi,(%esp)
f010140a:	e8 5c f7 ff ff       	call   f0100b6b <page_free>
	page_free(pp1);
f010140f:	89 3c 24             	mov    %edi,(%esp)
f0101412:	e8 54 f7 ff ff       	call   f0100b6b <page_free>
	page_free(pp2);
f0101417:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010141a:	89 04 24             	mov    %eax,(%esp)
f010141d:	e8 49 f7 ff ff       	call   f0100b6b <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101422:	a1 60 45 11 f0       	mov    0xf0114560,%eax
f0101427:	85 c0                	test   %eax,%eax
f0101429:	74 09                	je     f0101434 <mem_init+0x8ad>
		--nfree;
f010142b:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010142e:	8b 00                	mov    (%eax),%eax
f0101430:	85 c0                	test   %eax,%eax
f0101432:	75 f7                	jne    f010142b <mem_init+0x8a4>
		--nfree;
	assert(nfree == 0);
f0101434:	85 db                	test   %ebx,%ebx
f0101436:	74 24                	je     f010145c <mem_init+0x8d5>
f0101438:	c7 44 24 0c 1c 2d 10 	movl   $0xf0102d1c,0xc(%esp)
f010143f:	f0 
f0101440:	c7 44 24 08 7f 2b 10 	movl   $0xf0102b7f,0x8(%esp)
f0101447:	f0 
f0101448:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f010144f:	00 
f0101450:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f0101457:	e8 38 ec ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010145c:	c7 04 24 a8 2e 10 f0 	movl   $0xf0102ea8,(%esp)
f0101463:	e8 e2 00 00 00       	call   f010154a <cprintf>
	// or page_insert
	page_init();

	check_page_free_list(1);
	check_page_alloc();
panic("Lab2-Part1 complete!\n");
f0101468:	c7 44 24 08 27 2d 10 	movl   $0xf0102d27,0x8(%esp)
f010146f:	f0 
f0101470:	c7 44 24 04 a8 00 00 	movl   $0xa8,0x4(%esp)
f0101477:	00 
f0101478:	c7 04 24 59 2b 10 f0 	movl   $0xf0102b59,(%esp)
f010147f:	e8 10 ec ff ff       	call   f0100094 <_panic>

f0101484 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0101484:	55                   	push   %ebp
f0101485:	89 e5                	mov    %esp,%ebp
f0101487:	83 ec 04             	sub    $0x4,%esp
f010148a:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010148d:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0101491:	83 ea 01             	sub    $0x1,%edx
f0101494:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101498:	66 85 d2             	test   %dx,%dx
f010149b:	75 08                	jne    f01014a5 <page_decref+0x21>
		page_free(pp);
f010149d:	89 04 24             	mov    %eax,(%esp)
f01014a0:	e8 c6 f6 ff ff       	call   f0100b6b <page_free>
}
f01014a5:	c9                   	leave  
f01014a6:	c3                   	ret    

f01014a7 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01014a7:	55                   	push   %ebp
f01014a8:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01014aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01014af:	5d                   	pop    %ebp
f01014b0:	c3                   	ret    

f01014b1 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01014b1:	55                   	push   %ebp
f01014b2:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01014b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01014b9:	5d                   	pop    %ebp
f01014ba:	c3                   	ret    

f01014bb <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01014bb:	55                   	push   %ebp
f01014bc:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01014be:	b8 00 00 00 00       	mov    $0x0,%eax
f01014c3:	5d                   	pop    %ebp
f01014c4:	c3                   	ret    

f01014c5 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01014c5:	55                   	push   %ebp
f01014c6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01014c8:	5d                   	pop    %ebp
f01014c9:	c3                   	ret    

f01014ca <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01014ca:	55                   	push   %ebp
f01014cb:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01014cd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014d0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01014d3:	5d                   	pop    %ebp
f01014d4:	c3                   	ret    
f01014d5:	66 90                	xchg   %ax,%ax
f01014d7:	90                   	nop

f01014d8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01014d8:	55                   	push   %ebp
f01014d9:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01014db:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014df:	ba 70 00 00 00       	mov    $0x70,%edx
f01014e4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01014e5:	b2 71                	mov    $0x71,%dl
f01014e7:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01014e8:	0f b6 c0             	movzbl %al,%eax
}
f01014eb:	5d                   	pop    %ebp
f01014ec:	c3                   	ret    

f01014ed <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01014ed:	55                   	push   %ebp
f01014ee:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01014f0:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014f4:	ba 70 00 00 00       	mov    $0x70,%edx
f01014f9:	ee                   	out    %al,(%dx)
f01014fa:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f01014fe:	b2 71                	mov    $0x71,%dl
f0101500:	ee                   	out    %al,(%dx)
f0101501:	5d                   	pop    %ebp
f0101502:	c3                   	ret    
f0101503:	90                   	nop

f0101504 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101504:	55                   	push   %ebp
f0101505:	89 e5                	mov    %esp,%ebp
f0101507:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010150a:	8b 45 08             	mov    0x8(%ebp),%eax
f010150d:	89 04 24             	mov    %eax,(%esp)
f0101510:	e8 e7 f0 ff ff       	call   f01005fc <cputchar>
	*cnt++;
}
f0101515:	c9                   	leave  
f0101516:	c3                   	ret    

f0101517 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101517:	55                   	push   %ebp
f0101518:	89 e5                	mov    %esp,%ebp
f010151a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010151d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101524:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101527:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010152b:	8b 45 08             	mov    0x8(%ebp),%eax
f010152e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101532:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101535:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101539:	c7 04 24 04 15 10 f0 	movl   $0xf0101504,(%esp)
f0101540:	e8 9d 04 00 00       	call   f01019e2 <vprintfmt>
	return cnt;
}
f0101545:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101548:	c9                   	leave  
f0101549:	c3                   	ret    

f010154a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010154a:	55                   	push   %ebp
f010154b:	89 e5                	mov    %esp,%ebp
f010154d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101550:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101553:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101557:	8b 45 08             	mov    0x8(%ebp),%eax
f010155a:	89 04 24             	mov    %eax,(%esp)
f010155d:	e8 b5 ff ff ff       	call   f0101517 <vcprintf>
	va_end(ap);

	return cnt;
}
f0101562:	c9                   	leave  
f0101563:	c3                   	ret    
f0101564:	66 90                	xchg   %ax,%ax
f0101566:	66 90                	xchg   %ax,%ax
f0101568:	66 90                	xchg   %ax,%ax
f010156a:	66 90                	xchg   %ax,%ax
f010156c:	66 90                	xchg   %ax,%ax
f010156e:	66 90                	xchg   %ax,%ax

f0101570 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101570:	55                   	push   %ebp
f0101571:	89 e5                	mov    %esp,%ebp
f0101573:	57                   	push   %edi
f0101574:	56                   	push   %esi
f0101575:	53                   	push   %ebx
f0101576:	83 ec 10             	sub    $0x10,%esp
f0101579:	89 c6                	mov    %eax,%esi
f010157b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010157e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101581:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101584:	8b 1a                	mov    (%edx),%ebx
f0101586:	8b 09                	mov    (%ecx),%ecx
f0101588:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010158b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0101592:	eb 77                	jmp    f010160b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0101594:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101597:	01 d8                	add    %ebx,%eax
f0101599:	b9 02 00 00 00       	mov    $0x2,%ecx
f010159e:	99                   	cltd   
f010159f:	f7 f9                	idiv   %ecx
f01015a1:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01015a3:	eb 01                	jmp    f01015a6 <stab_binsearch+0x36>
			m--;
f01015a5:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01015a6:	39 d9                	cmp    %ebx,%ecx
f01015a8:	7c 1d                	jl     f01015c7 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01015aa:	6b d1 0c             	imul   $0xc,%ecx,%edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01015ad:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01015b2:	39 fa                	cmp    %edi,%edx
f01015b4:	75 ef                	jne    f01015a5 <stab_binsearch+0x35>
f01015b6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01015b9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01015bc:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f01015c0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01015c3:	73 18                	jae    f01015dd <stab_binsearch+0x6d>
f01015c5:	eb 05                	jmp    f01015cc <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01015c7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01015ca:	eb 3f                	jmp    f010160b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01015cc:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01015cf:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f01015d1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015d4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01015db:	eb 2e                	jmp    f010160b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01015dd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01015e0:	73 15                	jae    f01015f7 <stab_binsearch+0x87>
			*region_right = m - 1;
f01015e2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01015e5:	49                   	dec    %ecx
f01015e6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01015e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015ec:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015ee:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01015f5:	eb 14                	jmp    f010160b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01015f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01015fa:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01015fd:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f01015ff:	ff 45 0c             	incl   0xc(%ebp)
f0101602:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101604:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f010160b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010160e:	7e 84                	jle    f0101594 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101610:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0101614:	75 0d                	jne    f0101623 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0101616:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101619:	8b 02                	mov    (%edx),%eax
f010161b:	48                   	dec    %eax
f010161c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010161f:	89 01                	mov    %eax,(%ecx)
f0101621:	eb 22                	jmp    f0101645 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101623:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101626:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101628:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010162b:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010162d:	eb 01                	jmp    f0101630 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010162f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101630:	39 c1                	cmp    %eax,%ecx
f0101632:	7d 0c                	jge    f0101640 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0101634:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0101637:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010163c:	39 fa                	cmp    %edi,%edx
f010163e:	75 ef                	jne    f010162f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101640:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101643:	89 02                	mov    %eax,(%edx)
	}
}
f0101645:	83 c4 10             	add    $0x10,%esp
f0101648:	5b                   	pop    %ebx
f0101649:	5e                   	pop    %esi
f010164a:	5f                   	pop    %edi
f010164b:	5d                   	pop    %ebp
f010164c:	c3                   	ret    

f010164d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010164d:	55                   	push   %ebp
f010164e:	89 e5                	mov    %esp,%ebp
f0101650:	83 ec 38             	sub    $0x38,%esp
f0101653:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101656:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101659:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010165c:	8b 75 08             	mov    0x8(%ebp),%esi
f010165f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101662:	c7 03 c8 2e 10 f0    	movl   $0xf0102ec8,(%ebx)
	info->eip_line = 0;
f0101668:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010166f:	c7 43 08 c8 2e 10 f0 	movl   $0xf0102ec8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101676:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010167d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101680:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101687:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010168d:	76 12                	jbe    f01016a1 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010168f:	b8 35 9a 10 f0       	mov    $0xf0109a35,%eax
f0101694:	3d ad 7d 10 f0       	cmp    $0xf0107dad,%eax
f0101699:	0f 86 99 01 00 00    	jbe    f0101838 <debuginfo_eip+0x1eb>
f010169f:	eb 1c                	jmp    f01016bd <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01016a1:	c7 44 24 08 d2 2e 10 	movl   $0xf0102ed2,0x8(%esp)
f01016a8:	f0 
f01016a9:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01016b0:	00 
f01016b1:	c7 04 24 df 2e 10 f0 	movl   $0xf0102edf,(%esp)
f01016b8:	e8 d7 e9 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01016bd:	80 3d 34 9a 10 f0 00 	cmpb   $0x0,0xf0109a34
f01016c4:	0f 85 75 01 00 00    	jne    f010183f <debuginfo_eip+0x1f2>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01016ca:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01016d1:	b8 ac 7d 10 f0       	mov    $0xf0107dac,%eax
f01016d6:	2d fc 30 10 f0       	sub    $0xf01030fc,%eax
f01016db:	c1 f8 02             	sar    $0x2,%eax
f01016de:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01016e4:	83 e8 01             	sub    $0x1,%eax
f01016e7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01016ea:	89 74 24 04          	mov    %esi,0x4(%esp)
f01016ee:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01016f5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01016f8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01016fb:	b8 fc 30 10 f0       	mov    $0xf01030fc,%eax
f0101700:	e8 6b fe ff ff       	call   f0101570 <stab_binsearch>
	if (lfile == 0)
f0101705:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101708:	85 c0                	test   %eax,%eax
f010170a:	0f 84 36 01 00 00    	je     f0101846 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101710:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101713:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101716:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101719:	89 74 24 04          	mov    %esi,0x4(%esp)
f010171d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0101724:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101727:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010172a:	b8 fc 30 10 f0       	mov    $0xf01030fc,%eax
f010172f:	e8 3c fe ff ff       	call   f0101570 <stab_binsearch>

	if (lfun <= rfun) {
f0101734:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101737:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f010173a:	7f 2e                	jg     f010176a <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010173c:	6b c7 0c             	imul   $0xc,%edi,%eax
f010173f:	8d 90 fc 30 10 f0    	lea    -0xfefcf04(%eax),%edx
f0101745:	8b 80 fc 30 10 f0    	mov    -0xfefcf04(%eax),%eax
f010174b:	b9 35 9a 10 f0       	mov    $0xf0109a35,%ecx
f0101750:	81 e9 ad 7d 10 f0    	sub    $0xf0107dad,%ecx
f0101756:	39 c8                	cmp    %ecx,%eax
f0101758:	73 08                	jae    f0101762 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010175a:	05 ad 7d 10 f0       	add    $0xf0107dad,%eax
f010175f:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101762:	8b 42 08             	mov    0x8(%edx),%eax
f0101765:	89 43 10             	mov    %eax,0x10(%ebx)
f0101768:	eb 06                	jmp    f0101770 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010176a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010176d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101770:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0101777:	00 
f0101778:	8b 43 08             	mov    0x8(%ebx),%eax
f010177b:	89 04 24             	mov    %eax,(%esp)
f010177e:	e8 6d 09 00 00       	call   f01020f0 <strfind>
f0101783:	2b 43 08             	sub    0x8(%ebx),%eax
f0101786:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101789:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010178c:	39 cf                	cmp    %ecx,%edi
f010178e:	7c 62                	jl     f01017f2 <debuginfo_eip+0x1a5>
	       && stabs[lline].n_type != N_SOL
f0101790:	6b f7 0c             	imul   $0xc,%edi,%esi
f0101793:	81 c6 fc 30 10 f0    	add    $0xf01030fc,%esi
f0101799:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f010179d:	80 fa 84             	cmp    $0x84,%dl
f01017a0:	74 31                	je     f01017d3 <debuginfo_eip+0x186>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01017a2:	8d 47 ff             	lea    -0x1(%edi),%eax
f01017a5:	6b c0 0c             	imul   $0xc,%eax,%eax
f01017a8:	05 fc 30 10 f0       	add    $0xf01030fc,%eax
f01017ad:	eb 15                	jmp    f01017c4 <debuginfo_eip+0x177>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01017af:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01017b2:	39 cf                	cmp    %ecx,%edi
f01017b4:	7c 3c                	jl     f01017f2 <debuginfo_eip+0x1a5>
	       && stabs[lline].n_type != N_SOL
f01017b6:	89 c6                	mov    %eax,%esi
f01017b8:	83 e8 0c             	sub    $0xc,%eax
f01017bb:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f01017bf:	80 fa 84             	cmp    $0x84,%dl
f01017c2:	74 0f                	je     f01017d3 <debuginfo_eip+0x186>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01017c4:	80 fa 64             	cmp    $0x64,%dl
f01017c7:	75 e6                	jne    f01017af <debuginfo_eip+0x162>
f01017c9:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f01017cd:	74 e0                	je     f01017af <debuginfo_eip+0x162>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01017cf:	39 f9                	cmp    %edi,%ecx
f01017d1:	7f 1f                	jg     f01017f2 <debuginfo_eip+0x1a5>
f01017d3:	6b ff 0c             	imul   $0xc,%edi,%edi
f01017d6:	8b 87 fc 30 10 f0    	mov    -0xfefcf04(%edi),%eax
f01017dc:	ba 35 9a 10 f0       	mov    $0xf0109a35,%edx
f01017e1:	81 ea ad 7d 10 f0    	sub    $0xf0107dad,%edx
f01017e7:	39 d0                	cmp    %edx,%eax
f01017e9:	73 07                	jae    f01017f2 <debuginfo_eip+0x1a5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01017eb:	05 ad 7d 10 f0       	add    $0xf0107dad,%eax
f01017f0:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01017f2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01017f5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f01017f8:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01017fd:	39 ca                	cmp    %ecx,%edx
f01017ff:	7d 5f                	jge    f0101860 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f0101801:	8d 42 01             	lea    0x1(%edx),%eax
f0101804:	39 c1                	cmp    %eax,%ecx
f0101806:	7e 45                	jle    f010184d <debuginfo_eip+0x200>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101808:	6b f0 0c             	imul   $0xc,%eax,%esi
f010180b:	80 be 00 31 10 f0 a0 	cmpb   $0xa0,-0xfefcf00(%esi)
f0101812:	75 40                	jne    f0101854 <debuginfo_eip+0x207>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0101814:	6b d2 0c             	imul   $0xc,%edx,%edx
f0101817:	81 c2 fc 30 10 f0    	add    $0xf01030fc,%edx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010181d:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0101821:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101824:	39 c1                	cmp    %eax,%ecx
f0101826:	7e 33                	jle    f010185b <debuginfo_eip+0x20e>
f0101828:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010182b:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f010182f:	74 ec                	je     f010181d <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0101831:	b8 00 00 00 00       	mov    $0x0,%eax
f0101836:	eb 28                	jmp    f0101860 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101838:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010183d:	eb 21                	jmp    f0101860 <debuginfo_eip+0x213>
f010183f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101844:	eb 1a                	jmp    f0101860 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101846:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010184b:	eb 13                	jmp    f0101860 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010184d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101852:	eb 0c                	jmp    f0101860 <debuginfo_eip+0x213>
f0101854:	b8 00 00 00 00       	mov    $0x0,%eax
f0101859:	eb 05                	jmp    f0101860 <debuginfo_eip+0x213>
f010185b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101860:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101863:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101866:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101869:	89 ec                	mov    %ebp,%esp
f010186b:	5d                   	pop    %ebp
f010186c:	c3                   	ret    
f010186d:	66 90                	xchg   %ax,%ax
f010186f:	90                   	nop

f0101870 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101870:	55                   	push   %ebp
f0101871:	89 e5                	mov    %esp,%ebp
f0101873:	57                   	push   %edi
f0101874:	56                   	push   %esi
f0101875:	53                   	push   %ebx
f0101876:	83 ec 4c             	sub    $0x4c,%esp
f0101879:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010187c:	89 d7                	mov    %edx,%edi
f010187e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101881:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101884:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101887:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010188a:	b8 00 00 00 00       	mov    $0x0,%eax
f010188f:	39 d8                	cmp    %ebx,%eax
f0101891:	72 17                	jb     f01018aa <printnum+0x3a>
f0101893:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101896:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0101899:	76 0f                	jbe    f01018aa <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010189b:	8b 75 14             	mov    0x14(%ebp),%esi
f010189e:	83 ee 01             	sub    $0x1,%esi
f01018a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018a4:	85 f6                	test   %esi,%esi
f01018a6:	7f 63                	jg     f010190b <printnum+0x9b>
f01018a8:	eb 75                	jmp    f010191f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01018aa:	8b 5d 18             	mov    0x18(%ebp),%ebx
f01018ad:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f01018b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01018b4:	83 e8 01             	sub    $0x1,%eax
f01018b7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018bb:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01018be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018c2:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018c6:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01018cd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01018d0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01018d7:	00 
f01018d8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01018db:	89 1c 24             	mov    %ebx,(%esp)
f01018de:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01018e1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01018e5:	e8 96 0a 00 00       	call   f0102380 <__udivdi3>
f01018ea:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01018ed:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01018f0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018f4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01018f8:	89 04 24             	mov    %eax,(%esp)
f01018fb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01018ff:	89 fa                	mov    %edi,%edx
f0101901:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101904:	e8 67 ff ff ff       	call   f0101870 <printnum>
f0101909:	eb 14                	jmp    f010191f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010190b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010190f:	8b 45 18             	mov    0x18(%ebp),%eax
f0101912:	89 04 24             	mov    %eax,(%esp)
f0101915:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101917:	83 ee 01             	sub    $0x1,%esi
f010191a:	75 ef                	jne    f010190b <printnum+0x9b>
f010191c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010191f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101923:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101927:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010192a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010192e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101935:	00 
f0101936:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101939:	89 1c 24             	mov    %ebx,(%esp)
f010193c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010193f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101943:	e8 88 0b 00 00       	call   f01024d0 <__umoddi3>
f0101948:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010194c:	0f be 80 ed 2e 10 f0 	movsbl -0xfefd113(%eax),%eax
f0101953:	89 04 24             	mov    %eax,(%esp)
f0101956:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101959:	ff d0                	call   *%eax
}
f010195b:	83 c4 4c             	add    $0x4c,%esp
f010195e:	5b                   	pop    %ebx
f010195f:	5e                   	pop    %esi
f0101960:	5f                   	pop    %edi
f0101961:	5d                   	pop    %ebp
f0101962:	c3                   	ret    

f0101963 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101963:	55                   	push   %ebp
f0101964:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101966:	83 fa 01             	cmp    $0x1,%edx
f0101969:	7e 0e                	jle    f0101979 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010196b:	8b 10                	mov    (%eax),%edx
f010196d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101970:	89 08                	mov    %ecx,(%eax)
f0101972:	8b 02                	mov    (%edx),%eax
f0101974:	8b 52 04             	mov    0x4(%edx),%edx
f0101977:	eb 22                	jmp    f010199b <getuint+0x38>
	else if (lflag)
f0101979:	85 d2                	test   %edx,%edx
f010197b:	74 10                	je     f010198d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010197d:	8b 10                	mov    (%eax),%edx
f010197f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101982:	89 08                	mov    %ecx,(%eax)
f0101984:	8b 02                	mov    (%edx),%eax
f0101986:	ba 00 00 00 00       	mov    $0x0,%edx
f010198b:	eb 0e                	jmp    f010199b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010198d:	8b 10                	mov    (%eax),%edx
f010198f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101992:	89 08                	mov    %ecx,(%eax)
f0101994:	8b 02                	mov    (%edx),%eax
f0101996:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010199b:	5d                   	pop    %ebp
f010199c:	c3                   	ret    

f010199d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010199d:	55                   	push   %ebp
f010199e:	89 e5                	mov    %esp,%ebp
f01019a0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01019a3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01019a7:	8b 10                	mov    (%eax),%edx
f01019a9:	3b 50 04             	cmp    0x4(%eax),%edx
f01019ac:	73 0a                	jae    f01019b8 <sprintputch+0x1b>
		*b->buf++ = ch;
f01019ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01019b1:	88 0a                	mov    %cl,(%edx)
f01019b3:	83 c2 01             	add    $0x1,%edx
f01019b6:	89 10                	mov    %edx,(%eax)
}
f01019b8:	5d                   	pop    %ebp
f01019b9:	c3                   	ret    

f01019ba <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01019ba:	55                   	push   %ebp
f01019bb:	89 e5                	mov    %esp,%ebp
f01019bd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01019c0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01019c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01019c7:	8b 45 10             	mov    0x10(%ebp),%eax
f01019ca:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019ce:	8b 45 0c             	mov    0xc(%ebp),%eax
f01019d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01019d8:	89 04 24             	mov    %eax,(%esp)
f01019db:	e8 02 00 00 00       	call   f01019e2 <vprintfmt>
	va_end(ap);
}
f01019e0:	c9                   	leave  
f01019e1:	c3                   	ret    

f01019e2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01019e2:	55                   	push   %ebp
f01019e3:	89 e5                	mov    %esp,%ebp
f01019e5:	57                   	push   %edi
f01019e6:	56                   	push   %esi
f01019e7:	53                   	push   %ebx
f01019e8:	83 ec 4c             	sub    $0x4c,%esp
f01019eb:	8b 75 08             	mov    0x8(%ebp),%esi
f01019ee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01019f1:	8b 7d 10             	mov    0x10(%ebp),%edi
f01019f4:	eb 11                	jmp    f0101a07 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01019f6:	85 c0                	test   %eax,%eax
f01019f8:	0f 84 db 03 00 00    	je     f0101dd9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f01019fe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a02:	89 04 24             	mov    %eax,(%esp)
f0101a05:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101a07:	0f b6 07             	movzbl (%edi),%eax
f0101a0a:	83 c7 01             	add    $0x1,%edi
f0101a0d:	83 f8 25             	cmp    $0x25,%eax
f0101a10:	75 e4                	jne    f01019f6 <vprintfmt+0x14>
f0101a12:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0101a16:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0101a1d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0101a24:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0101a2b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a30:	eb 2b                	jmp    f0101a5d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a32:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101a35:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0101a39:	eb 22                	jmp    f0101a5d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a3b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101a3e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0101a42:	eb 19                	jmp    f0101a5d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a44:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0101a47:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101a4e:	eb 0d                	jmp    f0101a5d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0101a50:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101a53:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101a56:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a5d:	0f b6 0f             	movzbl (%edi),%ecx
f0101a60:	8d 47 01             	lea    0x1(%edi),%eax
f0101a63:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101a66:	0f b6 07             	movzbl (%edi),%eax
f0101a69:	83 e8 23             	sub    $0x23,%eax
f0101a6c:	3c 55                	cmp    $0x55,%al
f0101a6e:	0f 87 40 03 00 00    	ja     f0101db4 <vprintfmt+0x3d2>
f0101a74:	0f b6 c0             	movzbl %al,%eax
f0101a77:	ff 24 85 78 2f 10 f0 	jmp    *-0xfefd088(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101a7e:	83 e9 30             	sub    $0x30,%ecx
f0101a81:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f0101a84:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0101a88:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0101a8b:	83 f9 09             	cmp    $0x9,%ecx
f0101a8e:	77 57                	ja     f0101ae7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a90:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101a93:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101a96:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101a99:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101a9c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0101a9f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0101aa3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0101aa6:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0101aa9:	83 f9 09             	cmp    $0x9,%ecx
f0101aac:	76 eb                	jbe    f0101a99 <vprintfmt+0xb7>
f0101aae:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101ab1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101ab4:	eb 34                	jmp    f0101aea <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101ab6:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ab9:	8d 48 04             	lea    0x4(%eax),%ecx
f0101abc:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101abf:	8b 00                	mov    (%eax),%eax
f0101ac1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ac4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101ac7:	eb 21                	jmp    f0101aea <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0101ac9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101acd:	0f 88 71 ff ff ff    	js     f0101a44 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ad3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101ad6:	eb 85                	jmp    f0101a5d <vprintfmt+0x7b>
f0101ad8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101adb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0101ae2:	e9 76 ff ff ff       	jmp    f0101a5d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ae7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0101aea:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101aee:	0f 89 69 ff ff ff    	jns    f0101a5d <vprintfmt+0x7b>
f0101af4:	e9 57 ff ff ff       	jmp    f0101a50 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101af9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101afc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101aff:	e9 59 ff ff ff       	jmp    f0101a5d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101b04:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b07:	8d 50 04             	lea    0x4(%eax),%edx
f0101b0a:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b0d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b11:	8b 00                	mov    (%eax),%eax
f0101b13:	89 04 24             	mov    %eax,(%esp)
f0101b16:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b18:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101b1b:	e9 e7 fe ff ff       	jmp    f0101a07 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101b20:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b23:	8d 50 04             	lea    0x4(%eax),%edx
f0101b26:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b29:	8b 00                	mov    (%eax),%eax
f0101b2b:	89 c2                	mov    %eax,%edx
f0101b2d:	c1 fa 1f             	sar    $0x1f,%edx
f0101b30:	31 d0                	xor    %edx,%eax
f0101b32:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101b34:	83 f8 06             	cmp    $0x6,%eax
f0101b37:	7f 0b                	jg     f0101b44 <vprintfmt+0x162>
f0101b39:	8b 14 85 d0 30 10 f0 	mov    -0xfefcf30(,%eax,4),%edx
f0101b40:	85 d2                	test   %edx,%edx
f0101b42:	75 20                	jne    f0101b64 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0101b44:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b48:	c7 44 24 08 05 2f 10 	movl   $0xf0102f05,0x8(%esp)
f0101b4f:	f0 
f0101b50:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b54:	89 34 24             	mov    %esi,(%esp)
f0101b57:	e8 5e fe ff ff       	call   f01019ba <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b5c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101b5f:	e9 a3 fe ff ff       	jmp    f0101a07 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0101b64:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b68:	c7 44 24 08 91 2b 10 	movl   $0xf0102b91,0x8(%esp)
f0101b6f:	f0 
f0101b70:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b74:	89 34 24             	mov    %esi,(%esp)
f0101b77:	e8 3e fe ff ff       	call   f01019ba <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b7c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101b7f:	e9 83 fe ff ff       	jmp    f0101a07 <vprintfmt+0x25>
f0101b84:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101b87:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101b8a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101b8d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b90:	8d 50 04             	lea    0x4(%eax),%edx
f0101b93:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b96:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101b98:	85 ff                	test   %edi,%edi
f0101b9a:	b8 fe 2e 10 f0       	mov    $0xf0102efe,%eax
f0101b9f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101ba2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0101ba6:	74 06                	je     f0101bae <vprintfmt+0x1cc>
f0101ba8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0101bac:	7f 16                	jg     f0101bc4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101bae:	0f b6 17             	movzbl (%edi),%edx
f0101bb1:	0f be c2             	movsbl %dl,%eax
f0101bb4:	83 c7 01             	add    $0x1,%edi
f0101bb7:	85 c0                	test   %eax,%eax
f0101bb9:	0f 85 9f 00 00 00    	jne    f0101c5e <vprintfmt+0x27c>
f0101bbf:	e9 8b 00 00 00       	jmp    f0101c4f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101bc4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101bc8:	89 3c 24             	mov    %edi,(%esp)
f0101bcb:	e8 92 03 00 00       	call   f0101f62 <strnlen>
f0101bd0:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101bd3:	29 c2                	sub    %eax,%edx
f0101bd5:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0101bd8:	85 d2                	test   %edx,%edx
f0101bda:	7e d2                	jle    f0101bae <vprintfmt+0x1cc>
					putch(padc, putdat);
f0101bdc:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0101be0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101be3:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0101be6:	89 d7                	mov    %edx,%edi
f0101be8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101bec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101bef:	89 04 24             	mov    %eax,(%esp)
f0101bf2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101bf4:	83 ef 01             	sub    $0x1,%edi
f0101bf7:	75 ef                	jne    f0101be8 <vprintfmt+0x206>
f0101bf9:	89 7d d8             	mov    %edi,-0x28(%ebp)
f0101bfc:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101bff:	eb ad                	jmp    f0101bae <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101c01:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101c05:	74 20                	je     f0101c27 <vprintfmt+0x245>
f0101c07:	0f be d2             	movsbl %dl,%edx
f0101c0a:	83 ea 20             	sub    $0x20,%edx
f0101c0d:	83 fa 5e             	cmp    $0x5e,%edx
f0101c10:	76 15                	jbe    f0101c27 <vprintfmt+0x245>
					putch('?', putdat);
f0101c12:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101c15:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101c19:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101c20:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c23:	ff d1                	call   *%ecx
f0101c25:	eb 0f                	jmp    f0101c36 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0101c27:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101c2a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101c2e:	89 04 24             	mov    %eax,(%esp)
f0101c31:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c34:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101c36:	83 eb 01             	sub    $0x1,%ebx
f0101c39:	0f b6 17             	movzbl (%edi),%edx
f0101c3c:	0f be c2             	movsbl %dl,%eax
f0101c3f:	83 c7 01             	add    $0x1,%edi
f0101c42:	85 c0                	test   %eax,%eax
f0101c44:	75 24                	jne    f0101c6a <vprintfmt+0x288>
f0101c46:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101c49:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101c4c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101c4f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101c52:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101c56:	0f 8e ab fd ff ff    	jle    f0101a07 <vprintfmt+0x25>
f0101c5c:	eb 20                	jmp    f0101c7e <vprintfmt+0x29c>
f0101c5e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101c61:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101c64:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101c67:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101c6a:	85 f6                	test   %esi,%esi
f0101c6c:	78 93                	js     f0101c01 <vprintfmt+0x21f>
f0101c6e:	83 ee 01             	sub    $0x1,%esi
f0101c71:	79 8e                	jns    f0101c01 <vprintfmt+0x21f>
f0101c73:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101c76:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101c79:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101c7c:	eb d1                	jmp    f0101c4f <vprintfmt+0x26d>
f0101c7e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101c81:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101c85:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101c8c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101c8e:	83 ef 01             	sub    $0x1,%edi
f0101c91:	75 ee                	jne    f0101c81 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101c93:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101c96:	e9 6c fd ff ff       	jmp    f0101a07 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101c9b:	83 fa 01             	cmp    $0x1,%edx
f0101c9e:	66 90                	xchg   %ax,%ax
f0101ca0:	7e 16                	jle    f0101cb8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f0101ca2:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ca5:	8d 50 08             	lea    0x8(%eax),%edx
f0101ca8:	89 55 14             	mov    %edx,0x14(%ebp)
f0101cab:	8b 10                	mov    (%eax),%edx
f0101cad:	8b 48 04             	mov    0x4(%eax),%ecx
f0101cb0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101cb3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101cb6:	eb 32                	jmp    f0101cea <vprintfmt+0x308>
	else if (lflag)
f0101cb8:	85 d2                	test   %edx,%edx
f0101cba:	74 18                	je     f0101cd4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f0101cbc:	8b 45 14             	mov    0x14(%ebp),%eax
f0101cbf:	8d 50 04             	lea    0x4(%eax),%edx
f0101cc2:	89 55 14             	mov    %edx,0x14(%ebp)
f0101cc5:	8b 00                	mov    (%eax),%eax
f0101cc7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101cca:	89 c1                	mov    %eax,%ecx
f0101ccc:	c1 f9 1f             	sar    $0x1f,%ecx
f0101ccf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101cd2:	eb 16                	jmp    f0101cea <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f0101cd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0101cd7:	8d 50 04             	lea    0x4(%eax),%edx
f0101cda:	89 55 14             	mov    %edx,0x14(%ebp)
f0101cdd:	8b 00                	mov    (%eax),%eax
f0101cdf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ce2:	89 c7                	mov    %eax,%edi
f0101ce4:	c1 ff 1f             	sar    $0x1f,%edi
f0101ce7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101cea:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ced:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101cf0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101cf5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101cf9:	79 7d                	jns    f0101d78 <vprintfmt+0x396>
				putch('-', putdat);
f0101cfb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101cff:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101d06:	ff d6                	call   *%esi
				num = -(long long) num;
f0101d08:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d0b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101d0e:	f7 d8                	neg    %eax
f0101d10:	83 d2 00             	adc    $0x0,%edx
f0101d13:	f7 da                	neg    %edx
			}
			base = 10;
f0101d15:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101d1a:	eb 5c                	jmp    f0101d78 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101d1c:	8d 45 14             	lea    0x14(%ebp),%eax
f0101d1f:	e8 3f fc ff ff       	call   f0101963 <getuint>
			base = 10;
f0101d24:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101d29:	eb 4d                	jmp    f0101d78 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101d2b:	8d 45 14             	lea    0x14(%ebp),%eax
f0101d2e:	e8 30 fc ff ff       	call   f0101963 <getuint>
			base = 8;
f0101d33:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101d38:	eb 3e                	jmp    f0101d78 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
f0101d3a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d3e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101d45:	ff d6                	call   *%esi
			putch('x', putdat);
f0101d47:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d4b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101d52:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101d54:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d57:	8d 50 04             	lea    0x4(%eax),%edx
f0101d5a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101d5d:	8b 00                	mov    (%eax),%eax
f0101d5f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101d64:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101d69:	eb 0d                	jmp    f0101d78 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101d6b:	8d 45 14             	lea    0x14(%ebp),%eax
f0101d6e:	e8 f0 fb ff ff       	call   f0101963 <getuint>
			base = 16;
f0101d73:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101d78:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f0101d7c:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0101d80:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101d83:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101d87:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101d8b:	89 04 24             	mov    %eax,(%esp)
f0101d8e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101d92:	89 da                	mov    %ebx,%edx
f0101d94:	89 f0                	mov    %esi,%eax
f0101d96:	e8 d5 fa ff ff       	call   f0101870 <printnum>
			break;
f0101d9b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101d9e:	e9 64 fc ff ff       	jmp    f0101a07 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101da3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101da7:	89 0c 24             	mov    %ecx,(%esp)
f0101daa:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101dac:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101daf:	e9 53 fc ff ff       	jmp    f0101a07 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101db4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101db8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101dbf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101dc1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101dc5:	0f 84 3c fc ff ff    	je     f0101a07 <vprintfmt+0x25>
f0101dcb:	83 ef 01             	sub    $0x1,%edi
f0101dce:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101dd2:	75 f7                	jne    f0101dcb <vprintfmt+0x3e9>
f0101dd4:	e9 2e fc ff ff       	jmp    f0101a07 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0101dd9:	83 c4 4c             	add    $0x4c,%esp
f0101ddc:	5b                   	pop    %ebx
f0101ddd:	5e                   	pop    %esi
f0101dde:	5f                   	pop    %edi
f0101ddf:	5d                   	pop    %ebp
f0101de0:	c3                   	ret    

f0101de1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101de1:	55                   	push   %ebp
f0101de2:	89 e5                	mov    %esp,%ebp
f0101de4:	83 ec 28             	sub    $0x28,%esp
f0101de7:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dea:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101ded:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101df0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101df4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101df7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101dfe:	85 d2                	test   %edx,%edx
f0101e00:	7e 30                	jle    f0101e32 <vsnprintf+0x51>
f0101e02:	85 c0                	test   %eax,%eax
f0101e04:	74 2c                	je     f0101e32 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101e06:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e09:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e0d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101e10:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101e14:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101e17:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e1b:	c7 04 24 9d 19 10 f0 	movl   $0xf010199d,(%esp)
f0101e22:	e8 bb fb ff ff       	call   f01019e2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101e27:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101e2a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101e2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101e30:	eb 05                	jmp    f0101e37 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101e32:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101e37:	c9                   	leave  
f0101e38:	c3                   	ret    

f0101e39 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101e39:	55                   	push   %ebp
f0101e3a:	89 e5                	mov    %esp,%ebp
f0101e3c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101e3f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101e42:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e46:	8b 45 10             	mov    0x10(%ebp),%eax
f0101e49:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101e4d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101e50:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e54:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e57:	89 04 24             	mov    %eax,(%esp)
f0101e5a:	e8 82 ff ff ff       	call   f0101de1 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101e5f:	c9                   	leave  
f0101e60:	c3                   	ret    
f0101e61:	66 90                	xchg   %ax,%ax
f0101e63:	66 90                	xchg   %ax,%ax
f0101e65:	66 90                	xchg   %ax,%ax
f0101e67:	66 90                	xchg   %ax,%ax
f0101e69:	66 90                	xchg   %ax,%ax
f0101e6b:	66 90                	xchg   %ax,%ax
f0101e6d:	66 90                	xchg   %ax,%ax
f0101e6f:	90                   	nop

f0101e70 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101e70:	55                   	push   %ebp
f0101e71:	89 e5                	mov    %esp,%ebp
f0101e73:	57                   	push   %edi
f0101e74:	56                   	push   %esi
f0101e75:	53                   	push   %ebx
f0101e76:	83 ec 1c             	sub    $0x1c,%esp
f0101e79:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101e7c:	85 c0                	test   %eax,%eax
f0101e7e:	74 10                	je     f0101e90 <readline+0x20>
		cprintf("%s", prompt);
f0101e80:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e84:	c7 04 24 91 2b 10 f0 	movl   $0xf0102b91,(%esp)
f0101e8b:	e8 ba f6 ff ff       	call   f010154a <cprintf>

	i = 0;
	echoing = iscons(0);
f0101e90:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e97:	e8 81 e7 ff ff       	call   f010061d <iscons>
f0101e9c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101e9e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101ea3:	e8 64 e7 ff ff       	call   f010060c <getchar>
f0101ea8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101eaa:	85 c0                	test   %eax,%eax
f0101eac:	79 17                	jns    f0101ec5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0101eae:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101eb2:	c7 04 24 ec 30 10 f0 	movl   $0xf01030ec,(%esp)
f0101eb9:	e8 8c f6 ff ff       	call   f010154a <cprintf>
			return NULL;
f0101ebe:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ec3:	eb 6d                	jmp    f0101f32 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101ec5:	83 f8 7f             	cmp    $0x7f,%eax
f0101ec8:	74 05                	je     f0101ecf <readline+0x5f>
f0101eca:	83 f8 08             	cmp    $0x8,%eax
f0101ecd:	75 19                	jne    f0101ee8 <readline+0x78>
f0101ecf:	85 f6                	test   %esi,%esi
f0101ed1:	7e 15                	jle    f0101ee8 <readline+0x78>
			if (echoing)
f0101ed3:	85 ff                	test   %edi,%edi
f0101ed5:	74 0c                	je     f0101ee3 <readline+0x73>
				cputchar('\b');
f0101ed7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0101ede:	e8 19 e7 ff ff       	call   f01005fc <cputchar>
			i--;
f0101ee3:	83 ee 01             	sub    $0x1,%esi
f0101ee6:	eb bb                	jmp    f0101ea3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101ee8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101eee:	7f 1c                	jg     f0101f0c <readline+0x9c>
f0101ef0:	83 fb 1f             	cmp    $0x1f,%ebx
f0101ef3:	7e 17                	jle    f0101f0c <readline+0x9c>
			if (echoing)
f0101ef5:	85 ff                	test   %edi,%edi
f0101ef7:	74 08                	je     f0101f01 <readline+0x91>
				cputchar(c);
f0101ef9:	89 1c 24             	mov    %ebx,(%esp)
f0101efc:	e8 fb e6 ff ff       	call   f01005fc <cputchar>
			buf[i++] = c;
f0101f01:	88 9e 80 45 11 f0    	mov    %bl,-0xfeeba80(%esi)
f0101f07:	83 c6 01             	add    $0x1,%esi
f0101f0a:	eb 97                	jmp    f0101ea3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101f0c:	83 fb 0d             	cmp    $0xd,%ebx
f0101f0f:	74 05                	je     f0101f16 <readline+0xa6>
f0101f11:	83 fb 0a             	cmp    $0xa,%ebx
f0101f14:	75 8d                	jne    f0101ea3 <readline+0x33>
			if (echoing)
f0101f16:	85 ff                	test   %edi,%edi
f0101f18:	74 0c                	je     f0101f26 <readline+0xb6>
				cputchar('\n');
f0101f1a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101f21:	e8 d6 e6 ff ff       	call   f01005fc <cputchar>
			buf[i] = 0;
f0101f26:	c6 86 80 45 11 f0 00 	movb   $0x0,-0xfeeba80(%esi)
			return buf;
f0101f2d:	b8 80 45 11 f0       	mov    $0xf0114580,%eax
		}
	}
}
f0101f32:	83 c4 1c             	add    $0x1c,%esp
f0101f35:	5b                   	pop    %ebx
f0101f36:	5e                   	pop    %esi
f0101f37:	5f                   	pop    %edi
f0101f38:	5d                   	pop    %ebp
f0101f39:	c3                   	ret    
f0101f3a:	66 90                	xchg   %ax,%ax
f0101f3c:	66 90                	xchg   %ax,%ax
f0101f3e:	66 90                	xchg   %ax,%ax

f0101f40 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101f40:	55                   	push   %ebp
f0101f41:	89 e5                	mov    %esp,%ebp
f0101f43:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101f46:	80 3a 00             	cmpb   $0x0,(%edx)
f0101f49:	74 10                	je     f0101f5b <strlen+0x1b>
f0101f4b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101f50:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101f53:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101f57:	75 f7                	jne    f0101f50 <strlen+0x10>
f0101f59:	eb 05                	jmp    f0101f60 <strlen+0x20>
f0101f5b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101f60:	5d                   	pop    %ebp
f0101f61:	c3                   	ret    

f0101f62 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101f62:	55                   	push   %ebp
f0101f63:	89 e5                	mov    %esp,%ebp
f0101f65:	53                   	push   %ebx
f0101f66:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101f69:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101f6c:	85 c9                	test   %ecx,%ecx
f0101f6e:	74 1c                	je     f0101f8c <strnlen+0x2a>
f0101f70:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101f73:	74 1e                	je     f0101f93 <strnlen+0x31>
f0101f75:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101f7a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101f7c:	39 ca                	cmp    %ecx,%edx
f0101f7e:	74 18                	je     f0101f98 <strnlen+0x36>
f0101f80:	83 c2 01             	add    $0x1,%edx
f0101f83:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101f88:	75 f0                	jne    f0101f7a <strnlen+0x18>
f0101f8a:	eb 0c                	jmp    f0101f98 <strnlen+0x36>
f0101f8c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101f91:	eb 05                	jmp    f0101f98 <strnlen+0x36>
f0101f93:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101f98:	5b                   	pop    %ebx
f0101f99:	5d                   	pop    %ebp
f0101f9a:	c3                   	ret    

f0101f9b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101f9b:	55                   	push   %ebp
f0101f9c:	89 e5                	mov    %esp,%ebp
f0101f9e:	53                   	push   %ebx
f0101f9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fa2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101fa5:	89 c2                	mov    %eax,%edx
f0101fa7:	0f b6 19             	movzbl (%ecx),%ebx
f0101faa:	88 1a                	mov    %bl,(%edx)
f0101fac:	83 c2 01             	add    $0x1,%edx
f0101faf:	83 c1 01             	add    $0x1,%ecx
f0101fb2:	84 db                	test   %bl,%bl
f0101fb4:	75 f1                	jne    f0101fa7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101fb6:	5b                   	pop    %ebx
f0101fb7:	5d                   	pop    %ebp
f0101fb8:	c3                   	ret    

f0101fb9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101fb9:	55                   	push   %ebp
f0101fba:	89 e5                	mov    %esp,%ebp
f0101fbc:	56                   	push   %esi
f0101fbd:	53                   	push   %ebx
f0101fbe:	8b 75 08             	mov    0x8(%ebp),%esi
f0101fc1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101fc4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101fc7:	85 db                	test   %ebx,%ebx
f0101fc9:	74 16                	je     f0101fe1 <strncpy+0x28>
		/* do nothing */;
	return ret;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f0101fcb:	01 f3                	add    %esi,%ebx
f0101fcd:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f0101fcf:	0f b6 02             	movzbl (%edx),%eax
f0101fd2:	88 01                	mov    %al,(%ecx)
f0101fd4:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101fd7:	80 3a 01             	cmpb   $0x1,(%edx)
f0101fda:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101fdd:	39 d9                	cmp    %ebx,%ecx
f0101fdf:	75 ee                	jne    f0101fcf <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101fe1:	89 f0                	mov    %esi,%eax
f0101fe3:	5b                   	pop    %ebx
f0101fe4:	5e                   	pop    %esi
f0101fe5:	5d                   	pop    %ebp
f0101fe6:	c3                   	ret    

f0101fe7 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101fe7:	55                   	push   %ebp
f0101fe8:	89 e5                	mov    %esp,%ebp
f0101fea:	57                   	push   %edi
f0101feb:	56                   	push   %esi
f0101fec:	53                   	push   %ebx
f0101fed:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101ff0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101ff3:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101ff6:	89 f8                	mov    %edi,%eax
f0101ff8:	85 f6                	test   %esi,%esi
f0101ffa:	74 33                	je     f010202f <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f0101ffc:	83 fe 01             	cmp    $0x1,%esi
f0101fff:	74 25                	je     f0102026 <strlcpy+0x3f>
f0102001:	0f b6 0b             	movzbl (%ebx),%ecx
f0102004:	84 c9                	test   %cl,%cl
f0102006:	74 22                	je     f010202a <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0102008:	83 ee 02             	sub    $0x2,%esi
f010200b:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102010:	88 08                	mov    %cl,(%eax)
f0102012:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0102015:	39 f2                	cmp    %esi,%edx
f0102017:	74 13                	je     f010202c <strlcpy+0x45>
f0102019:	83 c2 01             	add    $0x1,%edx
f010201c:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0102020:	84 c9                	test   %cl,%cl
f0102022:	75 ec                	jne    f0102010 <strlcpy+0x29>
f0102024:	eb 06                	jmp    f010202c <strlcpy+0x45>
f0102026:	89 f8                	mov    %edi,%eax
f0102028:	eb 02                	jmp    f010202c <strlcpy+0x45>
f010202a:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f010202c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010202f:	29 f8                	sub    %edi,%eax
}
f0102031:	5b                   	pop    %ebx
f0102032:	5e                   	pop    %esi
f0102033:	5f                   	pop    %edi
f0102034:	5d                   	pop    %ebp
f0102035:	c3                   	ret    

f0102036 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0102036:	55                   	push   %ebp
f0102037:	89 e5                	mov    %esp,%ebp
f0102039:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010203c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010203f:	0f b6 01             	movzbl (%ecx),%eax
f0102042:	84 c0                	test   %al,%al
f0102044:	74 15                	je     f010205b <strcmp+0x25>
f0102046:	3a 02                	cmp    (%edx),%al
f0102048:	75 11                	jne    f010205b <strcmp+0x25>
		p++, q++;
f010204a:	83 c1 01             	add    $0x1,%ecx
f010204d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0102050:	0f b6 01             	movzbl (%ecx),%eax
f0102053:	84 c0                	test   %al,%al
f0102055:	74 04                	je     f010205b <strcmp+0x25>
f0102057:	3a 02                	cmp    (%edx),%al
f0102059:	74 ef                	je     f010204a <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010205b:	0f b6 c0             	movzbl %al,%eax
f010205e:	0f b6 12             	movzbl (%edx),%edx
f0102061:	29 d0                	sub    %edx,%eax
}
f0102063:	5d                   	pop    %ebp
f0102064:	c3                   	ret    

f0102065 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0102065:	55                   	push   %ebp
f0102066:	89 e5                	mov    %esp,%ebp
f0102068:	56                   	push   %esi
f0102069:	53                   	push   %ebx
f010206a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010206d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102070:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0102073:	85 f6                	test   %esi,%esi
f0102075:	74 29                	je     f01020a0 <strncmp+0x3b>
f0102077:	0f b6 03             	movzbl (%ebx),%eax
f010207a:	84 c0                	test   %al,%al
f010207c:	74 30                	je     f01020ae <strncmp+0x49>
f010207e:	3a 02                	cmp    (%edx),%al
f0102080:	75 2c                	jne    f01020ae <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0102082:	8d 43 01             	lea    0x1(%ebx),%eax
f0102085:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0102087:	89 c3                	mov    %eax,%ebx
f0102089:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010208c:	39 f0                	cmp    %esi,%eax
f010208e:	74 17                	je     f01020a7 <strncmp+0x42>
f0102090:	0f b6 08             	movzbl (%eax),%ecx
f0102093:	84 c9                	test   %cl,%cl
f0102095:	74 17                	je     f01020ae <strncmp+0x49>
f0102097:	83 c0 01             	add    $0x1,%eax
f010209a:	3a 0a                	cmp    (%edx),%cl
f010209c:	74 e9                	je     f0102087 <strncmp+0x22>
f010209e:	eb 0e                	jmp    f01020ae <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01020a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01020a5:	eb 0f                	jmp    f01020b6 <strncmp+0x51>
f01020a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01020ac:	eb 08                	jmp    f01020b6 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01020ae:	0f b6 03             	movzbl (%ebx),%eax
f01020b1:	0f b6 12             	movzbl (%edx),%edx
f01020b4:	29 d0                	sub    %edx,%eax
}
f01020b6:	5b                   	pop    %ebx
f01020b7:	5e                   	pop    %esi
f01020b8:	5d                   	pop    %ebp
f01020b9:	c3                   	ret    

f01020ba <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01020ba:	55                   	push   %ebp
f01020bb:	89 e5                	mov    %esp,%ebp
f01020bd:	53                   	push   %ebx
f01020be:	8b 45 08             	mov    0x8(%ebp),%eax
f01020c1:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01020c4:	0f b6 18             	movzbl (%eax),%ebx
f01020c7:	84 db                	test   %bl,%bl
f01020c9:	74 1d                	je     f01020e8 <strchr+0x2e>
f01020cb:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01020cd:	38 d3                	cmp    %dl,%bl
f01020cf:	75 06                	jne    f01020d7 <strchr+0x1d>
f01020d1:	eb 1a                	jmp    f01020ed <strchr+0x33>
f01020d3:	38 ca                	cmp    %cl,%dl
f01020d5:	74 16                	je     f01020ed <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01020d7:	83 c0 01             	add    $0x1,%eax
f01020da:	0f b6 10             	movzbl (%eax),%edx
f01020dd:	84 d2                	test   %dl,%dl
f01020df:	75 f2                	jne    f01020d3 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f01020e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01020e6:	eb 05                	jmp    f01020ed <strchr+0x33>
f01020e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01020ed:	5b                   	pop    %ebx
f01020ee:	5d                   	pop    %ebp
f01020ef:	c3                   	ret    

f01020f0 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01020f0:	55                   	push   %ebp
f01020f1:	89 e5                	mov    %esp,%ebp
f01020f3:	53                   	push   %ebx
f01020f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01020f7:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01020fa:	0f b6 18             	movzbl (%eax),%ebx
f01020fd:	84 db                	test   %bl,%bl
f01020ff:	74 1b                	je     f010211c <strfind+0x2c>
f0102101:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0102103:	38 d3                	cmp    %dl,%bl
f0102105:	75 0b                	jne    f0102112 <strfind+0x22>
f0102107:	eb 13                	jmp    f010211c <strfind+0x2c>
f0102109:	38 ca                	cmp    %cl,%dl
f010210b:	90                   	nop
f010210c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102110:	74 0a                	je     f010211c <strfind+0x2c>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0102112:	83 c0 01             	add    $0x1,%eax
f0102115:	0f b6 10             	movzbl (%eax),%edx
f0102118:	84 d2                	test   %dl,%dl
f010211a:	75 ed                	jne    f0102109 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010211c:	5b                   	pop    %ebx
f010211d:	5d                   	pop    %ebp
f010211e:	c3                   	ret    

f010211f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010211f:	55                   	push   %ebp
f0102120:	89 e5                	mov    %esp,%ebp
f0102122:	83 ec 0c             	sub    $0xc,%esp
f0102125:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102128:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010212b:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010212e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102131:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0102134:	85 c9                	test   %ecx,%ecx
f0102136:	74 36                	je     f010216e <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0102138:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010213e:	75 28                	jne    f0102168 <memset+0x49>
f0102140:	f6 c1 03             	test   $0x3,%cl
f0102143:	75 23                	jne    f0102168 <memset+0x49>
		c &= 0xFF;
f0102145:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102149:	89 d3                	mov    %edx,%ebx
f010214b:	c1 e3 08             	shl    $0x8,%ebx
f010214e:	89 d6                	mov    %edx,%esi
f0102150:	c1 e6 18             	shl    $0x18,%esi
f0102153:	89 d0                	mov    %edx,%eax
f0102155:	c1 e0 10             	shl    $0x10,%eax
f0102158:	09 f0                	or     %esi,%eax
f010215a:	09 c2                	or     %eax,%edx
f010215c:	89 d0                	mov    %edx,%eax
f010215e:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0102160:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0102163:	fc                   	cld    
f0102164:	f3 ab                	rep stos %eax,%es:(%edi)
f0102166:	eb 06                	jmp    f010216e <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0102168:	8b 45 0c             	mov    0xc(%ebp),%eax
f010216b:	fc                   	cld    
f010216c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010216e:	89 f8                	mov    %edi,%eax
f0102170:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0102173:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0102176:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0102179:	89 ec                	mov    %ebp,%esp
f010217b:	5d                   	pop    %ebp
f010217c:	c3                   	ret    

f010217d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010217d:	55                   	push   %ebp
f010217e:	89 e5                	mov    %esp,%ebp
f0102180:	83 ec 08             	sub    $0x8,%esp
f0102183:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102186:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102189:	8b 45 08             	mov    0x8(%ebp),%eax
f010218c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010218f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102192:	39 c6                	cmp    %eax,%esi
f0102194:	73 36                	jae    f01021cc <memmove+0x4f>
f0102196:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102199:	39 d0                	cmp    %edx,%eax
f010219b:	73 2f                	jae    f01021cc <memmove+0x4f>
		s += n;
		d += n;
f010219d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01021a0:	f6 c2 03             	test   $0x3,%dl
f01021a3:	75 1b                	jne    f01021c0 <memmove+0x43>
f01021a5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01021ab:	75 13                	jne    f01021c0 <memmove+0x43>
f01021ad:	f6 c1 03             	test   $0x3,%cl
f01021b0:	75 0e                	jne    f01021c0 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01021b2:	83 ef 04             	sub    $0x4,%edi
f01021b5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01021b8:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01021bb:	fd                   	std    
f01021bc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01021be:	eb 09                	jmp    f01021c9 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01021c0:	83 ef 01             	sub    $0x1,%edi
f01021c3:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01021c6:	fd                   	std    
f01021c7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01021c9:	fc                   	cld    
f01021ca:	eb 20                	jmp    f01021ec <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01021cc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01021d2:	75 13                	jne    f01021e7 <memmove+0x6a>
f01021d4:	a8 03                	test   $0x3,%al
f01021d6:	75 0f                	jne    f01021e7 <memmove+0x6a>
f01021d8:	f6 c1 03             	test   $0x3,%cl
f01021db:	75 0a                	jne    f01021e7 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01021dd:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01021e0:	89 c7                	mov    %eax,%edi
f01021e2:	fc                   	cld    
f01021e3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01021e5:	eb 05                	jmp    f01021ec <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01021e7:	89 c7                	mov    %eax,%edi
f01021e9:	fc                   	cld    
f01021ea:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01021ec:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01021ef:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01021f2:	89 ec                	mov    %ebp,%esp
f01021f4:	5d                   	pop    %ebp
f01021f5:	c3                   	ret    

f01021f6 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01021f6:	55                   	push   %ebp
f01021f7:	89 e5                	mov    %esp,%ebp
f01021f9:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01021fc:	8b 45 10             	mov    0x10(%ebp),%eax
f01021ff:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102203:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102206:	89 44 24 04          	mov    %eax,0x4(%esp)
f010220a:	8b 45 08             	mov    0x8(%ebp),%eax
f010220d:	89 04 24             	mov    %eax,(%esp)
f0102210:	e8 68 ff ff ff       	call   f010217d <memmove>
}
f0102215:	c9                   	leave  
f0102216:	c3                   	ret    

f0102217 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102217:	55                   	push   %ebp
f0102218:	89 e5                	mov    %esp,%ebp
f010221a:	57                   	push   %edi
f010221b:	56                   	push   %esi
f010221c:	53                   	push   %ebx
f010221d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0102220:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102223:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102226:	8d 78 ff             	lea    -0x1(%eax),%edi
f0102229:	85 c0                	test   %eax,%eax
f010222b:	74 36                	je     f0102263 <memcmp+0x4c>
		if (*s1 != *s2)
f010222d:	0f b6 03             	movzbl (%ebx),%eax
f0102230:	0f b6 0e             	movzbl (%esi),%ecx
f0102233:	38 c8                	cmp    %cl,%al
f0102235:	75 17                	jne    f010224e <memcmp+0x37>
f0102237:	ba 00 00 00 00       	mov    $0x0,%edx
f010223c:	eb 1a                	jmp    f0102258 <memcmp+0x41>
f010223e:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0102243:	83 c2 01             	add    $0x1,%edx
f0102246:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010224a:	38 c8                	cmp    %cl,%al
f010224c:	74 0a                	je     f0102258 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010224e:	0f b6 c0             	movzbl %al,%eax
f0102251:	0f b6 c9             	movzbl %cl,%ecx
f0102254:	29 c8                	sub    %ecx,%eax
f0102256:	eb 10                	jmp    f0102268 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102258:	39 fa                	cmp    %edi,%edx
f010225a:	75 e2                	jne    f010223e <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010225c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102261:	eb 05                	jmp    f0102268 <memcmp+0x51>
f0102263:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102268:	5b                   	pop    %ebx
f0102269:	5e                   	pop    %esi
f010226a:	5f                   	pop    %edi
f010226b:	5d                   	pop    %ebp
f010226c:	c3                   	ret    

f010226d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010226d:	55                   	push   %ebp
f010226e:	89 e5                	mov    %esp,%ebp
f0102270:	53                   	push   %ebx
f0102271:	8b 45 08             	mov    0x8(%ebp),%eax
f0102274:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0102277:	89 c2                	mov    %eax,%edx
f0102279:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010227c:	39 d0                	cmp    %edx,%eax
f010227e:	73 13                	jae    f0102293 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102280:	89 d9                	mov    %ebx,%ecx
f0102282:	38 18                	cmp    %bl,(%eax)
f0102284:	75 06                	jne    f010228c <memfind+0x1f>
f0102286:	eb 0b                	jmp    f0102293 <memfind+0x26>
f0102288:	38 08                	cmp    %cl,(%eax)
f010228a:	74 07                	je     f0102293 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010228c:	83 c0 01             	add    $0x1,%eax
f010228f:	39 d0                	cmp    %edx,%eax
f0102291:	75 f5                	jne    f0102288 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0102293:	5b                   	pop    %ebx
f0102294:	5d                   	pop    %ebp
f0102295:	c3                   	ret    

f0102296 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102296:	55                   	push   %ebp
f0102297:	89 e5                	mov    %esp,%ebp
f0102299:	57                   	push   %edi
f010229a:	56                   	push   %esi
f010229b:	53                   	push   %ebx
f010229c:	83 ec 04             	sub    $0x4,%esp
f010229f:	8b 55 08             	mov    0x8(%ebp),%edx
f01022a2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01022a5:	0f b6 02             	movzbl (%edx),%eax
f01022a8:	3c 09                	cmp    $0x9,%al
f01022aa:	74 04                	je     f01022b0 <strtol+0x1a>
f01022ac:	3c 20                	cmp    $0x20,%al
f01022ae:	75 0e                	jne    f01022be <strtol+0x28>
		s++;
f01022b0:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01022b3:	0f b6 02             	movzbl (%edx),%eax
f01022b6:	3c 09                	cmp    $0x9,%al
f01022b8:	74 f6                	je     f01022b0 <strtol+0x1a>
f01022ba:	3c 20                	cmp    $0x20,%al
f01022bc:	74 f2                	je     f01022b0 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01022be:	3c 2b                	cmp    $0x2b,%al
f01022c0:	75 0a                	jne    f01022cc <strtol+0x36>
		s++;
f01022c2:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01022c5:	bf 00 00 00 00       	mov    $0x0,%edi
f01022ca:	eb 10                	jmp    f01022dc <strtol+0x46>
f01022cc:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01022d1:	3c 2d                	cmp    $0x2d,%al
f01022d3:	75 07                	jne    f01022dc <strtol+0x46>
		s++, neg = 1;
f01022d5:	83 c2 01             	add    $0x1,%edx
f01022d8:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01022dc:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01022e2:	75 15                	jne    f01022f9 <strtol+0x63>
f01022e4:	80 3a 30             	cmpb   $0x30,(%edx)
f01022e7:	75 10                	jne    f01022f9 <strtol+0x63>
f01022e9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01022ed:	75 0a                	jne    f01022f9 <strtol+0x63>
		s += 2, base = 16;
f01022ef:	83 c2 02             	add    $0x2,%edx
f01022f2:	bb 10 00 00 00       	mov    $0x10,%ebx
f01022f7:	eb 10                	jmp    f0102309 <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f01022f9:	85 db                	test   %ebx,%ebx
f01022fb:	75 0c                	jne    f0102309 <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01022fd:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01022ff:	80 3a 30             	cmpb   $0x30,(%edx)
f0102302:	75 05                	jne    f0102309 <strtol+0x73>
		s++, base = 8;
f0102304:	83 c2 01             	add    $0x1,%edx
f0102307:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0102309:	b8 00 00 00 00       	mov    $0x0,%eax
f010230e:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102311:	0f b6 0a             	movzbl (%edx),%ecx
f0102314:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0102317:	89 f3                	mov    %esi,%ebx
f0102319:	80 fb 09             	cmp    $0x9,%bl
f010231c:	77 08                	ja     f0102326 <strtol+0x90>
			dig = *s - '0';
f010231e:	0f be c9             	movsbl %cl,%ecx
f0102321:	83 e9 30             	sub    $0x30,%ecx
f0102324:	eb 22                	jmp    f0102348 <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0102326:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0102329:	89 f3                	mov    %esi,%ebx
f010232b:	80 fb 19             	cmp    $0x19,%bl
f010232e:	77 08                	ja     f0102338 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0102330:	0f be c9             	movsbl %cl,%ecx
f0102333:	83 e9 57             	sub    $0x57,%ecx
f0102336:	eb 10                	jmp    f0102348 <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0102338:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010233b:	89 f3                	mov    %esi,%ebx
f010233d:	80 fb 19             	cmp    $0x19,%bl
f0102340:	77 16                	ja     f0102358 <strtol+0xc2>
			dig = *s - 'A' + 10;
f0102342:	0f be c9             	movsbl %cl,%ecx
f0102345:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0102348:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010234b:	7d 0f                	jge    f010235c <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f010234d:	83 c2 01             	add    $0x1,%edx
f0102350:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0102354:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0102356:	eb b9                	jmp    f0102311 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0102358:	89 c1                	mov    %eax,%ecx
f010235a:	eb 02                	jmp    f010235e <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010235c:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f010235e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102362:	74 05                	je     f0102369 <strtol+0xd3>
		*endptr = (char *) s;
f0102364:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102367:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0102369:	89 ca                	mov    %ecx,%edx
f010236b:	f7 da                	neg    %edx
f010236d:	85 ff                	test   %edi,%edi
f010236f:	0f 45 c2             	cmovne %edx,%eax
}
f0102372:	83 c4 04             	add    $0x4,%esp
f0102375:	5b                   	pop    %ebx
f0102376:	5e                   	pop    %esi
f0102377:	5f                   	pop    %edi
f0102378:	5d                   	pop    %ebp
f0102379:	c3                   	ret    
f010237a:	66 90                	xchg   %ax,%ax
f010237c:	66 90                	xchg   %ax,%ax
f010237e:	66 90                	xchg   %ax,%ax

f0102380 <__udivdi3>:
f0102380:	83 ec 1c             	sub    $0x1c,%esp
f0102383:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0102387:	89 7c 24 14          	mov    %edi,0x14(%esp)
f010238b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010238f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0102393:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0102397:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f010239b:	85 c0                	test   %eax,%eax
f010239d:	89 74 24 10          	mov    %esi,0x10(%esp)
f01023a1:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01023a5:	89 ea                	mov    %ebp,%edx
f01023a7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01023ab:	75 33                	jne    f01023e0 <__udivdi3+0x60>
f01023ad:	39 e9                	cmp    %ebp,%ecx
f01023af:	77 6f                	ja     f0102420 <__udivdi3+0xa0>
f01023b1:	85 c9                	test   %ecx,%ecx
f01023b3:	89 ce                	mov    %ecx,%esi
f01023b5:	75 0b                	jne    f01023c2 <__udivdi3+0x42>
f01023b7:	b8 01 00 00 00       	mov    $0x1,%eax
f01023bc:	31 d2                	xor    %edx,%edx
f01023be:	f7 f1                	div    %ecx
f01023c0:	89 c6                	mov    %eax,%esi
f01023c2:	31 d2                	xor    %edx,%edx
f01023c4:	89 e8                	mov    %ebp,%eax
f01023c6:	f7 f6                	div    %esi
f01023c8:	89 c5                	mov    %eax,%ebp
f01023ca:	89 f8                	mov    %edi,%eax
f01023cc:	f7 f6                	div    %esi
f01023ce:	89 ea                	mov    %ebp,%edx
f01023d0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01023d4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01023d8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01023dc:	83 c4 1c             	add    $0x1c,%esp
f01023df:	c3                   	ret    
f01023e0:	39 e8                	cmp    %ebp,%eax
f01023e2:	77 24                	ja     f0102408 <__udivdi3+0x88>
f01023e4:	0f bd c8             	bsr    %eax,%ecx
f01023e7:	83 f1 1f             	xor    $0x1f,%ecx
f01023ea:	89 0c 24             	mov    %ecx,(%esp)
f01023ed:	75 49                	jne    f0102438 <__udivdi3+0xb8>
f01023ef:	8b 74 24 08          	mov    0x8(%esp),%esi
f01023f3:	39 74 24 04          	cmp    %esi,0x4(%esp)
f01023f7:	0f 86 ab 00 00 00    	jbe    f01024a8 <__udivdi3+0x128>
f01023fd:	39 e8                	cmp    %ebp,%eax
f01023ff:	0f 82 a3 00 00 00    	jb     f01024a8 <__udivdi3+0x128>
f0102405:	8d 76 00             	lea    0x0(%esi),%esi
f0102408:	31 d2                	xor    %edx,%edx
f010240a:	31 c0                	xor    %eax,%eax
f010240c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102410:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0102414:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0102418:	83 c4 1c             	add    $0x1c,%esp
f010241b:	c3                   	ret    
f010241c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102420:	89 f8                	mov    %edi,%eax
f0102422:	f7 f1                	div    %ecx
f0102424:	31 d2                	xor    %edx,%edx
f0102426:	8b 74 24 10          	mov    0x10(%esp),%esi
f010242a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010242e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0102432:	83 c4 1c             	add    $0x1c,%esp
f0102435:	c3                   	ret    
f0102436:	66 90                	xchg   %ax,%ax
f0102438:	0f b6 0c 24          	movzbl (%esp),%ecx
f010243c:	89 c6                	mov    %eax,%esi
f010243e:	b8 20 00 00 00       	mov    $0x20,%eax
f0102443:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0102447:	2b 04 24             	sub    (%esp),%eax
f010244a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010244e:	d3 e6                	shl    %cl,%esi
f0102450:	89 c1                	mov    %eax,%ecx
f0102452:	d3 ed                	shr    %cl,%ebp
f0102454:	0f b6 0c 24          	movzbl (%esp),%ecx
f0102458:	09 f5                	or     %esi,%ebp
f010245a:	8b 74 24 04          	mov    0x4(%esp),%esi
f010245e:	d3 e6                	shl    %cl,%esi
f0102460:	89 c1                	mov    %eax,%ecx
f0102462:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102466:	89 d6                	mov    %edx,%esi
f0102468:	d3 ee                	shr    %cl,%esi
f010246a:	0f b6 0c 24          	movzbl (%esp),%ecx
f010246e:	d3 e2                	shl    %cl,%edx
f0102470:	89 c1                	mov    %eax,%ecx
f0102472:	d3 ef                	shr    %cl,%edi
f0102474:	09 d7                	or     %edx,%edi
f0102476:	89 f2                	mov    %esi,%edx
f0102478:	89 f8                	mov    %edi,%eax
f010247a:	f7 f5                	div    %ebp
f010247c:	89 d6                	mov    %edx,%esi
f010247e:	89 c7                	mov    %eax,%edi
f0102480:	f7 64 24 04          	mull   0x4(%esp)
f0102484:	39 d6                	cmp    %edx,%esi
f0102486:	72 30                	jb     f01024b8 <__udivdi3+0x138>
f0102488:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f010248c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0102490:	d3 e5                	shl    %cl,%ebp
f0102492:	39 c5                	cmp    %eax,%ebp
f0102494:	73 04                	jae    f010249a <__udivdi3+0x11a>
f0102496:	39 d6                	cmp    %edx,%esi
f0102498:	74 1e                	je     f01024b8 <__udivdi3+0x138>
f010249a:	89 f8                	mov    %edi,%eax
f010249c:	31 d2                	xor    %edx,%edx
f010249e:	e9 69 ff ff ff       	jmp    f010240c <__udivdi3+0x8c>
f01024a3:	90                   	nop
f01024a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01024a8:	31 d2                	xor    %edx,%edx
f01024aa:	b8 01 00 00 00       	mov    $0x1,%eax
f01024af:	e9 58 ff ff ff       	jmp    f010240c <__udivdi3+0x8c>
f01024b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01024b8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01024bb:	31 d2                	xor    %edx,%edx
f01024bd:	8b 74 24 10          	mov    0x10(%esp),%esi
f01024c1:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01024c5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01024c9:	83 c4 1c             	add    $0x1c,%esp
f01024cc:	c3                   	ret    
f01024cd:	66 90                	xchg   %ax,%ax
f01024cf:	90                   	nop

f01024d0 <__umoddi3>:
f01024d0:	83 ec 2c             	sub    $0x2c,%esp
f01024d3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01024d7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01024db:	89 74 24 20          	mov    %esi,0x20(%esp)
f01024df:	8b 74 24 38          	mov    0x38(%esp),%esi
f01024e3:	89 7c 24 24          	mov    %edi,0x24(%esp)
f01024e7:	8b 7c 24 34          	mov    0x34(%esp),%edi
f01024eb:	85 c0                	test   %eax,%eax
f01024ed:	89 c2                	mov    %eax,%edx
f01024ef:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f01024f3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f01024f7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01024fb:	89 74 24 10          	mov    %esi,0x10(%esp)
f01024ff:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0102503:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0102507:	75 1f                	jne    f0102528 <__umoddi3+0x58>
f0102509:	39 fe                	cmp    %edi,%esi
f010250b:	76 63                	jbe    f0102570 <__umoddi3+0xa0>
f010250d:	89 c8                	mov    %ecx,%eax
f010250f:	89 fa                	mov    %edi,%edx
f0102511:	f7 f6                	div    %esi
f0102513:	89 d0                	mov    %edx,%eax
f0102515:	31 d2                	xor    %edx,%edx
f0102517:	8b 74 24 20          	mov    0x20(%esp),%esi
f010251b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010251f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0102523:	83 c4 2c             	add    $0x2c,%esp
f0102526:	c3                   	ret    
f0102527:	90                   	nop
f0102528:	39 f8                	cmp    %edi,%eax
f010252a:	77 64                	ja     f0102590 <__umoddi3+0xc0>
f010252c:	0f bd e8             	bsr    %eax,%ebp
f010252f:	83 f5 1f             	xor    $0x1f,%ebp
f0102532:	75 74                	jne    f01025a8 <__umoddi3+0xd8>
f0102534:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0102538:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f010253c:	0f 87 0e 01 00 00    	ja     f0102650 <__umoddi3+0x180>
f0102542:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0102546:	29 f1                	sub    %esi,%ecx
f0102548:	19 c7                	sbb    %eax,%edi
f010254a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010254e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0102552:	8b 44 24 14          	mov    0x14(%esp),%eax
f0102556:	8b 54 24 18          	mov    0x18(%esp),%edx
f010255a:	8b 74 24 20          	mov    0x20(%esp),%esi
f010255e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0102562:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0102566:	83 c4 2c             	add    $0x2c,%esp
f0102569:	c3                   	ret    
f010256a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102570:	85 f6                	test   %esi,%esi
f0102572:	89 f5                	mov    %esi,%ebp
f0102574:	75 0b                	jne    f0102581 <__umoddi3+0xb1>
f0102576:	b8 01 00 00 00       	mov    $0x1,%eax
f010257b:	31 d2                	xor    %edx,%edx
f010257d:	f7 f6                	div    %esi
f010257f:	89 c5                	mov    %eax,%ebp
f0102581:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0102585:	31 d2                	xor    %edx,%edx
f0102587:	f7 f5                	div    %ebp
f0102589:	89 c8                	mov    %ecx,%eax
f010258b:	f7 f5                	div    %ebp
f010258d:	eb 84                	jmp    f0102513 <__umoddi3+0x43>
f010258f:	90                   	nop
f0102590:	89 c8                	mov    %ecx,%eax
f0102592:	89 fa                	mov    %edi,%edx
f0102594:	8b 74 24 20          	mov    0x20(%esp),%esi
f0102598:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010259c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01025a0:	83 c4 2c             	add    $0x2c,%esp
f01025a3:	c3                   	ret    
f01025a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01025a8:	8b 44 24 10          	mov    0x10(%esp),%eax
f01025ac:	be 20 00 00 00       	mov    $0x20,%esi
f01025b1:	89 e9                	mov    %ebp,%ecx
f01025b3:	29 ee                	sub    %ebp,%esi
f01025b5:	d3 e2                	shl    %cl,%edx
f01025b7:	89 f1                	mov    %esi,%ecx
f01025b9:	d3 e8                	shr    %cl,%eax
f01025bb:	89 e9                	mov    %ebp,%ecx
f01025bd:	09 d0                	or     %edx,%eax
f01025bf:	89 fa                	mov    %edi,%edx
f01025c1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025c5:	8b 44 24 10          	mov    0x10(%esp),%eax
f01025c9:	d3 e0                	shl    %cl,%eax
f01025cb:	89 f1                	mov    %esi,%ecx
f01025cd:	89 44 24 10          	mov    %eax,0x10(%esp)
f01025d1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01025d5:	d3 ea                	shr    %cl,%edx
f01025d7:	89 e9                	mov    %ebp,%ecx
f01025d9:	d3 e7                	shl    %cl,%edi
f01025db:	89 f1                	mov    %esi,%ecx
f01025dd:	d3 e8                	shr    %cl,%eax
f01025df:	89 e9                	mov    %ebp,%ecx
f01025e1:	09 f8                	or     %edi,%eax
f01025e3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01025e7:	f7 74 24 0c          	divl   0xc(%esp)
f01025eb:	d3 e7                	shl    %cl,%edi
f01025ed:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01025f1:	89 d7                	mov    %edx,%edi
f01025f3:	f7 64 24 10          	mull   0x10(%esp)
f01025f7:	39 d7                	cmp    %edx,%edi
f01025f9:	89 c1                	mov    %eax,%ecx
f01025fb:	89 54 24 14          	mov    %edx,0x14(%esp)
f01025ff:	72 3b                	jb     f010263c <__umoddi3+0x16c>
f0102601:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0102605:	72 31                	jb     f0102638 <__umoddi3+0x168>
f0102607:	8b 44 24 18          	mov    0x18(%esp),%eax
f010260b:	29 c8                	sub    %ecx,%eax
f010260d:	19 d7                	sbb    %edx,%edi
f010260f:	89 e9                	mov    %ebp,%ecx
f0102611:	89 fa                	mov    %edi,%edx
f0102613:	d3 e8                	shr    %cl,%eax
f0102615:	89 f1                	mov    %esi,%ecx
f0102617:	d3 e2                	shl    %cl,%edx
f0102619:	89 e9                	mov    %ebp,%ecx
f010261b:	09 d0                	or     %edx,%eax
f010261d:	89 fa                	mov    %edi,%edx
f010261f:	d3 ea                	shr    %cl,%edx
f0102621:	8b 74 24 20          	mov    0x20(%esp),%esi
f0102625:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0102629:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f010262d:	83 c4 2c             	add    $0x2c,%esp
f0102630:	c3                   	ret    
f0102631:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102638:	39 d7                	cmp    %edx,%edi
f010263a:	75 cb                	jne    f0102607 <__umoddi3+0x137>
f010263c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0102640:	89 c1                	mov    %eax,%ecx
f0102642:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0102646:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010264a:	eb bb                	jmp    f0102607 <__umoddi3+0x137>
f010264c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102650:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0102654:	0f 82 e8 fe ff ff    	jb     f0102542 <__umoddi3+0x72>
f010265a:	e9 f3 fe ff ff       	jmp    f0102552 <__umoddi3+0x82>

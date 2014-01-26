
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

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
f0100046:	b8 8c 69 11 f0       	mov    $0xf011698c,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 63 11 f0 	movl   $0xf0116300,(%esp)
f0100063:	e8 d7 2f 00 00       	call   f010303f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 9a 04 00 00       	call   f0100507 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 80 35 10 f0 	movl   $0xf0103580,(%esp)
f010007c:	e8 e9 23 00 00       	call   f010246a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 29 0e 00 00       	call   f0100eaf <mem_init>

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
f010009f:	83 3d 00 63 11 f0 00 	cmpl   $0x0,0xf0116300
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 00 63 11 f0    	mov    %esi,0xf0116300

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
f01000c1:	c7 04 24 9b 35 10 f0 	movl   $0xf010359b,(%esp)
f01000c8:	e8 9d 23 00 00       	call   f010246a <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 5e 23 00 00       	call   f0102437 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 d7 3f 10 f0 	movl   $0xf0103fd7,(%esp)
f01000e0:	e8 85 23 00 00       	call   f010246a <cprintf>
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
f010010b:	c7 04 24 b3 35 10 f0 	movl   $0xf01035b3,(%esp)
f0100112:	e8 53 23 00 00       	call   f010246a <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 11 23 00 00       	call   f0102437 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 d7 3f 10 f0 	movl   $0xf0103fd7,(%esp)
f010012d:	e8 38 23 00 00       	call   f010246a <cprintf>
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
f0100179:	a1 44 65 11 f0       	mov    0xf0116544,%eax
f010017e:	88 90 40 63 11 f0    	mov    %dl,-0xfee9cc0(%eax)
f0100184:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f0100187:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f010018d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100192:	0f 44 d0             	cmove  %eax,%edx
f0100195:	89 15 44 65 11 f0    	mov    %edx,0xf0116544
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
f0100262:	0f b7 05 54 65 11 f0 	movzwl 0xf0116554,%eax
f0100269:	66 85 c0             	test   %ax,%ax
f010026c:	0f 84 e5 00 00 00    	je     f0100357 <cons_putc+0x1ad>
			crt_pos--;
f0100272:	83 e8 01             	sub    $0x1,%eax
f0100275:	66 a3 54 65 11 f0    	mov    %ax,0xf0116554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027b:	0f b7 c0             	movzwl %ax,%eax
f010027e:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f0100284:	83 cf 20             	or     $0x20,%edi
f0100287:	8b 15 50 65 11 f0    	mov    0xf0116550,%edx
f010028d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100291:	eb 77                	jmp    f010030a <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100293:	66 83 05 54 65 11 f0 	addw   $0x50,0xf0116554
f010029a:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010029b:	0f b7 05 54 65 11 f0 	movzwl 0xf0116554,%eax
f01002a2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a8:	c1 e8 16             	shr    $0x16,%eax
f01002ab:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ae:	c1 e0 04             	shl    $0x4,%eax
f01002b1:	66 a3 54 65 11 f0    	mov    %ax,0xf0116554
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
f01002ed:	0f b7 05 54 65 11 f0 	movzwl 0xf0116554,%eax
f01002f4:	0f b7 c8             	movzwl %ax,%ecx
f01002f7:	8b 15 50 65 11 f0    	mov    0xf0116550,%edx
f01002fd:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100301:	83 c0 01             	add    $0x1,%eax
f0100304:	66 a3 54 65 11 f0    	mov    %ax,0xf0116554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010030a:	66 81 3d 54 65 11 f0 	cmpw   $0x7cf,0xf0116554
f0100311:	cf 07 
f0100313:	76 42                	jbe    f0100357 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100315:	a1 50 65 11 f0       	mov    0xf0116550,%eax
f010031a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100321:	00 
f0100322:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100328:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032c:	89 04 24             	mov    %eax,(%esp)
f010032f:	e8 69 2d 00 00       	call   f010309d <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100334:	8b 15 50 65 11 f0    	mov    0xf0116550,%edx
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
f010034f:	66 83 2d 54 65 11 f0 	subw   $0x50,0xf0116554
f0100356:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100357:	8b 0d 4c 65 11 f0    	mov    0xf011654c,%ecx
f010035d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100362:	89 ca                	mov    %ecx,%edx
f0100364:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100365:	0f b7 1d 54 65 11 f0 	movzwl 0xf0116554,%ebx
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
f01003ab:	83 0d 48 65 11 f0 40 	orl    $0x40,0xf0116548
		return 0;
f01003b2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003b7:	e9 d0 00 00 00       	jmp    f010048c <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003bc:	84 c0                	test   %al,%al
f01003be:	79 37                	jns    f01003f7 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c0:	8b 0d 48 65 11 f0    	mov    0xf0116548,%ecx
f01003c6:	89 cb                	mov    %ecx,%ebx
f01003c8:	83 e3 40             	and    $0x40,%ebx
f01003cb:	83 e0 7f             	and    $0x7f,%eax
f01003ce:	85 db                	test   %ebx,%ebx
f01003d0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d3:	0f b6 d2             	movzbl %dl,%edx
f01003d6:	0f b6 82 00 36 10 f0 	movzbl -0xfefca00(%edx),%eax
f01003dd:	83 c8 40             	or     $0x40,%eax
f01003e0:	0f b6 c0             	movzbl %al,%eax
f01003e3:	f7 d0                	not    %eax
f01003e5:	21 c1                	and    %eax,%ecx
f01003e7:	89 0d 48 65 11 f0    	mov    %ecx,0xf0116548
		return 0;
f01003ed:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f2:	e9 95 00 00 00       	jmp    f010048c <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f01003f7:	8b 0d 48 65 11 f0    	mov    0xf0116548,%ecx
f01003fd:	f6 c1 40             	test   $0x40,%cl
f0100400:	74 0e                	je     f0100410 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100402:	89 c2                	mov    %eax,%edx
f0100404:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100407:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040a:	89 0d 48 65 11 f0    	mov    %ecx,0xf0116548
	}

	shift |= shiftcode[data];
f0100410:	0f b6 d2             	movzbl %dl,%edx
f0100413:	0f b6 82 00 36 10 f0 	movzbl -0xfefca00(%edx),%eax
f010041a:	0b 05 48 65 11 f0    	or     0xf0116548,%eax
	shift ^= togglecode[data];
f0100420:	0f b6 8a 00 37 10 f0 	movzbl -0xfefc900(%edx),%ecx
f0100427:	31 c8                	xor    %ecx,%eax
f0100429:	a3 48 65 11 f0       	mov    %eax,0xf0116548

	c = charcode[shift & (CTL | SHIFT)][data];
f010042e:	89 c1                	mov    %eax,%ecx
f0100430:	83 e1 03             	and    $0x3,%ecx
f0100433:	8b 0c 8d 00 38 10 f0 	mov    -0xfefc800(,%ecx,4),%ecx
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
f010046e:	c7 04 24 cd 35 10 f0 	movl   $0xf01035cd,(%esp)
f0100475:	e8 f0 1f 00 00       	call   f010246a <cprintf>
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
f0100494:	83 3d 20 63 11 f0 00 	cmpl   $0x0,0xf0116320
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
f01004d2:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f01004d8:	3b 15 44 65 11 f0    	cmp    0xf0116544,%edx
f01004de:	74 20                	je     f0100500 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01004e0:	0f b6 82 40 63 11 f0 	movzbl -0xfee9cc0(%edx),%eax
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
f01004f8:	89 15 40 65 11 f0    	mov    %edx,0xf0116540
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
f010052d:	c7 05 4c 65 11 f0 b4 	movl   $0x3b4,0xf011654c
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
f0100545:	c7 05 4c 65 11 f0 d4 	movl   $0x3d4,0xf011654c
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
f0100554:	8b 0d 4c 65 11 f0    	mov    0xf011654c,%ecx
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
f0100579:	89 3d 50 65 11 f0    	mov    %edi,0xf0116550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010057f:	0f b6 d8             	movzbl %al,%ebx
f0100582:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100584:	66 89 35 54 65 11 f0 	mov    %si,0xf0116554
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
f01005d8:	89 0d 20 63 11 f0    	mov    %ecx,0xf0116320
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
f01005e8:	c7 04 24 d9 35 10 f0 	movl   $0xf01035d9,(%esp)
f01005ef:	e8 76 1e 00 00       	call   f010246a <cprintf>
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
f0100636:	c7 04 24 10 38 10 f0 	movl   $0xf0103810,(%esp)
f010063d:	e8 28 1e 00 00       	call   f010246a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100642:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100649:	00 
f010064a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 f8 38 10 f0 	movl   $0xf01038f8,(%esp)
f0100659:	e8 0c 1e 00 00       	call   f010246a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010065e:	c7 44 24 08 7f 35 10 	movl   $0x10357f,0x8(%esp)
f0100665:	00 
f0100666:	c7 44 24 04 7f 35 10 	movl   $0xf010357f,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 1c 39 10 f0 	movl   $0xf010391c,(%esp)
f0100675:	e8 f0 1d 00 00       	call   f010246a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010067a:	c7 44 24 08 00 63 11 	movl   $0x116300,0x8(%esp)
f0100681:	00 
f0100682:	c7 44 24 04 00 63 11 	movl   $0xf0116300,0x4(%esp)
f0100689:	f0 
f010068a:	c7 04 24 40 39 10 f0 	movl   $0xf0103940,(%esp)
f0100691:	e8 d4 1d 00 00       	call   f010246a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100696:	c7 44 24 08 8c 69 11 	movl   $0x11698c,0x8(%esp)
f010069d:	00 
f010069e:	c7 44 24 04 8c 69 11 	movl   $0xf011698c,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 64 39 10 f0 	movl   $0xf0103964,(%esp)
f01006ad:	e8 b8 1d 00 00       	call   f010246a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006b2:	b8 8b 6d 11 f0       	mov    $0xf0116d8b,%eax
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
f01006ce:	c7 04 24 88 39 10 f0 	movl   $0xf0103988,(%esp)
f01006d5:	e8 90 1d 00 00       	call   f010246a <cprintf>
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
f01006e9:	bb 44 3a 10 f0       	mov    $0xf0103a44,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f01006ee:	be 68 3a 10 f0       	mov    $0xf0103a68,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006f3:	8b 03                	mov    (%ebx),%eax
f01006f5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006f9:	8b 43 fc             	mov    -0x4(%ebx),%eax
f01006fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100700:	c7 04 24 29 38 10 f0 	movl   $0xf0103829,(%esp)
f0100707:	e8 5e 1d 00 00       	call   f010246a <cprintf>
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
f0100728:	c7 04 24 32 38 10 f0 	movl   $0xf0103832,(%esp)
f010072f:	e8 36 1d 00 00       	call   f010246a <cprintf>

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
f010073a:	c7 04 24 44 38 10 f0 	movl   $0xf0103844,(%esp)
f0100741:	e8 24 1d 00 00       	call   f010246a <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f0100746:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f0100749:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010074d:	c7 04 24 4f 38 10 f0 	movl   $0xf010384f,(%esp)
f0100754:	e8 11 1d 00 00       	call   f010246a <cprintf>
		for(i=2; i < 7; i++)
f0100759:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f010075e:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100761:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100765:	c7 04 24 49 38 10 f0 	movl   $0xf0103849,(%esp)
f010076c:	e8 f9 1c 00 00       	call   f010246a <cprintf>
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
f0100779:	c7 04 24 d7 3f 10 f0 	movl   $0xf0103fd7,(%esp)
f0100780:	e8 e5 1c 00 00       	call   f010246a <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f0100785:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100788:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078c:	89 3c 24             	mov    %edi,(%esp)
f010078f:	e8 d9 1d 00 00       	call   f010256d <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f0100794:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100797:	89 44 24 08          	mov    %eax,0x8(%esp)
f010079b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010079e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a2:	c7 04 24 60 38 10 f0 	movl   $0xf0103860,(%esp)
f01007a9:	e8 bc 1c 00 00       	call   f010246a <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f01007ae:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007b1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007b5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007bc:	c7 04 24 69 38 10 f0 	movl   $0xf0103869,(%esp)
f01007c3:	e8 a2 1c 00 00       	call   f010246a <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f01007c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007cf:	c7 04 24 6e 38 10 f0 	movl   $0xf010386e,(%esp)
f01007d6:	e8 8f 1c 00 00       	call   f010246a <cprintf>
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
f01007fb:	c7 04 24 b4 39 10 f0 	movl   $0xf01039b4,(%esp)
f0100802:	e8 63 1c 00 00       	call   f010246a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100807:	c7 04 24 d8 39 10 f0 	movl   $0xf01039d8,(%esp)
f010080e:	e8 57 1c 00 00       	call   f010246a <cprintf>


	while (1) {
		buf = readline("K> ");
f0100813:	c7 04 24 73 38 10 f0 	movl   $0xf0103873,(%esp)
f010081a:	e8 71 25 00 00       	call   f0102d90 <readline>
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
f0100847:	c7 04 24 77 38 10 f0 	movl   $0xf0103877,(%esp)
f010084e:	e8 87 27 00 00       	call   f0102fda <strchr>
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
f010086a:	c7 04 24 7c 38 10 f0 	movl   $0xf010387c,(%esp)
f0100871:	e8 f4 1b 00 00       	call   f010246a <cprintf>
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
f0100899:	c7 04 24 77 38 10 f0 	movl   $0xf0103877,(%esp)
f01008a0:	e8 35 27 00 00       	call   f0102fda <strchr>
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
f01008bb:	bf 40 3a 10 f0       	mov    $0xf0103a40,%edi
f01008c0:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c5:	8b 07                	mov    (%edi),%eax
f01008c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ce:	89 04 24             	mov    %eax,(%esp)
f01008d1:	e8 80 26 00 00       	call   f0102f56 <strcmp>
f01008d6:	85 c0                	test   %eax,%eax
f01008d8:	75 24                	jne    f01008fe <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008da:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01008dd:	8b 55 08             	mov    0x8(%ebp),%edx
f01008e0:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008e4:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008e7:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008eb:	89 1c 24             	mov    %ebx,(%esp)
f01008ee:	ff 14 85 48 3a 10 f0 	call   *-0xfefc5b8(,%eax,4)


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
f0100910:	c7 04 24 99 38 10 f0 	movl   $0xf0103899,(%esp)
f0100917:	e8 4e 1b 00 00       	call   f010246a <cprintf>
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

f0100940 <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100940:	55                   	push   %ebp
f0100941:	89 e5                	mov    %esp,%ebp
f0100943:	53                   	push   %ebx
f0100944:	83 ec 14             	sub    $0x14,%esp
	if (PGNUM(pa) >= npages)
f0100947:	89 cb                	mov    %ecx,%ebx
f0100949:	c1 eb 0c             	shr    $0xc,%ebx
f010094c:	3b 1d 80 69 11 f0    	cmp    0xf0116980,%ebx
f0100952:	72 18                	jb     f010096c <_kaddr+0x2c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100954:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100958:	c7 44 24 08 64 3a 10 	movl   $0xf0103a64,0x8(%esp)
f010095f:	f0 
f0100960:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100964:	89 04 24             	mov    %eax,(%esp)
f0100967:	e8 28 f7 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010096c:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100972:	83 c4 14             	add    $0x14,%esp
f0100975:	5b                   	pop    %ebx
f0100976:	5d                   	pop    %ebp
f0100977:	c3                   	ret    

f0100978 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100978:	55                   	push   %ebp
f0100979:	89 e5                	mov    %esp,%ebp
f010097b:	53                   	push   %ebx
f010097c:	83 ec 04             	sub    $0x4,%esp
f010097f:	89 d3                	mov    %edx,%ebx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100981:	c1 ea 16             	shr    $0x16,%edx
//cprintf("#pgdir is %x #",KADDR(PTE_ADDR(*pgdir)));
	if (!(*pgdir & PTE_P))
f0100984:	8b 0c 90             	mov    (%eax,%edx,4),%ecx
		return ~0;
f0100987:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
//cprintf("#pgdir is %x #",KADDR(PTE_ADDR(*pgdir)));
	if (!(*pgdir & PTE_P))
f010098c:	f6 c1 01             	test   $0x1,%cl
f010098f:	74 37                	je     f01009c8 <check_va2pa+0x50>
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100991:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100997:	ba c9 02 00 00       	mov    $0x2c9,%edx
f010099c:	b8 b8 3f 10 f0       	mov    $0xf0103fb8,%eax
f01009a1:	e8 9a ff ff ff       	call   f0100940 <_kaddr>
//cprintf("#%d the p+PTX(va) is %x #\n",PTX(va), p + PTX(va));
	if (!(p[PTX(va)] & PTE_P))
f01009a6:	c1 eb 0c             	shr    $0xc,%ebx
f01009a9:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f01009af:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f01009b2:	89 c2                	mov    %eax,%edx
f01009b4:	83 e2 01             	and    $0x1,%edx
		return ~0;
	//cprintf("%x\n", PTE_ADDR(p[PTX(va)]));
	return PTE_ADDR(p[PTX(va)]);
f01009b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009bc:	85 d2                	test   %edx,%edx
f01009be:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009c3:	0f 44 c2             	cmove  %edx,%eax
f01009c6:	eb 00                	jmp    f01009c8 <check_va2pa+0x50>
}
f01009c8:	83 c4 04             	add    $0x4,%esp
f01009cb:	5b                   	pop    %ebx
f01009cc:	5d                   	pop    %ebp
f01009cd:	c3                   	ret    

f01009ce <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009ce:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009d0:	83 3d 5c 65 11 f0 00 	cmpl   $0x0,0xf011655c
f01009d7:	75 0f                	jne    f01009e8 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009d9:	b8 8b 79 11 f0       	mov    $0xf011798b,%eax
f01009de:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009e3:	a3 5c 65 11 f0       	mov    %eax,0xf011655c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f01009e8:	85 d2                	test   %edx,%edx
f01009ea:	75 06                	jne    f01009f2 <boot_alloc+0x24>
		return nextfree;
f01009ec:	a1 5c 65 11 f0       	mov    0xf011655c,%eax
f01009f1:	c3                   	ret    
	result = nextfree;
f01009f2:	a1 5c 65 11 f0       	mov    0xf011655c,%eax
	nextfree += (n/PGSIZE + 1)*PGSIZE;
f01009f7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009fd:	8d 94 10 00 10 00 00 	lea    0x1000(%eax,%edx,1),%edx
f0100a04:	89 15 5c 65 11 f0    	mov    %edx,0xf011655c
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
f0100a0a:	8b 0d 80 69 11 f0    	mov    0xf0116980,%ecx
f0100a10:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f0100a16:	c1 e1 0c             	shl    $0xc,%ecx
f0100a19:	39 ca                	cmp    %ecx,%edx
f0100a1b:	72 22                	jb     f0100a3f <boot_alloc+0x71>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a1d:	55                   	push   %ebp
f0100a1e:	89 e5                	mov    %esp,%ebp
f0100a20:	83 ec 18             	sub    $0x18,%esp
	if(n == 0)
		return nextfree;
	result = nextfree;
	nextfree += (n/PGSIZE + 1)*PGSIZE;
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
		panic("Run out of memory!!\n");
f0100a23:	c7 44 24 08 c4 3f 10 	movl   $0xf0103fc4,0x8(%esp)
f0100a2a:	f0 
f0100a2b:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
f0100a32:	00 
f0100a33:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0100a3a:	e8 55 f6 ff ff       	call   f0100094 <_panic>
	return result;
}
f0100a3f:	f3 c3                	repz ret 

f0100a41 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a41:	55                   	push   %ebp
f0100a42:	89 e5                	mov    %esp,%ebp
f0100a44:	56                   	push   %esi
f0100a45:	53                   	push   %ebx
f0100a46:	83 ec 10             	sub    $0x10,%esp
f0100a49:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a4b:	89 04 24             	mov    %eax,(%esp)
f0100a4e:	e8 a5 19 00 00       	call   f01023f8 <mc146818_read>
f0100a53:	89 c6                	mov    %eax,%esi
f0100a55:	83 c3 01             	add    $0x1,%ebx
f0100a58:	89 1c 24             	mov    %ebx,(%esp)
f0100a5b:	e8 98 19 00 00       	call   f01023f8 <mc146818_read>
f0100a60:	c1 e0 08             	shl    $0x8,%eax
f0100a63:	09 f0                	or     %esi,%eax
}
f0100a65:	83 c4 10             	add    $0x10,%esp
f0100a68:	5b                   	pop    %ebx
f0100a69:	5e                   	pop    %esi
f0100a6a:	5d                   	pop    %ebp
f0100a6b:	c3                   	ret    

f0100a6c <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a6c:	2b 05 88 69 11 f0    	sub    0xf0116988,%eax
f0100a72:	c1 f8 03             	sar    $0x3,%eax
f0100a75:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a78:	89 c2                	mov    %eax,%edx
f0100a7a:	c1 ea 0c             	shr    $0xc,%edx
f0100a7d:	3b 15 80 69 11 f0    	cmp    0xf0116980,%edx
f0100a83:	72 26                	jb     f0100aab <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct Page *pp)
{
f0100a85:	55                   	push   %ebp
f0100a86:	89 e5                	mov    %esp,%ebp
f0100a88:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a8f:	c7 44 24 08 64 3a 10 	movl   $0xf0103a64,0x8(%esp)
f0100a96:	f0 
f0100a97:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100a9e:	00 
f0100a9f:	c7 04 24 d9 3f 10 f0 	movl   $0xf0103fd9,(%esp)
f0100aa6:	e8 e9 f5 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100aab:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
}
f0100ab0:	c3                   	ret    

f0100ab1 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ab1:	55                   	push   %ebp
f0100ab2:	89 e5                	mov    %esp,%ebp
f0100ab4:	56                   	push   %esi
f0100ab5:	53                   	push   %ebx
f0100ab6:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
f0100ab9:	a1 88 69 11 f0       	mov    0xf0116988,%eax
f0100abe:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100ac4:	8b 35 58 65 11 f0    	mov    0xf0116558,%esi
f0100aca:	83 fe 01             	cmp    $0x1,%esi
f0100acd:	76 37                	jbe    f0100b06 <page_init+0x55>
f0100acf:	8b 1d 60 65 11 f0    	mov    0xf0116560,%ebx
f0100ad5:	b8 01 00 00 00       	mov    $0x1,%eax
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
f0100ada:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
		pages[i].pp_ref = 0;
f0100ae1:	8b 0d 88 69 11 f0    	mov    0xf0116988,%ecx
f0100ae7:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100aee:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0100af1:	8b 1d 88 69 11 f0    	mov    0xf0116988,%ebx
f0100af7:	01 d3                	add    %edx,%ebx
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100af9:	83 c0 01             	add    $0x1,%eax
f0100afc:	39 f0                	cmp    %esi,%eax
f0100afe:	72 da                	jb     f0100ada <page_init+0x29>
f0100b00:	89 1d 60 65 11 f0    	mov    %ebx,0xf0116560
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	size_t page_num = PADDR(boot_alloc(0)) / PGSIZE;
f0100b06:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b0b:	e8 be fe ff ff       	call   f01009ce <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b10:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b15:	77 20                	ja     f0100b37 <page_init+0x86>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b17:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b1b:	c7 44 24 08 88 3a 10 	movl   $0xf0103a88,0x8(%esp)
f0100b22:	f0 
f0100b23:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
f0100b2a:	00 
f0100b2b:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0100b32:	e8 5d f5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100b37:	05 00 00 00 10       	add    $0x10000000,%eax
f0100b3c:	c1 e8 0c             	shr    $0xc,%eax
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100b3f:	3b 05 80 69 11 f0    	cmp    0xf0116980,%eax
f0100b45:	73 39                	jae    f0100b80 <page_init+0xcf>
f0100b47:	8b 1d 60 65 11 f0    	mov    0xf0116560,%ebx
f0100b4d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100b54:	8b 0d 88 69 11 f0    	mov    0xf0116988,%ecx
f0100b5a:	01 d1                	add    %edx,%ecx
f0100b5c:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100b62:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100b64:	8b 1d 88 69 11 f0    	mov    0xf0116988,%ebx
f0100b6a:	01 d3                	add    %edx,%ebx
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100b6c:	83 c0 01             	add    $0x1,%eax
f0100b6f:	83 c2 08             	add    $0x8,%edx
f0100b72:	39 05 80 69 11 f0    	cmp    %eax,0xf0116980
f0100b78:	77 da                	ja     f0100b54 <page_init+0xa3>
f0100b7a:	89 1d 60 65 11 f0    	mov    %ebx,0xf0116560
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
//	panic("here");
	
}
f0100b80:	83 c4 10             	add    $0x10,%esp
f0100b83:	5b                   	pop    %ebx
f0100b84:	5e                   	pop    %esi
f0100b85:	5d                   	pop    %ebp
f0100b86:	c3                   	ret    

f0100b87 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100b87:	55                   	push   %ebp
f0100b88:	89 e5                	mov    %esp,%ebp
f0100b8a:	53                   	push   %ebx
f0100b8b:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(!page_free_list)
f0100b8e:	8b 1d 60 65 11 f0    	mov    0xf0116560,%ebx
f0100b94:	85 db                	test   %ebx,%ebx
f0100b96:	74 6b                	je     f0100c03 <page_alloc+0x7c>
		return NULL;
	struct Page *alloc_page = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100b98:	8b 03                	mov    (%ebx),%eax
f0100b9a:	a3 60 65 11 f0       	mov    %eax,0xf0116560
	alloc_page -> pp_link = NULL;
f0100b9f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100ba5:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ba9:	74 58                	je     f0100c03 <page_alloc+0x7c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bab:	89 d8                	mov    %ebx,%eax
f0100bad:	2b 05 88 69 11 f0    	sub    0xf0116988,%eax
f0100bb3:	c1 f8 03             	sar    $0x3,%eax
f0100bb6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bb9:	89 c2                	mov    %eax,%edx
f0100bbb:	c1 ea 0c             	shr    $0xc,%edx
f0100bbe:	3b 15 80 69 11 f0    	cmp    0xf0116980,%edx
f0100bc4:	72 20                	jb     f0100be6 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bca:	c7 44 24 08 64 3a 10 	movl   $0xf0103a64,0x8(%esp)
f0100bd1:	f0 
f0100bd2:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100bd9:	00 
f0100bda:	c7 04 24 d9 3f 10 f0 	movl   $0xf0103fd9,(%esp)
f0100be1:	e8 ae f4 ff ff       	call   f0100094 <_panic>
		memset(page2kva(alloc_page), 0, PGSIZE);
f0100be6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100bed:	00 
f0100bee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100bf5:	00 
	return (void *)(pa + KERNBASE);
f0100bf6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bfb:	89 04 24             	mov    %eax,(%esp)
f0100bfe:	e8 3c 24 00 00       	call   f010303f <memset>
	
	return alloc_page;
}
f0100c03:	89 d8                	mov    %ebx,%eax
f0100c05:	83 c4 14             	add    $0x14,%esp
f0100c08:	5b                   	pop    %ebx
f0100c09:	5d                   	pop    %ebp
f0100c0a:	c3                   	ret    

f0100c0b <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100c0b:	55                   	push   %ebp
f0100c0c:	89 e5                	mov    %esp,%ebp
f0100c0e:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if(pp -> pp_ref)	// If the ref is not 0, return
f0100c11:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100c16:	75 0d                	jne    f0100c25 <page_free+0x1a>
		return;
	pp->pp_link = page_free_list;
f0100c18:	8b 15 60 65 11 f0    	mov    0xf0116560,%edx
f0100c1e:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100c20:	a3 60 65 11 f0       	mov    %eax,0xf0116560
}
f0100c25:	5d                   	pop    %ebp
f0100c26:	c3                   	ret    

f0100c27 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100c27:	55                   	push   %ebp
f0100c28:	89 e5                	mov    %esp,%ebp
f0100c2a:	83 ec 04             	sub    $0x4,%esp
f0100c2d:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100c30:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100c34:	83 ea 01             	sub    $0x1,%edx
f0100c37:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100c3b:	66 85 d2             	test   %dx,%dx
f0100c3e:	75 08                	jne    f0100c48 <page_decref+0x21>
		page_free(pp);
f0100c40:	89 04 24             	mov    %eax,(%esp)
f0100c43:	e8 c3 ff ff ff       	call   f0100c0b <page_free>
}
f0100c48:	c9                   	leave  
f0100c49:	c3                   	ret    

f0100c4a <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{/* see the check_va2pa() */
f0100c4a:	55                   	push   %ebp
f0100c4b:	89 e5                	mov    %esp,%ebp
f0100c4d:	56                   	push   %esi
f0100c4e:	53                   	push   %ebx
f0100c4f:	83 ec 10             	sub    $0x10,%esp
f0100c52:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/* va is a linear address */
	pde_t *ptdir = pgdir + PDX(va);
f0100c55:	89 de                	mov    %ebx,%esi
f0100c57:	c1 ee 16             	shr    $0x16,%esi
f0100c5a:	c1 e6 02             	shl    $0x2,%esi
f0100c5d:	03 75 08             	add    0x8(%ebp),%esi
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
f0100c60:	8b 06                	mov    (%esi),%eax
f0100c62:	a8 01                	test   $0x1,%al
f0100c64:	74 44                	je     f0100caa <pgdir_walk+0x60>
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f0100c66:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c6b:	89 c2                	mov    %eax,%edx
f0100c6d:	c1 ea 0c             	shr    $0xc,%edx
f0100c70:	3b 15 80 69 11 f0    	cmp    0xf0116980,%edx
f0100c76:	72 20                	jb     f0100c98 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c78:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c7c:	c7 44 24 08 64 3a 10 	movl   $0xf0103a64,0x8(%esp)
f0100c83:	f0 
f0100c84:	c7 44 24 04 6c 01 00 	movl   $0x16c,0x4(%esp)
f0100c8b:	00 
f0100c8c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0100c93:	e8 fc f3 ff ff       	call   f0100094 <_panic>
f0100c98:	c1 eb 0a             	shr    $0xa,%ebx
f0100c9b:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100ca1:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100ca8:	eb 7c                	jmp    f0100d26 <pgdir_walk+0xdc>
	if(!create)
f0100caa:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100cae:	74 6a                	je     f0100d1a <pgdir_walk+0xd0>
		return NULL;
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
f0100cb0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100cb7:	e8 cb fe ff ff       	call   f0100b87 <page_alloc>
	if(!page_create)
f0100cbc:	85 c0                	test   %eax,%eax
f0100cbe:	74 61                	je     f0100d21 <pgdir_walk+0xd7>
		return NULL; /* allocation fails */
	page_create -> pp_ref++; /* reference count increase */
f0100cc0:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100cc5:	2b 05 88 69 11 f0    	sub    0xf0116988,%eax
f0100ccb:	c1 f8 03             	sar    $0x3,%eax
f0100cce:	c1 e0 0c             	shl    $0xc,%eax
	*ptdir = page2pa(page_create)|PTE_P|PTE_U; /* insert into the new page table page */
f0100cd1:	83 c8 05             	or     $0x5,%eax
f0100cd4:	89 06                	mov    %eax,(%esi)
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f0100cd6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cdb:	89 c2                	mov    %eax,%edx
f0100cdd:	c1 ea 0c             	shr    $0xc,%edx
f0100ce0:	3b 15 80 69 11 f0    	cmp    0xf0116980,%edx
f0100ce6:	72 20                	jb     f0100d08 <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ce8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cec:	c7 44 24 08 64 3a 10 	movl   $0xf0103a64,0x8(%esp)
f0100cf3:	f0 
f0100cf4:	c7 44 24 04 74 01 00 	movl   $0x174,0x4(%esp)
f0100cfb:	00 
f0100cfc:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0100d03:	e8 8c f3 ff ff       	call   f0100094 <_panic>
f0100d08:	c1 eb 0a             	shr    $0xa,%ebx
f0100d0b:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100d11:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100d18:	eb 0c                	jmp    f0100d26 <pgdir_walk+0xdc>
	pde_t *ptdir = pgdir + PDX(va);
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
	if(!create)
		return NULL;
f0100d1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d1f:	eb 05                	jmp    f0100d26 <pgdir_walk+0xdc>
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
	if(!page_create)
		return NULL; /* allocation fails */
f0100d21:	b8 00 00 00 00       	mov    $0x0,%eax
	page_create -> pp_ref++; /* reference count increase */
	*ptdir = page2pa(page_create)|PTE_P|PTE_U; /* insert into the new page table page */
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
}
f0100d26:	83 c4 10             	add    $0x10,%esp
f0100d29:	5b                   	pop    %ebx
f0100d2a:	5e                   	pop    %esi
f0100d2b:	5d                   	pop    %ebp
f0100d2c:	c3                   	ret    

f0100d2d <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100d2d:	55                   	push   %ebp
f0100d2e:	89 e5                	mov    %esp,%ebp
f0100d30:	53                   	push   %ebx
f0100d31:	83 ec 14             	sub    $0x14,%esp
f0100d34:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0100d37:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100d3e:	00 
f0100d3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d46:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d49:	89 04 24             	mov    %eax,(%esp)
f0100d4c:	e8 f9 fe ff ff       	call   f0100c4a <pgdir_walk>
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
f0100d51:	85 c0                	test   %eax,%eax
f0100d53:	74 43                	je     f0100d98 <page_lookup+0x6b>
f0100d55:	f6 00 01             	testb  $0x1,(%eax)
f0100d58:	74 45                	je     f0100d9f <page_lookup+0x72>
		return NULL;
	if(pte_store)
f0100d5a:	85 db                	test   %ebx,%ebx
f0100d5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100d60:	74 02                	je     f0100d64 <page_lookup+0x37>
		*pte_store = pte;
f0100d62:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f0100d64:	8b 00                	mov    (%eax),%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d66:	c1 e8 0c             	shr    $0xc,%eax
f0100d69:	3b 05 80 69 11 f0    	cmp    0xf0116980,%eax
f0100d6f:	72 1c                	jb     f0100d8d <page_lookup+0x60>
		panic("pa2page called with invalid pa");
f0100d71:	c7 44 24 08 ac 3a 10 	movl   $0xf0103aac,0x8(%esp)
f0100d78:	f0 
f0100d79:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0100d80:	00 
f0100d81:	c7 04 24 d9 3f 10 f0 	movl   $0xf0103fd9,(%esp)
f0100d88:	e8 07 f3 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0100d8d:	8b 15 88 69 11 f0    	mov    0xf0116988,%edx
f0100d93:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0100d96:	eb 0c                	jmp    f0100da4 <page_lookup+0x77>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
		return NULL;
f0100d98:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d9d:	eb 05                	jmp    f0100da4 <page_lookup+0x77>
f0100d9f:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f0100da4:	83 c4 14             	add    $0x14,%esp
f0100da7:	5b                   	pop    %ebx
f0100da8:	5d                   	pop    %ebp
f0100da9:	c3                   	ret    

f0100daa <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100daa:	55                   	push   %ebp
f0100dab:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100dad:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100db0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100db3:	5d                   	pop    %ebp
f0100db4:	c3                   	ret    

f0100db5 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100db5:	55                   	push   %ebp
f0100db6:	89 e5                	mov    %esp,%ebp
f0100db8:	83 ec 28             	sub    $0x28,%esp
f0100dbb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100dbe:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100dc1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100dc4:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct Page *pp = page_lookup(pgdir, va, &pte);
f0100dc7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100dca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dce:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100dd2:	89 1c 24             	mov    %ebx,(%esp)
f0100dd5:	e8 53 ff ff ff       	call   f0100d2d <page_lookup>
	if(!pp)
f0100dda:	85 c0                	test   %eax,%eax
f0100ddc:	74 1d                	je     f0100dfb <page_remove+0x46>
		return;
	page_decref(pp);
f0100dde:	89 04 24             	mov    %eax,(%esp)
f0100de1:	e8 41 fe ff ff       	call   f0100c27 <page_decref>
	*pte = 0;
f0100de6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100de9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f0100def:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100df3:	89 1c 24             	mov    %ebx,(%esp)
f0100df6:	e8 af ff ff ff       	call   f0100daa <tlb_invalidate>
	
}
f0100dfb:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100dfe:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100e01:	89 ec                	mov    %ebp,%esp
f0100e03:	5d                   	pop    %ebp
f0100e04:	c3                   	ret    

f0100e05 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0100e05:	55                   	push   %ebp
f0100e06:	89 e5                	mov    %esp,%ebp
f0100e08:	83 ec 28             	sub    $0x28,%esp
f0100e0b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100e0e:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100e11:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100e14:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e17:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f0100e1a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100e21:	00 
f0100e22:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e26:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e29:	89 04 24             	mov    %eax,(%esp)
f0100e2c:	e8 19 fe ff ff       	call   f0100c4a <pgdir_walk>
f0100e31:	89 c6                	mov    %eax,%esi
	if(!pte)
f0100e33:	85 c0                	test   %eax,%eax
f0100e35:	74 66                	je     f0100e9d <page_insert+0x98>
		return -E_NO_MEM;
	if(*pte & PTE_P) { /* already a page */
f0100e37:	8b 00                	mov    (%eax),%eax
f0100e39:	a8 01                	test   $0x1,%al
f0100e3b:	74 3c                	je     f0100e79 <page_insert+0x74>
		if(PTE_ADDR(*pte) == page2pa(pp)){	/* the same one */
f0100e3d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e42:	89 da                	mov    %ebx,%edx
f0100e44:	2b 15 88 69 11 f0    	sub    0xf0116988,%edx
f0100e4a:	c1 fa 03             	sar    $0x3,%edx
f0100e4d:	c1 e2 0c             	shl    $0xc,%edx
f0100e50:	39 d0                	cmp    %edx,%eax
f0100e52:	75 16                	jne    f0100e6a <page_insert+0x65>
			tlb_invalidate(pgdir, va);
f0100e54:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e58:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e5b:	89 04 24             	mov    %eax,(%esp)
f0100e5e:	e8 47 ff ff ff       	call   f0100daa <tlb_invalidate>
			pp -> pp_ref--;
f0100e63:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f0100e68:	eb 0f                	jmp    f0100e79 <page_insert+0x74>
		}else
			page_remove(pgdir, va);
f0100e6a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e71:	89 04 24             	mov    %eax,(%esp)
f0100e74:	e8 3c ff ff ff       	call   f0100db5 <page_remove>
	}
	*pte = page2pa(pp)|perm|PTE_P;
f0100e79:	8b 55 14             	mov    0x14(%ebp),%edx
f0100e7c:	83 ca 01             	or     $0x1,%edx
f0100e7f:	89 d8                	mov    %ebx,%eax
f0100e81:	2b 05 88 69 11 f0    	sub    0xf0116988,%eax
f0100e87:	c1 f8 03             	sar    $0x3,%eax
f0100e8a:	c1 e0 0c             	shl    $0xc,%eax
f0100e8d:	09 d0                	or     %edx,%eax
f0100e8f:	89 06                	mov    %eax,(%esi)
//	cprintf("*the value of the pte is %x*", pte);
	pp -> pp_ref++;
f0100e91:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f0100e96:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e9b:	eb 05                	jmp    f0100ea2 <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
	if(!pte)
		return -E_NO_MEM;
f0100e9d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*pte = page2pa(pp)|perm|PTE_P;
//	cprintf("*the value of the pte is %x*", pte);
	pp -> pp_ref++;
	return 0;
}
f0100ea2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100ea5:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100ea8:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100eab:	89 ec                	mov    %ebp,%esp
f0100ead:	5d                   	pop    %ebp
f0100eae:	c3                   	ret    

f0100eaf <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100eaf:	55                   	push   %ebp
f0100eb0:	89 e5                	mov    %esp,%ebp
f0100eb2:	57                   	push   %edi
f0100eb3:	56                   	push   %esi
f0100eb4:	53                   	push   %ebx
f0100eb5:	83 ec 4c             	sub    $0x4c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100eb8:	b8 15 00 00 00       	mov    $0x15,%eax
f0100ebd:	e8 7f fb ff ff       	call   f0100a41 <nvram_read>
f0100ec2:	c1 e0 0a             	shl    $0xa,%eax
f0100ec5:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100ecb:	85 c0                	test   %eax,%eax
f0100ecd:	0f 48 c2             	cmovs  %edx,%eax
f0100ed0:	c1 f8 0c             	sar    $0xc,%eax
f0100ed3:	a3 58 65 11 f0       	mov    %eax,0xf0116558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100ed8:	b8 17 00 00 00       	mov    $0x17,%eax
f0100edd:	e8 5f fb ff ff       	call   f0100a41 <nvram_read>
f0100ee2:	c1 e0 0a             	shl    $0xa,%eax
f0100ee5:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100eeb:	85 c0                	test   %eax,%eax
f0100eed:	0f 48 c2             	cmovs  %edx,%eax
f0100ef0:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100ef3:	85 c0                	test   %eax,%eax
f0100ef5:	74 0e                	je     f0100f05 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100ef7:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100efd:	89 15 80 69 11 f0    	mov    %edx,0xf0116980
f0100f03:	eb 0c                	jmp    f0100f11 <mem_init+0x62>
	else
		npages = npages_basemem;
f0100f05:	8b 15 58 65 11 f0    	mov    0xf0116558,%edx
f0100f0b:	89 15 80 69 11 f0    	mov    %edx,0xf0116980

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0100f11:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100f14:	c1 e8 0a             	shr    $0xa,%eax
f0100f17:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100f1b:	a1 58 65 11 f0       	mov    0xf0116558,%eax
f0100f20:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100f23:	c1 e8 0a             	shr    $0xa,%eax
f0100f26:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0100f2a:	a1 80 69 11 f0       	mov    0xf0116980,%eax
f0100f2f:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100f32:	c1 e8 0a             	shr    $0xa,%eax
f0100f35:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f39:	c7 04 24 cc 3a 10 f0 	movl   $0xf0103acc,(%esp)
f0100f40:	e8 25 15 00 00       	call   f010246a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100f45:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100f4a:	e8 7f fa ff ff       	call   f01009ce <boot_alloc>
f0100f4f:	a3 84 69 11 f0       	mov    %eax,0xf0116984
	memset(kern_pgdir, 0, PGSIZE);
f0100f54:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f5b:	00 
f0100f5c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f63:	00 
f0100f64:	89 04 24             	mov    %eax,(%esp)
f0100f67:	e8 d3 20 00 00       	call   f010303f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100f6c:	a1 84 69 11 f0       	mov    0xf0116984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f71:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f76:	77 20                	ja     f0100f98 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f78:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f7c:	c7 44 24 08 88 3a 10 	movl   $0xf0103a88,0x8(%esp)
f0100f83:	f0 
f0100f84:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
f0100f8b:	00 
f0100f8c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0100f93:	e8 fc f0 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100f98:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100f9e:	83 ca 05             	or     $0x5,%edx
f0100fa1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page *)boot_alloc(npages * sizeof(struct Page));
f0100fa7:	a1 80 69 11 f0       	mov    0xf0116980,%eax
f0100fac:	c1 e0 03             	shl    $0x3,%eax
f0100faf:	e8 1a fa ff ff       	call   f01009ce <boot_alloc>
f0100fb4:	a3 88 69 11 f0       	mov    %eax,0xf0116988
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100fb9:	e8 f3 fa ff ff       	call   f0100ab1 <page_init>
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100fbe:	a1 60 65 11 f0       	mov    0xf0116560,%eax
f0100fc3:	85 c0                	test   %eax,%eax
f0100fc5:	75 1c                	jne    f0100fe3 <mem_init+0x134>
		panic("'page_free_list' is a null pointer!");
f0100fc7:	c7 44 24 08 08 3b 10 	movl   $0xf0103b08,0x8(%esp)
f0100fce:	f0 
f0100fcf:	c7 44 24 04 0c 02 00 	movl   $0x20c,0x4(%esp)
f0100fd6:	00 
f0100fd7:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0100fde:	e8 b1 f0 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100fe3:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100fe6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100fe9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100fec:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fef:	89 c2                	mov    %eax,%edx
f0100ff1:	2b 15 88 69 11 f0    	sub    0xf0116988,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ff7:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ffd:	0f 95 c2             	setne  %dl
f0101000:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0101003:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0101007:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0101009:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f010100d:	8b 00                	mov    (%eax),%eax
f010100f:	85 c0                	test   %eax,%eax
f0101011:	75 dc                	jne    f0100fef <mem_init+0x140>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0101013:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101016:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f010101c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010101f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101022:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0101024:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101027:	89 1d 60 65 11 f0    	mov    %ebx,0xf0116560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010102d:	85 db                	test   %ebx,%ebx
f010102f:	74 68                	je     f0101099 <mem_init+0x1ea>
f0101031:	89 d8                	mov    %ebx,%eax
f0101033:	2b 05 88 69 11 f0    	sub    0xf0116988,%eax
f0101039:	c1 f8 03             	sar    $0x3,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f010103c:	89 c2                	mov    %eax,%edx
f010103e:	c1 e2 0c             	shl    $0xc,%edx
f0101041:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0101046:	75 4b                	jne    f0101093 <mem_init+0x1e4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101048:	89 d0                	mov    %edx,%eax
f010104a:	c1 e8 0c             	shr    $0xc,%eax
f010104d:	3b 05 80 69 11 f0    	cmp    0xf0116980,%eax
f0101053:	72 20                	jb     f0101075 <mem_init+0x1c6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101055:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101059:	c7 44 24 08 64 3a 10 	movl   $0xf0103a64,0x8(%esp)
f0101060:	f0 
f0101061:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101068:	00 
f0101069:	c7 04 24 d9 3f 10 f0 	movl   $0xf0103fd9,(%esp)
f0101070:	e8 1f f0 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0101075:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f010107c:	00 
f010107d:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0101084:	00 
	return (void *)(pa + KERNBASE);
f0101085:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010108b:	89 14 24             	mov    %edx,(%esp)
f010108e:	e8 ac 1f 00 00       	call   f010303f <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101093:	8b 1b                	mov    (%ebx),%ebx
f0101095:	85 db                	test   %ebx,%ebx
f0101097:	75 98                	jne    f0101031 <mem_init+0x182>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0101099:	b8 00 00 00 00       	mov    $0x0,%eax
f010109e:	e8 2b f9 ff ff       	call   f01009ce <boot_alloc>
f01010a3:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010a6:	a1 60 65 11 f0       	mov    0xf0116560,%eax
f01010ab:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01010ae:	85 c0                	test   %eax,%eax
f01010b0:	0f 84 f8 01 00 00    	je     f01012ae <mem_init+0x3ff>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01010b6:	8b 1d 88 69 11 f0    	mov    0xf0116988,%ebx
f01010bc:	39 c3                	cmp    %eax,%ebx
f01010be:	77 4f                	ja     f010110f <mem_init+0x260>
		assert(pp < pages + npages);
f01010c0:	8b 15 80 69 11 f0    	mov    0xf0116980,%edx
f01010c6:	89 55 cc             	mov    %edx,-0x34(%ebp)
f01010c9:	8d 0c d3             	lea    (%ebx,%edx,8),%ecx
f01010cc:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01010cf:	39 c8                	cmp    %ecx,%eax
f01010d1:	73 65                	jae    f0101138 <mem_init+0x289>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01010d3:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f01010d6:	29 d8                	sub    %ebx,%eax
f01010d8:	a8 07                	test   $0x7,%al
f01010da:	0f 85 85 00 00 00    	jne    f0101165 <mem_init+0x2b6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01010e0:	c1 f8 03             	sar    $0x3,%eax
f01010e3:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01010e6:	85 c0                	test   %eax,%eax
f01010e8:	0f 84 a5 00 00 00    	je     f0101193 <mem_init+0x2e4>
		assert(page2pa(pp) != IOPHYSMEM);
f01010ee:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01010f3:	0f 84 c5 00 00 00    	je     f01011be <mem_init+0x30f>
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010f9:	8b 55 c4             	mov    -0x3c(%ebp),%edx
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f01010fc:	be 00 00 00 00       	mov    $0x0,%esi
f0101101:	bf 00 00 00 00       	mov    $0x0,%edi
f0101106:	e9 d7 00 00 00       	jmp    f01011e2 <mem_init+0x333>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f010110b:	39 d3                	cmp    %edx,%ebx
f010110d:	76 24                	jbe    f0101133 <mem_init+0x284>
f010110f:	c7 44 24 0c e7 3f 10 	movl   $0xf0103fe7,0xc(%esp)
f0101116:	f0 
f0101117:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010111e:	f0 
f010111f:	c7 44 24 04 26 02 00 	movl   $0x226,0x4(%esp)
f0101126:	00 
f0101127:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010112e:	e8 61 ef ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0101133:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0101136:	72 24                	jb     f010115c <mem_init+0x2ad>
f0101138:	c7 44 24 0c 08 40 10 	movl   $0xf0104008,0xc(%esp)
f010113f:	f0 
f0101140:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101147:	f0 
f0101148:	c7 44 24 04 27 02 00 	movl   $0x227,0x4(%esp)
f010114f:	00 
f0101150:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101157:	e8 38 ef ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010115c:	89 d0                	mov    %edx,%eax
f010115e:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101161:	a8 07                	test   $0x7,%al
f0101163:	74 24                	je     f0101189 <mem_init+0x2da>
f0101165:	c7 44 24 0c 2c 3b 10 	movl   $0xf0103b2c,0xc(%esp)
f010116c:	f0 
f010116d:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101174:	f0 
f0101175:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
f010117c:	00 
f010117d:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101184:	e8 0b ef ff ff       	call   f0100094 <_panic>
f0101189:	c1 f8 03             	sar    $0x3,%eax
f010118c:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f010118f:	85 c0                	test   %eax,%eax
f0101191:	75 24                	jne    f01011b7 <mem_init+0x308>
f0101193:	c7 44 24 0c 1c 40 10 	movl   $0xf010401c,0xc(%esp)
f010119a:	f0 
f010119b:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01011a2:	f0 
f01011a3:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
f01011aa:	00 
f01011ab:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01011b2:	e8 dd ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01011b7:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01011bc:	75 24                	jne    f01011e2 <mem_init+0x333>
f01011be:	c7 44 24 0c 2d 40 10 	movl   $0xf010402d,0xc(%esp)
f01011c5:	f0 
f01011c6:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01011cd:	f0 
f01011ce:	c7 44 24 04 2c 02 00 	movl   $0x22c,0x4(%esp)
f01011d5:	00 
f01011d6:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01011dd:	e8 b2 ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01011e2:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f01011e7:	75 24                	jne    f010120d <mem_init+0x35e>
f01011e9:	c7 44 24 0c 60 3b 10 	movl   $0xf0103b60,0xc(%esp)
f01011f0:	f0 
f01011f1:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01011f8:	f0 
f01011f9:	c7 44 24 04 2d 02 00 	movl   $0x22d,0x4(%esp)
f0101200:	00 
f0101201:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101208:	e8 87 ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f010120d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101212:	75 24                	jne    f0101238 <mem_init+0x389>
f0101214:	c7 44 24 0c 46 40 10 	movl   $0xf0104046,0xc(%esp)
f010121b:	f0 
f010121c:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101223:	f0 
f0101224:	c7 44 24 04 2e 02 00 	movl   $0x22e,0x4(%esp)
f010122b:	00 
f010122c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101233:	e8 5c ee ff ff       	call   f0100094 <_panic>
f0101238:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f010123a:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f010123f:	76 57                	jbe    f0101298 <mem_init+0x3e9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101241:	c1 e8 0c             	shr    $0xc,%eax
f0101244:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101247:	77 20                	ja     f0101269 <mem_init+0x3ba>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101249:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010124d:	c7 44 24 08 64 3a 10 	movl   $0xf0103a64,0x8(%esp)
f0101254:	f0 
f0101255:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010125c:	00 
f010125d:	c7 04 24 d9 3f 10 f0 	movl   $0xf0103fd9,(%esp)
f0101264:	e8 2b ee ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101269:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f010126f:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0101272:	76 29                	jbe    f010129d <mem_init+0x3ee>
f0101274:	c7 44 24 0c 84 3b 10 	movl   $0xf0103b84,0xc(%esp)
f010127b:	f0 
f010127c:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101283:	f0 
f0101284:	c7 44 24 04 2f 02 00 	movl   $0x22f,0x4(%esp)
f010128b:	00 
f010128c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101293:	e8 fc ed ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0101298:	83 c7 01             	add    $0x1,%edi
f010129b:	eb 03                	jmp    f01012a0 <mem_init+0x3f1>
		else
			++nfree_extmem;
f010129d:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01012a0:	8b 12                	mov    (%edx),%edx
f01012a2:	85 d2                	test   %edx,%edx
f01012a4:	0f 85 61 fe ff ff    	jne    f010110b <mem_init+0x25c>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01012aa:	85 ff                	test   %edi,%edi
f01012ac:	7f 24                	jg     f01012d2 <mem_init+0x423>
f01012ae:	c7 44 24 0c 60 40 10 	movl   $0xf0104060,0xc(%esp)
f01012b5:	f0 
f01012b6:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01012bd:	f0 
f01012be:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f01012c5:	00 
f01012c6:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01012cd:	e8 c2 ed ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f01012d2:	85 f6                	test   %esi,%esi
f01012d4:	7f 24                	jg     f01012fa <mem_init+0x44b>
f01012d6:	c7 44 24 0c 72 40 10 	movl   $0xf0104072,0xc(%esp)
f01012dd:	f0 
f01012de:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01012e5:	f0 
f01012e6:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f01012ed:	00 
f01012ee:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01012f5:	e8 9a ed ff ff       	call   f0100094 <_panic>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01012fa:	85 db                	test   %ebx,%ebx
f01012fc:	75 1c                	jne    f010131a <mem_init+0x46b>
		panic("'pages' is a null pointer!");
f01012fe:	c7 44 24 08 83 40 10 	movl   $0xf0104083,0x8(%esp)
f0101305:	f0 
f0101306:	c7 44 24 04 49 02 00 	movl   $0x249,0x4(%esp)
f010130d:	00 
f010130e:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101315:	e8 7a ed ff ff       	call   f0100094 <_panic>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f010131a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010131f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
		++nfree;
f0101322:	83 c3 01             	add    $0x1,%ebx
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101325:	8b 00                	mov    (%eax),%eax
f0101327:	85 c0                	test   %eax,%eax
f0101329:	75 f7                	jne    f0101322 <mem_init+0x473>
		++nfree;
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010132b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101332:	e8 50 f8 ff ff       	call   f0100b87 <page_alloc>
f0101337:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010133a:	85 c0                	test   %eax,%eax
f010133c:	75 24                	jne    f0101362 <mem_init+0x4b3>
f010133e:	c7 44 24 0c 9e 40 10 	movl   $0xf010409e,0xc(%esp)
f0101345:	f0 
f0101346:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010134d:	f0 
f010134e:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
f0101355:	00 
f0101356:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010135d:	e8 32 ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101362:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101369:	e8 19 f8 ff ff       	call   f0100b87 <page_alloc>
f010136e:	89 c7                	mov    %eax,%edi
f0101370:	85 c0                	test   %eax,%eax
f0101372:	75 24                	jne    f0101398 <mem_init+0x4e9>
f0101374:	c7 44 24 0c b4 40 10 	movl   $0xf01040b4,0xc(%esp)
f010137b:	f0 
f010137c:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101383:	f0 
f0101384:	c7 44 24 04 50 02 00 	movl   $0x250,0x4(%esp)
f010138b:	00 
f010138c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101393:	e8 fc ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101398:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010139f:	e8 e3 f7 ff ff       	call   f0100b87 <page_alloc>
f01013a4:	89 c6                	mov    %eax,%esi
f01013a6:	85 c0                	test   %eax,%eax
f01013a8:	75 24                	jne    f01013ce <mem_init+0x51f>
f01013aa:	c7 44 24 0c ca 40 10 	movl   $0xf01040ca,0xc(%esp)
f01013b1:	f0 
f01013b2:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01013b9:	f0 
f01013ba:	c7 44 24 04 51 02 00 	movl   $0x251,0x4(%esp)
f01013c1:	00 
f01013c2:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01013c9:	e8 c6 ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013ce:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f01013d1:	75 24                	jne    f01013f7 <mem_init+0x548>
f01013d3:	c7 44 24 0c e0 40 10 	movl   $0xf01040e0,0xc(%esp)
f01013da:	f0 
f01013db:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01013e2:	f0 
f01013e3:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f01013ea:	00 
f01013eb:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01013f2:	e8 9d ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013f7:	39 c7                	cmp    %eax,%edi
f01013f9:	74 05                	je     f0101400 <mem_init+0x551>
f01013fb:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01013fe:	75 24                	jne    f0101424 <mem_init+0x575>
f0101400:	c7 44 24 0c cc 3b 10 	movl   $0xf0103bcc,0xc(%esp)
f0101407:	f0 
f0101408:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010140f:	f0 
f0101410:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f0101417:	00 
f0101418:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010141f:	e8 70 ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101424:	8b 15 88 69 11 f0    	mov    0xf0116988,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010142a:	a1 80 69 11 f0       	mov    0xf0116980,%eax
f010142f:	c1 e0 0c             	shl    $0xc,%eax
f0101432:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101435:	29 d1                	sub    %edx,%ecx
f0101437:	c1 f9 03             	sar    $0x3,%ecx
f010143a:	c1 e1 0c             	shl    $0xc,%ecx
f010143d:	39 c1                	cmp    %eax,%ecx
f010143f:	72 24                	jb     f0101465 <mem_init+0x5b6>
f0101441:	c7 44 24 0c f2 40 10 	movl   $0xf01040f2,0xc(%esp)
f0101448:	f0 
f0101449:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101450:	f0 
f0101451:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0101458:	00 
f0101459:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101460:	e8 2f ec ff ff       	call   f0100094 <_panic>
f0101465:	89 f9                	mov    %edi,%ecx
f0101467:	29 d1                	sub    %edx,%ecx
f0101469:	c1 f9 03             	sar    $0x3,%ecx
f010146c:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010146f:	39 c8                	cmp    %ecx,%eax
f0101471:	77 24                	ja     f0101497 <mem_init+0x5e8>
f0101473:	c7 44 24 0c 0f 41 10 	movl   $0xf010410f,0xc(%esp)
f010147a:	f0 
f010147b:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101482:	f0 
f0101483:	c7 44 24 04 57 02 00 	movl   $0x257,0x4(%esp)
f010148a:	00 
f010148b:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101492:	e8 fd eb ff ff       	call   f0100094 <_panic>
f0101497:	89 f1                	mov    %esi,%ecx
f0101499:	29 d1                	sub    %edx,%ecx
f010149b:	89 ca                	mov    %ecx,%edx
f010149d:	c1 fa 03             	sar    $0x3,%edx
f01014a0:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014a3:	39 d0                	cmp    %edx,%eax
f01014a5:	77 24                	ja     f01014cb <mem_init+0x61c>
f01014a7:	c7 44 24 0c 2c 41 10 	movl   $0xf010412c,0xc(%esp)
f01014ae:	f0 
f01014af:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01014b6:	f0 
f01014b7:	c7 44 24 04 58 02 00 	movl   $0x258,0x4(%esp)
f01014be:	00 
f01014bf:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01014c6:	e8 c9 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014cb:	a1 60 65 11 f0       	mov    0xf0116560,%eax
f01014d0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014d3:	c7 05 60 65 11 f0 00 	movl   $0x0,0xf0116560
f01014da:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014dd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014e4:	e8 9e f6 ff ff       	call   f0100b87 <page_alloc>
f01014e9:	85 c0                	test   %eax,%eax
f01014eb:	74 24                	je     f0101511 <mem_init+0x662>
f01014ed:	c7 44 24 0c 49 41 10 	movl   $0xf0104149,0xc(%esp)
f01014f4:	f0 
f01014f5:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01014fc:	f0 
f01014fd:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0101504:	00 
f0101505:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010150c:	e8 83 eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101511:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101514:	89 04 24             	mov    %eax,(%esp)
f0101517:	e8 ef f6 ff ff       	call   f0100c0b <page_free>
	page_free(pp1);
f010151c:	89 3c 24             	mov    %edi,(%esp)
f010151f:	e8 e7 f6 ff ff       	call   f0100c0b <page_free>
	page_free(pp2);
f0101524:	89 34 24             	mov    %esi,(%esp)
f0101527:	e8 df f6 ff ff       	call   f0100c0b <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010152c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101533:	e8 4f f6 ff ff       	call   f0100b87 <page_alloc>
f0101538:	89 c6                	mov    %eax,%esi
f010153a:	85 c0                	test   %eax,%eax
f010153c:	75 24                	jne    f0101562 <mem_init+0x6b3>
f010153e:	c7 44 24 0c 9e 40 10 	movl   $0xf010409e,0xc(%esp)
f0101545:	f0 
f0101546:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010154d:	f0 
f010154e:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f0101555:	00 
f0101556:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010155d:	e8 32 eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101562:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101569:	e8 19 f6 ff ff       	call   f0100b87 <page_alloc>
f010156e:	89 c7                	mov    %eax,%edi
f0101570:	85 c0                	test   %eax,%eax
f0101572:	75 24                	jne    f0101598 <mem_init+0x6e9>
f0101574:	c7 44 24 0c b4 40 10 	movl   $0xf01040b4,0xc(%esp)
f010157b:	f0 
f010157c:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101583:	f0 
f0101584:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f010158b:	00 
f010158c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101593:	e8 fc ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101598:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010159f:	e8 e3 f5 ff ff       	call   f0100b87 <page_alloc>
f01015a4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015a7:	85 c0                	test   %eax,%eax
f01015a9:	75 24                	jne    f01015cf <mem_init+0x720>
f01015ab:	c7 44 24 0c ca 40 10 	movl   $0xf01040ca,0xc(%esp)
f01015b2:	f0 
f01015b3:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01015ba:	f0 
f01015bb:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f01015c2:	00 
f01015c3:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01015ca:	e8 c5 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015cf:	39 fe                	cmp    %edi,%esi
f01015d1:	75 24                	jne    f01015f7 <mem_init+0x748>
f01015d3:	c7 44 24 0c e0 40 10 	movl   $0xf01040e0,0xc(%esp)
f01015da:	f0 
f01015db:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01015e2:	f0 
f01015e3:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f01015ea:	00 
f01015eb:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01015f2:	e8 9d ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f7:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01015fa:	74 05                	je     f0101601 <mem_init+0x752>
f01015fc:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01015ff:	75 24                	jne    f0101625 <mem_init+0x776>
f0101601:	c7 44 24 0c cc 3b 10 	movl   $0xf0103bcc,0xc(%esp)
f0101608:	f0 
f0101609:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101610:	f0 
f0101611:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f0101618:	00 
f0101619:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101620:	e8 6f ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101625:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010162c:	e8 56 f5 ff ff       	call   f0100b87 <page_alloc>
f0101631:	85 c0                	test   %eax,%eax
f0101633:	74 24                	je     f0101659 <mem_init+0x7aa>
f0101635:	c7 44 24 0c 49 41 10 	movl   $0xf0104149,0xc(%esp)
f010163c:	f0 
f010163d:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101644:	f0 
f0101645:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f010164c:	00 
f010164d:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101654:	e8 3b ea ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101659:	89 f0                	mov    %esi,%eax
f010165b:	e8 0c f4 ff ff       	call   f0100a6c <page2kva>
f0101660:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101667:	00 
f0101668:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010166f:	00 
f0101670:	89 04 24             	mov    %eax,(%esp)
f0101673:	e8 c7 19 00 00       	call   f010303f <memset>
	page_free(pp0);
f0101678:	89 34 24             	mov    %esi,(%esp)
f010167b:	e8 8b f5 ff ff       	call   f0100c0b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101680:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101687:	e8 fb f4 ff ff       	call   f0100b87 <page_alloc>
f010168c:	85 c0                	test   %eax,%eax
f010168e:	75 24                	jne    f01016b4 <mem_init+0x805>
f0101690:	c7 44 24 0c 58 41 10 	movl   $0xf0104158,0xc(%esp)
f0101697:	f0 
f0101698:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010169f:	f0 
f01016a0:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
f01016a7:	00 
f01016a8:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01016af:	e8 e0 e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01016b4:	39 c6                	cmp    %eax,%esi
f01016b6:	74 24                	je     f01016dc <mem_init+0x82d>
f01016b8:	c7 44 24 0c 76 41 10 	movl   $0xf0104176,0xc(%esp)
f01016bf:	f0 
f01016c0:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01016c7:	f0 
f01016c8:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f01016cf:	00 
f01016d0:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01016d7:	e8 b8 e9 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
f01016dc:	89 f0                	mov    %esi,%eax
f01016de:	e8 89 f3 ff ff       	call   f0100a6c <page2kva>
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01016e3:	80 38 00             	cmpb   $0x0,(%eax)
f01016e6:	75 0b                	jne    f01016f3 <mem_init+0x844>
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01016e8:	ba 01 00 00 00       	mov    $0x1,%edx
		assert(c[i] == 0);
f01016ed:	80 3c 10 00          	cmpb   $0x0,(%eax,%edx,1)
f01016f1:	74 24                	je     f0101717 <mem_init+0x868>
f01016f3:	c7 44 24 0c 86 41 10 	movl   $0xf0104186,0xc(%esp)
f01016fa:	f0 
f01016fb:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101702:	f0 
f0101703:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f010170a:	00 
f010170b:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101712:	e8 7d e9 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101717:	83 c2 01             	add    $0x1,%edx
f010171a:	81 fa 00 10 00 00    	cmp    $0x1000,%edx
f0101720:	75 cb                	jne    f01016ed <mem_init+0x83e>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101722:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101725:	89 15 60 65 11 f0    	mov    %edx,0xf0116560

	// free the pages we took
	page_free(pp0);
f010172b:	89 34 24             	mov    %esi,(%esp)
f010172e:	e8 d8 f4 ff ff       	call   f0100c0b <page_free>
	page_free(pp1);
f0101733:	89 3c 24             	mov    %edi,(%esp)
f0101736:	e8 d0 f4 ff ff       	call   f0100c0b <page_free>
	page_free(pp2);
f010173b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010173e:	89 04 24             	mov    %eax,(%esp)
f0101741:	e8 c5 f4 ff ff       	call   f0100c0b <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101746:	a1 60 65 11 f0       	mov    0xf0116560,%eax
f010174b:	85 c0                	test   %eax,%eax
f010174d:	74 09                	je     f0101758 <mem_init+0x8a9>
		--nfree;
f010174f:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101752:	8b 00                	mov    (%eax),%eax
f0101754:	85 c0                	test   %eax,%eax
f0101756:	75 f7                	jne    f010174f <mem_init+0x8a0>
		--nfree;
	assert(nfree == 0);
f0101758:	85 db                	test   %ebx,%ebx
f010175a:	74 24                	je     f0101780 <mem_init+0x8d1>
f010175c:	c7 44 24 0c 90 41 10 	movl   $0xf0104190,0xc(%esp)
f0101763:	f0 
f0101764:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010176b:	f0 
f010176c:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f0101773:	00 
f0101774:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010177b:	e8 14 e9 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101780:	c7 04 24 ec 3b 10 f0 	movl   $0xf0103bec,(%esp)
f0101787:	e8 de 0c 00 00       	call   f010246a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010178c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101793:	e8 ef f3 ff ff       	call   f0100b87 <page_alloc>
f0101798:	89 c7                	mov    %eax,%edi
f010179a:	85 c0                	test   %eax,%eax
f010179c:	75 24                	jne    f01017c2 <mem_init+0x913>
f010179e:	c7 44 24 0c 9e 40 10 	movl   $0xf010409e,0xc(%esp)
f01017a5:	f0 
f01017a6:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01017ad:	f0 
f01017ae:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f01017b5:	00 
f01017b6:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01017bd:	e8 d2 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01017c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c9:	e8 b9 f3 ff ff       	call   f0100b87 <page_alloc>
f01017ce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017d1:	85 c0                	test   %eax,%eax
f01017d3:	75 24                	jne    f01017f9 <mem_init+0x94a>
f01017d5:	c7 44 24 0c b4 40 10 	movl   $0xf01040b4,0xc(%esp)
f01017dc:	f0 
f01017dd:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01017e4:	f0 
f01017e5:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f01017ec:	00 
f01017ed:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01017f4:	e8 9b e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01017f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101800:	e8 82 f3 ff ff       	call   f0100b87 <page_alloc>
f0101805:	89 c3                	mov    %eax,%ebx
f0101807:	85 c0                	test   %eax,%eax
f0101809:	75 24                	jne    f010182f <mem_init+0x980>
f010180b:	c7 44 24 0c ca 40 10 	movl   $0xf01040ca,0xc(%esp)
f0101812:	f0 
f0101813:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010181a:	f0 
f010181b:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f0101822:	00 
f0101823:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010182a:	e8 65 e8 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010182f:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101832:	75 24                	jne    f0101858 <mem_init+0x9a9>
f0101834:	c7 44 24 0c e0 40 10 	movl   $0xf01040e0,0xc(%esp)
f010183b:	f0 
f010183c:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101843:	f0 
f0101844:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f010184b:	00 
f010184c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101853:	e8 3c e8 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101858:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010185b:	74 04                	je     f0101861 <mem_init+0x9b2>
f010185d:	39 c7                	cmp    %eax,%edi
f010185f:	75 24                	jne    f0101885 <mem_init+0x9d6>
f0101861:	c7 44 24 0c cc 3b 10 	movl   $0xf0103bcc,0xc(%esp)
f0101868:	f0 
f0101869:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101870:	f0 
f0101871:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
f0101878:	00 
f0101879:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101880:	e8 0f e8 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101885:	8b 15 60 65 11 f0    	mov    0xf0116560,%edx
f010188b:	89 55 c8             	mov    %edx,-0x38(%ebp)
	page_free_list = 0;
f010188e:	c7 05 60 65 11 f0 00 	movl   $0x0,0xf0116560
f0101895:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101898:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010189f:	e8 e3 f2 ff ff       	call   f0100b87 <page_alloc>
f01018a4:	85 c0                	test   %eax,%eax
f01018a6:	74 24                	je     f01018cc <mem_init+0xa1d>
f01018a8:	c7 44 24 0c 49 41 10 	movl   $0xf0104149,0xc(%esp)
f01018af:	f0 
f01018b0:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01018b7:	f0 
f01018b8:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f01018bf:	00 
f01018c0:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01018c7:	e8 c8 e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018cc:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01018cf:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018d3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01018da:	00 
f01018db:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f01018e0:	89 04 24             	mov    %eax,(%esp)
f01018e3:	e8 45 f4 ff ff       	call   f0100d2d <page_lookup>
f01018e8:	85 c0                	test   %eax,%eax
f01018ea:	74 24                	je     f0101910 <mem_init+0xa61>
f01018ec:	c7 44 24 0c 0c 3c 10 	movl   $0xf0103c0c,0xc(%esp)
f01018f3:	f0 
f01018f4:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01018fb:	f0 
f01018fc:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f0101903:	00 
f0101904:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010190b:	e8 84 e7 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101910:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101917:	00 
f0101918:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010191f:	00 
f0101920:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101923:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101927:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f010192c:	89 04 24             	mov    %eax,(%esp)
f010192f:	e8 d1 f4 ff ff       	call   f0100e05 <page_insert>
f0101934:	85 c0                	test   %eax,%eax
f0101936:	78 24                	js     f010195c <mem_init+0xaad>
f0101938:	c7 44 24 0c 44 3c 10 	movl   $0xf0103c44,0xc(%esp)
f010193f:	f0 
f0101940:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101947:	f0 
f0101948:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f010194f:	00 
f0101950:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101957:	e8 38 e7 ff ff       	call   f0100094 <_panic>
//panic("\n");
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010195c:	89 3c 24             	mov    %edi,(%esp)
f010195f:	e8 a7 f2 ff ff       	call   f0100c0b <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101964:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010196b:	00 
f010196c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101973:	00 
f0101974:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101977:	89 44 24 04          	mov    %eax,0x4(%esp)
f010197b:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101980:	89 04 24             	mov    %eax,(%esp)
f0101983:	e8 7d f4 ff ff       	call   f0100e05 <page_insert>
f0101988:	85 c0                	test   %eax,%eax
f010198a:	74 24                	je     f01019b0 <mem_init+0xb01>
f010198c:	c7 44 24 0c 74 3c 10 	movl   $0xf0103c74,0xc(%esp)
f0101993:	f0 
f0101994:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010199b:	f0 
f010199c:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f01019a3:	00 
f01019a4:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01019ab:	e8 e4 e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019b0:	8b 35 84 69 11 f0    	mov    0xf0116984,%esi
f01019b6:	8b 15 88 69 11 f0    	mov    0xf0116988,%edx
f01019bc:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01019bf:	8b 16                	mov    (%esi),%edx
f01019c1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019c7:	89 f8                	mov    %edi,%eax
f01019c9:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01019cc:	c1 f8 03             	sar    $0x3,%eax
f01019cf:	c1 e0 0c             	shl    $0xc,%eax
f01019d2:	39 c2                	cmp    %eax,%edx
f01019d4:	74 24                	je     f01019fa <mem_init+0xb4b>
f01019d6:	c7 44 24 0c a4 3c 10 	movl   $0xf0103ca4,0xc(%esp)
f01019dd:	f0 
f01019de:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01019e5:	f0 
f01019e6:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f01019ed:	00 
f01019ee:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01019f5:	e8 9a e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019fa:	ba 00 00 00 00       	mov    $0x0,%edx
f01019ff:	89 f0                	mov    %esi,%eax
f0101a01:	e8 72 ef ff ff       	call   f0100978 <check_va2pa>
f0101a06:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101a09:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101a0c:	c1 fa 03             	sar    $0x3,%edx
f0101a0f:	c1 e2 0c             	shl    $0xc,%edx
f0101a12:	39 d0                	cmp    %edx,%eax
f0101a14:	74 24                	je     f0101a3a <mem_init+0xb8b>
f0101a16:	c7 44 24 0c cc 3c 10 	movl   $0xf0103ccc,0xc(%esp)
f0101a1d:	f0 
f0101a1e:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101a25:	f0 
f0101a26:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0101a2d:	00 
f0101a2e:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101a35:	e8 5a e6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101a3a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a3d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a42:	74 24                	je     f0101a68 <mem_init+0xbb9>
f0101a44:	c7 44 24 0c 9b 41 10 	movl   $0xf010419b,0xc(%esp)
f0101a4b:	f0 
f0101a4c:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101a53:	f0 
f0101a54:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0101a5b:	00 
f0101a5c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101a63:	e8 2c e6 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101a68:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101a6d:	74 24                	je     f0101a93 <mem_init+0xbe4>
f0101a6f:	c7 44 24 0c ac 41 10 	movl   $0xf01041ac,0xc(%esp)
f0101a76:	f0 
f0101a77:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101a7e:	f0 
f0101a7f:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f0101a86:	00 
f0101a87:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101a8e:	e8 01 e6 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a93:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a9a:	00 
f0101a9b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101aa2:	00 
f0101aa3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101aa7:	89 34 24             	mov    %esi,(%esp)
f0101aaa:	e8 56 f3 ff ff       	call   f0100e05 <page_insert>
f0101aaf:	85 c0                	test   %eax,%eax
f0101ab1:	74 24                	je     f0101ad7 <mem_init+0xc28>
f0101ab3:	c7 44 24 0c fc 3c 10 	movl   $0xf0103cfc,0xc(%esp)
f0101aba:	f0 
f0101abb:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101ac2:	f0 
f0101ac3:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0101aca:	00 
f0101acb:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101ad2:	e8 bd e5 ff ff       	call   f0100094 <_panic>
	//panic("va2pa: %x,page %x", check_va2pa(kern_pgdir, PGSIZE), page2pa(pp2));
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ad7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101adc:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101ae1:	e8 92 ee ff ff       	call   f0100978 <check_va2pa>
f0101ae6:	89 da                	mov    %ebx,%edx
f0101ae8:	2b 15 88 69 11 f0    	sub    0xf0116988,%edx
f0101aee:	c1 fa 03             	sar    $0x3,%edx
f0101af1:	c1 e2 0c             	shl    $0xc,%edx
f0101af4:	39 d0                	cmp    %edx,%eax
f0101af6:	74 24                	je     f0101b1c <mem_init+0xc6d>
f0101af8:	c7 44 24 0c 38 3d 10 	movl   $0xf0103d38,0xc(%esp)
f0101aff:	f0 
f0101b00:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101b07:	f0 
f0101b08:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0101b0f:	00 
f0101b10:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101b17:	e8 78 e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b1c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b21:	74 24                	je     f0101b47 <mem_init+0xc98>
f0101b23:	c7 44 24 0c bd 41 10 	movl   $0xf01041bd,0xc(%esp)
f0101b2a:	f0 
f0101b2b:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101b32:	f0 
f0101b33:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f0101b3a:	00 
f0101b3b:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101b42:	e8 4d e5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b47:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b4e:	e8 34 f0 ff ff       	call   f0100b87 <page_alloc>
f0101b53:	85 c0                	test   %eax,%eax
f0101b55:	74 24                	je     f0101b7b <mem_init+0xccc>
f0101b57:	c7 44 24 0c 49 41 10 	movl   $0xf0104149,0xc(%esp)
f0101b5e:	f0 
f0101b5f:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101b66:	f0 
f0101b67:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101b6e:	00 
f0101b6f:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101b76:	e8 19 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b7b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b82:	00 
f0101b83:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b8a:	00 
f0101b8b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b8f:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101b94:	89 04 24             	mov    %eax,(%esp)
f0101b97:	e8 69 f2 ff ff       	call   f0100e05 <page_insert>
f0101b9c:	85 c0                	test   %eax,%eax
f0101b9e:	74 24                	je     f0101bc4 <mem_init+0xd15>
f0101ba0:	c7 44 24 0c fc 3c 10 	movl   $0xf0103cfc,0xc(%esp)
f0101ba7:	f0 
f0101ba8:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101baf:	f0 
f0101bb0:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101bb7:	00 
f0101bb8:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101bbf:	e8 d0 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bc4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bc9:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101bce:	e8 a5 ed ff ff       	call   f0100978 <check_va2pa>
f0101bd3:	89 da                	mov    %ebx,%edx
f0101bd5:	2b 15 88 69 11 f0    	sub    0xf0116988,%edx
f0101bdb:	c1 fa 03             	sar    $0x3,%edx
f0101bde:	c1 e2 0c             	shl    $0xc,%edx
f0101be1:	39 d0                	cmp    %edx,%eax
f0101be3:	74 24                	je     f0101c09 <mem_init+0xd5a>
f0101be5:	c7 44 24 0c 38 3d 10 	movl   $0xf0103d38,0xc(%esp)
f0101bec:	f0 
f0101bed:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101bf4:	f0 
f0101bf5:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0101bfc:	00 
f0101bfd:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101c04:	e8 8b e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c09:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c0e:	74 24                	je     f0101c34 <mem_init+0xd85>
f0101c10:	c7 44 24 0c bd 41 10 	movl   $0xf01041bd,0xc(%esp)
f0101c17:	f0 
f0101c18:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101c1f:	f0 
f0101c20:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101c27:	00 
f0101c28:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101c2f:	e8 60 e4 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c34:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c3b:	e8 47 ef ff ff       	call   f0100b87 <page_alloc>
f0101c40:	85 c0                	test   %eax,%eax
f0101c42:	74 24                	je     f0101c68 <mem_init+0xdb9>
f0101c44:	c7 44 24 0c 49 41 10 	movl   $0xf0104149,0xc(%esp)
f0101c4b:	f0 
f0101c4c:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101c53:	f0 
f0101c54:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0101c5b:	00 
f0101c5c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101c63:	e8 2c e4 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c68:	8b 35 84 69 11 f0    	mov    0xf0116984,%esi
f0101c6e:	8b 0e                	mov    (%esi),%ecx
f0101c70:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101c76:	ba 0f 03 00 00       	mov    $0x30f,%edx
f0101c7b:	b8 b8 3f 10 f0       	mov    $0xf0103fb8,%eax
f0101c80:	e8 bb ec ff ff       	call   f0100940 <_kaddr>
f0101c85:	89 45 dc             	mov    %eax,-0x24(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c88:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c8f:	00 
f0101c90:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101c97:	00 
f0101c98:	89 34 24             	mov    %esi,(%esp)
f0101c9b:	e8 aa ef ff ff       	call   f0100c4a <pgdir_walk>
f0101ca0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101ca3:	83 c2 04             	add    $0x4,%edx
f0101ca6:	39 d0                	cmp    %edx,%eax
f0101ca8:	74 24                	je     f0101cce <mem_init+0xe1f>
f0101caa:	c7 44 24 0c 68 3d 10 	movl   $0xf0103d68,0xc(%esp)
f0101cb1:	f0 
f0101cb2:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101cb9:	f0 
f0101cba:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101cc1:	00 
f0101cc2:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101cc9:	e8 c6 e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101cce:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101cd5:	00 
f0101cd6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101cdd:	00 
f0101cde:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ce2:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101ce7:	89 04 24             	mov    %eax,(%esp)
f0101cea:	e8 16 f1 ff ff       	call   f0100e05 <page_insert>
f0101cef:	85 c0                	test   %eax,%eax
f0101cf1:	74 24                	je     f0101d17 <mem_init+0xe68>
f0101cf3:	c7 44 24 0c a8 3d 10 	movl   $0xf0103da8,0xc(%esp)
f0101cfa:	f0 
f0101cfb:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101d02:	f0 
f0101d03:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101d0a:	00 
f0101d0b:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101d12:	e8 7d e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d17:	8b 35 84 69 11 f0    	mov    0xf0116984,%esi
f0101d1d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d22:	89 f0                	mov    %esi,%eax
f0101d24:	e8 4f ec ff ff       	call   f0100978 <check_va2pa>
f0101d29:	89 da                	mov    %ebx,%edx
f0101d2b:	2b 15 88 69 11 f0    	sub    0xf0116988,%edx
f0101d31:	c1 fa 03             	sar    $0x3,%edx
f0101d34:	c1 e2 0c             	shl    $0xc,%edx
f0101d37:	39 d0                	cmp    %edx,%eax
f0101d39:	74 24                	je     f0101d5f <mem_init+0xeb0>
f0101d3b:	c7 44 24 0c 38 3d 10 	movl   $0xf0103d38,0xc(%esp)
f0101d42:	f0 
f0101d43:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101d4a:	f0 
f0101d4b:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101d52:	00 
f0101d53:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101d5a:	e8 35 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101d5f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d64:	74 24                	je     f0101d8a <mem_init+0xedb>
f0101d66:	c7 44 24 0c bd 41 10 	movl   $0xf01041bd,0xc(%esp)
f0101d6d:	f0 
f0101d6e:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101d75:	f0 
f0101d76:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f0101d7d:	00 
f0101d7e:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101d85:	e8 0a e3 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d8a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d91:	00 
f0101d92:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d99:	00 
f0101d9a:	89 34 24             	mov    %esi,(%esp)
f0101d9d:	e8 a8 ee ff ff       	call   f0100c4a <pgdir_walk>
f0101da2:	f6 00 04             	testb  $0x4,(%eax)
f0101da5:	75 24                	jne    f0101dcb <mem_init+0xf1c>
f0101da7:	c7 44 24 0c e8 3d 10 	movl   $0xf0103de8,0xc(%esp)
f0101dae:	f0 
f0101daf:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101db6:	f0 
f0101db7:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101dbe:	00 
f0101dbf:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101dc6:	e8 c9 e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101dcb:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101dd0:	f6 00 04             	testb  $0x4,(%eax)
f0101dd3:	75 24                	jne    f0101df9 <mem_init+0xf4a>
f0101dd5:	c7 44 24 0c ce 41 10 	movl   $0xf01041ce,0xc(%esp)
f0101ddc:	f0 
f0101ddd:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101de4:	f0 
f0101de5:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101dec:	00 
f0101ded:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101df4:	e8 9b e2 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101df9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e00:	00 
f0101e01:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101e08:	00 
f0101e09:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101e0d:	89 04 24             	mov    %eax,(%esp)
f0101e10:	e8 f0 ef ff ff       	call   f0100e05 <page_insert>
f0101e15:	85 c0                	test   %eax,%eax
f0101e17:	78 24                	js     f0101e3d <mem_init+0xf8e>
f0101e19:	c7 44 24 0c 1c 3e 10 	movl   $0xf0103e1c,0xc(%esp)
f0101e20:	f0 
f0101e21:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101e28:	f0 
f0101e29:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101e30:	00 
f0101e31:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101e38:	e8 57 e2 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e3d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e44:	00 
f0101e45:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e4c:	00 
f0101e4d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e50:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e54:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101e59:	89 04 24             	mov    %eax,(%esp)
f0101e5c:	e8 a4 ef ff ff       	call   f0100e05 <page_insert>
f0101e61:	85 c0                	test   %eax,%eax
f0101e63:	74 24                	je     f0101e89 <mem_init+0xfda>
f0101e65:	c7 44 24 0c 54 3e 10 	movl   $0xf0103e54,0xc(%esp)
f0101e6c:	f0 
f0101e6d:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101e74:	f0 
f0101e75:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101e7c:	00 
f0101e7d:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101e84:	e8 0b e2 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e89:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e90:	00 
f0101e91:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e98:	00 
f0101e99:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101e9e:	89 04 24             	mov    %eax,(%esp)
f0101ea1:	e8 a4 ed ff ff       	call   f0100c4a <pgdir_walk>
f0101ea6:	f6 00 04             	testb  $0x4,(%eax)
f0101ea9:	74 24                	je     f0101ecf <mem_init+0x1020>
f0101eab:	c7 44 24 0c 90 3e 10 	movl   $0xf0103e90,0xc(%esp)
f0101eb2:	f0 
f0101eb3:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101eba:	f0 
f0101ebb:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101ec2:	00 
f0101ec3:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101eca:	e8 c5 e1 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ecf:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101ed4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ed7:	ba 00 00 00 00       	mov    $0x0,%edx
f0101edc:	e8 97 ea ff ff       	call   f0100978 <check_va2pa>
f0101ee1:	89 c6                	mov    %eax,%esi
f0101ee3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee6:	2b 05 88 69 11 f0    	sub    0xf0116988,%eax
f0101eec:	c1 f8 03             	sar    $0x3,%eax
f0101eef:	c1 e0 0c             	shl    $0xc,%eax
f0101ef2:	39 c6                	cmp    %eax,%esi
f0101ef4:	74 24                	je     f0101f1a <mem_init+0x106b>
f0101ef6:	c7 44 24 0c c8 3e 10 	movl   $0xf0103ec8,0xc(%esp)
f0101efd:	f0 
f0101efe:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101f05:	f0 
f0101f06:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101f0d:	00 
f0101f0e:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101f15:	e8 7a e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f1a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f1f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f22:	e8 51 ea ff ff       	call   f0100978 <check_va2pa>
f0101f27:	39 c6                	cmp    %eax,%esi
f0101f29:	74 24                	je     f0101f4f <mem_init+0x10a0>
f0101f2b:	c7 44 24 0c f4 3e 10 	movl   $0xf0103ef4,0xc(%esp)
f0101f32:	f0 
f0101f33:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101f3a:	f0 
f0101f3b:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101f42:	00 
f0101f43:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101f4a:	e8 45 e1 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f4f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f52:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101f57:	74 24                	je     f0101f7d <mem_init+0x10ce>
f0101f59:	c7 44 24 0c e4 41 10 	movl   $0xf01041e4,0xc(%esp)
f0101f60:	f0 
f0101f61:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101f68:	f0 
f0101f69:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101f70:	00 
f0101f71:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101f78:	e8 17 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0101f7d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f82:	74 24                	je     f0101fa8 <mem_init+0x10f9>
f0101f84:	c7 44 24 0c f5 41 10 	movl   $0xf01041f5,0xc(%esp)
f0101f8b:	f0 
f0101f8c:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101f93:	f0 
f0101f94:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101f9b:	00 
f0101f9c:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101fa3:	e8 ec e0 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101fa8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101faf:	e8 d3 eb ff ff       	call   f0100b87 <page_alloc>
f0101fb4:	85 c0                	test   %eax,%eax
f0101fb6:	74 04                	je     f0101fbc <mem_init+0x110d>
f0101fb8:	39 c3                	cmp    %eax,%ebx
f0101fba:	74 24                	je     f0101fe0 <mem_init+0x1131>
f0101fbc:	c7 44 24 0c 24 3f 10 	movl   $0xf0103f24,0xc(%esp)
f0101fc3:	f0 
f0101fc4:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0101fcb:	f0 
f0101fcc:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0101fd3:	00 
f0101fd4:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0101fdb:	e8 b4 e0 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101fe0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101fe7:	00 
f0101fe8:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0101fed:	89 04 24             	mov    %eax,(%esp)
f0101ff0:	e8 c0 ed ff ff       	call   f0100db5 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ff5:	8b 35 84 69 11 f0    	mov    0xf0116984,%esi
f0101ffb:	ba 00 00 00 00       	mov    $0x0,%edx
f0102000:	89 f0                	mov    %esi,%eax
f0102002:	e8 71 e9 ff ff       	call   f0100978 <check_va2pa>
f0102007:	83 f8 ff             	cmp    $0xffffffff,%eax
f010200a:	74 24                	je     f0102030 <mem_init+0x1181>
f010200c:	c7 44 24 0c 48 3f 10 	movl   $0xf0103f48,0xc(%esp)
f0102013:	f0 
f0102014:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010201b:	f0 
f010201c:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0102023:	00 
f0102024:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010202b:	e8 64 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102030:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102035:	89 f0                	mov    %esi,%eax
f0102037:	e8 3c e9 ff ff       	call   f0100978 <check_va2pa>
f010203c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010203f:	2b 15 88 69 11 f0    	sub    0xf0116988,%edx
f0102045:	c1 fa 03             	sar    $0x3,%edx
f0102048:	c1 e2 0c             	shl    $0xc,%edx
f010204b:	39 d0                	cmp    %edx,%eax
f010204d:	74 24                	je     f0102073 <mem_init+0x11c4>
f010204f:	c7 44 24 0c f4 3e 10 	movl   $0xf0103ef4,0xc(%esp)
f0102056:	f0 
f0102057:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010205e:	f0 
f010205f:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102066:	00 
f0102067:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010206e:	e8 21 e0 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102073:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102076:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010207b:	74 24                	je     f01020a1 <mem_init+0x11f2>
f010207d:	c7 44 24 0c 9b 41 10 	movl   $0xf010419b,0xc(%esp)
f0102084:	f0 
f0102085:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010208c:	f0 
f010208d:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0102094:	00 
f0102095:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010209c:	e8 f3 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01020a1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020a6:	74 24                	je     f01020cc <mem_init+0x121d>
f01020a8:	c7 44 24 0c f5 41 10 	movl   $0xf01041f5,0xc(%esp)
f01020af:	f0 
f01020b0:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01020b7:	f0 
f01020b8:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f01020bf:	00 
f01020c0:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01020c7:	e8 c8 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020cc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020d3:	00 
f01020d4:	89 34 24             	mov    %esi,(%esp)
f01020d7:	e8 d9 ec ff ff       	call   f0100db5 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020dc:	8b 35 84 69 11 f0    	mov    0xf0116984,%esi
f01020e2:	ba 00 00 00 00       	mov    $0x0,%edx
f01020e7:	89 f0                	mov    %esi,%eax
f01020e9:	e8 8a e8 ff ff       	call   f0100978 <check_va2pa>
f01020ee:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020f1:	74 24                	je     f0102117 <mem_init+0x1268>
f01020f3:	c7 44 24 0c 48 3f 10 	movl   $0xf0103f48,0xc(%esp)
f01020fa:	f0 
f01020fb:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0102102:	f0 
f0102103:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f010210a:	00 
f010210b:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0102112:	e8 7d df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102117:	ba 00 10 00 00       	mov    $0x1000,%edx
f010211c:	89 f0                	mov    %esi,%eax
f010211e:	e8 55 e8 ff ff       	call   f0100978 <check_va2pa>
f0102123:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102126:	74 24                	je     f010214c <mem_init+0x129d>
f0102128:	c7 44 24 0c 6c 3f 10 	movl   $0xf0103f6c,0xc(%esp)
f010212f:	f0 
f0102130:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0102137:	f0 
f0102138:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f010213f:	00 
f0102140:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0102147:	e8 48 df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010214c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010214f:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102154:	74 24                	je     f010217a <mem_init+0x12cb>
f0102156:	c7 44 24 0c 06 42 10 	movl   $0xf0104206,0xc(%esp)
f010215d:	f0 
f010215e:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0102165:	f0 
f0102166:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f010216d:	00 
f010216e:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0102175:	e8 1a df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010217a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010217f:	74 24                	je     f01021a5 <mem_init+0x12f6>
f0102181:	c7 44 24 0c f5 41 10 	movl   $0xf01041f5,0xc(%esp)
f0102188:	f0 
f0102189:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0102190:	f0 
f0102191:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0102198:	00 
f0102199:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01021a0:	e8 ef de ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01021a5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021ac:	e8 d6 e9 ff ff       	call   f0100b87 <page_alloc>
f01021b1:	85 c0                	test   %eax,%eax
f01021b3:	74 05                	je     f01021ba <mem_init+0x130b>
f01021b5:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01021b8:	74 24                	je     f01021de <mem_init+0x132f>
f01021ba:	c7 44 24 0c 94 3f 10 	movl   $0xf0103f94,0xc(%esp)
f01021c1:	f0 
f01021c2:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01021c9:	f0 
f01021ca:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01021d1:	00 
f01021d2:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01021d9:	e8 b6 de ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01021de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021e5:	e8 9d e9 ff ff       	call   f0100b87 <page_alloc>
f01021ea:	85 c0                	test   %eax,%eax
f01021ec:	74 24                	je     f0102212 <mem_init+0x1363>
f01021ee:	c7 44 24 0c 49 41 10 	movl   $0xf0104149,0xc(%esp)
f01021f5:	f0 
f01021f6:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01021fd:	f0 
f01021fe:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0102205:	00 
f0102206:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010220d:	e8 82 de ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102212:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0102217:	8b 08                	mov    (%eax),%ecx
f0102219:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010221f:	89 fa                	mov    %edi,%edx
f0102221:	2b 15 88 69 11 f0    	sub    0xf0116988,%edx
f0102227:	c1 fa 03             	sar    $0x3,%edx
f010222a:	c1 e2 0c             	shl    $0xc,%edx
f010222d:	39 d1                	cmp    %edx,%ecx
f010222f:	74 24                	je     f0102255 <mem_init+0x13a6>
f0102231:	c7 44 24 0c a4 3c 10 	movl   $0xf0103ca4,0xc(%esp)
f0102238:	f0 
f0102239:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0102240:	f0 
f0102241:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0102248:	00 
f0102249:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0102250:	e8 3f de ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102255:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010225b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102260:	74 24                	je     f0102286 <mem_init+0x13d7>
f0102262:	c7 44 24 0c ac 41 10 	movl   $0xf01041ac,0xc(%esp)
f0102269:	f0 
f010226a:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f0102271:	f0 
f0102272:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0102279:	00 
f010227a:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f0102281:	e8 0e de ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102286:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010228c:	89 3c 24             	mov    %edi,(%esp)
f010228f:	e8 77 e9 ff ff       	call   f0100c0b <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102294:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010229b:	00 
f010229c:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01022a3:	00 
f01022a4:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f01022a9:	89 04 24             	mov    %eax,(%esp)
f01022ac:	e8 99 e9 ff ff       	call   f0100c4a <pgdir_walk>
f01022b1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01022b4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01022b7:	8b 35 84 69 11 f0    	mov    0xf0116984,%esi
f01022bd:	8b 4e 04             	mov    0x4(%esi),%ecx
f01022c0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01022c6:	ba 48 03 00 00       	mov    $0x348,%edx
f01022cb:	b8 b8 3f 10 f0       	mov    $0xf0103fb8,%eax
f01022d0:	e8 6b e6 ff ff       	call   f0100940 <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f01022d5:	83 c0 04             	add    $0x4,%eax
f01022d8:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01022db:	74 24                	je     f0102301 <mem_init+0x1452>
f01022dd:	c7 44 24 0c 17 42 10 	movl   $0xf0104217,0xc(%esp)
f01022e4:	f0 
f01022e5:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f01022ec:	f0 
f01022ed:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f01022f4:	00 
f01022f5:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01022fc:	e8 93 dd ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102301:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	pp0->pp_ref = 0;
f0102308:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010230e:	89 f8                	mov    %edi,%eax
f0102310:	e8 57 e7 ff ff       	call   f0100a6c <page2kva>
f0102315:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010231c:	00 
f010231d:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102324:	00 
f0102325:	89 04 24             	mov    %eax,(%esp)
f0102328:	e8 12 0d 00 00       	call   f010303f <memset>
	page_free(pp0);
f010232d:	89 3c 24             	mov    %edi,(%esp)
f0102330:	e8 d6 e8 ff ff       	call   f0100c0b <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102335:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010233c:	00 
f010233d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102344:	00 
f0102345:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f010234a:	89 04 24             	mov    %eax,(%esp)
f010234d:	e8 f8 e8 ff ff       	call   f0100c4a <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f0102352:	89 f8                	mov    %edi,%eax
f0102354:	e8 13 e7 ff ff       	call   f0100a6c <page2kva>
f0102359:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010235c:	f6 00 01             	testb  $0x1,(%eax)
f010235f:	75 0b                	jne    f010236c <mem_init+0x14bd>
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102361:	ba 01 00 00 00       	mov    $0x1,%edx
		assert((ptep[i] & PTE_P) == 0);
f0102366:	f6 04 90 01          	testb  $0x1,(%eax,%edx,4)
f010236a:	74 24                	je     f0102390 <mem_init+0x14e1>
f010236c:	c7 44 24 0c 2f 42 10 	movl   $0xf010422f,0xc(%esp)
f0102373:	f0 
f0102374:	c7 44 24 08 f3 3f 10 	movl   $0xf0103ff3,0x8(%esp)
f010237b:	f0 
f010237c:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0102383:	00 
f0102384:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f010238b:	e8 04 dd ff ff       	call   f0100094 <_panic>
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102390:	83 c2 01             	add    $0x1,%edx
f0102393:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f0102399:	75 cb                	jne    f0102366 <mem_init+0x14b7>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010239b:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f01023a0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01023a6:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// give free list back
	page_free_list = fl;
f01023ac:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01023af:	89 15 60 65 11 f0    	mov    %edx,0xf0116560

	// free the pages we took
	page_free(pp0);
f01023b5:	89 3c 24             	mov    %edi,(%esp)
f01023b8:	e8 4e e8 ff ff       	call   f0100c0b <page_free>
	page_free(pp1);
f01023bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023c0:	89 04 24             	mov    %eax,(%esp)
f01023c3:	e8 43 e8 ff ff       	call   f0100c0b <page_free>
	page_free(pp2);
f01023c8:	89 1c 24             	mov    %ebx,(%esp)
f01023cb:	e8 3b e8 ff ff       	call   f0100c0b <page_free>

	cprintf("check_page() succeeded!\n");
f01023d0:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01023d7:	e8 8e 00 00 00       	call   f010246a <cprintf>

	check_page_free_list(1);
	check_page_alloc();
//panic("Lab2-Part1 complete!\n");
	check_page();
panic("Lab2-Part2 complete!\n");
f01023dc:	c7 44 24 08 5f 42 10 	movl   $0xf010425f,0x8(%esp)
f01023e3:	f0 
f01023e4:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
f01023eb:	00 
f01023ec:	c7 04 24 b8 3f 10 f0 	movl   $0xf0103fb8,(%esp)
f01023f3:	e8 9c dc ff ff       	call   f0100094 <_panic>

f01023f8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01023f8:	55                   	push   %ebp
f01023f9:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01023fb:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01023ff:	ba 70 00 00 00       	mov    $0x70,%edx
f0102404:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102405:	b2 71                	mov    $0x71,%dl
f0102407:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102408:	0f b6 c0             	movzbl %al,%eax
}
f010240b:	5d                   	pop    %ebp
f010240c:	c3                   	ret    

f010240d <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010240d:	55                   	push   %ebp
f010240e:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102410:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102414:	ba 70 00 00 00       	mov    $0x70,%edx
f0102419:	ee                   	out    %al,(%dx)
f010241a:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f010241e:	b2 71                	mov    $0x71,%dl
f0102420:	ee                   	out    %al,(%dx)
f0102421:	5d                   	pop    %ebp
f0102422:	c3                   	ret    
f0102423:	90                   	nop

f0102424 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102424:	55                   	push   %ebp
f0102425:	89 e5                	mov    %esp,%ebp
f0102427:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010242a:	8b 45 08             	mov    0x8(%ebp),%eax
f010242d:	89 04 24             	mov    %eax,(%esp)
f0102430:	e8 c7 e1 ff ff       	call   f01005fc <cputchar>
	*cnt++;
}
f0102435:	c9                   	leave  
f0102436:	c3                   	ret    

f0102437 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102437:	55                   	push   %ebp
f0102438:	89 e5                	mov    %esp,%ebp
f010243a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010243d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102444:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102447:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010244b:	8b 45 08             	mov    0x8(%ebp),%eax
f010244e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102452:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102455:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102459:	c7 04 24 24 24 10 f0 	movl   $0xf0102424,(%esp)
f0102460:	e8 9d 04 00 00       	call   f0102902 <vprintfmt>
	return cnt;
}
f0102465:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102468:	c9                   	leave  
f0102469:	c3                   	ret    

f010246a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010246a:	55                   	push   %ebp
f010246b:	89 e5                	mov    %esp,%ebp
f010246d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102470:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102473:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102477:	8b 45 08             	mov    0x8(%ebp),%eax
f010247a:	89 04 24             	mov    %eax,(%esp)
f010247d:	e8 b5 ff ff ff       	call   f0102437 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102482:	c9                   	leave  
f0102483:	c3                   	ret    
f0102484:	66 90                	xchg   %ax,%ax
f0102486:	66 90                	xchg   %ax,%ax
f0102488:	66 90                	xchg   %ax,%ax
f010248a:	66 90                	xchg   %ax,%ax
f010248c:	66 90                	xchg   %ax,%ax
f010248e:	66 90                	xchg   %ax,%ax

f0102490 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102490:	55                   	push   %ebp
f0102491:	89 e5                	mov    %esp,%ebp
f0102493:	57                   	push   %edi
f0102494:	56                   	push   %esi
f0102495:	53                   	push   %ebx
f0102496:	83 ec 10             	sub    $0x10,%esp
f0102499:	89 c6                	mov    %eax,%esi
f010249b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010249e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01024a1:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01024a4:	8b 1a                	mov    (%edx),%ebx
f01024a6:	8b 09                	mov    (%ecx),%ecx
f01024a8:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01024ab:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f01024b2:	eb 77                	jmp    f010252b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01024b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01024b7:	01 d8                	add    %ebx,%eax
f01024b9:	b9 02 00 00 00       	mov    $0x2,%ecx
f01024be:	99                   	cltd   
f01024bf:	f7 f9                	idiv   %ecx
f01024c1:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01024c3:	eb 01                	jmp    f01024c6 <stab_binsearch+0x36>
			m--;
f01024c5:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01024c6:	39 d9                	cmp    %ebx,%ecx
f01024c8:	7c 1d                	jl     f01024e7 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01024ca:	6b d1 0c             	imul   $0xc,%ecx,%edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01024cd:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01024d2:	39 fa                	cmp    %edi,%edx
f01024d4:	75 ef                	jne    f01024c5 <stab_binsearch+0x35>
f01024d6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01024d9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01024dc:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f01024e0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01024e3:	73 18                	jae    f01024fd <stab_binsearch+0x6d>
f01024e5:	eb 05                	jmp    f01024ec <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01024e7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01024ea:	eb 3f                	jmp    f010252b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01024ec:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01024ef:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f01024f1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01024f4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01024fb:	eb 2e                	jmp    f010252b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01024fd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102500:	73 15                	jae    f0102517 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102502:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102505:	49                   	dec    %ecx
f0102506:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102509:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010250c:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010250e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102515:	eb 14                	jmp    f010252b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102517:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010251a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010251d:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f010251f:	ff 45 0c             	incl   0xc(%ebp)
f0102522:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102524:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f010252b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010252e:	7e 84                	jle    f01024b4 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102530:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102534:	75 0d                	jne    f0102543 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102536:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102539:	8b 02                	mov    (%edx),%eax
f010253b:	48                   	dec    %eax
f010253c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010253f:	89 01                	mov    %eax,(%ecx)
f0102541:	eb 22                	jmp    f0102565 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102543:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102546:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102548:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010254b:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010254d:	eb 01                	jmp    f0102550 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010254f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102550:	39 c1                	cmp    %eax,%ecx
f0102552:	7d 0c                	jge    f0102560 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102554:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102557:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010255c:	39 fa                	cmp    %edi,%edx
f010255e:	75 ef                	jne    f010254f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102560:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102563:	89 02                	mov    %eax,(%edx)
	}
}
f0102565:	83 c4 10             	add    $0x10,%esp
f0102568:	5b                   	pop    %ebx
f0102569:	5e                   	pop    %esi
f010256a:	5f                   	pop    %edi
f010256b:	5d                   	pop    %ebp
f010256c:	c3                   	ret    

f010256d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010256d:	55                   	push   %ebp
f010256e:	89 e5                	mov    %esp,%ebp
f0102570:	83 ec 38             	sub    $0x38,%esp
f0102573:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102576:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102579:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010257c:	8b 75 08             	mov    0x8(%ebp),%esi
f010257f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102582:	c7 03 75 42 10 f0    	movl   $0xf0104275,(%ebx)
	info->eip_line = 0;
f0102588:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010258f:	c7 43 08 75 42 10 f0 	movl   $0xf0104275,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102596:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010259d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01025a0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01025a7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01025ad:	76 12                	jbe    f01025c1 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01025af:	b8 ab b9 10 f0       	mov    $0xf010b9ab,%eax
f01025b4:	3d 2d 9c 10 f0       	cmp    $0xf0109c2d,%eax
f01025b9:	0f 86 99 01 00 00    	jbe    f0102758 <debuginfo_eip+0x1eb>
f01025bf:	eb 1c                	jmp    f01025dd <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01025c1:	c7 44 24 08 7f 42 10 	movl   $0xf010427f,0x8(%esp)
f01025c8:	f0 
f01025c9:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01025d0:	00 
f01025d1:	c7 04 24 8c 42 10 f0 	movl   $0xf010428c,(%esp)
f01025d8:	e8 b7 da ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01025dd:	80 3d aa b9 10 f0 00 	cmpb   $0x0,0xf010b9aa
f01025e4:	0f 85 75 01 00 00    	jne    f010275f <debuginfo_eip+0x1f2>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01025ea:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01025f1:	b8 2c 9c 10 f0       	mov    $0xf0109c2c,%eax
f01025f6:	2d a8 44 10 f0       	sub    $0xf01044a8,%eax
f01025fb:	c1 f8 02             	sar    $0x2,%eax
f01025fe:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102604:	83 e8 01             	sub    $0x1,%eax
f0102607:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010260a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010260e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102615:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102618:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010261b:	b8 a8 44 10 f0       	mov    $0xf01044a8,%eax
f0102620:	e8 6b fe ff ff       	call   f0102490 <stab_binsearch>
	if (lfile == 0)
f0102625:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102628:	85 c0                	test   %eax,%eax
f010262a:	0f 84 36 01 00 00    	je     f0102766 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102630:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102633:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102636:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102639:	89 74 24 04          	mov    %esi,0x4(%esp)
f010263d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102644:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102647:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010264a:	b8 a8 44 10 f0       	mov    $0xf01044a8,%eax
f010264f:	e8 3c fe ff ff       	call   f0102490 <stab_binsearch>

	if (lfun <= rfun) {
f0102654:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102657:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f010265a:	7f 2e                	jg     f010268a <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010265c:	6b c7 0c             	imul   $0xc,%edi,%eax
f010265f:	8d 90 a8 44 10 f0    	lea    -0xfefbb58(%eax),%edx
f0102665:	8b 80 a8 44 10 f0    	mov    -0xfefbb58(%eax),%eax
f010266b:	b9 ab b9 10 f0       	mov    $0xf010b9ab,%ecx
f0102670:	81 e9 2d 9c 10 f0    	sub    $0xf0109c2d,%ecx
f0102676:	39 c8                	cmp    %ecx,%eax
f0102678:	73 08                	jae    f0102682 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010267a:	05 2d 9c 10 f0       	add    $0xf0109c2d,%eax
f010267f:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102682:	8b 42 08             	mov    0x8(%edx),%eax
f0102685:	89 43 10             	mov    %eax,0x10(%ebx)
f0102688:	eb 06                	jmp    f0102690 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010268a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010268d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102690:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102697:	00 
f0102698:	8b 43 08             	mov    0x8(%ebx),%eax
f010269b:	89 04 24             	mov    %eax,(%esp)
f010269e:	e8 6d 09 00 00       	call   f0103010 <strfind>
f01026a3:	2b 43 08             	sub    0x8(%ebx),%eax
f01026a6:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01026a9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01026ac:	39 cf                	cmp    %ecx,%edi
f01026ae:	7c 62                	jl     f0102712 <debuginfo_eip+0x1a5>
	       && stabs[lline].n_type != N_SOL
f01026b0:	6b f7 0c             	imul   $0xc,%edi,%esi
f01026b3:	81 c6 a8 44 10 f0    	add    $0xf01044a8,%esi
f01026b9:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f01026bd:	80 fa 84             	cmp    $0x84,%dl
f01026c0:	74 31                	je     f01026f3 <debuginfo_eip+0x186>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01026c2:	8d 47 ff             	lea    -0x1(%edi),%eax
f01026c5:	6b c0 0c             	imul   $0xc,%eax,%eax
f01026c8:	05 a8 44 10 f0       	add    $0xf01044a8,%eax
f01026cd:	eb 15                	jmp    f01026e4 <debuginfo_eip+0x177>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01026cf:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01026d2:	39 cf                	cmp    %ecx,%edi
f01026d4:	7c 3c                	jl     f0102712 <debuginfo_eip+0x1a5>
	       && stabs[lline].n_type != N_SOL
f01026d6:	89 c6                	mov    %eax,%esi
f01026d8:	83 e8 0c             	sub    $0xc,%eax
f01026db:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f01026df:	80 fa 84             	cmp    $0x84,%dl
f01026e2:	74 0f                	je     f01026f3 <debuginfo_eip+0x186>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01026e4:	80 fa 64             	cmp    $0x64,%dl
f01026e7:	75 e6                	jne    f01026cf <debuginfo_eip+0x162>
f01026e9:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f01026ed:	74 e0                	je     f01026cf <debuginfo_eip+0x162>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01026ef:	39 f9                	cmp    %edi,%ecx
f01026f1:	7f 1f                	jg     f0102712 <debuginfo_eip+0x1a5>
f01026f3:	6b ff 0c             	imul   $0xc,%edi,%edi
f01026f6:	8b 87 a8 44 10 f0    	mov    -0xfefbb58(%edi),%eax
f01026fc:	ba ab b9 10 f0       	mov    $0xf010b9ab,%edx
f0102701:	81 ea 2d 9c 10 f0    	sub    $0xf0109c2d,%edx
f0102707:	39 d0                	cmp    %edx,%eax
f0102709:	73 07                	jae    f0102712 <debuginfo_eip+0x1a5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010270b:	05 2d 9c 10 f0       	add    $0xf0109c2d,%eax
f0102710:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102712:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102715:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102718:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010271d:	39 ca                	cmp    %ecx,%edx
f010271f:	7d 5f                	jge    f0102780 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f0102721:	8d 42 01             	lea    0x1(%edx),%eax
f0102724:	39 c1                	cmp    %eax,%ecx
f0102726:	7e 45                	jle    f010276d <debuginfo_eip+0x200>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102728:	6b f0 0c             	imul   $0xc,%eax,%esi
f010272b:	80 be ac 44 10 f0 a0 	cmpb   $0xa0,-0xfefbb54(%esi)
f0102732:	75 40                	jne    f0102774 <debuginfo_eip+0x207>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0102734:	6b d2 0c             	imul   $0xc,%edx,%edx
f0102737:	81 c2 a8 44 10 f0    	add    $0xf01044a8,%edx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010273d:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102741:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102744:	39 c1                	cmp    %eax,%ecx
f0102746:	7e 33                	jle    f010277b <debuginfo_eip+0x20e>
f0102748:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010274b:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f010274f:	74 ec                	je     f010273d <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102751:	b8 00 00 00 00       	mov    $0x0,%eax
f0102756:	eb 28                	jmp    f0102780 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102758:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010275d:	eb 21                	jmp    f0102780 <debuginfo_eip+0x213>
f010275f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102764:	eb 1a                	jmp    f0102780 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102766:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010276b:	eb 13                	jmp    f0102780 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010276d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102772:	eb 0c                	jmp    f0102780 <debuginfo_eip+0x213>
f0102774:	b8 00 00 00 00       	mov    $0x0,%eax
f0102779:	eb 05                	jmp    f0102780 <debuginfo_eip+0x213>
f010277b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102780:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0102783:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0102786:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0102789:	89 ec                	mov    %ebp,%esp
f010278b:	5d                   	pop    %ebp
f010278c:	c3                   	ret    
f010278d:	66 90                	xchg   %ax,%ax
f010278f:	90                   	nop

f0102790 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102790:	55                   	push   %ebp
f0102791:	89 e5                	mov    %esp,%ebp
f0102793:	57                   	push   %edi
f0102794:	56                   	push   %esi
f0102795:	53                   	push   %ebx
f0102796:	83 ec 4c             	sub    $0x4c,%esp
f0102799:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010279c:	89 d7                	mov    %edx,%edi
f010279e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01027a1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01027a4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01027a7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01027aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01027af:	39 d8                	cmp    %ebx,%eax
f01027b1:	72 17                	jb     f01027ca <printnum+0x3a>
f01027b3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01027b6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f01027b9:	76 0f                	jbe    f01027ca <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01027bb:	8b 75 14             	mov    0x14(%ebp),%esi
f01027be:	83 ee 01             	sub    $0x1,%esi
f01027c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027c4:	85 f6                	test   %esi,%esi
f01027c6:	7f 63                	jg     f010282b <printnum+0x9b>
f01027c8:	eb 75                	jmp    f010283f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01027ca:	8b 5d 18             	mov    0x18(%ebp),%ebx
f01027cd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f01027d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01027d4:	83 e8 01             	sub    $0x1,%eax
f01027d7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01027db:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01027de:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01027e2:	8b 44 24 08          	mov    0x8(%esp),%eax
f01027e6:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01027ea:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01027ed:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01027f0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01027f7:	00 
f01027f8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01027fb:	89 1c 24             	mov    %ebx,(%esp)
f01027fe:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102801:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102805:	e8 96 0a 00 00       	call   f01032a0 <__udivdi3>
f010280a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010280d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102810:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102814:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102818:	89 04 24             	mov    %eax,(%esp)
f010281b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010281f:	89 fa                	mov    %edi,%edx
f0102821:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102824:	e8 67 ff ff ff       	call   f0102790 <printnum>
f0102829:	eb 14                	jmp    f010283f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010282b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010282f:	8b 45 18             	mov    0x18(%ebp),%eax
f0102832:	89 04 24             	mov    %eax,(%esp)
f0102835:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102837:	83 ee 01             	sub    $0x1,%esi
f010283a:	75 ef                	jne    f010282b <printnum+0x9b>
f010283c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010283f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102843:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0102847:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010284a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010284e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102855:	00 
f0102856:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0102859:	89 1c 24             	mov    %ebx,(%esp)
f010285c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010285f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102863:	e8 88 0b 00 00       	call   f01033f0 <__umoddi3>
f0102868:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010286c:	0f be 80 9a 42 10 f0 	movsbl -0xfefbd66(%eax),%eax
f0102873:	89 04 24             	mov    %eax,(%esp)
f0102876:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102879:	ff d0                	call   *%eax
}
f010287b:	83 c4 4c             	add    $0x4c,%esp
f010287e:	5b                   	pop    %ebx
f010287f:	5e                   	pop    %esi
f0102880:	5f                   	pop    %edi
f0102881:	5d                   	pop    %ebp
f0102882:	c3                   	ret    

f0102883 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102883:	55                   	push   %ebp
f0102884:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102886:	83 fa 01             	cmp    $0x1,%edx
f0102889:	7e 0e                	jle    f0102899 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010288b:	8b 10                	mov    (%eax),%edx
f010288d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102890:	89 08                	mov    %ecx,(%eax)
f0102892:	8b 02                	mov    (%edx),%eax
f0102894:	8b 52 04             	mov    0x4(%edx),%edx
f0102897:	eb 22                	jmp    f01028bb <getuint+0x38>
	else if (lflag)
f0102899:	85 d2                	test   %edx,%edx
f010289b:	74 10                	je     f01028ad <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010289d:	8b 10                	mov    (%eax),%edx
f010289f:	8d 4a 04             	lea    0x4(%edx),%ecx
f01028a2:	89 08                	mov    %ecx,(%eax)
f01028a4:	8b 02                	mov    (%edx),%eax
f01028a6:	ba 00 00 00 00       	mov    $0x0,%edx
f01028ab:	eb 0e                	jmp    f01028bb <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01028ad:	8b 10                	mov    (%eax),%edx
f01028af:	8d 4a 04             	lea    0x4(%edx),%ecx
f01028b2:	89 08                	mov    %ecx,(%eax)
f01028b4:	8b 02                	mov    (%edx),%eax
f01028b6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01028bb:	5d                   	pop    %ebp
f01028bc:	c3                   	ret    

f01028bd <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01028bd:	55                   	push   %ebp
f01028be:	89 e5                	mov    %esp,%ebp
f01028c0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01028c3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01028c7:	8b 10                	mov    (%eax),%edx
f01028c9:	3b 50 04             	cmp    0x4(%eax),%edx
f01028cc:	73 0a                	jae    f01028d8 <sprintputch+0x1b>
		*b->buf++ = ch;
f01028ce:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01028d1:	88 0a                	mov    %cl,(%edx)
f01028d3:	83 c2 01             	add    $0x1,%edx
f01028d6:	89 10                	mov    %edx,(%eax)
}
f01028d8:	5d                   	pop    %ebp
f01028d9:	c3                   	ret    

f01028da <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01028da:	55                   	push   %ebp
f01028db:	89 e5                	mov    %esp,%ebp
f01028dd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01028e0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01028e3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028e7:	8b 45 10             	mov    0x10(%ebp),%eax
f01028ea:	89 44 24 08          	mov    %eax,0x8(%esp)
f01028ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01028f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01028f8:	89 04 24             	mov    %eax,(%esp)
f01028fb:	e8 02 00 00 00       	call   f0102902 <vprintfmt>
	va_end(ap);
}
f0102900:	c9                   	leave  
f0102901:	c3                   	ret    

f0102902 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102902:	55                   	push   %ebp
f0102903:	89 e5                	mov    %esp,%ebp
f0102905:	57                   	push   %edi
f0102906:	56                   	push   %esi
f0102907:	53                   	push   %ebx
f0102908:	83 ec 4c             	sub    $0x4c,%esp
f010290b:	8b 75 08             	mov    0x8(%ebp),%esi
f010290e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102911:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102914:	eb 11                	jmp    f0102927 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102916:	85 c0                	test   %eax,%eax
f0102918:	0f 84 db 03 00 00    	je     f0102cf9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
f010291e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102922:	89 04 24             	mov    %eax,(%esp)
f0102925:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102927:	0f b6 07             	movzbl (%edi),%eax
f010292a:	83 c7 01             	add    $0x1,%edi
f010292d:	83 f8 25             	cmp    $0x25,%eax
f0102930:	75 e4                	jne    f0102916 <vprintfmt+0x14>
f0102932:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0102936:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f010293d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0102944:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010294b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102950:	eb 2b                	jmp    f010297d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102952:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102955:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0102959:	eb 22                	jmp    f010297d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010295b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010295e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0102962:	eb 19                	jmp    f010297d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102964:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0102967:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010296e:	eb 0d                	jmp    f010297d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0102970:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102973:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102976:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010297d:	0f b6 0f             	movzbl (%edi),%ecx
f0102980:	8d 47 01             	lea    0x1(%edi),%eax
f0102983:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102986:	0f b6 07             	movzbl (%edi),%eax
f0102989:	83 e8 23             	sub    $0x23,%eax
f010298c:	3c 55                	cmp    $0x55,%al
f010298e:	0f 87 40 03 00 00    	ja     f0102cd4 <vprintfmt+0x3d2>
f0102994:	0f b6 c0             	movzbl %al,%eax
f0102997:	ff 24 85 24 43 10 f0 	jmp    *-0xfefbcdc(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010299e:	83 e9 30             	sub    $0x30,%ecx
f01029a1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f01029a4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f01029a8:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01029ab:	83 f9 09             	cmp    $0x9,%ecx
f01029ae:	77 57                	ja     f0102a07 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01029b0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01029b3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01029b6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01029b9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01029bc:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01029bf:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f01029c3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f01029c6:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01029c9:	83 f9 09             	cmp    $0x9,%ecx
f01029cc:	76 eb                	jbe    f01029b9 <vprintfmt+0xb7>
f01029ce:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01029d1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01029d4:	eb 34                	jmp    f0102a0a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01029d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01029d9:	8d 48 04             	lea    0x4(%eax),%ecx
f01029dc:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01029df:	8b 00                	mov    (%eax),%eax
f01029e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01029e4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01029e7:	eb 21                	jmp    f0102a0a <vprintfmt+0x108>

		case '.':
			if (width < 0)
f01029e9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01029ed:	0f 88 71 ff ff ff    	js     f0102964 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01029f3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01029f6:	eb 85                	jmp    f010297d <vprintfmt+0x7b>
f01029f8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01029fb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0102a02:	e9 76 ff ff ff       	jmp    f010297d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a07:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0102a0a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102a0e:	0f 89 69 ff ff ff    	jns    f010297d <vprintfmt+0x7b>
f0102a14:	e9 57 ff ff ff       	jmp    f0102970 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102a19:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a1c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102a1f:	e9 59 ff ff ff       	jmp    f010297d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102a24:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a27:	8d 50 04             	lea    0x4(%eax),%edx
f0102a2a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102a2d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102a31:	8b 00                	mov    (%eax),%eax
f0102a33:	89 04 24             	mov    %eax,(%esp)
f0102a36:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a38:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102a3b:	e9 e7 fe ff ff       	jmp    f0102927 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102a40:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a43:	8d 50 04             	lea    0x4(%eax),%edx
f0102a46:	89 55 14             	mov    %edx,0x14(%ebp)
f0102a49:	8b 00                	mov    (%eax),%eax
f0102a4b:	89 c2                	mov    %eax,%edx
f0102a4d:	c1 fa 1f             	sar    $0x1f,%edx
f0102a50:	31 d0                	xor    %edx,%eax
f0102a52:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102a54:	83 f8 06             	cmp    $0x6,%eax
f0102a57:	7f 0b                	jg     f0102a64 <vprintfmt+0x162>
f0102a59:	8b 14 85 7c 44 10 f0 	mov    -0xfefbb84(,%eax,4),%edx
f0102a60:	85 d2                	test   %edx,%edx
f0102a62:	75 20                	jne    f0102a84 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0102a64:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a68:	c7 44 24 08 b2 42 10 	movl   $0xf01042b2,0x8(%esp)
f0102a6f:	f0 
f0102a70:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102a74:	89 34 24             	mov    %esi,(%esp)
f0102a77:	e8 5e fe ff ff       	call   f01028da <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a7c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102a7f:	e9 a3 fe ff ff       	jmp    f0102927 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0102a84:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102a88:	c7 44 24 08 05 40 10 	movl   $0xf0104005,0x8(%esp)
f0102a8f:	f0 
f0102a90:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102a94:	89 34 24             	mov    %esi,(%esp)
f0102a97:	e8 3e fe ff ff       	call   f01028da <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a9c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102a9f:	e9 83 fe ff ff       	jmp    f0102927 <vprintfmt+0x25>
f0102aa4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102aa7:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0102aaa:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102aad:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ab0:	8d 50 04             	lea    0x4(%eax),%edx
f0102ab3:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ab6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102ab8:	85 ff                	test   %edi,%edi
f0102aba:	b8 ab 42 10 f0       	mov    $0xf01042ab,%eax
f0102abf:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102ac2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0102ac6:	74 06                	je     f0102ace <vprintfmt+0x1cc>
f0102ac8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0102acc:	7f 16                	jg     f0102ae4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102ace:	0f b6 17             	movzbl (%edi),%edx
f0102ad1:	0f be c2             	movsbl %dl,%eax
f0102ad4:	83 c7 01             	add    $0x1,%edi
f0102ad7:	85 c0                	test   %eax,%eax
f0102ad9:	0f 85 9f 00 00 00    	jne    f0102b7e <vprintfmt+0x27c>
f0102adf:	e9 8b 00 00 00       	jmp    f0102b6f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ae4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0102ae8:	89 3c 24             	mov    %edi,(%esp)
f0102aeb:	e8 92 03 00 00       	call   f0102e82 <strnlen>
f0102af0:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0102af3:	29 c2                	sub    %eax,%edx
f0102af5:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0102af8:	85 d2                	test   %edx,%edx
f0102afa:	7e d2                	jle    f0102ace <vprintfmt+0x1cc>
					putch(padc, putdat);
f0102afc:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0102b00:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102b03:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0102b06:	89 d7                	mov    %edx,%edi
f0102b08:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102b0c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b0f:	89 04 24             	mov    %eax,(%esp)
f0102b12:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102b14:	83 ef 01             	sub    $0x1,%edi
f0102b17:	75 ef                	jne    f0102b08 <vprintfmt+0x206>
f0102b19:	89 7d d8             	mov    %edi,-0x28(%ebp)
f0102b1c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102b1f:	eb ad                	jmp    f0102ace <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102b21:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0102b25:	74 20                	je     f0102b47 <vprintfmt+0x245>
f0102b27:	0f be d2             	movsbl %dl,%edx
f0102b2a:	83 ea 20             	sub    $0x20,%edx
f0102b2d:	83 fa 5e             	cmp    $0x5e,%edx
f0102b30:	76 15                	jbe    f0102b47 <vprintfmt+0x245>
					putch('?', putdat);
f0102b32:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b35:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102b39:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0102b40:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102b43:	ff d1                	call   *%ecx
f0102b45:	eb 0f                	jmp    f0102b56 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0102b47:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b4a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102b4e:	89 04 24             	mov    %eax,(%esp)
f0102b51:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102b54:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102b56:	83 eb 01             	sub    $0x1,%ebx
f0102b59:	0f b6 17             	movzbl (%edi),%edx
f0102b5c:	0f be c2             	movsbl %dl,%eax
f0102b5f:	83 c7 01             	add    $0x1,%edi
f0102b62:	85 c0                	test   %eax,%eax
f0102b64:	75 24                	jne    f0102b8a <vprintfmt+0x288>
f0102b66:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0102b69:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102b6c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b6f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102b72:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102b76:	0f 8e ab fd ff ff    	jle    f0102927 <vprintfmt+0x25>
f0102b7c:	eb 20                	jmp    f0102b9e <vprintfmt+0x29c>
f0102b7e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0102b81:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0102b84:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0102b87:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102b8a:	85 f6                	test   %esi,%esi
f0102b8c:	78 93                	js     f0102b21 <vprintfmt+0x21f>
f0102b8e:	83 ee 01             	sub    $0x1,%esi
f0102b91:	79 8e                	jns    f0102b21 <vprintfmt+0x21f>
f0102b93:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0102b96:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102b99:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102b9c:	eb d1                	jmp    f0102b6f <vprintfmt+0x26d>
f0102b9e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102ba1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102ba5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0102bac:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102bae:	83 ef 01             	sub    $0x1,%edi
f0102bb1:	75 ee                	jne    f0102ba1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bb3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102bb6:	e9 6c fd ff ff       	jmp    f0102927 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102bbb:	83 fa 01             	cmp    $0x1,%edx
f0102bbe:	66 90                	xchg   %ax,%ax
f0102bc0:	7e 16                	jle    f0102bd8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f0102bc2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bc5:	8d 50 08             	lea    0x8(%eax),%edx
f0102bc8:	89 55 14             	mov    %edx,0x14(%ebp)
f0102bcb:	8b 10                	mov    (%eax),%edx
f0102bcd:	8b 48 04             	mov    0x4(%eax),%ecx
f0102bd0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102bd3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102bd6:	eb 32                	jmp    f0102c0a <vprintfmt+0x308>
	else if (lflag)
f0102bd8:	85 d2                	test   %edx,%edx
f0102bda:	74 18                	je     f0102bf4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f0102bdc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bdf:	8d 50 04             	lea    0x4(%eax),%edx
f0102be2:	89 55 14             	mov    %edx,0x14(%ebp)
f0102be5:	8b 00                	mov    (%eax),%eax
f0102be7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102bea:	89 c1                	mov    %eax,%ecx
f0102bec:	c1 f9 1f             	sar    $0x1f,%ecx
f0102bef:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102bf2:	eb 16                	jmp    f0102c0a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f0102bf4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bf7:	8d 50 04             	lea    0x4(%eax),%edx
f0102bfa:	89 55 14             	mov    %edx,0x14(%ebp)
f0102bfd:	8b 00                	mov    (%eax),%eax
f0102bff:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c02:	89 c7                	mov    %eax,%edi
f0102c04:	c1 ff 1f             	sar    $0x1f,%edi
f0102c07:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102c0a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c0d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102c10:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102c15:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0102c19:	79 7d                	jns    f0102c98 <vprintfmt+0x396>
				putch('-', putdat);
f0102c1b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c1f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0102c26:	ff d6                	call   *%esi
				num = -(long long) num;
f0102c28:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c2b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102c2e:	f7 d8                	neg    %eax
f0102c30:	83 d2 00             	adc    $0x0,%edx
f0102c33:	f7 da                	neg    %edx
			}
			base = 10;
f0102c35:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102c3a:	eb 5c                	jmp    f0102c98 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102c3c:	8d 45 14             	lea    0x14(%ebp),%eax
f0102c3f:	e8 3f fc ff ff       	call   f0102883 <getuint>
			base = 10;
f0102c44:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102c49:	eb 4d                	jmp    f0102c98 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102c4b:	8d 45 14             	lea    0x14(%ebp),%eax
f0102c4e:	e8 30 fc ff ff       	call   f0102883 <getuint>
			base = 8;
f0102c53:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102c58:	eb 3e                	jmp    f0102c98 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
f0102c5a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c5e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0102c65:	ff d6                	call   *%esi
			putch('x', putdat);
f0102c67:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c6b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0102c72:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102c74:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c77:	8d 50 04             	lea    0x4(%eax),%edx
f0102c7a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102c7d:	8b 00                	mov    (%eax),%eax
f0102c7f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102c84:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102c89:	eb 0d                	jmp    f0102c98 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102c8b:	8d 45 14             	lea    0x14(%ebp),%eax
f0102c8e:	e8 f0 fb ff ff       	call   f0102883 <getuint>
			base = 16;
f0102c93:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102c98:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f0102c9c:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0102ca0:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0102ca3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102ca7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102cab:	89 04 24             	mov    %eax,(%esp)
f0102cae:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102cb2:	89 da                	mov    %ebx,%edx
f0102cb4:	89 f0                	mov    %esi,%eax
f0102cb6:	e8 d5 fa ff ff       	call   f0102790 <printnum>
			break;
f0102cbb:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102cbe:	e9 64 fc ff ff       	jmp    f0102927 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102cc3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102cc7:	89 0c 24             	mov    %ecx,(%esp)
f0102cca:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ccc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102ccf:	e9 53 fc ff ff       	jmp    f0102927 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102cd4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102cd8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0102cdf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102ce1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ce5:	0f 84 3c fc ff ff    	je     f0102927 <vprintfmt+0x25>
f0102ceb:	83 ef 01             	sub    $0x1,%edi
f0102cee:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102cf2:	75 f7                	jne    f0102ceb <vprintfmt+0x3e9>
f0102cf4:	e9 2e fc ff ff       	jmp    f0102927 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0102cf9:	83 c4 4c             	add    $0x4c,%esp
f0102cfc:	5b                   	pop    %ebx
f0102cfd:	5e                   	pop    %esi
f0102cfe:	5f                   	pop    %edi
f0102cff:	5d                   	pop    %ebp
f0102d00:	c3                   	ret    

f0102d01 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102d01:	55                   	push   %ebp
f0102d02:	89 e5                	mov    %esp,%ebp
f0102d04:	83 ec 28             	sub    $0x28,%esp
f0102d07:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d0a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102d0d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102d10:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102d14:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102d17:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102d1e:	85 d2                	test   %edx,%edx
f0102d20:	7e 30                	jle    f0102d52 <vsnprintf+0x51>
f0102d22:	85 c0                	test   %eax,%eax
f0102d24:	74 2c                	je     f0102d52 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102d26:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d29:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d2d:	8b 45 10             	mov    0x10(%ebp),%eax
f0102d30:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d34:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102d37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d3b:	c7 04 24 bd 28 10 f0 	movl   $0xf01028bd,(%esp)
f0102d42:	e8 bb fb ff ff       	call   f0102902 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102d47:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102d4a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102d4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d50:	eb 05                	jmp    f0102d57 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102d52:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102d57:	c9                   	leave  
f0102d58:	c3                   	ret    

f0102d59 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102d59:	55                   	push   %ebp
f0102d5a:	89 e5                	mov    %esp,%ebp
f0102d5c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102d5f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102d62:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d66:	8b 45 10             	mov    0x10(%ebp),%eax
f0102d69:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d6d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d70:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d74:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d77:	89 04 24             	mov    %eax,(%esp)
f0102d7a:	e8 82 ff ff ff       	call   f0102d01 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102d7f:	c9                   	leave  
f0102d80:	c3                   	ret    
f0102d81:	66 90                	xchg   %ax,%ax
f0102d83:	66 90                	xchg   %ax,%ax
f0102d85:	66 90                	xchg   %ax,%ax
f0102d87:	66 90                	xchg   %ax,%ax
f0102d89:	66 90                	xchg   %ax,%ax
f0102d8b:	66 90                	xchg   %ax,%ax
f0102d8d:	66 90                	xchg   %ax,%ax
f0102d8f:	90                   	nop

f0102d90 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102d90:	55                   	push   %ebp
f0102d91:	89 e5                	mov    %esp,%ebp
f0102d93:	57                   	push   %edi
f0102d94:	56                   	push   %esi
f0102d95:	53                   	push   %ebx
f0102d96:	83 ec 1c             	sub    $0x1c,%esp
f0102d99:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102d9c:	85 c0                	test   %eax,%eax
f0102d9e:	74 10                	je     f0102db0 <readline+0x20>
		cprintf("%s", prompt);
f0102da0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102da4:	c7 04 24 05 40 10 f0 	movl   $0xf0104005,(%esp)
f0102dab:	e8 ba f6 ff ff       	call   f010246a <cprintf>

	i = 0;
	echoing = iscons(0);
f0102db0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102db7:	e8 61 d8 ff ff       	call   f010061d <iscons>
f0102dbc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102dbe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102dc3:	e8 44 d8 ff ff       	call   f010060c <getchar>
f0102dc8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102dca:	85 c0                	test   %eax,%eax
f0102dcc:	79 17                	jns    f0102de5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0102dce:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102dd2:	c7 04 24 98 44 10 f0 	movl   $0xf0104498,(%esp)
f0102dd9:	e8 8c f6 ff ff       	call   f010246a <cprintf>
			return NULL;
f0102dde:	b8 00 00 00 00       	mov    $0x0,%eax
f0102de3:	eb 6d                	jmp    f0102e52 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102de5:	83 f8 7f             	cmp    $0x7f,%eax
f0102de8:	74 05                	je     f0102def <readline+0x5f>
f0102dea:	83 f8 08             	cmp    $0x8,%eax
f0102ded:	75 19                	jne    f0102e08 <readline+0x78>
f0102def:	85 f6                	test   %esi,%esi
f0102df1:	7e 15                	jle    f0102e08 <readline+0x78>
			if (echoing)
f0102df3:	85 ff                	test   %edi,%edi
f0102df5:	74 0c                	je     f0102e03 <readline+0x73>
				cputchar('\b');
f0102df7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0102dfe:	e8 f9 d7 ff ff       	call   f01005fc <cputchar>
			i--;
f0102e03:	83 ee 01             	sub    $0x1,%esi
f0102e06:	eb bb                	jmp    f0102dc3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102e08:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102e0e:	7f 1c                	jg     f0102e2c <readline+0x9c>
f0102e10:	83 fb 1f             	cmp    $0x1f,%ebx
f0102e13:	7e 17                	jle    f0102e2c <readline+0x9c>
			if (echoing)
f0102e15:	85 ff                	test   %edi,%edi
f0102e17:	74 08                	je     f0102e21 <readline+0x91>
				cputchar(c);
f0102e19:	89 1c 24             	mov    %ebx,(%esp)
f0102e1c:	e8 db d7 ff ff       	call   f01005fc <cputchar>
			buf[i++] = c;
f0102e21:	88 9e 80 65 11 f0    	mov    %bl,-0xfee9a80(%esi)
f0102e27:	83 c6 01             	add    $0x1,%esi
f0102e2a:	eb 97                	jmp    f0102dc3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0102e2c:	83 fb 0d             	cmp    $0xd,%ebx
f0102e2f:	74 05                	je     f0102e36 <readline+0xa6>
f0102e31:	83 fb 0a             	cmp    $0xa,%ebx
f0102e34:	75 8d                	jne    f0102dc3 <readline+0x33>
			if (echoing)
f0102e36:	85 ff                	test   %edi,%edi
f0102e38:	74 0c                	je     f0102e46 <readline+0xb6>
				cputchar('\n');
f0102e3a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0102e41:	e8 b6 d7 ff ff       	call   f01005fc <cputchar>
			buf[i] = 0;
f0102e46:	c6 86 80 65 11 f0 00 	movb   $0x0,-0xfee9a80(%esi)
			return buf;
f0102e4d:	b8 80 65 11 f0       	mov    $0xf0116580,%eax
		}
	}
}
f0102e52:	83 c4 1c             	add    $0x1c,%esp
f0102e55:	5b                   	pop    %ebx
f0102e56:	5e                   	pop    %esi
f0102e57:	5f                   	pop    %edi
f0102e58:	5d                   	pop    %ebp
f0102e59:	c3                   	ret    
f0102e5a:	66 90                	xchg   %ax,%ax
f0102e5c:	66 90                	xchg   %ax,%ax
f0102e5e:	66 90                	xchg   %ax,%ax

f0102e60 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102e60:	55                   	push   %ebp
f0102e61:	89 e5                	mov    %esp,%ebp
f0102e63:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102e66:	80 3a 00             	cmpb   $0x0,(%edx)
f0102e69:	74 10                	je     f0102e7b <strlen+0x1b>
f0102e6b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0102e70:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102e73:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102e77:	75 f7                	jne    f0102e70 <strlen+0x10>
f0102e79:	eb 05                	jmp    f0102e80 <strlen+0x20>
f0102e7b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0102e80:	5d                   	pop    %ebp
f0102e81:	c3                   	ret    

f0102e82 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102e82:	55                   	push   %ebp
f0102e83:	89 e5                	mov    %esp,%ebp
f0102e85:	53                   	push   %ebx
f0102e86:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0102e89:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102e8c:	85 c9                	test   %ecx,%ecx
f0102e8e:	74 1c                	je     f0102eac <strnlen+0x2a>
f0102e90:	80 3b 00             	cmpb   $0x0,(%ebx)
f0102e93:	74 1e                	je     f0102eb3 <strnlen+0x31>
f0102e95:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0102e9a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102e9c:	39 ca                	cmp    %ecx,%edx
f0102e9e:	74 18                	je     f0102eb8 <strnlen+0x36>
f0102ea0:	83 c2 01             	add    $0x1,%edx
f0102ea3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0102ea8:	75 f0                	jne    f0102e9a <strnlen+0x18>
f0102eaa:	eb 0c                	jmp    f0102eb8 <strnlen+0x36>
f0102eac:	b8 00 00 00 00       	mov    $0x0,%eax
f0102eb1:	eb 05                	jmp    f0102eb8 <strnlen+0x36>
f0102eb3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0102eb8:	5b                   	pop    %ebx
f0102eb9:	5d                   	pop    %ebp
f0102eba:	c3                   	ret    

f0102ebb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102ebb:	55                   	push   %ebp
f0102ebc:	89 e5                	mov    %esp,%ebp
f0102ebe:	53                   	push   %ebx
f0102ebf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ec2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102ec5:	89 c2                	mov    %eax,%edx
f0102ec7:	0f b6 19             	movzbl (%ecx),%ebx
f0102eca:	88 1a                	mov    %bl,(%edx)
f0102ecc:	83 c2 01             	add    $0x1,%edx
f0102ecf:	83 c1 01             	add    $0x1,%ecx
f0102ed2:	84 db                	test   %bl,%bl
f0102ed4:	75 f1                	jne    f0102ec7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102ed6:	5b                   	pop    %ebx
f0102ed7:	5d                   	pop    %ebp
f0102ed8:	c3                   	ret    

f0102ed9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102ed9:	55                   	push   %ebp
f0102eda:	89 e5                	mov    %esp,%ebp
f0102edc:	56                   	push   %esi
f0102edd:	53                   	push   %ebx
f0102ede:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ee1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102ee4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102ee7:	85 db                	test   %ebx,%ebx
f0102ee9:	74 16                	je     f0102f01 <strncpy+0x28>
		/* do nothing */;
	return ret;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f0102eeb:	01 f3                	add    %esi,%ebx
f0102eed:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f0102eef:	0f b6 02             	movzbl (%edx),%eax
f0102ef2:	88 01                	mov    %al,(%ecx)
f0102ef4:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102ef7:	80 3a 01             	cmpb   $0x1,(%edx)
f0102efa:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102efd:	39 d9                	cmp    %ebx,%ecx
f0102eff:	75 ee                	jne    f0102eef <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0102f01:	89 f0                	mov    %esi,%eax
f0102f03:	5b                   	pop    %ebx
f0102f04:	5e                   	pop    %esi
f0102f05:	5d                   	pop    %ebp
f0102f06:	c3                   	ret    

f0102f07 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0102f07:	55                   	push   %ebp
f0102f08:	89 e5                	mov    %esp,%ebp
f0102f0a:	57                   	push   %edi
f0102f0b:	56                   	push   %esi
f0102f0c:	53                   	push   %ebx
f0102f0d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102f10:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102f13:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102f16:	89 f8                	mov    %edi,%eax
f0102f18:	85 f6                	test   %esi,%esi
f0102f1a:	74 33                	je     f0102f4f <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f0102f1c:	83 fe 01             	cmp    $0x1,%esi
f0102f1f:	74 25                	je     f0102f46 <strlcpy+0x3f>
f0102f21:	0f b6 0b             	movzbl (%ebx),%ecx
f0102f24:	84 c9                	test   %cl,%cl
f0102f26:	74 22                	je     f0102f4a <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0102f28:	83 ee 02             	sub    $0x2,%esi
f0102f2b:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102f30:	88 08                	mov    %cl,(%eax)
f0102f32:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0102f35:	39 f2                	cmp    %esi,%edx
f0102f37:	74 13                	je     f0102f4c <strlcpy+0x45>
f0102f39:	83 c2 01             	add    $0x1,%edx
f0102f3c:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0102f40:	84 c9                	test   %cl,%cl
f0102f42:	75 ec                	jne    f0102f30 <strlcpy+0x29>
f0102f44:	eb 06                	jmp    f0102f4c <strlcpy+0x45>
f0102f46:	89 f8                	mov    %edi,%eax
f0102f48:	eb 02                	jmp    f0102f4c <strlcpy+0x45>
f0102f4a:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0102f4c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0102f4f:	29 f8                	sub    %edi,%eax
}
f0102f51:	5b                   	pop    %ebx
f0102f52:	5e                   	pop    %esi
f0102f53:	5f                   	pop    %edi
f0102f54:	5d                   	pop    %ebp
f0102f55:	c3                   	ret    

f0102f56 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0102f56:	55                   	push   %ebp
f0102f57:	89 e5                	mov    %esp,%ebp
f0102f59:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102f5c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102f5f:	0f b6 01             	movzbl (%ecx),%eax
f0102f62:	84 c0                	test   %al,%al
f0102f64:	74 15                	je     f0102f7b <strcmp+0x25>
f0102f66:	3a 02                	cmp    (%edx),%al
f0102f68:	75 11                	jne    f0102f7b <strcmp+0x25>
		p++, q++;
f0102f6a:	83 c1 01             	add    $0x1,%ecx
f0102f6d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0102f70:	0f b6 01             	movzbl (%ecx),%eax
f0102f73:	84 c0                	test   %al,%al
f0102f75:	74 04                	je     f0102f7b <strcmp+0x25>
f0102f77:	3a 02                	cmp    (%edx),%al
f0102f79:	74 ef                	je     f0102f6a <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102f7b:	0f b6 c0             	movzbl %al,%eax
f0102f7e:	0f b6 12             	movzbl (%edx),%edx
f0102f81:	29 d0                	sub    %edx,%eax
}
f0102f83:	5d                   	pop    %ebp
f0102f84:	c3                   	ret    

f0102f85 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0102f85:	55                   	push   %ebp
f0102f86:	89 e5                	mov    %esp,%ebp
f0102f88:	56                   	push   %esi
f0102f89:	53                   	push   %ebx
f0102f8a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0102f8d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102f90:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0102f93:	85 f6                	test   %esi,%esi
f0102f95:	74 29                	je     f0102fc0 <strncmp+0x3b>
f0102f97:	0f b6 03             	movzbl (%ebx),%eax
f0102f9a:	84 c0                	test   %al,%al
f0102f9c:	74 30                	je     f0102fce <strncmp+0x49>
f0102f9e:	3a 02                	cmp    (%edx),%al
f0102fa0:	75 2c                	jne    f0102fce <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0102fa2:	8d 43 01             	lea    0x1(%ebx),%eax
f0102fa5:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0102fa7:	89 c3                	mov    %eax,%ebx
f0102fa9:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0102fac:	39 f0                	cmp    %esi,%eax
f0102fae:	74 17                	je     f0102fc7 <strncmp+0x42>
f0102fb0:	0f b6 08             	movzbl (%eax),%ecx
f0102fb3:	84 c9                	test   %cl,%cl
f0102fb5:	74 17                	je     f0102fce <strncmp+0x49>
f0102fb7:	83 c0 01             	add    $0x1,%eax
f0102fba:	3a 0a                	cmp    (%edx),%cl
f0102fbc:	74 e9                	je     f0102fa7 <strncmp+0x22>
f0102fbe:	eb 0e                	jmp    f0102fce <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0102fc0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fc5:	eb 0f                	jmp    f0102fd6 <strncmp+0x51>
f0102fc7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fcc:	eb 08                	jmp    f0102fd6 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102fce:	0f b6 03             	movzbl (%ebx),%eax
f0102fd1:	0f b6 12             	movzbl (%edx),%edx
f0102fd4:	29 d0                	sub    %edx,%eax
}
f0102fd6:	5b                   	pop    %ebx
f0102fd7:	5e                   	pop    %esi
f0102fd8:	5d                   	pop    %ebp
f0102fd9:	c3                   	ret    

f0102fda <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0102fda:	55                   	push   %ebp
f0102fdb:	89 e5                	mov    %esp,%ebp
f0102fdd:	53                   	push   %ebx
f0102fde:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fe1:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0102fe4:	0f b6 18             	movzbl (%eax),%ebx
f0102fe7:	84 db                	test   %bl,%bl
f0102fe9:	74 1d                	je     f0103008 <strchr+0x2e>
f0102feb:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0102fed:	38 d3                	cmp    %dl,%bl
f0102fef:	75 06                	jne    f0102ff7 <strchr+0x1d>
f0102ff1:	eb 1a                	jmp    f010300d <strchr+0x33>
f0102ff3:	38 ca                	cmp    %cl,%dl
f0102ff5:	74 16                	je     f010300d <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0102ff7:	83 c0 01             	add    $0x1,%eax
f0102ffa:	0f b6 10             	movzbl (%eax),%edx
f0102ffd:	84 d2                	test   %dl,%dl
f0102fff:	75 f2                	jne    f0102ff3 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0103001:	b8 00 00 00 00       	mov    $0x0,%eax
f0103006:	eb 05                	jmp    f010300d <strchr+0x33>
f0103008:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010300d:	5b                   	pop    %ebx
f010300e:	5d                   	pop    %ebp
f010300f:	c3                   	ret    

f0103010 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103010:	55                   	push   %ebp
f0103011:	89 e5                	mov    %esp,%ebp
f0103013:	53                   	push   %ebx
f0103014:	8b 45 08             	mov    0x8(%ebp),%eax
f0103017:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010301a:	0f b6 18             	movzbl (%eax),%ebx
f010301d:	84 db                	test   %bl,%bl
f010301f:	74 1b                	je     f010303c <strfind+0x2c>
f0103021:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0103023:	38 d3                	cmp    %dl,%bl
f0103025:	75 0b                	jne    f0103032 <strfind+0x22>
f0103027:	eb 13                	jmp    f010303c <strfind+0x2c>
f0103029:	38 ca                	cmp    %cl,%dl
f010302b:	90                   	nop
f010302c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103030:	74 0a                	je     f010303c <strfind+0x2c>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103032:	83 c0 01             	add    $0x1,%eax
f0103035:	0f b6 10             	movzbl (%eax),%edx
f0103038:	84 d2                	test   %dl,%dl
f010303a:	75 ed                	jne    f0103029 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010303c:	5b                   	pop    %ebx
f010303d:	5d                   	pop    %ebp
f010303e:	c3                   	ret    

f010303f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010303f:	55                   	push   %ebp
f0103040:	89 e5                	mov    %esp,%ebp
f0103042:	83 ec 0c             	sub    $0xc,%esp
f0103045:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103048:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010304b:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010304e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103051:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103054:	85 c9                	test   %ecx,%ecx
f0103056:	74 36                	je     f010308e <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103058:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010305e:	75 28                	jne    f0103088 <memset+0x49>
f0103060:	f6 c1 03             	test   $0x3,%cl
f0103063:	75 23                	jne    f0103088 <memset+0x49>
		c &= 0xFF;
f0103065:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103069:	89 d3                	mov    %edx,%ebx
f010306b:	c1 e3 08             	shl    $0x8,%ebx
f010306e:	89 d6                	mov    %edx,%esi
f0103070:	c1 e6 18             	shl    $0x18,%esi
f0103073:	89 d0                	mov    %edx,%eax
f0103075:	c1 e0 10             	shl    $0x10,%eax
f0103078:	09 f0                	or     %esi,%eax
f010307a:	09 c2                	or     %eax,%edx
f010307c:	89 d0                	mov    %edx,%eax
f010307e:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103080:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103083:	fc                   	cld    
f0103084:	f3 ab                	rep stos %eax,%es:(%edi)
f0103086:	eb 06                	jmp    f010308e <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103088:	8b 45 0c             	mov    0xc(%ebp),%eax
f010308b:	fc                   	cld    
f010308c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010308e:	89 f8                	mov    %edi,%eax
f0103090:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103093:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103096:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103099:	89 ec                	mov    %ebp,%esp
f010309b:	5d                   	pop    %ebp
f010309c:	c3                   	ret    

f010309d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010309d:	55                   	push   %ebp
f010309e:	89 e5                	mov    %esp,%ebp
f01030a0:	83 ec 08             	sub    $0x8,%esp
f01030a3:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01030a6:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01030a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ac:	8b 75 0c             	mov    0xc(%ebp),%esi
f01030af:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01030b2:	39 c6                	cmp    %eax,%esi
f01030b4:	73 36                	jae    f01030ec <memmove+0x4f>
f01030b6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01030b9:	39 d0                	cmp    %edx,%eax
f01030bb:	73 2f                	jae    f01030ec <memmove+0x4f>
		s += n;
		d += n;
f01030bd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01030c0:	f6 c2 03             	test   $0x3,%dl
f01030c3:	75 1b                	jne    f01030e0 <memmove+0x43>
f01030c5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01030cb:	75 13                	jne    f01030e0 <memmove+0x43>
f01030cd:	f6 c1 03             	test   $0x3,%cl
f01030d0:	75 0e                	jne    f01030e0 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01030d2:	83 ef 04             	sub    $0x4,%edi
f01030d5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01030d8:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01030db:	fd                   	std    
f01030dc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01030de:	eb 09                	jmp    f01030e9 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01030e0:	83 ef 01             	sub    $0x1,%edi
f01030e3:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01030e6:	fd                   	std    
f01030e7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01030e9:	fc                   	cld    
f01030ea:	eb 20                	jmp    f010310c <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01030ec:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01030f2:	75 13                	jne    f0103107 <memmove+0x6a>
f01030f4:	a8 03                	test   $0x3,%al
f01030f6:	75 0f                	jne    f0103107 <memmove+0x6a>
f01030f8:	f6 c1 03             	test   $0x3,%cl
f01030fb:	75 0a                	jne    f0103107 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01030fd:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103100:	89 c7                	mov    %eax,%edi
f0103102:	fc                   	cld    
f0103103:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103105:	eb 05                	jmp    f010310c <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103107:	89 c7                	mov    %eax,%edi
f0103109:	fc                   	cld    
f010310a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010310c:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010310f:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103112:	89 ec                	mov    %ebp,%esp
f0103114:	5d                   	pop    %ebp
f0103115:	c3                   	ret    

f0103116 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103116:	55                   	push   %ebp
f0103117:	89 e5                	mov    %esp,%ebp
f0103119:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010311c:	8b 45 10             	mov    0x10(%ebp),%eax
f010311f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103123:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103126:	89 44 24 04          	mov    %eax,0x4(%esp)
f010312a:	8b 45 08             	mov    0x8(%ebp),%eax
f010312d:	89 04 24             	mov    %eax,(%esp)
f0103130:	e8 68 ff ff ff       	call   f010309d <memmove>
}
f0103135:	c9                   	leave  
f0103136:	c3                   	ret    

f0103137 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103137:	55                   	push   %ebp
f0103138:	89 e5                	mov    %esp,%ebp
f010313a:	57                   	push   %edi
f010313b:	56                   	push   %esi
f010313c:	53                   	push   %ebx
f010313d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103140:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103143:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103146:	8d 78 ff             	lea    -0x1(%eax),%edi
f0103149:	85 c0                	test   %eax,%eax
f010314b:	74 36                	je     f0103183 <memcmp+0x4c>
		if (*s1 != *s2)
f010314d:	0f b6 03             	movzbl (%ebx),%eax
f0103150:	0f b6 0e             	movzbl (%esi),%ecx
f0103153:	38 c8                	cmp    %cl,%al
f0103155:	75 17                	jne    f010316e <memcmp+0x37>
f0103157:	ba 00 00 00 00       	mov    $0x0,%edx
f010315c:	eb 1a                	jmp    f0103178 <memcmp+0x41>
f010315e:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103163:	83 c2 01             	add    $0x1,%edx
f0103166:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010316a:	38 c8                	cmp    %cl,%al
f010316c:	74 0a                	je     f0103178 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010316e:	0f b6 c0             	movzbl %al,%eax
f0103171:	0f b6 c9             	movzbl %cl,%ecx
f0103174:	29 c8                	sub    %ecx,%eax
f0103176:	eb 10                	jmp    f0103188 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103178:	39 fa                	cmp    %edi,%edx
f010317a:	75 e2                	jne    f010315e <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010317c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103181:	eb 05                	jmp    f0103188 <memcmp+0x51>
f0103183:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103188:	5b                   	pop    %ebx
f0103189:	5e                   	pop    %esi
f010318a:	5f                   	pop    %edi
f010318b:	5d                   	pop    %ebp
f010318c:	c3                   	ret    

f010318d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010318d:	55                   	push   %ebp
f010318e:	89 e5                	mov    %esp,%ebp
f0103190:	53                   	push   %ebx
f0103191:	8b 45 08             	mov    0x8(%ebp),%eax
f0103194:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0103197:	89 c2                	mov    %eax,%edx
f0103199:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010319c:	39 d0                	cmp    %edx,%eax
f010319e:	73 13                	jae    f01031b3 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f01031a0:	89 d9                	mov    %ebx,%ecx
f01031a2:	38 18                	cmp    %bl,(%eax)
f01031a4:	75 06                	jne    f01031ac <memfind+0x1f>
f01031a6:	eb 0b                	jmp    f01031b3 <memfind+0x26>
f01031a8:	38 08                	cmp    %cl,(%eax)
f01031aa:	74 07                	je     f01031b3 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01031ac:	83 c0 01             	add    $0x1,%eax
f01031af:	39 d0                	cmp    %edx,%eax
f01031b1:	75 f5                	jne    f01031a8 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01031b3:	5b                   	pop    %ebx
f01031b4:	5d                   	pop    %ebp
f01031b5:	c3                   	ret    

f01031b6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01031b6:	55                   	push   %ebp
f01031b7:	89 e5                	mov    %esp,%ebp
f01031b9:	57                   	push   %edi
f01031ba:	56                   	push   %esi
f01031bb:	53                   	push   %ebx
f01031bc:	83 ec 04             	sub    $0x4,%esp
f01031bf:	8b 55 08             	mov    0x8(%ebp),%edx
f01031c2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01031c5:	0f b6 02             	movzbl (%edx),%eax
f01031c8:	3c 09                	cmp    $0x9,%al
f01031ca:	74 04                	je     f01031d0 <strtol+0x1a>
f01031cc:	3c 20                	cmp    $0x20,%al
f01031ce:	75 0e                	jne    f01031de <strtol+0x28>
		s++;
f01031d0:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01031d3:	0f b6 02             	movzbl (%edx),%eax
f01031d6:	3c 09                	cmp    $0x9,%al
f01031d8:	74 f6                	je     f01031d0 <strtol+0x1a>
f01031da:	3c 20                	cmp    $0x20,%al
f01031dc:	74 f2                	je     f01031d0 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01031de:	3c 2b                	cmp    $0x2b,%al
f01031e0:	75 0a                	jne    f01031ec <strtol+0x36>
		s++;
f01031e2:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01031e5:	bf 00 00 00 00       	mov    $0x0,%edi
f01031ea:	eb 10                	jmp    f01031fc <strtol+0x46>
f01031ec:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01031f1:	3c 2d                	cmp    $0x2d,%al
f01031f3:	75 07                	jne    f01031fc <strtol+0x46>
		s++, neg = 1;
f01031f5:	83 c2 01             	add    $0x1,%edx
f01031f8:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01031fc:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103202:	75 15                	jne    f0103219 <strtol+0x63>
f0103204:	80 3a 30             	cmpb   $0x30,(%edx)
f0103207:	75 10                	jne    f0103219 <strtol+0x63>
f0103209:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010320d:	75 0a                	jne    f0103219 <strtol+0x63>
		s += 2, base = 16;
f010320f:	83 c2 02             	add    $0x2,%edx
f0103212:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103217:	eb 10                	jmp    f0103229 <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0103219:	85 db                	test   %ebx,%ebx
f010321b:	75 0c                	jne    f0103229 <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010321d:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010321f:	80 3a 30             	cmpb   $0x30,(%edx)
f0103222:	75 05                	jne    f0103229 <strtol+0x73>
		s++, base = 8;
f0103224:	83 c2 01             	add    $0x1,%edx
f0103227:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103229:	b8 00 00 00 00       	mov    $0x0,%eax
f010322e:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103231:	0f b6 0a             	movzbl (%edx),%ecx
f0103234:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103237:	89 f3                	mov    %esi,%ebx
f0103239:	80 fb 09             	cmp    $0x9,%bl
f010323c:	77 08                	ja     f0103246 <strtol+0x90>
			dig = *s - '0';
f010323e:	0f be c9             	movsbl %cl,%ecx
f0103241:	83 e9 30             	sub    $0x30,%ecx
f0103244:	eb 22                	jmp    f0103268 <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0103246:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103249:	89 f3                	mov    %esi,%ebx
f010324b:	80 fb 19             	cmp    $0x19,%bl
f010324e:	77 08                	ja     f0103258 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0103250:	0f be c9             	movsbl %cl,%ecx
f0103253:	83 e9 57             	sub    $0x57,%ecx
f0103256:	eb 10                	jmp    f0103268 <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0103258:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010325b:	89 f3                	mov    %esi,%ebx
f010325d:	80 fb 19             	cmp    $0x19,%bl
f0103260:	77 16                	ja     f0103278 <strtol+0xc2>
			dig = *s - 'A' + 10;
f0103262:	0f be c9             	movsbl %cl,%ecx
f0103265:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103268:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010326b:	7d 0f                	jge    f010327c <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f010326d:	83 c2 01             	add    $0x1,%edx
f0103270:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0103274:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103276:	eb b9                	jmp    f0103231 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103278:	89 c1                	mov    %eax,%ecx
f010327a:	eb 02                	jmp    f010327e <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010327c:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f010327e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103282:	74 05                	je     f0103289 <strtol+0xd3>
		*endptr = (char *) s;
f0103284:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103287:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103289:	89 ca                	mov    %ecx,%edx
f010328b:	f7 da                	neg    %edx
f010328d:	85 ff                	test   %edi,%edi
f010328f:	0f 45 c2             	cmovne %edx,%eax
}
f0103292:	83 c4 04             	add    $0x4,%esp
f0103295:	5b                   	pop    %ebx
f0103296:	5e                   	pop    %esi
f0103297:	5f                   	pop    %edi
f0103298:	5d                   	pop    %ebp
f0103299:	c3                   	ret    
f010329a:	66 90                	xchg   %ax,%ax
f010329c:	66 90                	xchg   %ax,%ax
f010329e:	66 90                	xchg   %ax,%ax

f01032a0 <__udivdi3>:
f01032a0:	83 ec 1c             	sub    $0x1c,%esp
f01032a3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f01032a7:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01032ab:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01032af:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01032b3:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01032b7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f01032bb:	85 c0                	test   %eax,%eax
f01032bd:	89 74 24 10          	mov    %esi,0x10(%esp)
f01032c1:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01032c5:	89 ea                	mov    %ebp,%edx
f01032c7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01032cb:	75 33                	jne    f0103300 <__udivdi3+0x60>
f01032cd:	39 e9                	cmp    %ebp,%ecx
f01032cf:	77 6f                	ja     f0103340 <__udivdi3+0xa0>
f01032d1:	85 c9                	test   %ecx,%ecx
f01032d3:	89 ce                	mov    %ecx,%esi
f01032d5:	75 0b                	jne    f01032e2 <__udivdi3+0x42>
f01032d7:	b8 01 00 00 00       	mov    $0x1,%eax
f01032dc:	31 d2                	xor    %edx,%edx
f01032de:	f7 f1                	div    %ecx
f01032e0:	89 c6                	mov    %eax,%esi
f01032e2:	31 d2                	xor    %edx,%edx
f01032e4:	89 e8                	mov    %ebp,%eax
f01032e6:	f7 f6                	div    %esi
f01032e8:	89 c5                	mov    %eax,%ebp
f01032ea:	89 f8                	mov    %edi,%eax
f01032ec:	f7 f6                	div    %esi
f01032ee:	89 ea                	mov    %ebp,%edx
f01032f0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01032f4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01032f8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01032fc:	83 c4 1c             	add    $0x1c,%esp
f01032ff:	c3                   	ret    
f0103300:	39 e8                	cmp    %ebp,%eax
f0103302:	77 24                	ja     f0103328 <__udivdi3+0x88>
f0103304:	0f bd c8             	bsr    %eax,%ecx
f0103307:	83 f1 1f             	xor    $0x1f,%ecx
f010330a:	89 0c 24             	mov    %ecx,(%esp)
f010330d:	75 49                	jne    f0103358 <__udivdi3+0xb8>
f010330f:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103313:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0103317:	0f 86 ab 00 00 00    	jbe    f01033c8 <__udivdi3+0x128>
f010331d:	39 e8                	cmp    %ebp,%eax
f010331f:	0f 82 a3 00 00 00    	jb     f01033c8 <__udivdi3+0x128>
f0103325:	8d 76 00             	lea    0x0(%esi),%esi
f0103328:	31 d2                	xor    %edx,%edx
f010332a:	31 c0                	xor    %eax,%eax
f010332c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103330:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103334:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103338:	83 c4 1c             	add    $0x1c,%esp
f010333b:	c3                   	ret    
f010333c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103340:	89 f8                	mov    %edi,%eax
f0103342:	f7 f1                	div    %ecx
f0103344:	31 d2                	xor    %edx,%edx
f0103346:	8b 74 24 10          	mov    0x10(%esp),%esi
f010334a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010334e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103352:	83 c4 1c             	add    $0x1c,%esp
f0103355:	c3                   	ret    
f0103356:	66 90                	xchg   %ax,%ax
f0103358:	0f b6 0c 24          	movzbl (%esp),%ecx
f010335c:	89 c6                	mov    %eax,%esi
f010335e:	b8 20 00 00 00       	mov    $0x20,%eax
f0103363:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0103367:	2b 04 24             	sub    (%esp),%eax
f010336a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010336e:	d3 e6                	shl    %cl,%esi
f0103370:	89 c1                	mov    %eax,%ecx
f0103372:	d3 ed                	shr    %cl,%ebp
f0103374:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103378:	09 f5                	or     %esi,%ebp
f010337a:	8b 74 24 04          	mov    0x4(%esp),%esi
f010337e:	d3 e6                	shl    %cl,%esi
f0103380:	89 c1                	mov    %eax,%ecx
f0103382:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103386:	89 d6                	mov    %edx,%esi
f0103388:	d3 ee                	shr    %cl,%esi
f010338a:	0f b6 0c 24          	movzbl (%esp),%ecx
f010338e:	d3 e2                	shl    %cl,%edx
f0103390:	89 c1                	mov    %eax,%ecx
f0103392:	d3 ef                	shr    %cl,%edi
f0103394:	09 d7                	or     %edx,%edi
f0103396:	89 f2                	mov    %esi,%edx
f0103398:	89 f8                	mov    %edi,%eax
f010339a:	f7 f5                	div    %ebp
f010339c:	89 d6                	mov    %edx,%esi
f010339e:	89 c7                	mov    %eax,%edi
f01033a0:	f7 64 24 04          	mull   0x4(%esp)
f01033a4:	39 d6                	cmp    %edx,%esi
f01033a6:	72 30                	jb     f01033d8 <__udivdi3+0x138>
f01033a8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01033ac:	0f b6 0c 24          	movzbl (%esp),%ecx
f01033b0:	d3 e5                	shl    %cl,%ebp
f01033b2:	39 c5                	cmp    %eax,%ebp
f01033b4:	73 04                	jae    f01033ba <__udivdi3+0x11a>
f01033b6:	39 d6                	cmp    %edx,%esi
f01033b8:	74 1e                	je     f01033d8 <__udivdi3+0x138>
f01033ba:	89 f8                	mov    %edi,%eax
f01033bc:	31 d2                	xor    %edx,%edx
f01033be:	e9 69 ff ff ff       	jmp    f010332c <__udivdi3+0x8c>
f01033c3:	90                   	nop
f01033c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01033c8:	31 d2                	xor    %edx,%edx
f01033ca:	b8 01 00 00 00       	mov    $0x1,%eax
f01033cf:	e9 58 ff ff ff       	jmp    f010332c <__udivdi3+0x8c>
f01033d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01033d8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01033db:	31 d2                	xor    %edx,%edx
f01033dd:	8b 74 24 10          	mov    0x10(%esp),%esi
f01033e1:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01033e5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01033e9:	83 c4 1c             	add    $0x1c,%esp
f01033ec:	c3                   	ret    
f01033ed:	66 90                	xchg   %ax,%ax
f01033ef:	90                   	nop

f01033f0 <__umoddi3>:
f01033f0:	83 ec 2c             	sub    $0x2c,%esp
f01033f3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01033f7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01033fb:	89 74 24 20          	mov    %esi,0x20(%esp)
f01033ff:	8b 74 24 38          	mov    0x38(%esp),%esi
f0103403:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0103407:	8b 7c 24 34          	mov    0x34(%esp),%edi
f010340b:	85 c0                	test   %eax,%eax
f010340d:	89 c2                	mov    %eax,%edx
f010340f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0103413:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0103417:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010341b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010341f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0103423:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103427:	75 1f                	jne    f0103448 <__umoddi3+0x58>
f0103429:	39 fe                	cmp    %edi,%esi
f010342b:	76 63                	jbe    f0103490 <__umoddi3+0xa0>
f010342d:	89 c8                	mov    %ecx,%eax
f010342f:	89 fa                	mov    %edi,%edx
f0103431:	f7 f6                	div    %esi
f0103433:	89 d0                	mov    %edx,%eax
f0103435:	31 d2                	xor    %edx,%edx
f0103437:	8b 74 24 20          	mov    0x20(%esp),%esi
f010343b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010343f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103443:	83 c4 2c             	add    $0x2c,%esp
f0103446:	c3                   	ret    
f0103447:	90                   	nop
f0103448:	39 f8                	cmp    %edi,%eax
f010344a:	77 64                	ja     f01034b0 <__umoddi3+0xc0>
f010344c:	0f bd e8             	bsr    %eax,%ebp
f010344f:	83 f5 1f             	xor    $0x1f,%ebp
f0103452:	75 74                	jne    f01034c8 <__umoddi3+0xd8>
f0103454:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103458:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f010345c:	0f 87 0e 01 00 00    	ja     f0103570 <__umoddi3+0x180>
f0103462:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0103466:	29 f1                	sub    %esi,%ecx
f0103468:	19 c7                	sbb    %eax,%edi
f010346a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010346e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103472:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103476:	8b 54 24 18          	mov    0x18(%esp),%edx
f010347a:	8b 74 24 20          	mov    0x20(%esp),%esi
f010347e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103482:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103486:	83 c4 2c             	add    $0x2c,%esp
f0103489:	c3                   	ret    
f010348a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103490:	85 f6                	test   %esi,%esi
f0103492:	89 f5                	mov    %esi,%ebp
f0103494:	75 0b                	jne    f01034a1 <__umoddi3+0xb1>
f0103496:	b8 01 00 00 00       	mov    $0x1,%eax
f010349b:	31 d2                	xor    %edx,%edx
f010349d:	f7 f6                	div    %esi
f010349f:	89 c5                	mov    %eax,%ebp
f01034a1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01034a5:	31 d2                	xor    %edx,%edx
f01034a7:	f7 f5                	div    %ebp
f01034a9:	89 c8                	mov    %ecx,%eax
f01034ab:	f7 f5                	div    %ebp
f01034ad:	eb 84                	jmp    f0103433 <__umoddi3+0x43>
f01034af:	90                   	nop
f01034b0:	89 c8                	mov    %ecx,%eax
f01034b2:	89 fa                	mov    %edi,%edx
f01034b4:	8b 74 24 20          	mov    0x20(%esp),%esi
f01034b8:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01034bc:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01034c0:	83 c4 2c             	add    $0x2c,%esp
f01034c3:	c3                   	ret    
f01034c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034c8:	8b 44 24 10          	mov    0x10(%esp),%eax
f01034cc:	be 20 00 00 00       	mov    $0x20,%esi
f01034d1:	89 e9                	mov    %ebp,%ecx
f01034d3:	29 ee                	sub    %ebp,%esi
f01034d5:	d3 e2                	shl    %cl,%edx
f01034d7:	89 f1                	mov    %esi,%ecx
f01034d9:	d3 e8                	shr    %cl,%eax
f01034db:	89 e9                	mov    %ebp,%ecx
f01034dd:	09 d0                	or     %edx,%eax
f01034df:	89 fa                	mov    %edi,%edx
f01034e1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034e5:	8b 44 24 10          	mov    0x10(%esp),%eax
f01034e9:	d3 e0                	shl    %cl,%eax
f01034eb:	89 f1                	mov    %esi,%ecx
f01034ed:	89 44 24 10          	mov    %eax,0x10(%esp)
f01034f1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01034f5:	d3 ea                	shr    %cl,%edx
f01034f7:	89 e9                	mov    %ebp,%ecx
f01034f9:	d3 e7                	shl    %cl,%edi
f01034fb:	89 f1                	mov    %esi,%ecx
f01034fd:	d3 e8                	shr    %cl,%eax
f01034ff:	89 e9                	mov    %ebp,%ecx
f0103501:	09 f8                	or     %edi,%eax
f0103503:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103507:	f7 74 24 0c          	divl   0xc(%esp)
f010350b:	d3 e7                	shl    %cl,%edi
f010350d:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103511:	89 d7                	mov    %edx,%edi
f0103513:	f7 64 24 10          	mull   0x10(%esp)
f0103517:	39 d7                	cmp    %edx,%edi
f0103519:	89 c1                	mov    %eax,%ecx
f010351b:	89 54 24 14          	mov    %edx,0x14(%esp)
f010351f:	72 3b                	jb     f010355c <__umoddi3+0x16c>
f0103521:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0103525:	72 31                	jb     f0103558 <__umoddi3+0x168>
f0103527:	8b 44 24 18          	mov    0x18(%esp),%eax
f010352b:	29 c8                	sub    %ecx,%eax
f010352d:	19 d7                	sbb    %edx,%edi
f010352f:	89 e9                	mov    %ebp,%ecx
f0103531:	89 fa                	mov    %edi,%edx
f0103533:	d3 e8                	shr    %cl,%eax
f0103535:	89 f1                	mov    %esi,%ecx
f0103537:	d3 e2                	shl    %cl,%edx
f0103539:	89 e9                	mov    %ebp,%ecx
f010353b:	09 d0                	or     %edx,%eax
f010353d:	89 fa                	mov    %edi,%edx
f010353f:	d3 ea                	shr    %cl,%edx
f0103541:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103545:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103549:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f010354d:	83 c4 2c             	add    $0x2c,%esp
f0103550:	c3                   	ret    
f0103551:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103558:	39 d7                	cmp    %edx,%edi
f010355a:	75 cb                	jne    f0103527 <__umoddi3+0x137>
f010355c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0103560:	89 c1                	mov    %eax,%ecx
f0103562:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0103566:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010356a:	eb bb                	jmp    f0103527 <__umoddi3+0x137>
f010356c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103570:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0103574:	0f 82 e8 fe ff ff    	jb     f0103462 <__umoddi3+0x72>
f010357a:	e9 f3 fe ff ff       	jmp    f0103472 <__umoddi3+0x82>

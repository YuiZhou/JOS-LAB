
obj/user/divzero：     文件格式 elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 37 00 00 00       	call   800068 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	90                   	nop

00800034 <umain>:

int zero;

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	zero = 0;
  80003a:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800041:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800044:	b8 01 00 00 00       	mov    $0x1,%eax
  800049:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004e:	89 c2                	mov    %eax,%edx
  800050:	c1 fa 1f             	sar    $0x1f,%edx
  800053:	f7 f9                	idiv   %ecx
  800055:	89 44 24 04          	mov    %eax,0x4(%esp)
  800059:	c7 04 24 20 10 80 00 	movl   $0x801020,(%esp)
  800060:	e8 f2 00 00 00       	call   800157 <cprintf>
}
  800065:	c9                   	leave  
  800066:	c3                   	ret    
  800067:	90                   	nop

00800068 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800068:	55                   	push   %ebp
  800069:	89 e5                	mov    %esp,%ebp
  80006b:	83 ec 18             	sub    $0x18,%esp
  80006e:	8b 45 08             	mov    0x8(%ebp),%eax
  800071:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800074:	c7 05 08 20 80 00 00 	movl   $0x0,0x802008
  80007b:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80007e:	85 c0                	test   %eax,%eax
  800080:	7e 08                	jle    80008a <libmain+0x22>
		binaryname = argv[0];
  800082:	8b 0a                	mov    (%edx),%ecx
  800084:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  80008a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80008e:	89 04 24             	mov    %eax,(%esp)
  800091:	e8 9e ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  800096:	e8 05 00 00 00       	call   8000a0 <exit>
}
  80009b:	c9                   	leave  
  80009c:	c3                   	ret    
  80009d:	66 90                	xchg   %ax,%ax
  80009f:	90                   	nop

008000a0 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a0:	55                   	push   %ebp
  8000a1:	89 e5                	mov    %esp,%ebp
  8000a3:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000ad:	e8 8d 0b 00 00       	call   800c3f <sys_env_destroy>
}
  8000b2:	c9                   	leave  
  8000b3:	c3                   	ret    

008000b4 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000b4:	55                   	push   %ebp
  8000b5:	89 e5                	mov    %esp,%ebp
  8000b7:	53                   	push   %ebx
  8000b8:	83 ec 14             	sub    $0x14,%esp
  8000bb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000be:	8b 03                	mov    (%ebx),%eax
  8000c0:	8b 55 08             	mov    0x8(%ebp),%edx
  8000c3:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8000c7:	83 c0 01             	add    $0x1,%eax
  8000ca:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8000cc:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d1:	75 19                	jne    8000ec <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000d3:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000da:	00 
  8000db:	8d 43 08             	lea    0x8(%ebx),%eax
  8000de:	89 04 24             	mov    %eax,(%esp)
  8000e1:	e8 fa 0a 00 00       	call   800be0 <sys_cputs>
		b->idx = 0;
  8000e6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000ec:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f0:	83 c4 14             	add    $0x14,%esp
  8000f3:	5b                   	pop    %ebx
  8000f4:	5d                   	pop    %ebp
  8000f5:	c3                   	ret    

008000f6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000f6:	55                   	push   %ebp
  8000f7:	89 e5                	mov    %esp,%ebp
  8000f9:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8000ff:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800106:	00 00 00 
	b.cnt = 0;
  800109:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800110:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800113:	8b 45 0c             	mov    0xc(%ebp),%eax
  800116:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80011a:	8b 45 08             	mov    0x8(%ebp),%eax
  80011d:	89 44 24 08          	mov    %eax,0x8(%esp)
  800121:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800127:	89 44 24 04          	mov    %eax,0x4(%esp)
  80012b:	c7 04 24 b4 00 80 00 	movl   $0x8000b4,(%esp)
  800132:	e8 bb 01 00 00       	call   8002f2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800137:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80013d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800141:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800147:	89 04 24             	mov    %eax,(%esp)
  80014a:	e8 91 0a 00 00       	call   800be0 <sys_cputs>

	return b.cnt;
}
  80014f:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800155:	c9                   	leave  
  800156:	c3                   	ret    

00800157 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800157:	55                   	push   %ebp
  800158:	89 e5                	mov    %esp,%ebp
  80015a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80015d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800160:	89 44 24 04          	mov    %eax,0x4(%esp)
  800164:	8b 45 08             	mov    0x8(%ebp),%eax
  800167:	89 04 24             	mov    %eax,(%esp)
  80016a:	e8 87 ff ff ff       	call   8000f6 <vcprintf>
	va_end(ap);

	return cnt;
}
  80016f:	c9                   	leave  
  800170:	c3                   	ret    
  800171:	66 90                	xchg   %ax,%ax
  800173:	66 90                	xchg   %ax,%ax
  800175:	66 90                	xchg   %ax,%ax
  800177:	66 90                	xchg   %ax,%ax
  800179:	66 90                	xchg   %ax,%ax
  80017b:	66 90                	xchg   %ax,%ax
  80017d:	66 90                	xchg   %ax,%ax
  80017f:	90                   	nop

00800180 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800180:	55                   	push   %ebp
  800181:	89 e5                	mov    %esp,%ebp
  800183:	57                   	push   %edi
  800184:	56                   	push   %esi
  800185:	53                   	push   %ebx
  800186:	83 ec 4c             	sub    $0x4c,%esp
  800189:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80018c:	89 d7                	mov    %edx,%edi
  80018e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800191:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800194:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800197:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80019a:	b8 00 00 00 00       	mov    $0x0,%eax
  80019f:	39 d8                	cmp    %ebx,%eax
  8001a1:	72 17                	jb     8001ba <printnum+0x3a>
  8001a3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8001a6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8001a9:	76 0f                	jbe    8001ba <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001ab:	8b 75 14             	mov    0x14(%ebp),%esi
  8001ae:	83 ee 01             	sub    $0x1,%esi
  8001b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8001b4:	85 f6                	test   %esi,%esi
  8001b6:	7f 63                	jg     80021b <printnum+0x9b>
  8001b8:	eb 75                	jmp    80022f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001ba:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8001bd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8001c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8001c4:	83 e8 01             	sub    $0x1,%eax
  8001c7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001cb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8001d2:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001d6:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001da:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8001dd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8001e0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8001e7:	00 
  8001e8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8001eb:	89 1c 24             	mov    %ebx,(%esp)
  8001ee:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8001f1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001f5:	e8 46 0b 00 00       	call   800d40 <__udivdi3>
  8001fa:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8001fd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800200:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800204:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800208:	89 04 24             	mov    %eax,(%esp)
  80020b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80020f:	89 fa                	mov    %edi,%edx
  800211:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800214:	e8 67 ff ff ff       	call   800180 <printnum>
  800219:	eb 14                	jmp    80022f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80021b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80021f:	8b 45 18             	mov    0x18(%ebp),%eax
  800222:	89 04 24             	mov    %eax,(%esp)
  800225:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800227:	83 ee 01             	sub    $0x1,%esi
  80022a:	75 ef                	jne    80021b <printnum+0x9b>
  80022c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80022f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800233:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800237:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80023a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80023e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800245:	00 
  800246:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800249:	89 1c 24             	mov    %ebx,(%esp)
  80024c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80024f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800253:	e8 38 0c 00 00       	call   800e90 <__umoddi3>
  800258:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80025c:	0f be 80 38 10 80 00 	movsbl 0x801038(%eax),%eax
  800263:	89 04 24             	mov    %eax,(%esp)
  800266:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800269:	ff d0                	call   *%eax
}
  80026b:	83 c4 4c             	add    $0x4c,%esp
  80026e:	5b                   	pop    %ebx
  80026f:	5e                   	pop    %esi
  800270:	5f                   	pop    %edi
  800271:	5d                   	pop    %ebp
  800272:	c3                   	ret    

00800273 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800273:	55                   	push   %ebp
  800274:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800276:	83 fa 01             	cmp    $0x1,%edx
  800279:	7e 0e                	jle    800289 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80027b:	8b 10                	mov    (%eax),%edx
  80027d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800280:	89 08                	mov    %ecx,(%eax)
  800282:	8b 02                	mov    (%edx),%eax
  800284:	8b 52 04             	mov    0x4(%edx),%edx
  800287:	eb 22                	jmp    8002ab <getuint+0x38>
	else if (lflag)
  800289:	85 d2                	test   %edx,%edx
  80028b:	74 10                	je     80029d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80028d:	8b 10                	mov    (%eax),%edx
  80028f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800292:	89 08                	mov    %ecx,(%eax)
  800294:	8b 02                	mov    (%edx),%eax
  800296:	ba 00 00 00 00       	mov    $0x0,%edx
  80029b:	eb 0e                	jmp    8002ab <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80029d:	8b 10                	mov    (%eax),%edx
  80029f:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002a2:	89 08                	mov    %ecx,(%eax)
  8002a4:	8b 02                	mov    (%edx),%eax
  8002a6:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002ab:	5d                   	pop    %ebp
  8002ac:	c3                   	ret    

008002ad <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002ad:	55                   	push   %ebp
  8002ae:	89 e5                	mov    %esp,%ebp
  8002b0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002b3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002b7:	8b 10                	mov    (%eax),%edx
  8002b9:	3b 50 04             	cmp    0x4(%eax),%edx
  8002bc:	73 0a                	jae    8002c8 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002be:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002c1:	88 0a                	mov    %cl,(%edx)
  8002c3:	83 c2 01             	add    $0x1,%edx
  8002c6:	89 10                	mov    %edx,(%eax)
}
  8002c8:	5d                   	pop    %ebp
  8002c9:	c3                   	ret    

008002ca <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002ca:	55                   	push   %ebp
  8002cb:	89 e5                	mov    %esp,%ebp
  8002cd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002d0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002d7:	8b 45 10             	mov    0x10(%ebp),%eax
  8002da:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002de:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002e5:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e8:	89 04 24             	mov    %eax,(%esp)
  8002eb:	e8 02 00 00 00       	call   8002f2 <vprintfmt>
	va_end(ap);
}
  8002f0:	c9                   	leave  
  8002f1:	c3                   	ret    

008002f2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002f2:	55                   	push   %ebp
  8002f3:	89 e5                	mov    %esp,%ebp
  8002f5:	57                   	push   %edi
  8002f6:	56                   	push   %esi
  8002f7:	53                   	push   %ebx
  8002f8:	83 ec 4c             	sub    $0x4c,%esp
  8002fb:	8b 75 08             	mov    0x8(%ebp),%esi
  8002fe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800301:	8b 7d 10             	mov    0x10(%ebp),%edi
  800304:	eb 11                	jmp    800317 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800306:	85 c0                	test   %eax,%eax
  800308:	0f 84 db 03 00 00    	je     8006e9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80030e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800312:	89 04 24             	mov    %eax,(%esp)
  800315:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800317:	0f b6 07             	movzbl (%edi),%eax
  80031a:	83 c7 01             	add    $0x1,%edi
  80031d:	83 f8 25             	cmp    $0x25,%eax
  800320:	75 e4                	jne    800306 <vprintfmt+0x14>
  800322:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800326:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80032d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800334:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80033b:	ba 00 00 00 00       	mov    $0x0,%edx
  800340:	eb 2b                	jmp    80036d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800342:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800345:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800349:	eb 22                	jmp    80036d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80034e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800352:	eb 19                	jmp    80036d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800354:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800357:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80035e:	eb 0d                	jmp    80036d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800360:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800363:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800366:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036d:	0f b6 0f             	movzbl (%edi),%ecx
  800370:	8d 47 01             	lea    0x1(%edi),%eax
  800373:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800376:	0f b6 07             	movzbl (%edi),%eax
  800379:	83 e8 23             	sub    $0x23,%eax
  80037c:	3c 55                	cmp    $0x55,%al
  80037e:	0f 87 40 03 00 00    	ja     8006c4 <vprintfmt+0x3d2>
  800384:	0f b6 c0             	movzbl %al,%eax
  800387:	ff 24 85 c8 10 80 00 	jmp    *0x8010c8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80038e:	83 e9 30             	sub    $0x30,%ecx
  800391:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800394:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800398:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80039b:	83 f9 09             	cmp    $0x9,%ecx
  80039e:	77 57                	ja     8003f7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a0:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8003a3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8003a6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003a9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  8003ac:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8003af:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8003b3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8003b6:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8003b9:	83 f9 09             	cmp    $0x9,%ecx
  8003bc:	76 eb                	jbe    8003a9 <vprintfmt+0xb7>
  8003be:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8003c1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  8003c4:	eb 34                	jmp    8003fa <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003c6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c9:	8d 48 04             	lea    0x4(%eax),%ecx
  8003cc:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003cf:	8b 00                	mov    (%eax),%eax
  8003d1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003d7:	eb 21                	jmp    8003fa <vprintfmt+0x108>

		case '.':
			if (width < 0)
  8003d9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003dd:	0f 88 71 ff ff ff    	js     800354 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8003e6:	eb 85                	jmp    80036d <vprintfmt+0x7b>
  8003e8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003eb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8003f2:	e9 76 ff ff ff       	jmp    80036d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8003fa:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003fe:	0f 89 69 ff ff ff    	jns    80036d <vprintfmt+0x7b>
  800404:	e9 57 ff ff ff       	jmp    800360 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800409:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80040f:	e9 59 ff ff ff       	jmp    80036d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800414:	8b 45 14             	mov    0x14(%ebp),%eax
  800417:	8d 50 04             	lea    0x4(%eax),%edx
  80041a:	89 55 14             	mov    %edx,0x14(%ebp)
  80041d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800421:	8b 00                	mov    (%eax),%eax
  800423:	89 04 24             	mov    %eax,(%esp)
  800426:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800428:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80042b:	e9 e7 fe ff ff       	jmp    800317 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800430:	8b 45 14             	mov    0x14(%ebp),%eax
  800433:	8d 50 04             	lea    0x4(%eax),%edx
  800436:	89 55 14             	mov    %edx,0x14(%ebp)
  800439:	8b 00                	mov    (%eax),%eax
  80043b:	89 c2                	mov    %eax,%edx
  80043d:	c1 fa 1f             	sar    $0x1f,%edx
  800440:	31 d0                	xor    %edx,%eax
  800442:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800444:	83 f8 06             	cmp    $0x6,%eax
  800447:	7f 0b                	jg     800454 <vprintfmt+0x162>
  800449:	8b 14 85 20 12 80 00 	mov    0x801220(,%eax,4),%edx
  800450:	85 d2                	test   %edx,%edx
  800452:	75 20                	jne    800474 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800454:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800458:	c7 44 24 08 50 10 80 	movl   $0x801050,0x8(%esp)
  80045f:	00 
  800460:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800464:	89 34 24             	mov    %esi,(%esp)
  800467:	e8 5e fe ff ff       	call   8002ca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80046f:	e9 a3 fe ff ff       	jmp    800317 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800474:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800478:	c7 44 24 08 59 10 80 	movl   $0x801059,0x8(%esp)
  80047f:	00 
  800480:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800484:	89 34 24             	mov    %esi,(%esp)
  800487:	e8 3e fe ff ff       	call   8002ca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80048c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80048f:	e9 83 fe ff ff       	jmp    800317 <vprintfmt+0x25>
  800494:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800497:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80049a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80049d:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a0:	8d 50 04             	lea    0x4(%eax),%edx
  8004a3:	89 55 14             	mov    %edx,0x14(%ebp)
  8004a6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004a8:	85 ff                	test   %edi,%edi
  8004aa:	b8 49 10 80 00       	mov    $0x801049,%eax
  8004af:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004b2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8004b6:	74 06                	je     8004be <vprintfmt+0x1cc>
  8004b8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8004bc:	7f 16                	jg     8004d4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004be:	0f b6 17             	movzbl (%edi),%edx
  8004c1:	0f be c2             	movsbl %dl,%eax
  8004c4:	83 c7 01             	add    $0x1,%edi
  8004c7:	85 c0                	test   %eax,%eax
  8004c9:	0f 85 9f 00 00 00    	jne    80056e <vprintfmt+0x27c>
  8004cf:	e9 8b 00 00 00       	jmp    80055f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004d8:	89 3c 24             	mov    %edi,(%esp)
  8004db:	e8 c2 02 00 00       	call   8007a2 <strnlen>
  8004e0:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8004e3:	29 c2                	sub    %eax,%edx
  8004e5:	89 55 d8             	mov    %edx,-0x28(%ebp)
  8004e8:	85 d2                	test   %edx,%edx
  8004ea:	7e d2                	jle    8004be <vprintfmt+0x1cc>
					putch(padc, putdat);
  8004ec:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8004f0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8004f3:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8004f6:	89 d7                	mov    %edx,%edi
  8004f8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8004ff:	89 04 24             	mov    %eax,(%esp)
  800502:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800504:	83 ef 01             	sub    $0x1,%edi
  800507:	75 ef                	jne    8004f8 <vprintfmt+0x206>
  800509:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80050c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80050f:	eb ad                	jmp    8004be <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800511:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800515:	74 20                	je     800537 <vprintfmt+0x245>
  800517:	0f be d2             	movsbl %dl,%edx
  80051a:	83 ea 20             	sub    $0x20,%edx
  80051d:	83 fa 5e             	cmp    $0x5e,%edx
  800520:	76 15                	jbe    800537 <vprintfmt+0x245>
					putch('?', putdat);
  800522:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800525:	89 54 24 04          	mov    %edx,0x4(%esp)
  800529:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800530:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800533:	ff d1                	call   *%ecx
  800535:	eb 0f                	jmp    800546 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800537:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80053a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80053e:	89 04 24             	mov    %eax,(%esp)
  800541:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800544:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800546:	83 eb 01             	sub    $0x1,%ebx
  800549:	0f b6 17             	movzbl (%edi),%edx
  80054c:	0f be c2             	movsbl %dl,%eax
  80054f:	83 c7 01             	add    $0x1,%edi
  800552:	85 c0                	test   %eax,%eax
  800554:	75 24                	jne    80057a <vprintfmt+0x288>
  800556:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800559:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80055c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800562:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800566:	0f 8e ab fd ff ff    	jle    800317 <vprintfmt+0x25>
  80056c:	eb 20                	jmp    80058e <vprintfmt+0x29c>
  80056e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800571:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800574:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800577:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80057a:	85 f6                	test   %esi,%esi
  80057c:	78 93                	js     800511 <vprintfmt+0x21f>
  80057e:	83 ee 01             	sub    $0x1,%esi
  800581:	79 8e                	jns    800511 <vprintfmt+0x21f>
  800583:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800586:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800589:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80058c:	eb d1                	jmp    80055f <vprintfmt+0x26d>
  80058e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800591:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800595:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80059c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80059e:	83 ef 01             	sub    $0x1,%edi
  8005a1:	75 ee                	jne    800591 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005a3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8005a6:	e9 6c fd ff ff       	jmp    800317 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005ab:	83 fa 01             	cmp    $0x1,%edx
  8005ae:	66 90                	xchg   %ax,%ax
  8005b0:	7e 16                	jle    8005c8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  8005b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b5:	8d 50 08             	lea    0x8(%eax),%edx
  8005b8:	89 55 14             	mov    %edx,0x14(%ebp)
  8005bb:	8b 10                	mov    (%eax),%edx
  8005bd:	8b 48 04             	mov    0x4(%eax),%ecx
  8005c0:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8005c3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005c6:	eb 32                	jmp    8005fa <vprintfmt+0x308>
	else if (lflag)
  8005c8:	85 d2                	test   %edx,%edx
  8005ca:	74 18                	je     8005e4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  8005cc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cf:	8d 50 04             	lea    0x4(%eax),%edx
  8005d2:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d5:	8b 00                	mov    (%eax),%eax
  8005d7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005da:	89 c1                	mov    %eax,%ecx
  8005dc:	c1 f9 1f             	sar    $0x1f,%ecx
  8005df:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005e2:	eb 16                	jmp    8005fa <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  8005e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e7:	8d 50 04             	lea    0x4(%eax),%edx
  8005ea:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ed:	8b 00                	mov    (%eax),%eax
  8005ef:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005f2:	89 c7                	mov    %eax,%edi
  8005f4:	c1 ff 1f             	sar    $0x1f,%edi
  8005f7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005fa:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005fd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800600:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800605:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800609:	79 7d                	jns    800688 <vprintfmt+0x396>
				putch('-', putdat);
  80060b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80060f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800616:	ff d6                	call   *%esi
				num = -(long long) num;
  800618:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80061b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80061e:	f7 d8                	neg    %eax
  800620:	83 d2 00             	adc    $0x0,%edx
  800623:	f7 da                	neg    %edx
			}
			base = 10;
  800625:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80062a:	eb 5c                	jmp    800688 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80062c:	8d 45 14             	lea    0x14(%ebp),%eax
  80062f:	e8 3f fc ff ff       	call   800273 <getuint>
			base = 10;
  800634:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800639:	eb 4d                	jmp    800688 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80063b:	8d 45 14             	lea    0x14(%ebp),%eax
  80063e:	e8 30 fc ff ff       	call   800273 <getuint>
			base = 8;
  800643:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800648:	eb 3e                	jmp    800688 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  80064a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80064e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800655:	ff d6                	call   *%esi
			putch('x', putdat);
  800657:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80065b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800662:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800664:	8b 45 14             	mov    0x14(%ebp),%eax
  800667:	8d 50 04             	lea    0x4(%eax),%edx
  80066a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80066d:	8b 00                	mov    (%eax),%eax
  80066f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800674:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800679:	eb 0d                	jmp    800688 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80067b:	8d 45 14             	lea    0x14(%ebp),%eax
  80067e:	e8 f0 fb ff ff       	call   800273 <getuint>
			base = 16;
  800683:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800688:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80068c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800690:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800693:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800697:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80069b:	89 04 24             	mov    %eax,(%esp)
  80069e:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006a2:	89 da                	mov    %ebx,%edx
  8006a4:	89 f0                	mov    %esi,%eax
  8006a6:	e8 d5 fa ff ff       	call   800180 <printnum>
			break;
  8006ab:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8006ae:	e9 64 fc ff ff       	jmp    800317 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006b3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006b7:	89 0c 24             	mov    %ecx,(%esp)
  8006ba:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006bc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006bf:	e9 53 fc ff ff       	jmp    800317 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006c4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006c8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006cf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006d1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006d5:	0f 84 3c fc ff ff    	je     800317 <vprintfmt+0x25>
  8006db:	83 ef 01             	sub    $0x1,%edi
  8006de:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006e2:	75 f7                	jne    8006db <vprintfmt+0x3e9>
  8006e4:	e9 2e fc ff ff       	jmp    800317 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8006e9:	83 c4 4c             	add    $0x4c,%esp
  8006ec:	5b                   	pop    %ebx
  8006ed:	5e                   	pop    %esi
  8006ee:	5f                   	pop    %edi
  8006ef:	5d                   	pop    %ebp
  8006f0:	c3                   	ret    

008006f1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006f1:	55                   	push   %ebp
  8006f2:	89 e5                	mov    %esp,%ebp
  8006f4:	83 ec 28             	sub    $0x28,%esp
  8006f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8006fa:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006fd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800700:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800704:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800707:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80070e:	85 d2                	test   %edx,%edx
  800710:	7e 30                	jle    800742 <vsnprintf+0x51>
  800712:	85 c0                	test   %eax,%eax
  800714:	74 2c                	je     800742 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800716:	8b 45 14             	mov    0x14(%ebp),%eax
  800719:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80071d:	8b 45 10             	mov    0x10(%ebp),%eax
  800720:	89 44 24 08          	mov    %eax,0x8(%esp)
  800724:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800727:	89 44 24 04          	mov    %eax,0x4(%esp)
  80072b:	c7 04 24 ad 02 80 00 	movl   $0x8002ad,(%esp)
  800732:	e8 bb fb ff ff       	call   8002f2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800737:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80073a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80073d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800740:	eb 05                	jmp    800747 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800742:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800747:	c9                   	leave  
  800748:	c3                   	ret    

00800749 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800749:	55                   	push   %ebp
  80074a:	89 e5                	mov    %esp,%ebp
  80074c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80074f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800752:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800756:	8b 45 10             	mov    0x10(%ebp),%eax
  800759:	89 44 24 08          	mov    %eax,0x8(%esp)
  80075d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800760:	89 44 24 04          	mov    %eax,0x4(%esp)
  800764:	8b 45 08             	mov    0x8(%ebp),%eax
  800767:	89 04 24             	mov    %eax,(%esp)
  80076a:	e8 82 ff ff ff       	call   8006f1 <vsnprintf>
	va_end(ap);

	return rc;
}
  80076f:	c9                   	leave  
  800770:	c3                   	ret    
  800771:	66 90                	xchg   %ax,%ax
  800773:	66 90                	xchg   %ax,%ax
  800775:	66 90                	xchg   %ax,%ax
  800777:	66 90                	xchg   %ax,%ax
  800779:	66 90                	xchg   %ax,%ax
  80077b:	66 90                	xchg   %ax,%ax
  80077d:	66 90                	xchg   %ax,%ax
  80077f:	90                   	nop

00800780 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800780:	55                   	push   %ebp
  800781:	89 e5                	mov    %esp,%ebp
  800783:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800786:	80 3a 00             	cmpb   $0x0,(%edx)
  800789:	74 10                	je     80079b <strlen+0x1b>
  80078b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800790:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800793:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800797:	75 f7                	jne    800790 <strlen+0x10>
  800799:	eb 05                	jmp    8007a0 <strlen+0x20>
  80079b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8007a0:	5d                   	pop    %ebp
  8007a1:	c3                   	ret    

008007a2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007a2:	55                   	push   %ebp
  8007a3:	89 e5                	mov    %esp,%ebp
  8007a5:	53                   	push   %ebx
  8007a6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8007a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007ac:	85 c9                	test   %ecx,%ecx
  8007ae:	74 1c                	je     8007cc <strnlen+0x2a>
  8007b0:	80 3b 00             	cmpb   $0x0,(%ebx)
  8007b3:	74 1e                	je     8007d3 <strnlen+0x31>
  8007b5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  8007ba:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007bc:	39 ca                	cmp    %ecx,%edx
  8007be:	74 18                	je     8007d8 <strnlen+0x36>
  8007c0:	83 c2 01             	add    $0x1,%edx
  8007c3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8007c8:	75 f0                	jne    8007ba <strnlen+0x18>
  8007ca:	eb 0c                	jmp    8007d8 <strnlen+0x36>
  8007cc:	b8 00 00 00 00       	mov    $0x0,%eax
  8007d1:	eb 05                	jmp    8007d8 <strnlen+0x36>
  8007d3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8007d8:	5b                   	pop    %ebx
  8007d9:	5d                   	pop    %ebp
  8007da:	c3                   	ret    

008007db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007db:	55                   	push   %ebp
  8007dc:	89 e5                	mov    %esp,%ebp
  8007de:	53                   	push   %ebx
  8007df:	8b 45 08             	mov    0x8(%ebp),%eax
  8007e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007e5:	89 c2                	mov    %eax,%edx
  8007e7:	0f b6 19             	movzbl (%ecx),%ebx
  8007ea:	88 1a                	mov    %bl,(%edx)
  8007ec:	83 c2 01             	add    $0x1,%edx
  8007ef:	83 c1 01             	add    $0x1,%ecx
  8007f2:	84 db                	test   %bl,%bl
  8007f4:	75 f1                	jne    8007e7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007f6:	5b                   	pop    %ebx
  8007f7:	5d                   	pop    %ebp
  8007f8:	c3                   	ret    

008007f9 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007f9:	55                   	push   %ebp
  8007fa:	89 e5                	mov    %esp,%ebp
  8007fc:	53                   	push   %ebx
  8007fd:	83 ec 08             	sub    $0x8,%esp
  800800:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800803:	89 1c 24             	mov    %ebx,(%esp)
  800806:	e8 75 ff ff ff       	call   800780 <strlen>
	strcpy(dst + len, src);
  80080b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80080e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800812:	01 d8                	add    %ebx,%eax
  800814:	89 04 24             	mov    %eax,(%esp)
  800817:	e8 bf ff ff ff       	call   8007db <strcpy>
	return dst;
}
  80081c:	89 d8                	mov    %ebx,%eax
  80081e:	83 c4 08             	add    $0x8,%esp
  800821:	5b                   	pop    %ebx
  800822:	5d                   	pop    %ebp
  800823:	c3                   	ret    

00800824 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800824:	55                   	push   %ebp
  800825:	89 e5                	mov    %esp,%ebp
  800827:	56                   	push   %esi
  800828:	53                   	push   %ebx
  800829:	8b 75 08             	mov    0x8(%ebp),%esi
  80082c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80082f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800832:	85 db                	test   %ebx,%ebx
  800834:	74 16                	je     80084c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800836:	01 f3                	add    %esi,%ebx
  800838:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  80083a:	0f b6 02             	movzbl (%edx),%eax
  80083d:	88 01                	mov    %al,(%ecx)
  80083f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800842:	80 3a 01             	cmpb   $0x1,(%edx)
  800845:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800848:	39 d9                	cmp    %ebx,%ecx
  80084a:	75 ee                	jne    80083a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80084c:	89 f0                	mov    %esi,%eax
  80084e:	5b                   	pop    %ebx
  80084f:	5e                   	pop    %esi
  800850:	5d                   	pop    %ebp
  800851:	c3                   	ret    

00800852 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800852:	55                   	push   %ebp
  800853:	89 e5                	mov    %esp,%ebp
  800855:	57                   	push   %edi
  800856:	56                   	push   %esi
  800857:	53                   	push   %ebx
  800858:	8b 7d 08             	mov    0x8(%ebp),%edi
  80085b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80085e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800861:	89 f8                	mov    %edi,%eax
  800863:	85 f6                	test   %esi,%esi
  800865:	74 33                	je     80089a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800867:	83 fe 01             	cmp    $0x1,%esi
  80086a:	74 25                	je     800891 <strlcpy+0x3f>
  80086c:	0f b6 0b             	movzbl (%ebx),%ecx
  80086f:	84 c9                	test   %cl,%cl
  800871:	74 22                	je     800895 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800873:	83 ee 02             	sub    $0x2,%esi
  800876:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80087b:	88 08                	mov    %cl,(%eax)
  80087d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800880:	39 f2                	cmp    %esi,%edx
  800882:	74 13                	je     800897 <strlcpy+0x45>
  800884:	83 c2 01             	add    $0x1,%edx
  800887:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80088b:	84 c9                	test   %cl,%cl
  80088d:	75 ec                	jne    80087b <strlcpy+0x29>
  80088f:	eb 06                	jmp    800897 <strlcpy+0x45>
  800891:	89 f8                	mov    %edi,%eax
  800893:	eb 02                	jmp    800897 <strlcpy+0x45>
  800895:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800897:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80089a:	29 f8                	sub    %edi,%eax
}
  80089c:	5b                   	pop    %ebx
  80089d:	5e                   	pop    %esi
  80089e:	5f                   	pop    %edi
  80089f:	5d                   	pop    %ebp
  8008a0:	c3                   	ret    

008008a1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008a1:	55                   	push   %ebp
  8008a2:	89 e5                	mov    %esp,%ebp
  8008a4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008a7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008aa:	0f b6 01             	movzbl (%ecx),%eax
  8008ad:	84 c0                	test   %al,%al
  8008af:	74 15                	je     8008c6 <strcmp+0x25>
  8008b1:	3a 02                	cmp    (%edx),%al
  8008b3:	75 11                	jne    8008c6 <strcmp+0x25>
		p++, q++;
  8008b5:	83 c1 01             	add    $0x1,%ecx
  8008b8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008bb:	0f b6 01             	movzbl (%ecx),%eax
  8008be:	84 c0                	test   %al,%al
  8008c0:	74 04                	je     8008c6 <strcmp+0x25>
  8008c2:	3a 02                	cmp    (%edx),%al
  8008c4:	74 ef                	je     8008b5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008c6:	0f b6 c0             	movzbl %al,%eax
  8008c9:	0f b6 12             	movzbl (%edx),%edx
  8008cc:	29 d0                	sub    %edx,%eax
}
  8008ce:	5d                   	pop    %ebp
  8008cf:	c3                   	ret    

008008d0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008d0:	55                   	push   %ebp
  8008d1:	89 e5                	mov    %esp,%ebp
  8008d3:	56                   	push   %esi
  8008d4:	53                   	push   %ebx
  8008d5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8008d8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008db:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  8008de:	85 f6                	test   %esi,%esi
  8008e0:	74 29                	je     80090b <strncmp+0x3b>
  8008e2:	0f b6 03             	movzbl (%ebx),%eax
  8008e5:	84 c0                	test   %al,%al
  8008e7:	74 30                	je     800919 <strncmp+0x49>
  8008e9:	3a 02                	cmp    (%edx),%al
  8008eb:	75 2c                	jne    800919 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  8008ed:	8d 43 01             	lea    0x1(%ebx),%eax
  8008f0:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  8008f2:	89 c3                	mov    %eax,%ebx
  8008f4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008f7:	39 f0                	cmp    %esi,%eax
  8008f9:	74 17                	je     800912 <strncmp+0x42>
  8008fb:	0f b6 08             	movzbl (%eax),%ecx
  8008fe:	84 c9                	test   %cl,%cl
  800900:	74 17                	je     800919 <strncmp+0x49>
  800902:	83 c0 01             	add    $0x1,%eax
  800905:	3a 0a                	cmp    (%edx),%cl
  800907:	74 e9                	je     8008f2 <strncmp+0x22>
  800909:	eb 0e                	jmp    800919 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  80090b:	b8 00 00 00 00       	mov    $0x0,%eax
  800910:	eb 0f                	jmp    800921 <strncmp+0x51>
  800912:	b8 00 00 00 00       	mov    $0x0,%eax
  800917:	eb 08                	jmp    800921 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800919:	0f b6 03             	movzbl (%ebx),%eax
  80091c:	0f b6 12             	movzbl (%edx),%edx
  80091f:	29 d0                	sub    %edx,%eax
}
  800921:	5b                   	pop    %ebx
  800922:	5e                   	pop    %esi
  800923:	5d                   	pop    %ebp
  800924:	c3                   	ret    

00800925 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800925:	55                   	push   %ebp
  800926:	89 e5                	mov    %esp,%ebp
  800928:	53                   	push   %ebx
  800929:	8b 45 08             	mov    0x8(%ebp),%eax
  80092c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  80092f:	0f b6 18             	movzbl (%eax),%ebx
  800932:	84 db                	test   %bl,%bl
  800934:	74 1d                	je     800953 <strchr+0x2e>
  800936:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800938:	38 d3                	cmp    %dl,%bl
  80093a:	75 06                	jne    800942 <strchr+0x1d>
  80093c:	eb 1a                	jmp    800958 <strchr+0x33>
  80093e:	38 ca                	cmp    %cl,%dl
  800940:	74 16                	je     800958 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800942:	83 c0 01             	add    $0x1,%eax
  800945:	0f b6 10             	movzbl (%eax),%edx
  800948:	84 d2                	test   %dl,%dl
  80094a:	75 f2                	jne    80093e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  80094c:	b8 00 00 00 00       	mov    $0x0,%eax
  800951:	eb 05                	jmp    800958 <strchr+0x33>
  800953:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800958:	5b                   	pop    %ebx
  800959:	5d                   	pop    %ebp
  80095a:	c3                   	ret    

0080095b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80095b:	55                   	push   %ebp
  80095c:	89 e5                	mov    %esp,%ebp
  80095e:	53                   	push   %ebx
  80095f:	8b 45 08             	mov    0x8(%ebp),%eax
  800962:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800965:	0f b6 18             	movzbl (%eax),%ebx
  800968:	84 db                	test   %bl,%bl
  80096a:	74 16                	je     800982 <strfind+0x27>
  80096c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  80096e:	38 d3                	cmp    %dl,%bl
  800970:	75 06                	jne    800978 <strfind+0x1d>
  800972:	eb 0e                	jmp    800982 <strfind+0x27>
  800974:	38 ca                	cmp    %cl,%dl
  800976:	74 0a                	je     800982 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800978:	83 c0 01             	add    $0x1,%eax
  80097b:	0f b6 10             	movzbl (%eax),%edx
  80097e:	84 d2                	test   %dl,%dl
  800980:	75 f2                	jne    800974 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800982:	5b                   	pop    %ebx
  800983:	5d                   	pop    %ebp
  800984:	c3                   	ret    

00800985 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800985:	55                   	push   %ebp
  800986:	89 e5                	mov    %esp,%ebp
  800988:	83 ec 0c             	sub    $0xc,%esp
  80098b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80098e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800991:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800994:	8b 7d 08             	mov    0x8(%ebp),%edi
  800997:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80099a:	85 c9                	test   %ecx,%ecx
  80099c:	74 36                	je     8009d4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80099e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009a4:	75 28                	jne    8009ce <memset+0x49>
  8009a6:	f6 c1 03             	test   $0x3,%cl
  8009a9:	75 23                	jne    8009ce <memset+0x49>
		c &= 0xFF;
  8009ab:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009af:	89 d3                	mov    %edx,%ebx
  8009b1:	c1 e3 08             	shl    $0x8,%ebx
  8009b4:	89 d6                	mov    %edx,%esi
  8009b6:	c1 e6 18             	shl    $0x18,%esi
  8009b9:	89 d0                	mov    %edx,%eax
  8009bb:	c1 e0 10             	shl    $0x10,%eax
  8009be:	09 f0                	or     %esi,%eax
  8009c0:	09 c2                	or     %eax,%edx
  8009c2:	89 d0                	mov    %edx,%eax
  8009c4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009c6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009c9:	fc                   	cld    
  8009ca:	f3 ab                	rep stos %eax,%es:(%edi)
  8009cc:	eb 06                	jmp    8009d4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009d1:	fc                   	cld    
  8009d2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009d4:	89 f8                	mov    %edi,%eax
  8009d6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8009d9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8009dc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8009df:	89 ec                	mov    %ebp,%esp
  8009e1:	5d                   	pop    %ebp
  8009e2:	c3                   	ret    

008009e3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009e3:	55                   	push   %ebp
  8009e4:	89 e5                	mov    %esp,%ebp
  8009e6:	83 ec 08             	sub    $0x8,%esp
  8009e9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8009ec:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009ef:	8b 45 08             	mov    0x8(%ebp),%eax
  8009f2:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009f5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009f8:	39 c6                	cmp    %eax,%esi
  8009fa:	73 36                	jae    800a32 <memmove+0x4f>
  8009fc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009ff:	39 d0                	cmp    %edx,%eax
  800a01:	73 2f                	jae    800a32 <memmove+0x4f>
		s += n;
		d += n;
  800a03:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a06:	f6 c2 03             	test   $0x3,%dl
  800a09:	75 1b                	jne    800a26 <memmove+0x43>
  800a0b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a11:	75 13                	jne    800a26 <memmove+0x43>
  800a13:	f6 c1 03             	test   $0x3,%cl
  800a16:	75 0e                	jne    800a26 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a18:	83 ef 04             	sub    $0x4,%edi
  800a1b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a1e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a21:	fd                   	std    
  800a22:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a24:	eb 09                	jmp    800a2f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a26:	83 ef 01             	sub    $0x1,%edi
  800a29:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a2c:	fd                   	std    
  800a2d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a2f:	fc                   	cld    
  800a30:	eb 20                	jmp    800a52 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a32:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a38:	75 13                	jne    800a4d <memmove+0x6a>
  800a3a:	a8 03                	test   $0x3,%al
  800a3c:	75 0f                	jne    800a4d <memmove+0x6a>
  800a3e:	f6 c1 03             	test   $0x3,%cl
  800a41:	75 0a                	jne    800a4d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a43:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a46:	89 c7                	mov    %eax,%edi
  800a48:	fc                   	cld    
  800a49:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a4b:	eb 05                	jmp    800a52 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a4d:	89 c7                	mov    %eax,%edi
  800a4f:	fc                   	cld    
  800a50:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a52:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a55:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a58:	89 ec                	mov    %ebp,%esp
  800a5a:	5d                   	pop    %ebp
  800a5b:	c3                   	ret    

00800a5c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800a5c:	55                   	push   %ebp
  800a5d:	89 e5                	mov    %esp,%ebp
  800a5f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a62:	8b 45 10             	mov    0x10(%ebp),%eax
  800a65:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a69:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a6c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a70:	8b 45 08             	mov    0x8(%ebp),%eax
  800a73:	89 04 24             	mov    %eax,(%esp)
  800a76:	e8 68 ff ff ff       	call   8009e3 <memmove>
}
  800a7b:	c9                   	leave  
  800a7c:	c3                   	ret    

00800a7d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a7d:	55                   	push   %ebp
  800a7e:	89 e5                	mov    %esp,%ebp
  800a80:	57                   	push   %edi
  800a81:	56                   	push   %esi
  800a82:	53                   	push   %ebx
  800a83:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a86:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a89:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a8c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800a8f:	85 c0                	test   %eax,%eax
  800a91:	74 36                	je     800ac9 <memcmp+0x4c>
		if (*s1 != *s2)
  800a93:	0f b6 03             	movzbl (%ebx),%eax
  800a96:	0f b6 0e             	movzbl (%esi),%ecx
  800a99:	38 c8                	cmp    %cl,%al
  800a9b:	75 17                	jne    800ab4 <memcmp+0x37>
  800a9d:	ba 00 00 00 00       	mov    $0x0,%edx
  800aa2:	eb 1a                	jmp    800abe <memcmp+0x41>
  800aa4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800aa9:	83 c2 01             	add    $0x1,%edx
  800aac:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800ab0:	38 c8                	cmp    %cl,%al
  800ab2:	74 0a                	je     800abe <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800ab4:	0f b6 c0             	movzbl %al,%eax
  800ab7:	0f b6 c9             	movzbl %cl,%ecx
  800aba:	29 c8                	sub    %ecx,%eax
  800abc:	eb 10                	jmp    800ace <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800abe:	39 fa                	cmp    %edi,%edx
  800ac0:	75 e2                	jne    800aa4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800ac2:	b8 00 00 00 00       	mov    $0x0,%eax
  800ac7:	eb 05                	jmp    800ace <memcmp+0x51>
  800ac9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ace:	5b                   	pop    %ebx
  800acf:	5e                   	pop    %esi
  800ad0:	5f                   	pop    %edi
  800ad1:	5d                   	pop    %ebp
  800ad2:	c3                   	ret    

00800ad3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ad3:	55                   	push   %ebp
  800ad4:	89 e5                	mov    %esp,%ebp
  800ad6:	53                   	push   %ebx
  800ad7:	8b 45 08             	mov    0x8(%ebp),%eax
  800ada:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800add:	89 c2                	mov    %eax,%edx
  800adf:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ae2:	39 d0                	cmp    %edx,%eax
  800ae4:	73 13                	jae    800af9 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ae6:	89 d9                	mov    %ebx,%ecx
  800ae8:	38 18                	cmp    %bl,(%eax)
  800aea:	75 06                	jne    800af2 <memfind+0x1f>
  800aec:	eb 0b                	jmp    800af9 <memfind+0x26>
  800aee:	38 08                	cmp    %cl,(%eax)
  800af0:	74 07                	je     800af9 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800af2:	83 c0 01             	add    $0x1,%eax
  800af5:	39 d0                	cmp    %edx,%eax
  800af7:	75 f5                	jne    800aee <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800af9:	5b                   	pop    %ebx
  800afa:	5d                   	pop    %ebp
  800afb:	c3                   	ret    

00800afc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800afc:	55                   	push   %ebp
  800afd:	89 e5                	mov    %esp,%ebp
  800aff:	57                   	push   %edi
  800b00:	56                   	push   %esi
  800b01:	53                   	push   %ebx
  800b02:	83 ec 04             	sub    $0x4,%esp
  800b05:	8b 55 08             	mov    0x8(%ebp),%edx
  800b08:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b0b:	0f b6 02             	movzbl (%edx),%eax
  800b0e:	3c 09                	cmp    $0x9,%al
  800b10:	74 04                	je     800b16 <strtol+0x1a>
  800b12:	3c 20                	cmp    $0x20,%al
  800b14:	75 0e                	jne    800b24 <strtol+0x28>
		s++;
  800b16:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b19:	0f b6 02             	movzbl (%edx),%eax
  800b1c:	3c 09                	cmp    $0x9,%al
  800b1e:	74 f6                	je     800b16 <strtol+0x1a>
  800b20:	3c 20                	cmp    $0x20,%al
  800b22:	74 f2                	je     800b16 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b24:	3c 2b                	cmp    $0x2b,%al
  800b26:	75 0a                	jne    800b32 <strtol+0x36>
		s++;
  800b28:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b2b:	bf 00 00 00 00       	mov    $0x0,%edi
  800b30:	eb 10                	jmp    800b42 <strtol+0x46>
  800b32:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b37:	3c 2d                	cmp    $0x2d,%al
  800b39:	75 07                	jne    800b42 <strtol+0x46>
		s++, neg = 1;
  800b3b:	83 c2 01             	add    $0x1,%edx
  800b3e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b42:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b48:	75 15                	jne    800b5f <strtol+0x63>
  800b4a:	80 3a 30             	cmpb   $0x30,(%edx)
  800b4d:	75 10                	jne    800b5f <strtol+0x63>
  800b4f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b53:	75 0a                	jne    800b5f <strtol+0x63>
		s += 2, base = 16;
  800b55:	83 c2 02             	add    $0x2,%edx
  800b58:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b5d:	eb 10                	jmp    800b6f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800b5f:	85 db                	test   %ebx,%ebx
  800b61:	75 0c                	jne    800b6f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b63:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b65:	80 3a 30             	cmpb   $0x30,(%edx)
  800b68:	75 05                	jne    800b6f <strtol+0x73>
		s++, base = 8;
  800b6a:	83 c2 01             	add    $0x1,%edx
  800b6d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800b6f:	b8 00 00 00 00       	mov    $0x0,%eax
  800b74:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b77:	0f b6 0a             	movzbl (%edx),%ecx
  800b7a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b7d:	89 f3                	mov    %esi,%ebx
  800b7f:	80 fb 09             	cmp    $0x9,%bl
  800b82:	77 08                	ja     800b8c <strtol+0x90>
			dig = *s - '0';
  800b84:	0f be c9             	movsbl %cl,%ecx
  800b87:	83 e9 30             	sub    $0x30,%ecx
  800b8a:	eb 22                	jmp    800bae <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800b8c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b8f:	89 f3                	mov    %esi,%ebx
  800b91:	80 fb 19             	cmp    $0x19,%bl
  800b94:	77 08                	ja     800b9e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800b96:	0f be c9             	movsbl %cl,%ecx
  800b99:	83 e9 57             	sub    $0x57,%ecx
  800b9c:	eb 10                	jmp    800bae <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800b9e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800ba1:	89 f3                	mov    %esi,%ebx
  800ba3:	80 fb 19             	cmp    $0x19,%bl
  800ba6:	77 16                	ja     800bbe <strtol+0xc2>
			dig = *s - 'A' + 10;
  800ba8:	0f be c9             	movsbl %cl,%ecx
  800bab:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800bae:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800bb1:	7d 0f                	jge    800bc2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800bb3:	83 c2 01             	add    $0x1,%edx
  800bb6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800bba:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800bbc:	eb b9                	jmp    800b77 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800bbe:	89 c1                	mov    %eax,%ecx
  800bc0:	eb 02                	jmp    800bc4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800bc2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800bc4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bc8:	74 05                	je     800bcf <strtol+0xd3>
		*endptr = (char *) s;
  800bca:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800bcd:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800bcf:	89 ca                	mov    %ecx,%edx
  800bd1:	f7 da                	neg    %edx
  800bd3:	85 ff                	test   %edi,%edi
  800bd5:	0f 45 c2             	cmovne %edx,%eax
}
  800bd8:	83 c4 04             	add    $0x4,%esp
  800bdb:	5b                   	pop    %ebx
  800bdc:	5e                   	pop    %esi
  800bdd:	5f                   	pop    %edi
  800bde:	5d                   	pop    %ebp
  800bdf:	c3                   	ret    

00800be0 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800be0:	55                   	push   %ebp
  800be1:	89 e5                	mov    %esp,%ebp
  800be3:	83 ec 0c             	sub    $0xc,%esp
  800be6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800be9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800bec:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bef:	b8 00 00 00 00       	mov    $0x0,%eax
  800bf4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bf7:	8b 55 08             	mov    0x8(%ebp),%edx
  800bfa:	89 c3                	mov    %eax,%ebx
  800bfc:	89 c7                	mov    %eax,%edi
  800bfe:	89 c6                	mov    %eax,%esi
  800c00:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c02:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c05:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c08:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c0b:	89 ec                	mov    %ebp,%esp
  800c0d:	5d                   	pop    %ebp
  800c0e:	c3                   	ret    

00800c0f <sys_cgetc>:

int
sys_cgetc(void)
{
  800c0f:	55                   	push   %ebp
  800c10:	89 e5                	mov    %esp,%ebp
  800c12:	83 ec 0c             	sub    $0xc,%esp
  800c15:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c18:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c1b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c1e:	ba 00 00 00 00       	mov    $0x0,%edx
  800c23:	b8 01 00 00 00       	mov    $0x1,%eax
  800c28:	89 d1                	mov    %edx,%ecx
  800c2a:	89 d3                	mov    %edx,%ebx
  800c2c:	89 d7                	mov    %edx,%edi
  800c2e:	89 d6                	mov    %edx,%esi
  800c30:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c32:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c35:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c38:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c3b:	89 ec                	mov    %ebp,%esp
  800c3d:	5d                   	pop    %ebp
  800c3e:	c3                   	ret    

00800c3f <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c3f:	55                   	push   %ebp
  800c40:	89 e5                	mov    %esp,%ebp
  800c42:	83 ec 38             	sub    $0x38,%esp
  800c45:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c48:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c4b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c4e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c53:	b8 03 00 00 00       	mov    $0x3,%eax
  800c58:	8b 55 08             	mov    0x8(%ebp),%edx
  800c5b:	89 cb                	mov    %ecx,%ebx
  800c5d:	89 cf                	mov    %ecx,%edi
  800c5f:	89 ce                	mov    %ecx,%esi
  800c61:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c63:	85 c0                	test   %eax,%eax
  800c65:	7e 28                	jle    800c8f <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c67:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c6b:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800c72:	00 
  800c73:	c7 44 24 08 3c 12 80 	movl   $0x80123c,0x8(%esp)
  800c7a:	00 
  800c7b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c82:	00 
  800c83:	c7 04 24 59 12 80 00 	movl   $0x801259,(%esp)
  800c8a:	e8 3d 00 00 00       	call   800ccc <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c8f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c92:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c95:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c98:	89 ec                	mov    %ebp,%esp
  800c9a:	5d                   	pop    %ebp
  800c9b:	c3                   	ret    

00800c9c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c9c:	55                   	push   %ebp
  800c9d:	89 e5                	mov    %esp,%ebp
  800c9f:	83 ec 0c             	sub    $0xc,%esp
  800ca2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ca5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ca8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cab:	ba 00 00 00 00       	mov    $0x0,%edx
  800cb0:	b8 02 00 00 00       	mov    $0x2,%eax
  800cb5:	89 d1                	mov    %edx,%ecx
  800cb7:	89 d3                	mov    %edx,%ebx
  800cb9:	89 d7                	mov    %edx,%edi
  800cbb:	89 d6                	mov    %edx,%esi
  800cbd:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800cbf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800cc2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cc5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cc8:	89 ec                	mov    %ebp,%esp
  800cca:	5d                   	pop    %ebp
  800ccb:	c3                   	ret    

00800ccc <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800ccc:	55                   	push   %ebp
  800ccd:	89 e5                	mov    %esp,%ebp
  800ccf:	56                   	push   %esi
  800cd0:	53                   	push   %ebx
  800cd1:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800cd4:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800cd7:	a1 0c 20 80 00       	mov    0x80200c,%eax
  800cdc:	85 c0                	test   %eax,%eax
  800cde:	74 10                	je     800cf0 <_panic+0x24>
		cprintf("%s: ", argv0);
  800ce0:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ce4:	c7 04 24 67 12 80 00 	movl   $0x801267,(%esp)
  800ceb:	e8 67 f4 ff ff       	call   800157 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800cf0:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800cf6:	e8 a1 ff ff ff       	call   800c9c <sys_getenvid>
  800cfb:	8b 55 0c             	mov    0xc(%ebp),%edx
  800cfe:	89 54 24 10          	mov    %edx,0x10(%esp)
  800d02:	8b 55 08             	mov    0x8(%ebp),%edx
  800d05:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800d09:	89 74 24 08          	mov    %esi,0x8(%esp)
  800d0d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d11:	c7 04 24 6c 12 80 00 	movl   $0x80126c,(%esp)
  800d18:	e8 3a f4 ff ff       	call   800157 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800d1d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800d21:	8b 45 10             	mov    0x10(%ebp),%eax
  800d24:	89 04 24             	mov    %eax,(%esp)
  800d27:	e8 ca f3 ff ff       	call   8000f6 <vcprintf>
	cprintf("\n");
  800d2c:	c7 04 24 2c 10 80 00 	movl   $0x80102c,(%esp)
  800d33:	e8 1f f4 ff ff       	call   800157 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800d38:	cc                   	int3   
  800d39:	eb fd                	jmp    800d38 <_panic+0x6c>
  800d3b:	66 90                	xchg   %ax,%ax
  800d3d:	66 90                	xchg   %ax,%ax
  800d3f:	90                   	nop

00800d40 <__udivdi3>:
  800d40:	83 ec 1c             	sub    $0x1c,%esp
  800d43:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800d47:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d4b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d4f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d53:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800d57:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800d5b:	85 c0                	test   %eax,%eax
  800d5d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d61:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d65:	89 ea                	mov    %ebp,%edx
  800d67:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800d6b:	75 33                	jne    800da0 <__udivdi3+0x60>
  800d6d:	39 e9                	cmp    %ebp,%ecx
  800d6f:	77 6f                	ja     800de0 <__udivdi3+0xa0>
  800d71:	85 c9                	test   %ecx,%ecx
  800d73:	89 ce                	mov    %ecx,%esi
  800d75:	75 0b                	jne    800d82 <__udivdi3+0x42>
  800d77:	b8 01 00 00 00       	mov    $0x1,%eax
  800d7c:	31 d2                	xor    %edx,%edx
  800d7e:	f7 f1                	div    %ecx
  800d80:	89 c6                	mov    %eax,%esi
  800d82:	31 d2                	xor    %edx,%edx
  800d84:	89 e8                	mov    %ebp,%eax
  800d86:	f7 f6                	div    %esi
  800d88:	89 c5                	mov    %eax,%ebp
  800d8a:	89 f8                	mov    %edi,%eax
  800d8c:	f7 f6                	div    %esi
  800d8e:	89 ea                	mov    %ebp,%edx
  800d90:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d94:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d98:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d9c:	83 c4 1c             	add    $0x1c,%esp
  800d9f:	c3                   	ret    
  800da0:	39 e8                	cmp    %ebp,%eax
  800da2:	77 24                	ja     800dc8 <__udivdi3+0x88>
  800da4:	0f bd c8             	bsr    %eax,%ecx
  800da7:	83 f1 1f             	xor    $0x1f,%ecx
  800daa:	89 0c 24             	mov    %ecx,(%esp)
  800dad:	75 49                	jne    800df8 <__udivdi3+0xb8>
  800daf:	8b 74 24 08          	mov    0x8(%esp),%esi
  800db3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800db7:	0f 86 ab 00 00 00    	jbe    800e68 <__udivdi3+0x128>
  800dbd:	39 e8                	cmp    %ebp,%eax
  800dbf:	0f 82 a3 00 00 00    	jb     800e68 <__udivdi3+0x128>
  800dc5:	8d 76 00             	lea    0x0(%esi),%esi
  800dc8:	31 d2                	xor    %edx,%edx
  800dca:	31 c0                	xor    %eax,%eax
  800dcc:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dd0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dd4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dd8:	83 c4 1c             	add    $0x1c,%esp
  800ddb:	c3                   	ret    
  800ddc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800de0:	89 f8                	mov    %edi,%eax
  800de2:	f7 f1                	div    %ecx
  800de4:	31 d2                	xor    %edx,%edx
  800de6:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dea:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dee:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800df2:	83 c4 1c             	add    $0x1c,%esp
  800df5:	c3                   	ret    
  800df6:	66 90                	xchg   %ax,%ax
  800df8:	0f b6 0c 24          	movzbl (%esp),%ecx
  800dfc:	89 c6                	mov    %eax,%esi
  800dfe:	b8 20 00 00 00       	mov    $0x20,%eax
  800e03:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800e07:	2b 04 24             	sub    (%esp),%eax
  800e0a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800e0e:	d3 e6                	shl    %cl,%esi
  800e10:	89 c1                	mov    %eax,%ecx
  800e12:	d3 ed                	shr    %cl,%ebp
  800e14:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e18:	09 f5                	or     %esi,%ebp
  800e1a:	8b 74 24 04          	mov    0x4(%esp),%esi
  800e1e:	d3 e6                	shl    %cl,%esi
  800e20:	89 c1                	mov    %eax,%ecx
  800e22:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e26:	89 d6                	mov    %edx,%esi
  800e28:	d3 ee                	shr    %cl,%esi
  800e2a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e2e:	d3 e2                	shl    %cl,%edx
  800e30:	89 c1                	mov    %eax,%ecx
  800e32:	d3 ef                	shr    %cl,%edi
  800e34:	09 d7                	or     %edx,%edi
  800e36:	89 f2                	mov    %esi,%edx
  800e38:	89 f8                	mov    %edi,%eax
  800e3a:	f7 f5                	div    %ebp
  800e3c:	89 d6                	mov    %edx,%esi
  800e3e:	89 c7                	mov    %eax,%edi
  800e40:	f7 64 24 04          	mull   0x4(%esp)
  800e44:	39 d6                	cmp    %edx,%esi
  800e46:	72 30                	jb     800e78 <__udivdi3+0x138>
  800e48:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800e4c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e50:	d3 e5                	shl    %cl,%ebp
  800e52:	39 c5                	cmp    %eax,%ebp
  800e54:	73 04                	jae    800e5a <__udivdi3+0x11a>
  800e56:	39 d6                	cmp    %edx,%esi
  800e58:	74 1e                	je     800e78 <__udivdi3+0x138>
  800e5a:	89 f8                	mov    %edi,%eax
  800e5c:	31 d2                	xor    %edx,%edx
  800e5e:	e9 69 ff ff ff       	jmp    800dcc <__udivdi3+0x8c>
  800e63:	90                   	nop
  800e64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e68:	31 d2                	xor    %edx,%edx
  800e6a:	b8 01 00 00 00       	mov    $0x1,%eax
  800e6f:	e9 58 ff ff ff       	jmp    800dcc <__udivdi3+0x8c>
  800e74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e78:	8d 47 ff             	lea    -0x1(%edi),%eax
  800e7b:	31 d2                	xor    %edx,%edx
  800e7d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e81:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e85:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e89:	83 c4 1c             	add    $0x1c,%esp
  800e8c:	c3                   	ret    
  800e8d:	66 90                	xchg   %ax,%ax
  800e8f:	90                   	nop

00800e90 <__umoddi3>:
  800e90:	83 ec 2c             	sub    $0x2c,%esp
  800e93:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800e97:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800e9b:	89 74 24 20          	mov    %esi,0x20(%esp)
  800e9f:	8b 74 24 38          	mov    0x38(%esp),%esi
  800ea3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800ea7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800eab:	85 c0                	test   %eax,%eax
  800ead:	89 c2                	mov    %eax,%edx
  800eaf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800eb3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800eb7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ebb:	89 74 24 10          	mov    %esi,0x10(%esp)
  800ebf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800ec3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ec7:	75 1f                	jne    800ee8 <__umoddi3+0x58>
  800ec9:	39 fe                	cmp    %edi,%esi
  800ecb:	76 63                	jbe    800f30 <__umoddi3+0xa0>
  800ecd:	89 c8                	mov    %ecx,%eax
  800ecf:	89 fa                	mov    %edi,%edx
  800ed1:	f7 f6                	div    %esi
  800ed3:	89 d0                	mov    %edx,%eax
  800ed5:	31 d2                	xor    %edx,%edx
  800ed7:	8b 74 24 20          	mov    0x20(%esp),%esi
  800edb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800edf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800ee3:	83 c4 2c             	add    $0x2c,%esp
  800ee6:	c3                   	ret    
  800ee7:	90                   	nop
  800ee8:	39 f8                	cmp    %edi,%eax
  800eea:	77 64                	ja     800f50 <__umoddi3+0xc0>
  800eec:	0f bd e8             	bsr    %eax,%ebp
  800eef:	83 f5 1f             	xor    $0x1f,%ebp
  800ef2:	75 74                	jne    800f68 <__umoddi3+0xd8>
  800ef4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800ef8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800efc:	0f 87 0e 01 00 00    	ja     801010 <__umoddi3+0x180>
  800f02:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800f06:	29 f1                	sub    %esi,%ecx
  800f08:	19 c7                	sbb    %eax,%edi
  800f0a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800f0e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800f12:	8b 44 24 14          	mov    0x14(%esp),%eax
  800f16:	8b 54 24 18          	mov    0x18(%esp),%edx
  800f1a:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f1e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f22:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f26:	83 c4 2c             	add    $0x2c,%esp
  800f29:	c3                   	ret    
  800f2a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f30:	85 f6                	test   %esi,%esi
  800f32:	89 f5                	mov    %esi,%ebp
  800f34:	75 0b                	jne    800f41 <__umoddi3+0xb1>
  800f36:	b8 01 00 00 00       	mov    $0x1,%eax
  800f3b:	31 d2                	xor    %edx,%edx
  800f3d:	f7 f6                	div    %esi
  800f3f:	89 c5                	mov    %eax,%ebp
  800f41:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f45:	31 d2                	xor    %edx,%edx
  800f47:	f7 f5                	div    %ebp
  800f49:	89 c8                	mov    %ecx,%eax
  800f4b:	f7 f5                	div    %ebp
  800f4d:	eb 84                	jmp    800ed3 <__umoddi3+0x43>
  800f4f:	90                   	nop
  800f50:	89 c8                	mov    %ecx,%eax
  800f52:	89 fa                	mov    %edi,%edx
  800f54:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f58:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f5c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f60:	83 c4 2c             	add    $0x2c,%esp
  800f63:	c3                   	ret    
  800f64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f68:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f6c:	be 20 00 00 00       	mov    $0x20,%esi
  800f71:	89 e9                	mov    %ebp,%ecx
  800f73:	29 ee                	sub    %ebp,%esi
  800f75:	d3 e2                	shl    %cl,%edx
  800f77:	89 f1                	mov    %esi,%ecx
  800f79:	d3 e8                	shr    %cl,%eax
  800f7b:	89 e9                	mov    %ebp,%ecx
  800f7d:	09 d0                	or     %edx,%eax
  800f7f:	89 fa                	mov    %edi,%edx
  800f81:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800f85:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f89:	d3 e0                	shl    %cl,%eax
  800f8b:	89 f1                	mov    %esi,%ecx
  800f8d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f91:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800f95:	d3 ea                	shr    %cl,%edx
  800f97:	89 e9                	mov    %ebp,%ecx
  800f99:	d3 e7                	shl    %cl,%edi
  800f9b:	89 f1                	mov    %esi,%ecx
  800f9d:	d3 e8                	shr    %cl,%eax
  800f9f:	89 e9                	mov    %ebp,%ecx
  800fa1:	09 f8                	or     %edi,%eax
  800fa3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800fa7:	f7 74 24 0c          	divl   0xc(%esp)
  800fab:	d3 e7                	shl    %cl,%edi
  800fad:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800fb1:	89 d7                	mov    %edx,%edi
  800fb3:	f7 64 24 10          	mull   0x10(%esp)
  800fb7:	39 d7                	cmp    %edx,%edi
  800fb9:	89 c1                	mov    %eax,%ecx
  800fbb:	89 54 24 14          	mov    %edx,0x14(%esp)
  800fbf:	72 3b                	jb     800ffc <__umoddi3+0x16c>
  800fc1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800fc5:	72 31                	jb     800ff8 <__umoddi3+0x168>
  800fc7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800fcb:	29 c8                	sub    %ecx,%eax
  800fcd:	19 d7                	sbb    %edx,%edi
  800fcf:	89 e9                	mov    %ebp,%ecx
  800fd1:	89 fa                	mov    %edi,%edx
  800fd3:	d3 e8                	shr    %cl,%eax
  800fd5:	89 f1                	mov    %esi,%ecx
  800fd7:	d3 e2                	shl    %cl,%edx
  800fd9:	89 e9                	mov    %ebp,%ecx
  800fdb:	09 d0                	or     %edx,%eax
  800fdd:	89 fa                	mov    %edi,%edx
  800fdf:	d3 ea                	shr    %cl,%edx
  800fe1:	8b 74 24 20          	mov    0x20(%esp),%esi
  800fe5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800fe9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800fed:	83 c4 2c             	add    $0x2c,%esp
  800ff0:	c3                   	ret    
  800ff1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ff8:	39 d7                	cmp    %edx,%edi
  800ffa:	75 cb                	jne    800fc7 <__umoddi3+0x137>
  800ffc:	8b 54 24 14          	mov    0x14(%esp),%edx
  801000:	89 c1                	mov    %eax,%ecx
  801002:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801006:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80100a:	eb bb                	jmp    800fc7 <__umoddi3+0x137>
  80100c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801010:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801014:	0f 82 e8 fe ff ff    	jb     800f02 <__umoddi3+0x72>
  80101a:	e9 f3 fe ff ff       	jmp    800f12 <__umoddi3+0x82>

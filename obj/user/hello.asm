
obj/user/hello：     文件格式 elf32-i386


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
  80002c:	e8 2f 00 00 00       	call   800060 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	90                   	nop

00800034 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	cprintf("hello, world\n");
  80003a:	c7 04 24 10 10 80 00 	movl   $0x801010,(%esp)
  800041:	e8 09 01 00 00       	call   80014f <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800046:	a1 04 20 80 00       	mov    0x802004,%eax
  80004b:	8b 40 48             	mov    0x48(%eax),%eax
  80004e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800052:	c7 04 24 1e 10 80 00 	movl   $0x80101e,(%esp)
  800059:	e8 f1 00 00 00       	call   80014f <cprintf>
}
  80005e:	c9                   	leave  
  80005f:	c3                   	ret    

00800060 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800060:	55                   	push   %ebp
  800061:	89 e5                	mov    %esp,%ebp
  800063:	83 ec 18             	sub    $0x18,%esp
  800066:	8b 45 08             	mov    0x8(%ebp),%eax
  800069:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80006c:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800073:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800076:	85 c0                	test   %eax,%eax
  800078:	7e 08                	jle    800082 <libmain+0x22>
		binaryname = argv[0];
  80007a:	8b 0a                	mov    (%edx),%ecx
  80007c:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800082:	89 54 24 04          	mov    %edx,0x4(%esp)
  800086:	89 04 24             	mov    %eax,(%esp)
  800089:	e8 a6 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  80008e:	e8 05 00 00 00       	call   800098 <exit>
}
  800093:	c9                   	leave  
  800094:	c3                   	ret    
  800095:	66 90                	xchg   %ax,%ax
  800097:	90                   	nop

00800098 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800098:	55                   	push   %ebp
  800099:	89 e5                	mov    %esp,%ebp
  80009b:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80009e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000a5:	e8 85 0b 00 00       	call   800c2f <sys_env_destroy>
}
  8000aa:	c9                   	leave  
  8000ab:	c3                   	ret    

008000ac <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000ac:	55                   	push   %ebp
  8000ad:	89 e5                	mov    %esp,%ebp
  8000af:	53                   	push   %ebx
  8000b0:	83 ec 14             	sub    $0x14,%esp
  8000b3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b6:	8b 03                	mov    (%ebx),%eax
  8000b8:	8b 55 08             	mov    0x8(%ebp),%edx
  8000bb:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8000bf:	83 c0 01             	add    $0x1,%eax
  8000c2:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8000c4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c9:	75 19                	jne    8000e4 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000cb:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000d2:	00 
  8000d3:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d6:	89 04 24             	mov    %eax,(%esp)
  8000d9:	e8 f2 0a 00 00       	call   800bd0 <sys_cputs>
		b->idx = 0;
  8000de:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000e4:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e8:	83 c4 14             	add    $0x14,%esp
  8000eb:	5b                   	pop    %ebx
  8000ec:	5d                   	pop    %ebp
  8000ed:	c3                   	ret    

008000ee <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000ee:	55                   	push   %ebp
  8000ef:	89 e5                	mov    %esp,%ebp
  8000f1:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8000f7:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000fe:	00 00 00 
	b.cnt = 0;
  800101:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800108:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80010b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80010e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800112:	8b 45 08             	mov    0x8(%ebp),%eax
  800115:	89 44 24 08          	mov    %eax,0x8(%esp)
  800119:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80011f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800123:	c7 04 24 ac 00 80 00 	movl   $0x8000ac,(%esp)
  80012a:	e8 b3 01 00 00       	call   8002e2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80012f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800135:	89 44 24 04          	mov    %eax,0x4(%esp)
  800139:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80013f:	89 04 24             	mov    %eax,(%esp)
  800142:	e8 89 0a 00 00       	call   800bd0 <sys_cputs>

	return b.cnt;
}
  800147:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80014d:	c9                   	leave  
  80014e:	c3                   	ret    

0080014f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014f:	55                   	push   %ebp
  800150:	89 e5                	mov    %esp,%ebp
  800152:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800155:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800158:	89 44 24 04          	mov    %eax,0x4(%esp)
  80015c:	8b 45 08             	mov    0x8(%ebp),%eax
  80015f:	89 04 24             	mov    %eax,(%esp)
  800162:	e8 87 ff ff ff       	call   8000ee <vcprintf>
	va_end(ap);

	return cnt;
}
  800167:	c9                   	leave  
  800168:	c3                   	ret    
  800169:	66 90                	xchg   %ax,%ax
  80016b:	66 90                	xchg   %ax,%ax
  80016d:	66 90                	xchg   %ax,%ax
  80016f:	90                   	nop

00800170 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800170:	55                   	push   %ebp
  800171:	89 e5                	mov    %esp,%ebp
  800173:	57                   	push   %edi
  800174:	56                   	push   %esi
  800175:	53                   	push   %ebx
  800176:	83 ec 4c             	sub    $0x4c,%esp
  800179:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80017c:	89 d7                	mov    %edx,%edi
  80017e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800181:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800184:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800187:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80018a:	b8 00 00 00 00       	mov    $0x0,%eax
  80018f:	39 d8                	cmp    %ebx,%eax
  800191:	72 17                	jb     8001aa <printnum+0x3a>
  800193:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800196:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800199:	76 0f                	jbe    8001aa <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80019b:	8b 75 14             	mov    0x14(%ebp),%esi
  80019e:	83 ee 01             	sub    $0x1,%esi
  8001a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8001a4:	85 f6                	test   %esi,%esi
  8001a6:	7f 63                	jg     80020b <printnum+0x9b>
  8001a8:	eb 75                	jmp    80021f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001aa:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8001ad:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8001b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8001b4:	83 e8 01             	sub    $0x1,%eax
  8001b7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001bb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8001c2:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001c6:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8001cd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8001d0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8001d7:	00 
  8001d8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8001db:	89 1c 24             	mov    %ebx,(%esp)
  8001de:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8001e1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001e5:	e8 46 0b 00 00       	call   800d30 <__udivdi3>
  8001ea:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8001ed:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8001f0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001f4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8001f8:	89 04 24             	mov    %eax,(%esp)
  8001fb:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001ff:	89 fa                	mov    %edi,%edx
  800201:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800204:	e8 67 ff ff ff       	call   800170 <printnum>
  800209:	eb 14                	jmp    80021f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80020b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80020f:	8b 45 18             	mov    0x18(%ebp),%eax
  800212:	89 04 24             	mov    %eax,(%esp)
  800215:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800217:	83 ee 01             	sub    $0x1,%esi
  80021a:	75 ef                	jne    80020b <printnum+0x9b>
  80021c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80021f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800223:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800227:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80022a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80022e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800235:	00 
  800236:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800239:	89 1c 24             	mov    %ebx,(%esp)
  80023c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80023f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800243:	e8 38 0c 00 00       	call   800e80 <__umoddi3>
  800248:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80024c:	0f be 80 3f 10 80 00 	movsbl 0x80103f(%eax),%eax
  800253:	89 04 24             	mov    %eax,(%esp)
  800256:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800259:	ff d0                	call   *%eax
}
  80025b:	83 c4 4c             	add    $0x4c,%esp
  80025e:	5b                   	pop    %ebx
  80025f:	5e                   	pop    %esi
  800260:	5f                   	pop    %edi
  800261:	5d                   	pop    %ebp
  800262:	c3                   	ret    

00800263 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800263:	55                   	push   %ebp
  800264:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800266:	83 fa 01             	cmp    $0x1,%edx
  800269:	7e 0e                	jle    800279 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80026b:	8b 10                	mov    (%eax),%edx
  80026d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800270:	89 08                	mov    %ecx,(%eax)
  800272:	8b 02                	mov    (%edx),%eax
  800274:	8b 52 04             	mov    0x4(%edx),%edx
  800277:	eb 22                	jmp    80029b <getuint+0x38>
	else if (lflag)
  800279:	85 d2                	test   %edx,%edx
  80027b:	74 10                	je     80028d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80027d:	8b 10                	mov    (%eax),%edx
  80027f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800282:	89 08                	mov    %ecx,(%eax)
  800284:	8b 02                	mov    (%edx),%eax
  800286:	ba 00 00 00 00       	mov    $0x0,%edx
  80028b:	eb 0e                	jmp    80029b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80028d:	8b 10                	mov    (%eax),%edx
  80028f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800292:	89 08                	mov    %ecx,(%eax)
  800294:	8b 02                	mov    (%edx),%eax
  800296:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80029b:	5d                   	pop    %ebp
  80029c:	c3                   	ret    

0080029d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80029d:	55                   	push   %ebp
  80029e:	89 e5                	mov    %esp,%ebp
  8002a0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002a3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002a7:	8b 10                	mov    (%eax),%edx
  8002a9:	3b 50 04             	cmp    0x4(%eax),%edx
  8002ac:	73 0a                	jae    8002b8 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002b1:	88 0a                	mov    %cl,(%edx)
  8002b3:	83 c2 01             	add    $0x1,%edx
  8002b6:	89 10                	mov    %edx,(%eax)
}
  8002b8:	5d                   	pop    %ebp
  8002b9:	c3                   	ret    

008002ba <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002ba:	55                   	push   %ebp
  8002bb:	89 e5                	mov    %esp,%ebp
  8002bd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002c0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002c7:	8b 45 10             	mov    0x10(%ebp),%eax
  8002ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d5:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d8:	89 04 24             	mov    %eax,(%esp)
  8002db:	e8 02 00 00 00       	call   8002e2 <vprintfmt>
	va_end(ap);
}
  8002e0:	c9                   	leave  
  8002e1:	c3                   	ret    

008002e2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002e2:	55                   	push   %ebp
  8002e3:	89 e5                	mov    %esp,%ebp
  8002e5:	57                   	push   %edi
  8002e6:	56                   	push   %esi
  8002e7:	53                   	push   %ebx
  8002e8:	83 ec 4c             	sub    $0x4c,%esp
  8002eb:	8b 75 08             	mov    0x8(%ebp),%esi
  8002ee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002f1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002f4:	eb 11                	jmp    800307 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002f6:	85 c0                	test   %eax,%eax
  8002f8:	0f 84 db 03 00 00    	je     8006d9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  8002fe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800302:	89 04 24             	mov    %eax,(%esp)
  800305:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800307:	0f b6 07             	movzbl (%edi),%eax
  80030a:	83 c7 01             	add    $0x1,%edi
  80030d:	83 f8 25             	cmp    $0x25,%eax
  800310:	75 e4                	jne    8002f6 <vprintfmt+0x14>
  800312:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800316:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80031d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800324:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80032b:	ba 00 00 00 00       	mov    $0x0,%edx
  800330:	eb 2b                	jmp    80035d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800332:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800335:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800339:	eb 22                	jmp    80035d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80033e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800342:	eb 19                	jmp    80035d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800344:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800347:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80034e:	eb 0d                	jmp    80035d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800350:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800353:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800356:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035d:	0f b6 0f             	movzbl (%edi),%ecx
  800360:	8d 47 01             	lea    0x1(%edi),%eax
  800363:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800366:	0f b6 07             	movzbl (%edi),%eax
  800369:	83 e8 23             	sub    $0x23,%eax
  80036c:	3c 55                	cmp    $0x55,%al
  80036e:	0f 87 40 03 00 00    	ja     8006b4 <vprintfmt+0x3d2>
  800374:	0f b6 c0             	movzbl %al,%eax
  800377:	ff 24 85 cc 10 80 00 	jmp    *0x8010cc(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80037e:	83 e9 30             	sub    $0x30,%ecx
  800381:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800384:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800388:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80038b:	83 f9 09             	cmp    $0x9,%ecx
  80038e:	77 57                	ja     8003e7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800390:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800393:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800396:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800399:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80039c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80039f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8003a3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8003a6:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8003a9:	83 f9 09             	cmp    $0x9,%ecx
  8003ac:	76 eb                	jbe    800399 <vprintfmt+0xb7>
  8003ae:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8003b1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  8003b4:	eb 34                	jmp    8003ea <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003b6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b9:	8d 48 04             	lea    0x4(%eax),%ecx
  8003bc:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003bf:	8b 00                	mov    (%eax),%eax
  8003c1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003c7:	eb 21                	jmp    8003ea <vprintfmt+0x108>

		case '.':
			if (width < 0)
  8003c9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003cd:	0f 88 71 ff ff ff    	js     800344 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8003d6:	eb 85                	jmp    80035d <vprintfmt+0x7b>
  8003d8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003db:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8003e2:	e9 76 ff ff ff       	jmp    80035d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8003ea:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003ee:	0f 89 69 ff ff ff    	jns    80035d <vprintfmt+0x7b>
  8003f4:	e9 57 ff ff ff       	jmp    800350 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003f9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003ff:	e9 59 ff ff ff       	jmp    80035d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800404:	8b 45 14             	mov    0x14(%ebp),%eax
  800407:	8d 50 04             	lea    0x4(%eax),%edx
  80040a:	89 55 14             	mov    %edx,0x14(%ebp)
  80040d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800411:	8b 00                	mov    (%eax),%eax
  800413:	89 04 24             	mov    %eax,(%esp)
  800416:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800418:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80041b:	e9 e7 fe ff ff       	jmp    800307 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800420:	8b 45 14             	mov    0x14(%ebp),%eax
  800423:	8d 50 04             	lea    0x4(%eax),%edx
  800426:	89 55 14             	mov    %edx,0x14(%ebp)
  800429:	8b 00                	mov    (%eax),%eax
  80042b:	89 c2                	mov    %eax,%edx
  80042d:	c1 fa 1f             	sar    $0x1f,%edx
  800430:	31 d0                	xor    %edx,%eax
  800432:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800434:	83 f8 06             	cmp    $0x6,%eax
  800437:	7f 0b                	jg     800444 <vprintfmt+0x162>
  800439:	8b 14 85 24 12 80 00 	mov    0x801224(,%eax,4),%edx
  800440:	85 d2                	test   %edx,%edx
  800442:	75 20                	jne    800464 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800444:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800448:	c7 44 24 08 57 10 80 	movl   $0x801057,0x8(%esp)
  80044f:	00 
  800450:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800454:	89 34 24             	mov    %esi,(%esp)
  800457:	e8 5e fe ff ff       	call   8002ba <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80045f:	e9 a3 fe ff ff       	jmp    800307 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800464:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800468:	c7 44 24 08 60 10 80 	movl   $0x801060,0x8(%esp)
  80046f:	00 
  800470:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800474:	89 34 24             	mov    %esi,(%esp)
  800477:	e8 3e fe ff ff       	call   8002ba <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80047c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80047f:	e9 83 fe ff ff       	jmp    800307 <vprintfmt+0x25>
  800484:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800487:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80048a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80048d:	8b 45 14             	mov    0x14(%ebp),%eax
  800490:	8d 50 04             	lea    0x4(%eax),%edx
  800493:	89 55 14             	mov    %edx,0x14(%ebp)
  800496:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800498:	85 ff                	test   %edi,%edi
  80049a:	b8 50 10 80 00       	mov    $0x801050,%eax
  80049f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004a2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8004a6:	74 06                	je     8004ae <vprintfmt+0x1cc>
  8004a8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8004ac:	7f 16                	jg     8004c4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004ae:	0f b6 17             	movzbl (%edi),%edx
  8004b1:	0f be c2             	movsbl %dl,%eax
  8004b4:	83 c7 01             	add    $0x1,%edi
  8004b7:	85 c0                	test   %eax,%eax
  8004b9:	0f 85 9f 00 00 00    	jne    80055e <vprintfmt+0x27c>
  8004bf:	e9 8b 00 00 00       	jmp    80054f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004c8:	89 3c 24             	mov    %edi,(%esp)
  8004cb:	e8 c2 02 00 00       	call   800792 <strnlen>
  8004d0:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8004d3:	29 c2                	sub    %eax,%edx
  8004d5:	89 55 d8             	mov    %edx,-0x28(%ebp)
  8004d8:	85 d2                	test   %edx,%edx
  8004da:	7e d2                	jle    8004ae <vprintfmt+0x1cc>
					putch(padc, putdat);
  8004dc:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8004e0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8004e3:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8004e6:	89 d7                	mov    %edx,%edi
  8004e8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8004ef:	89 04 24             	mov    %eax,(%esp)
  8004f2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f4:	83 ef 01             	sub    $0x1,%edi
  8004f7:	75 ef                	jne    8004e8 <vprintfmt+0x206>
  8004f9:	89 7d d8             	mov    %edi,-0x28(%ebp)
  8004fc:	8b 7d cc             	mov    -0x34(%ebp),%edi
  8004ff:	eb ad                	jmp    8004ae <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800501:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800505:	74 20                	je     800527 <vprintfmt+0x245>
  800507:	0f be d2             	movsbl %dl,%edx
  80050a:	83 ea 20             	sub    $0x20,%edx
  80050d:	83 fa 5e             	cmp    $0x5e,%edx
  800510:	76 15                	jbe    800527 <vprintfmt+0x245>
					putch('?', putdat);
  800512:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800515:	89 54 24 04          	mov    %edx,0x4(%esp)
  800519:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800520:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800523:	ff d1                	call   *%ecx
  800525:	eb 0f                	jmp    800536 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800527:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80052a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80052e:	89 04 24             	mov    %eax,(%esp)
  800531:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800534:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800536:	83 eb 01             	sub    $0x1,%ebx
  800539:	0f b6 17             	movzbl (%edi),%edx
  80053c:	0f be c2             	movsbl %dl,%eax
  80053f:	83 c7 01             	add    $0x1,%edi
  800542:	85 c0                	test   %eax,%eax
  800544:	75 24                	jne    80056a <vprintfmt+0x288>
  800546:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800549:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80054c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80054f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800552:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800556:	0f 8e ab fd ff ff    	jle    800307 <vprintfmt+0x25>
  80055c:	eb 20                	jmp    80057e <vprintfmt+0x29c>
  80055e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800561:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800564:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800567:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80056a:	85 f6                	test   %esi,%esi
  80056c:	78 93                	js     800501 <vprintfmt+0x21f>
  80056e:	83 ee 01             	sub    $0x1,%esi
  800571:	79 8e                	jns    800501 <vprintfmt+0x21f>
  800573:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800576:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800579:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80057c:	eb d1                	jmp    80054f <vprintfmt+0x26d>
  80057e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800581:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800585:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80058c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80058e:	83 ef 01             	sub    $0x1,%edi
  800591:	75 ee                	jne    800581 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800593:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800596:	e9 6c fd ff ff       	jmp    800307 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80059b:	83 fa 01             	cmp    $0x1,%edx
  80059e:	66 90                	xchg   %ax,%ax
  8005a0:	7e 16                	jle    8005b8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  8005a2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a5:	8d 50 08             	lea    0x8(%eax),%edx
  8005a8:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ab:	8b 10                	mov    (%eax),%edx
  8005ad:	8b 48 04             	mov    0x4(%eax),%ecx
  8005b0:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8005b3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005b6:	eb 32                	jmp    8005ea <vprintfmt+0x308>
	else if (lflag)
  8005b8:	85 d2                	test   %edx,%edx
  8005ba:	74 18                	je     8005d4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  8005bc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005bf:	8d 50 04             	lea    0x4(%eax),%edx
  8005c2:	89 55 14             	mov    %edx,0x14(%ebp)
  8005c5:	8b 00                	mov    (%eax),%eax
  8005c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005ca:	89 c1                	mov    %eax,%ecx
  8005cc:	c1 f9 1f             	sar    $0x1f,%ecx
  8005cf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005d2:	eb 16                	jmp    8005ea <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  8005d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d7:	8d 50 04             	lea    0x4(%eax),%edx
  8005da:	89 55 14             	mov    %edx,0x14(%ebp)
  8005dd:	8b 00                	mov    (%eax),%eax
  8005df:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005e2:	89 c7                	mov    %eax,%edi
  8005e4:	c1 ff 1f             	sar    $0x1f,%edi
  8005e7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005ea:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005ed:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005f0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005f5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  8005f9:	79 7d                	jns    800678 <vprintfmt+0x396>
				putch('-', putdat);
  8005fb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005ff:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800606:	ff d6                	call   *%esi
				num = -(long long) num;
  800608:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80060b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80060e:	f7 d8                	neg    %eax
  800610:	83 d2 00             	adc    $0x0,%edx
  800613:	f7 da                	neg    %edx
			}
			base = 10;
  800615:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80061a:	eb 5c                	jmp    800678 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80061c:	8d 45 14             	lea    0x14(%ebp),%eax
  80061f:	e8 3f fc ff ff       	call   800263 <getuint>
			base = 10;
  800624:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800629:	eb 4d                	jmp    800678 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80062b:	8d 45 14             	lea    0x14(%ebp),%eax
  80062e:	e8 30 fc ff ff       	call   800263 <getuint>
			base = 8;
  800633:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800638:	eb 3e                	jmp    800678 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  80063a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80063e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800645:	ff d6                	call   *%esi
			putch('x', putdat);
  800647:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80064b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800652:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800654:	8b 45 14             	mov    0x14(%ebp),%eax
  800657:	8d 50 04             	lea    0x4(%eax),%edx
  80065a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80065d:	8b 00                	mov    (%eax),%eax
  80065f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800664:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800669:	eb 0d                	jmp    800678 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80066b:	8d 45 14             	lea    0x14(%ebp),%eax
  80066e:	e8 f0 fb ff ff       	call   800263 <getuint>
			base = 16;
  800673:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800678:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80067c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800680:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800683:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800687:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80068b:	89 04 24             	mov    %eax,(%esp)
  80068e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800692:	89 da                	mov    %ebx,%edx
  800694:	89 f0                	mov    %esi,%eax
  800696:	e8 d5 fa ff ff       	call   800170 <printnum>
			break;
  80069b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80069e:	e9 64 fc ff ff       	jmp    800307 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006a3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006a7:	89 0c 24             	mov    %ecx,(%esp)
  8006aa:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006af:	e9 53 fc ff ff       	jmp    800307 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006b4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006b8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006bf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006c1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006c5:	0f 84 3c fc ff ff    	je     800307 <vprintfmt+0x25>
  8006cb:	83 ef 01             	sub    $0x1,%edi
  8006ce:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006d2:	75 f7                	jne    8006cb <vprintfmt+0x3e9>
  8006d4:	e9 2e fc ff ff       	jmp    800307 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8006d9:	83 c4 4c             	add    $0x4c,%esp
  8006dc:	5b                   	pop    %ebx
  8006dd:	5e                   	pop    %esi
  8006de:	5f                   	pop    %edi
  8006df:	5d                   	pop    %ebp
  8006e0:	c3                   	ret    

008006e1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006e1:	55                   	push   %ebp
  8006e2:	89 e5                	mov    %esp,%ebp
  8006e4:	83 ec 28             	sub    $0x28,%esp
  8006e7:	8b 45 08             	mov    0x8(%ebp),%eax
  8006ea:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006f0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006f4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006f7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006fe:	85 d2                	test   %edx,%edx
  800700:	7e 30                	jle    800732 <vsnprintf+0x51>
  800702:	85 c0                	test   %eax,%eax
  800704:	74 2c                	je     800732 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800706:	8b 45 14             	mov    0x14(%ebp),%eax
  800709:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80070d:	8b 45 10             	mov    0x10(%ebp),%eax
  800710:	89 44 24 08          	mov    %eax,0x8(%esp)
  800714:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800717:	89 44 24 04          	mov    %eax,0x4(%esp)
  80071b:	c7 04 24 9d 02 80 00 	movl   $0x80029d,(%esp)
  800722:	e8 bb fb ff ff       	call   8002e2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800727:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80072a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80072d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800730:	eb 05                	jmp    800737 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800732:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800737:	c9                   	leave  
  800738:	c3                   	ret    

00800739 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800739:	55                   	push   %ebp
  80073a:	89 e5                	mov    %esp,%ebp
  80073c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80073f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800742:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800746:	8b 45 10             	mov    0x10(%ebp),%eax
  800749:	89 44 24 08          	mov    %eax,0x8(%esp)
  80074d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800750:	89 44 24 04          	mov    %eax,0x4(%esp)
  800754:	8b 45 08             	mov    0x8(%ebp),%eax
  800757:	89 04 24             	mov    %eax,(%esp)
  80075a:	e8 82 ff ff ff       	call   8006e1 <vsnprintf>
	va_end(ap);

	return rc;
}
  80075f:	c9                   	leave  
  800760:	c3                   	ret    
  800761:	66 90                	xchg   %ax,%ax
  800763:	66 90                	xchg   %ax,%ax
  800765:	66 90                	xchg   %ax,%ax
  800767:	66 90                	xchg   %ax,%ax
  800769:	66 90                	xchg   %ax,%ax
  80076b:	66 90                	xchg   %ax,%ax
  80076d:	66 90                	xchg   %ax,%ax
  80076f:	90                   	nop

00800770 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800770:	55                   	push   %ebp
  800771:	89 e5                	mov    %esp,%ebp
  800773:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800776:	80 3a 00             	cmpb   $0x0,(%edx)
  800779:	74 10                	je     80078b <strlen+0x1b>
  80077b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800780:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800783:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800787:	75 f7                	jne    800780 <strlen+0x10>
  800789:	eb 05                	jmp    800790 <strlen+0x20>
  80078b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800790:	5d                   	pop    %ebp
  800791:	c3                   	ret    

00800792 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800792:	55                   	push   %ebp
  800793:	89 e5                	mov    %esp,%ebp
  800795:	53                   	push   %ebx
  800796:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800799:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079c:	85 c9                	test   %ecx,%ecx
  80079e:	74 1c                	je     8007bc <strnlen+0x2a>
  8007a0:	80 3b 00             	cmpb   $0x0,(%ebx)
  8007a3:	74 1e                	je     8007c3 <strnlen+0x31>
  8007a5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  8007aa:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007ac:	39 ca                	cmp    %ecx,%edx
  8007ae:	74 18                	je     8007c8 <strnlen+0x36>
  8007b0:	83 c2 01             	add    $0x1,%edx
  8007b3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8007b8:	75 f0                	jne    8007aa <strnlen+0x18>
  8007ba:	eb 0c                	jmp    8007c8 <strnlen+0x36>
  8007bc:	b8 00 00 00 00       	mov    $0x0,%eax
  8007c1:	eb 05                	jmp    8007c8 <strnlen+0x36>
  8007c3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8007c8:	5b                   	pop    %ebx
  8007c9:	5d                   	pop    %ebp
  8007ca:	c3                   	ret    

008007cb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007cb:	55                   	push   %ebp
  8007cc:	89 e5                	mov    %esp,%ebp
  8007ce:	53                   	push   %ebx
  8007cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8007d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007d5:	89 c2                	mov    %eax,%edx
  8007d7:	0f b6 19             	movzbl (%ecx),%ebx
  8007da:	88 1a                	mov    %bl,(%edx)
  8007dc:	83 c2 01             	add    $0x1,%edx
  8007df:	83 c1 01             	add    $0x1,%ecx
  8007e2:	84 db                	test   %bl,%bl
  8007e4:	75 f1                	jne    8007d7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007e6:	5b                   	pop    %ebx
  8007e7:	5d                   	pop    %ebp
  8007e8:	c3                   	ret    

008007e9 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007e9:	55                   	push   %ebp
  8007ea:	89 e5                	mov    %esp,%ebp
  8007ec:	53                   	push   %ebx
  8007ed:	83 ec 08             	sub    $0x8,%esp
  8007f0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007f3:	89 1c 24             	mov    %ebx,(%esp)
  8007f6:	e8 75 ff ff ff       	call   800770 <strlen>
	strcpy(dst + len, src);
  8007fb:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007fe:	89 54 24 04          	mov    %edx,0x4(%esp)
  800802:	01 d8                	add    %ebx,%eax
  800804:	89 04 24             	mov    %eax,(%esp)
  800807:	e8 bf ff ff ff       	call   8007cb <strcpy>
	return dst;
}
  80080c:	89 d8                	mov    %ebx,%eax
  80080e:	83 c4 08             	add    $0x8,%esp
  800811:	5b                   	pop    %ebx
  800812:	5d                   	pop    %ebp
  800813:	c3                   	ret    

00800814 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800814:	55                   	push   %ebp
  800815:	89 e5                	mov    %esp,%ebp
  800817:	56                   	push   %esi
  800818:	53                   	push   %ebx
  800819:	8b 75 08             	mov    0x8(%ebp),%esi
  80081c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80081f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800822:	85 db                	test   %ebx,%ebx
  800824:	74 16                	je     80083c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800826:	01 f3                	add    %esi,%ebx
  800828:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  80082a:	0f b6 02             	movzbl (%edx),%eax
  80082d:	88 01                	mov    %al,(%ecx)
  80082f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800832:	80 3a 01             	cmpb   $0x1,(%edx)
  800835:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800838:	39 d9                	cmp    %ebx,%ecx
  80083a:	75 ee                	jne    80082a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80083c:	89 f0                	mov    %esi,%eax
  80083e:	5b                   	pop    %ebx
  80083f:	5e                   	pop    %esi
  800840:	5d                   	pop    %ebp
  800841:	c3                   	ret    

00800842 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800842:	55                   	push   %ebp
  800843:	89 e5                	mov    %esp,%ebp
  800845:	57                   	push   %edi
  800846:	56                   	push   %esi
  800847:	53                   	push   %ebx
  800848:	8b 7d 08             	mov    0x8(%ebp),%edi
  80084b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80084e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800851:	89 f8                	mov    %edi,%eax
  800853:	85 f6                	test   %esi,%esi
  800855:	74 33                	je     80088a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800857:	83 fe 01             	cmp    $0x1,%esi
  80085a:	74 25                	je     800881 <strlcpy+0x3f>
  80085c:	0f b6 0b             	movzbl (%ebx),%ecx
  80085f:	84 c9                	test   %cl,%cl
  800861:	74 22                	je     800885 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800863:	83 ee 02             	sub    $0x2,%esi
  800866:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80086b:	88 08                	mov    %cl,(%eax)
  80086d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800870:	39 f2                	cmp    %esi,%edx
  800872:	74 13                	je     800887 <strlcpy+0x45>
  800874:	83 c2 01             	add    $0x1,%edx
  800877:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80087b:	84 c9                	test   %cl,%cl
  80087d:	75 ec                	jne    80086b <strlcpy+0x29>
  80087f:	eb 06                	jmp    800887 <strlcpy+0x45>
  800881:	89 f8                	mov    %edi,%eax
  800883:	eb 02                	jmp    800887 <strlcpy+0x45>
  800885:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800887:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80088a:	29 f8                	sub    %edi,%eax
}
  80088c:	5b                   	pop    %ebx
  80088d:	5e                   	pop    %esi
  80088e:	5f                   	pop    %edi
  80088f:	5d                   	pop    %ebp
  800890:	c3                   	ret    

00800891 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800891:	55                   	push   %ebp
  800892:	89 e5                	mov    %esp,%ebp
  800894:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800897:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80089a:	0f b6 01             	movzbl (%ecx),%eax
  80089d:	84 c0                	test   %al,%al
  80089f:	74 15                	je     8008b6 <strcmp+0x25>
  8008a1:	3a 02                	cmp    (%edx),%al
  8008a3:	75 11                	jne    8008b6 <strcmp+0x25>
		p++, q++;
  8008a5:	83 c1 01             	add    $0x1,%ecx
  8008a8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008ab:	0f b6 01             	movzbl (%ecx),%eax
  8008ae:	84 c0                	test   %al,%al
  8008b0:	74 04                	je     8008b6 <strcmp+0x25>
  8008b2:	3a 02                	cmp    (%edx),%al
  8008b4:	74 ef                	je     8008a5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008b6:	0f b6 c0             	movzbl %al,%eax
  8008b9:	0f b6 12             	movzbl (%edx),%edx
  8008bc:	29 d0                	sub    %edx,%eax
}
  8008be:	5d                   	pop    %ebp
  8008bf:	c3                   	ret    

008008c0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008c0:	55                   	push   %ebp
  8008c1:	89 e5                	mov    %esp,%ebp
  8008c3:	56                   	push   %esi
  8008c4:	53                   	push   %ebx
  8008c5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8008c8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008cb:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  8008ce:	85 f6                	test   %esi,%esi
  8008d0:	74 29                	je     8008fb <strncmp+0x3b>
  8008d2:	0f b6 03             	movzbl (%ebx),%eax
  8008d5:	84 c0                	test   %al,%al
  8008d7:	74 30                	je     800909 <strncmp+0x49>
  8008d9:	3a 02                	cmp    (%edx),%al
  8008db:	75 2c                	jne    800909 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  8008dd:	8d 43 01             	lea    0x1(%ebx),%eax
  8008e0:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  8008e2:	89 c3                	mov    %eax,%ebx
  8008e4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008e7:	39 f0                	cmp    %esi,%eax
  8008e9:	74 17                	je     800902 <strncmp+0x42>
  8008eb:	0f b6 08             	movzbl (%eax),%ecx
  8008ee:	84 c9                	test   %cl,%cl
  8008f0:	74 17                	je     800909 <strncmp+0x49>
  8008f2:	83 c0 01             	add    $0x1,%eax
  8008f5:	3a 0a                	cmp    (%edx),%cl
  8008f7:	74 e9                	je     8008e2 <strncmp+0x22>
  8008f9:	eb 0e                	jmp    800909 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008fb:	b8 00 00 00 00       	mov    $0x0,%eax
  800900:	eb 0f                	jmp    800911 <strncmp+0x51>
  800902:	b8 00 00 00 00       	mov    $0x0,%eax
  800907:	eb 08                	jmp    800911 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800909:	0f b6 03             	movzbl (%ebx),%eax
  80090c:	0f b6 12             	movzbl (%edx),%edx
  80090f:	29 d0                	sub    %edx,%eax
}
  800911:	5b                   	pop    %ebx
  800912:	5e                   	pop    %esi
  800913:	5d                   	pop    %ebp
  800914:	c3                   	ret    

00800915 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800915:	55                   	push   %ebp
  800916:	89 e5                	mov    %esp,%ebp
  800918:	53                   	push   %ebx
  800919:	8b 45 08             	mov    0x8(%ebp),%eax
  80091c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  80091f:	0f b6 18             	movzbl (%eax),%ebx
  800922:	84 db                	test   %bl,%bl
  800924:	74 1d                	je     800943 <strchr+0x2e>
  800926:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800928:	38 d3                	cmp    %dl,%bl
  80092a:	75 06                	jne    800932 <strchr+0x1d>
  80092c:	eb 1a                	jmp    800948 <strchr+0x33>
  80092e:	38 ca                	cmp    %cl,%dl
  800930:	74 16                	je     800948 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800932:	83 c0 01             	add    $0x1,%eax
  800935:	0f b6 10             	movzbl (%eax),%edx
  800938:	84 d2                	test   %dl,%dl
  80093a:	75 f2                	jne    80092e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  80093c:	b8 00 00 00 00       	mov    $0x0,%eax
  800941:	eb 05                	jmp    800948 <strchr+0x33>
  800943:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800948:	5b                   	pop    %ebx
  800949:	5d                   	pop    %ebp
  80094a:	c3                   	ret    

0080094b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80094b:	55                   	push   %ebp
  80094c:	89 e5                	mov    %esp,%ebp
  80094e:	53                   	push   %ebx
  80094f:	8b 45 08             	mov    0x8(%ebp),%eax
  800952:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800955:	0f b6 18             	movzbl (%eax),%ebx
  800958:	84 db                	test   %bl,%bl
  80095a:	74 16                	je     800972 <strfind+0x27>
  80095c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  80095e:	38 d3                	cmp    %dl,%bl
  800960:	75 06                	jne    800968 <strfind+0x1d>
  800962:	eb 0e                	jmp    800972 <strfind+0x27>
  800964:	38 ca                	cmp    %cl,%dl
  800966:	74 0a                	je     800972 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800968:	83 c0 01             	add    $0x1,%eax
  80096b:	0f b6 10             	movzbl (%eax),%edx
  80096e:	84 d2                	test   %dl,%dl
  800970:	75 f2                	jne    800964 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800972:	5b                   	pop    %ebx
  800973:	5d                   	pop    %ebp
  800974:	c3                   	ret    

00800975 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800975:	55                   	push   %ebp
  800976:	89 e5                	mov    %esp,%ebp
  800978:	83 ec 0c             	sub    $0xc,%esp
  80097b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80097e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800981:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800984:	8b 7d 08             	mov    0x8(%ebp),%edi
  800987:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80098a:	85 c9                	test   %ecx,%ecx
  80098c:	74 36                	je     8009c4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80098e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800994:	75 28                	jne    8009be <memset+0x49>
  800996:	f6 c1 03             	test   $0x3,%cl
  800999:	75 23                	jne    8009be <memset+0x49>
		c &= 0xFF;
  80099b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80099f:	89 d3                	mov    %edx,%ebx
  8009a1:	c1 e3 08             	shl    $0x8,%ebx
  8009a4:	89 d6                	mov    %edx,%esi
  8009a6:	c1 e6 18             	shl    $0x18,%esi
  8009a9:	89 d0                	mov    %edx,%eax
  8009ab:	c1 e0 10             	shl    $0x10,%eax
  8009ae:	09 f0                	or     %esi,%eax
  8009b0:	09 c2                	or     %eax,%edx
  8009b2:	89 d0                	mov    %edx,%eax
  8009b4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009b6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009b9:	fc                   	cld    
  8009ba:	f3 ab                	rep stos %eax,%es:(%edi)
  8009bc:	eb 06                	jmp    8009c4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009be:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009c1:	fc                   	cld    
  8009c2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009c4:	89 f8                	mov    %edi,%eax
  8009c6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8009c9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8009cc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8009cf:	89 ec                	mov    %ebp,%esp
  8009d1:	5d                   	pop    %ebp
  8009d2:	c3                   	ret    

008009d3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009d3:	55                   	push   %ebp
  8009d4:	89 e5                	mov    %esp,%ebp
  8009d6:	83 ec 08             	sub    $0x8,%esp
  8009d9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8009dc:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009df:	8b 45 08             	mov    0x8(%ebp),%eax
  8009e2:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009e5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009e8:	39 c6                	cmp    %eax,%esi
  8009ea:	73 36                	jae    800a22 <memmove+0x4f>
  8009ec:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009ef:	39 d0                	cmp    %edx,%eax
  8009f1:	73 2f                	jae    800a22 <memmove+0x4f>
		s += n;
		d += n;
  8009f3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009f6:	f6 c2 03             	test   $0x3,%dl
  8009f9:	75 1b                	jne    800a16 <memmove+0x43>
  8009fb:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a01:	75 13                	jne    800a16 <memmove+0x43>
  800a03:	f6 c1 03             	test   $0x3,%cl
  800a06:	75 0e                	jne    800a16 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a08:	83 ef 04             	sub    $0x4,%edi
  800a0b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a0e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a11:	fd                   	std    
  800a12:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a14:	eb 09                	jmp    800a1f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a16:	83 ef 01             	sub    $0x1,%edi
  800a19:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a1c:	fd                   	std    
  800a1d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a1f:	fc                   	cld    
  800a20:	eb 20                	jmp    800a42 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a22:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a28:	75 13                	jne    800a3d <memmove+0x6a>
  800a2a:	a8 03                	test   $0x3,%al
  800a2c:	75 0f                	jne    800a3d <memmove+0x6a>
  800a2e:	f6 c1 03             	test   $0x3,%cl
  800a31:	75 0a                	jne    800a3d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a33:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a36:	89 c7                	mov    %eax,%edi
  800a38:	fc                   	cld    
  800a39:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a3b:	eb 05                	jmp    800a42 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a3d:	89 c7                	mov    %eax,%edi
  800a3f:	fc                   	cld    
  800a40:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a42:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a45:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a48:	89 ec                	mov    %ebp,%esp
  800a4a:	5d                   	pop    %ebp
  800a4b:	c3                   	ret    

00800a4c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800a4c:	55                   	push   %ebp
  800a4d:	89 e5                	mov    %esp,%ebp
  800a4f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a52:	8b 45 10             	mov    0x10(%ebp),%eax
  800a55:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a59:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a5c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a60:	8b 45 08             	mov    0x8(%ebp),%eax
  800a63:	89 04 24             	mov    %eax,(%esp)
  800a66:	e8 68 ff ff ff       	call   8009d3 <memmove>
}
  800a6b:	c9                   	leave  
  800a6c:	c3                   	ret    

00800a6d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a6d:	55                   	push   %ebp
  800a6e:	89 e5                	mov    %esp,%ebp
  800a70:	57                   	push   %edi
  800a71:	56                   	push   %esi
  800a72:	53                   	push   %ebx
  800a73:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a76:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a79:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a7c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800a7f:	85 c0                	test   %eax,%eax
  800a81:	74 36                	je     800ab9 <memcmp+0x4c>
		if (*s1 != *s2)
  800a83:	0f b6 03             	movzbl (%ebx),%eax
  800a86:	0f b6 0e             	movzbl (%esi),%ecx
  800a89:	38 c8                	cmp    %cl,%al
  800a8b:	75 17                	jne    800aa4 <memcmp+0x37>
  800a8d:	ba 00 00 00 00       	mov    $0x0,%edx
  800a92:	eb 1a                	jmp    800aae <memcmp+0x41>
  800a94:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800a99:	83 c2 01             	add    $0x1,%edx
  800a9c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800aa0:	38 c8                	cmp    %cl,%al
  800aa2:	74 0a                	je     800aae <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800aa4:	0f b6 c0             	movzbl %al,%eax
  800aa7:	0f b6 c9             	movzbl %cl,%ecx
  800aaa:	29 c8                	sub    %ecx,%eax
  800aac:	eb 10                	jmp    800abe <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800aae:	39 fa                	cmp    %edi,%edx
  800ab0:	75 e2                	jne    800a94 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800ab2:	b8 00 00 00 00       	mov    $0x0,%eax
  800ab7:	eb 05                	jmp    800abe <memcmp+0x51>
  800ab9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800abe:	5b                   	pop    %ebx
  800abf:	5e                   	pop    %esi
  800ac0:	5f                   	pop    %edi
  800ac1:	5d                   	pop    %ebp
  800ac2:	c3                   	ret    

00800ac3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ac3:	55                   	push   %ebp
  800ac4:	89 e5                	mov    %esp,%ebp
  800ac6:	53                   	push   %ebx
  800ac7:	8b 45 08             	mov    0x8(%ebp),%eax
  800aca:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800acd:	89 c2                	mov    %eax,%edx
  800acf:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ad2:	39 d0                	cmp    %edx,%eax
  800ad4:	73 13                	jae    800ae9 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ad6:	89 d9                	mov    %ebx,%ecx
  800ad8:	38 18                	cmp    %bl,(%eax)
  800ada:	75 06                	jne    800ae2 <memfind+0x1f>
  800adc:	eb 0b                	jmp    800ae9 <memfind+0x26>
  800ade:	38 08                	cmp    %cl,(%eax)
  800ae0:	74 07                	je     800ae9 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800ae2:	83 c0 01             	add    $0x1,%eax
  800ae5:	39 d0                	cmp    %edx,%eax
  800ae7:	75 f5                	jne    800ade <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800ae9:	5b                   	pop    %ebx
  800aea:	5d                   	pop    %ebp
  800aeb:	c3                   	ret    

00800aec <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800aec:	55                   	push   %ebp
  800aed:	89 e5                	mov    %esp,%ebp
  800aef:	57                   	push   %edi
  800af0:	56                   	push   %esi
  800af1:	53                   	push   %ebx
  800af2:	83 ec 04             	sub    $0x4,%esp
  800af5:	8b 55 08             	mov    0x8(%ebp),%edx
  800af8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800afb:	0f b6 02             	movzbl (%edx),%eax
  800afe:	3c 09                	cmp    $0x9,%al
  800b00:	74 04                	je     800b06 <strtol+0x1a>
  800b02:	3c 20                	cmp    $0x20,%al
  800b04:	75 0e                	jne    800b14 <strtol+0x28>
		s++;
  800b06:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b09:	0f b6 02             	movzbl (%edx),%eax
  800b0c:	3c 09                	cmp    $0x9,%al
  800b0e:	74 f6                	je     800b06 <strtol+0x1a>
  800b10:	3c 20                	cmp    $0x20,%al
  800b12:	74 f2                	je     800b06 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b14:	3c 2b                	cmp    $0x2b,%al
  800b16:	75 0a                	jne    800b22 <strtol+0x36>
		s++;
  800b18:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b1b:	bf 00 00 00 00       	mov    $0x0,%edi
  800b20:	eb 10                	jmp    800b32 <strtol+0x46>
  800b22:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b27:	3c 2d                	cmp    $0x2d,%al
  800b29:	75 07                	jne    800b32 <strtol+0x46>
		s++, neg = 1;
  800b2b:	83 c2 01             	add    $0x1,%edx
  800b2e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b32:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b38:	75 15                	jne    800b4f <strtol+0x63>
  800b3a:	80 3a 30             	cmpb   $0x30,(%edx)
  800b3d:	75 10                	jne    800b4f <strtol+0x63>
  800b3f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b43:	75 0a                	jne    800b4f <strtol+0x63>
		s += 2, base = 16;
  800b45:	83 c2 02             	add    $0x2,%edx
  800b48:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b4d:	eb 10                	jmp    800b5f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800b4f:	85 db                	test   %ebx,%ebx
  800b51:	75 0c                	jne    800b5f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b53:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b55:	80 3a 30             	cmpb   $0x30,(%edx)
  800b58:	75 05                	jne    800b5f <strtol+0x73>
		s++, base = 8;
  800b5a:	83 c2 01             	add    $0x1,%edx
  800b5d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800b5f:	b8 00 00 00 00       	mov    $0x0,%eax
  800b64:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b67:	0f b6 0a             	movzbl (%edx),%ecx
  800b6a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b6d:	89 f3                	mov    %esi,%ebx
  800b6f:	80 fb 09             	cmp    $0x9,%bl
  800b72:	77 08                	ja     800b7c <strtol+0x90>
			dig = *s - '0';
  800b74:	0f be c9             	movsbl %cl,%ecx
  800b77:	83 e9 30             	sub    $0x30,%ecx
  800b7a:	eb 22                	jmp    800b9e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800b7c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b7f:	89 f3                	mov    %esi,%ebx
  800b81:	80 fb 19             	cmp    $0x19,%bl
  800b84:	77 08                	ja     800b8e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800b86:	0f be c9             	movsbl %cl,%ecx
  800b89:	83 e9 57             	sub    $0x57,%ecx
  800b8c:	eb 10                	jmp    800b9e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800b8e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b91:	89 f3                	mov    %esi,%ebx
  800b93:	80 fb 19             	cmp    $0x19,%bl
  800b96:	77 16                	ja     800bae <strtol+0xc2>
			dig = *s - 'A' + 10;
  800b98:	0f be c9             	movsbl %cl,%ecx
  800b9b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b9e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800ba1:	7d 0f                	jge    800bb2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800ba3:	83 c2 01             	add    $0x1,%edx
  800ba6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800baa:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800bac:	eb b9                	jmp    800b67 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800bae:	89 c1                	mov    %eax,%ecx
  800bb0:	eb 02                	jmp    800bb4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800bb2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800bb4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bb8:	74 05                	je     800bbf <strtol+0xd3>
		*endptr = (char *) s;
  800bba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800bbd:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800bbf:	89 ca                	mov    %ecx,%edx
  800bc1:	f7 da                	neg    %edx
  800bc3:	85 ff                	test   %edi,%edi
  800bc5:	0f 45 c2             	cmovne %edx,%eax
}
  800bc8:	83 c4 04             	add    $0x4,%esp
  800bcb:	5b                   	pop    %ebx
  800bcc:	5e                   	pop    %esi
  800bcd:	5f                   	pop    %edi
  800bce:	5d                   	pop    %ebp
  800bcf:	c3                   	ret    

00800bd0 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800bd0:	55                   	push   %ebp
  800bd1:	89 e5                	mov    %esp,%ebp
  800bd3:	83 ec 0c             	sub    $0xc,%esp
  800bd6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800bd9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800bdc:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bdf:	b8 00 00 00 00       	mov    $0x0,%eax
  800be4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800be7:	8b 55 08             	mov    0x8(%ebp),%edx
  800bea:	89 c3                	mov    %eax,%ebx
  800bec:	89 c7                	mov    %eax,%edi
  800bee:	89 c6                	mov    %eax,%esi
  800bf0:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800bf2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800bf5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800bf8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800bfb:	89 ec                	mov    %ebp,%esp
  800bfd:	5d                   	pop    %ebp
  800bfe:	c3                   	ret    

00800bff <sys_cgetc>:

int
sys_cgetc(void)
{
  800bff:	55                   	push   %ebp
  800c00:	89 e5                	mov    %esp,%ebp
  800c02:	83 ec 0c             	sub    $0xc,%esp
  800c05:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c08:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c0b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c0e:	ba 00 00 00 00       	mov    $0x0,%edx
  800c13:	b8 01 00 00 00       	mov    $0x1,%eax
  800c18:	89 d1                	mov    %edx,%ecx
  800c1a:	89 d3                	mov    %edx,%ebx
  800c1c:	89 d7                	mov    %edx,%edi
  800c1e:	89 d6                	mov    %edx,%esi
  800c20:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c22:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c25:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c28:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c2b:	89 ec                	mov    %ebp,%esp
  800c2d:	5d                   	pop    %ebp
  800c2e:	c3                   	ret    

00800c2f <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c2f:	55                   	push   %ebp
  800c30:	89 e5                	mov    %esp,%ebp
  800c32:	83 ec 38             	sub    $0x38,%esp
  800c35:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c38:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c3b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c3e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c43:	b8 03 00 00 00       	mov    $0x3,%eax
  800c48:	8b 55 08             	mov    0x8(%ebp),%edx
  800c4b:	89 cb                	mov    %ecx,%ebx
  800c4d:	89 cf                	mov    %ecx,%edi
  800c4f:	89 ce                	mov    %ecx,%esi
  800c51:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c53:	85 c0                	test   %eax,%eax
  800c55:	7e 28                	jle    800c7f <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c57:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c5b:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800c62:	00 
  800c63:	c7 44 24 08 40 12 80 	movl   $0x801240,0x8(%esp)
  800c6a:	00 
  800c6b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c72:	00 
  800c73:	c7 04 24 5d 12 80 00 	movl   $0x80125d,(%esp)
  800c7a:	e8 3d 00 00 00       	call   800cbc <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c7f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c82:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c85:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c88:	89 ec                	mov    %ebp,%esp
  800c8a:	5d                   	pop    %ebp
  800c8b:	c3                   	ret    

00800c8c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c8c:	55                   	push   %ebp
  800c8d:	89 e5                	mov    %esp,%ebp
  800c8f:	83 ec 0c             	sub    $0xc,%esp
  800c92:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c95:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c98:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c9b:	ba 00 00 00 00       	mov    $0x0,%edx
  800ca0:	b8 02 00 00 00       	mov    $0x2,%eax
  800ca5:	89 d1                	mov    %edx,%ecx
  800ca7:	89 d3                	mov    %edx,%ebx
  800ca9:	89 d7                	mov    %edx,%edi
  800cab:	89 d6                	mov    %edx,%esi
  800cad:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800caf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800cb2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cb5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cb8:	89 ec                	mov    %ebp,%esp
  800cba:	5d                   	pop    %ebp
  800cbb:	c3                   	ret    

00800cbc <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800cbc:	55                   	push   %ebp
  800cbd:	89 e5                	mov    %esp,%ebp
  800cbf:	56                   	push   %esi
  800cc0:	53                   	push   %ebx
  800cc1:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800cc4:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800cc7:	a1 08 20 80 00       	mov    0x802008,%eax
  800ccc:	85 c0                	test   %eax,%eax
  800cce:	74 10                	je     800ce0 <_panic+0x24>
		cprintf("%s: ", argv0);
  800cd0:	89 44 24 04          	mov    %eax,0x4(%esp)
  800cd4:	c7 04 24 6b 12 80 00 	movl   $0x80126b,(%esp)
  800cdb:	e8 6f f4 ff ff       	call   80014f <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800ce0:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ce6:	e8 a1 ff ff ff       	call   800c8c <sys_getenvid>
  800ceb:	8b 55 0c             	mov    0xc(%ebp),%edx
  800cee:	89 54 24 10          	mov    %edx,0x10(%esp)
  800cf2:	8b 55 08             	mov    0x8(%ebp),%edx
  800cf5:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800cf9:	89 74 24 08          	mov    %esi,0x8(%esp)
  800cfd:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d01:	c7 04 24 70 12 80 00 	movl   $0x801270,(%esp)
  800d08:	e8 42 f4 ff ff       	call   80014f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800d0d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800d11:	8b 45 10             	mov    0x10(%ebp),%eax
  800d14:	89 04 24             	mov    %eax,(%esp)
  800d17:	e8 d2 f3 ff ff       	call   8000ee <vcprintf>
	cprintf("\n");
  800d1c:	c7 04 24 1c 10 80 00 	movl   $0x80101c,(%esp)
  800d23:	e8 27 f4 ff ff       	call   80014f <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800d28:	cc                   	int3   
  800d29:	eb fd                	jmp    800d28 <_panic+0x6c>
  800d2b:	66 90                	xchg   %ax,%ax
  800d2d:	66 90                	xchg   %ax,%ax
  800d2f:	90                   	nop

00800d30 <__udivdi3>:
  800d30:	83 ec 1c             	sub    $0x1c,%esp
  800d33:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800d37:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d3b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d3f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d43:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800d47:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800d4b:	85 c0                	test   %eax,%eax
  800d4d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d51:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d55:	89 ea                	mov    %ebp,%edx
  800d57:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800d5b:	75 33                	jne    800d90 <__udivdi3+0x60>
  800d5d:	39 e9                	cmp    %ebp,%ecx
  800d5f:	77 6f                	ja     800dd0 <__udivdi3+0xa0>
  800d61:	85 c9                	test   %ecx,%ecx
  800d63:	89 ce                	mov    %ecx,%esi
  800d65:	75 0b                	jne    800d72 <__udivdi3+0x42>
  800d67:	b8 01 00 00 00       	mov    $0x1,%eax
  800d6c:	31 d2                	xor    %edx,%edx
  800d6e:	f7 f1                	div    %ecx
  800d70:	89 c6                	mov    %eax,%esi
  800d72:	31 d2                	xor    %edx,%edx
  800d74:	89 e8                	mov    %ebp,%eax
  800d76:	f7 f6                	div    %esi
  800d78:	89 c5                	mov    %eax,%ebp
  800d7a:	89 f8                	mov    %edi,%eax
  800d7c:	f7 f6                	div    %esi
  800d7e:	89 ea                	mov    %ebp,%edx
  800d80:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d84:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d88:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d8c:	83 c4 1c             	add    $0x1c,%esp
  800d8f:	c3                   	ret    
  800d90:	39 e8                	cmp    %ebp,%eax
  800d92:	77 24                	ja     800db8 <__udivdi3+0x88>
  800d94:	0f bd c8             	bsr    %eax,%ecx
  800d97:	83 f1 1f             	xor    $0x1f,%ecx
  800d9a:	89 0c 24             	mov    %ecx,(%esp)
  800d9d:	75 49                	jne    800de8 <__udivdi3+0xb8>
  800d9f:	8b 74 24 08          	mov    0x8(%esp),%esi
  800da3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800da7:	0f 86 ab 00 00 00    	jbe    800e58 <__udivdi3+0x128>
  800dad:	39 e8                	cmp    %ebp,%eax
  800daf:	0f 82 a3 00 00 00    	jb     800e58 <__udivdi3+0x128>
  800db5:	8d 76 00             	lea    0x0(%esi),%esi
  800db8:	31 d2                	xor    %edx,%edx
  800dba:	31 c0                	xor    %eax,%eax
  800dbc:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dc0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dc4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dc8:	83 c4 1c             	add    $0x1c,%esp
  800dcb:	c3                   	ret    
  800dcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dd0:	89 f8                	mov    %edi,%eax
  800dd2:	f7 f1                	div    %ecx
  800dd4:	31 d2                	xor    %edx,%edx
  800dd6:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dda:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dde:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800de2:	83 c4 1c             	add    $0x1c,%esp
  800de5:	c3                   	ret    
  800de6:	66 90                	xchg   %ax,%ax
  800de8:	0f b6 0c 24          	movzbl (%esp),%ecx
  800dec:	89 c6                	mov    %eax,%esi
  800dee:	b8 20 00 00 00       	mov    $0x20,%eax
  800df3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800df7:	2b 04 24             	sub    (%esp),%eax
  800dfa:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800dfe:	d3 e6                	shl    %cl,%esi
  800e00:	89 c1                	mov    %eax,%ecx
  800e02:	d3 ed                	shr    %cl,%ebp
  800e04:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e08:	09 f5                	or     %esi,%ebp
  800e0a:	8b 74 24 04          	mov    0x4(%esp),%esi
  800e0e:	d3 e6                	shl    %cl,%esi
  800e10:	89 c1                	mov    %eax,%ecx
  800e12:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e16:	89 d6                	mov    %edx,%esi
  800e18:	d3 ee                	shr    %cl,%esi
  800e1a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e1e:	d3 e2                	shl    %cl,%edx
  800e20:	89 c1                	mov    %eax,%ecx
  800e22:	d3 ef                	shr    %cl,%edi
  800e24:	09 d7                	or     %edx,%edi
  800e26:	89 f2                	mov    %esi,%edx
  800e28:	89 f8                	mov    %edi,%eax
  800e2a:	f7 f5                	div    %ebp
  800e2c:	89 d6                	mov    %edx,%esi
  800e2e:	89 c7                	mov    %eax,%edi
  800e30:	f7 64 24 04          	mull   0x4(%esp)
  800e34:	39 d6                	cmp    %edx,%esi
  800e36:	72 30                	jb     800e68 <__udivdi3+0x138>
  800e38:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800e3c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e40:	d3 e5                	shl    %cl,%ebp
  800e42:	39 c5                	cmp    %eax,%ebp
  800e44:	73 04                	jae    800e4a <__udivdi3+0x11a>
  800e46:	39 d6                	cmp    %edx,%esi
  800e48:	74 1e                	je     800e68 <__udivdi3+0x138>
  800e4a:	89 f8                	mov    %edi,%eax
  800e4c:	31 d2                	xor    %edx,%edx
  800e4e:	e9 69 ff ff ff       	jmp    800dbc <__udivdi3+0x8c>
  800e53:	90                   	nop
  800e54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e58:	31 d2                	xor    %edx,%edx
  800e5a:	b8 01 00 00 00       	mov    $0x1,%eax
  800e5f:	e9 58 ff ff ff       	jmp    800dbc <__udivdi3+0x8c>
  800e64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e68:	8d 47 ff             	lea    -0x1(%edi),%eax
  800e6b:	31 d2                	xor    %edx,%edx
  800e6d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e71:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e75:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e79:	83 c4 1c             	add    $0x1c,%esp
  800e7c:	c3                   	ret    
  800e7d:	66 90                	xchg   %ax,%ax
  800e7f:	90                   	nop

00800e80 <__umoddi3>:
  800e80:	83 ec 2c             	sub    $0x2c,%esp
  800e83:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800e87:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800e8b:	89 74 24 20          	mov    %esi,0x20(%esp)
  800e8f:	8b 74 24 38          	mov    0x38(%esp),%esi
  800e93:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800e97:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800e9b:	85 c0                	test   %eax,%eax
  800e9d:	89 c2                	mov    %eax,%edx
  800e9f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800ea3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800ea7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800eab:	89 74 24 10          	mov    %esi,0x10(%esp)
  800eaf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800eb3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800eb7:	75 1f                	jne    800ed8 <__umoddi3+0x58>
  800eb9:	39 fe                	cmp    %edi,%esi
  800ebb:	76 63                	jbe    800f20 <__umoddi3+0xa0>
  800ebd:	89 c8                	mov    %ecx,%eax
  800ebf:	89 fa                	mov    %edi,%edx
  800ec1:	f7 f6                	div    %esi
  800ec3:	89 d0                	mov    %edx,%eax
  800ec5:	31 d2                	xor    %edx,%edx
  800ec7:	8b 74 24 20          	mov    0x20(%esp),%esi
  800ecb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800ecf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800ed3:	83 c4 2c             	add    $0x2c,%esp
  800ed6:	c3                   	ret    
  800ed7:	90                   	nop
  800ed8:	39 f8                	cmp    %edi,%eax
  800eda:	77 64                	ja     800f40 <__umoddi3+0xc0>
  800edc:	0f bd e8             	bsr    %eax,%ebp
  800edf:	83 f5 1f             	xor    $0x1f,%ebp
  800ee2:	75 74                	jne    800f58 <__umoddi3+0xd8>
  800ee4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800ee8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800eec:	0f 87 0e 01 00 00    	ja     801000 <__umoddi3+0x180>
  800ef2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800ef6:	29 f1                	sub    %esi,%ecx
  800ef8:	19 c7                	sbb    %eax,%edi
  800efa:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800efe:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800f02:	8b 44 24 14          	mov    0x14(%esp),%eax
  800f06:	8b 54 24 18          	mov    0x18(%esp),%edx
  800f0a:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f0e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f12:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f16:	83 c4 2c             	add    $0x2c,%esp
  800f19:	c3                   	ret    
  800f1a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f20:	85 f6                	test   %esi,%esi
  800f22:	89 f5                	mov    %esi,%ebp
  800f24:	75 0b                	jne    800f31 <__umoddi3+0xb1>
  800f26:	b8 01 00 00 00       	mov    $0x1,%eax
  800f2b:	31 d2                	xor    %edx,%edx
  800f2d:	f7 f6                	div    %esi
  800f2f:	89 c5                	mov    %eax,%ebp
  800f31:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f35:	31 d2                	xor    %edx,%edx
  800f37:	f7 f5                	div    %ebp
  800f39:	89 c8                	mov    %ecx,%eax
  800f3b:	f7 f5                	div    %ebp
  800f3d:	eb 84                	jmp    800ec3 <__umoddi3+0x43>
  800f3f:	90                   	nop
  800f40:	89 c8                	mov    %ecx,%eax
  800f42:	89 fa                	mov    %edi,%edx
  800f44:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f48:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f4c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f50:	83 c4 2c             	add    $0x2c,%esp
  800f53:	c3                   	ret    
  800f54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f58:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f5c:	be 20 00 00 00       	mov    $0x20,%esi
  800f61:	89 e9                	mov    %ebp,%ecx
  800f63:	29 ee                	sub    %ebp,%esi
  800f65:	d3 e2                	shl    %cl,%edx
  800f67:	89 f1                	mov    %esi,%ecx
  800f69:	d3 e8                	shr    %cl,%eax
  800f6b:	89 e9                	mov    %ebp,%ecx
  800f6d:	09 d0                	or     %edx,%eax
  800f6f:	89 fa                	mov    %edi,%edx
  800f71:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800f75:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f79:	d3 e0                	shl    %cl,%eax
  800f7b:	89 f1                	mov    %esi,%ecx
  800f7d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f81:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800f85:	d3 ea                	shr    %cl,%edx
  800f87:	89 e9                	mov    %ebp,%ecx
  800f89:	d3 e7                	shl    %cl,%edi
  800f8b:	89 f1                	mov    %esi,%ecx
  800f8d:	d3 e8                	shr    %cl,%eax
  800f8f:	89 e9                	mov    %ebp,%ecx
  800f91:	09 f8                	or     %edi,%eax
  800f93:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800f97:	f7 74 24 0c          	divl   0xc(%esp)
  800f9b:	d3 e7                	shl    %cl,%edi
  800f9d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800fa1:	89 d7                	mov    %edx,%edi
  800fa3:	f7 64 24 10          	mull   0x10(%esp)
  800fa7:	39 d7                	cmp    %edx,%edi
  800fa9:	89 c1                	mov    %eax,%ecx
  800fab:	89 54 24 14          	mov    %edx,0x14(%esp)
  800faf:	72 3b                	jb     800fec <__umoddi3+0x16c>
  800fb1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800fb5:	72 31                	jb     800fe8 <__umoddi3+0x168>
  800fb7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800fbb:	29 c8                	sub    %ecx,%eax
  800fbd:	19 d7                	sbb    %edx,%edi
  800fbf:	89 e9                	mov    %ebp,%ecx
  800fc1:	89 fa                	mov    %edi,%edx
  800fc3:	d3 e8                	shr    %cl,%eax
  800fc5:	89 f1                	mov    %esi,%ecx
  800fc7:	d3 e2                	shl    %cl,%edx
  800fc9:	89 e9                	mov    %ebp,%ecx
  800fcb:	09 d0                	or     %edx,%eax
  800fcd:	89 fa                	mov    %edi,%edx
  800fcf:	d3 ea                	shr    %cl,%edx
  800fd1:	8b 74 24 20          	mov    0x20(%esp),%esi
  800fd5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800fd9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800fdd:	83 c4 2c             	add    $0x2c,%esp
  800fe0:	c3                   	ret    
  800fe1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800fe8:	39 d7                	cmp    %edx,%edi
  800fea:	75 cb                	jne    800fb7 <__umoddi3+0x137>
  800fec:	8b 54 24 14          	mov    0x14(%esp),%edx
  800ff0:	89 c1                	mov    %eax,%ecx
  800ff2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  800ff6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  800ffa:	eb bb                	jmp    800fb7 <__umoddi3+0x137>
  800ffc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801000:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801004:	0f 82 e8 fe ff ff    	jb     800ef2 <__umoddi3+0x72>
  80100a:	e9 f3 fe ff ff       	jmp    800f02 <__umoddi3+0x82>


obj/user/faultread：     文件格式 elf32-i386


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
  80002c:	e8 23 00 00 00       	call   800054 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	90                   	nop

00800034 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  80003a:	a1 00 00 00 00       	mov    0x0,%eax
  80003f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800043:	c7 04 24 00 10 80 00 	movl   $0x801000,(%esp)
  80004a:	e8 f4 00 00 00       	call   800143 <cprintf>
}
  80004f:	c9                   	leave  
  800050:	c3                   	ret    
  800051:	66 90                	xchg   %ax,%ax
  800053:	90                   	nop

00800054 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800054:	55                   	push   %ebp
  800055:	89 e5                	mov    %esp,%ebp
  800057:	83 ec 18             	sub    $0x18,%esp
  80005a:	8b 45 08             	mov    0x8(%ebp),%eax
  80005d:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800060:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800067:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80006a:	85 c0                	test   %eax,%eax
  80006c:	7e 08                	jle    800076 <libmain+0x22>
		binaryname = argv[0];
  80006e:	8b 0a                	mov    (%edx),%ecx
  800070:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800076:	89 54 24 04          	mov    %edx,0x4(%esp)
  80007a:	89 04 24             	mov    %eax,(%esp)
  80007d:	e8 b2 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  800082:	e8 05 00 00 00       	call   80008c <exit>
}
  800087:	c9                   	leave  
  800088:	c3                   	ret    
  800089:	66 90                	xchg   %ax,%ax
  80008b:	90                   	nop

0080008c <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80008c:	55                   	push   %ebp
  80008d:	89 e5                	mov    %esp,%ebp
  80008f:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800092:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800099:	e8 81 0b 00 00       	call   800c1f <sys_env_destroy>
}
  80009e:	c9                   	leave  
  80009f:	c3                   	ret    

008000a0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a0:	55                   	push   %ebp
  8000a1:	89 e5                	mov    %esp,%ebp
  8000a3:	53                   	push   %ebx
  8000a4:	83 ec 14             	sub    $0x14,%esp
  8000a7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000aa:	8b 03                	mov    (%ebx),%eax
  8000ac:	8b 55 08             	mov    0x8(%ebp),%edx
  8000af:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8000b3:	83 c0 01             	add    $0x1,%eax
  8000b6:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8000b8:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000bd:	75 19                	jne    8000d8 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000bf:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000c6:	00 
  8000c7:	8d 43 08             	lea    0x8(%ebx),%eax
  8000ca:	89 04 24             	mov    %eax,(%esp)
  8000cd:	e8 ee 0a 00 00       	call   800bc0 <sys_cputs>
		b->idx = 0;
  8000d2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000d8:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000dc:	83 c4 14             	add    $0x14,%esp
  8000df:	5b                   	pop    %ebx
  8000e0:	5d                   	pop    %ebp
  8000e1:	c3                   	ret    

008000e2 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000e2:	55                   	push   %ebp
  8000e3:	89 e5                	mov    %esp,%ebp
  8000e5:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8000eb:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000f2:	00 00 00 
	b.cnt = 0;
  8000f5:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8000fc:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8000ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  800102:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800106:	8b 45 08             	mov    0x8(%ebp),%eax
  800109:	89 44 24 08          	mov    %eax,0x8(%esp)
  80010d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800113:	89 44 24 04          	mov    %eax,0x4(%esp)
  800117:	c7 04 24 a0 00 80 00 	movl   $0x8000a0,(%esp)
  80011e:	e8 af 01 00 00       	call   8002d2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800123:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800129:	89 44 24 04          	mov    %eax,0x4(%esp)
  80012d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800133:	89 04 24             	mov    %eax,(%esp)
  800136:	e8 85 0a 00 00       	call   800bc0 <sys_cputs>

	return b.cnt;
}
  80013b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800141:	c9                   	leave  
  800142:	c3                   	ret    

00800143 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800143:	55                   	push   %ebp
  800144:	89 e5                	mov    %esp,%ebp
  800146:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800149:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80014c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800150:	8b 45 08             	mov    0x8(%ebp),%eax
  800153:	89 04 24             	mov    %eax,(%esp)
  800156:	e8 87 ff ff ff       	call   8000e2 <vcprintf>
	va_end(ap);

	return cnt;
}
  80015b:	c9                   	leave  
  80015c:	c3                   	ret    
  80015d:	66 90                	xchg   %ax,%ax
  80015f:	90                   	nop

00800160 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800160:	55                   	push   %ebp
  800161:	89 e5                	mov    %esp,%ebp
  800163:	57                   	push   %edi
  800164:	56                   	push   %esi
  800165:	53                   	push   %ebx
  800166:	83 ec 4c             	sub    $0x4c,%esp
  800169:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80016c:	89 d7                	mov    %edx,%edi
  80016e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800171:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800174:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800177:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80017a:	b8 00 00 00 00       	mov    $0x0,%eax
  80017f:	39 d8                	cmp    %ebx,%eax
  800181:	72 17                	jb     80019a <printnum+0x3a>
  800183:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800186:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800189:	76 0f                	jbe    80019a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80018b:	8b 75 14             	mov    0x14(%ebp),%esi
  80018e:	83 ee 01             	sub    $0x1,%esi
  800191:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800194:	85 f6                	test   %esi,%esi
  800196:	7f 63                	jg     8001fb <printnum+0x9b>
  800198:	eb 75                	jmp    80020f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80019a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80019d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8001a1:	8b 45 14             	mov    0x14(%ebp),%eax
  8001a4:	83 e8 01             	sub    $0x1,%eax
  8001a7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001ab:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8001b2:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001b6:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001ba:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8001bd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8001c0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8001c7:	00 
  8001c8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8001cb:	89 1c 24             	mov    %ebx,(%esp)
  8001ce:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8001d1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001d5:	e8 46 0b 00 00       	call   800d20 <__udivdi3>
  8001da:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8001dd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8001e0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001e4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8001e8:	89 04 24             	mov    %eax,(%esp)
  8001eb:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001ef:	89 fa                	mov    %edi,%edx
  8001f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8001f4:	e8 67 ff ff ff       	call   800160 <printnum>
  8001f9:	eb 14                	jmp    80020f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8001ff:	8b 45 18             	mov    0x18(%ebp),%eax
  800202:	89 04 24             	mov    %eax,(%esp)
  800205:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800207:	83 ee 01             	sub    $0x1,%esi
  80020a:	75 ef                	jne    8001fb <printnum+0x9b>
  80020c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80020f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800213:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800217:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80021a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80021e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800225:	00 
  800226:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800229:	89 1c 24             	mov    %ebx,(%esp)
  80022c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80022f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800233:	e8 38 0c 00 00       	call   800e70 <__umoddi3>
  800238:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80023c:	0f be 80 28 10 80 00 	movsbl 0x801028(%eax),%eax
  800243:	89 04 24             	mov    %eax,(%esp)
  800246:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800249:	ff d0                	call   *%eax
}
  80024b:	83 c4 4c             	add    $0x4c,%esp
  80024e:	5b                   	pop    %ebx
  80024f:	5e                   	pop    %esi
  800250:	5f                   	pop    %edi
  800251:	5d                   	pop    %ebp
  800252:	c3                   	ret    

00800253 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800253:	55                   	push   %ebp
  800254:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800256:	83 fa 01             	cmp    $0x1,%edx
  800259:	7e 0e                	jle    800269 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80025b:	8b 10                	mov    (%eax),%edx
  80025d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800260:	89 08                	mov    %ecx,(%eax)
  800262:	8b 02                	mov    (%edx),%eax
  800264:	8b 52 04             	mov    0x4(%edx),%edx
  800267:	eb 22                	jmp    80028b <getuint+0x38>
	else if (lflag)
  800269:	85 d2                	test   %edx,%edx
  80026b:	74 10                	je     80027d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80026d:	8b 10                	mov    (%eax),%edx
  80026f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800272:	89 08                	mov    %ecx,(%eax)
  800274:	8b 02                	mov    (%edx),%eax
  800276:	ba 00 00 00 00       	mov    $0x0,%edx
  80027b:	eb 0e                	jmp    80028b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80027d:	8b 10                	mov    (%eax),%edx
  80027f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800282:	89 08                	mov    %ecx,(%eax)
  800284:	8b 02                	mov    (%edx),%eax
  800286:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80028b:	5d                   	pop    %ebp
  80028c:	c3                   	ret    

0080028d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80028d:	55                   	push   %ebp
  80028e:	89 e5                	mov    %esp,%ebp
  800290:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800293:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800297:	8b 10                	mov    (%eax),%edx
  800299:	3b 50 04             	cmp    0x4(%eax),%edx
  80029c:	73 0a                	jae    8002a8 <sprintputch+0x1b>
		*b->buf++ = ch;
  80029e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002a1:	88 0a                	mov    %cl,(%edx)
  8002a3:	83 c2 01             	add    $0x1,%edx
  8002a6:	89 10                	mov    %edx,(%eax)
}
  8002a8:	5d                   	pop    %ebp
  8002a9:	c3                   	ret    

008002aa <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002aa:	55                   	push   %ebp
  8002ab:	89 e5                	mov    %esp,%ebp
  8002ad:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002b0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002b7:	8b 45 10             	mov    0x10(%ebp),%eax
  8002ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002be:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8002c8:	89 04 24             	mov    %eax,(%esp)
  8002cb:	e8 02 00 00 00       	call   8002d2 <vprintfmt>
	va_end(ap);
}
  8002d0:	c9                   	leave  
  8002d1:	c3                   	ret    

008002d2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002d2:	55                   	push   %ebp
  8002d3:	89 e5                	mov    %esp,%ebp
  8002d5:	57                   	push   %edi
  8002d6:	56                   	push   %esi
  8002d7:	53                   	push   %ebx
  8002d8:	83 ec 4c             	sub    $0x4c,%esp
  8002db:	8b 75 08             	mov    0x8(%ebp),%esi
  8002de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002e1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002e4:	eb 11                	jmp    8002f7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002e6:	85 c0                	test   %eax,%eax
  8002e8:	0f 84 db 03 00 00    	je     8006c9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  8002ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002f2:	89 04 24             	mov    %eax,(%esp)
  8002f5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002f7:	0f b6 07             	movzbl (%edi),%eax
  8002fa:	83 c7 01             	add    $0x1,%edi
  8002fd:	83 f8 25             	cmp    $0x25,%eax
  800300:	75 e4                	jne    8002e6 <vprintfmt+0x14>
  800302:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800306:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80030d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800314:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80031b:	ba 00 00 00 00       	mov    $0x0,%edx
  800320:	eb 2b                	jmp    80034d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800322:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800325:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800329:	eb 22                	jmp    80034d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80032b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80032e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800332:	eb 19                	jmp    80034d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800334:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800337:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80033e:	eb 0d                	jmp    80034d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800340:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800343:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800346:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034d:	0f b6 0f             	movzbl (%edi),%ecx
  800350:	8d 47 01             	lea    0x1(%edi),%eax
  800353:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800356:	0f b6 07             	movzbl (%edi),%eax
  800359:	83 e8 23             	sub    $0x23,%eax
  80035c:	3c 55                	cmp    $0x55,%al
  80035e:	0f 87 40 03 00 00    	ja     8006a4 <vprintfmt+0x3d2>
  800364:	0f b6 c0             	movzbl %al,%eax
  800367:	ff 24 85 b8 10 80 00 	jmp    *0x8010b8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80036e:	83 e9 30             	sub    $0x30,%ecx
  800371:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800374:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800378:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80037b:	83 f9 09             	cmp    $0x9,%ecx
  80037e:	77 57                	ja     8003d7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800380:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800383:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800386:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800389:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80038c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80038f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800393:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800396:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800399:	83 f9 09             	cmp    $0x9,%ecx
  80039c:	76 eb                	jbe    800389 <vprintfmt+0xb7>
  80039e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8003a1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  8003a4:	eb 34                	jmp    8003da <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003a6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a9:	8d 48 04             	lea    0x4(%eax),%ecx
  8003ac:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003af:	8b 00                	mov    (%eax),%eax
  8003b1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003b7:	eb 21                	jmp    8003da <vprintfmt+0x108>

		case '.':
			if (width < 0)
  8003b9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003bd:	0f 88 71 ff ff ff    	js     800334 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8003c6:	eb 85                	jmp    80034d <vprintfmt+0x7b>
  8003c8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003cb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8003d2:	e9 76 ff ff ff       	jmp    80034d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8003da:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003de:	0f 89 69 ff ff ff    	jns    80034d <vprintfmt+0x7b>
  8003e4:	e9 57 ff ff ff       	jmp    800340 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003e9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ec:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003ef:	e9 59 ff ff ff       	jmp    80034d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003f7:	8d 50 04             	lea    0x4(%eax),%edx
  8003fa:	89 55 14             	mov    %edx,0x14(%ebp)
  8003fd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800401:	8b 00                	mov    (%eax),%eax
  800403:	89 04 24             	mov    %eax,(%esp)
  800406:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800408:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80040b:	e9 e7 fe ff ff       	jmp    8002f7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800410:	8b 45 14             	mov    0x14(%ebp),%eax
  800413:	8d 50 04             	lea    0x4(%eax),%edx
  800416:	89 55 14             	mov    %edx,0x14(%ebp)
  800419:	8b 00                	mov    (%eax),%eax
  80041b:	89 c2                	mov    %eax,%edx
  80041d:	c1 fa 1f             	sar    $0x1f,%edx
  800420:	31 d0                	xor    %edx,%eax
  800422:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800424:	83 f8 06             	cmp    $0x6,%eax
  800427:	7f 0b                	jg     800434 <vprintfmt+0x162>
  800429:	8b 14 85 10 12 80 00 	mov    0x801210(,%eax,4),%edx
  800430:	85 d2                	test   %edx,%edx
  800432:	75 20                	jne    800454 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800434:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800438:	c7 44 24 08 40 10 80 	movl   $0x801040,0x8(%esp)
  80043f:	00 
  800440:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800444:	89 34 24             	mov    %esi,(%esp)
  800447:	e8 5e fe ff ff       	call   8002aa <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80044f:	e9 a3 fe ff ff       	jmp    8002f7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800454:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800458:	c7 44 24 08 49 10 80 	movl   $0x801049,0x8(%esp)
  80045f:	00 
  800460:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800464:	89 34 24             	mov    %esi,(%esp)
  800467:	e8 3e fe ff ff       	call   8002aa <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80046f:	e9 83 fe ff ff       	jmp    8002f7 <vprintfmt+0x25>
  800474:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800477:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80047a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80047d:	8b 45 14             	mov    0x14(%ebp),%eax
  800480:	8d 50 04             	lea    0x4(%eax),%edx
  800483:	89 55 14             	mov    %edx,0x14(%ebp)
  800486:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800488:	85 ff                	test   %edi,%edi
  80048a:	b8 39 10 80 00       	mov    $0x801039,%eax
  80048f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800492:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800496:	74 06                	je     80049e <vprintfmt+0x1cc>
  800498:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  80049c:	7f 16                	jg     8004b4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80049e:	0f b6 17             	movzbl (%edi),%edx
  8004a1:	0f be c2             	movsbl %dl,%eax
  8004a4:	83 c7 01             	add    $0x1,%edi
  8004a7:	85 c0                	test   %eax,%eax
  8004a9:	0f 85 9f 00 00 00    	jne    80054e <vprintfmt+0x27c>
  8004af:	e9 8b 00 00 00       	jmp    80053f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004b4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004b8:	89 3c 24             	mov    %edi,(%esp)
  8004bb:	e8 c2 02 00 00       	call   800782 <strnlen>
  8004c0:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8004c3:	29 c2                	sub    %eax,%edx
  8004c5:	89 55 d8             	mov    %edx,-0x28(%ebp)
  8004c8:	85 d2                	test   %edx,%edx
  8004ca:	7e d2                	jle    80049e <vprintfmt+0x1cc>
					putch(padc, putdat);
  8004cc:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8004d0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8004d3:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8004d6:	89 d7                	mov    %edx,%edi
  8004d8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8004df:	89 04 24             	mov    %eax,(%esp)
  8004e2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e4:	83 ef 01             	sub    $0x1,%edi
  8004e7:	75 ef                	jne    8004d8 <vprintfmt+0x206>
  8004e9:	89 7d d8             	mov    %edi,-0x28(%ebp)
  8004ec:	8b 7d cc             	mov    -0x34(%ebp),%edi
  8004ef:	eb ad                	jmp    80049e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004f1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8004f5:	74 20                	je     800517 <vprintfmt+0x245>
  8004f7:	0f be d2             	movsbl %dl,%edx
  8004fa:	83 ea 20             	sub    $0x20,%edx
  8004fd:	83 fa 5e             	cmp    $0x5e,%edx
  800500:	76 15                	jbe    800517 <vprintfmt+0x245>
					putch('?', putdat);
  800502:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800505:	89 54 24 04          	mov    %edx,0x4(%esp)
  800509:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800510:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800513:	ff d1                	call   *%ecx
  800515:	eb 0f                	jmp    800526 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800517:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80051a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80051e:	89 04 24             	mov    %eax,(%esp)
  800521:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800524:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800526:	83 eb 01             	sub    $0x1,%ebx
  800529:	0f b6 17             	movzbl (%edi),%edx
  80052c:	0f be c2             	movsbl %dl,%eax
  80052f:	83 c7 01             	add    $0x1,%edi
  800532:	85 c0                	test   %eax,%eax
  800534:	75 24                	jne    80055a <vprintfmt+0x288>
  800536:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800539:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80053c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80053f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800542:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800546:	0f 8e ab fd ff ff    	jle    8002f7 <vprintfmt+0x25>
  80054c:	eb 20                	jmp    80056e <vprintfmt+0x29c>
  80054e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800551:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800554:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800557:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80055a:	85 f6                	test   %esi,%esi
  80055c:	78 93                	js     8004f1 <vprintfmt+0x21f>
  80055e:	83 ee 01             	sub    $0x1,%esi
  800561:	79 8e                	jns    8004f1 <vprintfmt+0x21f>
  800563:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800566:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800569:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80056c:	eb d1                	jmp    80053f <vprintfmt+0x26d>
  80056e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800571:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800575:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80057c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80057e:	83 ef 01             	sub    $0x1,%edi
  800581:	75 ee                	jne    800571 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800583:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800586:	e9 6c fd ff ff       	jmp    8002f7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80058b:	83 fa 01             	cmp    $0x1,%edx
  80058e:	66 90                	xchg   %ax,%ax
  800590:	7e 16                	jle    8005a8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800592:	8b 45 14             	mov    0x14(%ebp),%eax
  800595:	8d 50 08             	lea    0x8(%eax),%edx
  800598:	89 55 14             	mov    %edx,0x14(%ebp)
  80059b:	8b 10                	mov    (%eax),%edx
  80059d:	8b 48 04             	mov    0x4(%eax),%ecx
  8005a0:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8005a3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005a6:	eb 32                	jmp    8005da <vprintfmt+0x308>
	else if (lflag)
  8005a8:	85 d2                	test   %edx,%edx
  8005aa:	74 18                	je     8005c4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  8005ac:	8b 45 14             	mov    0x14(%ebp),%eax
  8005af:	8d 50 04             	lea    0x4(%eax),%edx
  8005b2:	89 55 14             	mov    %edx,0x14(%ebp)
  8005b5:	8b 00                	mov    (%eax),%eax
  8005b7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005ba:	89 c1                	mov    %eax,%ecx
  8005bc:	c1 f9 1f             	sar    $0x1f,%ecx
  8005bf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005c2:	eb 16                	jmp    8005da <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  8005c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c7:	8d 50 04             	lea    0x4(%eax),%edx
  8005ca:	89 55 14             	mov    %edx,0x14(%ebp)
  8005cd:	8b 00                	mov    (%eax),%eax
  8005cf:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005d2:	89 c7                	mov    %eax,%edi
  8005d4:	c1 ff 1f             	sar    $0x1f,%edi
  8005d7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005da:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005dd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005e0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005e5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  8005e9:	79 7d                	jns    800668 <vprintfmt+0x396>
				putch('-', putdat);
  8005eb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005ef:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005f6:	ff d6                	call   *%esi
				num = -(long long) num;
  8005f8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005fb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8005fe:	f7 d8                	neg    %eax
  800600:	83 d2 00             	adc    $0x0,%edx
  800603:	f7 da                	neg    %edx
			}
			base = 10;
  800605:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80060a:	eb 5c                	jmp    800668 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80060c:	8d 45 14             	lea    0x14(%ebp),%eax
  80060f:	e8 3f fc ff ff       	call   800253 <getuint>
			base = 10;
  800614:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800619:	eb 4d                	jmp    800668 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80061b:	8d 45 14             	lea    0x14(%ebp),%eax
  80061e:	e8 30 fc ff ff       	call   800253 <getuint>
			base = 8;
  800623:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800628:	eb 3e                	jmp    800668 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  80062a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80062e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800635:	ff d6                	call   *%esi
			putch('x', putdat);
  800637:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80063b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800642:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800644:	8b 45 14             	mov    0x14(%ebp),%eax
  800647:	8d 50 04             	lea    0x4(%eax),%edx
  80064a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80064d:	8b 00                	mov    (%eax),%eax
  80064f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800654:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800659:	eb 0d                	jmp    800668 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80065b:	8d 45 14             	lea    0x14(%ebp),%eax
  80065e:	e8 f0 fb ff ff       	call   800253 <getuint>
			base = 16;
  800663:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800668:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80066c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800670:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800673:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800677:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80067b:	89 04 24             	mov    %eax,(%esp)
  80067e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800682:	89 da                	mov    %ebx,%edx
  800684:	89 f0                	mov    %esi,%eax
  800686:	e8 d5 fa ff ff       	call   800160 <printnum>
			break;
  80068b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80068e:	e9 64 fc ff ff       	jmp    8002f7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800693:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800697:	89 0c 24             	mov    %ecx,(%esp)
  80069a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80069c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80069f:	e9 53 fc ff ff       	jmp    8002f7 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006a4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006a8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006af:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006b1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006b5:	0f 84 3c fc ff ff    	je     8002f7 <vprintfmt+0x25>
  8006bb:	83 ef 01             	sub    $0x1,%edi
  8006be:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006c2:	75 f7                	jne    8006bb <vprintfmt+0x3e9>
  8006c4:	e9 2e fc ff ff       	jmp    8002f7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8006c9:	83 c4 4c             	add    $0x4c,%esp
  8006cc:	5b                   	pop    %ebx
  8006cd:	5e                   	pop    %esi
  8006ce:	5f                   	pop    %edi
  8006cf:	5d                   	pop    %ebp
  8006d0:	c3                   	ret    

008006d1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006d1:	55                   	push   %ebp
  8006d2:	89 e5                	mov    %esp,%ebp
  8006d4:	83 ec 28             	sub    $0x28,%esp
  8006d7:	8b 45 08             	mov    0x8(%ebp),%eax
  8006da:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006e0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006e4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006e7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006ee:	85 d2                	test   %edx,%edx
  8006f0:	7e 30                	jle    800722 <vsnprintf+0x51>
  8006f2:	85 c0                	test   %eax,%eax
  8006f4:	74 2c                	je     800722 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006f6:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006fd:	8b 45 10             	mov    0x10(%ebp),%eax
  800700:	89 44 24 08          	mov    %eax,0x8(%esp)
  800704:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800707:	89 44 24 04          	mov    %eax,0x4(%esp)
  80070b:	c7 04 24 8d 02 80 00 	movl   $0x80028d,(%esp)
  800712:	e8 bb fb ff ff       	call   8002d2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800717:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80071a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80071d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800720:	eb 05                	jmp    800727 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800722:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800727:	c9                   	leave  
  800728:	c3                   	ret    

00800729 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800729:	55                   	push   %ebp
  80072a:	89 e5                	mov    %esp,%ebp
  80072c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80072f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800732:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800736:	8b 45 10             	mov    0x10(%ebp),%eax
  800739:	89 44 24 08          	mov    %eax,0x8(%esp)
  80073d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800740:	89 44 24 04          	mov    %eax,0x4(%esp)
  800744:	8b 45 08             	mov    0x8(%ebp),%eax
  800747:	89 04 24             	mov    %eax,(%esp)
  80074a:	e8 82 ff ff ff       	call   8006d1 <vsnprintf>
	va_end(ap);

	return rc;
}
  80074f:	c9                   	leave  
  800750:	c3                   	ret    
  800751:	66 90                	xchg   %ax,%ax
  800753:	66 90                	xchg   %ax,%ax
  800755:	66 90                	xchg   %ax,%ax
  800757:	66 90                	xchg   %ax,%ax
  800759:	66 90                	xchg   %ax,%ax
  80075b:	66 90                	xchg   %ax,%ax
  80075d:	66 90                	xchg   %ax,%ax
  80075f:	90                   	nop

00800760 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800760:	55                   	push   %ebp
  800761:	89 e5                	mov    %esp,%ebp
  800763:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800766:	80 3a 00             	cmpb   $0x0,(%edx)
  800769:	74 10                	je     80077b <strlen+0x1b>
  80076b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800770:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800773:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800777:	75 f7                	jne    800770 <strlen+0x10>
  800779:	eb 05                	jmp    800780 <strlen+0x20>
  80077b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800780:	5d                   	pop    %ebp
  800781:	c3                   	ret    

00800782 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800782:	55                   	push   %ebp
  800783:	89 e5                	mov    %esp,%ebp
  800785:	53                   	push   %ebx
  800786:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800789:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80078c:	85 c9                	test   %ecx,%ecx
  80078e:	74 1c                	je     8007ac <strnlen+0x2a>
  800790:	80 3b 00             	cmpb   $0x0,(%ebx)
  800793:	74 1e                	je     8007b3 <strnlen+0x31>
  800795:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80079a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079c:	39 ca                	cmp    %ecx,%edx
  80079e:	74 18                	je     8007b8 <strnlen+0x36>
  8007a0:	83 c2 01             	add    $0x1,%edx
  8007a3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8007a8:	75 f0                	jne    80079a <strnlen+0x18>
  8007aa:	eb 0c                	jmp    8007b8 <strnlen+0x36>
  8007ac:	b8 00 00 00 00       	mov    $0x0,%eax
  8007b1:	eb 05                	jmp    8007b8 <strnlen+0x36>
  8007b3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8007b8:	5b                   	pop    %ebx
  8007b9:	5d                   	pop    %ebp
  8007ba:	c3                   	ret    

008007bb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007bb:	55                   	push   %ebp
  8007bc:	89 e5                	mov    %esp,%ebp
  8007be:	53                   	push   %ebx
  8007bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8007c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007c5:	89 c2                	mov    %eax,%edx
  8007c7:	0f b6 19             	movzbl (%ecx),%ebx
  8007ca:	88 1a                	mov    %bl,(%edx)
  8007cc:	83 c2 01             	add    $0x1,%edx
  8007cf:	83 c1 01             	add    $0x1,%ecx
  8007d2:	84 db                	test   %bl,%bl
  8007d4:	75 f1                	jne    8007c7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007d6:	5b                   	pop    %ebx
  8007d7:	5d                   	pop    %ebp
  8007d8:	c3                   	ret    

008007d9 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007d9:	55                   	push   %ebp
  8007da:	89 e5                	mov    %esp,%ebp
  8007dc:	53                   	push   %ebx
  8007dd:	83 ec 08             	sub    $0x8,%esp
  8007e0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007e3:	89 1c 24             	mov    %ebx,(%esp)
  8007e6:	e8 75 ff ff ff       	call   800760 <strlen>
	strcpy(dst + len, src);
  8007eb:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007ee:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007f2:	01 d8                	add    %ebx,%eax
  8007f4:	89 04 24             	mov    %eax,(%esp)
  8007f7:	e8 bf ff ff ff       	call   8007bb <strcpy>
	return dst;
}
  8007fc:	89 d8                	mov    %ebx,%eax
  8007fe:	83 c4 08             	add    $0x8,%esp
  800801:	5b                   	pop    %ebx
  800802:	5d                   	pop    %ebp
  800803:	c3                   	ret    

00800804 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800804:	55                   	push   %ebp
  800805:	89 e5                	mov    %esp,%ebp
  800807:	56                   	push   %esi
  800808:	53                   	push   %ebx
  800809:	8b 75 08             	mov    0x8(%ebp),%esi
  80080c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80080f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800812:	85 db                	test   %ebx,%ebx
  800814:	74 16                	je     80082c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800816:	01 f3                	add    %esi,%ebx
  800818:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  80081a:	0f b6 02             	movzbl (%edx),%eax
  80081d:	88 01                	mov    %al,(%ecx)
  80081f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800822:	80 3a 01             	cmpb   $0x1,(%edx)
  800825:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800828:	39 d9                	cmp    %ebx,%ecx
  80082a:	75 ee                	jne    80081a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80082c:	89 f0                	mov    %esi,%eax
  80082e:	5b                   	pop    %ebx
  80082f:	5e                   	pop    %esi
  800830:	5d                   	pop    %ebp
  800831:	c3                   	ret    

00800832 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800832:	55                   	push   %ebp
  800833:	89 e5                	mov    %esp,%ebp
  800835:	57                   	push   %edi
  800836:	56                   	push   %esi
  800837:	53                   	push   %ebx
  800838:	8b 7d 08             	mov    0x8(%ebp),%edi
  80083b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80083e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800841:	89 f8                	mov    %edi,%eax
  800843:	85 f6                	test   %esi,%esi
  800845:	74 33                	je     80087a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800847:	83 fe 01             	cmp    $0x1,%esi
  80084a:	74 25                	je     800871 <strlcpy+0x3f>
  80084c:	0f b6 0b             	movzbl (%ebx),%ecx
  80084f:	84 c9                	test   %cl,%cl
  800851:	74 22                	je     800875 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800853:	83 ee 02             	sub    $0x2,%esi
  800856:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80085b:	88 08                	mov    %cl,(%eax)
  80085d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800860:	39 f2                	cmp    %esi,%edx
  800862:	74 13                	je     800877 <strlcpy+0x45>
  800864:	83 c2 01             	add    $0x1,%edx
  800867:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80086b:	84 c9                	test   %cl,%cl
  80086d:	75 ec                	jne    80085b <strlcpy+0x29>
  80086f:	eb 06                	jmp    800877 <strlcpy+0x45>
  800871:	89 f8                	mov    %edi,%eax
  800873:	eb 02                	jmp    800877 <strlcpy+0x45>
  800875:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800877:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80087a:	29 f8                	sub    %edi,%eax
}
  80087c:	5b                   	pop    %ebx
  80087d:	5e                   	pop    %esi
  80087e:	5f                   	pop    %edi
  80087f:	5d                   	pop    %ebp
  800880:	c3                   	ret    

00800881 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800881:	55                   	push   %ebp
  800882:	89 e5                	mov    %esp,%ebp
  800884:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800887:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80088a:	0f b6 01             	movzbl (%ecx),%eax
  80088d:	84 c0                	test   %al,%al
  80088f:	74 15                	je     8008a6 <strcmp+0x25>
  800891:	3a 02                	cmp    (%edx),%al
  800893:	75 11                	jne    8008a6 <strcmp+0x25>
		p++, q++;
  800895:	83 c1 01             	add    $0x1,%ecx
  800898:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80089b:	0f b6 01             	movzbl (%ecx),%eax
  80089e:	84 c0                	test   %al,%al
  8008a0:	74 04                	je     8008a6 <strcmp+0x25>
  8008a2:	3a 02                	cmp    (%edx),%al
  8008a4:	74 ef                	je     800895 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008a6:	0f b6 c0             	movzbl %al,%eax
  8008a9:	0f b6 12             	movzbl (%edx),%edx
  8008ac:	29 d0                	sub    %edx,%eax
}
  8008ae:	5d                   	pop    %ebp
  8008af:	c3                   	ret    

008008b0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008b0:	55                   	push   %ebp
  8008b1:	89 e5                	mov    %esp,%ebp
  8008b3:	56                   	push   %esi
  8008b4:	53                   	push   %ebx
  8008b5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8008b8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008bb:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  8008be:	85 f6                	test   %esi,%esi
  8008c0:	74 29                	je     8008eb <strncmp+0x3b>
  8008c2:	0f b6 03             	movzbl (%ebx),%eax
  8008c5:	84 c0                	test   %al,%al
  8008c7:	74 30                	je     8008f9 <strncmp+0x49>
  8008c9:	3a 02                	cmp    (%edx),%al
  8008cb:	75 2c                	jne    8008f9 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  8008cd:	8d 43 01             	lea    0x1(%ebx),%eax
  8008d0:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  8008d2:	89 c3                	mov    %eax,%ebx
  8008d4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008d7:	39 f0                	cmp    %esi,%eax
  8008d9:	74 17                	je     8008f2 <strncmp+0x42>
  8008db:	0f b6 08             	movzbl (%eax),%ecx
  8008de:	84 c9                	test   %cl,%cl
  8008e0:	74 17                	je     8008f9 <strncmp+0x49>
  8008e2:	83 c0 01             	add    $0x1,%eax
  8008e5:	3a 0a                	cmp    (%edx),%cl
  8008e7:	74 e9                	je     8008d2 <strncmp+0x22>
  8008e9:	eb 0e                	jmp    8008f9 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008eb:	b8 00 00 00 00       	mov    $0x0,%eax
  8008f0:	eb 0f                	jmp    800901 <strncmp+0x51>
  8008f2:	b8 00 00 00 00       	mov    $0x0,%eax
  8008f7:	eb 08                	jmp    800901 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008f9:	0f b6 03             	movzbl (%ebx),%eax
  8008fc:	0f b6 12             	movzbl (%edx),%edx
  8008ff:	29 d0                	sub    %edx,%eax
}
  800901:	5b                   	pop    %ebx
  800902:	5e                   	pop    %esi
  800903:	5d                   	pop    %ebp
  800904:	c3                   	ret    

00800905 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800905:	55                   	push   %ebp
  800906:	89 e5                	mov    %esp,%ebp
  800908:	53                   	push   %ebx
  800909:	8b 45 08             	mov    0x8(%ebp),%eax
  80090c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  80090f:	0f b6 18             	movzbl (%eax),%ebx
  800912:	84 db                	test   %bl,%bl
  800914:	74 1d                	je     800933 <strchr+0x2e>
  800916:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800918:	38 d3                	cmp    %dl,%bl
  80091a:	75 06                	jne    800922 <strchr+0x1d>
  80091c:	eb 1a                	jmp    800938 <strchr+0x33>
  80091e:	38 ca                	cmp    %cl,%dl
  800920:	74 16                	je     800938 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800922:	83 c0 01             	add    $0x1,%eax
  800925:	0f b6 10             	movzbl (%eax),%edx
  800928:	84 d2                	test   %dl,%dl
  80092a:	75 f2                	jne    80091e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  80092c:	b8 00 00 00 00       	mov    $0x0,%eax
  800931:	eb 05                	jmp    800938 <strchr+0x33>
  800933:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800938:	5b                   	pop    %ebx
  800939:	5d                   	pop    %ebp
  80093a:	c3                   	ret    

0080093b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80093b:	55                   	push   %ebp
  80093c:	89 e5                	mov    %esp,%ebp
  80093e:	53                   	push   %ebx
  80093f:	8b 45 08             	mov    0x8(%ebp),%eax
  800942:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800945:	0f b6 18             	movzbl (%eax),%ebx
  800948:	84 db                	test   %bl,%bl
  80094a:	74 16                	je     800962 <strfind+0x27>
  80094c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  80094e:	38 d3                	cmp    %dl,%bl
  800950:	75 06                	jne    800958 <strfind+0x1d>
  800952:	eb 0e                	jmp    800962 <strfind+0x27>
  800954:	38 ca                	cmp    %cl,%dl
  800956:	74 0a                	je     800962 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800958:	83 c0 01             	add    $0x1,%eax
  80095b:	0f b6 10             	movzbl (%eax),%edx
  80095e:	84 d2                	test   %dl,%dl
  800960:	75 f2                	jne    800954 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800962:	5b                   	pop    %ebx
  800963:	5d                   	pop    %ebp
  800964:	c3                   	ret    

00800965 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800965:	55                   	push   %ebp
  800966:	89 e5                	mov    %esp,%ebp
  800968:	83 ec 0c             	sub    $0xc,%esp
  80096b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80096e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800971:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800974:	8b 7d 08             	mov    0x8(%ebp),%edi
  800977:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80097a:	85 c9                	test   %ecx,%ecx
  80097c:	74 36                	je     8009b4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80097e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800984:	75 28                	jne    8009ae <memset+0x49>
  800986:	f6 c1 03             	test   $0x3,%cl
  800989:	75 23                	jne    8009ae <memset+0x49>
		c &= 0xFF;
  80098b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80098f:	89 d3                	mov    %edx,%ebx
  800991:	c1 e3 08             	shl    $0x8,%ebx
  800994:	89 d6                	mov    %edx,%esi
  800996:	c1 e6 18             	shl    $0x18,%esi
  800999:	89 d0                	mov    %edx,%eax
  80099b:	c1 e0 10             	shl    $0x10,%eax
  80099e:	09 f0                	or     %esi,%eax
  8009a0:	09 c2                	or     %eax,%edx
  8009a2:	89 d0                	mov    %edx,%eax
  8009a4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009a6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009a9:	fc                   	cld    
  8009aa:	f3 ab                	rep stos %eax,%es:(%edi)
  8009ac:	eb 06                	jmp    8009b4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009b1:	fc                   	cld    
  8009b2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009b4:	89 f8                	mov    %edi,%eax
  8009b6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8009b9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8009bc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8009bf:	89 ec                	mov    %ebp,%esp
  8009c1:	5d                   	pop    %ebp
  8009c2:	c3                   	ret    

008009c3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009c3:	55                   	push   %ebp
  8009c4:	89 e5                	mov    %esp,%ebp
  8009c6:	83 ec 08             	sub    $0x8,%esp
  8009c9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8009cc:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d2:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009d5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009d8:	39 c6                	cmp    %eax,%esi
  8009da:	73 36                	jae    800a12 <memmove+0x4f>
  8009dc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009df:	39 d0                	cmp    %edx,%eax
  8009e1:	73 2f                	jae    800a12 <memmove+0x4f>
		s += n;
		d += n;
  8009e3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009e6:	f6 c2 03             	test   $0x3,%dl
  8009e9:	75 1b                	jne    800a06 <memmove+0x43>
  8009eb:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009f1:	75 13                	jne    800a06 <memmove+0x43>
  8009f3:	f6 c1 03             	test   $0x3,%cl
  8009f6:	75 0e                	jne    800a06 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  8009f8:	83 ef 04             	sub    $0x4,%edi
  8009fb:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009fe:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a01:	fd                   	std    
  800a02:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a04:	eb 09                	jmp    800a0f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a06:	83 ef 01             	sub    $0x1,%edi
  800a09:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a0c:	fd                   	std    
  800a0d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a0f:	fc                   	cld    
  800a10:	eb 20                	jmp    800a32 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a12:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a18:	75 13                	jne    800a2d <memmove+0x6a>
  800a1a:	a8 03                	test   $0x3,%al
  800a1c:	75 0f                	jne    800a2d <memmove+0x6a>
  800a1e:	f6 c1 03             	test   $0x3,%cl
  800a21:	75 0a                	jne    800a2d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a23:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a26:	89 c7                	mov    %eax,%edi
  800a28:	fc                   	cld    
  800a29:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a2b:	eb 05                	jmp    800a32 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a2d:	89 c7                	mov    %eax,%edi
  800a2f:	fc                   	cld    
  800a30:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a32:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a35:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a38:	89 ec                	mov    %ebp,%esp
  800a3a:	5d                   	pop    %ebp
  800a3b:	c3                   	ret    

00800a3c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800a3c:	55                   	push   %ebp
  800a3d:	89 e5                	mov    %esp,%ebp
  800a3f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a42:	8b 45 10             	mov    0x10(%ebp),%eax
  800a45:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a49:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a4c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a50:	8b 45 08             	mov    0x8(%ebp),%eax
  800a53:	89 04 24             	mov    %eax,(%esp)
  800a56:	e8 68 ff ff ff       	call   8009c3 <memmove>
}
  800a5b:	c9                   	leave  
  800a5c:	c3                   	ret    

00800a5d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a5d:	55                   	push   %ebp
  800a5e:	89 e5                	mov    %esp,%ebp
  800a60:	57                   	push   %edi
  800a61:	56                   	push   %esi
  800a62:	53                   	push   %ebx
  800a63:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a66:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a69:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a6c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800a6f:	85 c0                	test   %eax,%eax
  800a71:	74 36                	je     800aa9 <memcmp+0x4c>
		if (*s1 != *s2)
  800a73:	0f b6 03             	movzbl (%ebx),%eax
  800a76:	0f b6 0e             	movzbl (%esi),%ecx
  800a79:	38 c8                	cmp    %cl,%al
  800a7b:	75 17                	jne    800a94 <memcmp+0x37>
  800a7d:	ba 00 00 00 00       	mov    $0x0,%edx
  800a82:	eb 1a                	jmp    800a9e <memcmp+0x41>
  800a84:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800a89:	83 c2 01             	add    $0x1,%edx
  800a8c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800a90:	38 c8                	cmp    %cl,%al
  800a92:	74 0a                	je     800a9e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800a94:	0f b6 c0             	movzbl %al,%eax
  800a97:	0f b6 c9             	movzbl %cl,%ecx
  800a9a:	29 c8                	sub    %ecx,%eax
  800a9c:	eb 10                	jmp    800aae <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a9e:	39 fa                	cmp    %edi,%edx
  800aa0:	75 e2                	jne    800a84 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800aa2:	b8 00 00 00 00       	mov    $0x0,%eax
  800aa7:	eb 05                	jmp    800aae <memcmp+0x51>
  800aa9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800aae:	5b                   	pop    %ebx
  800aaf:	5e                   	pop    %esi
  800ab0:	5f                   	pop    %edi
  800ab1:	5d                   	pop    %ebp
  800ab2:	c3                   	ret    

00800ab3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ab3:	55                   	push   %ebp
  800ab4:	89 e5                	mov    %esp,%ebp
  800ab6:	53                   	push   %ebx
  800ab7:	8b 45 08             	mov    0x8(%ebp),%eax
  800aba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800abd:	89 c2                	mov    %eax,%edx
  800abf:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ac2:	39 d0                	cmp    %edx,%eax
  800ac4:	73 13                	jae    800ad9 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ac6:	89 d9                	mov    %ebx,%ecx
  800ac8:	38 18                	cmp    %bl,(%eax)
  800aca:	75 06                	jne    800ad2 <memfind+0x1f>
  800acc:	eb 0b                	jmp    800ad9 <memfind+0x26>
  800ace:	38 08                	cmp    %cl,(%eax)
  800ad0:	74 07                	je     800ad9 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800ad2:	83 c0 01             	add    $0x1,%eax
  800ad5:	39 d0                	cmp    %edx,%eax
  800ad7:	75 f5                	jne    800ace <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800ad9:	5b                   	pop    %ebx
  800ada:	5d                   	pop    %ebp
  800adb:	c3                   	ret    

00800adc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800adc:	55                   	push   %ebp
  800add:	89 e5                	mov    %esp,%ebp
  800adf:	57                   	push   %edi
  800ae0:	56                   	push   %esi
  800ae1:	53                   	push   %ebx
  800ae2:	83 ec 04             	sub    $0x4,%esp
  800ae5:	8b 55 08             	mov    0x8(%ebp),%edx
  800ae8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aeb:	0f b6 02             	movzbl (%edx),%eax
  800aee:	3c 09                	cmp    $0x9,%al
  800af0:	74 04                	je     800af6 <strtol+0x1a>
  800af2:	3c 20                	cmp    $0x20,%al
  800af4:	75 0e                	jne    800b04 <strtol+0x28>
		s++;
  800af6:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800af9:	0f b6 02             	movzbl (%edx),%eax
  800afc:	3c 09                	cmp    $0x9,%al
  800afe:	74 f6                	je     800af6 <strtol+0x1a>
  800b00:	3c 20                	cmp    $0x20,%al
  800b02:	74 f2                	je     800af6 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b04:	3c 2b                	cmp    $0x2b,%al
  800b06:	75 0a                	jne    800b12 <strtol+0x36>
		s++;
  800b08:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b0b:	bf 00 00 00 00       	mov    $0x0,%edi
  800b10:	eb 10                	jmp    800b22 <strtol+0x46>
  800b12:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b17:	3c 2d                	cmp    $0x2d,%al
  800b19:	75 07                	jne    800b22 <strtol+0x46>
		s++, neg = 1;
  800b1b:	83 c2 01             	add    $0x1,%edx
  800b1e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b22:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b28:	75 15                	jne    800b3f <strtol+0x63>
  800b2a:	80 3a 30             	cmpb   $0x30,(%edx)
  800b2d:	75 10                	jne    800b3f <strtol+0x63>
  800b2f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b33:	75 0a                	jne    800b3f <strtol+0x63>
		s += 2, base = 16;
  800b35:	83 c2 02             	add    $0x2,%edx
  800b38:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b3d:	eb 10                	jmp    800b4f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800b3f:	85 db                	test   %ebx,%ebx
  800b41:	75 0c                	jne    800b4f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b43:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b45:	80 3a 30             	cmpb   $0x30,(%edx)
  800b48:	75 05                	jne    800b4f <strtol+0x73>
		s++, base = 8;
  800b4a:	83 c2 01             	add    $0x1,%edx
  800b4d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800b4f:	b8 00 00 00 00       	mov    $0x0,%eax
  800b54:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b57:	0f b6 0a             	movzbl (%edx),%ecx
  800b5a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b5d:	89 f3                	mov    %esi,%ebx
  800b5f:	80 fb 09             	cmp    $0x9,%bl
  800b62:	77 08                	ja     800b6c <strtol+0x90>
			dig = *s - '0';
  800b64:	0f be c9             	movsbl %cl,%ecx
  800b67:	83 e9 30             	sub    $0x30,%ecx
  800b6a:	eb 22                	jmp    800b8e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800b6c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b6f:	89 f3                	mov    %esi,%ebx
  800b71:	80 fb 19             	cmp    $0x19,%bl
  800b74:	77 08                	ja     800b7e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800b76:	0f be c9             	movsbl %cl,%ecx
  800b79:	83 e9 57             	sub    $0x57,%ecx
  800b7c:	eb 10                	jmp    800b8e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800b7e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b81:	89 f3                	mov    %esi,%ebx
  800b83:	80 fb 19             	cmp    $0x19,%bl
  800b86:	77 16                	ja     800b9e <strtol+0xc2>
			dig = *s - 'A' + 10;
  800b88:	0f be c9             	movsbl %cl,%ecx
  800b8b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b8e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800b91:	7d 0f                	jge    800ba2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800b93:	83 c2 01             	add    $0x1,%edx
  800b96:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800b9a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800b9c:	eb b9                	jmp    800b57 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800b9e:	89 c1                	mov    %eax,%ecx
  800ba0:	eb 02                	jmp    800ba4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800ba2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800ba4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ba8:	74 05                	je     800baf <strtol+0xd3>
		*endptr = (char *) s;
  800baa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800bad:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800baf:	89 ca                	mov    %ecx,%edx
  800bb1:	f7 da                	neg    %edx
  800bb3:	85 ff                	test   %edi,%edi
  800bb5:	0f 45 c2             	cmovne %edx,%eax
}
  800bb8:	83 c4 04             	add    $0x4,%esp
  800bbb:	5b                   	pop    %ebx
  800bbc:	5e                   	pop    %esi
  800bbd:	5f                   	pop    %edi
  800bbe:	5d                   	pop    %ebp
  800bbf:	c3                   	ret    

00800bc0 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800bc0:	55                   	push   %ebp
  800bc1:	89 e5                	mov    %esp,%ebp
  800bc3:	83 ec 0c             	sub    $0xc,%esp
  800bc6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800bc9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800bcc:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bcf:	b8 00 00 00 00       	mov    $0x0,%eax
  800bd4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bd7:	8b 55 08             	mov    0x8(%ebp),%edx
  800bda:	89 c3                	mov    %eax,%ebx
  800bdc:	89 c7                	mov    %eax,%edi
  800bde:	89 c6                	mov    %eax,%esi
  800be0:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800be2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800be5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800be8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800beb:	89 ec                	mov    %ebp,%esp
  800bed:	5d                   	pop    %ebp
  800bee:	c3                   	ret    

00800bef <sys_cgetc>:

int
sys_cgetc(void)
{
  800bef:	55                   	push   %ebp
  800bf0:	89 e5                	mov    %esp,%ebp
  800bf2:	83 ec 0c             	sub    $0xc,%esp
  800bf5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800bf8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800bfb:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bfe:	ba 00 00 00 00       	mov    $0x0,%edx
  800c03:	b8 01 00 00 00       	mov    $0x1,%eax
  800c08:	89 d1                	mov    %edx,%ecx
  800c0a:	89 d3                	mov    %edx,%ebx
  800c0c:	89 d7                	mov    %edx,%edi
  800c0e:	89 d6                	mov    %edx,%esi
  800c10:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c12:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c15:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c18:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c1b:	89 ec                	mov    %ebp,%esp
  800c1d:	5d                   	pop    %ebp
  800c1e:	c3                   	ret    

00800c1f <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c1f:	55                   	push   %ebp
  800c20:	89 e5                	mov    %esp,%ebp
  800c22:	83 ec 38             	sub    $0x38,%esp
  800c25:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c28:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c2b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c2e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c33:	b8 03 00 00 00       	mov    $0x3,%eax
  800c38:	8b 55 08             	mov    0x8(%ebp),%edx
  800c3b:	89 cb                	mov    %ecx,%ebx
  800c3d:	89 cf                	mov    %ecx,%edi
  800c3f:	89 ce                	mov    %ecx,%esi
  800c41:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c43:	85 c0                	test   %eax,%eax
  800c45:	7e 28                	jle    800c6f <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c47:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c4b:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800c52:	00 
  800c53:	c7 44 24 08 2c 12 80 	movl   $0x80122c,0x8(%esp)
  800c5a:	00 
  800c5b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c62:	00 
  800c63:	c7 04 24 49 12 80 00 	movl   $0x801249,(%esp)
  800c6a:	e8 3d 00 00 00       	call   800cac <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c6f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c72:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c75:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c78:	89 ec                	mov    %ebp,%esp
  800c7a:	5d                   	pop    %ebp
  800c7b:	c3                   	ret    

00800c7c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c7c:	55                   	push   %ebp
  800c7d:	89 e5                	mov    %esp,%ebp
  800c7f:	83 ec 0c             	sub    $0xc,%esp
  800c82:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c85:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c88:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c8b:	ba 00 00 00 00       	mov    $0x0,%edx
  800c90:	b8 02 00 00 00       	mov    $0x2,%eax
  800c95:	89 d1                	mov    %edx,%ecx
  800c97:	89 d3                	mov    %edx,%ebx
  800c99:	89 d7                	mov    %edx,%edi
  800c9b:	89 d6                	mov    %edx,%esi
  800c9d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c9f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800ca2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ca5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ca8:	89 ec                	mov    %ebp,%esp
  800caa:	5d                   	pop    %ebp
  800cab:	c3                   	ret    

00800cac <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800cac:	55                   	push   %ebp
  800cad:	89 e5                	mov    %esp,%ebp
  800caf:	56                   	push   %esi
  800cb0:	53                   	push   %ebx
  800cb1:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800cb4:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800cb7:	a1 08 20 80 00       	mov    0x802008,%eax
  800cbc:	85 c0                	test   %eax,%eax
  800cbe:	74 10                	je     800cd0 <_panic+0x24>
		cprintf("%s: ", argv0);
  800cc0:	89 44 24 04          	mov    %eax,0x4(%esp)
  800cc4:	c7 04 24 57 12 80 00 	movl   $0x801257,(%esp)
  800ccb:	e8 73 f4 ff ff       	call   800143 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800cd0:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800cd6:	e8 a1 ff ff ff       	call   800c7c <sys_getenvid>
  800cdb:	8b 55 0c             	mov    0xc(%ebp),%edx
  800cde:	89 54 24 10          	mov    %edx,0x10(%esp)
  800ce2:	8b 55 08             	mov    0x8(%ebp),%edx
  800ce5:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800ce9:	89 74 24 08          	mov    %esi,0x8(%esp)
  800ced:	89 44 24 04          	mov    %eax,0x4(%esp)
  800cf1:	c7 04 24 5c 12 80 00 	movl   $0x80125c,(%esp)
  800cf8:	e8 46 f4 ff ff       	call   800143 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800cfd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800d01:	8b 45 10             	mov    0x10(%ebp),%eax
  800d04:	89 04 24             	mov    %eax,(%esp)
  800d07:	e8 d6 f3 ff ff       	call   8000e2 <vcprintf>
	cprintf("\n");
  800d0c:	c7 04 24 1c 10 80 00 	movl   $0x80101c,(%esp)
  800d13:	e8 2b f4 ff ff       	call   800143 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800d18:	cc                   	int3   
  800d19:	eb fd                	jmp    800d18 <_panic+0x6c>
  800d1b:	66 90                	xchg   %ax,%ax
  800d1d:	66 90                	xchg   %ax,%ax
  800d1f:	90                   	nop

00800d20 <__udivdi3>:
  800d20:	83 ec 1c             	sub    $0x1c,%esp
  800d23:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800d27:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d2b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d2f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d33:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800d37:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800d3b:	85 c0                	test   %eax,%eax
  800d3d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d41:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d45:	89 ea                	mov    %ebp,%edx
  800d47:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800d4b:	75 33                	jne    800d80 <__udivdi3+0x60>
  800d4d:	39 e9                	cmp    %ebp,%ecx
  800d4f:	77 6f                	ja     800dc0 <__udivdi3+0xa0>
  800d51:	85 c9                	test   %ecx,%ecx
  800d53:	89 ce                	mov    %ecx,%esi
  800d55:	75 0b                	jne    800d62 <__udivdi3+0x42>
  800d57:	b8 01 00 00 00       	mov    $0x1,%eax
  800d5c:	31 d2                	xor    %edx,%edx
  800d5e:	f7 f1                	div    %ecx
  800d60:	89 c6                	mov    %eax,%esi
  800d62:	31 d2                	xor    %edx,%edx
  800d64:	89 e8                	mov    %ebp,%eax
  800d66:	f7 f6                	div    %esi
  800d68:	89 c5                	mov    %eax,%ebp
  800d6a:	89 f8                	mov    %edi,%eax
  800d6c:	f7 f6                	div    %esi
  800d6e:	89 ea                	mov    %ebp,%edx
  800d70:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d74:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d78:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d7c:	83 c4 1c             	add    $0x1c,%esp
  800d7f:	c3                   	ret    
  800d80:	39 e8                	cmp    %ebp,%eax
  800d82:	77 24                	ja     800da8 <__udivdi3+0x88>
  800d84:	0f bd c8             	bsr    %eax,%ecx
  800d87:	83 f1 1f             	xor    $0x1f,%ecx
  800d8a:	89 0c 24             	mov    %ecx,(%esp)
  800d8d:	75 49                	jne    800dd8 <__udivdi3+0xb8>
  800d8f:	8b 74 24 08          	mov    0x8(%esp),%esi
  800d93:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800d97:	0f 86 ab 00 00 00    	jbe    800e48 <__udivdi3+0x128>
  800d9d:	39 e8                	cmp    %ebp,%eax
  800d9f:	0f 82 a3 00 00 00    	jb     800e48 <__udivdi3+0x128>
  800da5:	8d 76 00             	lea    0x0(%esi),%esi
  800da8:	31 d2                	xor    %edx,%edx
  800daa:	31 c0                	xor    %eax,%eax
  800dac:	8b 74 24 10          	mov    0x10(%esp),%esi
  800db0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800db4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800db8:	83 c4 1c             	add    $0x1c,%esp
  800dbb:	c3                   	ret    
  800dbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dc0:	89 f8                	mov    %edi,%eax
  800dc2:	f7 f1                	div    %ecx
  800dc4:	31 d2                	xor    %edx,%edx
  800dc6:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dca:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dce:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dd2:	83 c4 1c             	add    $0x1c,%esp
  800dd5:	c3                   	ret    
  800dd6:	66 90                	xchg   %ax,%ax
  800dd8:	0f b6 0c 24          	movzbl (%esp),%ecx
  800ddc:	89 c6                	mov    %eax,%esi
  800dde:	b8 20 00 00 00       	mov    $0x20,%eax
  800de3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800de7:	2b 04 24             	sub    (%esp),%eax
  800dea:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800dee:	d3 e6                	shl    %cl,%esi
  800df0:	89 c1                	mov    %eax,%ecx
  800df2:	d3 ed                	shr    %cl,%ebp
  800df4:	0f b6 0c 24          	movzbl (%esp),%ecx
  800df8:	09 f5                	or     %esi,%ebp
  800dfa:	8b 74 24 04          	mov    0x4(%esp),%esi
  800dfe:	d3 e6                	shl    %cl,%esi
  800e00:	89 c1                	mov    %eax,%ecx
  800e02:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e06:	89 d6                	mov    %edx,%esi
  800e08:	d3 ee                	shr    %cl,%esi
  800e0a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e0e:	d3 e2                	shl    %cl,%edx
  800e10:	89 c1                	mov    %eax,%ecx
  800e12:	d3 ef                	shr    %cl,%edi
  800e14:	09 d7                	or     %edx,%edi
  800e16:	89 f2                	mov    %esi,%edx
  800e18:	89 f8                	mov    %edi,%eax
  800e1a:	f7 f5                	div    %ebp
  800e1c:	89 d6                	mov    %edx,%esi
  800e1e:	89 c7                	mov    %eax,%edi
  800e20:	f7 64 24 04          	mull   0x4(%esp)
  800e24:	39 d6                	cmp    %edx,%esi
  800e26:	72 30                	jb     800e58 <__udivdi3+0x138>
  800e28:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800e2c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e30:	d3 e5                	shl    %cl,%ebp
  800e32:	39 c5                	cmp    %eax,%ebp
  800e34:	73 04                	jae    800e3a <__udivdi3+0x11a>
  800e36:	39 d6                	cmp    %edx,%esi
  800e38:	74 1e                	je     800e58 <__udivdi3+0x138>
  800e3a:	89 f8                	mov    %edi,%eax
  800e3c:	31 d2                	xor    %edx,%edx
  800e3e:	e9 69 ff ff ff       	jmp    800dac <__udivdi3+0x8c>
  800e43:	90                   	nop
  800e44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e48:	31 d2                	xor    %edx,%edx
  800e4a:	b8 01 00 00 00       	mov    $0x1,%eax
  800e4f:	e9 58 ff ff ff       	jmp    800dac <__udivdi3+0x8c>
  800e54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e58:	8d 47 ff             	lea    -0x1(%edi),%eax
  800e5b:	31 d2                	xor    %edx,%edx
  800e5d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e61:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e65:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e69:	83 c4 1c             	add    $0x1c,%esp
  800e6c:	c3                   	ret    
  800e6d:	66 90                	xchg   %ax,%ax
  800e6f:	90                   	nop

00800e70 <__umoddi3>:
  800e70:	83 ec 2c             	sub    $0x2c,%esp
  800e73:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800e77:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800e7b:	89 74 24 20          	mov    %esi,0x20(%esp)
  800e7f:	8b 74 24 38          	mov    0x38(%esp),%esi
  800e83:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800e87:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800e8b:	85 c0                	test   %eax,%eax
  800e8d:	89 c2                	mov    %eax,%edx
  800e8f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800e93:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800e97:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e9b:	89 74 24 10          	mov    %esi,0x10(%esp)
  800e9f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800ea3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ea7:	75 1f                	jne    800ec8 <__umoddi3+0x58>
  800ea9:	39 fe                	cmp    %edi,%esi
  800eab:	76 63                	jbe    800f10 <__umoddi3+0xa0>
  800ead:	89 c8                	mov    %ecx,%eax
  800eaf:	89 fa                	mov    %edi,%edx
  800eb1:	f7 f6                	div    %esi
  800eb3:	89 d0                	mov    %edx,%eax
  800eb5:	31 d2                	xor    %edx,%edx
  800eb7:	8b 74 24 20          	mov    0x20(%esp),%esi
  800ebb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800ebf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800ec3:	83 c4 2c             	add    $0x2c,%esp
  800ec6:	c3                   	ret    
  800ec7:	90                   	nop
  800ec8:	39 f8                	cmp    %edi,%eax
  800eca:	77 64                	ja     800f30 <__umoddi3+0xc0>
  800ecc:	0f bd e8             	bsr    %eax,%ebp
  800ecf:	83 f5 1f             	xor    $0x1f,%ebp
  800ed2:	75 74                	jne    800f48 <__umoddi3+0xd8>
  800ed4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800ed8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800edc:	0f 87 0e 01 00 00    	ja     800ff0 <__umoddi3+0x180>
  800ee2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800ee6:	29 f1                	sub    %esi,%ecx
  800ee8:	19 c7                	sbb    %eax,%edi
  800eea:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800eee:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ef2:	8b 44 24 14          	mov    0x14(%esp),%eax
  800ef6:	8b 54 24 18          	mov    0x18(%esp),%edx
  800efa:	8b 74 24 20          	mov    0x20(%esp),%esi
  800efe:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f02:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f06:	83 c4 2c             	add    $0x2c,%esp
  800f09:	c3                   	ret    
  800f0a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f10:	85 f6                	test   %esi,%esi
  800f12:	89 f5                	mov    %esi,%ebp
  800f14:	75 0b                	jne    800f21 <__umoddi3+0xb1>
  800f16:	b8 01 00 00 00       	mov    $0x1,%eax
  800f1b:	31 d2                	xor    %edx,%edx
  800f1d:	f7 f6                	div    %esi
  800f1f:	89 c5                	mov    %eax,%ebp
  800f21:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f25:	31 d2                	xor    %edx,%edx
  800f27:	f7 f5                	div    %ebp
  800f29:	89 c8                	mov    %ecx,%eax
  800f2b:	f7 f5                	div    %ebp
  800f2d:	eb 84                	jmp    800eb3 <__umoddi3+0x43>
  800f2f:	90                   	nop
  800f30:	89 c8                	mov    %ecx,%eax
  800f32:	89 fa                	mov    %edi,%edx
  800f34:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f38:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f3c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f40:	83 c4 2c             	add    $0x2c,%esp
  800f43:	c3                   	ret    
  800f44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f48:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f4c:	be 20 00 00 00       	mov    $0x20,%esi
  800f51:	89 e9                	mov    %ebp,%ecx
  800f53:	29 ee                	sub    %ebp,%esi
  800f55:	d3 e2                	shl    %cl,%edx
  800f57:	89 f1                	mov    %esi,%ecx
  800f59:	d3 e8                	shr    %cl,%eax
  800f5b:	89 e9                	mov    %ebp,%ecx
  800f5d:	09 d0                	or     %edx,%eax
  800f5f:	89 fa                	mov    %edi,%edx
  800f61:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800f65:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f69:	d3 e0                	shl    %cl,%eax
  800f6b:	89 f1                	mov    %esi,%ecx
  800f6d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f71:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800f75:	d3 ea                	shr    %cl,%edx
  800f77:	89 e9                	mov    %ebp,%ecx
  800f79:	d3 e7                	shl    %cl,%edi
  800f7b:	89 f1                	mov    %esi,%ecx
  800f7d:	d3 e8                	shr    %cl,%eax
  800f7f:	89 e9                	mov    %ebp,%ecx
  800f81:	09 f8                	or     %edi,%eax
  800f83:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800f87:	f7 74 24 0c          	divl   0xc(%esp)
  800f8b:	d3 e7                	shl    %cl,%edi
  800f8d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800f91:	89 d7                	mov    %edx,%edi
  800f93:	f7 64 24 10          	mull   0x10(%esp)
  800f97:	39 d7                	cmp    %edx,%edi
  800f99:	89 c1                	mov    %eax,%ecx
  800f9b:	89 54 24 14          	mov    %edx,0x14(%esp)
  800f9f:	72 3b                	jb     800fdc <__umoddi3+0x16c>
  800fa1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800fa5:	72 31                	jb     800fd8 <__umoddi3+0x168>
  800fa7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800fab:	29 c8                	sub    %ecx,%eax
  800fad:	19 d7                	sbb    %edx,%edi
  800faf:	89 e9                	mov    %ebp,%ecx
  800fb1:	89 fa                	mov    %edi,%edx
  800fb3:	d3 e8                	shr    %cl,%eax
  800fb5:	89 f1                	mov    %esi,%ecx
  800fb7:	d3 e2                	shl    %cl,%edx
  800fb9:	89 e9                	mov    %ebp,%ecx
  800fbb:	09 d0                	or     %edx,%eax
  800fbd:	89 fa                	mov    %edi,%edx
  800fbf:	d3 ea                	shr    %cl,%edx
  800fc1:	8b 74 24 20          	mov    0x20(%esp),%esi
  800fc5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800fc9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800fcd:	83 c4 2c             	add    $0x2c,%esp
  800fd0:	c3                   	ret    
  800fd1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800fd8:	39 d7                	cmp    %edx,%edi
  800fda:	75 cb                	jne    800fa7 <__umoddi3+0x137>
  800fdc:	8b 54 24 14          	mov    0x14(%esp),%edx
  800fe0:	89 c1                	mov    %eax,%ecx
  800fe2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  800fe6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  800fea:	eb bb                	jmp    800fa7 <__umoddi3+0x137>
  800fec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ff0:	3b 44 24 18          	cmp    0x18(%esp),%eax
  800ff4:	0f 82 e8 fe ff ff    	jb     800ee2 <__umoddi3+0x72>
  800ffa:	e9 f3 fe ff ff       	jmp    800ef2 <__umoddi3+0x82>


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
  800059:	c7 04 24 50 10 80 00 	movl   $0x801050,(%esp)
  800060:	e8 2e 01 00 00       	call   800193 <cprintf>
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
  80006b:	57                   	push   %edi
  80006c:	56                   	push   %esi
  80006d:	53                   	push   %ebx
  80006e:	83 ec 1c             	sub    $0x1c,%esp
  800071:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800074:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  800077:	e8 50 0c 00 00       	call   800ccc <sys_getenvid>
	thisenv = envs;
  80007c:	c7 05 08 20 80 00 00 	movl   $0xeec00000,0x802008
  800083:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  800086:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  80008c:	39 c2                	cmp    %eax,%edx
  80008e:	74 25                	je     8000b5 <libmain+0x4d>
  800090:	ba 60 00 c0 ee       	mov    $0xeec00060,%edx
  800095:	eb 12                	jmp    8000a9 <libmain+0x41>
  800097:	8b 4a 48             	mov    0x48(%edx),%ecx
  80009a:	83 c2 60             	add    $0x60,%edx
  80009d:	39 c1                	cmp    %eax,%ecx
  80009f:	75 08                	jne    8000a9 <libmain+0x41>
  8000a1:	89 3d 08 20 80 00    	mov    %edi,0x802008
  8000a7:	eb 0c                	jmp    8000b5 <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  8000a9:	89 d7                	mov    %edx,%edi
  8000ab:	85 d2                	test   %edx,%edx
  8000ad:	75 e8                	jne    800097 <libmain+0x2f>
  8000af:	89 15 08 20 80 00    	mov    %edx,0x802008
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000b5:	85 db                	test   %ebx,%ebx
  8000b7:	7e 07                	jle    8000c0 <libmain+0x58>
		binaryname = argv[0];
  8000b9:	8b 06                	mov    (%esi),%eax
  8000bb:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000c0:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000c4:	89 1c 24             	mov    %ebx,(%esp)
  8000c7:	e8 68 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  8000cc:	e8 0b 00 00 00       	call   8000dc <exit>
}
  8000d1:	83 c4 1c             	add    $0x1c,%esp
  8000d4:	5b                   	pop    %ebx
  8000d5:	5e                   	pop    %esi
  8000d6:	5f                   	pop    %edi
  8000d7:	5d                   	pop    %ebp
  8000d8:	c3                   	ret    
  8000d9:	66 90                	xchg   %ax,%ax
  8000db:	90                   	nop

008000dc <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000dc:	55                   	push   %ebp
  8000dd:	89 e5                	mov    %esp,%ebp
  8000df:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000e9:	e8 81 0b 00 00       	call   800c6f <sys_env_destroy>
}
  8000ee:	c9                   	leave  
  8000ef:	c3                   	ret    

008000f0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000f0:	55                   	push   %ebp
  8000f1:	89 e5                	mov    %esp,%ebp
  8000f3:	53                   	push   %ebx
  8000f4:	83 ec 14             	sub    $0x14,%esp
  8000f7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000fa:	8b 03                	mov    (%ebx),%eax
  8000fc:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ff:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  800103:	83 c0 01             	add    $0x1,%eax
  800106:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800108:	3d ff 00 00 00       	cmp    $0xff,%eax
  80010d:	75 19                	jne    800128 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80010f:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800116:	00 
  800117:	8d 43 08             	lea    0x8(%ebx),%eax
  80011a:	89 04 24             	mov    %eax,(%esp)
  80011d:	e8 ee 0a 00 00       	call   800c10 <sys_cputs>
		b->idx = 0;
  800122:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800128:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80012c:	83 c4 14             	add    $0x14,%esp
  80012f:	5b                   	pop    %ebx
  800130:	5d                   	pop    %ebp
  800131:	c3                   	ret    

00800132 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800132:	55                   	push   %ebp
  800133:	89 e5                	mov    %esp,%ebp
  800135:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80013b:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800142:	00 00 00 
	b.cnt = 0;
  800145:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80014c:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80014f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800152:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800156:	8b 45 08             	mov    0x8(%ebp),%eax
  800159:	89 44 24 08          	mov    %eax,0x8(%esp)
  80015d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800163:	89 44 24 04          	mov    %eax,0x4(%esp)
  800167:	c7 04 24 f0 00 80 00 	movl   $0x8000f0,(%esp)
  80016e:	e8 af 01 00 00       	call   800322 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800173:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800179:	89 44 24 04          	mov    %eax,0x4(%esp)
  80017d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800183:	89 04 24             	mov    %eax,(%esp)
  800186:	e8 85 0a 00 00       	call   800c10 <sys_cputs>

	return b.cnt;
}
  80018b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800191:	c9                   	leave  
  800192:	c3                   	ret    

00800193 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800193:	55                   	push   %ebp
  800194:	89 e5                	mov    %esp,%ebp
  800196:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800199:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80019c:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001a0:	8b 45 08             	mov    0x8(%ebp),%eax
  8001a3:	89 04 24             	mov    %eax,(%esp)
  8001a6:	e8 87 ff ff ff       	call   800132 <vcprintf>
	va_end(ap);

	return cnt;
}
  8001ab:	c9                   	leave  
  8001ac:	c3                   	ret    
  8001ad:	66 90                	xchg   %ax,%ax
  8001af:	90                   	nop

008001b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001b0:	55                   	push   %ebp
  8001b1:	89 e5                	mov    %esp,%ebp
  8001b3:	57                   	push   %edi
  8001b4:	56                   	push   %esi
  8001b5:	53                   	push   %ebx
  8001b6:	83 ec 4c             	sub    $0x4c,%esp
  8001b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8001bc:	89 d7                	mov    %edx,%edi
  8001be:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8001c1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8001c4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8001c7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001ca:	b8 00 00 00 00       	mov    $0x0,%eax
  8001cf:	39 d8                	cmp    %ebx,%eax
  8001d1:	72 17                	jb     8001ea <printnum+0x3a>
  8001d3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8001d6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8001d9:	76 0f                	jbe    8001ea <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001db:	8b 75 14             	mov    0x14(%ebp),%esi
  8001de:	83 ee 01             	sub    $0x1,%esi
  8001e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8001e4:	85 f6                	test   %esi,%esi
  8001e6:	7f 63                	jg     80024b <printnum+0x9b>
  8001e8:	eb 75                	jmp    80025f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001ea:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8001ed:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8001f1:	8b 45 14             	mov    0x14(%ebp),%eax
  8001f4:	83 e8 01             	sub    $0x1,%eax
  8001f7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001fb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800202:	8b 44 24 08          	mov    0x8(%esp),%eax
  800206:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80020a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80020d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800210:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800217:	00 
  800218:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80021b:	89 1c 24             	mov    %ebx,(%esp)
  80021e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800221:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800225:	e8 46 0b 00 00       	call   800d70 <__udivdi3>
  80022a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80022d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800230:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800234:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800238:	89 04 24             	mov    %eax,(%esp)
  80023b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80023f:	89 fa                	mov    %edi,%edx
  800241:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800244:	e8 67 ff ff ff       	call   8001b0 <printnum>
  800249:	eb 14                	jmp    80025f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80024b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80024f:	8b 45 18             	mov    0x18(%ebp),%eax
  800252:	89 04 24             	mov    %eax,(%esp)
  800255:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800257:	83 ee 01             	sub    $0x1,%esi
  80025a:	75 ef                	jne    80024b <printnum+0x9b>
  80025c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80025f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800263:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800267:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80026a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80026e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800275:	00 
  800276:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800279:	89 1c 24             	mov    %ebx,(%esp)
  80027c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80027f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800283:	e8 38 0c 00 00       	call   800ec0 <__umoddi3>
  800288:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80028c:	0f be 80 68 10 80 00 	movsbl 0x801068(%eax),%eax
  800293:	89 04 24             	mov    %eax,(%esp)
  800296:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800299:	ff d0                	call   *%eax
}
  80029b:	83 c4 4c             	add    $0x4c,%esp
  80029e:	5b                   	pop    %ebx
  80029f:	5e                   	pop    %esi
  8002a0:	5f                   	pop    %edi
  8002a1:	5d                   	pop    %ebp
  8002a2:	c3                   	ret    

008002a3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002a3:	55                   	push   %ebp
  8002a4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002a6:	83 fa 01             	cmp    $0x1,%edx
  8002a9:	7e 0e                	jle    8002b9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002ab:	8b 10                	mov    (%eax),%edx
  8002ad:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002b0:	89 08                	mov    %ecx,(%eax)
  8002b2:	8b 02                	mov    (%edx),%eax
  8002b4:	8b 52 04             	mov    0x4(%edx),%edx
  8002b7:	eb 22                	jmp    8002db <getuint+0x38>
	else if (lflag)
  8002b9:	85 d2                	test   %edx,%edx
  8002bb:	74 10                	je     8002cd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002bd:	8b 10                	mov    (%eax),%edx
  8002bf:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002c2:	89 08                	mov    %ecx,(%eax)
  8002c4:	8b 02                	mov    (%edx),%eax
  8002c6:	ba 00 00 00 00       	mov    $0x0,%edx
  8002cb:	eb 0e                	jmp    8002db <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002cd:	8b 10                	mov    (%eax),%edx
  8002cf:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002d2:	89 08                	mov    %ecx,(%eax)
  8002d4:	8b 02                	mov    (%edx),%eax
  8002d6:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002db:	5d                   	pop    %ebp
  8002dc:	c3                   	ret    

008002dd <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002dd:	55                   	push   %ebp
  8002de:	89 e5                	mov    %esp,%ebp
  8002e0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002e3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002e7:	8b 10                	mov    (%eax),%edx
  8002e9:	3b 50 04             	cmp    0x4(%eax),%edx
  8002ec:	73 0a                	jae    8002f8 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002ee:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002f1:	88 0a                	mov    %cl,(%edx)
  8002f3:	83 c2 01             	add    $0x1,%edx
  8002f6:	89 10                	mov    %edx,(%eax)
}
  8002f8:	5d                   	pop    %ebp
  8002f9:	c3                   	ret    

008002fa <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002fa:	55                   	push   %ebp
  8002fb:	89 e5                	mov    %esp,%ebp
  8002fd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800300:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800303:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800307:	8b 45 10             	mov    0x10(%ebp),%eax
  80030a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80030e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800311:	89 44 24 04          	mov    %eax,0x4(%esp)
  800315:	8b 45 08             	mov    0x8(%ebp),%eax
  800318:	89 04 24             	mov    %eax,(%esp)
  80031b:	e8 02 00 00 00       	call   800322 <vprintfmt>
	va_end(ap);
}
  800320:	c9                   	leave  
  800321:	c3                   	ret    

00800322 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800322:	55                   	push   %ebp
  800323:	89 e5                	mov    %esp,%ebp
  800325:	57                   	push   %edi
  800326:	56                   	push   %esi
  800327:	53                   	push   %ebx
  800328:	83 ec 4c             	sub    $0x4c,%esp
  80032b:	8b 75 08             	mov    0x8(%ebp),%esi
  80032e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800331:	8b 7d 10             	mov    0x10(%ebp),%edi
  800334:	eb 11                	jmp    800347 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800336:	85 c0                	test   %eax,%eax
  800338:	0f 84 db 03 00 00    	je     800719 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80033e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800342:	89 04 24             	mov    %eax,(%esp)
  800345:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800347:	0f b6 07             	movzbl (%edi),%eax
  80034a:	83 c7 01             	add    $0x1,%edi
  80034d:	83 f8 25             	cmp    $0x25,%eax
  800350:	75 e4                	jne    800336 <vprintfmt+0x14>
  800352:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800356:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80035d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800364:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80036b:	ba 00 00 00 00       	mov    $0x0,%edx
  800370:	eb 2b                	jmp    80039d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800372:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800375:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800379:	eb 22                	jmp    80039d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80037b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80037e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800382:	eb 19                	jmp    80039d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800384:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800387:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80038e:	eb 0d                	jmp    80039d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800390:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800393:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800396:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039d:	0f b6 0f             	movzbl (%edi),%ecx
  8003a0:	8d 47 01             	lea    0x1(%edi),%eax
  8003a3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003a6:	0f b6 07             	movzbl (%edi),%eax
  8003a9:	83 e8 23             	sub    $0x23,%eax
  8003ac:	3c 55                	cmp    $0x55,%al
  8003ae:	0f 87 40 03 00 00    	ja     8006f4 <vprintfmt+0x3d2>
  8003b4:	0f b6 c0             	movzbl %al,%eax
  8003b7:	ff 24 85 f8 10 80 00 	jmp    *0x8010f8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003be:	83 e9 30             	sub    $0x30,%ecx
  8003c1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  8003c4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  8003c8:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8003cb:	83 f9 09             	cmp    $0x9,%ecx
  8003ce:	77 57                	ja     800427 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d0:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8003d3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8003d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003d9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  8003dc:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8003df:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8003e3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8003e6:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8003e9:	83 f9 09             	cmp    $0x9,%ecx
  8003ec:	76 eb                	jbe    8003d9 <vprintfmt+0xb7>
  8003ee:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8003f1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  8003f4:	eb 34                	jmp    80042a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003f6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003f9:	8d 48 04             	lea    0x4(%eax),%ecx
  8003fc:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003ff:	8b 00                	mov    (%eax),%eax
  800401:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800404:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800407:	eb 21                	jmp    80042a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800409:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80040d:	0f 88 71 ff ff ff    	js     800384 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800413:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800416:	eb 85                	jmp    80039d <vprintfmt+0x7b>
  800418:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80041b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800422:	e9 76 ff ff ff       	jmp    80039d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800427:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80042a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80042e:	0f 89 69 ff ff ff    	jns    80039d <vprintfmt+0x7b>
  800434:	e9 57 ff ff ff       	jmp    800390 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800439:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80043f:	e9 59 ff ff ff       	jmp    80039d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800444:	8b 45 14             	mov    0x14(%ebp),%eax
  800447:	8d 50 04             	lea    0x4(%eax),%edx
  80044a:	89 55 14             	mov    %edx,0x14(%ebp)
  80044d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800451:	8b 00                	mov    (%eax),%eax
  800453:	89 04 24             	mov    %eax,(%esp)
  800456:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800458:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80045b:	e9 e7 fe ff ff       	jmp    800347 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800460:	8b 45 14             	mov    0x14(%ebp),%eax
  800463:	8d 50 04             	lea    0x4(%eax),%edx
  800466:	89 55 14             	mov    %edx,0x14(%ebp)
  800469:	8b 00                	mov    (%eax),%eax
  80046b:	89 c2                	mov    %eax,%edx
  80046d:	c1 fa 1f             	sar    $0x1f,%edx
  800470:	31 d0                	xor    %edx,%eax
  800472:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800474:	83 f8 06             	cmp    $0x6,%eax
  800477:	7f 0b                	jg     800484 <vprintfmt+0x162>
  800479:	8b 14 85 50 12 80 00 	mov    0x801250(,%eax,4),%edx
  800480:	85 d2                	test   %edx,%edx
  800482:	75 20                	jne    8004a4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800484:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800488:	c7 44 24 08 80 10 80 	movl   $0x801080,0x8(%esp)
  80048f:	00 
  800490:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800494:	89 34 24             	mov    %esi,(%esp)
  800497:	e8 5e fe ff ff       	call   8002fa <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80049c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80049f:	e9 a3 fe ff ff       	jmp    800347 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8004a4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8004a8:	c7 44 24 08 89 10 80 	movl   $0x801089,0x8(%esp)
  8004af:	00 
  8004b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004b4:	89 34 24             	mov    %esi,(%esp)
  8004b7:	e8 3e fe ff ff       	call   8002fa <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004bc:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004bf:	e9 83 fe ff ff       	jmp    800347 <vprintfmt+0x25>
  8004c4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8004c7:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8004ca:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d0:	8d 50 04             	lea    0x4(%eax),%edx
  8004d3:	89 55 14             	mov    %edx,0x14(%ebp)
  8004d6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004d8:	85 ff                	test   %edi,%edi
  8004da:	b8 79 10 80 00       	mov    $0x801079,%eax
  8004df:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004e2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8004e6:	74 06                	je     8004ee <vprintfmt+0x1cc>
  8004e8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8004ec:	7f 16                	jg     800504 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004ee:	0f b6 17             	movzbl (%edi),%edx
  8004f1:	0f be c2             	movsbl %dl,%eax
  8004f4:	83 c7 01             	add    $0x1,%edi
  8004f7:	85 c0                	test   %eax,%eax
  8004f9:	0f 85 9f 00 00 00    	jne    80059e <vprintfmt+0x27c>
  8004ff:	e9 8b 00 00 00       	jmp    80058f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800504:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800508:	89 3c 24             	mov    %edi,(%esp)
  80050b:	e8 c2 02 00 00       	call   8007d2 <strnlen>
  800510:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800513:	29 c2                	sub    %eax,%edx
  800515:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800518:	85 d2                	test   %edx,%edx
  80051a:	7e d2                	jle    8004ee <vprintfmt+0x1cc>
					putch(padc, putdat);
  80051c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800520:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800523:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800526:	89 d7                	mov    %edx,%edi
  800528:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80052c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80052f:	89 04 24             	mov    %eax,(%esp)
  800532:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800534:	83 ef 01             	sub    $0x1,%edi
  800537:	75 ef                	jne    800528 <vprintfmt+0x206>
  800539:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80053c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80053f:	eb ad                	jmp    8004ee <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800541:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800545:	74 20                	je     800567 <vprintfmt+0x245>
  800547:	0f be d2             	movsbl %dl,%edx
  80054a:	83 ea 20             	sub    $0x20,%edx
  80054d:	83 fa 5e             	cmp    $0x5e,%edx
  800550:	76 15                	jbe    800567 <vprintfmt+0x245>
					putch('?', putdat);
  800552:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800555:	89 54 24 04          	mov    %edx,0x4(%esp)
  800559:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800560:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800563:	ff d1                	call   *%ecx
  800565:	eb 0f                	jmp    800576 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800567:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80056a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80056e:	89 04 24             	mov    %eax,(%esp)
  800571:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800574:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800576:	83 eb 01             	sub    $0x1,%ebx
  800579:	0f b6 17             	movzbl (%edi),%edx
  80057c:	0f be c2             	movsbl %dl,%eax
  80057f:	83 c7 01             	add    $0x1,%edi
  800582:	85 c0                	test   %eax,%eax
  800584:	75 24                	jne    8005aa <vprintfmt+0x288>
  800586:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800589:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80058c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80058f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800592:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800596:	0f 8e ab fd ff ff    	jle    800347 <vprintfmt+0x25>
  80059c:	eb 20                	jmp    8005be <vprintfmt+0x29c>
  80059e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8005a1:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8005a4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8005a7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005aa:	85 f6                	test   %esi,%esi
  8005ac:	78 93                	js     800541 <vprintfmt+0x21f>
  8005ae:	83 ee 01             	sub    $0x1,%esi
  8005b1:	79 8e                	jns    800541 <vprintfmt+0x21f>
  8005b3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005b6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8005b9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8005bc:	eb d1                	jmp    80058f <vprintfmt+0x26d>
  8005be:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005c5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8005cc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005ce:	83 ef 01             	sub    $0x1,%edi
  8005d1:	75 ee                	jne    8005c1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8005d6:	e9 6c fd ff ff       	jmp    800347 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005db:	83 fa 01             	cmp    $0x1,%edx
  8005de:	66 90                	xchg   %ax,%ax
  8005e0:	7e 16                	jle    8005f8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  8005e2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e5:	8d 50 08             	lea    0x8(%eax),%edx
  8005e8:	89 55 14             	mov    %edx,0x14(%ebp)
  8005eb:	8b 10                	mov    (%eax),%edx
  8005ed:	8b 48 04             	mov    0x4(%eax),%ecx
  8005f0:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8005f3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005f6:	eb 32                	jmp    80062a <vprintfmt+0x308>
	else if (lflag)
  8005f8:	85 d2                	test   %edx,%edx
  8005fa:	74 18                	je     800614 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  8005fc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ff:	8d 50 04             	lea    0x4(%eax),%edx
  800602:	89 55 14             	mov    %edx,0x14(%ebp)
  800605:	8b 00                	mov    (%eax),%eax
  800607:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80060a:	89 c1                	mov    %eax,%ecx
  80060c:	c1 f9 1f             	sar    $0x1f,%ecx
  80060f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800612:	eb 16                	jmp    80062a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800614:	8b 45 14             	mov    0x14(%ebp),%eax
  800617:	8d 50 04             	lea    0x4(%eax),%edx
  80061a:	89 55 14             	mov    %edx,0x14(%ebp)
  80061d:	8b 00                	mov    (%eax),%eax
  80061f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800622:	89 c7                	mov    %eax,%edi
  800624:	c1 ff 1f             	sar    $0x1f,%edi
  800627:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80062a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80062d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800630:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800635:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800639:	79 7d                	jns    8006b8 <vprintfmt+0x396>
				putch('-', putdat);
  80063b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80063f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800646:	ff d6                	call   *%esi
				num = -(long long) num;
  800648:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80064b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80064e:	f7 d8                	neg    %eax
  800650:	83 d2 00             	adc    $0x0,%edx
  800653:	f7 da                	neg    %edx
			}
			base = 10;
  800655:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80065a:	eb 5c                	jmp    8006b8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80065c:	8d 45 14             	lea    0x14(%ebp),%eax
  80065f:	e8 3f fc ff ff       	call   8002a3 <getuint>
			base = 10;
  800664:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800669:	eb 4d                	jmp    8006b8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80066b:	8d 45 14             	lea    0x14(%ebp),%eax
  80066e:	e8 30 fc ff ff       	call   8002a3 <getuint>
			base = 8;
  800673:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800678:	eb 3e                	jmp    8006b8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  80067a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80067e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800685:	ff d6                	call   *%esi
			putch('x', putdat);
  800687:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80068b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800692:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800694:	8b 45 14             	mov    0x14(%ebp),%eax
  800697:	8d 50 04             	lea    0x4(%eax),%edx
  80069a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80069d:	8b 00                	mov    (%eax),%eax
  80069f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006a4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006a9:	eb 0d                	jmp    8006b8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006ab:	8d 45 14             	lea    0x14(%ebp),%eax
  8006ae:	e8 f0 fb ff ff       	call   8002a3 <getuint>
			base = 16;
  8006b3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006b8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  8006bc:	89 7c 24 10          	mov    %edi,0x10(%esp)
  8006c0:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8006c3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8006c7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8006cb:	89 04 24             	mov    %eax,(%esp)
  8006ce:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006d2:	89 da                	mov    %ebx,%edx
  8006d4:	89 f0                	mov    %esi,%eax
  8006d6:	e8 d5 fa ff ff       	call   8001b0 <printnum>
			break;
  8006db:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8006de:	e9 64 fc ff ff       	jmp    800347 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006e3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006e7:	89 0c 24             	mov    %ecx,(%esp)
  8006ea:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006ec:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006ef:	e9 53 fc ff ff       	jmp    800347 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006f4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006f8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006ff:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800701:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800705:	0f 84 3c fc ff ff    	je     800347 <vprintfmt+0x25>
  80070b:	83 ef 01             	sub    $0x1,%edi
  80070e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800712:	75 f7                	jne    80070b <vprintfmt+0x3e9>
  800714:	e9 2e fc ff ff       	jmp    800347 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800719:	83 c4 4c             	add    $0x4c,%esp
  80071c:	5b                   	pop    %ebx
  80071d:	5e                   	pop    %esi
  80071e:	5f                   	pop    %edi
  80071f:	5d                   	pop    %ebp
  800720:	c3                   	ret    

00800721 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800721:	55                   	push   %ebp
  800722:	89 e5                	mov    %esp,%ebp
  800724:	83 ec 28             	sub    $0x28,%esp
  800727:	8b 45 08             	mov    0x8(%ebp),%eax
  80072a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80072d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800730:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800734:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800737:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80073e:	85 d2                	test   %edx,%edx
  800740:	7e 30                	jle    800772 <vsnprintf+0x51>
  800742:	85 c0                	test   %eax,%eax
  800744:	74 2c                	je     800772 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800746:	8b 45 14             	mov    0x14(%ebp),%eax
  800749:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80074d:	8b 45 10             	mov    0x10(%ebp),%eax
  800750:	89 44 24 08          	mov    %eax,0x8(%esp)
  800754:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800757:	89 44 24 04          	mov    %eax,0x4(%esp)
  80075b:	c7 04 24 dd 02 80 00 	movl   $0x8002dd,(%esp)
  800762:	e8 bb fb ff ff       	call   800322 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800767:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80076a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80076d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800770:	eb 05                	jmp    800777 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800772:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800777:	c9                   	leave  
  800778:	c3                   	ret    

00800779 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800779:	55                   	push   %ebp
  80077a:	89 e5                	mov    %esp,%ebp
  80077c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80077f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800782:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800786:	8b 45 10             	mov    0x10(%ebp),%eax
  800789:	89 44 24 08          	mov    %eax,0x8(%esp)
  80078d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800790:	89 44 24 04          	mov    %eax,0x4(%esp)
  800794:	8b 45 08             	mov    0x8(%ebp),%eax
  800797:	89 04 24             	mov    %eax,(%esp)
  80079a:	e8 82 ff ff ff       	call   800721 <vsnprintf>
	va_end(ap);

	return rc;
}
  80079f:	c9                   	leave  
  8007a0:	c3                   	ret    
  8007a1:	66 90                	xchg   %ax,%ax
  8007a3:	66 90                	xchg   %ax,%ax
  8007a5:	66 90                	xchg   %ax,%ax
  8007a7:	66 90                	xchg   %ax,%ax
  8007a9:	66 90                	xchg   %ax,%ax
  8007ab:	66 90                	xchg   %ax,%ax
  8007ad:	66 90                	xchg   %ax,%ax
  8007af:	90                   	nop

008007b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007b0:	55                   	push   %ebp
  8007b1:	89 e5                	mov    %esp,%ebp
  8007b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007b6:	80 3a 00             	cmpb   $0x0,(%edx)
  8007b9:	74 10                	je     8007cb <strlen+0x1b>
  8007bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  8007c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007c7:	75 f7                	jne    8007c0 <strlen+0x10>
  8007c9:	eb 05                	jmp    8007d0 <strlen+0x20>
  8007cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8007d0:	5d                   	pop    %ebp
  8007d1:	c3                   	ret    

008007d2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007d2:	55                   	push   %ebp
  8007d3:	89 e5                	mov    %esp,%ebp
  8007d5:	53                   	push   %ebx
  8007d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8007d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007dc:	85 c9                	test   %ecx,%ecx
  8007de:	74 1c                	je     8007fc <strnlen+0x2a>
  8007e0:	80 3b 00             	cmpb   $0x0,(%ebx)
  8007e3:	74 1e                	je     800803 <strnlen+0x31>
  8007e5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  8007ea:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007ec:	39 ca                	cmp    %ecx,%edx
  8007ee:	74 18                	je     800808 <strnlen+0x36>
  8007f0:	83 c2 01             	add    $0x1,%edx
  8007f3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8007f8:	75 f0                	jne    8007ea <strnlen+0x18>
  8007fa:	eb 0c                	jmp    800808 <strnlen+0x36>
  8007fc:	b8 00 00 00 00       	mov    $0x0,%eax
  800801:	eb 05                	jmp    800808 <strnlen+0x36>
  800803:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800808:	5b                   	pop    %ebx
  800809:	5d                   	pop    %ebp
  80080a:	c3                   	ret    

0080080b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80080b:	55                   	push   %ebp
  80080c:	89 e5                	mov    %esp,%ebp
  80080e:	53                   	push   %ebx
  80080f:	8b 45 08             	mov    0x8(%ebp),%eax
  800812:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800815:	89 c2                	mov    %eax,%edx
  800817:	0f b6 19             	movzbl (%ecx),%ebx
  80081a:	88 1a                	mov    %bl,(%edx)
  80081c:	83 c2 01             	add    $0x1,%edx
  80081f:	83 c1 01             	add    $0x1,%ecx
  800822:	84 db                	test   %bl,%bl
  800824:	75 f1                	jne    800817 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800826:	5b                   	pop    %ebx
  800827:	5d                   	pop    %ebp
  800828:	c3                   	ret    

00800829 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800829:	55                   	push   %ebp
  80082a:	89 e5                	mov    %esp,%ebp
  80082c:	53                   	push   %ebx
  80082d:	83 ec 08             	sub    $0x8,%esp
  800830:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800833:	89 1c 24             	mov    %ebx,(%esp)
  800836:	e8 75 ff ff ff       	call   8007b0 <strlen>
	strcpy(dst + len, src);
  80083b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80083e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800842:	01 d8                	add    %ebx,%eax
  800844:	89 04 24             	mov    %eax,(%esp)
  800847:	e8 bf ff ff ff       	call   80080b <strcpy>
	return dst;
}
  80084c:	89 d8                	mov    %ebx,%eax
  80084e:	83 c4 08             	add    $0x8,%esp
  800851:	5b                   	pop    %ebx
  800852:	5d                   	pop    %ebp
  800853:	c3                   	ret    

00800854 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800854:	55                   	push   %ebp
  800855:	89 e5                	mov    %esp,%ebp
  800857:	56                   	push   %esi
  800858:	53                   	push   %ebx
  800859:	8b 75 08             	mov    0x8(%ebp),%esi
  80085c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80085f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800862:	85 db                	test   %ebx,%ebx
  800864:	74 16                	je     80087c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800866:	01 f3                	add    %esi,%ebx
  800868:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  80086a:	0f b6 02             	movzbl (%edx),%eax
  80086d:	88 01                	mov    %al,(%ecx)
  80086f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800872:	80 3a 01             	cmpb   $0x1,(%edx)
  800875:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800878:	39 d9                	cmp    %ebx,%ecx
  80087a:	75 ee                	jne    80086a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80087c:	89 f0                	mov    %esi,%eax
  80087e:	5b                   	pop    %ebx
  80087f:	5e                   	pop    %esi
  800880:	5d                   	pop    %ebp
  800881:	c3                   	ret    

00800882 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800882:	55                   	push   %ebp
  800883:	89 e5                	mov    %esp,%ebp
  800885:	57                   	push   %edi
  800886:	56                   	push   %esi
  800887:	53                   	push   %ebx
  800888:	8b 7d 08             	mov    0x8(%ebp),%edi
  80088b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80088e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800891:	89 f8                	mov    %edi,%eax
  800893:	85 f6                	test   %esi,%esi
  800895:	74 33                	je     8008ca <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800897:	83 fe 01             	cmp    $0x1,%esi
  80089a:	74 25                	je     8008c1 <strlcpy+0x3f>
  80089c:	0f b6 0b             	movzbl (%ebx),%ecx
  80089f:	84 c9                	test   %cl,%cl
  8008a1:	74 22                	je     8008c5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  8008a3:	83 ee 02             	sub    $0x2,%esi
  8008a6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008ab:	88 08                	mov    %cl,(%eax)
  8008ad:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008b0:	39 f2                	cmp    %esi,%edx
  8008b2:	74 13                	je     8008c7 <strlcpy+0x45>
  8008b4:	83 c2 01             	add    $0x1,%edx
  8008b7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  8008bb:	84 c9                	test   %cl,%cl
  8008bd:	75 ec                	jne    8008ab <strlcpy+0x29>
  8008bf:	eb 06                	jmp    8008c7 <strlcpy+0x45>
  8008c1:	89 f8                	mov    %edi,%eax
  8008c3:	eb 02                	jmp    8008c7 <strlcpy+0x45>
  8008c5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008c7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008ca:	29 f8                	sub    %edi,%eax
}
  8008cc:	5b                   	pop    %ebx
  8008cd:	5e                   	pop    %esi
  8008ce:	5f                   	pop    %edi
  8008cf:	5d                   	pop    %ebp
  8008d0:	c3                   	ret    

008008d1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008d1:	55                   	push   %ebp
  8008d2:	89 e5                	mov    %esp,%ebp
  8008d4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008da:	0f b6 01             	movzbl (%ecx),%eax
  8008dd:	84 c0                	test   %al,%al
  8008df:	74 15                	je     8008f6 <strcmp+0x25>
  8008e1:	3a 02                	cmp    (%edx),%al
  8008e3:	75 11                	jne    8008f6 <strcmp+0x25>
		p++, q++;
  8008e5:	83 c1 01             	add    $0x1,%ecx
  8008e8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008eb:	0f b6 01             	movzbl (%ecx),%eax
  8008ee:	84 c0                	test   %al,%al
  8008f0:	74 04                	je     8008f6 <strcmp+0x25>
  8008f2:	3a 02                	cmp    (%edx),%al
  8008f4:	74 ef                	je     8008e5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008f6:	0f b6 c0             	movzbl %al,%eax
  8008f9:	0f b6 12             	movzbl (%edx),%edx
  8008fc:	29 d0                	sub    %edx,%eax
}
  8008fe:	5d                   	pop    %ebp
  8008ff:	c3                   	ret    

00800900 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800900:	55                   	push   %ebp
  800901:	89 e5                	mov    %esp,%ebp
  800903:	56                   	push   %esi
  800904:	53                   	push   %ebx
  800905:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800908:	8b 55 0c             	mov    0xc(%ebp),%edx
  80090b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  80090e:	85 f6                	test   %esi,%esi
  800910:	74 29                	je     80093b <strncmp+0x3b>
  800912:	0f b6 03             	movzbl (%ebx),%eax
  800915:	84 c0                	test   %al,%al
  800917:	74 30                	je     800949 <strncmp+0x49>
  800919:	3a 02                	cmp    (%edx),%al
  80091b:	75 2c                	jne    800949 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  80091d:	8d 43 01             	lea    0x1(%ebx),%eax
  800920:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800922:	89 c3                	mov    %eax,%ebx
  800924:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800927:	39 f0                	cmp    %esi,%eax
  800929:	74 17                	je     800942 <strncmp+0x42>
  80092b:	0f b6 08             	movzbl (%eax),%ecx
  80092e:	84 c9                	test   %cl,%cl
  800930:	74 17                	je     800949 <strncmp+0x49>
  800932:	83 c0 01             	add    $0x1,%eax
  800935:	3a 0a                	cmp    (%edx),%cl
  800937:	74 e9                	je     800922 <strncmp+0x22>
  800939:	eb 0e                	jmp    800949 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  80093b:	b8 00 00 00 00       	mov    $0x0,%eax
  800940:	eb 0f                	jmp    800951 <strncmp+0x51>
  800942:	b8 00 00 00 00       	mov    $0x0,%eax
  800947:	eb 08                	jmp    800951 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800949:	0f b6 03             	movzbl (%ebx),%eax
  80094c:	0f b6 12             	movzbl (%edx),%edx
  80094f:	29 d0                	sub    %edx,%eax
}
  800951:	5b                   	pop    %ebx
  800952:	5e                   	pop    %esi
  800953:	5d                   	pop    %ebp
  800954:	c3                   	ret    

00800955 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800955:	55                   	push   %ebp
  800956:	89 e5                	mov    %esp,%ebp
  800958:	53                   	push   %ebx
  800959:	8b 45 08             	mov    0x8(%ebp),%eax
  80095c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  80095f:	0f b6 18             	movzbl (%eax),%ebx
  800962:	84 db                	test   %bl,%bl
  800964:	74 1d                	je     800983 <strchr+0x2e>
  800966:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800968:	38 d3                	cmp    %dl,%bl
  80096a:	75 06                	jne    800972 <strchr+0x1d>
  80096c:	eb 1a                	jmp    800988 <strchr+0x33>
  80096e:	38 ca                	cmp    %cl,%dl
  800970:	74 16                	je     800988 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800972:	83 c0 01             	add    $0x1,%eax
  800975:	0f b6 10             	movzbl (%eax),%edx
  800978:	84 d2                	test   %dl,%dl
  80097a:	75 f2                	jne    80096e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  80097c:	b8 00 00 00 00       	mov    $0x0,%eax
  800981:	eb 05                	jmp    800988 <strchr+0x33>
  800983:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800988:	5b                   	pop    %ebx
  800989:	5d                   	pop    %ebp
  80098a:	c3                   	ret    

0080098b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80098b:	55                   	push   %ebp
  80098c:	89 e5                	mov    %esp,%ebp
  80098e:	53                   	push   %ebx
  80098f:	8b 45 08             	mov    0x8(%ebp),%eax
  800992:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800995:	0f b6 18             	movzbl (%eax),%ebx
  800998:	84 db                	test   %bl,%bl
  80099a:	74 16                	je     8009b2 <strfind+0x27>
  80099c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  80099e:	38 d3                	cmp    %dl,%bl
  8009a0:	75 06                	jne    8009a8 <strfind+0x1d>
  8009a2:	eb 0e                	jmp    8009b2 <strfind+0x27>
  8009a4:	38 ca                	cmp    %cl,%dl
  8009a6:	74 0a                	je     8009b2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8009a8:	83 c0 01             	add    $0x1,%eax
  8009ab:	0f b6 10             	movzbl (%eax),%edx
  8009ae:	84 d2                	test   %dl,%dl
  8009b0:	75 f2                	jne    8009a4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  8009b2:	5b                   	pop    %ebx
  8009b3:	5d                   	pop    %ebp
  8009b4:	c3                   	ret    

008009b5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009b5:	55                   	push   %ebp
  8009b6:	89 e5                	mov    %esp,%ebp
  8009b8:	83 ec 0c             	sub    $0xc,%esp
  8009bb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8009be:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8009c1:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009c4:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009c7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009ca:	85 c9                	test   %ecx,%ecx
  8009cc:	74 36                	je     800a04 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009ce:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009d4:	75 28                	jne    8009fe <memset+0x49>
  8009d6:	f6 c1 03             	test   $0x3,%cl
  8009d9:	75 23                	jne    8009fe <memset+0x49>
		c &= 0xFF;
  8009db:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009df:	89 d3                	mov    %edx,%ebx
  8009e1:	c1 e3 08             	shl    $0x8,%ebx
  8009e4:	89 d6                	mov    %edx,%esi
  8009e6:	c1 e6 18             	shl    $0x18,%esi
  8009e9:	89 d0                	mov    %edx,%eax
  8009eb:	c1 e0 10             	shl    $0x10,%eax
  8009ee:	09 f0                	or     %esi,%eax
  8009f0:	09 c2                	or     %eax,%edx
  8009f2:	89 d0                	mov    %edx,%eax
  8009f4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009f6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009f9:	fc                   	cld    
  8009fa:	f3 ab                	rep stos %eax,%es:(%edi)
  8009fc:	eb 06                	jmp    800a04 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a01:	fc                   	cld    
  800a02:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a04:	89 f8                	mov    %edi,%eax
  800a06:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a09:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a0c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a0f:	89 ec                	mov    %ebp,%esp
  800a11:	5d                   	pop    %ebp
  800a12:	c3                   	ret    

00800a13 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a13:	55                   	push   %ebp
  800a14:	89 e5                	mov    %esp,%ebp
  800a16:	83 ec 08             	sub    $0x8,%esp
  800a19:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a1c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a1f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a22:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a25:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a28:	39 c6                	cmp    %eax,%esi
  800a2a:	73 36                	jae    800a62 <memmove+0x4f>
  800a2c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a2f:	39 d0                	cmp    %edx,%eax
  800a31:	73 2f                	jae    800a62 <memmove+0x4f>
		s += n;
		d += n;
  800a33:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a36:	f6 c2 03             	test   $0x3,%dl
  800a39:	75 1b                	jne    800a56 <memmove+0x43>
  800a3b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a41:	75 13                	jne    800a56 <memmove+0x43>
  800a43:	f6 c1 03             	test   $0x3,%cl
  800a46:	75 0e                	jne    800a56 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a48:	83 ef 04             	sub    $0x4,%edi
  800a4b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a4e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a51:	fd                   	std    
  800a52:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a54:	eb 09                	jmp    800a5f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a56:	83 ef 01             	sub    $0x1,%edi
  800a59:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a5c:	fd                   	std    
  800a5d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a5f:	fc                   	cld    
  800a60:	eb 20                	jmp    800a82 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a62:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a68:	75 13                	jne    800a7d <memmove+0x6a>
  800a6a:	a8 03                	test   $0x3,%al
  800a6c:	75 0f                	jne    800a7d <memmove+0x6a>
  800a6e:	f6 c1 03             	test   $0x3,%cl
  800a71:	75 0a                	jne    800a7d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a73:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a76:	89 c7                	mov    %eax,%edi
  800a78:	fc                   	cld    
  800a79:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a7b:	eb 05                	jmp    800a82 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a7d:	89 c7                	mov    %eax,%edi
  800a7f:	fc                   	cld    
  800a80:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a82:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a85:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a88:	89 ec                	mov    %ebp,%esp
  800a8a:	5d                   	pop    %ebp
  800a8b:	c3                   	ret    

00800a8c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800a8c:	55                   	push   %ebp
  800a8d:	89 e5                	mov    %esp,%ebp
  800a8f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a92:	8b 45 10             	mov    0x10(%ebp),%eax
  800a95:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a99:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a9c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800aa0:	8b 45 08             	mov    0x8(%ebp),%eax
  800aa3:	89 04 24             	mov    %eax,(%esp)
  800aa6:	e8 68 ff ff ff       	call   800a13 <memmove>
}
  800aab:	c9                   	leave  
  800aac:	c3                   	ret    

00800aad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800aad:	55                   	push   %ebp
  800aae:	89 e5                	mov    %esp,%ebp
  800ab0:	57                   	push   %edi
  800ab1:	56                   	push   %esi
  800ab2:	53                   	push   %ebx
  800ab3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800ab6:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ab9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800abc:	8d 78 ff             	lea    -0x1(%eax),%edi
  800abf:	85 c0                	test   %eax,%eax
  800ac1:	74 36                	je     800af9 <memcmp+0x4c>
		if (*s1 != *s2)
  800ac3:	0f b6 03             	movzbl (%ebx),%eax
  800ac6:	0f b6 0e             	movzbl (%esi),%ecx
  800ac9:	38 c8                	cmp    %cl,%al
  800acb:	75 17                	jne    800ae4 <memcmp+0x37>
  800acd:	ba 00 00 00 00       	mov    $0x0,%edx
  800ad2:	eb 1a                	jmp    800aee <memcmp+0x41>
  800ad4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800ad9:	83 c2 01             	add    $0x1,%edx
  800adc:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800ae0:	38 c8                	cmp    %cl,%al
  800ae2:	74 0a                	je     800aee <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800ae4:	0f b6 c0             	movzbl %al,%eax
  800ae7:	0f b6 c9             	movzbl %cl,%ecx
  800aea:	29 c8                	sub    %ecx,%eax
  800aec:	eb 10                	jmp    800afe <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800aee:	39 fa                	cmp    %edi,%edx
  800af0:	75 e2                	jne    800ad4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800af2:	b8 00 00 00 00       	mov    $0x0,%eax
  800af7:	eb 05                	jmp    800afe <memcmp+0x51>
  800af9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800afe:	5b                   	pop    %ebx
  800aff:	5e                   	pop    %esi
  800b00:	5f                   	pop    %edi
  800b01:	5d                   	pop    %ebp
  800b02:	c3                   	ret    

00800b03 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b03:	55                   	push   %ebp
  800b04:	89 e5                	mov    %esp,%ebp
  800b06:	53                   	push   %ebx
  800b07:	8b 45 08             	mov    0x8(%ebp),%eax
  800b0a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800b0d:	89 c2                	mov    %eax,%edx
  800b0f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b12:	39 d0                	cmp    %edx,%eax
  800b14:	73 13                	jae    800b29 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b16:	89 d9                	mov    %ebx,%ecx
  800b18:	38 18                	cmp    %bl,(%eax)
  800b1a:	75 06                	jne    800b22 <memfind+0x1f>
  800b1c:	eb 0b                	jmp    800b29 <memfind+0x26>
  800b1e:	38 08                	cmp    %cl,(%eax)
  800b20:	74 07                	je     800b29 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b22:	83 c0 01             	add    $0x1,%eax
  800b25:	39 d0                	cmp    %edx,%eax
  800b27:	75 f5                	jne    800b1e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b29:	5b                   	pop    %ebx
  800b2a:	5d                   	pop    %ebp
  800b2b:	c3                   	ret    

00800b2c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b2c:	55                   	push   %ebp
  800b2d:	89 e5                	mov    %esp,%ebp
  800b2f:	57                   	push   %edi
  800b30:	56                   	push   %esi
  800b31:	53                   	push   %ebx
  800b32:	83 ec 04             	sub    $0x4,%esp
  800b35:	8b 55 08             	mov    0x8(%ebp),%edx
  800b38:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b3b:	0f b6 02             	movzbl (%edx),%eax
  800b3e:	3c 09                	cmp    $0x9,%al
  800b40:	74 04                	je     800b46 <strtol+0x1a>
  800b42:	3c 20                	cmp    $0x20,%al
  800b44:	75 0e                	jne    800b54 <strtol+0x28>
		s++;
  800b46:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b49:	0f b6 02             	movzbl (%edx),%eax
  800b4c:	3c 09                	cmp    $0x9,%al
  800b4e:	74 f6                	je     800b46 <strtol+0x1a>
  800b50:	3c 20                	cmp    $0x20,%al
  800b52:	74 f2                	je     800b46 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b54:	3c 2b                	cmp    $0x2b,%al
  800b56:	75 0a                	jne    800b62 <strtol+0x36>
		s++;
  800b58:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b5b:	bf 00 00 00 00       	mov    $0x0,%edi
  800b60:	eb 10                	jmp    800b72 <strtol+0x46>
  800b62:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b67:	3c 2d                	cmp    $0x2d,%al
  800b69:	75 07                	jne    800b72 <strtol+0x46>
		s++, neg = 1;
  800b6b:	83 c2 01             	add    $0x1,%edx
  800b6e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b72:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b78:	75 15                	jne    800b8f <strtol+0x63>
  800b7a:	80 3a 30             	cmpb   $0x30,(%edx)
  800b7d:	75 10                	jne    800b8f <strtol+0x63>
  800b7f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b83:	75 0a                	jne    800b8f <strtol+0x63>
		s += 2, base = 16;
  800b85:	83 c2 02             	add    $0x2,%edx
  800b88:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b8d:	eb 10                	jmp    800b9f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800b8f:	85 db                	test   %ebx,%ebx
  800b91:	75 0c                	jne    800b9f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b93:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b95:	80 3a 30             	cmpb   $0x30,(%edx)
  800b98:	75 05                	jne    800b9f <strtol+0x73>
		s++, base = 8;
  800b9a:	83 c2 01             	add    $0x1,%edx
  800b9d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800b9f:	b8 00 00 00 00       	mov    $0x0,%eax
  800ba4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800ba7:	0f b6 0a             	movzbl (%edx),%ecx
  800baa:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800bad:	89 f3                	mov    %esi,%ebx
  800baf:	80 fb 09             	cmp    $0x9,%bl
  800bb2:	77 08                	ja     800bbc <strtol+0x90>
			dig = *s - '0';
  800bb4:	0f be c9             	movsbl %cl,%ecx
  800bb7:	83 e9 30             	sub    $0x30,%ecx
  800bba:	eb 22                	jmp    800bde <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800bbc:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800bbf:	89 f3                	mov    %esi,%ebx
  800bc1:	80 fb 19             	cmp    $0x19,%bl
  800bc4:	77 08                	ja     800bce <strtol+0xa2>
			dig = *s - 'a' + 10;
  800bc6:	0f be c9             	movsbl %cl,%ecx
  800bc9:	83 e9 57             	sub    $0x57,%ecx
  800bcc:	eb 10                	jmp    800bde <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800bce:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800bd1:	89 f3                	mov    %esi,%ebx
  800bd3:	80 fb 19             	cmp    $0x19,%bl
  800bd6:	77 16                	ja     800bee <strtol+0xc2>
			dig = *s - 'A' + 10;
  800bd8:	0f be c9             	movsbl %cl,%ecx
  800bdb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800bde:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800be1:	7d 0f                	jge    800bf2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800be3:	83 c2 01             	add    $0x1,%edx
  800be6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800bea:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800bec:	eb b9                	jmp    800ba7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800bee:	89 c1                	mov    %eax,%ecx
  800bf0:	eb 02                	jmp    800bf4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800bf2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800bf4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bf8:	74 05                	je     800bff <strtol+0xd3>
		*endptr = (char *) s;
  800bfa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800bfd:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800bff:	89 ca                	mov    %ecx,%edx
  800c01:	f7 da                	neg    %edx
  800c03:	85 ff                	test   %edi,%edi
  800c05:	0f 45 c2             	cmovne %edx,%eax
}
  800c08:	83 c4 04             	add    $0x4,%esp
  800c0b:	5b                   	pop    %ebx
  800c0c:	5e                   	pop    %esi
  800c0d:	5f                   	pop    %edi
  800c0e:	5d                   	pop    %ebp
  800c0f:	c3                   	ret    

00800c10 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800c10:	55                   	push   %ebp
  800c11:	89 e5                	mov    %esp,%ebp
  800c13:	83 ec 0c             	sub    $0xc,%esp
  800c16:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c19:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c1c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c1f:	b8 00 00 00 00       	mov    $0x0,%eax
  800c24:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c27:	8b 55 08             	mov    0x8(%ebp),%edx
  800c2a:	89 c3                	mov    %eax,%ebx
  800c2c:	89 c7                	mov    %eax,%edi
  800c2e:	89 c6                	mov    %eax,%esi
  800c30:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c32:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c35:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c38:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c3b:	89 ec                	mov    %ebp,%esp
  800c3d:	5d                   	pop    %ebp
  800c3e:	c3                   	ret    

00800c3f <sys_cgetc>:

int
sys_cgetc(void)
{
  800c3f:	55                   	push   %ebp
  800c40:	89 e5                	mov    %esp,%ebp
  800c42:	83 ec 0c             	sub    $0xc,%esp
  800c45:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c48:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c4b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c4e:	ba 00 00 00 00       	mov    $0x0,%edx
  800c53:	b8 01 00 00 00       	mov    $0x1,%eax
  800c58:	89 d1                	mov    %edx,%ecx
  800c5a:	89 d3                	mov    %edx,%ebx
  800c5c:	89 d7                	mov    %edx,%edi
  800c5e:	89 d6                	mov    %edx,%esi
  800c60:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c62:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c65:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c68:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c6b:	89 ec                	mov    %ebp,%esp
  800c6d:	5d                   	pop    %ebp
  800c6e:	c3                   	ret    

00800c6f <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c6f:	55                   	push   %ebp
  800c70:	89 e5                	mov    %esp,%ebp
  800c72:	83 ec 38             	sub    $0x38,%esp
  800c75:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c78:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c7b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c7e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c83:	b8 03 00 00 00       	mov    $0x3,%eax
  800c88:	8b 55 08             	mov    0x8(%ebp),%edx
  800c8b:	89 cb                	mov    %ecx,%ebx
  800c8d:	89 cf                	mov    %ecx,%edi
  800c8f:	89 ce                	mov    %ecx,%esi
  800c91:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c93:	85 c0                	test   %eax,%eax
  800c95:	7e 28                	jle    800cbf <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c97:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c9b:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800ca2:	00 
  800ca3:	c7 44 24 08 6c 12 80 	movl   $0x80126c,0x8(%esp)
  800caa:	00 
  800cab:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800cb2:	00 
  800cb3:	c7 04 24 89 12 80 00 	movl   $0x801289,(%esp)
  800cba:	e8 3d 00 00 00       	call   800cfc <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800cbf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800cc2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cc5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cc8:	89 ec                	mov    %ebp,%esp
  800cca:	5d                   	pop    %ebp
  800ccb:	c3                   	ret    

00800ccc <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800ccc:	55                   	push   %ebp
  800ccd:	89 e5                	mov    %esp,%ebp
  800ccf:	83 ec 0c             	sub    $0xc,%esp
  800cd2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800cd5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800cd8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cdb:	ba 00 00 00 00       	mov    $0x0,%edx
  800ce0:	b8 02 00 00 00       	mov    $0x2,%eax
  800ce5:	89 d1                	mov    %edx,%ecx
  800ce7:	89 d3                	mov    %edx,%ebx
  800ce9:	89 d7                	mov    %edx,%edi
  800ceb:	89 d6                	mov    %edx,%esi
  800ced:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800cef:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800cf2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cf5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cf8:	89 ec                	mov    %ebp,%esp
  800cfa:	5d                   	pop    %ebp
  800cfb:	c3                   	ret    

00800cfc <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800cfc:	55                   	push   %ebp
  800cfd:	89 e5                	mov    %esp,%ebp
  800cff:	56                   	push   %esi
  800d00:	53                   	push   %ebx
  800d01:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800d04:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800d07:	a1 0c 20 80 00       	mov    0x80200c,%eax
  800d0c:	85 c0                	test   %eax,%eax
  800d0e:	74 10                	je     800d20 <_panic+0x24>
		cprintf("%s: ", argv0);
  800d10:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d14:	c7 04 24 97 12 80 00 	movl   $0x801297,(%esp)
  800d1b:	e8 73 f4 ff ff       	call   800193 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800d20:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800d26:	e8 a1 ff ff ff       	call   800ccc <sys_getenvid>
  800d2b:	8b 55 0c             	mov    0xc(%ebp),%edx
  800d2e:	89 54 24 10          	mov    %edx,0x10(%esp)
  800d32:	8b 55 08             	mov    0x8(%ebp),%edx
  800d35:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800d39:	89 74 24 08          	mov    %esi,0x8(%esp)
  800d3d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d41:	c7 04 24 9c 12 80 00 	movl   $0x80129c,(%esp)
  800d48:	e8 46 f4 ff ff       	call   800193 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800d4d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800d51:	8b 45 10             	mov    0x10(%ebp),%eax
  800d54:	89 04 24             	mov    %eax,(%esp)
  800d57:	e8 d6 f3 ff ff       	call   800132 <vcprintf>
	cprintf("\n");
  800d5c:	c7 04 24 5c 10 80 00 	movl   $0x80105c,(%esp)
  800d63:	e8 2b f4 ff ff       	call   800193 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800d68:	cc                   	int3   
  800d69:	eb fd                	jmp    800d68 <_panic+0x6c>
  800d6b:	66 90                	xchg   %ax,%ax
  800d6d:	66 90                	xchg   %ax,%ax
  800d6f:	90                   	nop

00800d70 <__udivdi3>:
  800d70:	83 ec 1c             	sub    $0x1c,%esp
  800d73:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800d77:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d7b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d7f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d83:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800d87:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800d8b:	85 c0                	test   %eax,%eax
  800d8d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d91:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d95:	89 ea                	mov    %ebp,%edx
  800d97:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800d9b:	75 33                	jne    800dd0 <__udivdi3+0x60>
  800d9d:	39 e9                	cmp    %ebp,%ecx
  800d9f:	77 6f                	ja     800e10 <__udivdi3+0xa0>
  800da1:	85 c9                	test   %ecx,%ecx
  800da3:	89 ce                	mov    %ecx,%esi
  800da5:	75 0b                	jne    800db2 <__udivdi3+0x42>
  800da7:	b8 01 00 00 00       	mov    $0x1,%eax
  800dac:	31 d2                	xor    %edx,%edx
  800dae:	f7 f1                	div    %ecx
  800db0:	89 c6                	mov    %eax,%esi
  800db2:	31 d2                	xor    %edx,%edx
  800db4:	89 e8                	mov    %ebp,%eax
  800db6:	f7 f6                	div    %esi
  800db8:	89 c5                	mov    %eax,%ebp
  800dba:	89 f8                	mov    %edi,%eax
  800dbc:	f7 f6                	div    %esi
  800dbe:	89 ea                	mov    %ebp,%edx
  800dc0:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dc4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dc8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dcc:	83 c4 1c             	add    $0x1c,%esp
  800dcf:	c3                   	ret    
  800dd0:	39 e8                	cmp    %ebp,%eax
  800dd2:	77 24                	ja     800df8 <__udivdi3+0x88>
  800dd4:	0f bd c8             	bsr    %eax,%ecx
  800dd7:	83 f1 1f             	xor    $0x1f,%ecx
  800dda:	89 0c 24             	mov    %ecx,(%esp)
  800ddd:	75 49                	jne    800e28 <__udivdi3+0xb8>
  800ddf:	8b 74 24 08          	mov    0x8(%esp),%esi
  800de3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800de7:	0f 86 ab 00 00 00    	jbe    800e98 <__udivdi3+0x128>
  800ded:	39 e8                	cmp    %ebp,%eax
  800def:	0f 82 a3 00 00 00    	jb     800e98 <__udivdi3+0x128>
  800df5:	8d 76 00             	lea    0x0(%esi),%esi
  800df8:	31 d2                	xor    %edx,%edx
  800dfa:	31 c0                	xor    %eax,%eax
  800dfc:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e00:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e04:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e08:	83 c4 1c             	add    $0x1c,%esp
  800e0b:	c3                   	ret    
  800e0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e10:	89 f8                	mov    %edi,%eax
  800e12:	f7 f1                	div    %ecx
  800e14:	31 d2                	xor    %edx,%edx
  800e16:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e1a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e1e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e22:	83 c4 1c             	add    $0x1c,%esp
  800e25:	c3                   	ret    
  800e26:	66 90                	xchg   %ax,%ax
  800e28:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e2c:	89 c6                	mov    %eax,%esi
  800e2e:	b8 20 00 00 00       	mov    $0x20,%eax
  800e33:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800e37:	2b 04 24             	sub    (%esp),%eax
  800e3a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800e3e:	d3 e6                	shl    %cl,%esi
  800e40:	89 c1                	mov    %eax,%ecx
  800e42:	d3 ed                	shr    %cl,%ebp
  800e44:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e48:	09 f5                	or     %esi,%ebp
  800e4a:	8b 74 24 04          	mov    0x4(%esp),%esi
  800e4e:	d3 e6                	shl    %cl,%esi
  800e50:	89 c1                	mov    %eax,%ecx
  800e52:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e56:	89 d6                	mov    %edx,%esi
  800e58:	d3 ee                	shr    %cl,%esi
  800e5a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e5e:	d3 e2                	shl    %cl,%edx
  800e60:	89 c1                	mov    %eax,%ecx
  800e62:	d3 ef                	shr    %cl,%edi
  800e64:	09 d7                	or     %edx,%edi
  800e66:	89 f2                	mov    %esi,%edx
  800e68:	89 f8                	mov    %edi,%eax
  800e6a:	f7 f5                	div    %ebp
  800e6c:	89 d6                	mov    %edx,%esi
  800e6e:	89 c7                	mov    %eax,%edi
  800e70:	f7 64 24 04          	mull   0x4(%esp)
  800e74:	39 d6                	cmp    %edx,%esi
  800e76:	72 30                	jb     800ea8 <__udivdi3+0x138>
  800e78:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800e7c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e80:	d3 e5                	shl    %cl,%ebp
  800e82:	39 c5                	cmp    %eax,%ebp
  800e84:	73 04                	jae    800e8a <__udivdi3+0x11a>
  800e86:	39 d6                	cmp    %edx,%esi
  800e88:	74 1e                	je     800ea8 <__udivdi3+0x138>
  800e8a:	89 f8                	mov    %edi,%eax
  800e8c:	31 d2                	xor    %edx,%edx
  800e8e:	e9 69 ff ff ff       	jmp    800dfc <__udivdi3+0x8c>
  800e93:	90                   	nop
  800e94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e98:	31 d2                	xor    %edx,%edx
  800e9a:	b8 01 00 00 00       	mov    $0x1,%eax
  800e9f:	e9 58 ff ff ff       	jmp    800dfc <__udivdi3+0x8c>
  800ea4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ea8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800eab:	31 d2                	xor    %edx,%edx
  800ead:	8b 74 24 10          	mov    0x10(%esp),%esi
  800eb1:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800eb5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800eb9:	83 c4 1c             	add    $0x1c,%esp
  800ebc:	c3                   	ret    
  800ebd:	66 90                	xchg   %ax,%ax
  800ebf:	90                   	nop

00800ec0 <__umoddi3>:
  800ec0:	83 ec 2c             	sub    $0x2c,%esp
  800ec3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800ec7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800ecb:	89 74 24 20          	mov    %esi,0x20(%esp)
  800ecf:	8b 74 24 38          	mov    0x38(%esp),%esi
  800ed3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800ed7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800edb:	85 c0                	test   %eax,%eax
  800edd:	89 c2                	mov    %eax,%edx
  800edf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800ee3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800ee7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800eeb:	89 74 24 10          	mov    %esi,0x10(%esp)
  800eef:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800ef3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ef7:	75 1f                	jne    800f18 <__umoddi3+0x58>
  800ef9:	39 fe                	cmp    %edi,%esi
  800efb:	76 63                	jbe    800f60 <__umoddi3+0xa0>
  800efd:	89 c8                	mov    %ecx,%eax
  800eff:	89 fa                	mov    %edi,%edx
  800f01:	f7 f6                	div    %esi
  800f03:	89 d0                	mov    %edx,%eax
  800f05:	31 d2                	xor    %edx,%edx
  800f07:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f0b:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f0f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f13:	83 c4 2c             	add    $0x2c,%esp
  800f16:	c3                   	ret    
  800f17:	90                   	nop
  800f18:	39 f8                	cmp    %edi,%eax
  800f1a:	77 64                	ja     800f80 <__umoddi3+0xc0>
  800f1c:	0f bd e8             	bsr    %eax,%ebp
  800f1f:	83 f5 1f             	xor    $0x1f,%ebp
  800f22:	75 74                	jne    800f98 <__umoddi3+0xd8>
  800f24:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800f28:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800f2c:	0f 87 0e 01 00 00    	ja     801040 <__umoddi3+0x180>
  800f32:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800f36:	29 f1                	sub    %esi,%ecx
  800f38:	19 c7                	sbb    %eax,%edi
  800f3a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800f3e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800f42:	8b 44 24 14          	mov    0x14(%esp),%eax
  800f46:	8b 54 24 18          	mov    0x18(%esp),%edx
  800f4a:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f4e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f52:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f56:	83 c4 2c             	add    $0x2c,%esp
  800f59:	c3                   	ret    
  800f5a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f60:	85 f6                	test   %esi,%esi
  800f62:	89 f5                	mov    %esi,%ebp
  800f64:	75 0b                	jne    800f71 <__umoddi3+0xb1>
  800f66:	b8 01 00 00 00       	mov    $0x1,%eax
  800f6b:	31 d2                	xor    %edx,%edx
  800f6d:	f7 f6                	div    %esi
  800f6f:	89 c5                	mov    %eax,%ebp
  800f71:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f75:	31 d2                	xor    %edx,%edx
  800f77:	f7 f5                	div    %ebp
  800f79:	89 c8                	mov    %ecx,%eax
  800f7b:	f7 f5                	div    %ebp
  800f7d:	eb 84                	jmp    800f03 <__umoddi3+0x43>
  800f7f:	90                   	nop
  800f80:	89 c8                	mov    %ecx,%eax
  800f82:	89 fa                	mov    %edi,%edx
  800f84:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f88:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f8c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f90:	83 c4 2c             	add    $0x2c,%esp
  800f93:	c3                   	ret    
  800f94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f98:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f9c:	be 20 00 00 00       	mov    $0x20,%esi
  800fa1:	89 e9                	mov    %ebp,%ecx
  800fa3:	29 ee                	sub    %ebp,%esi
  800fa5:	d3 e2                	shl    %cl,%edx
  800fa7:	89 f1                	mov    %esi,%ecx
  800fa9:	d3 e8                	shr    %cl,%eax
  800fab:	89 e9                	mov    %ebp,%ecx
  800fad:	09 d0                	or     %edx,%eax
  800faf:	89 fa                	mov    %edi,%edx
  800fb1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800fb5:	8b 44 24 10          	mov    0x10(%esp),%eax
  800fb9:	d3 e0                	shl    %cl,%eax
  800fbb:	89 f1                	mov    %esi,%ecx
  800fbd:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fc1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800fc5:	d3 ea                	shr    %cl,%edx
  800fc7:	89 e9                	mov    %ebp,%ecx
  800fc9:	d3 e7                	shl    %cl,%edi
  800fcb:	89 f1                	mov    %esi,%ecx
  800fcd:	d3 e8                	shr    %cl,%eax
  800fcf:	89 e9                	mov    %ebp,%ecx
  800fd1:	09 f8                	or     %edi,%eax
  800fd3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800fd7:	f7 74 24 0c          	divl   0xc(%esp)
  800fdb:	d3 e7                	shl    %cl,%edi
  800fdd:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800fe1:	89 d7                	mov    %edx,%edi
  800fe3:	f7 64 24 10          	mull   0x10(%esp)
  800fe7:	39 d7                	cmp    %edx,%edi
  800fe9:	89 c1                	mov    %eax,%ecx
  800feb:	89 54 24 14          	mov    %edx,0x14(%esp)
  800fef:	72 3b                	jb     80102c <__umoddi3+0x16c>
  800ff1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800ff5:	72 31                	jb     801028 <__umoddi3+0x168>
  800ff7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800ffb:	29 c8                	sub    %ecx,%eax
  800ffd:	19 d7                	sbb    %edx,%edi
  800fff:	89 e9                	mov    %ebp,%ecx
  801001:	89 fa                	mov    %edi,%edx
  801003:	d3 e8                	shr    %cl,%eax
  801005:	89 f1                	mov    %esi,%ecx
  801007:	d3 e2                	shl    %cl,%edx
  801009:	89 e9                	mov    %ebp,%ecx
  80100b:	09 d0                	or     %edx,%eax
  80100d:	89 fa                	mov    %edi,%edx
  80100f:	d3 ea                	shr    %cl,%edx
  801011:	8b 74 24 20          	mov    0x20(%esp),%esi
  801015:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801019:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  80101d:	83 c4 2c             	add    $0x2c,%esp
  801020:	c3                   	ret    
  801021:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801028:	39 d7                	cmp    %edx,%edi
  80102a:	75 cb                	jne    800ff7 <__umoddi3+0x137>
  80102c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801030:	89 c1                	mov    %eax,%ecx
  801032:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801036:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80103a:	eb bb                	jmp    800ff7 <__umoddi3+0x137>
  80103c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801040:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801044:	0f 82 e8 fe ff ff    	jb     800f32 <__umoddi3+0x72>
  80104a:	e9 f3 fe ff ff       	jmp    800f42 <__umoddi3+0x82>

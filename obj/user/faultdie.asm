
obj/user/faultdie：     文件格式 elf32-i386


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
  80002c:	e8 63 00 00 00       	call   800094 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	66 90                	xchg   %ax,%ax
  800035:	66 90                	xchg   %ax,%ax
  800037:	66 90                	xchg   %ax,%ax
  800039:	66 90                	xchg   %ax,%ax
  80003b:	66 90                	xchg   %ax,%ax
  80003d:	66 90                	xchg   %ax,%ax
  80003f:	90                   	nop

00800040 <handler>:

#include <inc/lib.h>

void
handler(struct UTrapframe *utf)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	83 ec 18             	sub    $0x18,%esp
  800046:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void*)utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	cprintf("i faulted at va %x, err %x\n", addr, err & 7);
  800049:	8b 50 04             	mov    0x4(%eax),%edx
  80004c:	83 e2 07             	and    $0x7,%edx
  80004f:	89 54 24 08          	mov    %edx,0x8(%esp)
  800053:	8b 00                	mov    (%eax),%eax
  800055:	89 44 24 04          	mov    %eax,0x4(%esp)
  800059:	c7 04 24 c0 13 80 00 	movl   $0x8013c0,(%esp)
  800060:	e8 5a 01 00 00       	call   8001bf <cprintf>
	sys_env_destroy(sys_getenvid());
  800065:	e8 92 0c 00 00       	call   800cfc <sys_getenvid>
  80006a:	89 04 24             	mov    %eax,(%esp)
  80006d:	e8 2d 0c 00 00       	call   800c9f <sys_env_destroy>
}
  800072:	c9                   	leave  
  800073:	c3                   	ret    

00800074 <umain>:

void
umain(int argc, char **argv)
{
  800074:	55                   	push   %ebp
  800075:	89 e5                	mov    %esp,%ebp
  800077:	83 ec 18             	sub    $0x18,%esp
	set_pgfault_handler(handler);
  80007a:	c7 04 24 40 00 80 00 	movl   $0x800040,(%esp)
  800081:	e8 3e 0f 00 00       	call   800fc4 <set_pgfault_handler>
	*(int*)0xDeadBeef = 0;
  800086:	c7 05 ef be ad de 00 	movl   $0x0,0xdeadbeef
  80008d:	00 00 00 
}
  800090:	c9                   	leave  
  800091:	c3                   	ret    
  800092:	66 90                	xchg   %ax,%ax

00800094 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800094:	55                   	push   %ebp
  800095:	89 e5                	mov    %esp,%ebp
  800097:	57                   	push   %edi
  800098:	56                   	push   %esi
  800099:	53                   	push   %ebx
  80009a:	83 ec 1c             	sub    $0x1c,%esp
  80009d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000a0:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  8000a3:	e8 54 0c 00 00       	call   800cfc <sys_getenvid>
	thisenv = envs;
  8000a8:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  8000af:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  8000b2:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  8000b8:	39 c2                	cmp    %eax,%edx
  8000ba:	74 25                	je     8000e1 <libmain+0x4d>
  8000bc:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  8000c1:	eb 12                	jmp    8000d5 <libmain+0x41>
  8000c3:	8b 4a 48             	mov    0x48(%edx),%ecx
  8000c6:	83 c2 7c             	add    $0x7c,%edx
  8000c9:	39 c1                	cmp    %eax,%ecx
  8000cb:	75 08                	jne    8000d5 <libmain+0x41>
  8000cd:	89 3d 04 20 80 00    	mov    %edi,0x802004
  8000d3:	eb 0c                	jmp    8000e1 <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  8000d5:	89 d7                	mov    %edx,%edi
  8000d7:	85 d2                	test   %edx,%edx
  8000d9:	75 e8                	jne    8000c3 <libmain+0x2f>
  8000db:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000e1:	85 db                	test   %ebx,%ebx
  8000e3:	7e 07                	jle    8000ec <libmain+0x58>
		binaryname = argv[0];
  8000e5:	8b 06                	mov    (%esi),%eax
  8000e7:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000ec:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000f0:	89 1c 24             	mov    %ebx,(%esp)
  8000f3:	e8 7c ff ff ff       	call   800074 <umain>

	// exit gracefully
	exit();
  8000f8:	e8 0b 00 00 00       	call   800108 <exit>
}
  8000fd:	83 c4 1c             	add    $0x1c,%esp
  800100:	5b                   	pop    %ebx
  800101:	5e                   	pop    %esi
  800102:	5f                   	pop    %edi
  800103:	5d                   	pop    %ebp
  800104:	c3                   	ret    
  800105:	66 90                	xchg   %ax,%ax
  800107:	90                   	nop

00800108 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800108:	55                   	push   %ebp
  800109:	89 e5                	mov    %esp,%ebp
  80010b:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80010e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800115:	e8 85 0b 00 00       	call   800c9f <sys_env_destroy>
}
  80011a:	c9                   	leave  
  80011b:	c3                   	ret    

0080011c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80011c:	55                   	push   %ebp
  80011d:	89 e5                	mov    %esp,%ebp
  80011f:	53                   	push   %ebx
  800120:	83 ec 14             	sub    $0x14,%esp
  800123:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800126:	8b 03                	mov    (%ebx),%eax
  800128:	8b 55 08             	mov    0x8(%ebp),%edx
  80012b:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  80012f:	83 c0 01             	add    $0x1,%eax
  800132:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800134:	3d ff 00 00 00       	cmp    $0xff,%eax
  800139:	75 19                	jne    800154 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80013b:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800142:	00 
  800143:	8d 43 08             	lea    0x8(%ebx),%eax
  800146:	89 04 24             	mov    %eax,(%esp)
  800149:	e8 f2 0a 00 00       	call   800c40 <sys_cputs>
		b->idx = 0;
  80014e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800154:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800158:	83 c4 14             	add    $0x14,%esp
  80015b:	5b                   	pop    %ebx
  80015c:	5d                   	pop    %ebp
  80015d:	c3                   	ret    

0080015e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80015e:	55                   	push   %ebp
  80015f:	89 e5                	mov    %esp,%ebp
  800161:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800167:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80016e:	00 00 00 
	b.cnt = 0;
  800171:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800178:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80017b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80017e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800182:	8b 45 08             	mov    0x8(%ebp),%eax
  800185:	89 44 24 08          	mov    %eax,0x8(%esp)
  800189:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80018f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800193:	c7 04 24 1c 01 80 00 	movl   $0x80011c,(%esp)
  80019a:	e8 b3 01 00 00       	call   800352 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80019f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8001a5:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001a9:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001af:	89 04 24             	mov    %eax,(%esp)
  8001b2:	e8 89 0a 00 00       	call   800c40 <sys_cputs>

	return b.cnt;
}
  8001b7:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001bd:	c9                   	leave  
  8001be:	c3                   	ret    

008001bf <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001bf:	55                   	push   %ebp
  8001c0:	89 e5                	mov    %esp,%ebp
  8001c2:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001c5:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8001c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001cc:	8b 45 08             	mov    0x8(%ebp),%eax
  8001cf:	89 04 24             	mov    %eax,(%esp)
  8001d2:	e8 87 ff ff ff       	call   80015e <vcprintf>
	va_end(ap);

	return cnt;
}
  8001d7:	c9                   	leave  
  8001d8:	c3                   	ret    
  8001d9:	66 90                	xchg   %ax,%ax
  8001db:	66 90                	xchg   %ax,%ax
  8001dd:	66 90                	xchg   %ax,%ax
  8001df:	90                   	nop

008001e0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001e0:	55                   	push   %ebp
  8001e1:	89 e5                	mov    %esp,%ebp
  8001e3:	57                   	push   %edi
  8001e4:	56                   	push   %esi
  8001e5:	53                   	push   %ebx
  8001e6:	83 ec 4c             	sub    $0x4c,%esp
  8001e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8001ec:	89 d7                	mov    %edx,%edi
  8001ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8001f1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8001f4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8001f7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001fa:	b8 00 00 00 00       	mov    $0x0,%eax
  8001ff:	39 d8                	cmp    %ebx,%eax
  800201:	72 17                	jb     80021a <printnum+0x3a>
  800203:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800206:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800209:	76 0f                	jbe    80021a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80020b:	8b 75 14             	mov    0x14(%ebp),%esi
  80020e:	83 ee 01             	sub    $0x1,%esi
  800211:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800214:	85 f6                	test   %esi,%esi
  800216:	7f 63                	jg     80027b <printnum+0x9b>
  800218:	eb 75                	jmp    80028f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80021a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80021d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800221:	8b 45 14             	mov    0x14(%ebp),%eax
  800224:	83 e8 01             	sub    $0x1,%eax
  800227:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80022b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80022e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800232:	8b 44 24 08          	mov    0x8(%esp),%eax
  800236:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80023a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80023d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800240:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800247:	00 
  800248:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80024b:	89 1c 24             	mov    %ebx,(%esp)
  80024e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800251:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800255:	e8 76 0e 00 00       	call   8010d0 <__udivdi3>
  80025a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80025d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800260:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800264:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800268:	89 04 24             	mov    %eax,(%esp)
  80026b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80026f:	89 fa                	mov    %edi,%edx
  800271:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800274:	e8 67 ff ff ff       	call   8001e0 <printnum>
  800279:	eb 14                	jmp    80028f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80027b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80027f:	8b 45 18             	mov    0x18(%ebp),%eax
  800282:	89 04 24             	mov    %eax,(%esp)
  800285:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800287:	83 ee 01             	sub    $0x1,%esi
  80028a:	75 ef                	jne    80027b <printnum+0x9b>
  80028c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80028f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800293:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800297:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80029a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80029e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8002a5:	00 
  8002a6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002a9:	89 1c 24             	mov    %ebx,(%esp)
  8002ac:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8002af:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002b3:	e8 68 0f 00 00       	call   801220 <__umoddi3>
  8002b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002bc:	0f be 80 e6 13 80 00 	movsbl 0x8013e6(%eax),%eax
  8002c3:	89 04 24             	mov    %eax,(%esp)
  8002c6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002c9:	ff d0                	call   *%eax
}
  8002cb:	83 c4 4c             	add    $0x4c,%esp
  8002ce:	5b                   	pop    %ebx
  8002cf:	5e                   	pop    %esi
  8002d0:	5f                   	pop    %edi
  8002d1:	5d                   	pop    %ebp
  8002d2:	c3                   	ret    

008002d3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002d3:	55                   	push   %ebp
  8002d4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002d6:	83 fa 01             	cmp    $0x1,%edx
  8002d9:	7e 0e                	jle    8002e9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002db:	8b 10                	mov    (%eax),%edx
  8002dd:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002e0:	89 08                	mov    %ecx,(%eax)
  8002e2:	8b 02                	mov    (%edx),%eax
  8002e4:	8b 52 04             	mov    0x4(%edx),%edx
  8002e7:	eb 22                	jmp    80030b <getuint+0x38>
	else if (lflag)
  8002e9:	85 d2                	test   %edx,%edx
  8002eb:	74 10                	je     8002fd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002ed:	8b 10                	mov    (%eax),%edx
  8002ef:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002f2:	89 08                	mov    %ecx,(%eax)
  8002f4:	8b 02                	mov    (%edx),%eax
  8002f6:	ba 00 00 00 00       	mov    $0x0,%edx
  8002fb:	eb 0e                	jmp    80030b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002fd:	8b 10                	mov    (%eax),%edx
  8002ff:	8d 4a 04             	lea    0x4(%edx),%ecx
  800302:	89 08                	mov    %ecx,(%eax)
  800304:	8b 02                	mov    (%edx),%eax
  800306:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80030b:	5d                   	pop    %ebp
  80030c:	c3                   	ret    

0080030d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80030d:	55                   	push   %ebp
  80030e:	89 e5                	mov    %esp,%ebp
  800310:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800313:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800317:	8b 10                	mov    (%eax),%edx
  800319:	3b 50 04             	cmp    0x4(%eax),%edx
  80031c:	73 0a                	jae    800328 <sprintputch+0x1b>
		*b->buf++ = ch;
  80031e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800321:	88 0a                	mov    %cl,(%edx)
  800323:	83 c2 01             	add    $0x1,%edx
  800326:	89 10                	mov    %edx,(%eax)
}
  800328:	5d                   	pop    %ebp
  800329:	c3                   	ret    

0080032a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80032a:	55                   	push   %ebp
  80032b:	89 e5                	mov    %esp,%ebp
  80032d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800330:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800333:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800337:	8b 45 10             	mov    0x10(%ebp),%eax
  80033a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80033e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800341:	89 44 24 04          	mov    %eax,0x4(%esp)
  800345:	8b 45 08             	mov    0x8(%ebp),%eax
  800348:	89 04 24             	mov    %eax,(%esp)
  80034b:	e8 02 00 00 00       	call   800352 <vprintfmt>
	va_end(ap);
}
  800350:	c9                   	leave  
  800351:	c3                   	ret    

00800352 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800352:	55                   	push   %ebp
  800353:	89 e5                	mov    %esp,%ebp
  800355:	57                   	push   %edi
  800356:	56                   	push   %esi
  800357:	53                   	push   %ebx
  800358:	83 ec 4c             	sub    $0x4c,%esp
  80035b:	8b 75 08             	mov    0x8(%ebp),%esi
  80035e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800361:	8b 7d 10             	mov    0x10(%ebp),%edi
  800364:	eb 11                	jmp    800377 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800366:	85 c0                	test   %eax,%eax
  800368:	0f 84 db 03 00 00    	je     800749 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80036e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800372:	89 04 24             	mov    %eax,(%esp)
  800375:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800377:	0f b6 07             	movzbl (%edi),%eax
  80037a:	83 c7 01             	add    $0x1,%edi
  80037d:	83 f8 25             	cmp    $0x25,%eax
  800380:	75 e4                	jne    800366 <vprintfmt+0x14>
  800382:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800386:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80038d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800394:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80039b:	ba 00 00 00 00       	mov    $0x0,%edx
  8003a0:	eb 2b                	jmp    8003cd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003a5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  8003a9:	eb 22                	jmp    8003cd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ab:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003ae:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  8003b2:	eb 19                	jmp    8003cd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  8003b7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003be:	eb 0d                	jmp    8003cd <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8003c0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8003c3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8003c6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003cd:	0f b6 0f             	movzbl (%edi),%ecx
  8003d0:	8d 47 01             	lea    0x1(%edi),%eax
  8003d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003d6:	0f b6 07             	movzbl (%edi),%eax
  8003d9:	83 e8 23             	sub    $0x23,%eax
  8003dc:	3c 55                	cmp    $0x55,%al
  8003de:	0f 87 40 03 00 00    	ja     800724 <vprintfmt+0x3d2>
  8003e4:	0f b6 c0             	movzbl %al,%eax
  8003e7:	ff 24 85 a0 14 80 00 	jmp    *0x8014a0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003ee:	83 e9 30             	sub    $0x30,%ecx
  8003f1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  8003f4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  8003f8:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8003fb:	83 f9 09             	cmp    $0x9,%ecx
  8003fe:	77 57                	ja     800457 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800400:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800403:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800406:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800409:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80040c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80040f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800413:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800416:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800419:	83 f9 09             	cmp    $0x9,%ecx
  80041c:	76 eb                	jbe    800409 <vprintfmt+0xb7>
  80041e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800421:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800424:	eb 34                	jmp    80045a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800426:	8b 45 14             	mov    0x14(%ebp),%eax
  800429:	8d 48 04             	lea    0x4(%eax),%ecx
  80042c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80042f:	8b 00                	mov    (%eax),%eax
  800431:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800434:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800437:	eb 21                	jmp    80045a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800439:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80043d:	0f 88 71 ff ff ff    	js     8003b4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800443:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800446:	eb 85                	jmp    8003cd <vprintfmt+0x7b>
  800448:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80044b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800452:	e9 76 ff ff ff       	jmp    8003cd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800457:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80045a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80045e:	0f 89 69 ff ff ff    	jns    8003cd <vprintfmt+0x7b>
  800464:	e9 57 ff ff ff       	jmp    8003c0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800469:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80046f:	e9 59 ff ff ff       	jmp    8003cd <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800474:	8b 45 14             	mov    0x14(%ebp),%eax
  800477:	8d 50 04             	lea    0x4(%eax),%edx
  80047a:	89 55 14             	mov    %edx,0x14(%ebp)
  80047d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800481:	8b 00                	mov    (%eax),%eax
  800483:	89 04 24             	mov    %eax,(%esp)
  800486:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800488:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80048b:	e9 e7 fe ff ff       	jmp    800377 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800490:	8b 45 14             	mov    0x14(%ebp),%eax
  800493:	8d 50 04             	lea    0x4(%eax),%edx
  800496:	89 55 14             	mov    %edx,0x14(%ebp)
  800499:	8b 00                	mov    (%eax),%eax
  80049b:	89 c2                	mov    %eax,%edx
  80049d:	c1 fa 1f             	sar    $0x1f,%edx
  8004a0:	31 d0                	xor    %edx,%eax
  8004a2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004a4:	83 f8 08             	cmp    $0x8,%eax
  8004a7:	7f 0b                	jg     8004b4 <vprintfmt+0x162>
  8004a9:	8b 14 85 00 16 80 00 	mov    0x801600(,%eax,4),%edx
  8004b0:	85 d2                	test   %edx,%edx
  8004b2:	75 20                	jne    8004d4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  8004b4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8004b8:	c7 44 24 08 fe 13 80 	movl   $0x8013fe,0x8(%esp)
  8004bf:	00 
  8004c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004c4:	89 34 24             	mov    %esi,(%esp)
  8004c7:	e8 5e fe ff ff       	call   80032a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004cc:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004cf:	e9 a3 fe ff ff       	jmp    800377 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8004d4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8004d8:	c7 44 24 08 07 14 80 	movl   $0x801407,0x8(%esp)
  8004df:	00 
  8004e0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004e4:	89 34 24             	mov    %esi,(%esp)
  8004e7:	e8 3e fe ff ff       	call   80032a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ec:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004ef:	e9 83 fe ff ff       	jmp    800377 <vprintfmt+0x25>
  8004f4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8004f7:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8004fa:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004fd:	8b 45 14             	mov    0x14(%ebp),%eax
  800500:	8d 50 04             	lea    0x4(%eax),%edx
  800503:	89 55 14             	mov    %edx,0x14(%ebp)
  800506:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800508:	85 ff                	test   %edi,%edi
  80050a:	b8 f7 13 80 00       	mov    $0x8013f7,%eax
  80050f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800512:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800516:	74 06                	je     80051e <vprintfmt+0x1cc>
  800518:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  80051c:	7f 16                	jg     800534 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80051e:	0f b6 17             	movzbl (%edi),%edx
  800521:	0f be c2             	movsbl %dl,%eax
  800524:	83 c7 01             	add    $0x1,%edi
  800527:	85 c0                	test   %eax,%eax
  800529:	0f 85 9f 00 00 00    	jne    8005ce <vprintfmt+0x27c>
  80052f:	e9 8b 00 00 00       	jmp    8005bf <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800534:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800538:	89 3c 24             	mov    %edi,(%esp)
  80053b:	e8 c2 02 00 00       	call   800802 <strnlen>
  800540:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800543:	29 c2                	sub    %eax,%edx
  800545:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800548:	85 d2                	test   %edx,%edx
  80054a:	7e d2                	jle    80051e <vprintfmt+0x1cc>
					putch(padc, putdat);
  80054c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800550:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800553:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800556:	89 d7                	mov    %edx,%edi
  800558:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80055c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80055f:	89 04 24             	mov    %eax,(%esp)
  800562:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800564:	83 ef 01             	sub    $0x1,%edi
  800567:	75 ef                	jne    800558 <vprintfmt+0x206>
  800569:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80056c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80056f:	eb ad                	jmp    80051e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800571:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800575:	74 20                	je     800597 <vprintfmt+0x245>
  800577:	0f be d2             	movsbl %dl,%edx
  80057a:	83 ea 20             	sub    $0x20,%edx
  80057d:	83 fa 5e             	cmp    $0x5e,%edx
  800580:	76 15                	jbe    800597 <vprintfmt+0x245>
					putch('?', putdat);
  800582:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800585:	89 54 24 04          	mov    %edx,0x4(%esp)
  800589:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800590:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800593:	ff d1                	call   *%ecx
  800595:	eb 0f                	jmp    8005a6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800597:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80059a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80059e:	89 04 24             	mov    %eax,(%esp)
  8005a1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8005a4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005a6:	83 eb 01             	sub    $0x1,%ebx
  8005a9:	0f b6 17             	movzbl (%edi),%edx
  8005ac:	0f be c2             	movsbl %dl,%eax
  8005af:	83 c7 01             	add    $0x1,%edi
  8005b2:	85 c0                	test   %eax,%eax
  8005b4:	75 24                	jne    8005da <vprintfmt+0x288>
  8005b6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005b9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8005bc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005bf:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005c2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8005c6:	0f 8e ab fd ff ff    	jle    800377 <vprintfmt+0x25>
  8005cc:	eb 20                	jmp    8005ee <vprintfmt+0x29c>
  8005ce:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8005d1:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8005d4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8005d7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005da:	85 f6                	test   %esi,%esi
  8005dc:	78 93                	js     800571 <vprintfmt+0x21f>
  8005de:	83 ee 01             	sub    $0x1,%esi
  8005e1:	79 8e                	jns    800571 <vprintfmt+0x21f>
  8005e3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005e6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8005e9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8005ec:	eb d1                	jmp    8005bf <vprintfmt+0x26d>
  8005ee:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005f1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005f5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8005fc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005fe:	83 ef 01             	sub    $0x1,%edi
  800601:	75 ee                	jne    8005f1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800603:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800606:	e9 6c fd ff ff       	jmp    800377 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80060b:	83 fa 01             	cmp    $0x1,%edx
  80060e:	66 90                	xchg   %ax,%ax
  800610:	7e 16                	jle    800628 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800612:	8b 45 14             	mov    0x14(%ebp),%eax
  800615:	8d 50 08             	lea    0x8(%eax),%edx
  800618:	89 55 14             	mov    %edx,0x14(%ebp)
  80061b:	8b 10                	mov    (%eax),%edx
  80061d:	8b 48 04             	mov    0x4(%eax),%ecx
  800620:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800623:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800626:	eb 32                	jmp    80065a <vprintfmt+0x308>
	else if (lflag)
  800628:	85 d2                	test   %edx,%edx
  80062a:	74 18                	je     800644 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  80062c:	8b 45 14             	mov    0x14(%ebp),%eax
  80062f:	8d 50 04             	lea    0x4(%eax),%edx
  800632:	89 55 14             	mov    %edx,0x14(%ebp)
  800635:	8b 00                	mov    (%eax),%eax
  800637:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80063a:	89 c1                	mov    %eax,%ecx
  80063c:	c1 f9 1f             	sar    $0x1f,%ecx
  80063f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800642:	eb 16                	jmp    80065a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800644:	8b 45 14             	mov    0x14(%ebp),%eax
  800647:	8d 50 04             	lea    0x4(%eax),%edx
  80064a:	89 55 14             	mov    %edx,0x14(%ebp)
  80064d:	8b 00                	mov    (%eax),%eax
  80064f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800652:	89 c7                	mov    %eax,%edi
  800654:	c1 ff 1f             	sar    $0x1f,%edi
  800657:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80065a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80065d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800660:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800665:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800669:	79 7d                	jns    8006e8 <vprintfmt+0x396>
				putch('-', putdat);
  80066b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80066f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800676:	ff d6                	call   *%esi
				num = -(long long) num;
  800678:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80067b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80067e:	f7 d8                	neg    %eax
  800680:	83 d2 00             	adc    $0x0,%edx
  800683:	f7 da                	neg    %edx
			}
			base = 10;
  800685:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80068a:	eb 5c                	jmp    8006e8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80068c:	8d 45 14             	lea    0x14(%ebp),%eax
  80068f:	e8 3f fc ff ff       	call   8002d3 <getuint>
			base = 10;
  800694:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800699:	eb 4d                	jmp    8006e8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80069b:	8d 45 14             	lea    0x14(%ebp),%eax
  80069e:	e8 30 fc ff ff       	call   8002d3 <getuint>
			base = 8;
  8006a3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8006a8:	eb 3e                	jmp    8006e8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  8006aa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006ae:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8006b5:	ff d6                	call   *%esi
			putch('x', putdat);
  8006b7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006bb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8006c2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c7:	8d 50 04             	lea    0x4(%eax),%edx
  8006ca:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8006cd:	8b 00                	mov    (%eax),%eax
  8006cf:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006d4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006d9:	eb 0d                	jmp    8006e8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006db:	8d 45 14             	lea    0x14(%ebp),%eax
  8006de:	e8 f0 fb ff ff       	call   8002d3 <getuint>
			base = 16;
  8006e3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006e8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  8006ec:	89 7c 24 10          	mov    %edi,0x10(%esp)
  8006f0:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8006f3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8006f7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8006fb:	89 04 24             	mov    %eax,(%esp)
  8006fe:	89 54 24 04          	mov    %edx,0x4(%esp)
  800702:	89 da                	mov    %ebx,%edx
  800704:	89 f0                	mov    %esi,%eax
  800706:	e8 d5 fa ff ff       	call   8001e0 <printnum>
			break;
  80070b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80070e:	e9 64 fc ff ff       	jmp    800377 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800713:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800717:	89 0c 24             	mov    %ecx,(%esp)
  80071a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80071c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80071f:	e9 53 fc ff ff       	jmp    800377 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800724:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800728:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  80072f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800731:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800735:	0f 84 3c fc ff ff    	je     800377 <vprintfmt+0x25>
  80073b:	83 ef 01             	sub    $0x1,%edi
  80073e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800742:	75 f7                	jne    80073b <vprintfmt+0x3e9>
  800744:	e9 2e fc ff ff       	jmp    800377 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800749:	83 c4 4c             	add    $0x4c,%esp
  80074c:	5b                   	pop    %ebx
  80074d:	5e                   	pop    %esi
  80074e:	5f                   	pop    %edi
  80074f:	5d                   	pop    %ebp
  800750:	c3                   	ret    

00800751 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800751:	55                   	push   %ebp
  800752:	89 e5                	mov    %esp,%ebp
  800754:	83 ec 28             	sub    $0x28,%esp
  800757:	8b 45 08             	mov    0x8(%ebp),%eax
  80075a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80075d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800760:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800764:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800767:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80076e:	85 d2                	test   %edx,%edx
  800770:	7e 30                	jle    8007a2 <vsnprintf+0x51>
  800772:	85 c0                	test   %eax,%eax
  800774:	74 2c                	je     8007a2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800776:	8b 45 14             	mov    0x14(%ebp),%eax
  800779:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80077d:	8b 45 10             	mov    0x10(%ebp),%eax
  800780:	89 44 24 08          	mov    %eax,0x8(%esp)
  800784:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800787:	89 44 24 04          	mov    %eax,0x4(%esp)
  80078b:	c7 04 24 0d 03 80 00 	movl   $0x80030d,(%esp)
  800792:	e8 bb fb ff ff       	call   800352 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800797:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80079a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80079d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007a0:	eb 05                	jmp    8007a7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007a2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007a7:	c9                   	leave  
  8007a8:	c3                   	ret    

008007a9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007a9:	55                   	push   %ebp
  8007aa:	89 e5                	mov    %esp,%ebp
  8007ac:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007af:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007b2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007b6:	8b 45 10             	mov    0x10(%ebp),%eax
  8007b9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007bd:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007c4:	8b 45 08             	mov    0x8(%ebp),%eax
  8007c7:	89 04 24             	mov    %eax,(%esp)
  8007ca:	e8 82 ff ff ff       	call   800751 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007cf:	c9                   	leave  
  8007d0:	c3                   	ret    
  8007d1:	66 90                	xchg   %ax,%ax
  8007d3:	66 90                	xchg   %ax,%ax
  8007d5:	66 90                	xchg   %ax,%ax
  8007d7:	66 90                	xchg   %ax,%ax
  8007d9:	66 90                	xchg   %ax,%ax
  8007db:	66 90                	xchg   %ax,%ax
  8007dd:	66 90                	xchg   %ax,%ax
  8007df:	90                   	nop

008007e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007e0:	55                   	push   %ebp
  8007e1:	89 e5                	mov    %esp,%ebp
  8007e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007e6:	80 3a 00             	cmpb   $0x0,(%edx)
  8007e9:	74 10                	je     8007fb <strlen+0x1b>
  8007eb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  8007f0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007f7:	75 f7                	jne    8007f0 <strlen+0x10>
  8007f9:	eb 05                	jmp    800800 <strlen+0x20>
  8007fb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800800:	5d                   	pop    %ebp
  800801:	c3                   	ret    

00800802 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800802:	55                   	push   %ebp
  800803:	89 e5                	mov    %esp,%ebp
  800805:	53                   	push   %ebx
  800806:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800809:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80080c:	85 c9                	test   %ecx,%ecx
  80080e:	74 1c                	je     80082c <strnlen+0x2a>
  800810:	80 3b 00             	cmpb   $0x0,(%ebx)
  800813:	74 1e                	je     800833 <strnlen+0x31>
  800815:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80081a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80081c:	39 ca                	cmp    %ecx,%edx
  80081e:	74 18                	je     800838 <strnlen+0x36>
  800820:	83 c2 01             	add    $0x1,%edx
  800823:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800828:	75 f0                	jne    80081a <strnlen+0x18>
  80082a:	eb 0c                	jmp    800838 <strnlen+0x36>
  80082c:	b8 00 00 00 00       	mov    $0x0,%eax
  800831:	eb 05                	jmp    800838 <strnlen+0x36>
  800833:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800838:	5b                   	pop    %ebx
  800839:	5d                   	pop    %ebp
  80083a:	c3                   	ret    

0080083b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80083b:	55                   	push   %ebp
  80083c:	89 e5                	mov    %esp,%ebp
  80083e:	53                   	push   %ebx
  80083f:	8b 45 08             	mov    0x8(%ebp),%eax
  800842:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800845:	89 c2                	mov    %eax,%edx
  800847:	0f b6 19             	movzbl (%ecx),%ebx
  80084a:	88 1a                	mov    %bl,(%edx)
  80084c:	83 c2 01             	add    $0x1,%edx
  80084f:	83 c1 01             	add    $0x1,%ecx
  800852:	84 db                	test   %bl,%bl
  800854:	75 f1                	jne    800847 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800856:	5b                   	pop    %ebx
  800857:	5d                   	pop    %ebp
  800858:	c3                   	ret    

00800859 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800859:	55                   	push   %ebp
  80085a:	89 e5                	mov    %esp,%ebp
  80085c:	53                   	push   %ebx
  80085d:	83 ec 08             	sub    $0x8,%esp
  800860:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800863:	89 1c 24             	mov    %ebx,(%esp)
  800866:	e8 75 ff ff ff       	call   8007e0 <strlen>
	strcpy(dst + len, src);
  80086b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80086e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800872:	01 d8                	add    %ebx,%eax
  800874:	89 04 24             	mov    %eax,(%esp)
  800877:	e8 bf ff ff ff       	call   80083b <strcpy>
	return dst;
}
  80087c:	89 d8                	mov    %ebx,%eax
  80087e:	83 c4 08             	add    $0x8,%esp
  800881:	5b                   	pop    %ebx
  800882:	5d                   	pop    %ebp
  800883:	c3                   	ret    

00800884 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800884:	55                   	push   %ebp
  800885:	89 e5                	mov    %esp,%ebp
  800887:	56                   	push   %esi
  800888:	53                   	push   %ebx
  800889:	8b 75 08             	mov    0x8(%ebp),%esi
  80088c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80088f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800892:	85 db                	test   %ebx,%ebx
  800894:	74 16                	je     8008ac <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800896:	01 f3                	add    %esi,%ebx
  800898:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  80089a:	0f b6 02             	movzbl (%edx),%eax
  80089d:	88 01                	mov    %al,(%ecx)
  80089f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008a2:	80 3a 01             	cmpb   $0x1,(%edx)
  8008a5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008a8:	39 d9                	cmp    %ebx,%ecx
  8008aa:	75 ee                	jne    80089a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008ac:	89 f0                	mov    %esi,%eax
  8008ae:	5b                   	pop    %ebx
  8008af:	5e                   	pop    %esi
  8008b0:	5d                   	pop    %ebp
  8008b1:	c3                   	ret    

008008b2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008b2:	55                   	push   %ebp
  8008b3:	89 e5                	mov    %esp,%ebp
  8008b5:	57                   	push   %edi
  8008b6:	56                   	push   %esi
  8008b7:	53                   	push   %ebx
  8008b8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008bb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8008be:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008c1:	89 f8                	mov    %edi,%eax
  8008c3:	85 f6                	test   %esi,%esi
  8008c5:	74 33                	je     8008fa <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  8008c7:	83 fe 01             	cmp    $0x1,%esi
  8008ca:	74 25                	je     8008f1 <strlcpy+0x3f>
  8008cc:	0f b6 0b             	movzbl (%ebx),%ecx
  8008cf:	84 c9                	test   %cl,%cl
  8008d1:	74 22                	je     8008f5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  8008d3:	83 ee 02             	sub    $0x2,%esi
  8008d6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008db:	88 08                	mov    %cl,(%eax)
  8008dd:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008e0:	39 f2                	cmp    %esi,%edx
  8008e2:	74 13                	je     8008f7 <strlcpy+0x45>
  8008e4:	83 c2 01             	add    $0x1,%edx
  8008e7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  8008eb:	84 c9                	test   %cl,%cl
  8008ed:	75 ec                	jne    8008db <strlcpy+0x29>
  8008ef:	eb 06                	jmp    8008f7 <strlcpy+0x45>
  8008f1:	89 f8                	mov    %edi,%eax
  8008f3:	eb 02                	jmp    8008f7 <strlcpy+0x45>
  8008f5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008f7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008fa:	29 f8                	sub    %edi,%eax
}
  8008fc:	5b                   	pop    %ebx
  8008fd:	5e                   	pop    %esi
  8008fe:	5f                   	pop    %edi
  8008ff:	5d                   	pop    %ebp
  800900:	c3                   	ret    

00800901 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800901:	55                   	push   %ebp
  800902:	89 e5                	mov    %esp,%ebp
  800904:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800907:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80090a:	0f b6 01             	movzbl (%ecx),%eax
  80090d:	84 c0                	test   %al,%al
  80090f:	74 15                	je     800926 <strcmp+0x25>
  800911:	3a 02                	cmp    (%edx),%al
  800913:	75 11                	jne    800926 <strcmp+0x25>
		p++, q++;
  800915:	83 c1 01             	add    $0x1,%ecx
  800918:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80091b:	0f b6 01             	movzbl (%ecx),%eax
  80091e:	84 c0                	test   %al,%al
  800920:	74 04                	je     800926 <strcmp+0x25>
  800922:	3a 02                	cmp    (%edx),%al
  800924:	74 ef                	je     800915 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800926:	0f b6 c0             	movzbl %al,%eax
  800929:	0f b6 12             	movzbl (%edx),%edx
  80092c:	29 d0                	sub    %edx,%eax
}
  80092e:	5d                   	pop    %ebp
  80092f:	c3                   	ret    

00800930 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800930:	55                   	push   %ebp
  800931:	89 e5                	mov    %esp,%ebp
  800933:	56                   	push   %esi
  800934:	53                   	push   %ebx
  800935:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800938:	8b 55 0c             	mov    0xc(%ebp),%edx
  80093b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  80093e:	85 f6                	test   %esi,%esi
  800940:	74 29                	je     80096b <strncmp+0x3b>
  800942:	0f b6 03             	movzbl (%ebx),%eax
  800945:	84 c0                	test   %al,%al
  800947:	74 30                	je     800979 <strncmp+0x49>
  800949:	3a 02                	cmp    (%edx),%al
  80094b:	75 2c                	jne    800979 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  80094d:	8d 43 01             	lea    0x1(%ebx),%eax
  800950:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800952:	89 c3                	mov    %eax,%ebx
  800954:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800957:	39 f0                	cmp    %esi,%eax
  800959:	74 17                	je     800972 <strncmp+0x42>
  80095b:	0f b6 08             	movzbl (%eax),%ecx
  80095e:	84 c9                	test   %cl,%cl
  800960:	74 17                	je     800979 <strncmp+0x49>
  800962:	83 c0 01             	add    $0x1,%eax
  800965:	3a 0a                	cmp    (%edx),%cl
  800967:	74 e9                	je     800952 <strncmp+0x22>
  800969:	eb 0e                	jmp    800979 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  80096b:	b8 00 00 00 00       	mov    $0x0,%eax
  800970:	eb 0f                	jmp    800981 <strncmp+0x51>
  800972:	b8 00 00 00 00       	mov    $0x0,%eax
  800977:	eb 08                	jmp    800981 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800979:	0f b6 03             	movzbl (%ebx),%eax
  80097c:	0f b6 12             	movzbl (%edx),%edx
  80097f:	29 d0                	sub    %edx,%eax
}
  800981:	5b                   	pop    %ebx
  800982:	5e                   	pop    %esi
  800983:	5d                   	pop    %ebp
  800984:	c3                   	ret    

00800985 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800985:	55                   	push   %ebp
  800986:	89 e5                	mov    %esp,%ebp
  800988:	53                   	push   %ebx
  800989:	8b 45 08             	mov    0x8(%ebp),%eax
  80098c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  80098f:	0f b6 18             	movzbl (%eax),%ebx
  800992:	84 db                	test   %bl,%bl
  800994:	74 1d                	je     8009b3 <strchr+0x2e>
  800996:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800998:	38 d3                	cmp    %dl,%bl
  80099a:	75 06                	jne    8009a2 <strchr+0x1d>
  80099c:	eb 1a                	jmp    8009b8 <strchr+0x33>
  80099e:	38 ca                	cmp    %cl,%dl
  8009a0:	74 16                	je     8009b8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009a2:	83 c0 01             	add    $0x1,%eax
  8009a5:	0f b6 10             	movzbl (%eax),%edx
  8009a8:	84 d2                	test   %dl,%dl
  8009aa:	75 f2                	jne    80099e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  8009ac:	b8 00 00 00 00       	mov    $0x0,%eax
  8009b1:	eb 05                	jmp    8009b8 <strchr+0x33>
  8009b3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009b8:	5b                   	pop    %ebx
  8009b9:	5d                   	pop    %ebp
  8009ba:	c3                   	ret    

008009bb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009bb:	55                   	push   %ebp
  8009bc:	89 e5                	mov    %esp,%ebp
  8009be:	53                   	push   %ebx
  8009bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  8009c5:	0f b6 18             	movzbl (%eax),%ebx
  8009c8:	84 db                	test   %bl,%bl
  8009ca:	74 16                	je     8009e2 <strfind+0x27>
  8009cc:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  8009ce:	38 d3                	cmp    %dl,%bl
  8009d0:	75 06                	jne    8009d8 <strfind+0x1d>
  8009d2:	eb 0e                	jmp    8009e2 <strfind+0x27>
  8009d4:	38 ca                	cmp    %cl,%dl
  8009d6:	74 0a                	je     8009e2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8009d8:	83 c0 01             	add    $0x1,%eax
  8009db:	0f b6 10             	movzbl (%eax),%edx
  8009de:	84 d2                	test   %dl,%dl
  8009e0:	75 f2                	jne    8009d4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  8009e2:	5b                   	pop    %ebx
  8009e3:	5d                   	pop    %ebp
  8009e4:	c3                   	ret    

008009e5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009e5:	55                   	push   %ebp
  8009e6:	89 e5                	mov    %esp,%ebp
  8009e8:	83 ec 0c             	sub    $0xc,%esp
  8009eb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8009ee:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8009f1:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009f4:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009f7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009fa:	85 c9                	test   %ecx,%ecx
  8009fc:	74 36                	je     800a34 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009fe:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a04:	75 28                	jne    800a2e <memset+0x49>
  800a06:	f6 c1 03             	test   $0x3,%cl
  800a09:	75 23                	jne    800a2e <memset+0x49>
		c &= 0xFF;
  800a0b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a0f:	89 d3                	mov    %edx,%ebx
  800a11:	c1 e3 08             	shl    $0x8,%ebx
  800a14:	89 d6                	mov    %edx,%esi
  800a16:	c1 e6 18             	shl    $0x18,%esi
  800a19:	89 d0                	mov    %edx,%eax
  800a1b:	c1 e0 10             	shl    $0x10,%eax
  800a1e:	09 f0                	or     %esi,%eax
  800a20:	09 c2                	or     %eax,%edx
  800a22:	89 d0                	mov    %edx,%eax
  800a24:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a26:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a29:	fc                   	cld    
  800a2a:	f3 ab                	rep stos %eax,%es:(%edi)
  800a2c:	eb 06                	jmp    800a34 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a2e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a31:	fc                   	cld    
  800a32:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a34:	89 f8                	mov    %edi,%eax
  800a36:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a39:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a3c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a3f:	89 ec                	mov    %ebp,%esp
  800a41:	5d                   	pop    %ebp
  800a42:	c3                   	ret    

00800a43 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a43:	55                   	push   %ebp
  800a44:	89 e5                	mov    %esp,%ebp
  800a46:	83 ec 08             	sub    $0x8,%esp
  800a49:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a4c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a4f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a52:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a55:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a58:	39 c6                	cmp    %eax,%esi
  800a5a:	73 36                	jae    800a92 <memmove+0x4f>
  800a5c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a5f:	39 d0                	cmp    %edx,%eax
  800a61:	73 2f                	jae    800a92 <memmove+0x4f>
		s += n;
		d += n;
  800a63:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a66:	f6 c2 03             	test   $0x3,%dl
  800a69:	75 1b                	jne    800a86 <memmove+0x43>
  800a6b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a71:	75 13                	jne    800a86 <memmove+0x43>
  800a73:	f6 c1 03             	test   $0x3,%cl
  800a76:	75 0e                	jne    800a86 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a78:	83 ef 04             	sub    $0x4,%edi
  800a7b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a7e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a81:	fd                   	std    
  800a82:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a84:	eb 09                	jmp    800a8f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a86:	83 ef 01             	sub    $0x1,%edi
  800a89:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a8c:	fd                   	std    
  800a8d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a8f:	fc                   	cld    
  800a90:	eb 20                	jmp    800ab2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a92:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a98:	75 13                	jne    800aad <memmove+0x6a>
  800a9a:	a8 03                	test   $0x3,%al
  800a9c:	75 0f                	jne    800aad <memmove+0x6a>
  800a9e:	f6 c1 03             	test   $0x3,%cl
  800aa1:	75 0a                	jne    800aad <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800aa3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800aa6:	89 c7                	mov    %eax,%edi
  800aa8:	fc                   	cld    
  800aa9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aab:	eb 05                	jmp    800ab2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800aad:	89 c7                	mov    %eax,%edi
  800aaf:	fc                   	cld    
  800ab0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ab2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ab5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ab8:	89 ec                	mov    %ebp,%esp
  800aba:	5d                   	pop    %ebp
  800abb:	c3                   	ret    

00800abc <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800abc:	55                   	push   %ebp
  800abd:	89 e5                	mov    %esp,%ebp
  800abf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ac2:	8b 45 10             	mov    0x10(%ebp),%eax
  800ac5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800acc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ad0:	8b 45 08             	mov    0x8(%ebp),%eax
  800ad3:	89 04 24             	mov    %eax,(%esp)
  800ad6:	e8 68 ff ff ff       	call   800a43 <memmove>
}
  800adb:	c9                   	leave  
  800adc:	c3                   	ret    

00800add <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800add:	55                   	push   %ebp
  800ade:	89 e5                	mov    %esp,%ebp
  800ae0:	57                   	push   %edi
  800ae1:	56                   	push   %esi
  800ae2:	53                   	push   %ebx
  800ae3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800ae6:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ae9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800aec:	8d 78 ff             	lea    -0x1(%eax),%edi
  800aef:	85 c0                	test   %eax,%eax
  800af1:	74 36                	je     800b29 <memcmp+0x4c>
		if (*s1 != *s2)
  800af3:	0f b6 03             	movzbl (%ebx),%eax
  800af6:	0f b6 0e             	movzbl (%esi),%ecx
  800af9:	38 c8                	cmp    %cl,%al
  800afb:	75 17                	jne    800b14 <memcmp+0x37>
  800afd:	ba 00 00 00 00       	mov    $0x0,%edx
  800b02:	eb 1a                	jmp    800b1e <memcmp+0x41>
  800b04:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800b09:	83 c2 01             	add    $0x1,%edx
  800b0c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800b10:	38 c8                	cmp    %cl,%al
  800b12:	74 0a                	je     800b1e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800b14:	0f b6 c0             	movzbl %al,%eax
  800b17:	0f b6 c9             	movzbl %cl,%ecx
  800b1a:	29 c8                	sub    %ecx,%eax
  800b1c:	eb 10                	jmp    800b2e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b1e:	39 fa                	cmp    %edi,%edx
  800b20:	75 e2                	jne    800b04 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b22:	b8 00 00 00 00       	mov    $0x0,%eax
  800b27:	eb 05                	jmp    800b2e <memcmp+0x51>
  800b29:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b2e:	5b                   	pop    %ebx
  800b2f:	5e                   	pop    %esi
  800b30:	5f                   	pop    %edi
  800b31:	5d                   	pop    %ebp
  800b32:	c3                   	ret    

00800b33 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b33:	55                   	push   %ebp
  800b34:	89 e5                	mov    %esp,%ebp
  800b36:	53                   	push   %ebx
  800b37:	8b 45 08             	mov    0x8(%ebp),%eax
  800b3a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800b3d:	89 c2                	mov    %eax,%edx
  800b3f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b42:	39 d0                	cmp    %edx,%eax
  800b44:	73 13                	jae    800b59 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b46:	89 d9                	mov    %ebx,%ecx
  800b48:	38 18                	cmp    %bl,(%eax)
  800b4a:	75 06                	jne    800b52 <memfind+0x1f>
  800b4c:	eb 0b                	jmp    800b59 <memfind+0x26>
  800b4e:	38 08                	cmp    %cl,(%eax)
  800b50:	74 07                	je     800b59 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b52:	83 c0 01             	add    $0x1,%eax
  800b55:	39 d0                	cmp    %edx,%eax
  800b57:	75 f5                	jne    800b4e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b59:	5b                   	pop    %ebx
  800b5a:	5d                   	pop    %ebp
  800b5b:	c3                   	ret    

00800b5c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b5c:	55                   	push   %ebp
  800b5d:	89 e5                	mov    %esp,%ebp
  800b5f:	57                   	push   %edi
  800b60:	56                   	push   %esi
  800b61:	53                   	push   %ebx
  800b62:	83 ec 04             	sub    $0x4,%esp
  800b65:	8b 55 08             	mov    0x8(%ebp),%edx
  800b68:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b6b:	0f b6 02             	movzbl (%edx),%eax
  800b6e:	3c 09                	cmp    $0x9,%al
  800b70:	74 04                	je     800b76 <strtol+0x1a>
  800b72:	3c 20                	cmp    $0x20,%al
  800b74:	75 0e                	jne    800b84 <strtol+0x28>
		s++;
  800b76:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b79:	0f b6 02             	movzbl (%edx),%eax
  800b7c:	3c 09                	cmp    $0x9,%al
  800b7e:	74 f6                	je     800b76 <strtol+0x1a>
  800b80:	3c 20                	cmp    $0x20,%al
  800b82:	74 f2                	je     800b76 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b84:	3c 2b                	cmp    $0x2b,%al
  800b86:	75 0a                	jne    800b92 <strtol+0x36>
		s++;
  800b88:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b8b:	bf 00 00 00 00       	mov    $0x0,%edi
  800b90:	eb 10                	jmp    800ba2 <strtol+0x46>
  800b92:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b97:	3c 2d                	cmp    $0x2d,%al
  800b99:	75 07                	jne    800ba2 <strtol+0x46>
		s++, neg = 1;
  800b9b:	83 c2 01             	add    $0x1,%edx
  800b9e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ba2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ba8:	75 15                	jne    800bbf <strtol+0x63>
  800baa:	80 3a 30             	cmpb   $0x30,(%edx)
  800bad:	75 10                	jne    800bbf <strtol+0x63>
  800baf:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800bb3:	75 0a                	jne    800bbf <strtol+0x63>
		s += 2, base = 16;
  800bb5:	83 c2 02             	add    $0x2,%edx
  800bb8:	bb 10 00 00 00       	mov    $0x10,%ebx
  800bbd:	eb 10                	jmp    800bcf <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800bbf:	85 db                	test   %ebx,%ebx
  800bc1:	75 0c                	jne    800bcf <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bc3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bc5:	80 3a 30             	cmpb   $0x30,(%edx)
  800bc8:	75 05                	jne    800bcf <strtol+0x73>
		s++, base = 8;
  800bca:	83 c2 01             	add    $0x1,%edx
  800bcd:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800bcf:	b8 00 00 00 00       	mov    $0x0,%eax
  800bd4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bd7:	0f b6 0a             	movzbl (%edx),%ecx
  800bda:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800bdd:	89 f3                	mov    %esi,%ebx
  800bdf:	80 fb 09             	cmp    $0x9,%bl
  800be2:	77 08                	ja     800bec <strtol+0x90>
			dig = *s - '0';
  800be4:	0f be c9             	movsbl %cl,%ecx
  800be7:	83 e9 30             	sub    $0x30,%ecx
  800bea:	eb 22                	jmp    800c0e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800bec:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800bef:	89 f3                	mov    %esi,%ebx
  800bf1:	80 fb 19             	cmp    $0x19,%bl
  800bf4:	77 08                	ja     800bfe <strtol+0xa2>
			dig = *s - 'a' + 10;
  800bf6:	0f be c9             	movsbl %cl,%ecx
  800bf9:	83 e9 57             	sub    $0x57,%ecx
  800bfc:	eb 10                	jmp    800c0e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800bfe:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800c01:	89 f3                	mov    %esi,%ebx
  800c03:	80 fb 19             	cmp    $0x19,%bl
  800c06:	77 16                	ja     800c1e <strtol+0xc2>
			dig = *s - 'A' + 10;
  800c08:	0f be c9             	movsbl %cl,%ecx
  800c0b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c0e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800c11:	7d 0f                	jge    800c22 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800c13:	83 c2 01             	add    $0x1,%edx
  800c16:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800c1a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800c1c:	eb b9                	jmp    800bd7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800c1e:	89 c1                	mov    %eax,%ecx
  800c20:	eb 02                	jmp    800c24 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800c22:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800c24:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c28:	74 05                	je     800c2f <strtol+0xd3>
		*endptr = (char *) s;
  800c2a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c2d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800c2f:	89 ca                	mov    %ecx,%edx
  800c31:	f7 da                	neg    %edx
  800c33:	85 ff                	test   %edi,%edi
  800c35:	0f 45 c2             	cmovne %edx,%eax
}
  800c38:	83 c4 04             	add    $0x4,%esp
  800c3b:	5b                   	pop    %ebx
  800c3c:	5e                   	pop    %esi
  800c3d:	5f                   	pop    %edi
  800c3e:	5d                   	pop    %ebp
  800c3f:	c3                   	ret    

00800c40 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800c40:	55                   	push   %ebp
  800c41:	89 e5                	mov    %esp,%ebp
  800c43:	83 ec 0c             	sub    $0xc,%esp
  800c46:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c49:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c4c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c4f:	b8 00 00 00 00       	mov    $0x0,%eax
  800c54:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c57:	8b 55 08             	mov    0x8(%ebp),%edx
  800c5a:	89 c3                	mov    %eax,%ebx
  800c5c:	89 c7                	mov    %eax,%edi
  800c5e:	89 c6                	mov    %eax,%esi
  800c60:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c62:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c65:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c68:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c6b:	89 ec                	mov    %ebp,%esp
  800c6d:	5d                   	pop    %ebp
  800c6e:	c3                   	ret    

00800c6f <sys_cgetc>:

int
sys_cgetc(void)
{
  800c6f:	55                   	push   %ebp
  800c70:	89 e5                	mov    %esp,%ebp
  800c72:	83 ec 0c             	sub    $0xc,%esp
  800c75:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c78:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c7b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c7e:	ba 00 00 00 00       	mov    $0x0,%edx
  800c83:	b8 01 00 00 00       	mov    $0x1,%eax
  800c88:	89 d1                	mov    %edx,%ecx
  800c8a:	89 d3                	mov    %edx,%ebx
  800c8c:	89 d7                	mov    %edx,%edi
  800c8e:	89 d6                	mov    %edx,%esi
  800c90:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c92:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c95:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c98:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c9b:	89 ec                	mov    %ebp,%esp
  800c9d:	5d                   	pop    %ebp
  800c9e:	c3                   	ret    

00800c9f <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c9f:	55                   	push   %ebp
  800ca0:	89 e5                	mov    %esp,%ebp
  800ca2:	83 ec 38             	sub    $0x38,%esp
  800ca5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ca8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800cab:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cae:	b9 00 00 00 00       	mov    $0x0,%ecx
  800cb3:	b8 03 00 00 00       	mov    $0x3,%eax
  800cb8:	8b 55 08             	mov    0x8(%ebp),%edx
  800cbb:	89 cb                	mov    %ecx,%ebx
  800cbd:	89 cf                	mov    %ecx,%edi
  800cbf:	89 ce                	mov    %ecx,%esi
  800cc1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cc3:	85 c0                	test   %eax,%eax
  800cc5:	7e 28                	jle    800cef <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cc7:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ccb:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800cd2:	00 
  800cd3:	c7 44 24 08 24 16 80 	movl   $0x801624,0x8(%esp)
  800cda:	00 
  800cdb:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ce2:	00 
  800ce3:	c7 04 24 41 16 80 00 	movl   $0x801641,(%esp)
  800cea:	e8 6d 03 00 00       	call   80105c <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800cef:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800cf2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cf5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cf8:	89 ec                	mov    %ebp,%esp
  800cfa:	5d                   	pop    %ebp
  800cfb:	c3                   	ret    

00800cfc <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800cfc:	55                   	push   %ebp
  800cfd:	89 e5                	mov    %esp,%ebp
  800cff:	83 ec 0c             	sub    $0xc,%esp
  800d02:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d05:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d08:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d0b:	ba 00 00 00 00       	mov    $0x0,%edx
  800d10:	b8 02 00 00 00       	mov    $0x2,%eax
  800d15:	89 d1                	mov    %edx,%ecx
  800d17:	89 d3                	mov    %edx,%ebx
  800d19:	89 d7                	mov    %edx,%edi
  800d1b:	89 d6                	mov    %edx,%esi
  800d1d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800d1f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d22:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d25:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d28:	89 ec                	mov    %ebp,%esp
  800d2a:	5d                   	pop    %ebp
  800d2b:	c3                   	ret    

00800d2c <sys_yield>:

void
sys_yield(void)
{
  800d2c:	55                   	push   %ebp
  800d2d:	89 e5                	mov    %esp,%ebp
  800d2f:	83 ec 0c             	sub    $0xc,%esp
  800d32:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d35:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d38:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d3b:	ba 00 00 00 00       	mov    $0x0,%edx
  800d40:	b8 0a 00 00 00       	mov    $0xa,%eax
  800d45:	89 d1                	mov    %edx,%ecx
  800d47:	89 d3                	mov    %edx,%ebx
  800d49:	89 d7                	mov    %edx,%edi
  800d4b:	89 d6                	mov    %edx,%esi
  800d4d:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800d4f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d52:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d55:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d58:	89 ec                	mov    %ebp,%esp
  800d5a:	5d                   	pop    %ebp
  800d5b:	c3                   	ret    

00800d5c <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800d5c:	55                   	push   %ebp
  800d5d:	89 e5                	mov    %esp,%ebp
  800d5f:	83 ec 38             	sub    $0x38,%esp
  800d62:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d65:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d68:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d6b:	be 00 00 00 00       	mov    $0x0,%esi
  800d70:	b8 04 00 00 00       	mov    $0x4,%eax
  800d75:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d78:	8b 55 08             	mov    0x8(%ebp),%edx
  800d7b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d7e:	89 f7                	mov    %esi,%edi
  800d80:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d82:	85 c0                	test   %eax,%eax
  800d84:	7e 28                	jle    800dae <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d86:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d8a:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800d91:	00 
  800d92:	c7 44 24 08 24 16 80 	movl   $0x801624,0x8(%esp)
  800d99:	00 
  800d9a:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800da1:	00 
  800da2:	c7 04 24 41 16 80 00 	movl   $0x801641,(%esp)
  800da9:	e8 ae 02 00 00       	call   80105c <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800dae:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800db1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800db4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800db7:	89 ec                	mov    %ebp,%esp
  800db9:	5d                   	pop    %ebp
  800dba:	c3                   	ret    

00800dbb <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800dbb:	55                   	push   %ebp
  800dbc:	89 e5                	mov    %esp,%ebp
  800dbe:	83 ec 38             	sub    $0x38,%esp
  800dc1:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800dc4:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800dc7:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dca:	b8 05 00 00 00       	mov    $0x5,%eax
  800dcf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800dd2:	8b 55 08             	mov    0x8(%ebp),%edx
  800dd5:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800dd8:	8b 7d 14             	mov    0x14(%ebp),%edi
  800ddb:	8b 75 18             	mov    0x18(%ebp),%esi
  800dde:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800de0:	85 c0                	test   %eax,%eax
  800de2:	7e 28                	jle    800e0c <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800de4:	89 44 24 10          	mov    %eax,0x10(%esp)
  800de8:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800def:	00 
  800df0:	c7 44 24 08 24 16 80 	movl   $0x801624,0x8(%esp)
  800df7:	00 
  800df8:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800dff:	00 
  800e00:	c7 04 24 41 16 80 00 	movl   $0x801641,(%esp)
  800e07:	e8 50 02 00 00       	call   80105c <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800e0c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e0f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e12:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e15:	89 ec                	mov    %ebp,%esp
  800e17:	5d                   	pop    %ebp
  800e18:	c3                   	ret    

00800e19 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800e19:	55                   	push   %ebp
  800e1a:	89 e5                	mov    %esp,%ebp
  800e1c:	83 ec 38             	sub    $0x38,%esp
  800e1f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e22:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e25:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e28:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e2d:	b8 06 00 00 00       	mov    $0x6,%eax
  800e32:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e35:	8b 55 08             	mov    0x8(%ebp),%edx
  800e38:	89 df                	mov    %ebx,%edi
  800e3a:	89 de                	mov    %ebx,%esi
  800e3c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e3e:	85 c0                	test   %eax,%eax
  800e40:	7e 28                	jle    800e6a <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e42:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e46:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800e4d:	00 
  800e4e:	c7 44 24 08 24 16 80 	movl   $0x801624,0x8(%esp)
  800e55:	00 
  800e56:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e5d:	00 
  800e5e:	c7 04 24 41 16 80 00 	movl   $0x801641,(%esp)
  800e65:	e8 f2 01 00 00       	call   80105c <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800e6a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e6d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e70:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e73:	89 ec                	mov    %ebp,%esp
  800e75:	5d                   	pop    %ebp
  800e76:	c3                   	ret    

00800e77 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800e77:	55                   	push   %ebp
  800e78:	89 e5                	mov    %esp,%ebp
  800e7a:	83 ec 38             	sub    $0x38,%esp
  800e7d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e80:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e83:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e86:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e8b:	b8 08 00 00 00       	mov    $0x8,%eax
  800e90:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e93:	8b 55 08             	mov    0x8(%ebp),%edx
  800e96:	89 df                	mov    %ebx,%edi
  800e98:	89 de                	mov    %ebx,%esi
  800e9a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e9c:	85 c0                	test   %eax,%eax
  800e9e:	7e 28                	jle    800ec8 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ea0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ea4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800eab:	00 
  800eac:	c7 44 24 08 24 16 80 	movl   $0x801624,0x8(%esp)
  800eb3:	00 
  800eb4:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ebb:	00 
  800ebc:	c7 04 24 41 16 80 00 	movl   $0x801641,(%esp)
  800ec3:	e8 94 01 00 00       	call   80105c <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800ec8:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800ecb:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ece:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ed1:	89 ec                	mov    %ebp,%esp
  800ed3:	5d                   	pop    %ebp
  800ed4:	c3                   	ret    

00800ed5 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800ed5:	55                   	push   %ebp
  800ed6:	89 e5                	mov    %esp,%ebp
  800ed8:	83 ec 38             	sub    $0x38,%esp
  800edb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ede:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ee1:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ee4:	bb 00 00 00 00       	mov    $0x0,%ebx
  800ee9:	b8 09 00 00 00       	mov    $0x9,%eax
  800eee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ef1:	8b 55 08             	mov    0x8(%ebp),%edx
  800ef4:	89 df                	mov    %ebx,%edi
  800ef6:	89 de                	mov    %ebx,%esi
  800ef8:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800efa:	85 c0                	test   %eax,%eax
  800efc:	7e 28                	jle    800f26 <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800efe:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f02:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800f09:	00 
  800f0a:	c7 44 24 08 24 16 80 	movl   $0x801624,0x8(%esp)
  800f11:	00 
  800f12:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f19:	00 
  800f1a:	c7 04 24 41 16 80 00 	movl   $0x801641,(%esp)
  800f21:	e8 36 01 00 00       	call   80105c <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800f26:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f29:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f2c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f2f:	89 ec                	mov    %ebp,%esp
  800f31:	5d                   	pop    %ebp
  800f32:	c3                   	ret    

00800f33 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800f33:	55                   	push   %ebp
  800f34:	89 e5                	mov    %esp,%ebp
  800f36:	83 ec 0c             	sub    $0xc,%esp
  800f39:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f3c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f3f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f42:	be 00 00 00 00       	mov    $0x0,%esi
  800f47:	b8 0b 00 00 00       	mov    $0xb,%eax
  800f4c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f4f:	8b 55 08             	mov    0x8(%ebp),%edx
  800f52:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800f55:	8b 7d 14             	mov    0x14(%ebp),%edi
  800f58:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800f5a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f5d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f60:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f63:	89 ec                	mov    %ebp,%esp
  800f65:	5d                   	pop    %ebp
  800f66:	c3                   	ret    

00800f67 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800f67:	55                   	push   %ebp
  800f68:	89 e5                	mov    %esp,%ebp
  800f6a:	83 ec 38             	sub    $0x38,%esp
  800f6d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f70:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f73:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f76:	b9 00 00 00 00       	mov    $0x0,%ecx
  800f7b:	b8 0c 00 00 00       	mov    $0xc,%eax
  800f80:	8b 55 08             	mov    0x8(%ebp),%edx
  800f83:	89 cb                	mov    %ecx,%ebx
  800f85:	89 cf                	mov    %ecx,%edi
  800f87:	89 ce                	mov    %ecx,%esi
  800f89:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f8b:	85 c0                	test   %eax,%eax
  800f8d:	7e 28                	jle    800fb7 <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f8f:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f93:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800f9a:	00 
  800f9b:	c7 44 24 08 24 16 80 	movl   $0x801624,0x8(%esp)
  800fa2:	00 
  800fa3:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800faa:	00 
  800fab:	c7 04 24 41 16 80 00 	movl   $0x801641,(%esp)
  800fb2:	e8 a5 00 00 00       	call   80105c <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800fb7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800fba:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800fbd:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800fc0:	89 ec                	mov    %ebp,%esp
  800fc2:	5d                   	pop    %ebp
  800fc3:	c3                   	ret    

00800fc4 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  800fc4:	55                   	push   %ebp
  800fc5:	89 e5                	mov    %esp,%ebp
  800fc7:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  800fca:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  800fd1:	75 54                	jne    801027 <set_pgfault_handler+0x63>
		// First time through!
		// LAB 4: Your code here.
		if((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE), PTE_U|PTE_P|PTE_W)))
  800fd3:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800fda:	00 
  800fdb:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  800fe2:	ee 
  800fe3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800fea:	e8 6d fd ff ff       	call   800d5c <sys_page_alloc>
  800fef:	85 c0                	test   %eax,%eax
  800ff1:	74 20                	je     801013 <set_pgfault_handler+0x4f>
			panic("Exception stack alloc failed: %e!\n", r);
  800ff3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800ff7:	c7 44 24 08 50 16 80 	movl   $0x801650,0x8(%esp)
  800ffe:	00 
  800fff:	c7 44 24 04 21 00 00 	movl   $0x21,0x4(%esp)
  801006:	00 
  801007:	c7 04 24 73 16 80 00 	movl   $0x801673,(%esp)
  80100e:	e8 49 00 00 00       	call   80105c <_panic>
		sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  801013:	c7 44 24 04 34 10 80 	movl   $0x801034,0x4(%esp)
  80101a:	00 
  80101b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801022:	e8 ae fe ff ff       	call   800ed5 <sys_env_set_pgfault_upcall>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  801027:	8b 45 08             	mov    0x8(%ebp),%eax
  80102a:	a3 08 20 80 00       	mov    %eax,0x802008
}
  80102f:	c9                   	leave  
  801030:	c3                   	ret    
  801031:	66 90                	xchg   %ax,%ax
  801033:	90                   	nop

00801034 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801034:	54                   	push   %esp
	movl _pgfault_handler, %eax
  801035:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  80103a:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80103c:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	addl $8, %esp
  80103f:	83 c4 08             	add    $0x8,%esp

	movl 0x20(%esp), %ecx
  801042:	8b 4c 24 20          	mov    0x20(%esp),%ecx
	movl 0x28(%esp), %eax
  801046:	8b 44 24 28          	mov    0x28(%esp),%eax
	subl $0x4, %eax 
  80104a:	83 e8 04             	sub    $0x4,%eax
	movl %eax, 0x28(%esp)
  80104d:	89 44 24 28          	mov    %eax,0x28(%esp)
	movl %ecx, (%eax)
  801051:	89 08                	mov    %ecx,(%eax)


	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  801053:	61                   	popa   

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $4, %esp
  801054:	83 c4 04             	add    $0x4,%esp
	popfl
  801057:	9d                   	popf   

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	pop %esp
  801058:	5c                   	pop    %esp
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  801059:	c3                   	ret    
  80105a:	66 90                	xchg   %ax,%ax

0080105c <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80105c:	55                   	push   %ebp
  80105d:	89 e5                	mov    %esp,%ebp
  80105f:	56                   	push   %esi
  801060:	53                   	push   %ebx
  801061:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  801064:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  801067:	a1 0c 20 80 00       	mov    0x80200c,%eax
  80106c:	85 c0                	test   %eax,%eax
  80106e:	74 10                	je     801080 <_panic+0x24>
		cprintf("%s: ", argv0);
  801070:	89 44 24 04          	mov    %eax,0x4(%esp)
  801074:	c7 04 24 81 16 80 00 	movl   $0x801681,(%esp)
  80107b:	e8 3f f1 ff ff       	call   8001bf <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801080:	8b 35 00 20 80 00    	mov    0x802000,%esi
  801086:	e8 71 fc ff ff       	call   800cfc <sys_getenvid>
  80108b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80108e:	89 54 24 10          	mov    %edx,0x10(%esp)
  801092:	8b 55 08             	mov    0x8(%ebp),%edx
  801095:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801099:	89 74 24 08          	mov    %esi,0x8(%esp)
  80109d:	89 44 24 04          	mov    %eax,0x4(%esp)
  8010a1:	c7 04 24 88 16 80 00 	movl   $0x801688,(%esp)
  8010a8:	e8 12 f1 ff ff       	call   8001bf <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8010ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8010b1:	8b 45 10             	mov    0x10(%ebp),%eax
  8010b4:	89 04 24             	mov    %eax,(%esp)
  8010b7:	e8 a2 f0 ff ff       	call   80015e <vcprintf>
	cprintf("\n");
  8010bc:	c7 04 24 da 13 80 00 	movl   $0x8013da,(%esp)
  8010c3:	e8 f7 f0 ff ff       	call   8001bf <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8010c8:	cc                   	int3   
  8010c9:	eb fd                	jmp    8010c8 <_panic+0x6c>
  8010cb:	66 90                	xchg   %ax,%ax
  8010cd:	66 90                	xchg   %ax,%ax
  8010cf:	90                   	nop

008010d0 <__udivdi3>:
  8010d0:	83 ec 1c             	sub    $0x1c,%esp
  8010d3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  8010d7:	89 7c 24 14          	mov    %edi,0x14(%esp)
  8010db:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  8010df:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  8010e3:	8b 7c 24 20          	mov    0x20(%esp),%edi
  8010e7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  8010eb:	85 c0                	test   %eax,%eax
  8010ed:	89 74 24 10          	mov    %esi,0x10(%esp)
  8010f1:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8010f5:	89 ea                	mov    %ebp,%edx
  8010f7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8010fb:	75 33                	jne    801130 <__udivdi3+0x60>
  8010fd:	39 e9                	cmp    %ebp,%ecx
  8010ff:	77 6f                	ja     801170 <__udivdi3+0xa0>
  801101:	85 c9                	test   %ecx,%ecx
  801103:	89 ce                	mov    %ecx,%esi
  801105:	75 0b                	jne    801112 <__udivdi3+0x42>
  801107:	b8 01 00 00 00       	mov    $0x1,%eax
  80110c:	31 d2                	xor    %edx,%edx
  80110e:	f7 f1                	div    %ecx
  801110:	89 c6                	mov    %eax,%esi
  801112:	31 d2                	xor    %edx,%edx
  801114:	89 e8                	mov    %ebp,%eax
  801116:	f7 f6                	div    %esi
  801118:	89 c5                	mov    %eax,%ebp
  80111a:	89 f8                	mov    %edi,%eax
  80111c:	f7 f6                	div    %esi
  80111e:	89 ea                	mov    %ebp,%edx
  801120:	8b 74 24 10          	mov    0x10(%esp),%esi
  801124:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801128:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  80112c:	83 c4 1c             	add    $0x1c,%esp
  80112f:	c3                   	ret    
  801130:	39 e8                	cmp    %ebp,%eax
  801132:	77 24                	ja     801158 <__udivdi3+0x88>
  801134:	0f bd c8             	bsr    %eax,%ecx
  801137:	83 f1 1f             	xor    $0x1f,%ecx
  80113a:	89 0c 24             	mov    %ecx,(%esp)
  80113d:	75 49                	jne    801188 <__udivdi3+0xb8>
  80113f:	8b 74 24 08          	mov    0x8(%esp),%esi
  801143:	39 74 24 04          	cmp    %esi,0x4(%esp)
  801147:	0f 86 ab 00 00 00    	jbe    8011f8 <__udivdi3+0x128>
  80114d:	39 e8                	cmp    %ebp,%eax
  80114f:	0f 82 a3 00 00 00    	jb     8011f8 <__udivdi3+0x128>
  801155:	8d 76 00             	lea    0x0(%esi),%esi
  801158:	31 d2                	xor    %edx,%edx
  80115a:	31 c0                	xor    %eax,%eax
  80115c:	8b 74 24 10          	mov    0x10(%esp),%esi
  801160:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801164:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801168:	83 c4 1c             	add    $0x1c,%esp
  80116b:	c3                   	ret    
  80116c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801170:	89 f8                	mov    %edi,%eax
  801172:	f7 f1                	div    %ecx
  801174:	31 d2                	xor    %edx,%edx
  801176:	8b 74 24 10          	mov    0x10(%esp),%esi
  80117a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  80117e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801182:	83 c4 1c             	add    $0x1c,%esp
  801185:	c3                   	ret    
  801186:	66 90                	xchg   %ax,%ax
  801188:	0f b6 0c 24          	movzbl (%esp),%ecx
  80118c:	89 c6                	mov    %eax,%esi
  80118e:	b8 20 00 00 00       	mov    $0x20,%eax
  801193:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  801197:	2b 04 24             	sub    (%esp),%eax
  80119a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  80119e:	d3 e6                	shl    %cl,%esi
  8011a0:	89 c1                	mov    %eax,%ecx
  8011a2:	d3 ed                	shr    %cl,%ebp
  8011a4:	0f b6 0c 24          	movzbl (%esp),%ecx
  8011a8:	09 f5                	or     %esi,%ebp
  8011aa:	8b 74 24 04          	mov    0x4(%esp),%esi
  8011ae:	d3 e6                	shl    %cl,%esi
  8011b0:	89 c1                	mov    %eax,%ecx
  8011b2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8011b6:	89 d6                	mov    %edx,%esi
  8011b8:	d3 ee                	shr    %cl,%esi
  8011ba:	0f b6 0c 24          	movzbl (%esp),%ecx
  8011be:	d3 e2                	shl    %cl,%edx
  8011c0:	89 c1                	mov    %eax,%ecx
  8011c2:	d3 ef                	shr    %cl,%edi
  8011c4:	09 d7                	or     %edx,%edi
  8011c6:	89 f2                	mov    %esi,%edx
  8011c8:	89 f8                	mov    %edi,%eax
  8011ca:	f7 f5                	div    %ebp
  8011cc:	89 d6                	mov    %edx,%esi
  8011ce:	89 c7                	mov    %eax,%edi
  8011d0:	f7 64 24 04          	mull   0x4(%esp)
  8011d4:	39 d6                	cmp    %edx,%esi
  8011d6:	72 30                	jb     801208 <__udivdi3+0x138>
  8011d8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  8011dc:	0f b6 0c 24          	movzbl (%esp),%ecx
  8011e0:	d3 e5                	shl    %cl,%ebp
  8011e2:	39 c5                	cmp    %eax,%ebp
  8011e4:	73 04                	jae    8011ea <__udivdi3+0x11a>
  8011e6:	39 d6                	cmp    %edx,%esi
  8011e8:	74 1e                	je     801208 <__udivdi3+0x138>
  8011ea:	89 f8                	mov    %edi,%eax
  8011ec:	31 d2                	xor    %edx,%edx
  8011ee:	e9 69 ff ff ff       	jmp    80115c <__udivdi3+0x8c>
  8011f3:	90                   	nop
  8011f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8011f8:	31 d2                	xor    %edx,%edx
  8011fa:	b8 01 00 00 00       	mov    $0x1,%eax
  8011ff:	e9 58 ff ff ff       	jmp    80115c <__udivdi3+0x8c>
  801204:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801208:	8d 47 ff             	lea    -0x1(%edi),%eax
  80120b:	31 d2                	xor    %edx,%edx
  80120d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801211:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801215:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801219:	83 c4 1c             	add    $0x1c,%esp
  80121c:	c3                   	ret    
  80121d:	66 90                	xchg   %ax,%ax
  80121f:	90                   	nop

00801220 <__umoddi3>:
  801220:	83 ec 2c             	sub    $0x2c,%esp
  801223:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  801227:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80122b:	89 74 24 20          	mov    %esi,0x20(%esp)
  80122f:	8b 74 24 38          	mov    0x38(%esp),%esi
  801233:	89 7c 24 24          	mov    %edi,0x24(%esp)
  801237:	8b 7c 24 34          	mov    0x34(%esp),%edi
  80123b:	85 c0                	test   %eax,%eax
  80123d:	89 c2                	mov    %eax,%edx
  80123f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  801243:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  801247:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80124b:	89 74 24 10          	mov    %esi,0x10(%esp)
  80124f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  801253:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801257:	75 1f                	jne    801278 <__umoddi3+0x58>
  801259:	39 fe                	cmp    %edi,%esi
  80125b:	76 63                	jbe    8012c0 <__umoddi3+0xa0>
  80125d:	89 c8                	mov    %ecx,%eax
  80125f:	89 fa                	mov    %edi,%edx
  801261:	f7 f6                	div    %esi
  801263:	89 d0                	mov    %edx,%eax
  801265:	31 d2                	xor    %edx,%edx
  801267:	8b 74 24 20          	mov    0x20(%esp),%esi
  80126b:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80126f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801273:	83 c4 2c             	add    $0x2c,%esp
  801276:	c3                   	ret    
  801277:	90                   	nop
  801278:	39 f8                	cmp    %edi,%eax
  80127a:	77 64                	ja     8012e0 <__umoddi3+0xc0>
  80127c:	0f bd e8             	bsr    %eax,%ebp
  80127f:	83 f5 1f             	xor    $0x1f,%ebp
  801282:	75 74                	jne    8012f8 <__umoddi3+0xd8>
  801284:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801288:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  80128c:	0f 87 0e 01 00 00    	ja     8013a0 <__umoddi3+0x180>
  801292:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  801296:	29 f1                	sub    %esi,%ecx
  801298:	19 c7                	sbb    %eax,%edi
  80129a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  80129e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8012a2:	8b 44 24 14          	mov    0x14(%esp),%eax
  8012a6:	8b 54 24 18          	mov    0x18(%esp),%edx
  8012aa:	8b 74 24 20          	mov    0x20(%esp),%esi
  8012ae:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8012b2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8012b6:	83 c4 2c             	add    $0x2c,%esp
  8012b9:	c3                   	ret    
  8012ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8012c0:	85 f6                	test   %esi,%esi
  8012c2:	89 f5                	mov    %esi,%ebp
  8012c4:	75 0b                	jne    8012d1 <__umoddi3+0xb1>
  8012c6:	b8 01 00 00 00       	mov    $0x1,%eax
  8012cb:	31 d2                	xor    %edx,%edx
  8012cd:	f7 f6                	div    %esi
  8012cf:	89 c5                	mov    %eax,%ebp
  8012d1:	8b 44 24 0c          	mov    0xc(%esp),%eax
  8012d5:	31 d2                	xor    %edx,%edx
  8012d7:	f7 f5                	div    %ebp
  8012d9:	89 c8                	mov    %ecx,%eax
  8012db:	f7 f5                	div    %ebp
  8012dd:	eb 84                	jmp    801263 <__umoddi3+0x43>
  8012df:	90                   	nop
  8012e0:	89 c8                	mov    %ecx,%eax
  8012e2:	89 fa                	mov    %edi,%edx
  8012e4:	8b 74 24 20          	mov    0x20(%esp),%esi
  8012e8:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8012ec:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8012f0:	83 c4 2c             	add    $0x2c,%esp
  8012f3:	c3                   	ret    
  8012f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8012f8:	8b 44 24 10          	mov    0x10(%esp),%eax
  8012fc:	be 20 00 00 00       	mov    $0x20,%esi
  801301:	89 e9                	mov    %ebp,%ecx
  801303:	29 ee                	sub    %ebp,%esi
  801305:	d3 e2                	shl    %cl,%edx
  801307:	89 f1                	mov    %esi,%ecx
  801309:	d3 e8                	shr    %cl,%eax
  80130b:	89 e9                	mov    %ebp,%ecx
  80130d:	09 d0                	or     %edx,%eax
  80130f:	89 fa                	mov    %edi,%edx
  801311:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801315:	8b 44 24 10          	mov    0x10(%esp),%eax
  801319:	d3 e0                	shl    %cl,%eax
  80131b:	89 f1                	mov    %esi,%ecx
  80131d:	89 44 24 10          	mov    %eax,0x10(%esp)
  801321:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  801325:	d3 ea                	shr    %cl,%edx
  801327:	89 e9                	mov    %ebp,%ecx
  801329:	d3 e7                	shl    %cl,%edi
  80132b:	89 f1                	mov    %esi,%ecx
  80132d:	d3 e8                	shr    %cl,%eax
  80132f:	89 e9                	mov    %ebp,%ecx
  801331:	09 f8                	or     %edi,%eax
  801333:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  801337:	f7 74 24 0c          	divl   0xc(%esp)
  80133b:	d3 e7                	shl    %cl,%edi
  80133d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801341:	89 d7                	mov    %edx,%edi
  801343:	f7 64 24 10          	mull   0x10(%esp)
  801347:	39 d7                	cmp    %edx,%edi
  801349:	89 c1                	mov    %eax,%ecx
  80134b:	89 54 24 14          	mov    %edx,0x14(%esp)
  80134f:	72 3b                	jb     80138c <__umoddi3+0x16c>
  801351:	39 44 24 18          	cmp    %eax,0x18(%esp)
  801355:	72 31                	jb     801388 <__umoddi3+0x168>
  801357:	8b 44 24 18          	mov    0x18(%esp),%eax
  80135b:	29 c8                	sub    %ecx,%eax
  80135d:	19 d7                	sbb    %edx,%edi
  80135f:	89 e9                	mov    %ebp,%ecx
  801361:	89 fa                	mov    %edi,%edx
  801363:	d3 e8                	shr    %cl,%eax
  801365:	89 f1                	mov    %esi,%ecx
  801367:	d3 e2                	shl    %cl,%edx
  801369:	89 e9                	mov    %ebp,%ecx
  80136b:	09 d0                	or     %edx,%eax
  80136d:	89 fa                	mov    %edi,%edx
  80136f:	d3 ea                	shr    %cl,%edx
  801371:	8b 74 24 20          	mov    0x20(%esp),%esi
  801375:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801379:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  80137d:	83 c4 2c             	add    $0x2c,%esp
  801380:	c3                   	ret    
  801381:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801388:	39 d7                	cmp    %edx,%edi
  80138a:	75 cb                	jne    801357 <__umoddi3+0x137>
  80138c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801390:	89 c1                	mov    %eax,%ecx
  801392:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801396:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80139a:	eb bb                	jmp    801357 <__umoddi3+0x137>
  80139c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8013a0:	3b 44 24 18          	cmp    0x18(%esp),%eax
  8013a4:	0f 82 e8 fe ff ff    	jb     801292 <__umoddi3+0x72>
  8013aa:	e9 f3 fe ff ff       	jmp    8012a2 <__umoddi3+0x82>


obj/user/spin：     文件格式 elf32-i386


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
  80002c:	e8 8f 00 00 00       	call   8000c0 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	66 90                	xchg   %ax,%ax
  800035:	66 90                	xchg   %ax,%ax
  800037:	66 90                	xchg   %ax,%ax
  800039:	66 90                	xchg   %ax,%ax
  80003b:	66 90                	xchg   %ax,%ax
  80003d:	66 90                	xchg   %ax,%ax
  80003f:	90                   	nop

00800040 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	53                   	push   %ebx
  800044:	83 ec 14             	sub    $0x14,%esp
	envid_t env;

	cprintf("I am the parent.  Forking the child...\n");
  800047:	c7 04 24 00 17 80 00 	movl   $0x801700,(%esp)
  80004e:	e8 98 01 00 00       	call   8001eb <cprintf>
	if ((env = fork()) == 0) {
  800053:	e8 77 10 00 00       	call   8010cf <fork>
  800058:	89 c3                	mov    %eax,%ebx
  80005a:	85 c0                	test   %eax,%eax
  80005c:	75 0e                	jne    80006c <umain+0x2c>
		cprintf("I am the child.  Spinning...\n");
  80005e:	c7 04 24 78 17 80 00 	movl   $0x801778,(%esp)
  800065:	e8 81 01 00 00       	call   8001eb <cprintf>
  80006a:	eb fe                	jmp    80006a <umain+0x2a>
		while (1)
			/* do nothing */;
	}

	cprintf("I am the parent.  Running the child...\n");
  80006c:	c7 04 24 28 17 80 00 	movl   $0x801728,(%esp)
  800073:	e8 73 01 00 00       	call   8001eb <cprintf>
	sys_yield();
  800078:	e8 df 0c 00 00       	call   800d5c <sys_yield>
	sys_yield();
  80007d:	e8 da 0c 00 00       	call   800d5c <sys_yield>
	sys_yield();
  800082:	e8 d5 0c 00 00       	call   800d5c <sys_yield>
	sys_yield();
  800087:	e8 d0 0c 00 00       	call   800d5c <sys_yield>
	sys_yield();
  80008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800090:	e8 c7 0c 00 00       	call   800d5c <sys_yield>
	sys_yield();
  800095:	e8 c2 0c 00 00       	call   800d5c <sys_yield>
	sys_yield();
  80009a:	e8 bd 0c 00 00       	call   800d5c <sys_yield>
	sys_yield();
  80009f:	90                   	nop
  8000a0:	e8 b7 0c 00 00       	call   800d5c <sys_yield>

	cprintf("I am the parent.  Killing the child...\n");
  8000a5:	c7 04 24 50 17 80 00 	movl   $0x801750,(%esp)
  8000ac:	e8 3a 01 00 00       	call   8001eb <cprintf>
	sys_env_destroy(env);
  8000b1:	89 1c 24             	mov    %ebx,(%esp)
  8000b4:	e8 16 0c 00 00       	call   800ccf <sys_env_destroy>
}
  8000b9:	83 c4 14             	add    $0x14,%esp
  8000bc:	5b                   	pop    %ebx
  8000bd:	5d                   	pop    %ebp
  8000be:	c3                   	ret    
  8000bf:	90                   	nop

008000c0 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000c0:	55                   	push   %ebp
  8000c1:	89 e5                	mov    %esp,%ebp
  8000c3:	57                   	push   %edi
  8000c4:	56                   	push   %esi
  8000c5:	53                   	push   %ebx
  8000c6:	83 ec 1c             	sub    $0x1c,%esp
  8000c9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000cc:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  8000cf:	e8 58 0c 00 00       	call   800d2c <sys_getenvid>
	thisenv = envs;
  8000d4:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  8000db:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  8000de:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  8000e4:	39 c2                	cmp    %eax,%edx
  8000e6:	74 25                	je     80010d <libmain+0x4d>
  8000e8:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  8000ed:	eb 12                	jmp    800101 <libmain+0x41>
  8000ef:	8b 4a 48             	mov    0x48(%edx),%ecx
  8000f2:	83 c2 7c             	add    $0x7c,%edx
  8000f5:	39 c1                	cmp    %eax,%ecx
  8000f7:	75 08                	jne    800101 <libmain+0x41>
  8000f9:	89 3d 04 20 80 00    	mov    %edi,0x802004
  8000ff:	eb 0c                	jmp    80010d <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  800101:	89 d7                	mov    %edx,%edi
  800103:	85 d2                	test   %edx,%edx
  800105:	75 e8                	jne    8000ef <libmain+0x2f>
  800107:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80010d:	85 db                	test   %ebx,%ebx
  80010f:	7e 07                	jle    800118 <libmain+0x58>
		binaryname = argv[0];
  800111:	8b 06                	mov    (%esi),%eax
  800113:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800118:	89 74 24 04          	mov    %esi,0x4(%esp)
  80011c:	89 1c 24             	mov    %ebx,(%esp)
  80011f:	e8 1c ff ff ff       	call   800040 <umain>

	// exit gracefully
	exit();
  800124:	e8 0b 00 00 00       	call   800134 <exit>
}
  800129:	83 c4 1c             	add    $0x1c,%esp
  80012c:	5b                   	pop    %ebx
  80012d:	5e                   	pop    %esi
  80012e:	5f                   	pop    %edi
  80012f:	5d                   	pop    %ebp
  800130:	c3                   	ret    
  800131:	66 90                	xchg   %ax,%ax
  800133:	90                   	nop

00800134 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800134:	55                   	push   %ebp
  800135:	89 e5                	mov    %esp,%ebp
  800137:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80013a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800141:	e8 89 0b 00 00       	call   800ccf <sys_env_destroy>
}
  800146:	c9                   	leave  
  800147:	c3                   	ret    

00800148 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800148:	55                   	push   %ebp
  800149:	89 e5                	mov    %esp,%ebp
  80014b:	53                   	push   %ebx
  80014c:	83 ec 14             	sub    $0x14,%esp
  80014f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800152:	8b 03                	mov    (%ebx),%eax
  800154:	8b 55 08             	mov    0x8(%ebp),%edx
  800157:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  80015b:	83 c0 01             	add    $0x1,%eax
  80015e:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800160:	3d ff 00 00 00       	cmp    $0xff,%eax
  800165:	75 19                	jne    800180 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800167:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80016e:	00 
  80016f:	8d 43 08             	lea    0x8(%ebx),%eax
  800172:	89 04 24             	mov    %eax,(%esp)
  800175:	e8 f6 0a 00 00       	call   800c70 <sys_cputs>
		b->idx = 0;
  80017a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800180:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800184:	83 c4 14             	add    $0x14,%esp
  800187:	5b                   	pop    %ebx
  800188:	5d                   	pop    %ebp
  800189:	c3                   	ret    

0080018a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80018a:	55                   	push   %ebp
  80018b:	89 e5                	mov    %esp,%ebp
  80018d:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800193:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80019a:	00 00 00 
	b.cnt = 0;
  80019d:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001a4:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001a7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001aa:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001ae:	8b 45 08             	mov    0x8(%ebp),%eax
  8001b1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001b5:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001bf:	c7 04 24 48 01 80 00 	movl   $0x800148,(%esp)
  8001c6:	e8 b7 01 00 00       	call   800382 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001cb:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8001d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001d5:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001db:	89 04 24             	mov    %eax,(%esp)
  8001de:	e8 8d 0a 00 00       	call   800c70 <sys_cputs>

	return b.cnt;
}
  8001e3:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001e9:	c9                   	leave  
  8001ea:	c3                   	ret    

008001eb <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001eb:	55                   	push   %ebp
  8001ec:	89 e5                	mov    %esp,%ebp
  8001ee:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001f1:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8001f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001f8:	8b 45 08             	mov    0x8(%ebp),%eax
  8001fb:	89 04 24             	mov    %eax,(%esp)
  8001fe:	e8 87 ff ff ff       	call   80018a <vcprintf>
	va_end(ap);

	return cnt;
}
  800203:	c9                   	leave  
  800204:	c3                   	ret    
  800205:	66 90                	xchg   %ax,%ax
  800207:	66 90                	xchg   %ax,%ax
  800209:	66 90                	xchg   %ax,%ax
  80020b:	66 90                	xchg   %ax,%ax
  80020d:	66 90                	xchg   %ax,%ax
  80020f:	90                   	nop

00800210 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800210:	55                   	push   %ebp
  800211:	89 e5                	mov    %esp,%ebp
  800213:	57                   	push   %edi
  800214:	56                   	push   %esi
  800215:	53                   	push   %ebx
  800216:	83 ec 4c             	sub    $0x4c,%esp
  800219:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80021c:	89 d7                	mov    %edx,%edi
  80021e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800221:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800224:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800227:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80022a:	b8 00 00 00 00       	mov    $0x0,%eax
  80022f:	39 d8                	cmp    %ebx,%eax
  800231:	72 17                	jb     80024a <printnum+0x3a>
  800233:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800236:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800239:	76 0f                	jbe    80024a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80023b:	8b 75 14             	mov    0x14(%ebp),%esi
  80023e:	83 ee 01             	sub    $0x1,%esi
  800241:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800244:	85 f6                	test   %esi,%esi
  800246:	7f 63                	jg     8002ab <printnum+0x9b>
  800248:	eb 75                	jmp    8002bf <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80024a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80024d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800251:	8b 45 14             	mov    0x14(%ebp),%eax
  800254:	83 e8 01             	sub    $0x1,%eax
  800257:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80025b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80025e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800262:	8b 44 24 08          	mov    0x8(%esp),%eax
  800266:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80026a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80026d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800270:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800277:	00 
  800278:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80027b:	89 1c 24             	mov    %ebx,(%esp)
  80027e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800281:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800285:	e8 86 11 00 00       	call   801410 <__udivdi3>
  80028a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80028d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800290:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800294:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800298:	89 04 24             	mov    %eax,(%esp)
  80029b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80029f:	89 fa                	mov    %edi,%edx
  8002a1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002a4:	e8 67 ff ff ff       	call   800210 <printnum>
  8002a9:	eb 14                	jmp    8002bf <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002ab:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002af:	8b 45 18             	mov    0x18(%ebp),%eax
  8002b2:	89 04 24             	mov    %eax,(%esp)
  8002b5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002b7:	83 ee 01             	sub    $0x1,%esi
  8002ba:	75 ef                	jne    8002ab <printnum+0x9b>
  8002bc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002bf:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002c3:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8002c7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002ca:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8002ce:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8002d5:	00 
  8002d6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002d9:	89 1c 24             	mov    %ebx,(%esp)
  8002dc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8002df:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002e3:	e8 78 12 00 00       	call   801560 <__umoddi3>
  8002e8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002ec:	0f be 80 a0 17 80 00 	movsbl 0x8017a0(%eax),%eax
  8002f3:	89 04 24             	mov    %eax,(%esp)
  8002f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002f9:	ff d0                	call   *%eax
}
  8002fb:	83 c4 4c             	add    $0x4c,%esp
  8002fe:	5b                   	pop    %ebx
  8002ff:	5e                   	pop    %esi
  800300:	5f                   	pop    %edi
  800301:	5d                   	pop    %ebp
  800302:	c3                   	ret    

00800303 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800303:	55                   	push   %ebp
  800304:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800306:	83 fa 01             	cmp    $0x1,%edx
  800309:	7e 0e                	jle    800319 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80030b:	8b 10                	mov    (%eax),%edx
  80030d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800310:	89 08                	mov    %ecx,(%eax)
  800312:	8b 02                	mov    (%edx),%eax
  800314:	8b 52 04             	mov    0x4(%edx),%edx
  800317:	eb 22                	jmp    80033b <getuint+0x38>
	else if (lflag)
  800319:	85 d2                	test   %edx,%edx
  80031b:	74 10                	je     80032d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80031d:	8b 10                	mov    (%eax),%edx
  80031f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800322:	89 08                	mov    %ecx,(%eax)
  800324:	8b 02                	mov    (%edx),%eax
  800326:	ba 00 00 00 00       	mov    $0x0,%edx
  80032b:	eb 0e                	jmp    80033b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80032d:	8b 10                	mov    (%eax),%edx
  80032f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800332:	89 08                	mov    %ecx,(%eax)
  800334:	8b 02                	mov    (%edx),%eax
  800336:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80033b:	5d                   	pop    %ebp
  80033c:	c3                   	ret    

0080033d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80033d:	55                   	push   %ebp
  80033e:	89 e5                	mov    %esp,%ebp
  800340:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800343:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800347:	8b 10                	mov    (%eax),%edx
  800349:	3b 50 04             	cmp    0x4(%eax),%edx
  80034c:	73 0a                	jae    800358 <sprintputch+0x1b>
		*b->buf++ = ch;
  80034e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800351:	88 0a                	mov    %cl,(%edx)
  800353:	83 c2 01             	add    $0x1,%edx
  800356:	89 10                	mov    %edx,(%eax)
}
  800358:	5d                   	pop    %ebp
  800359:	c3                   	ret    

0080035a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80035a:	55                   	push   %ebp
  80035b:	89 e5                	mov    %esp,%ebp
  80035d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800360:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800363:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800367:	8b 45 10             	mov    0x10(%ebp),%eax
  80036a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80036e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800371:	89 44 24 04          	mov    %eax,0x4(%esp)
  800375:	8b 45 08             	mov    0x8(%ebp),%eax
  800378:	89 04 24             	mov    %eax,(%esp)
  80037b:	e8 02 00 00 00       	call   800382 <vprintfmt>
	va_end(ap);
}
  800380:	c9                   	leave  
  800381:	c3                   	ret    

00800382 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800382:	55                   	push   %ebp
  800383:	89 e5                	mov    %esp,%ebp
  800385:	57                   	push   %edi
  800386:	56                   	push   %esi
  800387:	53                   	push   %ebx
  800388:	83 ec 4c             	sub    $0x4c,%esp
  80038b:	8b 75 08             	mov    0x8(%ebp),%esi
  80038e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800391:	8b 7d 10             	mov    0x10(%ebp),%edi
  800394:	eb 11                	jmp    8003a7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800396:	85 c0                	test   %eax,%eax
  800398:	0f 84 db 03 00 00    	je     800779 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80039e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003a2:	89 04 24             	mov    %eax,(%esp)
  8003a5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003a7:	0f b6 07             	movzbl (%edi),%eax
  8003aa:	83 c7 01             	add    $0x1,%edi
  8003ad:	83 f8 25             	cmp    $0x25,%eax
  8003b0:	75 e4                	jne    800396 <vprintfmt+0x14>
  8003b2:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  8003b6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  8003bd:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8003c4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  8003cb:	ba 00 00 00 00       	mov    $0x0,%edx
  8003d0:	eb 2b                	jmp    8003fd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003d5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  8003d9:	eb 22                	jmp    8003fd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003db:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003de:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  8003e2:	eb 19                	jmp    8003fd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  8003e7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003ee:	eb 0d                	jmp    8003fd <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8003f0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8003f3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8003f6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fd:	0f b6 0f             	movzbl (%edi),%ecx
  800400:	8d 47 01             	lea    0x1(%edi),%eax
  800403:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800406:	0f b6 07             	movzbl (%edi),%eax
  800409:	83 e8 23             	sub    $0x23,%eax
  80040c:	3c 55                	cmp    $0x55,%al
  80040e:	0f 87 40 03 00 00    	ja     800754 <vprintfmt+0x3d2>
  800414:	0f b6 c0             	movzbl %al,%eax
  800417:	ff 24 85 60 18 80 00 	jmp    *0x801860(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80041e:	83 e9 30             	sub    $0x30,%ecx
  800421:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800424:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800428:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80042b:	83 f9 09             	cmp    $0x9,%ecx
  80042e:	77 57                	ja     800487 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800430:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800433:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800436:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800439:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80043c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80043f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800443:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800446:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800449:	83 f9 09             	cmp    $0x9,%ecx
  80044c:	76 eb                	jbe    800439 <vprintfmt+0xb7>
  80044e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800451:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800454:	eb 34                	jmp    80048a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800456:	8b 45 14             	mov    0x14(%ebp),%eax
  800459:	8d 48 04             	lea    0x4(%eax),%ecx
  80045c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80045f:	8b 00                	mov    (%eax),%eax
  800461:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800464:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800467:	eb 21                	jmp    80048a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800469:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80046d:	0f 88 71 ff ff ff    	js     8003e4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800473:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800476:	eb 85                	jmp    8003fd <vprintfmt+0x7b>
  800478:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80047b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800482:	e9 76 ff ff ff       	jmp    8003fd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800487:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80048a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80048e:	0f 89 69 ff ff ff    	jns    8003fd <vprintfmt+0x7b>
  800494:	e9 57 ff ff ff       	jmp    8003f0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800499:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80049c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80049f:	e9 59 ff ff ff       	jmp    8003fd <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a7:	8d 50 04             	lea    0x4(%eax),%edx
  8004aa:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004b1:	8b 00                	mov    (%eax),%eax
  8004b3:	89 04 24             	mov    %eax,(%esp)
  8004b6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004bb:	e9 e7 fe ff ff       	jmp    8003a7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004c0:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c3:	8d 50 04             	lea    0x4(%eax),%edx
  8004c6:	89 55 14             	mov    %edx,0x14(%ebp)
  8004c9:	8b 00                	mov    (%eax),%eax
  8004cb:	89 c2                	mov    %eax,%edx
  8004cd:	c1 fa 1f             	sar    $0x1f,%edx
  8004d0:	31 d0                	xor    %edx,%eax
  8004d2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004d4:	83 f8 08             	cmp    $0x8,%eax
  8004d7:	7f 0b                	jg     8004e4 <vprintfmt+0x162>
  8004d9:	8b 14 85 c0 19 80 00 	mov    0x8019c0(,%eax,4),%edx
  8004e0:	85 d2                	test   %edx,%edx
  8004e2:	75 20                	jne    800504 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  8004e4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8004e8:	c7 44 24 08 b8 17 80 	movl   $0x8017b8,0x8(%esp)
  8004ef:	00 
  8004f0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004f4:	89 34 24             	mov    %esi,(%esp)
  8004f7:	e8 5e fe ff ff       	call   80035a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004fc:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004ff:	e9 a3 fe ff ff       	jmp    8003a7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800504:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800508:	c7 44 24 08 c1 17 80 	movl   $0x8017c1,0x8(%esp)
  80050f:	00 
  800510:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800514:	89 34 24             	mov    %esi,(%esp)
  800517:	e8 3e fe ff ff       	call   80035a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80051c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80051f:	e9 83 fe ff ff       	jmp    8003a7 <vprintfmt+0x25>
  800524:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800527:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80052a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80052d:	8b 45 14             	mov    0x14(%ebp),%eax
  800530:	8d 50 04             	lea    0x4(%eax),%edx
  800533:	89 55 14             	mov    %edx,0x14(%ebp)
  800536:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800538:	85 ff                	test   %edi,%edi
  80053a:	b8 b1 17 80 00       	mov    $0x8017b1,%eax
  80053f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800542:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800546:	74 06                	je     80054e <vprintfmt+0x1cc>
  800548:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  80054c:	7f 16                	jg     800564 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80054e:	0f b6 17             	movzbl (%edi),%edx
  800551:	0f be c2             	movsbl %dl,%eax
  800554:	83 c7 01             	add    $0x1,%edi
  800557:	85 c0                	test   %eax,%eax
  800559:	0f 85 9f 00 00 00    	jne    8005fe <vprintfmt+0x27c>
  80055f:	e9 8b 00 00 00       	jmp    8005ef <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800564:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800568:	89 3c 24             	mov    %edi,(%esp)
  80056b:	e8 c2 02 00 00       	call   800832 <strnlen>
  800570:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800573:	29 c2                	sub    %eax,%edx
  800575:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800578:	85 d2                	test   %edx,%edx
  80057a:	7e d2                	jle    80054e <vprintfmt+0x1cc>
					putch(padc, putdat);
  80057c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800580:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800583:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800586:	89 d7                	mov    %edx,%edi
  800588:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80058c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80058f:	89 04 24             	mov    %eax,(%esp)
  800592:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800594:	83 ef 01             	sub    $0x1,%edi
  800597:	75 ef                	jne    800588 <vprintfmt+0x206>
  800599:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80059c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80059f:	eb ad                	jmp    80054e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005a1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8005a5:	74 20                	je     8005c7 <vprintfmt+0x245>
  8005a7:	0f be d2             	movsbl %dl,%edx
  8005aa:	83 ea 20             	sub    $0x20,%edx
  8005ad:	83 fa 5e             	cmp    $0x5e,%edx
  8005b0:	76 15                	jbe    8005c7 <vprintfmt+0x245>
					putch('?', putdat);
  8005b2:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8005b5:	89 54 24 04          	mov    %edx,0x4(%esp)
  8005b9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8005c0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8005c3:	ff d1                	call   *%ecx
  8005c5:	eb 0f                	jmp    8005d6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  8005c7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8005ca:	89 54 24 04          	mov    %edx,0x4(%esp)
  8005ce:	89 04 24             	mov    %eax,(%esp)
  8005d1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8005d4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005d6:	83 eb 01             	sub    $0x1,%ebx
  8005d9:	0f b6 17             	movzbl (%edi),%edx
  8005dc:	0f be c2             	movsbl %dl,%eax
  8005df:	83 c7 01             	add    $0x1,%edi
  8005e2:	85 c0                	test   %eax,%eax
  8005e4:	75 24                	jne    80060a <vprintfmt+0x288>
  8005e6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005e9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8005ec:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ef:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005f2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8005f6:	0f 8e ab fd ff ff    	jle    8003a7 <vprintfmt+0x25>
  8005fc:	eb 20                	jmp    80061e <vprintfmt+0x29c>
  8005fe:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800601:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800604:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800607:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80060a:	85 f6                	test   %esi,%esi
  80060c:	78 93                	js     8005a1 <vprintfmt+0x21f>
  80060e:	83 ee 01             	sub    $0x1,%esi
  800611:	79 8e                	jns    8005a1 <vprintfmt+0x21f>
  800613:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800616:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800619:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80061c:	eb d1                	jmp    8005ef <vprintfmt+0x26d>
  80061e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800621:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800625:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80062c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80062e:	83 ef 01             	sub    $0x1,%edi
  800631:	75 ee                	jne    800621 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800633:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800636:	e9 6c fd ff ff       	jmp    8003a7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80063b:	83 fa 01             	cmp    $0x1,%edx
  80063e:	66 90                	xchg   %ax,%ax
  800640:	7e 16                	jle    800658 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800642:	8b 45 14             	mov    0x14(%ebp),%eax
  800645:	8d 50 08             	lea    0x8(%eax),%edx
  800648:	89 55 14             	mov    %edx,0x14(%ebp)
  80064b:	8b 10                	mov    (%eax),%edx
  80064d:	8b 48 04             	mov    0x4(%eax),%ecx
  800650:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800653:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800656:	eb 32                	jmp    80068a <vprintfmt+0x308>
	else if (lflag)
  800658:	85 d2                	test   %edx,%edx
  80065a:	74 18                	je     800674 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  80065c:	8b 45 14             	mov    0x14(%ebp),%eax
  80065f:	8d 50 04             	lea    0x4(%eax),%edx
  800662:	89 55 14             	mov    %edx,0x14(%ebp)
  800665:	8b 00                	mov    (%eax),%eax
  800667:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80066a:	89 c1                	mov    %eax,%ecx
  80066c:	c1 f9 1f             	sar    $0x1f,%ecx
  80066f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800672:	eb 16                	jmp    80068a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800674:	8b 45 14             	mov    0x14(%ebp),%eax
  800677:	8d 50 04             	lea    0x4(%eax),%edx
  80067a:	89 55 14             	mov    %edx,0x14(%ebp)
  80067d:	8b 00                	mov    (%eax),%eax
  80067f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800682:	89 c7                	mov    %eax,%edi
  800684:	c1 ff 1f             	sar    $0x1f,%edi
  800687:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80068a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80068d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800690:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800695:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800699:	79 7d                	jns    800718 <vprintfmt+0x396>
				putch('-', putdat);
  80069b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80069f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006a6:	ff d6                	call   *%esi
				num = -(long long) num;
  8006a8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8006ab:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8006ae:	f7 d8                	neg    %eax
  8006b0:	83 d2 00             	adc    $0x0,%edx
  8006b3:	f7 da                	neg    %edx
			}
			base = 10;
  8006b5:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8006ba:	eb 5c                	jmp    800718 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006bc:	8d 45 14             	lea    0x14(%ebp),%eax
  8006bf:	e8 3f fc ff ff       	call   800303 <getuint>
			base = 10;
  8006c4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8006c9:	eb 4d                	jmp    800718 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  8006cb:	8d 45 14             	lea    0x14(%ebp),%eax
  8006ce:	e8 30 fc ff ff       	call   800303 <getuint>
			base = 8;
  8006d3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8006d8:	eb 3e                	jmp    800718 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  8006da:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006de:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8006e5:	ff d6                	call   *%esi
			putch('x', putdat);
  8006e7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006eb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8006f2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f7:	8d 50 04             	lea    0x4(%eax),%edx
  8006fa:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8006fd:	8b 00                	mov    (%eax),%eax
  8006ff:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800704:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800709:	eb 0d                	jmp    800718 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80070b:	8d 45 14             	lea    0x14(%ebp),%eax
  80070e:	e8 f0 fb ff ff       	call   800303 <getuint>
			base = 16;
  800713:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800718:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80071c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800720:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800723:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800727:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80072b:	89 04 24             	mov    %eax,(%esp)
  80072e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800732:	89 da                	mov    %ebx,%edx
  800734:	89 f0                	mov    %esi,%eax
  800736:	e8 d5 fa ff ff       	call   800210 <printnum>
			break;
  80073b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80073e:	e9 64 fc ff ff       	jmp    8003a7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800743:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800747:	89 0c 24             	mov    %ecx,(%esp)
  80074a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80074c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80074f:	e9 53 fc ff ff       	jmp    8003a7 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800754:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800758:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  80075f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800761:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800765:	0f 84 3c fc ff ff    	je     8003a7 <vprintfmt+0x25>
  80076b:	83 ef 01             	sub    $0x1,%edi
  80076e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800772:	75 f7                	jne    80076b <vprintfmt+0x3e9>
  800774:	e9 2e fc ff ff       	jmp    8003a7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800779:	83 c4 4c             	add    $0x4c,%esp
  80077c:	5b                   	pop    %ebx
  80077d:	5e                   	pop    %esi
  80077e:	5f                   	pop    %edi
  80077f:	5d                   	pop    %ebp
  800780:	c3                   	ret    

00800781 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800781:	55                   	push   %ebp
  800782:	89 e5                	mov    %esp,%ebp
  800784:	83 ec 28             	sub    $0x28,%esp
  800787:	8b 45 08             	mov    0x8(%ebp),%eax
  80078a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80078d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800790:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800794:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800797:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80079e:	85 d2                	test   %edx,%edx
  8007a0:	7e 30                	jle    8007d2 <vsnprintf+0x51>
  8007a2:	85 c0                	test   %eax,%eax
  8007a4:	74 2c                	je     8007d2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007a6:	8b 45 14             	mov    0x14(%ebp),%eax
  8007a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007ad:	8b 45 10             	mov    0x10(%ebp),%eax
  8007b0:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007b4:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007bb:	c7 04 24 3d 03 80 00 	movl   $0x80033d,(%esp)
  8007c2:	e8 bb fb ff ff       	call   800382 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007ca:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007d0:	eb 05                	jmp    8007d7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007d2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007d7:	c9                   	leave  
  8007d8:	c3                   	ret    

008007d9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007d9:	55                   	push   %ebp
  8007da:	89 e5                	mov    %esp,%ebp
  8007dc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007df:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007e2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007e6:	8b 45 10             	mov    0x10(%ebp),%eax
  8007e9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007ed:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007f0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007f4:	8b 45 08             	mov    0x8(%ebp),%eax
  8007f7:	89 04 24             	mov    %eax,(%esp)
  8007fa:	e8 82 ff ff ff       	call   800781 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007ff:	c9                   	leave  
  800800:	c3                   	ret    
  800801:	66 90                	xchg   %ax,%ax
  800803:	66 90                	xchg   %ax,%ax
  800805:	66 90                	xchg   %ax,%ax
  800807:	66 90                	xchg   %ax,%ax
  800809:	66 90                	xchg   %ax,%ax
  80080b:	66 90                	xchg   %ax,%ax
  80080d:	66 90                	xchg   %ax,%ax
  80080f:	90                   	nop

00800810 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800810:	55                   	push   %ebp
  800811:	89 e5                	mov    %esp,%ebp
  800813:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800816:	80 3a 00             	cmpb   $0x0,(%edx)
  800819:	74 10                	je     80082b <strlen+0x1b>
  80081b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800820:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800823:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800827:	75 f7                	jne    800820 <strlen+0x10>
  800829:	eb 05                	jmp    800830 <strlen+0x20>
  80082b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800830:	5d                   	pop    %ebp
  800831:	c3                   	ret    

00800832 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800832:	55                   	push   %ebp
  800833:	89 e5                	mov    %esp,%ebp
  800835:	53                   	push   %ebx
  800836:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800839:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80083c:	85 c9                	test   %ecx,%ecx
  80083e:	74 1c                	je     80085c <strnlen+0x2a>
  800840:	80 3b 00             	cmpb   $0x0,(%ebx)
  800843:	74 1e                	je     800863 <strnlen+0x31>
  800845:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80084a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80084c:	39 ca                	cmp    %ecx,%edx
  80084e:	74 18                	je     800868 <strnlen+0x36>
  800850:	83 c2 01             	add    $0x1,%edx
  800853:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800858:	75 f0                	jne    80084a <strnlen+0x18>
  80085a:	eb 0c                	jmp    800868 <strnlen+0x36>
  80085c:	b8 00 00 00 00       	mov    $0x0,%eax
  800861:	eb 05                	jmp    800868 <strnlen+0x36>
  800863:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800868:	5b                   	pop    %ebx
  800869:	5d                   	pop    %ebp
  80086a:	c3                   	ret    

0080086b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80086b:	55                   	push   %ebp
  80086c:	89 e5                	mov    %esp,%ebp
  80086e:	53                   	push   %ebx
  80086f:	8b 45 08             	mov    0x8(%ebp),%eax
  800872:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800875:	89 c2                	mov    %eax,%edx
  800877:	0f b6 19             	movzbl (%ecx),%ebx
  80087a:	88 1a                	mov    %bl,(%edx)
  80087c:	83 c2 01             	add    $0x1,%edx
  80087f:	83 c1 01             	add    $0x1,%ecx
  800882:	84 db                	test   %bl,%bl
  800884:	75 f1                	jne    800877 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800886:	5b                   	pop    %ebx
  800887:	5d                   	pop    %ebp
  800888:	c3                   	ret    

00800889 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800889:	55                   	push   %ebp
  80088a:	89 e5                	mov    %esp,%ebp
  80088c:	53                   	push   %ebx
  80088d:	83 ec 08             	sub    $0x8,%esp
  800890:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800893:	89 1c 24             	mov    %ebx,(%esp)
  800896:	e8 75 ff ff ff       	call   800810 <strlen>
	strcpy(dst + len, src);
  80089b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80089e:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008a2:	01 d8                	add    %ebx,%eax
  8008a4:	89 04 24             	mov    %eax,(%esp)
  8008a7:	e8 bf ff ff ff       	call   80086b <strcpy>
	return dst;
}
  8008ac:	89 d8                	mov    %ebx,%eax
  8008ae:	83 c4 08             	add    $0x8,%esp
  8008b1:	5b                   	pop    %ebx
  8008b2:	5d                   	pop    %ebp
  8008b3:	c3                   	ret    

008008b4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008b4:	55                   	push   %ebp
  8008b5:	89 e5                	mov    %esp,%ebp
  8008b7:	56                   	push   %esi
  8008b8:	53                   	push   %ebx
  8008b9:	8b 75 08             	mov    0x8(%ebp),%esi
  8008bc:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008bf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008c2:	85 db                	test   %ebx,%ebx
  8008c4:	74 16                	je     8008dc <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  8008c6:	01 f3                	add    %esi,%ebx
  8008c8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  8008ca:	0f b6 02             	movzbl (%edx),%eax
  8008cd:	88 01                	mov    %al,(%ecx)
  8008cf:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008d2:	80 3a 01             	cmpb   $0x1,(%edx)
  8008d5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008d8:	39 d9                	cmp    %ebx,%ecx
  8008da:	75 ee                	jne    8008ca <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008dc:	89 f0                	mov    %esi,%eax
  8008de:	5b                   	pop    %ebx
  8008df:	5e                   	pop    %esi
  8008e0:	5d                   	pop    %ebp
  8008e1:	c3                   	ret    

008008e2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008e2:	55                   	push   %ebp
  8008e3:	89 e5                	mov    %esp,%ebp
  8008e5:	57                   	push   %edi
  8008e6:	56                   	push   %esi
  8008e7:	53                   	push   %ebx
  8008e8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008eb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8008ee:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008f1:	89 f8                	mov    %edi,%eax
  8008f3:	85 f6                	test   %esi,%esi
  8008f5:	74 33                	je     80092a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  8008f7:	83 fe 01             	cmp    $0x1,%esi
  8008fa:	74 25                	je     800921 <strlcpy+0x3f>
  8008fc:	0f b6 0b             	movzbl (%ebx),%ecx
  8008ff:	84 c9                	test   %cl,%cl
  800901:	74 22                	je     800925 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800903:	83 ee 02             	sub    $0x2,%esi
  800906:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80090b:	88 08                	mov    %cl,(%eax)
  80090d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800910:	39 f2                	cmp    %esi,%edx
  800912:	74 13                	je     800927 <strlcpy+0x45>
  800914:	83 c2 01             	add    $0x1,%edx
  800917:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80091b:	84 c9                	test   %cl,%cl
  80091d:	75 ec                	jne    80090b <strlcpy+0x29>
  80091f:	eb 06                	jmp    800927 <strlcpy+0x45>
  800921:	89 f8                	mov    %edi,%eax
  800923:	eb 02                	jmp    800927 <strlcpy+0x45>
  800925:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800927:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80092a:	29 f8                	sub    %edi,%eax
}
  80092c:	5b                   	pop    %ebx
  80092d:	5e                   	pop    %esi
  80092e:	5f                   	pop    %edi
  80092f:	5d                   	pop    %ebp
  800930:	c3                   	ret    

00800931 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800931:	55                   	push   %ebp
  800932:	89 e5                	mov    %esp,%ebp
  800934:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800937:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80093a:	0f b6 01             	movzbl (%ecx),%eax
  80093d:	84 c0                	test   %al,%al
  80093f:	74 15                	je     800956 <strcmp+0x25>
  800941:	3a 02                	cmp    (%edx),%al
  800943:	75 11                	jne    800956 <strcmp+0x25>
		p++, q++;
  800945:	83 c1 01             	add    $0x1,%ecx
  800948:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80094b:	0f b6 01             	movzbl (%ecx),%eax
  80094e:	84 c0                	test   %al,%al
  800950:	74 04                	je     800956 <strcmp+0x25>
  800952:	3a 02                	cmp    (%edx),%al
  800954:	74 ef                	je     800945 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800956:	0f b6 c0             	movzbl %al,%eax
  800959:	0f b6 12             	movzbl (%edx),%edx
  80095c:	29 d0                	sub    %edx,%eax
}
  80095e:	5d                   	pop    %ebp
  80095f:	c3                   	ret    

00800960 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800960:	55                   	push   %ebp
  800961:	89 e5                	mov    %esp,%ebp
  800963:	56                   	push   %esi
  800964:	53                   	push   %ebx
  800965:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800968:	8b 55 0c             	mov    0xc(%ebp),%edx
  80096b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  80096e:	85 f6                	test   %esi,%esi
  800970:	74 29                	je     80099b <strncmp+0x3b>
  800972:	0f b6 03             	movzbl (%ebx),%eax
  800975:	84 c0                	test   %al,%al
  800977:	74 30                	je     8009a9 <strncmp+0x49>
  800979:	3a 02                	cmp    (%edx),%al
  80097b:	75 2c                	jne    8009a9 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  80097d:	8d 43 01             	lea    0x1(%ebx),%eax
  800980:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800982:	89 c3                	mov    %eax,%ebx
  800984:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800987:	39 f0                	cmp    %esi,%eax
  800989:	74 17                	je     8009a2 <strncmp+0x42>
  80098b:	0f b6 08             	movzbl (%eax),%ecx
  80098e:	84 c9                	test   %cl,%cl
  800990:	74 17                	je     8009a9 <strncmp+0x49>
  800992:	83 c0 01             	add    $0x1,%eax
  800995:	3a 0a                	cmp    (%edx),%cl
  800997:	74 e9                	je     800982 <strncmp+0x22>
  800999:	eb 0e                	jmp    8009a9 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  80099b:	b8 00 00 00 00       	mov    $0x0,%eax
  8009a0:	eb 0f                	jmp    8009b1 <strncmp+0x51>
  8009a2:	b8 00 00 00 00       	mov    $0x0,%eax
  8009a7:	eb 08                	jmp    8009b1 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009a9:	0f b6 03             	movzbl (%ebx),%eax
  8009ac:	0f b6 12             	movzbl (%edx),%edx
  8009af:	29 d0                	sub    %edx,%eax
}
  8009b1:	5b                   	pop    %ebx
  8009b2:	5e                   	pop    %esi
  8009b3:	5d                   	pop    %ebp
  8009b4:	c3                   	ret    

008009b5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009b5:	55                   	push   %ebp
  8009b6:	89 e5                	mov    %esp,%ebp
  8009b8:	53                   	push   %ebx
  8009b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009bc:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  8009bf:	0f b6 18             	movzbl (%eax),%ebx
  8009c2:	84 db                	test   %bl,%bl
  8009c4:	74 1d                	je     8009e3 <strchr+0x2e>
  8009c6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  8009c8:	38 d3                	cmp    %dl,%bl
  8009ca:	75 06                	jne    8009d2 <strchr+0x1d>
  8009cc:	eb 1a                	jmp    8009e8 <strchr+0x33>
  8009ce:	38 ca                	cmp    %cl,%dl
  8009d0:	74 16                	je     8009e8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009d2:	83 c0 01             	add    $0x1,%eax
  8009d5:	0f b6 10             	movzbl (%eax),%edx
  8009d8:	84 d2                	test   %dl,%dl
  8009da:	75 f2                	jne    8009ce <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  8009dc:	b8 00 00 00 00       	mov    $0x0,%eax
  8009e1:	eb 05                	jmp    8009e8 <strchr+0x33>
  8009e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009e8:	5b                   	pop    %ebx
  8009e9:	5d                   	pop    %ebp
  8009ea:	c3                   	ret    

008009eb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009eb:	55                   	push   %ebp
  8009ec:	89 e5                	mov    %esp,%ebp
  8009ee:	53                   	push   %ebx
  8009ef:	8b 45 08             	mov    0x8(%ebp),%eax
  8009f2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  8009f5:	0f b6 18             	movzbl (%eax),%ebx
  8009f8:	84 db                	test   %bl,%bl
  8009fa:	74 16                	je     800a12 <strfind+0x27>
  8009fc:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  8009fe:	38 d3                	cmp    %dl,%bl
  800a00:	75 06                	jne    800a08 <strfind+0x1d>
  800a02:	eb 0e                	jmp    800a12 <strfind+0x27>
  800a04:	38 ca                	cmp    %cl,%dl
  800a06:	74 0a                	je     800a12 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800a08:	83 c0 01             	add    $0x1,%eax
  800a0b:	0f b6 10             	movzbl (%eax),%edx
  800a0e:	84 d2                	test   %dl,%dl
  800a10:	75 f2                	jne    800a04 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800a12:	5b                   	pop    %ebx
  800a13:	5d                   	pop    %ebp
  800a14:	c3                   	ret    

00800a15 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a15:	55                   	push   %ebp
  800a16:	89 e5                	mov    %esp,%ebp
  800a18:	83 ec 0c             	sub    $0xc,%esp
  800a1b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800a1e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a21:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a24:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a27:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a2a:	85 c9                	test   %ecx,%ecx
  800a2c:	74 36                	je     800a64 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a2e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a34:	75 28                	jne    800a5e <memset+0x49>
  800a36:	f6 c1 03             	test   $0x3,%cl
  800a39:	75 23                	jne    800a5e <memset+0x49>
		c &= 0xFF;
  800a3b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a3f:	89 d3                	mov    %edx,%ebx
  800a41:	c1 e3 08             	shl    $0x8,%ebx
  800a44:	89 d6                	mov    %edx,%esi
  800a46:	c1 e6 18             	shl    $0x18,%esi
  800a49:	89 d0                	mov    %edx,%eax
  800a4b:	c1 e0 10             	shl    $0x10,%eax
  800a4e:	09 f0                	or     %esi,%eax
  800a50:	09 c2                	or     %eax,%edx
  800a52:	89 d0                	mov    %edx,%eax
  800a54:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a56:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a59:	fc                   	cld    
  800a5a:	f3 ab                	rep stos %eax,%es:(%edi)
  800a5c:	eb 06                	jmp    800a64 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a5e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a61:	fc                   	cld    
  800a62:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a64:	89 f8                	mov    %edi,%eax
  800a66:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a69:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a6c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a6f:	89 ec                	mov    %ebp,%esp
  800a71:	5d                   	pop    %ebp
  800a72:	c3                   	ret    

00800a73 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a73:	55                   	push   %ebp
  800a74:	89 e5                	mov    %esp,%ebp
  800a76:	83 ec 08             	sub    $0x8,%esp
  800a79:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a7c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a7f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a82:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a85:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a88:	39 c6                	cmp    %eax,%esi
  800a8a:	73 36                	jae    800ac2 <memmove+0x4f>
  800a8c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a8f:	39 d0                	cmp    %edx,%eax
  800a91:	73 2f                	jae    800ac2 <memmove+0x4f>
		s += n;
		d += n;
  800a93:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a96:	f6 c2 03             	test   $0x3,%dl
  800a99:	75 1b                	jne    800ab6 <memmove+0x43>
  800a9b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800aa1:	75 13                	jne    800ab6 <memmove+0x43>
  800aa3:	f6 c1 03             	test   $0x3,%cl
  800aa6:	75 0e                	jne    800ab6 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800aa8:	83 ef 04             	sub    $0x4,%edi
  800aab:	8d 72 fc             	lea    -0x4(%edx),%esi
  800aae:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800ab1:	fd                   	std    
  800ab2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ab4:	eb 09                	jmp    800abf <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800ab6:	83 ef 01             	sub    $0x1,%edi
  800ab9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800abc:	fd                   	std    
  800abd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800abf:	fc                   	cld    
  800ac0:	eb 20                	jmp    800ae2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ac2:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800ac8:	75 13                	jne    800add <memmove+0x6a>
  800aca:	a8 03                	test   $0x3,%al
  800acc:	75 0f                	jne    800add <memmove+0x6a>
  800ace:	f6 c1 03             	test   $0x3,%cl
  800ad1:	75 0a                	jne    800add <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800ad3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800ad6:	89 c7                	mov    %eax,%edi
  800ad8:	fc                   	cld    
  800ad9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800adb:	eb 05                	jmp    800ae2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800add:	89 c7                	mov    %eax,%edi
  800adf:	fc                   	cld    
  800ae0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ae2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ae5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ae8:	89 ec                	mov    %ebp,%esp
  800aea:	5d                   	pop    %ebp
  800aeb:	c3                   	ret    

00800aec <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800aec:	55                   	push   %ebp
  800aed:	89 e5                	mov    %esp,%ebp
  800aef:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800af2:	8b 45 10             	mov    0x10(%ebp),%eax
  800af5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800af9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800afc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b00:	8b 45 08             	mov    0x8(%ebp),%eax
  800b03:	89 04 24             	mov    %eax,(%esp)
  800b06:	e8 68 ff ff ff       	call   800a73 <memmove>
}
  800b0b:	c9                   	leave  
  800b0c:	c3                   	ret    

00800b0d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b0d:	55                   	push   %ebp
  800b0e:	89 e5                	mov    %esp,%ebp
  800b10:	57                   	push   %edi
  800b11:	56                   	push   %esi
  800b12:	53                   	push   %ebx
  800b13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800b16:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b19:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b1c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800b1f:	85 c0                	test   %eax,%eax
  800b21:	74 36                	je     800b59 <memcmp+0x4c>
		if (*s1 != *s2)
  800b23:	0f b6 03             	movzbl (%ebx),%eax
  800b26:	0f b6 0e             	movzbl (%esi),%ecx
  800b29:	38 c8                	cmp    %cl,%al
  800b2b:	75 17                	jne    800b44 <memcmp+0x37>
  800b2d:	ba 00 00 00 00       	mov    $0x0,%edx
  800b32:	eb 1a                	jmp    800b4e <memcmp+0x41>
  800b34:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800b39:	83 c2 01             	add    $0x1,%edx
  800b3c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800b40:	38 c8                	cmp    %cl,%al
  800b42:	74 0a                	je     800b4e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800b44:	0f b6 c0             	movzbl %al,%eax
  800b47:	0f b6 c9             	movzbl %cl,%ecx
  800b4a:	29 c8                	sub    %ecx,%eax
  800b4c:	eb 10                	jmp    800b5e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b4e:	39 fa                	cmp    %edi,%edx
  800b50:	75 e2                	jne    800b34 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b52:	b8 00 00 00 00       	mov    $0x0,%eax
  800b57:	eb 05                	jmp    800b5e <memcmp+0x51>
  800b59:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b5e:	5b                   	pop    %ebx
  800b5f:	5e                   	pop    %esi
  800b60:	5f                   	pop    %edi
  800b61:	5d                   	pop    %ebp
  800b62:	c3                   	ret    

00800b63 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b63:	55                   	push   %ebp
  800b64:	89 e5                	mov    %esp,%ebp
  800b66:	53                   	push   %ebx
  800b67:	8b 45 08             	mov    0x8(%ebp),%eax
  800b6a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800b6d:	89 c2                	mov    %eax,%edx
  800b6f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b72:	39 d0                	cmp    %edx,%eax
  800b74:	73 13                	jae    800b89 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b76:	89 d9                	mov    %ebx,%ecx
  800b78:	38 18                	cmp    %bl,(%eax)
  800b7a:	75 06                	jne    800b82 <memfind+0x1f>
  800b7c:	eb 0b                	jmp    800b89 <memfind+0x26>
  800b7e:	38 08                	cmp    %cl,(%eax)
  800b80:	74 07                	je     800b89 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b82:	83 c0 01             	add    $0x1,%eax
  800b85:	39 d0                	cmp    %edx,%eax
  800b87:	75 f5                	jne    800b7e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b89:	5b                   	pop    %ebx
  800b8a:	5d                   	pop    %ebp
  800b8b:	c3                   	ret    

00800b8c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b8c:	55                   	push   %ebp
  800b8d:	89 e5                	mov    %esp,%ebp
  800b8f:	57                   	push   %edi
  800b90:	56                   	push   %esi
  800b91:	53                   	push   %ebx
  800b92:	83 ec 04             	sub    $0x4,%esp
  800b95:	8b 55 08             	mov    0x8(%ebp),%edx
  800b98:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b9b:	0f b6 02             	movzbl (%edx),%eax
  800b9e:	3c 09                	cmp    $0x9,%al
  800ba0:	74 04                	je     800ba6 <strtol+0x1a>
  800ba2:	3c 20                	cmp    $0x20,%al
  800ba4:	75 0e                	jne    800bb4 <strtol+0x28>
		s++;
  800ba6:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ba9:	0f b6 02             	movzbl (%edx),%eax
  800bac:	3c 09                	cmp    $0x9,%al
  800bae:	74 f6                	je     800ba6 <strtol+0x1a>
  800bb0:	3c 20                	cmp    $0x20,%al
  800bb2:	74 f2                	je     800ba6 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800bb4:	3c 2b                	cmp    $0x2b,%al
  800bb6:	75 0a                	jne    800bc2 <strtol+0x36>
		s++;
  800bb8:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800bbb:	bf 00 00 00 00       	mov    $0x0,%edi
  800bc0:	eb 10                	jmp    800bd2 <strtol+0x46>
  800bc2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800bc7:	3c 2d                	cmp    $0x2d,%al
  800bc9:	75 07                	jne    800bd2 <strtol+0x46>
		s++, neg = 1;
  800bcb:	83 c2 01             	add    $0x1,%edx
  800bce:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800bd2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800bd8:	75 15                	jne    800bef <strtol+0x63>
  800bda:	80 3a 30             	cmpb   $0x30,(%edx)
  800bdd:	75 10                	jne    800bef <strtol+0x63>
  800bdf:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800be3:	75 0a                	jne    800bef <strtol+0x63>
		s += 2, base = 16;
  800be5:	83 c2 02             	add    $0x2,%edx
  800be8:	bb 10 00 00 00       	mov    $0x10,%ebx
  800bed:	eb 10                	jmp    800bff <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800bef:	85 db                	test   %ebx,%ebx
  800bf1:	75 0c                	jne    800bff <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bf3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bf5:	80 3a 30             	cmpb   $0x30,(%edx)
  800bf8:	75 05                	jne    800bff <strtol+0x73>
		s++, base = 8;
  800bfa:	83 c2 01             	add    $0x1,%edx
  800bfd:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800bff:	b8 00 00 00 00       	mov    $0x0,%eax
  800c04:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800c07:	0f b6 0a             	movzbl (%edx),%ecx
  800c0a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800c0d:	89 f3                	mov    %esi,%ebx
  800c0f:	80 fb 09             	cmp    $0x9,%bl
  800c12:	77 08                	ja     800c1c <strtol+0x90>
			dig = *s - '0';
  800c14:	0f be c9             	movsbl %cl,%ecx
  800c17:	83 e9 30             	sub    $0x30,%ecx
  800c1a:	eb 22                	jmp    800c3e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800c1c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800c1f:	89 f3                	mov    %esi,%ebx
  800c21:	80 fb 19             	cmp    $0x19,%bl
  800c24:	77 08                	ja     800c2e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800c26:	0f be c9             	movsbl %cl,%ecx
  800c29:	83 e9 57             	sub    $0x57,%ecx
  800c2c:	eb 10                	jmp    800c3e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800c2e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800c31:	89 f3                	mov    %esi,%ebx
  800c33:	80 fb 19             	cmp    $0x19,%bl
  800c36:	77 16                	ja     800c4e <strtol+0xc2>
			dig = *s - 'A' + 10;
  800c38:	0f be c9             	movsbl %cl,%ecx
  800c3b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c3e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800c41:	7d 0f                	jge    800c52 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800c43:	83 c2 01             	add    $0x1,%edx
  800c46:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800c4a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800c4c:	eb b9                	jmp    800c07 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800c4e:	89 c1                	mov    %eax,%ecx
  800c50:	eb 02                	jmp    800c54 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800c52:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800c54:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c58:	74 05                	je     800c5f <strtol+0xd3>
		*endptr = (char *) s;
  800c5a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c5d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800c5f:	89 ca                	mov    %ecx,%edx
  800c61:	f7 da                	neg    %edx
  800c63:	85 ff                	test   %edi,%edi
  800c65:	0f 45 c2             	cmovne %edx,%eax
}
  800c68:	83 c4 04             	add    $0x4,%esp
  800c6b:	5b                   	pop    %ebx
  800c6c:	5e                   	pop    %esi
  800c6d:	5f                   	pop    %edi
  800c6e:	5d                   	pop    %ebp
  800c6f:	c3                   	ret    

00800c70 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800c70:	55                   	push   %ebp
  800c71:	89 e5                	mov    %esp,%ebp
  800c73:	83 ec 0c             	sub    $0xc,%esp
  800c76:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c79:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c7c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c7f:	b8 00 00 00 00       	mov    $0x0,%eax
  800c84:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c87:	8b 55 08             	mov    0x8(%ebp),%edx
  800c8a:	89 c3                	mov    %eax,%ebx
  800c8c:	89 c7                	mov    %eax,%edi
  800c8e:	89 c6                	mov    %eax,%esi
  800c90:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c92:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c95:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c98:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c9b:	89 ec                	mov    %ebp,%esp
  800c9d:	5d                   	pop    %ebp
  800c9e:	c3                   	ret    

00800c9f <sys_cgetc>:

int
sys_cgetc(void)
{
  800c9f:	55                   	push   %ebp
  800ca0:	89 e5                	mov    %esp,%ebp
  800ca2:	83 ec 0c             	sub    $0xc,%esp
  800ca5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ca8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800cab:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cae:	ba 00 00 00 00       	mov    $0x0,%edx
  800cb3:	b8 01 00 00 00       	mov    $0x1,%eax
  800cb8:	89 d1                	mov    %edx,%ecx
  800cba:	89 d3                	mov    %edx,%ebx
  800cbc:	89 d7                	mov    %edx,%edi
  800cbe:	89 d6                	mov    %edx,%esi
  800cc0:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800cc2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800cc5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cc8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ccb:	89 ec                	mov    %ebp,%esp
  800ccd:	5d                   	pop    %ebp
  800cce:	c3                   	ret    

00800ccf <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ccf:	55                   	push   %ebp
  800cd0:	89 e5                	mov    %esp,%ebp
  800cd2:	83 ec 38             	sub    $0x38,%esp
  800cd5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800cd8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800cdb:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cde:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ce3:	b8 03 00 00 00       	mov    $0x3,%eax
  800ce8:	8b 55 08             	mov    0x8(%ebp),%edx
  800ceb:	89 cb                	mov    %ecx,%ebx
  800ced:	89 cf                	mov    %ecx,%edi
  800cef:	89 ce                	mov    %ecx,%esi
  800cf1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cf3:	85 c0                	test   %eax,%eax
  800cf5:	7e 28                	jle    800d1f <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cf7:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cfb:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800d02:	00 
  800d03:	c7 44 24 08 e4 19 80 	movl   $0x8019e4,0x8(%esp)
  800d0a:	00 
  800d0b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d12:	00 
  800d13:	c7 04 24 01 1a 80 00 	movl   $0x801a01,(%esp)
  800d1a:	e8 e1 05 00 00       	call   801300 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800d1f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d22:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d25:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d28:	89 ec                	mov    %ebp,%esp
  800d2a:	5d                   	pop    %ebp
  800d2b:	c3                   	ret    

00800d2c <sys_getenvid>:

envid_t
sys_getenvid(void)
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
  800d40:	b8 02 00 00 00       	mov    $0x2,%eax
  800d45:	89 d1                	mov    %edx,%ecx
  800d47:	89 d3                	mov    %edx,%ebx
  800d49:	89 d7                	mov    %edx,%edi
  800d4b:	89 d6                	mov    %edx,%esi
  800d4d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800d4f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d52:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d55:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d58:	89 ec                	mov    %ebp,%esp
  800d5a:	5d                   	pop    %ebp
  800d5b:	c3                   	ret    

00800d5c <sys_yield>:

void
sys_yield(void)
{
  800d5c:	55                   	push   %ebp
  800d5d:	89 e5                	mov    %esp,%ebp
  800d5f:	83 ec 0c             	sub    $0xc,%esp
  800d62:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d65:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d68:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d6b:	ba 00 00 00 00       	mov    $0x0,%edx
  800d70:	b8 0a 00 00 00       	mov    $0xa,%eax
  800d75:	89 d1                	mov    %edx,%ecx
  800d77:	89 d3                	mov    %edx,%ebx
  800d79:	89 d7                	mov    %edx,%edi
  800d7b:	89 d6                	mov    %edx,%esi
  800d7d:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800d7f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d82:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d85:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d88:	89 ec                	mov    %ebp,%esp
  800d8a:	5d                   	pop    %ebp
  800d8b:	c3                   	ret    

00800d8c <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800d8c:	55                   	push   %ebp
  800d8d:	89 e5                	mov    %esp,%ebp
  800d8f:	83 ec 38             	sub    $0x38,%esp
  800d92:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d95:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d98:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d9b:	be 00 00 00 00       	mov    $0x0,%esi
  800da0:	b8 04 00 00 00       	mov    $0x4,%eax
  800da5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800da8:	8b 55 08             	mov    0x8(%ebp),%edx
  800dab:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800dae:	89 f7                	mov    %esi,%edi
  800db0:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800db2:	85 c0                	test   %eax,%eax
  800db4:	7e 28                	jle    800dde <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  800db6:	89 44 24 10          	mov    %eax,0x10(%esp)
  800dba:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800dc1:	00 
  800dc2:	c7 44 24 08 e4 19 80 	movl   $0x8019e4,0x8(%esp)
  800dc9:	00 
  800dca:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800dd1:	00 
  800dd2:	c7 04 24 01 1a 80 00 	movl   $0x801a01,(%esp)
  800dd9:	e8 22 05 00 00       	call   801300 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800dde:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800de1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800de4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800de7:	89 ec                	mov    %ebp,%esp
  800de9:	5d                   	pop    %ebp
  800dea:	c3                   	ret    

00800deb <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800deb:	55                   	push   %ebp
  800dec:	89 e5                	mov    %esp,%ebp
  800dee:	83 ec 38             	sub    $0x38,%esp
  800df1:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800df4:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800df7:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dfa:	b8 05 00 00 00       	mov    $0x5,%eax
  800dff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e02:	8b 55 08             	mov    0x8(%ebp),%edx
  800e05:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e08:	8b 7d 14             	mov    0x14(%ebp),%edi
  800e0b:	8b 75 18             	mov    0x18(%ebp),%esi
  800e0e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e10:	85 c0                	test   %eax,%eax
  800e12:	7e 28                	jle    800e3c <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e14:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e18:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800e1f:	00 
  800e20:	c7 44 24 08 e4 19 80 	movl   $0x8019e4,0x8(%esp)
  800e27:	00 
  800e28:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e2f:	00 
  800e30:	c7 04 24 01 1a 80 00 	movl   $0x801a01,(%esp)
  800e37:	e8 c4 04 00 00       	call   801300 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800e3c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e3f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e42:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e45:	89 ec                	mov    %ebp,%esp
  800e47:	5d                   	pop    %ebp
  800e48:	c3                   	ret    

00800e49 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800e49:	55                   	push   %ebp
  800e4a:	89 e5                	mov    %esp,%ebp
  800e4c:	83 ec 38             	sub    $0x38,%esp
  800e4f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e52:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e55:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e58:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e5d:	b8 06 00 00 00       	mov    $0x6,%eax
  800e62:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e65:	8b 55 08             	mov    0x8(%ebp),%edx
  800e68:	89 df                	mov    %ebx,%edi
  800e6a:	89 de                	mov    %ebx,%esi
  800e6c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e6e:	85 c0                	test   %eax,%eax
  800e70:	7e 28                	jle    800e9a <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e72:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e76:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800e7d:	00 
  800e7e:	c7 44 24 08 e4 19 80 	movl   $0x8019e4,0x8(%esp)
  800e85:	00 
  800e86:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e8d:	00 
  800e8e:	c7 04 24 01 1a 80 00 	movl   $0x801a01,(%esp)
  800e95:	e8 66 04 00 00       	call   801300 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800e9a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e9d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ea0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ea3:	89 ec                	mov    %ebp,%esp
  800ea5:	5d                   	pop    %ebp
  800ea6:	c3                   	ret    

00800ea7 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800ea7:	55                   	push   %ebp
  800ea8:	89 e5                	mov    %esp,%ebp
  800eaa:	83 ec 38             	sub    $0x38,%esp
  800ead:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800eb0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800eb3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800eb6:	bb 00 00 00 00       	mov    $0x0,%ebx
  800ebb:	b8 08 00 00 00       	mov    $0x8,%eax
  800ec0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ec3:	8b 55 08             	mov    0x8(%ebp),%edx
  800ec6:	89 df                	mov    %ebx,%edi
  800ec8:	89 de                	mov    %ebx,%esi
  800eca:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ecc:	85 c0                	test   %eax,%eax
  800ece:	7e 28                	jle    800ef8 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ed0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ed4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800edb:	00 
  800edc:	c7 44 24 08 e4 19 80 	movl   $0x8019e4,0x8(%esp)
  800ee3:	00 
  800ee4:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800eeb:	00 
  800eec:	c7 04 24 01 1a 80 00 	movl   $0x801a01,(%esp)
  800ef3:	e8 08 04 00 00       	call   801300 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800ef8:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800efb:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800efe:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f01:	89 ec                	mov    %ebp,%esp
  800f03:	5d                   	pop    %ebp
  800f04:	c3                   	ret    

00800f05 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800f05:	55                   	push   %ebp
  800f06:	89 e5                	mov    %esp,%ebp
  800f08:	83 ec 38             	sub    $0x38,%esp
  800f0b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f0e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f11:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f14:	bb 00 00 00 00       	mov    $0x0,%ebx
  800f19:	b8 09 00 00 00       	mov    $0x9,%eax
  800f1e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f21:	8b 55 08             	mov    0x8(%ebp),%edx
  800f24:	89 df                	mov    %ebx,%edi
  800f26:	89 de                	mov    %ebx,%esi
  800f28:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f2a:	85 c0                	test   %eax,%eax
  800f2c:	7e 28                	jle    800f56 <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f2e:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f32:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800f39:	00 
  800f3a:	c7 44 24 08 e4 19 80 	movl   $0x8019e4,0x8(%esp)
  800f41:	00 
  800f42:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f49:	00 
  800f4a:	c7 04 24 01 1a 80 00 	movl   $0x801a01,(%esp)
  800f51:	e8 aa 03 00 00       	call   801300 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800f56:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f59:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f5c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f5f:	89 ec                	mov    %ebp,%esp
  800f61:	5d                   	pop    %ebp
  800f62:	c3                   	ret    

00800f63 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800f63:	55                   	push   %ebp
  800f64:	89 e5                	mov    %esp,%ebp
  800f66:	83 ec 0c             	sub    $0xc,%esp
  800f69:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f6c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f6f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f72:	be 00 00 00 00       	mov    $0x0,%esi
  800f77:	b8 0b 00 00 00       	mov    $0xb,%eax
  800f7c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f7f:	8b 55 08             	mov    0x8(%ebp),%edx
  800f82:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800f85:	8b 7d 14             	mov    0x14(%ebp),%edi
  800f88:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800f8a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f8d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f90:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f93:	89 ec                	mov    %ebp,%esp
  800f95:	5d                   	pop    %ebp
  800f96:	c3                   	ret    

00800f97 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800f97:	55                   	push   %ebp
  800f98:	89 e5                	mov    %esp,%ebp
  800f9a:	83 ec 38             	sub    $0x38,%esp
  800f9d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800fa0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800fa3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800fa6:	b9 00 00 00 00       	mov    $0x0,%ecx
  800fab:	b8 0c 00 00 00       	mov    $0xc,%eax
  800fb0:	8b 55 08             	mov    0x8(%ebp),%edx
  800fb3:	89 cb                	mov    %ecx,%ebx
  800fb5:	89 cf                	mov    %ecx,%edi
  800fb7:	89 ce                	mov    %ecx,%esi
  800fb9:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800fbb:	85 c0                	test   %eax,%eax
  800fbd:	7e 28                	jle    800fe7 <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800fbf:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fc3:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800fca:	00 
  800fcb:	c7 44 24 08 e4 19 80 	movl   $0x8019e4,0x8(%esp)
  800fd2:	00 
  800fd3:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800fda:	00 
  800fdb:	c7 04 24 01 1a 80 00 	movl   $0x801a01,(%esp)
  800fe2:	e8 19 03 00 00       	call   801300 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800fe7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800fea:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800fed:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ff0:	89 ec                	mov    %ebp,%esp
  800ff2:	5d                   	pop    %ebp
  800ff3:	c3                   	ret    

00800ff4 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800ff4:	55                   	push   %ebp
  800ff5:	89 e5                	mov    %esp,%ebp
  800ff7:	53                   	push   %ebx
  800ff8:	83 ec 24             	sub    $0x24,%esp
  800ffb:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void *) utf->utf_fault_va;
  800ffe:	8b 18                	mov    (%eax),%ebx
	// Hint:
	//   Use the read-only page table mappings at vpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if(!((err & FEC_WR) && (vpd[PDX(addr)]&PTE_P) && (vpt[PGNUM(addr)]&PTE_COW) ))
  801000:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  801004:	74 21                	je     801027 <pgfault+0x33>
  801006:	89 d8                	mov    %ebx,%eax
  801008:	c1 e8 16             	shr    $0x16,%eax
  80100b:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  801012:	a8 01                	test   $0x1,%al
  801014:	74 11                	je     801027 <pgfault+0x33>
  801016:	89 d8                	mov    %ebx,%eax
  801018:	c1 e8 0c             	shr    $0xc,%eax
  80101b:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  801022:	f6 c4 08             	test   $0x8,%ah
  801025:	75 1c                	jne    801043 <pgfault+0x4f>
		panic("Invalid fault address!\n");
  801027:	c7 44 24 08 0f 1a 80 	movl   $0x801a0f,0x8(%esp)
  80102e:	00 
  80102f:	c7 44 24 04 1d 00 00 	movl   $0x1d,0x4(%esp)
  801036:	00 
  801037:	c7 04 24 27 1a 80 00 	movl   $0x801a27,(%esp)
  80103e:	e8 bd 02 00 00       	call   801300 <_panic>
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
	if((r = sys_page_alloc(0, (void *)PFTEMP, PTE_W|PTE_P|PTE_U)))
  801043:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  80104a:	00 
  80104b:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  801052:	00 
  801053:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80105a:	e8 2d fd ff ff       	call   800d8c <sys_page_alloc>
  80105f:	85 c0                	test   %eax,%eax
  801061:	74 20                	je     801083 <pgfault+0x8f>
		panic("Alloc page error: %e", r);
  801063:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801067:	c7 44 24 08 32 1a 80 	movl   $0x801a32,0x8(%esp)
  80106e:	00 
  80106f:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
  801076:	00 
  801077:	c7 04 24 27 1a 80 00 	movl   $0x801a27,(%esp)
  80107e:	e8 7d 02 00 00       	call   801300 <_panic>
	addr = ROUNDDOWN(addr, PGSIZE);
  801083:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	memmove((void *)PFTEMP, addr, PGSIZE);
  801089:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  801090:	00 
  801091:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  801095:	c7 04 24 00 f0 7f 00 	movl   $0x7ff000,(%esp)
  80109c:	e8 d2 f9 ff ff       	call   800a73 <memmove>
	sys_page_map(0, (void *)PFTEMP, 0, addr, PTE_W|PTE_P|PTE_U);
  8010a1:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  8010a8:	00 
  8010a9:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8010ad:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8010b4:	00 
  8010b5:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  8010bc:	00 
  8010bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8010c4:	e8 22 fd ff ff       	call   800deb <sys_page_map>

	//panic("pgfault not implemented");
}
  8010c9:	83 c4 24             	add    $0x24,%esp
  8010cc:	5b                   	pop    %ebx
  8010cd:	5d                   	pop    %ebp
  8010ce:	c3                   	ret    

008010cf <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  8010cf:	55                   	push   %ebp
  8010d0:	89 e5                	mov    %esp,%ebp
  8010d2:	57                   	push   %edi
  8010d3:	56                   	push   %esi
  8010d4:	53                   	push   %ebx
  8010d5:	83 ec 3c             	sub    $0x3c,%esp
	// LAB 4: Your code here.
	envid_t ch_id;
	uint32_t cow_pg_ptr;
	int r;

	set_pgfault_handler(pgfault);
  8010d8:	c7 04 24 f4 0f 80 00 	movl   $0x800ff4,(%esp)
  8010df:	e8 8c 02 00 00       	call   801370 <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  8010e4:	ba 07 00 00 00       	mov    $0x7,%edx
  8010e9:	89 d0                	mov    %edx,%eax
  8010eb:	cd 30                	int    $0x30
  8010ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	if((ch_id = sys_exofork()) < 0)
  8010f0:	85 c0                	test   %eax,%eax
  8010f2:	79 1c                	jns    801110 <fork+0x41>
		panic("Fork error\n");
  8010f4:	c7 44 24 08 47 1a 80 	movl   $0x801a47,0x8(%esp)
  8010fb:	00 
  8010fc:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
  801103:	00 
  801104:	c7 04 24 27 1a 80 00 	movl   $0x801a27,(%esp)
  80110b:	e8 f0 01 00 00       	call   801300 <_panic>
  801110:	89 c7                	mov    %eax,%edi
	if(ch_id == 0){ /* the child process */
  801112:	bb 00 00 80 00       	mov    $0x800000,%ebx
  801117:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80111b:	75 1c                	jne    801139 <fork+0x6a>
		thisenv =  &envs[ENVX(sys_getenvid())];
  80111d:	e8 0a fc ff ff       	call   800d2c <sys_getenvid>
  801122:	25 ff 03 00 00       	and    $0x3ff,%eax
  801127:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80112a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80112f:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  801134:	e9 98 01 00 00       	jmp    8012d1 <fork+0x202>
	}
	for(cow_pg_ptr = UTEXT; cow_pg_ptr < UXSTACKTOP - PGSIZE; cow_pg_ptr += PGSIZE){
		if ((vpd[PDX(cow_pg_ptr)] & PTE_P) && (vpt[PGNUM(cow_pg_ptr)] & (PTE_P|PTE_U))) 
  801139:	89 d8                	mov    %ebx,%eax
  80113b:	c1 e8 16             	shr    $0x16,%eax
  80113e:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  801145:	a8 01                	test   $0x1,%al
  801147:	0f 84 0d 01 00 00    	je     80125a <fork+0x18b>
  80114d:	89 d8                	mov    %ebx,%eax
  80114f:	c1 e8 0c             	shr    $0xc,%eax
  801152:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  801159:	f6 c2 05             	test   $0x5,%dl
  80115c:	0f 84 f8 00 00 00    	je     80125a <fork+0x18b>
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	if((vpd[PDX(pn*PGSIZE)]&PTE_P) && (vpt[pn]&(PTE_COW|PTE_W))){
  801162:	89 c6                	mov    %eax,%esi
  801164:	c1 e6 0c             	shl    $0xc,%esi
  801167:	89 f2                	mov    %esi,%edx
  801169:	c1 ea 16             	shr    $0x16,%edx
  80116c:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  801173:	f6 c2 01             	test   $0x1,%dl
  801176:	0f 84 9a 00 00 00    	je     801216 <fork+0x147>
  80117c:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  801183:	a9 02 08 00 00       	test   $0x802,%eax
  801188:	0f 84 88 00 00 00    	je     801216 <fork+0x147>
		if((r = sys_page_map(0, (void *)(pn*PGSIZE), envid, (void *)(pn*PGSIZE), PTE_P|PTE_COW|PTE_U)))
  80118e:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  801195:	00 
  801196:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80119a:	89 7c 24 08          	mov    %edi,0x8(%esp)
  80119e:	89 74 24 04          	mov    %esi,0x4(%esp)
  8011a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8011a9:	e8 3d fc ff ff       	call   800deb <sys_page_map>
  8011ae:	85 c0                	test   %eax,%eax
  8011b0:	74 20                	je     8011d2 <fork+0x103>
			panic("Map page for child procesee failed: %e\n", r);
  8011b2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8011b6:	c7 44 24 08 6c 1a 80 	movl   $0x801a6c,0x8(%esp)
  8011bd:	00 
  8011be:	c7 44 24 04 43 00 00 	movl   $0x43,0x4(%esp)
  8011c5:	00 
  8011c6:	c7 04 24 27 1a 80 00 	movl   $0x801a27,(%esp)
  8011cd:	e8 2e 01 00 00       	call   801300 <_panic>
		if((r = sys_page_map(envid, (void *)(pn*PGSIZE), 0, (void *)(pn*PGSIZE), PTE_P|PTE_COW|PTE_U)))
  8011d2:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  8011d9:	00 
  8011da:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8011de:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8011e5:	00 
  8011e6:	89 74 24 04          	mov    %esi,0x4(%esp)
  8011ea:	89 3c 24             	mov    %edi,(%esp)
  8011ed:	e8 f9 fb ff ff       	call   800deb <sys_page_map>
  8011f2:	85 c0                	test   %eax,%eax
  8011f4:	74 64                	je     80125a <fork+0x18b>
			panic("Map page for child procesee failed: %e\n", r);
  8011f6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8011fa:	c7 44 24 08 6c 1a 80 	movl   $0x801a6c,0x8(%esp)
  801201:	00 
  801202:	c7 44 24 04 45 00 00 	movl   $0x45,0x4(%esp)
  801209:	00 
  80120a:	c7 04 24 27 1a 80 00 	movl   $0x801a27,(%esp)
  801211:	e8 ea 00 00 00       	call   801300 <_panic>
	}else
		if((r = sys_page_map(0, (void *)(pn*PGSIZE), envid, (void *)(pn*PGSIZE), PTE_P|PTE_U)))
  801216:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
  80121d:	00 
  80121e:	89 74 24 0c          	mov    %esi,0xc(%esp)
  801222:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801226:	89 74 24 04          	mov    %esi,0x4(%esp)
  80122a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801231:	e8 b5 fb ff ff       	call   800deb <sys_page_map>
  801236:	85 c0                	test   %eax,%eax
  801238:	74 20                	je     80125a <fork+0x18b>
			panic("Map page for child procesee failed: %e\n", r);
  80123a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80123e:	c7 44 24 08 6c 1a 80 	movl   $0x801a6c,0x8(%esp)
  801245:	00 
  801246:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
  80124d:	00 
  80124e:	c7 04 24 27 1a 80 00 	movl   $0x801a27,(%esp)
  801255:	e8 a6 00 00 00       	call   801300 <_panic>
		panic("Fork error\n");
	if(ch_id == 0){ /* the child process */
		thisenv =  &envs[ENVX(sys_getenvid())];
		return 0;
	}
	for(cow_pg_ptr = UTEXT; cow_pg_ptr < UXSTACKTOP - PGSIZE; cow_pg_ptr += PGSIZE){
  80125a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  801260:	81 fb 00 f0 bf ee    	cmp    $0xeebff000,%ebx
  801266:	0f 85 cd fe ff ff    	jne    801139 <fork+0x6a>
		if ((vpd[PDX(cow_pg_ptr)] & PTE_P) && (vpt[PGNUM(cow_pg_ptr)] & (PTE_P|PTE_U))) 
			duppage(ch_id, PGNUM(cow_pg_ptr));
	}

	if((r = sys_page_alloc(ch_id, (void *)(UXSTACKTOP - PGSIZE), PTE_U|PTE_P|PTE_W)))
  80126c:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801273:	00 
  801274:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  80127b:	ee 
  80127c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80127f:	89 04 24             	mov    %eax,(%esp)
  801282:	e8 05 fb ff ff       	call   800d8c <sys_page_alloc>
  801287:	85 c0                	test   %eax,%eax
  801289:	74 20                	je     8012ab <fork+0x1dc>
		panic("Alloc exception stack error: %e\n", r);
  80128b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80128f:	c7 44 24 08 94 1a 80 	movl   $0x801a94,0x8(%esp)
  801296:	00 
  801297:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  80129e:	00 
  80129f:	c7 04 24 27 1a 80 00 	movl   $0x801a27,(%esp)
  8012a6:	e8 55 00 00 00       	call   801300 <_panic>

	extern void _pgfault_upcall(void);
	sys_env_set_pgfault_upcall(ch_id, _pgfault_upcall);
  8012ab:	c7 44 24 04 e0 13 80 	movl   $0x8013e0,0x4(%esp)
  8012b2:	00 
  8012b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8012b6:	89 04 24             	mov    %eax,(%esp)
  8012b9:	e8 47 fc ff ff       	call   800f05 <sys_env_set_pgfault_upcall>

	sys_env_set_status(ch_id, ENV_RUNNABLE);
  8012be:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  8012c5:	00 
  8012c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8012c9:	89 04 24             	mov    %eax,(%esp)
  8012cc:	e8 d6 fb ff ff       	call   800ea7 <sys_env_set_status>
	return ch_id;
	//panic("fork not implemented");
}
  8012d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8012d4:	83 c4 3c             	add    $0x3c,%esp
  8012d7:	5b                   	pop    %ebx
  8012d8:	5e                   	pop    %esi
  8012d9:	5f                   	pop    %edi
  8012da:	5d                   	pop    %ebp
  8012db:	c3                   	ret    

008012dc <sfork>:

// Challenge!
int
sfork(void)
{
  8012dc:	55                   	push   %ebp
  8012dd:	89 e5                	mov    %esp,%ebp
  8012df:	83 ec 18             	sub    $0x18,%esp
	panic("sfork not implemented");
  8012e2:	c7 44 24 08 53 1a 80 	movl   $0x801a53,0x8(%esp)
  8012e9:	00 
  8012ea:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
  8012f1:	00 
  8012f2:	c7 04 24 27 1a 80 00 	movl   $0x801a27,(%esp)
  8012f9:	e8 02 00 00 00       	call   801300 <_panic>
  8012fe:	66 90                	xchg   %ax,%ax

00801300 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  801300:	55                   	push   %ebp
  801301:	89 e5                	mov    %esp,%ebp
  801303:	56                   	push   %esi
  801304:	53                   	push   %ebx
  801305:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  801308:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  80130b:	a1 08 20 80 00       	mov    0x802008,%eax
  801310:	85 c0                	test   %eax,%eax
  801312:	74 10                	je     801324 <_panic+0x24>
		cprintf("%s: ", argv0);
  801314:	89 44 24 04          	mov    %eax,0x4(%esp)
  801318:	c7 04 24 b5 1a 80 00 	movl   $0x801ab5,(%esp)
  80131f:	e8 c7 ee ff ff       	call   8001eb <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801324:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80132a:	e8 fd f9 ff ff       	call   800d2c <sys_getenvid>
  80132f:	8b 55 0c             	mov    0xc(%ebp),%edx
  801332:	89 54 24 10          	mov    %edx,0x10(%esp)
  801336:	8b 55 08             	mov    0x8(%ebp),%edx
  801339:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80133d:	89 74 24 08          	mov    %esi,0x8(%esp)
  801341:	89 44 24 04          	mov    %eax,0x4(%esp)
  801345:	c7 04 24 bc 1a 80 00 	movl   $0x801abc,(%esp)
  80134c:	e8 9a ee ff ff       	call   8001eb <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801351:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  801355:	8b 45 10             	mov    0x10(%ebp),%eax
  801358:	89 04 24             	mov    %eax,(%esp)
  80135b:	e8 2a ee ff ff       	call   80018a <vcprintf>
	cprintf("\n");
  801360:	c7 04 24 25 1a 80 00 	movl   $0x801a25,(%esp)
  801367:	e8 7f ee ff ff       	call   8001eb <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80136c:	cc                   	int3   
  80136d:	eb fd                	jmp    80136c <_panic+0x6c>
  80136f:	90                   	nop

00801370 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801370:	55                   	push   %ebp
  801371:	89 e5                	mov    %esp,%ebp
  801373:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  801376:	83 3d 0c 20 80 00 00 	cmpl   $0x0,0x80200c
  80137d:	75 54                	jne    8013d3 <set_pgfault_handler+0x63>
		// First time through!
		// LAB 4: Your code here.
		if((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE), PTE_U|PTE_P|PTE_W)))
  80137f:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801386:	00 
  801387:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  80138e:	ee 
  80138f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801396:	e8 f1 f9 ff ff       	call   800d8c <sys_page_alloc>
  80139b:	85 c0                	test   %eax,%eax
  80139d:	74 20                	je     8013bf <set_pgfault_handler+0x4f>
			panic("Exception stack alloc failed: %e!\n", r);
  80139f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8013a3:	c7 44 24 08 e0 1a 80 	movl   $0x801ae0,0x8(%esp)
  8013aa:	00 
  8013ab:	c7 44 24 04 21 00 00 	movl   $0x21,0x4(%esp)
  8013b2:	00 
  8013b3:	c7 04 24 04 1b 80 00 	movl   $0x801b04,(%esp)
  8013ba:	e8 41 ff ff ff       	call   801300 <_panic>
		sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  8013bf:	c7 44 24 04 e0 13 80 	movl   $0x8013e0,0x4(%esp)
  8013c6:	00 
  8013c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8013ce:	e8 32 fb ff ff       	call   800f05 <sys_env_set_pgfault_upcall>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8013d3:	8b 45 08             	mov    0x8(%ebp),%eax
  8013d6:	a3 0c 20 80 00       	mov    %eax,0x80200c
}
  8013db:	c9                   	leave  
  8013dc:	c3                   	ret    
  8013dd:	66 90                	xchg   %ax,%ax
  8013df:	90                   	nop

008013e0 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  8013e0:	54                   	push   %esp
	movl _pgfault_handler, %eax
  8013e1:	a1 0c 20 80 00       	mov    0x80200c,%eax
	call *%eax
  8013e6:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  8013e8:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	addl $8, %esp
  8013eb:	83 c4 08             	add    $0x8,%esp

	movl 0x20(%esp), %ecx
  8013ee:	8b 4c 24 20          	mov    0x20(%esp),%ecx
	movl 0x28(%esp), %eax
  8013f2:	8b 44 24 28          	mov    0x28(%esp),%eax
	subl $0x4, %eax 
  8013f6:	83 e8 04             	sub    $0x4,%eax
	movl %eax, 0x28(%esp)
  8013f9:	89 44 24 28          	mov    %eax,0x28(%esp)
	movl %ecx, (%eax)
  8013fd:	89 08                	mov    %ecx,(%eax)


	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  8013ff:	61                   	popa   

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $4, %esp
  801400:	83 c4 04             	add    $0x4,%esp
	popfl
  801403:	9d                   	popf   

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	pop %esp
  801404:	5c                   	pop    %esp
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  801405:	c3                   	ret    
  801406:	66 90                	xchg   %ax,%ax
  801408:	66 90                	xchg   %ax,%ax
  80140a:	66 90                	xchg   %ax,%ax
  80140c:	66 90                	xchg   %ax,%ax
  80140e:	66 90                	xchg   %ax,%ax

00801410 <__udivdi3>:
  801410:	83 ec 1c             	sub    $0x1c,%esp
  801413:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  801417:	89 7c 24 14          	mov    %edi,0x14(%esp)
  80141b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  80141f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  801423:	8b 7c 24 20          	mov    0x20(%esp),%edi
  801427:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  80142b:	85 c0                	test   %eax,%eax
  80142d:	89 74 24 10          	mov    %esi,0x10(%esp)
  801431:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801435:	89 ea                	mov    %ebp,%edx
  801437:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80143b:	75 33                	jne    801470 <__udivdi3+0x60>
  80143d:	39 e9                	cmp    %ebp,%ecx
  80143f:	77 6f                	ja     8014b0 <__udivdi3+0xa0>
  801441:	85 c9                	test   %ecx,%ecx
  801443:	89 ce                	mov    %ecx,%esi
  801445:	75 0b                	jne    801452 <__udivdi3+0x42>
  801447:	b8 01 00 00 00       	mov    $0x1,%eax
  80144c:	31 d2                	xor    %edx,%edx
  80144e:	f7 f1                	div    %ecx
  801450:	89 c6                	mov    %eax,%esi
  801452:	31 d2                	xor    %edx,%edx
  801454:	89 e8                	mov    %ebp,%eax
  801456:	f7 f6                	div    %esi
  801458:	89 c5                	mov    %eax,%ebp
  80145a:	89 f8                	mov    %edi,%eax
  80145c:	f7 f6                	div    %esi
  80145e:	89 ea                	mov    %ebp,%edx
  801460:	8b 74 24 10          	mov    0x10(%esp),%esi
  801464:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801468:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  80146c:	83 c4 1c             	add    $0x1c,%esp
  80146f:	c3                   	ret    
  801470:	39 e8                	cmp    %ebp,%eax
  801472:	77 24                	ja     801498 <__udivdi3+0x88>
  801474:	0f bd c8             	bsr    %eax,%ecx
  801477:	83 f1 1f             	xor    $0x1f,%ecx
  80147a:	89 0c 24             	mov    %ecx,(%esp)
  80147d:	75 49                	jne    8014c8 <__udivdi3+0xb8>
  80147f:	8b 74 24 08          	mov    0x8(%esp),%esi
  801483:	39 74 24 04          	cmp    %esi,0x4(%esp)
  801487:	0f 86 ab 00 00 00    	jbe    801538 <__udivdi3+0x128>
  80148d:	39 e8                	cmp    %ebp,%eax
  80148f:	0f 82 a3 00 00 00    	jb     801538 <__udivdi3+0x128>
  801495:	8d 76 00             	lea    0x0(%esi),%esi
  801498:	31 d2                	xor    %edx,%edx
  80149a:	31 c0                	xor    %eax,%eax
  80149c:	8b 74 24 10          	mov    0x10(%esp),%esi
  8014a0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8014a4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8014a8:	83 c4 1c             	add    $0x1c,%esp
  8014ab:	c3                   	ret    
  8014ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8014b0:	89 f8                	mov    %edi,%eax
  8014b2:	f7 f1                	div    %ecx
  8014b4:	31 d2                	xor    %edx,%edx
  8014b6:	8b 74 24 10          	mov    0x10(%esp),%esi
  8014ba:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8014be:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8014c2:	83 c4 1c             	add    $0x1c,%esp
  8014c5:	c3                   	ret    
  8014c6:	66 90                	xchg   %ax,%ax
  8014c8:	0f b6 0c 24          	movzbl (%esp),%ecx
  8014cc:	89 c6                	mov    %eax,%esi
  8014ce:	b8 20 00 00 00       	mov    $0x20,%eax
  8014d3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  8014d7:	2b 04 24             	sub    (%esp),%eax
  8014da:	8b 7c 24 08          	mov    0x8(%esp),%edi
  8014de:	d3 e6                	shl    %cl,%esi
  8014e0:	89 c1                	mov    %eax,%ecx
  8014e2:	d3 ed                	shr    %cl,%ebp
  8014e4:	0f b6 0c 24          	movzbl (%esp),%ecx
  8014e8:	09 f5                	or     %esi,%ebp
  8014ea:	8b 74 24 04          	mov    0x4(%esp),%esi
  8014ee:	d3 e6                	shl    %cl,%esi
  8014f0:	89 c1                	mov    %eax,%ecx
  8014f2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8014f6:	89 d6                	mov    %edx,%esi
  8014f8:	d3 ee                	shr    %cl,%esi
  8014fa:	0f b6 0c 24          	movzbl (%esp),%ecx
  8014fe:	d3 e2                	shl    %cl,%edx
  801500:	89 c1                	mov    %eax,%ecx
  801502:	d3 ef                	shr    %cl,%edi
  801504:	09 d7                	or     %edx,%edi
  801506:	89 f2                	mov    %esi,%edx
  801508:	89 f8                	mov    %edi,%eax
  80150a:	f7 f5                	div    %ebp
  80150c:	89 d6                	mov    %edx,%esi
  80150e:	89 c7                	mov    %eax,%edi
  801510:	f7 64 24 04          	mull   0x4(%esp)
  801514:	39 d6                	cmp    %edx,%esi
  801516:	72 30                	jb     801548 <__udivdi3+0x138>
  801518:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  80151c:	0f b6 0c 24          	movzbl (%esp),%ecx
  801520:	d3 e5                	shl    %cl,%ebp
  801522:	39 c5                	cmp    %eax,%ebp
  801524:	73 04                	jae    80152a <__udivdi3+0x11a>
  801526:	39 d6                	cmp    %edx,%esi
  801528:	74 1e                	je     801548 <__udivdi3+0x138>
  80152a:	89 f8                	mov    %edi,%eax
  80152c:	31 d2                	xor    %edx,%edx
  80152e:	e9 69 ff ff ff       	jmp    80149c <__udivdi3+0x8c>
  801533:	90                   	nop
  801534:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801538:	31 d2                	xor    %edx,%edx
  80153a:	b8 01 00 00 00       	mov    $0x1,%eax
  80153f:	e9 58 ff ff ff       	jmp    80149c <__udivdi3+0x8c>
  801544:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801548:	8d 47 ff             	lea    -0x1(%edi),%eax
  80154b:	31 d2                	xor    %edx,%edx
  80154d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801551:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801555:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801559:	83 c4 1c             	add    $0x1c,%esp
  80155c:	c3                   	ret    
  80155d:	66 90                	xchg   %ax,%ax
  80155f:	90                   	nop

00801560 <__umoddi3>:
  801560:	83 ec 2c             	sub    $0x2c,%esp
  801563:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  801567:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80156b:	89 74 24 20          	mov    %esi,0x20(%esp)
  80156f:	8b 74 24 38          	mov    0x38(%esp),%esi
  801573:	89 7c 24 24          	mov    %edi,0x24(%esp)
  801577:	8b 7c 24 34          	mov    0x34(%esp),%edi
  80157b:	85 c0                	test   %eax,%eax
  80157d:	89 c2                	mov    %eax,%edx
  80157f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  801583:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  801587:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80158b:	89 74 24 10          	mov    %esi,0x10(%esp)
  80158f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  801593:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801597:	75 1f                	jne    8015b8 <__umoddi3+0x58>
  801599:	39 fe                	cmp    %edi,%esi
  80159b:	76 63                	jbe    801600 <__umoddi3+0xa0>
  80159d:	89 c8                	mov    %ecx,%eax
  80159f:	89 fa                	mov    %edi,%edx
  8015a1:	f7 f6                	div    %esi
  8015a3:	89 d0                	mov    %edx,%eax
  8015a5:	31 d2                	xor    %edx,%edx
  8015a7:	8b 74 24 20          	mov    0x20(%esp),%esi
  8015ab:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8015af:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8015b3:	83 c4 2c             	add    $0x2c,%esp
  8015b6:	c3                   	ret    
  8015b7:	90                   	nop
  8015b8:	39 f8                	cmp    %edi,%eax
  8015ba:	77 64                	ja     801620 <__umoddi3+0xc0>
  8015bc:	0f bd e8             	bsr    %eax,%ebp
  8015bf:	83 f5 1f             	xor    $0x1f,%ebp
  8015c2:	75 74                	jne    801638 <__umoddi3+0xd8>
  8015c4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8015c8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  8015cc:	0f 87 0e 01 00 00    	ja     8016e0 <__umoddi3+0x180>
  8015d2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  8015d6:	29 f1                	sub    %esi,%ecx
  8015d8:	19 c7                	sbb    %eax,%edi
  8015da:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  8015de:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8015e2:	8b 44 24 14          	mov    0x14(%esp),%eax
  8015e6:	8b 54 24 18          	mov    0x18(%esp),%edx
  8015ea:	8b 74 24 20          	mov    0x20(%esp),%esi
  8015ee:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8015f2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8015f6:	83 c4 2c             	add    $0x2c,%esp
  8015f9:	c3                   	ret    
  8015fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801600:	85 f6                	test   %esi,%esi
  801602:	89 f5                	mov    %esi,%ebp
  801604:	75 0b                	jne    801611 <__umoddi3+0xb1>
  801606:	b8 01 00 00 00       	mov    $0x1,%eax
  80160b:	31 d2                	xor    %edx,%edx
  80160d:	f7 f6                	div    %esi
  80160f:	89 c5                	mov    %eax,%ebp
  801611:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801615:	31 d2                	xor    %edx,%edx
  801617:	f7 f5                	div    %ebp
  801619:	89 c8                	mov    %ecx,%eax
  80161b:	f7 f5                	div    %ebp
  80161d:	eb 84                	jmp    8015a3 <__umoddi3+0x43>
  80161f:	90                   	nop
  801620:	89 c8                	mov    %ecx,%eax
  801622:	89 fa                	mov    %edi,%edx
  801624:	8b 74 24 20          	mov    0x20(%esp),%esi
  801628:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80162c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801630:	83 c4 2c             	add    $0x2c,%esp
  801633:	c3                   	ret    
  801634:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801638:	8b 44 24 10          	mov    0x10(%esp),%eax
  80163c:	be 20 00 00 00       	mov    $0x20,%esi
  801641:	89 e9                	mov    %ebp,%ecx
  801643:	29 ee                	sub    %ebp,%esi
  801645:	d3 e2                	shl    %cl,%edx
  801647:	89 f1                	mov    %esi,%ecx
  801649:	d3 e8                	shr    %cl,%eax
  80164b:	89 e9                	mov    %ebp,%ecx
  80164d:	09 d0                	or     %edx,%eax
  80164f:	89 fa                	mov    %edi,%edx
  801651:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801655:	8b 44 24 10          	mov    0x10(%esp),%eax
  801659:	d3 e0                	shl    %cl,%eax
  80165b:	89 f1                	mov    %esi,%ecx
  80165d:	89 44 24 10          	mov    %eax,0x10(%esp)
  801661:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  801665:	d3 ea                	shr    %cl,%edx
  801667:	89 e9                	mov    %ebp,%ecx
  801669:	d3 e7                	shl    %cl,%edi
  80166b:	89 f1                	mov    %esi,%ecx
  80166d:	d3 e8                	shr    %cl,%eax
  80166f:	89 e9                	mov    %ebp,%ecx
  801671:	09 f8                	or     %edi,%eax
  801673:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  801677:	f7 74 24 0c          	divl   0xc(%esp)
  80167b:	d3 e7                	shl    %cl,%edi
  80167d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801681:	89 d7                	mov    %edx,%edi
  801683:	f7 64 24 10          	mull   0x10(%esp)
  801687:	39 d7                	cmp    %edx,%edi
  801689:	89 c1                	mov    %eax,%ecx
  80168b:	89 54 24 14          	mov    %edx,0x14(%esp)
  80168f:	72 3b                	jb     8016cc <__umoddi3+0x16c>
  801691:	39 44 24 18          	cmp    %eax,0x18(%esp)
  801695:	72 31                	jb     8016c8 <__umoddi3+0x168>
  801697:	8b 44 24 18          	mov    0x18(%esp),%eax
  80169b:	29 c8                	sub    %ecx,%eax
  80169d:	19 d7                	sbb    %edx,%edi
  80169f:	89 e9                	mov    %ebp,%ecx
  8016a1:	89 fa                	mov    %edi,%edx
  8016a3:	d3 e8                	shr    %cl,%eax
  8016a5:	89 f1                	mov    %esi,%ecx
  8016a7:	d3 e2                	shl    %cl,%edx
  8016a9:	89 e9                	mov    %ebp,%ecx
  8016ab:	09 d0                	or     %edx,%eax
  8016ad:	89 fa                	mov    %edi,%edx
  8016af:	d3 ea                	shr    %cl,%edx
  8016b1:	8b 74 24 20          	mov    0x20(%esp),%esi
  8016b5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8016b9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8016bd:	83 c4 2c             	add    $0x2c,%esp
  8016c0:	c3                   	ret    
  8016c1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8016c8:	39 d7                	cmp    %edx,%edi
  8016ca:	75 cb                	jne    801697 <__umoddi3+0x137>
  8016cc:	8b 54 24 14          	mov    0x14(%esp),%edx
  8016d0:	89 c1                	mov    %eax,%ecx
  8016d2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  8016d6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  8016da:	eb bb                	jmp    801697 <__umoddi3+0x137>
  8016dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8016e0:	3b 44 24 18          	cmp    0x18(%esp),%eax
  8016e4:	0f 82 e8 fe ff ff    	jb     8015d2 <__umoddi3+0x72>
  8016ea:	e9 f3 fe ff ff       	jmp    8015e2 <__umoddi3+0x82>

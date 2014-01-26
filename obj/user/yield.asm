
obj/user/yield：     文件格式 elf32-i386


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
  80002c:	e8 6f 00 00 00       	call   8000a0 <libmain>
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
  800037:	53                   	push   %ebx
  800038:	83 ec 14             	sub    $0x14,%esp
	int i;

	cprintf("Hello, I am environment %08x.\n", thisenv->env_id);
  80003b:	a1 04 20 80 00       	mov    0x802004,%eax
  800040:	8b 40 48             	mov    0x48(%eax),%eax
  800043:	89 44 24 04          	mov    %eax,0x4(%esp)
  800047:	c7 04 24 40 13 80 00 	movl   $0x801340,(%esp)
  80004e:	e8 78 01 00 00       	call   8001cb <cprintf>
	for (i = 0; i < 5; i++) {
  800053:	bb 00 00 00 00       	mov    $0x0,%ebx
		sys_yield();
  800058:	e8 df 0c 00 00       	call   800d3c <sys_yield>
		cprintf("Back in environment %08x, iteration %d.\n",
			thisenv->env_id, i);
  80005d:	a1 04 20 80 00       	mov    0x802004,%eax
	int i;

	cprintf("Hello, I am environment %08x.\n", thisenv->env_id);
	for (i = 0; i < 5; i++) {
		sys_yield();
		cprintf("Back in environment %08x, iteration %d.\n",
  800062:	8b 40 48             	mov    0x48(%eax),%eax
  800065:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800069:	89 44 24 04          	mov    %eax,0x4(%esp)
  80006d:	c7 04 24 60 13 80 00 	movl   $0x801360,(%esp)
  800074:	e8 52 01 00 00       	call   8001cb <cprintf>
umain(int argc, char **argv)
{
	int i;

	cprintf("Hello, I am environment %08x.\n", thisenv->env_id);
	for (i = 0; i < 5; i++) {
  800079:	83 c3 01             	add    $0x1,%ebx
  80007c:	83 fb 05             	cmp    $0x5,%ebx
  80007f:	75 d7                	jne    800058 <umain+0x24>
		sys_yield();
		cprintf("Back in environment %08x, iteration %d.\n",
			thisenv->env_id, i);
	}
	cprintf("All done in environment %08x.\n", thisenv->env_id);
  800081:	a1 04 20 80 00       	mov    0x802004,%eax
  800086:	8b 40 48             	mov    0x48(%eax),%eax
  800089:	89 44 24 04          	mov    %eax,0x4(%esp)
  80008d:	c7 04 24 8c 13 80 00 	movl   $0x80138c,(%esp)
  800094:	e8 32 01 00 00       	call   8001cb <cprintf>
}
  800099:	83 c4 14             	add    $0x14,%esp
  80009c:	5b                   	pop    %ebx
  80009d:	5d                   	pop    %ebp
  80009e:	c3                   	ret    
  80009f:	90                   	nop

008000a0 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000a0:	55                   	push   %ebp
  8000a1:	89 e5                	mov    %esp,%ebp
  8000a3:	57                   	push   %edi
  8000a4:	56                   	push   %esi
  8000a5:	53                   	push   %ebx
  8000a6:	83 ec 1c             	sub    $0x1c,%esp
  8000a9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000ac:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  8000af:	e8 58 0c 00 00       	call   800d0c <sys_getenvid>
	thisenv = envs;
  8000b4:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  8000bb:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  8000be:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  8000c4:	39 c2                	cmp    %eax,%edx
  8000c6:	74 25                	je     8000ed <libmain+0x4d>
  8000c8:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  8000cd:	eb 12                	jmp    8000e1 <libmain+0x41>
  8000cf:	8b 4a 48             	mov    0x48(%edx),%ecx
  8000d2:	83 c2 7c             	add    $0x7c,%edx
  8000d5:	39 c1                	cmp    %eax,%ecx
  8000d7:	75 08                	jne    8000e1 <libmain+0x41>
  8000d9:	89 3d 04 20 80 00    	mov    %edi,0x802004
  8000df:	eb 0c                	jmp    8000ed <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  8000e1:	89 d7                	mov    %edx,%edi
  8000e3:	85 d2                	test   %edx,%edx
  8000e5:	75 e8                	jne    8000cf <libmain+0x2f>
  8000e7:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000ed:	85 db                	test   %ebx,%ebx
  8000ef:	7e 07                	jle    8000f8 <libmain+0x58>
		binaryname = argv[0];
  8000f1:	8b 06                	mov    (%esi),%eax
  8000f3:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000f8:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000fc:	89 1c 24             	mov    %ebx,(%esp)
  8000ff:	e8 30 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  800104:	e8 0b 00 00 00       	call   800114 <exit>
}
  800109:	83 c4 1c             	add    $0x1c,%esp
  80010c:	5b                   	pop    %ebx
  80010d:	5e                   	pop    %esi
  80010e:	5f                   	pop    %edi
  80010f:	5d                   	pop    %ebp
  800110:	c3                   	ret    
  800111:	66 90                	xchg   %ax,%ax
  800113:	90                   	nop

00800114 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800114:	55                   	push   %ebp
  800115:	89 e5                	mov    %esp,%ebp
  800117:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80011a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800121:	e8 89 0b 00 00       	call   800caf <sys_env_destroy>
}
  800126:	c9                   	leave  
  800127:	c3                   	ret    

00800128 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800128:	55                   	push   %ebp
  800129:	89 e5                	mov    %esp,%ebp
  80012b:	53                   	push   %ebx
  80012c:	83 ec 14             	sub    $0x14,%esp
  80012f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800132:	8b 03                	mov    (%ebx),%eax
  800134:	8b 55 08             	mov    0x8(%ebp),%edx
  800137:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  80013b:	83 c0 01             	add    $0x1,%eax
  80013e:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800140:	3d ff 00 00 00       	cmp    $0xff,%eax
  800145:	75 19                	jne    800160 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800147:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80014e:	00 
  80014f:	8d 43 08             	lea    0x8(%ebx),%eax
  800152:	89 04 24             	mov    %eax,(%esp)
  800155:	e8 f6 0a 00 00       	call   800c50 <sys_cputs>
		b->idx = 0;
  80015a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800160:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800164:	83 c4 14             	add    $0x14,%esp
  800167:	5b                   	pop    %ebx
  800168:	5d                   	pop    %ebp
  800169:	c3                   	ret    

0080016a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80016a:	55                   	push   %ebp
  80016b:	89 e5                	mov    %esp,%ebp
  80016d:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800173:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80017a:	00 00 00 
	b.cnt = 0;
  80017d:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800184:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800187:	8b 45 0c             	mov    0xc(%ebp),%eax
  80018a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80018e:	8b 45 08             	mov    0x8(%ebp),%eax
  800191:	89 44 24 08          	mov    %eax,0x8(%esp)
  800195:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80019b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80019f:	c7 04 24 28 01 80 00 	movl   $0x800128,(%esp)
  8001a6:	e8 b7 01 00 00       	call   800362 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001ab:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8001b1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001b5:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001bb:	89 04 24             	mov    %eax,(%esp)
  8001be:	e8 8d 0a 00 00       	call   800c50 <sys_cputs>

	return b.cnt;
}
  8001c3:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001c9:	c9                   	leave  
  8001ca:	c3                   	ret    

008001cb <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001cb:	55                   	push   %ebp
  8001cc:	89 e5                	mov    %esp,%ebp
  8001ce:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001d1:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8001d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001d8:	8b 45 08             	mov    0x8(%ebp),%eax
  8001db:	89 04 24             	mov    %eax,(%esp)
  8001de:	e8 87 ff ff ff       	call   80016a <vcprintf>
	va_end(ap);

	return cnt;
}
  8001e3:	c9                   	leave  
  8001e4:	c3                   	ret    
  8001e5:	66 90                	xchg   %ax,%ax
  8001e7:	66 90                	xchg   %ax,%ax
  8001e9:	66 90                	xchg   %ax,%ax
  8001eb:	66 90                	xchg   %ax,%ax
  8001ed:	66 90                	xchg   %ax,%ax
  8001ef:	90                   	nop

008001f0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001f0:	55                   	push   %ebp
  8001f1:	89 e5                	mov    %esp,%ebp
  8001f3:	57                   	push   %edi
  8001f4:	56                   	push   %esi
  8001f5:	53                   	push   %ebx
  8001f6:	83 ec 4c             	sub    $0x4c,%esp
  8001f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8001fc:	89 d7                	mov    %edx,%edi
  8001fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800201:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800204:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800207:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80020a:	b8 00 00 00 00       	mov    $0x0,%eax
  80020f:	39 d8                	cmp    %ebx,%eax
  800211:	72 17                	jb     80022a <printnum+0x3a>
  800213:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800216:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800219:	76 0f                	jbe    80022a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80021b:	8b 75 14             	mov    0x14(%ebp),%esi
  80021e:	83 ee 01             	sub    $0x1,%esi
  800221:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800224:	85 f6                	test   %esi,%esi
  800226:	7f 63                	jg     80028b <printnum+0x9b>
  800228:	eb 75                	jmp    80029f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80022a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80022d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800231:	8b 45 14             	mov    0x14(%ebp),%eax
  800234:	83 e8 01             	sub    $0x1,%eax
  800237:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80023b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80023e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800242:	8b 44 24 08          	mov    0x8(%esp),%eax
  800246:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80024a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80024d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800250:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800257:	00 
  800258:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80025b:	89 1c 24             	mov    %ebx,(%esp)
  80025e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800261:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800265:	e8 e6 0d 00 00       	call   801050 <__udivdi3>
  80026a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80026d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800270:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800274:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800278:	89 04 24             	mov    %eax,(%esp)
  80027b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80027f:	89 fa                	mov    %edi,%edx
  800281:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800284:	e8 67 ff ff ff       	call   8001f0 <printnum>
  800289:	eb 14                	jmp    80029f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80028b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80028f:	8b 45 18             	mov    0x18(%ebp),%eax
  800292:	89 04 24             	mov    %eax,(%esp)
  800295:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800297:	83 ee 01             	sub    $0x1,%esi
  80029a:	75 ef                	jne    80028b <printnum+0x9b>
  80029c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80029f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002a3:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8002a7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002aa:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8002ae:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8002b5:	00 
  8002b6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002b9:	89 1c 24             	mov    %ebx,(%esp)
  8002bc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8002bf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002c3:	e8 d8 0e 00 00       	call   8011a0 <__umoddi3>
  8002c8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002cc:	0f be 80 b5 13 80 00 	movsbl 0x8013b5(%eax),%eax
  8002d3:	89 04 24             	mov    %eax,(%esp)
  8002d6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002d9:	ff d0                	call   *%eax
}
  8002db:	83 c4 4c             	add    $0x4c,%esp
  8002de:	5b                   	pop    %ebx
  8002df:	5e                   	pop    %esi
  8002e0:	5f                   	pop    %edi
  8002e1:	5d                   	pop    %ebp
  8002e2:	c3                   	ret    

008002e3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002e3:	55                   	push   %ebp
  8002e4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002e6:	83 fa 01             	cmp    $0x1,%edx
  8002e9:	7e 0e                	jle    8002f9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002eb:	8b 10                	mov    (%eax),%edx
  8002ed:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002f0:	89 08                	mov    %ecx,(%eax)
  8002f2:	8b 02                	mov    (%edx),%eax
  8002f4:	8b 52 04             	mov    0x4(%edx),%edx
  8002f7:	eb 22                	jmp    80031b <getuint+0x38>
	else if (lflag)
  8002f9:	85 d2                	test   %edx,%edx
  8002fb:	74 10                	je     80030d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002fd:	8b 10                	mov    (%eax),%edx
  8002ff:	8d 4a 04             	lea    0x4(%edx),%ecx
  800302:	89 08                	mov    %ecx,(%eax)
  800304:	8b 02                	mov    (%edx),%eax
  800306:	ba 00 00 00 00       	mov    $0x0,%edx
  80030b:	eb 0e                	jmp    80031b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80030d:	8b 10                	mov    (%eax),%edx
  80030f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800312:	89 08                	mov    %ecx,(%eax)
  800314:	8b 02                	mov    (%edx),%eax
  800316:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80031b:	5d                   	pop    %ebp
  80031c:	c3                   	ret    

0080031d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80031d:	55                   	push   %ebp
  80031e:	89 e5                	mov    %esp,%ebp
  800320:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800323:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800327:	8b 10                	mov    (%eax),%edx
  800329:	3b 50 04             	cmp    0x4(%eax),%edx
  80032c:	73 0a                	jae    800338 <sprintputch+0x1b>
		*b->buf++ = ch;
  80032e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800331:	88 0a                	mov    %cl,(%edx)
  800333:	83 c2 01             	add    $0x1,%edx
  800336:	89 10                	mov    %edx,(%eax)
}
  800338:	5d                   	pop    %ebp
  800339:	c3                   	ret    

0080033a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80033a:	55                   	push   %ebp
  80033b:	89 e5                	mov    %esp,%ebp
  80033d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800340:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800343:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800347:	8b 45 10             	mov    0x10(%ebp),%eax
  80034a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80034e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800351:	89 44 24 04          	mov    %eax,0x4(%esp)
  800355:	8b 45 08             	mov    0x8(%ebp),%eax
  800358:	89 04 24             	mov    %eax,(%esp)
  80035b:	e8 02 00 00 00       	call   800362 <vprintfmt>
	va_end(ap);
}
  800360:	c9                   	leave  
  800361:	c3                   	ret    

00800362 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800362:	55                   	push   %ebp
  800363:	89 e5                	mov    %esp,%ebp
  800365:	57                   	push   %edi
  800366:	56                   	push   %esi
  800367:	53                   	push   %ebx
  800368:	83 ec 4c             	sub    $0x4c,%esp
  80036b:	8b 75 08             	mov    0x8(%ebp),%esi
  80036e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800371:	8b 7d 10             	mov    0x10(%ebp),%edi
  800374:	eb 11                	jmp    800387 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800376:	85 c0                	test   %eax,%eax
  800378:	0f 84 db 03 00 00    	je     800759 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80037e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800382:	89 04 24             	mov    %eax,(%esp)
  800385:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800387:	0f b6 07             	movzbl (%edi),%eax
  80038a:	83 c7 01             	add    $0x1,%edi
  80038d:	83 f8 25             	cmp    $0x25,%eax
  800390:	75 e4                	jne    800376 <vprintfmt+0x14>
  800392:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800396:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80039d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8003a4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  8003ab:	ba 00 00 00 00       	mov    $0x0,%edx
  8003b0:	eb 2b                	jmp    8003dd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003b5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  8003b9:	eb 22                	jmp    8003dd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003be:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  8003c2:	eb 19                	jmp    8003dd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  8003c7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003ce:	eb 0d                	jmp    8003dd <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8003d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8003d3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8003d6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003dd:	0f b6 0f             	movzbl (%edi),%ecx
  8003e0:	8d 47 01             	lea    0x1(%edi),%eax
  8003e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003e6:	0f b6 07             	movzbl (%edi),%eax
  8003e9:	83 e8 23             	sub    $0x23,%eax
  8003ec:	3c 55                	cmp    $0x55,%al
  8003ee:	0f 87 40 03 00 00    	ja     800734 <vprintfmt+0x3d2>
  8003f4:	0f b6 c0             	movzbl %al,%eax
  8003f7:	ff 24 85 80 14 80 00 	jmp    *0x801480(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003fe:	83 e9 30             	sub    $0x30,%ecx
  800401:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800404:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800408:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80040b:	83 f9 09             	cmp    $0x9,%ecx
  80040e:	77 57                	ja     800467 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800410:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800413:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800416:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800419:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80041c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80041f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800423:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800426:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800429:	83 f9 09             	cmp    $0x9,%ecx
  80042c:	76 eb                	jbe    800419 <vprintfmt+0xb7>
  80042e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800431:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800434:	eb 34                	jmp    80046a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800436:	8b 45 14             	mov    0x14(%ebp),%eax
  800439:	8d 48 04             	lea    0x4(%eax),%ecx
  80043c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80043f:	8b 00                	mov    (%eax),%eax
  800441:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800444:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800447:	eb 21                	jmp    80046a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800449:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80044d:	0f 88 71 ff ff ff    	js     8003c4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800453:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800456:	eb 85                	jmp    8003dd <vprintfmt+0x7b>
  800458:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80045b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800462:	e9 76 ff ff ff       	jmp    8003dd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800467:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80046a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80046e:	0f 89 69 ff ff ff    	jns    8003dd <vprintfmt+0x7b>
  800474:	e9 57 ff ff ff       	jmp    8003d0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800479:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80047c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80047f:	e9 59 ff ff ff       	jmp    8003dd <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800484:	8b 45 14             	mov    0x14(%ebp),%eax
  800487:	8d 50 04             	lea    0x4(%eax),%edx
  80048a:	89 55 14             	mov    %edx,0x14(%ebp)
  80048d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800491:	8b 00                	mov    (%eax),%eax
  800493:	89 04 24             	mov    %eax,(%esp)
  800496:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800498:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80049b:	e9 e7 fe ff ff       	jmp    800387 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004a0:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a3:	8d 50 04             	lea    0x4(%eax),%edx
  8004a6:	89 55 14             	mov    %edx,0x14(%ebp)
  8004a9:	8b 00                	mov    (%eax),%eax
  8004ab:	89 c2                	mov    %eax,%edx
  8004ad:	c1 fa 1f             	sar    $0x1f,%edx
  8004b0:	31 d0                	xor    %edx,%eax
  8004b2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004b4:	83 f8 08             	cmp    $0x8,%eax
  8004b7:	7f 0b                	jg     8004c4 <vprintfmt+0x162>
  8004b9:	8b 14 85 e0 15 80 00 	mov    0x8015e0(,%eax,4),%edx
  8004c0:	85 d2                	test   %edx,%edx
  8004c2:	75 20                	jne    8004e4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  8004c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8004c8:	c7 44 24 08 cd 13 80 	movl   $0x8013cd,0x8(%esp)
  8004cf:	00 
  8004d0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004d4:	89 34 24             	mov    %esi,(%esp)
  8004d7:	e8 5e fe ff ff       	call   80033a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004dc:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004df:	e9 a3 fe ff ff       	jmp    800387 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8004e4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8004e8:	c7 44 24 08 d6 13 80 	movl   $0x8013d6,0x8(%esp)
  8004ef:	00 
  8004f0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004f4:	89 34 24             	mov    %esi,(%esp)
  8004f7:	e8 3e fe ff ff       	call   80033a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004fc:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004ff:	e9 83 fe ff ff       	jmp    800387 <vprintfmt+0x25>
  800504:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800507:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80050a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80050d:	8b 45 14             	mov    0x14(%ebp),%eax
  800510:	8d 50 04             	lea    0x4(%eax),%edx
  800513:	89 55 14             	mov    %edx,0x14(%ebp)
  800516:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800518:	85 ff                	test   %edi,%edi
  80051a:	b8 c6 13 80 00       	mov    $0x8013c6,%eax
  80051f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800522:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800526:	74 06                	je     80052e <vprintfmt+0x1cc>
  800528:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  80052c:	7f 16                	jg     800544 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80052e:	0f b6 17             	movzbl (%edi),%edx
  800531:	0f be c2             	movsbl %dl,%eax
  800534:	83 c7 01             	add    $0x1,%edi
  800537:	85 c0                	test   %eax,%eax
  800539:	0f 85 9f 00 00 00    	jne    8005de <vprintfmt+0x27c>
  80053f:	e9 8b 00 00 00       	jmp    8005cf <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800544:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800548:	89 3c 24             	mov    %edi,(%esp)
  80054b:	e8 c2 02 00 00       	call   800812 <strnlen>
  800550:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800553:	29 c2                	sub    %eax,%edx
  800555:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800558:	85 d2                	test   %edx,%edx
  80055a:	7e d2                	jle    80052e <vprintfmt+0x1cc>
					putch(padc, putdat);
  80055c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800560:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800563:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800566:	89 d7                	mov    %edx,%edi
  800568:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80056c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80056f:	89 04 24             	mov    %eax,(%esp)
  800572:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800574:	83 ef 01             	sub    $0x1,%edi
  800577:	75 ef                	jne    800568 <vprintfmt+0x206>
  800579:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80057c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80057f:	eb ad                	jmp    80052e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800581:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800585:	74 20                	je     8005a7 <vprintfmt+0x245>
  800587:	0f be d2             	movsbl %dl,%edx
  80058a:	83 ea 20             	sub    $0x20,%edx
  80058d:	83 fa 5e             	cmp    $0x5e,%edx
  800590:	76 15                	jbe    8005a7 <vprintfmt+0x245>
					putch('?', putdat);
  800592:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800595:	89 54 24 04          	mov    %edx,0x4(%esp)
  800599:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8005a0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8005a3:	ff d1                	call   *%ecx
  8005a5:	eb 0f                	jmp    8005b6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  8005a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8005aa:	89 54 24 04          	mov    %edx,0x4(%esp)
  8005ae:	89 04 24             	mov    %eax,(%esp)
  8005b1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8005b4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005b6:	83 eb 01             	sub    $0x1,%ebx
  8005b9:	0f b6 17             	movzbl (%edi),%edx
  8005bc:	0f be c2             	movsbl %dl,%eax
  8005bf:	83 c7 01             	add    $0x1,%edi
  8005c2:	85 c0                	test   %eax,%eax
  8005c4:	75 24                	jne    8005ea <vprintfmt+0x288>
  8005c6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005c9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8005cc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005cf:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005d2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8005d6:	0f 8e ab fd ff ff    	jle    800387 <vprintfmt+0x25>
  8005dc:	eb 20                	jmp    8005fe <vprintfmt+0x29c>
  8005de:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8005e1:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8005e4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8005e7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005ea:	85 f6                	test   %esi,%esi
  8005ec:	78 93                	js     800581 <vprintfmt+0x21f>
  8005ee:	83 ee 01             	sub    $0x1,%esi
  8005f1:	79 8e                	jns    800581 <vprintfmt+0x21f>
  8005f3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005f6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8005f9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8005fc:	eb d1                	jmp    8005cf <vprintfmt+0x26d>
  8005fe:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800601:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800605:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80060c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80060e:	83 ef 01             	sub    $0x1,%edi
  800611:	75 ee                	jne    800601 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800613:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800616:	e9 6c fd ff ff       	jmp    800387 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80061b:	83 fa 01             	cmp    $0x1,%edx
  80061e:	66 90                	xchg   %ax,%ax
  800620:	7e 16                	jle    800638 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800622:	8b 45 14             	mov    0x14(%ebp),%eax
  800625:	8d 50 08             	lea    0x8(%eax),%edx
  800628:	89 55 14             	mov    %edx,0x14(%ebp)
  80062b:	8b 10                	mov    (%eax),%edx
  80062d:	8b 48 04             	mov    0x4(%eax),%ecx
  800630:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800633:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800636:	eb 32                	jmp    80066a <vprintfmt+0x308>
	else if (lflag)
  800638:	85 d2                	test   %edx,%edx
  80063a:	74 18                	je     800654 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  80063c:	8b 45 14             	mov    0x14(%ebp),%eax
  80063f:	8d 50 04             	lea    0x4(%eax),%edx
  800642:	89 55 14             	mov    %edx,0x14(%ebp)
  800645:	8b 00                	mov    (%eax),%eax
  800647:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80064a:	89 c1                	mov    %eax,%ecx
  80064c:	c1 f9 1f             	sar    $0x1f,%ecx
  80064f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800652:	eb 16                	jmp    80066a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800654:	8b 45 14             	mov    0x14(%ebp),%eax
  800657:	8d 50 04             	lea    0x4(%eax),%edx
  80065a:	89 55 14             	mov    %edx,0x14(%ebp)
  80065d:	8b 00                	mov    (%eax),%eax
  80065f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800662:	89 c7                	mov    %eax,%edi
  800664:	c1 ff 1f             	sar    $0x1f,%edi
  800667:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80066a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80066d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800670:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800675:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800679:	79 7d                	jns    8006f8 <vprintfmt+0x396>
				putch('-', putdat);
  80067b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80067f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800686:	ff d6                	call   *%esi
				num = -(long long) num;
  800688:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80068b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80068e:	f7 d8                	neg    %eax
  800690:	83 d2 00             	adc    $0x0,%edx
  800693:	f7 da                	neg    %edx
			}
			base = 10;
  800695:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80069a:	eb 5c                	jmp    8006f8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80069c:	8d 45 14             	lea    0x14(%ebp),%eax
  80069f:	e8 3f fc ff ff       	call   8002e3 <getuint>
			base = 10;
  8006a4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8006a9:	eb 4d                	jmp    8006f8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  8006ab:	8d 45 14             	lea    0x14(%ebp),%eax
  8006ae:	e8 30 fc ff ff       	call   8002e3 <getuint>
			base = 8;
  8006b3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8006b8:	eb 3e                	jmp    8006f8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  8006ba:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006be:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8006c5:	ff d6                	call   *%esi
			putch('x', putdat);
  8006c7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006cb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8006d2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d7:	8d 50 04             	lea    0x4(%eax),%edx
  8006da:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8006dd:	8b 00                	mov    (%eax),%eax
  8006df:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006e4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006e9:	eb 0d                	jmp    8006f8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006eb:	8d 45 14             	lea    0x14(%ebp),%eax
  8006ee:	e8 f0 fb ff ff       	call   8002e3 <getuint>
			base = 16;
  8006f3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006f8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  8006fc:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800700:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800703:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800707:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80070b:	89 04 24             	mov    %eax,(%esp)
  80070e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800712:	89 da                	mov    %ebx,%edx
  800714:	89 f0                	mov    %esi,%eax
  800716:	e8 d5 fa ff ff       	call   8001f0 <printnum>
			break;
  80071b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80071e:	e9 64 fc ff ff       	jmp    800387 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800723:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800727:	89 0c 24             	mov    %ecx,(%esp)
  80072a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80072c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80072f:	e9 53 fc ff ff       	jmp    800387 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800734:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800738:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  80073f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800741:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800745:	0f 84 3c fc ff ff    	je     800387 <vprintfmt+0x25>
  80074b:	83 ef 01             	sub    $0x1,%edi
  80074e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800752:	75 f7                	jne    80074b <vprintfmt+0x3e9>
  800754:	e9 2e fc ff ff       	jmp    800387 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800759:	83 c4 4c             	add    $0x4c,%esp
  80075c:	5b                   	pop    %ebx
  80075d:	5e                   	pop    %esi
  80075e:	5f                   	pop    %edi
  80075f:	5d                   	pop    %ebp
  800760:	c3                   	ret    

00800761 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800761:	55                   	push   %ebp
  800762:	89 e5                	mov    %esp,%ebp
  800764:	83 ec 28             	sub    $0x28,%esp
  800767:	8b 45 08             	mov    0x8(%ebp),%eax
  80076a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80076d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800770:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800774:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800777:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80077e:	85 d2                	test   %edx,%edx
  800780:	7e 30                	jle    8007b2 <vsnprintf+0x51>
  800782:	85 c0                	test   %eax,%eax
  800784:	74 2c                	je     8007b2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800786:	8b 45 14             	mov    0x14(%ebp),%eax
  800789:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80078d:	8b 45 10             	mov    0x10(%ebp),%eax
  800790:	89 44 24 08          	mov    %eax,0x8(%esp)
  800794:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800797:	89 44 24 04          	mov    %eax,0x4(%esp)
  80079b:	c7 04 24 1d 03 80 00 	movl   $0x80031d,(%esp)
  8007a2:	e8 bb fb ff ff       	call   800362 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007aa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007b0:	eb 05                	jmp    8007b7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007b2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007b7:	c9                   	leave  
  8007b8:	c3                   	ret    

008007b9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007b9:	55                   	push   %ebp
  8007ba:	89 e5                	mov    %esp,%ebp
  8007bc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007bf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007c6:	8b 45 10             	mov    0x10(%ebp),%eax
  8007c9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007cd:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007d4:	8b 45 08             	mov    0x8(%ebp),%eax
  8007d7:	89 04 24             	mov    %eax,(%esp)
  8007da:	e8 82 ff ff ff       	call   800761 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007df:	c9                   	leave  
  8007e0:	c3                   	ret    
  8007e1:	66 90                	xchg   %ax,%ax
  8007e3:	66 90                	xchg   %ax,%ax
  8007e5:	66 90                	xchg   %ax,%ax
  8007e7:	66 90                	xchg   %ax,%ax
  8007e9:	66 90                	xchg   %ax,%ax
  8007eb:	66 90                	xchg   %ax,%ax
  8007ed:	66 90                	xchg   %ax,%ax
  8007ef:	90                   	nop

008007f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007f0:	55                   	push   %ebp
  8007f1:	89 e5                	mov    %esp,%ebp
  8007f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f6:	80 3a 00             	cmpb   $0x0,(%edx)
  8007f9:	74 10                	je     80080b <strlen+0x1b>
  8007fb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800800:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800803:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800807:	75 f7                	jne    800800 <strlen+0x10>
  800809:	eb 05                	jmp    800810 <strlen+0x20>
  80080b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800810:	5d                   	pop    %ebp
  800811:	c3                   	ret    

00800812 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800812:	55                   	push   %ebp
  800813:	89 e5                	mov    %esp,%ebp
  800815:	53                   	push   %ebx
  800816:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800819:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80081c:	85 c9                	test   %ecx,%ecx
  80081e:	74 1c                	je     80083c <strnlen+0x2a>
  800820:	80 3b 00             	cmpb   $0x0,(%ebx)
  800823:	74 1e                	je     800843 <strnlen+0x31>
  800825:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80082a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80082c:	39 ca                	cmp    %ecx,%edx
  80082e:	74 18                	je     800848 <strnlen+0x36>
  800830:	83 c2 01             	add    $0x1,%edx
  800833:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800838:	75 f0                	jne    80082a <strnlen+0x18>
  80083a:	eb 0c                	jmp    800848 <strnlen+0x36>
  80083c:	b8 00 00 00 00       	mov    $0x0,%eax
  800841:	eb 05                	jmp    800848 <strnlen+0x36>
  800843:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800848:	5b                   	pop    %ebx
  800849:	5d                   	pop    %ebp
  80084a:	c3                   	ret    

0080084b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80084b:	55                   	push   %ebp
  80084c:	89 e5                	mov    %esp,%ebp
  80084e:	53                   	push   %ebx
  80084f:	8b 45 08             	mov    0x8(%ebp),%eax
  800852:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800855:	89 c2                	mov    %eax,%edx
  800857:	0f b6 19             	movzbl (%ecx),%ebx
  80085a:	88 1a                	mov    %bl,(%edx)
  80085c:	83 c2 01             	add    $0x1,%edx
  80085f:	83 c1 01             	add    $0x1,%ecx
  800862:	84 db                	test   %bl,%bl
  800864:	75 f1                	jne    800857 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800866:	5b                   	pop    %ebx
  800867:	5d                   	pop    %ebp
  800868:	c3                   	ret    

00800869 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800869:	55                   	push   %ebp
  80086a:	89 e5                	mov    %esp,%ebp
  80086c:	53                   	push   %ebx
  80086d:	83 ec 08             	sub    $0x8,%esp
  800870:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800873:	89 1c 24             	mov    %ebx,(%esp)
  800876:	e8 75 ff ff ff       	call   8007f0 <strlen>
	strcpy(dst + len, src);
  80087b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80087e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800882:	01 d8                	add    %ebx,%eax
  800884:	89 04 24             	mov    %eax,(%esp)
  800887:	e8 bf ff ff ff       	call   80084b <strcpy>
	return dst;
}
  80088c:	89 d8                	mov    %ebx,%eax
  80088e:	83 c4 08             	add    $0x8,%esp
  800891:	5b                   	pop    %ebx
  800892:	5d                   	pop    %ebp
  800893:	c3                   	ret    

00800894 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800894:	55                   	push   %ebp
  800895:	89 e5                	mov    %esp,%ebp
  800897:	56                   	push   %esi
  800898:	53                   	push   %ebx
  800899:	8b 75 08             	mov    0x8(%ebp),%esi
  80089c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80089f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008a2:	85 db                	test   %ebx,%ebx
  8008a4:	74 16                	je     8008bc <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  8008a6:	01 f3                	add    %esi,%ebx
  8008a8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  8008aa:	0f b6 02             	movzbl (%edx),%eax
  8008ad:	88 01                	mov    %al,(%ecx)
  8008af:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008b2:	80 3a 01             	cmpb   $0x1,(%edx)
  8008b5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008b8:	39 d9                	cmp    %ebx,%ecx
  8008ba:	75 ee                	jne    8008aa <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008bc:	89 f0                	mov    %esi,%eax
  8008be:	5b                   	pop    %ebx
  8008bf:	5e                   	pop    %esi
  8008c0:	5d                   	pop    %ebp
  8008c1:	c3                   	ret    

008008c2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008c2:	55                   	push   %ebp
  8008c3:	89 e5                	mov    %esp,%ebp
  8008c5:	57                   	push   %edi
  8008c6:	56                   	push   %esi
  8008c7:	53                   	push   %ebx
  8008c8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008cb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8008ce:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008d1:	89 f8                	mov    %edi,%eax
  8008d3:	85 f6                	test   %esi,%esi
  8008d5:	74 33                	je     80090a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  8008d7:	83 fe 01             	cmp    $0x1,%esi
  8008da:	74 25                	je     800901 <strlcpy+0x3f>
  8008dc:	0f b6 0b             	movzbl (%ebx),%ecx
  8008df:	84 c9                	test   %cl,%cl
  8008e1:	74 22                	je     800905 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  8008e3:	83 ee 02             	sub    $0x2,%esi
  8008e6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008eb:	88 08                	mov    %cl,(%eax)
  8008ed:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008f0:	39 f2                	cmp    %esi,%edx
  8008f2:	74 13                	je     800907 <strlcpy+0x45>
  8008f4:	83 c2 01             	add    $0x1,%edx
  8008f7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  8008fb:	84 c9                	test   %cl,%cl
  8008fd:	75 ec                	jne    8008eb <strlcpy+0x29>
  8008ff:	eb 06                	jmp    800907 <strlcpy+0x45>
  800901:	89 f8                	mov    %edi,%eax
  800903:	eb 02                	jmp    800907 <strlcpy+0x45>
  800905:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800907:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80090a:	29 f8                	sub    %edi,%eax
}
  80090c:	5b                   	pop    %ebx
  80090d:	5e                   	pop    %esi
  80090e:	5f                   	pop    %edi
  80090f:	5d                   	pop    %ebp
  800910:	c3                   	ret    

00800911 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800911:	55                   	push   %ebp
  800912:	89 e5                	mov    %esp,%ebp
  800914:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800917:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80091a:	0f b6 01             	movzbl (%ecx),%eax
  80091d:	84 c0                	test   %al,%al
  80091f:	74 15                	je     800936 <strcmp+0x25>
  800921:	3a 02                	cmp    (%edx),%al
  800923:	75 11                	jne    800936 <strcmp+0x25>
		p++, q++;
  800925:	83 c1 01             	add    $0x1,%ecx
  800928:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80092b:	0f b6 01             	movzbl (%ecx),%eax
  80092e:	84 c0                	test   %al,%al
  800930:	74 04                	je     800936 <strcmp+0x25>
  800932:	3a 02                	cmp    (%edx),%al
  800934:	74 ef                	je     800925 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800936:	0f b6 c0             	movzbl %al,%eax
  800939:	0f b6 12             	movzbl (%edx),%edx
  80093c:	29 d0                	sub    %edx,%eax
}
  80093e:	5d                   	pop    %ebp
  80093f:	c3                   	ret    

00800940 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800940:	55                   	push   %ebp
  800941:	89 e5                	mov    %esp,%ebp
  800943:	56                   	push   %esi
  800944:	53                   	push   %ebx
  800945:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800948:	8b 55 0c             	mov    0xc(%ebp),%edx
  80094b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  80094e:	85 f6                	test   %esi,%esi
  800950:	74 29                	je     80097b <strncmp+0x3b>
  800952:	0f b6 03             	movzbl (%ebx),%eax
  800955:	84 c0                	test   %al,%al
  800957:	74 30                	je     800989 <strncmp+0x49>
  800959:	3a 02                	cmp    (%edx),%al
  80095b:	75 2c                	jne    800989 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  80095d:	8d 43 01             	lea    0x1(%ebx),%eax
  800960:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800962:	89 c3                	mov    %eax,%ebx
  800964:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800967:	39 f0                	cmp    %esi,%eax
  800969:	74 17                	je     800982 <strncmp+0x42>
  80096b:	0f b6 08             	movzbl (%eax),%ecx
  80096e:	84 c9                	test   %cl,%cl
  800970:	74 17                	je     800989 <strncmp+0x49>
  800972:	83 c0 01             	add    $0x1,%eax
  800975:	3a 0a                	cmp    (%edx),%cl
  800977:	74 e9                	je     800962 <strncmp+0x22>
  800979:	eb 0e                	jmp    800989 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  80097b:	b8 00 00 00 00       	mov    $0x0,%eax
  800980:	eb 0f                	jmp    800991 <strncmp+0x51>
  800982:	b8 00 00 00 00       	mov    $0x0,%eax
  800987:	eb 08                	jmp    800991 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800989:	0f b6 03             	movzbl (%ebx),%eax
  80098c:	0f b6 12             	movzbl (%edx),%edx
  80098f:	29 d0                	sub    %edx,%eax
}
  800991:	5b                   	pop    %ebx
  800992:	5e                   	pop    %esi
  800993:	5d                   	pop    %ebp
  800994:	c3                   	ret    

00800995 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800995:	55                   	push   %ebp
  800996:	89 e5                	mov    %esp,%ebp
  800998:	53                   	push   %ebx
  800999:	8b 45 08             	mov    0x8(%ebp),%eax
  80099c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  80099f:	0f b6 18             	movzbl (%eax),%ebx
  8009a2:	84 db                	test   %bl,%bl
  8009a4:	74 1d                	je     8009c3 <strchr+0x2e>
  8009a6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  8009a8:	38 d3                	cmp    %dl,%bl
  8009aa:	75 06                	jne    8009b2 <strchr+0x1d>
  8009ac:	eb 1a                	jmp    8009c8 <strchr+0x33>
  8009ae:	38 ca                	cmp    %cl,%dl
  8009b0:	74 16                	je     8009c8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009b2:	83 c0 01             	add    $0x1,%eax
  8009b5:	0f b6 10             	movzbl (%eax),%edx
  8009b8:	84 d2                	test   %dl,%dl
  8009ba:	75 f2                	jne    8009ae <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  8009bc:	b8 00 00 00 00       	mov    $0x0,%eax
  8009c1:	eb 05                	jmp    8009c8 <strchr+0x33>
  8009c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c8:	5b                   	pop    %ebx
  8009c9:	5d                   	pop    %ebp
  8009ca:	c3                   	ret    

008009cb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009cb:	55                   	push   %ebp
  8009cc:	89 e5                	mov    %esp,%ebp
  8009ce:	53                   	push   %ebx
  8009cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  8009d5:	0f b6 18             	movzbl (%eax),%ebx
  8009d8:	84 db                	test   %bl,%bl
  8009da:	74 16                	je     8009f2 <strfind+0x27>
  8009dc:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  8009de:	38 d3                	cmp    %dl,%bl
  8009e0:	75 06                	jne    8009e8 <strfind+0x1d>
  8009e2:	eb 0e                	jmp    8009f2 <strfind+0x27>
  8009e4:	38 ca                	cmp    %cl,%dl
  8009e6:	74 0a                	je     8009f2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8009e8:	83 c0 01             	add    $0x1,%eax
  8009eb:	0f b6 10             	movzbl (%eax),%edx
  8009ee:	84 d2                	test   %dl,%dl
  8009f0:	75 f2                	jne    8009e4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  8009f2:	5b                   	pop    %ebx
  8009f3:	5d                   	pop    %ebp
  8009f4:	c3                   	ret    

008009f5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009f5:	55                   	push   %ebp
  8009f6:	89 e5                	mov    %esp,%ebp
  8009f8:	83 ec 0c             	sub    $0xc,%esp
  8009fb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8009fe:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a01:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a04:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a07:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a0a:	85 c9                	test   %ecx,%ecx
  800a0c:	74 36                	je     800a44 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a0e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a14:	75 28                	jne    800a3e <memset+0x49>
  800a16:	f6 c1 03             	test   $0x3,%cl
  800a19:	75 23                	jne    800a3e <memset+0x49>
		c &= 0xFF;
  800a1b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a1f:	89 d3                	mov    %edx,%ebx
  800a21:	c1 e3 08             	shl    $0x8,%ebx
  800a24:	89 d6                	mov    %edx,%esi
  800a26:	c1 e6 18             	shl    $0x18,%esi
  800a29:	89 d0                	mov    %edx,%eax
  800a2b:	c1 e0 10             	shl    $0x10,%eax
  800a2e:	09 f0                	or     %esi,%eax
  800a30:	09 c2                	or     %eax,%edx
  800a32:	89 d0                	mov    %edx,%eax
  800a34:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a36:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a39:	fc                   	cld    
  800a3a:	f3 ab                	rep stos %eax,%es:(%edi)
  800a3c:	eb 06                	jmp    800a44 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a3e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a41:	fc                   	cld    
  800a42:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a44:	89 f8                	mov    %edi,%eax
  800a46:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a49:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a4c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a4f:	89 ec                	mov    %ebp,%esp
  800a51:	5d                   	pop    %ebp
  800a52:	c3                   	ret    

00800a53 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a53:	55                   	push   %ebp
  800a54:	89 e5                	mov    %esp,%ebp
  800a56:	83 ec 08             	sub    $0x8,%esp
  800a59:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a5c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a5f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a62:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a65:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a68:	39 c6                	cmp    %eax,%esi
  800a6a:	73 36                	jae    800aa2 <memmove+0x4f>
  800a6c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a6f:	39 d0                	cmp    %edx,%eax
  800a71:	73 2f                	jae    800aa2 <memmove+0x4f>
		s += n;
		d += n;
  800a73:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a76:	f6 c2 03             	test   $0x3,%dl
  800a79:	75 1b                	jne    800a96 <memmove+0x43>
  800a7b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a81:	75 13                	jne    800a96 <memmove+0x43>
  800a83:	f6 c1 03             	test   $0x3,%cl
  800a86:	75 0e                	jne    800a96 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a88:	83 ef 04             	sub    $0x4,%edi
  800a8b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a8e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a91:	fd                   	std    
  800a92:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a94:	eb 09                	jmp    800a9f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a96:	83 ef 01             	sub    $0x1,%edi
  800a99:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a9c:	fd                   	std    
  800a9d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a9f:	fc                   	cld    
  800aa0:	eb 20                	jmp    800ac2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800aa2:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800aa8:	75 13                	jne    800abd <memmove+0x6a>
  800aaa:	a8 03                	test   $0x3,%al
  800aac:	75 0f                	jne    800abd <memmove+0x6a>
  800aae:	f6 c1 03             	test   $0x3,%cl
  800ab1:	75 0a                	jne    800abd <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800ab3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800ab6:	89 c7                	mov    %eax,%edi
  800ab8:	fc                   	cld    
  800ab9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800abb:	eb 05                	jmp    800ac2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800abd:	89 c7                	mov    %eax,%edi
  800abf:	fc                   	cld    
  800ac0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ac2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ac5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ac8:	89 ec                	mov    %ebp,%esp
  800aca:	5d                   	pop    %ebp
  800acb:	c3                   	ret    

00800acc <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800acc:	55                   	push   %ebp
  800acd:	89 e5                	mov    %esp,%ebp
  800acf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ad2:	8b 45 10             	mov    0x10(%ebp),%eax
  800ad5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ad9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800adc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ae0:	8b 45 08             	mov    0x8(%ebp),%eax
  800ae3:	89 04 24             	mov    %eax,(%esp)
  800ae6:	e8 68 ff ff ff       	call   800a53 <memmove>
}
  800aeb:	c9                   	leave  
  800aec:	c3                   	ret    

00800aed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800aed:	55                   	push   %ebp
  800aee:	89 e5                	mov    %esp,%ebp
  800af0:	57                   	push   %edi
  800af1:	56                   	push   %esi
  800af2:	53                   	push   %ebx
  800af3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800af6:	8b 75 0c             	mov    0xc(%ebp),%esi
  800af9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800afc:	8d 78 ff             	lea    -0x1(%eax),%edi
  800aff:	85 c0                	test   %eax,%eax
  800b01:	74 36                	je     800b39 <memcmp+0x4c>
		if (*s1 != *s2)
  800b03:	0f b6 03             	movzbl (%ebx),%eax
  800b06:	0f b6 0e             	movzbl (%esi),%ecx
  800b09:	38 c8                	cmp    %cl,%al
  800b0b:	75 17                	jne    800b24 <memcmp+0x37>
  800b0d:	ba 00 00 00 00       	mov    $0x0,%edx
  800b12:	eb 1a                	jmp    800b2e <memcmp+0x41>
  800b14:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800b19:	83 c2 01             	add    $0x1,%edx
  800b1c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800b20:	38 c8                	cmp    %cl,%al
  800b22:	74 0a                	je     800b2e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800b24:	0f b6 c0             	movzbl %al,%eax
  800b27:	0f b6 c9             	movzbl %cl,%ecx
  800b2a:	29 c8                	sub    %ecx,%eax
  800b2c:	eb 10                	jmp    800b3e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b2e:	39 fa                	cmp    %edi,%edx
  800b30:	75 e2                	jne    800b14 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b32:	b8 00 00 00 00       	mov    $0x0,%eax
  800b37:	eb 05                	jmp    800b3e <memcmp+0x51>
  800b39:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b3e:	5b                   	pop    %ebx
  800b3f:	5e                   	pop    %esi
  800b40:	5f                   	pop    %edi
  800b41:	5d                   	pop    %ebp
  800b42:	c3                   	ret    

00800b43 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b43:	55                   	push   %ebp
  800b44:	89 e5                	mov    %esp,%ebp
  800b46:	53                   	push   %ebx
  800b47:	8b 45 08             	mov    0x8(%ebp),%eax
  800b4a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800b4d:	89 c2                	mov    %eax,%edx
  800b4f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b52:	39 d0                	cmp    %edx,%eax
  800b54:	73 13                	jae    800b69 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b56:	89 d9                	mov    %ebx,%ecx
  800b58:	38 18                	cmp    %bl,(%eax)
  800b5a:	75 06                	jne    800b62 <memfind+0x1f>
  800b5c:	eb 0b                	jmp    800b69 <memfind+0x26>
  800b5e:	38 08                	cmp    %cl,(%eax)
  800b60:	74 07                	je     800b69 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b62:	83 c0 01             	add    $0x1,%eax
  800b65:	39 d0                	cmp    %edx,%eax
  800b67:	75 f5                	jne    800b5e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b69:	5b                   	pop    %ebx
  800b6a:	5d                   	pop    %ebp
  800b6b:	c3                   	ret    

00800b6c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b6c:	55                   	push   %ebp
  800b6d:	89 e5                	mov    %esp,%ebp
  800b6f:	57                   	push   %edi
  800b70:	56                   	push   %esi
  800b71:	53                   	push   %ebx
  800b72:	83 ec 04             	sub    $0x4,%esp
  800b75:	8b 55 08             	mov    0x8(%ebp),%edx
  800b78:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b7b:	0f b6 02             	movzbl (%edx),%eax
  800b7e:	3c 09                	cmp    $0x9,%al
  800b80:	74 04                	je     800b86 <strtol+0x1a>
  800b82:	3c 20                	cmp    $0x20,%al
  800b84:	75 0e                	jne    800b94 <strtol+0x28>
		s++;
  800b86:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b89:	0f b6 02             	movzbl (%edx),%eax
  800b8c:	3c 09                	cmp    $0x9,%al
  800b8e:	74 f6                	je     800b86 <strtol+0x1a>
  800b90:	3c 20                	cmp    $0x20,%al
  800b92:	74 f2                	je     800b86 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b94:	3c 2b                	cmp    $0x2b,%al
  800b96:	75 0a                	jne    800ba2 <strtol+0x36>
		s++;
  800b98:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b9b:	bf 00 00 00 00       	mov    $0x0,%edi
  800ba0:	eb 10                	jmp    800bb2 <strtol+0x46>
  800ba2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ba7:	3c 2d                	cmp    $0x2d,%al
  800ba9:	75 07                	jne    800bb2 <strtol+0x46>
		s++, neg = 1;
  800bab:	83 c2 01             	add    $0x1,%edx
  800bae:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800bb2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800bb8:	75 15                	jne    800bcf <strtol+0x63>
  800bba:	80 3a 30             	cmpb   $0x30,(%edx)
  800bbd:	75 10                	jne    800bcf <strtol+0x63>
  800bbf:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800bc3:	75 0a                	jne    800bcf <strtol+0x63>
		s += 2, base = 16;
  800bc5:	83 c2 02             	add    $0x2,%edx
  800bc8:	bb 10 00 00 00       	mov    $0x10,%ebx
  800bcd:	eb 10                	jmp    800bdf <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800bcf:	85 db                	test   %ebx,%ebx
  800bd1:	75 0c                	jne    800bdf <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bd3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bd5:	80 3a 30             	cmpb   $0x30,(%edx)
  800bd8:	75 05                	jne    800bdf <strtol+0x73>
		s++, base = 8;
  800bda:	83 c2 01             	add    $0x1,%edx
  800bdd:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800bdf:	b8 00 00 00 00       	mov    $0x0,%eax
  800be4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800be7:	0f b6 0a             	movzbl (%edx),%ecx
  800bea:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800bed:	89 f3                	mov    %esi,%ebx
  800bef:	80 fb 09             	cmp    $0x9,%bl
  800bf2:	77 08                	ja     800bfc <strtol+0x90>
			dig = *s - '0';
  800bf4:	0f be c9             	movsbl %cl,%ecx
  800bf7:	83 e9 30             	sub    $0x30,%ecx
  800bfa:	eb 22                	jmp    800c1e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800bfc:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800bff:	89 f3                	mov    %esi,%ebx
  800c01:	80 fb 19             	cmp    $0x19,%bl
  800c04:	77 08                	ja     800c0e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800c06:	0f be c9             	movsbl %cl,%ecx
  800c09:	83 e9 57             	sub    $0x57,%ecx
  800c0c:	eb 10                	jmp    800c1e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800c0e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800c11:	89 f3                	mov    %esi,%ebx
  800c13:	80 fb 19             	cmp    $0x19,%bl
  800c16:	77 16                	ja     800c2e <strtol+0xc2>
			dig = *s - 'A' + 10;
  800c18:	0f be c9             	movsbl %cl,%ecx
  800c1b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c1e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800c21:	7d 0f                	jge    800c32 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800c23:	83 c2 01             	add    $0x1,%edx
  800c26:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800c2a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800c2c:	eb b9                	jmp    800be7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800c2e:	89 c1                	mov    %eax,%ecx
  800c30:	eb 02                	jmp    800c34 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800c32:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800c34:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c38:	74 05                	je     800c3f <strtol+0xd3>
		*endptr = (char *) s;
  800c3a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c3d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800c3f:	89 ca                	mov    %ecx,%edx
  800c41:	f7 da                	neg    %edx
  800c43:	85 ff                	test   %edi,%edi
  800c45:	0f 45 c2             	cmovne %edx,%eax
}
  800c48:	83 c4 04             	add    $0x4,%esp
  800c4b:	5b                   	pop    %ebx
  800c4c:	5e                   	pop    %esi
  800c4d:	5f                   	pop    %edi
  800c4e:	5d                   	pop    %ebp
  800c4f:	c3                   	ret    

00800c50 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800c50:	55                   	push   %ebp
  800c51:	89 e5                	mov    %esp,%ebp
  800c53:	83 ec 0c             	sub    $0xc,%esp
  800c56:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c59:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c5c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c5f:	b8 00 00 00 00       	mov    $0x0,%eax
  800c64:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c67:	8b 55 08             	mov    0x8(%ebp),%edx
  800c6a:	89 c3                	mov    %eax,%ebx
  800c6c:	89 c7                	mov    %eax,%edi
  800c6e:	89 c6                	mov    %eax,%esi
  800c70:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c72:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c75:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c78:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c7b:	89 ec                	mov    %ebp,%esp
  800c7d:	5d                   	pop    %ebp
  800c7e:	c3                   	ret    

00800c7f <sys_cgetc>:

int
sys_cgetc(void)
{
  800c7f:	55                   	push   %ebp
  800c80:	89 e5                	mov    %esp,%ebp
  800c82:	83 ec 0c             	sub    $0xc,%esp
  800c85:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c88:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c8b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c8e:	ba 00 00 00 00       	mov    $0x0,%edx
  800c93:	b8 01 00 00 00       	mov    $0x1,%eax
  800c98:	89 d1                	mov    %edx,%ecx
  800c9a:	89 d3                	mov    %edx,%ebx
  800c9c:	89 d7                	mov    %edx,%edi
  800c9e:	89 d6                	mov    %edx,%esi
  800ca0:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ca2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800ca5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ca8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cab:	89 ec                	mov    %ebp,%esp
  800cad:	5d                   	pop    %ebp
  800cae:	c3                   	ret    

00800caf <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800caf:	55                   	push   %ebp
  800cb0:	89 e5                	mov    %esp,%ebp
  800cb2:	83 ec 38             	sub    $0x38,%esp
  800cb5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800cb8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800cbb:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cbe:	b9 00 00 00 00       	mov    $0x0,%ecx
  800cc3:	b8 03 00 00 00       	mov    $0x3,%eax
  800cc8:	8b 55 08             	mov    0x8(%ebp),%edx
  800ccb:	89 cb                	mov    %ecx,%ebx
  800ccd:	89 cf                	mov    %ecx,%edi
  800ccf:	89 ce                	mov    %ecx,%esi
  800cd1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cd3:	85 c0                	test   %eax,%eax
  800cd5:	7e 28                	jle    800cff <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cd7:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cdb:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800ce2:	00 
  800ce3:	c7 44 24 08 04 16 80 	movl   $0x801604,0x8(%esp)
  800cea:	00 
  800ceb:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800cf2:	00 
  800cf3:	c7 04 24 21 16 80 00 	movl   $0x801621,(%esp)
  800cfa:	e8 d5 02 00 00       	call   800fd4 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800cff:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d02:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d05:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d08:	89 ec                	mov    %ebp,%esp
  800d0a:	5d                   	pop    %ebp
  800d0b:	c3                   	ret    

00800d0c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800d0c:	55                   	push   %ebp
  800d0d:	89 e5                	mov    %esp,%ebp
  800d0f:	83 ec 0c             	sub    $0xc,%esp
  800d12:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d15:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d18:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d1b:	ba 00 00 00 00       	mov    $0x0,%edx
  800d20:	b8 02 00 00 00       	mov    $0x2,%eax
  800d25:	89 d1                	mov    %edx,%ecx
  800d27:	89 d3                	mov    %edx,%ebx
  800d29:	89 d7                	mov    %edx,%edi
  800d2b:	89 d6                	mov    %edx,%esi
  800d2d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800d2f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d32:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d35:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d38:	89 ec                	mov    %ebp,%esp
  800d3a:	5d                   	pop    %ebp
  800d3b:	c3                   	ret    

00800d3c <sys_yield>:

void
sys_yield(void)
{
  800d3c:	55                   	push   %ebp
  800d3d:	89 e5                	mov    %esp,%ebp
  800d3f:	83 ec 0c             	sub    $0xc,%esp
  800d42:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d45:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d48:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d4b:	ba 00 00 00 00       	mov    $0x0,%edx
  800d50:	b8 0a 00 00 00       	mov    $0xa,%eax
  800d55:	89 d1                	mov    %edx,%ecx
  800d57:	89 d3                	mov    %edx,%ebx
  800d59:	89 d7                	mov    %edx,%edi
  800d5b:	89 d6                	mov    %edx,%esi
  800d5d:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800d5f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d62:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d65:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d68:	89 ec                	mov    %ebp,%esp
  800d6a:	5d                   	pop    %ebp
  800d6b:	c3                   	ret    

00800d6c <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800d6c:	55                   	push   %ebp
  800d6d:	89 e5                	mov    %esp,%ebp
  800d6f:	83 ec 38             	sub    $0x38,%esp
  800d72:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d75:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d78:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d7b:	be 00 00 00 00       	mov    $0x0,%esi
  800d80:	b8 04 00 00 00       	mov    $0x4,%eax
  800d85:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d88:	8b 55 08             	mov    0x8(%ebp),%edx
  800d8b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d8e:	89 f7                	mov    %esi,%edi
  800d90:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d92:	85 c0                	test   %eax,%eax
  800d94:	7e 28                	jle    800dbe <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d96:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d9a:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800da1:	00 
  800da2:	c7 44 24 08 04 16 80 	movl   $0x801604,0x8(%esp)
  800da9:	00 
  800daa:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800db1:	00 
  800db2:	c7 04 24 21 16 80 00 	movl   $0x801621,(%esp)
  800db9:	e8 16 02 00 00       	call   800fd4 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800dbe:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800dc1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800dc4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800dc7:	89 ec                	mov    %ebp,%esp
  800dc9:	5d                   	pop    %ebp
  800dca:	c3                   	ret    

00800dcb <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800dcb:	55                   	push   %ebp
  800dcc:	89 e5                	mov    %esp,%ebp
  800dce:	83 ec 38             	sub    $0x38,%esp
  800dd1:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800dd4:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800dd7:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dda:	b8 05 00 00 00       	mov    $0x5,%eax
  800ddf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800de2:	8b 55 08             	mov    0x8(%ebp),%edx
  800de5:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800de8:	8b 7d 14             	mov    0x14(%ebp),%edi
  800deb:	8b 75 18             	mov    0x18(%ebp),%esi
  800dee:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800df0:	85 c0                	test   %eax,%eax
  800df2:	7e 28                	jle    800e1c <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800df4:	89 44 24 10          	mov    %eax,0x10(%esp)
  800df8:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800dff:	00 
  800e00:	c7 44 24 08 04 16 80 	movl   $0x801604,0x8(%esp)
  800e07:	00 
  800e08:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e0f:	00 
  800e10:	c7 04 24 21 16 80 00 	movl   $0x801621,(%esp)
  800e17:	e8 b8 01 00 00       	call   800fd4 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800e1c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e1f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e22:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e25:	89 ec                	mov    %ebp,%esp
  800e27:	5d                   	pop    %ebp
  800e28:	c3                   	ret    

00800e29 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800e29:	55                   	push   %ebp
  800e2a:	89 e5                	mov    %esp,%ebp
  800e2c:	83 ec 38             	sub    $0x38,%esp
  800e2f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e32:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e35:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e38:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e3d:	b8 06 00 00 00       	mov    $0x6,%eax
  800e42:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e45:	8b 55 08             	mov    0x8(%ebp),%edx
  800e48:	89 df                	mov    %ebx,%edi
  800e4a:	89 de                	mov    %ebx,%esi
  800e4c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e4e:	85 c0                	test   %eax,%eax
  800e50:	7e 28                	jle    800e7a <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e52:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e56:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800e5d:	00 
  800e5e:	c7 44 24 08 04 16 80 	movl   $0x801604,0x8(%esp)
  800e65:	00 
  800e66:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e6d:	00 
  800e6e:	c7 04 24 21 16 80 00 	movl   $0x801621,(%esp)
  800e75:	e8 5a 01 00 00       	call   800fd4 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800e7a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e7d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e80:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e83:	89 ec                	mov    %ebp,%esp
  800e85:	5d                   	pop    %ebp
  800e86:	c3                   	ret    

00800e87 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800e87:	55                   	push   %ebp
  800e88:	89 e5                	mov    %esp,%ebp
  800e8a:	83 ec 38             	sub    $0x38,%esp
  800e8d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e90:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e93:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e96:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e9b:	b8 08 00 00 00       	mov    $0x8,%eax
  800ea0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ea3:	8b 55 08             	mov    0x8(%ebp),%edx
  800ea6:	89 df                	mov    %ebx,%edi
  800ea8:	89 de                	mov    %ebx,%esi
  800eaa:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800eac:	85 c0                	test   %eax,%eax
  800eae:	7e 28                	jle    800ed8 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800eb0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800eb4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800ebb:	00 
  800ebc:	c7 44 24 08 04 16 80 	movl   $0x801604,0x8(%esp)
  800ec3:	00 
  800ec4:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ecb:	00 
  800ecc:	c7 04 24 21 16 80 00 	movl   $0x801621,(%esp)
  800ed3:	e8 fc 00 00 00       	call   800fd4 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800ed8:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800edb:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ede:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ee1:	89 ec                	mov    %ebp,%esp
  800ee3:	5d                   	pop    %ebp
  800ee4:	c3                   	ret    

00800ee5 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800ee5:	55                   	push   %ebp
  800ee6:	89 e5                	mov    %esp,%ebp
  800ee8:	83 ec 38             	sub    $0x38,%esp
  800eeb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800eee:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ef1:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ef4:	bb 00 00 00 00       	mov    $0x0,%ebx
  800ef9:	b8 09 00 00 00       	mov    $0x9,%eax
  800efe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f01:	8b 55 08             	mov    0x8(%ebp),%edx
  800f04:	89 df                	mov    %ebx,%edi
  800f06:	89 de                	mov    %ebx,%esi
  800f08:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f0a:	85 c0                	test   %eax,%eax
  800f0c:	7e 28                	jle    800f36 <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f0e:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f12:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800f19:	00 
  800f1a:	c7 44 24 08 04 16 80 	movl   $0x801604,0x8(%esp)
  800f21:	00 
  800f22:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f29:	00 
  800f2a:	c7 04 24 21 16 80 00 	movl   $0x801621,(%esp)
  800f31:	e8 9e 00 00 00       	call   800fd4 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800f36:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f39:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f3c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f3f:	89 ec                	mov    %ebp,%esp
  800f41:	5d                   	pop    %ebp
  800f42:	c3                   	ret    

00800f43 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800f43:	55                   	push   %ebp
  800f44:	89 e5                	mov    %esp,%ebp
  800f46:	83 ec 0c             	sub    $0xc,%esp
  800f49:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f4c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f4f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f52:	be 00 00 00 00       	mov    $0x0,%esi
  800f57:	b8 0b 00 00 00       	mov    $0xb,%eax
  800f5c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f5f:	8b 55 08             	mov    0x8(%ebp),%edx
  800f62:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800f65:	8b 7d 14             	mov    0x14(%ebp),%edi
  800f68:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800f6a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f6d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f70:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f73:	89 ec                	mov    %ebp,%esp
  800f75:	5d                   	pop    %ebp
  800f76:	c3                   	ret    

00800f77 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800f77:	55                   	push   %ebp
  800f78:	89 e5                	mov    %esp,%ebp
  800f7a:	83 ec 38             	sub    $0x38,%esp
  800f7d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f80:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f83:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f86:	b9 00 00 00 00       	mov    $0x0,%ecx
  800f8b:	b8 0c 00 00 00       	mov    $0xc,%eax
  800f90:	8b 55 08             	mov    0x8(%ebp),%edx
  800f93:	89 cb                	mov    %ecx,%ebx
  800f95:	89 cf                	mov    %ecx,%edi
  800f97:	89 ce                	mov    %ecx,%esi
  800f99:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f9b:	85 c0                	test   %eax,%eax
  800f9d:	7e 28                	jle    800fc7 <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f9f:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fa3:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800faa:	00 
  800fab:	c7 44 24 08 04 16 80 	movl   $0x801604,0x8(%esp)
  800fb2:	00 
  800fb3:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800fba:	00 
  800fbb:	c7 04 24 21 16 80 00 	movl   $0x801621,(%esp)
  800fc2:	e8 0d 00 00 00       	call   800fd4 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800fc7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800fca:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800fcd:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800fd0:	89 ec                	mov    %ebp,%esp
  800fd2:	5d                   	pop    %ebp
  800fd3:	c3                   	ret    

00800fd4 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800fd4:	55                   	push   %ebp
  800fd5:	89 e5                	mov    %esp,%ebp
  800fd7:	56                   	push   %esi
  800fd8:	53                   	push   %ebx
  800fd9:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800fdc:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800fdf:	a1 08 20 80 00       	mov    0x802008,%eax
  800fe4:	85 c0                	test   %eax,%eax
  800fe6:	74 10                	je     800ff8 <_panic+0x24>
		cprintf("%s: ", argv0);
  800fe8:	89 44 24 04          	mov    %eax,0x4(%esp)
  800fec:	c7 04 24 2f 16 80 00 	movl   $0x80162f,(%esp)
  800ff3:	e8 d3 f1 ff ff       	call   8001cb <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800ff8:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ffe:	e8 09 fd ff ff       	call   800d0c <sys_getenvid>
  801003:	8b 55 0c             	mov    0xc(%ebp),%edx
  801006:	89 54 24 10          	mov    %edx,0x10(%esp)
  80100a:	8b 55 08             	mov    0x8(%ebp),%edx
  80100d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801011:	89 74 24 08          	mov    %esi,0x8(%esp)
  801015:	89 44 24 04          	mov    %eax,0x4(%esp)
  801019:	c7 04 24 38 16 80 00 	movl   $0x801638,(%esp)
  801020:	e8 a6 f1 ff ff       	call   8001cb <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801025:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  801029:	8b 45 10             	mov    0x10(%ebp),%eax
  80102c:	89 04 24             	mov    %eax,(%esp)
  80102f:	e8 36 f1 ff ff       	call   80016a <vcprintf>
	cprintf("\n");
  801034:	c7 04 24 34 16 80 00 	movl   $0x801634,(%esp)
  80103b:	e8 8b f1 ff ff       	call   8001cb <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  801040:	cc                   	int3   
  801041:	eb fd                	jmp    801040 <_panic+0x6c>
  801043:	66 90                	xchg   %ax,%ax
  801045:	66 90                	xchg   %ax,%ax
  801047:	66 90                	xchg   %ax,%ax
  801049:	66 90                	xchg   %ax,%ax
  80104b:	66 90                	xchg   %ax,%ax
  80104d:	66 90                	xchg   %ax,%ax
  80104f:	90                   	nop

00801050 <__udivdi3>:
  801050:	83 ec 1c             	sub    $0x1c,%esp
  801053:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  801057:	89 7c 24 14          	mov    %edi,0x14(%esp)
  80105b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  80105f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  801063:	8b 7c 24 20          	mov    0x20(%esp),%edi
  801067:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  80106b:	85 c0                	test   %eax,%eax
  80106d:	89 74 24 10          	mov    %esi,0x10(%esp)
  801071:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801075:	89 ea                	mov    %ebp,%edx
  801077:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80107b:	75 33                	jne    8010b0 <__udivdi3+0x60>
  80107d:	39 e9                	cmp    %ebp,%ecx
  80107f:	77 6f                	ja     8010f0 <__udivdi3+0xa0>
  801081:	85 c9                	test   %ecx,%ecx
  801083:	89 ce                	mov    %ecx,%esi
  801085:	75 0b                	jne    801092 <__udivdi3+0x42>
  801087:	b8 01 00 00 00       	mov    $0x1,%eax
  80108c:	31 d2                	xor    %edx,%edx
  80108e:	f7 f1                	div    %ecx
  801090:	89 c6                	mov    %eax,%esi
  801092:	31 d2                	xor    %edx,%edx
  801094:	89 e8                	mov    %ebp,%eax
  801096:	f7 f6                	div    %esi
  801098:	89 c5                	mov    %eax,%ebp
  80109a:	89 f8                	mov    %edi,%eax
  80109c:	f7 f6                	div    %esi
  80109e:	89 ea                	mov    %ebp,%edx
  8010a0:	8b 74 24 10          	mov    0x10(%esp),%esi
  8010a4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8010a8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8010ac:	83 c4 1c             	add    $0x1c,%esp
  8010af:	c3                   	ret    
  8010b0:	39 e8                	cmp    %ebp,%eax
  8010b2:	77 24                	ja     8010d8 <__udivdi3+0x88>
  8010b4:	0f bd c8             	bsr    %eax,%ecx
  8010b7:	83 f1 1f             	xor    $0x1f,%ecx
  8010ba:	89 0c 24             	mov    %ecx,(%esp)
  8010bd:	75 49                	jne    801108 <__udivdi3+0xb8>
  8010bf:	8b 74 24 08          	mov    0x8(%esp),%esi
  8010c3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  8010c7:	0f 86 ab 00 00 00    	jbe    801178 <__udivdi3+0x128>
  8010cd:	39 e8                	cmp    %ebp,%eax
  8010cf:	0f 82 a3 00 00 00    	jb     801178 <__udivdi3+0x128>
  8010d5:	8d 76 00             	lea    0x0(%esi),%esi
  8010d8:	31 d2                	xor    %edx,%edx
  8010da:	31 c0                	xor    %eax,%eax
  8010dc:	8b 74 24 10          	mov    0x10(%esp),%esi
  8010e0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8010e4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8010e8:	83 c4 1c             	add    $0x1c,%esp
  8010eb:	c3                   	ret    
  8010ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8010f0:	89 f8                	mov    %edi,%eax
  8010f2:	f7 f1                	div    %ecx
  8010f4:	31 d2                	xor    %edx,%edx
  8010f6:	8b 74 24 10          	mov    0x10(%esp),%esi
  8010fa:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8010fe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801102:	83 c4 1c             	add    $0x1c,%esp
  801105:	c3                   	ret    
  801106:	66 90                	xchg   %ax,%ax
  801108:	0f b6 0c 24          	movzbl (%esp),%ecx
  80110c:	89 c6                	mov    %eax,%esi
  80110e:	b8 20 00 00 00       	mov    $0x20,%eax
  801113:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  801117:	2b 04 24             	sub    (%esp),%eax
  80111a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  80111e:	d3 e6                	shl    %cl,%esi
  801120:	89 c1                	mov    %eax,%ecx
  801122:	d3 ed                	shr    %cl,%ebp
  801124:	0f b6 0c 24          	movzbl (%esp),%ecx
  801128:	09 f5                	or     %esi,%ebp
  80112a:	8b 74 24 04          	mov    0x4(%esp),%esi
  80112e:	d3 e6                	shl    %cl,%esi
  801130:	89 c1                	mov    %eax,%ecx
  801132:	89 74 24 04          	mov    %esi,0x4(%esp)
  801136:	89 d6                	mov    %edx,%esi
  801138:	d3 ee                	shr    %cl,%esi
  80113a:	0f b6 0c 24          	movzbl (%esp),%ecx
  80113e:	d3 e2                	shl    %cl,%edx
  801140:	89 c1                	mov    %eax,%ecx
  801142:	d3 ef                	shr    %cl,%edi
  801144:	09 d7                	or     %edx,%edi
  801146:	89 f2                	mov    %esi,%edx
  801148:	89 f8                	mov    %edi,%eax
  80114a:	f7 f5                	div    %ebp
  80114c:	89 d6                	mov    %edx,%esi
  80114e:	89 c7                	mov    %eax,%edi
  801150:	f7 64 24 04          	mull   0x4(%esp)
  801154:	39 d6                	cmp    %edx,%esi
  801156:	72 30                	jb     801188 <__udivdi3+0x138>
  801158:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  80115c:	0f b6 0c 24          	movzbl (%esp),%ecx
  801160:	d3 e5                	shl    %cl,%ebp
  801162:	39 c5                	cmp    %eax,%ebp
  801164:	73 04                	jae    80116a <__udivdi3+0x11a>
  801166:	39 d6                	cmp    %edx,%esi
  801168:	74 1e                	je     801188 <__udivdi3+0x138>
  80116a:	89 f8                	mov    %edi,%eax
  80116c:	31 d2                	xor    %edx,%edx
  80116e:	e9 69 ff ff ff       	jmp    8010dc <__udivdi3+0x8c>
  801173:	90                   	nop
  801174:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801178:	31 d2                	xor    %edx,%edx
  80117a:	b8 01 00 00 00       	mov    $0x1,%eax
  80117f:	e9 58 ff ff ff       	jmp    8010dc <__udivdi3+0x8c>
  801184:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801188:	8d 47 ff             	lea    -0x1(%edi),%eax
  80118b:	31 d2                	xor    %edx,%edx
  80118d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801191:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801195:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801199:	83 c4 1c             	add    $0x1c,%esp
  80119c:	c3                   	ret    
  80119d:	66 90                	xchg   %ax,%ax
  80119f:	90                   	nop

008011a0 <__umoddi3>:
  8011a0:	83 ec 2c             	sub    $0x2c,%esp
  8011a3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  8011a7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  8011ab:	89 74 24 20          	mov    %esi,0x20(%esp)
  8011af:	8b 74 24 38          	mov    0x38(%esp),%esi
  8011b3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  8011b7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  8011bb:	85 c0                	test   %eax,%eax
  8011bd:	89 c2                	mov    %eax,%edx
  8011bf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  8011c3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  8011c7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8011cb:	89 74 24 10          	mov    %esi,0x10(%esp)
  8011cf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  8011d3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8011d7:	75 1f                	jne    8011f8 <__umoddi3+0x58>
  8011d9:	39 fe                	cmp    %edi,%esi
  8011db:	76 63                	jbe    801240 <__umoddi3+0xa0>
  8011dd:	89 c8                	mov    %ecx,%eax
  8011df:	89 fa                	mov    %edi,%edx
  8011e1:	f7 f6                	div    %esi
  8011e3:	89 d0                	mov    %edx,%eax
  8011e5:	31 d2                	xor    %edx,%edx
  8011e7:	8b 74 24 20          	mov    0x20(%esp),%esi
  8011eb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8011ef:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8011f3:	83 c4 2c             	add    $0x2c,%esp
  8011f6:	c3                   	ret    
  8011f7:	90                   	nop
  8011f8:	39 f8                	cmp    %edi,%eax
  8011fa:	77 64                	ja     801260 <__umoddi3+0xc0>
  8011fc:	0f bd e8             	bsr    %eax,%ebp
  8011ff:	83 f5 1f             	xor    $0x1f,%ebp
  801202:	75 74                	jne    801278 <__umoddi3+0xd8>
  801204:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801208:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  80120c:	0f 87 0e 01 00 00    	ja     801320 <__umoddi3+0x180>
  801212:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  801216:	29 f1                	sub    %esi,%ecx
  801218:	19 c7                	sbb    %eax,%edi
  80121a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  80121e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801222:	8b 44 24 14          	mov    0x14(%esp),%eax
  801226:	8b 54 24 18          	mov    0x18(%esp),%edx
  80122a:	8b 74 24 20          	mov    0x20(%esp),%esi
  80122e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801232:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801236:	83 c4 2c             	add    $0x2c,%esp
  801239:	c3                   	ret    
  80123a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801240:	85 f6                	test   %esi,%esi
  801242:	89 f5                	mov    %esi,%ebp
  801244:	75 0b                	jne    801251 <__umoddi3+0xb1>
  801246:	b8 01 00 00 00       	mov    $0x1,%eax
  80124b:	31 d2                	xor    %edx,%edx
  80124d:	f7 f6                	div    %esi
  80124f:	89 c5                	mov    %eax,%ebp
  801251:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801255:	31 d2                	xor    %edx,%edx
  801257:	f7 f5                	div    %ebp
  801259:	89 c8                	mov    %ecx,%eax
  80125b:	f7 f5                	div    %ebp
  80125d:	eb 84                	jmp    8011e3 <__umoddi3+0x43>
  80125f:	90                   	nop
  801260:	89 c8                	mov    %ecx,%eax
  801262:	89 fa                	mov    %edi,%edx
  801264:	8b 74 24 20          	mov    0x20(%esp),%esi
  801268:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80126c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801270:	83 c4 2c             	add    $0x2c,%esp
  801273:	c3                   	ret    
  801274:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801278:	8b 44 24 10          	mov    0x10(%esp),%eax
  80127c:	be 20 00 00 00       	mov    $0x20,%esi
  801281:	89 e9                	mov    %ebp,%ecx
  801283:	29 ee                	sub    %ebp,%esi
  801285:	d3 e2                	shl    %cl,%edx
  801287:	89 f1                	mov    %esi,%ecx
  801289:	d3 e8                	shr    %cl,%eax
  80128b:	89 e9                	mov    %ebp,%ecx
  80128d:	09 d0                	or     %edx,%eax
  80128f:	89 fa                	mov    %edi,%edx
  801291:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801295:	8b 44 24 10          	mov    0x10(%esp),%eax
  801299:	d3 e0                	shl    %cl,%eax
  80129b:	89 f1                	mov    %esi,%ecx
  80129d:	89 44 24 10          	mov    %eax,0x10(%esp)
  8012a1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  8012a5:	d3 ea                	shr    %cl,%edx
  8012a7:	89 e9                	mov    %ebp,%ecx
  8012a9:	d3 e7                	shl    %cl,%edi
  8012ab:	89 f1                	mov    %esi,%ecx
  8012ad:	d3 e8                	shr    %cl,%eax
  8012af:	89 e9                	mov    %ebp,%ecx
  8012b1:	09 f8                	or     %edi,%eax
  8012b3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  8012b7:	f7 74 24 0c          	divl   0xc(%esp)
  8012bb:	d3 e7                	shl    %cl,%edi
  8012bd:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8012c1:	89 d7                	mov    %edx,%edi
  8012c3:	f7 64 24 10          	mull   0x10(%esp)
  8012c7:	39 d7                	cmp    %edx,%edi
  8012c9:	89 c1                	mov    %eax,%ecx
  8012cb:	89 54 24 14          	mov    %edx,0x14(%esp)
  8012cf:	72 3b                	jb     80130c <__umoddi3+0x16c>
  8012d1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  8012d5:	72 31                	jb     801308 <__umoddi3+0x168>
  8012d7:	8b 44 24 18          	mov    0x18(%esp),%eax
  8012db:	29 c8                	sub    %ecx,%eax
  8012dd:	19 d7                	sbb    %edx,%edi
  8012df:	89 e9                	mov    %ebp,%ecx
  8012e1:	89 fa                	mov    %edi,%edx
  8012e3:	d3 e8                	shr    %cl,%eax
  8012e5:	89 f1                	mov    %esi,%ecx
  8012e7:	d3 e2                	shl    %cl,%edx
  8012e9:	89 e9                	mov    %ebp,%ecx
  8012eb:	09 d0                	or     %edx,%eax
  8012ed:	89 fa                	mov    %edi,%edx
  8012ef:	d3 ea                	shr    %cl,%edx
  8012f1:	8b 74 24 20          	mov    0x20(%esp),%esi
  8012f5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8012f9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8012fd:	83 c4 2c             	add    $0x2c,%esp
  801300:	c3                   	ret    
  801301:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801308:	39 d7                	cmp    %edx,%edi
  80130a:	75 cb                	jne    8012d7 <__umoddi3+0x137>
  80130c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801310:	89 c1                	mov    %eax,%ecx
  801312:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801316:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80131a:	eb bb                	jmp    8012d7 <__umoddi3+0x137>
  80131c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801320:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801324:	0f 82 e8 fe ff ff    	jb     801212 <__umoddi3+0x72>
  80132a:	e9 f3 fe ff ff       	jmp    801222 <__umoddi3+0x82>

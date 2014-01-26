
obj/user/pingpongs：     文件格式 elf32-i386


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
  80002c:	e8 1b 01 00 00       	call   80014c <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	90                   	nop

00800034 <umain>:

uint32_t val;

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	57                   	push   %edi
  800038:	56                   	push   %esi
  800039:	53                   	push   %ebx
  80003a:	83 ec 4c             	sub    $0x4c,%esp
	envid_t who;
	uint32_t i;

	i = 0;
	if ((who = sfork()) != 0) {
  80003d:	e8 64 10 00 00       	call   8010a6 <sfork>
  800042:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800045:	85 c0                	test   %eax,%eax
  800047:	74 5e                	je     8000a7 <umain+0x73>
		cprintf("i am %08x; thisenv is %p\n", sys_getenvid(), thisenv);
  800049:	8b 1d 08 20 80 00    	mov    0x802008,%ebx
  80004f:	e8 68 0d 00 00       	call   800dbc <sys_getenvid>
  800054:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800058:	89 44 24 04          	mov    %eax,0x4(%esp)
  80005c:	c7 04 24 c0 14 80 00 	movl   $0x8014c0,(%esp)
  800063:	e8 0f 02 00 00       	call   800277 <cprintf>
		// get the ball rolling
		cprintf("send 0 from %x to %x\n", sys_getenvid(), who);
  800068:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  80006b:	e8 4c 0d 00 00       	call   800dbc <sys_getenvid>
  800070:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800074:	89 44 24 04          	mov    %eax,0x4(%esp)
  800078:	c7 04 24 da 14 80 00 	movl   $0x8014da,(%esp)
  80007f:	e8 f3 01 00 00       	call   800277 <cprintf>
		ipc_send(who, 0, 0, 0);
  800084:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80008b:	00 
  80008c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800093:	00 
  800094:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80009b:	00 
  80009c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80009f:	89 04 24             	mov    %eax,(%esp)
  8000a2:	e8 43 10 00 00       	call   8010ea <ipc_send>
	}

	while (1) {
		ipc_recv(&who, 0, 0);
  8000a7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8000ae:	00 
  8000af:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8000b6:	00 
  8000b7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  8000ba:	89 04 24             	mov    %eax,(%esp)
  8000bd:	e8 06 10 00 00       	call   8010c8 <ipc_recv>
		cprintf("%x got %d from %x (thisenv is %p %x)\n", sys_getenvid(), val, who, thisenv, thisenv->env_id);
  8000c2:	8b 1d 08 20 80 00    	mov    0x802008,%ebx
  8000c8:	8b 7b 48             	mov    0x48(%ebx),%edi
  8000cb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8000ce:	8b 15 04 20 80 00    	mov    0x802004,%edx
  8000d4:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  8000d7:	e8 e0 0c 00 00       	call   800dbc <sys_getenvid>
  8000dc:	89 7c 24 14          	mov    %edi,0x14(%esp)
  8000e0:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8000e4:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8000e8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8000eb:	89 54 24 08          	mov    %edx,0x8(%esp)
  8000ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  8000f3:	c7 04 24 f0 14 80 00 	movl   $0x8014f0,(%esp)
  8000fa:	e8 78 01 00 00       	call   800277 <cprintf>
		if (val == 10)
  8000ff:	a1 04 20 80 00       	mov    0x802004,%eax
  800104:	83 f8 0a             	cmp    $0xa,%eax
  800107:	74 38                	je     800141 <umain+0x10d>
			return;
		++val;
  800109:	83 c0 01             	add    $0x1,%eax
  80010c:	a3 04 20 80 00       	mov    %eax,0x802004
		ipc_send(who, 0, 0, 0);
  800111:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800118:	00 
  800119:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800120:	00 
  800121:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800128:	00 
  800129:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80012c:	89 04 24             	mov    %eax,(%esp)
  80012f:	e8 b6 0f 00 00       	call   8010ea <ipc_send>
		if (val == 10)
  800134:	83 3d 04 20 80 00 0a 	cmpl   $0xa,0x802004
  80013b:	0f 85 66 ff ff ff    	jne    8000a7 <umain+0x73>
			return;
	}

}
  800141:	83 c4 4c             	add    $0x4c,%esp
  800144:	5b                   	pop    %ebx
  800145:	5e                   	pop    %esi
  800146:	5f                   	pop    %edi
  800147:	5d                   	pop    %ebp
  800148:	c3                   	ret    
  800149:	66 90                	xchg   %ax,%ax
  80014b:	90                   	nop

0080014c <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80014c:	55                   	push   %ebp
  80014d:	89 e5                	mov    %esp,%ebp
  80014f:	57                   	push   %edi
  800150:	56                   	push   %esi
  800151:	53                   	push   %ebx
  800152:	83 ec 1c             	sub    $0x1c,%esp
  800155:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800158:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  80015b:	e8 5c 0c 00 00       	call   800dbc <sys_getenvid>
	thisenv = envs;
  800160:	c7 05 08 20 80 00 00 	movl   $0xeec00000,0x802008
  800167:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  80016a:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  800170:	39 c2                	cmp    %eax,%edx
  800172:	74 25                	je     800199 <libmain+0x4d>
  800174:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  800179:	eb 12                	jmp    80018d <libmain+0x41>
  80017b:	8b 4a 48             	mov    0x48(%edx),%ecx
  80017e:	83 c2 7c             	add    $0x7c,%edx
  800181:	39 c1                	cmp    %eax,%ecx
  800183:	75 08                	jne    80018d <libmain+0x41>
  800185:	89 3d 08 20 80 00    	mov    %edi,0x802008
  80018b:	eb 0c                	jmp    800199 <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  80018d:	89 d7                	mov    %edx,%edi
  80018f:	85 d2                	test   %edx,%edx
  800191:	75 e8                	jne    80017b <libmain+0x2f>
  800193:	89 15 08 20 80 00    	mov    %edx,0x802008
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800199:	85 db                	test   %ebx,%ebx
  80019b:	7e 07                	jle    8001a4 <libmain+0x58>
		binaryname = argv[0];
  80019d:	8b 06                	mov    (%esi),%eax
  80019f:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8001a4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8001a8:	89 1c 24             	mov    %ebx,(%esp)
  8001ab:	e8 84 fe ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  8001b0:	e8 0b 00 00 00       	call   8001c0 <exit>
}
  8001b5:	83 c4 1c             	add    $0x1c,%esp
  8001b8:	5b                   	pop    %ebx
  8001b9:	5e                   	pop    %esi
  8001ba:	5f                   	pop    %edi
  8001bb:	5d                   	pop    %ebp
  8001bc:	c3                   	ret    
  8001bd:	66 90                	xchg   %ax,%ax
  8001bf:	90                   	nop

008001c0 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8001c0:	55                   	push   %ebp
  8001c1:	89 e5                	mov    %esp,%ebp
  8001c3:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8001c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8001cd:	e8 8d 0b 00 00       	call   800d5f <sys_env_destroy>
}
  8001d2:	c9                   	leave  
  8001d3:	c3                   	ret    

008001d4 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001d4:	55                   	push   %ebp
  8001d5:	89 e5                	mov    %esp,%ebp
  8001d7:	53                   	push   %ebx
  8001d8:	83 ec 14             	sub    $0x14,%esp
  8001db:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001de:	8b 03                	mov    (%ebx),%eax
  8001e0:	8b 55 08             	mov    0x8(%ebp),%edx
  8001e3:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8001e7:	83 c0 01             	add    $0x1,%eax
  8001ea:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8001ec:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001f1:	75 19                	jne    80020c <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001f3:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001fa:	00 
  8001fb:	8d 43 08             	lea    0x8(%ebx),%eax
  8001fe:	89 04 24             	mov    %eax,(%esp)
  800201:	e8 fa 0a 00 00       	call   800d00 <sys_cputs>
		b->idx = 0;
  800206:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80020c:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800210:	83 c4 14             	add    $0x14,%esp
  800213:	5b                   	pop    %ebx
  800214:	5d                   	pop    %ebp
  800215:	c3                   	ret    

00800216 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800216:	55                   	push   %ebp
  800217:	89 e5                	mov    %esp,%ebp
  800219:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80021f:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800226:	00 00 00 
	b.cnt = 0;
  800229:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800230:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800233:	8b 45 0c             	mov    0xc(%ebp),%eax
  800236:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80023a:	8b 45 08             	mov    0x8(%ebp),%eax
  80023d:	89 44 24 08          	mov    %eax,0x8(%esp)
  800241:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800247:	89 44 24 04          	mov    %eax,0x4(%esp)
  80024b:	c7 04 24 d4 01 80 00 	movl   $0x8001d4,(%esp)
  800252:	e8 bb 01 00 00       	call   800412 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800257:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80025d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800261:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800267:	89 04 24             	mov    %eax,(%esp)
  80026a:	e8 91 0a 00 00       	call   800d00 <sys_cputs>

	return b.cnt;
}
  80026f:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800275:	c9                   	leave  
  800276:	c3                   	ret    

00800277 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800277:	55                   	push   %ebp
  800278:	89 e5                	mov    %esp,%ebp
  80027a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80027d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800280:	89 44 24 04          	mov    %eax,0x4(%esp)
  800284:	8b 45 08             	mov    0x8(%ebp),%eax
  800287:	89 04 24             	mov    %eax,(%esp)
  80028a:	e8 87 ff ff ff       	call   800216 <vcprintf>
	va_end(ap);

	return cnt;
}
  80028f:	c9                   	leave  
  800290:	c3                   	ret    
  800291:	66 90                	xchg   %ax,%ax
  800293:	66 90                	xchg   %ax,%ax
  800295:	66 90                	xchg   %ax,%ax
  800297:	66 90                	xchg   %ax,%ax
  800299:	66 90                	xchg   %ax,%ax
  80029b:	66 90                	xchg   %ax,%ax
  80029d:	66 90                	xchg   %ax,%ax
  80029f:	90                   	nop

008002a0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002a0:	55                   	push   %ebp
  8002a1:	89 e5                	mov    %esp,%ebp
  8002a3:	57                   	push   %edi
  8002a4:	56                   	push   %esi
  8002a5:	53                   	push   %ebx
  8002a6:	83 ec 4c             	sub    $0x4c,%esp
  8002a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8002ac:	89 d7                	mov    %edx,%edi
  8002ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8002b1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8002b4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002b7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002ba:	b8 00 00 00 00       	mov    $0x0,%eax
  8002bf:	39 d8                	cmp    %ebx,%eax
  8002c1:	72 17                	jb     8002da <printnum+0x3a>
  8002c3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002c6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8002c9:	76 0f                	jbe    8002da <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002cb:	8b 75 14             	mov    0x14(%ebp),%esi
  8002ce:	83 ee 01             	sub    $0x1,%esi
  8002d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8002d4:	85 f6                	test   %esi,%esi
  8002d6:	7f 63                	jg     80033b <printnum+0x9b>
  8002d8:	eb 75                	jmp    80034f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002da:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8002dd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8002e1:	8b 45 14             	mov    0x14(%ebp),%eax
  8002e4:	83 e8 01             	sub    $0x1,%eax
  8002e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002eb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8002f2:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002f6:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002fa:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002fd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800300:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800307:	00 
  800308:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80030b:	89 1c 24             	mov    %ebx,(%esp)
  80030e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800311:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800315:	e8 b6 0e 00 00       	call   8011d0 <__udivdi3>
  80031a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80031d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800320:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800324:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800328:	89 04 24             	mov    %eax,(%esp)
  80032b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80032f:	89 fa                	mov    %edi,%edx
  800331:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800334:	e8 67 ff ff ff       	call   8002a0 <printnum>
  800339:	eb 14                	jmp    80034f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80033b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80033f:	8b 45 18             	mov    0x18(%ebp),%eax
  800342:	89 04 24             	mov    %eax,(%esp)
  800345:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800347:	83 ee 01             	sub    $0x1,%esi
  80034a:	75 ef                	jne    80033b <printnum+0x9b>
  80034c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80034f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800353:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800357:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80035a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80035e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800365:	00 
  800366:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800369:	89 1c 24             	mov    %ebx,(%esp)
  80036c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80036f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800373:	e8 a8 0f 00 00       	call   801320 <__umoddi3>
  800378:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80037c:	0f be 80 20 15 80 00 	movsbl 0x801520(%eax),%eax
  800383:	89 04 24             	mov    %eax,(%esp)
  800386:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800389:	ff d0                	call   *%eax
}
  80038b:	83 c4 4c             	add    $0x4c,%esp
  80038e:	5b                   	pop    %ebx
  80038f:	5e                   	pop    %esi
  800390:	5f                   	pop    %edi
  800391:	5d                   	pop    %ebp
  800392:	c3                   	ret    

00800393 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800393:	55                   	push   %ebp
  800394:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800396:	83 fa 01             	cmp    $0x1,%edx
  800399:	7e 0e                	jle    8003a9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80039b:	8b 10                	mov    (%eax),%edx
  80039d:	8d 4a 08             	lea    0x8(%edx),%ecx
  8003a0:	89 08                	mov    %ecx,(%eax)
  8003a2:	8b 02                	mov    (%edx),%eax
  8003a4:	8b 52 04             	mov    0x4(%edx),%edx
  8003a7:	eb 22                	jmp    8003cb <getuint+0x38>
	else if (lflag)
  8003a9:	85 d2                	test   %edx,%edx
  8003ab:	74 10                	je     8003bd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003ad:	8b 10                	mov    (%eax),%edx
  8003af:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003b2:	89 08                	mov    %ecx,(%eax)
  8003b4:	8b 02                	mov    (%edx),%eax
  8003b6:	ba 00 00 00 00       	mov    $0x0,%edx
  8003bb:	eb 0e                	jmp    8003cb <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003bd:	8b 10                	mov    (%eax),%edx
  8003bf:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003c2:	89 08                	mov    %ecx,(%eax)
  8003c4:	8b 02                	mov    (%edx),%eax
  8003c6:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003cb:	5d                   	pop    %ebp
  8003cc:	c3                   	ret    

008003cd <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003cd:	55                   	push   %ebp
  8003ce:	89 e5                	mov    %esp,%ebp
  8003d0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003d3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003d7:	8b 10                	mov    (%eax),%edx
  8003d9:	3b 50 04             	cmp    0x4(%eax),%edx
  8003dc:	73 0a                	jae    8003e8 <sprintputch+0x1b>
		*b->buf++ = ch;
  8003de:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8003e1:	88 0a                	mov    %cl,(%edx)
  8003e3:	83 c2 01             	add    $0x1,%edx
  8003e6:	89 10                	mov    %edx,(%eax)
}
  8003e8:	5d                   	pop    %ebp
  8003e9:	c3                   	ret    

008003ea <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003ea:	55                   	push   %ebp
  8003eb:	89 e5                	mov    %esp,%ebp
  8003ed:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003f0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003f7:	8b 45 10             	mov    0x10(%ebp),%eax
  8003fa:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  800401:	89 44 24 04          	mov    %eax,0x4(%esp)
  800405:	8b 45 08             	mov    0x8(%ebp),%eax
  800408:	89 04 24             	mov    %eax,(%esp)
  80040b:	e8 02 00 00 00       	call   800412 <vprintfmt>
	va_end(ap);
}
  800410:	c9                   	leave  
  800411:	c3                   	ret    

00800412 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800412:	55                   	push   %ebp
  800413:	89 e5                	mov    %esp,%ebp
  800415:	57                   	push   %edi
  800416:	56                   	push   %esi
  800417:	53                   	push   %ebx
  800418:	83 ec 4c             	sub    $0x4c,%esp
  80041b:	8b 75 08             	mov    0x8(%ebp),%esi
  80041e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800421:	8b 7d 10             	mov    0x10(%ebp),%edi
  800424:	eb 11                	jmp    800437 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800426:	85 c0                	test   %eax,%eax
  800428:	0f 84 db 03 00 00    	je     800809 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80042e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800432:	89 04 24             	mov    %eax,(%esp)
  800435:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800437:	0f b6 07             	movzbl (%edi),%eax
  80043a:	83 c7 01             	add    $0x1,%edi
  80043d:	83 f8 25             	cmp    $0x25,%eax
  800440:	75 e4                	jne    800426 <vprintfmt+0x14>
  800442:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800446:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80044d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800454:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80045b:	ba 00 00 00 00       	mov    $0x0,%edx
  800460:	eb 2b                	jmp    80048d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800462:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800465:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800469:	eb 22                	jmp    80048d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80046e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800472:	eb 19                	jmp    80048d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800474:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800477:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80047e:	eb 0d                	jmp    80048d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800480:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800483:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800486:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80048d:	0f b6 0f             	movzbl (%edi),%ecx
  800490:	8d 47 01             	lea    0x1(%edi),%eax
  800493:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800496:	0f b6 07             	movzbl (%edi),%eax
  800499:	83 e8 23             	sub    $0x23,%eax
  80049c:	3c 55                	cmp    $0x55,%al
  80049e:	0f 87 40 03 00 00    	ja     8007e4 <vprintfmt+0x3d2>
  8004a4:	0f b6 c0             	movzbl %al,%eax
  8004a7:	ff 24 85 e0 15 80 00 	jmp    *0x8015e0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8004ae:	83 e9 30             	sub    $0x30,%ecx
  8004b1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  8004b4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  8004b8:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004bb:	83 f9 09             	cmp    $0x9,%ecx
  8004be:	77 57                	ja     800517 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c0:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004c3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8004c6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004c9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  8004cc:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8004cf:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8004d3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8004d6:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004d9:	83 f9 09             	cmp    $0x9,%ecx
  8004dc:	76 eb                	jbe    8004c9 <vprintfmt+0xb7>
  8004de:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004e1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  8004e4:	eb 34                	jmp    80051a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8004e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e9:	8d 48 04             	lea    0x4(%eax),%ecx
  8004ec:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004ef:	8b 00                	mov    (%eax),%eax
  8004f1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004f4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004f7:	eb 21                	jmp    80051a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  8004f9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004fd:	0f 88 71 ff ff ff    	js     800474 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800503:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800506:	eb 85                	jmp    80048d <vprintfmt+0x7b>
  800508:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80050b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800512:	e9 76 ff ff ff       	jmp    80048d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800517:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80051a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80051e:	0f 89 69 ff ff ff    	jns    80048d <vprintfmt+0x7b>
  800524:	e9 57 ff ff ff       	jmp    800480 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800529:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80052c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80052f:	e9 59 ff ff ff       	jmp    80048d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800534:	8b 45 14             	mov    0x14(%ebp),%eax
  800537:	8d 50 04             	lea    0x4(%eax),%edx
  80053a:	89 55 14             	mov    %edx,0x14(%ebp)
  80053d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800541:	8b 00                	mov    (%eax),%eax
  800543:	89 04 24             	mov    %eax,(%esp)
  800546:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800548:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80054b:	e9 e7 fe ff ff       	jmp    800437 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800550:	8b 45 14             	mov    0x14(%ebp),%eax
  800553:	8d 50 04             	lea    0x4(%eax),%edx
  800556:	89 55 14             	mov    %edx,0x14(%ebp)
  800559:	8b 00                	mov    (%eax),%eax
  80055b:	89 c2                	mov    %eax,%edx
  80055d:	c1 fa 1f             	sar    $0x1f,%edx
  800560:	31 d0                	xor    %edx,%eax
  800562:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800564:	83 f8 08             	cmp    $0x8,%eax
  800567:	7f 0b                	jg     800574 <vprintfmt+0x162>
  800569:	8b 14 85 40 17 80 00 	mov    0x801740(,%eax,4),%edx
  800570:	85 d2                	test   %edx,%edx
  800572:	75 20                	jne    800594 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800574:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800578:	c7 44 24 08 38 15 80 	movl   $0x801538,0x8(%esp)
  80057f:	00 
  800580:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800584:	89 34 24             	mov    %esi,(%esp)
  800587:	e8 5e fe ff ff       	call   8003ea <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80058c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80058f:	e9 a3 fe ff ff       	jmp    800437 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800594:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800598:	c7 44 24 08 41 15 80 	movl   $0x801541,0x8(%esp)
  80059f:	00 
  8005a0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005a4:	89 34 24             	mov    %esi,(%esp)
  8005a7:	e8 3e fe ff ff       	call   8003ea <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8005af:	e9 83 fe ff ff       	jmp    800437 <vprintfmt+0x25>
  8005b4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8005b7:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8005ba:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005bd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c0:	8d 50 04             	lea    0x4(%eax),%edx
  8005c3:	89 55 14             	mov    %edx,0x14(%ebp)
  8005c6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8005c8:	85 ff                	test   %edi,%edi
  8005ca:	b8 31 15 80 00       	mov    $0x801531,%eax
  8005cf:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8005d2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8005d6:	74 06                	je     8005de <vprintfmt+0x1cc>
  8005d8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8005dc:	7f 16                	jg     8005f4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005de:	0f b6 17             	movzbl (%edi),%edx
  8005e1:	0f be c2             	movsbl %dl,%eax
  8005e4:	83 c7 01             	add    $0x1,%edi
  8005e7:	85 c0                	test   %eax,%eax
  8005e9:	0f 85 9f 00 00 00    	jne    80068e <vprintfmt+0x27c>
  8005ef:	e9 8b 00 00 00       	jmp    80067f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005f4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005f8:	89 3c 24             	mov    %edi,(%esp)
  8005fb:	e8 c2 02 00 00       	call   8008c2 <strnlen>
  800600:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800603:	29 c2                	sub    %eax,%edx
  800605:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800608:	85 d2                	test   %edx,%edx
  80060a:	7e d2                	jle    8005de <vprintfmt+0x1cc>
					putch(padc, putdat);
  80060c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800610:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800613:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800616:	89 d7                	mov    %edx,%edi
  800618:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80061c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80061f:	89 04 24             	mov    %eax,(%esp)
  800622:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800624:	83 ef 01             	sub    $0x1,%edi
  800627:	75 ef                	jne    800618 <vprintfmt+0x206>
  800629:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80062c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80062f:	eb ad                	jmp    8005de <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800631:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800635:	74 20                	je     800657 <vprintfmt+0x245>
  800637:	0f be d2             	movsbl %dl,%edx
  80063a:	83 ea 20             	sub    $0x20,%edx
  80063d:	83 fa 5e             	cmp    $0x5e,%edx
  800640:	76 15                	jbe    800657 <vprintfmt+0x245>
					putch('?', putdat);
  800642:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800645:	89 54 24 04          	mov    %edx,0x4(%esp)
  800649:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800650:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800653:	ff d1                	call   *%ecx
  800655:	eb 0f                	jmp    800666 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800657:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80065a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80065e:	89 04 24             	mov    %eax,(%esp)
  800661:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800664:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800666:	83 eb 01             	sub    $0x1,%ebx
  800669:	0f b6 17             	movzbl (%edi),%edx
  80066c:	0f be c2             	movsbl %dl,%eax
  80066f:	83 c7 01             	add    $0x1,%edi
  800672:	85 c0                	test   %eax,%eax
  800674:	75 24                	jne    80069a <vprintfmt+0x288>
  800676:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800679:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80067c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80067f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800682:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800686:	0f 8e ab fd ff ff    	jle    800437 <vprintfmt+0x25>
  80068c:	eb 20                	jmp    8006ae <vprintfmt+0x29c>
  80068e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800691:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800694:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800697:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80069a:	85 f6                	test   %esi,%esi
  80069c:	78 93                	js     800631 <vprintfmt+0x21f>
  80069e:	83 ee 01             	sub    $0x1,%esi
  8006a1:	79 8e                	jns    800631 <vprintfmt+0x21f>
  8006a3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8006a6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006a9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8006ac:	eb d1                	jmp    80067f <vprintfmt+0x26d>
  8006ae:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8006b1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006b5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8006bc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006be:	83 ef 01             	sub    $0x1,%edi
  8006c1:	75 ee                	jne    8006b1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006c3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8006c6:	e9 6c fd ff ff       	jmp    800437 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006cb:	83 fa 01             	cmp    $0x1,%edx
  8006ce:	66 90                	xchg   %ax,%ax
  8006d0:	7e 16                	jle    8006e8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  8006d2:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d5:	8d 50 08             	lea    0x8(%eax),%edx
  8006d8:	89 55 14             	mov    %edx,0x14(%ebp)
  8006db:	8b 10                	mov    (%eax),%edx
  8006dd:	8b 48 04             	mov    0x4(%eax),%ecx
  8006e0:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8006e3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8006e6:	eb 32                	jmp    80071a <vprintfmt+0x308>
	else if (lflag)
  8006e8:	85 d2                	test   %edx,%edx
  8006ea:	74 18                	je     800704 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  8006ec:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ef:	8d 50 04             	lea    0x4(%eax),%edx
  8006f2:	89 55 14             	mov    %edx,0x14(%ebp)
  8006f5:	8b 00                	mov    (%eax),%eax
  8006f7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8006fa:	89 c1                	mov    %eax,%ecx
  8006fc:	c1 f9 1f             	sar    $0x1f,%ecx
  8006ff:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800702:	eb 16                	jmp    80071a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800704:	8b 45 14             	mov    0x14(%ebp),%eax
  800707:	8d 50 04             	lea    0x4(%eax),%edx
  80070a:	89 55 14             	mov    %edx,0x14(%ebp)
  80070d:	8b 00                	mov    (%eax),%eax
  80070f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800712:	89 c7                	mov    %eax,%edi
  800714:	c1 ff 1f             	sar    $0x1f,%edi
  800717:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80071a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80071d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800720:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800725:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800729:	79 7d                	jns    8007a8 <vprintfmt+0x396>
				putch('-', putdat);
  80072b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80072f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800736:	ff d6                	call   *%esi
				num = -(long long) num;
  800738:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80073b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80073e:	f7 d8                	neg    %eax
  800740:	83 d2 00             	adc    $0x0,%edx
  800743:	f7 da                	neg    %edx
			}
			base = 10;
  800745:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80074a:	eb 5c                	jmp    8007a8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80074c:	8d 45 14             	lea    0x14(%ebp),%eax
  80074f:	e8 3f fc ff ff       	call   800393 <getuint>
			base = 10;
  800754:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800759:	eb 4d                	jmp    8007a8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80075b:	8d 45 14             	lea    0x14(%ebp),%eax
  80075e:	e8 30 fc ff ff       	call   800393 <getuint>
			base = 8;
  800763:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800768:	eb 3e                	jmp    8007a8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  80076a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80076e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800775:	ff d6                	call   *%esi
			putch('x', putdat);
  800777:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80077b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800782:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800784:	8b 45 14             	mov    0x14(%ebp),%eax
  800787:	8d 50 04             	lea    0x4(%eax),%edx
  80078a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80078d:	8b 00                	mov    (%eax),%eax
  80078f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800794:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800799:	eb 0d                	jmp    8007a8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80079b:	8d 45 14             	lea    0x14(%ebp),%eax
  80079e:	e8 f0 fb ff ff       	call   800393 <getuint>
			base = 16;
  8007a3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007a8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  8007ac:	89 7c 24 10          	mov    %edi,0x10(%esp)
  8007b0:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8007b3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8007b7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8007bb:	89 04 24             	mov    %eax,(%esp)
  8007be:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007c2:	89 da                	mov    %ebx,%edx
  8007c4:	89 f0                	mov    %esi,%eax
  8007c6:	e8 d5 fa ff ff       	call   8002a0 <printnum>
			break;
  8007cb:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007ce:	e9 64 fc ff ff       	jmp    800437 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8007d3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007d7:	89 0c 24             	mov    %ecx,(%esp)
  8007da:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007dc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8007df:	e9 53 fc ff ff       	jmp    800437 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007e4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007e8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007ef:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007f1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8007f5:	0f 84 3c fc ff ff    	je     800437 <vprintfmt+0x25>
  8007fb:	83 ef 01             	sub    $0x1,%edi
  8007fe:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800802:	75 f7                	jne    8007fb <vprintfmt+0x3e9>
  800804:	e9 2e fc ff ff       	jmp    800437 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800809:	83 c4 4c             	add    $0x4c,%esp
  80080c:	5b                   	pop    %ebx
  80080d:	5e                   	pop    %esi
  80080e:	5f                   	pop    %edi
  80080f:	5d                   	pop    %ebp
  800810:	c3                   	ret    

00800811 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800811:	55                   	push   %ebp
  800812:	89 e5                	mov    %esp,%ebp
  800814:	83 ec 28             	sub    $0x28,%esp
  800817:	8b 45 08             	mov    0x8(%ebp),%eax
  80081a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80081d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800820:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800824:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800827:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80082e:	85 d2                	test   %edx,%edx
  800830:	7e 30                	jle    800862 <vsnprintf+0x51>
  800832:	85 c0                	test   %eax,%eax
  800834:	74 2c                	je     800862 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800836:	8b 45 14             	mov    0x14(%ebp),%eax
  800839:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80083d:	8b 45 10             	mov    0x10(%ebp),%eax
  800840:	89 44 24 08          	mov    %eax,0x8(%esp)
  800844:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800847:	89 44 24 04          	mov    %eax,0x4(%esp)
  80084b:	c7 04 24 cd 03 80 00 	movl   $0x8003cd,(%esp)
  800852:	e8 bb fb ff ff       	call   800412 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800857:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80085a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80085d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800860:	eb 05                	jmp    800867 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800862:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800867:	c9                   	leave  
  800868:	c3                   	ret    

00800869 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800869:	55                   	push   %ebp
  80086a:	89 e5                	mov    %esp,%ebp
  80086c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80086f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800872:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800876:	8b 45 10             	mov    0x10(%ebp),%eax
  800879:	89 44 24 08          	mov    %eax,0x8(%esp)
  80087d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800880:	89 44 24 04          	mov    %eax,0x4(%esp)
  800884:	8b 45 08             	mov    0x8(%ebp),%eax
  800887:	89 04 24             	mov    %eax,(%esp)
  80088a:	e8 82 ff ff ff       	call   800811 <vsnprintf>
	va_end(ap);

	return rc;
}
  80088f:	c9                   	leave  
  800890:	c3                   	ret    
  800891:	66 90                	xchg   %ax,%ax
  800893:	66 90                	xchg   %ax,%ax
  800895:	66 90                	xchg   %ax,%ax
  800897:	66 90                	xchg   %ax,%ax
  800899:	66 90                	xchg   %ax,%ax
  80089b:	66 90                	xchg   %ax,%ax
  80089d:	66 90                	xchg   %ax,%ax
  80089f:	90                   	nop

008008a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008a0:	55                   	push   %ebp
  8008a1:	89 e5                	mov    %esp,%ebp
  8008a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008a6:	80 3a 00             	cmpb   $0x0,(%edx)
  8008a9:	74 10                	je     8008bb <strlen+0x1b>
  8008ab:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  8008b0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008b3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008b7:	75 f7                	jne    8008b0 <strlen+0x10>
  8008b9:	eb 05                	jmp    8008c0 <strlen+0x20>
  8008bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8008c0:	5d                   	pop    %ebp
  8008c1:	c3                   	ret    

008008c2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008c2:	55                   	push   %ebp
  8008c3:	89 e5                	mov    %esp,%ebp
  8008c5:	53                   	push   %ebx
  8008c6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8008c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008cc:	85 c9                	test   %ecx,%ecx
  8008ce:	74 1c                	je     8008ec <strnlen+0x2a>
  8008d0:	80 3b 00             	cmpb   $0x0,(%ebx)
  8008d3:	74 1e                	je     8008f3 <strnlen+0x31>
  8008d5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  8008da:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008dc:	39 ca                	cmp    %ecx,%edx
  8008de:	74 18                	je     8008f8 <strnlen+0x36>
  8008e0:	83 c2 01             	add    $0x1,%edx
  8008e3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8008e8:	75 f0                	jne    8008da <strnlen+0x18>
  8008ea:	eb 0c                	jmp    8008f8 <strnlen+0x36>
  8008ec:	b8 00 00 00 00       	mov    $0x0,%eax
  8008f1:	eb 05                	jmp    8008f8 <strnlen+0x36>
  8008f3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8008f8:	5b                   	pop    %ebx
  8008f9:	5d                   	pop    %ebp
  8008fa:	c3                   	ret    

008008fb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008fb:	55                   	push   %ebp
  8008fc:	89 e5                	mov    %esp,%ebp
  8008fe:	53                   	push   %ebx
  8008ff:	8b 45 08             	mov    0x8(%ebp),%eax
  800902:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800905:	89 c2                	mov    %eax,%edx
  800907:	0f b6 19             	movzbl (%ecx),%ebx
  80090a:	88 1a                	mov    %bl,(%edx)
  80090c:	83 c2 01             	add    $0x1,%edx
  80090f:	83 c1 01             	add    $0x1,%ecx
  800912:	84 db                	test   %bl,%bl
  800914:	75 f1                	jne    800907 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800916:	5b                   	pop    %ebx
  800917:	5d                   	pop    %ebp
  800918:	c3                   	ret    

00800919 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800919:	55                   	push   %ebp
  80091a:	89 e5                	mov    %esp,%ebp
  80091c:	53                   	push   %ebx
  80091d:	83 ec 08             	sub    $0x8,%esp
  800920:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800923:	89 1c 24             	mov    %ebx,(%esp)
  800926:	e8 75 ff ff ff       	call   8008a0 <strlen>
	strcpy(dst + len, src);
  80092b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80092e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800932:	01 d8                	add    %ebx,%eax
  800934:	89 04 24             	mov    %eax,(%esp)
  800937:	e8 bf ff ff ff       	call   8008fb <strcpy>
	return dst;
}
  80093c:	89 d8                	mov    %ebx,%eax
  80093e:	83 c4 08             	add    $0x8,%esp
  800941:	5b                   	pop    %ebx
  800942:	5d                   	pop    %ebp
  800943:	c3                   	ret    

00800944 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800944:	55                   	push   %ebp
  800945:	89 e5                	mov    %esp,%ebp
  800947:	56                   	push   %esi
  800948:	53                   	push   %ebx
  800949:	8b 75 08             	mov    0x8(%ebp),%esi
  80094c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80094f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800952:	85 db                	test   %ebx,%ebx
  800954:	74 16                	je     80096c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800956:	01 f3                	add    %esi,%ebx
  800958:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  80095a:	0f b6 02             	movzbl (%edx),%eax
  80095d:	88 01                	mov    %al,(%ecx)
  80095f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800962:	80 3a 01             	cmpb   $0x1,(%edx)
  800965:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800968:	39 d9                	cmp    %ebx,%ecx
  80096a:	75 ee                	jne    80095a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80096c:	89 f0                	mov    %esi,%eax
  80096e:	5b                   	pop    %ebx
  80096f:	5e                   	pop    %esi
  800970:	5d                   	pop    %ebp
  800971:	c3                   	ret    

00800972 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800972:	55                   	push   %ebp
  800973:	89 e5                	mov    %esp,%ebp
  800975:	57                   	push   %edi
  800976:	56                   	push   %esi
  800977:	53                   	push   %ebx
  800978:	8b 7d 08             	mov    0x8(%ebp),%edi
  80097b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80097e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800981:	89 f8                	mov    %edi,%eax
  800983:	85 f6                	test   %esi,%esi
  800985:	74 33                	je     8009ba <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800987:	83 fe 01             	cmp    $0x1,%esi
  80098a:	74 25                	je     8009b1 <strlcpy+0x3f>
  80098c:	0f b6 0b             	movzbl (%ebx),%ecx
  80098f:	84 c9                	test   %cl,%cl
  800991:	74 22                	je     8009b5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800993:	83 ee 02             	sub    $0x2,%esi
  800996:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80099b:	88 08                	mov    %cl,(%eax)
  80099d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8009a0:	39 f2                	cmp    %esi,%edx
  8009a2:	74 13                	je     8009b7 <strlcpy+0x45>
  8009a4:	83 c2 01             	add    $0x1,%edx
  8009a7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  8009ab:	84 c9                	test   %cl,%cl
  8009ad:	75 ec                	jne    80099b <strlcpy+0x29>
  8009af:	eb 06                	jmp    8009b7 <strlcpy+0x45>
  8009b1:	89 f8                	mov    %edi,%eax
  8009b3:	eb 02                	jmp    8009b7 <strlcpy+0x45>
  8009b5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  8009b7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8009ba:	29 f8                	sub    %edi,%eax
}
  8009bc:	5b                   	pop    %ebx
  8009bd:	5e                   	pop    %esi
  8009be:	5f                   	pop    %edi
  8009bf:	5d                   	pop    %ebp
  8009c0:	c3                   	ret    

008009c1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8009c1:	55                   	push   %ebp
  8009c2:	89 e5                	mov    %esp,%ebp
  8009c4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009c7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8009ca:	0f b6 01             	movzbl (%ecx),%eax
  8009cd:	84 c0                	test   %al,%al
  8009cf:	74 15                	je     8009e6 <strcmp+0x25>
  8009d1:	3a 02                	cmp    (%edx),%al
  8009d3:	75 11                	jne    8009e6 <strcmp+0x25>
		p++, q++;
  8009d5:	83 c1 01             	add    $0x1,%ecx
  8009d8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8009db:	0f b6 01             	movzbl (%ecx),%eax
  8009de:	84 c0                	test   %al,%al
  8009e0:	74 04                	je     8009e6 <strcmp+0x25>
  8009e2:	3a 02                	cmp    (%edx),%al
  8009e4:	74 ef                	je     8009d5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009e6:	0f b6 c0             	movzbl %al,%eax
  8009e9:	0f b6 12             	movzbl (%edx),%edx
  8009ec:	29 d0                	sub    %edx,%eax
}
  8009ee:	5d                   	pop    %ebp
  8009ef:	c3                   	ret    

008009f0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009f0:	55                   	push   %ebp
  8009f1:	89 e5                	mov    %esp,%ebp
  8009f3:	56                   	push   %esi
  8009f4:	53                   	push   %ebx
  8009f5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8009f8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009fb:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  8009fe:	85 f6                	test   %esi,%esi
  800a00:	74 29                	je     800a2b <strncmp+0x3b>
  800a02:	0f b6 03             	movzbl (%ebx),%eax
  800a05:	84 c0                	test   %al,%al
  800a07:	74 30                	je     800a39 <strncmp+0x49>
  800a09:	3a 02                	cmp    (%edx),%al
  800a0b:	75 2c                	jne    800a39 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800a0d:	8d 43 01             	lea    0x1(%ebx),%eax
  800a10:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800a12:	89 c3                	mov    %eax,%ebx
  800a14:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800a17:	39 f0                	cmp    %esi,%eax
  800a19:	74 17                	je     800a32 <strncmp+0x42>
  800a1b:	0f b6 08             	movzbl (%eax),%ecx
  800a1e:	84 c9                	test   %cl,%cl
  800a20:	74 17                	je     800a39 <strncmp+0x49>
  800a22:	83 c0 01             	add    $0x1,%eax
  800a25:	3a 0a                	cmp    (%edx),%cl
  800a27:	74 e9                	je     800a12 <strncmp+0x22>
  800a29:	eb 0e                	jmp    800a39 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a2b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a30:	eb 0f                	jmp    800a41 <strncmp+0x51>
  800a32:	b8 00 00 00 00       	mov    $0x0,%eax
  800a37:	eb 08                	jmp    800a41 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a39:	0f b6 03             	movzbl (%ebx),%eax
  800a3c:	0f b6 12             	movzbl (%edx),%edx
  800a3f:	29 d0                	sub    %edx,%eax
}
  800a41:	5b                   	pop    %ebx
  800a42:	5e                   	pop    %esi
  800a43:	5d                   	pop    %ebp
  800a44:	c3                   	ret    

00800a45 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800a45:	55                   	push   %ebp
  800a46:	89 e5                	mov    %esp,%ebp
  800a48:	53                   	push   %ebx
  800a49:	8b 45 08             	mov    0x8(%ebp),%eax
  800a4c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a4f:	0f b6 18             	movzbl (%eax),%ebx
  800a52:	84 db                	test   %bl,%bl
  800a54:	74 1d                	je     800a73 <strchr+0x2e>
  800a56:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a58:	38 d3                	cmp    %dl,%bl
  800a5a:	75 06                	jne    800a62 <strchr+0x1d>
  800a5c:	eb 1a                	jmp    800a78 <strchr+0x33>
  800a5e:	38 ca                	cmp    %cl,%dl
  800a60:	74 16                	je     800a78 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a62:	83 c0 01             	add    $0x1,%eax
  800a65:	0f b6 10             	movzbl (%eax),%edx
  800a68:	84 d2                	test   %dl,%dl
  800a6a:	75 f2                	jne    800a5e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800a6c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a71:	eb 05                	jmp    800a78 <strchr+0x33>
  800a73:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a78:	5b                   	pop    %ebx
  800a79:	5d                   	pop    %ebp
  800a7a:	c3                   	ret    

00800a7b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a7b:	55                   	push   %ebp
  800a7c:	89 e5                	mov    %esp,%ebp
  800a7e:	53                   	push   %ebx
  800a7f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a82:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a85:	0f b6 18             	movzbl (%eax),%ebx
  800a88:	84 db                	test   %bl,%bl
  800a8a:	74 16                	je     800aa2 <strfind+0x27>
  800a8c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a8e:	38 d3                	cmp    %dl,%bl
  800a90:	75 06                	jne    800a98 <strfind+0x1d>
  800a92:	eb 0e                	jmp    800aa2 <strfind+0x27>
  800a94:	38 ca                	cmp    %cl,%dl
  800a96:	74 0a                	je     800aa2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800a98:	83 c0 01             	add    $0x1,%eax
  800a9b:	0f b6 10             	movzbl (%eax),%edx
  800a9e:	84 d2                	test   %dl,%dl
  800aa0:	75 f2                	jne    800a94 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800aa2:	5b                   	pop    %ebx
  800aa3:	5d                   	pop    %ebp
  800aa4:	c3                   	ret    

00800aa5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800aa5:	55                   	push   %ebp
  800aa6:	89 e5                	mov    %esp,%ebp
  800aa8:	83 ec 0c             	sub    $0xc,%esp
  800aab:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800aae:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ab1:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800ab4:	8b 7d 08             	mov    0x8(%ebp),%edi
  800ab7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800aba:	85 c9                	test   %ecx,%ecx
  800abc:	74 36                	je     800af4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800abe:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800ac4:	75 28                	jne    800aee <memset+0x49>
  800ac6:	f6 c1 03             	test   $0x3,%cl
  800ac9:	75 23                	jne    800aee <memset+0x49>
		c &= 0xFF;
  800acb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800acf:	89 d3                	mov    %edx,%ebx
  800ad1:	c1 e3 08             	shl    $0x8,%ebx
  800ad4:	89 d6                	mov    %edx,%esi
  800ad6:	c1 e6 18             	shl    $0x18,%esi
  800ad9:	89 d0                	mov    %edx,%eax
  800adb:	c1 e0 10             	shl    $0x10,%eax
  800ade:	09 f0                	or     %esi,%eax
  800ae0:	09 c2                	or     %eax,%edx
  800ae2:	89 d0                	mov    %edx,%eax
  800ae4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800ae6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800ae9:	fc                   	cld    
  800aea:	f3 ab                	rep stos %eax,%es:(%edi)
  800aec:	eb 06                	jmp    800af4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800aee:	8b 45 0c             	mov    0xc(%ebp),%eax
  800af1:	fc                   	cld    
  800af2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800af4:	89 f8                	mov    %edi,%eax
  800af6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800af9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800afc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800aff:	89 ec                	mov    %ebp,%esp
  800b01:	5d                   	pop    %ebp
  800b02:	c3                   	ret    

00800b03 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b03:	55                   	push   %ebp
  800b04:	89 e5                	mov    %esp,%ebp
  800b06:	83 ec 08             	sub    $0x8,%esp
  800b09:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b0c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800b0f:	8b 45 08             	mov    0x8(%ebp),%eax
  800b12:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b15:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b18:	39 c6                	cmp    %eax,%esi
  800b1a:	73 36                	jae    800b52 <memmove+0x4f>
  800b1c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b1f:	39 d0                	cmp    %edx,%eax
  800b21:	73 2f                	jae    800b52 <memmove+0x4f>
		s += n;
		d += n;
  800b23:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b26:	f6 c2 03             	test   $0x3,%dl
  800b29:	75 1b                	jne    800b46 <memmove+0x43>
  800b2b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b31:	75 13                	jne    800b46 <memmove+0x43>
  800b33:	f6 c1 03             	test   $0x3,%cl
  800b36:	75 0e                	jne    800b46 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800b38:	83 ef 04             	sub    $0x4,%edi
  800b3b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800b3e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800b41:	fd                   	std    
  800b42:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b44:	eb 09                	jmp    800b4f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800b46:	83 ef 01             	sub    $0x1,%edi
  800b49:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800b4c:	fd                   	std    
  800b4d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800b4f:	fc                   	cld    
  800b50:	eb 20                	jmp    800b72 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b52:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800b58:	75 13                	jne    800b6d <memmove+0x6a>
  800b5a:	a8 03                	test   $0x3,%al
  800b5c:	75 0f                	jne    800b6d <memmove+0x6a>
  800b5e:	f6 c1 03             	test   $0x3,%cl
  800b61:	75 0a                	jne    800b6d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800b63:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800b66:	89 c7                	mov    %eax,%edi
  800b68:	fc                   	cld    
  800b69:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b6b:	eb 05                	jmp    800b72 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b6d:	89 c7                	mov    %eax,%edi
  800b6f:	fc                   	cld    
  800b70:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b72:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b75:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b78:	89 ec                	mov    %ebp,%esp
  800b7a:	5d                   	pop    %ebp
  800b7b:	c3                   	ret    

00800b7c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800b7c:	55                   	push   %ebp
  800b7d:	89 e5                	mov    %esp,%ebp
  800b7f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800b82:	8b 45 10             	mov    0x10(%ebp),%eax
  800b85:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b89:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b8c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b90:	8b 45 08             	mov    0x8(%ebp),%eax
  800b93:	89 04 24             	mov    %eax,(%esp)
  800b96:	e8 68 ff ff ff       	call   800b03 <memmove>
}
  800b9b:	c9                   	leave  
  800b9c:	c3                   	ret    

00800b9d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b9d:	55                   	push   %ebp
  800b9e:	89 e5                	mov    %esp,%ebp
  800ba0:	57                   	push   %edi
  800ba1:	56                   	push   %esi
  800ba2:	53                   	push   %ebx
  800ba3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800ba6:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ba9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800bac:	8d 78 ff             	lea    -0x1(%eax),%edi
  800baf:	85 c0                	test   %eax,%eax
  800bb1:	74 36                	je     800be9 <memcmp+0x4c>
		if (*s1 != *s2)
  800bb3:	0f b6 03             	movzbl (%ebx),%eax
  800bb6:	0f b6 0e             	movzbl (%esi),%ecx
  800bb9:	38 c8                	cmp    %cl,%al
  800bbb:	75 17                	jne    800bd4 <memcmp+0x37>
  800bbd:	ba 00 00 00 00       	mov    $0x0,%edx
  800bc2:	eb 1a                	jmp    800bde <memcmp+0x41>
  800bc4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800bc9:	83 c2 01             	add    $0x1,%edx
  800bcc:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800bd0:	38 c8                	cmp    %cl,%al
  800bd2:	74 0a                	je     800bde <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800bd4:	0f b6 c0             	movzbl %al,%eax
  800bd7:	0f b6 c9             	movzbl %cl,%ecx
  800bda:	29 c8                	sub    %ecx,%eax
  800bdc:	eb 10                	jmp    800bee <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800bde:	39 fa                	cmp    %edi,%edx
  800be0:	75 e2                	jne    800bc4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800be2:	b8 00 00 00 00       	mov    $0x0,%eax
  800be7:	eb 05                	jmp    800bee <memcmp+0x51>
  800be9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800bee:	5b                   	pop    %ebx
  800bef:	5e                   	pop    %esi
  800bf0:	5f                   	pop    %edi
  800bf1:	5d                   	pop    %ebp
  800bf2:	c3                   	ret    

00800bf3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800bf3:	55                   	push   %ebp
  800bf4:	89 e5                	mov    %esp,%ebp
  800bf6:	53                   	push   %ebx
  800bf7:	8b 45 08             	mov    0x8(%ebp),%eax
  800bfa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800bfd:	89 c2                	mov    %eax,%edx
  800bff:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800c02:	39 d0                	cmp    %edx,%eax
  800c04:	73 13                	jae    800c19 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c06:	89 d9                	mov    %ebx,%ecx
  800c08:	38 18                	cmp    %bl,(%eax)
  800c0a:	75 06                	jne    800c12 <memfind+0x1f>
  800c0c:	eb 0b                	jmp    800c19 <memfind+0x26>
  800c0e:	38 08                	cmp    %cl,(%eax)
  800c10:	74 07                	je     800c19 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c12:	83 c0 01             	add    $0x1,%eax
  800c15:	39 d0                	cmp    %edx,%eax
  800c17:	75 f5                	jne    800c0e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c19:	5b                   	pop    %ebx
  800c1a:	5d                   	pop    %ebp
  800c1b:	c3                   	ret    

00800c1c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c1c:	55                   	push   %ebp
  800c1d:	89 e5                	mov    %esp,%ebp
  800c1f:	57                   	push   %edi
  800c20:	56                   	push   %esi
  800c21:	53                   	push   %ebx
  800c22:	83 ec 04             	sub    $0x4,%esp
  800c25:	8b 55 08             	mov    0x8(%ebp),%edx
  800c28:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c2b:	0f b6 02             	movzbl (%edx),%eax
  800c2e:	3c 09                	cmp    $0x9,%al
  800c30:	74 04                	je     800c36 <strtol+0x1a>
  800c32:	3c 20                	cmp    $0x20,%al
  800c34:	75 0e                	jne    800c44 <strtol+0x28>
		s++;
  800c36:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c39:	0f b6 02             	movzbl (%edx),%eax
  800c3c:	3c 09                	cmp    $0x9,%al
  800c3e:	74 f6                	je     800c36 <strtol+0x1a>
  800c40:	3c 20                	cmp    $0x20,%al
  800c42:	74 f2                	je     800c36 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c44:	3c 2b                	cmp    $0x2b,%al
  800c46:	75 0a                	jne    800c52 <strtol+0x36>
		s++;
  800c48:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800c4b:	bf 00 00 00 00       	mov    $0x0,%edi
  800c50:	eb 10                	jmp    800c62 <strtol+0x46>
  800c52:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c57:	3c 2d                	cmp    $0x2d,%al
  800c59:	75 07                	jne    800c62 <strtol+0x46>
		s++, neg = 1;
  800c5b:	83 c2 01             	add    $0x1,%edx
  800c5e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c62:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800c68:	75 15                	jne    800c7f <strtol+0x63>
  800c6a:	80 3a 30             	cmpb   $0x30,(%edx)
  800c6d:	75 10                	jne    800c7f <strtol+0x63>
  800c6f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800c73:	75 0a                	jne    800c7f <strtol+0x63>
		s += 2, base = 16;
  800c75:	83 c2 02             	add    $0x2,%edx
  800c78:	bb 10 00 00 00       	mov    $0x10,%ebx
  800c7d:	eb 10                	jmp    800c8f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800c7f:	85 db                	test   %ebx,%ebx
  800c81:	75 0c                	jne    800c8f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800c83:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c85:	80 3a 30             	cmpb   $0x30,(%edx)
  800c88:	75 05                	jne    800c8f <strtol+0x73>
		s++, base = 8;
  800c8a:	83 c2 01             	add    $0x1,%edx
  800c8d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800c8f:	b8 00 00 00 00       	mov    $0x0,%eax
  800c94:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800c97:	0f b6 0a             	movzbl (%edx),%ecx
  800c9a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800c9d:	89 f3                	mov    %esi,%ebx
  800c9f:	80 fb 09             	cmp    $0x9,%bl
  800ca2:	77 08                	ja     800cac <strtol+0x90>
			dig = *s - '0';
  800ca4:	0f be c9             	movsbl %cl,%ecx
  800ca7:	83 e9 30             	sub    $0x30,%ecx
  800caa:	eb 22                	jmp    800cce <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800cac:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800caf:	89 f3                	mov    %esi,%ebx
  800cb1:	80 fb 19             	cmp    $0x19,%bl
  800cb4:	77 08                	ja     800cbe <strtol+0xa2>
			dig = *s - 'a' + 10;
  800cb6:	0f be c9             	movsbl %cl,%ecx
  800cb9:	83 e9 57             	sub    $0x57,%ecx
  800cbc:	eb 10                	jmp    800cce <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800cbe:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800cc1:	89 f3                	mov    %esi,%ebx
  800cc3:	80 fb 19             	cmp    $0x19,%bl
  800cc6:	77 16                	ja     800cde <strtol+0xc2>
			dig = *s - 'A' + 10;
  800cc8:	0f be c9             	movsbl %cl,%ecx
  800ccb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800cce:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800cd1:	7d 0f                	jge    800ce2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800cd3:	83 c2 01             	add    $0x1,%edx
  800cd6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800cda:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800cdc:	eb b9                	jmp    800c97 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800cde:	89 c1                	mov    %eax,%ecx
  800ce0:	eb 02                	jmp    800ce4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800ce2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800ce4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ce8:	74 05                	je     800cef <strtol+0xd3>
		*endptr = (char *) s;
  800cea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800ced:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800cef:	89 ca                	mov    %ecx,%edx
  800cf1:	f7 da                	neg    %edx
  800cf3:	85 ff                	test   %edi,%edi
  800cf5:	0f 45 c2             	cmovne %edx,%eax
}
  800cf8:	83 c4 04             	add    $0x4,%esp
  800cfb:	5b                   	pop    %ebx
  800cfc:	5e                   	pop    %esi
  800cfd:	5f                   	pop    %edi
  800cfe:	5d                   	pop    %ebp
  800cff:	c3                   	ret    

00800d00 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800d00:	55                   	push   %ebp
  800d01:	89 e5                	mov    %esp,%ebp
  800d03:	83 ec 0c             	sub    $0xc,%esp
  800d06:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d09:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d0c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d0f:	b8 00 00 00 00       	mov    $0x0,%eax
  800d14:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d17:	8b 55 08             	mov    0x8(%ebp),%edx
  800d1a:	89 c3                	mov    %eax,%ebx
  800d1c:	89 c7                	mov    %eax,%edi
  800d1e:	89 c6                	mov    %eax,%esi
  800d20:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800d22:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d25:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d28:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d2b:	89 ec                	mov    %ebp,%esp
  800d2d:	5d                   	pop    %ebp
  800d2e:	c3                   	ret    

00800d2f <sys_cgetc>:

int
sys_cgetc(void)
{
  800d2f:	55                   	push   %ebp
  800d30:	89 e5                	mov    %esp,%ebp
  800d32:	83 ec 0c             	sub    $0xc,%esp
  800d35:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d38:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d3b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d3e:	ba 00 00 00 00       	mov    $0x0,%edx
  800d43:	b8 01 00 00 00       	mov    $0x1,%eax
  800d48:	89 d1                	mov    %edx,%ecx
  800d4a:	89 d3                	mov    %edx,%ebx
  800d4c:	89 d7                	mov    %edx,%edi
  800d4e:	89 d6                	mov    %edx,%esi
  800d50:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800d52:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d55:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d58:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d5b:	89 ec                	mov    %ebp,%esp
  800d5d:	5d                   	pop    %ebp
  800d5e:	c3                   	ret    

00800d5f <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800d5f:	55                   	push   %ebp
  800d60:	89 e5                	mov    %esp,%ebp
  800d62:	83 ec 38             	sub    $0x38,%esp
  800d65:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d68:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d6b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d6e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d73:	b8 03 00 00 00       	mov    $0x3,%eax
  800d78:	8b 55 08             	mov    0x8(%ebp),%edx
  800d7b:	89 cb                	mov    %ecx,%ebx
  800d7d:	89 cf                	mov    %ecx,%edi
  800d7f:	89 ce                	mov    %ecx,%esi
  800d81:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d83:	85 c0                	test   %eax,%eax
  800d85:	7e 28                	jle    800daf <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d87:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d8b:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800d92:	00 
  800d93:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800d9a:	00 
  800d9b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800da2:	00 
  800da3:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800daa:	e8 a5 03 00 00       	call   801154 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800daf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800db2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800db5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800db8:	89 ec                	mov    %ebp,%esp
  800dba:	5d                   	pop    %ebp
  800dbb:	c3                   	ret    

00800dbc <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800dbc:	55                   	push   %ebp
  800dbd:	89 e5                	mov    %esp,%ebp
  800dbf:	83 ec 0c             	sub    $0xc,%esp
  800dc2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800dc5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800dc8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dcb:	ba 00 00 00 00       	mov    $0x0,%edx
  800dd0:	b8 02 00 00 00       	mov    $0x2,%eax
  800dd5:	89 d1                	mov    %edx,%ecx
  800dd7:	89 d3                	mov    %edx,%ebx
  800dd9:	89 d7                	mov    %edx,%edi
  800ddb:	89 d6                	mov    %edx,%esi
  800ddd:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800ddf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800de2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800de5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800de8:	89 ec                	mov    %ebp,%esp
  800dea:	5d                   	pop    %ebp
  800deb:	c3                   	ret    

00800dec <sys_yield>:

void
sys_yield(void)
{
  800dec:	55                   	push   %ebp
  800ded:	89 e5                	mov    %esp,%ebp
  800def:	83 ec 0c             	sub    $0xc,%esp
  800df2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800df5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800df8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dfb:	ba 00 00 00 00       	mov    $0x0,%edx
  800e00:	b8 0a 00 00 00       	mov    $0xa,%eax
  800e05:	89 d1                	mov    %edx,%ecx
  800e07:	89 d3                	mov    %edx,%ebx
  800e09:	89 d7                	mov    %edx,%edi
  800e0b:	89 d6                	mov    %edx,%esi
  800e0d:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800e0f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e12:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e15:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e18:	89 ec                	mov    %ebp,%esp
  800e1a:	5d                   	pop    %ebp
  800e1b:	c3                   	ret    

00800e1c <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800e1c:	55                   	push   %ebp
  800e1d:	89 e5                	mov    %esp,%ebp
  800e1f:	83 ec 38             	sub    $0x38,%esp
  800e22:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e25:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e28:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e2b:	be 00 00 00 00       	mov    $0x0,%esi
  800e30:	b8 04 00 00 00       	mov    $0x4,%eax
  800e35:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e38:	8b 55 08             	mov    0x8(%ebp),%edx
  800e3b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e3e:	89 f7                	mov    %esi,%edi
  800e40:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e42:	85 c0                	test   %eax,%eax
  800e44:	7e 28                	jle    800e6e <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e46:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e4a:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800e51:	00 
  800e52:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800e59:	00 
  800e5a:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e61:	00 
  800e62:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800e69:	e8 e6 02 00 00       	call   801154 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800e6e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e71:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e74:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e77:	89 ec                	mov    %ebp,%esp
  800e79:	5d                   	pop    %ebp
  800e7a:	c3                   	ret    

00800e7b <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800e7b:	55                   	push   %ebp
  800e7c:	89 e5                	mov    %esp,%ebp
  800e7e:	83 ec 38             	sub    $0x38,%esp
  800e81:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e84:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e87:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e8a:	b8 05 00 00 00       	mov    $0x5,%eax
  800e8f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e92:	8b 55 08             	mov    0x8(%ebp),%edx
  800e95:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e98:	8b 7d 14             	mov    0x14(%ebp),%edi
  800e9b:	8b 75 18             	mov    0x18(%ebp),%esi
  800e9e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ea0:	85 c0                	test   %eax,%eax
  800ea2:	7e 28                	jle    800ecc <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ea4:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ea8:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800eaf:	00 
  800eb0:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800eb7:	00 
  800eb8:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ebf:	00 
  800ec0:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800ec7:	e8 88 02 00 00       	call   801154 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800ecc:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800ecf:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ed2:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ed5:	89 ec                	mov    %ebp,%esp
  800ed7:	5d                   	pop    %ebp
  800ed8:	c3                   	ret    

00800ed9 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800ed9:	55                   	push   %ebp
  800eda:	89 e5                	mov    %esp,%ebp
  800edc:	83 ec 38             	sub    $0x38,%esp
  800edf:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ee2:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ee5:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ee8:	bb 00 00 00 00       	mov    $0x0,%ebx
  800eed:	b8 06 00 00 00       	mov    $0x6,%eax
  800ef2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ef5:	8b 55 08             	mov    0x8(%ebp),%edx
  800ef8:	89 df                	mov    %ebx,%edi
  800efa:	89 de                	mov    %ebx,%esi
  800efc:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800efe:	85 c0                	test   %eax,%eax
  800f00:	7e 28                	jle    800f2a <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f02:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f06:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800f0d:	00 
  800f0e:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800f15:	00 
  800f16:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f1d:	00 
  800f1e:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800f25:	e8 2a 02 00 00       	call   801154 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800f2a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f2d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f30:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f33:	89 ec                	mov    %ebp,%esp
  800f35:	5d                   	pop    %ebp
  800f36:	c3                   	ret    

00800f37 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800f37:	55                   	push   %ebp
  800f38:	89 e5                	mov    %esp,%ebp
  800f3a:	83 ec 38             	sub    $0x38,%esp
  800f3d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f40:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f43:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f46:	bb 00 00 00 00       	mov    $0x0,%ebx
  800f4b:	b8 08 00 00 00       	mov    $0x8,%eax
  800f50:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f53:	8b 55 08             	mov    0x8(%ebp),%edx
  800f56:	89 df                	mov    %ebx,%edi
  800f58:	89 de                	mov    %ebx,%esi
  800f5a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f5c:	85 c0                	test   %eax,%eax
  800f5e:	7e 28                	jle    800f88 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f60:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f64:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800f6b:	00 
  800f6c:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800f73:	00 
  800f74:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f7b:	00 
  800f7c:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800f83:	e8 cc 01 00 00       	call   801154 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800f88:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f8b:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f8e:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f91:	89 ec                	mov    %ebp,%esp
  800f93:	5d                   	pop    %ebp
  800f94:	c3                   	ret    

00800f95 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800f95:	55                   	push   %ebp
  800f96:	89 e5                	mov    %esp,%ebp
  800f98:	83 ec 38             	sub    $0x38,%esp
  800f9b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f9e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800fa1:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800fa4:	bb 00 00 00 00       	mov    $0x0,%ebx
  800fa9:	b8 09 00 00 00       	mov    $0x9,%eax
  800fae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800fb1:	8b 55 08             	mov    0x8(%ebp),%edx
  800fb4:	89 df                	mov    %ebx,%edi
  800fb6:	89 de                	mov    %ebx,%esi
  800fb8:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800fba:	85 c0                	test   %eax,%eax
  800fbc:	7e 28                	jle    800fe6 <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800fbe:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fc2:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800fc9:	00 
  800fca:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800fd1:	00 
  800fd2:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800fd9:	00 
  800fda:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800fe1:	e8 6e 01 00 00       	call   801154 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800fe6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800fe9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800fec:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800fef:	89 ec                	mov    %ebp,%esp
  800ff1:	5d                   	pop    %ebp
  800ff2:	c3                   	ret    

00800ff3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800ff3:	55                   	push   %ebp
  800ff4:	89 e5                	mov    %esp,%ebp
  800ff6:	83 ec 0c             	sub    $0xc,%esp
  800ff9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ffc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800fff:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801002:	be 00 00 00 00       	mov    $0x0,%esi
  801007:	b8 0b 00 00 00       	mov    $0xb,%eax
  80100c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80100f:	8b 55 08             	mov    0x8(%ebp),%edx
  801012:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801015:	8b 7d 14             	mov    0x14(%ebp),%edi
  801018:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  80101a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80101d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  801020:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801023:	89 ec                	mov    %ebp,%esp
  801025:	5d                   	pop    %ebp
  801026:	c3                   	ret    

00801027 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  801027:	55                   	push   %ebp
  801028:	89 e5                	mov    %esp,%ebp
  80102a:	83 ec 38             	sub    $0x38,%esp
  80102d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  801030:	89 75 f8             	mov    %esi,-0x8(%ebp)
  801033:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801036:	b9 00 00 00 00       	mov    $0x0,%ecx
  80103b:	b8 0c 00 00 00       	mov    $0xc,%eax
  801040:	8b 55 08             	mov    0x8(%ebp),%edx
  801043:	89 cb                	mov    %ecx,%ebx
  801045:	89 cf                	mov    %ecx,%edi
  801047:	89 ce                	mov    %ecx,%esi
  801049:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80104b:	85 c0                	test   %eax,%eax
  80104d:	7e 28                	jle    801077 <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  80104f:	89 44 24 10          	mov    %eax,0x10(%esp)
  801053:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  80105a:	00 
  80105b:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  801062:	00 
  801063:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80106a:	00 
  80106b:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  801072:	e8 dd 00 00 00       	call   801154 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  801077:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80107a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80107d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801080:	89 ec                	mov    %ebp,%esp
  801082:	5d                   	pop    %ebp
  801083:	c3                   	ret    

00801084 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  801084:	55                   	push   %ebp
  801085:	89 e5                	mov    %esp,%ebp
  801087:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("fork not implemented");
  80108a:	c7 44 24 08 9b 17 80 	movl   $0x80179b,0x8(%esp)
  801091:	00 
  801092:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
  801099:	00 
  80109a:	c7 04 24 8f 17 80 00 	movl   $0x80178f,(%esp)
  8010a1:	e8 ae 00 00 00       	call   801154 <_panic>

008010a6 <sfork>:
}

// Challenge!
int
sfork(void)
{
  8010a6:	55                   	push   %ebp
  8010a7:	89 e5                	mov    %esp,%ebp
  8010a9:	83 ec 18             	sub    $0x18,%esp
	panic("sfork not implemented");
  8010ac:	c7 44 24 08 9a 17 80 	movl   $0x80179a,0x8(%esp)
  8010b3:	00 
  8010b4:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  8010bb:	00 
  8010bc:	c7 04 24 8f 17 80 00 	movl   $0x80178f,(%esp)
  8010c3:	e8 8c 00 00 00       	call   801154 <_panic>

008010c8 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  8010c8:	55                   	push   %ebp
  8010c9:	89 e5                	mov    %esp,%ebp
  8010cb:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("ipc_recv not implemented");
  8010ce:	c7 44 24 08 b0 17 80 	movl   $0x8017b0,0x8(%esp)
  8010d5:	00 
  8010d6:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
  8010dd:	00 
  8010de:	c7 04 24 c9 17 80 00 	movl   $0x8017c9,(%esp)
  8010e5:	e8 6a 00 00 00       	call   801154 <_panic>

008010ea <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  8010ea:	55                   	push   %ebp
  8010eb:	89 e5                	mov    %esp,%ebp
  8010ed:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("ipc_send not implemented");
  8010f0:	c7 44 24 08 d3 17 80 	movl   $0x8017d3,0x8(%esp)
  8010f7:	00 
  8010f8:	c7 44 24 04 2a 00 00 	movl   $0x2a,0x4(%esp)
  8010ff:	00 
  801100:	c7 04 24 c9 17 80 00 	movl   $0x8017c9,(%esp)
  801107:	e8 48 00 00 00       	call   801154 <_panic>

0080110c <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  80110c:	55                   	push   %ebp
  80110d:	89 e5                	mov    %esp,%ebp
  80110f:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
		if (envs[i].env_type == type)
  801112:	a1 50 00 c0 ee       	mov    0xeec00050,%eax
  801117:	39 c8                	cmp    %ecx,%eax
  801119:	74 17                	je     801132 <ipc_find_env+0x26>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  80111b:	b8 01 00 00 00       	mov    $0x1,%eax
		if (envs[i].env_type == type)
  801120:	6b d0 7c             	imul   $0x7c,%eax,%edx
  801123:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  801129:	8b 52 50             	mov    0x50(%edx),%edx
  80112c:	39 ca                	cmp    %ecx,%edx
  80112e:	75 14                	jne    801144 <ipc_find_env+0x38>
  801130:	eb 05                	jmp    801137 <ipc_find_env+0x2b>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  801132:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
			return envs[i].env_id;
  801137:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80113a:	05 08 00 c0 ee       	add    $0xeec00008,%eax
  80113f:	8b 40 40             	mov    0x40(%eax),%eax
  801142:	eb 0e                	jmp    801152 <ipc_find_env+0x46>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  801144:	83 c0 01             	add    $0x1,%eax
  801147:	3d 00 04 00 00       	cmp    $0x400,%eax
  80114c:	75 d2                	jne    801120 <ipc_find_env+0x14>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  80114e:	66 b8 00 00          	mov    $0x0,%ax
}
  801152:	5d                   	pop    %ebp
  801153:	c3                   	ret    

00801154 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  801154:	55                   	push   %ebp
  801155:	89 e5                	mov    %esp,%ebp
  801157:	56                   	push   %esi
  801158:	53                   	push   %ebx
  801159:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  80115c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  80115f:	a1 0c 20 80 00       	mov    0x80200c,%eax
  801164:	85 c0                	test   %eax,%eax
  801166:	74 10                	je     801178 <_panic+0x24>
		cprintf("%s: ", argv0);
  801168:	89 44 24 04          	mov    %eax,0x4(%esp)
  80116c:	c7 04 24 ec 17 80 00 	movl   $0x8017ec,(%esp)
  801173:	e8 ff f0 ff ff       	call   800277 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801178:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80117e:	e8 39 fc ff ff       	call   800dbc <sys_getenvid>
  801183:	8b 55 0c             	mov    0xc(%ebp),%edx
  801186:	89 54 24 10          	mov    %edx,0x10(%esp)
  80118a:	8b 55 08             	mov    0x8(%ebp),%edx
  80118d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801191:	89 74 24 08          	mov    %esi,0x8(%esp)
  801195:	89 44 24 04          	mov    %eax,0x4(%esp)
  801199:	c7 04 24 f4 17 80 00 	movl   $0x8017f4,(%esp)
  8011a0:	e8 d2 f0 ff ff       	call   800277 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8011a5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8011a9:	8b 45 10             	mov    0x10(%ebp),%eax
  8011ac:	89 04 24             	mov    %eax,(%esp)
  8011af:	e8 62 f0 ff ff       	call   800216 <vcprintf>
	cprintf("\n");
  8011b4:	c7 04 24 d8 14 80 00 	movl   $0x8014d8,(%esp)
  8011bb:	e8 b7 f0 ff ff       	call   800277 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8011c0:	cc                   	int3   
  8011c1:	eb fd                	jmp    8011c0 <_panic+0x6c>
  8011c3:	66 90                	xchg   %ax,%ax
  8011c5:	66 90                	xchg   %ax,%ax
  8011c7:	66 90                	xchg   %ax,%ax
  8011c9:	66 90                	xchg   %ax,%ax
  8011cb:	66 90                	xchg   %ax,%ax
  8011cd:	66 90                	xchg   %ax,%ax
  8011cf:	90                   	nop

008011d0 <__udivdi3>:
  8011d0:	83 ec 1c             	sub    $0x1c,%esp
  8011d3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  8011d7:	89 7c 24 14          	mov    %edi,0x14(%esp)
  8011db:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  8011df:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  8011e3:	8b 7c 24 20          	mov    0x20(%esp),%edi
  8011e7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  8011eb:	85 c0                	test   %eax,%eax
  8011ed:	89 74 24 10          	mov    %esi,0x10(%esp)
  8011f1:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8011f5:	89 ea                	mov    %ebp,%edx
  8011f7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8011fb:	75 33                	jne    801230 <__udivdi3+0x60>
  8011fd:	39 e9                	cmp    %ebp,%ecx
  8011ff:	77 6f                	ja     801270 <__udivdi3+0xa0>
  801201:	85 c9                	test   %ecx,%ecx
  801203:	89 ce                	mov    %ecx,%esi
  801205:	75 0b                	jne    801212 <__udivdi3+0x42>
  801207:	b8 01 00 00 00       	mov    $0x1,%eax
  80120c:	31 d2                	xor    %edx,%edx
  80120e:	f7 f1                	div    %ecx
  801210:	89 c6                	mov    %eax,%esi
  801212:	31 d2                	xor    %edx,%edx
  801214:	89 e8                	mov    %ebp,%eax
  801216:	f7 f6                	div    %esi
  801218:	89 c5                	mov    %eax,%ebp
  80121a:	89 f8                	mov    %edi,%eax
  80121c:	f7 f6                	div    %esi
  80121e:	89 ea                	mov    %ebp,%edx
  801220:	8b 74 24 10          	mov    0x10(%esp),%esi
  801224:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801228:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  80122c:	83 c4 1c             	add    $0x1c,%esp
  80122f:	c3                   	ret    
  801230:	39 e8                	cmp    %ebp,%eax
  801232:	77 24                	ja     801258 <__udivdi3+0x88>
  801234:	0f bd c8             	bsr    %eax,%ecx
  801237:	83 f1 1f             	xor    $0x1f,%ecx
  80123a:	89 0c 24             	mov    %ecx,(%esp)
  80123d:	75 49                	jne    801288 <__udivdi3+0xb8>
  80123f:	8b 74 24 08          	mov    0x8(%esp),%esi
  801243:	39 74 24 04          	cmp    %esi,0x4(%esp)
  801247:	0f 86 ab 00 00 00    	jbe    8012f8 <__udivdi3+0x128>
  80124d:	39 e8                	cmp    %ebp,%eax
  80124f:	0f 82 a3 00 00 00    	jb     8012f8 <__udivdi3+0x128>
  801255:	8d 76 00             	lea    0x0(%esi),%esi
  801258:	31 d2                	xor    %edx,%edx
  80125a:	31 c0                	xor    %eax,%eax
  80125c:	8b 74 24 10          	mov    0x10(%esp),%esi
  801260:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801264:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801268:	83 c4 1c             	add    $0x1c,%esp
  80126b:	c3                   	ret    
  80126c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801270:	89 f8                	mov    %edi,%eax
  801272:	f7 f1                	div    %ecx
  801274:	31 d2                	xor    %edx,%edx
  801276:	8b 74 24 10          	mov    0x10(%esp),%esi
  80127a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  80127e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801282:	83 c4 1c             	add    $0x1c,%esp
  801285:	c3                   	ret    
  801286:	66 90                	xchg   %ax,%ax
  801288:	0f b6 0c 24          	movzbl (%esp),%ecx
  80128c:	89 c6                	mov    %eax,%esi
  80128e:	b8 20 00 00 00       	mov    $0x20,%eax
  801293:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  801297:	2b 04 24             	sub    (%esp),%eax
  80129a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  80129e:	d3 e6                	shl    %cl,%esi
  8012a0:	89 c1                	mov    %eax,%ecx
  8012a2:	d3 ed                	shr    %cl,%ebp
  8012a4:	0f b6 0c 24          	movzbl (%esp),%ecx
  8012a8:	09 f5                	or     %esi,%ebp
  8012aa:	8b 74 24 04          	mov    0x4(%esp),%esi
  8012ae:	d3 e6                	shl    %cl,%esi
  8012b0:	89 c1                	mov    %eax,%ecx
  8012b2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8012b6:	89 d6                	mov    %edx,%esi
  8012b8:	d3 ee                	shr    %cl,%esi
  8012ba:	0f b6 0c 24          	movzbl (%esp),%ecx
  8012be:	d3 e2                	shl    %cl,%edx
  8012c0:	89 c1                	mov    %eax,%ecx
  8012c2:	d3 ef                	shr    %cl,%edi
  8012c4:	09 d7                	or     %edx,%edi
  8012c6:	89 f2                	mov    %esi,%edx
  8012c8:	89 f8                	mov    %edi,%eax
  8012ca:	f7 f5                	div    %ebp
  8012cc:	89 d6                	mov    %edx,%esi
  8012ce:	89 c7                	mov    %eax,%edi
  8012d0:	f7 64 24 04          	mull   0x4(%esp)
  8012d4:	39 d6                	cmp    %edx,%esi
  8012d6:	72 30                	jb     801308 <__udivdi3+0x138>
  8012d8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  8012dc:	0f b6 0c 24          	movzbl (%esp),%ecx
  8012e0:	d3 e5                	shl    %cl,%ebp
  8012e2:	39 c5                	cmp    %eax,%ebp
  8012e4:	73 04                	jae    8012ea <__udivdi3+0x11a>
  8012e6:	39 d6                	cmp    %edx,%esi
  8012e8:	74 1e                	je     801308 <__udivdi3+0x138>
  8012ea:	89 f8                	mov    %edi,%eax
  8012ec:	31 d2                	xor    %edx,%edx
  8012ee:	e9 69 ff ff ff       	jmp    80125c <__udivdi3+0x8c>
  8012f3:	90                   	nop
  8012f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8012f8:	31 d2                	xor    %edx,%edx
  8012fa:	b8 01 00 00 00       	mov    $0x1,%eax
  8012ff:	e9 58 ff ff ff       	jmp    80125c <__udivdi3+0x8c>
  801304:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801308:	8d 47 ff             	lea    -0x1(%edi),%eax
  80130b:	31 d2                	xor    %edx,%edx
  80130d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801311:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801315:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801319:	83 c4 1c             	add    $0x1c,%esp
  80131c:	c3                   	ret    
  80131d:	66 90                	xchg   %ax,%ax
  80131f:	90                   	nop

00801320 <__umoddi3>:
  801320:	83 ec 2c             	sub    $0x2c,%esp
  801323:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  801327:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80132b:	89 74 24 20          	mov    %esi,0x20(%esp)
  80132f:	8b 74 24 38          	mov    0x38(%esp),%esi
  801333:	89 7c 24 24          	mov    %edi,0x24(%esp)
  801337:	8b 7c 24 34          	mov    0x34(%esp),%edi
  80133b:	85 c0                	test   %eax,%eax
  80133d:	89 c2                	mov    %eax,%edx
  80133f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  801343:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  801347:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80134b:	89 74 24 10          	mov    %esi,0x10(%esp)
  80134f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  801353:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801357:	75 1f                	jne    801378 <__umoddi3+0x58>
  801359:	39 fe                	cmp    %edi,%esi
  80135b:	76 63                	jbe    8013c0 <__umoddi3+0xa0>
  80135d:	89 c8                	mov    %ecx,%eax
  80135f:	89 fa                	mov    %edi,%edx
  801361:	f7 f6                	div    %esi
  801363:	89 d0                	mov    %edx,%eax
  801365:	31 d2                	xor    %edx,%edx
  801367:	8b 74 24 20          	mov    0x20(%esp),%esi
  80136b:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80136f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801373:	83 c4 2c             	add    $0x2c,%esp
  801376:	c3                   	ret    
  801377:	90                   	nop
  801378:	39 f8                	cmp    %edi,%eax
  80137a:	77 64                	ja     8013e0 <__umoddi3+0xc0>
  80137c:	0f bd e8             	bsr    %eax,%ebp
  80137f:	83 f5 1f             	xor    $0x1f,%ebp
  801382:	75 74                	jne    8013f8 <__umoddi3+0xd8>
  801384:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801388:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  80138c:	0f 87 0e 01 00 00    	ja     8014a0 <__umoddi3+0x180>
  801392:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  801396:	29 f1                	sub    %esi,%ecx
  801398:	19 c7                	sbb    %eax,%edi
  80139a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  80139e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8013a2:	8b 44 24 14          	mov    0x14(%esp),%eax
  8013a6:	8b 54 24 18          	mov    0x18(%esp),%edx
  8013aa:	8b 74 24 20          	mov    0x20(%esp),%esi
  8013ae:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8013b2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8013b6:	83 c4 2c             	add    $0x2c,%esp
  8013b9:	c3                   	ret    
  8013ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8013c0:	85 f6                	test   %esi,%esi
  8013c2:	89 f5                	mov    %esi,%ebp
  8013c4:	75 0b                	jne    8013d1 <__umoddi3+0xb1>
  8013c6:	b8 01 00 00 00       	mov    $0x1,%eax
  8013cb:	31 d2                	xor    %edx,%edx
  8013cd:	f7 f6                	div    %esi
  8013cf:	89 c5                	mov    %eax,%ebp
  8013d1:	8b 44 24 0c          	mov    0xc(%esp),%eax
  8013d5:	31 d2                	xor    %edx,%edx
  8013d7:	f7 f5                	div    %ebp
  8013d9:	89 c8                	mov    %ecx,%eax
  8013db:	f7 f5                	div    %ebp
  8013dd:	eb 84                	jmp    801363 <__umoddi3+0x43>
  8013df:	90                   	nop
  8013e0:	89 c8                	mov    %ecx,%eax
  8013e2:	89 fa                	mov    %edi,%edx
  8013e4:	8b 74 24 20          	mov    0x20(%esp),%esi
  8013e8:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8013ec:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8013f0:	83 c4 2c             	add    $0x2c,%esp
  8013f3:	c3                   	ret    
  8013f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8013f8:	8b 44 24 10          	mov    0x10(%esp),%eax
  8013fc:	be 20 00 00 00       	mov    $0x20,%esi
  801401:	89 e9                	mov    %ebp,%ecx
  801403:	29 ee                	sub    %ebp,%esi
  801405:	d3 e2                	shl    %cl,%edx
  801407:	89 f1                	mov    %esi,%ecx
  801409:	d3 e8                	shr    %cl,%eax
  80140b:	89 e9                	mov    %ebp,%ecx
  80140d:	09 d0                	or     %edx,%eax
  80140f:	89 fa                	mov    %edi,%edx
  801411:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801415:	8b 44 24 10          	mov    0x10(%esp),%eax
  801419:	d3 e0                	shl    %cl,%eax
  80141b:	89 f1                	mov    %esi,%ecx
  80141d:	89 44 24 10          	mov    %eax,0x10(%esp)
  801421:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  801425:	d3 ea                	shr    %cl,%edx
  801427:	89 e9                	mov    %ebp,%ecx
  801429:	d3 e7                	shl    %cl,%edi
  80142b:	89 f1                	mov    %esi,%ecx
  80142d:	d3 e8                	shr    %cl,%eax
  80142f:	89 e9                	mov    %ebp,%ecx
  801431:	09 f8                	or     %edi,%eax
  801433:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  801437:	f7 74 24 0c          	divl   0xc(%esp)
  80143b:	d3 e7                	shl    %cl,%edi
  80143d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801441:	89 d7                	mov    %edx,%edi
  801443:	f7 64 24 10          	mull   0x10(%esp)
  801447:	39 d7                	cmp    %edx,%edi
  801449:	89 c1                	mov    %eax,%ecx
  80144b:	89 54 24 14          	mov    %edx,0x14(%esp)
  80144f:	72 3b                	jb     80148c <__umoddi3+0x16c>
  801451:	39 44 24 18          	cmp    %eax,0x18(%esp)
  801455:	72 31                	jb     801488 <__umoddi3+0x168>
  801457:	8b 44 24 18          	mov    0x18(%esp),%eax
  80145b:	29 c8                	sub    %ecx,%eax
  80145d:	19 d7                	sbb    %edx,%edi
  80145f:	89 e9                	mov    %ebp,%ecx
  801461:	89 fa                	mov    %edi,%edx
  801463:	d3 e8                	shr    %cl,%eax
  801465:	89 f1                	mov    %esi,%ecx
  801467:	d3 e2                	shl    %cl,%edx
  801469:	89 e9                	mov    %ebp,%ecx
  80146b:	09 d0                	or     %edx,%eax
  80146d:	89 fa                	mov    %edi,%edx
  80146f:	d3 ea                	shr    %cl,%edx
  801471:	8b 74 24 20          	mov    0x20(%esp),%esi
  801475:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801479:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  80147d:	83 c4 2c             	add    $0x2c,%esp
  801480:	c3                   	ret    
  801481:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801488:	39 d7                	cmp    %edx,%edi
  80148a:	75 cb                	jne    801457 <__umoddi3+0x137>
  80148c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801490:	89 c1                	mov    %eax,%ecx
  801492:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801496:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80149a:	eb bb                	jmp    801457 <__umoddi3+0x137>
  80149c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8014a0:	3b 44 24 18          	cmp    0x18(%esp),%eax
  8014a4:	0f 82 e8 fe ff ff    	jb     801392 <__umoddi3+0x72>
  8014aa:	e9 f3 fe ff ff       	jmp    8013a2 <__umoddi3+0x82>

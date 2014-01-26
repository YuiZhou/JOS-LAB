
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
  80003d:	e8 2a 13 00 00       	call   80136c <sfork>
  800042:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800045:	85 c0                	test   %eax,%eax
  800047:	74 5e                	je     8000a7 <umain+0x73>
		cprintf("i am %08x; thisenv is %p\n", sys_getenvid(), thisenv);
  800049:	8b 1d 08 20 80 00    	mov    0x802008,%ebx
  80004f:	e8 68 0d 00 00       	call   800dbc <sys_getenvid>
  800054:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800058:	89 44 24 04          	mov    %eax,0x4(%esp)
  80005c:	c7 04 24 20 1b 80 00 	movl   $0x801b20,(%esp)
  800063:	e8 0f 02 00 00       	call   800277 <cprintf>
		// get the ball rolling
		cprintf("send 0 from %x to %x\n", sys_getenvid(), who);
  800068:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  80006b:	e8 4c 0d 00 00       	call   800dbc <sys_getenvid>
  800070:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800074:	89 44 24 04          	mov    %eax,0x4(%esp)
  800078:	c7 04 24 3a 1b 80 00 	movl   $0x801b3a,(%esp)
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
  8000a2:	e8 c5 15 00 00       	call   80166c <ipc_send>
	}

	while (1) {
		ipc_recv(&who, 0, 0);
  8000a7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8000ae:	00 
  8000af:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8000b6:	00 
  8000b7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  8000ba:	89 04 24             	mov    %eax,(%esp)
  8000bd:	e8 52 15 00 00       	call   801614 <ipc_recv>
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
  8000f3:	c7 04 24 50 1b 80 00 	movl   $0x801b50,(%esp)
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
  80012f:	e8 38 15 00 00       	call   80166c <ipc_send>
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
  800315:	e8 16 15 00 00       	call   801830 <__udivdi3>
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
  800373:	e8 08 16 00 00       	call   801980 <__umoddi3>
  800378:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80037c:	0f be 80 80 1b 80 00 	movsbl 0x801b80(%eax),%eax
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
  8004a7:	ff 24 85 40 1c 80 00 	jmp    *0x801c40(,%eax,4)
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
  800569:	8b 14 85 a0 1d 80 00 	mov    0x801da0(,%eax,4),%edx
  800570:	85 d2                	test   %edx,%edx
  800572:	75 20                	jne    800594 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800574:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800578:	c7 44 24 08 98 1b 80 	movl   $0x801b98,0x8(%esp)
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
  800598:	c7 44 24 08 a1 1b 80 	movl   $0x801ba1,0x8(%esp)
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
  8005ca:	b8 91 1b 80 00       	mov    $0x801b91,%eax
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
  800d93:	c7 44 24 08 c4 1d 80 	movl   $0x801dc4,0x8(%esp)
  800d9a:	00 
  800d9b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800da2:	00 
  800da3:	c7 04 24 e1 1d 80 00 	movl   $0x801de1,(%esp)
  800daa:	e8 71 09 00 00       	call   801720 <_panic>

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
  800e52:	c7 44 24 08 c4 1d 80 	movl   $0x801dc4,0x8(%esp)
  800e59:	00 
  800e5a:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e61:	00 
  800e62:	c7 04 24 e1 1d 80 00 	movl   $0x801de1,(%esp)
  800e69:	e8 b2 08 00 00       	call   801720 <_panic>

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
  800eb0:	c7 44 24 08 c4 1d 80 	movl   $0x801dc4,0x8(%esp)
  800eb7:	00 
  800eb8:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ebf:	00 
  800ec0:	c7 04 24 e1 1d 80 00 	movl   $0x801de1,(%esp)
  800ec7:	e8 54 08 00 00       	call   801720 <_panic>

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
  800f0e:	c7 44 24 08 c4 1d 80 	movl   $0x801dc4,0x8(%esp)
  800f15:	00 
  800f16:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f1d:	00 
  800f1e:	c7 04 24 e1 1d 80 00 	movl   $0x801de1,(%esp)
  800f25:	e8 f6 07 00 00       	call   801720 <_panic>

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
  800f6c:	c7 44 24 08 c4 1d 80 	movl   $0x801dc4,0x8(%esp)
  800f73:	00 
  800f74:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f7b:	00 
  800f7c:	c7 04 24 e1 1d 80 00 	movl   $0x801de1,(%esp)
  800f83:	e8 98 07 00 00       	call   801720 <_panic>

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
  800fca:	c7 44 24 08 c4 1d 80 	movl   $0x801dc4,0x8(%esp)
  800fd1:	00 
  800fd2:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800fd9:	00 
  800fda:	c7 04 24 e1 1d 80 00 	movl   $0x801de1,(%esp)
  800fe1:	e8 3a 07 00 00       	call   801720 <_panic>

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
  80105b:	c7 44 24 08 c4 1d 80 	movl   $0x801dc4,0x8(%esp)
  801062:	00 
  801063:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80106a:	00 
  80106b:	c7 04 24 e1 1d 80 00 	movl   $0x801de1,(%esp)
  801072:	e8 a9 06 00 00       	call   801720 <_panic>

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

00801084 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  801084:	55                   	push   %ebp
  801085:	89 e5                	mov    %esp,%ebp
  801087:	53                   	push   %ebx
  801088:	83 ec 24             	sub    $0x24,%esp
  80108b:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void *) utf->utf_fault_va;
  80108e:	8b 18                	mov    (%eax),%ebx
	// Hint:
	//   Use the read-only page table mappings at vpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if(!((err & FEC_WR) && (vpd[PDX(addr)]&PTE_P) && (vpt[PGNUM(addr)]&PTE_COW) ))
  801090:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  801094:	74 21                	je     8010b7 <pgfault+0x33>
  801096:	89 d8                	mov    %ebx,%eax
  801098:	c1 e8 16             	shr    $0x16,%eax
  80109b:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  8010a2:	a8 01                	test   $0x1,%al
  8010a4:	74 11                	je     8010b7 <pgfault+0x33>
  8010a6:	89 d8                	mov    %ebx,%eax
  8010a8:	c1 e8 0c             	shr    $0xc,%eax
  8010ab:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  8010b2:	f6 c4 08             	test   $0x8,%ah
  8010b5:	75 1c                	jne    8010d3 <pgfault+0x4f>
		panic("Invalid fault address!\n");
  8010b7:	c7 44 24 08 ef 1d 80 	movl   $0x801def,0x8(%esp)
  8010be:	00 
  8010bf:	c7 44 24 04 1e 00 00 	movl   $0x1e,0x4(%esp)
  8010c6:	00 
  8010c7:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  8010ce:	e8 4d 06 00 00       	call   801720 <_panic>
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
	if((r = sys_page_alloc(0, (void *)PFTEMP, PTE_W|PTE_P|PTE_U)))
  8010d3:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8010da:	00 
  8010db:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  8010e2:	00 
  8010e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8010ea:	e8 2d fd ff ff       	call   800e1c <sys_page_alloc>
  8010ef:	85 c0                	test   %eax,%eax
  8010f1:	74 20                	je     801113 <pgfault+0x8f>
		panic("Alloc page error: %e", r);
  8010f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8010f7:	c7 44 24 08 12 1e 80 	movl   $0x801e12,0x8(%esp)
  8010fe:	00 
  8010ff:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
  801106:	00 
  801107:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  80110e:	e8 0d 06 00 00       	call   801720 <_panic>
	addr = ROUNDDOWN(addr, PGSIZE);
  801113:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	memmove((void *)PFTEMP, addr, PGSIZE);
  801119:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  801120:	00 
  801121:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  801125:	c7 04 24 00 f0 7f 00 	movl   $0x7ff000,(%esp)
  80112c:	e8 d2 f9 ff ff       	call   800b03 <memmove>
	sys_page_map(0, (void *)PFTEMP, 0, addr, PTE_W|PTE_P|PTE_U);
  801131:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  801138:	00 
  801139:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  80113d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801144:	00 
  801145:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  80114c:	00 
  80114d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801154:	e8 22 fd ff ff       	call   800e7b <sys_page_map>

	//panic("pgfault not implemented");
}
  801159:	83 c4 24             	add    $0x24,%esp
  80115c:	5b                   	pop    %ebx
  80115d:	5d                   	pop    %ebp
  80115e:	c3                   	ret    

0080115f <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  80115f:	55                   	push   %ebp
  801160:	89 e5                	mov    %esp,%ebp
  801162:	57                   	push   %edi
  801163:	56                   	push   %esi
  801164:	53                   	push   %ebx
  801165:	83 ec 3c             	sub    $0x3c,%esp
	// LAB 4: Your code here.
	envid_t ch_id;
	uint32_t cow_pg_ptr;
	int r;

	set_pgfault_handler(pgfault);
  801168:	c7 04 24 84 10 80 00 	movl   $0x801084,(%esp)
  80116f:	e8 1c 06 00 00       	call   801790 <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  801174:	ba 07 00 00 00       	mov    $0x7,%edx
  801179:	89 d0                	mov    %edx,%eax
  80117b:	cd 30                	int    $0x30
  80117d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	if((ch_id = sys_exofork()) < 0)
  801180:	85 c0                	test   %eax,%eax
  801182:	79 1c                	jns    8011a0 <fork+0x41>
		panic("Fork error\n");
  801184:	c7 44 24 08 27 1e 80 	movl   $0x801e27,0x8(%esp)
  80118b:	00 
  80118c:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  801193:	00 
  801194:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  80119b:	e8 80 05 00 00       	call   801720 <_panic>
  8011a0:	89 c7                	mov    %eax,%edi
	if(ch_id == 0){ /* the child process */
  8011a2:	bb 00 00 80 00       	mov    $0x800000,%ebx
  8011a7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8011ab:	75 1c                	jne    8011c9 <fork+0x6a>
		thisenv =  &envs[ENVX(sys_getenvid())];
  8011ad:	e8 0a fc ff ff       	call   800dbc <sys_getenvid>
  8011b2:	25 ff 03 00 00       	and    $0x3ff,%eax
  8011b7:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8011ba:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8011bf:	a3 08 20 80 00       	mov    %eax,0x802008
		return 0;
  8011c4:	e9 98 01 00 00       	jmp    801361 <fork+0x202>
	}
	for(cow_pg_ptr = UTEXT; cow_pg_ptr < UXSTACKTOP - PGSIZE; cow_pg_ptr += PGSIZE){
		if ((vpd[PDX(cow_pg_ptr)] & PTE_P) && (vpt[PGNUM(cow_pg_ptr)] & (PTE_P|PTE_U))) 
  8011c9:	89 d8                	mov    %ebx,%eax
  8011cb:	c1 e8 16             	shr    $0x16,%eax
  8011ce:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  8011d5:	a8 01                	test   $0x1,%al
  8011d7:	0f 84 0d 01 00 00    	je     8012ea <fork+0x18b>
  8011dd:	89 d8                	mov    %ebx,%eax
  8011df:	c1 e8 0c             	shr    $0xc,%eax
  8011e2:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  8011e9:	f6 c2 05             	test   $0x5,%dl
  8011ec:	0f 84 f8 00 00 00    	je     8012ea <fork+0x18b>
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	if((vpd[PDX(pn*PGSIZE)]&PTE_P) && (vpt[pn]&(PTE_COW|PTE_W))){
  8011f2:	89 c6                	mov    %eax,%esi
  8011f4:	c1 e6 0c             	shl    $0xc,%esi
  8011f7:	89 f2                	mov    %esi,%edx
  8011f9:	c1 ea 16             	shr    $0x16,%edx
  8011fc:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  801203:	f6 c2 01             	test   $0x1,%dl
  801206:	0f 84 9a 00 00 00    	je     8012a6 <fork+0x147>
  80120c:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  801213:	a9 02 08 00 00       	test   $0x802,%eax
  801218:	0f 84 88 00 00 00    	je     8012a6 <fork+0x147>
		if((r = sys_page_map(0, (void *)(pn*PGSIZE), envid, (void *)(pn*PGSIZE), PTE_P|PTE_COW|PTE_U)))
  80121e:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  801225:	00 
  801226:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80122a:	89 7c 24 08          	mov    %edi,0x8(%esp)
  80122e:	89 74 24 04          	mov    %esi,0x4(%esp)
  801232:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801239:	e8 3d fc ff ff       	call   800e7b <sys_page_map>
  80123e:	85 c0                	test   %eax,%eax
  801240:	74 20                	je     801262 <fork+0x103>
			panic("Map page for child procesee failed: %e\n", r);
  801242:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801246:	c7 44 24 08 80 1e 80 	movl   $0x801e80,0x8(%esp)
  80124d:	00 
  80124e:	c7 44 24 04 44 00 00 	movl   $0x44,0x4(%esp)
  801255:	00 
  801256:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  80125d:	e8 be 04 00 00       	call   801720 <_panic>
		if((r = sys_page_map(envid, (void *)(pn*PGSIZE), 0, (void *)(pn*PGSIZE), PTE_P|PTE_COW|PTE_U)))
  801262:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  801269:	00 
  80126a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80126e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801275:	00 
  801276:	89 74 24 04          	mov    %esi,0x4(%esp)
  80127a:	89 3c 24             	mov    %edi,(%esp)
  80127d:	e8 f9 fb ff ff       	call   800e7b <sys_page_map>
  801282:	85 c0                	test   %eax,%eax
  801284:	74 64                	je     8012ea <fork+0x18b>
			panic("Map page for child procesee failed: %e\n", r);
  801286:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80128a:	c7 44 24 08 80 1e 80 	movl   $0x801e80,0x8(%esp)
  801291:	00 
  801292:	c7 44 24 04 46 00 00 	movl   $0x46,0x4(%esp)
  801299:	00 
  80129a:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  8012a1:	e8 7a 04 00 00       	call   801720 <_panic>
	}else
		if((r = sys_page_map(0, (void *)(pn*PGSIZE), envid, (void *)(pn*PGSIZE), PTE_P|PTE_U)))
  8012a6:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
  8012ad:	00 
  8012ae:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8012b2:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8012b6:	89 74 24 04          	mov    %esi,0x4(%esp)
  8012ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8012c1:	e8 b5 fb ff ff       	call   800e7b <sys_page_map>
  8012c6:	85 c0                	test   %eax,%eax
  8012c8:	74 20                	je     8012ea <fork+0x18b>
			panic("Map page for child procesee failed: %e\n", r);
  8012ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012ce:	c7 44 24 08 80 1e 80 	movl   $0x801e80,0x8(%esp)
  8012d5:	00 
  8012d6:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
  8012dd:	00 
  8012de:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  8012e5:	e8 36 04 00 00       	call   801720 <_panic>
		panic("Fork error\n");
	if(ch_id == 0){ /* the child process */
		thisenv =  &envs[ENVX(sys_getenvid())];
		return 0;
	}
	for(cow_pg_ptr = UTEXT; cow_pg_ptr < UXSTACKTOP - PGSIZE; cow_pg_ptr += PGSIZE){
  8012ea:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  8012f0:	81 fb 00 f0 bf ee    	cmp    $0xeebff000,%ebx
  8012f6:	0f 85 cd fe ff ff    	jne    8011c9 <fork+0x6a>
		if ((vpd[PDX(cow_pg_ptr)] & PTE_P) && (vpt[PGNUM(cow_pg_ptr)] & (PTE_P|PTE_U))) 
			duppage(ch_id, PGNUM(cow_pg_ptr));
	}

	if((r = sys_page_alloc(ch_id, (void *)(UXSTACKTOP - PGSIZE), PTE_U|PTE_P|PTE_W)))
  8012fc:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801303:	00 
  801304:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  80130b:	ee 
  80130c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80130f:	89 04 24             	mov    %eax,(%esp)
  801312:	e8 05 fb ff ff       	call   800e1c <sys_page_alloc>
  801317:	85 c0                	test   %eax,%eax
  801319:	74 20                	je     80133b <fork+0x1dc>
		panic("Alloc exception stack error: %e\n", r);
  80131b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80131f:	c7 44 24 08 a8 1e 80 	movl   $0x801ea8,0x8(%esp)
  801326:	00 
  801327:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  80132e:	00 
  80132f:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  801336:	e8 e5 03 00 00       	call   801720 <_panic>

	extern void _pgfault_upcall(void);
	sys_env_set_pgfault_upcall(ch_id, _pgfault_upcall);
  80133b:	c7 44 24 04 00 18 80 	movl   $0x801800,0x4(%esp)
  801342:	00 
  801343:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801346:	89 04 24             	mov    %eax,(%esp)
  801349:	e8 47 fc ff ff       	call   800f95 <sys_env_set_pgfault_upcall>

	sys_env_set_status(ch_id, ENV_RUNNABLE);
  80134e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  801355:	00 
  801356:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801359:	89 04 24             	mov    %eax,(%esp)
  80135c:	e8 d6 fb ff ff       	call   800f37 <sys_env_set_status>
	return ch_id;
	//panic("fork not implemented");
}
  801361:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801364:	83 c4 3c             	add    $0x3c,%esp
  801367:	5b                   	pop    %ebx
  801368:	5e                   	pop    %esi
  801369:	5f                   	pop    %edi
  80136a:	5d                   	pop    %ebp
  80136b:	c3                   	ret    

0080136c <sfork>:

// Challenge!
int
sfork(void)
{
  80136c:	55                   	push   %ebp
  80136d:	89 e5                	mov    %esp,%ebp
  80136f:	57                   	push   %edi
  801370:	56                   	push   %esi
  801371:	53                   	push   %ebx
  801372:	83 ec 3c             	sub    $0x3c,%esp
	set_pgfault_handler (pgfault);
  801375:	c7 04 24 84 10 80 00 	movl   $0x801084,(%esp)
  80137c:	e8 0f 04 00 00       	call   801790 <set_pgfault_handler>
  801381:	ba 07 00 00 00       	mov    $0x7,%edx
  801386:	89 d0                	mov    %edx,%eax
  801388:	cd 30                	int    $0x30
  80138a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80138d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	envid_t envid;
	uint32_t i;
	int r;
	envid = sys_exofork();
	
	if(envid < 0)
  801390:	85 c0                	test   %eax,%eax
  801392:	79 20                	jns    8013b4 <sfork+0x48>
		panic("sys_exofork: %e", envid);
  801394:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801398:	c7 44 24 08 33 1e 80 	movl   $0x801e33,0x8(%esp)
  80139f:	00 
  8013a0:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
  8013a7:	00 
  8013a8:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  8013af:	e8 6c 03 00 00       	call   801720 <_panic>
		
	if(envid == 0){
  8013b4:	be 01 00 00 00       	mov    $0x1,%esi
  8013b9:	bb 00 d0 bf ee       	mov    $0xeebfd000,%ebx
  8013be:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8013c2:	75 1c                	jne    8013e0 <sfork+0x74>
		thisenv = &envs[ENVX(sys_getenvid())];
  8013c4:	e8 f3 f9 ff ff       	call   800dbc <sys_getenvid>
  8013c9:	25 ff 03 00 00       	and    $0x3ff,%eax
  8013ce:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8013d1:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8013d6:	a3 08 20 80 00       	mov    %eax,0x802008
		return 0;
  8013db:	e9 26 02 00 00       	jmp    801606 <sfork+0x29a>
	}
	
	int instack = 1;
	for(i = USTACKTOP - PGSIZE; i >= UTEXT; i -= PGSIZE){
		if((vpd[PDX(i)] & PTE_P) > 0 && (vpt[PGNUM(i)] & PTE_P) > 0 && (vpt[PGNUM(i)] & PTE_U) > 0)
  8013e0:	89 d8                	mov    %ebx,%eax
  8013e2:	c1 e8 16             	shr    $0x16,%eax
  8013e5:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  8013ec:	a8 01                	test   $0x1,%al
  8013ee:	0f 84 64 01 00 00    	je     801558 <sfork+0x1ec>
  8013f4:	89 df                	mov    %ebx,%edi
  8013f6:	c1 ef 0c             	shr    $0xc,%edi
  8013f9:	8b 04 bd 00 00 40 ef 	mov    -0x10c00000(,%edi,4),%eax
  801400:	a8 01                	test   $0x1,%al
  801402:	0f 84 57 01 00 00    	je     80155f <sfork+0x1f3>
  801408:	8b 04 bd 00 00 40 ef 	mov    -0x10c00000(,%edi,4),%eax
  80140f:	a8 04                	test   $0x4,%al
  801411:	0f 84 4f 01 00 00    	je     801566 <sfork+0x1fa>

static int
sduppage(envid_t envid, unsigned pn, int use_cow)
{
	int r;
	void *i = (void *) ((uint32_t) pn * PGSIZE);
  801417:	c1 e7 0c             	shl    $0xc,%edi
	pte_t pte = vpt[PGNUM(i)];
  80141a:	89 f8                	mov    %edi,%eax
  80141c:	c1 e8 0c             	shr    $0xc,%eax
  80141f:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax

	if (use_cow || (pte & PTE_COW) > 0) {
  801426:	85 f6                	test   %esi,%esi
  801428:	75 09                	jne    801433 <sfork+0xc7>
  80142a:	f6 c4 08             	test   $0x8,%ah
  80142d:	0f 84 93 00 00 00    	je     8014c6 <sfork+0x15a>
		if((r = sys_page_map(0, i, envid, i, PTE_U|PTE_P|PTE_COW))<0)
  801433:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  80143a:	00 
  80143b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80143f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  801442:	89 44 24 08          	mov    %eax,0x8(%esp)
  801446:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80144a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801451:	e8 25 fa ff ff       	call   800e7b <sys_page_map>
  801456:	85 c0                	test   %eax,%eax
  801458:	79 20                	jns    80147a <sfork+0x10e>
			panic("sduppage: page map failed: %e",r);
  80145a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80145e:	c7 44 24 08 43 1e 80 	movl   $0x801e43,0x8(%esp)
  801465:	00 
  801466:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  80146d:	00 
  80146e:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  801475:	e8 a6 02 00 00       	call   801720 <_panic>
		
		if((r = sys_page_map(0, i, 0, i, PTE_U|PTE_P|PTE_COW)) < 0)
  80147a:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  801481:	00 
  801482:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801486:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80148d:	00 
  80148e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  801492:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801499:	e8 dd f9 ff ff       	call   800e7b <sys_page_map>
  80149e:	85 c0                	test   %eax,%eax
  8014a0:	0f 89 c5 00 00 00    	jns    80156b <sfork+0x1ff>
			panic("sduppage: page map failed: %e",r);
  8014a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8014aa:	c7 44 24 08 43 1e 80 	movl   $0x801e43,0x8(%esp)
  8014b1:	00 
  8014b2:	c7 44 24 04 b1 00 00 	movl   $0xb1,0x4(%esp)
  8014b9:	00 
  8014ba:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  8014c1:	e8 5a 02 00 00       	call   801720 <_panic>
	} else if((pte & PTE_W) > 0){
  8014c6:	a8 02                	test   $0x2,%al
  8014c8:	74 47                	je     801511 <sfork+0x1a5>
		if((r = sys_page_map(0, i, envid, i, PTE_U|PTE_P|PTE_W)) < 0)
  8014ca:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  8014d1:	00 
  8014d2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8014d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8014d9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8014dd:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8014e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8014e8:	e8 8e f9 ff ff       	call   800e7b <sys_page_map>
  8014ed:	85 c0                	test   %eax,%eax
  8014ef:	79 7a                	jns    80156b <sfork+0x1ff>
			panic("sduppage: page map failed: %e",r);
  8014f1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8014f5:	c7 44 24 08 43 1e 80 	movl   $0x801e43,0x8(%esp)
  8014fc:	00 
  8014fd:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  801504:	00 
  801505:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  80150c:	e8 0f 02 00 00       	call   801720 <_panic>
	} else{
		if((r = sys_page_map(0, i, envid, i, PTE_U|PTE_P)) < 0)
  801511:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
  801518:	00 
  801519:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80151d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  801520:	89 44 24 08          	mov    %eax,0x8(%esp)
  801524:	89 7c 24 04          	mov    %edi,0x4(%esp)
  801528:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80152f:	e8 47 f9 ff ff       	call   800e7b <sys_page_map>
  801534:	85 c0                	test   %eax,%eax
  801536:	79 33                	jns    80156b <sfork+0x1ff>
			panic("sduppage: page map failed: %e",r);
  801538:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80153c:	c7 44 24 08 43 1e 80 	movl   $0x801e43,0x8(%esp)
  801543:	00 
  801544:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  80154b:	00 
  80154c:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  801553:	e8 c8 01 00 00       	call   801720 <_panic>
	int instack = 1;
	for(i = USTACKTOP - PGSIZE; i >= UTEXT; i -= PGSIZE){
		if((vpd[PDX(i)] & PTE_P) > 0 && (vpt[PGNUM(i)] & PTE_P) > 0 && (vpt[PGNUM(i)] & PTE_U) > 0)
			sduppage(envid, PGNUM(i), instack);
		else
			instack = 0;
  801558:	be 00 00 00 00       	mov    $0x0,%esi
  80155d:	eb 0c                	jmp    80156b <sfork+0x1ff>
  80155f:	be 00 00 00 00       	mov    $0x0,%esi
  801564:	eb 05                	jmp    80156b <sfork+0x1ff>
  801566:	be 00 00 00 00       	mov    $0x0,%esi
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	
	int instack = 1;
	for(i = USTACKTOP - PGSIZE; i >= UTEXT; i -= PGSIZE){
  80156b:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  801571:	81 fb 00 f0 7f 00    	cmp    $0x7ff000,%ebx
  801577:	0f 85 63 fe ff ff    	jne    8013e0 <sfork+0x74>
			sduppage(envid, PGNUM(i), instack);
		else
			instack = 0;
	}
	
	if((r = sys_page_alloc(envid, (void *)(UXSTACKTOP- PGSIZE), PTE_U|PTE_W|PTE_P)) < 0)
  80157d:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801584:	00 
  801585:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  80158c:	ee 
  80158d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801590:	89 04 24             	mov    %eax,(%esp)
  801593:	e8 84 f8 ff ff       	call   800e1c <sys_page_alloc>
  801598:	85 c0                	test   %eax,%eax
  80159a:	79 20                	jns    8015bc <sfork+0x250>
		panic("sfork: page alloc failed : %e", r);
  80159c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8015a0:	c7 44 24 08 61 1e 80 	movl   $0x801e61,0x8(%esp)
  8015a7:	00 
  8015a8:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  8015af:	00 
  8015b0:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  8015b7:	e8 64 01 00 00       	call   801720 <_panic>
	
	extern void _pgfault_upcall(void);
	sys_env_set_pgfault_upcall(envid, _pgfault_upcall);
  8015bc:	c7 44 24 04 00 18 80 	movl   $0x801800,0x4(%esp)
  8015c3:	00 
  8015c4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8015c7:	89 04 24             	mov    %eax,(%esp)
  8015ca:	e8 c6 f9 ff ff       	call   800f95 <sys_env_set_pgfault_upcall>
	
	if((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
  8015cf:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  8015d6:	00 
  8015d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8015da:	89 04 24             	mov    %eax,(%esp)
  8015dd:	e8 55 f9 ff ff       	call   800f37 <sys_env_set_status>
  8015e2:	85 c0                	test   %eax,%eax
  8015e4:	79 20                	jns    801606 <sfork+0x29a>
		panic("sfork: set child env status failed : %e", r);
  8015e6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8015ea:	c7 44 24 08 cc 1e 80 	movl   $0x801ecc,0x8(%esp)
  8015f1:	00 
  8015f2:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  8015f9:	00 
  8015fa:	c7 04 24 07 1e 80 00 	movl   $0x801e07,(%esp)
  801601:	e8 1a 01 00 00       	call   801720 <_panic>
		
	return envid;
}
  801606:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801609:	83 c4 3c             	add    $0x3c,%esp
  80160c:	5b                   	pop    %ebx
  80160d:	5e                   	pop    %esi
  80160e:	5f                   	pop    %edi
  80160f:	5d                   	pop    %ebp
  801610:	c3                   	ret    
  801611:	66 90                	xchg   %ax,%ax
  801613:	90                   	nop

00801614 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  801614:	55                   	push   %ebp
  801615:	89 e5                	mov    %esp,%ebp
  801617:	56                   	push   %esi
  801618:	53                   	push   %ebx
  801619:	83 ec 10             	sub    $0x10,%esp
  80161c:	8b 75 08             	mov    0x8(%ebp),%esi
  80161f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// LAB 4: Your code here.
	int r;
	if(pg == NULL)
		pg = (void *)~0x0;
  801622:	85 db                	test   %ebx,%ebx
  801624:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  801629:	0f 44 d8             	cmove  %eax,%ebx
	//else
	if((r = sys_ipc_recv(pg)) < 0)
  80162c:	89 1c 24             	mov    %ebx,(%esp)
  80162f:	e8 f3 f9 ff ff       	call   801027 <sys_ipc_recv>
  801634:	85 c0                	test   %eax,%eax
  801636:	78 2d                	js     801665 <ipc_recv+0x51>
		return r;
	//volatile struct Env *curenv = (struct Env*)envs+ENVX(sys_getenvid());

	if(from_env_store)
  801638:	85 f6                	test   %esi,%esi
  80163a:	74 0a                	je     801646 <ipc_recv+0x32>
		*from_env_store = thisenv -> env_ipc_from;
  80163c:	a1 08 20 80 00       	mov    0x802008,%eax
  801641:	8b 40 74             	mov    0x74(%eax),%eax
  801644:	89 06                	mov    %eax,(%esi)
	if(pg && perm_store)
  801646:	85 db                	test   %ebx,%ebx
  801648:	74 13                	je     80165d <ipc_recv+0x49>
  80164a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  80164e:	74 0d                	je     80165d <ipc_recv+0x49>
		*perm_store = thisenv -> env_ipc_perm;
  801650:	a1 08 20 80 00       	mov    0x802008,%eax
  801655:	8b 40 78             	mov    0x78(%eax),%eax
  801658:	8b 55 10             	mov    0x10(%ebp),%edx
  80165b:	89 02                	mov    %eax,(%edx)
	else if(perm_store)
		perm_store = (int *)0;
	return thisenv->env_ipc_value;
  80165d:	a1 08 20 80 00       	mov    0x802008,%eax
  801662:	8b 40 70             	mov    0x70(%eax),%eax
}
  801665:	83 c4 10             	add    $0x10,%esp
  801668:	5b                   	pop    %ebx
  801669:	5e                   	pop    %esi
  80166a:	5d                   	pop    %ebp
  80166b:	c3                   	ret    

0080166c <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  80166c:	55                   	push   %ebp
  80166d:	89 e5                	mov    %esp,%ebp
  80166f:	57                   	push   %edi
  801670:	56                   	push   %esi
  801671:	53                   	push   %ebx
  801672:	83 ec 1c             	sub    $0x1c,%esp
  801675:	8b 7d 08             	mov    0x8(%ebp),%edi
  801678:	8b 75 0c             	mov    0xc(%ebp),%esi
  80167b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	int r;

	if(pg == NULL)
  80167e:	85 db                	test   %ebx,%ebx
		pg = (void *)~0x0;
  801680:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  801685:	0f 44 d8             	cmove  %eax,%ebx
  801688:	eb 2a                	jmp    8016b4 <ipc_send+0x48>
	while((r = sys_ipc_try_send(to_env, val, pg, perm)) < 0){
		if(r != -E_IPC_NOT_RECV)
  80168a:	83 f8 f9             	cmp    $0xfffffff9,%eax
  80168d:	74 20                	je     8016af <ipc_send+0x43>
            panic("Send message error %e\n",r);
  80168f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801693:	c7 44 24 08 f4 1e 80 	movl   $0x801ef4,0x8(%esp)
  80169a:	00 
  80169b:	c7 44 24 04 3d 00 00 	movl   $0x3d,0x4(%esp)
  8016a2:	00 
  8016a3:	c7 04 24 0b 1f 80 00 	movl   $0x801f0b,(%esp)
  8016aa:	e8 71 00 00 00       	call   801720 <_panic>
		sys_yield();
  8016af:	e8 38 f7 ff ff       	call   800dec <sys_yield>
	// LAB 4: Your code here.
	int r;

	if(pg == NULL)
		pg = (void *)~0x0;
	while((r = sys_ipc_try_send(to_env, val, pg, perm)) < 0){
  8016b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8016b7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8016bb:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8016bf:	89 74 24 04          	mov    %esi,0x4(%esp)
  8016c3:	89 3c 24             	mov    %edi,(%esp)
  8016c6:	e8 28 f9 ff ff       	call   800ff3 <sys_ipc_try_send>
  8016cb:	85 c0                	test   %eax,%eax
  8016cd:	78 bb                	js     80168a <ipc_send+0x1e>
		if(r != -E_IPC_NOT_RECV)
            panic("Send message error %e\n",r);
		sys_yield();
	}
	// panic("ipc_send not implemented");
}
  8016cf:	83 c4 1c             	add    $0x1c,%esp
  8016d2:	5b                   	pop    %ebx
  8016d3:	5e                   	pop    %esi
  8016d4:	5f                   	pop    %edi
  8016d5:	5d                   	pop    %ebp
  8016d6:	c3                   	ret    

008016d7 <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  8016d7:	55                   	push   %ebp
  8016d8:	89 e5                	mov    %esp,%ebp
  8016da:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
		if (envs[i].env_type == type)
  8016dd:	a1 50 00 c0 ee       	mov    0xeec00050,%eax
  8016e2:	39 c8                	cmp    %ecx,%eax
  8016e4:	74 17                	je     8016fd <ipc_find_env+0x26>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  8016e6:	b8 01 00 00 00       	mov    $0x1,%eax
		if (envs[i].env_type == type)
  8016eb:	6b d0 7c             	imul   $0x7c,%eax,%edx
  8016ee:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  8016f4:	8b 52 50             	mov    0x50(%edx),%edx
  8016f7:	39 ca                	cmp    %ecx,%edx
  8016f9:	75 14                	jne    80170f <ipc_find_env+0x38>
  8016fb:	eb 05                	jmp    801702 <ipc_find_env+0x2b>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  8016fd:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
			return envs[i].env_id;
  801702:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801705:	05 08 00 c0 ee       	add    $0xeec00008,%eax
  80170a:	8b 40 40             	mov    0x40(%eax),%eax
  80170d:	eb 0e                	jmp    80171d <ipc_find_env+0x46>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  80170f:	83 c0 01             	add    $0x1,%eax
  801712:	3d 00 04 00 00       	cmp    $0x400,%eax
  801717:	75 d2                	jne    8016eb <ipc_find_env+0x14>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  801719:	66 b8 00 00          	mov    $0x0,%ax
}
  80171d:	5d                   	pop    %ebp
  80171e:	c3                   	ret    
  80171f:	90                   	nop

00801720 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  801720:	55                   	push   %ebp
  801721:	89 e5                	mov    %esp,%ebp
  801723:	56                   	push   %esi
  801724:	53                   	push   %ebx
  801725:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  801728:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  80172b:	a1 0c 20 80 00       	mov    0x80200c,%eax
  801730:	85 c0                	test   %eax,%eax
  801732:	74 10                	je     801744 <_panic+0x24>
		cprintf("%s: ", argv0);
  801734:	89 44 24 04          	mov    %eax,0x4(%esp)
  801738:	c7 04 24 15 1f 80 00 	movl   $0x801f15,(%esp)
  80173f:	e8 33 eb ff ff       	call   800277 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801744:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80174a:	e8 6d f6 ff ff       	call   800dbc <sys_getenvid>
  80174f:	8b 55 0c             	mov    0xc(%ebp),%edx
  801752:	89 54 24 10          	mov    %edx,0x10(%esp)
  801756:	8b 55 08             	mov    0x8(%ebp),%edx
  801759:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80175d:	89 74 24 08          	mov    %esi,0x8(%esp)
  801761:	89 44 24 04          	mov    %eax,0x4(%esp)
  801765:	c7 04 24 1c 1f 80 00 	movl   $0x801f1c,(%esp)
  80176c:	e8 06 eb ff ff       	call   800277 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801771:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  801775:	8b 45 10             	mov    0x10(%ebp),%eax
  801778:	89 04 24             	mov    %eax,(%esp)
  80177b:	e8 96 ea ff ff       	call   800216 <vcprintf>
	cprintf("\n");
  801780:	c7 04 24 05 1e 80 00 	movl   $0x801e05,(%esp)
  801787:	e8 eb ea ff ff       	call   800277 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80178c:	cc                   	int3   
  80178d:	eb fd                	jmp    80178c <_panic+0x6c>
  80178f:	90                   	nop

00801790 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801790:	55                   	push   %ebp
  801791:	89 e5                	mov    %esp,%ebp
  801793:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  801796:	83 3d 10 20 80 00 00 	cmpl   $0x0,0x802010
  80179d:	75 54                	jne    8017f3 <set_pgfault_handler+0x63>
		// First time through!
		// LAB 4: Your code here.
		if((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE), PTE_U|PTE_P|PTE_W)))
  80179f:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8017a6:	00 
  8017a7:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  8017ae:	ee 
  8017af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8017b6:	e8 61 f6 ff ff       	call   800e1c <sys_page_alloc>
  8017bb:	85 c0                	test   %eax,%eax
  8017bd:	74 20                	je     8017df <set_pgfault_handler+0x4f>
			panic("Exception stack alloc failed: %e!\n", r);
  8017bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8017c3:	c7 44 24 08 40 1f 80 	movl   $0x801f40,0x8(%esp)
  8017ca:	00 
  8017cb:	c7 44 24 04 21 00 00 	movl   $0x21,0x4(%esp)
  8017d2:	00 
  8017d3:	c7 04 24 64 1f 80 00 	movl   $0x801f64,(%esp)
  8017da:	e8 41 ff ff ff       	call   801720 <_panic>
		sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  8017df:	c7 44 24 04 00 18 80 	movl   $0x801800,0x4(%esp)
  8017e6:	00 
  8017e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8017ee:	e8 a2 f7 ff ff       	call   800f95 <sys_env_set_pgfault_upcall>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8017f3:	8b 45 08             	mov    0x8(%ebp),%eax
  8017f6:	a3 10 20 80 00       	mov    %eax,0x802010
}
  8017fb:	c9                   	leave  
  8017fc:	c3                   	ret    
  8017fd:	66 90                	xchg   %ax,%ax
  8017ff:	90                   	nop

00801800 <_pgfault_upcall>:
  801800:	54                   	push   %esp
  801801:	a1 10 20 80 00       	mov    0x802010,%eax
  801806:	ff d0                	call   *%eax
  801808:	83 c4 04             	add    $0x4,%esp
  80180b:	83 c4 08             	add    $0x8,%esp
  80180e:	8b 4c 24 20          	mov    0x20(%esp),%ecx
  801812:	8b 44 24 28          	mov    0x28(%esp),%eax
  801816:	83 e8 04             	sub    $0x4,%eax
  801819:	89 44 24 28          	mov    %eax,0x28(%esp)
  80181d:	89 08                	mov    %ecx,(%eax)
  80181f:	61                   	popa   
  801820:	83 c4 04             	add    $0x4,%esp
  801823:	9d                   	popf   
  801824:	5c                   	pop    %esp
  801825:	c3                   	ret    
  801826:	66 90                	xchg   %ax,%ax
  801828:	66 90                	xchg   %ax,%ax
  80182a:	66 90                	xchg   %ax,%ax
  80182c:	66 90                	xchg   %ax,%ax
  80182e:	66 90                	xchg   %ax,%ax

00801830 <__udivdi3>:
  801830:	83 ec 1c             	sub    $0x1c,%esp
  801833:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  801837:	89 7c 24 14          	mov    %edi,0x14(%esp)
  80183b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  80183f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  801843:	8b 7c 24 20          	mov    0x20(%esp),%edi
  801847:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  80184b:	85 c0                	test   %eax,%eax
  80184d:	89 74 24 10          	mov    %esi,0x10(%esp)
  801851:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801855:	89 ea                	mov    %ebp,%edx
  801857:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80185b:	75 33                	jne    801890 <__udivdi3+0x60>
  80185d:	39 e9                	cmp    %ebp,%ecx
  80185f:	77 6f                	ja     8018d0 <__udivdi3+0xa0>
  801861:	85 c9                	test   %ecx,%ecx
  801863:	89 ce                	mov    %ecx,%esi
  801865:	75 0b                	jne    801872 <__udivdi3+0x42>
  801867:	b8 01 00 00 00       	mov    $0x1,%eax
  80186c:	31 d2                	xor    %edx,%edx
  80186e:	f7 f1                	div    %ecx
  801870:	89 c6                	mov    %eax,%esi
  801872:	31 d2                	xor    %edx,%edx
  801874:	89 e8                	mov    %ebp,%eax
  801876:	f7 f6                	div    %esi
  801878:	89 c5                	mov    %eax,%ebp
  80187a:	89 f8                	mov    %edi,%eax
  80187c:	f7 f6                	div    %esi
  80187e:	89 ea                	mov    %ebp,%edx
  801880:	8b 74 24 10          	mov    0x10(%esp),%esi
  801884:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801888:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  80188c:	83 c4 1c             	add    $0x1c,%esp
  80188f:	c3                   	ret    
  801890:	39 e8                	cmp    %ebp,%eax
  801892:	77 24                	ja     8018b8 <__udivdi3+0x88>
  801894:	0f bd c8             	bsr    %eax,%ecx
  801897:	83 f1 1f             	xor    $0x1f,%ecx
  80189a:	89 0c 24             	mov    %ecx,(%esp)
  80189d:	75 49                	jne    8018e8 <__udivdi3+0xb8>
  80189f:	8b 74 24 08          	mov    0x8(%esp),%esi
  8018a3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  8018a7:	0f 86 ab 00 00 00    	jbe    801958 <__udivdi3+0x128>
  8018ad:	39 e8                	cmp    %ebp,%eax
  8018af:	0f 82 a3 00 00 00    	jb     801958 <__udivdi3+0x128>
  8018b5:	8d 76 00             	lea    0x0(%esi),%esi
  8018b8:	31 d2                	xor    %edx,%edx
  8018ba:	31 c0                	xor    %eax,%eax
  8018bc:	8b 74 24 10          	mov    0x10(%esp),%esi
  8018c0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8018c4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8018c8:	83 c4 1c             	add    $0x1c,%esp
  8018cb:	c3                   	ret    
  8018cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8018d0:	89 f8                	mov    %edi,%eax
  8018d2:	f7 f1                	div    %ecx
  8018d4:	31 d2                	xor    %edx,%edx
  8018d6:	8b 74 24 10          	mov    0x10(%esp),%esi
  8018da:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8018de:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8018e2:	83 c4 1c             	add    $0x1c,%esp
  8018e5:	c3                   	ret    
  8018e6:	66 90                	xchg   %ax,%ax
  8018e8:	0f b6 0c 24          	movzbl (%esp),%ecx
  8018ec:	89 c6                	mov    %eax,%esi
  8018ee:	b8 20 00 00 00       	mov    $0x20,%eax
  8018f3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  8018f7:	2b 04 24             	sub    (%esp),%eax
  8018fa:	8b 7c 24 08          	mov    0x8(%esp),%edi
  8018fe:	d3 e6                	shl    %cl,%esi
  801900:	89 c1                	mov    %eax,%ecx
  801902:	d3 ed                	shr    %cl,%ebp
  801904:	0f b6 0c 24          	movzbl (%esp),%ecx
  801908:	09 f5                	or     %esi,%ebp
  80190a:	8b 74 24 04          	mov    0x4(%esp),%esi
  80190e:	d3 e6                	shl    %cl,%esi
  801910:	89 c1                	mov    %eax,%ecx
  801912:	89 74 24 04          	mov    %esi,0x4(%esp)
  801916:	89 d6                	mov    %edx,%esi
  801918:	d3 ee                	shr    %cl,%esi
  80191a:	0f b6 0c 24          	movzbl (%esp),%ecx
  80191e:	d3 e2                	shl    %cl,%edx
  801920:	89 c1                	mov    %eax,%ecx
  801922:	d3 ef                	shr    %cl,%edi
  801924:	09 d7                	or     %edx,%edi
  801926:	89 f2                	mov    %esi,%edx
  801928:	89 f8                	mov    %edi,%eax
  80192a:	f7 f5                	div    %ebp
  80192c:	89 d6                	mov    %edx,%esi
  80192e:	89 c7                	mov    %eax,%edi
  801930:	f7 64 24 04          	mull   0x4(%esp)
  801934:	39 d6                	cmp    %edx,%esi
  801936:	72 30                	jb     801968 <__udivdi3+0x138>
  801938:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  80193c:	0f b6 0c 24          	movzbl (%esp),%ecx
  801940:	d3 e5                	shl    %cl,%ebp
  801942:	39 c5                	cmp    %eax,%ebp
  801944:	73 04                	jae    80194a <__udivdi3+0x11a>
  801946:	39 d6                	cmp    %edx,%esi
  801948:	74 1e                	je     801968 <__udivdi3+0x138>
  80194a:	89 f8                	mov    %edi,%eax
  80194c:	31 d2                	xor    %edx,%edx
  80194e:	e9 69 ff ff ff       	jmp    8018bc <__udivdi3+0x8c>
  801953:	90                   	nop
  801954:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801958:	31 d2                	xor    %edx,%edx
  80195a:	b8 01 00 00 00       	mov    $0x1,%eax
  80195f:	e9 58 ff ff ff       	jmp    8018bc <__udivdi3+0x8c>
  801964:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801968:	8d 47 ff             	lea    -0x1(%edi),%eax
  80196b:	31 d2                	xor    %edx,%edx
  80196d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801971:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801975:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801979:	83 c4 1c             	add    $0x1c,%esp
  80197c:	c3                   	ret    
  80197d:	66 90                	xchg   %ax,%ax
  80197f:	90                   	nop

00801980 <__umoddi3>:
  801980:	83 ec 2c             	sub    $0x2c,%esp
  801983:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  801987:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80198b:	89 74 24 20          	mov    %esi,0x20(%esp)
  80198f:	8b 74 24 38          	mov    0x38(%esp),%esi
  801993:	89 7c 24 24          	mov    %edi,0x24(%esp)
  801997:	8b 7c 24 34          	mov    0x34(%esp),%edi
  80199b:	85 c0                	test   %eax,%eax
  80199d:	89 c2                	mov    %eax,%edx
  80199f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  8019a3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  8019a7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8019ab:	89 74 24 10          	mov    %esi,0x10(%esp)
  8019af:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  8019b3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8019b7:	75 1f                	jne    8019d8 <__umoddi3+0x58>
  8019b9:	39 fe                	cmp    %edi,%esi
  8019bb:	76 63                	jbe    801a20 <__umoddi3+0xa0>
  8019bd:	89 c8                	mov    %ecx,%eax
  8019bf:	89 fa                	mov    %edi,%edx
  8019c1:	f7 f6                	div    %esi
  8019c3:	89 d0                	mov    %edx,%eax
  8019c5:	31 d2                	xor    %edx,%edx
  8019c7:	8b 74 24 20          	mov    0x20(%esp),%esi
  8019cb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8019cf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8019d3:	83 c4 2c             	add    $0x2c,%esp
  8019d6:	c3                   	ret    
  8019d7:	90                   	nop
  8019d8:	39 f8                	cmp    %edi,%eax
  8019da:	77 64                	ja     801a40 <__umoddi3+0xc0>
  8019dc:	0f bd e8             	bsr    %eax,%ebp
  8019df:	83 f5 1f             	xor    $0x1f,%ebp
  8019e2:	75 74                	jne    801a58 <__umoddi3+0xd8>
  8019e4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8019e8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  8019ec:	0f 87 0e 01 00 00    	ja     801b00 <__umoddi3+0x180>
  8019f2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  8019f6:	29 f1                	sub    %esi,%ecx
  8019f8:	19 c7                	sbb    %eax,%edi
  8019fa:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  8019fe:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801a02:	8b 44 24 14          	mov    0x14(%esp),%eax
  801a06:	8b 54 24 18          	mov    0x18(%esp),%edx
  801a0a:	8b 74 24 20          	mov    0x20(%esp),%esi
  801a0e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801a12:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801a16:	83 c4 2c             	add    $0x2c,%esp
  801a19:	c3                   	ret    
  801a1a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801a20:	85 f6                	test   %esi,%esi
  801a22:	89 f5                	mov    %esi,%ebp
  801a24:	75 0b                	jne    801a31 <__umoddi3+0xb1>
  801a26:	b8 01 00 00 00       	mov    $0x1,%eax
  801a2b:	31 d2                	xor    %edx,%edx
  801a2d:	f7 f6                	div    %esi
  801a2f:	89 c5                	mov    %eax,%ebp
  801a31:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801a35:	31 d2                	xor    %edx,%edx
  801a37:	f7 f5                	div    %ebp
  801a39:	89 c8                	mov    %ecx,%eax
  801a3b:	f7 f5                	div    %ebp
  801a3d:	eb 84                	jmp    8019c3 <__umoddi3+0x43>
  801a3f:	90                   	nop
  801a40:	89 c8                	mov    %ecx,%eax
  801a42:	89 fa                	mov    %edi,%edx
  801a44:	8b 74 24 20          	mov    0x20(%esp),%esi
  801a48:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801a4c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801a50:	83 c4 2c             	add    $0x2c,%esp
  801a53:	c3                   	ret    
  801a54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801a58:	8b 44 24 10          	mov    0x10(%esp),%eax
  801a5c:	be 20 00 00 00       	mov    $0x20,%esi
  801a61:	89 e9                	mov    %ebp,%ecx
  801a63:	29 ee                	sub    %ebp,%esi
  801a65:	d3 e2                	shl    %cl,%edx
  801a67:	89 f1                	mov    %esi,%ecx
  801a69:	d3 e8                	shr    %cl,%eax
  801a6b:	89 e9                	mov    %ebp,%ecx
  801a6d:	09 d0                	or     %edx,%eax
  801a6f:	89 fa                	mov    %edi,%edx
  801a71:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801a75:	8b 44 24 10          	mov    0x10(%esp),%eax
  801a79:	d3 e0                	shl    %cl,%eax
  801a7b:	89 f1                	mov    %esi,%ecx
  801a7d:	89 44 24 10          	mov    %eax,0x10(%esp)
  801a81:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  801a85:	d3 ea                	shr    %cl,%edx
  801a87:	89 e9                	mov    %ebp,%ecx
  801a89:	d3 e7                	shl    %cl,%edi
  801a8b:	89 f1                	mov    %esi,%ecx
  801a8d:	d3 e8                	shr    %cl,%eax
  801a8f:	89 e9                	mov    %ebp,%ecx
  801a91:	09 f8                	or     %edi,%eax
  801a93:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  801a97:	f7 74 24 0c          	divl   0xc(%esp)
  801a9b:	d3 e7                	shl    %cl,%edi
  801a9d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801aa1:	89 d7                	mov    %edx,%edi
  801aa3:	f7 64 24 10          	mull   0x10(%esp)
  801aa7:	39 d7                	cmp    %edx,%edi
  801aa9:	89 c1                	mov    %eax,%ecx
  801aab:	89 54 24 14          	mov    %edx,0x14(%esp)
  801aaf:	72 3b                	jb     801aec <__umoddi3+0x16c>
  801ab1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  801ab5:	72 31                	jb     801ae8 <__umoddi3+0x168>
  801ab7:	8b 44 24 18          	mov    0x18(%esp),%eax
  801abb:	29 c8                	sub    %ecx,%eax
  801abd:	19 d7                	sbb    %edx,%edi
  801abf:	89 e9                	mov    %ebp,%ecx
  801ac1:	89 fa                	mov    %edi,%edx
  801ac3:	d3 e8                	shr    %cl,%eax
  801ac5:	89 f1                	mov    %esi,%ecx
  801ac7:	d3 e2                	shl    %cl,%edx
  801ac9:	89 e9                	mov    %ebp,%ecx
  801acb:	09 d0                	or     %edx,%eax
  801acd:	89 fa                	mov    %edi,%edx
  801acf:	d3 ea                	shr    %cl,%edx
  801ad1:	8b 74 24 20          	mov    0x20(%esp),%esi
  801ad5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801ad9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801add:	83 c4 2c             	add    $0x2c,%esp
  801ae0:	c3                   	ret    
  801ae1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801ae8:	39 d7                	cmp    %edx,%edi
  801aea:	75 cb                	jne    801ab7 <__umoddi3+0x137>
  801aec:	8b 54 24 14          	mov    0x14(%esp),%edx
  801af0:	89 c1                	mov    %eax,%ecx
  801af2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801af6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  801afa:	eb bb                	jmp    801ab7 <__umoddi3+0x137>
  801afc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801b00:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801b04:	0f 82 e8 fe ff ff    	jb     8019f2 <__umoddi3+0x72>
  801b0a:	e9 f3 fe ff ff       	jmp    801a02 <__umoddi3+0x82>

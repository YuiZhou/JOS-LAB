
obj/user/forktree：     文件格式 elf32-i386


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
  80002c:	e8 cb 00 00 00       	call   8000fc <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	90                   	nop

00800034 <forktree>:
	}
}

void
forktree(const char *cur)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	53                   	push   %ebx
  800038:	83 ec 14             	sub    $0x14,%esp
  80003b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("%04x: I am '%s'\n", sys_getenvid(), cur);
  80003e:	e8 29 0d 00 00       	call   800d6c <sys_getenvid>
  800043:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800047:	89 44 24 04          	mov    %eax,0x4(%esp)
  80004b:	c7 04 24 c0 19 80 00 	movl   $0x8019c0,(%esp)
  800052:	e8 d0 01 00 00       	call   800227 <cprintf>

	forkchild(cur, '0');
  800057:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
  80005e:	00 
  80005f:	89 1c 24             	mov    %ebx,(%esp)
  800062:	e8 16 00 00 00       	call   80007d <forkchild>
	forkchild(cur, '1');
  800067:	c7 44 24 04 31 00 00 	movl   $0x31,0x4(%esp)
  80006e:	00 
  80006f:	89 1c 24             	mov    %ebx,(%esp)
  800072:	e8 06 00 00 00       	call   80007d <forkchild>
}
  800077:	83 c4 14             	add    $0x14,%esp
  80007a:	5b                   	pop    %ebx
  80007b:	5d                   	pop    %ebp
  80007c:	c3                   	ret    

0080007d <forkchild>:

void forktree(const char *cur);

void
forkchild(const char *cur, char branch)
{
  80007d:	55                   	push   %ebp
  80007e:	89 e5                	mov    %esp,%ebp
  800080:	83 ec 38             	sub    $0x38,%esp
  800083:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800086:	89 75 fc             	mov    %esi,-0x4(%ebp)
  800089:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80008c:	8b 75 0c             	mov    0xc(%ebp),%esi
	char nxt[DEPTH+1];

	if (strlen(cur) >= DEPTH)
  80008f:	89 1c 24             	mov    %ebx,(%esp)
  800092:	e8 b9 07 00 00       	call   800850 <strlen>
  800097:	83 f8 02             	cmp    $0x2,%eax
  80009a:	7f 41                	jg     8000dd <forkchild+0x60>
		return;

	snprintf(nxt, DEPTH+1, "%s%c", cur, branch);
  80009c:	89 f0                	mov    %esi,%eax
  80009e:	0f be f0             	movsbl %al,%esi
  8000a1:	89 74 24 10          	mov    %esi,0x10(%esp)
  8000a5:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8000a9:	c7 44 24 08 d1 19 80 	movl   $0x8019d1,0x8(%esp)
  8000b0:	00 
  8000b1:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
  8000b8:	00 
  8000b9:	8d 45 f4             	lea    -0xc(%ebp),%eax
  8000bc:	89 04 24             	mov    %eax,(%esp)
  8000bf:	e8 55 07 00 00       	call   800819 <snprintf>
	if (fork() == 0) {
  8000c4:	e8 46 10 00 00       	call   80110f <fork>
  8000c9:	85 c0                	test   %eax,%eax
  8000cb:	75 10                	jne    8000dd <forkchild+0x60>
		forktree(nxt);
  8000cd:	8d 45 f4             	lea    -0xc(%ebp),%eax
  8000d0:	89 04 24             	mov    %eax,(%esp)
  8000d3:	e8 5c ff ff ff       	call   800034 <forktree>
		exit();
  8000d8:	e8 93 00 00 00       	call   800170 <exit>
	}
}
  8000dd:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  8000e0:	8b 75 fc             	mov    -0x4(%ebp),%esi
  8000e3:	89 ec                	mov    %ebp,%esp
  8000e5:	5d                   	pop    %ebp
  8000e6:	c3                   	ret    

008000e7 <umain>:
	forkchild(cur, '1');
}

void
umain(int argc, char **argv)
{
  8000e7:	55                   	push   %ebp
  8000e8:	89 e5                	mov    %esp,%ebp
  8000ea:	83 ec 18             	sub    $0x18,%esp
	forktree("");
  8000ed:	c7 04 24 66 1c 80 00 	movl   $0x801c66,(%esp)
  8000f4:	e8 3b ff ff ff       	call   800034 <forktree>
}
  8000f9:	c9                   	leave  
  8000fa:	c3                   	ret    
  8000fb:	90                   	nop

008000fc <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000fc:	55                   	push   %ebp
  8000fd:	89 e5                	mov    %esp,%ebp
  8000ff:	57                   	push   %edi
  800100:	56                   	push   %esi
  800101:	53                   	push   %ebx
  800102:	83 ec 1c             	sub    $0x1c,%esp
  800105:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800108:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  80010b:	e8 5c 0c 00 00       	call   800d6c <sys_getenvid>
	thisenv = envs;
  800110:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  800117:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  80011a:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  800120:	39 c2                	cmp    %eax,%edx
  800122:	74 25                	je     800149 <libmain+0x4d>
  800124:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  800129:	eb 12                	jmp    80013d <libmain+0x41>
  80012b:	8b 4a 48             	mov    0x48(%edx),%ecx
  80012e:	83 c2 7c             	add    $0x7c,%edx
  800131:	39 c1                	cmp    %eax,%ecx
  800133:	75 08                	jne    80013d <libmain+0x41>
  800135:	89 3d 04 20 80 00    	mov    %edi,0x802004
  80013b:	eb 0c                	jmp    800149 <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  80013d:	89 d7                	mov    %edx,%edi
  80013f:	85 d2                	test   %edx,%edx
  800141:	75 e8                	jne    80012b <libmain+0x2f>
  800143:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800149:	85 db                	test   %ebx,%ebx
  80014b:	7e 07                	jle    800154 <libmain+0x58>
		binaryname = argv[0];
  80014d:	8b 06                	mov    (%esi),%eax
  80014f:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800154:	89 74 24 04          	mov    %esi,0x4(%esp)
  800158:	89 1c 24             	mov    %ebx,(%esp)
  80015b:	e8 87 ff ff ff       	call   8000e7 <umain>

	// exit gracefully
	exit();
  800160:	e8 0b 00 00 00       	call   800170 <exit>
}
  800165:	83 c4 1c             	add    $0x1c,%esp
  800168:	5b                   	pop    %ebx
  800169:	5e                   	pop    %esi
  80016a:	5f                   	pop    %edi
  80016b:	5d                   	pop    %ebp
  80016c:	c3                   	ret    
  80016d:	66 90                	xchg   %ax,%ax
  80016f:	90                   	nop

00800170 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800170:	55                   	push   %ebp
  800171:	89 e5                	mov    %esp,%ebp
  800173:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800176:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80017d:	e8 8d 0b 00 00       	call   800d0f <sys_env_destroy>
}
  800182:	c9                   	leave  
  800183:	c3                   	ret    

00800184 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800184:	55                   	push   %ebp
  800185:	89 e5                	mov    %esp,%ebp
  800187:	53                   	push   %ebx
  800188:	83 ec 14             	sub    $0x14,%esp
  80018b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80018e:	8b 03                	mov    (%ebx),%eax
  800190:	8b 55 08             	mov    0x8(%ebp),%edx
  800193:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  800197:	83 c0 01             	add    $0x1,%eax
  80019a:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  80019c:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001a1:	75 19                	jne    8001bc <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001a3:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001aa:	00 
  8001ab:	8d 43 08             	lea    0x8(%ebx),%eax
  8001ae:	89 04 24             	mov    %eax,(%esp)
  8001b1:	e8 fa 0a 00 00       	call   800cb0 <sys_cputs>
		b->idx = 0;
  8001b6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8001bc:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001c0:	83 c4 14             	add    $0x14,%esp
  8001c3:	5b                   	pop    %ebx
  8001c4:	5d                   	pop    %ebp
  8001c5:	c3                   	ret    

008001c6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001c6:	55                   	push   %ebp
  8001c7:	89 e5                	mov    %esp,%ebp
  8001c9:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8001cf:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001d6:	00 00 00 
	b.cnt = 0;
  8001d9:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001e0:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001e3:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001e6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001ea:	8b 45 08             	mov    0x8(%ebp),%eax
  8001ed:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001f1:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001f7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001fb:	c7 04 24 84 01 80 00 	movl   $0x800184,(%esp)
  800202:	e8 bb 01 00 00       	call   8003c2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800207:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80020d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800211:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800217:	89 04 24             	mov    %eax,(%esp)
  80021a:	e8 91 0a 00 00       	call   800cb0 <sys_cputs>

	return b.cnt;
}
  80021f:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800225:	c9                   	leave  
  800226:	c3                   	ret    

00800227 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800227:	55                   	push   %ebp
  800228:	89 e5                	mov    %esp,%ebp
  80022a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80022d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800230:	89 44 24 04          	mov    %eax,0x4(%esp)
  800234:	8b 45 08             	mov    0x8(%ebp),%eax
  800237:	89 04 24             	mov    %eax,(%esp)
  80023a:	e8 87 ff ff ff       	call   8001c6 <vcprintf>
	va_end(ap);

	return cnt;
}
  80023f:	c9                   	leave  
  800240:	c3                   	ret    
  800241:	66 90                	xchg   %ax,%ax
  800243:	66 90                	xchg   %ax,%ax
  800245:	66 90                	xchg   %ax,%ax
  800247:	66 90                	xchg   %ax,%ax
  800249:	66 90                	xchg   %ax,%ax
  80024b:	66 90                	xchg   %ax,%ax
  80024d:	66 90                	xchg   %ax,%ax
  80024f:	90                   	nop

00800250 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800250:	55                   	push   %ebp
  800251:	89 e5                	mov    %esp,%ebp
  800253:	57                   	push   %edi
  800254:	56                   	push   %esi
  800255:	53                   	push   %ebx
  800256:	83 ec 4c             	sub    $0x4c,%esp
  800259:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80025c:	89 d7                	mov    %edx,%edi
  80025e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800261:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800264:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800267:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80026a:	b8 00 00 00 00       	mov    $0x0,%eax
  80026f:	39 d8                	cmp    %ebx,%eax
  800271:	72 17                	jb     80028a <printnum+0x3a>
  800273:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800276:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800279:	76 0f                	jbe    80028a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80027b:	8b 75 14             	mov    0x14(%ebp),%esi
  80027e:	83 ee 01             	sub    $0x1,%esi
  800281:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800284:	85 f6                	test   %esi,%esi
  800286:	7f 63                	jg     8002eb <printnum+0x9b>
  800288:	eb 75                	jmp    8002ff <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80028a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80028d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800291:	8b 45 14             	mov    0x14(%ebp),%eax
  800294:	83 e8 01             	sub    $0x1,%eax
  800297:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80029b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80029e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8002a2:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002a6:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002aa:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002ad:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8002b0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8002b7:	00 
  8002b8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002bb:	89 1c 24             	mov    %ebx,(%esp)
  8002be:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8002c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002c5:	e8 06 14 00 00       	call   8016d0 <__udivdi3>
  8002ca:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8002cd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8002d0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8002d4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8002d8:	89 04 24             	mov    %eax,(%esp)
  8002db:	89 54 24 04          	mov    %edx,0x4(%esp)
  8002df:	89 fa                	mov    %edi,%edx
  8002e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002e4:	e8 67 ff ff ff       	call   800250 <printnum>
  8002e9:	eb 14                	jmp    8002ff <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002eb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002ef:	8b 45 18             	mov    0x18(%ebp),%eax
  8002f2:	89 04 24             	mov    %eax,(%esp)
  8002f5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002f7:	83 ee 01             	sub    $0x1,%esi
  8002fa:	75 ef                	jne    8002eb <printnum+0x9b>
  8002fc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002ff:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800303:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800307:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80030a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80030e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800315:	00 
  800316:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800319:	89 1c 24             	mov    %ebx,(%esp)
  80031c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80031f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800323:	e8 f8 14 00 00       	call   801820 <__umoddi3>
  800328:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80032c:	0f be 80 e0 19 80 00 	movsbl 0x8019e0(%eax),%eax
  800333:	89 04 24             	mov    %eax,(%esp)
  800336:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800339:	ff d0                	call   *%eax
}
  80033b:	83 c4 4c             	add    $0x4c,%esp
  80033e:	5b                   	pop    %ebx
  80033f:	5e                   	pop    %esi
  800340:	5f                   	pop    %edi
  800341:	5d                   	pop    %ebp
  800342:	c3                   	ret    

00800343 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800343:	55                   	push   %ebp
  800344:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800346:	83 fa 01             	cmp    $0x1,%edx
  800349:	7e 0e                	jle    800359 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80034b:	8b 10                	mov    (%eax),%edx
  80034d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800350:	89 08                	mov    %ecx,(%eax)
  800352:	8b 02                	mov    (%edx),%eax
  800354:	8b 52 04             	mov    0x4(%edx),%edx
  800357:	eb 22                	jmp    80037b <getuint+0x38>
	else if (lflag)
  800359:	85 d2                	test   %edx,%edx
  80035b:	74 10                	je     80036d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80035d:	8b 10                	mov    (%eax),%edx
  80035f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800362:	89 08                	mov    %ecx,(%eax)
  800364:	8b 02                	mov    (%edx),%eax
  800366:	ba 00 00 00 00       	mov    $0x0,%edx
  80036b:	eb 0e                	jmp    80037b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80036d:	8b 10                	mov    (%eax),%edx
  80036f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800372:	89 08                	mov    %ecx,(%eax)
  800374:	8b 02                	mov    (%edx),%eax
  800376:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80037b:	5d                   	pop    %ebp
  80037c:	c3                   	ret    

0080037d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80037d:	55                   	push   %ebp
  80037e:	89 e5                	mov    %esp,%ebp
  800380:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800383:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800387:	8b 10                	mov    (%eax),%edx
  800389:	3b 50 04             	cmp    0x4(%eax),%edx
  80038c:	73 0a                	jae    800398 <sprintputch+0x1b>
		*b->buf++ = ch;
  80038e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800391:	88 0a                	mov    %cl,(%edx)
  800393:	83 c2 01             	add    $0x1,%edx
  800396:	89 10                	mov    %edx,(%eax)
}
  800398:	5d                   	pop    %ebp
  800399:	c3                   	ret    

0080039a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80039a:	55                   	push   %ebp
  80039b:	89 e5                	mov    %esp,%ebp
  80039d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003a0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003a7:	8b 45 10             	mov    0x10(%ebp),%eax
  8003aa:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003b1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003b5:	8b 45 08             	mov    0x8(%ebp),%eax
  8003b8:	89 04 24             	mov    %eax,(%esp)
  8003bb:	e8 02 00 00 00       	call   8003c2 <vprintfmt>
	va_end(ap);
}
  8003c0:	c9                   	leave  
  8003c1:	c3                   	ret    

008003c2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003c2:	55                   	push   %ebp
  8003c3:	89 e5                	mov    %esp,%ebp
  8003c5:	57                   	push   %edi
  8003c6:	56                   	push   %esi
  8003c7:	53                   	push   %ebx
  8003c8:	83 ec 4c             	sub    $0x4c,%esp
  8003cb:	8b 75 08             	mov    0x8(%ebp),%esi
  8003ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003d1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8003d4:	eb 11                	jmp    8003e7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003d6:	85 c0                	test   %eax,%eax
  8003d8:	0f 84 db 03 00 00    	je     8007b9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  8003de:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003e2:	89 04 24             	mov    %eax,(%esp)
  8003e5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003e7:	0f b6 07             	movzbl (%edi),%eax
  8003ea:	83 c7 01             	add    $0x1,%edi
  8003ed:	83 f8 25             	cmp    $0x25,%eax
  8003f0:	75 e4                	jne    8003d6 <vprintfmt+0x14>
  8003f2:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  8003f6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  8003fd:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800404:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80040b:	ba 00 00 00 00       	mov    $0x0,%edx
  800410:	eb 2b                	jmp    80043d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800412:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800415:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800419:	eb 22                	jmp    80043d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80041b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80041e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800422:	eb 19                	jmp    80043d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800424:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800427:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80042e:	eb 0d                	jmp    80043d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800430:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800433:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800436:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043d:	0f b6 0f             	movzbl (%edi),%ecx
  800440:	8d 47 01             	lea    0x1(%edi),%eax
  800443:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800446:	0f b6 07             	movzbl (%edi),%eax
  800449:	83 e8 23             	sub    $0x23,%eax
  80044c:	3c 55                	cmp    $0x55,%al
  80044e:	0f 87 40 03 00 00    	ja     800794 <vprintfmt+0x3d2>
  800454:	0f b6 c0             	movzbl %al,%eax
  800457:	ff 24 85 a0 1a 80 00 	jmp    *0x801aa0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80045e:	83 e9 30             	sub    $0x30,%ecx
  800461:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800464:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800468:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80046b:	83 f9 09             	cmp    $0x9,%ecx
  80046e:	77 57                	ja     8004c7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800470:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800473:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800476:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800479:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80047c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80047f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800483:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800486:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800489:	83 f9 09             	cmp    $0x9,%ecx
  80048c:	76 eb                	jbe    800479 <vprintfmt+0xb7>
  80048e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800491:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800494:	eb 34                	jmp    8004ca <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800496:	8b 45 14             	mov    0x14(%ebp),%eax
  800499:	8d 48 04             	lea    0x4(%eax),%ecx
  80049c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80049f:	8b 00                	mov    (%eax),%eax
  8004a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004a7:	eb 21                	jmp    8004ca <vprintfmt+0x108>

		case '.':
			if (width < 0)
  8004a9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004ad:	0f 88 71 ff ff ff    	js     800424 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004b6:	eb 85                	jmp    80043d <vprintfmt+0x7b>
  8004b8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004bb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8004c2:	e9 76 ff ff ff       	jmp    80043d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8004ca:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004ce:	0f 89 69 ff ff ff    	jns    80043d <vprintfmt+0x7b>
  8004d4:	e9 57 ff ff ff       	jmp    800430 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004d9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004dc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004df:	e9 59 ff ff ff       	jmp    80043d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e7:	8d 50 04             	lea    0x4(%eax),%edx
  8004ea:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004f1:	8b 00                	mov    (%eax),%eax
  8004f3:	89 04 24             	mov    %eax,(%esp)
  8004f6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004f8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004fb:	e9 e7 fe ff ff       	jmp    8003e7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800500:	8b 45 14             	mov    0x14(%ebp),%eax
  800503:	8d 50 04             	lea    0x4(%eax),%edx
  800506:	89 55 14             	mov    %edx,0x14(%ebp)
  800509:	8b 00                	mov    (%eax),%eax
  80050b:	89 c2                	mov    %eax,%edx
  80050d:	c1 fa 1f             	sar    $0x1f,%edx
  800510:	31 d0                	xor    %edx,%eax
  800512:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800514:	83 f8 08             	cmp    $0x8,%eax
  800517:	7f 0b                	jg     800524 <vprintfmt+0x162>
  800519:	8b 14 85 00 1c 80 00 	mov    0x801c00(,%eax,4),%edx
  800520:	85 d2                	test   %edx,%edx
  800522:	75 20                	jne    800544 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800524:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800528:	c7 44 24 08 f8 19 80 	movl   $0x8019f8,0x8(%esp)
  80052f:	00 
  800530:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800534:	89 34 24             	mov    %esi,(%esp)
  800537:	e8 5e fe ff ff       	call   80039a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80053c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80053f:	e9 a3 fe ff ff       	jmp    8003e7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800544:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800548:	c7 44 24 08 01 1a 80 	movl   $0x801a01,0x8(%esp)
  80054f:	00 
  800550:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800554:	89 34 24             	mov    %esi,(%esp)
  800557:	e8 3e fe ff ff       	call   80039a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80055f:	e9 83 fe ff ff       	jmp    8003e7 <vprintfmt+0x25>
  800564:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800567:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80056a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80056d:	8b 45 14             	mov    0x14(%ebp),%eax
  800570:	8d 50 04             	lea    0x4(%eax),%edx
  800573:	89 55 14             	mov    %edx,0x14(%ebp)
  800576:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800578:	85 ff                	test   %edi,%edi
  80057a:	b8 f1 19 80 00       	mov    $0x8019f1,%eax
  80057f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800582:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800586:	74 06                	je     80058e <vprintfmt+0x1cc>
  800588:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  80058c:	7f 16                	jg     8005a4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80058e:	0f b6 17             	movzbl (%edi),%edx
  800591:	0f be c2             	movsbl %dl,%eax
  800594:	83 c7 01             	add    $0x1,%edi
  800597:	85 c0                	test   %eax,%eax
  800599:	0f 85 9f 00 00 00    	jne    80063e <vprintfmt+0x27c>
  80059f:	e9 8b 00 00 00       	jmp    80062f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005a4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005a8:	89 3c 24             	mov    %edi,(%esp)
  8005ab:	e8 c2 02 00 00       	call   800872 <strnlen>
  8005b0:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8005b3:	29 c2                	sub    %eax,%edx
  8005b5:	89 55 d8             	mov    %edx,-0x28(%ebp)
  8005b8:	85 d2                	test   %edx,%edx
  8005ba:	7e d2                	jle    80058e <vprintfmt+0x1cc>
					putch(padc, putdat);
  8005bc:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8005c0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8005c3:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8005c6:	89 d7                	mov    %edx,%edi
  8005c8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005cc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8005cf:	89 04 24             	mov    %eax,(%esp)
  8005d2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005d4:	83 ef 01             	sub    $0x1,%edi
  8005d7:	75 ef                	jne    8005c8 <vprintfmt+0x206>
  8005d9:	89 7d d8             	mov    %edi,-0x28(%ebp)
  8005dc:	8b 7d cc             	mov    -0x34(%ebp),%edi
  8005df:	eb ad                	jmp    80058e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005e1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8005e5:	74 20                	je     800607 <vprintfmt+0x245>
  8005e7:	0f be d2             	movsbl %dl,%edx
  8005ea:	83 ea 20             	sub    $0x20,%edx
  8005ed:	83 fa 5e             	cmp    $0x5e,%edx
  8005f0:	76 15                	jbe    800607 <vprintfmt+0x245>
					putch('?', putdat);
  8005f2:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8005f5:	89 54 24 04          	mov    %edx,0x4(%esp)
  8005f9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800600:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800603:	ff d1                	call   *%ecx
  800605:	eb 0f                	jmp    800616 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800607:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80060a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80060e:	89 04 24             	mov    %eax,(%esp)
  800611:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800614:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800616:	83 eb 01             	sub    $0x1,%ebx
  800619:	0f b6 17             	movzbl (%edi),%edx
  80061c:	0f be c2             	movsbl %dl,%eax
  80061f:	83 c7 01             	add    $0x1,%edi
  800622:	85 c0                	test   %eax,%eax
  800624:	75 24                	jne    80064a <vprintfmt+0x288>
  800626:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800629:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80062c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80062f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800632:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800636:	0f 8e ab fd ff ff    	jle    8003e7 <vprintfmt+0x25>
  80063c:	eb 20                	jmp    80065e <vprintfmt+0x29c>
  80063e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800641:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800644:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800647:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80064a:	85 f6                	test   %esi,%esi
  80064c:	78 93                	js     8005e1 <vprintfmt+0x21f>
  80064e:	83 ee 01             	sub    $0x1,%esi
  800651:	79 8e                	jns    8005e1 <vprintfmt+0x21f>
  800653:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800656:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800659:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80065c:	eb d1                	jmp    80062f <vprintfmt+0x26d>
  80065e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800661:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800665:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80066c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80066e:	83 ef 01             	sub    $0x1,%edi
  800671:	75 ee                	jne    800661 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800673:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800676:	e9 6c fd ff ff       	jmp    8003e7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80067b:	83 fa 01             	cmp    $0x1,%edx
  80067e:	66 90                	xchg   %ax,%ax
  800680:	7e 16                	jle    800698 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800682:	8b 45 14             	mov    0x14(%ebp),%eax
  800685:	8d 50 08             	lea    0x8(%eax),%edx
  800688:	89 55 14             	mov    %edx,0x14(%ebp)
  80068b:	8b 10                	mov    (%eax),%edx
  80068d:	8b 48 04             	mov    0x4(%eax),%ecx
  800690:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800693:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800696:	eb 32                	jmp    8006ca <vprintfmt+0x308>
	else if (lflag)
  800698:	85 d2                	test   %edx,%edx
  80069a:	74 18                	je     8006b4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  80069c:	8b 45 14             	mov    0x14(%ebp),%eax
  80069f:	8d 50 04             	lea    0x4(%eax),%edx
  8006a2:	89 55 14             	mov    %edx,0x14(%ebp)
  8006a5:	8b 00                	mov    (%eax),%eax
  8006a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8006aa:	89 c1                	mov    %eax,%ecx
  8006ac:	c1 f9 1f             	sar    $0x1f,%ecx
  8006af:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8006b2:	eb 16                	jmp    8006ca <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  8006b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b7:	8d 50 04             	lea    0x4(%eax),%edx
  8006ba:	89 55 14             	mov    %edx,0x14(%ebp)
  8006bd:	8b 00                	mov    (%eax),%eax
  8006bf:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8006c2:	89 c7                	mov    %eax,%edi
  8006c4:	c1 ff 1f             	sar    $0x1f,%edi
  8006c7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8006ca:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8006cd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006d0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006d5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  8006d9:	79 7d                	jns    800758 <vprintfmt+0x396>
				putch('-', putdat);
  8006db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006df:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006e6:	ff d6                	call   *%esi
				num = -(long long) num;
  8006e8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8006eb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8006ee:	f7 d8                	neg    %eax
  8006f0:	83 d2 00             	adc    $0x0,%edx
  8006f3:	f7 da                	neg    %edx
			}
			base = 10;
  8006f5:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8006fa:	eb 5c                	jmp    800758 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006fc:	8d 45 14             	lea    0x14(%ebp),%eax
  8006ff:	e8 3f fc ff ff       	call   800343 <getuint>
			base = 10;
  800704:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800709:	eb 4d                	jmp    800758 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80070b:	8d 45 14             	lea    0x14(%ebp),%eax
  80070e:	e8 30 fc ff ff       	call   800343 <getuint>
			base = 8;
  800713:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800718:	eb 3e                	jmp    800758 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  80071a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80071e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800725:	ff d6                	call   *%esi
			putch('x', putdat);
  800727:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80072b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800732:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800734:	8b 45 14             	mov    0x14(%ebp),%eax
  800737:	8d 50 04             	lea    0x4(%eax),%edx
  80073a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80073d:	8b 00                	mov    (%eax),%eax
  80073f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800744:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800749:	eb 0d                	jmp    800758 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80074b:	8d 45 14             	lea    0x14(%ebp),%eax
  80074e:	e8 f0 fb ff ff       	call   800343 <getuint>
			base = 16;
  800753:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800758:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80075c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800760:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800763:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800767:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80076b:	89 04 24             	mov    %eax,(%esp)
  80076e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800772:	89 da                	mov    %ebx,%edx
  800774:	89 f0                	mov    %esi,%eax
  800776:	e8 d5 fa ff ff       	call   800250 <printnum>
			break;
  80077b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80077e:	e9 64 fc ff ff       	jmp    8003e7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800783:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800787:	89 0c 24             	mov    %ecx,(%esp)
  80078a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80078c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80078f:	e9 53 fc ff ff       	jmp    8003e7 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800794:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800798:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  80079f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007a1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8007a5:	0f 84 3c fc ff ff    	je     8003e7 <vprintfmt+0x25>
  8007ab:	83 ef 01             	sub    $0x1,%edi
  8007ae:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8007b2:	75 f7                	jne    8007ab <vprintfmt+0x3e9>
  8007b4:	e9 2e fc ff ff       	jmp    8003e7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8007b9:	83 c4 4c             	add    $0x4c,%esp
  8007bc:	5b                   	pop    %ebx
  8007bd:	5e                   	pop    %esi
  8007be:	5f                   	pop    %edi
  8007bf:	5d                   	pop    %ebp
  8007c0:	c3                   	ret    

008007c1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007c1:	55                   	push   %ebp
  8007c2:	89 e5                	mov    %esp,%ebp
  8007c4:	83 ec 28             	sub    $0x28,%esp
  8007c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ca:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007d0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007d4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007d7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007de:	85 d2                	test   %edx,%edx
  8007e0:	7e 30                	jle    800812 <vsnprintf+0x51>
  8007e2:	85 c0                	test   %eax,%eax
  8007e4:	74 2c                	je     800812 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8007e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007ed:	8b 45 10             	mov    0x10(%ebp),%eax
  8007f0:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007f4:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007f7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007fb:	c7 04 24 7d 03 80 00 	movl   $0x80037d,(%esp)
  800802:	e8 bb fb ff ff       	call   8003c2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800807:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80080a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80080d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800810:	eb 05                	jmp    800817 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800812:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800817:	c9                   	leave  
  800818:	c3                   	ret    

00800819 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800819:	55                   	push   %ebp
  80081a:	89 e5                	mov    %esp,%ebp
  80081c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80081f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800822:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800826:	8b 45 10             	mov    0x10(%ebp),%eax
  800829:	89 44 24 08          	mov    %eax,0x8(%esp)
  80082d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800830:	89 44 24 04          	mov    %eax,0x4(%esp)
  800834:	8b 45 08             	mov    0x8(%ebp),%eax
  800837:	89 04 24             	mov    %eax,(%esp)
  80083a:	e8 82 ff ff ff       	call   8007c1 <vsnprintf>
	va_end(ap);

	return rc;
}
  80083f:	c9                   	leave  
  800840:	c3                   	ret    
  800841:	66 90                	xchg   %ax,%ax
  800843:	66 90                	xchg   %ax,%ax
  800845:	66 90                	xchg   %ax,%ax
  800847:	66 90                	xchg   %ax,%ax
  800849:	66 90                	xchg   %ax,%ax
  80084b:	66 90                	xchg   %ax,%ax
  80084d:	66 90                	xchg   %ax,%ax
  80084f:	90                   	nop

00800850 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800850:	55                   	push   %ebp
  800851:	89 e5                	mov    %esp,%ebp
  800853:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800856:	80 3a 00             	cmpb   $0x0,(%edx)
  800859:	74 10                	je     80086b <strlen+0x1b>
  80085b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800860:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800863:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800867:	75 f7                	jne    800860 <strlen+0x10>
  800869:	eb 05                	jmp    800870 <strlen+0x20>
  80086b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800870:	5d                   	pop    %ebp
  800871:	c3                   	ret    

00800872 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800872:	55                   	push   %ebp
  800873:	89 e5                	mov    %esp,%ebp
  800875:	53                   	push   %ebx
  800876:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800879:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80087c:	85 c9                	test   %ecx,%ecx
  80087e:	74 1c                	je     80089c <strnlen+0x2a>
  800880:	80 3b 00             	cmpb   $0x0,(%ebx)
  800883:	74 1e                	je     8008a3 <strnlen+0x31>
  800885:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80088a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80088c:	39 ca                	cmp    %ecx,%edx
  80088e:	74 18                	je     8008a8 <strnlen+0x36>
  800890:	83 c2 01             	add    $0x1,%edx
  800893:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800898:	75 f0                	jne    80088a <strnlen+0x18>
  80089a:	eb 0c                	jmp    8008a8 <strnlen+0x36>
  80089c:	b8 00 00 00 00       	mov    $0x0,%eax
  8008a1:	eb 05                	jmp    8008a8 <strnlen+0x36>
  8008a3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8008a8:	5b                   	pop    %ebx
  8008a9:	5d                   	pop    %ebp
  8008aa:	c3                   	ret    

008008ab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008ab:	55                   	push   %ebp
  8008ac:	89 e5                	mov    %esp,%ebp
  8008ae:	53                   	push   %ebx
  8008af:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008b5:	89 c2                	mov    %eax,%edx
  8008b7:	0f b6 19             	movzbl (%ecx),%ebx
  8008ba:	88 1a                	mov    %bl,(%edx)
  8008bc:	83 c2 01             	add    $0x1,%edx
  8008bf:	83 c1 01             	add    $0x1,%ecx
  8008c2:	84 db                	test   %bl,%bl
  8008c4:	75 f1                	jne    8008b7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008c6:	5b                   	pop    %ebx
  8008c7:	5d                   	pop    %ebp
  8008c8:	c3                   	ret    

008008c9 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008c9:	55                   	push   %ebp
  8008ca:	89 e5                	mov    %esp,%ebp
  8008cc:	53                   	push   %ebx
  8008cd:	83 ec 08             	sub    $0x8,%esp
  8008d0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008d3:	89 1c 24             	mov    %ebx,(%esp)
  8008d6:	e8 75 ff ff ff       	call   800850 <strlen>
	strcpy(dst + len, src);
  8008db:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008de:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008e2:	01 d8                	add    %ebx,%eax
  8008e4:	89 04 24             	mov    %eax,(%esp)
  8008e7:	e8 bf ff ff ff       	call   8008ab <strcpy>
	return dst;
}
  8008ec:	89 d8                	mov    %ebx,%eax
  8008ee:	83 c4 08             	add    $0x8,%esp
  8008f1:	5b                   	pop    %ebx
  8008f2:	5d                   	pop    %ebp
  8008f3:	c3                   	ret    

008008f4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008f4:	55                   	push   %ebp
  8008f5:	89 e5                	mov    %esp,%ebp
  8008f7:	56                   	push   %esi
  8008f8:	53                   	push   %ebx
  8008f9:	8b 75 08             	mov    0x8(%ebp),%esi
  8008fc:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008ff:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800902:	85 db                	test   %ebx,%ebx
  800904:	74 16                	je     80091c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800906:	01 f3                	add    %esi,%ebx
  800908:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  80090a:	0f b6 02             	movzbl (%edx),%eax
  80090d:	88 01                	mov    %al,(%ecx)
  80090f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800912:	80 3a 01             	cmpb   $0x1,(%edx)
  800915:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800918:	39 d9                	cmp    %ebx,%ecx
  80091a:	75 ee                	jne    80090a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80091c:	89 f0                	mov    %esi,%eax
  80091e:	5b                   	pop    %ebx
  80091f:	5e                   	pop    %esi
  800920:	5d                   	pop    %ebp
  800921:	c3                   	ret    

00800922 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800922:	55                   	push   %ebp
  800923:	89 e5                	mov    %esp,%ebp
  800925:	57                   	push   %edi
  800926:	56                   	push   %esi
  800927:	53                   	push   %ebx
  800928:	8b 7d 08             	mov    0x8(%ebp),%edi
  80092b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80092e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800931:	89 f8                	mov    %edi,%eax
  800933:	85 f6                	test   %esi,%esi
  800935:	74 33                	je     80096a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800937:	83 fe 01             	cmp    $0x1,%esi
  80093a:	74 25                	je     800961 <strlcpy+0x3f>
  80093c:	0f b6 0b             	movzbl (%ebx),%ecx
  80093f:	84 c9                	test   %cl,%cl
  800941:	74 22                	je     800965 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800943:	83 ee 02             	sub    $0x2,%esi
  800946:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80094b:	88 08                	mov    %cl,(%eax)
  80094d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800950:	39 f2                	cmp    %esi,%edx
  800952:	74 13                	je     800967 <strlcpy+0x45>
  800954:	83 c2 01             	add    $0x1,%edx
  800957:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80095b:	84 c9                	test   %cl,%cl
  80095d:	75 ec                	jne    80094b <strlcpy+0x29>
  80095f:	eb 06                	jmp    800967 <strlcpy+0x45>
  800961:	89 f8                	mov    %edi,%eax
  800963:	eb 02                	jmp    800967 <strlcpy+0x45>
  800965:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800967:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80096a:	29 f8                	sub    %edi,%eax
}
  80096c:	5b                   	pop    %ebx
  80096d:	5e                   	pop    %esi
  80096e:	5f                   	pop    %edi
  80096f:	5d                   	pop    %ebp
  800970:	c3                   	ret    

00800971 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800971:	55                   	push   %ebp
  800972:	89 e5                	mov    %esp,%ebp
  800974:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800977:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80097a:	0f b6 01             	movzbl (%ecx),%eax
  80097d:	84 c0                	test   %al,%al
  80097f:	74 15                	je     800996 <strcmp+0x25>
  800981:	3a 02                	cmp    (%edx),%al
  800983:	75 11                	jne    800996 <strcmp+0x25>
		p++, q++;
  800985:	83 c1 01             	add    $0x1,%ecx
  800988:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80098b:	0f b6 01             	movzbl (%ecx),%eax
  80098e:	84 c0                	test   %al,%al
  800990:	74 04                	je     800996 <strcmp+0x25>
  800992:	3a 02                	cmp    (%edx),%al
  800994:	74 ef                	je     800985 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800996:	0f b6 c0             	movzbl %al,%eax
  800999:	0f b6 12             	movzbl (%edx),%edx
  80099c:	29 d0                	sub    %edx,%eax
}
  80099e:	5d                   	pop    %ebp
  80099f:	c3                   	ret    

008009a0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009a0:	55                   	push   %ebp
  8009a1:	89 e5                	mov    %esp,%ebp
  8009a3:	56                   	push   %esi
  8009a4:	53                   	push   %ebx
  8009a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8009a8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009ab:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  8009ae:	85 f6                	test   %esi,%esi
  8009b0:	74 29                	je     8009db <strncmp+0x3b>
  8009b2:	0f b6 03             	movzbl (%ebx),%eax
  8009b5:	84 c0                	test   %al,%al
  8009b7:	74 30                	je     8009e9 <strncmp+0x49>
  8009b9:	3a 02                	cmp    (%edx),%al
  8009bb:	75 2c                	jne    8009e9 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  8009bd:	8d 43 01             	lea    0x1(%ebx),%eax
  8009c0:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  8009c2:	89 c3                	mov    %eax,%ebx
  8009c4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009c7:	39 f0                	cmp    %esi,%eax
  8009c9:	74 17                	je     8009e2 <strncmp+0x42>
  8009cb:	0f b6 08             	movzbl (%eax),%ecx
  8009ce:	84 c9                	test   %cl,%cl
  8009d0:	74 17                	je     8009e9 <strncmp+0x49>
  8009d2:	83 c0 01             	add    $0x1,%eax
  8009d5:	3a 0a                	cmp    (%edx),%cl
  8009d7:	74 e9                	je     8009c2 <strncmp+0x22>
  8009d9:	eb 0e                	jmp    8009e9 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009db:	b8 00 00 00 00       	mov    $0x0,%eax
  8009e0:	eb 0f                	jmp    8009f1 <strncmp+0x51>
  8009e2:	b8 00 00 00 00       	mov    $0x0,%eax
  8009e7:	eb 08                	jmp    8009f1 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009e9:	0f b6 03             	movzbl (%ebx),%eax
  8009ec:	0f b6 12             	movzbl (%edx),%edx
  8009ef:	29 d0                	sub    %edx,%eax
}
  8009f1:	5b                   	pop    %ebx
  8009f2:	5e                   	pop    %esi
  8009f3:	5d                   	pop    %ebp
  8009f4:	c3                   	ret    

008009f5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009f5:	55                   	push   %ebp
  8009f6:	89 e5                	mov    %esp,%ebp
  8009f8:	53                   	push   %ebx
  8009f9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009fc:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  8009ff:	0f b6 18             	movzbl (%eax),%ebx
  800a02:	84 db                	test   %bl,%bl
  800a04:	74 1d                	je     800a23 <strchr+0x2e>
  800a06:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a08:	38 d3                	cmp    %dl,%bl
  800a0a:	75 06                	jne    800a12 <strchr+0x1d>
  800a0c:	eb 1a                	jmp    800a28 <strchr+0x33>
  800a0e:	38 ca                	cmp    %cl,%dl
  800a10:	74 16                	je     800a28 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a12:	83 c0 01             	add    $0x1,%eax
  800a15:	0f b6 10             	movzbl (%eax),%edx
  800a18:	84 d2                	test   %dl,%dl
  800a1a:	75 f2                	jne    800a0e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800a1c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a21:	eb 05                	jmp    800a28 <strchr+0x33>
  800a23:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a28:	5b                   	pop    %ebx
  800a29:	5d                   	pop    %ebp
  800a2a:	c3                   	ret    

00800a2b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a2b:	55                   	push   %ebp
  800a2c:	89 e5                	mov    %esp,%ebp
  800a2e:	53                   	push   %ebx
  800a2f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a32:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a35:	0f b6 18             	movzbl (%eax),%ebx
  800a38:	84 db                	test   %bl,%bl
  800a3a:	74 16                	je     800a52 <strfind+0x27>
  800a3c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a3e:	38 d3                	cmp    %dl,%bl
  800a40:	75 06                	jne    800a48 <strfind+0x1d>
  800a42:	eb 0e                	jmp    800a52 <strfind+0x27>
  800a44:	38 ca                	cmp    %cl,%dl
  800a46:	74 0a                	je     800a52 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800a48:	83 c0 01             	add    $0x1,%eax
  800a4b:	0f b6 10             	movzbl (%eax),%edx
  800a4e:	84 d2                	test   %dl,%dl
  800a50:	75 f2                	jne    800a44 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800a52:	5b                   	pop    %ebx
  800a53:	5d                   	pop    %ebp
  800a54:	c3                   	ret    

00800a55 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a55:	55                   	push   %ebp
  800a56:	89 e5                	mov    %esp,%ebp
  800a58:	83 ec 0c             	sub    $0xc,%esp
  800a5b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800a5e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a61:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a64:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a67:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a6a:	85 c9                	test   %ecx,%ecx
  800a6c:	74 36                	je     800aa4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a6e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a74:	75 28                	jne    800a9e <memset+0x49>
  800a76:	f6 c1 03             	test   $0x3,%cl
  800a79:	75 23                	jne    800a9e <memset+0x49>
		c &= 0xFF;
  800a7b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a7f:	89 d3                	mov    %edx,%ebx
  800a81:	c1 e3 08             	shl    $0x8,%ebx
  800a84:	89 d6                	mov    %edx,%esi
  800a86:	c1 e6 18             	shl    $0x18,%esi
  800a89:	89 d0                	mov    %edx,%eax
  800a8b:	c1 e0 10             	shl    $0x10,%eax
  800a8e:	09 f0                	or     %esi,%eax
  800a90:	09 c2                	or     %eax,%edx
  800a92:	89 d0                	mov    %edx,%eax
  800a94:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a96:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a99:	fc                   	cld    
  800a9a:	f3 ab                	rep stos %eax,%es:(%edi)
  800a9c:	eb 06                	jmp    800aa4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a9e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800aa1:	fc                   	cld    
  800aa2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800aa4:	89 f8                	mov    %edi,%eax
  800aa6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800aa9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800aac:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800aaf:	89 ec                	mov    %ebp,%esp
  800ab1:	5d                   	pop    %ebp
  800ab2:	c3                   	ret    

00800ab3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800ab3:	55                   	push   %ebp
  800ab4:	89 e5                	mov    %esp,%ebp
  800ab6:	83 ec 08             	sub    $0x8,%esp
  800ab9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800abc:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800abf:	8b 45 08             	mov    0x8(%ebp),%eax
  800ac2:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ac5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800ac8:	39 c6                	cmp    %eax,%esi
  800aca:	73 36                	jae    800b02 <memmove+0x4f>
  800acc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800acf:	39 d0                	cmp    %edx,%eax
  800ad1:	73 2f                	jae    800b02 <memmove+0x4f>
		s += n;
		d += n;
  800ad3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ad6:	f6 c2 03             	test   $0x3,%dl
  800ad9:	75 1b                	jne    800af6 <memmove+0x43>
  800adb:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800ae1:	75 13                	jne    800af6 <memmove+0x43>
  800ae3:	f6 c1 03             	test   $0x3,%cl
  800ae6:	75 0e                	jne    800af6 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800ae8:	83 ef 04             	sub    $0x4,%edi
  800aeb:	8d 72 fc             	lea    -0x4(%edx),%esi
  800aee:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800af1:	fd                   	std    
  800af2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800af4:	eb 09                	jmp    800aff <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800af6:	83 ef 01             	sub    $0x1,%edi
  800af9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800afc:	fd                   	std    
  800afd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800aff:	fc                   	cld    
  800b00:	eb 20                	jmp    800b22 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b02:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800b08:	75 13                	jne    800b1d <memmove+0x6a>
  800b0a:	a8 03                	test   $0x3,%al
  800b0c:	75 0f                	jne    800b1d <memmove+0x6a>
  800b0e:	f6 c1 03             	test   $0x3,%cl
  800b11:	75 0a                	jne    800b1d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800b13:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800b16:	89 c7                	mov    %eax,%edi
  800b18:	fc                   	cld    
  800b19:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b1b:	eb 05                	jmp    800b22 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b1d:	89 c7                	mov    %eax,%edi
  800b1f:	fc                   	cld    
  800b20:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b22:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b25:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b28:	89 ec                	mov    %ebp,%esp
  800b2a:	5d                   	pop    %ebp
  800b2b:	c3                   	ret    

00800b2c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800b2c:	55                   	push   %ebp
  800b2d:	89 e5                	mov    %esp,%ebp
  800b2f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800b32:	8b 45 10             	mov    0x10(%ebp),%eax
  800b35:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b39:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b3c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b40:	8b 45 08             	mov    0x8(%ebp),%eax
  800b43:	89 04 24             	mov    %eax,(%esp)
  800b46:	e8 68 ff ff ff       	call   800ab3 <memmove>
}
  800b4b:	c9                   	leave  
  800b4c:	c3                   	ret    

00800b4d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b4d:	55                   	push   %ebp
  800b4e:	89 e5                	mov    %esp,%ebp
  800b50:	57                   	push   %edi
  800b51:	56                   	push   %esi
  800b52:	53                   	push   %ebx
  800b53:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800b56:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b59:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b5c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800b5f:	85 c0                	test   %eax,%eax
  800b61:	74 36                	je     800b99 <memcmp+0x4c>
		if (*s1 != *s2)
  800b63:	0f b6 03             	movzbl (%ebx),%eax
  800b66:	0f b6 0e             	movzbl (%esi),%ecx
  800b69:	38 c8                	cmp    %cl,%al
  800b6b:	75 17                	jne    800b84 <memcmp+0x37>
  800b6d:	ba 00 00 00 00       	mov    $0x0,%edx
  800b72:	eb 1a                	jmp    800b8e <memcmp+0x41>
  800b74:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800b79:	83 c2 01             	add    $0x1,%edx
  800b7c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800b80:	38 c8                	cmp    %cl,%al
  800b82:	74 0a                	je     800b8e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800b84:	0f b6 c0             	movzbl %al,%eax
  800b87:	0f b6 c9             	movzbl %cl,%ecx
  800b8a:	29 c8                	sub    %ecx,%eax
  800b8c:	eb 10                	jmp    800b9e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b8e:	39 fa                	cmp    %edi,%edx
  800b90:	75 e2                	jne    800b74 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b92:	b8 00 00 00 00       	mov    $0x0,%eax
  800b97:	eb 05                	jmp    800b9e <memcmp+0x51>
  800b99:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b9e:	5b                   	pop    %ebx
  800b9f:	5e                   	pop    %esi
  800ba0:	5f                   	pop    %edi
  800ba1:	5d                   	pop    %ebp
  800ba2:	c3                   	ret    

00800ba3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ba3:	55                   	push   %ebp
  800ba4:	89 e5                	mov    %esp,%ebp
  800ba6:	53                   	push   %ebx
  800ba7:	8b 45 08             	mov    0x8(%ebp),%eax
  800baa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800bad:	89 c2                	mov    %eax,%edx
  800baf:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800bb2:	39 d0                	cmp    %edx,%eax
  800bb4:	73 13                	jae    800bc9 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800bb6:	89 d9                	mov    %ebx,%ecx
  800bb8:	38 18                	cmp    %bl,(%eax)
  800bba:	75 06                	jne    800bc2 <memfind+0x1f>
  800bbc:	eb 0b                	jmp    800bc9 <memfind+0x26>
  800bbe:	38 08                	cmp    %cl,(%eax)
  800bc0:	74 07                	je     800bc9 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800bc2:	83 c0 01             	add    $0x1,%eax
  800bc5:	39 d0                	cmp    %edx,%eax
  800bc7:	75 f5                	jne    800bbe <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800bc9:	5b                   	pop    %ebx
  800bca:	5d                   	pop    %ebp
  800bcb:	c3                   	ret    

00800bcc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800bcc:	55                   	push   %ebp
  800bcd:	89 e5                	mov    %esp,%ebp
  800bcf:	57                   	push   %edi
  800bd0:	56                   	push   %esi
  800bd1:	53                   	push   %ebx
  800bd2:	83 ec 04             	sub    $0x4,%esp
  800bd5:	8b 55 08             	mov    0x8(%ebp),%edx
  800bd8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800bdb:	0f b6 02             	movzbl (%edx),%eax
  800bde:	3c 09                	cmp    $0x9,%al
  800be0:	74 04                	je     800be6 <strtol+0x1a>
  800be2:	3c 20                	cmp    $0x20,%al
  800be4:	75 0e                	jne    800bf4 <strtol+0x28>
		s++;
  800be6:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800be9:	0f b6 02             	movzbl (%edx),%eax
  800bec:	3c 09                	cmp    $0x9,%al
  800bee:	74 f6                	je     800be6 <strtol+0x1a>
  800bf0:	3c 20                	cmp    $0x20,%al
  800bf2:	74 f2                	je     800be6 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800bf4:	3c 2b                	cmp    $0x2b,%al
  800bf6:	75 0a                	jne    800c02 <strtol+0x36>
		s++;
  800bf8:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800bfb:	bf 00 00 00 00       	mov    $0x0,%edi
  800c00:	eb 10                	jmp    800c12 <strtol+0x46>
  800c02:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c07:	3c 2d                	cmp    $0x2d,%al
  800c09:	75 07                	jne    800c12 <strtol+0x46>
		s++, neg = 1;
  800c0b:	83 c2 01             	add    $0x1,%edx
  800c0e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c12:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800c18:	75 15                	jne    800c2f <strtol+0x63>
  800c1a:	80 3a 30             	cmpb   $0x30,(%edx)
  800c1d:	75 10                	jne    800c2f <strtol+0x63>
  800c1f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800c23:	75 0a                	jne    800c2f <strtol+0x63>
		s += 2, base = 16;
  800c25:	83 c2 02             	add    $0x2,%edx
  800c28:	bb 10 00 00 00       	mov    $0x10,%ebx
  800c2d:	eb 10                	jmp    800c3f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800c2f:	85 db                	test   %ebx,%ebx
  800c31:	75 0c                	jne    800c3f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800c33:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c35:	80 3a 30             	cmpb   $0x30,(%edx)
  800c38:	75 05                	jne    800c3f <strtol+0x73>
		s++, base = 8;
  800c3a:	83 c2 01             	add    $0x1,%edx
  800c3d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800c3f:	b8 00 00 00 00       	mov    $0x0,%eax
  800c44:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800c47:	0f b6 0a             	movzbl (%edx),%ecx
  800c4a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800c4d:	89 f3                	mov    %esi,%ebx
  800c4f:	80 fb 09             	cmp    $0x9,%bl
  800c52:	77 08                	ja     800c5c <strtol+0x90>
			dig = *s - '0';
  800c54:	0f be c9             	movsbl %cl,%ecx
  800c57:	83 e9 30             	sub    $0x30,%ecx
  800c5a:	eb 22                	jmp    800c7e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800c5c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800c5f:	89 f3                	mov    %esi,%ebx
  800c61:	80 fb 19             	cmp    $0x19,%bl
  800c64:	77 08                	ja     800c6e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800c66:	0f be c9             	movsbl %cl,%ecx
  800c69:	83 e9 57             	sub    $0x57,%ecx
  800c6c:	eb 10                	jmp    800c7e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800c6e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800c71:	89 f3                	mov    %esi,%ebx
  800c73:	80 fb 19             	cmp    $0x19,%bl
  800c76:	77 16                	ja     800c8e <strtol+0xc2>
			dig = *s - 'A' + 10;
  800c78:	0f be c9             	movsbl %cl,%ecx
  800c7b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c7e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800c81:	7d 0f                	jge    800c92 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800c83:	83 c2 01             	add    $0x1,%edx
  800c86:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800c8a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800c8c:	eb b9                	jmp    800c47 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800c8e:	89 c1                	mov    %eax,%ecx
  800c90:	eb 02                	jmp    800c94 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800c92:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800c94:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c98:	74 05                	je     800c9f <strtol+0xd3>
		*endptr = (char *) s;
  800c9a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c9d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800c9f:	89 ca                	mov    %ecx,%edx
  800ca1:	f7 da                	neg    %edx
  800ca3:	85 ff                	test   %edi,%edi
  800ca5:	0f 45 c2             	cmovne %edx,%eax
}
  800ca8:	83 c4 04             	add    $0x4,%esp
  800cab:	5b                   	pop    %ebx
  800cac:	5e                   	pop    %esi
  800cad:	5f                   	pop    %edi
  800cae:	5d                   	pop    %ebp
  800caf:	c3                   	ret    

00800cb0 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800cb0:	55                   	push   %ebp
  800cb1:	89 e5                	mov    %esp,%ebp
  800cb3:	83 ec 0c             	sub    $0xc,%esp
  800cb6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800cb9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800cbc:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cbf:	b8 00 00 00 00       	mov    $0x0,%eax
  800cc4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cc7:	8b 55 08             	mov    0x8(%ebp),%edx
  800cca:	89 c3                	mov    %eax,%ebx
  800ccc:	89 c7                	mov    %eax,%edi
  800cce:	89 c6                	mov    %eax,%esi
  800cd0:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800cd2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800cd5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cd8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cdb:	89 ec                	mov    %ebp,%esp
  800cdd:	5d                   	pop    %ebp
  800cde:	c3                   	ret    

00800cdf <sys_cgetc>:

int
sys_cgetc(void)
{
  800cdf:	55                   	push   %ebp
  800ce0:	89 e5                	mov    %esp,%ebp
  800ce2:	83 ec 0c             	sub    $0xc,%esp
  800ce5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ce8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ceb:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cee:	ba 00 00 00 00       	mov    $0x0,%edx
  800cf3:	b8 01 00 00 00       	mov    $0x1,%eax
  800cf8:	89 d1                	mov    %edx,%ecx
  800cfa:	89 d3                	mov    %edx,%ebx
  800cfc:	89 d7                	mov    %edx,%edi
  800cfe:	89 d6                	mov    %edx,%esi
  800d00:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800d02:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d05:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d08:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d0b:	89 ec                	mov    %ebp,%esp
  800d0d:	5d                   	pop    %ebp
  800d0e:	c3                   	ret    

00800d0f <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800d0f:	55                   	push   %ebp
  800d10:	89 e5                	mov    %esp,%ebp
  800d12:	83 ec 38             	sub    $0x38,%esp
  800d15:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d18:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d1b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d1e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d23:	b8 03 00 00 00       	mov    $0x3,%eax
  800d28:	8b 55 08             	mov    0x8(%ebp),%edx
  800d2b:	89 cb                	mov    %ecx,%ebx
  800d2d:	89 cf                	mov    %ecx,%edi
  800d2f:	89 ce                	mov    %ecx,%esi
  800d31:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d33:	85 c0                	test   %eax,%eax
  800d35:	7e 28                	jle    800d5f <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d37:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d3b:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800d42:	00 
  800d43:	c7 44 24 08 24 1c 80 	movl   $0x801c24,0x8(%esp)
  800d4a:	00 
  800d4b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d52:	00 
  800d53:	c7 04 24 41 1c 80 00 	movl   $0x801c41,(%esp)
  800d5a:	e8 65 08 00 00       	call   8015c4 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800d5f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d62:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d65:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d68:	89 ec                	mov    %ebp,%esp
  800d6a:	5d                   	pop    %ebp
  800d6b:	c3                   	ret    

00800d6c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800d6c:	55                   	push   %ebp
  800d6d:	89 e5                	mov    %esp,%ebp
  800d6f:	83 ec 0c             	sub    $0xc,%esp
  800d72:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d75:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d78:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d7b:	ba 00 00 00 00       	mov    $0x0,%edx
  800d80:	b8 02 00 00 00       	mov    $0x2,%eax
  800d85:	89 d1                	mov    %edx,%ecx
  800d87:	89 d3                	mov    %edx,%ebx
  800d89:	89 d7                	mov    %edx,%edi
  800d8b:	89 d6                	mov    %edx,%esi
  800d8d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800d8f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d92:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d95:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d98:	89 ec                	mov    %ebp,%esp
  800d9a:	5d                   	pop    %ebp
  800d9b:	c3                   	ret    

00800d9c <sys_yield>:

void
sys_yield(void)
{
  800d9c:	55                   	push   %ebp
  800d9d:	89 e5                	mov    %esp,%ebp
  800d9f:	83 ec 0c             	sub    $0xc,%esp
  800da2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800da5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800da8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dab:	ba 00 00 00 00       	mov    $0x0,%edx
  800db0:	b8 0a 00 00 00       	mov    $0xa,%eax
  800db5:	89 d1                	mov    %edx,%ecx
  800db7:	89 d3                	mov    %edx,%ebx
  800db9:	89 d7                	mov    %edx,%edi
  800dbb:	89 d6                	mov    %edx,%esi
  800dbd:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800dbf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800dc2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800dc5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800dc8:	89 ec                	mov    %ebp,%esp
  800dca:	5d                   	pop    %ebp
  800dcb:	c3                   	ret    

00800dcc <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800dcc:	55                   	push   %ebp
  800dcd:	89 e5                	mov    %esp,%ebp
  800dcf:	83 ec 38             	sub    $0x38,%esp
  800dd2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800dd5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800dd8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ddb:	be 00 00 00 00       	mov    $0x0,%esi
  800de0:	b8 04 00 00 00       	mov    $0x4,%eax
  800de5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800de8:	8b 55 08             	mov    0x8(%ebp),%edx
  800deb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800dee:	89 f7                	mov    %esi,%edi
  800df0:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800df2:	85 c0                	test   %eax,%eax
  800df4:	7e 28                	jle    800e1e <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  800df6:	89 44 24 10          	mov    %eax,0x10(%esp)
  800dfa:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800e01:	00 
  800e02:	c7 44 24 08 24 1c 80 	movl   $0x801c24,0x8(%esp)
  800e09:	00 
  800e0a:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e11:	00 
  800e12:	c7 04 24 41 1c 80 00 	movl   $0x801c41,(%esp)
  800e19:	e8 a6 07 00 00       	call   8015c4 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800e1e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e21:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e24:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e27:	89 ec                	mov    %ebp,%esp
  800e29:	5d                   	pop    %ebp
  800e2a:	c3                   	ret    

00800e2b <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800e2b:	55                   	push   %ebp
  800e2c:	89 e5                	mov    %esp,%ebp
  800e2e:	83 ec 38             	sub    $0x38,%esp
  800e31:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e34:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e37:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e3a:	b8 05 00 00 00       	mov    $0x5,%eax
  800e3f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e42:	8b 55 08             	mov    0x8(%ebp),%edx
  800e45:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e48:	8b 7d 14             	mov    0x14(%ebp),%edi
  800e4b:	8b 75 18             	mov    0x18(%ebp),%esi
  800e4e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e50:	85 c0                	test   %eax,%eax
  800e52:	7e 28                	jle    800e7c <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e54:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e58:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800e5f:	00 
  800e60:	c7 44 24 08 24 1c 80 	movl   $0x801c24,0x8(%esp)
  800e67:	00 
  800e68:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e6f:	00 
  800e70:	c7 04 24 41 1c 80 00 	movl   $0x801c41,(%esp)
  800e77:	e8 48 07 00 00       	call   8015c4 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800e7c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e7f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e82:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e85:	89 ec                	mov    %ebp,%esp
  800e87:	5d                   	pop    %ebp
  800e88:	c3                   	ret    

00800e89 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800e89:	55                   	push   %ebp
  800e8a:	89 e5                	mov    %esp,%ebp
  800e8c:	83 ec 38             	sub    $0x38,%esp
  800e8f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e92:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e95:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e98:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e9d:	b8 06 00 00 00       	mov    $0x6,%eax
  800ea2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ea5:	8b 55 08             	mov    0x8(%ebp),%edx
  800ea8:	89 df                	mov    %ebx,%edi
  800eaa:	89 de                	mov    %ebx,%esi
  800eac:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800eae:	85 c0                	test   %eax,%eax
  800eb0:	7e 28                	jle    800eda <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800eb2:	89 44 24 10          	mov    %eax,0x10(%esp)
  800eb6:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800ebd:	00 
  800ebe:	c7 44 24 08 24 1c 80 	movl   $0x801c24,0x8(%esp)
  800ec5:	00 
  800ec6:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ecd:	00 
  800ece:	c7 04 24 41 1c 80 00 	movl   $0x801c41,(%esp)
  800ed5:	e8 ea 06 00 00       	call   8015c4 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800eda:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800edd:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ee0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ee3:	89 ec                	mov    %ebp,%esp
  800ee5:	5d                   	pop    %ebp
  800ee6:	c3                   	ret    

00800ee7 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800ee7:	55                   	push   %ebp
  800ee8:	89 e5                	mov    %esp,%ebp
  800eea:	83 ec 38             	sub    $0x38,%esp
  800eed:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ef0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ef3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ef6:	bb 00 00 00 00       	mov    $0x0,%ebx
  800efb:	b8 08 00 00 00       	mov    $0x8,%eax
  800f00:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f03:	8b 55 08             	mov    0x8(%ebp),%edx
  800f06:	89 df                	mov    %ebx,%edi
  800f08:	89 de                	mov    %ebx,%esi
  800f0a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f0c:	85 c0                	test   %eax,%eax
  800f0e:	7e 28                	jle    800f38 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f10:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f14:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800f1b:	00 
  800f1c:	c7 44 24 08 24 1c 80 	movl   $0x801c24,0x8(%esp)
  800f23:	00 
  800f24:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f2b:	00 
  800f2c:	c7 04 24 41 1c 80 00 	movl   $0x801c41,(%esp)
  800f33:	e8 8c 06 00 00       	call   8015c4 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800f38:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f3b:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f3e:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f41:	89 ec                	mov    %ebp,%esp
  800f43:	5d                   	pop    %ebp
  800f44:	c3                   	ret    

00800f45 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800f45:	55                   	push   %ebp
  800f46:	89 e5                	mov    %esp,%ebp
  800f48:	83 ec 38             	sub    $0x38,%esp
  800f4b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f4e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f51:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f54:	bb 00 00 00 00       	mov    $0x0,%ebx
  800f59:	b8 09 00 00 00       	mov    $0x9,%eax
  800f5e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f61:	8b 55 08             	mov    0x8(%ebp),%edx
  800f64:	89 df                	mov    %ebx,%edi
  800f66:	89 de                	mov    %ebx,%esi
  800f68:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f6a:	85 c0                	test   %eax,%eax
  800f6c:	7e 28                	jle    800f96 <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f6e:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f72:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800f79:	00 
  800f7a:	c7 44 24 08 24 1c 80 	movl   $0x801c24,0x8(%esp)
  800f81:	00 
  800f82:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f89:	00 
  800f8a:	c7 04 24 41 1c 80 00 	movl   $0x801c41,(%esp)
  800f91:	e8 2e 06 00 00       	call   8015c4 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800f96:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f99:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f9c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f9f:	89 ec                	mov    %ebp,%esp
  800fa1:	5d                   	pop    %ebp
  800fa2:	c3                   	ret    

00800fa3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800fa3:	55                   	push   %ebp
  800fa4:	89 e5                	mov    %esp,%ebp
  800fa6:	83 ec 0c             	sub    $0xc,%esp
  800fa9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800fac:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800faf:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800fb2:	be 00 00 00 00       	mov    $0x0,%esi
  800fb7:	b8 0b 00 00 00       	mov    $0xb,%eax
  800fbc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800fbf:	8b 55 08             	mov    0x8(%ebp),%edx
  800fc2:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800fc5:	8b 7d 14             	mov    0x14(%ebp),%edi
  800fc8:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800fca:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800fcd:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800fd0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800fd3:	89 ec                	mov    %ebp,%esp
  800fd5:	5d                   	pop    %ebp
  800fd6:	c3                   	ret    

00800fd7 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800fd7:	55                   	push   %ebp
  800fd8:	89 e5                	mov    %esp,%ebp
  800fda:	83 ec 38             	sub    $0x38,%esp
  800fdd:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800fe0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800fe3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800fe6:	b9 00 00 00 00       	mov    $0x0,%ecx
  800feb:	b8 0c 00 00 00       	mov    $0xc,%eax
  800ff0:	8b 55 08             	mov    0x8(%ebp),%edx
  800ff3:	89 cb                	mov    %ecx,%ebx
  800ff5:	89 cf                	mov    %ecx,%edi
  800ff7:	89 ce                	mov    %ecx,%esi
  800ff9:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ffb:	85 c0                	test   %eax,%eax
  800ffd:	7e 28                	jle    801027 <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800fff:	89 44 24 10          	mov    %eax,0x10(%esp)
  801003:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  80100a:	00 
  80100b:	c7 44 24 08 24 1c 80 	movl   $0x801c24,0x8(%esp)
  801012:	00 
  801013:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80101a:	00 
  80101b:	c7 04 24 41 1c 80 00 	movl   $0x801c41,(%esp)
  801022:	e8 9d 05 00 00       	call   8015c4 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  801027:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80102a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80102d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801030:	89 ec                	mov    %ebp,%esp
  801032:	5d                   	pop    %ebp
  801033:	c3                   	ret    

00801034 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  801034:	55                   	push   %ebp
  801035:	89 e5                	mov    %esp,%ebp
  801037:	53                   	push   %ebx
  801038:	83 ec 24             	sub    $0x24,%esp
  80103b:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void *) utf->utf_fault_va;
  80103e:	8b 18                	mov    (%eax),%ebx
	// Hint:
	//   Use the read-only page table mappings at vpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if(!((err & FEC_WR) && (vpd[PDX(addr)]&PTE_P) && (vpt[PGNUM(addr)]&PTE_COW) ))
  801040:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  801044:	74 21                	je     801067 <pgfault+0x33>
  801046:	89 d8                	mov    %ebx,%eax
  801048:	c1 e8 16             	shr    $0x16,%eax
  80104b:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  801052:	a8 01                	test   $0x1,%al
  801054:	74 11                	je     801067 <pgfault+0x33>
  801056:	89 d8                	mov    %ebx,%eax
  801058:	c1 e8 0c             	shr    $0xc,%eax
  80105b:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  801062:	f6 c4 08             	test   $0x8,%ah
  801065:	75 1c                	jne    801083 <pgfault+0x4f>
		panic("Invalid fault address!\n");
  801067:	c7 44 24 08 4f 1c 80 	movl   $0x801c4f,0x8(%esp)
  80106e:	00 
  80106f:	c7 44 24 04 1e 00 00 	movl   $0x1e,0x4(%esp)
  801076:	00 
  801077:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  80107e:	e8 41 05 00 00       	call   8015c4 <_panic>
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
	if((r = sys_page_alloc(0, (void *)PFTEMP, PTE_W|PTE_P|PTE_U)))
  801083:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  80108a:	00 
  80108b:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  801092:	00 
  801093:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80109a:	e8 2d fd ff ff       	call   800dcc <sys_page_alloc>
  80109f:	85 c0                	test   %eax,%eax
  8010a1:	74 20                	je     8010c3 <pgfault+0x8f>
		panic("Alloc page error: %e", r);
  8010a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8010a7:	c7 44 24 08 72 1c 80 	movl   $0x801c72,0x8(%esp)
  8010ae:	00 
  8010af:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
  8010b6:	00 
  8010b7:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  8010be:	e8 01 05 00 00       	call   8015c4 <_panic>
	addr = ROUNDDOWN(addr, PGSIZE);
  8010c3:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	memmove((void *)PFTEMP, addr, PGSIZE);
  8010c9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  8010d0:	00 
  8010d1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8010d5:	c7 04 24 00 f0 7f 00 	movl   $0x7ff000,(%esp)
  8010dc:	e8 d2 f9 ff ff       	call   800ab3 <memmove>
	sys_page_map(0, (void *)PFTEMP, 0, addr, PTE_W|PTE_P|PTE_U);
  8010e1:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  8010e8:	00 
  8010e9:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8010ed:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8010f4:	00 
  8010f5:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  8010fc:	00 
  8010fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801104:	e8 22 fd ff ff       	call   800e2b <sys_page_map>

	//panic("pgfault not implemented");
}
  801109:	83 c4 24             	add    $0x24,%esp
  80110c:	5b                   	pop    %ebx
  80110d:	5d                   	pop    %ebp
  80110e:	c3                   	ret    

0080110f <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  80110f:	55                   	push   %ebp
  801110:	89 e5                	mov    %esp,%ebp
  801112:	57                   	push   %edi
  801113:	56                   	push   %esi
  801114:	53                   	push   %ebx
  801115:	83 ec 3c             	sub    $0x3c,%esp
	// LAB 4: Your code here.
	envid_t ch_id;
	uint32_t cow_pg_ptr;
	int r;

	set_pgfault_handler(pgfault);
  801118:	c7 04 24 34 10 80 00 	movl   $0x801034,(%esp)
  80111f:	e8 10 05 00 00       	call   801634 <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  801124:	ba 07 00 00 00       	mov    $0x7,%edx
  801129:	89 d0                	mov    %edx,%eax
  80112b:	cd 30                	int    $0x30
  80112d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	if((ch_id = sys_exofork()) < 0)
  801130:	85 c0                	test   %eax,%eax
  801132:	79 1c                	jns    801150 <fork+0x41>
		panic("Fork error\n");
  801134:	c7 44 24 08 87 1c 80 	movl   $0x801c87,0x8(%esp)
  80113b:	00 
  80113c:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  801143:	00 
  801144:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  80114b:	e8 74 04 00 00       	call   8015c4 <_panic>
  801150:	89 c7                	mov    %eax,%edi
	if(ch_id == 0){ /* the child process */
  801152:	bb 00 00 80 00       	mov    $0x800000,%ebx
  801157:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80115b:	75 1c                	jne    801179 <fork+0x6a>
		thisenv =  &envs[ENVX(sys_getenvid())];
  80115d:	e8 0a fc ff ff       	call   800d6c <sys_getenvid>
  801162:	25 ff 03 00 00       	and    $0x3ff,%eax
  801167:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80116a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80116f:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  801174:	e9 98 01 00 00       	jmp    801311 <fork+0x202>
	}
	for(cow_pg_ptr = UTEXT; cow_pg_ptr < UXSTACKTOP - PGSIZE; cow_pg_ptr += PGSIZE){
		if ((vpd[PDX(cow_pg_ptr)] & PTE_P) && (vpt[PGNUM(cow_pg_ptr)] & (PTE_P|PTE_U))) 
  801179:	89 d8                	mov    %ebx,%eax
  80117b:	c1 e8 16             	shr    $0x16,%eax
  80117e:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  801185:	a8 01                	test   $0x1,%al
  801187:	0f 84 0d 01 00 00    	je     80129a <fork+0x18b>
  80118d:	89 d8                	mov    %ebx,%eax
  80118f:	c1 e8 0c             	shr    $0xc,%eax
  801192:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  801199:	f6 c2 05             	test   $0x5,%dl
  80119c:	0f 84 f8 00 00 00    	je     80129a <fork+0x18b>
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	if((vpd[PDX(pn*PGSIZE)]&PTE_P) && (vpt[pn]&(PTE_COW|PTE_W))){
  8011a2:	89 c6                	mov    %eax,%esi
  8011a4:	c1 e6 0c             	shl    $0xc,%esi
  8011a7:	89 f2                	mov    %esi,%edx
  8011a9:	c1 ea 16             	shr    $0x16,%edx
  8011ac:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  8011b3:	f6 c2 01             	test   $0x1,%dl
  8011b6:	0f 84 9a 00 00 00    	je     801256 <fork+0x147>
  8011bc:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  8011c3:	a9 02 08 00 00       	test   $0x802,%eax
  8011c8:	0f 84 88 00 00 00    	je     801256 <fork+0x147>
		if((r = sys_page_map(0, (void *)(pn*PGSIZE), envid, (void *)(pn*PGSIZE), PTE_P|PTE_COW|PTE_U)))
  8011ce:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  8011d5:	00 
  8011d6:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8011da:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8011de:	89 74 24 04          	mov    %esi,0x4(%esp)
  8011e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8011e9:	e8 3d fc ff ff       	call   800e2b <sys_page_map>
  8011ee:	85 c0                	test   %eax,%eax
  8011f0:	74 20                	je     801212 <fork+0x103>
			panic("Map page for child procesee failed: %e\n", r);
  8011f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8011f6:	c7 44 24 08 e0 1c 80 	movl   $0x801ce0,0x8(%esp)
  8011fd:	00 
  8011fe:	c7 44 24 04 44 00 00 	movl   $0x44,0x4(%esp)
  801205:	00 
  801206:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  80120d:	e8 b2 03 00 00       	call   8015c4 <_panic>
		if((r = sys_page_map(envid, (void *)(pn*PGSIZE), 0, (void *)(pn*PGSIZE), PTE_P|PTE_COW|PTE_U)))
  801212:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  801219:	00 
  80121a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80121e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801225:	00 
  801226:	89 74 24 04          	mov    %esi,0x4(%esp)
  80122a:	89 3c 24             	mov    %edi,(%esp)
  80122d:	e8 f9 fb ff ff       	call   800e2b <sys_page_map>
  801232:	85 c0                	test   %eax,%eax
  801234:	74 64                	je     80129a <fork+0x18b>
			panic("Map page for child procesee failed: %e\n", r);
  801236:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80123a:	c7 44 24 08 e0 1c 80 	movl   $0x801ce0,0x8(%esp)
  801241:	00 
  801242:	c7 44 24 04 46 00 00 	movl   $0x46,0x4(%esp)
  801249:	00 
  80124a:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  801251:	e8 6e 03 00 00       	call   8015c4 <_panic>
	}else
		if((r = sys_page_map(0, (void *)(pn*PGSIZE), envid, (void *)(pn*PGSIZE), PTE_P|PTE_U)))
  801256:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
  80125d:	00 
  80125e:	89 74 24 0c          	mov    %esi,0xc(%esp)
  801262:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801266:	89 74 24 04          	mov    %esi,0x4(%esp)
  80126a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801271:	e8 b5 fb ff ff       	call   800e2b <sys_page_map>
  801276:	85 c0                	test   %eax,%eax
  801278:	74 20                	je     80129a <fork+0x18b>
			panic("Map page for child procesee failed: %e\n", r);
  80127a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80127e:	c7 44 24 08 e0 1c 80 	movl   $0x801ce0,0x8(%esp)
  801285:	00 
  801286:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
  80128d:	00 
  80128e:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  801295:	e8 2a 03 00 00       	call   8015c4 <_panic>
		panic("Fork error\n");
	if(ch_id == 0){ /* the child process */
		thisenv =  &envs[ENVX(sys_getenvid())];
		return 0;
	}
	for(cow_pg_ptr = UTEXT; cow_pg_ptr < UXSTACKTOP - PGSIZE; cow_pg_ptr += PGSIZE){
  80129a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  8012a0:	81 fb 00 f0 bf ee    	cmp    $0xeebff000,%ebx
  8012a6:	0f 85 cd fe ff ff    	jne    801179 <fork+0x6a>
		if ((vpd[PDX(cow_pg_ptr)] & PTE_P) && (vpt[PGNUM(cow_pg_ptr)] & (PTE_P|PTE_U))) 
			duppage(ch_id, PGNUM(cow_pg_ptr));
	}

	if((r = sys_page_alloc(ch_id, (void *)(UXSTACKTOP - PGSIZE), PTE_U|PTE_P|PTE_W)))
  8012ac:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8012b3:	00 
  8012b4:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  8012bb:	ee 
  8012bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8012bf:	89 04 24             	mov    %eax,(%esp)
  8012c2:	e8 05 fb ff ff       	call   800dcc <sys_page_alloc>
  8012c7:	85 c0                	test   %eax,%eax
  8012c9:	74 20                	je     8012eb <fork+0x1dc>
		panic("Alloc exception stack error: %e\n", r);
  8012cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012cf:	c7 44 24 08 08 1d 80 	movl   $0x801d08,0x8(%esp)
  8012d6:	00 
  8012d7:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  8012de:	00 
  8012df:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  8012e6:	e8 d9 02 00 00       	call   8015c4 <_panic>

	extern void _pgfault_upcall(void);
	sys_env_set_pgfault_upcall(ch_id, _pgfault_upcall);
  8012eb:	c7 44 24 04 a4 16 80 	movl   $0x8016a4,0x4(%esp)
  8012f2:	00 
  8012f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8012f6:	89 04 24             	mov    %eax,(%esp)
  8012f9:	e8 47 fc ff ff       	call   800f45 <sys_env_set_pgfault_upcall>

	sys_env_set_status(ch_id, ENV_RUNNABLE);
  8012fe:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  801305:	00 
  801306:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801309:	89 04 24             	mov    %eax,(%esp)
  80130c:	e8 d6 fb ff ff       	call   800ee7 <sys_env_set_status>
	return ch_id;
	//panic("fork not implemented");
}
  801311:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801314:	83 c4 3c             	add    $0x3c,%esp
  801317:	5b                   	pop    %ebx
  801318:	5e                   	pop    %esi
  801319:	5f                   	pop    %edi
  80131a:	5d                   	pop    %ebp
  80131b:	c3                   	ret    

0080131c <sfork>:

// Challenge!
int
sfork(void)
{
  80131c:	55                   	push   %ebp
  80131d:	89 e5                	mov    %esp,%ebp
  80131f:	57                   	push   %edi
  801320:	56                   	push   %esi
  801321:	53                   	push   %ebx
  801322:	83 ec 3c             	sub    $0x3c,%esp
	set_pgfault_handler (pgfault);
  801325:	c7 04 24 34 10 80 00 	movl   $0x801034,(%esp)
  80132c:	e8 03 03 00 00       	call   801634 <set_pgfault_handler>
  801331:	ba 07 00 00 00       	mov    $0x7,%edx
  801336:	89 d0                	mov    %edx,%eax
  801338:	cd 30                	int    $0x30
  80133a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80133d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	envid_t envid;
	uint32_t i;
	int r;
	envid = sys_exofork();
	
	if(envid < 0)
  801340:	85 c0                	test   %eax,%eax
  801342:	79 20                	jns    801364 <sfork+0x48>
		panic("sys_exofork: %e", envid);
  801344:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801348:	c7 44 24 08 93 1c 80 	movl   $0x801c93,0x8(%esp)
  80134f:	00 
  801350:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
  801357:	00 
  801358:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  80135f:	e8 60 02 00 00       	call   8015c4 <_panic>
		
	if(envid == 0){
  801364:	be 01 00 00 00       	mov    $0x1,%esi
  801369:	bb 00 d0 bf ee       	mov    $0xeebfd000,%ebx
  80136e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  801372:	75 1c                	jne    801390 <sfork+0x74>
		thisenv = &envs[ENVX(sys_getenvid())];
  801374:	e8 f3 f9 ff ff       	call   800d6c <sys_getenvid>
  801379:	25 ff 03 00 00       	and    $0x3ff,%eax
  80137e:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801381:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  801386:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  80138b:	e9 26 02 00 00       	jmp    8015b6 <sfork+0x29a>
	}
	
	int instack = 1;
	for(i = USTACKTOP - PGSIZE; i >= UTEXT; i -= PGSIZE){
		if((vpd[PDX(i)] & PTE_P) > 0 && (vpt[PGNUM(i)] & PTE_P) > 0 && (vpt[PGNUM(i)] & PTE_U) > 0)
  801390:	89 d8                	mov    %ebx,%eax
  801392:	c1 e8 16             	shr    $0x16,%eax
  801395:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  80139c:	a8 01                	test   $0x1,%al
  80139e:	0f 84 64 01 00 00    	je     801508 <sfork+0x1ec>
  8013a4:	89 df                	mov    %ebx,%edi
  8013a6:	c1 ef 0c             	shr    $0xc,%edi
  8013a9:	8b 04 bd 00 00 40 ef 	mov    -0x10c00000(,%edi,4),%eax
  8013b0:	a8 01                	test   $0x1,%al
  8013b2:	0f 84 57 01 00 00    	je     80150f <sfork+0x1f3>
  8013b8:	8b 04 bd 00 00 40 ef 	mov    -0x10c00000(,%edi,4),%eax
  8013bf:	a8 04                	test   $0x4,%al
  8013c1:	0f 84 4f 01 00 00    	je     801516 <sfork+0x1fa>

static int
sduppage(envid_t envid, unsigned pn, int use_cow)
{
	int r;
	void *i = (void *) ((uint32_t) pn * PGSIZE);
  8013c7:	c1 e7 0c             	shl    $0xc,%edi
	pte_t pte = vpt[PGNUM(i)];
  8013ca:	89 f8                	mov    %edi,%eax
  8013cc:	c1 e8 0c             	shr    $0xc,%eax
  8013cf:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax

	if (use_cow || (pte & PTE_COW) > 0) {
  8013d6:	85 f6                	test   %esi,%esi
  8013d8:	75 09                	jne    8013e3 <sfork+0xc7>
  8013da:	f6 c4 08             	test   $0x8,%ah
  8013dd:	0f 84 93 00 00 00    	je     801476 <sfork+0x15a>
		if((r = sys_page_map(0, i, envid, i, PTE_U|PTE_P|PTE_COW))<0)
  8013e3:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  8013ea:	00 
  8013eb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8013ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8013f2:	89 44 24 08          	mov    %eax,0x8(%esp)
  8013f6:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8013fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801401:	e8 25 fa ff ff       	call   800e2b <sys_page_map>
  801406:	85 c0                	test   %eax,%eax
  801408:	79 20                	jns    80142a <sfork+0x10e>
			panic("sduppage: page map failed: %e",r);
  80140a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80140e:	c7 44 24 08 a3 1c 80 	movl   $0x801ca3,0x8(%esp)
  801415:	00 
  801416:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  80141d:	00 
  80141e:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  801425:	e8 9a 01 00 00       	call   8015c4 <_panic>
		
		if((r = sys_page_map(0, i, 0, i, PTE_U|PTE_P|PTE_COW)) < 0)
  80142a:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  801431:	00 
  801432:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801436:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80143d:	00 
  80143e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  801442:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801449:	e8 dd f9 ff ff       	call   800e2b <sys_page_map>
  80144e:	85 c0                	test   %eax,%eax
  801450:	0f 89 c5 00 00 00    	jns    80151b <sfork+0x1ff>
			panic("sduppage: page map failed: %e",r);
  801456:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80145a:	c7 44 24 08 a3 1c 80 	movl   $0x801ca3,0x8(%esp)
  801461:	00 
  801462:	c7 44 24 04 b1 00 00 	movl   $0xb1,0x4(%esp)
  801469:	00 
  80146a:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  801471:	e8 4e 01 00 00       	call   8015c4 <_panic>
	} else if((pte & PTE_W) > 0){
  801476:	a8 02                	test   $0x2,%al
  801478:	74 47                	je     8014c1 <sfork+0x1a5>
		if((r = sys_page_map(0, i, envid, i, PTE_U|PTE_P|PTE_W)) < 0)
  80147a:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  801481:	00 
  801482:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801486:	8b 45 e0             	mov    -0x20(%ebp),%eax
  801489:	89 44 24 08          	mov    %eax,0x8(%esp)
  80148d:	89 7c 24 04          	mov    %edi,0x4(%esp)
  801491:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801498:	e8 8e f9 ff ff       	call   800e2b <sys_page_map>
  80149d:	85 c0                	test   %eax,%eax
  80149f:	79 7a                	jns    80151b <sfork+0x1ff>
			panic("sduppage: page map failed: %e",r);
  8014a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8014a5:	c7 44 24 08 a3 1c 80 	movl   $0x801ca3,0x8(%esp)
  8014ac:	00 
  8014ad:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  8014b4:	00 
  8014b5:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  8014bc:	e8 03 01 00 00       	call   8015c4 <_panic>
	} else{
		if((r = sys_page_map(0, i, envid, i, PTE_U|PTE_P)) < 0)
  8014c1:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
  8014c8:	00 
  8014c9:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8014cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8014d0:	89 44 24 08          	mov    %eax,0x8(%esp)
  8014d4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8014d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8014df:	e8 47 f9 ff ff       	call   800e2b <sys_page_map>
  8014e4:	85 c0                	test   %eax,%eax
  8014e6:	79 33                	jns    80151b <sfork+0x1ff>
			panic("sduppage: page map failed: %e",r);
  8014e8:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8014ec:	c7 44 24 08 a3 1c 80 	movl   $0x801ca3,0x8(%esp)
  8014f3:	00 
  8014f4:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  8014fb:	00 
  8014fc:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  801503:	e8 bc 00 00 00       	call   8015c4 <_panic>
	int instack = 1;
	for(i = USTACKTOP - PGSIZE; i >= UTEXT; i -= PGSIZE){
		if((vpd[PDX(i)] & PTE_P) > 0 && (vpt[PGNUM(i)] & PTE_P) > 0 && (vpt[PGNUM(i)] & PTE_U) > 0)
			sduppage(envid, PGNUM(i), instack);
		else
			instack = 0;
  801508:	be 00 00 00 00       	mov    $0x0,%esi
  80150d:	eb 0c                	jmp    80151b <sfork+0x1ff>
  80150f:	be 00 00 00 00       	mov    $0x0,%esi
  801514:	eb 05                	jmp    80151b <sfork+0x1ff>
  801516:	be 00 00 00 00       	mov    $0x0,%esi
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	
	int instack = 1;
	for(i = USTACKTOP - PGSIZE; i >= UTEXT; i -= PGSIZE){
  80151b:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  801521:	81 fb 00 f0 7f 00    	cmp    $0x7ff000,%ebx
  801527:	0f 85 63 fe ff ff    	jne    801390 <sfork+0x74>
			sduppage(envid, PGNUM(i), instack);
		else
			instack = 0;
	}
	
	if((r = sys_page_alloc(envid, (void *)(UXSTACKTOP- PGSIZE), PTE_U|PTE_W|PTE_P)) < 0)
  80152d:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801534:	00 
  801535:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  80153c:	ee 
  80153d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801540:	89 04 24             	mov    %eax,(%esp)
  801543:	e8 84 f8 ff ff       	call   800dcc <sys_page_alloc>
  801548:	85 c0                	test   %eax,%eax
  80154a:	79 20                	jns    80156c <sfork+0x250>
		panic("sfork: page alloc failed : %e", r);
  80154c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801550:	c7 44 24 08 c1 1c 80 	movl   $0x801cc1,0x8(%esp)
  801557:	00 
  801558:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  80155f:	00 
  801560:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  801567:	e8 58 00 00 00       	call   8015c4 <_panic>
	
	extern void _pgfault_upcall(void);
	sys_env_set_pgfault_upcall(envid, _pgfault_upcall);
  80156c:	c7 44 24 04 a4 16 80 	movl   $0x8016a4,0x4(%esp)
  801573:	00 
  801574:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801577:	89 04 24             	mov    %eax,(%esp)
  80157a:	e8 c6 f9 ff ff       	call   800f45 <sys_env_set_pgfault_upcall>
	
	if((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
  80157f:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  801586:	00 
  801587:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80158a:	89 04 24             	mov    %eax,(%esp)
  80158d:	e8 55 f9 ff ff       	call   800ee7 <sys_env_set_status>
  801592:	85 c0                	test   %eax,%eax
  801594:	79 20                	jns    8015b6 <sfork+0x29a>
		panic("sfork: set child env status failed : %e", r);
  801596:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80159a:	c7 44 24 08 2c 1d 80 	movl   $0x801d2c,0x8(%esp)
  8015a1:	00 
  8015a2:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  8015a9:	00 
  8015aa:	c7 04 24 67 1c 80 00 	movl   $0x801c67,(%esp)
  8015b1:	e8 0e 00 00 00       	call   8015c4 <_panic>
		
	return envid;
}
  8015b6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8015b9:	83 c4 3c             	add    $0x3c,%esp
  8015bc:	5b                   	pop    %ebx
  8015bd:	5e                   	pop    %esi
  8015be:	5f                   	pop    %edi
  8015bf:	5d                   	pop    %ebp
  8015c0:	c3                   	ret    
  8015c1:	66 90                	xchg   %ax,%ax
  8015c3:	90                   	nop

008015c4 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8015c4:	55                   	push   %ebp
  8015c5:	89 e5                	mov    %esp,%ebp
  8015c7:	56                   	push   %esi
  8015c8:	53                   	push   %ebx
  8015c9:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8015cc:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  8015cf:	a1 08 20 80 00       	mov    0x802008,%eax
  8015d4:	85 c0                	test   %eax,%eax
  8015d6:	74 10                	je     8015e8 <_panic+0x24>
		cprintf("%s: ", argv0);
  8015d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8015dc:	c7 04 24 54 1d 80 00 	movl   $0x801d54,(%esp)
  8015e3:	e8 3f ec ff ff       	call   800227 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8015e8:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8015ee:	e8 79 f7 ff ff       	call   800d6c <sys_getenvid>
  8015f3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8015f6:	89 54 24 10          	mov    %edx,0x10(%esp)
  8015fa:	8b 55 08             	mov    0x8(%ebp),%edx
  8015fd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801601:	89 74 24 08          	mov    %esi,0x8(%esp)
  801605:	89 44 24 04          	mov    %eax,0x4(%esp)
  801609:	c7 04 24 5c 1d 80 00 	movl   $0x801d5c,(%esp)
  801610:	e8 12 ec ff ff       	call   800227 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801615:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  801619:	8b 45 10             	mov    0x10(%ebp),%eax
  80161c:	89 04 24             	mov    %eax,(%esp)
  80161f:	e8 a2 eb ff ff       	call   8001c6 <vcprintf>
	cprintf("\n");
  801624:	c7 04 24 65 1c 80 00 	movl   $0x801c65,(%esp)
  80162b:	e8 f7 eb ff ff       	call   800227 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  801630:	cc                   	int3   
  801631:	eb fd                	jmp    801630 <_panic+0x6c>
  801633:	90                   	nop

00801634 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801634:	55                   	push   %ebp
  801635:	89 e5                	mov    %esp,%ebp
  801637:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  80163a:	83 3d 0c 20 80 00 00 	cmpl   $0x0,0x80200c
  801641:	75 54                	jne    801697 <set_pgfault_handler+0x63>
		// First time through!
		// LAB 4: Your code here.
		if((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE), PTE_U|PTE_P|PTE_W)))
  801643:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  80164a:	00 
  80164b:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  801652:	ee 
  801653:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80165a:	e8 6d f7 ff ff       	call   800dcc <sys_page_alloc>
  80165f:	85 c0                	test   %eax,%eax
  801661:	74 20                	je     801683 <set_pgfault_handler+0x4f>
			panic("Exception stack alloc failed: %e!\n", r);
  801663:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801667:	c7 44 24 08 80 1d 80 	movl   $0x801d80,0x8(%esp)
  80166e:	00 
  80166f:	c7 44 24 04 21 00 00 	movl   $0x21,0x4(%esp)
  801676:	00 
  801677:	c7 04 24 a4 1d 80 00 	movl   $0x801da4,(%esp)
  80167e:	e8 41 ff ff ff       	call   8015c4 <_panic>
		sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  801683:	c7 44 24 04 a4 16 80 	movl   $0x8016a4,0x4(%esp)
  80168a:	00 
  80168b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801692:	e8 ae f8 ff ff       	call   800f45 <sys_env_set_pgfault_upcall>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  801697:	8b 45 08             	mov    0x8(%ebp),%eax
  80169a:	a3 0c 20 80 00       	mov    %eax,0x80200c
}
  80169f:	c9                   	leave  
  8016a0:	c3                   	ret    
  8016a1:	66 90                	xchg   %ax,%ax
  8016a3:	90                   	nop

008016a4 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  8016a4:	54                   	push   %esp
	movl _pgfault_handler, %eax
  8016a5:	a1 0c 20 80 00       	mov    0x80200c,%eax
	call *%eax
  8016aa:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  8016ac:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	addl $8, %esp
  8016af:	83 c4 08             	add    $0x8,%esp

	movl 0x20(%esp), %ecx
  8016b2:	8b 4c 24 20          	mov    0x20(%esp),%ecx
	movl 0x28(%esp), %eax
  8016b6:	8b 44 24 28          	mov    0x28(%esp),%eax
	subl $0x4, %eax 
  8016ba:	83 e8 04             	sub    $0x4,%eax
	movl %eax, 0x28(%esp)
  8016bd:	89 44 24 28          	mov    %eax,0x28(%esp)
	movl %ecx, (%eax)
  8016c1:	89 08                	mov    %ecx,(%eax)


	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  8016c3:	61                   	popa   

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $4, %esp
  8016c4:	83 c4 04             	add    $0x4,%esp
	popfl
  8016c7:	9d                   	popf   

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	pop %esp
  8016c8:	5c                   	pop    %esp
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  8016c9:	c3                   	ret    
  8016ca:	66 90                	xchg   %ax,%ax
  8016cc:	66 90                	xchg   %ax,%ax
  8016ce:	66 90                	xchg   %ax,%ax

008016d0 <__udivdi3>:
  8016d0:	83 ec 1c             	sub    $0x1c,%esp
  8016d3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  8016d7:	89 7c 24 14          	mov    %edi,0x14(%esp)
  8016db:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  8016df:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  8016e3:	8b 7c 24 20          	mov    0x20(%esp),%edi
  8016e7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  8016eb:	85 c0                	test   %eax,%eax
  8016ed:	89 74 24 10          	mov    %esi,0x10(%esp)
  8016f1:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8016f5:	89 ea                	mov    %ebp,%edx
  8016f7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8016fb:	75 33                	jne    801730 <__udivdi3+0x60>
  8016fd:	39 e9                	cmp    %ebp,%ecx
  8016ff:	77 6f                	ja     801770 <__udivdi3+0xa0>
  801701:	85 c9                	test   %ecx,%ecx
  801703:	89 ce                	mov    %ecx,%esi
  801705:	75 0b                	jne    801712 <__udivdi3+0x42>
  801707:	b8 01 00 00 00       	mov    $0x1,%eax
  80170c:	31 d2                	xor    %edx,%edx
  80170e:	f7 f1                	div    %ecx
  801710:	89 c6                	mov    %eax,%esi
  801712:	31 d2                	xor    %edx,%edx
  801714:	89 e8                	mov    %ebp,%eax
  801716:	f7 f6                	div    %esi
  801718:	89 c5                	mov    %eax,%ebp
  80171a:	89 f8                	mov    %edi,%eax
  80171c:	f7 f6                	div    %esi
  80171e:	89 ea                	mov    %ebp,%edx
  801720:	8b 74 24 10          	mov    0x10(%esp),%esi
  801724:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801728:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  80172c:	83 c4 1c             	add    $0x1c,%esp
  80172f:	c3                   	ret    
  801730:	39 e8                	cmp    %ebp,%eax
  801732:	77 24                	ja     801758 <__udivdi3+0x88>
  801734:	0f bd c8             	bsr    %eax,%ecx
  801737:	83 f1 1f             	xor    $0x1f,%ecx
  80173a:	89 0c 24             	mov    %ecx,(%esp)
  80173d:	75 49                	jne    801788 <__udivdi3+0xb8>
  80173f:	8b 74 24 08          	mov    0x8(%esp),%esi
  801743:	39 74 24 04          	cmp    %esi,0x4(%esp)
  801747:	0f 86 ab 00 00 00    	jbe    8017f8 <__udivdi3+0x128>
  80174d:	39 e8                	cmp    %ebp,%eax
  80174f:	0f 82 a3 00 00 00    	jb     8017f8 <__udivdi3+0x128>
  801755:	8d 76 00             	lea    0x0(%esi),%esi
  801758:	31 d2                	xor    %edx,%edx
  80175a:	31 c0                	xor    %eax,%eax
  80175c:	8b 74 24 10          	mov    0x10(%esp),%esi
  801760:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801764:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801768:	83 c4 1c             	add    $0x1c,%esp
  80176b:	c3                   	ret    
  80176c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801770:	89 f8                	mov    %edi,%eax
  801772:	f7 f1                	div    %ecx
  801774:	31 d2                	xor    %edx,%edx
  801776:	8b 74 24 10          	mov    0x10(%esp),%esi
  80177a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  80177e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801782:	83 c4 1c             	add    $0x1c,%esp
  801785:	c3                   	ret    
  801786:	66 90                	xchg   %ax,%ax
  801788:	0f b6 0c 24          	movzbl (%esp),%ecx
  80178c:	89 c6                	mov    %eax,%esi
  80178e:	b8 20 00 00 00       	mov    $0x20,%eax
  801793:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  801797:	2b 04 24             	sub    (%esp),%eax
  80179a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  80179e:	d3 e6                	shl    %cl,%esi
  8017a0:	89 c1                	mov    %eax,%ecx
  8017a2:	d3 ed                	shr    %cl,%ebp
  8017a4:	0f b6 0c 24          	movzbl (%esp),%ecx
  8017a8:	09 f5                	or     %esi,%ebp
  8017aa:	8b 74 24 04          	mov    0x4(%esp),%esi
  8017ae:	d3 e6                	shl    %cl,%esi
  8017b0:	89 c1                	mov    %eax,%ecx
  8017b2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8017b6:	89 d6                	mov    %edx,%esi
  8017b8:	d3 ee                	shr    %cl,%esi
  8017ba:	0f b6 0c 24          	movzbl (%esp),%ecx
  8017be:	d3 e2                	shl    %cl,%edx
  8017c0:	89 c1                	mov    %eax,%ecx
  8017c2:	d3 ef                	shr    %cl,%edi
  8017c4:	09 d7                	or     %edx,%edi
  8017c6:	89 f2                	mov    %esi,%edx
  8017c8:	89 f8                	mov    %edi,%eax
  8017ca:	f7 f5                	div    %ebp
  8017cc:	89 d6                	mov    %edx,%esi
  8017ce:	89 c7                	mov    %eax,%edi
  8017d0:	f7 64 24 04          	mull   0x4(%esp)
  8017d4:	39 d6                	cmp    %edx,%esi
  8017d6:	72 30                	jb     801808 <__udivdi3+0x138>
  8017d8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  8017dc:	0f b6 0c 24          	movzbl (%esp),%ecx
  8017e0:	d3 e5                	shl    %cl,%ebp
  8017e2:	39 c5                	cmp    %eax,%ebp
  8017e4:	73 04                	jae    8017ea <__udivdi3+0x11a>
  8017e6:	39 d6                	cmp    %edx,%esi
  8017e8:	74 1e                	je     801808 <__udivdi3+0x138>
  8017ea:	89 f8                	mov    %edi,%eax
  8017ec:	31 d2                	xor    %edx,%edx
  8017ee:	e9 69 ff ff ff       	jmp    80175c <__udivdi3+0x8c>
  8017f3:	90                   	nop
  8017f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8017f8:	31 d2                	xor    %edx,%edx
  8017fa:	b8 01 00 00 00       	mov    $0x1,%eax
  8017ff:	e9 58 ff ff ff       	jmp    80175c <__udivdi3+0x8c>
  801804:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801808:	8d 47 ff             	lea    -0x1(%edi),%eax
  80180b:	31 d2                	xor    %edx,%edx
  80180d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801811:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801815:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801819:	83 c4 1c             	add    $0x1c,%esp
  80181c:	c3                   	ret    
  80181d:	66 90                	xchg   %ax,%ax
  80181f:	90                   	nop

00801820 <__umoddi3>:
  801820:	83 ec 2c             	sub    $0x2c,%esp
  801823:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  801827:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80182b:	89 74 24 20          	mov    %esi,0x20(%esp)
  80182f:	8b 74 24 38          	mov    0x38(%esp),%esi
  801833:	89 7c 24 24          	mov    %edi,0x24(%esp)
  801837:	8b 7c 24 34          	mov    0x34(%esp),%edi
  80183b:	85 c0                	test   %eax,%eax
  80183d:	89 c2                	mov    %eax,%edx
  80183f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  801843:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  801847:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80184b:	89 74 24 10          	mov    %esi,0x10(%esp)
  80184f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  801853:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801857:	75 1f                	jne    801878 <__umoddi3+0x58>
  801859:	39 fe                	cmp    %edi,%esi
  80185b:	76 63                	jbe    8018c0 <__umoddi3+0xa0>
  80185d:	89 c8                	mov    %ecx,%eax
  80185f:	89 fa                	mov    %edi,%edx
  801861:	f7 f6                	div    %esi
  801863:	89 d0                	mov    %edx,%eax
  801865:	31 d2                	xor    %edx,%edx
  801867:	8b 74 24 20          	mov    0x20(%esp),%esi
  80186b:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80186f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801873:	83 c4 2c             	add    $0x2c,%esp
  801876:	c3                   	ret    
  801877:	90                   	nop
  801878:	39 f8                	cmp    %edi,%eax
  80187a:	77 64                	ja     8018e0 <__umoddi3+0xc0>
  80187c:	0f bd e8             	bsr    %eax,%ebp
  80187f:	83 f5 1f             	xor    $0x1f,%ebp
  801882:	75 74                	jne    8018f8 <__umoddi3+0xd8>
  801884:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801888:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  80188c:	0f 87 0e 01 00 00    	ja     8019a0 <__umoddi3+0x180>
  801892:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  801896:	29 f1                	sub    %esi,%ecx
  801898:	19 c7                	sbb    %eax,%edi
  80189a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  80189e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8018a2:	8b 44 24 14          	mov    0x14(%esp),%eax
  8018a6:	8b 54 24 18          	mov    0x18(%esp),%edx
  8018aa:	8b 74 24 20          	mov    0x20(%esp),%esi
  8018ae:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8018b2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8018b6:	83 c4 2c             	add    $0x2c,%esp
  8018b9:	c3                   	ret    
  8018ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8018c0:	85 f6                	test   %esi,%esi
  8018c2:	89 f5                	mov    %esi,%ebp
  8018c4:	75 0b                	jne    8018d1 <__umoddi3+0xb1>
  8018c6:	b8 01 00 00 00       	mov    $0x1,%eax
  8018cb:	31 d2                	xor    %edx,%edx
  8018cd:	f7 f6                	div    %esi
  8018cf:	89 c5                	mov    %eax,%ebp
  8018d1:	8b 44 24 0c          	mov    0xc(%esp),%eax
  8018d5:	31 d2                	xor    %edx,%edx
  8018d7:	f7 f5                	div    %ebp
  8018d9:	89 c8                	mov    %ecx,%eax
  8018db:	f7 f5                	div    %ebp
  8018dd:	eb 84                	jmp    801863 <__umoddi3+0x43>
  8018df:	90                   	nop
  8018e0:	89 c8                	mov    %ecx,%eax
  8018e2:	89 fa                	mov    %edi,%edx
  8018e4:	8b 74 24 20          	mov    0x20(%esp),%esi
  8018e8:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8018ec:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8018f0:	83 c4 2c             	add    $0x2c,%esp
  8018f3:	c3                   	ret    
  8018f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8018f8:	8b 44 24 10          	mov    0x10(%esp),%eax
  8018fc:	be 20 00 00 00       	mov    $0x20,%esi
  801901:	89 e9                	mov    %ebp,%ecx
  801903:	29 ee                	sub    %ebp,%esi
  801905:	d3 e2                	shl    %cl,%edx
  801907:	89 f1                	mov    %esi,%ecx
  801909:	d3 e8                	shr    %cl,%eax
  80190b:	89 e9                	mov    %ebp,%ecx
  80190d:	09 d0                	or     %edx,%eax
  80190f:	89 fa                	mov    %edi,%edx
  801911:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801915:	8b 44 24 10          	mov    0x10(%esp),%eax
  801919:	d3 e0                	shl    %cl,%eax
  80191b:	89 f1                	mov    %esi,%ecx
  80191d:	89 44 24 10          	mov    %eax,0x10(%esp)
  801921:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  801925:	d3 ea                	shr    %cl,%edx
  801927:	89 e9                	mov    %ebp,%ecx
  801929:	d3 e7                	shl    %cl,%edi
  80192b:	89 f1                	mov    %esi,%ecx
  80192d:	d3 e8                	shr    %cl,%eax
  80192f:	89 e9                	mov    %ebp,%ecx
  801931:	09 f8                	or     %edi,%eax
  801933:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  801937:	f7 74 24 0c          	divl   0xc(%esp)
  80193b:	d3 e7                	shl    %cl,%edi
  80193d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801941:	89 d7                	mov    %edx,%edi
  801943:	f7 64 24 10          	mull   0x10(%esp)
  801947:	39 d7                	cmp    %edx,%edi
  801949:	89 c1                	mov    %eax,%ecx
  80194b:	89 54 24 14          	mov    %edx,0x14(%esp)
  80194f:	72 3b                	jb     80198c <__umoddi3+0x16c>
  801951:	39 44 24 18          	cmp    %eax,0x18(%esp)
  801955:	72 31                	jb     801988 <__umoddi3+0x168>
  801957:	8b 44 24 18          	mov    0x18(%esp),%eax
  80195b:	29 c8                	sub    %ecx,%eax
  80195d:	19 d7                	sbb    %edx,%edi
  80195f:	89 e9                	mov    %ebp,%ecx
  801961:	89 fa                	mov    %edi,%edx
  801963:	d3 e8                	shr    %cl,%eax
  801965:	89 f1                	mov    %esi,%ecx
  801967:	d3 e2                	shl    %cl,%edx
  801969:	89 e9                	mov    %ebp,%ecx
  80196b:	09 d0                	or     %edx,%eax
  80196d:	89 fa                	mov    %edi,%edx
  80196f:	d3 ea                	shr    %cl,%edx
  801971:	8b 74 24 20          	mov    0x20(%esp),%esi
  801975:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801979:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  80197d:	83 c4 2c             	add    $0x2c,%esp
  801980:	c3                   	ret    
  801981:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801988:	39 d7                	cmp    %edx,%edi
  80198a:	75 cb                	jne    801957 <__umoddi3+0x137>
  80198c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801990:	89 c1                	mov    %eax,%ecx
  801992:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801996:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80199a:	eb bb                	jmp    801957 <__umoddi3+0x137>
  80199c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8019a0:	3b 44 24 18          	cmp    0x18(%esp),%eax
  8019a4:	0f 82 e8 fe ff ff    	jb     801892 <__umoddi3+0x72>
  8019aa:	e9 f3 fe ff ff       	jmp    8018a2 <__umoddi3+0x82>

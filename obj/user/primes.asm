
obj/user/primes：     文件格式 elf32-i386


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
  80002c:	e8 1f 01 00 00       	call   800150 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	90                   	nop

00800034 <primeproc>:

#include <inc/lib.h>

unsigned
primeproc(void)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	57                   	push   %edi
  800038:	56                   	push   %esi
  800039:	53                   	push   %ebx
  80003a:	83 ec 2c             	sub    $0x2c,%esp
	int i, id, p;
	envid_t envid;

	// fetch a prime from our left neighbor
top:
	p = ipc_recv(&envid, 0, 0);
  80003d:	8d 75 e4             	lea    -0x1c(%ebp),%esi
  800040:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800047:	00 
  800048:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80004f:	00 
  800050:	89 34 24             	mov    %esi,(%esp)
  800053:	e8 e0 10 00 00       	call   801138 <ipc_recv>
  800058:	89 c3                	mov    %eax,%ebx
	cprintf("CPU %d: %d ", thisenv->env_cpunum, p);
  80005a:	a1 04 20 80 00       	mov    0x802004,%eax
  80005f:	8b 40 5c             	mov    0x5c(%eax),%eax
  800062:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800066:	89 44 24 04          	mov    %eax,0x4(%esp)
  80006a:	c7 04 24 c0 14 80 00 	movl   $0x8014c0,(%esp)
  800071:	e8 75 02 00 00       	call   8002eb <cprintf>

	// fork a right neighbor to continue the chain
	if ((id = fork()) < 0)
  800076:	e8 79 10 00 00       	call   8010f4 <fork>
  80007b:	89 c7                	mov    %eax,%edi
  80007d:	85 c0                	test   %eax,%eax
  80007f:	79 20                	jns    8000a1 <primeproc+0x6d>
		panic("fork: %e", id);
  800081:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800085:	c7 44 24 08 cc 14 80 	movl   $0x8014cc,0x8(%esp)
  80008c:	00 
  80008d:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
  800094:	00 
  800095:	c7 04 24 d5 14 80 00 	movl   $0x8014d5,(%esp)
  80009c:	e8 37 01 00 00       	call   8001d8 <_panic>
	if (id == 0)
  8000a1:	85 c0                	test   %eax,%eax
  8000a3:	74 9b                	je     800040 <primeproc+0xc>
		goto top;

	// filter out multiples of our prime
	while (1) {
		i = ipc_recv(&envid, 0, 0);
  8000a5:	8d 75 e4             	lea    -0x1c(%ebp),%esi
  8000a8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8000af:	00 
  8000b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8000b7:	00 
  8000b8:	89 34 24             	mov    %esi,(%esp)
  8000bb:	e8 78 10 00 00       	call   801138 <ipc_recv>
  8000c0:	89 c1                	mov    %eax,%ecx
		if (i % p)
  8000c2:	89 c2                	mov    %eax,%edx
  8000c4:	c1 fa 1f             	sar    $0x1f,%edx
  8000c7:	f7 fb                	idiv   %ebx
  8000c9:	85 d2                	test   %edx,%edx
  8000cb:	74 db                	je     8000a8 <primeproc+0x74>
			ipc_send(id, i, 0, 0);
  8000cd:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8000d4:	00 
  8000d5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8000dc:	00 
  8000dd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8000e1:	89 3c 24             	mov    %edi,(%esp)
  8000e4:	e8 71 10 00 00       	call   80115a <ipc_send>
  8000e9:	eb bd                	jmp    8000a8 <primeproc+0x74>

008000eb <umain>:
	}
}

void
umain(int argc, char **argv)
{
  8000eb:	55                   	push   %ebp
  8000ec:	89 e5                	mov    %esp,%ebp
  8000ee:	56                   	push   %esi
  8000ef:	53                   	push   %ebx
  8000f0:	83 ec 10             	sub    $0x10,%esp
	int i, id;

	// fork the first prime process in the chain
	if ((id = fork()) < 0)
  8000f3:	e8 fc 0f 00 00       	call   8010f4 <fork>
  8000f8:	89 c6                	mov    %eax,%esi
  8000fa:	85 c0                	test   %eax,%eax
  8000fc:	79 20                	jns    80011e <umain+0x33>
		panic("fork: %e", id);
  8000fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800102:	c7 44 24 08 cc 14 80 	movl   $0x8014cc,0x8(%esp)
  800109:	00 
  80010a:	c7 44 24 04 2d 00 00 	movl   $0x2d,0x4(%esp)
  800111:	00 
  800112:	c7 04 24 d5 14 80 00 	movl   $0x8014d5,(%esp)
  800119:	e8 ba 00 00 00       	call   8001d8 <_panic>
	if (id == 0)
  80011e:	bb 02 00 00 00       	mov    $0x2,%ebx
  800123:	85 c0                	test   %eax,%eax
  800125:	75 05                	jne    80012c <umain+0x41>
		primeproc();
  800127:	e8 08 ff ff ff       	call   800034 <primeproc>

	// feed all the integers through
	for (i = 2; ; i++)
		ipc_send(id, i, 0, 0);
  80012c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800133:	00 
  800134:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80013b:	00 
  80013c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800140:	89 34 24             	mov    %esi,(%esp)
  800143:	e8 12 10 00 00       	call   80115a <ipc_send>
		panic("fork: %e", id);
	if (id == 0)
		primeproc();

	// feed all the integers through
	for (i = 2; ; i++)
  800148:	83 c3 01             	add    $0x1,%ebx
  80014b:	eb df                	jmp    80012c <umain+0x41>
  80014d:	66 90                	xchg   %ax,%ax
  80014f:	90                   	nop

00800150 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800150:	55                   	push   %ebp
  800151:	89 e5                	mov    %esp,%ebp
  800153:	57                   	push   %edi
  800154:	56                   	push   %esi
  800155:	53                   	push   %ebx
  800156:	83 ec 1c             	sub    $0x1c,%esp
  800159:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80015c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  80015f:	e8 c8 0c 00 00       	call   800e2c <sys_getenvid>
	thisenv = envs;
  800164:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  80016b:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  80016e:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  800174:	39 c2                	cmp    %eax,%edx
  800176:	74 25                	je     80019d <libmain+0x4d>
  800178:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  80017d:	eb 12                	jmp    800191 <libmain+0x41>
  80017f:	8b 4a 48             	mov    0x48(%edx),%ecx
  800182:	83 c2 7c             	add    $0x7c,%edx
  800185:	39 c1                	cmp    %eax,%ecx
  800187:	75 08                	jne    800191 <libmain+0x41>
  800189:	89 3d 04 20 80 00    	mov    %edi,0x802004
  80018f:	eb 0c                	jmp    80019d <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  800191:	89 d7                	mov    %edx,%edi
  800193:	85 d2                	test   %edx,%edx
  800195:	75 e8                	jne    80017f <libmain+0x2f>
  800197:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80019d:	85 db                	test   %ebx,%ebx
  80019f:	7e 07                	jle    8001a8 <libmain+0x58>
		binaryname = argv[0];
  8001a1:	8b 06                	mov    (%esi),%eax
  8001a3:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8001a8:	89 74 24 04          	mov    %esi,0x4(%esp)
  8001ac:	89 1c 24             	mov    %ebx,(%esp)
  8001af:	e8 37 ff ff ff       	call   8000eb <umain>

	// exit gracefully
	exit();
  8001b4:	e8 0b 00 00 00       	call   8001c4 <exit>
}
  8001b9:	83 c4 1c             	add    $0x1c,%esp
  8001bc:	5b                   	pop    %ebx
  8001bd:	5e                   	pop    %esi
  8001be:	5f                   	pop    %edi
  8001bf:	5d                   	pop    %ebp
  8001c0:	c3                   	ret    
  8001c1:	66 90                	xchg   %ax,%ax
  8001c3:	90                   	nop

008001c4 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8001c4:	55                   	push   %ebp
  8001c5:	89 e5                	mov    %esp,%ebp
  8001c7:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8001ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8001d1:	e8 f9 0b 00 00       	call   800dcf <sys_env_destroy>
}
  8001d6:	c9                   	leave  
  8001d7:	c3                   	ret    

008001d8 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8001d8:	55                   	push   %ebp
  8001d9:	89 e5                	mov    %esp,%ebp
  8001db:	56                   	push   %esi
  8001dc:	53                   	push   %ebx
  8001dd:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8001e0:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  8001e3:	a1 08 20 80 00       	mov    0x802008,%eax
  8001e8:	85 c0                	test   %eax,%eax
  8001ea:	74 10                	je     8001fc <_panic+0x24>
		cprintf("%s: ", argv0);
  8001ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001f0:	c7 04 24 ed 14 80 00 	movl   $0x8014ed,(%esp)
  8001f7:	e8 ef 00 00 00       	call   8002eb <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001fc:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800202:	e8 25 0c 00 00       	call   800e2c <sys_getenvid>
  800207:	8b 55 0c             	mov    0xc(%ebp),%edx
  80020a:	89 54 24 10          	mov    %edx,0x10(%esp)
  80020e:	8b 55 08             	mov    0x8(%ebp),%edx
  800211:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800215:	89 74 24 08          	mov    %esi,0x8(%esp)
  800219:	89 44 24 04          	mov    %eax,0x4(%esp)
  80021d:	c7 04 24 f4 14 80 00 	movl   $0x8014f4,(%esp)
  800224:	e8 c2 00 00 00       	call   8002eb <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800229:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80022d:	8b 45 10             	mov    0x10(%ebp),%eax
  800230:	89 04 24             	mov    %eax,(%esp)
  800233:	e8 52 00 00 00       	call   80028a <vcprintf>
	cprintf("\n");
  800238:	c7 04 24 f2 14 80 00 	movl   $0x8014f2,(%esp)
  80023f:	e8 a7 00 00 00       	call   8002eb <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800244:	cc                   	int3   
  800245:	eb fd                	jmp    800244 <_panic+0x6c>
  800247:	90                   	nop

00800248 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800248:	55                   	push   %ebp
  800249:	89 e5                	mov    %esp,%ebp
  80024b:	53                   	push   %ebx
  80024c:	83 ec 14             	sub    $0x14,%esp
  80024f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800252:	8b 03                	mov    (%ebx),%eax
  800254:	8b 55 08             	mov    0x8(%ebp),%edx
  800257:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  80025b:	83 c0 01             	add    $0x1,%eax
  80025e:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800260:	3d ff 00 00 00       	cmp    $0xff,%eax
  800265:	75 19                	jne    800280 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800267:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80026e:	00 
  80026f:	8d 43 08             	lea    0x8(%ebx),%eax
  800272:	89 04 24             	mov    %eax,(%esp)
  800275:	e8 f6 0a 00 00       	call   800d70 <sys_cputs>
		b->idx = 0;
  80027a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800280:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800284:	83 c4 14             	add    $0x14,%esp
  800287:	5b                   	pop    %ebx
  800288:	5d                   	pop    %ebp
  800289:	c3                   	ret    

0080028a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80028a:	55                   	push   %ebp
  80028b:	89 e5                	mov    %esp,%ebp
  80028d:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800293:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80029a:	00 00 00 
	b.cnt = 0;
  80029d:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8002a4:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8002a7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002aa:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002ae:	8b 45 08             	mov    0x8(%ebp),%eax
  8002b1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002b5:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8002bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002bf:	c7 04 24 48 02 80 00 	movl   $0x800248,(%esp)
  8002c6:	e8 b7 01 00 00       	call   800482 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8002cb:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8002d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d5:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8002db:	89 04 24             	mov    %eax,(%esp)
  8002de:	e8 8d 0a 00 00       	call   800d70 <sys_cputs>

	return b.cnt;
}
  8002e3:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002e9:	c9                   	leave  
  8002ea:	c3                   	ret    

008002eb <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002eb:	55                   	push   %ebp
  8002ec:	89 e5                	mov    %esp,%ebp
  8002ee:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002f1:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002f8:	8b 45 08             	mov    0x8(%ebp),%eax
  8002fb:	89 04 24             	mov    %eax,(%esp)
  8002fe:	e8 87 ff ff ff       	call   80028a <vcprintf>
	va_end(ap);

	return cnt;
}
  800303:	c9                   	leave  
  800304:	c3                   	ret    
  800305:	66 90                	xchg   %ax,%ax
  800307:	66 90                	xchg   %ax,%ax
  800309:	66 90                	xchg   %ax,%ax
  80030b:	66 90                	xchg   %ax,%ax
  80030d:	66 90                	xchg   %ax,%ax
  80030f:	90                   	nop

00800310 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800310:	55                   	push   %ebp
  800311:	89 e5                	mov    %esp,%ebp
  800313:	57                   	push   %edi
  800314:	56                   	push   %esi
  800315:	53                   	push   %ebx
  800316:	83 ec 4c             	sub    $0x4c,%esp
  800319:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80031c:	89 d7                	mov    %edx,%edi
  80031e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800321:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800324:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800327:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80032a:	b8 00 00 00 00       	mov    $0x0,%eax
  80032f:	39 d8                	cmp    %ebx,%eax
  800331:	72 17                	jb     80034a <printnum+0x3a>
  800333:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800336:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800339:	76 0f                	jbe    80034a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80033b:	8b 75 14             	mov    0x14(%ebp),%esi
  80033e:	83 ee 01             	sub    $0x1,%esi
  800341:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800344:	85 f6                	test   %esi,%esi
  800346:	7f 63                	jg     8003ab <printnum+0x9b>
  800348:	eb 75                	jmp    8003bf <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80034a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80034d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800351:	8b 45 14             	mov    0x14(%ebp),%eax
  800354:	83 e8 01             	sub    $0x1,%eax
  800357:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80035b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80035e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800362:	8b 44 24 08          	mov    0x8(%esp),%eax
  800366:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80036a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80036d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800370:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800377:	00 
  800378:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80037b:	89 1c 24             	mov    %ebx,(%esp)
  80037e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800381:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800385:	e8 46 0e 00 00       	call   8011d0 <__udivdi3>
  80038a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80038d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800390:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800394:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800398:	89 04 24             	mov    %eax,(%esp)
  80039b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80039f:	89 fa                	mov    %edi,%edx
  8003a1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003a4:	e8 67 ff ff ff       	call   800310 <printnum>
  8003a9:	eb 14                	jmp    8003bf <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8003ab:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003af:	8b 45 18             	mov    0x18(%ebp),%eax
  8003b2:	89 04 24             	mov    %eax,(%esp)
  8003b5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8003b7:	83 ee 01             	sub    $0x1,%esi
  8003ba:	75 ef                	jne    8003ab <printnum+0x9b>
  8003bc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8003bf:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003c3:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8003c7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003ca:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8003ce:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8003d5:	00 
  8003d6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8003d9:	89 1c 24             	mov    %ebx,(%esp)
  8003dc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8003df:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003e3:	e8 38 0f 00 00       	call   801320 <__umoddi3>
  8003e8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003ec:	0f be 80 18 15 80 00 	movsbl 0x801518(%eax),%eax
  8003f3:	89 04 24             	mov    %eax,(%esp)
  8003f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003f9:	ff d0                	call   *%eax
}
  8003fb:	83 c4 4c             	add    $0x4c,%esp
  8003fe:	5b                   	pop    %ebx
  8003ff:	5e                   	pop    %esi
  800400:	5f                   	pop    %edi
  800401:	5d                   	pop    %ebp
  800402:	c3                   	ret    

00800403 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800403:	55                   	push   %ebp
  800404:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800406:	83 fa 01             	cmp    $0x1,%edx
  800409:	7e 0e                	jle    800419 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80040b:	8b 10                	mov    (%eax),%edx
  80040d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800410:	89 08                	mov    %ecx,(%eax)
  800412:	8b 02                	mov    (%edx),%eax
  800414:	8b 52 04             	mov    0x4(%edx),%edx
  800417:	eb 22                	jmp    80043b <getuint+0x38>
	else if (lflag)
  800419:	85 d2                	test   %edx,%edx
  80041b:	74 10                	je     80042d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80041d:	8b 10                	mov    (%eax),%edx
  80041f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800422:	89 08                	mov    %ecx,(%eax)
  800424:	8b 02                	mov    (%edx),%eax
  800426:	ba 00 00 00 00       	mov    $0x0,%edx
  80042b:	eb 0e                	jmp    80043b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80042d:	8b 10                	mov    (%eax),%edx
  80042f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800432:	89 08                	mov    %ecx,(%eax)
  800434:	8b 02                	mov    (%edx),%eax
  800436:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80043b:	5d                   	pop    %ebp
  80043c:	c3                   	ret    

0080043d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80043d:	55                   	push   %ebp
  80043e:	89 e5                	mov    %esp,%ebp
  800440:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800443:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800447:	8b 10                	mov    (%eax),%edx
  800449:	3b 50 04             	cmp    0x4(%eax),%edx
  80044c:	73 0a                	jae    800458 <sprintputch+0x1b>
		*b->buf++ = ch;
  80044e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800451:	88 0a                	mov    %cl,(%edx)
  800453:	83 c2 01             	add    $0x1,%edx
  800456:	89 10                	mov    %edx,(%eax)
}
  800458:	5d                   	pop    %ebp
  800459:	c3                   	ret    

0080045a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80045a:	55                   	push   %ebp
  80045b:	89 e5                	mov    %esp,%ebp
  80045d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800460:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800463:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800467:	8b 45 10             	mov    0x10(%ebp),%eax
  80046a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80046e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800471:	89 44 24 04          	mov    %eax,0x4(%esp)
  800475:	8b 45 08             	mov    0x8(%ebp),%eax
  800478:	89 04 24             	mov    %eax,(%esp)
  80047b:	e8 02 00 00 00       	call   800482 <vprintfmt>
	va_end(ap);
}
  800480:	c9                   	leave  
  800481:	c3                   	ret    

00800482 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800482:	55                   	push   %ebp
  800483:	89 e5                	mov    %esp,%ebp
  800485:	57                   	push   %edi
  800486:	56                   	push   %esi
  800487:	53                   	push   %ebx
  800488:	83 ec 4c             	sub    $0x4c,%esp
  80048b:	8b 75 08             	mov    0x8(%ebp),%esi
  80048e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800491:	8b 7d 10             	mov    0x10(%ebp),%edi
  800494:	eb 11                	jmp    8004a7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800496:	85 c0                	test   %eax,%eax
  800498:	0f 84 db 03 00 00    	je     800879 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80049e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004a2:	89 04 24             	mov    %eax,(%esp)
  8004a5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004a7:	0f b6 07             	movzbl (%edi),%eax
  8004aa:	83 c7 01             	add    $0x1,%edi
  8004ad:	83 f8 25             	cmp    $0x25,%eax
  8004b0:	75 e4                	jne    800496 <vprintfmt+0x14>
  8004b2:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  8004b6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  8004bd:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8004c4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  8004cb:	ba 00 00 00 00       	mov    $0x0,%edx
  8004d0:	eb 2b                	jmp    8004fd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8004d5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  8004d9:	eb 22                	jmp    8004fd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004db:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8004de:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  8004e2:	eb 19                	jmp    8004fd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  8004e7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8004ee:	eb 0d                	jmp    8004fd <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8004f0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004f3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004f6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004fd:	0f b6 0f             	movzbl (%edi),%ecx
  800500:	8d 47 01             	lea    0x1(%edi),%eax
  800503:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800506:	0f b6 07             	movzbl (%edi),%eax
  800509:	83 e8 23             	sub    $0x23,%eax
  80050c:	3c 55                	cmp    $0x55,%al
  80050e:	0f 87 40 03 00 00    	ja     800854 <vprintfmt+0x3d2>
  800514:	0f b6 c0             	movzbl %al,%eax
  800517:	ff 24 85 e0 15 80 00 	jmp    *0x8015e0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80051e:	83 e9 30             	sub    $0x30,%ecx
  800521:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800524:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800528:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80052b:	83 f9 09             	cmp    $0x9,%ecx
  80052e:	77 57                	ja     800587 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800530:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800533:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800536:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800539:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80053c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80053f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800543:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800546:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800549:	83 f9 09             	cmp    $0x9,%ecx
  80054c:	76 eb                	jbe    800539 <vprintfmt+0xb7>
  80054e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800551:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800554:	eb 34                	jmp    80058a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800556:	8b 45 14             	mov    0x14(%ebp),%eax
  800559:	8d 48 04             	lea    0x4(%eax),%ecx
  80055c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80055f:	8b 00                	mov    (%eax),%eax
  800561:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800564:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800567:	eb 21                	jmp    80058a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800569:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80056d:	0f 88 71 ff ff ff    	js     8004e4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800573:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800576:	eb 85                	jmp    8004fd <vprintfmt+0x7b>
  800578:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80057b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800582:	e9 76 ff ff ff       	jmp    8004fd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800587:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80058a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80058e:	0f 89 69 ff ff ff    	jns    8004fd <vprintfmt+0x7b>
  800594:	e9 57 ff ff ff       	jmp    8004f0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800599:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80059c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80059f:	e9 59 ff ff ff       	jmp    8004fd <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8005a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a7:	8d 50 04             	lea    0x4(%eax),%edx
  8005aa:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005b1:	8b 00                	mov    (%eax),%eax
  8005b3:	89 04 24             	mov    %eax,(%esp)
  8005b6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005b8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8005bb:	e9 e7 fe ff ff       	jmp    8004a7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8005c0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c3:	8d 50 04             	lea    0x4(%eax),%edx
  8005c6:	89 55 14             	mov    %edx,0x14(%ebp)
  8005c9:	8b 00                	mov    (%eax),%eax
  8005cb:	89 c2                	mov    %eax,%edx
  8005cd:	c1 fa 1f             	sar    $0x1f,%edx
  8005d0:	31 d0                	xor    %edx,%eax
  8005d2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8005d4:	83 f8 08             	cmp    $0x8,%eax
  8005d7:	7f 0b                	jg     8005e4 <vprintfmt+0x162>
  8005d9:	8b 14 85 40 17 80 00 	mov    0x801740(,%eax,4),%edx
  8005e0:	85 d2                	test   %edx,%edx
  8005e2:	75 20                	jne    800604 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  8005e4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005e8:	c7 44 24 08 30 15 80 	movl   $0x801530,0x8(%esp)
  8005ef:	00 
  8005f0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005f4:	89 34 24             	mov    %esi,(%esp)
  8005f7:	e8 5e fe ff ff       	call   80045a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005fc:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8005ff:	e9 a3 fe ff ff       	jmp    8004a7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800604:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800608:	c7 44 24 08 39 15 80 	movl   $0x801539,0x8(%esp)
  80060f:	00 
  800610:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800614:	89 34 24             	mov    %esi,(%esp)
  800617:	e8 3e fe ff ff       	call   80045a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80061c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80061f:	e9 83 fe ff ff       	jmp    8004a7 <vprintfmt+0x25>
  800624:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800627:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80062a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80062d:	8b 45 14             	mov    0x14(%ebp),%eax
  800630:	8d 50 04             	lea    0x4(%eax),%edx
  800633:	89 55 14             	mov    %edx,0x14(%ebp)
  800636:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800638:	85 ff                	test   %edi,%edi
  80063a:	b8 29 15 80 00       	mov    $0x801529,%eax
  80063f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800642:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800646:	74 06                	je     80064e <vprintfmt+0x1cc>
  800648:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  80064c:	7f 16                	jg     800664 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80064e:	0f b6 17             	movzbl (%edi),%edx
  800651:	0f be c2             	movsbl %dl,%eax
  800654:	83 c7 01             	add    $0x1,%edi
  800657:	85 c0                	test   %eax,%eax
  800659:	0f 85 9f 00 00 00    	jne    8006fe <vprintfmt+0x27c>
  80065f:	e9 8b 00 00 00       	jmp    8006ef <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800664:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800668:	89 3c 24             	mov    %edi,(%esp)
  80066b:	e8 c2 02 00 00       	call   800932 <strnlen>
  800670:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800673:	29 c2                	sub    %eax,%edx
  800675:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800678:	85 d2                	test   %edx,%edx
  80067a:	7e d2                	jle    80064e <vprintfmt+0x1cc>
					putch(padc, putdat);
  80067c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800680:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800683:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800686:	89 d7                	mov    %edx,%edi
  800688:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80068c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80068f:	89 04 24             	mov    %eax,(%esp)
  800692:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800694:	83 ef 01             	sub    $0x1,%edi
  800697:	75 ef                	jne    800688 <vprintfmt+0x206>
  800699:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80069c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80069f:	eb ad                	jmp    80064e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8006a1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8006a5:	74 20                	je     8006c7 <vprintfmt+0x245>
  8006a7:	0f be d2             	movsbl %dl,%edx
  8006aa:	83 ea 20             	sub    $0x20,%edx
  8006ad:	83 fa 5e             	cmp    $0x5e,%edx
  8006b0:	76 15                	jbe    8006c7 <vprintfmt+0x245>
					putch('?', putdat);
  8006b2:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8006b5:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006b9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8006c0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8006c3:	ff d1                	call   *%ecx
  8006c5:	eb 0f                	jmp    8006d6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  8006c7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8006ca:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006ce:	89 04 24             	mov    %eax,(%esp)
  8006d1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8006d4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006d6:	83 eb 01             	sub    $0x1,%ebx
  8006d9:	0f b6 17             	movzbl (%edi),%edx
  8006dc:	0f be c2             	movsbl %dl,%eax
  8006df:	83 c7 01             	add    $0x1,%edi
  8006e2:	85 c0                	test   %eax,%eax
  8006e4:	75 24                	jne    80070a <vprintfmt+0x288>
  8006e6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8006e9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006ec:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006ef:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006f2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006f6:	0f 8e ab fd ff ff    	jle    8004a7 <vprintfmt+0x25>
  8006fc:	eb 20                	jmp    80071e <vprintfmt+0x29c>
  8006fe:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800701:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800704:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800707:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80070a:	85 f6                	test   %esi,%esi
  80070c:	78 93                	js     8006a1 <vprintfmt+0x21f>
  80070e:	83 ee 01             	sub    $0x1,%esi
  800711:	79 8e                	jns    8006a1 <vprintfmt+0x21f>
  800713:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800716:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800719:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80071c:	eb d1                	jmp    8006ef <vprintfmt+0x26d>
  80071e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800721:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800725:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80072c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80072e:	83 ef 01             	sub    $0x1,%edi
  800731:	75 ee                	jne    800721 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800733:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800736:	e9 6c fd ff ff       	jmp    8004a7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80073b:	83 fa 01             	cmp    $0x1,%edx
  80073e:	66 90                	xchg   %ax,%ax
  800740:	7e 16                	jle    800758 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800742:	8b 45 14             	mov    0x14(%ebp),%eax
  800745:	8d 50 08             	lea    0x8(%eax),%edx
  800748:	89 55 14             	mov    %edx,0x14(%ebp)
  80074b:	8b 10                	mov    (%eax),%edx
  80074d:	8b 48 04             	mov    0x4(%eax),%ecx
  800750:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800753:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800756:	eb 32                	jmp    80078a <vprintfmt+0x308>
	else if (lflag)
  800758:	85 d2                	test   %edx,%edx
  80075a:	74 18                	je     800774 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  80075c:	8b 45 14             	mov    0x14(%ebp),%eax
  80075f:	8d 50 04             	lea    0x4(%eax),%edx
  800762:	89 55 14             	mov    %edx,0x14(%ebp)
  800765:	8b 00                	mov    (%eax),%eax
  800767:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80076a:	89 c1                	mov    %eax,%ecx
  80076c:	c1 f9 1f             	sar    $0x1f,%ecx
  80076f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800772:	eb 16                	jmp    80078a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800774:	8b 45 14             	mov    0x14(%ebp),%eax
  800777:	8d 50 04             	lea    0x4(%eax),%edx
  80077a:	89 55 14             	mov    %edx,0x14(%ebp)
  80077d:	8b 00                	mov    (%eax),%eax
  80077f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800782:	89 c7                	mov    %eax,%edi
  800784:	c1 ff 1f             	sar    $0x1f,%edi
  800787:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80078a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80078d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800790:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800795:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800799:	79 7d                	jns    800818 <vprintfmt+0x396>
				putch('-', putdat);
  80079b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80079f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8007a6:	ff d6                	call   *%esi
				num = -(long long) num;
  8007a8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8007ab:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8007ae:	f7 d8                	neg    %eax
  8007b0:	83 d2 00             	adc    $0x0,%edx
  8007b3:	f7 da                	neg    %edx
			}
			base = 10;
  8007b5:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8007ba:	eb 5c                	jmp    800818 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8007bc:	8d 45 14             	lea    0x14(%ebp),%eax
  8007bf:	e8 3f fc ff ff       	call   800403 <getuint>
			base = 10;
  8007c4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8007c9:	eb 4d                	jmp    800818 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  8007cb:	8d 45 14             	lea    0x14(%ebp),%eax
  8007ce:	e8 30 fc ff ff       	call   800403 <getuint>
			base = 8;
  8007d3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007d8:	eb 3e                	jmp    800818 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  8007da:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007de:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8007e5:	ff d6                	call   *%esi
			putch('x', putdat);
  8007e7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007eb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8007f2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007f7:	8d 50 04             	lea    0x4(%eax),%edx
  8007fa:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007fd:	8b 00                	mov    (%eax),%eax
  8007ff:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800804:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800809:	eb 0d                	jmp    800818 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80080b:	8d 45 14             	lea    0x14(%ebp),%eax
  80080e:	e8 f0 fb ff ff       	call   800403 <getuint>
			base = 16;
  800813:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800818:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80081c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800820:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800823:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800827:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80082b:	89 04 24             	mov    %eax,(%esp)
  80082e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800832:	89 da                	mov    %ebx,%edx
  800834:	89 f0                	mov    %esi,%eax
  800836:	e8 d5 fa ff ff       	call   800310 <printnum>
			break;
  80083b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80083e:	e9 64 fc ff ff       	jmp    8004a7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800843:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800847:	89 0c 24             	mov    %ecx,(%esp)
  80084a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80084c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80084f:	e9 53 fc ff ff       	jmp    8004a7 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800854:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800858:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  80085f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800861:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800865:	0f 84 3c fc ff ff    	je     8004a7 <vprintfmt+0x25>
  80086b:	83 ef 01             	sub    $0x1,%edi
  80086e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800872:	75 f7                	jne    80086b <vprintfmt+0x3e9>
  800874:	e9 2e fc ff ff       	jmp    8004a7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800879:	83 c4 4c             	add    $0x4c,%esp
  80087c:	5b                   	pop    %ebx
  80087d:	5e                   	pop    %esi
  80087e:	5f                   	pop    %edi
  80087f:	5d                   	pop    %ebp
  800880:	c3                   	ret    

00800881 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800881:	55                   	push   %ebp
  800882:	89 e5                	mov    %esp,%ebp
  800884:	83 ec 28             	sub    $0x28,%esp
  800887:	8b 45 08             	mov    0x8(%ebp),%eax
  80088a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80088d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800890:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800894:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800897:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80089e:	85 d2                	test   %edx,%edx
  8008a0:	7e 30                	jle    8008d2 <vsnprintf+0x51>
  8008a2:	85 c0                	test   %eax,%eax
  8008a4:	74 2c                	je     8008d2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8008a6:	8b 45 14             	mov    0x14(%ebp),%eax
  8008a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8008ad:	8b 45 10             	mov    0x10(%ebp),%eax
  8008b0:	89 44 24 08          	mov    %eax,0x8(%esp)
  8008b4:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8008b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8008bb:	c7 04 24 3d 04 80 00 	movl   $0x80043d,(%esp)
  8008c2:	e8 bb fb ff ff       	call   800482 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8008c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8008ca:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8008cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8008d0:	eb 05                	jmp    8008d7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8008d2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8008d7:	c9                   	leave  
  8008d8:	c3                   	ret    

008008d9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8008d9:	55                   	push   %ebp
  8008da:	89 e5                	mov    %esp,%ebp
  8008dc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8008df:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8008e2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8008e6:	8b 45 10             	mov    0x10(%ebp),%eax
  8008e9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8008ed:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008f0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8008f4:	8b 45 08             	mov    0x8(%ebp),%eax
  8008f7:	89 04 24             	mov    %eax,(%esp)
  8008fa:	e8 82 ff ff ff       	call   800881 <vsnprintf>
	va_end(ap);

	return rc;
}
  8008ff:	c9                   	leave  
  800900:	c3                   	ret    
  800901:	66 90                	xchg   %ax,%ax
  800903:	66 90                	xchg   %ax,%ax
  800905:	66 90                	xchg   %ax,%ax
  800907:	66 90                	xchg   %ax,%ax
  800909:	66 90                	xchg   %ax,%ax
  80090b:	66 90                	xchg   %ax,%ax
  80090d:	66 90                	xchg   %ax,%ax
  80090f:	90                   	nop

00800910 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800910:	55                   	push   %ebp
  800911:	89 e5                	mov    %esp,%ebp
  800913:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800916:	80 3a 00             	cmpb   $0x0,(%edx)
  800919:	74 10                	je     80092b <strlen+0x1b>
  80091b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800920:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800923:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800927:	75 f7                	jne    800920 <strlen+0x10>
  800929:	eb 05                	jmp    800930 <strlen+0x20>
  80092b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800930:	5d                   	pop    %ebp
  800931:	c3                   	ret    

00800932 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800932:	55                   	push   %ebp
  800933:	89 e5                	mov    %esp,%ebp
  800935:	53                   	push   %ebx
  800936:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800939:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80093c:	85 c9                	test   %ecx,%ecx
  80093e:	74 1c                	je     80095c <strnlen+0x2a>
  800940:	80 3b 00             	cmpb   $0x0,(%ebx)
  800943:	74 1e                	je     800963 <strnlen+0x31>
  800945:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80094a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80094c:	39 ca                	cmp    %ecx,%edx
  80094e:	74 18                	je     800968 <strnlen+0x36>
  800950:	83 c2 01             	add    $0x1,%edx
  800953:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800958:	75 f0                	jne    80094a <strnlen+0x18>
  80095a:	eb 0c                	jmp    800968 <strnlen+0x36>
  80095c:	b8 00 00 00 00       	mov    $0x0,%eax
  800961:	eb 05                	jmp    800968 <strnlen+0x36>
  800963:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800968:	5b                   	pop    %ebx
  800969:	5d                   	pop    %ebp
  80096a:	c3                   	ret    

0080096b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80096b:	55                   	push   %ebp
  80096c:	89 e5                	mov    %esp,%ebp
  80096e:	53                   	push   %ebx
  80096f:	8b 45 08             	mov    0x8(%ebp),%eax
  800972:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800975:	89 c2                	mov    %eax,%edx
  800977:	0f b6 19             	movzbl (%ecx),%ebx
  80097a:	88 1a                	mov    %bl,(%edx)
  80097c:	83 c2 01             	add    $0x1,%edx
  80097f:	83 c1 01             	add    $0x1,%ecx
  800982:	84 db                	test   %bl,%bl
  800984:	75 f1                	jne    800977 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800986:	5b                   	pop    %ebx
  800987:	5d                   	pop    %ebp
  800988:	c3                   	ret    

00800989 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800989:	55                   	push   %ebp
  80098a:	89 e5                	mov    %esp,%ebp
  80098c:	53                   	push   %ebx
  80098d:	83 ec 08             	sub    $0x8,%esp
  800990:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800993:	89 1c 24             	mov    %ebx,(%esp)
  800996:	e8 75 ff ff ff       	call   800910 <strlen>
	strcpy(dst + len, src);
  80099b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80099e:	89 54 24 04          	mov    %edx,0x4(%esp)
  8009a2:	01 d8                	add    %ebx,%eax
  8009a4:	89 04 24             	mov    %eax,(%esp)
  8009a7:	e8 bf ff ff ff       	call   80096b <strcpy>
	return dst;
}
  8009ac:	89 d8                	mov    %ebx,%eax
  8009ae:	83 c4 08             	add    $0x8,%esp
  8009b1:	5b                   	pop    %ebx
  8009b2:	5d                   	pop    %ebp
  8009b3:	c3                   	ret    

008009b4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8009b4:	55                   	push   %ebp
  8009b5:	89 e5                	mov    %esp,%ebp
  8009b7:	56                   	push   %esi
  8009b8:	53                   	push   %ebx
  8009b9:	8b 75 08             	mov    0x8(%ebp),%esi
  8009bc:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009bf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8009c2:	85 db                	test   %ebx,%ebx
  8009c4:	74 16                	je     8009dc <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  8009c6:	01 f3                	add    %esi,%ebx
  8009c8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  8009ca:	0f b6 02             	movzbl (%edx),%eax
  8009cd:	88 01                	mov    %al,(%ecx)
  8009cf:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8009d2:	80 3a 01             	cmpb   $0x1,(%edx)
  8009d5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8009d8:	39 d9                	cmp    %ebx,%ecx
  8009da:	75 ee                	jne    8009ca <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8009dc:	89 f0                	mov    %esi,%eax
  8009de:	5b                   	pop    %ebx
  8009df:	5e                   	pop    %esi
  8009e0:	5d                   	pop    %ebp
  8009e1:	c3                   	ret    

008009e2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8009e2:	55                   	push   %ebp
  8009e3:	89 e5                	mov    %esp,%ebp
  8009e5:	57                   	push   %edi
  8009e6:	56                   	push   %esi
  8009e7:	53                   	push   %ebx
  8009e8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009eb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8009ee:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8009f1:	89 f8                	mov    %edi,%eax
  8009f3:	85 f6                	test   %esi,%esi
  8009f5:	74 33                	je     800a2a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  8009f7:	83 fe 01             	cmp    $0x1,%esi
  8009fa:	74 25                	je     800a21 <strlcpy+0x3f>
  8009fc:	0f b6 0b             	movzbl (%ebx),%ecx
  8009ff:	84 c9                	test   %cl,%cl
  800a01:	74 22                	je     800a25 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800a03:	83 ee 02             	sub    $0x2,%esi
  800a06:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800a0b:	88 08                	mov    %cl,(%eax)
  800a0d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800a10:	39 f2                	cmp    %esi,%edx
  800a12:	74 13                	je     800a27 <strlcpy+0x45>
  800a14:	83 c2 01             	add    $0x1,%edx
  800a17:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  800a1b:	84 c9                	test   %cl,%cl
  800a1d:	75 ec                	jne    800a0b <strlcpy+0x29>
  800a1f:	eb 06                	jmp    800a27 <strlcpy+0x45>
  800a21:	89 f8                	mov    %edi,%eax
  800a23:	eb 02                	jmp    800a27 <strlcpy+0x45>
  800a25:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800a27:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800a2a:	29 f8                	sub    %edi,%eax
}
  800a2c:	5b                   	pop    %ebx
  800a2d:	5e                   	pop    %esi
  800a2e:	5f                   	pop    %edi
  800a2f:	5d                   	pop    %ebp
  800a30:	c3                   	ret    

00800a31 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800a31:	55                   	push   %ebp
  800a32:	89 e5                	mov    %esp,%ebp
  800a34:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a37:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800a3a:	0f b6 01             	movzbl (%ecx),%eax
  800a3d:	84 c0                	test   %al,%al
  800a3f:	74 15                	je     800a56 <strcmp+0x25>
  800a41:	3a 02                	cmp    (%edx),%al
  800a43:	75 11                	jne    800a56 <strcmp+0x25>
		p++, q++;
  800a45:	83 c1 01             	add    $0x1,%ecx
  800a48:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800a4b:	0f b6 01             	movzbl (%ecx),%eax
  800a4e:	84 c0                	test   %al,%al
  800a50:	74 04                	je     800a56 <strcmp+0x25>
  800a52:	3a 02                	cmp    (%edx),%al
  800a54:	74 ef                	je     800a45 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800a56:	0f b6 c0             	movzbl %al,%eax
  800a59:	0f b6 12             	movzbl (%edx),%edx
  800a5c:	29 d0                	sub    %edx,%eax
}
  800a5e:	5d                   	pop    %ebp
  800a5f:	c3                   	ret    

00800a60 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800a60:	55                   	push   %ebp
  800a61:	89 e5                	mov    %esp,%ebp
  800a63:	56                   	push   %esi
  800a64:	53                   	push   %ebx
  800a65:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a68:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a6b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800a6e:	85 f6                	test   %esi,%esi
  800a70:	74 29                	je     800a9b <strncmp+0x3b>
  800a72:	0f b6 03             	movzbl (%ebx),%eax
  800a75:	84 c0                	test   %al,%al
  800a77:	74 30                	je     800aa9 <strncmp+0x49>
  800a79:	3a 02                	cmp    (%edx),%al
  800a7b:	75 2c                	jne    800aa9 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800a7d:	8d 43 01             	lea    0x1(%ebx),%eax
  800a80:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800a82:	89 c3                	mov    %eax,%ebx
  800a84:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800a87:	39 f0                	cmp    %esi,%eax
  800a89:	74 17                	je     800aa2 <strncmp+0x42>
  800a8b:	0f b6 08             	movzbl (%eax),%ecx
  800a8e:	84 c9                	test   %cl,%cl
  800a90:	74 17                	je     800aa9 <strncmp+0x49>
  800a92:	83 c0 01             	add    $0x1,%eax
  800a95:	3a 0a                	cmp    (%edx),%cl
  800a97:	74 e9                	je     800a82 <strncmp+0x22>
  800a99:	eb 0e                	jmp    800aa9 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a9b:	b8 00 00 00 00       	mov    $0x0,%eax
  800aa0:	eb 0f                	jmp    800ab1 <strncmp+0x51>
  800aa2:	b8 00 00 00 00       	mov    $0x0,%eax
  800aa7:	eb 08                	jmp    800ab1 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800aa9:	0f b6 03             	movzbl (%ebx),%eax
  800aac:	0f b6 12             	movzbl (%edx),%edx
  800aaf:	29 d0                	sub    %edx,%eax
}
  800ab1:	5b                   	pop    %ebx
  800ab2:	5e                   	pop    %esi
  800ab3:	5d                   	pop    %ebp
  800ab4:	c3                   	ret    

00800ab5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800ab5:	55                   	push   %ebp
  800ab6:	89 e5                	mov    %esp,%ebp
  800ab8:	53                   	push   %ebx
  800ab9:	8b 45 08             	mov    0x8(%ebp),%eax
  800abc:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800abf:	0f b6 18             	movzbl (%eax),%ebx
  800ac2:	84 db                	test   %bl,%bl
  800ac4:	74 1d                	je     800ae3 <strchr+0x2e>
  800ac6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800ac8:	38 d3                	cmp    %dl,%bl
  800aca:	75 06                	jne    800ad2 <strchr+0x1d>
  800acc:	eb 1a                	jmp    800ae8 <strchr+0x33>
  800ace:	38 ca                	cmp    %cl,%dl
  800ad0:	74 16                	je     800ae8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800ad2:	83 c0 01             	add    $0x1,%eax
  800ad5:	0f b6 10             	movzbl (%eax),%edx
  800ad8:	84 d2                	test   %dl,%dl
  800ada:	75 f2                	jne    800ace <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800adc:	b8 00 00 00 00       	mov    $0x0,%eax
  800ae1:	eb 05                	jmp    800ae8 <strchr+0x33>
  800ae3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ae8:	5b                   	pop    %ebx
  800ae9:	5d                   	pop    %ebp
  800aea:	c3                   	ret    

00800aeb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800aeb:	55                   	push   %ebp
  800aec:	89 e5                	mov    %esp,%ebp
  800aee:	53                   	push   %ebx
  800aef:	8b 45 08             	mov    0x8(%ebp),%eax
  800af2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800af5:	0f b6 18             	movzbl (%eax),%ebx
  800af8:	84 db                	test   %bl,%bl
  800afa:	74 16                	je     800b12 <strfind+0x27>
  800afc:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800afe:	38 d3                	cmp    %dl,%bl
  800b00:	75 06                	jne    800b08 <strfind+0x1d>
  800b02:	eb 0e                	jmp    800b12 <strfind+0x27>
  800b04:	38 ca                	cmp    %cl,%dl
  800b06:	74 0a                	je     800b12 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800b08:	83 c0 01             	add    $0x1,%eax
  800b0b:	0f b6 10             	movzbl (%eax),%edx
  800b0e:	84 d2                	test   %dl,%dl
  800b10:	75 f2                	jne    800b04 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800b12:	5b                   	pop    %ebx
  800b13:	5d                   	pop    %ebp
  800b14:	c3                   	ret    

00800b15 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800b15:	55                   	push   %ebp
  800b16:	89 e5                	mov    %esp,%ebp
  800b18:	83 ec 0c             	sub    $0xc,%esp
  800b1b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b1e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b21:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800b24:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b27:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b2a:	85 c9                	test   %ecx,%ecx
  800b2c:	74 36                	je     800b64 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b2e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b34:	75 28                	jne    800b5e <memset+0x49>
  800b36:	f6 c1 03             	test   $0x3,%cl
  800b39:	75 23                	jne    800b5e <memset+0x49>
		c &= 0xFF;
  800b3b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b3f:	89 d3                	mov    %edx,%ebx
  800b41:	c1 e3 08             	shl    $0x8,%ebx
  800b44:	89 d6                	mov    %edx,%esi
  800b46:	c1 e6 18             	shl    $0x18,%esi
  800b49:	89 d0                	mov    %edx,%eax
  800b4b:	c1 e0 10             	shl    $0x10,%eax
  800b4e:	09 f0                	or     %esi,%eax
  800b50:	09 c2                	or     %eax,%edx
  800b52:	89 d0                	mov    %edx,%eax
  800b54:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800b56:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800b59:	fc                   	cld    
  800b5a:	f3 ab                	rep stos %eax,%es:(%edi)
  800b5c:	eb 06                	jmp    800b64 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b5e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b61:	fc                   	cld    
  800b62:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800b64:	89 f8                	mov    %edi,%eax
  800b66:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b69:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b6c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b6f:	89 ec                	mov    %ebp,%esp
  800b71:	5d                   	pop    %ebp
  800b72:	c3                   	ret    

00800b73 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b73:	55                   	push   %ebp
  800b74:	89 e5                	mov    %esp,%ebp
  800b76:	83 ec 08             	sub    $0x8,%esp
  800b79:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b7c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800b7f:	8b 45 08             	mov    0x8(%ebp),%eax
  800b82:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b85:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b88:	39 c6                	cmp    %eax,%esi
  800b8a:	73 36                	jae    800bc2 <memmove+0x4f>
  800b8c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b8f:	39 d0                	cmp    %edx,%eax
  800b91:	73 2f                	jae    800bc2 <memmove+0x4f>
		s += n;
		d += n;
  800b93:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b96:	f6 c2 03             	test   $0x3,%dl
  800b99:	75 1b                	jne    800bb6 <memmove+0x43>
  800b9b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800ba1:	75 13                	jne    800bb6 <memmove+0x43>
  800ba3:	f6 c1 03             	test   $0x3,%cl
  800ba6:	75 0e                	jne    800bb6 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800ba8:	83 ef 04             	sub    $0x4,%edi
  800bab:	8d 72 fc             	lea    -0x4(%edx),%esi
  800bae:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800bb1:	fd                   	std    
  800bb2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bb4:	eb 09                	jmp    800bbf <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800bb6:	83 ef 01             	sub    $0x1,%edi
  800bb9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800bbc:	fd                   	std    
  800bbd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800bbf:	fc                   	cld    
  800bc0:	eb 20                	jmp    800be2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bc2:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800bc8:	75 13                	jne    800bdd <memmove+0x6a>
  800bca:	a8 03                	test   $0x3,%al
  800bcc:	75 0f                	jne    800bdd <memmove+0x6a>
  800bce:	f6 c1 03             	test   $0x3,%cl
  800bd1:	75 0a                	jne    800bdd <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800bd3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800bd6:	89 c7                	mov    %eax,%edi
  800bd8:	fc                   	cld    
  800bd9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bdb:	eb 05                	jmp    800be2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800bdd:	89 c7                	mov    %eax,%edi
  800bdf:	fc                   	cld    
  800be0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800be2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800be5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800be8:	89 ec                	mov    %ebp,%esp
  800bea:	5d                   	pop    %ebp
  800beb:	c3                   	ret    

00800bec <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800bec:	55                   	push   %ebp
  800bed:	89 e5                	mov    %esp,%ebp
  800bef:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800bf2:	8b 45 10             	mov    0x10(%ebp),%eax
  800bf5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800bf9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800bfc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c00:	8b 45 08             	mov    0x8(%ebp),%eax
  800c03:	89 04 24             	mov    %eax,(%esp)
  800c06:	e8 68 ff ff ff       	call   800b73 <memmove>
}
  800c0b:	c9                   	leave  
  800c0c:	c3                   	ret    

00800c0d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800c0d:	55                   	push   %ebp
  800c0e:	89 e5                	mov    %esp,%ebp
  800c10:	57                   	push   %edi
  800c11:	56                   	push   %esi
  800c12:	53                   	push   %ebx
  800c13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800c16:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c19:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c1c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800c1f:	85 c0                	test   %eax,%eax
  800c21:	74 36                	je     800c59 <memcmp+0x4c>
		if (*s1 != *s2)
  800c23:	0f b6 03             	movzbl (%ebx),%eax
  800c26:	0f b6 0e             	movzbl (%esi),%ecx
  800c29:	38 c8                	cmp    %cl,%al
  800c2b:	75 17                	jne    800c44 <memcmp+0x37>
  800c2d:	ba 00 00 00 00       	mov    $0x0,%edx
  800c32:	eb 1a                	jmp    800c4e <memcmp+0x41>
  800c34:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800c39:	83 c2 01             	add    $0x1,%edx
  800c3c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800c40:	38 c8                	cmp    %cl,%al
  800c42:	74 0a                	je     800c4e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800c44:	0f b6 c0             	movzbl %al,%eax
  800c47:	0f b6 c9             	movzbl %cl,%ecx
  800c4a:	29 c8                	sub    %ecx,%eax
  800c4c:	eb 10                	jmp    800c5e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c4e:	39 fa                	cmp    %edi,%edx
  800c50:	75 e2                	jne    800c34 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c52:	b8 00 00 00 00       	mov    $0x0,%eax
  800c57:	eb 05                	jmp    800c5e <memcmp+0x51>
  800c59:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c5e:	5b                   	pop    %ebx
  800c5f:	5e                   	pop    %esi
  800c60:	5f                   	pop    %edi
  800c61:	5d                   	pop    %ebp
  800c62:	c3                   	ret    

00800c63 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c63:	55                   	push   %ebp
  800c64:	89 e5                	mov    %esp,%ebp
  800c66:	53                   	push   %ebx
  800c67:	8b 45 08             	mov    0x8(%ebp),%eax
  800c6a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800c6d:	89 c2                	mov    %eax,%edx
  800c6f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800c72:	39 d0                	cmp    %edx,%eax
  800c74:	73 13                	jae    800c89 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c76:	89 d9                	mov    %ebx,%ecx
  800c78:	38 18                	cmp    %bl,(%eax)
  800c7a:	75 06                	jne    800c82 <memfind+0x1f>
  800c7c:	eb 0b                	jmp    800c89 <memfind+0x26>
  800c7e:	38 08                	cmp    %cl,(%eax)
  800c80:	74 07                	je     800c89 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c82:	83 c0 01             	add    $0x1,%eax
  800c85:	39 d0                	cmp    %edx,%eax
  800c87:	75 f5                	jne    800c7e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c89:	5b                   	pop    %ebx
  800c8a:	5d                   	pop    %ebp
  800c8b:	c3                   	ret    

00800c8c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c8c:	55                   	push   %ebp
  800c8d:	89 e5                	mov    %esp,%ebp
  800c8f:	57                   	push   %edi
  800c90:	56                   	push   %esi
  800c91:	53                   	push   %ebx
  800c92:	83 ec 04             	sub    $0x4,%esp
  800c95:	8b 55 08             	mov    0x8(%ebp),%edx
  800c98:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c9b:	0f b6 02             	movzbl (%edx),%eax
  800c9e:	3c 09                	cmp    $0x9,%al
  800ca0:	74 04                	je     800ca6 <strtol+0x1a>
  800ca2:	3c 20                	cmp    $0x20,%al
  800ca4:	75 0e                	jne    800cb4 <strtol+0x28>
		s++;
  800ca6:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ca9:	0f b6 02             	movzbl (%edx),%eax
  800cac:	3c 09                	cmp    $0x9,%al
  800cae:	74 f6                	je     800ca6 <strtol+0x1a>
  800cb0:	3c 20                	cmp    $0x20,%al
  800cb2:	74 f2                	je     800ca6 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800cb4:	3c 2b                	cmp    $0x2b,%al
  800cb6:	75 0a                	jne    800cc2 <strtol+0x36>
		s++;
  800cb8:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800cbb:	bf 00 00 00 00       	mov    $0x0,%edi
  800cc0:	eb 10                	jmp    800cd2 <strtol+0x46>
  800cc2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800cc7:	3c 2d                	cmp    $0x2d,%al
  800cc9:	75 07                	jne    800cd2 <strtol+0x46>
		s++, neg = 1;
  800ccb:	83 c2 01             	add    $0x1,%edx
  800cce:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800cd2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800cd8:	75 15                	jne    800cef <strtol+0x63>
  800cda:	80 3a 30             	cmpb   $0x30,(%edx)
  800cdd:	75 10                	jne    800cef <strtol+0x63>
  800cdf:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800ce3:	75 0a                	jne    800cef <strtol+0x63>
		s += 2, base = 16;
  800ce5:	83 c2 02             	add    $0x2,%edx
  800ce8:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ced:	eb 10                	jmp    800cff <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800cef:	85 db                	test   %ebx,%ebx
  800cf1:	75 0c                	jne    800cff <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800cf3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800cf5:	80 3a 30             	cmpb   $0x30,(%edx)
  800cf8:	75 05                	jne    800cff <strtol+0x73>
		s++, base = 8;
  800cfa:	83 c2 01             	add    $0x1,%edx
  800cfd:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800cff:	b8 00 00 00 00       	mov    $0x0,%eax
  800d04:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800d07:	0f b6 0a             	movzbl (%edx),%ecx
  800d0a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800d0d:	89 f3                	mov    %esi,%ebx
  800d0f:	80 fb 09             	cmp    $0x9,%bl
  800d12:	77 08                	ja     800d1c <strtol+0x90>
			dig = *s - '0';
  800d14:	0f be c9             	movsbl %cl,%ecx
  800d17:	83 e9 30             	sub    $0x30,%ecx
  800d1a:	eb 22                	jmp    800d3e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800d1c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800d1f:	89 f3                	mov    %esi,%ebx
  800d21:	80 fb 19             	cmp    $0x19,%bl
  800d24:	77 08                	ja     800d2e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800d26:	0f be c9             	movsbl %cl,%ecx
  800d29:	83 e9 57             	sub    $0x57,%ecx
  800d2c:	eb 10                	jmp    800d3e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800d2e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800d31:	89 f3                	mov    %esi,%ebx
  800d33:	80 fb 19             	cmp    $0x19,%bl
  800d36:	77 16                	ja     800d4e <strtol+0xc2>
			dig = *s - 'A' + 10;
  800d38:	0f be c9             	movsbl %cl,%ecx
  800d3b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800d3e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800d41:	7d 0f                	jge    800d52 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800d43:	83 c2 01             	add    $0x1,%edx
  800d46:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800d4a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800d4c:	eb b9                	jmp    800d07 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800d4e:	89 c1                	mov    %eax,%ecx
  800d50:	eb 02                	jmp    800d54 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800d52:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800d54:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d58:	74 05                	je     800d5f <strtol+0xd3>
		*endptr = (char *) s;
  800d5a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800d5d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800d5f:	89 ca                	mov    %ecx,%edx
  800d61:	f7 da                	neg    %edx
  800d63:	85 ff                	test   %edi,%edi
  800d65:	0f 45 c2             	cmovne %edx,%eax
}
  800d68:	83 c4 04             	add    $0x4,%esp
  800d6b:	5b                   	pop    %ebx
  800d6c:	5e                   	pop    %esi
  800d6d:	5f                   	pop    %edi
  800d6e:	5d                   	pop    %ebp
  800d6f:	c3                   	ret    

00800d70 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800d70:	55                   	push   %ebp
  800d71:	89 e5                	mov    %esp,%ebp
  800d73:	83 ec 0c             	sub    $0xc,%esp
  800d76:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d79:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d7c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d7f:	b8 00 00 00 00       	mov    $0x0,%eax
  800d84:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d87:	8b 55 08             	mov    0x8(%ebp),%edx
  800d8a:	89 c3                	mov    %eax,%ebx
  800d8c:	89 c7                	mov    %eax,%edi
  800d8e:	89 c6                	mov    %eax,%esi
  800d90:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800d92:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800d95:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800d98:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800d9b:	89 ec                	mov    %ebp,%esp
  800d9d:	5d                   	pop    %ebp
  800d9e:	c3                   	ret    

00800d9f <sys_cgetc>:

int
sys_cgetc(void)
{
  800d9f:	55                   	push   %ebp
  800da0:	89 e5                	mov    %esp,%ebp
  800da2:	83 ec 0c             	sub    $0xc,%esp
  800da5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800da8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800dab:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dae:	ba 00 00 00 00       	mov    $0x0,%edx
  800db3:	b8 01 00 00 00       	mov    $0x1,%eax
  800db8:	89 d1                	mov    %edx,%ecx
  800dba:	89 d3                	mov    %edx,%ebx
  800dbc:	89 d7                	mov    %edx,%edi
  800dbe:	89 d6                	mov    %edx,%esi
  800dc0:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800dc2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800dc5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800dc8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800dcb:	89 ec                	mov    %ebp,%esp
  800dcd:	5d                   	pop    %ebp
  800dce:	c3                   	ret    

00800dcf <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800dcf:	55                   	push   %ebp
  800dd0:	89 e5                	mov    %esp,%ebp
  800dd2:	83 ec 38             	sub    $0x38,%esp
  800dd5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800dd8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ddb:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dde:	b9 00 00 00 00       	mov    $0x0,%ecx
  800de3:	b8 03 00 00 00       	mov    $0x3,%eax
  800de8:	8b 55 08             	mov    0x8(%ebp),%edx
  800deb:	89 cb                	mov    %ecx,%ebx
  800ded:	89 cf                	mov    %ecx,%edi
  800def:	89 ce                	mov    %ecx,%esi
  800df1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800df3:	85 c0                	test   %eax,%eax
  800df5:	7e 28                	jle    800e1f <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800df7:	89 44 24 10          	mov    %eax,0x10(%esp)
  800dfb:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800e02:	00 
  800e03:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800e0a:	00 
  800e0b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e12:	00 
  800e13:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800e1a:	e8 b9 f3 ff ff       	call   8001d8 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800e1f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e22:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e25:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e28:	89 ec                	mov    %ebp,%esp
  800e2a:	5d                   	pop    %ebp
  800e2b:	c3                   	ret    

00800e2c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800e2c:	55                   	push   %ebp
  800e2d:	89 e5                	mov    %esp,%ebp
  800e2f:	83 ec 0c             	sub    $0xc,%esp
  800e32:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e35:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e38:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e3b:	ba 00 00 00 00       	mov    $0x0,%edx
  800e40:	b8 02 00 00 00       	mov    $0x2,%eax
  800e45:	89 d1                	mov    %edx,%ecx
  800e47:	89 d3                	mov    %edx,%ebx
  800e49:	89 d7                	mov    %edx,%edi
  800e4b:	89 d6                	mov    %edx,%esi
  800e4d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800e4f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e52:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e55:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e58:	89 ec                	mov    %ebp,%esp
  800e5a:	5d                   	pop    %ebp
  800e5b:	c3                   	ret    

00800e5c <sys_yield>:

void
sys_yield(void)
{
  800e5c:	55                   	push   %ebp
  800e5d:	89 e5                	mov    %esp,%ebp
  800e5f:	83 ec 0c             	sub    $0xc,%esp
  800e62:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e65:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e68:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e6b:	ba 00 00 00 00       	mov    $0x0,%edx
  800e70:	b8 0a 00 00 00       	mov    $0xa,%eax
  800e75:	89 d1                	mov    %edx,%ecx
  800e77:	89 d3                	mov    %edx,%ebx
  800e79:	89 d7                	mov    %edx,%edi
  800e7b:	89 d6                	mov    %edx,%esi
  800e7d:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800e7f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e82:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e85:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e88:	89 ec                	mov    %ebp,%esp
  800e8a:	5d                   	pop    %ebp
  800e8b:	c3                   	ret    

00800e8c <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800e8c:	55                   	push   %ebp
  800e8d:	89 e5                	mov    %esp,%ebp
  800e8f:	83 ec 38             	sub    $0x38,%esp
  800e92:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e95:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e98:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e9b:	be 00 00 00 00       	mov    $0x0,%esi
  800ea0:	b8 04 00 00 00       	mov    $0x4,%eax
  800ea5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ea8:	8b 55 08             	mov    0x8(%ebp),%edx
  800eab:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800eae:	89 f7                	mov    %esi,%edi
  800eb0:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800eb2:	85 c0                	test   %eax,%eax
  800eb4:	7e 28                	jle    800ede <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  800eb6:	89 44 24 10          	mov    %eax,0x10(%esp)
  800eba:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800ec1:	00 
  800ec2:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800ec9:	00 
  800eca:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ed1:	00 
  800ed2:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800ed9:	e8 fa f2 ff ff       	call   8001d8 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800ede:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800ee1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ee4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ee7:	89 ec                	mov    %ebp,%esp
  800ee9:	5d                   	pop    %ebp
  800eea:	c3                   	ret    

00800eeb <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800eeb:	55                   	push   %ebp
  800eec:	89 e5                	mov    %esp,%ebp
  800eee:	83 ec 38             	sub    $0x38,%esp
  800ef1:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ef4:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ef7:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800efa:	b8 05 00 00 00       	mov    $0x5,%eax
  800eff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f02:	8b 55 08             	mov    0x8(%ebp),%edx
  800f05:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800f08:	8b 7d 14             	mov    0x14(%ebp),%edi
  800f0b:	8b 75 18             	mov    0x18(%ebp),%esi
  800f0e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f10:	85 c0                	test   %eax,%eax
  800f12:	7e 28                	jle    800f3c <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f14:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f18:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800f1f:	00 
  800f20:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800f27:	00 
  800f28:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f2f:	00 
  800f30:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800f37:	e8 9c f2 ff ff       	call   8001d8 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800f3c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f3f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f42:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f45:	89 ec                	mov    %ebp,%esp
  800f47:	5d                   	pop    %ebp
  800f48:	c3                   	ret    

00800f49 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800f49:	55                   	push   %ebp
  800f4a:	89 e5                	mov    %esp,%ebp
  800f4c:	83 ec 38             	sub    $0x38,%esp
  800f4f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f52:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f55:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f58:	bb 00 00 00 00       	mov    $0x0,%ebx
  800f5d:	b8 06 00 00 00       	mov    $0x6,%eax
  800f62:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f65:	8b 55 08             	mov    0x8(%ebp),%edx
  800f68:	89 df                	mov    %ebx,%edi
  800f6a:	89 de                	mov    %ebx,%esi
  800f6c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f6e:	85 c0                	test   %eax,%eax
  800f70:	7e 28                	jle    800f9a <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f72:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f76:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800f7d:	00 
  800f7e:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800f85:	00 
  800f86:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f8d:	00 
  800f8e:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800f95:	e8 3e f2 ff ff       	call   8001d8 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800f9a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f9d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800fa0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800fa3:	89 ec                	mov    %ebp,%esp
  800fa5:	5d                   	pop    %ebp
  800fa6:	c3                   	ret    

00800fa7 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800fa7:	55                   	push   %ebp
  800fa8:	89 e5                	mov    %esp,%ebp
  800faa:	83 ec 38             	sub    $0x38,%esp
  800fad:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800fb0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800fb3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800fb6:	bb 00 00 00 00       	mov    $0x0,%ebx
  800fbb:	b8 08 00 00 00       	mov    $0x8,%eax
  800fc0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800fc3:	8b 55 08             	mov    0x8(%ebp),%edx
  800fc6:	89 df                	mov    %ebx,%edi
  800fc8:	89 de                	mov    %ebx,%esi
  800fca:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800fcc:	85 c0                	test   %eax,%eax
  800fce:	7e 28                	jle    800ff8 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800fd0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fd4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800fdb:	00 
  800fdc:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  800fe3:	00 
  800fe4:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800feb:	00 
  800fec:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  800ff3:	e8 e0 f1 ff ff       	call   8001d8 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800ff8:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800ffb:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ffe:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801001:	89 ec                	mov    %ebp,%esp
  801003:	5d                   	pop    %ebp
  801004:	c3                   	ret    

00801005 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  801005:	55                   	push   %ebp
  801006:	89 e5                	mov    %esp,%ebp
  801008:	83 ec 38             	sub    $0x38,%esp
  80100b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80100e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  801011:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801014:	bb 00 00 00 00       	mov    $0x0,%ebx
  801019:	b8 09 00 00 00       	mov    $0x9,%eax
  80101e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801021:	8b 55 08             	mov    0x8(%ebp),%edx
  801024:	89 df                	mov    %ebx,%edi
  801026:	89 de                	mov    %ebx,%esi
  801028:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80102a:	85 c0                	test   %eax,%eax
  80102c:	7e 28                	jle    801056 <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  80102e:	89 44 24 10          	mov    %eax,0x10(%esp)
  801032:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  801039:	00 
  80103a:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  801041:	00 
  801042:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  801049:	00 
  80104a:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  801051:	e8 82 f1 ff ff       	call   8001d8 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  801056:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  801059:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80105c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80105f:	89 ec                	mov    %ebp,%esp
  801061:	5d                   	pop    %ebp
  801062:	c3                   	ret    

00801063 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  801063:	55                   	push   %ebp
  801064:	89 e5                	mov    %esp,%ebp
  801066:	83 ec 0c             	sub    $0xc,%esp
  801069:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80106c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80106f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801072:	be 00 00 00 00       	mov    $0x0,%esi
  801077:	b8 0b 00 00 00       	mov    $0xb,%eax
  80107c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80107f:	8b 55 08             	mov    0x8(%ebp),%edx
  801082:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801085:	8b 7d 14             	mov    0x14(%ebp),%edi
  801088:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  80108a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80108d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  801090:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801093:	89 ec                	mov    %ebp,%esp
  801095:	5d                   	pop    %ebp
  801096:	c3                   	ret    

00801097 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  801097:	55                   	push   %ebp
  801098:	89 e5                	mov    %esp,%ebp
  80109a:	83 ec 38             	sub    $0x38,%esp
  80109d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8010a0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8010a3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8010a6:	b9 00 00 00 00       	mov    $0x0,%ecx
  8010ab:	b8 0c 00 00 00       	mov    $0xc,%eax
  8010b0:	8b 55 08             	mov    0x8(%ebp),%edx
  8010b3:	89 cb                	mov    %ecx,%ebx
  8010b5:	89 cf                	mov    %ecx,%edi
  8010b7:	89 ce                	mov    %ecx,%esi
  8010b9:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8010bb:	85 c0                	test   %eax,%eax
  8010bd:	7e 28                	jle    8010e7 <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  8010bf:	89 44 24 10          	mov    %eax,0x10(%esp)
  8010c3:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  8010ca:	00 
  8010cb:	c7 44 24 08 64 17 80 	movl   $0x801764,0x8(%esp)
  8010d2:	00 
  8010d3:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8010da:	00 
  8010db:	c7 04 24 81 17 80 00 	movl   $0x801781,(%esp)
  8010e2:	e8 f1 f0 ff ff       	call   8001d8 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  8010e7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8010ea:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8010ed:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8010f0:	89 ec                	mov    %ebp,%esp
  8010f2:	5d                   	pop    %ebp
  8010f3:	c3                   	ret    

008010f4 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  8010f4:	55                   	push   %ebp
  8010f5:	89 e5                	mov    %esp,%ebp
  8010f7:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("fork not implemented");
  8010fa:	c7 44 24 08 9b 17 80 	movl   $0x80179b,0x8(%esp)
  801101:	00 
  801102:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
  801109:	00 
  80110a:	c7 04 24 8f 17 80 00 	movl   $0x80178f,(%esp)
  801111:	e8 c2 f0 ff ff       	call   8001d8 <_panic>

00801116 <sfork>:
}

// Challenge!
int
sfork(void)
{
  801116:	55                   	push   %ebp
  801117:	89 e5                	mov    %esp,%ebp
  801119:	83 ec 18             	sub    $0x18,%esp
	panic("sfork not implemented");
  80111c:	c7 44 24 08 9a 17 80 	movl   $0x80179a,0x8(%esp)
  801123:	00 
  801124:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  80112b:	00 
  80112c:	c7 04 24 8f 17 80 00 	movl   $0x80178f,(%esp)
  801133:	e8 a0 f0 ff ff       	call   8001d8 <_panic>

00801138 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  801138:	55                   	push   %ebp
  801139:	89 e5                	mov    %esp,%ebp
  80113b:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("ipc_recv not implemented");
  80113e:	c7 44 24 08 b0 17 80 	movl   $0x8017b0,0x8(%esp)
  801145:	00 
  801146:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
  80114d:	00 
  80114e:	c7 04 24 c9 17 80 00 	movl   $0x8017c9,(%esp)
  801155:	e8 7e f0 ff ff       	call   8001d8 <_panic>

0080115a <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  80115a:	55                   	push   %ebp
  80115b:	89 e5                	mov    %esp,%ebp
  80115d:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("ipc_send not implemented");
  801160:	c7 44 24 08 d3 17 80 	movl   $0x8017d3,0x8(%esp)
  801167:	00 
  801168:	c7 44 24 04 2a 00 00 	movl   $0x2a,0x4(%esp)
  80116f:	00 
  801170:	c7 04 24 c9 17 80 00 	movl   $0x8017c9,(%esp)
  801177:	e8 5c f0 ff ff       	call   8001d8 <_panic>

0080117c <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  80117c:	55                   	push   %ebp
  80117d:	89 e5                	mov    %esp,%ebp
  80117f:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
		if (envs[i].env_type == type)
  801182:	a1 50 00 c0 ee       	mov    0xeec00050,%eax
  801187:	39 c8                	cmp    %ecx,%eax
  801189:	74 17                	je     8011a2 <ipc_find_env+0x26>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  80118b:	b8 01 00 00 00       	mov    $0x1,%eax
		if (envs[i].env_type == type)
  801190:	6b d0 7c             	imul   $0x7c,%eax,%edx
  801193:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  801199:	8b 52 50             	mov    0x50(%edx),%edx
  80119c:	39 ca                	cmp    %ecx,%edx
  80119e:	75 14                	jne    8011b4 <ipc_find_env+0x38>
  8011a0:	eb 05                	jmp    8011a7 <ipc_find_env+0x2b>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  8011a2:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
			return envs[i].env_id;
  8011a7:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8011aa:	05 08 00 c0 ee       	add    $0xeec00008,%eax
  8011af:	8b 40 40             	mov    0x40(%eax),%eax
  8011b2:	eb 0e                	jmp    8011c2 <ipc_find_env+0x46>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  8011b4:	83 c0 01             	add    $0x1,%eax
  8011b7:	3d 00 04 00 00       	cmp    $0x400,%eax
  8011bc:	75 d2                	jne    801190 <ipc_find_env+0x14>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  8011be:	66 b8 00 00          	mov    $0x0,%ax
}
  8011c2:	5d                   	pop    %ebp
  8011c3:	c3                   	ret    
  8011c4:	66 90                	xchg   %ax,%ax
  8011c6:	66 90                	xchg   %ax,%ax
  8011c8:	66 90                	xchg   %ax,%ax
  8011ca:	66 90                	xchg   %ax,%ax
  8011cc:	66 90                	xchg   %ax,%ax
  8011ce:	66 90                	xchg   %ax,%ax

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

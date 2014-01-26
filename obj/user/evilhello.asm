
obj/user/evilhello：     文件格式 elf32-i386


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
  80002c:	e8 1f 00 00 00       	call   800050 <libmain>
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
	// try to print the kernel entry point as a string!  mua ha ha!
	sys_cputs((char*)0xf010000c, 100);
  80003a:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  800041:	00 
  800042:	c7 04 24 0c 00 10 f0 	movl   $0xf010000c,(%esp)
  800049:	e8 4e 00 00 00       	call   80009c <sys_cputs>
}
  80004e:	c9                   	leave  
  80004f:	c3                   	ret    

00800050 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800050:	55                   	push   %ebp
  800051:	89 e5                	mov    %esp,%ebp
  800053:	83 ec 18             	sub    $0x18,%esp
  800056:	8b 45 08             	mov    0x8(%ebp),%eax
  800059:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80005c:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800063:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800066:	85 c0                	test   %eax,%eax
  800068:	7e 08                	jle    800072 <libmain+0x22>
		binaryname = argv[0];
  80006a:	8b 0a                	mov    (%edx),%ecx
  80006c:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800072:	89 54 24 04          	mov    %edx,0x4(%esp)
  800076:	89 04 24             	mov    %eax,(%esp)
  800079:	e8 b6 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  80007e:	e8 05 00 00 00       	call   800088 <exit>
}
  800083:	c9                   	leave  
  800084:	c3                   	ret    
  800085:	66 90                	xchg   %ax,%ax
  800087:	90                   	nop

00800088 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800088:	55                   	push   %ebp
  800089:	89 e5                	mov    %esp,%ebp
  80008b:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80008e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800095:	e8 61 00 00 00       	call   8000fb <sys_env_destroy>
}
  80009a:	c9                   	leave  
  80009b:	c3                   	ret    

0080009c <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  80009c:	55                   	push   %ebp
  80009d:	89 e5                	mov    %esp,%ebp
  80009f:	83 ec 0c             	sub    $0xc,%esp
  8000a2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000a5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000a8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000ab:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000b3:	8b 55 08             	mov    0x8(%ebp),%edx
  8000b6:	89 c3                	mov    %eax,%ebx
  8000b8:	89 c7                	mov    %eax,%edi
  8000ba:	89 c6                	mov    %eax,%esi
  8000bc:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000be:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000c1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000c4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000c7:	89 ec                	mov    %ebp,%esp
  8000c9:	5d                   	pop    %ebp
  8000ca:	c3                   	ret    

008000cb <sys_cgetc>:

int
sys_cgetc(void)
{
  8000cb:	55                   	push   %ebp
  8000cc:	89 e5                	mov    %esp,%ebp
  8000ce:	83 ec 0c             	sub    $0xc,%esp
  8000d1:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000d4:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000d7:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000da:	ba 00 00 00 00       	mov    $0x0,%edx
  8000df:	b8 01 00 00 00       	mov    $0x1,%eax
  8000e4:	89 d1                	mov    %edx,%ecx
  8000e6:	89 d3                	mov    %edx,%ebx
  8000e8:	89 d7                	mov    %edx,%edi
  8000ea:	89 d6                	mov    %edx,%esi
  8000ec:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000ee:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000f1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000f4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000f7:	89 ec                	mov    %ebp,%esp
  8000f9:	5d                   	pop    %ebp
  8000fa:	c3                   	ret    

008000fb <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000fb:	55                   	push   %ebp
  8000fc:	89 e5                	mov    %esp,%ebp
  8000fe:	83 ec 38             	sub    $0x38,%esp
  800101:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800104:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800107:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80010a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80010f:	b8 03 00 00 00       	mov    $0x3,%eax
  800114:	8b 55 08             	mov    0x8(%ebp),%edx
  800117:	89 cb                	mov    %ecx,%ebx
  800119:	89 cf                	mov    %ecx,%edi
  80011b:	89 ce                	mov    %ecx,%esi
  80011d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80011f:	85 c0                	test   %eax,%eax
  800121:	7e 28                	jle    80014b <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800123:	89 44 24 10          	mov    %eax,0x10(%esp)
  800127:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  80012e:	00 
  80012f:	c7 44 24 08 0a 10 80 	movl   $0x80100a,0x8(%esp)
  800136:	00 
  800137:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80013e:	00 
  80013f:	c7 04 24 27 10 80 00 	movl   $0x801027,(%esp)
  800146:	e8 3d 00 00 00       	call   800188 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80014b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80014e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800151:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800154:	89 ec                	mov    %ebp,%esp
  800156:	5d                   	pop    %ebp
  800157:	c3                   	ret    

00800158 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800158:	55                   	push   %ebp
  800159:	89 e5                	mov    %esp,%ebp
  80015b:	83 ec 0c             	sub    $0xc,%esp
  80015e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800161:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800164:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800167:	ba 00 00 00 00       	mov    $0x0,%edx
  80016c:	b8 02 00 00 00       	mov    $0x2,%eax
  800171:	89 d1                	mov    %edx,%ecx
  800173:	89 d3                	mov    %edx,%ebx
  800175:	89 d7                	mov    %edx,%edi
  800177:	89 d6                	mov    %edx,%esi
  800179:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80017b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80017e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800181:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800184:	89 ec                	mov    %ebp,%esp
  800186:	5d                   	pop    %ebp
  800187:	c3                   	ret    

00800188 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800188:	55                   	push   %ebp
  800189:	89 e5                	mov    %esp,%ebp
  80018b:	56                   	push   %esi
  80018c:	53                   	push   %ebx
  80018d:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800190:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800193:	a1 08 20 80 00       	mov    0x802008,%eax
  800198:	85 c0                	test   %eax,%eax
  80019a:	74 10                	je     8001ac <_panic+0x24>
		cprintf("%s: ", argv0);
  80019c:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001a0:	c7 04 24 35 10 80 00 	movl   $0x801035,(%esp)
  8001a7:	e8 ef 00 00 00       	call   80029b <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001ac:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8001b2:	e8 a1 ff ff ff       	call   800158 <sys_getenvid>
  8001b7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001ba:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001be:	8b 55 08             	mov    0x8(%ebp),%edx
  8001c1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001c5:	89 74 24 08          	mov    %esi,0x8(%esp)
  8001c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001cd:	c7 04 24 3c 10 80 00 	movl   $0x80103c,(%esp)
  8001d4:	e8 c2 00 00 00       	call   80029b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001d9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001dd:	8b 45 10             	mov    0x10(%ebp),%eax
  8001e0:	89 04 24             	mov    %eax,(%esp)
  8001e3:	e8 52 00 00 00       	call   80023a <vcprintf>
	cprintf("\n");
  8001e8:	c7 04 24 3a 10 80 00 	movl   $0x80103a,(%esp)
  8001ef:	e8 a7 00 00 00       	call   80029b <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001f4:	cc                   	int3   
  8001f5:	eb fd                	jmp    8001f4 <_panic+0x6c>
  8001f7:	90                   	nop

008001f8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001f8:	55                   	push   %ebp
  8001f9:	89 e5                	mov    %esp,%ebp
  8001fb:	53                   	push   %ebx
  8001fc:	83 ec 14             	sub    $0x14,%esp
  8001ff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800202:	8b 03                	mov    (%ebx),%eax
  800204:	8b 55 08             	mov    0x8(%ebp),%edx
  800207:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  80020b:	83 c0 01             	add    $0x1,%eax
  80020e:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800210:	3d ff 00 00 00       	cmp    $0xff,%eax
  800215:	75 19                	jne    800230 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800217:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80021e:	00 
  80021f:	8d 43 08             	lea    0x8(%ebx),%eax
  800222:	89 04 24             	mov    %eax,(%esp)
  800225:	e8 72 fe ff ff       	call   80009c <sys_cputs>
		b->idx = 0;
  80022a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800230:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800234:	83 c4 14             	add    $0x14,%esp
  800237:	5b                   	pop    %ebx
  800238:	5d                   	pop    %ebp
  800239:	c3                   	ret    

0080023a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80023a:	55                   	push   %ebp
  80023b:	89 e5                	mov    %esp,%ebp
  80023d:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800243:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80024a:	00 00 00 
	b.cnt = 0;
  80024d:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800254:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800257:	8b 45 0c             	mov    0xc(%ebp),%eax
  80025a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80025e:	8b 45 08             	mov    0x8(%ebp),%eax
  800261:	89 44 24 08          	mov    %eax,0x8(%esp)
  800265:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80026b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80026f:	c7 04 24 f8 01 80 00 	movl   $0x8001f8,(%esp)
  800276:	e8 b7 01 00 00       	call   800432 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80027b:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800281:	89 44 24 04          	mov    %eax,0x4(%esp)
  800285:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80028b:	89 04 24             	mov    %eax,(%esp)
  80028e:	e8 09 fe ff ff       	call   80009c <sys_cputs>

	return b.cnt;
}
  800293:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800299:	c9                   	leave  
  80029a:	c3                   	ret    

0080029b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80029b:	55                   	push   %ebp
  80029c:	89 e5                	mov    %esp,%ebp
  80029e:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002a1:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002a4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002a8:	8b 45 08             	mov    0x8(%ebp),%eax
  8002ab:	89 04 24             	mov    %eax,(%esp)
  8002ae:	e8 87 ff ff ff       	call   80023a <vcprintf>
	va_end(ap);

	return cnt;
}
  8002b3:	c9                   	leave  
  8002b4:	c3                   	ret    
  8002b5:	66 90                	xchg   %ax,%ax
  8002b7:	66 90                	xchg   %ax,%ax
  8002b9:	66 90                	xchg   %ax,%ax
  8002bb:	66 90                	xchg   %ax,%ax
  8002bd:	66 90                	xchg   %ax,%ax
  8002bf:	90                   	nop

008002c0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002c0:	55                   	push   %ebp
  8002c1:	89 e5                	mov    %esp,%ebp
  8002c3:	57                   	push   %edi
  8002c4:	56                   	push   %esi
  8002c5:	53                   	push   %ebx
  8002c6:	83 ec 4c             	sub    $0x4c,%esp
  8002c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8002cc:	89 d7                	mov    %edx,%edi
  8002ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8002d1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8002d4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002d7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002da:	b8 00 00 00 00       	mov    $0x0,%eax
  8002df:	39 d8                	cmp    %ebx,%eax
  8002e1:	72 17                	jb     8002fa <printnum+0x3a>
  8002e3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002e6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8002e9:	76 0f                	jbe    8002fa <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002eb:	8b 75 14             	mov    0x14(%ebp),%esi
  8002ee:	83 ee 01             	sub    $0x1,%esi
  8002f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8002f4:	85 f6                	test   %esi,%esi
  8002f6:	7f 63                	jg     80035b <printnum+0x9b>
  8002f8:	eb 75                	jmp    80036f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002fa:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8002fd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800301:	8b 45 14             	mov    0x14(%ebp),%eax
  800304:	83 e8 01             	sub    $0x1,%eax
  800307:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80030b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80030e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800312:	8b 44 24 08          	mov    0x8(%esp),%eax
  800316:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80031a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80031d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800320:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800327:	00 
  800328:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80032b:	89 1c 24             	mov    %ebx,(%esp)
  80032e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800331:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800335:	e8 e6 09 00 00       	call   800d20 <__udivdi3>
  80033a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80033d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800340:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800344:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800348:	89 04 24             	mov    %eax,(%esp)
  80034b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80034f:	89 fa                	mov    %edi,%edx
  800351:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800354:	e8 67 ff ff ff       	call   8002c0 <printnum>
  800359:	eb 14                	jmp    80036f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80035b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80035f:	8b 45 18             	mov    0x18(%ebp),%eax
  800362:	89 04 24             	mov    %eax,(%esp)
  800365:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800367:	83 ee 01             	sub    $0x1,%esi
  80036a:	75 ef                	jne    80035b <printnum+0x9b>
  80036c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80036f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800373:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800377:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80037a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80037e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800385:	00 
  800386:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800389:	89 1c 24             	mov    %ebx,(%esp)
  80038c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80038f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800393:	e8 d8 0a 00 00       	call   800e70 <__umoddi3>
  800398:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80039c:	0f be 80 60 10 80 00 	movsbl 0x801060(%eax),%eax
  8003a3:	89 04 24             	mov    %eax,(%esp)
  8003a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003a9:	ff d0                	call   *%eax
}
  8003ab:	83 c4 4c             	add    $0x4c,%esp
  8003ae:	5b                   	pop    %ebx
  8003af:	5e                   	pop    %esi
  8003b0:	5f                   	pop    %edi
  8003b1:	5d                   	pop    %ebp
  8003b2:	c3                   	ret    

008003b3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8003b3:	55                   	push   %ebp
  8003b4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8003b6:	83 fa 01             	cmp    $0x1,%edx
  8003b9:	7e 0e                	jle    8003c9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8003bb:	8b 10                	mov    (%eax),%edx
  8003bd:	8d 4a 08             	lea    0x8(%edx),%ecx
  8003c0:	89 08                	mov    %ecx,(%eax)
  8003c2:	8b 02                	mov    (%edx),%eax
  8003c4:	8b 52 04             	mov    0x4(%edx),%edx
  8003c7:	eb 22                	jmp    8003eb <getuint+0x38>
	else if (lflag)
  8003c9:	85 d2                	test   %edx,%edx
  8003cb:	74 10                	je     8003dd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003cd:	8b 10                	mov    (%eax),%edx
  8003cf:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003d2:	89 08                	mov    %ecx,(%eax)
  8003d4:	8b 02                	mov    (%edx),%eax
  8003d6:	ba 00 00 00 00       	mov    $0x0,%edx
  8003db:	eb 0e                	jmp    8003eb <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003dd:	8b 10                	mov    (%eax),%edx
  8003df:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003e2:	89 08                	mov    %ecx,(%eax)
  8003e4:	8b 02                	mov    (%edx),%eax
  8003e6:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003eb:	5d                   	pop    %ebp
  8003ec:	c3                   	ret    

008003ed <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003ed:	55                   	push   %ebp
  8003ee:	89 e5                	mov    %esp,%ebp
  8003f0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003f3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003f7:	8b 10                	mov    (%eax),%edx
  8003f9:	3b 50 04             	cmp    0x4(%eax),%edx
  8003fc:	73 0a                	jae    800408 <sprintputch+0x1b>
		*b->buf++ = ch;
  8003fe:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800401:	88 0a                	mov    %cl,(%edx)
  800403:	83 c2 01             	add    $0x1,%edx
  800406:	89 10                	mov    %edx,(%eax)
}
  800408:	5d                   	pop    %ebp
  800409:	c3                   	ret    

0080040a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80040a:	55                   	push   %ebp
  80040b:	89 e5                	mov    %esp,%ebp
  80040d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800410:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800413:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800417:	8b 45 10             	mov    0x10(%ebp),%eax
  80041a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80041e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800421:	89 44 24 04          	mov    %eax,0x4(%esp)
  800425:	8b 45 08             	mov    0x8(%ebp),%eax
  800428:	89 04 24             	mov    %eax,(%esp)
  80042b:	e8 02 00 00 00       	call   800432 <vprintfmt>
	va_end(ap);
}
  800430:	c9                   	leave  
  800431:	c3                   	ret    

00800432 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800432:	55                   	push   %ebp
  800433:	89 e5                	mov    %esp,%ebp
  800435:	57                   	push   %edi
  800436:	56                   	push   %esi
  800437:	53                   	push   %ebx
  800438:	83 ec 4c             	sub    $0x4c,%esp
  80043b:	8b 75 08             	mov    0x8(%ebp),%esi
  80043e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800441:	8b 7d 10             	mov    0x10(%ebp),%edi
  800444:	eb 11                	jmp    800457 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800446:	85 c0                	test   %eax,%eax
  800448:	0f 84 db 03 00 00    	je     800829 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80044e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800452:	89 04 24             	mov    %eax,(%esp)
  800455:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800457:	0f b6 07             	movzbl (%edi),%eax
  80045a:	83 c7 01             	add    $0x1,%edi
  80045d:	83 f8 25             	cmp    $0x25,%eax
  800460:	75 e4                	jne    800446 <vprintfmt+0x14>
  800462:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800466:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80046d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800474:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80047b:	ba 00 00 00 00       	mov    $0x0,%edx
  800480:	eb 2b                	jmp    8004ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800482:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800485:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800489:	eb 22                	jmp    8004ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80048b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80048e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800492:	eb 19                	jmp    8004ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800494:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800497:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80049e:	eb 0d                	jmp    8004ad <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8004a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004a3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004a6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ad:	0f b6 0f             	movzbl (%edi),%ecx
  8004b0:	8d 47 01             	lea    0x1(%edi),%eax
  8004b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004b6:	0f b6 07             	movzbl (%edi),%eax
  8004b9:	83 e8 23             	sub    $0x23,%eax
  8004bc:	3c 55                	cmp    $0x55,%al
  8004be:	0f 87 40 03 00 00    	ja     800804 <vprintfmt+0x3d2>
  8004c4:	0f b6 c0             	movzbl %al,%eax
  8004c7:	ff 24 85 f0 10 80 00 	jmp    *0x8010f0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8004ce:	83 e9 30             	sub    $0x30,%ecx
  8004d1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  8004d4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  8004d8:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004db:	83 f9 09             	cmp    $0x9,%ecx
  8004de:	77 57                	ja     800537 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e0:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004e3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8004e6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004e9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  8004ec:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8004ef:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8004f3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8004f6:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004f9:	83 f9 09             	cmp    $0x9,%ecx
  8004fc:	76 eb                	jbe    8004e9 <vprintfmt+0xb7>
  8004fe:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800501:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800504:	eb 34                	jmp    80053a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800506:	8b 45 14             	mov    0x14(%ebp),%eax
  800509:	8d 48 04             	lea    0x4(%eax),%ecx
  80050c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80050f:	8b 00                	mov    (%eax),%eax
  800511:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800514:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800517:	eb 21                	jmp    80053a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800519:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80051d:	0f 88 71 ff ff ff    	js     800494 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800523:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800526:	eb 85                	jmp    8004ad <vprintfmt+0x7b>
  800528:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80052b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800532:	e9 76 ff ff ff       	jmp    8004ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800537:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80053a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80053e:	0f 89 69 ff ff ff    	jns    8004ad <vprintfmt+0x7b>
  800544:	e9 57 ff ff ff       	jmp    8004a0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800549:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80054c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80054f:	e9 59 ff ff ff       	jmp    8004ad <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800554:	8b 45 14             	mov    0x14(%ebp),%eax
  800557:	8d 50 04             	lea    0x4(%eax),%edx
  80055a:	89 55 14             	mov    %edx,0x14(%ebp)
  80055d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800561:	8b 00                	mov    (%eax),%eax
  800563:	89 04 24             	mov    %eax,(%esp)
  800566:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800568:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80056b:	e9 e7 fe ff ff       	jmp    800457 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800570:	8b 45 14             	mov    0x14(%ebp),%eax
  800573:	8d 50 04             	lea    0x4(%eax),%edx
  800576:	89 55 14             	mov    %edx,0x14(%ebp)
  800579:	8b 00                	mov    (%eax),%eax
  80057b:	89 c2                	mov    %eax,%edx
  80057d:	c1 fa 1f             	sar    $0x1f,%edx
  800580:	31 d0                	xor    %edx,%eax
  800582:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800584:	83 f8 06             	cmp    $0x6,%eax
  800587:	7f 0b                	jg     800594 <vprintfmt+0x162>
  800589:	8b 14 85 48 12 80 00 	mov    0x801248(,%eax,4),%edx
  800590:	85 d2                	test   %edx,%edx
  800592:	75 20                	jne    8005b4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800594:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800598:	c7 44 24 08 78 10 80 	movl   $0x801078,0x8(%esp)
  80059f:	00 
  8005a0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005a4:	89 34 24             	mov    %esi,(%esp)
  8005a7:	e8 5e fe ff ff       	call   80040a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8005af:	e9 a3 fe ff ff       	jmp    800457 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8005b4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8005b8:	c7 44 24 08 81 10 80 	movl   $0x801081,0x8(%esp)
  8005bf:	00 
  8005c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005c4:	89 34 24             	mov    %esi,(%esp)
  8005c7:	e8 3e fe ff ff       	call   80040a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005cc:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8005cf:	e9 83 fe ff ff       	jmp    800457 <vprintfmt+0x25>
  8005d4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8005d7:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8005da:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005dd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e0:	8d 50 04             	lea    0x4(%eax),%edx
  8005e3:	89 55 14             	mov    %edx,0x14(%ebp)
  8005e6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8005e8:	85 ff                	test   %edi,%edi
  8005ea:	b8 71 10 80 00       	mov    $0x801071,%eax
  8005ef:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8005f2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8005f6:	74 06                	je     8005fe <vprintfmt+0x1cc>
  8005f8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8005fc:	7f 16                	jg     800614 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005fe:	0f b6 17             	movzbl (%edi),%edx
  800601:	0f be c2             	movsbl %dl,%eax
  800604:	83 c7 01             	add    $0x1,%edi
  800607:	85 c0                	test   %eax,%eax
  800609:	0f 85 9f 00 00 00    	jne    8006ae <vprintfmt+0x27c>
  80060f:	e9 8b 00 00 00       	jmp    80069f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800614:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800618:	89 3c 24             	mov    %edi,(%esp)
  80061b:	e8 c2 02 00 00       	call   8008e2 <strnlen>
  800620:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800623:	29 c2                	sub    %eax,%edx
  800625:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800628:	85 d2                	test   %edx,%edx
  80062a:	7e d2                	jle    8005fe <vprintfmt+0x1cc>
					putch(padc, putdat);
  80062c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800630:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800633:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800636:	89 d7                	mov    %edx,%edi
  800638:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80063c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80063f:	89 04 24             	mov    %eax,(%esp)
  800642:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800644:	83 ef 01             	sub    $0x1,%edi
  800647:	75 ef                	jne    800638 <vprintfmt+0x206>
  800649:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80064c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80064f:	eb ad                	jmp    8005fe <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800651:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800655:	74 20                	je     800677 <vprintfmt+0x245>
  800657:	0f be d2             	movsbl %dl,%edx
  80065a:	83 ea 20             	sub    $0x20,%edx
  80065d:	83 fa 5e             	cmp    $0x5e,%edx
  800660:	76 15                	jbe    800677 <vprintfmt+0x245>
					putch('?', putdat);
  800662:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800665:	89 54 24 04          	mov    %edx,0x4(%esp)
  800669:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800670:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800673:	ff d1                	call   *%ecx
  800675:	eb 0f                	jmp    800686 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800677:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80067a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80067e:	89 04 24             	mov    %eax,(%esp)
  800681:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800684:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800686:	83 eb 01             	sub    $0x1,%ebx
  800689:	0f b6 17             	movzbl (%edi),%edx
  80068c:	0f be c2             	movsbl %dl,%eax
  80068f:	83 c7 01             	add    $0x1,%edi
  800692:	85 c0                	test   %eax,%eax
  800694:	75 24                	jne    8006ba <vprintfmt+0x288>
  800696:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800699:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80069c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80069f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006a2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006a6:	0f 8e ab fd ff ff    	jle    800457 <vprintfmt+0x25>
  8006ac:	eb 20                	jmp    8006ce <vprintfmt+0x29c>
  8006ae:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8006b1:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8006b4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8006b7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006ba:	85 f6                	test   %esi,%esi
  8006bc:	78 93                	js     800651 <vprintfmt+0x21f>
  8006be:	83 ee 01             	sub    $0x1,%esi
  8006c1:	79 8e                	jns    800651 <vprintfmt+0x21f>
  8006c3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8006c6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006c9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8006cc:	eb d1                	jmp    80069f <vprintfmt+0x26d>
  8006ce:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8006d1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006d5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8006dc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006de:	83 ef 01             	sub    $0x1,%edi
  8006e1:	75 ee                	jne    8006d1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006e3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8006e6:	e9 6c fd ff ff       	jmp    800457 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006eb:	83 fa 01             	cmp    $0x1,%edx
  8006ee:	66 90                	xchg   %ax,%ax
  8006f0:	7e 16                	jle    800708 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  8006f2:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f5:	8d 50 08             	lea    0x8(%eax),%edx
  8006f8:	89 55 14             	mov    %edx,0x14(%ebp)
  8006fb:	8b 10                	mov    (%eax),%edx
  8006fd:	8b 48 04             	mov    0x4(%eax),%ecx
  800700:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800703:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800706:	eb 32                	jmp    80073a <vprintfmt+0x308>
	else if (lflag)
  800708:	85 d2                	test   %edx,%edx
  80070a:	74 18                	je     800724 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  80070c:	8b 45 14             	mov    0x14(%ebp),%eax
  80070f:	8d 50 04             	lea    0x4(%eax),%edx
  800712:	89 55 14             	mov    %edx,0x14(%ebp)
  800715:	8b 00                	mov    (%eax),%eax
  800717:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80071a:	89 c1                	mov    %eax,%ecx
  80071c:	c1 f9 1f             	sar    $0x1f,%ecx
  80071f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800722:	eb 16                	jmp    80073a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800724:	8b 45 14             	mov    0x14(%ebp),%eax
  800727:	8d 50 04             	lea    0x4(%eax),%edx
  80072a:	89 55 14             	mov    %edx,0x14(%ebp)
  80072d:	8b 00                	mov    (%eax),%eax
  80072f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800732:	89 c7                	mov    %eax,%edi
  800734:	c1 ff 1f             	sar    $0x1f,%edi
  800737:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80073a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80073d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800740:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800745:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800749:	79 7d                	jns    8007c8 <vprintfmt+0x396>
				putch('-', putdat);
  80074b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80074f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800756:	ff d6                	call   *%esi
				num = -(long long) num;
  800758:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80075b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80075e:	f7 d8                	neg    %eax
  800760:	83 d2 00             	adc    $0x0,%edx
  800763:	f7 da                	neg    %edx
			}
			base = 10;
  800765:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80076a:	eb 5c                	jmp    8007c8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80076c:	8d 45 14             	lea    0x14(%ebp),%eax
  80076f:	e8 3f fc ff ff       	call   8003b3 <getuint>
			base = 10;
  800774:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800779:	eb 4d                	jmp    8007c8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80077b:	8d 45 14             	lea    0x14(%ebp),%eax
  80077e:	e8 30 fc ff ff       	call   8003b3 <getuint>
			base = 8;
  800783:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800788:	eb 3e                	jmp    8007c8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  80078a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80078e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800795:	ff d6                	call   *%esi
			putch('x', putdat);
  800797:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80079b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8007a2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007a7:	8d 50 04             	lea    0x4(%eax),%edx
  8007aa:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007ad:	8b 00                	mov    (%eax),%eax
  8007af:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007b4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007b9:	eb 0d                	jmp    8007c8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007bb:	8d 45 14             	lea    0x14(%ebp),%eax
  8007be:	e8 f0 fb ff ff       	call   8003b3 <getuint>
			base = 16;
  8007c3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007c8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  8007cc:	89 7c 24 10          	mov    %edi,0x10(%esp)
  8007d0:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8007d3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8007d7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8007db:	89 04 24             	mov    %eax,(%esp)
  8007de:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007e2:	89 da                	mov    %ebx,%edx
  8007e4:	89 f0                	mov    %esi,%eax
  8007e6:	e8 d5 fa ff ff       	call   8002c0 <printnum>
			break;
  8007eb:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007ee:	e9 64 fc ff ff       	jmp    800457 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8007f3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007f7:	89 0c 24             	mov    %ecx,(%esp)
  8007fa:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007fc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8007ff:	e9 53 fc ff ff       	jmp    800457 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800804:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800808:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  80080f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800811:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800815:	0f 84 3c fc ff ff    	je     800457 <vprintfmt+0x25>
  80081b:	83 ef 01             	sub    $0x1,%edi
  80081e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800822:	75 f7                	jne    80081b <vprintfmt+0x3e9>
  800824:	e9 2e fc ff ff       	jmp    800457 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800829:	83 c4 4c             	add    $0x4c,%esp
  80082c:	5b                   	pop    %ebx
  80082d:	5e                   	pop    %esi
  80082e:	5f                   	pop    %edi
  80082f:	5d                   	pop    %ebp
  800830:	c3                   	ret    

00800831 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800831:	55                   	push   %ebp
  800832:	89 e5                	mov    %esp,%ebp
  800834:	83 ec 28             	sub    $0x28,%esp
  800837:	8b 45 08             	mov    0x8(%ebp),%eax
  80083a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80083d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800840:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800844:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800847:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80084e:	85 d2                	test   %edx,%edx
  800850:	7e 30                	jle    800882 <vsnprintf+0x51>
  800852:	85 c0                	test   %eax,%eax
  800854:	74 2c                	je     800882 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800856:	8b 45 14             	mov    0x14(%ebp),%eax
  800859:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80085d:	8b 45 10             	mov    0x10(%ebp),%eax
  800860:	89 44 24 08          	mov    %eax,0x8(%esp)
  800864:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800867:	89 44 24 04          	mov    %eax,0x4(%esp)
  80086b:	c7 04 24 ed 03 80 00 	movl   $0x8003ed,(%esp)
  800872:	e8 bb fb ff ff       	call   800432 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800877:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80087a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80087d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800880:	eb 05                	jmp    800887 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800882:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800887:	c9                   	leave  
  800888:	c3                   	ret    

00800889 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800889:	55                   	push   %ebp
  80088a:	89 e5                	mov    %esp,%ebp
  80088c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80088f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800892:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800896:	8b 45 10             	mov    0x10(%ebp),%eax
  800899:	89 44 24 08          	mov    %eax,0x8(%esp)
  80089d:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008a0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8008a4:	8b 45 08             	mov    0x8(%ebp),%eax
  8008a7:	89 04 24             	mov    %eax,(%esp)
  8008aa:	e8 82 ff ff ff       	call   800831 <vsnprintf>
	va_end(ap);

	return rc;
}
  8008af:	c9                   	leave  
  8008b0:	c3                   	ret    
  8008b1:	66 90                	xchg   %ax,%ax
  8008b3:	66 90                	xchg   %ax,%ax
  8008b5:	66 90                	xchg   %ax,%ax
  8008b7:	66 90                	xchg   %ax,%ax
  8008b9:	66 90                	xchg   %ax,%ax
  8008bb:	66 90                	xchg   %ax,%ax
  8008bd:	66 90                	xchg   %ax,%ax
  8008bf:	90                   	nop

008008c0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008c0:	55                   	push   %ebp
  8008c1:	89 e5                	mov    %esp,%ebp
  8008c3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008c6:	80 3a 00             	cmpb   $0x0,(%edx)
  8008c9:	74 10                	je     8008db <strlen+0x1b>
  8008cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  8008d0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008d3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008d7:	75 f7                	jne    8008d0 <strlen+0x10>
  8008d9:	eb 05                	jmp    8008e0 <strlen+0x20>
  8008db:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8008e0:	5d                   	pop    %ebp
  8008e1:	c3                   	ret    

008008e2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008e2:	55                   	push   %ebp
  8008e3:	89 e5                	mov    %esp,%ebp
  8008e5:	53                   	push   %ebx
  8008e6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8008e9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008ec:	85 c9                	test   %ecx,%ecx
  8008ee:	74 1c                	je     80090c <strnlen+0x2a>
  8008f0:	80 3b 00             	cmpb   $0x0,(%ebx)
  8008f3:	74 1e                	je     800913 <strnlen+0x31>
  8008f5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  8008fa:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008fc:	39 ca                	cmp    %ecx,%edx
  8008fe:	74 18                	je     800918 <strnlen+0x36>
  800900:	83 c2 01             	add    $0x1,%edx
  800903:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800908:	75 f0                	jne    8008fa <strnlen+0x18>
  80090a:	eb 0c                	jmp    800918 <strnlen+0x36>
  80090c:	b8 00 00 00 00       	mov    $0x0,%eax
  800911:	eb 05                	jmp    800918 <strnlen+0x36>
  800913:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800918:	5b                   	pop    %ebx
  800919:	5d                   	pop    %ebp
  80091a:	c3                   	ret    

0080091b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80091b:	55                   	push   %ebp
  80091c:	89 e5                	mov    %esp,%ebp
  80091e:	53                   	push   %ebx
  80091f:	8b 45 08             	mov    0x8(%ebp),%eax
  800922:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800925:	89 c2                	mov    %eax,%edx
  800927:	0f b6 19             	movzbl (%ecx),%ebx
  80092a:	88 1a                	mov    %bl,(%edx)
  80092c:	83 c2 01             	add    $0x1,%edx
  80092f:	83 c1 01             	add    $0x1,%ecx
  800932:	84 db                	test   %bl,%bl
  800934:	75 f1                	jne    800927 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800936:	5b                   	pop    %ebx
  800937:	5d                   	pop    %ebp
  800938:	c3                   	ret    

00800939 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800939:	55                   	push   %ebp
  80093a:	89 e5                	mov    %esp,%ebp
  80093c:	53                   	push   %ebx
  80093d:	83 ec 08             	sub    $0x8,%esp
  800940:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800943:	89 1c 24             	mov    %ebx,(%esp)
  800946:	e8 75 ff ff ff       	call   8008c0 <strlen>
	strcpy(dst + len, src);
  80094b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80094e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800952:	01 d8                	add    %ebx,%eax
  800954:	89 04 24             	mov    %eax,(%esp)
  800957:	e8 bf ff ff ff       	call   80091b <strcpy>
	return dst;
}
  80095c:	89 d8                	mov    %ebx,%eax
  80095e:	83 c4 08             	add    $0x8,%esp
  800961:	5b                   	pop    %ebx
  800962:	5d                   	pop    %ebp
  800963:	c3                   	ret    

00800964 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800964:	55                   	push   %ebp
  800965:	89 e5                	mov    %esp,%ebp
  800967:	56                   	push   %esi
  800968:	53                   	push   %ebx
  800969:	8b 75 08             	mov    0x8(%ebp),%esi
  80096c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80096f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800972:	85 db                	test   %ebx,%ebx
  800974:	74 16                	je     80098c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800976:	01 f3                	add    %esi,%ebx
  800978:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  80097a:	0f b6 02             	movzbl (%edx),%eax
  80097d:	88 01                	mov    %al,(%ecx)
  80097f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800982:	80 3a 01             	cmpb   $0x1,(%edx)
  800985:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800988:	39 d9                	cmp    %ebx,%ecx
  80098a:	75 ee                	jne    80097a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80098c:	89 f0                	mov    %esi,%eax
  80098e:	5b                   	pop    %ebx
  80098f:	5e                   	pop    %esi
  800990:	5d                   	pop    %ebp
  800991:	c3                   	ret    

00800992 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800992:	55                   	push   %ebp
  800993:	89 e5                	mov    %esp,%ebp
  800995:	57                   	push   %edi
  800996:	56                   	push   %esi
  800997:	53                   	push   %ebx
  800998:	8b 7d 08             	mov    0x8(%ebp),%edi
  80099b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80099e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8009a1:	89 f8                	mov    %edi,%eax
  8009a3:	85 f6                	test   %esi,%esi
  8009a5:	74 33                	je     8009da <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  8009a7:	83 fe 01             	cmp    $0x1,%esi
  8009aa:	74 25                	je     8009d1 <strlcpy+0x3f>
  8009ac:	0f b6 0b             	movzbl (%ebx),%ecx
  8009af:	84 c9                	test   %cl,%cl
  8009b1:	74 22                	je     8009d5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  8009b3:	83 ee 02             	sub    $0x2,%esi
  8009b6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8009bb:	88 08                	mov    %cl,(%eax)
  8009bd:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8009c0:	39 f2                	cmp    %esi,%edx
  8009c2:	74 13                	je     8009d7 <strlcpy+0x45>
  8009c4:	83 c2 01             	add    $0x1,%edx
  8009c7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  8009cb:	84 c9                	test   %cl,%cl
  8009cd:	75 ec                	jne    8009bb <strlcpy+0x29>
  8009cf:	eb 06                	jmp    8009d7 <strlcpy+0x45>
  8009d1:	89 f8                	mov    %edi,%eax
  8009d3:	eb 02                	jmp    8009d7 <strlcpy+0x45>
  8009d5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  8009d7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8009da:	29 f8                	sub    %edi,%eax
}
  8009dc:	5b                   	pop    %ebx
  8009dd:	5e                   	pop    %esi
  8009de:	5f                   	pop    %edi
  8009df:	5d                   	pop    %ebp
  8009e0:	c3                   	ret    

008009e1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8009e1:	55                   	push   %ebp
  8009e2:	89 e5                	mov    %esp,%ebp
  8009e4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009e7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8009ea:	0f b6 01             	movzbl (%ecx),%eax
  8009ed:	84 c0                	test   %al,%al
  8009ef:	74 15                	je     800a06 <strcmp+0x25>
  8009f1:	3a 02                	cmp    (%edx),%al
  8009f3:	75 11                	jne    800a06 <strcmp+0x25>
		p++, q++;
  8009f5:	83 c1 01             	add    $0x1,%ecx
  8009f8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8009fb:	0f b6 01             	movzbl (%ecx),%eax
  8009fe:	84 c0                	test   %al,%al
  800a00:	74 04                	je     800a06 <strcmp+0x25>
  800a02:	3a 02                	cmp    (%edx),%al
  800a04:	74 ef                	je     8009f5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800a06:	0f b6 c0             	movzbl %al,%eax
  800a09:	0f b6 12             	movzbl (%edx),%edx
  800a0c:	29 d0                	sub    %edx,%eax
}
  800a0e:	5d                   	pop    %ebp
  800a0f:	c3                   	ret    

00800a10 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800a10:	55                   	push   %ebp
  800a11:	89 e5                	mov    %esp,%ebp
  800a13:	56                   	push   %esi
  800a14:	53                   	push   %ebx
  800a15:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a18:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a1b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800a1e:	85 f6                	test   %esi,%esi
  800a20:	74 29                	je     800a4b <strncmp+0x3b>
  800a22:	0f b6 03             	movzbl (%ebx),%eax
  800a25:	84 c0                	test   %al,%al
  800a27:	74 30                	je     800a59 <strncmp+0x49>
  800a29:	3a 02                	cmp    (%edx),%al
  800a2b:	75 2c                	jne    800a59 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800a2d:	8d 43 01             	lea    0x1(%ebx),%eax
  800a30:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800a32:	89 c3                	mov    %eax,%ebx
  800a34:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800a37:	39 f0                	cmp    %esi,%eax
  800a39:	74 17                	je     800a52 <strncmp+0x42>
  800a3b:	0f b6 08             	movzbl (%eax),%ecx
  800a3e:	84 c9                	test   %cl,%cl
  800a40:	74 17                	je     800a59 <strncmp+0x49>
  800a42:	83 c0 01             	add    $0x1,%eax
  800a45:	3a 0a                	cmp    (%edx),%cl
  800a47:	74 e9                	je     800a32 <strncmp+0x22>
  800a49:	eb 0e                	jmp    800a59 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a4b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a50:	eb 0f                	jmp    800a61 <strncmp+0x51>
  800a52:	b8 00 00 00 00       	mov    $0x0,%eax
  800a57:	eb 08                	jmp    800a61 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a59:	0f b6 03             	movzbl (%ebx),%eax
  800a5c:	0f b6 12             	movzbl (%edx),%edx
  800a5f:	29 d0                	sub    %edx,%eax
}
  800a61:	5b                   	pop    %ebx
  800a62:	5e                   	pop    %esi
  800a63:	5d                   	pop    %ebp
  800a64:	c3                   	ret    

00800a65 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800a65:	55                   	push   %ebp
  800a66:	89 e5                	mov    %esp,%ebp
  800a68:	53                   	push   %ebx
  800a69:	8b 45 08             	mov    0x8(%ebp),%eax
  800a6c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a6f:	0f b6 18             	movzbl (%eax),%ebx
  800a72:	84 db                	test   %bl,%bl
  800a74:	74 1d                	je     800a93 <strchr+0x2e>
  800a76:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a78:	38 d3                	cmp    %dl,%bl
  800a7a:	75 06                	jne    800a82 <strchr+0x1d>
  800a7c:	eb 1a                	jmp    800a98 <strchr+0x33>
  800a7e:	38 ca                	cmp    %cl,%dl
  800a80:	74 16                	je     800a98 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a82:	83 c0 01             	add    $0x1,%eax
  800a85:	0f b6 10             	movzbl (%eax),%edx
  800a88:	84 d2                	test   %dl,%dl
  800a8a:	75 f2                	jne    800a7e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800a8c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a91:	eb 05                	jmp    800a98 <strchr+0x33>
  800a93:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a98:	5b                   	pop    %ebx
  800a99:	5d                   	pop    %ebp
  800a9a:	c3                   	ret    

00800a9b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a9b:	55                   	push   %ebp
  800a9c:	89 e5                	mov    %esp,%ebp
  800a9e:	53                   	push   %ebx
  800a9f:	8b 45 08             	mov    0x8(%ebp),%eax
  800aa2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800aa5:	0f b6 18             	movzbl (%eax),%ebx
  800aa8:	84 db                	test   %bl,%bl
  800aaa:	74 16                	je     800ac2 <strfind+0x27>
  800aac:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800aae:	38 d3                	cmp    %dl,%bl
  800ab0:	75 06                	jne    800ab8 <strfind+0x1d>
  800ab2:	eb 0e                	jmp    800ac2 <strfind+0x27>
  800ab4:	38 ca                	cmp    %cl,%dl
  800ab6:	74 0a                	je     800ac2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800ab8:	83 c0 01             	add    $0x1,%eax
  800abb:	0f b6 10             	movzbl (%eax),%edx
  800abe:	84 d2                	test   %dl,%dl
  800ac0:	75 f2                	jne    800ab4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800ac2:	5b                   	pop    %ebx
  800ac3:	5d                   	pop    %ebp
  800ac4:	c3                   	ret    

00800ac5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800ac5:	55                   	push   %ebp
  800ac6:	89 e5                	mov    %esp,%ebp
  800ac8:	83 ec 0c             	sub    $0xc,%esp
  800acb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ace:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ad1:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800ad4:	8b 7d 08             	mov    0x8(%ebp),%edi
  800ad7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800ada:	85 c9                	test   %ecx,%ecx
  800adc:	74 36                	je     800b14 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800ade:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800ae4:	75 28                	jne    800b0e <memset+0x49>
  800ae6:	f6 c1 03             	test   $0x3,%cl
  800ae9:	75 23                	jne    800b0e <memset+0x49>
		c &= 0xFF;
  800aeb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800aef:	89 d3                	mov    %edx,%ebx
  800af1:	c1 e3 08             	shl    $0x8,%ebx
  800af4:	89 d6                	mov    %edx,%esi
  800af6:	c1 e6 18             	shl    $0x18,%esi
  800af9:	89 d0                	mov    %edx,%eax
  800afb:	c1 e0 10             	shl    $0x10,%eax
  800afe:	09 f0                	or     %esi,%eax
  800b00:	09 c2                	or     %eax,%edx
  800b02:	89 d0                	mov    %edx,%eax
  800b04:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800b06:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800b09:	fc                   	cld    
  800b0a:	f3 ab                	rep stos %eax,%es:(%edi)
  800b0c:	eb 06                	jmp    800b14 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b0e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b11:	fc                   	cld    
  800b12:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800b14:	89 f8                	mov    %edi,%eax
  800b16:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b19:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b1c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b1f:	89 ec                	mov    %ebp,%esp
  800b21:	5d                   	pop    %ebp
  800b22:	c3                   	ret    

00800b23 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b23:	55                   	push   %ebp
  800b24:	89 e5                	mov    %esp,%ebp
  800b26:	83 ec 08             	sub    $0x8,%esp
  800b29:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b2c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800b2f:	8b 45 08             	mov    0x8(%ebp),%eax
  800b32:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b35:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b38:	39 c6                	cmp    %eax,%esi
  800b3a:	73 36                	jae    800b72 <memmove+0x4f>
  800b3c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b3f:	39 d0                	cmp    %edx,%eax
  800b41:	73 2f                	jae    800b72 <memmove+0x4f>
		s += n;
		d += n;
  800b43:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b46:	f6 c2 03             	test   $0x3,%dl
  800b49:	75 1b                	jne    800b66 <memmove+0x43>
  800b4b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b51:	75 13                	jne    800b66 <memmove+0x43>
  800b53:	f6 c1 03             	test   $0x3,%cl
  800b56:	75 0e                	jne    800b66 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800b58:	83 ef 04             	sub    $0x4,%edi
  800b5b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800b5e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800b61:	fd                   	std    
  800b62:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b64:	eb 09                	jmp    800b6f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800b66:	83 ef 01             	sub    $0x1,%edi
  800b69:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800b6c:	fd                   	std    
  800b6d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800b6f:	fc                   	cld    
  800b70:	eb 20                	jmp    800b92 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b72:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800b78:	75 13                	jne    800b8d <memmove+0x6a>
  800b7a:	a8 03                	test   $0x3,%al
  800b7c:	75 0f                	jne    800b8d <memmove+0x6a>
  800b7e:	f6 c1 03             	test   $0x3,%cl
  800b81:	75 0a                	jne    800b8d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800b83:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800b86:	89 c7                	mov    %eax,%edi
  800b88:	fc                   	cld    
  800b89:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b8b:	eb 05                	jmp    800b92 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b8d:	89 c7                	mov    %eax,%edi
  800b8f:	fc                   	cld    
  800b90:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b92:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b95:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b98:	89 ec                	mov    %ebp,%esp
  800b9a:	5d                   	pop    %ebp
  800b9b:	c3                   	ret    

00800b9c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800b9c:	55                   	push   %ebp
  800b9d:	89 e5                	mov    %esp,%ebp
  800b9f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ba2:	8b 45 10             	mov    0x10(%ebp),%eax
  800ba5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ba9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800bac:	89 44 24 04          	mov    %eax,0x4(%esp)
  800bb0:	8b 45 08             	mov    0x8(%ebp),%eax
  800bb3:	89 04 24             	mov    %eax,(%esp)
  800bb6:	e8 68 ff ff ff       	call   800b23 <memmove>
}
  800bbb:	c9                   	leave  
  800bbc:	c3                   	ret    

00800bbd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800bbd:	55                   	push   %ebp
  800bbe:	89 e5                	mov    %esp,%ebp
  800bc0:	57                   	push   %edi
  800bc1:	56                   	push   %esi
  800bc2:	53                   	push   %ebx
  800bc3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800bc6:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bc9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800bcc:	8d 78 ff             	lea    -0x1(%eax),%edi
  800bcf:	85 c0                	test   %eax,%eax
  800bd1:	74 36                	je     800c09 <memcmp+0x4c>
		if (*s1 != *s2)
  800bd3:	0f b6 03             	movzbl (%ebx),%eax
  800bd6:	0f b6 0e             	movzbl (%esi),%ecx
  800bd9:	38 c8                	cmp    %cl,%al
  800bdb:	75 17                	jne    800bf4 <memcmp+0x37>
  800bdd:	ba 00 00 00 00       	mov    $0x0,%edx
  800be2:	eb 1a                	jmp    800bfe <memcmp+0x41>
  800be4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800be9:	83 c2 01             	add    $0x1,%edx
  800bec:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800bf0:	38 c8                	cmp    %cl,%al
  800bf2:	74 0a                	je     800bfe <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800bf4:	0f b6 c0             	movzbl %al,%eax
  800bf7:	0f b6 c9             	movzbl %cl,%ecx
  800bfa:	29 c8                	sub    %ecx,%eax
  800bfc:	eb 10                	jmp    800c0e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800bfe:	39 fa                	cmp    %edi,%edx
  800c00:	75 e2                	jne    800be4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c02:	b8 00 00 00 00       	mov    $0x0,%eax
  800c07:	eb 05                	jmp    800c0e <memcmp+0x51>
  800c09:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c0e:	5b                   	pop    %ebx
  800c0f:	5e                   	pop    %esi
  800c10:	5f                   	pop    %edi
  800c11:	5d                   	pop    %ebp
  800c12:	c3                   	ret    

00800c13 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c13:	55                   	push   %ebp
  800c14:	89 e5                	mov    %esp,%ebp
  800c16:	53                   	push   %ebx
  800c17:	8b 45 08             	mov    0x8(%ebp),%eax
  800c1a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800c1d:	89 c2                	mov    %eax,%edx
  800c1f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800c22:	39 d0                	cmp    %edx,%eax
  800c24:	73 13                	jae    800c39 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c26:	89 d9                	mov    %ebx,%ecx
  800c28:	38 18                	cmp    %bl,(%eax)
  800c2a:	75 06                	jne    800c32 <memfind+0x1f>
  800c2c:	eb 0b                	jmp    800c39 <memfind+0x26>
  800c2e:	38 08                	cmp    %cl,(%eax)
  800c30:	74 07                	je     800c39 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c32:	83 c0 01             	add    $0x1,%eax
  800c35:	39 d0                	cmp    %edx,%eax
  800c37:	75 f5                	jne    800c2e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c39:	5b                   	pop    %ebx
  800c3a:	5d                   	pop    %ebp
  800c3b:	c3                   	ret    

00800c3c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c3c:	55                   	push   %ebp
  800c3d:	89 e5                	mov    %esp,%ebp
  800c3f:	57                   	push   %edi
  800c40:	56                   	push   %esi
  800c41:	53                   	push   %ebx
  800c42:	83 ec 04             	sub    $0x4,%esp
  800c45:	8b 55 08             	mov    0x8(%ebp),%edx
  800c48:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c4b:	0f b6 02             	movzbl (%edx),%eax
  800c4e:	3c 09                	cmp    $0x9,%al
  800c50:	74 04                	je     800c56 <strtol+0x1a>
  800c52:	3c 20                	cmp    $0x20,%al
  800c54:	75 0e                	jne    800c64 <strtol+0x28>
		s++;
  800c56:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c59:	0f b6 02             	movzbl (%edx),%eax
  800c5c:	3c 09                	cmp    $0x9,%al
  800c5e:	74 f6                	je     800c56 <strtol+0x1a>
  800c60:	3c 20                	cmp    $0x20,%al
  800c62:	74 f2                	je     800c56 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c64:	3c 2b                	cmp    $0x2b,%al
  800c66:	75 0a                	jne    800c72 <strtol+0x36>
		s++;
  800c68:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800c6b:	bf 00 00 00 00       	mov    $0x0,%edi
  800c70:	eb 10                	jmp    800c82 <strtol+0x46>
  800c72:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c77:	3c 2d                	cmp    $0x2d,%al
  800c79:	75 07                	jne    800c82 <strtol+0x46>
		s++, neg = 1;
  800c7b:	83 c2 01             	add    $0x1,%edx
  800c7e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c82:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800c88:	75 15                	jne    800c9f <strtol+0x63>
  800c8a:	80 3a 30             	cmpb   $0x30,(%edx)
  800c8d:	75 10                	jne    800c9f <strtol+0x63>
  800c8f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800c93:	75 0a                	jne    800c9f <strtol+0x63>
		s += 2, base = 16;
  800c95:	83 c2 02             	add    $0x2,%edx
  800c98:	bb 10 00 00 00       	mov    $0x10,%ebx
  800c9d:	eb 10                	jmp    800caf <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800c9f:	85 db                	test   %ebx,%ebx
  800ca1:	75 0c                	jne    800caf <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ca3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ca5:	80 3a 30             	cmpb   $0x30,(%edx)
  800ca8:	75 05                	jne    800caf <strtol+0x73>
		s++, base = 8;
  800caa:	83 c2 01             	add    $0x1,%edx
  800cad:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800caf:	b8 00 00 00 00       	mov    $0x0,%eax
  800cb4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800cb7:	0f b6 0a             	movzbl (%edx),%ecx
  800cba:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800cbd:	89 f3                	mov    %esi,%ebx
  800cbf:	80 fb 09             	cmp    $0x9,%bl
  800cc2:	77 08                	ja     800ccc <strtol+0x90>
			dig = *s - '0';
  800cc4:	0f be c9             	movsbl %cl,%ecx
  800cc7:	83 e9 30             	sub    $0x30,%ecx
  800cca:	eb 22                	jmp    800cee <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800ccc:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800ccf:	89 f3                	mov    %esi,%ebx
  800cd1:	80 fb 19             	cmp    $0x19,%bl
  800cd4:	77 08                	ja     800cde <strtol+0xa2>
			dig = *s - 'a' + 10;
  800cd6:	0f be c9             	movsbl %cl,%ecx
  800cd9:	83 e9 57             	sub    $0x57,%ecx
  800cdc:	eb 10                	jmp    800cee <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800cde:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800ce1:	89 f3                	mov    %esi,%ebx
  800ce3:	80 fb 19             	cmp    $0x19,%bl
  800ce6:	77 16                	ja     800cfe <strtol+0xc2>
			dig = *s - 'A' + 10;
  800ce8:	0f be c9             	movsbl %cl,%ecx
  800ceb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800cee:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800cf1:	7d 0f                	jge    800d02 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800cf3:	83 c2 01             	add    $0x1,%edx
  800cf6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800cfa:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800cfc:	eb b9                	jmp    800cb7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800cfe:	89 c1                	mov    %eax,%ecx
  800d00:	eb 02                	jmp    800d04 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800d02:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800d04:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d08:	74 05                	je     800d0f <strtol+0xd3>
		*endptr = (char *) s;
  800d0a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800d0d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800d0f:	89 ca                	mov    %ecx,%edx
  800d11:	f7 da                	neg    %edx
  800d13:	85 ff                	test   %edi,%edi
  800d15:	0f 45 c2             	cmovne %edx,%eax
}
  800d18:	83 c4 04             	add    $0x4,%esp
  800d1b:	5b                   	pop    %ebx
  800d1c:	5e                   	pop    %esi
  800d1d:	5f                   	pop    %edi
  800d1e:	5d                   	pop    %ebp
  800d1f:	c3                   	ret    

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

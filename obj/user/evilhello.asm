
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
  800049:	e8 8a 00 00 00       	call   8000d8 <sys_cputs>
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
  800053:	57                   	push   %edi
  800054:	56                   	push   %esi
  800055:	53                   	push   %ebx
  800056:	83 ec 1c             	sub    $0x1c,%esp
  800059:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  80005f:	e8 30 01 00 00       	call   800194 <sys_getenvid>
	thisenv = envs;
  800064:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  80006b:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  80006e:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  800074:	39 c2                	cmp    %eax,%edx
  800076:	74 25                	je     80009d <libmain+0x4d>
  800078:	ba 60 00 c0 ee       	mov    $0xeec00060,%edx
  80007d:	eb 12                	jmp    800091 <libmain+0x41>
  80007f:	8b 4a 48             	mov    0x48(%edx),%ecx
  800082:	83 c2 60             	add    $0x60,%edx
  800085:	39 c1                	cmp    %eax,%ecx
  800087:	75 08                	jne    800091 <libmain+0x41>
  800089:	89 3d 04 20 80 00    	mov    %edi,0x802004
  80008f:	eb 0c                	jmp    80009d <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  800091:	89 d7                	mov    %edx,%edi
  800093:	85 d2                	test   %edx,%edx
  800095:	75 e8                	jne    80007f <libmain+0x2f>
  800097:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80009d:	85 db                	test   %ebx,%ebx
  80009f:	7e 07                	jle    8000a8 <libmain+0x58>
		binaryname = argv[0];
  8000a1:	8b 06                	mov    (%esi),%eax
  8000a3:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000a8:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000ac:	89 1c 24             	mov    %ebx,(%esp)
  8000af:	e8 80 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  8000b4:	e8 0b 00 00 00       	call   8000c4 <exit>
}
  8000b9:	83 c4 1c             	add    $0x1c,%esp
  8000bc:	5b                   	pop    %ebx
  8000bd:	5e                   	pop    %esi
  8000be:	5f                   	pop    %edi
  8000bf:	5d                   	pop    %ebp
  8000c0:	c3                   	ret    
  8000c1:	66 90                	xchg   %ax,%ax
  8000c3:	90                   	nop

008000c4 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000c4:	55                   	push   %ebp
  8000c5:	89 e5                	mov    %esp,%ebp
  8000c7:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000d1:	e8 61 00 00 00       	call   800137 <sys_env_destroy>
}
  8000d6:	c9                   	leave  
  8000d7:	c3                   	ret    

008000d8 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000d8:	55                   	push   %ebp
  8000d9:	89 e5                	mov    %esp,%ebp
  8000db:	83 ec 0c             	sub    $0xc,%esp
  8000de:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000e1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000e4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000e7:	b8 00 00 00 00       	mov    $0x0,%eax
  8000ec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000ef:	8b 55 08             	mov    0x8(%ebp),%edx
  8000f2:	89 c3                	mov    %eax,%ebx
  8000f4:	89 c7                	mov    %eax,%edi
  8000f6:	89 c6                	mov    %eax,%esi
  8000f8:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000fa:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000fd:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800100:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800103:	89 ec                	mov    %ebp,%esp
  800105:	5d                   	pop    %ebp
  800106:	c3                   	ret    

00800107 <sys_cgetc>:

int
sys_cgetc(void)
{
  800107:	55                   	push   %ebp
  800108:	89 e5                	mov    %esp,%ebp
  80010a:	83 ec 0c             	sub    $0xc,%esp
  80010d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800110:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800113:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800116:	ba 00 00 00 00       	mov    $0x0,%edx
  80011b:	b8 01 00 00 00       	mov    $0x1,%eax
  800120:	89 d1                	mov    %edx,%ecx
  800122:	89 d3                	mov    %edx,%ebx
  800124:	89 d7                	mov    %edx,%edi
  800126:	89 d6                	mov    %edx,%esi
  800128:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  80012a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80012d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800130:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800133:	89 ec                	mov    %ebp,%esp
  800135:	5d                   	pop    %ebp
  800136:	c3                   	ret    

00800137 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800137:	55                   	push   %ebp
  800138:	89 e5                	mov    %esp,%ebp
  80013a:	83 ec 38             	sub    $0x38,%esp
  80013d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800140:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800143:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800146:	b9 00 00 00 00       	mov    $0x0,%ecx
  80014b:	b8 03 00 00 00       	mov    $0x3,%eax
  800150:	8b 55 08             	mov    0x8(%ebp),%edx
  800153:	89 cb                	mov    %ecx,%ebx
  800155:	89 cf                	mov    %ecx,%edi
  800157:	89 ce                	mov    %ecx,%esi
  800159:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80015b:	85 c0                	test   %eax,%eax
  80015d:	7e 28                	jle    800187 <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  80015f:	89 44 24 10          	mov    %eax,0x10(%esp)
  800163:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  80016a:	00 
  80016b:	c7 44 24 08 4a 10 80 	movl   $0x80104a,0x8(%esp)
  800172:	00 
  800173:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80017a:	00 
  80017b:	c7 04 24 67 10 80 00 	movl   $0x801067,(%esp)
  800182:	e8 3d 00 00 00       	call   8001c4 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800187:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80018a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80018d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800190:	89 ec                	mov    %ebp,%esp
  800192:	5d                   	pop    %ebp
  800193:	c3                   	ret    

00800194 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800194:	55                   	push   %ebp
  800195:	89 e5                	mov    %esp,%ebp
  800197:	83 ec 0c             	sub    $0xc,%esp
  80019a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80019d:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8001a0:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001a3:	ba 00 00 00 00       	mov    $0x0,%edx
  8001a8:	b8 02 00 00 00       	mov    $0x2,%eax
  8001ad:	89 d1                	mov    %edx,%ecx
  8001af:	89 d3                	mov    %edx,%ebx
  8001b1:	89 d7                	mov    %edx,%edi
  8001b3:	89 d6                	mov    %edx,%esi
  8001b5:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  8001b7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8001ba:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8001bd:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8001c0:	89 ec                	mov    %ebp,%esp
  8001c2:	5d                   	pop    %ebp
  8001c3:	c3                   	ret    

008001c4 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8001c4:	55                   	push   %ebp
  8001c5:	89 e5                	mov    %esp,%ebp
  8001c7:	56                   	push   %esi
  8001c8:	53                   	push   %ebx
  8001c9:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8001cc:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  8001cf:	a1 08 20 80 00       	mov    0x802008,%eax
  8001d4:	85 c0                	test   %eax,%eax
  8001d6:	74 10                	je     8001e8 <_panic+0x24>
		cprintf("%s: ", argv0);
  8001d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001dc:	c7 04 24 75 10 80 00 	movl   $0x801075,(%esp)
  8001e3:	e8 ef 00 00 00       	call   8002d7 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001e8:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8001ee:	e8 a1 ff ff ff       	call   800194 <sys_getenvid>
  8001f3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001f6:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001fa:	8b 55 08             	mov    0x8(%ebp),%edx
  8001fd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800201:	89 74 24 08          	mov    %esi,0x8(%esp)
  800205:	89 44 24 04          	mov    %eax,0x4(%esp)
  800209:	c7 04 24 7c 10 80 00 	movl   $0x80107c,(%esp)
  800210:	e8 c2 00 00 00       	call   8002d7 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800215:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800219:	8b 45 10             	mov    0x10(%ebp),%eax
  80021c:	89 04 24             	mov    %eax,(%esp)
  80021f:	e8 52 00 00 00       	call   800276 <vcprintf>
	cprintf("\n");
  800224:	c7 04 24 7a 10 80 00 	movl   $0x80107a,(%esp)
  80022b:	e8 a7 00 00 00       	call   8002d7 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800230:	cc                   	int3   
  800231:	eb fd                	jmp    800230 <_panic+0x6c>
  800233:	90                   	nop

00800234 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800234:	55                   	push   %ebp
  800235:	89 e5                	mov    %esp,%ebp
  800237:	53                   	push   %ebx
  800238:	83 ec 14             	sub    $0x14,%esp
  80023b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80023e:	8b 03                	mov    (%ebx),%eax
  800240:	8b 55 08             	mov    0x8(%ebp),%edx
  800243:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  800247:	83 c0 01             	add    $0x1,%eax
  80024a:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  80024c:	3d ff 00 00 00       	cmp    $0xff,%eax
  800251:	75 19                	jne    80026c <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800253:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80025a:	00 
  80025b:	8d 43 08             	lea    0x8(%ebx),%eax
  80025e:	89 04 24             	mov    %eax,(%esp)
  800261:	e8 72 fe ff ff       	call   8000d8 <sys_cputs>
		b->idx = 0;
  800266:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80026c:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800270:	83 c4 14             	add    $0x14,%esp
  800273:	5b                   	pop    %ebx
  800274:	5d                   	pop    %ebp
  800275:	c3                   	ret    

00800276 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800276:	55                   	push   %ebp
  800277:	89 e5                	mov    %esp,%ebp
  800279:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80027f:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800286:	00 00 00 
	b.cnt = 0;
  800289:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800290:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800293:	8b 45 0c             	mov    0xc(%ebp),%eax
  800296:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80029a:	8b 45 08             	mov    0x8(%ebp),%eax
  80029d:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002a1:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8002a7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002ab:	c7 04 24 34 02 80 00 	movl   $0x800234,(%esp)
  8002b2:	e8 bb 01 00 00       	call   800472 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8002b7:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8002bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002c1:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8002c7:	89 04 24             	mov    %eax,(%esp)
  8002ca:	e8 09 fe ff ff       	call   8000d8 <sys_cputs>

	return b.cnt;
}
  8002cf:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002d5:	c9                   	leave  
  8002d6:	c3                   	ret    

008002d7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002d7:	55                   	push   %ebp
  8002d8:	89 e5                	mov    %esp,%ebp
  8002da:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002dd:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002e0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002e4:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e7:	89 04 24             	mov    %eax,(%esp)
  8002ea:	e8 87 ff ff ff       	call   800276 <vcprintf>
	va_end(ap);

	return cnt;
}
  8002ef:	c9                   	leave  
  8002f0:	c3                   	ret    
  8002f1:	66 90                	xchg   %ax,%ax
  8002f3:	66 90                	xchg   %ax,%ax
  8002f5:	66 90                	xchg   %ax,%ax
  8002f7:	66 90                	xchg   %ax,%ax
  8002f9:	66 90                	xchg   %ax,%ax
  8002fb:	66 90                	xchg   %ax,%ax
  8002fd:	66 90                	xchg   %ax,%ax
  8002ff:	90                   	nop

00800300 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800300:	55                   	push   %ebp
  800301:	89 e5                	mov    %esp,%ebp
  800303:	57                   	push   %edi
  800304:	56                   	push   %esi
  800305:	53                   	push   %ebx
  800306:	83 ec 4c             	sub    $0x4c,%esp
  800309:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80030c:	89 d7                	mov    %edx,%edi
  80030e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800311:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800314:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800317:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80031a:	b8 00 00 00 00       	mov    $0x0,%eax
  80031f:	39 d8                	cmp    %ebx,%eax
  800321:	72 17                	jb     80033a <printnum+0x3a>
  800323:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800326:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800329:	76 0f                	jbe    80033a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80032b:	8b 75 14             	mov    0x14(%ebp),%esi
  80032e:	83 ee 01             	sub    $0x1,%esi
  800331:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800334:	85 f6                	test   %esi,%esi
  800336:	7f 63                	jg     80039b <printnum+0x9b>
  800338:	eb 75                	jmp    8003af <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80033a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80033d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800341:	8b 45 14             	mov    0x14(%ebp),%eax
  800344:	83 e8 01             	sub    $0x1,%eax
  800347:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80034b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80034e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800352:	8b 44 24 08          	mov    0x8(%esp),%eax
  800356:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80035a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80035d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800360:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800367:	00 
  800368:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80036b:	89 1c 24             	mov    %ebx,(%esp)
  80036e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800371:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800375:	e8 e6 09 00 00       	call   800d60 <__udivdi3>
  80037a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80037d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800380:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800384:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800388:	89 04 24             	mov    %eax,(%esp)
  80038b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80038f:	89 fa                	mov    %edi,%edx
  800391:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800394:	e8 67 ff ff ff       	call   800300 <printnum>
  800399:	eb 14                	jmp    8003af <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80039b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80039f:	8b 45 18             	mov    0x18(%ebp),%eax
  8003a2:	89 04 24             	mov    %eax,(%esp)
  8003a5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8003a7:	83 ee 01             	sub    $0x1,%esi
  8003aa:	75 ef                	jne    80039b <printnum+0x9b>
  8003ac:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8003af:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003b3:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8003b7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003ba:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8003be:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8003c5:	00 
  8003c6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8003c9:	89 1c 24             	mov    %ebx,(%esp)
  8003cc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8003cf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003d3:	e8 d8 0a 00 00       	call   800eb0 <__umoddi3>
  8003d8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003dc:	0f be 80 a0 10 80 00 	movsbl 0x8010a0(%eax),%eax
  8003e3:	89 04 24             	mov    %eax,(%esp)
  8003e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003e9:	ff d0                	call   *%eax
}
  8003eb:	83 c4 4c             	add    $0x4c,%esp
  8003ee:	5b                   	pop    %ebx
  8003ef:	5e                   	pop    %esi
  8003f0:	5f                   	pop    %edi
  8003f1:	5d                   	pop    %ebp
  8003f2:	c3                   	ret    

008003f3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8003f3:	55                   	push   %ebp
  8003f4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8003f6:	83 fa 01             	cmp    $0x1,%edx
  8003f9:	7e 0e                	jle    800409 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8003fb:	8b 10                	mov    (%eax),%edx
  8003fd:	8d 4a 08             	lea    0x8(%edx),%ecx
  800400:	89 08                	mov    %ecx,(%eax)
  800402:	8b 02                	mov    (%edx),%eax
  800404:	8b 52 04             	mov    0x4(%edx),%edx
  800407:	eb 22                	jmp    80042b <getuint+0x38>
	else if (lflag)
  800409:	85 d2                	test   %edx,%edx
  80040b:	74 10                	je     80041d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80040d:	8b 10                	mov    (%eax),%edx
  80040f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800412:	89 08                	mov    %ecx,(%eax)
  800414:	8b 02                	mov    (%edx),%eax
  800416:	ba 00 00 00 00       	mov    $0x0,%edx
  80041b:	eb 0e                	jmp    80042b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80041d:	8b 10                	mov    (%eax),%edx
  80041f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800422:	89 08                	mov    %ecx,(%eax)
  800424:	8b 02                	mov    (%edx),%eax
  800426:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80042b:	5d                   	pop    %ebp
  80042c:	c3                   	ret    

0080042d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80042d:	55                   	push   %ebp
  80042e:	89 e5                	mov    %esp,%ebp
  800430:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800433:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800437:	8b 10                	mov    (%eax),%edx
  800439:	3b 50 04             	cmp    0x4(%eax),%edx
  80043c:	73 0a                	jae    800448 <sprintputch+0x1b>
		*b->buf++ = ch;
  80043e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800441:	88 0a                	mov    %cl,(%edx)
  800443:	83 c2 01             	add    $0x1,%edx
  800446:	89 10                	mov    %edx,(%eax)
}
  800448:	5d                   	pop    %ebp
  800449:	c3                   	ret    

0080044a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80044a:	55                   	push   %ebp
  80044b:	89 e5                	mov    %esp,%ebp
  80044d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800450:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800453:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800457:	8b 45 10             	mov    0x10(%ebp),%eax
  80045a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80045e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800461:	89 44 24 04          	mov    %eax,0x4(%esp)
  800465:	8b 45 08             	mov    0x8(%ebp),%eax
  800468:	89 04 24             	mov    %eax,(%esp)
  80046b:	e8 02 00 00 00       	call   800472 <vprintfmt>
	va_end(ap);
}
  800470:	c9                   	leave  
  800471:	c3                   	ret    

00800472 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800472:	55                   	push   %ebp
  800473:	89 e5                	mov    %esp,%ebp
  800475:	57                   	push   %edi
  800476:	56                   	push   %esi
  800477:	53                   	push   %ebx
  800478:	83 ec 4c             	sub    $0x4c,%esp
  80047b:	8b 75 08             	mov    0x8(%ebp),%esi
  80047e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800481:	8b 7d 10             	mov    0x10(%ebp),%edi
  800484:	eb 11                	jmp    800497 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800486:	85 c0                	test   %eax,%eax
  800488:	0f 84 db 03 00 00    	je     800869 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80048e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800492:	89 04 24             	mov    %eax,(%esp)
  800495:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800497:	0f b6 07             	movzbl (%edi),%eax
  80049a:	83 c7 01             	add    $0x1,%edi
  80049d:	83 f8 25             	cmp    $0x25,%eax
  8004a0:	75 e4                	jne    800486 <vprintfmt+0x14>
  8004a2:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  8004a6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  8004ad:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8004b4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  8004bb:	ba 00 00 00 00       	mov    $0x0,%edx
  8004c0:	eb 2b                	jmp    8004ed <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8004c5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  8004c9:	eb 22                	jmp    8004ed <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004cb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8004ce:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  8004d2:	eb 19                	jmp    8004ed <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  8004d7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8004de:	eb 0d                	jmp    8004ed <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8004e0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004e6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ed:	0f b6 0f             	movzbl (%edi),%ecx
  8004f0:	8d 47 01             	lea    0x1(%edi),%eax
  8004f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004f6:	0f b6 07             	movzbl (%edi),%eax
  8004f9:	83 e8 23             	sub    $0x23,%eax
  8004fc:	3c 55                	cmp    $0x55,%al
  8004fe:	0f 87 40 03 00 00    	ja     800844 <vprintfmt+0x3d2>
  800504:	0f b6 c0             	movzbl %al,%eax
  800507:	ff 24 85 30 11 80 00 	jmp    *0x801130(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80050e:	83 e9 30             	sub    $0x30,%ecx
  800511:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800514:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800518:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80051b:	83 f9 09             	cmp    $0x9,%ecx
  80051e:	77 57                	ja     800577 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800520:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800523:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800526:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800529:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80052c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80052f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800533:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800536:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800539:	83 f9 09             	cmp    $0x9,%ecx
  80053c:	76 eb                	jbe    800529 <vprintfmt+0xb7>
  80053e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800541:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800544:	eb 34                	jmp    80057a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800546:	8b 45 14             	mov    0x14(%ebp),%eax
  800549:	8d 48 04             	lea    0x4(%eax),%ecx
  80054c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80054f:	8b 00                	mov    (%eax),%eax
  800551:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800554:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800557:	eb 21                	jmp    80057a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800559:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80055d:	0f 88 71 ff ff ff    	js     8004d4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800563:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800566:	eb 85                	jmp    8004ed <vprintfmt+0x7b>
  800568:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80056b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800572:	e9 76 ff ff ff       	jmp    8004ed <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800577:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80057a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80057e:	0f 89 69 ff ff ff    	jns    8004ed <vprintfmt+0x7b>
  800584:	e9 57 ff ff ff       	jmp    8004e0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800589:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80058c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80058f:	e9 59 ff ff ff       	jmp    8004ed <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800594:	8b 45 14             	mov    0x14(%ebp),%eax
  800597:	8d 50 04             	lea    0x4(%eax),%edx
  80059a:	89 55 14             	mov    %edx,0x14(%ebp)
  80059d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005a1:	8b 00                	mov    (%eax),%eax
  8005a3:	89 04 24             	mov    %eax,(%esp)
  8005a6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005a8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8005ab:	e9 e7 fe ff ff       	jmp    800497 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8005b0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b3:	8d 50 04             	lea    0x4(%eax),%edx
  8005b6:	89 55 14             	mov    %edx,0x14(%ebp)
  8005b9:	8b 00                	mov    (%eax),%eax
  8005bb:	89 c2                	mov    %eax,%edx
  8005bd:	c1 fa 1f             	sar    $0x1f,%edx
  8005c0:	31 d0                	xor    %edx,%eax
  8005c2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8005c4:	83 f8 06             	cmp    $0x6,%eax
  8005c7:	7f 0b                	jg     8005d4 <vprintfmt+0x162>
  8005c9:	8b 14 85 88 12 80 00 	mov    0x801288(,%eax,4),%edx
  8005d0:	85 d2                	test   %edx,%edx
  8005d2:	75 20                	jne    8005f4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  8005d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005d8:	c7 44 24 08 b8 10 80 	movl   $0x8010b8,0x8(%esp)
  8005df:	00 
  8005e0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005e4:	89 34 24             	mov    %esi,(%esp)
  8005e7:	e8 5e fe ff ff       	call   80044a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ec:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8005ef:	e9 a3 fe ff ff       	jmp    800497 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8005f4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8005f8:	c7 44 24 08 c1 10 80 	movl   $0x8010c1,0x8(%esp)
  8005ff:	00 
  800600:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800604:	89 34 24             	mov    %esi,(%esp)
  800607:	e8 3e fe ff ff       	call   80044a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80060c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80060f:	e9 83 fe ff ff       	jmp    800497 <vprintfmt+0x25>
  800614:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800617:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80061a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80061d:	8b 45 14             	mov    0x14(%ebp),%eax
  800620:	8d 50 04             	lea    0x4(%eax),%edx
  800623:	89 55 14             	mov    %edx,0x14(%ebp)
  800626:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800628:	85 ff                	test   %edi,%edi
  80062a:	b8 b1 10 80 00       	mov    $0x8010b1,%eax
  80062f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800632:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800636:	74 06                	je     80063e <vprintfmt+0x1cc>
  800638:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  80063c:	7f 16                	jg     800654 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80063e:	0f b6 17             	movzbl (%edi),%edx
  800641:	0f be c2             	movsbl %dl,%eax
  800644:	83 c7 01             	add    $0x1,%edi
  800647:	85 c0                	test   %eax,%eax
  800649:	0f 85 9f 00 00 00    	jne    8006ee <vprintfmt+0x27c>
  80064f:	e9 8b 00 00 00       	jmp    8006df <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800654:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800658:	89 3c 24             	mov    %edi,(%esp)
  80065b:	e8 c2 02 00 00       	call   800922 <strnlen>
  800660:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800663:	29 c2                	sub    %eax,%edx
  800665:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800668:	85 d2                	test   %edx,%edx
  80066a:	7e d2                	jle    80063e <vprintfmt+0x1cc>
					putch(padc, putdat);
  80066c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800670:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800673:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800676:	89 d7                	mov    %edx,%edi
  800678:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80067c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80067f:	89 04 24             	mov    %eax,(%esp)
  800682:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800684:	83 ef 01             	sub    $0x1,%edi
  800687:	75 ef                	jne    800678 <vprintfmt+0x206>
  800689:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80068c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80068f:	eb ad                	jmp    80063e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800691:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800695:	74 20                	je     8006b7 <vprintfmt+0x245>
  800697:	0f be d2             	movsbl %dl,%edx
  80069a:	83 ea 20             	sub    $0x20,%edx
  80069d:	83 fa 5e             	cmp    $0x5e,%edx
  8006a0:	76 15                	jbe    8006b7 <vprintfmt+0x245>
					putch('?', putdat);
  8006a2:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8006a5:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006a9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8006b0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8006b3:	ff d1                	call   *%ecx
  8006b5:	eb 0f                	jmp    8006c6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  8006b7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8006ba:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006be:	89 04 24             	mov    %eax,(%esp)
  8006c1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8006c4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006c6:	83 eb 01             	sub    $0x1,%ebx
  8006c9:	0f b6 17             	movzbl (%edi),%edx
  8006cc:	0f be c2             	movsbl %dl,%eax
  8006cf:	83 c7 01             	add    $0x1,%edi
  8006d2:	85 c0                	test   %eax,%eax
  8006d4:	75 24                	jne    8006fa <vprintfmt+0x288>
  8006d6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8006d9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006dc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006df:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006e2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006e6:	0f 8e ab fd ff ff    	jle    800497 <vprintfmt+0x25>
  8006ec:	eb 20                	jmp    80070e <vprintfmt+0x29c>
  8006ee:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8006f1:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8006f4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8006f7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006fa:	85 f6                	test   %esi,%esi
  8006fc:	78 93                	js     800691 <vprintfmt+0x21f>
  8006fe:	83 ee 01             	sub    $0x1,%esi
  800701:	79 8e                	jns    800691 <vprintfmt+0x21f>
  800703:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800706:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800709:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80070c:	eb d1                	jmp    8006df <vprintfmt+0x26d>
  80070e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800711:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800715:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80071c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80071e:	83 ef 01             	sub    $0x1,%edi
  800721:	75 ee                	jne    800711 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800723:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800726:	e9 6c fd ff ff       	jmp    800497 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80072b:	83 fa 01             	cmp    $0x1,%edx
  80072e:	66 90                	xchg   %ax,%ax
  800730:	7e 16                	jle    800748 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800732:	8b 45 14             	mov    0x14(%ebp),%eax
  800735:	8d 50 08             	lea    0x8(%eax),%edx
  800738:	89 55 14             	mov    %edx,0x14(%ebp)
  80073b:	8b 10                	mov    (%eax),%edx
  80073d:	8b 48 04             	mov    0x4(%eax),%ecx
  800740:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800743:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800746:	eb 32                	jmp    80077a <vprintfmt+0x308>
	else if (lflag)
  800748:	85 d2                	test   %edx,%edx
  80074a:	74 18                	je     800764 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  80074c:	8b 45 14             	mov    0x14(%ebp),%eax
  80074f:	8d 50 04             	lea    0x4(%eax),%edx
  800752:	89 55 14             	mov    %edx,0x14(%ebp)
  800755:	8b 00                	mov    (%eax),%eax
  800757:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80075a:	89 c1                	mov    %eax,%ecx
  80075c:	c1 f9 1f             	sar    $0x1f,%ecx
  80075f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800762:	eb 16                	jmp    80077a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800764:	8b 45 14             	mov    0x14(%ebp),%eax
  800767:	8d 50 04             	lea    0x4(%eax),%edx
  80076a:	89 55 14             	mov    %edx,0x14(%ebp)
  80076d:	8b 00                	mov    (%eax),%eax
  80076f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800772:	89 c7                	mov    %eax,%edi
  800774:	c1 ff 1f             	sar    $0x1f,%edi
  800777:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80077a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80077d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800780:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800785:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800789:	79 7d                	jns    800808 <vprintfmt+0x396>
				putch('-', putdat);
  80078b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80078f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800796:	ff d6                	call   *%esi
				num = -(long long) num;
  800798:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80079b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80079e:	f7 d8                	neg    %eax
  8007a0:	83 d2 00             	adc    $0x0,%edx
  8007a3:	f7 da                	neg    %edx
			}
			base = 10;
  8007a5:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8007aa:	eb 5c                	jmp    800808 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8007ac:	8d 45 14             	lea    0x14(%ebp),%eax
  8007af:	e8 3f fc ff ff       	call   8003f3 <getuint>
			base = 10;
  8007b4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8007b9:	eb 4d                	jmp    800808 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  8007bb:	8d 45 14             	lea    0x14(%ebp),%eax
  8007be:	e8 30 fc ff ff       	call   8003f3 <getuint>
			base = 8;
  8007c3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007c8:	eb 3e                	jmp    800808 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  8007ca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007ce:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8007d5:	ff d6                	call   *%esi
			putch('x', putdat);
  8007d7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007db:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8007e2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007e7:	8d 50 04             	lea    0x4(%eax),%edx
  8007ea:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007ed:	8b 00                	mov    (%eax),%eax
  8007ef:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007f4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007f9:	eb 0d                	jmp    800808 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007fb:	8d 45 14             	lea    0x14(%ebp),%eax
  8007fe:	e8 f0 fb ff ff       	call   8003f3 <getuint>
			base = 16;
  800803:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800808:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80080c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800810:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800813:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800817:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80081b:	89 04 24             	mov    %eax,(%esp)
  80081e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800822:	89 da                	mov    %ebx,%edx
  800824:	89 f0                	mov    %esi,%eax
  800826:	e8 d5 fa ff ff       	call   800300 <printnum>
			break;
  80082b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80082e:	e9 64 fc ff ff       	jmp    800497 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800833:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800837:	89 0c 24             	mov    %ecx,(%esp)
  80083a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80083c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80083f:	e9 53 fc ff ff       	jmp    800497 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800844:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800848:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  80084f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800851:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800855:	0f 84 3c fc ff ff    	je     800497 <vprintfmt+0x25>
  80085b:	83 ef 01             	sub    $0x1,%edi
  80085e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800862:	75 f7                	jne    80085b <vprintfmt+0x3e9>
  800864:	e9 2e fc ff ff       	jmp    800497 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800869:	83 c4 4c             	add    $0x4c,%esp
  80086c:	5b                   	pop    %ebx
  80086d:	5e                   	pop    %esi
  80086e:	5f                   	pop    %edi
  80086f:	5d                   	pop    %ebp
  800870:	c3                   	ret    

00800871 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800871:	55                   	push   %ebp
  800872:	89 e5                	mov    %esp,%ebp
  800874:	83 ec 28             	sub    $0x28,%esp
  800877:	8b 45 08             	mov    0x8(%ebp),%eax
  80087a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80087d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800880:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800884:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800887:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80088e:	85 d2                	test   %edx,%edx
  800890:	7e 30                	jle    8008c2 <vsnprintf+0x51>
  800892:	85 c0                	test   %eax,%eax
  800894:	74 2c                	je     8008c2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800896:	8b 45 14             	mov    0x14(%ebp),%eax
  800899:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80089d:	8b 45 10             	mov    0x10(%ebp),%eax
  8008a0:	89 44 24 08          	mov    %eax,0x8(%esp)
  8008a4:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8008a7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8008ab:	c7 04 24 2d 04 80 00 	movl   $0x80042d,(%esp)
  8008b2:	e8 bb fb ff ff       	call   800472 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8008b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8008ba:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8008c0:	eb 05                	jmp    8008c7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8008c2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8008c7:	c9                   	leave  
  8008c8:	c3                   	ret    

008008c9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8008c9:	55                   	push   %ebp
  8008ca:	89 e5                	mov    %esp,%ebp
  8008cc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8008cf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8008d2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8008d6:	8b 45 10             	mov    0x10(%ebp),%eax
  8008d9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8008dd:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008e0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8008e4:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e7:	89 04 24             	mov    %eax,(%esp)
  8008ea:	e8 82 ff ff ff       	call   800871 <vsnprintf>
	va_end(ap);

	return rc;
}
  8008ef:	c9                   	leave  
  8008f0:	c3                   	ret    
  8008f1:	66 90                	xchg   %ax,%ax
  8008f3:	66 90                	xchg   %ax,%ax
  8008f5:	66 90                	xchg   %ax,%ax
  8008f7:	66 90                	xchg   %ax,%ax
  8008f9:	66 90                	xchg   %ax,%ax
  8008fb:	66 90                	xchg   %ax,%ax
  8008fd:	66 90                	xchg   %ax,%ax
  8008ff:	90                   	nop

00800900 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800900:	55                   	push   %ebp
  800901:	89 e5                	mov    %esp,%ebp
  800903:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800906:	80 3a 00             	cmpb   $0x0,(%edx)
  800909:	74 10                	je     80091b <strlen+0x1b>
  80090b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800910:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800913:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800917:	75 f7                	jne    800910 <strlen+0x10>
  800919:	eb 05                	jmp    800920 <strlen+0x20>
  80091b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800920:	5d                   	pop    %ebp
  800921:	c3                   	ret    

00800922 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800922:	55                   	push   %ebp
  800923:	89 e5                	mov    %esp,%ebp
  800925:	53                   	push   %ebx
  800926:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800929:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80092c:	85 c9                	test   %ecx,%ecx
  80092e:	74 1c                	je     80094c <strnlen+0x2a>
  800930:	80 3b 00             	cmpb   $0x0,(%ebx)
  800933:	74 1e                	je     800953 <strnlen+0x31>
  800935:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80093a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80093c:	39 ca                	cmp    %ecx,%edx
  80093e:	74 18                	je     800958 <strnlen+0x36>
  800940:	83 c2 01             	add    $0x1,%edx
  800943:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800948:	75 f0                	jne    80093a <strnlen+0x18>
  80094a:	eb 0c                	jmp    800958 <strnlen+0x36>
  80094c:	b8 00 00 00 00       	mov    $0x0,%eax
  800951:	eb 05                	jmp    800958 <strnlen+0x36>
  800953:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800958:	5b                   	pop    %ebx
  800959:	5d                   	pop    %ebp
  80095a:	c3                   	ret    

0080095b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80095b:	55                   	push   %ebp
  80095c:	89 e5                	mov    %esp,%ebp
  80095e:	53                   	push   %ebx
  80095f:	8b 45 08             	mov    0x8(%ebp),%eax
  800962:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800965:	89 c2                	mov    %eax,%edx
  800967:	0f b6 19             	movzbl (%ecx),%ebx
  80096a:	88 1a                	mov    %bl,(%edx)
  80096c:	83 c2 01             	add    $0x1,%edx
  80096f:	83 c1 01             	add    $0x1,%ecx
  800972:	84 db                	test   %bl,%bl
  800974:	75 f1                	jne    800967 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800976:	5b                   	pop    %ebx
  800977:	5d                   	pop    %ebp
  800978:	c3                   	ret    

00800979 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800979:	55                   	push   %ebp
  80097a:	89 e5                	mov    %esp,%ebp
  80097c:	53                   	push   %ebx
  80097d:	83 ec 08             	sub    $0x8,%esp
  800980:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800983:	89 1c 24             	mov    %ebx,(%esp)
  800986:	e8 75 ff ff ff       	call   800900 <strlen>
	strcpy(dst + len, src);
  80098b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80098e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800992:	01 d8                	add    %ebx,%eax
  800994:	89 04 24             	mov    %eax,(%esp)
  800997:	e8 bf ff ff ff       	call   80095b <strcpy>
	return dst;
}
  80099c:	89 d8                	mov    %ebx,%eax
  80099e:	83 c4 08             	add    $0x8,%esp
  8009a1:	5b                   	pop    %ebx
  8009a2:	5d                   	pop    %ebp
  8009a3:	c3                   	ret    

008009a4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8009a4:	55                   	push   %ebp
  8009a5:	89 e5                	mov    %esp,%ebp
  8009a7:	56                   	push   %esi
  8009a8:	53                   	push   %ebx
  8009a9:	8b 75 08             	mov    0x8(%ebp),%esi
  8009ac:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009af:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8009b2:	85 db                	test   %ebx,%ebx
  8009b4:	74 16                	je     8009cc <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  8009b6:	01 f3                	add    %esi,%ebx
  8009b8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  8009ba:	0f b6 02             	movzbl (%edx),%eax
  8009bd:	88 01                	mov    %al,(%ecx)
  8009bf:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8009c2:	80 3a 01             	cmpb   $0x1,(%edx)
  8009c5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8009c8:	39 d9                	cmp    %ebx,%ecx
  8009ca:	75 ee                	jne    8009ba <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8009cc:	89 f0                	mov    %esi,%eax
  8009ce:	5b                   	pop    %ebx
  8009cf:	5e                   	pop    %esi
  8009d0:	5d                   	pop    %ebp
  8009d1:	c3                   	ret    

008009d2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8009d2:	55                   	push   %ebp
  8009d3:	89 e5                	mov    %esp,%ebp
  8009d5:	57                   	push   %edi
  8009d6:	56                   	push   %esi
  8009d7:	53                   	push   %ebx
  8009d8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009db:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8009de:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8009e1:	89 f8                	mov    %edi,%eax
  8009e3:	85 f6                	test   %esi,%esi
  8009e5:	74 33                	je     800a1a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  8009e7:	83 fe 01             	cmp    $0x1,%esi
  8009ea:	74 25                	je     800a11 <strlcpy+0x3f>
  8009ec:	0f b6 0b             	movzbl (%ebx),%ecx
  8009ef:	84 c9                	test   %cl,%cl
  8009f1:	74 22                	je     800a15 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  8009f3:	83 ee 02             	sub    $0x2,%esi
  8009f6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8009fb:	88 08                	mov    %cl,(%eax)
  8009fd:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800a00:	39 f2                	cmp    %esi,%edx
  800a02:	74 13                	je     800a17 <strlcpy+0x45>
  800a04:	83 c2 01             	add    $0x1,%edx
  800a07:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  800a0b:	84 c9                	test   %cl,%cl
  800a0d:	75 ec                	jne    8009fb <strlcpy+0x29>
  800a0f:	eb 06                	jmp    800a17 <strlcpy+0x45>
  800a11:	89 f8                	mov    %edi,%eax
  800a13:	eb 02                	jmp    800a17 <strlcpy+0x45>
  800a15:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800a17:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800a1a:	29 f8                	sub    %edi,%eax
}
  800a1c:	5b                   	pop    %ebx
  800a1d:	5e                   	pop    %esi
  800a1e:	5f                   	pop    %edi
  800a1f:	5d                   	pop    %ebp
  800a20:	c3                   	ret    

00800a21 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800a21:	55                   	push   %ebp
  800a22:	89 e5                	mov    %esp,%ebp
  800a24:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a27:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800a2a:	0f b6 01             	movzbl (%ecx),%eax
  800a2d:	84 c0                	test   %al,%al
  800a2f:	74 15                	je     800a46 <strcmp+0x25>
  800a31:	3a 02                	cmp    (%edx),%al
  800a33:	75 11                	jne    800a46 <strcmp+0x25>
		p++, q++;
  800a35:	83 c1 01             	add    $0x1,%ecx
  800a38:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800a3b:	0f b6 01             	movzbl (%ecx),%eax
  800a3e:	84 c0                	test   %al,%al
  800a40:	74 04                	je     800a46 <strcmp+0x25>
  800a42:	3a 02                	cmp    (%edx),%al
  800a44:	74 ef                	je     800a35 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800a46:	0f b6 c0             	movzbl %al,%eax
  800a49:	0f b6 12             	movzbl (%edx),%edx
  800a4c:	29 d0                	sub    %edx,%eax
}
  800a4e:	5d                   	pop    %ebp
  800a4f:	c3                   	ret    

00800a50 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800a50:	55                   	push   %ebp
  800a51:	89 e5                	mov    %esp,%ebp
  800a53:	56                   	push   %esi
  800a54:	53                   	push   %ebx
  800a55:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a58:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a5b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800a5e:	85 f6                	test   %esi,%esi
  800a60:	74 29                	je     800a8b <strncmp+0x3b>
  800a62:	0f b6 03             	movzbl (%ebx),%eax
  800a65:	84 c0                	test   %al,%al
  800a67:	74 30                	je     800a99 <strncmp+0x49>
  800a69:	3a 02                	cmp    (%edx),%al
  800a6b:	75 2c                	jne    800a99 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800a6d:	8d 43 01             	lea    0x1(%ebx),%eax
  800a70:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800a72:	89 c3                	mov    %eax,%ebx
  800a74:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800a77:	39 f0                	cmp    %esi,%eax
  800a79:	74 17                	je     800a92 <strncmp+0x42>
  800a7b:	0f b6 08             	movzbl (%eax),%ecx
  800a7e:	84 c9                	test   %cl,%cl
  800a80:	74 17                	je     800a99 <strncmp+0x49>
  800a82:	83 c0 01             	add    $0x1,%eax
  800a85:	3a 0a                	cmp    (%edx),%cl
  800a87:	74 e9                	je     800a72 <strncmp+0x22>
  800a89:	eb 0e                	jmp    800a99 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a8b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a90:	eb 0f                	jmp    800aa1 <strncmp+0x51>
  800a92:	b8 00 00 00 00       	mov    $0x0,%eax
  800a97:	eb 08                	jmp    800aa1 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a99:	0f b6 03             	movzbl (%ebx),%eax
  800a9c:	0f b6 12             	movzbl (%edx),%edx
  800a9f:	29 d0                	sub    %edx,%eax
}
  800aa1:	5b                   	pop    %ebx
  800aa2:	5e                   	pop    %esi
  800aa3:	5d                   	pop    %ebp
  800aa4:	c3                   	ret    

00800aa5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800aa5:	55                   	push   %ebp
  800aa6:	89 e5                	mov    %esp,%ebp
  800aa8:	53                   	push   %ebx
  800aa9:	8b 45 08             	mov    0x8(%ebp),%eax
  800aac:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800aaf:	0f b6 18             	movzbl (%eax),%ebx
  800ab2:	84 db                	test   %bl,%bl
  800ab4:	74 1d                	je     800ad3 <strchr+0x2e>
  800ab6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800ab8:	38 d3                	cmp    %dl,%bl
  800aba:	75 06                	jne    800ac2 <strchr+0x1d>
  800abc:	eb 1a                	jmp    800ad8 <strchr+0x33>
  800abe:	38 ca                	cmp    %cl,%dl
  800ac0:	74 16                	je     800ad8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800ac2:	83 c0 01             	add    $0x1,%eax
  800ac5:	0f b6 10             	movzbl (%eax),%edx
  800ac8:	84 d2                	test   %dl,%dl
  800aca:	75 f2                	jne    800abe <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800acc:	b8 00 00 00 00       	mov    $0x0,%eax
  800ad1:	eb 05                	jmp    800ad8 <strchr+0x33>
  800ad3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ad8:	5b                   	pop    %ebx
  800ad9:	5d                   	pop    %ebp
  800ada:	c3                   	ret    

00800adb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800adb:	55                   	push   %ebp
  800adc:	89 e5                	mov    %esp,%ebp
  800ade:	53                   	push   %ebx
  800adf:	8b 45 08             	mov    0x8(%ebp),%eax
  800ae2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800ae5:	0f b6 18             	movzbl (%eax),%ebx
  800ae8:	84 db                	test   %bl,%bl
  800aea:	74 16                	je     800b02 <strfind+0x27>
  800aec:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800aee:	38 d3                	cmp    %dl,%bl
  800af0:	75 06                	jne    800af8 <strfind+0x1d>
  800af2:	eb 0e                	jmp    800b02 <strfind+0x27>
  800af4:	38 ca                	cmp    %cl,%dl
  800af6:	74 0a                	je     800b02 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800af8:	83 c0 01             	add    $0x1,%eax
  800afb:	0f b6 10             	movzbl (%eax),%edx
  800afe:	84 d2                	test   %dl,%dl
  800b00:	75 f2                	jne    800af4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800b02:	5b                   	pop    %ebx
  800b03:	5d                   	pop    %ebp
  800b04:	c3                   	ret    

00800b05 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800b05:	55                   	push   %ebp
  800b06:	89 e5                	mov    %esp,%ebp
  800b08:	83 ec 0c             	sub    $0xc,%esp
  800b0b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b0e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b11:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800b14:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b17:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b1a:	85 c9                	test   %ecx,%ecx
  800b1c:	74 36                	je     800b54 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b1e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b24:	75 28                	jne    800b4e <memset+0x49>
  800b26:	f6 c1 03             	test   $0x3,%cl
  800b29:	75 23                	jne    800b4e <memset+0x49>
		c &= 0xFF;
  800b2b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b2f:	89 d3                	mov    %edx,%ebx
  800b31:	c1 e3 08             	shl    $0x8,%ebx
  800b34:	89 d6                	mov    %edx,%esi
  800b36:	c1 e6 18             	shl    $0x18,%esi
  800b39:	89 d0                	mov    %edx,%eax
  800b3b:	c1 e0 10             	shl    $0x10,%eax
  800b3e:	09 f0                	or     %esi,%eax
  800b40:	09 c2                	or     %eax,%edx
  800b42:	89 d0                	mov    %edx,%eax
  800b44:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800b46:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800b49:	fc                   	cld    
  800b4a:	f3 ab                	rep stos %eax,%es:(%edi)
  800b4c:	eb 06                	jmp    800b54 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b4e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b51:	fc                   	cld    
  800b52:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800b54:	89 f8                	mov    %edi,%eax
  800b56:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b59:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b5c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b5f:	89 ec                	mov    %ebp,%esp
  800b61:	5d                   	pop    %ebp
  800b62:	c3                   	ret    

00800b63 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b63:	55                   	push   %ebp
  800b64:	89 e5                	mov    %esp,%ebp
  800b66:	83 ec 08             	sub    $0x8,%esp
  800b69:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b6c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800b6f:	8b 45 08             	mov    0x8(%ebp),%eax
  800b72:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b75:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b78:	39 c6                	cmp    %eax,%esi
  800b7a:	73 36                	jae    800bb2 <memmove+0x4f>
  800b7c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b7f:	39 d0                	cmp    %edx,%eax
  800b81:	73 2f                	jae    800bb2 <memmove+0x4f>
		s += n;
		d += n;
  800b83:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b86:	f6 c2 03             	test   $0x3,%dl
  800b89:	75 1b                	jne    800ba6 <memmove+0x43>
  800b8b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b91:	75 13                	jne    800ba6 <memmove+0x43>
  800b93:	f6 c1 03             	test   $0x3,%cl
  800b96:	75 0e                	jne    800ba6 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800b98:	83 ef 04             	sub    $0x4,%edi
  800b9b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800b9e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800ba1:	fd                   	std    
  800ba2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ba4:	eb 09                	jmp    800baf <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800ba6:	83 ef 01             	sub    $0x1,%edi
  800ba9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800bac:	fd                   	std    
  800bad:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800baf:	fc                   	cld    
  800bb0:	eb 20                	jmp    800bd2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bb2:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800bb8:	75 13                	jne    800bcd <memmove+0x6a>
  800bba:	a8 03                	test   $0x3,%al
  800bbc:	75 0f                	jne    800bcd <memmove+0x6a>
  800bbe:	f6 c1 03             	test   $0x3,%cl
  800bc1:	75 0a                	jne    800bcd <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800bc3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800bc6:	89 c7                	mov    %eax,%edi
  800bc8:	fc                   	cld    
  800bc9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bcb:	eb 05                	jmp    800bd2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800bcd:	89 c7                	mov    %eax,%edi
  800bcf:	fc                   	cld    
  800bd0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800bd2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800bd5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800bd8:	89 ec                	mov    %ebp,%esp
  800bda:	5d                   	pop    %ebp
  800bdb:	c3                   	ret    

00800bdc <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800bdc:	55                   	push   %ebp
  800bdd:	89 e5                	mov    %esp,%ebp
  800bdf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800be2:	8b 45 10             	mov    0x10(%ebp),%eax
  800be5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800be9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800bec:	89 44 24 04          	mov    %eax,0x4(%esp)
  800bf0:	8b 45 08             	mov    0x8(%ebp),%eax
  800bf3:	89 04 24             	mov    %eax,(%esp)
  800bf6:	e8 68 ff ff ff       	call   800b63 <memmove>
}
  800bfb:	c9                   	leave  
  800bfc:	c3                   	ret    

00800bfd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800bfd:	55                   	push   %ebp
  800bfe:	89 e5                	mov    %esp,%ebp
  800c00:	57                   	push   %edi
  800c01:	56                   	push   %esi
  800c02:	53                   	push   %ebx
  800c03:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800c06:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c09:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c0c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800c0f:	85 c0                	test   %eax,%eax
  800c11:	74 36                	je     800c49 <memcmp+0x4c>
		if (*s1 != *s2)
  800c13:	0f b6 03             	movzbl (%ebx),%eax
  800c16:	0f b6 0e             	movzbl (%esi),%ecx
  800c19:	38 c8                	cmp    %cl,%al
  800c1b:	75 17                	jne    800c34 <memcmp+0x37>
  800c1d:	ba 00 00 00 00       	mov    $0x0,%edx
  800c22:	eb 1a                	jmp    800c3e <memcmp+0x41>
  800c24:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800c29:	83 c2 01             	add    $0x1,%edx
  800c2c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800c30:	38 c8                	cmp    %cl,%al
  800c32:	74 0a                	je     800c3e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800c34:	0f b6 c0             	movzbl %al,%eax
  800c37:	0f b6 c9             	movzbl %cl,%ecx
  800c3a:	29 c8                	sub    %ecx,%eax
  800c3c:	eb 10                	jmp    800c4e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c3e:	39 fa                	cmp    %edi,%edx
  800c40:	75 e2                	jne    800c24 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c42:	b8 00 00 00 00       	mov    $0x0,%eax
  800c47:	eb 05                	jmp    800c4e <memcmp+0x51>
  800c49:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c4e:	5b                   	pop    %ebx
  800c4f:	5e                   	pop    %esi
  800c50:	5f                   	pop    %edi
  800c51:	5d                   	pop    %ebp
  800c52:	c3                   	ret    

00800c53 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c53:	55                   	push   %ebp
  800c54:	89 e5                	mov    %esp,%ebp
  800c56:	53                   	push   %ebx
  800c57:	8b 45 08             	mov    0x8(%ebp),%eax
  800c5a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800c5d:	89 c2                	mov    %eax,%edx
  800c5f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800c62:	39 d0                	cmp    %edx,%eax
  800c64:	73 13                	jae    800c79 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c66:	89 d9                	mov    %ebx,%ecx
  800c68:	38 18                	cmp    %bl,(%eax)
  800c6a:	75 06                	jne    800c72 <memfind+0x1f>
  800c6c:	eb 0b                	jmp    800c79 <memfind+0x26>
  800c6e:	38 08                	cmp    %cl,(%eax)
  800c70:	74 07                	je     800c79 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c72:	83 c0 01             	add    $0x1,%eax
  800c75:	39 d0                	cmp    %edx,%eax
  800c77:	75 f5                	jne    800c6e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c79:	5b                   	pop    %ebx
  800c7a:	5d                   	pop    %ebp
  800c7b:	c3                   	ret    

00800c7c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c7c:	55                   	push   %ebp
  800c7d:	89 e5                	mov    %esp,%ebp
  800c7f:	57                   	push   %edi
  800c80:	56                   	push   %esi
  800c81:	53                   	push   %ebx
  800c82:	83 ec 04             	sub    $0x4,%esp
  800c85:	8b 55 08             	mov    0x8(%ebp),%edx
  800c88:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c8b:	0f b6 02             	movzbl (%edx),%eax
  800c8e:	3c 09                	cmp    $0x9,%al
  800c90:	74 04                	je     800c96 <strtol+0x1a>
  800c92:	3c 20                	cmp    $0x20,%al
  800c94:	75 0e                	jne    800ca4 <strtol+0x28>
		s++;
  800c96:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c99:	0f b6 02             	movzbl (%edx),%eax
  800c9c:	3c 09                	cmp    $0x9,%al
  800c9e:	74 f6                	je     800c96 <strtol+0x1a>
  800ca0:	3c 20                	cmp    $0x20,%al
  800ca2:	74 f2                	je     800c96 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ca4:	3c 2b                	cmp    $0x2b,%al
  800ca6:	75 0a                	jne    800cb2 <strtol+0x36>
		s++;
  800ca8:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800cab:	bf 00 00 00 00       	mov    $0x0,%edi
  800cb0:	eb 10                	jmp    800cc2 <strtol+0x46>
  800cb2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800cb7:	3c 2d                	cmp    $0x2d,%al
  800cb9:	75 07                	jne    800cc2 <strtol+0x46>
		s++, neg = 1;
  800cbb:	83 c2 01             	add    $0x1,%edx
  800cbe:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800cc2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800cc8:	75 15                	jne    800cdf <strtol+0x63>
  800cca:	80 3a 30             	cmpb   $0x30,(%edx)
  800ccd:	75 10                	jne    800cdf <strtol+0x63>
  800ccf:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800cd3:	75 0a                	jne    800cdf <strtol+0x63>
		s += 2, base = 16;
  800cd5:	83 c2 02             	add    $0x2,%edx
  800cd8:	bb 10 00 00 00       	mov    $0x10,%ebx
  800cdd:	eb 10                	jmp    800cef <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800cdf:	85 db                	test   %ebx,%ebx
  800ce1:	75 0c                	jne    800cef <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ce3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ce5:	80 3a 30             	cmpb   $0x30,(%edx)
  800ce8:	75 05                	jne    800cef <strtol+0x73>
		s++, base = 8;
  800cea:	83 c2 01             	add    $0x1,%edx
  800ced:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800cef:	b8 00 00 00 00       	mov    $0x0,%eax
  800cf4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800cf7:	0f b6 0a             	movzbl (%edx),%ecx
  800cfa:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800cfd:	89 f3                	mov    %esi,%ebx
  800cff:	80 fb 09             	cmp    $0x9,%bl
  800d02:	77 08                	ja     800d0c <strtol+0x90>
			dig = *s - '0';
  800d04:	0f be c9             	movsbl %cl,%ecx
  800d07:	83 e9 30             	sub    $0x30,%ecx
  800d0a:	eb 22                	jmp    800d2e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800d0c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800d0f:	89 f3                	mov    %esi,%ebx
  800d11:	80 fb 19             	cmp    $0x19,%bl
  800d14:	77 08                	ja     800d1e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800d16:	0f be c9             	movsbl %cl,%ecx
  800d19:	83 e9 57             	sub    $0x57,%ecx
  800d1c:	eb 10                	jmp    800d2e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800d1e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800d21:	89 f3                	mov    %esi,%ebx
  800d23:	80 fb 19             	cmp    $0x19,%bl
  800d26:	77 16                	ja     800d3e <strtol+0xc2>
			dig = *s - 'A' + 10;
  800d28:	0f be c9             	movsbl %cl,%ecx
  800d2b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800d2e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800d31:	7d 0f                	jge    800d42 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800d33:	83 c2 01             	add    $0x1,%edx
  800d36:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800d3a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800d3c:	eb b9                	jmp    800cf7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800d3e:	89 c1                	mov    %eax,%ecx
  800d40:	eb 02                	jmp    800d44 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800d42:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800d44:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d48:	74 05                	je     800d4f <strtol+0xd3>
		*endptr = (char *) s;
  800d4a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800d4d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800d4f:	89 ca                	mov    %ecx,%edx
  800d51:	f7 da                	neg    %edx
  800d53:	85 ff                	test   %edi,%edi
  800d55:	0f 45 c2             	cmovne %edx,%eax
}
  800d58:	83 c4 04             	add    $0x4,%esp
  800d5b:	5b                   	pop    %ebx
  800d5c:	5e                   	pop    %esi
  800d5d:	5f                   	pop    %edi
  800d5e:	5d                   	pop    %ebp
  800d5f:	c3                   	ret    

00800d60 <__udivdi3>:
  800d60:	83 ec 1c             	sub    $0x1c,%esp
  800d63:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800d67:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d6b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d6f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d73:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800d77:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800d7b:	85 c0                	test   %eax,%eax
  800d7d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d81:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d85:	89 ea                	mov    %ebp,%edx
  800d87:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800d8b:	75 33                	jne    800dc0 <__udivdi3+0x60>
  800d8d:	39 e9                	cmp    %ebp,%ecx
  800d8f:	77 6f                	ja     800e00 <__udivdi3+0xa0>
  800d91:	85 c9                	test   %ecx,%ecx
  800d93:	89 ce                	mov    %ecx,%esi
  800d95:	75 0b                	jne    800da2 <__udivdi3+0x42>
  800d97:	b8 01 00 00 00       	mov    $0x1,%eax
  800d9c:	31 d2                	xor    %edx,%edx
  800d9e:	f7 f1                	div    %ecx
  800da0:	89 c6                	mov    %eax,%esi
  800da2:	31 d2                	xor    %edx,%edx
  800da4:	89 e8                	mov    %ebp,%eax
  800da6:	f7 f6                	div    %esi
  800da8:	89 c5                	mov    %eax,%ebp
  800daa:	89 f8                	mov    %edi,%eax
  800dac:	f7 f6                	div    %esi
  800dae:	89 ea                	mov    %ebp,%edx
  800db0:	8b 74 24 10          	mov    0x10(%esp),%esi
  800db4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800db8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dbc:	83 c4 1c             	add    $0x1c,%esp
  800dbf:	c3                   	ret    
  800dc0:	39 e8                	cmp    %ebp,%eax
  800dc2:	77 24                	ja     800de8 <__udivdi3+0x88>
  800dc4:	0f bd c8             	bsr    %eax,%ecx
  800dc7:	83 f1 1f             	xor    $0x1f,%ecx
  800dca:	89 0c 24             	mov    %ecx,(%esp)
  800dcd:	75 49                	jne    800e18 <__udivdi3+0xb8>
  800dcf:	8b 74 24 08          	mov    0x8(%esp),%esi
  800dd3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800dd7:	0f 86 ab 00 00 00    	jbe    800e88 <__udivdi3+0x128>
  800ddd:	39 e8                	cmp    %ebp,%eax
  800ddf:	0f 82 a3 00 00 00    	jb     800e88 <__udivdi3+0x128>
  800de5:	8d 76 00             	lea    0x0(%esi),%esi
  800de8:	31 d2                	xor    %edx,%edx
  800dea:	31 c0                	xor    %eax,%eax
  800dec:	8b 74 24 10          	mov    0x10(%esp),%esi
  800df0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800df4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800df8:	83 c4 1c             	add    $0x1c,%esp
  800dfb:	c3                   	ret    
  800dfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e00:	89 f8                	mov    %edi,%eax
  800e02:	f7 f1                	div    %ecx
  800e04:	31 d2                	xor    %edx,%edx
  800e06:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e0a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e0e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e12:	83 c4 1c             	add    $0x1c,%esp
  800e15:	c3                   	ret    
  800e16:	66 90                	xchg   %ax,%ax
  800e18:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e1c:	89 c6                	mov    %eax,%esi
  800e1e:	b8 20 00 00 00       	mov    $0x20,%eax
  800e23:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800e27:	2b 04 24             	sub    (%esp),%eax
  800e2a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800e2e:	d3 e6                	shl    %cl,%esi
  800e30:	89 c1                	mov    %eax,%ecx
  800e32:	d3 ed                	shr    %cl,%ebp
  800e34:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e38:	09 f5                	or     %esi,%ebp
  800e3a:	8b 74 24 04          	mov    0x4(%esp),%esi
  800e3e:	d3 e6                	shl    %cl,%esi
  800e40:	89 c1                	mov    %eax,%ecx
  800e42:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e46:	89 d6                	mov    %edx,%esi
  800e48:	d3 ee                	shr    %cl,%esi
  800e4a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e4e:	d3 e2                	shl    %cl,%edx
  800e50:	89 c1                	mov    %eax,%ecx
  800e52:	d3 ef                	shr    %cl,%edi
  800e54:	09 d7                	or     %edx,%edi
  800e56:	89 f2                	mov    %esi,%edx
  800e58:	89 f8                	mov    %edi,%eax
  800e5a:	f7 f5                	div    %ebp
  800e5c:	89 d6                	mov    %edx,%esi
  800e5e:	89 c7                	mov    %eax,%edi
  800e60:	f7 64 24 04          	mull   0x4(%esp)
  800e64:	39 d6                	cmp    %edx,%esi
  800e66:	72 30                	jb     800e98 <__udivdi3+0x138>
  800e68:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800e6c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e70:	d3 e5                	shl    %cl,%ebp
  800e72:	39 c5                	cmp    %eax,%ebp
  800e74:	73 04                	jae    800e7a <__udivdi3+0x11a>
  800e76:	39 d6                	cmp    %edx,%esi
  800e78:	74 1e                	je     800e98 <__udivdi3+0x138>
  800e7a:	89 f8                	mov    %edi,%eax
  800e7c:	31 d2                	xor    %edx,%edx
  800e7e:	e9 69 ff ff ff       	jmp    800dec <__udivdi3+0x8c>
  800e83:	90                   	nop
  800e84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e88:	31 d2                	xor    %edx,%edx
  800e8a:	b8 01 00 00 00       	mov    $0x1,%eax
  800e8f:	e9 58 ff ff ff       	jmp    800dec <__udivdi3+0x8c>
  800e94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e98:	8d 47 ff             	lea    -0x1(%edi),%eax
  800e9b:	31 d2                	xor    %edx,%edx
  800e9d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800ea1:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800ea5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800ea9:	83 c4 1c             	add    $0x1c,%esp
  800eac:	c3                   	ret    
  800ead:	66 90                	xchg   %ax,%ax
  800eaf:	90                   	nop

00800eb0 <__umoddi3>:
  800eb0:	83 ec 2c             	sub    $0x2c,%esp
  800eb3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800eb7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800ebb:	89 74 24 20          	mov    %esi,0x20(%esp)
  800ebf:	8b 74 24 38          	mov    0x38(%esp),%esi
  800ec3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800ec7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800ecb:	85 c0                	test   %eax,%eax
  800ecd:	89 c2                	mov    %eax,%edx
  800ecf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800ed3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800ed7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800edb:	89 74 24 10          	mov    %esi,0x10(%esp)
  800edf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800ee3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ee7:	75 1f                	jne    800f08 <__umoddi3+0x58>
  800ee9:	39 fe                	cmp    %edi,%esi
  800eeb:	76 63                	jbe    800f50 <__umoddi3+0xa0>
  800eed:	89 c8                	mov    %ecx,%eax
  800eef:	89 fa                	mov    %edi,%edx
  800ef1:	f7 f6                	div    %esi
  800ef3:	89 d0                	mov    %edx,%eax
  800ef5:	31 d2                	xor    %edx,%edx
  800ef7:	8b 74 24 20          	mov    0x20(%esp),%esi
  800efb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800eff:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f03:	83 c4 2c             	add    $0x2c,%esp
  800f06:	c3                   	ret    
  800f07:	90                   	nop
  800f08:	39 f8                	cmp    %edi,%eax
  800f0a:	77 64                	ja     800f70 <__umoddi3+0xc0>
  800f0c:	0f bd e8             	bsr    %eax,%ebp
  800f0f:	83 f5 1f             	xor    $0x1f,%ebp
  800f12:	75 74                	jne    800f88 <__umoddi3+0xd8>
  800f14:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800f18:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800f1c:	0f 87 0e 01 00 00    	ja     801030 <__umoddi3+0x180>
  800f22:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800f26:	29 f1                	sub    %esi,%ecx
  800f28:	19 c7                	sbb    %eax,%edi
  800f2a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800f2e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800f32:	8b 44 24 14          	mov    0x14(%esp),%eax
  800f36:	8b 54 24 18          	mov    0x18(%esp),%edx
  800f3a:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f3e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f42:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f46:	83 c4 2c             	add    $0x2c,%esp
  800f49:	c3                   	ret    
  800f4a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f50:	85 f6                	test   %esi,%esi
  800f52:	89 f5                	mov    %esi,%ebp
  800f54:	75 0b                	jne    800f61 <__umoddi3+0xb1>
  800f56:	b8 01 00 00 00       	mov    $0x1,%eax
  800f5b:	31 d2                	xor    %edx,%edx
  800f5d:	f7 f6                	div    %esi
  800f5f:	89 c5                	mov    %eax,%ebp
  800f61:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f65:	31 d2                	xor    %edx,%edx
  800f67:	f7 f5                	div    %ebp
  800f69:	89 c8                	mov    %ecx,%eax
  800f6b:	f7 f5                	div    %ebp
  800f6d:	eb 84                	jmp    800ef3 <__umoddi3+0x43>
  800f6f:	90                   	nop
  800f70:	89 c8                	mov    %ecx,%eax
  800f72:	89 fa                	mov    %edi,%edx
  800f74:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f78:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f7c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f80:	83 c4 2c             	add    $0x2c,%esp
  800f83:	c3                   	ret    
  800f84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f88:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f8c:	be 20 00 00 00       	mov    $0x20,%esi
  800f91:	89 e9                	mov    %ebp,%ecx
  800f93:	29 ee                	sub    %ebp,%esi
  800f95:	d3 e2                	shl    %cl,%edx
  800f97:	89 f1                	mov    %esi,%ecx
  800f99:	d3 e8                	shr    %cl,%eax
  800f9b:	89 e9                	mov    %ebp,%ecx
  800f9d:	09 d0                	or     %edx,%eax
  800f9f:	89 fa                	mov    %edi,%edx
  800fa1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800fa5:	8b 44 24 10          	mov    0x10(%esp),%eax
  800fa9:	d3 e0                	shl    %cl,%eax
  800fab:	89 f1                	mov    %esi,%ecx
  800fad:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fb1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800fb5:	d3 ea                	shr    %cl,%edx
  800fb7:	89 e9                	mov    %ebp,%ecx
  800fb9:	d3 e7                	shl    %cl,%edi
  800fbb:	89 f1                	mov    %esi,%ecx
  800fbd:	d3 e8                	shr    %cl,%eax
  800fbf:	89 e9                	mov    %ebp,%ecx
  800fc1:	09 f8                	or     %edi,%eax
  800fc3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800fc7:	f7 74 24 0c          	divl   0xc(%esp)
  800fcb:	d3 e7                	shl    %cl,%edi
  800fcd:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800fd1:	89 d7                	mov    %edx,%edi
  800fd3:	f7 64 24 10          	mull   0x10(%esp)
  800fd7:	39 d7                	cmp    %edx,%edi
  800fd9:	89 c1                	mov    %eax,%ecx
  800fdb:	89 54 24 14          	mov    %edx,0x14(%esp)
  800fdf:	72 3b                	jb     80101c <__umoddi3+0x16c>
  800fe1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800fe5:	72 31                	jb     801018 <__umoddi3+0x168>
  800fe7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800feb:	29 c8                	sub    %ecx,%eax
  800fed:	19 d7                	sbb    %edx,%edi
  800fef:	89 e9                	mov    %ebp,%ecx
  800ff1:	89 fa                	mov    %edi,%edx
  800ff3:	d3 e8                	shr    %cl,%eax
  800ff5:	89 f1                	mov    %esi,%ecx
  800ff7:	d3 e2                	shl    %cl,%edx
  800ff9:	89 e9                	mov    %ebp,%ecx
  800ffb:	09 d0                	or     %edx,%eax
  800ffd:	89 fa                	mov    %edi,%edx
  800fff:	d3 ea                	shr    %cl,%edx
  801001:	8b 74 24 20          	mov    0x20(%esp),%esi
  801005:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801009:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  80100d:	83 c4 2c             	add    $0x2c,%esp
  801010:	c3                   	ret    
  801011:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801018:	39 d7                	cmp    %edx,%edi
  80101a:	75 cb                	jne    800fe7 <__umoddi3+0x137>
  80101c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801020:	89 c1                	mov    %eax,%ecx
  801022:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801026:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80102a:	eb bb                	jmp    800fe7 <__umoddi3+0x137>
  80102c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801030:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801034:	0f 82 e8 fe ff ff    	jb     800f22 <__umoddi3+0x72>
  80103a:	e9 f3 fe ff ff       	jmp    800f32 <__umoddi3+0x82>

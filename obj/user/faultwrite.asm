
obj/user/faultwrite：     文件格式 elf32-i386


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
  80002c:	e8 13 00 00 00       	call   800044 <libmain>
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
	*(unsigned*)0 = 0;
  800037:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  80003e:	00 00 00 
}
  800041:	5d                   	pop    %ebp
  800042:	c3                   	ret    
  800043:	90                   	nop

00800044 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800044:	55                   	push   %ebp
  800045:	89 e5                	mov    %esp,%ebp
  800047:	57                   	push   %edi
  800048:	56                   	push   %esi
  800049:	53                   	push   %ebx
  80004a:	83 ec 1c             	sub    $0x1c,%esp
  80004d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800050:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  800053:	e8 30 01 00 00       	call   800188 <sys_getenvid>
	thisenv = envs;
  800058:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  80005f:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  800062:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  800068:	39 c2                	cmp    %eax,%edx
  80006a:	74 25                	je     800091 <libmain+0x4d>
  80006c:	ba 60 00 c0 ee       	mov    $0xeec00060,%edx
  800071:	eb 12                	jmp    800085 <libmain+0x41>
  800073:	8b 4a 48             	mov    0x48(%edx),%ecx
  800076:	83 c2 60             	add    $0x60,%edx
  800079:	39 c1                	cmp    %eax,%ecx
  80007b:	75 08                	jne    800085 <libmain+0x41>
  80007d:	89 3d 04 20 80 00    	mov    %edi,0x802004
  800083:	eb 0c                	jmp    800091 <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  800085:	89 d7                	mov    %edx,%edi
  800087:	85 d2                	test   %edx,%edx
  800089:	75 e8                	jne    800073 <libmain+0x2f>
  80008b:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800091:	85 db                	test   %ebx,%ebx
  800093:	7e 07                	jle    80009c <libmain+0x58>
		binaryname = argv[0];
  800095:	8b 06                	mov    (%esi),%eax
  800097:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80009c:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000a0:	89 1c 24             	mov    %ebx,(%esp)
  8000a3:	e8 8c ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  8000a8:	e8 0b 00 00 00       	call   8000b8 <exit>
}
  8000ad:	83 c4 1c             	add    $0x1c,%esp
  8000b0:	5b                   	pop    %ebx
  8000b1:	5e                   	pop    %esi
  8000b2:	5f                   	pop    %edi
  8000b3:	5d                   	pop    %ebp
  8000b4:	c3                   	ret    
  8000b5:	66 90                	xchg   %ax,%ax
  8000b7:	90                   	nop

008000b8 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000b8:	55                   	push   %ebp
  8000b9:	89 e5                	mov    %esp,%ebp
  8000bb:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000c5:	e8 61 00 00 00       	call   80012b <sys_env_destroy>
}
  8000ca:	c9                   	leave  
  8000cb:	c3                   	ret    

008000cc <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000cc:	55                   	push   %ebp
  8000cd:	89 e5                	mov    %esp,%ebp
  8000cf:	83 ec 0c             	sub    $0xc,%esp
  8000d2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000d5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000d8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000db:	b8 00 00 00 00       	mov    $0x0,%eax
  8000e0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000e3:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e6:	89 c3                	mov    %eax,%ebx
  8000e8:	89 c7                	mov    %eax,%edi
  8000ea:	89 c6                	mov    %eax,%esi
  8000ec:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000ee:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000f1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000f4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000f7:	89 ec                	mov    %ebp,%esp
  8000f9:	5d                   	pop    %ebp
  8000fa:	c3                   	ret    

008000fb <sys_cgetc>:

int
sys_cgetc(void)
{
  8000fb:	55                   	push   %ebp
  8000fc:	89 e5                	mov    %esp,%ebp
  8000fe:	83 ec 0c             	sub    $0xc,%esp
  800101:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800104:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800107:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80010a:	ba 00 00 00 00       	mov    $0x0,%edx
  80010f:	b8 01 00 00 00       	mov    $0x1,%eax
  800114:	89 d1                	mov    %edx,%ecx
  800116:	89 d3                	mov    %edx,%ebx
  800118:	89 d7                	mov    %edx,%edi
  80011a:	89 d6                	mov    %edx,%esi
  80011c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  80011e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800121:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800124:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800127:	89 ec                	mov    %ebp,%esp
  800129:	5d                   	pop    %ebp
  80012a:	c3                   	ret    

0080012b <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80012b:	55                   	push   %ebp
  80012c:	89 e5                	mov    %esp,%ebp
  80012e:	83 ec 38             	sub    $0x38,%esp
  800131:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800134:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800137:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80013a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80013f:	b8 03 00 00 00       	mov    $0x3,%eax
  800144:	8b 55 08             	mov    0x8(%ebp),%edx
  800147:	89 cb                	mov    %ecx,%ebx
  800149:	89 cf                	mov    %ecx,%edi
  80014b:	89 ce                	mov    %ecx,%esi
  80014d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80014f:	85 c0                	test   %eax,%eax
  800151:	7e 28                	jle    80017b <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800153:	89 44 24 10          	mov    %eax,0x10(%esp)
  800157:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  80015e:	00 
  80015f:	c7 44 24 08 3a 10 80 	movl   $0x80103a,0x8(%esp)
  800166:	00 
  800167:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80016e:	00 
  80016f:	c7 04 24 57 10 80 00 	movl   $0x801057,(%esp)
  800176:	e8 3d 00 00 00       	call   8001b8 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80017b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80017e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800181:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800184:	89 ec                	mov    %ebp,%esp
  800186:	5d                   	pop    %ebp
  800187:	c3                   	ret    

00800188 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800188:	55                   	push   %ebp
  800189:	89 e5                	mov    %esp,%ebp
  80018b:	83 ec 0c             	sub    $0xc,%esp
  80018e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800191:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800194:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800197:	ba 00 00 00 00       	mov    $0x0,%edx
  80019c:	b8 02 00 00 00       	mov    $0x2,%eax
  8001a1:	89 d1                	mov    %edx,%ecx
  8001a3:	89 d3                	mov    %edx,%ebx
  8001a5:	89 d7                	mov    %edx,%edi
  8001a7:	89 d6                	mov    %edx,%esi
  8001a9:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  8001ab:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8001ae:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8001b1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8001b4:	89 ec                	mov    %ebp,%esp
  8001b6:	5d                   	pop    %ebp
  8001b7:	c3                   	ret    

008001b8 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8001b8:	55                   	push   %ebp
  8001b9:	89 e5                	mov    %esp,%ebp
  8001bb:	56                   	push   %esi
  8001bc:	53                   	push   %ebx
  8001bd:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8001c0:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  8001c3:	a1 08 20 80 00       	mov    0x802008,%eax
  8001c8:	85 c0                	test   %eax,%eax
  8001ca:	74 10                	je     8001dc <_panic+0x24>
		cprintf("%s: ", argv0);
  8001cc:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001d0:	c7 04 24 65 10 80 00 	movl   $0x801065,(%esp)
  8001d7:	e8 ef 00 00 00       	call   8002cb <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001dc:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8001e2:	e8 a1 ff ff ff       	call   800188 <sys_getenvid>
  8001e7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001ea:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001ee:	8b 55 08             	mov    0x8(%ebp),%edx
  8001f1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001f5:	89 74 24 08          	mov    %esi,0x8(%esp)
  8001f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001fd:	c7 04 24 6c 10 80 00 	movl   $0x80106c,(%esp)
  800204:	e8 c2 00 00 00       	call   8002cb <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800209:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80020d:	8b 45 10             	mov    0x10(%ebp),%eax
  800210:	89 04 24             	mov    %eax,(%esp)
  800213:	e8 52 00 00 00       	call   80026a <vcprintf>
	cprintf("\n");
  800218:	c7 04 24 6a 10 80 00 	movl   $0x80106a,(%esp)
  80021f:	e8 a7 00 00 00       	call   8002cb <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800224:	cc                   	int3   
  800225:	eb fd                	jmp    800224 <_panic+0x6c>
  800227:	90                   	nop

00800228 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800228:	55                   	push   %ebp
  800229:	89 e5                	mov    %esp,%ebp
  80022b:	53                   	push   %ebx
  80022c:	83 ec 14             	sub    $0x14,%esp
  80022f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800232:	8b 03                	mov    (%ebx),%eax
  800234:	8b 55 08             	mov    0x8(%ebp),%edx
  800237:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  80023b:	83 c0 01             	add    $0x1,%eax
  80023e:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800240:	3d ff 00 00 00       	cmp    $0xff,%eax
  800245:	75 19                	jne    800260 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800247:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80024e:	00 
  80024f:	8d 43 08             	lea    0x8(%ebx),%eax
  800252:	89 04 24             	mov    %eax,(%esp)
  800255:	e8 72 fe ff ff       	call   8000cc <sys_cputs>
		b->idx = 0;
  80025a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800260:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800264:	83 c4 14             	add    $0x14,%esp
  800267:	5b                   	pop    %ebx
  800268:	5d                   	pop    %ebp
  800269:	c3                   	ret    

0080026a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80026a:	55                   	push   %ebp
  80026b:	89 e5                	mov    %esp,%ebp
  80026d:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800273:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80027a:	00 00 00 
	b.cnt = 0;
  80027d:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800284:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800287:	8b 45 0c             	mov    0xc(%ebp),%eax
  80028a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80028e:	8b 45 08             	mov    0x8(%ebp),%eax
  800291:	89 44 24 08          	mov    %eax,0x8(%esp)
  800295:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80029b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80029f:	c7 04 24 28 02 80 00 	movl   $0x800228,(%esp)
  8002a6:	e8 b7 01 00 00       	call   800462 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8002ab:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8002b1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002b5:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8002bb:	89 04 24             	mov    %eax,(%esp)
  8002be:	e8 09 fe ff ff       	call   8000cc <sys_cputs>

	return b.cnt;
}
  8002c3:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002c9:	c9                   	leave  
  8002ca:	c3                   	ret    

008002cb <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002cb:	55                   	push   %ebp
  8002cc:	89 e5                	mov    %esp,%ebp
  8002ce:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002d1:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d8:	8b 45 08             	mov    0x8(%ebp),%eax
  8002db:	89 04 24             	mov    %eax,(%esp)
  8002de:	e8 87 ff ff ff       	call   80026a <vcprintf>
	va_end(ap);

	return cnt;
}
  8002e3:	c9                   	leave  
  8002e4:	c3                   	ret    
  8002e5:	66 90                	xchg   %ax,%ax
  8002e7:	66 90                	xchg   %ax,%ax
  8002e9:	66 90                	xchg   %ax,%ax
  8002eb:	66 90                	xchg   %ax,%ax
  8002ed:	66 90                	xchg   %ax,%ax
  8002ef:	90                   	nop

008002f0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002f0:	55                   	push   %ebp
  8002f1:	89 e5                	mov    %esp,%ebp
  8002f3:	57                   	push   %edi
  8002f4:	56                   	push   %esi
  8002f5:	53                   	push   %ebx
  8002f6:	83 ec 4c             	sub    $0x4c,%esp
  8002f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8002fc:	89 d7                	mov    %edx,%edi
  8002fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800301:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800304:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800307:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80030a:	b8 00 00 00 00       	mov    $0x0,%eax
  80030f:	39 d8                	cmp    %ebx,%eax
  800311:	72 17                	jb     80032a <printnum+0x3a>
  800313:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800316:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800319:	76 0f                	jbe    80032a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80031b:	8b 75 14             	mov    0x14(%ebp),%esi
  80031e:	83 ee 01             	sub    $0x1,%esi
  800321:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800324:	85 f6                	test   %esi,%esi
  800326:	7f 63                	jg     80038b <printnum+0x9b>
  800328:	eb 75                	jmp    80039f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80032a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80032d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800331:	8b 45 14             	mov    0x14(%ebp),%eax
  800334:	83 e8 01             	sub    $0x1,%eax
  800337:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80033b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80033e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800342:	8b 44 24 08          	mov    0x8(%esp),%eax
  800346:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80034a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80034d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800350:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800357:	00 
  800358:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80035b:	89 1c 24             	mov    %ebx,(%esp)
  80035e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800361:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800365:	e8 e6 09 00 00       	call   800d50 <__udivdi3>
  80036a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80036d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800370:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800374:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800378:	89 04 24             	mov    %eax,(%esp)
  80037b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80037f:	89 fa                	mov    %edi,%edx
  800381:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800384:	e8 67 ff ff ff       	call   8002f0 <printnum>
  800389:	eb 14                	jmp    80039f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80038b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80038f:	8b 45 18             	mov    0x18(%ebp),%eax
  800392:	89 04 24             	mov    %eax,(%esp)
  800395:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800397:	83 ee 01             	sub    $0x1,%esi
  80039a:	75 ef                	jne    80038b <printnum+0x9b>
  80039c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80039f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003a3:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8003a7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003aa:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8003ae:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8003b5:	00 
  8003b6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8003b9:	89 1c 24             	mov    %ebx,(%esp)
  8003bc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8003bf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003c3:	e8 d8 0a 00 00       	call   800ea0 <__umoddi3>
  8003c8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003cc:	0f be 80 90 10 80 00 	movsbl 0x801090(%eax),%eax
  8003d3:	89 04 24             	mov    %eax,(%esp)
  8003d6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003d9:	ff d0                	call   *%eax
}
  8003db:	83 c4 4c             	add    $0x4c,%esp
  8003de:	5b                   	pop    %ebx
  8003df:	5e                   	pop    %esi
  8003e0:	5f                   	pop    %edi
  8003e1:	5d                   	pop    %ebp
  8003e2:	c3                   	ret    

008003e3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8003e3:	55                   	push   %ebp
  8003e4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8003e6:	83 fa 01             	cmp    $0x1,%edx
  8003e9:	7e 0e                	jle    8003f9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8003eb:	8b 10                	mov    (%eax),%edx
  8003ed:	8d 4a 08             	lea    0x8(%edx),%ecx
  8003f0:	89 08                	mov    %ecx,(%eax)
  8003f2:	8b 02                	mov    (%edx),%eax
  8003f4:	8b 52 04             	mov    0x4(%edx),%edx
  8003f7:	eb 22                	jmp    80041b <getuint+0x38>
	else if (lflag)
  8003f9:	85 d2                	test   %edx,%edx
  8003fb:	74 10                	je     80040d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003fd:	8b 10                	mov    (%eax),%edx
  8003ff:	8d 4a 04             	lea    0x4(%edx),%ecx
  800402:	89 08                	mov    %ecx,(%eax)
  800404:	8b 02                	mov    (%edx),%eax
  800406:	ba 00 00 00 00       	mov    $0x0,%edx
  80040b:	eb 0e                	jmp    80041b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80040d:	8b 10                	mov    (%eax),%edx
  80040f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800412:	89 08                	mov    %ecx,(%eax)
  800414:	8b 02                	mov    (%edx),%eax
  800416:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80041b:	5d                   	pop    %ebp
  80041c:	c3                   	ret    

0080041d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80041d:	55                   	push   %ebp
  80041e:	89 e5                	mov    %esp,%ebp
  800420:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800423:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800427:	8b 10                	mov    (%eax),%edx
  800429:	3b 50 04             	cmp    0x4(%eax),%edx
  80042c:	73 0a                	jae    800438 <sprintputch+0x1b>
		*b->buf++ = ch;
  80042e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800431:	88 0a                	mov    %cl,(%edx)
  800433:	83 c2 01             	add    $0x1,%edx
  800436:	89 10                	mov    %edx,(%eax)
}
  800438:	5d                   	pop    %ebp
  800439:	c3                   	ret    

0080043a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80043a:	55                   	push   %ebp
  80043b:	89 e5                	mov    %esp,%ebp
  80043d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800440:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800443:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800447:	8b 45 10             	mov    0x10(%ebp),%eax
  80044a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80044e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800451:	89 44 24 04          	mov    %eax,0x4(%esp)
  800455:	8b 45 08             	mov    0x8(%ebp),%eax
  800458:	89 04 24             	mov    %eax,(%esp)
  80045b:	e8 02 00 00 00       	call   800462 <vprintfmt>
	va_end(ap);
}
  800460:	c9                   	leave  
  800461:	c3                   	ret    

00800462 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800462:	55                   	push   %ebp
  800463:	89 e5                	mov    %esp,%ebp
  800465:	57                   	push   %edi
  800466:	56                   	push   %esi
  800467:	53                   	push   %ebx
  800468:	83 ec 4c             	sub    $0x4c,%esp
  80046b:	8b 75 08             	mov    0x8(%ebp),%esi
  80046e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800471:	8b 7d 10             	mov    0x10(%ebp),%edi
  800474:	eb 11                	jmp    800487 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800476:	85 c0                	test   %eax,%eax
  800478:	0f 84 db 03 00 00    	je     800859 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80047e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800482:	89 04 24             	mov    %eax,(%esp)
  800485:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800487:	0f b6 07             	movzbl (%edi),%eax
  80048a:	83 c7 01             	add    $0x1,%edi
  80048d:	83 f8 25             	cmp    $0x25,%eax
  800490:	75 e4                	jne    800476 <vprintfmt+0x14>
  800492:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800496:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80049d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8004a4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  8004ab:	ba 00 00 00 00       	mov    $0x0,%edx
  8004b0:	eb 2b                	jmp    8004dd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8004b5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  8004b9:	eb 22                	jmp    8004dd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004bb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8004be:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  8004c2:	eb 19                	jmp    8004dd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  8004c7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8004ce:	eb 0d                	jmp    8004dd <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8004d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004d3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004d6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004dd:	0f b6 0f             	movzbl (%edi),%ecx
  8004e0:	8d 47 01             	lea    0x1(%edi),%eax
  8004e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004e6:	0f b6 07             	movzbl (%edi),%eax
  8004e9:	83 e8 23             	sub    $0x23,%eax
  8004ec:	3c 55                	cmp    $0x55,%al
  8004ee:	0f 87 40 03 00 00    	ja     800834 <vprintfmt+0x3d2>
  8004f4:	0f b6 c0             	movzbl %al,%eax
  8004f7:	ff 24 85 20 11 80 00 	jmp    *0x801120(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8004fe:	83 e9 30             	sub    $0x30,%ecx
  800501:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800504:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800508:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80050b:	83 f9 09             	cmp    $0x9,%ecx
  80050e:	77 57                	ja     800567 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800510:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800513:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800516:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800519:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80051c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80051f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800523:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800526:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800529:	83 f9 09             	cmp    $0x9,%ecx
  80052c:	76 eb                	jbe    800519 <vprintfmt+0xb7>
  80052e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800531:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800534:	eb 34                	jmp    80056a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800536:	8b 45 14             	mov    0x14(%ebp),%eax
  800539:	8d 48 04             	lea    0x4(%eax),%ecx
  80053c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80053f:	8b 00                	mov    (%eax),%eax
  800541:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800544:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800547:	eb 21                	jmp    80056a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800549:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80054d:	0f 88 71 ff ff ff    	js     8004c4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800553:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800556:	eb 85                	jmp    8004dd <vprintfmt+0x7b>
  800558:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80055b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800562:	e9 76 ff ff ff       	jmp    8004dd <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800567:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80056a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80056e:	0f 89 69 ff ff ff    	jns    8004dd <vprintfmt+0x7b>
  800574:	e9 57 ff ff ff       	jmp    8004d0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800579:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80057c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80057f:	e9 59 ff ff ff       	jmp    8004dd <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800584:	8b 45 14             	mov    0x14(%ebp),%eax
  800587:	8d 50 04             	lea    0x4(%eax),%edx
  80058a:	89 55 14             	mov    %edx,0x14(%ebp)
  80058d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800591:	8b 00                	mov    (%eax),%eax
  800593:	89 04 24             	mov    %eax,(%esp)
  800596:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800598:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80059b:	e9 e7 fe ff ff       	jmp    800487 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8005a0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a3:	8d 50 04             	lea    0x4(%eax),%edx
  8005a6:	89 55 14             	mov    %edx,0x14(%ebp)
  8005a9:	8b 00                	mov    (%eax),%eax
  8005ab:	89 c2                	mov    %eax,%edx
  8005ad:	c1 fa 1f             	sar    $0x1f,%edx
  8005b0:	31 d0                	xor    %edx,%eax
  8005b2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8005b4:	83 f8 06             	cmp    $0x6,%eax
  8005b7:	7f 0b                	jg     8005c4 <vprintfmt+0x162>
  8005b9:	8b 14 85 78 12 80 00 	mov    0x801278(,%eax,4),%edx
  8005c0:	85 d2                	test   %edx,%edx
  8005c2:	75 20                	jne    8005e4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  8005c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005c8:	c7 44 24 08 a8 10 80 	movl   $0x8010a8,0x8(%esp)
  8005cf:	00 
  8005d0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005d4:	89 34 24             	mov    %esi,(%esp)
  8005d7:	e8 5e fe ff ff       	call   80043a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005dc:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8005df:	e9 a3 fe ff ff       	jmp    800487 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8005e4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8005e8:	c7 44 24 08 b1 10 80 	movl   $0x8010b1,0x8(%esp)
  8005ef:	00 
  8005f0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005f4:	89 34 24             	mov    %esi,(%esp)
  8005f7:	e8 3e fe ff ff       	call   80043a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005fc:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8005ff:	e9 83 fe ff ff       	jmp    800487 <vprintfmt+0x25>
  800604:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800607:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80060a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80060d:	8b 45 14             	mov    0x14(%ebp),%eax
  800610:	8d 50 04             	lea    0x4(%eax),%edx
  800613:	89 55 14             	mov    %edx,0x14(%ebp)
  800616:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800618:	85 ff                	test   %edi,%edi
  80061a:	b8 a1 10 80 00       	mov    $0x8010a1,%eax
  80061f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800622:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800626:	74 06                	je     80062e <vprintfmt+0x1cc>
  800628:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  80062c:	7f 16                	jg     800644 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80062e:	0f b6 17             	movzbl (%edi),%edx
  800631:	0f be c2             	movsbl %dl,%eax
  800634:	83 c7 01             	add    $0x1,%edi
  800637:	85 c0                	test   %eax,%eax
  800639:	0f 85 9f 00 00 00    	jne    8006de <vprintfmt+0x27c>
  80063f:	e9 8b 00 00 00       	jmp    8006cf <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800644:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800648:	89 3c 24             	mov    %edi,(%esp)
  80064b:	e8 c2 02 00 00       	call   800912 <strnlen>
  800650:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800653:	29 c2                	sub    %eax,%edx
  800655:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800658:	85 d2                	test   %edx,%edx
  80065a:	7e d2                	jle    80062e <vprintfmt+0x1cc>
					putch(padc, putdat);
  80065c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800660:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800663:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800666:	89 d7                	mov    %edx,%edi
  800668:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80066c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80066f:	89 04 24             	mov    %eax,(%esp)
  800672:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800674:	83 ef 01             	sub    $0x1,%edi
  800677:	75 ef                	jne    800668 <vprintfmt+0x206>
  800679:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80067c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80067f:	eb ad                	jmp    80062e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800681:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800685:	74 20                	je     8006a7 <vprintfmt+0x245>
  800687:	0f be d2             	movsbl %dl,%edx
  80068a:	83 ea 20             	sub    $0x20,%edx
  80068d:	83 fa 5e             	cmp    $0x5e,%edx
  800690:	76 15                	jbe    8006a7 <vprintfmt+0x245>
					putch('?', putdat);
  800692:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800695:	89 54 24 04          	mov    %edx,0x4(%esp)
  800699:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8006a0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8006a3:	ff d1                	call   *%ecx
  8006a5:	eb 0f                	jmp    8006b6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  8006a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8006aa:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006ae:	89 04 24             	mov    %eax,(%esp)
  8006b1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8006b4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006b6:	83 eb 01             	sub    $0x1,%ebx
  8006b9:	0f b6 17             	movzbl (%edi),%edx
  8006bc:	0f be c2             	movsbl %dl,%eax
  8006bf:	83 c7 01             	add    $0x1,%edi
  8006c2:	85 c0                	test   %eax,%eax
  8006c4:	75 24                	jne    8006ea <vprintfmt+0x288>
  8006c6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8006c9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006cc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006cf:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006d2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006d6:	0f 8e ab fd ff ff    	jle    800487 <vprintfmt+0x25>
  8006dc:	eb 20                	jmp    8006fe <vprintfmt+0x29c>
  8006de:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8006e1:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8006e4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8006e7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006ea:	85 f6                	test   %esi,%esi
  8006ec:	78 93                	js     800681 <vprintfmt+0x21f>
  8006ee:	83 ee 01             	sub    $0x1,%esi
  8006f1:	79 8e                	jns    800681 <vprintfmt+0x21f>
  8006f3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8006f6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006f9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8006fc:	eb d1                	jmp    8006cf <vprintfmt+0x26d>
  8006fe:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800701:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800705:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80070c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80070e:	83 ef 01             	sub    $0x1,%edi
  800711:	75 ee                	jne    800701 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800713:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800716:	e9 6c fd ff ff       	jmp    800487 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80071b:	83 fa 01             	cmp    $0x1,%edx
  80071e:	66 90                	xchg   %ax,%ax
  800720:	7e 16                	jle    800738 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800722:	8b 45 14             	mov    0x14(%ebp),%eax
  800725:	8d 50 08             	lea    0x8(%eax),%edx
  800728:	89 55 14             	mov    %edx,0x14(%ebp)
  80072b:	8b 10                	mov    (%eax),%edx
  80072d:	8b 48 04             	mov    0x4(%eax),%ecx
  800730:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800733:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800736:	eb 32                	jmp    80076a <vprintfmt+0x308>
	else if (lflag)
  800738:	85 d2                	test   %edx,%edx
  80073a:	74 18                	je     800754 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  80073c:	8b 45 14             	mov    0x14(%ebp),%eax
  80073f:	8d 50 04             	lea    0x4(%eax),%edx
  800742:	89 55 14             	mov    %edx,0x14(%ebp)
  800745:	8b 00                	mov    (%eax),%eax
  800747:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80074a:	89 c1                	mov    %eax,%ecx
  80074c:	c1 f9 1f             	sar    $0x1f,%ecx
  80074f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800752:	eb 16                	jmp    80076a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800754:	8b 45 14             	mov    0x14(%ebp),%eax
  800757:	8d 50 04             	lea    0x4(%eax),%edx
  80075a:	89 55 14             	mov    %edx,0x14(%ebp)
  80075d:	8b 00                	mov    (%eax),%eax
  80075f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800762:	89 c7                	mov    %eax,%edi
  800764:	c1 ff 1f             	sar    $0x1f,%edi
  800767:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80076a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80076d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800770:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800775:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800779:	79 7d                	jns    8007f8 <vprintfmt+0x396>
				putch('-', putdat);
  80077b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80077f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800786:	ff d6                	call   *%esi
				num = -(long long) num;
  800788:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80078b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80078e:	f7 d8                	neg    %eax
  800790:	83 d2 00             	adc    $0x0,%edx
  800793:	f7 da                	neg    %edx
			}
			base = 10;
  800795:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80079a:	eb 5c                	jmp    8007f8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80079c:	8d 45 14             	lea    0x14(%ebp),%eax
  80079f:	e8 3f fc ff ff       	call   8003e3 <getuint>
			base = 10;
  8007a4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8007a9:	eb 4d                	jmp    8007f8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  8007ab:	8d 45 14             	lea    0x14(%ebp),%eax
  8007ae:	e8 30 fc ff ff       	call   8003e3 <getuint>
			base = 8;
  8007b3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007b8:	eb 3e                	jmp    8007f8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  8007ba:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007be:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8007c5:	ff d6                	call   *%esi
			putch('x', putdat);
  8007c7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007cb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8007d2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007d7:	8d 50 04             	lea    0x4(%eax),%edx
  8007da:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007dd:	8b 00                	mov    (%eax),%eax
  8007df:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007e4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007e9:	eb 0d                	jmp    8007f8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007eb:	8d 45 14             	lea    0x14(%ebp),%eax
  8007ee:	e8 f0 fb ff ff       	call   8003e3 <getuint>
			base = 16;
  8007f3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007f8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  8007fc:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800800:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800803:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800807:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80080b:	89 04 24             	mov    %eax,(%esp)
  80080e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800812:	89 da                	mov    %ebx,%edx
  800814:	89 f0                	mov    %esi,%eax
  800816:	e8 d5 fa ff ff       	call   8002f0 <printnum>
			break;
  80081b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80081e:	e9 64 fc ff ff       	jmp    800487 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800823:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800827:	89 0c 24             	mov    %ecx,(%esp)
  80082a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80082c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80082f:	e9 53 fc ff ff       	jmp    800487 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800834:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800838:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  80083f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800841:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800845:	0f 84 3c fc ff ff    	je     800487 <vprintfmt+0x25>
  80084b:	83 ef 01             	sub    $0x1,%edi
  80084e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800852:	75 f7                	jne    80084b <vprintfmt+0x3e9>
  800854:	e9 2e fc ff ff       	jmp    800487 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800859:	83 c4 4c             	add    $0x4c,%esp
  80085c:	5b                   	pop    %ebx
  80085d:	5e                   	pop    %esi
  80085e:	5f                   	pop    %edi
  80085f:	5d                   	pop    %ebp
  800860:	c3                   	ret    

00800861 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800861:	55                   	push   %ebp
  800862:	89 e5                	mov    %esp,%ebp
  800864:	83 ec 28             	sub    $0x28,%esp
  800867:	8b 45 08             	mov    0x8(%ebp),%eax
  80086a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80086d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800870:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800874:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800877:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80087e:	85 d2                	test   %edx,%edx
  800880:	7e 30                	jle    8008b2 <vsnprintf+0x51>
  800882:	85 c0                	test   %eax,%eax
  800884:	74 2c                	je     8008b2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800886:	8b 45 14             	mov    0x14(%ebp),%eax
  800889:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80088d:	8b 45 10             	mov    0x10(%ebp),%eax
  800890:	89 44 24 08          	mov    %eax,0x8(%esp)
  800894:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800897:	89 44 24 04          	mov    %eax,0x4(%esp)
  80089b:	c7 04 24 1d 04 80 00 	movl   $0x80041d,(%esp)
  8008a2:	e8 bb fb ff ff       	call   800462 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8008a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8008aa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8008ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8008b0:	eb 05                	jmp    8008b7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8008b2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8008b7:	c9                   	leave  
  8008b8:	c3                   	ret    

008008b9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8008b9:	55                   	push   %ebp
  8008ba:	89 e5                	mov    %esp,%ebp
  8008bc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8008bf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8008c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8008c6:	8b 45 10             	mov    0x10(%ebp),%eax
  8008c9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8008cd:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8008d4:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d7:	89 04 24             	mov    %eax,(%esp)
  8008da:	e8 82 ff ff ff       	call   800861 <vsnprintf>
	va_end(ap);

	return rc;
}
  8008df:	c9                   	leave  
  8008e0:	c3                   	ret    
  8008e1:	66 90                	xchg   %ax,%ax
  8008e3:	66 90                	xchg   %ax,%ax
  8008e5:	66 90                	xchg   %ax,%ax
  8008e7:	66 90                	xchg   %ax,%ax
  8008e9:	66 90                	xchg   %ax,%ax
  8008eb:	66 90                	xchg   %ax,%ax
  8008ed:	66 90                	xchg   %ax,%ax
  8008ef:	90                   	nop

008008f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008f0:	55                   	push   %ebp
  8008f1:	89 e5                	mov    %esp,%ebp
  8008f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008f6:	80 3a 00             	cmpb   $0x0,(%edx)
  8008f9:	74 10                	je     80090b <strlen+0x1b>
  8008fb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800900:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800903:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800907:	75 f7                	jne    800900 <strlen+0x10>
  800909:	eb 05                	jmp    800910 <strlen+0x20>
  80090b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800910:	5d                   	pop    %ebp
  800911:	c3                   	ret    

00800912 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800912:	55                   	push   %ebp
  800913:	89 e5                	mov    %esp,%ebp
  800915:	53                   	push   %ebx
  800916:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800919:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80091c:	85 c9                	test   %ecx,%ecx
  80091e:	74 1c                	je     80093c <strnlen+0x2a>
  800920:	80 3b 00             	cmpb   $0x0,(%ebx)
  800923:	74 1e                	je     800943 <strnlen+0x31>
  800925:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80092a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80092c:	39 ca                	cmp    %ecx,%edx
  80092e:	74 18                	je     800948 <strnlen+0x36>
  800930:	83 c2 01             	add    $0x1,%edx
  800933:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800938:	75 f0                	jne    80092a <strnlen+0x18>
  80093a:	eb 0c                	jmp    800948 <strnlen+0x36>
  80093c:	b8 00 00 00 00       	mov    $0x0,%eax
  800941:	eb 05                	jmp    800948 <strnlen+0x36>
  800943:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800948:	5b                   	pop    %ebx
  800949:	5d                   	pop    %ebp
  80094a:	c3                   	ret    

0080094b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80094b:	55                   	push   %ebp
  80094c:	89 e5                	mov    %esp,%ebp
  80094e:	53                   	push   %ebx
  80094f:	8b 45 08             	mov    0x8(%ebp),%eax
  800952:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800955:	89 c2                	mov    %eax,%edx
  800957:	0f b6 19             	movzbl (%ecx),%ebx
  80095a:	88 1a                	mov    %bl,(%edx)
  80095c:	83 c2 01             	add    $0x1,%edx
  80095f:	83 c1 01             	add    $0x1,%ecx
  800962:	84 db                	test   %bl,%bl
  800964:	75 f1                	jne    800957 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800966:	5b                   	pop    %ebx
  800967:	5d                   	pop    %ebp
  800968:	c3                   	ret    

00800969 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800969:	55                   	push   %ebp
  80096a:	89 e5                	mov    %esp,%ebp
  80096c:	53                   	push   %ebx
  80096d:	83 ec 08             	sub    $0x8,%esp
  800970:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800973:	89 1c 24             	mov    %ebx,(%esp)
  800976:	e8 75 ff ff ff       	call   8008f0 <strlen>
	strcpy(dst + len, src);
  80097b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80097e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800982:	01 d8                	add    %ebx,%eax
  800984:	89 04 24             	mov    %eax,(%esp)
  800987:	e8 bf ff ff ff       	call   80094b <strcpy>
	return dst;
}
  80098c:	89 d8                	mov    %ebx,%eax
  80098e:	83 c4 08             	add    $0x8,%esp
  800991:	5b                   	pop    %ebx
  800992:	5d                   	pop    %ebp
  800993:	c3                   	ret    

00800994 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800994:	55                   	push   %ebp
  800995:	89 e5                	mov    %esp,%ebp
  800997:	56                   	push   %esi
  800998:	53                   	push   %ebx
  800999:	8b 75 08             	mov    0x8(%ebp),%esi
  80099c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80099f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8009a2:	85 db                	test   %ebx,%ebx
  8009a4:	74 16                	je     8009bc <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  8009a6:	01 f3                	add    %esi,%ebx
  8009a8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  8009aa:	0f b6 02             	movzbl (%edx),%eax
  8009ad:	88 01                	mov    %al,(%ecx)
  8009af:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8009b2:	80 3a 01             	cmpb   $0x1,(%edx)
  8009b5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8009b8:	39 d9                	cmp    %ebx,%ecx
  8009ba:	75 ee                	jne    8009aa <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8009bc:	89 f0                	mov    %esi,%eax
  8009be:	5b                   	pop    %ebx
  8009bf:	5e                   	pop    %esi
  8009c0:	5d                   	pop    %ebp
  8009c1:	c3                   	ret    

008009c2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8009c2:	55                   	push   %ebp
  8009c3:	89 e5                	mov    %esp,%ebp
  8009c5:	57                   	push   %edi
  8009c6:	56                   	push   %esi
  8009c7:	53                   	push   %ebx
  8009c8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009cb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8009ce:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8009d1:	89 f8                	mov    %edi,%eax
  8009d3:	85 f6                	test   %esi,%esi
  8009d5:	74 33                	je     800a0a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  8009d7:	83 fe 01             	cmp    $0x1,%esi
  8009da:	74 25                	je     800a01 <strlcpy+0x3f>
  8009dc:	0f b6 0b             	movzbl (%ebx),%ecx
  8009df:	84 c9                	test   %cl,%cl
  8009e1:	74 22                	je     800a05 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  8009e3:	83 ee 02             	sub    $0x2,%esi
  8009e6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8009eb:	88 08                	mov    %cl,(%eax)
  8009ed:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8009f0:	39 f2                	cmp    %esi,%edx
  8009f2:	74 13                	je     800a07 <strlcpy+0x45>
  8009f4:	83 c2 01             	add    $0x1,%edx
  8009f7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  8009fb:	84 c9                	test   %cl,%cl
  8009fd:	75 ec                	jne    8009eb <strlcpy+0x29>
  8009ff:	eb 06                	jmp    800a07 <strlcpy+0x45>
  800a01:	89 f8                	mov    %edi,%eax
  800a03:	eb 02                	jmp    800a07 <strlcpy+0x45>
  800a05:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800a07:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800a0a:	29 f8                	sub    %edi,%eax
}
  800a0c:	5b                   	pop    %ebx
  800a0d:	5e                   	pop    %esi
  800a0e:	5f                   	pop    %edi
  800a0f:	5d                   	pop    %ebp
  800a10:	c3                   	ret    

00800a11 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800a11:	55                   	push   %ebp
  800a12:	89 e5                	mov    %esp,%ebp
  800a14:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a17:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800a1a:	0f b6 01             	movzbl (%ecx),%eax
  800a1d:	84 c0                	test   %al,%al
  800a1f:	74 15                	je     800a36 <strcmp+0x25>
  800a21:	3a 02                	cmp    (%edx),%al
  800a23:	75 11                	jne    800a36 <strcmp+0x25>
		p++, q++;
  800a25:	83 c1 01             	add    $0x1,%ecx
  800a28:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800a2b:	0f b6 01             	movzbl (%ecx),%eax
  800a2e:	84 c0                	test   %al,%al
  800a30:	74 04                	je     800a36 <strcmp+0x25>
  800a32:	3a 02                	cmp    (%edx),%al
  800a34:	74 ef                	je     800a25 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800a36:	0f b6 c0             	movzbl %al,%eax
  800a39:	0f b6 12             	movzbl (%edx),%edx
  800a3c:	29 d0                	sub    %edx,%eax
}
  800a3e:	5d                   	pop    %ebp
  800a3f:	c3                   	ret    

00800a40 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800a40:	55                   	push   %ebp
  800a41:	89 e5                	mov    %esp,%ebp
  800a43:	56                   	push   %esi
  800a44:	53                   	push   %ebx
  800a45:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a48:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a4b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800a4e:	85 f6                	test   %esi,%esi
  800a50:	74 29                	je     800a7b <strncmp+0x3b>
  800a52:	0f b6 03             	movzbl (%ebx),%eax
  800a55:	84 c0                	test   %al,%al
  800a57:	74 30                	je     800a89 <strncmp+0x49>
  800a59:	3a 02                	cmp    (%edx),%al
  800a5b:	75 2c                	jne    800a89 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800a5d:	8d 43 01             	lea    0x1(%ebx),%eax
  800a60:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800a62:	89 c3                	mov    %eax,%ebx
  800a64:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800a67:	39 f0                	cmp    %esi,%eax
  800a69:	74 17                	je     800a82 <strncmp+0x42>
  800a6b:	0f b6 08             	movzbl (%eax),%ecx
  800a6e:	84 c9                	test   %cl,%cl
  800a70:	74 17                	je     800a89 <strncmp+0x49>
  800a72:	83 c0 01             	add    $0x1,%eax
  800a75:	3a 0a                	cmp    (%edx),%cl
  800a77:	74 e9                	je     800a62 <strncmp+0x22>
  800a79:	eb 0e                	jmp    800a89 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a7b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a80:	eb 0f                	jmp    800a91 <strncmp+0x51>
  800a82:	b8 00 00 00 00       	mov    $0x0,%eax
  800a87:	eb 08                	jmp    800a91 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a89:	0f b6 03             	movzbl (%ebx),%eax
  800a8c:	0f b6 12             	movzbl (%edx),%edx
  800a8f:	29 d0                	sub    %edx,%eax
}
  800a91:	5b                   	pop    %ebx
  800a92:	5e                   	pop    %esi
  800a93:	5d                   	pop    %ebp
  800a94:	c3                   	ret    

00800a95 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800a95:	55                   	push   %ebp
  800a96:	89 e5                	mov    %esp,%ebp
  800a98:	53                   	push   %ebx
  800a99:	8b 45 08             	mov    0x8(%ebp),%eax
  800a9c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a9f:	0f b6 18             	movzbl (%eax),%ebx
  800aa2:	84 db                	test   %bl,%bl
  800aa4:	74 1d                	je     800ac3 <strchr+0x2e>
  800aa6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800aa8:	38 d3                	cmp    %dl,%bl
  800aaa:	75 06                	jne    800ab2 <strchr+0x1d>
  800aac:	eb 1a                	jmp    800ac8 <strchr+0x33>
  800aae:	38 ca                	cmp    %cl,%dl
  800ab0:	74 16                	je     800ac8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800ab2:	83 c0 01             	add    $0x1,%eax
  800ab5:	0f b6 10             	movzbl (%eax),%edx
  800ab8:	84 d2                	test   %dl,%dl
  800aba:	75 f2                	jne    800aae <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800abc:	b8 00 00 00 00       	mov    $0x0,%eax
  800ac1:	eb 05                	jmp    800ac8 <strchr+0x33>
  800ac3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ac8:	5b                   	pop    %ebx
  800ac9:	5d                   	pop    %ebp
  800aca:	c3                   	ret    

00800acb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800acb:	55                   	push   %ebp
  800acc:	89 e5                	mov    %esp,%ebp
  800ace:	53                   	push   %ebx
  800acf:	8b 45 08             	mov    0x8(%ebp),%eax
  800ad2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800ad5:	0f b6 18             	movzbl (%eax),%ebx
  800ad8:	84 db                	test   %bl,%bl
  800ada:	74 16                	je     800af2 <strfind+0x27>
  800adc:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800ade:	38 d3                	cmp    %dl,%bl
  800ae0:	75 06                	jne    800ae8 <strfind+0x1d>
  800ae2:	eb 0e                	jmp    800af2 <strfind+0x27>
  800ae4:	38 ca                	cmp    %cl,%dl
  800ae6:	74 0a                	je     800af2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800ae8:	83 c0 01             	add    $0x1,%eax
  800aeb:	0f b6 10             	movzbl (%eax),%edx
  800aee:	84 d2                	test   %dl,%dl
  800af0:	75 f2                	jne    800ae4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800af2:	5b                   	pop    %ebx
  800af3:	5d                   	pop    %ebp
  800af4:	c3                   	ret    

00800af5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800af5:	55                   	push   %ebp
  800af6:	89 e5                	mov    %esp,%ebp
  800af8:	83 ec 0c             	sub    $0xc,%esp
  800afb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800afe:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b01:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800b04:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b07:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b0a:	85 c9                	test   %ecx,%ecx
  800b0c:	74 36                	je     800b44 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b0e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b14:	75 28                	jne    800b3e <memset+0x49>
  800b16:	f6 c1 03             	test   $0x3,%cl
  800b19:	75 23                	jne    800b3e <memset+0x49>
		c &= 0xFF;
  800b1b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b1f:	89 d3                	mov    %edx,%ebx
  800b21:	c1 e3 08             	shl    $0x8,%ebx
  800b24:	89 d6                	mov    %edx,%esi
  800b26:	c1 e6 18             	shl    $0x18,%esi
  800b29:	89 d0                	mov    %edx,%eax
  800b2b:	c1 e0 10             	shl    $0x10,%eax
  800b2e:	09 f0                	or     %esi,%eax
  800b30:	09 c2                	or     %eax,%edx
  800b32:	89 d0                	mov    %edx,%eax
  800b34:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800b36:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800b39:	fc                   	cld    
  800b3a:	f3 ab                	rep stos %eax,%es:(%edi)
  800b3c:	eb 06                	jmp    800b44 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b3e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b41:	fc                   	cld    
  800b42:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800b44:	89 f8                	mov    %edi,%eax
  800b46:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b49:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b4c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b4f:	89 ec                	mov    %ebp,%esp
  800b51:	5d                   	pop    %ebp
  800b52:	c3                   	ret    

00800b53 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b53:	55                   	push   %ebp
  800b54:	89 e5                	mov    %esp,%ebp
  800b56:	83 ec 08             	sub    $0x8,%esp
  800b59:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b5c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800b5f:	8b 45 08             	mov    0x8(%ebp),%eax
  800b62:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b65:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b68:	39 c6                	cmp    %eax,%esi
  800b6a:	73 36                	jae    800ba2 <memmove+0x4f>
  800b6c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b6f:	39 d0                	cmp    %edx,%eax
  800b71:	73 2f                	jae    800ba2 <memmove+0x4f>
		s += n;
		d += n;
  800b73:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b76:	f6 c2 03             	test   $0x3,%dl
  800b79:	75 1b                	jne    800b96 <memmove+0x43>
  800b7b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b81:	75 13                	jne    800b96 <memmove+0x43>
  800b83:	f6 c1 03             	test   $0x3,%cl
  800b86:	75 0e                	jne    800b96 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800b88:	83 ef 04             	sub    $0x4,%edi
  800b8b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800b8e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800b91:	fd                   	std    
  800b92:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b94:	eb 09                	jmp    800b9f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800b96:	83 ef 01             	sub    $0x1,%edi
  800b99:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800b9c:	fd                   	std    
  800b9d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800b9f:	fc                   	cld    
  800ba0:	eb 20                	jmp    800bc2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ba2:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800ba8:	75 13                	jne    800bbd <memmove+0x6a>
  800baa:	a8 03                	test   $0x3,%al
  800bac:	75 0f                	jne    800bbd <memmove+0x6a>
  800bae:	f6 c1 03             	test   $0x3,%cl
  800bb1:	75 0a                	jne    800bbd <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800bb3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800bb6:	89 c7                	mov    %eax,%edi
  800bb8:	fc                   	cld    
  800bb9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bbb:	eb 05                	jmp    800bc2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800bbd:	89 c7                	mov    %eax,%edi
  800bbf:	fc                   	cld    
  800bc0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800bc2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800bc5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800bc8:	89 ec                	mov    %ebp,%esp
  800bca:	5d                   	pop    %ebp
  800bcb:	c3                   	ret    

00800bcc <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800bcc:	55                   	push   %ebp
  800bcd:	89 e5                	mov    %esp,%ebp
  800bcf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800bd2:	8b 45 10             	mov    0x10(%ebp),%eax
  800bd5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800bd9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800bdc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800be0:	8b 45 08             	mov    0x8(%ebp),%eax
  800be3:	89 04 24             	mov    %eax,(%esp)
  800be6:	e8 68 ff ff ff       	call   800b53 <memmove>
}
  800beb:	c9                   	leave  
  800bec:	c3                   	ret    

00800bed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800bed:	55                   	push   %ebp
  800bee:	89 e5                	mov    %esp,%ebp
  800bf0:	57                   	push   %edi
  800bf1:	56                   	push   %esi
  800bf2:	53                   	push   %ebx
  800bf3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800bf6:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bf9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800bfc:	8d 78 ff             	lea    -0x1(%eax),%edi
  800bff:	85 c0                	test   %eax,%eax
  800c01:	74 36                	je     800c39 <memcmp+0x4c>
		if (*s1 != *s2)
  800c03:	0f b6 03             	movzbl (%ebx),%eax
  800c06:	0f b6 0e             	movzbl (%esi),%ecx
  800c09:	38 c8                	cmp    %cl,%al
  800c0b:	75 17                	jne    800c24 <memcmp+0x37>
  800c0d:	ba 00 00 00 00       	mov    $0x0,%edx
  800c12:	eb 1a                	jmp    800c2e <memcmp+0x41>
  800c14:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800c19:	83 c2 01             	add    $0x1,%edx
  800c1c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800c20:	38 c8                	cmp    %cl,%al
  800c22:	74 0a                	je     800c2e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800c24:	0f b6 c0             	movzbl %al,%eax
  800c27:	0f b6 c9             	movzbl %cl,%ecx
  800c2a:	29 c8                	sub    %ecx,%eax
  800c2c:	eb 10                	jmp    800c3e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c2e:	39 fa                	cmp    %edi,%edx
  800c30:	75 e2                	jne    800c14 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c32:	b8 00 00 00 00       	mov    $0x0,%eax
  800c37:	eb 05                	jmp    800c3e <memcmp+0x51>
  800c39:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c3e:	5b                   	pop    %ebx
  800c3f:	5e                   	pop    %esi
  800c40:	5f                   	pop    %edi
  800c41:	5d                   	pop    %ebp
  800c42:	c3                   	ret    

00800c43 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c43:	55                   	push   %ebp
  800c44:	89 e5                	mov    %esp,%ebp
  800c46:	53                   	push   %ebx
  800c47:	8b 45 08             	mov    0x8(%ebp),%eax
  800c4a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800c4d:	89 c2                	mov    %eax,%edx
  800c4f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800c52:	39 d0                	cmp    %edx,%eax
  800c54:	73 13                	jae    800c69 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c56:	89 d9                	mov    %ebx,%ecx
  800c58:	38 18                	cmp    %bl,(%eax)
  800c5a:	75 06                	jne    800c62 <memfind+0x1f>
  800c5c:	eb 0b                	jmp    800c69 <memfind+0x26>
  800c5e:	38 08                	cmp    %cl,(%eax)
  800c60:	74 07                	je     800c69 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c62:	83 c0 01             	add    $0x1,%eax
  800c65:	39 d0                	cmp    %edx,%eax
  800c67:	75 f5                	jne    800c5e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c69:	5b                   	pop    %ebx
  800c6a:	5d                   	pop    %ebp
  800c6b:	c3                   	ret    

00800c6c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c6c:	55                   	push   %ebp
  800c6d:	89 e5                	mov    %esp,%ebp
  800c6f:	57                   	push   %edi
  800c70:	56                   	push   %esi
  800c71:	53                   	push   %ebx
  800c72:	83 ec 04             	sub    $0x4,%esp
  800c75:	8b 55 08             	mov    0x8(%ebp),%edx
  800c78:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c7b:	0f b6 02             	movzbl (%edx),%eax
  800c7e:	3c 09                	cmp    $0x9,%al
  800c80:	74 04                	je     800c86 <strtol+0x1a>
  800c82:	3c 20                	cmp    $0x20,%al
  800c84:	75 0e                	jne    800c94 <strtol+0x28>
		s++;
  800c86:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c89:	0f b6 02             	movzbl (%edx),%eax
  800c8c:	3c 09                	cmp    $0x9,%al
  800c8e:	74 f6                	je     800c86 <strtol+0x1a>
  800c90:	3c 20                	cmp    $0x20,%al
  800c92:	74 f2                	je     800c86 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c94:	3c 2b                	cmp    $0x2b,%al
  800c96:	75 0a                	jne    800ca2 <strtol+0x36>
		s++;
  800c98:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800c9b:	bf 00 00 00 00       	mov    $0x0,%edi
  800ca0:	eb 10                	jmp    800cb2 <strtol+0x46>
  800ca2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ca7:	3c 2d                	cmp    $0x2d,%al
  800ca9:	75 07                	jne    800cb2 <strtol+0x46>
		s++, neg = 1;
  800cab:	83 c2 01             	add    $0x1,%edx
  800cae:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800cb2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800cb8:	75 15                	jne    800ccf <strtol+0x63>
  800cba:	80 3a 30             	cmpb   $0x30,(%edx)
  800cbd:	75 10                	jne    800ccf <strtol+0x63>
  800cbf:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800cc3:	75 0a                	jne    800ccf <strtol+0x63>
		s += 2, base = 16;
  800cc5:	83 c2 02             	add    $0x2,%edx
  800cc8:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ccd:	eb 10                	jmp    800cdf <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800ccf:	85 db                	test   %ebx,%ebx
  800cd1:	75 0c                	jne    800cdf <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800cd3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800cd5:	80 3a 30             	cmpb   $0x30,(%edx)
  800cd8:	75 05                	jne    800cdf <strtol+0x73>
		s++, base = 8;
  800cda:	83 c2 01             	add    $0x1,%edx
  800cdd:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800cdf:	b8 00 00 00 00       	mov    $0x0,%eax
  800ce4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800ce7:	0f b6 0a             	movzbl (%edx),%ecx
  800cea:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800ced:	89 f3                	mov    %esi,%ebx
  800cef:	80 fb 09             	cmp    $0x9,%bl
  800cf2:	77 08                	ja     800cfc <strtol+0x90>
			dig = *s - '0';
  800cf4:	0f be c9             	movsbl %cl,%ecx
  800cf7:	83 e9 30             	sub    $0x30,%ecx
  800cfa:	eb 22                	jmp    800d1e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800cfc:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800cff:	89 f3                	mov    %esi,%ebx
  800d01:	80 fb 19             	cmp    $0x19,%bl
  800d04:	77 08                	ja     800d0e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800d06:	0f be c9             	movsbl %cl,%ecx
  800d09:	83 e9 57             	sub    $0x57,%ecx
  800d0c:	eb 10                	jmp    800d1e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800d0e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800d11:	89 f3                	mov    %esi,%ebx
  800d13:	80 fb 19             	cmp    $0x19,%bl
  800d16:	77 16                	ja     800d2e <strtol+0xc2>
			dig = *s - 'A' + 10;
  800d18:	0f be c9             	movsbl %cl,%ecx
  800d1b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800d1e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800d21:	7d 0f                	jge    800d32 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800d23:	83 c2 01             	add    $0x1,%edx
  800d26:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800d2a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800d2c:	eb b9                	jmp    800ce7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800d2e:	89 c1                	mov    %eax,%ecx
  800d30:	eb 02                	jmp    800d34 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800d32:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800d34:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d38:	74 05                	je     800d3f <strtol+0xd3>
		*endptr = (char *) s;
  800d3a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800d3d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800d3f:	89 ca                	mov    %ecx,%edx
  800d41:	f7 da                	neg    %edx
  800d43:	85 ff                	test   %edi,%edi
  800d45:	0f 45 c2             	cmovne %edx,%eax
}
  800d48:	83 c4 04             	add    $0x4,%esp
  800d4b:	5b                   	pop    %ebx
  800d4c:	5e                   	pop    %esi
  800d4d:	5f                   	pop    %edi
  800d4e:	5d                   	pop    %ebp
  800d4f:	c3                   	ret    

00800d50 <__udivdi3>:
  800d50:	83 ec 1c             	sub    $0x1c,%esp
  800d53:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800d57:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d5b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d5f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d63:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800d67:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800d6b:	85 c0                	test   %eax,%eax
  800d6d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d71:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d75:	89 ea                	mov    %ebp,%edx
  800d77:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800d7b:	75 33                	jne    800db0 <__udivdi3+0x60>
  800d7d:	39 e9                	cmp    %ebp,%ecx
  800d7f:	77 6f                	ja     800df0 <__udivdi3+0xa0>
  800d81:	85 c9                	test   %ecx,%ecx
  800d83:	89 ce                	mov    %ecx,%esi
  800d85:	75 0b                	jne    800d92 <__udivdi3+0x42>
  800d87:	b8 01 00 00 00       	mov    $0x1,%eax
  800d8c:	31 d2                	xor    %edx,%edx
  800d8e:	f7 f1                	div    %ecx
  800d90:	89 c6                	mov    %eax,%esi
  800d92:	31 d2                	xor    %edx,%edx
  800d94:	89 e8                	mov    %ebp,%eax
  800d96:	f7 f6                	div    %esi
  800d98:	89 c5                	mov    %eax,%ebp
  800d9a:	89 f8                	mov    %edi,%eax
  800d9c:	f7 f6                	div    %esi
  800d9e:	89 ea                	mov    %ebp,%edx
  800da0:	8b 74 24 10          	mov    0x10(%esp),%esi
  800da4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800da8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dac:	83 c4 1c             	add    $0x1c,%esp
  800daf:	c3                   	ret    
  800db0:	39 e8                	cmp    %ebp,%eax
  800db2:	77 24                	ja     800dd8 <__udivdi3+0x88>
  800db4:	0f bd c8             	bsr    %eax,%ecx
  800db7:	83 f1 1f             	xor    $0x1f,%ecx
  800dba:	89 0c 24             	mov    %ecx,(%esp)
  800dbd:	75 49                	jne    800e08 <__udivdi3+0xb8>
  800dbf:	8b 74 24 08          	mov    0x8(%esp),%esi
  800dc3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800dc7:	0f 86 ab 00 00 00    	jbe    800e78 <__udivdi3+0x128>
  800dcd:	39 e8                	cmp    %ebp,%eax
  800dcf:	0f 82 a3 00 00 00    	jb     800e78 <__udivdi3+0x128>
  800dd5:	8d 76 00             	lea    0x0(%esi),%esi
  800dd8:	31 d2                	xor    %edx,%edx
  800dda:	31 c0                	xor    %eax,%eax
  800ddc:	8b 74 24 10          	mov    0x10(%esp),%esi
  800de0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800de4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800de8:	83 c4 1c             	add    $0x1c,%esp
  800deb:	c3                   	ret    
  800dec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800df0:	89 f8                	mov    %edi,%eax
  800df2:	f7 f1                	div    %ecx
  800df4:	31 d2                	xor    %edx,%edx
  800df6:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dfa:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dfe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e02:	83 c4 1c             	add    $0x1c,%esp
  800e05:	c3                   	ret    
  800e06:	66 90                	xchg   %ax,%ax
  800e08:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e0c:	89 c6                	mov    %eax,%esi
  800e0e:	b8 20 00 00 00       	mov    $0x20,%eax
  800e13:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800e17:	2b 04 24             	sub    (%esp),%eax
  800e1a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800e1e:	d3 e6                	shl    %cl,%esi
  800e20:	89 c1                	mov    %eax,%ecx
  800e22:	d3 ed                	shr    %cl,%ebp
  800e24:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e28:	09 f5                	or     %esi,%ebp
  800e2a:	8b 74 24 04          	mov    0x4(%esp),%esi
  800e2e:	d3 e6                	shl    %cl,%esi
  800e30:	89 c1                	mov    %eax,%ecx
  800e32:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e36:	89 d6                	mov    %edx,%esi
  800e38:	d3 ee                	shr    %cl,%esi
  800e3a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e3e:	d3 e2                	shl    %cl,%edx
  800e40:	89 c1                	mov    %eax,%ecx
  800e42:	d3 ef                	shr    %cl,%edi
  800e44:	09 d7                	or     %edx,%edi
  800e46:	89 f2                	mov    %esi,%edx
  800e48:	89 f8                	mov    %edi,%eax
  800e4a:	f7 f5                	div    %ebp
  800e4c:	89 d6                	mov    %edx,%esi
  800e4e:	89 c7                	mov    %eax,%edi
  800e50:	f7 64 24 04          	mull   0x4(%esp)
  800e54:	39 d6                	cmp    %edx,%esi
  800e56:	72 30                	jb     800e88 <__udivdi3+0x138>
  800e58:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800e5c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e60:	d3 e5                	shl    %cl,%ebp
  800e62:	39 c5                	cmp    %eax,%ebp
  800e64:	73 04                	jae    800e6a <__udivdi3+0x11a>
  800e66:	39 d6                	cmp    %edx,%esi
  800e68:	74 1e                	je     800e88 <__udivdi3+0x138>
  800e6a:	89 f8                	mov    %edi,%eax
  800e6c:	31 d2                	xor    %edx,%edx
  800e6e:	e9 69 ff ff ff       	jmp    800ddc <__udivdi3+0x8c>
  800e73:	90                   	nop
  800e74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e78:	31 d2                	xor    %edx,%edx
  800e7a:	b8 01 00 00 00       	mov    $0x1,%eax
  800e7f:	e9 58 ff ff ff       	jmp    800ddc <__udivdi3+0x8c>
  800e84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e88:	8d 47 ff             	lea    -0x1(%edi),%eax
  800e8b:	31 d2                	xor    %edx,%edx
  800e8d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e91:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e95:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e99:	83 c4 1c             	add    $0x1c,%esp
  800e9c:	c3                   	ret    
  800e9d:	66 90                	xchg   %ax,%ax
  800e9f:	90                   	nop

00800ea0 <__umoddi3>:
  800ea0:	83 ec 2c             	sub    $0x2c,%esp
  800ea3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800ea7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800eab:	89 74 24 20          	mov    %esi,0x20(%esp)
  800eaf:	8b 74 24 38          	mov    0x38(%esp),%esi
  800eb3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800eb7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800ebb:	85 c0                	test   %eax,%eax
  800ebd:	89 c2                	mov    %eax,%edx
  800ebf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800ec3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800ec7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ecb:	89 74 24 10          	mov    %esi,0x10(%esp)
  800ecf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800ed3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ed7:	75 1f                	jne    800ef8 <__umoddi3+0x58>
  800ed9:	39 fe                	cmp    %edi,%esi
  800edb:	76 63                	jbe    800f40 <__umoddi3+0xa0>
  800edd:	89 c8                	mov    %ecx,%eax
  800edf:	89 fa                	mov    %edi,%edx
  800ee1:	f7 f6                	div    %esi
  800ee3:	89 d0                	mov    %edx,%eax
  800ee5:	31 d2                	xor    %edx,%edx
  800ee7:	8b 74 24 20          	mov    0x20(%esp),%esi
  800eeb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800eef:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800ef3:	83 c4 2c             	add    $0x2c,%esp
  800ef6:	c3                   	ret    
  800ef7:	90                   	nop
  800ef8:	39 f8                	cmp    %edi,%eax
  800efa:	77 64                	ja     800f60 <__umoddi3+0xc0>
  800efc:	0f bd e8             	bsr    %eax,%ebp
  800eff:	83 f5 1f             	xor    $0x1f,%ebp
  800f02:	75 74                	jne    800f78 <__umoddi3+0xd8>
  800f04:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800f08:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800f0c:	0f 87 0e 01 00 00    	ja     801020 <__umoddi3+0x180>
  800f12:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800f16:	29 f1                	sub    %esi,%ecx
  800f18:	19 c7                	sbb    %eax,%edi
  800f1a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800f1e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800f22:	8b 44 24 14          	mov    0x14(%esp),%eax
  800f26:	8b 54 24 18          	mov    0x18(%esp),%edx
  800f2a:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f2e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f32:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f36:	83 c4 2c             	add    $0x2c,%esp
  800f39:	c3                   	ret    
  800f3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f40:	85 f6                	test   %esi,%esi
  800f42:	89 f5                	mov    %esi,%ebp
  800f44:	75 0b                	jne    800f51 <__umoddi3+0xb1>
  800f46:	b8 01 00 00 00       	mov    $0x1,%eax
  800f4b:	31 d2                	xor    %edx,%edx
  800f4d:	f7 f6                	div    %esi
  800f4f:	89 c5                	mov    %eax,%ebp
  800f51:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f55:	31 d2                	xor    %edx,%edx
  800f57:	f7 f5                	div    %ebp
  800f59:	89 c8                	mov    %ecx,%eax
  800f5b:	f7 f5                	div    %ebp
  800f5d:	eb 84                	jmp    800ee3 <__umoddi3+0x43>
  800f5f:	90                   	nop
  800f60:	89 c8                	mov    %ecx,%eax
  800f62:	89 fa                	mov    %edi,%edx
  800f64:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f68:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f6c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f70:	83 c4 2c             	add    $0x2c,%esp
  800f73:	c3                   	ret    
  800f74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f78:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f7c:	be 20 00 00 00       	mov    $0x20,%esi
  800f81:	89 e9                	mov    %ebp,%ecx
  800f83:	29 ee                	sub    %ebp,%esi
  800f85:	d3 e2                	shl    %cl,%edx
  800f87:	89 f1                	mov    %esi,%ecx
  800f89:	d3 e8                	shr    %cl,%eax
  800f8b:	89 e9                	mov    %ebp,%ecx
  800f8d:	09 d0                	or     %edx,%eax
  800f8f:	89 fa                	mov    %edi,%edx
  800f91:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800f95:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f99:	d3 e0                	shl    %cl,%eax
  800f9b:	89 f1                	mov    %esi,%ecx
  800f9d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fa1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800fa5:	d3 ea                	shr    %cl,%edx
  800fa7:	89 e9                	mov    %ebp,%ecx
  800fa9:	d3 e7                	shl    %cl,%edi
  800fab:	89 f1                	mov    %esi,%ecx
  800fad:	d3 e8                	shr    %cl,%eax
  800faf:	89 e9                	mov    %ebp,%ecx
  800fb1:	09 f8                	or     %edi,%eax
  800fb3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800fb7:	f7 74 24 0c          	divl   0xc(%esp)
  800fbb:	d3 e7                	shl    %cl,%edi
  800fbd:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800fc1:	89 d7                	mov    %edx,%edi
  800fc3:	f7 64 24 10          	mull   0x10(%esp)
  800fc7:	39 d7                	cmp    %edx,%edi
  800fc9:	89 c1                	mov    %eax,%ecx
  800fcb:	89 54 24 14          	mov    %edx,0x14(%esp)
  800fcf:	72 3b                	jb     80100c <__umoddi3+0x16c>
  800fd1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800fd5:	72 31                	jb     801008 <__umoddi3+0x168>
  800fd7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800fdb:	29 c8                	sub    %ecx,%eax
  800fdd:	19 d7                	sbb    %edx,%edi
  800fdf:	89 e9                	mov    %ebp,%ecx
  800fe1:	89 fa                	mov    %edi,%edx
  800fe3:	d3 e8                	shr    %cl,%eax
  800fe5:	89 f1                	mov    %esi,%ecx
  800fe7:	d3 e2                	shl    %cl,%edx
  800fe9:	89 e9                	mov    %ebp,%ecx
  800feb:	09 d0                	or     %edx,%eax
  800fed:	89 fa                	mov    %edi,%edx
  800fef:	d3 ea                	shr    %cl,%edx
  800ff1:	8b 74 24 20          	mov    0x20(%esp),%esi
  800ff5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800ff9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800ffd:	83 c4 2c             	add    $0x2c,%esp
  801000:	c3                   	ret    
  801001:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801008:	39 d7                	cmp    %edx,%edi
  80100a:	75 cb                	jne    800fd7 <__umoddi3+0x137>
  80100c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801010:	89 c1                	mov    %eax,%ecx
  801012:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801016:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80101a:	eb bb                	jmp    800fd7 <__umoddi3+0x137>
  80101c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801020:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801024:	0f 82 e8 fe ff ff    	jb     800f12 <__umoddi3+0x72>
  80102a:	e9 f3 fe ff ff       	jmp    800f22 <__umoddi3+0x82>

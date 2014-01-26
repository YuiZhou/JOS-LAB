
obj/user/dumbfork：     文件格式 elf32-i386


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
  80002c:	e8 2f 02 00 00       	call   800260 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	66 90                	xchg   %ax,%ax
  800035:	66 90                	xchg   %ax,%ax
  800037:	66 90                	xchg   %ax,%ax
  800039:	66 90                	xchg   %ax,%ax
  80003b:	66 90                	xchg   %ax,%ax
  80003d:	66 90                	xchg   %ax,%ax
  80003f:	90                   	nop

00800040 <duppage>:
	}
}

void
duppage(envid_t dstenv, void *addr)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	56                   	push   %esi
  800044:	53                   	push   %ebx
  800045:	83 ec 20             	sub    $0x20,%esp
  800048:	8b 75 08             	mov    0x8(%ebp),%esi
  80004b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int r;

	// This is NOT what you should do in your fork.
	if ((r = sys_page_alloc(dstenv, addr, PTE_P|PTE_U|PTE_W)) < 0)
  80004e:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800055:	00 
  800056:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80005a:	89 34 24             	mov    %esi,(%esp)
  80005d:	e8 3a 0f 00 00       	call   800f9c <sys_page_alloc>
  800062:	85 c0                	test   %eax,%eax
  800064:	79 20                	jns    800086 <duppage+0x46>
		panic("sys_page_alloc: %e", r);
  800066:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80006a:	c7 44 24 08 00 15 80 	movl   $0x801500,0x8(%esp)
  800071:	00 
  800072:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  800079:	00 
  80007a:	c7 04 24 13 15 80 00 	movl   $0x801513,(%esp)
  800081:	e8 62 02 00 00       	call   8002e8 <_panic>
	if ((r = sys_page_map(dstenv, addr, 0, UTEMP, PTE_P|PTE_U|PTE_W)) < 0)
  800086:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  80008d:	00 
  80008e:	c7 44 24 0c 00 00 40 	movl   $0x400000,0xc(%esp)
  800095:	00 
  800096:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80009d:	00 
  80009e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8000a2:	89 34 24             	mov    %esi,(%esp)
  8000a5:	e8 51 0f 00 00       	call   800ffb <sys_page_map>
  8000aa:	85 c0                	test   %eax,%eax
  8000ac:	79 20                	jns    8000ce <duppage+0x8e>
		panic("sys_page_map: %e", r);
  8000ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000b2:	c7 44 24 08 23 15 80 	movl   $0x801523,0x8(%esp)
  8000b9:	00 
  8000ba:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
  8000c1:	00 
  8000c2:	c7 04 24 13 15 80 00 	movl   $0x801513,(%esp)
  8000c9:	e8 1a 02 00 00       	call   8002e8 <_panic>
	memmove(UTEMP, addr, PGSIZE);
  8000ce:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  8000d5:	00 
  8000d6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8000da:	c7 04 24 00 00 40 00 	movl   $0x400000,(%esp)
  8000e1:	e8 9d 0b 00 00       	call   800c83 <memmove>
	if ((r = sys_page_unmap(0, UTEMP)) < 0)
  8000e6:	c7 44 24 04 00 00 40 	movl   $0x400000,0x4(%esp)
  8000ed:	00 
  8000ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000f5:	e8 5f 0f 00 00       	call   801059 <sys_page_unmap>
  8000fa:	85 c0                	test   %eax,%eax
  8000fc:	79 20                	jns    80011e <duppage+0xde>
		panic("sys_page_unmap: %e", r);
  8000fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800102:	c7 44 24 08 34 15 80 	movl   $0x801534,0x8(%esp)
  800109:	00 
  80010a:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  800111:	00 
  800112:	c7 04 24 13 15 80 00 	movl   $0x801513,(%esp)
  800119:	e8 ca 01 00 00       	call   8002e8 <_panic>
}
  80011e:	83 c4 20             	add    $0x20,%esp
  800121:	5b                   	pop    %ebx
  800122:	5e                   	pop    %esi
  800123:	5d                   	pop    %ebp
  800124:	c3                   	ret    

00800125 <dumbfork>:

envid_t
dumbfork(void)
{
  800125:	55                   	push   %ebp
  800126:	89 e5                	mov    %esp,%ebp
  800128:	56                   	push   %esi
  800129:	53                   	push   %ebx
  80012a:	83 ec 20             	sub    $0x20,%esp
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  80012d:	be 07 00 00 00       	mov    $0x7,%esi
  800132:	89 f0                	mov    %esi,%eax
  800134:	cd 30                	int    $0x30
  800136:	89 c6                	mov    %eax,%esi
	// The kernel will initialize it with a copy of our register state,
	// so that the child will appear to have called sys_exofork() too -
	// except that in the child, this "fake" call to sys_exofork()
	// will return 0 instead of the envid of the child.
	envid = sys_exofork();
	if (envid < 0)
  800138:	85 c0                	test   %eax,%eax
  80013a:	79 20                	jns    80015c <dumbfork+0x37>
		panic("sys_exofork: %e", envid);
  80013c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800140:	c7 44 24 08 47 15 80 	movl   $0x801547,0x8(%esp)
  800147:	00 
  800148:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
  80014f:	00 
  800150:	c7 04 24 13 15 80 00 	movl   $0x801513,(%esp)
  800157:	e8 8c 01 00 00       	call   8002e8 <_panic>
	if (envid == 0) {
  80015c:	85 c0                	test   %eax,%eax
  80015e:	75 1c                	jne    80017c <dumbfork+0x57>
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
  800160:	e8 d7 0d 00 00       	call   800f3c <sys_getenvid>
  800165:	25 ff 03 00 00       	and    $0x3ff,%eax
  80016a:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80016d:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800172:	a3 04 20 80 00       	mov    %eax,0x802004
  800177:	e9 82 00 00 00       	jmp    8001fe <dumbfork+0xd9>
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.
	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
  80017c:	c7 45 f4 00 00 80 00 	movl   $0x800000,-0xc(%ebp)
  800183:	b8 0c 20 80 00       	mov    $0x80200c,%eax
  800188:	3d 00 00 80 00       	cmp    $0x800000,%eax
  80018d:	76 27                	jbe    8001b6 <dumbfork+0x91>
  80018f:	89 f3                	mov    %esi,%ebx
  800191:	ba 00 00 80 00       	mov    $0x800000,%edx
		duppage(envid, addr);
  800196:	89 54 24 04          	mov    %edx,0x4(%esp)
  80019a:	89 1c 24             	mov    %ebx,(%esp)
  80019d:	e8 9e fe ff ff       	call   800040 <duppage>
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.
	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
  8001a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
  8001a5:	81 c2 00 10 00 00    	add    $0x1000,%edx
  8001ab:	89 55 f4             	mov    %edx,-0xc(%ebp)
  8001ae:	81 fa 0c 20 80 00    	cmp    $0x80200c,%edx
  8001b4:	72 e0                	jb     800196 <dumbfork+0x71>
		duppage(envid, addr);

	// Also copy the stack we are currently running on.
	duppage(envid, ROUNDDOWN(&addr, PGSIZE));
  8001b6:	8d 45 f4             	lea    -0xc(%ebp),%eax
  8001b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  8001be:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001c2:	89 34 24             	mov    %esi,(%esp)
  8001c5:	e8 76 fe ff ff       	call   800040 <duppage>

	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
  8001ca:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  8001d1:	00 
  8001d2:	89 34 24             	mov    %esi,(%esp)
  8001d5:	e8 dd 0e 00 00       	call   8010b7 <sys_env_set_status>
  8001da:	85 c0                	test   %eax,%eax
  8001dc:	79 20                	jns    8001fe <dumbfork+0xd9>
		panic("sys_env_set_status: %e", r);
  8001de:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001e2:	c7 44 24 08 57 15 80 	movl   $0x801557,0x8(%esp)
  8001e9:	00 
  8001ea:	c7 44 24 04 4c 00 00 	movl   $0x4c,0x4(%esp)
  8001f1:	00 
  8001f2:	c7 04 24 13 15 80 00 	movl   $0x801513,(%esp)
  8001f9:	e8 ea 00 00 00       	call   8002e8 <_panic>

	return envid;
}
  8001fe:	89 f0                	mov    %esi,%eax
  800200:	83 c4 20             	add    $0x20,%esp
  800203:	5b                   	pop    %ebx
  800204:	5e                   	pop    %esi
  800205:	5d                   	pop    %ebp
  800206:	c3                   	ret    

00800207 <umain>:

envid_t dumbfork(void);

void
umain(int argc, char **argv)
{
  800207:	55                   	push   %ebp
  800208:	89 e5                	mov    %esp,%ebp
  80020a:	56                   	push   %esi
  80020b:	53                   	push   %ebx
  80020c:	83 ec 10             	sub    $0x10,%esp
	envid_t who;
	int i;

	// fork a child process
	who = dumbfork();
  80020f:	e8 11 ff ff ff       	call   800125 <dumbfork>
  800214:	89 c6                	mov    %eax,%esi

	// print a message and yield to the other a few times
	for (i = 0; i < (who ? 10 : 20); i++) {
  800216:	bb 00 00 00 00       	mov    $0x0,%ebx
  80021b:	eb 28                	jmp    800245 <umain+0x3e>
		cprintf("%d: I am the %s!\n", i, who ? "parent" : "child");
  80021d:	b8 75 15 80 00       	mov    $0x801575,%eax
  800222:	eb 05                	jmp    800229 <umain+0x22>
  800224:	b8 6e 15 80 00       	mov    $0x80156e,%eax
  800229:	89 44 24 08          	mov    %eax,0x8(%esp)
  80022d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800231:	c7 04 24 7b 15 80 00 	movl   $0x80157b,(%esp)
  800238:	e8 be 01 00 00       	call   8003fb <cprintf>
		sys_yield();
  80023d:	e8 2a 0d 00 00       	call   800f6c <sys_yield>

	// fork a child process
	who = dumbfork();

	// print a message and yield to the other a few times
	for (i = 0; i < (who ? 10 : 20); i++) {
  800242:	83 c3 01             	add    $0x1,%ebx
  800245:	85 f6                	test   %esi,%esi
  800247:	75 09                	jne    800252 <umain+0x4b>
  800249:	83 fb 13             	cmp    $0x13,%ebx
  80024c:	7e cf                	jle    80021d <umain+0x16>
  80024e:	66 90                	xchg   %ax,%ax
  800250:	eb 05                	jmp    800257 <umain+0x50>
  800252:	83 fb 09             	cmp    $0x9,%ebx
  800255:	7e cd                	jle    800224 <umain+0x1d>
		cprintf("%d: I am the %s!\n", i, who ? "parent" : "child");
		sys_yield();
	}
}
  800257:	83 c4 10             	add    $0x10,%esp
  80025a:	5b                   	pop    %ebx
  80025b:	5e                   	pop    %esi
  80025c:	5d                   	pop    %ebp
  80025d:	c3                   	ret    
  80025e:	66 90                	xchg   %ax,%ax

00800260 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800260:	55                   	push   %ebp
  800261:	89 e5                	mov    %esp,%ebp
  800263:	57                   	push   %edi
  800264:	56                   	push   %esi
  800265:	53                   	push   %ebx
  800266:	83 ec 1c             	sub    $0x1c,%esp
  800269:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80026c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  80026f:	e8 c8 0c 00 00       	call   800f3c <sys_getenvid>
	thisenv = envs;
  800274:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  80027b:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  80027e:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  800284:	39 c2                	cmp    %eax,%edx
  800286:	74 25                	je     8002ad <libmain+0x4d>
  800288:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  80028d:	eb 12                	jmp    8002a1 <libmain+0x41>
  80028f:	8b 4a 48             	mov    0x48(%edx),%ecx
  800292:	83 c2 7c             	add    $0x7c,%edx
  800295:	39 c1                	cmp    %eax,%ecx
  800297:	75 08                	jne    8002a1 <libmain+0x41>
  800299:	89 3d 04 20 80 00    	mov    %edi,0x802004
  80029f:	eb 0c                	jmp    8002ad <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  8002a1:	89 d7                	mov    %edx,%edi
  8002a3:	85 d2                	test   %edx,%edx
  8002a5:	75 e8                	jne    80028f <libmain+0x2f>
  8002a7:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8002ad:	85 db                	test   %ebx,%ebx
  8002af:	7e 07                	jle    8002b8 <libmain+0x58>
		binaryname = argv[0];
  8002b1:	8b 06                	mov    (%esi),%eax
  8002b3:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8002b8:	89 74 24 04          	mov    %esi,0x4(%esp)
  8002bc:	89 1c 24             	mov    %ebx,(%esp)
  8002bf:	e8 43 ff ff ff       	call   800207 <umain>

	// exit gracefully
	exit();
  8002c4:	e8 0b 00 00 00       	call   8002d4 <exit>
}
  8002c9:	83 c4 1c             	add    $0x1c,%esp
  8002cc:	5b                   	pop    %ebx
  8002cd:	5e                   	pop    %esi
  8002ce:	5f                   	pop    %edi
  8002cf:	5d                   	pop    %ebp
  8002d0:	c3                   	ret    
  8002d1:	66 90                	xchg   %ax,%ax
  8002d3:	90                   	nop

008002d4 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8002d4:	55                   	push   %ebp
  8002d5:	89 e5                	mov    %esp,%ebp
  8002d7:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8002da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8002e1:	e8 f9 0b 00 00       	call   800edf <sys_env_destroy>
}
  8002e6:	c9                   	leave  
  8002e7:	c3                   	ret    

008002e8 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8002e8:	55                   	push   %ebp
  8002e9:	89 e5                	mov    %esp,%ebp
  8002eb:	56                   	push   %esi
  8002ec:	53                   	push   %ebx
  8002ed:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8002f0:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  8002f3:	a1 08 20 80 00       	mov    0x802008,%eax
  8002f8:	85 c0                	test   %eax,%eax
  8002fa:	74 10                	je     80030c <_panic+0x24>
		cprintf("%s: ", argv0);
  8002fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800300:	c7 04 24 97 15 80 00 	movl   $0x801597,(%esp)
  800307:	e8 ef 00 00 00       	call   8003fb <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80030c:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800312:	e8 25 0c 00 00       	call   800f3c <sys_getenvid>
  800317:	8b 55 0c             	mov    0xc(%ebp),%edx
  80031a:	89 54 24 10          	mov    %edx,0x10(%esp)
  80031e:	8b 55 08             	mov    0x8(%ebp),%edx
  800321:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800325:	89 74 24 08          	mov    %esi,0x8(%esp)
  800329:	89 44 24 04          	mov    %eax,0x4(%esp)
  80032d:	c7 04 24 9c 15 80 00 	movl   $0x80159c,(%esp)
  800334:	e8 c2 00 00 00       	call   8003fb <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800339:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80033d:	8b 45 10             	mov    0x10(%ebp),%eax
  800340:	89 04 24             	mov    %eax,(%esp)
  800343:	e8 52 00 00 00       	call   80039a <vcprintf>
	cprintf("\n");
  800348:	c7 04 24 8b 15 80 00 	movl   $0x80158b,(%esp)
  80034f:	e8 a7 00 00 00       	call   8003fb <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800354:	cc                   	int3   
  800355:	eb fd                	jmp    800354 <_panic+0x6c>
  800357:	90                   	nop

00800358 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800358:	55                   	push   %ebp
  800359:	89 e5                	mov    %esp,%ebp
  80035b:	53                   	push   %ebx
  80035c:	83 ec 14             	sub    $0x14,%esp
  80035f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800362:	8b 03                	mov    (%ebx),%eax
  800364:	8b 55 08             	mov    0x8(%ebp),%edx
  800367:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  80036b:	83 c0 01             	add    $0x1,%eax
  80036e:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800370:	3d ff 00 00 00       	cmp    $0xff,%eax
  800375:	75 19                	jne    800390 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800377:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80037e:	00 
  80037f:	8d 43 08             	lea    0x8(%ebx),%eax
  800382:	89 04 24             	mov    %eax,(%esp)
  800385:	e8 f6 0a 00 00       	call   800e80 <sys_cputs>
		b->idx = 0;
  80038a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800390:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800394:	83 c4 14             	add    $0x14,%esp
  800397:	5b                   	pop    %ebx
  800398:	5d                   	pop    %ebp
  800399:	c3                   	ret    

0080039a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80039a:	55                   	push   %ebp
  80039b:	89 e5                	mov    %esp,%ebp
  80039d:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8003a3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8003aa:	00 00 00 
	b.cnt = 0;
  8003ad:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8003b4:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8003b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003be:	8b 45 08             	mov    0x8(%ebp),%eax
  8003c1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003c5:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8003cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003cf:	c7 04 24 58 03 80 00 	movl   $0x800358,(%esp)
  8003d6:	e8 b7 01 00 00       	call   800592 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8003db:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8003e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003e5:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8003eb:	89 04 24             	mov    %eax,(%esp)
  8003ee:	e8 8d 0a 00 00       	call   800e80 <sys_cputs>

	return b.cnt;
}
  8003f3:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8003f9:	c9                   	leave  
  8003fa:	c3                   	ret    

008003fb <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8003fb:	55                   	push   %ebp
  8003fc:	89 e5                	mov    %esp,%ebp
  8003fe:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800401:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800404:	89 44 24 04          	mov    %eax,0x4(%esp)
  800408:	8b 45 08             	mov    0x8(%ebp),%eax
  80040b:	89 04 24             	mov    %eax,(%esp)
  80040e:	e8 87 ff ff ff       	call   80039a <vcprintf>
	va_end(ap);

	return cnt;
}
  800413:	c9                   	leave  
  800414:	c3                   	ret    
  800415:	66 90                	xchg   %ax,%ax
  800417:	66 90                	xchg   %ax,%ax
  800419:	66 90                	xchg   %ax,%ax
  80041b:	66 90                	xchg   %ax,%ax
  80041d:	66 90                	xchg   %ax,%ax
  80041f:	90                   	nop

00800420 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800420:	55                   	push   %ebp
  800421:	89 e5                	mov    %esp,%ebp
  800423:	57                   	push   %edi
  800424:	56                   	push   %esi
  800425:	53                   	push   %ebx
  800426:	83 ec 4c             	sub    $0x4c,%esp
  800429:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80042c:	89 d7                	mov    %edx,%edi
  80042e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800431:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800434:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800437:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80043a:	b8 00 00 00 00       	mov    $0x0,%eax
  80043f:	39 d8                	cmp    %ebx,%eax
  800441:	72 17                	jb     80045a <printnum+0x3a>
  800443:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800446:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800449:	76 0f                	jbe    80045a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80044b:	8b 75 14             	mov    0x14(%ebp),%esi
  80044e:	83 ee 01             	sub    $0x1,%esi
  800451:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800454:	85 f6                	test   %esi,%esi
  800456:	7f 63                	jg     8004bb <printnum+0x9b>
  800458:	eb 75                	jmp    8004cf <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80045a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80045d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800461:	8b 45 14             	mov    0x14(%ebp),%eax
  800464:	83 e8 01             	sub    $0x1,%eax
  800467:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80046b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80046e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800472:	8b 44 24 08          	mov    0x8(%esp),%eax
  800476:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80047a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80047d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800480:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800487:	00 
  800488:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80048b:	89 1c 24             	mov    %ebx,(%esp)
  80048e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800491:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800495:	e8 76 0d 00 00       	call   801210 <__udivdi3>
  80049a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80049d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8004a0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8004a4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8004a8:	89 04 24             	mov    %eax,(%esp)
  8004ab:	89 54 24 04          	mov    %edx,0x4(%esp)
  8004af:	89 fa                	mov    %edi,%edx
  8004b1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8004b4:	e8 67 ff ff ff       	call   800420 <printnum>
  8004b9:	eb 14                	jmp    8004cf <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8004bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004bf:	8b 45 18             	mov    0x18(%ebp),%eax
  8004c2:	89 04 24             	mov    %eax,(%esp)
  8004c5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8004c7:	83 ee 01             	sub    $0x1,%esi
  8004ca:	75 ef                	jne    8004bb <printnum+0x9b>
  8004cc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8004cf:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004d3:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8004d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8004da:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8004de:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8004e5:	00 
  8004e6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8004e9:	89 1c 24             	mov    %ebx,(%esp)
  8004ec:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8004ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004f3:	e8 68 0e 00 00       	call   801360 <__umoddi3>
  8004f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004fc:	0f be 80 c0 15 80 00 	movsbl 0x8015c0(%eax),%eax
  800503:	89 04 24             	mov    %eax,(%esp)
  800506:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800509:	ff d0                	call   *%eax
}
  80050b:	83 c4 4c             	add    $0x4c,%esp
  80050e:	5b                   	pop    %ebx
  80050f:	5e                   	pop    %esi
  800510:	5f                   	pop    %edi
  800511:	5d                   	pop    %ebp
  800512:	c3                   	ret    

00800513 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800513:	55                   	push   %ebp
  800514:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800516:	83 fa 01             	cmp    $0x1,%edx
  800519:	7e 0e                	jle    800529 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80051b:	8b 10                	mov    (%eax),%edx
  80051d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800520:	89 08                	mov    %ecx,(%eax)
  800522:	8b 02                	mov    (%edx),%eax
  800524:	8b 52 04             	mov    0x4(%edx),%edx
  800527:	eb 22                	jmp    80054b <getuint+0x38>
	else if (lflag)
  800529:	85 d2                	test   %edx,%edx
  80052b:	74 10                	je     80053d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80052d:	8b 10                	mov    (%eax),%edx
  80052f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800532:	89 08                	mov    %ecx,(%eax)
  800534:	8b 02                	mov    (%edx),%eax
  800536:	ba 00 00 00 00       	mov    $0x0,%edx
  80053b:	eb 0e                	jmp    80054b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80053d:	8b 10                	mov    (%eax),%edx
  80053f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800542:	89 08                	mov    %ecx,(%eax)
  800544:	8b 02                	mov    (%edx),%eax
  800546:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80054b:	5d                   	pop    %ebp
  80054c:	c3                   	ret    

0080054d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80054d:	55                   	push   %ebp
  80054e:	89 e5                	mov    %esp,%ebp
  800550:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800553:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800557:	8b 10                	mov    (%eax),%edx
  800559:	3b 50 04             	cmp    0x4(%eax),%edx
  80055c:	73 0a                	jae    800568 <sprintputch+0x1b>
		*b->buf++ = ch;
  80055e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800561:	88 0a                	mov    %cl,(%edx)
  800563:	83 c2 01             	add    $0x1,%edx
  800566:	89 10                	mov    %edx,(%eax)
}
  800568:	5d                   	pop    %ebp
  800569:	c3                   	ret    

0080056a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80056a:	55                   	push   %ebp
  80056b:	89 e5                	mov    %esp,%ebp
  80056d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800570:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800573:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800577:	8b 45 10             	mov    0x10(%ebp),%eax
  80057a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80057e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800581:	89 44 24 04          	mov    %eax,0x4(%esp)
  800585:	8b 45 08             	mov    0x8(%ebp),%eax
  800588:	89 04 24             	mov    %eax,(%esp)
  80058b:	e8 02 00 00 00       	call   800592 <vprintfmt>
	va_end(ap);
}
  800590:	c9                   	leave  
  800591:	c3                   	ret    

00800592 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800592:	55                   	push   %ebp
  800593:	89 e5                	mov    %esp,%ebp
  800595:	57                   	push   %edi
  800596:	56                   	push   %esi
  800597:	53                   	push   %ebx
  800598:	83 ec 4c             	sub    $0x4c,%esp
  80059b:	8b 75 08             	mov    0x8(%ebp),%esi
  80059e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005a1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8005a4:	eb 11                	jmp    8005b7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8005a6:	85 c0                	test   %eax,%eax
  8005a8:	0f 84 db 03 00 00    	je     800989 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  8005ae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005b2:	89 04 24             	mov    %eax,(%esp)
  8005b5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8005b7:	0f b6 07             	movzbl (%edi),%eax
  8005ba:	83 c7 01             	add    $0x1,%edi
  8005bd:	83 f8 25             	cmp    $0x25,%eax
  8005c0:	75 e4                	jne    8005a6 <vprintfmt+0x14>
  8005c2:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  8005c6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  8005cd:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8005d4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  8005db:	ba 00 00 00 00       	mov    $0x0,%edx
  8005e0:	eb 2b                	jmp    80060d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e2:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8005e5:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  8005e9:	eb 22                	jmp    80060d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005eb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8005ee:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  8005f2:	eb 19                	jmp    80060d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  8005f7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8005fe:	eb 0d                	jmp    80060d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800600:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800603:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800606:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80060d:	0f b6 0f             	movzbl (%edi),%ecx
  800610:	8d 47 01             	lea    0x1(%edi),%eax
  800613:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800616:	0f b6 07             	movzbl (%edi),%eax
  800619:	83 e8 23             	sub    $0x23,%eax
  80061c:	3c 55                	cmp    $0x55,%al
  80061e:	0f 87 40 03 00 00    	ja     800964 <vprintfmt+0x3d2>
  800624:	0f b6 c0             	movzbl %al,%eax
  800627:	ff 24 85 80 16 80 00 	jmp    *0x801680(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80062e:	83 e9 30             	sub    $0x30,%ecx
  800631:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800634:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800638:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80063b:	83 f9 09             	cmp    $0x9,%ecx
  80063e:	77 57                	ja     800697 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800640:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800643:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800646:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800649:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80064c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80064f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800653:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800656:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800659:	83 f9 09             	cmp    $0x9,%ecx
  80065c:	76 eb                	jbe    800649 <vprintfmt+0xb7>
  80065e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800661:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800664:	eb 34                	jmp    80069a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800666:	8b 45 14             	mov    0x14(%ebp),%eax
  800669:	8d 48 04             	lea    0x4(%eax),%ecx
  80066c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80066f:	8b 00                	mov    (%eax),%eax
  800671:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800674:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800677:	eb 21                	jmp    80069a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800679:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80067d:	0f 88 71 ff ff ff    	js     8005f4 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800683:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800686:	eb 85                	jmp    80060d <vprintfmt+0x7b>
  800688:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80068b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800692:	e9 76 ff ff ff       	jmp    80060d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800697:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80069a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80069e:	0f 89 69 ff ff ff    	jns    80060d <vprintfmt+0x7b>
  8006a4:	e9 57 ff ff ff       	jmp    800600 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8006a9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8006af:	e9 59 ff ff ff       	jmp    80060d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8006b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b7:	8d 50 04             	lea    0x4(%eax),%edx
  8006ba:	89 55 14             	mov    %edx,0x14(%ebp)
  8006bd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006c1:	8b 00                	mov    (%eax),%eax
  8006c3:	89 04 24             	mov    %eax,(%esp)
  8006c6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006c8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8006cb:	e9 e7 fe ff ff       	jmp    8005b7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8006d0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d3:	8d 50 04             	lea    0x4(%eax),%edx
  8006d6:	89 55 14             	mov    %edx,0x14(%ebp)
  8006d9:	8b 00                	mov    (%eax),%eax
  8006db:	89 c2                	mov    %eax,%edx
  8006dd:	c1 fa 1f             	sar    $0x1f,%edx
  8006e0:	31 d0                	xor    %edx,%eax
  8006e2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8006e4:	83 f8 08             	cmp    $0x8,%eax
  8006e7:	7f 0b                	jg     8006f4 <vprintfmt+0x162>
  8006e9:	8b 14 85 e0 17 80 00 	mov    0x8017e0(,%eax,4),%edx
  8006f0:	85 d2                	test   %edx,%edx
  8006f2:	75 20                	jne    800714 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  8006f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006f8:	c7 44 24 08 d8 15 80 	movl   $0x8015d8,0x8(%esp)
  8006ff:	00 
  800700:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800704:	89 34 24             	mov    %esi,(%esp)
  800707:	e8 5e fe ff ff       	call   80056a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80070c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80070f:	e9 a3 fe ff ff       	jmp    8005b7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800714:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800718:	c7 44 24 08 e1 15 80 	movl   $0x8015e1,0x8(%esp)
  80071f:	00 
  800720:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800724:	89 34 24             	mov    %esi,(%esp)
  800727:	e8 3e fe ff ff       	call   80056a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80072c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80072f:	e9 83 fe ff ff       	jmp    8005b7 <vprintfmt+0x25>
  800734:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800737:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80073a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80073d:	8b 45 14             	mov    0x14(%ebp),%eax
  800740:	8d 50 04             	lea    0x4(%eax),%edx
  800743:	89 55 14             	mov    %edx,0x14(%ebp)
  800746:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800748:	85 ff                	test   %edi,%edi
  80074a:	b8 d1 15 80 00       	mov    $0x8015d1,%eax
  80074f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800752:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800756:	74 06                	je     80075e <vprintfmt+0x1cc>
  800758:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  80075c:	7f 16                	jg     800774 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80075e:	0f b6 17             	movzbl (%edi),%edx
  800761:	0f be c2             	movsbl %dl,%eax
  800764:	83 c7 01             	add    $0x1,%edi
  800767:	85 c0                	test   %eax,%eax
  800769:	0f 85 9f 00 00 00    	jne    80080e <vprintfmt+0x27c>
  80076f:	e9 8b 00 00 00       	jmp    8007ff <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800774:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800778:	89 3c 24             	mov    %edi,(%esp)
  80077b:	e8 c2 02 00 00       	call   800a42 <strnlen>
  800780:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800783:	29 c2                	sub    %eax,%edx
  800785:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800788:	85 d2                	test   %edx,%edx
  80078a:	7e d2                	jle    80075e <vprintfmt+0x1cc>
					putch(padc, putdat);
  80078c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800790:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800793:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800796:	89 d7                	mov    %edx,%edi
  800798:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80079c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80079f:	89 04 24             	mov    %eax,(%esp)
  8007a2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8007a4:	83 ef 01             	sub    $0x1,%edi
  8007a7:	75 ef                	jne    800798 <vprintfmt+0x206>
  8007a9:	89 7d d8             	mov    %edi,-0x28(%ebp)
  8007ac:	8b 7d cc             	mov    -0x34(%ebp),%edi
  8007af:	eb ad                	jmp    80075e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8007b1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8007b5:	74 20                	je     8007d7 <vprintfmt+0x245>
  8007b7:	0f be d2             	movsbl %dl,%edx
  8007ba:	83 ea 20             	sub    $0x20,%edx
  8007bd:	83 fa 5e             	cmp    $0x5e,%edx
  8007c0:	76 15                	jbe    8007d7 <vprintfmt+0x245>
					putch('?', putdat);
  8007c2:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8007c5:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007c9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8007d0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8007d3:	ff d1                	call   *%ecx
  8007d5:	eb 0f                	jmp    8007e6 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  8007d7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8007da:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007de:	89 04 24             	mov    %eax,(%esp)
  8007e1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8007e4:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8007e6:	83 eb 01             	sub    $0x1,%ebx
  8007e9:	0f b6 17             	movzbl (%edi),%edx
  8007ec:	0f be c2             	movsbl %dl,%eax
  8007ef:	83 c7 01             	add    $0x1,%edi
  8007f2:	85 c0                	test   %eax,%eax
  8007f4:	75 24                	jne    80081a <vprintfmt+0x288>
  8007f6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8007f9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8007fc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007ff:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800802:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800806:	0f 8e ab fd ff ff    	jle    8005b7 <vprintfmt+0x25>
  80080c:	eb 20                	jmp    80082e <vprintfmt+0x29c>
  80080e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800811:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800814:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800817:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80081a:	85 f6                	test   %esi,%esi
  80081c:	78 93                	js     8007b1 <vprintfmt+0x21f>
  80081e:	83 ee 01             	sub    $0x1,%esi
  800821:	79 8e                	jns    8007b1 <vprintfmt+0x21f>
  800823:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800826:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800829:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80082c:	eb d1                	jmp    8007ff <vprintfmt+0x26d>
  80082e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800831:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800835:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80083c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80083e:	83 ef 01             	sub    $0x1,%edi
  800841:	75 ee                	jne    800831 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800843:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800846:	e9 6c fd ff ff       	jmp    8005b7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80084b:	83 fa 01             	cmp    $0x1,%edx
  80084e:	66 90                	xchg   %ax,%ax
  800850:	7e 16                	jle    800868 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800852:	8b 45 14             	mov    0x14(%ebp),%eax
  800855:	8d 50 08             	lea    0x8(%eax),%edx
  800858:	89 55 14             	mov    %edx,0x14(%ebp)
  80085b:	8b 10                	mov    (%eax),%edx
  80085d:	8b 48 04             	mov    0x4(%eax),%ecx
  800860:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800863:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800866:	eb 32                	jmp    80089a <vprintfmt+0x308>
	else if (lflag)
  800868:	85 d2                	test   %edx,%edx
  80086a:	74 18                	je     800884 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  80086c:	8b 45 14             	mov    0x14(%ebp),%eax
  80086f:	8d 50 04             	lea    0x4(%eax),%edx
  800872:	89 55 14             	mov    %edx,0x14(%ebp)
  800875:	8b 00                	mov    (%eax),%eax
  800877:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80087a:	89 c1                	mov    %eax,%ecx
  80087c:	c1 f9 1f             	sar    $0x1f,%ecx
  80087f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800882:	eb 16                	jmp    80089a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800884:	8b 45 14             	mov    0x14(%ebp),%eax
  800887:	8d 50 04             	lea    0x4(%eax),%edx
  80088a:	89 55 14             	mov    %edx,0x14(%ebp)
  80088d:	8b 00                	mov    (%eax),%eax
  80088f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800892:	89 c7                	mov    %eax,%edi
  800894:	c1 ff 1f             	sar    $0x1f,%edi
  800897:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80089a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80089d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8008a0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8008a5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  8008a9:	79 7d                	jns    800928 <vprintfmt+0x396>
				putch('-', putdat);
  8008ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8008af:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8008b6:	ff d6                	call   *%esi
				num = -(long long) num;
  8008b8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8008bb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8008be:	f7 d8                	neg    %eax
  8008c0:	83 d2 00             	adc    $0x0,%edx
  8008c3:	f7 da                	neg    %edx
			}
			base = 10;
  8008c5:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8008ca:	eb 5c                	jmp    800928 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8008cc:	8d 45 14             	lea    0x14(%ebp),%eax
  8008cf:	e8 3f fc ff ff       	call   800513 <getuint>
			base = 10;
  8008d4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8008d9:	eb 4d                	jmp    800928 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  8008db:	8d 45 14             	lea    0x14(%ebp),%eax
  8008de:	e8 30 fc ff ff       	call   800513 <getuint>
			base = 8;
  8008e3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8008e8:	eb 3e                	jmp    800928 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  8008ea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8008ee:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8008f5:	ff d6                	call   *%esi
			putch('x', putdat);
  8008f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8008fb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800902:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800904:	8b 45 14             	mov    0x14(%ebp),%eax
  800907:	8d 50 04             	lea    0x4(%eax),%edx
  80090a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80090d:	8b 00                	mov    (%eax),%eax
  80090f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800914:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800919:	eb 0d                	jmp    800928 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80091b:	8d 45 14             	lea    0x14(%ebp),%eax
  80091e:	e8 f0 fb ff ff       	call   800513 <getuint>
			base = 16;
  800923:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800928:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80092c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800930:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800933:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800937:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80093b:	89 04 24             	mov    %eax,(%esp)
  80093e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800942:	89 da                	mov    %ebx,%edx
  800944:	89 f0                	mov    %esi,%eax
  800946:	e8 d5 fa ff ff       	call   800420 <printnum>
			break;
  80094b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80094e:	e9 64 fc ff ff       	jmp    8005b7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800953:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800957:	89 0c 24             	mov    %ecx,(%esp)
  80095a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80095c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80095f:	e9 53 fc ff ff       	jmp    8005b7 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800964:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800968:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  80096f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800971:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800975:	0f 84 3c fc ff ff    	je     8005b7 <vprintfmt+0x25>
  80097b:	83 ef 01             	sub    $0x1,%edi
  80097e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800982:	75 f7                	jne    80097b <vprintfmt+0x3e9>
  800984:	e9 2e fc ff ff       	jmp    8005b7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800989:	83 c4 4c             	add    $0x4c,%esp
  80098c:	5b                   	pop    %ebx
  80098d:	5e                   	pop    %esi
  80098e:	5f                   	pop    %edi
  80098f:	5d                   	pop    %ebp
  800990:	c3                   	ret    

00800991 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800991:	55                   	push   %ebp
  800992:	89 e5                	mov    %esp,%ebp
  800994:	83 ec 28             	sub    $0x28,%esp
  800997:	8b 45 08             	mov    0x8(%ebp),%eax
  80099a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80099d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8009a0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8009a4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8009a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8009ae:	85 d2                	test   %edx,%edx
  8009b0:	7e 30                	jle    8009e2 <vsnprintf+0x51>
  8009b2:	85 c0                	test   %eax,%eax
  8009b4:	74 2c                	je     8009e2 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8009b6:	8b 45 14             	mov    0x14(%ebp),%eax
  8009b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8009bd:	8b 45 10             	mov    0x10(%ebp),%eax
  8009c0:	89 44 24 08          	mov    %eax,0x8(%esp)
  8009c4:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8009c7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8009cb:	c7 04 24 4d 05 80 00 	movl   $0x80054d,(%esp)
  8009d2:	e8 bb fb ff ff       	call   800592 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8009d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8009da:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8009dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8009e0:	eb 05                	jmp    8009e7 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8009e2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8009e7:	c9                   	leave  
  8009e8:	c3                   	ret    

008009e9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8009e9:	55                   	push   %ebp
  8009ea:	89 e5                	mov    %esp,%ebp
  8009ec:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8009ef:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8009f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8009f6:	8b 45 10             	mov    0x10(%ebp),%eax
  8009f9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8009fd:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a00:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a04:	8b 45 08             	mov    0x8(%ebp),%eax
  800a07:	89 04 24             	mov    %eax,(%esp)
  800a0a:	e8 82 ff ff ff       	call   800991 <vsnprintf>
	va_end(ap);

	return rc;
}
  800a0f:	c9                   	leave  
  800a10:	c3                   	ret    
  800a11:	66 90                	xchg   %ax,%ax
  800a13:	66 90                	xchg   %ax,%ax
  800a15:	66 90                	xchg   %ax,%ax
  800a17:	66 90                	xchg   %ax,%ax
  800a19:	66 90                	xchg   %ax,%ax
  800a1b:	66 90                	xchg   %ax,%ax
  800a1d:	66 90                	xchg   %ax,%ax
  800a1f:	90                   	nop

00800a20 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800a20:	55                   	push   %ebp
  800a21:	89 e5                	mov    %esp,%ebp
  800a23:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800a26:	80 3a 00             	cmpb   $0x0,(%edx)
  800a29:	74 10                	je     800a3b <strlen+0x1b>
  800a2b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800a30:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800a33:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800a37:	75 f7                	jne    800a30 <strlen+0x10>
  800a39:	eb 05                	jmp    800a40 <strlen+0x20>
  800a3b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800a40:	5d                   	pop    %ebp
  800a41:	c3                   	ret    

00800a42 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800a42:	55                   	push   %ebp
  800a43:	89 e5                	mov    %esp,%ebp
  800a45:	53                   	push   %ebx
  800a46:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a49:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a4c:	85 c9                	test   %ecx,%ecx
  800a4e:	74 1c                	je     800a6c <strnlen+0x2a>
  800a50:	80 3b 00             	cmpb   $0x0,(%ebx)
  800a53:	74 1e                	je     800a73 <strnlen+0x31>
  800a55:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  800a5a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a5c:	39 ca                	cmp    %ecx,%edx
  800a5e:	74 18                	je     800a78 <strnlen+0x36>
  800a60:	83 c2 01             	add    $0x1,%edx
  800a63:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800a68:	75 f0                	jne    800a5a <strnlen+0x18>
  800a6a:	eb 0c                	jmp    800a78 <strnlen+0x36>
  800a6c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a71:	eb 05                	jmp    800a78 <strnlen+0x36>
  800a73:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800a78:	5b                   	pop    %ebx
  800a79:	5d                   	pop    %ebp
  800a7a:	c3                   	ret    

00800a7b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800a7b:	55                   	push   %ebp
  800a7c:	89 e5                	mov    %esp,%ebp
  800a7e:	53                   	push   %ebx
  800a7f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a82:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800a85:	89 c2                	mov    %eax,%edx
  800a87:	0f b6 19             	movzbl (%ecx),%ebx
  800a8a:	88 1a                	mov    %bl,(%edx)
  800a8c:	83 c2 01             	add    $0x1,%edx
  800a8f:	83 c1 01             	add    $0x1,%ecx
  800a92:	84 db                	test   %bl,%bl
  800a94:	75 f1                	jne    800a87 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800a96:	5b                   	pop    %ebx
  800a97:	5d                   	pop    %ebp
  800a98:	c3                   	ret    

00800a99 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800a99:	55                   	push   %ebp
  800a9a:	89 e5                	mov    %esp,%ebp
  800a9c:	53                   	push   %ebx
  800a9d:	83 ec 08             	sub    $0x8,%esp
  800aa0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800aa3:	89 1c 24             	mov    %ebx,(%esp)
  800aa6:	e8 75 ff ff ff       	call   800a20 <strlen>
	strcpy(dst + len, src);
  800aab:	8b 55 0c             	mov    0xc(%ebp),%edx
  800aae:	89 54 24 04          	mov    %edx,0x4(%esp)
  800ab2:	01 d8                	add    %ebx,%eax
  800ab4:	89 04 24             	mov    %eax,(%esp)
  800ab7:	e8 bf ff ff ff       	call   800a7b <strcpy>
	return dst;
}
  800abc:	89 d8                	mov    %ebx,%eax
  800abe:	83 c4 08             	add    $0x8,%esp
  800ac1:	5b                   	pop    %ebx
  800ac2:	5d                   	pop    %ebp
  800ac3:	c3                   	ret    

00800ac4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800ac4:	55                   	push   %ebp
  800ac5:	89 e5                	mov    %esp,%ebp
  800ac7:	56                   	push   %esi
  800ac8:	53                   	push   %ebx
  800ac9:	8b 75 08             	mov    0x8(%ebp),%esi
  800acc:	8b 55 0c             	mov    0xc(%ebp),%edx
  800acf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800ad2:	85 db                	test   %ebx,%ebx
  800ad4:	74 16                	je     800aec <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800ad6:	01 f3                	add    %esi,%ebx
  800ad8:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  800ada:	0f b6 02             	movzbl (%edx),%eax
  800add:	88 01                	mov    %al,(%ecx)
  800adf:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800ae2:	80 3a 01             	cmpb   $0x1,(%edx)
  800ae5:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800ae8:	39 d9                	cmp    %ebx,%ecx
  800aea:	75 ee                	jne    800ada <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800aec:	89 f0                	mov    %esi,%eax
  800aee:	5b                   	pop    %ebx
  800aef:	5e                   	pop    %esi
  800af0:	5d                   	pop    %ebp
  800af1:	c3                   	ret    

00800af2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800af2:	55                   	push   %ebp
  800af3:	89 e5                	mov    %esp,%ebp
  800af5:	57                   	push   %edi
  800af6:	56                   	push   %esi
  800af7:	53                   	push   %ebx
  800af8:	8b 7d 08             	mov    0x8(%ebp),%edi
  800afb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800afe:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800b01:	89 f8                	mov    %edi,%eax
  800b03:	85 f6                	test   %esi,%esi
  800b05:	74 33                	je     800b3a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800b07:	83 fe 01             	cmp    $0x1,%esi
  800b0a:	74 25                	je     800b31 <strlcpy+0x3f>
  800b0c:	0f b6 0b             	movzbl (%ebx),%ecx
  800b0f:	84 c9                	test   %cl,%cl
  800b11:	74 22                	je     800b35 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800b13:	83 ee 02             	sub    $0x2,%esi
  800b16:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800b1b:	88 08                	mov    %cl,(%eax)
  800b1d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800b20:	39 f2                	cmp    %esi,%edx
  800b22:	74 13                	je     800b37 <strlcpy+0x45>
  800b24:	83 c2 01             	add    $0x1,%edx
  800b27:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  800b2b:	84 c9                	test   %cl,%cl
  800b2d:	75 ec                	jne    800b1b <strlcpy+0x29>
  800b2f:	eb 06                	jmp    800b37 <strlcpy+0x45>
  800b31:	89 f8                	mov    %edi,%eax
  800b33:	eb 02                	jmp    800b37 <strlcpy+0x45>
  800b35:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800b37:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800b3a:	29 f8                	sub    %edi,%eax
}
  800b3c:	5b                   	pop    %ebx
  800b3d:	5e                   	pop    %esi
  800b3e:	5f                   	pop    %edi
  800b3f:	5d                   	pop    %ebp
  800b40:	c3                   	ret    

00800b41 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800b41:	55                   	push   %ebp
  800b42:	89 e5                	mov    %esp,%ebp
  800b44:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b47:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800b4a:	0f b6 01             	movzbl (%ecx),%eax
  800b4d:	84 c0                	test   %al,%al
  800b4f:	74 15                	je     800b66 <strcmp+0x25>
  800b51:	3a 02                	cmp    (%edx),%al
  800b53:	75 11                	jne    800b66 <strcmp+0x25>
		p++, q++;
  800b55:	83 c1 01             	add    $0x1,%ecx
  800b58:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800b5b:	0f b6 01             	movzbl (%ecx),%eax
  800b5e:	84 c0                	test   %al,%al
  800b60:	74 04                	je     800b66 <strcmp+0x25>
  800b62:	3a 02                	cmp    (%edx),%al
  800b64:	74 ef                	je     800b55 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800b66:	0f b6 c0             	movzbl %al,%eax
  800b69:	0f b6 12             	movzbl (%edx),%edx
  800b6c:	29 d0                	sub    %edx,%eax
}
  800b6e:	5d                   	pop    %ebp
  800b6f:	c3                   	ret    

00800b70 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800b70:	55                   	push   %ebp
  800b71:	89 e5                	mov    %esp,%ebp
  800b73:	56                   	push   %esi
  800b74:	53                   	push   %ebx
  800b75:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800b78:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b7b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800b7e:	85 f6                	test   %esi,%esi
  800b80:	74 29                	je     800bab <strncmp+0x3b>
  800b82:	0f b6 03             	movzbl (%ebx),%eax
  800b85:	84 c0                	test   %al,%al
  800b87:	74 30                	je     800bb9 <strncmp+0x49>
  800b89:	3a 02                	cmp    (%edx),%al
  800b8b:	75 2c                	jne    800bb9 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800b8d:	8d 43 01             	lea    0x1(%ebx),%eax
  800b90:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800b92:	89 c3                	mov    %eax,%ebx
  800b94:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800b97:	39 f0                	cmp    %esi,%eax
  800b99:	74 17                	je     800bb2 <strncmp+0x42>
  800b9b:	0f b6 08             	movzbl (%eax),%ecx
  800b9e:	84 c9                	test   %cl,%cl
  800ba0:	74 17                	je     800bb9 <strncmp+0x49>
  800ba2:	83 c0 01             	add    $0x1,%eax
  800ba5:	3a 0a                	cmp    (%edx),%cl
  800ba7:	74 e9                	je     800b92 <strncmp+0x22>
  800ba9:	eb 0e                	jmp    800bb9 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800bab:	b8 00 00 00 00       	mov    $0x0,%eax
  800bb0:	eb 0f                	jmp    800bc1 <strncmp+0x51>
  800bb2:	b8 00 00 00 00       	mov    $0x0,%eax
  800bb7:	eb 08                	jmp    800bc1 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800bb9:	0f b6 03             	movzbl (%ebx),%eax
  800bbc:	0f b6 12             	movzbl (%edx),%edx
  800bbf:	29 d0                	sub    %edx,%eax
}
  800bc1:	5b                   	pop    %ebx
  800bc2:	5e                   	pop    %esi
  800bc3:	5d                   	pop    %ebp
  800bc4:	c3                   	ret    

00800bc5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800bc5:	55                   	push   %ebp
  800bc6:	89 e5                	mov    %esp,%ebp
  800bc8:	53                   	push   %ebx
  800bc9:	8b 45 08             	mov    0x8(%ebp),%eax
  800bcc:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800bcf:	0f b6 18             	movzbl (%eax),%ebx
  800bd2:	84 db                	test   %bl,%bl
  800bd4:	74 1d                	je     800bf3 <strchr+0x2e>
  800bd6:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800bd8:	38 d3                	cmp    %dl,%bl
  800bda:	75 06                	jne    800be2 <strchr+0x1d>
  800bdc:	eb 1a                	jmp    800bf8 <strchr+0x33>
  800bde:	38 ca                	cmp    %cl,%dl
  800be0:	74 16                	je     800bf8 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800be2:	83 c0 01             	add    $0x1,%eax
  800be5:	0f b6 10             	movzbl (%eax),%edx
  800be8:	84 d2                	test   %dl,%dl
  800bea:	75 f2                	jne    800bde <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800bec:	b8 00 00 00 00       	mov    $0x0,%eax
  800bf1:	eb 05                	jmp    800bf8 <strchr+0x33>
  800bf3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800bf8:	5b                   	pop    %ebx
  800bf9:	5d                   	pop    %ebp
  800bfa:	c3                   	ret    

00800bfb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800bfb:	55                   	push   %ebp
  800bfc:	89 e5                	mov    %esp,%ebp
  800bfe:	53                   	push   %ebx
  800bff:	8b 45 08             	mov    0x8(%ebp),%eax
  800c02:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800c05:	0f b6 18             	movzbl (%eax),%ebx
  800c08:	84 db                	test   %bl,%bl
  800c0a:	74 16                	je     800c22 <strfind+0x27>
  800c0c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800c0e:	38 d3                	cmp    %dl,%bl
  800c10:	75 06                	jne    800c18 <strfind+0x1d>
  800c12:	eb 0e                	jmp    800c22 <strfind+0x27>
  800c14:	38 ca                	cmp    %cl,%dl
  800c16:	74 0a                	je     800c22 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800c18:	83 c0 01             	add    $0x1,%eax
  800c1b:	0f b6 10             	movzbl (%eax),%edx
  800c1e:	84 d2                	test   %dl,%dl
  800c20:	75 f2                	jne    800c14 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800c22:	5b                   	pop    %ebx
  800c23:	5d                   	pop    %ebp
  800c24:	c3                   	ret    

00800c25 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800c25:	55                   	push   %ebp
  800c26:	89 e5                	mov    %esp,%ebp
  800c28:	83 ec 0c             	sub    $0xc,%esp
  800c2b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c2e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c31:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800c34:	8b 7d 08             	mov    0x8(%ebp),%edi
  800c37:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800c3a:	85 c9                	test   %ecx,%ecx
  800c3c:	74 36                	je     800c74 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800c3e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800c44:	75 28                	jne    800c6e <memset+0x49>
  800c46:	f6 c1 03             	test   $0x3,%cl
  800c49:	75 23                	jne    800c6e <memset+0x49>
		c &= 0xFF;
  800c4b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800c4f:	89 d3                	mov    %edx,%ebx
  800c51:	c1 e3 08             	shl    $0x8,%ebx
  800c54:	89 d6                	mov    %edx,%esi
  800c56:	c1 e6 18             	shl    $0x18,%esi
  800c59:	89 d0                	mov    %edx,%eax
  800c5b:	c1 e0 10             	shl    $0x10,%eax
  800c5e:	09 f0                	or     %esi,%eax
  800c60:	09 c2                	or     %eax,%edx
  800c62:	89 d0                	mov    %edx,%eax
  800c64:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800c66:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800c69:	fc                   	cld    
  800c6a:	f3 ab                	rep stos %eax,%es:(%edi)
  800c6c:	eb 06                	jmp    800c74 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800c6e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800c71:	fc                   	cld    
  800c72:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800c74:	89 f8                	mov    %edi,%eax
  800c76:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c79:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c7c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c7f:	89 ec                	mov    %ebp,%esp
  800c81:	5d                   	pop    %ebp
  800c82:	c3                   	ret    

00800c83 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800c83:	55                   	push   %ebp
  800c84:	89 e5                	mov    %esp,%ebp
  800c86:	83 ec 08             	sub    $0x8,%esp
  800c89:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c8c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800c8f:	8b 45 08             	mov    0x8(%ebp),%eax
  800c92:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c95:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800c98:	39 c6                	cmp    %eax,%esi
  800c9a:	73 36                	jae    800cd2 <memmove+0x4f>
  800c9c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800c9f:	39 d0                	cmp    %edx,%eax
  800ca1:	73 2f                	jae    800cd2 <memmove+0x4f>
		s += n;
		d += n;
  800ca3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ca6:	f6 c2 03             	test   $0x3,%dl
  800ca9:	75 1b                	jne    800cc6 <memmove+0x43>
  800cab:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800cb1:	75 13                	jne    800cc6 <memmove+0x43>
  800cb3:	f6 c1 03             	test   $0x3,%cl
  800cb6:	75 0e                	jne    800cc6 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800cb8:	83 ef 04             	sub    $0x4,%edi
  800cbb:	8d 72 fc             	lea    -0x4(%edx),%esi
  800cbe:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800cc1:	fd                   	std    
  800cc2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800cc4:	eb 09                	jmp    800ccf <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800cc6:	83 ef 01             	sub    $0x1,%edi
  800cc9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800ccc:	fd                   	std    
  800ccd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ccf:	fc                   	cld    
  800cd0:	eb 20                	jmp    800cf2 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800cd2:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800cd8:	75 13                	jne    800ced <memmove+0x6a>
  800cda:	a8 03                	test   $0x3,%al
  800cdc:	75 0f                	jne    800ced <memmove+0x6a>
  800cde:	f6 c1 03             	test   $0x3,%cl
  800ce1:	75 0a                	jne    800ced <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800ce3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800ce6:	89 c7                	mov    %eax,%edi
  800ce8:	fc                   	cld    
  800ce9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ceb:	eb 05                	jmp    800cf2 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800ced:	89 c7                	mov    %eax,%edi
  800cef:	fc                   	cld    
  800cf0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800cf2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cf5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cf8:	89 ec                	mov    %ebp,%esp
  800cfa:	5d                   	pop    %ebp
  800cfb:	c3                   	ret    

00800cfc <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800cfc:	55                   	push   %ebp
  800cfd:	89 e5                	mov    %esp,%ebp
  800cff:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800d02:	8b 45 10             	mov    0x10(%ebp),%eax
  800d05:	89 44 24 08          	mov    %eax,0x8(%esp)
  800d09:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d0c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d10:	8b 45 08             	mov    0x8(%ebp),%eax
  800d13:	89 04 24             	mov    %eax,(%esp)
  800d16:	e8 68 ff ff ff       	call   800c83 <memmove>
}
  800d1b:	c9                   	leave  
  800d1c:	c3                   	ret    

00800d1d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800d1d:	55                   	push   %ebp
  800d1e:	89 e5                	mov    %esp,%ebp
  800d20:	57                   	push   %edi
  800d21:	56                   	push   %esi
  800d22:	53                   	push   %ebx
  800d23:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800d26:	8b 75 0c             	mov    0xc(%ebp),%esi
  800d29:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800d2c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800d2f:	85 c0                	test   %eax,%eax
  800d31:	74 36                	je     800d69 <memcmp+0x4c>
		if (*s1 != *s2)
  800d33:	0f b6 03             	movzbl (%ebx),%eax
  800d36:	0f b6 0e             	movzbl (%esi),%ecx
  800d39:	38 c8                	cmp    %cl,%al
  800d3b:	75 17                	jne    800d54 <memcmp+0x37>
  800d3d:	ba 00 00 00 00       	mov    $0x0,%edx
  800d42:	eb 1a                	jmp    800d5e <memcmp+0x41>
  800d44:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800d49:	83 c2 01             	add    $0x1,%edx
  800d4c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800d50:	38 c8                	cmp    %cl,%al
  800d52:	74 0a                	je     800d5e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800d54:	0f b6 c0             	movzbl %al,%eax
  800d57:	0f b6 c9             	movzbl %cl,%ecx
  800d5a:	29 c8                	sub    %ecx,%eax
  800d5c:	eb 10                	jmp    800d6e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800d5e:	39 fa                	cmp    %edi,%edx
  800d60:	75 e2                	jne    800d44 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800d62:	b8 00 00 00 00       	mov    $0x0,%eax
  800d67:	eb 05                	jmp    800d6e <memcmp+0x51>
  800d69:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800d6e:	5b                   	pop    %ebx
  800d6f:	5e                   	pop    %esi
  800d70:	5f                   	pop    %edi
  800d71:	5d                   	pop    %ebp
  800d72:	c3                   	ret    

00800d73 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800d73:	55                   	push   %ebp
  800d74:	89 e5                	mov    %esp,%ebp
  800d76:	53                   	push   %ebx
  800d77:	8b 45 08             	mov    0x8(%ebp),%eax
  800d7a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800d7d:	89 c2                	mov    %eax,%edx
  800d7f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800d82:	39 d0                	cmp    %edx,%eax
  800d84:	73 13                	jae    800d99 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800d86:	89 d9                	mov    %ebx,%ecx
  800d88:	38 18                	cmp    %bl,(%eax)
  800d8a:	75 06                	jne    800d92 <memfind+0x1f>
  800d8c:	eb 0b                	jmp    800d99 <memfind+0x26>
  800d8e:	38 08                	cmp    %cl,(%eax)
  800d90:	74 07                	je     800d99 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800d92:	83 c0 01             	add    $0x1,%eax
  800d95:	39 d0                	cmp    %edx,%eax
  800d97:	75 f5                	jne    800d8e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800d99:	5b                   	pop    %ebx
  800d9a:	5d                   	pop    %ebp
  800d9b:	c3                   	ret    

00800d9c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800d9c:	55                   	push   %ebp
  800d9d:	89 e5                	mov    %esp,%ebp
  800d9f:	57                   	push   %edi
  800da0:	56                   	push   %esi
  800da1:	53                   	push   %ebx
  800da2:	83 ec 04             	sub    $0x4,%esp
  800da5:	8b 55 08             	mov    0x8(%ebp),%edx
  800da8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800dab:	0f b6 02             	movzbl (%edx),%eax
  800dae:	3c 09                	cmp    $0x9,%al
  800db0:	74 04                	je     800db6 <strtol+0x1a>
  800db2:	3c 20                	cmp    $0x20,%al
  800db4:	75 0e                	jne    800dc4 <strtol+0x28>
		s++;
  800db6:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800db9:	0f b6 02             	movzbl (%edx),%eax
  800dbc:	3c 09                	cmp    $0x9,%al
  800dbe:	74 f6                	je     800db6 <strtol+0x1a>
  800dc0:	3c 20                	cmp    $0x20,%al
  800dc2:	74 f2                	je     800db6 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800dc4:	3c 2b                	cmp    $0x2b,%al
  800dc6:	75 0a                	jne    800dd2 <strtol+0x36>
		s++;
  800dc8:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800dcb:	bf 00 00 00 00       	mov    $0x0,%edi
  800dd0:	eb 10                	jmp    800de2 <strtol+0x46>
  800dd2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800dd7:	3c 2d                	cmp    $0x2d,%al
  800dd9:	75 07                	jne    800de2 <strtol+0x46>
		s++, neg = 1;
  800ddb:	83 c2 01             	add    $0x1,%edx
  800dde:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800de2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800de8:	75 15                	jne    800dff <strtol+0x63>
  800dea:	80 3a 30             	cmpb   $0x30,(%edx)
  800ded:	75 10                	jne    800dff <strtol+0x63>
  800def:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800df3:	75 0a                	jne    800dff <strtol+0x63>
		s += 2, base = 16;
  800df5:	83 c2 02             	add    $0x2,%edx
  800df8:	bb 10 00 00 00       	mov    $0x10,%ebx
  800dfd:	eb 10                	jmp    800e0f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800dff:	85 db                	test   %ebx,%ebx
  800e01:	75 0c                	jne    800e0f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800e03:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800e05:	80 3a 30             	cmpb   $0x30,(%edx)
  800e08:	75 05                	jne    800e0f <strtol+0x73>
		s++, base = 8;
  800e0a:	83 c2 01             	add    $0x1,%edx
  800e0d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800e0f:	b8 00 00 00 00       	mov    $0x0,%eax
  800e14:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800e17:	0f b6 0a             	movzbl (%edx),%ecx
  800e1a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800e1d:	89 f3                	mov    %esi,%ebx
  800e1f:	80 fb 09             	cmp    $0x9,%bl
  800e22:	77 08                	ja     800e2c <strtol+0x90>
			dig = *s - '0';
  800e24:	0f be c9             	movsbl %cl,%ecx
  800e27:	83 e9 30             	sub    $0x30,%ecx
  800e2a:	eb 22                	jmp    800e4e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800e2c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800e2f:	89 f3                	mov    %esi,%ebx
  800e31:	80 fb 19             	cmp    $0x19,%bl
  800e34:	77 08                	ja     800e3e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800e36:	0f be c9             	movsbl %cl,%ecx
  800e39:	83 e9 57             	sub    $0x57,%ecx
  800e3c:	eb 10                	jmp    800e4e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800e3e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800e41:	89 f3                	mov    %esi,%ebx
  800e43:	80 fb 19             	cmp    $0x19,%bl
  800e46:	77 16                	ja     800e5e <strtol+0xc2>
			dig = *s - 'A' + 10;
  800e48:	0f be c9             	movsbl %cl,%ecx
  800e4b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800e4e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800e51:	7d 0f                	jge    800e62 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800e53:	83 c2 01             	add    $0x1,%edx
  800e56:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800e5a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800e5c:	eb b9                	jmp    800e17 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800e5e:	89 c1                	mov    %eax,%ecx
  800e60:	eb 02                	jmp    800e64 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800e62:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800e64:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800e68:	74 05                	je     800e6f <strtol+0xd3>
		*endptr = (char *) s;
  800e6a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800e6d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800e6f:	89 ca                	mov    %ecx,%edx
  800e71:	f7 da                	neg    %edx
  800e73:	85 ff                	test   %edi,%edi
  800e75:	0f 45 c2             	cmovne %edx,%eax
}
  800e78:	83 c4 04             	add    $0x4,%esp
  800e7b:	5b                   	pop    %ebx
  800e7c:	5e                   	pop    %esi
  800e7d:	5f                   	pop    %edi
  800e7e:	5d                   	pop    %ebp
  800e7f:	c3                   	ret    

00800e80 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800e80:	55                   	push   %ebp
  800e81:	89 e5                	mov    %esp,%ebp
  800e83:	83 ec 0c             	sub    $0xc,%esp
  800e86:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800e89:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e8c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e8f:	b8 00 00 00 00       	mov    $0x0,%eax
  800e94:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e97:	8b 55 08             	mov    0x8(%ebp),%edx
  800e9a:	89 c3                	mov    %eax,%ebx
  800e9c:	89 c7                	mov    %eax,%edi
  800e9e:	89 c6                	mov    %eax,%esi
  800ea0:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800ea2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800ea5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ea8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800eab:	89 ec                	mov    %ebp,%esp
  800ead:	5d                   	pop    %ebp
  800eae:	c3                   	ret    

00800eaf <sys_cgetc>:

int
sys_cgetc(void)
{
  800eaf:	55                   	push   %ebp
  800eb0:	89 e5                	mov    %esp,%ebp
  800eb2:	83 ec 0c             	sub    $0xc,%esp
  800eb5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800eb8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ebb:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ebe:	ba 00 00 00 00       	mov    $0x0,%edx
  800ec3:	b8 01 00 00 00       	mov    $0x1,%eax
  800ec8:	89 d1                	mov    %edx,%ecx
  800eca:	89 d3                	mov    %edx,%ebx
  800ecc:	89 d7                	mov    %edx,%edi
  800ece:	89 d6                	mov    %edx,%esi
  800ed0:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ed2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800ed5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ed8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800edb:	89 ec                	mov    %ebp,%esp
  800edd:	5d                   	pop    %ebp
  800ede:	c3                   	ret    

00800edf <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800edf:	55                   	push   %ebp
  800ee0:	89 e5                	mov    %esp,%ebp
  800ee2:	83 ec 38             	sub    $0x38,%esp
  800ee5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ee8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800eeb:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800eee:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ef3:	b8 03 00 00 00       	mov    $0x3,%eax
  800ef8:	8b 55 08             	mov    0x8(%ebp),%edx
  800efb:	89 cb                	mov    %ecx,%ebx
  800efd:	89 cf                	mov    %ecx,%edi
  800eff:	89 ce                	mov    %ecx,%esi
  800f01:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f03:	85 c0                	test   %eax,%eax
  800f05:	7e 28                	jle    800f2f <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f07:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f0b:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800f12:	00 
  800f13:	c7 44 24 08 04 18 80 	movl   $0x801804,0x8(%esp)
  800f1a:	00 
  800f1b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f22:	00 
  800f23:	c7 04 24 21 18 80 00 	movl   $0x801821,(%esp)
  800f2a:	e8 b9 f3 ff ff       	call   8002e8 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800f2f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f32:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f35:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f38:	89 ec                	mov    %ebp,%esp
  800f3a:	5d                   	pop    %ebp
  800f3b:	c3                   	ret    

00800f3c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800f3c:	55                   	push   %ebp
  800f3d:	89 e5                	mov    %esp,%ebp
  800f3f:	83 ec 0c             	sub    $0xc,%esp
  800f42:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f45:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f48:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f4b:	ba 00 00 00 00       	mov    $0x0,%edx
  800f50:	b8 02 00 00 00       	mov    $0x2,%eax
  800f55:	89 d1                	mov    %edx,%ecx
  800f57:	89 d3                	mov    %edx,%ebx
  800f59:	89 d7                	mov    %edx,%edi
  800f5b:	89 d6                	mov    %edx,%esi
  800f5d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800f5f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f62:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f65:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f68:	89 ec                	mov    %ebp,%esp
  800f6a:	5d                   	pop    %ebp
  800f6b:	c3                   	ret    

00800f6c <sys_yield>:

void
sys_yield(void)
{
  800f6c:	55                   	push   %ebp
  800f6d:	89 e5                	mov    %esp,%ebp
  800f6f:	83 ec 0c             	sub    $0xc,%esp
  800f72:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f75:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f78:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f7b:	ba 00 00 00 00       	mov    $0x0,%edx
  800f80:	b8 0a 00 00 00       	mov    $0xa,%eax
  800f85:	89 d1                	mov    %edx,%ecx
  800f87:	89 d3                	mov    %edx,%ebx
  800f89:	89 d7                	mov    %edx,%edi
  800f8b:	89 d6                	mov    %edx,%esi
  800f8d:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800f8f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800f92:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800f95:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800f98:	89 ec                	mov    %ebp,%esp
  800f9a:	5d                   	pop    %ebp
  800f9b:	c3                   	ret    

00800f9c <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800f9c:	55                   	push   %ebp
  800f9d:	89 e5                	mov    %esp,%ebp
  800f9f:	83 ec 38             	sub    $0x38,%esp
  800fa2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800fa5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800fa8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800fab:	be 00 00 00 00       	mov    $0x0,%esi
  800fb0:	b8 04 00 00 00       	mov    $0x4,%eax
  800fb5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800fb8:	8b 55 08             	mov    0x8(%ebp),%edx
  800fbb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800fbe:	89 f7                	mov    %esi,%edi
  800fc0:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800fc2:	85 c0                	test   %eax,%eax
  800fc4:	7e 28                	jle    800fee <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  800fc6:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fca:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800fd1:	00 
  800fd2:	c7 44 24 08 04 18 80 	movl   $0x801804,0x8(%esp)
  800fd9:	00 
  800fda:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800fe1:	00 
  800fe2:	c7 04 24 21 18 80 00 	movl   $0x801821,(%esp)
  800fe9:	e8 fa f2 ff ff       	call   8002e8 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800fee:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800ff1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ff4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ff7:	89 ec                	mov    %ebp,%esp
  800ff9:	5d                   	pop    %ebp
  800ffa:	c3                   	ret    

00800ffb <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800ffb:	55                   	push   %ebp
  800ffc:	89 e5                	mov    %esp,%ebp
  800ffe:	83 ec 38             	sub    $0x38,%esp
  801001:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  801004:	89 75 f8             	mov    %esi,-0x8(%ebp)
  801007:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80100a:	b8 05 00 00 00       	mov    $0x5,%eax
  80100f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801012:	8b 55 08             	mov    0x8(%ebp),%edx
  801015:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801018:	8b 7d 14             	mov    0x14(%ebp),%edi
  80101b:	8b 75 18             	mov    0x18(%ebp),%esi
  80101e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  801020:	85 c0                	test   %eax,%eax
  801022:	7e 28                	jle    80104c <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  801024:	89 44 24 10          	mov    %eax,0x10(%esp)
  801028:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  80102f:	00 
  801030:	c7 44 24 08 04 18 80 	movl   $0x801804,0x8(%esp)
  801037:	00 
  801038:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80103f:	00 
  801040:	c7 04 24 21 18 80 00 	movl   $0x801821,(%esp)
  801047:	e8 9c f2 ff ff       	call   8002e8 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  80104c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80104f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  801052:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801055:	89 ec                	mov    %ebp,%esp
  801057:	5d                   	pop    %ebp
  801058:	c3                   	ret    

00801059 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  801059:	55                   	push   %ebp
  80105a:	89 e5                	mov    %esp,%ebp
  80105c:	83 ec 38             	sub    $0x38,%esp
  80105f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  801062:	89 75 f8             	mov    %esi,-0x8(%ebp)
  801065:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801068:	bb 00 00 00 00       	mov    $0x0,%ebx
  80106d:	b8 06 00 00 00       	mov    $0x6,%eax
  801072:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801075:	8b 55 08             	mov    0x8(%ebp),%edx
  801078:	89 df                	mov    %ebx,%edi
  80107a:	89 de                	mov    %ebx,%esi
  80107c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80107e:	85 c0                	test   %eax,%eax
  801080:	7e 28                	jle    8010aa <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  801082:	89 44 24 10          	mov    %eax,0x10(%esp)
  801086:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  80108d:	00 
  80108e:	c7 44 24 08 04 18 80 	movl   $0x801804,0x8(%esp)
  801095:	00 
  801096:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80109d:	00 
  80109e:	c7 04 24 21 18 80 00 	movl   $0x801821,(%esp)
  8010a5:	e8 3e f2 ff ff       	call   8002e8 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  8010aa:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8010ad:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8010b0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8010b3:	89 ec                	mov    %ebp,%esp
  8010b5:	5d                   	pop    %ebp
  8010b6:	c3                   	ret    

008010b7 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  8010b7:	55                   	push   %ebp
  8010b8:	89 e5                	mov    %esp,%ebp
  8010ba:	83 ec 38             	sub    $0x38,%esp
  8010bd:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8010c0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8010c3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8010c6:	bb 00 00 00 00       	mov    $0x0,%ebx
  8010cb:	b8 08 00 00 00       	mov    $0x8,%eax
  8010d0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8010d3:	8b 55 08             	mov    0x8(%ebp),%edx
  8010d6:	89 df                	mov    %ebx,%edi
  8010d8:	89 de                	mov    %ebx,%esi
  8010da:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8010dc:	85 c0                	test   %eax,%eax
  8010de:	7e 28                	jle    801108 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  8010e0:	89 44 24 10          	mov    %eax,0x10(%esp)
  8010e4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  8010eb:	00 
  8010ec:	c7 44 24 08 04 18 80 	movl   $0x801804,0x8(%esp)
  8010f3:	00 
  8010f4:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8010fb:	00 
  8010fc:	c7 04 24 21 18 80 00 	movl   $0x801821,(%esp)
  801103:	e8 e0 f1 ff ff       	call   8002e8 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  801108:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80110b:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80110e:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801111:	89 ec                	mov    %ebp,%esp
  801113:	5d                   	pop    %ebp
  801114:	c3                   	ret    

00801115 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  801115:	55                   	push   %ebp
  801116:	89 e5                	mov    %esp,%ebp
  801118:	83 ec 38             	sub    $0x38,%esp
  80111b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80111e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  801121:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801124:	bb 00 00 00 00       	mov    $0x0,%ebx
  801129:	b8 09 00 00 00       	mov    $0x9,%eax
  80112e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801131:	8b 55 08             	mov    0x8(%ebp),%edx
  801134:	89 df                	mov    %ebx,%edi
  801136:	89 de                	mov    %ebx,%esi
  801138:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80113a:	85 c0                	test   %eax,%eax
  80113c:	7e 28                	jle    801166 <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  80113e:	89 44 24 10          	mov    %eax,0x10(%esp)
  801142:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  801149:	00 
  80114a:	c7 44 24 08 04 18 80 	movl   $0x801804,0x8(%esp)
  801151:	00 
  801152:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  801159:	00 
  80115a:	c7 04 24 21 18 80 00 	movl   $0x801821,(%esp)
  801161:	e8 82 f1 ff ff       	call   8002e8 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  801166:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  801169:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80116c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80116f:	89 ec                	mov    %ebp,%esp
  801171:	5d                   	pop    %ebp
  801172:	c3                   	ret    

00801173 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  801173:	55                   	push   %ebp
  801174:	89 e5                	mov    %esp,%ebp
  801176:	83 ec 0c             	sub    $0xc,%esp
  801179:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80117c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80117f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801182:	be 00 00 00 00       	mov    $0x0,%esi
  801187:	b8 0b 00 00 00       	mov    $0xb,%eax
  80118c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80118f:	8b 55 08             	mov    0x8(%ebp),%edx
  801192:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801195:	8b 7d 14             	mov    0x14(%ebp),%edi
  801198:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  80119a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80119d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8011a0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8011a3:	89 ec                	mov    %ebp,%esp
  8011a5:	5d                   	pop    %ebp
  8011a6:	c3                   	ret    

008011a7 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8011a7:	55                   	push   %ebp
  8011a8:	89 e5                	mov    %esp,%ebp
  8011aa:	83 ec 38             	sub    $0x38,%esp
  8011ad:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8011b0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8011b3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8011b6:	b9 00 00 00 00       	mov    $0x0,%ecx
  8011bb:	b8 0c 00 00 00       	mov    $0xc,%eax
  8011c0:	8b 55 08             	mov    0x8(%ebp),%edx
  8011c3:	89 cb                	mov    %ecx,%ebx
  8011c5:	89 cf                	mov    %ecx,%edi
  8011c7:	89 ce                	mov    %ecx,%esi
  8011c9:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8011cb:	85 c0                	test   %eax,%eax
  8011cd:	7e 28                	jle    8011f7 <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  8011cf:	89 44 24 10          	mov    %eax,0x10(%esp)
  8011d3:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  8011da:	00 
  8011db:	c7 44 24 08 04 18 80 	movl   $0x801804,0x8(%esp)
  8011e2:	00 
  8011e3:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8011ea:	00 
  8011eb:	c7 04 24 21 18 80 00 	movl   $0x801821,(%esp)
  8011f2:	e8 f1 f0 ff ff       	call   8002e8 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  8011f7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8011fa:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8011fd:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801200:	89 ec                	mov    %ebp,%esp
  801202:	5d                   	pop    %ebp
  801203:	c3                   	ret    
  801204:	66 90                	xchg   %ax,%ax
  801206:	66 90                	xchg   %ax,%ax
  801208:	66 90                	xchg   %ax,%ax
  80120a:	66 90                	xchg   %ax,%ax
  80120c:	66 90                	xchg   %ax,%ax
  80120e:	66 90                	xchg   %ax,%ax

00801210 <__udivdi3>:
  801210:	83 ec 1c             	sub    $0x1c,%esp
  801213:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  801217:	89 7c 24 14          	mov    %edi,0x14(%esp)
  80121b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  80121f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  801223:	8b 7c 24 20          	mov    0x20(%esp),%edi
  801227:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  80122b:	85 c0                	test   %eax,%eax
  80122d:	89 74 24 10          	mov    %esi,0x10(%esp)
  801231:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801235:	89 ea                	mov    %ebp,%edx
  801237:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80123b:	75 33                	jne    801270 <__udivdi3+0x60>
  80123d:	39 e9                	cmp    %ebp,%ecx
  80123f:	77 6f                	ja     8012b0 <__udivdi3+0xa0>
  801241:	85 c9                	test   %ecx,%ecx
  801243:	89 ce                	mov    %ecx,%esi
  801245:	75 0b                	jne    801252 <__udivdi3+0x42>
  801247:	b8 01 00 00 00       	mov    $0x1,%eax
  80124c:	31 d2                	xor    %edx,%edx
  80124e:	f7 f1                	div    %ecx
  801250:	89 c6                	mov    %eax,%esi
  801252:	31 d2                	xor    %edx,%edx
  801254:	89 e8                	mov    %ebp,%eax
  801256:	f7 f6                	div    %esi
  801258:	89 c5                	mov    %eax,%ebp
  80125a:	89 f8                	mov    %edi,%eax
  80125c:	f7 f6                	div    %esi
  80125e:	89 ea                	mov    %ebp,%edx
  801260:	8b 74 24 10          	mov    0x10(%esp),%esi
  801264:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801268:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  80126c:	83 c4 1c             	add    $0x1c,%esp
  80126f:	c3                   	ret    
  801270:	39 e8                	cmp    %ebp,%eax
  801272:	77 24                	ja     801298 <__udivdi3+0x88>
  801274:	0f bd c8             	bsr    %eax,%ecx
  801277:	83 f1 1f             	xor    $0x1f,%ecx
  80127a:	89 0c 24             	mov    %ecx,(%esp)
  80127d:	75 49                	jne    8012c8 <__udivdi3+0xb8>
  80127f:	8b 74 24 08          	mov    0x8(%esp),%esi
  801283:	39 74 24 04          	cmp    %esi,0x4(%esp)
  801287:	0f 86 ab 00 00 00    	jbe    801338 <__udivdi3+0x128>
  80128d:	39 e8                	cmp    %ebp,%eax
  80128f:	0f 82 a3 00 00 00    	jb     801338 <__udivdi3+0x128>
  801295:	8d 76 00             	lea    0x0(%esi),%esi
  801298:	31 d2                	xor    %edx,%edx
  80129a:	31 c0                	xor    %eax,%eax
  80129c:	8b 74 24 10          	mov    0x10(%esp),%esi
  8012a0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8012a4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8012a8:	83 c4 1c             	add    $0x1c,%esp
  8012ab:	c3                   	ret    
  8012ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8012b0:	89 f8                	mov    %edi,%eax
  8012b2:	f7 f1                	div    %ecx
  8012b4:	31 d2                	xor    %edx,%edx
  8012b6:	8b 74 24 10          	mov    0x10(%esp),%esi
  8012ba:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8012be:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8012c2:	83 c4 1c             	add    $0x1c,%esp
  8012c5:	c3                   	ret    
  8012c6:	66 90                	xchg   %ax,%ax
  8012c8:	0f b6 0c 24          	movzbl (%esp),%ecx
  8012cc:	89 c6                	mov    %eax,%esi
  8012ce:	b8 20 00 00 00       	mov    $0x20,%eax
  8012d3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  8012d7:	2b 04 24             	sub    (%esp),%eax
  8012da:	8b 7c 24 08          	mov    0x8(%esp),%edi
  8012de:	d3 e6                	shl    %cl,%esi
  8012e0:	89 c1                	mov    %eax,%ecx
  8012e2:	d3 ed                	shr    %cl,%ebp
  8012e4:	0f b6 0c 24          	movzbl (%esp),%ecx
  8012e8:	09 f5                	or     %esi,%ebp
  8012ea:	8b 74 24 04          	mov    0x4(%esp),%esi
  8012ee:	d3 e6                	shl    %cl,%esi
  8012f0:	89 c1                	mov    %eax,%ecx
  8012f2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8012f6:	89 d6                	mov    %edx,%esi
  8012f8:	d3 ee                	shr    %cl,%esi
  8012fa:	0f b6 0c 24          	movzbl (%esp),%ecx
  8012fe:	d3 e2                	shl    %cl,%edx
  801300:	89 c1                	mov    %eax,%ecx
  801302:	d3 ef                	shr    %cl,%edi
  801304:	09 d7                	or     %edx,%edi
  801306:	89 f2                	mov    %esi,%edx
  801308:	89 f8                	mov    %edi,%eax
  80130a:	f7 f5                	div    %ebp
  80130c:	89 d6                	mov    %edx,%esi
  80130e:	89 c7                	mov    %eax,%edi
  801310:	f7 64 24 04          	mull   0x4(%esp)
  801314:	39 d6                	cmp    %edx,%esi
  801316:	72 30                	jb     801348 <__udivdi3+0x138>
  801318:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  80131c:	0f b6 0c 24          	movzbl (%esp),%ecx
  801320:	d3 e5                	shl    %cl,%ebp
  801322:	39 c5                	cmp    %eax,%ebp
  801324:	73 04                	jae    80132a <__udivdi3+0x11a>
  801326:	39 d6                	cmp    %edx,%esi
  801328:	74 1e                	je     801348 <__udivdi3+0x138>
  80132a:	89 f8                	mov    %edi,%eax
  80132c:	31 d2                	xor    %edx,%edx
  80132e:	e9 69 ff ff ff       	jmp    80129c <__udivdi3+0x8c>
  801333:	90                   	nop
  801334:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801338:	31 d2                	xor    %edx,%edx
  80133a:	b8 01 00 00 00       	mov    $0x1,%eax
  80133f:	e9 58 ff ff ff       	jmp    80129c <__udivdi3+0x8c>
  801344:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801348:	8d 47 ff             	lea    -0x1(%edi),%eax
  80134b:	31 d2                	xor    %edx,%edx
  80134d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801351:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801355:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801359:	83 c4 1c             	add    $0x1c,%esp
  80135c:	c3                   	ret    
  80135d:	66 90                	xchg   %ax,%ax
  80135f:	90                   	nop

00801360 <__umoddi3>:
  801360:	83 ec 2c             	sub    $0x2c,%esp
  801363:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  801367:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80136b:	89 74 24 20          	mov    %esi,0x20(%esp)
  80136f:	8b 74 24 38          	mov    0x38(%esp),%esi
  801373:	89 7c 24 24          	mov    %edi,0x24(%esp)
  801377:	8b 7c 24 34          	mov    0x34(%esp),%edi
  80137b:	85 c0                	test   %eax,%eax
  80137d:	89 c2                	mov    %eax,%edx
  80137f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  801383:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  801387:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80138b:	89 74 24 10          	mov    %esi,0x10(%esp)
  80138f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  801393:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801397:	75 1f                	jne    8013b8 <__umoddi3+0x58>
  801399:	39 fe                	cmp    %edi,%esi
  80139b:	76 63                	jbe    801400 <__umoddi3+0xa0>
  80139d:	89 c8                	mov    %ecx,%eax
  80139f:	89 fa                	mov    %edi,%edx
  8013a1:	f7 f6                	div    %esi
  8013a3:	89 d0                	mov    %edx,%eax
  8013a5:	31 d2                	xor    %edx,%edx
  8013a7:	8b 74 24 20          	mov    0x20(%esp),%esi
  8013ab:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8013af:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8013b3:	83 c4 2c             	add    $0x2c,%esp
  8013b6:	c3                   	ret    
  8013b7:	90                   	nop
  8013b8:	39 f8                	cmp    %edi,%eax
  8013ba:	77 64                	ja     801420 <__umoddi3+0xc0>
  8013bc:	0f bd e8             	bsr    %eax,%ebp
  8013bf:	83 f5 1f             	xor    $0x1f,%ebp
  8013c2:	75 74                	jne    801438 <__umoddi3+0xd8>
  8013c4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8013c8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  8013cc:	0f 87 0e 01 00 00    	ja     8014e0 <__umoddi3+0x180>
  8013d2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  8013d6:	29 f1                	sub    %esi,%ecx
  8013d8:	19 c7                	sbb    %eax,%edi
  8013da:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  8013de:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8013e2:	8b 44 24 14          	mov    0x14(%esp),%eax
  8013e6:	8b 54 24 18          	mov    0x18(%esp),%edx
  8013ea:	8b 74 24 20          	mov    0x20(%esp),%esi
  8013ee:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8013f2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8013f6:	83 c4 2c             	add    $0x2c,%esp
  8013f9:	c3                   	ret    
  8013fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801400:	85 f6                	test   %esi,%esi
  801402:	89 f5                	mov    %esi,%ebp
  801404:	75 0b                	jne    801411 <__umoddi3+0xb1>
  801406:	b8 01 00 00 00       	mov    $0x1,%eax
  80140b:	31 d2                	xor    %edx,%edx
  80140d:	f7 f6                	div    %esi
  80140f:	89 c5                	mov    %eax,%ebp
  801411:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801415:	31 d2                	xor    %edx,%edx
  801417:	f7 f5                	div    %ebp
  801419:	89 c8                	mov    %ecx,%eax
  80141b:	f7 f5                	div    %ebp
  80141d:	eb 84                	jmp    8013a3 <__umoddi3+0x43>
  80141f:	90                   	nop
  801420:	89 c8                	mov    %ecx,%eax
  801422:	89 fa                	mov    %edi,%edx
  801424:	8b 74 24 20          	mov    0x20(%esp),%esi
  801428:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80142c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801430:	83 c4 2c             	add    $0x2c,%esp
  801433:	c3                   	ret    
  801434:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801438:	8b 44 24 10          	mov    0x10(%esp),%eax
  80143c:	be 20 00 00 00       	mov    $0x20,%esi
  801441:	89 e9                	mov    %ebp,%ecx
  801443:	29 ee                	sub    %ebp,%esi
  801445:	d3 e2                	shl    %cl,%edx
  801447:	89 f1                	mov    %esi,%ecx
  801449:	d3 e8                	shr    %cl,%eax
  80144b:	89 e9                	mov    %ebp,%ecx
  80144d:	09 d0                	or     %edx,%eax
  80144f:	89 fa                	mov    %edi,%edx
  801451:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801455:	8b 44 24 10          	mov    0x10(%esp),%eax
  801459:	d3 e0                	shl    %cl,%eax
  80145b:	89 f1                	mov    %esi,%ecx
  80145d:	89 44 24 10          	mov    %eax,0x10(%esp)
  801461:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  801465:	d3 ea                	shr    %cl,%edx
  801467:	89 e9                	mov    %ebp,%ecx
  801469:	d3 e7                	shl    %cl,%edi
  80146b:	89 f1                	mov    %esi,%ecx
  80146d:	d3 e8                	shr    %cl,%eax
  80146f:	89 e9                	mov    %ebp,%ecx
  801471:	09 f8                	or     %edi,%eax
  801473:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  801477:	f7 74 24 0c          	divl   0xc(%esp)
  80147b:	d3 e7                	shl    %cl,%edi
  80147d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801481:	89 d7                	mov    %edx,%edi
  801483:	f7 64 24 10          	mull   0x10(%esp)
  801487:	39 d7                	cmp    %edx,%edi
  801489:	89 c1                	mov    %eax,%ecx
  80148b:	89 54 24 14          	mov    %edx,0x14(%esp)
  80148f:	72 3b                	jb     8014cc <__umoddi3+0x16c>
  801491:	39 44 24 18          	cmp    %eax,0x18(%esp)
  801495:	72 31                	jb     8014c8 <__umoddi3+0x168>
  801497:	8b 44 24 18          	mov    0x18(%esp),%eax
  80149b:	29 c8                	sub    %ecx,%eax
  80149d:	19 d7                	sbb    %edx,%edi
  80149f:	89 e9                	mov    %ebp,%ecx
  8014a1:	89 fa                	mov    %edi,%edx
  8014a3:	d3 e8                	shr    %cl,%eax
  8014a5:	89 f1                	mov    %esi,%ecx
  8014a7:	d3 e2                	shl    %cl,%edx
  8014a9:	89 e9                	mov    %ebp,%ecx
  8014ab:	09 d0                	or     %edx,%eax
  8014ad:	89 fa                	mov    %edi,%edx
  8014af:	d3 ea                	shr    %cl,%edx
  8014b1:	8b 74 24 20          	mov    0x20(%esp),%esi
  8014b5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8014b9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8014bd:	83 c4 2c             	add    $0x2c,%esp
  8014c0:	c3                   	ret    
  8014c1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8014c8:	39 d7                	cmp    %edx,%edi
  8014ca:	75 cb                	jne    801497 <__umoddi3+0x137>
  8014cc:	8b 54 24 14          	mov    0x14(%esp),%edx
  8014d0:	89 c1                	mov    %eax,%ecx
  8014d2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  8014d6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  8014da:	eb bb                	jmp    801497 <__umoddi3+0x137>
  8014dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8014e0:	3b 44 24 18          	cmp    0x18(%esp),%eax
  8014e4:	0f 82 e8 fe ff ff    	jb     8013d2 <__umoddi3+0x72>
  8014ea:	e9 f3 fe ff ff       	jmp    8013e2 <__umoddi3+0x82>

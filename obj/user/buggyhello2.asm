
obj/user/buggyhello2：     文件格式 elf32-i386


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
  80002c:	e8 23 00 00 00       	call   800054 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	90                   	nop

00800034 <umain>:

const char *hello = "hello, world\n";

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	sys_cputs(hello, 1024*1024);
  80003a:	c7 44 24 04 00 00 10 	movl   $0x100000,0x4(%esp)
  800041:	00 
  800042:	a1 00 20 80 00       	mov    0x802000,%eax
  800047:	89 04 24             	mov    %eax,(%esp)
  80004a:	e8 8d 00 00 00       	call   8000dc <sys_cputs>
}
  80004f:	c9                   	leave  
  800050:	c3                   	ret    
  800051:	66 90                	xchg   %ax,%ax
  800053:	90                   	nop

00800054 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800054:	55                   	push   %ebp
  800055:	89 e5                	mov    %esp,%ebp
  800057:	57                   	push   %edi
  800058:	56                   	push   %esi
  800059:	53                   	push   %ebx
  80005a:	83 ec 1c             	sub    $0x1c,%esp
  80005d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800060:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  800063:	e8 30 01 00 00       	call   800198 <sys_getenvid>
	thisenv = envs;
  800068:	c7 05 08 20 80 00 00 	movl   $0xeec00000,0x802008
  80006f:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  800072:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  800078:	39 c2                	cmp    %eax,%edx
  80007a:	74 25                	je     8000a1 <libmain+0x4d>
  80007c:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  800081:	eb 12                	jmp    800095 <libmain+0x41>
  800083:	8b 4a 48             	mov    0x48(%edx),%ecx
  800086:	83 c2 7c             	add    $0x7c,%edx
  800089:	39 c1                	cmp    %eax,%ecx
  80008b:	75 08                	jne    800095 <libmain+0x41>
  80008d:	89 3d 08 20 80 00    	mov    %edi,0x802008
  800093:	eb 0c                	jmp    8000a1 <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  800095:	89 d7                	mov    %edx,%edi
  800097:	85 d2                	test   %edx,%edx
  800099:	75 e8                	jne    800083 <libmain+0x2f>
  80009b:	89 15 08 20 80 00    	mov    %edx,0x802008
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000a1:	85 db                	test   %ebx,%ebx
  8000a3:	7e 07                	jle    8000ac <libmain+0x58>
		binaryname = argv[0];
  8000a5:	8b 06                	mov    (%esi),%eax
  8000a7:	a3 04 20 80 00       	mov    %eax,0x802004

	// call user main routine
	umain(argc, argv);
  8000ac:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000b0:	89 1c 24             	mov    %ebx,(%esp)
  8000b3:	e8 7c ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  8000b8:	e8 0b 00 00 00       	call   8000c8 <exit>
}
  8000bd:	83 c4 1c             	add    $0x1c,%esp
  8000c0:	5b                   	pop    %ebx
  8000c1:	5e                   	pop    %esi
  8000c2:	5f                   	pop    %edi
  8000c3:	5d                   	pop    %ebp
  8000c4:	c3                   	ret    
  8000c5:	66 90                	xchg   %ax,%ax
  8000c7:	90                   	nop

008000c8 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000c8:	55                   	push   %ebp
  8000c9:	89 e5                	mov    %esp,%ebp
  8000cb:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000ce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000d5:	e8 61 00 00 00       	call   80013b <sys_env_destroy>
}
  8000da:	c9                   	leave  
  8000db:	c3                   	ret    

008000dc <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000dc:	55                   	push   %ebp
  8000dd:	89 e5                	mov    %esp,%ebp
  8000df:	83 ec 0c             	sub    $0xc,%esp
  8000e2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000e5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000e8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000eb:	b8 00 00 00 00       	mov    $0x0,%eax
  8000f0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000f3:	8b 55 08             	mov    0x8(%ebp),%edx
  8000f6:	89 c3                	mov    %eax,%ebx
  8000f8:	89 c7                	mov    %eax,%edi
  8000fa:	89 c6                	mov    %eax,%esi
  8000fc:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000fe:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800101:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800104:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800107:	89 ec                	mov    %ebp,%esp
  800109:	5d                   	pop    %ebp
  80010a:	c3                   	ret    

0080010b <sys_cgetc>:

int
sys_cgetc(void)
{
  80010b:	55                   	push   %ebp
  80010c:	89 e5                	mov    %esp,%ebp
  80010e:	83 ec 0c             	sub    $0xc,%esp
  800111:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800114:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800117:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80011a:	ba 00 00 00 00       	mov    $0x0,%edx
  80011f:	b8 01 00 00 00       	mov    $0x1,%eax
  800124:	89 d1                	mov    %edx,%ecx
  800126:	89 d3                	mov    %edx,%ebx
  800128:	89 d7                	mov    %edx,%edi
  80012a:	89 d6                	mov    %edx,%esi
  80012c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  80012e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800131:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800134:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800137:	89 ec                	mov    %ebp,%esp
  800139:	5d                   	pop    %ebp
  80013a:	c3                   	ret    

0080013b <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80013b:	55                   	push   %ebp
  80013c:	89 e5                	mov    %esp,%ebp
  80013e:	83 ec 38             	sub    $0x38,%esp
  800141:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800144:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800147:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80014a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80014f:	b8 03 00 00 00       	mov    $0x3,%eax
  800154:	8b 55 08             	mov    0x8(%ebp),%edx
  800157:	89 cb                	mov    %ecx,%ebx
  800159:	89 cf                	mov    %ecx,%edi
  80015b:	89 ce                	mov    %ecx,%esi
  80015d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80015f:	85 c0                	test   %eax,%eax
  800161:	7e 28                	jle    80018b <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800163:	89 44 24 10          	mov    %eax,0x10(%esp)
  800167:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  80016e:	00 
  80016f:	c7 44 24 08 f8 12 80 	movl   $0x8012f8,0x8(%esp)
  800176:	00 
  800177:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80017e:	00 
  80017f:	c7 04 24 15 13 80 00 	movl   $0x801315,(%esp)
  800186:	e8 d5 02 00 00       	call   800460 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80018b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80018e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800191:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800194:	89 ec                	mov    %ebp,%esp
  800196:	5d                   	pop    %ebp
  800197:	c3                   	ret    

00800198 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800198:	55                   	push   %ebp
  800199:	89 e5                	mov    %esp,%ebp
  80019b:	83 ec 0c             	sub    $0xc,%esp
  80019e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8001a1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8001a4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001a7:	ba 00 00 00 00       	mov    $0x0,%edx
  8001ac:	b8 02 00 00 00       	mov    $0x2,%eax
  8001b1:	89 d1                	mov    %edx,%ecx
  8001b3:	89 d3                	mov    %edx,%ebx
  8001b5:	89 d7                	mov    %edx,%edi
  8001b7:	89 d6                	mov    %edx,%esi
  8001b9:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  8001bb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8001be:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8001c1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8001c4:	89 ec                	mov    %ebp,%esp
  8001c6:	5d                   	pop    %ebp
  8001c7:	c3                   	ret    

008001c8 <sys_yield>:

void
sys_yield(void)
{
  8001c8:	55                   	push   %ebp
  8001c9:	89 e5                	mov    %esp,%ebp
  8001cb:	83 ec 0c             	sub    $0xc,%esp
  8001ce:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8001d1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8001d4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001d7:	ba 00 00 00 00       	mov    $0x0,%edx
  8001dc:	b8 0a 00 00 00       	mov    $0xa,%eax
  8001e1:	89 d1                	mov    %edx,%ecx
  8001e3:	89 d3                	mov    %edx,%ebx
  8001e5:	89 d7                	mov    %edx,%edi
  8001e7:	89 d6                	mov    %edx,%esi
  8001e9:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  8001eb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8001ee:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8001f1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8001f4:	89 ec                	mov    %ebp,%esp
  8001f6:	5d                   	pop    %ebp
  8001f7:	c3                   	ret    

008001f8 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  8001f8:	55                   	push   %ebp
  8001f9:	89 e5                	mov    %esp,%ebp
  8001fb:	83 ec 38             	sub    $0x38,%esp
  8001fe:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800201:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800204:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800207:	be 00 00 00 00       	mov    $0x0,%esi
  80020c:	b8 04 00 00 00       	mov    $0x4,%eax
  800211:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800214:	8b 55 08             	mov    0x8(%ebp),%edx
  800217:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80021a:	89 f7                	mov    %esi,%edi
  80021c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80021e:	85 c0                	test   %eax,%eax
  800220:	7e 28                	jle    80024a <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  800222:	89 44 24 10          	mov    %eax,0x10(%esp)
  800226:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  80022d:	00 
  80022e:	c7 44 24 08 f8 12 80 	movl   $0x8012f8,0x8(%esp)
  800235:	00 
  800236:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80023d:	00 
  80023e:	c7 04 24 15 13 80 00 	movl   $0x801315,(%esp)
  800245:	e8 16 02 00 00       	call   800460 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  80024a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80024d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800250:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800253:	89 ec                	mov    %ebp,%esp
  800255:	5d                   	pop    %ebp
  800256:	c3                   	ret    

00800257 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800257:	55                   	push   %ebp
  800258:	89 e5                	mov    %esp,%ebp
  80025a:	83 ec 38             	sub    $0x38,%esp
  80025d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800260:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800263:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800266:	b8 05 00 00 00       	mov    $0x5,%eax
  80026b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80026e:	8b 55 08             	mov    0x8(%ebp),%edx
  800271:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800274:	8b 7d 14             	mov    0x14(%ebp),%edi
  800277:	8b 75 18             	mov    0x18(%ebp),%esi
  80027a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80027c:	85 c0                	test   %eax,%eax
  80027e:	7e 28                	jle    8002a8 <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800280:	89 44 24 10          	mov    %eax,0x10(%esp)
  800284:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  80028b:	00 
  80028c:	c7 44 24 08 f8 12 80 	movl   $0x8012f8,0x8(%esp)
  800293:	00 
  800294:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80029b:	00 
  80029c:	c7 04 24 15 13 80 00 	movl   $0x801315,(%esp)
  8002a3:	e8 b8 01 00 00       	call   800460 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  8002a8:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8002ab:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8002ae:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8002b1:	89 ec                	mov    %ebp,%esp
  8002b3:	5d                   	pop    %ebp
  8002b4:	c3                   	ret    

008002b5 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8002b5:	55                   	push   %ebp
  8002b6:	89 e5                	mov    %esp,%ebp
  8002b8:	83 ec 38             	sub    $0x38,%esp
  8002bb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8002be:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8002c1:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002c4:	bb 00 00 00 00       	mov    $0x0,%ebx
  8002c9:	b8 06 00 00 00       	mov    $0x6,%eax
  8002ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002d1:	8b 55 08             	mov    0x8(%ebp),%edx
  8002d4:	89 df                	mov    %ebx,%edi
  8002d6:	89 de                	mov    %ebx,%esi
  8002d8:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8002da:	85 c0                	test   %eax,%eax
  8002dc:	7e 28                	jle    800306 <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002de:	89 44 24 10          	mov    %eax,0x10(%esp)
  8002e2:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  8002e9:	00 
  8002ea:	c7 44 24 08 f8 12 80 	movl   $0x8012f8,0x8(%esp)
  8002f1:	00 
  8002f2:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8002f9:	00 
  8002fa:	c7 04 24 15 13 80 00 	movl   $0x801315,(%esp)
  800301:	e8 5a 01 00 00       	call   800460 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800306:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800309:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80030c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80030f:	89 ec                	mov    %ebp,%esp
  800311:	5d                   	pop    %ebp
  800312:	c3                   	ret    

00800313 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800313:	55                   	push   %ebp
  800314:	89 e5                	mov    %esp,%ebp
  800316:	83 ec 38             	sub    $0x38,%esp
  800319:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80031c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80031f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800322:	bb 00 00 00 00       	mov    $0x0,%ebx
  800327:	b8 08 00 00 00       	mov    $0x8,%eax
  80032c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80032f:	8b 55 08             	mov    0x8(%ebp),%edx
  800332:	89 df                	mov    %ebx,%edi
  800334:	89 de                	mov    %ebx,%esi
  800336:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800338:	85 c0                	test   %eax,%eax
  80033a:	7e 28                	jle    800364 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  80033c:	89 44 24 10          	mov    %eax,0x10(%esp)
  800340:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800347:	00 
  800348:	c7 44 24 08 f8 12 80 	movl   $0x8012f8,0x8(%esp)
  80034f:	00 
  800350:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800357:	00 
  800358:	c7 04 24 15 13 80 00 	movl   $0x801315,(%esp)
  80035f:	e8 fc 00 00 00       	call   800460 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800364:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800367:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80036a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80036d:	89 ec                	mov    %ebp,%esp
  80036f:	5d                   	pop    %ebp
  800370:	c3                   	ret    

00800371 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800371:	55                   	push   %ebp
  800372:	89 e5                	mov    %esp,%ebp
  800374:	83 ec 38             	sub    $0x38,%esp
  800377:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80037a:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80037d:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800380:	bb 00 00 00 00       	mov    $0x0,%ebx
  800385:	b8 09 00 00 00       	mov    $0x9,%eax
  80038a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80038d:	8b 55 08             	mov    0x8(%ebp),%edx
  800390:	89 df                	mov    %ebx,%edi
  800392:	89 de                	mov    %ebx,%esi
  800394:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800396:	85 c0                	test   %eax,%eax
  800398:	7e 28                	jle    8003c2 <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  80039a:	89 44 24 10          	mov    %eax,0x10(%esp)
  80039e:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  8003a5:	00 
  8003a6:	c7 44 24 08 f8 12 80 	movl   $0x8012f8,0x8(%esp)
  8003ad:	00 
  8003ae:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8003b5:	00 
  8003b6:	c7 04 24 15 13 80 00 	movl   $0x801315,(%esp)
  8003bd:	e8 9e 00 00 00       	call   800460 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8003c2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8003c5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8003c8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8003cb:	89 ec                	mov    %ebp,%esp
  8003cd:	5d                   	pop    %ebp
  8003ce:	c3                   	ret    

008003cf <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8003cf:	55                   	push   %ebp
  8003d0:	89 e5                	mov    %esp,%ebp
  8003d2:	83 ec 0c             	sub    $0xc,%esp
  8003d5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8003d8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8003db:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8003de:	be 00 00 00 00       	mov    $0x0,%esi
  8003e3:	b8 0b 00 00 00       	mov    $0xb,%eax
  8003e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8003eb:	8b 55 08             	mov    0x8(%ebp),%edx
  8003ee:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003f1:	8b 7d 14             	mov    0x14(%ebp),%edi
  8003f4:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8003f6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8003f9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8003fc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8003ff:	89 ec                	mov    %ebp,%esp
  800401:	5d                   	pop    %ebp
  800402:	c3                   	ret    

00800403 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800403:	55                   	push   %ebp
  800404:	89 e5                	mov    %esp,%ebp
  800406:	83 ec 38             	sub    $0x38,%esp
  800409:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80040c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80040f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800412:	b9 00 00 00 00       	mov    $0x0,%ecx
  800417:	b8 0c 00 00 00       	mov    $0xc,%eax
  80041c:	8b 55 08             	mov    0x8(%ebp),%edx
  80041f:	89 cb                	mov    %ecx,%ebx
  800421:	89 cf                	mov    %ecx,%edi
  800423:	89 ce                	mov    %ecx,%esi
  800425:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800427:	85 c0                	test   %eax,%eax
  800429:	7e 28                	jle    800453 <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  80042b:	89 44 24 10          	mov    %eax,0x10(%esp)
  80042f:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800436:	00 
  800437:	c7 44 24 08 f8 12 80 	movl   $0x8012f8,0x8(%esp)
  80043e:	00 
  80043f:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800446:	00 
  800447:	c7 04 24 15 13 80 00 	movl   $0x801315,(%esp)
  80044e:	e8 0d 00 00 00       	call   800460 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800453:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800456:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800459:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80045c:	89 ec                	mov    %ebp,%esp
  80045e:	5d                   	pop    %ebp
  80045f:	c3                   	ret    

00800460 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800460:	55                   	push   %ebp
  800461:	89 e5                	mov    %esp,%ebp
  800463:	56                   	push   %esi
  800464:	53                   	push   %ebx
  800465:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800468:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  80046b:	a1 0c 20 80 00       	mov    0x80200c,%eax
  800470:	85 c0                	test   %eax,%eax
  800472:	74 10                	je     800484 <_panic+0x24>
		cprintf("%s: ", argv0);
  800474:	89 44 24 04          	mov    %eax,0x4(%esp)
  800478:	c7 04 24 23 13 80 00 	movl   $0x801323,(%esp)
  80047f:	e8 ef 00 00 00       	call   800573 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800484:	8b 35 04 20 80 00    	mov    0x802004,%esi
  80048a:	e8 09 fd ff ff       	call   800198 <sys_getenvid>
  80048f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800492:	89 54 24 10          	mov    %edx,0x10(%esp)
  800496:	8b 55 08             	mov    0x8(%ebp),%edx
  800499:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80049d:	89 74 24 08          	mov    %esi,0x8(%esp)
  8004a1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004a5:	c7 04 24 28 13 80 00 	movl   $0x801328,(%esp)
  8004ac:	e8 c2 00 00 00       	call   800573 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8004b1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004b5:	8b 45 10             	mov    0x10(%ebp),%eax
  8004b8:	89 04 24             	mov    %eax,(%esp)
  8004bb:	e8 52 00 00 00       	call   800512 <vcprintf>
	cprintf("\n");
  8004c0:	c7 04 24 ec 12 80 00 	movl   $0x8012ec,(%esp)
  8004c7:	e8 a7 00 00 00       	call   800573 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8004cc:	cc                   	int3   
  8004cd:	eb fd                	jmp    8004cc <_panic+0x6c>
  8004cf:	90                   	nop

008004d0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8004d0:	55                   	push   %ebp
  8004d1:	89 e5                	mov    %esp,%ebp
  8004d3:	53                   	push   %ebx
  8004d4:	83 ec 14             	sub    $0x14,%esp
  8004d7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8004da:	8b 03                	mov    (%ebx),%eax
  8004dc:	8b 55 08             	mov    0x8(%ebp),%edx
  8004df:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8004e3:	83 c0 01             	add    $0x1,%eax
  8004e6:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8004e8:	3d ff 00 00 00       	cmp    $0xff,%eax
  8004ed:	75 19                	jne    800508 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8004ef:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8004f6:	00 
  8004f7:	8d 43 08             	lea    0x8(%ebx),%eax
  8004fa:	89 04 24             	mov    %eax,(%esp)
  8004fd:	e8 da fb ff ff       	call   8000dc <sys_cputs>
		b->idx = 0;
  800502:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800508:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80050c:	83 c4 14             	add    $0x14,%esp
  80050f:	5b                   	pop    %ebx
  800510:	5d                   	pop    %ebp
  800511:	c3                   	ret    

00800512 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800512:	55                   	push   %ebp
  800513:	89 e5                	mov    %esp,%ebp
  800515:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80051b:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800522:	00 00 00 
	b.cnt = 0;
  800525:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80052c:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80052f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800532:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800536:	8b 45 08             	mov    0x8(%ebp),%eax
  800539:	89 44 24 08          	mov    %eax,0x8(%esp)
  80053d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800543:	89 44 24 04          	mov    %eax,0x4(%esp)
  800547:	c7 04 24 d0 04 80 00 	movl   $0x8004d0,(%esp)
  80054e:	e8 af 01 00 00       	call   800702 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800553:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800559:	89 44 24 04          	mov    %eax,0x4(%esp)
  80055d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800563:	89 04 24             	mov    %eax,(%esp)
  800566:	e8 71 fb ff ff       	call   8000dc <sys_cputs>

	return b.cnt;
}
  80056b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800571:	c9                   	leave  
  800572:	c3                   	ret    

00800573 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800573:	55                   	push   %ebp
  800574:	89 e5                	mov    %esp,%ebp
  800576:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800579:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80057c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800580:	8b 45 08             	mov    0x8(%ebp),%eax
  800583:	89 04 24             	mov    %eax,(%esp)
  800586:	e8 87 ff ff ff       	call   800512 <vcprintf>
	va_end(ap);

	return cnt;
}
  80058b:	c9                   	leave  
  80058c:	c3                   	ret    
  80058d:	66 90                	xchg   %ax,%ax
  80058f:	90                   	nop

00800590 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800590:	55                   	push   %ebp
  800591:	89 e5                	mov    %esp,%ebp
  800593:	57                   	push   %edi
  800594:	56                   	push   %esi
  800595:	53                   	push   %ebx
  800596:	83 ec 4c             	sub    $0x4c,%esp
  800599:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80059c:	89 d7                	mov    %edx,%edi
  80059e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8005a1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005a4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005a7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8005aa:	b8 00 00 00 00       	mov    $0x0,%eax
  8005af:	39 d8                	cmp    %ebx,%eax
  8005b1:	72 17                	jb     8005ca <printnum+0x3a>
  8005b3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8005b6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8005b9:	76 0f                	jbe    8005ca <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8005bb:	8b 75 14             	mov    0x14(%ebp),%esi
  8005be:	83 ee 01             	sub    $0x1,%esi
  8005c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005c4:	85 f6                	test   %esi,%esi
  8005c6:	7f 63                	jg     80062b <printnum+0x9b>
  8005c8:	eb 75                	jmp    80063f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8005ca:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8005cd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8005d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d4:	83 e8 01             	sub    $0x1,%eax
  8005d7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005db:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8005de:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8005e2:	8b 44 24 08          	mov    0x8(%esp),%eax
  8005e6:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8005ea:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005ed:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8005f0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8005f7:	00 
  8005f8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8005fb:	89 1c 24             	mov    %ebx,(%esp)
  8005fe:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800601:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800605:	e8 e6 09 00 00       	call   800ff0 <__udivdi3>
  80060a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80060d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800610:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800614:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800618:	89 04 24             	mov    %eax,(%esp)
  80061b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80061f:	89 fa                	mov    %edi,%edx
  800621:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800624:	e8 67 ff ff ff       	call   800590 <printnum>
  800629:	eb 14                	jmp    80063f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80062b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80062f:	8b 45 18             	mov    0x18(%ebp),%eax
  800632:	89 04 24             	mov    %eax,(%esp)
  800635:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800637:	83 ee 01             	sub    $0x1,%esi
  80063a:	75 ef                	jne    80062b <printnum+0x9b>
  80063c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80063f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800643:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800647:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80064a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80064e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800655:	00 
  800656:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800659:	89 1c 24             	mov    %ebx,(%esp)
  80065c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80065f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800663:	e8 d8 0a 00 00       	call   801140 <__umoddi3>
  800668:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80066c:	0f be 80 4c 13 80 00 	movsbl 0x80134c(%eax),%eax
  800673:	89 04 24             	mov    %eax,(%esp)
  800676:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800679:	ff d0                	call   *%eax
}
  80067b:	83 c4 4c             	add    $0x4c,%esp
  80067e:	5b                   	pop    %ebx
  80067f:	5e                   	pop    %esi
  800680:	5f                   	pop    %edi
  800681:	5d                   	pop    %ebp
  800682:	c3                   	ret    

00800683 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800683:	55                   	push   %ebp
  800684:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800686:	83 fa 01             	cmp    $0x1,%edx
  800689:	7e 0e                	jle    800699 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80068b:	8b 10                	mov    (%eax),%edx
  80068d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800690:	89 08                	mov    %ecx,(%eax)
  800692:	8b 02                	mov    (%edx),%eax
  800694:	8b 52 04             	mov    0x4(%edx),%edx
  800697:	eb 22                	jmp    8006bb <getuint+0x38>
	else if (lflag)
  800699:	85 d2                	test   %edx,%edx
  80069b:	74 10                	je     8006ad <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80069d:	8b 10                	mov    (%eax),%edx
  80069f:	8d 4a 04             	lea    0x4(%edx),%ecx
  8006a2:	89 08                	mov    %ecx,(%eax)
  8006a4:	8b 02                	mov    (%edx),%eax
  8006a6:	ba 00 00 00 00       	mov    $0x0,%edx
  8006ab:	eb 0e                	jmp    8006bb <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8006ad:	8b 10                	mov    (%eax),%edx
  8006af:	8d 4a 04             	lea    0x4(%edx),%ecx
  8006b2:	89 08                	mov    %ecx,(%eax)
  8006b4:	8b 02                	mov    (%edx),%eax
  8006b6:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8006bb:	5d                   	pop    %ebp
  8006bc:	c3                   	ret    

008006bd <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8006bd:	55                   	push   %ebp
  8006be:	89 e5                	mov    %esp,%ebp
  8006c0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8006c3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8006c7:	8b 10                	mov    (%eax),%edx
  8006c9:	3b 50 04             	cmp    0x4(%eax),%edx
  8006cc:	73 0a                	jae    8006d8 <sprintputch+0x1b>
		*b->buf++ = ch;
  8006ce:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006d1:	88 0a                	mov    %cl,(%edx)
  8006d3:	83 c2 01             	add    $0x1,%edx
  8006d6:	89 10                	mov    %edx,(%eax)
}
  8006d8:	5d                   	pop    %ebp
  8006d9:	c3                   	ret    

008006da <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8006da:	55                   	push   %ebp
  8006db:	89 e5                	mov    %esp,%ebp
  8006dd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8006e0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8006e3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006e7:	8b 45 10             	mov    0x10(%ebp),%eax
  8006ea:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006f1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006f5:	8b 45 08             	mov    0x8(%ebp),%eax
  8006f8:	89 04 24             	mov    %eax,(%esp)
  8006fb:	e8 02 00 00 00       	call   800702 <vprintfmt>
	va_end(ap);
}
  800700:	c9                   	leave  
  800701:	c3                   	ret    

00800702 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800702:	55                   	push   %ebp
  800703:	89 e5                	mov    %esp,%ebp
  800705:	57                   	push   %edi
  800706:	56                   	push   %esi
  800707:	53                   	push   %ebx
  800708:	83 ec 4c             	sub    $0x4c,%esp
  80070b:	8b 75 08             	mov    0x8(%ebp),%esi
  80070e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800711:	8b 7d 10             	mov    0x10(%ebp),%edi
  800714:	eb 11                	jmp    800727 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800716:	85 c0                	test   %eax,%eax
  800718:	0f 84 db 03 00 00    	je     800af9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80071e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800722:	89 04 24             	mov    %eax,(%esp)
  800725:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800727:	0f b6 07             	movzbl (%edi),%eax
  80072a:	83 c7 01             	add    $0x1,%edi
  80072d:	83 f8 25             	cmp    $0x25,%eax
  800730:	75 e4                	jne    800716 <vprintfmt+0x14>
  800732:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800736:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80073d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800744:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80074b:	ba 00 00 00 00       	mov    $0x0,%edx
  800750:	eb 2b                	jmp    80077d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800752:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800755:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800759:	eb 22                	jmp    80077d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80075b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80075e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800762:	eb 19                	jmp    80077d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800764:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800767:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80076e:	eb 0d                	jmp    80077d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800770:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800773:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800776:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80077d:	0f b6 0f             	movzbl (%edi),%ecx
  800780:	8d 47 01             	lea    0x1(%edi),%eax
  800783:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800786:	0f b6 07             	movzbl (%edi),%eax
  800789:	83 e8 23             	sub    $0x23,%eax
  80078c:	3c 55                	cmp    $0x55,%al
  80078e:	0f 87 40 03 00 00    	ja     800ad4 <vprintfmt+0x3d2>
  800794:	0f b6 c0             	movzbl %al,%eax
  800797:	ff 24 85 20 14 80 00 	jmp    *0x801420(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80079e:	83 e9 30             	sub    $0x30,%ecx
  8007a1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  8007a4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  8007a8:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8007ab:	83 f9 09             	cmp    $0x9,%ecx
  8007ae:	77 57                	ja     800807 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007b0:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007b3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8007b6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8007b9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  8007bc:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8007bf:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8007c3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8007c6:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8007c9:	83 f9 09             	cmp    $0x9,%ecx
  8007cc:	76 eb                	jbe    8007b9 <vprintfmt+0xb7>
  8007ce:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8007d1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  8007d4:	eb 34                	jmp    80080a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8007d6:	8b 45 14             	mov    0x14(%ebp),%eax
  8007d9:	8d 48 04             	lea    0x4(%eax),%ecx
  8007dc:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8007df:	8b 00                	mov    (%eax),%eax
  8007e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007e4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8007e7:	eb 21                	jmp    80080a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  8007e9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8007ed:	0f 88 71 ff ff ff    	js     800764 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007f3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007f6:	eb 85                	jmp    80077d <vprintfmt+0x7b>
  8007f8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8007fb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800802:	e9 76 ff ff ff       	jmp    80077d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800807:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80080a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80080e:	0f 89 69 ff ff ff    	jns    80077d <vprintfmt+0x7b>
  800814:	e9 57 ff ff ff       	jmp    800770 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800819:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80081c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80081f:	e9 59 ff ff ff       	jmp    80077d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800824:	8b 45 14             	mov    0x14(%ebp),%eax
  800827:	8d 50 04             	lea    0x4(%eax),%edx
  80082a:	89 55 14             	mov    %edx,0x14(%ebp)
  80082d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800831:	8b 00                	mov    (%eax),%eax
  800833:	89 04 24             	mov    %eax,(%esp)
  800836:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800838:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80083b:	e9 e7 fe ff ff       	jmp    800727 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800840:	8b 45 14             	mov    0x14(%ebp),%eax
  800843:	8d 50 04             	lea    0x4(%eax),%edx
  800846:	89 55 14             	mov    %edx,0x14(%ebp)
  800849:	8b 00                	mov    (%eax),%eax
  80084b:	89 c2                	mov    %eax,%edx
  80084d:	c1 fa 1f             	sar    $0x1f,%edx
  800850:	31 d0                	xor    %edx,%eax
  800852:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800854:	83 f8 08             	cmp    $0x8,%eax
  800857:	7f 0b                	jg     800864 <vprintfmt+0x162>
  800859:	8b 14 85 80 15 80 00 	mov    0x801580(,%eax,4),%edx
  800860:	85 d2                	test   %edx,%edx
  800862:	75 20                	jne    800884 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800864:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800868:	c7 44 24 08 64 13 80 	movl   $0x801364,0x8(%esp)
  80086f:	00 
  800870:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800874:	89 34 24             	mov    %esi,(%esp)
  800877:	e8 5e fe ff ff       	call   8006da <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80087c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80087f:	e9 a3 fe ff ff       	jmp    800727 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800884:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800888:	c7 44 24 08 6d 13 80 	movl   $0x80136d,0x8(%esp)
  80088f:	00 
  800890:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800894:	89 34 24             	mov    %esi,(%esp)
  800897:	e8 3e fe ff ff       	call   8006da <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80089c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80089f:	e9 83 fe ff ff       	jmp    800727 <vprintfmt+0x25>
  8008a4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8008a7:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8008aa:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8008ad:	8b 45 14             	mov    0x14(%ebp),%eax
  8008b0:	8d 50 04             	lea    0x4(%eax),%edx
  8008b3:	89 55 14             	mov    %edx,0x14(%ebp)
  8008b6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8008b8:	85 ff                	test   %edi,%edi
  8008ba:	b8 5d 13 80 00       	mov    $0x80135d,%eax
  8008bf:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8008c2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8008c6:	74 06                	je     8008ce <vprintfmt+0x1cc>
  8008c8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8008cc:	7f 16                	jg     8008e4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8008ce:	0f b6 17             	movzbl (%edi),%edx
  8008d1:	0f be c2             	movsbl %dl,%eax
  8008d4:	83 c7 01             	add    $0x1,%edi
  8008d7:	85 c0                	test   %eax,%eax
  8008d9:	0f 85 9f 00 00 00    	jne    80097e <vprintfmt+0x27c>
  8008df:	e9 8b 00 00 00       	jmp    80096f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8008e4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8008e8:	89 3c 24             	mov    %edi,(%esp)
  8008eb:	e8 c2 02 00 00       	call   800bb2 <strnlen>
  8008f0:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8008f3:	29 c2                	sub    %eax,%edx
  8008f5:	89 55 d8             	mov    %edx,-0x28(%ebp)
  8008f8:	85 d2                	test   %edx,%edx
  8008fa:	7e d2                	jle    8008ce <vprintfmt+0x1cc>
					putch(padc, putdat);
  8008fc:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800900:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800903:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800906:	89 d7                	mov    %edx,%edi
  800908:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80090c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80090f:	89 04 24             	mov    %eax,(%esp)
  800912:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800914:	83 ef 01             	sub    $0x1,%edi
  800917:	75 ef                	jne    800908 <vprintfmt+0x206>
  800919:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80091c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80091f:	eb ad                	jmp    8008ce <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800921:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800925:	74 20                	je     800947 <vprintfmt+0x245>
  800927:	0f be d2             	movsbl %dl,%edx
  80092a:	83 ea 20             	sub    $0x20,%edx
  80092d:	83 fa 5e             	cmp    $0x5e,%edx
  800930:	76 15                	jbe    800947 <vprintfmt+0x245>
					putch('?', putdat);
  800932:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800935:	89 54 24 04          	mov    %edx,0x4(%esp)
  800939:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800940:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800943:	ff d1                	call   *%ecx
  800945:	eb 0f                	jmp    800956 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800947:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80094a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80094e:	89 04 24             	mov    %eax,(%esp)
  800951:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800954:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800956:	83 eb 01             	sub    $0x1,%ebx
  800959:	0f b6 17             	movzbl (%edi),%edx
  80095c:	0f be c2             	movsbl %dl,%eax
  80095f:	83 c7 01             	add    $0x1,%edi
  800962:	85 c0                	test   %eax,%eax
  800964:	75 24                	jne    80098a <vprintfmt+0x288>
  800966:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800969:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80096c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80096f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800972:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800976:	0f 8e ab fd ff ff    	jle    800727 <vprintfmt+0x25>
  80097c:	eb 20                	jmp    80099e <vprintfmt+0x29c>
  80097e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800981:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800984:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800987:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80098a:	85 f6                	test   %esi,%esi
  80098c:	78 93                	js     800921 <vprintfmt+0x21f>
  80098e:	83 ee 01             	sub    $0x1,%esi
  800991:	79 8e                	jns    800921 <vprintfmt+0x21f>
  800993:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800996:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800999:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80099c:	eb d1                	jmp    80096f <vprintfmt+0x26d>
  80099e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8009a1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8009a5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8009ac:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8009ae:	83 ef 01             	sub    $0x1,%edi
  8009b1:	75 ee                	jne    8009a1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8009b3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8009b6:	e9 6c fd ff ff       	jmp    800727 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8009bb:	83 fa 01             	cmp    $0x1,%edx
  8009be:	66 90                	xchg   %ax,%ax
  8009c0:	7e 16                	jle    8009d8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  8009c2:	8b 45 14             	mov    0x14(%ebp),%eax
  8009c5:	8d 50 08             	lea    0x8(%eax),%edx
  8009c8:	89 55 14             	mov    %edx,0x14(%ebp)
  8009cb:	8b 10                	mov    (%eax),%edx
  8009cd:	8b 48 04             	mov    0x4(%eax),%ecx
  8009d0:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8009d3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8009d6:	eb 32                	jmp    800a0a <vprintfmt+0x308>
	else if (lflag)
  8009d8:	85 d2                	test   %edx,%edx
  8009da:	74 18                	je     8009f4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  8009dc:	8b 45 14             	mov    0x14(%ebp),%eax
  8009df:	8d 50 04             	lea    0x4(%eax),%edx
  8009e2:	89 55 14             	mov    %edx,0x14(%ebp)
  8009e5:	8b 00                	mov    (%eax),%eax
  8009e7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8009ea:	89 c1                	mov    %eax,%ecx
  8009ec:	c1 f9 1f             	sar    $0x1f,%ecx
  8009ef:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8009f2:	eb 16                	jmp    800a0a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  8009f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8009f7:	8d 50 04             	lea    0x4(%eax),%edx
  8009fa:	89 55 14             	mov    %edx,0x14(%ebp)
  8009fd:	8b 00                	mov    (%eax),%eax
  8009ff:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800a02:	89 c7                	mov    %eax,%edi
  800a04:	c1 ff 1f             	sar    $0x1f,%edi
  800a07:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800a0a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800a0d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800a10:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800a15:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800a19:	79 7d                	jns    800a98 <vprintfmt+0x396>
				putch('-', putdat);
  800a1b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a1f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800a26:	ff d6                	call   *%esi
				num = -(long long) num;
  800a28:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800a2b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800a2e:	f7 d8                	neg    %eax
  800a30:	83 d2 00             	adc    $0x0,%edx
  800a33:	f7 da                	neg    %edx
			}
			base = 10;
  800a35:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800a3a:	eb 5c                	jmp    800a98 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800a3c:	8d 45 14             	lea    0x14(%ebp),%eax
  800a3f:	e8 3f fc ff ff       	call   800683 <getuint>
			base = 10;
  800a44:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800a49:	eb 4d                	jmp    800a98 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800a4b:	8d 45 14             	lea    0x14(%ebp),%eax
  800a4e:	e8 30 fc ff ff       	call   800683 <getuint>
			base = 8;
  800a53:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800a58:	eb 3e                	jmp    800a98 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  800a5a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a5e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800a65:	ff d6                	call   *%esi
			putch('x', putdat);
  800a67:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a6b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800a72:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800a74:	8b 45 14             	mov    0x14(%ebp),%eax
  800a77:	8d 50 04             	lea    0x4(%eax),%edx
  800a7a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800a7d:	8b 00                	mov    (%eax),%eax
  800a7f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800a84:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800a89:	eb 0d                	jmp    800a98 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800a8b:	8d 45 14             	lea    0x14(%ebp),%eax
  800a8e:	e8 f0 fb ff ff       	call   800683 <getuint>
			base = 16;
  800a93:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800a98:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  800a9c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800aa0:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800aa3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800aa7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800aab:	89 04 24             	mov    %eax,(%esp)
  800aae:	89 54 24 04          	mov    %edx,0x4(%esp)
  800ab2:	89 da                	mov    %ebx,%edx
  800ab4:	89 f0                	mov    %esi,%eax
  800ab6:	e8 d5 fa ff ff       	call   800590 <printnum>
			break;
  800abb:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800abe:	e9 64 fc ff ff       	jmp    800727 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800ac3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ac7:	89 0c 24             	mov    %ecx,(%esp)
  800aca:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800acc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800acf:	e9 53 fc ff ff       	jmp    800727 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800ad4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ad8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800adf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800ae1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800ae5:	0f 84 3c fc ff ff    	je     800727 <vprintfmt+0x25>
  800aeb:	83 ef 01             	sub    $0x1,%edi
  800aee:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800af2:	75 f7                	jne    800aeb <vprintfmt+0x3e9>
  800af4:	e9 2e fc ff ff       	jmp    800727 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800af9:	83 c4 4c             	add    $0x4c,%esp
  800afc:	5b                   	pop    %ebx
  800afd:	5e                   	pop    %esi
  800afe:	5f                   	pop    %edi
  800aff:	5d                   	pop    %ebp
  800b00:	c3                   	ret    

00800b01 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800b01:	55                   	push   %ebp
  800b02:	89 e5                	mov    %esp,%ebp
  800b04:	83 ec 28             	sub    $0x28,%esp
  800b07:	8b 45 08             	mov    0x8(%ebp),%eax
  800b0a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800b0d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800b10:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800b14:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800b17:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800b1e:	85 d2                	test   %edx,%edx
  800b20:	7e 30                	jle    800b52 <vsnprintf+0x51>
  800b22:	85 c0                	test   %eax,%eax
  800b24:	74 2c                	je     800b52 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800b26:	8b 45 14             	mov    0x14(%ebp),%eax
  800b29:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b2d:	8b 45 10             	mov    0x10(%ebp),%eax
  800b30:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b34:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800b37:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b3b:	c7 04 24 bd 06 80 00 	movl   $0x8006bd,(%esp)
  800b42:	e8 bb fb ff ff       	call   800702 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800b47:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800b4a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800b4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800b50:	eb 05                	jmp    800b57 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800b52:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800b57:	c9                   	leave  
  800b58:	c3                   	ret    

00800b59 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800b59:	55                   	push   %ebp
  800b5a:	89 e5                	mov    %esp,%ebp
  800b5c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800b5f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800b62:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b66:	8b 45 10             	mov    0x10(%ebp),%eax
  800b69:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b6d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b70:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b74:	8b 45 08             	mov    0x8(%ebp),%eax
  800b77:	89 04 24             	mov    %eax,(%esp)
  800b7a:	e8 82 ff ff ff       	call   800b01 <vsnprintf>
	va_end(ap);

	return rc;
}
  800b7f:	c9                   	leave  
  800b80:	c3                   	ret    
  800b81:	66 90                	xchg   %ax,%ax
  800b83:	66 90                	xchg   %ax,%ax
  800b85:	66 90                	xchg   %ax,%ax
  800b87:	66 90                	xchg   %ax,%ax
  800b89:	66 90                	xchg   %ax,%ax
  800b8b:	66 90                	xchg   %ax,%ax
  800b8d:	66 90                	xchg   %ax,%ax
  800b8f:	90                   	nop

00800b90 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800b90:	55                   	push   %ebp
  800b91:	89 e5                	mov    %esp,%ebp
  800b93:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800b96:	80 3a 00             	cmpb   $0x0,(%edx)
  800b99:	74 10                	je     800bab <strlen+0x1b>
  800b9b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800ba0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800ba3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800ba7:	75 f7                	jne    800ba0 <strlen+0x10>
  800ba9:	eb 05                	jmp    800bb0 <strlen+0x20>
  800bab:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800bb0:	5d                   	pop    %ebp
  800bb1:	c3                   	ret    

00800bb2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800bb2:	55                   	push   %ebp
  800bb3:	89 e5                	mov    %esp,%ebp
  800bb5:	53                   	push   %ebx
  800bb6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800bb9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800bbc:	85 c9                	test   %ecx,%ecx
  800bbe:	74 1c                	je     800bdc <strnlen+0x2a>
  800bc0:	80 3b 00             	cmpb   $0x0,(%ebx)
  800bc3:	74 1e                	je     800be3 <strnlen+0x31>
  800bc5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  800bca:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800bcc:	39 ca                	cmp    %ecx,%edx
  800bce:	74 18                	je     800be8 <strnlen+0x36>
  800bd0:	83 c2 01             	add    $0x1,%edx
  800bd3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800bd8:	75 f0                	jne    800bca <strnlen+0x18>
  800bda:	eb 0c                	jmp    800be8 <strnlen+0x36>
  800bdc:	b8 00 00 00 00       	mov    $0x0,%eax
  800be1:	eb 05                	jmp    800be8 <strnlen+0x36>
  800be3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800be8:	5b                   	pop    %ebx
  800be9:	5d                   	pop    %ebp
  800bea:	c3                   	ret    

00800beb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800beb:	55                   	push   %ebp
  800bec:	89 e5                	mov    %esp,%ebp
  800bee:	53                   	push   %ebx
  800bef:	8b 45 08             	mov    0x8(%ebp),%eax
  800bf2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800bf5:	89 c2                	mov    %eax,%edx
  800bf7:	0f b6 19             	movzbl (%ecx),%ebx
  800bfa:	88 1a                	mov    %bl,(%edx)
  800bfc:	83 c2 01             	add    $0x1,%edx
  800bff:	83 c1 01             	add    $0x1,%ecx
  800c02:	84 db                	test   %bl,%bl
  800c04:	75 f1                	jne    800bf7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800c06:	5b                   	pop    %ebx
  800c07:	5d                   	pop    %ebp
  800c08:	c3                   	ret    

00800c09 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800c09:	55                   	push   %ebp
  800c0a:	89 e5                	mov    %esp,%ebp
  800c0c:	53                   	push   %ebx
  800c0d:	83 ec 08             	sub    $0x8,%esp
  800c10:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800c13:	89 1c 24             	mov    %ebx,(%esp)
  800c16:	e8 75 ff ff ff       	call   800b90 <strlen>
	strcpy(dst + len, src);
  800c1b:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c1e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800c22:	01 d8                	add    %ebx,%eax
  800c24:	89 04 24             	mov    %eax,(%esp)
  800c27:	e8 bf ff ff ff       	call   800beb <strcpy>
	return dst;
}
  800c2c:	89 d8                	mov    %ebx,%eax
  800c2e:	83 c4 08             	add    $0x8,%esp
  800c31:	5b                   	pop    %ebx
  800c32:	5d                   	pop    %ebp
  800c33:	c3                   	ret    

00800c34 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800c34:	55                   	push   %ebp
  800c35:	89 e5                	mov    %esp,%ebp
  800c37:	56                   	push   %esi
  800c38:	53                   	push   %ebx
  800c39:	8b 75 08             	mov    0x8(%ebp),%esi
  800c3c:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c3f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800c42:	85 db                	test   %ebx,%ebx
  800c44:	74 16                	je     800c5c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800c46:	01 f3                	add    %esi,%ebx
  800c48:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  800c4a:	0f b6 02             	movzbl (%edx),%eax
  800c4d:	88 01                	mov    %al,(%ecx)
  800c4f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800c52:	80 3a 01             	cmpb   $0x1,(%edx)
  800c55:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800c58:	39 d9                	cmp    %ebx,%ecx
  800c5a:	75 ee                	jne    800c4a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800c5c:	89 f0                	mov    %esi,%eax
  800c5e:	5b                   	pop    %ebx
  800c5f:	5e                   	pop    %esi
  800c60:	5d                   	pop    %ebp
  800c61:	c3                   	ret    

00800c62 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800c62:	55                   	push   %ebp
  800c63:	89 e5                	mov    %esp,%ebp
  800c65:	57                   	push   %edi
  800c66:	56                   	push   %esi
  800c67:	53                   	push   %ebx
  800c68:	8b 7d 08             	mov    0x8(%ebp),%edi
  800c6b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c6e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800c71:	89 f8                	mov    %edi,%eax
  800c73:	85 f6                	test   %esi,%esi
  800c75:	74 33                	je     800caa <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800c77:	83 fe 01             	cmp    $0x1,%esi
  800c7a:	74 25                	je     800ca1 <strlcpy+0x3f>
  800c7c:	0f b6 0b             	movzbl (%ebx),%ecx
  800c7f:	84 c9                	test   %cl,%cl
  800c81:	74 22                	je     800ca5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800c83:	83 ee 02             	sub    $0x2,%esi
  800c86:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800c8b:	88 08                	mov    %cl,(%eax)
  800c8d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800c90:	39 f2                	cmp    %esi,%edx
  800c92:	74 13                	je     800ca7 <strlcpy+0x45>
  800c94:	83 c2 01             	add    $0x1,%edx
  800c97:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  800c9b:	84 c9                	test   %cl,%cl
  800c9d:	75 ec                	jne    800c8b <strlcpy+0x29>
  800c9f:	eb 06                	jmp    800ca7 <strlcpy+0x45>
  800ca1:	89 f8                	mov    %edi,%eax
  800ca3:	eb 02                	jmp    800ca7 <strlcpy+0x45>
  800ca5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800ca7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800caa:	29 f8                	sub    %edi,%eax
}
  800cac:	5b                   	pop    %ebx
  800cad:	5e                   	pop    %esi
  800cae:	5f                   	pop    %edi
  800caf:	5d                   	pop    %ebp
  800cb0:	c3                   	ret    

00800cb1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800cb1:	55                   	push   %ebp
  800cb2:	89 e5                	mov    %esp,%ebp
  800cb4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800cb7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800cba:	0f b6 01             	movzbl (%ecx),%eax
  800cbd:	84 c0                	test   %al,%al
  800cbf:	74 15                	je     800cd6 <strcmp+0x25>
  800cc1:	3a 02                	cmp    (%edx),%al
  800cc3:	75 11                	jne    800cd6 <strcmp+0x25>
		p++, q++;
  800cc5:	83 c1 01             	add    $0x1,%ecx
  800cc8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800ccb:	0f b6 01             	movzbl (%ecx),%eax
  800cce:	84 c0                	test   %al,%al
  800cd0:	74 04                	je     800cd6 <strcmp+0x25>
  800cd2:	3a 02                	cmp    (%edx),%al
  800cd4:	74 ef                	je     800cc5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800cd6:	0f b6 c0             	movzbl %al,%eax
  800cd9:	0f b6 12             	movzbl (%edx),%edx
  800cdc:	29 d0                	sub    %edx,%eax
}
  800cde:	5d                   	pop    %ebp
  800cdf:	c3                   	ret    

00800ce0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800ce0:	55                   	push   %ebp
  800ce1:	89 e5                	mov    %esp,%ebp
  800ce3:	56                   	push   %esi
  800ce4:	53                   	push   %ebx
  800ce5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800ce8:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ceb:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800cee:	85 f6                	test   %esi,%esi
  800cf0:	74 29                	je     800d1b <strncmp+0x3b>
  800cf2:	0f b6 03             	movzbl (%ebx),%eax
  800cf5:	84 c0                	test   %al,%al
  800cf7:	74 30                	je     800d29 <strncmp+0x49>
  800cf9:	3a 02                	cmp    (%edx),%al
  800cfb:	75 2c                	jne    800d29 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800cfd:	8d 43 01             	lea    0x1(%ebx),%eax
  800d00:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800d02:	89 c3                	mov    %eax,%ebx
  800d04:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800d07:	39 f0                	cmp    %esi,%eax
  800d09:	74 17                	je     800d22 <strncmp+0x42>
  800d0b:	0f b6 08             	movzbl (%eax),%ecx
  800d0e:	84 c9                	test   %cl,%cl
  800d10:	74 17                	je     800d29 <strncmp+0x49>
  800d12:	83 c0 01             	add    $0x1,%eax
  800d15:	3a 0a                	cmp    (%edx),%cl
  800d17:	74 e9                	je     800d02 <strncmp+0x22>
  800d19:	eb 0e                	jmp    800d29 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800d1b:	b8 00 00 00 00       	mov    $0x0,%eax
  800d20:	eb 0f                	jmp    800d31 <strncmp+0x51>
  800d22:	b8 00 00 00 00       	mov    $0x0,%eax
  800d27:	eb 08                	jmp    800d31 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800d29:	0f b6 03             	movzbl (%ebx),%eax
  800d2c:	0f b6 12             	movzbl (%edx),%edx
  800d2f:	29 d0                	sub    %edx,%eax
}
  800d31:	5b                   	pop    %ebx
  800d32:	5e                   	pop    %esi
  800d33:	5d                   	pop    %ebp
  800d34:	c3                   	ret    

00800d35 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800d35:	55                   	push   %ebp
  800d36:	89 e5                	mov    %esp,%ebp
  800d38:	53                   	push   %ebx
  800d39:	8b 45 08             	mov    0x8(%ebp),%eax
  800d3c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800d3f:	0f b6 18             	movzbl (%eax),%ebx
  800d42:	84 db                	test   %bl,%bl
  800d44:	74 1d                	je     800d63 <strchr+0x2e>
  800d46:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800d48:	38 d3                	cmp    %dl,%bl
  800d4a:	75 06                	jne    800d52 <strchr+0x1d>
  800d4c:	eb 1a                	jmp    800d68 <strchr+0x33>
  800d4e:	38 ca                	cmp    %cl,%dl
  800d50:	74 16                	je     800d68 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800d52:	83 c0 01             	add    $0x1,%eax
  800d55:	0f b6 10             	movzbl (%eax),%edx
  800d58:	84 d2                	test   %dl,%dl
  800d5a:	75 f2                	jne    800d4e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800d5c:	b8 00 00 00 00       	mov    $0x0,%eax
  800d61:	eb 05                	jmp    800d68 <strchr+0x33>
  800d63:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800d68:	5b                   	pop    %ebx
  800d69:	5d                   	pop    %ebp
  800d6a:	c3                   	ret    

00800d6b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800d6b:	55                   	push   %ebp
  800d6c:	89 e5                	mov    %esp,%ebp
  800d6e:	53                   	push   %ebx
  800d6f:	8b 45 08             	mov    0x8(%ebp),%eax
  800d72:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800d75:	0f b6 18             	movzbl (%eax),%ebx
  800d78:	84 db                	test   %bl,%bl
  800d7a:	74 16                	je     800d92 <strfind+0x27>
  800d7c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800d7e:	38 d3                	cmp    %dl,%bl
  800d80:	75 06                	jne    800d88 <strfind+0x1d>
  800d82:	eb 0e                	jmp    800d92 <strfind+0x27>
  800d84:	38 ca                	cmp    %cl,%dl
  800d86:	74 0a                	je     800d92 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800d88:	83 c0 01             	add    $0x1,%eax
  800d8b:	0f b6 10             	movzbl (%eax),%edx
  800d8e:	84 d2                	test   %dl,%dl
  800d90:	75 f2                	jne    800d84 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800d92:	5b                   	pop    %ebx
  800d93:	5d                   	pop    %ebp
  800d94:	c3                   	ret    

00800d95 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800d95:	55                   	push   %ebp
  800d96:	89 e5                	mov    %esp,%ebp
  800d98:	83 ec 0c             	sub    $0xc,%esp
  800d9b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d9e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800da1:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800da4:	8b 7d 08             	mov    0x8(%ebp),%edi
  800da7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800daa:	85 c9                	test   %ecx,%ecx
  800dac:	74 36                	je     800de4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800dae:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800db4:	75 28                	jne    800dde <memset+0x49>
  800db6:	f6 c1 03             	test   $0x3,%cl
  800db9:	75 23                	jne    800dde <memset+0x49>
		c &= 0xFF;
  800dbb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800dbf:	89 d3                	mov    %edx,%ebx
  800dc1:	c1 e3 08             	shl    $0x8,%ebx
  800dc4:	89 d6                	mov    %edx,%esi
  800dc6:	c1 e6 18             	shl    $0x18,%esi
  800dc9:	89 d0                	mov    %edx,%eax
  800dcb:	c1 e0 10             	shl    $0x10,%eax
  800dce:	09 f0                	or     %esi,%eax
  800dd0:	09 c2                	or     %eax,%edx
  800dd2:	89 d0                	mov    %edx,%eax
  800dd4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800dd6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800dd9:	fc                   	cld    
  800dda:	f3 ab                	rep stos %eax,%es:(%edi)
  800ddc:	eb 06                	jmp    800de4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800dde:	8b 45 0c             	mov    0xc(%ebp),%eax
  800de1:	fc                   	cld    
  800de2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800de4:	89 f8                	mov    %edi,%eax
  800de6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800de9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800dec:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800def:	89 ec                	mov    %ebp,%esp
  800df1:	5d                   	pop    %ebp
  800df2:	c3                   	ret    

00800df3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800df3:	55                   	push   %ebp
  800df4:	89 e5                	mov    %esp,%ebp
  800df6:	83 ec 08             	sub    $0x8,%esp
  800df9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800dfc:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800dff:	8b 45 08             	mov    0x8(%ebp),%eax
  800e02:	8b 75 0c             	mov    0xc(%ebp),%esi
  800e05:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800e08:	39 c6                	cmp    %eax,%esi
  800e0a:	73 36                	jae    800e42 <memmove+0x4f>
  800e0c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800e0f:	39 d0                	cmp    %edx,%eax
  800e11:	73 2f                	jae    800e42 <memmove+0x4f>
		s += n;
		d += n;
  800e13:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e16:	f6 c2 03             	test   $0x3,%dl
  800e19:	75 1b                	jne    800e36 <memmove+0x43>
  800e1b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800e21:	75 13                	jne    800e36 <memmove+0x43>
  800e23:	f6 c1 03             	test   $0x3,%cl
  800e26:	75 0e                	jne    800e36 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800e28:	83 ef 04             	sub    $0x4,%edi
  800e2b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800e2e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800e31:	fd                   	std    
  800e32:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e34:	eb 09                	jmp    800e3f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800e36:	83 ef 01             	sub    $0x1,%edi
  800e39:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800e3c:	fd                   	std    
  800e3d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800e3f:	fc                   	cld    
  800e40:	eb 20                	jmp    800e62 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e42:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800e48:	75 13                	jne    800e5d <memmove+0x6a>
  800e4a:	a8 03                	test   $0x3,%al
  800e4c:	75 0f                	jne    800e5d <memmove+0x6a>
  800e4e:	f6 c1 03             	test   $0x3,%cl
  800e51:	75 0a                	jne    800e5d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800e53:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800e56:	89 c7                	mov    %eax,%edi
  800e58:	fc                   	cld    
  800e59:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e5b:	eb 05                	jmp    800e62 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800e5d:	89 c7                	mov    %eax,%edi
  800e5f:	fc                   	cld    
  800e60:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800e62:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e65:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e68:	89 ec                	mov    %ebp,%esp
  800e6a:	5d                   	pop    %ebp
  800e6b:	c3                   	ret    

00800e6c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800e6c:	55                   	push   %ebp
  800e6d:	89 e5                	mov    %esp,%ebp
  800e6f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800e72:	8b 45 10             	mov    0x10(%ebp),%eax
  800e75:	89 44 24 08          	mov    %eax,0x8(%esp)
  800e79:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e7c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e80:	8b 45 08             	mov    0x8(%ebp),%eax
  800e83:	89 04 24             	mov    %eax,(%esp)
  800e86:	e8 68 ff ff ff       	call   800df3 <memmove>
}
  800e8b:	c9                   	leave  
  800e8c:	c3                   	ret    

00800e8d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800e8d:	55                   	push   %ebp
  800e8e:	89 e5                	mov    %esp,%ebp
  800e90:	57                   	push   %edi
  800e91:	56                   	push   %esi
  800e92:	53                   	push   %ebx
  800e93:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800e96:	8b 75 0c             	mov    0xc(%ebp),%esi
  800e99:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800e9c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800e9f:	85 c0                	test   %eax,%eax
  800ea1:	74 36                	je     800ed9 <memcmp+0x4c>
		if (*s1 != *s2)
  800ea3:	0f b6 03             	movzbl (%ebx),%eax
  800ea6:	0f b6 0e             	movzbl (%esi),%ecx
  800ea9:	38 c8                	cmp    %cl,%al
  800eab:	75 17                	jne    800ec4 <memcmp+0x37>
  800ead:	ba 00 00 00 00       	mov    $0x0,%edx
  800eb2:	eb 1a                	jmp    800ece <memcmp+0x41>
  800eb4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800eb9:	83 c2 01             	add    $0x1,%edx
  800ebc:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800ec0:	38 c8                	cmp    %cl,%al
  800ec2:	74 0a                	je     800ece <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800ec4:	0f b6 c0             	movzbl %al,%eax
  800ec7:	0f b6 c9             	movzbl %cl,%ecx
  800eca:	29 c8                	sub    %ecx,%eax
  800ecc:	eb 10                	jmp    800ede <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ece:	39 fa                	cmp    %edi,%edx
  800ed0:	75 e2                	jne    800eb4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800ed2:	b8 00 00 00 00       	mov    $0x0,%eax
  800ed7:	eb 05                	jmp    800ede <memcmp+0x51>
  800ed9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ede:	5b                   	pop    %ebx
  800edf:	5e                   	pop    %esi
  800ee0:	5f                   	pop    %edi
  800ee1:	5d                   	pop    %ebp
  800ee2:	c3                   	ret    

00800ee3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ee3:	55                   	push   %ebp
  800ee4:	89 e5                	mov    %esp,%ebp
  800ee6:	53                   	push   %ebx
  800ee7:	8b 45 08             	mov    0x8(%ebp),%eax
  800eea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800eed:	89 c2                	mov    %eax,%edx
  800eef:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ef2:	39 d0                	cmp    %edx,%eax
  800ef4:	73 13                	jae    800f09 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ef6:	89 d9                	mov    %ebx,%ecx
  800ef8:	38 18                	cmp    %bl,(%eax)
  800efa:	75 06                	jne    800f02 <memfind+0x1f>
  800efc:	eb 0b                	jmp    800f09 <memfind+0x26>
  800efe:	38 08                	cmp    %cl,(%eax)
  800f00:	74 07                	je     800f09 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800f02:	83 c0 01             	add    $0x1,%eax
  800f05:	39 d0                	cmp    %edx,%eax
  800f07:	75 f5                	jne    800efe <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800f09:	5b                   	pop    %ebx
  800f0a:	5d                   	pop    %ebp
  800f0b:	c3                   	ret    

00800f0c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800f0c:	55                   	push   %ebp
  800f0d:	89 e5                	mov    %esp,%ebp
  800f0f:	57                   	push   %edi
  800f10:	56                   	push   %esi
  800f11:	53                   	push   %ebx
  800f12:	83 ec 04             	sub    $0x4,%esp
  800f15:	8b 55 08             	mov    0x8(%ebp),%edx
  800f18:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f1b:	0f b6 02             	movzbl (%edx),%eax
  800f1e:	3c 09                	cmp    $0x9,%al
  800f20:	74 04                	je     800f26 <strtol+0x1a>
  800f22:	3c 20                	cmp    $0x20,%al
  800f24:	75 0e                	jne    800f34 <strtol+0x28>
		s++;
  800f26:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f29:	0f b6 02             	movzbl (%edx),%eax
  800f2c:	3c 09                	cmp    $0x9,%al
  800f2e:	74 f6                	je     800f26 <strtol+0x1a>
  800f30:	3c 20                	cmp    $0x20,%al
  800f32:	74 f2                	je     800f26 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800f34:	3c 2b                	cmp    $0x2b,%al
  800f36:	75 0a                	jne    800f42 <strtol+0x36>
		s++;
  800f38:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800f3b:	bf 00 00 00 00       	mov    $0x0,%edi
  800f40:	eb 10                	jmp    800f52 <strtol+0x46>
  800f42:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800f47:	3c 2d                	cmp    $0x2d,%al
  800f49:	75 07                	jne    800f52 <strtol+0x46>
		s++, neg = 1;
  800f4b:	83 c2 01             	add    $0x1,%edx
  800f4e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800f52:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800f58:	75 15                	jne    800f6f <strtol+0x63>
  800f5a:	80 3a 30             	cmpb   $0x30,(%edx)
  800f5d:	75 10                	jne    800f6f <strtol+0x63>
  800f5f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800f63:	75 0a                	jne    800f6f <strtol+0x63>
		s += 2, base = 16;
  800f65:	83 c2 02             	add    $0x2,%edx
  800f68:	bb 10 00 00 00       	mov    $0x10,%ebx
  800f6d:	eb 10                	jmp    800f7f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800f6f:	85 db                	test   %ebx,%ebx
  800f71:	75 0c                	jne    800f7f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800f73:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800f75:	80 3a 30             	cmpb   $0x30,(%edx)
  800f78:	75 05                	jne    800f7f <strtol+0x73>
		s++, base = 8;
  800f7a:	83 c2 01             	add    $0x1,%edx
  800f7d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800f7f:	b8 00 00 00 00       	mov    $0x0,%eax
  800f84:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800f87:	0f b6 0a             	movzbl (%edx),%ecx
  800f8a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800f8d:	89 f3                	mov    %esi,%ebx
  800f8f:	80 fb 09             	cmp    $0x9,%bl
  800f92:	77 08                	ja     800f9c <strtol+0x90>
			dig = *s - '0';
  800f94:	0f be c9             	movsbl %cl,%ecx
  800f97:	83 e9 30             	sub    $0x30,%ecx
  800f9a:	eb 22                	jmp    800fbe <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800f9c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800f9f:	89 f3                	mov    %esi,%ebx
  800fa1:	80 fb 19             	cmp    $0x19,%bl
  800fa4:	77 08                	ja     800fae <strtol+0xa2>
			dig = *s - 'a' + 10;
  800fa6:	0f be c9             	movsbl %cl,%ecx
  800fa9:	83 e9 57             	sub    $0x57,%ecx
  800fac:	eb 10                	jmp    800fbe <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800fae:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800fb1:	89 f3                	mov    %esi,%ebx
  800fb3:	80 fb 19             	cmp    $0x19,%bl
  800fb6:	77 16                	ja     800fce <strtol+0xc2>
			dig = *s - 'A' + 10;
  800fb8:	0f be c9             	movsbl %cl,%ecx
  800fbb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800fbe:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800fc1:	7d 0f                	jge    800fd2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800fc3:	83 c2 01             	add    $0x1,%edx
  800fc6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800fca:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800fcc:	eb b9                	jmp    800f87 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800fce:	89 c1                	mov    %eax,%ecx
  800fd0:	eb 02                	jmp    800fd4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800fd2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800fd4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800fd8:	74 05                	je     800fdf <strtol+0xd3>
		*endptr = (char *) s;
  800fda:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800fdd:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800fdf:	89 ca                	mov    %ecx,%edx
  800fe1:	f7 da                	neg    %edx
  800fe3:	85 ff                	test   %edi,%edi
  800fe5:	0f 45 c2             	cmovne %edx,%eax
}
  800fe8:	83 c4 04             	add    $0x4,%esp
  800feb:	5b                   	pop    %ebx
  800fec:	5e                   	pop    %esi
  800fed:	5f                   	pop    %edi
  800fee:	5d                   	pop    %ebp
  800fef:	c3                   	ret    

00800ff0 <__udivdi3>:
  800ff0:	83 ec 1c             	sub    $0x1c,%esp
  800ff3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800ff7:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800ffb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800fff:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  801003:	8b 7c 24 20          	mov    0x20(%esp),%edi
  801007:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  80100b:	85 c0                	test   %eax,%eax
  80100d:	89 74 24 10          	mov    %esi,0x10(%esp)
  801011:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801015:	89 ea                	mov    %ebp,%edx
  801017:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80101b:	75 33                	jne    801050 <__udivdi3+0x60>
  80101d:	39 e9                	cmp    %ebp,%ecx
  80101f:	77 6f                	ja     801090 <__udivdi3+0xa0>
  801021:	85 c9                	test   %ecx,%ecx
  801023:	89 ce                	mov    %ecx,%esi
  801025:	75 0b                	jne    801032 <__udivdi3+0x42>
  801027:	b8 01 00 00 00       	mov    $0x1,%eax
  80102c:	31 d2                	xor    %edx,%edx
  80102e:	f7 f1                	div    %ecx
  801030:	89 c6                	mov    %eax,%esi
  801032:	31 d2                	xor    %edx,%edx
  801034:	89 e8                	mov    %ebp,%eax
  801036:	f7 f6                	div    %esi
  801038:	89 c5                	mov    %eax,%ebp
  80103a:	89 f8                	mov    %edi,%eax
  80103c:	f7 f6                	div    %esi
  80103e:	89 ea                	mov    %ebp,%edx
  801040:	8b 74 24 10          	mov    0x10(%esp),%esi
  801044:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801048:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  80104c:	83 c4 1c             	add    $0x1c,%esp
  80104f:	c3                   	ret    
  801050:	39 e8                	cmp    %ebp,%eax
  801052:	77 24                	ja     801078 <__udivdi3+0x88>
  801054:	0f bd c8             	bsr    %eax,%ecx
  801057:	83 f1 1f             	xor    $0x1f,%ecx
  80105a:	89 0c 24             	mov    %ecx,(%esp)
  80105d:	75 49                	jne    8010a8 <__udivdi3+0xb8>
  80105f:	8b 74 24 08          	mov    0x8(%esp),%esi
  801063:	39 74 24 04          	cmp    %esi,0x4(%esp)
  801067:	0f 86 ab 00 00 00    	jbe    801118 <__udivdi3+0x128>
  80106d:	39 e8                	cmp    %ebp,%eax
  80106f:	0f 82 a3 00 00 00    	jb     801118 <__udivdi3+0x128>
  801075:	8d 76 00             	lea    0x0(%esi),%esi
  801078:	31 d2                	xor    %edx,%edx
  80107a:	31 c0                	xor    %eax,%eax
  80107c:	8b 74 24 10          	mov    0x10(%esp),%esi
  801080:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801084:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801088:	83 c4 1c             	add    $0x1c,%esp
  80108b:	c3                   	ret    
  80108c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801090:	89 f8                	mov    %edi,%eax
  801092:	f7 f1                	div    %ecx
  801094:	31 d2                	xor    %edx,%edx
  801096:	8b 74 24 10          	mov    0x10(%esp),%esi
  80109a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  80109e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8010a2:	83 c4 1c             	add    $0x1c,%esp
  8010a5:	c3                   	ret    
  8010a6:	66 90                	xchg   %ax,%ax
  8010a8:	0f b6 0c 24          	movzbl (%esp),%ecx
  8010ac:	89 c6                	mov    %eax,%esi
  8010ae:	b8 20 00 00 00       	mov    $0x20,%eax
  8010b3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  8010b7:	2b 04 24             	sub    (%esp),%eax
  8010ba:	8b 7c 24 08          	mov    0x8(%esp),%edi
  8010be:	d3 e6                	shl    %cl,%esi
  8010c0:	89 c1                	mov    %eax,%ecx
  8010c2:	d3 ed                	shr    %cl,%ebp
  8010c4:	0f b6 0c 24          	movzbl (%esp),%ecx
  8010c8:	09 f5                	or     %esi,%ebp
  8010ca:	8b 74 24 04          	mov    0x4(%esp),%esi
  8010ce:	d3 e6                	shl    %cl,%esi
  8010d0:	89 c1                	mov    %eax,%ecx
  8010d2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8010d6:	89 d6                	mov    %edx,%esi
  8010d8:	d3 ee                	shr    %cl,%esi
  8010da:	0f b6 0c 24          	movzbl (%esp),%ecx
  8010de:	d3 e2                	shl    %cl,%edx
  8010e0:	89 c1                	mov    %eax,%ecx
  8010e2:	d3 ef                	shr    %cl,%edi
  8010e4:	09 d7                	or     %edx,%edi
  8010e6:	89 f2                	mov    %esi,%edx
  8010e8:	89 f8                	mov    %edi,%eax
  8010ea:	f7 f5                	div    %ebp
  8010ec:	89 d6                	mov    %edx,%esi
  8010ee:	89 c7                	mov    %eax,%edi
  8010f0:	f7 64 24 04          	mull   0x4(%esp)
  8010f4:	39 d6                	cmp    %edx,%esi
  8010f6:	72 30                	jb     801128 <__udivdi3+0x138>
  8010f8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  8010fc:	0f b6 0c 24          	movzbl (%esp),%ecx
  801100:	d3 e5                	shl    %cl,%ebp
  801102:	39 c5                	cmp    %eax,%ebp
  801104:	73 04                	jae    80110a <__udivdi3+0x11a>
  801106:	39 d6                	cmp    %edx,%esi
  801108:	74 1e                	je     801128 <__udivdi3+0x138>
  80110a:	89 f8                	mov    %edi,%eax
  80110c:	31 d2                	xor    %edx,%edx
  80110e:	e9 69 ff ff ff       	jmp    80107c <__udivdi3+0x8c>
  801113:	90                   	nop
  801114:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801118:	31 d2                	xor    %edx,%edx
  80111a:	b8 01 00 00 00       	mov    $0x1,%eax
  80111f:	e9 58 ff ff ff       	jmp    80107c <__udivdi3+0x8c>
  801124:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801128:	8d 47 ff             	lea    -0x1(%edi),%eax
  80112b:	31 d2                	xor    %edx,%edx
  80112d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801131:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801135:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801139:	83 c4 1c             	add    $0x1c,%esp
  80113c:	c3                   	ret    
  80113d:	66 90                	xchg   %ax,%ax
  80113f:	90                   	nop

00801140 <__umoddi3>:
  801140:	83 ec 2c             	sub    $0x2c,%esp
  801143:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  801147:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80114b:	89 74 24 20          	mov    %esi,0x20(%esp)
  80114f:	8b 74 24 38          	mov    0x38(%esp),%esi
  801153:	89 7c 24 24          	mov    %edi,0x24(%esp)
  801157:	8b 7c 24 34          	mov    0x34(%esp),%edi
  80115b:	85 c0                	test   %eax,%eax
  80115d:	89 c2                	mov    %eax,%edx
  80115f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  801163:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  801167:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80116b:	89 74 24 10          	mov    %esi,0x10(%esp)
  80116f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  801173:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801177:	75 1f                	jne    801198 <__umoddi3+0x58>
  801179:	39 fe                	cmp    %edi,%esi
  80117b:	76 63                	jbe    8011e0 <__umoddi3+0xa0>
  80117d:	89 c8                	mov    %ecx,%eax
  80117f:	89 fa                	mov    %edi,%edx
  801181:	f7 f6                	div    %esi
  801183:	89 d0                	mov    %edx,%eax
  801185:	31 d2                	xor    %edx,%edx
  801187:	8b 74 24 20          	mov    0x20(%esp),%esi
  80118b:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80118f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801193:	83 c4 2c             	add    $0x2c,%esp
  801196:	c3                   	ret    
  801197:	90                   	nop
  801198:	39 f8                	cmp    %edi,%eax
  80119a:	77 64                	ja     801200 <__umoddi3+0xc0>
  80119c:	0f bd e8             	bsr    %eax,%ebp
  80119f:	83 f5 1f             	xor    $0x1f,%ebp
  8011a2:	75 74                	jne    801218 <__umoddi3+0xd8>
  8011a4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8011a8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  8011ac:	0f 87 0e 01 00 00    	ja     8012c0 <__umoddi3+0x180>
  8011b2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  8011b6:	29 f1                	sub    %esi,%ecx
  8011b8:	19 c7                	sbb    %eax,%edi
  8011ba:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  8011be:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8011c2:	8b 44 24 14          	mov    0x14(%esp),%eax
  8011c6:	8b 54 24 18          	mov    0x18(%esp),%edx
  8011ca:	8b 74 24 20          	mov    0x20(%esp),%esi
  8011ce:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8011d2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8011d6:	83 c4 2c             	add    $0x2c,%esp
  8011d9:	c3                   	ret    
  8011da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8011e0:	85 f6                	test   %esi,%esi
  8011e2:	89 f5                	mov    %esi,%ebp
  8011e4:	75 0b                	jne    8011f1 <__umoddi3+0xb1>
  8011e6:	b8 01 00 00 00       	mov    $0x1,%eax
  8011eb:	31 d2                	xor    %edx,%edx
  8011ed:	f7 f6                	div    %esi
  8011ef:	89 c5                	mov    %eax,%ebp
  8011f1:	8b 44 24 0c          	mov    0xc(%esp),%eax
  8011f5:	31 d2                	xor    %edx,%edx
  8011f7:	f7 f5                	div    %ebp
  8011f9:	89 c8                	mov    %ecx,%eax
  8011fb:	f7 f5                	div    %ebp
  8011fd:	eb 84                	jmp    801183 <__umoddi3+0x43>
  8011ff:	90                   	nop
  801200:	89 c8                	mov    %ecx,%eax
  801202:	89 fa                	mov    %edi,%edx
  801204:	8b 74 24 20          	mov    0x20(%esp),%esi
  801208:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80120c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801210:	83 c4 2c             	add    $0x2c,%esp
  801213:	c3                   	ret    
  801214:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801218:	8b 44 24 10          	mov    0x10(%esp),%eax
  80121c:	be 20 00 00 00       	mov    $0x20,%esi
  801221:	89 e9                	mov    %ebp,%ecx
  801223:	29 ee                	sub    %ebp,%esi
  801225:	d3 e2                	shl    %cl,%edx
  801227:	89 f1                	mov    %esi,%ecx
  801229:	d3 e8                	shr    %cl,%eax
  80122b:	89 e9                	mov    %ebp,%ecx
  80122d:	09 d0                	or     %edx,%eax
  80122f:	89 fa                	mov    %edi,%edx
  801231:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801235:	8b 44 24 10          	mov    0x10(%esp),%eax
  801239:	d3 e0                	shl    %cl,%eax
  80123b:	89 f1                	mov    %esi,%ecx
  80123d:	89 44 24 10          	mov    %eax,0x10(%esp)
  801241:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  801245:	d3 ea                	shr    %cl,%edx
  801247:	89 e9                	mov    %ebp,%ecx
  801249:	d3 e7                	shl    %cl,%edi
  80124b:	89 f1                	mov    %esi,%ecx
  80124d:	d3 e8                	shr    %cl,%eax
  80124f:	89 e9                	mov    %ebp,%ecx
  801251:	09 f8                	or     %edi,%eax
  801253:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  801257:	f7 74 24 0c          	divl   0xc(%esp)
  80125b:	d3 e7                	shl    %cl,%edi
  80125d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801261:	89 d7                	mov    %edx,%edi
  801263:	f7 64 24 10          	mull   0x10(%esp)
  801267:	39 d7                	cmp    %edx,%edi
  801269:	89 c1                	mov    %eax,%ecx
  80126b:	89 54 24 14          	mov    %edx,0x14(%esp)
  80126f:	72 3b                	jb     8012ac <__umoddi3+0x16c>
  801271:	39 44 24 18          	cmp    %eax,0x18(%esp)
  801275:	72 31                	jb     8012a8 <__umoddi3+0x168>
  801277:	8b 44 24 18          	mov    0x18(%esp),%eax
  80127b:	29 c8                	sub    %ecx,%eax
  80127d:	19 d7                	sbb    %edx,%edi
  80127f:	89 e9                	mov    %ebp,%ecx
  801281:	89 fa                	mov    %edi,%edx
  801283:	d3 e8                	shr    %cl,%eax
  801285:	89 f1                	mov    %esi,%ecx
  801287:	d3 e2                	shl    %cl,%edx
  801289:	89 e9                	mov    %ebp,%ecx
  80128b:	09 d0                	or     %edx,%eax
  80128d:	89 fa                	mov    %edi,%edx
  80128f:	d3 ea                	shr    %cl,%edx
  801291:	8b 74 24 20          	mov    0x20(%esp),%esi
  801295:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801299:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  80129d:	83 c4 2c             	add    $0x2c,%esp
  8012a0:	c3                   	ret    
  8012a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8012a8:	39 d7                	cmp    %edx,%edi
  8012aa:	75 cb                	jne    801277 <__umoddi3+0x137>
  8012ac:	8b 54 24 14          	mov    0x14(%esp),%edx
  8012b0:	89 c1                	mov    %eax,%ecx
  8012b2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  8012b6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  8012ba:	eb bb                	jmp    801277 <__umoddi3+0x137>
  8012bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8012c0:	3b 44 24 18          	cmp    0x18(%esp),%eax
  8012c4:	0f 82 e8 fe ff ff    	jb     8011b2 <__umoddi3+0x72>
  8012ca:	e9 f3 fe ff ff       	jmp    8011c2 <__umoddi3+0x82>

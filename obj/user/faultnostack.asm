
obj/user/faultnostack：     文件格式 elf32-i386


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
  80002c:	e8 2b 00 00 00       	call   80005c <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	90                   	nop

00800034 <umain>:

void _pgfault_upcall();

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	sys_env_set_pgfault_upcall(0, (void*) _pgfault_upcall);
  80003a:	c7 44 24 04 68 04 80 	movl   $0x800468,0x4(%esp)
  800041:	00 
  800042:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800049:	e8 2b 03 00 00       	call   800379 <sys_env_set_pgfault_upcall>
	*(int*)0 = 0;
  80004e:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  800055:	00 00 00 
}
  800058:	c9                   	leave  
  800059:	c3                   	ret    
  80005a:	66 90                	xchg   %ax,%ax

0080005c <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005c:	55                   	push   %ebp
  80005d:	89 e5                	mov    %esp,%ebp
  80005f:	57                   	push   %edi
  800060:	56                   	push   %esi
  800061:	53                   	push   %ebx
  800062:	83 ec 1c             	sub    $0x1c,%esp
  800065:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800068:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  80006b:	e8 30 01 00 00       	call   8001a0 <sys_getenvid>
	thisenv = envs;
  800070:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  800077:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  80007a:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  800080:	39 c2                	cmp    %eax,%edx
  800082:	74 25                	je     8000a9 <libmain+0x4d>
  800084:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  800089:	eb 12                	jmp    80009d <libmain+0x41>
  80008b:	8b 4a 48             	mov    0x48(%edx),%ecx
  80008e:	83 c2 7c             	add    $0x7c,%edx
  800091:	39 c1                	cmp    %eax,%ecx
  800093:	75 08                	jne    80009d <libmain+0x41>
  800095:	89 3d 04 20 80 00    	mov    %edi,0x802004
  80009b:	eb 0c                	jmp    8000a9 <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  80009d:	89 d7                	mov    %edx,%edi
  80009f:	85 d2                	test   %edx,%edx
  8000a1:	75 e8                	jne    80008b <libmain+0x2f>
  8000a3:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000a9:	85 db                	test   %ebx,%ebx
  8000ab:	7e 07                	jle    8000b4 <libmain+0x58>
		binaryname = argv[0];
  8000ad:	8b 06                	mov    (%esi),%eax
  8000af:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000b4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000b8:	89 1c 24             	mov    %ebx,(%esp)
  8000bb:	e8 74 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  8000c0:	e8 0b 00 00 00       	call   8000d0 <exit>
}
  8000c5:	83 c4 1c             	add    $0x1c,%esp
  8000c8:	5b                   	pop    %ebx
  8000c9:	5e                   	pop    %esi
  8000ca:	5f                   	pop    %edi
  8000cb:	5d                   	pop    %ebp
  8000cc:	c3                   	ret    
  8000cd:	66 90                	xchg   %ax,%ax
  8000cf:	90                   	nop

008000d0 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000d0:	55                   	push   %ebp
  8000d1:	89 e5                	mov    %esp,%ebp
  8000d3:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000dd:	e8 61 00 00 00       	call   800143 <sys_env_destroy>
}
  8000e2:	c9                   	leave  
  8000e3:	c3                   	ret    

008000e4 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000e4:	55                   	push   %ebp
  8000e5:	89 e5                	mov    %esp,%ebp
  8000e7:	83 ec 0c             	sub    $0xc,%esp
  8000ea:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000ed:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000f0:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000f3:	b8 00 00 00 00       	mov    $0x0,%eax
  8000f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000fb:	8b 55 08             	mov    0x8(%ebp),%edx
  8000fe:	89 c3                	mov    %eax,%ebx
  800100:	89 c7                	mov    %eax,%edi
  800102:	89 c6                	mov    %eax,%esi
  800104:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800106:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800109:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80010c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80010f:	89 ec                	mov    %ebp,%esp
  800111:	5d                   	pop    %ebp
  800112:	c3                   	ret    

00800113 <sys_cgetc>:

int
sys_cgetc(void)
{
  800113:	55                   	push   %ebp
  800114:	89 e5                	mov    %esp,%ebp
  800116:	83 ec 0c             	sub    $0xc,%esp
  800119:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80011c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80011f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800122:	ba 00 00 00 00       	mov    $0x0,%edx
  800127:	b8 01 00 00 00       	mov    $0x1,%eax
  80012c:	89 d1                	mov    %edx,%ecx
  80012e:	89 d3                	mov    %edx,%ebx
  800130:	89 d7                	mov    %edx,%edi
  800132:	89 d6                	mov    %edx,%esi
  800134:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800136:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800139:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80013c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80013f:	89 ec                	mov    %ebp,%esp
  800141:	5d                   	pop    %ebp
  800142:	c3                   	ret    

00800143 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800143:	55                   	push   %ebp
  800144:	89 e5                	mov    %esp,%ebp
  800146:	83 ec 38             	sub    $0x38,%esp
  800149:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80014c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80014f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800152:	b9 00 00 00 00       	mov    $0x0,%ecx
  800157:	b8 03 00 00 00       	mov    $0x3,%eax
  80015c:	8b 55 08             	mov    0x8(%ebp),%edx
  80015f:	89 cb                	mov    %ecx,%ebx
  800161:	89 cf                	mov    %ecx,%edi
  800163:	89 ce                	mov    %ecx,%esi
  800165:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800167:	85 c0                	test   %eax,%eax
  800169:	7e 28                	jle    800193 <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  80016b:	89 44 24 10          	mov    %eax,0x10(%esp)
  80016f:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800176:	00 
  800177:	c7 44 24 08 8a 13 80 	movl   $0x80138a,0x8(%esp)
  80017e:	00 
  80017f:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800186:	00 
  800187:	c7 04 24 a7 13 80 00 	movl   $0x8013a7,(%esp)
  80018e:	e8 fd 02 00 00       	call   800490 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800193:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800196:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800199:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80019c:	89 ec                	mov    %ebp,%esp
  80019e:	5d                   	pop    %ebp
  80019f:	c3                   	ret    

008001a0 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  8001a0:	55                   	push   %ebp
  8001a1:	89 e5                	mov    %esp,%ebp
  8001a3:	83 ec 0c             	sub    $0xc,%esp
  8001a6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8001a9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8001ac:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001af:	ba 00 00 00 00       	mov    $0x0,%edx
  8001b4:	b8 02 00 00 00       	mov    $0x2,%eax
  8001b9:	89 d1                	mov    %edx,%ecx
  8001bb:	89 d3                	mov    %edx,%ebx
  8001bd:	89 d7                	mov    %edx,%edi
  8001bf:	89 d6                	mov    %edx,%esi
  8001c1:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  8001c3:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8001c6:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8001c9:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8001cc:	89 ec                	mov    %ebp,%esp
  8001ce:	5d                   	pop    %ebp
  8001cf:	c3                   	ret    

008001d0 <sys_yield>:

void
sys_yield(void)
{
  8001d0:	55                   	push   %ebp
  8001d1:	89 e5                	mov    %esp,%ebp
  8001d3:	83 ec 0c             	sub    $0xc,%esp
  8001d6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8001d9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8001dc:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001df:	ba 00 00 00 00       	mov    $0x0,%edx
  8001e4:	b8 0a 00 00 00       	mov    $0xa,%eax
  8001e9:	89 d1                	mov    %edx,%ecx
  8001eb:	89 d3                	mov    %edx,%ebx
  8001ed:	89 d7                	mov    %edx,%edi
  8001ef:	89 d6                	mov    %edx,%esi
  8001f1:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  8001f3:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8001f6:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8001f9:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8001fc:	89 ec                	mov    %ebp,%esp
  8001fe:	5d                   	pop    %ebp
  8001ff:	c3                   	ret    

00800200 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800200:	55                   	push   %ebp
  800201:	89 e5                	mov    %esp,%ebp
  800203:	83 ec 38             	sub    $0x38,%esp
  800206:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800209:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80020c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80020f:	be 00 00 00 00       	mov    $0x0,%esi
  800214:	b8 04 00 00 00       	mov    $0x4,%eax
  800219:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80021c:	8b 55 08             	mov    0x8(%ebp),%edx
  80021f:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800222:	89 f7                	mov    %esi,%edi
  800224:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800226:	85 c0                	test   %eax,%eax
  800228:	7e 28                	jle    800252 <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  80022a:	89 44 24 10          	mov    %eax,0x10(%esp)
  80022e:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800235:	00 
  800236:	c7 44 24 08 8a 13 80 	movl   $0x80138a,0x8(%esp)
  80023d:	00 
  80023e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800245:	00 
  800246:	c7 04 24 a7 13 80 00 	movl   $0x8013a7,(%esp)
  80024d:	e8 3e 02 00 00       	call   800490 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800252:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800255:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800258:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80025b:	89 ec                	mov    %ebp,%esp
  80025d:	5d                   	pop    %ebp
  80025e:	c3                   	ret    

0080025f <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  80025f:	55                   	push   %ebp
  800260:	89 e5                	mov    %esp,%ebp
  800262:	83 ec 38             	sub    $0x38,%esp
  800265:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800268:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80026b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80026e:	b8 05 00 00 00       	mov    $0x5,%eax
  800273:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800276:	8b 55 08             	mov    0x8(%ebp),%edx
  800279:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80027c:	8b 7d 14             	mov    0x14(%ebp),%edi
  80027f:	8b 75 18             	mov    0x18(%ebp),%esi
  800282:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800284:	85 c0                	test   %eax,%eax
  800286:	7e 28                	jle    8002b0 <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800288:	89 44 24 10          	mov    %eax,0x10(%esp)
  80028c:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800293:	00 
  800294:	c7 44 24 08 8a 13 80 	movl   $0x80138a,0x8(%esp)
  80029b:	00 
  80029c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8002a3:	00 
  8002a4:	c7 04 24 a7 13 80 00 	movl   $0x8013a7,(%esp)
  8002ab:	e8 e0 01 00 00       	call   800490 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  8002b0:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8002b3:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8002b6:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8002b9:	89 ec                	mov    %ebp,%esp
  8002bb:	5d                   	pop    %ebp
  8002bc:	c3                   	ret    

008002bd <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8002bd:	55                   	push   %ebp
  8002be:	89 e5                	mov    %esp,%ebp
  8002c0:	83 ec 38             	sub    $0x38,%esp
  8002c3:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8002c6:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8002c9:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002cc:	bb 00 00 00 00       	mov    $0x0,%ebx
  8002d1:	b8 06 00 00 00       	mov    $0x6,%eax
  8002d6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002d9:	8b 55 08             	mov    0x8(%ebp),%edx
  8002dc:	89 df                	mov    %ebx,%edi
  8002de:	89 de                	mov    %ebx,%esi
  8002e0:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8002e2:	85 c0                	test   %eax,%eax
  8002e4:	7e 28                	jle    80030e <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002e6:	89 44 24 10          	mov    %eax,0x10(%esp)
  8002ea:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  8002f1:	00 
  8002f2:	c7 44 24 08 8a 13 80 	movl   $0x80138a,0x8(%esp)
  8002f9:	00 
  8002fa:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800301:	00 
  800302:	c7 04 24 a7 13 80 00 	movl   $0x8013a7,(%esp)
  800309:	e8 82 01 00 00       	call   800490 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  80030e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800311:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800314:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800317:	89 ec                	mov    %ebp,%esp
  800319:	5d                   	pop    %ebp
  80031a:	c3                   	ret    

0080031b <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  80031b:	55                   	push   %ebp
  80031c:	89 e5                	mov    %esp,%ebp
  80031e:	83 ec 38             	sub    $0x38,%esp
  800321:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800324:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800327:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80032a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80032f:	b8 08 00 00 00       	mov    $0x8,%eax
  800334:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800337:	8b 55 08             	mov    0x8(%ebp),%edx
  80033a:	89 df                	mov    %ebx,%edi
  80033c:	89 de                	mov    %ebx,%esi
  80033e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800340:	85 c0                	test   %eax,%eax
  800342:	7e 28                	jle    80036c <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800344:	89 44 24 10          	mov    %eax,0x10(%esp)
  800348:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  80034f:	00 
  800350:	c7 44 24 08 8a 13 80 	movl   $0x80138a,0x8(%esp)
  800357:	00 
  800358:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80035f:	00 
  800360:	c7 04 24 a7 13 80 00 	movl   $0x8013a7,(%esp)
  800367:	e8 24 01 00 00       	call   800490 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  80036c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80036f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800372:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800375:	89 ec                	mov    %ebp,%esp
  800377:	5d                   	pop    %ebp
  800378:	c3                   	ret    

00800379 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800379:	55                   	push   %ebp
  80037a:	89 e5                	mov    %esp,%ebp
  80037c:	83 ec 38             	sub    $0x38,%esp
  80037f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800382:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800385:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800388:	bb 00 00 00 00       	mov    $0x0,%ebx
  80038d:	b8 09 00 00 00       	mov    $0x9,%eax
  800392:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800395:	8b 55 08             	mov    0x8(%ebp),%edx
  800398:	89 df                	mov    %ebx,%edi
  80039a:	89 de                	mov    %ebx,%esi
  80039c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80039e:	85 c0                	test   %eax,%eax
  8003a0:	7e 28                	jle    8003ca <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  8003a2:	89 44 24 10          	mov    %eax,0x10(%esp)
  8003a6:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  8003ad:	00 
  8003ae:	c7 44 24 08 8a 13 80 	movl   $0x80138a,0x8(%esp)
  8003b5:	00 
  8003b6:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8003bd:	00 
  8003be:	c7 04 24 a7 13 80 00 	movl   $0x8013a7,(%esp)
  8003c5:	e8 c6 00 00 00       	call   800490 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8003ca:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8003cd:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8003d0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8003d3:	89 ec                	mov    %ebp,%esp
  8003d5:	5d                   	pop    %ebp
  8003d6:	c3                   	ret    

008003d7 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8003d7:	55                   	push   %ebp
  8003d8:	89 e5                	mov    %esp,%ebp
  8003da:	83 ec 0c             	sub    $0xc,%esp
  8003dd:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8003e0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8003e3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8003e6:	be 00 00 00 00       	mov    $0x0,%esi
  8003eb:	b8 0b 00 00 00       	mov    $0xb,%eax
  8003f0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8003f3:	8b 55 08             	mov    0x8(%ebp),%edx
  8003f6:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003f9:	8b 7d 14             	mov    0x14(%ebp),%edi
  8003fc:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8003fe:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800401:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800404:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800407:	89 ec                	mov    %ebp,%esp
  800409:	5d                   	pop    %ebp
  80040a:	c3                   	ret    

0080040b <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  80040b:	55                   	push   %ebp
  80040c:	89 e5                	mov    %esp,%ebp
  80040e:	83 ec 38             	sub    $0x38,%esp
  800411:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800414:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800417:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80041a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80041f:	b8 0c 00 00 00       	mov    $0xc,%eax
  800424:	8b 55 08             	mov    0x8(%ebp),%edx
  800427:	89 cb                	mov    %ecx,%ebx
  800429:	89 cf                	mov    %ecx,%edi
  80042b:	89 ce                	mov    %ecx,%esi
  80042d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80042f:	85 c0                	test   %eax,%eax
  800431:	7e 28                	jle    80045b <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800433:	89 44 24 10          	mov    %eax,0x10(%esp)
  800437:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  80043e:	00 
  80043f:	c7 44 24 08 8a 13 80 	movl   $0x80138a,0x8(%esp)
  800446:	00 
  800447:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80044e:	00 
  80044f:	c7 04 24 a7 13 80 00 	movl   $0x8013a7,(%esp)
  800456:	e8 35 00 00 00       	call   800490 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  80045b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80045e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800461:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800464:	89 ec                	mov    %ebp,%esp
  800466:	5d                   	pop    %ebp
  800467:	c3                   	ret    

00800468 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  800468:	54                   	push   %esp
	movl _pgfault_handler, %eax
  800469:	a1 0c 20 80 00       	mov    0x80200c,%eax
	call *%eax
  80046e:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  800470:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	addl $8, %esp
  800473:	83 c4 08             	add    $0x8,%esp

	movl 0x20(%esp), %ecx
  800476:	8b 4c 24 20          	mov    0x20(%esp),%ecx
	movl 0x28(%esp), %eax
  80047a:	8b 44 24 28          	mov    0x28(%esp),%eax
	subl $0x4, %eax 
  80047e:	83 e8 04             	sub    $0x4,%eax
	movl %eax, 0x28(%esp)
  800481:	89 44 24 28          	mov    %eax,0x28(%esp)
	movl %ecx, (%eax)
  800485:	89 08                	mov    %ecx,(%eax)


	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  800487:	61                   	popa   

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $4, %esp
  800488:	83 c4 04             	add    $0x4,%esp
	popfl
  80048b:	9d                   	popf   

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	pop %esp
  80048c:	5c                   	pop    %esp
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  80048d:	c3                   	ret    
  80048e:	66 90                	xchg   %ax,%ax

00800490 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800490:	55                   	push   %ebp
  800491:	89 e5                	mov    %esp,%ebp
  800493:	56                   	push   %esi
  800494:	53                   	push   %ebx
  800495:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800498:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  80049b:	a1 08 20 80 00       	mov    0x802008,%eax
  8004a0:	85 c0                	test   %eax,%eax
  8004a2:	74 10                	je     8004b4 <_panic+0x24>
		cprintf("%s: ", argv0);
  8004a4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004a8:	c7 04 24 b5 13 80 00 	movl   $0x8013b5,(%esp)
  8004af:	e8 ef 00 00 00       	call   8005a3 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8004b4:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8004ba:	e8 e1 fc ff ff       	call   8001a0 <sys_getenvid>
  8004bf:	8b 55 0c             	mov    0xc(%ebp),%edx
  8004c2:	89 54 24 10          	mov    %edx,0x10(%esp)
  8004c6:	8b 55 08             	mov    0x8(%ebp),%edx
  8004c9:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8004cd:	89 74 24 08          	mov    %esi,0x8(%esp)
  8004d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004d5:	c7 04 24 bc 13 80 00 	movl   $0x8013bc,(%esp)
  8004dc:	e8 c2 00 00 00       	call   8005a3 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8004e1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004e5:	8b 45 10             	mov    0x10(%ebp),%eax
  8004e8:	89 04 24             	mov    %eax,(%esp)
  8004eb:	e8 52 00 00 00       	call   800542 <vcprintf>
	cprintf("\n");
  8004f0:	c7 04 24 ba 13 80 00 	movl   $0x8013ba,(%esp)
  8004f7:	e8 a7 00 00 00       	call   8005a3 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8004fc:	cc                   	int3   
  8004fd:	eb fd                	jmp    8004fc <_panic+0x6c>
  8004ff:	90                   	nop

00800500 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800500:	55                   	push   %ebp
  800501:	89 e5                	mov    %esp,%ebp
  800503:	53                   	push   %ebx
  800504:	83 ec 14             	sub    $0x14,%esp
  800507:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80050a:	8b 03                	mov    (%ebx),%eax
  80050c:	8b 55 08             	mov    0x8(%ebp),%edx
  80050f:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  800513:	83 c0 01             	add    $0x1,%eax
  800516:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800518:	3d ff 00 00 00       	cmp    $0xff,%eax
  80051d:	75 19                	jne    800538 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80051f:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800526:	00 
  800527:	8d 43 08             	lea    0x8(%ebx),%eax
  80052a:	89 04 24             	mov    %eax,(%esp)
  80052d:	e8 b2 fb ff ff       	call   8000e4 <sys_cputs>
		b->idx = 0;
  800532:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800538:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80053c:	83 c4 14             	add    $0x14,%esp
  80053f:	5b                   	pop    %ebx
  800540:	5d                   	pop    %ebp
  800541:	c3                   	ret    

00800542 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800542:	55                   	push   %ebp
  800543:	89 e5                	mov    %esp,%ebp
  800545:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80054b:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800552:	00 00 00 
	b.cnt = 0;
  800555:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80055c:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80055f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800562:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800566:	8b 45 08             	mov    0x8(%ebp),%eax
  800569:	89 44 24 08          	mov    %eax,0x8(%esp)
  80056d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800573:	89 44 24 04          	mov    %eax,0x4(%esp)
  800577:	c7 04 24 00 05 80 00 	movl   $0x800500,(%esp)
  80057e:	e8 af 01 00 00       	call   800732 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800583:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800589:	89 44 24 04          	mov    %eax,0x4(%esp)
  80058d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800593:	89 04 24             	mov    %eax,(%esp)
  800596:	e8 49 fb ff ff       	call   8000e4 <sys_cputs>

	return b.cnt;
}
  80059b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8005a1:	c9                   	leave  
  8005a2:	c3                   	ret    

008005a3 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8005a3:	55                   	push   %ebp
  8005a4:	89 e5                	mov    %esp,%ebp
  8005a6:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8005a9:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8005ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  8005b0:	8b 45 08             	mov    0x8(%ebp),%eax
  8005b3:	89 04 24             	mov    %eax,(%esp)
  8005b6:	e8 87 ff ff ff       	call   800542 <vcprintf>
	va_end(ap);

	return cnt;
}
  8005bb:	c9                   	leave  
  8005bc:	c3                   	ret    
  8005bd:	66 90                	xchg   %ax,%ax
  8005bf:	90                   	nop

008005c0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8005c0:	55                   	push   %ebp
  8005c1:	89 e5                	mov    %esp,%ebp
  8005c3:	57                   	push   %edi
  8005c4:	56                   	push   %esi
  8005c5:	53                   	push   %ebx
  8005c6:	83 ec 4c             	sub    $0x4c,%esp
  8005c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8005cc:	89 d7                	mov    %edx,%edi
  8005ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8005d1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005d4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005d7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8005da:	b8 00 00 00 00       	mov    $0x0,%eax
  8005df:	39 d8                	cmp    %ebx,%eax
  8005e1:	72 17                	jb     8005fa <printnum+0x3a>
  8005e3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8005e6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8005e9:	76 0f                	jbe    8005fa <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8005eb:	8b 75 14             	mov    0x14(%ebp),%esi
  8005ee:	83 ee 01             	sub    $0x1,%esi
  8005f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005f4:	85 f6                	test   %esi,%esi
  8005f6:	7f 63                	jg     80065b <printnum+0x9b>
  8005f8:	eb 75                	jmp    80066f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8005fa:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8005fd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800601:	8b 45 14             	mov    0x14(%ebp),%eax
  800604:	83 e8 01             	sub    $0x1,%eax
  800607:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80060b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80060e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800612:	8b 44 24 08          	mov    0x8(%esp),%eax
  800616:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80061a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80061d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800620:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800627:	00 
  800628:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80062b:	89 1c 24             	mov    %ebx,(%esp)
  80062e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800631:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800635:	e8 56 0a 00 00       	call   801090 <__udivdi3>
  80063a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80063d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800640:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800644:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800648:	89 04 24             	mov    %eax,(%esp)
  80064b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80064f:	89 fa                	mov    %edi,%edx
  800651:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800654:	e8 67 ff ff ff       	call   8005c0 <printnum>
  800659:	eb 14                	jmp    80066f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80065b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80065f:	8b 45 18             	mov    0x18(%ebp),%eax
  800662:	89 04 24             	mov    %eax,(%esp)
  800665:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800667:	83 ee 01             	sub    $0x1,%esi
  80066a:	75 ef                	jne    80065b <printnum+0x9b>
  80066c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80066f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800673:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800677:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80067a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80067e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800685:	00 
  800686:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800689:	89 1c 24             	mov    %ebx,(%esp)
  80068c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80068f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800693:	e8 48 0b 00 00       	call   8011e0 <__umoddi3>
  800698:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80069c:	0f be 80 df 13 80 00 	movsbl 0x8013df(%eax),%eax
  8006a3:	89 04 24             	mov    %eax,(%esp)
  8006a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8006a9:	ff d0                	call   *%eax
}
  8006ab:	83 c4 4c             	add    $0x4c,%esp
  8006ae:	5b                   	pop    %ebx
  8006af:	5e                   	pop    %esi
  8006b0:	5f                   	pop    %edi
  8006b1:	5d                   	pop    %ebp
  8006b2:	c3                   	ret    

008006b3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8006b3:	55                   	push   %ebp
  8006b4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8006b6:	83 fa 01             	cmp    $0x1,%edx
  8006b9:	7e 0e                	jle    8006c9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8006bb:	8b 10                	mov    (%eax),%edx
  8006bd:	8d 4a 08             	lea    0x8(%edx),%ecx
  8006c0:	89 08                	mov    %ecx,(%eax)
  8006c2:	8b 02                	mov    (%edx),%eax
  8006c4:	8b 52 04             	mov    0x4(%edx),%edx
  8006c7:	eb 22                	jmp    8006eb <getuint+0x38>
	else if (lflag)
  8006c9:	85 d2                	test   %edx,%edx
  8006cb:	74 10                	je     8006dd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8006cd:	8b 10                	mov    (%eax),%edx
  8006cf:	8d 4a 04             	lea    0x4(%edx),%ecx
  8006d2:	89 08                	mov    %ecx,(%eax)
  8006d4:	8b 02                	mov    (%edx),%eax
  8006d6:	ba 00 00 00 00       	mov    $0x0,%edx
  8006db:	eb 0e                	jmp    8006eb <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8006dd:	8b 10                	mov    (%eax),%edx
  8006df:	8d 4a 04             	lea    0x4(%edx),%ecx
  8006e2:	89 08                	mov    %ecx,(%eax)
  8006e4:	8b 02                	mov    (%edx),%eax
  8006e6:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8006eb:	5d                   	pop    %ebp
  8006ec:	c3                   	ret    

008006ed <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8006ed:	55                   	push   %ebp
  8006ee:	89 e5                	mov    %esp,%ebp
  8006f0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8006f3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8006f7:	8b 10                	mov    (%eax),%edx
  8006f9:	3b 50 04             	cmp    0x4(%eax),%edx
  8006fc:	73 0a                	jae    800708 <sprintputch+0x1b>
		*b->buf++ = ch;
  8006fe:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800701:	88 0a                	mov    %cl,(%edx)
  800703:	83 c2 01             	add    $0x1,%edx
  800706:	89 10                	mov    %edx,(%eax)
}
  800708:	5d                   	pop    %ebp
  800709:	c3                   	ret    

0080070a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80070a:	55                   	push   %ebp
  80070b:	89 e5                	mov    %esp,%ebp
  80070d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800710:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800713:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800717:	8b 45 10             	mov    0x10(%ebp),%eax
  80071a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80071e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800721:	89 44 24 04          	mov    %eax,0x4(%esp)
  800725:	8b 45 08             	mov    0x8(%ebp),%eax
  800728:	89 04 24             	mov    %eax,(%esp)
  80072b:	e8 02 00 00 00       	call   800732 <vprintfmt>
	va_end(ap);
}
  800730:	c9                   	leave  
  800731:	c3                   	ret    

00800732 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800732:	55                   	push   %ebp
  800733:	89 e5                	mov    %esp,%ebp
  800735:	57                   	push   %edi
  800736:	56                   	push   %esi
  800737:	53                   	push   %ebx
  800738:	83 ec 4c             	sub    $0x4c,%esp
  80073b:	8b 75 08             	mov    0x8(%ebp),%esi
  80073e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800741:	8b 7d 10             	mov    0x10(%ebp),%edi
  800744:	eb 11                	jmp    800757 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800746:	85 c0                	test   %eax,%eax
  800748:	0f 84 db 03 00 00    	je     800b29 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80074e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800752:	89 04 24             	mov    %eax,(%esp)
  800755:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800757:	0f b6 07             	movzbl (%edi),%eax
  80075a:	83 c7 01             	add    $0x1,%edi
  80075d:	83 f8 25             	cmp    $0x25,%eax
  800760:	75 e4                	jne    800746 <vprintfmt+0x14>
  800762:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800766:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80076d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800774:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80077b:	ba 00 00 00 00       	mov    $0x0,%edx
  800780:	eb 2b                	jmp    8007ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800782:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800785:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800789:	eb 22                	jmp    8007ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80078b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80078e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800792:	eb 19                	jmp    8007ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800794:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800797:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80079e:	eb 0d                	jmp    8007ad <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8007a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8007a3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007a6:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007ad:	0f b6 0f             	movzbl (%edi),%ecx
  8007b0:	8d 47 01             	lea    0x1(%edi),%eax
  8007b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8007b6:	0f b6 07             	movzbl (%edi),%eax
  8007b9:	83 e8 23             	sub    $0x23,%eax
  8007bc:	3c 55                	cmp    $0x55,%al
  8007be:	0f 87 40 03 00 00    	ja     800b04 <vprintfmt+0x3d2>
  8007c4:	0f b6 c0             	movzbl %al,%eax
  8007c7:	ff 24 85 a0 14 80 00 	jmp    *0x8014a0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8007ce:	83 e9 30             	sub    $0x30,%ecx
  8007d1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  8007d4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  8007d8:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8007db:	83 f9 09             	cmp    $0x9,%ecx
  8007de:	77 57                	ja     800837 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007e0:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007e3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8007e6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8007e9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  8007ec:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8007ef:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8007f3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8007f6:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8007f9:	83 f9 09             	cmp    $0x9,%ecx
  8007fc:	76 eb                	jbe    8007e9 <vprintfmt+0xb7>
  8007fe:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800801:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800804:	eb 34                	jmp    80083a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800806:	8b 45 14             	mov    0x14(%ebp),%eax
  800809:	8d 48 04             	lea    0x4(%eax),%ecx
  80080c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80080f:	8b 00                	mov    (%eax),%eax
  800811:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800814:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800817:	eb 21                	jmp    80083a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800819:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80081d:	0f 88 71 ff ff ff    	js     800794 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800823:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800826:	eb 85                	jmp    8007ad <vprintfmt+0x7b>
  800828:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80082b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800832:	e9 76 ff ff ff       	jmp    8007ad <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800837:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80083a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80083e:	0f 89 69 ff ff ff    	jns    8007ad <vprintfmt+0x7b>
  800844:	e9 57 ff ff ff       	jmp    8007a0 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800849:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80084c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80084f:	e9 59 ff ff ff       	jmp    8007ad <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800854:	8b 45 14             	mov    0x14(%ebp),%eax
  800857:	8d 50 04             	lea    0x4(%eax),%edx
  80085a:	89 55 14             	mov    %edx,0x14(%ebp)
  80085d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800861:	8b 00                	mov    (%eax),%eax
  800863:	89 04 24             	mov    %eax,(%esp)
  800866:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800868:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80086b:	e9 e7 fe ff ff       	jmp    800757 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800870:	8b 45 14             	mov    0x14(%ebp),%eax
  800873:	8d 50 04             	lea    0x4(%eax),%edx
  800876:	89 55 14             	mov    %edx,0x14(%ebp)
  800879:	8b 00                	mov    (%eax),%eax
  80087b:	89 c2                	mov    %eax,%edx
  80087d:	c1 fa 1f             	sar    $0x1f,%edx
  800880:	31 d0                	xor    %edx,%eax
  800882:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800884:	83 f8 08             	cmp    $0x8,%eax
  800887:	7f 0b                	jg     800894 <vprintfmt+0x162>
  800889:	8b 14 85 00 16 80 00 	mov    0x801600(,%eax,4),%edx
  800890:	85 d2                	test   %edx,%edx
  800892:	75 20                	jne    8008b4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800894:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800898:	c7 44 24 08 f7 13 80 	movl   $0x8013f7,0x8(%esp)
  80089f:	00 
  8008a0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8008a4:	89 34 24             	mov    %esi,(%esp)
  8008a7:	e8 5e fe ff ff       	call   80070a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8008af:	e9 a3 fe ff ff       	jmp    800757 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8008b4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8008b8:	c7 44 24 08 00 14 80 	movl   $0x801400,0x8(%esp)
  8008bf:	00 
  8008c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8008c4:	89 34 24             	mov    %esi,(%esp)
  8008c7:	e8 3e fe ff ff       	call   80070a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008cc:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8008cf:	e9 83 fe ff ff       	jmp    800757 <vprintfmt+0x25>
  8008d4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8008d7:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8008da:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8008dd:	8b 45 14             	mov    0x14(%ebp),%eax
  8008e0:	8d 50 04             	lea    0x4(%eax),%edx
  8008e3:	89 55 14             	mov    %edx,0x14(%ebp)
  8008e6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8008e8:	85 ff                	test   %edi,%edi
  8008ea:	b8 f0 13 80 00       	mov    $0x8013f0,%eax
  8008ef:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8008f2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8008f6:	74 06                	je     8008fe <vprintfmt+0x1cc>
  8008f8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8008fc:	7f 16                	jg     800914 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8008fe:	0f b6 17             	movzbl (%edi),%edx
  800901:	0f be c2             	movsbl %dl,%eax
  800904:	83 c7 01             	add    $0x1,%edi
  800907:	85 c0                	test   %eax,%eax
  800909:	0f 85 9f 00 00 00    	jne    8009ae <vprintfmt+0x27c>
  80090f:	e9 8b 00 00 00       	jmp    80099f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800914:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800918:	89 3c 24             	mov    %edi,(%esp)
  80091b:	e8 c2 02 00 00       	call   800be2 <strnlen>
  800920:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800923:	29 c2                	sub    %eax,%edx
  800925:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800928:	85 d2                	test   %edx,%edx
  80092a:	7e d2                	jle    8008fe <vprintfmt+0x1cc>
					putch(padc, putdat);
  80092c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800930:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800933:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800936:	89 d7                	mov    %edx,%edi
  800938:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80093c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80093f:	89 04 24             	mov    %eax,(%esp)
  800942:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800944:	83 ef 01             	sub    $0x1,%edi
  800947:	75 ef                	jne    800938 <vprintfmt+0x206>
  800949:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80094c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80094f:	eb ad                	jmp    8008fe <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800951:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800955:	74 20                	je     800977 <vprintfmt+0x245>
  800957:	0f be d2             	movsbl %dl,%edx
  80095a:	83 ea 20             	sub    $0x20,%edx
  80095d:	83 fa 5e             	cmp    $0x5e,%edx
  800960:	76 15                	jbe    800977 <vprintfmt+0x245>
					putch('?', putdat);
  800962:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800965:	89 54 24 04          	mov    %edx,0x4(%esp)
  800969:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800970:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800973:	ff d1                	call   *%ecx
  800975:	eb 0f                	jmp    800986 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800977:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80097a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80097e:	89 04 24             	mov    %eax,(%esp)
  800981:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800984:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800986:	83 eb 01             	sub    $0x1,%ebx
  800989:	0f b6 17             	movzbl (%edi),%edx
  80098c:	0f be c2             	movsbl %dl,%eax
  80098f:	83 c7 01             	add    $0x1,%edi
  800992:	85 c0                	test   %eax,%eax
  800994:	75 24                	jne    8009ba <vprintfmt+0x288>
  800996:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800999:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80099c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80099f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8009a2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8009a6:	0f 8e ab fd ff ff    	jle    800757 <vprintfmt+0x25>
  8009ac:	eb 20                	jmp    8009ce <vprintfmt+0x29c>
  8009ae:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8009b1:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8009b4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8009b7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8009ba:	85 f6                	test   %esi,%esi
  8009bc:	78 93                	js     800951 <vprintfmt+0x21f>
  8009be:	83 ee 01             	sub    $0x1,%esi
  8009c1:	79 8e                	jns    800951 <vprintfmt+0x21f>
  8009c3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8009c6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8009c9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8009cc:	eb d1                	jmp    80099f <vprintfmt+0x26d>
  8009ce:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8009d1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8009d5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8009dc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8009de:	83 ef 01             	sub    $0x1,%edi
  8009e1:	75 ee                	jne    8009d1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8009e3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8009e6:	e9 6c fd ff ff       	jmp    800757 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8009eb:	83 fa 01             	cmp    $0x1,%edx
  8009ee:	66 90                	xchg   %ax,%ax
  8009f0:	7e 16                	jle    800a08 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  8009f2:	8b 45 14             	mov    0x14(%ebp),%eax
  8009f5:	8d 50 08             	lea    0x8(%eax),%edx
  8009f8:	89 55 14             	mov    %edx,0x14(%ebp)
  8009fb:	8b 10                	mov    (%eax),%edx
  8009fd:	8b 48 04             	mov    0x4(%eax),%ecx
  800a00:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800a03:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800a06:	eb 32                	jmp    800a3a <vprintfmt+0x308>
	else if (lflag)
  800a08:	85 d2                	test   %edx,%edx
  800a0a:	74 18                	je     800a24 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  800a0c:	8b 45 14             	mov    0x14(%ebp),%eax
  800a0f:	8d 50 04             	lea    0x4(%eax),%edx
  800a12:	89 55 14             	mov    %edx,0x14(%ebp)
  800a15:	8b 00                	mov    (%eax),%eax
  800a17:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800a1a:	89 c1                	mov    %eax,%ecx
  800a1c:	c1 f9 1f             	sar    $0x1f,%ecx
  800a1f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800a22:	eb 16                	jmp    800a3a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800a24:	8b 45 14             	mov    0x14(%ebp),%eax
  800a27:	8d 50 04             	lea    0x4(%eax),%edx
  800a2a:	89 55 14             	mov    %edx,0x14(%ebp)
  800a2d:	8b 00                	mov    (%eax),%eax
  800a2f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800a32:	89 c7                	mov    %eax,%edi
  800a34:	c1 ff 1f             	sar    $0x1f,%edi
  800a37:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800a3a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800a3d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800a40:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800a45:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800a49:	79 7d                	jns    800ac8 <vprintfmt+0x396>
				putch('-', putdat);
  800a4b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a4f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800a56:	ff d6                	call   *%esi
				num = -(long long) num;
  800a58:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800a5b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800a5e:	f7 d8                	neg    %eax
  800a60:	83 d2 00             	adc    $0x0,%edx
  800a63:	f7 da                	neg    %edx
			}
			base = 10;
  800a65:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800a6a:	eb 5c                	jmp    800ac8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800a6c:	8d 45 14             	lea    0x14(%ebp),%eax
  800a6f:	e8 3f fc ff ff       	call   8006b3 <getuint>
			base = 10;
  800a74:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800a79:	eb 4d                	jmp    800ac8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800a7b:	8d 45 14             	lea    0x14(%ebp),%eax
  800a7e:	e8 30 fc ff ff       	call   8006b3 <getuint>
			base = 8;
  800a83:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800a88:	eb 3e                	jmp    800ac8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  800a8a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a8e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800a95:	ff d6                	call   *%esi
			putch('x', putdat);
  800a97:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a9b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800aa2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800aa4:	8b 45 14             	mov    0x14(%ebp),%eax
  800aa7:	8d 50 04             	lea    0x4(%eax),%edx
  800aaa:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800aad:	8b 00                	mov    (%eax),%eax
  800aaf:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800ab4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800ab9:	eb 0d                	jmp    800ac8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800abb:	8d 45 14             	lea    0x14(%ebp),%eax
  800abe:	e8 f0 fb ff ff       	call   8006b3 <getuint>
			base = 16;
  800ac3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800ac8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  800acc:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800ad0:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800ad3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ad7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800adb:	89 04 24             	mov    %eax,(%esp)
  800ade:	89 54 24 04          	mov    %edx,0x4(%esp)
  800ae2:	89 da                	mov    %ebx,%edx
  800ae4:	89 f0                	mov    %esi,%eax
  800ae6:	e8 d5 fa ff ff       	call   8005c0 <printnum>
			break;
  800aeb:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800aee:	e9 64 fc ff ff       	jmp    800757 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800af3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800af7:	89 0c 24             	mov    %ecx,(%esp)
  800afa:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800afc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800aff:	e9 53 fc ff ff       	jmp    800757 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800b04:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800b08:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800b0f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800b11:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800b15:	0f 84 3c fc ff ff    	je     800757 <vprintfmt+0x25>
  800b1b:	83 ef 01             	sub    $0x1,%edi
  800b1e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800b22:	75 f7                	jne    800b1b <vprintfmt+0x3e9>
  800b24:	e9 2e fc ff ff       	jmp    800757 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800b29:	83 c4 4c             	add    $0x4c,%esp
  800b2c:	5b                   	pop    %ebx
  800b2d:	5e                   	pop    %esi
  800b2e:	5f                   	pop    %edi
  800b2f:	5d                   	pop    %ebp
  800b30:	c3                   	ret    

00800b31 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800b31:	55                   	push   %ebp
  800b32:	89 e5                	mov    %esp,%ebp
  800b34:	83 ec 28             	sub    $0x28,%esp
  800b37:	8b 45 08             	mov    0x8(%ebp),%eax
  800b3a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800b3d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800b40:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800b44:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800b47:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800b4e:	85 d2                	test   %edx,%edx
  800b50:	7e 30                	jle    800b82 <vsnprintf+0x51>
  800b52:	85 c0                	test   %eax,%eax
  800b54:	74 2c                	je     800b82 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800b56:	8b 45 14             	mov    0x14(%ebp),%eax
  800b59:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b5d:	8b 45 10             	mov    0x10(%ebp),%eax
  800b60:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b64:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800b67:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b6b:	c7 04 24 ed 06 80 00 	movl   $0x8006ed,(%esp)
  800b72:	e8 bb fb ff ff       	call   800732 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800b77:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800b7a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800b7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800b80:	eb 05                	jmp    800b87 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800b82:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800b87:	c9                   	leave  
  800b88:	c3                   	ret    

00800b89 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800b89:	55                   	push   %ebp
  800b8a:	89 e5                	mov    %esp,%ebp
  800b8c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800b8f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800b92:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b96:	8b 45 10             	mov    0x10(%ebp),%eax
  800b99:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b9d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800ba0:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ba4:	8b 45 08             	mov    0x8(%ebp),%eax
  800ba7:	89 04 24             	mov    %eax,(%esp)
  800baa:	e8 82 ff ff ff       	call   800b31 <vsnprintf>
	va_end(ap);

	return rc;
}
  800baf:	c9                   	leave  
  800bb0:	c3                   	ret    
  800bb1:	66 90                	xchg   %ax,%ax
  800bb3:	66 90                	xchg   %ax,%ax
  800bb5:	66 90                	xchg   %ax,%ax
  800bb7:	66 90                	xchg   %ax,%ax
  800bb9:	66 90                	xchg   %ax,%ax
  800bbb:	66 90                	xchg   %ax,%ax
  800bbd:	66 90                	xchg   %ax,%ax
  800bbf:	90                   	nop

00800bc0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800bc0:	55                   	push   %ebp
  800bc1:	89 e5                	mov    %esp,%ebp
  800bc3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800bc6:	80 3a 00             	cmpb   $0x0,(%edx)
  800bc9:	74 10                	je     800bdb <strlen+0x1b>
  800bcb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800bd0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800bd3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800bd7:	75 f7                	jne    800bd0 <strlen+0x10>
  800bd9:	eb 05                	jmp    800be0 <strlen+0x20>
  800bdb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800be0:	5d                   	pop    %ebp
  800be1:	c3                   	ret    

00800be2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800be2:	55                   	push   %ebp
  800be3:	89 e5                	mov    %esp,%ebp
  800be5:	53                   	push   %ebx
  800be6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800be9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800bec:	85 c9                	test   %ecx,%ecx
  800bee:	74 1c                	je     800c0c <strnlen+0x2a>
  800bf0:	80 3b 00             	cmpb   $0x0,(%ebx)
  800bf3:	74 1e                	je     800c13 <strnlen+0x31>
  800bf5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  800bfa:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800bfc:	39 ca                	cmp    %ecx,%edx
  800bfe:	74 18                	je     800c18 <strnlen+0x36>
  800c00:	83 c2 01             	add    $0x1,%edx
  800c03:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800c08:	75 f0                	jne    800bfa <strnlen+0x18>
  800c0a:	eb 0c                	jmp    800c18 <strnlen+0x36>
  800c0c:	b8 00 00 00 00       	mov    $0x0,%eax
  800c11:	eb 05                	jmp    800c18 <strnlen+0x36>
  800c13:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800c18:	5b                   	pop    %ebx
  800c19:	5d                   	pop    %ebp
  800c1a:	c3                   	ret    

00800c1b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800c1b:	55                   	push   %ebp
  800c1c:	89 e5                	mov    %esp,%ebp
  800c1e:	53                   	push   %ebx
  800c1f:	8b 45 08             	mov    0x8(%ebp),%eax
  800c22:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800c25:	89 c2                	mov    %eax,%edx
  800c27:	0f b6 19             	movzbl (%ecx),%ebx
  800c2a:	88 1a                	mov    %bl,(%edx)
  800c2c:	83 c2 01             	add    $0x1,%edx
  800c2f:	83 c1 01             	add    $0x1,%ecx
  800c32:	84 db                	test   %bl,%bl
  800c34:	75 f1                	jne    800c27 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800c36:	5b                   	pop    %ebx
  800c37:	5d                   	pop    %ebp
  800c38:	c3                   	ret    

00800c39 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800c39:	55                   	push   %ebp
  800c3a:	89 e5                	mov    %esp,%ebp
  800c3c:	53                   	push   %ebx
  800c3d:	83 ec 08             	sub    $0x8,%esp
  800c40:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800c43:	89 1c 24             	mov    %ebx,(%esp)
  800c46:	e8 75 ff ff ff       	call   800bc0 <strlen>
	strcpy(dst + len, src);
  800c4b:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c4e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800c52:	01 d8                	add    %ebx,%eax
  800c54:	89 04 24             	mov    %eax,(%esp)
  800c57:	e8 bf ff ff ff       	call   800c1b <strcpy>
	return dst;
}
  800c5c:	89 d8                	mov    %ebx,%eax
  800c5e:	83 c4 08             	add    $0x8,%esp
  800c61:	5b                   	pop    %ebx
  800c62:	5d                   	pop    %ebp
  800c63:	c3                   	ret    

00800c64 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800c64:	55                   	push   %ebp
  800c65:	89 e5                	mov    %esp,%ebp
  800c67:	56                   	push   %esi
  800c68:	53                   	push   %ebx
  800c69:	8b 75 08             	mov    0x8(%ebp),%esi
  800c6c:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c6f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800c72:	85 db                	test   %ebx,%ebx
  800c74:	74 16                	je     800c8c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800c76:	01 f3                	add    %esi,%ebx
  800c78:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  800c7a:	0f b6 02             	movzbl (%edx),%eax
  800c7d:	88 01                	mov    %al,(%ecx)
  800c7f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800c82:	80 3a 01             	cmpb   $0x1,(%edx)
  800c85:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800c88:	39 d9                	cmp    %ebx,%ecx
  800c8a:	75 ee                	jne    800c7a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800c8c:	89 f0                	mov    %esi,%eax
  800c8e:	5b                   	pop    %ebx
  800c8f:	5e                   	pop    %esi
  800c90:	5d                   	pop    %ebp
  800c91:	c3                   	ret    

00800c92 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800c92:	55                   	push   %ebp
  800c93:	89 e5                	mov    %esp,%ebp
  800c95:	57                   	push   %edi
  800c96:	56                   	push   %esi
  800c97:	53                   	push   %ebx
  800c98:	8b 7d 08             	mov    0x8(%ebp),%edi
  800c9b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c9e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800ca1:	89 f8                	mov    %edi,%eax
  800ca3:	85 f6                	test   %esi,%esi
  800ca5:	74 33                	je     800cda <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800ca7:	83 fe 01             	cmp    $0x1,%esi
  800caa:	74 25                	je     800cd1 <strlcpy+0x3f>
  800cac:	0f b6 0b             	movzbl (%ebx),%ecx
  800caf:	84 c9                	test   %cl,%cl
  800cb1:	74 22                	je     800cd5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800cb3:	83 ee 02             	sub    $0x2,%esi
  800cb6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800cbb:	88 08                	mov    %cl,(%eax)
  800cbd:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800cc0:	39 f2                	cmp    %esi,%edx
  800cc2:	74 13                	je     800cd7 <strlcpy+0x45>
  800cc4:	83 c2 01             	add    $0x1,%edx
  800cc7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  800ccb:	84 c9                	test   %cl,%cl
  800ccd:	75 ec                	jne    800cbb <strlcpy+0x29>
  800ccf:	eb 06                	jmp    800cd7 <strlcpy+0x45>
  800cd1:	89 f8                	mov    %edi,%eax
  800cd3:	eb 02                	jmp    800cd7 <strlcpy+0x45>
  800cd5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800cd7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800cda:	29 f8                	sub    %edi,%eax
}
  800cdc:	5b                   	pop    %ebx
  800cdd:	5e                   	pop    %esi
  800cde:	5f                   	pop    %edi
  800cdf:	5d                   	pop    %ebp
  800ce0:	c3                   	ret    

00800ce1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800ce1:	55                   	push   %ebp
  800ce2:	89 e5                	mov    %esp,%ebp
  800ce4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ce7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800cea:	0f b6 01             	movzbl (%ecx),%eax
  800ced:	84 c0                	test   %al,%al
  800cef:	74 15                	je     800d06 <strcmp+0x25>
  800cf1:	3a 02                	cmp    (%edx),%al
  800cf3:	75 11                	jne    800d06 <strcmp+0x25>
		p++, q++;
  800cf5:	83 c1 01             	add    $0x1,%ecx
  800cf8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800cfb:	0f b6 01             	movzbl (%ecx),%eax
  800cfe:	84 c0                	test   %al,%al
  800d00:	74 04                	je     800d06 <strcmp+0x25>
  800d02:	3a 02                	cmp    (%edx),%al
  800d04:	74 ef                	je     800cf5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800d06:	0f b6 c0             	movzbl %al,%eax
  800d09:	0f b6 12             	movzbl (%edx),%edx
  800d0c:	29 d0                	sub    %edx,%eax
}
  800d0e:	5d                   	pop    %ebp
  800d0f:	c3                   	ret    

00800d10 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800d10:	55                   	push   %ebp
  800d11:	89 e5                	mov    %esp,%ebp
  800d13:	56                   	push   %esi
  800d14:	53                   	push   %ebx
  800d15:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800d18:	8b 55 0c             	mov    0xc(%ebp),%edx
  800d1b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800d1e:	85 f6                	test   %esi,%esi
  800d20:	74 29                	je     800d4b <strncmp+0x3b>
  800d22:	0f b6 03             	movzbl (%ebx),%eax
  800d25:	84 c0                	test   %al,%al
  800d27:	74 30                	je     800d59 <strncmp+0x49>
  800d29:	3a 02                	cmp    (%edx),%al
  800d2b:	75 2c                	jne    800d59 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800d2d:	8d 43 01             	lea    0x1(%ebx),%eax
  800d30:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800d32:	89 c3                	mov    %eax,%ebx
  800d34:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800d37:	39 f0                	cmp    %esi,%eax
  800d39:	74 17                	je     800d52 <strncmp+0x42>
  800d3b:	0f b6 08             	movzbl (%eax),%ecx
  800d3e:	84 c9                	test   %cl,%cl
  800d40:	74 17                	je     800d59 <strncmp+0x49>
  800d42:	83 c0 01             	add    $0x1,%eax
  800d45:	3a 0a                	cmp    (%edx),%cl
  800d47:	74 e9                	je     800d32 <strncmp+0x22>
  800d49:	eb 0e                	jmp    800d59 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800d4b:	b8 00 00 00 00       	mov    $0x0,%eax
  800d50:	eb 0f                	jmp    800d61 <strncmp+0x51>
  800d52:	b8 00 00 00 00       	mov    $0x0,%eax
  800d57:	eb 08                	jmp    800d61 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800d59:	0f b6 03             	movzbl (%ebx),%eax
  800d5c:	0f b6 12             	movzbl (%edx),%edx
  800d5f:	29 d0                	sub    %edx,%eax
}
  800d61:	5b                   	pop    %ebx
  800d62:	5e                   	pop    %esi
  800d63:	5d                   	pop    %ebp
  800d64:	c3                   	ret    

00800d65 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800d65:	55                   	push   %ebp
  800d66:	89 e5                	mov    %esp,%ebp
  800d68:	53                   	push   %ebx
  800d69:	8b 45 08             	mov    0x8(%ebp),%eax
  800d6c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800d6f:	0f b6 18             	movzbl (%eax),%ebx
  800d72:	84 db                	test   %bl,%bl
  800d74:	74 1d                	je     800d93 <strchr+0x2e>
  800d76:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800d78:	38 d3                	cmp    %dl,%bl
  800d7a:	75 06                	jne    800d82 <strchr+0x1d>
  800d7c:	eb 1a                	jmp    800d98 <strchr+0x33>
  800d7e:	38 ca                	cmp    %cl,%dl
  800d80:	74 16                	je     800d98 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800d82:	83 c0 01             	add    $0x1,%eax
  800d85:	0f b6 10             	movzbl (%eax),%edx
  800d88:	84 d2                	test   %dl,%dl
  800d8a:	75 f2                	jne    800d7e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800d8c:	b8 00 00 00 00       	mov    $0x0,%eax
  800d91:	eb 05                	jmp    800d98 <strchr+0x33>
  800d93:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800d98:	5b                   	pop    %ebx
  800d99:	5d                   	pop    %ebp
  800d9a:	c3                   	ret    

00800d9b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800d9b:	55                   	push   %ebp
  800d9c:	89 e5                	mov    %esp,%ebp
  800d9e:	53                   	push   %ebx
  800d9f:	8b 45 08             	mov    0x8(%ebp),%eax
  800da2:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800da5:	0f b6 18             	movzbl (%eax),%ebx
  800da8:	84 db                	test   %bl,%bl
  800daa:	74 16                	je     800dc2 <strfind+0x27>
  800dac:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800dae:	38 d3                	cmp    %dl,%bl
  800db0:	75 06                	jne    800db8 <strfind+0x1d>
  800db2:	eb 0e                	jmp    800dc2 <strfind+0x27>
  800db4:	38 ca                	cmp    %cl,%dl
  800db6:	74 0a                	je     800dc2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800db8:	83 c0 01             	add    $0x1,%eax
  800dbb:	0f b6 10             	movzbl (%eax),%edx
  800dbe:	84 d2                	test   %dl,%dl
  800dc0:	75 f2                	jne    800db4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800dc2:	5b                   	pop    %ebx
  800dc3:	5d                   	pop    %ebp
  800dc4:	c3                   	ret    

00800dc5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800dc5:	55                   	push   %ebp
  800dc6:	89 e5                	mov    %esp,%ebp
  800dc8:	83 ec 0c             	sub    $0xc,%esp
  800dcb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800dce:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800dd1:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800dd4:	8b 7d 08             	mov    0x8(%ebp),%edi
  800dd7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800dda:	85 c9                	test   %ecx,%ecx
  800ddc:	74 36                	je     800e14 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800dde:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800de4:	75 28                	jne    800e0e <memset+0x49>
  800de6:	f6 c1 03             	test   $0x3,%cl
  800de9:	75 23                	jne    800e0e <memset+0x49>
		c &= 0xFF;
  800deb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800def:	89 d3                	mov    %edx,%ebx
  800df1:	c1 e3 08             	shl    $0x8,%ebx
  800df4:	89 d6                	mov    %edx,%esi
  800df6:	c1 e6 18             	shl    $0x18,%esi
  800df9:	89 d0                	mov    %edx,%eax
  800dfb:	c1 e0 10             	shl    $0x10,%eax
  800dfe:	09 f0                	or     %esi,%eax
  800e00:	09 c2                	or     %eax,%edx
  800e02:	89 d0                	mov    %edx,%eax
  800e04:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800e06:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800e09:	fc                   	cld    
  800e0a:	f3 ab                	rep stos %eax,%es:(%edi)
  800e0c:	eb 06                	jmp    800e14 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800e0e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e11:	fc                   	cld    
  800e12:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800e14:	89 f8                	mov    %edi,%eax
  800e16:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e19:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e1c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e1f:	89 ec                	mov    %ebp,%esp
  800e21:	5d                   	pop    %ebp
  800e22:	c3                   	ret    

00800e23 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800e23:	55                   	push   %ebp
  800e24:	89 e5                	mov    %esp,%ebp
  800e26:	83 ec 08             	sub    $0x8,%esp
  800e29:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e2c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800e2f:	8b 45 08             	mov    0x8(%ebp),%eax
  800e32:	8b 75 0c             	mov    0xc(%ebp),%esi
  800e35:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800e38:	39 c6                	cmp    %eax,%esi
  800e3a:	73 36                	jae    800e72 <memmove+0x4f>
  800e3c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800e3f:	39 d0                	cmp    %edx,%eax
  800e41:	73 2f                	jae    800e72 <memmove+0x4f>
		s += n;
		d += n;
  800e43:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e46:	f6 c2 03             	test   $0x3,%dl
  800e49:	75 1b                	jne    800e66 <memmove+0x43>
  800e4b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800e51:	75 13                	jne    800e66 <memmove+0x43>
  800e53:	f6 c1 03             	test   $0x3,%cl
  800e56:	75 0e                	jne    800e66 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800e58:	83 ef 04             	sub    $0x4,%edi
  800e5b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800e5e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800e61:	fd                   	std    
  800e62:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e64:	eb 09                	jmp    800e6f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800e66:	83 ef 01             	sub    $0x1,%edi
  800e69:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800e6c:	fd                   	std    
  800e6d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800e6f:	fc                   	cld    
  800e70:	eb 20                	jmp    800e92 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e72:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800e78:	75 13                	jne    800e8d <memmove+0x6a>
  800e7a:	a8 03                	test   $0x3,%al
  800e7c:	75 0f                	jne    800e8d <memmove+0x6a>
  800e7e:	f6 c1 03             	test   $0x3,%cl
  800e81:	75 0a                	jne    800e8d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800e83:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800e86:	89 c7                	mov    %eax,%edi
  800e88:	fc                   	cld    
  800e89:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e8b:	eb 05                	jmp    800e92 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800e8d:	89 c7                	mov    %eax,%edi
  800e8f:	fc                   	cld    
  800e90:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800e92:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e95:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e98:	89 ec                	mov    %ebp,%esp
  800e9a:	5d                   	pop    %ebp
  800e9b:	c3                   	ret    

00800e9c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800e9c:	55                   	push   %ebp
  800e9d:	89 e5                	mov    %esp,%ebp
  800e9f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ea2:	8b 45 10             	mov    0x10(%ebp),%eax
  800ea5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ea9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800eac:	89 44 24 04          	mov    %eax,0x4(%esp)
  800eb0:	8b 45 08             	mov    0x8(%ebp),%eax
  800eb3:	89 04 24             	mov    %eax,(%esp)
  800eb6:	e8 68 ff ff ff       	call   800e23 <memmove>
}
  800ebb:	c9                   	leave  
  800ebc:	c3                   	ret    

00800ebd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800ebd:	55                   	push   %ebp
  800ebe:	89 e5                	mov    %esp,%ebp
  800ec0:	57                   	push   %edi
  800ec1:	56                   	push   %esi
  800ec2:	53                   	push   %ebx
  800ec3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800ec6:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ec9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ecc:	8d 78 ff             	lea    -0x1(%eax),%edi
  800ecf:	85 c0                	test   %eax,%eax
  800ed1:	74 36                	je     800f09 <memcmp+0x4c>
		if (*s1 != *s2)
  800ed3:	0f b6 03             	movzbl (%ebx),%eax
  800ed6:	0f b6 0e             	movzbl (%esi),%ecx
  800ed9:	38 c8                	cmp    %cl,%al
  800edb:	75 17                	jne    800ef4 <memcmp+0x37>
  800edd:	ba 00 00 00 00       	mov    $0x0,%edx
  800ee2:	eb 1a                	jmp    800efe <memcmp+0x41>
  800ee4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800ee9:	83 c2 01             	add    $0x1,%edx
  800eec:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800ef0:	38 c8                	cmp    %cl,%al
  800ef2:	74 0a                	je     800efe <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800ef4:	0f b6 c0             	movzbl %al,%eax
  800ef7:	0f b6 c9             	movzbl %cl,%ecx
  800efa:	29 c8                	sub    %ecx,%eax
  800efc:	eb 10                	jmp    800f0e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800efe:	39 fa                	cmp    %edi,%edx
  800f00:	75 e2                	jne    800ee4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800f02:	b8 00 00 00 00       	mov    $0x0,%eax
  800f07:	eb 05                	jmp    800f0e <memcmp+0x51>
  800f09:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800f0e:	5b                   	pop    %ebx
  800f0f:	5e                   	pop    %esi
  800f10:	5f                   	pop    %edi
  800f11:	5d                   	pop    %ebp
  800f12:	c3                   	ret    

00800f13 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800f13:	55                   	push   %ebp
  800f14:	89 e5                	mov    %esp,%ebp
  800f16:	53                   	push   %ebx
  800f17:	8b 45 08             	mov    0x8(%ebp),%eax
  800f1a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800f1d:	89 c2                	mov    %eax,%edx
  800f1f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800f22:	39 d0                	cmp    %edx,%eax
  800f24:	73 13                	jae    800f39 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800f26:	89 d9                	mov    %ebx,%ecx
  800f28:	38 18                	cmp    %bl,(%eax)
  800f2a:	75 06                	jne    800f32 <memfind+0x1f>
  800f2c:	eb 0b                	jmp    800f39 <memfind+0x26>
  800f2e:	38 08                	cmp    %cl,(%eax)
  800f30:	74 07                	je     800f39 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800f32:	83 c0 01             	add    $0x1,%eax
  800f35:	39 d0                	cmp    %edx,%eax
  800f37:	75 f5                	jne    800f2e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800f39:	5b                   	pop    %ebx
  800f3a:	5d                   	pop    %ebp
  800f3b:	c3                   	ret    

00800f3c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800f3c:	55                   	push   %ebp
  800f3d:	89 e5                	mov    %esp,%ebp
  800f3f:	57                   	push   %edi
  800f40:	56                   	push   %esi
  800f41:	53                   	push   %ebx
  800f42:	83 ec 04             	sub    $0x4,%esp
  800f45:	8b 55 08             	mov    0x8(%ebp),%edx
  800f48:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f4b:	0f b6 02             	movzbl (%edx),%eax
  800f4e:	3c 09                	cmp    $0x9,%al
  800f50:	74 04                	je     800f56 <strtol+0x1a>
  800f52:	3c 20                	cmp    $0x20,%al
  800f54:	75 0e                	jne    800f64 <strtol+0x28>
		s++;
  800f56:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f59:	0f b6 02             	movzbl (%edx),%eax
  800f5c:	3c 09                	cmp    $0x9,%al
  800f5e:	74 f6                	je     800f56 <strtol+0x1a>
  800f60:	3c 20                	cmp    $0x20,%al
  800f62:	74 f2                	je     800f56 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800f64:	3c 2b                	cmp    $0x2b,%al
  800f66:	75 0a                	jne    800f72 <strtol+0x36>
		s++;
  800f68:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800f6b:	bf 00 00 00 00       	mov    $0x0,%edi
  800f70:	eb 10                	jmp    800f82 <strtol+0x46>
  800f72:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800f77:	3c 2d                	cmp    $0x2d,%al
  800f79:	75 07                	jne    800f82 <strtol+0x46>
		s++, neg = 1;
  800f7b:	83 c2 01             	add    $0x1,%edx
  800f7e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800f82:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800f88:	75 15                	jne    800f9f <strtol+0x63>
  800f8a:	80 3a 30             	cmpb   $0x30,(%edx)
  800f8d:	75 10                	jne    800f9f <strtol+0x63>
  800f8f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800f93:	75 0a                	jne    800f9f <strtol+0x63>
		s += 2, base = 16;
  800f95:	83 c2 02             	add    $0x2,%edx
  800f98:	bb 10 00 00 00       	mov    $0x10,%ebx
  800f9d:	eb 10                	jmp    800faf <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800f9f:	85 db                	test   %ebx,%ebx
  800fa1:	75 0c                	jne    800faf <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800fa3:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800fa5:	80 3a 30             	cmpb   $0x30,(%edx)
  800fa8:	75 05                	jne    800faf <strtol+0x73>
		s++, base = 8;
  800faa:	83 c2 01             	add    $0x1,%edx
  800fad:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800faf:	b8 00 00 00 00       	mov    $0x0,%eax
  800fb4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800fb7:	0f b6 0a             	movzbl (%edx),%ecx
  800fba:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800fbd:	89 f3                	mov    %esi,%ebx
  800fbf:	80 fb 09             	cmp    $0x9,%bl
  800fc2:	77 08                	ja     800fcc <strtol+0x90>
			dig = *s - '0';
  800fc4:	0f be c9             	movsbl %cl,%ecx
  800fc7:	83 e9 30             	sub    $0x30,%ecx
  800fca:	eb 22                	jmp    800fee <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800fcc:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800fcf:	89 f3                	mov    %esi,%ebx
  800fd1:	80 fb 19             	cmp    $0x19,%bl
  800fd4:	77 08                	ja     800fde <strtol+0xa2>
			dig = *s - 'a' + 10;
  800fd6:	0f be c9             	movsbl %cl,%ecx
  800fd9:	83 e9 57             	sub    $0x57,%ecx
  800fdc:	eb 10                	jmp    800fee <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800fde:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800fe1:	89 f3                	mov    %esi,%ebx
  800fe3:	80 fb 19             	cmp    $0x19,%bl
  800fe6:	77 16                	ja     800ffe <strtol+0xc2>
			dig = *s - 'A' + 10;
  800fe8:	0f be c9             	movsbl %cl,%ecx
  800feb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800fee:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800ff1:	7d 0f                	jge    801002 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800ff3:	83 c2 01             	add    $0x1,%edx
  800ff6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800ffa:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800ffc:	eb b9                	jmp    800fb7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800ffe:	89 c1                	mov    %eax,%ecx
  801000:	eb 02                	jmp    801004 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  801002:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  801004:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  801008:	74 05                	je     80100f <strtol+0xd3>
		*endptr = (char *) s;
  80100a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80100d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  80100f:	89 ca                	mov    %ecx,%edx
  801011:	f7 da                	neg    %edx
  801013:	85 ff                	test   %edi,%edi
  801015:	0f 45 c2             	cmovne %edx,%eax
}
  801018:	83 c4 04             	add    $0x4,%esp
  80101b:	5b                   	pop    %ebx
  80101c:	5e                   	pop    %esi
  80101d:	5f                   	pop    %edi
  80101e:	5d                   	pop    %ebp
  80101f:	c3                   	ret    

00801020 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801020:	55                   	push   %ebp
  801021:	89 e5                	mov    %esp,%ebp
  801023:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  801026:	83 3d 0c 20 80 00 00 	cmpl   $0x0,0x80200c
  80102d:	75 54                	jne    801083 <set_pgfault_handler+0x63>
		// First time through!
		// LAB 4: Your code here.
		if((r = sys_page_alloc(0, (void *)(UXSTACKTOP - PGSIZE), PTE_U|PTE_P|PTE_W)))
  80102f:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801036:	00 
  801037:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  80103e:	ee 
  80103f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801046:	e8 b5 f1 ff ff       	call   800200 <sys_page_alloc>
  80104b:	85 c0                	test   %eax,%eax
  80104d:	74 20                	je     80106f <set_pgfault_handler+0x4f>
			panic("Exception stack alloc failed: %e!\n", r);
  80104f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801053:	c7 44 24 08 24 16 80 	movl   $0x801624,0x8(%esp)
  80105a:	00 
  80105b:	c7 44 24 04 21 00 00 	movl   $0x21,0x4(%esp)
  801062:	00 
  801063:	c7 04 24 48 16 80 00 	movl   $0x801648,(%esp)
  80106a:	e8 21 f4 ff ff       	call   800490 <_panic>
		sys_env_set_pgfault_upcall(0, _pgfault_upcall);
  80106f:	c7 44 24 04 68 04 80 	movl   $0x800468,0x4(%esp)
  801076:	00 
  801077:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80107e:	e8 f6 f2 ff ff       	call   800379 <sys_env_set_pgfault_upcall>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  801083:	8b 45 08             	mov    0x8(%ebp),%eax
  801086:	a3 0c 20 80 00       	mov    %eax,0x80200c
}
  80108b:	c9                   	leave  
  80108c:	c3                   	ret    
  80108d:	66 90                	xchg   %ax,%ax
  80108f:	90                   	nop

00801090 <__udivdi3>:
  801090:	83 ec 1c             	sub    $0x1c,%esp
  801093:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  801097:	89 7c 24 14          	mov    %edi,0x14(%esp)
  80109b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  80109f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  8010a3:	8b 7c 24 20          	mov    0x20(%esp),%edi
  8010a7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  8010ab:	85 c0                	test   %eax,%eax
  8010ad:	89 74 24 10          	mov    %esi,0x10(%esp)
  8010b1:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8010b5:	89 ea                	mov    %ebp,%edx
  8010b7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8010bb:	75 33                	jne    8010f0 <__udivdi3+0x60>
  8010bd:	39 e9                	cmp    %ebp,%ecx
  8010bf:	77 6f                	ja     801130 <__udivdi3+0xa0>
  8010c1:	85 c9                	test   %ecx,%ecx
  8010c3:	89 ce                	mov    %ecx,%esi
  8010c5:	75 0b                	jne    8010d2 <__udivdi3+0x42>
  8010c7:	b8 01 00 00 00       	mov    $0x1,%eax
  8010cc:	31 d2                	xor    %edx,%edx
  8010ce:	f7 f1                	div    %ecx
  8010d0:	89 c6                	mov    %eax,%esi
  8010d2:	31 d2                	xor    %edx,%edx
  8010d4:	89 e8                	mov    %ebp,%eax
  8010d6:	f7 f6                	div    %esi
  8010d8:	89 c5                	mov    %eax,%ebp
  8010da:	89 f8                	mov    %edi,%eax
  8010dc:	f7 f6                	div    %esi
  8010de:	89 ea                	mov    %ebp,%edx
  8010e0:	8b 74 24 10          	mov    0x10(%esp),%esi
  8010e4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8010e8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8010ec:	83 c4 1c             	add    $0x1c,%esp
  8010ef:	c3                   	ret    
  8010f0:	39 e8                	cmp    %ebp,%eax
  8010f2:	77 24                	ja     801118 <__udivdi3+0x88>
  8010f4:	0f bd c8             	bsr    %eax,%ecx
  8010f7:	83 f1 1f             	xor    $0x1f,%ecx
  8010fa:	89 0c 24             	mov    %ecx,(%esp)
  8010fd:	75 49                	jne    801148 <__udivdi3+0xb8>
  8010ff:	8b 74 24 08          	mov    0x8(%esp),%esi
  801103:	39 74 24 04          	cmp    %esi,0x4(%esp)
  801107:	0f 86 ab 00 00 00    	jbe    8011b8 <__udivdi3+0x128>
  80110d:	39 e8                	cmp    %ebp,%eax
  80110f:	0f 82 a3 00 00 00    	jb     8011b8 <__udivdi3+0x128>
  801115:	8d 76 00             	lea    0x0(%esi),%esi
  801118:	31 d2                	xor    %edx,%edx
  80111a:	31 c0                	xor    %eax,%eax
  80111c:	8b 74 24 10          	mov    0x10(%esp),%esi
  801120:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801124:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801128:	83 c4 1c             	add    $0x1c,%esp
  80112b:	c3                   	ret    
  80112c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801130:	89 f8                	mov    %edi,%eax
  801132:	f7 f1                	div    %ecx
  801134:	31 d2                	xor    %edx,%edx
  801136:	8b 74 24 10          	mov    0x10(%esp),%esi
  80113a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  80113e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801142:	83 c4 1c             	add    $0x1c,%esp
  801145:	c3                   	ret    
  801146:	66 90                	xchg   %ax,%ax
  801148:	0f b6 0c 24          	movzbl (%esp),%ecx
  80114c:	89 c6                	mov    %eax,%esi
  80114e:	b8 20 00 00 00       	mov    $0x20,%eax
  801153:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  801157:	2b 04 24             	sub    (%esp),%eax
  80115a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  80115e:	d3 e6                	shl    %cl,%esi
  801160:	89 c1                	mov    %eax,%ecx
  801162:	d3 ed                	shr    %cl,%ebp
  801164:	0f b6 0c 24          	movzbl (%esp),%ecx
  801168:	09 f5                	or     %esi,%ebp
  80116a:	8b 74 24 04          	mov    0x4(%esp),%esi
  80116e:	d3 e6                	shl    %cl,%esi
  801170:	89 c1                	mov    %eax,%ecx
  801172:	89 74 24 04          	mov    %esi,0x4(%esp)
  801176:	89 d6                	mov    %edx,%esi
  801178:	d3 ee                	shr    %cl,%esi
  80117a:	0f b6 0c 24          	movzbl (%esp),%ecx
  80117e:	d3 e2                	shl    %cl,%edx
  801180:	89 c1                	mov    %eax,%ecx
  801182:	d3 ef                	shr    %cl,%edi
  801184:	09 d7                	or     %edx,%edi
  801186:	89 f2                	mov    %esi,%edx
  801188:	89 f8                	mov    %edi,%eax
  80118a:	f7 f5                	div    %ebp
  80118c:	89 d6                	mov    %edx,%esi
  80118e:	89 c7                	mov    %eax,%edi
  801190:	f7 64 24 04          	mull   0x4(%esp)
  801194:	39 d6                	cmp    %edx,%esi
  801196:	72 30                	jb     8011c8 <__udivdi3+0x138>
  801198:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  80119c:	0f b6 0c 24          	movzbl (%esp),%ecx
  8011a0:	d3 e5                	shl    %cl,%ebp
  8011a2:	39 c5                	cmp    %eax,%ebp
  8011a4:	73 04                	jae    8011aa <__udivdi3+0x11a>
  8011a6:	39 d6                	cmp    %edx,%esi
  8011a8:	74 1e                	je     8011c8 <__udivdi3+0x138>
  8011aa:	89 f8                	mov    %edi,%eax
  8011ac:	31 d2                	xor    %edx,%edx
  8011ae:	e9 69 ff ff ff       	jmp    80111c <__udivdi3+0x8c>
  8011b3:	90                   	nop
  8011b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8011b8:	31 d2                	xor    %edx,%edx
  8011ba:	b8 01 00 00 00       	mov    $0x1,%eax
  8011bf:	e9 58 ff ff ff       	jmp    80111c <__udivdi3+0x8c>
  8011c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8011c8:	8d 47 ff             	lea    -0x1(%edi),%eax
  8011cb:	31 d2                	xor    %edx,%edx
  8011cd:	8b 74 24 10          	mov    0x10(%esp),%esi
  8011d1:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8011d5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8011d9:	83 c4 1c             	add    $0x1c,%esp
  8011dc:	c3                   	ret    
  8011dd:	66 90                	xchg   %ax,%ax
  8011df:	90                   	nop

008011e0 <__umoddi3>:
  8011e0:	83 ec 2c             	sub    $0x2c,%esp
  8011e3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  8011e7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  8011eb:	89 74 24 20          	mov    %esi,0x20(%esp)
  8011ef:	8b 74 24 38          	mov    0x38(%esp),%esi
  8011f3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  8011f7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  8011fb:	85 c0                	test   %eax,%eax
  8011fd:	89 c2                	mov    %eax,%edx
  8011ff:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  801203:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  801207:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80120b:	89 74 24 10          	mov    %esi,0x10(%esp)
  80120f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  801213:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801217:	75 1f                	jne    801238 <__umoddi3+0x58>
  801219:	39 fe                	cmp    %edi,%esi
  80121b:	76 63                	jbe    801280 <__umoddi3+0xa0>
  80121d:	89 c8                	mov    %ecx,%eax
  80121f:	89 fa                	mov    %edi,%edx
  801221:	f7 f6                	div    %esi
  801223:	89 d0                	mov    %edx,%eax
  801225:	31 d2                	xor    %edx,%edx
  801227:	8b 74 24 20          	mov    0x20(%esp),%esi
  80122b:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80122f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801233:	83 c4 2c             	add    $0x2c,%esp
  801236:	c3                   	ret    
  801237:	90                   	nop
  801238:	39 f8                	cmp    %edi,%eax
  80123a:	77 64                	ja     8012a0 <__umoddi3+0xc0>
  80123c:	0f bd e8             	bsr    %eax,%ebp
  80123f:	83 f5 1f             	xor    $0x1f,%ebp
  801242:	75 74                	jne    8012b8 <__umoddi3+0xd8>
  801244:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801248:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  80124c:	0f 87 0e 01 00 00    	ja     801360 <__umoddi3+0x180>
  801252:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  801256:	29 f1                	sub    %esi,%ecx
  801258:	19 c7                	sbb    %eax,%edi
  80125a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  80125e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801262:	8b 44 24 14          	mov    0x14(%esp),%eax
  801266:	8b 54 24 18          	mov    0x18(%esp),%edx
  80126a:	8b 74 24 20          	mov    0x20(%esp),%esi
  80126e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801272:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801276:	83 c4 2c             	add    $0x2c,%esp
  801279:	c3                   	ret    
  80127a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801280:	85 f6                	test   %esi,%esi
  801282:	89 f5                	mov    %esi,%ebp
  801284:	75 0b                	jne    801291 <__umoddi3+0xb1>
  801286:	b8 01 00 00 00       	mov    $0x1,%eax
  80128b:	31 d2                	xor    %edx,%edx
  80128d:	f7 f6                	div    %esi
  80128f:	89 c5                	mov    %eax,%ebp
  801291:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801295:	31 d2                	xor    %edx,%edx
  801297:	f7 f5                	div    %ebp
  801299:	89 c8                	mov    %ecx,%eax
  80129b:	f7 f5                	div    %ebp
  80129d:	eb 84                	jmp    801223 <__umoddi3+0x43>
  80129f:	90                   	nop
  8012a0:	89 c8                	mov    %ecx,%eax
  8012a2:	89 fa                	mov    %edi,%edx
  8012a4:	8b 74 24 20          	mov    0x20(%esp),%esi
  8012a8:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8012ac:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8012b0:	83 c4 2c             	add    $0x2c,%esp
  8012b3:	c3                   	ret    
  8012b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8012b8:	8b 44 24 10          	mov    0x10(%esp),%eax
  8012bc:	be 20 00 00 00       	mov    $0x20,%esi
  8012c1:	89 e9                	mov    %ebp,%ecx
  8012c3:	29 ee                	sub    %ebp,%esi
  8012c5:	d3 e2                	shl    %cl,%edx
  8012c7:	89 f1                	mov    %esi,%ecx
  8012c9:	d3 e8                	shr    %cl,%eax
  8012cb:	89 e9                	mov    %ebp,%ecx
  8012cd:	09 d0                	or     %edx,%eax
  8012cf:	89 fa                	mov    %edi,%edx
  8012d1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012d5:	8b 44 24 10          	mov    0x10(%esp),%eax
  8012d9:	d3 e0                	shl    %cl,%eax
  8012db:	89 f1                	mov    %esi,%ecx
  8012dd:	89 44 24 10          	mov    %eax,0x10(%esp)
  8012e1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  8012e5:	d3 ea                	shr    %cl,%edx
  8012e7:	89 e9                	mov    %ebp,%ecx
  8012e9:	d3 e7                	shl    %cl,%edi
  8012eb:	89 f1                	mov    %esi,%ecx
  8012ed:	d3 e8                	shr    %cl,%eax
  8012ef:	89 e9                	mov    %ebp,%ecx
  8012f1:	09 f8                	or     %edi,%eax
  8012f3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  8012f7:	f7 74 24 0c          	divl   0xc(%esp)
  8012fb:	d3 e7                	shl    %cl,%edi
  8012fd:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801301:	89 d7                	mov    %edx,%edi
  801303:	f7 64 24 10          	mull   0x10(%esp)
  801307:	39 d7                	cmp    %edx,%edi
  801309:	89 c1                	mov    %eax,%ecx
  80130b:	89 54 24 14          	mov    %edx,0x14(%esp)
  80130f:	72 3b                	jb     80134c <__umoddi3+0x16c>
  801311:	39 44 24 18          	cmp    %eax,0x18(%esp)
  801315:	72 31                	jb     801348 <__umoddi3+0x168>
  801317:	8b 44 24 18          	mov    0x18(%esp),%eax
  80131b:	29 c8                	sub    %ecx,%eax
  80131d:	19 d7                	sbb    %edx,%edi
  80131f:	89 e9                	mov    %ebp,%ecx
  801321:	89 fa                	mov    %edi,%edx
  801323:	d3 e8                	shr    %cl,%eax
  801325:	89 f1                	mov    %esi,%ecx
  801327:	d3 e2                	shl    %cl,%edx
  801329:	89 e9                	mov    %ebp,%ecx
  80132b:	09 d0                	or     %edx,%eax
  80132d:	89 fa                	mov    %edi,%edx
  80132f:	d3 ea                	shr    %cl,%edx
  801331:	8b 74 24 20          	mov    0x20(%esp),%esi
  801335:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801339:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  80133d:	83 c4 2c             	add    $0x2c,%esp
  801340:	c3                   	ret    
  801341:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801348:	39 d7                	cmp    %edx,%edi
  80134a:	75 cb                	jne    801317 <__umoddi3+0x137>
  80134c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801350:	89 c1                	mov    %eax,%ecx
  801352:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801356:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80135a:	eb bb                	jmp    801317 <__umoddi3+0x137>
  80135c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801360:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801364:	0f 82 e8 fe ff ff    	jb     801252 <__umoddi3+0x72>
  80136a:	e9 f3 fe ff ff       	jmp    801262 <__umoddi3+0x82>

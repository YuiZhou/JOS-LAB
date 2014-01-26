
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
  800177:	c7 44 24 08 4a 13 80 	movl   $0x80134a,0x8(%esp)
  80017e:	00 
  80017f:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800186:	00 
  800187:	c7 04 24 67 13 80 00 	movl   $0x801367,(%esp)
  80018e:	e8 e1 02 00 00       	call   800474 <_panic>

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
  800236:	c7 44 24 08 4a 13 80 	movl   $0x80134a,0x8(%esp)
  80023d:	00 
  80023e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800245:	00 
  800246:	c7 04 24 67 13 80 00 	movl   $0x801367,(%esp)
  80024d:	e8 22 02 00 00       	call   800474 <_panic>

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
  800294:	c7 44 24 08 4a 13 80 	movl   $0x80134a,0x8(%esp)
  80029b:	00 
  80029c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8002a3:	00 
  8002a4:	c7 04 24 67 13 80 00 	movl   $0x801367,(%esp)
  8002ab:	e8 c4 01 00 00       	call   800474 <_panic>

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
  8002f2:	c7 44 24 08 4a 13 80 	movl   $0x80134a,0x8(%esp)
  8002f9:	00 
  8002fa:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800301:	00 
  800302:	c7 04 24 67 13 80 00 	movl   $0x801367,(%esp)
  800309:	e8 66 01 00 00       	call   800474 <_panic>

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
  800350:	c7 44 24 08 4a 13 80 	movl   $0x80134a,0x8(%esp)
  800357:	00 
  800358:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80035f:	00 
  800360:	c7 04 24 67 13 80 00 	movl   $0x801367,(%esp)
  800367:	e8 08 01 00 00       	call   800474 <_panic>

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
  8003ae:	c7 44 24 08 4a 13 80 	movl   $0x80134a,0x8(%esp)
  8003b5:	00 
  8003b6:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8003bd:	00 
  8003be:	c7 04 24 67 13 80 00 	movl   $0x801367,(%esp)
  8003c5:	e8 aa 00 00 00       	call   800474 <_panic>

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
  80043f:	c7 44 24 08 4a 13 80 	movl   $0x80134a,0x8(%esp)
  800446:	00 
  800447:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80044e:	00 
  80044f:	c7 04 24 67 13 80 00 	movl   $0x801367,(%esp)
  800456:	e8 19 00 00 00       	call   800474 <_panic>

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
  800473:	90                   	nop

00800474 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800474:	55                   	push   %ebp
  800475:	89 e5                	mov    %esp,%ebp
  800477:	56                   	push   %esi
  800478:	53                   	push   %ebx
  800479:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  80047c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  80047f:	a1 08 20 80 00       	mov    0x802008,%eax
  800484:	85 c0                	test   %eax,%eax
  800486:	74 10                	je     800498 <_panic+0x24>
		cprintf("%s: ", argv0);
  800488:	89 44 24 04          	mov    %eax,0x4(%esp)
  80048c:	c7 04 24 75 13 80 00 	movl   $0x801375,(%esp)
  800493:	e8 ef 00 00 00       	call   800587 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800498:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80049e:	e8 fd fc ff ff       	call   8001a0 <sys_getenvid>
  8004a3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8004a6:	89 54 24 10          	mov    %edx,0x10(%esp)
  8004aa:	8b 55 08             	mov    0x8(%ebp),%edx
  8004ad:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8004b1:	89 74 24 08          	mov    %esi,0x8(%esp)
  8004b5:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004b9:	c7 04 24 7c 13 80 00 	movl   $0x80137c,(%esp)
  8004c0:	e8 c2 00 00 00       	call   800587 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8004c5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004c9:	8b 45 10             	mov    0x10(%ebp),%eax
  8004cc:	89 04 24             	mov    %eax,(%esp)
  8004cf:	e8 52 00 00 00       	call   800526 <vcprintf>
	cprintf("\n");
  8004d4:	c7 04 24 7a 13 80 00 	movl   $0x80137a,(%esp)
  8004db:	e8 a7 00 00 00       	call   800587 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8004e0:	cc                   	int3   
  8004e1:	eb fd                	jmp    8004e0 <_panic+0x6c>
  8004e3:	90                   	nop

008004e4 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8004e4:	55                   	push   %ebp
  8004e5:	89 e5                	mov    %esp,%ebp
  8004e7:	53                   	push   %ebx
  8004e8:	83 ec 14             	sub    $0x14,%esp
  8004eb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8004ee:	8b 03                	mov    (%ebx),%eax
  8004f0:	8b 55 08             	mov    0x8(%ebp),%edx
  8004f3:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8004f7:	83 c0 01             	add    $0x1,%eax
  8004fa:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8004fc:	3d ff 00 00 00       	cmp    $0xff,%eax
  800501:	75 19                	jne    80051c <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800503:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80050a:	00 
  80050b:	8d 43 08             	lea    0x8(%ebx),%eax
  80050e:	89 04 24             	mov    %eax,(%esp)
  800511:	e8 ce fb ff ff       	call   8000e4 <sys_cputs>
		b->idx = 0;
  800516:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80051c:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800520:	83 c4 14             	add    $0x14,%esp
  800523:	5b                   	pop    %ebx
  800524:	5d                   	pop    %ebp
  800525:	c3                   	ret    

00800526 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800526:	55                   	push   %ebp
  800527:	89 e5                	mov    %esp,%ebp
  800529:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80052f:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800536:	00 00 00 
	b.cnt = 0;
  800539:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800540:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800543:	8b 45 0c             	mov    0xc(%ebp),%eax
  800546:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80054a:	8b 45 08             	mov    0x8(%ebp),%eax
  80054d:	89 44 24 08          	mov    %eax,0x8(%esp)
  800551:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800557:	89 44 24 04          	mov    %eax,0x4(%esp)
  80055b:	c7 04 24 e4 04 80 00 	movl   $0x8004e4,(%esp)
  800562:	e8 bb 01 00 00       	call   800722 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800567:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80056d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800571:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800577:	89 04 24             	mov    %eax,(%esp)
  80057a:	e8 65 fb ff ff       	call   8000e4 <sys_cputs>

	return b.cnt;
}
  80057f:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800585:	c9                   	leave  
  800586:	c3                   	ret    

00800587 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800587:	55                   	push   %ebp
  800588:	89 e5                	mov    %esp,%ebp
  80058a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80058d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800590:	89 44 24 04          	mov    %eax,0x4(%esp)
  800594:	8b 45 08             	mov    0x8(%ebp),%eax
  800597:	89 04 24             	mov    %eax,(%esp)
  80059a:	e8 87 ff ff ff       	call   800526 <vcprintf>
	va_end(ap);

	return cnt;
}
  80059f:	c9                   	leave  
  8005a0:	c3                   	ret    
  8005a1:	66 90                	xchg   %ax,%ax
  8005a3:	66 90                	xchg   %ax,%ax
  8005a5:	66 90                	xchg   %ax,%ax
  8005a7:	66 90                	xchg   %ax,%ax
  8005a9:	66 90                	xchg   %ax,%ax
  8005ab:	66 90                	xchg   %ax,%ax
  8005ad:	66 90                	xchg   %ax,%ax
  8005af:	90                   	nop

008005b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8005b0:	55                   	push   %ebp
  8005b1:	89 e5                	mov    %esp,%ebp
  8005b3:	57                   	push   %edi
  8005b4:	56                   	push   %esi
  8005b5:	53                   	push   %ebx
  8005b6:	83 ec 4c             	sub    $0x4c,%esp
  8005b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8005bc:	89 d7                	mov    %edx,%edi
  8005be:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8005c1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005c4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005c7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8005ca:	b8 00 00 00 00       	mov    $0x0,%eax
  8005cf:	39 d8                	cmp    %ebx,%eax
  8005d1:	72 17                	jb     8005ea <printnum+0x3a>
  8005d3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8005d6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8005d9:	76 0f                	jbe    8005ea <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8005db:	8b 75 14             	mov    0x14(%ebp),%esi
  8005de:	83 ee 01             	sub    $0x1,%esi
  8005e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005e4:	85 f6                	test   %esi,%esi
  8005e6:	7f 63                	jg     80064b <printnum+0x9b>
  8005e8:	eb 75                	jmp    80065f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8005ea:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8005ed:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8005f1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f4:	83 e8 01             	sub    $0x1,%eax
  8005f7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005fb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8005fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800602:	8b 44 24 08          	mov    0x8(%esp),%eax
  800606:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80060a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80060d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800610:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800617:	00 
  800618:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80061b:	89 1c 24             	mov    %ebx,(%esp)
  80061e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800621:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800625:	e8 26 0a 00 00       	call   801050 <__udivdi3>
  80062a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80062d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800630:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800634:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800638:	89 04 24             	mov    %eax,(%esp)
  80063b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80063f:	89 fa                	mov    %edi,%edx
  800641:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800644:	e8 67 ff ff ff       	call   8005b0 <printnum>
  800649:	eb 14                	jmp    80065f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80064b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80064f:	8b 45 18             	mov    0x18(%ebp),%eax
  800652:	89 04 24             	mov    %eax,(%esp)
  800655:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800657:	83 ee 01             	sub    $0x1,%esi
  80065a:	75 ef                	jne    80064b <printnum+0x9b>
  80065c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80065f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800663:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800667:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80066a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80066e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800675:	00 
  800676:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800679:	89 1c 24             	mov    %ebx,(%esp)
  80067c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80067f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800683:	e8 18 0b 00 00       	call   8011a0 <__umoddi3>
  800688:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80068c:	0f be 80 9f 13 80 00 	movsbl 0x80139f(%eax),%eax
  800693:	89 04 24             	mov    %eax,(%esp)
  800696:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800699:	ff d0                	call   *%eax
}
  80069b:	83 c4 4c             	add    $0x4c,%esp
  80069e:	5b                   	pop    %ebx
  80069f:	5e                   	pop    %esi
  8006a0:	5f                   	pop    %edi
  8006a1:	5d                   	pop    %ebp
  8006a2:	c3                   	ret    

008006a3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8006a3:	55                   	push   %ebp
  8006a4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8006a6:	83 fa 01             	cmp    $0x1,%edx
  8006a9:	7e 0e                	jle    8006b9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8006ab:	8b 10                	mov    (%eax),%edx
  8006ad:	8d 4a 08             	lea    0x8(%edx),%ecx
  8006b0:	89 08                	mov    %ecx,(%eax)
  8006b2:	8b 02                	mov    (%edx),%eax
  8006b4:	8b 52 04             	mov    0x4(%edx),%edx
  8006b7:	eb 22                	jmp    8006db <getuint+0x38>
	else if (lflag)
  8006b9:	85 d2                	test   %edx,%edx
  8006bb:	74 10                	je     8006cd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8006bd:	8b 10                	mov    (%eax),%edx
  8006bf:	8d 4a 04             	lea    0x4(%edx),%ecx
  8006c2:	89 08                	mov    %ecx,(%eax)
  8006c4:	8b 02                	mov    (%edx),%eax
  8006c6:	ba 00 00 00 00       	mov    $0x0,%edx
  8006cb:	eb 0e                	jmp    8006db <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8006cd:	8b 10                	mov    (%eax),%edx
  8006cf:	8d 4a 04             	lea    0x4(%edx),%ecx
  8006d2:	89 08                	mov    %ecx,(%eax)
  8006d4:	8b 02                	mov    (%edx),%eax
  8006d6:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8006db:	5d                   	pop    %ebp
  8006dc:	c3                   	ret    

008006dd <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8006dd:	55                   	push   %ebp
  8006de:	89 e5                	mov    %esp,%ebp
  8006e0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8006e3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8006e7:	8b 10                	mov    (%eax),%edx
  8006e9:	3b 50 04             	cmp    0x4(%eax),%edx
  8006ec:	73 0a                	jae    8006f8 <sprintputch+0x1b>
		*b->buf++ = ch;
  8006ee:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006f1:	88 0a                	mov    %cl,(%edx)
  8006f3:	83 c2 01             	add    $0x1,%edx
  8006f6:	89 10                	mov    %edx,(%eax)
}
  8006f8:	5d                   	pop    %ebp
  8006f9:	c3                   	ret    

008006fa <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8006fa:	55                   	push   %ebp
  8006fb:	89 e5                	mov    %esp,%ebp
  8006fd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800700:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800703:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800707:	8b 45 10             	mov    0x10(%ebp),%eax
  80070a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80070e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800711:	89 44 24 04          	mov    %eax,0x4(%esp)
  800715:	8b 45 08             	mov    0x8(%ebp),%eax
  800718:	89 04 24             	mov    %eax,(%esp)
  80071b:	e8 02 00 00 00       	call   800722 <vprintfmt>
	va_end(ap);
}
  800720:	c9                   	leave  
  800721:	c3                   	ret    

00800722 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800722:	55                   	push   %ebp
  800723:	89 e5                	mov    %esp,%ebp
  800725:	57                   	push   %edi
  800726:	56                   	push   %esi
  800727:	53                   	push   %ebx
  800728:	83 ec 4c             	sub    $0x4c,%esp
  80072b:	8b 75 08             	mov    0x8(%ebp),%esi
  80072e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800731:	8b 7d 10             	mov    0x10(%ebp),%edi
  800734:	eb 11                	jmp    800747 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800736:	85 c0                	test   %eax,%eax
  800738:	0f 84 db 03 00 00    	je     800b19 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80073e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800742:	89 04 24             	mov    %eax,(%esp)
  800745:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800747:	0f b6 07             	movzbl (%edi),%eax
  80074a:	83 c7 01             	add    $0x1,%edi
  80074d:	83 f8 25             	cmp    $0x25,%eax
  800750:	75 e4                	jne    800736 <vprintfmt+0x14>
  800752:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800756:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80075d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800764:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80076b:	ba 00 00 00 00       	mov    $0x0,%edx
  800770:	eb 2b                	jmp    80079d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800772:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800775:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800779:	eb 22                	jmp    80079d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80077b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80077e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800782:	eb 19                	jmp    80079d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800784:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800787:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80078e:	eb 0d                	jmp    80079d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800790:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800793:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800796:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80079d:	0f b6 0f             	movzbl (%edi),%ecx
  8007a0:	8d 47 01             	lea    0x1(%edi),%eax
  8007a3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8007a6:	0f b6 07             	movzbl (%edi),%eax
  8007a9:	83 e8 23             	sub    $0x23,%eax
  8007ac:	3c 55                	cmp    $0x55,%al
  8007ae:	0f 87 40 03 00 00    	ja     800af4 <vprintfmt+0x3d2>
  8007b4:	0f b6 c0             	movzbl %al,%eax
  8007b7:	ff 24 85 60 14 80 00 	jmp    *0x801460(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8007be:	83 e9 30             	sub    $0x30,%ecx
  8007c1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  8007c4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  8007c8:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8007cb:	83 f9 09             	cmp    $0x9,%ecx
  8007ce:	77 57                	ja     800827 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007d0:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007d3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8007d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8007d9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  8007dc:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8007df:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8007e3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8007e6:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8007e9:	83 f9 09             	cmp    $0x9,%ecx
  8007ec:	76 eb                	jbe    8007d9 <vprintfmt+0xb7>
  8007ee:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8007f1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  8007f4:	eb 34                	jmp    80082a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8007f6:	8b 45 14             	mov    0x14(%ebp),%eax
  8007f9:	8d 48 04             	lea    0x4(%eax),%ecx
  8007fc:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8007ff:	8b 00                	mov    (%eax),%eax
  800801:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800804:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800807:	eb 21                	jmp    80082a <vprintfmt+0x108>

		case '.':
			if (width < 0)
  800809:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80080d:	0f 88 71 ff ff ff    	js     800784 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800813:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800816:	eb 85                	jmp    80079d <vprintfmt+0x7b>
  800818:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80081b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800822:	e9 76 ff ff ff       	jmp    80079d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800827:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80082a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80082e:	0f 89 69 ff ff ff    	jns    80079d <vprintfmt+0x7b>
  800834:	e9 57 ff ff ff       	jmp    800790 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800839:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80083c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80083f:	e9 59 ff ff ff       	jmp    80079d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800844:	8b 45 14             	mov    0x14(%ebp),%eax
  800847:	8d 50 04             	lea    0x4(%eax),%edx
  80084a:	89 55 14             	mov    %edx,0x14(%ebp)
  80084d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800851:	8b 00                	mov    (%eax),%eax
  800853:	89 04 24             	mov    %eax,(%esp)
  800856:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800858:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80085b:	e9 e7 fe ff ff       	jmp    800747 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800860:	8b 45 14             	mov    0x14(%ebp),%eax
  800863:	8d 50 04             	lea    0x4(%eax),%edx
  800866:	89 55 14             	mov    %edx,0x14(%ebp)
  800869:	8b 00                	mov    (%eax),%eax
  80086b:	89 c2                	mov    %eax,%edx
  80086d:	c1 fa 1f             	sar    $0x1f,%edx
  800870:	31 d0                	xor    %edx,%eax
  800872:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800874:	83 f8 08             	cmp    $0x8,%eax
  800877:	7f 0b                	jg     800884 <vprintfmt+0x162>
  800879:	8b 14 85 c0 15 80 00 	mov    0x8015c0(,%eax,4),%edx
  800880:	85 d2                	test   %edx,%edx
  800882:	75 20                	jne    8008a4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800884:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800888:	c7 44 24 08 b7 13 80 	movl   $0x8013b7,0x8(%esp)
  80088f:	00 
  800890:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800894:	89 34 24             	mov    %esi,(%esp)
  800897:	e8 5e fe ff ff       	call   8006fa <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80089c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80089f:	e9 a3 fe ff ff       	jmp    800747 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8008a4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8008a8:	c7 44 24 08 c0 13 80 	movl   $0x8013c0,0x8(%esp)
  8008af:	00 
  8008b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8008b4:	89 34 24             	mov    %esi,(%esp)
  8008b7:	e8 3e fe ff ff       	call   8006fa <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008bc:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8008bf:	e9 83 fe ff ff       	jmp    800747 <vprintfmt+0x25>
  8008c4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8008c7:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8008ca:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8008cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8008d0:	8d 50 04             	lea    0x4(%eax),%edx
  8008d3:	89 55 14             	mov    %edx,0x14(%ebp)
  8008d6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8008d8:	85 ff                	test   %edi,%edi
  8008da:	b8 b0 13 80 00       	mov    $0x8013b0,%eax
  8008df:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8008e2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8008e6:	74 06                	je     8008ee <vprintfmt+0x1cc>
  8008e8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8008ec:	7f 16                	jg     800904 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8008ee:	0f b6 17             	movzbl (%edi),%edx
  8008f1:	0f be c2             	movsbl %dl,%eax
  8008f4:	83 c7 01             	add    $0x1,%edi
  8008f7:	85 c0                	test   %eax,%eax
  8008f9:	0f 85 9f 00 00 00    	jne    80099e <vprintfmt+0x27c>
  8008ff:	e9 8b 00 00 00       	jmp    80098f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800904:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800908:	89 3c 24             	mov    %edi,(%esp)
  80090b:	e8 c2 02 00 00       	call   800bd2 <strnlen>
  800910:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800913:	29 c2                	sub    %eax,%edx
  800915:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800918:	85 d2                	test   %edx,%edx
  80091a:	7e d2                	jle    8008ee <vprintfmt+0x1cc>
					putch(padc, putdat);
  80091c:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800920:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800923:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800926:	89 d7                	mov    %edx,%edi
  800928:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80092c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80092f:	89 04 24             	mov    %eax,(%esp)
  800932:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800934:	83 ef 01             	sub    $0x1,%edi
  800937:	75 ef                	jne    800928 <vprintfmt+0x206>
  800939:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80093c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80093f:	eb ad                	jmp    8008ee <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800941:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800945:	74 20                	je     800967 <vprintfmt+0x245>
  800947:	0f be d2             	movsbl %dl,%edx
  80094a:	83 ea 20             	sub    $0x20,%edx
  80094d:	83 fa 5e             	cmp    $0x5e,%edx
  800950:	76 15                	jbe    800967 <vprintfmt+0x245>
					putch('?', putdat);
  800952:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800955:	89 54 24 04          	mov    %edx,0x4(%esp)
  800959:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800960:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800963:	ff d1                	call   *%ecx
  800965:	eb 0f                	jmp    800976 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800967:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80096a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80096e:	89 04 24             	mov    %eax,(%esp)
  800971:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800974:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800976:	83 eb 01             	sub    $0x1,%ebx
  800979:	0f b6 17             	movzbl (%edi),%edx
  80097c:	0f be c2             	movsbl %dl,%eax
  80097f:	83 c7 01             	add    $0x1,%edi
  800982:	85 c0                	test   %eax,%eax
  800984:	75 24                	jne    8009aa <vprintfmt+0x288>
  800986:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800989:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80098c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80098f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800992:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800996:	0f 8e ab fd ff ff    	jle    800747 <vprintfmt+0x25>
  80099c:	eb 20                	jmp    8009be <vprintfmt+0x29c>
  80099e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8009a1:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8009a4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8009a7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8009aa:	85 f6                	test   %esi,%esi
  8009ac:	78 93                	js     800941 <vprintfmt+0x21f>
  8009ae:	83 ee 01             	sub    $0x1,%esi
  8009b1:	79 8e                	jns    800941 <vprintfmt+0x21f>
  8009b3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8009b6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8009b9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8009bc:	eb d1                	jmp    80098f <vprintfmt+0x26d>
  8009be:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8009c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8009c5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8009cc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8009ce:	83 ef 01             	sub    $0x1,%edi
  8009d1:	75 ee                	jne    8009c1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8009d3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8009d6:	e9 6c fd ff ff       	jmp    800747 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8009db:	83 fa 01             	cmp    $0x1,%edx
  8009de:	66 90                	xchg   %ax,%ax
  8009e0:	7e 16                	jle    8009f8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  8009e2:	8b 45 14             	mov    0x14(%ebp),%eax
  8009e5:	8d 50 08             	lea    0x8(%eax),%edx
  8009e8:	89 55 14             	mov    %edx,0x14(%ebp)
  8009eb:	8b 10                	mov    (%eax),%edx
  8009ed:	8b 48 04             	mov    0x4(%eax),%ecx
  8009f0:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8009f3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8009f6:	eb 32                	jmp    800a2a <vprintfmt+0x308>
	else if (lflag)
  8009f8:	85 d2                	test   %edx,%edx
  8009fa:	74 18                	je     800a14 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  8009fc:	8b 45 14             	mov    0x14(%ebp),%eax
  8009ff:	8d 50 04             	lea    0x4(%eax),%edx
  800a02:	89 55 14             	mov    %edx,0x14(%ebp)
  800a05:	8b 00                	mov    (%eax),%eax
  800a07:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800a0a:	89 c1                	mov    %eax,%ecx
  800a0c:	c1 f9 1f             	sar    $0x1f,%ecx
  800a0f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800a12:	eb 16                	jmp    800a2a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800a14:	8b 45 14             	mov    0x14(%ebp),%eax
  800a17:	8d 50 04             	lea    0x4(%eax),%edx
  800a1a:	89 55 14             	mov    %edx,0x14(%ebp)
  800a1d:	8b 00                	mov    (%eax),%eax
  800a1f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800a22:	89 c7                	mov    %eax,%edi
  800a24:	c1 ff 1f             	sar    $0x1f,%edi
  800a27:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800a2a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800a2d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800a30:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800a35:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800a39:	79 7d                	jns    800ab8 <vprintfmt+0x396>
				putch('-', putdat);
  800a3b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a3f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800a46:	ff d6                	call   *%esi
				num = -(long long) num;
  800a48:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800a4b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800a4e:	f7 d8                	neg    %eax
  800a50:	83 d2 00             	adc    $0x0,%edx
  800a53:	f7 da                	neg    %edx
			}
			base = 10;
  800a55:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800a5a:	eb 5c                	jmp    800ab8 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800a5c:	8d 45 14             	lea    0x14(%ebp),%eax
  800a5f:	e8 3f fc ff ff       	call   8006a3 <getuint>
			base = 10;
  800a64:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800a69:	eb 4d                	jmp    800ab8 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800a6b:	8d 45 14             	lea    0x14(%ebp),%eax
  800a6e:	e8 30 fc ff ff       	call   8006a3 <getuint>
			base = 8;
  800a73:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800a78:	eb 3e                	jmp    800ab8 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  800a7a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a7e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800a85:	ff d6                	call   *%esi
			putch('x', putdat);
  800a87:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a8b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800a92:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800a94:	8b 45 14             	mov    0x14(%ebp),%eax
  800a97:	8d 50 04             	lea    0x4(%eax),%edx
  800a9a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800a9d:	8b 00                	mov    (%eax),%eax
  800a9f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800aa4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800aa9:	eb 0d                	jmp    800ab8 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800aab:	8d 45 14             	lea    0x14(%ebp),%eax
  800aae:	e8 f0 fb ff ff       	call   8006a3 <getuint>
			base = 16;
  800ab3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800ab8:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  800abc:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800ac0:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800ac3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ac7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800acb:	89 04 24             	mov    %eax,(%esp)
  800ace:	89 54 24 04          	mov    %edx,0x4(%esp)
  800ad2:	89 da                	mov    %ebx,%edx
  800ad4:	89 f0                	mov    %esi,%eax
  800ad6:	e8 d5 fa ff ff       	call   8005b0 <printnum>
			break;
  800adb:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800ade:	e9 64 fc ff ff       	jmp    800747 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800ae3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ae7:	89 0c 24             	mov    %ecx,(%esp)
  800aea:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800aec:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800aef:	e9 53 fc ff ff       	jmp    800747 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800af4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800af8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800aff:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800b01:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800b05:	0f 84 3c fc ff ff    	je     800747 <vprintfmt+0x25>
  800b0b:	83 ef 01             	sub    $0x1,%edi
  800b0e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800b12:	75 f7                	jne    800b0b <vprintfmt+0x3e9>
  800b14:	e9 2e fc ff ff       	jmp    800747 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800b19:	83 c4 4c             	add    $0x4c,%esp
  800b1c:	5b                   	pop    %ebx
  800b1d:	5e                   	pop    %esi
  800b1e:	5f                   	pop    %edi
  800b1f:	5d                   	pop    %ebp
  800b20:	c3                   	ret    

00800b21 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800b21:	55                   	push   %ebp
  800b22:	89 e5                	mov    %esp,%ebp
  800b24:	83 ec 28             	sub    $0x28,%esp
  800b27:	8b 45 08             	mov    0x8(%ebp),%eax
  800b2a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800b2d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800b30:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800b34:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800b37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800b3e:	85 d2                	test   %edx,%edx
  800b40:	7e 30                	jle    800b72 <vsnprintf+0x51>
  800b42:	85 c0                	test   %eax,%eax
  800b44:	74 2c                	je     800b72 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800b46:	8b 45 14             	mov    0x14(%ebp),%eax
  800b49:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b4d:	8b 45 10             	mov    0x10(%ebp),%eax
  800b50:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b54:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800b57:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b5b:	c7 04 24 dd 06 80 00 	movl   $0x8006dd,(%esp)
  800b62:	e8 bb fb ff ff       	call   800722 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800b67:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800b6a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800b6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800b70:	eb 05                	jmp    800b77 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800b72:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800b77:	c9                   	leave  
  800b78:	c3                   	ret    

00800b79 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800b79:	55                   	push   %ebp
  800b7a:	89 e5                	mov    %esp,%ebp
  800b7c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800b7f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800b82:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b86:	8b 45 10             	mov    0x10(%ebp),%eax
  800b89:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b8d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b90:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b94:	8b 45 08             	mov    0x8(%ebp),%eax
  800b97:	89 04 24             	mov    %eax,(%esp)
  800b9a:	e8 82 ff ff ff       	call   800b21 <vsnprintf>
	va_end(ap);

	return rc;
}
  800b9f:	c9                   	leave  
  800ba0:	c3                   	ret    
  800ba1:	66 90                	xchg   %ax,%ax
  800ba3:	66 90                	xchg   %ax,%ax
  800ba5:	66 90                	xchg   %ax,%ax
  800ba7:	66 90                	xchg   %ax,%ax
  800ba9:	66 90                	xchg   %ax,%ax
  800bab:	66 90                	xchg   %ax,%ax
  800bad:	66 90                	xchg   %ax,%ax
  800baf:	90                   	nop

00800bb0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800bb0:	55                   	push   %ebp
  800bb1:	89 e5                	mov    %esp,%ebp
  800bb3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800bb6:	80 3a 00             	cmpb   $0x0,(%edx)
  800bb9:	74 10                	je     800bcb <strlen+0x1b>
  800bbb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800bc0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800bc3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800bc7:	75 f7                	jne    800bc0 <strlen+0x10>
  800bc9:	eb 05                	jmp    800bd0 <strlen+0x20>
  800bcb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800bd0:	5d                   	pop    %ebp
  800bd1:	c3                   	ret    

00800bd2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800bd2:	55                   	push   %ebp
  800bd3:	89 e5                	mov    %esp,%ebp
  800bd5:	53                   	push   %ebx
  800bd6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800bd9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800bdc:	85 c9                	test   %ecx,%ecx
  800bde:	74 1c                	je     800bfc <strnlen+0x2a>
  800be0:	80 3b 00             	cmpb   $0x0,(%ebx)
  800be3:	74 1e                	je     800c03 <strnlen+0x31>
  800be5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  800bea:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800bec:	39 ca                	cmp    %ecx,%edx
  800bee:	74 18                	je     800c08 <strnlen+0x36>
  800bf0:	83 c2 01             	add    $0x1,%edx
  800bf3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800bf8:	75 f0                	jne    800bea <strnlen+0x18>
  800bfa:	eb 0c                	jmp    800c08 <strnlen+0x36>
  800bfc:	b8 00 00 00 00       	mov    $0x0,%eax
  800c01:	eb 05                	jmp    800c08 <strnlen+0x36>
  800c03:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800c08:	5b                   	pop    %ebx
  800c09:	5d                   	pop    %ebp
  800c0a:	c3                   	ret    

00800c0b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800c0b:	55                   	push   %ebp
  800c0c:	89 e5                	mov    %esp,%ebp
  800c0e:	53                   	push   %ebx
  800c0f:	8b 45 08             	mov    0x8(%ebp),%eax
  800c12:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800c15:	89 c2                	mov    %eax,%edx
  800c17:	0f b6 19             	movzbl (%ecx),%ebx
  800c1a:	88 1a                	mov    %bl,(%edx)
  800c1c:	83 c2 01             	add    $0x1,%edx
  800c1f:	83 c1 01             	add    $0x1,%ecx
  800c22:	84 db                	test   %bl,%bl
  800c24:	75 f1                	jne    800c17 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800c26:	5b                   	pop    %ebx
  800c27:	5d                   	pop    %ebp
  800c28:	c3                   	ret    

00800c29 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800c29:	55                   	push   %ebp
  800c2a:	89 e5                	mov    %esp,%ebp
  800c2c:	53                   	push   %ebx
  800c2d:	83 ec 08             	sub    $0x8,%esp
  800c30:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800c33:	89 1c 24             	mov    %ebx,(%esp)
  800c36:	e8 75 ff ff ff       	call   800bb0 <strlen>
	strcpy(dst + len, src);
  800c3b:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c3e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800c42:	01 d8                	add    %ebx,%eax
  800c44:	89 04 24             	mov    %eax,(%esp)
  800c47:	e8 bf ff ff ff       	call   800c0b <strcpy>
	return dst;
}
  800c4c:	89 d8                	mov    %ebx,%eax
  800c4e:	83 c4 08             	add    $0x8,%esp
  800c51:	5b                   	pop    %ebx
  800c52:	5d                   	pop    %ebp
  800c53:	c3                   	ret    

00800c54 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800c54:	55                   	push   %ebp
  800c55:	89 e5                	mov    %esp,%ebp
  800c57:	56                   	push   %esi
  800c58:	53                   	push   %ebx
  800c59:	8b 75 08             	mov    0x8(%ebp),%esi
  800c5c:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c5f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800c62:	85 db                	test   %ebx,%ebx
  800c64:	74 16                	je     800c7c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800c66:	01 f3                	add    %esi,%ebx
  800c68:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  800c6a:	0f b6 02             	movzbl (%edx),%eax
  800c6d:	88 01                	mov    %al,(%ecx)
  800c6f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800c72:	80 3a 01             	cmpb   $0x1,(%edx)
  800c75:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800c78:	39 d9                	cmp    %ebx,%ecx
  800c7a:	75 ee                	jne    800c6a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800c7c:	89 f0                	mov    %esi,%eax
  800c7e:	5b                   	pop    %ebx
  800c7f:	5e                   	pop    %esi
  800c80:	5d                   	pop    %ebp
  800c81:	c3                   	ret    

00800c82 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800c82:	55                   	push   %ebp
  800c83:	89 e5                	mov    %esp,%ebp
  800c85:	57                   	push   %edi
  800c86:	56                   	push   %esi
  800c87:	53                   	push   %ebx
  800c88:	8b 7d 08             	mov    0x8(%ebp),%edi
  800c8b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c8e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800c91:	89 f8                	mov    %edi,%eax
  800c93:	85 f6                	test   %esi,%esi
  800c95:	74 33                	je     800cca <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800c97:	83 fe 01             	cmp    $0x1,%esi
  800c9a:	74 25                	je     800cc1 <strlcpy+0x3f>
  800c9c:	0f b6 0b             	movzbl (%ebx),%ecx
  800c9f:	84 c9                	test   %cl,%cl
  800ca1:	74 22                	je     800cc5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800ca3:	83 ee 02             	sub    $0x2,%esi
  800ca6:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800cab:	88 08                	mov    %cl,(%eax)
  800cad:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800cb0:	39 f2                	cmp    %esi,%edx
  800cb2:	74 13                	je     800cc7 <strlcpy+0x45>
  800cb4:	83 c2 01             	add    $0x1,%edx
  800cb7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  800cbb:	84 c9                	test   %cl,%cl
  800cbd:	75 ec                	jne    800cab <strlcpy+0x29>
  800cbf:	eb 06                	jmp    800cc7 <strlcpy+0x45>
  800cc1:	89 f8                	mov    %edi,%eax
  800cc3:	eb 02                	jmp    800cc7 <strlcpy+0x45>
  800cc5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800cc7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800cca:	29 f8                	sub    %edi,%eax
}
  800ccc:	5b                   	pop    %ebx
  800ccd:	5e                   	pop    %esi
  800cce:	5f                   	pop    %edi
  800ccf:	5d                   	pop    %ebp
  800cd0:	c3                   	ret    

00800cd1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800cd1:	55                   	push   %ebp
  800cd2:	89 e5                	mov    %esp,%ebp
  800cd4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800cd7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800cda:	0f b6 01             	movzbl (%ecx),%eax
  800cdd:	84 c0                	test   %al,%al
  800cdf:	74 15                	je     800cf6 <strcmp+0x25>
  800ce1:	3a 02                	cmp    (%edx),%al
  800ce3:	75 11                	jne    800cf6 <strcmp+0x25>
		p++, q++;
  800ce5:	83 c1 01             	add    $0x1,%ecx
  800ce8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800ceb:	0f b6 01             	movzbl (%ecx),%eax
  800cee:	84 c0                	test   %al,%al
  800cf0:	74 04                	je     800cf6 <strcmp+0x25>
  800cf2:	3a 02                	cmp    (%edx),%al
  800cf4:	74 ef                	je     800ce5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800cf6:	0f b6 c0             	movzbl %al,%eax
  800cf9:	0f b6 12             	movzbl (%edx),%edx
  800cfc:	29 d0                	sub    %edx,%eax
}
  800cfe:	5d                   	pop    %ebp
  800cff:	c3                   	ret    

00800d00 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800d00:	55                   	push   %ebp
  800d01:	89 e5                	mov    %esp,%ebp
  800d03:	56                   	push   %esi
  800d04:	53                   	push   %ebx
  800d05:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800d08:	8b 55 0c             	mov    0xc(%ebp),%edx
  800d0b:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800d0e:	85 f6                	test   %esi,%esi
  800d10:	74 29                	je     800d3b <strncmp+0x3b>
  800d12:	0f b6 03             	movzbl (%ebx),%eax
  800d15:	84 c0                	test   %al,%al
  800d17:	74 30                	je     800d49 <strncmp+0x49>
  800d19:	3a 02                	cmp    (%edx),%al
  800d1b:	75 2c                	jne    800d49 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800d1d:	8d 43 01             	lea    0x1(%ebx),%eax
  800d20:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800d22:	89 c3                	mov    %eax,%ebx
  800d24:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800d27:	39 f0                	cmp    %esi,%eax
  800d29:	74 17                	je     800d42 <strncmp+0x42>
  800d2b:	0f b6 08             	movzbl (%eax),%ecx
  800d2e:	84 c9                	test   %cl,%cl
  800d30:	74 17                	je     800d49 <strncmp+0x49>
  800d32:	83 c0 01             	add    $0x1,%eax
  800d35:	3a 0a                	cmp    (%edx),%cl
  800d37:	74 e9                	je     800d22 <strncmp+0x22>
  800d39:	eb 0e                	jmp    800d49 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800d3b:	b8 00 00 00 00       	mov    $0x0,%eax
  800d40:	eb 0f                	jmp    800d51 <strncmp+0x51>
  800d42:	b8 00 00 00 00       	mov    $0x0,%eax
  800d47:	eb 08                	jmp    800d51 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800d49:	0f b6 03             	movzbl (%ebx),%eax
  800d4c:	0f b6 12             	movzbl (%edx),%edx
  800d4f:	29 d0                	sub    %edx,%eax
}
  800d51:	5b                   	pop    %ebx
  800d52:	5e                   	pop    %esi
  800d53:	5d                   	pop    %ebp
  800d54:	c3                   	ret    

00800d55 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800d55:	55                   	push   %ebp
  800d56:	89 e5                	mov    %esp,%ebp
  800d58:	53                   	push   %ebx
  800d59:	8b 45 08             	mov    0x8(%ebp),%eax
  800d5c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800d5f:	0f b6 18             	movzbl (%eax),%ebx
  800d62:	84 db                	test   %bl,%bl
  800d64:	74 1d                	je     800d83 <strchr+0x2e>
  800d66:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800d68:	38 d3                	cmp    %dl,%bl
  800d6a:	75 06                	jne    800d72 <strchr+0x1d>
  800d6c:	eb 1a                	jmp    800d88 <strchr+0x33>
  800d6e:	38 ca                	cmp    %cl,%dl
  800d70:	74 16                	je     800d88 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800d72:	83 c0 01             	add    $0x1,%eax
  800d75:	0f b6 10             	movzbl (%eax),%edx
  800d78:	84 d2                	test   %dl,%dl
  800d7a:	75 f2                	jne    800d6e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800d7c:	b8 00 00 00 00       	mov    $0x0,%eax
  800d81:	eb 05                	jmp    800d88 <strchr+0x33>
  800d83:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800d88:	5b                   	pop    %ebx
  800d89:	5d                   	pop    %ebp
  800d8a:	c3                   	ret    

00800d8b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800d8b:	55                   	push   %ebp
  800d8c:	89 e5                	mov    %esp,%ebp
  800d8e:	53                   	push   %ebx
  800d8f:	8b 45 08             	mov    0x8(%ebp),%eax
  800d92:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800d95:	0f b6 18             	movzbl (%eax),%ebx
  800d98:	84 db                	test   %bl,%bl
  800d9a:	74 16                	je     800db2 <strfind+0x27>
  800d9c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800d9e:	38 d3                	cmp    %dl,%bl
  800da0:	75 06                	jne    800da8 <strfind+0x1d>
  800da2:	eb 0e                	jmp    800db2 <strfind+0x27>
  800da4:	38 ca                	cmp    %cl,%dl
  800da6:	74 0a                	je     800db2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800da8:	83 c0 01             	add    $0x1,%eax
  800dab:	0f b6 10             	movzbl (%eax),%edx
  800dae:	84 d2                	test   %dl,%dl
  800db0:	75 f2                	jne    800da4 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800db2:	5b                   	pop    %ebx
  800db3:	5d                   	pop    %ebp
  800db4:	c3                   	ret    

00800db5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800db5:	55                   	push   %ebp
  800db6:	89 e5                	mov    %esp,%ebp
  800db8:	83 ec 0c             	sub    $0xc,%esp
  800dbb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800dbe:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800dc1:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800dc4:	8b 7d 08             	mov    0x8(%ebp),%edi
  800dc7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800dca:	85 c9                	test   %ecx,%ecx
  800dcc:	74 36                	je     800e04 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800dce:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800dd4:	75 28                	jne    800dfe <memset+0x49>
  800dd6:	f6 c1 03             	test   $0x3,%cl
  800dd9:	75 23                	jne    800dfe <memset+0x49>
		c &= 0xFF;
  800ddb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800ddf:	89 d3                	mov    %edx,%ebx
  800de1:	c1 e3 08             	shl    $0x8,%ebx
  800de4:	89 d6                	mov    %edx,%esi
  800de6:	c1 e6 18             	shl    $0x18,%esi
  800de9:	89 d0                	mov    %edx,%eax
  800deb:	c1 e0 10             	shl    $0x10,%eax
  800dee:	09 f0                	or     %esi,%eax
  800df0:	09 c2                	or     %eax,%edx
  800df2:	89 d0                	mov    %edx,%eax
  800df4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800df6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800df9:	fc                   	cld    
  800dfa:	f3 ab                	rep stos %eax,%es:(%edi)
  800dfc:	eb 06                	jmp    800e04 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800dfe:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e01:	fc                   	cld    
  800e02:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800e04:	89 f8                	mov    %edi,%eax
  800e06:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800e09:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e0c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e0f:	89 ec                	mov    %ebp,%esp
  800e11:	5d                   	pop    %ebp
  800e12:	c3                   	ret    

00800e13 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800e13:	55                   	push   %ebp
  800e14:	89 e5                	mov    %esp,%ebp
  800e16:	83 ec 08             	sub    $0x8,%esp
  800e19:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800e1c:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800e1f:	8b 45 08             	mov    0x8(%ebp),%eax
  800e22:	8b 75 0c             	mov    0xc(%ebp),%esi
  800e25:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800e28:	39 c6                	cmp    %eax,%esi
  800e2a:	73 36                	jae    800e62 <memmove+0x4f>
  800e2c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800e2f:	39 d0                	cmp    %edx,%eax
  800e31:	73 2f                	jae    800e62 <memmove+0x4f>
		s += n;
		d += n;
  800e33:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e36:	f6 c2 03             	test   $0x3,%dl
  800e39:	75 1b                	jne    800e56 <memmove+0x43>
  800e3b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800e41:	75 13                	jne    800e56 <memmove+0x43>
  800e43:	f6 c1 03             	test   $0x3,%cl
  800e46:	75 0e                	jne    800e56 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800e48:	83 ef 04             	sub    $0x4,%edi
  800e4b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800e4e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800e51:	fd                   	std    
  800e52:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e54:	eb 09                	jmp    800e5f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800e56:	83 ef 01             	sub    $0x1,%edi
  800e59:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800e5c:	fd                   	std    
  800e5d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800e5f:	fc                   	cld    
  800e60:	eb 20                	jmp    800e82 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e62:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800e68:	75 13                	jne    800e7d <memmove+0x6a>
  800e6a:	a8 03                	test   $0x3,%al
  800e6c:	75 0f                	jne    800e7d <memmove+0x6a>
  800e6e:	f6 c1 03             	test   $0x3,%cl
  800e71:	75 0a                	jne    800e7d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800e73:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800e76:	89 c7                	mov    %eax,%edi
  800e78:	fc                   	cld    
  800e79:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e7b:	eb 05                	jmp    800e82 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800e7d:	89 c7                	mov    %eax,%edi
  800e7f:	fc                   	cld    
  800e80:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800e82:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e85:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e88:	89 ec                	mov    %ebp,%esp
  800e8a:	5d                   	pop    %ebp
  800e8b:	c3                   	ret    

00800e8c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800e8c:	55                   	push   %ebp
  800e8d:	89 e5                	mov    %esp,%ebp
  800e8f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800e92:	8b 45 10             	mov    0x10(%ebp),%eax
  800e95:	89 44 24 08          	mov    %eax,0x8(%esp)
  800e99:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e9c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ea0:	8b 45 08             	mov    0x8(%ebp),%eax
  800ea3:	89 04 24             	mov    %eax,(%esp)
  800ea6:	e8 68 ff ff ff       	call   800e13 <memmove>
}
  800eab:	c9                   	leave  
  800eac:	c3                   	ret    

00800ead <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800ead:	55                   	push   %ebp
  800eae:	89 e5                	mov    %esp,%ebp
  800eb0:	57                   	push   %edi
  800eb1:	56                   	push   %esi
  800eb2:	53                   	push   %ebx
  800eb3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800eb6:	8b 75 0c             	mov    0xc(%ebp),%esi
  800eb9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ebc:	8d 78 ff             	lea    -0x1(%eax),%edi
  800ebf:	85 c0                	test   %eax,%eax
  800ec1:	74 36                	je     800ef9 <memcmp+0x4c>
		if (*s1 != *s2)
  800ec3:	0f b6 03             	movzbl (%ebx),%eax
  800ec6:	0f b6 0e             	movzbl (%esi),%ecx
  800ec9:	38 c8                	cmp    %cl,%al
  800ecb:	75 17                	jne    800ee4 <memcmp+0x37>
  800ecd:	ba 00 00 00 00       	mov    $0x0,%edx
  800ed2:	eb 1a                	jmp    800eee <memcmp+0x41>
  800ed4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800ed9:	83 c2 01             	add    $0x1,%edx
  800edc:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800ee0:	38 c8                	cmp    %cl,%al
  800ee2:	74 0a                	je     800eee <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800ee4:	0f b6 c0             	movzbl %al,%eax
  800ee7:	0f b6 c9             	movzbl %cl,%ecx
  800eea:	29 c8                	sub    %ecx,%eax
  800eec:	eb 10                	jmp    800efe <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800eee:	39 fa                	cmp    %edi,%edx
  800ef0:	75 e2                	jne    800ed4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800ef2:	b8 00 00 00 00       	mov    $0x0,%eax
  800ef7:	eb 05                	jmp    800efe <memcmp+0x51>
  800ef9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800efe:	5b                   	pop    %ebx
  800eff:	5e                   	pop    %esi
  800f00:	5f                   	pop    %edi
  800f01:	5d                   	pop    %ebp
  800f02:	c3                   	ret    

00800f03 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800f03:	55                   	push   %ebp
  800f04:	89 e5                	mov    %esp,%ebp
  800f06:	53                   	push   %ebx
  800f07:	8b 45 08             	mov    0x8(%ebp),%eax
  800f0a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800f0d:	89 c2                	mov    %eax,%edx
  800f0f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800f12:	39 d0                	cmp    %edx,%eax
  800f14:	73 13                	jae    800f29 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800f16:	89 d9                	mov    %ebx,%ecx
  800f18:	38 18                	cmp    %bl,(%eax)
  800f1a:	75 06                	jne    800f22 <memfind+0x1f>
  800f1c:	eb 0b                	jmp    800f29 <memfind+0x26>
  800f1e:	38 08                	cmp    %cl,(%eax)
  800f20:	74 07                	je     800f29 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800f22:	83 c0 01             	add    $0x1,%eax
  800f25:	39 d0                	cmp    %edx,%eax
  800f27:	75 f5                	jne    800f1e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800f29:	5b                   	pop    %ebx
  800f2a:	5d                   	pop    %ebp
  800f2b:	c3                   	ret    

00800f2c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800f2c:	55                   	push   %ebp
  800f2d:	89 e5                	mov    %esp,%ebp
  800f2f:	57                   	push   %edi
  800f30:	56                   	push   %esi
  800f31:	53                   	push   %ebx
  800f32:	83 ec 04             	sub    $0x4,%esp
  800f35:	8b 55 08             	mov    0x8(%ebp),%edx
  800f38:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f3b:	0f b6 02             	movzbl (%edx),%eax
  800f3e:	3c 09                	cmp    $0x9,%al
  800f40:	74 04                	je     800f46 <strtol+0x1a>
  800f42:	3c 20                	cmp    $0x20,%al
  800f44:	75 0e                	jne    800f54 <strtol+0x28>
		s++;
  800f46:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f49:	0f b6 02             	movzbl (%edx),%eax
  800f4c:	3c 09                	cmp    $0x9,%al
  800f4e:	74 f6                	je     800f46 <strtol+0x1a>
  800f50:	3c 20                	cmp    $0x20,%al
  800f52:	74 f2                	je     800f46 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800f54:	3c 2b                	cmp    $0x2b,%al
  800f56:	75 0a                	jne    800f62 <strtol+0x36>
		s++;
  800f58:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800f5b:	bf 00 00 00 00       	mov    $0x0,%edi
  800f60:	eb 10                	jmp    800f72 <strtol+0x46>
  800f62:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800f67:	3c 2d                	cmp    $0x2d,%al
  800f69:	75 07                	jne    800f72 <strtol+0x46>
		s++, neg = 1;
  800f6b:	83 c2 01             	add    $0x1,%edx
  800f6e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800f72:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800f78:	75 15                	jne    800f8f <strtol+0x63>
  800f7a:	80 3a 30             	cmpb   $0x30,(%edx)
  800f7d:	75 10                	jne    800f8f <strtol+0x63>
  800f7f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800f83:	75 0a                	jne    800f8f <strtol+0x63>
		s += 2, base = 16;
  800f85:	83 c2 02             	add    $0x2,%edx
  800f88:	bb 10 00 00 00       	mov    $0x10,%ebx
  800f8d:	eb 10                	jmp    800f9f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800f8f:	85 db                	test   %ebx,%ebx
  800f91:	75 0c                	jne    800f9f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800f93:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800f95:	80 3a 30             	cmpb   $0x30,(%edx)
  800f98:	75 05                	jne    800f9f <strtol+0x73>
		s++, base = 8;
  800f9a:	83 c2 01             	add    $0x1,%edx
  800f9d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800f9f:	b8 00 00 00 00       	mov    $0x0,%eax
  800fa4:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800fa7:	0f b6 0a             	movzbl (%edx),%ecx
  800faa:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800fad:	89 f3                	mov    %esi,%ebx
  800faf:	80 fb 09             	cmp    $0x9,%bl
  800fb2:	77 08                	ja     800fbc <strtol+0x90>
			dig = *s - '0';
  800fb4:	0f be c9             	movsbl %cl,%ecx
  800fb7:	83 e9 30             	sub    $0x30,%ecx
  800fba:	eb 22                	jmp    800fde <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800fbc:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800fbf:	89 f3                	mov    %esi,%ebx
  800fc1:	80 fb 19             	cmp    $0x19,%bl
  800fc4:	77 08                	ja     800fce <strtol+0xa2>
			dig = *s - 'a' + 10;
  800fc6:	0f be c9             	movsbl %cl,%ecx
  800fc9:	83 e9 57             	sub    $0x57,%ecx
  800fcc:	eb 10                	jmp    800fde <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800fce:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800fd1:	89 f3                	mov    %esi,%ebx
  800fd3:	80 fb 19             	cmp    $0x19,%bl
  800fd6:	77 16                	ja     800fee <strtol+0xc2>
			dig = *s - 'A' + 10;
  800fd8:	0f be c9             	movsbl %cl,%ecx
  800fdb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800fde:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800fe1:	7d 0f                	jge    800ff2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800fe3:	83 c2 01             	add    $0x1,%edx
  800fe6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800fea:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800fec:	eb b9                	jmp    800fa7 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800fee:	89 c1                	mov    %eax,%ecx
  800ff0:	eb 02                	jmp    800ff4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800ff2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800ff4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ff8:	74 05                	je     800fff <strtol+0xd3>
		*endptr = (char *) s;
  800ffa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800ffd:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800fff:	89 ca                	mov    %ecx,%edx
  801001:	f7 da                	neg    %edx
  801003:	85 ff                	test   %edi,%edi
  801005:	0f 45 c2             	cmovne %edx,%eax
}
  801008:	83 c4 04             	add    $0x4,%esp
  80100b:	5b                   	pop    %ebx
  80100c:	5e                   	pop    %esi
  80100d:	5f                   	pop    %edi
  80100e:	5d                   	pop    %ebp
  80100f:	c3                   	ret    

00801010 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801010:	55                   	push   %ebp
  801011:	89 e5                	mov    %esp,%ebp
  801013:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  801016:	83 3d 0c 20 80 00 00 	cmpl   $0x0,0x80200c
  80101d:	75 1c                	jne    80103b <set_pgfault_handler+0x2b>
		// First time through!
		// LAB 4: Your code here.
		panic("set_pgfault_handler not implemented");
  80101f:	c7 44 24 08 e4 15 80 	movl   $0x8015e4,0x8(%esp)
  801026:	00 
  801027:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  80102e:	00 
  80102f:	c7 04 24 08 16 80 00 	movl   $0x801608,(%esp)
  801036:	e8 39 f4 ff ff       	call   800474 <_panic>
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  80103b:	8b 45 08             	mov    0x8(%ebp),%eax
  80103e:	a3 0c 20 80 00       	mov    %eax,0x80200c
}
  801043:	c9                   	leave  
  801044:	c3                   	ret    
  801045:	66 90                	xchg   %ax,%ax
  801047:	66 90                	xchg   %ax,%ax
  801049:	66 90                	xchg   %ax,%ax
  80104b:	66 90                	xchg   %ax,%ax
  80104d:	66 90                	xchg   %ax,%ax
  80104f:	90                   	nop

00801050 <__udivdi3>:
  801050:	83 ec 1c             	sub    $0x1c,%esp
  801053:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  801057:	89 7c 24 14          	mov    %edi,0x14(%esp)
  80105b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  80105f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  801063:	8b 7c 24 20          	mov    0x20(%esp),%edi
  801067:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  80106b:	85 c0                	test   %eax,%eax
  80106d:	89 74 24 10          	mov    %esi,0x10(%esp)
  801071:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801075:	89 ea                	mov    %ebp,%edx
  801077:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80107b:	75 33                	jne    8010b0 <__udivdi3+0x60>
  80107d:	39 e9                	cmp    %ebp,%ecx
  80107f:	77 6f                	ja     8010f0 <__udivdi3+0xa0>
  801081:	85 c9                	test   %ecx,%ecx
  801083:	89 ce                	mov    %ecx,%esi
  801085:	75 0b                	jne    801092 <__udivdi3+0x42>
  801087:	b8 01 00 00 00       	mov    $0x1,%eax
  80108c:	31 d2                	xor    %edx,%edx
  80108e:	f7 f1                	div    %ecx
  801090:	89 c6                	mov    %eax,%esi
  801092:	31 d2                	xor    %edx,%edx
  801094:	89 e8                	mov    %ebp,%eax
  801096:	f7 f6                	div    %esi
  801098:	89 c5                	mov    %eax,%ebp
  80109a:	89 f8                	mov    %edi,%eax
  80109c:	f7 f6                	div    %esi
  80109e:	89 ea                	mov    %ebp,%edx
  8010a0:	8b 74 24 10          	mov    0x10(%esp),%esi
  8010a4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8010a8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8010ac:	83 c4 1c             	add    $0x1c,%esp
  8010af:	c3                   	ret    
  8010b0:	39 e8                	cmp    %ebp,%eax
  8010b2:	77 24                	ja     8010d8 <__udivdi3+0x88>
  8010b4:	0f bd c8             	bsr    %eax,%ecx
  8010b7:	83 f1 1f             	xor    $0x1f,%ecx
  8010ba:	89 0c 24             	mov    %ecx,(%esp)
  8010bd:	75 49                	jne    801108 <__udivdi3+0xb8>
  8010bf:	8b 74 24 08          	mov    0x8(%esp),%esi
  8010c3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  8010c7:	0f 86 ab 00 00 00    	jbe    801178 <__udivdi3+0x128>
  8010cd:	39 e8                	cmp    %ebp,%eax
  8010cf:	0f 82 a3 00 00 00    	jb     801178 <__udivdi3+0x128>
  8010d5:	8d 76 00             	lea    0x0(%esi),%esi
  8010d8:	31 d2                	xor    %edx,%edx
  8010da:	31 c0                	xor    %eax,%eax
  8010dc:	8b 74 24 10          	mov    0x10(%esp),%esi
  8010e0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8010e4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8010e8:	83 c4 1c             	add    $0x1c,%esp
  8010eb:	c3                   	ret    
  8010ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8010f0:	89 f8                	mov    %edi,%eax
  8010f2:	f7 f1                	div    %ecx
  8010f4:	31 d2                	xor    %edx,%edx
  8010f6:	8b 74 24 10          	mov    0x10(%esp),%esi
  8010fa:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8010fe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801102:	83 c4 1c             	add    $0x1c,%esp
  801105:	c3                   	ret    
  801106:	66 90                	xchg   %ax,%ax
  801108:	0f b6 0c 24          	movzbl (%esp),%ecx
  80110c:	89 c6                	mov    %eax,%esi
  80110e:	b8 20 00 00 00       	mov    $0x20,%eax
  801113:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  801117:	2b 04 24             	sub    (%esp),%eax
  80111a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  80111e:	d3 e6                	shl    %cl,%esi
  801120:	89 c1                	mov    %eax,%ecx
  801122:	d3 ed                	shr    %cl,%ebp
  801124:	0f b6 0c 24          	movzbl (%esp),%ecx
  801128:	09 f5                	or     %esi,%ebp
  80112a:	8b 74 24 04          	mov    0x4(%esp),%esi
  80112e:	d3 e6                	shl    %cl,%esi
  801130:	89 c1                	mov    %eax,%ecx
  801132:	89 74 24 04          	mov    %esi,0x4(%esp)
  801136:	89 d6                	mov    %edx,%esi
  801138:	d3 ee                	shr    %cl,%esi
  80113a:	0f b6 0c 24          	movzbl (%esp),%ecx
  80113e:	d3 e2                	shl    %cl,%edx
  801140:	89 c1                	mov    %eax,%ecx
  801142:	d3 ef                	shr    %cl,%edi
  801144:	09 d7                	or     %edx,%edi
  801146:	89 f2                	mov    %esi,%edx
  801148:	89 f8                	mov    %edi,%eax
  80114a:	f7 f5                	div    %ebp
  80114c:	89 d6                	mov    %edx,%esi
  80114e:	89 c7                	mov    %eax,%edi
  801150:	f7 64 24 04          	mull   0x4(%esp)
  801154:	39 d6                	cmp    %edx,%esi
  801156:	72 30                	jb     801188 <__udivdi3+0x138>
  801158:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  80115c:	0f b6 0c 24          	movzbl (%esp),%ecx
  801160:	d3 e5                	shl    %cl,%ebp
  801162:	39 c5                	cmp    %eax,%ebp
  801164:	73 04                	jae    80116a <__udivdi3+0x11a>
  801166:	39 d6                	cmp    %edx,%esi
  801168:	74 1e                	je     801188 <__udivdi3+0x138>
  80116a:	89 f8                	mov    %edi,%eax
  80116c:	31 d2                	xor    %edx,%edx
  80116e:	e9 69 ff ff ff       	jmp    8010dc <__udivdi3+0x8c>
  801173:	90                   	nop
  801174:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801178:	31 d2                	xor    %edx,%edx
  80117a:	b8 01 00 00 00       	mov    $0x1,%eax
  80117f:	e9 58 ff ff ff       	jmp    8010dc <__udivdi3+0x8c>
  801184:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801188:	8d 47 ff             	lea    -0x1(%edi),%eax
  80118b:	31 d2                	xor    %edx,%edx
  80118d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801191:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801195:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801199:	83 c4 1c             	add    $0x1c,%esp
  80119c:	c3                   	ret    
  80119d:	66 90                	xchg   %ax,%ax
  80119f:	90                   	nop

008011a0 <__umoddi3>:
  8011a0:	83 ec 2c             	sub    $0x2c,%esp
  8011a3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  8011a7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  8011ab:	89 74 24 20          	mov    %esi,0x20(%esp)
  8011af:	8b 74 24 38          	mov    0x38(%esp),%esi
  8011b3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  8011b7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  8011bb:	85 c0                	test   %eax,%eax
  8011bd:	89 c2                	mov    %eax,%edx
  8011bf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  8011c3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  8011c7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8011cb:	89 74 24 10          	mov    %esi,0x10(%esp)
  8011cf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  8011d3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8011d7:	75 1f                	jne    8011f8 <__umoddi3+0x58>
  8011d9:	39 fe                	cmp    %edi,%esi
  8011db:	76 63                	jbe    801240 <__umoddi3+0xa0>
  8011dd:	89 c8                	mov    %ecx,%eax
  8011df:	89 fa                	mov    %edi,%edx
  8011e1:	f7 f6                	div    %esi
  8011e3:	89 d0                	mov    %edx,%eax
  8011e5:	31 d2                	xor    %edx,%edx
  8011e7:	8b 74 24 20          	mov    0x20(%esp),%esi
  8011eb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8011ef:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8011f3:	83 c4 2c             	add    $0x2c,%esp
  8011f6:	c3                   	ret    
  8011f7:	90                   	nop
  8011f8:	39 f8                	cmp    %edi,%eax
  8011fa:	77 64                	ja     801260 <__umoddi3+0xc0>
  8011fc:	0f bd e8             	bsr    %eax,%ebp
  8011ff:	83 f5 1f             	xor    $0x1f,%ebp
  801202:	75 74                	jne    801278 <__umoddi3+0xd8>
  801204:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801208:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  80120c:	0f 87 0e 01 00 00    	ja     801320 <__umoddi3+0x180>
  801212:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  801216:	29 f1                	sub    %esi,%ecx
  801218:	19 c7                	sbb    %eax,%edi
  80121a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  80121e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801222:	8b 44 24 14          	mov    0x14(%esp),%eax
  801226:	8b 54 24 18          	mov    0x18(%esp),%edx
  80122a:	8b 74 24 20          	mov    0x20(%esp),%esi
  80122e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801232:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801236:	83 c4 2c             	add    $0x2c,%esp
  801239:	c3                   	ret    
  80123a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801240:	85 f6                	test   %esi,%esi
  801242:	89 f5                	mov    %esi,%ebp
  801244:	75 0b                	jne    801251 <__umoddi3+0xb1>
  801246:	b8 01 00 00 00       	mov    $0x1,%eax
  80124b:	31 d2                	xor    %edx,%edx
  80124d:	f7 f6                	div    %esi
  80124f:	89 c5                	mov    %eax,%ebp
  801251:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801255:	31 d2                	xor    %edx,%edx
  801257:	f7 f5                	div    %ebp
  801259:	89 c8                	mov    %ecx,%eax
  80125b:	f7 f5                	div    %ebp
  80125d:	eb 84                	jmp    8011e3 <__umoddi3+0x43>
  80125f:	90                   	nop
  801260:	89 c8                	mov    %ecx,%eax
  801262:	89 fa                	mov    %edi,%edx
  801264:	8b 74 24 20          	mov    0x20(%esp),%esi
  801268:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80126c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801270:	83 c4 2c             	add    $0x2c,%esp
  801273:	c3                   	ret    
  801274:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801278:	8b 44 24 10          	mov    0x10(%esp),%eax
  80127c:	be 20 00 00 00       	mov    $0x20,%esi
  801281:	89 e9                	mov    %ebp,%ecx
  801283:	29 ee                	sub    %ebp,%esi
  801285:	d3 e2                	shl    %cl,%edx
  801287:	89 f1                	mov    %esi,%ecx
  801289:	d3 e8                	shr    %cl,%eax
  80128b:	89 e9                	mov    %ebp,%ecx
  80128d:	09 d0                	or     %edx,%eax
  80128f:	89 fa                	mov    %edi,%edx
  801291:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801295:	8b 44 24 10          	mov    0x10(%esp),%eax
  801299:	d3 e0                	shl    %cl,%eax
  80129b:	89 f1                	mov    %esi,%ecx
  80129d:	89 44 24 10          	mov    %eax,0x10(%esp)
  8012a1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  8012a5:	d3 ea                	shr    %cl,%edx
  8012a7:	89 e9                	mov    %ebp,%ecx
  8012a9:	d3 e7                	shl    %cl,%edi
  8012ab:	89 f1                	mov    %esi,%ecx
  8012ad:	d3 e8                	shr    %cl,%eax
  8012af:	89 e9                	mov    %ebp,%ecx
  8012b1:	09 f8                	or     %edi,%eax
  8012b3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  8012b7:	f7 74 24 0c          	divl   0xc(%esp)
  8012bb:	d3 e7                	shl    %cl,%edi
  8012bd:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8012c1:	89 d7                	mov    %edx,%edi
  8012c3:	f7 64 24 10          	mull   0x10(%esp)
  8012c7:	39 d7                	cmp    %edx,%edi
  8012c9:	89 c1                	mov    %eax,%ecx
  8012cb:	89 54 24 14          	mov    %edx,0x14(%esp)
  8012cf:	72 3b                	jb     80130c <__umoddi3+0x16c>
  8012d1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  8012d5:	72 31                	jb     801308 <__umoddi3+0x168>
  8012d7:	8b 44 24 18          	mov    0x18(%esp),%eax
  8012db:	29 c8                	sub    %ecx,%eax
  8012dd:	19 d7                	sbb    %edx,%edi
  8012df:	89 e9                	mov    %ebp,%ecx
  8012e1:	89 fa                	mov    %edi,%edx
  8012e3:	d3 e8                	shr    %cl,%eax
  8012e5:	89 f1                	mov    %esi,%ecx
  8012e7:	d3 e2                	shl    %cl,%edx
  8012e9:	89 e9                	mov    %ebp,%ecx
  8012eb:	09 d0                	or     %edx,%eax
  8012ed:	89 fa                	mov    %edi,%edx
  8012ef:	d3 ea                	shr    %cl,%edx
  8012f1:	8b 74 24 20          	mov    0x20(%esp),%esi
  8012f5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8012f9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8012fd:	83 c4 2c             	add    $0x2c,%esp
  801300:	c3                   	ret    
  801301:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801308:	39 d7                	cmp    %edx,%edi
  80130a:	75 cb                	jne    8012d7 <__umoddi3+0x137>
  80130c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801310:	89 c1                	mov    %eax,%ecx
  801312:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801316:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80131a:	eb bb                	jmp    8012d7 <__umoddi3+0x137>
  80131c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801320:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801324:	0f 82 e8 fe ff ff    	jb     801212 <__umoddi3+0x72>
  80132a:	e9 f3 fe ff ff       	jmp    801222 <__umoddi3+0x82>

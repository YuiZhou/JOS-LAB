
obj/user/badsegment：     文件格式 elf32-i386


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
  80002c:	e8 0f 00 00 00       	call   800040 <libmain>
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
	// Try to load the kernel's TSS selector into the DS register.
	asm volatile("movw $0x28,%ax; movw %ax,%ds");
  800037:	66 b8 28 00          	mov    $0x28,%ax
  80003b:	8e d8                	mov    %eax,%ds
}
  80003d:	5d                   	pop    %ebp
  80003e:	c3                   	ret    
  80003f:	90                   	nop

00800040 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	57                   	push   %edi
  800044:	56                   	push   %esi
  800045:	53                   	push   %ebx
  800046:	83 ec 1c             	sub    $0x1c,%esp
  800049:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80004c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  80004f:	e8 30 01 00 00       	call   800184 <sys_getenvid>
	thisenv = envs;
  800054:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  80005b:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  80005e:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  800064:	39 c2                	cmp    %eax,%edx
  800066:	74 25                	je     80008d <libmain+0x4d>
  800068:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  80006d:	eb 12                	jmp    800081 <libmain+0x41>
  80006f:	8b 4a 48             	mov    0x48(%edx),%ecx
  800072:	83 c2 7c             	add    $0x7c,%edx
  800075:	39 c1                	cmp    %eax,%ecx
  800077:	75 08                	jne    800081 <libmain+0x41>
  800079:	89 3d 04 20 80 00    	mov    %edi,0x802004
  80007f:	eb 0c                	jmp    80008d <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  800081:	89 d7                	mov    %edx,%edi
  800083:	85 d2                	test   %edx,%edx
  800085:	75 e8                	jne    80006f <libmain+0x2f>
  800087:	89 15 04 20 80 00    	mov    %edx,0x802004
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80008d:	85 db                	test   %ebx,%ebx
  80008f:	7e 07                	jle    800098 <libmain+0x58>
		binaryname = argv[0];
  800091:	8b 06                	mov    (%esi),%eax
  800093:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800098:	89 74 24 04          	mov    %esi,0x4(%esp)
  80009c:	89 1c 24             	mov    %ebx,(%esp)
  80009f:	e8 90 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  8000a4:	e8 0b 00 00 00       	call   8000b4 <exit>
}
  8000a9:	83 c4 1c             	add    $0x1c,%esp
  8000ac:	5b                   	pop    %ebx
  8000ad:	5e                   	pop    %esi
  8000ae:	5f                   	pop    %edi
  8000af:	5d                   	pop    %ebp
  8000b0:	c3                   	ret    
  8000b1:	66 90                	xchg   %ax,%ax
  8000b3:	90                   	nop

008000b4 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000b4:	55                   	push   %ebp
  8000b5:	89 e5                	mov    %esp,%ebp
  8000b7:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000c1:	e8 61 00 00 00       	call   800127 <sys_env_destroy>
}
  8000c6:	c9                   	leave  
  8000c7:	c3                   	ret    

008000c8 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000c8:	55                   	push   %ebp
  8000c9:	89 e5                	mov    %esp,%ebp
  8000cb:	83 ec 0c             	sub    $0xc,%esp
  8000ce:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000d1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000d4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d7:	b8 00 00 00 00       	mov    $0x0,%eax
  8000dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000df:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e2:	89 c3                	mov    %eax,%ebx
  8000e4:	89 c7                	mov    %eax,%edi
  8000e6:	89 c6                	mov    %eax,%esi
  8000e8:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000ea:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000ed:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000f0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000f3:	89 ec                	mov    %ebp,%esp
  8000f5:	5d                   	pop    %ebp
  8000f6:	c3                   	ret    

008000f7 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000f7:	55                   	push   %ebp
  8000f8:	89 e5                	mov    %esp,%ebp
  8000fa:	83 ec 0c             	sub    $0xc,%esp
  8000fd:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800100:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800103:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800106:	ba 00 00 00 00       	mov    $0x0,%edx
  80010b:	b8 01 00 00 00       	mov    $0x1,%eax
  800110:	89 d1                	mov    %edx,%ecx
  800112:	89 d3                	mov    %edx,%ebx
  800114:	89 d7                	mov    %edx,%edi
  800116:	89 d6                	mov    %edx,%esi
  800118:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  80011a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80011d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800120:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800123:	89 ec                	mov    %ebp,%esp
  800125:	5d                   	pop    %ebp
  800126:	c3                   	ret    

00800127 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800127:	55                   	push   %ebp
  800128:	89 e5                	mov    %esp,%ebp
  80012a:	83 ec 38             	sub    $0x38,%esp
  80012d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800130:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800133:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800136:	b9 00 00 00 00       	mov    $0x0,%ecx
  80013b:	b8 03 00 00 00       	mov    $0x3,%eax
  800140:	8b 55 08             	mov    0x8(%ebp),%edx
  800143:	89 cb                	mov    %ecx,%ebx
  800145:	89 cf                	mov    %ecx,%edi
  800147:	89 ce                	mov    %ecx,%esi
  800149:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80014b:	85 c0                	test   %eax,%eax
  80014d:	7e 28                	jle    800177 <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  80014f:	89 44 24 10          	mov    %eax,0x10(%esp)
  800153:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  80015a:	00 
  80015b:	c7 44 24 08 ca 12 80 	movl   $0x8012ca,0x8(%esp)
  800162:	00 
  800163:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80016a:	00 
  80016b:	c7 04 24 e7 12 80 00 	movl   $0x8012e7,(%esp)
  800172:	e8 d5 02 00 00       	call   80044c <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800177:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80017a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80017d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800180:	89 ec                	mov    %ebp,%esp
  800182:	5d                   	pop    %ebp
  800183:	c3                   	ret    

00800184 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800184:	55                   	push   %ebp
  800185:	89 e5                	mov    %esp,%ebp
  800187:	83 ec 0c             	sub    $0xc,%esp
  80018a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80018d:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800190:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800193:	ba 00 00 00 00       	mov    $0x0,%edx
  800198:	b8 02 00 00 00       	mov    $0x2,%eax
  80019d:	89 d1                	mov    %edx,%ecx
  80019f:	89 d3                	mov    %edx,%ebx
  8001a1:	89 d7                	mov    %edx,%edi
  8001a3:	89 d6                	mov    %edx,%esi
  8001a5:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  8001a7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8001aa:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8001ad:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8001b0:	89 ec                	mov    %ebp,%esp
  8001b2:	5d                   	pop    %ebp
  8001b3:	c3                   	ret    

008001b4 <sys_yield>:

void
sys_yield(void)
{
  8001b4:	55                   	push   %ebp
  8001b5:	89 e5                	mov    %esp,%ebp
  8001b7:	83 ec 0c             	sub    $0xc,%esp
  8001ba:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8001bd:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8001c0:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001c3:	ba 00 00 00 00       	mov    $0x0,%edx
  8001c8:	b8 0a 00 00 00       	mov    $0xa,%eax
  8001cd:	89 d1                	mov    %edx,%ecx
  8001cf:	89 d3                	mov    %edx,%ebx
  8001d1:	89 d7                	mov    %edx,%edi
  8001d3:	89 d6                	mov    %edx,%esi
  8001d5:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  8001d7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8001da:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8001dd:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8001e0:	89 ec                	mov    %ebp,%esp
  8001e2:	5d                   	pop    %ebp
  8001e3:	c3                   	ret    

008001e4 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  8001e4:	55                   	push   %ebp
  8001e5:	89 e5                	mov    %esp,%ebp
  8001e7:	83 ec 38             	sub    $0x38,%esp
  8001ea:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8001ed:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8001f0:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001f3:	be 00 00 00 00       	mov    $0x0,%esi
  8001f8:	b8 04 00 00 00       	mov    $0x4,%eax
  8001fd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800200:	8b 55 08             	mov    0x8(%ebp),%edx
  800203:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800206:	89 f7                	mov    %esi,%edi
  800208:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80020a:	85 c0                	test   %eax,%eax
  80020c:	7e 28                	jle    800236 <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  80020e:	89 44 24 10          	mov    %eax,0x10(%esp)
  800212:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800219:	00 
  80021a:	c7 44 24 08 ca 12 80 	movl   $0x8012ca,0x8(%esp)
  800221:	00 
  800222:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800229:	00 
  80022a:	c7 04 24 e7 12 80 00 	movl   $0x8012e7,(%esp)
  800231:	e8 16 02 00 00       	call   80044c <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800236:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800239:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80023c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80023f:	89 ec                	mov    %ebp,%esp
  800241:	5d                   	pop    %ebp
  800242:	c3                   	ret    

00800243 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800243:	55                   	push   %ebp
  800244:	89 e5                	mov    %esp,%ebp
  800246:	83 ec 38             	sub    $0x38,%esp
  800249:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80024c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80024f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800252:	b8 05 00 00 00       	mov    $0x5,%eax
  800257:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80025a:	8b 55 08             	mov    0x8(%ebp),%edx
  80025d:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800260:	8b 7d 14             	mov    0x14(%ebp),%edi
  800263:	8b 75 18             	mov    0x18(%ebp),%esi
  800266:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800268:	85 c0                	test   %eax,%eax
  80026a:	7e 28                	jle    800294 <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  80026c:	89 44 24 10          	mov    %eax,0x10(%esp)
  800270:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800277:	00 
  800278:	c7 44 24 08 ca 12 80 	movl   $0x8012ca,0x8(%esp)
  80027f:	00 
  800280:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800287:	00 
  800288:	c7 04 24 e7 12 80 00 	movl   $0x8012e7,(%esp)
  80028f:	e8 b8 01 00 00       	call   80044c <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800294:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800297:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80029a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80029d:	89 ec                	mov    %ebp,%esp
  80029f:	5d                   	pop    %ebp
  8002a0:	c3                   	ret    

008002a1 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8002a1:	55                   	push   %ebp
  8002a2:	89 e5                	mov    %esp,%ebp
  8002a4:	83 ec 38             	sub    $0x38,%esp
  8002a7:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8002aa:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8002ad:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002b0:	bb 00 00 00 00       	mov    $0x0,%ebx
  8002b5:	b8 06 00 00 00       	mov    $0x6,%eax
  8002ba:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002bd:	8b 55 08             	mov    0x8(%ebp),%edx
  8002c0:	89 df                	mov    %ebx,%edi
  8002c2:	89 de                	mov    %ebx,%esi
  8002c4:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8002c6:	85 c0                	test   %eax,%eax
  8002c8:	7e 28                	jle    8002f2 <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002ca:	89 44 24 10          	mov    %eax,0x10(%esp)
  8002ce:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  8002d5:	00 
  8002d6:	c7 44 24 08 ca 12 80 	movl   $0x8012ca,0x8(%esp)
  8002dd:	00 
  8002de:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8002e5:	00 
  8002e6:	c7 04 24 e7 12 80 00 	movl   $0x8012e7,(%esp)
  8002ed:	e8 5a 01 00 00       	call   80044c <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  8002f2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8002f5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8002f8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8002fb:	89 ec                	mov    %ebp,%esp
  8002fd:	5d                   	pop    %ebp
  8002fe:	c3                   	ret    

008002ff <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  8002ff:	55                   	push   %ebp
  800300:	89 e5                	mov    %esp,%ebp
  800302:	83 ec 38             	sub    $0x38,%esp
  800305:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800308:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80030b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80030e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800313:	b8 08 00 00 00       	mov    $0x8,%eax
  800318:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80031b:	8b 55 08             	mov    0x8(%ebp),%edx
  80031e:	89 df                	mov    %ebx,%edi
  800320:	89 de                	mov    %ebx,%esi
  800322:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800324:	85 c0                	test   %eax,%eax
  800326:	7e 28                	jle    800350 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800328:	89 44 24 10          	mov    %eax,0x10(%esp)
  80032c:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800333:	00 
  800334:	c7 44 24 08 ca 12 80 	movl   $0x8012ca,0x8(%esp)
  80033b:	00 
  80033c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800343:	00 
  800344:	c7 04 24 e7 12 80 00 	movl   $0x8012e7,(%esp)
  80034b:	e8 fc 00 00 00       	call   80044c <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800350:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800353:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800356:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800359:	89 ec                	mov    %ebp,%esp
  80035b:	5d                   	pop    %ebp
  80035c:	c3                   	ret    

0080035d <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  80035d:	55                   	push   %ebp
  80035e:	89 e5                	mov    %esp,%ebp
  800360:	83 ec 38             	sub    $0x38,%esp
  800363:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800366:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800369:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80036c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800371:	b8 09 00 00 00       	mov    $0x9,%eax
  800376:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800379:	8b 55 08             	mov    0x8(%ebp),%edx
  80037c:	89 df                	mov    %ebx,%edi
  80037e:	89 de                	mov    %ebx,%esi
  800380:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800382:	85 c0                	test   %eax,%eax
  800384:	7e 28                	jle    8003ae <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  800386:	89 44 24 10          	mov    %eax,0x10(%esp)
  80038a:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800391:	00 
  800392:	c7 44 24 08 ca 12 80 	movl   $0x8012ca,0x8(%esp)
  800399:	00 
  80039a:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8003a1:	00 
  8003a2:	c7 04 24 e7 12 80 00 	movl   $0x8012e7,(%esp)
  8003a9:	e8 9e 00 00 00       	call   80044c <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8003ae:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8003b1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8003b4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8003b7:	89 ec                	mov    %ebp,%esp
  8003b9:	5d                   	pop    %ebp
  8003ba:	c3                   	ret    

008003bb <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8003bb:	55                   	push   %ebp
  8003bc:	89 e5                	mov    %esp,%ebp
  8003be:	83 ec 0c             	sub    $0xc,%esp
  8003c1:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8003c4:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8003c7:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8003ca:	be 00 00 00 00       	mov    $0x0,%esi
  8003cf:	b8 0b 00 00 00       	mov    $0xb,%eax
  8003d4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8003d7:	8b 55 08             	mov    0x8(%ebp),%edx
  8003da:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003dd:	8b 7d 14             	mov    0x14(%ebp),%edi
  8003e0:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8003e2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8003e5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8003e8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8003eb:	89 ec                	mov    %ebp,%esp
  8003ed:	5d                   	pop    %ebp
  8003ee:	c3                   	ret    

008003ef <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8003ef:	55                   	push   %ebp
  8003f0:	89 e5                	mov    %esp,%ebp
  8003f2:	83 ec 38             	sub    $0x38,%esp
  8003f5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8003f8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8003fb:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8003fe:	b9 00 00 00 00       	mov    $0x0,%ecx
  800403:	b8 0c 00 00 00       	mov    $0xc,%eax
  800408:	8b 55 08             	mov    0x8(%ebp),%edx
  80040b:	89 cb                	mov    %ecx,%ebx
  80040d:	89 cf                	mov    %ecx,%edi
  80040f:	89 ce                	mov    %ecx,%esi
  800411:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800413:	85 c0                	test   %eax,%eax
  800415:	7e 28                	jle    80043f <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800417:	89 44 24 10          	mov    %eax,0x10(%esp)
  80041b:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800422:	00 
  800423:	c7 44 24 08 ca 12 80 	movl   $0x8012ca,0x8(%esp)
  80042a:	00 
  80042b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800432:	00 
  800433:	c7 04 24 e7 12 80 00 	movl   $0x8012e7,(%esp)
  80043a:	e8 0d 00 00 00       	call   80044c <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  80043f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800442:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800445:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800448:	89 ec                	mov    %ebp,%esp
  80044a:	5d                   	pop    %ebp
  80044b:	c3                   	ret    

0080044c <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80044c:	55                   	push   %ebp
  80044d:	89 e5                	mov    %esp,%ebp
  80044f:	56                   	push   %esi
  800450:	53                   	push   %ebx
  800451:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800454:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800457:	a1 08 20 80 00       	mov    0x802008,%eax
  80045c:	85 c0                	test   %eax,%eax
  80045e:	74 10                	je     800470 <_panic+0x24>
		cprintf("%s: ", argv0);
  800460:	89 44 24 04          	mov    %eax,0x4(%esp)
  800464:	c7 04 24 f5 12 80 00 	movl   $0x8012f5,(%esp)
  80046b:	e8 ef 00 00 00       	call   80055f <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800470:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800476:	e8 09 fd ff ff       	call   800184 <sys_getenvid>
  80047b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80047e:	89 54 24 10          	mov    %edx,0x10(%esp)
  800482:	8b 55 08             	mov    0x8(%ebp),%edx
  800485:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800489:	89 74 24 08          	mov    %esi,0x8(%esp)
  80048d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800491:	c7 04 24 fc 12 80 00 	movl   $0x8012fc,(%esp)
  800498:	e8 c2 00 00 00       	call   80055f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80049d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004a1:	8b 45 10             	mov    0x10(%ebp),%eax
  8004a4:	89 04 24             	mov    %eax,(%esp)
  8004a7:	e8 52 00 00 00       	call   8004fe <vcprintf>
	cprintf("\n");
  8004ac:	c7 04 24 fa 12 80 00 	movl   $0x8012fa,(%esp)
  8004b3:	e8 a7 00 00 00       	call   80055f <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8004b8:	cc                   	int3   
  8004b9:	eb fd                	jmp    8004b8 <_panic+0x6c>
  8004bb:	90                   	nop

008004bc <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8004bc:	55                   	push   %ebp
  8004bd:	89 e5                	mov    %esp,%ebp
  8004bf:	53                   	push   %ebx
  8004c0:	83 ec 14             	sub    $0x14,%esp
  8004c3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8004c6:	8b 03                	mov    (%ebx),%eax
  8004c8:	8b 55 08             	mov    0x8(%ebp),%edx
  8004cb:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8004cf:	83 c0 01             	add    $0x1,%eax
  8004d2:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8004d4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8004d9:	75 19                	jne    8004f4 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8004db:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8004e2:	00 
  8004e3:	8d 43 08             	lea    0x8(%ebx),%eax
  8004e6:	89 04 24             	mov    %eax,(%esp)
  8004e9:	e8 da fb ff ff       	call   8000c8 <sys_cputs>
		b->idx = 0;
  8004ee:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8004f4:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8004f8:	83 c4 14             	add    $0x14,%esp
  8004fb:	5b                   	pop    %ebx
  8004fc:	5d                   	pop    %ebp
  8004fd:	c3                   	ret    

008004fe <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8004fe:	55                   	push   %ebp
  8004ff:	89 e5                	mov    %esp,%ebp
  800501:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800507:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80050e:	00 00 00 
	b.cnt = 0;
  800511:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800518:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80051b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80051e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800522:	8b 45 08             	mov    0x8(%ebp),%eax
  800525:	89 44 24 08          	mov    %eax,0x8(%esp)
  800529:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80052f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800533:	c7 04 24 bc 04 80 00 	movl   $0x8004bc,(%esp)
  80053a:	e8 b3 01 00 00       	call   8006f2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80053f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800545:	89 44 24 04          	mov    %eax,0x4(%esp)
  800549:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80054f:	89 04 24             	mov    %eax,(%esp)
  800552:	e8 71 fb ff ff       	call   8000c8 <sys_cputs>

	return b.cnt;
}
  800557:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80055d:	c9                   	leave  
  80055e:	c3                   	ret    

0080055f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80055f:	55                   	push   %ebp
  800560:	89 e5                	mov    %esp,%ebp
  800562:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800565:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800568:	89 44 24 04          	mov    %eax,0x4(%esp)
  80056c:	8b 45 08             	mov    0x8(%ebp),%eax
  80056f:	89 04 24             	mov    %eax,(%esp)
  800572:	e8 87 ff ff ff       	call   8004fe <vcprintf>
	va_end(ap);

	return cnt;
}
  800577:	c9                   	leave  
  800578:	c3                   	ret    
  800579:	66 90                	xchg   %ax,%ax
  80057b:	66 90                	xchg   %ax,%ax
  80057d:	66 90                	xchg   %ax,%ax
  80057f:	90                   	nop

00800580 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800580:	55                   	push   %ebp
  800581:	89 e5                	mov    %esp,%ebp
  800583:	57                   	push   %edi
  800584:	56                   	push   %esi
  800585:	53                   	push   %ebx
  800586:	83 ec 4c             	sub    $0x4c,%esp
  800589:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80058c:	89 d7                	mov    %edx,%edi
  80058e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800591:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800594:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800597:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80059a:	b8 00 00 00 00       	mov    $0x0,%eax
  80059f:	39 d8                	cmp    %ebx,%eax
  8005a1:	72 17                	jb     8005ba <printnum+0x3a>
  8005a3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8005a6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8005a9:	76 0f                	jbe    8005ba <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8005ab:	8b 75 14             	mov    0x14(%ebp),%esi
  8005ae:	83 ee 01             	sub    $0x1,%esi
  8005b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005b4:	85 f6                	test   %esi,%esi
  8005b6:	7f 63                	jg     80061b <printnum+0x9b>
  8005b8:	eb 75                	jmp    80062f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8005ba:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8005bd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8005c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c4:	83 e8 01             	sub    $0x1,%eax
  8005c7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005cb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8005ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8005d2:	8b 44 24 08          	mov    0x8(%esp),%eax
  8005d6:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8005da:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005dd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8005e0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8005e7:	00 
  8005e8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8005eb:	89 1c 24             	mov    %ebx,(%esp)
  8005ee:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8005f1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005f5:	e8 e6 09 00 00       	call   800fe0 <__udivdi3>
  8005fa:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8005fd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800600:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800604:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800608:	89 04 24             	mov    %eax,(%esp)
  80060b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80060f:	89 fa                	mov    %edi,%edx
  800611:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800614:	e8 67 ff ff ff       	call   800580 <printnum>
  800619:	eb 14                	jmp    80062f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80061b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80061f:	8b 45 18             	mov    0x18(%ebp),%eax
  800622:	89 04 24             	mov    %eax,(%esp)
  800625:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800627:	83 ee 01             	sub    $0x1,%esi
  80062a:	75 ef                	jne    80061b <printnum+0x9b>
  80062c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80062f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800633:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800637:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80063a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80063e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800645:	00 
  800646:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800649:	89 1c 24             	mov    %ebx,(%esp)
  80064c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80064f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800653:	e8 d8 0a 00 00       	call   801130 <__umoddi3>
  800658:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80065c:	0f be 80 20 13 80 00 	movsbl 0x801320(%eax),%eax
  800663:	89 04 24             	mov    %eax,(%esp)
  800666:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800669:	ff d0                	call   *%eax
}
  80066b:	83 c4 4c             	add    $0x4c,%esp
  80066e:	5b                   	pop    %ebx
  80066f:	5e                   	pop    %esi
  800670:	5f                   	pop    %edi
  800671:	5d                   	pop    %ebp
  800672:	c3                   	ret    

00800673 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800673:	55                   	push   %ebp
  800674:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800676:	83 fa 01             	cmp    $0x1,%edx
  800679:	7e 0e                	jle    800689 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80067b:	8b 10                	mov    (%eax),%edx
  80067d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800680:	89 08                	mov    %ecx,(%eax)
  800682:	8b 02                	mov    (%edx),%eax
  800684:	8b 52 04             	mov    0x4(%edx),%edx
  800687:	eb 22                	jmp    8006ab <getuint+0x38>
	else if (lflag)
  800689:	85 d2                	test   %edx,%edx
  80068b:	74 10                	je     80069d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80068d:	8b 10                	mov    (%eax),%edx
  80068f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800692:	89 08                	mov    %ecx,(%eax)
  800694:	8b 02                	mov    (%edx),%eax
  800696:	ba 00 00 00 00       	mov    $0x0,%edx
  80069b:	eb 0e                	jmp    8006ab <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80069d:	8b 10                	mov    (%eax),%edx
  80069f:	8d 4a 04             	lea    0x4(%edx),%ecx
  8006a2:	89 08                	mov    %ecx,(%eax)
  8006a4:	8b 02                	mov    (%edx),%eax
  8006a6:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8006ab:	5d                   	pop    %ebp
  8006ac:	c3                   	ret    

008006ad <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8006ad:	55                   	push   %ebp
  8006ae:	89 e5                	mov    %esp,%ebp
  8006b0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8006b3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8006b7:	8b 10                	mov    (%eax),%edx
  8006b9:	3b 50 04             	cmp    0x4(%eax),%edx
  8006bc:	73 0a                	jae    8006c8 <sprintputch+0x1b>
		*b->buf++ = ch;
  8006be:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006c1:	88 0a                	mov    %cl,(%edx)
  8006c3:	83 c2 01             	add    $0x1,%edx
  8006c6:	89 10                	mov    %edx,(%eax)
}
  8006c8:	5d                   	pop    %ebp
  8006c9:	c3                   	ret    

008006ca <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8006ca:	55                   	push   %ebp
  8006cb:	89 e5                	mov    %esp,%ebp
  8006cd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8006d0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8006d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006d7:	8b 45 10             	mov    0x10(%ebp),%eax
  8006da:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006de:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006e5:	8b 45 08             	mov    0x8(%ebp),%eax
  8006e8:	89 04 24             	mov    %eax,(%esp)
  8006eb:	e8 02 00 00 00       	call   8006f2 <vprintfmt>
	va_end(ap);
}
  8006f0:	c9                   	leave  
  8006f1:	c3                   	ret    

008006f2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8006f2:	55                   	push   %ebp
  8006f3:	89 e5                	mov    %esp,%ebp
  8006f5:	57                   	push   %edi
  8006f6:	56                   	push   %esi
  8006f7:	53                   	push   %ebx
  8006f8:	83 ec 4c             	sub    $0x4c,%esp
  8006fb:	8b 75 08             	mov    0x8(%ebp),%esi
  8006fe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800701:	8b 7d 10             	mov    0x10(%ebp),%edi
  800704:	eb 11                	jmp    800717 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800706:	85 c0                	test   %eax,%eax
  800708:	0f 84 db 03 00 00    	je     800ae9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  80070e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800712:	89 04 24             	mov    %eax,(%esp)
  800715:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800717:	0f b6 07             	movzbl (%edi),%eax
  80071a:	83 c7 01             	add    $0x1,%edi
  80071d:	83 f8 25             	cmp    $0x25,%eax
  800720:	75 e4                	jne    800706 <vprintfmt+0x14>
  800722:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800726:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  80072d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800734:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80073b:	ba 00 00 00 00       	mov    $0x0,%edx
  800740:	eb 2b                	jmp    80076d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800742:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800745:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800749:	eb 22                	jmp    80076d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80074b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80074e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800752:	eb 19                	jmp    80076d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800754:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800757:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80075e:	eb 0d                	jmp    80076d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800760:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800763:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800766:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80076d:	0f b6 0f             	movzbl (%edi),%ecx
  800770:	8d 47 01             	lea    0x1(%edi),%eax
  800773:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800776:	0f b6 07             	movzbl (%edi),%eax
  800779:	83 e8 23             	sub    $0x23,%eax
  80077c:	3c 55                	cmp    $0x55,%al
  80077e:	0f 87 40 03 00 00    	ja     800ac4 <vprintfmt+0x3d2>
  800784:	0f b6 c0             	movzbl %al,%eax
  800787:	ff 24 85 e0 13 80 00 	jmp    *0x8013e0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80078e:	83 e9 30             	sub    $0x30,%ecx
  800791:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800794:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800798:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80079b:	83 f9 09             	cmp    $0x9,%ecx
  80079e:	77 57                	ja     8007f7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007a0:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007a3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8007a6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8007a9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  8007ac:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8007af:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8007b3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8007b6:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8007b9:	83 f9 09             	cmp    $0x9,%ecx
  8007bc:	76 eb                	jbe    8007a9 <vprintfmt+0xb7>
  8007be:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8007c1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  8007c4:	eb 34                	jmp    8007fa <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8007c6:	8b 45 14             	mov    0x14(%ebp),%eax
  8007c9:	8d 48 04             	lea    0x4(%eax),%ecx
  8007cc:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8007cf:	8b 00                	mov    (%eax),%eax
  8007d1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007d4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8007d7:	eb 21                	jmp    8007fa <vprintfmt+0x108>

		case '.':
			if (width < 0)
  8007d9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8007dd:	0f 88 71 ff ff ff    	js     800754 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007e3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007e6:	eb 85                	jmp    80076d <vprintfmt+0x7b>
  8007e8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8007eb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8007f2:	e9 76 ff ff ff       	jmp    80076d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007f7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8007fa:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8007fe:	0f 89 69 ff ff ff    	jns    80076d <vprintfmt+0x7b>
  800804:	e9 57 ff ff ff       	jmp    800760 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800809:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80080c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80080f:	e9 59 ff ff ff       	jmp    80076d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800814:	8b 45 14             	mov    0x14(%ebp),%eax
  800817:	8d 50 04             	lea    0x4(%eax),%edx
  80081a:	89 55 14             	mov    %edx,0x14(%ebp)
  80081d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800821:	8b 00                	mov    (%eax),%eax
  800823:	89 04 24             	mov    %eax,(%esp)
  800826:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800828:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80082b:	e9 e7 fe ff ff       	jmp    800717 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800830:	8b 45 14             	mov    0x14(%ebp),%eax
  800833:	8d 50 04             	lea    0x4(%eax),%edx
  800836:	89 55 14             	mov    %edx,0x14(%ebp)
  800839:	8b 00                	mov    (%eax),%eax
  80083b:	89 c2                	mov    %eax,%edx
  80083d:	c1 fa 1f             	sar    $0x1f,%edx
  800840:	31 d0                	xor    %edx,%eax
  800842:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800844:	83 f8 08             	cmp    $0x8,%eax
  800847:	7f 0b                	jg     800854 <vprintfmt+0x162>
  800849:	8b 14 85 40 15 80 00 	mov    0x801540(,%eax,4),%edx
  800850:	85 d2                	test   %edx,%edx
  800852:	75 20                	jne    800874 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800854:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800858:	c7 44 24 08 38 13 80 	movl   $0x801338,0x8(%esp)
  80085f:	00 
  800860:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800864:	89 34 24             	mov    %esi,(%esp)
  800867:	e8 5e fe ff ff       	call   8006ca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80086c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80086f:	e9 a3 fe ff ff       	jmp    800717 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800874:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800878:	c7 44 24 08 41 13 80 	movl   $0x801341,0x8(%esp)
  80087f:	00 
  800880:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800884:	89 34 24             	mov    %esi,(%esp)
  800887:	e8 3e fe ff ff       	call   8006ca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80088c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80088f:	e9 83 fe ff ff       	jmp    800717 <vprintfmt+0x25>
  800894:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800897:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80089a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80089d:	8b 45 14             	mov    0x14(%ebp),%eax
  8008a0:	8d 50 04             	lea    0x4(%eax),%edx
  8008a3:	89 55 14             	mov    %edx,0x14(%ebp)
  8008a6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8008a8:	85 ff                	test   %edi,%edi
  8008aa:	b8 31 13 80 00       	mov    $0x801331,%eax
  8008af:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8008b2:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8008b6:	74 06                	je     8008be <vprintfmt+0x1cc>
  8008b8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8008bc:	7f 16                	jg     8008d4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8008be:	0f b6 17             	movzbl (%edi),%edx
  8008c1:	0f be c2             	movsbl %dl,%eax
  8008c4:	83 c7 01             	add    $0x1,%edi
  8008c7:	85 c0                	test   %eax,%eax
  8008c9:	0f 85 9f 00 00 00    	jne    80096e <vprintfmt+0x27c>
  8008cf:	e9 8b 00 00 00       	jmp    80095f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8008d4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8008d8:	89 3c 24             	mov    %edi,(%esp)
  8008db:	e8 c2 02 00 00       	call   800ba2 <strnlen>
  8008e0:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8008e3:	29 c2                	sub    %eax,%edx
  8008e5:	89 55 d8             	mov    %edx,-0x28(%ebp)
  8008e8:	85 d2                	test   %edx,%edx
  8008ea:	7e d2                	jle    8008be <vprintfmt+0x1cc>
					putch(padc, putdat);
  8008ec:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8008f0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8008f3:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8008f6:	89 d7                	mov    %edx,%edi
  8008f8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8008fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8008ff:	89 04 24             	mov    %eax,(%esp)
  800902:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800904:	83 ef 01             	sub    $0x1,%edi
  800907:	75 ef                	jne    8008f8 <vprintfmt+0x206>
  800909:	89 7d d8             	mov    %edi,-0x28(%ebp)
  80090c:	8b 7d cc             	mov    -0x34(%ebp),%edi
  80090f:	eb ad                	jmp    8008be <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800911:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800915:	74 20                	je     800937 <vprintfmt+0x245>
  800917:	0f be d2             	movsbl %dl,%edx
  80091a:	83 ea 20             	sub    $0x20,%edx
  80091d:	83 fa 5e             	cmp    $0x5e,%edx
  800920:	76 15                	jbe    800937 <vprintfmt+0x245>
					putch('?', putdat);
  800922:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800925:	89 54 24 04          	mov    %edx,0x4(%esp)
  800929:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800930:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800933:	ff d1                	call   *%ecx
  800935:	eb 0f                	jmp    800946 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800937:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80093a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80093e:	89 04 24             	mov    %eax,(%esp)
  800941:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800944:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800946:	83 eb 01             	sub    $0x1,%ebx
  800949:	0f b6 17             	movzbl (%edi),%edx
  80094c:	0f be c2             	movsbl %dl,%eax
  80094f:	83 c7 01             	add    $0x1,%edi
  800952:	85 c0                	test   %eax,%eax
  800954:	75 24                	jne    80097a <vprintfmt+0x288>
  800956:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800959:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80095c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80095f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800962:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800966:	0f 8e ab fd ff ff    	jle    800717 <vprintfmt+0x25>
  80096c:	eb 20                	jmp    80098e <vprintfmt+0x29c>
  80096e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800971:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800974:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800977:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80097a:	85 f6                	test   %esi,%esi
  80097c:	78 93                	js     800911 <vprintfmt+0x21f>
  80097e:	83 ee 01             	sub    $0x1,%esi
  800981:	79 8e                	jns    800911 <vprintfmt+0x21f>
  800983:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800986:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800989:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80098c:	eb d1                	jmp    80095f <vprintfmt+0x26d>
  80098e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800991:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800995:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80099c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80099e:	83 ef 01             	sub    $0x1,%edi
  8009a1:	75 ee                	jne    800991 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8009a3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8009a6:	e9 6c fd ff ff       	jmp    800717 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8009ab:	83 fa 01             	cmp    $0x1,%edx
  8009ae:	66 90                	xchg   %ax,%ax
  8009b0:	7e 16                	jle    8009c8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  8009b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8009b5:	8d 50 08             	lea    0x8(%eax),%edx
  8009b8:	89 55 14             	mov    %edx,0x14(%ebp)
  8009bb:	8b 10                	mov    (%eax),%edx
  8009bd:	8b 48 04             	mov    0x4(%eax),%ecx
  8009c0:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8009c3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8009c6:	eb 32                	jmp    8009fa <vprintfmt+0x308>
	else if (lflag)
  8009c8:	85 d2                	test   %edx,%edx
  8009ca:	74 18                	je     8009e4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  8009cc:	8b 45 14             	mov    0x14(%ebp),%eax
  8009cf:	8d 50 04             	lea    0x4(%eax),%edx
  8009d2:	89 55 14             	mov    %edx,0x14(%ebp)
  8009d5:	8b 00                	mov    (%eax),%eax
  8009d7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8009da:	89 c1                	mov    %eax,%ecx
  8009dc:	c1 f9 1f             	sar    $0x1f,%ecx
  8009df:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8009e2:	eb 16                	jmp    8009fa <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  8009e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8009e7:	8d 50 04             	lea    0x4(%eax),%edx
  8009ea:	89 55 14             	mov    %edx,0x14(%ebp)
  8009ed:	8b 00                	mov    (%eax),%eax
  8009ef:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8009f2:	89 c7                	mov    %eax,%edi
  8009f4:	c1 ff 1f             	sar    $0x1f,%edi
  8009f7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8009fa:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8009fd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800a00:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800a05:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800a09:	79 7d                	jns    800a88 <vprintfmt+0x396>
				putch('-', putdat);
  800a0b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a0f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800a16:	ff d6                	call   *%esi
				num = -(long long) num;
  800a18:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800a1b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800a1e:	f7 d8                	neg    %eax
  800a20:	83 d2 00             	adc    $0x0,%edx
  800a23:	f7 da                	neg    %edx
			}
			base = 10;
  800a25:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800a2a:	eb 5c                	jmp    800a88 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800a2c:	8d 45 14             	lea    0x14(%ebp),%eax
  800a2f:	e8 3f fc ff ff       	call   800673 <getuint>
			base = 10;
  800a34:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800a39:	eb 4d                	jmp    800a88 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800a3b:	8d 45 14             	lea    0x14(%ebp),%eax
  800a3e:	e8 30 fc ff ff       	call   800673 <getuint>
			base = 8;
  800a43:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800a48:	eb 3e                	jmp    800a88 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  800a4a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a4e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800a55:	ff d6                	call   *%esi
			putch('x', putdat);
  800a57:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a5b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800a62:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800a64:	8b 45 14             	mov    0x14(%ebp),%eax
  800a67:	8d 50 04             	lea    0x4(%eax),%edx
  800a6a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800a6d:	8b 00                	mov    (%eax),%eax
  800a6f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800a74:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800a79:	eb 0d                	jmp    800a88 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800a7b:	8d 45 14             	lea    0x14(%ebp),%eax
  800a7e:	e8 f0 fb ff ff       	call   800673 <getuint>
			base = 16;
  800a83:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800a88:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  800a8c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800a90:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800a93:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800a97:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800a9b:	89 04 24             	mov    %eax,(%esp)
  800a9e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800aa2:	89 da                	mov    %ebx,%edx
  800aa4:	89 f0                	mov    %esi,%eax
  800aa6:	e8 d5 fa ff ff       	call   800580 <printnum>
			break;
  800aab:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800aae:	e9 64 fc ff ff       	jmp    800717 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800ab3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ab7:	89 0c 24             	mov    %ecx,(%esp)
  800aba:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800abc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800abf:	e9 53 fc ff ff       	jmp    800717 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800ac4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ac8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800acf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800ad1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800ad5:	0f 84 3c fc ff ff    	je     800717 <vprintfmt+0x25>
  800adb:	83 ef 01             	sub    $0x1,%edi
  800ade:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800ae2:	75 f7                	jne    800adb <vprintfmt+0x3e9>
  800ae4:	e9 2e fc ff ff       	jmp    800717 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800ae9:	83 c4 4c             	add    $0x4c,%esp
  800aec:	5b                   	pop    %ebx
  800aed:	5e                   	pop    %esi
  800aee:	5f                   	pop    %edi
  800aef:	5d                   	pop    %ebp
  800af0:	c3                   	ret    

00800af1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800af1:	55                   	push   %ebp
  800af2:	89 e5                	mov    %esp,%ebp
  800af4:	83 ec 28             	sub    $0x28,%esp
  800af7:	8b 45 08             	mov    0x8(%ebp),%eax
  800afa:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800afd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800b00:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800b04:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800b07:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800b0e:	85 d2                	test   %edx,%edx
  800b10:	7e 30                	jle    800b42 <vsnprintf+0x51>
  800b12:	85 c0                	test   %eax,%eax
  800b14:	74 2c                	je     800b42 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800b16:	8b 45 14             	mov    0x14(%ebp),%eax
  800b19:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b1d:	8b 45 10             	mov    0x10(%ebp),%eax
  800b20:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b24:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800b27:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b2b:	c7 04 24 ad 06 80 00 	movl   $0x8006ad,(%esp)
  800b32:	e8 bb fb ff ff       	call   8006f2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800b37:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800b3a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800b3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800b40:	eb 05                	jmp    800b47 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800b42:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800b47:	c9                   	leave  
  800b48:	c3                   	ret    

00800b49 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800b49:	55                   	push   %ebp
  800b4a:	89 e5                	mov    %esp,%ebp
  800b4c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800b4f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800b52:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b56:	8b 45 10             	mov    0x10(%ebp),%eax
  800b59:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b5d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b60:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b64:	8b 45 08             	mov    0x8(%ebp),%eax
  800b67:	89 04 24             	mov    %eax,(%esp)
  800b6a:	e8 82 ff ff ff       	call   800af1 <vsnprintf>
	va_end(ap);

	return rc;
}
  800b6f:	c9                   	leave  
  800b70:	c3                   	ret    
  800b71:	66 90                	xchg   %ax,%ax
  800b73:	66 90                	xchg   %ax,%ax
  800b75:	66 90                	xchg   %ax,%ax
  800b77:	66 90                	xchg   %ax,%ax
  800b79:	66 90                	xchg   %ax,%ax
  800b7b:	66 90                	xchg   %ax,%ax
  800b7d:	66 90                	xchg   %ax,%ax
  800b7f:	90                   	nop

00800b80 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800b80:	55                   	push   %ebp
  800b81:	89 e5                	mov    %esp,%ebp
  800b83:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800b86:	80 3a 00             	cmpb   $0x0,(%edx)
  800b89:	74 10                	je     800b9b <strlen+0x1b>
  800b8b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800b90:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800b93:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800b97:	75 f7                	jne    800b90 <strlen+0x10>
  800b99:	eb 05                	jmp    800ba0 <strlen+0x20>
  800b9b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800ba0:	5d                   	pop    %ebp
  800ba1:	c3                   	ret    

00800ba2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800ba2:	55                   	push   %ebp
  800ba3:	89 e5                	mov    %esp,%ebp
  800ba5:	53                   	push   %ebx
  800ba6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800ba9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800bac:	85 c9                	test   %ecx,%ecx
  800bae:	74 1c                	je     800bcc <strnlen+0x2a>
  800bb0:	80 3b 00             	cmpb   $0x0,(%ebx)
  800bb3:	74 1e                	je     800bd3 <strnlen+0x31>
  800bb5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  800bba:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800bbc:	39 ca                	cmp    %ecx,%edx
  800bbe:	74 18                	je     800bd8 <strnlen+0x36>
  800bc0:	83 c2 01             	add    $0x1,%edx
  800bc3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800bc8:	75 f0                	jne    800bba <strnlen+0x18>
  800bca:	eb 0c                	jmp    800bd8 <strnlen+0x36>
  800bcc:	b8 00 00 00 00       	mov    $0x0,%eax
  800bd1:	eb 05                	jmp    800bd8 <strnlen+0x36>
  800bd3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800bd8:	5b                   	pop    %ebx
  800bd9:	5d                   	pop    %ebp
  800bda:	c3                   	ret    

00800bdb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800bdb:	55                   	push   %ebp
  800bdc:	89 e5                	mov    %esp,%ebp
  800bde:	53                   	push   %ebx
  800bdf:	8b 45 08             	mov    0x8(%ebp),%eax
  800be2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800be5:	89 c2                	mov    %eax,%edx
  800be7:	0f b6 19             	movzbl (%ecx),%ebx
  800bea:	88 1a                	mov    %bl,(%edx)
  800bec:	83 c2 01             	add    $0x1,%edx
  800bef:	83 c1 01             	add    $0x1,%ecx
  800bf2:	84 db                	test   %bl,%bl
  800bf4:	75 f1                	jne    800be7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800bf6:	5b                   	pop    %ebx
  800bf7:	5d                   	pop    %ebp
  800bf8:	c3                   	ret    

00800bf9 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800bf9:	55                   	push   %ebp
  800bfa:	89 e5                	mov    %esp,%ebp
  800bfc:	53                   	push   %ebx
  800bfd:	83 ec 08             	sub    $0x8,%esp
  800c00:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800c03:	89 1c 24             	mov    %ebx,(%esp)
  800c06:	e8 75 ff ff ff       	call   800b80 <strlen>
	strcpy(dst + len, src);
  800c0b:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c0e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800c12:	01 d8                	add    %ebx,%eax
  800c14:	89 04 24             	mov    %eax,(%esp)
  800c17:	e8 bf ff ff ff       	call   800bdb <strcpy>
	return dst;
}
  800c1c:	89 d8                	mov    %ebx,%eax
  800c1e:	83 c4 08             	add    $0x8,%esp
  800c21:	5b                   	pop    %ebx
  800c22:	5d                   	pop    %ebp
  800c23:	c3                   	ret    

00800c24 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800c24:	55                   	push   %ebp
  800c25:	89 e5                	mov    %esp,%ebp
  800c27:	56                   	push   %esi
  800c28:	53                   	push   %ebx
  800c29:	8b 75 08             	mov    0x8(%ebp),%esi
  800c2c:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c2f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800c32:	85 db                	test   %ebx,%ebx
  800c34:	74 16                	je     800c4c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800c36:	01 f3                	add    %esi,%ebx
  800c38:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  800c3a:	0f b6 02             	movzbl (%edx),%eax
  800c3d:	88 01                	mov    %al,(%ecx)
  800c3f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800c42:	80 3a 01             	cmpb   $0x1,(%edx)
  800c45:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800c48:	39 d9                	cmp    %ebx,%ecx
  800c4a:	75 ee                	jne    800c3a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800c4c:	89 f0                	mov    %esi,%eax
  800c4e:	5b                   	pop    %ebx
  800c4f:	5e                   	pop    %esi
  800c50:	5d                   	pop    %ebp
  800c51:	c3                   	ret    

00800c52 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800c52:	55                   	push   %ebp
  800c53:	89 e5                	mov    %esp,%ebp
  800c55:	57                   	push   %edi
  800c56:	56                   	push   %esi
  800c57:	53                   	push   %ebx
  800c58:	8b 7d 08             	mov    0x8(%ebp),%edi
  800c5b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c5e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800c61:	89 f8                	mov    %edi,%eax
  800c63:	85 f6                	test   %esi,%esi
  800c65:	74 33                	je     800c9a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800c67:	83 fe 01             	cmp    $0x1,%esi
  800c6a:	74 25                	je     800c91 <strlcpy+0x3f>
  800c6c:	0f b6 0b             	movzbl (%ebx),%ecx
  800c6f:	84 c9                	test   %cl,%cl
  800c71:	74 22                	je     800c95 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800c73:	83 ee 02             	sub    $0x2,%esi
  800c76:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800c7b:	88 08                	mov    %cl,(%eax)
  800c7d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800c80:	39 f2                	cmp    %esi,%edx
  800c82:	74 13                	je     800c97 <strlcpy+0x45>
  800c84:	83 c2 01             	add    $0x1,%edx
  800c87:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  800c8b:	84 c9                	test   %cl,%cl
  800c8d:	75 ec                	jne    800c7b <strlcpy+0x29>
  800c8f:	eb 06                	jmp    800c97 <strlcpy+0x45>
  800c91:	89 f8                	mov    %edi,%eax
  800c93:	eb 02                	jmp    800c97 <strlcpy+0x45>
  800c95:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800c97:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800c9a:	29 f8                	sub    %edi,%eax
}
  800c9c:	5b                   	pop    %ebx
  800c9d:	5e                   	pop    %esi
  800c9e:	5f                   	pop    %edi
  800c9f:	5d                   	pop    %ebp
  800ca0:	c3                   	ret    

00800ca1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800ca1:	55                   	push   %ebp
  800ca2:	89 e5                	mov    %esp,%ebp
  800ca4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ca7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800caa:	0f b6 01             	movzbl (%ecx),%eax
  800cad:	84 c0                	test   %al,%al
  800caf:	74 15                	je     800cc6 <strcmp+0x25>
  800cb1:	3a 02                	cmp    (%edx),%al
  800cb3:	75 11                	jne    800cc6 <strcmp+0x25>
		p++, q++;
  800cb5:	83 c1 01             	add    $0x1,%ecx
  800cb8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800cbb:	0f b6 01             	movzbl (%ecx),%eax
  800cbe:	84 c0                	test   %al,%al
  800cc0:	74 04                	je     800cc6 <strcmp+0x25>
  800cc2:	3a 02                	cmp    (%edx),%al
  800cc4:	74 ef                	je     800cb5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800cc6:	0f b6 c0             	movzbl %al,%eax
  800cc9:	0f b6 12             	movzbl (%edx),%edx
  800ccc:	29 d0                	sub    %edx,%eax
}
  800cce:	5d                   	pop    %ebp
  800ccf:	c3                   	ret    

00800cd0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800cd0:	55                   	push   %ebp
  800cd1:	89 e5                	mov    %esp,%ebp
  800cd3:	56                   	push   %esi
  800cd4:	53                   	push   %ebx
  800cd5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800cd8:	8b 55 0c             	mov    0xc(%ebp),%edx
  800cdb:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800cde:	85 f6                	test   %esi,%esi
  800ce0:	74 29                	je     800d0b <strncmp+0x3b>
  800ce2:	0f b6 03             	movzbl (%ebx),%eax
  800ce5:	84 c0                	test   %al,%al
  800ce7:	74 30                	je     800d19 <strncmp+0x49>
  800ce9:	3a 02                	cmp    (%edx),%al
  800ceb:	75 2c                	jne    800d19 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800ced:	8d 43 01             	lea    0x1(%ebx),%eax
  800cf0:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800cf2:	89 c3                	mov    %eax,%ebx
  800cf4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800cf7:	39 f0                	cmp    %esi,%eax
  800cf9:	74 17                	je     800d12 <strncmp+0x42>
  800cfb:	0f b6 08             	movzbl (%eax),%ecx
  800cfe:	84 c9                	test   %cl,%cl
  800d00:	74 17                	je     800d19 <strncmp+0x49>
  800d02:	83 c0 01             	add    $0x1,%eax
  800d05:	3a 0a                	cmp    (%edx),%cl
  800d07:	74 e9                	je     800cf2 <strncmp+0x22>
  800d09:	eb 0e                	jmp    800d19 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800d0b:	b8 00 00 00 00       	mov    $0x0,%eax
  800d10:	eb 0f                	jmp    800d21 <strncmp+0x51>
  800d12:	b8 00 00 00 00       	mov    $0x0,%eax
  800d17:	eb 08                	jmp    800d21 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800d19:	0f b6 03             	movzbl (%ebx),%eax
  800d1c:	0f b6 12             	movzbl (%edx),%edx
  800d1f:	29 d0                	sub    %edx,%eax
}
  800d21:	5b                   	pop    %ebx
  800d22:	5e                   	pop    %esi
  800d23:	5d                   	pop    %ebp
  800d24:	c3                   	ret    

00800d25 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800d25:	55                   	push   %ebp
  800d26:	89 e5                	mov    %esp,%ebp
  800d28:	53                   	push   %ebx
  800d29:	8b 45 08             	mov    0x8(%ebp),%eax
  800d2c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800d2f:	0f b6 18             	movzbl (%eax),%ebx
  800d32:	84 db                	test   %bl,%bl
  800d34:	74 1d                	je     800d53 <strchr+0x2e>
  800d36:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800d38:	38 d3                	cmp    %dl,%bl
  800d3a:	75 06                	jne    800d42 <strchr+0x1d>
  800d3c:	eb 1a                	jmp    800d58 <strchr+0x33>
  800d3e:	38 ca                	cmp    %cl,%dl
  800d40:	74 16                	je     800d58 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800d42:	83 c0 01             	add    $0x1,%eax
  800d45:	0f b6 10             	movzbl (%eax),%edx
  800d48:	84 d2                	test   %dl,%dl
  800d4a:	75 f2                	jne    800d3e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800d4c:	b8 00 00 00 00       	mov    $0x0,%eax
  800d51:	eb 05                	jmp    800d58 <strchr+0x33>
  800d53:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800d58:	5b                   	pop    %ebx
  800d59:	5d                   	pop    %ebp
  800d5a:	c3                   	ret    

00800d5b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800d5b:	55                   	push   %ebp
  800d5c:	89 e5                	mov    %esp,%ebp
  800d5e:	53                   	push   %ebx
  800d5f:	8b 45 08             	mov    0x8(%ebp),%eax
  800d62:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800d65:	0f b6 18             	movzbl (%eax),%ebx
  800d68:	84 db                	test   %bl,%bl
  800d6a:	74 16                	je     800d82 <strfind+0x27>
  800d6c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800d6e:	38 d3                	cmp    %dl,%bl
  800d70:	75 06                	jne    800d78 <strfind+0x1d>
  800d72:	eb 0e                	jmp    800d82 <strfind+0x27>
  800d74:	38 ca                	cmp    %cl,%dl
  800d76:	74 0a                	je     800d82 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800d78:	83 c0 01             	add    $0x1,%eax
  800d7b:	0f b6 10             	movzbl (%eax),%edx
  800d7e:	84 d2                	test   %dl,%dl
  800d80:	75 f2                	jne    800d74 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800d82:	5b                   	pop    %ebx
  800d83:	5d                   	pop    %ebp
  800d84:	c3                   	ret    

00800d85 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800d85:	55                   	push   %ebp
  800d86:	89 e5                	mov    %esp,%ebp
  800d88:	83 ec 0c             	sub    $0xc,%esp
  800d8b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800d8e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800d91:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800d94:	8b 7d 08             	mov    0x8(%ebp),%edi
  800d97:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800d9a:	85 c9                	test   %ecx,%ecx
  800d9c:	74 36                	je     800dd4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800d9e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800da4:	75 28                	jne    800dce <memset+0x49>
  800da6:	f6 c1 03             	test   $0x3,%cl
  800da9:	75 23                	jne    800dce <memset+0x49>
		c &= 0xFF;
  800dab:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800daf:	89 d3                	mov    %edx,%ebx
  800db1:	c1 e3 08             	shl    $0x8,%ebx
  800db4:	89 d6                	mov    %edx,%esi
  800db6:	c1 e6 18             	shl    $0x18,%esi
  800db9:	89 d0                	mov    %edx,%eax
  800dbb:	c1 e0 10             	shl    $0x10,%eax
  800dbe:	09 f0                	or     %esi,%eax
  800dc0:	09 c2                	or     %eax,%edx
  800dc2:	89 d0                	mov    %edx,%eax
  800dc4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800dc6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800dc9:	fc                   	cld    
  800dca:	f3 ab                	rep stos %eax,%es:(%edi)
  800dcc:	eb 06                	jmp    800dd4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800dce:	8b 45 0c             	mov    0xc(%ebp),%eax
  800dd1:	fc                   	cld    
  800dd2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800dd4:	89 f8                	mov    %edi,%eax
  800dd6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800dd9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ddc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ddf:	89 ec                	mov    %ebp,%esp
  800de1:	5d                   	pop    %ebp
  800de2:	c3                   	ret    

00800de3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800de3:	55                   	push   %ebp
  800de4:	89 e5                	mov    %esp,%ebp
  800de6:	83 ec 08             	sub    $0x8,%esp
  800de9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800dec:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800def:	8b 45 08             	mov    0x8(%ebp),%eax
  800df2:	8b 75 0c             	mov    0xc(%ebp),%esi
  800df5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800df8:	39 c6                	cmp    %eax,%esi
  800dfa:	73 36                	jae    800e32 <memmove+0x4f>
  800dfc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800dff:	39 d0                	cmp    %edx,%eax
  800e01:	73 2f                	jae    800e32 <memmove+0x4f>
		s += n;
		d += n;
  800e03:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e06:	f6 c2 03             	test   $0x3,%dl
  800e09:	75 1b                	jne    800e26 <memmove+0x43>
  800e0b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800e11:	75 13                	jne    800e26 <memmove+0x43>
  800e13:	f6 c1 03             	test   $0x3,%cl
  800e16:	75 0e                	jne    800e26 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800e18:	83 ef 04             	sub    $0x4,%edi
  800e1b:	8d 72 fc             	lea    -0x4(%edx),%esi
  800e1e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800e21:	fd                   	std    
  800e22:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e24:	eb 09                	jmp    800e2f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800e26:	83 ef 01             	sub    $0x1,%edi
  800e29:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800e2c:	fd                   	std    
  800e2d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800e2f:	fc                   	cld    
  800e30:	eb 20                	jmp    800e52 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e32:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800e38:	75 13                	jne    800e4d <memmove+0x6a>
  800e3a:	a8 03                	test   $0x3,%al
  800e3c:	75 0f                	jne    800e4d <memmove+0x6a>
  800e3e:	f6 c1 03             	test   $0x3,%cl
  800e41:	75 0a                	jne    800e4d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800e43:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800e46:	89 c7                	mov    %eax,%edi
  800e48:	fc                   	cld    
  800e49:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e4b:	eb 05                	jmp    800e52 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800e4d:	89 c7                	mov    %eax,%edi
  800e4f:	fc                   	cld    
  800e50:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800e52:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800e55:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800e58:	89 ec                	mov    %ebp,%esp
  800e5a:	5d                   	pop    %ebp
  800e5b:	c3                   	ret    

00800e5c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800e5c:	55                   	push   %ebp
  800e5d:	89 e5                	mov    %esp,%ebp
  800e5f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800e62:	8b 45 10             	mov    0x10(%ebp),%eax
  800e65:	89 44 24 08          	mov    %eax,0x8(%esp)
  800e69:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e6c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e70:	8b 45 08             	mov    0x8(%ebp),%eax
  800e73:	89 04 24             	mov    %eax,(%esp)
  800e76:	e8 68 ff ff ff       	call   800de3 <memmove>
}
  800e7b:	c9                   	leave  
  800e7c:	c3                   	ret    

00800e7d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800e7d:	55                   	push   %ebp
  800e7e:	89 e5                	mov    %esp,%ebp
  800e80:	57                   	push   %edi
  800e81:	56                   	push   %esi
  800e82:	53                   	push   %ebx
  800e83:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800e86:	8b 75 0c             	mov    0xc(%ebp),%esi
  800e89:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800e8c:	8d 78 ff             	lea    -0x1(%eax),%edi
  800e8f:	85 c0                	test   %eax,%eax
  800e91:	74 36                	je     800ec9 <memcmp+0x4c>
		if (*s1 != *s2)
  800e93:	0f b6 03             	movzbl (%ebx),%eax
  800e96:	0f b6 0e             	movzbl (%esi),%ecx
  800e99:	38 c8                	cmp    %cl,%al
  800e9b:	75 17                	jne    800eb4 <memcmp+0x37>
  800e9d:	ba 00 00 00 00       	mov    $0x0,%edx
  800ea2:	eb 1a                	jmp    800ebe <memcmp+0x41>
  800ea4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800ea9:	83 c2 01             	add    $0x1,%edx
  800eac:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800eb0:	38 c8                	cmp    %cl,%al
  800eb2:	74 0a                	je     800ebe <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800eb4:	0f b6 c0             	movzbl %al,%eax
  800eb7:	0f b6 c9             	movzbl %cl,%ecx
  800eba:	29 c8                	sub    %ecx,%eax
  800ebc:	eb 10                	jmp    800ece <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ebe:	39 fa                	cmp    %edi,%edx
  800ec0:	75 e2                	jne    800ea4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800ec2:	b8 00 00 00 00       	mov    $0x0,%eax
  800ec7:	eb 05                	jmp    800ece <memcmp+0x51>
  800ec9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ece:	5b                   	pop    %ebx
  800ecf:	5e                   	pop    %esi
  800ed0:	5f                   	pop    %edi
  800ed1:	5d                   	pop    %ebp
  800ed2:	c3                   	ret    

00800ed3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ed3:	55                   	push   %ebp
  800ed4:	89 e5                	mov    %esp,%ebp
  800ed6:	53                   	push   %ebx
  800ed7:	8b 45 08             	mov    0x8(%ebp),%eax
  800eda:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800edd:	89 c2                	mov    %eax,%edx
  800edf:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ee2:	39 d0                	cmp    %edx,%eax
  800ee4:	73 13                	jae    800ef9 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ee6:	89 d9                	mov    %ebx,%ecx
  800ee8:	38 18                	cmp    %bl,(%eax)
  800eea:	75 06                	jne    800ef2 <memfind+0x1f>
  800eec:	eb 0b                	jmp    800ef9 <memfind+0x26>
  800eee:	38 08                	cmp    %cl,(%eax)
  800ef0:	74 07                	je     800ef9 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800ef2:	83 c0 01             	add    $0x1,%eax
  800ef5:	39 d0                	cmp    %edx,%eax
  800ef7:	75 f5                	jne    800eee <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800ef9:	5b                   	pop    %ebx
  800efa:	5d                   	pop    %ebp
  800efb:	c3                   	ret    

00800efc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800efc:	55                   	push   %ebp
  800efd:	89 e5                	mov    %esp,%ebp
  800eff:	57                   	push   %edi
  800f00:	56                   	push   %esi
  800f01:	53                   	push   %ebx
  800f02:	83 ec 04             	sub    $0x4,%esp
  800f05:	8b 55 08             	mov    0x8(%ebp),%edx
  800f08:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f0b:	0f b6 02             	movzbl (%edx),%eax
  800f0e:	3c 09                	cmp    $0x9,%al
  800f10:	74 04                	je     800f16 <strtol+0x1a>
  800f12:	3c 20                	cmp    $0x20,%al
  800f14:	75 0e                	jne    800f24 <strtol+0x28>
		s++;
  800f16:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f19:	0f b6 02             	movzbl (%edx),%eax
  800f1c:	3c 09                	cmp    $0x9,%al
  800f1e:	74 f6                	je     800f16 <strtol+0x1a>
  800f20:	3c 20                	cmp    $0x20,%al
  800f22:	74 f2                	je     800f16 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  800f24:	3c 2b                	cmp    $0x2b,%al
  800f26:	75 0a                	jne    800f32 <strtol+0x36>
		s++;
  800f28:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800f2b:	bf 00 00 00 00       	mov    $0x0,%edi
  800f30:	eb 10                	jmp    800f42 <strtol+0x46>
  800f32:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800f37:	3c 2d                	cmp    $0x2d,%al
  800f39:	75 07                	jne    800f42 <strtol+0x46>
		s++, neg = 1;
  800f3b:	83 c2 01             	add    $0x1,%edx
  800f3e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800f42:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800f48:	75 15                	jne    800f5f <strtol+0x63>
  800f4a:	80 3a 30             	cmpb   $0x30,(%edx)
  800f4d:	75 10                	jne    800f5f <strtol+0x63>
  800f4f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800f53:	75 0a                	jne    800f5f <strtol+0x63>
		s += 2, base = 16;
  800f55:	83 c2 02             	add    $0x2,%edx
  800f58:	bb 10 00 00 00       	mov    $0x10,%ebx
  800f5d:	eb 10                	jmp    800f6f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  800f5f:	85 db                	test   %ebx,%ebx
  800f61:	75 0c                	jne    800f6f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800f63:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800f65:	80 3a 30             	cmpb   $0x30,(%edx)
  800f68:	75 05                	jne    800f6f <strtol+0x73>
		s++, base = 8;
  800f6a:	83 c2 01             	add    $0x1,%edx
  800f6d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800f6f:	b8 00 00 00 00       	mov    $0x0,%eax
  800f74:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800f77:	0f b6 0a             	movzbl (%edx),%ecx
  800f7a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800f7d:	89 f3                	mov    %esi,%ebx
  800f7f:	80 fb 09             	cmp    $0x9,%bl
  800f82:	77 08                	ja     800f8c <strtol+0x90>
			dig = *s - '0';
  800f84:	0f be c9             	movsbl %cl,%ecx
  800f87:	83 e9 30             	sub    $0x30,%ecx
  800f8a:	eb 22                	jmp    800fae <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  800f8c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800f8f:	89 f3                	mov    %esi,%ebx
  800f91:	80 fb 19             	cmp    $0x19,%bl
  800f94:	77 08                	ja     800f9e <strtol+0xa2>
			dig = *s - 'a' + 10;
  800f96:	0f be c9             	movsbl %cl,%ecx
  800f99:	83 e9 57             	sub    $0x57,%ecx
  800f9c:	eb 10                	jmp    800fae <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  800f9e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800fa1:	89 f3                	mov    %esi,%ebx
  800fa3:	80 fb 19             	cmp    $0x19,%bl
  800fa6:	77 16                	ja     800fbe <strtol+0xc2>
			dig = *s - 'A' + 10;
  800fa8:	0f be c9             	movsbl %cl,%ecx
  800fab:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800fae:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800fb1:	7d 0f                	jge    800fc2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  800fb3:	83 c2 01             	add    $0x1,%edx
  800fb6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800fba:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800fbc:	eb b9                	jmp    800f77 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800fbe:	89 c1                	mov    %eax,%ecx
  800fc0:	eb 02                	jmp    800fc4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800fc2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800fc4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800fc8:	74 05                	je     800fcf <strtol+0xd3>
		*endptr = (char *) s;
  800fca:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800fcd:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800fcf:	89 ca                	mov    %ecx,%edx
  800fd1:	f7 da                	neg    %edx
  800fd3:	85 ff                	test   %edi,%edi
  800fd5:	0f 45 c2             	cmovne %edx,%eax
}
  800fd8:	83 c4 04             	add    $0x4,%esp
  800fdb:	5b                   	pop    %ebx
  800fdc:	5e                   	pop    %esi
  800fdd:	5f                   	pop    %edi
  800fde:	5d                   	pop    %ebp
  800fdf:	c3                   	ret    

00800fe0 <__udivdi3>:
  800fe0:	83 ec 1c             	sub    $0x1c,%esp
  800fe3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800fe7:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800feb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800fef:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800ff3:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800ff7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800ffb:	85 c0                	test   %eax,%eax
  800ffd:	89 74 24 10          	mov    %esi,0x10(%esp)
  801001:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801005:	89 ea                	mov    %ebp,%edx
  801007:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80100b:	75 33                	jne    801040 <__udivdi3+0x60>
  80100d:	39 e9                	cmp    %ebp,%ecx
  80100f:	77 6f                	ja     801080 <__udivdi3+0xa0>
  801011:	85 c9                	test   %ecx,%ecx
  801013:	89 ce                	mov    %ecx,%esi
  801015:	75 0b                	jne    801022 <__udivdi3+0x42>
  801017:	b8 01 00 00 00       	mov    $0x1,%eax
  80101c:	31 d2                	xor    %edx,%edx
  80101e:	f7 f1                	div    %ecx
  801020:	89 c6                	mov    %eax,%esi
  801022:	31 d2                	xor    %edx,%edx
  801024:	89 e8                	mov    %ebp,%eax
  801026:	f7 f6                	div    %esi
  801028:	89 c5                	mov    %eax,%ebp
  80102a:	89 f8                	mov    %edi,%eax
  80102c:	f7 f6                	div    %esi
  80102e:	89 ea                	mov    %ebp,%edx
  801030:	8b 74 24 10          	mov    0x10(%esp),%esi
  801034:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801038:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  80103c:	83 c4 1c             	add    $0x1c,%esp
  80103f:	c3                   	ret    
  801040:	39 e8                	cmp    %ebp,%eax
  801042:	77 24                	ja     801068 <__udivdi3+0x88>
  801044:	0f bd c8             	bsr    %eax,%ecx
  801047:	83 f1 1f             	xor    $0x1f,%ecx
  80104a:	89 0c 24             	mov    %ecx,(%esp)
  80104d:	75 49                	jne    801098 <__udivdi3+0xb8>
  80104f:	8b 74 24 08          	mov    0x8(%esp),%esi
  801053:	39 74 24 04          	cmp    %esi,0x4(%esp)
  801057:	0f 86 ab 00 00 00    	jbe    801108 <__udivdi3+0x128>
  80105d:	39 e8                	cmp    %ebp,%eax
  80105f:	0f 82 a3 00 00 00    	jb     801108 <__udivdi3+0x128>
  801065:	8d 76 00             	lea    0x0(%esi),%esi
  801068:	31 d2                	xor    %edx,%edx
  80106a:	31 c0                	xor    %eax,%eax
  80106c:	8b 74 24 10          	mov    0x10(%esp),%esi
  801070:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801074:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801078:	83 c4 1c             	add    $0x1c,%esp
  80107b:	c3                   	ret    
  80107c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801080:	89 f8                	mov    %edi,%eax
  801082:	f7 f1                	div    %ecx
  801084:	31 d2                	xor    %edx,%edx
  801086:	8b 74 24 10          	mov    0x10(%esp),%esi
  80108a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  80108e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801092:	83 c4 1c             	add    $0x1c,%esp
  801095:	c3                   	ret    
  801096:	66 90                	xchg   %ax,%ax
  801098:	0f b6 0c 24          	movzbl (%esp),%ecx
  80109c:	89 c6                	mov    %eax,%esi
  80109e:	b8 20 00 00 00       	mov    $0x20,%eax
  8010a3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  8010a7:	2b 04 24             	sub    (%esp),%eax
  8010aa:	8b 7c 24 08          	mov    0x8(%esp),%edi
  8010ae:	d3 e6                	shl    %cl,%esi
  8010b0:	89 c1                	mov    %eax,%ecx
  8010b2:	d3 ed                	shr    %cl,%ebp
  8010b4:	0f b6 0c 24          	movzbl (%esp),%ecx
  8010b8:	09 f5                	or     %esi,%ebp
  8010ba:	8b 74 24 04          	mov    0x4(%esp),%esi
  8010be:	d3 e6                	shl    %cl,%esi
  8010c0:	89 c1                	mov    %eax,%ecx
  8010c2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8010c6:	89 d6                	mov    %edx,%esi
  8010c8:	d3 ee                	shr    %cl,%esi
  8010ca:	0f b6 0c 24          	movzbl (%esp),%ecx
  8010ce:	d3 e2                	shl    %cl,%edx
  8010d0:	89 c1                	mov    %eax,%ecx
  8010d2:	d3 ef                	shr    %cl,%edi
  8010d4:	09 d7                	or     %edx,%edi
  8010d6:	89 f2                	mov    %esi,%edx
  8010d8:	89 f8                	mov    %edi,%eax
  8010da:	f7 f5                	div    %ebp
  8010dc:	89 d6                	mov    %edx,%esi
  8010de:	89 c7                	mov    %eax,%edi
  8010e0:	f7 64 24 04          	mull   0x4(%esp)
  8010e4:	39 d6                	cmp    %edx,%esi
  8010e6:	72 30                	jb     801118 <__udivdi3+0x138>
  8010e8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  8010ec:	0f b6 0c 24          	movzbl (%esp),%ecx
  8010f0:	d3 e5                	shl    %cl,%ebp
  8010f2:	39 c5                	cmp    %eax,%ebp
  8010f4:	73 04                	jae    8010fa <__udivdi3+0x11a>
  8010f6:	39 d6                	cmp    %edx,%esi
  8010f8:	74 1e                	je     801118 <__udivdi3+0x138>
  8010fa:	89 f8                	mov    %edi,%eax
  8010fc:	31 d2                	xor    %edx,%edx
  8010fe:	e9 69 ff ff ff       	jmp    80106c <__udivdi3+0x8c>
  801103:	90                   	nop
  801104:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801108:	31 d2                	xor    %edx,%edx
  80110a:	b8 01 00 00 00       	mov    $0x1,%eax
  80110f:	e9 58 ff ff ff       	jmp    80106c <__udivdi3+0x8c>
  801114:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801118:	8d 47 ff             	lea    -0x1(%edi),%eax
  80111b:	31 d2                	xor    %edx,%edx
  80111d:	8b 74 24 10          	mov    0x10(%esp),%esi
  801121:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801125:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801129:	83 c4 1c             	add    $0x1c,%esp
  80112c:	c3                   	ret    
  80112d:	66 90                	xchg   %ax,%ax
  80112f:	90                   	nop

00801130 <__umoddi3>:
  801130:	83 ec 2c             	sub    $0x2c,%esp
  801133:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  801137:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80113b:	89 74 24 20          	mov    %esi,0x20(%esp)
  80113f:	8b 74 24 38          	mov    0x38(%esp),%esi
  801143:	89 7c 24 24          	mov    %edi,0x24(%esp)
  801147:	8b 7c 24 34          	mov    0x34(%esp),%edi
  80114b:	85 c0                	test   %eax,%eax
  80114d:	89 c2                	mov    %eax,%edx
  80114f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  801153:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  801157:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80115b:	89 74 24 10          	mov    %esi,0x10(%esp)
  80115f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  801163:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801167:	75 1f                	jne    801188 <__umoddi3+0x58>
  801169:	39 fe                	cmp    %edi,%esi
  80116b:	76 63                	jbe    8011d0 <__umoddi3+0xa0>
  80116d:	89 c8                	mov    %ecx,%eax
  80116f:	89 fa                	mov    %edi,%edx
  801171:	f7 f6                	div    %esi
  801173:	89 d0                	mov    %edx,%eax
  801175:	31 d2                	xor    %edx,%edx
  801177:	8b 74 24 20          	mov    0x20(%esp),%esi
  80117b:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80117f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801183:	83 c4 2c             	add    $0x2c,%esp
  801186:	c3                   	ret    
  801187:	90                   	nop
  801188:	39 f8                	cmp    %edi,%eax
  80118a:	77 64                	ja     8011f0 <__umoddi3+0xc0>
  80118c:	0f bd e8             	bsr    %eax,%ebp
  80118f:	83 f5 1f             	xor    $0x1f,%ebp
  801192:	75 74                	jne    801208 <__umoddi3+0xd8>
  801194:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801198:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  80119c:	0f 87 0e 01 00 00    	ja     8012b0 <__umoddi3+0x180>
  8011a2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  8011a6:	29 f1                	sub    %esi,%ecx
  8011a8:	19 c7                	sbb    %eax,%edi
  8011aa:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  8011ae:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8011b2:	8b 44 24 14          	mov    0x14(%esp),%eax
  8011b6:	8b 54 24 18          	mov    0x18(%esp),%edx
  8011ba:	8b 74 24 20          	mov    0x20(%esp),%esi
  8011be:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8011c2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  8011c6:	83 c4 2c             	add    $0x2c,%esp
  8011c9:	c3                   	ret    
  8011ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8011d0:	85 f6                	test   %esi,%esi
  8011d2:	89 f5                	mov    %esi,%ebp
  8011d4:	75 0b                	jne    8011e1 <__umoddi3+0xb1>
  8011d6:	b8 01 00 00 00       	mov    $0x1,%eax
  8011db:	31 d2                	xor    %edx,%edx
  8011dd:	f7 f6                	div    %esi
  8011df:	89 c5                	mov    %eax,%ebp
  8011e1:	8b 44 24 0c          	mov    0xc(%esp),%eax
  8011e5:	31 d2                	xor    %edx,%edx
  8011e7:	f7 f5                	div    %ebp
  8011e9:	89 c8                	mov    %ecx,%eax
  8011eb:	f7 f5                	div    %ebp
  8011ed:	eb 84                	jmp    801173 <__umoddi3+0x43>
  8011ef:	90                   	nop
  8011f0:	89 c8                	mov    %ecx,%eax
  8011f2:	89 fa                	mov    %edi,%edx
  8011f4:	8b 74 24 20          	mov    0x20(%esp),%esi
  8011f8:	8b 7c 24 24          	mov    0x24(%esp),%edi
  8011fc:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801200:	83 c4 2c             	add    $0x2c,%esp
  801203:	c3                   	ret    
  801204:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801208:	8b 44 24 10          	mov    0x10(%esp),%eax
  80120c:	be 20 00 00 00       	mov    $0x20,%esi
  801211:	89 e9                	mov    %ebp,%ecx
  801213:	29 ee                	sub    %ebp,%esi
  801215:	d3 e2                	shl    %cl,%edx
  801217:	89 f1                	mov    %esi,%ecx
  801219:	d3 e8                	shr    %cl,%eax
  80121b:	89 e9                	mov    %ebp,%ecx
  80121d:	09 d0                	or     %edx,%eax
  80121f:	89 fa                	mov    %edi,%edx
  801221:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801225:	8b 44 24 10          	mov    0x10(%esp),%eax
  801229:	d3 e0                	shl    %cl,%eax
  80122b:	89 f1                	mov    %esi,%ecx
  80122d:	89 44 24 10          	mov    %eax,0x10(%esp)
  801231:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  801235:	d3 ea                	shr    %cl,%edx
  801237:	89 e9                	mov    %ebp,%ecx
  801239:	d3 e7                	shl    %cl,%edi
  80123b:	89 f1                	mov    %esi,%ecx
  80123d:	d3 e8                	shr    %cl,%eax
  80123f:	89 e9                	mov    %ebp,%ecx
  801241:	09 f8                	or     %edi,%eax
  801243:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  801247:	f7 74 24 0c          	divl   0xc(%esp)
  80124b:	d3 e7                	shl    %cl,%edi
  80124d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801251:	89 d7                	mov    %edx,%edi
  801253:	f7 64 24 10          	mull   0x10(%esp)
  801257:	39 d7                	cmp    %edx,%edi
  801259:	89 c1                	mov    %eax,%ecx
  80125b:	89 54 24 14          	mov    %edx,0x14(%esp)
  80125f:	72 3b                	jb     80129c <__umoddi3+0x16c>
  801261:	39 44 24 18          	cmp    %eax,0x18(%esp)
  801265:	72 31                	jb     801298 <__umoddi3+0x168>
  801267:	8b 44 24 18          	mov    0x18(%esp),%eax
  80126b:	29 c8                	sub    %ecx,%eax
  80126d:	19 d7                	sbb    %edx,%edi
  80126f:	89 e9                	mov    %ebp,%ecx
  801271:	89 fa                	mov    %edi,%edx
  801273:	d3 e8                	shr    %cl,%eax
  801275:	89 f1                	mov    %esi,%ecx
  801277:	d3 e2                	shl    %cl,%edx
  801279:	89 e9                	mov    %ebp,%ecx
  80127b:	09 d0                	or     %edx,%eax
  80127d:	89 fa                	mov    %edi,%edx
  80127f:	d3 ea                	shr    %cl,%edx
  801281:	8b 74 24 20          	mov    0x20(%esp),%esi
  801285:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801289:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  80128d:	83 c4 2c             	add    $0x2c,%esp
  801290:	c3                   	ret    
  801291:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801298:	39 d7                	cmp    %edx,%edi
  80129a:	75 cb                	jne    801267 <__umoddi3+0x137>
  80129c:	8b 54 24 14          	mov    0x14(%esp),%edx
  8012a0:	89 c1                	mov    %eax,%ecx
  8012a2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  8012a6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  8012aa:	eb bb                	jmp    801267 <__umoddi3+0x137>
  8012ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8012b0:	3b 44 24 18          	cmp    0x18(%esp),%eax
  8012b4:	0f 82 e8 fe ff ff    	jb     8011a2 <__umoddi3+0x72>
  8012ba:	e9 f3 fe ff ff       	jmp    8011b2 <__umoddi3+0x82>

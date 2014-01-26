
obj/user/faultregs：     文件格式 elf32-i386


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
  80002c:	e8 67 05 00 00       	call   800598 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	90                   	nop

00800034 <check_regs>:
static struct regs before, during, after;

static void
check_regs(struct regs* a, const char *an, struct regs* b, const char *bn,
	   const char *testname)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	57                   	push   %edi
  800038:	56                   	push   %esi
  800039:	53                   	push   %ebx
  80003a:	83 ec 1c             	sub    $0x1c,%esp
  80003d:	89 c6                	mov    %eax,%esi
  80003f:	89 cb                	mov    %ecx,%ebx
	int mismatch = 0;

	cprintf("%-6s %-8s %-8s\n", "", an, bn);
  800041:	8b 45 08             	mov    0x8(%ebp),%eax
  800044:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800048:	89 54 24 08          	mov    %edx,0x8(%esp)
  80004c:	c7 44 24 04 91 18 80 	movl   $0x801891,0x4(%esp)
  800053:	00 
  800054:	c7 04 24 60 18 80 00 	movl   $0x801860,(%esp)
  80005b:	e8 d3 06 00 00       	call   800733 <cprintf>
			cprintf("MISMATCH\n");				\
			mismatch = 1;					\
		}							\
	} while (0)

	CHECK(edi, regs.reg_edi);
  800060:	8b 03                	mov    (%ebx),%eax
  800062:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800066:	8b 06                	mov    (%esi),%eax
  800068:	89 44 24 08          	mov    %eax,0x8(%esp)
  80006c:	c7 44 24 04 70 18 80 	movl   $0x801870,0x4(%esp)
  800073:	00 
  800074:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  80007b:	e8 b3 06 00 00       	call   800733 <cprintf>
  800080:	8b 03                	mov    (%ebx),%eax
  800082:	39 06                	cmp    %eax,(%esi)
  800084:	75 13                	jne    800099 <check_regs+0x65>
  800086:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  80008d:	e8 a1 06 00 00       	call   800733 <cprintf>

static void
check_regs(struct regs* a, const char *an, struct regs* b, const char *bn,
	   const char *testname)
{
	int mismatch = 0;
  800092:	bf 00 00 00 00       	mov    $0x0,%edi
  800097:	eb 11                	jmp    8000aa <check_regs+0x76>
			cprintf("MISMATCH\n");				\
			mismatch = 1;					\
		}							\
	} while (0)

	CHECK(edi, regs.reg_edi);
  800099:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  8000a0:	e8 8e 06 00 00       	call   800733 <cprintf>
  8000a5:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(esi, regs.reg_esi);
  8000aa:	8b 43 04             	mov    0x4(%ebx),%eax
  8000ad:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000b1:	8b 46 04             	mov    0x4(%esi),%eax
  8000b4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8000b8:	c7 44 24 04 92 18 80 	movl   $0x801892,0x4(%esp)
  8000bf:	00 
  8000c0:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  8000c7:	e8 67 06 00 00       	call   800733 <cprintf>
  8000cc:	8b 43 04             	mov    0x4(%ebx),%eax
  8000cf:	39 46 04             	cmp    %eax,0x4(%esi)
  8000d2:	75 0e                	jne    8000e2 <check_regs+0xae>
  8000d4:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  8000db:	e8 53 06 00 00       	call   800733 <cprintf>
  8000e0:	eb 11                	jmp    8000f3 <check_regs+0xbf>
  8000e2:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  8000e9:	e8 45 06 00 00       	call   800733 <cprintf>
  8000ee:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ebp, regs.reg_ebp);
  8000f3:	8b 43 08             	mov    0x8(%ebx),%eax
  8000f6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000fa:	8b 46 08             	mov    0x8(%esi),%eax
  8000fd:	89 44 24 08          	mov    %eax,0x8(%esp)
  800101:	c7 44 24 04 96 18 80 	movl   $0x801896,0x4(%esp)
  800108:	00 
  800109:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  800110:	e8 1e 06 00 00       	call   800733 <cprintf>
  800115:	8b 43 08             	mov    0x8(%ebx),%eax
  800118:	39 46 08             	cmp    %eax,0x8(%esi)
  80011b:	75 0e                	jne    80012b <check_regs+0xf7>
  80011d:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  800124:	e8 0a 06 00 00       	call   800733 <cprintf>
  800129:	eb 11                	jmp    80013c <check_regs+0x108>
  80012b:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  800132:	e8 fc 05 00 00       	call   800733 <cprintf>
  800137:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ebx, regs.reg_ebx);
  80013c:	8b 43 10             	mov    0x10(%ebx),%eax
  80013f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800143:	8b 46 10             	mov    0x10(%esi),%eax
  800146:	89 44 24 08          	mov    %eax,0x8(%esp)
  80014a:	c7 44 24 04 9a 18 80 	movl   $0x80189a,0x4(%esp)
  800151:	00 
  800152:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  800159:	e8 d5 05 00 00       	call   800733 <cprintf>
  80015e:	8b 43 10             	mov    0x10(%ebx),%eax
  800161:	39 46 10             	cmp    %eax,0x10(%esi)
  800164:	75 0e                	jne    800174 <check_regs+0x140>
  800166:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  80016d:	e8 c1 05 00 00       	call   800733 <cprintf>
  800172:	eb 11                	jmp    800185 <check_regs+0x151>
  800174:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  80017b:	e8 b3 05 00 00       	call   800733 <cprintf>
  800180:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(edx, regs.reg_edx);
  800185:	8b 43 14             	mov    0x14(%ebx),%eax
  800188:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80018c:	8b 46 14             	mov    0x14(%esi),%eax
  80018f:	89 44 24 08          	mov    %eax,0x8(%esp)
  800193:	c7 44 24 04 9e 18 80 	movl   $0x80189e,0x4(%esp)
  80019a:	00 
  80019b:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  8001a2:	e8 8c 05 00 00       	call   800733 <cprintf>
  8001a7:	8b 43 14             	mov    0x14(%ebx),%eax
  8001aa:	39 46 14             	cmp    %eax,0x14(%esi)
  8001ad:	75 0e                	jne    8001bd <check_regs+0x189>
  8001af:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  8001b6:	e8 78 05 00 00       	call   800733 <cprintf>
  8001bb:	eb 11                	jmp    8001ce <check_regs+0x19a>
  8001bd:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  8001c4:	e8 6a 05 00 00       	call   800733 <cprintf>
  8001c9:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ecx, regs.reg_ecx);
  8001ce:	8b 43 18             	mov    0x18(%ebx),%eax
  8001d1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001d5:	8b 46 18             	mov    0x18(%esi),%eax
  8001d8:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001dc:	c7 44 24 04 a2 18 80 	movl   $0x8018a2,0x4(%esp)
  8001e3:	00 
  8001e4:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  8001eb:	e8 43 05 00 00       	call   800733 <cprintf>
  8001f0:	8b 43 18             	mov    0x18(%ebx),%eax
  8001f3:	39 46 18             	cmp    %eax,0x18(%esi)
  8001f6:	75 0e                	jne    800206 <check_regs+0x1d2>
  8001f8:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  8001ff:	e8 2f 05 00 00       	call   800733 <cprintf>
  800204:	eb 11                	jmp    800217 <check_regs+0x1e3>
  800206:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  80020d:	e8 21 05 00 00       	call   800733 <cprintf>
  800212:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eax, regs.reg_eax);
  800217:	8b 43 1c             	mov    0x1c(%ebx),%eax
  80021a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80021e:	8b 46 1c             	mov    0x1c(%esi),%eax
  800221:	89 44 24 08          	mov    %eax,0x8(%esp)
  800225:	c7 44 24 04 a6 18 80 	movl   $0x8018a6,0x4(%esp)
  80022c:	00 
  80022d:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  800234:	e8 fa 04 00 00       	call   800733 <cprintf>
  800239:	8b 43 1c             	mov    0x1c(%ebx),%eax
  80023c:	39 46 1c             	cmp    %eax,0x1c(%esi)
  80023f:	75 0e                	jne    80024f <check_regs+0x21b>
  800241:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  800248:	e8 e6 04 00 00       	call   800733 <cprintf>
  80024d:	eb 11                	jmp    800260 <check_regs+0x22c>
  80024f:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  800256:	e8 d8 04 00 00       	call   800733 <cprintf>
  80025b:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eip, eip);
  800260:	8b 43 20             	mov    0x20(%ebx),%eax
  800263:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800267:	8b 46 20             	mov    0x20(%esi),%eax
  80026a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80026e:	c7 44 24 04 aa 18 80 	movl   $0x8018aa,0x4(%esp)
  800275:	00 
  800276:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  80027d:	e8 b1 04 00 00       	call   800733 <cprintf>
  800282:	8b 43 20             	mov    0x20(%ebx),%eax
  800285:	39 46 20             	cmp    %eax,0x20(%esi)
  800288:	75 0e                	jne    800298 <check_regs+0x264>
  80028a:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  800291:	e8 9d 04 00 00       	call   800733 <cprintf>
  800296:	eb 11                	jmp    8002a9 <check_regs+0x275>
  800298:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  80029f:	e8 8f 04 00 00       	call   800733 <cprintf>
  8002a4:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eflags, eflags);
  8002a9:	8b 43 24             	mov    0x24(%ebx),%eax
  8002ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002b0:	8b 46 24             	mov    0x24(%esi),%eax
  8002b3:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002b7:	c7 44 24 04 ae 18 80 	movl   $0x8018ae,0x4(%esp)
  8002be:	00 
  8002bf:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  8002c6:	e8 68 04 00 00       	call   800733 <cprintf>
  8002cb:	8b 43 24             	mov    0x24(%ebx),%eax
  8002ce:	39 46 24             	cmp    %eax,0x24(%esi)
  8002d1:	75 0e                	jne    8002e1 <check_regs+0x2ad>
  8002d3:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  8002da:	e8 54 04 00 00       	call   800733 <cprintf>
  8002df:	eb 11                	jmp    8002f2 <check_regs+0x2be>
  8002e1:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  8002e8:	e8 46 04 00 00       	call   800733 <cprintf>
  8002ed:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(esp, esp);
  8002f2:	8b 43 28             	mov    0x28(%ebx),%eax
  8002f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002f9:	8b 46 28             	mov    0x28(%esi),%eax
  8002fc:	89 44 24 08          	mov    %eax,0x8(%esp)
  800300:	c7 44 24 04 b5 18 80 	movl   $0x8018b5,0x4(%esp)
  800307:	00 
  800308:	c7 04 24 74 18 80 00 	movl   $0x801874,(%esp)
  80030f:	e8 1f 04 00 00       	call   800733 <cprintf>
  800314:	8b 43 28             	mov    0x28(%ebx),%eax
  800317:	39 46 28             	cmp    %eax,0x28(%esi)
  80031a:	75 25                	jne    800341 <check_regs+0x30d>
  80031c:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  800323:	e8 0b 04 00 00       	call   800733 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  800328:	8b 45 0c             	mov    0xc(%ebp),%eax
  80032b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80032f:	c7 04 24 b9 18 80 00 	movl   $0x8018b9,(%esp)
  800336:	e8 f8 03 00 00       	call   800733 <cprintf>
	if (!mismatch)
  80033b:	85 ff                	test   %edi,%edi
  80033d:	74 23                	je     800362 <check_regs+0x32e>
  80033f:	eb 2f                	jmp    800370 <check_regs+0x33c>
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
	CHECK(esp, esp);
  800341:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  800348:	e8 e6 03 00 00       	call   800733 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  80034d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800350:	89 44 24 04          	mov    %eax,0x4(%esp)
  800354:	c7 04 24 b9 18 80 00 	movl   $0x8018b9,(%esp)
  80035b:	e8 d3 03 00 00       	call   800733 <cprintf>
  800360:	eb 0e                	jmp    800370 <check_regs+0x33c>
	if (!mismatch)
		cprintf("OK\n");
  800362:	c7 04 24 84 18 80 00 	movl   $0x801884,(%esp)
  800369:	e8 c5 03 00 00       	call   800733 <cprintf>
  80036e:	eb 0c                	jmp    80037c <check_regs+0x348>
	else
		cprintf("MISMATCH\n");
  800370:	c7 04 24 88 18 80 00 	movl   $0x801888,(%esp)
  800377:	e8 b7 03 00 00       	call   800733 <cprintf>
}
  80037c:	83 c4 1c             	add    $0x1c,%esp
  80037f:	5b                   	pop    %ebx
  800380:	5e                   	pop    %esi
  800381:	5f                   	pop    %edi
  800382:	5d                   	pop    %ebp
  800383:	c3                   	ret    

00800384 <pgfault>:

static void
pgfault(struct UTrapframe *utf)
{
  800384:	55                   	push   %ebp
  800385:	89 e5                	mov    %esp,%ebp
  800387:	83 ec 28             	sub    $0x28,%esp
  80038a:	8b 45 08             	mov    0x8(%ebp),%eax
	int r;

	if (utf->utf_fault_va != (uint32_t)UTEMP)
  80038d:	8b 10                	mov    (%eax),%edx
  80038f:	81 fa 00 00 40 00    	cmp    $0x400000,%edx
  800395:	74 27                	je     8003be <pgfault+0x3a>
		panic("pgfault expected at UTEMP, got 0x%08x (eip %08x)",
  800397:	8b 40 28             	mov    0x28(%eax),%eax
  80039a:	89 44 24 10          	mov    %eax,0x10(%esp)
  80039e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8003a2:	c7 44 24 08 20 19 80 	movl   $0x801920,0x8(%esp)
  8003a9:	00 
  8003aa:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  8003b1:	00 
  8003b2:	c7 04 24 c7 18 80 00 	movl   $0x8018c7,(%esp)
  8003b9:	e8 62 02 00 00       	call   800620 <_panic>
		      utf->utf_fault_va, utf->utf_eip);

	// Check registers in UTrapframe
	during.regs = utf->utf_regs;
  8003be:	8b 50 08             	mov    0x8(%eax),%edx
  8003c1:	89 15 a0 20 80 00    	mov    %edx,0x8020a0
  8003c7:	8b 50 0c             	mov    0xc(%eax),%edx
  8003ca:	89 15 a4 20 80 00    	mov    %edx,0x8020a4
  8003d0:	8b 50 10             	mov    0x10(%eax),%edx
  8003d3:	89 15 a8 20 80 00    	mov    %edx,0x8020a8
  8003d9:	8b 50 14             	mov    0x14(%eax),%edx
  8003dc:	89 15 ac 20 80 00    	mov    %edx,0x8020ac
  8003e2:	8b 50 18             	mov    0x18(%eax),%edx
  8003e5:	89 15 b0 20 80 00    	mov    %edx,0x8020b0
  8003eb:	8b 50 1c             	mov    0x1c(%eax),%edx
  8003ee:	89 15 b4 20 80 00    	mov    %edx,0x8020b4
  8003f4:	8b 50 20             	mov    0x20(%eax),%edx
  8003f7:	89 15 b8 20 80 00    	mov    %edx,0x8020b8
  8003fd:	8b 50 24             	mov    0x24(%eax),%edx
  800400:	89 15 bc 20 80 00    	mov    %edx,0x8020bc
	during.eip = utf->utf_eip;
  800406:	8b 50 28             	mov    0x28(%eax),%edx
  800409:	89 15 c0 20 80 00    	mov    %edx,0x8020c0
	during.eflags = utf->utf_eflags;
  80040f:	8b 50 2c             	mov    0x2c(%eax),%edx
  800412:	89 15 c4 20 80 00    	mov    %edx,0x8020c4
	during.esp = utf->utf_esp;
  800418:	8b 40 30             	mov    0x30(%eax),%eax
  80041b:	a3 c8 20 80 00       	mov    %eax,0x8020c8
	check_regs(&before, "before", &during, "during", "in UTrapframe");
  800420:	c7 44 24 04 df 18 80 	movl   $0x8018df,0x4(%esp)
  800427:	00 
  800428:	c7 04 24 ed 18 80 00 	movl   $0x8018ed,(%esp)
  80042f:	b9 a0 20 80 00       	mov    $0x8020a0,%ecx
  800434:	ba d8 18 80 00       	mov    $0x8018d8,%edx
  800439:	b8 20 20 80 00       	mov    $0x802020,%eax
  80043e:	e8 f1 fb ff ff       	call   800034 <check_regs>

	// Map UTEMP so the write succeeds
	if ((r = sys_page_alloc(0, UTEMP, PTE_U|PTE_P|PTE_W)) < 0)
  800443:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  80044a:	00 
  80044b:	c7 44 24 04 00 00 40 	movl   $0x400000,0x4(%esp)
  800452:	00 
  800453:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80045a:	e8 6d 0e 00 00       	call   8012cc <sys_page_alloc>
  80045f:	85 c0                	test   %eax,%eax
  800461:	79 20                	jns    800483 <pgfault+0xff>
		panic("sys_page_alloc: %e", r);
  800463:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800467:	c7 44 24 08 f4 18 80 	movl   $0x8018f4,0x8(%esp)
  80046e:	00 
  80046f:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  800476:	00 
  800477:	c7 04 24 c7 18 80 00 	movl   $0x8018c7,(%esp)
  80047e:	e8 9d 01 00 00       	call   800620 <_panic>
}
  800483:	c9                   	leave  
  800484:	c3                   	ret    

00800485 <umain>:

void
umain(int argc, char **argv)
{
  800485:	55                   	push   %ebp
  800486:	89 e5                	mov    %esp,%ebp
  800488:	83 ec 18             	sub    $0x18,%esp
	set_pgfault_handler(pgfault);
  80048b:	c7 04 24 84 03 80 00 	movl   $0x800384,(%esp)
  800492:	e8 9d 10 00 00       	call   801534 <set_pgfault_handler>

	__asm __volatile(
  800497:	50                   	push   %eax
  800498:	9c                   	pushf  
  800499:	58                   	pop    %eax
  80049a:	0d d5 08 00 00       	or     $0x8d5,%eax
  80049f:	50                   	push   %eax
  8004a0:	9d                   	popf   
  8004a1:	a3 44 20 80 00       	mov    %eax,0x802044
  8004a6:	8d 05 e1 04 80 00    	lea    0x8004e1,%eax
  8004ac:	a3 40 20 80 00       	mov    %eax,0x802040
  8004b1:	58                   	pop    %eax
  8004b2:	89 3d 20 20 80 00    	mov    %edi,0x802020
  8004b8:	89 35 24 20 80 00    	mov    %esi,0x802024
  8004be:	89 2d 28 20 80 00    	mov    %ebp,0x802028
  8004c4:	89 1d 30 20 80 00    	mov    %ebx,0x802030
  8004ca:	89 15 34 20 80 00    	mov    %edx,0x802034
  8004d0:	89 0d 38 20 80 00    	mov    %ecx,0x802038
  8004d6:	a3 3c 20 80 00       	mov    %eax,0x80203c
  8004db:	89 25 48 20 80 00    	mov    %esp,0x802048
  8004e1:	c7 05 00 00 40 00 2a 	movl   $0x2a,0x400000
  8004e8:	00 00 00 
  8004eb:	89 3d 60 20 80 00    	mov    %edi,0x802060
  8004f1:	89 35 64 20 80 00    	mov    %esi,0x802064
  8004f7:	89 2d 68 20 80 00    	mov    %ebp,0x802068
  8004fd:	89 1d 70 20 80 00    	mov    %ebx,0x802070
  800503:	89 15 74 20 80 00    	mov    %edx,0x802074
  800509:	89 0d 78 20 80 00    	mov    %ecx,0x802078
  80050f:	a3 7c 20 80 00       	mov    %eax,0x80207c
  800514:	89 25 88 20 80 00    	mov    %esp,0x802088
  80051a:	8b 3d 20 20 80 00    	mov    0x802020,%edi
  800520:	8b 35 24 20 80 00    	mov    0x802024,%esi
  800526:	8b 2d 28 20 80 00    	mov    0x802028,%ebp
  80052c:	8b 1d 30 20 80 00    	mov    0x802030,%ebx
  800532:	8b 15 34 20 80 00    	mov    0x802034,%edx
  800538:	8b 0d 38 20 80 00    	mov    0x802038,%ecx
  80053e:	a1 3c 20 80 00       	mov    0x80203c,%eax
  800543:	8b 25 48 20 80 00    	mov    0x802048,%esp
  800549:	50                   	push   %eax
  80054a:	9c                   	pushf  
  80054b:	58                   	pop    %eax
  80054c:	a3 84 20 80 00       	mov    %eax,0x802084
  800551:	58                   	pop    %eax
		: : "m" (before), "m" (after) : "memory", "cc");

	// Check UTEMP to roughly determine that EIP was restored
	// correctly (of course, we probably wouldn't get this far if
	// it weren't)
	if (*(int*)UTEMP != 42)
  800552:	83 3d 00 00 40 00 2a 	cmpl   $0x2a,0x400000
  800559:	74 0c                	je     800567 <umain+0xe2>
		cprintf("EIP after page-fault MISMATCH\n");
  80055b:	c7 04 24 54 19 80 00 	movl   $0x801954,(%esp)
  800562:	e8 cc 01 00 00       	call   800733 <cprintf>
	after.eip = before.eip;
  800567:	a1 40 20 80 00       	mov    0x802040,%eax
  80056c:	a3 80 20 80 00       	mov    %eax,0x802080

	check_regs(&before, "before", &after, "after", "after page-fault");
  800571:	c7 44 24 04 07 19 80 	movl   $0x801907,0x4(%esp)
  800578:	00 
  800579:	c7 04 24 18 19 80 00 	movl   $0x801918,(%esp)
  800580:	b9 60 20 80 00       	mov    $0x802060,%ecx
  800585:	ba d8 18 80 00       	mov    $0x8018d8,%edx
  80058a:	b8 20 20 80 00       	mov    $0x802020,%eax
  80058f:	e8 a0 fa ff ff       	call   800034 <check_regs>
}
  800594:	c9                   	leave  
  800595:	c3                   	ret    
  800596:	66 90                	xchg   %ax,%ax

00800598 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800598:	55                   	push   %ebp
  800599:	89 e5                	mov    %esp,%ebp
  80059b:	57                   	push   %edi
  80059c:	56                   	push   %esi
  80059d:	53                   	push   %ebx
  80059e:	83 ec 1c             	sub    $0x1c,%esp
  8005a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8005a4:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
  8005a7:	e8 c0 0c 00 00       	call   80126c <sys_getenvid>
	thisenv = envs;
  8005ac:	c7 05 cc 20 80 00 00 	movl   $0xeec00000,0x8020cc
  8005b3:	00 c0 ee 
	for(;thisenv;thisenv++)
		if(thisenv -> env_id == thisid)
  8005b6:	8b 15 48 00 c0 ee    	mov    0xeec00048,%edx
  8005bc:	39 c2                	cmp    %eax,%edx
  8005be:	74 25                	je     8005e5 <libmain+0x4d>
  8005c0:	ba 7c 00 c0 ee       	mov    $0xeec0007c,%edx
  8005c5:	eb 12                	jmp    8005d9 <libmain+0x41>
  8005c7:	8b 4a 48             	mov    0x48(%edx),%ecx
  8005ca:	83 c2 7c             	add    $0x7c,%edx
  8005cd:	39 c1                	cmp    %eax,%ecx
  8005cf:	75 08                	jne    8005d9 <libmain+0x41>
  8005d1:	89 3d cc 20 80 00    	mov    %edi,0x8020cc
  8005d7:	eb 0c                	jmp    8005e5 <libmain+0x4d>
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t thisid = sys_getenvid();
	thisenv = envs;
	for(;thisenv;thisenv++)
  8005d9:	89 d7                	mov    %edx,%edi
  8005db:	85 d2                	test   %edx,%edx
  8005dd:	75 e8                	jne    8005c7 <libmain+0x2f>
  8005df:	89 15 cc 20 80 00    	mov    %edx,0x8020cc
		if(thisenv -> env_id == thisid)
			break;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8005e5:	85 db                	test   %ebx,%ebx
  8005e7:	7e 07                	jle    8005f0 <libmain+0x58>
		binaryname = argv[0];
  8005e9:	8b 06                	mov    (%esi),%eax
  8005eb:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8005f0:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005f4:	89 1c 24             	mov    %ebx,(%esp)
  8005f7:	e8 89 fe ff ff       	call   800485 <umain>

	// exit gracefully
	exit();
  8005fc:	e8 0b 00 00 00       	call   80060c <exit>
}
  800601:	83 c4 1c             	add    $0x1c,%esp
  800604:	5b                   	pop    %ebx
  800605:	5e                   	pop    %esi
  800606:	5f                   	pop    %edi
  800607:	5d                   	pop    %ebp
  800608:	c3                   	ret    
  800609:	66 90                	xchg   %ax,%ax
  80060b:	90                   	nop

0080060c <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80060c:	55                   	push   %ebp
  80060d:	89 e5                	mov    %esp,%ebp
  80060f:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800612:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800619:	e8 f1 0b 00 00       	call   80120f <sys_env_destroy>
}
  80061e:	c9                   	leave  
  80061f:	c3                   	ret    

00800620 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800620:	55                   	push   %ebp
  800621:	89 e5                	mov    %esp,%ebp
  800623:	56                   	push   %esi
  800624:	53                   	push   %ebx
  800625:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800628:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  80062b:	a1 d0 20 80 00       	mov    0x8020d0,%eax
  800630:	85 c0                	test   %eax,%eax
  800632:	74 10                	je     800644 <_panic+0x24>
		cprintf("%s: ", argv0);
  800634:	89 44 24 04          	mov    %eax,0x4(%esp)
  800638:	c7 04 24 7d 19 80 00 	movl   $0x80197d,(%esp)
  80063f:	e8 ef 00 00 00       	call   800733 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800644:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80064a:	e8 1d 0c 00 00       	call   80126c <sys_getenvid>
  80064f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800652:	89 54 24 10          	mov    %edx,0x10(%esp)
  800656:	8b 55 08             	mov    0x8(%ebp),%edx
  800659:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80065d:	89 74 24 08          	mov    %esi,0x8(%esp)
  800661:	89 44 24 04          	mov    %eax,0x4(%esp)
  800665:	c7 04 24 84 19 80 00 	movl   $0x801984,(%esp)
  80066c:	e8 c2 00 00 00       	call   800733 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800671:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800675:	8b 45 10             	mov    0x10(%ebp),%eax
  800678:	89 04 24             	mov    %eax,(%esp)
  80067b:	e8 52 00 00 00       	call   8006d2 <vcprintf>
	cprintf("\n");
  800680:	c7 04 24 90 18 80 00 	movl   $0x801890,(%esp)
  800687:	e8 a7 00 00 00       	call   800733 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80068c:	cc                   	int3   
  80068d:	eb fd                	jmp    80068c <_panic+0x6c>
  80068f:	90                   	nop

00800690 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800690:	55                   	push   %ebp
  800691:	89 e5                	mov    %esp,%ebp
  800693:	53                   	push   %ebx
  800694:	83 ec 14             	sub    $0x14,%esp
  800697:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80069a:	8b 03                	mov    (%ebx),%eax
  80069c:	8b 55 08             	mov    0x8(%ebp),%edx
  80069f:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8006a3:	83 c0 01             	add    $0x1,%eax
  8006a6:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8006a8:	3d ff 00 00 00       	cmp    $0xff,%eax
  8006ad:	75 19                	jne    8006c8 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8006af:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8006b6:	00 
  8006b7:	8d 43 08             	lea    0x8(%ebx),%eax
  8006ba:	89 04 24             	mov    %eax,(%esp)
  8006bd:	e8 ee 0a 00 00       	call   8011b0 <sys_cputs>
		b->idx = 0;
  8006c2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8006c8:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8006cc:	83 c4 14             	add    $0x14,%esp
  8006cf:	5b                   	pop    %ebx
  8006d0:	5d                   	pop    %ebp
  8006d1:	c3                   	ret    

008006d2 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8006d2:	55                   	push   %ebp
  8006d3:	89 e5                	mov    %esp,%ebp
  8006d5:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8006db:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8006e2:	00 00 00 
	b.cnt = 0;
  8006e5:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8006ec:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8006ef:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006f6:	8b 45 08             	mov    0x8(%ebp),%eax
  8006f9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006fd:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800703:	89 44 24 04          	mov    %eax,0x4(%esp)
  800707:	c7 04 24 90 06 80 00 	movl   $0x800690,(%esp)
  80070e:	e8 af 01 00 00       	call   8008c2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800713:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800719:	89 44 24 04          	mov    %eax,0x4(%esp)
  80071d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800723:	89 04 24             	mov    %eax,(%esp)
  800726:	e8 85 0a 00 00       	call   8011b0 <sys_cputs>

	return b.cnt;
}
  80072b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800731:	c9                   	leave  
  800732:	c3                   	ret    

00800733 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800733:	55                   	push   %ebp
  800734:	89 e5                	mov    %esp,%ebp
  800736:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800739:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80073c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800740:	8b 45 08             	mov    0x8(%ebp),%eax
  800743:	89 04 24             	mov    %eax,(%esp)
  800746:	e8 87 ff ff ff       	call   8006d2 <vcprintf>
	va_end(ap);

	return cnt;
}
  80074b:	c9                   	leave  
  80074c:	c3                   	ret    
  80074d:	66 90                	xchg   %ax,%ax
  80074f:	90                   	nop

00800750 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800750:	55                   	push   %ebp
  800751:	89 e5                	mov    %esp,%ebp
  800753:	57                   	push   %edi
  800754:	56                   	push   %esi
  800755:	53                   	push   %ebx
  800756:	83 ec 4c             	sub    $0x4c,%esp
  800759:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80075c:	89 d7                	mov    %edx,%edi
  80075e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800761:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800764:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800767:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80076a:	b8 00 00 00 00       	mov    $0x0,%eax
  80076f:	39 d8                	cmp    %ebx,%eax
  800771:	72 17                	jb     80078a <printnum+0x3a>
  800773:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800776:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  800779:	76 0f                	jbe    80078a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80077b:	8b 75 14             	mov    0x14(%ebp),%esi
  80077e:	83 ee 01             	sub    $0x1,%esi
  800781:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800784:	85 f6                	test   %esi,%esi
  800786:	7f 63                	jg     8007eb <printnum+0x9b>
  800788:	eb 75                	jmp    8007ff <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80078a:	8b 5d 18             	mov    0x18(%ebp),%ebx
  80078d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  800791:	8b 45 14             	mov    0x14(%ebp),%eax
  800794:	83 e8 01             	sub    $0x1,%eax
  800797:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80079b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80079e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8007a2:	8b 44 24 08          	mov    0x8(%esp),%eax
  8007a6:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8007aa:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8007ad:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8007b0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8007b7:	00 
  8007b8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8007bb:	89 1c 24             	mov    %ebx,(%esp)
  8007be:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8007c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007c5:	e8 a6 0d 00 00       	call   801570 <__udivdi3>
  8007ca:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8007cd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8007d0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8007d4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8007d8:	89 04 24             	mov    %eax,(%esp)
  8007db:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007df:	89 fa                	mov    %edi,%edx
  8007e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8007e4:	e8 67 ff ff ff       	call   800750 <printnum>
  8007e9:	eb 14                	jmp    8007ff <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8007eb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007ef:	8b 45 18             	mov    0x18(%ebp),%eax
  8007f2:	89 04 24             	mov    %eax,(%esp)
  8007f5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8007f7:	83 ee 01             	sub    $0x1,%esi
  8007fa:	75 ef                	jne    8007eb <printnum+0x9b>
  8007fc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8007ff:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800803:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800807:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80080a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80080e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800815:	00 
  800816:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800819:	89 1c 24             	mov    %ebx,(%esp)
  80081c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80081f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800823:	e8 98 0e 00 00       	call   8016c0 <__umoddi3>
  800828:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80082c:	0f be 80 a7 19 80 00 	movsbl 0x8019a7(%eax),%eax
  800833:	89 04 24             	mov    %eax,(%esp)
  800836:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800839:	ff d0                	call   *%eax
}
  80083b:	83 c4 4c             	add    $0x4c,%esp
  80083e:	5b                   	pop    %ebx
  80083f:	5e                   	pop    %esi
  800840:	5f                   	pop    %edi
  800841:	5d                   	pop    %ebp
  800842:	c3                   	ret    

00800843 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800843:	55                   	push   %ebp
  800844:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800846:	83 fa 01             	cmp    $0x1,%edx
  800849:	7e 0e                	jle    800859 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80084b:	8b 10                	mov    (%eax),%edx
  80084d:	8d 4a 08             	lea    0x8(%edx),%ecx
  800850:	89 08                	mov    %ecx,(%eax)
  800852:	8b 02                	mov    (%edx),%eax
  800854:	8b 52 04             	mov    0x4(%edx),%edx
  800857:	eb 22                	jmp    80087b <getuint+0x38>
	else if (lflag)
  800859:	85 d2                	test   %edx,%edx
  80085b:	74 10                	je     80086d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80085d:	8b 10                	mov    (%eax),%edx
  80085f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800862:	89 08                	mov    %ecx,(%eax)
  800864:	8b 02                	mov    (%edx),%eax
  800866:	ba 00 00 00 00       	mov    $0x0,%edx
  80086b:	eb 0e                	jmp    80087b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80086d:	8b 10                	mov    (%eax),%edx
  80086f:	8d 4a 04             	lea    0x4(%edx),%ecx
  800872:	89 08                	mov    %ecx,(%eax)
  800874:	8b 02                	mov    (%edx),%eax
  800876:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80087b:	5d                   	pop    %ebp
  80087c:	c3                   	ret    

0080087d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80087d:	55                   	push   %ebp
  80087e:	89 e5                	mov    %esp,%ebp
  800880:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800883:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800887:	8b 10                	mov    (%eax),%edx
  800889:	3b 50 04             	cmp    0x4(%eax),%edx
  80088c:	73 0a                	jae    800898 <sprintputch+0x1b>
		*b->buf++ = ch;
  80088e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800891:	88 0a                	mov    %cl,(%edx)
  800893:	83 c2 01             	add    $0x1,%edx
  800896:	89 10                	mov    %edx,(%eax)
}
  800898:	5d                   	pop    %ebp
  800899:	c3                   	ret    

0080089a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80089a:	55                   	push   %ebp
  80089b:	89 e5                	mov    %esp,%ebp
  80089d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8008a0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8008a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8008a7:	8b 45 10             	mov    0x10(%ebp),%eax
  8008aa:	89 44 24 08          	mov    %eax,0x8(%esp)
  8008ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008b1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8008b5:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b8:	89 04 24             	mov    %eax,(%esp)
  8008bb:	e8 02 00 00 00       	call   8008c2 <vprintfmt>
	va_end(ap);
}
  8008c0:	c9                   	leave  
  8008c1:	c3                   	ret    

008008c2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8008c2:	55                   	push   %ebp
  8008c3:	89 e5                	mov    %esp,%ebp
  8008c5:	57                   	push   %edi
  8008c6:	56                   	push   %esi
  8008c7:	53                   	push   %ebx
  8008c8:	83 ec 4c             	sub    $0x4c,%esp
  8008cb:	8b 75 08             	mov    0x8(%ebp),%esi
  8008ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8008d1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8008d4:	eb 11                	jmp    8008e7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8008d6:	85 c0                	test   %eax,%eax
  8008d8:	0f 84 db 03 00 00    	je     800cb9 <vprintfmt+0x3f7>
				return;
			putch(ch, putdat);
  8008de:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8008e2:	89 04 24             	mov    %eax,(%esp)
  8008e5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8008e7:	0f b6 07             	movzbl (%edi),%eax
  8008ea:	83 c7 01             	add    $0x1,%edi
  8008ed:	83 f8 25             	cmp    $0x25,%eax
  8008f0:	75 e4                	jne    8008d6 <vprintfmt+0x14>
  8008f2:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  8008f6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  8008fd:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800904:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80090b:	ba 00 00 00 00       	mov    $0x0,%edx
  800910:	eb 2b                	jmp    80093d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800912:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800915:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  800919:	eb 22                	jmp    80093d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80091b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80091e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800922:	eb 19                	jmp    80093d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800924:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800927:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80092e:	eb 0d                	jmp    80093d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800930:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800933:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800936:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80093d:	0f b6 0f             	movzbl (%edi),%ecx
  800940:	8d 47 01             	lea    0x1(%edi),%eax
  800943:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800946:	0f b6 07             	movzbl (%edi),%eax
  800949:	83 e8 23             	sub    $0x23,%eax
  80094c:	3c 55                	cmp    $0x55,%al
  80094e:	0f 87 40 03 00 00    	ja     800c94 <vprintfmt+0x3d2>
  800954:	0f b6 c0             	movzbl %al,%eax
  800957:	ff 24 85 60 1a 80 00 	jmp    *0x801a60(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80095e:	83 e9 30             	sub    $0x30,%ecx
  800961:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
  800964:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
  800968:	8d 48 d0             	lea    -0x30(%eax),%ecx
  80096b:	83 f9 09             	cmp    $0x9,%ecx
  80096e:	77 57                	ja     8009c7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800970:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800973:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800976:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800979:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  80097c:	8d 14 92             	lea    (%edx,%edx,4),%edx
  80097f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  800983:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  800986:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800989:	83 f9 09             	cmp    $0x9,%ecx
  80098c:	76 eb                	jbe    800979 <vprintfmt+0xb7>
  80098e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800991:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800994:	eb 34                	jmp    8009ca <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800996:	8b 45 14             	mov    0x14(%ebp),%eax
  800999:	8d 48 04             	lea    0x4(%eax),%ecx
  80099c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80099f:	8b 00                	mov    (%eax),%eax
  8009a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8009a4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8009a7:	eb 21                	jmp    8009ca <vprintfmt+0x108>

		case '.':
			if (width < 0)
  8009a9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8009ad:	0f 88 71 ff ff ff    	js     800924 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8009b3:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8009b6:	eb 85                	jmp    80093d <vprintfmt+0x7b>
  8009b8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8009bb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8009c2:	e9 76 ff ff ff       	jmp    80093d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8009c7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8009ca:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8009ce:	0f 89 69 ff ff ff    	jns    80093d <vprintfmt+0x7b>
  8009d4:	e9 57 ff ff ff       	jmp    800930 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8009d9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8009dc:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8009df:	e9 59 ff ff ff       	jmp    80093d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8009e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8009e7:	8d 50 04             	lea    0x4(%eax),%edx
  8009ea:	89 55 14             	mov    %edx,0x14(%ebp)
  8009ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8009f1:	8b 00                	mov    (%eax),%eax
  8009f3:	89 04 24             	mov    %eax,(%esp)
  8009f6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8009f8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8009fb:	e9 e7 fe ff ff       	jmp    8008e7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800a00:	8b 45 14             	mov    0x14(%ebp),%eax
  800a03:	8d 50 04             	lea    0x4(%eax),%edx
  800a06:	89 55 14             	mov    %edx,0x14(%ebp)
  800a09:	8b 00                	mov    (%eax),%eax
  800a0b:	89 c2                	mov    %eax,%edx
  800a0d:	c1 fa 1f             	sar    $0x1f,%edx
  800a10:	31 d0                	xor    %edx,%eax
  800a12:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800a14:	83 f8 08             	cmp    $0x8,%eax
  800a17:	7f 0b                	jg     800a24 <vprintfmt+0x162>
  800a19:	8b 14 85 c0 1b 80 00 	mov    0x801bc0(,%eax,4),%edx
  800a20:	85 d2                	test   %edx,%edx
  800a22:	75 20                	jne    800a44 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
  800a24:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800a28:	c7 44 24 08 bf 19 80 	movl   $0x8019bf,0x8(%esp)
  800a2f:	00 
  800a30:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a34:	89 34 24             	mov    %esi,(%esp)
  800a37:	e8 5e fe ff ff       	call   80089a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800a3c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800a3f:	e9 a3 fe ff ff       	jmp    8008e7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800a44:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800a48:	c7 44 24 08 c8 19 80 	movl   $0x8019c8,0x8(%esp)
  800a4f:	00 
  800a50:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800a54:	89 34 24             	mov    %esi,(%esp)
  800a57:	e8 3e fe ff ff       	call   80089a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800a5c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800a5f:	e9 83 fe ff ff       	jmp    8008e7 <vprintfmt+0x25>
  800a64:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800a67:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800a6a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800a6d:	8b 45 14             	mov    0x14(%ebp),%eax
  800a70:	8d 50 04             	lea    0x4(%eax),%edx
  800a73:	89 55 14             	mov    %edx,0x14(%ebp)
  800a76:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800a78:	85 ff                	test   %edi,%edi
  800a7a:	b8 b8 19 80 00       	mov    $0x8019b8,%eax
  800a7f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800a82:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800a86:	74 06                	je     800a8e <vprintfmt+0x1cc>
  800a88:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  800a8c:	7f 16                	jg     800aa4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800a8e:	0f b6 17             	movzbl (%edi),%edx
  800a91:	0f be c2             	movsbl %dl,%eax
  800a94:	83 c7 01             	add    $0x1,%edi
  800a97:	85 c0                	test   %eax,%eax
  800a99:	0f 85 9f 00 00 00    	jne    800b3e <vprintfmt+0x27c>
  800a9f:	e9 8b 00 00 00       	jmp    800b2f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800aa4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800aa8:	89 3c 24             	mov    %edi,(%esp)
  800aab:	e8 c2 02 00 00       	call   800d72 <strnlen>
  800ab0:	8b 55 cc             	mov    -0x34(%ebp),%edx
  800ab3:	29 c2                	sub    %eax,%edx
  800ab5:	89 55 d8             	mov    %edx,-0x28(%ebp)
  800ab8:	85 d2                	test   %edx,%edx
  800aba:	7e d2                	jle    800a8e <vprintfmt+0x1cc>
					putch(padc, putdat);
  800abc:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  800ac0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800ac3:	89 7d cc             	mov    %edi,-0x34(%ebp)
  800ac6:	89 d7                	mov    %edx,%edi
  800ac8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800acc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800acf:	89 04 24             	mov    %eax,(%esp)
  800ad2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800ad4:	83 ef 01             	sub    $0x1,%edi
  800ad7:	75 ef                	jne    800ac8 <vprintfmt+0x206>
  800ad9:	89 7d d8             	mov    %edi,-0x28(%ebp)
  800adc:	8b 7d cc             	mov    -0x34(%ebp),%edi
  800adf:	eb ad                	jmp    800a8e <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800ae1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800ae5:	74 20                	je     800b07 <vprintfmt+0x245>
  800ae7:	0f be d2             	movsbl %dl,%edx
  800aea:	83 ea 20             	sub    $0x20,%edx
  800aed:	83 fa 5e             	cmp    $0x5e,%edx
  800af0:	76 15                	jbe    800b07 <vprintfmt+0x245>
					putch('?', putdat);
  800af2:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800af5:	89 54 24 04          	mov    %edx,0x4(%esp)
  800af9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800b00:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800b03:	ff d1                	call   *%ecx
  800b05:	eb 0f                	jmp    800b16 <vprintfmt+0x254>
				else
					putch(ch, putdat);
  800b07:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800b0a:	89 54 24 04          	mov    %edx,0x4(%esp)
  800b0e:	89 04 24             	mov    %eax,(%esp)
  800b11:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800b14:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800b16:	83 eb 01             	sub    $0x1,%ebx
  800b19:	0f b6 17             	movzbl (%edi),%edx
  800b1c:	0f be c2             	movsbl %dl,%eax
  800b1f:	83 c7 01             	add    $0x1,%edi
  800b22:	85 c0                	test   %eax,%eax
  800b24:	75 24                	jne    800b4a <vprintfmt+0x288>
  800b26:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800b29:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800b2c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800b2f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800b32:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800b36:	0f 8e ab fd ff ff    	jle    8008e7 <vprintfmt+0x25>
  800b3c:	eb 20                	jmp    800b5e <vprintfmt+0x29c>
  800b3e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800b41:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800b44:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800b47:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800b4a:	85 f6                	test   %esi,%esi
  800b4c:	78 93                	js     800ae1 <vprintfmt+0x21f>
  800b4e:	83 ee 01             	sub    $0x1,%esi
  800b51:	79 8e                	jns    800ae1 <vprintfmt+0x21f>
  800b53:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800b56:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  800b59:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800b5c:	eb d1                	jmp    800b2f <vprintfmt+0x26d>
  800b5e:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800b61:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800b65:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800b6c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800b6e:	83 ef 01             	sub    $0x1,%edi
  800b71:	75 ee                	jne    800b61 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800b73:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800b76:	e9 6c fd ff ff       	jmp    8008e7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800b7b:	83 fa 01             	cmp    $0x1,%edx
  800b7e:	66 90                	xchg   %ax,%ax
  800b80:	7e 16                	jle    800b98 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
  800b82:	8b 45 14             	mov    0x14(%ebp),%eax
  800b85:	8d 50 08             	lea    0x8(%eax),%edx
  800b88:	89 55 14             	mov    %edx,0x14(%ebp)
  800b8b:	8b 10                	mov    (%eax),%edx
  800b8d:	8b 48 04             	mov    0x4(%eax),%ecx
  800b90:	89 55 d0             	mov    %edx,-0x30(%ebp)
  800b93:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800b96:	eb 32                	jmp    800bca <vprintfmt+0x308>
	else if (lflag)
  800b98:	85 d2                	test   %edx,%edx
  800b9a:	74 18                	je     800bb4 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
  800b9c:	8b 45 14             	mov    0x14(%ebp),%eax
  800b9f:	8d 50 04             	lea    0x4(%eax),%edx
  800ba2:	89 55 14             	mov    %edx,0x14(%ebp)
  800ba5:	8b 00                	mov    (%eax),%eax
  800ba7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800baa:	89 c1                	mov    %eax,%ecx
  800bac:	c1 f9 1f             	sar    $0x1f,%ecx
  800baf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800bb2:	eb 16                	jmp    800bca <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
  800bb4:	8b 45 14             	mov    0x14(%ebp),%eax
  800bb7:	8d 50 04             	lea    0x4(%eax),%edx
  800bba:	89 55 14             	mov    %edx,0x14(%ebp)
  800bbd:	8b 00                	mov    (%eax),%eax
  800bbf:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800bc2:	89 c7                	mov    %eax,%edi
  800bc4:	c1 ff 1f             	sar    $0x1f,%edi
  800bc7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800bca:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800bcd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800bd0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800bd5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800bd9:	79 7d                	jns    800c58 <vprintfmt+0x396>
				putch('-', putdat);
  800bdb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800bdf:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800be6:	ff d6                	call   *%esi
				num = -(long long) num;
  800be8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800beb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800bee:	f7 d8                	neg    %eax
  800bf0:	83 d2 00             	adc    $0x0,%edx
  800bf3:	f7 da                	neg    %edx
			}
			base = 10;
  800bf5:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800bfa:	eb 5c                	jmp    800c58 <vprintfmt+0x396>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800bfc:	8d 45 14             	lea    0x14(%ebp),%eax
  800bff:	e8 3f fc ff ff       	call   800843 <getuint>
			base = 10;
  800c04:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800c09:	eb 4d                	jmp    800c58 <vprintfmt+0x396>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800c0b:	8d 45 14             	lea    0x14(%ebp),%eax
  800c0e:	e8 30 fc ff ff       	call   800843 <getuint>
			base = 8;
  800c13:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800c18:	eb 3e                	jmp    800c58 <vprintfmt+0x396>

		// pointer
		case 'p':
			putch('0', putdat);
  800c1a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800c1e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800c25:	ff d6                	call   *%esi
			putch('x', putdat);
  800c27:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800c2b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800c32:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800c34:	8b 45 14             	mov    0x14(%ebp),%eax
  800c37:	8d 50 04             	lea    0x4(%eax),%edx
  800c3a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800c3d:	8b 00                	mov    (%eax),%eax
  800c3f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800c44:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800c49:	eb 0d                	jmp    800c58 <vprintfmt+0x396>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800c4b:	8d 45 14             	lea    0x14(%ebp),%eax
  800c4e:	e8 f0 fb ff ff       	call   800843 <getuint>
			base = 16;
  800c53:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800c58:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  800c5c:	89 7c 24 10          	mov    %edi,0x10(%esp)
  800c60:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800c63:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800c67:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c6b:	89 04 24             	mov    %eax,(%esp)
  800c6e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800c72:	89 da                	mov    %ebx,%edx
  800c74:	89 f0                	mov    %esi,%eax
  800c76:	e8 d5 fa ff ff       	call   800750 <printnum>
			break;
  800c7b:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800c7e:	e9 64 fc ff ff       	jmp    8008e7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800c83:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800c87:	89 0c 24             	mov    %ecx,(%esp)
  800c8a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800c8c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800c8f:	e9 53 fc ff ff       	jmp    8008e7 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800c94:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800c98:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800c9f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800ca1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800ca5:	0f 84 3c fc ff ff    	je     8008e7 <vprintfmt+0x25>
  800cab:	83 ef 01             	sub    $0x1,%edi
  800cae:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800cb2:	75 f7                	jne    800cab <vprintfmt+0x3e9>
  800cb4:	e9 2e fc ff ff       	jmp    8008e7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  800cb9:	83 c4 4c             	add    $0x4c,%esp
  800cbc:	5b                   	pop    %ebx
  800cbd:	5e                   	pop    %esi
  800cbe:	5f                   	pop    %edi
  800cbf:	5d                   	pop    %ebp
  800cc0:	c3                   	ret    

00800cc1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800cc1:	55                   	push   %ebp
  800cc2:	89 e5                	mov    %esp,%ebp
  800cc4:	83 ec 28             	sub    $0x28,%esp
  800cc7:	8b 45 08             	mov    0x8(%ebp),%eax
  800cca:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800ccd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800cd0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800cd4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800cd7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800cde:	85 d2                	test   %edx,%edx
  800ce0:	7e 30                	jle    800d12 <vsnprintf+0x51>
  800ce2:	85 c0                	test   %eax,%eax
  800ce4:	74 2c                	je     800d12 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800ce6:	8b 45 14             	mov    0x14(%ebp),%eax
  800ce9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800ced:	8b 45 10             	mov    0x10(%ebp),%eax
  800cf0:	89 44 24 08          	mov    %eax,0x8(%esp)
  800cf4:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800cf7:	89 44 24 04          	mov    %eax,0x4(%esp)
  800cfb:	c7 04 24 7d 08 80 00 	movl   $0x80087d,(%esp)
  800d02:	e8 bb fb ff ff       	call   8008c2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800d07:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800d0a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800d0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800d10:	eb 05                	jmp    800d17 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800d12:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800d17:	c9                   	leave  
  800d18:	c3                   	ret    

00800d19 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800d19:	55                   	push   %ebp
  800d1a:	89 e5                	mov    %esp,%ebp
  800d1c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800d1f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800d22:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800d26:	8b 45 10             	mov    0x10(%ebp),%eax
  800d29:	89 44 24 08          	mov    %eax,0x8(%esp)
  800d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d30:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d34:	8b 45 08             	mov    0x8(%ebp),%eax
  800d37:	89 04 24             	mov    %eax,(%esp)
  800d3a:	e8 82 ff ff ff       	call   800cc1 <vsnprintf>
	va_end(ap);

	return rc;
}
  800d3f:	c9                   	leave  
  800d40:	c3                   	ret    
  800d41:	66 90                	xchg   %ax,%ax
  800d43:	66 90                	xchg   %ax,%ax
  800d45:	66 90                	xchg   %ax,%ax
  800d47:	66 90                	xchg   %ax,%ax
  800d49:	66 90                	xchg   %ax,%ax
  800d4b:	66 90                	xchg   %ax,%ax
  800d4d:	66 90                	xchg   %ax,%ax
  800d4f:	90                   	nop

00800d50 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800d50:	55                   	push   %ebp
  800d51:	89 e5                	mov    %esp,%ebp
  800d53:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800d56:	80 3a 00             	cmpb   $0x0,(%edx)
  800d59:	74 10                	je     800d6b <strlen+0x1b>
  800d5b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800d60:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800d63:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800d67:	75 f7                	jne    800d60 <strlen+0x10>
  800d69:	eb 05                	jmp    800d70 <strlen+0x20>
  800d6b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800d70:	5d                   	pop    %ebp
  800d71:	c3                   	ret    

00800d72 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800d72:	55                   	push   %ebp
  800d73:	89 e5                	mov    %esp,%ebp
  800d75:	53                   	push   %ebx
  800d76:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800d79:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800d7c:	85 c9                	test   %ecx,%ecx
  800d7e:	74 1c                	je     800d9c <strnlen+0x2a>
  800d80:	80 3b 00             	cmpb   $0x0,(%ebx)
  800d83:	74 1e                	je     800da3 <strnlen+0x31>
  800d85:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  800d8a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800d8c:	39 ca                	cmp    %ecx,%edx
  800d8e:	74 18                	je     800da8 <strnlen+0x36>
  800d90:	83 c2 01             	add    $0x1,%edx
  800d93:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  800d98:	75 f0                	jne    800d8a <strnlen+0x18>
  800d9a:	eb 0c                	jmp    800da8 <strnlen+0x36>
  800d9c:	b8 00 00 00 00       	mov    $0x0,%eax
  800da1:	eb 05                	jmp    800da8 <strnlen+0x36>
  800da3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800da8:	5b                   	pop    %ebx
  800da9:	5d                   	pop    %ebp
  800daa:	c3                   	ret    

00800dab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800dab:	55                   	push   %ebp
  800dac:	89 e5                	mov    %esp,%ebp
  800dae:	53                   	push   %ebx
  800daf:	8b 45 08             	mov    0x8(%ebp),%eax
  800db2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800db5:	89 c2                	mov    %eax,%edx
  800db7:	0f b6 19             	movzbl (%ecx),%ebx
  800dba:	88 1a                	mov    %bl,(%edx)
  800dbc:	83 c2 01             	add    $0x1,%edx
  800dbf:	83 c1 01             	add    $0x1,%ecx
  800dc2:	84 db                	test   %bl,%bl
  800dc4:	75 f1                	jne    800db7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800dc6:	5b                   	pop    %ebx
  800dc7:	5d                   	pop    %ebp
  800dc8:	c3                   	ret    

00800dc9 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800dc9:	55                   	push   %ebp
  800dca:	89 e5                	mov    %esp,%ebp
  800dcc:	53                   	push   %ebx
  800dcd:	83 ec 08             	sub    $0x8,%esp
  800dd0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800dd3:	89 1c 24             	mov    %ebx,(%esp)
  800dd6:	e8 75 ff ff ff       	call   800d50 <strlen>
	strcpy(dst + len, src);
  800ddb:	8b 55 0c             	mov    0xc(%ebp),%edx
  800dde:	89 54 24 04          	mov    %edx,0x4(%esp)
  800de2:	01 d8                	add    %ebx,%eax
  800de4:	89 04 24             	mov    %eax,(%esp)
  800de7:	e8 bf ff ff ff       	call   800dab <strcpy>
	return dst;
}
  800dec:	89 d8                	mov    %ebx,%eax
  800dee:	83 c4 08             	add    $0x8,%esp
  800df1:	5b                   	pop    %ebx
  800df2:	5d                   	pop    %ebp
  800df3:	c3                   	ret    

00800df4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800df4:	55                   	push   %ebp
  800df5:	89 e5                	mov    %esp,%ebp
  800df7:	56                   	push   %esi
  800df8:	53                   	push   %ebx
  800df9:	8b 75 08             	mov    0x8(%ebp),%esi
  800dfc:	8b 55 0c             	mov    0xc(%ebp),%edx
  800dff:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800e02:	85 db                	test   %ebx,%ebx
  800e04:	74 16                	je     800e1c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
  800e06:	01 f3                	add    %esi,%ebx
  800e08:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
  800e0a:	0f b6 02             	movzbl (%edx),%eax
  800e0d:	88 01                	mov    %al,(%ecx)
  800e0f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800e12:	80 3a 01             	cmpb   $0x1,(%edx)
  800e15:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800e18:	39 d9                	cmp    %ebx,%ecx
  800e1a:	75 ee                	jne    800e0a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800e1c:	89 f0                	mov    %esi,%eax
  800e1e:	5b                   	pop    %ebx
  800e1f:	5e                   	pop    %esi
  800e20:	5d                   	pop    %ebp
  800e21:	c3                   	ret    

00800e22 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800e22:	55                   	push   %ebp
  800e23:	89 e5                	mov    %esp,%ebp
  800e25:	57                   	push   %edi
  800e26:	56                   	push   %esi
  800e27:	53                   	push   %ebx
  800e28:	8b 7d 08             	mov    0x8(%ebp),%edi
  800e2b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800e2e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800e31:	89 f8                	mov    %edi,%eax
  800e33:	85 f6                	test   %esi,%esi
  800e35:	74 33                	je     800e6a <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
  800e37:	83 fe 01             	cmp    $0x1,%esi
  800e3a:	74 25                	je     800e61 <strlcpy+0x3f>
  800e3c:	0f b6 0b             	movzbl (%ebx),%ecx
  800e3f:	84 c9                	test   %cl,%cl
  800e41:	74 22                	je     800e65 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
  800e43:	83 ee 02             	sub    $0x2,%esi
  800e46:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800e4b:	88 08                	mov    %cl,(%eax)
  800e4d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800e50:	39 f2                	cmp    %esi,%edx
  800e52:	74 13                	je     800e67 <strlcpy+0x45>
  800e54:	83 c2 01             	add    $0x1,%edx
  800e57:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  800e5b:	84 c9                	test   %cl,%cl
  800e5d:	75 ec                	jne    800e4b <strlcpy+0x29>
  800e5f:	eb 06                	jmp    800e67 <strlcpy+0x45>
  800e61:	89 f8                	mov    %edi,%eax
  800e63:	eb 02                	jmp    800e67 <strlcpy+0x45>
  800e65:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  800e67:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800e6a:	29 f8                	sub    %edi,%eax
}
  800e6c:	5b                   	pop    %ebx
  800e6d:	5e                   	pop    %esi
  800e6e:	5f                   	pop    %edi
  800e6f:	5d                   	pop    %ebp
  800e70:	c3                   	ret    

00800e71 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800e71:	55                   	push   %ebp
  800e72:	89 e5                	mov    %esp,%ebp
  800e74:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800e77:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800e7a:	0f b6 01             	movzbl (%ecx),%eax
  800e7d:	84 c0                	test   %al,%al
  800e7f:	74 15                	je     800e96 <strcmp+0x25>
  800e81:	3a 02                	cmp    (%edx),%al
  800e83:	75 11                	jne    800e96 <strcmp+0x25>
		p++, q++;
  800e85:	83 c1 01             	add    $0x1,%ecx
  800e88:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800e8b:	0f b6 01             	movzbl (%ecx),%eax
  800e8e:	84 c0                	test   %al,%al
  800e90:	74 04                	je     800e96 <strcmp+0x25>
  800e92:	3a 02                	cmp    (%edx),%al
  800e94:	74 ef                	je     800e85 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800e96:	0f b6 c0             	movzbl %al,%eax
  800e99:	0f b6 12             	movzbl (%edx),%edx
  800e9c:	29 d0                	sub    %edx,%eax
}
  800e9e:	5d                   	pop    %ebp
  800e9f:	c3                   	ret    

00800ea0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800ea0:	55                   	push   %ebp
  800ea1:	89 e5                	mov    %esp,%ebp
  800ea3:	56                   	push   %esi
  800ea4:	53                   	push   %ebx
  800ea5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800ea8:	8b 55 0c             	mov    0xc(%ebp),%edx
  800eab:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800eae:	85 f6                	test   %esi,%esi
  800eb0:	74 29                	je     800edb <strncmp+0x3b>
  800eb2:	0f b6 03             	movzbl (%ebx),%eax
  800eb5:	84 c0                	test   %al,%al
  800eb7:	74 30                	je     800ee9 <strncmp+0x49>
  800eb9:	3a 02                	cmp    (%edx),%al
  800ebb:	75 2c                	jne    800ee9 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
  800ebd:	8d 43 01             	lea    0x1(%ebx),%eax
  800ec0:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
  800ec2:	89 c3                	mov    %eax,%ebx
  800ec4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800ec7:	39 f0                	cmp    %esi,%eax
  800ec9:	74 17                	je     800ee2 <strncmp+0x42>
  800ecb:	0f b6 08             	movzbl (%eax),%ecx
  800ece:	84 c9                	test   %cl,%cl
  800ed0:	74 17                	je     800ee9 <strncmp+0x49>
  800ed2:	83 c0 01             	add    $0x1,%eax
  800ed5:	3a 0a                	cmp    (%edx),%cl
  800ed7:	74 e9                	je     800ec2 <strncmp+0x22>
  800ed9:	eb 0e                	jmp    800ee9 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800edb:	b8 00 00 00 00       	mov    $0x0,%eax
  800ee0:	eb 0f                	jmp    800ef1 <strncmp+0x51>
  800ee2:	b8 00 00 00 00       	mov    $0x0,%eax
  800ee7:	eb 08                	jmp    800ef1 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800ee9:	0f b6 03             	movzbl (%ebx),%eax
  800eec:	0f b6 12             	movzbl (%edx),%edx
  800eef:	29 d0                	sub    %edx,%eax
}
  800ef1:	5b                   	pop    %ebx
  800ef2:	5e                   	pop    %esi
  800ef3:	5d                   	pop    %ebp
  800ef4:	c3                   	ret    

00800ef5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800ef5:	55                   	push   %ebp
  800ef6:	89 e5                	mov    %esp,%ebp
  800ef8:	53                   	push   %ebx
  800ef9:	8b 45 08             	mov    0x8(%ebp),%eax
  800efc:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800eff:	0f b6 18             	movzbl (%eax),%ebx
  800f02:	84 db                	test   %bl,%bl
  800f04:	74 1d                	je     800f23 <strchr+0x2e>
  800f06:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800f08:	38 d3                	cmp    %dl,%bl
  800f0a:	75 06                	jne    800f12 <strchr+0x1d>
  800f0c:	eb 1a                	jmp    800f28 <strchr+0x33>
  800f0e:	38 ca                	cmp    %cl,%dl
  800f10:	74 16                	je     800f28 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800f12:	83 c0 01             	add    $0x1,%eax
  800f15:	0f b6 10             	movzbl (%eax),%edx
  800f18:	84 d2                	test   %dl,%dl
  800f1a:	75 f2                	jne    800f0e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800f1c:	b8 00 00 00 00       	mov    $0x0,%eax
  800f21:	eb 05                	jmp    800f28 <strchr+0x33>
  800f23:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800f28:	5b                   	pop    %ebx
  800f29:	5d                   	pop    %ebp
  800f2a:	c3                   	ret    

00800f2b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800f2b:	55                   	push   %ebp
  800f2c:	89 e5                	mov    %esp,%ebp
  800f2e:	53                   	push   %ebx
  800f2f:	8b 45 08             	mov    0x8(%ebp),%eax
  800f32:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800f35:	0f b6 18             	movzbl (%eax),%ebx
  800f38:	84 db                	test   %bl,%bl
  800f3a:	74 16                	je     800f52 <strfind+0x27>
  800f3c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800f3e:	38 d3                	cmp    %dl,%bl
  800f40:	75 06                	jne    800f48 <strfind+0x1d>
  800f42:	eb 0e                	jmp    800f52 <strfind+0x27>
  800f44:	38 ca                	cmp    %cl,%dl
  800f46:	74 0a                	je     800f52 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800f48:	83 c0 01             	add    $0x1,%eax
  800f4b:	0f b6 10             	movzbl (%eax),%edx
  800f4e:	84 d2                	test   %dl,%dl
  800f50:	75 f2                	jne    800f44 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800f52:	5b                   	pop    %ebx
  800f53:	5d                   	pop    %ebp
  800f54:	c3                   	ret    

00800f55 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800f55:	55                   	push   %ebp
  800f56:	89 e5                	mov    %esp,%ebp
  800f58:	83 ec 0c             	sub    $0xc,%esp
  800f5b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800f5e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800f61:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800f64:	8b 7d 08             	mov    0x8(%ebp),%edi
  800f67:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800f6a:	85 c9                	test   %ecx,%ecx
  800f6c:	74 36                	je     800fa4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800f6e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800f74:	75 28                	jne    800f9e <memset+0x49>
  800f76:	f6 c1 03             	test   $0x3,%cl
  800f79:	75 23                	jne    800f9e <memset+0x49>
		c &= 0xFF;
  800f7b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800f7f:	89 d3                	mov    %edx,%ebx
  800f81:	c1 e3 08             	shl    $0x8,%ebx
  800f84:	89 d6                	mov    %edx,%esi
  800f86:	c1 e6 18             	shl    $0x18,%esi
  800f89:	89 d0                	mov    %edx,%eax
  800f8b:	c1 e0 10             	shl    $0x10,%eax
  800f8e:	09 f0                	or     %esi,%eax
  800f90:	09 c2                	or     %eax,%edx
  800f92:	89 d0                	mov    %edx,%eax
  800f94:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800f96:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800f99:	fc                   	cld    
  800f9a:	f3 ab                	rep stos %eax,%es:(%edi)
  800f9c:	eb 06                	jmp    800fa4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800f9e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800fa1:	fc                   	cld    
  800fa2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800fa4:	89 f8                	mov    %edi,%eax
  800fa6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800fa9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800fac:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800faf:	89 ec                	mov    %ebp,%esp
  800fb1:	5d                   	pop    %ebp
  800fb2:	c3                   	ret    

00800fb3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800fb3:	55                   	push   %ebp
  800fb4:	89 e5                	mov    %esp,%ebp
  800fb6:	83 ec 08             	sub    $0x8,%esp
  800fb9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800fbc:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800fbf:	8b 45 08             	mov    0x8(%ebp),%eax
  800fc2:	8b 75 0c             	mov    0xc(%ebp),%esi
  800fc5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800fc8:	39 c6                	cmp    %eax,%esi
  800fca:	73 36                	jae    801002 <memmove+0x4f>
  800fcc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800fcf:	39 d0                	cmp    %edx,%eax
  800fd1:	73 2f                	jae    801002 <memmove+0x4f>
		s += n;
		d += n;
  800fd3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800fd6:	f6 c2 03             	test   $0x3,%dl
  800fd9:	75 1b                	jne    800ff6 <memmove+0x43>
  800fdb:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800fe1:	75 13                	jne    800ff6 <memmove+0x43>
  800fe3:	f6 c1 03             	test   $0x3,%cl
  800fe6:	75 0e                	jne    800ff6 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800fe8:	83 ef 04             	sub    $0x4,%edi
  800feb:	8d 72 fc             	lea    -0x4(%edx),%esi
  800fee:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800ff1:	fd                   	std    
  800ff2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ff4:	eb 09                	jmp    800fff <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800ff6:	83 ef 01             	sub    $0x1,%edi
  800ff9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800ffc:	fd                   	std    
  800ffd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800fff:	fc                   	cld    
  801000:	eb 20                	jmp    801022 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  801002:	f7 c6 03 00 00 00    	test   $0x3,%esi
  801008:	75 13                	jne    80101d <memmove+0x6a>
  80100a:	a8 03                	test   $0x3,%al
  80100c:	75 0f                	jne    80101d <memmove+0x6a>
  80100e:	f6 c1 03             	test   $0x3,%cl
  801011:	75 0a                	jne    80101d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  801013:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  801016:	89 c7                	mov    %eax,%edi
  801018:	fc                   	cld    
  801019:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80101b:	eb 05                	jmp    801022 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80101d:	89 c7                	mov    %eax,%edi
  80101f:	fc                   	cld    
  801020:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  801022:	8b 75 f8             	mov    -0x8(%ebp),%esi
  801025:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801028:	89 ec                	mov    %ebp,%esp
  80102a:	5d                   	pop    %ebp
  80102b:	c3                   	ret    

0080102c <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  80102c:	55                   	push   %ebp
  80102d:	89 e5                	mov    %esp,%ebp
  80102f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  801032:	8b 45 10             	mov    0x10(%ebp),%eax
  801035:	89 44 24 08          	mov    %eax,0x8(%esp)
  801039:	8b 45 0c             	mov    0xc(%ebp),%eax
  80103c:	89 44 24 04          	mov    %eax,0x4(%esp)
  801040:	8b 45 08             	mov    0x8(%ebp),%eax
  801043:	89 04 24             	mov    %eax,(%esp)
  801046:	e8 68 ff ff ff       	call   800fb3 <memmove>
}
  80104b:	c9                   	leave  
  80104c:	c3                   	ret    

0080104d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80104d:	55                   	push   %ebp
  80104e:	89 e5                	mov    %esp,%ebp
  801050:	57                   	push   %edi
  801051:	56                   	push   %esi
  801052:	53                   	push   %ebx
  801053:	8b 5d 08             	mov    0x8(%ebp),%ebx
  801056:	8b 75 0c             	mov    0xc(%ebp),%esi
  801059:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80105c:	8d 78 ff             	lea    -0x1(%eax),%edi
  80105f:	85 c0                	test   %eax,%eax
  801061:	74 36                	je     801099 <memcmp+0x4c>
		if (*s1 != *s2)
  801063:	0f b6 03             	movzbl (%ebx),%eax
  801066:	0f b6 0e             	movzbl (%esi),%ecx
  801069:	38 c8                	cmp    %cl,%al
  80106b:	75 17                	jne    801084 <memcmp+0x37>
  80106d:	ba 00 00 00 00       	mov    $0x0,%edx
  801072:	eb 1a                	jmp    80108e <memcmp+0x41>
  801074:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  801079:	83 c2 01             	add    $0x1,%edx
  80107c:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  801080:	38 c8                	cmp    %cl,%al
  801082:	74 0a                	je     80108e <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  801084:	0f b6 c0             	movzbl %al,%eax
  801087:	0f b6 c9             	movzbl %cl,%ecx
  80108a:	29 c8                	sub    %ecx,%eax
  80108c:	eb 10                	jmp    80109e <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80108e:	39 fa                	cmp    %edi,%edx
  801090:	75 e2                	jne    801074 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  801092:	b8 00 00 00 00       	mov    $0x0,%eax
  801097:	eb 05                	jmp    80109e <memcmp+0x51>
  801099:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80109e:	5b                   	pop    %ebx
  80109f:	5e                   	pop    %esi
  8010a0:	5f                   	pop    %edi
  8010a1:	5d                   	pop    %ebp
  8010a2:	c3                   	ret    

008010a3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8010a3:	55                   	push   %ebp
  8010a4:	89 e5                	mov    %esp,%ebp
  8010a6:	53                   	push   %ebx
  8010a7:	8b 45 08             	mov    0x8(%ebp),%eax
  8010aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  8010ad:	89 c2                	mov    %eax,%edx
  8010af:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8010b2:	39 d0                	cmp    %edx,%eax
  8010b4:	73 13                	jae    8010c9 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  8010b6:	89 d9                	mov    %ebx,%ecx
  8010b8:	38 18                	cmp    %bl,(%eax)
  8010ba:	75 06                	jne    8010c2 <memfind+0x1f>
  8010bc:	eb 0b                	jmp    8010c9 <memfind+0x26>
  8010be:	38 08                	cmp    %cl,(%eax)
  8010c0:	74 07                	je     8010c9 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8010c2:	83 c0 01             	add    $0x1,%eax
  8010c5:	39 d0                	cmp    %edx,%eax
  8010c7:	75 f5                	jne    8010be <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8010c9:	5b                   	pop    %ebx
  8010ca:	5d                   	pop    %ebp
  8010cb:	c3                   	ret    

008010cc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8010cc:	55                   	push   %ebp
  8010cd:	89 e5                	mov    %esp,%ebp
  8010cf:	57                   	push   %edi
  8010d0:	56                   	push   %esi
  8010d1:	53                   	push   %ebx
  8010d2:	83 ec 04             	sub    $0x4,%esp
  8010d5:	8b 55 08             	mov    0x8(%ebp),%edx
  8010d8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8010db:	0f b6 02             	movzbl (%edx),%eax
  8010de:	3c 09                	cmp    $0x9,%al
  8010e0:	74 04                	je     8010e6 <strtol+0x1a>
  8010e2:	3c 20                	cmp    $0x20,%al
  8010e4:	75 0e                	jne    8010f4 <strtol+0x28>
		s++;
  8010e6:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8010e9:	0f b6 02             	movzbl (%edx),%eax
  8010ec:	3c 09                	cmp    $0x9,%al
  8010ee:	74 f6                	je     8010e6 <strtol+0x1a>
  8010f0:	3c 20                	cmp    $0x20,%al
  8010f2:	74 f2                	je     8010e6 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
  8010f4:	3c 2b                	cmp    $0x2b,%al
  8010f6:	75 0a                	jne    801102 <strtol+0x36>
		s++;
  8010f8:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8010fb:	bf 00 00 00 00       	mov    $0x0,%edi
  801100:	eb 10                	jmp    801112 <strtol+0x46>
  801102:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  801107:	3c 2d                	cmp    $0x2d,%al
  801109:	75 07                	jne    801112 <strtol+0x46>
		s++, neg = 1;
  80110b:	83 c2 01             	add    $0x1,%edx
  80110e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  801112:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  801118:	75 15                	jne    80112f <strtol+0x63>
  80111a:	80 3a 30             	cmpb   $0x30,(%edx)
  80111d:	75 10                	jne    80112f <strtol+0x63>
  80111f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  801123:	75 0a                	jne    80112f <strtol+0x63>
		s += 2, base = 16;
  801125:	83 c2 02             	add    $0x2,%edx
  801128:	bb 10 00 00 00       	mov    $0x10,%ebx
  80112d:	eb 10                	jmp    80113f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
  80112f:	85 db                	test   %ebx,%ebx
  801131:	75 0c                	jne    80113f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  801133:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  801135:	80 3a 30             	cmpb   $0x30,(%edx)
  801138:	75 05                	jne    80113f <strtol+0x73>
		s++, base = 8;
  80113a:	83 c2 01             	add    $0x1,%edx
  80113d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  80113f:	b8 00 00 00 00       	mov    $0x0,%eax
  801144:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  801147:	0f b6 0a             	movzbl (%edx),%ecx
  80114a:	8d 71 d0             	lea    -0x30(%ecx),%esi
  80114d:	89 f3                	mov    %esi,%ebx
  80114f:	80 fb 09             	cmp    $0x9,%bl
  801152:	77 08                	ja     80115c <strtol+0x90>
			dig = *s - '0';
  801154:	0f be c9             	movsbl %cl,%ecx
  801157:	83 e9 30             	sub    $0x30,%ecx
  80115a:	eb 22                	jmp    80117e <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
  80115c:	8d 71 9f             	lea    -0x61(%ecx),%esi
  80115f:	89 f3                	mov    %esi,%ebx
  801161:	80 fb 19             	cmp    $0x19,%bl
  801164:	77 08                	ja     80116e <strtol+0xa2>
			dig = *s - 'a' + 10;
  801166:	0f be c9             	movsbl %cl,%ecx
  801169:	83 e9 57             	sub    $0x57,%ecx
  80116c:	eb 10                	jmp    80117e <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
  80116e:	8d 71 bf             	lea    -0x41(%ecx),%esi
  801171:	89 f3                	mov    %esi,%ebx
  801173:	80 fb 19             	cmp    $0x19,%bl
  801176:	77 16                	ja     80118e <strtol+0xc2>
			dig = *s - 'A' + 10;
  801178:	0f be c9             	movsbl %cl,%ecx
  80117b:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  80117e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  801181:	7d 0f                	jge    801192 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
  801183:	83 c2 01             	add    $0x1,%edx
  801186:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  80118a:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  80118c:	eb b9                	jmp    801147 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  80118e:	89 c1                	mov    %eax,%ecx
  801190:	eb 02                	jmp    801194 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  801192:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  801194:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  801198:	74 05                	je     80119f <strtol+0xd3>
		*endptr = (char *) s;
  80119a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80119d:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  80119f:	89 ca                	mov    %ecx,%edx
  8011a1:	f7 da                	neg    %edx
  8011a3:	85 ff                	test   %edi,%edi
  8011a5:	0f 45 c2             	cmovne %edx,%eax
}
  8011a8:	83 c4 04             	add    $0x4,%esp
  8011ab:	5b                   	pop    %ebx
  8011ac:	5e                   	pop    %esi
  8011ad:	5f                   	pop    %edi
  8011ae:	5d                   	pop    %ebp
  8011af:	c3                   	ret    

008011b0 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8011b0:	55                   	push   %ebp
  8011b1:	89 e5                	mov    %esp,%ebp
  8011b3:	83 ec 0c             	sub    $0xc,%esp
  8011b6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8011b9:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8011bc:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8011bf:	b8 00 00 00 00       	mov    $0x0,%eax
  8011c4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8011c7:	8b 55 08             	mov    0x8(%ebp),%edx
  8011ca:	89 c3                	mov    %eax,%ebx
  8011cc:	89 c7                	mov    %eax,%edi
  8011ce:	89 c6                	mov    %eax,%esi
  8011d0:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8011d2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8011d5:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8011d8:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8011db:	89 ec                	mov    %ebp,%esp
  8011dd:	5d                   	pop    %ebp
  8011de:	c3                   	ret    

008011df <sys_cgetc>:

int
sys_cgetc(void)
{
  8011df:	55                   	push   %ebp
  8011e0:	89 e5                	mov    %esp,%ebp
  8011e2:	83 ec 0c             	sub    $0xc,%esp
  8011e5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8011e8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8011eb:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8011ee:	ba 00 00 00 00       	mov    $0x0,%edx
  8011f3:	b8 01 00 00 00       	mov    $0x1,%eax
  8011f8:	89 d1                	mov    %edx,%ecx
  8011fa:	89 d3                	mov    %edx,%ebx
  8011fc:	89 d7                	mov    %edx,%edi
  8011fe:	89 d6                	mov    %edx,%esi
  801200:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  801202:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  801205:	8b 75 f8             	mov    -0x8(%ebp),%esi
  801208:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80120b:	89 ec                	mov    %ebp,%esp
  80120d:	5d                   	pop    %ebp
  80120e:	c3                   	ret    

0080120f <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80120f:	55                   	push   %ebp
  801210:	89 e5                	mov    %esp,%ebp
  801212:	83 ec 38             	sub    $0x38,%esp
  801215:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  801218:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80121b:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80121e:	b9 00 00 00 00       	mov    $0x0,%ecx
  801223:	b8 03 00 00 00       	mov    $0x3,%eax
  801228:	8b 55 08             	mov    0x8(%ebp),%edx
  80122b:	89 cb                	mov    %ecx,%ebx
  80122d:	89 cf                	mov    %ecx,%edi
  80122f:	89 ce                	mov    %ecx,%esi
  801231:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  801233:	85 c0                	test   %eax,%eax
  801235:	7e 28                	jle    80125f <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  801237:	89 44 24 10          	mov    %eax,0x10(%esp)
  80123b:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  801242:	00 
  801243:	c7 44 24 08 e4 1b 80 	movl   $0x801be4,0x8(%esp)
  80124a:	00 
  80124b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  801252:	00 
  801253:	c7 04 24 01 1c 80 00 	movl   $0x801c01,(%esp)
  80125a:	e8 c1 f3 ff ff       	call   800620 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80125f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  801262:	8b 75 f8             	mov    -0x8(%ebp),%esi
  801265:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801268:	89 ec                	mov    %ebp,%esp
  80126a:	5d                   	pop    %ebp
  80126b:	c3                   	ret    

0080126c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80126c:	55                   	push   %ebp
  80126d:	89 e5                	mov    %esp,%ebp
  80126f:	83 ec 0c             	sub    $0xc,%esp
  801272:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  801275:	89 75 f8             	mov    %esi,-0x8(%ebp)
  801278:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80127b:	ba 00 00 00 00       	mov    $0x0,%edx
  801280:	b8 02 00 00 00       	mov    $0x2,%eax
  801285:	89 d1                	mov    %edx,%ecx
  801287:	89 d3                	mov    %edx,%ebx
  801289:	89 d7                	mov    %edx,%edi
  80128b:	89 d6                	mov    %edx,%esi
  80128d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80128f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  801292:	8b 75 f8             	mov    -0x8(%ebp),%esi
  801295:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801298:	89 ec                	mov    %ebp,%esp
  80129a:	5d                   	pop    %ebp
  80129b:	c3                   	ret    

0080129c <sys_yield>:

void
sys_yield(void)
{
  80129c:	55                   	push   %ebp
  80129d:	89 e5                	mov    %esp,%ebp
  80129f:	83 ec 0c             	sub    $0xc,%esp
  8012a2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8012a5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8012a8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8012ab:	ba 00 00 00 00       	mov    $0x0,%edx
  8012b0:	b8 0a 00 00 00       	mov    $0xa,%eax
  8012b5:	89 d1                	mov    %edx,%ecx
  8012b7:	89 d3                	mov    %edx,%ebx
  8012b9:	89 d7                	mov    %edx,%edi
  8012bb:	89 d6                	mov    %edx,%esi
  8012bd:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  8012bf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8012c2:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8012c5:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8012c8:	89 ec                	mov    %ebp,%esp
  8012ca:	5d                   	pop    %ebp
  8012cb:	c3                   	ret    

008012cc <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  8012cc:	55                   	push   %ebp
  8012cd:	89 e5                	mov    %esp,%ebp
  8012cf:	83 ec 38             	sub    $0x38,%esp
  8012d2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8012d5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8012d8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8012db:	be 00 00 00 00       	mov    $0x0,%esi
  8012e0:	b8 04 00 00 00       	mov    $0x4,%eax
  8012e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8012e8:	8b 55 08             	mov    0x8(%ebp),%edx
  8012eb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8012ee:	89 f7                	mov    %esi,%edi
  8012f0:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8012f2:	85 c0                	test   %eax,%eax
  8012f4:	7e 28                	jle    80131e <sys_page_alloc+0x52>
		panic("syscall %d returned %d (> 0)", num, ret);
  8012f6:	89 44 24 10          	mov    %eax,0x10(%esp)
  8012fa:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  801301:	00 
  801302:	c7 44 24 08 e4 1b 80 	movl   $0x801be4,0x8(%esp)
  801309:	00 
  80130a:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  801311:	00 
  801312:	c7 04 24 01 1c 80 00 	movl   $0x801c01,(%esp)
  801319:	e8 02 f3 ff ff       	call   800620 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  80131e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  801321:	8b 75 f8             	mov    -0x8(%ebp),%esi
  801324:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801327:	89 ec                	mov    %ebp,%esp
  801329:	5d                   	pop    %ebp
  80132a:	c3                   	ret    

0080132b <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  80132b:	55                   	push   %ebp
  80132c:	89 e5                	mov    %esp,%ebp
  80132e:	83 ec 38             	sub    $0x38,%esp
  801331:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  801334:	89 75 f8             	mov    %esi,-0x8(%ebp)
  801337:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80133a:	b8 05 00 00 00       	mov    $0x5,%eax
  80133f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801342:	8b 55 08             	mov    0x8(%ebp),%edx
  801345:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801348:	8b 7d 14             	mov    0x14(%ebp),%edi
  80134b:	8b 75 18             	mov    0x18(%ebp),%esi
  80134e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  801350:	85 c0                	test   %eax,%eax
  801352:	7e 28                	jle    80137c <sys_page_map+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  801354:	89 44 24 10          	mov    %eax,0x10(%esp)
  801358:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  80135f:	00 
  801360:	c7 44 24 08 e4 1b 80 	movl   $0x801be4,0x8(%esp)
  801367:	00 
  801368:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80136f:	00 
  801370:	c7 04 24 01 1c 80 00 	movl   $0x801c01,(%esp)
  801377:	e8 a4 f2 ff ff       	call   800620 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  80137c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80137f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  801382:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801385:	89 ec                	mov    %ebp,%esp
  801387:	5d                   	pop    %ebp
  801388:	c3                   	ret    

00801389 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  801389:	55                   	push   %ebp
  80138a:	89 e5                	mov    %esp,%ebp
  80138c:	83 ec 38             	sub    $0x38,%esp
  80138f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  801392:	89 75 f8             	mov    %esi,-0x8(%ebp)
  801395:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801398:	bb 00 00 00 00       	mov    $0x0,%ebx
  80139d:	b8 06 00 00 00       	mov    $0x6,%eax
  8013a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8013a5:	8b 55 08             	mov    0x8(%ebp),%edx
  8013a8:	89 df                	mov    %ebx,%edi
  8013aa:	89 de                	mov    %ebx,%esi
  8013ac:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8013ae:	85 c0                	test   %eax,%eax
  8013b0:	7e 28                	jle    8013da <sys_page_unmap+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  8013b2:	89 44 24 10          	mov    %eax,0x10(%esp)
  8013b6:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  8013bd:	00 
  8013be:	c7 44 24 08 e4 1b 80 	movl   $0x801be4,0x8(%esp)
  8013c5:	00 
  8013c6:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8013cd:	00 
  8013ce:	c7 04 24 01 1c 80 00 	movl   $0x801c01,(%esp)
  8013d5:	e8 46 f2 ff ff       	call   800620 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  8013da:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8013dd:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8013e0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8013e3:	89 ec                	mov    %ebp,%esp
  8013e5:	5d                   	pop    %ebp
  8013e6:	c3                   	ret    

008013e7 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  8013e7:	55                   	push   %ebp
  8013e8:	89 e5                	mov    %esp,%ebp
  8013ea:	83 ec 38             	sub    $0x38,%esp
  8013ed:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8013f0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8013f3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8013f6:	bb 00 00 00 00       	mov    $0x0,%ebx
  8013fb:	b8 08 00 00 00       	mov    $0x8,%eax
  801400:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801403:	8b 55 08             	mov    0x8(%ebp),%edx
  801406:	89 df                	mov    %ebx,%edi
  801408:	89 de                	mov    %ebx,%esi
  80140a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80140c:	85 c0                	test   %eax,%eax
  80140e:	7e 28                	jle    801438 <sys_env_set_status+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  801410:	89 44 24 10          	mov    %eax,0x10(%esp)
  801414:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  80141b:	00 
  80141c:	c7 44 24 08 e4 1b 80 	movl   $0x801be4,0x8(%esp)
  801423:	00 
  801424:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80142b:	00 
  80142c:	c7 04 24 01 1c 80 00 	movl   $0x801c01,(%esp)
  801433:	e8 e8 f1 ff ff       	call   800620 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  801438:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80143b:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80143e:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801441:	89 ec                	mov    %ebp,%esp
  801443:	5d                   	pop    %ebp
  801444:	c3                   	ret    

00801445 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  801445:	55                   	push   %ebp
  801446:	89 e5                	mov    %esp,%ebp
  801448:	83 ec 38             	sub    $0x38,%esp
  80144b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80144e:	89 75 f8             	mov    %esi,-0x8(%ebp)
  801451:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801454:	bb 00 00 00 00       	mov    $0x0,%ebx
  801459:	b8 09 00 00 00       	mov    $0x9,%eax
  80145e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801461:	8b 55 08             	mov    0x8(%ebp),%edx
  801464:	89 df                	mov    %ebx,%edi
  801466:	89 de                	mov    %ebx,%esi
  801468:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80146a:	85 c0                	test   %eax,%eax
  80146c:	7e 28                	jle    801496 <sys_env_set_pgfault_upcall+0x51>
		panic("syscall %d returned %d (> 0)", num, ret);
  80146e:	89 44 24 10          	mov    %eax,0x10(%esp)
  801472:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  801479:	00 
  80147a:	c7 44 24 08 e4 1b 80 	movl   $0x801be4,0x8(%esp)
  801481:	00 
  801482:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  801489:	00 
  80148a:	c7 04 24 01 1c 80 00 	movl   $0x801c01,(%esp)
  801491:	e8 8a f1 ff ff       	call   800620 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  801496:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  801499:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80149c:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80149f:	89 ec                	mov    %ebp,%esp
  8014a1:	5d                   	pop    %ebp
  8014a2:	c3                   	ret    

008014a3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8014a3:	55                   	push   %ebp
  8014a4:	89 e5                	mov    %esp,%ebp
  8014a6:	83 ec 0c             	sub    $0xc,%esp
  8014a9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8014ac:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8014af:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8014b2:	be 00 00 00 00       	mov    $0x0,%esi
  8014b7:	b8 0b 00 00 00       	mov    $0xb,%eax
  8014bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8014bf:	8b 55 08             	mov    0x8(%ebp),%edx
  8014c2:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8014c5:	8b 7d 14             	mov    0x14(%ebp),%edi
  8014c8:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8014ca:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8014cd:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8014d0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8014d3:	89 ec                	mov    %ebp,%esp
  8014d5:	5d                   	pop    %ebp
  8014d6:	c3                   	ret    

008014d7 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8014d7:	55                   	push   %ebp
  8014d8:	89 e5                	mov    %esp,%ebp
  8014da:	83 ec 38             	sub    $0x38,%esp
  8014dd:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8014e0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8014e3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8014e6:	b9 00 00 00 00       	mov    $0x0,%ecx
  8014eb:	b8 0c 00 00 00       	mov    $0xc,%eax
  8014f0:	8b 55 08             	mov    0x8(%ebp),%edx
  8014f3:	89 cb                	mov    %ecx,%ebx
  8014f5:	89 cf                	mov    %ecx,%edi
  8014f7:	89 ce                	mov    %ecx,%esi
  8014f9:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8014fb:	85 c0                	test   %eax,%eax
  8014fd:	7e 28                	jle    801527 <sys_ipc_recv+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  8014ff:	89 44 24 10          	mov    %eax,0x10(%esp)
  801503:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  80150a:	00 
  80150b:	c7 44 24 08 e4 1b 80 	movl   $0x801be4,0x8(%esp)
  801512:	00 
  801513:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80151a:	00 
  80151b:	c7 04 24 01 1c 80 00 	movl   $0x801c01,(%esp)
  801522:	e8 f9 f0 ff ff       	call   800620 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  801527:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80152a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80152d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  801530:	89 ec                	mov    %ebp,%esp
  801532:	5d                   	pop    %ebp
  801533:	c3                   	ret    

00801534 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801534:	55                   	push   %ebp
  801535:	89 e5                	mov    %esp,%ebp
  801537:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  80153a:	83 3d d4 20 80 00 00 	cmpl   $0x0,0x8020d4
  801541:	75 1c                	jne    80155f <set_pgfault_handler+0x2b>
		// First time through!
		// LAB 4: Your code here.
		panic("set_pgfault_handler not implemented");
  801543:	c7 44 24 08 10 1c 80 	movl   $0x801c10,0x8(%esp)
  80154a:	00 
  80154b:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  801552:	00 
  801553:	c7 04 24 34 1c 80 00 	movl   $0x801c34,(%esp)
  80155a:	e8 c1 f0 ff ff       	call   800620 <_panic>
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  80155f:	8b 45 08             	mov    0x8(%ebp),%eax
  801562:	a3 d4 20 80 00       	mov    %eax,0x8020d4
}
  801567:	c9                   	leave  
  801568:	c3                   	ret    
  801569:	66 90                	xchg   %ax,%ax
  80156b:	66 90                	xchg   %ax,%ax
  80156d:	66 90                	xchg   %ax,%ax
  80156f:	90                   	nop

00801570 <__udivdi3>:
  801570:	83 ec 1c             	sub    $0x1c,%esp
  801573:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  801577:	89 7c 24 14          	mov    %edi,0x14(%esp)
  80157b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  80157f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  801583:	8b 7c 24 20          	mov    0x20(%esp),%edi
  801587:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  80158b:	85 c0                	test   %eax,%eax
  80158d:	89 74 24 10          	mov    %esi,0x10(%esp)
  801591:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801595:	89 ea                	mov    %ebp,%edx
  801597:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80159b:	75 33                	jne    8015d0 <__udivdi3+0x60>
  80159d:	39 e9                	cmp    %ebp,%ecx
  80159f:	77 6f                	ja     801610 <__udivdi3+0xa0>
  8015a1:	85 c9                	test   %ecx,%ecx
  8015a3:	89 ce                	mov    %ecx,%esi
  8015a5:	75 0b                	jne    8015b2 <__udivdi3+0x42>
  8015a7:	b8 01 00 00 00       	mov    $0x1,%eax
  8015ac:	31 d2                	xor    %edx,%edx
  8015ae:	f7 f1                	div    %ecx
  8015b0:	89 c6                	mov    %eax,%esi
  8015b2:	31 d2                	xor    %edx,%edx
  8015b4:	89 e8                	mov    %ebp,%eax
  8015b6:	f7 f6                	div    %esi
  8015b8:	89 c5                	mov    %eax,%ebp
  8015ba:	89 f8                	mov    %edi,%eax
  8015bc:	f7 f6                	div    %esi
  8015be:	89 ea                	mov    %ebp,%edx
  8015c0:	8b 74 24 10          	mov    0x10(%esp),%esi
  8015c4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8015c8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8015cc:	83 c4 1c             	add    $0x1c,%esp
  8015cf:	c3                   	ret    
  8015d0:	39 e8                	cmp    %ebp,%eax
  8015d2:	77 24                	ja     8015f8 <__udivdi3+0x88>
  8015d4:	0f bd c8             	bsr    %eax,%ecx
  8015d7:	83 f1 1f             	xor    $0x1f,%ecx
  8015da:	89 0c 24             	mov    %ecx,(%esp)
  8015dd:	75 49                	jne    801628 <__udivdi3+0xb8>
  8015df:	8b 74 24 08          	mov    0x8(%esp),%esi
  8015e3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  8015e7:	0f 86 ab 00 00 00    	jbe    801698 <__udivdi3+0x128>
  8015ed:	39 e8                	cmp    %ebp,%eax
  8015ef:	0f 82 a3 00 00 00    	jb     801698 <__udivdi3+0x128>
  8015f5:	8d 76 00             	lea    0x0(%esi),%esi
  8015f8:	31 d2                	xor    %edx,%edx
  8015fa:	31 c0                	xor    %eax,%eax
  8015fc:	8b 74 24 10          	mov    0x10(%esp),%esi
  801600:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801604:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801608:	83 c4 1c             	add    $0x1c,%esp
  80160b:	c3                   	ret    
  80160c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801610:	89 f8                	mov    %edi,%eax
  801612:	f7 f1                	div    %ecx
  801614:	31 d2                	xor    %edx,%edx
  801616:	8b 74 24 10          	mov    0x10(%esp),%esi
  80161a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  80161e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  801622:	83 c4 1c             	add    $0x1c,%esp
  801625:	c3                   	ret    
  801626:	66 90                	xchg   %ax,%ax
  801628:	0f b6 0c 24          	movzbl (%esp),%ecx
  80162c:	89 c6                	mov    %eax,%esi
  80162e:	b8 20 00 00 00       	mov    $0x20,%eax
  801633:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  801637:	2b 04 24             	sub    (%esp),%eax
  80163a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  80163e:	d3 e6                	shl    %cl,%esi
  801640:	89 c1                	mov    %eax,%ecx
  801642:	d3 ed                	shr    %cl,%ebp
  801644:	0f b6 0c 24          	movzbl (%esp),%ecx
  801648:	09 f5                	or     %esi,%ebp
  80164a:	8b 74 24 04          	mov    0x4(%esp),%esi
  80164e:	d3 e6                	shl    %cl,%esi
  801650:	89 c1                	mov    %eax,%ecx
  801652:	89 74 24 04          	mov    %esi,0x4(%esp)
  801656:	89 d6                	mov    %edx,%esi
  801658:	d3 ee                	shr    %cl,%esi
  80165a:	0f b6 0c 24          	movzbl (%esp),%ecx
  80165e:	d3 e2                	shl    %cl,%edx
  801660:	89 c1                	mov    %eax,%ecx
  801662:	d3 ef                	shr    %cl,%edi
  801664:	09 d7                	or     %edx,%edi
  801666:	89 f2                	mov    %esi,%edx
  801668:	89 f8                	mov    %edi,%eax
  80166a:	f7 f5                	div    %ebp
  80166c:	89 d6                	mov    %edx,%esi
  80166e:	89 c7                	mov    %eax,%edi
  801670:	f7 64 24 04          	mull   0x4(%esp)
  801674:	39 d6                	cmp    %edx,%esi
  801676:	72 30                	jb     8016a8 <__udivdi3+0x138>
  801678:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  80167c:	0f b6 0c 24          	movzbl (%esp),%ecx
  801680:	d3 e5                	shl    %cl,%ebp
  801682:	39 c5                	cmp    %eax,%ebp
  801684:	73 04                	jae    80168a <__udivdi3+0x11a>
  801686:	39 d6                	cmp    %edx,%esi
  801688:	74 1e                	je     8016a8 <__udivdi3+0x138>
  80168a:	89 f8                	mov    %edi,%eax
  80168c:	31 d2                	xor    %edx,%edx
  80168e:	e9 69 ff ff ff       	jmp    8015fc <__udivdi3+0x8c>
  801693:	90                   	nop
  801694:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801698:	31 d2                	xor    %edx,%edx
  80169a:	b8 01 00 00 00       	mov    $0x1,%eax
  80169f:	e9 58 ff ff ff       	jmp    8015fc <__udivdi3+0x8c>
  8016a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8016a8:	8d 47 ff             	lea    -0x1(%edi),%eax
  8016ab:	31 d2                	xor    %edx,%edx
  8016ad:	8b 74 24 10          	mov    0x10(%esp),%esi
  8016b1:	8b 7c 24 14          	mov    0x14(%esp),%edi
  8016b5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  8016b9:	83 c4 1c             	add    $0x1c,%esp
  8016bc:	c3                   	ret    
  8016bd:	66 90                	xchg   %ax,%ax
  8016bf:	90                   	nop

008016c0 <__umoddi3>:
  8016c0:	83 ec 2c             	sub    $0x2c,%esp
  8016c3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  8016c7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  8016cb:	89 74 24 20          	mov    %esi,0x20(%esp)
  8016cf:	8b 74 24 38          	mov    0x38(%esp),%esi
  8016d3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  8016d7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  8016db:	85 c0                	test   %eax,%eax
  8016dd:	89 c2                	mov    %eax,%edx
  8016df:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  8016e3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  8016e7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8016eb:	89 74 24 10          	mov    %esi,0x10(%esp)
  8016ef:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  8016f3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8016f7:	75 1f                	jne    801718 <__umoddi3+0x58>
  8016f9:	39 fe                	cmp    %edi,%esi
  8016fb:	76 63                	jbe    801760 <__umoddi3+0xa0>
  8016fd:	89 c8                	mov    %ecx,%eax
  8016ff:	89 fa                	mov    %edi,%edx
  801701:	f7 f6                	div    %esi
  801703:	89 d0                	mov    %edx,%eax
  801705:	31 d2                	xor    %edx,%edx
  801707:	8b 74 24 20          	mov    0x20(%esp),%esi
  80170b:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80170f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801713:	83 c4 2c             	add    $0x2c,%esp
  801716:	c3                   	ret    
  801717:	90                   	nop
  801718:	39 f8                	cmp    %edi,%eax
  80171a:	77 64                	ja     801780 <__umoddi3+0xc0>
  80171c:	0f bd e8             	bsr    %eax,%ebp
  80171f:	83 f5 1f             	xor    $0x1f,%ebp
  801722:	75 74                	jne    801798 <__umoddi3+0xd8>
  801724:	8b 7c 24 14          	mov    0x14(%esp),%edi
  801728:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  80172c:	0f 87 0e 01 00 00    	ja     801840 <__umoddi3+0x180>
  801732:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  801736:	29 f1                	sub    %esi,%ecx
  801738:	19 c7                	sbb    %eax,%edi
  80173a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  80173e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  801742:	8b 44 24 14          	mov    0x14(%esp),%eax
  801746:	8b 54 24 18          	mov    0x18(%esp),%edx
  80174a:	8b 74 24 20          	mov    0x20(%esp),%esi
  80174e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801752:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801756:	83 c4 2c             	add    $0x2c,%esp
  801759:	c3                   	ret    
  80175a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801760:	85 f6                	test   %esi,%esi
  801762:	89 f5                	mov    %esi,%ebp
  801764:	75 0b                	jne    801771 <__umoddi3+0xb1>
  801766:	b8 01 00 00 00       	mov    $0x1,%eax
  80176b:	31 d2                	xor    %edx,%edx
  80176d:	f7 f6                	div    %esi
  80176f:	89 c5                	mov    %eax,%ebp
  801771:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801775:	31 d2                	xor    %edx,%edx
  801777:	f7 f5                	div    %ebp
  801779:	89 c8                	mov    %ecx,%eax
  80177b:	f7 f5                	div    %ebp
  80177d:	eb 84                	jmp    801703 <__umoddi3+0x43>
  80177f:	90                   	nop
  801780:	89 c8                	mov    %ecx,%eax
  801782:	89 fa                	mov    %edi,%edx
  801784:	8b 74 24 20          	mov    0x20(%esp),%esi
  801788:	8b 7c 24 24          	mov    0x24(%esp),%edi
  80178c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  801790:	83 c4 2c             	add    $0x2c,%esp
  801793:	c3                   	ret    
  801794:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801798:	8b 44 24 10          	mov    0x10(%esp),%eax
  80179c:	be 20 00 00 00       	mov    $0x20,%esi
  8017a1:	89 e9                	mov    %ebp,%ecx
  8017a3:	29 ee                	sub    %ebp,%esi
  8017a5:	d3 e2                	shl    %cl,%edx
  8017a7:	89 f1                	mov    %esi,%ecx
  8017a9:	d3 e8                	shr    %cl,%eax
  8017ab:	89 e9                	mov    %ebp,%ecx
  8017ad:	09 d0                	or     %edx,%eax
  8017af:	89 fa                	mov    %edi,%edx
  8017b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8017b5:	8b 44 24 10          	mov    0x10(%esp),%eax
  8017b9:	d3 e0                	shl    %cl,%eax
  8017bb:	89 f1                	mov    %esi,%ecx
  8017bd:	89 44 24 10          	mov    %eax,0x10(%esp)
  8017c1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  8017c5:	d3 ea                	shr    %cl,%edx
  8017c7:	89 e9                	mov    %ebp,%ecx
  8017c9:	d3 e7                	shl    %cl,%edi
  8017cb:	89 f1                	mov    %esi,%ecx
  8017cd:	d3 e8                	shr    %cl,%eax
  8017cf:	89 e9                	mov    %ebp,%ecx
  8017d1:	09 f8                	or     %edi,%eax
  8017d3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  8017d7:	f7 74 24 0c          	divl   0xc(%esp)
  8017db:	d3 e7                	shl    %cl,%edi
  8017dd:	89 7c 24 18          	mov    %edi,0x18(%esp)
  8017e1:	89 d7                	mov    %edx,%edi
  8017e3:	f7 64 24 10          	mull   0x10(%esp)
  8017e7:	39 d7                	cmp    %edx,%edi
  8017e9:	89 c1                	mov    %eax,%ecx
  8017eb:	89 54 24 14          	mov    %edx,0x14(%esp)
  8017ef:	72 3b                	jb     80182c <__umoddi3+0x16c>
  8017f1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  8017f5:	72 31                	jb     801828 <__umoddi3+0x168>
  8017f7:	8b 44 24 18          	mov    0x18(%esp),%eax
  8017fb:	29 c8                	sub    %ecx,%eax
  8017fd:	19 d7                	sbb    %edx,%edi
  8017ff:	89 e9                	mov    %ebp,%ecx
  801801:	89 fa                	mov    %edi,%edx
  801803:	d3 e8                	shr    %cl,%eax
  801805:	89 f1                	mov    %esi,%ecx
  801807:	d3 e2                	shl    %cl,%edx
  801809:	89 e9                	mov    %ebp,%ecx
  80180b:	09 d0                	or     %edx,%eax
  80180d:	89 fa                	mov    %edi,%edx
  80180f:	d3 ea                	shr    %cl,%edx
  801811:	8b 74 24 20          	mov    0x20(%esp),%esi
  801815:	8b 7c 24 24          	mov    0x24(%esp),%edi
  801819:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  80181d:	83 c4 2c             	add    $0x2c,%esp
  801820:	c3                   	ret    
  801821:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801828:	39 d7                	cmp    %edx,%edi
  80182a:	75 cb                	jne    8017f7 <__umoddi3+0x137>
  80182c:	8b 54 24 14          	mov    0x14(%esp),%edx
  801830:	89 c1                	mov    %eax,%ecx
  801832:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  801836:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  80183a:	eb bb                	jmp    8017f7 <__umoddi3+0x137>
  80183c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801840:	3b 44 24 18          	cmp    0x18(%esp),%eax
  801844:	0f 82 e8 fe ff ff    	jb     801732 <__umoddi3+0x72>
  80184a:	e9 f3 fe ff ff       	jmp    801742 <__umoddi3+0x82>

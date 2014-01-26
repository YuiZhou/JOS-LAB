
output：     文件格式 elf64-x86-64


Disassembly of section .init:

00000000004003c8 <_init>:
  4003c8:	48 83 ec 08          	sub    $0x8,%rsp
  4003cc:	e8 6b 00 00 00       	callq  40043c <call_gmon_start>
  4003d1:	48 83 c4 08          	add    $0x8,%rsp
  4003d5:	c3                   	retq   

Disassembly of section .plt:

00000000004003e0 <printf@plt-0x10>:
  4003e0:	ff 35 22 0c 20 00    	pushq  0x200c22(%rip)        # 601008 <_GLOBAL_OFFSET_TABLE_+0x8>
  4003e6:	ff 25 24 0c 20 00    	jmpq   *0x200c24(%rip)        # 601010 <_GLOBAL_OFFSET_TABLE_+0x10>
  4003ec:	0f 1f 40 00          	nopl   0x0(%rax)

00000000004003f0 <printf@plt>:
  4003f0:	ff 25 22 0c 20 00    	jmpq   *0x200c22(%rip)        # 601018 <_GLOBAL_OFFSET_TABLE_+0x18>
  4003f6:	68 00 00 00 00       	pushq  $0x0
  4003fb:	e9 e0 ff ff ff       	jmpq   4003e0 <_init+0x18>

0000000000400400 <__libc_start_main@plt>:
  400400:	ff 25 1a 0c 20 00    	jmpq   *0x200c1a(%rip)        # 601020 <_GLOBAL_OFFSET_TABLE_+0x20>
  400406:	68 01 00 00 00       	pushq  $0x1
  40040b:	e9 d0 ff ff ff       	jmpq   4003e0 <_init+0x18>

Disassembly of section .text:

0000000000400410 <_start>:
  400410:	31 ed                	xor    %ebp,%ebp
  400412:	49 89 d1             	mov    %rdx,%r9
  400415:	5e                   	pop    %rsi
  400416:	48 89 e2             	mov    %rsp,%rdx
  400419:	48 83 e4 f0          	and    $0xfffffffffffffff0,%rsp
  40041d:	50                   	push   %rax
  40041e:	54                   	push   %rsp
  40041f:	49 c7 c0 e0 05 40 00 	mov    $0x4005e0,%r8
  400426:	48 c7 c1 50 05 40 00 	mov    $0x400550,%rcx
  40042d:	48 c7 c7 1c 05 40 00 	mov    $0x40051c,%rdi
  400434:	e8 c7 ff ff ff       	callq  400400 <__libc_start_main@plt>
  400439:	f4                   	hlt    
  40043a:	66 90                	xchg   %ax,%ax

000000000040043c <call_gmon_start>:
  40043c:	48 83 ec 08          	sub    $0x8,%rsp
  400440:	48 8b 05 b1 0b 20 00 	mov    0x200bb1(%rip),%rax        # 600ff8 <_DYNAMIC+0x1d0>
  400447:	48 85 c0             	test   %rax,%rax
  40044a:	74 02                	je     40044e <call_gmon_start+0x12>
  40044c:	ff d0                	callq  *%rax
  40044e:	48 83 c4 08          	add    $0x8,%rsp
  400452:	c3                   	retq   
  400453:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  40045a:	00 00 00 
  40045d:	0f 1f 00             	nopl   (%rax)

0000000000400460 <deregister_tm_clones>:
  400460:	b8 3f 10 60 00       	mov    $0x60103f,%eax
  400465:	55                   	push   %rbp
  400466:	48 2d 38 10 60 00    	sub    $0x601038,%rax
  40046c:	48 83 f8 0e          	cmp    $0xe,%rax
  400470:	48 89 e5             	mov    %rsp,%rbp
  400473:	77 02                	ja     400477 <deregister_tm_clones+0x17>
  400475:	5d                   	pop    %rbp
  400476:	c3                   	retq   
  400477:	b8 00 00 00 00       	mov    $0x0,%eax
  40047c:	48 85 c0             	test   %rax,%rax
  40047f:	74 f4                	je     400475 <deregister_tm_clones+0x15>
  400481:	5d                   	pop    %rbp
  400482:	bf 38 10 60 00       	mov    $0x601038,%edi
  400487:	ff e0                	jmpq   *%rax
  400489:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000400490 <register_tm_clones>:
  400490:	b8 38 10 60 00       	mov    $0x601038,%eax
  400495:	55                   	push   %rbp
  400496:	48 2d 38 10 60 00    	sub    $0x601038,%rax
  40049c:	48 c1 f8 03          	sar    $0x3,%rax
  4004a0:	48 89 e5             	mov    %rsp,%rbp
  4004a3:	48 89 c2             	mov    %rax,%rdx
  4004a6:	48 c1 ea 3f          	shr    $0x3f,%rdx
  4004aa:	48 01 d0             	add    %rdx,%rax
  4004ad:	48 89 c6             	mov    %rax,%rsi
  4004b0:	48 d1 fe             	sar    %rsi
  4004b3:	75 02                	jne    4004b7 <register_tm_clones+0x27>
  4004b5:	5d                   	pop    %rbp
  4004b6:	c3                   	retq   
  4004b7:	ba 00 00 00 00       	mov    $0x0,%edx
  4004bc:	48 85 d2             	test   %rdx,%rdx
  4004bf:	74 f4                	je     4004b5 <register_tm_clones+0x25>
  4004c1:	5d                   	pop    %rbp
  4004c2:	bf 38 10 60 00       	mov    $0x601038,%edi
  4004c7:	ff e2                	jmpq   *%rdx
  4004c9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000004004d0 <__do_global_dtors_aux>:
  4004d0:	80 3d 61 0b 20 00 00 	cmpb   $0x0,0x200b61(%rip)        # 601038 <__TMC_END__>
  4004d7:	75 11                	jne    4004ea <__do_global_dtors_aux+0x1a>
  4004d9:	55                   	push   %rbp
  4004da:	48 89 e5             	mov    %rsp,%rbp
  4004dd:	e8 7e ff ff ff       	callq  400460 <deregister_tm_clones>
  4004e2:	5d                   	pop    %rbp
  4004e3:	c6 05 4e 0b 20 00 01 	movb   $0x1,0x200b4e(%rip)        # 601038 <__TMC_END__>
  4004ea:	f3 c3                	repz retq 
  4004ec:	0f 1f 40 00          	nopl   0x0(%rax)

00000000004004f0 <frame_dummy>:
  4004f0:	48 83 3d 28 09 20 00 	cmpq   $0x0,0x200928(%rip)        # 600e20 <__JCR_END__>
  4004f7:	00 
  4004f8:	74 1b                	je     400515 <frame_dummy+0x25>
  4004fa:	b8 00 00 00 00       	mov    $0x0,%eax
  4004ff:	48 85 c0             	test   %rax,%rax
  400502:	74 11                	je     400515 <frame_dummy+0x25>
  400504:	55                   	push   %rbp
  400505:	bf 20 0e 60 00       	mov    $0x600e20,%edi
  40050a:	48 89 e5             	mov    %rsp,%rbp
  40050d:	ff d0                	callq  *%rax
  40050f:	5d                   	pop    %rbp
  400510:	e9 7b ff ff ff       	jmpq   400490 <register_tm_clones>
  400515:	e9 76 ff ff ff       	jmpq   400490 <register_tm_clones>
  40051a:	66 90                	xchg   %ax,%ax

000000000040051c <main>:
  40051c:	55                   	push   %rbp
  40051d:	48 89 e5             	mov    %rsp,%rbp
  400520:	48 83 ec 10          	sub    $0x10,%rsp
  400524:	c7 45 fc 72 6c 64 00 	movl   $0x646c72,-0x4(%rbp)
  40052b:	48 8d 45 fc          	lea    -0x4(%rbp),%rax
  40052f:	48 89 c2             	mov    %rax,%rdx
  400532:	be 10 e1 00 00       	mov    $0xe110,%esi
  400537:	bf f4 05 40 00       	mov    $0x4005f4,%edi
  40053c:	b8 00 00 00 00       	mov    $0x0,%eax
  400541:	e8 aa fe ff ff       	callq  4003f0 <printf@plt>
  400546:	c9                   	leaveq 
  400547:	c3                   	retq   
  400548:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
  40054f:	00 

0000000000400550 <__libc_csu_init>:
  400550:	48 89 6c 24 d8       	mov    %rbp,-0x28(%rsp)
  400555:	4c 89 64 24 e0       	mov    %r12,-0x20(%rsp)
  40055a:	48 8d 2d b7 08 20 00 	lea    0x2008b7(%rip),%rbp        # 600e18 <__init_array_end>
  400561:	4c 8d 25 a8 08 20 00 	lea    0x2008a8(%rip),%r12        # 600e10 <__frame_dummy_init_array_entry>
  400568:	4c 89 6c 24 e8       	mov    %r13,-0x18(%rsp)
  40056d:	4c 89 74 24 f0       	mov    %r14,-0x10(%rsp)
  400572:	4c 89 7c 24 f8       	mov    %r15,-0x8(%rsp)
  400577:	48 89 5c 24 d0       	mov    %rbx,-0x30(%rsp)
  40057c:	48 83 ec 38          	sub    $0x38,%rsp
  400580:	4c 29 e5             	sub    %r12,%rbp
  400583:	41 89 fd             	mov    %edi,%r13d
  400586:	49 89 f6             	mov    %rsi,%r14
  400589:	48 c1 fd 03          	sar    $0x3,%rbp
  40058d:	49 89 d7             	mov    %rdx,%r15
  400590:	e8 33 fe ff ff       	callq  4003c8 <_init>
  400595:	48 85 ed             	test   %rbp,%rbp
  400598:	74 1c                	je     4005b6 <__libc_csu_init+0x66>
  40059a:	31 db                	xor    %ebx,%ebx
  40059c:	0f 1f 40 00          	nopl   0x0(%rax)
  4005a0:	4c 89 fa             	mov    %r15,%rdx
  4005a3:	4c 89 f6             	mov    %r14,%rsi
  4005a6:	44 89 ef             	mov    %r13d,%edi
  4005a9:	41 ff 14 dc          	callq  *(%r12,%rbx,8)
  4005ad:	48 83 c3 01          	add    $0x1,%rbx
  4005b1:	48 39 eb             	cmp    %rbp,%rbx
  4005b4:	75 ea                	jne    4005a0 <__libc_csu_init+0x50>
  4005b6:	48 8b 5c 24 08       	mov    0x8(%rsp),%rbx
  4005bb:	48 8b 6c 24 10       	mov    0x10(%rsp),%rbp
  4005c0:	4c 8b 64 24 18       	mov    0x18(%rsp),%r12
  4005c5:	4c 8b 6c 24 20       	mov    0x20(%rsp),%r13
  4005ca:	4c 8b 74 24 28       	mov    0x28(%rsp),%r14
  4005cf:	4c 8b 7c 24 30       	mov    0x30(%rsp),%r15
  4005d4:	48 83 c4 38          	add    $0x38,%rsp
  4005d8:	c3                   	retq   
  4005d9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000004005e0 <__libc_csu_fini>:
  4005e0:	f3 c3                	repz retq 
  4005e2:	66 90                	xchg   %ax,%ax

Disassembly of section .fini:

00000000004005e4 <_fini>:
  4005e4:	48 83 ec 08          	sub    $0x8,%rsp
  4005e8:	48 83 c4 08          	add    $0x8,%rsp
  4005ec:	c3                   	retq   

output：     文件格式 elf32-i386


Disassembly of section .init:

080482b4 <_init>:
 80482b4:	53                   	push   %ebx
 80482b5:	83 ec 08             	sub    $0x8,%esp
 80482b8:	e8 00 00 00 00       	call   80482bd <_init+0x9>
 80482bd:	5b                   	pop    %ebx
 80482be:	81 c3 43 1d 00 00    	add    $0x1d43,%ebx
 80482c4:	8b 83 fc ff ff ff    	mov    -0x4(%ebx),%eax
 80482ca:	85 c0                	test   %eax,%eax
 80482cc:	74 05                	je     80482d3 <_init+0x1f>
 80482ce:	e8 2d 00 00 00       	call   8048300 <__gmon_start__@plt>
 80482d3:	83 c4 08             	add    $0x8,%esp
 80482d6:	5b                   	pop    %ebx
 80482d7:	c3                   	ret    

Disassembly of section .plt:

080482e0 <printf@plt-0x10>:
 80482e0:	ff 35 04 a0 04 08    	pushl  0x804a004
 80482e6:	ff 25 08 a0 04 08    	jmp    *0x804a008
 80482ec:	00 00                	add    %al,(%eax)
	...

080482f0 <printf@plt>:
 80482f0:	ff 25 0c a0 04 08    	jmp    *0x804a00c
 80482f6:	68 00 00 00 00       	push   $0x0
 80482fb:	e9 e0 ff ff ff       	jmp    80482e0 <_init+0x2c>

08048300 <__gmon_start__@plt>:
 8048300:	ff 25 10 a0 04 08    	jmp    *0x804a010
 8048306:	68 08 00 00 00       	push   $0x8
 804830b:	e9 d0 ff ff ff       	jmp    80482e0 <_init+0x2c>

08048310 <__libc_start_main@plt>:
 8048310:	ff 25 14 a0 04 08    	jmp    *0x804a014
 8048316:	68 10 00 00 00       	push   $0x10
 804831b:	e9 c0 ff ff ff       	jmp    80482e0 <_init+0x2c>

Disassembly of section .text:

08048320 <_start>:
 8048320:	31 ed                	xor    %ebp,%ebp
 8048322:	5e                   	pop    %esi
 8048323:	89 e1                	mov    %esp,%ecx
 8048325:	83 e4 f0             	and    $0xfffffff0,%esp
 8048328:	50                   	push   %eax
 8048329:	54                   	push   %esp
 804832a:	52                   	push   %edx
 804832b:	68 b0 84 04 08       	push   $0x80484b0
 8048330:	68 40 84 04 08       	push   $0x8048440
 8048335:	51                   	push   %ecx
 8048336:	56                   	push   %esi
 8048337:	68 0c 84 04 08       	push   $0x804840c
 804833c:	e8 cf ff ff ff       	call   8048310 <__libc_start_main@plt>
 8048341:	f4                   	hlt    
 8048342:	66 90                	xchg   %ax,%ax
 8048344:	66 90                	xchg   %ax,%ax
 8048346:	66 90                	xchg   %ax,%ax
 8048348:	66 90                	xchg   %ax,%ax
 804834a:	66 90                	xchg   %ax,%ax
 804834c:	66 90                	xchg   %ax,%ax
 804834e:	66 90                	xchg   %ax,%ax

08048350 <deregister_tm_clones>:
 8048350:	b8 23 a0 04 08       	mov    $0x804a023,%eax
 8048355:	2d 20 a0 04 08       	sub    $0x804a020,%eax
 804835a:	83 f8 06             	cmp    $0x6,%eax
 804835d:	77 02                	ja     8048361 <deregister_tm_clones+0x11>
 804835f:	f3 c3                	repz ret 
 8048361:	b8 00 00 00 00       	mov    $0x0,%eax
 8048366:	85 c0                	test   %eax,%eax
 8048368:	74 f5                	je     804835f <deregister_tm_clones+0xf>
 804836a:	55                   	push   %ebp
 804836b:	89 e5                	mov    %esp,%ebp
 804836d:	83 ec 18             	sub    $0x18,%esp
 8048370:	c7 04 24 20 a0 04 08 	movl   $0x804a020,(%esp)
 8048377:	ff d0                	call   *%eax
 8048379:	c9                   	leave  
 804837a:	c3                   	ret    
 804837b:	90                   	nop
 804837c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

08048380 <register_tm_clones>:
 8048380:	b8 20 a0 04 08       	mov    $0x804a020,%eax
 8048385:	2d 20 a0 04 08       	sub    $0x804a020,%eax
 804838a:	c1 f8 02             	sar    $0x2,%eax
 804838d:	89 c2                	mov    %eax,%edx
 804838f:	c1 ea 1f             	shr    $0x1f,%edx
 8048392:	01 d0                	add    %edx,%eax
 8048394:	d1 f8                	sar    %eax
 8048396:	75 02                	jne    804839a <register_tm_clones+0x1a>
 8048398:	f3 c3                	repz ret 
 804839a:	ba 00 00 00 00       	mov    $0x0,%edx
 804839f:	85 d2                	test   %edx,%edx
 80483a1:	74 f5                	je     8048398 <register_tm_clones+0x18>
 80483a3:	55                   	push   %ebp
 80483a4:	89 e5                	mov    %esp,%ebp
 80483a6:	83 ec 18             	sub    $0x18,%esp
 80483a9:	89 44 24 04          	mov    %eax,0x4(%esp)
 80483ad:	c7 04 24 20 a0 04 08 	movl   $0x804a020,(%esp)
 80483b4:	ff d2                	call   *%edx
 80483b6:	c9                   	leave  
 80483b7:	c3                   	ret    
 80483b8:	90                   	nop
 80483b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

080483c0 <__do_global_dtors_aux>:
 80483c0:	80 3d 20 a0 04 08 00 	cmpb   $0x0,0x804a020
 80483c7:	75 13                	jne    80483dc <__do_global_dtors_aux+0x1c>
 80483c9:	55                   	push   %ebp
 80483ca:	89 e5                	mov    %esp,%ebp
 80483cc:	83 ec 08             	sub    $0x8,%esp
 80483cf:	e8 7c ff ff ff       	call   8048350 <deregister_tm_clones>
 80483d4:	c6 05 20 a0 04 08 01 	movb   $0x1,0x804a020
 80483db:	c9                   	leave  
 80483dc:	f3 c3                	repz ret 
 80483de:	66 90                	xchg   %ax,%ax

080483e0 <frame_dummy>:
 80483e0:	a1 10 9f 04 08       	mov    0x8049f10,%eax
 80483e5:	85 c0                	test   %eax,%eax
 80483e7:	74 1e                	je     8048407 <frame_dummy+0x27>
 80483e9:	b8 00 00 00 00       	mov    $0x0,%eax
 80483ee:	85 c0                	test   %eax,%eax
 80483f0:	74 15                	je     8048407 <frame_dummy+0x27>
 80483f2:	55                   	push   %ebp
 80483f3:	89 e5                	mov    %esp,%ebp
 80483f5:	83 ec 18             	sub    $0x18,%esp
 80483f8:	c7 04 24 10 9f 04 08 	movl   $0x8049f10,(%esp)
 80483ff:	ff d0                	call   *%eax
 8048401:	c9                   	leave  
 8048402:	e9 79 ff ff ff       	jmp    8048380 <register_tm_clones>
 8048407:	e9 74 ff ff ff       	jmp    8048380 <register_tm_clones>

0804840c <main>:
 804840c:	55                   	push   %ebp
 804840d:	89 e5                	mov    %esp,%ebp
 804840f:	83 e4 f0             	and    $0xfffffff0,%esp
 8048412:	83 ec 20             	sub    $0x20,%esp
 8048415:	c7 44 24 1c 72 6c 64 	movl   $0x646c72,0x1c(%esp)
 804841c:	00 
 804841d:	8d 44 24 1c          	lea    0x1c(%esp),%eax
 8048421:	89 44 24 08          	mov    %eax,0x8(%esp)
 8048425:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
 804842c:	00 
 804842d:	c7 04 24 d8 84 04 08 	movl   $0x80484d8,(%esp)
 8048434:	e8 b7 fe ff ff       	call   80482f0 <printf@plt>
 8048439:	c9                   	leave  
 804843a:	c3                   	ret    
 804843b:	66 90                	xchg   %ax,%ax
 804843d:	66 90                	xchg   %ax,%ax
 804843f:	90                   	nop

08048440 <__libc_csu_init>:
 8048440:	55                   	push   %ebp
 8048441:	57                   	push   %edi
 8048442:	56                   	push   %esi
 8048443:	53                   	push   %ebx
 8048444:	e8 69 00 00 00       	call   80484b2 <__i686.get_pc_thunk.bx>
 8048449:	81 c3 b7 1b 00 00    	add    $0x1bb7,%ebx
 804844f:	83 ec 1c             	sub    $0x1c,%esp
 8048452:	8b 6c 24 30          	mov    0x30(%esp),%ebp
 8048456:	8d bb 0c ff ff ff    	lea    -0xf4(%ebx),%edi
 804845c:	e8 53 fe ff ff       	call   80482b4 <_init>
 8048461:	8d 83 08 ff ff ff    	lea    -0xf8(%ebx),%eax
 8048467:	29 c7                	sub    %eax,%edi
 8048469:	c1 ff 02             	sar    $0x2,%edi
 804846c:	85 ff                	test   %edi,%edi
 804846e:	74 29                	je     8048499 <__libc_csu_init+0x59>
 8048470:	31 f6                	xor    %esi,%esi
 8048472:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 8048478:	8b 44 24 38          	mov    0x38(%esp),%eax
 804847c:	89 2c 24             	mov    %ebp,(%esp)
 804847f:	89 44 24 08          	mov    %eax,0x8(%esp)
 8048483:	8b 44 24 34          	mov    0x34(%esp),%eax
 8048487:	89 44 24 04          	mov    %eax,0x4(%esp)
 804848b:	ff 94 b3 08 ff ff ff 	call   *-0xf8(%ebx,%esi,4)
 8048492:	83 c6 01             	add    $0x1,%esi
 8048495:	39 fe                	cmp    %edi,%esi
 8048497:	75 df                	jne    8048478 <__libc_csu_init+0x38>
 8048499:	83 c4 1c             	add    $0x1c,%esp
 804849c:	5b                   	pop    %ebx
 804849d:	5e                   	pop    %esi
 804849e:	5f                   	pop    %edi
 804849f:	5d                   	pop    %ebp
 80484a0:	c3                   	ret    
 80484a1:	eb 0d                	jmp    80484b0 <__libc_csu_fini>
 80484a3:	90                   	nop
 80484a4:	90                   	nop
 80484a5:	90                   	nop
 80484a6:	90                   	nop
 80484a7:	90                   	nop
 80484a8:	90                   	nop
 80484a9:	90                   	nop
 80484aa:	90                   	nop
 80484ab:	90                   	nop
 80484ac:	90                   	nop
 80484ad:	90                   	nop
 80484ae:	90                   	nop
 80484af:	90                   	nop

080484b0 <__libc_csu_fini>:
 80484b0:	f3 c3                	repz ret 

080484b2 <__i686.get_pc_thunk.bx>:
 80484b2:	8b 1c 24             	mov    (%esp),%ebx
 80484b5:	c3                   	ret    
 80484b6:	66 90                	xchg   %ax,%ax

Disassembly of section .fini:

080484b8 <_fini>:
 80484b8:	53                   	push   %ebx
 80484b9:	83 ec 08             	sub    $0x8,%esp
 80484bc:	e8 00 00 00 00       	call   80484c1 <_fini+0x9>
 80484c1:	5b                   	pop    %ebx
 80484c2:	81 c3 3f 1b 00 00    	add    $0x1b3f,%ebx
 80484c8:	83 c4 08             	add    $0x8,%esp
 80484cb:	5b                   	pop    %ebx
 80484cc:	c3                   	ret    

/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

# .text
# 	.globl System_call;                                                    \
#   .type System_call, @function;                                          \

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
 /*
  * see the example and types of exceptions and interrupts
  * TRAPHANDLER_NOEC - No return
  * TRAPHANDLER - return
  *
  * http://pdos.csail.mit.edu/6.828/2011/readings/i386/s09_10.htm
  */
TRAPHANDLER_NOEC(Divide_error, T_DIVIDE);
TRAPHANDLER_NOEC(Debug, T_DEBUG);
TRAPHANDLER_NOEC(Non_Maskable_Interrupt, T_NMI);
TRAPHANDLER_NOEC(Breakpoint, T_BRKPT);
TRAPHANDLER_NOEC(Overflow, T_OFLOW);
TRAPHANDLER_NOEC(BOUND_Range_Exceeded, T_BOUND);
TRAPHANDLER_NOEC(Invalid_Opcode, T_ILLOP);
TRAPHANDLER_NOEC(Device_Not_Available, T_DEVICE);
TRAPHANDLER(Double_Fault, T_DBLFLT);
TRAPHANDLER(Invalid_TSS, T_TSS);
TRAPHANDLER(Segment_Not_Present, T_SEGNP);
TRAPHANDLER(Stack_Fault, T_STACK);
TRAPHANDLER(General_Protection, T_GPFLT);
TRAPHANDLER(Page_Fault, T_PGFLT);
TRAPHANDLER_NOEC(x87_FPU_Floating_Point_Error, T_FPERR);
TRAPHANDLER_NOEC(Alignment_Check, T_ALIGN);
TRAPHANDLER_NOEC(Machine_Check, T_MCHK);
TRAPHANDLER_NOEC(SIMD_Floating_Point_Exception, T_SIMDERR);

TRAPHANDLER_NOEC(System_call,T_SYSCALL);

TRAPHANDLER_NOEC(IRQ_timer,IRQ_OFFSET+IRQ_TIMER);
TRAPHANDLER_NOEC(IRQ_kbd,IRQ_OFFSET+IRQ_KBD);
TRAPHANDLER_NOEC(IRQ_serial,IRQ_OFFSET+IRQ_SERIAL);
TRAPHANDLER_NOEC(IRQ_spurious,IRQ_OFFSET+IRQ_SPURIOUS);
TRAPHANDLER_NOEC(IRQ_ide,IRQ_OFFSET+IRQ_IDE);
TRAPHANDLER_NOEC(IRQ_error,IRQ_OFFSET+IRQ_ERROR);

/*
 * Lab 3: Your code here for _alltraps
 */
 _alltraps:
 	pushw   $0x0
	pushw	%ds
	pushw	$0x0
	pushw	%es	
	pushal
	movl	$GD_KD, %eax /* GD_KD is kern data -- 0x10 */
	movw	%ax, %ds
	movw	%ax, %es
	pushl %esp
	call trap

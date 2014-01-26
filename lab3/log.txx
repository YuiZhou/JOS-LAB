# exceptions and interrupts
 interrupt - asynchronous external to the processor[ > 31]
 exception - caused by the code[0 - 31]

In JOS, all exceptions are handled in kernel mode - privilege level 0

# NESTED EXCEPTION
Only when entering the kernel from user mode, the X86 processor automatically switches stacks before pushing its old register stat onto the stack and invoking the appropriate exception handler through the IDT.
Else, just push, not switch.

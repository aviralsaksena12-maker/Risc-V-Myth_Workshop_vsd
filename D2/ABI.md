🏗️ RISC-V Architecture & ABI Essentials

This document outlines the fundamental relationship between the Application Binary Interface (ABI), the Instruction Set Architecture (ISA), and the physical hardware implementation (RTL).
1. The ABI: The Bridge Between Software and Hardware

The Application Binary Interface (ABI) is the set of rules that defines how application programs interact with the operating system and the processor's hardware.

    Layered Interaction:

        API (Application Programming Interface): High-level interaction between applications and standard libraries (e.g., stdio.h in C).

        ABI: Connects the OS to the machine language (ISA). It includes System Calls that allow software to request hardware resources.

        ISA (Instruction Set Architecture): The boundary between software and hardware (e.g., RISC-V, x86, ARM).

        RTL (Register-Transfer Level): The physical hardware realization of the ISA.

2. Memory Organization & Data Flow

In a 64-bit system (RV64), data management between the high-speed registers and the larger, slower memory is critical.
Byte-Addressable Memory

    Memory is organized into 1-byte (8-bit) chunks.

    A Double-Word (64-bit value) occupies 8 consecutive memory addresses.

    Little Endian System: RISC-V typically stores the Least Significant Byte (LSB) at the lowest memory address.

Load/Store Operations

Since registers can only hold a limited amount of data, instructions are used to move data between Memory and Registers:

    Load (e.g., ld): Pulls a 64-bit value from memory into a register.

        Syntax: ld X0, 16(X23) — Adds an offset of 16 to the base address in X23 and loads the result into X0.

    Store (e.g., sd): Saves the contents of a register back into memory.

3. RISC-V Register Set & ABI Naming

The RISC-V architecture defines 32 general-purpose registers (x0 to x31). While the hardware sees them as numbers, the ABI assigns them specific names and roles to ensure software compatibility.
Standard Register Mapping (ABI)
Register	ABI Name	Description
x0	zero	Hardwired to 0; ignores all writes.
x1	ra	Return Address for function calls.
x2	sp	Stack Pointer.
x3	gp	Global Pointer.
x4	tp	Thread Pointer.
x5-x7	t0-t2	Temporary registers.
x8-x9	s0-s1	Saved registers / Frame pointer.
x10-x17	a0-a7	Function arguments and return values.
x18-x27	s2-s11	Saved registers.
x28-x31	t3-t6	More temporary registers.
4. Instruction Types (RV64I)

RISC-V instructions are 32 bits wide and categorized by their format:

    R-Type (Register): Operates on three registers (e.g., add x1, x2, x3).

    I-Type (Immediate): Operates on registers and a constant value (e.g., addi x1, x2, 10 or ld).

    S-Type (Store): Specifically formatted for memory store operations (e.g., sd).

    B-Type (Branch): Used for conditional jumps (e.g., beq, blt).


## RISC-V MYTH Workshop - VSD

This repository contains the work and labs completed during the Microprocessor for You in Thirty Hours (MYTH) workshop organized by VSD (VLSI System Design) and NASSCOM. The workshop focuses on the journey from a high-level C program to the final RTL implementation of a RISC-V core.
Table of Contents

    Introduction

    Day 1: Introduction to RISC-V ISA and GNU Toolchain

    Day 2: ABI and System Calls

    Day 3: Digital Logic with TL-Verilog and Makerchip

    Day 4: RISC-V Microarchitecture Design

    Day 5: Pipelining and Final Core Implementation

    How to Use

## Introduction

The project involves designing a 5-stage RISC-V processor core that supports the RV32I Base Integer Instruction Set. The design is implemented using TL-Verilog (Transaction-Level Verilog) within the Makerchip IDE.
Day 1: Introduction to RISC-V ISA and GNU Toolchain

    Exploration of the RISC-V Instruction Set Architecture (ISA).

    Compiling C programs for RISC-V using the riscv64-unknown-elf-gcc compiler.

    Simulating and analyzing object files using spike and pk.

    Lab: Calculated the sum of numbers from 1 to N using RISC-V assembly.

## Day 2: ABI and System Calls

    Understanding the Application Binary Interface (ABI) and register nomenclature (a0-a7, s0-s11, etc.).

    Writing assembly code to interface with C programs.

    Analyzing the performance of different optimization flags (-Ofast, -O1).

## Day 3: Digital Logic with TL-Verilog and Makerchip

    Introduction to TL-Verilog and the Makerchip platform.

    Implementation of basic digital gates, muxes, and a 32-bit Combinational ALU.

        Key Concept: Understanding Pipelined Logic and Validity.

## Day 4: RISC-V Microarchitecture Design

    Defining the Program Counter (PC) and Fetch logic.

    Instruction Decoding for various formats (R-type, I-type, S-type, B-type, U-type, J-type).

    Register File Read/Write operations.

## Day 5: Pipelining and Final Core Implementation

    Implementing a 5-stage pipeline: Fetch, Decode, Execute, Memory, Writeback.

    Handling Hazards: Data hazards and Branch hazards using stalls and bypassing.

    Integration of Load/Store instructions and Control Flow.

    Final Result: A functional RISC-V core capable of executing assembly programs.

## How to Use

    Open the code in the Lab D3 D4 D5 folder.

    Copy the .tlv code.

    Paste it into the Makerchip IDE.

    Examine the waveform and diagrams to verify the processor's state.

## FinalRiscV(RV32I)
 ## Diagram
<img width="383" height="706" alt="Screenshot 2026-04-03 213222" src="https://github.com/user-attachments/assets/5b9a720e-bb8d-4a6a-936d-9920c94480db" />


 ## Waveform
 
<img width="959" height="750" alt="Screenshot 2026-04-03 213153" src="https://github.com/user-attachments/assets/99c60716-b003-4c2c-963c-da6bee431edc" />


 ## Visualization
<img width="864" height="522" alt="Screenshot 2026-04-03 213136" src="https://github.com/user-attachments/assets/ba1c00b0-0b54-408d-b79f-be713ff2deb5" />


## log
<img width="948" height="361" alt="image" src="https://github.com/user-attachments/assets/73d7487e-d85f-4389-91ac-0c59ee61ff6f" />


## Acknowledgments

    Kunal Ghosh, Co-founder, VSD Corp. Pvt. Ltd.

    Steve Hoover, Founder, Redwood EDA.

    NASSCOM and the VSD team for the mentorship.

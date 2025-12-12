# RISC-V CPU Project

This project is a reference Minispec/Bluespec implementation of a 32-bit RV32I processor capable of running bare-metal programs and workloads such as MNIST inference. The repository contains the modular hardware blocks (fetch, decode, execute, caches, and memory), a thin runtime/OS shim, and the toolchains and tests used to validate the design.

---

## Repository Layout

- **Minispec hardware (`*.ms`)**
  - `Processor.ms` (top level), `Fetch.ms`, `Decode.ms`, `Execute.ms`, `ALU.ms`, `RegisterFile.ms`, and cache/memory models.
  - Testbenches: `DecodeTB.ms`, `ExecuteTB.ms`, `FetchTB.ms`, `DirectMappedCacheTB.ms`, `TwoWayCacheTB.ms`, etc.
- **Bluespec glue (`*.bsv`)**
  - SRAM wrappers (`SRAMArray.bsv`), randomizers, and helper IP.
- **Software (`sw/`)**
  - Cross-compiled micro/macro/pipeline tests, MNIST workload, and the `elf2hex` utility.
- **Automation**
  - Top-level `Makefile` for hardware builds/tests and `sw/Makefile` for firmware image generation.
  - Python harnesses (`test.py`, `grade.py`) for regression and grading.

---

## CPU Technical Specification

### ISA & Data Types

- Implements the RV32I base integer ISA with OP, OPIMM, LOAD/STORE, BRANCH, JAL, JALR, LUI, and AUIPC instruction classes (`ProcTypes.ms`).
- Uses 32 general-purpose registers (`RegisterFile.ms`) backed by a vector of 32 `Word` registers with x0 hard-wired to zero.
- The decode stage produces a `DecodedInst` bundle (iType, ALU op, branch function, memory function, destination/source registers, immediate) used throughout the pipeline.

### Pipeline Overview

| Stage | Responsibilities |
| --- | --- |
| **Fetch** | Drives the instruction memory/cache via a `FetchInput` handshake supporting Stall/Dequeue/Redirect actions. Ensures sequential PC increments, branch redirects, and annul handling (validated by `FetchTB.ms`). |
| **Decode** | Parses 32-bit instructions into structured control signals, performs immediate extraction, and guards against unsupported funct3/funct7 combinations (see `DecodeTB.ms`). |
| **Execute** | Applies ALU operations, evaluates branches, computes memory addresses, and prepares the `ExecInst` bundle containing next-PC, memory request info, and write-back data (see `ExecuteTB.ms`). |
| **Memory** | Issues `MemReq` transactions through the cache interface, handles load alignment/sign extension, and tracks outstanding memory operations. |
| **Writeback** | Commits register updates via `RegWriteArgs` unless the destination is x0. |

### Pipeline Microarchitecture

- **Five-stage overlap**: Fetch, Decode, Execute, Memory, and Writeback run concurrently with per-stage registers encapsulated in Minispec modules (e.g., `FetchTB.ms`, `DecodeTB.ms`, `ExecuteTB.ms`). Each stage exposes a decoupled `Maybe` interface so downstream stalls only propagate when necessary, keeping earlier stages busy.
- **Hazard management**: Decode tags source/destination registers and immediates in `DecodedInst`, allowing Execute to resolve dependencies without re-decoding and enabling bypass paths (implemented within `Execute.ms`/`Processor.ms`). Register writes are suppressed for x0 in `RegisterFile.ms` to avoid structural hazards on the zero register.
- **Control flow**: The Fetch interface supports Stall/Dequeue/Redirect actions, enabling fast branch resolution—Execute computes the target PC, and Fetch can annul in-flight requests the very next cycle. `FetchTB.ms` stresses long, stall-heavy, and redirect-heavy scenarios to verify responsiveness.
- **Memory overlap**: The Memory stage tracks outstanding cache transactions through `MemReq`/`MemFunc` metadata so stores can proceed while loads wait on cache fills. When paired with `MainMemory` or `CacheWrapper`, the processor can continue issuing independent instructions while memory latency is hidden behind other pipeline work.
- **Caching for throughput**: Direct-mapped or two-way caches reduce average memory latency dramatically. The Beveren workload verifies that the cache responds within a few dozen cycles, so the pipeline rarely bubbles on instruction/data fetches, maintaining near one instruction per cycle on cache hits.

### Execution Units

- **ALU**: Supports ADD/SUB, logical (AND/OR/XOR), shifts (SLL/SRL/SRA and immediate variants), comparisons (SLT/SLTU), and auxiliary ops required by AUIPC/LUI.
- **Branch Unit**: Implements EQ/NE/LT/LTU/GE/GEU comparisons plus a “delayed branch” tag for speculative control (`ProcTypes.ms`).
- **Register File**: Dual read ports and one write port with simulation-friendly state dumping.

### Implemented Hardware Blocks

- **ALU (`ALU.ms:1-205`)** – Built from a custom 32-bit barrel shifter, signed/unsigned comparators, and both ripple-carry and prefix adders. The `alu()` function selects between arithmetic, logical, and shift paths while the helper functions (`barrelRShift`, `sft32`, `lt32`, `addSub`, `fastAdd`) provide the underlying datapath components.
- **Decoder (`Decode.ms:62-200`)** – Extracts source/destination registers and immediates for every RV32I format, sets the appropriate `IType`, and assigns ALU/branch/memory functions. Invalid opcode/funct combinations fall back to `Unsupported`, ensuring the pipeline never executes malformed instructions.
- **Execute (`Execute.ms:1-60`)** – Combines decoded control with register operands, feeds the Minispec ALU, evaluates branches via `aluBr`, produces write-back data, and computes memory addresses/next PC values for loads, stores, and jumps.

---

## Memory System & Caches

### Cache Geometry

`CacheTypes.ms` defines the shared cache interface:

- 64 sets, 16 words/line (512-bit lines) with derived tag/index/offset widths.
- Load/store op enumeration (`MemFunc`) plus helpers (isLoad/isStore).
- Cache line status encodings (NotValid, Clean, Dirty) and request status FSM (Ready, Lookup, Writeback, Fill).

### Implementations & Tests

- `DirectMappedCache.ms` and `TwoWayCache.ms` plug into the shared interface.
- The `Beveren` workload (`Beveren.ms`) stress-tests caches with random loads/stores, validates responses against a reference `WordMem`, and checks hit/miss counters plus performance bounds for 1-way and 2-way configurations.

### Main Memory & MMIO

- `WordMem` models 16 MB of byte-addressable DRAM backed by `mem.vmh` with alignment checks and byte-enable writes.
- `MainMemory` adds realistic latency (line fills + extra cycles) and streams cache line reads/writes.
- `SingleCycleMemory` offers an idealized backend for unit tests and implements simple MMIO:
  - `0x4000_0000`: write a byte to UART/console.
  - `0x4000_0004`: write a 32-bit integer to console.
  - `0x4000_1000`: program exit/status.
- `CacheWrapper` wraps any cache to interface with `MainMemory` while preserving the MMIO side effects.

---

## Bare-Metal Runtime & OS Interface

- Minimal CRT (`sw/mnist/src/crt0.S`) initializes registers, sets the stack pointer to 0x80000, and jumps to `main`.
- System “calls” are simple MMIO reads/writes:
  - `print_char` writes to `0x4000_0000`.
  - `print_int` utilities layer on top (`sw/mnist/src/utils.c`).
  - `exit` writes the return code to `0x4000_1000` and loops forever.
  - `load_arg` reads arguments from `0x4000_3000`.
- Programs are freestanding (`-nostdlib -nostartfiles`) and linked with `tools/bare-link.ld`.

---

## Software Stack & Workloads

- `sw/Makefile` cross-compiles assembly/C tests for RV32I, producing `.riscv` ELFs, `.dump` disassemblies, and `.vmh` memory images via `tools/elf2hex`.
- Test suites:
  - `microtests`: targeted ISA checks with golden register dumps.
  - `pipetests`: pipeline hazard scenarios.
  - `fullasmtests`: ISA compliance and branch prediction challenges.
  - `mnist`: C inference workload linked against `mnist_src` weights/activations.
- VMH files live under `sw/build/<suite>/` and are symlinked to `mem.vmh` when running the processor.

---

## Building, Running, and Testing

1. **Build the processor**
   ```bash
   make
   ```
2. **Unit-level tests**
   ```bash
   make test_decode
   make test_execute
   make test_fetch        # symlinks fetch_test.vmh
   make DirectMappedBeveren
   make TwoWayBeveren
   ```
3. **Software images**
   ```bash
   make -C sw
   ```
4. **Program tests**
   ```bash
   ./test.py microtests          # or pipetests/fullasmtests/mnist
   ./grade.py                    # runs fullasmtests + mnist runtime scoring
   ```
   The harness symlinks the requested VMH into `mem.vmh`, runs `./Processor`, and compares output against `sw/<suite>/*.expected`.
5. **Synthesis placeholder**
   ```bash
   make synth
   ```

---

## Performance & Clocking Guidelines

- **Target frequency**: When synthesized to modern FPGA fabrics (e.g., Xilinx Artix/UltraScale) or a modest ASIC flow, the five-stage Minispec pipeline typically closes timing around 80–120 MHz with the direct-mapped cache and 60–100 MHz with the two-way cache (extra LRU/state logic slightly reduces Fmax). Exact results depend on your ALU and bypass implementations.
- **Latency hiding**: With caches meeting the Beveren timing bounds (line fills in ≈32–48 cycles), the processor sustains close to 1 IPC on cache hits. Main-memory latency only dominates when workloads exceed the 16 KB instruction/data footprints or thrash the cache.
- **Runtime expectations**: The included grading script evaluates MNIST inference runtimes with thresholds ranging from 20 M cycles down to 250 k cycles. Hitting the faster bins requires both a high operating frequency and low CPI (i.e., minimal stalls and efficient caching).
- **Tuning levers**: Raising the cache size/associativity, optimizing branch resolution latency, and improving forwarding paths in `Execute.ms`/`Processor.ms` can all increase the maximum achievable clock frequency or reduce cycle count, so focus on those before re-synthesizing.

---

## License

This repository does not currently include a formal license. Please add one (e.g., MIT, BSD, Apache-2.0) before redistributing derivatives.

# mips-cpu-vhdl

A single-cycle 32-bit MIPS CPU implemented in VHDL, synthesized and deployed on a Xilinx Nexys A7 FPGA. This project demonstrates hands-on knowledge of computer architecture, RTL design, combinational control logic, and hardware simulation and verification. Built as part of Computer Architecture and Design course at Concordia University. The design covers the full datapath and a combinational control unit supporting 20 MIPS instructions across R, I, and J formats.

## Architecture Overview

The CPU is a single-cycle design: every instruction completes in one clock cycle. The datapath and control unit are integrated into a single top-level `cpu` entity.

```
        ┌──────────┐    instruction    ┌──────────┐
        │  I-Cache │ ───────────────►  │ Control  │
        │  (32x32  │                   │  Unit    │
        │   ROM)   │                   └──────────┘
        └──────────┘    control signals     │
             ▲               ┌─────────────┘
             │               ▼
        ┌────┴─────┐    ┌──────────┐    ┌──────────┐
        │    PC    │    │ Register │    │   ALU    │
        │ Register │    │  File    │◄──►│          │
        └────┬─────┘    │ (32x32)  │    └────┬─────┘
             │          └──────────┘         │
             │                               ▼
        ┌────┴──────────────────────┐  ┌──────────┐
        │      Next-Address Unit    │  │ D-Cache  │
        │  (PC+1, branch, jump, jr) │  │ (32x32   │
        └───────────────────────────┘  │   RAM)   │
                                       └──────────┘
```

## Supported Instructions

| Type | Instructions |
|------|-------------|
| R-type arithmetic | `add`, `sub`, `slt` |
| R-type logical | `and`, `or`, `xor`, `nor` |
| I-type arithmetic | `addi`, `slti`, `lui` |
| I-type logical | `andi`, `ori`, `xori` |
| Memory | `lw`, `sw` |
| Branch | `beq`, `bne`, `bltz` |
| Jump | `j`, `jr` |

## File Structure

```
├── Code/
│   ├── cpu.vhd           # Top-level entity: datapath + control unit
│   ├── alu.vhd           # 32-bit ALU (add/sub, logic, slt)
│   ├── regfile.vhd       # 32x32-bit register file (R0 hardwired to 0)
│   ├── i_cache.vhd       # Instruction cache (32-location ROM)
│   ├── d_cache.vhd       # Data cache (32-location synchronous RAM)
│   ├── sign_extend.vhd   # Configurable sign/zero extension (4 modes)
│   ├── next_address.vhd  # PC logic: PC+1, branch offset, jump, jr
│   ├── pc_reg.vhd        # 32-bit PC register with async reset
│   └── cpu.xdc           # Xilinx constraints (Nexys A7 pin mapping)
├── DO/
│   └── cpu_labtest.do    # ModelSim simulation script
├── Vivado_Log_Files/
│   ├── synth_runme.log   # Synthesis log
│   └── impl_runme.log    # Implementation log
└── Docs/
    └── labtest_sim.pdf   # ModelSim simulation waveforms
```

## Control Unit

The control unit is a purely combinational process that decodes the 6-bit opcode (and 6-bit func field for R-type instructions) to drive 10 control signals:

| Signal | Width | Function |
|--------|-------|----------|
| `reg_write` | 1-bit | Enable write to register file |
| `reg_dst` | 1-bit | Write destination: `rt` (I-type) or `rd` (R-type) |
| `reg_in_src` | 1-bit | Register write data: ALU result or memory |
| `alu_src` | 1-bit | ALU second operand: `rt` or sign-extended immediate |
| `add_sub` | 1-bit | ALU mode: addition or subtraction |
| `data_write` | 1-bit | Enable write to data cache (`sw`) |
| `logic_func` | 2-bit | ALU logical operation: AND / OR / XOR / NOR |
| `func` | 2-bit | Sign-extension mode (LUI / arithmetic / logical) |
| `branch_type` | 2-bit | Branch condition: none / BEQ / BNE / BLTZ |
| `pc_sel` | 2-bit | Next PC source: PC+1/branch / jump / jump-register |

## Simulation

The test program loaded into the I-cache exercises the major instruction classes:

```asm
addi r3, r0, 0        ; r3 = 0 (loop counter target)
addi r1, r0, 0        ; r1 = 0 (accumulator)
addi r2, r0, 5        ; r2 = 5 (loop counter)
loop:
  add  r1, r1, r2     ; r1 += r2  (accumulate sum 5+4+3+2+1 = 15)
  addi r2, r2, -1     ; r2--
  beq  r2, r3, done   ; if r2 == 0, exit loop
  j    loop           ; else repeat
done:
  sw   r1, 0(r0)      ; store result to memory
  lw   r4, 0(r0)      ; load it back
  andi r4, r4, 0x000A
  ori  r4, r4, 0x0001
  xori r4, r4, 0x000B
  xori r4, r4, 0x0000
```

The simulation verifies all major instruction classes: ALU operations with and without immediate operands, memory access (`lw`/`sw`), conditional branches (`beq`), and unconditional jumps (`j`). Waveforms are included in [`labtest_sim.pdf`](labtest_sim.pdf).

## Build and Run

### Simulation (ModelSim)

**1. Set up the environment:**
```bash
source /CMC/ENVIRONMENT/modelsim.env
```

**2. Create the work library and compile all VHDL files (in order from low-level to high-level):**
```bash
vlib work
vcom Code/alu.vhd
vcom Code/regfile.vhd
vcom Code/sign_extend.vhd
vcom Code/pc_reg.vhd
vcom Code/i_cache.vhd
vcom Code/d_cache.vhd
vcom Code/next_address.vhd
vcom Code/cpu.vhd
```

**3. Run the simulation using the provided DO file:**
```bash
vsim -do DO/cpu_labtest.do cpu &
```

This loads the design and runs the test program defined in the I-cache. Use the Wave window to see the full waveform.

To re-run after modifying the I-cache or VHDL, recompile the changed file(s) with `vcom` and restart with `vsim`.

---

### Synthesis & Implementation (Xilinx Vivado on Nexys A7)

**1. Set up the environment:**
```bash
source /CMC/scripts/xilinx.vivado.2025.1.csh
```

**2. Launch Vivado:**
```bash
vivado &
```

**3. In the Vivado GUI:**
- Select **Create Project** → RTL Project
- Add all `.vhd` files from `Code/` (target language: VHDL)
- Add `Code/cpu.xdc` as the constraints file
- Select part: **xc7a100tcsg324-1** (Artix-7, Nexys A7-100T)

**4. Run the flow:**
- **Run Synthesis** → **Run Implementation** → **Generate Bitstream**

**5. Program the board:**
- Connect the Nexys A7 via USB (jumpers: JP3 → USB, JP2 → USB, JP1 → USB/SD)
- In Vivado: **Open Hardware Manager** → **Open Target** → **Autoconnect** → **Program Device**

**Board I/O mapping (from `cpu.xdc`):**

| Signal | Board I/O |
|--------|-----------|
| `clk` | Slide switch |
| `reset` | Slide switch |
| `rs_out[3:0]` | LEDs |
| `rt_out[3:0]` | LEDs |
| `pc_out[3:0]` | LEDs |
| `overflow`, `zero` | LEDs |

Toggle the clock switch to step through instructions. Assert reset to restart execution from address 0.

---

## Tools & Target Hardware

- **HDL:** VHDL (IEEE std_logic_1164, std_logic_signed)
- **Simulation:** ModelSim
- **Synthesis & Implementation:** Xilinx Vivado
- **FPGA:** Xilinx Nexys A7 (Artix-7)

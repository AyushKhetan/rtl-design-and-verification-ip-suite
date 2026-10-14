# RTL Design & Verification IP Suite

A collection of reusable SystemVerilog IP blocks and verification exercises for digital-design and SoC-integration workflows. The suite covers FIFO architectures, arbitration, streaming interfaces, serial peripherals, and memory-mapped DMA control, with simulation-based verification and formal-property experiments.

## Highlights

- **Parameterized FIFOs:** synchronous FIFO and asynchronous FIFO with Gray-coded pointer synchronization for clock-domain crossing.
- **Arbitration and streaming control:** round-robin arbiter and ready/valid skid-buffer design work for flow control and interface corner cases.
- **Serial interfaces:** UART transmitter/receiver, serial loopback, and an SPI master.
- **Memory-mapped peripheral integration:** APB-controlled UART with programmable registers, status reporting, and serial-loopback verification.
- **DMA and SoC integration:** MMIO-based DMA controller, register interface, transfer engine, and bus support.
- **Verification:** self-checking SystemVerilog testbenches, SystemVerilog Assertions (SVA), and SymbiYosys/Yosys formal-verification setups for selected blocks.

## Repository structure

| Directory | Contents |
|---|---|
| `parameterized-sync-fifo/` | Parameterized synchronous FIFO, simulation testbench, and formal harness |
| `async-fifo/` | Asynchronous FIFO, CDC-oriented pointer logic, assertions, testbench, and formal configuration |
| `parameterized-rr-arbiter/` | Round-robin arbiter, self-checking testbench, and formal collateral |
| `uart/` | UART TX/RX RTL and standalone/loopback testbenches |
| `apb/` | APB register block and APB–UART integration top with testbenches |
| `spi/` | SPI master RTL and testbench |
| `dma/` | DMA engine, top-level integration, registers, specification, and testbenches |
| `bus/` | SoC bus support RTL |

The ready/valid skid-buffer design is part of the suite's stated scope, but its standalone source is not present in this exported snapshot. Add the RTL and corresponding tests to the repository when available.

## Verification approach

Verification is organized around focused, block-level tests and formal checks where applicable:

1. **Simulation:** exercise reset behavior, normal transactions, boundary conditions, and interface corner cases using self-checking testbenches.
2. **Assertions:** express protocol and control invariants with SVA where supported.
3. **Formal checks:** use the supplied SymbiYosys configurations to explore properties of selected FIFO and arbitration logic.
4. **Integration testing:** exercise APB register access and UART serial loopback through the integrated top.

Formal collateral is not a blanket claim that every IP block has been formally proven. In particular, re-run the arbiter formal job and review its result before relying on it as a passing proof. Likewise, re-run simulations from a clean checkout before publishing specific pass claims.

## Toolchain

- **Icarus Verilog** (`iverilog`, `vvp`) for simulation
- **GTKWave** for waveform inspection
- **Yosys / SymbiYosys** (`yosys`, `sby`) for synthesis-oriented and formal flows

Tool compatibility depends on the constructs in each testbench and formal harness. Run each block from its directory or adapt source paths to your local tool setup.

## Suggested starting points

- FIFO behavior: `parameterized-sync-fifo/rtl/fifo.sv`, `parameterized-sync-fifo/tb/tb_fifo.sv`
- Asynchronous FIFO / CDC: `async-fifo/rtl/async_fifo.sv`
- Arbitration: `parameterized-rr-arbiter/rtl/rr_arbiter.sv`
- UART and loopback: `uart/rtl/uart_tx.sv`, `uart/rtl/uart_rx.sv`, `uart/tb/uart_loopback_tb.sv`
- APB–UART integration: `apb/rtl/uart_apb_top.sv`, `apb/tb/tb_uart_apb_top.sv`
- SPI master: `spi/rtl/spi_master.sv`
- DMA: `dma/rtl/dma.sv`, `dma/docs/dma_spec.md`

## Scope and status

This repository documents RTL design and verification work across reusable IP blocks, CDC, serial interfaces, and SoC integration. The source snapshot contains the synchronous/asynchronous FIFO, arbiter, UART, APB–UART, SPI, and DMA source trees listed above. A few details may need to be completed or revalidated in a clean environment; do not interpret the presence of a formal configuration or an old result file as proof that the latest source passes every check.

# RTL Design & Verification IP Suite

A collection of reusable Verilog/SystemVerilog IP blocks developed around **RTL architecture, functional verification, CDC, formal properties, and SoC integration**. The suite brings together parameterized control and storage structures, serial peripherals, and a memory-mapped DMA path.

## IP portfolio

| IP block | Overview | Verification collateral |
|---|---|---|
| **Parameterized synchronous FIFO** | Configurable FIFO RTL with synchronous read/write control and full/empty handling | Self-checking testbench and formal harness |
| **Asynchronous FIFO** | Dual-clock FIFO using Gray-coded pointers and multi-flop synchronization for clock-domain crossing | Simulation testbench, SVA, and formal configurations |
| **Round-robin arbiter** | Parameterized arbitration with rotating priority and grant logic | Self-checking testbench and formal harness |
| **UART** | UART transmitter and receiver with serial loopback testing | Standalone TX/RX testbenches and loopback testbench |
| **APB-controlled UART** | Memory-mapped UART registers and APB-to-UART integration, including status and receive-data handling | Register-block and integrated top-level testbenches |
| **SPI master** | RTL implementation of a serial peripheral interface master | Testbench |
| **MMIO-based DMA controller** | DMA engine and register interface for memory-mapped control and SoC integration | DMA engine and top-level testbenches; see verification notes below |
| **SoC bus support** | Bus logic used by the integration-oriented RTL | RTL source |

The suite also includes work on a **ready/valid skid buffer**; its standalone RTL and testbench are not included in the current repository snapshot.

## Design and verification approach

The projects emphasize:

- **Reusable RTL:** modular interfaces and parameterization where appropriate.
- **Functional verification:** self-checking testbenches for normal operation, boundary conditions, reset behavior, and interface corner cases.
- **CDC-aware design:** Gray-coded FIFO pointers and synchronizer stages in the asynchronous FIFO.
- **Assertions and formal methods:** SVA and SymbiYosys/Yosys formal harnesses for selected designs.
- **Integration testing:** APB register accesses and UART serial loopback through the integrated peripheral top.
- **Implementation awareness:** synthesizable RTL and attention to hardware architecture rather than behavioral-only models.

Formal infrastructure is provided for selected blocks; its presence should not be interpreted as proof that every design has a passing formal result. In particular, the round-robin arbiter's saved formal artifacts include a failure that needs to be investigated. DMA verification collateral is also incomplete in the supplied snapshot, so the DMA tests and their dependencies should be reviewed before treating the environment as a complete regression.

## Repository structure

```text
.
├── parameterized-sync-fifo/   # Synchronous FIFO RTL, testbench, formal harness
├── async-fifo/                # Asynchronous FIFO, CDC logic, SVA, formal collateral
├── parameterized-rr-arbiter/  # Round-robin arbiter and verification collateral
├── uart/                      # UART TX/RX and loopback tests
├── apb/                       # APB register block and APB–UART integration
├── spi/                       # SPI master and testbench
├── dma/                       # DMA engine, registers, top level, specification, tests
└── bus/                       # SoC bus support RTL
```

Individual IP blocks are kept in separate directories so their RTL, tests, and formal setups can be developed independently.

## Tooling

The repository uses open-source RTL and verification tools where supported:

- **Icarus Verilog** (`iverilog`, `vvp`) — simulation
- **GTKWave** — waveform inspection
- **Yosys** — RTL analysis and synthesis
- **SymbiYosys** (`sby`) — formal verification orchestration

Tool requirements and invocation commands vary by block. Consult the testbench and `.sby` configuration in each project, and rerun checks from a clean checkout before relying on a result.

## Getting started

1. Choose an IP block and inspect its RTL and testbench.
2. Compile and run its testbench with the required source files and simulator.
3. For blocks with formal configurations, run the corresponding SymbiYosys job separately from simulation.
4. Review waveforms or counterexamples when a check fails.
5. Keep documented verification status aligned with reproducible results from the current source.

## Scope

This repository brings together reusable RTL IP spanning FIFOs, arbitration, serial interfaces, and memory-mapped SoC integration. The emphasis is on both the hardware architecture and the verification collateral used to exercise it.
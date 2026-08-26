# Parameterized RTL Design & Verification

A growing collection of **parameterized RTL designs** developed with an emphasis on clean hardware architecture, synthesizability, simulation-based verification, and formal verification.

The repository is intended as a practical RTL/design-verification portfolio as well as a working record of progressively more sophisticated digital design projects.

## Projects

| Project | Description | Verification |
|---|---|---|
| [`parameterized-rr-arbiter`](./parameterized-rr-arbiter) | Parameterized round-robin arbiter with circular priority and one-hot grant generation | Simulation + formal verification |
| [`parameterized-sync-fifo`](./parameterized-sync-fifo) | Parameterized synchronous FIFO | Simulation-based verification |
| [`async-fifo`](./async-fifo) | Parameterized asynchronous FIFO / clock-domain-crossing design | RTL development; verification flow under development |

## Design Philosophy

The projects follow a few principles:

- **Parameterization** — widths, depths, and other architectural dimensions should be configurable where practical.
- **Synthesizable RTL** — designs are written with implementation in mind rather than as purely behavioral models.
- **Architecture before code** — derive the hardware structure first and then express it in RTL.
- **Verification alongside design** — functional verification and formal properties are developed as part of the design process.
- **Corner-case driven development** — reset behavior, boundary conditions, wrap-around, empty/full conditions, and other edge cases are treated explicitly.
- **Implementation awareness** — synthesis results are inspected to understand the actual hardware implied by the RTL.

## Verification

The verification approach varies with the project and includes:

- Directed simulation
- Self-checking testbenches
- Waveform inspection
- SystemVerilog Assertions (SVA)
- Formal verification using **Yosys + SymbiYosys**
- Synthesis inspection using **Yosys**

The goal is not merely to obtain passing simulations, but to understand **what properties define correct hardware behavior** and to verify those properties as rigorously as practical.

## Repository Structure

```text
parameterized-rtl-design-verification/
│
├── parameterized-rr-arbiter/
│   ├── rtl/
│   ├── tb/
│   ├── formal/
│   └── ...
│
├── parameterized-sync-fifo/
│   └── ...
│
├── async-fifo/
│   ├── rtl/
│   └── ...
│
└── README.md
```

Individual projects are intentionally kept self-contained so that their RTL, testbench, and verification infrastructure can evolve independently.

## Tools

The projects primarily use open-source HDL and verification tooling, including:

- **SystemVerilog / Verilog**
- **Yosys** — synthesis and RTL analysis
- **SymbiYosys (SBY)** — formal verification orchestration
- **Yosys SMTBMC** — bounded/model-checking based formal verification
- **Icarus Verilog** — simulation where applicable
- **GTKWave** — waveform inspection where applicable

Exact tool requirements and commands may differ between projects; see the README or scripts inside an individual project where provided.

## Current Learning Focus

The repository is being developed progressively, with increasing emphasis on:

1. Parameterized RTL architecture
2. Efficient combinational structures
3. Sequential design and state management
4. Self-checking verification
5. SystemVerilog semantics
6. SystemVerilog Assertions
7. Formal property development
8. Safety, liveness, and fairness properties
9. Synthesis-aware RTL optimization

## Roadmap

Planned additions include progressively more complex reusable RTL blocks and stronger verification environments, with increasing use of:

- Assertions and formal verification
- Constrained/randomized testing
- Coverage
- CDC-aware verification
- More systematic synthesis and implementation analysis
- Reusable verification infrastructure

## Author

**Ayush Khetan**

Electronics & Communication Engineering  
BITS Pilani

---

> This repository is primarily a learning and portfolio project, with an emphasis on understanding the reasoning behind RTL architectures and their verification rather than simply collecting finished modules.

# DMA Controller Specification

## 1. Functional Overview

**Type:** Single-channel, memory-to-memory DMA controller
**Purpose:** Autonomous transfer of a programmed number of 32-bit words between source and destination memory addresses.

The CPU configures the DMA through an **MMIO register interface** and initiates a transfer using the START command. The DMA engine then performs the transfer independently of the CPU.

---

## 2. Data & Address Parameters

| Parameter | Specification |
|---|---|
| Data width | 32 bits |
| Address width | 32 bits |
| Transfer granularity | 1 word = 4 bytes |
| Addressing | Byte-addressed |
| Address increment | +4 bytes per completed word |
| Transfer length | Number of 32-bit words |
| Channels | 1 |
| Transfer direction | Memory → Memory |

---

## 3. Architecture

```text
                         MMIO Control Plane
                               │
                               ▼
                        ┌─────────────┐
                        │  dma_regs   │
                        │             │
              MMIO ───►│ SOURCE      │
                        │ DESTINATION │
                        │ LENGTH      │
                        │ CONTROL     │
                        │ STATUS      │
                        └──────┬──────┘
                               │
                 dma_start     │
                 src_addr      │
                 dst_addr      │
                 length        │
                               ▼
                        ┌─────────────┐
                        │ dma_engine  │
                        │             │
                        │ IDLE        │
                        │ READ        │
                        │ WRITE       │
                        │ DONE        │
                        └──────┬──────┘
                               │
                     Memory Interface
                               │
                               ▼
                           ┌───────┐
                           │Memory │
                           └───────┘

             dma_busy / dma_done
                  ▲
                  │
             dma_engine
                  │
                  ▼
               dma_regs
                  │
                  ▼
                 CPU

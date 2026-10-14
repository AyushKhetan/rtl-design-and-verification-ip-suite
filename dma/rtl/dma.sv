module dma(
    input logic        clk,
    input logic        rst_n,

    // MMIO interface
    input logic        mmio_valid,
    input logic        mmio_write,
    input logic [31:0] mmio_addr,
    input logic [31:0] mmio_wdata,
    output logic [31:0] mmio_rdata,

    output logic        mem_valid,
    output logic        mem_write,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    input  logic        mem_ready,
    input  logic [31:0] mem_rdata
);


    logic dma_start;
    logic dma_busy;
    logic dma_done;

    logic [31:0] src_addr;
    logic [31:0] dst_addr;
    logic [31:0] length;

dma_regs u_dma_regs(
    .clk(clk),
    .rst_n(rst_n),

    .mmio_valid(mmio_valid),
    .mmio_write(mmio_write),
    .mmio_addr(mmio_addr),
    .mmio_wdata(mmio_wdata),

    .mmio_rdata(mmio_rdata),
    .dma_busy(dma_busy),
    .dma_done(dma_done),

    .dma_start(dma_start),
    .src_addr(src_addr),
    .dst_addr(dst_addr),
    .length(length)
);


dma_engine u_dma_engine(
    .clk(clk),
    .rst_n(rst_n),

    .dma_start(dma_start),
    .src_addr(src_addr),
    .dst_addr(dst_addr),
    .length(length),

    .dma_busy(dma_busy),
    .dma_done(dma_done),

    .mem_valid(mem_valid),
    .mem_write(mem_write),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_ready(mem_ready)
);

endmodule

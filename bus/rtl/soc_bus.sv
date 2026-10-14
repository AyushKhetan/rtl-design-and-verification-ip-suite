module soc_bus(
    // instruction
    input  logic [31:0] imem_addr,
    output logic [31:0] imem_rdata,

    // Data
    input  logic [31:0] dmem_addr,
    input  logic [31:0] dmem_wdata,
    input  logic        dmem_read,
    input  logic        dmem_write,
    output logic [31:0] dmem_rdata,

    // Instruction memory
    output logic [31:0] imem_mem_addr,
    input  logic [31:0] imem_mem_rdata,

    // Data memory
    output logic [31:0] dmem_mem_addr,
    output logic [31:0] dmem_mem_wdata,

    output logic        dmem_mem_write,
    input  logic [31:0] dmem_mem_rdata,
);

    // Instruction path
    assign imem_mem_addr = imem_addr;
    assign imem_rdata    = imem_mem_rdata;

    // Data path
    assign dmem_mem_addr = dmem_addr;
    assign dmem_mem_wdata = dmem_wdata;
    assign dmem_mem_write = dmem_write;
    assign dmem_rdata = dmem_mem_rdata;

endmodule

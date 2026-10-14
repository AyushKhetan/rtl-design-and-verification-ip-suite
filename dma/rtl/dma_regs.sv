module dma_regs (
    input  logic        clk,
    input  logic        rst_n,

    // MMIO interface
    input  logic        mmio_valid,
    input  logic        mmio_write,
    input  logic [31:0] mmio_addr,
    input  logic [31:0] mmio_wdata,
    output logic [31:0] mmio_rdata,

    // DMA engine status
    input  logic        dma_busy,
    input  logic        dma_done,

    // Configuration to DMA engine
    output logic        dma_start,
    output logic [31:0] src_addr,
    output logic [31:0] dst_addr,
    output logic [31:0] length
);

localparam logic [31:0] ADDR_CONTROL = 32'h0000_0000;
localparam logic [31:0] ADDR_STATUS  = 32'h0000_0004;
localparam logic [31:0] ADDR_SOURCE  = 32'h0000_0008;
localparam logic [31:0] ADDR_DEST    = 32'h0000_000C;
localparam logic [31:0] ADDR_LENGTH  = 32'h0000_0010;



always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        src_addr <= 32'h0;
        dst_addr <= 32'h0;
        length   <= 32'h0;
        dma_start <= 1'b0;
    end
    else begin
        // START handling
        if(mmio_valid && mmio_write && (mmio_addr == ADDR_CONTROL) && (mmio_wdata[0] == 1'b1) && !dma_busy) begin
            dma_start <= 1'b1; // lsb of control word is start signal
        end
        else begin
            dma_start <= 1'b0;
        end
        // MMIO writes
        if(mmio_valid && mmio_write && mmio_addr == ADDR_SOURCE) begin
            src_addr <= mmio_wdata;
        end
        if(mmio_valid && mmio_write && mmio_addr == ADDR_DEST) begin
            dst_addr <= mmio_wdata;
        end
        if(mmio_valid && mmio_write && mmio_addr == ADDR_LENGTH) begin
            length <= mmio_wdata;
        end
    end
end

always_comb begin
    // Default read data
    mmio_rdata = 32'h0;

    if(mmio_valid && !mmio_write) begin
        case(mmio_addr)
            ADDR_SOURCE:  mmio_rdata = src_addr;
            ADDR_DEST:    mmio_rdata = dst_addr;
            ADDR_LENGTH:  mmio_rdata = length;
            ADDR_CONTROL: mmio_rdata = 32'h0; // Control register is write-only
            ADDR_STATUS:  mmio_rdata = {30'h0, dma_done, dma_busy}; // Status register
            default:      mmio_rdata = 32'h0; // Invalid address
        endcase
    end
end

endmodule

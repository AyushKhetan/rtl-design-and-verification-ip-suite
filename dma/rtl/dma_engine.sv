module dma_engine(
    input  logic        clk,
    input  logic        rst_n,

    // Command/Configuration
    input  logic        dma_start,
    input  logic [31:0] src_addr,
    input  logic [31:0] dst_addr,
    input  logic [31:0] length,

    // Status
    output logic        dma_busy,
    output logic        dma_done,

    // Memory interface
    output logic        mem_valid,
    output logic        mem_write,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    input  logic        mem_ready,
    input  logic [31:0] mem_rdata
);


logic [31:0] current_src;
logic [31:0] current_dst;
logic [31:0] remaining;
logic [31:0] data_buffer;

typedef enum logic [1:0] {
    IDLE,
    READ,
    WRITE,
    DONE
} state_t;

state_t state;

always_comb begin
    mem_valid = (state == READ) || (state == WRITE);
    mem_write = (state == WRITE);
    mem_addr  = (state == READ)  ? current_src :
                (state == WRITE) ? current_dst :
                                   32'h0;
    mem_wdata = data_buffer;
    dma_busy = (state == WRITE) || (state == READ);
    dma_done = (state == DONE);
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        current_src <= 0;
        current_dst <= 0;
        remaining <= 0;
        data_buffer <= 0;
    end
    else begin
        case(state)
            IDLE: begin
                if(dma_start) begin
                    current_src <= src_addr;
                    current_dst <= dst_addr;
                    remaining <= length;
                    if(length > 0) begin
                        state <= READ;
                    end
                    else begin
                        state <= DONE;
                    end
                end
            end
            READ: begin
                if(mem_ready) begin
                    data_buffer <= mem_rdata;
                    state <= WRITE;
                end
            end
            WRITE: begin
                if(mem_ready) begin
                    current_src <= current_src + 4;
                    current_dst <= current_dst + 4;
                    remaining <= remaining - 1;
                    if(remaining > 1) begin
                        state <= READ;
                    end
                    else begin
                        state <= DONE;
                    end
                end
            end
            DONE: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule

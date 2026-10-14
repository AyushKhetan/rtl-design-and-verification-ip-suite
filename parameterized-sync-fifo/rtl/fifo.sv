module fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 4
)(
    input logic clk,
    input logic reset,
    input logic wr_en,
    input logic rd_en,
    input logic [DATA_WIDTH-1:0] din,
    output logic [PTR_WIDTH-1:0] wr_ptr,
    output logic [PTR_WIDTH-1:0] rd_ptr,
    output logic [DATA_WIDTH-1:0] dout,
    output logic empty,
    output logic full,
    output logic [PTR_WIDTH-1:0] count
);


localparam int ADDR_WIDTH = $clog2(DEPTH);
localparam int PTR_WIDTH = ADDR_WIDTH + 1;

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1]; // 4x8 FIFO memory

logic past_valid;

always @(posedge clk) begin
    if (reset)
        past_valid <= 1'b0;
    else
        past_valid <= 1'b1;
end

always_ff@(posedge clk) begin
    if(reset) begin
        wr_ptr <= {PTR_WIDTH{1'b0}};
        rd_ptr <= {PTR_WIDTH{1'b0}};
        dout <= {DATA_WIDTH{1'b0}};
    end
    else begin
        if(wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
            wr_ptr <= wr_ptr + 1;
        end
        if(rd_en && !empty) begin
            dout <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
        end
    end
end

assign empty = (wr_ptr == rd_ptr);
assign full = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) && (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1]);
assign count = wr_ptr - rd_ptr;

endmodule

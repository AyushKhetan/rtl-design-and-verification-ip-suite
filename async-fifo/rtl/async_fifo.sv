module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 3
)(
    input logic wr_clk,
    input logic rd_clk,
    input logic reset,

    input logic wr_en,
    input logic [DATA_WIDTH-1:0] wr_data,
    output logic full,

    input logic rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic empty
);

parameter DEPTH = 2**ADDR_WIDTH;
parameter PTR_WIDTH = ADDR_WIDTH + 1;

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

logic write_fire;
assign write_fire = wr_en && !full;
logic [PTR_WIDTH-1:0] wr_ptr;
logic [PTR_WIDTH-1:0] wr_ptr_gray;
logic [PTR_WIDTH-1:0] wr_ptr_gray_immSync;
logic [PTR_WIDTH-1:0] wr_ptr_gray_sync;

always @(posedge wr_clk) begin
    if (reset) begin
        wr_ptr <= 0;
        wr_ptr_gray <= 0;
        wr_ptr_gray_sync <= 0;
        full <= 0;
    end 
    else if (write_fire) begin
        mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
        wr_ptr <= wr_ptr + 1;
        wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        full <= ((wr_ptr + 1) ^ ((wr_ptr + 1) >> 1) == ({~rd_ptr_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2], rd_ptr_gray_sync[PTR_WIDTH-3:0]}));
    end
    else begin
        full <= (wr_ptr_gray == {~rd_ptr_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2], rd_ptr_gray_sync[PTR_WIDTH-3:0]});
    end
end

logic read_fire;
assign read_fire = rd_en && !empty;
logic [PTR_WIDTH-1:0] rd_ptr;
logic [PTR_WIDTH-1:0] rd_ptr_gray;
logic [PTR_WIDTH-1:0] rd_ptr_gray_immSync;
logic [PTR_WIDTH-1:0] rd_ptr_gray_sync;

always @(posedge rd_clk) begin
    if (reset) begin
        rd_ptr <= 0;
        rd_ptr_gray <= 0;
        rd_ptr_gray_sync <= 0;
        empty <= 0;
    end 
    else if (read_fire) begin
        rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        rd_ptr <= rd_ptr + 1;
        rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        empty <= (((rd_ptr + 1) ^ ((rd_ptr + 1) >> 1)) == wr_ptr_gray_sync);
    end
    else begin
        empty <= (((rd_ptr) ^ ((rd_ptr) >> 1)) == wr_ptr_gray_sync);
    end
end

always @(posedge rd_clk) begin
    if (reset) begin
        wr_ptr_gray_immSync <= 0;
        wr_ptr_gray_sync <=0;
    end
    else begin
        wr_ptr_gray_immSync <= wr_ptr_gray;
        wr_ptr_gray_sync <= wr_ptr_gray_immSync;
    end
end

always @(posedge wr_clk) begin
    if (reset) begin
        rd_ptr_gray_immSync <= 0;
        rd_ptr_gray_sync <= 0;
    end
    else begin
        rd_ptr_gray_immSync <= rd_ptr_gray;
        rd_ptr_gray_sync <= rd_ptr_gray_immSync;
    end
end





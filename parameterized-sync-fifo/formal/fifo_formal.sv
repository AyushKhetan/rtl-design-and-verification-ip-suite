module fifo_formal;

    localparam int DATA_WIDTH = 16;
    localparam int DEPTH      = 8;
    localparam int ADDR_WIDTH = $clog2(DEPTH);
    localparam int PTR_WIDTH  = ADDR_WIDTH + 1;

    logic clk;
    logic reset;
    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] din;

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;
    logic [DATA_WIDTH-1:0] dout;
    logic empty;
    logic full;
    logic [PTR_WIDTH-1:0] count;

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk    (clk),
        .reset  (reset),
        .wr_en  (wr_en),
        .rd_en  (rd_en),
        .din    (din),
        .wr_ptr (wr_ptr),
        .rd_ptr (rd_ptr),
        .dout   (dout),
        .empty  (empty),
        .full   (full),
        .count  (count)
    );

    // Reset assumptions
    initial begin
        assume(reset);
    end

    always @(posedge clk) begin
        if ($initstate)
            assume(reset);
        else
            assume(!reset);
    end

    // FIFO invariants
    always @(posedge clk) begin
        if (!reset) begin

            // Empty iff count is zero
            assert(empty == (count == 0));

            // Full iff count equals DEPTH
            assert(full == (count == DEPTH));

            // Count cannot exceed FIFO capacity
            assert(count <= DEPTH);

        end
    end

endmodule
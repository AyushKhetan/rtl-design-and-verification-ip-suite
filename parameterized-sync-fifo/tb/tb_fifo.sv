module tb_fifo;

logic clk;
logic reset;
logic wr_en;
logic rd_en;
logic [15:0] din;

logic [3:0] wr_ptr;
logic [3:0] rd_ptr;
logic [15:0] dout;
logic empty;
logic full;
logic [3:0] count;

fifo  #(
    .DATA_WIDTH(16),
    .DEPTH(8)
) dut(
    .clk(clk),
    .reset(reset),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .din(din),
    .wr_ptr(wr_ptr),
    .rd_ptr(rd_ptr),
    .dout(dout),
    .empty(empty),
    .full(full),
    .count(count)
);

always #5 clk = ~clk; // Clock generation with a period of 10 time units

initial begin
    $dumpfile("sim/fifo.vcd");
    $dumpvars(0, tb_fifo);
    
    $monitor("t=%0t wr_ptr=%0d rd_ptr=%0d din=%0h dout=%0h empty=%b full=%b count=%0d",
         $time, wr_ptr, rd_ptr, din, dout, empty, full, count);
    clk = 0;
    reset = 1;
    wr_en = 0; 
    rd_en = 0;
    din = 16'b0;
    #10 reset = 0; // Release reset after 10 time units
    wr_en = 1; // Enable write
    din = 16'h0008; // Write data to FIFO
    @(posedge clk); // Wait for the next clock edge
    #1
    din = 16'h0009;
    @(posedge clk); // Wait for the next clock edge
    #1
    din = 16'h000A; 
    @(posedge clk); // Wait for the next clock edge
    #1
    din = 16'h000B;
    @(posedge clk); // Wait for the next clock edge
    #1
    din = 16'h000C;
    @(posedge clk); // Wait for the next clock edge
    #1
    wr_en = 0; // Disable write
    repeat (3) begin
        #5 rd_en = 1;
        @(posedge clk); // Wait for the next clock edge
    end
    #1
    rd_en = 0; // Disable read
    wr_en = 1; // Enable write
    #1
    din = 16'h000D; // Write data to FIFO
    @(posedge clk); // Wait for the next clock edge
    #1
    din = 16'h000E;
    @(posedge clk); // Wait for the next clock edge
    #1
    din = 16'h000F;
    @(posedge clk); // Wait for the next clock edge
    #1
    din = 16'h0010;
    @(posedge clk); // Wait for the next clock edge
    #1
    wr_en = 0; // Disable write
    #5 rd_en = 1; // Enable read
    repeat (6) begin
        @(posedge clk); // Wait for the next clock edge
    end
    #10 $finish; // End simulation
end

endmodule





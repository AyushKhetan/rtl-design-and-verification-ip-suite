`timescale 1ns/1ps
module uart_tx_tb;

    // ---------------------------------------------------------
    // Testbench parameters
    // ---------------------------------------------------------
    localparam int CLK_FREQ  = 100;
    localparam int BAUD_RATE = 10;

    // ---------------------------------------------------------
    // DUT signals
    // ---------------------------------------------------------
    logic       clk;
    logic       reset;
    logic [7:0] data_in;
    logic       start;
    logic       tx;
    logic       busy;

    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk       (clk),
        .reset     (reset),
        .data_in   (data_in),
        .start     (start),
        .tx        (tx),
        .busy      (busy)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ---------------------------------------------------------
    // Test sequence
    // ---------------------------------------------------------
    initial begin

        // Initial values
        reset  = 1'b1;
        data_in = 8'b0;
        start  = 1'b0;

        // Hold reset for a couple of clock cycles
        repeat (2) @(posedge clk);

        // Release reset
        reset = 1'b0;

        // Give DUT one cycle
        @(posedge clk);

        // Load data
        data_in = 8'b10110010;

        // Start transmission
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        // Wait for transmission to finish
        wait (busy == 1'b1);
        wait (busy == 1'b0);

        // Give simulation some time to settle
        #20;

        $finish;
    end

    // ---------------------------------------------------------
    // Waveform dump
    // ---------------------------------------------------------
    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);
    end

endmodule

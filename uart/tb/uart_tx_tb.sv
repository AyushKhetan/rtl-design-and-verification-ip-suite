`timescale 1ns/1ps

module uart_tx_tb;

    localparam int CLK_FREQ  = 100;
    localparam int BAUD_RATE = 10;
    localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

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

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ---------------------------------------------------------
    // Transmit one byte and check the complete UART frame
    // ---------------------------------------------------------
    task automatic transmit_and_check(input logic [7:0] data);
        logic [9:0] expected_frame;
        logic [9:0] received_frame;
        integer i;

        begin
            // UART frame:
            // {stop, data[7:0], start}
            // This naturally gives LSB-first data transmission.
            expected_frame = {1'b1, data, 1'b0};

            data_in = data;

            // Start transaction
            @(posedge clk);
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            // Wait until TX actually becomes busy
            wait (busy == 1'b1);

            // Wait until the middle of the START bit.
            // We are using 10 clocks/bit.
            repeat (CLKS_PER_BIT / 2) @(posedge clk);

            // Sample each of the 10 frame bits
            for (i = 0; i < 10; i = i + 1) begin
                received_frame[i] = tx;
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            if (received_frame !== expected_frame) begin
                $display("FAIL: data = %h", data);
                $display("Expected frame = %b", expected_frame);
                $display("Received frame = %b", received_frame);
                $fatal;
            end
            else begin
                $display("PASS: data = %h", data);
            end

            // Transmission should eventually finish
            wait (busy == 1'b0);

            // Make sure TX returned to idle level
            if (tx !== 1'b1) begin
                $display("FAIL: TX did not return to idle");
                $fatal;
            end
        end
    endtask

    // ---------------------------------------------------------
    // Test
    // ---------------------------------------------------------
    initial begin
        reset   = 1'b1;
        data_in = 8'h00;
        start   = 1'b0;

        repeat (2) @(posedge clk);

        reset = 1'b0;

        transmit_and_check(8'hB2);
        transmit_and_check(8'h00);
        transmit_and_check(8'hFF);
        transmit_and_check(8'hA5);

        $display("--------------------------------");
        $display("UART TX TEST PASSED");
        $display("--------------------------------");

        #20;
        $finish;
    end

    // Waveform
    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);
    end

endmodule

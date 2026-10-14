`timescale 1ns/1ps

module uart_loopback_tb;

    localparam int CLK_FREQ  = 1600;
    localparam int BAUD_RATE = 10;

    logic       clk;
    logic       reset;

    logic [7:0] tx_data;
    logic       start;
    logic       tx;
    logic       tx_busy;

    logic [7:0] rx_data;
    logic       rx_valid;

    // ---------------------------------------------------------
    // TX
    // ---------------------------------------------------------
    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) tx_inst (
        .clk       (clk),
        .reset     (reset),
        .data_in   (tx_data),
        .start     (start),
        .tx        (tx),
        .busy      (tx_busy)
    );

    // ---------------------------------------------------------
    // RX
    // ---------------------------------------------------------
    uart_rx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) rx_inst (
        .clk       (clk),
        .reset     (reset),
        .rx        (tx),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid)
    );

    // ---------------------------------------------------------
    // Clock
    // ---------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ---------------------------------------------------------
    // Waveform
    // ---------------------------------------------------------
    initial begin
        $dumpfile("uart_loopback.vcd");
        $dumpvars(0, uart_loopback_tb);
    end

    // ---------------------------------------------------------
    // Transmit and verify one byte
    // ---------------------------------------------------------
    task automatic transmit_and_check(input logic [7:0] data);

        begin
            tx_data = data;

            // Start pulse
            @(posedge clk);
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            // Wait for receiver to report a valid byte
            // Make sure TX has finished before starting another byte
            fork
                begin
                    wait (tx_busy == 1'b0);
                end
                begin
                    wait (rx_valid == 1'b1);
                end
            join

            if (rx_data !== data) begin
                $display("FAIL: TX=%h RX=%h", data, rx_data);
                $fatal;
            end
            else begin
                $display("PASS: TX=%h RX=%h", data, rx_data);
            end



            // rx_valid is a pulse; give it time to return low
            repeat (1000)@(posedge clk);
        end

    endtask

    // ---------------------------------------------------------
    // Test sequence
    // ---------------------------------------------------------
    initial begin

        reset   = 1'b1;
        tx_data = 8'h00;
        start   = 1'b0;

        repeat (3) @(posedge clk);
        reset = 1'b0;

        transmit_and_check(8'h00);
        transmit_and_check(8'hA5);
        transmit_and_check(8'hFF);
        transmit_and_check(8'hB2);
        transmit_and_check(8'hB5);

        $display("----------------------------------------");
        $display("UART TX -> RX LOOPBACK TEST PASSED");
        $display("----------------------------------------");

        #100;
        $finish;
    end

endmodule

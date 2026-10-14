`timescale 1ns/1ps

module uart_rx_tb;

    localparam int CLK_FREQ  = 1600;
    localparam int BAUD_RATE = 10;

    logic       clk;
    logic       reset;
    logic       rx;

    logic [7:0] rx_data;
    logic       rx_valid;

    uart_rx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk       (clk),
        .reset     (reset),
        .rx        (rx),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid)
    );

    // 10 ns clock period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("uart_rx.vcd");
        $dumpvars(0, uart_rx_tb);
    end

    initial begin
        reset = 1;
        rx    = 1;

        repeat (2) @(posedge clk);
        reset = 0;
        rx = 1;
        repeat (2) @(posedge clk);

        /*send_uart_byte(8'hB5);

        wait (rx_valid);

        if (rx_data !== 8'hB5) begin
            $display("FAIL: expected B5, got %h", rx_data);
            $fatal;
        end
        else begin
            $display("PASS: received B5");
        end

        send_bad_stop(8'hA5);

        // Give RX enough time to process the stop bit
        repeat (20) @(posedge clk);

        if (rx_valid !== 1'b0) begin
            $display("FAIL: rx_valid asserted on framing error");
            $fatal;
        end
        else begin
            $display("PASS: framing error rejected");
        end*/

        send_noise();

        repeat (100) @(posedge clk);

        if (rx_valid !== 1'b0) begin
            $display("FAIL: false start accepted");
            $fatal;
        end
        else begin
            $display("PASS: false start rejected");
        end

        $finish;

    end

    task automatic send_uart_byte(input logic [7:0] data);

        integer i;

        begin
            // Start bit
            rx = 1'b0;
            repeat (160) @(posedge clk);

            // Data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                repeat (160) @(posedge clk);
            end

            // Stop bit
            rx = 1'b1;
            repeat (160) @(posedge clk);
        end

    endtask


    task automatic send_bad_stop(input logic [7:0] data);

        integer i;

        begin
            // START
            rx = 1'b0;
            repeat (160) @(posedge clk);

            // DATA, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                repeat (160) @(posedge clk);
            end

            // BAD STOP: should be 1, but deliberately keep it 0
            rx = 1'b0;
            repeat (160) @(posedge clk);

            // Return line to idle
            rx = 1'b1;
        end

    endtask


    task automatic send_noise;

        begin
            // Idle
            rx = 1'b1;

            // Short low pulse: 50 clocks < 80-clock START validation time
            rx = 1'b0;
            repeat (50) @(posedge clk);

            // Return to idle
            rx = 1'b1;
        end

    endtask

endmodule

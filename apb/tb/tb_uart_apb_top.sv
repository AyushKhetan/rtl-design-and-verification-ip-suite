
`timescale 1ns/1ps

module tb_uart_apb_top;

    localparam integer CLK_FREQ  = 160;
    localparam integer BAUD_RATE = 10;

    logic PCLK = 1'b0;
    logic PRESETn = 1'b0;

    logic PSEL = 1'b0;
    logic PENABLE = 1'b0;
    logic PWRITE = 1'b0;
    logic [7:0] PADDR = 8'h00;
    logic [7:0] PWDATA = 8'h00;

    logic [7:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

    logic uart_rx_pin;
    logic uart_tx_pin;

    assign uart_rx_pin = uart_tx_pin;

    always #5 PCLK = ~PCLK;

    uart_apb_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .uart_rx_pin(uart_rx_pin),
        .uart_tx_pin(uart_tx_pin)
    );

    task automatic apb_write(
        input logic [7:0] addr,
        input logic [7:0] data
    );
        @(negedge PCLK);
        PSEL = 1'b1;
        PENABLE = 1'b0;
        PWRITE = 1'b1;
        PADDR = addr;
        PWDATA = data;

        @(negedge PCLK);
        PENABLE = 1'b1;

        @(posedge PCLK);
        #1;

        if (PSLVERR)
            $fatal(1, "Unexpected APB write error at %h", addr);

        @(negedge PCLK);
        PSEL = 1'b0;
        PENABLE = 1'b0;
        PWRITE = 1'b0;
        PADDR = 8'h00;
        PWDATA = 8'h00;
    endtask

    task automatic apb_read(
        input logic [7:0] addr,
        output logic [7:0] data
    );
        @(negedge PCLK);
        PSEL = 1'b1;
        PENABLE = 1'b0;
        PWRITE = 1'b0;
        PADDR = addr;

        @(negedge PCLK);
        PENABLE = 1'b1;

        @(posedge PCLK);
        #1;
        data = PRDATA;

        if (PSLVERR)
            $fatal(1, "Unexpected APB read error at %h", addr);

        @(negedge PCLK);
        PSEL = 1'b0;
        PENABLE = 1'b0;
        PADDR = 8'h00;
    endtask

    logic [7:0] received;

    initial begin

        repeat (4) @(negedge PCLK);
        PRESETn = 1'b1;

        // Write transmit byte.
        apb_write(8'h08, 8'hA5);

        // Wait for UART transmission and reception to finish.
        repeat (200) @(negedge PCLK);

        // Check that RX data is available.
        apb_read(8'h04, received);
        if (received[1] !== 1'b1)
            $fatal(1, "RX_AVAILABLE was not asserted");

        // Read received byte.
        apb_read(8'h0C, received);
        if (received !== 8'hA5)
            $fatal(1, "RX mismatch: expected A5, got %h", received);

        // RX_AVAILABLE should clear after reading RX_DATA.
        apb_read(8'h04, received);
        if (received[1] !== 1'b0)
            $fatal(1, "RX_AVAILABLE did not clear");

        $display("PASS: APB -> UART TX -> UART RX -> APB");
        $finish;
    end

    initial begin
        #50000;
        $fatal(1, "TIMEOUT: end-to-end test");
    end

endmodule

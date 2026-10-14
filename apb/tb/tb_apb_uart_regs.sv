`timescale 1ns/1ps

module tb_apb_uart_regs;

    // ------------------------------------------------------------
    // Clock and reset
    // ------------------------------------------------------------

    logic PCLK;
    logic PRESETn;

    initial begin
        PCLK = 1'b0;
        forever #5 PCLK = ~PCLK;
    end


    // ------------------------------------------------------------
    // APB signals
    // ------------------------------------------------------------

    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [7:0]  PADDR;
    logic [7:0]  PWDATA;

    logic [7:0]  PRDATA;
    logic        PREADY;
    logic        PSLVERR;

    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy = 1'b0;

    logic [7:0] rx_data = 8'h00;
    logic       rx_valid = 1'b0;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    apb_uart_regs dut (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),

        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PADDR   (PADDR),
        .PWDATA  (PWDATA),

        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR),

        .tx_data  (tx_data),
        .tx_start (tx_start),
        .tx_busy  (tx_busy),

        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );


    // ------------------------------------------------------------
    // APB write task
    // ------------------------------------------------------------

    task automatic apb_write(
        input  logic [7:0] addr,
        input  logic [7:0] data,
        output logic       error
    );
        begin
            error = 1'b0;

            @(negedge PCLK);
            PSEL    = 1'b1;
            PENABLE = 1'b0;
            PWRITE  = 1'b1;
            PADDR   = addr;
            PWDATA  = data;

            @(negedge PCLK);
            PENABLE = 1'b1;

            @(posedge PCLK);
            #1;

            error = PSLVERR;

            if (error)
                $display("WRITE ERROR: addr=%h data=%h", addr, data);
            else
                $display("WRITE OK: addr=%h data=%h", addr, data);

            @(negedge PCLK);
            PSEL    = 1'b0;
            PENABLE = 1'b0;
            PWRITE  = 1'b0;
            PADDR   = 8'h00;
            PWDATA  = 8'h00;
        end
    endtask

    // ------------------------------------------------------------
    // APB read task
    // ------------------------------------------------------------

    task automatic apb_read(
        input  logic [7:0] addr,
        output logic [7:0] data
    );
        begin
            // SETUP
            @(negedge PCLK);
            PSEL    = 1'b1;
            PENABLE = 1'b0;
            PWRITE  = 1'b0;
            PADDR   = addr;
            PWDATA  = 8'h00;

            // ACCESS
            @(negedge PCLK);
            PENABLE = 1'b1;

            // Transfer completes on next rising edge
            @(posedge PCLK);

            #1;

            data = PRDATA;

            if (PSLVERR)
                $display("READ ERROR: addr=%h", addr);
            else
                $display("READ OK: addr=%h data=%h", addr, data);

            // Return to IDLE
            @(negedge PCLK);
            PSEL    = 1'b0;
            PENABLE = 1'b0;
            PADDR   = 8'h00;
        end
    endtask


    logic write_error;

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    logic [7:0] read_data;

    initial begin

        // Initial values
        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PADDR   = 8'h00;
        PWDATA  = 8'h00;

        // Reset
        PRESETn = 1'b0;

        repeat (2)
            @(posedge PCLK);

        PRESETn = 1'b1;

        @(posedge PCLK);


        // --------------------------------------------------------
        // TEST 1: CONTROL write/read
        // --------------------------------------------------------

        apb_write(8'h00, 8'h01, write_error);

        apb_read(8'h00, read_data);

        if (read_data !== 8'h01)
            $error("TEST 1 FAILED: CONTROL expected 01, got %h",
                   read_data);
        else
            $display("TEST 1 PASSED");


        // --------------------------------------------------------
        // TEST 2: TX_DATA write/read
        // --------------------------------------------------------

        apb_write(8'h08, 8'h55, write_error);

        apb_read(8'h08, read_data);

        if (read_data !== 8'h55)
            $error("TEST 2 FAILED: TX_DATA expected 55, got %h",
                   read_data);
        else
            $display("TEST 2 PASSED");


        // --------------------------------------------------------
        // TEST 3: STATUS read
        // --------------------------------------------------------

        apb_read(8'h04, read_data);

        if (read_data !== 8'h00)
            $error("TEST 3 FAILED: STATUS expected 00, got %h",
                   read_data);
        else
            $display("TEST 3 PASSED");


        // --------------------------------------------------------
        // TEST 4: RX_DATA read
        // --------------------------------------------------------

        apb_read(8'h0C, read_data);

        if (read_data !== 8'h00)
            $error("TEST 4 FAILED: RX_DATA expected 00, got %h",
                   read_data);
        else
            $display("TEST 4 PASSED");


        // --------------------------------------------------------
        // TEST 5: Illegal write to STATUS
        // --------------------------------------------------------

        apb_write(8'h04, 8'hAA, write_error);

        if (!write_error)
            $error("TEST 5 FAILED: STATUS write should generate error");
        else
            $display("TEST 5 PASSED");

        // --------------------------------------------------------
        // TEST 6: Illegal write to RX_DATA
        // --------------------------------------------------------

        apb_write(8'h0C, 8'hAA, write_error);

        if (!PSLVERR)
            $error("TEST 6 FAILED: RX_DATA write should generate error");
        else
            $display("TEST 6 PASSED");


        // --------------------------------------------------------
        // TEST 7: Invalid address
        // --------------------------------------------------------

        apb_write(8'h20, 8'hAA, write_error);

        if (!PSLVERR)
            $error("TEST 7 FAILED: invalid write should generate error");
        else
            $display("TEST 7 PASSED");


        apb_read(8'h20, read_data);

        if (!PSLVERR)
            $error("TEST 8 FAILED: invalid read should generate error");
        else if (read_data !== 8'h00)
            $error("TEST 8 FAILED: invalid read should return 00");
        else
            $display("TEST 8 PASSED");


        // --------------------------------------------------------
        // Finish
        // --------------------------------------------------------

        $display("----------------------------------------");
        $display("APB REGISTER BLOCK TEST COMPLETE");
        $display("----------------------------------------");

        #20;
        $finish;
    end

endmodule

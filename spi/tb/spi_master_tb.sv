`timescale 1ns/1ps

module spi_master_tb;

    // ============================================================
    // PARAMETERS
    // ============================================================

    localparam int CLK_FREQ = 50_000_000;
    localparam int SPI_FREQ = 1_000_000;

    localparam time CLK_PERIOD = 20ns;

    integer error_count;


    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic reset;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    // ============================================================
    // MODE 0 SIGNALS
    // CPOL = 0, CPHA = 0
    // ============================================================

    logic       start0;
    logic [7:0] tx0;
    logic [7:0] rx0;
    logic       busy0;
    logic       done0;
    logic       cs0;
    logic       sclk0;
    logic       mosi0;
    logic       miso0;

    logic [7:0] slave0_data;
    logic [7:0] observed_tx0;


    // ============================================================
    // MODE 1 SIGNALS
    // CPOL = 0, CPHA = 1
    // ============================================================

    logic       start1;
    logic [7:0] tx1;
    logic [7:0] rx1;
    logic       busy1;
    logic       done1;
    logic       cs1;
    logic       sclk1;
    logic       mosi1;
    logic       miso1;

    logic [7:0] slave1_data;
    logic [7:0] observed_tx1;


    // ============================================================
    // MODE 2 SIGNALS
    // CPOL = 1, CPHA = 0
    // ============================================================

    logic       start2;
    logic [7:0] tx2;
    logic [7:0] rx2;
    logic       busy2;
    logic       done2;
    logic       cs2;
    logic       sclk2;
    logic       mosi2;
    logic       miso2;

    logic [7:0] slave2_data;
    logic [7:0] observed_tx2;


    // ============================================================
    // MODE 3 SIGNALS
    // CPOL = 1, CPHA = 1
    // ============================================================

    logic       start3;
    logic [7:0] tx3;
    logic [7:0] rx3;
    logic       busy3;
    logic       done3;
    logic       cs3;
    logic       sclk3;
    logic       mosi3;
    logic       miso3;

    logic [7:0] slave3_data;
    logic [7:0] observed_tx3;


    // ============================================================
    // DUT - MODE 0
    // ============================================================

    spi_master #(
        .CLK_FREQ(CLK_FREQ),
        .SPI_FREQ(SPI_FREQ),
        .CPOL(0),
        .CPHA(0)
    ) dut_mode0 (
        .clk(clk),
        .reset(reset),

        .start(start0),
        .tx_data(tx0),

        .rx_data(rx0),
        .busy(busy0),
        .done(done0),

        .cs(cs0),
        .sclk(sclk0),
        .mosi(mosi0),
        .miso(miso0)
    );


    // ============================================================
    // DUT - MODE 1
    // ============================================================

    spi_master #(
        .CLK_FREQ(CLK_FREQ),
        .SPI_FREQ(SPI_FREQ),
        .CPOL(0),
        .CPHA(1)
    ) dut_mode1 (
        .clk(clk),
        .reset(reset),

        .start(start1),
        .tx_data(tx1),

        .rx_data(rx1),
        .busy(busy1),
        .done(done1),

        .cs(cs1),
        .sclk(sclk1),
        .mosi(mosi1),
        .miso(miso1)
    );


    // ============================================================
    // DUT - MODE 2
    // ============================================================

    spi_master #(
        .CLK_FREQ(CLK_FREQ),
        .SPI_FREQ(SPI_FREQ),
        .CPOL(1),
        .CPHA(0)
    ) dut_mode2 (
        .clk(clk),
        .reset(reset),

        .start(start2),
        .tx_data(tx2),

        .rx_data(rx2),
        .busy(busy2),
        .done(done2),

        .cs(cs2),
        .sclk(sclk2),
        .mosi(mosi2),
        .miso(miso2)
    );


    // ============================================================
    // DUT - MODE 3
    // ============================================================

    spi_master #(
        .CLK_FREQ(CLK_FREQ),
        .SPI_FREQ(SPI_FREQ),
        .CPOL(1),
        .CPHA(1)
    ) dut_mode3 (
        .clk(clk),
        .reset(reset),

        .start(start3),
        .tx_data(tx3),

        .rx_data(rx3),
        .busy(busy3),
        .done(done3),

        .cs(cs3),
        .sclk(sclk3),
        .mosi(mosi3),
        .miso(miso3)
    );


    // ============================================================
    // MODE 0 SLAVE
    //
    // CPOL = 0
    // CPHA = 0
    //
    // Rising  = SAMPLE
    // Falling = CHANGE
    //
    // D7 must be available before first rising edge.
    // ============================================================

    initial begin : mode0_slave

        integer i;

        miso0 = 1'b0;

        forever begin

            @(negedge cs0);

            observed_tx0 = 8'h00;

            // First MISO bit available before first sample
            miso0 = slave0_data[7];

            for (i = 7; i >= 0; i = i - 1) begin

                // Master samples MISO / slave observes MOSI
                @(posedge sclk0);

                #1;
                observed_tx0[i] = mosi0;

                if (i > 0) begin

                    // Slave changes MISO
                    @(negedge sclk0);
                    miso0 = slave0_data[i-1];

                end

            end

            // Wait for transaction termination
            @(posedge cs0);

            miso0 = 1'b0;

        end

    end


    // ============================================================
    // MODE 1 SLAVE
    //
    // CPOL = 0
    // CPHA = 1
    //
    // Rising  = CHANGE
    // Falling = SAMPLE
    //
    // D7 is established on first rising/change edge.
    // ============================================================

    initial begin : mode1_slave

        integer i;

        miso1 = 1'b0;

        forever begin

            @(negedge cs1);

            observed_tx1 = 8'h00;

            for (i = 7; i >= 0; i = i - 1) begin

                // First edge is rising/change.
                // Master changes MOSI here.
                @(posedge sclk1);

                #1;

                observed_tx1[i] = mosi1;

                // Slave changes MISO on change edge.
                // It is then stable for the following falling
                // sample edge.
                miso1 = slave1_data[i];

                // Falling edge = SAMPLE
                @(negedge sclk1);

            end

            miso1 = 1'b0;

        end

    end


    // ============================================================
    // MODE 2 SLAVE
    //
    // CPOL = 1
    // CPHA = 0
    //
    // Falling = SAMPLE
    // Rising  = CHANGE
    //
    // D7 must be available before first falling edge.
    // ============================================================

    initial begin : mode2_slave

        integer i;

        miso2 = 1'b0;

        forever begin

            @(negedge cs2);

            observed_tx2 = 8'h00;

            // First MISO bit available before first sample
            miso2 = slave2_data[7];

            for (i = 7; i >= 0; i = i - 1) begin

                // Falling edge = SAMPLE
                @(negedge sclk2);

                #1;

                observed_tx2[i] = mosi2;

                if (i > 0) begin

                    // Rising edge = CHANGE
                    @(posedge sclk2);

                    miso2 = slave2_data[i-1];

                end

            end

            @(posedge cs2);

            miso2 = 1'b0;

        end

    end


    // ============================================================
    // MODE 3 SLAVE
    //
    // CPOL = 1
    // CPHA = 1
    //
    // Falling = CHANGE
    // Rising  = SAMPLE
    //
    // D7 is established on first falling/change edge.
    // ============================================================

    initial begin : mode3_slave

        integer i;

        miso3 = 1'b0;

        forever begin

            @(negedge cs3);

            observed_tx3 = 8'h00;

            for (i = 7; i >= 0; i = i - 1) begin

                // First edge is falling/change.
                @(negedge sclk3);

                #1;

                observed_tx3[i] = mosi3;

                // Slave changes MISO on change edge.
                // It is stable for the following rising sample.
                miso3 = slave3_data[i];

                // Rising edge = SAMPLE
                @(posedge sclk3);

            end

            miso3 = 1'b0;

        end

    end


    // ============================================================
    // RESET / INITIALIZATION
    // ============================================================

    initial begin

        reset = 1'b1;

        start0 = 1'b0;
        start1 = 1'b0;
        start2 = 1'b0;
        start3 = 1'b0;

        tx0 = 8'h00;
        tx1 = 8'h00;
        tx2 = 8'h00;
        tx3 = 8'h00;

        slave0_data = 8'h00;
        slave1_data = 8'h00;
        slave2_data = 8'h00;
        slave3_data = 8'h00;

        error_count = 0;

        repeat (5) @(posedge clk);

        reset = 1'b0;

    end


    // ============================================================
    // MODE 0 TEST
    // ============================================================

    task test_mode0;

        input [7:0] tx_byte;
        input [7:0] rx_byte;

        begin

            $display("");
            $display("============================================");
            $display("MODE 0 TEST");
            $display("TX = %02h    RX = %02h", tx_byte, rx_byte);
            $display("============================================");

            slave0_data = rx_byte;

            // Drive inputs away from DUT sampling edge
            @(negedge clk);

            tx0 = tx_byte;
            start0 = 1'b1;

            @(negedge clk);

            start0 = 1'b0;

            // Wait for completion
            @(posedge done0);

            @(posedge clk);

            if (rx0 !== rx_byte) begin

                $display(
                    "MODE 0 RX FAILED: expected %02h, got %02h",
                    rx_byte, rx0
                );

                error_count = error_count + 1;

            end
            else
                $display("MODE 0 RX PASSED");


            if (observed_tx0 !== tx_byte) begin

                $display(
                    "MODE 0 TX FAILED: expected %02h, got %02h",
                    tx_byte, observed_tx0
                );

                error_count = error_count + 1;

            end
            else
                $display("MODE 0 TX PASSED");


            if (cs0 !== 1'b1 ||
                busy0 !== 1'b0 ||
                sclk0 !== 1'b0) begin

                $display("MODE 0 CONTROL FAILED");

                error_count = error_count + 1;

            end
            else
                $display("MODE 0 CONTROL PASSED");

        end

    endtask


    // ============================================================
    // MODE 1 TEST
    // ============================================================

    task test_mode1;

        input [7:0] tx_byte;
        input [7:0] rx_byte;

        begin

            $display("");
            $display("============================================");
            $display("MODE 1 TEST");
            $display("TX = %02h    RX = %02h", tx_byte, rx_byte);
            $display("============================================");

            slave1_data = rx_byte;

            @(negedge clk);

            tx1 = tx_byte;
            start1 = 1'b1;

            @(negedge clk);

            start1 = 1'b0;

            @(posedge done1);

            @(posedge clk);

            if (rx1 !== rx_byte) begin

                $display(
                    "MODE 1 RX FAILED: expected %02h, got %02h",
                    rx_byte, rx1
                );

                error_count = error_count + 1;

            end
            else
                $display("MODE 1 RX PASSED");


            if (observed_tx1 !== tx_byte) begin

                $display(
                    "MODE 1 TX FAILED: expected %02h, got %02h",
                    tx_byte, observed_tx1
                );

                error_count = error_count + 1;

            end
            else
                $display("MODE 1 TX PASSED");


            if (cs1 !== 1'b1 ||
                busy1 !== 1'b0 ||
                sclk1 !== 1'b0) begin

                $display("MODE 1 CONTROL FAILED");

                error_count = error_count + 1;

            end
            else
                $display("MODE 1 CONTROL PASSED");

        end

    endtask


    // ============================================================
    // MODE 2 TEST
    // ============================================================

    task test_mode2;

        input [7:0] tx_byte;
        input [7:0] rx_byte;

        begin

            $display("");
            $display("============================================");
            $display("MODE 2 TEST");
            $display("TX = %02h    RX = %02h", tx_byte, rx_byte);
            $display("============================================");

            slave2_data = rx_byte;

            @(negedge clk);

            tx2 = tx_byte;
            start2 = 1'b1;

            @(negedge clk);

            start2 = 1'b0;

            @(posedge done2);

            @(posedge clk);

            if (rx2 !== rx_byte) begin

                $display(
                    "MODE 2 RX FAILED: expected %02h, got %02h",
                    rx_byte, rx2
                );

                error_count = error_count + 1;

            end
            else
                $display("MODE 2 RX PASSED");


            if (observed_tx2 !== tx_byte) begin

                $display(
                    "MODE 2 TX FAILED: expected %02h, got %02h",
                    tx_byte, observed_tx2
                );

                error_count = error_count + 1;

            end
            else
                $display("MODE 2 TX PASSED");


            if (cs2 !== 1'b1 ||
                busy2 !== 1'b0 ||
                sclk2 !== 1'b1) begin

                $display("MODE 2 CONTROL FAILED");

                error_count = error_count + 1;

            end
            else
                $display("MODE 2 CONTROL PASSED");

        end

    endtask


    // ============================================================
    // MODE 3 TEST
    // ============================================================

    task test_mode3;

        input [7:0] tx_byte;
        input [7:0] rx_byte;

        begin

            $display("");
            $display("============================================");
            $display("MODE 3 TEST");
            $display("TX = %02h    RX = %02h", tx_byte, rx_byte);
            $display("============================================");

            slave3_data = rx_byte;

            @(negedge clk);

            tx3 = tx_byte;
            start3 = 1'b1;

            @(negedge clk);

            start3 = 1'b0;

            @(posedge done3);

            @(posedge clk);

            if (rx3 !== rx_byte) begin

                $display(
                    "MODE 3 RX FAILED: expected %02h, got %02h",
                    rx_byte, rx3
                );

                error_count = error_count + 1;

            end
            else
                $display("MODE 3 RX PASSED");


            if (observed_tx3 !== tx_byte) begin

                $display(
                    "MODE 3 TX FAILED: expected %02h, got %02h",
                    tx_byte, observed_tx3
                );

                error_count = error_count + 1;

            end
            else
                $display("MODE 3 TX PASSED");


            if (cs3 !== 1'b1 ||
                busy3 !== 1'b0 ||
                sclk3 !== 1'b1) begin

                $display("MODE 3 CONTROL FAILED");

                error_count = error_count + 1;

            end
            else
                $display("MODE 3 CONTROL PASSED");

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        wait(reset == 1'b0);

        @(negedge clk);

        // --------------------------------------------------------
        // Basic test patterns
        // --------------------------------------------------------

        test_mode0(8'h3C, 8'hA5);

        test_mode1(8'hF0, 8'h5A);

        test_mode2(8'hA5, 8'h5A);

        test_mode3(8'h5A, 8'hA5);


        // --------------------------------------------------------
        // All-zero / all-one patterns
        // --------------------------------------------------------

        test_mode0(8'hFF, 8'h00);

        test_mode1(8'h00, 8'hFF);

        test_mode2(8'h00, 8'hFF);

        test_mode3(8'hFF, 8'h00);


        // --------------------------------------------------------
        // Additional mixed patterns
        // --------------------------------------------------------

        test_mode0(8'hA5, 8'h5A);

        test_mode1(8'h5A, 8'hA5);

        test_mode2(8'h3C, 8'hC3);

        test_mode3(8'hC3, 8'h3C);


        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("================================================");

        if (error_count == 0)
            $display("ALL SPI MODE 0/1/2/3 TESTS PASSED");
        else
            $display(
                "SPI TESTS FAILED: %0d ERROR(S)",
                error_count
            );

        $display("================================================");
        $display("");

        #100;

        $finish;

    end


    // ============================================================
    // WAVEFORM DUMP
    // ============================================================

    initial begin

        $dumpfile("spi_master_tb.vcd");
        $dumpvars(0, spi_master_tb);

    end

endmodule

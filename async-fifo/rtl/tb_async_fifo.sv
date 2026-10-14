`timescale 1ns/1ps

module tb_async_fifo;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 3;
    localparam DEPTH      = 2**ADDR_WIDTH;

    logic                  wr_clk, rd_clk;
    logic                  reset;
    logic                  wr_en, rd_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic [DATA_WIDTH-1:0] rd_data;
    logic                  full, empty;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk  (wr_clk),
        .rd_clk  (rd_clk),
        .reset   (reset),
        .wr_en   (wr_en),
        .wr_data (wr_data),
        .full    (full),
        .rd_en   (rd_en),
        .rd_data (rd_data),
        .empty   (empty)
    );

    // ------------------------------------------------------------
    // Unrelated clocks: 10 ns and 14 ns
    // ------------------------------------------------------------

    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk;
    end

    initial begin
        rd_clk = 0;
        forever #7 rd_clk = ~rd_clk;
    end

    // ------------------------------------------------------------
    // Reference model
    // ------------------------------------------------------------

    logic [DATA_WIDTH-1:0] expected_queue [$];

    integer errors;
    integer writes;
    integer reads;
    integer i;

    // ------------------------------------------------------------
    // Monitor successful writes
    // ------------------------------------------------------------

    always @(posedge wr_clk) begin
        if (!reset && wr_en && !full) begin

            if (expected_queue.size() >= DEPTH) begin
                $display("ERROR @ %0t: DUT accepted write while model full",
                         $time);
                errors = errors + 1;
            end
            else begin
                expected_queue.push_back(wr_data);
                writes = writes + 1;
            end
        end
    end

    // ------------------------------------------------------------
    // Monitor successful reads
    // ------------------------------------------------------------

    always @(posedge rd_clk) begin
        if (!reset && rd_en && !empty) begin

            // rd_data is registered in the DUT, so wait for NBA update
            #1;

            if (expected_queue.size() == 0) begin
                $display("ERROR @ %0t: DUT accepted read with empty model",
                         $time);
                errors = errors + 1;
            end
            else if (rd_data !== expected_queue[0]) begin
                $display("ERROR @ %0t: DATA MISMATCH: expected=%h got=%h",
                         $time, expected_queue[0], rd_data);
                errors = errors + 1;
                expected_queue.pop_front();
                reads = reads + 1;
            end
            else begin
                $display("READ  @ %0t: %h", $time, rd_data);
                expected_queue.pop_front();
                reads = reads + 1;
            end
        end
    end

    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------

    initial begin
        reset   = 1;
        wr_en   = 0;
        rd_en   = 0;
        wr_data = 0;

        errors = 0;
        writes = 0;
        reads  = 0;

        // Reset
        #25;
        reset = 0;

        repeat (3) @(posedge rd_clk);

        if (!empty) begin
            $display("ERROR: FIFO not empty after reset");
            errors = errors + 1;
        end

        // --------------------------------------------------------
        // Directed test: fill FIFO
        // --------------------------------------------------------

        $display("\n--- FILL TEST ---");

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge wr_clk);
            wr_en   = 1;
            wr_data = 8'hA0 + i;
        end

        @(negedge wr_clk);
        wr_en = 0;

        // Allow synchronized pointer to reach write domain
        repeat (3) @(posedge wr_clk);

        if (!full) begin
            $display("ERROR: FIFO did not become full");
            errors = errors + 1;
        end
        else
            $display("PASS: FIFO full");

        // --------------------------------------------------------
        // Directed overflow attempt
        // --------------------------------------------------------

        @(negedge wr_clk);
        wr_en   = 1;
        wr_data = 8'hFF;

        @(negedge wr_clk);
        wr_en = 0;

        // --------------------------------------------------------
        // Drain FIFO
        // --------------------------------------------------------

        $display("\n--- DRAIN TEST ---");

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge rd_clk);
            rd_en = 1;
        end

        @(negedge rd_clk);
        rd_en = 0;

        repeat (3) @(posedge rd_clk);

        if (!empty) begin
            $display("ERROR: FIFO did not become empty");
            errors = errors + 1;
        end
        else
            $display("PASS: FIFO empty");

        // --------------------------------------------------------
        // Randomized asynchronous operation
        // --------------------------------------------------------

        $display("\n--- RANDOM TEST ---");

        fork

            begin
                repeat (500) begin
                    @(negedge wr_clk);
                    wr_en   = $urandom_range(0,1);
                    wr_data = $urandom;
                end

                @(negedge wr_clk);
                wr_en = 0;
            end

            begin
                repeat (500) begin
                    @(negedge rd_clk);
                    rd_en = $urandom_range(0,1);
                end

                @(negedge rd_clk);
                rd_en = 0;
            end

        join

        // Allow outstanding transactions / synchronized pointers
        repeat (10) @(posedge rd_clk);
        repeat (10) @(posedge wr_clk);

        // Stop new traffic
        wr_en = 0;
        rd_en = 0;

        // Drain anything remaining in the model
        while (expected_queue.size() != 0) begin
            @(negedge rd_clk);
            rd_en = 1;
        end

        @(negedge rd_clk);
        rd_en = 0;

        repeat (5) @(posedge rd_clk);

        // --------------------------------------------------------
        // Result
        // --------------------------------------------------------

        $display("\n======================================");
        $display("ASYNC FIFO TEST COMPLETE");
        $display("Successful writes : %0d", writes);
        $display("Successful reads  : %0d", reads);
        $display("Remaining model   : %0d", expected_queue.size());
        $display("Errors            : %0d", errors);
        $display("======================================");

        if (errors == 0 && expected_queue.size() == 0)
            $display("***** TEST PASSED *****");
        else
            $display("***** TEST FAILED *****");

        #20;
        $finish;
    end

    // ------------------------------------------------------------
    // Waveform
    // ------------------------------------------------------------

    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
    end

endmodule

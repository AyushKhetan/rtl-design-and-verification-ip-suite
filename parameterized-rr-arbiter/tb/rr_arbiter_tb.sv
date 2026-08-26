`timescale 1ns/1ps

module rr_arbiter_tb;

    localparam int N = 8;

    logic         clk;
    logic         reset;
    logic [N-1:0] req;
    logic [N-1:0] grant;

    rr_arbiter #(
        .N(N)
    ) dut (
        .clk   (clk),
        .reset (reset),
        .req   (req),
        .grant (grant)
    );

    // 10 ns clock
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        req   = 0;

        // Reset
        #12;
        reset = 0;

        // -------------------------------------------------
        // Test 1: single requester
        // -------------------------------------------------
        req = 8'b00000100;       // requester 2
        #2;
        $display("T1 req=%b grant=%b", req, grant);
        assert(grant == 8'b00000100);

        @(posedge clk);
        #1;

        // -------------------------------------------------
        // Test 2: multiple requesters
        // Current priority should now be requester 3.
        // Requests: 1, 3, 5
        // Therefore requester 3 wins.
        // -------------------------------------------------
        req = 8'b00101010;
        #2;
        $display("T2 req=%b grant=%b", req, grant);
        assert(grant == 8'b00001000);

        @(posedge clk);
        #1;

        // Priority is now requester 4.
        // Same requests: 1, 3, 5
        // Therefore requester 5 wins.
        #2;
        $display("T3 req=%b grant=%b", req, grant);
        assert(grant == 8'b00100000);

        @(posedge clk);
        #1;

        // Priority is now requester 6.
        // Same requests: 1, 3, 5
        // Wrap around -> requester 1 wins.
        #2;
        $display("T4 req=%b grant=%b", req, grant);
        assert(grant == 8'b00000010);

        @(posedge clk);
        #1;

        // -------------------------------------------------
        // Test 5: no requests
        // -------------------------------------------------
        req = 0;
        #2;
        $display("T5 req=%b grant=%b", req, grant);
        assert(grant == 0);

        $display("================================");
        $display("ALL TESTS PASSED");
        $display("================================");

        $finish;
    end

endmodule
module rr_arbiter_formal;

    localparam int N = 8;

    logic        clk;
    logic        reset;
    logic [N-1:0] req;
    logic [N-1:0] grant;

    rr_arbiter #(.N(N))
    dut(
        .clk(clk),
        .reset(reset),
        .req(req),
        .grant(grant)
    );



    // ---------------------------------------------------------
    // Reference round-robin model
    // ---------------------------------------------------------

    logic [N-1:0] expected_grant;
    logic [N-1:0] prio;

    integer k;
    integer i;
    integer start_idx;
    integer offset;
    integer idx;

    assign prio = dut.prio;

    always_comb begin
        expected_grant = '0;
        start_idx      = 0;

        // Decode one-hot priority into its requester index
        for (k = 0; k < N; k = k + 1) begin
            if (prio[k])
                start_idx = k;
        end

        // Scan cyclically from the current priority
        for (offset = 0; offset < N; offset = offset + 1) begin
            idx = start_idx + offset;

            if (idx >= N)
                idx = idx - N;

            if ((expected_grant == '0) && req[idx])
                expected_grant[idx] = 1'b1;
        end
    end

    logic [N-1:0] expected_next_prio;

    always_comb begin
        expected_next_prio = prio;

        for (i = 0; i < N; i = i + 1) begin
            if (grant[i]) begin
                expected_next_prio = '0;

                if (i == N-1)
                    expected_next_prio[0] = 1'b1;
                else
                    expected_next_prio[i+1] = 1'b1;
            end
        end
    end
    

    /*assert property (@(posedge clk) $onehot0(grant));

    assert property (
        @(posedge clk)
        (grant & ~req) == '0
        );

    assert property (
        @(posedge clk) 
        |req |-> |grant
        );

    assert property (
        @(posedge clk)
        reset |-> (prio == N'b1)
        );*/

    assert property (
        @(posedge clk)
        grant == expected_grant
        );

    /*assert property(
         @(posedge clk)
        dut.prio == $past(expected_next_prio)
        );       

    assert property (
        @(posedge clk)
        $onehot(prio)
        );*/
endmodule
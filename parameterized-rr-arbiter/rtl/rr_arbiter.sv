module rr_arbiter #(
    parameter int N = 4
)(
    input  logic         clk,
    input  logic         reset,
    input  logic [N-1:0] req,
    output logic [N-1:0] grant
);


    logic [N-1:0] prio;
    logic [N-1:0] next_prio;

    // Your combinational logic here:
    // 1. circularly rotate req
    // 2. isolate lowest set bit
    // 3. rotate grant back
    // 4. determine next priority

    logic [N-1:0] circ;
    logic [N-1:0] grant_circ;

    logic [N-1:0] ror1, ror2, ror4;
    logic rotate1, rotate2, rotate4;
    logic [N-1:0] stage1, stage2;

    logic [N-1:0] rol1, rol2, rol4;
    logic roll1, roll2, roll4;
    logic [N-1:0] stage3, stage4;

    assign rotate1 = prio[1] | prio[3] | prio[5] | prio[7];
    assign rotate2 = prio[2] | prio[3] | prio[6] | prio[7];
    assign rotate4 = prio[4] | prio[5] | prio[6] | prio[7];

    assign ror1 = (req >> 1) | (req << (N - 1));
    assign stage1 = rotate1 ? ror1 : req;

    assign ror2 = (stage1 >> 2) | (stage1 << (N - 2));
    assign stage2 = rotate2 ? ror2 : stage1;

    assign ror4 = (stage2 >> 4) | (stage2 << (N - 4));
    assign circ = rotate4 ? ror4 : stage2;

    // Isolate lowest set bit
    // This is a common trick to isolate the lowest set bit in a binary number.
    assign grant_circ = circ & -circ;


    assign rol1 = (grant_circ << 1) | (grant_circ >> (N - 1));
    assign stage3 = rotate1 ? rol1 : grant_circ;

    assign rol2 = (stage3 << 2) | (stage3 >> (N - 2));
    assign stage4 = rotate2 ? rol2 : stage3;

    assign rol4 = (stage4 << 4) | (stage4 >> (N - 4));
    assign grant = rotate4 ? rol4 : stage4;

    assign next_prio = (grant == 0) ? prio : (grant << 1) | grant[N-1];

    // Sequential priority register here.
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            prio <= {{(N-1){1'b0}}, 1'b1};
        end else begin
            prio <= next_prio;
        end
    end





    `ifdef FORMAL

    // =========================================================
    // FORMAL REFERENCE MODEL
    // =========================================================

    logic [N-1:0] expected_grant;

    integer fk;
    integer fstart;
    integer foffset;
    integer fidx;

    always @* begin
        expected_grant = '0;
        fstart = 0;

        for (fk = 0; fk < N; fk = fk + 1) begin
            if (prio[fk])
                fstart = fk;
        end

        for (foffset = 0; foffset < N; foffset = foffset + 1) begin
            fidx = fstart + foffset;

            if (fidx >= N)
                fidx = fidx - N;

            if ((expected_grant == '0) && req[fidx])
                expected_grant[fidx] = 1'b1;
        end
    end


    logic [N-1:0] expected_next_prio;

    integer pi;

    always @* begin
        expected_next_prio = prio;

        for (pi = 0; pi < N; pi = pi + 1) begin
            if (grant[pi]) begin
                expected_next_prio = '0;

                if (pi == N-1)
                    expected_next_prio[0] = 1'b1;
                else
                    expected_next_prio[pi+1] = 1'b1;
            end
        end
    end


    logic [N-1:0] expected_prio_d;
    logic          formal_valid;

    always @(posedge clk) begin
        if (reset) begin
            expected_prio_d <= '0;
            formal_valid    <= 1'b0;
        end
        else begin
            expected_prio_d <= expected_next_prio;
            formal_valid    <= 1'b1;
        end
    end

    // =========================================================
    // RESET ASSUMPTION
    // =========================================================

    initial assume(reset);


    // =========================================================
    // ASSERTIONS
    // =========================================================

    always @(posedge clk) begin
        if (!reset)
            assert($onehot(prio));
    end

    always @(posedge clk) begin
        if (!reset)
            assert(grant == expected_grant);
    end

    always @(posedge clk) begin
        if (!reset)
            assert($onehot0(grant));
    end

    always @(posedge clk) begin
        if (!reset)
            assert((grant & ~req) == '0);
    end

    always @(posedge clk) begin
    if (!reset && formal_valid)
        assert(prio == expected_prio_d);
    end

`endif

endmodule
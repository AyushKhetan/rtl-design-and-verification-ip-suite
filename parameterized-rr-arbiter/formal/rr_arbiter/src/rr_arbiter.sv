module rr_arbiter #(
    parameter int N = 8
)(
    input  logic         clk,
    input  logic         reset,
    input  logic [N-1:0] req,
    output logic [N-1:0] grant
);

    // Parameters

    localparam  int INDEX_W = (N <= 1) ? 1 : $clog2(N);
    localparam int COUNT_W = (N <= 1) ? 1 : $clog2(N + 1);

    logic [N-1:0] prio;
    logic [N-1:0] next_prio;

    logic [N-1:0] grant_circ;

    logic [N-1:0] ror_stage [0:INDEX_W];

    logic [N-1:0] index_mask;

    assign index_mask = ~prio & (prio - 1'b1);

    localparam int LEVELS = (N <= 1) ? 0 : $clog2(N);

    logic [COUNT_W-1:0] pop_tree [0:LEVELS][0:N-1];
    logic [INDEX_W-1:0] index;

    genvar l, j;

    generate

        // Level 0: individual bits
        for (j = 0; j < N; j = j + 1) begin : GEN_POP_INPUT
            assign pop_tree[0][j] = {{(COUNT_W-1){1'b0}}, index_mask[j]};
        end

        // Successive adder levels
        for (l = 0; l < LEVELS; l = l + 1) begin : GEN_POP_LEVEL

            for (j = 0; j < N; j = j + 1) begin : GEN_POP_NODE

                if ((2*j + 1) < ((N + (1 << l) - 1) >> l)) begin

                    assign pop_tree[l+1][j] = pop_tree[l][2*j] + pop_tree[l][2*j+1];

                end
                else if (j < ((N + (1 << l) - 1) >> (l+1))) begin

                    assign pop_tree[l+1][j] = pop_tree[l][2*j];

                end
                else begin

                    assign pop_tree[l+1][j] = '0;

                end

            end
        end

    endgenerate

    assign index = pop_tree[LEVELS][0];

    assign ror_stage [0] = req;

    genvar k;
    generate
        for(k=0; k < INDEX_W; k=k+1) begin: GEN_ROR
            localparam  int SHIFT = 1 << k;

            if (SHIFT < N) begin
                assign ror_stage[k+1] = index[k]? ((ror_stage[k] >> SHIFT) | (ror_stage[k] << (N-SHIFT))): ror_stage[k];
            end
            else begin
                assign ror_stage[k+1] = ror_stage[k];
            end
        end
    endgenerate


    // Isolate lowest set bit
    // This is a common trick to isolate the lowest set bit in a binary number.
    assign grant_circ = ror_stage[INDEX_W] & -ror_stage[INDEX_W];


    logic [N-1:0] rol_stage [0:INDEX_W];

    assign rol_stage[0] = grant_circ;

    generate
        for (k = 0; k < INDEX_W; k = k + 1) begin : GEN_ROL
            localparam int SHIFT = 1 << k;

            if (SHIFT < N) begin
                assign rol_stage[k+1] =
                    index[k]? ((rol_stage[k] << SHIFT) | (rol_stage[k] >> (N - SHIFT))): rol_stage[k];
            end
            else begin
                assign rol_stage[k+1] = rol_stage[k];
            end
        end
    endgenerate

    assign grant = rol_stage[INDEX_W];

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

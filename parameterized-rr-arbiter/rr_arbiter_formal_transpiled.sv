module rr_arbiter #(
    parameter int N = 8
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
endmodule

    // === TRANSPILED SVA CHECKERS ===
    // Antecedent logic
    // --- Assertion 1 (assert_1) ---
    // Type: ASSERT
    logic _a1_lhs_s0_pass;
    logic _a1_lhs_final;
    logic _a1_rhs_final_pass;
    assign _a1_lhs_s0_pass = (1'b1 && 1);
    assign _a1_lhs_final = _a1_lhs_s0_pass;

    // Consequent logic
    logic _a1_rhs_expr_0;
    logic [0:0] [0:0] _a1_rhs_vec_0;
    logic _a1_rhs_fail_0;
    logic _a1_rhs_pass;

    assign _a1_rhs_expr_0 = (grant == expected_grant);
    assign _a1_rhs_vec_0 = _a1_rhs_expr_0;

    // --- Z-Node Lookback Logic for Stage 0 ---
    // 1. Z-Nodes tree (Bottom-Up)
    logic _a1_lb_z_0_s0;
    assign _a1_lb_z_0_s0 = _a1_rhs_vec_0[0];
    // 2. Final Aggregation for Stage 0
    logic _a1_lb_agg_final_0;
    assign _a1_lb_agg_final_0 = _a1_lb_z_0_s0;
    // 3. Match and Fail pipeline
    logic _a1_match_0;
    assign _a1_match_0 = _a1_lhs_final && _a1_lb_agg_final_0;
    assign _a1_rhs_fail_0 = _a1_lhs_final && !_a1_lb_agg_final_0;
    assign _a1_rhs_pass = _a1_match_0;

    assign _a1_rhs_final_pass = _a1_rhs_pass;

    // --- Final Assertion Checks ---
    always_ff @(posedge clk) begin
        begin
            if (_a1_rhs_fail_0) assert_1: assert(0);
        end
    end

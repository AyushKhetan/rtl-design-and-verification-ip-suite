module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 3
)(
    input logic wr_clk,
    input logic rd_clk,
    input logic reset,

    input logic wr_en,
    input logic [DATA_WIDTH-1:0] wr_data,
    output logic full,

    input logic rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic empty
);

parameter DEPTH = 2**ADDR_WIDTH;
parameter PTR_WIDTH = ADDR_WIDTH + 1;

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

logic wr_rst_int;
logic wr_rst;

logic write_fire;
assign write_fire = wr_en && !full;
logic [PTR_WIDTH-1:0] wr_ptr;
logic [PTR_WIDTH-1:0] wr_ptr_nxt;
logic [PTR_WIDTH-1:0] wr_ptr_gray;
logic [PTR_WIDTH-1:0] wr_ptr_gray_nxt;
logic [PTR_WIDTH-1:0] wr_ptr_gray_immSync;
logic [PTR_WIDTH-1:0] wr_ptr_gray_sync;


logic rd_rst_int;
logic rd_rst;

logic read_fire;

logic [PTR_WIDTH-1:0] rd_ptr;
logic [PTR_WIDTH-1:0] rd_ptr_nxt;
logic [PTR_WIDTH-1:0] rd_ptr_gray;
logic [PTR_WIDTH-1:0] rd_ptr_gray_nxt;
logic [PTR_WIDTH-1:0] rd_ptr_gray_immSync;
logic [PTR_WIDTH-1:0] rd_ptr_gray_sync;

assign wr_ptr_nxt = wr_ptr + write_fire;
assign wr_ptr_gray_nxt = wr_ptr_nxt ^ (wr_ptr_nxt >> 1);

always@(posedge wr_clk or posedge reset) begin
    if(reset) begin
        wr_rst <= 1;
        wr_rst_int <= 1;
    end
    else begin
        wr_rst_int <= 0;
        wr_rst <= wr_rst_int;
    end
end

always @(posedge wr_clk or posedge wr_rst) begin
    if (wr_rst) begin
        wr_ptr <= 0;
        wr_ptr_gray <= 0;
        full <= 0;
    end
    else begin
        if (write_fire)
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
        wr_ptr <= wr_ptr_nxt;
        wr_ptr_gray <= wr_ptr_gray_nxt;
        full <= (wr_ptr_gray_nxt == ({~rd_ptr_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2], rd_ptr_gray_sync[PTR_WIDTH-3:0]}));
    end
end


assign read_fire = rd_en && !empty;


assign rd_ptr_nxt = rd_ptr + read_fire;
assign rd_ptr_gray_nxt = rd_ptr_nxt ^ (rd_ptr_nxt >> 1);


always@(posedge rd_clk or posedge reset) begin
    if(reset) begin
        rd_rst <= 1;
        rd_rst_int <= 1;
    end
    else begin
        rd_rst_int <= 0;
        rd_rst <= rd_rst_int;
    end
end

always @(posedge rd_clk or posedge rd_rst) begin
    if (rd_rst) begin
        rd_ptr <= 0;
        rd_ptr_gray <= 0;
        rd_data <= 0;
        empty <= 1;
    end
    else begin
        if(read_fire)
            rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        rd_ptr <= rd_ptr_nxt;
        rd_ptr_gray <= rd_ptr_gray_nxt;
        empty <= (rd_ptr_gray_nxt == wr_ptr_gray_sync);
    end
end

always @(posedge rd_clk or posedge rd_rst) begin
    if (rd_rst) begin
        wr_ptr_gray_immSync <= 0;
        wr_ptr_gray_sync <=0;
    end
    else begin
        wr_ptr_gray_immSync <= wr_ptr_gray;
        wr_ptr_gray_sync <= wr_ptr_gray_immSync;
    end
end

always @(posedge wr_clk or posedge wr_rst) begin
    if (wr_rst) begin
        rd_ptr_gray_immSync <= 0;
        rd_ptr_gray_sync <= 0;
    end
    else begin
        rd_ptr_gray_immSync <= rd_ptr_gray;
        rd_ptr_gray_sync <= rd_ptr_gray_immSync;
    end
end


`ifdef FORMAL


    // ------------------------------------------------------------
    // Binary pointer advancement
    // ------------------------------------------------------------


// [SVA-DISABLED]     assert property (
// [SVA-DISABLED]     @(posedge wr_clk)
// [SVA-DISABLED]     full |-> !write_fire
// [SVA-DISABLED] );

// [SVA-DISABLED] assert property (
// [SVA-DISABLED]     @(posedge rd_clk)
// [SVA-DISABLED]     empty |-> !read_fire
// [SVA-DISABLED] );

`endif


    // === TRANSPILED SVA CHECKERS ===
    // Antecedent logic
    // --- Assertion 1 (assert_1) ---
    // Type: ASSERT
    logic _a1_lhs_s0_pass;
    logic _a1_lhs_final;
    logic _a1_rhs_final_pass;
    assign _a1_lhs_s0_pass = (1'b1 && full);
    assign _a1_lhs_final = _a1_lhs_s0_pass;

    // Consequent logic
    logic _a1_rhs_expr_0;
    logic [0:0] [0:0] _a1_rhs_vec_0;
    logic _a1_rhs_fail_0;
    logic _a1_rhs_pass;

    assign _a1_rhs_expr_0 = !write_fire;
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
    always_ff @(posedge wr_clk) begin
        begin
            if (_a1_rhs_fail_0) assert_1: assert(0);
        end
    end

    // Antecedent logic
    // --- Assertion 2 (assert_2) ---
    // Type: ASSERT
    logic _a2_lhs_s0_pass;
    logic _a2_lhs_final;
    logic _a2_rhs_final_pass;
    assign _a2_lhs_s0_pass = (1'b1 && empty);
    assign _a2_lhs_final = _a2_lhs_s0_pass;

    // Consequent logic
    logic _a2_rhs_expr_0;
    logic [0:0] [0:0] _a2_rhs_vec_0;
    logic _a2_rhs_fail_0;
    logic _a2_rhs_pass;

    assign _a2_rhs_expr_0 = !read_fire;
    assign _a2_rhs_vec_0 = _a2_rhs_expr_0;

    // --- Z-Node Lookback Logic for Stage 0 ---
    // 1. Z-Nodes tree (Bottom-Up)
    logic _a2_lb_z_0_s0;
    assign _a2_lb_z_0_s0 = _a2_rhs_vec_0[0];
    // 2. Final Aggregation for Stage 0
    logic _a2_lb_agg_final_0;
    assign _a2_lb_agg_final_0 = _a2_lb_z_0_s0;
    // 3. Match and Fail pipeline
    logic _a2_match_0;
    assign _a2_match_0 = _a2_lhs_final && _a2_lb_agg_final_0;
    assign _a2_rhs_fail_0 = _a2_lhs_final && !_a2_lb_agg_final_0;
    assign _a2_rhs_pass = _a2_match_0;

    assign _a2_rhs_final_pass = _a2_rhs_pass;

    // --- Final Assertion Checks ---
    always_ff @(posedge rd_clk) begin
        begin
            if (_a2_rhs_fail_0) assert_2: assert(0);
        end
    end

endmodule

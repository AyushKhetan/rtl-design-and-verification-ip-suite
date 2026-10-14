module uart_tx #(
    parameter int CLK_FREQ  = 50_000_000,
    parameter int BAUD_RATE = 115_200
)(
    input  logic       clk,
    input  logic       reset,

    input  logic [7:0] data_in,
    input  logic       start,

    output logic       tx,
    output logic       busy
);

localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam int BAUD_COUNT_WIDTH = $clog2(CLKS_PER_BIT);

typedef enum logic [1:0] {
    IDLE,
    START,
    TRANSMIT,
    STOP
} state_t;

state_t state;
logic [7:0] tx_shift;

logic [2:0] bit_count;
logic [BAUD_COUNT_WIDTH-1:0] baud_count;
logic baud_tick;

assign baud_tick = (state != IDLE) && (baud_count == CLKS_PER_BIT - 1);

always @(posedge clk or posedge reset) begin
    if(reset) begin
        baud_count <= 0;
    end
    else begin
        if (state == IDLE) begin
            baud_count <= 0;
        end
        else if (baud_tick) begin
            baud_count <= 0;
        end
        else begin
            baud_count <= baud_count + 1;
        end
    end
end

assign busy = (state != IDLE);

assign tx = (state == IDLE)  ? 1'b1 :
            (state == START) ? 1'b0 :
            (state == STOP)  ? 1'b1 :
                               tx_shift[0];

always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        state <= IDLE;
        tx_shift <= 8'b0;
        bit_count <= 3'b0;
    end
    else begin
        case (state)
            IDLE: begin
                if (start) begin
                    state <= START;
                    tx_shift <= data_in;
                    bit_count <= 3'b0;
                end
            end
            START: begin
                if(baud_tick) begin
                    state <= TRANSMIT;
                end
            end
            TRANSMIT: begin
                if(baud_tick) begin
                    if(bit_count == 7) begin
                        state <= STOP;
                    end
                    else begin
                        state <= TRANSMIT;
                        bit_count <= bit_count + 1;
                    end
                    tx_shift <= tx_shift >> 1;
                end
            end
            STOP: begin
                if(baud_tick) begin
                    state <= IDLE;
                end
            end
        endcase
    end
end


endmodule

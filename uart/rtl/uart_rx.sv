module uart_rx #(
    parameter int CLK_FREQ  = 50_000_000,
    parameter int BAUD_RATE = 115_200
)(
    input logic clk,
    input logic reset,
    input logic rx,
    output logic [7:0] rx_data,
    output logic       rx_valid
);

localparam int CLKS_PER_SAMPLE = CLK_FREQ / (16 * BAUD_RATE);
localparam  int BAUD_COUNT_WIDTH = $clog2(CLKS_PER_SAMPLE);

logic rx_meta;
logic rx_sync;
logic old_sync;
logic falledge;

logic [BAUD_COUNT_WIDTH-1:0] baud_count;
logic [3:0] sample_count;
logic [2:0] bit_count;
logic sample_tick;


typedef enum logic [1:0] {
    IDLE,
    START_CHECK,
    RECEIVE,
    STOP_CHECK
} state_t;

state_t state;


always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        rx_meta <= 1'b0;
        rx_sync <= 1'b0;
        old_sync <= 1'b0;
    end
    else begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
        old_sync <= rx_sync;
    end
end

assign falledge = old_sync&(~rx_sync);

assign sample_tick = (baud_count==CLKS_PER_SAMPLE-1);

always_ff @( posedge clk or posedge reset ) begin
    if(reset) begin
        state <= IDLE;
        rx_valid <= 1'b0;
        rx_data <= 8'h00;
        baud_count <= 0;
        sample_count <= 0;
        bit_count <= 0;
    end
    else begin
        rx_valid <= 1'b0;
        case(state)
            IDLE: begin
                if(falledge) begin
                    state <= START_CHECK;
                    bit_count <= 0;
                    sample_count <= 0;
                    baud_count <= 0;
                    rx_valid <= 1'b0;
                end
            end
            START_CHECK: begin
                baud_count <= baud_count + 1;
                if(sample_tick) begin
                    if(sample_count == 7) begin
                        if(rx_sync == 0) begin
                            state <= RECEIVE;
                            sample_count <= 0;
                        end
                        else begin
                            state <= IDLE;
                        end
                    end
                    else begin
                        sample_count <= sample_count + 1;
                    end
                    baud_count <= 0;
                end
                rx_valid <= 1'b0;
            end
            RECEIVE: begin
                baud_count <= baud_count + 1;
                if(sample_tick) begin
                    if(sample_count == 15) begin
                        rx_data <= {rx_sync,{rx_data[7:1]}};
                        sample_count <= 0;
                        if(bit_count == 7) begin
                            state <= STOP_CHECK;
                        end
                        else begin
                            bit_count <= bit_count + 1;
                        end
                    end
                    else begin
                        sample_count <= sample_count + 1;
                    end
                    baud_count <= 0;
                end

                rx_valid <= 1'b0;
            end
            STOP_CHECK: begin
                baud_count <= baud_count + 1;
                if(sample_tick) begin
                    if(sample_count == 15) begin
                        if(rx_sync == 1) begin
                            rx_valid <= 1'b1;
                        end
                        state <= IDLE;
                    end
                    else begin
                        sample_count <= sample_count + 1;
                    end
                    baud_count <= 0;
                end
            end
        endcase
    end
end

endmodule

module spi_master #(
    parameter int CLK_FREQ = 50_000_000,
    parameter int SPI_FREQ = 1_000_000,
    parameter int CPOL = 0,
    parameter int CPHA = 0
)(
    input logic clk,
    input logic reset,

    input logic start,
    input logic [7:0] tx_data,

    output logic [7:0] rx_data,
    output logic busy,
    output logic done,

    output logic cs,
    output logic sclk,
    output logic mosi,
    input logic miso
);

localparam int CLKS_PER_HALF_SCLK = CLK_FREQ / (2 * SPI_FREQ);

localparam int CLK_COUNT_WIDTH = $clog2(CLKS_PER_HALF_SCLK);

logic [CLK_COUNT_WIDTH-1:0] clk_count;
logic                      sclk_tick;

logic [7:0] tx_shift;
logic [7:0] rx_shift;

logic [2:0] bit_count;

logic sample_edge;
logic change_edge;

assign sample_edge = ~(CPHA^CPOL);
assign change_edge = CPHA^CPOL;

typedef enum logic {
    IDLE,
    TRANSFER
} state_t;

state_t state;

always_ff @(posedge clk or posedge reset) begin
    if(reset || sclk_tick || (state == IDLE && start)) begin
        clk_count <= 0;
    end
    else begin
        clk_count <= clk_count + '1;
    end
end

assign sclk_tick = (clk_count == CLKS_PER_HALF_SCLK-1);

always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        sclk <= CPOL;
    end
    else if(sclk_tick && state!=IDLE) begin
        sclk <= ~sclk;
    end
end

always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        state <= IDLE;
        cs <= 1;
        busy <= 0;
        bit_count <= 0;
        done <= 0;
    end
    else begin
        done <= 0;
        case (state)
            IDLE: begin
                if(start) begin
                    state <= TRANSFER;
                    cs <= 0;
                    busy <= 1;
                    bit_count <= 0;
                    tx_shift <= tx_data;
                    rx_shift <= 0;

                    if(CPHA == 0)
                        mosi <= tx_data[7];
                end
            end
            TRANSFER: begin
                if(sclk_tick && (sclk!=sample_edge)) begin
                    rx_shift <= {rx_shift[6:0],miso};
                    if(CPHA) begin
                        bit_count <= bit_count + 1;
                        if(bit_count == 7) begin
                            state <= IDLE;
                            rx_data <= {rx_shift[6:0],miso};
                            cs <= 1;
                            busy <= 0;
                            done <= 1;
                        end
                    end
                end
                if(sclk_tick && (sclk!=change_edge)) begin
                    if (CPHA)
                        mosi <= tx_shift[7];
                    else
                        mosi <= tx_shift[6];

                    tx_shift <= tx_shift << 1;
                    if(!CPHA) begin
                        bit_count <= bit_count + 1;
                        if(bit_count == 7) begin
                            state <= IDLE;
                            rx_data <= rx_shift;
                            cs <= 1;
                            busy <= 0;
                            done <= 1;
                        end
                    end
                end
            end
        endcase
    end
end


endmodule

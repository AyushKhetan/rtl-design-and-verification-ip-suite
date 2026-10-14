
module uart_apb_top #(
    parameter int CLK_FREQ  = 50_000_000,
    parameter int BAUD_RATE = 115_200
) (
    input  logic       PCLK,
    input  logic       PRESETn,

    input  logic       PSEL,
    input  logic       PENABLE,
    input  logic       PWRITE,
    input  logic [7:0] PADDR,
    input  logic [7:0] PWDATA,

    output logic [7:0] PRDATA,
    output logic       PREADY,
    output logic       PSLVERR,

    input  logic       uart_rx_pin,
    output logic       uart_tx_pin
);

    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy;

    logic [7:0] rx_data;
    logic       rx_valid;

    apb_uart_regs u_regs (
        .PCLK(PCLK),
        .PRESETn(PRESETn),

        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),

        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),

        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),

        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_tx (
        .clk(PCLK),
        .reset(!PRESETn),
        .data_in(tx_data),
        .start(tx_start),
        .tx(uart_tx_pin),
        .busy(tx_busy)
    );

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_rx (
        .clk(PCLK),
        .reset(!PRESETn),
        .rx(uart_rx_pin),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

endmodule

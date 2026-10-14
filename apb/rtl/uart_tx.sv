module uart_tx #(
    parameter integer CLK_FREQ = 50_000_000,
    parameter integer BAUD_RATE = 9_600
) (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       tx_start,
    input  logic [7:0] tx_data,

    output logic       tx,
    output logic       busy,
    output logic       tx_done
);

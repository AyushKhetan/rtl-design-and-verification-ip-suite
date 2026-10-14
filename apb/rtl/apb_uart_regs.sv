module apb_uart_regs (
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

    output logic [7:0] tx_data,
    output logic       tx_start,
    input  logic       tx_busy,

    input  logic [7:0] rx_data,
    input  logic       rx_valid
);

    localparam logic [7:0] ADDR_CONTROL = 8'h00;
    localparam logic [7:0] ADDR_STATUS  = 8'h04;
    localparam logic [7:0] ADDR_TX_DATA = 8'h08;
    localparam logic [7:0] ADDR_RX_DATA = 8'h0C;

    logic [7:0] control_reg;
    logic [7:0] tx_data_reg;
    logic [7:0] rx_data_reg;
    logic       rx_available;

    logic access;
    logic write_transfer;
    logic read_transfer;
    logic bad_address;
    logic bad_busy_write;

    assign PREADY = 1'b1;
    assign access = PSEL && PENABLE;
    assign write_transfer = access && PWRITE && PREADY;
    assign read_transfer  = access && !PWRITE && PREADY;

    assign tx_data = tx_data_reg;

    always_comb begin
        bad_address = 1'b0;
        bad_busy_write = 1'b0;

        if (access && PWRITE) begin
            if ((PADDR != ADDR_CONTROL) &&
                (PADDR != ADDR_TX_DATA))
                bad_address = 1'b1;

            if ((PADDR == ADDR_TX_DATA) && tx_busy)
                bad_busy_write = 1'b1;
        end
        else if (access && !PWRITE) begin
            if ((PADDR != ADDR_CONTROL) &&
                (PADDR != ADDR_STATUS) &&
                (PADDR != ADDR_TX_DATA) &&
                (PADDR != ADDR_RX_DATA))
                bad_address = 1'b1;
        end

        PSLVERR = access && PREADY &&
                  (bad_address || bad_busy_write);
    end

    always_comb begin
        PRDATA = 8'h00;

        if (read_transfer) begin
            case (PADDR)
                ADDR_CONTROL: PRDATA = control_reg;
                ADDR_STATUS:  PRDATA = {6'b0, rx_available, tx_busy};
                ADDR_TX_DATA: PRDATA = tx_data_reg;
                ADDR_RX_DATA: PRDATA = rx_data_reg;
                default:      PRDATA = 8'h00;
            endcase
        end
    end

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            control_reg  <= 8'h00;
            tx_data_reg  <= 8'h00;
            rx_data_reg  <= 8'h00;
            rx_available <= 1'b0;
            tx_start     <= 1'b0;
        end
        else begin
            // Default to no new transmit request.
            tx_start <= 1'b0;

            // Capture received data and remember that it is available.
            if (rx_valid) begin
                rx_data_reg  <= rx_data;
                rx_available <= 1'b1;
            end

            if (read_transfer && !PSLVERR &&
                (PADDR == ADDR_RX_DATA))
                rx_available <= 1'b0;

            if (write_transfer && !PSLVERR) begin
                case (PADDR)
                    ADDR_CONTROL: begin
                        control_reg <= PWDATA;
                    end

                    ADDR_TX_DATA: begin
                        tx_data_reg <= PWDATA;
                        tx_start    <= 1'b1;
                    end

                    default: begin
                        // No state change for unsupported writes.
                    end
                endcase
            end
        end
    end

endmodule

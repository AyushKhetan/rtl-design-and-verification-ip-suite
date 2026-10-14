module dma_tb;

    logic        clk;
    logic        rst_n;
    logic        mmio_valid;
    logic        mmio_write;
    logic [31:0] mmio_addr;
    logic [31:0] mmio_wdata;
    logic [31:0] mmio_rdata;
    logic        mem_valid;
    logic        mem_write;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic        mem_ready;
    logic [31:0] mem_rdata;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end


    dma dut(
        .clk(clk),
        .rst_n(rst_n),
        .mmio_valid(mmio_valid),
        .mmio_write(mmio_write),
        .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata),
        .mmio_rdata(mmio_rdata),
        .mem_valid(mem_valid),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_ready(mem_ready),
        .mem_rdata(mem_rdata)
    );

    task mmio_write_reg(
        input logic [31:0] addr,
        input logic [31:0] data
    );
        begin
            mmio_addr  = addr;
            mmio_wdata = data;
            mmio_valid = 1'b1;
            mmio_write = 1'b1;

            @(posedge clk);

            mmio_valid = 1'b0;
            mmio_write = 1'b0;
        end
    endtask


    logic [31:0] mem [0:4095]; // 4KB memory - part of memory model

    initial begin
        rst_n = 0;
        mem[32'h1000 >> 2] = 32'hAAAA0001;
        mem[32'h1004 >> 2] = 32'hAAAA0002;
        mem[32'h1008 >> 2] = 32'hAAAA0003;
        mem[32'h100C >> 2] = 32'hAAAA0004;

        repeat (2) @(posedge clk);
        rst_n = 1;

        mmio_write_reg(32'h08, 32'h00001000); // Set source address
        mmio_write_reg(32'h0C, 32'h00002000); // Set destination address
        mmio_write_reg(32'h10, 32'h00000004); // Set length
        mmio_write_reg(32'h00, 32'h00000001); // Start

        wait(dut.dma_done);
        @(posedge clk);

        if ((mem[32'h2000 >> 2] == 32'hAAAA0001) && (mem[32'h2004 >> 2] == 32'hAAAA0002) && (mem[32'h2008 >> 2] == 32'hAAAA0003) && (mem[32'h200C >> 2] == 32'hAAAA0004))
            $display("PASS: DMA transferred 4 words of data correctly with memory delay");
        else
            $display("FAIL: DMA data mismatch");

        $finish;
    end



    always_comb begin       //memory model
        mem_ready = 1'b0;
        mem_rdata = 32'h0;

        if (mem_valid) begin
            mem_ready = 1'b1;

            if (!mem_write)
                mem_rdata = mem[mem_addr >> 2];
        end
    end

    always_ff @(posedge clk) begin
        if (mem_valid && mem_write)
            mem[mem_addr >> 2] <= mem_wdata;
    end

endmodule

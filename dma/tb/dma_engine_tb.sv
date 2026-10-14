module dma_engine_tb;

    logic        clk;
    logic        rst_n;

    logic        dma_start;
    logic [31:0] src_addr;
    logic [31:0] dst_addr;
    logic [31:0] length;

    logic        dma_busy;
    logic        dma_done;

    logic        mem_valid;
    logic        mem_write;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic        mem_ready;

    logic [31:0] mem [0:4095]; // 4KB memory

    logic [1:0] wait_count;

    dma_engine dut (
        .clk(clk),
        .rst_n(rst_n),

        .dma_start(dma_start),
        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .length(length),

        .dma_busy(dma_busy),
        .dma_done(dma_done),

        .mem_valid(mem_valid),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    initial begin
        rst_n = 0;

        mem[32'h1000 >> 2] = 32'hAAAA0001;
        mem[32'h1004 >> 2] = 32'hAAAA0002;
        mem[32'h1008 >> 2] = 32'hAAAA0003;
        mem[32'h100C >> 2] = 32'hAAAA0004;


        dma_start = 0;
        src_addr = 0;
        dst_addr = 0;
        length = 0;


        @(posedge clk);
        @(posedge clk);

        rst_n = 1;

        src_addr = 32'h1000;
        dst_addr = 32'h2000;
        length = 32'h4;

        dma_start = 1;
        @(posedge clk);
        dma_start = 0;

        @(posedge clk);
        @(posedge clk);

        dma_start = 1;
        @(posedge clk);
        dma_start = 0;

        wait(dma_done);
        @(posedge clk);

        if ((mem[32'h2000 >> 2] == 32'hAAAA0001) && (mem[32'h2004 >> 2] == 32'hAAAA0002) && (mem[32'h2008 >> 2] == 32'hAAAA0003) && (mem[32'h200C >> 2] == 32'hAAAA0004))
            $display("PASS: DMA transferred 0 words of data correctly with memory dly");
        else
            $display("FAIL: DMA data mismatch");

        $finish;
    end

    always @(posedge clk) begin
        if (mem_valid && !mem_write)
            $display("READ  addr = %h", mem_addr);

        if (mem_valid && mem_write)
            $display("WRITE addr = %h", mem_addr);

        if(!rst_n) begin
            wait_count <= 0;
            mem_ready <= 1'b0;
        end
        else begin
            mem_ready <= 1'b0;

            if(mem_valid) begin
                /*if(wait_count < 2) begin
                    wait_count <= wait_count + 1;
                end
                else begin
                    wait_count <= 0;
                    mem_ready <= 1'b1;*/
                    if(mem_write) begin
                        mem[mem_addr>>2] <= mem_wdata;
                    end
                    mem_ready <= 1'b1;
                end
            end
        end


    always_comb begin
        mem_rdata = 32'h0;
        if(mem_valid) begin
            if(!mem_write) begin
                mem_rdata = mem[mem_addr>>2];
            end
        end
    end
endmodule

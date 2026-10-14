module async_fifo_sva (
    ports
);


   always @(posedge clk or posedge reset) begin
    assert (wr_ptr_gray == wr_ptr^(wr_ptr>>1));

    if(!reset) begin
        if(write_fire)
        assert(wr_ptr == $past(wr_ptr)+1);
    end

    if(full) begin
        assert(write_fire==0);
    end
    else
   end

endmodule

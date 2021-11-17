`timescale 1ns / 1ps

`include "common.svh"

module render_fetch_tb;

    //initialize inputs and outputs
    logic clk, start;
    logic[10:0] hcount;
    logic[9:0] vcount;
    logic[LOG_BOARD_SIZE-1:0] view_x, view_y;
    logic[WORD_SIZE-1:0] data_r;
    logic[LOG_MAX_ADDR-1:0] addr_r;
    logic is_alive;
    
    //clock
    always #5 clk = !clk;
    
    render_fetch uut(.clk_in(clk),
                     .start_in(start),
                     .hcount_in(hcount),
                     .vcount_in(vcount),
                     .view_x_in(view_x),
                     .view_y_in(view_y),
                     .data_r_in(data_r),
                     .addr_r_out(addr_r),
                     .is_alive_out(is_alive));
                     
     initial begin
        clk = 0;
        start = 0;
        hcount = 0;
        vcount = 0;
        view_x = 0;
        view_y = 0;
        data_r = 16'b1100101001010000; //test data sample
        addr_r = 0;
        is_alive = 0;
        
        // Start test
        #10;
        start = 1;
        #10;
        start = 0;
        for (hcount = 0; hcount < SCREEN_WIDTH; hcount = hcount+1) #10;
        if ((hcount == 1023) && (vcount < SCREEN_HEIGHT)) begin
            hcount = 0;
            vcount = vcount + 1;
        end
        #10;
         
     end;
endmodule

`timescale 1ns / 1ps

`include "common.svh"

module cell_render_tb;
    logic clk;
    always #5 clk = !clk;

    //initialize input

    logic is_alive;
    logic[10:0] hcount;
    logic[9:0] vcount;
    
    //initialize output
    logic[11:0] pix;
    
    cell_render uut(.clk_in(clk),
                    .is_alive_in(is_alive),
                    .hcount_in(hcount),
                    .vcount_in(vcount),
                    .pix_out(pix));

    //initialize input
    initial begin
        clk = 0;
        is_alive = 0;
        hcount = 0;
        vcount = 0;
        pix = 0;
        
        // Test cell_render
        #10;
        for (vcount = 0; vcount < SCREEN_HEIGHT; vcount = vcount + 1) begin
            for (hcount = 0; hcount < SCREEN_WIDTH; hcount = hcount + 1) begin
                #10;
                is_alive = ~is_alive;
            end
        end
    end
    
endmodule

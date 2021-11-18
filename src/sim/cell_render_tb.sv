`timescale 1ns / 1ps

module cell_render_tb;

    //initialize input
    logic clk;
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
                    
    //clk
    always #10 clk = !clk;
    
    //initialize input
    initial begin
        clk = 0;
        is_alive = 1;
        hcount = 0;
        vcount = 0;
        pix = 0;
        #10;
        for (hcount = 0; hcount < SCREEN_WIDTH; hcount = hcount + 1) #10;
        if ((hcount == SCREEN_WIDTH) && (vcount < SCREEN_HEIGHT)) begin
            hcount = 0;
            vcount = vcount + 1;
        end
        #10;
        is_alive = 1;
        #20;
        is_alive = 0;
        #30;
        
    end
    
endmodule

`include "common.svh"

module stat_render_tb;


    //initialize inputs
    logic clk;
    logic rst;
    logic[10:0] hcount;
    logic[9:0] vcount;
    logic is_alive;
    logic[11:0] pix;

    // Helper
    logic[31:0] frame;
    
    //uut
    stat_render uut(.clk_130mhz(clk),
                    .rst_in(rst),
                    .hcount_in(hcount),
                    .vcount_in(vcount),
                    .is_alive_in(is_alive),
                    .pix_out(pix));
                    
    //clk
    always #10 clk = !clk;
    
    initial begin
        clk = 0;
        rst = 0;
        hcount = 0;
        vcount = 0;
        is_alive = 0;
        
        //start test
        #10;
        rst = 1;
        #10;
        rst = 0;
        for (frame = 0; frame < 64; frame++) begin
            for (vcount = 0; vcount < SCREEN_HEIGHT; vcount++) begin
                for (hcount = 0; hcount < SCREEN_WIDTH; hcount++) begin
                    #10;
                    is_alive = ~is_alive;
                end
            end
        end
    end

endmodule

`timescale 1ns / 1ps

module cursor_render_tb;
    localparam CELL_SIZE = BOARD_SIZE / VIEW_SIZE;
    logic clk;
    always #5 clk = !clk;

    // Input
    logic[10:0] hcount;
    logic[9:0] vcount;
    pos_t view_x, view_y, cursor_x, cursor_y;

    // Output
    logic[11:0] pix;

    cursor_render cr(.clk_in(clk), .hcount_in(hcount), .vcount_in(vcount),
                     .view_x_in(view_x), .view_y_in(view_y),
                     .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
                     .pix_out(pix));

    initial begin
        clk = 0;
        hcount = 0;
        vcount = 0;
        view_x = 2;
        view_y = 1;
        cursor_x = 3;
        cursor_y = 2;

        // Start test
        #20;
        for (integer j = 0; j < 768; j++) begin
            for (integer i = 0; i < 1024; i++) begin
                #10;
                hcount = i;
                vcount = j;
            end
        end
    end
endmodule

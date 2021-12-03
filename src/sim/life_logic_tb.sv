`timescale 1ns / 1ps

`include "common.svh"

module life_logic_tb;
    logic clk;
    always #5 clk = !clk;

    // Inputs
    logic rst, click;
    logic[LOG_MAX_SPEED-1:0] speed;
    pos_t cursor_x, cursor_y;
    hcount_t hcount_in;
    vcount_t vcount_in;
    logic alive_in, wr_en;

    // Outputs
    hcount_t hcount_out;
    vcount_t vcount_out;
    logic alive;

    life_logic uut(.clk_in(clk), .rst_in(rst), .alive_in(alive_in), .wr_en(wr_en),
                   .speed_in(speed), .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
                   .cursor_click_in(click), .hcount_in(hcount_in), .vcount_in(vcount_in),
                   .hcount_out(hcount_out), .vcount_out(vcount_out), .alive_out(alive));

    always_ff @(posedge clk) begin
        localparam HCOUNT_BP = 4, VCOUNT_BP = 4;
        if (rst) begin
            hcount_in <= 0;
            vcount_in <= 0;
        end else begin
            hcount_in <= hcount_in < SCREEN_WIDTH + HCOUNT_BP 
                       ? hcount_in + 1 : 0;
            vcount_in <= vcount_in < SCREEN_WIDTH + VCOUNT_BP
                       ? vcount_in + (hcount_in == SCREEN_WIDTH + HCOUNT_BP) : 0;
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        click = 0;
        speed = 0;
        cursor_x = 0;
        cursor_y = 0;
        alive_in = 0;
        wr_en = 0;

        // Start test
        #20;
        rst = 0;
        click = 1;
        cursor_x = 1;
        cursor_y = 0;
        #10;
        #200;
        #10;
        alive_in = 1;
        wr_en = 1;
        #20;
        alive_in = 0;
        #10;
        alive_in = 1;
        #30;
        wr_en = 0;
        
        #150;
        alive_in = 0;
        wr_en = 1;
        #10;
        alive_in = 0;
        #10;
        alive_in = 1;
        #10;
        alive_in = 0;
        #10;
        alive_in = 1;
        #10;
        alive_in = 0;
        #10;
        wr_en = 0;
        #10;
    end
endmodule

`timescale 1ns / 1ps

`include "common.svh"

module life_logic_tb;
    logic clk;
    always #5 clk = !clk;

    // Inputs
    logic rst, start, click;
    logic[LOG_MAX_SPEED-1:0] speed;
    data_t data_r;
    pos_t cursor_x, cursor_y;

    // Outputs
    addr_t addr_r, addr_w;
    data_t data_w;
    logic wr_en, done;

    life_logic uut(.clk_in(clk), .rst_in(rst), .start_in(start),
                   .speed_in(speed), .data_r_in(data_r),
                   .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
                   .cursor_click_in(click), .addr_r_out(addr_r),
                   .addr_w_out(addr_w), .data_w_out(data_w),
                   .wr_en_out(wr_en), .done_out(done));

    logic[15:0] data[0:MAX_ADDR-1];

    always_ff @(posedge clk) begin
        data_r <= data[addr_r];
    end

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        click = 0;
        speed = 0;
        cursor_x = 0;
        cursor_y = 0;
        for (integer i = 0; i < MAX_ADDR; i++) begin
            data[i] = ~i;
        end
        
        // Start test
        #20;
        rst = 0;
        click = 1;
        cursor_x = 1;
        cursor_y = 0;
        start = 1;
        #10;
        start = 0;
        #100;
    end
endmodule

`timescale 1ns / 1ps

`include "common.svh"

module user_interface_tb;
    logic clk;
    always #5 clk = !clk;

    // Input
    logic rst;
    logic[15:0] sw;
    logic btnd, btnc, btnu, btnl, btnr;

    // Output
    logic click;
    speed_t speed;
    pos_t cursor_x, cursor_y, view_x, view_y;

    user_interface#(.LOG_DEBOUNCE_COUNT(1), .LOG_WAIT_COUNT(2))
        ui(.clk_in(clk), .rst_in(rst), .sw_in(sw), .btnd_in(btnd),
           .btnc_in(btnc), .btnu_in(btnu), .btnl_in(btnl), .btnr_in(btnr),
           .click_out(click), .speed_out(speed), .cursor_x_out(cursor_x),
           .cursor_y_out(cursor_y), .view_x_out(view_x), .view_y_out(view_y));

    initial begin
        #10;
        clk = 0;
        {btnd, btnc, btnu, btnl, btnr} = 5'b0;
        sw = 15'b0;
        rst = 1;
        #30;
        rst = 0;

        // Check speed
        #10;
        sw[2:0] = 3'b101;

        // Check moving cursor
        #30;
        btnd = 1;
        #30;
        btnd = 0;
        btnu = 1;
        #30;
        btnu = 0;
        btnr = 1;
        #30;
        btnr = 0;
        btnl = 1;
        #30;
        btnl = 0;

        // Check moving view
        for (integer i = 0; i < VIEW_SIZE; i++) begin
            #10;
            btnr = 1;
        end
        #10;
        btnr = 0;
    end

endmodule

`timescale 1ns / 1ps

`include "common.svh"

module logic_rule_tb;
    logic clk;
    always #5 clk = !clk;

    // Inputs
    logic stall_in;
    pos_t x, y, cursor_x, cursor_y;
    logic[WINDOW_WIDTH-1:0] window[2:0];
    logic click, update;

    // Output
    logic[NUM_PE-1:0] state;
    logic stall_out;

    logic_rule rule(.clk_in(clk), .stall_in(stall_in), .x_in(x), .y_in(y),
                    .window_in(window), .cursor_x_in(cursor_x),
                    .cursor_y_in(cursor_y), .cursor_click_in(click),
                    .update_in(update), .state_out(state), .stall_out(stall_out));

    initial begin
        #10;
        clk = 0;
        stall_in = 0;
        x = 0;
        y = 0;
        window = {0, 0, 0};
        cursor_x = 0;
        cursor_y = 0;
        click = 0;
        update = 0;

        // Test user input
        #15;
        x = 1;
        y = 1;
        cursor_x = 1;
        cursor_y = 1;
        click = 1;
        #10;
        window = {0, 3'b010, 0};
        #10
        cursor_x = 0;
        #10;
        click = 0;
        
        // Test rule
        #10;
        update = 1;
        window = {3'b111, 3'b010, 3'b111};
        #10;
        window = {3'b000, 3'b010, 3'b000};
        #10;
        window = {3'b111, 3'b010, 3'b000};
        #10;
        window = {3'b111, 3'b000, 3'b000};
        
        // Test stall
        #10;
        stall_in = 1;
        #10;
    end
endmodule

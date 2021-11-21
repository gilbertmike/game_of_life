`timescale 1ns / 1ps

`include "common.svh"

module logic_fetcher_tb;
    logic clk;
    always #5 clk = !clk;

    // Input
    logic start;
    data_t data_in;

    // Output
    window_row_t window[2:0];
    addr_t addr_out;
    pos_t x, y;
    logic stall;

    logic_fetcher fetcher(.clk_in(clk), .start_in(start), .data_in(data_in),
                          .window_out(window), .addr_out(addr_out), .x_out(x),
                          .y_out(y), .stall_out(stall));

    initial begin
        clk = 0;
        start = 0;
        data_in = 0;

        // Start fetching
        #20;
        start = 1;
        #10;
        start = 0;
        #200;
    end
endmodule

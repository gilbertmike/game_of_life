`timescale 1ns / 1ps

`include "common.svh"

`default_nettype none
module logic_writeback_tb;
    logic clk;
    always #5 clk = !clk;

    // Input
    logic stall, start;
    logic[NUM_PE-1:0] next_state;

    // Output
    logic wr_en;
    addr_t addr_w;
    data_t data_w;
    logic done;

    logic_writeback wb(.clk_in(clk), .stall_in(stall), .start_in(start),
                       .next_state_in(next_state), .wr_en_out(wr_en),
                       .addr_w_out(addr_w), .data_w_out(data_w),
                       .done_out(done));

    initial begin
        clk = 0;
        start = 0;
        stall = 0;
        next_state = 1'b0;

        // Start test
        #20;
        start = 1;
        next_state = 1'b1;
        #10;
        start = 0;
        next_state = 1'b1;
        for (integer i = 0; i < WORD_SIZE; i++) begin
            #10;
            next_state = !next_state;
        end

        // Test stall
        #10;
        stall = 1;
        next_state = 1'b0;
        #10;
        stall = 1;
        next_state = 1'b1;
        #10;
        stall = 0;
        next_state = 1'b1;
        for (integer i = 0; i < WORD_SIZE; i++) begin
            #10;
            next_state = !next_state;
        end
    end
endmodule
`default_nettype wire


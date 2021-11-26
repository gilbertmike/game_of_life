`timescale 1ns / 1ps

`include "common.svh"

module synchronizer_tb;
    
    //initialize inputs
    logic clk;
    logic rst;
    logic logic_done;
    logic render_done;
    logic buf_ready;

    //initialize outputs
    logic logic_start;
    logic buf_swap;

    //initialize uut
    synchronizer uut(.clk_in(clk),
                     .rst_in(rst),
                     .logic_done_in(logic_done),
                     .render_done_in(render_done),
                     .buf_ready_in(buf_ready),
                     .logic_start_out(logic_start),
                     .buf_swap_out(buf_swap));

    //clock
    always #5 clk = !clk;

    initial begin
        clk = 0;
        rst = 0;
        logic_done = 0;
        render_done = 0;
        buf_ready = 0;
        #5
        rst = 1;
        #5
        rst = 0;
        logic_done = 1;
        #5
        buf_ready = 1;
        #5
        buf_ready = 1;
        render_done = 1;
        #5
        buf_ready = 1;

    end
endmodule

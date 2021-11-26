`timescale 1ns / 1ps

`include "common.svh"

module double_buffer_tb;
    logic clk;
    always #5 clk = !clk;

    // Input
    addr_t logic_addr_r;
    addr_t logic_addr_w;
    data_t logic_data_w;
    logic logic_wr_en;
    addr_t render_addr_r;

    logic swap;
    logic rst;
    
    // Output
    data_t logic_data_r;
    data_t render_data_r;

    double_buffer db(.logic_addr_r(logic_addr_r), .logic_addr_w(logic_addr_w),
                     .logic_data_w(logic_data_w), .logic_wr_en(logic_wr_en),
                     .render_addr_r(render_addr_r), .swap_in(swap),
                     .rst_in(rst), .clk_in(clk), .logic_data_r(logic_data_r),
                     .render_data_r(render_data_r));

    initial begin
        #10;
        clk = 0;
        rst = 1;
        swap = 0;
        #50;
        rst = 0;

        // Logic stores data in address 0
        #10;
        logic_addr_w = 0;
        logic_data_w = 1;
        logic_wr_en = 1;

        logic_addr_r = 0;
        render_addr_r = 0;
        #10;
        logic_wr_en = 0;

        // Swap. Render and logic should be able to see the data
        #10;
        swap = 1;
        #10;
        swap = 0;
        render_addr_r = 0;
        logic_addr_r = 0;
        #10;
        render_addr_r = 1;
        #10;
        render_addr_r = 0;
        #10;
        assert(logic_data_r == 1);
        assert(render_data_r == 1);
    end
endmodule

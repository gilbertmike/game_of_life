`timescale 1ns / 1ps

`include "common.svh"

`default_nettype none
module double_buffer_top(input wire clk_100mhz, input wire[15:0] sw,
                         output logic[3:0] vga_r, vga_g, vga_b,
                         output logic vga_hs, vga_vs,
                         output logic[15:0] led);
    logic clk_130mhz, clk_65mhz;
    clk_wiz_130mhz wiz(.clk_in1(clk_100mhz), .clk_130mhz(clk_130mhz),
                       .clk_65mhz(clk_65mhz));

    data_t render_data_r, logic_data_r;
    logic db_ready;
    double_buffer db(
        .clk_130mhz(clk_65mhz), .rst_in(sw[15]), .swap_in(sw[14]),
        .render_addr_r(0),
        .logic_addr_r(0), .logic_addr_w(0),
        .logic_wr_en(sw[13]), .render_data_r(render_data_r),
        .logic_data_w(sw[7:0]), .logic_data_r(logic_data_r),
        .ready_out(db_ready));
    always_ff @(posedge clk_65mhz) begin
        led <= render_data_r;
    end
endmodule
`default_nettype wire
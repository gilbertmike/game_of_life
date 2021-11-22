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

    logic [10:0] hcount0;
    logic [9:0] vcount0;
    logic hsync0, vsync0, blank0;
    xvga xvga1(
        .clk_65mhz(clk_65mhz), .rst_in(sw[15]),
        .hcount_out(hcount0),
        .vcount_out(vcount0),
        .vsync_out(hsync0),
        .hsync_out(vsync0),
        .blank_out(blank0));

    always_ff @(posedge clk_65mhz) begin
//        if (render_data_r[hcount0[LOG_WORD_SIZE-1+3:3]]) begin
//            vga_r <= 4'hF;
//        end
//        if (logic_data_r[hcount0[LOG_WORD_SIZE-1+3:3]]) begin
//            vga_g <= 4'hF;
//        end
        vga_r <= 4'h0;
        vga_g <= 4'h0;
        vga_b <= blank0 ? 4'h0 : 4'hF;
        {vga_hs, vga_vs} <= {~hsync0, ~vsync0};
    end
endmodule
`default_nettype wire
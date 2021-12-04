
`include "common.svh"

`default_nettype none
module top_level#(parameter LOG_DEBOUNCE_COUNT=20,
                  parameter LOG_WAIT_COUNT=25)
                 (input wire clk_100mhz,
                  input wire btnc, btnu, btnl, btnr, btnd,
                  input wire[15:0] sw,
                  output logic[15:0] led,
                  output logic[3:0] vga_r, vga_g, vga_b,
                  output logic vga_hs, vga_vs,
                  output logic sd_reset, sd_cd, sd_sck, sd_cmd,
                  output logic[3:0] sd_dat);
    logic clk_25mhz;
    clk_wiz clk_gen(.reset(sw[15]), .clk_100_in(clk_100mhz),
                    .clk_25_out(clk_25mhz));

    logic [10:0] hcount;
    logic [9:0] vcount;
    logic hsync, vsync, blank;
    xvga xvga1(
        .vclk_in(clk_25mhz),
        .rst_in(sw[15]),
        .hcount_out(hcount),
        .vcount_out(vcount),
        .vsync_out(vsync),
        .hsync_out(hsync),
        .blank_out(blank));

    pos_t cursor_x, cursor_y, view_x, view_y;
    speed_t speed;
    logic click;
    hcount_t ui_hcount;
    vcount_t ui_vcount;
    logic ui_hsync, ui_vsync, ui_blank;
    user_interface#(LOG_DEBOUNCE_COUNT, LOG_WAIT_COUNT) ui(
        .clk_in(clk_25mhz), .rst_in(sw[15]),
        .btnd_in(btnd), .btnc_in(btnc), .btnl_in(btnl), .btnr_in(btnr),
        .btnu_in(btnu), .sw_in(sw),
        .hcount_in(hcount), .vcount_in(vcount), .vsync_in(vsync),
        .hsync_in(hsync), .blank_in(blank),
        .speed_out(speed), .cursor_x_out(cursor_x), .cursor_y_out(cursor_y),
        .click_out(click),
        .hcount_out(ui_hcount), .vcount_out(ui_vcount), .hsync_out(ui_hsync),
        .vsync_out(ui_vsync), .blank_out(ui_blank));

    hcount_t logic_hcount;
    vcount_t logic_vcount;
    logic cell_alive;
    logic logic_hsync, logic_vsync, logic_blank;
    life_logic life_logic(
        .clk_in(clk_25mhz), .rst_in(sw[15]), .speed_in(speed),
        .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
        .cursor_click_in(click),
        .alive_in(0), .wr_en(0),
        .hcount_in(ui_hcount), .vcount_in(ui_vcount), .vsync_in(ui_vsync),
        .hsync_in(ui_hsync), .blank_in(ui_blank),
        .hcount_out(logic_hcount), .vcount_out(logic_vcount),
        .hsync_out(logic_hsync), .vsync_out(logic_vsync),
        .blank_out(logic_blank),
        .alive_out(cell_alive));

    renderer renderer(
        .clk_in(clk_25mhz), .rst_in(sw[15]), .cell_alive_in(cell_alive),
        .hcount_in(logic_hcount), .vcount_in(logic_vcount),
        .hsync_in(logic_hsync), .vsync_in(logic_vsync), .blank_in(logic_blank),
        .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
        .pix_out({vga_r, vga_g, vga_b}), .vsync_out(vga_vs),
        .hsync_out(vga_hs));

    assign led[0] = click;
endmodule
`default_nettype wire

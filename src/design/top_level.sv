
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
                  output logic[3:0] sd_dat,
                  inout wire ps2_clk, ps2_data);
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
    logic[2:0] seed_idx;
    logic seed_en;
    logic click;
    vga_if vga_ui_seeder();
    user_interface#(LOG_DEBOUNCE_COUNT, LOG_WAIT_COUNT) ui(
        .clk_in(clk_25mhz), .rst_in(sw[15]),
        .btnd_in(btnd), .btnc_in(btnc), .btnl_in(btnl), .btnr_in(btnr),
        .btnu_in(btnu), .sw_in(sw),
        .hcount_in(hcount), .vcount_in(vcount), .vsync_in(vsync),
        .hsync_in(hsync), .blank_in(blank),
        .speed_out(speed), .cursor_x_out(cursor_x), .cursor_y_out(cursor_y),
        .click_out(click), .seed_idx_out(seed_idx), .seed_en_out(seed_en),
        .vga_out(vga_ui_seeder.src), .ps2_clk(ps2_clk), .ps2_data(ps2_data));

    logic seed_alive, seed_wr_en;
    vga_if vga_seeder_logic();
    seed_gen seeder(.clk_in(clk_25mhz), .rst_in(sw[15]), .idx_in(seed_idx),
                    .vga_in(vga_ui_seeder.dst), .en_in(seed_en),
                    .alive_out(seed_alive), .wr_en_out(seed_wr_en),
                    .vga_out(vga_seeder_logic.src));

    hcount_t logic_hcount;
    vcount_t logic_vcount;
    logic cell_alive;
    logic logic_hsync, logic_vsync, logic_blank;
    life_logic life_logic(
        .clk_in(clk_25mhz), .rst_in(sw[15]), .speed_in(speed),
        .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
        .cursor_click_in(click),
        .alive_in(seed_alive), .wr_en(seed_wr_en),
        .hcount_in(vga_seeder_logic.hcount), .vcount_in(vga_seeder_logic.vcount), .hsync_in(vga_seeder_logic.hsync),
        .vsync_in(vga_seeder_logic.vsync), .blank_in(vga_seeder_logic.blank),
        .hcount_out(logic_hcount), .vcount_out(logic_vcount),
        .hsync_out(logic_hsync), .vsync_out(logic_vsync),
        .blank_out(logic_blank),
        .alive_out(cell_alive));

    renderer renderer(
        .clk_in(clk_25mhz), .rst_in(sw[15]), .cell_alive_in(cell_alive),
        .hcount_in(logic_hcount), .vcount_in(logic_vcount),
        .hsync_in(logic_hsync), .vsync_in(logic_vsync), .blank_in(logic_blank),
        .cursor_x_in(cursor_x), .cursor_y_in(cursor_y), .seed_idx_in(seed_idx),
        .pix_out({vga_r, vga_g, vga_b}), .vsync_out(vga_vs),
        .hsync_out(vga_hs));

    assign led[0] = click;
endmodule
`default_nettype wire

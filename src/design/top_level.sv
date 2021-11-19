`default_nettype none
module top_level(input wire clk_100mhz,
                 input wire btnc, btnu, btnl, btnr, btnd,
                 input wire[15:0] sw,
                 output logic[3:0] vga_r, vga_g, vga_b,
                 output logic vga_hs, vga_vs);
    logic clk_130mhz;
    clk_wiz_130mhz(.clk_in1(clk_100mhz), .clk_out1(clk_130mhz));

    pos_t cursor_x, cursor_y, view_x, view_y;
    speed_t speed;
    logic click;
    user_interface ui(.clk_in(clk_130mhz), .btnd_in(btnd), .btnc_in(btnc),
                      .btnl_in(btnl), .btnr_in(btnr), .btnu_in(btnu),
                      .sw_in(sw), .speed_out(speed), .cursor_x_out(cursor_x),
                      .cursor_y_out(cursor_y), .click_out(click),
                      .view_x_out(view_x), .view_y_out(view_y));
    ila_0(.clk(clk_130mhz), .probe0(cursor_x), .probe1(cursor_y), .probe2(view_x),
          .probe3(view_y), .probe4({btnu, btnd, btnc, btnl, btnr}));

    logic logic_done, render_done;
    logic logic_start, render_start, buf_swap;
    synchronizer sync(.clk_in(clk_130mhz), .logic_done_in(logic_done),
                      .render_done_in(render_done),
                      .logic_start_out(logic_start),
                      .render_start_out(render_start),
                      .buf_swap_out(buf_swap));

    addr_t render_addr_r;
    data_t render_data_r;
    addr_t logic_addr_r, logic_addr_w;
    data_t logic_data_r, logic_data_w;
    logic logic_wr_en;
    
    double_buffer db(
        .clk_in(clk_130mhz), .swap_in(buf_swap), .render_addr_r(render_addr_r),
        .logic_addr_r(logic_addr_r), .logic_addr_w(logic_addr_w),
        .logic_wr_en(logic_wr_en), .render_data_r(render_data_r),
        .logic_data_w(logic_data_w), .logic_data_r(logic_data_r));

    renderer renderer(
        .clk_130mhz(clk_130mhz), .start_in(render_start),
        .data_in(render_data_r), .view_x_in(view_x), .view_y_in(view_y),
        .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
        .done_out(render_done), .addr_r_out(render_addr_r),
        .pix_out({vga_r, vga_g, vga_b}), .vsync_out(vga_vs),
        .hsync_out(vga_hs));

    life_logic life_logic(
        .clk_in(clk_130mhz), .start_in(logic_start), .speed_in(speed),
        .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
        .cursor_click_in(click), .data_r_in(logic_data_r),
        .addr_r_out(logic_addr_r), .addr_w_out(logic_addr_w),
        .wr_en_out(logic_wr_en), .data_w_out(logic_data_w),
        .done_out(logic_done));
endmodule
`default_nettype wire

`default_nettype none
module top_level#(parameter LOG_DEBOUNCE_COUNT=20,
                  parameter LOG_WAIT_COUNT=25)
                 (input wire clk_100mhz,
                  input wire btnc, btnu, btnl, btnr, btnd,
                  input wire[15:0] sw,
                  output logic[3:0] vga_r, vga_g, vga_b,
                  output logic vga_hs, vga_vs);
    logic clk_25mhz;
    clk_wiz clk_gen(.clk_100mhz(clk_100mhz), .clk_25mhz(clk_25mhz));

    logic logic_done, render_done, db_ready;
    logic logic_start, buf_swap;
    synchronizer sync(.clk_in(clk_25mhz), .rst_in(sw[15]),
                      .logic_done_in(logic_done),
                      .render_done_in(render_done),
                      .buf_ready_in(db_ready),
                      .logic_start_out(logic_start),
                      .buf_swap_out(buf_swap));

    pos_t cursor_x, cursor_y, view_x, view_y;
    speed_t speed;
    logic click, click0;
    user_interface#(LOG_DEBOUNCE_COUNT, LOG_WAIT_COUNT) ui(
        .clk_in(clk_100mhz), .rst_in(sw[15]), .logic_done_in(logic_done),
        .btnd_in(btnd), .btnc_in(btnc), .btnl_in(btnl), .btnr_in(btnr),
        .btnu_in(btnu), .sw_in(sw), .speed_out(speed), .cursor_x_out(cursor_x),
        .cursor_y_out(cursor_y), .click_out(click0), .view_x_out(view_x),
        .view_y_out(view_y));

    addr_t render_addr_r;
    data_t render_data_r;
    addr_t logic_addr_r, logic_addr_w;
    data_t logic_data_r, logic_data_w;
    logic logic_wr_en;
    assign click = 1;

    double_buffer db(
        .clk_in(clk_100mhz), .rst_in(sw[15]), .swap_in(buf_swap),
        .render_addr_r(render_addr_r),
        .logic_addr_r(logic_addr_r), .logic_addr_w(logic_addr_w),
        .logic_wr_en(logic_wr_en), .render_data_r(render_data_r),
        .logic_data_w(logic_data_w), .logic_data_r(logic_data_r),
        .ready_out(db_ready));

    renderer renderer(
        .clk_in(clk_100mhz), .vclk_in(clk_25mhz), .rst_in(sw[15]),
        .data_in(render_data_r), .view_x_in(view_x), .view_y_in(view_y),
        .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
        .done_out(render_done), .addr_r_out(render_addr_r),
        .pix_out({vga_r, vga_g, vga_b}), .vsync_out(vga_vs),
        .hsync_out(vga_hs));

    life_logic life_logic(
        .clk_in(clk_100mhz), .rst_in(sw[15]), .start_in(logic_start),
        .speed_in(speed), .cursor_x_in(cursor_x), .cursor_y_in(cursor_y),
        .cursor_click_in(click), .data_r_in(logic_data_r),
        .addr_r_out(logic_addr_r), .addr_w_out(logic_addr_w),
        .wr_en_out(logic_wr_en), .data_w_out(logic_data_w),
        .done_out(logic_done));
endmodule
`default_nettype wire

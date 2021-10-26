`default_nettype none
module life_stat_renderer(input wire clk_in,
                          input wire[2*LOG_BOARD_SIZE-1:0] count_in,
                          input wire[LOG_SCREEN_WIDTH-1:0] hcount_in,
                          input wire[LOG_SCREEN_HEIGHT-1:0] vcount_in,
                          output logic[3:0] pix_r_out,
                          output logic[3:0] pix_g_out,
                          output logic[3:0] pix_b_out);
endmodule
`default_nettype wire

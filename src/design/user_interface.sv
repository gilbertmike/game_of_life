`include "common.svh"

`default_nettype none
module user_interface(input wire clk_in,
                      input wire[15:0] sw_in,
                      input wire btnd_in, btnc_in, btnu_in, btnl_in, btnr_in,
                      output logic click_out,
                      output logic[LOG_MAX_SPEED-1:0] speed_out,
                      output logic[LOG_BOARD_SIZE-1:0] cursor_x_out, cursor_y_out,
                      output pos_t view_x_out, view_y_out);
endmodule
`default_nettype wire

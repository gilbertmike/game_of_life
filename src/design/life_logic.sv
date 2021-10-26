`include "common.svh"

`default_nettype none
module life_logic(input wire clk_in,
                  input wire start_in,
                  input wire[LOG_MAX_SPEED-1:0] speed_in,
                  input wire[LOG_LINE_WIDTH-1:0] data_r_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                  input wire cursor_click_in,
                  output logic[LOG_MAX_ADDR-1:0] addr_r_out,
                  output logic[LOG_MAX_ADDR-1:0] addr_w_out,
                  output logic[LOG_LINE_WIDTH-1:0] data_out,
                  output logic wr_en_out,
                  output logic done_out);
endmodule
`default_nettype wire

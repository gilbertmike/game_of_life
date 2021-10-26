`default_nettype none
// TODO: user input
module life_logic#(parameter ADDR_SIZE = 32,
                   parameter LINE_WIDTH = 8,
                   parameter LOG_MAX_SPEED = 3,
                   parameter LOG_BOARD_SIZE = 10)
                  (input wire clk_in,
                   input wire start_in,
                   input wire[LOG_MAX_SPEED-1:0] speed_in,
                   input wire[LINE_WIDTH-1:0] data_r_in,
                   input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                   input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                   input wire cursor_click_in,
                   output logic[ADDR_SIZE-1:0] addr_r_out,
                   output logic[ADDR_SIZE-1:0] addr_w_out,
                   output logic[LINE_WIDTH-1:0] data_out,
                   output logic wr_en_out,
                   output logic done_out);
endmodule
`default_nettype wire

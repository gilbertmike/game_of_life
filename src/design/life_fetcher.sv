`include "common.svh"

`default_nettype none
module life_fetcher(input wire clk_in,
                    input wire start_in,
                    input wire[LOG_BOARD_SIZE-1:0] x_in,
                    input wire[LOG_BOARD_SIZE-1:0] y_in,
                    output logic[8:0] window_out,
                    output logic valid_out);
endmodule
`default_nettype wire

`include "common.svh"

`default_nettype none
module renderer(input wire clk_in, start_in,
                input wire[LOG_LINE_WIDTH-1:0] data_in,
                input wire[LOG_MAX_ADDR-1:0] view_x_in, view_y_in,
                output wire[LOG_MAX_ADDR-1:0] addr_r_out,
                output logic done_out,
                output logic[11:0] pix_out,
                output logic vsync_out, hsync_out);
endmodule
`default_nettype wire


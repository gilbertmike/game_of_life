`default_nettype none
module renderer#(parameter ADDR_SIZE=32, LINE_WIDTH = 8)
                (input wire clk_in,
                 input wire scrollx_in, scrolly_in,
                 input wire[LINE_WIDTH-1:0] data_in,
                 output wire[ADDR_SIZE-1:0] addr_r_out,
                 output logic[11:0] pix_out,
                 output logic vsync_out, hsync_out);
endmodule
`default_nettype wire


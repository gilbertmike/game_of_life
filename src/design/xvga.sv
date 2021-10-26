`include "common.svh"

`default_nettype none
module xvga(input wire clk_in,
            output logic vsync_out,
            output logic hsync_out,
            output logic blank_out,
            output logic[LOG_SCREEN_WIDTH-1:0] hcount_out,
            output logic[LOG_SCREEN_HEIGHT-1:0]_vcount_out);
endmodule
`default_nettype wire

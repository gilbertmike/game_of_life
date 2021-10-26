`default_nettype none
module double_buffer#(ADDR_SIZE=32, LINE_WIDTH=8)
                     (input wire clk_in,
                      input wire swap_in,
                      input wire[ADDR_SIZE-1:0] render_addr_r,
                      input wire[ADDR_SIZE-1:0] logic_addr_r,
                      input wire[ADDR_SIZE-1:0] logic_addr_w,
                      input wire[LINE_WIDTH-1:0] logic_data_w,
                      input wire logic_wr_en,
                      output logic[LINE_WIDTH-1:0] render_data_r,
                      output logic[LINE_WIDTH-1:0] logic_data_r);
endmodule
`default_nettype wire

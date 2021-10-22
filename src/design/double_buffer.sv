`default_nettype none
module double_buffer#(ADDR_SIZE=32, LINE_WIDTH=8)
                     (input wire clk_in,
                      input wire swap_in,
                      input wire[ADDR_SIZE-1:0] addr_rend_r,
                      input wire[ADDR_SIZE-1:0] addr_logic_r,
                      input wire[ADDR_SIZE-1:0] addr_logic_w,
                      input wire[LINE_WIDTH-1:0] data_logic_w,
                      output logic[LINE_WIDTH-1:0] data_rend_r,
                      output logic[LINE_WIDTH-1:0] data_logic_r);
endmodule
`default_nettype wire

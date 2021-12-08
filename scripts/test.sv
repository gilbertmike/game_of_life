`default_nettype none
module seed_select(input wire[4:0] seed_idx,
                   input wire[5:0] x_in,
                   input wire[5:0] y_in,
                   output logic alive_out);
    logic alive[0:-1];
    assign alive_out = alive[seed_idx];
endmodule
`default_nettype wire

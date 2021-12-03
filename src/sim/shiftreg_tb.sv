`timescale 1ns / 1ps

`default_nettype none
module shiftreg_tb;
    logic clk;
    always #5 clk = !clk;

    // Inputs
    logic rst, alive_in, shift;

    // Outputs
    logic alive_out;

    smol_shiftreg0#(.SIZE(4)) dut(
        .clk_in(clk), .rst_in(rst), .alive_in(alive_in),
        .shift_in(shift), .alive_out(alive_out));

    initial begin
        clk = 0;
        rst = 1;
        alive_in = 0;
        shift = 0;
        #20;
        rst = 0;

        #10;
        shift = 1;
        #10;
        alive_in = 1;
        #10;
        shift = 0;
        #10;
        shift = 1;
        alive_in = 0;
        #10;
        alive_in = 1;
        #10;
        shift = 0;
        #10;
        alive_in = 0;
        #10;
        alive_in = 1;
        #10;
        shift = 1;
        #50;
    end
endmodule
`default_nettype wire

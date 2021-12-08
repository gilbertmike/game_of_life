`timescale 1ns / 1ps

`include "common.svh"

`default_nettype none
module sound_effect_tb;
    logic clk;
    always #5 clk = !clk;

    // Inputs
    logic rst, click, seed_en;
    logic[LOG_NUM_SEED-1:0] seed_idx;

    // Output
    logic aud_sd, aud_pwm;

    sound_effect dut(.clk_in(clk), .rst_in(rst), .seed_idx_in(seed_idx),
                     .seed_en_in(seed_en), .click_in(click),
                     .aud_sd_out(aud_sd), .aud_pwm_out(aud_pwm));

    initial begin
        clk = 0;
        rst = 1;
        click = 0;
        seed_en = 0;
        seed_idx = 0;

        #20;
        rst = 0;
        seed_idx = 1;
        #1000;
    end
endmodule
`default_nettype wire

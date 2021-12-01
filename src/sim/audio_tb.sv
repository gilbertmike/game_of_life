`timescale 1ns / 1ps

`include "common.svh"

module audio_tb;

    //initiate inputs
    logic clk;
    logic rst;
    logic sd_cd;
    logic play_audio;   
    
    //initiate outputs
    logic sd_dat;
    logic sd_reset;
    logic sd_sck;
    logic sd_cmd;
    logic aud_pwm;
    
    //uut
    audio uut(.clk_in(clk), .rst_in(rst), .sd_cd_in(sd_cd), 
              .play_audio_in(play_audio), .sd_dat(sd_dat),
              .sd_reset_out(sd_reset), .sd_sck_out(sd_sck),
              .sd_cmd_out(sd_cmd), .aud_pwm_out(aud_pwm));
    
    //clk
    always #5 clk = !clk;
    
    initial begin
        clk = 0;
        rst = 0;
        sd_cd = 0;
        play_audio = 0;
        sd_dat = 0;
        #10
        rst = 1;
        #10
        rst = 0;
        
    end
endmodule

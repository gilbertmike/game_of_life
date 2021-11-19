`timescale 1ns / 1ps

typedef logic[7:0] sample_t;

`default_nettype none
/**
 * audio - plays music and sound effects.
 *
 * Operation:
 *  - Music will loop forever.
 *  - If effect_in is nonzero, the selected sound effect will be played.
 *    When the current sound effect is over, effect_in is checked again.
 */
module audio(input wire clk_100mhz,
             input wire rst_in,
             input wire[1:0] effect_in,
             input wire miso_in,
             output logic cs_out, mosi_out, sclk_out,
             output logic aud_sd_out, aud_pwm_out);
    logic clk_25mhz;
    clk_wiz_25mhz(.clk_in1(clk_100mhz), .clk_out1(clk_25mhz));

    // TODO: set up address generation to play music.
    logic rd, byte_available, ready_for_next, ready;
    logic[31:0] addr;
    sample_t sample;
    sd_controller sd(.cs(cs_out), .mosi(mosi_out), .miso(miso_in),
                     .sclk(sclk_out), .rd(rd), .byte_available(byte_available),
                     .wr(1'b0), .din(7'b0),
                     .ready_for_next_byte(ready_for_next), .reset(rst_in),
                     .ready(ready), .address(addr), .clk(clk_25mhz),
                     .status(5'b0));

    logic pwm;
    audio_pwm pwm(.clk_100mhz(clk_100mhz), .reset_in(rst_in),
                  .music_data(sample), .pwm_out(pwm));

    assign aud_pwm_out = pwm ? 1'bZ : 1'b0;
endmodule
`default_nettype wire

`default_nettype none
/**
 * audio_pwm - generates PWM signal from 8-bit sample.
 *
 * Credit:
 * 6.111 Final Project SD card starter tutorial by Grace Quaratiello.
 */
module audio_pwm(input wire clk_100mhz,
                 input wire reset_in
                 input wire[7:0] music_data,
                 output logic pwm_out);
    // counts up to 255 clock cycles per pwm period
    reg [7:0] pwm_counter = 8'd0; 

    always @(posedge clk) begin
        if(reset) begin
            pwm_counter <= 0;
            pwm_out <= 0;
        end
        else begin
            pwm_counter <= pwm_counter + 1;
            
            if(pwm_counter >= music_data) PWM_out <= 0;
            else pwm_out <= 1;
        end
    end
endmodule
`default_nettype wire


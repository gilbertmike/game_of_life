`timescale 1ns / 1ps

`include "common.svh"

typedef logic[7:0] sample_t;

`default_nettype none
module sound_effect(input wire clk_in,
                    input wire rst_in,
                    input wire[LOG_NUM_SEED-1:0] seed_idx_in,
                    input wire seed_en_in,
                    input wire click_in,
                    output logic aud_sd_out, aud_pwm_out);
    logic[LOG_NUM_SEED-1:0] last_seed_idx;
    logic last_seed_en;
    logic last_click;
    logic[1:0] effect_in;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            last_seed_idx <= 0;
            last_seed_en <= 0;
            last_click <= 0;
            effect_in <= 0;
        end else begin
            last_seed_idx <= seed_idx_in;
            last_seed_en <= seed_en_in;
            last_click <= click_in;
            if (last_seed_en && !seed_en_in) begin
                effect_in <= 1;
            end else if (last_seed_idx != seed_idx_in) begin
                effect_in <= 2;
            end else if (!last_click && click_in) begin
                effect_in <= 3;
            end else begin
                effect_in <= 0;
            end
        end
    end

    audio a(.clk_in(clk_in), .rst_in(rst_in), .effect_in(effect_in),
            .aud_sd_out(aud_sd_out), .aud_pwm_out(aud_pwm_out));
endmodule
`default_nettype wire

`default_nettype none
/**
 * audio - plays music and sound effects.
 *
 * Operation:
 *  - Music will loop forever.
 *  - If effect_in is nonzero, the selected sound effect will be played.
 *    When the current sound effect is over, effect_in is checked again.
 */
module audio(input wire clk_in,
             input wire rst_in,
             input wire[1:0] effect_in,
             output logic aud_sd_out, aud_pwm_out);
    localparam PERIOD = 567;  // 25MHz/ 44.1kHz
    localparam MIN_ADDR = 1_000;
    localparam MAX_ADDR = 40_000;

    sample_t pat_sel_sample;
    logic[15:0] addr;
    pattern_select_rom pattern_select(
        .clka(clk_in), .addra(addr), .douta(pat_sel_sample));

    sample_t pat_sc_sample;
    pattern_scroll_rom pattern_scroll(
        .clka(clk_in), .addra(addr), .douta(pat_sc_sample));

    sample_t click_sample;
    click_rom click(
        .clka(clk_in), .addra(addr), .douta(click_sample));

    logic[1:0] effect_idx;
    sample_t sample;
    always_comb begin
        case (effect_idx)
            0: sample = 0;
            1: sample = pat_sel_sample;
            2: sample = pat_sc_sample;
            3: sample = click_sample;
            default: sample = 0;
        endcase
    end

    enum logic { IDLE, WORKING } state;
    logic[9:0] counter;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            state <= IDLE;
            counter <= 0;
            addr <= 0;
            effect_idx <= 0;
        end else if (effect_in != 0) begin
            state <= WORKING;
            counter <= 0;
            addr <= MIN_ADDR;
            effect_idx <= effect_in;
        end else if (state == WORKING) begin
            if (counter == PERIOD) begin
                counter <= 0;
                addr <= addr + 1;
                if (addr == MAX_ADDR) begin
                    addr <= 0;
                    state <= IDLE;
                end
            end else begin
                counter <= counter + 1;
            end
        end
    end

    logic pwm;
    audio_pwm p(.clk_in(clk_in), .reset_in(rst_in),
                .music_data(sample / 8), .pwm_out(pwm));

    assign aud_sd_out = 1;
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
module audio_pwm(input wire clk_in,
                 input wire reset_in,
                 input wire[7:0] music_data,
                 output logic pwm_out);
    // counts up to 63 clock cycles per pwm period
    reg [5:0] pwm_counter = 8'd0; 

    always @(posedge clk_in) begin
        if(reset_in) begin
            pwm_counter <= 0;
            pwm_out <= 0;
        end
        else begin
            pwm_counter <= pwm_counter + 1;
            
            if(pwm_counter >= music_data) pwm_out <= 0;
            else pwm_out <= 1;
        end
    end
endmodule
`default_nettype wire

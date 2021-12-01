`timescale 1ns / 1ps

/**
 * audio - outputs audio read from sd card.
 *
 * Operation:
 * - reads from sd card via sd_controller
 * - inputs the read data into fifo queue
 * - audio_pwm takes output from fifo queue, return aud_pwm_out
 *
 * Inputs:
 * - sd_cd_in always 1, play_audio_in depends on user input
 */

module audio(input wire clk_in,
             input wire clk_25mhz, 
             input wire rst_in,
             input wire sd_cd_in,
             input wire play_audio_in,
                     
             inout wire [3:0] sd_dat,

             output logic sd_reset_out, 
             output logic sd_sck_out, 
             output logic sd_cmd_out,
             output logic aud_pwm_out);

    parameter START_ADDR = 0;
    parameter THRESHOLD = 512;
    parameter FIFO_CYCLE_COUNT = 7;

    logic reset;            // assign to your system reset
    assign reset = rst_in;

    assign sd_dat[2:1] = 2'b11;
    assign sd_reset = 0;
    
    assign aud_pwm_out = pwm_out?1'bZ:1'b0;


    // sd_controller inputs
    logic rd;                   // read enable
    logic wr;                   // write enable
    assign wr = 0;              // write always disabled
    logic[7:0] sd_din;          // data to sd card
    logic[31:0] addr;          // starting address for read/write operation

    // sd_controller outputs
    logic ready;                // high when ready for new read/write operation
    logic[7:0] sd_dout;         // data from sd card
    logic byte_available;       // high when byte available for read
    logic ready_for_next_byte;  // high when ready for new byte to be written
    logic[4:0] status;          // for debugging

    // FIFO inputs
    logic full;
    logic empty;
    logic[7:0] fifo_dout;
    logic rd_en;

    // FIFO output
    logic[8:0] data_count;

    // handles reading from the SD card
    sd_controller sd(.reset(reset), .clk(clk_25mhz), .cs(sd_dat[3]), .mosi(sd_cmd_out), 
                     .miso(sd_dat[0]), .sclk(sd_sck_out), .ready(ready), .address(addr),
                     .rd(rd), .dout(sd_dout), .byte_available(byte_available),
                     .wr(wr), .din(sd_din), .ready_for_next_byte(ready_for_next_byte),
                     .status(status));
                     
    // PWM module
    audio_pwm pwm(.clk(clk_in), .reset(rst_in), .music_data(fifo_dout), 
                  .pwm_out(pwm_out));

    // FIFO for data queue
    fifo_generator_0 fifo(.srst(reset), .clk(clk_25mhz), .full(full), .din(sd_dout),
                           .wr_en(byte_available), .empty(empty), .dout(fifo_dout), .rd_en(rd_en));

    logic[2:0] cycle_count;
    logic[8:0] byte_count;

    always_ff @(posedge clk_25mhz) begin
        if (reset) begin
            addr <= START_ADDR;
            rd <= 1'b1;
            cycle_count <= 1'b0;
        end else begin
            if (cycle_count == FIFO_CYCLE_COUNT)
                rd_en <= 1'b1;
            else if (byte_count == 512)    //each SD read operation reads 512 bytes
                addr <= addr + 512;
            else if (data_count > THRESHOLD-1) 
                rd <= 1'b0;
            cycle_count <= cycle_count + 1'b1;
            byte_count <= byte_count + 1'b1;
        end
    end

endmodule

        
// audio_pwm module from SD card tutorial (6.111)
module audio_pwm(
        input clk, 			// 100MHz clock.
        input reset,		// Reset assertion.
        input [7:0] music_data,	// 8-bit music sample
        output reg pwm_out		// PWM output. Connect this to ampPWM.
        );
        
        reg [7:0] pwm_counter = 8'd0;           // counts up to 255 clock cycles per pwm period
              
        always @(posedge clk) begin
            if(reset) begin
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

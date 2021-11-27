`timescale 1ns / 1ps

module top_level_sd(input clk_100mhz, 
                    input sd_cd,
                    input [15:0]sw,
                             
                    inout [3:0] sd_dat,
                       
                    output logic [15:0] led,
                    output logic sd_reset, 
                    output logic sd_sck, 
                    output logic sd_cmd
    );
    
    parameter START_ADDR = 15;
    
    logic reset;            // assign to your system reset
    assign reset = sw[15];
    
    assign sd_dat[2:1] = 2'b11;
    assign sd_reset = 0;
    
    // generate 25 mhz clock for sd_controller 
    logic clk_25mhz;
    clk_wiz clk_gen(.clk_100mhz(clk_100mhz), .clk_25mhz(clk_25mhz));
   
    // sd_controller inputs
    logic rd;                   // read enable
    logic wr;                   // write enable
    assign wr = 0;              // write always disabled
    logic[7:0] din;            // data to sd card
    logic[31:0] addr;          // starting address for read/write operation
    
    // sd_controller outputs
    logic ready;                // high when ready for new read/write operation
    logic[7:0] dout;           // data from sd card
    logic byte_available;       // high when byte available for read
    logic last_byte_available;  // used to generate pulse
    logic ready_for_next_byte;  // high when ready for new byte to be written
    
    // FIFO inputs
    logic full;
    logic[7:0] din;
    logic wr_en;
    logic empty;
    logic[7:0] dout;
    logic rd_en;
    
    // FIFO output
    logic[8:0] data_count;
    
    // handles reading from the SD card
    sd_controller sd(.reset(reset), .clk(clk_25mhz), .cs(sd_dat[3]), .mosi(sd_cmd), 
                     .miso(sd_dat[0]), .sclk(sd_sck), .ready(ready), .address(addr),
                     .rd(rd), .dout(dout), .byte_available(byte_available),
                     .wr(wr), .din(din), .ready_for_next_byte(ready_for_next_byte),
                     .data_count(data_count));
                     
    // FIFO for data queue
     fifo_generator_0 fifo(.srst(srst), .clk(clk_25mhz), .full(full), .din(din),
                           .wr_en(wr_en), .empty(empty), .dout(dout), .rd_en(rd_en));
    
    always_ff @(posedge clk_25mhz) begin
        if (reset) begin
            addr <= START_ADDR;
            rd <= 1'b1;
        end else begin
            if (byte_available && (byte_available == !last_byte_available)) begin
                wr_en <= 1'b1;
                last_byte_available <= byte_available;
            end
        end
    end
    
endmodule
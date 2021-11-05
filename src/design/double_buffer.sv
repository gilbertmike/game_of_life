`include "common.svh"

`default_nettype none
module double_buffer(input wire clk_in,
                     input wire rst_in,
                     input wire swap_in,
                     input wire[LOG_MAX_ADDR-1:0] render_addr_r,
                     input wire[LOG_MAX_ADDR-1:0] logic_addr_r,
                     input wire[LOG_MAX_ADDR-1:0] logic_addr_w,
                     input wire[WORD_SIZE-1:0] logic_data_w,
                     input wire logic_wr_en,
                     output logic[WORD_SIZE-1:0] render_data_r,
                     output logic[WORD_SIZE-1:0] logic_data_r);
    addr_t buf0_addra;
    data_t buf0_data_ra;
    data_t buf0_data_wa;
    logic buf0_wr_ena;
    addr_t buf0_addrb;
    data_t buf0_data_rb;
    bram_buffer0 buf0(.clka(clk_in), .addra(buf0_addra), .dina(buf0_data_wa),
                      .douta(buf0_data_ra), .wea(buf0_wr_ena),
                      .clkb(clk_in), .addrb(buf0_addrb), .dinb(0),
                      .doutb(buf0_data_rb), .web(0));

    addr_t buf1_addra;
    data_t buf1_data_ra;
    data_t buf1_data_wa;
    logic buf1_wr_ena;
    addr_t buf1_addrb;
    data_t buf1_data_rb;
    bram_buffer1 buf1(.clka(clk_in), .addra(buf1_addra), .dina(buf1_data_wa),
                      .douta(buf1_data_ra), .wea(buf1_wr_ena),
                      .clkb(clk_in), .addrb(buf1_addrb), .dinb(0),
                      .doutb(buf1_data_rb), .web(0));

    // buffer_toggle decides if logic writes to buf0 or buf1
    logic buffer_toggle;
    always_ff @(posedge clk_in) begin
        if (rst_in)
            buffer_toggle <= 0;
        else
            buffer_toggle <= swap_in ? !buffer_toggle : buffer_toggle;
    end

    always_comb begin
        if (buffer_toggle) begin
            buf0_addra = logic_addr_w;
            buf0_data_wa = logic_data_w;
            buf0_wr_ena = logic_wr_en;

            buf1_addra = logic_addr_r;
            logic_data_r = buf1_data_ra;
            buf1_addrb = render_addr_r;
            render_data_r = buf1_data_rb;
            buf1_wr_ena = 0;
        end else begin
            buf1_addra = logic_addr_w;
            buf1_data_wa = logic_data_w;
            buf1_wr_ena = logic_wr_en;

            buf0_addra = logic_addr_r;
            logic_data_r = buf0_data_ra;
            buf0_addrb = render_addr_r;
            render_data_r = buf0_data_rb;
            buf0_wr_ena = 0;
        end
    end
endmodule
`default_nettype wire

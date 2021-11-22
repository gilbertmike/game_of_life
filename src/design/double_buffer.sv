`include "common.svh"

`default_nettype none
module double_buffer(input wire clk_130mhz,
                     input wire rst_in,
                     input wire swap_in,
                     input wire[LOG_MAX_ADDR-1:0] render_addr_r,
                     input wire[LOG_MAX_ADDR-1:0] logic_addr_r,
                     input wire[LOG_MAX_ADDR-1:0] logic_addr_w,
                     input wire[WORD_SIZE-1:0] logic_data_w,
                     input wire logic_wr_en,
                     output logic ready_out,
                     output logic[WORD_SIZE-1:0] render_data_r,
                     output logic[WORD_SIZE-1:0] logic_data_r);
    addr_t buf0_addra;
    data_t buf0_data_ra;
    data_t buf0_data_wa;
    logic buf0_wr_ena;
    addr_t buf0_addrb;
    data_t buf0_data_rb;
    bram_buffer0 buf0(.clka(clk_130mhz), .addra(buf0_addra), .dina(buf0_data_wa),
                      .douta(buf0_data_ra), .wea(buf0_wr_ena),
                      .clkb(clk_130mhz), .addrb(buf0_addrb), .dinb(0),
                      .doutb(buf0_data_rb), .web(0));

    addr_t buf1_addra;
    data_t buf1_data_ra;
    data_t buf1_data_wa;
    logic buf1_wr_ena;
    addr_t buf1_addrb;
    data_t buf1_data_rb;
    bram_buffer1 buf1(.clka(clk_130mhz), .addra(buf1_addra), .dina(buf1_data_wa),
                      .douta(buf1_data_ra), .wea(buf1_wr_ena),
                      .clkb(clk_130mhz), .addrb(buf1_addrb), .dinb(0),
                      .doutb(buf1_data_rb), .web(0));

    // buffer_toggle decides if logic writes to buf0 or buf1
    logic buffer_toggle;
    always_ff @(posedge clk_130mhz) begin
        if (rst_in) begin
            buffer_toggle <= 0;
        end else begin
            buffer_toggle <= swap_in ? !buffer_toggle : buffer_toggle;
            ready_out <= 1;
        end
    end

    always_comb begin
        if (buffer_toggle) begin
            buf0_addra = logic_addr_w;
            buf0_data_wa = logic_data_w;
            buf0_wr_ena = logic_wr_en;

            buf0_addrb = 0;

            buf1_addra = logic_addr_r;
            buf1_data_wa = 0;
            buf1_wr_ena = 0;

            buf1_addrb = render_addr_r;
        end else begin
            buf1_addra = logic_addr_w;
            buf1_data_wa = logic_data_w;
            buf1_wr_ena = logic_wr_en;

            buf1_addrb = 0;

            buf0_addra = logic_addr_r;
            buf0_data_wa = 0;
            buf0_wr_ena = 0;

            buf0_addrb = render_addr_r;
        end
    end

    always_ff @(posedge clk_130mhz) begin
        if (buffer_toggle) begin
            logic_data_r <= buf1_data_ra;
            render_data_r <= buf1_data_rb;
        end else begin
            logic_data_r <= buf0_data_ra;
            render_data_r <= buf0_data_rb;
        end
    end
endmodule
`default_nettype wire

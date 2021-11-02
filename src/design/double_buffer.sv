`default_nettype none
module double_buffer#(ADDR_SIZE=32, LINE_WIDTH=8)
                     (input wire clk_in,
                      input wire swap_in,
                      input wire[ADDR_SIZE-1:0] render_addr_r,
                      input wire[ADDR_SIZE-1:0] logic_addr_r,
                      input wire[ADDR_SIZE-1:0] logic_addr_w,
                      input wire[LINE_WIDTH-1:0] logic_data_w,
                      input wire logic_wr_en,
                      output logic[LINE_WIDTH-1:0] render_data_r,
                      output logic[LINE_WIDTH-1:0] logic_data_r);
    addr_t buf0_addr_r;
    addr_t buf0_addr_w;
    data_t buf0_data_r;
    data_t buf0_data_w;
    logic buf0_wr_en;
    bram_buffer0 buf0(.clka(clk_in), .addra(buf0_addr_w), .dina(buf0_data_w),
                      .wea(buf0_wr_en), .clkb(clk_in), .addrb(buf0_addr_r), 
                      .doutb(buf0_data_r));

    addr_t buf1_addr_r;
    addr_t buf1_addr_w;
    data_t buf1_data_r;
    data_t buf1_data_w;
    logic buf1_wr_en;
    bram_buffer1 buf1(.clka(clk_in), .addra(buf1_addr_w), .dina(buf1_data_w),
                      .wea(buf1_wr_en), .clkb(clk_in), .addrb(buf1_addr_r), 
                      .doutb(buf1_data_r));

    // buffer_toggle decides if logic goes to buf0 or buf1
    logic buffer_toggle;
    always_ff @(posedge clk_in) begin
        buffer_toggle <= swap_in ? !buffer_toggle : buffer_toggle;
    end

    always_comb begin
        if (buffer_toggle) begin
            buf0_addr_r = logic_addr_r;
            logic_data_r = buf0_data_r;
            buf0_addr_w = logic_addr_w;
            buf0_data_w = logic_data_w;
            buf0_wr_en = logic_wr_en;

            buf1_addr_r = render_addr_r;
            render_data_r = buf1_data_r;
            buf1_addr_w = 0;
            buf1_data_w = 0;
            buf1_wr_en = 0;
        end else begin
            buf0_addr_r = render_addr_r;
            render_data_r = buf0_data_r;
            buf0_addr_w = 0;
            buf0_data_w = 0;
            buf0_wr_en = 0;

            buf1_addr_r = logic_addr_r;
            logic_data_r = buf1_data_r;
            buf1_addr_w = logic_addr_w;
            buf1_data_w = logic_data_w;
            buf1_wr_en = logic_wr_en;
        end
    end
endmodule
`default_nettype wire

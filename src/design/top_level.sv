`default_nettype none
module top_level(input wire clk_100mhz,
                 input wire btnc, btnu, btnl, btnr, btnd,
                 input wire[15:0] sw,
                 output logic[3:0] vga_r, vga_g, vga_b,
                 output logic vga_hs, vga_vs);
    parameter LINE_WIDTH = 8;
    parameter ADDR_SIZE = 3;
    parameter LOG_MAX_SPEED = 3;
    parameter SPEED_SW = 0;

    logic[ADDR_SIZE-1:0] addr_rend_r;
    logic[LINE_WIDTH-1:0] data_rend_r;
    logic[ADDR_SIZE-1:0] addr_logic_r;
    logic[ADDR_SIZE-1:0] addr_logic_w;
    logic[LINE_WIDTH-1:0] data_logic_w;
    logic[LINE_WIDTH-1:0] data_logic_r;
    
    logic buf_swap, logic_done;
    logic[1:0] done_count;
    always_ff @(posedge clk_100mhz) begin
        if (sw[15]) begin
            done_count <= 2'd0;
        end else if (done_count == 2'd0) begin
            buf_swap <= 1'b0;
        end else begin
            case ({logic_done, vga_vs})
                2'b11: begin
                    done_count <= 2'd0;
                    buf_swap <= 1'b1;
                end
                2'b10: done_count <= 2'd1;
                2'b01: done_count <= 2'd1;
                default: begin
                    done_count <= 2'd0;
                    buf_swap <= 1'b0;
                end
            endcase
        end
    end

    double_buffer#(.ADDR_SIZE(ADDR_SIZE), .LINE_WIDTH(LINE_WIDTH)) db(
        .clk_in(clk_100mhz), .addr_rend_r(addr_rend_r), .swap_in(buf_swap),
        .addr_logic_r(addr_logic_r), .addr_logic_w(addr_logic_w),
        .data_rend_r(data_rend_r), .data_logic_w(data_logic_w),
        .data_logic_r(data_logic_r));

    renderer#(.LINE_WIDTH(LINE_WIDTH)) renderer0(
        .clk_in(clk_100mhz), .data_in(data_rend_r), .addr_r_out(addr_rend_r),
        .pix_out({vga_r, vga_g, vga_b}), .vsync_out(vga_vs),
        .hsync_out(vga_hs));

    life_logic#(.ADDR_SIZE(ADDR_SIZE), .LINE_WIDTH(LINE_WIDTH),
                .LOG_MAX_SPEED(LOG_MAX_SPEED))
        life_logic0(.clk_in(clk_100mhz),
                    .speed_in(sw[SPEED_SW+LOG_MAX_SPEED-1:SPEED_SW]),
                    .addr_r_out(addr_logic_r), .addr_w_out(addr_logic_w),
                    .data_out(data_logic_w), .done_out(logic_done));
endmodule
`default_nettype wire

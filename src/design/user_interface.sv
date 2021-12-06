`include "common.svh"

`default_nettype none
module user_interface#(parameter LOG_DEBOUNCE_COUNT = 20,
                       parameter LOG_WAIT_COUNT = 25)
                      (input wire clk_in, rst_in,
                       input wire[15:0] sw_in,
                       input wire btnd_in, btnc_in, btnu_in, btnl_in, btnr_in,
                       input wire[HCOUNT_WIDTH-1:0] hcount_in,
                       input wire[VCOUNT_WIDTH-1:0] vcount_in,
                       input wire hsync_in, vsync_in, blank_in,
                       output logic click_out,
                       output logic[LOG_MAX_SPEED-1:0] speed_out,
                       output logic[LOG_BOARD_SIZE-1:0] cursor_x_out,
                       output logic[LOG_BOARD_SIZE-1:0] cursor_y_out,
                       output logic[LOG_NUM_SEED-1:0] seed_idx_out,
                       output logic seed_en_out,
                       vga_if.src vga_out);
    // --------------------------------------- Debouncers (excluded from stage)
    logic btnd_deb, btnu_deb, btnc_deb, btnl_deb, btnr_deb;
    debounce#(LOG_DEBOUNCE_COUNT) btn_debouncers [4:0] (
        .clk_in(clk_in), .rst_in(rst_in),
        .noisy_in({btnd_in, btnc_in, btnu_in, btnl_in, btnr_in}),
        .clean_out({btnd_deb, btnc_deb, btnu_deb, btnl_deb, btnr_deb}));

    logic btnd, btnu, btnl, btnr;
    btn_pwd#(LOG_WAIT_COUNT) btn_pwds [3:0] (
        .clk_in(clk_in), .rst_in(rst_in),
        .btn_in({btnd_deb, btnu_deb, btnl_deb, btnr_deb}),
        .move_out({btnd, btnu, btnl, btnr}));

    logic[15:0] sw;
    debounce#(LOG_DEBOUNCE_COUNT) sw_debouncers [15:0] (
        .clk_in(clk_in), .rst_in(rst_in), .noisy_in(sw_in),
        .clean_out(sw));

    // --------------------------------------- Board viewer logic (First Stage)
    logic click_edge;  // frame-width pulse of click
    pos_edge click_edge_detect(
        .clk_in(clk_in), .rst_in(rst_in),
        .en(hcount_in == BOARD_SIZE && vcount_in == BOARD_SIZE),
        .in(btnc_deb),
        .out(click_edge));

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            speed_out <= 0;
            click_out <= 0;
            cursor_x_out <= BOARD_SIZE / 2;
            cursor_y_out <= BOARD_SIZE / 2;
            seed_idx_out <= 0;
            seed_en_out <= 0;
            vga_out.hcount <= 0;
            vga_out.vcount <= 0;
            {vga_out.hsync, vga_out.vsync, vga_out.blank} <= 0;
        end else begin
            speed_out <= sw[LOG_MAX_SPEED-1:0];
            click_out <= click_edge;
            if (btnd) begin
                cursor_y_out <= cursor_y_out + 1;
            end else if (btnu) begin
                cursor_y_out <= cursor_y_out - 1;
            end else if (btnl) begin
                cursor_x_out <= cursor_x_out - 1;
            end else if (btnr) begin
                cursor_x_out <= cursor_x_out + 1;
            end
            seed_idx_out <= sw[SEED_SW+LOG_NUM_SEED-1:SEED_SW];
            seed_en_out <= sw[SEED_EN_SW];
            vga_out.hcount <= hcount_in;
            vga_out.vcount <= vcount_in;
            {vga_out.hsync, vga_out.vsync, vga_out.blank} <=
                {hsync_in, vsync_in, blank_in};
        end

    end
endmodule
`default_nettype wire

`default_nettype wire
module pos_edge(input wire clk_in,
                input wire rst_in,
                input wire en,
                input wire in,
                output logic out);
    logic last;
    always_ff @(posedge clk_in) begin
        if (rst_in)
            out <= 0;
        else if (en) begin
            last <= in;
            out <= !last && in;
        end
    end
endmodule
`default_nettype none

`default_nettype none
module debounce#(parameter LOG_DEBOUNCE_COUNT = 20)
                (input wire clk_in, rst_in, noisy_in,
                 output logic clean_out);
    localparam DEBOUNCE_COUNT = 2**LOG_DEBOUNCE_COUNT - 1;
    logic[LOG_DEBOUNCE_COUNT-1:0] count;
    logic new_input;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            new_input <= noisy_in;
            clean_out <= noisy_in;
            count <= 0;
        end else if (noisy_in != new_input) begin
            new_input <= noisy_in;
            count <= 0;
        end else if (count == DEBOUNCE_COUNT) begin
            clean_out <= new_input;
        end else begin
            count <= count + 1;
        end
    end
endmodule 
`default_nettype wire

`default_nettype none
/**
 * btnhandler - implement press-wait-hold for buttons
 *
 * When btn_in is first asserted, then a pulse is sent in move_out. After
 * waiting for 2**LOG_WAIT_COUNT cycles, if btn_in is still asserted, then
 * move_out is asserted and held.
 */
module btn_pwd#(parameter LOG_WAIT_COUNT = 26)
               (input wire clk_in, rst_in, btn_in,
                output logic move_out);
    localparam WAIT_COUNT = 2**LOG_WAIT_COUNT - 1;
    logic[LOG_WAIT_COUNT-1:0] count;

    always_ff @(posedge clk_in) begin
        if (rst_in || !btn_in) begin
            move_out <= 0;
            count <= 0;
        end else if (btn_in) begin
            move_out <= count == 0;
            count <= count + 1;
        end
    end
endmodule
`default_nettype wire

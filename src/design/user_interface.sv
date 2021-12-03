`include "common.svh"

`default_nettype none
module user_interface#(parameter LOG_DEBOUNCE_COUNT = 20,
                       parameter LOG_WAIT_COUNT = 25)
                      (input wire clk_in, rst_in,
                       input wire[15:0] sw_in,
                       input wire btnd_in, btnc_in, btnu_in, btnl_in, btnr_in,
                       output logic click_out,
                       output logic[LOG_MAX_SPEED-1:0] speed_out,
                       output logic[LOG_BOARD_SIZE-1:0] cursor_x_out,
                       output logic[LOG_BOARD_SIZE-1:0] cursor_y_out);
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

    assign speed_out = sw[LOG_MAX_SPEED-1:0];

    // Board viewer logic
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            click_out <= 0;
            cursor_x_out <= BOARD_SIZE / 2;
            cursor_y_out <= BOARD_SIZE / 2;
        end else begin
            click_out <= btnc_deb;
            if (btnd) begin
                cursor_y_out <= cursor_y_out + 1;
            end else if (btnu) begin
                cursor_y_out <= cursor_y_out - 1;
            end else if (btnl) begin
                cursor_x_out <= cursor_x_out - 1;
            end else if (btnr) begin
                cursor_x_out <= cursor_x_out + 1;
            end
        end
    end
endmodule
`default_nettype wire

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

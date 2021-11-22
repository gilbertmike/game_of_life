`include "common.svh"

`default_nettype none
module synchronizer(input wire clk_in, rst_in,
                    input wire logic_done_in, render_done_in, buf_ready_in,
                    output logic logic_start_out,
                    output logic buf_swap_out);
    enum logic[1:0] { WAITING, WAITING_BUF, STARTING } state;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            logic_start_out <= 0;
            buf_swap_out <= 0;
            state <= WAITING;
        end else if (state == WAITING && logic_done_in && render_done_in) begin
            state <= WAITING_BUF;
            buf_swap_out <= 1;
        end else if (state == WAITING_BUF) begin
            buf_swap_out <= 0;
            if (buf_ready_in) begin
                state <= STARTING;
                logic_start_out <= 1;
            end
        end else if (state == STARTING) begin
            logic_start_out <= 0;
            buf_swap_out <= 0;
            if (!render_done_in) state <= WAITING;
        end
    end
endmodule
`default_nettype wire

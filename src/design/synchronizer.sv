`include "common.svh"

`default_nettype none
module synchronizer(input wire clk_in, rst_in,
                    input wire logic_done_in, render_done_in, buf_ready_in,
                    output logic logic_start_out, render_start_out,
                    output logic buf_swap_out);

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            logic_start_out <= 0;
            render_start_out <= 0;
            buf_swap_out <= 0;
        end else if (logic_done_in) begin
            if (render_done_in) begin
                buf_swap_out <= 1;
                if (buf_swap_out && buf_ready_in) begin
                    logic_start_out <= 1;
                    render_start_out <= 1;
                    buf_swap_out <= 0;
                end
            end
        end
    end
endmodule
`default_nettype wire

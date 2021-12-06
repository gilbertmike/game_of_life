`include "common.svh"

`default_nettype none
/**
 * life_logic - computes next board state.
 *
 * Operation:
 *  - Reads from double_buffer and writes the next state in.
 *  - Pulse start_in to start operation.
 *  - Check done_out to tell if next state is computed completely.
 */
module life_logic(input wire clk_in,
                  input wire rst_in,
                  input wire[LOG_MAX_SPEED-1:0] speed_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                  input wire cursor_click_in,
                  input wire[HCOUNT_WIDTH-1:0] hcount_in,
                  input wire[VCOUNT_WIDTH-1:0] vcount_in,
                  input wire hsync_in, vsync_in, blank_in,
                  input wire alive_in,
                  input wire wr_en,
                  output logic[HCOUNT_WIDTH-1:0] hcount_out,
                  output logic[VCOUNT_WIDTH-1:0] vcount_out,
                  output logic hsync_out, vsync_out, blank_out,
                  output logic alive_out);
    localparam ADDR_START = 2*BOARD_SIZE + 3;

    hcount_t hcount1, hcount2, hcount3;
    vcount_t vcount1, vcount2, vcount3;
    logic hsync1, hsync2, hsync3;
    logic vsync1, vsync2, vsync3;
    logic blank1, blank2, blank3;

    logic en1, en2, en3;
    logic update1, update2;
    logic rule_click1, rule_click2;
    logic alive_in1, alive_in2;
    logic wr_en1, wr_en2;

    logic a, b, c, d, e, f, g, h, i;
    logic next_state2, next_state3;

    // ------------------------------------------------------- First Stage
    life_tick tick(.clk_in(clk_in), .rst_in(rst_in), .speed_in(speed_in),
                   .hcount_in(hcount_in), .vcount_in(vcount_in),
                   .hcount_out(hcount1), .vcount_out(vcount1), .en_out(en1),
                   .update_out(update1));

    always_ff @(posedge clk_in) begin
        rule_click1 <= cursor_x_in == hcount_in && cursor_y_in == vcount_in
                        && cursor_click_in;
        alive_in1 <= alive_in;
        wr_en1 <= wr_en;
        {hsync1, vsync1, blank1} <= {hsync_in, vsync_in, blank_in};
    end

    // ------------------------------------------------------- Second Stage
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            en2 <= 0;
            rule_click2 <= 0;
            alive_in2 <= 0;
            wr_en2 <= 0;
            update2 <= 0;
            {hcount2, vcount2} <= 0;
            {hsync2, vsync2, blank2} <= 3'b0;
        end else begin
            en2 <= en1;
            rule_click2 <= rule_click1;
            alive_in2 <= alive_in1;
            wr_en2 <= wr_en1;
            update2 <= update1;
            hcount2 <= hcount1;
            vcount2 <= vcount1;
            {hsync2, vsync2, blank2} <= {hsync1, vsync1, blank1};
        end
    end

    smol_shiftreg0 row1_buf(.clk_in(clk_in), .rst_in(rst_in), .alive_in(d),
                            .rd_en(en1), .wr_en(en2), .alive_out(c));
    smol_shiftreg1 row2_buf(.clk_in(clk_in), .rst_in(rst_in), .alive_in(g),
                            .rd_en(en1), .wr_en(en2), .alive_out(f));
    big_shiftreg rest_buf(.clk_in(clk_in), .rst_in(rst_in), .wr_en(en2),
                          .alive_in(next_state2), .rd_en(en1), .alive_out(i));

    // ------------------------------------------------------------ Third Stage
    life_rule rule(.a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g), .h(h),
                   .i(i), .click(rule_click2), .alive_in(alive_in2),
                   .wr_en(wr_en2), .update_in(update2),
                   .next_state(next_state2));

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            {a, b, d, e, g, h} <= 9'b0;
        end else if (en2) begin
            a <= b;
            b <= c;
            d <= e;
            e <= f;
            g <= h;
            h <= i;
        end

        if (rst_in) begin
            en3 <= 0;
            next_state3 <= 0;
            {hcount3, vcount3} <= 0;
            {hsync3, vsync3, blank3} <=3'b0;
        end else begin
            en3 <= en2;
            next_state3 <= next_state2;
            {hcount3, vcount3} <= {hcount2, vcount2};
            {hsync3, vsync3, blank3} <= {hsync2, vsync2, blank2};
        end
    end

    // ----------------------------------------------------------- Fourth Stage
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            alive_out <= 0;
        end else if (en3) begin
            alive_out <= next_state3;
        end else begin
            alive_out <= 0;
        end

        if (rst_in) begin
            {hcount_out, vcount_out} <= 0;
            {hsync_out, vsync_out, blank_out} <= 0;
        end else begin
            {hcount_out, vcount_out} <= {hcount3, vcount3};
            {hsync_out, vsync_out, blank_out} <= {hsync3, vsync3, blank3};
        end
    end
endmodule
`default_nettype wire

`default_nettype none
/**
 * life_rule - all comb logic to calculate next state
 *
 * Timing: zero stage pipeline (1 cycle latency).
 */
module life_rule(input wire a, b, c,
                 input wire d, e, f,
                 input wire g, h, i,
                 input wire click,
                 input wire alive_in,
                 input wire wr_en,
                 input wire update_in,
                 output logic next_state);
    logic[3:0] neighbor_cnt;
    logic evolved_state;
    assign neighbor_cnt = a + b + c + d + f + g + h + i;
    assign evolved_state = (neighbor_cnt == 3) || (neighbor_cnt == 2 && e);
    always_comb begin
        if (wr_en)
            next_state = alive_in;
        else if (click)
            next_state = !e;
        else if (update_in)
            next_state = evolved_state;
        else
            next_state = e;
    end
endmodule
`default_nettype wire

`default_nettype none
/**
 * life_tick - if current pixel is inside board, assert en_out.
 *
 * Timing: one stage pipeline (2 cycle latency).
 */
module life_tick(input wire clk_in,
                 input wire rst_in,
                 input wire[LOG_MAX_SPEED-1:0] speed_in,
                 input wire[HCOUNT_WIDTH-1:0] hcount_in,
                 input wire[VCOUNT_WIDTH-1:0] vcount_in,
                 output logic[HCOUNT_WIDTH-1:0] hcount_out,
                 output logic[VCOUNT_WIDTH-1:0] vcount_out,
                 output logic en_out, update_out);
    localparam COUNTER_THRES = 60;
    logic[7:0] speed_counter;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            en_out <= 0;
            update_out <= 0;
            hcount_out <= 0;
            vcount_out <= 0;
            update_out <= 0;
            speed_counter <= 0;
        end else begin
            // Process cell only if rendering pixel in side the board.
            en_out <= (hcount_in < BOARD_SIZE) && (vcount_in < BOARD_SIZE);
            hcount_out <= hcount_in;
            vcount_out <= vcount_in;
            if (hcount_in == BOARD_SIZE && vcount_in == BOARD_SIZE) begin
                speed_counter <= speed_counter >= COUNTER_THRES ?
                                 0 : speed_counter + speed_in;
                update_out <= speed_counter >= COUNTER_THRES;
            end
        end
    end
endmodule
`default_nettype wire

`default_nettype none
module big_shiftreg#(parameter SIZE=BOARD_SIZE*(BOARD_SIZE-1)-1)
                    (input wire clk_in,
                     input wire rst_in,
                     input wire alive_in,
                     input wire wr_en,
                     input wire rd_en,
                     output logic alive_out);
    typedef logic[19:0] addr_t;

    addr_t head_addr, tail_addr;
    bram1024_2_wr1_rd1_0 b(
        .clka(clk_in), .addra(head_addr), .dina(alive_in), .wea(wr_en),
        .clkb(clk_in), .addrb(tail_addr), .doutb(alive_out));

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            head_addr <= SIZE;
            tail_addr <= 0;
        end else begin
            head_addr <= head_addr + wr_en;
            tail_addr <= tail_addr + rd_en;
        end
    end
endmodule
`default_nettype wire

`default_nettype none
module smol_shiftreg0#(parameter SIZE=BOARD_SIZE-2)
                      (input wire clk_in,
                       input wire rst_in,
                       input wire alive_in,
                       input wire wr_en,
                       input wire rd_en,
                       output logic alive_out);
    typedef logic[9:0] addr_t;

    addr_t head_addr, tail_addr;
    bram1024_wr1_rd1_0 b(
        .clka(clk_in), .addra(head_addr), .dina(alive_in), .wea(wr_en),
        .clkb(clk_in), .addrb(tail_addr), .doutb(alive_out));

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            head_addr <= SIZE;
            tail_addr <= 0;
        end else begin
            head_addr <= head_addr + wr_en;
            tail_addr <= tail_addr + rd_en;
        end
    end
endmodule
`default_nettype wire

`default_nettype none
module smol_shiftreg1#(parameter SIZE=BOARD_SIZE-2)
                      (input wire clk_in,
                       input wire rst_in,
                       input wire alive_in,
                       input wire wr_en,
                       input wire rd_en,
                       output logic alive_out);
    typedef logic[9:0] addr_t;

    addr_t head_addr, tail_addr;
    bram1024_wr1_rd1_1 b(
        .clka(clk_in), .addra(head_addr), .dina(alive_in), .wea(wr_en),
        .clkb(clk_in), .addrb(tail_addr), .doutb(alive_out));

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            head_addr <= SIZE;
            tail_addr <= 0;
        end else begin
            head_addr <= head_addr + wr_en;
            tail_addr <= tail_addr + rd_en;
        end
    end
endmodule
`default_nettype wire

`default_nettype none
/**
 * seed_gen - generates pre-made seeds.
 *
 * Inputs:
 *  - idx_in is used to choose the pattern.
 *  - idx_in == 0 is used to denote no pattern.
 *  - idx_in == 1 generates all zeros.
 */
module seed_gen(input wire clk_in,
                input wire rst_in,
                input wire[LOG_NUM_SEED-1:0] idx_in,
                input wire en_in,
                vga_if vga_in,
                output logic alive_out,
                output logic wr_en_out,
                vga_if vga_out);
    localparam SEED_SIZE = 50;
    localparam SEED_START = (BOARD_SIZE - SEED_SIZE) / 2;
    localparam SEED_END = SEED_START + SEED_SIZE;

    // ------------------------------------------------------------ First Stage
    vga_t vga1;

    logic[5:0] x, y;
    logic in_pattern;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            x <= 0;
            y <= 0;
            in_pattern <= 0;
            vga1 <= '{hcount: 0, vcount: 0, hsync: 0, vsync: 0, blank: 0};
        end else begin
            x <= vga_in.hcount - SEED_START;
            y <= vga_in.vcount - SEED_START;
            in_pattern <=
                (vga_in.hcount >= SEED_START && vga_in.hcount < SEED_END)
                && (vga_in.vcount >= SEED_START && vga_in.vcount < SEED_END);
            vga1 <= '{hcount: vga_in.hcount, vcount: vga_in.vcount,
                      hsync: vga_in.hsync, vsync: vga_in.vsync,
                      blank: vga_in.blank};
        end
    end

    // ----------------------------------------------------------- Second Stage
    logic seed_alive;
    seed_select s(.seed_idx(idx_in), .x_in(x), .y_in(y),
                  .alive_out(seed_alive));

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            wr_en_out <= 0;
            alive_out <= 0;
            vga_out.hcount <= 0;
            vga_out.vcount <= 0;
            vga_out.hsync <= 0;
            vga_out.vsync <= 0;
            vga_out.blank <= 0;
        end else begin
            wr_en_out <= en_in;
            alive_out <= idx_in == 0 ? 0 : in_pattern && seed_alive;
            vga_out.hcount <= vga1.hcount;
            vga_out.vcount <= vga1.vcount;
            vga_out.hsync <= vga1.hsync;
            vga_out.vsync <= vga1.vsync;
            vga_out.blank <= vga1.blank;
        end
    end
endmodule
`default_nettype wire

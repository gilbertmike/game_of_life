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
                  input wire start_in,
                  input wire[LOG_MAX_SPEED-1:0] speed_in,
                  input wire[WORD_SIZE-1:0] data_r_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                  input wire cursor_click_in,
                  output logic[LOG_MAX_ADDR-1:0] addr_r_out,
                  output logic[LOG_MAX_ADDR-1:0] addr_w_out,
                  output logic[WORD_SIZE-1:0] data_w_out,
                  output logic wr_en_out,
                  output logic done_out);
    // Central game logic FSM
    logic update;
    logic[7:0] counter;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            update <= 1'b0;
            counter <= 0;
        end else if (start_in) begin
            update <= counter >= 8'hFF - speed_in ? 1'b1 : 1'b0;
            counter <= counter + speed_in;
        end else begin
            update <= 1'b0;
        end
    end

    logic fetch_stall, fetch_done;
    pos_t fetch_x, fetch_y;
    window_row_t fetch_window[2:0];
    logic_fetcher fetch(.clk_in(clk_in), .start_in(start_in), .data_in(data_r_in),
                        .window_out(fetch_window), .addr_out(addr_r_out), .x_out(fetch_x),
                        .y_out(fetch_y), .stall_out(fetch_stall), .done_out(fetch_done));

    logic rule_stall, rule_done;
    logic[NUM_PE-1:0] rule_state;
    logic_rule rule(.clk_in(clk_in), .stall_in(fetch_stall), .x_in(fetch_x),
                    .y_in(fetch_y), .window_in(fetch_window),
                    .done_in(fetch_done), .cursor_x_in(cursor_x_in),
                    .cursor_y_in(cursor_y_in),
                    .cursor_click_in(cursor_click_in), .update_in(update),
                    .state_out(rule_state), .stall_out(rule_stall),
                    .done_out(rule_done));

    // Delay writeback start by 2 cycles
    logic wb_start0;
    logic wb_start;
    always_ff @(posedge clk_in) begin
        wb_start0 <= start_in;
        wb_start <= wb_start0;
    end
    logic wb_done, rst_done;
    logic_writeback wb(.clk_in(clk_in), .stall_in(rule_stall),
                       .done_in(rule_done), .start_in(wb_start),
                       .next_state_in(rule_state), .wr_en_out(wr_en_out),
                       .addr_w_out(addr_w_out), .data_w_out(data_w_out),
                       .done_out(wb_done));
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            rst_done <= 1'b1;
        end else if (start_in) begin
            rst_done <= 1'b0;
        end
    end
    assign done_out = rst_done || wb_done;
endmodule
`default_nettype wire

`default_nettype none
/**
 * life_fetcher - generates tuple of (x, y, window, stall)
 *
 * Output:
 *  - The window is centered at cell (x, y).
 *  - The output will start from (0, 0), the top left cell.
 *  - If stall is asserted, then the output is invalid and will be
 *    resumed eventually.
 *
 * Timing:
 *  - Single pipeline stage with stall signal.
 */
module logic_fetcher(input wire clk_in,
                     input wire start_in,
                     input wire[WORD_SIZE-1:0] data_in,
                     output logic[WINDOW_WIDTH-1:0] window_out[2:0],
                     output logic[LOG_MAX_ADDR-1:0] addr_out,
                     output logic[LOG_BOARD_SIZE-1:0] x_out, y_out,
                     output logic stall_out,
                     output logic done_out);
    localparam WORDS_PER_ROW = BOARD_SIZE / WORD_SIZE;
    localparam STRIDE = NUM_PE;

    enum logic[3:0] {
        SEARCH, PRE_FETCH_ROW_0, FETCH_ROW_0, FETCH_ROW_1, FETCH_ROW_2,
        FETCH_ROW_3, FETCH_ROW_4, FETCH_ROW_5, WINDOW, READY
    } cache_state;

    // cache data structures
    addr_t buf_addr, buf_addr_last;  // address of first word in buffer
    logic valid;
    logic[0:2*WORD_SIZE-1] buffer[2:0];

    // addresses of first and last words making up a window.
   logic under_x, over_x, under_y, over_y;
    addr_t cur_addr, row_above_addr, word_addr, word_addr_last;
    logic[LOG_WORD_SIZE-1:0] word_idx;  // index of x_out - 1 in cache
    logic cache_hit;
    always_comb begin
        under_x = x_out == 0;
        over_x = x_out >= BOARD_SIZE - WINDOW_WIDTH + 2;
        under_y = y_out == 0;
        over_y = y_out == BOARD_SIZE-1;

        cur_addr = y_out*WORDS_PER_ROW + x_out/WORD_SIZE;
        row_above_addr = (y_out-1)*WORDS_PER_ROW + x_out/WORD_SIZE;
        if (under_x) begin
            word_addr = cur_addr - 1;
            word_addr_last = row_above_addr;
        end else if (over_x) begin
            word_addr = row_above_addr;
            word_addr_last = row_above_addr - WORDS_PER_ROW + 2;
        end else begin
            word_addr = row_above_addr;
            word_addr_last = row_above_addr + 1;
        end

        cache_hit = (word_addr == buf_addr)
                  && (word_addr_last == buf_addr_last) && valid;
        word_idx = x_out[LOG_WORD_SIZE-1:0] - 1;
    end

    logic last_x_in_row, last_y_in_col;
    assign last_x_in_row = x_out == BOARD_SIZE-NUM_PE;
    assign last_y_in_col = y_out == BOARD_SIZE-1;
    always_ff @(posedge clk_in) begin
        if (start_in) begin
            x_out <= 0;
            y_out <= 0;
            done_out <= 0;
            stall_out <= 1;

            {buffer[2], buffer[1], buffer[0]} <= {3*2*WORD_SIZE{1'b0}};
            buf_addr <= 0;
            addr_out <= 0;
            valid <= 0;
            cache_state <= SEARCH;  // lookup from cache
        end else if (!stall_out && !done_out) begin  // ready to move
            if (last_x_in_row && last_y_in_col) begin
                x_out <= 0;
                y_out <= 0;
                done_out <= 1;
                stall_out <= 1;
            end else if (last_x_in_row) begin
                x_out <= 0;
                y_out <= y_out + 1;
                stall_out <= 1;
            end else begin
                x_out <= x_out + STRIDE;
                stall_out <= 1;
            end
            cache_state <= SEARCH;
        end else if (!done_out) begin  // cache state machine
            case (cache_state)
                SEARCH: begin
                    if (cache_hit) begin
                        cache_state <= READY;

                        window_out[2] <= buffer[2][word_idx+:WINDOW_WIDTH];
                        window_out[1] <= buffer[1][word_idx+:WINDOW_WIDTH];
                        window_out[0] <= buffer[0][word_idx+:WINDOW_WIDTH];
                        stall_out <= 0;
                    end else begin
                        buf_addr <= word_addr;
                        buf_addr_last <= word_addr_last;
                        addr_out <= word_addr;
                        cache_state <= PRE_FETCH_ROW_0;
                        valid <= 0;
                    end
                end
                PRE_FETCH_ROW_0: begin
                    addr_out <= addr_out + WORDS_PER_ROW;
                    cache_state <= FETCH_ROW_0;
                end
                FETCH_ROW_0: begin
                    addr_out <= addr_out + WORDS_PER_ROW;
                    cache_state <= FETCH_ROW_1;
                    buffer[2][0+:WORD_SIZE] <= under_x || under_y ? 0
                                                                  : data_in;
                end
                FETCH_ROW_1: begin
                    addr_out <= word_addr_last;
                    cache_state <= FETCH_ROW_2;

                    buffer[1][0+:WORD_SIZE] <= under_x ? 0 : data_in;
                end
                FETCH_ROW_2: begin
                    addr_out <= addr_out + WORDS_PER_ROW;
                    cache_state <= FETCH_ROW_3;

                    buffer[0][0+:WORD_SIZE] <= under_x || over_y ? 0 :data_in;
                end
                FETCH_ROW_3: begin
                    addr_out <= addr_out + WORDS_PER_ROW;
                    cache_state <= FETCH_ROW_4;

                    buffer[2][WORD_SIZE+:WORD_SIZE] <=
                        over_x || under_y ? 0 : data_in;
                end
                FETCH_ROW_4: begin
                    cache_state <= FETCH_ROW_5;

                    buffer[1][WORD_SIZE+:WORD_SIZE] <= over_x ? 0 : data_in;
                end
                FETCH_ROW_5: begin
                    cache_state <= SEARCH;

                    buffer[0][WORD_SIZE+:WORD_SIZE] <=
                        over_x || over_y ? 0 :data_in;
                    valid <= 1;
                end
                READY: begin /* wait */ end
                default: begin
                    cache_state <= READY;
                end
            endcase
        end
    end
endmodule
`default_nettype wire

`default_nettype none
/**
 * logic_rule - computes next board state.
 * 
 * Timing:
 *  - Single pipleline stage with stall signal.
 */
module logic_rule(input wire clk_in, stall_in, done_in,
                  input wire[LOG_BOARD_SIZE-1:0] x_in,
                  input wire[LOG_BOARD_SIZE-1:0] y_in,
                  input wire[WINDOW_WIDTH-1:0] window_in[2:0],
                  input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                  input wire cursor_click_in,
                  input wire update_in,
                  output logic[NUM_PE-1:0] state_out,
                  output logic stall_out, done_out);
    logic[3:0] neighbor_cnt[NUM_PE-1:0];
    logic[NUM_PE-1:0] old_state;
    logic[NUM_PE-1:0] next_state;
    always_comb begin
        for (integer i = NUM_PE-1; i >= 0; i--) begin
            old_state[i] = window_in[1][i+1];
            neighbor_cnt[i] = window_in[2][i+2] + window_in[2][i+1]
                            + window_in[2][i] + window_in[1][i+2]
                            + window_in[1][i] + window_in[0][i+2]
                            + window_in[0][i+1] + window_in[0][i];
            if (update_in) begin
                if (old_state[i]) begin
                    if (neighbor_cnt[i] > 3) // overpopulation
                        next_state[i] = 1'b0;
                    else if (neighbor_cnt[i] < 2) // underpopulation
                        next_state[i] = 1'b0;
                    else // lives on
                        next_state[i] = 1'b1;
                end else if (neighbor_cnt[i] == 3) // reproduction
                    next_state[i] = 1'b1;
                else
                    next_state[i] = 1'b0;
            end else begin
                next_state[i] = window_in[1][i+1];
            end
        end
    end

    always_ff @(posedge clk_in) begin
        for (integer i = NUM_PE-1; i >= 0; i--) begin
            if (((x_in + NUM_PE-1-i) == cursor_x_in) && (y_in == cursor_y_in)
                    && cursor_click_in && !stall_in)
                state_out[i] <= !old_state[i];
            else if (!stall_in)
                state_out[i] <= next_state[i];
        end
        stall_out <= stall_in;
        done_out <= done_in;
    end
endmodule
`default_nettype wire

`default_nettype none
/**
 * logic_writeback - buffers next word and sends it out.
 *
 * Timing:
 *  - Single pipeline stage.
 */
module logic_writeback(input wire clk_in, stall_in, start_in, done_in,
                       input wire[NUM_PE-1:0] next_state_in,
                       output logic wr_en_out, done_out,
                       output logic[LOG_MAX_ADDR-1:0] addr_w_out,
                       output logic[WORD_SIZE-1:0] data_w_out);
    logic[LOG_WORD_SIZE-1:0] buf_size;
    always_ff @(posedge clk_in) begin
        if (start_in) begin
            buf_size <= 0;
            addr_w_out <= MAX_ADDR-1;
            wr_en_out <= 0;
            data_w_out <= 0;
        end else if (!stall_in) begin
            buf_size <= buf_size + NUM_PE;
            data_w_out <= {data_w_out[WORD_SIZE-NUM_PE-1:0], next_state_in};
            if (buf_size == WORD_SIZE-NUM_PE) begin
                wr_en_out <= 1;
                addr_w_out <= addr_w_out + 1;
            end else begin
                wr_en_out <= 0;
            end
        end else begin
            wr_en_out <= 0;
        end
        done_out <= done_in;
    end
endmodule
`default_nettype wire

`default_nettype none
module new_logic(input wire clk_in,
                 input wire rst_in,
                 input wire start_in,
                 input wire[LOG_MAX_SPEED-1:0] speed_in,
                 input wire[WORD_SIZE-1:0] data_r_in,
                 input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                 input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                 input wire cursor_click_in,
                 output logic[LOG_MAX_ADDR-1:0] addr_r_out,
                 output logic[LOG_MAX_ADDR-1:0] addr_w_out,
                 output logic[WORD_SIZE-1:0] data_w_out,
                 output logic wr_en_out,
                 output logic done_out);
    
endmodule
`default_nettype wire

`default_nettype none
/**
 * new_fsm - Generates x_out, y_out, and done_out for fetch stage.
 *
 * Inputs:
 *  - start_in and fetch_ready_in has to be pulses.
 *
 * Operations:
 *  - When reset, done_out is 1
 *  - When started, done_out is 0, x_out == 0, y_out == 0.
 *  - When fetch_ready_in is asserted, x_out and y_out will increment in the
 *    next cycle.
 *  - done_out is asserted again when x_out and y_out wraps around to 0.
 */
module new_fsm(input wire clk_in,
               input wire rst_in,
               input wire start_in,
               input wire fetch_ready_in,
               output logic[LOG_BOARD_SIZE-1:0] x_out, y_out
               output logic done_out);
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            done_out <= 1;
            x_out <= 0;
            y_out <= 0;
        end else if (done_out && start_in) begin
            done_out <= 0;
            x_out <= 0;
            y_out <= 0;
        end else if (!done_out && fetch_ready_in) begin
            x_out <= x_out + 1;
            y_out <= y_out + (x_out == BOARD_SIZE-1);
            done_out <= (x_out == BOARD_SIZE-1) && (y_out == BOARD_SIZE-1);
        end
    end
endmodule
`default_nettype wire

`default_nettype none
module new_fetch(input wire clk_in,
                 input wire done_in,
                 input wire[WORD_SIZE-1:0] data_in,
                 input wire[LOG_BOARD_SIZE-1:0] x_in, y_in,
                 output logic[WINDOW_WIDTH-1:0] window_out[0:2],
                 output logic[LOG_MAX_ADDR-1:0] addr_out,
                 output logic[LOG_BOARD_SIZE-1:0] x_out, y_out,
                 output logic stall_out,
                 output logic ready_out,
                 output logic done_out);
    enum logic[3:0] {
        DONE, ADDR_CALC, PRE_ROW0, ROW0, ROW1, ROW2, ROW3, ROW4, ROW5 } state;

    logic[2*WINDOW_WIDTH-1:0] buffer[0:2];

    logic under_x, over_x, under_y, over_y;
    logic[LOG_WORD_SIZE-1:0] start_idx_in_word;
    logic[LOG_WORD_SIZE:0] start_idx;
    logic[LOG_MAX_ADDR-1:0] row0_addr, row3_addr;
    always_ff @(posedge clk_in) begin
        case (state)
            DONE: begin
                if (!done_in) begin
                    ready_out <= 1;
                    stall_out <= 1;
                    state <= ADDR_CALC;
                    done_out <= 0;
                end
            end
            PRE_ROW0: begin
                addr_out <= row1_addr;
                state <= ROW0;
            end
            ROW0: begin
                addr_out <= row2_addr;
                buffer[0][2*WINDOW_WIDTH-1 -: WINDOW_WIDTH] <=
                    under_x || under_y ? 0 : data_in;
                state <= ROW1;
            end
            ROW1: begin
                addr_out <= row3_addr;
                buffer[1][2*WINDOW_WIDTH-1 -: WINDOW_WIDTH] <=
                    under_x ? 0 : data_in;
                state <= ROW2;
            end
            ROW2: begin
                addr_out <= row4_addr;
                buffer[2][2*WINDOW_WIDTH-1 -: WINDOW_WIDTH] <=
                    under_x || over_y ? 0 : data_in;
                state <= ROW3;
            end
            ROW3: begin
                addr_out <= row5_addr;
                buffer[0][WINDOW_WIDTH-1 : 0] <=
                    under_x || under_y ? 0 : data_in;
                state <= ROW4;
            end
            ROW4: begin
                buffer[1][WINDOW_WIDTH-1 : 0] <= over_x ? 0 : data_in;
                state <= ROW5;
            end
            ROW5: begin
                buffer[2][WINDOW_WIDTH-1 : 0] <=
                    over_x || over_y ? 0 : data_in;
                state <= WINDOW_OUT;
            end
            WINDOW_OUT: begin
                $assert (stall_out == 1 && ready_out == 0) 
                else $error("WINDOW_OUT messed up :(");
                window_out <= buffer[start_idx -: WINDOW_WIDTH];
                stall_out <= 0;
                ready_out <= 1;
                if (done_in) begin
                    done_out <= 1;
                    state <= DONE;
                end else begin
                    state <= ADDR_CALC;
                end
            end
            ADDR_CALC: begin
                $assert (ready_out == 1 && stall_out == 0) 
                else $error("ADDR_CALC state messed up :(");

                under_x <= (x_in == 0);
                over_x <= (x_in >= BOARD_SIZE - (WINDOW - 2));
                under_y <= (y_in == 0);
                over_y <= (y_in == BOARD_SIZE - 1);
                start_idx_in_word <=
                    WORD_SIZE - 1 - x_in[LOG_WORD_SIZE-1:0];
                start_idx <= WINDOW_WIDTH + start_idx_in_word;

                x_out <= x_in;
                y_out <= y_in;

                addr_out <= (y_in - 1) * WORDS_PER_ROW
                            + ((x_in - 1) / WORD_SIZE);
                row1_addr <= y_in * WORDS_PER_ROW + ((x_in - 1) / WORD_SIZE);
                row2_addr <= (y_in + 1) * WORDS_PER_ROW
                            + ((x_in - 1) / WORD_SIZE);
                row3_addr <= (y_in - 1) * WORDS_PER_ROW
                            + ((x_in + WINDOW_WIDTH - 2) / WORD_SIZE);
                row4_addr <= y_in * WORDS_PER_ROW
                            + ((x_in + WINDOW_WIDTH - 2) / WORD_SIZE);
                row5_addr <= (y_in + 1) * WORDS_PER_ROW
                            + ((x_in + WINDOW_WIDTH - 2) / WORD_SIZE);
 
                ready_out <= 0;
                stall_out <= 1;
                state <= PRE_ROW0;
            end
        endcase
    end
endmodule
`default_nettype wire

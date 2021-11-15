`include "common.svh"

`default_nettype none
module life_logic(input wire clk_in,
                  input wire start_in,
                  input wire[LOG_MAX_SPEED-1:0] speed_in,
                  input wire[LOG_WORD_SIZE-1:0] data_r_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                  input wire cursor_click_in,
                  output logic[LOG_MAX_ADDR-1:0] addr_r_out,
                  output logic[LOG_MAX_ADDR-1:0] addr_w_out,
                  output logic[LOG_WORD_SIZE-1:0] data_out,
                  output logic wr_en_out,
                  output logic done_out);
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
 */
module logic_fetcher(input wire clk_in,
                     input wire start_in,
                     input wire[WORD_SIZE-1:0] data_in,
                     output logic[WINDOW_WIDTH-1:0] window_out[2:0],
                     output logic[LOG_MAX_ADDR-1:0] addr_out,
                     output logic[LOG_BOARD_SIZE-1:0] x_out, y_out,
                     output logic stall_out);
    localparam WORDS_PER_ROW = BOARD_SIZE / WORD_SIZE;
    localparam STRIDE = WINDOW_WIDTH-2;

    enum logic[1:0] { DONE, ROW_START_0, ROW_START_1, STEADY } state;
    enum logic[1:0] { IDLE, FETCH_ROW_0, FETCH_ROW_1, FETCH_ROW_2 } row_state;

    logic[2*WORD_SIZE-1:0] buffer[2:0];

    // control state machine
    logic last_x_in_row, last_y_in_col;
    assign last_x_in_row = x_out == BOARD_SIZE-1;
    assign last_y_in_col = y_out == BOARD_SIZE-1;
    always_ff @(posedge clk_in) begin
        if (start_in) begin
            state <= ROW_START_0;
            x_out <= 0;
            y_out <= 0;
        end else begin
            case (state)
                ROW_START_0:
                    if (row_state == FETCH_ROW_2) state <= ROW_START_1;
                ROW_START_1:
                    if (row_state == FETCH_ROW_2) begin
                        state <= STEADY;
                        stall_out <= 0;
                    end
                STEADY: begin
                    if (last_x_in_row && last_y_in_col) begin
                        state <= DONE;
                        x_out <= 0;
                        y_out <= 0;
                        stall_out <= 1;
                    end else if (last_x_in_row) begin
                        state <= ROW_START_0;
                        x_out <= 0;
                        y_out <= y_out + 1;
                        stall_out <= 1;
                    end else begin
                        x_out <= x_out + STRIDE;
                    end
                end
                DONE: begin /* wait for start */ end
            endcase
        end
    end


    // address calculation logic
    // 
    // Fetches three rows at a time. Maintains the invariants:
    //  - When row_state == FETCH_ROW_i then row i (from top) is in data_in.
    logic last_x_in_word, starting_row;
    assign last_x_in_word = x_out[LOG_WORD_SIZE-1:0] == WORD_SIZE-1;
    assign starting_row = state == ROW_START_0 || state == ROW_START_1;
    always_ff @(posedge clk_in) begin
        if (start_in) begin
            row_state <= FETCH_ROW_0;
            addr_out <= 0;
        end else begin
            case (row_state)
                IDLE: if (last_x_in_word) row_state <= FETCH_ROW_0;
                FETCH_ROW_0: begin
                    row_state <= FETCH_ROW_1;
                    // next row, same col
                    addr_out <= addr_out + WORDS_PER_ROW;
                end
                FETCH_ROW_1: begin
                    row_state <= FETCH_ROW_2;
                    addr_out <= addr_out + WORDS_PER_ROW; // next row, same col
                end
                FETCH_ROW_2: begin
                    if (last_x_in_row) begin
                        // addr points to col 0. To start the new row of
                        // windows, just move one row up.
                        addr_out <= addr_out - WORDS_PER_ROW;
                        row_state <= FETCH_ROW_0;
                    end else if (starting_row || last_x_in_word) begin
                        // two rows up, one col right
                        addr_out <= addr_out - 2*WORDS_PER_ROW + 1;
                        if (starting_row || last_x_in_word)
                            row_state <= FETCH_ROW_0;
                        else
                            row_state <= IDLE;
                    end
                end
                default: begin
                    row_state <= FETCH_ROW_0;
                    addr_out <= 0;
                end
            endcase
        end
    end

    // buffer population logic
    always_ff @(posedge clk_in) begin
        if (start_in) begin
            x_out <= 0;
            y_out <= 0;
            stall_out <= 1;
        end else if (state == ROW_START_0) begin
            case (row_state)
                FETCH_ROW_0: buffer[2][2*WORD_SIZE-1] <= data_in[WORD_SIZE-1];
                FETCH_ROW_1: buffer[1][2*WORD_SIZE-1] <= data_in[WORD_SIZE-1];
                FETCH_ROW_2: buffer[0][2*WORD_SIZE-1] <= data_in[WORD_SIZE-1];
            endcase
        end else if (state == ROW_START_1) begin
            case (row_state)
                FETCH_ROW_0: buffer[2][2*WORD_SIZE-2:WORD_SIZE-1] <= data_in;
                FETCH_ROW_1: buffer[1][2*WORD_SIZE-2:WORD_SIZE-1] <= data_in;
                FETCH_ROW_2: begin
                    buffer[0][2*WORD_SIZE-2:WORD_SIZE-1] <= data_in;
                end
            endcase
        end else if (state == STEADY) begin
            case (row_state)
                IDLE: begin
                    buffer[2] <= buffer[2] << 1;
                    buffer[1] <= buffer[1] << 1;
                    buffer[0] <= buffer[0] << 1;
                end
                FETCH_ROW_0: begin
                    buffer[2] <= {buffer[2][2*WORD_SIZE-2:WORD_SIZE-1],
                                  data_in};
                    buffer[1] <= buffer[1] << 1;
                    buffer[0] <= buffer[0] << 1;
                end
                FETCH_ROW_1: begin
                    buffer[2] <= buffer[2] << 1;
                    buffer[1] <= {buffer[1][2*WORD_SIZE-1:WORD_SIZE],
                                  data_in,
                                  1'b0};
                    buffer[0] <= buffer[0] << 1;
                end
                FETCH_ROW_2: begin
                    buffer[2] <= buffer[2] << 1;
                    buffer[1] <= buffer[1] << 1;
                    buffer[0] <= {buffer[0][2*WORD_SIZE-1:WORD_SIZE+1],
                                  data_in,
                                  2'b0};
                end
            endcase
        end
    end

    // window logic
    always_comb begin
        for (integer i = 0; i < 3; i++) begin
            window_out[i] = buffer[i][2*WORD_SIZE-1:2*WORD_SIZE-WINDOW_WIDTH];
        end
    end
endmodule
`default_nettype wire

`default_nettype none
module logic_rule(input wire clk_in, stall_in,
                  input wire[LOG_BOARD_SIZE-1:0] x_in,
                  input wire[LOG_BOARD_SIZE-1:0] y_in,
                  input wire[WINDOW_WIDTH-1:0] window_in[2:0],
                  input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                  input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                  input wire cursor_click_in,
                  input wire update_in,
                  output logic[NUM_PE-1:0] state_out,
                  output logic stall_out);
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
            if (x_in + NUM_PE-1-i == cursor_x_in && y_in == cursor_y_in
                    && cursor_click_in && !stall_in)
                state_out[i] <= !old_state[i];
            else if (!stall_in)
                state_out[i] <= next_state[i];
        end
        stall_out <= stall_in;
    end
endmodule

`default_nettype none
module logic_writeback(input wire clk_in, stall_in, start_in,
                       input wire[NUM_PE-1:0] next_state_in,
                       output logic wr_en_out,
                       output logic[LOG_MAX_ADDR-1:0] addr_w_out,
                       output logic[WORD_SIZE-1:0] data_w_out);
    logic[LOG_WORD_SIZE-1:0] buffer_idx;
    always_ff @(posedge clk_in) begin
        if (start_in) begin
            buffer_idx <= WORD_SIZE-1;
            addr_w_out <= MAX_ADDR-1;
            wr_en_out <= 0;
            data_w_out <= 0;
        end else if (!stall_in) begin
            buffer_idx <= buffer_idx - NUM_PE;
            data_w_out <= {data_w_out[WORD_SIZE-3:0], next_state_in};
            if (buffer_idx < WORD_SIZE - NUM_PE) begin
                wr_en_out <= 0;
            end else begin
                wr_en_out <= 1;
                addr_w_out <= addr_w_out + 1;
            end
        end
    end
endmodule
`default_nettype wire


`include "common.svh"

`default_nettype none
module renderer(input wire clk_in, start_in,
                input wire[WORD_SIZE-1:0] data_in,
                input wire[LOG_MAX_ADDR-1:0] view_x_in, view_y_in,
                output wire[LOG_MAX_ADDR-1:0] addr_r_out,
                output logic done_out,
                output logic[11:0] pix_out,
                output logic vsync_out, hsync_out);

    logic [10:0] hcount;
    logic [9:0] vcount;
    logic[LOG_SCREEN_HEIGHT-1:0] vsync;
    logic[LOG_SCREEN_WIDTH-1:0] hsync;
    logic blank;
    
    //initiate xvga instance
    xvga xvga1(.clk_in(clk_in),
           .hcount_out(hcount),
           .vcount_out(vcount),
           .vsync_out(vsync),
           .hsync_out(hsync),
           .blank_out(blank));

endmodule

//xvga module copied from lab 3: change parameters!
module xvga(input wire clk_in,
            output logic [10:0] hcount_out,    // pixel number on current line
            output logic [9:0] vcount_out,     // line number
            output logic[LOG_SCREEN_HEIGHT-1:0] vsync_out, 
            output logic[LOG_SCREEN_WIDTH-1:0] hsync_out,
            output logic blank_out);

    parameter  H_FP = 24;                 // horizontal front porch
    parameter  H_SYNC_PULSE = 136;        // horizontal sync
    parameter  H_BP = 160;                // horizontal back porch

    parameter  V_FP = 3;                  // vertical front porch
    parameter  V_SYNC_PULSE = 6;          // vertical sync 
    parameter  V_BP = 29;                 // vertical back porch

    // horizontal: 1344 pixels total
    // display 1024 pixels per line
    logic hblank,vblank;
    logic hsyncon,hsyncoff,hreset,hblankon;
    assign hblankon = (hcount_out == (LOG_SCREEN_WIDTH -1));    
    assign hsyncon = (hcount_out == (LOG_SCREEN_WIDTH + H_FP - 1));  //1047
    assign hsyncoff = (hcount_out == (LOG_SCREEN_WIDTH + H_FP + H_SYNC_PULSE - 1));  // 1183
    assign hreset = (hcount_out == (LOG_SCREEN_WIDTH + H_FP + H_SYNC_PULSE + H_BP - 1));  //1343

    // vertical: 806 lines total
    // display 768 lines
    logic vsyncon,vsyncoff,vreset,vblankon;
    assign vblankon = hreset & (vcount_out == (LOG_SCREEN_HEIGHT - 1));   // 767 
    assign vsyncon = hreset & (vcount_out == (LOG_SCREEN_HEIGHT + V_FP - 1));  // 771
    assign vsyncoff = hreset & (vcount_out == (LOG_SCREEN_HEIGHT + V_FP + V_SYNC_PULSE - 1));  // 777
    assign vreset = hreset & (vcount_out == (LOG_SCREEN_HEIGHT + V_FP + V_SYNC_PULSE + V_BP - 1)); // 805

    // sync and blanking
    logic next_hblank,next_vblank;
    assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
    assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
    always_ff @(posedge clk_in) begin
        hcount_out <= hreset ? 0 : hcount_out + 1;
        hblank <= next_hblank;
        hsync_out <= hsyncon ? 0 : hsyncoff ? 1 : hsync_out;  // active low

        vcount_out <= hreset ? (vreset ? 0 : vcount_out + 1) : vcount_out;
        vblank <= next_vblank;
        vsync_out <= vsyncon ? 0 : vsyncoff ? 1 : vsync_out;  // active low

        blank_out <= next_vblank | (next_hblank & ~hreset);
    end
endmodule

//render_fetch module, to fetch info on squares within view window
module render_fetch (input wire clk_in, start_in,
                     input wire[10:0] hcount_in,
                     input wire[9:0] vcount_in,
                     input wire[LOG_BOARD_SIZE-1:0] view_x_in, view_y_in,
                     input wire[WORD_SIZE-1:0] data_r_in,
                     output logic[LOG_MAX_ADDR-1:0] addr_r_out,
                     output logic is_alive_out);
                     
    localparam WORDS_PER_ROW = BOARD_SIZE / WORD_SIZE;
    // cell in view coordinate
    pos_t view_cell_x, view_cell_y;
    // cell in board coord
    pos_t board_cell_x, board_cell_y;
    
    always_comb begin
        //shift from pixel coord to cell coord
        view_cell_x = hcount_in >> LOG_CELL_SIZE;
        view_cell_y = vcount_in >> LOG_CELL_SIZE;
        board_cell_x = view_x_in + view_cell_x;
        board_cell_y = view_y_in + view_cell_y;
    end

    always_ff @(posedge clk_in) begin
       if (start_in) begin
           addr_r_out <= 0;
           is_alive_out <= 0;
       end else begin
           addr_r_out <= board_cell_y * WORDS_PER_ROW + board_cell_x >> LOG_WORD_SIZE;
           is_alive_out <= data_r_in[WORD_SIZE-1-board_cell_x[LOG_WORD_SIZE-1:0]];
       end
    end
    
endmodule
`default_nettype wire

`default_nettype none
/**
 * cursor_render - renders a highlighted square.
 * 
 * Assumptions:
 *  - view starts at pixel (0, 0).
 *  - cursor_x_in and cursor_y_in given in board coordinate.
 *
 * Output:
 *  - returns white when pixel is at border of the cell the cursor is on.
 *  - black otherwise.
 *
 * Timing:
 *  - Stage one pipeline.
 */
module cursor_render(input wire clk_in,
                     input wire[10:0] hcount_in,
                     input wire[9:0] vcount_in,
                     input wire[LOG_BOARD_SIZE-1:0] view_x_in,
                     input wire[LOG_BOARD_SIZE-1:0] view_y_in,
                     input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                     input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                     output logic[11:0] pix_out);
    localparam CELL_SIZE = BOARD_SIZE / VIEW_SIZE;
    localparam LOG_CELL_SIZE = LOG_BOARD_SIZE - LOG_VIEW_SIZE;

    pos_t cursor_x_in_view, cursor_y_in_view;
    logic[10:0] cursor_x_in_pix;
    logic[9:0] cursor_y_in_pix;
    logic in_x_range, in_y_range, at_x_edge, at_y_edge;
    always_comb begin
        cursor_x_in_view = cursor_x_in - view_x_in;
        cursor_y_in_view = cursor_y_in - view_y_in;
        cursor_x_in_pix = cursor_x_in_view << LOG_CELL_SIZE;
        cursor_y_in_pix = cursor_y_in_view << LOG_CELL_SIZE;

        in_x_range = (hcount_in >= cursor_x_in_pix)
                        && (hcount_in <= cursor_x_in_pix + CELL_SIZE-1);
        in_y_range = (vcount_in >= cursor_y_in_pix)
                        && (vcount_in <= cursor_y_in_pix + CELL_SIZE-1);
        at_x_edge = (hcount_in == cursor_x_in_pix)
                        || (hcount_in == cursor_x_in_pix + CELL_SIZE-1);
        at_y_edge = (vcount_in == cursor_y_in_pix)
                        || (vcount_in == cursor_y_in_pix + CELL_SIZE-1);
    end

    always_ff @(posedge clk_in) begin
        if ((at_x_edge && in_y_range) || (at_y_edge && in_x_range))
            pix_out <= 12'hFFF;
        else
            pix_out <= 12'b0;
    end
endmodule
`default_nettype wire

`default_nettype none
/**
 * stat_render - counts number of alive squares in a frame, then
 * creates an updating graph keeping tally of alive squares.
 *
 * Output:
 *  - returns pix_out corresponding to the graph
 */
module stat_render(input wire clk_130mhz,
                   input wire rst_in,
                   input wire[10:0] hcount_in,
                   input wire[9:0] vcount_in,
                   input wire is_alive_in,
                   output logic[11:0] pix_out);
        parameter GRAPH_HEIGHT = 200, GRAPH_WIDTH = 200;
        parameter HISTORY_LEN = 25;
        parameter GRAPH_ORIGIN_X = 800, GRAPH_ORIGIN_Y = 16; //origin positioned at top left corner
        localparam SAMPLE_PIX = GRAPH_WIDTH / HISTORY_LEN;
        localparam LOG_HISTORY_LEN = $clog2(HISTORY_LEN) + 1;
        localparam LOG_SAMPLE_PIX = $clog2(SAMPLE_PIX);

        logic[4:0] frame_cnt;
        logic[15:0] max_tally;
        logic[4:0] log_max_tally;
        logic[HISTORY_LEN:0][15:0] tally;
        always_ff @(posedge clk_130mhz) begin
            if (rst_in) begin
                frame_cnt <= 0;
                max_tally <= 1;
                log_max_tally <= 0;
            end else if (hcount_in == SCREEN_WIDTH-1 && vcount_in == SCREEN_HEIGHT-1) begin
                frame_cnt <= frame_cnt + 1;
                if (frame_cnt == 5'b1_1111) begin
                    tally <= {tally[HISTORY_LEN:1], 16'b0};
                end
            end else if (frame_cnt == 5'b0) begin
                tally[0] <= tally[0] + is_alive_in;
                if (tally[0] > max_tally) begin
                    max_tally <= max_tally << 1;
                    log_max_tally <= log_max_tally + 1;
                end
            end
        end
        
        logic[LOG_HISTORY_LEN-1:0] sample_idx;
        logic[9:0] sample_height;
        logic[9:0] sample_vcount;
        logic in_range_x, in_range_y, on_point;
        always_comb begin
            in_range_x = hcount_in > GRAPH_ORIGIN_X
                && hcount_in < (GRAPH_ORIGIN_X + GRAPH_WIDTH);
            in_range_y = vcount_in > GRAPH_ORIGIN_Y
                && vcount_in < (GRAPH_ORIGIN_Y + GRAPH_HEIGHT);
            sample_idx = (hcount_in - GRAPH_ORIGIN_X) >> LOG_SAMPLE_PIX;
            sample_height =
                (GRAPH_HEIGHT * tally[sample_idx]) << log_max_tally;
            sample_vcount = GRAPH_ORIGIN_Y + GRAPH_HEIGHT - sample_height;
            on_point = vcount_in == sample_vcount;
        end

        //draws x and y axis for graph
        always_ff @(posedge clk_130mhz) begin
            if ((vcount_in == GRAPH_ORIGIN_Y + GRAPH_HEIGHT)
                    && in_range_x) begin
                pix_out <= 12'hFFF;
            end else if (hcount_in == GRAPH_ORIGIN_X && in_range_y) begin
                pix_out <= 12'hFFF;
            end else if (in_range_x && in_range_y && on_point) begin
                pix_out <= 12'hFFF;
            end else begin
                pix_out <= 12'h0;
            end
        end
endmodule
`default_nettype wire


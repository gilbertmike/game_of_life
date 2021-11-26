`include "common.svh"

`default_nettype none
/**
 * renderer - renders the game screen.
 *
 * Output:
 *  - Standard VGA output.
 *  - During blank period, done_out is asserted.
 *
 * Timing:
 *  - Three stage pipeline.
 */
module renderer(input wire clk_in, vclk_in, rst_in,
                input wire[WORD_SIZE-1:0] data_in,
                input wire[LOG_BOARD_SIZE-1:0] view_x_in, view_y_in,
                input wire[LOG_BOARD_SIZE-1:0] cursor_x_in, cursor_y_in,
                output wire[LOG_MAX_ADDR-1:0] addr_r_out,
                output logic done_out,
                output logic[11:0] pix_out,
                output logic vsync_out, hsync_out);
    //initiate xvga instance
    logic [10:0] hcount0;
    logic [9:0] vcount0;
    logic hsync0, vsync0, blank0;
    xvga xvga1(
        .vclk_in(vclk_in),
        .hcount_out(hcount0),
        .vcount_out(vcount0),
        .vsync_out(vsync0),
        .hsync_out(hsync0),
        .blank_out(blank0));

    // Sample user input so no update happens within a frame
    pos_t view_x, view_y, cursor_x, cursor_y;
    always_ff @(posedge clk_in) begin
        if (hcount0 == 0 && vcount0 == 0) begin
            view_x <= view_x_in;
            view_y <= view_y_in;
            cursor_x <= cursor_x_in;
            cursor_y <= cursor_y_in;
        end
    end

    // First stage pipeline (counted from hcount, vcount) --------------------

    logic is_alive;
    render_fetch fetch(.clk_in(clk_in),
                       .hcount_in(hcount0), .vcount_in(vcount0),
                       .view_x_in(view_x), .view_y_in(view_y),
                       .data_r_in(data_in), .addr_r_out(addr_r_out),
                       .is_alive_out(is_alive));

    // Second stage pipeline (counted from hcount, vcount) -------------------

    logic[10:0] hcount1;
    logic[9:0] vcount1;
    logic hsync1, vsync1, blank1;
    always_ff @(posedge clk_in) begin
        hcount1 <= hcount0;
        vcount1 <= vcount0;
        {hsync1, vsync1, blank1} <= {hsync0, vsync0, blank0};
    end

    logic[11:0] cell_pix;
    cell_render cell_r(.clk_in(clk_in), .is_alive_in(is_alive),
                       .hcount_in(hcount1), .vcount_in(vcount1),
                       .pix_out(cell_pix));

    logic[11:0] cursor_pix;
    cursor_render cursor_r(.clk_in(clk_in), .hcount_in(hcount1),
                           .vcount_in(vcount1), .view_x_in(view_x),
                           .view_y_in(view_y), .cursor_x_in(cursor_x),
                           .cursor_y_in(cursor_y), .pix_out(cursor_pix));
                           
    logic[11:0] stat_pix;
    stat_render stat_r(.clk_in(clk_in),
                       .rst_in(rst_in),
                       .hcount_in(hcount1),
                       .vcount_in(vcount1),
                       .is_alive_in(is_alive),
                       .pix_out(stat_pix));
            
    logic[11:0] fence_pix;
    fence_render fence_r(.clk_in(clk_in),
                         .rst_in(rst_in),
                         .hcount_in(hcount1),
                         .vcount_in(vcount1),
                         .pix_out(fence_pix));

    // Third stage pipeline --------------------------------------------------

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            pix_out <= 0;
            done_out <= 1;
        end else begin
            pix_out[11:8] <= blank1 ? 0 : cell_pix[11:8] + cursor_pix[11:8]
                                          + stat_pix[11:8] + fence_pix[11:8];
            pix_out[7:3] <= blank1 ? 0 : cell_pix[7:3] + cursor_pix[7:3]
                                         + stat_pix[7:3] + fence_pix[7:3];
            pix_out[3:0] <= blank1 ? 0 : cell_pix[3:0] + cursor_pix[3:0]
                                         + stat_pix[3:0] + fence_pix[3:0];
            done_out <= (vcount1 >= SCREEN_HEIGHT);
        end
        {hsync_out, vsync_out} <= {~hsync1, ~vsync1};
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Update: 8/8/2019 GH 
// Create Date: 10/02/2015 02:05:19 AM
// Module Name: xvga
//
// xvga: Generate VGA display signals (1024 x 768 @ 60Hz)
//
//                              ---- HORIZONTAL -----     ------VERTICAL -----
//                              Active                    Active
//                    Freq      Video   FP  Sync   BP      Video   FP  Sync  BP
//   640x480, 60Hz    25.175    640     16    96   48       480    11   2    31
//   800x600, 60Hz    40.000    800     40   128   88       600     1   4    23
//   1024x768, 60Hz   65.000    1024    24   136  160       768     3   6    29
//   1280x1024, 60Hz  108.00    1280    48   112  248       768     1   3    38
//   1280x720p 60Hz   75.25     1280    72    80  216       720     3   5    30
//   1920x1080 60Hz   148.5     1920    88    44  148      1080     4   5    36
//
// change the clock frequency, front porches, sync's, and back porches to create 
// other screen resolutions
////////////////////////////////////////////////////////////////////////////////

module xvga(input wire vclk_in,
            output logic [10:0] hcount_out,    // pixel number on current line
            output logic [9:0] vcount_out,     // line number
            output logic vsync_out, hsync_out,
            output logic blank_out);

   parameter DISPLAY_WIDTH  = 640;      // display width
   parameter DISPLAY_HEIGHT = 480;       // number of lines

   parameter  H_FP = 16;                 // horizontal front porch
   parameter  H_SYNC_PULSE = 96;        // horizontal sync
   parameter  H_BP = 48;                // horizontal back porch

   parameter  V_FP = 11;                  // vertical front porch
   parameter  V_SYNC_PULSE = 2;          // vertical sync 
   parameter  V_BP = 31;                 // vertical back porch

   // horizontal: 1344 pixels total
   // display 1024 pixels per line
   logic hblank,vblank;
   logic hsyncon,hsyncoff,hreset,hblankon;
   assign hblankon = (hcount_out == (DISPLAY_WIDTH -1));    
   assign hsyncon = (hcount_out == (DISPLAY_WIDTH + H_FP - 1));  //1047
   assign hsyncoff = (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE - 1));  // 1183
   assign hreset = (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE + H_BP - 1));  //1343

   // vertical: 806 lines total
   // display 768 lines
   logic vsyncon,vsyncoff,vreset,vblankon;
   assign vblankon = hreset & (vcount_out == (DISPLAY_HEIGHT - 1));   // 767 
   assign vsyncon = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP - 1));  // 771
   assign vsyncoff = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE - 1));  // 777
   assign vreset = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE + V_BP - 1)); // 805

   // sync and blanking
   logic next_hblank,next_vblank;
   assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
   assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
   always_ff @(posedge vclk_in) begin
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
module render_fetch (input wire clk_in,
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
        addr_r_out <= board_cell_y * WORDS_PER_ROW
            + board_cell_x >> LOG_WORD_SIZE;
        is_alive_out <=
            data_r_in[WORD_SIZE-1-board_cell_x[LOG_WORD_SIZE-1:0]];
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
            pix_out <= CURSOR_COLOR;
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
module stat_render(input wire clk_in,
                   input wire rst_in,
                   input wire[10:0] hcount_in,
                   input wire[9:0] vcount_in,
                   input wire is_alive_in,
                   output logic[11:0] pix_out);
    localparam SAMPLE_PIX = GRAPH_WIDTH / HISTORY_LEN;
    localparam LOG_HISTORY_LEN = $clog2(HISTORY_LEN) + 1;
    localparam LOG_SAMPLE_PIX = $clog2(SAMPLE_PIX);

    logic[4:0] frame_cnt;
    logic[15:0] max_tally;
    logic[4:0] log_max_tally;
    logic[HISTORY_LEN:0][15:0] tally;
    always_ff @(posedge clk_in) begin
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
            (128 * tally[sample_idx] + 64 * tally[sample_idx]) << log_max_tally;
        sample_vcount = GRAPH_ORIGIN_Y + GRAPH_HEIGHT - sample_height;
        on_point = vcount_in == sample_vcount;
    end

    //draws x and y axis for graph
    always_ff @(posedge clk_in) begin
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

// * cell_render - renders a highlighted square.
// * 
// * Assumptions:
// *  - view starts at pixel (0, 0).
// *  - is_alive signal has correct timing, received every cycle for every pixel.
// *
// * Output:
// *  - returns white when the pixel is included in an alive cell.
// *  - black otherwise.
// *
// * Timing:
// *  - Stage one pipeline.
// */
module cell_render(input wire clk_in,
                   input wire is_alive_in,
                   input wire[10:0] hcount_in,
                   input wire[9:0] vcount_in,
                   output logic[11:0] pix_out);
    always_ff @(posedge clk_in) begin
        if ((hcount_in < VIEW_SIZE*CELL_SIZE)
                && (vcount_in < VIEW_SIZE*CELL_SIZE)) begin
            if (is_alive_in)
                pix_out <= CELL_COLOR;
            else
                pix_out <= 12'h0;
        end else
            pix_out <= 12'h0;
    end         
endmodule

`default_nettype none
// * fence_render - draws the border that separates game board, 
// *                graph and pattern selection
// * Output: pix_out
// * 
// * Timing: 
// - stage 2 pipeline
module fence_render (input wire clk_in,
                     input wire rst_in,
                     input wire[10:0] hcount_in,
                     input wire[9:0] vcount_in,
                     output logic[11:0] pix_out);
   localparam GAME_BOARD_DIS = 30, TOP_DIS = SCREEN_HEIGHT >> 1;
   parameter VIEW_PIX = VIEW_SIZE * CELL_SIZE;

   always_ff @(posedge clk_in) begin
       if (rst_in) begin
           pix_out <= 0;
       end else begin
           if (hcount_in == VIEW_PIX)
               pix_out <= 12'hFFF;
           else if (hcount_in > VIEW_PIX && vcount_in == TOP_DIS)
               pix_out <= 12'hFFF;
           else 
               pix_out <= 12'h0;
       end
   end
endmodule

`default_nettype wire

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
module renderer(input wire clk_in, rst_in,
                input wire cell_alive_in,
                input wire[HCOUNT_WIDTH-1:0] hcount_in,
                input wire[VCOUNT_WIDTH-1:0] vcount_in,
                input wire hsync_in, vsync_in, blank_in,
                input wire[LOG_NUM_SEED-1:0] seed_idx_in,
                input wire[LOG_BOARD_SIZE-1:0] cursor_x_in, cursor_y_in,
                output logic[11:0] pix_out,
                output logic vsync_out, hsync_out);
    // Sample user input so no update happens within a frame
    pos_t view_x, view_y, cursor_x, cursor_y;
    always_ff @(posedge clk_in) begin
        if (hcount_in == 0 && vcount_in == 0) begin
            cursor_x <= cursor_x_in;
            cursor_y <= cursor_y_in;
        end
    end

    logic[10:0] hcount1;
    logic[9:0] vcount1;
    logic hsync1, vsync1, blank1;
    always_ff @(posedge clk_in) begin
        hcount1 <= hcount_in;
        vcount1 <= vcount_in;
        {hsync1, vsync1, blank1} <= {hsync_in, vsync_in, blank_in};
    end

    logic[11:0] cell_pix;
    cell_render cell_r(.clk_in(clk_in), .is_alive_in(cell_alive_in),
                       .pix_out(cell_pix));

    logic[11:0] cursor_pix;
    cursor_render cursor_r(.clk_in(clk_in), .hcount_in(hcount_in),
                           .vcount_in(vcount_in), .cursor_x_in(cursor_x),
                           .cursor_y_in(cursor_y), .pix_out(cursor_pix));

    logic[11:0] stat_pix;
    stat_render stat_r(.clk_in(clk_in),
                       .rst_in(rst_in),
                       .hcount_in(hcount_in),
                       .vcount_in(vcount_in),
                       .is_alive_in(cell_alive_in),
                       .pix_out(stat_pix));
            
    logic[11:0] fence_pix;
    fence_render fence_r(.clk_in(clk_in),
                         .rst_in(rst_in),
                         .hcount_in(hcount_in),
                         .vcount_in(vcount_in),
                         .pix_out(fence_pix));

    logic[11:0] text_pix;
    text_render pic_r(.clk_in(clk_in),
                       .hcount_in(hcount_in),
                       .vcount_in(vcount_in),
                       .text_pix_out(text_pix));
                       
    logic[11:0] highlight_pix;
    highlight_render hl_r(.clk_in(clk_in),
                          .hcount_in(hcount_in),
                          .vcount_in(vcount_in),
                          .seed_idx_in(seed_idx_in),
                          .highlight_pix_out(highlight_pix));

    logic[11:0] blended_pix;
    alpha_blend r(
                .text_pix_in(text_pix[11:8]),
                .highlight_pix_in(highlight_pix[11:8]),
                .blended_pix_out(blended_pix[11:8])
                );
    alpha_blend g(
                .text_pix_in(text_pix[7:4]),
                .highlight_pix_in(highlight_pix[7:4]),
                .blended_pix_out(blended_pix[7:4])
                );
    alpha_blend b(
                .text_pix_in(text_pix[3:0]),
                .highlight_pix_in(highlight_pix[3:0]),
                .blended_pix_out(blended_pix[3:0])
                );
    
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            pix_out <= 0;
        end else begin
            pix_out[11:8] <= blank1 ? 0 : cell_pix[11:8] + cursor_pix[11:8]
                                          + stat_pix[11:8] + fence_pix[11:8]
                                          + blended_pix[11:8];
            pix_out[7:3] <= blank1 ? 0 : cell_pix[7:3] + cursor_pix[7:3]
                                         + stat_pix[7:3] + fence_pix[7:3]
                                         + blended_pix[7:3];
            pix_out[3:0] <= blank1 ? 0 : cell_pix[3:0] + cursor_pix[3:0]
                                         + stat_pix[3:0] + fence_pix[3:0]
                                         + blended_pix[3:0];
        end
        {hsync_out, vsync_out} <= {~hsync1, ~vsync1};
    end
endmodule

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
                     input wire[LOG_BOARD_SIZE-1:0] cursor_x_in,
                     input wire[LOG_BOARD_SIZE-1:0] cursor_y_in,
                     output logic[11:0] pix_out);
    pos_t cursor_x_in_view, cursor_y_in_view;
    logic in_x_range, in_y_range, at_x_edge, at_y_edge;
    always_comb begin
        in_x_range = (hcount_in >= cursor_x_in-1)
                        && (hcount_in <= cursor_x_in + 1);
        in_y_range = (vcount_in >= cursor_y_in)
                        && (vcount_in <= cursor_y_in + 1);
        at_x_edge = (hcount_in == cursor_x_in)
                        || (hcount_in == cursor_x_in + 1);
        at_y_edge = (vcount_in == cursor_y_in)
                        || (vcount_in == cursor_y_in + 1);
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
    localparam GRAPH_ZERO_Y = GRAPH_ORIGIN_Y + GRAPH_HEIGHT;
    localparam LOG_GRAPH_HEIGHT = $clog2(GRAPH_HEIGHT);
    localparam LOG_GRAPH_WIDTH = $clog2(GRAPH_WIDTH);

    logic[4:0] counter;
    logic[17:0] max_tally;
    logic[17:0] cur_tally;
    logic[15:0] history[0:GRAPH_WIDTH-1];
    logic[4:0] log_max_tally;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            max_tally <= 1;
            log_max_tally <= 0;
            cur_tally <= 0;
            counter <= 0;
            for (integer i = 0; i < GRAPH_WIDTH; i++) begin
                history[i] <= 0;
            end
        end else if (hcount_in == BOARD_SIZE && vcount_in == BOARD_SIZE) begin
            if (counter >= GRAPH_SAMPLE_PERIOD) begin
                counter <= 0;
                for (integer i = 0; i < GRAPH_WIDTH - 1; i++) begin
                    history[i] <= history[i+1];
                end
                history[GRAPH_WIDTH-1] <= cur_tally;
            end else begin
                counter <= counter + 1;
            end
            cur_tally <= 0;
        end else if (hcount_in < BOARD_SIZE && vcount_in < BOARD_SIZE) begin
            cur_tally <= cur_tally + is_alive_in;
            if (cur_tally >= max_tally) begin
                max_tally <= max_tally << 1;
                log_max_tally <= log_max_tally + 1;
            end
        end
    end

    logic[LOG_GRAPH_WIDTH-1:0] sample_idx;
    vcount_t sample_vcount;
    logic in_range_x, in_range_y, on_point;
    always_comb begin
        in_range_x = hcount_in >= GRAPH_ORIGIN_X
            && hcount_in < (GRAPH_ORIGIN_X + GRAPH_WIDTH);
        in_range_y = vcount_in >= GRAPH_ORIGIN_Y
            && vcount_in < (GRAPH_ORIGIN_Y + GRAPH_HEIGHT);
        sample_idx = hcount_in - GRAPH_ORIGIN_X;
        sample_vcount = GRAPH_ZERO_Y
            - ((history[sample_idx] << LOG_GRAPH_HEIGHT) >> log_max_tally);
        on_point = (vcount_in >= sample_vcount) && (vcount_in < GRAPH_ZERO_Y);
    end

    //draws x and y axis for graph
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            pix_out <= 12'hFFF;
        end else if ((vcount_in == GRAPH_ORIGIN_Y + GRAPH_HEIGHT)
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
                   output logic[11:0] pix_out);
    always_ff @(posedge clk_in) begin
        if (is_alive_in)
            pix_out <= CELL_COLOR;
        else
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
   localparam GAME_BOARD_DIS = 30, TOP_DIS = 148;

   always_ff @(posedge clk_in) begin
       if (rst_in) begin
           pix_out <= 0;
       end else begin
           if (hcount_in == BOARD_SIZE + 1)
               pix_out <= 12'hFFF;
           else if (hcount_in > BOARD_SIZE + 1 && vcount_in == TOP_DIS)
               pix_out <= 12'hFFF;
           else 
               pix_out <= 12'h0;
       end
   end
endmodule

`default_nettype wire

`default_nettype none
////////////////////////////////////////////////////
//
// text_render based off of picture_lab from lab 3
//
//////////////////////////////////////////////////
module text_render#(parameter WIDTH = SCREEN_WIDTH - BOARD_SIZE, 
                    HEIGHT = SCREEN_HEIGHT - 148, COLOR = 12'hFFF)
                    (input wire clk_in,
                     input wire [10:0] hcount_in,
                     input wire [9:0] vcount_in,
                     output logic [11:0] text_pix_out);
    localparam PATTERN_X_START = BOARD_SIZE + 1;
    localparam PATTERN_Y_START = 148;
    
    // image size: 332x160

    logic[16:0] image_addr;
    logic image_bit;

    // calculate rom address and read the location
    assign image_addr = (vcount_in-PATTERN_Y_START) * WIDTH
                      + (hcount_in-PATTERN_X_START);
    pattern_text_rom  rom1(.clka(clk_in), .addra(image_addr), .douta(image_bit));

    logic x_in_range, y_in_range;
    assign x_in_range = (hcount_in >= PATTERN_X_START)
                      && (hcount_in < (PATTERN_X_START + WIDTH));
    assign y_in_range = (vcount_in >= PATTERN_Y_START)
                      && (vcount_in < (PATTERN_Y_START + HEIGHT));
    always_ff @ (posedge clk_in) begin
        if (x_in_range && y_in_range && image_bit)
            text_pix_out <= COLOR; // greyscale
        else
            text_pix_out <= 0;
   end
endmodule

// * highlight_render - highlights the selected pattern name
// *
// * Output: highlight_pix_out
// *
module highlight_render# (parameter WIDTH = 160, HEIGHT = 14, COLOR = 12'h999) 
                        (input wire clk_in,
                         input wire [10:0] hcount_in,
                         input wire [9:0] vcount_in,
                         input wire [LOG_NUM_SEED-1:0] seed_idx_in,
                         output logic [11:0] highlight_pix_out);
        localparam HIGHLIGHT_X = BOARD_SIZE + 2;
        localparam HIGHLIGHT_Y_BEGIN = 160;

        vcount_t hl_y_coor;
        always_comb begin
            hl_y_coor = HIGHLIGHT_Y_BEGIN + (seed_idx_in - 1)*HEIGHT;
        end

        always_ff @(posedge clk_in) begin
            if (seed_idx_in != 0) begin
                if  ((hcount_in >= HIGHLIGHT_X && hcount_in < (HIGHLIGHT_X + WIDTH)) &&
                            (vcount_in >= hl_y_coor && vcount_in < (hl_y_coor + HEIGHT)))
                    highlight_pix_out <= COLOR;
                else 
                    highlight_pix_out <= 0;
            end else 
                highlight_pix_out <= 0;            
        end 
endmodule

// * alpha_blend - combines pixels from text_render and text_highlihghter
// * 
// * Output: blended_pix_out
module alpha_blend(
        input wire[3:0] text_pix_in,
        input wire[3:0] highlight_pix_in,
        output logic[3:0] blended_pix_out
        );
    
        logic[5:0] temp; //solution to overflow
        always_comb begin
            temp = text_pix_in * ALPHA_IN + highlight_pix_in * (6'b100 - ALPHA_IN);
            blended_pix_out = temp[5:2];
        end
endmodule

`default_nettype wire

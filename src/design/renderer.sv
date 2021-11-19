`include "common.svh"

`default_nettype none
/**
 * renderer - renders the game screen.
 *
 * Timing:
 *  - Three stage pipeline.
 */
module renderer(input wire clk_130mhz, start_in,
                input wire[WORD_SIZE-1:0] data_in,
                input wire[LOG_BOARD_SIZE-1:0] view_x_in, view_y_in,
                input wire[LOG_BOARD_SIZE-1:0] cursor_x_in, cursor_y_in,
                output wire[LOG_MAX_ADDR-1:0] addr_r_out,
                output logic done_out,
                output logic[11:0] pix_out,
                output logic vsync_out, hsync_out);
    logic clk_65mhz;
    clk_wiz_65mhz(.clk_in1(clk_130mhz), .clk_out1(clk_65mhz));

    //initiate xvga instance
    logic [10:0] hcount0;
    logic [9:0] vcount0;
    logic hsync0, vsync0, blank0;
    xvga xvga1(.clk_65mhz(clk_65mhz),
           .hcount_out(hcount0),
           .vcount_out(vcount0),
           .vsync_out(vsync0),
           .hsync_out(hsync0),
           .blank_out(blank0));

    // Sample user input so no update happens within a frame
    pos_t view_x, view_y, cursor_x, cursor_y;
    always_ff @(posedge clk_130mhz) begin
        if (!vsync0) begin
            view_x <= view_x_in;
            view_y <= view_y_in;
            cursor_x <= cursor_x_in;
            cursor_y <= cursor_y_in;
        end
    end


    // First stage pipeline (counted from hcount, vcount) --------------------

    logic is_alive;
    render_fetch fetch(.clk_130mhz(clk_130mhz), .start_in(start_in),
                       .hcount_in(hcount0), .vcount_in(vcount0),
                       .view_x_in(view_x), .view_y_in(view_y),
                       .data_r_in(data_in), .addr_r_out(addr_r_out),
                       .is_alive_out(is_alive));

    // Second stage pipeline (counted from hcount, vcount) -------------------

    logic[10:0] hcount1;
    logic[9:0] vcount1;
    logic hsync1, vsync1, blank1;
    always_ff @(posedge clk_130mhz) begin
        hcount1 <= hcount0;
        vcount1 <= vcount0;
        {hsync1, vsync1, blank1} <= {hsync0, vsync0, blank0};
    end

    logic[11:0] cell_pix;
    cell_render(.clk_130mhz(clk_130mhz), .is_alive_in(is_alive),
                .hcount_in(hcount1), .vcount_in(vcount1), .pix_out(cell_pix));

    logic[11:0] cursor_pix;
    cursor_render(.clk_130mhz(clk_130mhz), .hcount_in(hcount1),
                  .vcount_in(vcount1), .view_x_in(view_x),
                  .view_y_in(view_y), .cursor_x_in(cursor_x),
                  .cursor_y_in(cursor_y), .pix_out(cursor_pix));

    // Third stage pipeline --------------------------------------------------

    always_ff @(posedge clk_130mhz) begin
        pix_out <= cell_pix + cursor_pix;
        {hsync_out, vsync_out} <= {hsync1, vsync1};
        done_out <= (hsync1 == SCREEN_WIDTH) && (vsync1 == SCREEN_HEIGHT);
    end
endmodule

//xvga module copied from lab 3: change parameters!
module xvga(input wire clk_65mhz,
            output logic [10:0] hcount_out,    // pixel number on current line
            output logic [9:0] vcount_out,     // line number
            output logic vsync_out, hsync_out, blank_out);
    parameter DISPLAY_WIDTH = 1024;
    parameter DISPLAY_HEIGHT = 768;

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
    assign hblankon = (hcount_out == (DISPLAY_WIDTH - 1));    
    assign hsyncon = (hcount_out == (DISPLAY_WIDTH + H_FP - 1));  //1047
    assign hsyncoff =
        (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE - 1));  // 1183
    assign hreset =
        (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE + H_BP - 1));  //1343

    // vertical: 806 lines total
    // display 768 lines
    logic vsyncon,vsyncoff,vreset,vblankon;
    assign vblankon = hreset & (vcount_out == (DISPLAY_HEIGHT - 1));   // 767 
    assign vsyncon =
        hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP - 1));  // 771
    assign vsyncoff = hreset
        & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE - 1));  // 777
    assign vreset = hreset
        & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE + V_BP - 1)); // 805

    // sync and blanking
    logic next_hblank,next_vblank;
    assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
    assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
    always_ff @(posedge clk_65mhz) begin
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
module render_fetch (input wire clk_130mhz, start_in,
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

    always_ff @(posedge clk_130mhz) begin
        if (start_in) begin
            addr_r_out <= 0;
            is_alive_out <= 0;
        end else begin
            addr_r_out <= board_cell_y * WORDS_PER_ROW
                + board_cell_x >> LOG_WORD_SIZE;
            is_alive_out <=
                data_r_in[WORD_SIZE-1-board_cell_x[LOG_WORD_SIZE-1:0]];
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
module cursor_render(input wire clk_130mhz,
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

    always_ff @(posedge clk_130mhz) begin
        if ((at_x_edge && in_y_range) || (at_y_edge && in_x_range))
            pix_out <= 12'hFFF;
        else
            pix_out <= 12'b0;
    end
endmodule

`default_nettype wire

`default_nettype none
/**
 * cell_render - renders a highlighted square.
 * 
 * Assumptions:
 *  - view starts at pixel (0, 0).
 *  - is_alive signal has correct timing, received every cycle for every pixel.
 *
 * Output:
 *  - returns white when the pixel is included in an alive cell.
 *  - black otherwise.
 *
 * Timing:
 *  - Stage one pipeline.
 */
module cell_render(input wire clk_130mhz,
                   input wire is_alive_in,
                   input wire[10:0] hcount_in,
                   input wire[9:0] vcount_in,
                   output logic[11:0] pix_out);
       
        always_ff @(posedge clk_130mhz) begin
            if ((hcount_in < VIEW_SIZE*CELL_SIZE)
                    && (vcount_in < VIEW_SIZE*CELL_SIZE)) begin
                if (is_alive_in)
                   pix_out <= 12'hFFF;
                else
                   pix_out <= 12'h0;
            end else
                pix_out <= 12'h0;
        end         
   
endmodule

`default_nettype wire

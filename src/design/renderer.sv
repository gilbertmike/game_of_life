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

    //initiate xvga instance
    xvga xvga1(.clk_in(clk_in),
               .hcount_out(hcount),
               .vcount_out(vcount),
               .vsync_out(vsync),
               .hsync_out(hsync),
               .blank_out(blank));

    //render_fetch module, to fetch info on squares within view window
    module render_fetch (input wire clk_in, rst_in,
                        input wire[LOG_BOARD_SIZE-1:0] view_x_in, view_y_in,
                        input wire[WORD_SIZE-1:0] data_r_in,
                        output logic[LOG_MAX_ADDR-1:0] addr_r_out,
                        output logic is_alive_out);

        always_ff @(posedge clk_in) begin
           if (rst_in) begin
               addr_r_out <= 0;
               is_alive_out <= 0;
           //range of view is view_x + hcount, view_y + vcount
               
           end
        end
        //constructs range for view window

        //requests data for pixels in range window

        //sends each pixel data out
        
    endmodule
endmodule
`default_nettype wire


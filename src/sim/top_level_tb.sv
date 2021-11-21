`timescale 1ns / 1ps

module top_level_tb;
    logic clk;
    always #5 clk = !clk;

    // Input
    logic btnl, btnu, btnr, btnd, btnc;
    logic[15:0] sw;

    // Output
    logic[3:0] r, g, b;
    logic hs, vs;

    top_level#(.LOG_DEBOUNCE_COUNT(1), .LOG_WAIT_COUNT(1))
        uut(.clk_100mhz(clk), .btnc(btnc), .btnr(btnr), .btnu(btnu),
            .btnl(btnl), .btnd(btnd), .sw(sw), .vga_r(r), .vga_g(g), .vga_b(b),
            .vga_hs(hs), .vga_vs(vs));

    initial begin
        clk = 0;
        {btnl, btnu, btnr, btnd, btnc, sw} = 0;
        sw[15] = 1;
        
        // Start test
        #20;
        sw[15] = 0;
        btnc = 1;
        #100;
    end
endmodule

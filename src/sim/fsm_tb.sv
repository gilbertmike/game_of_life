
module fsm_tb;

    localparam LOG_BOARD_SIZE = 3;

    //initialize inputs
    logic clk;
    logic rst;
    logic start;
    logic fetch_ready;
    
    //initialize outputs
    logic[LOG_BOARD_SIZE-1:0] x;
    logic[LOG_BOARD_SIZE-1:0] y;
    logic done;
    
    //pulse generation
    logic start_dly;
    logic fetch_ready_dly;
    
    //uut
    new_fsm uut(.clk_in(clk),
 .rst_in(rst), 
.start_in(start),
                
.fetch_ready_in(fetch_ready),
 .x_out(x), .y_out(y),
 
                .done_out(done));
    
    //clk
    always #5 clk = !clk;
    
    initial begin
        clk = 0;
        rst = 0;
        start = 0;
        fetch_ready = 0;
        x = 0;
        y = 0;
        done = 0;
        #10
        rst = 1;
        #10
        rst = 0;
        start = 1;
        #10
        start = 0;
        for (integer i=0; i<1050; i = i+1) begin
            fetch_ready = 1;
            #10
            fetch_ready = 0;
            #40;
        end
        start = 1;
        #10
        start = 0;
        #100;
    end
endmodule

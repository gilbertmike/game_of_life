`ifndef COMMON_SVH_
`define COMMON_SVH_

// Memory and game state parameters
parameter BOARD_SIZE = 480;
parameter LOG_BOARD_SIZE = $clog2(BOARD_SIZE);

// User input parameters
parameter LOG_MAX_SPEED = 3;
parameter SPEED_SW = 0;

parameter MAX_SPEED = 2**LOG_MAX_SPEED;

// Drawing parameters
parameter SCREEN_WIDTH = 640;
parameter SCREEN_HEIGHT = 480;
parameter HCOUNT_WIDTH = 11;
parameter VCOUNT_WIDTH = 10;

parameter CELL_COLOR = 12'hFFF;
parameter CURSOR_COLOR = 12'h0F0;

// Statistics render parameter
parameter GRAPH_HEIGHT = 128, GRAPH_WIDTH = 128;
parameter HISTORY_LEN = 32;
parameter GRAPH_ORIGIN_X = BOARD_SIZE + 10, GRAPH_ORIGIN_Y = 10; //origin positioned at top left corner

// Commonly used data types
typedef logic data_t;
typedef logic[LOG_BOARD_SIZE-1:0] pos_t;
typedef logic[LOG_MAX_SPEED-1:0] speed_t;
typedef logic[HCOUNT_WIDTH-1:0] hcount_t;
typedef logic[VCOUNT_WIDTH-1:0] vcount_t;
`endif

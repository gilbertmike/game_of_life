`ifndef COMMON_SVH_
`define COMMON_SVH_

// Memory and game state parameters
parameter LOG_LINE_WIDTH = 3;
parameter LOG_BOARD_SIZE = 10;

parameter LOG_MAX_ADDR = LOG_BOARD_SIZE*2 - LOG_LINE_WIDTH;
parameter BOARD_SIZE = 2**LOG_BOARD_SIZE;


// User input parameters
parameter LOG_MAX_SPEED = 3;
parameter SPEED_SW = 0;

parameter MAX_SPEED = 2**LOG_MAX_SPEED;


// Drawing parameters
parameter SCREEN_WIDTH = 1024;
parameter SCREEN_HEIGHT = 768;
parameter LOG_SCREEN_WIDTH = $clog2(SCREEN_WIDTH);
parameter LOG_SCREEN_HEIGHT = $clog2(SCREEN_HEIGHT);


// Commonly used data types
typedef logic[LOG_MAX_ADDR-1:0] addr_t;
typedef logic[LOG_LINE_WIDTH-1:0] data_t;

typedef logic[LOG_MAX_SPEED-1:0] speed_t;

typedef logic[LOG_BOARD_SIZE-1:0] pos_t;

`endif

`ifndef COMMON_SVH_
`define COMMON_SVH_

// Memory and game state parameters
parameter LOG_WORD_SIZE = 4;
parameter LOG_BOARD_SIZE = 10;
parameter LOG_VIEW_SIZE = 8;
parameter LOG_NUM_PE = 0;
parameter NUM_PE = 2**LOG_NUM_PE;
parameter WINDOW_WIDTH = 2 + NUM_PE;

parameter WORD_SIZE = 2**LOG_WORD_SIZE;
parameter LOG_MAX_ADDR = LOG_BOARD_SIZE*2 - LOG_WORD_SIZE;
parameter MAX_ADDR = 2**LOG_MAX_ADDR;
parameter BOARD_SIZE = 2**LOG_BOARD_SIZE;
parameter VIEW_SIZE = 2**LOG_VIEW_SIZE;

parameter SD_CARD_BLOCK = 512;


// User input parameters
parameter LOG_MAX_SPEED = 3;
parameter SPEED_SW = 0;

parameter MAX_SPEED = 2**LOG_MAX_SPEED;


// Drawing parameters
parameter SCREEN_WIDTH = 1024;
parameter SCREEN_HEIGHT = 512;
parameter LOG_SCREEN_WIDTH = $clog2(SCREEN_WIDTH);
parameter LOG_SCREEN_HEIGHT = $clog2(SCREEN_HEIGHT);
parameter LOG_CELL_SIZE = LOG_SCREEN_HEIGHT - LOG_VIEW_SIZE;
parameter CELL_SIZE = 2**LOG_CELL_SIZE;


// Audio parameters
parameter SONG_START_ADDR = 512;
parameter SONG_END_ADDR = 4096;


// Commonly used data types
typedef logic[LOG_MAX_ADDR-1:0] addr_t;
typedef logic[WORD_SIZE-1:0] data_t;

typedef logic[WINDOW_WIDTH-1:0] window_row_t;

typedef logic[LOG_MAX_SPEED-1:0] speed_t;

typedef logic[LOG_BOARD_SIZE-1:0] pos_t;

`endif

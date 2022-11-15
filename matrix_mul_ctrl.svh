`ifndef MATRIX_MUL_CTRL_HEADER
`define MATRIX_MUL_CTRL_HEADER
typedef struct packed {
    logic valid;
    logic[14:0] input_a_addr_begin; // matrix A address. A is transposed before send into excution
    logic[16:0] input_b_addr_begin; // matrix B address. A and B should be aligned into N times of Muler's width. By default, 8
    logic[14:0] output_c_addr_begin;
    logic[14:0] a_line_size;
    logic[16:0] b_line_size;
    logic[14:0] c_line_size;
    
    logic[11:0] matrix_n;
} matrix_mul_ctrl_t;

typedef logic[14:0]  feature_bram_addr_t;
typedef logic[16:0]  weight_bram_addr_t;
typedef logic[14:0]  output_bram_addr_t;
typedef logic[63:0]  data_64_t;
typedef logic[255:0] data_256_t;
// No need response for output.
`endif
`ifndef MATRIX_MUL_CTRL_HEADER
`define MATRIX_MUL_CTRL_HEADER
typedef struct packed {
    logic[15:0] n;
    logic[15:0] p;
    logic[15:0] m;
} inst_t;

typedef logic[11:0]  feature_bram_addr_t;
typedef logic[13:0]  weight_bram_addr_t;
typedef logic[9:0]  output_bram_addr_t;
typedef logic[63:0]  data_64_t;
typedef logic[255:0] data_256_t;
typedef struct packed {
    logic valid;
    feature_bram_addr_t input_a_addr_begin; // matrix A address. A is transposed before send into excution
    weight_bram_addr_t input_b_addr_begin; // matrix B address. A and B should be aligned into N times of Muler's width. By default, 8
    output_bram_addr_t output_c_addr_begin;
    feature_bram_addr_t a_line_size;
    weight_bram_addr_t b_line_size;
    output_bram_addr_t c_line_size;
    
    logic[11:0] matrix_n;
} matrix_mul_ctrl_t;

// No need response for output.
`endif
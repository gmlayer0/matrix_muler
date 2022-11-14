`timescale 1 ps / 1 ps

typedef struct packed {
    logic valid,
    logic[14:0] input_a_addr_begin, // matrix A address. A is transposed before send into excution
    logic[16:0] input_b_addr_begin, // matrix B address. A and B should be aligned into N times of Muler's width. By default, 8
    logic[14:0] output_c_addr_begin,
    logic[14:0] a_line_size,
    logic[16:0] b_line_size,
    logic[14:0] c_line_size,
    
    logic[11:0] matrix_n,
} matrix_mul_ctrl_t;

typedef logic[14:0]  feature_bram_addr_t;
typedef logic[16:0]  weight_bram_addr_t;
typedef logic[14:0]  output_bram_addr_t;
typedef logic[63:0]  data_64_t;
typedef logic[255:0] data_256_t;
// No need response for output.

module matrix_mul_ctrl  #(
    parameter int MULER_WIDTH = 8,
    parameter int NUM_WIDTH = 8,
    parameter int OUTPUT_WIDTH = 32,
    parameter int MULER_DELAY = 1,
    parameter int ROW_SIZE = 8,
    parameter int COLUMN_SIZE = 8,

    parameter int BRAM_READ_LATENCY = 3 // BRAM Latency should be no less then 1, for at least one clk is needed for num_valid
)(
    input clk,
    input rst,
    output req_valid,
    input matrix_mul_ctrl_t ctrl_info,

    output feature_bram_addr_t feature_addr,
    input data_64_t feature_resp,
    output weight_bram_addr_t weight_addr,
    input data_64_t weight_resp,

    output output_bram_addr_t output_addr,
    output data_256_t output_data,
    output logic output_we
);

    // Matrix Muler core
    logic num_valid_r;
    logic [11:0] num_r;
    logic [7:0][7:0] input_a;
    logic [7:0][7:0] input_b;
    logic [7:0][31:0] output_r;
    mac_array #(
        .MULER_WIDTH(8),
        .NUM_WIDTH(12),
        .OUTPUT_WIDTH(32),
        .MULER_DELAY(1),
        .ROW_SIZE(8),
        .COLUMN_SIZE(8)
    ) mac_array_core (
        .clk(clk),
        .rst(rst),
        .num_valid(num_valid_r),
        .num(num_r),
        .data_a(input_a),
        .data_b(input_b),
        .result_r(output_r)
    );

    // input_address controlling logic
    logic[14:0] feature_len_size;
    logic[16:0] weight_len_size;
    always_ff @(posedge clk) begin
        if(req_valid & ctrl_info.valid) begin
            feature_addr <= ctrl_info.input_a_addr_begin;
            weight_addr <= ctrl_info.input_b_addr_begin;
            feature_len_size <= ctrl_info.a_line_size;
            weight_len_size <= ctrl_info.b_line_size;
        end else begin
            feature_addr <= feature_addr + feature_len_size;
            weight_addr <= weight_addr + weight_len_size;
        end
    end

    // output_address controlling logic
    logic output_valid;
    logic[14:0] output_len_size;
    logic[14:0] output_addr_last;
    logic[14:0] output_len_size_last;
    always_ff @(posedge clk) begin
        if(output_valid) begin
            output_addr <= output_addr_last;
            output_len_size <= output_len_size_last;
        end else begin
            output_addr <= output_addr + output_len_size;
        end
    end

    // output_address pipeline maintain logic
    always_ff @(posedge clk) begin
        if(req_valid & ctrl_info.valid) begin
            output_addr_last <= ctrl_info.output_c_addr_begin;
            output_len_size_last <= ctrl_info.c_line_size;
        end
    end

    // num_valid controlling logic
    logic[BRAM_READ_LATENCY - 1 : 0] num_valid_shfit_register;
    logic[BRAM_READ_LATENCY - 1 : 0][11:0] num_shift_register;
    always_ff @(posedge clk) begin
        num_valid_shift_register <= {num_valid_shfit_register[BRAM_READ_LATENCY - 2 : 0], req_valid};
        num_shift_register <= {num_shift_register[BRAM_READ_LATENCY - 2 : 0], ctrl_info.matrix_n};
    end
    assign num_valid_r = num_valid_shfit_register[BRAM_READ_LATENCY - 1];
    assign num_r = num_shift_register[BRAM_READ_LATENCY - 1];

    // output_valid controlling logic
    logic[11:0] execution_cnt;
    always_ff @(posedge clk) begin
        if(num_valid_r) begin
            execution_cnt <= MULER_DELAY + num_r;
        end else begin
            if(execution_cnt != 0) begin
                execution_cnt <= execution_cnt - 1;
            end
        end
    end

    // req_valid controlling logic
    

endmodule
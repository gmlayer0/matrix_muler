`timescale 1 ps / 1 ps
`include "matrix_mul_ctrl.svh"

module matrix_mul_ctrl_tb;
    logic clk;
    always #1 clk = ~clk;
    logic rst;
    logic[7:0][7:0][7:0] bram_a = {
        {8'd9,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1},
        {8'd9,8'd2,8'd2,8'd2,8'd2,8'd2,8'd2,8'd2},
        {8'd9,8'd3,8'd3,8'd3,8'd3,8'd3,8'd3,8'd3},
        {8'd9,8'd4,8'd4,8'd4,8'd4,8'd4,8'd4,8'd4},
        {8'd9,8'd5,8'd5,8'd5,8'd5,8'd5,8'd5,8'd5},
        {8'd9,8'd6,8'd6,8'd6,8'd6,8'd6,8'd6,8'd6},
        {8'd9,8'd7,8'd7,8'd7,8'd7,8'd7,8'd7,8'd7},
        {8'd9,8'd8,8'd8,8'd8,8'd8,8'd8,8'd8,8'd8}
    };
    logic[7:0][7:0][7:0] bram_b = {
        {8'd1,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0},
        {8'd0,8'd1,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0},
        {8'd0,8'd0,8'd1,8'd0,8'd0,8'd0,8'd0,8'd0},
        {8'd0,8'd0,8'd0,8'd1,8'd0,8'd0,8'd0,8'd0},
        {8'd0,8'd0,8'd0,8'd0,8'd1,8'd0,8'd0,8'd0},
        {8'd0,8'd0,8'd0,8'd0,8'd0,8'd1,8'd0,8'd0},
        {8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd1,8'd0},
        {8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd1}
    };
    // logic[7:0][3:0][7:0] bram_a = {
    //     {8'd9,8'd1,8'd1,8'd1},
    //     {8'd9,8'd2,8'd2,8'd2},
    //     {8'd9,8'd3,8'd3,8'd3},
    //     {8'd9,8'd9,8'd9,8'd9},
    //     {8'd9,8'd5,8'd5,8'd5},
    //     {8'd9,8'd6,8'd6,8'd6},
    //     {8'd9,8'd7,8'd7,8'd7},
    //     {8'd9,8'd9,8'd9,8'd9}
    // };
    // logic[7:0][3:0][7:0] bram_b = {
    //     {8'd1,8'd0,8'd0,8'd0},
    //     {8'd0,8'd1,8'd0,8'd0},
    //     {8'd0,8'd0,8'd1,8'd0},
    //     {8'd0,8'd0,8'd0,8'd1},
    //     {8'd1,8'd0,8'd0,8'd0},
    //     {8'd0,8'd1,8'd0,8'd0},
    //     {8'd0,8'd0,8'd1,8'd0},
    //     {8'd0,8'd0,8'd0,8'd1}
    // };
    matrix_mul_ctrl_t ctrl_info;
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        ctrl_info = '0;
        ctrl_info.valid = '1;
        ctrl_info.a_line_size = 14'd8;
        ctrl_info.b_line_size = 14'd8;
        ctrl_info.c_line_size = 14'd64;
        ctrl_info.matrix_n = 12'd8;
        #10
        rst = 1'b0;
        #12
        ctrl_info.valid = '1;
        ctrl_info.matrix_n = 12'd8;
        #100
        $finish();
    end

    feature_bram_addr_t feature_addr;
    weight_bram_addr_t weight_addr;
    logic[7:0][7:0] feature_resp;
    logic[7:0][7:0] weight_resp;

    feature_bram_addr_t[1:0] feature_addr_delay;
    weight_bram_addr_t[1:0] weight_addr_delay;
    always_ff @(posedge clk) begin
        feature_addr_delay <= {feature_addr_delay[0], feature_addr};
        weight_addr_delay  <= {weight_addr_delay[0] ,  weight_addr};
    end
    always_ff @(posedge clk) begin
        feature_resp <= bram_a[feature_addr_delay[1][5:3]];
        weight_resp  <= bram_b[weight_addr_delay[1][5:3]];
    end

    output_bram_addr_t output_addr;
    logic[3:0][31:0] output_data;
    logic output_we;
    logic req_valid;

    matrix_mul_ctrl  #(
    .MULER_WIDTH(8),
    .NUM_WIDTH(12),
    .OUTPUT_WIDTH(32),
    .MULER_DELAY(1),
    .ROW_SIZE(8),
    .COLUMN_SIZE(8),
    .BRAM_READ_LATENCY(3) // BRAM Latency should be no less then 1, for at least one clk is needed for num_valid
    ) uut (
    .clk,
    .rst,
    .req_valid,
    .ctrl_info,

    .feature_addr,
    .feature_resp,
    .weight_addr,
    .weight_resp,

    .output_addr,
    .output_data,
    .output_we
);
endmodule
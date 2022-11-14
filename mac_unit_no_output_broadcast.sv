`timescale 1 ps / 1 ps

module mac_unit_no_output_broadcast #(
    parameter int MULER_WIDTH = 8,
    parameter int NUM_WIDTH = 8,
    parameter int OUTPUT_WIDTH = 32,
    parameter int MULER_DELAY = 1
)(
    input clk,
    input rst,

    // muler_counter
    input num_valid,
    input [NUM_WIDTH - 1 : 0] num,
    output logic num_valid_r,
    output logic [NUM_WIDTH - 1 : 0] num_r,

    // data input and broadcasting
    input logic[1:0][MULER_WIDTH - 1 : 0] data,
    output logic[1:0][MULER_WIDTH - 1 : 0] data_r,

    // input logic[OUTPUT_WIDTH - 1 : 0] result,
    output logic[OUTPUT_WIDTH - 1 : 0] result_r,
    output logic data_ready
);

    // num register
    // Actually, it can be merge into counter.
    // always_ff @(posedge clk) begin : num_r_handling
    //     if(rst || num_valid) begin
    //         num_r <= num;
    //     end
    // end

    // num_valid register
    always_ff @(posedge clk) begin : num_valid_r_handling
        num_valid_r <= num_valid;
    end

    // data register
    always_ff @(posedge clk) begin : data_r_handling
        data_r <= data;
    end

    // counter
    logic[NUM_WIDTH - 1 : 0] counter_r;
    assign num_r = counter_r;
    always_ff @(posedge clk) begin : counter_handling
        if(rst || num_valid) begin
            counter_r <= num;
        end else begin
            counter_r <= counter_r - 1;
        end
    end

    // MAC core
    logic[OUTPUT_WIDTH - 1 : 0] output_r;
    mac_core_8x8_32 mac_core(
        .clk(clk),
        .rst(rst || num_valid),
        .a_i(data[0]),
        .b_i(data[1]),
        .output_r
    );

    // controller
    assign data_ready = ((counter_r + MULER_DELAY) == 1);
    always_ff @(posedge clk) begin : result_r_handling
        if(data_ready) begin
            result_r <= output_r;
        end
    end

endmodule
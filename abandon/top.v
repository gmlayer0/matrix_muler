`timescale 1 ps / 1 ps
// `include "matrix_mul_ctrl.svh"

module accelerator_top(
    input wire clk,
    input wire rst,

    output wire[11:0] bram_a_addr,
    output wire[63:0] bram_a_din,
    input  wire[63:0] bram_a_dout,
    output wire bram_a_en,
    output wire bram_a_we,

    output wire[13:0] bram_b_addr,
    output wire[63:0] bram_b_din,
    input  wire[63:0] bram_b_dout,
    output wire bram_b_en,
    output wire bram_b_we,

    output wire[9:0]   bram_c_addr,
    output wire[255:0] bram_c_din,
    input  wire[255:0] bram_c_dout,
    output wire bram_c_en,
    output wire bram_c_we,

    output wire[8:0]  bram_d_addr,
    output wire[63:0] bram_d_din,
    input  wire[63:0] bram_d_dout,
    output wire bram_d_en,
    output wire bram_d_we
);

    assign bram_a_din = 0;
    assign bram_a_we = 0;
    assign bram_b_din = 0;
    assign bram_b_we = 0;

    assign bram_a_en = 1;
    assign bram_b_en = 1;
    assign bram_c_en = 1;
    assign bram_d_en = 1;

    wire matrix_mul_ctrl_ready;
    wire[84:0] ctrl_info;
    wire[47:0] inst;

    wire inst_valid;
    wire inst_ready;

    matrix_mul_ctrl#(
        .MULER_WIDTH(8),
        .NUM_WIDTH(8),
        .OUTPUT_WIDTH(32),
        .MULER_DELAY(1),
        .ROW_SIZE(8),
        .COLUMN_SIZE(8),
        .BRAM_READ_LATENCY(1) // BRAM Latency should be no less then 1, for at least one clk is needed for num_valid
    )matrix_mul_core(
        .clk(clk),
        .rst(rst),
        .req_valid(matrix_mul_ctrl_ready),
        .ctrl_info(ctrl_info),
        .feature_addr(bram_a_addr),
        .feature_resp(bram_a_dout),
        .weight_addr (bram_b_addr),
        .weight_resp (bram_b_dout),
        .output_addr (bram_c_addr),
        .output_data (bram_c_din),
        .output_we   (bram_c_we)
    );

    matrix_dispatcher#(
        .ROW_SIZE(8),
        .COLUMN_SIZE(8)
    )dispatcher(
        .clk(clk),
        .rst(rst),
        .ctrl_info(ctrl_info),
        .inst(inst),

        .s_valid(inst_valid),
        .s_ready(inst_ready),

        // .m_valid(),
        .m_ready(matrix_mul_ctrl_ready)
    );

    main_ctrl main_ctrl_i(
        .clk(clk),
        .rst(rst),
        .addr(bram_d_addr),
        .rdata(bram_d_dout),
        .wdata(bram_d_din),
        .we(bram_d_we),
        .inst(inst),
        .inst_valid(inst_valid),
        .inst_ready(inst_ready)
    );

endmodule
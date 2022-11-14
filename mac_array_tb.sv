`timescale 1 ps / 1 ps

module mac_array_tb;

    logic clk,rst;
    logic num_valid;
    logic [15:0] num;
    logic [7:0][7:0] input_a;
    logic [7:0][7:0] input_b;
    always #5 clk = ~clk;
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        num = 16'd10;
        num_valid = 1'b1;
        input_a = '0;
        input_b = '0;
        # 100
        rst = 1'b0;

        # 10
        num_valid = 1'b0;
        input_a = {8'd1,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd1};
        # 10
        input_a = {8'd2,8'd2,8'd2,8'd2,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd1,8'd0};
        # 10
        input_a = {8'd3,8'd3,8'd3,8'd3,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd0,8'd0,8'd1,8'd0,8'd0};
        # 10
        input_a = {8'd4,8'd4,8'd4,8'd4,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd0,8'd1,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd5,8'd5,8'd5,8'd5,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd1,8'd0,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd6,8'd6,8'd6,8'd6,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd1,8'd0,8'd0,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd7,8'd7,8'd7,8'd7,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd1,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd8,8'd8,8'd8,8'd8,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd1,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd8,8'd8,8'd8,8'd8,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd1,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0};
        # 10    
        input_a = {8'd8,8'd8,8'd8,8'd8,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd1,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0};
        # 10
        input_a = '0;
        input_b = '0;
        num = 16'd7;
        num_valid = 1'b1;
        # 10
        num_valid = 1'b0;
        input_a = {8'd8,8'd7,8'd6,8'd5,8'd4,8'd3,8'd2,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd1};
        # 10
        input_a = {8'd2,8'd2,8'd2,8'd2,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd1,8'd0};
        # 10
        input_a = {8'd3,8'd3,8'd3,8'd3,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd0,8'd0,8'd1,8'd0,8'd0};
        # 10
        input_a = {8'd4,8'd4,8'd4,8'd4,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd0,8'd1,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd5,8'd5,8'd5,8'd5,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd1,8'd0,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd6,8'd6,8'd6,8'd6,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd0,8'd1,8'd0,8'd0,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd7,8'd7,8'd7,8'd7,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd0,8'd1,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd8,8'd8,8'd8,8'd8,8'd1,8'd1,8'd1,8'd1};
        input_b = {8'd1,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0};
        # 250
        $finish();
    end

    logic [7:0][31:0] output_r;

    mac_array #(
        .MULER_WIDTH(8),
        .NUM_WIDTH(16),
        .OUTPUT_WIDTH(32),
        .MULER_DELAY(1),
        .ROW_SIZE(8),
        .COLUMN_SIZE(8)
    ) mac_ut (
        .clk(clk),
        .rst(rst),
        .num_valid,
        .num,
        .data_a(input_a),
        .data_b(input_b),
        .result_r(output_r)
    );
    
endmodule
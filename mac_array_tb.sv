module mac_array_tb;

    logic clk,rst;
    logic num_valid;
    logic [15:0] num;
    logic [3:0][7:0] input_a;
    logic [3:0][7:0] input_b;
    always #5 clk = ~clk;
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        num = 16'd4;
        num_valid = 1'b1;
        # 100
        rst = 1'b0;

        # 10
        num_valid = 1'b0;
        input_a = {8'd1,8'd0,8'd0,8'd0};
        input_b = {8'd1,8'd0,8'd0,8'd0};
        # 10
        input_a = {8'd0,8'd1,8'd0,8'd0};
        input_b = {8'd0,8'd1,8'd0,8'd0};
        # 10
        input_a = {8'd0,8'd0,8'd1,8'd0};
        input_b = {8'd0,8'd0,8'd1,8'd0};
        # 10
        input_a = {8'd0,8'd0,8'd0,8'd1};
        input_b = {8'd0,8'd0,8'd0,8'd1};
    end

    logic [3:0][31:0] output_r;

    mac_array #(
        .MULER_WIDTH(8),
        .NUM_WIDTH(16),
        .OUTPUT_WIDTH(32),
        .MULER_DELAY(1),
        .ROW_SIZE(4),
        .COLUMN_SIZE(4)
    ) mac_ut (
        .clk,
        .rst,
        .num_valid,
        .num,
        .data_a(input_a),
        .data_b(input_b),
        .result_r(output_r)
    );
    
endmodule
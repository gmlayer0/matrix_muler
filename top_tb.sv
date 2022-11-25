`timescale 1 ps / 1 ps

module top_tb;
    logic clk;
    logic rst;
    always #1 clk = ~clk;
    initial begin
        clk = 0;
        rst = '1;
        #10
        rst = '0;
    end
    logic[11:0] bram_a_addr;
    logic[63:0] bram_a_din;
    logic[63:0] bram_a_dout;
    logic bram_a_en;
    logic bram_a_we;

    logic[13:0] bram_b_addr;
    logic[63:0] bram_b_din;
    logic[63:0] bram_b_dout;
    logic bram_b_en;
    logic bram_b_we;
    
    logic[9:0]   bram_c_addr;
    logic[255:0] bram_c_din;
    logic[255:0] bram_c_dout;
    logic bram_c_en;
    logic bram_c_we;
    
    logic[8:0]  bram_d_addr;
    logic[63:0] bram_d_din;
    logic[63:0] bram_d_dout;
    logic bram_d_en;
    logic bram_d_we;

    logic[31:0][7:0][7:0] bram_a;
    logic[31:0][7:0][7:0] bram_b;
    logic[31:0][7:0][31:0] bram_c;
    logic[31:0][7:0][7:0] bram_d;

    accelerator_top top_ut(
        .clk,
        .rst,
        .bram_a_addr,
        .bram_a_din,
        .bram_a_dout,
        .bram_a_en,
        .bram_a_we,
        .bram_b_addr,
        .bram_b_din,
        .bram_b_dout,
        .bram_b_en,
        .bram_b_we,
        .bram_c_addr,
        .bram_c_din,
        .bram_c_dout,
        .bram_c_en,
        .bram_c_we,
        .bram_d_addr,
        .bram_d_din,
        .bram_d_dout,
        .bram_d_en,
        .bram_d_we
    );

    always_ff @(posedge clk) begin
        bram_a_dout <= bram_a[bram_a_addr[4:0]];
        bram_b_dout <= bram_b[bram_b_addr[4:0]];
        bram_c_dout <= bram_c[bram_c_addr[4:0]];
        bram_d_dout <= bram_d[bram_d_addr[4:0]];
    end

    always_ff @(posedge clk) begin
        if(rst) begin
        bram_a <= {
            {64'h0101000001000101},
            {64'h0001000000010001},
            {64'h0000000001010001},
            {64'h0100010101010101},
            {64'h0001000001000000},
            {64'h0000010100010000},
            {64'h0000000101010000},
            {64'h0000010100000101}
        };
        bram_b <= {
            {64'h0000000100000001},
            {64'h0101000100000000},
            {64'h0000010100010001},
            {64'h0000010001000001},
            {64'h0100010001000001},
            {64'h0101000100010101},
            {64'h0001010101000101},
            {64'h0001010000010001}
        };
        bram_c <= '0;
        bram_d <= {
            {16'd0,16'd9,16'd32,16'd32},{16'd0,16'd9,16'd32,16'd32},
            64'd1}; 
        end
        if(bram_a_we) begin
            bram_a[bram_a_addr[4:0]] <= bram_a_din;
        end
        if(bram_b_we) begin
            bram_b[bram_b_addr[4:0]] <= bram_b_din;
        end
        if(bram_c_we) begin
            bram_c[bram_c_addr[4:0]] <= bram_c_din;
        end
        if(bram_d_we) begin
            bram_d[bram_d_addr[4:0]] <= bram_d_din;
        end
    end

    initial begin
        #400
        $finish();
    end

endmodule
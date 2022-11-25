`timescale 1 ps / 1 ps

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

    // inst fetch machine.
    // bram latency should be exactly one cycle.

    // fsm machine
    reg[2:0] fsm_state;
    wire inst_valid;
    wire inst_ready;
    wire inst_gnt;
    localparam S_WAIT = 0;
    localparam S_FETCH_INST = 1;
    localparam S_WAIT_READY = 2;
    localparam S_EXEC = 3;
    localparam S_WB_FLAG  = 4;
    localparam S_FETCH_FLAG = 5;
    always @(posedge clk) begin
        if(rst) begin
            fsm_state <= S_WAIT;
        end else begin
           if(fsm_state == S_WAIT) begin
               fsm_state <= bram_d_dout[0];
           end else if(fsm_state == S_FETCH_INST) begin
               fsm_state <= S_WAIT_READY;
           end else if(fsm_state == S_WAIT_READY) begin
               if(inst_ready) begin
                  fsm_state <= S_EXEC;
               end
           end else if(fsm_state == S_EXEC) begin
               if(inst_gnt) begin
                  fsm_state <= S_WB_FLAG;
               end
           end else if(fsm_state == S_WB_FLAG) begin
               fsm_state <= S_FETCH_FLAG;
           end else if(fsm_state == S_FETCH_FLAG) begin
               fsm_state <= S_WAIT;
           end
        end
    end

    // inst_valid logic.
    assign inst_valid = fsm_state == S_WAIT_READY;

    // bram_d logic
    assign bram_d_addr = (fsm_state == S_FETCH_INST || fsm_state == S_WAIT_READY) ? 2 : 0;
    assign bram_d_din = 0;
    assign bram_d_we = fsm_state == S_WB_FLAG;

    // instance matrix core.
    matrix_muler_bram #(
        .MULER_WIDTH(8),
        // parameter int NUM_WIDTH = 8,
        .OUTPUT_WIDTH(32),
        .MULER_DELAY(1),
        .BRAM_DELAY(1),

        .ROW_SIZE(8),
        .COLUMN_SIZE(8),

        .CTRL_N_LEN(12),

        .ADDR_A_LEN(12),
        .ADDR_B_LEN(14),
        .ADDR_OUTPUT_LEN(10)
    ) matrix_muler(
        .clk(clk),
        .rst(rst),

        .valid(inst_valid),      // input inst is valid.
        .ready(inst_ready),     // ready for next inst.

        .data_gnt(inst_gnt),  // data is ready. write flag after this signal set high.

        .a_size_in(0 | (bram_d_dout[15: 3] + (|bram_d_dout[ 2: 0]))),
        .b_size_in(0 | (bram_d_dout[31:19] + (|bram_d_dout[18:16]))),
        .n_size_in(0 | bram_d_dout[47:32]),

        .a_addr(bram_a_addr),
        .data_a(bram_a_dout),
        .b_addr(bram_b_addr),
        .data_b(bram_b_dout),
        .output_addr(bram_c_addr),
        .output_data(bram_c_din),
        .output_we(bram_c_we)
);

endmodule
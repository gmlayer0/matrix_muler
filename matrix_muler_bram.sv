`timescale 1 ps / 1 ps

module matrix_muler_bram #(
    parameter int MULER_WIDTH = 8,
    // parameter int NUM_WIDTH = 8,
    parameter int OUTPUT_WIDTH = 32,
    parameter int MULER_DELAY = 1,
    parameter int BRAM_DELAY = 1,

    parameter int ROW_SIZE = 8,
    parameter int COLUMN_SIZE = 8,

    parameter int CTRL_N_LEN = 12,

    parameter int ADDR_A_LEN = 12,
    parameter int ADDR_B_LEN = 12,
    parameter int ADDR_OUTPUT_LEN = 12
)(
    input clk,
    input rst,

    input logic valid,      // input inst is valid.
    output logic ready,     // ready for next inst.

    output logic data_gnt,  // data is ready. write flag after this signal set high.

    input logic[ADDR_A_LEN - 1 : 0] a_size_in,
    input logic[ADDR_B_LEN - 1 : 0] b_size_in,
    input logic[CTRL_N_LEN - 1 : 0] n_size_in,

    output logic[ADDR_A_LEN - 1 : 0] a_addr,
    input logic[COLUMN_SIZE - 1 : 0][MULER_WIDTH - 1 : 0] data_a,
    output logic[ADDR_B_LEN - 1 : 0] b_addr,
    input logic[ ROW_SIZE   - 1 : 0][MULER_WIDTH - 1 : 0] data_b,
    output logic[ADDR_OUTPUT_LEN - 1 : 0] output_addr,
    output logic[ROW_SIZE   - 1 : 0][OUTPUT_WIDTH - 1 : 0]output_data,
    output logic output_we
);

    // handling size record
    logic[ADDR_A_LEN - 1 : 0] a_r;
    logic[ADDR_B_LEN - 1 : 0] b_r;
    logic[CTRL_N_LEN - 1 : 0] n_r;
    always_ff @(posedge clk) begin
        if(rst) begin // TODO: DO WE REALLY NEED IT?
            a_r <= '0;
            b_r <= '0;
            n_r <= '0;
        end else
        if(valid & ready) begin
            a_r <= a_size_in;
            b_r <= b_size_in;
            n_r <= n_size_in;
        end
    end

    // a,b, addressing root conting logic for sub_matrix dividing 
    logic count_valid; // valid to trigger an a_addr_root add
    logic[ADDR_A_LEN - 1 : 0] a_addr_root;
    logic a_root_carry;
    logic[ADDR_B_LEN - 1 : 0] b_addr_root;
    logic b_root_carry;
    logic[ADDR_OUTPUT_LEN - 1 : 0] output_a_addr_root;
    logic[ADDR_OUTPUT_LEN - 1 : 0] output_b_addr_root;
    // A part
    always_ff @(posedge clk) begin
        if(rst) begin // TODO: DO WE REALLY NEED IT?
            a_addr_root <= '0;
            output_a_addr_root <= '0;
            ready <= 1'b1;
        end else
        // counter reset logic
        if(valid & ready) begin
            a_addr_root <= '0;
            ready <= 1'b0;
            output_a_addr_root <= b_size_in << ($clog2(COLUMN_SIZE));
        end else
        // counter add logic
        if(count_valid & a_root_carry & b_root_carry) begin
            a_addr_root <= '0;
            output_a_addr_root <= '0;
            ready <= 1'b1;
        end
        if(count_valid & b_root_carry) begin
            a_addr_root <= a_addr_root + 1'b1;
            output_a_addr_root <= output_a_addr_root + (b_r << ($clog2(COLUMN_SIZE)));
        end
    end
    // counter end logic
    assign a_root_carry = (a_addr_root == a_r - 1'b1);

    // B part
    always_ff @(posedge clk) begin
        if(rst) begin // TODO: DO WE REALLY NEED IT?
            b_addr_root <= '0;
            output_b_addr_root <= '0;
        end else
        // counter reset logic
        if(valid & ready) begin
            b_addr_root <= '0;
            output_b_addr_root <= '0;
        end else
        // counter add logic
        if(count_valid & b_root_carry) begin
            b_addr_root <= '0;
            output_b_addr_root <= output_a_addr_root;
        end else
        if(count_valid) begin
            b_addr_root <= b_addr_root + 1'b1;
            output_b_addr_root <= output_b_addr_root + 1'b1;
        end
    end

    // output address fifo, 4 depth is enough
    logic[3:0][ADDR_OUTPUT_LEN - 1 : 0] output_b_addr_fifo;
    logic count_valid_delay;
    logic[1:0] out_b_addr_fifo_wptr;
    logic[1:0] out_b_addr_fifo_rptr;
    
    // output counter
    logic[$clog2(COLUMN_SIZE) - 1:0] output_cnt;
    logic output_valid_early;
    always_ff @(posedge clk) begin
        if(rst) begin
            output_cnt <= '0;
        end else if(output_cnt) begin
            output_cnt <= output_cnt - 1;
        end else if(output_valid_early) begin
            output_cnt <= COLUMN_SIZE - 1;
        end
    end

    // count_valid_delay part
    always_ff @(posedge clk) begin
        count_valid_delay <= count_valid;
    end

    // wptr part
    always_ff @(posedge clk) begin
        if(rst) begin // TODO: DO WE REALLY NEED IT?
            out_b_addr_fifo_wptr <= '0;
        end else
        // counter reset logic
        if(valid & ready) begin
            out_b_addr_fifo_wptr <= 1'b1;
        end else
        if(count_valid_delay) begin
            out_b_addr_fifo_wptr <= out_b_addr_fifo_wptr + 1'b1;
        end
    end

    // rptr part
    always_ff @(posedge clk) begin
        if(rst) begin // TODO: DO WE REALLY NEED IT?
            out_b_addr_fifo_rptr <= '0;
        end else
        // counter reset logic
        if(valid & ready) begin
            out_b_addr_fifo_rptr <= '0;
        end else
        if(&output_cnt) begin
            out_b_addr_fifo_rptr <= out_b_addr_fifo_rptr + 1'b1;
        end
    end

    // data_in part
    always_ff @(posedge clk) begin
        if(valid & ready) begin
            output_b_addr_fifo[0] <= '0;
        end else
        if(count_valid_delay) begin
            output_b_addr_fifo[out_b_addr_fifo_wptr] <= output_b_addr_root;
        end
    end

    // counter end logic
    assign b_root_carry = (b_addr_root == b_r - 1'b1);

    // per_matrix addressing logic.
    // once next matrix is in, count_valid is set to high
    logic sub_matrix_valid;
    logic sub_matrix_ready;
    assign sub_matrix_valid = ~ready;
    assign count_valid = sub_matrix_valid & sub_matrix_ready;

    // A addressing logic
    always_ff @(posedge clk) begin
        // I'm pretty sure, this module doesn't need to reset at all.
        if(sub_matrix_valid & sub_matrix_ready) begin
            a_addr <= a_addr_root;
        end else begin
            a_addr <= a_addr + a_r;
        end
    end

    // B addressing logic
    always_ff @(posedge clk) begin
        // I'm pretty sure, this module doesn't need to reset at all.
        if(sub_matrix_valid & sub_matrix_ready) begin
            b_addr <= b_addr_root;
        end else begin
            b_addr <= b_addr + b_r;
        end
    end

    // Output addressing logic
    always_ff @(posedge clk) begin
        // I'm pretty sure, this module doesn't need to reset at all.
        if(output_cnt == 0 && output_valid_early) begin
            output_addr <= output_b_addr_fifo[out_b_addr_fifo_rptr];
        end else if(output_we) begin
            output_addr <= output_addr + b_r;
        end
    end

    // sub_matrix_valid logic.
    logic[CTRL_N_LEN : 0] exc_counter;
    always_ff @(posedge clk) begin
        if(rst) begin
            exc_counter <= '0;
        end else if(sub_matrix_valid & sub_matrix_ready) begin
            exc_counter <= n_r + BRAM_DELAY + MULER_DELAY + COLUMN_SIZE + ROW_SIZE;
        end else if(exc_counter) begin
            exc_counter <= exc_counter - 1'b1;
        end
    end
    assign sub_matrix_ready = (n_r + BRAM_DELAY + MULER_DELAY + ROW_SIZE + 1) > exc_counter && (9 + BRAM_DELAY + MULER_DELAY + ROW_SIZE) > exc_counter;

    // num_valid and num register controlling
    logic [BRAM_DELAY - 1 : 0]num_valid_r;
    logic [BRAM_DELAY - 1 : 0][CTRL_N_LEN - 1 : 0] num_r;
    always_ff @(posedge clk) begin
        num_valid_r <= (num_valid_r << 1) | (sub_matrix_valid & sub_matrix_ready);
        num_r <= (num_r << CTRL_N_LEN) | n_r;
    end
    logic num_valid;
    logic[CTRL_N_LEN - 1 : 0] num;
    assign num = num_r[BRAM_DELAY - 1];
    assign num_valid = num_valid_r[BRAM_DELAY - 1];

    mac_array #(
        .MULER_WIDTH(MULER_WIDTH),
        .NUM_WIDTH(CTRL_N_LEN),
        .OUTPUT_WIDTH(OUTPUT_WIDTH),
        .MULER_DELAY(MULER_DELAY),
        .ROW_SIZE(ROW_SIZE),
        .COLUMN_SIZE(COLUMN_SIZE)
    ) mac_array_core (
        .clk(clk),
        .rst(rst),
        .num_valid,
        .num,
        .data_a,
        .data_b,
        .result_r(output_data),

        .result_valid_match(output_we),
        .result_valid_r(output_valid_early)
    );

    assign data_gnt = (exc_counter == 0) & ready;

endmodule
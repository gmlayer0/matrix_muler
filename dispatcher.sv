// TODO: Not finish yet.
`timescale 1ps / 1ps
`include "matrix_mul_ctrl.svh"

module matrix_dispatcher #(
    parameter int ROW_SIZE = 8,
    parameter int COLUMN_SIZE = 8
)(
    input clk,
    input rst,
    input inst_t inst,
    input logic s_valid,  // next inst is valid for dispatcher.
    output logic s_ready, // dispatcher is ready to get next inst. 

    output matrix_mul_ctrl_t ctrl_info,
    output logic m_valid, // next matrix mul operation is valid to send.
    input logic m_ready   // matrix mul core is ready to get next operation.
);  
    // inst input logic
    logic[15:0] n_r;
    logic[13:0] m_aligned_r;
    logic[13:0] p_aligned_r; 
    always_ff @(posedge clk) begin
        if(s_valid & s_ready) begin
            n_r <= inst.n;
            m_aligned_r <= inst.m[15:3] + (|inst.m[2:0]);
            p_aligned_r <= inst.p[15:3] + (|inst.p[2:0]);
        end
    end

    // m_aligned_p_r handling logic
    logic[13:0] m_aligned_p_r; // Accumulator, add 1 per execution until m_aligned_r - 1, matrix_mul_end, setup s_ready for next instruction.
    logic go_next_line;
    always_ff @(posedge clk) begin
        if(s_valid & s_ready) begin
            m_aligned_p_r <= 1;
        end else if(s_ready) begin
            m_aligned_p_r <= '0; 
        end else if(m_ready & go_next_line) begin
            m_aligned_p_r <= m_aligned_p_r + 1;
        end
    end

    // p_aligned_p_r handling logic
    logic[13:0] p_aligned_p_r; // Accumulator, add 1 per execution until p_aligned_r - 1, clear.
    assign go_next_line = p_aligned_p_r == p_aligned_r;
    always_ff @(posedge clk) begin
        if(s_valid & s_ready) begin
            p_aligned_p_r <= 1;
        end else if(s_ready) begin
            p_aligned_p_r <= '0; 
        end else if(m_ready & go_next_line) begin
            p_aligned_p_r <= 1;
        end else if(m_ready) begin
            p_aligned_p_r <= p_aligned_p_r + 1;
        end
    end

    // feature address pointer handling
    logic[14:0] feature_p_r;
    always_ff @(posedge clk) begin
        if(s_valid & s_ready) begin
            feature_p_r <= '0;
        end else if(m_ready & go_next_line) begin
            feature_p_r <= feature_p_r + 1;
        end
    end

    // weight address pointer handling
    logic[16:0] weight_p_r;
    always_ff @(posedge clk) begin
        if(s_valid & s_ready) begin
            weight_p_r <= '0;
        end else if(m_ready & go_next_line) begin
            weight_p_r <= '0;
        end else if(m_ready) begin
            weight_p_r <= weight_p_r + 1;
        end
    end

    // output address pointer handling
    logic[14:0] output_p_r;
    logic[14:0] output_p_base_r;
    always_ff @(posedge clk) begin
        if(s_valid & s_ready) begin
            output_p_r <= '0;
            output_p_base_r <= '0;
        end else if(m_ready & go_next_line) begin
            output_p_r <= output_p_base_r + (p_aligned_r << $clog2(COLUMN_SIZE));
            output_p_base_r <= output_p_base_r + (p_aligned_r << $clog2(COLUMN_SIZE));
        end else if(m_ready) begin
            output_p_r <= output_p_r + 1;
        end
    end

    // as a slave to inst-bram. 
    // input logic s_valid,  // next inst is valid for dispatcher.
    // output logic s_ready, // dispatcher is ready to get next inst. 
    always_ff @(posedge clk) begin
        if(rst) begin
            s_ready <= 1;
        end else begin
            if(s_valid & s_ready) begin
                // start of one inst
                s_ready <= '0;
            end else if(m_ready & go_next_line & (m_aligned_p_r == m_aligned_r)) begin
                // end of one inst
                s_ready <= 1;
            end
        end
    end

    // as a master to matrix_mul_ctrl.
    // output logic m_valid, // next matrix mul operation is valid to send.
    // input logic m_ready   // matrix mul core is ready to get next operation.
    always_ff @(posedge clk) begin
        if(s_ready & s_valid) begin
            m_valid <= 1'b1;
        end else if(m_ready & go_next_line & (m_aligned_p_r == m_aligned_r)) begin
            m_valid <= 1'b0;
        end
    end

    // ctrl_unit assign
    assign ctrl_info.valid = m_valid;
    assign ctrl_info.input_a_addr_begin = (feature_p_r);
    assign ctrl_info.input_b_addr_begin = (weight_p_r);
    assign ctrl_info.output_c_addr_begin = (output_p_r);
    assign ctrl_info.a_line_size = (m_aligned_r);
    assign ctrl_info.b_line_size = (p_aligned_r);
    assign ctrl_info.c_line_size = (p_aligned_r);
    assign ctrl_info.matrix_n = m_valid ? n_r:4;
endmodule
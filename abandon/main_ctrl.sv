`timescale 1 ps / 1 ps
`include "matrix_mul_ctrl.svh"

module main_ctrl (
    input clk,
    input rst,

    output logic[8:0] addr,
    input  logic[63:0] rdata,
    output logic[63:0] wdata,
    output logic we,

    output inst_t inst,
    output logic inst_valid,
    input logic inst_ready 
);

    // This module is a FSM with only two state, execution status and waiting status.
    
    // FSM Machine and addr machine
    logic fsm_state; // 1 is for execution status, and 0 is for waiting status
    logic fetching;  // 1 is for rdata not valid yet.
    logic[1:0] fetching_cnt;
    logic[9:0] addr_r;
    assign addr = addr_r;
    always_ff @(posedge clk) begin
        if(rst) begin
            fsm_state <= '0;
            addr_r <= '0;
            we <= '0;
        end else begin
            if(~fsm_state) begin
                fsm_state <= (~fetching) & (rdata[0] == 1);
                addr_r <= ((~fetching) & (rdata[0] == 1)) ? 2 : 0;
                we <= '0;
            end else begin
                if((rdata == '0) && (fetching_cnt <= 1) && inst_ready) begin
                    fsm_state <= '0;
                    addr_r <= '0;
                    we <= 1;
                end else begin
                    we <= '0;
                    fsm_state <= 1;
                    if(inst_ready && inst_valid) begin
                        addr_r <= addr_r + 1;
                    end
                end
            end
        end
    end

    // fetching logic.
    assign fetching = |fetching_cnt;
    always_ff @(posedge clk) begin
        if(rst) begin
            fetching_cnt <= '0;
        end else if((inst_ready && inst_valid) || ((rdata == '0) && (fetching_cnt <= 1) && fsm_state) || ((~fetching) & (rdata[0] == 1) & (~fsm_state))) begin
            fetching_cnt <= 2; // 1 cycle for bram to responed, another 1 is for fsm_state update.
        end else if(fetching_cnt != '0) begin
            fetching_cnt <= fetching_cnt - 1;
        end
    end

    // inst_valid logic.
    assign inst_valid = (~fetching) & fsm_state;
    
    // inst connection
    assign inst.n = rdata[47:32];
    assign inst.m = rdata[15:0];
    assign inst.p = rdata[31:16];

    // wdata
    assign wdata = '0;

endmodule
`timescale 1 ps / 1 ps

module mac_core_8x8_32 (
    input clk,
    input rst,
    input logic[7:0] a_i,
    input logic[7:0] b_i,
    output logic[31:0] output_r
);

logic[15:0] mul;
// always_comb begin : muler
//     mul = a_i * b_i;
//     if(a_i[7]) begin
//         mul[15:8] = mul[15:8] - b_i;
//     end
//     if(b_i[7]) begin
//         mul[15:8] = mul[15:8] - a_i;
//     end
// end
mult_s8_u8 mul_core(
    .A(a_i),
    .B(b_i),
    .P(mul)
);

always_ff @(posedge clk) begin : output_register
    if(rst) begin
        output_r <= 0;
    end else begin
        output_r <= mul + output_r;
    end
end

endmodule
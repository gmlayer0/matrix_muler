`timescale 1 ps / 1 ps
module bit_shifter_2b (
    input wire[16:0] i,
    output wire[14:0] o
);
    assign o = i[16:2];
endmodule
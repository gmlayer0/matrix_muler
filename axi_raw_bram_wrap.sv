// TODO: Not finish yet.
`timescale 1ps/1ps

module axi_raw_bram_wrap #(
    parameter int BRAM_SIZE = 32*1024,              // in byte, must equal to 2^n, where n is a integer
    parameter int RAW_INTERFACE_WIDTH = 8,           // in byte
    parameter int BRAM_LATENCY = 3                  // cycles before output_data is valid
    localparam int RAW_ADDR_WIDTH = $clog2(BRAM_SIZE) - $clog2(RAW_INTERFACE_WIDTH);
    localparam type raw_addr_t = logic [RAW_ADDR_WIDTH-1:0],
    localparam type raw_data_t = logic [RAW_INTERFACE_WIDTH*8-1:0]
)(
    input clk,
    input rst,
    AXI_BUS.Slave axi_slv_intf,
    
    input raw_addr_t raw_addr,
    input raw_data_t raw_write_data,
    output raw_data_t raw_read_data,
    input logic we // not plans to support strobe mode for now.
);
    
    logic mem_req_o;
    logic mem_gnt_i;
    assign mem_gnt_i = mem_req_o;
    logic mem_addr_o;
    logic [31:0]mem_wdata_o;
    logic [3 :0]mem_strb_o;
    logic mem_atop_o; // useless
    logic mem_we_o;
    logic mem_rvalid_i; // just a delay of mem_req_o | mem_we_o
    logic [31:0]mem_rdata_i;

    logic [BRAM_LATENCY - 1 : 0] req_shift_register;
    assign mem_rvalid_i = req_shift_register[BRAM_LATENCY - 1];
    generate
        if(BRAM_LATENCY > 1) begin
            always_ff @(posedge clk) begin
                req_shift_register <= {req_shift_register[BRAM_LATENCY - 2:0],{mem_req_o | mem_we_o}};
            end
        end else begin
            always_ff @(posedge clk) begin
                req_shift_register <= mem_req_o | mem_we_o;
            end
        end
    endgenerate

    /// Interface wrapper for module `axi_to_mem`.
    module axi_to_mem_intf #(
    /// See `axi_to_mem`, parameter `AddrWidth`.
    .ADDR_WIDTH($clog2(BRAM_SIZE)),
    /// See `axi_to_mem`, parameter `DataWidth`.
    .DATA_WIDTH(32'd32), // zynq gp_axi is 32bit width.
    /// AXI4+ATOP ID width.
    .ID_WIDTH(32'd0),
    /// AXI4+ATOP user width.
    .USER_WIDTH(32'd0),
    /// See `axi_to_mem`, parameter `NumBanks`.
    .NUM_BANKS(32'd0),
    /// See `axi_to_mem`, parameter `BufDepth`.
    .BUF_DEPTH(32'd1),
    /// Hide write requests if the strb == '0
    .HIDE_STRB(1'b1),
    /// Depth of output fifo/fall_through_register. Increase for asymmetric backpressure (contention) on banks.
    .OUT_FIFO_DEPTH(32'd1)
    ) (
    /// Clock input.
    .clk_i(clk),
    /// Asynchronous reset, active low.
    .rst_ni(~rst),
    /// See `axi_to_mem`, port `busy_o`.
    //   .busy_o(), we dont need it.
    /// AXI4+ATOP slave interface port.
    .slv(axi_slv_intf),
    .mem_req_o,
    .mem_gnt_i,
    .mem_addr_o,
    .mem_wdata_o,
    .mem_strb_o,
    .mem_atop_o,
    .mem_we_o,
    .mem_rvalid_i,
    .mem_rdata_i
    );

    xpm_memory_tdpram #(
      .ADDR_WIDTH_A($clog2(BRAM_SIZE)),             // A is for axi
      .ADDR_WIDTH_B(RAW_ADDR_WIDTH),                // B is for raw
      .AUTO_SLEEP_TIME(0),
      .BYTE_WRITE_WIDTH_A(32),                      // axi rw port is 32 bits wide.
      .BYTE_WRITE_WIDTH_B(8 * RAW_INTERFACE_WIDTH), // x8 from byte to bits
      .CASCADE_HEIGHT(0),
      .CLOCKING_MODE("common_clock"),
      .ECC_MODE("no_ecc"),
      .MEMORY_INIT_FILE("none"),
      .MEMORY_INIT_PARAM("0"),
      .MEMORY_OPTIMIZATION("true"),
      .MEMORY_PRIMITIVE("auto"),
      .MEMORY_SIZE(BRAM_SIZE * 8),    // size in bits, BRAM_SIZE is in byte, so we multiply 8 on it.
      .MESSAGE_CONTROL(0),
      .READ_DATA_WIDTH_A(32),
      .READ_DATA_WIDTH_B(8 * RAW_INTERFACE_WIDTH),
      .READ_LATENCY_A(BRAM_LATENCY),
      .READ_LATENCY_B(BRAM_LATENCY),
      .READ_RESET_VALUE_A("0"),
      .READ_RESET_VALUE_B("0"),
      .RST_MODE_A("SYNC"),
      .RST_MODE_B("SYNC"),
      .SIM_ASSERT_CHK(0),
      .USE_EMBEDDED_CONSTRAINT(0),
      .USE_MEM_INIT(1),
      .WAKEUP_TIME("disable_sleep"), 
      .WRITE_DATA_WIDTH_A(32),
      .WRITE_DATA_WIDTH_B(8 * RAW_INTERFACE_WIDTH),
      .WRITE_MODE_A("no_change"),
      .WRITE_MODE_B("no_change")
   )
   xpm_memory_tdpram_inst (
    //   .dbiterra(dbiterra),             // 1-bit output: Status signal to indicate double bit error occurrence
    //                                    // on the data output of port A.

    //   .dbiterrb(dbiterrb),             // 1-bit output: Status signal to indicate double bit error occurrence
    //                                    // on the data output of port A.

      .douta(douta),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .doutb(doutb),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterra(sbiterra),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port A.

      .sbiterrb(sbiterrb),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B write and read operations.
      .clka(clka),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clkb),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .dinb(dinb),                     // WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
      .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .injectdbiterra(injectdbiterra), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectdbiterrb(injectdbiterrb), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(injectsbiterra), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterrb(injectsbiterrb), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regcea(regcea),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .regceb(regceb),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rsta(rsta),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .rstb(rstb),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(sleep),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(wea),                       // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

      .web(web)                        // WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
                                       // for port B input data port dinb. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dinb to address addrb. For example, to
                                       // synchronously write only bits [15-8] of dinb when WRITE_DATA_WIDTH_B
                                       // is 32, web would be 4'b0010.

   );

endmodule
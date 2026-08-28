`timescale 1ns / 1ps

module sample_memory_2 #(
    parameter DATA_WIDTH  = 11,
    parameter ADDR_WIDTH  = 14,
    parameter NUM_SAMPLES = 1024,
    parameter NUM_GROUPS  = 16
)(
    input wire clk,
    input wire rst_n,

    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] wr_addr,

    input wire signed [DATA_WIDTH-1:0] adc1_in,
    input wire signed [DATA_WIDTH-1:0] adc2_in,
    input wire signed [DATA_WIDTH-1:0] adc3_in,
    input wire signed [DATA_WIDTH-1:0] adc4_in,

    input wire [ADDR_WIDTH-1:0] rd_addr1_current,
    input wire [ADDR_WIDTH-1:0] rd_addr1_previous,

    input wire [ADDR_WIDTH-1:0] rd_addr2_current,
    input wire [ADDR_WIDTH-1:0] rd_addr2_previous,

    input wire [ADDR_WIDTH-1:0] rd_addr3_current,
    input wire [ADDR_WIDTH-1:0] rd_addr3_previous,

    input wire [ADDR_WIDTH-1:0] rd_addr4_current,
    input wire [ADDR_WIDTH-1:0] rd_addr4_previous,

    output wire signed [DATA_WIDTH-1:0] adc1_current,
    output wire signed [DATA_WIDTH-1:0] adc1_previous,

    output wire signed [DATA_WIDTH-1:0] adc2_current,
    output wire signed [DATA_WIDTH-1:0] adc2_previous,

    output wire signed [DATA_WIDTH-1:0] adc3_current,
    output wire signed [DATA_WIDTH-1:0] adc3_previous,

    output wire signed [DATA_WIDTH-1:0] adc4_current,
    output wire signed [DATA_WIDTH-1:0] adc4_previous
);

    localparam DEPTH = NUM_GROUPS * NUM_SAMPLES;

    (* ram_style = "block" *)
    reg signed [DATA_WIDTH-1:0] memory1 [0:DEPTH-1];

    (* ram_style = "block" *)
    reg signed [DATA_WIDTH-1:0] memory2 [0:DEPTH-1];

    (* ram_style = "block" *)
    reg signed [DATA_WIDTH-1:0] memory3 [0:DEPTH-1];

    (* ram_style = "block" *)
    reg signed [DATA_WIDTH-1:0] memory4 [0:DEPTH-1];

    always @(posedge clk) begin
        if (wr_en) begin
            memory1[wr_addr] <= adc1_in;
            memory2[wr_addr] <= adc2_in;
            memory3[wr_addr] <= adc3_in;
            memory4[wr_addr] <= adc4_in;
        end
    end

    assign adc1_current  = memory1[rd_addr1_current];
    assign adc1_previous = memory1[rd_addr1_previous];

    assign adc2_current  = memory2[rd_addr2_current];
    assign adc2_previous = memory2[rd_addr2_previous];

    assign adc3_current  = memory3[rd_addr3_current];
    assign adc3_previous = memory3[rd_addr3_previous];

    assign adc4_current  = memory4[rd_addr4_current];
    assign adc4_previous = memory4[rd_addr4_previous];

endmodule
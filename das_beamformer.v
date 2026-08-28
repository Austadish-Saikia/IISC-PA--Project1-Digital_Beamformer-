`timescale 1ns / 1ps

module das_beamformer #(
    parameter IN_WIDTH  = 12,
    parameter OUT_WIDTH = 14
)(
    input wire signed [IN_WIDTH-1:0] x1,
    input wire signed [IN_WIDTH-1:0] x2,
    input wire signed [IN_WIDTH-1:0] x3,
    input wire signed [IN_WIDTH-1:0] x4,

    output wire signed [OUT_WIDTH-1:0] beam_sum
);

    wire signed [OUT_WIDTH-1:0] x1_ext;
    wire signed [OUT_WIDTH-1:0] x2_ext;
    wire signed [OUT_WIDTH-1:0] x3_ext;
    wire signed [OUT_WIDTH-1:0] x4_ext;

    assign x1_ext = {{(OUT_WIDTH-IN_WIDTH){x1[IN_WIDTH-1]}}, x1};
    assign x2_ext = {{(OUT_WIDTH-IN_WIDTH){x2[IN_WIDTH-1]}}, x2};
    assign x3_ext = {{(OUT_WIDTH-IN_WIDTH){x3[IN_WIDTH-1]}}, x3};
    assign x4_ext = {{(OUT_WIDTH-IN_WIDTH){x4[IN_WIDTH-1]}}, x4};

    assign beam_sum =
        x1_ext +
        x2_ext +
        x3_ext +
        x4_ext;

endmodule
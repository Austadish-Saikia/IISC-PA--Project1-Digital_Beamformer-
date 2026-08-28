

`timescale 1ns / 1ps

module fractional_delay_interpolator #(
    parameter DATA_WIDTH = 11,
    parameter FRAC_BITS  = 8,
    parameter OUT_WIDTH  = DATA_WIDTH + 1
)(
    input wire signed [DATA_WIDTH-1:0] sample_current,
    input wire signed [DATA_WIDTH-1:0] sample_previous,

    input wire [FRAC_BITS-1:0] frac,

    output reg signed [OUT_WIDTH-1:0] sample_out
);

    localparam integer SCALE =
        (1 << FRAC_BITS);

    reg [FRAC_BITS:0] weight_current;
    reg [FRAC_BITS:0] weight_previous;

    reg signed [DATA_WIDTH+FRAC_BITS:0]
        mult_current;

    reg signed [DATA_WIDTH+FRAC_BITS:0]
        mult_previous;

    reg signed [DATA_WIDTH+FRAC_BITS+1:0]
        sum_value;

    always @(*) begin

        weight_previous =
            {1'b0, frac};

        weight_current =
            SCALE - weight_previous;

        mult_current =
            $signed(sample_current) *
            $signed({1'b0,weight_current});

        mult_previous =
            $signed(sample_previous) *
            $signed({1'b0,weight_previous});

        sum_value =
            mult_current +
            mult_previous;

        sample_out =
            sum_value >>> FRAC_BITS;

    end

endmodule
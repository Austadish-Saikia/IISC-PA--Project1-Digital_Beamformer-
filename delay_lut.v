
`timescale 1ns / 1ps

module delay_lut #(
    parameter NUM_GROUPS = 16,
    parameter NUM_FOCI   = 4,
    parameter INT_BITS   = 8,
    parameter FRAC_BITS  = 8
)(
    input wire [1:0] focus_sel,
    input wire [3:0] group_sel,

    output reg [INT_BITS-1:0] d1_int,
    output reg [FRAC_BITS-1:0] d1_frac,

    output reg [INT_BITS-1:0] d2_int,
    output reg [FRAC_BITS-1:0] d2_frac,

    output reg [INT_BITS-1:0] d3_int,
    output reg [FRAC_BITS-1:0] d3_frac,

    output reg [INT_BITS-1:0] d4_int,
    output reg [FRAC_BITS-1:0] d4_frac
);

    reg [55:0] mem [0:63];

    initial begin
        $readmemh("delay_lut_8x8.mem", mem);
    end

    wire [5:0] lut_addr =
        (group_sel * NUM_FOCI) + focus_sel;

    always @(*) begin

        d4_int  = mem[lut_addr][55:50];
        d4_frac = mem[lut_addr][49:42];

        d3_int  = mem[lut_addr][41:36];
        d3_frac = mem[lut_addr][35:28];

        d2_int  = mem[lut_addr][27:22];
        d2_frac = mem[lut_addr][21:14];

        d1_int  = mem[lut_addr][13:8];
        d1_frac = mem[lut_addr][7:0];

    end

endmodule
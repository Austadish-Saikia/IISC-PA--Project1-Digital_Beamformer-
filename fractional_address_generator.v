`timescale 1ns / 1ps

module fractional_delay_address_generator #(
    parameter ADDR_WIDTH  = 14,
    parameter NUM_SAMPLES = 1024,
    parameter NUM_GROUPS  = 16
)(
    input wire [3:0] group_sel,
    input wire [9:0] sample_index,

    input wire [7:0] d1_int,
    input wire [7:0] d2_int,
    input wire [7:0] d3_int,
    input wire [7:0] d4_int,

    output wire [ADDR_WIDTH-1:0] addr1_current,
    output wire [ADDR_WIDTH-1:0] addr1_previous,

    output wire [ADDR_WIDTH-1:0] addr2_current,
    output wire [ADDR_WIDTH-1:0] addr2_previous,

    output wire [ADDR_WIDTH-1:0] addr3_current,
    output wire [ADDR_WIDTH-1:0] addr3_previous,

    output wire [ADDR_WIDTH-1:0] addr4_current,
    output wire [ADDR_WIDTH-1:0] addr4_previous
);

    /*
     * RAM organization:
     *
     * group 0 : addresses 0       ... 1023
     * group 1 : addresses 1024    ... 2047
     * ...
     * group15 : addresses 15360   ... 16383
     */

    wire [ADDR_WIDTH-1:0] group_base =
        group_sel << 10;

    function [9:0] clamp_sample;
        input signed [11:0] value;
        begin
            if (value < 0)
                clamp_sample = 10'd0;
            else if (value >= NUM_SAMPLES)
                clamp_sample = NUM_SAMPLES - 1;
            else
                clamp_sample = value[9:0];
        end
    endfunction

    wire signed [11:0] raw1 =
        $signed({2'b00, sample_index}) -
        $signed({4'b0000, d1_int});

    wire signed [11:0] raw2 =
        $signed({2'b00, sample_index}) -
        $signed({4'b0000, d2_int});

    wire signed [11:0] raw3 =
        $signed({2'b00, sample_index}) -
        $signed({4'b0000, d3_int});

    wire signed [11:0] raw4 =
        $signed({2'b00, sample_index}) -
        $signed({4'b0000, d4_int});

    wire [9:0] off1 = clamp_sample(raw1);
    wire [9:0] off2 = clamp_sample(raw2);
    wire [9:0] off3 = clamp_sample(raw3);
    wire [9:0] off4 = clamp_sample(raw4);

    wire [9:0] prev1 =
        (off1 == 0) ? 0 : off1 - 1'b1;

    wire [9:0] prev2 =
        (off2 == 0) ? 0 : off2 - 1'b1;

    wire [9:0] prev3 =
        (off3 == 0) ? 0 : off3 - 1'b1;

    wire [9:0] prev4 =
        (off4 == 0) ? 0 : off4 - 1'b1;

    assign addr1_current =
        group_base + off1;

    assign addr1_previous =
        group_base + prev1;

    assign addr2_current =
        group_base + off2;

    assign addr2_previous =
        group_base + prev2;

    assign addr3_current =
        group_base + off3;

    assign addr3_previous =
        group_base + prev3;

    assign addr4_current =
        group_base + off4;

    assign addr4_previous =
        group_base + prev4;

endmodule
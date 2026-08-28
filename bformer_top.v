`timescale 1ns / 1ps

module bformer2_top #(
    parameter DATA_WIDTH          = 11,
    parameter ADDR_WIDTH          = 14,   // 16 groups × 1024 = 16384
    parameter NUM_SAMPLES         = 1024,
    parameter NUM_GROUPS          = 16,
    parameter NUM_FOCI            = 4,
    parameter FRAC_BITS           = 8,
    parameter DAS_WIDTH           = DATA_WIDTH + 3,
    parameter FRAME_PERIOD_CYCLES = 720898,
    parameter FRAME_GAP_CYCLES    = 0
)(
    input wire clk,
    input wire rst_n,

    input wire signed [DATA_WIDTH-1:0] adc1,
    input wire signed [DATA_WIDTH-1:0] adc2,
    input wire signed [DATA_WIDTH-1:0] adc3,
    input wire signed [DATA_WIDTH-1:0] adc4,

    output wire signed [DAS_WIDTH-1:0] beam_out,
    output wire beam_valid
);

    localparam INTERP_WIDTH = DATA_WIDTH + 1;

    wire capture_en;
    wire [ADDR_WIDTH-1:0] capture_addr;

    wire processing_valid;
    wire [9:0] sample_index;
    wire [3:0] group_sel;
    wire [1:0] focus_sel;

    wire acc_clear;
    wire acc_valid;
    wire first_group;
    wire frame_output_valid;
    wire busy;

    wire [7:0] d1_int;
    wire [7:0] d2_int;
    wire [7:0] d3_int;
    wire [7:0] d4_int;

    wire [7:0] d1_frac;
    wire [7:0] d2_frac;
    wire [7:0] d3_frac;
    wire [7:0] d4_frac;

    wire [ADDR_WIDTH-1:0] rd_addr1_curr;
    wire [ADDR_WIDTH-1:0] rd_addr1_prev;
    wire [ADDR_WIDTH-1:0] rd_addr2_curr;
    wire [ADDR_WIDTH-1:0] rd_addr2_prev;
    wire [ADDR_WIDTH-1:0] rd_addr3_curr;
    wire [ADDR_WIDTH-1:0] rd_addr3_prev;
    wire [ADDR_WIDTH-1:0] rd_addr4_curr;
    wire [ADDR_WIDTH-1:0] rd_addr4_prev;

    wire signed [DATA_WIDTH-1:0] adc1_curr;
    wire signed [DATA_WIDTH-1:0] adc1_prev;
    wire signed [DATA_WIDTH-1:0] adc2_curr;
    wire signed [DATA_WIDTH-1:0] adc2_prev;
    wire signed [DATA_WIDTH-1:0] adc3_curr;
    wire signed [DATA_WIDTH-1:0] adc3_prev;
    wire signed [DATA_WIDTH-1:0] adc4_curr;
    wire signed [DATA_WIDTH-1:0] adc4_prev;

    wire signed [INTERP_WIDTH-1:0] interp1;
    wire signed [INTERP_WIDTH-1:0] interp2;
    wire signed [INTERP_WIDTH-1:0] interp3;
    wire signed [INTERP_WIDTH-1:0] interp4;

    wire signed [DAS_WIDTH-1:0] das_sum;

    assign beam_out   = das_sum;
    assign beam_valid = processing_valid;

    tdm_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_SAMPLES(NUM_SAMPLES),
        .NUM_GROUPS(NUM_GROUPS),
        .NUM_FOCI(NUM_FOCI),
        .FRAME_GAP_CYCLES(FRAME_GAP_CYCLES),
        .FRAME_PERIOD_CYCLES(FRAME_PERIOD_CYCLES)
    ) u_tdm_controller (
        .clk(clk),
        .rst_n(rst_n),

        .capture_en(capture_en),
        .capture_addr(capture_addr),

        .processing_valid(processing_valid),
        .sample_index(sample_index),
        .group_sel(group_sel),
        .focus_sel(focus_sel),

        .acc_clear(acc_clear),
        .acc_valid(acc_valid),
        .first_group(first_group),
        .frame_output_valid(frame_output_valid),
        .busy(busy)
    );

    sample_memory_2 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_SAMPLES(NUM_SAMPLES),
        .NUM_GROUPS(NUM_GROUPS)
    ) u_sample_memory (
        .clk(clk),
        .rst_n(rst_n),

        .wr_en(capture_en),
        .wr_addr(capture_addr),

        .adc1_in(adc1),
        .adc2_in(adc2),
        .adc3_in(adc3),
        .adc4_in(adc4),

        .rd_addr1_current(rd_addr1_curr),
        .rd_addr1_previous(rd_addr1_prev),

        .rd_addr2_current(rd_addr2_curr),
        .rd_addr2_previous(rd_addr2_prev),

        .rd_addr3_current(rd_addr3_curr),
        .rd_addr3_previous(rd_addr3_prev),

        .rd_addr4_current(rd_addr4_curr),
        .rd_addr4_previous(rd_addr4_prev),

        .adc1_current(adc1_curr),
        .adc1_previous(adc1_prev),

        .adc2_current(adc2_curr),
        .adc2_previous(adc2_prev),

        .adc3_current(adc3_curr),
        .adc3_previous(adc3_prev),

        .adc4_current(adc4_curr),
        .adc4_previous(adc4_prev)
    );

    delay_lut #(
        .NUM_GROUPS(NUM_GROUPS),
        .NUM_FOCI(NUM_FOCI),
        .INT_BITS(8),
        .FRAC_BITS(FRAC_BITS)
    ) u_delay_lut (
        .focus_sel(focus_sel),
        .group_sel(group_sel),

        .d1_int(d1_int),
        .d1_frac(d1_frac),

        .d2_int(d2_int),
        .d2_frac(d2_frac),

        .d3_int(d3_int),
        .d3_frac(d3_frac),

        .d4_int(d4_int),
        .d4_frac(d4_frac)
    );

    fractional_delay_address_generator #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_SAMPLES(NUM_SAMPLES),
        .NUM_GROUPS(NUM_GROUPS)
    ) u_addr_gen (
        .group_sel(group_sel),
        .sample_index(sample_index),

        .d1_int(d1_int),
        .d2_int(d2_int),
        .d3_int(d3_int),
        .d4_int(d4_int),

        .addr1_current(rd_addr1_curr),
        .addr1_previous(rd_addr1_prev),

        .addr2_current(rd_addr2_curr),
        .addr2_previous(rd_addr2_prev),

        .addr3_current(rd_addr3_curr),
        .addr3_previous(rd_addr3_prev),

        .addr4_current(rd_addr4_curr),
        .addr4_previous(rd_addr4_prev)
    );

    fractional_delay_interpolator #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .OUT_WIDTH(INTERP_WIDTH)
    ) u_interp1 (
        .sample_current(adc1_curr),
        .sample_previous(adc1_prev),
        .frac(d1_frac),
        .sample_out(interp1)
    );

    fractional_delay_interpolator #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .OUT_WIDTH(INTERP_WIDTH)
    ) u_interp2 (
        .sample_current(adc2_curr),
        .sample_previous(adc2_prev),
        .frac(d2_frac),
        .sample_out(interp2)
    );

    fractional_delay_interpolator #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .OUT_WIDTH(INTERP_WIDTH)
    ) u_interp3 (
        .sample_current(adc3_curr),
        .sample_previous(adc3_prev),
        .frac(d3_frac),
        .sample_out(interp3)
    );

    fractional_delay_interpolator #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .OUT_WIDTH(INTERP_WIDTH)
    ) u_interp4 (
        .sample_current(adc4_curr),
        .sample_previous(adc4_prev),
        .frac(d4_frac),
        .sample_out(interp4)
    );

    das_beamformer #(
        .IN_WIDTH(INTERP_WIDTH),
        .OUT_WIDTH(DAS_WIDTH)
    ) u_das_beamformer (
        .x1(interp1),
        .x2(interp2),
        .x3(interp3),
        .x4(interp4),
        .beam_sum(das_sum)
    );

endmodule
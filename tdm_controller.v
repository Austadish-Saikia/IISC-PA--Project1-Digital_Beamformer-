
`timescale 1ns / 1ps

module tdm_controller #(
    parameter ADDR_WIDTH          = 16,
    parameter NUM_SAMPLES         = 1024,
    parameter NUM_GROUPS          = 16,
    parameter NUM_FOCI            = 4,
    parameter FRAME_GAP_CYCLES    = 0,
    parameter FRAME_PERIOD_CYCLES = 720898
)(
    input wire clk,
    input wire rst_n,


    output reg                  capture_en,
    output reg [ADDR_WIDTH-1:0] capture_addr,


    output reg                  processing_valid,
    output reg [9:0]            sample_index,
    output reg [3:0]            group_sel,
    output reg [1:0]            focus_sel,

    output reg                  acc_clear,
    output reg                  acc_valid,
    output reg                  first_group,
    output reg                  frame_output_valid,
    output reg                  busy
);


    localparam STATE_IDLE       = 3'd0;
    localparam STATE_CAPTURE    = 3'd1;
    localparam STATE_PROCESS    = 3'd2;
    localparam STATE_FRAME_DONE = 3'd3;
    localparam STATE_GAP        = 3'd4;

    reg [2:0] state;

  

    reg [3:0] adc_div_cnt;

    localparam integer CAPTURE_DEPTH =
        NUM_GROUPS * NUM_SAMPLES;

    reg [9:0] sample_cnt;
    reg [3:0] group_cnt;
    reg [1:0] focus_cnt;


    localparam integer PROCESS_COUNT =
        NUM_GROUPS * NUM_SAMPLES * NUM_FOCI;


    reg [31:0] gap_cnt;



    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
        end
        else begin
            case (state)

                STATE_IDLE: begin
                    state <= STATE_CAPTURE;
                end

                STATE_CAPTURE: begin
                 
                    if ((capture_addr == CAPTURE_DEPTH-1) &&
                        (adc_div_cnt == 4'd9)) begin

                        state <= STATE_PROCESS;
                    end
                end

                STATE_PROCESS: begin
    
                    if ((group_cnt  == NUM_GROUPS-1) &&
                        (sample_cnt == NUM_SAMPLES-1) &&
                        (focus_cnt  == NUM_FOCI-1)) begin

                        state <= STATE_FRAME_DONE;
                    end
                end

                STATE_FRAME_DONE: begin

                    if (FRAME_GAP_CYCLES != 0) begin
                        state <= STATE_GAP;
                    end
                    else begin
                        state <= STATE_CAPTURE;
                    end

                end

                STATE_GAP: begin

                    if (gap_cnt >= FRAME_GAP_CYCLES-1) begin
                        state <= STATE_CAPTURE;
                    end

                end

                default: begin
                    state <= STATE_IDLE;
                end

            endcase
        end
    end


    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            capture_en         <= 1'b0;
            capture_addr       <= {ADDR_WIDTH{1'b0}};

            processing_valid   <= 1'b0;

            sample_index       <= 10'd0;
            group_sel          <= 4'd0;
            focus_sel          <= 2'd0;

            acc_clear          <= 1'b0;
            acc_valid          <= 1'b0;
            first_group        <= 1'b0;

            frame_output_valid <= 1'b0;
            busy               <= 1'b0;

            adc_div_cnt        <= 4'd0;

            sample_cnt         <= 10'd0;
            group_cnt          <= 4'd0;
            focus_cnt          <= 2'd0;

            gap_cnt            <= 32'd0;

        end
        else begin


            capture_en         <= 1'b0;
            processing_valid   <= 1'b0;
            acc_clear          <= 1'b0;
            acc_valid          <= 1'b0;
            frame_output_valid <= 1'b0;

            case (state)

                STATE_IDLE: begin

                    busy <= 1'b0;

                    capture_addr <= {ADDR_WIDTH{1'b0}};
                    adc_div_cnt  <= 4'd0;

                    sample_cnt <= 10'd0;
                    group_cnt  <= 4'd0;
                    focus_cnt  <= 2'd0;

                    sample_index <= 10'd0;
                    group_sel    <= 4'd0;
                    focus_sel    <= 2'd0;

                    first_group <= 1'b0;

                end

                STATE_CAPTURE: begin

                    busy <= 1'b1;

                    if (adc_div_cnt == 4'd9) begin

                        adc_div_cnt <= 4'd0;

                        capture_en <= 1'b1;

                        if (capture_addr == CAPTURE_DEPTH-1) begin


                            capture_addr <= {ADDR_WIDTH{1'b0}};

                            sample_cnt <= 10'd0;
                            group_cnt  <= 4'd0;
                            focus_cnt  <= 2'd0;

                            sample_index <= 10'd0;
                            group_sel    <= 4'd0;
                            focus_sel    <= 2'd0;

                        end
                        else begin

                            capture_addr <= capture_addr + 1'b1;

                        end

                    end
                    else begin

                        adc_div_cnt <= adc_div_cnt + 1'b1;

                    end

                end


                STATE_PROCESS: begin

                    busy <= 1'b1;

   

                    sample_index <= sample_cnt;
                    group_sel    <= group_cnt;
                    focus_sel    <= focus_cnt;

                    first_group <=
                        (group_cnt == 0);

                    // --------------------------------------------------------
                    // Current processing point is valid.
                    // --------------------------------------------------------

                    processing_valid <= 1'b1;
                    acc_valid        <= 1'b1;

    

                    if (focus_cnt == NUM_FOCI-1) begin

                        focus_cnt <= 2'd0;

                        if (sample_cnt == NUM_SAMPLES-1) begin

                            sample_cnt <= 10'd0;

                            if (group_cnt == NUM_GROUPS-1) begin

                
                                group_cnt <= 4'd0;

                            end
                            else begin

                                group_cnt <= group_cnt + 1'b1;

                            end

                        end
                        else begin

                            sample_cnt <= sample_cnt + 1'b1;

                        end

                    end
                    else begin

                        focus_cnt <= focus_cnt + 1'b1;

                    end

                end


                STATE_FRAME_DONE: begin

                    busy <= 1'b0;

                    // One-clock frame completion pulse.
                    frame_output_valid <= 1'b1;

                    // Ensure processing is NOT valid here.
                    processing_valid <= 1'b0;

                    // Prepare next frame.
                    capture_addr <= {ADDR_WIDTH{1'b0}};

                    adc_div_cnt <= 4'd0;

                    sample_cnt <= 10'd0;
                    group_cnt  <= 4'd0;
                    focus_cnt  <= 2'd0;

                    sample_index <= 10'd0;
                    group_sel    <= 4'd0;
                    focus_sel    <= 2'd0;

                end


                STATE_GAP: begin

                    busy <= 1'b0;

                    processing_valid   <= 1'b0;
                    frame_output_valid <= 1'b0;

                    if (gap_cnt >= FRAME_GAP_CYCLES-1) begin

                        gap_cnt <= 32'd0;

                    end
                    else begin

                        gap_cnt <= gap_cnt + 1'b1;

                    end

                end

                default: begin

                    busy <= 1'b0;
                    state <= STATE_IDLE;

                end

            endcase
        end
    end

endmodule
`timescale 1ns / 1ps

module tb_bformer2_top;



    localparam DATA_WIDTH  = 11;
    localparam ADDR_WIDTH  = 14;
    localparam NUM_SAMPLES = 1024;
    localparam NUM_GROUPS  = 16;
    localparam NUM_FOCI    = 4;
    localparam FRAC_BITS   = 8;
    localparam DAS_WIDTH   = DATA_WIDTH + 3;
    localparam CLK_PERIOD_NS = 5;
    localparam TOTAL_VECTORS = NUM_GROUPS * NUM_SAMPLES;



    reg clk;
    reg rst_n;

    reg signed [DATA_WIDTH-1:0] adc1;
    reg signed [DATA_WIDTH-1:0] adc2;
    reg signed [DATA_WIDTH-1:0] adc3;
    reg signed [DATA_WIDTH-1:0] adc4;

    wire signed [DAS_WIDTH-1:0] beam_out;
    wire                        beam_valid;
    reg signed [DATA_WIDTH-1:0] csv_data [0:NUM_SAMPLES-1][0:63];

 
    integer csv_in;
    integer csv_file;


    integer r;
    integer c;
    integer scan_cnt;
    integer val [0:63];

    integer drive_addr;
    integer drive_group;
    integer drive_sample;

    bformer2_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_SAMPLES(NUM_SAMPLES),
        .NUM_GROUPS(NUM_GROUPS),
        .NUM_FOCI(NUM_FOCI),
        .FRAC_BITS(FRAC_BITS),
        .DAS_WIDTH(DAS_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .adc1(adc1),
        .adc2(adc2),
        .adc3(adc3),
        .adc4(adc4),
        .beam_out(beam_out),
        .beam_valid(beam_valid)
    );

 
    always #(CLK_PERIOD_NS / 2.0) clk = ~clk;


    initial begin
        csv_in = $fopen(
    "C:/Users/austa/OneDrive/Desktop/HOME_TURF/BFORMER_FINAL/BFORMER_FINAL/captrdata_11 (2).csv",
    "r"
);
        if (csv_in == 0) begin
            $display("ERROR: Could not open captrdata_11 (2).csv");
            $finish;
        end

        $display("================================================");
        $display("Loading CSV (1024 x 64)");
        $display("================================================");

        for (r = 0; r < NUM_SAMPLES; r = r + 1) begin

            for (c = 0; c < 64; c = c + 1)
                val[c] = 0;

            scan_cnt = $fscanf(
                csv_in,
                "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",
                val[0],  val[1],  val[2],  val[3],
                val[4],  val[5],  val[6],  val[7],
                val[8],  val[9],  val[10], val[11],
                val[12], val[13], val[14], val[15],
                val[16], val[17], val[18], val[19],
                val[20], val[21], val[22], val[23],
                val[24], val[25], val[26], val[27],
                val[28], val[29], val[30], val[31],
                val[32], val[33], val[34], val[35],
                val[36], val[37], val[38], val[39],
                val[40], val[41], val[42], val[43],
                val[44], val[45], val[46], val[47],
                val[48], val[49], val[50], val[51],
                val[52], val[53], val[54], val[55],
                val[56], val[57], val[58], val[59],
                val[60], val[61], val[62], val[63]
            );

            if (scan_cnt < 64) begin
                $display("ERROR: row %d has only %d values", r, scan_cnt);
                $finish;
            end

            for (c = 0; c < 64; c = c + 1)
                csv_data[r][c] = val[c][DATA_WIDTH-1:0];
        end

        $fclose(csv_in);
        $display("CSV loaded successfully.");
        $display("Sample 0, group0: %d %d %d %d",
            csv_data[0][0], csv_data[0][1], csv_data[0][2], csv_data[0][3]);
        $display("Sample 0, group15: %d %d %d %d",
            csv_data[0][60], csv_data[0][61], csv_data[0][62], csv_data[0][63]);
        $display("");
    end


    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;
        adc1  = 0;
        adc2  = 0;
        adc3  = 0;
        adc4  = 0;
        #100;
        rst_n = 1'b1;
        $display("RESET released at %d ns", $time);
    end

  
    always @(*) begin
        adc1 = 0;
        adc2 = 0;
        adc3 = 0;
        adc4 = 0;

        if (rst_n) begin
            drive_addr = uut.capture_addr;
            if (drive_addr >= 0 && drive_addr < TOTAL_VECTORS) begin
                drive_group  = drive_addr / NUM_SAMPLES;
                drive_sample = drive_addr % NUM_SAMPLES;
                if (drive_group >= 0 && drive_group < NUM_GROUPS &&
                    drive_sample >= 0 && drive_sample < NUM_SAMPLES) begin
                    adc1 = csv_data[drive_sample][drive_group*4 + 0];
                    adc2 = csv_data[drive_sample][drive_group*4 + 1];
                    adc3 = csv_data[drive_sample][drive_group*4 + 2];
                    adc4 = csv_data[drive_sample][drive_group*4 + 3];
                end
            end
        end
    end


    initial begin
        csv_file = $fopen("final_csv_8x8_corrected.csv", "w");
        if (csv_file == 0) begin
            $display("ERROR: Could not create final_csv_8x8_corrected.csv");
            $finish;
        end

 
        $fwrite(csv_file, "time_ns,");
        $fwrite(csv_file, "capture_addr,");
        $fwrite(csv_file, "processing_valid,");
        $fwrite(csv_file, "group,");
        $fwrite(csv_file, "focus,");
        $fwrite(csv_file, "sample,");
        $fwrite(csv_file, "d1_int,");
        $fwrite(csv_file, "d1_frac,");
        $fwrite(csv_file, "d2_int,");
        $fwrite(csv_file, "d2_frac,");
        $fwrite(csv_file, "d3_int,");
        $fwrite(csv_file, "d3_frac,");
        $fwrite(csv_file, "d4_int,");
        $fwrite(csv_file, "d4_frac,");
        $fwrite(csv_file, "interp1,");
        $fwrite(csv_file, "interp2,");
        $fwrite(csv_file, "interp3,");
        $fwrite(csv_file, "interp4,");
        $fwrite(csv_file, "das_sum,");
        $fwrite(csv_file, "beam_out\n");
    end

    always @(posedge clk) begin
        if (rst_n && uut.processing_valid) begin
            $fdisplay(csv_file,
                "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",
                $time,
                uut.capture_addr,
                uut.processing_valid,
                uut.group_sel,
                uut.focus_sel,
                uut.sample_index,
                uut.d1_int,
                uut.d1_frac,
                uut.d2_int,
                uut.d2_frac,
                uut.d3_int,
                uut.d3_frac,
                uut.d4_int,
                uut.d4_frac,
                uut.interp1,
                uut.interp2,
                uut.interp3,
                uut.interp4,
                uut.das_sum,
                uut.beam_out
            );
        end
    end

    // ================================================================
    // DEBUG PRINT (new group, focus=0, sample=0)
    // ================================================================

    always @(posedge clk) begin
        if (rst_n && uut.processing_valid &&
            uut.sample_index == 0 && uut.focus_sel == 0) begin
            $display("G%d F%d S%d | D=(%d.%d,%d.%d,%d.%d,%d.%d) | DAS=%d",
                uut.group_sel,
                uut.focus_sel,
                uut.sample_index,
                uut.d1_int, uut.d1_frac,
                uut.d2_int, uut.d2_frac,
                uut.d3_int, uut.d3_frac,
                uut.d4_int, uut.d4_frac,
                uut.das_sum
            );
        end
    end

    initial begin
        #3000000;
        $display("");
        $display("================================================");
        $display("SIMULATION FINISHED");
        $display("Output: final_csv_8x8_corrected.csv");
        $display("================================================");
        $fclose(csv_file);
        $finish;
    end

endmodule
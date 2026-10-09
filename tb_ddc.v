`timescale 1ns/1ps
// RTL processing-chain test. JTAG transport and the board top are not simulated.
module tb_ddc;
    reg clk = 0;
    always #10 clk = ~clk; // 50 MHz
    reg reset = 1;
    reg enable = 0;
    reg [6:0] phase_step = 18;
    wire tick;
    wire [6:0] phase;
    wire signed [15:0] signal_sample, lo_sine, lo_cosine;
    wire signed [15:0] mixed_i, mixed_q, filtered_i, filtered_q;
    wire valid_i, valid_q;
    integer filtered_count = 0;
    integer captured_count = 0;
    integer errors = 0;
    integer csv_file;
    integer test_lo;
    reg done = 0;
    reg capture_valid = 0;
    reg signed [15:0] captured_i = 0, captured_q = 0;
    integer expected_i [0:15];
    integer expected_q [0:15];

    sample_tick u_tick(.clk(clk), .reset(reset), .enable(enable), .tick(tick));
    test_signal u_signal(.clk(clk), .reset(reset), .sample_enable(tick), .sample(signal_sample));
    nco_phase u_phase(.clk(clk), .reset(reset), .sample_enable(tick), .phase_step(phase_step), .phase(phase));
    nco_lut u_lut(.phase(phase), .sine(lo_sine), .cosine(lo_cosine));
    iq_mixer u_mixer(.signal_sample(signal_sample), .lo_cosine(lo_cosine), .lo_sine(lo_sine), .mixed_i(mixed_i), .mixed_q(mixed_q));
    fir_lowpass u_fir_i(.clk(clk), .reset(reset), .sample_enable(tick), .sample_in(mixed_i), .sample_out(filtered_i), .output_valid(valid_i));
    fir_lowpass u_fir_q(.clk(clk), .reset(reset), .sample_enable(tick), .sample_in(mixed_q), .sample_out(filtered_q), .output_valid(valid_q));

    // Observe pre-edge valid/data just as the board capture logic does.
    // Discard outputs 0..7; retain outputs 8,13,...83.
    always @(posedge clk) begin
        capture_valid <= 0;
        if (reset) begin
            filtered_count = 0;
            captured_count = 0;
            done = 0;
            captured_i <= 0;
            captured_q <= 0;
        end else if (enable && !done) begin
            if (valid_i !== valid_q) begin
                $display("FAIL: I/Q valid signals differ at %t", $time);
                $fatal(1);
            end
            if (valid_i && valid_q) begin
                if ((filtered_count >= 8) && (((filtered_count-8) % 5) == 0)) begin
                    captured_i <= filtered_i;
                    captured_q <= filtered_q;
                    capture_valid <= 1;
                    $fdisplay(csv_file, "%0d,%0d,%0d,%0d", captured_count, captured_count*50, $signed(filtered_i), $signed(filtered_q));
                    if (($signed(filtered_i) !== expected_i[captured_count]) ||
                        ($signed(filtered_q) !== expected_q[captured_count])) begin
                        errors = errors + 1;
                        $display("FAIL LO=%0d pair=%0d: I=%0d Q=%0d expected I=%0d Q=%0d", test_lo, captured_count, $signed(filtered_i), $signed(filtered_q), expected_i[captured_count], expected_q[captured_count]);
                    end
                    captured_count = captured_count + 1;
                    if (captured_count == 16) done = 1;
                end
                filtered_count = filtered_count + 1;
            end
        end
    end

    task run_case;
        input integer lo_hz;
        integer k;
        integer errors_before;
        begin
            @(negedge clk);
            enable = 0;
            reset = 1;
            test_lo = lo_hz;
            phase_step = (lo_hz == 18000) ? 18 : 20;
            errors_before = errors;
            if (lo_hz == 18000) begin
                expected_i[0]=5066; expected_q[0]=2803;
                expected_i[1]=2451; expected_q[1]=5246;
                expected_i[2]=-1101; expected_q[2]=5685;
                expected_i[3]=-4232; expected_q[3]=3952;
                expected_i[4]=-5747; expected_q[4]=709;
                expected_i[5]=-5067; expected_q[5]=-2804;
                expected_i[6]=-2452; expected_q[6]=-5247;
                expected_i[7]=1100; expected_q[7]=-5686;
                expected_i[8]=4231; expected_q[8]=-3953;
                expected_i[9]=5746; expected_q[9]=-710;
                for (k=10; k<16; k=k+1) begin
                    expected_i[k]=expected_i[k-10];
                    expected_q[k]=expected_q[k-10];
                end
                csv_file=$fopen("SIM_DDC_18kHz.csv", "w");
            end else begin
                for (k=0; k<16; k=k+1) begin
                    expected_i[k]=5999; expected_q[k]=0;
                end
                csv_file=$fopen("SIM_DDC_20kHz.csv", "w");
            end
            if (!csv_file) $fatal(1, "Cannot open simulation CSV");
            $fdisplay(csv_file, "sample,time_us,I,Q");
            repeat (5) @(negedge clk);
            reset = 0;
            enable = 1;
            wait(done);
            @(negedge clk);
            enable = 0;
            $fclose(csv_file);
            if (errors == errors_before)
                $display("PASS: LO=%0d Hz, all 16 I/Q pairs match hardware capture", lo_hz);
            repeat (5) @(negedge clk);
        end
    endtask

    initial begin
        run_case(18000);
        run_case(20000);
        if (errors) $fatal(1, "%0d captured pairs failed comparison", errors);
        $display("PASS: both LO cases completed; 32 I/Q pairs matched.");
        $stop;
    end

    initial begin
        #2500000;
        $fatal(1, "Timeout: capture did not complete within 2.5 ms");
    end
endmodule

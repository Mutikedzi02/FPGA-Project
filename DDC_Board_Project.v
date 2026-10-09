module DDC_Board_Project (
    input wire MAX10_CLK1_50,
    input wire [9:0] SW,
    output wire [9:0] LEDR
);

    wire [9:0] control;

    wire sample_enable;
    wire capture_enable;

    wire [6:0] phase;
    wire [6:0] phase_step;

    wire signed [15:0] signal_sample;
    wire signed [15:0] lo_sine;
    wire signed [15:0] lo_cosine;

    wire signed [15:0] mixed_i;
    wire signed [15:0] mixed_q;
    wire signed [15:0] filtered_i;
    wire signed [15:0] filtered_q;

    wire valid_i;
    wire valid_q;
    wire [15:0] probe_data;

    reg signed [15:0] capture_i [0:15];
    reg signed [15:0] capture_q [0:15];

    reg [3:0] write_address = 4'd0;
    reg [3:0] warmup_count = 4'd0;
    reg [2:0] decimation_count = 3'd0;
    reg capture_done = 1'b0;

    // JTAG control bits:
    // [0]   Run capture
    // [1]   Reset
    // [5:2] Capture memory read address
    // [6]   LO selection: 0 = 18 kHz, 1 = 20 kHz
    // [7]   Probe selection: 0 = I, 1 = Q
    // [9:8] Unused

    assign capture_enable = control[0] && !capture_done;
    assign phase_step = control[6] ? 7'd20 : 7'd18;

    jtag_control u_jtag_control (
        .probe(probe_data),
        .source_clk(MAX10_CLK1_50),
        .source(control)
    );

    // 100 kHz sample enable from the 50 MHz board clock.
    sample_tick u_sample_tick (
        .clk(MAX10_CLK1_50),
        .reset(control[1]),
        .enable(capture_enable),
        .tick(sample_enable)
    );

    // Internally generated 20 kHz test signal.
    test_signal u_test_signal (
        .clk(MAX10_CLK1_50),
        .reset(control[1]),
        .sample_enable(sample_enable),
        .sample(signal_sample)
    );

    nco_phase u_nco_phase (
        .clk(MAX10_CLK1_50),
        .reset(control[1]),
        .sample_enable(sample_enable),
        .phase_step(phase_step),
        .phase(phase)
    );

    nco_lut u_nco_lut (
        .phase(phase),
        .sine(lo_sine),
        .cosine(lo_cosine)
    );

    iq_mixer u_iq_mixer (
        .signal_sample(signal_sample),
        .lo_cosine(lo_cosine),
        .lo_sine(lo_sine),
        .mixed_i(mixed_i),
        .mixed_q(mixed_q)
    );

    fir_lowpass u_filter_i (
        .clk(MAX10_CLK1_50),
        .reset(control[1]),
        .sample_enable(sample_enable),
        .sample_in(mixed_i),
        .sample_out(filtered_i),
        .output_valid(valid_i)
    );

    fir_lowpass u_filter_q (
        .clk(MAX10_CLK1_50),
        .reset(control[1]),
        .sample_enable(sample_enable),
        .sample_in(mixed_q),
        .sample_out(filtered_q),
        .output_valid(valid_q)
    );

    // Discard eight startup outputs, then retain one
    // filtered I/Q pair out of every five.
    // Stored sample rate: 100 kHz / 5 = 20 kHz.
    always @(posedge MAX10_CLK1_50) begin
        if (control[1]) begin
            write_address <= 4'd0;
            warmup_count <= 4'd0;
            decimation_count <= 3'd0;
            capture_done <= 1'b0;
        end else if (valid_i && valid_q && !capture_done) begin
            if (warmup_count < 4'd8) begin
                warmup_count <= warmup_count + 4'd1;
            end else if (decimation_count == 3'd0) begin
                capture_i[write_address] <= filtered_i;
                capture_q[write_address] <= filtered_q;

                decimation_count <= 3'd4;

                if (write_address == 4'd15)
                    capture_done <= 1'b1;
                else
                    write_address <= write_address + 4'd1;
            end else begin
                decimation_count <= decimation_count - 3'd1;
            end
        end
    end

    // Read captured I or Q through JTAG.
    // Read only after capture_done is asserted.
    assign probe_data = control[7]
                      ? capture_q[control[5:2]]
                      : capture_i[control[5:2]];

    // LEDR0: capture complete.
    // LEDR[4:1]: capture write address.
    assign LEDR = {5'b00000, write_address, capture_done};

endmodule
module fir_lowpass (
    input wire clk,
    input wire reset,
    input wire sample_enable,
    input wire signed [15:0] sample_in,
    output reg signed [15:0] sample_out,
    output reg output_valid
);

    localparam IDLE   = 3'd0;
    localparam SUM    = 3'd1;
    localparam PREP   = 3'd2;
    localparam DIVIDE = 3'd3;
    localparam FINISH = 3'd4;

    reg [2:0] state;
    reg signed [15:0] delay [0:8];
    reg [3:0] tap_index;

    reg signed [31:0] accumulator;
    reg signed [31:0] tap_value;
    reg signed [31:0] weighted_tap;

    reg negative_result;
    reg [31:0] dividend;
    reg [31:0] quotient;
    reg [5:0] remainder;
    reg [5:0] trial_remainder;
    reg [5:0] bits_left;

    integer j;

    // Coefficients: 1, 2, 3, 4, 5, 4, 3, 2, 1
    always @(*) begin
        tap_value = 32'sd0;

        if (tap_index <= 4'd8)
            tap_value = {{16{delay[tap_index][15]}},
                         delay[tap_index]};

        case (tap_index)
            4'd0, 4'd8:
                weighted_tap = tap_value;

            4'd1, 4'd7:
                weighted_tap = tap_value <<< 1;

            4'd2, 4'd6:
                weighted_tap = (tap_value <<< 1) + tap_value;

            4'd3, 4'd5:
                weighted_tap = tap_value <<< 2;

            4'd4:
                weighted_tap = (tap_value <<< 2) + tap_value;

            default:
                weighted_tap = 32'sd0;
        endcase

        trial_remainder = {remainder[4:0], dividend[31]};
    end

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            tap_index <= 4'd0;
            accumulator <= 32'sd0;
            negative_result <= 1'b0;
            dividend <= 32'd0;
            quotient <= 32'd0;
            remainder <= 6'd0;
            bits_left <= 6'd0;
            sample_out <= 16'sd0;
            output_valid <= 1'b0;

            for (j = 0; j < 9; j = j + 1)
                delay[j] <= 16'sd0;
        end else begin
            output_valid <= 1'b0;

            case (state)
                IDLE: begin
                    if (sample_enable) begin
                        for (j = 8; j > 0; j = j - 1)
                            delay[j] <= delay[j-1];

                        delay[0] <= sample_in;
                        tap_index <= 4'd0;
                        accumulator <= 32'sd0;
                        state <= SUM;
                    end
                end

                SUM: begin
                    accumulator <= accumulator + weighted_tap;

                    if (tap_index == 4'd8)
                        state <= PREP;
                    else
                        tap_index <= tap_index + 4'd1;
                end

                PREP: begin
                    negative_result <= accumulator[31];

                    if (accumulator[31])
                        dividend <= -accumulator;
                    else
                        dividend <= accumulator;

                    quotient <= 32'd0;
                    remainder <= 6'd0;
                    bits_left <= 6'd32;
                    state <= DIVIDE;
                end

                // Exact division by 25, one bit per clock.
                DIVIDE: begin
                    dividend <= {dividend[30:0], 1'b0};

                    if (trial_remainder >= 6'd25) begin
                        remainder <= trial_remainder - 6'd25;
                        quotient <= {quotient[30:0], 1'b1};
                    end else begin
                        remainder <= trial_remainder;
                        quotient <= {quotient[30:0], 1'b0};
                    end

                    bits_left <= bits_left - 6'd1;

                    if (bits_left == 6'd1)
                        state <= FINISH;
                end

                FINISH: begin
                    if (negative_result)
                        sample_out <= -$signed(quotient[15:0]);
                    else
                        sample_out <= $signed(quotient[15:0]);

                    output_valid <= 1'b1;
                    state <= IDLE;
                end

                default:
                    state <= IDLE;
            endcase
        end
    end

endmodule
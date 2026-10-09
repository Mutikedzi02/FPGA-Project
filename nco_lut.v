module nco_lut (
    input  wire [6:0] phase,
    output wire signed [15:0] sine,
    output wire signed [15:0] cosine
);

    wire [6:0] cosine_phase;

    assign cosine_phase = (phase >= 7'd75)
                        ? phase - 7'd75
                        : phase + 7'd25;

    function signed [15:0] sine_value;
        input [6:0] p;

        reg [6:0] index;
        reg negative;
        reg signed [15:0] magnitude;

        begin
            // Fold the full cycle into its first quarter.
            if (p <= 7'd25) begin
                index = p;
                negative = 1'b0;
            end
            else if (p <= 7'd50) begin
                index = 7'd50 - p;
                negative = 1'b0;
            end
            else if (p <= 7'd75) begin
                index = p - 7'd50;
                negative = 1'b1;
            end
            else begin
                index = 7'd100 - p;
                negative = 1'b1;
            end

            case (index)
                7'd0:  magnitude = 16'sd0;
                7'd1:  magnitude = 16'sd2057;
                7'd2:  magnitude = 16'sd4107;
                7'd3:  magnitude = 16'sd6140;
                7'd4:  magnitude = 16'sd8149;
                7'd5:  magnitude = 16'sd10126;
                7'd6:  magnitude = 16'sd12062;
                7'd7:  magnitude = 16'sd13952;
                7'd8:  magnitude = 16'sd15786;
                7'd9:  magnitude = 16'sd17557;
                7'd10: magnitude = 16'sd19260;
                7'd11: magnitude = 16'sd20886;
                7'd12: magnitude = 16'sd22431;
                7'd13: magnitude = 16'sd23886;
                7'd14: magnitude = 16'sd25247;
                7'd15: magnitude = 16'sd26509;
                7'd16: magnitude = 16'sd27666;
                7'd17: magnitude = 16'sd28714;
                7'd18: magnitude = 16'sd29648;
                7'd19: magnitude = 16'sd30466;
                7'd20: magnitude = 16'sd31163;
                7'd21: magnitude = 16'sd31738;
                7'd22: magnitude = 16'sd32187;
                7'd23: magnitude = 16'sd32509;
                7'd24: magnitude = 16'sd32702;
                7'd25: magnitude = 16'sd32767;
                default: magnitude = 16'sd0;
            endcase

            sine_value = negative ? -magnitude : magnitude;
        end
    endfunction

    assign sine   = sine_value(phase);
    assign cosine = sine_value(cosine_phase);

endmodule
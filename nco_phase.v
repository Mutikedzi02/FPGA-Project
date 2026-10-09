module nco_phase (
    input  wire       clk,
    input  wire       reset,
    input  wire       sample_enable,
    input  wire [6:0] phase_step,
    output reg  [6:0] phase = 7'd0
);

    wire [7:0] phase_sum;

    assign phase_sum = {1'b0, phase}
                     + {1'b0, phase_step};

    always @(posedge clk) begin
        if (reset)
            phase <= 7'd0;
        else if (sample_enable) begin
            if (phase_sum >= 8'd100)
                phase <= phase_sum - 8'd100;
            else
                phase <= phase_sum[6:0];
        end
    end

endmodule
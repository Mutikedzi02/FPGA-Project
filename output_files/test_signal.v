module test_signal (
    input  wire clk,
    input  wire reset,
    input  wire sample_enable,
    output reg signed [15:0] sample
);

    reg [2:0] sample_index = 3'd0;

    always @(posedge clk) begin
        if (reset)
            sample_index <= 3'd0;
        else if (sample_enable) begin
            if (sample_index == 3'd4)
                sample_index <= 3'd0;
            else
                sample_index <= sample_index + 3'd1;
        end
    end

    always @(*) begin
        case (sample_index)
            3'd0: sample =  16'sd12000;
            3'd1: sample =  16'sd3708;
            3'd2: sample = -16'sd9708;
            3'd3: sample = -16'sd9708;
            3'd4: sample =  16'sd3708;
            default: sample = 16'sd0;
        endcase
    end

endmodule
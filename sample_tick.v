module sample_tick (
    input  wire clk,
    input  wire reset,
    input  wire enable,
    output wire tick
);

    reg [8:0] divider = 9'd0;

    assign tick = enable && !reset && (divider == 9'd499);

    always @(posedge clk) begin
        if (reset) begin
            divider <= 9'd0;
        end
        else if (enable) begin
            if (divider == 9'd499)
                divider <= 9'd0;
            else
                divider <= divider + 9'd1;
        end
    end

endmodule
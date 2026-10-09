module iq_mixer (
    input  wire signed [15:0] signal_sample,
    input  wire signed [15:0] lo_cosine,
    input  wire signed [15:0] lo_sine,
    output wire signed [15:0] mixed_i,
    output wire signed [15:0] mixed_q
);

    wire signed [31:0] product_i;
    wire signed [31:0] product_q;
    wire signed [31:0] negative_product_q;

    assign product_i = signal_sample * lo_cosine;
    assign product_q = signal_sample * lo_sine;

    assign negative_product_q = -product_q;

    assign mixed_i = product_i >>> 15;
    assign mixed_q = negative_product_q >>> 15;

endmodule
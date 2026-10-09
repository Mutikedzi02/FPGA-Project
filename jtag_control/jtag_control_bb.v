
module jtag_control (
	probe,
	source_clk,
	source);	

	input	[15:0]	probe;
	input		source_clk;
	output	[9:0]	source;
endmodule

// Simple encoders

module encoder #(
    parameter WIDTH = 2,
    parameter LOG_WIDTH = ($clog2(WIDTH) > 0 ? $clog2(WIDTH) : 1)
) (
    input   wire   [WIDTH-1:0]    one_hot,
    output  reg    [LOG_WIDTH-1:0]    encoded
);

reg [WIDTH-1:0] mask [LOG_WIDTH-1:0];

integer i, j;

always @(*) begin
	for (i = 0; i < LOG_WIDTH; i = i + 1) begin
		for (j = 0; j < WIDTH; j = j + 1) begin
			mask[i][j] = ((j & (1 << i)) != 0) ? 1'b1 : 1'b0;
		end
	end

	for (i = 0; i < WIDTH; i = i + 1) begin
		encoded[i] = |(mask[i] & one_hot);
	end
end

endmodule

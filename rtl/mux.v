module Mux2 #(
	parameter W = 32
) (
	input wire s,
	input wire [W-1:0] i0,
	input wire [W-1:0] i1,
	output wire [W-1:0] o
);
	assign o = s ? i1 : i0;
endmodule


module Mux3 #(
	parameter W = 32
) (
	input wire [1:0] s,
	input wire [W-1:0] i0,
	input wire [W-1:0] i1,
	input wire [W-1:0] i2,
	output wire [W-1:0] o
);
	assign o = s[1] ? i2 : s[0] ? i1 : i0;
endmodule


module Mux4 #(
	parameter W = 32
) (
	input wire [1:0] s,
	input wire [W-1:0] i0,
	input wire [W-1:0] i1,
	input wire [W-1:0] i2,
	input wire [W-1:0] i3,
	output wire [W-1:0] o
);
	assign o = s[1] ? (s[0]? i3 : i2) : (s[0] ? i1 : i0);
endmodule


module Mux5 #(
	parameter W = 32
) (
	input wire [2:0] s,
	input wire [W-1:0] i0,
	input wire [W-1:0] i1,
	input wire [W-1:0] i2,
	input wire [W-1:0] i3,
	input wire [W-1:0] i4,
	output wire [W-1:0] o
);

`ifdef SIM
	assign o = s[2] ? (i4) : (s[1] ? (s[0]? i3 : i2) : (s[0] ? i1 : i0));
`else
	Mux8 #(
        .W(W))
        aux (
        .s(s),
        .i0(i0),
        .i1(i1),
        .i2(i2),
        .i3(i3),
        .i4(i4),
        .i5({W{1'b0}}),
        .i6({W{1'b0}}),
        .i7({W{1'b0}}),
        .o(o));
`endif

endmodule


module Mux6 #(
	parameter W = 32
) (
	input wire [2:0] s,
	input wire [W-1:0] i0,
	input wire [W-1:0] i1,
	input wire [W-1:0] i2,
	input wire [W-1:0] i3,
	input wire [W-1:0] i4,
	input wire [W-1:0] i5,
	output wire [W-1:0] o
);

`ifdef SIM
	assign o = s[2] ? (s[0]? i5 : i4) : (s[1] ? (s[0]? i3 : i2) : (s[0] ? i1 : i0));
`else
	Mux8 #(
        .W(W))
        aux (
        .s(s),
        .i0(i0),
        .i1(i1),
        .i2(i2),
        .i3(i3),
        .i4(i4),
        .i5(i5),
        .i6({W{1'b0}}),
        .i7({W{1'b0}}),
        .o(o));
`endif

endmodule


module Mux7 #(
	parameter W = 32
) (
	input wire [2:0] s,
	input wire [W-1:0] i0,
	input wire [W-1:0] i1,
	input wire [W-1:0] i2,
	input wire [W-1:0] i3,
	input wire [W-1:0] i4,
	input wire [W-1:0] i5,
	input wire [W-1:0] i6,
	output wire [W-1:0] o
);

`ifdef SIM
	assign o = s[2] ? (s[1] ? i6 : s[0] ? i5 : i4) : (s[1] ? (s[0]? i3 : i2) : (s[0] ? i1 : i0));
`else
	Mux8 #(
        .W(W))
        aux (
        .s(s),
        .i0(i0),
        .i1(i1),
        .i2(i2),
        .i3(i3),
        .i4(i4),
        .i5(i5),
        .i6(i6),
        .i7({W{1'b0}}),
        .o(o));
`endif

endmodule


module Mux8 #(
	parameter W = 32
) (
	input wire [2:0] s,
	input wire [W-1:0] i0,
	input wire [W-1:0] i1,
	input wire [W-1:0] i2,
	input wire [W-1:0] i3,
	input wire [W-1:0] i4,
	input wire [W-1:0] i5,
	input wire [W-1:0] i6,
	input wire [W-1:0] i7,
	output wire [W-1:0] o
);

`ifdef SIM
	assign o = s[2] ? (s[1] ? (s[0]? i7 : i6) : (s[0] ? i5 : i4)) : (s[1] ? (s[0]? i3 : i2) : (s[0] ? i1 : i0));
`else
	assign done = 0;
	genvar i;

	generate for (i = 0; i < W; i = i + 1) begin

		wire o0, o1;

		LUT6 #(
		.INIT    (64'hFF00F0F0CCCCAAAA))
		selection0_lut( 
		.I0     (i0[i]),
		.I1     (i1[i]),
		.I2     (i2[i]),
		.I3     (i3[i]),
		.I4     (s[0]),
		.I5     (s[1]),
		.O      (o0)); 


		LUT6 #(
		.INIT    (64'hFF00F0F0CCCCAAAA))
		selection1_lut( 
		.I0     (i4[i]),
		.I1     (i5[i]),
		.I2     (i6[i]),
		.I3     (i7[i]),
		.I4     (s[0]),
		.I5     (s[1]),
		.O      (o1)); 


		MUXF7 combiner0_muxf7 ( 
	       .I0      (o0),
	       .I1      (o1),                     
	       .S       (s[2]),
	       .O       (o[i])) ;

	end endgenerate
`endif

endmodule


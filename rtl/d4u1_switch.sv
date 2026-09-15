`default_nettype none

module d4u1_switch #(
	parameter N	= 4,		// number of clients
	parameter A_W	= $clog2(N)+1,	// addr width
	parameter D_W	= 32,		// data width
	parameter PAYLOAD_W = A_W+D_W+1,
	parameter posl  = 0,		// which level
	parameter posx 	= 0,		// which position
	parameter NUM_D = 4,
	parameter NUM_U = 1
) (
	input  wire 			clk,		// clock
	input  wire 			rst,		// reset
	input  wire 			ce,			// clock enable
	
	input  	wire	[PAYLOAD_W-1:0] 	d_i	[NUM_D-1:0],	// d  input payload
	output	wire	[NUM_D-1:0]		d_i_bp	,	// d  input backpressured
	input	wire	[NUM_D-1:0]		d_i_v	,	// d  input valid
	
	input  	wire	[PAYLOAD_W-1:0] 	u_i	[NUM_U-1:0],	// u    input payload
	output	wire	[NUM_U-1:0]		u_i_bp	,	// u    input backpressured
	input	wire	[NUM_U-1:0]		u_i_v	,	// u    input valid

	output 	wire	[PAYLOAD_W-1:0] 	d_o	[NUM_D-1:0],	// d  input payload
	input	wire	[NUM_D-1:0]		d_o_bp	,	// d  input backpressured
	output	wire	[NUM_D-1:0]		d_o_v	,	// d  input valid

	output 	wire	[PAYLOAD_W-1:0] 	u_o	[NUM_U-1:0],	// u    input payload
	input	wire	[NUM_U-1:0]		u_o_bp	,	// u    input backpressured
	output	wire	[NUM_U-1:0]		u_o_v	,	// u    input valid

	output 	wire 			done		// done
);

genvar i;

// down output selects
wire [$clog2(NUM_U+NUM_D-1)-1:0] d_sel [NUM_D-1:0];
wire [$clog2(NUM_D)-1:0] u_sel [NUM_U-1:0];

// wire to outs
wire [PAYLOAD_W-1:0] d_o_c [NUM_D-1:0];
wire [PAYLOAD_W-1:0] u_o_c [NUM_U-1:0];

wire [NUM_D-1:0] d_o_v_c;
wire [NUM_U-1:0] u_o_v_c;

// registered outs
reg [PAYLOAD_W-1:0] d_o_r [NUM_D-1:0];
reg [PAYLOAD_W-1:0] u_o_r [NUM_U-1:0];

// in addresses
wire [A_W-1:0] d_i_addr [NUM_D-1:0];
wire [A_W-1:0] u_i_addr [NUM_U-1:0];

// registered valids
reg [NUM_D-1:0] d_o_v_r;
reg [NUM_U-1:0] u_o_v_r;

// get addresses

    Mux4 #(
        .W(PAYLOAD_W)
    ) d_mux0 (
        .s(d_sel[0]),
        .i0(d_i[1]),
        .i1(d_i[2]),
        .i2(d_i[3]),
        .i3(u_i[0]),
        .o(d_o_c[0])
    );

    Mux4 #(
        .W(PAYLOAD_W)
    ) d_mux1 (
        .s(d_sel[1]),
        .i0(d_i[0]),
        .i1(d_i[2]),
        .i2(d_i[3]),
        .i3(u_i[0]),
        .o(d_o_c[1])
    );

    Mux4 #(
        .W(PAYLOAD_W)
    ) d_mux2 (
        .s(d_sel[2]),
        .i0(d_i[0]),
        .i1(d_i[1]),
        .i2(d_i[3]),
        .i3(u_i[0]),
        .o(d_o_c[2])
    );

    Mux4 #(
        .W(PAYLOAD_W)
    ) d_mux3 (
        .s(d_sel[3]),
        .i0(d_i[0]),
        .i1(d_i[1]),
        .i2(d_i[2]),
        .i3(u_i[0]),
        .o(d_o_c[3])
    );

generate for (i = 0; i < NUM_D; i = i + 1) begin
    assign d_i_addr[i] = d_i[i][D_W+A_W-1:D_W];

    always @(posedge(clk)) begin
        if (rst) begin
            d_o_v_r[i] <= '0;
            d_o_r[i] <= '0;
        end else begin
            if (!d_o_bp[i])
            begin
                d_o_v_r[i] <= d_o_v_c[i];
                d_o_r[i] <= {d_o_c[i]};
            end
        end
    end

    assign d_o[i] = {d_o_r[i]};
    assign d_o_v[i] = d_o_v_r[i];

end endgenerate

generate for (i = 0; i < NUM_U; i = i + 1) begin
    assign u_i_addr[i] = u_i[i][D_W+A_W-1:D_W];
    Mux4 #(
        .W(PAYLOAD_W)
    ) u_mux (
        .s(u_sel[i]),
        .i0(d_i[0]),
        .i1(d_i[1]),
        .i2(d_i[2]),
        .i3(d_i[3]),
        .o(u_o_c[i])
    );

    always @(posedge(clk)) begin
        if (rst) begin
            u_o_v_r[i] <= '0;
            u_o_r[i] <= '0;
        end else begin
            if (!u_o_bp[i])
            begin
                u_o_v_r[i] <= u_o_v_c[i];
                u_o_r[i] <= {u_o_c[i]};
            end
        end
    end

    assign u_o[i] = {u_o_r[i]};
    assign u_o_v[i] = u_o_v_r[i];

end endgenerate

// Instantiate router
d4u1_route #(
	.N(N),
	.A_W(A_W),
	.D_W(D_W),
	.posl(posl),
	.posx(posx)
) router (
	.clk(clk),
	.rst(rst),
	.ce(ce),
	.d_i_v(d_i_v),
	.u_i_v(u_i_v),
	.d_i_bp(d_i_bp),
	.u_i_bp(u_i_bp),
	.d_i_addr(d_i_addr),
	.u_i_addr(u_i_addr),
	.d_o_v(d_o_v_c),
	.u_o_v(u_o_v_c),
	.d_o_bp(d_o_bp),
	.u_o_bp(u_o_bp),
	.d_sel(d_sel),
	.u_sel(u_sel)
);

// generate done signal

`ifdef SIM
	reg done_sig=0;
	always @(posedge clk) begin
		if(!|d_i_v && !|u_i_v) begin
			done_sig <= 1;
		end else begin
			done_sig <= 0;
		end
	end
	assign done = done_sig;
`else
	assign done = 0;
`endif

endmodule

`default_nettype none

module d4u2_route #(
	parameter N	= 4,		// number of clients
	parameter A_W	= $clog2(N)+1,	// log number of clients
	parameter D_W	= 32,
	parameter posl  = 0,		// which level
	parameter posx 	= 0,		// which position
	parameter NUM_D = 4,
	parameter NUM_U = 2,
	parameter D_PER_U = (NUM_D/NUM_U),
	parameter LOG_D_PER_U = ($clog2(D_PER_U) > 0 ? $clog2(D_PER_U) : 1)
) (
	input  	wire 			    clk		,	// clock
	input  	wire 			    rst		,	// reset
	input  	wire 			    ce		,	// clock enable
	input  	wire    [NUM_D-1:0]	    d_i_v		,	// down0 input valid
	input  	wire    [NUM_U-1:0]	    u_i_v		,	// up0 input valid
	output  wire    [NUM_D-1:0]	    d_i_bp		,	// down0 input is backpressured
	output  wire    [NUM_U-1:0]	    u_i_bp		,	// up0 input is backpressured
	input  	wire	[A_W-1:0]	d_i_addr [NUM_D-1:0]	,	// down0 input addr
	input  	wire 	[A_W-1:0] 	u_i_addr [NUM_U-1:0]	, 	// up0 input addr
	output 	wire    [NUM_D-1:0]	    d_o_v		,	// valid for down mux
	output 	wire    [NUM_U-1:0]	    u_o_v		,	// valid for up mux
	input	wire    [NUM_D-1:0]	    d_o_bp		,	// down0 output is backpressured
	input	wire	[NUM_U-1:0]	    u_o_bp		,	// down1 output is backpressured
	output 	wire	[$clog2(NUM_U+NUM_D-1)-1:0] 	  d_sel [NUM_D-1:0],	// select for down0 mux
	output 	wire	[LOG_D_PER_U-1:0]                 u_sel [NUM_U-1:0]	// select for down0 mux
);

localparam SWITCH_PREFIX_OFFSET = 2*posl;
localparam ADDR_PREFIX_OFFSET = 2*(posl+1);
localparam ADDR_PREFIX_SIZE = A_W - 2*(posl+1);

wire [ADDR_PREFIX_SIZE-1 : 0] switch_prefix;
assign switch_prefix = posx[SWITCH_PREFIX_OFFSET+ADDR_PREFIX_SIZE-1 : SWITCH_PREFIX_OFFSET];

localparam ADDR_ROUTE_OFFSET = 2*posl;
localparam ADDR_ROUTE_SIZE = 2;

// wires for interfacing with arbiter
genvar i, j;

//
wire [NUM_D-1:0] d_got_d [NUM_D-1:0];
wire [NUM_D-1:0] u_got_d [NUM_U-1:0];

wire [NUM_U-1:0] d_got_u [NUM_D-1:0];

wire [NUM_D-1:0] d_wants_d [NUM_D-1:0];
wire [NUM_D-1:0] u_wants_d [NUM_U-1:0];
wire [NUM_U-1:0] d_wants_u [NUM_D-1:0];

// manage d 
generate for (i = 0; i < NUM_D; i = i + 1) begin : gen_d
    wire [ADDR_ROUTE_SIZE-1 : 0] d_route_bits = d_i_addr[i][ADDR_ROUTE_OFFSET+ADDR_ROUTE_SIZE-1 : ADDR_ROUTE_OFFSET];
    wire [ADDR_PREFIX_SIZE-1 : 0] d_prefix_bits = d_i_addr[i][ADDR_PREFIX_OFFSET+ADDR_PREFIX_SIZE-1 : ADDR_PREFIX_OFFSET];
    wire d_turns = d_prefix_bits == switch_prefix;

    wire [NUM_D-2:0] d_wanted_by_d;
    wire [NUM_U-1:0] d_wanted_by_u;
    wire [NUM_U+NUM_D-2:0] d_grants;

    for (j = 0; j < i; j = j + 1) begin
        assign d_wants_d[i][j] = d_i_v[i] && d_turns && (d_route_bits == j);
	assign d_wanted_by_d[j] = d_wants_d[j][i];
	assign d_got_d[j][i] = d_grants[j];
    end

	assign d_wants_d[i][i] = 0;
	assign d_got_d[i][i] = 0;

    for (j = i + 1; j < NUM_D; j = j + 1) begin
        assign d_wants_d[i][j] = d_i_v[i] && d_turns && (d_route_bits == j);
	assign d_wanted_by_d[j-1] = d_wants_d[j][i];
	assign d_got_d[j][i] = d_grants[j-1];
    end
    
    for (j = 0; j < NUM_U; j = j + 1) begin
        assign d_wants_u[i][j] = (i/D_PER_U == j) ? (d_i_v[i] && !d_turns) : 1'b0;
	assign d_wanted_by_u[j] = u_wants_d[j][i];
	assign u_got_d[j][i] = d_grants[j+NUM_D-1];
    end

    rr_arbiter #(.WORD_WIDTH(NUM_U+NUM_D-1)) rrD (.clk(clk), .rst(rst), .requests({d_wanted_by_u, d_wanted_by_d}), .grant(d_grants));
    encoder #(.WIDTH(NUM_U+NUM_D-1)) encD (.one_hot({d_grants}), .encoded(d_sel[i]));

    assign d_o_v[i] = |d_grants;
    assign d_i_bp[i] = |(d_wants_d[i] & (~d_got_d[i] | d_o_bp)) || |(d_wants_u[i] & (~d_got_u[i] | u_o_bp));

end endgenerate

// manage u
generate for (i = 0; i < NUM_U; i = i + 1) begin : gen_u
    wire [ADDR_ROUTE_SIZE-1 : 0] u_route_bits = u_i_addr[i][ADDR_ROUTE_OFFSET+ADDR_ROUTE_SIZE-1 : ADDR_ROUTE_OFFSET];
    wire [D_PER_U-1:0] u_wanted_by_d;
    wire [D_PER_U-1:0] u_grants;
    
    for (j = 0; j < NUM_D; j = j + 1) begin
        assign u_wants_d[i][j] = u_i_v[i] && (u_route_bits == j);
	if (j/D_PER_U == i) begin
		assign d_got_u[j][i] = u_grants[j%D_PER_U];
		assign u_wanted_by_d[j%D_PER_U] = d_wants_u[j][i];
	end else begin
		assign d_got_u[j][i] = 1'b0;
	end
    end

    rr_arbiter #(.WORD_WIDTH(D_PER_U)) rrU (.clk(clk), .rst(rst), .requests(u_wanted_by_d), .grant(u_grants));
    encoder #(.WIDTH(D_PER_U)) encU (.one_hot({u_grants}), .encoded(u_sel[i]));

    assign u_o_v[i] = |u_grants;
    assign u_i_bp[i] = |(u_wants_d[i] & (~u_got_d[i] | d_o_bp));
    
end endgenerate

endmodule

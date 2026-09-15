`default_nettype none

module d4u4_switch_top
#
(
	parameter	N	= 4,			//number of clients
	parameter	WRAP	= 1,			//crossbar?
	parameter	A_W	= $clog2(N) + 1, 	//addr width
	parameter	D_W	= 32,			//data width
        parameter   EXT_PAYLOAD_W = A_W + D_W,
        parameter   INT_PAYLOAD_W = A_W + D_W + 1,
	parameter	posl	= 0,			//which level
	parameter	posx	= 0, 		//which position
	parameter	NUM_D	= 4,
	parameter	NUM_U	= 4

)
(
	input  wire 			clk,		// clock
	input  wire 			rst,		// reset
	input  wire 			ce,		// clock enable
	
	input  	wire	[EXT_PAYLOAD_W-1:0] 	s_axis_d_wdata	[NUM_D-1:0],	
	output	wire    [NUM_D-1:0]	s_axis_d_wready	,
	input	wire    [NUM_D-1:0]	s_axis_d_wvalid	,
	input	wire    [NUM_D-1:0]	s_axis_d_wlast	,
	
	input  	wire	[EXT_PAYLOAD_W-1:0] 	s_axis_u_wdata	[NUM_U-1:0],	
	output	wire    [NUM_U-1:0]	s_axis_u_wready	,
	input	wire    [NUM_U-1:0]	s_axis_u_wvalid	,
	input	wire    [NUM_U-1:0]	s_axis_u_wlast	,

	output 	wire	[EXT_PAYLOAD_W-1:0] 	m_axis_d_wdata	[NUM_D-1:0],
	input	wire    [NUM_D-1:0]	m_axis_d_wready	,
	output	wire    [NUM_D-1:0]	m_axis_d_wvalid	,
	output	wire    [NUM_D-1:0]	m_axis_d_wlast	,	

	output 	wire	[EXT_PAYLOAD_W-1:0] 	m_axis_u_wdata	[NUM_U-1:0],
	input	wire    [NUM_U-1:0]	m_axis_u_wready	,
	output	wire    [NUM_U-1:0]	m_axis_u_wvalid	,
	output	wire    [NUM_U-1:0]	m_axis_u_wlast	,	

	output 	wire 			done		// done
);

genvar i;

// previous vals

reg [EXT_PAYLOAD_W-1:0] previous_d [NUM_D-1:0];
reg [EXT_PAYLOAD_W-1:0] previous_u [NUM_U-1:0];

// now counter
integer now = 0;

always@(posedge clk)
begin
	now <= now+1;
end

// switch payload inputs

wire [INT_PAYLOAD_W-1:0] switch_i_d_d [NUM_D-1:0];
wire [INT_PAYLOAD_W-1:0] switch_i_d_u [NUM_U-1:0];

// switch valid inputs

wire [NUM_D-1:0] switch_i_v_d;
wire [NUM_U-1:0] switch_i_v_u;

// switch bp inputs

wire [NUM_D-1:0] switch_i_b_d;
wire [NUM_U-1:0] switch_i_b_u;

// switch payload outputs

wire [INT_PAYLOAD_W-1:0] switch_o_d_d [NUM_D-1:0];
wire [INT_PAYLOAD_W-1:0] switch_o_d_u [NUM_U-1:0];

// switch valid outputs

wire [NUM_D-1:0] switch_o_v_d;
wire [NUM_U-1:0] switch_o_v_u;

// switch bp outputs

wire [NUM_D-1:0] switch_o_b_d;
wire [NUM_U-1:0] switch_o_b_u;

// switch instantiation

d4u4_switch #(
	.N(N),
	.A_W(A_W),
	.D_W(D_W),
	.posl(posl),
	.posx(posx)
) switch (
	.clk(clk),
	.rst(rst),
	.ce(ce),
	
	.d_i(switch_i_d_d)	,
	.d_i_bp(switch_i_b_d)	,
	.d_i_v(switch_i_v_d)	,
	
	.u_i(switch_i_d_u)	,
	.u_i_bp(switch_i_b_u)	,
	.u_i_v(switch_i_v_u)	,

	.d_o(switch_o_d_d)	,
	.d_o_bp(switch_o_b_d)	,
	.d_o_v(switch_o_v_d)	,

	.u_o(switch_o_d_u)	,
	.u_o_bp(switch_o_b_u)	,
	.u_o_v(switch_o_v_u)	,

	.done(done)
);

// Manage d shadow registers

wire	[INT_PAYLOAD_W-1:0]	bp_i_d_d [NUM_D-1:0];
wire	[NUM_D-1:0]		bp_i_v_d;
wire	[NUM_D-1:0]		bp_i_b_d;

wire	[INT_PAYLOAD_W-1:0]	bp_o_d_d [NUM_D-1:0];
wire	[NUM_D-1:0]		bp_o_v_d;
wire	[NUM_D-1:0]		bp_o_b_d;

generate for (i = 0; i < NUM_D; i = i + 1) begin

	assign bp_i_v_d[i]	= s_axis_d_wvalid[i];
	assign bp_i_d_d[i]	= {s_axis_d_wlast[i], s_axis_d_wdata[i]};
	assign s_axis_d_wready[i]	= !bp_i_b_d[i];

	assign switch_i_v_d[i]	= bp_o_v_d[i];
	assign switch_i_d_d[i]	= bp_o_d_d[i];
	assign bp_o_b_d[i]	= switch_i_b_d[i];

    assign m_axis_d_wvalid[i] = switch_o_v_d[i];
    assign m_axis_d_wlast[i] = switch_o_d_d[i][INT_PAYLOAD_W-1];
    assign switch_o_b_d[i] = !m_axis_d_wready[i];
    assign m_axis_d_wdata[i] = switch_o_d_d[i][EXT_PAYLOAD_W-1:0];

	shadow_reg_combi
	#(
		.D_W		(D_W	),
		.A_W		(A_W	)
	)
	bp_D
	(
		.clk		(clk		), 
		.rst		(rst		), 
		.i_v		(bp_i_v_d[i]	),
		.i_d		(bp_i_d_d[i]	), 
	 	.i_b		(bp_i_b_d[i]	),
	 	.o_v		(bp_o_v_d[i]	),
		.o_d		(bp_o_d_d[i]	),	 
		.o_b		(bp_o_b_d[i]	) // unregistered from DOR logic
	);

    always@(posedge clk)
    begin
        if (previous_d[i]!=m_axis_d_wdata[i])
        begin
            $display("Time%0d: switching",now-1);
            previous_d[i] <= m_axis_d_wdata[i];
        end
    end

end endgenerate

// Manage u shadow registers

wire	[INT_PAYLOAD_W-1:0]	bp_i_d_u [NUM_U-1:0];
wire	[NUM_U-1:0]		bp_i_v_u;
wire	[NUM_U-1:0]		bp_i_b_u;

wire	[INT_PAYLOAD_W-1:0]	bp_o_d_u [NUM_U-1:0];
wire	[NUM_U-1:0]		bp_o_v_u;
wire	[NUM_U-1:0]		bp_o_b_u;

generate for (i = 0; i < NUM_U; i = i + 1) begin

	assign bp_i_v_u[i]	= s_axis_u_wvalid[i];
	assign bp_i_d_u[i]	= {s_axis_u_wlast[i], s_axis_u_wdata[i]};
	assign s_axis_u_wready[i]	= !bp_i_b_u[i];

	assign switch_i_v_u[i]	= bp_o_v_u[i];
	assign switch_i_d_u[i]	= bp_o_d_u[i];
	assign bp_o_b_u[i]	= switch_i_b_u[i];

    assign m_axis_u_wvalid[i] = switch_o_v_u[i];
    assign m_axis_u_wlast[i] = switch_o_d_u[i][INT_PAYLOAD_W-1];
    assign switch_o_b_u[i] = !m_axis_u_wready[i];
    assign m_axis_u_wdata[i] = switch_o_d_u[i][EXT_PAYLOAD_W-1:0];

	shadow_reg_combi
	#(
		.D_W		(D_W	),
		.A_W		(A_W	)
	)
	bp_U
	(
		.clk		(clk		), 
		.rst		(rst		), 
		.i_v		(bp_i_v_u[i]	),
		.i_d		(bp_i_d_u[i]	), 
	 	.i_b		(bp_i_b_u[i]	),
	 	.o_v		(bp_o_v_u[i]	),
		.o_d		(bp_o_d_u[i]	),	 
		.o_b		(bp_o_b_u[i]	) // unregistered from DOR logic
	);

    always@(posedge clk)
    begin
        if (previous_u[i]!=m_axis_u_wdata[i])
        begin
            $display("Time%0d: switching",now-1);
            previous_u[i] <= m_axis_u_wdata[i];
        end
    end

end endgenerate

endmodule

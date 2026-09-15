`include "commands.h"

module bft4 #(
	parameter WRAP		= 1,
	parameter N		    = 4,
parameter D_W=96,
	parameter A_W		= $clog2(N)+1,
	parameter LEVELS	= $clog2(N)/2, // Log4 of N
	parameter PAYLOAD_W = A_W+D_W
) (
	input  wire clk,
	input  wire rst,
	input  wire ce,
	
	input	wire	[((A_W+D_W+1)*N)-1:0]	peo_p,
	input	wire	[N-1:0]			peo_v_p,
	input	wire	[N-1:0]			peo_l_p,
	output	reg	    [N-1:0]			peo_r_p,

	output	reg	    [((A_W+D_W+1)*N)-1:0]	pei_p,
	output	reg	    [N-1:0]			pei_v_p,
	output	reg	    [N-1:0]			pei_l_p,
	input	wire	[N-1:0]			pei_r_p
);

wire	[A_W+D_W-1:0]	grid_up		[LEVELS-1:0][N-1:0];	
wire			grid_up_v	[LEVELS-1:0][N-1:0];	
wire 			grid_up_r	[LEVELS-1:0][N-1:0];	
wire 			grid_up_l	[LEVELS-1:0][N-1:0];	

wire 	[A_W+D_W-1:0] 	grid_dn 	[LEVELS-1:0][N-1:0];	
wire 		 	grid_dn_v 	[LEVELS-1:0][N-1:0];	
wire 	 		grid_dn_r 	[LEVELS-1:0][N-1:0];	
wire 	 		grid_dn_l 	[LEVELS-1:0][N-1:0];	

reg 	[A_W+D_W-1:0] 	peo 		[N-1:0];	
reg 	[N-1:0]	 	peo_v 		;	
wire 	[N-1:0]		peo_r 		;	
reg 	[N-1:0]		peo_l 		;	

wire 	[A_W+D_W-1:0] 	pei 		[N-1:0];	
wire 	[N-1:0]	 	pei_v 		;	
reg 	[N-1:0]	 	pei_r 		;	
wire 	[N-1:0]	 	pei_l 		;	

localparam integer TYPE_LEVELS=11;

	// tree 
`ifdef TREE
	localparam TYPE = {32'd0,32'd0,32'd0,32'd0,32'd0,32'd0,32'd0,32'd0,32'd0,32'd0,32'd0};
`endif
	// xbar 
`ifdef XBAR
	localparam TYPE = {32'd2,32'd2,32'd2,32'd2,32'd2,32'd2,32'd2,32'd2,32'd2,32'd2,32'd2};
`endif
	// mesh0 0.5 
`ifdef MESH0
	localparam TYPE = {32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,32'd1};
`endif
	// mesh0 0.67 
`ifdef MESH1
	localparam TYPE = {32'd2,32'd1,32'd1,32'd2,32'd1,32'd1,32'd2,32'd1,32'd1,32'd2,32'd1};
`endif

genvar m, n, l, m1, i;
integer r;

genvar x;
generate for (x = 0; x < N; x = x + 1) begin: routeout
	always @(posedge clk) 
	begin
		peo[x]	<= peo_p[(x+1)*(A_W+D_W+1)-1:x*(A_W+D_W+1)];
		pei_p[(x+1)*(A_W+D_W+1)-1:x*(A_W+D_W+1)]	<= pei[x]; 
	end
end endgenerate

always@(posedge clk)
begin
	peo_v	<= peo_v_p;
	peo_l	<= peo_l_p;
	peo_r_p	<= peo_r;

	pei_v_p	<= pei_v;
	pei_l_p	<= pei_l;
	pei_r	<= pei_r_p;
end


generate if(N>4) begin: n2
for (l = 1; l < LEVELS; l = l + 1) begin : ls

	localparam GROUP_SIZE = 1 << (2*l);

	for (m = 0; m < (N/4)/GROUP_SIZE; m = m + 1) begin : ms
		for (n = 0; n < GROUP_SIZE; n = n + 1) begin : ns

			localparam WIRE_BASE = m * 4 * GROUP_SIZE + n;

            wire [A_W+D_W-1:0] s_axis_d_wdata	[3:0];	
            wire [3:0] s_axis_d_wvalid;	
            wire [3:0] s_axis_d_wready;	
            wire [3:0] s_axis_d_wlast;	

            wire [A_W+D_W-1:0] s_axis_u_wdata	[3:0];	
            wire [3:0] s_axis_u_wvalid;	
            wire [3:0] s_axis_u_wready;	
            wire [3:0] s_axis_u_wlast;	

            wire [A_W+D_W-1:0] m_axis_d_wdata	[3:0];	
            wire [3:0] m_axis_d_wvalid;	
            wire [3:0] m_axis_d_wready;	
            wire [3:0] m_axis_d_wlast;	

            wire [A_W+D_W-1:0] m_axis_u_wdata	[3:0];	
            wire [3:0] m_axis_u_wvalid;	
            wire [3:0] m_axis_u_wready;	
            wire [3:0] m_axis_u_wlast;	

            for (i = 0; i < 4; i = i + 1) begin: wiring_level

                assign s_axis_d_wdata[i] = grid_up[l-1][WIRE_BASE + i * GROUP_SIZE];
                assign s_axis_d_wvalid[i] = grid_up_v[l-1][WIRE_BASE + i * GROUP_SIZE];
                assign s_axis_d_wlast[i] = grid_up_l[l-1][WIRE_BASE + i * GROUP_SIZE];
                assign grid_up_r[l-1][WIRE_BASE + i * GROUP_SIZE] = s_axis_d_wready[i];

                assign s_axis_u_wdata[i] = grid_dn[l][WIRE_BASE + i * GROUP_SIZE];
                assign s_axis_u_wvalid[i] = (l == (LEVELS-1)) ? 0 : grid_dn_v[l][WIRE_BASE + i * GROUP_SIZE];
                assign s_axis_u_wlast[i] = grid_dn_l[l][WIRE_BASE + i * GROUP_SIZE];
                assign grid_dn_r[l][WIRE_BASE + i * GROUP_SIZE] = s_axis_u_wready[i];

                assign grid_dn[l-1][WIRE_BASE + i * GROUP_SIZE] = m_axis_d_wdata[i];
		assign grid_dn_v[l-1][WIRE_BASE + i * GROUP_SIZE] = m_axis_d_wvalid[i];
		assign grid_dn_l[l-1][WIRE_BASE + i * GROUP_SIZE] = m_axis_d_wlast[i];
		assign m_axis_d_wready[i] = grid_dn_r[l-1][WIRE_BASE +  i * GROUP_SIZE];

                assign grid_up[l][WIRE_BASE + i * GROUP_SIZE] = m_axis_u_wdata[i];
                assign grid_up_v[l][WIRE_BASE + i * GROUP_SIZE] = m_axis_u_wvalid[i];
                assign grid_up_l[l][WIRE_BASE + i * GROUP_SIZE] = m_axis_u_wlast[i];
                assign m_axis_u_wready[i] = grid_up_r[l][WIRE_BASE + i * GROUP_SIZE];
            end

			if(((TYPE >> (32*(TYPE_LEVELS-1-l))) & {32{1'b1}})==2) begin: d4u4_level
				d4u4_switch_top
				#
				(
					.N(N),
					.WRAP(WRAP),
					.A_W(A_W),
					.D_W(D_W),
					.posl(l),
					.posx(m*GROUP_SIZE+n)
				) sb
				(
					.clk(clk),		// clock
					.rst(rst),		// reset
					.ce(ce),		// clock enable
					
					.s_axis_d_wdata(s_axis_d_wdata),
					.s_axis_d_wready(s_axis_d_wready),
					.s_axis_d_wvalid(s_axis_d_wvalid),
					.s_axis_d_wlast(s_axis_d_wlast),
					
					.s_axis_u_wdata(s_axis_u_wdata),
					.s_axis_u_wready(s_axis_u_wready),
					.s_axis_u_wvalid(s_axis_u_wvalid),
					.s_axis_u_wlast(s_axis_u_wlast),

					.m_axis_d_wdata(m_axis_d_wdata)	,
					.m_axis_d_wready(m_axis_d_wready)	,
					.m_axis_d_wvalid(m_axis_d_wvalid)	,
					.m_axis_d_wlast(m_axis_d_wlast)	,	

					.m_axis_u_wdata(m_axis_u_wdata)	,
					.m_axis_u_wready(m_axis_u_wready) ,
					.m_axis_u_wvalid(m_axis_u_wvalid) ,
					.m_axis_u_wlast(m_axis_u_wlast)
				);
				
				end
			if(((TYPE >> (32*(TYPE_LEVELS-1-l))) & {32{1'b1}})==1) begin: d4u2_level
				d4u2_switch_top
					#
					(
						.N(N),
						.WRAP(WRAP),
						.A_W(A_W),
						.D_W(D_W),
						.posl(l),
						.posx(m*GROUP_SIZE+n)
					) sb
					(
						.clk(clk),		// clock
						.rst(rst),		// reset
						.ce(ce),		// clock enable
					
						.s_axis_d_wdata(s_axis_d_wdata),
						.s_axis_d_wready(s_axis_d_wready),
						.s_axis_d_wvalid(s_axis_d_wvalid),
						.s_axis_d_wlast(s_axis_d_wlast),
					
						.s_axis_u_wdata(s_axis_u_wdata[1:0]),
						.s_axis_u_wready(s_axis_u_wready[1:0]),
						.s_axis_u_wvalid(s_axis_u_wvalid[1:0]),
						.s_axis_u_wlast(s_axis_u_wlast[1:0]),

						.m_axis_d_wdata(m_axis_d_wdata)	,
						.m_axis_d_wready(m_axis_d_wready)	,
						.m_axis_d_wvalid(m_axis_d_wvalid)	,
						.m_axis_d_wlast(m_axis_d_wlast)	,	

						.m_axis_u_wdata(m_axis_u_wdata[1:0])	,
						.m_axis_u_wready(m_axis_u_wready[1:0]) ,
						.m_axis_u_wvalid(m_axis_u_wvalid[1:0]) ,
						.m_axis_u_wlast(m_axis_u_wlast[1:0])
					);
				
				end
			if(((TYPE >> (32*(TYPE_LEVELS-1-l))) & {32{1'b1}})==0) begin: d4u1_level

				d4u1_switch_top
					#
					(
						.N(N),
						.WRAP(WRAP),
						.A_W(A_W),
						.D_W(D_W),
						.posl(l),
						.posx(m*GROUP_SIZE+n)
					) sb
					(
						.clk(clk),		// clock
						.rst(rst),		// reset
						.ce(ce),		// clock enable
					
						.s_axis_d_wdata(s_axis_d_wdata),
						.s_axis_d_wready(s_axis_d_wready),
						.s_axis_d_wvalid(s_axis_d_wvalid),
						.s_axis_d_wlast(s_axis_d_wlast),
					
						.s_axis_u_wdata(s_axis_u_wdata[0:0]),
						.s_axis_u_wready(s_axis_u_wready[0:0]),
						.s_axis_u_wvalid(s_axis_u_wvalid[0:0]),
						.s_axis_u_wlast(s_axis_u_wlast[0:0]),

						.m_axis_d_wdata(m_axis_d_wdata)	,
						.m_axis_d_wready(m_axis_d_wready)	,
						.m_axis_d_wvalid(m_axis_d_wvalid)	,
						.m_axis_d_wlast(m_axis_d_wlast)	,	

						.m_axis_u_wdata(m_axis_u_wdata[0:0])	,
						.m_axis_u_wready(m_axis_u_wready[0:0]) ,
						.m_axis_u_wvalid(m_axis_u_wvalid[0:0]) ,
						.m_axis_u_wlast(m_axis_u_wlast[0:0])
					);
				
				end
		end
	end
end
end endgenerate

generate for (m = 0; m < N/4; m = m + 1) begin : xs

	localparam PE_POS_BASE = 4*m;

    wire [A_W+D_W-1:0] s_axis_d_wdata	[3:0];	
    wire [3:0] s_axis_d_wvalid;	
    wire [3:0] s_axis_d_wready;	
    wire [3:0] s_axis_d_wlast;	

    wire [A_W+D_W-1:0] s_axis_u_wdata	[3:0];	
    wire [3:0] s_axis_u_wvalid;	
    wire [3:0] s_axis_u_wready;	
    wire [3:0] s_axis_u_wlast;	

    wire [A_W+D_W-1:0] m_axis_d_wdata	[3:0];	
    wire [3:0] m_axis_d_wvalid;	
    wire [3:0] m_axis_d_wready;	
    wire [3:0] m_axis_d_wlast;	

    wire [A_W+D_W-1:0] m_axis_u_wdata	[3:0];	
    wire [3:0] m_axis_u_wvalid;	
    wire [3:0] m_axis_u_wready;	
    wire [3:0] m_axis_u_wlast;	

    for (i = 0; i < 4; i = i + 1) begin : wiring_level0

        assign s_axis_d_wdata[i] = peo[PE_POS_BASE+i];
        assign s_axis_d_wvalid[i] = peo_v[PE_POS_BASE+i];
        assign s_axis_d_wlast[i] = peo_l[PE_POS_BASE+i];
        assign peo_r[PE_POS_BASE+i] = s_axis_d_wready[i];

        assign s_axis_u_wdata[i] = grid_dn[0][PE_POS_BASE+i];
        assign s_axis_u_wvalid[i] = (0 == (LEVELS-1)) ? 0 : grid_dn_v[0][PE_POS_BASE+i];
        assign s_axis_u_wlast[i] = grid_dn_l[0][PE_POS_BASE+i];
        assign grid_dn_r[0][PE_POS_BASE+i] = s_axis_u_wready[i];

        assign pei[PE_POS_BASE+i] = m_axis_d_wdata[i];
	assign pei_v[PE_POS_BASE+i] = m_axis_d_wvalid[i];
        assign pei_l[PE_POS_BASE+i] = m_axis_d_wlast[i];
	assign m_axis_d_wready[i] = pei_r[PE_POS_BASE+i];

        assign grid_up[0][PE_POS_BASE+i] = m_axis_u_wdata[i];
        assign grid_up_v[0][PE_POS_BASE+i] = m_axis_u_wvalid[i];
        assign grid_up_l[0][PE_POS_BASE+i] = m_axis_u_wlast[i];
        assign m_axis_u_wready[i] = grid_up_r[0][PE_POS_BASE+i];
    end

	if(((TYPE >> (32*(TYPE_LEVELS-1))) & {32{1'b1}})==2) begin: d4u4_level0

	d4u4_switch_top
				#
				(
					.N(N),
					.WRAP(WRAP),
					.A_W(A_W),
					.D_W(D_W),
					.posl(0),
					.posx(m)
				) sb
				(
					.clk(clk),		// clock
					.rst(rst),		// reset
					.ce(ce),		// clock enable
					
					.s_axis_d_wdata(s_axis_d_wdata),
					.s_axis_d_wready(s_axis_d_wready),
					.s_axis_d_wvalid(s_axis_d_wvalid),
					.s_axis_d_wlast(s_axis_d_wlast),
					
					.s_axis_u_wdata(s_axis_u_wdata),
					.s_axis_u_wready(s_axis_u_wready),
					.s_axis_u_wvalid(s_axis_u_wvalid),
					.s_axis_u_wlast(s_axis_u_wlast),

					.m_axis_d_wdata(m_axis_d_wdata)	,
					.m_axis_d_wready(m_axis_d_wready)	,
					.m_axis_d_wvalid(m_axis_d_wvalid)	,
					.m_axis_d_wlast(m_axis_d_wlast)	,	

					.m_axis_u_wdata(m_axis_u_wdata)	,
					.m_axis_u_wready(m_axis_u_wready) ,
					.m_axis_u_wvalid(m_axis_u_wvalid) ,
					.m_axis_u_wlast(m_axis_u_wlast)
				);
		
	end

	if(((TYPE >> (32*(TYPE_LEVELS-1))) & {32{1'b1}})==1) begin: d4u2_level0

		d4u2_switch_top
				#
				(
					.N(N),
					.WRAP(WRAP),
					.A_W(A_W),
					.D_W(D_W),
					.posl(0),
					.posx(m)
				) sb
				(
					.clk(clk),		// clock
					.rst(rst),		// reset
					.ce(ce),		// clock enable
					
					.s_axis_d_wdata(s_axis_d_wdata),
					.s_axis_d_wready(s_axis_d_wready),
					.s_axis_d_wvalid(s_axis_d_wvalid),
					.s_axis_d_wlast(s_axis_d_wlast),
					
					.s_axis_u_wdata(s_axis_u_wdata[1:0]),
					.s_axis_u_wready(s_axis_u_wready[1:0]),
					.s_axis_u_wvalid(s_axis_u_wvalid[1:0]),
					.s_axis_u_wlast(s_axis_u_wlast[1:0]),

					.m_axis_d_wdata(m_axis_d_wdata)	,
					.m_axis_d_wready(m_axis_d_wready)	,
					.m_axis_d_wvalid(m_axis_d_wvalid)	,
					.m_axis_d_wlast(m_axis_d_wlast)	,	

					.m_axis_u_wdata(m_axis_u_wdata[1:0])	,
					.m_axis_u_wready(m_axis_u_wready[1:0]) ,
					.m_axis_u_wvalid(m_axis_u_wvalid[1:0]) ,
					.m_axis_u_wlast(m_axis_u_wlast[1:0])
				);
		
	end

	if(((TYPE >> (32*(TYPE_LEVELS-1))) & {32{1'b1}})==0) begin: d4u1_level0

	d4u1_switch_top
				#
				(
					.N(N),
					.WRAP(WRAP),
					.A_W(A_W),
					.D_W(D_W),
					.posl(0),
					.posx(m)
				) sb
				(
					.clk(clk),		// clock
					.rst(rst),		// reset
					.ce(ce),		// clock enable
					
					.s_axis_d_wdata(s_axis_d_wdata),
					.s_axis_d_wready(s_axis_d_wready),
					.s_axis_d_wvalid(s_axis_d_wvalid),
					.s_axis_d_wlast(s_axis_d_wlast),
					
					.s_axis_u_wdata(s_axis_u_wdata[0:0]),
					.s_axis_u_wready(s_axis_u_wready[0:0]),
					.s_axis_u_wvalid(s_axis_u_wvalid[0:0]),
					.s_axis_u_wlast(s_axis_u_wlast[0:0]),

					.m_axis_d_wdata(m_axis_d_wdata)	,
					.m_axis_d_wready(m_axis_d_wready)	,
					.m_axis_d_wvalid(m_axis_d_wvalid)	,
					.m_axis_d_wlast(m_axis_d_wlast)	,	

					.m_axis_u_wdata(m_axis_u_wdata[0:0])	,
					.m_axis_u_wready(m_axis_u_wready[0:0]) ,
					.m_axis_u_wvalid(m_axis_u_wvalid[0:0]) ,
					.m_axis_u_wlast(m_axis_u_wlast[0:0])
				);
		
	end

end endgenerate

endmodule

`default_nettype none

`include "commands.h"

module bft4 #(
	parameter WRAP		= 1,
	parameter PAT		= 0,
	parameter N		    = 4,
	parameter D_W		= 32,
	parameter A_W		= $clog2(N)+1,
	parameter LEVELS	= $clog2(N)/2, // Log4 of N
	parameter LIMIT		= 8192,
	parameter RATE		= 100,
	parameter SIGMA		= 4,
	parameter PAYLOAD_W = A_W+D_W
) (
	input  wire clk,
	input  wire rst,
	input  wire ce,
	input  wire `Cmd cmd,
	input  wire [PAYLOAD_W:0] in,
	output wire [(PAYLOAD_W+1)*N-1:0] out,
	output wire done_all
);

reg 	[A_W+D_W:0] 	in_r;
reg 	[A_W+D_W:0] 	loopback_r 	[N-1:0];

wire	[A_W+D_W:0]	grid_up		[LEVELS-1:0][N-1:0];	
wire			grid_up_v	[LEVELS-1:0][N-1:0];	
wire 			grid_up_r	[LEVELS-1:0][N-1:0];	
wire 			grid_up_l	[LEVELS-1:0][N-1:0];	

wire 	[A_W+D_W:0] 	grid_dn 	[LEVELS-1:0][N-1:0];	
wire 		 	grid_dn_v 	[LEVELS-1:0][N-1:0];	
wire 	 		grid_dn_r 	[LEVELS-1:0][N-1:0];	
wire 	 		grid_dn_l 	[LEVELS-1:0][N-1:0];	

wire 	[A_W+D_W:0] 	peo 		[N-1:0];	
wire 		 	peo_v 		[N-1:0];	
wire 	 		peo_r 		[N-1:0];	
wire 	 		peo_l 		[N-1:0];	

wire 	[A_W+D_W:0] 	pei 		[N-1:0];	
wire 		 	pei_v 		[N-1:0];	
wire 		 	pei_r 		[N-1:0];	
wire 		 	pei_l 		[N-1:0];	

wire [N-1:0] done_pe;
wire [N/4-1:0] done_sw [LEVELS-1:0];
wire [LEVELS-1:0] done_sw_lvl; 

integer now_r=0;

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

genvar m, n, l, k, m1, q, hr, i;
integer r;
generate if (WRAP==1) begin: localwrap
	for (q = 0; q < N; q = q + 1) begin : as1
		assign grid_dn[LEVELS-1][q] = in_r;
	end
	always @(posedge clk) begin
		in_r = in;
	end			
end endgenerate

reg [(A_W+D_W+2)*N-1:0] out_r;
genvar x;
generate for (x = 0; x < N; x = x + 1) begin: routeout
	always @(posedge clk) begin
		out_r[(x+1)*(A_W+D_W+2)-1:x*(A_W+D_W+2)] <= peo[x];
	end
end endgenerate
assign out = out_r;	

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
					.m_axis_u_wlast(m_axis_u_wlast)	,	

					.done(done_sw[l][m*GROUP_SIZE+n])		// done
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
						.m_axis_u_wlast(m_axis_u_wlast[1:0])	,	

						.done(done_sw[l][m*GROUP_SIZE+n])		// done
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
						.m_axis_u_wlast(m_axis_u_wlast[0:0])	,	

						.done(done_sw[l][m*GROUP_SIZE+n])		// done
					);
				
				end
		end
	end
end
end endgenerate

generate for (m = 0; m < N/4; m = m + 1) begin : xs

	localparam PE_POS_BASE = 4*m;

	for (k = 0; k < 4; k = k + 1)
	begin
		client_top #(.D_W(D_W), .A_W(A_W),.N(N), .posx(PE_POS_BASE + k),
		             .LIMIT(LIMIT), .SIGMA(SIGMA), .RATE(RATE), .WRAP(WRAP), .PAT(PAT))
		cli(.clk(clk), .rst(rst), .ce(ce), .cmd(cmd),
			.s_axis_c_wdata(pei[PE_POS_BASE + k]),
			.s_axis_c_wvalid(pei_v[PE_POS_BASE + k]),
			.s_axis_c_wready(pei_r[PE_POS_BASE + k]),
			.s_axis_c_wlast(pei_l[PE_POS_BASE + k]),
			.m_axis_c_wdata(peo[PE_POS_BASE + k]),
			.m_axis_c_wvalid(peo_v[PE_POS_BASE + k]),
			.m_axis_c_wready(peo_r[PE_POS_BASE + k]),
			.m_axis_c_wlast(peo_l[PE_POS_BASE + k]),
			.done(done_pe[PE_POS_BASE + k]));
	end

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
					.m_axis_u_wlast(m_axis_u_wlast)	,	

					.done(done_sw[0][m])		// done
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
					.m_axis_u_wlast(m_axis_u_wlast[1:0])	,	

					.done(done_sw[0][m])		// done
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
					.m_axis_u_wlast(m_axis_u_wlast[0:0])	,	

					.done(done_sw[0][m])		// done
				);
		
	end

end endgenerate

generate for (l = 0; l < LEVELS; l = l + 1) begin : reduce
	assign done_sw_lvl[l] = &done_sw[l];
end endgenerate

assign done_all = &done_pe & &done_sw_lvl & (now_r>16*LIMIT+N); // verilog supports reductions??!

always@(posedge clk) begin
	now_r     <= now_r + 1;
//		$display("done_pe=%b, done_sw_lvl=%b now=%0d",done_pe,done_sw_lvl,now>16*LIMIT+N);
end


endmodule

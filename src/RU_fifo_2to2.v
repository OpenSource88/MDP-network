module RU_fifo_2to2
#(
	parameter RU_FIFO_DEPTH	= 16,
			  RU_FIFO_WIDTH = 32
)
(
    input   	clk         
    ,input   	rst_n       

	,input [2-1:0] in_valid
	,input [2*RU_FIFO_WIDTH-1:0]	in_data
	,input [2*1-1:0] in_addr
	,output	[2-1:0] in_ready  
	
	,output [2-1:0] out_valid
	,output [2*RU_FIFO_WIDTH-1:0]	out_data
	,input	[2-1:0] out_ready
 
    );

genvar gv_i	;
genvar gv_j	;

localparam PORT_NUM = 2 ;
localparam PORT_NUM_LOG = $clog2(PORT_NUM)   ;   

wire [PORT_NUM-1 : 0][RU_FIFO_WIDTH-1 : 0] datain_list ;     

wire [PORT_NUM-1 : 0][PORT_NUM-1 : 0] wr_ens    ;
wire [PORT_NUM-1 : 0] rd_en    ;

wire [PORT_NUM-1 : 0] empty    ;
wire [PORT_NUM-1 : 0] full     ;

wire in_not_ready   ; 
    assign in_not_ready = (|full)   ;

generate
	for(gv_i=0; gv_i<PORT_NUM; gv_i=gv_i+1) 
	begin: GEN_fifo_in_signal
        	assign datain_list[gv_i] = in_data[(gv_i+1)*RU_FIFO_WIDTH-1 : gv_i*RU_FIFO_WIDTH];

		for(gv_j=0; gv_j<PORT_NUM; gv_j=gv_j+1) 
		begin:GEN_wr_ens
			assign wr_ens[gv_i][gv_j] = in_not_ready ? 1'b0 : 
                    ( in_valid[gv_j] &&  (in_addr[(gv_j+1)*PORT_NUM_LOG-1:gv_j*PORT_NUM_LOG] == gv_i) )	;	
		end
		assign rd_en[gv_i]  = empty[gv_i] ? 1'b0 : out_ready[gv_i]	;

		assign in_ready[gv_i] = ~in_not_ready	;
		assign out_valid[gv_i] = empty[gv_i] ? 1'b0 : 1'b1	;
	end
endgenerate


generate
	for(gv_i=0; gv_i<PORT_NUM; gv_i=gv_i+1)
	begin: GEN_fifo
		fifo_sync_2w_1r
		#(
    		.WIDTH(RU_FIFO_WIDTH)
			,.DEPTH(RU_FIFO_DEPTH)
		) u_fifo_sync_2w_1r(
			.clk		(clk)
			,.rst_n		(rst_n)
            ,.datain_list (datain_list)
			,.wr_ens	(wr_ens[gv_i])
			,.rd_en		(rd_en[gv_i])

			,.dataout	(out_data[(gv_i+1)*RU_FIFO_WIDTH-1:gv_i*RU_FIFO_WIDTH])
			,.empty		(empty[gv_i])
			,.full		(full[gv_i])
		);

	end
endgenerate




endmodule
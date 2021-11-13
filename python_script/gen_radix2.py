
from Param_define import *

print("module ",MODULE_NAME,"(", sep="")
print("\
    input   	clk\n\
    ,input   	rst_n\n\
    ,input	[%d-1:0] input_valid\n\
    ,input	[%d-1:0][%d-1:0] input_data\n\
    ,input  [%d-1:0][%d-1:0] input_addr\n\
    ,output	[%d-1:0] input_side_ready\n\
    ,output [%d-1:0] output_valid\n\
    ,output [%d-1:0][%d-1:0] output_data\n\
    ,input  [%d-1:0] output_side_ready\n\
    ,output     empty\n\
);" %(CHANNEL_NUM, \
      CHANNEL_NUM, DATA_WIDTH, \
      CHANNEL_NUM, ADDR_BIT, \
      CHANNEL_NUM, \
      CHANNEL_NUM, \
      CHANNEL_NUM, DATA_WIDTH, \
      CHANNEL_NUM  ))


#localparam
print("\
localparam integer WIDTH = %d\n\
                  ,DEPTH = %d\n\
                  ,CHANNEL_NUM = %d\n\
                  ,STAGE_NUM = %d\n\
                  ,PORT_NUM = 2\n\
                  ,PORT_NUM_LOG = 1;" %(\
                       DATA_WIDTH+ADDR_BIT,\
                       FIFO_DEPTH,\
                       CHANNEL_NUM,\
                       ADDR_BIT))

#empty signal of MDP-network
print("\
integer i   ;\n\
reg [CHANNEL_NUM-1:0] inside_cnt ;\n\
reg [CHANNEL_NUM-1:0] in_cnt ;\n\
reg [CHANNEL_NUM-1:0] out_cnt ;\n\
\n\
    always@(*) begin    \n\
        in_cnt = 'd0;\n\
        for(i=0; i<CHANNEL_NUM; i=i+1)\n\
        begin:GEN_in_cnt\n\
            in_cnt = in_cnt + (input_valid[i] & input_side_ready[i])   ;\n\
        end\n\
    end\n\
\n\
    always@(*) begin\n\
        out_cnt = 'd0;\n\
        for(i=0; i<CHANNEL_NUM; i=i+1) \n\
        begin:GEN_out_cnt\n\
            out_cnt = out_cnt + (output_valid[i] & output_side_ready[i])   ;\n\
        end\n\
    end\n\
\n\
    always @(posedge clk or negedge rst_n) begin\n\
        if(!rst_n)\n\
            inside_cnt <= 0;\n\
        else\n\
            inside_cnt <= inside_cnt + in_cnt - out_cnt  ; \n\
    end\n\
\n\
    assign empty = (inside_cnt == 'd0)  ;\n\
\n\
")

print("\n\
genvar	gv_i	;\n\
genvar  gv_j    ;\n\
genvar  gv_k    ;\n\
genvar  gv_t    ;\n\
\n\
wire    [STAGE_NUM:0][CHANNEL_NUM-1:0] out_valid;\n\
wire    [STAGE_NUM:0][CHANNEL_NUM-1:0][WIDTH-1:0] out_data;    \n\
wire    [STAGE_NUM:0][CHANNEL_NUM-1:0] out_ready;\n\
\n\
reg     [STAGE_NUM-1:0][CHANNEL_NUM-1:0] reg_out_valid;\n\
reg     [STAGE_NUM-1:0][CHANNEL_NUM-1:0][WIDTH-1:0] reg_out_data;    \n\
\n\
\n\
assign out_valid[0] = input_valid;\n\
assign input_side_ready = out_ready[0];\n\
\n\
assign output_valid = out_valid[STAGE_NUM]  ;\n\
assign out_ready[STAGE_NUM] = output_side_ready;\n\
\n\
generate\n\
    for(gv_i=0; gv_i<CHANNEL_NUM; gv_i=gv_i+1)\n\
    begin: GEN_input_output_data\n\
        assign out_data[0][gv_i] = {input_data[gv_i], input_addr[gv_i]};\n\
        assign output_data[gv_i] = out_data[STAGE_NUM][gv_i][WIDTH-1 : STAGE_NUM];\n\
    end\n\
endgenerate\n\
")


print("\
generate\n\
    for(gv_i=0; gv_i<STAGE_NUM; gv_i=gv_i+1)        \n\
    begin: GEN_layer\n\
        localparam group = (PORT_NUM**gv_i) ;\n\
        localparam base_plus = CHANNEL_NUM/group ;\n\
        localparam step = base_plus / PORT_NUM;\n\
        for(gv_j=0; gv_j<group; gv_j=gv_j+1)\n\
        begin:GEN_group\n\
            for(gv_k=0; gv_k<step; gv_k=gv_k+1)\n\
            begin:GEN_pair\n\
                localparam pair_num0 = base_plus * gv_j + gv_k ;\n\
                localparam pair_num1 = pair_num0 + step;\n\
                \n\
                RU_fifo_2to2\n\
        		#(\n\
        			.RU_FIFO_DEPTH (DEPTH)\n\
        			,.RU_FIFO_WIDTH (WIDTH)\n\
        		)	u_fifo(\n\
        			.clk		(clk)         \n\
        			,.rst_n		(rst_n) \n\
        \n\
                    ,.in_valid  ({reg_out_valid[gv_i][pair_num1],\n\
                                  reg_out_valid[gv_i][pair_num0]})\n\
        			,.in_data	({reg_out_data[gv_i][pair_num1],\n\
                                  reg_out_data[gv_i][pair_num0]})\n\
        			,.in_addr	({reg_out_data[gv_i][pair_num1][STAGE_NUM-(gv_i*PORT_NUM_LOG)-1 : STAGE_NUM-(gv_i+1)*PORT_NUM_LOG], \n\
                                  reg_out_data[gv_i][pair_num0][STAGE_NUM-(gv_i*PORT_NUM_LOG)-1 : STAGE_NUM-(gv_i+1)*PORT_NUM_LOG]})\n\
                    ,.in_ready  ({out_ready[gv_i][pair_num1],\n\
                                  out_ready[gv_i][pair_num0]})\n\
        \n\
        			,.out_valid	({out_valid[gv_i+1][pair_num1],\n\
                                  out_valid[gv_i+1][pair_num0]})\n\
        			,.out_data	({out_data[gv_i+1][pair_num1], \n\
                                  out_data[gv_i+1][pair_num0]})\n\
        			,.out_ready	({out_ready[gv_i+1][pair_num1], \n\
                                  out_ready[gv_i+1][pair_num0]})\n\
        			);\n\
                \n\
            end //gv_k\n\
        end //gv_j\n\
       \n\
        \n\
        for(gv_t=0; gv_t<CHANNEL_NUM; gv_t=gv_t+1) \n\
        begin:GEN_reg_out_valid_data\n\
            always @(posedge clk or negedge rst_n) begin\n\
                if(!rst_n)\n\
                    reg_out_valid[gv_i][gv_t] <= 'd0;    \n\
                else if(~out_ready[gv_i][gv_t])\n\
                    reg_out_valid[gv_i][gv_t] <= reg_out_valid[gv_i][gv_t];    \n\
                else\n\
                    reg_out_valid[gv_i][gv_t] <= out_valid[gv_i][gv_t];        \n\
            end\n\
            \n\
            always @(posedge clk or negedge rst_n) begin\n\
                if(!rst_n)\n\
                    reg_out_data[gv_i][gv_t] <= 'd0;    \n\
                else if(~out_ready[gv_i][gv_t])\n\
                    reg_out_data[gv_i][gv_t] <= reg_out_data[gv_i][gv_t];    \n\
                else\n\
                    reg_out_data[gv_i][gv_t] <= out_data[gv_i][gv_t];            \n\
            end\n\
        end\n\
    end\n\
endgenerate\n\
\n\
\n\
endmodule\n\
")


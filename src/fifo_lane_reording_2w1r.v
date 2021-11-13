`timescale 1ns / 1ps

module fifo_lane_reording_2w1r
#(
    parameter WIDTH = 32
)
(

  input  [WIDTH-1 : 0]    data_in0,
  input  [WIDTH-1 : 0]    data_in1,
  input                   valid_in0,
  input                   valid_in1,

  output [WIDTH-1 : 0]    data_out0,
  output [WIDTH-1 : 0]    data_out1,
  output                  valid_out0,
  output                  valid_out1
);

localparam CHANNEL_NUM = 2;
localparam CHANNEL_NUM_LOG = $clog2(CHANNEL_NUM);


wire [CHANNEL_NUM_LOG-1:0] nxt_arb_id_0;
wire [CHANNEL_NUM_LOG-1:0] nxt_arb_id_1;
wire arb_en = 1'b1;
wire [CHANNEL_NUM-1:0] arb_req = {valid_in1,valid_in0};

wire [CHANNEL_NUM_LOG-1:0] cur_arb_id_0 = {CHANNEL_NUM_LOG{1'b1}}; 

wire [CHANNEL_NUM_LOG:0] valid_num;


arb_comb2 arb_comb_inst_0(
    .cur_arb_id (cur_arb_id_0), 
    .arb_req    (arb_req),
    .arb_en     (arb_en),
    .nxt_arb_id (nxt_arb_id_0)   
);

arb_comb2 arb_comb_inst_1(
    .cur_arb_id (nxt_arb_id_0), 
    .arb_req    (arb_req),
    .arb_en     (arb_en),
    .nxt_arb_id (nxt_arb_id_1)  
);



assign data_out0 =
    {WIDTH{nxt_arb_id_0 == 1'd0}} & data_in0 |
    {WIDTH{nxt_arb_id_0 == 1'd1}} & data_in1 ;

assign data_out1 =
    {WIDTH{nxt_arb_id_1 == 1'd0}} & data_in0 |
    {WIDTH{nxt_arb_id_1 == 1'd1}} & data_in1 ;


assign valid_num = (valid_in0 + valid_in1 + 2'd0) ;
assign valid_out0 = valid_num != 2'd0;
assign valid_out1 = valid_num > 2'd1;
endmodule
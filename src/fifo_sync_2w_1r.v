`timescale 1ns / 1ps

module fifo_sync_2w_1r
#(
    parameter WIDTH = 32,
              DEPTH = 4
) 
(
    input                      clk,
    input                      rst_n,
   
    input  [2-1 : 0][WIDTH-1 : 0] datain_list,

    input  [1 : 0]             wr_ens, 

    input                      rd_en,  
    
    output  [WIDTH-1 : 0]      dataout,
    output                     empty,  
    output                     full    
);

localparam WR_PORT_NUM = 2;

wire [WIDTH-1 : 0]       data_ordered [0 : WR_PORT_NUM-1];
wire [WR_PORT_NUM-1 : 0] wr_en_ordered;

fifo_lane_reording_2w1r #(
    .WIDTH(WIDTH)
) fifo_lane_reording_inst(
    .data_in0   (datain_list[0]),
    .data_in1   (datain_list[1]),
    .valid_in0  (wr_ens[0]),
    .valid_in1  (wr_ens[1]),

    .data_out0  (data_ordered[0]),
    .data_out1  (data_ordered[1]),
    .valid_out0 (wr_en_ordered[0]),
    .valid_out1 (wr_en_ordered[1])
);

fifo_sync_2w_1r_no_ordering #(
    .WIDTH            (WIDTH),
    .DEPTH            (DEPTH)
)fifo_sync_2w_1r_no_ordering_inst(
    .clk         (clk),
    .rst_n       (rst_n),
    .datain0     (data_ordered[0]),
    .datain1     (data_ordered[1]),
    .wr_en0      (wr_en_ordered[0]),
    .wr_en1      (wr_en_ordered[1]),
    .rd_en       (rd_en),
    .dataout     (dataout),
    .empty       (empty),
    .full        (full)
);

endmodule
`timescale 1ns / 1ps

module fifo_sync_2w_1r_no_ordering
#(
    parameter WIDTH = 32,
                     DEPTH = 4
) 
(
    input                      clk,
    input                      rst_n,
    
    input     [WIDTH-1 : 0]    datain0,
    input     [WIDTH-1 : 0]    datain1,

    input                      wr_en0, 
    input                      wr_en1, 

    input                      rd_en,  
    
    output     [WIDTH-1 : 0]   dataout,
    output                     empty,  
    output                     full    
);

localparam WR_PORT_NUM      = 2;
localparam WR_PORT_NUM_LOG  = $clog2(WR_PORT_NUM);
localparam DEPTH_LOG        = $clog2(DEPTH);

localparam DEPTH_LOG_W_0    = {(DEPTH_LOG){1'b0}};
localparam DEPTH_LOG_W_1    = {{(DEPTH_LOG-1){1'b0}},1'd1};

localparam CNT_DEPTH_LOG_0    = {(DEPTH_LOG+1){1'b0}};

localparam S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;


wire [WR_PORT_NUM-1 : 0][DEPTH_LOG-1 : 0]      wr_addr ;
wire [WR_PORT_NUM-1 : 0][DEPTH_LOG : 0]        wr_addr_round ;
wire [DEPTH_LOG : 0]        wr_ptr_round;
wire [DEPTH_LOG-1 : 0]      rd_ptr_comb;
wire [DEPTH_LOG-1 : 0]      wr_ptr_comb;
wire [WR_PORT_NUM_LOG : 0]  wr_en_num;
wire                        have_wr_en;
wire                        true_empty;

reg  [DEPTH_LOG-1 : 0]      rd_ptr;
reg  [DEPTH_LOG-1 : 0]      wr_ptr;
reg  [DEPTH_LOG : 0]      cnt;
reg  [DEPTH-1 : 0][WIDTH-1 : 0]          fifo_mem    ; 

wire [DEPTH_LOG : 0]        wr_ptr_sub_deep;
wire [DEPTH_LOG : 0]      cnt_nxt;

assign wr_ptr_sub_deep =  wr_ptr - DEPTH[DEPTH_LOG:0]; 
assign wr_addr_round[1] = wr_ptr_sub_deep + 'd1;
assign wr_ptr_round     = wr_ptr_sub_deep + wr_en_num;

assign wr_addr[0] = wr_ptr;
assign wr_addr[1] = wr_addr_round[1][DEPTH_LOG] ? wr_ptr + 1'd1 : wr_addr_round[1][DEPTH_LOG-1:0];

assign have_wr_en = wr_en0 | wr_en1 ;
assign wr_en_num = wr_en0 + wr_en1 + {(WR_PORT_NUM_LOG+1){1'b0}};

assign wr_ptr_comb = wr_ptr_round[DEPTH_LOG] ? wr_ptr + wr_en_num : wr_ptr_round[DEPTH_LOG-1:0];
assign rd_ptr_comb = rd_ptr == DEPTH[DEPTH_LOG-1:0] - DEPTH_LOG_W_1 ? DEPTH_LOG_W_0 : rd_ptr + 1'b1;

assign cnt_nxt = cnt + wr_en_num;
assign full  = cnt > DEPTH[DEPTH_LOG:0] - WR_PORT_NUM;  
assign empty = cnt_nxt == CNT_DEPTH_LOG_0;

assign true_empty = cnt == CNT_DEPTH_LOG_0;
assign dataout = true_empty ? datain0 : fifo_mem[rd_ptr];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt     <= CNT_DEPTH_LOG_0;
        wr_ptr  <= DEPTH_LOG_W_0;
        rd_ptr  <= DEPTH_LOG_W_0;
        fifo_mem <= 'd0;
    end
    else begin
        case ({rd_en,have_wr_en})
            S0 : begin   // Idle
                cnt <= cnt;
            end
            S1 : begin   // Write FIFO
                if(wr_en0)
                    fifo_mem[wr_addr[0]] <= datain0;
                if(wr_en1)
                    fifo_mem[wr_addr[1]] <= datain1;
                wr_ptr <= wr_ptr_comb;
                cnt <= cnt + wr_en_num;
                rd_ptr <= rd_ptr;
            end 
            S2 : begin   // Read FIFO
                rd_ptr <= rd_ptr_comb;
                wr_ptr <= wr_ptr;
                cnt <= cnt - 1'b1;
            end 
            S3 : begin  // Read & Write FIFO
                if(wr_en0)
                    fifo_mem[wr_addr[0]] <= datain0;
                if(wr_en1)
                    fifo_mem[wr_addr[1]] <= datain1;
                wr_ptr <= wr_ptr_comb;
                rd_ptr <= rd_ptr_comb;
                cnt <= cnt + wr_en_num - 1'b1;
            end 
        endcase
    end
end


endmodule
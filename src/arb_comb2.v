module arb_comb2
(
  input cur_arb_id,
  input [1:0]arb_req,
  input arb_en,
  output reg nxt_arb_id
);

always @(*)
begin
  if(arb_en)
  begin
      case(cur_arb_id)
        1'd0:
        case(1'b1)
                arb_req[1]:nxt_arb_id=1'd1;
                arb_req[0]:nxt_arb_id=1'd0;
                default:nxt_arb_id=1'd0;
        endcase
        1'd1:
        case(1'b1)
                arb_req[0]:nxt_arb_id=1'd0;
                arb_req[1]:nxt_arb_id=1'd1;
                default:nxt_arb_id=1'd1;
        endcase
        default:nxt_arb_id=1'd0;
      endcase
  end
  else
    nxt_arb_id=cur_arb_id;
end

endmodule
`timescale 1ns/1ns

module pixel_mean_ordering#(
    parameter           ROW_NUM = 9'd96,    // number of row
    parameter           COL_NUM = 9'd128,    // number of col
    parameter           DATA_WIDTH  = 16
)(
    input               rst,
    input               video_clk,
	input      [15:0]   pixel_mean,
    input               pixel_mean_val,
    input               rd_req,
    output wire         wr_done,
	output reg [23:0]   rgb_o,
    output wire         rgb_o_val
   );

// address head
parameter   addr_above = 0;
parameter   addr_left  = COL_NUM;
parameter   addr_right = COL_NUM + 1;
parameter   addr_under = COL_NUM + 2*(ROW_NUM-2) - 1;
// count the pixel num
reg [8:0]   cnt;
wire        add_cnt;
wire        end_cnt;
// ping pong 
reg         flag_ping_pong;
wire        flag_ping_pong_change;
// write ping pong
wire        wr_en_ping;
wire        wr_en_pong;
// genarate ordered write address
wire        part_above;
wire        part_left;
wire        part_right;
wire        part_under;
reg [8:0]   wr_addr;
// write done
reg         flag_rd;
wire        flag_rd_l2h;
wire        flag_rd_h2l;
// rising of rd_req
reg         rd_req_d0;
wire        rising_rd_req;
reg         rising_rd_req_d0,rising_rd_req_d1,rising_rd_req_d2;
// read address
reg [8:0]   rd_addr;
wire        add_rd_addr;
wire        end_rd_addr;
// ping pong read
wire        rd_clk_ping;
wire        rd_clk_pong;
wire[15:0]  rd_data_ping;
wire[15:0]  rd_data_pong;
wire[15:0]  rd_data;
reg [15:0]  rd_data_reg;



// count the pixel num
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        cnt <= 'b0;
    end else if (add_cnt) begin
        if(end_cnt)begin
            cnt <= 'b0;
        end else begin
            cnt <= cnt + 1'b1;
        end   
    end
end
assign  add_cnt = pixel_mean_val;
assign  end_cnt = add_cnt && (cnt == (2*COL_NUM + 2*ROW_NUM - 4) - 1);
// flag ping pong
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        flag_ping_pong <= 0;
    end else begin
        if(flag_ping_pong_change) flag_ping_pong <= ~flag_ping_pong;
    end
end
assign  flag_ping_pong_change = end_cnt;
// genarate ordered write address
always@(*)begin
    if(rst)begin
        wr_addr = 'b0;
    end else begin
        if(part_above) wr_addr = 0 + cnt;
        if(part_right) wr_addr = (cnt-128-1)/2 + 128;
        if(part_left ) wr_addr = 443 - (cnt-128)/2;
        if(part_under) wr_addr = 349 - (cnt - 316);
    end
end
assign  part_above = (cnt <= 127);
assign  part_left  = (cnt >= 128) && (cnt <= 315) && (cnt[0] == 0);
assign  part_right = (cnt >= 128) && (cnt <= 315) && (cnt[0] == 1);
assign  part_under = (cnt >= 316) && (cnt <= 443);
// ping pong ram
pixel_ram pixel_mean_ping_ram (
  .wr_clk   (video_clk      ),    // input
  .wr_data  (pixel_mean     ),    // input [15:0]
  .wr_addr  (wr_addr        ),    // input [8:0]
  .wr_en    (wr_en_ping     ),    // input
  .rd_clk   (rd_clk_ping    ),    // input
  .rd_addr  (rd_addr        ),    // input [8:0]
  .rd_data  (rd_data_ping   ),    // output [15:0]
  .rst      (rst            )     // input
);
pixel_ram pixel_mean_pong_ram (
  .wr_clk   (video_clk      ),    // input
  .wr_data  (pixel_mean     ),    // input [15:0]
  .wr_addr  (wr_addr        ),    // input [8:0]
  .wr_en    (wr_en_pong     ),    // input
  .rd_clk   (rd_clk_pong    ),    // input
  .rd_addr  (rd_addr        ),    // input [8:0]
  .rd_data  (rd_data_pong   ),    // output [15:0]
  .rst      (rst            )     // input
);
assign  wr_en_ping = pixel_mean_val && !flag_ping_pong;
assign  wr_en_pong = pixel_mean_val && flag_ping_pong;

// flag_rd
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        flag_rd <= 0;
    end else begin
        if(flag_rd_l2h) flag_rd <= 1;
        if(flag_rd_h2l) flag_rd <= 0;
    end
end
assign  flag_rd_l2h = end_cnt;
assign  flag_rd_h2l = end_rd_addr;
assign  wr_done = flag_rd;
// edge of rd_req
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        rd_req_d0 <= 0;
    end else begin
        rd_req_d0 <= rd_req & flag_rd; 
    end
end
assign  rising_rd_req = rd_req & ~rd_req_d0;
// count rd_addr
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        rd_addr <= 'b0;
    end else if (add_rd_addr) begin
        if(end_rd_addr)begin
            rd_addr <= 'b0;
        end else begin
            rd_addr <= rd_addr + 1'b1;
        end   
    end
end
assign  add_rd_addr = flag_rd && rising_rd_req;
assign  end_rd_addr = add_rd_addr && rd_addr == (2*COL_NUM + 2*ROW_NUM - 4) - 1;
// ping pong read
assign  rd_clk_ping = flag_ping_pong && flag_rd && rising_rd_req;
assign  rd_clk_pong = !flag_ping_pong && flag_rd && rising_rd_req;
assign  rd_data = flag_ping_pong ? rd_data_ping : rd_data_pong;

always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        rd_data_reg <= 0;
    end else if(rising_rd_req)begin
        rd_data_reg <= rd_data;
    end
end

always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        rgb_o <= 0;
    end else begin
        rgb_o <= {3'b0,rd_data_reg[10:7],1'b0,3'b0,rd_data_reg[15:12],1'b0,3'b0,rd_data_reg[4:1],1'b0};
    end
end

always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        rising_rd_req_d0 <= 0;
        rising_rd_req_d1 <= 0;
        rising_rd_req_d2 <= 0;
    end else begin
        rising_rd_req_d0 <= rising_rd_req;
        rising_rd_req_d1 <= rising_rd_req_d0;
        rising_rd_req_d2 <= rising_rd_req_d1;
    end
end
assign rgb_o_val = flag_rd & rising_rd_req_d2;

endmodule
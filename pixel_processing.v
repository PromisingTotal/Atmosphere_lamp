`timescale 1ns/1ns

module pixel_processing#(
    parameter          ROW_NUM = 9'd384,    // number of row
    parameter          COL_NUM = 9'd128,    // number of col
    parameter          DATA_WIDTH  = 16
)(
    input              rst,
    input              video_clk,
	input     [15:0]   rgb565_i,
    input              data_valid,
	output reg[15:0]   pixel_mean,
    output reg         odata_val
   ); 

// col and row cnt 
reg [8:0]   col_cnt;
reg [8:0]   row_cnt;
wire        add_col_cnt = data_valid;
wire        end_col_cnt = add_col_cnt && (col_cnt == COL_NUM-1);
wire        add_row_cnt = end_col_cnt;
wire        end_row_cnt = add_row_cnt && (row_cnt == ROW_NUM-1);
// edge taking
wire        pixel_above = row_cnt < 4;
wire        pixel_under = row_cnt >= ROW_NUM - 4;
wire        pixel_left  = !(pixel_above || pixel_under) && col_cnt == 1-1;
wire        pixel_right = !(pixel_above || pixel_under) && col_cnt == COL_NUM-1;

//----------------------------------------------------------------
//------------------------- above pixel --------------------------
//----------------------------------------------------------------
// above pixel ram
wire[8:0]   wr_addr_above = (col_cnt << 2) + row_cnt;
wire        wr_en_above = data_valid & pixel_above;
wire        wr_clk_above = video_clk;
wire[15:0]  wr_data_above = rgb565_i;
// 4bits read out and mean them (4bits -> 1bits)------------------
// read ram
reg         flag_above_mean;
reg [8:0]   rd_addr_above;
wire        add_rd_addr_above = flag_above_mean;
wire        end_rd_addr_above = add_rd_addr_above && rd_addr_above == 4*COL_NUM-1;
wire        flag_above_mean_l2h = end_col_cnt && (row_cnt == 4-1);
wire        flag_above_mean_h2l = end_rd_addr_above;
wire        rd_clk_above = video_clk & flag_above_mean;
wire[15:0]  rd_data_above;
// save the 4 pixel
reg [15:0]  reg_4bit_above_0,reg_4bit_above_1,reg_4bit_above_2,reg_4bit_above_3;
// alignment
reg [15:0]  reg_4bit_above_0_align,reg_4bit_above_1_align,reg_4bit_above_2_align;
// reg cnt
reg [2:0]   reg_cnt_above;
wire        add_reg_cnt_above = flag_above_mean;
wire        end_reg_cnt_above = add_reg_cnt_above && reg_cnt_above == 4 - 1;
// cal the mean of rgb (4bits rgb -> 1bit rgb)
wire[7:0]   mean_red_above,mean_green_above,mean_blue_above;
wire[15:0]  mean_rgb_above;
//----------------------------------------------------------------
//------------------------- left pixel ---------------------------
//----------------------------------------------------------------
// save the 4 pixel
reg [15:0]  reg_4bit_left_0,reg_4bit_left_1,reg_4bit_left_2,reg_4bit_left_3;
// shift cnt
reg [2:0]   reg_cnt_left;
wire        add_reg_cnt_left = add_col_cnt && pixel_left;
wire        end_reg_cnt_left = add_reg_cnt_left && reg_cnt_left == 4 - 1;
// alignment
reg [15:0]  reg_4bit_left_0_align,reg_4bit_left_1_align,reg_4bit_left_2_align;
// cal the mean of rgb (4bits rgb -> 1bit rgb)
wire[7:0]   mean_red_left,mean_green_left,mean_blue_left;
wire[15:0]  mean_rgb_left;
//----------------------------------------------------------------
//------------------------- right pixel ---------------------------
//----------------------------------------------------------------
// save the 4 pixel
reg [15:0]  reg_4bit_right_0,reg_4bit_right_1,reg_4bit_right_2,reg_4bit_right_3;
// reg cnt
reg [2:0]   reg_cnt_right;
wire        add_reg_cnt_right = add_col_cnt && pixel_right;
wire        end_reg_cnt_right = add_reg_cnt_right && reg_cnt_right == 4 - 1;
// alignment
reg [15:0]  reg_4bit_right_0_align,reg_4bit_right_1_align,reg_4bit_right_2_align;
// cal the mean of rgb (4bits rgb -> 1bit rgb)
wire[7:0]   mean_red_right,mean_green_right,mean_blue_right;
wire[15:0]  mean_rgb_right;
//----------------------------------------------------------------
//------------------------- under pixel --------------------------
//----------------------------------------------------------------
// under pixel ram
wire[8:0]   wr_addr_under = (col_cnt << 2) + row_cnt - (ROW_NUM - 4);
wire        wr_en_under = data_valid & pixel_under;
wire        wr_clk_under = video_clk;
wire[15:0]  wr_data_under = rgb565_i;
// 4bits read out and mean them (4bits -> 1bits)------------------
// read ram
reg         flag_under_mean;
reg [8:0]   rd_addr_under;
wire        add_rd_addr_under = flag_under_mean;
wire        end_rd_addr_under = add_rd_addr_under && rd_addr_under == 4*COL_NUM-1;
wire        flag_under_mean_l2h = end_col_cnt && (row_cnt == ROW_NUM-1);
wire        flag_under_mean_h2l = end_rd_addr_under;
wire        rd_clk_under = video_clk & flag_under_mean;
wire[15:0]  rd_data_under;
// save the 4 pixel
reg [15:0]  reg_4bit_under_0,reg_4bit_under_1,reg_4bit_under_2,reg_4bit_under_3;
// alignment
reg [15:0]  reg_4bit_under_0_align,reg_4bit_under_1_align,reg_4bit_under_2_align;
// reg cnt
reg [2:0]   reg_cnt_under;
wire        add_reg_cnt_under = flag_under_mean;
wire        end_reg_cnt_under = add_reg_cnt_under && reg_cnt_under == 4 - 1;
// cal the mean of rgb (4bits rgb -> 1bit rgb)
wire[7:0]   mean_red_under,mean_green_under,mean_blue_under;
wire[15:0]  mean_rgb_under;

reg         odata_val_d0;


// genarate col and row number
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        col_cnt <= 'b0;
    end else if (add_col_cnt) begin
        if(end_col_cnt)begin
            col_cnt <= 'b0;
        end else begin
            col_cnt <= col_cnt + 1'b1;
        end   
    end
end
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        row_cnt <= 'b0;
    end else if (add_row_cnt) begin
        if(end_row_cnt)begin
            row_cnt <= 'b0;
        end else begin
            row_cnt <= row_cnt + 1'b1;
        end   
    end
end

//----------------------------------------------------------------
//------------------------- above pixel --------------------------
//----------------------------------------------------------------
// above pixel ram
pixel_ram above_pixel_ram (
  .wr_data  (wr_data_above  ),    // input [15:0]
  .wr_addr  (wr_addr_above  ),    // input [8:0]
  .rd_addr  (rd_addr_above  ),    // input [8:0]
  .wr_clk   (wr_clk_above   ),    // input
  .rd_clk   (rd_clk_above   ),    // input
  .wr_en    (wr_en_above    ),    // input
  .rst      (rst            ),    // input
  .rd_data  (rd_data_above  )     // output [15:0]
);

//------------ 4bits read out and mean (4bits -> 1bits)-------------
// flag_above_mean
always@(posedge video_clk or posedge rst)begin
	if(rst)begin
		flag_above_mean <= 0;
    end else if(flag_above_mean_l2h)begin
		flag_above_mean <= 1;
    end else if(flag_above_mean_h2l)begin
        flag_above_mean <= 0;
    end
end
// rd_addr_above
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        rd_addr_above <= 'b0;
    end else if (add_rd_addr_above) begin
        if(end_rd_addr_above)begin
            rd_addr_above <= 'b0;
        end else begin
            rd_addr_above <= rd_addr_above + 1'b1;
        end   
    end
end
// reg cnt
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        reg_cnt_above <= 'b0;
    end else if (add_reg_cnt_above) begin
        if(end_reg_cnt_above)begin
            reg_cnt_above <= 'b0;
        end else begin
            reg_cnt_above <= reg_cnt_above + 1'b1;
        end   
    end
end
// reg arangement
always@(*)begin
    if(rst)begin
        reg_4bit_above_0 <= 0;
        reg_4bit_above_1 <= 0;
        reg_4bit_above_2 <= 0;
        reg_4bit_above_3 <= 0;
    end else begin
        if(add_reg_cnt_above && reg_cnt_above == 0) reg_4bit_above_0 <= rd_data_above;
        if(add_reg_cnt_above && reg_cnt_above == 1) reg_4bit_above_1 <= rd_data_above;
        if(add_reg_cnt_above && reg_cnt_above == 2) reg_4bit_above_2 <= rd_data_above;
        if(add_reg_cnt_above && reg_cnt_above == 3) reg_4bit_above_3 <= rd_data_above;
    end
end
// alignment
always@(*)begin
    if(rst)begin
        reg_4bit_above_0_align <= 0;
        reg_4bit_above_1_align <= 0;
        reg_4bit_above_2_align <= 0;
    end else if(end_reg_cnt_above)begin
        reg_4bit_above_0_align <= reg_4bit_above_0;
        reg_4bit_above_1_align <= reg_4bit_above_1;
        reg_4bit_above_2_align <= reg_4bit_above_2;
    end
end
// mean of rgb
assign mean_red_above   = (reg_4bit_above_0_align[(DATA_WIDTH-1)-:5] + reg_4bit_above_1_align[(DATA_WIDTH-1)-:5] + reg_4bit_above_2_align[(DATA_WIDTH-1)-:5] + reg_4bit_above_3[(DATA_WIDTH-1)-:5]);
assign mean_green_above = (reg_4bit_above_0_align[(DATA_WIDTH-6)-:6] + reg_4bit_above_1_align[(DATA_WIDTH-6)-:6] + reg_4bit_above_2_align[(DATA_WIDTH-6)-:6] + reg_4bit_above_3[(DATA_WIDTH-6)-:6]);
assign mean_blue_above  = (reg_4bit_above_0_align[(DATA_WIDTH-12)-:5] + reg_4bit_above_1_align[(DATA_WIDTH-12)-:5] + reg_4bit_above_2_align[(DATA_WIDTH-12)-:5] + reg_4bit_above_3[(DATA_WIDTH-12)-:5]);
assign mean_rgb_above   = {mean_red_above[6:2],mean_green_above[7:2],mean_blue_above[6:2]};

//----------------------------------------------------------------
//------------------------- left pixel ---------------------------
//----------------------------------------------------------------
// reg cnt
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        reg_cnt_left <= 'b0;
    end else if (add_reg_cnt_left) begin
        if(end_reg_cnt_left)begin
            reg_cnt_left <= 'b0;
        end else begin
            reg_cnt_left <= reg_cnt_left + 1'b1;
        end   
    end
end
// reg arangement
always@(*)begin
    if(rst)begin
        reg_4bit_left_0 <= 0;
        reg_4bit_left_1 <= 0;
        reg_4bit_left_2 <= 0;
        reg_4bit_left_3 <= 0;
    end else begin
        if(add_reg_cnt_left && reg_cnt_left == 0) reg_4bit_left_0 <= rgb565_i;
        if(add_reg_cnt_left && reg_cnt_left == 1) reg_4bit_left_1 <= rgb565_i;
        if(add_reg_cnt_left && reg_cnt_left == 2) reg_4bit_left_2 <= rgb565_i;
        if(add_reg_cnt_left && reg_cnt_left == 3) reg_4bit_left_3 <= rgb565_i;
    end
end
// alignment
always@(*)begin
    if(rst)begin
        reg_4bit_left_0_align <= 0;
        reg_4bit_left_1_align <= 0;
        reg_4bit_left_2_align <= 0;
    end else if(end_reg_cnt_left)begin
        reg_4bit_left_0_align <= reg_4bit_left_0;
        reg_4bit_left_1_align <= reg_4bit_left_1;
        reg_4bit_left_2_align <= reg_4bit_left_2;
    end
end
// mean of rgb
assign mean_red_left   = (reg_4bit_left_0_align[(DATA_WIDTH-1)-:5] + reg_4bit_left_1_align[(DATA_WIDTH-1)-:5] + reg_4bit_left_2_align[(DATA_WIDTH-1)-:5] + reg_4bit_left_3[(DATA_WIDTH-1)-:5]);
assign mean_green_left = (reg_4bit_left_0_align[(DATA_WIDTH-6)-:6] + reg_4bit_left_1_align[(DATA_WIDTH-6)-:6] + reg_4bit_left_2_align[(DATA_WIDTH-6)-:6] + reg_4bit_left_3[(DATA_WIDTH-6)-:6]);
assign mean_blue_left  = (reg_4bit_left_0_align[(DATA_WIDTH-12)-:5] + reg_4bit_left_1_align[(DATA_WIDTH-12)-:5] + reg_4bit_left_2_align[(DATA_WIDTH-12)-:5] + reg_4bit_left_3[(DATA_WIDTH-12)-:5]);
assign mean_rgb_left   = {mean_red_left[6:2],mean_green_left[7:2],mean_blue_left[6:2]};

//----------------------------------------------------------------
//------------------------- right pixel ---------------------------
//----------------------------------------------------------------
// reg cnt
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        reg_cnt_right <= 'b0;
    end else if (add_reg_cnt_right) begin
        if(end_reg_cnt_right)begin
            reg_cnt_right <= 'b0;
        end else begin
            reg_cnt_right <= reg_cnt_right + 1'b1;
        end   
    end
end
// reg arangement
always@(*)begin
    if(rst)begin
        reg_4bit_right_0 <= 0;
        reg_4bit_right_1 <= 0;
        reg_4bit_right_2 <= 0;
        reg_4bit_right_3 <= 0;
    end else begin
        if(add_reg_cnt_right && reg_cnt_right == 0) reg_4bit_right_0 <= rgb565_i;
        if(add_reg_cnt_right && reg_cnt_right == 1) reg_4bit_right_1 <= rgb565_i;
        if(add_reg_cnt_right && reg_cnt_right == 2) reg_4bit_right_2 <= rgb565_i;
        if(add_reg_cnt_right && reg_cnt_right == 3) reg_4bit_right_3 <= rgb565_i;
    end
end
// alignment
always@(*)begin
    if(rst)begin
        reg_4bit_right_0_align <= 0;
        reg_4bit_right_1_align <= 0;
        reg_4bit_right_2_align <= 0;
    end else if(end_reg_cnt_right)begin
        reg_4bit_right_0_align <= reg_4bit_right_0;
        reg_4bit_right_1_align <= reg_4bit_right_1;
        reg_4bit_right_2_align <= reg_4bit_right_2;
    end
end
// mean of rgb
assign mean_red_right   = (reg_4bit_right_0_align[(DATA_WIDTH-1)-:5] + reg_4bit_right_1_align[(DATA_WIDTH-1)-:5] + reg_4bit_right_2_align[(DATA_WIDTH-1)-:5] + reg_4bit_right_3[(DATA_WIDTH-1)-:5]);
assign mean_green_right = (reg_4bit_right_0_align[(DATA_WIDTH-6)-:6] + reg_4bit_right_1_align[(DATA_WIDTH-6)-:6] + reg_4bit_right_2_align[(DATA_WIDTH-6)-:6] + reg_4bit_right_3[(DATA_WIDTH-6)-:6]);
assign mean_blue_right  = (reg_4bit_right_0_align[(DATA_WIDTH-12)-:5] + reg_4bit_right_1_align[(DATA_WIDTH-12)-:5] + reg_4bit_right_2_align[(DATA_WIDTH-12)-:5] + reg_4bit_right_3[(DATA_WIDTH-12)-:5]);
assign mean_rgb_right   = {mean_red_right[6:2],mean_green_right[7:2],mean_blue_right[6:2]};

//----------------------------------------------------------------
//------------------------- under pixel --------------------------
//----------------------------------------------------------------
// under pixel ram
pixel_ram under_pixel_ram (
  .wr_data  (wr_data_under  ),    // input [15:0]
  .wr_addr  (wr_addr_under  ),    // input [8:0]
  .rd_addr  (rd_addr_under  ),    // input [8:0]
  .wr_clk   (wr_clk_under   ),    // input
  .rd_clk   (rd_clk_under   ),    // input
  .wr_en    (wr_en_under    ),    // input
  .rst      (rst            ),    // input
  .rd_data  (rd_data_under  )     // output [15:0]
);

//------------ 4bits read out and mean (4bits -> 1bits)-------------
// flag_under_mean
always@(posedge video_clk or posedge rst)begin
	if(rst)begin
		flag_under_mean <= 0;
    end else if(flag_under_mean_l2h)begin
		flag_under_mean <= 1;
    end else if(flag_under_mean_h2l)begin
        flag_under_mean <= 0;
    end
end
// rd_addr_under
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        rd_addr_under <= 'b0;
    end else if (add_rd_addr_under) begin
        if(end_rd_addr_under)begin
            rd_addr_under <= 'b0;
        end else begin
            rd_addr_under <= rd_addr_under + 1'b1;
        end   
    end
end
// reg cnt
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        reg_cnt_under <= 'b0;
    end else if (add_reg_cnt_under) begin
        if(end_reg_cnt_under)begin
            reg_cnt_under <= 'b0;
        end else begin
            reg_cnt_under <= reg_cnt_under + 1'b1;
        end   
    end
end
// reg arangement
always@(*)begin
    if(rst)begin
        reg_4bit_under_0 <= 0;
        reg_4bit_under_1 <= 0;
        reg_4bit_under_2 <= 0;
        reg_4bit_under_3 <= 0;
    end else begin
        if(add_rd_addr_under && reg_cnt_under == 0) reg_4bit_under_0 <= rd_data_under;
        if(add_rd_addr_under && reg_cnt_under == 1) reg_4bit_under_1 <= rd_data_under;
        if(add_rd_addr_under && reg_cnt_under == 2) reg_4bit_under_2 <= rd_data_under;
        if(add_rd_addr_under && reg_cnt_under == 3) reg_4bit_under_3 <= rd_data_under;
    end
end
// alignment
always@(*)begin
    if(rst)begin
        reg_4bit_under_0_align <= 0;
        reg_4bit_under_1_align <= 0;
        reg_4bit_under_2_align <= 0;
    end else if(end_reg_cnt_under)begin
        reg_4bit_under_0_align <= reg_4bit_under_0;
        reg_4bit_under_1_align <= reg_4bit_under_1;
        reg_4bit_under_2_align <= reg_4bit_under_2;
    end
end
// mean of rgb
assign mean_red_under   = (reg_4bit_under_0_align[(DATA_WIDTH-1)-:5] + reg_4bit_under_1_align[(DATA_WIDTH-1)-:5] + reg_4bit_under_2_align[(DATA_WIDTH-1)-:5] + reg_4bit_under_3[(DATA_WIDTH-1)-:5]);
assign mean_green_under = (reg_4bit_under_0_align[(DATA_WIDTH-6)-:6] + reg_4bit_under_1_align[(DATA_WIDTH-6)-:6] + reg_4bit_under_2_align[(DATA_WIDTH-6)-:6] + reg_4bit_under_3[(DATA_WIDTH-6)-:6]);
assign mean_blue_under  = (reg_4bit_under_0_align[(DATA_WIDTH-12)-:5] + reg_4bit_under_1_align[(DATA_WIDTH-12)-:5] + reg_4bit_under_2_align[(DATA_WIDTH-12)-:5] + reg_4bit_under_3[(DATA_WIDTH-12)-:5]);
assign mean_rgb_under   = {mean_red_under[6:2],mean_green_under[7:2],mean_blue_under[6:2]};



//----------------------------------------------------------------
//------------------------- pixel mean ---------------------------
//----------------------------------------------------------------
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        pixel_mean <= 'b0;
    end else begin
        if(end_reg_cnt_above) pixel_mean <= mean_rgb_above;
        if(end_reg_cnt_left)  pixel_mean <= mean_rgb_left;
        if(end_reg_cnt_right) pixel_mean <= mean_rgb_right;
        if(end_reg_cnt_under) pixel_mean <= mean_rgb_under;
    end
end
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        odata_val <= 'b0;
        odata_val_d0 <= 0;
    end else begin
        odata_val_d0 <= end_reg_cnt_above || end_reg_cnt_left || end_reg_cnt_right || end_reg_cnt_under;
        odata_val <= odata_val_d0;
    end
end

endmodule
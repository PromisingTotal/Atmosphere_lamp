module pixel_taking#(
    parameter          H_CMOS_DISP = 11'd1024,
    parameter          V_CMOS_DISP = 11'd768,
    parameter          DATA_WIDTH  = 16
)(
    input              rst,
    input              video_clk,
	input     [15:0]   pdata_i,
	output reg[15:0]   pdata_o,
    output reg         data_val
   );


wire        video_de;
reg         video_de_d0;


reg [11:0]  h_cnt;
reg [11:0]  v_cnt;
wire        add_h_cnt;
wire        end_h_cnt;
wire        add_v_cnt;
wire        end_v_cnt;
wire        interval_sampling = (!v_cnt[0] && !h_cnt[0]) ? 1'b1 : 1'b0;

// save the 4 pixel
reg [15:0]  reg_4bit_0,reg_4bit_1,reg_4bit_2,reg_4bit_3;
// alignment
reg [15:0]  reg_4bit_0_align,reg_4bit_1_align,reg_4bit_2_align;
// reg cnt
reg [2:0]   reg_cnt;
wire        add_reg_cnt;
wire        end_reg_cnt;
// cal the mean of rgb (4bits rgb -> 1bit rgb)
wire[7:0]   mean_red,mean_green,mean_blue;
wire[15:0]  mean_rgb;
reg         data_val_d0;

//------------------------------------------------------------------------
//------------------------------------------------------------------------
always@(posedge video_clk or posedge rst) begin
	if(rst == 1'b1)begin
		video_de_d0 <= 1'b0;
	end else begin
		video_de_d0 <= video_de;		
	end
end

color_bar color_bar_m0(
	.clk(video_clk),
	.rst(rst),
	.hs(),
	.vs(),
	.de(video_de),
	.rgb_r(),
	.rgb_g(),
	.rgb_b()
);

always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        h_cnt <= 12'b0;
    end else if (add_h_cnt) begin
        if(end_h_cnt)begin
            h_cnt <= 12'b0;
        end else begin
            h_cnt <= h_cnt + 1'b1;
        end   
    end
end
assign  add_h_cnt = video_de_d0;
assign  end_h_cnt = add_h_cnt && (h_cnt == H_CMOS_DISP-1);
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        v_cnt <= 12'b0;
    end else if (add_v_cnt) begin
        if(end_v_cnt)begin
            v_cnt <= 12'b0;
        end else begin
            v_cnt <= v_cnt + 1'b1;
        end   
    end
end
assign  add_v_cnt = end_h_cnt;
assign  end_v_cnt = add_v_cnt && (v_cnt == V_CMOS_DISP-1);

//------------------------------------------------------------------------
//------------------------------------------------------------------------
// reg cnt
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        reg_cnt <= 'b0;
    end else if (add_reg_cnt) begin
        if(end_reg_cnt)begin
            reg_cnt <= 'b0;
        end else begin
            reg_cnt <= reg_cnt + 1'b1;
        end   
    end
end
assign  add_reg_cnt = add_h_cnt && ~v_cnt[0];
assign  end_reg_cnt = add_reg_cnt && reg_cnt == 8 - 1;
// reg arangement
always@(*)begin
    if(rst)begin
        reg_4bit_0 <= 0;
        reg_4bit_1 <= 0;
        reg_4bit_2 <= 0;
        reg_4bit_3 <= 0;
    end else if(~v_cnt[0])begin
        if(add_reg_cnt && reg_cnt == 0) reg_4bit_0 <= pdata_i;
        if(add_reg_cnt && reg_cnt == 2) reg_4bit_1 <= pdata_i;
        if(add_reg_cnt && reg_cnt == 4) reg_4bit_2 <= pdata_i;
        if(add_reg_cnt && reg_cnt == 6) reg_4bit_3 <= pdata_i;
    end
end
// alignment
always@(*)begin
    if(rst)begin
        reg_4bit_0_align <= 0;
        reg_4bit_1_align <= 0;
        reg_4bit_2_align <= 0;
    end else if(end_reg_cnt)begin
        reg_4bit_0_align <= reg_4bit_0;
        reg_4bit_1_align <= reg_4bit_1;
        reg_4bit_2_align <= reg_4bit_2;
    end
end
// mean of rgb
assign mean_red   = (reg_4bit_0_align[(DATA_WIDTH-1)-:5] + reg_4bit_1_align[(DATA_WIDTH-1)-:5] + reg_4bit_2_align[(DATA_WIDTH-1)-:5] + reg_4bit_3[(DATA_WIDTH-1)-:5]);
assign mean_green = (reg_4bit_0_align[(DATA_WIDTH-6)-:6] + reg_4bit_1_align[(DATA_WIDTH-6)-:6] + reg_4bit_2_align[(DATA_WIDTH-6)-:6] + reg_4bit_3[(DATA_WIDTH-6)-:6]);
assign mean_blue  = (reg_4bit_0_align[(DATA_WIDTH-12)-:5] + reg_4bit_1_align[(DATA_WIDTH-12)-:5] + reg_4bit_2_align[(DATA_WIDTH-12)-:5] + reg_4bit_3[(DATA_WIDTH-12)-:5]);
assign mean_rgb   = {mean_red[6:2],mean_green[7:2],mean_blue[6:2]};

//----------------------------------------------------------------
//------------------------- pixel mean ---------------------------
//----------------------------------------------------------------
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        pdata_o <= 'b0;
    end else begin
        if(end_reg_cnt) pdata_o <= mean_rgb;
    end
end
always@(posedge video_clk or posedge rst)begin
    if(rst)begin
        data_val <= 'b0;
        data_val_d0 <= 'b0;
    end else begin
        data_val_d0 <= end_reg_cnt;
        data_val <= data_val_d0;
    end
end

endmodule
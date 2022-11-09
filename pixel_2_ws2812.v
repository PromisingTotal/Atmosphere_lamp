
module pixel_2_ws2812 (
    input  wire         clk,
    input  wire         rst,

    input  wire[23:0]   pixel_data,
    input  wire         pixel_data_vld,
    output wire         pixel_data_req,
    
    input  wire         ws2812_data_req,
    output wire[23:0]   ws2812_data,
    output wire         ws2812_data_vld
);

parameter NUM_PIXEL = 9'd444;
parameter NUM_CYCEL_RST = 16'd25000;



reg         reg_pixel_data_vld;
wire        rising_pixel_data_vld;

reg         reg_ws2812_data_req;
wire        rising_ws2812_data_req;

reg         flag_rst;
wire        flag_rst_l2h;
wire        flag_rst_h2l;

reg [8:0]   cnt_pixel;// max:444
wire        add_cnt_pixel;
wire        end_cnt_pixel;

reg [15:0]  cnt_rst;// max:444
wire        add_cnt_rst;
wire        end_cnt_rst;

//-------------------------------------------------------------------
//-------------------------------------------------------------------
assign      pixel_data_req = ~flag_rst & ws2812_data_req;
assign      ws2812_data = pixel_data;
assign      ws2812_data_vld = pixel_data_vld;
//-------------------------------------------------------------------
//-------------------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if(rst)begin
        reg_pixel_data_vld <= 0;
    end else begin
        reg_pixel_data_vld <= pixel_data_vld;
    end
end
assign rising_pixel_data_vld = pixel_data_vld & ~reg_pixel_data_vld;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        reg_ws2812_data_req <= 0;
    end else begin
        reg_ws2812_data_req <= ws2812_data_req;
    end
end
assign rising_ws2812_data_req = ws2812_data_req & ~reg_ws2812_data_req;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        flag_rst <= 1;
    end else begin
        if(flag_rst_l2h) flag_rst <= 1;
        if(flag_rst_h2l) flag_rst <= 0;
    end
end
assign flag_rst_l2h = cnt_pixel == 444 - 1 && rising_ws2812_data_req;
assign flag_rst_h2l = end_cnt_rst;


always @(posedge clk or posedge rst) begin
    if(rst)begin
        cnt_pixel <= 0;
    end else if(add_cnt_pixel)begin
        if(end_cnt_pixel)begin
            cnt_pixel <= 0;
        end else begin
            cnt_pixel <= cnt_pixel + 1'b1;
        end
    end
end
assign  add_cnt_pixel = rising_pixel_data_vld;
assign  end_cnt_pixel = add_cnt_pixel && cnt_pixel == NUM_PIXEL - 1;


always @(posedge clk or posedge rst) begin
    if(rst)begin
        cnt_rst <= 0;
    end else if(add_cnt_rst)begin
        if(end_cnt_rst)begin
            cnt_rst <= 0;
        end else begin
            cnt_rst <= cnt_rst + 1'b1;
        end
    end
end
assign  add_cnt_rst = flag_rst;
assign  end_cnt_rst = add_cnt_rst && cnt_rst == NUM_CYCEL_RST - 1;
    
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/13 22:07:25
// Design Name: 
// Module Name: WS2812_DRIVER
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//clk:输入时钟,需要50MHz
//rst:复位
//GRB_input:输入GRB数据24bit
//start_flag:开始信号
//GRB_output:输出
//end_flag:结束标志
/*
WS2812B驱动
一次性并行输入24bit，复位后start_flag为0,end_flag为1，
start_flag为开始信号，发送上升沿后开始读取数据，
数据完成传输后end_flag拉高，再次发送开始信号后end_flag自动拉低
当给出开始信号后数据需要一直维持到结束信号发出，
数据传输期间不会中断，再发送开始信号无效，直到结束，除非进行复位。
在同一数据周期内数据数据开始和结束间隔不要超过280us，超过280us为下一数据周期
*/
module WS2812_DRIVER(
input wire clk,
input wire rst,
input wire[23:0] GRB_input,
input wire start_flag,
output wire GRB_output,
output wire end_flag
    );
parameter CNT_CYCLE=78-1;//时钟65MHz
parameter CNT_FLAG1=19-1;
parameter CNT_FLAG2=39-1;
reg [6:0] cnt_cycle;//周期计数器
reg [4:0] i; //位数索引
wire one_bit;//缓存1bit
reg cycle_flag;//记满一个周期标志，其实就是计数溢出标位
reg start;//开始标志
reg finish;
reg wait_signal;//等待信号
assign end_flag=finish;
assign one_bit=GRB_input[23-i];
WS2812_1bit #(
        .CNT_CYCLE   (CNT_CYCLE),
        .CNT_FLAG1   (CNT_FLAG1),
        .CNT_FLAG2   (CNT_FLAG2)
)u_WS2812_1bit(
        .clk (clk),
        .rst (rst),
        .wait_signal (start),
        .one_bit (one_bit),
        .one_bit_output (GRB_output)
   );
//--------等待开始信号--------
always @(posedge clk or posedge start_flag or negedge  rst) begin
    if(rst==0) begin
        start<=1'b0;
        finish<=1'b1;
    end
    else if (start_flag==1'b1)begin
         start<=1'b1;
         finish<=1'b0;
    end
    else begin
        if(cycle_flag==1'b1) begin
            if(i==23) begin
                start<=1'b0;
                finish<=1'b1;
            end
         end
     end
end
//-------记一个周期--------
always @(posedge clk or  negedge rst) begin
    if(rst==0 || start==0)  begin
        cnt_cycle<='d0;
        cycle_flag<=1'b0;
    end
    else begin
         if(cnt_cycle==CNT_CYCLE) begin
              cnt_cycle<='d0;
              cycle_flag<=1'b1;
          end
          else begin
               cnt_cycle<=cnt_cycle+1'b1;
               cycle_flag<=1'b0;
          end
    end
end
//------解析每个位-------
always @(posedge  clk or negedge  rst) begin
    if(rst==0 ||start==0) begin
        i<=0;
    end
    else begin
        if(cycle_flag==1'b1) begin
            if(i==23) begin
                i<=0;
            end
            else begin
                i<=i+1;
            end
         end
    end
end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/13 22:53:03
// Design Name: 
// Module Name: WS2812_1bit
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

//1bit输出模块，输入需保持1.2us
module WS2812_1bit(
input clk,
input rst,
input wait_signal,
input one_bit,
output one_bit_output
    );
 parameter CNT_CYCLE=78-1;//时钟65MHz
 parameter CNT_FLAG1=19-1;
 parameter CNT_FLAG2=39-1;
 reg [6:0] cnt_cycle;
 reg pwm;
 wire inter_rst;
 assign one_bit_output=pwm;
 assign inter_rst=wait_signal && rst;
 //--------记一个周期--------
 always @(posedge clk or negedge inter_rst) begin
    if(inter_rst==1'b0) begin
        cnt_cycle<='d0;
    end
    else if(cnt_cycle==CNT_CYCLE)  begin
        cnt_cycle<='d0;
    end
    else  begin
        cnt_cycle<=cnt_cycle+1'b1;  
    end
 end
 //-----根据输入产生对应的PWM波
 always  @(posedge clk or negedge inter_rst) begin
    if(inter_rst==1'b0) begin
        pwm<=1'b0;
    end
    else if(one_bit==1'b0) begin
        if(cnt_cycle<CNT_FLAG1)begin
            pwm<=1'b1;
        end
        else begin
            pwm<=1'b0;
        end
    end
    else begin
        if(cnt_cycle<CNT_FLAG2)begin
            pwm<=1'b1;
        end
        else  begin
            pwm<=1'b0;
        end
    end
 end
endmodule

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
//clk:����ʱ��,��Ҫ50MHz
//rst:��λ
//GRB_input:����GRB����24bit
//start_flag:��ʼ�ź�
//GRB_output:���
//end_flag:������־
/*
WS2812B����
һ���Բ�������24bit����λ��start_flagΪ0,end_flagΪ1��
start_flagΪ��ʼ�źţ����������غ�ʼ��ȡ���ݣ�
������ɴ����end_flag���ߣ��ٴη��Ϳ�ʼ�źź�end_flag�Զ�����
��������ʼ�źź�������Ҫһֱά�ֵ������źŷ�����
���ݴ����ڼ䲻���жϣ��ٷ��Ϳ�ʼ�ź���Ч��ֱ�����������ǽ��и�λ��
��ͬһ�����������������ݿ�ʼ�ͽ��������Ҫ����280us������280usΪ��һ��������
*/
module WS2812_DRIVER(
input wire clk,
input wire rst,
input wire[23:0] GRB_input,
input wire start_flag,
output wire GRB_output,
output wire end_flag
    );
parameter CNT_CYCLE=78-1;//ʱ��65MHz
parameter CNT_FLAG1=19-1;
parameter CNT_FLAG2=39-1;
reg [6:0] cnt_cycle;//���ڼ�����
reg [4:0] i; //λ������
wire one_bit;//����1bit
reg cycle_flag;//����һ�����ڱ�־����ʵ���Ǽ��������λ
reg start;//��ʼ��־
reg finish;
reg wait_signal;//�ȴ��ź�
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
//--------�ȴ���ʼ�ź�--------
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
//-------��һ������--------
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
//------����ÿ��λ-------
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

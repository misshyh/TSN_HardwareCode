//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//�?术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料�?
//版权�?有，盗版必究�?
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           eth_udp_loop
// Last modified Date:  2020/2/18 9:20:14
// Last Version:        V1.0
// Descriptions:        以太网�?�信UDP通信环回顶层模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/18 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//
//----------------------------------------------------------------------------------------
//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************////***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//

module eth_udp_loop(
    input              sys_clk   , //系统时钟
    input              sys_rst_n , //系统复位信号，低电平有效 
    //以太�??????0RGMII接口   
    input              eth_rxc   , //RGMII接收数据时钟
    input              eth_rx_ctl, //RGMII输入数据有效信号
    input       [3:0]  eth_rxd   , //RGMII输入数据
    output             eth_txc   , ///RGMII发�?�数据时�?     
    output             eth_tx_ctl, //RGMII输出数据有效信号
    output      [3:0]  eth_txd   , //RGMII输出数据          
    output             eth_rst_n ,   //以太网芯片复位信号，低电平有�?
    //以太�?1RGMII接口  
    input              eth_rxc1   , //RGMII接收数据时钟
    input              eth_rx_ctl1, //RGMII输入数据有效信号
    input       [3:0]  eth_rxd1   , //RGMII输入数据
    output             eth_txc1   , //RGMII发�?�数据时�?    
    output             eth_tx_ctl1, //RGMII输出数据有效信号
    output      [3:0]  eth_txd1,    //RGMII输出数据    

    //串口IO
    input              uart_rxd,
    output             uart_txd,

    //LED输出模块
    output             led
    );

//uart parameter define
parameter  CLK_FREQ = 50000000;         //定义系统时钟频率
parameter  UART_BPS = 115200;           //定义串口波特�?
parameter  ETH_VLAN     = 32'h8100_2000   ;      //�޸Ĵ�1 

//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//

//发�?�网�?
//parameter define
//�?发板MAC地址 00-11-22-33-44-55
parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
//�?发板IP地址 192.168.1.10
parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};  
//目的MAC地址 ff_ff_ff_ff_ff_ff
parameter  DES_MAC   = 48'h00_11_22_33_44_66;
//parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;        
//目的IP地址 192.168.1.255     
parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd11};  
//输入数据IO延时,此处�?0,即不延时(如果为n,表示延时n*78ps) 
parameter IDELAY_VALUE = 0;

//接收网卡
//parameter define
//�?发板MAC地址 00-11-22-33-44-66
parameter  BOARD_MAC1 = 48'h00_11_22_33_44_66;     
//�?发板IP地址 192.168.1.11
parameter  BOARD_IP1  = {8'd192,8'd168,8'd1,8'd11};  
////目的MAC地址 ff_ff_ff_ff_ff_ff400
//parameter  DES_MAC1   = 48'h64_00_f1_11_22_33;    
////目的IP地址 192.168.1.10     
//parameter  DES_IP1    = {8'd192,8'd168,8'd1,8'd255};  
////输入数据IO延时,此处�??????0,即不延时(如果为n,表示延时n*78ps) 
parameter  DES_MAC1   = 48'h64_00_f1_11_22_33;    
//目的IP地址 192.168.1.10     
parameter  DES_IP1    = {8'd192,8'd168,8'd1,8'd25};  
//输入数据IO延时,此处�??????0,即不延时(如果为n,表示延时n*78ps) 
parameter IDELAY_VALUE1 = 0;


localparam T_200 = 32'b00000000000000001001110001000000;
localparam T_400 = 32'b00000000000000010011100010000000;
localparam T_600 = 32'b00000000000000011101010011000000;
//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//
/**************发�?�网卡相�?****************/
//wire define
wire          clk_200m   ; //用于IO延时的时�?????? 
              
wire          gmii_rx_clk; //GMII接收时钟
wire          gmii_rx_dv ; //GMII接收数据有效信号
wire  [7:0]   gmii_rxd   ; //GMII接收数据
wire          gmii_tx_clk; ///GMII发�?�时�?
wire          gmii_tx_en ; //GMII发�?�数据使能信�?
wire  [7:0]   gmii_txd   ; //GMII发�?�数�?    


wire  [47:0]  src_mac       ; //接收到目的MAC地址
wire  [31:0]  src_ip        ; //接收到目的IP地址    
wire  [47:0]  des_mac       ; //发�?�的目标MAC地址
wire  [31:0]  des_ip        ; //发�?�的目标IP地址   

wire          udp_gmii_tx_en; //UDP GMII输出数据有效信号 
wire  [7:0]   udp_gmii_txd  ; //UDP GMII输出数据
wire          rec_pkt_done  ; //UDP单包数据接收完成信号
wire          rec_en        ; //UDP接收的数据使能信�?
wire  [31:0]  rec_data      ; ////UDP接收的数�?
wire  [15:0]  rec_byte_num  ; //UDP接收的有效字节数 单位:byte 
wire  [15:0]  tx_byte_num   ; //UDP发�?�的有效字节�? 单位:byte 
wire          udp_tx_done   ; //UDP发�?�完成信�?
wire          tx_req        ; //UDP读数据请求信�?
wire  [31:0]  tx_data       ; //UDP待发送数�?


//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//
/***************接收网卡相关****************/
//wire define 
wire          gmii_rx_clk1; //GMII接收时钟
wire          gmii_rx_dv1 ; //GMII接收数据有效信号
wire  [7:0]   gmii_rxd1   ; //GMII接收数据
wire          gmii_tx_clk1; //GMII发�?�时�?
wire          gmii_tx_en1 ; //GMII发�?�数据使能信�?
wire  [7:0]   gmii_txd1   ; //GMII发�?�数�?   


wire  [47:0]  src_mac1       ; //接收到目的MAC地址
wire  [31:0]  src_ip1        ; //接收到目的IP地址    

wire  [47:0]  des_mac1       ; //发�?�的目标MAC地址
wire  [31:0]  des_ip1       ; //发�?�的目标IP地址 

wire          udp_gmii_tx_en1; //UDP GMII输出数据有效信号 
wire  [7:0]   udp_gmii_txd1  ; //UDP GMII输出数据
wire          rec_pkt_done1  ; //UDP单包数据接收完成信号
wire          rec_en1        ; //UDP接收的数据使能信�?
wire  [31:0]  rec_data1      ; //UDP接收的数�?
wire  [15:0]  rec_byte_num1  ; //UDP接收的有效字节数 单位:byte 
wire  [15:0]  tx_byte_num1   ; ////UDP发�?�的有效字节�? 单位:byte  
wire          udp_tx_done1   ; //UDP发�?�完成信�?
wire          tx_req1        ; //UDP读数据请求信�?
wire  [31:0]  tx_data1       ; //UDP待发送数�?


//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//
//*****************************************************
//**                    main code
//*****************************************************
/***************发�?�网卡相�?*********************************/
reg [31:0] fp;
assign tx_data = fp;       //发�?�数�?
assign tx_data1 = fp;
reg [24:0] cnt;
// reg [7:0] time_cnt;
reg [31:0] time_cnt;
reg [9:0] tx_time;
reg [9:0] rx_time;
reg [9:0] delay;
reg [9:0] delay1;
reg [9:0] time_h;
reg [9:0] tx_time_ms;
reg [9:0] rx_time_ms;

//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//
//*********************************************************�߼�����ģ��***************************************************************************//
//***********************************************************************************************************************************************//
//**************************************************************************************************************************************************//
//****************************************��ʱ*******************************************************************************************************//

reg [9:0] us;
reg [9:0] ms;
reg [5:0] s;
reg [5:0] min;
reg [7:0] t_hz;

always @(posedge clk_200m or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        t_hz <= 8'd0;
        us <= 10'd0;
        ms <= 10'd0;
        s <= 6'd0;
        min <= 6'd0;
    end
    else begin
        if(t_hz < 8'd200)begin
            t_hz <= t_hz + 8'd1; 
            end   
        else begin
            t_hz <= 8'd0;
            if(us < 10'd1000) begin
                us <= us + 10'd1;
            end
            else begin
                us <= 10'd0;
                ms <= ms + 10'd1;
                if(ms == 10'd1000) begin
                    ms <= 10'd0;
                    s <= s + 6'd1;
                    if(s == 6'd60) begin
                        s <= s + 6'd0;
                        min <= min + 6'd1;
                    end
                end
            end
        end
       end
end
//********************************ע��ʱ��us ms***************************************************************************************************************//
//always @(posedge clk_200m or negedge sys_rst_n) begin
//    if(!sys_rst_n)
//        fp <= 0;
//    else begin
//        if(udp_tx_done == 1'd1)
//            fp[31:22] <= us[9:0];
//            fp[23:14] <= ms[9:0];
//    end
//end
//*****************************���������ķ��ͼ�ʱ��******************************************************************************************************************//
reg [31:0] timeout_cnt;
always @(posedge clk_200m or negedge sys_rst_n) begin
    if(!sys_rst_n)
        timeout_cnt <= 0;
    else begin
            if(timeout_cnt > T_400)begin
                timeout_cnt <= timeout_cnt <= 0;
                end
            else begin
                timeout_cnt <= timeout_cnt + 32'd1;
                end
        end
    end

//********************************ÿ��ʱ�Ӷ�����ʱ���ע��************************************************************************************************************//
always @(posedge clk_200m or negedge sys_rst_n) begin
    if(!sys_rst_n)
        fp <= 0;
    else begin
        if(timeout_cnt==32'b000000000000000000000000111)begin
          fp[31:22] <= us[9:0];
          fp[23:14] <= ms[9:0];
        end
    end
end
//********************************ʱ�Ӽ��㲢���͵�uart***************************************************************************************************************//

always @(posedge clk_200m or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        tx_time <= 0;
        rx_time <= 0;
        delay <= 0;
        time_h <= 0;
    end
    else begin
        if(rec_pkt_done1 == 1'd1)begin
            tx_time[9:0] <= rec_data1[31:22];
            rx_time[9:0] <= us[9:0];
            // tx_time_ms[7:0] <= rec_data1[23:17];
            // rx_time_ms[7:0] <= ms[9:2];
            // if(tx_time_ms!=rx_time_ms)begin
            //     delay <= 0;
            // end
            // else 
            if(tx_time > rx_time)begin
//                delay <=( 10'd1000 - tx_time + rx_time > 8'd100)? 8'd86:10'd1000 - tx_time + rx_time;
//                delay <= 10'd1000 - tx_time + rx_time ;
                time_h <= 10'd1000 - tx_time + rx_time ;
                delay  <=  time_h;
//                if(time_h < 10'd100)  begin
//                    delay  <=  time_h;
////                    delay <=  time_h - 10'd80;
//                   end
//                 else begin
//                    if(time_h < 10'd200) begin
//                        delay  <=  time_h - 10'd100;
//                    end
//                    else begin
//                        delay  <= 10'd84;
//                    end
//                    end
            end
            else begin
//                delay <= ( rx_time - tx_time > 8'd100) ? 8'd71:rx_time - tx_time;
//                delay <=  rx_time - tx_time ;
                time_h <=  rx_time - tx_time ;
                delay  <=  time_h ;
//                if(time_h < 10'd100) begin
//                    delay <=  time_h ;
//                    end
//                else begin
//                    if(time_h < 10'd200) begin
//                        delay <=  time_h - 10'd100;
//                        end
//                      else begin
//                        delay <= 10'd76;
//                      end
//                end
            end           
        end       
    end 
end

//接收网卡�?要间隔一段时间发送一个包到交换机
always @(posedge rec_pkt_done1 or negedge sys_rst_n) begin
    if(!sys_rst_n)
       delay1 <= 0;
    else begin
        if(delay <  10'd100)begin
            delay1 <= 10'd100;
            end
         else begin
            if(delay <  10'd200)begin
                delay1 <= 10'd200;
            end
            else begin
                delay1 <= 10'd300;
            end
         end     
    end
end
//*****************************���������ķ��ͼ�ʱ��******************************************************************************************************************//
reg [31:0] timeout_cnt_1;
always @(posedge clk_200m or negedge sys_rst_n) begin
    if(!sys_rst_n)
        timeout_cnt_1 <= 0;
    else begin
            if(timeout_cnt_1>32'b01000000000000000000000000000)begin
                timeout_cnt_1 <= timeout_cnt_1 <= 0;
                end
            else begin
                timeout_cnt_1 <= timeout_cnt_1 + 32'd1;     
        end
    end
end
//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//
//*******************************发�?�使能部�?****************************************************************************************************************//
wire tx_start_en;
wire tx_start_en1;
wire timeout_cnt_flag;
wire timeout_cnt_flag_1;
assign timeout_cnt_flag = (timeout_cnt==32'b000000000000000000000001000) ? 1:0;
assign timeout_cnt_flag_1 = (timeout_cnt_1==32'b00000000000000000000000100) ? 1:0;
//assign tx_start_en = mode_flag_flag ? (timeout_cnt_flag | rec_pkt_done1) : timeout_cnt_flag;
assign tx_start_en = timeout_cnt_flag;
assign tx_start_en1 = timeout_cnt_flag_1;

assign tx_byte_num = 16'd8;             //发�?�byte数量
assign tx_byte_num1 = 16'd8;
assign des_mac = src_mac;
assign des_ip = src_ip;
assign des_mac1 = src_mac1;
assign des_ip1 = src_ip1;
assign eth_rst_n = sys_rst_n;
//***********************************************************************************************************************************************//

//always @(posedge gmii_rx_clk ) begin
//        if(rec_pkt_done1 == 1'd1)begin
//            if(delay > 8'd100) begin
//                delay <= 8'd85;
//                end
//                end
//end
reg [9:0] us_1;
reg [7:0] t_hz_1;
always @(posedge clk_200m or negedge sys_rst_n or posedge timeout_cnt_flag) begin
    if( !sys_rst_n  ) begin
        t_hz_1 <= 8'd0;
        us_1 <= 10'd0;
    end
    else begin
        if( timeout_cnt_flag==1 )begin
            t_hz_1 <= 8'd0;
            us_1 <= 10'd10;
            end
        else begin
            if(t_hz_1 < 8'd100)begin
                t_hz_1 <= t_hz_1 + 8'd1; 
                end   
            else begin
                t_hz_1 <= 8'd0;
                if(us_1 < 10'd1000) begin
                    us_1 <= us_1 + 10'd1;
                    end
                else begin
                    us_1 <= 10'd10;
                    end
            end
        end
     end
 end
//*********************************时钟部分*******************************************************************************************************//
//MMCM/PLL
clk_wiz u_clk_wiz(
    .clk_in1   (sys_clk   ),
    .clk_out1  (clk_200m  ),    
    .reset     (~sys_rst_n), 
    .locked    (locked)
);
//***********************************************************************************************************************************************//
//**************************************发�?�网卡：GMII接口转RGMII接口*********************************************************************************************************//
//GMII接口转RGMII接口
gmii_to_rgmii 
    #(
     .IDELAY_VALUE (IDELAY_VALUE)
     )
    u_gmii_to_rgmii(
    .idelay_clk    (clk_200m    ),

    .gmii_rx_clk   (gmii_rx_clk ),
    .gmii_rx_dv    (gmii_rx_dv  ),
    .gmii_rxd      (gmii_rxd    ),
    .gmii_tx_clk   (gmii_tx_clk ),
    .gmii_tx_en    (udp_gmii_tx_en  ),
    .gmii_txd      (udp_gmii_txd    ),
    
    .rgmii_rxc     (eth_rxc     ),
    .rgmii_rx_ctl  (eth_rx_ctl  ),
    .rgmii_rxd     (eth_rxd     ),
    .rgmii_txc     (eth_txc     ),
    .rgmii_tx_ctl  (eth_tx_ctl  ),
    .rgmii_txd     (eth_txd     )
    );

    
//***********************************************************************************************************************************************//
//**************************************发�?�网卡：UDP传输部分*********************************************************************************************************//
//UDP通信
udp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
//    .ETH_VLAN      (ETH_VLAN   )
    )
   u_udp(
    .rst_n         (sys_rst_n   ),  
    
    .gmii_rx_clk   (gmii_rx_clk ),           
    .gmii_rx_dv    (gmii_rx_dv  ),         
    .gmii_rxd      (gmii_rxd    ),                   
    .gmii_tx_clk   (gmii_tx_clk ), 
    .gmii_tx_en    (udp_gmii_tx_en),         
    .gmii_txd      (udp_gmii_txd),  

    .rec_pkt_done  (rec_pkt_done),    
    .rec_en        (rec_en      ),     
    .rec_data      (rec_data    ),         
    .rec_byte_num  (rec_byte_num),      
    .tx_start_en   (tx_start_en ),        
    .tx_data       (tx_data     ),         
    .tx_byte_num   (tx_byte_num ),  
    .des_mac       (des_mac     ),
    .des_ip        (des_ip      ),    
    .tx_done       (udp_tx_done ),        
    .tx_req        (tx_req      )           
    ); 
  



//同步FIFO
// sync_fifo_2048x32b u_sync_fifo_2048x32b (
//     .clk      (gmii_rx_clk),  // input wire clk
//     .rst      (~sys_rst_n),  // input wire rst
//     .din      (rec_data  ),  // input wire [31 : 0] din
//     .wr_en    (rec_en    ),  // input wire wr_en
//     .rd_en    (tx_req    ),  // input wire rd_en
//     .dout     (   ),  // output wire [31 : 0] dout
//     .full     (),            // output wire full
//     .empty    ()             // output wire empty
//     );  
//***********************************************************************************************************************************************//
//**************************************接收网卡：GMII接口转RGMII接口*********************************************************************************************************//
//GMII接口转RGMII接口
    gmii_to_rgmii 
    #(
     .IDELAY_VALUE (IDELAY_VALUE1)
     )
    u1_gmii_to_rgmii(
    .idelay_clk    (clk_200m    ),

    .gmii_rx_clk   (gmii_rx_clk1 ),
    .gmii_rx_dv    (gmii_rx_dv1  ),
    .gmii_rxd      (gmii_rxd1    ),
    .gmii_tx_clk   (gmii_tx_clk1 ),
    .gmii_tx_en    (udp_gmii_tx_en1  ),
    .gmii_txd      (udp_gmii_txd1    ),
    
    .rgmii_rxc     (eth_rxc1     ),
    .rgmii_rx_ctl  (eth_rx_ctl1  ),
    .rgmii_rxd     (eth_rxd1     ),
    .rgmii_txc     (eth_txc1     ),
    .rgmii_tx_ctl  (eth_tx_ctl1  ),
    .rgmii_txd     (eth_txd1     )
    );



//***********************************************************************************************************************************************//
//**************************************接收网卡：UDP模块*********************************************************************************************************//
//UDP通信
udp                                             
   #(
    .BOARD_MAC     (BOARD_MAC1),      //参数例化
    .BOARD_IP      (BOARD_IP1 ),
    .DES_MAC       (DES_MAC1  ),
    .DES_IP        (DES_IP1   )
//    .ETH_VLAN      (ETH_VLAN   )
    )
   u1_udp(
    .rst_n         (sys_rst_n   ),  
    
    .gmii_rx_clk   (gmii_rx_clk1 ),           
    .gmii_rx_dv    (gmii_rx_dv1  ),         
    .gmii_rxd      (gmii_rxd1    ),                   
    .gmii_tx_clk   (gmii_tx_clk1 ), 
    .gmii_tx_en    (udp_gmii_tx_en1),         
    .gmii_txd      (udp_gmii_txd1),  

    .rec_pkt_done  (rec_pkt_done1),    
    .rec_en        (rec_en1      ),     
    .rec_data      (rec_data1    ),         
    .rec_byte_num  (rec_byte_num1),      
    .tx_start_en   (tx_start_en1),        
    .tx_data       (tx_data1),         
    .tx_byte_num   (tx_byte_num1),  
    .des_mac       (des_mac1),
    .des_ip        (des_ip1      ),    
    .tx_done       (udp_tx_done1 ),        
    .tx_req        (tx_req1      )           
    ); 
//***********************************************************************************************************************************************//
//*************************************探针部分：测试信号线*********************************************************************************************************//
ila_0 u1_ila_0(
    .clk(clk_200m),
    .probe0(clk_200m),
    .probe1(timeout_cnt_flag),
    .probe2(tx_time),
    .probe3(rx_time),
    .probe4(delay),
    .probe5(rec_pkt_done1),
    .probe6(t_hz_1),
    .probe7(us_1),
    .probe8(ms)
);


//***********************************************************************************************************************************************//
//**************************************串口：UART*********************************************************************************************************//
wire uart_send_en;
wire [7:0] uart_send_data;
wire uart_tx_busy;
//wire uart_txd;
assign uart_send_en = rec_pkt_done1;
assign uart_send_data = us_1[7:0];


uart_send #(                          
    .CLK_FREQ       (CLK_FREQ),         //设置系统时钟频率
    .UART_BPS       (UART_BPS))         //设置串口发�?�波特率u0_uart_send
u_uart_send( 
    .sys_clk        (sys_clk),
    .sys_rst_n      (sys_rst_n),
     
    .uart_en        (uart_send_en),
    .uart_din       (uart_send_data),
    .uart_tx_busy   (uart_tx_busy),
    .uart_txd       (uart_txd)
);

endmodule
//***********************************************************************************************************************************************//
//***********************************************************************************************************************************************//
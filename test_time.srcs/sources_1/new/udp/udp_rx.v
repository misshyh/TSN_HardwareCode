//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//�?术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料�?
//版权�?有，盗版必究�?
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           udp_rx
// Last modified Date:  2020/2/18 9:20:14
// Last Version:        V1.0
// Descriptions:        以太网数据接收模�?
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/18 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module udp_rx(
    input                clk         ,    //时钟信号
    input                rst_n       ,    //复位信号，低电平有效
    
    input                gmii_rx_dv  ,    //GMII输入数据有效信号
    input        [7:0]   gmii_rxd    ,    //GMII输入数据
    output  reg          rec_pkt_done,    //以太网单包数据接收完成信�?
    output  reg          rec_en      ,    //以太网接收的数据使能信号
    output  reg  [31:0]  rec_data    ,    //以太网接收的数据
    output  reg  [15:0]  rec_byte_num     //以太网接收的有效字节�? 单位:byte     
    );

//parameter define
//�?发板MAC地址 00-11-22-33-44-55
parameter BOARD_MAC = 48'h00_11_22_33_44_55; 
//�?发板IP地址 192.168.1.10 
parameter BOARD_IP = {8'd192,8'd168,8'd1,8'd10};

localparam  st_idle     = 7'b000_0001; //初始状�?�，等待接收前导�?
localparam  st_preamble = 7'b000_0010; //接收前导码状�? 
localparam  st_eth_head = 7'b000_0100; //接收以太网帧�?
localparam  st_ip_head  = 7'b000_1000; //接收IP首部
localparam  st_udp_head = 7'b001_0000; //接收UDP首部
localparam  st_rx_data  = 7'b010_0000; //接收有效数据
localparam  st_rx_end   = 7'b100_0000; //接收结束

localparam  ETH_TYPE    = 16'h22ff   ; //以太网协议类�? IP协议
parameter  ETH_VLAN    = 32'h8100_e001   ; //以太网协议类�? IP协议
localparam  UDP_TYPE    = 8'd17      ; //UDP协议类型

//reg define
reg  [6:0]   cur_state       ;
reg  [6:0]   next_state      ;
                             
reg          skip_en         ; //控制状�?�跳转使能信�?
reg          error_en        ; //解析错误使能信号
reg  [4:0]   cnt             ; //解析数据计数�?
reg  [47:0]  des_mac         ; //目的MAC地址
reg  [15:0]  eth_type        ; //以太网类�?

reg  [31:0]  eth_vlan        ; //以太网类�?
reg  [31:0]  des_ip          ; //目的IP地址
reg  [5:0]   ip_head_byte_num; //IP首部长度
reg  [15:0]  udp_byte_num    ; //UDP长度
reg  [15:0]  data_byte_num   ; //数据长度
reg  [15:0]  data_cnt        ; //有效数据计数    
reg  [1:0]   rec_en_cnt      ; //8bit�?32bit计数�?

//*****************************************************
//**                    main code
//*****************************************************

//(三段式状态机)同步时序描述状�?�转�?
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cur_state <= st_idle;  
    else
        cur_state <= next_state;
end

//组合逻辑判断状�?�转移条�?
always @(*) begin
    next_state = st_idle;
    case(cur_state)
        st_idle : begin                                     //等待接收前导�?
            if(skip_en) 
                next_state = st_preamble;
            else
                next_state = st_idle;    
        end
        st_preamble : begin                                 //接收前导�?
            if(skip_en) 
                next_state = st_eth_head;
            else if(error_en) 
                next_state = st_rx_end;    
            else
                next_state = st_preamble;    
        end
        st_eth_head : begin                                 //接收以太网帧�?
            if(skip_en) 
                next_state = st_ip_head;
            else if(error_en) 
                next_state = st_rx_end;
            else
                next_state = st_eth_head;           
        end  
        st_ip_head : begin                                  //接收IP首部
            if(skip_en)
                next_state = st_udp_head;
            else if(error_en)
                next_state = st_rx_end;
            else
                next_state = st_ip_head;       
        end 
        st_udp_head : begin                                 //接收UDP首部
            if(skip_en)
                next_state = st_rx_data;
            else
                next_state = st_udp_head;    
        end                
        st_rx_data : begin                                  //接收有效数据
            if(skip_en)
                next_state = st_rx_end;
            else
                next_state = st_rx_data;    
        end                           
        st_rx_end : begin                                   //接收结束
            if(skip_en)
                next_state = st_idle;
            else
                next_state = st_rx_end;          
        end
        default : next_state = st_idle;
    endcase                                          
end    

//时序电路描述状�?�输�?,解析以太网数�?
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        skip_en <= 1'b0;
        error_en <= 1'b0;
        cnt <= 5'd0;
        des_mac <= 48'd0;
        eth_type <= 16'd0;
        eth_vlan <= 32'd0;
        des_ip <= 32'd0;
        ip_head_byte_num <= 6'd0;
        udp_byte_num <= 16'd0;
        data_byte_num <= 16'd0;
        data_cnt <= 16'd0;
        rec_en_cnt <= 2'd0;
        rec_en <= 1'b0;
        rec_data <= 32'd0;
        rec_pkt_done <= 1'b0;
        rec_byte_num <= 16'd0;
    end
    else begin
        skip_en <= 1'b0;
        error_en <= 1'b0;  
        rec_en <= 1'b0;
        rec_pkt_done <= 1'b0;
        case(next_state)
            st_idle : begin
                if((gmii_rx_dv == 1'b1) && (gmii_rxd == 8'h55)) 
                    skip_en <= 1'b1;
            end
            st_preamble : begin
                if(gmii_rx_dv) begin                         //解析前导�?
                    cnt <= cnt + 5'd1;
                    if((cnt < 5'd6) && (gmii_rxd != 8'h55))  //7�?8'h55  
                        error_en <= 1'b1;
                    else if(cnt==5'd6) begin
                        cnt <= 5'd0;
                        if(gmii_rxd==8'hd5)                  //1�?8'hd5
                            skip_en <= 1'b1;
                        else
                            error_en <= 1'b1;    
                    end  
                end  
            end
            st_eth_head : begin
                if(gmii_rx_dv) begin
                    cnt <= cnt + 5'b1;
                    if(cnt < 5'd6) 
                        des_mac <= {des_mac[39:0],gmii_rxd}; //目的MAC地址
                    else if(cnt == 5'd12) 
                        eth_vlan[31:24] <= gmii_rxd;          //以太网协议类�?
                    else if(cnt == 5'd13) 
                        eth_vlan[23:16] <= gmii_rxd;          //以太网协议类�?
                    else if(cnt == 5'd14) 
                        eth_vlan[15:8] <= gmii_rxd;          //以太网协议类�?
                    else if(cnt == 5'd15) 
                        eth_vlan[7:0] <= gmii_rxd;          //以太网协议类�?
                    else if(cnt == 5'd16) 
                        eth_type[15:8] <= gmii_rxd;          //以太网协议类�?
                    else if(cnt == 5'd17) begin
                        eth_type[7:0] <= gmii_rxd;
                        cnt <= 5'd0;
                        //判断MAC地址是否为开发板MAC地址或�?�公共地�?
                        if(((des_mac == BOARD_MAC) ||(des_mac == 48'hff_ff_ff_ff_ff_ff))
                       && eth_type[15:8] == ETH_TYPE[15:8] && eth_type[7:0] == ETH_TYPE[7:0]&&eth_vlan[15:8]==ETH_VLAN[15:8])            
                            skip_en <= 1'b1;
                        else
                            error_en <= 1'b1;
                    end        
                end  
            end
            st_ip_head : begin
                if(gmii_rx_dv) begin
                    cnt <= cnt + 5'd1;
                    if(cnt == 5'd0)
                        ip_head_byte_num <= {gmii_rxd[3:0],2'd0};  //寄存IP首部长度
                    else if(cnt == 5'd9) begin
                        if(gmii_rxd != UDP_TYPE) begin
                            //如果当前接收的数据不是UDP协议，停止解析数�?                        
                            error_en <= 1'b1;               
                            cnt <= 5'd0;                        
                        end
                    end                    
                    else if((cnt >= 5'd16) && (cnt <= 5'd18))
                        des_ip <= {des_ip[23:0],gmii_rxd};         //寄存目的IP地址
                    else if(cnt == 5'd19) begin
                        des_ip <= {des_ip[23:0],gmii_rxd}; 
                        //判断IP地址是否为开发板IP地址
                        if((des_ip[23:0] == BOARD_IP[31:8])
                            && (gmii_rxd == BOARD_IP[7:0])) begin  
                            if(cnt == ip_head_byte_num - 1'b1) begin
                                skip_en <=1'b1;                     
                                cnt <= 5'd0;
                            end                             
                        end    
                        else begin            
                            //IP错误，停止解析数�?                        
                            error_en <= 1'b1;               
                            cnt <= 5'd0;
                        end                                                  
                    end                          
                    else if(cnt == ip_head_byte_num - 1'b1) begin 
                        skip_en <=1'b1;                      //IP首部解析完成
                        cnt <= 5'd0;                    
                    end    
                end                                
            end 
            st_udp_head : begin
                if(gmii_rx_dv) begin
                    cnt <= cnt + 5'd1;
                    if(cnt == 5'd4)
                        udp_byte_num[15:8] <= gmii_rxd;      //解析UDP字节长度 
                    else if(cnt == 5'd5)
                        udp_byte_num[7:0] <= gmii_rxd;
                    else if(cnt == 5'd7) begin
                        //有效数据字节长度，（UDP首部8个字节，�?以减�?8�?
                        data_byte_num <= udp_byte_num - 16'd8;     
                        skip_en <= 1'b1;
                        cnt <= 5'd0;
                    end  
                end                 
            end          
            st_rx_data : begin         
                //接收数据，转换成32bit            
                if(gmii_rx_dv) begin
                    data_cnt <= data_cnt + 16'd1;
                    rec_en_cnt <= rec_en_cnt + 2'd1;
                    if(data_cnt == data_byte_num - 16'd1) begin
                        skip_en <= 1'b1;                    //有效数据接收完成
                        data_cnt <= 16'd0;
                        rec_en_cnt <= 2'd0;
                        rec_pkt_done <= 1'b1;               
                        rec_en <= 1'b1;                     
                        rec_byte_num <= data_byte_num;
                    end    
                    //先收到的数据放在了rec_data的高�?,�?以当数据不是4的�?�数�?,
                    //低位数据为无效数据，可根据有效字节数来判�?(rec_byte_num)
                    if(rec_en_cnt == 2'd0)
                        rec_data[31:24] <= gmii_rxd;
                    else if(rec_en_cnt == 2'd1)
                        rec_data[23:16] <= gmii_rxd;
                    else if(rec_en_cnt == 2'd2) 
                        rec_data[15:8] <= gmii_rxd;        
                    else if(rec_en_cnt==2'd3) begin
                        rec_en <= 1'b1;
                        rec_data[7:0] <= gmii_rxd;
                    end    
                end  
            end    
            st_rx_end : begin                               //单包数据接收完成   
                if(gmii_rx_dv == 1'b0 && skip_en == 1'b0)
                    skip_en <= 1'b1; 
            end    
            default : ;
        endcase                                                        
    end
end

endmodule
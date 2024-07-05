# import imp
from socket import timeout
import serial
import PySimpleGUI as sg  
uart=serial.Serial('COM13',115200,timeout=2,parity=serial.PARITY_NONE,rtscts=0)
time_max=0
layout = [
	[sg.Text('测试仪结果')],      
	# [sg.InputText()],      
	# [sg.Submit(), sg.Cancel()]
] 
window = sg.Window('Window Title',layout)  
window = sg.Window('size')  
# event, values = window.read()   

while True:
    data=uart.read()
    # if x:
    #     str=x.decode('utf-8')
    #     print(str,end='')
    out_1 = ''

    for i in range(0,len(data)):
        out_1 = out_1 + '{:02X}'.format(data[i]) + ' '  #加空格
    out_1 = [i for i in list(out_1.split(' ')) if i != '']
    out_1 = [(int(j,16)) for j in out_1]
    #{}["REV_DATA"] = (out_1)
    #print("receive",bytes(binascii.b2a_hex(out_1))[2:-1])
                               #Hex转换成字符串
    if out_1:
        data_print=int(out_1[0])
        if time_max<data_print:
            time_max=data_print
        print('now the delay is '+str(data_print))
        print('now the max delay is '+str(time_max))
        # print(type(data_print))
    # print(type(out_1))
    # print(out_1)
    # print(len(out_1))

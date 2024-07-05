from numpy.lib.function_base import place
import serial
import serial.tools.list_ports
import sys
import re
import os
import time
import datetime
import threading
from PyQt5.QtCore import *
from PyQt5.QtGui import *
from PyQt5.QtWidgets import *
global max_delay


class Serialwindow(QWidget):
    def __init__(self) -> None:
        super().__init__()
        self.initUI()
    def initUI(self):


        #self.qssstyle = CommonHelper.readQSS(self.stylefile)

        self.port = ''
        self.bps = 0
        self.timeout = 0.0

        self.senddata=bytes()

        self.read_data=''
        
        self.btn_plist=QPushButton('获取可用串口',self)
        self.btn_plist.setGeometry(20,20,60,20)
        self.btn_plist.clicked.connect(self.get_serial_info)
        self.btn_plist.adjustSize()
        
        self.btn_ser_init=QPushButton('初始化',self)
        self.btn_ser_init.setGeometry(20,50,60,20)
        self.btn_ser_init.clicked.connect(self.serial_init)
        self.btn_ser_init.adjustSize()

        self.btn_open=QPushButton('打开串口',self)
        self.btn_open.setGeometry(20,80,60,20)
        self.btn_open.clicked.connect(self.open_serial)
        self.btn_open.adjustSize()

        self.btn_close=QPushButton('关闭串口',self)
        self.btn_close.setGeometry(20,110,60,20)
        self.btn_close.clicked.connect(self.close_serial)
        self.btn_close.adjustSize()

        self.btn_read_data=QPushButton('读取数据',self)
        self.btn_read_data.setGeometry(20,140,60,20)
        self.btn_read_data.clicked.connect(self.read_data_size)
        self.btn_read_data.adjustSize()

        # self.btn_write_data=QPushButton('发送数据',self)
        # self.btn_write_data.setGeometry(40,460,60,20)
        # self.btn_write_data.clicked.connect(self.send_data)
        # self.btn_write_data.adjustSize()

        #Qcombobox
        self.port_set=QComboBox(self)
        self.port_set.setGeometry(500,20,100,20)
        self.port_set.addItems(['COM13'])
        #self.port_set.activated.connect(self.Qcombo)

        self.lbl_port_set=QLabel(self)
        self.lbl_port_set.setGeometry(420,20,60,20)
        self.lbl_port_set.setText('串口号:')

        self.baud_set=QComboBox(self)
        self.baud_set.setGeometry(500,50,100,20)
        self.baud_set.addItems(['115200','19200','38400','9600'])

        self.lbl_baud_set=QLabel(self)
        self.lbl_baud_set.setGeometry(420,50,60,20)
        self.lbl_baud_set.setText('波特率:')

        self.stopbit_set=QComboBox(self)
        self.stopbit_set.setGeometry(500,80,100,20)
        self.stopbit_set.addItems(['0','1'])

        self.lbl_stopbit_set = QLabel(self)
        self.lbl_stopbit_set.setGeometry(420, 80, 60, 20)
        self.lbl_stopbit_set.setText('停止位:')

        self.parity_set=QComboBox(self)
        self.parity_set.setGeometry(500,110,100,20)
        self.parity_set.addItems(['无','奇校验','偶校验'])

        self.lbl_parity_set = QLabel(self)
        self.lbl_parity_set.setGeometry(420, 110, 60, 20)
        self.lbl_parity_set.setText('校验位:')

        self.databit_set=QComboBox(self)
        self.databit_set.setGeometry(500,140,100,20)
        self.databit_set.addItems(['8','7'])

        self.lbl_databit_set=QLabel(self)
        self.lbl_databit_set.setGeometry(420,140,60,20)
        self.lbl_databit_set.setText('数据位:')

        self.timeout_set=QLineEdit(self)
        self.timeout_set.setGeometry(500,170,100,20)
        self.timeout_set.setText('1000')

        self.lbl_timeout_set=QLabel(self)
        self.lbl_timeout_set.setGeometry(420,170,60,20)
        self.lbl_timeout_set.setText('超时设置:')

        self.lbl_timeout_set_2=QLabel(self)
        self.lbl_timeout_set_2.setGeometry(610,170,60,20)
        self.lbl_timeout_set_2.setText('ms')


        #
        # self.le_senddata=QLineEdit(self)
        # self.le_senddata.setGeometry(120,460,300,20)
        # self.le_senddata.setText('010300100002C5CE')

        self.le_recdata=QTextEdit(self)
        self.le_recdata.setGeometry(120,220,600,200)

        self.setGeometry(100,100,800,600)
        self.setWindowTitle('时间敏感网络测试仪')
       # self.setStyleSheet(self.qssstyle)
        self.show()


    def Qcombo(self):
        print(self.port_set.currentText())
        print(self.baud_set.currentText())
        print(self.stopbit_set.currentText())
        print(self.parity_set.currentText())
        print(self.databit_set.currentText())
        print(self.timeout_set.text())

    def get_serial_info(self):   #获取可用串口列表

        #打印可用串口列表
        #self.need_serial = ''

        self.plist = list(serial.tools.list_ports.comports())
        if len(self.plist) <= 0:
            print('未找到串口')
            qm = QMessageBox.warning(self, '提示窗口', '未找到串口!请检查接线和电脑接口。', QMessageBox.Ok|QMessageBox.Cancel,QMessageBox.Ok)
            if qm == QMessageBox.Yes:
                print('Yes')
            else:
                print('No')
        else:
            for i in list(self.plist):

                self.port_set.addItem(i.name)


        #return self.need_serial
        #print(self.plist)

    def serial_init(self):   #初始化

        self.port = self.port_set.currentText()
        self.bps = int(self.baud_set.currentText())
        self.timeout = float(self.timeout_set.text())

        try:
            self.ser = serial.Serial(port=self.port,baudrate=self.bps,bytesize=8,parity='N',stopbits=1)
            print(self.ser)
            if self.ser.is_open:
                print('串口正常')
        except Exception as e:

            QMessageBox.warning(self, 'tips!', str(e), QMessageBox.Ok | QMessageBox.Cancel, QMessageBox.Ok)
            print('初始化异常：', e)


    def open_serial(self):   #打开串口
        try:
            self.ser.open()
        except Exception as e:
            QMessageBox.warning(self, 'tips!', str(e), QMessageBox.Ok | QMessageBox.Cancel, QMessageBox.Ok)
            print('打开串口异常：', e)

    def close_serial(self):  #关闭串口
        try:
            self.ser.close()

        except Exception as e:

            QMessageBox.warning(self,'tips!',str(e),QMessageBox.Ok|QMessageBox.Cancel,QMessageBox.Ok)
            print('关闭串口异常：', e)


    def read_data_size(self):

        ct=datetime.datetime.now()
        ct_str=ct.strftime("%Y-%m-%d %H:%M:%S")
        try:
            #self.size=10
            self.read_data=self.ser.read_all()
            #print(self.read_data)
            self.read_data_str=self.read_data.hex()   #字节转成16进制字符显示
            #re.findall(r'.{3}',self.read_data_str)
            self.read_data_str_fg=self.str_fenge(self.read_data_str)
            #print(self.read_data_str)
            self.le_recdata.append('\n'+'['+ct_str+']'+' '+self.read_data_str_fg+'\n')
            # self.le_recdata='\n'+'['+ct_str+']'+' '+self.read_data_str_fg+'\n'
        except Exception as e:
            QMessageBox.warning(self, 'read_data_size tips!', str(e), QMessageBox.Ok | QMessageBox.Cancel, QMessageBox.Ok)
        #return self.read_data

    def read_data_line(self):

        self.read_data=self.ser.readline()
        return self.read_data

    def read_data_alway(self, way):
        print('开始接受数据：')
        while True:
            try:
                if self.ser.inWaiting:
                    if(way == 0 ):
                        for i in range(self.ser.inWaiting):
                            print('接收ascII数据：'+str(self.read_data_size(1)))
                            data1 = self.read_data_size(1).hex()
                            data2 = int(data1, 16)
                            print('1123')
                            print('接收到16进制数据：'+data1+'接收到10进制数据：'+str(data2))
                    if(way == 1 ):
                        data = self.ser.read_all()
            except Exception as e:
                print('read_data_alway 异常：', e)


    def str_fenge(self,A):
        '''
        对字符串进行按长度分割，并在中间加入其他字符，如空格、短横等
        '''
        b = re.findall(r'.{2}',A)    ####获取的字符串
        # b = '123456897'
        c = ' '.join(b)                ####字符串中添加空格
        print(c)
        # b = '12 34 56 89 17'      ##实际运行过程中需要将b直接替换成c
        ##############################################################
        s=c.split()
        d=[]
        for i in s:
            a=int(i,16)
            d.append(a)
        print(d)
        print(type(d[0]))      ##列表d为 int类型,数据处理部分在这里实现
        head_1='delay is :'
        head_2='the max delay is : '
        # if max_delay<max(d) :
        #     max_delay=max(d)
        out_str=head_1+str(d)+'\n'+head_2+str(max(d))
        # out_str=head_1+str(d)+'\n'+head_2+str(max_delay)
        return out_str

if __name__ == '__main__':

    app = QApplication(sys.argv)
    ex = Serialwindow()
    sys.exit(app.exec_())

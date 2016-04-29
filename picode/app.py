from flask import Flask
app = Flask(__name__)

import time
import serial
import threading
import requests
from serial import SerialException

@app.route('/m/<angle>/<usr>')
def runm(angle, usr):

    s = "m" + "," + str(angle) + "," + str(usr) + "\n"
    print 
    
    try:
       ser.open()
    except:
       pass

    ser.write(s)
    print "WRITING TO FIREFLY:", s,
    
    try:
       ser.close()
    except:
       pass
    
    return s


@app.route('/p/<angle>/<usr>')
def runp(angle, usr):

    s = "p" + "," + str(angle) + "," + str(usr) + "\n"
    print 

    try:
       ser.open()
    except:
       pass

    ser.write(s)
    print "WRITING TO FIREFLY:", s,
    
    try:
       ser.close()
    except:
       pass
   
    return s

@app.route('/lowpower/<on>/<usr>')
def low_power(on, usr):
    
    print 
    usr_node = int(usr)
    
    if on == "on":
	on_node = 1
    else:
        on_node = 0

    s = "l" + "," + str(on_node) + "," + str(usr_node) + "\n"

    try:
       ser.open()
    except:
       pass

    ser.write(s)
    print "WRITING TO FIREFLY:", s,
    
    try:
       ser.close()
    except:
       pass

    return s


def receive(ser):

    while True:
        
        try:
	   ser.open()
        except:
	   pass

	x = ser.readline()
        
        try:
           ser.close()
        except:
           pass

	if (x != ""):
	   print 
	   print "FROM FIREFLY:", x,

	   if (x[0] == "i"):
	       string = x.split(",")
	       servo_pos = int(string[1])
	       usr_node = int(string[2])
	       print "FROM APP:", requests.get('http://touch-mobile-cloud.herokuapp.com/api/servo_location/'+str(usr_node)+"/"+str(servo_pos)).content		    
   
	   elif (x[0] == "d"):
	       string = x.split(",")
	       usr_node = int(string[1])
	       print "FROM APP:", requests.get('http://touch-mobile-cloud.herokuapp.com/api/low_battery/'+str(usr_node)).content		

	   elif (x[0] == "e"):
	       string = x.split(",")
	       usr_node = int(string[1])
	       print "FROM APP:", requests.get('http://touch-mobile-cloud.herokuapp.com/api/not_found/'+str(usr_node)).content
	   
#115200
if __name__ == '__main__':

    ser = serial.Serial(
       port='/dev/ttyAMA0',
       baudrate = 115200,
       parity=serial.PARITY_NONE,
       stopbits=serial.STOPBITS_ONE,
       bytesize=serial.EIGHTBITS,
       timeout=10
       )

    ser.close()    
    lock = threading.Lock()
    t = threading.Thread(target= receive, args=[ser])
    t.setDaemon(True)
    t.start()
    app.run(debug=True, host='0.0.0.0', threaded=True)

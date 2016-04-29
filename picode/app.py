from flask import Flask
app = Flask(__name__)

import time
import serial
import threading
import requests


@app.route('/m/<angle>/<usr>')
def runm(angle, usr):

    global low_power_queue
    global low_power_cmd

    s = "m" + "," + str(angle) + "," + str(usr) + "\n"
    print 
    if (int(usr) not in low_power_queue):
    	lock.acquire()
    	try:
		ser.open()
    	except:
		pass
    	ser.write(s)
	print "WRITING TO FIREFLY:", s,
    	ser.close()
    	lock.release()
    else: 
	print "Its in low power mode. Not sending"
	usr_node = int(usr)
	low_power_cmd[usr_node] = [s]	
	print low_power_cmd
	print low_power_queue

    return s


@app.route('/p/<angle>/<usr>')
def runp(angle, usr):

    global low_power_queue
    global low_power_cmd

    s = "p" + "," + str(angle) + "," + str(usr) + "\n"
    print 
    if (int(usr) not in low_power_queue):
    	lock.acquire()
    	try:
        	ser.open()
    	except:
        	pass
    	ser.write(s)
	print "WRITING TO FIREFLY:", s,
    	ser.close()
    	lock.release()
    else: 
	print "Its low power mode. Not sending"
	usr_node = int(usr)
	low_power_cmd[usr_node] = [s]
	print low_power_cmd
	print low_power_queue
	
    return s


@app.route('/l/<on>/<usr>')
def low_power(on, usr):
    
    global low_power_queue
    global low_power_cmd

    print 
    usr_node = int(usr)
    on_node = int(on)

    if (on_node == 1) and usr_node not in low_power_queue:
	low_power_queue.append(usr_node)
	
    elif (on_node == 0) and usr_node in low_power_queue:
	low_power_queue.remove(usr_node)
	low_power_cmd[usr_node] = []
	
    s = "l" + "," + str(on) + "," + str(usr) + "\n"

    lock.acquire()
    try:
       ser.open()
    except:
       pass
    ser.write(s)
    print "WRITING TO FIREFLY:", s,
    ser.close()
    lock.release()
    return s


def receive():

    global low_power_queue
    global low_power_cmd

    while True:
        try:
	    ser.open()
	except:
	    pass
    	
	x = ser.readline()
	ser.close()
	
	if (x != ""):
	   print 
	   print "FROM FIREFLY:", x,
	
	   if (x[0] == "w"):
	       string = x.split(",")
               usr_node = int(string[1])	   
	       print low_power_queue, low_power_cmd	
	       if ((usr_node in low_power_queue) and (usr_node in low_power_cmd) and (low_power_cmd[usr_node] != [])):	       
	           cmd = low_power_cmd[usr_node][0]
	    
		   lock.acquire()
	           try:
	               ser.open()
        	   except:	
        	       pass
        	   ser.write(cmd)
		   print "WRITING TO FIREFLY:", cmd,

		   low_power_cmd[usr_node] = []
       		   ser.close()
       		   lock.release()
     
	   elif (x[0] == "q"):
	       string = x.split(",")
	       usr_node = int(string[1])
	       
	       if (usr_node in low_power_queue):
	           low_power = 1
	       else:
	           low_power = 0

	       cmd =  "l" + "," + str(lower_power) + "," + str(usr_node) + "\n"
	       lock.acquire()
               try:
                  ser.open()
               except:
                  pass
               ser.write(cmd)
	       print "WRITING TO FIREFLY:", cmd,
               ser.close()
               lock.release()

	   elif (x[0] == "i"):
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
	   

if __name__ == '__main__':

    low_power_queue = []
    low_power_cmd = dict()

    ser = serial.Serial(
       port='/dev/ttyAMA0',
       baudrate = 115200,
       parity=serial.PARITY_NONE,
       stopbits=serial.STOPBITS_ONE,
       bytesize=serial.EIGHTBITS,
       timeout=2
       )

    lock = threading.Lock()
    t = threading.Thread(target= receive, args=[])
    t.setDaemon(True)
    t.start()
    app.run(debug=True, host='0.0.0.0', threaded=True)

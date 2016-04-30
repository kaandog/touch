import time
import requests
import BaseHTTPServer 

HOST_NAME = 'touchpi.wv.cc.cmu.edu' 
PORT_NUMBER = 5000 # Maybe set this to 9000.

import serial
import threading

ser = serial.Serial(
       port='/dev/ttyAMA0',
       baudrate = 115200,
       parity=serial.PARITY_NONE,
       stopbits=serial.STOPBITS_ONE,
       bytesize=serial.EIGHTBITS,
       timeout=1
       )

class MyHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_HEAD(s):
       s.send_response(200)
       s.send_header("Content-type", "text/html")
       s.end_headers()

    def do_GET(s):
       """Respond to a GET request."""
       s.send_response(200)
       s.send_header("Content-type", "text/html")
       s.end_headers()

       parameters =  s.path.split("/")[1:]

       s.wfile.write("<html><head><title>Title goes here.</title></head>")
       s.wfile.write("<body>")
       s.wfile.write("<p>You accessed path: %s</p>" % s.path)

       lock.acquire()
       
       if (parameters[0] == "m" or parameters[0] == "p"):
           try:
               angle = int(parameters[1])
               user_id = int(parameters[2])
               request = parameters[0] + str(",") + str(angle) + str(",") + str(user_id) + "\n"
               s.wfile.write("<p> The request is: %s </p>" % request)
               print "WRITING TO FIREFLY:", request,
               ser.write(request)
           except:
               pass

       elif (parameters[0] == "l"):
           try:
               node_on = int(parameters[1])
               if (node_on == 1 or node_on == 0):
                   user_id = int(parameters[2])
                   request = parameters[0] + str(",") + str(node_on) + str(",") + str(user_id) + "\n"
                   s.wfile.write("<p> The request is: %s </p>" % request)
                   print "WRITING TO FIREFLY:", request,
                   ser.write(request)
           except:
               pass
       s.wfile.write("</body></html>")
       lock.release()


def receive_from_firefly():
    while True:
        x = ser.readline()
	lock.acquire()

        if (x != ""):
            print "FROM FIREFLY:", x,
            if (x[0] == "i"):
                string = x.split(",")
                servo_pos = int(string[1])
                node_id = int(string[2])
                print "FROM APP:", requests.get('http://touch-mobile-cloud.herokuapp.com/api/servo_location/'+str(node_id)+"/"+str(servo_pos)).content		    
               
            elif (x[0] == "d"):
                string = x.split(",")
                low_battery = int(string[1])
                node_id = int(string[2])
                print "FROM APP:", requests.get('http://touch-mobile-cloud.herokuapp.com/api/low_battery/'+str(node_id)+"/"+str(low_battery)).content		


            elif (x[0] == "e"):
                string = x.split(",")
		node_found = int(string[1])
                node_id = int(string[2])
                print "FROM APP:", requests.get('http://touch-mobile-cloud.herokuapp.com/api/is_found/'+str(node_id)+"/"+str(node_found)).content
	lock.release()
        
if __name__ == '__main__':
    server_class = BaseHTTPServer.HTTPServer
    httpd = server_class((HOST_NAME, PORT_NUMBER), MyHandler)

    lock = threading.Lock()

    t = threading.Thread(target= receive_from_firefly, args=[])
    t.setDaemon(True)
    t.start()
    
    
    print time.asctime(), "Server Starts - %s:%s" % (HOST_NAME, PORT_NUMBER)
    try:
        while True:
            httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    print time.asctime(), "Server Stops - %s:%s" % (HOST_NAME, PORT_NUMBER)

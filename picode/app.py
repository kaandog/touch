from flask import Flask
app = Flask(__name__)


import time
import serial

ser = serial.Serial(
       port='/dev/ttyAMA0',
       baudrate = 115200,
       parity=serial.PARITY_NONE,
       stopbits=serial.STOPBITS_ONE,
       bytesize=serial.EIGHTBITS,
       timeout=1
       )

@app.route('/up/<usr>')
def up(usr):
    s = "UP : " + str(usr)
    print s
    ser.write("5")
    return s

@app.route('/down/<usr>')
def down(usr):
    s = "DOWN : " + str(usr)
    print s
    ser.write("1")
    return s

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

    

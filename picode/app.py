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

@app.route('/<angle>/<usr>')
def run(angle, usr):
    s = str(angle) + "," + str(usr) + "\n"
    ser.write(s)
    return s

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

    

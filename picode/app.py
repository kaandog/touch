from flask import Flask
app = Flask(__name__)

@app.route('/up/<usr>')
def up(usr):
    s = "UP : " + str(usr)
    print s
    return s

@app.route('/down/<usr>')
def down(usr):
    s = "DOWN : " + str(usr)
    print s
    return s

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

    

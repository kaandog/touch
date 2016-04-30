#!/bin/sh
#launcher.sh


while ! wget http://google.com -O- 2>/dev/null | grep -q Lucky; do
sleep 10
done

cd /
cd home/pi/touch/picode
python server_threaded.py
cd /

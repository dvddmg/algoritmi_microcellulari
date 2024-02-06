#!/bin/bash
#export DISPLAY=:0

qjackctl -s &
sleep 8
python servo_osc.py &
sclang MAIN.scd

import argparse
import numpy as np
import random as rnd
from pythonosc.dispatcher import Dispatcher
from pythonosc import osc_server
from adafruit_servokit import ServoKit

kit = ServoKit(channels=16)
ip = "127.0.0.1"
port = 5005
valori = [0] * 16
nServo = 16

def smistatore(address, args):
   global valori
   valori = np.fromstring(args, dtype=int, sep=",")
   servos()

def servos():
   global valori
   for i in range(nServo):
      if valori[i] == 180:
         kit.servo[i].angle = rnd.randint(0, 180)

try:
  while True:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ip", default=ip, help="The ip to listen on")
    parser.add_argument("--port", type=int, default=port, help="The port to listen on")
    args = parser.parse_args()

    dispatcher = Dispatcher()
    dispatcher.map("/power", smistatore)

    server = osc_server.ThreadingOSCUDPServer((args.ip, args.port), dispatcher)
    print("Serving on {}".format(server.server_address))
    server.serve_forever()

except: KeyboardInterrupt
print("\nfine")

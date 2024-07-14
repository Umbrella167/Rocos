# -*- coding: utf-8 -*-
"""
@Brief: This is a vision module(single robot) for RoboCup Small Size League 
@Version: grSim 4 camera version
@author: Wang Yunkai
"""

import socket
from time import sleep
import vision_detection_pb2 as detection

VISION_PORT = 23333 # Athena vision port
ROBOT_ID = 6

class VisionModule:
    def __init__(self, VISION_PORT=23333, SENDERIP = '0.0.0.0'):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1) 
        self.sock.bind((SENDERIP,VISION_PORT))

        self.robot_info = [0, 0, 0, 0, 0, 0]
        self.ball_info = [0, 0, 0, 0]

    def receive(self):
        data, addr = self.sock.recvfrom(65535)
        sleep(0.001) # wait for reading
        return data

    def get_info(self, ROBOT_ID):
        data = self.receive()
        
        package = detection.Vision_DetectionFrame()
        package.ParseFromString(data)
        print(package)
        robots = package.robots_blue # repeat
        for robot in robots:
            if robot.robot_id == ROBOT_ID:
                self.robot_info[0] = robot.x/1000.0
                self.robot_info[1] = robot.y/1000.0
                self.robot_info[2] = robot.orientation
                self.robot_info[3] = robot.vel_x/1000.0
                self.robot_info[4] = robot.vel_y/1000.0
                self.robot_info[5] = robot.rotate_vel
                #print('Robot', robot.confidence)
        
        ball = package.balls # not repeat
        self.ball_info[0] = ball.x/1000.0
        self.ball_info[1] = ball.y/1000.0
        self.ball_info[2] = ball.vel_x/1000.0
        self.ball_info[3] = ball.vel_y/1000.0
        #print('Ball', ball.confidence)
if __name__ == '__main__':
    vision = VisionModule(VISION_PORT)
    while True:
        vision.get_info(ROBOT_ID)
        print(vision.robot_info)
        print(vision.ball_info)
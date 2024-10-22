import numpy as np
from scipy.spatial import distance_matrix
from tbkpy.socket.udp import UDPMultiCastReceiver, UDPSender
from tbkpy.socket.plugins import ProtobufParser
from tzcp.ssl.rocos.zss_vision_detection_pb2 import Vision_DetectionFrame
from tzcp.ssl.rocos.zss_debug_pb2 import Debug_Heatmap, Debug_Msgs, Debug_Msg
from tzcp.ssl.rocos.zss_geometry_pb2 import Point
from threading import Event
import time
import tbkpy._core as tbkpy
import pickle
tbkpy.init("test_ping")
puber = tbkpy.Publisher("messi_Puber","ping")
HEATMAP_COLORS = ["gray", "rainbow", "jet", "PiYG", "cool", "coolwarm", "seismic", "default"]

class DEF:
    HEATMAP = "coolwarm"
    FLX = 9000
    FLY = 6000
    PLX = 1000
    PLY = 2000
    ROBOT_RADIUS = 90
    GL = 1000
    STEP = 80
    GOAL = np.array((FLX/2, 0))

    MAX_ACC = 4000
    MAX_VEL = 3500
    MAX_BALL_VEL = 6000

    POINTS_MAX_NUM = 2000

def get_points_and_sizes(robot):
    points = np.empty((0,2))
    sizes = np.empty(0)
    # resolution of heatmap
    res = DEF.STEP 
    R = DEF.ROBOT_RADIUS

    # represent points from unimportant to important
    # points in back field
    res = 3*DEF.STEP
    p = np.mgrid[-DEF.FLX/2-R:0:res, -DEF.FLY/2:DEF.FLY/2:res].reshape(2, -1).T
    points, sizes = np.concatenate((points, p)), np.concatenate((sizes, np.ones(len(p))*res))
    # points in front field
    res = DEF.STEP*0.8
    p = np.mgrid[0:DEF.FLX/2:res, -DEF.FLY/2:DEF.FLY/2:res].reshape(2, -1).T
    points, sizes = np.concatenate((points, p)), np.concatenate((sizes, np.ones(len(p))*res))
    # points around robot
    res = DEF.STEP*0.3
    dl = DEF.FLX/10
    p = np.mgrid[-dl:dl:res, -dl:dl:res].reshape(2, -1).T
    circle = np.linalg.norm(p, axis=1) < 1.0*dl
    p = p[circle]
    for r in robot:
        # points, sizes = np.concatenate((points, p+r)), np.concatenate((sizes, np.ones(len(p))*res))
        pass

    in_their_penalty = np.logical_and(points[:,0] > DEF.FLX/2 - DEF.PLX - R, np.abs(points[:,1]) < DEF.PLY/2+R)
    in_our_penalty = np.logical_and(points[:,0] < -DEF.FLX/2 + DEF.PLX + R, np.abs(points[:,1]) < DEF.PLY/2+R)
    out_of_field = np.logical_or(np.abs(points[:,0]) > DEF.FLX/2-R, np.abs(points[:,1]) > DEF.FLY/2-R)
    ban = np.logical_or(np.logical_or(in_their_penalty, in_our_penalty), out_of_field)
    points = points[~ban]
    sizes = sizes[~ban]
    # print("points", len(points))
    return points, sizes

def dist(pos:np.ndarray, target:np.ndarray):
    return np.linalg.norm(pos - target, axis=1)

def norm(v:np.ndarray):
    return (v-np.min(v))/(np.max(v)-np.min(v))

def max_run_dist(t):
    h = np.minimum(t/2*DEF.MAX_ACC, DEF.MAX_VEL)
    w1 = np.maximum(t - 2*h/DEF.MAX_ACC, 0)
    return 0.5*h*(w1 + t)

def calculate_interception(points, ball, robot, enemy):
    lines = points - ball
    enemy_relative = enemy - ball
    angles = np.arctan2(lines[:,1], lines[:,0])
    matrixs = np.array([[np.cos(angles), -np.sin(angles)], [np.sin(angles), np.cos(angles)]]).transpose(2,0,1)
    enemy_rotate = np.dot(enemy_relative, matrixs)
    projection_x = enemy_rotate[...,0]
    projection_y = np.abs(enemy_rotate[...,1])
    dist_mx = distance_matrix(enemy_relative, lines)
    dist = np.linalg.norm(lines, axis=1)
    ban1 = projection_x < 0
    ban2 = projection_x > dist
    projection_y[ban1] = np.linalg.norm(enemy_relative, axis=1)[np.argwhere(ban1)[:,0]]
    projection_y[ban2] = dist_mx[ban2]
    value = -4*(1/np.clip(projection_y/(max_run_dist(dist / DEF.MAX_BALL_VEL)+DEF.ROBOT_RADIUS), 0.5, 1.5) - 1/1.5)
    return value.min(axis=0)

def calculate_shoot_angle(points, ball, robot, enemy):
    pass
class Messi:
    def __init__(self):
        self.signal = Event()
        self.receiver = UDPMultiCastReceiver("233.233.233.233", 41001, callback=self.callback, plugin = ProtobufParser(Vision_DetectionFrame))
        self.sender = UDPSender(plugin=ProtobufParser(Debug_Heatmap))
        self.heatmap_endpoint = ("127.0.0.1", 20003)
        self.debug_endpoint = ("127.0.0.1", 20001)
        self.heatmap_name = DEF.HEATMAP
        self.step = 1
    def callback(self, recv):
        self.vision = recv[0]
        self.signal.set()
    def test_heatmap(self):
        self.signal.wait()
        heatmap = Debug_Heatmap()
        # random one
        heatmap.cmap = HEATMAP_COLORS[self.heatmap_index]
        self.heatmap_index = (self.heatmap_index + 1) % len(HEATMAP_COLORS)
        for i in range(91):
            heat = Debug_Heatmap.HeatDiscrete()
            y = np.linspace(-3000, 3000, 61)
            heat.x.extend([-4500+i*100]*len(y))
            heat.y.extend(y)
            heat.value = float(i/90)
            heat.size = 100 ## mm
            heatmap.discrete.append(heat)
        print("pb_size", heatmap.ByteSize())
        self.sender.send(heatmap, self.heatmap_endpoint)

        debug = Debug_Msgs()

        for robot in self.vision.robots_blue:
            msg = Debug_Msg()
            msg.type = Debug_Msg.Debug_Type.TEXT
            msg.text.text = heatmap.cmap
            msg.text.pos.x = robot.x
            msg.text.pos.y = robot.y
            msg.text.size = 120
            msg.text.weight = 120
            debug.msgs.append(msg)
        self.sender.send(debug, self.debug_endpoint)

        self.signal.clear()
    def calculate(self):
        self.signal.wait()
        starttime = time.time()
        robot = np.array([(robot.x, robot.y) for robot in self.vision.robots_blue])
        enemy = np.array([(robot.x, robot.y) for robot in self.vision.robots_yellow])
        ball = np.array([self.vision.balls.x, self.vision.balls.y])

        points, sizes = get_points_and_sizes(robot)
        value = np.zeros(len(points))

        # near to goal
        value += 1.0*-np.clip(dist(points, DEF.GOAL),2000, 5000) / 3000
        # near to robot
        value += -0.5*np.clip(distance_matrix(points, robot).min(axis=1) / 3000, 0.3, 1.0)
        # far from enemy
        value += 2*(np.clip(distance_matrix(points, enemy).min(axis=1) / 3000, 0.0, 0.3))
        # dist to ball
        value += -1/np.clip(dist(points, ball) / 2000, 0.2, 1.0)
        # intercept by enemy
        value += 0.7*calculate_interception(points, ball, robot, enemy)
        # value += 0.7*calculate_shoot_angle(points, ball, robot, enemy)
        
        best_point = list(points[np.argmax(value)])
        puber.publish(f"{best_point[0]}, {best_point[1]}")
        self.send_heatmap(points, value, sizes)
        self.signal.clear()
        # print("time", time.time()-starttime)

    def histogram_equalization(self, values):
        hist, bins = np.histogram(values, bins=256, range=(0,1))
        cdf = hist.cumsum()
        cdf = (cdf - cdf.min()) / (cdf.max() - cdf.min())
        values = np.interp(values, bins[:-1], cdf)
        return values
    def send_heatmap(self, points, values, size=[DEF.STEP]):
        if len(values) > DEF.POINTS_MAX_NUM:
            index = np.argsort(-values)[:DEF.POINTS_MAX_NUM]
            if len(size) == len(values):
                size = size[index]
            values = values[index]
            points = points[index]
        values = norm(values)
        values = self.histogram_equalization(values)
        heatmap = Debug_Heatmap()
        heatmap.cmap = self.heatmap_name
        heat = Debug_Heatmap.Heat()
        heat.x.extend(points[:,0])
        heat.y.extend(points[:,1])
        heat.value.extend(values)
        heat.size.extend(size)
        heatmap.heat.append(heat)
        # heatmap.shape = Debug_Heatmap.Shape.CIRCLE
        self.sender.send(heatmap, self.heatmap_endpoint)

def main():
    import time
    messi = Messi()
    def changeCMAP():
        while True:
            time.sleep(1)
            messi.heatmap_name = HEATMAP_COLORS[np.random.randint(0, len(HEATMAP_COLORS))]
    import threading
    # threading.Thread(target=changeCMAP).start()
    while True:
        time.sleep(0.0001)
        messi.calculate()
        # messi.test_heatmap()

def get_cmap(cmap_name):
    import matplotlib.cm as cm
    import matplotlib.pyplot as plt
    import numpy as np
    value = np.linspace(0, 1, 4)
    colors = cm.get_cmap(cmap_name)(value)
    # get r g b a
    r,g,b,a = colors[:,0], colors[:,1], colors[:,2], colors[:,3]
    cc = {"r": r, "g": g, "b": b}
    for color, color_value in cc.items():
        output = "{"
        for i, cv in enumerate(color_value):
            output += f"{{ {value[i]:.1f}f, {cv:.2f}f}},"
        output += "}"
        print(f"{color} = segValue(v, {output});")
    # print([f"{c} = segValue(v, {{ {} }});" for c,v in cc.items()])
    plt.plot(value, r, 'r')
    plt.plot(value, g, 'g')
    plt.plot(value, b, 'b')
    # plt.plot(value, a, 'k')
    plt.show()

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 2 and sys.argv[1] == "cmap":
        get_cmap(sys.argv[2])
        exit(0)
    main()
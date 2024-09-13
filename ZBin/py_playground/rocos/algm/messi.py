import numpy as np
from tbkpy.socket.udp import UDPMultiCastReceiver, UDPSender
from tbkpy.socket.plugins import ProtobufParser
from tzcp.ssl.rocos.zss_vision_detection_pb2 import Vision_DetectionFrame
from tzcp.ssl.rocos.zss_debug_pb2 import Debug_Heatmap, Debug_Msgs, Debug_Msg
from tzcp.ssl.rocos.zss_geometry_pb2 import Point
from threading import Event

HEATMAP_COLORS = ["gray", "rainbow", "jet", "PiYG", "cool", "coolwarm", "seismic", "default"]

class Messi:
    def __init__(self):
        self.signal = Event()
        self.receiver = UDPMultiCastReceiver("233.233.233.233", 23333, callback=self.callback, plugin = ProtobufParser(Vision_DetectionFrame))
        self.sender = UDPSender(plugin=ProtobufParser(Debug_Heatmap))
        self.heatmap_endpoint = ("127.0.0.1", 20003)
        self.debug_endpoint = ("127.0.0.1", 20001)

        self.heatmap_index = 0
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
            heat = Debug_Heatmap.Heat()
            y = np.linspace(-3000, 3000, 61)
            heat.x.extend([-4500+i*100]*len(y))
            heat.y.extend(y)
            heat.value = float(i/90)
            heat.size = 100 ## mm
            heatmap.points.append(heat)
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

def main():
    import time
    messi = Messi()
    while True:
        time.sleep(1)
        messi.test_heatmap()

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
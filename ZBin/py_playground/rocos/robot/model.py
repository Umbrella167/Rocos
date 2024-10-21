import numpy as np
import itertools as it
class RobotConfig:
    max_speed = 3.4 # m/s
    mass = 2.2 # kg
    degree1 = 45
    degree2 = 45
    wheels_degree = np.array([degree1, 180-degree2, 180+degree2, 360-degree1])

class OmniWheel:
    class Config:
        power = 30 # w
        radius = 58/2.0 # mm
        gear_ratio = 3.18
        stall_torque = 0.15 # Nm
        nomimal_coef = 280 # rpm * Nm
        degree = 45  # degree
    def __init__(self, degree):
        self._c = self.Config()
        self._c.degree = degree
        max_rpm = self.__speed2rpm(RobotConfig.max_speed*np.sin(self._c.degree/180*np.pi))
        print("max_rpm : ",max_rpm)
        self.friction_torque = self._c.nomimal_coef / max_rpm
        self.friction_ratio = self.friction_torque / max_rpm
    
    def getAcc(self, speed): # return min and max acceleration
        # from m/s -> rpm
        rpm = self.__speed2rpm(speed)
        # from rpm -> Nm
        torque = np.clip(self._c.nomimal_coef / rpm, -self._c.stall_torque, self._c.stall_torque)
        # from Nm -> force (N)
        friction_torque = -self.friction_ratio * rpm
        mm_torque = np.stack((torque, -torque), axis=-1)
        mm_friction_torque = np.stack((friction_torque, friction_torque), axis=-1)
        force = (mm_friction_torque + mm_torque) / (self._c.radius / 1000) * self._c.gear_ratio
        return np.sort(force, axis=-1) / RobotConfig.mass

    def __speed2rpm(self, speed: float):
        return speed * self._c.gear_ratio * 1000 / self._c.radius / (2*np.pi) * 60

class Robot:
    def __init__(self):
        self.wheels = [OmniWheel(degree) for degree in RobotConfig.wheels_degree]
        self.wheels_angle = np.array([wheel._c.degree / 180 * np.pi for wheel in self.wheels])
        self.wheels_matrix = np.array([[-np.sin(angle), np.cos(angle)] for angle in self.wheels_angle])
        self.wheel_ratio = np.average([-np.sin(self.wheels_angle[-1]),np.cos(self.wheels_angle[-1])])

        self.simple_mx = self.wheel_ratio * 2 * np.array([[-1,1],[-1,-1]])
        self.simple_mx_inv = np.linalg.inv(self.simple_mx)

        self.acc_limit = np.zeros((2,2)) # x min max, y min max (not in robot coordinate, use wheel coordinate - wheel1 for x, wheel2 for y)

    def updateSpeed(self, speed):
        assert(speed.shape[-1] == 2)
        speed_wheel = (speed @ self.wheels_matrix.T)
        acc_wheel = np.stack([wheel.getAcc(speed_wheel[...,i]) for i, wheel in enumerate(self.wheels)],axis=-2)
        print("acc_wheel", acc_wheel, acc_wheel.shape)
        self.acc_limit = acc_wheel[:2] * 2
        print("acc_limit : ",self.acc_limit)

    def getAcc(self, _theta, speed = None): # return for polar coordinate
        theta = np.array(_theta) - 3*np.pi/4
        if speed is not None:
            self.updateSpeed(speed)
        acc = np.copy(self.acc_limit)
        acc[:,0] = np.minimum(acc[:,0],-0.0001)
        acc[:,1] = np.maximum(acc[:,1],0.0001)
        r = 1 / np.array([np.cos(theta), np.cos(theta), np.sin(theta), np.sin(theta)]).T
        res = r * acc.reshape(-1)
        res[res<0] = np.Inf
        res = np.min(res,axis=-1)
        return res

    def old_getAcc(self, speed): # [..., 2] -> [..., 2]
        assert(speed.shape[-1] == 2)
        # get wheels speed
        speed_wheel = (speed @ self.wheels_matrix.T)
        # get wheels acceleration
        acc_wheel = np.stack([wheel.getAcc(speed_wheel[...,i]) for i, wheel in enumerate(self.wheels)],axis=-2)

        ## method 1 for individual wheel acceleration
        # all_acc = np.stack(np.meshgrid(*[np.linspace(acc_wheel[...,i,0],acc_wheel[...,i,1],2) for i in range(len(self.wheels))]),axis=-1)
        ## method 2 for simplified wheel acceleration
        # index1 = np.array([np.hstack((np.array(r),1-np.array(r))) for r in it.product([0,1],repeat=2)])
        # assert(index1.shape[1] == acc_wheel.shape[-2])
        # index0 = np.tile(np.arange(acc_wheel.shape[0]),index1.shape[0])
        # all_acc = acc_wheel[index0,index1.flatten()]
        # print(f"accs : {all_acc.reshape(-1,4)}\nmx : {self.wheels_matrix}")
        # res = all_acc.reshape(-1,4) @ self.wheels_matrix
        # print(f"res : {res}")

        ## method 3 for more simplified wheel acceleration
        index1 = np.array([[0,0],[0,1],[1,0],[1,1]]).reshape(-1)
        index0 = np.array([[0,1]]*4).reshape(-1)
        all_acc = acc_wheel[index0,index1].reshape(-1,2)
        
        res = all_acc @ self.simple_mx

        x0,x1 = acc_wheel[0]
        y0,y1 = acc_wheel[1]
        center = np.array([(x0+x1)/2,(y0+y1)/2])
        x = (x0-x1)/2
        y = (y0-y1)/2
        bias = center.reshape(1,2) @ self.simple_mx
        a0 = np.array([x,0]) @ self.simple_mx
        a1 = np.array([0,y]) @ self.simple_mx
        return res, (bias,a0,a1)


if __name__ == "__main__":
    def testWheelAcc():
        degree = 45
        wheel = OmniWheel(degree)
        max_wheel_speed = RobotConfig.max_speed / np.sin(degree/180*np.pi)
        speed = np.linspace(-max_wheel_speed,max_wheel_speed,100)
        acc1, acc2 = wheel.getAcc(speed)

        import matplotlib.pyplot as plt
        plt.plot(speed, acc1, 'r')
        plt.plot(speed, acc2, 'b')
        plt.plot(speed, acc1 * 0)
        plt.xlabel("Speed (m/s)")
        plt.ylabel("Acceleration (m/s^2)")
        plt.title("Acceleration vs Speed")
        plt.show()

    def testRobotAcc():
        robot = Robot()
        # speed = np.array([[0,s] for s in np.linspace(0.01,RobotConfig.max_speed,3)])

        def getAcc(speed):
            accs, infos = robot.old_getAcc(speed)
            theta = np.linspace(0,2*np.pi,200)
            accs2 = robot.getAcc(theta,speed)
            count = accs.shape[0]
            coods = it.combinations(range(count),2)
            coods = (np.array(list(coods)).reshape(-1))
            return accs, coods, (theta, accs2)

        import matplotlib.pyplot as plt
        from matplotlib.patches import Wedge
        from matplotlib.widgets import Slider

        fig, ax = plt.subplots(figsize=(12, 12))
        cood_lim = 26
        ax.set_xlim(-cood_lim,cood_lim)
        ax.set_ylim(-cood_lim,cood_lim)
        acc, coods, others = getAcc(np.array([-0.1,-0.1]))
        line, = ax.plot(acc[coods,0], acc[coods,1], 'g')
        # draw circle

        fig.subplots_adjust(left=0.1, bottom=0.1)
        x_slider = Slider(plt.axes([0.1, 0.04, 0.8, 0.02]), 'X', -RobotConfig.max_speed, RobotConfig.max_speed, valinit=0.01)
        y_slider = Slider(plt.axes([0.1, 0.01, 0.8, 0.02]), 'Y', -RobotConfig.max_speed, RobotConfig.max_speed, valinit=0.01)
        def update(v):
            def drawRobot(ax):
                carpet_circle = plt.Circle((0,0), 15, fill=True, color='grey')
                ax.add_artist(carpet_circle)
                current_acc_circle = plt.Circle((0,0), 6, fill=True)
                ax.add_artist(current_acc_circle)

                robot_theta = 45
                robot = Wedge((0,0), 3, robot_theta, 360-robot_theta, fill=True, color='grey')
                ax.add_artist(robot)

                arrow = ax.arrow(0,0,x_slider.val*3,y_slider.val*3, head_width=2, head_length=2, fc='k', ec='k')
                ax.add_artist(arrow)
            ax.clear()
            ax.set_xlim(-cood_lim,cood_lim)
            ax.set_ylim(-cood_lim,cood_lim)
            drawRobot(ax)
            speed = np.array([x_slider.val, y_slider.val])
            acc,coods,(theta, r) = getAcc(speed)
            ax.plot(acc[coods,0], acc[coods,1], 'g')
            ax.plot(r*np.cos(theta), r*np.sin(theta), 'r')
            ax.plot(0,0,'ro')

        x_slider.on_changed(update)
        y_slider.on_changed(update)
        plt.show()

    # testWheelAcc()
    testRobotAcc()
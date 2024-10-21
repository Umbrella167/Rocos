import matplotlib.pyplot as plt
import casadi as ca

opti = ca.Opti()
x = opti.variable()
y = opti.variable()
opti.minimize((1-x)**2 + (y-x**2)**2)
opti.solver('ipopt')
sol = opti.solve()

print(f"sol : {sol.value(x),sol.value(y)}, iter : {sol.stats()['iter_count']}")

plt.plot(sol.value(x),sol.value(y),'ro')
plt.show()
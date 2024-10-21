import numpy as np
import casadi as ca
import do_mpc

model = do_mpc.model.Model('continuous') # either 'discrete' or 'continuous'

"""
model variables : 
| Long name             | Short name | Remark   |
|-----------------------|------------|----------|
| states                | _x         | Required |
| inputs                | _u         | Required |
| algebraic             | _z         | Optional |
| parameters            | _p         | Optional |
| timevarying_parameter | _tvp       | Optional |
"""

m0 = 0.6  # kg, mass of the cart
m1 = 0.2  # kg, mass of the first rod
m2 = 0.2  # kg, mass of the second rod
L1 = 0.5  # m,  length of the first rod
L2 = 0.5  # m,  length of the second rod

g = 9.80665 # m/s^2, Gravity

# -------------------
l1 = L1/2 # m,
l2 = L2/2 # m,
J1 = (m1 * l1**2) / 3   # Inertia
J2 = (m2 * l2**2) / 3   # Inertia

h1 = m0 + m1 + m2
h2 = m1*l1 + m2*L1
h3 = m2*l2
h4 = m1*l1**2 + m2*L1**2 + J1
h5 = m2*l2*L1
h6 = m2*l2**2 + J2
h7 = (m1*l1 + m2*L1) * g
h8 = m2*l2*g

# -----------------------
pos = model.set_variable('_x',  'pos')
theta = model.set_variable('_x',  'theta', (2,1))
dpos = model.set_variable('_x',  'dpos')
dtheta = model.set_variable('_x',  'dtheta', (2,1))

u = model.set_variable('_u',  'force')

ddpos = model.set_variable('_z', 'ddpos')
ddtheta = model.set_variable('_z', 'ddtheta', (2,1))

model.set_rhs('pos', dpos)
model.set_rhs('theta', dtheta)
model.set_rhs('dpos', ddpos)
model.set_rhs('dtheta', ddtheta)

euler_lagrange = ca.vertcat(
        # 1
        h1*ddpos+h2*ddtheta[0]*ca.cos(theta[0])+h3*ddtheta[1]*ca.cos(theta[1])
        - (h2*dtheta[0]**2*ca.sin(theta[0]) + h3*dtheta[1]**2*ca.sin(theta[1]) + u),
        # 2
        h2*ca.cos(theta[0])*ddpos + h4*ddtheta[0] + h5*ca.cos(theta[0]-theta[1])*ddtheta[1]
        - (h7*ca.sin(theta[0]) - h5*dtheta[1]**2*ca.sin(theta[0]-theta[1])),
        # 3
        h3*ca.cos(theta[1])*ddpos + h5*ca.cos(theta[0]-theta[1])*ddtheta[0] + h6*ddtheta[1]
        - (h5*dtheta[0]**2*ca.sin(theta[0]-theta[1]) + h8*ca.sin(theta[1]))
    )

model.set_alg('euler_lagrange', euler_lagrange)

E_kin_cart = 1 / 2 * m0 * dpos**2
E_kin_p1 = 1 / 2 * m1 * (
    (dpos + l1 * dtheta[0] * ca.cos(theta[0]))**2 +
    (l1 * dtheta[0] * ca.sin(theta[0]))**2) + 1 / 2 * J1 * dtheta[0]**2
E_kin_p2 = 1 / 2 * m2 * (
    (dpos + L1 * dtheta[0] * ca.cos(theta[0]) + l2 * dtheta[1] * ca.cos(theta[1]))**2 +
    (L1 * dtheta[0] * ca.sin(theta[0]) + l2 * dtheta[1] * ca.sin(theta[1]))**
    2) + 1 / 2 * J2 * dtheta[0]**2

E_kin = E_kin_cart + E_kin_p1 + E_kin_p2

E_pot = m1 * g * l1 * ca.cos(
theta[0]) + m2 * g * (L1 * ca.cos(theta[0]) +
                            l2 * ca.cos(theta[1]))

model.set_expression('E_kin', E_kin)
model.set_expression('E_pot', E_pot)

model.setup()

mpc = do_mpc.controller.MPC(model)

setup_mpc = {
    'n_horizon': 100,
    'n_robust': 0,
    'open_loop': 0,
    't_step': 0.04,
    'state_discretization': 'collocation',
    'collocation_type': 'radau',
    'collocation_deg': 3,
    'collocation_ni': 1,
    'store_full_solution': True,
    # Use MA27 linear solver in ipopt for faster calculations:
    'nlpsol_opts': {'ipopt.linear_solver': 'mumps'}
}
mpc.set_param(**setup_mpc)

mterm = model.aux['E_kin'] - model.aux['E_pot'] # terminal cost
lterm = model.aux['E_kin'] - model.aux['E_pot'] # stage cost

mpc.set_objective(mterm=mterm, lterm=lterm)
# Input force is implicitly restricted through the objective.
mpc.set_rterm(force=0.1)

mpc.bounds['lower','_u','force'] = -4
mpc.bounds['upper','_u','force'] = 4

mpc.setup()


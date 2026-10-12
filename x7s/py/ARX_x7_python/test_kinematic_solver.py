import bimanual
import numpy as np
np.set_printoptions(suppress=True)
np.set_printoptions(precision=2)

if __name__ == "__main__":
	print(bimanual.left_arm_forward_kinematics(np.array([1.0,0.0,0.0,1.0,0.0,0.0,0.0])))
	print(bimanual.left_arm_inverse_kinematics(np.array([-0.19,  0.0, 0.11, -0.0,  0.0, -0.0])))
	print(bimanual.right_arm_forward_kinematics(np.array([1.0,1.0,0.0,0.0,0.0,0.0,1.0])))
	print(bimanual.right_arm_inverse_kinematics(np.array([0.0,0.1,0.1,0.0,0.0,0.0])))

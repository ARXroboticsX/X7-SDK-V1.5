from bimanual import SingleArm
from typing import Dict, Any
import numpy as np

def test_single_arm(single_arm: SingleArm, duration: float = 10.0, dt: float = 0.01):
    #single_arm.go_home()
    while(1):

        print(single_arm.get_ee_pose())
        print(single_arm.get_joint_positions())
        
        positions = [0.5, 1.0, -0.1, 0.1, 0, 0, 0]  # 指定每个关节的位置
        joint_names = ["joint1", "joint2", "joint3","joint4", "joint5", "joint6","joint7"]  # 对应关节的名称

        single_arm.set_joint_positions(positions=positions, joint_names=joint_names)
        single_arm.set_catch_pos(1)

if __name__ == "__main__":
    arm_config: Dict[str, Any] = {
        "can_port": "can1",
        "type": 0,
    }
    single_arm = SingleArm(arm_config)
    test_single_arm(single_arm)
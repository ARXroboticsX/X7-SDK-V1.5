from bimanual import SingleArm
from typing import Dict, Any
import numpy as np

def test_single_arm(single_arm0: SingleArm, single_arm1: SingleArm):
    #single_arm.go_home()
    while(1):

        # 位置控制
        l_xyzrpy = np.array([0.0,  0.1, 0.0, 0.0, 0.0, 0.0])  # x, y, z 位置
        r_xyzrpy = np.array([0.0, -0.1, 0.0, 0.0, 0.0, 0.0])  # x, y, z 位置

        success = single_arm0.set_ee_pose_xyzrpy(l_xyzrpy)
        success = single_arm1.set_ee_pose_xyzrpy(r_xyzrpy)

        single_arm0.set_catch_pos(1)
        single_arm1.set_catch_pos(1)

        # 关节控制
        # positions = [0.5, 0, -0.1, 0.1, 0, 0, 0]  # 指定每个关节的位置
        # joint_names = ["joint1", "joint2", "joint3","joint4", "joint5", "joint6","joint7"]  # 对应关节的名称
        # positions2 = [0.5, 0, -0.1, 0.1, 0, 0, 0]  # 指定每个关节的位置
        # joint_names2 = ["joint1", "joint2", "joint3","joint4", "joint5", "joint6","joint7"]  # 对应关节的名称
        # single_arm0.set_joint_positions(positions=positions, joint_names=joint_names)
        # single_arm0.set_catch_pos(1)
        # single_arm1.set_joint_positions(positions=positions2, joint_names=joint_names2)
        # single_arm1.set_catch_pos(1)


  
        print(single_arm0.get_ee_pose())
        print(single_arm0.get_joint_positions())


if __name__ == "__main__":
    arm_config_0: Dict[str, Any] = {
        "can_port": "can0",
        "type": 2,
        # Add necessary configuration parameters for the left arm
    }

    arm_config_1: Dict[str, Any] = {
        "can_port": "can1",
        "type": 3,
        # Add necessary configuration parameters for the left arm
    }
    single_arm0 = SingleArm(arm_config_0)
    single_arm1 = SingleArm(arm_config_1)
    test_single_arm(single_arm0,single_arm1)

import kinematic_solver as solver
import numpy as np
import os

from .single_arm import ARM_URDF_MAP

# 按 type 缓存 KinematicSolver 实例，避免左右臂/新旧型号共用同一个
_instances = {}
current_dir = os.path.dirname(os.path.abspath(__file__))


def _get_solver(type=0):
    global _instances
    if type not in _instances:
        urdf_name = ARM_URDF_MAP.get(type)
        if urdf_name is None:
            raise ValueError(
                f"Unknown arm type {type!r}, valid types are {list(ARM_URDF_MAP.keys())}"
            )
        urdf_path = os.path.join(current_dir, urdf_name)
        _instances[type] = solver.KinematicSolver(urdf_path)
    return _instances[type]


def left_arm_forward_kinematics(joint_angles, type=0):
    return _get_solver(type).forward_kinematics(joint_angles)


def left_arm_inverse_kinematics(target_pose, type=0):
    return _get_solver(type).inverse_kinematics(target_pose)


def right_arm_forward_kinematics(joint_angles, type=0):
    return _get_solver(type).forward_kinematics(joint_angles)


def right_arm_inverse_kinematics(target_pose, type=0):
    return _get_solver(type).inverse_kinematics(target_pose)

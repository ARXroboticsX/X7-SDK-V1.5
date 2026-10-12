#!/usr/bin/env python3
"""
ARX LIFT 2026 底盘/升降 API 示例
"""

import time
from liftlib import InterfacesPy, RobotType


def main():
    # 配置
    CAN_ROBOT = 'can5'  # 机器人CAN接口
    ROBOT_TYPE = RobotType.X72026  # 带头部的 X7 用 X72026; 无头部的 LIFT: 升降反装用 LIFT2026_18

    print("正在初始化机器人...")

    try:
        # 初始化机器人
        robot = InterfacesPy(CAN_ROBOT, ROBOT_TYPE)
        print(f"✓ 机器人已连接 (CAN: {CAN_ROBOT})")

        # 控制参数
        robot.loop()
        lift_height = robot.get_height()  # 启动时的升降高度 (增量式基准, 无需复位)
        set_height_cmd = 0.0              



        # 控制循环
        while True:


            # 设置升降高度  (0,0.38)!!!!!!!
            # 此处为了保持上电后无需复位，设置增量值
            set_height_cmd=0     #距启动前，增加的高度值
            set_lift_height=lift_height+set_height_cmd
            robot.set_height(set_lift_height)


            # 底盘速度，设置模式为1  x，y，z，mode  eg:(0.1,0,0,1)
            robot.set_chassis_cmd(0,0,0,1)

            
            # 轮速控制，设置模式为3
            # robot.set_chassis_cmd(0,0,0,3)
            # robot.set_wheel_vel(0,0,0,0)


            # 头部角度 rad (仅 X7 机型, LIFT 机型为空操作): 自动钳制软限位, 限速转动
            robot.set_head_yaw(0.2) 
            robot.set_head_pitch(-0.2)

            # 获取高度值
            get_chassis_height=robot.get_height()

            # 轮速获取
            get_wheel_vel=robot.get_wheel_vel()
            
            # 头部姿态获取
            get_head_pos=robot.get_head_pos()

            print(f"当前高度: {get_chassis_height}")
            print(f"轮速: {get_wheel_vel}")
            # print(f"头部角度: {get_head_pos}")



            # 执行控制循环
            robot.loop()
            time.sleep(0.0025)

    except KeyboardInterrupt:
        print("\n\n正在退出...")
    except Exception as e:
        print(f"\n错误: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0


if __name__ == '__main__':
    import sys
    sys.exit(main())

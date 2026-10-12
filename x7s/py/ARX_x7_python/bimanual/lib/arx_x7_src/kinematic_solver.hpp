#include <memory>
#include <string>

namespace arx {
class KinematicSolver {
public:
  KinematicSolver(const std::string &urdf_path);
  ~KinematicSolver();
  void computeForwardKinematics(double joint_angles[7],
                                double end_effector_pose[6]);
  void computeInverseKinematics(double target_pose[6], double joint_angles[7]);

private:
  class impl;
  std::unique_ptr<impl> pimpl;
};
} // namespace arx
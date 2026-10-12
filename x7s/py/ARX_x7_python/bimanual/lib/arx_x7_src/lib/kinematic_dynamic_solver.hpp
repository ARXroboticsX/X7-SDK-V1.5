#pragma once

#include <kdl_parser/kdl_parser.hpp>
#include <kdl/chain.hpp>
#include <kdl/tree.hpp>
#include <kdl/chainfksolver.hpp>
#include <kdl/chainiksolver.hpp>
#include <kdl/chainiksolverpos_lma.hpp>
#include <kdl/chainiksolverpos_nr.hpp>
#include <kdl/chainiksolverpos_nr_jl.hpp>
#include <kdl/chainfksolverpos_recursive.hpp>
#include <kdl/chainfksolvervel_recursive.hpp>
#include <kdl/chainiksolvervel_pinv.hpp>
#include <kdl/chaindynparam.hpp>


namespace arx
{
    class KinematicDynamicSolver 
    {
    public:
        KinematicDynamicSolver(const std::string& urdf_path,const std::string& base_link, const std::string& end_effector_link);

        KDL::Frame computeForwardKinematics(const KDL::JntArray& joint_angles);
        KDL::JntArray computeInverseKinematics(KDL::Frame& target_pose);
        KDL::JntArray computeGravityCompensationTorque(const KDL::JntArray& joint_angles);
        KDL::Frame init_frame_;
    private:
        KDL::Tree tree_;
        KDL::Chain chain_;
        std::unique_ptr<KDL::ChainFkSolverPos_recursive> fk_solver_;
        std::unique_ptr<KDL::ChainIkSolverPos_LMA> ik_solver_;
        std::unique_ptr<KDL::ChainDynParam> dyn_param_solver_;
        KDL::Vector gravity_;
    };
} // namespace arx

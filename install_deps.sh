#!/usr/bin/env bash
# X7 SDK 依赖库一键安装 (Ubuntu 24.04 x86_64 / 系统 Python 3.12)
#
# 用法: ./install_deps.sh [--rebuild-kdl]    (用普通用户运行, 需要时自动 sudo)
#   --rebuild-kdl  即使 /usr/local/lib/libkdl_parser.so 已存在也重新编译安装
#
# 安装内容 (可重复执行, 已装的跳过):
#   编译工具   build-essential cmake python3-dev
#   pybind11   pybind11-dev
#   KDL        liborocos-kdl-dev liburdfdom-dev liburdfdom-headers-dev
#              + kdl_parser (源码克隆到 ~/kdl_parser 编译, 库装到 /usr/local, 无需 ROS)
#   CAN        can-utils (slcand / candump) + python-can >= 4.0
#   Python     numpy
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KDL_HOME="$HOME/kdl_parser"
KDL_REPO="https://github.com/ros/kdl_parser.git"
KDL_TAG="2.11.0"
ARX_LIB="$ROOT/x7s/py/ARX_x7_python/bimanual/lib/arx_x7_src"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

REBUILD_KDL=0
for arg in "$@"; do
    case "$arg" in
        --rebuild-kdl) REBUILD_KDL=1 ;;
        -h|--help)     sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)             die "未知参数: $arg (见 --help)" ;;
    esac
done

SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

# ---------------------------------------------------------------- 环境检查
info "检查系统环境"
[[ "$(uname -m)" == x86_64 ]] || die "预编译库仅支持 x86_64, 当前 $(uname -m)"
command -v apt-get >/dev/null || die "需要 Ubuntu/Debian (apt-get)"
. /etc/os-release
if [[ "${ID:-}" == ubuntu && "${VERSION_ID:-}" == 24.04 ]]; then
    ok "$PRETTY_NAME"
else
    warn "推荐 Ubuntu 24.04, 当前 ${PRETTY_NAME:-未知}, 继续尝试"
fi
[[ -z "${CONDA_PREFIX:-}${VIRTUAL_ENV:-}" ]] \
    || warn "检测到 conda/venv 已激活, SDK 需要系统 Python 3.12, 建议先 deactivate"
PY=/usr/bin/python3
[[ -x "$PY" ]] || PY="$(command -v python3 || true)"
[[ -n "$PY" ]] || die "未找到 python3"
"$PY" -c 'import sys; sys.exit(sys.version_info[:2] != (3, 12))' \
    || die "需要 Python 3.12 (liftlib/*.so 为 cpython-312 预编译), 当前: $("$PY" -V 2>&1) ($PY)"
ok "$("$PY" -V) ($PY)"

# ---------------------------------------------------------------- apt 依赖
info "安装 apt 依赖"
APT_PKGS=(build-essential cmake git python3-dev pybind11-dev
          liborocos-kdl-dev liburdfdom-dev liburdfdom-headers-dev can-utils)
missing=()
for p in "${APT_PKGS[@]}"; do
    dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" || missing+=("$p")
done
# Python 包已能 import (pip 或 apt 装的都行) 就不动
"$PY" -c 'import numpy' 2>/dev/null || missing+=(python3-numpy)
"$PY" -c 'import can, sys; sys.exit(int(can.__version__.split(".")[0]) < 4)' 2>/dev/null \
    || missing+=(python3-can)

if (( ${#missing[@]} )); then
    info "apt 安装: ${missing[*]}"
    $SUDO apt-get update
    $SUDO apt-get install -y "${missing[@]}"
else
    ok "apt 依赖均已安装"
fi

# ---------------------------------------------------------------- kdl_parser
# libarx_x7_src.so 运行时依赖 libkdl_parser.so (RUNPATH=/usr/local/lib), apt 里没有, 需源码编译
info "kdl_parser (源码目录 $KDL_HOME)"
if [[ $REBUILD_KDL == 1 || ! -e /usr/local/lib/libkdl_parser.so ]]; then
    if [[ ! -f "$KDL_HOME/kdl_parser/src/kdl_parser.cpp" ]]; then
        [[ ! -e "$KDL_HOME" ]] || die "$KDL_HOME 已存在但不是 kdl_parser 源码, 请移走后重试"
        git -c advice.detachedHead=false clone --depth 1 -b "$KDL_TAG" "$KDL_REPO" "$KDL_HOME" \
            || die "克隆失败, 检查网络后重试 (git clone -b $KDL_TAG $KDL_REPO $KDL_HOME)"
    fi

    # 上游依赖 ROS 的 urdf / rcutils, 在 standalone/ 里用 urdfdom 和 fprintf 替代, 不改上游源码
    STANDALONE="$KDL_HOME/standalone"
    mkdir -p "$STANDALONE/shim/urdf" "$STANDALONE/shim/rcutils"
    cat > "$STANDALONE/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.10)
project(kdl_parser_standalone CXX)
set(CMAKE_CXX_STANDARD 17)
set(KDL_PARSER_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../kdl_parser)
find_package(orocos_kdl REQUIRED)
find_package(urdfdom REQUIRED)
add_library(kdl_parser SHARED ${KDL_PARSER_DIR}/src/kdl_parser.cpp)
target_compile_definitions(kdl_parser PRIVATE KDL_PARSER_BUILDING_DLL)
target_include_directories(kdl_parser PRIVATE shim PUBLIC ${KDL_PARSER_DIR}/include ${orocos_kdl_INCLUDE_DIRS} ${urdfdom_INCLUDE_DIRS})
target_link_libraries(kdl_parser PUBLIC ${orocos_kdl_LIBRARIES} ${urdfdom_LIBRARIES})
install(TARGETS kdl_parser LIBRARY DESTINATION lib)
install(DIRECTORY ${KDL_PARSER_DIR}/include/kdl_parser DESTINATION include)
EOF
    cat > "$STANDALONE/shim/urdf/model.h" <<'EOF'
// Standalone replacement for ROS urdf::Model, backed directly by urdfdom.
#pragma once
#include <string>
#include <urdf_model/model.h>
#include <urdf_parser/urdf_parser.h>

namespace urdf
{
class Model : public ModelInterface
{
public:
  bool initString(const std::string & xml)
  {
    ModelInterfaceSharedPtr model = parseURDF(xml);
    if (!model) {
      return false;
    }
    static_cast<ModelInterface &>(*this) = *model;
    return true;
  }
};
}  // namespace urdf
EOF
    cat > "$STANDALONE/shim/urdf/urdfdom_compatibility.h" <<'EOF'
// urdfdom_headers >= 1.0 already provides the *SharedPtr typedefs.
#pragma once
#include <urdf_model/types.h>
EOF
    cat > "$STANDALONE/shim/rcutils/logging_macros.h" <<'EOF'
// Standalone replacement for rcutils logging macros.
#pragma once
#include <cstdio>
#define RCUTILS_LOG_ERROR_NAMED(name, ...) (std::fprintf(stderr, "[ERROR] [%s] ", name), std::fprintf(stderr, __VA_ARGS__), std::fputc('\n', stderr))
#define RCUTILS_LOG_WARN_NAMED(name, ...) (std::fprintf(stderr, "[WARN] [%s] ", name), std::fprintf(stderr, __VA_ARGS__), std::fputc('\n', stderr))
#define RCUTILS_LOG_DEBUG_NAMED(name, ...) ((void)0)
EOF

    cmake -S "$STANDALONE" -B "$STANDALONE/build" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local >/dev/null
    cmake --build "$STANDALONE/build" -j"$(nproc)"
    $SUDO cmake --install "$STANDALONE/build"
    $SUDO ldconfig
    ok "已安装 /usr/local/lib/libkdl_parser.so"
else
    ok "/usr/local/lib/libkdl_parser.so 已存在, 跳过 (--rebuild-kdl 可强制重编)"
fi

# ---------------------------------------------------------------- 校验
info "校验"
ok "cmake $(cmake --version | head -1 | awk '{print $3}')"
ok "pybind11 $(dpkg-query -W -f='${Version}' pybind11-dev)"
ok "orocos-kdl $(dpkg-query -W -f='${Version}' liborocos-kdl-dev)"
command -v slcand >/dev/null || die "未找到 slcand (can-utils)"
ok "can-utils $(dpkg-query -W -f='${Version}' can-utils)"
ok "numpy $("$PY" -c 'import numpy; print(numpy.__version__)')"
"$PY" -c 'import can, sys; sys.exit(int(can.__version__.split(".")[0]) < 4)' 2>/dev/null \
    || die "python-can 版本需 >= 4.0, 当前 $("$PY" -c 'import can; print(can.__version__)' 2>&1)"
ok "python-can $("$PY" -c 'import can; print(can.__version__)')"
# 预编译的机械臂库能否找全动态库 (kdl_parser / orocos-kdl / urdfdom ...)
for so in "$ARX_LIB"/libarx_x7_src.so "$ARX_LIB"/libkinematic_dynamic_solver.so; do
    notfound="$(ldd "$so" | grep 'not found' || true)"
    [[ -z "$notfound" ]] || die "$(basename "$so") 缺少动态库:"$'\n'"$notfound"
done
ok "libarx_x7_src.so / libkinematic_dynamic_solver.so 依赖完整"

printf '\n\033[1;32m依赖安装完成\033[0m\n'

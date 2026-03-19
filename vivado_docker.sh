#!/bin/bash

# 1. Grab Display (Default to :0 if unset)
V_DISPLAY="${DISPLAY:-:0}"

# 2. Grant X11 Permission
xhost +local:docker > /dev/null

# 3. Define Paths
PROJECT_DIR=$(pwd)
HOST_TOOLS_DIR="$HOME/dev/fpga/xilinx_tools"

echo "Starting Vivado Container..."
echo "  Display: $V_DISPLAY"
echo "  Project: $PROJECT_DIR"
echo "  Tools  : $HOST_TOOLS_DIR -> /tools/Xilinx"
echo "  Vivado Args: ${@:-[GUI mode]}"

# 4. Run Command
docker run -it --rm \
    --net=host \
    --ipc=host \
    --privileged \
    -e DISPLAY=$V_DISPLAY \
    -e _JAVA_AWT_WM_NONREPARENTING=1 \
    -e QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox" \
    -e QTWEBENGINE_DISABLE_SANDBOX=1 \
    -e LIBGL_ALWAYS_SOFTWARE=1 \
    -e GALLIUM_DRIVER=softpipe \
    -e MESA_GL_VERSION_OVERRIDE=4.5 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev/dri:/dev/dri \
    -v "$HOME/.Xauthority:/home/fpgauser/.Xauthority:rw" \
    -v "$PROJECT_DIR:/home/fpgauser/workspace" \
    -v "$HOST_TOOLS_DIR:/tools/Xilinx:rw" \
    -w /home/fpgauser/workspace \
    --user $(id -u):$(id -g) \
    my-vivado-image:2021.2 \
    /bin/bash -c "source /tools/Xilinx/Vivado/2021.2/settings64.sh && vivado \"\$@\"" -- "$@"

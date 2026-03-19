#!/bin/bash

# Installs Xilinx Vivado 2021.2 inside the Docker container.
# The installer GUI writes to ~/dev/fpga/xilinx_tools on the host via bind mount.
#
# Usage: ./install_vivado.sh [path_to_installer.bin]
#   If no argument given, looks for the installer in ~/dev/fpga/xilinx_tools/

INSTALLER_NAME="Xilinx_Unified_2021.2_1021_0703_Lin64.bin"
HOST_TOOLS_DIR="$HOME/dev/fpga/xilinx_tools"
IMAGE="my-vivado-image:2021.2"

# Resolve installer path
if [ -n "$1" ]; then
    INSTALLER_PATH="$(realpath "$1")"
    INSTALLER_DIR="$(dirname "$INSTALLER_PATH")"
    INSTALLER_BIN="$(basename "$INSTALLER_PATH")"
else
    INSTALLER_DIR="$HOST_TOOLS_DIR"
    INSTALLER_BIN="$INSTALLER_NAME"
    INSTALLER_PATH="$INSTALLER_DIR/$INSTALLER_BIN"
fi

# Validate
if [ ! -f "$INSTALLER_PATH" ]; then
    echo "ERROR: Installer not found at $INSTALLER_PATH"
    echo "Usage: $0 [path_to_installer.bin]"
    exit 1
fi

if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
    echo "ERROR: Docker image '$IMAGE' not found."
    echo "Build it first: cd vivado-vitis && docker build -t $IMAGE ."
    exit 1
fi

# Ensure installer is executable
chmod +x "$INSTALLER_PATH"

# Create tools dir if missing
mkdir -p "$HOST_TOOLS_DIR"

V_DISPLAY="${DISPLAY:-:0}"
xhost +local:docker > /dev/null

echo "=== Vivado 2021.2 Installer ==="
echo "  Installer: $INSTALLER_PATH"
echo "  Install to: $HOST_TOOLS_DIR (mounted as /tools/Xilinx)"
echo ""
echo "IMPORTANT: When the installer asks for the installation path,"
echo "           set it to: /tools/Xilinx"
echo ""

docker run -it --rm \
    --net=host \
    -e DISPLAY="$V_DISPLAY" \
    -e _JAVA_AWT_WM_NONREPARENTING=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "$HOME/.Xauthority:/home/fpgauser/.Xauthority:rw" \
    -v "$INSTALLER_DIR:/installer_source:ro" \
    -v "$HOST_TOOLS_DIR:/tools/Xilinx:rw" \
    --user "$(id -u):$(id -g)" \
    "$IMAGE" \
    /bin/bash -c "echo 'Run: /installer_source/$INSTALLER_BIN' && exec /bin/bash"

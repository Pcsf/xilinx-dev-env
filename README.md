# xilinx-dev-env

Reusable Xilinx Vivado + Vitis AI development environment for Arch Linux.
Designed to run Enterprise Linux tools (Vivado, Vitis) in Docker containers
on a host that doesn't meet Xilinx's OS requirements (e.g., Arch, Hyprland).

## Strategy

The Docker image provides only OS dependencies (Ubuntu 20.04 + GUI libs).
Vivado tools (~100GB) live on the host at `~/dev/fpga/xilinx_tools` and are
mounted into the container at `/tools/Xilinx` at runtime — keeping the image
small and the installation persistent across container rebuilds.

## Structure

```
xilinx-dev-env/
  vivado-vitis/
    Dockerfile            # Ubuntu 20.04 base image with GUI dependencies
    vivado_uninstall.sh   # Safe version-specific uninstaller
  Vitis-AI/               # Git submodule — official Xilinx repo
  vivado_docker.sh        # Launches Vivado container (GUI or batch mode)
  install_vivado.sh       # One-time Vivado installer script
  centos7-os-release      # CentOS stub required by some Xilinx tools
```

## Setup (one time)

### 1. Clone

```bash
git clone --recurse-submodules git@github.com:Pcsf/xilinx-dev-env.git
```

### 2. Build the Vivado Docker image

```bash
cd vivado-vitis
docker build -t my-vivado-image:2021.2 .
```

### 3. Install Vivado

Download the Vivado 2021.2 installer from [Xilinx](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html)
and place it in `~/dev/fpga/xilinx_tools/`.

```bash
# Auto-finds installer in ~/dev/fpga/xilinx_tools/
./install_vivado.sh

# Or specify path explicitly
./install_vivado.sh /path/to/Xilinx_Unified_2021.2_1021_0703_Lin64.bin
```

**CRITICAL:** When the installer asks for the installation path, set it to `/tools/Xilinx`.
This maps to `~/dev/fpga/xilinx_tools` on the host.

### 4. Pull the Vitis AI container

```bash
docker pull xilinx/vitis-ai-pytorch-cpu:latest
```

## Daily Usage

### Launch Vivado (GUI)

```bash
./vivado_docker.sh
```

### Launch Vivado (batch mode)

```bash
./vivado_docker.sh -mode batch -source /path/to/script.tcl
```

### Launch Vitis AI

```bash
cd Vitis-AI
./docker_run.sh xilinx/vitis-ai-pytorch-cpu:latest
```

## Uninstalling a Vivado version

```bash
./vivado-vitis/vivado_uninstall.sh 2021.2
```

## Important Notes

- `_JAVA_AWT_WM_NONREPARENTING=1` is set in the launch scripts — required
  for GUI rendering under tiling WMs (Hyprland/XWayland)
- Do not use the Vitis AI GPU image (requires NVIDIA CUDA); use CPU image only
- Do not build Vitis AI from source (broken dependencies)
- The Vivado container runs as the host user to avoid file permission issues

#!/usr/bin/env bash
# vivado_uninstall.sh — Safe uninstaller for any Vivado/Vitis version
#
# WHY NOT use Xilinx's official `xsetup -Uninstall`:
#   The Xilinx installer records paths relative to the Docker container
#   mountpoint (/tools/Xilinx/...). Running xsetup from the host would
#   look for /tools/Xilinx/... which doesn't exist there, failing silently.
#   Manual removal of version-specific subdirectories is the correct approach.
#
# WHAT IS SAFE TO REMOVE:
#   All tool directories use per-version subdirectories (e.g. Vivado/2023.2).
#   Shared components (xic, DocNav) have no version suffix and are left untouched.
#
# Usage:
#   ./vivado_uninstall.sh <version> [install_base_dir]
#
# Arguments:
#   version          Vivado/Vitis version to remove, e.g. 2023.2
#   install_base_dir Base directory where Xilinx tools are installed
#                    (default: ~/dev/fpga/xilinx_tools)
#
# Example:
#   ./vivado_uninstall.sh 2023.2
#   ./vivado_uninstall.sh 2023.2 /opt/xilinx

set -euo pipefail

# ── Arguments ──────────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <version> [install_base_dir]"
    echo "Example: $0 2023.2"
    echo "         $0 2023.2 /opt/xilinx"
    exit 1
fi

VERSION="$1"
INSTALL_BASE="${2:-$HOME/dev/fpga/xilinx_tools}"

# ── Directories that are version-specific (safe to remove) ─────────────────────
# Shared components (xic, DocNav) are deliberately excluded.
VERSION_DIRS=(
    "${INSTALL_BASE}/Vivado/${VERSION}"
    "${INSTALL_BASE}/Vitis/${VERSION}"
    "${INSTALL_BASE}/Vitis_HLS/${VERSION}"
    "${INSTALL_BASE}/Model_Composer/${VERSION}"
    "${INSTALL_BASE}/SharedData/${VERSION}"
)

# .xinstall metadata: Xilinx uses either "Vivado_<ver>" or "Vitis_<ver>" naming.
XINSTALL_CANDIDATES=(
    "${INSTALL_BASE}/.xinstall/Vivado_${VERSION}"
    "${INSTALL_BASE}/.xinstall/Vitis_${VERSION}"
)

# ── Pre-flight checks ───────────────────────────────────────────────────────────
if [[ ! -d "${INSTALL_BASE}" ]]; then
    echo "ERROR: Install base directory not found: ${INSTALL_BASE}"
    exit 1
fi

# Collect directories that actually exist on disk
TO_REMOVE=()
for dir in "${VERSION_DIRS[@]}" "${XINSTALL_CANDIDATES[@]}"; do
    if [[ -d "${dir}" ]]; then
        TO_REMOVE+=("${dir}")
    fi
done

if [[ ${#TO_REMOVE[@]} -eq 0 ]]; then
    echo "ERROR: No directories found for version ${VERSION} in ${INSTALL_BASE}."
    echo ""
    echo "Installed versions detected:"
    for tool in Vivado Vitis Vitis_HLS; do
        if [[ -d "${INSTALL_BASE}/${tool}" ]]; then
            echo "  ${tool}/: $(ls "${INSTALL_BASE}/${tool}/" | tr '\n' ' ')"
        fi
    done
    exit 1
fi

# Warn if any other version shares the install base (safety check)
OTHER_VERSIONS=()
for tool in Vivado Vitis Vitis_HLS; do
    if [[ -d "${INSTALL_BASE}/${tool}" ]]; then
        while IFS= read -r ver; do
            if [[ "${ver}" != "${VERSION}" ]]; then
                OTHER_VERSIONS+=("${tool}/${ver}")
            fi
        done < <(ls "${INSTALL_BASE}/${tool}/")
    fi
done

# ── Summary ─────────────────────────────────────────────────────────────────────
echo "========================================================"
echo "  Xilinx Vivado Uninstaller"
echo "========================================================"
echo "  Version to remove : ${VERSION}"
echo "  Install base      : ${INSTALL_BASE}"
echo ""
echo "  Directories to delete:"
for dir in "${TO_REMOVE[@]}"; do
    size=$(du -sh "${dir}" 2>/dev/null | cut -f1 || echo "?")
    printf "    [%s]  %s\n" "${size}" "${dir}"
done

if [[ ${#OTHER_VERSIONS[@]} -gt 0 ]]; then
    echo ""
    echo "  Other versions detected (will NOT be touched):"
    for v in "${OTHER_VERSIONS[@]}"; do
        echo "    ${INSTALL_BASE}/${v}"
    done
    echo "  Shared components (xic, DocNav) also left untouched."
fi

echo "========================================================"
echo ""
read -rp "Permanently delete the above directories? [y/N] " confirm
if [[ "${confirm,,}" != "y" ]]; then
    echo "Aborted."
    exit 0
fi

# ── Remove version-specific directories ────────────────────────────────────────
echo ""
for dir in "${TO_REMOVE[@]}"; do
    echo "Removing: ${dir}"
    rm -rf "${dir}"
done

echo ""
echo "Done. Vivado/Vitis ${VERSION} has been removed."
if [[ ${#OTHER_VERSIONS[@]} -gt 0 ]]; then
    echo "Other versions remain intact at ${INSTALL_BASE}."
fi

#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_FILE=$(ls "${SCRIPT_DIR}"/NVIDIA-Linux-x86_64-*.run 2>/dev/null | head -1)
MODULES_DIR="${SCRIPT_DIR}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root"
        exit 1
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        log_error "Cannot detect distribution"
        exit 1
    fi
}

install_dependencies() {
    local distro=$(detect_distro)
    log_info "Installing dependencies for $distro..."
    
    case $distro in
        ubuntu|debian)
            apt-get update
            apt-get install -y build-essential linux-headers-$(uname -r) wget
            ;;
        fedora|rhel|centos)
            dnf install -y kernel-devel kernel-headers gcc make wget
            ;;
        arch)
            pacman -Sy --noconfirm linux-headers base-devel wget
            ;;
        *)
            log_warn "Unknown distribution: $distro. Please install dependencies manually."
            log_warn "Required: build-essential, linux-headers-$(uname -r)"
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
            ;;
    esac
}

disable_nouveau() {
    log_info "Disabling nouveau driver..."
    
    if lsmod | grep -q nouveau; then
        log_warn "Nouveau is currently loaded. It will be disabled after reboot."
    fi
    
    cat > /etc/modprobe.d/blacklist-nouveau.conf << 'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
    
    if command -v update-initramfs &> /dev/null; then
        update-initramfs -u
    elif command -v dracut &> /dev/null; then
        dracut --force
    fi
    
    log_info "Nouveau disabled. Reboot required for changes to take effect."
}

install_driver() {
    if [ -z "$DRIVER_FILE" ]; then
        log_error "NVIDIA driver file not found in ${SCRIPT_DIR}"
        log_error "Expected: NVIDIA-Linux-x86_64-VERSION.run"
        exit 1
    fi
    
    log_info "Installing NVIDIA driver (without kernel modules)..."
    log_info "Driver file: $DRIVER_FILE"
    
    chmod +x "$DRIVER_FILE"
    
    "$DRIVER_FILE" --no-kernel-modules -a -s --no-x-check -z --skip-module-load
    
    log_info "NVIDIA driver installed successfully."
}

install_kernel_modules() {
    log_info "Installing P2P kernel modules..."
    
    local modules=("nvidia.ko" "nvidia-drm.ko" "nvidia-modeset.ko" "nvidia-uvm.ko" "nvidia-peermem.ko")
    local modules_dest="/lib/modules/$(uname -r)/kernel/drivers/video"
    
    for mod in "${modules[@]}"; do
        if [ -f "${MODULES_DIR}/${mod}" ]; then
            log_info "Installing ${mod}..."
            cp "${MODULES_DIR}/${mod}" "${modules_dest}/"
        else
            log_error "Module not found: ${mod}"
            exit 1
        fi
    done
    
    log_info "Running depmod..."
    depmod -a
    
    if command -v update-initramfs &> /dev/null; then
        log_info "Updating initramfs..."
        update-initramfs -u
    elif command -v dracut &> /dev/null; then
        log_info "Rebuilding initramfs with dracut..."
        dracut --force
    fi
    
    log_info "Kernel modules installed successfully."
}

configure_auto_load() {
    log_info "Configuring kernel module auto-load..."
    
    cat > /etc/modules-load.d/nvidia.conf << 'EOF'
nvidia
nvidia-drm
nvidia-modeset
nvidia-uvm
EOF

    cat > /etc/modprobe.d/nvidia.conf << 'EOF'
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia-drm modeset=1
EOF

    log_info "Auto-load configuration created."
}

verify_installation() {
    log_info "Verifying installation..."
    
    echo ""
    echo "=== Driver Version ==="
    if [ -f /usr/lib/x86_64-linux-gnu/libnvidia-glcore.so.* ]; then
        ls -la /usr/lib/x86_64-linux-gnu/libnvidia-glcore.so.* | head -1
    fi
    
    echo ""
    echo "=== Kernel Modules ==="
    for mod in nvidia nvidia-drm nvidia-modeset nvidia-uvm; do
        if modinfo "${mod}" 2>/dev/null | grep -q "^version:"; then
            version=$(modinfo "${mod}" 2>/dev/null | grep "^version:" | awk '{print $2}')
            echo "${mod}: ${version}"
        else
            echo "${mod}: NOT FOUND"
        fi
    done
    
    echo ""
    log_info "Installation verification complete."
}

print_summary() {
    echo ""
    echo "========================================"
    echo "  NVIDIA P2P Driver Installation Complete"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "  1. Reboot your system: sudo reboot"
    echo "  2. Verify with: nvidia-smi"
    echo "  3. Check P2P topology: nvidia-smi topo -m"
    echo ""
}

main() {
    echo ""
    echo "========================================"
    echo "  NVIDIA P2P Driver Installer"
    echo "========================================"
    echo ""
    
    check_root
    
    local skip_deps=false
    local skip_nouveau=false
    local skip_driver=false
    local skip_modules=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-deps)
                skip_deps=true
                shift
                ;;
            --skip-nouveau)
                skip_nouveau=true
                shift
                ;;
            --skip-driver)
                skip_driver=true
                shift
                ;;
            --skip-modules)
                skip_modules=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --skip-deps      Skip dependency installation"
                echo "  --skip-nouveau   Skip nouveau blacklist"
                echo "  --skip-driver    Skip driver installation"
                echo "  --skip-modules   Skip kernel module installation"
                echo "  --help           Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [ "$skip_deps" = false ]; then
        install_dependencies
    fi
    
    if [ "$skip_nouveau" = false ]; then
        disable_nouveau
    fi
    
    if [ "$skip_driver" = false ]; then
        install_driver
    fi
    
    if [ "$skip_modules" = false ]; then
        install_kernel_modules
    fi
    
    configure_auto_load
    verify_installation
    print_summary
}

main "$@"

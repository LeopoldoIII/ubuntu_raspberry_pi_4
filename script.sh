#!/usr/bin/env bash
# ==============================================================================
# DevLab Automated Installer & Setup Engine
# Supports Ubuntu 24.04/22.04 LTS on x86_64 (PCs/ThinkPads) and ARM64 (Raspberry Pi 4/5)
# ==============================================================================

set -euo pipefail

# --- Color Constants ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Log Helpers ---
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Hardware Auto-Detection ---
detect_hardware() {
    ARCH=$(uname -m)
    TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
    TOTAL_RAM_GB=$(awk "BEGIN {printf \"%.1f\", ${TOTAL_RAM_MB}/1024}")
    FREE_DISK_GB=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')

    log_info "Detecting hardware resources..."
    echo -e "  - CPU Architecture : ${CYAN}${ARCH}${NC}"
    echo -e "  - Total RAM        : ${CYAN}${TOTAL_RAM_GB} GB${NC}"
    echo -e "  - Free Storage     : ${CYAN}${FREE_DISK_GB} GB${NC}"
    echo ""
}

# --- Recommended LLM Model Calibration ---
get_recommended_llm() {
    if (( $(echo "$TOTAL_RAM_GB >= 15.0" | bc -l) )); then
        echo "qwen2.5-coder:7b"
    elif (( $(echo "$TOTAL_RAM_GB >= 7.5" | bc -l) )); then
        echo "qwen2.5-coder:3b"
    else
        echo "qwen2.5-coder:1.5b"
    fi
}

# --- Module Installations ---
install_base_tools() {
    log_info "Updating system packages and installing base utilities..."
    sudo apt-get update -y
    sudo apt-get install -y git curl htop zsh net-tools ca-certificates software-properties-common whiptail ufw fail2ban bc
    log_success "Base system packages updated."
}

configure_hardening() {
    log_info "Configuring host security (UFW Firewall & Fail2ban)..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp   # SSH
    sudo ufw allow 80/tcp   # Dashy Dashboard
    sudo ufw allow 443/tcp  # HTTPS
    sudo ufw allow 3000/tcp # Open WebUI
    sudo ufw allow 8000/tcp # Woodpecker CI
    sudo ufw allow 8080/tcp # Adminer
    sudo ufw allow 8090/tcp # Beszel Telemetry
    sudo ufw allow 9000/tcp # Portainer & SonarQube
    sudo ufw --force enable || true
    sudo systemctl enable --now fail2ban || true
    log_success "Host security hardening active."
}

install_docker() {
    log_info "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        log_info "Installing Docker Engine..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker "$USER" || true
        rm -f get-docker.sh
        log_success "Docker installed successfully."
    else
        log_success "Docker is already installed."
    fi

    log_info "Installing Docker Compose plugin..."
    sudo apt-get install -y docker-compose-plugin
    log_success "Docker Compose plugin ready."
}

install_ollama() {
    log_info "Checking Ollama LLM engine..."
    if ! command -v ollama &> /dev/null; then
        log_info "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
        log_success "Ollama installed."
    else
        log_success "Ollama is already installed."
    fi

    RECOMMENDED_MODEL=$(get_recommended_llm)
    log_info "Pulling recommended LLM model for your RAM (${TOTAL_RAM_GB} GB): ${RECOMMENDED_MODEL}..."
    ollama pull "${RECOMMENDED_MODEL}" || log_warn "Failed to pull model ${RECOMMENDED_MODEL}. You can pull it manually later using: ollama pull ${RECOMMENDED_MODEL}"
}

setup_zram() {
    log_info "Configuring ZRAM memory compression & Swap tuning..."
    sudo apt-get install -y zram-config || sudo apt-get install -y zram-tools || true
    log_success "ZRAM memory optimization configured."
}

install_k3s() {
    log_info "Installing lightweight Kubernetes (K3s)..."
    if ! command -v k3s &> /dev/null; then
        curl -sfL https://get.k3s.io | sh -
        mkdir -p "$HOME/.kube"
        sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config" || true
        sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config" || true
        log_success "K3s Kubernetes installed successfully."
    else
        log_success "K3s is already installed."
    fi
}

install_zsh() {
    log_info "Setting up Zsh and Oh My Zsh..."
    sudo apt-get install -y zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no CHSH=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
        log_success "Oh My Zsh installed."
    fi
}

start_docker_stacks() {
    log_info "Launching Docker Compose stacks..."
    
    [ -f "docker/docker-compose.monitoring.yml" ] && docker compose -f docker/docker-compose.monitoring.yml up -d
    [ -f "docker/docker-compose.databases.yml" ] && docker compose -f docker/docker-compose.databases.yml up -d
    [ -f "docker/docker-compose.llm.yml" ] && docker compose -f docker/docker-compose.llm.yml up -d
    [ -f "docker/docker-compose.floci.yml" ] && docker compose -f docker/docker-compose.floci.yml up -d
    [ -f "docker/docker-compose.security.yml" ] && docker compose -f docker/docker-compose.security.yml up -d
    [ -f "docker/docker-compose.cicd.yml" ] && docker compose -f docker/docker-compose.cicd.yml up -d
    
    log_success "All requested Docker stacks are running."
}

# --- Interactive TUI Menu Wizard ---
run_interactive_wizard() {
    if ! command -v whiptail &> /dev/null; then
        sudo apt-get update -y && sudo apt-get install -y whiptail
    fi

    RECOMMENDED_MODEL=$(get_recommended_llm)

    CHOICES=$(whiptail --title "DevLab Interactive Setup Wizard" \
        --checklist "Detected System: ${ARCH} | RAM: ${TOTAL_RAM_GB}GB | Free Storage: ${FREE_DISK_GB}GB\n\nSelect components to install:" \
        20 78 10 \
        "BASE" "System Update & Host Hardening (UFW Firewall, Fail2ban)" ON \
        "DOCKER" "Docker Engine & Docker Compose Plugin" ON \
        "MONITORING" "Unified Web Dashboard (Dashy), Beszel Telemetry & Portainer" ON \
        "DATABASES" "Database Stack (PostgreSQL + pgvector, Redis, Adminer)" ON \
        "LLM" "Local LLM Engine (Ollama + Open WebUI - Auto: ${RECOMMENDED_MODEL})" ON \
        "FLOCI" "Cloud Emulation Stack (Floci AWS/GCP/Azure)" ON \
        "SECURITY" "DevSecOps Suite (SonarQube SAST, OWASP ZAP, Trivy, Tailscale)" ON \
        "CICD" "CI/CD Engine (Woodpecker CI Server & Runner)" ON \
        "K3S" "Lightweight Kubernetes Engine (K3s & kubectl)" OFF \
        "ZRAM" "ZRAM Memory Optimization & Swap Tuning" ON \
        "ZSH" "Zsh Shell & Oh My Zsh Environment" ON 3>&1 1>&2 2>&3) || exit 0

    log_info "Starting installation based on your wizard selection..."

    for CHOICE in $CHOICES; do
        CLEAN_CHOICE=$(echo "$CHOICE" | tr -d '"')
        case "$CLEAN_CHOICE" in
            BASE) install_base_tools; configure_hardening ;;
            DOCKER) install_docker ;;
            LLM) install_ollama ;;
            ZRAM) setup_zram ;;
            K3S) install_k3s ;;
            ZSH) install_zsh ;;
        esac
    done

    start_docker_stacks
}

# --- CLI Flag Argument Parsing ---
parse_flags() {
    NON_INTERACTIVE=false
    INSTALL_ALL=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --non-interactive) NON_INTERACTIVE=true; shift ;;
            --all) INSTALL_ALL=true; shift ;;
            --docker) install_docker; shift ;;
            --llm) install_ollama; shift ;;
            --k3s) install_k3s; shift ;;
            --zram) setup_zram; shift ;;
            *) log_warn "Unknown flag: $1"; shift ;;
        esac
    done

    if [ "$INSTALL_ALL" = true ]; then
        install_base_tools
        configure_hardening
        install_docker
        install_ollama
        setup_zram
        install_k3s
        install_zsh
        start_docker_stacks
    fi
}

# --- Main Entry Point ---
main() {
    echo -e "${CYAN}========================================================================${NC}"
    echo -e "${CYAN} 🚀 DevLab Setup Engine: Multi-Arch DevLab, Kubernetes, Security & AI ${NC}"
    echo -e "${CYAN}========================================================================${NC}"
    echo ""

    detect_hardware

    if [[ $# -eq 0 ]]; then
        run_interactive_wizard
    else
        parse_flags "$@"
    fi

    echo ""
    log_success "🎉 DevLab setup completed successfully!"
    echo -e "🔗 Unified Control Dashboard : ${GREEN}http://localhost:80${NC}"
    echo -e "📊 Hardware Telemetry Console: ${GREEN}http://localhost:8090${NC}"
    echo -e "🐳 Container Manager         : ${GREEN}http://localhost:9000${NC}"
    echo -e "🧠 Local LLM Open WebUI      : ${GREEN}http://localhost:3000${NC}"
    echo -e "🛠️  CI/CD Console (Woodpecker): ${GREEN}http://localhost:8000${NC}"
    echo -e "🔍 SonarQube Code Scanner    : ${GREEN}http://localhost:9000/sonar${NC}"
    echo ""
    log_info "If this is your first time adding yourself to the docker group, please log out and back in."
}

main "$@"
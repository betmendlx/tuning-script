#!/bin/bash

# Enhanced tune_server_limits.sh
# Script to optimize server performance by adjusting system limits and settings

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

# Define variables
MAX_FILE_DESCRIPTORS=1048576
MAX_PROCESSES=1048576
LOG_FILE="/var/log/tune_server_limits.log"

# Logging function
log() {
  echo -e "$(date): $1" | tee -a "$LOG_FILE"
}

# Colorful logging function
clog() {
  echo -e "${2}$(date): $1${NC}" | tee -a "$LOG_FILE"
}

# Backup function
backup_file() {
  if [ -f "$1" ]; then
    cp "$1" "$1.bak_$(date +%Y%m%d%H%M%S)"
    clog "Backup created: $1.bak_$(date +%Y%m%d%H%M%S)" "$YELLOW"
  fi
}

# Function to safely append to a file
safe_append() {
  if ! grep -qF "$2" "$1"; then
    echo "$2" | sudo tee -a "$1" > /dev/null
    clog "Appended to $1: $2" "$GREEN"
  else
    clog "Entry already exists in $1: $2" "$YELLOW"
  fi
}

clog "Starting server limit tuning script" "$BLUE"

# Backup configuration files
backup_file /etc/security/limits.conf
backup_file /etc/pam.d/common-session
backup_file /etc/sysctl.conf

# Modify /etc/security/limits.conf
clog "Updating /etc/security/limits.conf..." "$CYAN"
safe_append /etc/security/limits.conf "*    soft nofile $MAX_FILE_DESCRIPTORS"
safe_append /etc/security/limits.conf "*    hard nofile $MAX_FILE_DESCRIPTORS"
safe_append /etc/security/limits.conf "root soft nofile $MAX_FILE_DESCRIPTORS"
safe_append /etc/security/limits.conf "root hard nofile $MAX_FILE_DESCRIPTORS"
safe_append /etc/security/limits.conf "*    soft nproc $MAX_PROCESSES"
safe_append /etc/security/limits.conf "*    hard nproc $MAX_PROCESSES"
safe_append /etc/security/limits.conf "root soft nproc $MAX_PROCESSES"
safe_append /etc/security/limits.conf "root hard nproc $MAX_PROCESSES"

# Edit /etc/pam.d/common-session
clog "Updating /etc/pam.d/common-session..." "$CYAN"
safe_append /etc/pam.d/common-session "session required pam_limits.so"

# Modify /etc/sysctl.conf
clog "Updating /etc/sysctl.conf..." "$CYAN"
safe_append /etc/sysctl.conf "fs.file-max = 2097152"
safe_append /etc/sysctl.conf "fs.nr_open = $MAX_FILE_DESCRIPTORS"
safe_append /etc/sysctl.conf "net.core.somaxconn = 65535"
safe_append /etc/sysctl.conf "net.core.netdev_max_backlog = 65536"
safe_append /etc/sysctl.conf "net.ipv4.tcp_max_syn_backlog = 8192"
safe_append /etc/sysctl.conf "net.ipv4.tcp_tw_reuse = 1"
safe_append /etc/sysctl.conf "net.ipv4.ip_local_port_range = 1024 65535"
safe_append /etc/sysctl.conf "net.ipv4.tcp_fin_timeout = 15"
safe_append /etc/sysctl.conf "net.ipv4.tcp_keepalive_time = 300"
safe_append /etc/sysctl.conf "net.ipv4.tcp_max_tw_buckets = 1440000"
safe_append /etc/sysctl.conf "net.core.rmem_max = 16777216"
safe_append /etc/sysctl.conf "net.core.wmem_max = 16777216"
safe_append /etc/sysctl.conf "net.ipv4.tcp_rmem = 4096 87380 16777216"
safe_append /etc/sysctl.conf "net.ipv4.tcp_wmem = 4096 65536 16777216"

# Apply the sysctl changes
clog "Applying sysctl changes..." "$MAGENTA"
if sudo sysctl -p; then
  clog "Sysctl changes applied successfully" "$GREEN"
else
  clog "Error applying sysctl changes" "$RED"
fi

# Optimize disk I/O scheduler
SYSTEM_DISK=$(lsblk -ndo NAME | head -n1)
clog "Optimizing disk I/O scheduler for /dev/${SYSTEM_DISK}..." "$CYAN"
if [ -e "/sys/block/${SYSTEM_DISK}/queue/scheduler" ]; then
  echo "none" | sudo tee /sys/block/${SYSTEM_DISK}/queue/scheduler > /dev/null
  clog "I/O scheduler set to none for /dev/${SYSTEM_DISK}" "$GREEN"
else
  clog "Error: Scheduler file not found for /dev/${SYSTEM_DISK}" "$RED"
fi

# Optimize TCP congestion control algorithm
clog "Setting TCP congestion control algorithm to BBR..." "$CYAN"
if grep -q "tcp_bbr" /proc/modules; then
  safe_append /etc/sysctl.conf "net.core.default_qdisc = fq"
  safe_append /etc/sysctl.conf "net.ipv4.tcp_congestion_control = bbr"
  sysctl -p > /dev/null
  clog "TCP congestion control set to BBR" "$GREEN"
else
  clog "BBR module not available. Consider upgrading your kernel to use BBR." "$YELLOW"
fi

# Display the new limits
clog "New open files limit: $(ulimit -n)" "$GREEN"
clog "New number of processes limit: $(ulimit -u)" "$GREEN"

clog "Script completed. It's recommended to reboot the system for all changes to take effect." "$BLUE"

echo -e "${MAGENTA}Server limit tuning completed. Check $LOG_FILE for details.${NC}"
echo -e "${YELLOW}It's recommended to reboot the system for all changes to take effect.${NC}"

# Offer to reboot the system
read -p "Do you want to reboot the system now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    clog "Rebooting the system..." "$RED"
    shutdown -r now
fi

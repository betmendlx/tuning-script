#!/bin/bash

# desktop_laptop_tune.sh
# Script to optimize desktop and laptop performance by adjusting system limits and settings

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
MAX_FILE_DESCRIPTORS=524288
MAX_PROCESSES=524288
LOG_FILE="/var/log/desktop_laptop_tune.log"

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

clog "Starting desktop/laptop performance tuning script" "$BLUE"

# Backup configuration files
backup_file /etc/security/limits.conf
backup_file /etc/sysctl.conf

# Modify /etc/security/limits.conf
clog "Updating /etc/security/limits.conf..." "$CYAN"
safe_append /etc/security/limits.conf "*    soft nofile $MAX_FILE_DESCRIPTORS"
safe_append /etc/security/limits.conf "*    hard nofile $MAX_FILE_DESCRIPTORS"
safe_append /etc/security/limits.conf "*    soft nproc $MAX_PROCESSES"
safe_append /etc/security/limits.conf "*    hard nproc $MAX_PROCESSES"

# Modify /etc/sysctl.conf
clog "Updating /etc/sysctl.conf..." "$CYAN"
safe_append /etc/sysctl.conf "fs.file-max = 1048576"
safe_append /etc/sysctl.conf "fs.inotify.max_user_watches = 524288"
safe_append /etc/sysctl.conf "vm.swappiness = 10"
safe_append /etc/sysctl.conf "vm.vfs_cache_pressure = 50"
safe_append /etc/sysctl.conf "net.core.somaxconn = 4096"
safe_append /etc/sysctl.conf "net.ipv4.tcp_max_syn_backlog = 4096"
safe_append /etc/sysctl.conf "net.core.netdev_max_backlog = 4096"
safe_append /etc/sysctl.conf "net.ipv4.tcp_fastopen = 3"

# Apply the sysctl changes
clog "Applying sysctl changes..." "$MAGENTA"
if sudo sysctl -p; then
  clog "Sysctl changes applied successfully" "$GREEN"
else
  clog "Error applying sysctl changes" "$RED"
fi

# Optimize I/O scheduler for SSDs
clog "Optimizing I/O scheduler for SSDs..." "$CYAN"
for disk in $(lsblk -dnno NAME | grep -E '^sd|^nvme'); do
  if [ -e "/sys/block/$disk/queue/rotational" ] && [ "$(cat /sys/block/$disk/queue/rotational)" -eq 0 ]; then
    echo "none" | sudo tee /sys/block/$disk/queue/scheduler > /dev/null
    clog "I/O scheduler set to none for /dev/$disk (SSD)" "$GREEN"
  fi
done

# Enable TRIM for SSDs
clog "Enabling TRIM for SSDs..." "$CYAN"
if ! systemctl is-active --quiet fstrim.timer; then
  sudo systemctl enable fstrim.timer
  sudo systemctl start fstrim.timer
  clog "TRIM service enabled and started" "$GREEN"
else
  clog "TRIM service already active" "$YELLOW"
fi

# Optimize CPU governor
clog "Setting CPU governor to performance..." "$CYAN"
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  echo "performance" | sudo tee $cpu/cpufreq/scaling_governor > /dev/null
done
clog "CPU governor set to performance" "$GREEN"

# Enable zswap
clog "Enabling zswap..." "$CYAN"
if ! grep -q "zswap.enabled=1" /etc/default/grub; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="zswap.enabled=1 /' /etc/default/grub
  sudo update-grub
  clog "zswap enabled in GRUB configuration" "$GREEN"
else
  clog "zswap already enabled in GRUB configuration" "$YELLOW"
fi

# Optimize virtual memory
clog "Optimizing virtual memory settings..." "$CYAN"
safe_append /etc/sysctl.conf "vm.dirty_background_ratio = 5"
safe_append /etc/sysctl.conf "vm.dirty_ratio = 10"

# Display the new limits
clog "New open files limit: $(ulimit -n)" "$GREEN"
clog "New number of processes limit: $(ulimit -u)" "$GREEN"

clog "Script completed. It's recommended to reboot the system for all changes to take effect." "$BLUE"

echo -e "${MAGENTA}Desktop/laptop performance tuning completed. Check $LOG_FILE for details.${NC}"
echo -e "${YELLOW}It's recommended to reboot the system for all changes to take effect.${NC}"

# Offer to reboot the system
read -p "Do you want to reboot the system now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    clog "Rebooting the system..." "$RED"
    shutdown -r now
fi

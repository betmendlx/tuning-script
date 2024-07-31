# Performance Tuning Scripts

This repository contains scripts for optimizing the performance of various Linux systems, including servers, desktops, and laptops. These scripts adjust system limits and settings to improve overall system performance and responsiveness.

## Scripts

1. `tune_server_limits.sh`: Optimizes server performance
2. `desktop_laptop_tune.sh`: Enhances desktop and laptop performance

## Features

- Colorful output for better readability
- Automatic backup of modified configuration files
- Optimization of system limits, network settings, and I/O performance
- CPU governor management (for desktop/laptop script)
- SSD-specific optimizations (for desktop/laptop script)

## Usage

### Server Optimization

1. Clone this repository:
   ```
   git clone https://github.com/your-username/performance-tuning-scripts.git
   ```

2. Navigate to the repository directory:
   ```
   cd performance-tuning-scripts
   ```

3. Make the script executable:
   ```
   chmod +x tune_server_limits.sh
   ```

4. Run the script with root privileges:
   ```
   sudo ./tune_server_limits.sh
   ```

### Desktop/Laptop Optimization

1. Clone this repository (if you haven't already):
   ```
   git clone https://github.com/your-username/performance-tuning-scripts.git
   ```

2. Navigate to the repository directory:
   ```
   cd performance-tuning-scripts
   ```

3. Make the script executable:
   ```
   chmod +x desktop_laptop_tune.sh
   ```

4. Run the script with root privileges:
   ```
   sudo ./desktop_laptop_tune.sh
   ```

## Important Considerations

- These scripts make system-wide changes. It's recommended to review the scripts and understand the modifications before running them.
- Always back up your system before making significant changes.
- Some optimizations may not be suitable for all hardware configurations or use cases. Monitor your system after applying these changes and adjust as necessary.
- The scripts will create log files (`/var/log/tune_server_limits.log` for servers and `/var/log/desktop_laptop_tune.log` for desktops/laptops) detailing the changes made.
- A system reboot is recommended after running these scripts for all changes to take effect.

## Customization

You can customize these scripts by modifying the values in the variables section at the beginning of each script. Adjust the settings based on your specific hardware and requirements.

## Contributing

Contributions to improve these scripts or add new optimizations are welcome! Please submit a pull request with your proposed changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

These scripts are provided as-is, without any warranty. Use them at your own risk. The authors are not responsible for any damage or data loss that may occur from using these scripts.

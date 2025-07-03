#!/bin/bash
set -e

# --- Configuration ---
DRIVER_URL="https://us.download.nvidia.com/tesla/570.86.23/NVIDIA-Linux-x86_64-570.86.23.run"
DRIVER_FILE="NVIDIA-Linux-x86_64-570.86.23.run"
INSTALLER_ARGS="--dkms --non-interactive --accept-license"

# --- Script ---

# Download driver
echo "Downloading NVIDIA driver from ${DRIVER_URL}..."
wget -O "${DRIVER_FILE}" "${DRIVER_URL}"

# Verify download
if [ ! -f "${DRIVER_FILE}" ]; then
    echo "ERROR: Driver download failed. File '${DRIVER_FILE}' not found."
    exit 1
fi
echo "Driver downloaded successfully."

# Install prerequisites
echo "Updating package lists and installing prerequisites (build-essential, dkms)..."
sudo apt-get update
sudo apt-get install -y build-essential dkms

# Stop display manager (if running)
echo "Attempting to stop display manager..."
if systemctl is-active --quiet gdm3; then
    echo "Stopping gdm3 service..."
    sudo systemctl stop gdm3
elif systemctl is-active --quiet lightdm; then
    echo "Stopping lightdm service..."
    sudo systemctl stop lightdm
elif systemctl is-active --quiet sddm; then
    echo "Stopping sddm service..."
    sudo systemctl stop sddm
else
    echo "No common display manager (gdm3, lightdm, sddm) found active. Skipping."
fi

# Install driver
echo "Making the driver installer executable..."
sudo chmod +x "${DRIVER_FILE}"

echo "Starting NVIDIA driver installation with args: ${INSTALLER_ARGS}..."
sudo ./"${DRIVER_FILE}" ${INSTALLER_ARGS}

echo "Driver installation script finished."
echo "A system reboot is required to complete the installation."
# To reboot automatically, uncomment the following line:
# sudo reboot

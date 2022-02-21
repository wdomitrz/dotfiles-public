#!/usr/bin/env bash
set -xue

# ssh server config
if [ -f "~/.local/bin/.config-sshd" ]; then
    sudo apt-get update --yes && sudo apt-get install --yes openssh-server
    ~/.local/bin/.config-sshd
fi

# keybord options - map caps lock to ctrl
sudo sed -i -E "s/^(XKBOPTIONS)\s*=\s*\"\"/\1=\"ctrl:nocaps\"/g" /etc/default/keyboard

# lightdm configuration files
sudo sed -i -E "s/^(greeter-hide-users)\s*=\s*/#\1=/g" /usr/share/lightdm/*/*.conf
[ -d "~/.config/lightdm-gtk-greeter.conf.d/" ] && sudo cp ~/.config/lightdm-gtk-greeter.conf.d/* /usr/share/lightdm/lightdm-gtk-greeter.conf.d/

# Fix problem with network manager
sudo touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf

# get certificates
[ -d "~/.config/ca-certificates/" ] && sudo cp ~/.config/ca-certificates/* /usr/share/ca-certificates/

# Disable problematic redshift autostart
sudo rm -f /etc/systemd/user/default.target.wants/redshift*.service

# bluetooth config
## Enable user space HID
sudo sed -i -E "s/^#?(UserspaceHID)\s*=\s*[a-z]*/\1=true/g" /etc/bluetooth/input.conf
## Set idle timeout
sudo sed -i -E "s/^#?(IdleTimeout)\s*=\s*[0-9]*/\1=10/g" /etc/bluetooth/input.conf
# fast bluetooth config
## Enable FastConnect
sudo sed -i -E "s/^#?(FastConnectable)\s*=\s*[a-z]*/\1 = true/g" /etc/bluetooth/main.conf
## Set number of reconnect attempts
sudo sed -i -E "s/^#?(ReconnectAttempts)\s*=\s*[0-9]*/\1=7/g" /etc/bluetooth/main.conf
## Set reconnect intervals
sudo sed -i -E "s/^#?(ReconnectIntervals)\s*=\s*[0-9,]*/\1=1,2,4,8,16,32,64/g" /etc/bluetooth/main.conf

# Keychron make Fn+f-keys work
echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
sudo update-initramfs -u

# Set the original palette as a default option
update-alternatives --query newt-palette &&
    sudo update-alternatives --set newt-palette /etc/newt/palette.original ||
    echo "no newt-palette"

# Configure grub defaults
# Custom colors
[ -f "~/.config/grub/custom.cfg" ] && sudo cp ~/.config/grub/custom.cfg /boot/grub/
# 1 second timeout
sudo sed -i -E "s/^(GRUB_TIMEOUT)\s*=\s*[0-9]+$/\1=1/" /etc/default/grub
# No splash screen
sudo sed -i -E "s/ *splash//" /etc/default/grub
# Regenerate config
sudo update-grub

# Fix iwlwifi iwl-debug-yoyo.bin error
FIX="options iwlwifi enable_ini=N"
CONF="/etc/modprobe.d/iwlwifi.conf"
if ! grep -s "$FIX" "$CONF" >/dev/null; then
    echo "$FIX" | sudo tee -a "$CONF"
fi

# Create swap file
SWAPFILE_LOCATION="/swapfile"
if ! [ -f "${SWAPFILE_LOCATION}" ]; then
    sudo fallocate -l 2G "${SWAPFILE_LOCATION}"
    sudo chmod 600 "${SWAPFILE_LOCATION}"
    sudo mkswap "${SWAPFILE_LOCATION}"
    sudo swapon "${SWAPFILE_LOCATION}"
    echo "${SWAPFILE_LOCATION} none    swap    sw    0   0" | sudo tee -a /etc/fstab
fi
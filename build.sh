#!/usr/bin/env bash

# ==========================================================
# WinOs Builder
# Debian 12 Bookworm Live ISO Builder
# XFCE4 + Windows 11 Layout
# Designed for GitHub Actions
# ==========================================================

set -euo pipefail

# ==========================================================
# VARIABLES
# ==========================================================

ISO_NAME="WinOs-v1"
WORKDIR="$HOME/winos-build"
LIVE_DIR="$WORKDIR/live-build"

ARCH="amd64"
DIST="bookworm"

# ==========================================================
# COLORS
# ==========================================================

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==========================================================
# LOGGING
# ==========================================================

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    exit 1
}

# ==========================================================
# CHECK ROOT
# ==========================================================

if [[ $EUID -ne 0 ]]; then
    fail "Run as root."
fi

# ==========================================================
# PREPARE
# ==========================================================

log "Preparing directories..."

rm -rf "$WORKDIR"
mkdir -p "$LIVE_DIR"

cd "$LIVE_DIR"

# ==========================================================
# INSTALL CONFIG
# ==========================================================

log "Configuring live-build..."

lb config \
  --architectures "$ARCH" \
  --distribution "$DIST" \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer live \
  --bootappend-live "boot=live components quiet splash" \
  --apt-indices false \
  --memtest none

ok "Live-build configured."

# ==========================================================
# PACKAGE LISTS
# ==========================================================

mkdir -p config/package-lists

cat > config/package-lists/winos.list.chroot << 'EOF'
# ==========================================================
# XFCE DESKTOP
# ==========================================================

xfce4
xfce4-goodies
xfce4-terminal
xfce4-whiskermenu-plugin

# ==========================================================
# DISPLAY MANAGER
# ==========================================================

lightdm
lightdm-gtk-greeter

# ==========================================================
# AUDIO STACK
# ==========================================================

pipewire
pipewire-pulse
wireplumber
alsa-utils
pavucontrol

# ==========================================================
# NETWORK
# ==========================================================

network-manager
network-manager-gnome

# ==========================================================
# BROWSER
# ==========================================================

firefox-esr

# ==========================================================
# FILE MANAGER
# ==========================================================

thunar
thunar-archive-plugin

# ==========================================================
# TERMINAL
# ==========================================================

xfce4-terminal

# ==========================================================
# UTILITIES
# ==========================================================

gparted
nano
vim
curl
wget
git
unzip
zip
p7zip-full

# ==========================================================
# DRIVERS & FIRMWARE
# ==========================================================

firmware-linux
firmware-linux-free
firmware-linux-nonfree
firmware-iwlwifi
firmware-realtek
firmware-atheros
firmware-amd-graphics
firmware-misc-nonfree

intel-microcode
amd64-microcode

mesa-utils
vulkan-tools

# ==========================================================
# THEMES & FONTS
# ==========================================================

papirus-icon-theme
fonts-noto
fonts-liberation
fonts-crosextra-carlito
fonts-crosextra-caladea

# ==========================================================
# SYSTEM
# ==========================================================

sudo
bash-completion
gvfs
policykit-1
dbus-x11
avahi-daemon

EOF

# ==========================================================
# WINDOWS 11 THEME HOOK
# ==========================================================

mkdir -p config/hooks/live

cat > config/hooks/live/0100-theme.hook.chroot << 'EOF'
#!/bin/bash

set -e

mkdir -p /usr/share/themes
mkdir -p /usr/share/icons
mkdir -p /etc/skel/.themes
mkdir -p /etc/skel/.icons

cd /tmp

echo "[*] Downloading Windows 11 GTK Theme..."

wget -O win11-theme.zip \
https://github.com/B00merang-Project/Windows-11/archive/refs/heads/master.zip

unzip win11-theme.zip

THEME_DIR=$(find . -maxdepth 1 -type d | grep Windows-11 | head -n1)

cp -r "$THEME_DIR"/* /usr/share/themes/
cp -r "$THEME_DIR"/* /etc/skel/.themes/

echo "[*] Downloading Windows 11 Icons..."

wget -O win11-icons.zip \
https://github.com/yeyushengfan258/Win11-icon-theme/archive/refs/heads/main.zip

unzip win11-icons.zip

ICON_DIR=$(find . -maxdepth 1 -type d | grep Win11-icon-theme | head -n1)

cp -r "$ICON_DIR"/* /usr/share/icons/
cp -r "$ICON_DIR"/* /etc/skel/.icons/

chmod -R 755 /usr/share/themes
chmod -R 755 /usr/share/icons

EOF

chmod +x config/hooks/live/0100-theme.hook.chroot

# ==========================================================
# XFCE WINDOWS 11 LAYOUT
# ==========================================================

mkdir -p config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml

# ----------------------------------------------------------
# XFWM4
# ----------------------------------------------------------

cat > config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Windows-11"/>
  </property>
</channel>
EOF

# ----------------------------------------------------------
# XFCE PANEL
# ----------------------------------------------------------

cat > config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>

    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=10;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="size" type="uint" value="42"/>
      <property name="mode" type="uint" value="0"/>
      <property name="position-locked" type="bool" value="true"/>

      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
      </property>
    </property>
  </property>
</channel>
EOF

# ==========================================================
# GTK SETTINGS
# ==========================================================

mkdir -p config/includes.chroot/etc/skel/.config/gtk-3.0

cat > config/includes.chroot/etc/skel/.gtkrc-2.0 << 'EOF'
gtk-theme-name="Windows-11"
gtk-icon-theme-name="Win11"
gtk-font-name="Segoe UI 10"
EOF

cat > config/includes.chroot/etc/skel/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name=Windows-11
gtk-icon-theme-name=Win11
gtk-font-name=Segoe UI 10
gtk-cursor-theme-size=24
EOF

# ==========================================================
# LIGHTDM
# ==========================================================

mkdir -p config/includes.chroot/etc/lightdm

cat > config/includes.chroot/etc/lightdm/lightdm.conf << 'EOF'
[Seat:*]
user-session=xfce
greeter-session=lightdm-gtk-greeter
EOF

# ==========================================================
# HOSTNAME
# ==========================================================

mkdir -p config/includes.chroot/etc

echo "WinOs" > config/includes.chroot/etc/hostname

# ==========================================================
# BUILD
# ==========================================================

log "Building ISO..."
log "This can take 30-90 minutes."

lb build

# ==========================================================
# RENAME ISO
# ==========================================================

ISO=$(find . -name "*.iso" | head -n1)

if [[ -z "$ISO" ]]; then
    fail "ISO not found."
fi

mv "$ISO" "${ISO_NAME}.iso"

ok "ISO successfully created:"
echo
echo "$LIVE_DIR/${ISO_NAME}.iso"
echo

# ==========================================================
# FINAL
# ==========================================================

log "Build complete."

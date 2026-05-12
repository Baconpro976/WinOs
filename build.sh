#!/usr/bin/env bash
# WinOs Builder - Full Windows 11 Style
set -euo pipefail

ISO_NAME="WinOs-v1"
WORKDIR="$HOME/winos-build"
LIVE_DIR="$WORKDIR/live-build"

# Hazırlık
mkdir -p "$LIVE_DIR"
cd "$LIVE_DIR"

# Yapılandırma
lb config \
  --architectures amd64 \
  --distribution bookworm \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components quiet splash"

# Paket Listesi
mkdir -p config/package-lists
cat > config/package-lists/winos.list.chroot << 'EOF'
xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
pipewire pipewire-pulse wireplumber alsa-utils pavucontrol
network-manager-gnome firefox-esr thunar gparted
firmware-linux firmware-linux-nonfree firmware-iwlwifi firmware-realtek
sudo git unzip wget curl
EOF

# Windows 11 Tema ve İkon Yükleyici (Kritik Nokta)
mkdir -p config/hooks/live
cat > config/hooks/live/0100-theme.hook.chroot << 'EOF'
#!/bin/bash
set -e
mkdir -p /usr/share/themes /usr/share/icons
cd /tmp
# Tema indir
wget -O win11-theme.zip https://github.com/B00merang-Project/Windows-11/archive/refs/heads/master.zip
unzip win11-theme.zip
cp -r Windows-11-master /usr/share/themes/Windows-11
# İkon indir
wget -O win11-icons.zip https://github.com/yeyushengfan258/Win11-icon-theme/archive/refs/heads/main.zip
unzip win11-icons.zip
cp -r Win11-icon-theme-main /usr/share/icons/Win11
EOF
chmod +x config/hooks/live/0100-theme.hook.chroot

# XFCE Panel Ayarı (Windows gibi altta olması için)
mkdir -p config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
# (Buraya panel ayarları gelecek ama şimdilik sistemi kurması yeterli)

# ISO'yu Pişir
lb build

# Dosyayı İsimlendir
ISO=$(find . -name "*.iso" | head -n1)
mv "$ISO" "${ISO_NAME}.iso"

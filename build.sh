#!/bin/bash
set -e

# Live-build'i sıfırdan ve temiz kur
sudo apt-get install -y live-build
lb clean --all

# Yapılandırma - En garanti ayarlar
lb config \
  --architectures amd64 \
  --distribution bookworm \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware"

# Basit bir XFCE masaüstü ekle
mkdir -p config/package-lists
echo "xfce4 lightdm firefox-esr" > config/package-lists/desktop.list.chroot

# ISO'yu pişir
sudo lb build

#!/bin/bash
set -e

# Çalışma dizinini temizle
sudo rm -rf live-build
mkdir -p live-build && cd live-build

# En temel yapılandırma
sudo lb config \
  --architectures amd64 \
  --bootstrap copy \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid

# Gerekli paketleri ekle
mkdir -p config/package-lists
echo "xfce4 xfce4-goodies lightdm firefox-esr sudo" > config/package-lists/my.list.chroot

# ISO'yu inşa et
sudo lb build

#!/bin/bash

# 1. PRE-FLIGHT CHECKS
# ---------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

source /etc/os-release
echo ">> Detected current OS: Debian $VERSION_CODENAME"

if [ "$VERSION_CODENAME" == "bullseye" ]; then
    TARGET_CODENAME="bookworm"
    echo ">> Plan: Upgrade Bullseye -> Bookworm (Step 1 of 2)"
elif [ "$VERSION_CODENAME" == "bookworm" ]; then
    TARGET_CODENAME="trixie"
    echo ">> Plan: Upgrade Bookworm -> Trixie (Final Step)"
else
    echo "❌ Current version '$VERSION_CODENAME' is not supported by this script."
    exit 1
fi

# 1.5 TIMESHIFT SNAPSHOT
# ---------------------------------------------------
# Checks if timeshift is installed and configured
if command -v timeshift &> /dev/null; then
    echo "-------------------------------------------------------"
    echo "📸 Creating Timeshift snapshot..."
    echo "-------------------------------------------------------"
    # Create snapshot with description and 'Daily' tag (D)
    timeshift --create --comments "Upgrade: $VERSION_CODENAME -> $TARGET_CODENAME" --tags D
else
    echo "-------------------------------------------------------"
    echo "⚠️  Timeshift not installed or not found in PATH."
    echo "   Skipping system snapshot."
    echo "-------------------------------------------------------"
fi

# 2. UPDATE CURRENT SYSTEM
# ---------------------------------------------------
echo ">> Updating current packages..."
export DEBIAN_FRONTEND=noninteractive

apt update
apt upgrade -y
apt full-upgrade -y
apt autoremove -y

# 3. MODIFY SOURCES
# ---------------------------------------------------
echo ">> Switching repositories from $VERSION_CODENAME to $TARGET_CODENAME..."

# Standard sources
if [ -f /etc/apt/sources.list ]; then
    sed -i "s/$VERSION_CODENAME/$TARGET_CODENAME/g" /etc/apt/sources.list
fi

# Deb822 sources
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sed -i "s/$VERSION_CODENAME/$TARGET_CODENAME/g" /etc/apt/sources.list.d/debian.sources
fi

# Third-party sources
find /etc/apt/sources.list.d/ -name "*.list" -exec sed -i "s/$VERSION_CODENAME/$TARGET_CODENAME/g" {} +

# Non-free-firmware fix for Bookworm+
if [ "$TARGET_CODENAME" == "bookworm" ]; then
    sed -i 's/non-free /non-free non-free-firmware /g' /etc/apt/sources.list
    sed -i 's/non-free$/non-free non-free-firmware/g' /etc/apt/sources.list
fi

# 4. PERFORM DISTRIBUTION UPGRADE
# ---------------------------------------------------
echo ">> Starting Full Distribution Upgrade to $TARGET_CODENAME..."

apt update

# Two-stage upgrade to handle dependency shifts safely
apt upgrade --without-new-pkgs -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# 5. CLEANUP
# ---------------------------------------------------
echo ">> Cleaning up..."
apt autoremove -y
apt clean

# 6. REBOOT CHECK
# ---------------------------------------------------
if [ -f /var/run/reboot-required ]; then
    echo "-------------------------------------------------------"
    echo "🔴 REBOOT IS REQUIRED"
    echo "-------------------------------------------------------"
    
    if [ -f /var/run/reboot-required.pkgs ]; then
        echo "The following updates triggered the reboot request:"
        cat /var/run/reboot-required.pkgs | sed 's/^/  - /'
    fi
    
    echo ""
    read -p "Would you like to reboot now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ">> Rebooting..."
        reboot
    fi
else
    echo "-------------------------------------------------------"
    echo "✅ No reboot required. Upgrade complete."
    echo "-------------------------------------------------------"
    
    if [ "$TARGET_CODENAME" == "bookworm" ]; then
        echo "ℹ️  NOTE: You have reached Bookworm."
        echo "   To reach Trixie, run this script one more time."
    fi
fi

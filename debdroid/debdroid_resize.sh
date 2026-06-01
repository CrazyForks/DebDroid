#!/system/bin/sh

# Checks for a matching debdroid configuration file
if [ ! -f /sdcard/debdroid/debdroid_env.sh ]; then
    echo "$0: Missing required configuration file: /sdcard/debdroid/debdroid_env.sh"
    exit 1
fi

# shellcheck disable=SC1091
. /sdcard/debdroid/debdroid_env.sh

# Prints HELP Usage
if [ $# -eq 0 ]; then
echo "DebDroid resizer (https://github.com/NICUP14/DebDroid)
Author: NICUP14
Version: $DEBDROID_VER

Description:
  A lightweight utility to resize ext2 Debian images for DebDroid environments.

Usage:
  $0 [SIZE]

Arguments:
  SIZE        
       New target size for the image.
       If shrinking, extra data is lost. If extending, the new space reads as zeros.

Size Format:
  - Integer followed by optional unit.
  - Units: K, M, G (powers of 1024), KB, MB, GB (powers of 1000)
  - Binary prefixes supported: KiB=K, MiB=M, GiB=G
  Examples: 512M, 5G, 10G

Notes:
  - Shrinking the image is not recommended unless necessary.

Examples:
  $0 5G    # Extend image to 5 GiB"
fi

# Checks for a matching architecture
ARCH=$(getprop ro.product.cpu.abi)
if [ "$ARCH" != "arm64-v8a" ]; then
    echo "$0: Unsupported architecture: $ARCH."
    echo "This script only works on arm64-v8a. (aarch64)"
    exit 1
fi

# Check if the user has root permissions 
if [ "$(id -u)" -ne 0 ]; then
    echo "$0: Missing required super-user permissions."
    exit 1
fi

# shellcheck disable=SC2124
DEBDROIDRSZ_SIZE="$@"

# Checks for a valid size
if ! echo "$DEBDROIDRSZ_SIZE" | grep -Eq '^[0-9]+([KMG]?B?)?$'; then
    echo "$0: Invalid size: $DEBDROIDRSZ_SIZE"
    exit 1
fi

# Ensures the image is not mounted
if $BUSYBOX mountpoint -q "$DEBDROID_ENV"; then
    echo "$0: Refusing to resize a mounted image."
    echo "Terminate all running instances before resizing the image."
    exit 1
fi

echo "Resizing $DEBDROID_IMG to $DEBDROIDRSZ_SIZE..."
($BUSYBOX truncate -s "$DEBDROIDRSZ_SIZE" "$DEBDROID_IMG" && \
    "$DEBDROID_BIN"/e2fsck -fp "$DEBDROID_IMG" && \
    "$DEBDROID_BIN"/resize2fs "$DEBDROID_IMG" && \
    echo "Done!") || echo "Fail!"

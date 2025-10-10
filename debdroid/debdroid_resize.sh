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
  $0 (+|-)[SIZE]

Arguments:
  SIZE        
       Target size for the image. Must include a '+' to extend or '-' to reduce.
       If shrinking, extra data is lost. If extending, the new space reads as zeros.

Size Format:
  - Integer followed by optional unit.
  - Units: K, M, G (powers of 1024), KB, MB, GB (powers of 1000)
  - Binary prefixes supported: KiB=K, MiB=M, GiB=G
  Examples: +512M, -2G, +10K

Notes:
  - Shrinking the image is not recommended unless necessary.

Examples:
  $0 +1G     # Extend image by 1 GiB
  $0 -500M   # Reduce image by 500 MiB"
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
    echo "$0: Missing required super-user permisions."
    exit 1
fi

# shellcheck disable=SC2124
DEBDROIDRSZ_SIZE="$@"
if echo "$DEBDROIDRSZ_SIZE" | grep -Eq '^[+-][0-9]+([KMG]?B?)?$'; then
    echo "$0: Invalid size: $DEBDROIDRSZ_SIZE"
fi

echo "Resizing $DEBDROID_IMG to $DEBDROIDRSZ_SIZE..."
("$DEBDROID_BIN"/truncate -s "$DEBDROIDRSZ_SIZE" "$DEBDROID_IMG" && \
    "$DEBDROID_BIN"/e2fsck -fp "$DEBDROID_IMG" && \
    "$DEBDROID_BIN"/resize2fs "$DEBDROID_IMG" && \
    echo "Done!") || echo "Fail!"

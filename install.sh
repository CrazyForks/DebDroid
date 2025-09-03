#!/system/bin/sh

echo ' ____  _____ ____  ____  ____   ___ ___ ____  '
echo '|  _ \| ____| __ )|  _ \|  _ \ / _ \_ _|  _ \ '
echo '| | | |  _| |  _ \| | | | |_) | | | | || | | |'
echo '| |_| | |___| |_) | |_| |  _ <| |_| | || |_| |'
echo '|____/|_____|____/|____/|_| \_\\\\___/___|____/ '
echo
echo 'DebDroid installer (https://github.com/NICUP14/DebDroid)'
echo 'Made by NICUP14!'
echo

# Checks for a matching architecture
ARCH=$(getprop ro.product.cpu.abi)
if [ "$ARCH" != "arm64-v8a" ]; then
    echo "$0: Unsupported architecture: $ARCH."
    echo "This script only works on arm64-v8a (aarch64)."
    exit 1
fi

# Check if the user has root permissions 
if [ "$(id -u)" -ne 0 ]; then
    echo "$0: Missing required super-user permisions."
    exit 1
fi

# Checks for a matching debdroid configuration file
if [ ! -f ./debdroid/debdroid_env.sh ]; then
    echo "$0: Missing required configuration file: ./debdroid/debdroid_env.sh"
    echo "Please change your current directory to the debdroid root folder and try again."
    exit 1
fi

# shellcheck disable=SC1091
. ./debdroid/debdroid_env.sh

echo "$0: Populating $DEBDROID_HOME..."
mkdir -p "$DEBDROID_HOME"
mkdir -p "$DEBDROID_HOME"/bin "$DEBDROID_HOME"/mnt "$DEBDROID_HOME"/lib

cp ./bin/* "$DEBDROID_HOME"/bin
cp ./lib/* "$DEBDROID_HOME"/lib

echo "$0: Populating $DEBDROID_SDHOME..."
mkdir -p "$DEBDROID_SDHOME"
mkdir -p  "$DEBDROID_SDHOME"/img "$DEBDROID_SDHOME"/patch

cp ./patch/* "$DEBDROID_SDHOME"/patch
cp ./debdroid/* "$DEBDROID_SDHOME/"
cat ./img/debian.img.part-* > "$DEBDROID_SDHOME"/img/debian.img

echo "$0: Done!"

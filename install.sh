#!/system/bin/sh

echo ' ____  _____ ____  ____  ____   ___ ___ ____  '
echo '|  _ \| ____| __ )|  _ \|  _ \ / _ \_ _|  _ \ '
echo '| | | |  _| |  _ \| | | | |_) | | | | || | | |'
echo '| |_| | |___| |_) | |_| |  _ <| |_| | || |_| |'
# shellcheck disable=SC2028
echo '|____/|_____|____/|____/|_| \_\\\\___/___|____/ '
echo
echo 'DebDroid installer (https://github.com/NICUP14/DebDroid)'
echo 'Author: NICUP14'
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
    echo "$0: Missing required super-user permissions."
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

# Creates the skeleton under /data/local
echo "$0: Populating $DEBDROID_HOME..."
mkdir -p "$DEBDROID_HOME" \
    "$DEBDROID_HOME"/bin "$DEBDROID_HOME"/mnt "$DEBDROID_HOME"/lib

# Installs project binaries
cp -r ./bin/ "$DEBDROID_HOME"
for bin in "$DEBDROID_HOME"/bin/*; do
    [ -f "$bin" ] || continue # Ensures that the binary exists
    chmod 755 "$bin"
done
chown -R root:root "$DEBDROID_HOME"/bin

# Installs project libraries
cp -r ./lib/ "$DEBDROID_HOME"
for lib in "$DEBDROID_HOME"/lib/*; do
    [ -f "$lib" ] || continue # Ensures that the library exists
    chmod 644 "$lib"
done
chown -R root:root "$DEBDROID_HOME"/lib

# Creates the skeleton under /sdcard
echo "$0: Populating $DEBDROID_SDHOME..."
mkdir -p "$DEBDROID_SDHOME" \
    "$DEBDROID_SDHOME"/img "$DEBDROID_SDHOME"/command

cp -r ./command "$DEBDROID_SDHOME"
cp -r ./debdroid/* "$DEBDROID_SDHOME"

if [ -e "$DEBDROID_SDHOME"/img/debian.img ]; then
    echo "$0: Refusing to overwrite \"$DEBDROID_SDHOME/img/debian.img\", skipping image creation."
else
    echo "$0: Creating the debian image..."
    cat ./img/debian.img.part-* > "$DEBDROID_SDHOME"/img/debian.img

    echo "$0: Enter a new size for the environment or press enter to skip this step:"
    echo "Examples: 5G, +1G, +500M (default=1G)"
    read -r size
    sh -c "sh $DEBDROID_SDHOME/debdroid_resize.sh $size"
fi

echo "$0: Successfully installed DebDroid v$DEBDROID_VER!"

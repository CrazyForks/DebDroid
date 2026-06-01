#!/system/bin/sh

# Debdroid Manager configuration parameters
CONFIG_DEV_FD=yes
CONFIG_DEV_IO=yes
CONFIG_DEV_LOOP=yes
CONFIG_DEBDROID_BIN=yes
CONFIG_DEBDROID_LIB=yes
CONFIG_ENV_FSCK=yes
CONFIG_ENV_SHMMAX=268435456 # 250MB
CONFIG_ENV_DNSSERVER=1.1.1.1 # Fallback dns server (Cloudflare)

# Mounts the chroot environment
start_environment()
{
    # Disables mount propagation
    $BUSYBOX mount --make-rprivate /

    # Links the standard streams to their file descriptor
    if [ "$CONFIG_DEV_FD" = "yes" ] && [ ! -e "/dev/fd" ]; then
        ln -s /proc/self/fd /dev/fd
    fi
    if [ "$CONFIG_DEV_IO" = "yes" ]; then
        [ ! -e "/dev/stdin" ]  && ln -s /proc/self/fd/0 /dev/stdin
        [ ! -e "/dev/stdout" ] && ln -s /proc/self/fd/1 /dev/stdout
        [ ! -e "/dev/stderr" ] && ln -s /proc/self/fd/2 /dev/stderr
    fi

    # Links /dev/block loopback devices under /dev
    if [ "$CONFIG_DEV_LOOP" = "yes" ]; then
        for idx in $($BUSYBOX seq 0 7); do
            [ ! -e /dev/loop"$idx" ] && ln -s /dev/block/loop"$idx" /dev/loop"$idx"
        done
    fi

    # Ensures DEBDROIDMGR_IMG is a regular file
    if [ ! -f "$DEBDROIDMGR_IMG" ]; then
        echo "$0: Cannot locate debian image: \"$DEBDROIDMGR_IMG\"."
        exit 1
    fi

    # Ensures DEBDROIDMGR_ENV is not a symlink
    if [ -L "$DEBDROIDMGR_ENV" ]; then
        echo "$0: Refusing to operate on a symlinked environment."
        exit 1
    fi

    # Attempts image repair
    if [ "$CONFIG_ENV_FSCK" = "yes" ]; then
        echo "Attempting image repair..."
        if ! "$DEBDROIDMGR_BIN"/e2fsck -fp "$DEBDROIDMGR_IMG"; then
            echo "$0: Failed to repair the linux image."
            echo "Manual user intervention is required."
            exit 1
        fi
    fi

    # Prepares the image mountpoint
    mkdir -p "$DEBDROIDMGR_ENV"
    if ! $BUSYBOX mount -o loop "$DEBDROIDMGR_IMG" "$DEBDROIDMGR_ENV"; then
        echo "$0: Failed to mount the linux filesystem."
        echo "Loop mounts can fail sometimes. Rerun the script."
        exit 1
    fi

    # Ensures DEBDROIDMGR_ENV is a valid filesystem
    if [ ! -f "$DEBDROIDMGR_ENV/bin/sh" ]; then
        echo "$0: Mounted image does not appear to be a valid linux filesystem."
        exit 1
    fi

    # Mounts the /proc filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/proc
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/proc && $BUSYBOX mount -t proc /proc "$DEBDROIDMGR_ENV"/proc

    # Checks if the host has overlay support
    if ! grep -q overlay /proc/filesystems > /dev/null  2>&1; then
        echo "$0: Missing overlay support, falling back to bind-mount for /dev."
    fi

    # Mounts the /dev filesystem (overlayed)
    mkdir -p "$DEBDROIDMGR_ENV"/dev
    mkdir -p "$DEBDROIDMGR_ENV"/mnt/dev-upper "$DEBDROIDMGR_ENV"/mnt/dev-work
    chmod 700 "$DEBDROIDMGR_ENV"/mnt/dev-upper "$DEBDROIDMGR_ENV"/mnt/dev-work
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/mnt/dev-upper && $BUSYBOX mount -t tmpfs tmpfs "$DEBDROIDMGR_ENV"/mnt/dev-upper
    if ! $BUSYBOX mount -t overlay overlay \
            -o lowerdir=/dev,upperdir="$DEBDROIDMGR_ENV"/mnt/dev-upper,workdir="$DEBDROIDMGR_ENV"/mnt/dev-work \
            "$DEBDROIDMGR_ENV"/dev > /dev/null 2>&1; then
        echo "$0: Overlay failed, falling back to bind-mount for /dev."
        $BUSYBOX mount --bind /dev "$DEBDROIDMGR_ENV"/dev

        # Cleans the unused tmpfs
        $BUSYBOX umount "$DEBDROIDMGR_ENV"/mnt/dev-upper
        rm -rf "$DEBDROIDMGR_ENV"/mnt/dev-upper "$DEBDROIDMGR_ENV"/mnt/dev-work
    fi

    # Mounts the /dev/pts filesystem
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/dev/pts && $BUSYBOX mount -t devpts devpts "$DEBDROIDMGR_ENV"/dev/pts

    # Mounts the /dev/shm filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/dev/shm
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/dev/shm && $BUSYBOX mount -o rw,nosuid,nodev,noexec,mode=1777 -t tmpfs tmpfs "$DEBDROIDMGR_ENV"/dev/shm

    # Mounts the /sys filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/sys
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/sys && $BUSYBOX mount -r -t sysfs /sys "$DEBDROIDMGR_ENV"/sys

    # Mounts the /tmp filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/tmp
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/tmp && $BUSYBOX mount -t tmpfs -o rw,nosuid,nodev,mode=1777,size=64M tmpfs "$DEBDROIDMGR_ENV"/tmp

    # Mounts the /system filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/system
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/system && $BUSYBOX mount -r /system "$DEBDROIDMGR_ENV"/system

    # Mounts the /sdcard filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/sdcard
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/sdcard && $BUSYBOX mount --bind /sdcard "$DEBDROIDMGR_ENV"/sdcard

    # Mounts the /debdroid/bin directory
    mkdir -p "$DEBDROIDMGR_ENV"/debdroid/bin
    [ "$CONFIG_DEBDROID_BIN" = "yes" ] && \
        ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/debdroid/bin && $BUSYBOX mount --bind "$DEBDROIDMGR_BIN" "$DEBDROIDMGR_ENV"/debdroid/bin

    # Mounts and preloads libs in the /debdroid/lib directory
    mkdir -p "$DEBDROIDMGR_ENV"/debdroid/lib
    true > "$DEBDROIDMGR_ENV"/etc/ld.so.preload
    if [ "$CONFIG_DEBDROID_LIB" = "yes" ]; then
        ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/debdroid/lib && $BUSYBOX mount --bind "$DEBDROIDMGR_LIB" "$DEBDROIDMGR_ENV"/debdroid/lib

        # Registers debdroid libraries in /etc/ld.so.preload
        for lib in "$DEBDROIDMGR_ENV"/debdroid/lib/*.so*; do
            [ -f "$lib" ] || continue # Ensures that library exists
            # shellcheck disable=SC2046
            echo /debdroid/lib/$(basename "$lib") >> "$DEBDROIDMGR_ENV"/etc/ld.so.preload
        done
    fi

    # Grows the system's shared memory
    $BUSYBOX sysctl -w kernel.shmmax="$CONFIG_ENV_SHMMAX" > /dev/null 2>&1

    # Creates the /etc/resolv.conf file
    true > "$DEBDROIDMGR_ENV"/etc/resolv.conf
    for server in 1 2 3 4; do
        [ -z "$(getprop net.dns$server)" ] && break
        echo "nameserver $(getprop net.dns$server)" >> "$DEBDROIDMGR_ENV"/etc/resolv.conf
    done

    # Creates a fallback for the /etc/resolv.conf file
    if [ ! -s "$DEBDROIDMGR_ENV"/etc/resolv.conf ]; then
        echo "$0: DNS resolution failed, falling back to nameserver $CONFIG_ENV_DNSSERVER"
        echo "nameserver $CONFIG_ENV_DNSSERVER" >> "$DEBDROIDMGR_ENV"/etc/resolv.conf
    fi

    # Creates the /etc/hosts file
    true > "$DEBDROIDMGR_ENV"/etc/hosts
    echo "127.0.0.1     localhost $($BUSYBOX hostname)" >> "$DEBDROIDMGR_ENV"/etc/hosts
    echo "::1           localhost ip6-localhost ip6-loopback" >> "$DEBDROIDMGR_ENV"/etc/hosts
}

# Unmounts the chroot environment
stop_environment()
{
    # Unmounts previously mounted filesystems
    for mount_point in debdroid/lib debdroid/bin sdcard system tmp dev/pts dev/shm dev mnt/dev-upper sys proc; do
        if $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV/$mount_point"; then
            $BUSYBOX umount "$DEBDROIDMGR_ENV/$mount_point" > /dev/null 2>&1 || $BUSYBOX umount -l "$DEBDROIDMGR_ENV/$mount_point" > /dev/null 2>&1
        fi
    done

    # Unmounts the root filesystem
    $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV" && $BUSYBOX umount "$DEBDROIDMGR_ENV"
}

# Prints HELP Usage
if [ $# -eq 0 ]; then
    echo "$0: A lightweight utility to create safe, isolated chroot environments."
    echo "Usage: $0 <img> <mount-point> <bin-dir> <lib-dir> (<command>)?"
    exit
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

# Checks for missing arguments
if [ $# -lt 4 ]; then
    echo "$0: Expected at least 4 arguments, but got $#."
    echo "Usage: $0 <img> <mount-point> <bin-dir> <lib-dir> (<command>)?"
    exit 1
fi


# Checks for popular busybox install locations
if [ -z "$BUSYBOX" ]; then
    if [ -x /sbin/busybox ]; then
        BUSYBOX=/sbin/busybox
    elif [ -x /system/bin/busybox ]; then
        BUSYBOX=/system/bin/busybox
    elif [ -x /system/xbin/busybox ]; then
        BUSYBOX=/system/xbin/busybox
    elif [ -x /data/local/bin/busybox ]; then
        BUSYBOX=/data/local/bin/busybox
    else
        echo "$0: Cannot locate the busybox binary."
        echo "Manually set it using the $BUSYBOX variable."
        exit 1
    fi
fi

# Configures parameters
DEBDROIDMGR_IMG=$1
DEBDROIDMGR_ENV=$2
DEBDROIDMGR_BIN=$3
DEBDROIDMGR_LIB=$4
shift 4

# NOTE: Remains unquoted as it has to preserve flags when passed to chroot
# shellcheck disable=SC2124
DEBDROIDMGR_EXEC=$@

# Pass 1: Sets up the private mount namespace
if [ -z "$DEBDROIDMGR_MARK" ]; then
    export DEBDROIDMGR_MARK=1

    # Creates a private mount namespace
    # shellcheck disable=SC2086
    if ! $BUSYBOX unshare --mount sh "$0" "$DEBDROIDMGR_IMG" "$DEBDROIDMGR_ENV" "$DEBDROIDMGR_BIN" "$DEBDROIDMGR_LIB" $DEBDROIDMGR_EXEC; then
        echo "$0: Failed to create a private mountpoint."
    fi

    echo "$0: Stopping environment: \"$DEBDROIDMGR_ENV\""
    stop_environment

    unset DEBDROIDMGR_MARK

# Pass 2: Sets up the linux filesystem
else
    # Defines the chroot command
    : "${DEBDROIDMGR_EXEC:=/bin/su}"

    # Makes the script trigger "stop_environment" on exit
    trap 'stop_environment' EXIT HUP INT TERM QUIT PIPE

    echo "$0: Starting environment: \"$DEBDROIDMGR_ENV\""
    start_environment

    # Spawns a clean login session without inheriting env variables
    echo "$0: Running chroot command: \"$DEBDROIDMGR_EXEC\""
    $BUSYBOX chroot "$DEBDROIDMGR_ENV" /bin/su - -c "sh /debdroid/bin/debinit && $DEBDROIDMGR_EXEC"
fi
